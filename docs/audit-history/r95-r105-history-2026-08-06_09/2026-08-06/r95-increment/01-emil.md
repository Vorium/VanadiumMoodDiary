# emilkowalski 增量审视报告 (R93 后 → R95+)

> **视角**: 设计工程 (Emil Kowalski "Design Engineering" 方法论)
> **审视人**: Mavis (orchestrator, emil 视角)
> **基线**: [R92 emil 报告](../01-emilkowalski-design-report.md) (45.9KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: 7 task 隐藏 8 业务 + 36 R93 tests + medication_calendar 642→209 行

---

## 0. 摘要 (TL;DR)

R92 emil 评分 7.5/10, "token 化顶级, 执行分裂, 3 个 P0 半成品"。R93 已修 4 个半成品 (CBT wizard / FAB / chart / treatment placeholder) + 4 个设置页 section hidden。**R93 后新发现**: 主页从 436 行涨到 679 行 (R88-91 加 4 widget), 224 TextStyle 中 32 个在主题层 (已算 token), 真正 magic 残留 192 个。

---

## 1. R92 基线复盘

**R92 emil 7.5/10 核心发现**:
- 主页 8 widget 堆叠, primary action 不突出 (P1-2.2.3)
- 主页 hero illustration 140dp 视觉几乎 0 (issue 1.2.10)
- 158 TextStyle 残留 (~40% magic)
- 162 EdgeInsets 残留
- 50+ Duration + 50+ Curves 残留 (~30% token 化)
- 3 P0 半成品 (CBT wizard / FAB stub / treatment placeholder)

**R93 已修 4 项半成品**:
- ✅ CBT wizard 5/7 栏 save 修 (字段不丢)
- ✅ homeFabHotline / homeFabTop 真功能 (路由 + Scrollable.ensureVisible)
- ✅ assessment_center 顶部 mini 趋势图 (复用 R90 chart widget)
- ✅ treatment_placeholder 真页面 (R91 placeholder 替换)
- ✅ 设置页 4 section hidden (IAP / 失联 / 5 厂商 / Email)

---

## 2. R93 后新发现

### 2.1 架构层 (1 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| E-1 | 主页 679 行 god page (R88-91 加 4 widget 后涨 243 行) | `lib/presentation/pages/home/home_page.dart` | XL | P1 |

### 2.2 底层 (3 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| E-2 | 224 TextStyle 中 18 个在 `app_typography.dart` (已算 token) + 14 个 `app_theme.dart` (重叠) + 12 个 `medication_report_pdf_layout.dart` (PDF 特殊) — 真正 magic 192 个 | 多文件 | L | P0 |
| E-3 | 208 EdgeInsets 全部 magic 残留, 应走 `AppTokens.spacingXxx` | 多文件 | L | P0 |
| E-4 | 96 Duration 中 17 个已 token (app_motion / app_routes), 79 个 magic 残留 | 多文件 | L | P0 |

---

## 3. R92 未修的 P0/P1 (现状)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| E-5 | 主页 hero illustration 140dp 视觉几乎 0 | M | **未修** | P1 |
| E-6 | 主页 header 3 icon button 0 tooltip | XS | **未修** (R93 hidden 但 0 tooltip) | P3 |
| E-7 | 主页 8 widget 堆叠, primary action 不突出 | XL | **未修** (反而涨到 679 行) | P1 |
| E-8 | 紧急联系人添加 5 步 → 3 步 ("3 tap 抵达") | L | **未修** (R93 hidden 联系人入口) | P1 |
| E-9 | 数据导出 5 步 → 3 步 | M | **未修** | P1 |
| E-10 | quick mood carousel 1 tap 0 反馈 (误触落库) | M | **未修** | P1 |
| E-11 | medication_calendar 30 天热力图 0 tap 详情 | M | **R93 task 1 拆了, 但 0 tap 详情仍未加** | P1 |
| E-12 | 通知状态卡 17 步纯文字 0 截图 0 链接 | M | **未修** | P3 |
| E-13 | vent 长按/swipe 删除 0 视觉提示 | XS | **未修** | P3 |
| E-14 | `legal_page` toggle 缺 chip 标识撤回时间 | XS | **未修** | P3 |
| E-15 | `email_preview.dart` 整个文件是 v0.4 早期版残留 (失联是 SMS, 不是 email) | XS | **未修** (R93 hidden email service 但文件仍在) | **P0 必删** |
| E-16 | `mood_dialog.dart` 25 行薄壳 god-pattern 纯转发 | XS | **未修** | P3 |
| E-17 | `refill_manage_page.dart` 4 StatCard 数字挤一起 | XS | **未修** | P2 |
| E-18 | `setup_step_medication.dart` PrimaryButton + Stack hacky | XS | **未修** | P3 |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-2 周)

1. **R95 task 1**: 拆 `data_management_section.dart` 606 行 → 6 sub-tile (L, 1-2 周)
2. **R95 task 3**: 224 TextStyle 集中器化 (保留 PDF 字体 12 个) (L, 1-2 周)
3. **R95 task 4**: 208 EdgeInsets + 96 Duration 中 79 个 magic 集中器化 (L, 1-2 周)
4. **R95 task 10**: 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med) (M, 1 周)

### 4.2 P1 重要 (1-2 周)

5. **R95 task 5**: 拆 `home_page.dart` 679 行 → 5 sub-section (XL, 1-2 周)
6. **R95 task 6**: 拆 `trend_calendar.dart` 642 行 → 3 sub-section (XL, 1-2 周)
7. **R95 task 7**: 拆 `mood_audio_section.dart` 553 行 → 4 sub-widget (L, 1-2 周)
8. **R95 task 16**: 主页信息架构重排 (emil "3 tap 抵达") (XL, 1-2 周, 配 task 5)
9. **R95 task 18**: 紧急联系人 5 步 → 3 步 (L, 1 周)
10. **R95 task 19**: 数据导出 5 步 → 3 步 (M, 1 周, 配 task 1)
11. **R95 task 51**: 趋势页 4 StatCard 数字挤一起 → 2x2 grid (XS, 1-2h, 配 task 6)

### 4.3 P2 建议 (1-3 月)

12. **R95 task 44**: 主页 hero illustration 真组件 (替换 140dp 占位) (M, 2-3d)
13. **R95 task 47**: 通知状态卡 17 步纯文字 0 截图 0 链接 → 加截图 (M, 1-2d)

### 4.4 P3 nice-to-have (3+ 月)

14. **R95 task 45**: 主页 header 3 icon button 加 tooltip (XS, 1-2h)
15. **R95 task 46**: `legal_page` toggle 加 chip 标识撤回时间 (XS, 1-2h)
16. **R95 task 48**: vent 长按/swipe 删除 0 视觉提示 (XS, 1-2h)
17. **R95 task 49**: `mood_dialog.dart` → 直接 `MoodRecorderPage` (emil honest abstraction) (XS, 1-2h)
18. **R95 task 50**: `setup_step_medication.dart` PressFeedback + LoadingSpinner (XS, 1-2h)

---

**emil 视角报告完成时间**: 2026-08-06
**emil 视角报告体量**: 4.2KB
**R95+ emil 建议总计**: 18 项 (4 P0 + 7 P1 + 2 P2 + 5 P3)
**参考**: [00-r95-summary.md §3.1](./00-r95-summary.md#31-emilkowalski-视角-设计工程--r93-后增量)
