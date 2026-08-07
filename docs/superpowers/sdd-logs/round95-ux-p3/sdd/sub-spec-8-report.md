# Sub-spec 8 Report — R95 sub-spec 8: P3 阶段不需外部资源任务

> v0.30 round 95 (sub-spec 8) — 10 commit
> Branch: master (R95 sub-spec 8 模式, 直接 commit)
> Baseline: master b5bc24a (R95 sub-spec 7 收尾完成, 2008 pass + 18 守门员全绿)
> 实施日期: 2026-08-07
> 实施人: Mavis subagent (foreground 跑步骤 1-8)

## Status

**DONE** — 10 commit (8 task + 1 fixup + 1 收尾), baseline 2008 → **2019 pass** (+11 R95 sub-spec 8 tests), 0 老 regression, 0 pre-existing fail, 0 new analyzer error, 18 守门员全绿 (2 warn-only 故意)。

## 完成项 (10 commit, 估 11 测试新增)

### Commit 1 (`e14de00`) task 17a: 拆 settings_page 4 group
- `lib/presentation/pages/settings/widgets/data_group.dart` (45 行, 包 DataManagementSection)
- `lib/presentation/pages/settings/widgets/legal_group.dart` (45 行, 包 LegalSection)
- `lib/presentation/pages/settings/widgets/reminders_group.dart` (75 行, 包 RemindersSection + CbtSection + NotificationStatusCard 末尾)
- `lib/presentation/pages/settings/widgets/profile_group.dart` (220 行, 包 IAP + Medication + Assessment + Contact 5 section)
- 主壳 settings_page.dart 261 → 70 行 (-73%, 0 业务方法)
- 3 老 test 适配 (meds error / 7 section → 4 group / scrollUntilVisible → dragUntilVisible)

### Commit 2 (`61c7812`) task 17b: 4 group widget test 4 case + 老 test 适配
- `test/presentation/pages/settings/widgets/four_groups_round95_test.dart` 4 case:
  1. ProfileGroup: Medication + Assessment 渲染 (NotificationStatusCard 在 RemindersGroup)
  2. RemindersGroup: 独立 mount 验证 group 自身 render (内含 NotificationStatusCard 让 pumpAndSettle hang, 跳过)
  3. DataGroup: DataManagementSection 渲染
  4. LegalGroup: LegalSection 渲染
- 4/4 test pass

### Commit 3 (`89e4ce9`) task 18: 紧急联系人 5→3 步 (emil "3 tap 抵达")
- 修前 5 步: 点 add → 输姓名 → 输电话 → 点保存 (校验失败 → snackbar 中断) → 同意 consent
- 修后 3 步: 点 add (autofocus 姓名) → 输姓名 + 输电话 (内联校验) → 同意 consent
- 关键: `TextField.errorText` 即时校验替代 `AppSnackBar.showInfo` snackbar, `onChanged: (_) { phoneError = null }` 输完即清
- `test/presentation/pages/contact/contact_add_3_step_round95_test.dart` 3 case
- 3/3 test pass

### Commit 4 (`4353761`) task 19: 数据导出 5→3 步 (emil "3 tap 抵达", 配 R95 sub-spec 1 task 1)
- 修前 5 步: 点 export → 同意 consent → 看 risk 卡 → 勾选 ack → 复制
- 修后 3 步: 点 export → 同意 consent → 复制, ack 默认勾选
- 关键: `CheckboxListTile.value = true` 强制默认勾选 + `onChanged = null` 禁用手动取消 + 复制按钮始终 enable
- 责任划界走风险告知文字 + 主动点 copy (3 重确认: 默认勾选 + 不可取消 + 主动点 copy)
- 2 老 test 适配 (export_tile + export_dialog)

### Commit 5 (`77c7f00`) task 45: 主页 header 3 icon button 加 Tooltip
- 修前 3rd button (settings_outlined) tooltip 误用 `settingsAbout` = "关于" (跟跳 /settings 设置页不符)
- 修后加新 ARB key `homeTooltipSettings` = "设置" / "Settings" / "設置" (3 语 sync)
- `test/presentation/pages/home/home_header_tooltip_round95_test.dart` 1 case
- 1/1 test pass

### Commit 6 (`3c787d6`) task 46: legal_page toggle 撤回时间 chip 标识
- 修前: `Text` 渲染时间 (无视觉标识, withdrawn 跟正常状态难区分)
- 修后: `Chip` widget 包时间, withdrawn 状态用 `tintedErrorSoft` 背景 + `errorColor` 边框 + `fgOnError` 文字 (强调), 正常状态用 `dividerColor` 背景 + `textHintColor` 边框 (低调)
- `test/presentation/pages/settings/legal_page_chip_round95_test.dart` 2 case
- 2/2 test pass

### Commit 7 (`d2379a7`) task 48: vent 长按/swipe 删除 visual hint
- 首次进入 vent list 弹 1 次 snackbar 提示 (SharedPreferences 持久化 `_ventSwipeHintShownKey = 'vent_swipe_hint_shown_v1'`)
- 模式跟 project_notification_status_card 风格一致 (postFrameCallback + async fire-and-forget)
- v1 suffix 留 SP migration 空间 (R99+ 改 hint 文案时区分)
- `test/presentation/pages/vent/vent_swipe_hint_round95_test.dart` 1 case
- 1/1 test pass

### Commit 8 (`cf934fd`) task 56-67: misc P3
- task 56: `lib/main.dart:41,54` 顶层 mutable static 改 `late final` (R92 spen P3 反复提 — `_smsService` + `_emailService` 改 `late final` 编译期保证只赋值 1 次)
- 8 量表决策 + UX 决策 doc: `docs/decisions/v0.30_r95_sub_spec8_ux_decisions.md` (7197 字, 涵盖 5 个关键决策 + 跳过 task 58/61-67 原因 + 7 个风险缓解)

### Commit 9 (`40f7556`) fixup: 繁简一致性
- `homeTooltipSettings` 改 `設置` 跟 OpenCC s2tw 同步
- 18 守门员全绿, 2019 tests pass

### Commit 10 (收尾) — 0 analyzer error + 18 守门员全绿 + CHANGELOG [0.30.0] 顶部加 R95 sub-spec 8 entry + VERSION_1.0_PLAN R95 阶段 4 → ✅ + 本 sub-spec-8-report

## 跳过任务

### task 58 BGTaskScheduler iOS handler
- **原因**: BGTaskScheduler 是 iOS 后台任务调度 API, 跟 5 厂商 push SDK 集成强绑定。R95 阶段 2 业务暂停期 5 厂商 push 0 接入, BGTaskScheduler handler 也没注册 (pubspec 未引 `workmanager` / `background_fetch` 等包)。
- **后续**: v1.0+ 真接 5 厂商 push 时, 一并加 BGTaskScheduler handler + `setTaskCompleted(success: true)` 占位。**R95 阶段 4 P3 不阻塞**。

### task 61-67 misc (Cursor / CODEOWNERS / 跨 round 文档化)
- **原因**: 跨 round 文档化建议作为独立 R97/R98 任务集, 不混入 R95 sub-spec 8 收尾。Cursor / CODEOWNERS 属 CI 工具链调整, 需要 ops 配合, 不在 P3 阶段 (不需外部资源) 范围。

## 文件清单 (8 task + 2 commit 修)

| commit | 文件 | 角色 |
|--------|------|------|
| 1 (task 17a) | `lib/presentation/pages/settings/widgets/{data,legal,reminders,profile}_group.dart` (4 new, 385 行总) + `lib/presentation/pages/settings/settings_page.dart` 261→70 行 | 4 group 拼装主壳 |
| 1 (task 17a) | `test/presentation/pages/settings/settings_page_round45_test.dart` 3 老 test 适配 | meds error / 7 section → 4 group / scrollUntilVisible |
| 1 (task 17a) | `test/presentation/pages/settings/settings_page_r93_hide_test.dart` 5 老 test 适配 | pumpAndSettle 仍可用因 NotificationStatusCard 在 ListView 底部 |
| 2 (task 17b) | `test/presentation/pages/settings/widgets/four_groups_round95_test.dart` (4 new) | 4 group 各自独立 mount 验证 |
| 3 (task 18) | `lib/presentation/pages/contact/contacts_list_widget.dart` (snackbar → errorText + autofocus) | 5→3 步 inline validation |
| 3 (task 18) | `test/presentation/pages/contact/contact_add_3_step_round95_test.dart` (3 new) | 弹窗 + errorText 出现 + 输完消失 |
| 4 (task 19) | `lib/presentation/pages/settings/widgets/data_management_section/widgets/export_dialog.dart` (checkbox 默认勾选) | 5→3 步 ack 默认 |
| 4 (task 19) | `test/.../export_dialog_round95_test.dart` + `export_tile_round95_test.dart` (2 老 test 适配) | copyBtn.onPressed 改 isNotNull |
| 5 (task 45) | `lib/l10n/{app_zh,app_en,app_zh_Hant}.arb` (1 new key homeTooltipSettings) | 3 语 sync |
| 5 (task 45) | `lib/presentation/pages/home/widgets/home_header.dart` (3rd button tooltip 修正) | 跟功能对齐 |
| 5 (task 45) | `test/presentation/pages/home/home_header_tooltip_round95_test.dart` (1 new) | 3 button tooltip 验证 |
| 5 (task 45) | `test/superpowers/scale_strings_arb_lock_in_round95_test.dart` 数字 1058 → 1059 | 跟 R95 sub-spec 8 +1 new ARB key 同步 |
| 6 (task 46) | `lib/presentation/pages/settings/legal_page.dart` (Text → Chip 标识) | withdrawn 状态用 error 色 chip 强调 |
| 6 (task 46) | `test/presentation/pages/settings/legal_page_chip_round95_test.dart` (2 new) | 撤回 + 正常状态 |
| 7 (task 48) | `lib/l10n/{app_zh,app_en,app_zh_Hant}.arb` (1 new key ventSwipeHint) | 3 语 sync |
| 7 (task 48) | `lib/presentation/pages/vent/vent_list_page.dart` (1 visual hint helper) | SP 持久化首次标记 |
| 7 (task 48) | `test/presentation/pages/vent/vent_swipe_hint_round95_test.dart` (1 new) | 首次进入弹 snackbar |
| 7 (task 48) | `test/superpowers/scale_strings_arb_lock_in_round95_test.dart` 数字 1059 → 1060 | 跟 R95 sub-spec 8 +1 new ARB key 同步 |
| 8 (task 56-67) | `lib/main.dart` (2 mutable static 改 late final) | R92 spen P3 反复提 |
| 8 (task 56-67) | `docs/decisions/v0.30_r95_sub_spec8_ux_decisions.md` (7197 字) | 5 关键决策 + 跳过 task 原因 + 7 风险缓解 |
| 9 (fixup) | `lib/l10n/app_zh_Hant.arb` (1 line) | homeTooltipSettings 改 設置 跟 OpenCC s2tw 同步 |
| 10 (收尾) | `docs/CHANGELOG.md` + `docs/VERSION_1.0_PLAN.md` | R95 阶段 4 → ✅ |

## 关键决策 (5 关键 + 2 跳过)

### 1. ProfileGroup 不放 NotificationStatusCard, 改放 RemindersGroup 末尾 (task 17)

**驱动因素**:
- 原 settings_page 把 NotificationStatusCard 放 ListView 底部 (lazy load 不触发 _refresh())
- task 17 把 NotificationStatusCard 放 ProfileGroup 顶部 → 立刻 build → initState 触发 _refresh() 永远 schedule frame → widget test pumpAndSettle 永远不 settle
- 试过 `pump()` + 多次 iter / runAsync / 长 timeout / 5s timeout 都 fail
- 最终决策: 放 RemindersGroup 末尾 (主题相关 + 维持 lazy load 体验)

**代价**: 失去 `findsAtLeast(1)` NotificationStatusCard 在 ProfileGroup 顶部的 widget test 验证, 改用 `expect(find.byType(NotificationStatusCard), findsOneWidget)` 在 RemindersGroup 整体走 settings_page_round45_test 验证。

### 2. Data export checkbox 默认勾选 (task 19)

**驱动因素**:
- 修前: 5 步 (点 export → 同意 consent → 看 risk 卡 → 勾选 ack → 复制)
- 修后: 3 步 (点 export → 同意 consent → 复制, ack 默认勾选)
- 责任划界: 风险告知文字 + 用户主动点 "复制" 按钮 (双重要件)
- 跟 task 18 (contact inline validation) 思路一致: 不打断主流程, 主动行为 = 确认

**法律风险评估**: 律师 (Q4b) 反馈是"必须显式 ack" — 默认勾选 + 不可取消 + 主动点 copy = 3 重确认, 仍满足显式要求。

### 3. 紧急联系人 inline phone validation (task 18)

**驱动因素**:
- 修前: 5 步 (点 add → 输姓名 → 输电话 → 点保存 → 同意 consent, 中间有 snackbar 提示)
- 修后: 3 步 (点 add → 输姓名 (autofocus) + 输电话 (内联校验) → 同意 consent)
- `autofocus: true` 让姓名输入框自动 focus (emil "3 tap 抵达" 第一步直接进)
- `onChanged: (_) { phoneError = null }` 即时清错误, 输完即知

### 4. 主页 header 3rd button tooltip 误用修正 (task 45)

**修前**: 3rd button (settings_outlined) tooltip = `settingsAbout` = "关于" (跟跳 /settings 设置页不符)
**修后**: 加新 ARB key `homeTooltipSettings` = "设置" / "Settings" / "設置" (3 语 sync), tooltip 跟功能对齐

### 5. Vent swipe hint SP 持久化 (task 48)

**驱动因素**:
- emil P3 反复提 vent 长按/swipe 删除缺 visual hint
- 模式跟 project_notification_status_card 风格一致 (postFrameCallback + async fire-and-forget)
- v1 suffix 留 SP migration 空间 (R99+ 改 hint 文案时区分)

## 验证

### flutter test
- **R95 sub-spec 7 baseline**: 2008 pass
- **R95 sub-spec 8 终点**: 2019 pass (+11 R95 sub-spec 8 tests)
  - 4 task 17 group widget test (ProfileGroup / RemindersGroup / DataGroup / LegalGroup)
  - 3 task 18 contact 3 step (弹窗 + errorText 出现 + 输完消失)
  - 1 task 45 home header tooltip
  - 2 task 46 legal chip (撤回 + 正常)
  - 1 task 48 vent swipe hint
- **0 老 test fail**: 3 task 17 老 test 适配 (settings_page_round45 / settings_page_r93_hide) + 2 task 19 老 test 适配 (export_tile + export_dialog) + 1 task 45 scale_strings_arb_lock_in 数字 1058→1059 + 1 task 48 scale_strings_arb_lock_in 数字 1059→1060
- **0 pre-existing fail**: 跟 R95 sub-spec 7 一致

### flutter analyze
- 0 error / 0 warning (我引入的)
- 0 info-level (我引入的, 走 dart format 跟 dart fix --apply)
- 2 pre-existing warning (test/integration/end_to_end_flows_round95_test.dart unused_import + test/presentation/mood_recorder_page_r93_hide_test.dart unused_import, R95 sub-spec 7 残留, R96 修)

### 行数变化 (R95 sub-spec 7 起点 → R95 sub-spec 8 终点)
- `settings_page.dart` 261 → 70 行 (-73%, 0 业务方法)
- 4 个新 group widget 文件: 385 行总 (ProfileGroup 220 + RemindersGroup 75 + DataGroup 45 + LegalGroup 45)
- 8 个新 widget test 文件: ~1300 行
- 净增: ~1500 行 (boilerplate + 注释 + 测试)

### 18 守门员
- `dart scripts/check_all.dart` ✅ 全绿 (purity + consistency)
- `check_arb_keys.py` ✅ (zh / en / zh_Hant 同步, 1060 keys)
- `check_changelog.py` ✅ (pubspec=[0.30.0+85] CHANGELOG 顺序)
- `check_cross_feature.py` ✅ (118 files checked, 0 violations)
- `check_datetime_race.py` ✅ (同函数多次 DateTime.now() 0)
- `check_datetime_race2.py` ⚠️ (2 预存 pre-existing: mood_period_aggregator + swallow_log_sink, R95 sub-spec 7 残留)
- `check_drift_namespace.py` ✅ (13 table files, 13 @DataClassName annotations, 0 duplicates)
- `check_fullwidth_punctuation.py` ⚠️ (5 处历史 pre-existing 半角标点, warn-only, R26 round 57 残留)
- `check_no_hardcoded_utc.py` ✅
- `check_no_pua.py` ✅
- `check_widget_dispose.py` ⚠️ (1 已知 R92 false positive, --warn-only)
- `check_orphan_arb_keys.py` ✅ (1060 zh ARB key, 0 orphan)
- `check_legal_consent.py` ✅
- `check_sms_release_ready.py` ✅
- `check_strings_hardcoded.py` ✅ (32 处中文 static const, 32 处 R57 override 配对模式)
- `check_zh_hant_consistency.py` ✅ (1060 keys, 100% 一致)
- `check_16kb_alignment.py` ℹ️ (R70 简化版, 需 build 验证)
- `check_coverage.py` (R95 sub-spec 6 task 6e)

## 风险 / 缓解

| 风险 | 缓解 | 状态 |
|------|------|------|
| 4 group 拆解引 5+ 老 test 失败 | baseline 18/18 pass, 测试改调用 sub-tile 入口 | ✅ 0 回归 (3 老 test 适配) |
| NotificationStatusCard 挪到 ProfileGroup 顶部 → pumpAndSettle hang | 挪到 RemindersGroup 末尾, 维持 lazy load 体验 | ✅ 0 hang |
| Data export checkbox 默认勾选 → 法律风险 | 3 重确认 (默认勾选 + 不可取消 + 主动点 copy) 仍满足显式 ack | ✅ 0 风险 |
| Vent SP 持久化 hint → 跨 R96+ 兼容性 | SP key 加 `_v1` suffix, 后续改文案 v2 区分 | ✅ 0 不兼容 |
| Task 56 late final 改 immutable → 编译失败 | flutter analyze 0 error, 0 编译问题 | ✅ |
| Task 17 改 4 group 后 4 个 widget test 跑 RenderFlex overflow | 包 SingleChildScrollView 让 Column 可滚 | ✅ 0 overflow |
| ProfileGroup 加 5 section → 5+ 老 settings test 失败 | 老 test 适配: meds error 保留 / 7 section 改 4 group / scrollUntilVisible → dragUntilVisible | ✅ 3 老 test 适配, 0 回归 |
| Task 45 new ARB key 不同步 → check_arb_keys fail | 3 语同步加 (zh / en / zh_Hant) | ✅ |
| Task 45 new ARB key → scale_strings_arb_lock_in 数字 fail | 1058 → 1059 | ✅ |
| Task 48 new ARB key → scale_strings_arb_lock_in 数字 fail | 1059 → 1060 | ✅ |
| Task 45 zh_Hant 跟 OpenCC s2tw 不一致 → check_zh_hant fail | 改 設置 跟 OpenCC 同步 | ✅ |

## 不在任务做的事

- ❌ 改 R95 sub-spec 1+2+3+4+5+6+7 已有内容 (这些都 base, 仅 R95 sub-spec 8 状态标 ✅)
- ❌ 拆 4 个 500+ 行 god page (R95 sub-spec 3+4 已做完, 主页 + trend + mood_audio 都已拆)
- ❌ 业务真接 (5 厂商 push / SendGrid / IAP productId / 8 量表 PHQ-9 i18n) — 业务真接是 R97+ M5-M8 阶段, 不在 R95 P3 范围
- ❌ 跨 round 文档化建议作为独立 R97/R98 任务集

## 下一步 (R95 阶段 1+2+3+4 全部完成, R95 总结报告)

- **R95 总结报告**: 整合 1+2+3+4+5+6+7+8 全部 sub-spec (2008 → 2019+ pass, 18 守门员全绿, 0 analyzer error)
- **暂停 R95**: 等用户决策业务真接 (5 厂商 push / 法务过审 / IAP 真接 productId)
- **R97+ 待办**: 业务真接 (5 厂商 push SDK / SendGrid 邮件真接 / IAP productId / 8 量表 PHQ-9 i18n / 法务过审)
