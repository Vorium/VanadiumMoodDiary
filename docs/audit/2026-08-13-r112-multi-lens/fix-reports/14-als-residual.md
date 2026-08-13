# Fix Report: ALS 化视觉残留 — MedicationsListWidget + AssessmentReminderSection (F1 遗留)

日期: 2026-08-14 · 状态: 2/2 done · 测试: 127 pass 0 fail (见文末)

## 范围

F1 lane (fix-report 07) 当时因跨 feature 边界留下 2 个嵌在已 ALS 化 settings
组里的 Card 旧方言组件。本批把它们转成 AppleListSection (iOS insetGrouped
白块 + hairline 0.5 + 0 阴影, spec §4.5), 对齐宿主 (profile_group /
assessment_section)。

**改动文件 (6 个)**:

| 文件 | 改法 |
|---|---|
| `medications_list_widget.dart` | 0 逻辑改, 仅 header 注释补 v0.32 round 14 记录 |
| `medication_list_view.dart` | 用药日历入口 `AppListTile.carded` (Card) → ALS + `AppListTile.standard(contentPadding: EdgeInsets.zero)`; active/stopped 2 处 `Card + 手写 Divider(height: 1)` → ALS (hairline 由容器自动串联) |
| `medication_row.dart` | 加 `contentPadding` 透传参数 (默认 null 行为不变), 供 ALS 宿主传 `EdgeInsets.zero` 避免 ListTile 自带 16 横向 double padding |
| `assessment_reminder_section.dart` | loading + 主态 2 处 Card → ALS (`margin: EdgeInsets.zero`); SwitchListTile/AppListTile `contentPadding: EdgeInsets.zero`; 2 处手写 `Divider(height: 1, thickness: 0.5)` 删 (容器自动 hairline); 帮助文字行去外层 `Padding(edgeInsetsMd)` (由 ALS cell 16/12 提供) |
| `medications_list_split_round45d_test.dart` | 3 个 case 加 ALS/Card 结构断言 |
| `four_groups_round95_test.dart` | ProfileGroup case 加 `Card ×0` lock-in (子树含两个转换组件) |

## 视觉规则落实

- **0 Card**: 2 组件树内 Card 4 处 → 0 处 (grep 实测; 同目录其余文件如
  medication_calendar_grid 的 Card 属其他组件, 不在本批范围)
- **0 阴影 + 圆角 16 白块**: 全走 AppleListSection 容器, `margin: EdgeInsets.zero`
  (宿主 PageScaffold 已给 pageMarginH 20, 跟 F1 lane 样板一致)
- **hairline 0.5**: 手写 Divider 全删, 由容器自动串联
- **0 硬编码 Color/fontSize**: 无新增硬编码 (check_strings_hardcoded 规则 2 = 0)
- **业务行为 0 改**: 编辑/删除/swipe/续方/开关/间隔选择/文案/路由全原样

## 关键实现决策

1. **MedicationRow contentPadding 透传**: MedicationRow 内部 ListTile 默认自带
   16 横向 contentPadding, 放进 ALS cell (16/12) 会 double 成 32。跟 F1 lane
   contacts_list_widget 同款修法 — 透传 `contentPadding: EdgeInsets.zero`。
2. **Material 断言**: AppleListSection 已在 R112 round 8 root fix 从 DecoratedBox
   改为 `Material(color: surfaceColor, clipBehavior: antiAlias)` (SDK list_tile.dart
   `_findIntermediateWidget` 断言实读验证), ListTile/SwitchListTile ink 有 Material
   祖先, 无需 F1 lane 的 `_alsCell` 透明 Material 包裹。
3. **Dismissible 在 ALS cell 内**: 跟 contacts_list_widget 同模式 (Dismissible 作
   ALS child, swipe background 内嵌于 cell padding), 视觉与行为经 round45d
   test 验证。

## 文件所有权说明

任务清单只列 `medications_list_widget.dart`, 但该文件纯业务 (3 Set + 4 handler),
Card 实际在渲染子组件 `medication_list_view.dart` (同组件树内), 且 row 需
contentPadding 透传 — 故组件树内 3 文件 (list_widget / list_view / row) 一起改,
`medications_list_widget.dart` 本身 0 逻辑改动。

## 测试 (结构断言同步更新)

- `medications_list_split_round45d_test.dart`: 3 case 加断言 —
  - stopped list case: ALS ×1 + Card ×0
  - active meds case: ALS ×2 (日历入口 + active 列表) + Card ×0
  - MedicationsListWidget(meds=[1]): ALS ×2 + Card ×0
- `four_groups_round95_test.dart` ProfileGroup: 加 `Card ×0` lock-in
  (meds=[] → EmptyState 无 Card + AssessmentReminderSection 已 ALS)

**实测**:

- `medications_list_split_round45d + four_groups_round95 + settings_page_round45`
  = **17 pass 0 fail**
- `test/presentation/pages/settings/` + `test/presentation/pages/medication/` +
  `apple_health_phase4_global_sanity_round12` = **110 pass 0 fail**
  (注: 中途 `add_medication_page_round7b_test.dart` 短暂 load fail 是并行
  agent 未提交重构 `add_medication_submit_flow.dart` 尚未落盘, 与本次改动无关;
  该文件随后由并行 agent 创建, 复跑全绿)

## 守门员

- `flutter analyze` (全项目): 我的 6 个文件 0 issue; 全项目 113 info 全为
  其他文件存量 (基线 115 → 113, 本批净 -2 info 无新增)
- `python scripts/check_cross_feature.py` → 137 files, 0 violations
- `python scripts/check_strings_hardcoded.py` → 规则 2 (inline) = 0 处
- `dart scripts/check_all.dart` → 纯度 + 一致性 双过

## Concerns / 遗留

1. **stale 注释 (非我文件)**: `profile_group.dart:174-177` 与
   `assessment_section.dart:7-9/57-58` 的 "MedicationsListWidget 内部 Card
   跨 feature 不动 / AssessmentReminderSection 是 assessment feature 的 Card,
   跨 feature 不动" 注释现已过期 — 属 settings lane 所有权, 建议该 owner 顺手清。
2. **MedicationRow contentPadding 新参数** 默认 null, 旧调用方行为不变,
   但 medication feature 其他未来调用方应记得传 `EdgeInsets.zero` 才能进 ALS。
3. 同目录其余 Card (medication_calendar_grid / day_detail / legend /
   assessment_center_card / result_panel 等) 属其他组件, 未在本次范围。
