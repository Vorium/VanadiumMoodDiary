# AGENTS.md

> 给 AI 编程 Agent 看的项目指引。先读 README.md 看产品视角，再读这份看代码视角。

## 项目速览

**产品**：精神心理患者吃药打卡 App（参考"死了么"模式做私域加强版）。

**栈**：Flutter 3.44.5 / Dart 3.12.2 / Riverpod 2.6 / Drift 2.28 (SQLCipher) / go_router 14.6。

**核心特性**：本地加密、零云端、4 层架构（`presentation → domain ← data`）+ 共享层（`shared/`）。

## 4 层架构 + 共享层

```
lib/
├── main.dart              # 入口（含通知 init）
├── app.dart               # App 根 + ProviderScope
├── routing/               # go_router 配置（app_router.dart）
├── theme/                 # AppTokens + Material 3 主题
├── l10n/                  # Strings 静态常量（中文）
├── data/                  # 基础设施层
│   ├── database/         # Drift 表 / 数据库 / 迁移
│   │   ├── tables/       # 1 个表 = 1 个文件（*_entries.dart）
│   │   ├── *mapper.dart  # row ↔ entity 翻译
│   │   └── app_database.dart
│   ├── repositories/     # *RepositoryImpl（实现 domain 接口）
│   ├── services/         # 通知/邮件/SMS/录音/导出
│   └── (无 utils/ - 搬到 shared/ 了)
├── domain/                # 领域层（0 Flutter 0 Drift 0 data 0 presentation）
│   ├── entities/         # 业务实体（*Entity 后缀）
│   ├── logic/            # 业务规则（量表/streak/care engine/报告）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例（业务编排）
├── shared/                # 共享层：domain + data + presentation 共用
│   ├── formatters.dart    # 格式化工具
│   ├── json_codec.dart    # JSON 编解码
│   ├── domain_value.dart  # DomainValue<T>（替代 drift Value<T>）
│   └── mood_visual.dart   # 情绪分数 → emoji/label/ARGB int
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers
    ├── pages/             # 1 个页面 = 1 个目录
    │   ├── home/
    │   ├── setup/
    │   ├── settings/
    │   ├── trend/
    │   ├── assessment/
    │   ├── medication/
    │   └── vent/         # v0.15 树洞
    └── widgets/           # 通用组件（*_button.dart / page_scaffold.dart 等）
```

**依赖方向**：`presentation → domain ← data`。`domain/` 下任何文件都不能 `import 'package:flutter/...'`。验证方式：`flutter analyze` + `flutter test`，以及 0 error。

**关键约束**：
- domain 实体 = `*Entity` 后缀（避免和 drift `@DataClassName('X')` 冲突）
- drift 表的 @DataClassName 用单数（`VentEntry`），但 domain 实体叫 `VentEntryEntity`
- row → entity 的翻译放 `data/database/*_mapper.dart`，**不放** domain 层
- presentation provider 用 `Provider<X>(...)` 暴露 `XRepository`（domain 接口），不暴露 impl
- UI 调 `context.push(...)` / `context.pop()`（go_router 习惯），不用 `Navigator.pushNamed`

## 必读文件

进项目先扫这 5 个：

1. `lib/main.dart` — 启动顺序、SQLCipher 初始化、通知 init
2. `lib/data/database/app_database.dart` — schemaVersion 当前 6，所有表 + migration
3. `lib/domain/logic/care_engine.dart` — 失联检测 / 续方 / 通知触发核心规则
4. `lib/presentation/providers/core_providers.dart` — 全局 provider 注册表
5. `lib/routing/app_router.dart` — 所有页面路由 + shell（NavigationRail）

## 命名约定

| 概念 | 命名 | 例子 |
|---|---|---|
| drift 表 | snake_case 表名 + 单数 @DataClassName | `vent_entries` + `VentEntry` |
| domain 实体 | PascalCase + `Entity` 后缀 | `VentEntryEntity` |
| mapper | `X_mapper.dart` | `vent_mapper.dart` |
| repository impl | `X_repository_impl.dart` | `vent_repository_impl.dart` |
| abstract repo | `X_repository.dart`（无后缀） | `vent_repository.dart` |
| provider | `xRepositoryProvider` | `ventRepositoryProvider` |
| 页面 | 1 个目录 = 1 个页面 | `lib/presentation/pages/vent/` |
| 测试 | 跟实现 1:1，加 round 编号后缀 | `vent_list_round18_test.dart` |

## 开发流程

**新功能 5 步走**（参考 v0.15 vent 落地）：

1. **domain**：`entities/X_entity.dart` + `repositories/X_repository.dart`（abstract）
2. **data**：`database/tables/x_entries.dart` + `database/x_mapper.dart` + `repositories/x_repository_impl.dart`
3. **schema 升级**：`app_database.dart` schemaVersion++ + migration + `watchX`/`insertX`/`deleteX` 方法 + `dart run build_runner build --delete-conflicting-outputs`
4. **presentation**：`pages/x/`（1 个目录 = 1 页面） + `core_providers.dart` + `app_router.dart` 加路由
5. **测试 + 验证**：`flutter analyze` 0 error + `flutter test` 全过 + `flutter commit` 风格 commit

**写完先跑两个命令**：

```bash
flutter analyze    # 必须 0 error
flutter test       # 必须全过（当前 462 cases）
```

## 隐私边界

以下模块**严禁**互相渗透：

| 模块 | 进什么 | 不进什么 |
|---|---|---|
| 树洞（vent） | 无 | 趋势 / 评估 / CareEngine / SafetyWatch / 通知 / 关怀 |
| 情绪日记（mood） | mood-specific reports | 通知（v0.15 之后可加） |
| 心理评估（assessment） | 评估历史趋势 | 失联通知（除非 CrisisSignal） |
| 打卡（check-in） | streak / 趋势 | 评估 |
| 失联通知（SafetyWatch） | 通知家人 | 内部 detail（仅 SMS） |

如果发现树洞内容进了趋势页 = **bug**，立即修。

## 测试

```bash
flutter test                                       # 全部
flutter test test/domain/                          # 仅 domain
flutter test test/data/                            # 仅 data
flutter test test/presentation/                    # 仅 presentation
flutter test test/presentation/X_round18_test.dart # 单文件
```

测试结构：1 个测试文件对应 1 个 round。命名 `{module}_{roundN}_test.dart`。`roundN` 对应版本号中的 round 数字（如 v0.15 round 18）。

测试三层：
- **domain 业务**：纯 Dart，零 Flutter 依赖，最快
- **data round-trip**：DB insert → entity → 校验字段
- **presentation widget**：`ProviderScope` overrides + `MaterialApp` + `tester.pumpAndSettle`

## 调试

```bash
flutter run -d <device>                            # 跑
flutter logs                                       # 看日志
flutter test --plain-name "测试描述"               # 跑单个 test
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成
```

**dev 服务器坑**：web 平台不能用 `flutter run -d chrome`（drift worker 404），用 `flutter build web` + `python -m http.server 8358` 走 production 模式。

## 架构检查脚本（v0.16 Round 9-11）

1 个 CI 友好的脚本检查 4 层架构健康度（v0.16 Round 13 起合并）：

```bash
dart scripts/check_all.dart   # 一次出两份报告：purity + consistency
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑
```

**`check_all.dart`** 检查：
- **[1/2] 纯度**：domain/shared/ 0 flutter / 0 drift / 0 data / 0 presentation；data 不依赖 presentation。同时检测 `package:` 绝对路径 + `../../` 相对路径
- **[2/2] 一致性**：domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应；shared/ 每个文件至少被 2 层用
- 违规时 exit code 1，CI 会 fail

> Round 13 之前用的是 `check_domain_purity.dart` + `check_architecture_consistency.dart` 2 个 script，已合并删除。

**已知 bug 修复**：写这俩脚本时发现 Dart `RegExp` 默认 `^` 不 multi-line — 必须显式 `multiLine: true` 或用 `readAsLinesSync()` 逐行处理。

## 关键约束

- `dart:io` 只在 `data/` 下用（domain 层用 `dart:io` 拼路径 OK，但不能用 `package:flutter/...`）
- 写完代码**必跑** `flutter analyze` + `flutter test`
- 任何 PR 必保 0 error / 0 warning（info-level 可以）
- `pubspec.yaml` 改完必跑 `flutter pub get`
- drift 表改完必跑 `dart run build_runner build --delete-conflicting-outputs`
- 改完 schema 必改 `app_database.dart` 的 schemaVersion + migration
- 提交风格：`<version> round <N>: <title>`，参考 `git log --oneline`

## 已知坑

- **schemaVersion 升级漏 migration**：改表后忘了加 `onUpgrade`，老用户升级会崩
- **`VentEntryEntity` vs `VentEntry`**：domain 用前者，drift 生成后者，写 import 别搞混
- **audioplayers + record** 一起用：先 `dispose recorder` 再 `dispose player`，否则文件锁冲突
- **SQLCipher 加密 + audio 文件**：audio 在 DB 之外（app docs），但 DB 路径仍受 SQLCipher 保护
- **crash reporter 集成**：本项目不接 Firebase / Sentry，本地 SQLite 错误通过 `runZonedGuarded` 打印

## 决策记录

| 决策 | 原因 |
|---|---|
| 4 层架构 | domain 易测试 + 易复用 + 0 Flutter 依赖 |
| SQLCipher | 精神心理患者数据敏感，零云端 |
| 树洞独立表 | 隐私边界：绝对不进任何分析 / 通知 / 关怀 |
| audio 存本地文件 | DB 体积不能爆炸，文件用路径引用 |
| ProviderScope overrides 测试 | 真实 DB 测试太慢，in-memory + override 足够覆盖 |
| 主页底部按钮加"倾诉" | 用户主要路径 = 打卡 / 设置 / 倾诉 3 个核心动作 |

## 文档

- `README.md` — 产品视角
- `docs/CHANGELOG.md` — 版本变更（Keep a Changelog 格式）
- `docs/DEPLOYMENT.md` — 部署相关
- `docs/SENDGRID_SETUP.md` — 邮件服务配置
- `AGENTS.md` — 本文件（代码视角）
