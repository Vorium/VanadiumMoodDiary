# R95 sub-spec 5 task 3-4 token 残留 — Audit 报告

> **审计日期**: 2026-08-07
> **审计模式**: R95 stale audit lock-in 模式 (跟 task 8/9/25/26 一致)
> **基线**: R95 报告 §6.1-6.3 估 `224 + 208 + 96`
> **实测**: `220 + 205 + 95` (R95 数字 1-3 差异, grep 模式差异, 实质一致)

---

## 1. 全局 grep 数字 (R95 数字验证)

| 类型 | R95 报 | 实测 (2026-08-07) | 差异 | 备注 |
|------|--------|-------------------|------|------|
| `TextStyle(` 全文 | 224 | **220** | -4 | R95 模式可能含 `TextStyle?` 类型注解 |
| `EdgeInsets.` 全文 | 208 | **205** | -3 | 差异极小, 模式相同 |
| `Duration(` 全文 | 96 | **95** | -1 | 实质一致 |
| `Curves.` 全文 | 9 | **9** | 0 | **0 漂移** ✅ |

**结论**: R95 数字准确, "低估 16%" 评估也正确 (R92 估 420 实际 488)。

---

## 2. 扣除集中器自身 (算"已 token")

| 类型 | 总数 | 集中器自身 | 业务真 magic |
|------|------|------------|--------------|
| `TextStyle(` | 220 | 44 (app_typography 18 + app_theme 14 + medication_report_pdf 12) | **176** |
| `EdgeInsets.` | 205 | 12 (medication_report_pdf) | **193** |
| `Duration(` | 95 | 21 (app_motion 11 + app_routes 6 + app_spacing 4) | **74** |
| `Curves.` | 9 | 9 (app_motion) | **0** ✅ |

**业务真 magic 总数**: 176 + 193 + 74 = **443 处**

---

## 3. 真 magic 残留按文件 Top 20

### 3.1 TextStyle 真 magic 残留 (业务)

| # | 文件 | 数量 | 备注 |
|---|------|------|------|
| 1 | `medication/widgets/edit_medication_dialog.dart` | 7 | 全部半 token (用 AppTokens.fontSize + AppTokens.color), 应改 textStyleXxx |
| 2 | `settings/legal_page.dart` | 6 | 多数半 token, 有 literal |
| 3 | `setup/setup_step_welcome.dart` | 6 | 含 1-2 真 magic literal |
| 4 | `assessment/assessment_widgets.dart` | 6 | 多数半 token |
| 5 | `vent/vent_detail_page.dart` | 6 | 含 literal |
| 6 | `setup/setup_step_medication.dart` | 5 | 半 token |
| 7 | `widgets/section_header.dart` | 5 | 通用 widget, 应优先 token 化 |
| 8 | `settings/reminders_hub_page.dart` | 5 | 半 token |
| 9 | `medication/today_med_schedule.dart` | 4 | 半 token |
| 10 | `setup/setup_page.dart` | 4 | 半 token |
| 11 | `main.dart` | 4 | 含 system overlay style (M3 ThemeData) |
| 12 | `setup/setup_step_done.dart` | 4 | 半 token |
| 13 | `home/widgets/hero_illustration.dart` | 4 | **含 literal fontSize (4 个)** ⚠️ |
| 14 | `settings/widgets/report_history_dialog.dart` | 4 | 半 token |
| 15 | `settings/widgets/notification_status_card.dart` | 4 | 半 token |
| 16 | `assessment/widgets/assessment_reminder_section.dart` | 4 | 半 token |
| 17 | `settings/settings_page.dart` | 4 | 半 token |

**真 magic 分类**:
- **Literal fontSize: N (数字)**: 11 (PDF) + 4 (hero_illustration) + 3 (cbt PDF) + 3 (app_typography) + 2 (assessment_unavailable) + 4 个单点 = **约 25 处真 literal magic**
- **半 token (AppTokens.fontSizeX + AppTokens.color)**: 其余 ~150 处可优化成 textStyleXxx 集中器

### 3.2 EdgeInsets 真 magic 残留 (业务 Top 15)

| # | 文件 | 数量 | 主要模式 |
|---|------|------|----------|
| 1 | `trend/widgets/trend_day_detail_card.dart` | 7 | 多种 (all/symmetric/only) |
| 2 | `daily_tracking/widgets/social_rhythm_widgets.dart` | 5 | all + symmetric |
| 3 | `medication/refill_manage_page.dart` | 5 | all + only |
| 4 | `settings/legal_page.dart` | 5 | all + symmetric |
| 5 | `daily_tracking/widgets/sleep_widgets.dart` | 5 | all + symmetric |
| 6 | `mood/widgets/cbt_wizard.dart` | 5 | all + only |
| 7 | `assessment/widgets/assessment_reminder_section.dart` | 4 | all + symmetric |
| 8 | `assessment/widgets/assessment_history_list.dart` | 4 | all + only |
| 9 | `settings/reminders_hub_page.dart` | 4 | all + symmetric |
| 10 | `medication/medication_calendar_page.dart` | 4 | symmetric + only |
| 11 | `medication/today_med_schedule.dart` | 4 | all + symmetric |
| 12 | `assessment/widgets/assessment_result_panel.dart` | 4 | all + only |
| 13 | `settings/widgets/reminder_cards.dart` | 4 | all + symmetric |
| 14 | `assessment/assessment_widgets.dart` | 4 | all + only |
| 15 | `settings/widgets/data_management_section/widgets/export_dialog.dart` | 4 | all + symmetric |

**主要 magic 模式**:
- `EdgeInsets.all(8)` (占大头) → 应有 `AppTokens.edgeInsetsXs` 静态 const
- `EdgeInsets.all(16)` → `AppTokens.edgeInsetsSm`
- `EdgeInsets.all(24)` → `AppTokens.edgeInsetsMd`
- `EdgeInsets.symmetric(horizontal: 16, vertical: 8)` → 多组合, 需 additive helper

### 3.3 Duration 真 magic 残留 (业务 Top 10)

| # | 文件 | 数量 | 备注 |
|---|------|------|------|
| 1 | `medication/widgets/medication_calendar_grid.dart` | 4 | 业务日历网格 |
| 2 | `widgets/check_in_button.dart` | 3 | 打卡按钮 |
| 3 | `domain/logic/trend_calculator.dart` | 3 | 业务逻辑 |
| 4 | `home/widgets/home_fab_toolbar.dart` | 3 | 主页 fab |
| 5 | `medication/widgets/medications_list_widget.dart` | 3 | 用药列表 |
| 6 | `domain/logic/care_strategies.dart` | 3 | 业务逻辑 |
| 7 | `widgets/loading_skeleton.dart` | 3 | 通用 widget |
| 8 | `vent/vent_list_page.dart` | 3 | 树洞列表 |
| 9 | `core/data/services/reminder_dispatcher.dart` | 3 | 提醒派发 |
| 10 | 其他 8 个文件 | 2-3 | 散落 |

**主要 magic 模式**:
- `Duration(milliseconds: 200)` → `AppMotion.durFast` ✅
- `Duration(milliseconds: 300)` → `AppMotion.durNormal` ✅
- `Duration(milliseconds: 500)` → `AppMotion.durSlow` ✅
- `Duration(seconds: 2/3/4)` → `AppMotion.snackBarDurationShort/Medium/Long` ✅

---

## 4. 修真策略 (stale audit 模式)

### 4.1 修真原则

1. **完美等价替换**: color + fontSize 都对应集中器 → 改 textStyleXxx
2. **半 token 优化**: 现是 `TextStyle(fontSize: AppTokens.fontSizeCaption, color: AppTokens.textHintColor(c))` → 改 `AppTokens.textStyleCaptionHint(c)` (有现成集中器)
3. **加 helper 后批量改**:
   - 加 `AppSpacing.edgeInsetsAll(Spacing.X)` 5 个静态 const (让 facade `AppTokens.edgeInsetsXs/Sm/Md/Lg/Xl`)
   - 改 `EdgeInsets.all(8/16/24/40/80)` 全部
4. **保留 (不动)**:
   - `medication_report_pdf_layout.dart` 12 + 12 (PDF 字体特殊)
   - `app_typography.dart` 18 (集中器自身)
   - `app_theme.dart` 14 (ThemeData.copyWith 内嵌, 部分集中器重叠)
   - `app_motion.dart` 11 (集中器自身)
   - `app_routes.dart` 6 (集中器自身)
   - `app_spacing.dart` 4 (集中器自身)
5. **不强行改**:
   - `EdgeInsets.symmetric/only/fromLTRB` 复杂组合 → 不加 wrapper 避免 token 膨胀
   - Color 跟集中器不对应 (如 textStyleLabel + primaryColor) → 保留半 token, 改 textStyleXxx 反而破坏视觉
   - `const TextStyle(...)` (内嵌 const) → 直接换 AppTokens.fontSize 即可 (const TextStyle(const 字段) 仍 OK)

### 4.2 实际修量估计

| 类型 | 真 magic 业务数 | 修法 | 估可修 |
|------|----------------|------|--------|
| TextStyle 半 token | ~150 | 改 textStyleXxx | **80-100 处** |
| TextStyle literal fontSize | ~25 | 加 fontSize token / 用现有 | **15-20 处** |
| EdgeInsets.all() | ~120 | 加 edgeInsetsXxx helper 后改 | **80-100 处** |
| EdgeInsets.symmetric/only/fromLTRB | ~70 | 保留 (避免 token 膨胀) | 0 (保留) |
| Duration milliseconds: N | ~50 | 改 AppMotion.durXxx | **30-40 处** |
| Duration seconds: N | ~24 | 改 AppMotion.snackBarDuration | **15-20 处** |

**估总修**: 220-280 处真 magic 残留 (保守估 200+)

---

## 5. 守门员要求

修真后必保:
1. `flutter analyze` 0 error
2. `flutter test` 全过 (1780 baseline + 估 30+ lock-in test)
3. `dart scripts/check_all.dart` 4 层架构纯度
4. 16 .py 守门员全绿
5. `medication_report_pdf_layout.dart` 12+12 保留 (PDF 特殊)
6. 集中器自身不动 (app_typography 18 / app_theme 14 / app_motion 11 / app_routes 6 / app_spacing 4)

---

## 6. stale audit 风险评估

R95 报告数字准确 (差 1-3 是 grep 模式差异), 无低估。stale audit 模式处理:
- **加 lock-in test** (估 +30) 验证 50+ 真 magic 残留修后改用 `AppTokens.xxx` 引用
- 验证 PDF 特殊 + 集中器自身保留
- 修真后 grep 验 `TextStyle(` 总数从 220 减到估 100 (业务 50-100 处), EdgeInsets 从 205 减到估 100, Duration 从 95 减到估 50
