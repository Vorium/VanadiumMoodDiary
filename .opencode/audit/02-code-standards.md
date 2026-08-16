# 02-code-standards.md — Flutter 代码规范审计 (flutter-audit 视角)

> 审计时间: 2026-08-16 · 基线: v1.1.0+149, R113 修复战役后 working tree (未 commit)
> 依据: `.opencode/standards/flutter-code.md` + `.opencode/standards/architecture.md` + 项目 AGENTS.md
> 审计方式: READ-ONLY 静态扫描 + 命令实测, 零代码修改

## 实测复验清单 (全部命令实跑)

| 门禁 | 实测结果 | 与声明对比 |
|---|---|---|
| `flutter analyze` | **0 error / 0 warning / 266 info** | ✅ 声明 263 info → 实为 266 (lib 16 / test 250) |
| `dart scripts/check_all.dart` | 纯度 ✅ + 一致性 ✅ | ✅ 属实 |
| `flutter test` | **2407 pass / 0 fail / 1 skip** | ✅ 与声明一致 |
| `dart format --output=none --set-exit-if-changed lib test` | 770 文件 0 changed, exit 0 | ✅ 属实 |
| `python scripts/check_coverage.py` | PASS (18 gatekeeper 阈值) | ✅ lcov.info 存在 |
| `check_strings_hardcoded.py` | OK — 规则1=28 处中文 canonical (R57 override 配对合法) / inline=0 / domain=0 | ✅ 属实 |
| `check_widget_dispose.py` | 0 资源泄漏风险 | ✅ 属实 |
| `check_cross_feature.py --ci` | 152 files, 0 violations | ✅ 属实 |
| `check_datetime_race.py` + `check_datetime_race2.py` | 0 真可疑 race (均 exit 0) | ✅ 属实 |
| `check_no_hardcoded_utc.py` | 0 硬编码时区 | ✅ 属实 |
| `check_pii_in_title.py` | exit 0 | ✅ 属实 |
| `check_apple_health_claim / check_usecase_layer / check_legal_consent / check_review_information_todo / check_arb_keys / check_orphan_arb_keys / check_changelog` | 全部 exit 0 | ✅ 属实 |
| go_router 集中度 | 0 `MaterialPageRoute` / 0 `Navigator.push` / 0 `pushNamed` | ✅ 全走 context.push/pop |
| Riverpod 统一 | 0 GetX / Bloc / Provider 包混用 | ✅ |
| 状态色作文字色 | 0 处 `color: AppColors.success/error/warning` 裸用; fgOn* 4 token 就位并被使用 | ✅ |
| 硬编码色值 | lib/ 0 处 `Color(0x` (token 文件外); 0 处 `Colors.red/green...` (仅 PDF 层 `PdfColors.*` 合理豁免) | ✅ |
| raw IconButton | lib/ 0 处 (41 匹配全为 `PressFeedbackIconButton(` 或注释) | ✅ |
| 废弃 API | 0 withOpacity / FlatButton / RaisedButton | ✅ |
| spring.dart 死代码 | 已有真 caller (check_in_button.dart:268 `Spring.standard.toSimulation`) | ✅ 已闭环 |
| const/final 纪律 | strict-casts + strict-inference + strict-raw-types + prefer_const* 全开, 0 warning | ✅ |
| R113 拆分 claim | export_import_pipeline 934L → facade + 5 文件; setup 页已出 ≥400L 榜 | ✅ 属实 |

## 分析统计

- lib/ 428 文件 ~90.5K LOC (含 8.6K l10n 生成 + 8.8K drift 生成); test/ 321 文件
- analyze info 分布: lib 16 (15 trailing comma + 1 dangling doc) / test 250 (182 集中于 scale_strings_arb_lock_in_round95_test.dart 历史锁库文件 + R113 新增 worry 测试 40 条)
- god class ≥400L: **20 文件** (详见 F-02); build >80 行: **39 文件**, 其中 11 个 >150 行 (F-03)
- dispose / race / PII / i18n / 架构纯度: 全绿

## 发现清单

### F-01 [P2 · 重大 · 维度3性能 · 类型:底层 · 难度:中] 长列表懒加载回归 (2 处)

R112 ALS 化把懒加载列表改成了 eager 构建:

- `lib/presentation/pages/mood_list/mood_list_page.dart:151-171` — `ListView(children: [AppleListSection(children: [for (final entry in entries) MoodListItem(...)])])`。注释 (line 148) 自证此前是 `ListView.builder`, R112 改 AppleListSection 后退化为全量构建。
- `lib/presentation/pages/vent/vent_list_page.dart:286-341` — 同样模式, `ListView(children: [AppleListSection(children: [for (var i...) FadeIn(Dismissible(...))])])`。注释 (line 283) 自证此前是 `ListView.separated`。

**影响**: 情绪日记/树洞是高频记录功能, 年积累 1000+ 条时全部 widget 一次性构建 + 无 viewport 回收, 首帧与滚动帧率劣化; 树洞每条还叠 FadeIn + Dismissible。
**规范条款**: flutter-code.md「大列表 ListView.builder; 列表项 const」。
**建议**: 在 `AppleListSection` 内部加 lazy 变体 (shrinkWrap 列表 + builder), 或列表外层恢复 builder 按 section 分片; 迁移后加 500 条目 widget 测试锁帧。

### F-02 [P2 · 重大 · 维度2架构 · 类型:架构 · 难度:中] god class ≥400L 仍 20 个

`find lib -name "*.dart" | xargs wc -l | sort -rn` (排除 .g.dart + l10n 生成):

| 文件 | 行数 | 判定 |
|---|---|---|
| `core/data/services/export/import_entities.dart` | 664 | **真 god class** (R113 wave 5 拆出后最大手写文件, AGENTS R114 已记"可视需再拆 _importDailyTracking") |
| `presentation/pages/vent/vent_list_page.dart` | 645 | 页面大 (含 build 215 行) |
| `presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | 612 | 真 god class |
| `presentation/pages/mood_list/mood_trend_page.dart` | 609 | 页面大 |
| `presentation/widgets/audio_lifecycle.dart` | 605 | **mixin god class** (4 抽象方法 + 状态机, 单一职责但 605 行) |
| `core/data/database/app_database.dart` | 564 | 基础设施, 豁免 |
| `presentation/pages/settings/legal_page.dart` | 555 | 页面大 (含 3 份法律文书) |
| `presentation/pages/vent/vent_compose_page.dart` | 520 | 页面大 |
| `core/theme/app_colors.dart` | 519 | 纯 token, 豁免 |
| `presentation/pages/settings/widgets/notification_status_card.dart` | 491 | 子组件 god class |
| `presentation/pages/mood/widgets/mood_recorder_page.dart` | 476 | 页面大 |
| `presentation/pages/vent/vent_detail_page.dart` | 464 | 页面大 |
| `core/data/services/export/export_orchestrator.dart` | 450 | 编排器 (职责集中, 可观察) |
| `presentation/pages/assessment/assessment_widgets.dart` | 435 | 多 widget 混居 |
| `presentation/pages/mood_list/mood_detail_page.dart` | 432 | 页面大 |
| `core/data/services/mood_audio_service.dart` | 431 | service 大 |
| `presentation/pages/home/home_page_state.dart` | 420 | state god class (build 188 行) |
| `presentation/pages/medication/widgets/edit_medication_dialog.dart` | 417 | dialog god class (build 225 行) |
| `presentation/pages/medication/refill_manage_page.dart` | 408 | 页面大 |
| `domain/entities/scale_translations/static_scale_translations.dart` | 785 | 数据表, 标准豁免 |

**规范条款**: architecture.md「god class ≥400L 且多职责 → 拆; 数据表/纯 token 豁免; 页面规模大文件不强制拆」。
**建议**: 按 architecture.md 判定标准, 真 god class 优先拆 `import_entities` (再抽 _importDailyTracking) → `mood_audio_recorder_widget` → `audio_lifecycle` (mixin 拆成 ticker/加密/STT 3 个子 mixin)。页面大文件维持现状。

### F-03 [P3 · 轻微 · 维度1风格 · 类型:架构 · 难度:低] 39 个文件 build 方法 >80 行 (11 个 >150)

标准「build 方法 ≤80 行 (超标拆私有 widget)」。Brace-balanced 实测 (每文件首个 build):

- **>150 行 (11)**: edit_medication_dialog.dart:186 (225) / vent_detail_page.dart:243 (215) / medication_detail_page.dart:32 (207) / mood_audio_recorder_widget.dart:370 (189) / home_page_state.dart:180 (188) / mood_recorder_page.dart:299 (177) / export_dialog.dart:70 (171) / assessment_chart_card.dart:29 (166) / crisis_hotline_page.dart:64 (161) / assessment_widgets.dart:270 (161) / home_fab_toolbar.dart:56 (159)
- **121-150 (5)**: trend_day_detail_card.dart:41 (157) / medication_calendar_page.dart:71 (154) / mood_review_page.dart:88 (146) / medication_page.dart:67 (140) / add_medication_step2_form.dart:59 (135)
- **81-120 (23)**: medication_report_dialog.dart:40 (126) / assessment_result_panel.dart:45 (121) / medication_row.dart:63 (120) / setup_step_consent.dart:76 (118) / setup_step_medication.dart:49 (117) / report_history_dialog.dart:22 (111) / notification_status_card.dart:231 (110) / assessment_section.dart:30 (109) / add_medication_page.dart:139 (107) / setup_step_done.dart:27 (106) / trend_calendar.dart:87 (105) / treatment_list.dart:49 (103) / dimension_row.dart:29 (99) / reminders_hub_page.dart:43 (98) / today_summary_card.dart:39 (97) / mood_list_filter_bar.dart:35 (96) / apple_list_section.dart:120 (90) / add_medication_step3_form.dart:64 (88) / assessment_reminder_section.dart:120 (88) / legal_page.dart:240 (86) / medication_calendar_grid.dart:59 (86) / app_shell.dart:80 (86) / check_in_button.dart:80 (85)

**建议**: 与 F-02 同批 — 拆 god class 时顺手抽 `_buildXxx` → 私有 StatelessWidget; 低优先 (info 级, 不影响门禁)。

### F-04 [P3 · 轻微 · 维度1风格 · 类型:底层 · 难度:低] lib/ 15 处 require_trailing_commas info (10 文件)

`dart format` 全绿 ≠ lint 全绿 (formatter 不加 trailing comma, lint 要求加)。R113 wave 1 "dart format 142 文件" 未清 lint:

- cbt_thought_record_pdf_layout.dart ×3 (69×2, 130) / vent_compose_page.dart ×2 (95×2) / vent_tag_picker.dart ×2 (13, 52) / mood_review_aggregator.dart ×2 (55, 119) / worry_archive_page.dart:49 / worry_selector_field.dart:102 / import_tile.dart:217 / tracking_item_card.dart:237 / medication_page_stats_calculator.dart:100 / skip_backup.dart:107

**建议**: `dart fix --apply lib/` 一键清 (同时清 test/ 侧 250 info 中大部分 trailing comma — 182 在 scale_strings 锁库测试 + 40 在 R113 新 worry 测试)。

### F-05 [P3 · 轻微 · 维度2结构 · 类型:底层 · 难度:低] uuid ^4.5.1 死依赖未删

`pubspec.yaml:53` 声明 `uuid: ^4.5.1`; lib/ + test/ grep `package:uuid|Uuid(` = **0 引用** (R112/R113 报告均已点名, 仍未处理)。
**建议**: 删依赖行 + `flutter pub get` 刷新 lock。

### F-06 [P3 · 轻微 · 维度1风格 · 类型:底层 · 难度:低] mood_review_aggregator.dart:2 dangling library doc comment

`lib/domain/logic/mood_review_aggregator.dart:1-2` — 文件头 `//` 路径注释 + `///` 文档注释无 `library;` directive, 触发 `dangling_library_doc_comments` (lib/ 16 info 中唯一非 trailing comma)。
**建议**: 文件头加 `library;` 或把 `///` 改 `//`。

### F-07 [P3 · 轻微 · 维度1风格 · 类型:底层 · 难度:低] 3 处 dynamic 于 JSON 校验层

`lib/core/data/services/export/export_schema_service.dart:114,134,154` — `dynamic v` 参数。标准「避免 dynamic (JSON 校验层可用 Object? + type check)」。
**建议**: 改 `Object?` + is 检查 (strict-casts 已开, 改后风险低)。

### F-08 [P3 · 轻微 · 维度4无障碍 · 类型:底层 · 难度:低] 44dp 紧凑按钮 + 0 显式 textScaler [待人工确认]

- `app_spacing.dart:128` `buttonHeightSmall = 44.0` (iOS 44pt 惯例); `app_tokens.dart:227` `buttonHeightCompact = 44` — 低于 Material 48dp 触达标准。iOS 44pt 是平台惯例可豁免, 但 Android 侧建议仍 48dp [待人工确认: 两端是否分流]。
- lib/ `textScaler` 显式使用 = **0**。全依赖 MediaQuery 默认缩放, 但项目大量固定 `fontSize` + 紧凑行高 (信息密度 +30%), 200% 字号下溢出风险未验证 [待人工确认: 大字号实测一轮]。

### F-09 [P3 · 轻微 · 维度1风格 · 类型:底层 · 难度:低] debugPrint 1 处 (规范边界)

`lib/core/data/utils/skip_backup.dart:106` — `debugPrint` 在 `if (kDebugMode)` 守卫内。标准「禁止 print (用 developer.log 或 piiSafeLog)」; debugPrint 是 Flutter 官宣 print 替代 + 已守卫, 判定为合规边界, 仅记录不改 [待人工确认]。

### F-10 [轻微 · 维度2结构] working tree 未 commit (R113 + round 8-9 全量改动)

`git status` 显示 AGENTS.md / README / ci.yml / analysis_options / launcher 图标等 25+ 文件 modified, 最近 commit 停在 `f9f4e2b5 1.1.0 round 8c`。属用户既定流程 ("未 commit 等用户确认"), 记录提醒, 不算缺陷。

## 评分

**8.0 / 10**

| 维度 | 得分 | 依据 |
|---|---|---|
| 1 代码风格与语法 | 8.5 | 0e/0w; strict-* 全开; 0 废弃 API; 扣分: 15 trailing comma + 39 build>80 + 3 dynamic |
| 2 项目结构与架构 | 8.0 | 4 层纯度双绿 + Riverpod/go_router 100% 统一 + 0 跨 feature; 扣分: 20 god class 中 3 真 god class + uuid 死依赖 |
| 3 性能 | 7.0 | dispose 0 泄漏 + const 纪律严; 扣分: 2 处长列表 eager 回归 (F-01 是本次唯一实质功能级发现) |
| 4 UI/无障碍/i18n | 8.5 | 0 硬编码色/文案 + 状态色 token 化 100% + IconButton 全 tooltip 化; 扣分: 44dp 紧凑按钮 + textScaler 未实测 |

**相对 R113 审计 (flutter-audit 8.7) 回落到 8.0 的原因**: R113 报告未覆盖 list 懒加载回归 (F-01) 与 build 长度/死依赖等静态纵深 — 属"报告盲区"而非"质量倒退"; 全部硬门禁 (测试/analyze/21 守门员/format/coverage) 复验 100% 属实, 无致命项。

## 修复路线 (P2 优先)

1. F-01 懒加载恢复 (2 文件, ~2h) — 唯一 P2 性能项
2. F-02 import_entities → _importDailyTracking 拆分 (1d) + F-03 同批抽 build (~2d, 可分批)
3. F-04/F-05/F-06/F-07 四合一低风险清扫 (`dart fix --apply` + 删依赖 + library; + Object?, ~1h)
4. F-08 大字号实测 + Android 44→48dp 决策 (0.5d)
