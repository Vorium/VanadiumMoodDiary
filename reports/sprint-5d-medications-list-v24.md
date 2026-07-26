# Sprint #5d — medications_list_widget god class 拆解报告 (v0.24 round 45)

> **视角**：emilkowalski（god class 拆解样板）
> **基线**: v0.24 round 45 / commit `465b827` (HEAD) / 974 test cases / 0 analyze error
> **设计文档**: `docs/refactor/medications_list_split_design.md` (370 行 / 17.1KB)
> **完成日期**: 2026-07-26
> **不要 commit** (root 决定 commit 时机)

---

## 1. 拆解前/后行数对比

| 文件 | 拆解前 | 拆解后 | Δ | 状态 |
|---|---|---|---|---|
| `medications_list_widget.dart` (orchestrator) | **554** | **203** | **-351 (-63%)** | ✅ 大幅瘦身 |
| `widgets/medication_list_view.dart` (新, 列表渲染) | 0 | 155 | new | ✅ presentation-only 抽出 |
| `widgets/medication_row.dart` (新, 单行) | 0 | 219 | new | ✅ 现有 `_MedicationRow` 重命名 + 加 `enableSwipe` |
| `widgets/medication_empty_state.dart` (新, 空态) | 0 | 49 | new | ✅ 复用 2 种空态 (noMeds/noActive) |
| `widgets/refill_days_dialog.dart` (新, 续方 dialog) | 0 | 81 | new | ✅ 移到独立文件 (refill_manage 可复用) |
| `edit_medication_dialog.dart` (已有, 不动) | 406 | 406 | 0 | ✅ 保留不动 |
| **拆解前** (554 + 406 = 960) | — | — | — | — |
| **拆解后** (203 + 155 + 219 + 49 + 81 + 406 = 1113) | 960 | 1113 | +153 (+16%) | (+16% 是 import + 子 widget 接口注释 + doc comment) |
| `test/presentation/medications_list_split_round45d_test.dart` (新, 10 case) | 0 | 293 | new | ✅ 覆盖子 widget mount + 公开 API 签名不变 |
| `docs/refactor/medications_list_split_design.md` (新, 设计文档) | 0 | 370 | new | ✅ emil 决策框架 + 数据流图 |

> 行数增加 16% 是合理代价 — 拆出来每个子 widget 有独立 doc comment + 接口注释 + import 块
> 实际业务代码减少: orchestrator 203 行 (3 Set + 4 handler + 10 行 build) vs 原 554 行 (3 Set + 4 handler + 263 行 build)

### Spec 目标对比

| 子 widget | spec 目标 | 实际 | 状态 |
|---|---|---|---|
| `MedicationsListWidget` (orchestrator) | ~80 行 | **203 行** | ⚠️ 超 123 行 (但比原 554 行 -63%, 单一职责清晰) |
| `MedicationListView` | ~100 行 | **155 行** | ⚠️ 超 55 行 (active/stopped 双列表 + helper method) |
| `MedicationRow` | ~190 行 | **219 行** | ⚠️ 超 29 行 (现 _MedicationRow 几乎 1:1 搬, 加 enableSwipe 参数) |
| `MedicationEmptyState` | ~50 行 | **49 行** | ✅ 略低 |
| `RefillDaysDialog` | ~70 行 | **81 行** | ✅ 略高 (含 5 个 hint + 默认 7 回落) |

> orchestrator 203 行 跟 spec 80 行差距分析:
> - 4 个 handler 业务逻辑共 150 行 (edit/delete/swipeDelete/refill 各 20-60 行)
> - 3 个 Set 状态 3 行
> - 13 行 import 块
> - 22 行 header comment (v0.12-0.24 演进史)
> - 10 行 build (delegate to MedicationListView + MedicationEmptyState)
>
> 决定: 203 行可接受 — 比 554 减 63%, 单一职责清晰 (state + 4 handler), 不强行压缩注释.

---

## 2. 5 个新子 widget 接口摘要

### `MedicationListView` (155 行)

```dart
class MedicationListView extends StatelessWidget {
  final List<MedicationEntity> meds;
  final Set<int> deleting;          // 引用 parent state
  final Set<int> editing;
  final Set<int> editingRefill;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(MedicationEntity med) onEdit;
  final Future<void> Function(MedicationEntity med) onEditRefill;
  final Future<void> Function(MedicationEntity med) onSwipeDelete;

  /// presentation-only: 渲染用药日历入口 + active list + stopped list
  /// 业务全在 parent handler, 此 widget 只管 view
}
```

- **状态**：无（全 StatelessWidget）
- **职责**：active/stopped 分类 + 4 个 helper build method (`_buildCalendarEntry` / `_buildActiveList` / `_buildStoppedHeader` / `_buildStoppedList`)
- **频度**：tens/day

### `MedicationRow` (219 行)

```dart
class MedicationRow extends StatelessWidget {
  final MedicationEntity med;
  final bool isDeleting;
  final bool isEditing;
  final bool isEditingRefill;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onEditRefill;
  final Future<void> Function(MedicationEntity) onSwipeDelete;
  final bool enableSwipe;  // 停药不启用 (新参数)

  /// 单行: ListTile + Dismissible (active) + 3 IconButton (edit / refill / delete)
  /// 全 Stateless, 状态由 parent 透传
}
```

- **状态**：无
- **职责**：单行渲染 + swipe 触发 (active only)
- **频度**：tens/day (每个药一行)

### `MedicationEmptyState` (49 行)

```dart
enum MedicationEmptyKind { noMeds, noActive }

class MedicationEmptyState extends StatelessWidget {
  final MedicationEmptyKind kind;

  /// 复用 2 种空态:
  /// - noMeds: "还没添加常吃药" + 添加按钮
  /// - noActive: "没有在用的药" + 提示
}
```

- **状态**：无
- **职责**：统一 2 种空态入口, 复用 `EmptyState` 集中器
- **频度**：rare (用户首次打开 / 全部停药时)

### `RefillDaysDialog` (81 行)

```dart
class RefillDaysDialog extends StatefulWidget {
  final int initial;

  /// 续方提前天数选择 (5 个预设 [3, 5, 7, 14, 30])
  /// initial 不在 _options 时回落到 7
  /// 返回 int? (null = 取消)
}
```

- **状态**：`_selected: int` (内部)
- **职责**：弹 dialog 选续方提前天数
- **频度**：tens/day (per medication per refill edit)
- **复用性**: 未来 `refill_manage_page` 可直接 import 用

### `MedicationsListWidget` (203 行 orchestrator)

```dart
class MedicationsListWidget extends ConsumerStatefulWidget {
  final List<MedicationEntity> meds;  // 公开 API 不变
  const MedicationsListWidget({super.key, required this.meds});
}

class _MedicationsListWidgetState extends ConsumerState<MedicationsListWidget> {
  // ===== 3 个跨 widget 状态 =====
  final Set<int> _deleting = {};
  final Set<int> _editingRefill = {};
  final Set<int> _editing = {};

  // ===== 4 个业务流程 handler (保留所有 P0 修复) =====
  Future<void> _editMedication(MedicationEntity med) async { ... }
  Future<void> _deleteMedication(int id) async { ... }
  Future<void> _swipeDeleteMedication(MedicationEntity med) async { ... }
  Future<void> _editRefill(MedicationEntity med) async { ... }

  @override
  Widget build(BuildContext context) {
    if (widget.meds.isEmpty) {
      return const MedicationEmptyState(kind: MedicationEmptyKind.noMeds);
    }
    return MedicationListView(
      meds: widget.meds,
      deleting: _deleting, editing: _editing, editingRefill: _editingRefill,
      onDelete: _deleteMedication,
      onEdit: _editMedication,
      onEditRefill: _editRefill,
      onSwipeDelete: _swipeDeleteMedication,
    );
  }
}
```

- **状态**：3 Set (跨 widget 状态, parent 持有, 子 widget 引用)
- **职责**：业务流程编排 (4 handler) + build delegate
- **频度**：tens/day

---

## 3. 现有 P0/P1 修复保留验证

| 修复 | 来源 | 保留位置 |
|---|---|---|
| swipe-to-dismiss + Undo snackbar | v0.21 round 23 P1-26 | `MedicationRow(enableSwipe: true)` + `_swipeDeleteMedication` handler |
| `DateTime.now()` 一次取 (避免 midnight race) | v0.16 round 19 P0-2 | `_editRefill` handler 入口 `final now = DateTime.now()` |
| notification reschedule after refresh | v0.23 P0-3 H2 | `_editRefill` handler `await ref.refresh(medicationsProvider.future)` |
| Haptics.warning on swipe | v0.21 round 23 | `_swipeDeleteMedication` handler |
| AppSnackBar 集中化 (4 处) | v0.22 round 30 sp-zh P1-16 | 4 handler 全用 `AppSnackBar.xxx` |
| `fgOnError` token | v0.22 round 30 emil P2-6 | `MedicationRow` background IconButton color |
| `ChipBadge` 集中器 | v0.24 round 43 emil P1-01 H-05 | `MedicationRow` stopped 状态 |
| `swallowError` 模式 | v0.22 round 30 | 3 个 catch block 走 `AppSnackBar.error` (含 swallow) |
| isInRefillWindow + isRefillOverdue 同步 | v0.14 fix | `MedicationRow.refillTextColor` + icon 同源 |
| `DateTime.now()` 跨 midnight race | v0.16 round 19B | `_daysUntilRefill` 函数入口一次取, 全函数复用 |
| Dismissible key 稳定 (med-${med.id}) | v0.21 round 23 | `MedicationRow` build (`ValueKey('medication-${med.id}')`) |

---

## 4. 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze` | **0 error / 0 warning** (56 info-level 历史遗留, 0 from my files) |
| `flutter test` (全部) | **986/986 pass** (从 baseline 974 + 10 新 split test + 2 已有 in-progress WIP) |
| `flutter test test/presentation/medications_list_split_round45d_test.dart` (新) | **10/10 pass** |
| `flutter test test/presentation/medication_calendar_round13c_test.dart` (现有) | **7/7 pass** (无 regression) |
| `flutter test test/presentation/refill_manage_round13a_test.dart` (现有) | **11/11 pass** (无 regression) |
| `flutter test test/presentation/today_med_schedule_round17_test.dart` (现有) | **pass** (无 regression) |
| `dart scripts/check_all.dart` | ✅ 4 层架构纯度 + 语义一致性 全过 |
| `python scripts/check_cross_feature.py` | ✅ 59 files, 0 violations (从 55 → 59, +4 new files) |

### 10 个新 split test 覆盖 (`medications_list_split_round45d_test.dart`)

| Group | Test 数 | 覆盖目标 |
|---|---|---|
| `MedicationEmptyState` 2 种 kind | 2 | noMeds/noActive 走对 l10n + 添加按钮 |
| `MedicationRow` active/stopped | 2 | active 显示药名+剂量, stopped 显示"已停药"徽章 + enableSwipe 路径 |
| `MedicationListView` 空态 + 列表 | 2 | 无 active 走 noActive 空态, 有 active 显示用药日历入口 |
| `MedicationsListWidget` 公开 API | 2 | meds=[] 走 noMeds, meds=[1] mount OK (公开 API 签名不变) |
| `RefillDaysDialog` mount + 默认值 | 2 | 5 radio 选项显示, initial=10 回落 7 |
| **小计** | **10** | |

> emil 设计决策验证:
> - **状态归属**: 3 Set 状态在 orchestrator, 子 widget 全 Stateless 引用
> - **callback 显式化**: 4 handler 通过 named callback 传给 ListView, 不透传整包
> - **单一职责**: 5 个子 widget 各管自己 (4 presentation + 1 dialog)
> - **公开 API 兼容**: `MedicationsListWidget({required meds})` 签名不变, 调用方零改动
> - **enableSwipe 参数化**: 停药不启用 Dismissible, 1 widget 处理 2 case, 避免拆 2 widget

---

## 5. emil 设计决策 (5 条)

### 5.1 决策 1: state class 放 handler 还是放 view?

**A. handler 在 state, view 在子 widget ✅** — 跟 mood_dialog 同模式

- state class 203 行 (3 Set + 4 handler + 13 行 build + 22 行 header)
- 子 widget 各 49-219 行, presentation-only
- handler 跟 widget state 紧密耦合 (`_deleting.add(id)` + `setState`), 抽 service 反而破坏封装

### 5.2 决策 2: _MedicationRow 加 `enableSwipe` 还是拆 2 widget?

**A. 加 `enableSwipe: bool` 参数 ✅**

- 1 个 widget, 1 处维护
- stopped 药不包 Dismissible (delete 走 IconButton 已确认)
- 避免代码重复 ×2

### 5.3 决策 3: MedicationEmptyState 用 1 widget + enum 还是 2 widget?

**A. 1 widget + `MedicationEmptyKind` enum ✅**

- 调用方明确意图, 内部 switch 走 2 个 EmptyState 配置
- 避免 2 widget × 20 行过度拆分

### 5.4 决策 4: _RefillDaysDialog 移到独立文件吗?

**A. 移到独立文件 `refill_days_dialog.dart` ✅**

- dialog 状态 (selected radio) 跟 parent state 无关
- 未来 `refill_manage_page` 可复用此 dialog (v0.14 round 13A 已有, 但目前 inline)
- 独立文件方便 widget test 单独测
- emil 频度决策: dialog 触发频度 tens/day, 抽出合算

### 5.5 决策 5: l10n 调用位置?

**emil "decisions should be nameable" 原则** ✅

- 子 widget 内部直接调 `AppLocalizations.of(context).medsXxx`
- orchestrator 调 l10n 仅用于 error snackbar (`commonDelete` / `commonSetup`)
- 跟原文件 l10n 路径 1:1 保持, 0 漏改

---

## 6. 拆解前后行数对比总结

```
拆解前 (Sprint #5d 启动时):
  medications_list_widget.dart: 554 行 (1 god class, 4 handler + 3 Set + 100+ 行 build)
  ────────────────────────────────────────────────
  总: 554 行 (1 god)

拆解后 (Sprint #5d, 本次):
  medications_list_widget.dart: 203 行 (orchestrator, 4 handler + 3 Set + 13 行 build)
  + medication_list_view.dart: 155 行 (列表渲染, 4 helper build)
  + medication_row.dart: 219 行 (单行, ListTile + Dismissible + 3 IconButton)
  + medication_empty_state.dart: 49 行 (空态, 2 kind enum)
  + refill_days_dialog.dart: 81 行 (续方 dialog)
  ────────────────────────────────────────────────
  总: 707 行 (1 orchestrator + 4 子 widget)
```

| 指标 | 拆解前 | 拆解后 | Δ |
|---|---|---|---|
| orchestrator (god class) 单一职责 | ❌ 4 类混在一起 | ✅ 4 handler + delegate build | 改善 |
| 单一文件最大行数 | 554 (orchestrator) | 219 (MedicationRow) | -60% |
| 新增 doc 块 | 0 | 17.1KB 设计文档 + 10 新 test | 改善 |
| test 覆盖 | 0 split test | 10 新 test + 7 现有 test 仍 pass | 改善 |
| 4 层架构 | 0 violation | 0 violation | 持平 |
| 公开 API 兼容性 | n/a | ✅ `MedicationsListWidget({required meds})` 签名不变 | 改善 |
| 跨 feature import | 0 violation | 0 violation (4 new files 全在同 feature 内) | 持平 |

---

## 7. 剩余 P0 风险 (god class 续拆建议)

| god class | 行数 | 状态 | 后续 sprint 建议 |
|---|---|---|---|
| `mood_dialog.dart` | 199 | ✅ **已拆** (Sprint #5) | — |
| `notification_service.dart` | 415 | ✅ **已拆** (Sprint #5b) | — |
| `data_export_service.dart` | 538 | ✅ **已拆** (Sprint #5c) | — |
| `medications_list_widget.dart` | 203 | ✅ **本 sprint 拆 4 子** (Sprint #5d) | 203 行可接受, 单一职责清晰 |
| `assessment_history_page.dart` | **654** | ⚠️ 仍 god class (历史 + 趋势图 + 周期提醒 + 详情) | **v0.25 Sprint #5e** 抽 4 子 widget (1-2 天) |
| `trend_charts.dart` | **622** | ⚠️ 仍 god class (4 种图 + Stagger 公式) | v0.25 Sprint #5f 拆 (1-2 天) |
| `vent_compose_page.dart` | **566** | ⚠️ 仍 god class (录音 + 编辑 + 播放 + 提交) | v0.25 Sprint #5g 拆 3 子 widget (1-2 天) |
| `medication_calendar_page.dart` | **445** | ⚠️ 仍 god class (日历 + 当日 + 统计) | v0.25 Sprint #5h 拆 (1 天) |
| `setup_page.dart` | **444** | ⚠️ 仍 god class (4 步骤全 1 state class) | v0.25 Sprint #5i 拆 4 step widget (1 天) |

**最大风险** (按 ROI 排序):
1. **`assessment_history_page.dart` 654 行** — 历史 + 趋势图 + 周期提醒 + 详情都在, 抽 4 子 widget 改善最大 (1-2 天)
2. **`trend_charts.dart` 622 行** — 4 种图 + Stagger 公式可拆 (line / bar / heatmap / empty) (1-2 天)
3. **`vent_compose_page.dart` 566 行** — 录音 + 编辑 + 播放 + 提交 4 类决策混在一起, 跟 mood_dialog 同模式 (1-2 天)

**Sprint #5e (assessment_history) 拆解建议** (跟本次同模式):
1. `AssessmentHistoryList` (~150 行) — 历史列表 (含 empty + 加载状态)
2. `AssessmentTrendChart` (~200 行) — 趋势图 (line / bar 拆 sub-widget)
3. `AssessmentReminderSection` (~100 行) — 周期提醒 section
4. `AssessmentDetailDialog` (~150 行) — 详情弹窗
5. `assessment_history_page.dart` 缩到 ~150 行 orchestrator

**Sprint #5f (trend_charts) 拆解建议**:
1. `TrendLineChart` (~150 行) — 折线图
2. `TrendBarChart` (~100 行) — 柱状图
3. `TrendHeatmap` (~150 行) — 热力图
4. `TrendEmpty` (~50 行) — 空态
5. `trend_charts.dart` 缩到 ~150 行 orchestrator + Stagger 公式 token

---

## 8. 测试覆盖总结

| 状态 | 数量 | 备注 |
|---|---|---|
| 拆解前 baseline (round 45) | 974 | Sprint #5c 拆完后 |
| 拆解前实际 (本 sprint 启动时) | 976 | +2 来自 in-progress WIP |
| 拆解后 (本 sprint 完) | **986** | +10 (10 新 split test) |
| 7 现有 medication_calendar test | 7 | 100% 仍 pass |
| 11 现有 refill_manage test | 11 | 100% 仍 pass |
| 10 新 split test | 10 | 100% pass (4 子 widget mount + 公开 API 签名不变 + 2 dialog radio 选项) |
| 4-layer architecture | 0 violation | 0 flutter / 0 drift / 0 data / 0 presentation |
| Cross-feature import | 0 violation | 59 files 干净 (+4 new files) |

---

## 9. 工作量

| 步骤 | 实际 |
|---|---|
| Step 1: 写设计文档 (`medications_list_split_design.md`) | 🟢 30 分钟 |
| Step 2: 抽 `MedicationEmptyState` (最简单) | 🟢 15 分钟 |
| Step 3: 抽 `MedicationRow` (重命名 + 加 `enableSwipe`) | 🟡 30 分钟 |
| Step 4: 抽 `MedicationListView` (含 active/stopped 分类) | 🟡 45 分钟 |
| Step 5: 抽 `RefillDaysDialog` (移到独立文件) | 🟢 15 分钟 |
| Step 6: 重写 orchestrator (缩到 203 行) | 🟡 30 分钟 |
| Step 7: 写 split test (10 case) | 🟡 1 小时 (含 l10n string 校对 + stub 适配) |
| Step 8: 全量验证 (analyze + test + check_all + cross_feature) | 🟢 30 分钟 |
| **合计** | **🟢 4 小时** (比 spec 估算的 4-6 小时少, 主要因 stub 复用现有模式) |

---

## 10. 后续建议

- **v0.25 Sprint #5e**: assessment_history_page 654 行拆 4 子 widget (1-2 天)
- **v0.25 Sprint #5f**: trend_charts 622 行拆 4 种图 sub-widget (1-2 天)
- **v0.25 Sprint #5g**: vent_compose_page 566 行拆 3 子 (1-2 天, 跟 mood_dialog 同模式)
- **v0.25 Sprint #5h**: medication_calendar_page 445 行拆 (1 天)
- **v0.25 Sprint #5i**: setup_page 444 行拆 4 step widget (1 天)
- **v0.25 Sprint #6 中段**: 5 page god class 拆完后, 补 widget test 覆盖率 (从 ~25% 提到 50%)

---

**不要 commit** (root 决定 commit 时机)。
