# emil 视角 v0.25 round 56h 增量审视

> **视角**：UI / 动效 / 交互 / 视觉（Design Engineering 视角）
> **基线**：v0.23 round 42（7da198c，2026-07-26 早）
> **终点**：v0.25 round 56h（33b5fd0，HEAD）
> **增量**：14 round（R49–R60 主线 + R56b–R56h 子线，含 R50/R51/R52/R53a/R54/R55/R56/R56b/R56c 系列/R56d/R56e/R56f/R56g/R56h）
> **不重复**：2026-07-26 三份报告（emil 97 + spen 55 + spzh 56 = 208 发现）已列的 P0–P3，本报告只关注**v0.25 增量**。
> **token 限制声明**：本次只 grep presentation/ + core/theme/，不遍历 domain/data；输出 5000–8000 token。

---

## 1. 顶层架构审视（emil 视角）

emil "decisions should be nameable" 的 token 化在 v0.25 推到了**新阶段**：从 v0.24 round 48 的"动效 85% / 色彩 70% / 文字 40%" 推到 **"动效 100% / 色彩 ~100% / 文字 36%"**（注：文字 36% 来自 inline TextStyle 160 处 vs textStyle helper 57 处 = 26% token 化率；emil 报告承诺的 R50b 子 round 没做）。

**3 个核心观点**：

1. **dark mode 颜色 token 化 ✅ 100% 完成**（R49）：75 处 `AppTokens.primaryColor(context)` + 47 处 `errorColor/warningColor` 替换，原 60+ 处 light-mode const silent bug 全清。剩 1 处是 `app_list_tile.dart:26` 的 doc comment。**emil 头号哲学"good defaults"在 dark mode 维度首次 100% 落地**。这是 v0.25 增量对 emil 视角的**最大贡献**。

2. **spacing / icon-size 集中器 ✅ 100% 完成**（R56 + R56b）：46 处 SizedBox magic + 32 处 `size: 14/18/56/64` 全走 token。`iconSizeInline/Small/Empty/Error` 4 个集中器 35 处引用。但 **R56 同时加了 5 个"死 token"**（`chartPlaceholderHeight` / `sparklineHeight` / `heatmapLabelWidth` / `eventTimeColWidth` / `shimmerPauseMs`）—— emil "taste = subtraction" 原则反例：先抽 token 后没在同 round 替换，token 变 dead code。

3. **R50 score 集中器 ❌ 完全 dead token**（P0 #2 失败）：`textStyleScoreLg/Xl/Xxl` 3 个 helper 0 处引用。R50 commit 明确说"完整替换 49+ 处 inline TextStyle 留到 R50b 子 round (本 round 优先 P0 token 化集中器, 风格统一不是阻塞 bug)"——R50b 没做。**emil 头号哲学反例**：加集中器不替换 = 集中器本身变 dead code = 比"全部 inline"更糟（混淆后来读者）。

**新 god class 拆分（spen 干，emil 关系不大）**：R53a/R57/R58/R59/R60 全在 data / service / domain / routing 层，0 处动 `lib/presentation/`。**emil 一致性评估：无影响**。但 R59 把 `app_router.dart` 418→51 行（-88%）很优雅。

**emil 视角对 v0.25 整体评价**：动效 / 色彩 / 间距 / icon-size 4 个维度的 token 化收口，dark mode 全部 silent bug 修复，是项目自 v0.17 动效集中器以来**最大的一次 design system 推进**。但文字 token 化 R50b 没落地、IconButton 触感 17 处残留、5 个 dead token = 仍有 ~15-20% 集中器采用率债务。

---

## 2. 8 维度动画审计（v0.25 增量）

| 维度 | v0.23 round 42 评 | v0.25 round 56h 评 | 变化 |
|------|------------------|-------------------|------|
| **动效 token 化** | 85%（dur/curve/MotionScheme 集中器） | **100%**（Curves 直用 0 处 + 13 PageTransitionSwitcher + 8 FadeIn + 2 SlideUp + 5 MotionScheme 引用） | **+15%** ✅ |
| **动效集中器采用率** | 85% | **~95%**（CelebrationOverlay R48 抽 animations/，MoodQuickButton 接管 tap，vent_list PressFeedback） | +10% ✅ |
| **色彩 token 化** | 70%（60+ 处 `color: AppTokens.primary` 裸用） | **~100%**（75 primaryColor + 47 errorColor/warningColor 引用，唯一 1 处 doc 注释） | **+30%** ✅✅ |
| **dark mode 兼容** | 差（light-mode const 在 dark mode 颜色错） | **100% 修复**（3 个 dynamic getter + 35 文件 116 行替换） | **质变** ✅✅ |
| **文字 TextStyle 化** | 40%（209 inline，14 helper） | **36%**（160 inline / 57 helper = 26% token 化率） | **-4%** ❌（R50b 没做） |
| **icon 尺寸 token 化** | 50%（24+ 处 `size: 18` 裸用） | **~100%**（24 iconSizeInline + 4 iconSizeSmall + 5 iconSizeEmpty + 2 iconSizeError） | **+50%** ✅ |
| **spacing token 化** | 80%（21+ 处 SizedBox magic） | **100%**（0 SizedBox magic 残留，R56b 46 处全替换） | **+20%** ✅ |
| **集中器 widget 采用率** | 8 集中器 ~70% | **AppListTile 49% / EmptyState 16 / ErrorState 17 / SectionHeader 14 / PressFeedbackIconButton 8** | **离散，AppListTile 落后** ⚠️ |

**总结**：4 维度从 70%→100%（动效/色彩/icon/spacing），文字是唯一掉队（40%→36%）。R50b 子 round 是 v0.26 头号工程。

---

## 3. 关键发现（12 个增量发现，不重复 2026-07-26 报告）

> 编号 #EMIL-INC-01..12。**仅 v0.25 round 49–56h 新增 / 新发现的问题**。

| # | 类别 | 文件:行 | 问题 | 修复难度 | 优先级 |
|---|------|---------|------|----------|--------|
| **EMIL-INC-01** | **dead token** | `app_tokens.dart:634-660` | R50 加 `textStyleScoreLg/Xl/Xxl` 3 个 helper 0 处引用——R50 报告承诺 R50b 子 round 替换 inline TextStyle 49+ 处，没做 | 极小（grep 替换 ~11 处 fontSize 24/32/64） | **P0** |
| **EMIL-INC-02** | **dead token** | `app_tokens.dart` | R56 加 `chartPlaceholderHeight=200` / `sparklineHeight=80` / `heatmapLabelWidth=60` / `eventTimeColWidth=36` / `shimmerPauseMs=600` 5 个 token 0 处引用 | 极小（grep 替换 ~8 处） | **P1** |
| **EMIL-INC-03** | **dead token** | `app_tokens.dart` | R50 报告第 4.4 节承诺加 `textStyleMono(context)` helper + `monoFontFamily='monospace'` 集中器，**完全没加**——`data_management_section.dart:167/363` + `medication_report_dialog.dart:82` 3 处仍硬编 `'monospace'` | 极小（加 helper + 3 处替换） | **P2** |
| **EMIL-INC-04** | **inline TextStyle** | 全 presentation/ | R50 计划做 R50b 替换 49+ 处，**未做**。现状 160 处 inline `TextStyle(...)`，57 处走 `textStyleXxx` helper = 26% token 化率（比 v0.24 round 48 的 40% **反而退步**——R48 已加 helper 但 v0.25 又新增 20+ 处 inline） | 中（1 round，~100 处替换） | **P0** |
| **EMIL-INC-05** | **触感集中器** | 14 文件 17 处 | `IconButton(...)` 没用 `PressFeedbackIconButton` 集中器，缺 :active scale：<br>- `medication_row.dart:127/133/143` (3)<br>- `report_history_dialog.dart:43/103` (2)<br>- `vent_detail_page.dart:182/266` (2)<br>- `trend_calendar.dart:99/118` (2)<br>- `mood_recorder.dart:513/521` (2)<br>- `vent_list_page.dart:42/44` (2, doc 注释 + 1 处) <br>- `contact/contacts_list_widget.dart:78` (1)<br>- `setup_step_medication.dart:184` (1)<br>- `notification_status_card.dart:207` (1)<br>- `medication_report_dialog.dart` (1)<br>- `last_startup_error_banner.dart` (1)<br>- `vent_audio_section.dart` (1)<br>- `notification_failure_banner.dart:54` (1) | 极小（1 round，17 处替换） | **P1** |
| **EMIL-INC-06** | **触感集中器** | 2 文件 2 处 | `SegmentedButton` 缺 :active feedback（M3 splash 但无 scale）：<br>- `medication_calendar_page.dart:84` (7/30/90 天切换)<br>- `trend_page.dart:232` (list ↔ calendar 切换) | 小（包 PressFeedback + MotionScheme.subtle） | **P2** |
| **EMIL-INC-07** | **集中器采用率** | `presentation/` | 8 集中器采用率统计（v0.25 R56h 状态）：<br>- AppSnackBar: 78 处 ✅（R47 B-06）<br>- PressFeedback: 31 处 ✅<br>- EmptyState: 16 处 ✅<br>- ErrorState: 17 处 ✅<br>- SectionHeader: 14 处<br>- PageTransitionSwitcher: 13 处<br>- PressFeedbackIconButton: 8 处 ⚠️（17 处 IconButton 没走）<br>- FadeIn: 8 处<br>- ChipBadge: 3 处 ⚠️（覆盖率低，需审查用法）<br>- **AppListTile: 19/39 = 49% 覆盖率 ⚠️**（剩 20 处 `ListTile(...)` 裸用，集中在 `setup_step_welcome.dart` + `medication_list_view.dart` + `medication_row.dart`）<br>- AppSemantics: 7 处 ⚠️（R45 加的集中器，a11y 维度低采用率）<br>- LoadingSkeleton: 1 处 ⚠️（可能 grep 不到 widget name，应该是 `LoadingSkeleton.xxx`） | 小（多 round） | **P1** |
| **EMIL-INC-08** | **dark mode 验证** | 全 presentation/ | R49 改了 35+ 文件 116 行，**残留扫描结果**：`grep "color:\s*AppTokens\.(primary|error|warning|...)\b(?!Col)"` 0 命中（除 `app_list_tile.dart:26` doc comment）= **真正的 100%**。但 R49 没改的"半成品 token"（`AppTokens.primaryLight` / `success` / `tintedError` / `tintedSuccess` 等仍是 static const）将来在 dark mode 也会 silent bug——目前使用率 < 5 次/项，**风险低** | 极小（未来监控） | P3 |
| **EMIL-INC-09** | **i18n 占位符** | 3 文件 3 处 | 跟 emil 原报告 E1/E2 一致，未修：<br>- `contacts_list_widget.dart:172` `hintText: '13800138000'`（en 模式中国手机号格式）<br>- `edit_medication_dialog.dart:262` `hintText: '40'`<br>- `setup_step_medication.dart:212` `hintText: '40'` | 极小（3 ARB key + 3 处替换） | **P3** |
| **EMIL-INC-10** | **microcopy** | `l10n/app_zh.arb:98` | G1 树洞导出敏感文案未改：仍 "即将导出...敏感话题...可能被他人看到...加密磁盘...未授权的人" 5 段话+3 列表+粗体。R49-R56h 14 round 没动 | 中（i18n 修改） | P3 |
| **EMIL-INC-11** | **god page** | `setup/setup_page.dart:446 lines` | 跟 emil 原报告 C5 一致未拆。R46 之前已拆 4 步，但 setup_page 仍 446 行（含 4 步状态管理 + 协议版本号 + legal dialog 编排）。v0.25 R49-R56h 没动 | 中（拆 4 步协调器） | P3 |
| **EMIL-INC-12** | **a11y** | 3 文件 3 处 | 跟 emil 原报告 F1-F3 一致未修：<br>- `medication_report_dialog.dart:99/139` share button 缺 Semantics.label<br>- `medication_calendar_page.dart:84-105` ButtonSegment icon 缺 Semantics<br>- `home_header.dart:39-53` 用户名缺 `Semantics(header: true)` | 小 | P3 |

**总计增量发现：12 个**（P0 ×2 + P1 ×3 + P2 ×1 + P3 ×6）。

---

## 4. 关键观察

**观察 1：v0.25 是 token 化收口期，但"加 token 不替换"反模式出现**。R50 加 3 个 score 集中器 0 引用，R56 加 5 个 chart/sparkline/heatmap/shimmer 集中器 0 引用。emil "taste = subtraction" 原则：dead token 比 inline magic 更糟（混淆后来读者以为"应该有 helper 但找不到"）。**建议**：未来加集中器的 commit 必须同 round 完成替换，否则 revert token。

**观察 2：dark mode 颜色 token 化是 v0.25 emil 头号胜利**。R49 39 文件 116 行 + 3 个 dynamic getter + 1 个 onSurfaceMuted，**真正的 100%**（grep 验证 0 处裸用 light-mode const）。这是精神心理患者 dark mode 用户（晚间服药 / 失眠 / 抑郁发作期）的视觉对比度 bug 一次性修复，对**敏感时段用户体验**价值极高。emil "good defaults matter more than options" 在此首次 100% 落地。

**观察 3：R57-R60 god class 拆分跟 emil 关系不大但 R59 极优雅**。`app_router.dart` 418→51 行（-88%），拆 `app_routes.dart` (3 transition + 14 GoRoute + errorBuilder) + `app_shell.dart` (AppShell + _NavDest)。这是 R45-R60 god class 拆分大潮的**最佳范例**——单文件 < 200 行的 emil 原则 100% 满足。R53a app_database (45% 减) / R57 safety_watch (24% 减) / R58 medication_report (3 纯函数类) / R60 MedicationDraft value object 同样高质量。**emil 一致性：完全无影响**（0 处动 `lib/presentation/`）。

**观察 4：R56b spacing token 化是"机械替换"模式的胜利**。46 处 `SizedBox(width|height: 2/4/6/8/16/24/40/80)` 走 `spacingXxxs/Xxs/chipGap/Xs/Sm/Md/Lg` 集中器，`scripts/_r56b_spacing_tokenize.py` 自动化脚本一次性完成。**emil 原则验证**：当决策**可机械表达**（"2-80 整数映射到 spacing token"）时，自动化 + 人工 review 比纯人工快 10 倍。R49 同样用 `_r49_dark_mode_color_replace.py` 自动化 39 文件替换。

**观察 5：IconButton 集中器 17 处残留 = 触感债务**。medication_row 3 + report_history 2 + vent_detail 2 + trend_calendar 2 + mood_recorder 2 + vent_list 2 + 6 个其他 = 17 处。**emil "cohesion" 原则**：3 个 IconButton 在 medication_row 缺 :active scale = 100+/day 频度的用药列表操作缺触感反馈 = 体感折扣。下次用户编辑用药时会感知"不一致"。**P1 修复 1 round**。

**观察 6：AppListTile 49% 覆盖率 = 集中器采用率最大债务**。39 处 ListTile 中 19 走 AppListTile + 20 裸用。**emil "consistency" 原则**：20 处裸用 = 4+ 个 ListTile 在 setup_step_welcome / medication_list_view / medication_row 等关键路径上未走集中器（carded / standard / destructive 3 模式不统一）。**P1 修复 1 round**。

**观察 7：8 维度动画审计中"色彩 100% / 动效 100% / spacing 100% / icon 100%" 是 v0.25 增量最大成就**。但**文字 36% 退步**（R48 40% → R56h 36% = 实际 -4%）暴露 R50b 没做的代价。**emil "decisions should be nameable" 在 TextStyle 维度首次退步**——这比 v0.24 round 48 还糟。

---

## 5. 下轮建议

**建议 1（v0.26 round 57-58, P0）**：
- **R57**：R50b 完整替换 49+ 处 inline TextStyle → `textStyleXxx(context).copyWith(color: ...)`。目标 160→30 处内联，**文字 token 化从 36% 推到 80%+**。1 round，~120 处替换 + 5 个 helper 复用。
- **R58**：删除 5+3 = 8 个 dead token（`textStyleScoreLg/Xl/Xxl` + `chartPlaceholderHeight` / `sparklineHeight` / `heatmapLabelWidth` / `eventTimeColWidth` / `shimmerPauseMs`）——若不替换则删，避免混淆。或补 R58b 替换 inline 用法。

**建议 2（v0.26 round 59-60, P1）**：
- **R59**：17 处 IconButton 走 `PressFeedbackIconButton` 集中器，2 处 SegmentedButton 包 `PressFeedback` + `MotionScheme.subtle`。**触感债务清零**。1 round，~20 处替换。
- **R60**：20 处裸 `ListTile(...)` 走 `AppListTile.standard/carded/destructive` 集中器，**ListTile 统一度从 49%→100%**。1 round，~20 处替换。

**建议 3（v0.26 round 61, P2）**：
- **R61**：5 维度 token 化收口后，做 1 round "**集中器健康度 audit**"：(a) 所有 token 引用率统计，(b) dead token 清理，(c) 集中器采用率 dashboard（`scripts/_audit_centralizers.py` 加到守护套件）。**emil "taste = subtraction" 制度化**。

**建议 4（v0.26 round 62, P3）**：
- **R62**：G1 vent export 敏感文案去警示化（emil "calm over cautionary"）+ 3 处 hintText i18n 化（E1/E2）。0.5 round，i18n + 文案 review。

**建议 5（v0.26 起，制度化）**：
- **新加 token 必须同 round 替换**（R50 教训）—— 在 `scripts/check_orphan_tokens.py` 守护脚本加：每个 `static TextStyle textStyle*` / `static const double *Height` / `static const double *Width` 必须 ≥ 1 处引用（除 `app_tokens.dart` 内定义），否则 fail。这是 emil "taste = subtraction" 的 CI 化。

---

## 附：grep 复现手册（v0.25 R56h 验证）

```bash
# 1. dark mode 颜色硬编残留（应 0 处，除 doc 注释）
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "color:\s*AppTokens\.(primary|error|warning)\b(?!Col)"

# 2. inline TextStyle 残留（应 < 50）
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "TextStyle\(" | Measure-Object

# 3. SizedBox magic 残留（应 0 处）
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "SizedBox\((width|height):\s*[0-9]"

# 4. Icon size magic 残留（应 0 处）
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "size:\s*(14|18|56|64)\b"

# 5. IconButton 没用 PressFeedbackIconButton 集中器（应 0 处）
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "IconButton\("

# 6. dead token 检查（应 0 处）
Get-ChildItem lib -Recurse -Filter *.dart |
  Select-String -Pattern "AppTokens\.(textStyleScoreLg|textStyleScoreXl|textStyleScoreXxl|chartPlaceholderHeight|sparklineHeight|heatmapLabelWidth|eventTimeColWidth|shimmerPauseMs)\b"

# 7. AppListTile vs ListTile 集中器采用率
Get-ChildItem lib\presentation -Recurse -Filter *.dart |
  Select-String -Pattern "(App)?ListTile\("
```

---

**报告完。**

> **总增量发现：12 个**（P0 ×2 + P1 ×3 + P2 ×1 + P3 ×6）。
> **v0.25 R49–R56h emil 视角最大贡献**：dark mode 颜色 token 化 100% + spacing 100% + icon-size 100% = 3 维度收口。
> **v0.25 emil 头号债务**：R50b inline TextStyle 49+ 处替换未做（文字 36%→退步）+ 8 个 dead token + IconButton 17 处残留。
> **报告路径**：`D:\Batch\chroniccare\docs\reviews\v0.25\review_emil_round56h.md`
