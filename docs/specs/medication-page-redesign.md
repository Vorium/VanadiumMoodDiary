# 用药页面重构设计方案 — 参照 Apple Health Medications

**创建时间**: 2026-08-07
**状态**: 设计方案（待确认后实施）
**参照**: Apple Health Medications (iOS 16+)

---

## 一、Apple Health 用药界面核心设计

### 1.1 核心页面

| 页面 | 功能 | 关键设计 |
|------|------|----------|
| **Medications List** | 药物列表 + 今日状态 | 卡片式药物展示，每药有颜色药丸图标 + 剂量 + 时间 |
| **Add Medication** | 添加药物向导 | 3-7 步 wizard: 药名 → 剂型 → 剂量 → 频率 → 时间 → 颜色 → 确认 |
| **Daily Schedule** | 今日服药计划 | 按时间段分组（早/午/晚/睡前），一键打卡 |
| **Medication Detail** | 药物详情 + 依从性 | 药物信息 + 30 天日历热力图 + 趋势 |
| **Log History** | 服药历史 | 按日期分组的打卡记录 |

### 1.2 关键交互模式

- **时间段分组**: Morning / Afternoon / Evening / Bedtime（不是按药物分组）
- **一键打卡**: 每个时间段内的药物可单独或批量打卡
- **颜色药丸**: 每种药物有自定义颜色 + 形状图标，视觉识别
- **依从性日历**: 每日一个 cell，颜色编码（全服/部分/漏服）
- **通知提醒**: 每个时间段一条通知，点击直达打卡

---

## 二、当前项目现状分析

### 2.1 当前页面结构

```
lib/presentation/pages/medication/
├── medication_calendar_page.dart    ← 依从性热力图（N药×N天）
├── refill_manage_page.dart          ← 续方管理
├── temp_medication_dialog.dart      ← 临时吃药弹窗
├── today_med_schedule.dart          ← 主页小卡（今日服药进度）
└── widgets/
    ├── medications_list_widget.dart  ← 常吃药列表（嵌入设置页）
    ├── medication_list_view.dart     ← 列表渲染
    ├── medication_row.dart           ← 单行（Dismissible + 3 IconButton）
    ├── medication_empty_state.dart   ← 空态
    ├── edit_medication_dialog.dart   ← 编辑弹窗（413行）
    ├── refill_days_dialog.dart       ← 续方天数选择
    ├── choose_window_dialog.dart     ← 报告窗口选择
    ├── medication_calendar_grid.dart ← 热力图网格
    ├── medication_calendar_day_detail.dart ← 单日详情
    └── medication_calendar_legend.dart     ← 颜色图例
```

### 2.2 当前数据模型

```dart
// Drift 表
Medications {
  id, name, dosage, dosageUnit(mg/tablet),
  timesJson([{"h":8,"m":0},{"h":20,"m":0}]),
  startDate, endDate, isActive,
  refillAt, refillReminderDays
}

// 打卡记录
CheckIns {
  id, medicationId, type(normal/temp), timestamp
}
```

### 2.3 当前问题

| 问题 | 详情 |
|------|------|
| **入口分散** | 药物列表在设置页，日历在独立页面，临时吃药在弹窗 |
| **无时间段视图** | 今日计划只是 Wrap 芯片，没有 Apple Health 那样的时间段分组 |
| **编辑体验差** | 413 行弹窗，字段堆叠，无向导式流程 |
| **无药物颜色/形状** | 没有视觉识别系统 |
| **打卡粒度粗** | 只记录"今天吃了这药"，不记录"哪个时间点吃的" |
| **主页小卡信息少** | TodayMedSchedule 只显示时间芯片，无依从性进度 |

---

## 三、重构设计方案

### 3.1 新页面结构

```
lib/presentation/pages/medication/
├── medication_page.dart              ← 【新建】用药主页（独立路由）
│   ├── MedicationPageHeader          ← 顶部：标题 + 添加按钮
│   ├── TodayScheduleSection          ← 今日服药计划（时间段分组）
│   ├── MedicationListSection         ← 我的药物列表（卡片式）
│   └── QuickActionsSection           ← 快捷操作（日历/续方/报告）
│
├── add_medication_page.dart          ← 【新建】添加药物向导（3步）
│   ├── Step1_NameForm                ← 药名 + 剂型
│   ├── Step2_DosageSchedule          ← 剂量 + 频率 + 时间
│   └── Step3_Confirm                 ← 确认 + 颜色选择
│
├── medication_detail_page.dart       ← 【新建】药物详情页
│   ├── MedicationInfoCard            ← 药物信息卡
│   ├── AdherenceCalendar             ← 30天依从性日历
│   ├── RecentHistory                 ← 最近服药记录
│   └── ActionsSection                ← 编辑/续方/停药
│
├── medication_calendar_page.dart     ← 【保留】依从性热力图
├── refill_manage_page.dart           ← 【保留】续方管理
├── temp_medication_dialog.dart       ← 【保留】临时吃药
├── today_med_schedule.dart           ← 【重构】改为时间段分组
└── widgets/
    ├── medication_time_slot_card.dart ← 【新建】时间段卡片（早/午/晚/睡前）
    ├── medication_pill_icon.dart      ← 【新建】药丸颜色形状图标
    ├── medication_card.dart           ← 【新建】药物卡片（替代 medication_row）
    ├── adherence_calendar_cell.dart   ← 【新建】依从性日历 cell
    ├── add_med_step_name.dart         ← 【新建】添加步骤1
    ├── add_med_step_dosage.dart       ← 【新建】添加步骤2
    ├── add_med_step_confirm.dart      ← 【新建】添加步骤3
    ├── medications_list_widget.dart   ← 【保留】
    ├── medication_empty_state.dart    ← 【保留】
    ├── edit_medication_dialog.dart    ← 【保留】兼容旧流程
    ├── refill_days_dialog.dart        ← 【保留】
    ├── choose_window_dialog.dart      ← 【保留】
    ├── medication_calendar_grid.dart  ← 【保留】
    ├── medication_calendar_day_detail.dart ← 【保留】
    └── medication_calendar_legend.dart    ← 【保留】
```

### 3.2 新增路由

```dart
// 路由配置
GoRoute(
  path: '/medication',
  pageBuilder: (context, state) => const CustomTransitionPage(
    child: MedicationPage(),
    transitionsBuilder: fadeTransition,
  ),
),
GoRoute(
  path: '/medication/add',
  pageBuilder: (context, state) => const CustomTransitionPage(
    child: AddMedicationPage(),
    transitionsBuilder: slideUpTransition,
  ),
),
GoRoute(
  path: '/medication/detail/:id',
  pageBuilder: (context, state) => CustomTransitionPage(
    child: MedicationDetailPage(
      medicationId: int.parse(state.pathParameters['id']!),
    ),
    transitionsBuilder: slideRightTransition,
  ),
),
```

### 3.3 入口变更

| 原入口 | 新入口 | 说明 |
|--------|--------|------|
| 设置页 → MedicationsListWidget | **主页 FAB → /medication** | 用药成为一级入口 |
| 主页 TodayMedSchedule 小卡 | **主页 TodayMedSchedule → /medication** | 点击进入用药主页 |
| 设置页 → /medication/calendar | **用药主页 → /medication/calendar** | 日历从用药主页进 |

---

## 四、核心页面设计

### 4.1 用药主页 (`MedicationPage`)

```
┌─────────────────────────────────────┐
│  用药                    [+] 添加    │  ← AppBar
├─────────────────────────────────────┤
│  ┌─ 今日服药 ─────────────────────┐ │
│  │ ☀️ 早上 (8:00)                 │ │
│  │ ┌──────────┐ ┌──────────┐     │ │
│  │ │ 🟢 舍曲林  │ │ 🟢 阿立哌唑│     │ │
│  │ │ 50mg ×1  │ │ 10mg ×1  │     │ │
│  │ │ ✅ 已服   │ │ ⏰ 待服   │     │ │
│  │ └──────────┘ └──────────┘     │ │
│  │                                │ │
│  │ 🌙 晚上 (20:00)                │ │
│  │ ┌──────────┐ ┌──────────┐     │ │
│  │ │ 🟡 碳酸锂  │ │ 🟡 劳拉西泮│     │ │
│  │ │ 300mg ×2 │ │ 0.5mg ×1 │     │ │
│  │ │ ⏰ 待服   │ │ ⏰ 待服   │     │ │
│  │ └──────────┘ └──────────┘     │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ 我的药物 ─────────────────────┐ │
│  │ 🟢 舍曲林 50mg  早晚各1  在用   │ │
│  │ 🟡 碳酸锂 300mg 晚上1次  在用   │ │
│  │ 🔴 文拉法辛 75mg 已停药         │ │
│  └────────────────────────────────┘ │
│                                     │
│  [📅 用药日历]  [💊 续方管理]  [📊 报告] │
└─────────────────────────────────────┘
```

### 4.2 添加药物向导 (`AddMedicationPage`)

**Step 1: 药名 + 剂型**
```
┌─────────────────────────────────────┐
│  ← 添加药物              Step 1/3   │
├─────────────────────────────────────┤
│                                     │
│  药物名称                            │
│  ┌─────────────────────────────┐    │
│  │ 舍曲林                       │    │
│  └─────────────────────────────┘    │
│                                     │
│  剂型                               │
│  [💊 片剂] [💉 胶囊] [🧪 口服液]    │
│  [🩹 贴剂] [💉 注射] [💊 其他]      │
│                                     │
│              [下一步 →]              │
└─────────────────────────────────────┘
```

**Step 2: 剂量 + 频率 + 时间**
```
┌─────────────────────────────────────┐
│  ← 添加药物              Step 2/3   │
├─────────────────────────────────────┤
│                                     │
│  每次剂量                            │
│  ┌──────┐ [mg ▼]  × [1]           │
│  │  50  │                          │
│  └──────┘                          │
│                                     │
│  服药频率                            │
│  [每天] [指定日期] [按需]            │
│                                     │
│  服药时间                            │
│  [☀️ 早上 8:00] [🌙 晚上 20:00]    │
│              [+ 添加时间]            │
│                                     │
│           [← 上一步] [下一步 →]      │
└─────────────────────────────────────┘
```

**Step 3: 确认 + 颜色**
```
┌─────────────────────────────────────┐
│  ← 添加药物              Step 3/3   │
├─────────────────────────────────────┤
│                                     │
│  药物颜色（可选，帮助视觉识别）       │
│  [🟢] [🟡] [🔴] [🔵] [🟣] [⚪]    │
│                                     │
│  ┌─ 确认信息 ─────────────────────┐ │
│  │ 药名: 舍曲林                    │ │
│  │ 剂型: 片剂                      │ │
│  │ 剂量: 50mg × 1                  │ │
│  │ 频率: 每天                      │ │
│  │ 时间: 早上 8:00, 晚上 20:00    │ │
│  └────────────────────────────────┘ │
│                                     │
│  [⏰ 设置提醒通知]                   │
│                                     │
│           [← 上一步] [✓ 保存]       │
└─────────────────────────────────────┘
```

### 4.3 药物详情页 (`MedicationDetailPage`)

```
┌─────────────────────────────────────┐
│  ← 舍曲林                           │
├─────────────────────────────────────┤
│  ┌────────────────────────────────┐ │
│  │ 🟢 舍曲林                      │ │
│  │ 50mg × 1  片剂                 │ │
│  │ 早上 8:00, 晚上 20:00          │ │
│  │ 起始日期: 2026-06-15           │ │
│  │ 状态: 在用                     │ │
│  └────────────────────────────────┘ │
│                                     │
│  ┌─ 依从性 ───────────────────────┐ │
│  │ 本月依从率: 92% (23/25天)      │ │
│  │                                │ │
│  │ 日 一 二 三 四 五 六           │ │
│  │  ✅ ✅ ✅ ✅ ✅                │ │
│  │  ✅ ✅ ❌ ✅ ✅ ✅ ✅           │ │
│  │  ✅ ✅ ✅ ✅ ✅ ⏳              │ │
│  └────────────────────────────────┘ │
│                                     │
│  [✏️ 编辑]  [📦 续方]  [⏸️ 停药]   │
│                                     │
│  [📅 用药日历]  [📊 用药报告]       │
└─────────────────────────────────────┘
```

---

## 五、数据模型变更

### 5.1 MedicationEntity 扩展

```dart
// 新增字段
enum MedicationForm { tablet, capsule, liquid, patch, injection, other }

class MedicationEntity {
  // ... 现有字段 ...
  final MedicationForm form;       // 新增: 剂型
  final int colorIndex;            // 新增: 颜色索引 (0-5, 对应绿/黄/红/蓝/紫/白)
  final String? notes;             // 新增: 备注
}
```

### 5.2 Drift 表迁移 (schemaVersion 20)

```dart
// 新增列
@DataClassName('Medication')
class Medications extends Table {
  // ... 现有列 ...
  TextColumn get form => text().withDefault(const Constant('tablet'))();  // 新增
  IntColumn get colorIndex => integer().withDefault(const Constant(0))(); // 新增
  TextColumn get notes => text().nullable()();                            // 新增
}
```

### 5.3 CheckIn 扩展（可选 — 打卡粒度细化）

```dart
// 方案 A: 在 CheckIn 表新增 timeSlotIndex 列
// 优点: 精确到哪个时间点打卡
// 缺点: 需要改表结构 + 迁移

// 方案 B: 保持现状（只记录当天是否打卡）
// 优点: 不改表结构，兼容现有逻辑
// 缺点: 无法区分"早上吃了但晚上没吃"

// 推荐: 方案 B（先保持现状，v1.0 后考虑方案 A）
// 理由: 精神心理患者的核心需求是"今天有没有吃药"，而非"哪个时间点吃的"
// Apple Health 做时间点打卡是因为它有药房数据库，我们没有
```

---

## 六、实现计划

### Phase 1: 路由 + 页面骨架 (1-2天)

| 任务 | 文件 | 说明 |
|------|------|------|
| 新建 `MedicationPage` | `medication_page.dart` | 用药主页骨架 |
| 新建 `AddMedicationPage` | `add_medication_page.dart` | 添加药物向导骨架 |
| 新建 `MedicationDetailPage` | `medication_detail_page.dart` | 药物详情骨架 |
| 加路由 | `app_route_medication.dart` | 3 条新路由 |
| 加入口 | `home_page_state.dart` | 主页 → 用药主页 |

### Phase 2: 核心 Widget (2-3天)

| 任务 | 文件 | 说明 |
|------|------|------|
| `MedicationPillIcon` | `medication_pill_icon.dart` | 颜色药丸图标 |
| `MedicationTimeSlotCard` | `medication_time_slot_card.dart` | 时间段卡片 |
| `MedicationCard` | `medication_card.dart` | 药物卡片（替代 MedicationRow） |
| `AdherenceCalendarCell` | `adherence_calendar_cell.dart` | 依从性日历 cell |
| `TodayScheduleSection` | 在 `medication_page.dart` 内 | 今日服药时间段分组 |

### Phase 3: 添加药物向导 (1-2天)

| 任务 | 文件 | 说明 |
|------|------|------|
| Step 1 | `add_med_step_name.dart` | 药名 + 剂型 |
| Step 2 | `add_med_step_dosage.dart` | 剂量 + 频率 + 时间 |
| Step 3 | `add_med_step_confirm.dart` | 确认 + 颜色 |
| 保存逻辑 | 复用 `medicationRepositoryProvider.add()` | + form/colorIndex |

### Phase 4: 数据层扩展 (1天)

| 任务 | 文件 | 说明 |
|------|------|------|
| Entity 扩展 | `medication_entity.dart` | +form/colorIndex/notes |
| Drift 表扩展 | `medications.dart` | +form/colorIndex/notes |
| Mapper 更新 | `medication_mapper.dart` | 新字段映射 |
| schemaVersion 20 | `app_database.dart` | 迁移脚本 |
| ARB key | `app_zh/en/zh_Hant.arb` | 新文案 |

### Phase 5: 集成 + 测试 (1-2天)

| 任务 | 说明 |
|------|------|
| 主页入口 | TodayMedSchedule → /medication |
| 设置页入口 | MedicationsListWidget 保留，加"进入用药主页" |
| Widget 测试 | 新 widget 3-5 个测试 |
| 集成测试 | 添加药物 → 打卡 → 查看详情 流程 |

---

## 七、影响分析

### 7.1 需要修改的现有文件

| 文件 | 改动 | 风险 |
|------|------|------|
| `app_route_medication.dart` | 加 3 条路由 | 低 |
| `home_page_state.dart` | TodayMedSchedule 点击跳转 | 低 |
| `medication_entity.dart` | 加 3 个字段 | 中 |
| `medications.dart` (drift) | 加 3 列 + 迁移 | 中 |
| `medication_mapper.dart` | 新字段映射 | 低 |
| `app_database.dart` | schemaVersion 20 | 中 |
| `core_providers.dart` | 无变化 | — |
| `shared_providers.dart` | 可能加 provider | 低 |

### 7.2 不需要修改的

| 模块 | 原因 |
|------|------|
| 打卡系统 (CheckIn) | 保持现状，方案 B |
| 通知系统 (MedicationNotifier) | 时间段通知可后续加 |
| 续方系统 (RefillNotifier) | 不变 |
| 用药报告 (MedicationReport) | 不变 |
| PDF 导出 | 不变 |

### 7.3 新增 ARB key 估算

| 类别 | key 数 | 说明 |
|------|--------|------|
| 用药主页 | ~15 | 标题/时间段标签/空态/快捷操作 |
| 添加向导 | ~20 | 步骤标题/字段标签/按钮/验证消息 |
| 药物详情 | ~10 | 信息标签/操作按钮/依从性 |
| 通用 | ~5 | 剂型/颜色/频率 |
| **合计** | **~50** | × 3 语 = 150 条 ARB |

---

## 八、与现有功能的兼容性

| 现有功能 | 兼容方案 |
|----------|----------|
| MedicationsListWidget (设置页) | 保留，加"进入用药主页"按钮 |
| EditMedicationDialog | 保留，新旧流程并存 |
| MedicationCalendarPage | 保留，从用药主页进入 |
| RefillManagePage | 保留，从用药主页进入 |
| TempMedicationDialog | 保留 |
| TodayMedSchedule (主页小卡) | 重构为时间段分组，点击进用药主页 |
| MedicationReport | 不变 |
| MedicationReportPdf | 不变 |

---

## 九、决策点

| # | 问题 | 选项 | 推荐 |
|---|------|------|------|
| 1 | 打卡粒度 | A: 时间点打卡 / B: 保持日打卡 | **B** (先保持，v1.0后考虑A) |
| 2 | 入口位置 | A: 主页FAB / B: 设置页 / C: NavigationRail | **C** (加"用药"到 NavigationRail) |
| 3 | 添加向导步数 | A: 3步 / B: 5步(仿Apple) / C: 1页表单 | **A** (3步简洁，精神患者不耐长流程) |
| 4 | 药丸颜色 | A: 固定6色 / B: 自定义色盘 / C: 无 | **A** (6色足够，减少选择负担) |
| 5 | 剂型选择 | A: 6种预设 / B: 自由输入 / C: 无 | **A** (跟Apple一致) |

---

## 十、参考截图描述 (Apple Health)

### Apple Health Medications 主页面
- 顶部: "Your Medications" 标题 + "Add Medication" 按钮
- 中部: 药物卡片列表，每卡有：
  - 左侧: 彩色药丸图标（圆角矩形，颜色自定义）
  - 中间: 药名（粗体）+ 剂量 + 频率
  - 右侧: ">" 箭头
- 底部: "Log All" 按钮（批量打卡）

### Apple Health Daily Schedule
- 按时间段分组: Morning / Afternoon / Evening / Bedtime
- 每个时间段下:
  - 药物列表（药丸图标 + 药名 + 剂量）
  - 每药右侧: "Log" 按钮（点击变 ✓）
- 顶部: 今日日期 + 总进度

### Apple Health Medication Detail
- 顶部: 药物信息卡（名称/剂量/频率/起始日期）
- 中部: "Did you take...?" 快速打卡
- 下部: 30天日历视图（每天一个cell，颜色编码）
- 底部: 编辑/停药/删除操作
