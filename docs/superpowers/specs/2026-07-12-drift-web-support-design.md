# Drift Web 平台支持设计

> 给慢性病管家（ChronicCare）Flutter 应用添加 Web 平台支持
> 让 MVP 阶段可以在浏览器跑通完整功能（打卡 / 失联检测 / 邮件 mock）
> 决策日期：2026-07-12 · Q4 答案 = Web (H5) 优先

---

## 1. 问题

### 1.1 背景

慢性病管家是 Flutter 3.41.9 + Dart 3.11.5 项目，数据层用 Drift 2.28（SQLite ORM）+ `sqlite3_flutter_libs` 0.5.42（提供 native SQLite 库）。

### 1.2 根因

`sqlite3_flutter_libs` 依赖 `dart:ffi`（Dart 的 C ABI 桥接）。Web 平台（dart2js / dart2wasm 编译目标）**不支持 FFI**——Web 沙箱没有 native ABI 概念。

错误信息：
```
Error: Dart library 'dart:ffi' is not available on this platform.
```

### 1.3 阻断效果

`flutter build web --release` 失败；`flutter run -d chrome` 无法启动。

PRD 已经选定 Web (H5) 为 MVP 优先平台。Drift web 不支持就阻断了 PRD 路线。

---

## 2. 决策

**采用方案 1：手动条件导入 + WASM**

### 2.1 备选方案对比

| 方案 | 工作量 | 优点 | 缺点 |
|---|---|---|---|
| **1 · 条件导入 + WASM**（推荐） | 2-3h | 标准做法、长期可维护、官方支持 | 需下 1.3MB WASM 资源 |
| 2 · `package:drift_flutter` 封装 | 1-2h | 少写代码 | 多一层依赖、性能调试不直观 |
| 3 · 换数据库（shared_preferences） | 3-4h | 不依赖 Drift web | 迁移成本高、查询能力差 |

### 2.2 方案 1 概述

把 `app_database.dart` 里 `_openConnection()` 拆到 3 个平台相关文件：

- `connection/connection.dart`：abstract 接口
- `connection/native.dart`：iOS / Android / Windows / macOS / Linux 的 `NativeDatabase` 实现
- `connection/web.dart`：Web 的 `WasmDatabase` 实现

用 Dart 的 **conditional import** 让编译器在 build 时挑对应文件：
```dart
import 'connection/connection.dart'
  if (dart.library.html) 'connection/web.dart'
  if (dart.library.io) 'connection/native.dart';
```

---

## 3. 实施细节

### 3.1 文件改动

**新增 3 文件：**

`lib/data/database/connection/connection.dart`（~5 行）
```dart
import 'package:drift/drift.dart';

/// 平台无关的连接抽象
QueryExecutor openConnection() =>
    throw UnsupportedError('Please override in platform-specific file');
```

`lib/data/database/connection/native.dart`（~12 行）
```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chroniccare.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

`lib/data/database/connection/web.dart`（~15 行）
```dart
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final db = await WasmDatabase.open(
      databaseName: 'chroniccare',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return db.resolvedExecutor;
  }));
}
```

**下载 2 静态资源到 `web/`：**
- `web/sqlite3.wasm`（~1.3 MB，从 `https://github.com/simolus3/sqlite3.dart/releases` 下载对应版本）
- `web/drift_worker.dart.js`（~30 KB，从 `https://github.com/simolus3/drift/releases` 下载对应版本）

**改 1 文件：**

`lib/data/database/app_database.dart`
- 删：`import 'package:drift/native.dart';` + `import 'package:path_provider/path_provider.dart';` + `import 'package:path/path.dart' as p;`
- 删：原 `_openConnection()` 函数体
- 删：`import 'connection/connection.dart' if (dart.library.html) 'connection/web.dart' if (dart.library.io) 'connection/native.dart';`
- 改：`AppDatabase() : super(openConnection());`

### 3.2 数据流

**Web 平台首次启动：**
1. 浏览器加载 `web/index.html` → 加载 `main.dart.js`
2. Drift 调 `WasmDatabase.open()` → 浏览器 fetch `web/sqlite3.wasm`（~1.3 MB 一次性）
3. Drift 调 `web/drift_worker.dart.js` 在 Worker 线程跑 WASM 隔离环境
4. SQLite 数据持久化到 **IndexedDB**（浏览器内）
5. 后续读写都走 WASM + IndexedDB，秒级响应

**Native 平台（iOS / Android / Windows 等）：**
- 走 `connection/native.dart` 分支
- 用 `path_provider` 拿应用文档目录
- 文件 `chroniccare.sqlite` 存在本地

### 3.3 错误处理

- WASM 加载失败 → `WasmDatabase.open()` 抛 `Exception`
- `LazyDatabase` 会延迟到首次查询时实例化
- MVP 阶段不弹 alert，只用 `developer.log` 输出 + 主页按钮变 disabled + 显示"请检查网络"
- v1.0+ 完善：捕获错误并显示 SnackBar

### 3.4 资源版本管理

- `sqlite3.wasm` 版本跟随 `package:sqlite3` 升级
- 当前 `sqlite3: 2.9.4`（pubspec.lock 锁定）
- 对应 WASM 版本在 `https://github.com/simolus3/sqlite3.dart/releases/tag/sqlite3-2.9.4`
- 用 `curl` 直接下载到 `web/`，不写脚本（一次性）

---

## 4. 测试

### 4.1 现有测试

**32 个单元测试不受影响**：
- `streak_calculator_test.dart`（11 个）：纯逻辑，不碰 DB
- `email_template_test.dart`（6 个）：纯逻辑
- `reminder_scheduler_test.dart`（9 个）：纯逻辑
- `email_service_test.dart`（2 个）：纯逻辑 + mock

**回归保护**：`flutter test` 跑通 = 业务逻辑没动到。

### 4.2 新增测试（MVP 阶段不做）

- web 集成测试（需要 drift_test + Chrome 环境）→ v1.0+ 再说
- 单元测试 `connection/web.dart`：mock `WasmDatabase.open()`，验证调用参数正确

### 4.3 验证清单

跑 `flutter run -d chrome` 之前确认：
- [ ] 32 个单元测试仍过（`flutter test`）
- [ ] analyze 0 issues（`flutter analyze`）
- [ ] `flutter build web --release` 成功
- [ ] `flutter run -d chrome` 启动后浏览器自动打开
- [ ] 主页 setup → home 流程跑通
- [ ] 打卡写入数据库（DevTools 验证 IndexedDB）
- [ ] 杀进程重启 → 数据还在

---

## 5. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| sqlite3.wasm 与 drift 版本不匹配 | 中 | 高 | 用 pubspec.lock 锁的 `sqlite3: 2.9.4` 对应 release tag |
| Web 上 IndexedDB 容量限制 | 低 | 中 | MVP 单用户 ≤1MB（PRD 5.2）远低于 50MB 限额 |
| WASM 加载慢（首次 ~2s） | 中 | 低 | 加 loading 指示器（MVP 可选） |
| 后续 native 端测试需要 native deps | 低 | 中 | 保留 `connection/native.dart` 显式分支，方便切换回测 |
| 浏览器不支持 SharedArrayBuffer（WASM 多线程） | 低 | 中 | drift WASM 单线程也能跑；性能 OK |

---

## 6. 范围

### 6.1 包含

- ✅ web 平台 conditional import 三件套
- ✅ 静态资源下载（sqlite3.wasm + drift_worker.dart.js）
- ✅ app_database.dart 改 1 文件
- ✅ 现有 32 测试不回归
- ✅ analyze 0 issues

### 6.2 不包含

- ❌ 邮件真实发送（用 EMAIL_USE_MOCK=true 即可）
- ❌ web 集成测试
- ❌ web UI 优化（移动端 viewport 等 v1.0+）
- ❌ iOS / Android native 端改动
- ❌ 性能优化（WASM 加载 loading 提示）

### 6.3 依赖

无需新加 pub 依赖。`drift: 2.28.2` 已经包含 `drift/wasm.dart`。

---

## 7. 验收标准

✅ 完成定义：
1. `flutter build web --release` 成功，产物在 `build/web/`
2. `flutter run -d chrome` 启动后浏览器自动打开 `http://localhost:<port>`
3. 主页 setup 流程跑通（输入名字 + 邮箱 → 跳 home）
4. 主页 home 大按钮打卡 1 次，刷新页面数据还在
5. `flutter test` 32/32 过
6. `flutter analyze` 0 issues
