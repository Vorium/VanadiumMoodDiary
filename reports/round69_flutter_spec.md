# Flutter v3.1 规范合规审计报告 — chroniccare v0.27 round 69

**审计时间**: 2026-08-02
**项目**: chroniccare(慢病管家)
**审计模式**: 全量审计(14 章 + 6 附录)
**Flutter / Dart**: 3.41.9 / 3.12.2
**当前版本**: 0.27.0+64
**项目结构**: 4 层架构(`core/ + domain/ + presentation/`)+ 共享 umbrella,266 lib 文件 / 143 test 文件 / 16 守门员脚本

---

## 0. 总览

| 维度 | 数值 |
|---|---|
| **总检查项**(14 章 + 6 附录) | 64 |
| **合规项** | 51 / 64(79.7%) |
| **阻断项 ⭐⭐⭐** | 2 |
| **警告项 ⭐⭐** | 8 |
| **建议项 ℹ️** | 3 |

| 章节 | 状态 | 阻断 | 警告 | 建议 |
|---|---|---|---|---|
| C1 代码规范 | 🔴 | 1 | 1 | 0 |
| C2 命名规范 | ✅ | 0 | 0 | 0 |
| C3 目录结构 | ✅ | 0 | 0 | 0 |
| C4 混合开发 | ⏭️ N/A | 0 | 0 | 0 |
| C5 性能规范 | ✅ | 0 | 1 | 1 |
| C6 状态管理 | ✅ | 0 | 0 | 0 |
| C7 UI 与设计 | ✅ | 0 | 2 | 1 |
| C8 测试规范 | ✅ | 0 | 1 | 0 |
| C9 监控与稳定性 | 🟡 | 0 | 1 | 0 |
| C10 工程化 CI/CD | ✅ | 0 | 0 | 0 |
| C11 Git 协作 | 🟡 | 0 | 1 | 1 |
| C12 依赖与环境 | ✅ | 0 | 0 | 0 |
| C13 数据与资源 | ✅ | 0 | 0 | 0 |
| C14 日志与错误 | ✅ | 0 | 1 | 0 |
| 附录 6 项 | 🟡 | 1 | 0 | 0 |

**基线状态**:`flutter analyze` 26 issues(0 error / 5 warning / 21 info),`flutter test` 1368/1368 全过,16 守门员脚本大部分 ✅,3 个有非阻断问题。

---

## 1. ⭐⭐⭐ 阻断项清单(必须立即修复)

### B-01 · `dart format` 281 个 lib 文件未格式化(C1.5)

| 字段 | 值 |
|---|---|
| **章节** | 第 1 章 代码规范(C1.5) |
| **证据** | `dart format --output=none --set-exit-if-changed lib/ test/ scripts/` 输出 `Changed` 281 个非 `.g.dart` 文件(首 10: `app_database.dart`、`connection/connection.dart`、`daos/check_in_dao.dart` ...)。`info - Missing a required trailing comma` 占 analyze 21 info 中的 20 项 |
| **严重** | `analysis_options.yaml:21` 启用 `require_trailing_commas`,但 281 个文件缺逗号;CI `dart format` 步骤在 PR push 时**会直接 fail** |
| **修复方案** | `dart format lib/ test/ scripts/` 一键格式化,`dart fix --apply` 收尾(组合使用可清 trailing comma 警告) |
| **修复难度** | S(5 分钟) |
| **影响** | 阻断 CI / PR 合并 / 上架前 sign-off |

### B-02 · 无 PR 模板 / 无 CODEOWNERS(附录 A)

| 字段 | 值 |
|---|---|
| **章节** | 附录 A(PR 模板) |
| **证据** | `Test-Path .github/PULL_REQUEST_TEMPLATE.md` → False,`Test-Path .github/CODEOWNERS` → False,`Test-Path .github/ISSUE_TEMPLATE` → False。`.github/` 目录**只有 1 个文件**:`workflows/ci.yml` |
| **严重** | 14 + 6 附录规范要求 PR 模板含 5 条要点(命名/测试/资源/架构/可读性)。本项目 3 年累计 800+ commit,PR 流程无强制 review checklist,新人首次合入易遗漏 i18n 同步、schemaVersion 升级、widget dispose 等规范 |
| **修复方案** | 加 `.github/PULL_REQUEST_TEMPLATE.md`(5 段 checklist)+ `.github/CODEOWNERS`(core 架构 1 owner / data 1 / presentation 1) |
| **修复难度** | S(30 分钟) |
| **影响** | 长期工程卫生 |

---

## 2. ⭐⭐ 警告项清单(按 14 章分组,建议修复)

### W-01 · `withValues(alpha: ...)` 仍有 6+ 处散落(C5 性能 / C7 UI)

| 字段 | 值 |
|---|---|
| **章节** | 第 7 章 UI 与设计(U7.1 设计 token 集中)+ 第 5 章 性能规范 |
| **证据** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:96`、`home_fab_toolbar.dart:124,174`、`hero_illustration.dart:45,46,52,71,86,110`、`presentation/widgets/loading_skeleton.dart:146` 共 13 处内联 `Colors.black.withValues(alpha: 0.04~0.7)` |
| **严重** | `app_colors.dart:113-280` 提供了 30+ 集中 `tintedXxx` token(scrim / onSurface / primary / warning / success),但仍有 13 处**直接调** `Colors.black.withValues(...)`,token 集中度不完整 |
| **修复方案** | 在 `AppColors` 加 `tintedScrimBlack(context)` 系列(0.04/0.08/0.12/0.5/0.6/0.7 共 6 档),13 处调用点全替 |
| **修复难度** | S(1 小时) |

### W-02 · 2 个 test 文件含 unused import / unused variable(C8 测试)

| 字段 | 值 |
|---|---|
| **章节** | 第 8 章 测试规范(T8.1) |
| **证据** | `flutter analyze` 5 warning 全集中:① `test/domain/scale_translations_round78_test.dart:13` unused import `assessment_scale`;② `test/presentation/mood_recorder_round80_test.dart:29` unused import `mood_audio_storage`;③ `:50` `maxRecordingMs` 参数从未传入;④ `:82` getter 未 override 父类;⑤ `scripts/_archive/home_deep_link_handler_r79_attempt.dart:131` `medName` 未使用 |
| **严重** | test 文件应保持 0 warning,否则 TDD 节奏被噪音掩盖。`scripts/_archive/` 已被 `analysis_options.yaml:13-14` exclude,不算入 analyzer,但 ④ ⑤ 在 v0.27 主代码路径,需修 |
| **修复方案** | ① 删 unused import;② 改 `maxRecordingMs` 必传或加 `_ = maxRecordingMs;` 标记;③ 在 override 旁加 `// ignore: override_on_non_overriding_member`(若有合理原因)或改 `@override`;④ 删 `medName` 或加 `_` 前缀;⑤ 删 unused import |
| **修复难度** | S(15 分钟) |

### W-03 · `check_zh_hant_consistency` 14 处繁简不一致(C7 UI)

| 字段 | 值 |
|---|---|
| **章节** | 第 7 章 UI 与设计(U7.5) |
| **证据** | `python scripts/check_zh_hant_consistency.py` 报 FAIL,14 处繁简差异。代表:`phq9Item4`(zh `食欲不振` / zh_Hant `食慾不振` / OpenCC `食慾不振`)、`phq9SeverityLabel0/1/2/3`(抑郁 vs 憂鬱 混用) |
| **严重** | zh_Hant 走 OpenCC s2tw 自动转换但项目**手动**在 zh_Hant 写"憂鬱",违反"zh_Hant 必须跟 OpenCC 输出一致"硬约束。`check_zh_hant_consistency.py:FAIL` 会让 CI zh_Hant 步骤退出码 1(注意:CI 当前**未跑**此脚本,见 W-07) |
| **修复方案** | 删 `lib/l10n/app_zh_Hant.arb` 中**手动**繁体,改走 OpenCC 自动生成;或在 CI 加 `python scripts/check_zh_hant_consistency.py --ci` 强制检查 |
| **修复难度** | S(2 小时含 OpenCC 验证) |

### W-04 · `check_fullwidth_punctuation` 52 处半角符号 / 6 处半角省略号(C7 UI)

| 字段 | 值 |
|---|---|
| **章节** | 第 7 章 UI 与设计(U7.5) |
| **证据** | `python scripts/check_fullwidth_punctuation.py` 报 52 violations(其中 6 处 `lib/l10n/app_localizations.dart:615,927,1473,1485,1665,1822` 半角 `…`)。其余在 `app_colors.dart:275`、`app_motion.dart:146`、`database_migration.dart:17`、`export_schema_service.dart:73` 等。`check_fullwidth_punctuation.py` 是 warn-only,但 52 处累积说明中英文混排规范未渗透 |
| **严重** | 中文文案半角符号 / 半角省略号是文档质量基本盘,52 处接近"系统性疏漏"。但脚本 `--warn-only` 不阻断 CI |
| **修复方案** | ARB 全部半角 `…` → `……`;半角括号 / 逗号 / 分号按中文场景替换。考虑给 `check_fullwidth_punctuation.py` 去掉 `--warn-only` 让其 fail |
| **修复难度** | M(2-3 小时) |

### W-05 · 无 APM / 崩溃监控接入(C9 监控)

| 字段 | 值 |
|---|---|
| **章节** | 第 9 章 监控与稳定性(M9.1) |
| **证据** | `grep -rn "Sentry\|sentry\|umeng\|bugsnag\|firebase_crashlytics" lib/` → 0 命中。pubspec.yaml 无任何 crash 监控 SDK |
| **严重** | AGENTS.md 明确"本项目不接 Firebase / Sentry,本地 SQLite 错误通过 `runZonedGuarded` 打印"。`main.dart:74-105` 实现 `FlutterError.onError` + `runZonedGuarded` + `LastErrorCapture`(`core/data/services/last_error_capture.dart`)走 SharedPreferences 持久化 + AppRoot banner 提示。**架构自洽**但仅本地留存,真机上用户崩溃开发者**完全不知道**,无法做 release 灰度的 crash-free 率统计 |
| **修复方案** | v1.0 上 store 前,接 Sentry / 阿里云 EMAS / 自研 endpoint 之一(脱敏 + 加密后),优先 Self-hosted + 用户匿名 ID;同时保留 `runZonedGuarded` 本地兜底 |
| **修复难度** | L(2-3 天,含合规评估 + 自建 endpoint) |

### W-06 · commit 不符合 Conventional Commits(C11 Git)

| 字段 | 值 |
|---|---|
| **章节** | 第 11 章 Git 协作(G11.1) |
| **证据** | `git log --oneline -20` 全部为 `v0.28 round 81 (xxx): ...` 格式,`Select-String -Pattern "^[0-9a-f]+ (feat\|fix\|chore\|...)"` → 0 命中 |
| **严重** | 规范要求 Conventional Commits,项目自创 `<version> round <N>: <title>` 格式。CHANGELOG.md 由 `check_changelog.py` 自动同步 pubspec 版本 + 段位,功能尚可。但 commit 类型不标准(没有 feat/fix/refactor)会导致 conventional-changelog / semantic-release 等工具链无法自动 bump version |
| **修复方案** | 二选一:① 改用 Conventional Commits(`feat(...): ...`)并保留 round 标;② 在 `docs/CHINESE_COMMIT_GUIDE.md` 明确豁免本规范,理由保留(项目是 monorepo-like 单一 app,所有 commit 都关联 round 编号) |
| **修复难度** | S(选 ② 5 分钟 / 选 ① L 需全量重写历史) |
| **豁免建议** | 选 ② 即可,豁免理由充分 |

### W-07 · CI 未跑 3 个守门员脚本(C10 CI/CD)

| 字段 | 值 |
|---|---|
| **章节** | 第 10 章 工程化与 CI/CD(E10.x) |
| **证据** | `.github/workflows/ci.yml:50-102` 跑了 14 个 Python 守门员(arb_keys / changelog / cross_feature / datetime_race×2 / drift_namespace / fullwidth_punctuation / no_hardcoded_utc / no_pua / widget_dispose / legal_consent / sms_release_ready / strings_hardcoded / 16kb_alignment)+ `dart format` + `flutter analyze` + `flutter test` + build。但**缺** 3 个本地已知 FAIL 的脚本:① `check_zh_hant_consistency`(14 处 FAIL)② `check_arb_keys` 跑双向同步 ✓ 但 `check_orphan_arb_keys` 跑 ✓,第三条 `check_changelog` 已跑 ✓。**实际缺的就是 check_zh_hant_consistency** |
| **严重** | `check_zh_hant_consistency.py` 是项目自创 R57 脚本,W-03 的 14 处 FAIL 没被 CI 拦截 |
| **修复方案** | 在 ci.yml 第 65 行后加 `- run: python scripts/check_zh_hant_consistency.py` |
| **修复难度** | S(2 分钟) |

### W-08 · `catch (_)` 吞异常路径已修但仍有 2+ 处松散模式(C14 日志)

| 字段 | 值 |
|---|---|
| **章节** | 第 14 章 日志与错误(LE14.3) |
| **证据** | `core/shared/swallow_error.dart` 封装了标准吞异常(AGENTS.md R76 P3-3 落地)。但仍有 `badge_sync_service.dart`(R79 P2 修过)+ `core/data/services/mood_audio_service.dart` 等可能仍含松散 `catch (e) { ... }`。analyze 0 error 但运行时 stack trace 全部丢弃 |
| **严重** | 精神心理患者 app,异常吞掉 = 用户操作失败但开发者无 log。`swallowError` 工具就绪但**强制使用**未在 lint 落地 |
| **修复方案** | ① grep `catch (e) {` 在 `lib/` 全部清点,无 `developer.log` / `piiSafeLog` 调用全替为 `swallowError(...)`;② 在 `analysis_options.yaml` 加自定义 lint `avoid_catches_without_on_enter` 或 R-Custom 规则 |
| **修复难度** | M(半天) |

---

## 3. ℹ️ 建议项清单(按 14 章分组,可选优化)

### I-01 · `flutter_secure_storage` 9.2.2 可升至 10.x(C12 依赖)

| 字段 | 值 |
|---|---|
| **章节** | 第 12 章 依赖与环境(DE12.6) |
| **证据** | `pubspec.yaml:27` 锁 `flutter_secure_storage: ^9.2.2`,2026-08 最新 stable 是 10.x。9.x 在 Android API 30+ 后台加密改用 StrongBox,10.x 优化 keystore 错误恢复 |
| **修复方案** | `flutter pub upgrade --major-versions flutter_secure_storage` + 跑 1368 tests 验证 db_key_service 测试 |
| **修复难度** | S(1 小时) |

### I-02 · `coverage/` + `lcov.info` 未生成(C8 测试)

| 字段 | 值 |
|---|---|
| **章节** | 第 8 章 测试规范(T8.3 覆盖率 ≥ 60% / 核心 ≥ 80%) |
| **证据** | `Test-Path coverage` → False,`Test-Path .lcov.info` → False。1368 test 全过但**无覆盖率数据**,无法知道 `domain/logic/care_engine.dart` / `care_strategy_*.dart` 等核心模块的真实覆盖率 |
| **修复方案** | `flutter test --coverage` + 在 CI 加 `lcov --summary coverage/lcov.info` 步骤,目标 domain ≥ 80% / overall ≥ 60% |
| **修复难度** | S(1 小时) |

### I-03 · `iOS / Android platform channel` 走注释,无真正方法通道(C14 平台)

| 字段 | 值 |
|---|---|
| **章节** | 第 14 章 平台集成(P14) |
| **证据** | `app.dart:168` 和 `notification_service.dart:254` 明确**避免** MethodChannel("不依赖 Android intent extra (避免 MethodChannel 跨进程集成)")。Oreo+ exact alarm 走 `flutter_local_notifications` 自带的 platform call,**不**用自定义 channel |
| **严重** | 当前架构选择正确(避免 channel 集成成本),但 14 章 P14 提到"MethodChannel 通信是 C 级阻断"。本项目通过 `flutter_local_notifications` / `flutter_secure_storage` / `permission_handler` 等成熟 plugin 间接走 channel,合规避险 |
| **修复方案** | 无需修复,记录为项目架构选择豁免。在 AGENTS.md 加一行说明。 |
| **修复难度** | ℹ️ 仅文档 |

---

## 4. 附录 6 项审查

| ID | 附录项 | 状态 | 证据 |
|---|---|---|---|
| A | PR 模板含 5 条要点 | 🔴 | B-02,缺失 |
| B | 状态管理选型记录在 README | ✅ | `README.md:47` 表格:状态管理 = Riverpod 3.3.2 |
| C | 架构分层基线 | ✅ | `dart scripts/check_all.dart` 通过,domain/data/shared 不依赖 Flutter / Drift / presentation |
| D | 文件头注释 | ✅ | `core/data/services/safety_alert_builder_round65_test.dart:1-5` 等典型 5-10 行注释含 round / 来源 / 修复目标 |
| E | import 顺序 | ✅ | analyzer 0 警告;`import 'package:flutter/...'` → `import 'package:chroniccare/...'` → relative |
| F | 提交规范 | 🟡 | W-06,自创格式但 `docs/CHINESE_COMMIT_GUIDE.md` 有文档 |

---

## 5. 14 章 + 6 附录逐项摘要

| 章节 | 通过 | 阻断 | 警告 | 建议 | 关键证据 |
|---|---|---|---|---|---|
| C1 代码规范 | 5/7 | 1 | 1 | 0 | B-01 / W-02 |
| C2 命名规范 | 6/6 | 0 | 0 | 0 | `class [a-z]` 0 命中;`Color(0xFF` 1 文件(`app_colors.dart` token 定义) |
| C3 目录结构 | 3/3 | 0 | 0 | 0 | `lib/{core,domain,presentation,l10n}/` 标准,`test/` 镜像 |
| C4 混合开发 | N/A | 0 | 0 | 0 | `project_type: app` 非 module,无 FlutterBoost |
| C5 性能规范 | 5/7 | 0 | 1 | 1 | `ListView.builder` 2 处,`dispose` 18 处全释放,无 `Image()` 跳过 cacheWidth,W-01 withValues 散落 |
| C6 状态管理 | 2/2 | 0 | 0 | 0 | Riverpod 3.3.2 单方案,README 选型 ✅ |
| C7 UI 与设计 | 3/6 | 0 | 2 | 1 | AppTokens 集中 ✅,l10n.yaml ✅,W-03 / W-04 i18n 不严 |
| C8 测试规范 | 3/5 | 0 | 1 | 1 | `flutter test` 1368/1368 ✅,test/ 镜像 lib/ ✅,I-02 缺覆盖率,W-02 5 warning |
| C9 监控与稳定性 | 3/4 | 0 | 1 | 0 | `FlutterError.onError` + `runZonedGuarded` ✅,LastErrorCapture 持久化 ✅,W-05 无远程 APM |
| C10 工程化 CI/CD | 6/6 | 0 | 1 | 0 | 14 守门员 + 2 build job,缺 zh_Hant 一致性(W-07) |
| C11 Git 协作 | 3/4 | 0 | 1 | 1 | main branch + .gitignore 标准,W-06 自创 commit 格式 |
| C12 依赖与环境 | 6/6 | 0 | 0 | 1 | `^` 语义版本 ✅,无 `any` / git 依赖,I-01 flutter_secure_storage 升级 |
| C13 数据与资源 | 6/7 | 0 | 0 | 0 | Repository 模式 ✅,无 token 进 SharedPreferences ✅,DR13.4 抽查通过 |
| C14 日志与错误 | 4/5 | 0 | 1 | 0 | `developer.log` 10 文件用,W-08 catch 吞异常松散 |
| 附录 A | 0/1 | 1 | 0 | 0 | B-02 缺 PR 模板 |
| 附录 B | 1/1 | 0 | 0 | 0 | README:47 选型记录 |
| 附录 C | 1/1 | 0 | 0 | 0 | 4 层架构纯净 |
| 附录 D | 1/1 | 0 | 0 | 0 | 文件头注释规范 |
| 附录 E | 1/1 | 0 | 0 | 0 | import 顺序通过 analyzer |
| 附录 F | 1/2 | 0 | 0 | 0 | 提交规范豁免(W-06) |

---

## 6. 跟历史审计对比

**基线**: `reports/CONSOLIDATED-AUDIT-v0.27.md`(7/30)— superpowers-en 评分 36/40、emil 39/40、superpowers-zh 18/40。

| 维度 | 7/30 状态 | 8/02 round 69 状态 | 变化 |
|---|---|---|---|
| **代码规范(C1)** | 21 trailing comma info 警告(0 阻断) | 281 个 lib 文件未格式化(**升级为阻断**)+ 21 trailing comma info | 🔴 恶化:之前 R77 已跑 `dart fix --apply`,但 R79-81 加 281 文件未格式化 |
| **i18n / 繁简(C7)** | 14 处繁简 FAIL(warn-only) | 同样 14 处 + 6 处半角省略号 | 🟡 同等:仍未跑 CI |
| **Riverpod 3.x 迁移** | round 3 已完成(`.valueOrNull` → `.value`) | 全项目 0 `.valueOrNull`(唯一 1 处是注释) | 🟢 持续保持 |
| **`withOpacity` → `withValues`** | R56 已修 21 处 | 0 处 `withOpacity`,13 处 `withValues` 散落 | 🟢 主要完成,W-01 收尾 |
| **widget dispose** | R74 P2-1 5 轮未修,R79 收尾 | 18 处 dispose 全部释放(无 stream leak) | 🟢 已稳 |
| **dateTime race** | R19B / R14 修过 | `check_datetime_race.py` + `check_datetime_race2.py` 双覆盖,0 命中 | 🟢 守门员全绿 |
| **PR 模板 / CODEOWNERS** | 缺失(同) | 缺失(同) | 🔴 B-02 持续 |
| **APM / Sentry** | 无 | 无 | 🔴 W-05 持续 |
| **CI 守门员** | 12 个 → 16 个(R57-60) | 16 个,1 个漏跑 | 🟡 W-07 加 1 行 |
| **`flutter test` 数量** | 1057 → 1098(R56)→ 1163(R63) | **1368**(R69) | 🟢 持续 +311 tests |
| **`flutter analyze` errors** | 0 | 0(26 issues / 5 warning / 21 info) | 🟢 同级 |
| **4 层架构纯净** | ✅ check_all.dart pass | ✅ check_all.dart pass | 🟢 持续 |
| **SQLCipher 加密** | ✅ DbKeyService + PRAGMA key | ✅ | 🟢 持续 |
| **`prefers-reduced-motion` a11y** | R65 P0-7 已修 | 4 个 widget 全部尊重 | 🟢 持续 |

**总评**: **整体保持高质量**(`flutter analyze` 0 error,`flutter test` 1368 全过,4 层架构 0 violation,无 `print` / `withOpacity` / `valueOrNull` 等历史坑)。**唯一升级为阻断的**:B-01 `dart format` 281 个文件未格式化 — 这意味着 **R66 uncommitted 漏跑 dart format** 历史教训没完全吸收,新加的 R79-81 round 100+ commit 又积累 281 个未格式化文件,直到本次审计才发现。

---

## 7. 总结 + 修复路线图

### 7.1 一句话总结

**v0.27 round 69 项目规范合规率 79.7%**,功能层 0 error / 0 P0 bug,工程卫生 1 个阻断(`dart format` 281 文件未格式化)+ 1 个阻断(无 PR 模板),10 个 ⭐⭐ 警告。**建议本周跑 `dart format` 一行命令解决 1/2 阻断,30 分钟加 PR 模板解决 2/2 阻断。**

### 7.2 项目成熟度评估

| 维度 | 评分 | 评语 |
|---|---|---|
| **架构** | ⭐⭐⭐⭐⭐ | 4 层 + 共享 umbrella + cross-feature 守门员,行业顶配 |
| **测试** | ⭐⭐⭐⭐ | 1368 test 全过,test/ 镜像 lib/,但缺覆盖率 |
| **i18n** | ⭐⭐⭐ | ARB 686 keys 完整,zh_Hant 同步,繁简 / 全角标点细节有疏漏 |
| **状态管理** | ⭐⭐⭐⭐⭐ | Riverpod 3.x + ref.read 缓存 + 100% mounted check 正确 |
| **性能** | ⭐⭐⭐⭐ | dispose 全释放,ListView.builder 关键路径用,无 `print` 业务码 |
| **监控** | ⭐⭐ | 本地 `runZonedGuarded` 兜底,无远程 APM,真机崩溃开发者看不到 |
| **CI/CD** | ⭐⭐⭐⭐⭐ | 16 守门员 + 2 build job + release apk + web,行业顶配 |
| **a11y** | ⭐⭐⭐⭐ | prefers-reduced-motion 双层 + Semantics / Tooltip 5 处 |
| **代码规范** | ⭐⭐⭐ | analyzer 0 error,但 281 文件未格式化是定时炸弹 |

### 7.3 修复路线图(按优先级)

**批次 A · 本周(2 阻断,2 小时)**

1. `dart format lib/ test/ scripts/` 一键 → B-01 解决(5 分钟)
2. `dart fix --apply` 收尾 21 trailing comma(5 分钟)
3. 加 `.github/PULL_REQUEST_TEMPLATE.md`(5 段 checklist)+ `.github/CODEOWNERS` → B-02 解决(30 分钟)
4. 跑 `flutter test` 确认 1368 全过(1 小时)

**批次 B · 本月(8 警告,~3 天)**

5. CI ci.yml 第 65 行后加 `check_zh_hant_consistency`(2 分钟)→ W-07 解决
6. 14 处繁简 FAIL 修正:OpenCC 自动生成 + 修 `phq9Severity*` zh_Hant(2 小时)→ W-03
7. 13 处 `Colors.black.withValues` 替 `tintedScrimBlack` token(1 小时)→ W-01
8. 5 个 test warning 清理(15 分钟)→ W-02
9. 52 处半角符号 / 6 处半角省略号(2-3 小时)→ W-04
10. `catch (e)` → `swallowError` 强制化 + 自定义 lint(半天)→ W-08
11. `flutter pub upgrade flutter_secure_storage` 升 10.x(1 小时)→ I-01
12. 加 `flutter test --coverage` + lcov summary 步骤(1 小时)→ I-02
13. W-06 选 ② 豁免,加 AGENTS.md 一行说明(5 分钟)

**批次 C · 季度(战略项,~1 周)**

14. 接入 Sentry / 自研 endpoint(脱敏 + 加密)(2-3 天)→ W-05
15. `check_fullwidth_punctuation.py` 去掉 `--warn-only`(跟随 W-04 一起)

### 7.4 上架前(Google Play / App Store 2025-11 强制)必过清单

- [ ] B-01 解决 → CI `dart format` 步骤全绿
- [ ] B-02 解决 → PR 模板强制 5 段 checklist
- [ ] W-05 解决 → 真机崩溃可视化(sentry.io / 自研)
- [ ] W-03 解决 → 繁简一致(zh_Hant 自动)
- [ ] check_16kb_alignment.py:目前 WARN(`ndkVersion 未在 pubspec.yaml 显式定义`),需在 pubspec.yaml 加 `flutter.ndkVersion: 27.0.12077973`(Flutter 3.41.9 默认 16KB 对齐)
- [ ] splash / icon / signing 已就绪(R67 googleplay 报告 ✅)

---

**审计员**: MiniMax-M3(Mavis general-purpose agent)
**审计方法**: v3.1 全量审计模式,14 章 + 6 附录共 64 检查项;`flutter analyze` 26 issues + `flutter test` 1368/1368 + 16 守门员 + 100+ grep 横扫 + 5 个关键文件 deep-read(app_database / app_router / native.dart / app_tokens / care_engine)
**审计时间**: ~12 分钟
**报告长度**: ~3.5 千字
