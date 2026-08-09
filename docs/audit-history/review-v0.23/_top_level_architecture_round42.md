# 顶层架构审视（v0.23 round 42 / owner 视角草稿）

> **作者**：Mavis（root orchestrator）
> **基线**：v0.22 round 30 三份报告 + v0.22 round 30 → v0.23 round 42 共 12 round 实际变更
> **目的**：回答用户问题——"项目是否可采用更优架构、存在哪些可重构的模块、高内聚低耦合"
> **状态**：草稿（worker 报告回来后根据增量发现 refine）

---

## 1. 当前架构画像（基线）

| 维度 | 现状 | 来源 |
|---|---|---|
| 总规模 | 183 lib 文件 / 845 tests / 0 analyze error | AGENTS.md + ls 计数 |
| 架构 | 4 层（presentation / domain / data）+ 5 个 umbrella（core/{data,shared,theme,routing,l10n}） | AGENTS.md §"4 层架构" |
| 核心模式 | 4 层依赖方向 `presentation → domain ← data`；domain 0 flutter 0 drift | check_all.dart 100% 纯度 |
| 跨 feature 守门 | `check_cross_feature.py --ci` 0 violation | round 30 spen 验过 |
| 隐私边界 | vent 0 进分析/通知/关怀；树洞独立表 | AGENTS.md §"隐私边界" |
| Facade 模式 | `notification_service.dart` 已 facade 4 子服务（SnoozeManager / ReminderService / AssessmentReminderService / SafetyWatchService） | round 30 spen §"可重构模块" |
| Token 化 | `app_tokens.dart` 525 行覆盖动效 95% / 颜色 90% / 字号 60% / 间距 100% / 圆角 100% / 阴影 100% | round 30 emil §"顶层架构审视" |
| 通用 widget | `presentation/widgets/` 8 文件（loading_skeleton / page_scaffold / press_feedback / secondary_button / app_snack_bar / animations/ 等） | round 30 emil §"组件设计问题" |
| 数据存储 | Drift + SQLCipher（本地加密，零云端） | AGENTS.md §"关键约束" |
| Provider 框架 | Riverpod 3.3.2（24 provider 全手写，**未用 riverpod_generator**） | AGENTS.md §"栈" |
| Union type | 手写 enum + switch（**未用 Freezed sealed class**） | round 30 spen §"项目可采用的更优架构" |
| CI | 4 件套（flutter analyze + test + check_all + check_cross_feature）；**未跑 `flutter build apk` / `flutter build web`** | round 30 spen §"verification-before-completion 落地" |
| i18n | 99% 完整（中英 ARB 108+ keys；**1% 漏在 exception / debug 路径**） | round 30 spzh §"中文 UI 文案 i18n 完整性" |

**成熟度判断**：v0.23 round 42 = 12 round 连续打磨，**4 层架构纯度 100% + token 化 90% + 测试 845 / 845**。**架构是项目最稳的资产**（round 30 spen 观察 #1）。

---

## 2. 项目可采用的更优架构（按性价比排序）

### A. **riverpod_generator 引入**（性价比最高，建议做）

- **现状**：24 个 provider 全手写，每个 5-15 行 boilerplate
- **方案**：加 `@riverpod` annotation，`build_runner` 自动生成 provider
- **收益**：
  - 减 30% provider 代码（5+ files × 50 行）
  - 改 provider 签名时 IDE 重构友好
  - 跟 Drift `build_runner` 流程合并
- **风险**：
  - 1 天迁移 + 24 provider 改写
  - `dart fix` 可能产生 diff 需要手动 review
- **建议**：**值得做**（small / 1 day / 收益持续）

### B. **隐私子包化 `core/data/privacy/`**

- **现状**：隐私敏感文件散在 3 个目录：
  - `core/data/services/vent_audio_storage.dart`
  - `core/data/services/notification_payload.dart`
  - `core/data/services/pii_safe_log.dart`
  - `core/data/services/encryption_service.dart`
  - `core/shared/json_codec.dart`（PII 序列化）
- **方案**：抽 `lib/core/data/privacy/` 子包，集中这 4-5 个文件
- **收益**：
  - 合规审计（律师外审 PIPL §14 §52）一次看一个目录
  - 未来加 GPS / 联系人 / 国密 SM4 都有专门目录
  - `check_all.dart` 加 "privacy 子包不依赖 presentation" 守门
- **风险**：仅改 import 路径，0 行为变化
- **建议**：**值得做**（small / 4-6h / 一次性收益但长期受益）

### C. **push 通道架构化（接 5 厂商 SDK）**

- **现状**：
  - `notification_service.dart` 调 `flutter_local_notifications`，未接厂商 push
  - 国产 ROM 杀进程后通知 0 送达（v0.22 round 20 修过自检卡，治标不治本）
  - round 30 spzh 标记为 **P0 必修 / 80-120h**
- **方案**：抽 `lib/core/data/services/push/` 子包，分接口 + 实现
  ```
  push/
  ├── push_channel.dart           # 抽象接口
  ├── local_notification_channel.dart  # 已有
  ├── hms_channel.dart            # 华为（new）
  ├── mipush_channel.dart         # 小米（new）
  ├── oppo_push_channel.dart      # OPPO（new）
  ├── vivo_push_channel.dart      # vivo（new）
  ├── flyme_push_channel.dart     # 魅族（new）
  └── push_dispatcher.dart        # 编排：本地 fallback → 厂商 push
  ```
- **收益**：架构上支撑 v0.23+ 国产 ROM 通知完全失效问题的根因解决
- **风险**：xlarge（每家 SDK 接入 16-24h + 5 厂商开发者联盟注册 + 推送证书）
- **建议**：**必做但分阶段**（v0.24 接 1-2 家，v0.25 接剩余）

### D. **`application/` 中间层（use case 编排）**

- **现状**：
  - `domain/logic/care_engine.dart`（业务规则 + 部分 IO 双重职责）
  - `domain/logic/safety_watch_service.dart`（同上）
  - `domain/logic/reminder_scheduler.dart`（同上）
  - 典型"厚 service"反模式（round 30 spen #1 提了）
- **方案**：抽 `lib/application/` 中间层
  ```
  application/
  ├── care/
  │   ├── apply_care_check.dart       # 用例：触发失联检查
  │   └── record_care_event.dart      # 用例：记录关怀事件
  ├── medication/
  │   ├── schedule_refill_reminder.dart
  │   └── record_medication_taken.dart
  └── assessment/
      ├── compare_with_history.dart
      └── schedule_assessment_reminder.dart
  ```
- **收益**：
  - domain 业务规则 100% 纯 Dart 可单测（已达成）
  - service 退化为薄 IO wrapper
  - use case 编排独立可测（mock 多个 repo）
- **风险**：
  - 重组 ~20 个文件
  - mid-risk（破坏现有 24 provider 的依赖图）
- **建议**：**锦上添花**（medium / 8-12h / 看 v0.24+ 业务复杂度再决定）。如果业务继续线性增长，不需要；如有重大新需求（多用户 / 多角色 / 远程同步），必须

### E. **顶层 widget library 子目录化**

- **现状**：`lib/presentation/widgets/` 8 文件
  - 通用：loading_skeleton / page_scaffold / press_feedback / secondary_button / app_snack_bar
  - 动画：animations/{fade_in, slide_up, celebration_overlay}
- **方案**：拆 `widgets/{buttons, chips, cards, forms, animations, layouts, errors, a11y}/` 子目录
- **收益**：发现 widget 更直观
- **风险**：仅改 import 路径
- **建议**：**值得做**（small / 2-3h / 但跟 god class 拆分是同一个 round 工作）

### F. **Drift → Isar / sembast 迁移**

- **现状**：Drift 代码生成慢、alter table 不支持改列属性（v0.22 round 31 修过 userName schema）
- **方案**：迁 Isar（NoSQL，schema 灵活）
- **收益**：免 migration、改列属性、build 快 5x
- **风险**：xlarge（1 周迁移 + 重新测试 845 tests）
- **建议**：**不做**。当前 schema 已稳定（schemaVersion 12），Drift 性能可接受，迁移 ROI 极低

### G. **Freezed union types**

- **现状**：`CareTriggerType` (5 case) / `SafetyCheckKind` (8 case) / `ReminderLevel` (5 case) 大量 switch
- **方案**：Freezed sealed class 提供 exhaustive checking
- **收益**：编译期 catch missing case
- **风险**：加 1 个 build dep
- **建议**：**锦上添花**（small / 1 day）。当前 switch 都有 default 分支兜底，不算紧急

### H. **BLoC 替代 Riverpod**

- **不建议**。项目已 3 层抽象（domain entity / abstract repo / impl）+ Riverpod 3.x 的 `AsyncValue.whenData` 已 OK。切换 BLoC 重写成本远大于收益

### 决策矩阵

| 选项 | 难度 | 收益 | 风险 | 建议 |
|---|---|---|---|---|
| A. riverpod_generator | small (1d) | 高 | 低 | **v0.24 启动** |
| B. privacy 子包化 | small (4-6h) | 中 | 低 | **v0.24 启动** |
| C. push 通道架构化 | xlarge (80-120h) | 高（解 P0） | 中 | **v0.24-25 分阶段必做** |
| D. application/ 中间层 | medium (8-12h) | 中 | 中 | 锦上添花，看 v0.24 业务 |
| E. widget library 子目录化 | small (2-3h) | 低 | 低 | 跟 god class 拆分同一个 round |
| F. Drift → Isar | xlarge (1w) | 低 | 高 | **不做** |
| G. Freezed union | small (1d) | 中 | 低 | 锦上添花 |
| H. BLoC 替代 | xlarge | 负 | 高 | **不做** |

---

## 3. 可重构的模块（god class / over-engineered）

按"文件大小 + 单一职责违反程度 + round 30 报告 + 12 round 实际进展"综合排序：

### P1（应修）

| # | 文件 | 现状 | 拆分方案 | 跟 round 30 差异 |
|---|---|---|---|---|
| 1 | `lib/presentation/pages/mood/mood_dialog.dart` 797 行 | 1 文件含 4 维评分 + 标签 + chip 选中态 + tag 输入 + saving 状态 | 拆 `widgets/rating_row.dart` / `widgets/tag_filter.dart` / `mood_dialog.dart` 主体 | round 30 emil **没列**（后增严重） |
| 2 | `lib/presentation/pages/settings/settings_page.dart` 688 行 | 6 section 混 | round 34 抽了 5 个通用 widget 但 section 仍混；继续拆 `widgets/notifications_section.dart` / `widgets/data_section.dart` / `widgets/about_section.dart` | round 30 spen #1 提，**部分修**（v0.22 round 34） |
| 3 | `lib/presentation/pages/assessment/assessment_history_page.dart` 624 行 | chart + list + legend + filter 混 | 拆 `widgets/history_chart.dart` / `widgets/history_list.dart` / `widgets/severity_legend.dart` | round 30 spen #4 提，**未修** |
| 4 | `lib/presentation/pages/trend/trend_charts.dart` 595 行 | 1 文件 4 widget（heatmap / monthly_chart / sparkline / day_cell） | 拆 3-4 个文件 | round 30 spen #8 提，**未修** |
| 5 | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` 397 行 | form fields + time picker + refill + sav ing state 混 | 拆 `widgets/med_form_fields.dart` / `widgets/time_picker_section.dart` / `widgets/refill_section.dart` | round 30 spen #7 提，**未修** |

### P2（可修）

| # | 文件 | 现状 | 拆分方案 | 跟 round 30 差异 |
|---|---|---|---|---|
| 6 | `lib/core/data/services/data_export_service.dart` 535 行 | 11 处 _isoUtc + 7+ exporter/importer 混 | 拆 `exporters/{check_in,medication,assessment}_exporter.dart` + `importers/json_importer.dart` | round 30 spen #5 提，**未修** |
| 7 | `lib/core/data/services/notification_service.dart` 573 行 | 已 facade 4 子服务，但公开 API 6+ 方法仍散在 | 进一步细分 `PushDispatcher` / `Scheduler` / `Renderer` | round 30 spen #3 提，**部分修**（已 facade） |
| 8 | `lib/presentation/pages/medication/medication_calendar_page.dart` 414 行 | 加载 + grid + day detail sheet 混 | 拆 `widgets/calendar_grid.dart` / `widgets/day_detail_sheet.dart` | round 30 spen #6 提，**未修** |
| 9 | `lib/presentation/pages/medication/refill_manage_page.dart` 343 行 | list + add dialog + status indicator 混 | 拆 `widgets/refill_list.dart` / `widgets/add_refill_dialog.dart` | **新发现** |

### 不该拆的（过 engineering）

- `lib/core/theme/app_tokens.dart` 525 行 — 集中 token 是 emil 设计原则正确决策，**不能拆**（round 30 spen 明确说）
- `lib/core/routing/app_router.dart` 398 行 — 1 文件管所有路由是 go_router 实践
- `lib/main.dart` 345 行 — 启动顺序 + SQLCipher + 通知 init，1 文件管完
- `lib/core/data/database/app_database.dart` 483 行 — 1 DB 1 文件是 Drift 实践
- `lib/presentation/pages/setup/setup_page.dart` 418 行 — 4 step orchestrator，1 文件清晰

---

## 4. 高内聚低耦合 评估

### 4.1 跨边界耦合现状（优秀）

| 维度 | 现状 | 守门机制 | 评价 |
|---|---|---|---|
| presentation/page 跨 feature import | 0 violation | `check_cross_feature.py --ci` | 优秀 |
| presentation 跨层访问 data | `core_providers.dart` 集中器暴露 domain 接口，**不暴露 impl** | 人工 review | 优秀 |
| domain 引用 flutter / drift | 0 violation | `check_all.dart` 100% 纯度 | 优秀 |
| data 引用 presentation | 0 violation | `check_all.dart` | 优秀 |
| shared 跨层使用 | formatters / json_codec / mood_visual / domain_value 4 文件 2+ 层用 | `check_all.dart` 一致性 | OK |
| widget 跨 feature 复用 | 5 通用 widget 抽好（loading_skeleton / page_scaffold / press_feedback / secondary_button / app_snack_bar） | 人工 review | 优秀 |
| service facade 模式 | `notification_service.dart` facade 4 子服务 | 架构决策记录 | 优秀 |
| schema 集中 | 1 个 `app_database.dart` 管 13 张表 + 12 个 migration | Drift 实践 | 优秀 |

**结论**：项目在"跨边界耦合"维度已经做到 100% 守门 + 0 violation。**剩余问题全是"单文件过大"的拆分粒度**，不是"跨边界耦合"。

### 4.2 内部模块高内聚评估

| 维度 | 现状 | 评价 | 改进方向 |
|---|---|---|---|
| mood_dialog 4 维评分内聚 | 1 个文件 4 维评分 row + 标签 + tag filter + saving state | **内聚不够**（4 件事） | 拆 rating_row + tag_filter + dialog 主体 |
| settings_page 6 section 内聚 | 1 个文件 6 section | **内聚不够** | 拆 6 个 section widget |
| notification_service 4 子服务 | facade + 4 sub-service（SnoozeManager / ReminderService / AssessmentReminderService / SafetyWatchService） | **内聚优秀** | 维持 |
| care_engine 4 strategy | 已 facade 4 strategy（v0.23 round 41 修） | **内聚优秀** | 维持 |
| reminders_hub 5 card | v0.22 round 35 拆 5 card | **内聚优秀** | 维持 |
| trend_charts 4 widget | 1 文件 4 widget | **内聚不够** | 拆 3-4 文件 |

### 4.3 跨 feature 数据流（隐私边界）

| 模块 | 进什么 | 不进什么 | 评价 |
|---|---|---|---|
| 树洞（vent） | 无 | 趋势 / 评估 / CareEngine / SafetyWatch / 通知 / 关怀 | 优秀 |
| 情绪日记（mood） | mood-specific reports | 通知（v0.15 之后可加） | 优秀 |
| 心理评估（assessment） | 评估历史趋势 | 失联通知（除非 CrisisSignal） | 优秀 |
| 打卡（check-in） | streak / 趋势 | 评估 | 优秀 |
| 失联通知（SafetyWatch） | 通知家人 | 内部 detail（仅 SMS） | 优秀 |

**结论**：隐私边界已 100% 守住，0 越界。

---

## 5. 顶层重构建议（按 round 30 报告 + 12 round 实际进展综合）

### 5.1 应该做的（按 ROI 排序）

1. **presentation god class 拆分**（P1，5-7h）— mood_dialog 797 / settings_page 688 / assessment_history_page 624 / trend_charts 595 / edit_medication_dialog 397
2. **riverpod_generator 引入**（A 选项，1 day）— 24 provider boilerplate 减 30%
3. **privacy 子包化**（B 选项，4-6h）— PIPL 合规审计支撑
4. **push 通道架构化**（C 选项，分 5 round / 80-120h）— 国产 ROM P0 根因解决
5. **widget library 子目录化**（E 选项，2-3h）— 跟 #1 同一个 round

### 5.2 锦上添花（看 v0.24 业务）

- Freezed union types（G 选项，1 day）
- application/ 中间层（D 选项，8-12h）

### 5.3 不要做的

- Drift → Isar 迁移（F 选项，ROI 极低）
- BLoC 替代 Riverpod（H 选项，反向 ROI）
- 拆 `app_tokens.dart`（过 engineering）

---

## 6. 决策框架（什么时候该重构？什么时候不该？）

基于 round 30 + 12 round 实际进展 + 本审视，给项目一个"该不该重构"决策树：

1. **如果文件 > 500 行** → 拆（看 round 34-35 模式）
2. **如果模式重复 3+ 处** → 抽通用 widget（看 round 34）
3. **如果跨 feature import 跨 pages/** → 不允许（`check_cross_feature.py` 守门）
4. **如果 domain 引用 flutter / drift** → 不允许（`check_all.dart` 守门）
5. **如果 service 公开 API > 10 个** → 考虑 facade 模式（看 `notification_service` 4 子服务）
6. **如果 P0 必修 >= 3 项** → 一个 round 集中清理（看 v0.23 round 38）
7. **如果 P1 应修 >= 5 项** → 下一个 round 处理（看 v0.23 round 39）
8. **如果 P2 可修 >= 10 项** → 一个 round 集中清理（看 v0.23 round 40）
9. **如果新 feature / 重大架构** → brainstorming + writing-plans 流程（sp-zh T-23 强规则）

---

## 7. 关键观察

1. **架构是项目最稳的资产**：4 层 + 5 umbrella + 跨 feature 守门 + 隐私边界 100%。剩余问题全是"单文件过大"（拆分粒度），不是"跨边界耦合"。
2. **12 round 集中清理效果显著**：v0.22 round 30→37 + v0.23 round 38→42 共 12 round，已修了 round 30 报告里大部分 P0 / 部分 P1 / 部分 P2。3 份 worker 报告回来后能看到具体修了哪些、残留哪些。
3. **P0 必修 = 国产 ROM 通知 + 法律文档**：这两个 P0 跨多个 round 持续存在，是项目"上线前必杀点"。
4. **subagent 友好度 = 60%**：大量 P1 / P2 工作（widget test / DateTime race / catch migration / god class 拆分）天然适合 subagent-driven-development 拆 3-5 个并行 worker。当前还是单 agent 串行。
5. **CI 缺 release build**：`flutter build apk` / `flutter build web` 不在 CI，是 verification-before-completion 经典违反。`flutter test` 过 ≠ 编译过。
6. **CHANGELOG + tag 流程 12 round 没补**：v0.18-0.23 全无 git tag，上架时不可追溯。`GIT_WORKFLOW.md` 写的"每个 minor version 打 tag"失效。
7. **精神心理 App 的"伦理 + 法律 + 监管"三角合规风险**：PHQ-9 抑郁 + GAD-7 焦虑 + 失联通知 = 似构成 NMPA 二类医疗器械？需法务确认（v0.23+ 立项时 3 方联合 review）。

---

**草稿完成**。3 个 worker 报告回来后，我会：
1. 把 worker 增量发现 merge 进本文件 §3 / §4 / §5
2. 把 worker 报告里的 P0/P1/P2/P3 全部收录到整合总览表（`docs/reviews/v0.23/_integration_overview_round42.md`）
3. 标注每个问题的 skill 来源 / 架构还是底层 / 修复难度 / 优先级

> **owner 立场**：项目 v0.23 round 42 整体**架构健康度 9/10**。**"高内聚低耦合"是项目最强项**（4 层 + 5 umbrella + 跨 feature 守门 + facade 模式）；**"单文件过大"是项目最大弱点**（5 个 > 500 行 god class）。**P0 必修仍是国产 ROM 通知 + 法律文档**。
