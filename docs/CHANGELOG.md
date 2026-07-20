# 变更日志

> 格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [0.17.0] - 2026-07-17

### Changed
- **架构升级（Round 1-5）**：从 3 个 skill（emilkowalski / superpowers-en / superpowers-zh）调研出的可优化点全部落地

### Added (emil 动效)
- **AppTokens 动画 token**（A1）：补 4 个 curve 常量（curveStandard/curveDecelerate/curveAccelerate/curveDelight）+ emil 决策框架 doc 注释
- **CheckInButton 状态过渡**（A3）：AnimatedContainer 让背景色 + 圆角在 durNormal + curveStandard 下过渡；文字切走 AnimatedSwitcher fade + scale
- **streak 数字 TweenAnimationBuilder**（A6）：数字从 0 → N 平滑递增
- **go_router 3 类 page transition**（A2）：`_fadePage`（主导航 occasional）/ `_slideRightPage`（子页 slide-from-right）/ `_slideUpPage`（全屏深页 rare full-screen modal feel）
- **vent 列表 → 详情 Hero**（A4）：Hero(tag: 'vent-avatar-{id}') 头像"飞"过去
- **vent 空态 + 鼓励文案 fade + scale**（A8）

### Added (process)
- **跨 midnight 自动 refresh streak**（B3 design issue）：AppRoot 挂 midnight timer，00:00:05 自动 `ref.invalidate(streakSummaryProvider)`，避免 streak 跨日还显示昨日的值
- **nextMidnightRefresh 纯函数**：抽 top-level `@visibleForTesting`，跨月/跨年边界都正确处理
- **CareEngine 12 个 edge case test**（B5）：fire 3 态 + 4 个核心规则的边界（22:00 整点 / 周末 18:00 边界 / 36h + hour<10）

### Fixed (Riverpod 3.0 升级)
- **flutter_riverpod 2.6.1 → 3.3.2**：自动 retry + 指数退避、`Ref` 子类统一、`==` 过滤 StreamProvider
- **AsyncValue.valueOrNull → .value**（2 处）：
  - `lib/routing/app_router.dart:85` (profile 守卫)
  - `lib/presentation/pages/home/widgets/temp_medication_dialog.dart:65` (meds list fallback)
- **freezed 2.5.7 → 3.2.5**（Riverpod 3.x 依赖要求）

### Tests
- 516/516 pass（v0.16 491 → v0.17 +25）
  - 7 个 round 1 emil 动效 test（AppTokens + CheckInButton + vent empty state）
  - 6 个 round 4 midnight refresh test（跨月/跨年/buffer 边界）
  - 12 个 round 5 CareEngine test（fire 3 态 + 4 规则边界）

### Architecture
- 4 层架构纯度 + 一致性保持：check_all.dart 仍全过
- Riverpod 3.x 升级**冲击面极小**（项目 0 个 StateProvider / StateNotifierProvider / ChangeNotifierProvider / FamilyNotifier / AutoDispose*）
- B1（!mounted → ref.mounted）实际上**无法迁移** — Riverpod 3 的 `ref.mounted` 是 `Notifier` 特性，项目全用 `Provider`/`StreamProvider`/`ConsumerStatefulWidget`，不能直接迁移。保持 30+ 处 `!mounted` check

## [0.18.0] - 2026-07-18

### Added (P0 安全 / 隐私 / 稳定)
- **PII 安全日志**（`pii_safe_log.dart` `b046f13`）：release 模式 swallow 错误日志，dev 模式完整堆栈
- **树洞录音 AES-256 加密**（`4f2f196`）：录音文件加密存盘（`[16-byte IV][ciphertext]`），SQLCipher 之外的第二层保护
- **PII 数据导出透明告知**（`00fcfaa`）：vent 文字导出前弹 dialog 说明内容会被读
- **P0-2 4 层修复**（`4c69e91`）：`notification_service` 接受 entity，消除 domain → data 反向依赖
- **全局错误处理**（`a1aa700`）：`runZonedGuarded` 兜底 + 9 处 silent catch 改 `swallowError` 统一可观测性
- **P0-7 web 端阻断**（`ee72529`）：web 平台抛明确 PlatformException，不静默失败
- **P0-8 4 表查询索引**（`ee72529`）：`check_ins` / `medications` / `contacts` / `assessments` 加 `(user_id, timestamp)` 复合索引，N+1 显著减少
- **P0-13 step 0 法律同意 PopScope**（`ddb9009`）：首次进入 setup 拦截物理返回键，强制勾选同意
- **PIPL 3 份草稿文档**（`d9bae94`）：隐私政策 / 用户协议 / 数据收集说明

### Added (P1 UI/UX 体系)
- **LoadingSkeleton 统一**（`5b6f3c3`）：19 处裸 `CircularProgressIndicator` 替换为 3 形态骨架（fullScreen / card / Spinner）
- **EmptyState 通用组件**（`8d7b456`）：8+ 处空态文案 + 图标 + CTA 抽统一组件
- **radiusCell / radiusCellLg token**（`8d7b456`）：6+ 处硬编码圆角收口
- **dark mode token API**（`6366d3c`）：`AppTokens` 加 dark variant，8 处 widget 切换主题 token
- **MotionScheme 应用**（`296d623`）：3 widget 应用 emil 决策框架
- **WCAG contrast test**（`43695ee`）：color token 自动验证 4.5:1 / 3:1 对比度
- **home_page god-page 拆 5 widget**（`df0a394`）：header / streak / check-in / temp-med / vent-entry 各 1 文件
- **SnoozeManager 拆子 service**（`85d0253`）：从 `notification_service` 独立
- **core_providers 拆 3 文件**（`5610394`）：按职责 `core` / `service` / `vent` providers
- **repositories 按 feature 拆子目录**（`1a501ce`）：`data/repositories/{check_in,medication,contact,...}/`
- **5 层 umbrella 目录树重写**（`7b95d41`）：`core/data|shared|theme|routing|l10n` 物理分层文档化

### Added (P1 i18n / a11y)
- **i18n batch 1+2**（`befdbe5` `7ff087a`）：提取 16 个共用 string，23 处 widget 替换
- **P1-16 全角标点批量修复**（`731f975`）：173 处中文文案统一
- **P1-17 引号统一**（`24dcf81`）：英文 `'` → 中文 `''`
- **P1-19/P1-20 a11y 文档化**（`43695ee`）：reduced motion / screen reader 行为说明
- **全局尊重 prefers-reduced-motion**（`0ad8e79`）：检测系统级动效偏好自动禁用
- **港澳台/国际区号扩展**（`388ce92`）：`phone_validator` 支持 +852/+853/+886/+1/+44 等
- **联系人 banner 抽 widget**（`388ce92`）：`ContactListBanner` 通用

### Added (P1 数据层)
- **mood schema 4 维度**（`bf5b866`）：schemaVersion 6→7，`mood_entries` 加精力 / 睡眠 / 焦虑 3 列
- **user_profiles.lastCheckInAt live write**（`0412692`）：打卡后回写，失联检测不再用旧值
- **CareCopy 抽离**（`ee6cd3b`）：CareEngine 文案集中 1 处
- **删 setup 软提醒双推**（`ee6cd3b`）：之前 setup 完成后会推 2 条软提醒

### Fixed
- **MockSmsProvider/AliyunSmsProvider 显式 throw + UI banner**（`d62fa2f`）：失败不再静默
- **inject now param to SafetyWatchService.checkNow**（`c20261d`）：flaky test 修，测试时间可控
- **药名 hint 中性文案**（`8e0b98c`）：避免广告法风险

### Tests
- 565/565 pass（v0.17 491 → v0.18 +74）
  - `pii_safe_log_round18_test.dart`：release swallow 行为
  - `snooze_manager_round18_test.dart`：snooze 逻辑独立测试
  - `app_tokens_dark_round18_test.dart`：dark mode token 153 行覆盖
  - `check_all_round18_test.dart`：4 层 + cross-feature 检测回归
  - `care_engine_copy_round18_test.dart`：CareCopy 抽离回归
  - WCAG contrast 自动验证（4.5:1 / 3:1 边界）
  - vent encryption round-trip：加密 → 解密字节级一致

### Architecture
- **5 层 umbrella 落地**：`core/data|shared|theme|routing|l10n` 物理分层，`presentation → domain ← data` 方向不变
- **P0-2 vent-encryption 跨层落地**：data 层加密 + domain 层透明（`VentEntryEntity` 不暴露 IV）
- **dart format + dart fix 批量 cleanup**（`07b748b` `3f42cd7` `6800d72`）：28 个 trailing comma + 多处 prefer_const_constructors 一键净

## [0.19.0] - 2026-07-18

### Changed
- **v0.19 大文件拆分 + 架构违规修复**（`31c86f3`）：god-file 治理 + 反向依赖清除
  - `trend_page.dart` 1496→216 行，拆为 `trend_charts` / `trend_calendar` / `trend_summary` / `trend_utils` 5 文件
  - `assessment_page.dart` 794→570 行，提取 sparkline + question card → `assessment_widgets.dart`
  - `setup_page.dart` 1077→999 行，提取 `MedDraft` / `TemplateApplyResult` / `ConsentCheckRow` → `setup_widgets.dart`
  - 4 文件相对路径 import 统一为绝对 `package:` 路径
  - `pubspec.yaml` 移除未使用的 `freezed` / `json_serializable` 依赖

### Refactored
- **`setup_page.dart` 1000 行拆 7 文件**（`4cd0bf0`）：setup flow 按步骤拆 widget
- **`ComparisonCard` 提取到 `assessment_widgets.dart`**（`d5693e8`）：评估页 widget 收口

### Fixed (latent bugs)
- **`reminder_scheduler` 缓存 `DateTime.now()`**（`a435903`）：跨 await 阈值不一致修复（同款 v0.14 / v0.16 修过 3 次）
- **4 处 `setState` / 资源清理 bug**（`0971139`）：dispose 之前先取消 subscription
- **6 处 mounted 检查 + 错误处理 + 资源清理**（`7b7d516`）：widget 生命周期一致性
- **4 处空 catch 改 `swallowError`**（`2449a63`）：统一错误可观测性
- **`mood_dialog.dart` 修 context vs ctx async gap**（`31c86f3`）：`use_build_context_synchronously` 警告消除
- **`reminder_scheduler.dart` dynamic → MedicationEntity? 类型安全**（`31c86f3`）：去掉 dynamic
- **`vent_compose_page.dart` 移除 `dart:io` import**（`31c86f3`）：委托 `VentAudioStorage`

### Added (测试)
- **29 个测试文件补全 roundN 命名后缀**（`20bd10e`）：统一 `{module}_roundNN_test.dart` 命名
- **`notification_navigation` + `vent_audio_storage` 测试**（`0758894`）：service 行为 lock
- **`database_migration` 测试**（`dbeeaff`）：schemaVersion 1→8 全迁移路径覆盖

### Tests
- 702/702 pass（v0.18 565 → v0.19 +137）
  - rename 29 个测试文件（`20bd10e`）：纯命名整理，不改行为
  - `database_migration` 全 schemaVersion 路径覆盖
  - `notification_navigation` / `vent_audio_storage` service 行为 lock
  - `reminder_scheduler` + 6 处 mounted bug 回归
  - 配合文档同步 `AGENTS.md` 测试数 679 → 706（`17091e0`）

### Architecture
- **setup flow 模块化**：1000 行 `setup_page.dart` → 7 个独立 widget 文件
- **评估 widget 收口**：`ComparisonCard` 集中到 `assessment_widgets.dart`
- **5 层 umbrella 保持**：跨拆分不破坏 4 层架构
- **未使用依赖清理**：从 `pubspec.yaml` 删 `freezed` / `json_serializable`（实测 0 引用）

## [0.20.0] - 2026-07-18

### Changed
- **加密依赖迁移：encrypt → pointycastle**（`97476d5`）：encrypt 包自 2022 年停维，pointycastle 是其底层依赖且持续维护
  - `encryption_service.dart` / `crypto_service.dart` 重写：pointycastle AES-256-CBC + PKCS7
  - **加密格式完全兼容**：`[16-byte IV][ciphertext]` 格式不变，老数据可正常解密
  - `pubspec.yaml`：删 `encrypt`，加 `pointycastle: ^3.9.1`
  - 涉及 3 个文件 / 65+ / 61-

### Tests
- 702/702 pass（v0.19 702 → v0.20 0）
  - 无新增测试（依赖迁移靠现有 encryption round-trip 覆盖）

### Architecture
- **依赖健康度**：pointycastle 持续维护，encrypt 停维 4 年
- **零迁移成本**：加密 blob 格式不变，无需 schema 升级
- **依赖收敛**：少 1 个 transitive 依赖（encrypt 内部也用 pointycastle）

## [0.21.0] - 2026-07-20

### Changed
- **analyzer 全清 + dart fix + dart format**（`9c305ed`）：0 errors / 0 warnings / 43 info
  - 修 5 处 `implicit_this_reference_in_initializer`（`index.dart` 用 `late final` + constructor body）
  - 删 `setup_page.dart` 死 import `go_router`
  - 抽 4 处硬编码 string 到 ARB（`setup_step_welcome.dart`）
  - 修 stale `@override` on deleted `scheduleSoftReminder` in test
  - `dart fix --apply`：48 个 auto-fix（prefer_const_constructors / require_trailing_commas / prefer_function_declarations_over_variables）
  - `dart format`：39 个文件重排
  - 涉及 49 个文件 / 528+ / 265-

### Added (P0 性能 / 架构纯化)
- **N+1 query 修**（`eec9d9a`）：
  - DB 层加 `watchNormalCheckIns` / `getLatestNormalCheckIn` / `getLatestAssessmentTimestamp`
  - Services 用 DB query 替代全表 scan + Dart filter
  - Providers 复用缓存数据，不再每次 re-fetch
  - 删 `main.dart` 重复 `AppDatabase()` connection
  - 独立 async 用 `Future.wait` 并行化
- **Architecture purity**（`eec9d9a`）：
  - `care_copy.dart` 从 `shared/` 移到 `domain/logic/`（仅 domain 用）
  - `pii_safe_log.dart` 从 `shared/` 移到 `data/services/`（仅 data 用）
  - `notification_navigation.dart` 从 `data/services/` 移到 `routing/`（是 routing 逻辑）
- **P0 隐私 / UI / 同意 batch 1**（`94e0803`）：综合

### Added (P1 UX)
- **P1-21 中文本土化**（`2e24e7f`）：HUD 文案中文优化
- **P1-23 联系人同意**（`2e24e7f`）：添加联系人前弹同意 dialog
- **P1-24 userName nullable**（`2e24e7f`）：数据库列 nullable 化，无 userName 不阻塞 setup
- **P1-26 Dismissible**（`295d4b3`）：列表项滑动删除
- **P1-27 RefreshIndicator**（`295d4b3`）：下拉刷新统一组件

### Added (P2 / P3 polish)
- **P2 polish**（`b0b9757`）：snackbar token 收口 + streak 数字 tween + legal 文案同步
- **P3-1 主题切换淡入动画**（`419df9c`）：dark/light 切换时页面内容淡入过渡

### Added (L10N 全面化)
- **~125 个硬编码中文抽到 ARB**（`eec9d9a`）：`settings_page` 28 / `reminders_hub_page` 38 / `notification_status_card` 37 / `medications_list_widget` 20
- 中英 ARB 文件键对齐（各 108+ keys）

### Added (清理)
- **删 14 个一次性 migration scripts**（`eec9d9a`）：从 `scripts/` 物理删除
- **`vent_entry.dart` → `vent_entry_entity.dart`**（`eec9d9a`）：命名一致性，9 个 import 同步
- **`PRD-v0.1-draft.md` 从根目录移到 `docs/`**（`eec9d9a`）

### Fixed
- **Pubspec 版本号 → `0.21.0+1`**（`eec9d9a`）
- **Flutter 版本统一到 3.44.5**（`eec9d9a`）：pubspec / README / CI 三处对齐

### Tests
- 703/703 pass（v0.20 702 → v0.21 +1）
  - N+1 query 修回归测试
  - `Dismissible` / `RefreshIndicator` widget 测试
  - 主题切换淡入动画测试
  - 之前 1 个 pre-existing failure（`data_export` version mismatch）仍存在

### Architecture
- **4 层架构保持纯净**：`architecture purity` 仍 0 违规
- **L10N 双层分明**：presentation 走 `flutter_localizations`（`l10n/`），domain 走 `core/l10n/`
- **依赖健康度**：删未用 `freezed` / `json_serializable`（v0.19 净），`encrypt` 已迁 `pointycastle`（v0.20 净）

## [0.22.0] - 2026-07-20

### Fixed (round 28 — 三视角审视 P0 必修)
- **trend_calendar 6 处 dark mode silent bug**（emil-bug-01，`lib/presentation/pages/trend/trend_calendar.dart`）：v0.21 P1-5 修 dark mode 加 8 个 dynamic color getter，但 `_DayDetailCard` + `_EventRow` 漏了 6 处静态 `AppTokens.divider` / `AppTokens.textHint` / `AppTokens.textSecondary`。在 dark mode 下白底白字 silent bug。修：全部换成 `AppTokens.dividerColor(context)` / `textHintColor(context)` / `textSecondaryColor(context)`，去掉外层 `const` 让 BuildContext 可用
- **trend_calendar 跨日不刷新**（spen-bug-10，同文件）：`CalendarView` 原是 `StatefulWidget`，`_today = DateTime.now()` 在 field init 取一次永远不变；用户跨过 00:00:05 后 today 高亮 + `_selected` 仍指向昨天。修：改 `ConsumerStatefulWidget` + 在 build 加 `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild（跟 `medication_calendar_page.dart:44` 同款 fix）
- **\_StreakCounter listener leak**（emil-bug-03，`lib/presentation/pages/check_in/check_in_button.dart:152-160`）：之前 `didUpdateWidget` 每次 value 变化都 `_controller.addListener(() { setState... })` 匿名闭包但**没移除旧 listener**。controller 持有 N 个 listener，每次 tick 触发 N 次 setState → 指数级 rebuild 风险。修：抽 `_tickListener` 字段稳定引用，`initState` 注册 1 次，`didUpdateWidget` 复用同一 listener + 改 `_lastValue = _currentAnimated.round()`，`dispose` 移除
- **mood 5 评分无 Semantics wrapper**（emil-bug-04，`lib/presentation/pages/mood/mood_dialog.dart:215-248`）：5 个评分按钮无 `Semantics` 包装，TalkBack 读 5 个孤立"1 2 3 4 5"，精神心理患者辅助技术体验极差。修：外层 `Semantics(container: true, label: '情绪评分, 1 到 5 分制, 5 分最积极')` + 每按钮 `Semantics(button: true, inMutuallyExclusiveGroup: true, selected: ..., label: '$s 分, 已选')`
- **评估 ChoiceChip 4 选项无 group Semantics**（emil-bug-05，`lib/presentation/pages/assessment/assessment_widgets.dart:182-239`）：9 题 × 4 选项 = 36 个孤立读屏项。修：QuestionCard 外层 `Semantics(container: true, label: '评估题 $index: ${item.text}, 4 项单选, 当前: $selectedLabel')` 一次性念出题号 + 题文 + 当前选择

### Added (round 28 文档补完)
- **CHANGELOG 补 v0.18/19/20/21 整段**：v0.17 段后缺失的 4 个 minor version 段补全，50+ commit 按 P0/P1/P2 分组 + 测试数变化（491 → 565 → 702 → 702 → 703）

### Tests
- 703/703 pass（P0 修复未引入新测试，下个 round 加 regression）
- `flutter analyze` 0 issues

## [0.16.0] - 2026-07-17

### Changed
- **架构整理（Round 1-19）**：
  - 4 层架构纯度 + 一致性 合并到 `scripts/check_all.dart`（替代 2 个旧 script）
  - check_all 支持 `package: 绝对路径` + `../../ 相对路径` 两种 import 检测
  - 修了 `care_engine.dart` 用相对路径绕过 purity 检查的隐藏 bug — 切到 `NotificationSender` 抽象接口
  - 修了 18 个 unused import + 1 个 dead try/catch + 2 个 dead `// ignore` 块 + 1 个 dead `audioExists()` 方法
  - 修 4 个 Flutter 3.32+ `RadioListTile` deprecation（改用 `RadioGroup` 祖先）

### Fixed
- **Stream subscription leak**：树洞详情/撰写页 `_player.onXxx.listen()` 之前没存 subscription，dispose 没取消。修后存 `StreamSubscription?` 字段 + `dispose()` 取消
- **`vent_entry.dart` 死代码**：删 `audioExists()` + 误导注释 + `dart:io` import（实际不是仅做 path 拼接，是磁盘 I/O）
- **`safety_watch_service.dart` 死参数**：删 `EmailService? emailService` 构造参数（v1.0+ 占位，EmailService 整个在 production 没用）
- **文档同步**：
  - `SENDGRID_SETUP.md` 删 stale `fromEmail` 参数示例（构造函数早没这参数）+ 改 `to` 为手机号
  - `AGENTS.md` / `README.md` 同步 `check_all.dart` + `dart scripts/check_all.dart`（不用 `dart run`，会触发 `objective_c` build hook 失败）
  - `email_preview.dart` 修正 round 注释（之前写错 Round 13 → 实际 Round 12）

### Removed
- **`dio: ^5.7.0`** 依赖：清理后 `EmailService` 没有任何 `package:dio/dio` 引用
- **`EmailService` 中的 `Dio` 字段 + 未用 `html` 变量**
- **`EmailService` 的 `Medication?` drift row 参数**：改用 `MedicationEntity?`（domain entity），消除 domain → data 反向依赖
- **`scripts/check_domain_purity.dart` + `scripts/check_architecture_consistency.dart`**：合并到 `check_all.dart`
- **`scripts/debug_check.dart`**：占位文件

### Architecture
- **Domain 层严格 0 flutter / 0 drift / 0 data / 0 dart:io 依赖**（除 vent_entry 的 `audioPath` 字段类型用 String）
- **共享层使用度**：所有 `shared/` 工具至少被 2 层用（被 check_all 验证）

### Tests
- 471/471 pass（461 → 471：5 check_all + 3 streak unsorted + 2 assessment unsorted）
- 新增 `test/data/email_service_test.dart`（用 `MedicationEntity` 替代之前的 drift row）
- 新增 `test/scripts/check_all_test.dart`（5 个，验证 4 层架构检测 + 相对路径解析 + Windows path bug）

### Fixed (latent bugs)
- **`streak_calculator.dart` 隐式排序假设**：`calculate` + `shouldShowStreakBroken` 用 `.first` 假设 caller 传 DESC，调用方目前都传已排序数据（`watchAllCheckIns()` Drift orderBy DESC），但任何未来 caller 传未排序数据会算错 streak。加显式 sort + 3 个 unsorted input regression test
- **`assessment_comparison.dart` 隐式排序假设**：`fromRecords` 用 `.last` 假设 caller 传 ASC，同样的 fragility。修：先 sort 再取。加 2 个 unsorted input test
- **`medications_list_widget.dart` 多次 `DateTime.now()` race**：`_editRefill` 之前 3 次 `DateTime.now()` 算 initialDate/firstDate/lastDate，跨 midnight 时三者可能不一致（`reminder_scheduler.dart:97` v0.14 已有同款 fix）。修：先算 `now` 一次再复用
- **`trend_page.dart:36-39` field 初始化多次 `DateTime.now()`**：`_calendarMonth` 用 2 次 `.now()` 算 year 和 month，跨 midnight 边界可能 month 不一致（23:59 → 12，00:00 → 1）。修：抽成 `_initialCalendarMonth()` 静态方法算 1 次
- **`notification_service.dart` 2 个 cancel id 范围过窄**：
  - `cancelAllSnoozes` 之前 `[4000, 104000)` 范围，snooze id 公式 `4000 + medId * 1440 + minutes`，medId ≥ 72 漏 cancel
  - `rescheduleMedicationReminders` 之前 `[2000, 3000)` 范围，med reminder id 公式 `2000 + medId * 10 + i`，medId ≥ 100 漏 cancel
  - 修：范围都放宽到 200000+（covers medId 几万个，远超实际用户量）
- **`vent_audio_storage.dart` 文件名 collision 风险**：`newAudioPath` 之前只用 `DateTime.now().millisecondsSinceEpoch` 作后缀，同毫秒内录 2 段会文件名相同 → 后录的覆盖前录的。修：加 4 位 random suffix (`vent_{ms}_{rand4}.m4a`)，同毫秒冲突概率 1/10000

### Removed
- **`EmailTemplate.buildHtml()`**：60 行 HTML 模板，v0.6 改 mock 短信后整个 HTML 路径无生产调用
- **`test/domain/email_template_test.dart` 中的 `buildHtml` 测试**：自测死代码

### Final state
- `flutter analyze`: 0 issues（无 warning、无 error、无 info）
- 4 个 `RadioListTile` 迁移到 Flutter 3.32+ `RadioGroup` 祖先 API
- 88 个文件 `dart format` + `dart fix --apply` 一键 cleanup（229 fixes）
- `test/scripts/check_all_test.dart` 新增 5 个测试，覆盖 `package:chroniccare/` 绝对路径 + `../../` 相对路径检测
- 修 `check_all.dart` 潜在 Windows 路径 bug：`package:chroniccare/data/bar.dart` 的 rel 部分 `/` 没转 `Platform.pathSeparator`，导致 marker `\lib\data\` 匹配不上

### Fixed (round 19B — 第 8 轮 code review 新发现的 6 个 bug)
- **`notification_service.rescheduleRefillReminders` cancel range 过窄**：
  - 之前 `_refillBaseId + 1000` 范围，refill id 公式 `_refillBaseId + medId`（`6000 + medId`），medId ≥ 1000 漏 cancel
  - 修：范围放到 200000（同 round 19 medication reminder 的修法），覆盖 medId 几万个
  - 配套把 `_refillNotificationId` 改 `@visibleForTesting` 暴露成 `refillNotificationId` 便于测试
- **`reminder_scheduler.dart` 隐式排序假设**：`normalCheckIns.first.timestamp` 假设 `watchAll()` 返 DESC，drift orderBy 一改就 silent 算错
  - 修：显式 `normalCheckIns.sort((a, b) => b.timestamp.compareTo(a.timestamp))` 后再 `.first`
- **`safety_watch_service.dart` 隐式排序假设**：同款 `normalCheckIns.first.timestamp` 隐式 DESC。修：同上显式 sort
- **`assessment_reminder_service.dart` 隐式排序假设**：`assessments.last.timestamp` 假设 `watchAssessments()` 返 ASC（"最后"= list 末尾），drift orderBy 一改漏取最新评估
  - 修：用 `assessments.map((c) => c.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)` 显式找最新，不依赖 list 顺序
- **`scheduleRefillReminder` 多次 `DateTime.now()` race**：
  - 之前 2 次 `DateTime.now()`（fireAt 过期判断 + daysLeft 计算），跨 midnight 时可能用不同日期
  - 修：先 `final now = DateTime.now();` 一次，下面两处复用
- **`vent_compose_page._getAudioDuration` AudioPlayer leak**：
  - 之前 try 块内 `await player.setSource(...)` + `await player.getDuration()` + `await player.dispose()` 一气呵成；任一环节抛异常都直接走 catch，`dispose()` 不会跑 → AudioPlayer 资源泄漏
  - 修：把 `dispose()` 移到 `finally` 块，确保异常路径也释放

### Tests (round 19B)
- 478/478 pass（471 → 478：6 refill id range + 1 safety_watch unsorted data）
- 新增 `test/data/notification_service_round19b_test.dart`：6 cases 覆盖 refill id 公式 + cancel range 范围（medId=0/1/999/1000/10000/50000 都验证）
- 新增 `test/data/sort_assumption_round19b_test.dart`：1 case 用 unsorted 顺序插入 3 条打卡（5天前/3天前/1小时前），验证 SafetyWatch 取 latest = 1小时前（修前会取 5天前误报触发告警）

### Fixed (round 19C — 第 9 轮 code review 新发现)
- **`app_router.dart:110` 路由参数 unsafe parse**：
  - 之前 `int.parse(state.pathParameters['id'] ?? '0')` 处理 `/vent/detail/abc` 时 `int.parse('abc')` 抛 FormatException
  - 修：改用 `int.tryParse(...) ?? 0`，invalid id fallback 到 0（详情页会显示"找不到了"，不崩 app）

### Tests (round 19C)
- 486/486 pass（478 → 486：8 route param parsing 边界 case）
- 新增 `test/routing/route_parsing_round19c_test.dart`：8 cases 覆盖 `int.tryParse` fallback 行为（valid int / empty / 'abc' / mixed / negative / whitespace / null path param）

### Added (round 20 — 通知自检 + OEM 后台引导)
- **`NotificationService.pendingCount`**：返回当前待发通知数；plugin 抛 PlatformException 时返回 -1（web/desktop 平台）
- **设置页「通知与提醒」自检卡** (`NotificationStatusCard`)：
  - 状态显示：当前已排队的待发通知数（0 / N / 不支持三态）
  - **测试通知按钮**：点一下立即推一条，看到 = 通知工作正常
  - **查看已排队通知**：弹 dialog 列出所有 `pendingNotificationRequests` 标题
  - **国产手机后台引导**：折叠面板展开 5 大品牌（小米 / 华为 / OPPO / Vivo / 魅族）每家 2-3 步后台保活路径
  - `kIsWeb` fallback：web 端显示"通知功能仅在 Android/iOS 可用"，隐藏功能按钮

### Fixed (round 20)
- **国产 ROM 静默杀通知没用户可见信号**：之前 20:00 提醒失败只在 log 里 `developer.log`，用户根本不知道。加自检卡后用户能主动验证 + 看到"没有待发通知"立即知道要排查

### Tests (round 20)
- 491/491 pass（486 → 491：5 widget test）
- 新增 `test/presentation/notification_status_card_round20_test.dart`：5 cases 覆盖
  - mobile 模式显示完整 card
  - pendingCount 三种状态（5 / 0 / -1）的 UI 提示
  - 点"测试通知"按钮 → 调 `showNow` 推一条
  - 点刷新按钮 → 重新读 pendingCount

## [0.15.0] - 2026-07-15

### Added
- **树洞（Vent / 私密倾诉空间）**
  - 4 层架构落地：`VentEntryEntity` + `VentRepository` 抽象 + Drift 实现
  - 新表 `vent_entries`（schemaVersion 6，v5 → v6 迁移）
  - 支持文字 / 语音（m4a / aac）/ 混排三种记录形式
  - 录音用 `record` 5.2.0，播放用 `audioplayers` 6.8.1
  - 3 个页面：`/vent`（列表 + 长按删除）/ `/vent/compose`（文字 + 录音）/ `/vent/detail/:id`（详情 + 进度条）
  - audio 文件存 `app docs/vent_audio/`，DB 仅存路径（SQLCipher 整体加密）
  - 主页加"倾诉 🌲"入口按钮

### 设计原则（关键）
- **完全私密**：树洞不进入任何分析、趋势、评估、CareEngine、SafetyWatch
- **不触发任何通知**：即使内容含"想死"也不通知家人（保护"私密空间"信任）
- **文字 / 语音 至少一个**：否则 `ArgumentError` 拒绝保存
- **命名约定**：domain 实体 `VentEntryEntity`（避免与 drift `@DataClassName('VentEntry')` 冲突）

### Tests
- 462 cases pass（v0.14 430 → v0.15 +32）
- `test/domain/vent_entry_entity_round18_test.dart`（20 个实体：业务方法 / durationLabel / copyWith / 相等性）
- `test/presentation/vent_list_round18_test.dart`（6 个 widget：空状态 / 文字条目 / 语音条目 / 混排 / 长截断 / 多条目）

## [0.14.0] - 2026-07-15

### Added
- **续方管理**（`/settings/refills`）：集中看所有药物的续方状态
  - 顶部 4 统计：总药数 / 已设续方 / 提醒中 / 已过期
  - 列表按状态优先级排序（已过期 > 提醒中 > 已设 > 未设置）
  - 4 个状态徽章 + 颜色（绿/橙/红/灰）
  - 行点击 → 跳到 EditMedicationDialog
  - 入口：RemindersHub 续方卡的"管理续方"按钮 + settings page
- **评估历史独立页**（`/assessment/history`）
  - 顶部 3 卡统计：总评估 / 最近 PHQ-9 / 最近 GAD-7（带严重度色）
  - 折线图：每个量表 1 张 fl_chart，至少 2 次评估才画
  - 完整记录：倒序，每条带"上次对比 ↑↓ 分数"
  - 严重度标签：正常/轻度/中度/重度（按临床标准分档）
  - 空状态：友好提示 + "开始第一次评估"按钮
  - 入口：home_page 心理评估图标 + settings page
- **用药日历**（`/medication/calendar`）：医生视角的依从性热力图
  - 行 = 1 种在用药物，列 = 1 天（7/30/90 三档可切）
  - 颜色 = 打卡次数 / 期望次数：漏服/部分/100% 四档配色
  - 图例卡 + 顶部说明
  - 入口：settings page "用药" section
- **提醒中心**（`/settings/reminders`）：集中管理所有提醒
  - 5 张卡：每日打卡 / 用药 / 续方 / 周期评估 / 失联通知
  - 每张卡配 sheet 配置 + 状态徽章
  - 入口：settings page

### Fixed（4 轮审查 + 16 修）
- **路由顺序冲突**（Bug A）：`/assessment/history` 之前被 `/assessment/:id` 拦住，调整声明顺序
- **日期边界 raw math**（Bug B + 续方 + 推送文案）：用 `_daysUntilRefill` / `_daysBetween` 按"天"算，refill day 整天都算 in window
- **临床严重度分级**（Bug C）：PHQ-9 0-4/5-9/10-14/15-19/20+、GAD-7 0-4/5-9/10-14/15+（之前用百分比，错判 5 类）
- **严重度配色统一**（Bug D）：抽出 `severityStyle()` 一处定义，chart dot / history 圆圈 / chip / summary 4 处同源
- **代码重复**（Bug E）：删 3 处重复的 `_severity` / `_severityLevel`
- **续方统计色**（Bug F）：inWindow 黄色 / overdue 红色（之前都红）
- **用药日历 times=[]**（Bug G）：跳过无时间药的行 + 提示文案
- **用药日历 O(n·m·k) 性能**（Bug H）：预 group `Map<int, Map<DateTime, int>>`
- **chart 底轴 label 密度**（Bug I）：90 点 → 6 label
- **失联检测 now/inDays**（Bug J）：捕获一次 now + 按天算
- **推送文案 "还剩 X 天"**（Bug K）：用按天算法
- **评估 diff 跨量表**（Bug L）：`_findPreviousSameScale` 找同量表前一条
- **deep-link safety race**（Bug M）：独立 `_safetyRerunRequested` flag + `force: true`
- **续方图标同步**（Bug N）：icon 和文字同源
- **AppDatabase 泄漏**（Bug O）：try/finally + close()
- **lint 清理**：13 个文件的 unused imports / variable

### Changed
- **架构升级到 4 层**：`presentation → domain ← data`，domain 层 0 Flutter 依赖
  - `domain/entities/`：业务实体（MedicationEntity / CheckInEntity / ContactEntity / MoodEntryEntity）
  - `domain/repositories/`：抽象接口（无实现）
  - `domain/usecases/`：用例（RecordCheckInUseCase / RecordTempMedicationUseCase / TriggerReminderUseCase）
  - `domain/logic/`：业务规则（量表/streak/care engine/报告/评估对比）
- **数据层 0 Flutter 依赖**（mappers in data 层做 Entity ↔ Drift 转换）
- **Repository 模式**：UI 不直接碰 Drift，only 调 use case
- 通知 id 分段：1001=默认 / 2000+=药物时间 / 3000=软提醒 / 4000+=关怀
- `AppTokens.warningStrong` 新增（中度档专用色 0xFFFF8A65）

### Tests
- 430 cases pass（v0.13 ~400 → v0.14 +30）
- 4 轮全文件审查，每次新增 regression test 卡住 bug
- domain 业务逻辑 + data round-trip + presentation widget 三层覆盖

## [0.13.0] - 2026-07-14

### Added
- 多档案联系人（soft delete + 排序）
- 续方提前提醒 N 天
- 评估历史 + sparkline 在 result 页

## [0.12.0] - 2026-07-14

### Added
- 邮件通知 + 安全开关
- 临时吃药关联到现有药物
- 趋势页（30 天热力图 + 6 月柱状图）
- PHQ-9 抑郁量表
- 用药报告（PDF + Markdown）

## [0.8.0] - 2026-07-13

### Added
- **量表多选**：PHQ-9 + GAD-7 共用 `AssessmentScale` 抽象
  - `lib/domain/logic/assessment_scale.dart`（抽象 + `AssessmentItem` / `AssessmentResult` / `CrisisSignal`）
  - `lib/domain/logic/scale_registry.dart`（聚合 + byId 查询）
  - `lib/domain/logic/gad7.dart`（GAD-7 焦虑量表，7 题 0-3 分 0-21）
  - 评估页 `AssessmentPage` 改为接收 `scaleId` 参数的 `AssessmentRunner`
  - 路由：`/assessment` redirect 到 `/assessment/phq9`，`/assessment/:id` 通用
  - 设置页"健康"区改为量表列表（PHQ-9 / GAD-7）
- **量表历史折线图**（多线趋势 + Tooltip 详情）
  - `lib/domain/logic/assessment_record.dart`（从 `CheckIn` 反序列化）
  - `app_database.watchAssessments()` + `CheckInRepository.watchAssessments()`（filter phq9/gad7，正序）
  - `assessmentsProvider`（Riverpod StreamProvider）
  - 趋势页新增"心理评估历史" section（`LineChart` 多线 + 图例 + 空状态 + Tooltip 显示 `MM/DD HH:mm + 量表名 + 原始分/满分 + 百分比`）
- **测试**：86 tests pass（v0.7 是 57 → v0.8 加 29 个）
  - `test/domain/gad7_test.dart`（19 个：常量/接口契约/严重度切分/无危机）
  - `test/domain/scale_registry_test.dart`（4 个：聚合/byId/数据完整性）
  - `test/domain/assessment_record_test.dart`（8 个：合法/缺字段/损坏 JSON/type 过滤）
- **Web 加载修复**
  - CanvasKit 走 CDN（国内 `gstatic.com` 污染）→ `--no-web-resources-cdn` 走本地 `build/web/canvaskit/`
  - dev 模式（`flutter run -d chrome`）下 drift worker 404 → 切 `flutter build web` + `python -m http.server 8358` production 模式
  - 验证 `index.html` / `sqlite3.wasm` / `drift_worker.dart.js` 全部 200

### Changed
- `phq9.dart`：保留旧 `Phq9Item` / `Phq9Result` / `phq9Items` / `phq9Options` API（兼容），新增 `Phq9Scale` 实现抽象 + `phq9Scale` 单例
- `assessment_page.dart`：完全重写为通用 `AssessmentRunner`，接收 `scaleId` 渲染对应量表
- `app_router.dart`：路由参数化（`/assessment/:id`）

## [0.7.0] - 2026-07-12

### Added
- **SMS 服务抽象**（`SmsProvider` 接口 + `MockSmsProvider` + `AliyunSmsProvider` 占位）
- **多联系人通知循环** + `ReminderLevel` 渐进（none → 邮件 → 短信）
- **药物时间点 zonedSchedule 推送**（id 段 2000+，每个 med × 每个 time 稳定 id）
- **打卡反馈**（haptic + `AnimatedCelebration` + 动态鼓励文案按 streak 切换）
- **10am 软提醒**（漏 1 天主动 push 安慰，id 段 3000）
- **临时吃药关联到现有药物**（dropdown 选择已有药 / 自由输入）
- **数据导出/导入**（JSON 剪贴板，v0.7 不加密，v1.0+ 上加密备份）
- **CareEngine 规则引擎**（4 种触发：`secondDayMissed` / `lateCheckInHabit` / `weekPerfect` / `none`）
- **LocalAiHook 接口**（MedGemma 1.5 接入点预留，v0.8+ 真实集成）
- **PHQ-9 抑郁量表**（9 题 0-3 分 0-27，第 9 题自杀念头阳性 → 危机资源对话框）
- 通知 id 分段：1001=默认提醒 / 2000+ 药物时间 / 3000=软提醒 / 4000+=关怀
- 测试 57 个（v0.6 基础上加 13 个 PHQ-9 + CareEngine）

### Changed
- 主页 UI 升级：动态鼓励文案 + 临时吃药按钮 + 吃药时间展示
- 首次引导 step 2：药物时间点 picker（多 time）
- 趋势页完整化（之前只有汇总 → 加热力图 + 柱状图）

## [0.6.0] - 2026-07-12

### Added
- **多联系人邮件通知**（SendGrid Mock 实现，按 sortOrder 顺序发送）
- **失联检测 v0**：48h 未打卡 → 邮件（v0.7 改为 CareEngine 规则驱动）
- **趋势页 v0**：数据汇总 + 30 天热力图 + 6 月柱状图 + streak 总结
- 设置页增加联系人增删改

## [0.5.0] - 2026-07-12

### Added
- **极简 MVP**：主页打卡 + 设置 + 首次引导（两步）
- **drift 本地数据库**（`check_ins` / `medications` / `contacts` / `user_profiles` 四表）
- **go_router 路由**（`/setup` + ShellRoute `/` `/settings`）
- **Riverpod 2.6** 状态管理（`checkInRepositoryProvider` / `contactsProvider` 等）
- **flutter_local_notifications** 集成（每日 20:00 通用提醒，v0.7 加 zonedSchedule）
- **flutter_dotenv** 配置加载
- **fl_chart** 集成（v0.6 趋势页使用）
- 设计 Token 体系（`AppTokens`）：spacing / radius / fontSize / breakpoint

## [0.1.0+1] - 2026-07-11

### Added
- Day 1：项目骨架
  - `pubspec.yaml`（12 个核心依赖 + 7 个 dev 依赖）
  - `analysis_options.yaml`（strict-casts / strict-inference）
  - `.gitignore`
  - `lib/theme/app_tokens.dart`（设计 Token 规范）
  - `lib/theme/app_theme.dart`（Material 3 主题）
  - `lib/l10n/strings.dart`（国际化字符串）
  - `lib/main.dart`（入口）
  - `lib/app.dart`（App 根 + go_router 占位）
  - `README.md`
  - 本 CHANGELOG
- 完整 PRD v0.4、设计规格、设计 Token、实施 Plan

### Pending
- Day 2-7：业务逻辑、UI、邮件集成、Web 部署
- Day 8-9：SendGrid 真实集成
- Day 10-11：APK + iOS 打包
- Day 12-14：上架准备
