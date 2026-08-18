
- [x] Task 1: complete (commits 377f81f..ce2288d, review clean — 6/6 tests pass, schema 16→17, 8 commits, Approved with 6 Minor findings logged)

### Task 1 Minor findings (deferred to final review)

1. `lib/core/data/database/app_database.dart:83, 250` — 注释说 "16→17" 实际 diff 是 15→17, 改注释措辞
2. `lib/core/data/database/app_database.dart:250-262` — `if (from <= 16)` fragile to future v15→v16, 加 placeholder
3. `lib/domain/entities/mood_entry_entity.dart:131-138` — `cbtLevel` 5-check 漏 `evidenceFor`/`evidenceAgainst`
4. `lib/domain/entities/mood_entry_entity.dart:267-270` — `toString` 漏 8 CBT 字段
5. `test/data/mood_cbt_roundtrip_round84_test.dart:90-98` — 3-栏 test 只检查 2/8 字段为 null
6. `lib/core/data/database/app_database.dart:83-88` — comment 引用 `_DayDetailCard` 跨层 leak

- [x] Task 2: complete (commits ce2288d..e604847, review Approved with 2 Important + 3 Minor findings logged)

### Task 2 Important + Minor findings (deferred to final review)

**Important:**
1. `ThoughtRecordLevelNotifier` 无 Notifier 单元测试 — brief 范围只测 enum, 但 Notifier 行为(SP 读默认值 / setLevel 持久化)未覆盖. 建议加 3 个 Notifier test
2. `setLevel` state-before-write ordering: state 先更新 + await 后持久化, 若 SP 写失败 state 跟 SP 不一致 (brief-mandated, 但 contract 沉默)

**Minor:**
1. `sharedPreferencesProvider` 放 cbt_providers.dart 跟 core_providers.dart 风格不一致
2. test path 在 test/domain/entities/ 子目录 (项目其它 test 是平铺)
3. pre-existing `lib/l10n/app_localizations_zh.dart` 未提交修改 (非 task 2 引入, 需 next task 处理)

- [x] Task 3: complete (commits e604847..ac75e7a, review Approved clean — 6/6 tests, CbtDraftState + Notifier + provider)

### Task 3 Minor findings (deferred to final review)

1. `cbt_providers.dart:76-86` — `firstEmptyStep` docstring 编号跟代码不一致 (docstring 说 5=coreBelief, 实际 4=coreBelief)
2. `cbt_providers.dart:144-149` — `setStep` 不 enforce 3-col (level=three 时 setStep(N) 仍生效, 应当守卫返回 0)
3. `cbt_providers.dart:151-181` — `updateField` 不能 clear field to null (??-coalescing 限制)
4. `cbt_providers.dart:154-170` — `updateField` rebuilds full `MoodEntryDraft` 11 行 boilerplate, 加 `MoodEntryDraft.copyWith` 可解

- [x] Task 4: complete (commits ac75e7a..dcc1ef6, review Approved + 1 Important fix shipped, 3 widget tests, 3 widgets, StatefulWidget migration for controller lifecycle)

### Task 4 Findings (deferred/fixed)

**Important (FIXED in dcc1ef6):**
- `CbtSectionField` `TextEditingController` 在 `build()` 里 new — 改成 StatefulWidget + initState/dispose + 加 parent-rebuild regression test ✓

**Minor (deferred to final review):**
- `cbt_explainer_card.dart:71-72` 注释说 "expanded==null || onToggle==null" 实际是 &&, 改 doc
- test 文件 comment 误导 "ProviderScope + MaterialApp" 但实际没用 ProviderScope
- 1 commit vs brief 说的 2 commits (TDD preserved, git history nit)
- `cbt_explainer_card.dart` trailing comma 风格

- [x] Task 5: complete (commits dcc1ef6..0adeb52, review Needed fixes → 2 fix shipped, 1 widget test, 3 栏 mode + SegmentedButton 集成 + SP sync)

### Task 5 Findings (fixed)

**Important (FIXED in 0adeb52):**
- `mood_recorder_page.dart:99` dispose() reset 跟 SP 持久化冲突 → addPostFrameCallback 在 initState 同步 `cbtDraftProvider.level` 从 `thoughtRecordLevelProvider` ✓
- `cbt_three_column_round84_test.dart:23-26` test name 误导 (没 assert score chip) → 加 5 个 score chip 断言 ✓

**Minor (deferred to final review):**
- 12+ 处硬编码中文 string (cbt_three_column_mode.dart + mood_recorder_page.dart SegmentedButton labels)
- mood_recorder_page 跟 brief `_MoodRecorderPageState` sketch 略不同 (ConstrainedBox maxWidth 560, actions 在 scroll 内)
- `_save()` 13-field MoodEntryDraft 构造 boilerplate, 期望 `MoodEntryDraft.copyWith`
- test 不 exercise level-routing path (cbtDraftProvider override 可加)
- baseline 数字 spec 写 1163 实际 ~1436

- [x] Task 6: complete (commits 0adeb52..0bc7c4a, review Approved + 2 Important fix shipped, 2 widget tests + 3 unit tests, 5/7 栏 wizard + score chip 接入 + 完成 button)

### Task 6 Findings (fixed)

**Important (FIXED in 0bc7c4a):**
- `cbt_wizard.dart:155-160` step 2 score chip 是空 placeholder → 加 `CbtDraftNotifier.updateScore(int)` + wire chip + 加 3 unit test ✓
- `cbt_wizard.dart:79-83` wizard "保存" button 静默丢数据 → label 改 "完成" + comment 说明 parent owns save ✓
- 同样 fix `cbt_three_column_mode.dart` score chip ✓

**Minor (deferred to final review):**
- `cbt_wizard.dart:13-19` 7 栏 step mapping comment 跟代码不对 (comment 说 5=coreBelief, 实际 4=coreBelief)
- test 名字说 "5 栏 wizard" 实际跑 3 栏 state (Riverpod build 期间不能 setLevel 限制)
- step 3 hint 跟 step 1 第一条 prompt 重复
- 缺 7 栏 path / 后退导航 / last-step save 测试

**Forwarded to Task 8 / final review:**
- 缺 widget test 验证 chip click → score update end-to-end
- wizard 完成 → parent 保存 UX 不直 (out of scope)
- 3-栏 + 5/7-栏 step-2 score chip 重复逻辑, 可抽 `ScoreChipGroup` widget

- [x] Task 7: complete (commits 0bc7c4a..2dacff2, review Pending — implementer reports 3/3 widget tests pass, 1445 total, CbtSection 跟项目 6 section 同模式, 跨 feature 边界守, 等 review)

- [x] Task 8: complete (commits 2dacff2..51c9a0e, review Approved + 1 Important fix shipped, 2 widget tests, DayDetailCard 公开 + CBT 5/7 栏摘要)

### Task 8 Findings (fixed)

**Important (FIXED in 51c9a0e):**
- 2 行 `app_database.dart:95, 259` 注释 stale 引用 `_DayDetailCard` → 改成 `DayDetailCard` ✓

**Minor (deferred to final review):**
- `trend_calendar.dart:487-505` `Wrap` with single child (YAGNI hook, brief-mandated 保留)
- test helper class `TestDayDetailCard` 公开 (跟 production 一致, OK)
- 缺 7 栏 `cbtLevel == 7` 路径 widget test
- `find.text` 不够 specific (没 descendant 锁住 CBT block)

- [x] Task 9: complete (commits 51c9a0e..2e16abc, review Pending — 35 ARB keys zh/en/zh_Hant 同步, 1447 pass, 16 守护脚本全绿)

- [x] Task 10: complete (commits 2e16abc..bcce87b, review Pending — integration test + 16 守门员绿 + CHANGELOG + pubspec bump + P0 production bug fix in bcce87b)

### Task 10 Findings (fixed)

**P0 (FIXED in bcce87b):**
- `mood_repository_impl.dart:39-54` add() 漏传 8 个 CBT 字段 → 加上 8 个 `Value(draft.xxx)` + 加 2 个 regression test (走 `MoodRepositoryImpl.add()` 真路径) ✓
- 老 round-trip test 走 `entity.toCompanion()` 没捕获这个 bug (中间漏了 repo add layer)

**P2 (deferred, 在 final review 处理):**
- `CbtWizard` 在 `mood_recorder_page` 的 `SingleChildScrollView` 嵌套触发 `RenderFlex` 布局错误 (widget test 绕开 Dialog 走 Scaffold 直挂)

**Pre-existing unrelated (out of scope):**
- 16 pre-existing setup_* test failure (R77 加 4 个 ConsentCheckRow 老测试没同步)
- 9 pre-existing `RadioListTile` deprecation info

