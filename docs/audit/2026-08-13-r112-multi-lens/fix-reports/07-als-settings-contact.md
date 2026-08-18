# Fix Report: settings/contact/crisis_hotline/reminders_hub AppleListSection 化 (F1 / EM-02 / AH-04)

日期: 2026-08-13 · 状态: 全部 done · 测试: 81+42+1 全绿 (见文末)

## 范围

R111/R112 AH-04/EM-02 点名 "settings 41 Card 最重 + crisis_hotline 0 ALS"
的第一半 (F1 lane)。目标: settings 4 组 + reminders_hub + contact +
crisis_hotline 的 `Card + ListTile` 旧方言 → `AppleListSection` /
`AppListTile` 新方言 (spec §4.5, 以 home/setup/medication 样板为准)。

**改动文件 (24 个)**: settings_page / reminders_hub_page /
profile_group / reminders_group / data_group(未改, 见注) / legal_group(未改, 见注)
/ reminders_section / cbt_section / legal_section / data_management_section
+ 6 sub-tile / assessment_section / notification_status_card /
reminder_cards / contacts_list_widget / crisis_hotline_page + 6 个测试文件。

## 视觉规则落实

- **0 Card**: 我名下文件 Card 从 24 处 → **0 处** (grep 实测), 15 处
  AppleListSection runtime 调用。
- **0 阴影 + 圆角 16 白块**: 全部走 AppleListSection 容器
  (spec §4.5 insetGrouped), `margin: EdgeInsets.zero` (PageScaffold 已给
  pageMarginH 20, 跟 home/medication 样板一致)。
- **hairline 0.5**: 手写 `Divider(height: 1, thickness: 0.5)` 全删, 由
  AppleListSection 自动串联 (评估量表列表的 `indent: 56` 也删 — 样板
  home 不缩进)。
- **13pt ALL CAPS SectionHeader**: group 级 SectionHeader 保留 (R111
  EM-02b 已统一 13pt); 章节内标题不重复 (SectionHeader 覆盖多块时 ALS
  不带 title, 避免"提醒中心"等文案双份)。
- **0 硬编码 Color/fontSize**: 新增代码全走 AppTokens (tintedSuccessSoft /
  radiusChip / textStyleCaption 等); 无新硬编码中文 (check_strings_hardcoded
  规则 2 inline = 0)。
- **章节间距 spacingLg 24 → spacingMd 16** (settings_page 4 组间 /
  profile_group / reminders_group / reminders_hub_page 卡片间, 跟 spec
  §5.1 "整体 spacing 16" 一致)。

## 每个文件

| 文件 | 改法 |
|---|---|
| settings_page.dart | 4 组间 spacingLg → spacingMd |
| profile_group.dart | _UserProfileCard / IAP 已购 / IAP 未购 3 Card → ALS (已购卡绿色 tint 用 DecoratedBox 保留) |
| reminders_group.dart | 组内 spacingLg → spacingMd; RemindersSection / CbtSection / NotificationStatusCard 各自 Card → ALS |
| data_group.dart / legal_group.dart | 未改 — 只有 SectionHeader + 1 个 section widget, 视觉结构已在新方言 |
| reminders_section.dart | Card + 2 tile + 手写 Divider → ALS (2 tile) |
| cbt_section.dart | Card + Padding → ALS + 原 Column (RadioListTile contentPadding 归零) |
| legal_section.dart | Card → ALS (1 tile) |
| data_management_section.dart | Card + 6 tile + 5 手写 Divider → ALS (6 tile) |
| 6 sub-tile (export/cbt_pdf/report/history/import/clear) | AppListTile 加 `contentPadding: EdgeInsets.zero` |
| assessment_section.dart | 4 Card → 4 ALS (评估历史 / 量表列表 / 关于 / 免责声明); scaleNameL10n 调用 (D agent) 原样保留 |
| notification_status_card.dart | 主卡 Card → ALS (3 tile + OEM ExpansionTile); web 分支 AppListTile.carded → ALS; ExpansionTile tilePadding 归零 + childrenPadding 去左右双缩进 |
| reminder_cards.dart | ReminderCard 基类 Card → ALS (mock SMS 警告 Container 原样) |
| reminders_hub_page.dart | 卡间 spacingSm → spacingMd |
| contacts_list_widget.dart | Card + Dismissible 行 + 手写 Divider → ALS |
| crisis_hotline_page.dart | SectionHeader + AppListTile.carded → ALS(title: 地区, children: entries); 拨打/复制逻辑 0 改 |

## 跨 feature 边界 (未动)

- `MedicationsListWidget` / `MedicationListView` (medication feature 的
  Card, profile_group meds section) — **未动**, profile_group 保留
  SectionHeader + 原 list, 待 medication lane 自转后无缝接入。
- `AssessmentReminderSection` (assessment feature 的 Card) — **未动**,
  assessment_section 里原样保留。
- `legal_page.dart` (B agent) / providers (G agent) — 未碰。

## 关键坑: Flutter debug assert "ListTile background color or ink splashes may be invisible"

AppleListSection 的白色容器是 `DecoratedBox(surface)`, ListTile 的
ink 画在最近 Material 祖先上 — ListTile 放进去直接触发 debug assert
(Flutter 3.41 list_tile.dart `_debugCheckBackgroundIsHidden`)。home/
medication 样板全用自定义 Row 所以没人踩过; 本 lane 首次把 ListTile
放进 ALS。修法 (本 lane 文件内): 每个 ListTile 外包一层
`Material(type: MaterialType.transparency)` (私有 helper `_alsCell` 或
inline), 断言通过 + 视觉 0 变化。**遗留建议**: 未来应把
`apple_list_section.dart` 的 DecoratedBox 改成 `Material(color: ...,
clipBehavior: antiAlias)` 一次性根治, 27 处调用方不用各自包 Material
(改动不在本 lane 文件所有权, 未做)。

## 测试 (结构断言同步更新)

- `reminders_hub_round12c_test.dart`: "5 个 card 都用 Card 容器" →
  "5 个 card 都用 AppleListSection 容器" (AppleListSection ×5 + Card ×0)
- `contacts_list_widget_round45_test.dart`: 加 ALS ×1 结构断言; case 3
  描述去 "2 个 Divider" (改由容器自动 hairline)
- `cbt_section_round84_test.dart`: 加 ALS ×1 + Card ×0
- `four_groups_round95_test.dart`: DataGroup/LegalGroup 各加 ALS ×1 + Card ×0
- `notification_status_card_round20_test.dart`: mobile case 加 ALS ×1 + Card ×0

**实测**: `test/presentation/pages/settings/` + `pages/contact/` +
contacts_list_widget_round45 + reminders_hub_round12c +
reminders_hub_safety_gate_round8 + notification_status_card_round20 +
notification_status_card_permission_round8 = **81 pass 0 fail**;
再跑 home_emil_round81 + task10 lock-in + data_management_section 子目录 +
four_groups = **42 pass**; integration cbt flow = **1 pass**。

## 守门员

- `flutter analyze` (全项目): 0 error / 0 warning (唯一涉及我文件的 info
  = notification_status_card.dart:121 `goSettings == true`, 另一 agent
  GP-10 未提交改动, 非本 lane)
- `python scripts/check_cross_feature.py` → 138 files, 0 violations
- `python scripts/check_strings_hardcoded.py` → inline 0 处
- `python scripts/check_apple_health_claim.py` → OK

## 业务行为保证

开关/导航/按钮回调/文案全部原样: IAP buy 流程、RemindersHub 5 卡 +
2 bottom sheet、CBT SP 写入、export/import/clear 全流程、联系人
ConsentDialog + swipe 删除、热线 tel:/复制 均 0 改 (仅容器/间距/tile
padding 变)。
