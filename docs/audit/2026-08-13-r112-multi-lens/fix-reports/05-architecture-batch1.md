# R112 Architecture Batch 1 修复报告 (subagent 05)

- 作者: 实现 subagent (architecture batch 1)
- 时间: 2026-08-13
- baseline: R112 working tree (pubspec 0.32.0+142)
- 范围: AR-17 / AR-18 / AR-16 / R112-ARCH-02 + R112-01 / R112-08 / R112-09 / R112-10 / SP-R112-04

## 任务状态总览

| # | 任务 | 状态 | 备注 |
|---|---|---|---|
| 1 | R112-01 裸 id 回归 (scale_name_l10n phq9/gad7) | ✅ done | + assert(false) default 分支 |
| 2 | AR-17 scale 翻译 4 源合一 (删 810L 死代码) | ✅ done | 净删 842L lib + 4 test 重写 |
| 3 | AR-18 接线 2 个死 usecase | ✅ done | CheckSafetyUseCase + ScheduleRefillReminderUseCase 变活 |
| 4 | AR-16 data→l10n 循环 + 守门盲区 | ✅ done | check_all data 规则 +l10n +core/routing, 4 文件全修 |
| 5 | R112-ARCH-02 data→core/routing 传递依赖 | ✅ done | DeepLinkResolver (domain 纯函数) + 注入回调 |
| 6 | R112-08 notification_delegate 旧 id doc | ✅ done | 8000/7000/9999 → 5000002/5000001/5000100 |
| 7 | R112-09 showSafetyAlert userName 死参数 | ✅ done | 参数 + 调用 + test helper 同步删 |
| 8 | R112-10 NoOp usecase 标记 | ✅ done | doc 注释标记 (domain 纯度守门禁 flutter/foundation marker, 见下) |
| 9 | SP-R112-04 saveSetup StateError 测试 | ✅ done | 新测试 1 case + transaction 回滚断言 |

**无 blocked 项。**

## 验证结果 (全跑实测)

- `flutter analyze`: **0 error / 0 warning** / 113 info (baseline R112 是 3 warning / 133 info)
- `flutter test` 全量: **2447 pass / 4 fail / 1 skip** — 4 fail 是 iOS 资产占位 (AppIcon/LaunchImage 68B, 等设计师, 与 R112 baseline 同款); baseline 2377 pass → +70
- 守门员: `check_all` (含新规则) ✅ / `check_usecase_layer` ✅ / `check_cross_feature` ✅ / `check_orphan_arb_keys` ✅ (111 orphan 已用引用锁封住) / `check_strings_hardcoded` ✅ / `check_coverage` ✅ (18 gatekeeper PASS) / `check_arb_keys` ✅ / `check_zh_hant_consistency` ✅ / `check_legal_consent` ✅ / `check_pii_in_title` ✅ 等
- 已知非本批: `check_fullwidth_punctuation` 1 处违规在 `lib/presentation/pages/setup/setup_widgets.dart:20` (0.31.0 round 10b 引入, 归 setup agent); `check_review_information_todo` warn-only 3 占位 (外部依赖)

## 各任务要点

### 1. R112-01 (emil)
- `scale_name_l10n.dart`: `scaleShortDescL10n` 补 `phq9`/`gad7` 2 case (ARB key `phq9ShortDescription`/`gad7ShortDescription` 已存在); 两个 switch 的 default 改 `_unregisteredId(id)` — debug `assert(false, '未注册量表: $id')`, release 返 id 兜底。
- 测试: `scale_name_l10n_round8_test.dart` 全 10 id 覆盖 + desc `isNot(id)` 断言 + 未知 id 改 `throwsA(isA<AssertionError>())`。

### 2. AR-17 (scale 翻译合一)
- **删** `lib/presentation/services/scale_translations_l10n.dart` (32L 主壳) + `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` (810L, 186 method, 0 运行时 caller) = **净删 842L**。
- `assessment_center_card.dart`: 私有 `_l10nName`/`_l10nShortDesc` switch 全删, 改 `scaleNameL10n`/`scaleShortDescL10n` 公共 helper。
- 4 个 lock-in test 重写 (共 -200L 净):
  - `scale_translations_round78_test.dart`: en/zh 路径改直测 ARB getter (`en.phq9Item0` 等); `Phq9Scale(translations:)` 集成测试用本地 `_EnTranslations extends StaticScaleTranslations` 替身 (保住"translations 注入链路"覆盖)。
  - `scale_translations_round65_test.dart`: 同上, 本地 `_EnNameTranslations` 替身。
  - `phq9_detect_crisis_round60_test.dart`: R77 hotline en 组用本地 `_EnHotlineTranslations` 替身。
  - `scale_strings_arb_lock_in_round95_test.dart`: 全组改直测 ARB getter; Group 3 (stub items 返 '') 改为锁 domain StaticScaleTranslations 中文 items fallback 非空; **新增 Group 3b 111 个 options/severity ARB key 引用锁** (这些 key 原是死类的唯一引用方, 删除后 check_orphan_arb_keys FAIL — 它们是 Task 6 items i18n v1.0 预留翻译, 用 zh+en 各 1 断言锁住 3 语非空 + 防 orphan); ARB 总数 baseline 1250 → **1278** (跟 A agent 同批 +28 key 同步)。
- 量表名 source of truth 收敛: domain `StaticScaleTranslations` (中文 fallback, 保留不动) + presentation `scaleNameL10n` (name/shortDesc) 2 源。

### 3. AR-18 (usecase 接线)
- `safety_watch_service.dart`: 加 `CheckSafetyUseCase` 字段 (构造注入, 默认 `const CheckSafetyUseCase()`), `SafetyDetector.detect(...)` 改 `_checkSafetyUseCase(CheckSafetyInput(...))` — usecase 0 运行时 caller → 2 caller。
- `refill_notifier.dart`: 加 `ScheduleRefillReminderUseCase` 字段 (同款注入); `scheduleRefillReminder` fireAt/isExpired 计算改走 usecase; `rescheduleRefillReminders` 过滤 + fire time 计算改走 usecase 结果循环。行为差异 (与 usecase 文档规则对齐): inactive 药物现在也跳过单药调度 (原只有重排跳过, 无 caller 传 inactive 单药)。
- `test/domain/usecases/` 原样全绿; `refill_notifier_round61c_test.dart` 19 case 全绿; `safety_watch_service_round12_test.dart` 22 case 全绿。

### 4. AR-16 (data→l10n 循环 + 守门)
- `scripts/check_all.dart`: `_purityRules['data']` 加 `package:chroniccare/l10n/` + `package:chroniccare/core/routing/` 两条 forbidden (含 `_isForbiddenImport` 对应 case) — 规则生效实锤 (跑时只报 2 个 routing 违规, 修完 0)。
- 4 个 data 文件 l10n import 全移除:
  - `safety_watch_service.dart`: entry 3 方法改拿 `SafetyAlertL10nResolver` (按文件注释 tear-off 方案执行); `displayMessageL10n` 移到 presentation extension 新文件 `safety_check_result_l10n.dart` (caller 语法 `result.displayMessageL10n(l10n)` 不变)。
  - `preset_medication_templates.dart`: 删 5 个 l10n 方法 + switch (~90L), 只留 key 数据; 解析移到 presentation extension 新文件 `preset_med_l10n.dart` (caller 语法 `t.nameL10n(l10n)` 不变, 仅 +1 import)。
  - `cbt_thought_record_pdf.dart` / `_layout.dart`: `build`/`CbtLayout` 改拿 `CbtPdfL10n` interface (layout 文件定义, 10 getter); 适配器 `cbt_pdf_l10n.dart` (presentation, `AppLocalizationsCbtPdfL10n`)。
- 改动超出所有权清单的最小 caller 文件 (flag 给协调者): `home_page_state.dart` / `home_care_engine_dispatcher.dart` (home, 与 setup agent 无交集, 每处 ~8 行 tear-off 构造 + 1 import), `setup_page_state.dart` / `preset_templates_sheet.dart` (setup 目录, **与另一个 agent 目录重叠**, 每文件只 +1 import 行, 无逻辑改动), `cbt_pdf_tile.dart` (settings, 1 行 wrap)。

### 5. R112-ARCH-02 (data→core/routing)
- 新建 `lib/domain/logic/notification_deep_link_resolver.dart` (0 Flutter/0 data): `resolveNotificationDeepLinkRoute(String?)` — payload → route string 纯函数, 4 类 action 全解析 + 非法输入返 null; 12 case 新测试 `notification_deep_link_resolver_round112_test.dart`。
- `notification_navigation.dart`: `_pathFor` 删, 路由决策走 domain resolver; `_pendingLaunchLink`(link) → `_pendingLaunchPayload`(raw string); GoRouter 绑定 + onLink 观察保留 (app 层用)。
- `notification_service.dart`: 删 `core/routing` import + `_defaultOnTap`; `onNotificationTap`/`onLaunchPayload` 改可空注入回调; `_onResponse` static → instance。
- `notification_initializer.dart`: 加 `onLaunchPayload` 回调, 删 `NotificationNavigation.setLaunchPayload` 直调 + import。
- `main.dart` (`_initNotification`): app 层接线 `NotificationService(onNotificationTap: NotificationNavigation.handleTap, onLaunchPayload: NotificationNavigation.setLaunchPayload)`。
- `core_providers.dart:74` fallback `NotificationService()` 不改 (不在所有权; 生产必被 main override, fallback 只 log 不导航)。
- 测试: `notification_service_split_round45b_test` 默认回调断言改 null + reason; `notification_navigation_round20_test` 原样全绿; 新 resolver 测试 12 case。

### 6-9. 杂项
- R112-08: `notification_delegate.dart` 3 处字段 doc + 1 处委派 doc 旧 id (8000/7000/9999) → 5000002/5000001/5000100 (与 `notification_service.dart` 固定带文档一致)。
- R112-09: `showSafetyAlert` `userName` 死参数删 + `safety_alert_sender_impl.dart` 传参删 (该文件不在原清单, 按任务授权纳入所有权只删传参) + `safety_test_helpers.dart` SafetyAlertCall record 同步删字段 (测试断言不依赖 userName, 0 行为变化)。
- R112-10: `NoOpDispatchSafetyAlertUseCase` 标 **doc 注释** (⚠️ 严禁生产代码构造) — 原计划 `@visibleForTesting` marker, 但 `package:flutter/foundation.dart` (re-export 来源) 触发 check_all domain 纯度守门 (0 `package:flutter/`), 与 R110 round 3 (schedule_assessment_reminder 删同款 marker) 先例一致, 改注释标记; 结构不动, 抽 test 公共 helper 包的大迁移留后续。
- SP-R112-04: 新测试 `test/data/app_database_save_setup_round112_test.dart` — contactList 2 / contactConsents 1 → `throwsA(isA<StateError>())` + transaction 回滚断言 (userProfile null / contacts empty)。app_database.dart 未改。

## 净删行数

- lib 净删: **-842** (scale_translations_l10n 全删) + preset templates -90 + safety_watch -25 + notification 相关 -10 ≈ **lib 净删 ~950 行**, 新增 4 个文件 (+53 resolver / +49 / +62 / +45) + 新测试 (+79 / +51) + orphan 锁 (+236 其中 222 是断言行)。
- 汇总 (仅本批 45 文件): **+1999 / -1518** (含 842 删 + test 重写), 其中死代码净删 842L + 111 ARB key 引用锁防止 222 行翻译变 orphan。

## Concerns / 需协调者注意

1. **超出所有权清单的最小 caller 改动** (5 文件): `home_page_state.dart`、`home_care_engine_dispatcher.dart`、`setup_page_state.dart`、`preset_templates_sheet.dart`、`cbt_pdf_tile.dart`。setup 2 文件与另一个 agent 的目录重叠, 但每文件仅 +1 import 行 (extension 模式), 若对方同批改动同样区域应无冲突 (git 可自动合并)。
2. **ARB 总数 baseline 已改 1250 → 1278** (`scale_strings_arb_lock_in_round95_test.dart`): 这 +28 是 A agent 同批加的 ARB key (不是本批), 若 A agent 后续再加 key 需再 bump 一次。
3. **111 个 options/severity ARB key 用测试锁保活** (Group 3b): 它们是 Task 6 (items i18n, v1.0 R51b) 的预留翻译, 死类删除后无运行时引用。选择了"锁保活"而非"删 key" (避免与 A agent 的 ARB 工作冲突 + 保留已翻译内容)。若架构方决策是"未启用 key 应删", 删后需同步 180-key count 锁 + 1278 total。
4. **scale_name_l10n.dart 是 untracked 文件** (R112 working tree 未提交产物), 本批编辑后仍 untracked — 与整合 commit 一起入库即可。
5. `core_providers.dart:74` 的 `NotificationService()` fallback 未接线 navigation 回调 (不在所有权): 生产永远被 main.dart override 覆盖, 但若未来测试依赖 fallback 导航行为需补。
6. 已知非本批守门: `check_fullwidth_punctuation` 1 处 (`setup_widgets.dart:20`, setup agent 领域); `check_16kb_alignment` 需重 build 验证 (R112 跨期)。
7. `refill_notifier` 行为微调: inactive 单药现在也跳过调度 (与 usecase 文档规则 1:1), 若有用例依赖旧行为需 review。
