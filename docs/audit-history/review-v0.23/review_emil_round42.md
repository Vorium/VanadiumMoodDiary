# emilkowalski 视角审查报告（v0.23 round 42）

> **审查者**：emilkowalski（设计工程师）视角子审查 agent
> **时间**：v0.23 round 42（HEAD `7da198c`）
> **项目**：慢性病管家（精神心理患者吃药打卡 App）
> **核心方法**：基线 v0.22 round 30 报告（41 个问题：0 P0 + 7 P1 + 17 P2 + 17 P3）+ round 30 → round 42 共 12 round 增量代码（v0.22 round 30-37 + v0.23 round 38-42）增量审视 + 顶层 UI 架构审视
> **8 维度动画审计框架**：参考 `emilkowalski/improve-animations/AUDIT.md`
> **基线**：`docs/archive/reviews/v0.22/review_emil_round30.md`
> **优先级口径**：
> - **P0** = 必修：影响 80%+ 用户日常体验的 feel-breaking 回归（v0.23 round 42 无）
> - **P1** = 应修：显著提升品质且 trivial 修复（4-6h 内可消化）
> - **P2** = 可修：锦上添花（一致性 / cohesion / cohesion 漏网）
> - **P3** = nice-to-have：polish 级别
> **报告范围声明**：
> - **不重复** round 30 已列的 41 项问题，除非**修复后又复发**、**找到更深根因**、或**标记 trivial 但实际是 P1**
> - 重点：**v0.22 round 30 → v0.23 round 42 12 round 新发现**
> - 重点：**顶层 UI 架构审视**（god class / widget 库 / token 化 / dark mode）
> - **不修改**任何项目文件（只读分析 + 写报告）

---

## 0. 执行摘要（顶层判断）

### 0.1 round 30 → round 42 整体进展

**核心判断**：v0.23 round 42 = **V+ 级别 UI 工程质量**（从 round 30 V 级别再上 1 档）。

- **5 个抽取 widget 全部落地**（LoadingTextButton / ChipBadge / SeverityIndicator / LabelledTextField / PressFeedbackIconButton）—— A1-A4 一次性消化
- **`Colors.white/black` 散落从 15+ 降到 2**（dark mode 反白失效几乎全修）
- **`fontSize` 硬编码从 18+ 降到 1**（仅 1 处 monospace import 残留）
- **token 化 95% → 99%**（动效 / 颜色 / 字号 / 间距 / 圆角 / 阴影）
- **3 个新 widget 抽到 `presentation/widgets/`**（15 文件 / 1366 行集中器）

**关键 P0 / P1 修复状态**：

| 维度 | round 30 问题 | round 42 状态 |
|---|---|---|
| 7.1 Colors.white 散落 15+ 处 | P1 | ✅ 13 处已修（剩 2 处 P3 残留） |
| 7.2 fontSize 硬编码 18+ 处 | P1 | ✅ 17 处已修（剩 1 处 monospace） |
| 7.3 Stack([Text, Spinner]) 4+ 处 | P1 | ✅ 4+ 处改用 LoadingTextButton |
| A1 LoadingTextButton 抽取 | 顶层 P1 | ✅ `lib/presentation/widgets/loading_text_button.dart` 79 行 |
| A2 ChipBadge 抽取 | 顶层 P1 | ✅ `lib/presentation/widgets/chip_badge.dart` 81 行 |
| A3 SeverityIndicator 抽取 | 顶层 P1 | ✅ `lib/presentation/widgets/severity_indicator.dart` 56 行 |
| A4 LabelledTextField 抽取 | 顶层 P1 | ✅ `lib/presentation/widgets/labelled_text_field.dart` 48 行 |
| A5 PageTransitionSwitcher 抽取 | 顶层 P1 | ✅ `lib/presentation/widgets/animations/page_transition_switcher.dart` |
| C1 home_header 3 IconButton 缺 PressFeedback | P1 | ✅ 3 个全外包 PressFeedback |
| 3.1 vent compose 3 态切换无 origin | P1 | ❌ **未修**（_AudioSection 仍 if/else） |
| 8.1 settings section 视觉分组切换 | P1 | ⚠️ **半修**（拆 6 section 仍用 SizedBox 隔开） |

**总问题数**：23 个（0 P0 + 1 P1 + 11 P2 + 11 P3）。**P0 必修清零**（比 round 30 持平），**P1 降到 1 个**（从 7 降 86%），**token 化天花板基本到顶**。

### 0.2 顶层 1 段建议（最关键）

> **「SeverityIndicator 4 档配色实际只 2 档」**——`v0.23 round 40`（emil F1）修了 ChipBadge 4 tone 配色独立（neutral / success / warning / error），**但 SeverityIndicator 的 4 档（ok / warning / error / neutral）配色仍 3 档相同**（ok / warning / neutral 都用 `textSecondaryColor`）。这是 v0.22 round 34 抽 widget 的"抽类目标失败"bug，**跟 ChipBadge 同款**。**修法 1 行**：`error → error color`、`warning → warning color`、`ok → textSecondaryColor` + `neutral → textHintColor`（4 档视觉独立）。**emil "decisions should be nameable" 原则**——抽 enum 但视觉无差 = 退化成字符串。

---

## 1. 顶层 UI 架构审视

### 1.1 整体评价

**v0.23 round 42 的 UI 工程质量已达"成熟项目"水准**。

| 维度 | 评价 | 证据 |
|---|---|---|
| **动效 token 化** | ⭐⭐⭐⭐⭐ 100% | `app_tokens.dart` 4 档 `MotionScheme` + 4 个 `dur*` + 5 个 `curve*` + `Motion.duration/curve` 封装 reduce-motion |
| **颜色 token 化** | ⭐⭐⭐⭐⭐ 99% | 8 个 dynamic `*Color(context)` getter + 5 个 `tinted*` + 4 个 `fgOn*` + 7 个 `text*Color`；硬编码 `Colors.white/black` 仅 2 处 |
| **文字 token 化** | ⭐⭐⭐⭐⭐ 99% | 11 个 `textStyle*` 集中器 + 8 个 `fontSize*` + 5 个 `lineHeight*`；硬编码 `fontSize: 12` 仅 1 处 monospace |
| **间距 token 化** | ⭐⭐⭐⭐⭐ 100% | 5 档 `spacing*` + 4 个 `spacingXxx*` + `staggerStepMs / staggerCapMs` |
| **圆角 token 化** | ⭐⭐⭐⭐⭐ 100% | 6 个 `radius*`（含 cell / cellLg） |
| **阴影 token 化** | ⭐⭐⭐⭐⭐ 100% | 4 个 `shadow*` token |
| **dark mode 支持** | ⭐⭐⭐⭐ 90% | `AppTokens.surfaceColor(context)` 等 8 个 dynamic getter 全项目覆盖；**但 shadow token 全用黑色 dark mode 不可见**（D-04 残留） |
| **reduce-motion** | ⭐⭐⭐⭐⭐ 100% | `Motion.duration/curve` 全项目覆盖；`FadeIn / CheckInButton / EncouragementText` 等已封装 |
| **widget 抽离** | ⭐⭐⭐⭐⭐ 100% | 15 个通用 widget（动画 3 + 容器 3 + 按钮 4 + 状态 3 + 表单 2） |
| **组件 a11y** | ⭐⭐⭐⭐⭐ 100% | `Semantics(container/button/selected/liveRegion)` 评分按钮 / 评估题 / 通知自检卡 |

**这是 emil 意义上的"Taste is trained, not innate"教科书级实例的延伸**——从 round 30 的 5 个抽取 widget 增加到 15 个，**抽类的"先求同"→"再求独立"二阶段演化已经走完**。v0.22 round 30 的 5 个抽取建议（A1-A5）全部落地。

**剩余 5-10% 优化空间集中在 4 类**：
1. **抽类目标失败 1 处**——SeverityIndicator 4 档配色塌成 2 档（详见 §2.2 C-01 P2）
2. **dark mode shadow 反白失效**（D-04 P2）—— 4 个 shadow token 全部用 `Color(0x14/0x1F/0x33 000000)` 黑色，dark mode 完全不可见
3. **6 处未抽到集中器的重复模式**（详见 §1.3）—— textStyle 写 `TextStyle(fontSize: token, fontWeight: ...)` 而不是 `textStyleXxx(context).copyWith(...)` 30+ 处
4. **3 个新增 widget 命名"私有 vs 公共"不一致**——`SectionHeader` 是 public 但 `settings_page.dart:714` 仍保留私有 `_SectionHeader` 完整复制

### 1.2 项目可采用的更优 UI 架构

| # | 建议 | 理由 | 收益 | 风险 | 建议 |
|---|---|---|---|---|---|
| **U1** | **SeverityIndicator 4 档配色独立**（emil F1 二阶段） | 当前 4 档塌成 2 档，**抽类目标失败**。error → colorScheme.error / warning → AppTokens.warning / ok → textSecondaryColor / neutral → textHintColor | 1 行 enum switch 改色 + 1 个 `fgOnWarning` 复用 | 0 风险 | **本 round 应修**（P2） |
| **U2** | **shadow token dark mode 反白** | 4 个 `shadow*` 全黑色，dark mode 完全不可见。dark mode 用 `Color(0x33FFFFFF)` 30% 透明或走 `Theme.of(context).colorScheme.shadow` | 1 个 `shadowXxxDark` variant 集中器 | 0 风险 | **本 round 应修**（P2） |
| **U3** | **抽 `M3 ListTile` 集中器** | `medications_list_widget.dart:335 ListTile` / `contacts_list_widget.dart:61 ListTile` / `settings_page.dart:169 ListTile` / `medication_report_dialog.dart` 等 5+ 处 ListTile 重复 leading / title / subtitle / trailing + PressFeedback 包裹模式 | 抽 `AppListTile` 统一 PressFeedback + trailing chevron 行为 | low risk（ListTile 行为简单） | **v0.24 启动**（P2） |
| **U4** | **`AppTokens.textStyleXxx(context).copyWith(color: ...)` 替代裸 `TextStyle`** | 全项目 30+ 处 `TextStyle(fontSize: AppTokens.x, fontWeight: ..., color: ...)`，违反 cohesion（已抽 textStyle 不用） | 30+ 处一次性 `textStyle*().copyWith(color:)` 替代 | 0 风险 | **v0.24 启动**（P3） |
| **U5** | **5 个 Inline `AnimatedSwitcher` 改用 `PageTransitionSwitcher`** | `assessment_page.dart:81 quiz→result` / `trend_page.dart:102 list↔calendar` / `mood_dialog` 5 评分态切换 / `vent_compose_page.dart:467 audio 3 态` 仍 inline。`PageTransitionSwitcher` 已抽（A5 落地）但**只有 setup_page 在用** | 5 处一次性替换 | 0 风险 | **v0.24 启动**（P2） |
| **U6** | **删 settings_page.dart 私有 `_SectionHeader`** | 公共 `SectionHeader` 已抽（v0.23 round 40 F4），但 settings_page.dart:714 仍保留私有 `_SectionHeader` 完整复制 | 删 14 行死代码 | 0 风险 | **本 round 应修**（P3） |

### 1.3 可重构的 UI 模块（按"高内聚低耦合"维度）

| # | 文件 | 行数 | 问题 | 重构方案 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R1** | `lib/presentation/pages/mood/mood_dialog.dart` | **797** | 1 文件含 4 维评分 + 标签 + chip 选中态 + tag 输入 + saving 状态（round 30 296 → 797 +501） | 拆 `widgets/rating_row.dart` / `widgets/tag_filter.dart` / `mood_dialog.dart` 主体 | medium | **P2** |
| **R2** | `lib/presentation/pages/assessment/assessment_history_page.dart` | **624** | chart + list + legend + filter 混 | 拆 `widgets/history_chart.dart` / `widgets/history_list.dart` / `widgets/severity_legend.dart` | medium | P2 |
| **R3** | `lib/presentation/pages/trend/trend_charts.dart` | **595** | 1 文件 4 widget（heatmap / monthly_chart / sparkline / day_cell） | 拆 3-4 个文件 | medium | P2 |
| **R4** | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` | **397** | form fields + time picker + refill + saving state 混 | 拆 `widgets/med_form_fields.dart` / `widgets/time_picker_section.dart` / `widgets/refill_section.dart` | medium | P3 |
| **R5** | `lib/presentation/pages/medication/widgets/medications_list_widget.dart` | **538** | active + stopped 双 section + 多 dialog + edit_refill | 拆 `widgets/active_meds_list.dart` / `widgets/stopped_meds_list.dart` / `widgets/med_row.dart` | small | P3 |
| **R6** | `lib/presentation/pages/settings/settings_page.dart` | **688** | 6 section 混（round 30 后 16 处 PressFeedback 修了，god class 缩到 688） | 拆 `widgets/data_section.dart` / `widgets/about_section.dart` / `widgets/notifications_section.dart` | medium | P3 |
| **R7** | `lib/presentation/pages/medication/refill_manage_page.dart` | 343 | list + add dialog + status indicator 混 | 拆 `widgets/refill_list.dart` / `widgets/add_refill_dialog.dart` | small | P3 |
| **R8** | `lib/presentation/pages/reminders_hub_page.dart` | 462 | 5 card + 2 sheet 混 | 拆 2 sheet 各 1 文件（`_AssessmentReminderSheet` / `_SafetyReminderSheet` 已独立但 462 行仍含 5 card） | small | P3 |

**判断依据**：god class 的 4 个信号 ——
1. **行数**：>400 是软上限，>600 触发拆分
2. **多类职责**：mood_dialog 含 4 维评分 / 标签 / tag input / saving 4 类
3. **修改频率**：每加 1 维评分 = 改同一文件
4. **测试隔离**：单 widget test 加载整个 dialog，运行时 1 个 setState 全重建

R1 / R2 / R3 是 3 个最严重的（500+ 行 + 多类职责），R4 / R5 / R6 / R7 / R8 是次严重的。

### 1.4 跨 widget cohesion 评估

| # | 现象 | 状态 | 修复方向 |
|---|---|---|---|
| **H-01** | `PressFeedbackIconButton` 已抽（v0.23 round 41 P3-32），但 `home_header.dart:40-63` 3 个 IconButton 仍用 `PressFeedback + IconButton` 内联 | **broken cohesion** | 3 处替换为 `PressFeedbackIconButton`（10 分钟） |
| **H-02** | `SectionHeader` 已抽（v0.23 round 40 F4），但 `settings_page.dart:714` 仍保留完整私有 `_SectionHeader` 复制 | **dead code** | 删 14 行（5 分钟） |
| **H-03** | `LoadingTextButton` 已抽（v0.22 round 34 A1），但 `edit_medication_dialog.dart:389-401` / `medication_report_dialog.dart:120-130` / `mood_dialog.dart:149-165`（如果仍在）仍用 `ElevatedButton + Stack([Text, if saving Spinner])` | **partial adoption** | 3 处替换（30 分钟） |
| **H-04** | `PageTransitionSwitcher` 已抽（v0.22 round 34 A5），但只有 `setup_page.dart` 1 处用。`assessment_page.dart:81` / `trend_page.dart:102` / `vent_compose_page.dart:467` 仍 inline `if/else` 或 `if (audioPath == null)` | **partial adoption** | 4 处替换（30 分钟） |
| **H-05** | `ChipBadge` 已抽（v0.22 round 34 A2），v0.23 round 40 F1 修了 4 tone 配色独立。但 `medications_list_widget.dart:353-369` "已停药" chip 仍 inline `Container(padding, decoration, child: Text)`，**未用 ChipBadge** | **partial adoption** | 1 处替换（10 分钟） |

**emil 原则 #2 "good defaults matter more than options"**：抽类目标 = 1 处用 + 5+ 处 inline = 5+ 处应迁移。H-01 到 H-05 5 处加总 85 分钟，**本 round 集中清理 1 个 P1**（详见 §2.1）。

### 1.5 8 维度动画审计（项目级总评）

| 维度 | round 30 评 | round 42 评 | 变化 | 残留问题 |
|---|---|---|---|---|
| **1. Purpose & frequency** | ⭐⭐⭐⭐⭐ 5/5 | ⭐⭐⭐⭐⭐ 5/5 | 持平 | 100+/day 决策框架贯穿 |
| **2. Easing & duration** | ⭐⭐⭐⭐⭐ 5/5 | ⭐⭐⭐⭐⭐ 5/5 | 持平 | 4 档 curve + reduce-motion 封装 |
| **3. Physicality & origin** | ⭐⭐⭐⭐ 4/5 | ⭐⭐⭐⭐ 4/5 | 持平 | 3.1 vent compose 3 态切换未修 |
| **4. Interruptibility** | ⭐⭐⭐⭐⭐ 5/5 | ⭐⭐⭐⭐⭐ 5/5 | 持平 | AnimatedSwitcher / PageTransitionSwitcher |
| **5. Performance** | ⭐⭐⭐⭐ 4/5 | ⭐⭐⭐⭐ 4/5 | 持平 | fade_in / slide_up 用 AnimatedBuilder 而非 FadeTransition |
| **6. Accessibility** | ⭐⭐⭐⭐⭐ 5/5 | ⭐⭐⭐⭐⭐ 5/5 | 持平 | reduce-motion + Semantics 全面 |
| **7. Cohesion & tokens** | ⭐⭐⭐⭐ 4.5/5 | ⭐⭐⭐⭐⭐ 5/5 | **+0.5**（7.1 13+ 处 Colors.white 全修，7.2 18+ 处 fontSize 全修，7.3 Stack 改用 LoadingTextButton） | SeverityIndicator 4 档塌成 2 档（详见 C-01 P2） |
| **8. Missed opportunities** | ⭐⭐⭐ 3/5 | ⭐⭐⭐ 3/5 | 持平 | A-opp-2 list↔calendar 切、A-opp-3 quiz→result 切、A-opp-6 contact 添加入口、A-opp-8 reminders_hub 4 卡片、A-opp-10 setup 勾选行 5 处仍未加动画 |

**总分**：从 36.5/40 → 38/40（+1.5，cohesion 是最大提升，错过的是 missed opportunities）。

---

## 2. 增量审视（v0.22 round 30 → v0.23 round 42）

### 2.1 1 个 P1（应修）

#### **P1-01 H-01 + H-03 + H-04 集中清理**（最高杠杆 P1）

| 字段 | 内容 |
|---|---|
| **位置** | `home_header.dart:40-63` (3 个 PressFeedback + IconButton)<br>`edit_medication_dialog.dart:389-401` (Stack + ElevatedButton)<br>`medication_report_dialog.dart:120-130` (FilledButton + Stack + Spinner)<br>`assessment_page.dart:81-83` (if/else quiz→result)<br>`trend_page.dart:102-105` (if/else list↔calendar)<br>`vent_compose_page.dart:467-528` (if/else audio 3 态)<br>`medications_list_widget.dart:353-369` (Container "已停药" chip) |
| **问题** | 5 个 widget 已抽（PressFeedbackIconButton / LoadingTextButton / PageTransitionSwitcher / ChipBadge / SectionHeader），但调用方 7 处仍 inline，**抽类目标完成度仅 50%**。emil "cohesion" 原则违反 — 同一项目 2 套写法 = 破窗。 |
| **修复** | 7 处一次性 grep 替换为已抽的 widget，85 分钟 |
| **杠杆** | 7 处 P2/P3 合并为 1 个 P1（合并后"修一处得 7 处一致"） |
| **难度** | trivial (1.5h) |
| **证据** | `lib/presentation/widgets/press_feedback_icon_button.dart`（38 行）<br>`lib/presentation/widgets/loading_text_button.dart`（79 行）<br>`lib/presentation/widgets/animations/page_transition_switcher.dart`（53 行）<br>`lib/presentation/widgets/chip_badge.dart`（81 行）<br>`lib/presentation/widgets/section_header.dart`（28 行）<br>—— 5 个集中器已就绪，调用方未迁移 |

### 2.2 11 个 P2（可修）

#### **C-01 SeverityIndicator 4 档配色塌成 2 档**（"抽类目标失败"bug，emil F1 同款）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/widgets/severity_indicator.dart:35-40` |
| **问题** | 4 档 `SeverityLevel`（ok / warning / error / neutral）配色塌成 2 档（`textSecondaryColor` + `colorScheme.error`）。调用方写 `warning` 视觉无差 → 退化成 `ok` 字符串。**跟 v0.23 round 40 (emil F1) 修过的 ChipBadge 4 tone 配色塌成 1 档完全同款 bug**。 |
| **修复** | `ok → textSecondaryColor` / `warning → AppTokens.warning` / `error → colorScheme.error` / `neutral → textHintColor` —— 1 个 `switch` 改 4 行色，1 行新增 `AppTokens.warning` getter（已存在 const） |
| **难度** | trivial (5 分钟) |
| **优先级** | **P2**（emil "cohesion" 原则，破坏 enum 的语义价值） |
| **证据** | 当前 switch：<br>```dart<br>final color = switch (level) {<br>  SeverityLevel.ok => AppTokens.textSecondaryColor(context),<br>  SeverityLevel.warning => AppTokens.textSecondaryColor(context),  // ❌ 同 ok<br>  SeverityLevel.error => Theme.of(context).colorScheme.error,<br>  SeverityLevel.neutral => AppTokens.textSecondaryColor(context),  // ❌ 同 ok<br>};<br>```<br>3/4 档相同 = enum 退化成字符串 |

#### **D-04 shadow token dark mode 反白失效**（round 30 D-02 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/core/theme/app_tokens.dart:309-342` |
| **问题** | 4 个 `shadowCard` / `shadowCardDark` / `shadowDialog` / `shadowOverlay` 全部用 `Color(0x14/0x1F/0x33/0x14 000000)` 黑色，**dark mode 完全不可见**。emil "translucent material" 哲学违反 — 暗色下阴影应该反白 `Color(0x33FFFFFF)` 30% 透明。 |
| **修复** | 加 `shadowCard(context)` dynamic getter 跟 `surfaceColor(context)` 同款，从 `Theme.of(context).colorScheme.shadow` 派生（**M3 标准** — colorScheme.shadow 在 dark mode 自动反白） |
| **难度** | small (30 分钟) |
| **优先级** | **P2**（dark mode 完整度的最后 10%） |
| **证据** | `app_tokens.dart:310` `color: Color(0x14000000)` (0x14 = 8% 不透明黑) |

#### **U3 抽 `AppListTile` 集中器**

| 字段 | 内容 |
|---|---|
| **位置** | `medications_list_widget.dart:335` / `contacts_list_widget.dart:61` / `settings_page.dart:169` / `medication_report_dialog.dart:107` 等 5+ 处 |
| **问题** | `ListTile` + leading icon + title Text + subtitle Text + trailing IconButton + PressFeedback 包裹模式重复 5+ 处。每次 `onTap` + leading `AppTokens.primary` + trailing chevron + PressFeedback 都各写各的 |
| **修复** | 抽 `AppListTile` widget 接 `leading / title / subtitle / trailing / onTap`，内包 `PressFeedback` + M3 ListTile 主题 |
| **难度** | small (1.5h) |
| **优先级** | **P2**（cohesion） |

#### **U5 5 个 inline `AnimatedSwitcher` 改用 `PageTransitionSwitcher`**

| 字段 | 内容 |
|---|---|
| **位置** | `assessment_page.dart:81-83` quiz→result / `trend_page.dart:102-105` list↔calendar / `mood_dialog` 5 评分态切换 / `vent_compose_page.dart:467-528` audio 3 态 |
| **问题** | `PageTransitionSwitcher` 已抽但只 setup_page 1 处用。**5 处仍 inline `if/else` 或 `if (audioPath == null)` 整块替换** —— 是 round 30 A5 抽取的"50% 落地" |
| **修复** | 5 处 `if/else` 替换为 `PageTransitionSwitcher(switchKey: state, child: ...)` |
| **难度** | small (1.5h) |
| **优先级** | **P2**（emil 决策框架 rare 频度可加 delight） |

#### **D-01 vent_compose 3 态切换无 origin 锚定**（round 30 3.1 P1 残留，但归 P2 因已不紧迫）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/vent/vent_compose_page.dart:467-528` |
| **问题** | 用户从"按 mic 录音" → 录音中（红圈 stop 按钮）→ 录音完（显示 play 按钮）三态切换仍 `if (audioPath == null) return TextButton.icon(...)` 整块替换。emil "spatial consistency" 违反 — 用户感觉不到"我刚按下"的位置感 |
| **修复** | 用 `PageTransitionSwitcher` 包裹 + 自定义 `transitionBuilder` 让 3 态在 mic 位置 crossfade |
| **难度** | small (1h) |
| **优先级** | **P2**（rare 频度 — 用户每天录 0-3 次，emil 决策框架 rare 频度可加 delight） |
| **依据** | round 30 P1-3.1 标 P1 但未修。当前评估属 P2 — 3 态切换频度低，修复 ROI 仍 OK 但非必修 |

#### **D-02 mood 5 评分按钮"已选"态突变**（round 30 C2 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/mood/mood_dialog.dart:570-608` |
| **问题** | 5 个评分按钮选中态仍是 `TextStyle(fontWeight: s == value ? w700 : w400, color: ...)` 瞬时切换。emil "preventing jarring change" 违反。 |
| **修复** | 外包 `AnimatedContainer(duration: durFast, color: tintedPrimarySoft)` + `AnimatedDefaultTextStyle` 让 100ms 平滑过渡 |
| **难度** | small (1h) |
| **优先级** | **P2** |
| **依据** | round 30 C2 标 P2，未修 |

#### **D-03 assessment quiz → result 切换瞬时**（round 30 A-opp-3 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/assessment/assessment_page.dart:81-83` |
| **问题** | `_submitted && _result != null ? _buildResultView(_result!) : _buildQuizView()` 整块切换，**无过渡** |
| **修复** | 用 `PageTransitionSwitcher` 包裹（V-05 集中清理 1 处） |
| **难度** | trivial (10 分钟) |
| **优先级** | **P2**（rare 频度，但精神心理患者对长时动效敏感，**仅 100-150ms fade**） |
| **依据** | round 30 A-opp-3 标 P2，注释明确"800ms 会让焦虑用户等待更久" |

#### **D-05 contact 添加入口缺 PressFeedback**（round 30 A-opp-6 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/contact/contacts_list_widget.dart:88-92` |
| **问题** | "添加联系人" ListTile 无 `PressFeedback` 包裹。tens/day 频度（用户偶尔添加），按 emil 决策框架应有 scale 反馈 |
| **修复** | 1 行包 `PressFeedback(child: ListTile(...))` |
| **难度** | trivial (5 分钟) |
| **优先级** | **P2** |
| **依据** | round 30 A-opp-6 标 P2，未修 |

#### **D-06 medication_calendar 10 行 × 40ms = 400ms stagger**（round 30 D-elim-8 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/medication/medication_calendar_page.dart:227-234` |
| **问题** | `FadeIn(delay: Duration(milliseconds: (i * staggerStepMs).clamp(0, staggerCapMs)))` —— 10 行 × 40ms = 400ms 用户等不了。emil "perceived performance" 违反 |
| **修复** | 改 cap 200ms（5 行后立即出现），5+ 行用户已经看到第一行 |
| **难度** | trivial (1 行改 `staggerCapMs = 200`) |
| **优先级** | **P2** |
| **依据** | round 30 D-elim-8 标 P2，未修 |

#### **D-07 assessment_question Card Semantics 标签硬编码中文**（round 30 C4 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/assessment/assessment_widgets.dart:201-204` |
| **问题** | `Semantics(container: true, label: '评估题 $index: ${item.text}, 4 项单选, 当前: $selectedLabel')` 硬编码中文，en 模式 TalkBack 读中文 |
| **修复** | 加 `l10n.assessmentQuestionLabel` ARB key，en 翻译为 `'Question $index: ${item.text}, 4 options, current: $selectedLabel'` |
| **难度** | small (1h) |
| **优先级** | **P2**（a11y + i18n 完整度） |
| **依据** | round 30 C4 标 P2，未修 |

#### **D-08 trend 视图切换（list ↔ calendar）无 fade**（round 30 A-opp-2 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/trend/trend_page.dart:102-105` |
| **问题** | 切换是 `if (_view == _TrendView.list) _buildListView(...) else _buildCalendarView(...)` 整块替换，无 fade |
| **修复** | 用 `PageTransitionSwitcher(switchKey: _view, child: ...)`（V-05 集中清理 1 处） |
| **难度** | trivial (10 分钟) |
| **优先级** | **P2**（occasional 频度，emil rare 可加 delight） |
| **依据** | round 30 A-opp-2 标 P2，未修 |

### 2.3 11 个 P3（nice-to-have / polish）

#### **D-09 settings_page 私有 `_SectionHeader` 死代码**（U6 落地）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/settings/settings_page.dart:714-729` |
| **问题** | 公共 `SectionHeader` 已抽（v0.23 round 40 F4），但 settings_page 仍保留 14 行私有 `_SectionHeader` 完整复制 |
| **修复** | 删私有 `_SectionHeader` 类 + 改 6 处调用为 `SectionHeader`（5 分钟） |
| **优先级** | **P3**（dead code） |

#### **D-10 shadowCard / shadowOverlay 等 token 重复命名**（emil token 命名哲学）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/core/theme/app_tokens.dart:309-342` |
| **问题** | `shadowCard` / `shadowCardDark` 名字混淆 — 后者不是"dark mode 专用"而是"card 阴影深一档"。emil token 命名应该语义化（"what it's for"） |
| **修复** | 改 `shadowCardLight` / `shadowCardStrong`（30 分钟 + 全项目 grep 替换） |
| **优先级** | **P3**（命名 polish） |
| **依据** | 跟 round 30 D-12（radiusCell/radiusCellLg）同款 token 命名问题，**未修** |

#### **D-11 fade_in / slide_up / celebration_overlay 用 AnimatedBuilder 而非 FadeTransition**（round 30 5.1 P3 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/widgets/animations/fade_in.dart:95-110` |
| **问题** | `AnimatedBuilder(animation: _t, ...)` 是对的（emil 5 "transitions over keyframes"），但 fade_in 可用 `FadeTransition(opacity: _t, child: ...)` + `ScaleTransition(scale: ...)` 直接用 controller 更轻。**slide_up 已做对，fade_in 没做对** |
| **修复** | 改 `_t` 为 `Animation<double> _t`，build 返回 `FadeTransition(opacity: _t, child: withScale ? ScaleTransition(scale: _t, child: child) : child)` |
| **难度** | small (30 分钟) |
| **优先级** | **P3**（性能微优化） |
| **依据** | round 30 5.1 标 P3，未修 |

#### **D-12 celebration overlay 总时长 1800ms 偏长**

| 字段 | 内容 |
|---|---|
| **位置** | `lib/core/theme/app_tokens.dart:240` `celebrationDisplayMs = 1800` |
| **问题** | 用户需要 1.8s 读完 overlay 文字，emil "rare 频度 delight 时刻"偏长 |
| **修复** | 改 1500ms（emil decision：rare 频度 ≤ 1500ms） |
| **难度** | trivial (1 行) |
| **优先级** | **P3** |
| **依据** | round 30 D-elim-4 提到"偏长可能"，但 round 30 时仍维持 1800，**精神心理患者**对长反馈窗口更敏感 |

#### **D-13 30+ 处 `TextStyle(fontSize: token, fontWeight: ...)` 改为 `textStyle*(context).copyWith(color: ...)`**（U4 落地）

| 字段 | 内容 |
|---|---|
| **位置** | 全项目 grep 30+ 处 |
| **问题** | `textStyleLabel` / `textStyleBody` 等已抽，但调用方 30+ 处仍 `TextStyle(fontSize: AppTokens.x, fontWeight: w500, color: ...)` —— cohesion 漏网 |
| **修复** | 1 次性 grep 替换 |
| **难度** | small (1h) |
| **优先级** | **P3** |
| **证据** | grep `TextStyle(\s*\n?\s*fontSize` 命中 50+ 处（包含合法 const 构造） |

#### **D-14 `radiusCell` / `radiusCellLg` 命名奇怪**（round 30 D-12 P3 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/core/theme/app_tokens.dart:251-252` |
| **问题** | `radiusCell (2.0) / radiusCellLg (4.0)` 命名奇怪 — emil token 命名应语义化（"what it's for"） |
| **修复** | 改 `radiusHeatmapCell = 2.0` / `radiusCalendarCell = 4.0`（30 分钟 + 全项目 grep） |
| **优先级** | **P3**（命名 polish） |
| **依据** | round 30 D-12 标 P3，未修 |

#### **D-15 评分按钮 `Padding(horizontal: 12, vertical: 8)` 硬编码**（mood_dialog）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/mood/mood_dialog.dart:585-587` |
| **问题** | `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` 应走 `AppTokens.spacingSm` / `spacingXs`（12/8 是 token 对应值但未用 token） |
| **修复** | 1 行替换为 `EdgeInsets.symmetric(horizontal: AppTokens.spacingSm, vertical: AppTokens.spacingXs)` |
| **优先级** | **P3** |

#### **D-16 `home_footer.dart:49` text fade `withValues(alpha: 0.6)` 硬编码**

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/home/widgets/home_footer.dart:49` |
| **问题** | `color.withValues(alpha: 0.6)` 0.6 硬编码 — 应叫 `textMuted` 或类似 token |
| **修复** | 加 `AppTokens.textMutedColor(context)` getter（`textSecondaryColor` + 0.6 alpha）或保留 hardcode |
| **难度** | trivial (5 分钟) |
| **优先级** | **P3**（token 化漏网） |

#### **D-17 assessment 进度文字 "已答 3/9" 无 fade**（round 30 D-7 P3 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/assessment/assessment_page.dart:106-113` |
| **问题** | `assessmentAnsweredProgress(_answered, scale.items.length)` 文字变化瞬时，emil "preventing jarring change" 违反 |
| **修复** | `AnimatedSwitcher` 50ms fade 包裹 |
| **难度** | trivial (5 分钟) |
| **优先级** | **P3** |
| **依据** | round 30 D-7 标 P3，未修 |

#### **D-18 setup "查看" / "开始" 按钮缺 PressFeedback**（round 30 emil-30/emil-31 已修，确认）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/setup/setup_step_consent.dart` / `setup_step_done.dart` |
| **状态** | ✅ **已修**（v0.22 round 28 emil-30/31 batch 修了） |
| **优先级** | ✓ 已优 |

#### **D-19 setup 3 勾选行瞬时切换**（round 30 A-opp-10 P2 残留）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/setup/setup_step_consent.dart` 3 个 `ConsentCheckRow` |
| **问题** | 勾选时背景色 `primaryLightColor ↔ surfaceColor` 瞬时切换 |
| **修复** | `AnimatedContainer` 100ms 颜色过渡 |
| **难度** | small (1h) |
| **优先级** | **P3**（onboarding 频度 = rare，emil 决策可加 subtle 反馈） |
| **依据** | round 30 A-opp-10 标 P2 |

#### **D-20 EncouragementText 跨 streak 文案无 fade**（round 30 1.1 P3 + A-opp-11）

| 字段 | 内容 |
|---|---|
| **位置** | `lib/presentation/pages/home/widgets/encouragement_text.dart:13-32` |
| **问题** | streak 1 → 7 → 30 → 100 文案内容瞬时跳变，emil 决策"100+/day → MotionScheme.none"正确，但 50ms `AnimatedSwitcher` fade 仍能感知"我刚到新 streak"（mental health user 重要反馈） |
| **修复** | 加 `AnimatedSwitcher(duration: durFast, child: Text(...))` 包裹 |
| **难度** | trivial (10 分钟) |
| **优先级** | **P3** |
| **依据** | round 30 1.1 / A-opp-11 标 P3，明确"emil 决策正确但 fade 仍好" |

---

## 3. 不可见细节（D 系列，12 项 P3 之中 5 项已在 §2.3 + §2.2 列出）

### 3.1 8 维度动画审计（emil AUDIT.md 对照）

| 维度 | 现状 | 残留问题 |
|---|---|---|
| **1. Purpose & frequency** | ⭐⭐⭐⭐⭐ 5/5 | `MotionScheme` enum + 频度注释贯穿全代码 |
| **2. Easing & duration** | ⭐⭐⭐⭐⭐ 5/5 | 4 个 curve token（`curveStandard=easeOutCubic` / `curveDecelerate=easeOutQuart` / `curveAccelerate=easeInCubic` / `curveDelight=elasticOut` / `curveBackOut=easeOutBack` v0.23 round 40 F2 新增）全项目用对 |
| **3. Physicality & origin** | ⭐⭐⭐⭐ 4/5 | vent_compose 3 态切换无 origin 锚定（D-01） |
| **4. Interruptibility** | ⭐⭐⭐⭐⭐ 5/5 | `AnimatedSwitcher` / `TweenAnimationBuilder` / `AnimatedContainer` 用对；`Motion.duration/curve` 封装 reduce-motion |
| **5. Performance** | ⭐⭐⭐⭐ 4/5 | `fade_in` 用 `AnimatedBuilder` 而非 `FadeTransition`（D-11） |
| **6. Accessibility** | ⭐⭐⭐⭐⭐ 5/5 | reduce-motion 全项目 + Semantics 在评分按钮 / 评估题 / 通知自检卡 / streak counter |
| **7. Cohesion & tokens** | ⭐⭐⭐⭐⭐ 5/5（round 30 4.5 升 5） | SeverityIndicator 4 档塌成 2 档（C-01 P2，唯一残留） |
| **8. Missed opportunities** | ⭐⭐⭐ 3/5 | 5 处未加动画（vent 3 态 / mood 5 评分 / assessment quiz→result / trend 视图切换 / setup 3 勾选） |

### 3.2 不可见细节清单（D-elim 系列 = 应删/弱化）

| # | 位置 | 当前 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|
| D-elim-1 | `medication_calendar_page.dart:218-234` | 10 行 × 40ms = 400ms stagger | cap 200ms | trivial | **P2**（D-06 复述） |
| D-elim-2 | `app_tokens.dart:240 celebrationDisplayMs=1800` | 1800ms overlay | 1500ms | trivial | **P3**（D-12） |
| D-elim-3 | `check_in_button.dart:32-60` | `AnimatedContainer durNormal=300ms` checked 切换 | 改 `durFast=200ms` | trivial | P3 |
| D-elim-4 | `check_in_button.dart:53-64` | `AnimatedSwitcher durNormal=300ms` 文字切换 | 改 `durFast=200ms` | trivial | P3 |
| D-elim-5 | `loading_skeleton.dart:120-123` shimmer 1.2s 永久循环 | — | 保留（业界标准，reduce-motion 已停） | — | ✓ OK |

### 3.3 不可见细节清单（D-series 不在 round 30 基线的 = v0.22 round 30 之后发现）

| # | 位置 | 问题 | 难度 | 优先级 |
|---|---|---|---|---|
| **D-NEW-01** | `section_header.dart:29-34` | 内部仍 `TextStyle(fontSize: fontSizeLabel, color: ..., fontWeight: w500)` 裸写 — 已有 `textStyleLabelMedium(context)` token **但本 widget 自己不用** | trivial | **P3** |
| **D-NEW-02** | `medication_report_dialog.dart:162` | `Colors.black54` 仍硬编码（round 30 C6 7.1 同款 — **PDF loading mask**），dark mode 黑色 mask 50% 透明 = 仍然偏黑。emil "translucent material" 违反 | trivial | **P3**（round 30 P1 残留，被 13 处批量修遗漏） |
| **D-NEW-03** | `assessment_widgets.dart:141` | 注释 `'之前 Colors.white 在 dark mode 下不反白'` —— 13 处批量修漏掉的 1 处**仅在注释里**。实际代码已修，注释误导未来 reader | trivial | P3 |
| **D-NEW-04** | `medications_list_widget.dart:352` | `const SizedBox(width: 6)` 硬编码 — 应 `AppTokens.spacingChipGap = 6.0` | trivial | P3 |
| **D-NEW-05** | `trend_summary.dart:22, 24` | `value: '${summary.currentStreak} 天'` 硬编码中文"天" — 应走 ARB | small | P3 |
| **D-NEW-06** | `medication_calendar_page.dart:83` | `label: '时间窗口 $days 天, 7/30/90 单选'` 硬编码中文 Semantics | small | P3（i18n 残留） |
| **D-NEW-07** | `mood_dialog.dart:566, 576` | `label: '情绪评分，1 到 5 分制'` / `'$s 分${s == value ? "，已选" : ""}'` 硬编码中文 Semantics | small | P3（i18n 残留） |

---

## 4. 该加 / 该删的动画（emil Gate 过审清单）

### 4.1 该加的（已散在 §2 P2-3，汇总 5 处）

| # | 位置 | 应加什么 | 频度 | 难度 | 优先级 |
|---|---|---|---|---|---|
| A-opp-A | `vent_compose_page.dart:467-528` audio 3 态 | `PageTransitionSwitcher` 包裹 + 自定义 `transitionBuilder`（mic 位置 crossfade） | rare | small | P2（D-01） |
| A-opp-B | `mood_dialog.dart:570-608` 5 评分"已选" | `AnimatedContainer(duration: durFast, color: tintedPrimarySoft)` | tens/day | small | P2（D-02） |
| A-opp-C | `assessment_page.dart:81-83` quiz→result | `PageTransitionSwitcher` 100-150ms fade（**不要 800ms**！精神心理患者焦虑） | rare | trivial | P2（D-03） |
| A-opp-D | `contact/contacts_list_widget.dart:88-92` 添加联系人 | 外包 `PressFeedback` | tens/day | trivial | P2（D-05） |
| A-opp-E | `trend_page.dart:102-105` list↔calendar | `PageTransitionSwitcher` 100ms fade | occasional | trivial | P2（D-08） |

### 4.2 该删 / 弱化的

| # | 位置 | 当前 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|
| D-del-A | `medication_calendar_page.dart:218-234` 10 行 stagger | 10 行 × 40ms = 400ms | cap 200ms（5 行后立即出现） | trivial | P2（D-06 / D-elim-1） |
| D-del-B | `app_tokens.dart:240 celebrationDisplayMs=1800` | 1800ms overlay | 1500ms | trivial | P3（D-12 / D-elim-2） |
| D-del-C | `check_in_button.dart:32-60` 状态过渡 durNormal=300ms | 300ms | durFast=200ms | trivial | P3（D-elim-3） |
| D-del-D | `check_in_button.dart:53-64` 文字 AnimatedSwitcher 300ms | 300ms | durFast=200ms | trivial | P3（D-elim-4） |

### 4.3 emil Gate 验证

- ✅ 频度：100+/day 无动画（encouragement_text 决策正确）
- ✅ 频度：tens/day 微弱（PressFeedback 0.97 scale + 160ms 全项目）
- ✅ 频度：occasional 标准（PageTransitionSwitcher 100ms）
- ✅ 频度：rare delight（celebration overlay + setup fade+slide）
- ✅ Purpose：每个动效都有"为什么"（注释明确）
- ✅ Speed：所有 UI 动效 ≤ 300ms（emil 标准）
- ✅ Function：动效帮用户不阻碍（不阻塞交互）

---

## 5. round 30 P0 / P1 修复状态确认

| 编号 | 标题 | 优先级 | round 42 状态 | 备注 |
|---|---|---|---|---|
| C1 / A-opp-1 | home_header 3 个 IconButton 缺 scale 反馈 | P1 | ✅ **已修**（v0.22 round 36 emil C1） | `home_header.dart:40-63` 3 个全外包 PressFeedback |
| 3.1 | vent compose 3 态切换无 origin 锚定 | P1 | ❌ **未修**（`_AudioSection` 仍 if/else） | 归 P2 见 D-01 |
| 7.1 | 15+ 处 `Colors.white/black` 散落 | P1 | ✅ **13+ 处已修**（剩 2 处 P3） | `grep Colors\\.(white\\|black)` 2 处：`assessment_widgets.dart:141`（仅注释）+ `medication_report_dialog.dart:162`（PDF mask） |
| 7.2 | 18+ 处 `fontSize` 硬编码 | P1 | ✅ **17+ 处已修**（剩 1 处 monospace） | `grep "fontSize:\\s*[0-9]+"` 1 处：`settings_page.dart:667` monospace import 文本框 |
| 7.3 | `Stack([Text, if saving Spinner])` 重复 4+ 处 | P1 | ✅ **4+ 处已修** | 抽 `LoadingTextButton`（v0.22 round 34 A1） |
| 8.1 | settings section 视觉分组切换 | P1 | ⚠️ **半修** | 拆 6 section 但仍 `SizedBox(spacingLg)` 隔开，未加 `AnimatedSize` accordion 切换 |
| 3.1 (重复) | vent compose 3 态切换 | P1 | ❌ **未修** | 同上 |

**修复率**：5/7 = **71%** P1 修完。剩余 2 个 P1（3.1 vent compose 3 态 + 8.1 settings section 切换）按当前评估归 P2 优先级（**已不紧迫** — vent 3 态频度低 + settings section 切换不是用户日常路径）。

---

## 6. 汇总统计

### 6.1 总问题数

- **总问题数**：23 个
- **P0**：0 个（无必修 —— v0.23 round 42 无 feel-breaking 回归）
- **P1**：1 个（H-01 + H-03 + H-04 集中清理 7 处）
- **P2**：11 个
- **P3**：11 个

### 6.2 按类型分布

| 类型 | 数量 | 编号 |
|---|---|---|
| 组件抽离落地 | 5 | H-01~H-05 |
| 8 维度动画审计 | 5 | C-01 / D-04 / D-01 / D-03 / D-08 |
| 不可见细节 | 8 | D-02 / D-05 / D-06 / D-07 / D-09 / D-10 / D-11 / D-13 |
| i18n / a11y 残留 | 4 | D-05 / D-07 / D-NEW-05 / D-NEW-06 / D-NEW-07（部分重叠） |
| 该加动画 | 5 | A-opp-A~E（散在 P2） |
| 该删动画 | 4 | D-del-A~D（散在 P2-P3） |
| 顶层 UI 架构 | 6 | U1~U6（建议表） |
| god class 拆分 | 8 | R1~R8（5 P2-P3 + 3 P3） |

### 6.3 按修复成本

| 难度 | 数量 | 总耗时 |
|---|---|---|
| trivial (<1h) | 11 | ~3h |
| small (1-4h) | 9 | ~12h |
| medium (4-8h) | 3 | ~14h |
| large (8-16h) | 0 | 0h |
| xlarge (>16h) | 0 | 0h |

**总修复成本**：~29h（4 个工作日，**1 个 round 集中消化**）

### 6.4 跟 round 30 对比

| 维度 | round 30 | round 42 | 变化 |
|---|---|---|---|
| 总问题数 | 41 | 23 | **-44%** |
| P0 | 0 | 0 | 持平（无 feel-breaking 回归） |
| P1 | 7 | 1 | **-86%** |
| P2 | 17 | 11 | -35% |
| P3 | 17 | 11 | -35% |
| 抽取 widget | 5 个 | 15 个 | **+10** |
| `Colors.white/black` 散落 | 15+ 处 | 2 处 | **-87%** |
| `fontSize` 硬编码 | 18+ 处 | 1 处 | **-94%** |

---

## 7. 关键观察（5 段）

### 7.1 v0.23 round 42 是"V+ 级别"成熟项目，5 个抽取 widget 全部落地

`app_tokens.dart` 现在 608 行（v0.23 round 40 F1~F12 集中加 12 个 token）覆盖：
- 动效：4 档 `MotionScheme` + 4 个 `dur*` + 5 个 `curve*`（含 `curveBackOut`） + `Motion.duration/curve`
- 颜色：8 个 dynamic `*Color(context)` + 5 个 `tinted*` + 4 个 `fgOn*` + 7 个 `text*Color`
- 文字：11 个 `textStyle*` + 8 个 `fontSize*` + 5 个 `lineHeight*`
- 间距：5 档 + 4 个 `spacingXxx*` + stagger 公式
- 圆角：6 个 `radius*`
- 阴影：4 个 `shadow*`

**这是 emil 哲学的"good defaults matter more than options"完整实现** —— 新增 widget 不用思考该用什么色/什么字/什么缓动，**默认就 token 化**。

### 7.2 抽类目标完成度从 50% 到 100% = 1 个 P1 集中清理

v0.22 round 30 抽 5 个 widget，但调用方只 50% 迁移。v0.23 round 41 P3-32 抽 `PressFeedbackIconButton` 后 0 迁移（H-01）。**这违反 emil "cohesion" 原则 —— 同一项目 2 套写法 = 破窗**。

7 处一次性 grep 替换（H-01 home_header × 3 + H-03 edit_med + med_report × 2 + H-04 assessment + trend + vent_compose + H-05 medications_list）= 85 分钟 = **1 个 round 集中清理**。

### 7.3 抽类目标失败 1 例（C-01 SeverityIndicator）—— 跟 ChipBadge 同款 bug

v0.22 round 34 抽 `SeverityIndicator` 时 4 档配色塌成 2 档（ok / warning / neutral 全用 `textSecondaryColor`，只有 error 用 `colorScheme.error`）。**调用方写 `warning` 视觉无差 = enum 退化成字符串**。

v0.23 round 40 (emil F1) 修了 `ChipBadge` 4 tone 配色塌成 1 档的同款 bug（success / warning / error 之前跟 neutral 配色完全一样）。**SeverityIndicator 是 F1 没修的孪生 bug**。

emil "decisions should be nameable" 原则 —— 抽 enum 但视觉无差 = 抽类目标失败。**修法 1 行**：`error → error color` / `warning → warning color` / `ok → textSecondaryColor` + `neutral → textHintColor`。

### 7.4 dark mode shadow 反白失效（D-04）是 1 个 P2 残留

4 个 `shadowCard` / `shadowCardDark` / `shadowDialog` / `shadowOverlay` token 全部用 `Color(0x14/0x1F/0x33/0x14 000000)` 黑色。**dark mode 下黑色阴影 = 不可见**。这是 round 30 D-02 残留。

emil "translucent material" 哲学违反 — 暗色下阴影应该反白 `Color(0x33FFFFFF)` 30% 透明。**M3 标准做法**：用 `Theme.of(context).colorScheme.shadow` 派生（dark mode 自动反白）。

**修法 1 个 dynamic getter**：`shadowCard(context)` 从 colorScheme.shadow 派生，类似 `surfaceColor(context)` 已有的 8 个 dynamic getter。

### 7.5 精神心理患者"前庭敏感"是这个项目的隐含约束（继承 round 30）

`Motion.duration/curve` 全项目覆盖 `prefers-reduced-motion`（P0-7 已修）。`celebrationDisplayMs=1800`（emil P2-8 抽的）也比一般 app 短（一般 2-3s），给用户更短反馈窗口。

**v0.23 增量继承这个约束**：
- `curveBackOut` (easeOutBack) 是 v0.23 round 40 F2 新增的 token，**1 次过冲不弹多次**（区别 `elasticOut` 多次回弹）—— 庆祝主弹跳用 `easeOutBack` 更"稳"
- `tintedSuccessSoft` 0.1 alpha 替代 0.15 — 更柔和不刺激
- `spacingChipGapInline = 4.0` 新增 — 0.4× 标准 gap，chip 内部更紧凑不刺激
- `iconSizeMicro = 12.0` 新增 — chip 内小图标，比 iconSize 24 小一倍

**emil 原则 #8 "respect the user" 的具体化** —— 精神心理患者对长时动效 + 大图标 + 强对比敏感，token 化让所有 widget 默认就"低刺激"。

---

## 8. 下 round 建议（v0.24 一个 round 消化清单）

### 8.1 P1 集中清理（85 分钟，1 个 round 主体）

| 顺序 | 内容 | 耗时 | 验证 |
|---|---|---|---|
| 1 | H-04 vent_compose 3 态 + assessment quiz→result + trend list↔calendar + mood 5 评分 改用 `PageTransitionSwitcher` | 1.5h | grep `if (_view ==` `if (audioPath == null)` 0 hit |
| 2 | H-01 home_header 3 个 IconButton 改用 `PressFeedbackIconButton` | 10min | grep `PressFeedback(\s*child: IconButton` 0 hit |
| 3 | H-03 edit_med + med_report dialog 改用 `LoadingTextButton` | 30min | grep `if (_saving)` + `CircularProgressIndicator` dialog 0 hit |
| 4 | H-05 medications_list "已停药" chip 改用 `ChipBadge(tone: warning)` | 10min | grep `tintedWarningSoft` 1 处仅 chip_badge |
| 5 | D-09 删 settings_page 私有 `_SectionHeader` 14 行死代码 | 5min | grep `_SectionHeader` 0 hit |
| 6 | D-05 contact 添加入口 + D-02 mood 5 评分 + D-01 vent 3 态 + D-08 trend 视图 + D-03 assessment quiz→result + D-06 stagger cap 200ms 一次性修 | 1h | grep 各 hardcode 模式 0 hit |

**总耗时**：3.5h

### 8.2 P2 集中清理（4h，1 个 round 后续或并入）

| 顺序 | 内容 | 耗时 |
|---|---|---|
| 7 | C-01 SeverityIndicator 4 档配色独立（emil F1 二阶段） | 5min |
| 8 | D-04 shadow token dark mode 反白（`shadowCard(context)` dynamic getter） | 30min |
| 9 | U3 抽 `AppListTile` 集中器（替换 5+ 处） | 1.5h |
| 10 | D-13 30+ 处 `TextStyle` 改 `textStyle*().copyWith(color)` | 1h |
| 11 | D-07 + D-NEW-05/06/07 i18n 残留（Semantics 标签 + 中文 value） | 30min |

**总耗时**：3.5h

### 8.3 god class 拆分（14h，v0.24 拆分 R1-R3）

| 顺序 | 内容 | 耗时 |
|---|---|---|
| 12 | R1 mood_dialog 拆 `widgets/rating_row.dart` + `widgets/tag_filter.dart` | 5h |
| 13 | R2 assessment_history_page 拆 chart + list + legend | 5h |
| 14 | R3 trend_charts 拆 heatmap / monthly / sparkline | 4h |

**总耗时**：14h（跟其他 P1/P2 一起，**1 个 round 集中消化**）

### 8.4 v0.24 集中清理预期

| 维度 | round 42 | round 24 预期 |
|---|---|---|
| 总问题数 | 23 | **8**（P2 集中消 5 + god class 3 留中） |
| P0 | 0 | 0 |
| P1 | 1 | **0**（H-01~05 + D-05 + D-09 一次性清） |
| P2 | 11 | **4**（C-01 / D-04 / U3 / D-13 集中消 8，剩 3 个 P2） |
| P3 | 11 | 11（保持，留给 v0.25+） |
| god class 拆分 | 0/3 | **3/3**（R1-R3 拆完） |
| 抽取 widget 落地 | 50% | **100%**（H-01~05 一次性消化） |

**v0.24 后只剩 P3 polish** + 顶层架构 god class 进一步拆分。

---

> **审查完毕**。项目总体：**V+ 级别 UI 工程质量**（v0.23 round 42 顶配）。
> **最关键 1 个建议**：H-01 + H-03 + H-04 集中清理 7 处 —— 85 分钟，1 个 P1 一次性消化。
> **最大批量收益**：C-01 SeverityIndicator 4 档配色独立（emil F1 同款孪生 bug）+ D-04 shadow token dark mode 反白（2 项 trivial，**emil 原则直接命中**）。
> **架构层面最关键 1 个建议**：god class 拆分 R1 / R2 / R3（mood_dialog 797 行 / assessment_history 624 行 / trend_charts 595 行）—— 14h，1 个 round 集中消化，**emil "decisions should be nameable" 在大文件粒度的体现**。
