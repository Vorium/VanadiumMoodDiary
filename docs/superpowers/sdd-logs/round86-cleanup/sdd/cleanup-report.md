# R86 Cleanup Report (v0.30 round 86)

**Branch:** `fix/minor-cleanup`
**Commits:**
- `bb8ab62` — v0.30 round 86 (test): R77 setup_* 4-checkbox + 同步老测试 (16 pre-existing fail 修)
- `d28c927` — v0.30 round 86 (cleanup): 25+ Minor findings from sub-spec 1+2 review

## Part 1 — R77 setup_* test fix (16 pre-existing fails)

### Files modified
- `test/presentation/setup_consent_round14_test.dart` — 5 cases, 3→4 Checkbox
  + 加年龄严正声明 label 断言 (`find.textContaining('本人郑重承诺')`) + 勾
  3 个仍 disabled (R83 加了第 4 个 checkbox 后)
- `test/presentation/setup_page_round18_test.dart` — `_passConsent` helper
  3→4 (R18 有 4 case 用 _passConsent)
- `test/presentation/setup_page_round77_test.dart` — 7 cases, 3→4 Checkbox
  (含 4 step 状态机 / 返回 / 重置)
- `test/presentation/setup_step2_round14_test.dart` — 2 cases, 3→4

### Why these were failing
`lib/presentation/pages/setup/setup_step_consent.dart` v0.27 R83 (Q11a
律师审核 ⚠️ 修复) 加了第 4 个 `ConsentCheckRow` (`setupLegalAgeAttestation`
年龄严正声明, 依据《未成年人保护法》§44 + 《PIPL》§31, 14-18 周岁用户
需监护人代为签署同意). 4 个 consent (用户协议 / 隐私政策 / 敏感数据 /
年龄严正声明) 全部勾上 → `开始设置` enabled. 老测试期望 3 个 Checkbox,
勾 3 个 enabled, 加完 4 个后 assert `findsNWidgets(3)` 报 "is too many"
(Found 4 widgets). 4 个测试文件, 16 cases, 全因这个错位.

### Text verified
- `setupLegalAgeAttestation` = "本人郑重承诺:我已年满 18 周岁..."
  (lib/l10n/app_zh.arb:1504). 测试用 `find.textContaining('本人郑重承诺')`
  锁定第 4 个 checkbox, 不锁完整字符串 (后续 i18n 调整更稳).
- `setupHello` = "您好,我是慢病管家" 仍存在 (lib/l10n/app_zh.arb:44), 不动
- `setupConsentStart` = "开始设置" 仍存在 (lib/l10n/app_zh.arb:853), 不动
- `setupNext` = "下一步 →" 仍存在 (lib/l10n/app_zh.arb:51), 不动

## Part 2 — 25+ Minor findings applied

### Applied (12 items)

1. **`lib/core/data/database/app_database.dart:91`** — comment "schemaVersion
   16 → 17" → "schemaVersion 15 → 17" (R84 Task 1 Minor 1: 实际 code diff
   15→17, 无中间 v16)
2. **`lib/core/data/database/app_database.dart:257-269`** — migration
   注释 "v16 → v17" → "v15 → v17 (无中间 v16)" + 加 "未来 v16 placeholder"
   提示 (R84 Task 1 Minor 2: `if (from <= 16)` fragile to future v15→v16)
3. **`lib/domain/entities/mood_entry_entity.dart:196-213`** — `cbtLevel`
   5-check 漏 `evidenceFor` / `evidenceAgainst` (R84 Task 1 Minor 3):
   加 2 个条件, 文档化完整 6 个 5/7 栏共享字段
4. **`lib/domain/entities/mood_entry_entity.dart:262-273`** — `toString` 漏
   8 个 CBT 字段 (R84 Task 1 Minor 4): 加 situation / automaticThought /
   evidenceFor / evidenceAgainst / alternativeThought / reratedScore /
   coreBelief / behaviorResponse
5. **`lib/presentation/providers/cbt_providers.dart:93-107`** — `firstEmptyStep`
   docstring 编号错 (R84 Task 3 Minor 1): 7 栏 "0-4 同 5 栏, 5=coreBelief,
   6=behaviorResponse" → 真实 7 栏 7 步 (0-6): 0-3 同 5 栏, 4=coreBelief,
   5=behaviorResponse, 6=确认 + 加 "setStep maxStep=6" 提示
6. **`lib/presentation/pages/mood/widgets/cbt_explainer_card.dart:8`** —
   注释 "expanded==null || onToggle==null" 实际是 && 触发内部 _expanded
   (R84 Task 4 Minor 1): 改 doc "任一为 null (expanded==null ||
   onToggle==null) → 走内部 _expanded"
7. **`lib/presentation/pages/mood/widgets/cbt_explainer_card.dart:62-72`** —
   `dart format` 修 trailing comma 风格错位 (R84 Task 4 Minor 4)
8. **`test/presentation/pages/mood/cbt_widgets_round84_test.dart:8-9`** —
   注释误导 "ProviderScope + MaterialApp" (R84 Task 4 Minor 2): 改 "纯
   stateless widget 测试 (无 Riverpod), 只用 MaterialApp + tester.pumpAndSettle"
9. **`test/data/mood_cbt_roundtrip_round84_test.dart:93-104`** — 3-栏
   round-trip test 只 check 2/8 字段为 null (R84 Task 1 Minor 5): 加剩余
   6 个 CBT 字段 null 断言 + 加 `cbtLevel == null` 断言
10. **`test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart`** —
    修 `],),` dart fix --apply artifacts (R85 Task 1 Minor 1)
11. **`test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart:60-63`** —
    test 2 "7 栏 entries 也返回" 只 check length 不 check id (R85 Task 1
    Minor 3): 加 `expect(result.first.id, 1)` 跟 test 1 一致
12. **`docs/CHANGELOG.md:55-112`** — 新增 [0.30.0] R86 cleanup 段
    (Fixed / Changed / Tests / Defered to v0.30+ / out of scope 4 子段,
    25+ Minor 集中记录 + 哪些 defer 留 R87+)

### Already fixed (acknowledged, no action)

- **R84 Task 8 `_DayDetailCard` 跨层 leak** (R8 commit 51c9a0e 已修) — 当前
  app_database.dart:97 + 266 已用 `DayDetailCard` (无下划线)
- **R84 Task 6 cbt_wizard.dart:13-19 7 栏 step mapping** (commit eebb8fd
  final review 已修) — 当前 cbt_wizard.dart:13-19 已对齐 (4=核心信念,
  5=行为应对, 6=确认)
- **R84 Task 5 `cbt_three_column_round84_test.dart:23-26` test name 误导**
  (R5 commit 0adeb52 已修) — 已加 5 个 score chip 断言
- **R84 Task 6 `cbt_wizard.dart` step 2 score chip placeholder + "保存"
  button** (R6 commit 0bc7c4a 已修) — 已加 updateScore + "完成" 按钮
- **R84 Task 4 `CbtSectionField` TextEditingController 在 build() 里 new**
  (R4 commit dcc1ef6 已修) — 已改 StatefulWidget + dispose 模式

### Deferred (留 R87+, 行为变更或大 refactor)

- **`sharedPreferencesProvider` 放 cbt_providers.dart** 跟 core_providers
  风格不一致 (R84 Task 2 Minor 1) — 改位置需 4-5 个文件 (1 source + 3 test
  + main.dart) import 改动, 单独立 PR 更安全
- **`test/domain/entities/` 子目录** 跟项目其它 test 平铺不一致 (R84 Task 2
  Minor 2) — 跟 sub-spec 1 整体一起整理
- **`lib/l10n/app_localizations_zh.dart` 未提交修改** (R84 Task 2 Minor 3) —
  pre-existing 跟 SP generator 关联, 跟 i18n 集中处理
- **`cbt_providers.dart:144-149` setStep 不 enforce 3-col** (R84 Task 3
  Minor 2) — 行为变更
- **`cbt_providers.dart:151-181` updateField 不能 clear field to null**
  (R84 Task 3 Minor 3) — 行为变更
- **`MoodEntryDraft.copyWith`** 11 行 boilerplate (R84 Task 3 Minor 4) —
  加新 method 需大测, 跟 P0 fix path 绑定, 单独立 PR
- **cbt_three_column_mode.dart + mood_recorder_page.dart 12+ 硬编码中文**
  (R84 Task 5 Minor 1) — i18n 大工程, 留 i18n 集中 PR
- **mood_recorder_page 跟 brief `_MoodRecorderPageState` sketch 略不同**
  (R84 Task 5 Minor 2) — 非 bug, 留 spec 收敛
- **`_save()` 13-field MoodEntryDraft 构造 boilerplate** (R84 Task 5 Minor
  3) — 跟 MoodEntryDraft.copyWith 一起做
- **test 不 exercise level-routing path** (R84 Task 5 Minor 4) — 跟
  cbtDraftProvider 集成测一起做
- **cbt_wizard.dart step 3 hint 跟 step 1 第一条 prompt 重复** (R84 Task 6
  Minor 3) — 内容调整, 留 R87+ UX 集中
- **缺 7 栏 path / 后退导航 / last-step save 测试** (R84 Task 6 Minor 4 +
  Forwarded Task 8) — 跟 R86 cbt_wizard 集成测一起加
- **trend_calendar.dart:487-505 `Wrap` with single child** (R84 Task 8
  Minor 1) — YAGNI hook, brief-mandated 保留 (spec 规定)
- **缺 7 栏 `cbtLevel == 7` 路径 widget test** (R84 Task 8 Minor 3) — 跟
  R86 task 5 一起加
- **`find.text` 不够 specific (没 descendant 锁住 CBT block)** (R84 Task 8
  Minor 4) — 跟 R86 task 8 widget 测一起加
- **`CbtWizard` 在 `mood_recorder_page` 的 `SingleChildScrollView` 嵌套
  RenderFlex** (R84 Task 10 P2) — 跟布局 refactor 一起
- **9 pre-existing `RadioListTile` deprecation info** (R84 Task 10
  pre-existing) — 跟 M3 RadioGroup 升级一起做
- **R85 Task 1 "缺 boundary at 5 test (cbtLevel 不可设 4/6)"** — 跟
  ThoughtRecordLevel enum 一起验

## Test results

| | Before | After |
|---|---|---|
| Total tests | 1456 pass + 16 setup_* fail | 1472 pass / 0 fail |
| `flutter analyze` | 9 issues (9 pre-existing info) | 9 issues (9 pre-existing info) |
| 16 守门员脚本 | 17/17 pass | 17/17 pass |

### Specific test count delta
- `setup_consent_round14_test.dart`: 0 → 5 pass (was 5 fail)
- `setup_page_round18_test.dart`: 0 → 4 pass (was 4 fail)
- `setup_page_round77_test.dart`: 2 → 7 pass (was 5 fail)
  - (注: 之前有 2 pass 是 _NoopNotificationService override 通过但因 checkbox 报错的 case 现在变 0)
- `setup_step2_round14_test.dart`: 0 → 2 pass (was 2 fail)

合计: 16 修复 + 0 新增 = 1472 total. 无 regress.

## Analyze result

```
9 issues found. (ran in 5.6s)
```

全部 9 issues 是 pre-existing RadioListTile `deprecated_member_use`
(cbt_section.dart + cbt_section_round84_test.dart 共 9 处), 跟 R85 baseline
完全一致, 跟 R83 起就被标记的 M3 RadioGroup 升级一起做, 不在本批.

## 守门员 result

```
Scripts: 17 pass, 0 fail
```

16 python + 1 dart, 跟 R85 一致:
- check_arb_keys ✓
- check_changelog ✓
- check_cross_feature ✓
- check_datetime_race ✓
- check_datetime_race2 ✓
- check_drift_namespace ✓
- check_fullwidth_punctuation ✓ (warn-only)
- check_legal_consent ✓
- check_no_hardcoded_utc ✓
- check_no_pua ✓
- check_orphan_arb_keys ✓
- check_sms_release_ready ✓ (warn-only)
- check_strings_hardcoded ✓
- check_widget_dispose ✓
- check_zh_hant_consistency ✓
- check_16kb_alignment ✓
- check_all.dart ✓ (dart)

## Files modified (12)

1. `docs/CHANGELOG.md` (+57 lines: R86 entry)
2. `lib/core/data/database/app_database.dart` (comment 15→17 + placeholder)
3. `lib/domain/entities/mood_entry_entity.dart` (cbtLevel 5-check + toString
   8 字段)
4. `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart` (注释
   "||" → "任一" + dart format trailing comma)
5. `lib/presentation/providers/cbt_providers.dart` (firstEmptyStep docstring
   7 栏 5/6 → 4/5)
6. `test/data/mood_cbt_roundtrip_round84_test.dart` (3-栏 test 6 字段 null
   断言 + cbtLevel)
7. `test/presentation/pages/mood/cbt_widgets_round84_test.dart` (注释
   "ProviderScope + MaterialApp" 误导)
8. `test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart`
   (修 `],),` artifacts + test 2 id 断言)
9. `test/presentation/setup_consent_round14_test.dart` (3→4 Checkbox +
   年龄严正声明 label)
10. `test/presentation/setup_page_round18_test.dart` (_passConsent 3→4)
11. `test/presentation/setup_page_round77_test.dart` (3→4 Checkbox)
12. `test/presentation/setup_step2_round14_test.dart` (3→4 Checkbox)

## Concerns / notes

1. **Pubspec 没 bump**: R86 是 cleanup batch, 不改 pubspec.yaml 也不改
   守门员 list, 跟 R85 同 0.30.0+85. CHANGELOG 段也是 [0.30.0] 而不是
   [0.30.1], 跟 task spec 一致.
2. **cbtLevel 5-check 改 = 行为变更**: 跟 R83 起 R84 Task 1 review
   就指出的真 bug. 修法: 任一 5/7 栏共享字段 (含 evidenceFor/Against) 非空
   → cbtLevel = 5. 影响面: 之前填了 only evidenceFor/Against (无
   situation/automaticThought/alternativeThought/reratedScore) 的 user
   cbtLevel 会从 null 升到 5. 实际数据: round-trip test 跑通, 4 个
   existing 用例 (mood_recorder / DayDetailCard / cbt_rerated_entries /
   trend_calendar_badge) 行为不变 (因为他们都已经填了 situation 等, 不是
   only evidence). 风险: low, 加 test 覆盖.
3. **toString 加 8 字段**: 加 console.log 调试信息更详细, 无 log 成本.
   hashCode / == 已经包含这 8 字段, 一致性修.
4. **R77 setup 4-checkbox 同步**: 同步了 4 个文件 16 case, 加 1 case 年龄
   严正声明 label 断言. 老 `勾 1 / 2 / 3 个 → 仍 disabled` 测试更新成
   "3 个 disabled, 4 个 enabled". 实际生产用 4-checkbox, 测试也用 4-checkbox.
5. **Minor "defer" 多**: 25+ Minor 里实际 apply 12, defer 18+. Defer 原因
   大多: 行为变更 (需 P0 配套) / i18n 大工程 / layout refactor / 已有
   follow-up 计划. 在 CHANGELOG "Defered to v0.30+ / out of scope" 段
   全部记录, 留 R87+ 集中.
