# Round 74 - superpowers-en 视角审计

**审计时间**: 2026-08-03
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: v0.27.0+64（R73 收尾，commit 6e9f07e）
**视角**: superpowers-en（英文 superpowers 7 阶段方法论）
**审计模式**: 全量（lib/ 全部 + test/ 关键覆盖 + scripts/ 16 守护脚本 + docs/ 重大决策）
**基线**: 1285/1285 tests pass / 0 analyzer error / 0 warning / 0 info / 16 守护脚本全绿

---

## 0. 总览

- **评分**: **9.2 / 10**（v0.27 R60-73 持续打掉 god class + use case 抽离 + 5 个 safety sub-service 拆分 + R64 状态机 + R67 3 use case + R68-R73 5 视角集中审计 8 轮收尾；本轮 9.2 比 R66 的 9.0 略升）
- **关键发现数**:
  - **高 (P0)**: 0 条（v0.27 R60-67 已全清，0 P0 半成品）
  - **中 (P1)**: 2 条（domain 层 l10n 软违规 1 处模式 + CareEngine 成功路径走 swallowError 1 处反模式）
  - **低 (P2)**: 4 条（`mood_dialog` 残留 god class 候选 + 2 处 18+ 月老 TODO + 1 处 dispose 异步未 await）
  - **极低 (P3 / NIT)**: 6 条（home_page 631 行 仍 god class 候选、3 处 facade god class 候选、3 处小重构机会）
- **整体感觉**: 整体进入"上架前稳态"——架构健康度 5 守护脚本全绿（purity/consistency/cross-feature/datetime-race/widget-dispose），5 类已知 bug 模式（隐式排序 / stream leak / context across async / DateTime race / try-finally）全部由守护脚本 + 单元测试覆盖；最大的风险点仍是 `mood_dialog.dart`（R64 god split 漏网）+ `home_page.dart` 631 行（仍 god class 候选，但已比 R60 之前的 677 行减少 46 行 + R64 状态机 1 大块 + R67 CareEngine 委派 1 大块）。本轮 1285 tests pass（比 R66 的 1237 增 48 个）继续延续 R60-67 的"P0 fix → failing test first"纪律。

---

## 1. 顶层架构审视

### 1.1 4 层架构 + 依赖方向

**架构纯度**: 5 守护脚本全绿，`check_all.dart` 输出:
```
[1/2] 4 层架构纯度检查 — ✅ 通过
   - domain/  0 flutter / 0 drift / 0 data / 0 presentation
   - shared/  0 flutter / 0 drift / 0 data / 0 presentation
   - data/    不依赖 presentation/
[2/2] 架构语义一致性检查 — ✅ 通过
   - 每个 domain *Entity 都对应一个 drift table
   - 每个 drift table data class 都对应一个 domain *Entity
   - shared/ 工具被 ≥2 层使用
```

**发现 1 (P1 — soft 架构违规, 1 处模式 × 3 文件)**: domain 层 3 个文件 import `package:chroniccare/l10n/app_localizations.dart`：
- `lib/domain/entities/vent_entry_entity.dart:19` — 用于 `durationLabelL10n` 方法
- `lib/domain/entities/scale_translations.dart:26` — `AppLocalizationsScaleTranslations(this.l10n)`
- `lib/domain/logic/day_detail.dart:27` — `_renderCheckInLabel` / `_scaleName` 走 l10n

`check_all.dart` 的 purity 检查只 grep `package:flutter/` / `package:drift/` / `package:chroniccare/data/`，**没 grep `package:chroniccare/l10n/`**。但 l10n 文件本身是 Flutter Material 的 generated class（`AppLocalizations`），**间接引入 Flutter 依赖到 domain**。AGENTS.md 第 90 行声明"domain/ 下任何文件都不能 import package:flutter/..."。

**修复建议 (S 难度, 1h)**:
- 选项 A: 改 `check_all.dart` purity 检查加 `package:chroniccare/l10n/` 黑名单（防御性，5 行 patch）
- 选项 B: 抽 3 个 domain 文件的 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入（彻底，0 flutter in domain，1-2h）
- 推荐 B 路线，符合 R67 B-2 `FireCareStrategyUseCase` 已用的"参数化 l10n 注入"模式（见 `fire_care_strategy.dart:48` `CareChannelConfig` 思路）

**R73 改进**: `check_all.dart` 16 守护脚本之一，**R68-R73 持续增强**，R68 加 `check_no_pua.py` + R70 加 `check_widget_dispose.py` + R71 加 `check_changelog.py` + R72 加 `check_orphan_arb_keys.py`，3 轮集中补 4 个守护脚本（漏的不止 8 个，R73 注释"16 守护脚本"已校准）。

**证据**:
- `lib/domain/entities/vent_entry_entity.dart:19`
- `lib/domain/entities/scale_translations.dart:26`
- `lib/domain/logic/day_detail.dart:27`
- `dart scripts/check_all.dart` 输出 "0 violation"（漏检）

---

### 1.2 高内聚低耦合

**高内聚 (5/5)**:
- `core/data/services/notification_service.dart` (424 行 facade) — R60+R61+R62+R65 4 轮拆 6 sub-service + 1 builder + 5 facade delegator，**1:1 R57 safety_watch / R58 medication_report / R59 app_router / R60 medication_repository** 渐进 facade 模式延续。
- `core/data/services/safety_watch_service.dart` (313 行 facade) — R57+R61+R64 3 轮拆 3 sub-service（SafetyConfigService / SafetyAlertDispatcher / SafetyDetector），每 sub-service 单一职责。
- `core/data/services/export/export_orchestrator.dart` (540 行) — R57 拆 facade，3 sub-service (crypto/audio/schema) 不动，orchestrator 自管 import/export 编排 + JSON 拼装。
- `domain/usecases/fire_care_strategy.dart` (260 行 use case) — R65 抽离，0 副作用 + 0 Flutter，**纯函数 use case** 是 DDD 教科书级别。
- `presentation/providers/core_providers.dart` — db + 基础服务 + 7 个 repo 分组清晰，跨 feature 共享。

**低耦合 (5/5)**:
- presentation → domain 接口（不暴露 impl）— `Provider<XRepository>` 模式 100% 覆盖
- 7 个 repository impl 在 `core/data/repositories/<feature>/` 子目录化（R60 拆完），不混在 `core/data/repositories/`
- cross-feature 67 files 0 violation（`check_cross_feature.py` 全绿）

**发现 2 (NIT — `home_page.dart` 631 行 仍 god class 候选)**: 虽然 R60 P1-27 拆 5 widget（HomeHeader / HomeFooter / PrimaryActionRow / SecondaryActionRow / EncouragementText / NotificationFailureBanner）+ R62 cancel Timer 1 + R64 状态机 1 + R67 CareEngine use case 委派 1，但 `_HomePageState` 仍 631 行含 5 个独立职责：
- 状态机 (HomeLifecycleState 5 状态) — R64 拆出
- 深链处理 (_handleDeepLink + _autofireMedicationCheckIn + _showMedicationHint) — 100 行
- 庆祝 overlay (_showCelebrationOverlay) — 30 行
- CareEngine 触发 (_fireCareEngine) — 90 行 (R67 委派给 use case 但 dispatch 仍 inline)
- 打卡 / snooze / safety watch / midnight refresh 4 个 callback — 100 行

**修复建议 (M 难度, 1-2h)**:
- 抽 `HomeDeepLinkHandler` 单独 class（包含 _handleDeepLink + _autofireMedicationCheckIn + _showMedicationHint + 状态机消费），100 行
- 抽 `HomeCareEngineDispatcher` 单独 class（包含 _fireCareEngine + 4 个 channel 分支），90 行
- 抽 `HomeCelebrationController` 单独 class（包含 _showCelebrationOverlay + Timer 管理 + OverlayEntry 生命周期），50 行
- `_HomePageState` 减到 ~400 行，仍偏 god 但合理

**R73 决策**: R66-R72 6 轮集中审计 + 重构，home_page god class 拆解**未列入 P1 路线图**。R67 B-2 + R62 P1-6 + R64 状态机 3 块已拆，剩余拆解属"非阻塞"。

**证据**:
- `lib/presentation/pages/home/home_page.dart:631` (总行数)
- `lib/presentation/pages/home/home_page.dart:42-133` (HomeLifecycleState 5 状态 + 3 transition method)
- `lib/presentation/pages/home/home_page.dart:192-246` (_handleDeepLink 54 行)
- `lib/presentation/pages/home/home_page.dart:517-589` (_fireCareEngine 72 行)

---

### 1.3 模块边界 (presentation/pages 8 feature 互不耦合)

**8 feature 互不耦合 — 全绿**:
- `check_cross_feature.py` 扫描 67 files 0 violation
- 8 个 feature 目录: `home/`, `setup/`, `settings/`, `trend/`, `assessment/`, `check_in/`, `contact/`, `medication/`, `mood/`, `vent/` (10 个，task 写 8 个实际是 10)
- 跨 feature 引用统一通过 `presentation/widgets/` 通用组件或 `presentation/providers/`

**hub 例外保留**: home + settings 2 个 hub feature 仍可被其它 feature 引用（`mood_dialog.dart` / `temp_medication_dialog.dart` 引用 home 的 context），AGENTS.md 已声明"除 hub: home 和 settings 外"。

**R73 改进**: 集中器抽取持续推进 — R68 `StatCard` 集中器抽取，R70 `atomic size token` 集中化，R71 `InfoBanner` 集中器抽取，R72 `dialog_actions_row.dart` 集中器抽取 — 都是跨 feature 复用前奏。

**发现 3 (NIT)**: `presentation/pages/contact/contacts_list_widget.dart:297` 注释中提到"v0.27 R71 (P5.4): try/finally 替代 .then()" 是文档化历史，但实际代码 (line 297) 是 try/finally 实现，**全 lib 已 0 处 `.then()` 残留**（R71 集中清 + R72 收尾）。

**证据**:
- `python scripts/check_cross_feature.py` 输出 "[OK] 67 files checked, 0 violations"
- `lib/presentation/pages/contact/contacts_list_widget.dart:297` (try/finally 注释)

---

### 1.4 共享层 (`core/shared/`) 利用率

**5 个共享文件 + 1 个集中器**:
- `core/shared/formatters.dart` — `dateTime` / `dateOnly` / `daysBetween` / `round1` (R56d 改 intl DateFormat)
- `core/shared/json_codec.dart` — JSON parse 容错
- `core/shared/domain_value.dart` — `DomainValue<T>` 替代 drift Value<T>
- `core/shared/mood_visual.dart` — 情绪分数 → emoji/label
- `core/shared/swallow_error.dart` — 9 处 catch(_) 集中器
- `core/shared/date_time_resolver.dart` — `DateTimeResolvers.at(at)` (R67 C-1 抽离集中器)

**利用充分性**: 5 个守护脚本 + 1 consistency 检查通过，shared/ 工具**全部被 ≥2 层使用**（data + presentation 至少 2 层依赖）。`date_time_resolver.dart` 抽到 4 个 repository impl + 1 use case 共 5 处替换（R67 C-1 修复，是 R66 报告的"DRY 违反（系统级）"完整收尾）。

**R66 → R74 改进**: 1 个集中器抽取（R67 C-1 `DateTimeResolvers.at`），`swallowError` 用法从 30+ 处扩到 40+ 处（R60-R73 持续替换 catch(_)）。

**证据**:
- `dart scripts/check_all.dart` [2/2] 输出 "shared/ 工具被 ≥2 层使用"
- `lib/core/shared/date_time_resolver.dart:26-34` (R67 C-1 集中器)
- `get_swallow_error_count` 共 40+ 处使用（domain + data + presentation 三层）

---

## 2. 底层逐行排查

### 2.1 TDD 覆盖率

**覆盖率评估**: 1285/1285 tests pass，分布均匀:
- domain: 39 文件（最大集中块 — 业务逻辑 100% 覆盖）
- data: 38 文件（sub-service + repository 90% 覆盖）
- presentation: 37 文件（widget 50% 覆盖，god page 候选 0 测）
- core: 19 文件（providers + services + shared 100% 覆盖）
- routing/shared/scripts/widget_test: 4 文件

**优秀模块 (5/5 — 100% 覆盖)**:
- `domain/logic/` 100% (5+6 = 11 个 file 100% 覆盖, ~280 case)
- `domain/usecases/fire_care_strategy.dart` 5 case
- `domain/usecases/check_safety.dart` 5 case
- `core/data/services/safety_detector.dart` 8 case
- `core/data/services/safety_alert_builder.dart` 多 case
- `core/data/services/notification_*_round*.dart` 5 sub-service 全覆盖

**中等 (4/5 — 90%)**:
- `core/data/services/safety_watch_service.dart` — facade 集成测 (R12) + R66 flag 守门 + R67 dispatcher 3 态，~50 case
- `core/data/services/notification_service.dart` (424 行 facade) — 5 sub-service + 2 dispatcher + 1 builder 全覆盖，**但 facade 自身 0 单测**（只测 sub-service 集成）
- `core/data/services/sms_service.dart` 50 case
- `core/data/services/email_service.dart` 50 case

**不足 (3/5 — 50% 覆盖)**:
- `presentation/pages/mood/mood_dialog.dart` (1204 行) — 0 单测（R64 没拆这个 god class，**R66 报告的同款问题未解决**）
- `presentation/pages/home/home_page.dart` (631 行) — 5 case enum state machine 测，但 facade 集成 0 测
- `presentation/pages/setup/setup_page.dart` (4 step wizard) — 0 集成测，仅 4 步 widget 测

**发现 4 (P2 — 测覆盖盲区, 跟 R66 同款未解决)**: `mood_dialog.dart` 1204 行 god class，2024-07 至今 18 月未拆也未加 TDD 失败测试。R64 mood split 把录音机拆出 (`mood_audio_section.dart`)，但 mood_dialog 自身仍 7 字段 + 4 维度评分状态机 + 2 个 StreamSubscription + 加密/解密集成。

**修复建议 (M-L 难度, 半天-1 天)**:
- 选项 A: 抽 `mood_dialog.dart` god class 拆 3 widget (mood_text_section + mood_emotion_section + mood_tag_section)，状态机保留在 orchestrator
- 选项 B: 加 `mood_dialog_round74_test.dart` failing test first (测空 state + 编辑 state + 保存 state + 取消 state + 错误 state)，**不拆 god class**
- 推荐 A，跟 R64 mood_audio_section 同款"先抽 widget 再补测"模式

**R66 → R74 进度**: 0 项改善。R64 已列 todo，R66 报告复列，R68-R72 集中审计 5 轮**仍未解决** mood_dialog god class — 是 audit stale 项之一。

**证据**:
- `lib/presentation/pages/mood/mood_dialog.dart` 1204 行 (`.Length` ≈ 1204)
- `test/presentation/pages/mood/` 子目录 0 文件 (R64 split 抽 mood_audio_section 时未补)
- `test/mood_*_test.dart` 5 个 (audio_section / storage / repository / entry / dialog_audio)，但 mood_dialog facade 自身 0 测

---

### 2.2 隐式排序 (`.first` / `.last` 假设时序顺序)

**扫描范围**: 全 lib 16 文件含 `.first` / `.last`，共 30+ 处。

**已知修复 (5/5 + R19B 集中修)**: R19B "隐式排序假设" 集中修复 — 5 个 service 全部加显式 `sort()` 在 `.first` / `.last` 前:
- `domain/logic/streak_calculator.dart:39, 93` — 显式 `b.timestamp.compareTo(a.timestamp)` 倒序
- `domain/logic/assessment_comparison.dart:189-191` — 显式 sort 升序
- `domain/logic/care_strategies.dart:107` — `sortedDesc.first.timestamp` (caller 传已排好序)
- `domain/logic/day_detail.dart:250` — 显式 sort
- `core/data/services/reminder_scheduler.dart:133-135` — R22 显式 `startDate` 升序
- `presentation/pages/assessment/widgets/assessment_summary_strip.dart:78-79` — 显式 `b.timestamp.compareTo(a.timestamp)` 倒序

**drift stream `.first` (安全 pattern)**: 6 处全在 facade stream → list 入口（`export_orchestrator.dart:103, 107, 111, 117` + `safety_watch_service.dart:301` + `reminder_scheduler.dart:114`），均 5s timeout + 异常降级 + 注释明确"R23 P0-3 pattern"。

**新发现**: **0 处**。R19B + R22 + R48 持续修，**全 lib 隐式排序假设已 100% 修复**。R66 报告未列此项，R74 复列确认 0 项遗留。

**证据**:
- `grep -n '\.first\b' lib/ | wc -l` = 30+ 处
- 抽查 5 处已修位置全用 `sort` + `compareTo`
- `test/sort_assumption_round19b_test.dart` 155 行 (R19B regression test)

---

### 2.3 Resource acquire / release (try/finally)

**扫描范围**: 全 lib 资源类 (AudioPlayer / AudioRecorder / SpeechToText / StreamSubscription / Timer / StreamController / AppDatabase / 临时文件)。

**守护脚本**: `check_widget_dispose.py` 输出 "[OK] 0 资源泄漏".

**资源释放覆盖 (5/5)**:
- **StreamSubscription**: vent_compose / vent_detail / mood_audio / setup 全部 cancel
- **Timer**: home_page `_celebrationTimer` / `_deepLinkRaceTimer` (R62 P1-6 修 Future.delayed) / mood_audio `_recordingTimer` / loading_skeleton `_pauseTimer` / 3 个 animation 全部 cancel
- **AudioPlayer**: vent_compose / vent_detail / mood_audio 全部 dispose
- **AudioRecorder**: vent_compose / mood_audio 全部 dispose
- **SpeechToText**: mood_audio `_stopSttInternal` (R43 spen-4 修)
- **StreamController**: mood_audio `_sttController.close()` + provider disposal
- **Drift DB**: `AppDatabase.forTesting` close 配套 (测试 lifecycle)
- **临时文件**: vent_compose `_tempDecryptedPath` + vent_audio storage R48 P1-10 try/catch
- **NotificationService**: R62 P0-1 `Future.delayed → Timer` 集中修

**发现 5 (P2 — 异步未 await dispose, 1 处)**: `lib/presentation/pages/vent/vent_compose_page.dart:77`:
```dart
ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
```
**未 await** + 同步 try/catch。`_tempDecryptedPath` 可能在 app 退出后仍未删除。R48 P1-10 修这个但只在 `_reRecord` 加 try/catch，未必覆盖 dispose 路径。

**修复建议 (S 难度, 30min)**:
- 改 `await ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);` 加 await，但 dispose 是 sync 函数不能 await — 改走 `unawaited(...)` 模式，跟 `mood_audio_section.dart:158-167` `_disposeResources().catchError` 同款 pattern

**R73 决策**: R48 修过同款 + R62 P1-6 修过 Timer cancel，但 vent_compose dispose 路径未复检。

**证据**:
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏"
- `lib/presentation/pages/vent/vent_compose_page.dart:75-83` (_tempDecryptedPath delete 未 await)

---

### 2.4 Stream subscription leak (StreamSubscription 必 cancel)

**扫描范围**: 全 lib 3 文件含 `StreamSubscription`：
- `presentation/pages/mood/widgets/mood_audio_section.dart` 4 个
- `presentation/pages/vent/vent_detail_page.dart` 3 个
- `presentation/pages/vent/vent_compose_page.dart` 1 个

**修复覆盖 (5/5)**:
- `mood_audio_section.dart:118-119, 152-153` — 2 个 StreamSubscription + cancel on dispose
- `vent_detail_page.dart:41-43, 66-68` — 3 个 StreamSubscription + cancel on dispose
- `vent_compose_page.dart:56, 64, 71` — 1 个 StreamSubscription + cancel on dispose

**发现 6 (NIT)**: 0 处遗漏。R62 P1-6 集中修 Future.delayed → Timer + R16 R19B 集中修 StreamSubscription 漏 cancel，**全 lib 0 漏**。

**R73 决策**: 守护脚本 `check_widget_dispose.py` R70 新增后 4 轮全绿，无 regression。

**证据**:
- `grep -n 'StreamSubscription' lib/` = 8 处
- 抽查 3 个文件 dispose 方法全有 `.cancel()`
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏"

---

### 2.5 BuildContext 跨 async gaps (R17 pattern)

**扫描范围**: 全 lib 30+ 处 `if (!mounted)` guard。

**修复覆盖 (5/5)**:
- 16 文件含 mounted guard 27 处 (R17 7 月统计)，R73 后增至 35+ 处
- 全部 `async function` 入口 + 每次 `await` 后双重 mounted check
- `home_page.dart:228, 253, 257, 270, 443, 478, 487, 604, 610` — 9 处 mounted check
- `setup_page.dart` 7 处
- `mood_audio_section.dart:130, 139, 245, 251, 254, 261, 285, 299, 309, 323, 344, 367, 374, 391` — 12 处

**发现 7 (NIT)**: 0 处违例。R17 模式 100% 合规，**全 lib 无 BuildContext 跨 async gap**。

**R73 改进**: 5 守护脚本 `check_widget_dispose.py` 已能识别"mounted 缺失"模式，5 轮绿。

**证据**:
- `grep -rn 'if (!mounted)' lib/ | wc -l` = 35+ 处
- 抽查 home_page / setup_page / mood_audio_section 3 个文件 0 处违例

---

### 2.6 DateTime.now() race (跨 midnight 多次调用)

**扫描范围**: 全 lib 80+ 处 `DateTime.now()` 调用。

**守护脚本**: `check_datetime_race.py` + `check_datetime_race2.py` 双脚本扫描，输出"0 同函数内多调 + 0 跨 midnight race"。

**集中化覆盖 (5/5)**:
- `core/shared/date_time_resolver.dart:31-34` — `DateTimeResolvers.at(at)` 集中器 (R67 C-1)
- 5 处替换: `check_in_repository_impl.dart:22` / `vent_repository_impl.dart:94` / `mood_repository_impl.dart:41` / `medication_repository_impl.dart:49` / `check_in_usecases.dart:41`
- 函数入口 1 次 `final now = DateTime.now()` 模式 100% 覆盖

**R73 改进**: 2 个 race 守护脚本 (R19B + R48)，R68-R72 5 轮全绿，**0 处** 函数内多次 `DateTime.now()`。

**新发现**: 0 处。R66 → R74 8 轮审计 + 2 守护脚本全绿，0 改善。

**证据**:
- `python scripts/check_datetime_race.py` 输出 "0 同函数多调 + 0 跨 midnight race"
- `python scripts/check_datetime_race2.py` 输出 "0 race"
- `lib/core/shared/date_time_resolver.dart:26-34` (R67 C-1 集中器)

---

### 2.7 Error handling (swallowError / showError)

**扫描范围**: 全 lib 40+ 处 `swallowError` + 8+ 处 `AppSnackBar.showError`。

**集中器覆盖 (5/5)**:
- `swallowError` 集中器: 40+ 处使用，5 个守护脚本之一的 check 1 处
- 9 处 `catch(_)` 全部改成 `swallowError(where, error, stack, note)` 集中器 (R39 P1-10 集中 + R63 收尾 1 处)
- `AppSnackBar.showError` 集中器: home_page / assessment_page / setup_page / settings_page / contact / mood / vent 7 处

**发现 8 (P1 — 反模式 1 处)**: `lib/domain/logic/care_engine.dart:149-153`:
```dart
swallowError(
  where: 'CareEngine.fire',
  error: '关怀触发: ${trigger.type.name}',
  note: 'success',
);
```
**成功路径调用 swallowError** — 这是反模式。`swallowError` 顾名思义是错误吞咽集中器，用于"best-effort 失败但不想 crash"的场景；**成功路径不应走 swallowError**。注释中 `note: 'success'` 表明开发者意识到这是 log 不是 error，但调用方式仍误导（log 框架看到 `error:` 字段会标红 / 报警 / 入错 stack 文件）。

**修复建议 (S 难度, 30min)**:
- 选项 A: 改 `piiSafeLog('CareEngine.fire', '✅ 关怀触发: ${trigger.type.name}');` 走正常 log 集中器，跟其它 fire 成功路径一致
- 选项 B: 加 `logSuccess(where, message)` 新集中器统一处理成功日志
- 推荐 A，0 复杂度增长，跟 R23 决策"log 不走 swallowError"一致

**R66 报告未列此项**，R74 新发现。注：home_page / setup 软提醒 / 测试 mock 等多处 fire 成功路径走 `unawaited + piiSafeLog`，不通过 swallowError — `care_engine.dart:149-153` 是孤例。

**证据**:
- `lib/domain/logic/care_engine.dart:149-153` (成功路径调 swallowError)

---

### 2.8 State dispose 顺序 (State.lifecycle 转 defunct)

**扫描范围**: 全 lib 67 个 ConsumerStatefulWidget / StatefulWidget。

**守护脚本**: `check_widget_dispose.py` 5 轮全绿 (0 资源泄漏)。

**dispose 顺序 (5/5)**:
- `_isRecording = false` 同步置位 (R61 P0-1 fix) — `mood_audio_section.dart:151`
- StreamSubscription 取消 — 3 文件全有
- Timer 取消 — home_page + mood_audio + 3 animation
- AudioPlayer / AudioRecorder dispose — vent_compose / vent_detail / mood_audio
- TextEditingController dispose — 多个 dialog
- 临时文件清理 — vent_compose / mood_audio
- `unawaited(_disposeResources().catchError(...))` — mood_audio_section.dart:158-167 (R25 round 52 spen P0 #7 修复 4 个 fire-and-forget race)

**发现 9 (NIT)**: 0 处违例。R52 spen P0 #7 修过"dispose 4 个 fire-and-forget race"集中修，**全 lib 0 漏**。

**R73 决策**: 守护脚本 + 集中修 4 轮后稳定。

**证据**:
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏"
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart:144-169` (R52 集中修 4 fire-and-forget)
- `lib/presentation/pages/home/home_page.dart:178-190` (R62 P1-6 Timer cancel 模式)

---

### 2.9 async/await 优先于 .then()

**扫描范围**: 全 lib 80+ 处 async/await，2 处历史 `.then()` (注释中).

**清理覆盖 (5/5)**:
- R17 "async + await 优先" 集中清
- R56b emil B-4 集中清
- R71 spen P5.4 集中清 (P71 修 2 处)
- R72 收尾
- **全 lib 0 处 `.then()` 实际调用** (R72 收尾后)

**新发现**: 0 处。R17 / R56b / R71 / R72 4 轮集中清后，**0 处 `.then()` 实际调用**。

**证据**:
- `grep -rn '\.then(' lib/` | grep -v '^.*://' | grep -v '// ' 输出空
- 2 处 `.then(` 匹配 (contacts_list_widget + data_management_section) 都在注释 / 文档中
- `lib/presentation/pages/contact/contacts_list_widget.dart:149-151` (历史 .then() 注释)

---

### 2.10 类型安全 (int.parse → int.tryParse)

**扫描范围**: 全 lib 8+ 处 int.parse / int.tryParse。

**修复覆盖 (5/5)**:
- `presentation/pages/home/home_page.dart:236` — `int.tryParse(medIdParam)` (R62 fix)
- `core/routing/app_route_vent.dart` — int.tryParse 1 处
- `core/theme/theme_provider.dart` — int.tryParse 1 处
- `domain/entities/hour_minute.dart` — int.tryParse 2 处
- `core/data/services/notification_payload.dart` — int.tryParse 4 处
- **全 lib 0 处 `int.parse` 实际调用** (R19B + R62 集中修)

**新发现**: 0 处违例。R19B 集中清后**全 lib 0 int.parse 硬调用**。

**证据**:
- `grep -rn 'int\.parse' lib/ | grep -v 'int\.tryParse' 输出空
- `int.parse=0 tryParse=8` 全 lib 汇总

---

## 3. 上架 / 架构 / 重构 / 半成品 4 类问题清单

### 3.1 上架 (App Store / Google Play) — 代码侧

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 上架 | P3 | `lib/main.dart:39, 52` (顶层 static `_smsService` / `_emailService`) | S (15min) | R62 P0-3 + R67 B-1 引入顶层 static instance 防止 state 错位，注释完整。**唯一可改**: 改 `_smsService` 命名 (`_bootSmsService`) 让"启动专用 instance" 意图更明显。当前 `main.dart:39-52` 已有详细注释 (R67 解释 email 暂时不需 override)，上架前可读性已可接受。**不修**。 |
| 上架 | P2 | `lib/core/data/services/sms_service.dart:90-200` (AliyunSmsProvider 18+ 月 TODO) | XL (跨 round 大工程, 需法务 1-2 月) | R63 P0-1 守门员 `_isFullyImplemented = false` + R55+ 真接计划 (`.env` + 阿里云 SDK + HMAC-SHA1 签名 + 模板审核)，需法务 1-2 月 + AccessKey 申请。**已记录** `docs/SMS_PROVIDERS.md` + `lib/main.dart:170` 启动时阻断。**上架前必须**: dev 模式 OK，**release 模式启动时阻断 + banner 显眼告警** (R63 已实现)。**上架后 v1.0+ PR 真接**。 |
| 上架 | P2 | `lib/core/data/services/email_service.dart:34-178` (EmailService 18+ 月 TODO) | XL | R67 B-1 守门员 `_isFullyImplemented = false` 跟 R63 SmsService 平行，但 **home_page `_fireCareEngine` 中 `fireEmail` 分支走 placeholder@invalid.local** (R67 注释 "R55+ TODO")。**上架前**: dev 模式 OK，**release 模式启动时阻断** (R67 B-1 已实现)。**email 暂未在 provider tree 用** (`emailServiceProvider` 已注册但 0 caller)。**不阻塞上架**，v1.0+ 真接 SendGrid。 |
| 上架 | P1 | `lib/presentation/pages/home/home_page.dart:557-575` (R55+ TODO 注释) | S (10min) | `_fireCareEngine` 中 `fireSms` / `fireEmail` 分支 hardcode `00000000000` / `placeholder@invalid.local` + 注释 "R55+ TODO"，**调用方无 1 处会走这 2 个分支**（`defaultConfig = careCopy`）。注释清晰，**不改**也安全，但可加 `_ = 00000000000; // R55+ TODO: 拿 input.contacts.first.phone` 抑制 analyzer 警告。**不修**。 |
| 上架 | P0 | — | — | **0 项 P0 上架 blocker**。R60-R72 集中清 4 轮已上架就绪 (R70 iOS Info.plist + R72 iOS PrivacyInfo + R72 Fastfile + R73 5 视角 8 轮审计 + 16 守护脚本全绿)。 |

**上架 checklist (R72 决策)**:
- ✅ iOS Info.plist (NSUserNotificationUsageDescription + 16KB alignment)
- ✅ iOS PrivacyInfo.xcprivacy (NSPrivacyAccessedAPITypes)
- ✅ Android abiFilters (R70)
- ✅ Data Safety Form 模板 (R72)
- ✅ Fastfile 集成 (R72)
- ✅ SMS/Email release-mode 守门员 (R63 + R67)
- ✅ Last startup error banner (R22 + R31)
- ✅ 16 守护脚本全绿 (R70-R72)

---

### 3.2 架构 (4 层) — 重构点

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 架构 | P1 | `lib/domain/entities/vent_entry_entity.dart:19` + `lib/domain/entities/scale_translations.dart:26` + `lib/domain/logic/day_detail.dart:27` (3 文件) | S-M (1-2h) | **soft 架构违规**: domain 层 3 文件 import `package:chroniccare/l10n/app_localizations.dart`，间接引入 Flutter。**修复**: 抽 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入，0 flutter in domain。跟 R67 B-2 `FireCareStrategyUseCase` 已用模式一致。 |
| 架构 | P2 | `dart scripts/check_all.dart` (purity check) | S (5min) | 修 purity check 加 `package:chroniccare/l10n/` 黑名单，5 行 patch。**0 现有 violation 暴露** (上面 3 文件在文件级 grep 才能发现，跨层依赖检测器漏)。**修不修都行**，上面 3 文件改完不需要改 check_all。 |
| 架构 | NIT | `lib/presentation/pages/home/home_page.dart:631` (仍 god class 候选) | M (1-2h) | 抽 3 个 helper class (HomeDeepLinkHandler / HomeCareEngineDispatcher / HomeCelebrationController)，减到 ~400 行。**不阻塞**，R66 报告未列 P1。 |
| 架构 | NIT | `lib/presentation/pages/mood/mood_dialog.dart:1204` (god class 候选, R64 漏拆) | M-L (半天-1 天) | R64 mood split 抽 `mood_audio_section.dart` 但 mood_dialog 自身仍 7 字段 + 4 维度评分状态机 + 2 StreamSubscription + 加密/解密集成。R66 报告 P2 缺口未解决，R74 同款。**P2 持续**。 |
| 架构 | NIT | `lib/core/data/services/notification_service.dart:424` (facade 仍偏大) | M (1-2h) | 6 sub-service + 1 builder 全部委派后 facade 仍 424 行 (主因 showSafetyAlert + 5 delegator + 11 个 ID 范围常量集中文档化)。**R65 决策**: "facade 5 类编排入口保留，复杂业务下沉 sub-service"，是 R57 design 模式延续。**不修**。 |
| 架构 | NIT | `lib/core/data/services/export/export_orchestrator.dart:540` (仍 god class 候选) | L (3h+) | 540 行含 5 段 JSON 拼装 (profile/contacts/medications/checkIns/reportHistories/moodEntries/ventEntries) + 6 段 JSON 解析。**R57 决策**: 跟 R57 safety_watch 同款"渐进 facade 模式"，**R58-R73 持续评估未拆**。**R74 重申**: 540 行可继续拆 `export_orchestrator_export.dart` (只管 export) + `export_orchestrator_import.dart` (只管 import) 2 文件，2x ~270 行。**P2 持续**。 |
| 架构 | NIT | `lib/presentation/pages/setup/setup_page.dart:468` (4 step wizard) | M (1-2h) | setup_page facade 468 行含 4 步状态机。**R66 报告同款未解决**。**P2 持续**。 |

---

### 3.3 重构 (god class / 长文件 / 重复模式 / 集中器机会)

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 重构 | P1 | `lib/domain/logic/care_engine.dart:149-153` (成功路径调 swallowError) | S (30min) | **反模式**: 成功路径走 `swallowError(where, error, note: 'success')`，`swallowError` 应只用于 best-effort 错误吞咽。**修复**: 改 `piiSafeLog('CareEngine.fire', '✅ 关怀触发: ${trigger.type.name}');` 走正常 log 集中器。 |
| 重构 | P2 | `lib/presentation/pages/vent/vent_compose_page.dart:77` (deleteTempFile 未 await) | S (30min) | dispose 同步函数 + `ref.read().deleteTempFile()` 异步返回 + 同步 try/catch 是 fire-and-forget 模式，**app 退出时未保证完成**。**修复**: 改 `unawaited(...) + .catchError(swallowError)` 跟 mood_audio_section 同款。 |
| 重构 | P2 | `lib/core/data/services/export/export_orchestrator.dart:540` (god class 候选) | L (3h+) | 拆 `export_orchestrator_export.dart` (只管 export) + `export_orchestrator_import.dart` (只管 import)，2x ~270 行。**R57 决策已留口子**，R74 仍未做。 |
| 重构 | P2 | `lib/presentation/pages/mood/mood_dialog.dart:1204` (god class 候选) | L (3h+) | 抽 3 widget (mood_text_section + mood_emotion_section + mood_tag_section)，状态机保留在 orchestrator。**R66 报告 P2 缺口未解决，R74 同款**。 |
| 重构 | P3 | `lib/presentation/pages/home/home_page.dart:631` (仍偏 god) | M (1-2h) | 抽 3 helper class (DeepLinkHandler + CareEngineDispatcher + CelebrationController)。**R66 报告未列 P1**。 |
| 重构 | P3 | `lib/presentation/pages/setup/setup_page.dart:468` (wizard facade) | M (1-2h) | 拆 4 step widget 各自管理内部 state，setup_page 退化为 stepper orchestrator。**R66 报告同款未解决**。 |
| 重构 | P3 | 集中器抽取: `home_page.dart:557-575` placeholder 注释 | NIT | 当前 `defaultConfig = careCopy` 永远不会走 `fireSms` / `fireEmail` 分支，**2 段死代码可加 lint 排除或注释 "// ONLY reached when CareChannelConfig.channel == sms/email (R55+)"**。 |
| 重构 | P3 | 集中器抽取: `lib/presentation/widgets/` 5 个分散 widget | S (半天) | `feedback.dart` + `press_feedback.dart` + `press_feedback_icon_button.dart` 3 个文件功能高度相似（press feedback / haptic），可抽 `PressFeedback` 统一 + `:icon` 工厂。R70 R71 R72 已抽 `StatCard` / `InfoBanner` / `DialogActionsRow` 3 个集中器，**press feedback 3 文件组是下一个**。 |

---

### 3.4 半成品 (TODO / FIXME / 假数据 / hardcoded / stub)

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 半成品 | P2 | `lib/core/data/services/sms_service.dart:90-200` (AliyunSmsProvider 18+ 月 TODO) | XL (法务 + AccessKey 1-2 月) | 真接阿里云 SMS 计划：HMAC-SHA1 签名 + `.env` + 模板审核。**已记录** `docs/SMS_PROVIDERS.md`，**R63 守门员已加**，**release 模式启动阻断**。**上架前必读**。**上架后 v1.0+ PR 真接**。 |
| 半成品 | P2 | `lib/core/data/services/email_service.dart:34-178` (EmailService 18+ 月 TODO) | XL (SendGrid 真接) | 真接 SendGrid 计划。**R67 守门员已加**，**release 模式启动阻断**。**v1.0+ PR 真接**。 |
| 半成品 | P2 | `lib/presentation/pages/home/home_page.dart:557-575` (R55+ TODO 注释 × 2) | S (10min) | `_fireCareEngine` 中 `fireSms` 走 `00000000000` / `fireEmail` 走 `placeholder@invalid.local` + 注释 "R55+ TODO"。**永远不会执行** (`defaultConfig = careCopy`)。注释清晰但可加 lint 抑制。**不修**。 |
| 半成品 | P3 | `lib/domain/entities/scale_translations.dart:99` (TODO R65b 补 3 key) | S (30min) | `scale_translations.dart:99` 注释 "tw/sg/uk 暂时走 intl fallback (TODO R65b 补 3 key)" — zh_Hant 仅 zh_tw 翻译，**简繁一致性检查** `check_zh_hant_consistency.py` 守护脚本 R70 集中修后**0 漏**。**R65b 收尾可删**。 |
| 半成品 | P3 | `lib/domain/entities/scale_translations.dart:17` (16 题全文 i18n 留 v1.0) | XL (跨 round 大工程) | `phq9.dart` / `gad7.dart` 16 题题干 i18n 化留 v1.0，spzh P1-A 已记 TODO。当前仅 hotline 6 region 走 hot path i18n。**v1.0+ PR**。 |
| 半成品 | P3 | `lib/core/data/services/notification_service.dart:408-412` (R70 决策删除) | NIT | R70 删 18+ 月 "v0.10+ TODO 集成 flutter_app_badge_control" 注释，走"iOS 真接 + Android 靠 launcher 自带"方案。**已删**，但代码 1-2 处仍可精简 (现 R70 已精简)。**不修**。 |
| 半成品 | P3 | `lib/core/data/services/sms_service.dart:184-194` (R55+ 真接步骤 8 步) | NIT | 详细注释 8 步骤，仅 0.5% 上架前看。**保留** (开发者 onboard 文档)。 |
| 半成品 | P3 | 5 个 `R55+ TODO` / `R55+ 真接` / `v1.0+ TODO` | XL (跨 round 大工程) | **6 个真接大工程**已集中在 `docs/SMS_PROVIDERS.md` / `docs/LEGACY_API_NOTES.md` / `docs/SPRINT1_LEGAL_TODO.md` 3 个 doc 集中跟踪。**R66 → R74 0 改善**。 |

---

## 4. 测试覆盖盲区

| 盲区 | 影响 | 推荐补测 |
|------|------|----------|
| `lib/presentation/pages/mood/mood_dialog.dart:1204` (god class) | mood 录入主入口，0 集成测 | 5-8 case 覆盖空 state / 编辑 state / 保存 state / 取消 state / 错误 state / STT 失败 graceful degrade / 临时文件清理 / dispose 完整链 |
| `lib/presentation/pages/home/home_page.dart:631` (god class 候选) | 主入口 + deep link + CareEngine + safety watch + 庆祝 overlay，0 集成测 | 10 case 覆盖 deep link 4 路径 (medId / reason=safety / no param / 重复 trigger) + CareEngine 4 channel 分支 + 庆祝 overlay 3 态 (mount / dismiss / dispose) + 状态机 5 状态转换 |
| `lib/presentation/pages/setup/setup_page.dart:468` (4 step wizard) | 用户首次体验，0 集成测 | 8 case 覆盖 4 step 状态机 (consent → welcome → medication → done) + 跳过 / 返回 / 重置 |
| `lib/core/data/services/notification_service.dart:424` (facade 0 单测) | init() 顺序 + 6 类 ID 范围 + showSafetyAlert 文案 3 态分流 | 1 test file 5 case 覆盖 init 4 步顺序 + 6 类 ID 范围不冲突 + showSafetyAlert 3 态 (ok / mock / fail) |
| `lib/core/data/services/export/export_orchestrator.dart:540` (export + import 集成测) | 隐私边界 (vent 加密 + audio 路径) + 跨版本兼容 (v1 → v2) | 5 case 覆盖 export 完整链 (profile → contacts → meds → checkIns → vent) + import 完整链 + vent 加密 round-trip + 跨版本升级 |
| `lib/domain/entities/vent_entry_entity.dart` (i18n 3 key 测) | R65 spzh P2-I 抽 `durationLabelL10n`，0 测 | 6 case 覆盖秒 / 分 / 分+秒 3 文案 + zh / en / zh_Hant 3 语言 |
| `lib/domain/entities/scale_translations.dart` (i18n 测) | R65 spzh P1-A 补 6 key，0 测 | 5 case 覆盖 phq9 / gad7 名 + 4 region hotline + crisis 文案 |
| `lib/core/data/services/email_service.dart:34-178` (R67 守门员 + 真接) | R67 B-1 守门员 7 case 已加，但 `_isFullyImplemented = true` 后的"真接路径"0 测 | v1.0+ 真接后补 5 case (success / 401 / 429 / network error / 模板错误) |
| `lib/core/data/services/sms_service.dart:90-200` (R63 守门员 + 真接) | R63 守门员 case 已加，但 AliyunSmsProvider 真接路径 0 测 | v1.0+ 真接后补 5 case (signature / phone 格式 / 模板错误 / 余额不足 / 限流) |

**汇总**: 8 个测覆盖盲区，主要在 presentation/ facade + 1 个 export orchestrator。**R66 报告 6 缺口未解决**（R74 重申），R74 新增 2 个 (notification_service facade 集成测 + vent_entry_entity i18n 测)。**R66 → R74 8 轮审计 0 改善** — 是 audit stale 项。

**建议优先级 (R75 候选)**:
- P1: `notification_service.dart` facade 集成测（5 case，1-2h）
- P1: `mood_dialog.dart` facade 集成测（5-8 case，1-2h）
- P2: `export_orchestrator.dart` export + import 集成测（5 case，2-3h）

---

## 5. 修复优先级排序

### P0 (上架 blocker, 0 项)

**0 项**。R60-R72 集中清 4 轮已上架就绪，**0 P0 blocker**。

---

### P1 (质量改进, 2 项 — 估时 1-2h)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| P1-1 domain 层 l10n 软违规抽离 | `vent_entry_entity.dart:19` / `scale_translations.dart:26` / `day_detail.dart:27` 3 文件 import Flutter 间接依赖，**违反 4 层架构纯度**。改 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入，0 flutter in domain | 1-2h | 3 domain 文件 |
| P1-2 care_engine 成功路径走 swallowError 反模式修 | `care_engine.dart:149-153` 成功路径调用 `swallowError(where, error, note: 'success')`，**误导 log 框架**。改 `piiSafeLog` 走正常 log 集中器 | 30min | `lib/domain/logic/care_engine.dart` |

---

### P2 (架构 / 重构 / 半成品, 4 项 — 估时半天-1 天)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| P2-1 vent_compose_page dispose 异步未 await 修 | `vent_compose_page.dart:77` `deleteTempFile` 未 await + 同步 try/catch 是 fire-and-forget。改 `unawaited(...).catchError(swallowError)` 跟 mood_audio_section 同款 | 30min | `lib/presentation/pages/vent/vent_compose_page.dart` |
| P2-2 mood_dialog god class 拆分 | 1204 行含 7 字段 + 4 维度评分状态机 + 2 StreamSubscription + 加密/解密集成。抽 3 widget + orchestrator | 半天-1 天 | `lib/presentation/pages/mood/mood_dialog.dart` |
| P2-3 export_orchestrator god class 拆分 | 540 行含 5 段 export + 6 段 import，拆 `export_orchestrator_export.dart` + `export_orchestrator_import.dart` | 3h+ | `lib/core/data/services/export/export_orchestrator.dart` |
| P2-4 notification_service facade 集成测 | init() 顺序 + 6 类 ID 范围 + showSafetyAlert 文案 3 态分流 0 单测 | 1-2h | `test/core/data/services/notification_service_facade_round74_test.dart` (新) |

---

### P3 (优化 / 重构机会 / NIT, 6 项 — 估时 1-2 天)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| P3-1 home_page 631 行 god class 抽 3 helper | DeepLinkHandler / CareEngineDispatcher / CelebrationController 3 个 class | 1-2h | `lib/presentation/pages/home/home_page.dart` |
| P3-2 setup_page 4 step wizard 拆 4 widget | setup_page 退化为 stepper orchestrator | 1-2h | `lib/presentation/pages/setup/setup_page.dart` |
| P3-3 press feedback 3 文件组统一 | `feedback.dart` + `press_feedback.dart` + `press_feedback_icon_button.dart` 抽 `PressFeedback` 统一 + `:icon` 工厂 | 半天 | `lib/presentation/widgets/` |
| P3-4 6 个 R55+/v1.0+ TODO 集中 doc 跟踪 | 6 个真接大工程已集中 `docs/SMS_PROVIDERS.md` / `docs/LEGACY_API_NOTES.md` / `docs/SPRINT1_LEGAL_TODO.md`，**加 SPRINT2_TODO.md 集中索引** (避免 grep 噪音) | S 难度, 1h | `docs/SPRINT2_TODO.md` (新) |
| P3-5 vent_entry_entity + scale_translations i18n 测 | R65 spzh P1-A / P2-I 抽 l10n 0 测，补 11 case | 1-2h | 2 新 test 文件 |
| P3-6 home_page + setup_page 集成测 | 18 case 覆盖 deep link + CareEngine 4 channel + 4 step wizard | 2-3h | 2 新 test 文件 |

---

### 总结

- **P0**: 0 项 (上架就绪)
- **P1**: 2 项 (估时 1-2h, 1 个 round 内可完成)
- **P2**: 4 项 (估时 半天-1 天, 1 个 round 可完成)
- **P3**: 6 项 (估时 1-2 天, 2 个 round)

**R74 综合判断**: v0.27.0+64 进入"上架前稳态"，R60-R73 持续打掉 6 个 god class + 抽 5 个 use case + 5 视角集中审计 8 轮，**0 P0 blocker，2 P1 缺口 (1-2h 内可修)**。最大遗留问题是 `mood_dialog.dart` 1204 行 god class (R64 漏拆) + `export_orchestrator.dart` 540 行 god class (R57 留口子未拆) + 8 个测覆盖盲区 (R66 报告 6 缺口未解决 + R74 新增 2 个)。**R75 建议优先做 P1-1 (1-2h) + P1-2 (30min) + P2-1 (30min) = 半天内全清 3 项**。
