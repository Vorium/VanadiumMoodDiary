# medications_list_widget god class 拆解设计

> **Sprint**: v0.24 Sprint #5d
> **基线**: v0.24 round 45 / commit `465b827` (HEAD) / 974 test cases / 0 analyze error
> **Skill 视角**: emilkowalski (设计工程师 · 状态归属 · 组件边界 · 决策命名化 · testability)
> **目标文件**: `lib/presentation/pages/medication/widgets/medications_list_widget.dart` (554 行, 1 个 state class 装 list + edit + delete + refill + swipe + dialog)
> **参考样板**: mood_dialog 738 → 199 行 (5 子 widget + 1 orchestrator)

---

## 1. 现状诊断 (emil 视角)

### 1.1 数字说话

| 指标 | 值 | emil 评估 |
|---|---|---|
| 总行数 | **554** | 超过 god class 阈值 (500+) |
| `_MedicationsListWidgetState` 字段 | **3 个 Set** (`_deleting` / `_editingRefill` / `_editing`) | 3 个状态机共享 1 state |
| 公开方法 | **4 个** (`_editMedication` / `_deleteMedication` / `_swipeDeleteMedication` / `_editRefill`) | 4 类业务流程 |
| 私有 widget | **2 个** (`_MedicationRow` 188 行 + `_RefillDaysDialog` 67 行) | 都在同一文件, 编译单元膨胀 |
| 业务职责 | **4 类**: 列表渲染 / 编辑流程 / 删除流程 (含 swipe+undo) / 续方流程 (date picker+days dialog+reschedule) | 违反 SRP |
| 内嵌 widget | `_MedicationRow` 持有 4 个 callback + 3 个 bool flag + 1 Dismissible | callback hell, 难独立测试 |

### 1.2 emil "decisions should be nameable" 检查

`medications_list_widget.dart` 当前 4 类状态**有命名但耦合**:

- `_deleting` Set<int>: 哪几行正在删除 (含 swipe 状态) — 状态名清晰
- `_editing` Set<int>: 哪几行正在 edit dialog
- `_editingRefill` Set<int>: 哪几行正在 refill dialog
- **业务逻辑全在 state class 内** — 4 个 handler 各 20-60 行, 共 150+ 行

**emil 视角**:
- 3 个 Set 命名清晰 (good)
- 4 个 handler 命名清晰 (good) 
- **但 state class 同时是 list view + dialog host + business logic executor** — 单一职责缺失
- 4 个 callback 链 (onDelete / onEdit / onEditRefill / onSwipeDelete) 通过 `_MedicationRow` 透传 — 中间层冗余

### 1.3 当前 god class 的 4 类决策混在一起

1. **列表渲染决策** (active/stopped 分类 + Dismissible + Card + ListTile) — 纯 presentation
2. **行渲染决策** (med name + 剂量 + 续方副标题 + 3 个 IconButton) — 纯 presentation
3. **业务流程决策** (4 个 handler 调 dialog / repo / notif / snackbar) — 业务编排
4. **空态决策** (2 处 EmptyState 复用) — 纯 presentation

---

## 2. 拆解方案 (emil 决策)

### 2.1 拆分原则 (5 条)

1. **3 个新子 widget + 1 orchestrator**: 跟 mood_dialog 5 子 + 1 orchestrator 同模式
2. **presentation-only 拆分**: 行/列表/空态都拆出去, state class 只保留业务流程
3. **callback 链显式化**: 子 widget 拿自己需要的 callback, 不透传整包
4. **保持公开 API 不变**: `MedicationsListWidget({required meds})` 签名不动, 现有调用方零改动
5. **保留所有 P0/P1 修复**: swipe-to-dismiss Undo (v0.21 round 23) / midnight race fix (v0.16 round 19) / notification reschedule after refresh (v0.23 P0-3 H2) / AppSnackBar 集中化 (v0.22 round 30) / Haptics.warning on swipe (v0.21 round 23)

### 2.2 目标文件树

```
lib/presentation/pages/medication/widgets/
├── medications_list_widget.dart    (~150 行 — 1 orchestrator, 仅 state + 4 handler + delegate build)
├── medication_list_view.dart       (~110 行 — 列表渲染: header card + active list + stopped list)
├── medication_row.dart             (~200 行 — 单行: ListTile + Dismissible + 3 IconButton)
├── medication_empty_state.dart     (~50 行 — 复用 2 种空态: 全空 + 无 active)
├── edit_medication_dialog.dart     (406 行 — 已有, 不动)
└── _refill_days_dialog.dart        (~70 行 — 已存在 _RefillDaysDialog, 移到独立文件)
```

**总行数** (拆解后): 150 + 110 + 200 + 50 + 70 = **580 行** (vs 原来 554, +5%)
- 行数略增来自 import 块 + 子 widget 接口注释 + doc comment
- 实际业务代码减少: 单一职责清晰, 4 个子 widget 各管自己

### 2.3 数据流 (orchestrator → 子 widget)

```
MedicationsListWidget [ConsumerStatefulWidget]      ← 公开 API 不变
  └── _MedicationsListWidgetState
        ├── state: _deleting / _editing / _editingRefill (Set<int> × 3)
        ├── handlers: _editMedication / _deleteMedication /
        │            _swipeDeleteMedication / _editRefill
        └── build:
              └── MedicationListView(
                    meds: widget.meds,
                    deleting: _deleting,
                    editing: _editing,
                    editingRefill: _editingRefill,
                    onDelete: _deleteMedication,
                    onEdit: _editMedication,
                    onEditRefill: _editRefill,
                    onSwipeDelete: _swipeDeleteMedication,
                  )
                  ↓
                  MedicationListView [StatelessWidget]
                    ├── header: 用药日历入口 Card
                    ├── empty (if activeMeds.isEmpty) → MedicationEmptyState
                    ├── active list: MedicationRow × N (Dismissible 包)
                    └── stopped list: MedicationRow × N (no Dismissible)
```

### 2.4 3 个新子 widget 接口 (emil "decisions should be nameable")

#### `MedicationListView` (~110 行)

```dart
class MedicationListView extends StatelessWidget {
  final List<MedicationEntity> meds;
  final Set<int> deleting;
  final Set<int> editing;
  final Set<int> editingRefill;
  final Future<void> Function(int id) onDelete;
  final Future<void> Function(MedicationEntity med) onEdit;
  final Future<void> Function(MedicationEntity med) onEditRefill;
  final Future<void> Function(MedicationEntity med) onSwipeDelete;

  /// 渲染: 用药日历入口卡 + active list + stopped list
  /// 全 Stateless, 状态由 parent 持有
  /// 调 onXxx 触发业务流程 (parent handler 负责 mounted check + error handling)
}
```

**责任**:
- 拆 active vs stopped meds
- 渲染用药日历入口 Card (v0.14 round 13C)
- 渲染 active list (含 Dismissible swipe) 或 active empty state
- 渲染 stopped section header + list

**频度**: tens/day (用户每天看 medication)

#### `MedicationRow` (~200 行, 现有 _MedicationRow 搬过来)

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
  final bool enableSwipe;  // stopped 药不启用

  /// 单行: ListTile + Dismissible + 3 IconButton (edit / refill / delete)
  /// 全 Stateless, parent 持状态, 回调透传
}
```

**责任**:
- 渲染 ListTile (leading icon + name + ChipBadge + dosage subtitle + refill subtitle)
- 渲染 trailing (loading spinner OR edit + refill + delete IconButton)
- Dismissible 包整个 ListTile (stopped 不包)

**保留**:
- v0.22 round 30 (emil P2-6): `fgOnError` 集中器
- v0.24 round 43 (emil P1-01 H-05): `ChipBadge` 集中器替代 inline Container
- v0.14 fix: `med.isInRefillWindow()` 跟 icon 同源

**变更**:
- 加 `enableSwipe: bool` 参数, 停药不启用 Dismissible
- 类名 `_MedicationRow` → `MedicationRow` (新文件, 可 export)

#### `MedicationEmptyState` (~50 行)

```dart
class MedicationEmptyState extends StatelessWidget {
  final VoidCallback onAddMedication;

  /// 复用 2 种空态:
  /// - meds.isEmpty: "还没有添加药物" + 添加按钮 (medsListEmpty)
  /// - activeMeds.isEmpty: "暂未在用药物" + 提示 (medsListNoActive + medsListNoActiveHint)
  /// 共用 EmptyState 集中器, 不重复 icon/title/subtitle
}
```

**责任**: 替代 2 处 inline `EmptyState(...)`, 提供 1 个统一入口

**emil 决策**:
- 不抽 2 个独立 widget (overkill), 1 个 widget + enum type 参数

#### `_RefillDaysDialog` (~70 行, 独立文件)

```dart
class RefillDaysDialog extends StatefulWidget {
  final int initial;

  /// 续方提前天数选择 dialog (v0.14 round 13A 续方管理复用)
  /// 5 个 RadioListTile 选项 [3, 5, 7, 14, 30]
  /// 选中后 Navigator.pop(context, days)
}
```

**责任**: 弹 dialog 选续方提前天数, 返回 int?

**变更**: 类名 `_RefillDaysDialog` → `RefillDaysDialog` (公开, 文件可独立 import)

### 2.5 orchestrator (`medications_list_widget.dart` ~150 行)

```dart
class MedicationsListWidget extends ConsumerStatefulWidget {
  final List<MedicationEntity> meds;
  const MedicationsListWidget({super.key, required this.meds});

  @override
  ConsumerState<MedicationsListWidget> createState() =>
      _MedicationsListWidgetState();
}

class _MedicationsListWidgetState extends ConsumerState<MedicationsListWidget> {
  // ===== 跨 widget 状态 =====
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
      return MedicationEmptyState(onAddMedication: () => context.push('/medication/new'));
    }
    return MedicationListView(
      meds: widget.meds,
      deleting: _deleting,
      editing: _editing,
      editingRefill: _editingRefill,
      onDelete: _deleteMedication,
      onEdit: _editMedication,
      onEditRefill: _editRefill,
      onSwipeDelete: _swipeDeleteMedication,
    );
  }
}
```

---

## 3. 关键设计决策 (emil 决策框架)

### 3.1 决策 1: state class 是放 handler 还是放 view?

| 候选 | 优劣 |
|---|---|
| **A. handler 在 state, view 在子 widget ✅** | state class 150 行 (4 handler + 3 Set + 10 行 build), 子 widget 各 50-200 行 |
| B. handler 全提到 controller, state 只 setState | 过度抽象, 4 个 controller 各 30-60 行, 但 widget 树穿透 3 层 |
| C. handler 全提到 service (跟 notification_service 同模式) | handler 跟 widget state 耦合 (loading Set, mounted check), 不适合抽 service |

**决策**: A。**handler 跟 widget state 紧密耦合** (`_deleting.add(id)` + `setState`), 抽 service 反而破坏封装。

### 3.2 决策 2: _MedicationRow 加 `enableSwipe` 参数还是拆 2 个 widget?

| 候选 | 优劣 |
|---|---|
| **A. 加 `enableSwipe: bool` 参数 ✅** | 1 个 widget, 1 处维护, stopped 药不包 Dismissible |
| B. 拆 `MedicationRow` (无 swipe) + `MedicationRowDismissible` (有 swipe) | 重复代码, 维护成本 ×2 |

**决策**: A。停药不需要 swipe (delete 走 IconButton 已确认), 加 bool 参数即可。

### 3.3 决策 3: MedicationEmptyState 用 1 widget + type enum 还是 2 独立 widget?

| 候选 | 优劣 |
|---|---|
| **A. 1 widget + `MedicationEmptyKind` enum ✅** | 调用方明确意图, 内部 if/switch 走 2 个 EmptyState 配置 |
| B. 2 独立 widget `MedicationsEmpty` + `NoActiveMedsEmpty` | 过度拆分, 2 widget 各 20 行 |

**决策**: A。`enum MedicationEmptyKind { noMeds, noActive }` + 1 widget。

### 3.4 决策 4: _RefillDaysDialog 移到独立文件吗?

**决策**: **移到独立文件 `refill_days_dialog.dart`**。理由:
- dialog 状态 (selected radio button) 跟 parent state 无关
- 未来 `refill_manage_page` 复用此 dialog (v0.14 round 13A 已有, 但目前是 inline)
- 独立文件方便 widget test 单独测

**emil 频度决策**: dialog 触发频度 = tens/day (per medication), 抽出合算。

### 3.5 决策 5: l10n 调用位置?

**emil "decisions should be nameable" 原则**: l10n 文本应靠近使用点。

**决策**:
- 子 widget 内部直接调 `AppLocalizations.of(context).medsXxx`
- orchestrator 调 l10n 仅用于 error snackbar (`commonDelete` / `commonSetup`)

---

## 4. 验证策略

### 4.1 静态验证

```bash
flutter analyze                              # 0 error (48 info-level 已有, 不回归)
flutter test                                 # 974 cases pass (不回归)
dart scripts/check_all.dart                  # 4 层架构 0 violation
python scripts/check_cross_feature.py        # 跨 feature 0 violation
```

### 4.2 测试覆盖

| 文件 | 行数 | 测试目标 |
|---|---|---|
| `medications_list_widget.dart` (orchestrator) | ~150 | 4 handler 行为 (mount + handler 调用) |
| `widgets/medication_list_view.dart` | ~110 | active/stopped 分类 + empty state fallback + Dismissible wiring |
| `widgets/medication_row.dart` | ~200 | ListTile 渲染 + IconButton callback + Dismissible swipe 触发 |
| `widgets/medication_empty_state.dart` | ~50 | 2 种空态走对 l10n + onAction 回调 |
| `widgets/refill_days_dialog.dart` | ~70 | 5 radio + 默认 7 + Navigator.pop |

**新 test**: `test/presentation/medications_list_split_round45d_test.dart`
- 验证 4 个新子 widget 都能 mount
- 验证 swipe-to-dismiss 触发 `_swipeDeleteMedication` 行为
- 验证 `MedicationEmptyState` 2 种 kind 走对 l10n
- 验证 `RefillDaysDialog` 5 radio 选项 + 默认 7

### 4.3 行为不变性 (P0/P1 不回归)

| P0/P1 修复 | 来源 | 保留位置 |
|---|---|---|
| swipe-to-dismiss + Undo snackbar | v0.21 round 23 P1-26 | `_MedicationRow` (renamed MedicationRow) `enableSwipe=true` + `_swipeDeleteMedication` handler |
| `DateTime.now()` 一次取 | v0.16 round 19 P0-2 | `_editRefill` handler 入口 `final now = DateTime.now()` |
| notification reschedule after refresh | v0.23 P0-3 H2 | `_editRefill` handler `await ref.refresh(medicationsProvider.future)` |
| Haptics.warning on swipe | v0.21 round 23 | `_swipeDeleteMedication` handler |
| AppSnackBar 集中化 (4 处) | v0.22 round 30 sp-zh P1-16 | 4 个 handler 全用 `AppSnackBar.xxx` |
| `fgOnError` token | v0.22 round 30 emil P2-6 | `MedicationRow` background IconButton color |
| `ChipBadge` 集中器 | v0.24 round 43 emil P1-01 H-05 | `MedicationRow` stopped 状态 |

---

## 5. 工作量估算

| 步骤 | 工作量 |
|---|---|
| Step 1: 写设计文档 (本文档) | 🟢 30 分钟 |
| Step 2: 抽 MedicationEmptyState (最简单) | 🟢 15 分钟 |
| Step 3: 抽 MedicationRow (重命名 + 加 enableSwipe) | 🟡 30 分钟 |
| Step 4: 抽 MedicationListView (含 active/stopped 分类) | 🟡 45 分钟 |
| Step 5: 抽 RefillDaysDialog (移到独立文件) | 🟢 15 分钟 |
| Step 6: 重写 orchestrator (缩到 ~150 行) | 🟡 30 分钟 |
| Step 7: 写 split test (5 个 widget mount + 行为) | 🟡 1-2 小时 |
| Step 8: 全量验证 (analyze + test + check_all + cross_feature) | 🟢 30 分钟 |
| **合计** | **🟠 4-6 小时** |

---

## 6. 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| 公开 API `MedicationsListWidget({required meds})` 被破坏 | 🟢 低 | 子 widget 内部重构, 公开签名不变 |
| 现有 974 test 失效 (medication_calendar / refill_manage / today_med_schedule) | 🟢 低 | 这 3 个 test 不直接测 `MedicationsListWidget`, 只测 RefillManagePage / MedicationCalendarPage / TodayMedSchedule |
| 状态机迁移 bug (3 Set 跨 widget 透传) | 🟡 中 | 子 widget 拿 Set 引用, 不复制, parent setState 触发 rebuild |
| swipe-to-dismiss 行为改变 | 🟡 中 | 显式加 `enableSwipe` 参数, stopped=false, active=true, 跟原来一致 |
| l10n 漏改某处 | 🟢 低 | 子 widget 内直接 `AppLocalizations.of(context).medsXxx`, 跟原文件路径一致 |

---

## 7. 不在本次 scope

- ❌ `assessment_history_page.dart` 654 行 god class 拆解
- ❌ `trend_charts.dart` 622 行 god class 拆解
- ❌ `vent_compose_page.dart` 566 行 god class 拆解
- ❌ `medication_calendar_page.dart` 445 行 god class 拆解
- ❌ `setup_page.dart` 444 行 god class 拆解
- ❌ `data_export_service.dart` 538 行 god class 拆解 (v0.25 Sprint #5c)
- ❌ 其他 emil 报告 P0-P3 修复项

**本次只动 `medications_list_widget.dart` + 新增 4 个子 widget**。

---

## 8. 参考样板: mood_dialog 拆解成功关键

| 关键 | 体现 |
|---|---|
| 1 widget = 1 orchestrator | mood_dialog 199 行, 仅 AlertDialog 容器 + 状态编排 |
| N 个子 widget 各管自己职责 | 5 个 widget (form / tags / note / recorder / actions) |
| 跨 widget 状态上抛 | 4 维度 + tag Set + controller 留 orchestrator |
| 状态机下沉 | MoodRecorder 自管 recorder + player + STT + temp file |
| 不引入新架构 | 仅用 ValueNotifier + Controller 模式 |

**medications_list 拆解关键 (跟 mood_dialog 同)**:
- 1 widget = 1 orchestrator (~150 行, 4 handler + 3 Set + 10 行 build)
- 4 个子 widget 各管自己职责 (list / row / empty / dialog)
- 跨 widget 状态 (3 Set + 4 handler) 留 orchestrator
- 子 widget 全 Stateless, callback 透传
- 不引入 Riverpod (list 业务简单, ValueNotifier 也不需要)
