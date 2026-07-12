# Drift Web 平台支持实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让慢性病管家 Flutter 应用在 web 平台跑通完整 SQLite 功能，MVP 阶段可在浏览器演示。

**Architecture:** Drift conditional import 模式 + WASM 后端。把 `_openConnection()` 拆到 `connection/{abstract, native, web}.dart` 三文件，build 时编译器根据目标平台挑对应实现。

**Tech Stack:**
- Drift 2.28.2（pubspec.lock 锁）
- sqlite3 2.9.4（pubspec.lock 锁）
- sqlite3_flutter_libs 0.5.42（提供 native binary）
- WasmDatabase（drift 内置）
- Flutter 3.41.9 + Dart 3.11.5

## Global Constraints

- Flutter 3.41.9，Dart 3.11.5（pubspec.yaml 锁的 `flutter: ">=3.41.0"`）
- 现有 **32 个单元测试不能回归**（`flutter test` 必须 32/32 过）
- `flutter analyze` 必须 **0 issues**
- 资源版本必须匹配 `sqlite3: 2.9.4`（pubspec.lock 锁的）
- 所有 commit 用 project-local git config（`Mavis <mavis@MiniMax.local>`）
- **MVP 阶段不做 web 集成测试**（spec 4.2 明确：以 build + 集成验证为主，v1.0+ 再补单测）

---

### Task 1: 创建 connection/ 三件套

**Files:**
- Create: `lib/data/database/connection/connection.dart`
- Create: `lib/data/database/connection/native.dart`
- Create: `lib/data/database/connection/web.dart`

**Interfaces:**
- Consumes: 无（从零建）
- Produces: `QueryExecutor openConnection()` —— abstract 签名，三平台都实现

- [ ] **Step 1: 创建 `lib/data/database/connection/connection.dart`（abstract 接口）**

完整内容：
```dart
import 'package:drift/drift.dart';

/// 平台无关的连接抽象
///
/// 在 native 平台（iOS / Android / Windows / macOS / Linux）走 [native.dart]
/// 在 web 平台走 [web.dart]
/// 用 conditional import 切换：见 `app_database.dart` 的 import 块
QueryExecutor openConnection() =>
    throw UnsupportedError(
      'openConnection() should be overridden by a platform-specific import',
    );
```

- [ ] **Step 2: 创建 `lib/data/database/connection/native.dart`（iOS/Android/Windows/macOS/Linux 实现）**

完整内容：
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

- [ ] **Step 3: 创建 `lib/data/database/connection/web.dart`（Web WASM 实现）**

完整内容：
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

- [ ] **Step 4: 验证三文件存在**

Run (PowerShell):
```powershell
Get-ChildItem D:\Batch\chroniccare\lib\data\database\connection | Select-Object Name, Length
```

Expected: 列出 `connection.dart` / `native.dart` / `web.dart` 三个文件，每个 < 1 KB。

- [ ] **Step 5: Commit**

```bash
git add lib/data/database/connection/
git commit -m "feat(db): add drift conditional import scaffold for web/native"
```

Expected: 1 commit, 3 new files, no other changes.

---

### Task 2: 改 `app_database.dart` 用条件导入

**Files:**
- Modify: `lib/data/database/app_database.dart`

**Interfaces:**
- Consumes: `connection/connection.dart`（abstract）+ `connection/native.dart`（dart.library.io）+ `connection/web.dart`（dart.library.html）
- Produces: `AppDatabase` 类继续对外暴露，但内部构造改成 `super(openConnection())`

- [ ] **Step 1: 替换 import 块**

找到 `lib/data/database/app_database.dart` 第 1-12 行（`import 'package:drift/drift.dart';` 到 `import 'tables/user_profiles.dart';`），把：
```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/check_ins.dart';
import 'tables/contacts.dart';
import 'tables/medications.dart';
import 'tables/user_profiles.dart';
```

替换为：
```dart
import 'package:drift/drift.dart';

import 'connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

import 'tables/check_ins.dart';
import 'tables/contacts.dart';
import 'tables/medications.dart';
import 'tables/user_profiles.dart';
```

- [ ] **Step 2: 删 `_openConnection()` 函数**

找到 `lib/data/database/app_database.dart` 第 125-131 行的 `LazyDatabase _openConnection() { ... }` 整个函数（包括闭合大括号），删除。

- [ ] **Step 3: 改 `AppDatabase` 构造**

找到 `class AppDatabase extends _$AppDatabase { AppDatabase() : super(_openConnection()); }`，把 `_openConnection()` 改成 `openConnection()`：
```dart
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
```

- [ ] **Step 4: 跑 `flutter test` 确认 32/32 没回归**

Run (PowerShell):
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
Set-Location D:\Batch\chroniccare
& "D:\tools\flutter\bin\flutter.bat" test
```

Expected: `All tests passed!` + 32 个 test 编号全过。

- [ ] **Step 5: 跑 `flutter analyze` 确认 0 issues**

Run (PowerShell):
```powershell
& "D:\tools\flutter\bin\flutter.bat" analyze
```

Expected: `No issues found!`（可能在 17-20 秒内出结果）。

- [ ] **Step 6: Commit**

```bash
git add lib/data/database/app_database.dart
git commit -m "refactor(db): switch app_database to conditional import openConnection"
```

Expected: 1 commit, 1 file changed.

---

### Task 3: 下载 web 静态资源（sqlite3.wasm + drift_worker.dart.js）

**Files:**
- Create: `web/sqlite3.wasm`（~1.3 MB）
- Create: `web/drift_worker.dart.js`（~30 KB）

**Interfaces:**
- Consumes: 无（直接下载）
- Produces: web 平台能 fetch 到这两个资源

- [ ] **Step 1: 下 `web/sqlite3.wasm`（匹配 sqlite3 2.9.4）**

Run (PowerShell):
```powershell
$ProgressPreference = 'Continue'
$url = 'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm'
$out = 'D:\Batch\chroniccare\web\sqlite3.wasm'
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 300
Get-Item $out | Select-Object Length
```

Expected: Length 在 1,300,000 到 1,500,000 bytes 之间（~1.3 MB）。

- [ ] **Step 2: 下 `web/drift_worker.dart.js`（匹配 drift 2.28.2）**

Run (PowerShell):
```powershell
$ProgressPreference = 'Continue'
$url = 'https://github.com/simolus3/drift/releases/download/drift-2.28.2/drift_worker.dart.js'
$out = 'D:\Batch\chroniccare\web\drift_worker.dart.js'
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 120
Get-Item $out | Select-Object Length
```

Expected: Length 在 20,000 到 50,000 bytes 之间（~30 KB）。

- [ ] **Step 3: 验证两个文件存在且非空**

Run (PowerShell):
```powershell
Get-ChildItem D:\Batch\chroniccare\web\sqlite3.wasm, D:\Batch\chroniccare\web\drift_worker.dart.js | Select-Object Name, Length
```

Expected: 两个文件都列出，size 跟 step 1 / step 2 一致。

- [ ] **Step 4: Commit**

```bash
git add web/sqlite3.wasm web/drift_worker.dart.js
git commit -m "chore(web): add sqlite3 2.9.4 wasm + drift 2.28.2 worker for web platform"
```

Expected: 1 commit, 2 new files, total ~1.3 MB.

---

### Task 4: 验证 web build 成功

**Files:** 无（纯验证）

**Interfaces:**
- Consumes: Task 1-3 全部产出
- Produces: `build/web/` 产物

- [ ] **Step 1: 跑 `flutter build web --release`**

Run (PowerShell):
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
Set-Location D:\Batch\chroniccare
& "D:\tools\flutter\bin\flutter.bat" build web --release
```

Expected: 看到 `✓ Built build/web` 之类的成功信息，无 `Error: Failed to compile`。
耗时：首次 3-5 分钟（dart2js 编译 + 资源处理）。

- [ ] **Step 2: 验证 `build/web/` 产物**

Run (PowerShell):
```powershell
Get-ChildItem D:\Batch\chroniccare\build\web | Select-Object Name | Format-Table -AutoSize
```

Expected: 看到 `index.html`、`main.dart.js`、`flutter.js`、`flutter_service_worker.js`、`assets/`、`canvaskit/`、`sqlite3.wasm`、`drift_worker.dart.js` 等。

- [ ] **Step 3: 不 commit（build/ 在 .gitignore）**

无操作。`build/` 已被 `.gitignore` 排除。

---

### Task 5: 启动 dev server + 截图验证 UI

**Files:** 无（纯集成验证）

**Interfaces:**
- Consumes: build 成功 + 资源就位
- Produces: 截图证明 UI 跑得通

- [ ] **Step 1: 启动 `flutter run -d chrome` 后台**

Run (PowerShell):
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
Set-Location D:\Batch\chroniccare
Start-Process -FilePath "D:\tools\flutter\bin\flutter.bat" -ArgumentList "run","-d","chrome","--web-port=8765","--web-hostname=127.0.0.1" -RedirectStandardOutput "D:\tools\flutter\run.log" -RedirectStandardError "D:\tools\flutter\run.err.log" -NoNewWindow -PassThru | Select-Object Id
```

Expected: 输出一个 PID。把 PID 存到变量备用。
后台日志写到 `D:\tools\flutter\run.log` 和 `run.err.log`。

- [ ] **Step 2: 等 dev server 启动（最多 60 秒）**

Run (PowerShell):
```powershell
$timeout = 60
$elapsed = 0
while ($elapsed -lt $timeout) {
  Start-Sleep -Seconds 5
  $elapsed += 5
  if (Test-Path D:\tools\flutter\run.log) {
    $content = Get-Content D:\tools\flutter\run.log -Raw -ErrorAction SilentlyContinue
    if ($content -match 'http://127\.0\.0\.1:8765') {
      "Dev server ready after $elapsed seconds"
      break
    }
  }
}
```

Expected: 30-60 秒内看到 "Dev server ready" 输出。
若超时：检查 `run.err.log` 看错误（可能是 WASM 加载失败、port 占用等）。

- [ ] **Step 3: 用 playwright 打开并截图 setup 页**

Run (PowerShell):
```powershell
mavis mcp call playwright browser_navigate '{"url":"http://127.0.0.1:8765"}'
mavis mcp call playwright browser_take_screenshot '{"filename":"setup-page.png","fullPage":true}'
mavis mcp call playwright browser_take_screenshot --schema 2>&1 | Select-Object -First 5
```

如果 playwright MCP 没装（`mavis mcp call` 报错），用 playwright Python SDK：
```powershell
pip install playwright
playwright install chromium
python -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={'width':390,'height':844})
    page.goto('http://127.0.0.1:8765')
    page.wait_for_load_state('networkidle', timeout=30000)
    page.screenshot(path='D:\Batch\chroniccare\target\ui-setup.png', full_page=True)
    browser.close()
print('OK')
"
```

Expected: 截图保存到 `D:\Batch\chroniccare\target\ui-setup.png`，看到 setup 流程第 1 步（输入名字 + 邮箱）。

- [ ] **Step 4: 验证 setup → home 跳转**

继续用 playwright（如果用 Python SDK）：
```python
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={'width':390,'height':844})
    page.goto('http://127.0.0.1:8765')
    page.wait_for_load_state('networkidle', timeout=30000)

    # 填 setup 表单
    page.fill('input[aria-label*="名字"], input[aria-label*="name"]', '测试小明')
    # 邮箱输入（如果存在）
    try:
        page.fill('input[aria-label*="邮箱"], input[aria-label*="email"]', 'mom@example.com')
    except:
        pass

    # 点下一步
    page.click('button:has-text("下一步")')
    page.wait_for_timeout(2000)

    # 截 setup 第二步
    page.screenshot(path='D:\Batch\chroniccare\target\ui-setup-step2.png', full_page=True)

    # 完成 setup
    page.click('button:has-text("开始"), button:has-text("完成")')
    page.wait_for_timeout(3000)

    # 截 home 页
    page.screenshot(path='D:\Batch\chroniccare\target\ui-home.png', full_page=True)

    # 点打卡按钮
    page.click('button:has-text("吃了药")')
    page.wait_for_timeout(2000)
    page.screenshot(path='D:\Batch\chroniccare\target\ui-checked.png', full_page=True)

    browser.close()
print('Smoke test passed')
```

Expected: 4 张截图（setup-1 / setup-2 / home / checked）保存到 `target/`，最后打印 "Smoke test passed"。

- [ ] **Step 5: 关 dev server**

Run (PowerShell):
```powershell
Get-Process -Name chrome -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process -Name "flutter" -ErrorAction SilentlyContinue | Stop-Process -Force
Get-NetTCPConnection -LocalPort 8765 -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
```

Expected: 端口 8765 不再被占用。

- [ ] **Step 6: 更新 CHANGELOG.md**

编辑 `docs/CHANGELOG.md`，在 0.1.0+1 之上加新版本：
```markdown
## [0.1.1+2] - 2026-07-12

### Added
- Drift web 平台支持（conditional import + WASM）
- 资源：web/sqlite3.wasm + web/drift_worker.dart.js
- 主入口接通 AppRoot + NotificationService init + dotenv load

### Fixed
- 5 个 lint info 全清（require_trailing_commas × 3, prefer_const_constructors × 2）

### Verified
- 32/32 单元测试通过
- analyze 0 issues
- web build + UI smoke test 跑通
```

- [ ] **Step 7: Commit**

```bash
git add docs/CHANGELOG.md target/ui-*.png
git commit -m "docs: changelog v0.1.1+2 + UI smoke test screenshots"
```

Expected: 1 commit, 1 file changed (CHANGELOG) + 4 screenshots added.
注：`target/` 不在 .gitignore（要加），但截图作为里程碑证据 commit 一次。

---

## Self-Review Checklist

实施前工程师请检查：

- [ ] Task 1-3 是顺序依赖（必须按序）
- [ ] Task 4 依赖 Task 1-3（无 Task 4 验证前不能宣称 web 支持完成）
- [ ] Task 5 是最终烟测，失败需回滚 Task 2
- [ ] 每个 Task 末尾都有 commit
- [ ] Global Constraints 在每个 Task 都隐含生效
- [ ] 没有 "TBD" / "implement later" / "appropriate error handling" 这类 placeholder
- [ ] 所有 code block 都有完整代码
- [ ] 所有命令有 Expected 输出
