# Fix Report: vent / assessment / mood_list / daily_tracking AppleListSection 化 (F2 / EM-02 / AH-04 第二半 + AH-15 + AH-16)

日期: 2026-08-13 · 状态: 全部 done · 目标测试 82 全绿 · 全量 2460 pass / 1 skip / 5 fail (4 iOS 资产占位 + 1 跨期 lock-in, 见文末)

## 范围

R111/R112 AH-04/EM-02 点名的 ALS 化第二半 (F2 lane): vent / assessment /
mood_list / daily_tracking 的 `Card + ListTile` 旧方言 → `AppleListSection`
(spec §4.5 / §5.5-5.7, 以 home/setup/medication 样板为准), 外加 AH-15
(vent systemPurple FAB) + AH-16 (medication 4 tile 语义化 + tintedMetricSoft
死 token 清除)。

**改动文件 (16 个)**: vent_list_page / mood_list_page / mood_list_item /
mood_detail_page / daily_tracking_page / assessment_widgets (ComparisonCard
+ AssessmentSparkline) / assessment_history_list / assessment_summary_strip /
assessment_chart_card / medication_page (4 tile) / app_colors + app_tokens
(tintedMetricSoft 删) + 4 个测试文件。

## 视觉规则落实

- **0 新 Card**: 我名下文件 Card 从 9 处 → 0 处 (grep 实测), 新增
  **14 处** `AppleListSection(` runtime 调用 (vent 1 / assessment 6 /
  mood_list 7 / daily_tracking 1)。
- **insetGrouped + margin zero**: 全部 ALS 走 `margin: EdgeInsets.zero`
  (PageScaffold 已给 pageMarginH 20, 跟 home/medication 样板一致)。
- **13pt ALL CAPS title**: section 标题走 ALS title (mood_list
  `moodListEntryCount` "N 条记录" / assessment "完整记录" / "对比上次" /
  "历史趋势" / daily_tracking 分类名); 无标题场景 (vent 列表 / mood_detail
  hero / note) 不传 title, 0 新文案 0 新 ARB key。
- **hairline 0.5**: 手写 `Divider(height: 1, thickness: 0.5, indent: 56)`
  (assessment_history_list) 删, 由 ALS 自动串联。
- **0 阴影 / 0 硬编码 Color/fontSize**: 新增代码全走 AppTokens +
  healthMetricsColorFor; check_strings_hardcoded 规则 2 inline = 0。

## 关键决策 (供主 agent review)

1. **ListTile 不能放 ALS 内 (debug 断言)**: AppleListSection 容器是
   `ClipRRect > DecoratedBox` (非 Material), ListTile 在 widget test
   debug 断言 "ListTile background color or ink splashes may be
   invisible" → 我名下所有 ALS cell 全改 `PressFeedback + GestureDetector
   + Row` 平铺 (home _RowCell / MedicationListCell 样板)。⚠️ ALS 文档注释
   仍写 "通常是 ListTile" — 该注释是错的, 建议主 agent 后续修正 apple_list_section.dart
   的 doc (该文件不在我所有权)。
2. **mood_list_item.dart 不在所有权清单**: MoodListItem 唯一 caller 是
   mood_list_page (grep 实锤), 为完成 "mood_list 列表 ALS 化" 我改了它
   (ListTile → Row, 视觉结构 only, 0 业务逻辑 0 文案变化)。若与主 agent
   的 file-ownership 冲突请告知。
3. **daily_tracking TrackingItemCard 未改** (不在所有权): 分类区改为
   ALS(title=分类名) 包裹, 但 TrackingItemCard 内部仍是
   `Card(elevation: 0, border)` — 视觉上是"白组内描边块", 不完美但
   tracking_item_card.dart 不在我名单 (且被 _PinnedSection 横滚复用)。
   若要彻底去 Card, 建议主 agent 后续拆 TrackingItemCard 的 `showCard`
   参数或平铺化。
4. **assessment 结果页 (AssessmentResultPanel) 未改**: 推荐就医卡有
   tintedWarningSoft 语义色 + 免责声明卡, 转 ALS 会丢色 → spec §5.7
   "题目页保留" 一致, 保持 Card。
5. **AH-16 语义映射** (R112 审计建议 refill=orange / history=blue):
   待服=`medication`(红) / 已服=`checkIn`(绿) / 需续方=`contact`(橙) /
   日历=`trend`(蓝)。icon 随 metricId 自动区分
   (medication/check_circle/contact_phone/show_chart)。⚠️
   contact_phone 作"需续方" icon 语义略怪 — AppleHealthTile icon 由
   metricId 硬映射且不在我所有权, 若要求 icon 完全语义可后续给
   AppleHealthTile 加 icon override。
6. **tintedMetricSoft 死 token**: grep 确认 0 runtime caller → 从
   app_colors.dart + app_tokens.dart facade 删除 (任务明确授权这 2 文件)。
   AppleHealthTile 内联 `withValues(alpha: 0.12/0.18)` 保持不变。

## 每个文件

| 文件 | 改法 |
|---|---|
| vent_list_page.dart | `_EntryList`: ListView.separated → ListView + ALS(children = FadeIn stagger + Dismissible 行); `_EntryCard` → `_EntryCell` (Card 删 + ListTile → Row, Hero/onLongPress/预览/时长 0 业务变化); SwipeDeleteBackground rounded:true → false (ALS 容器内); **AH-15: systemPurple FAB** (未封存 + 有条目时显示, 空态走 EmptyState action, 封存态无 FAB) |
| mood_list_page.dart | ListView.builder → ListView + ALS(title: moodListEntryCount, children: MoodListItem); onTap → /mood/detail/:id 保留 (C1 R112-02) |
| mood_list_item.dart | ListTile → PressFeedback + GestureDetector + Row (见决策 2) |
| mood_detail_page.dart | 6 个 Card → 6 个 ALS: hero(emoji+score) / 情绪标签 / 影响因素 / CBT 记录(title) / note / audio(行); 录音 ListTile → Row |
| daily_tracking_page.dart | 分类区 TrackingCategoryHeader + Padding → ALS(title=_categoryLabel(4 case)); `_showItemActions` / pinned 区 0 改 |
| assessment_widgets.dart | ComparisonCard + AssessmentSparkline Card → ALS(margin zero); ⚠️ SparklinePainter / sparklineMaxTotalFor (C2) 0 改; QuestionCard 保留 (spec §5.7 题目页保留) |
| assessment_history_list.dart | Card + header Row + 手写 Divider(indent 56) → ALS(title: 完整记录); _HistoryItem 外层 Padding 删 |
| assessment_summary_strip.dart | Card + Padding → ALS (3 stat Row 原样) |
| assessment_chart_card.dart | <2 记录: AppListTile.carded → ALS(title + icon row); ≥2: Card + header → ALS(title=量表名, count 右上, 折线图 0 改) |
| medication_page.dart | AH-16: 4 tile metricId 语义化 (见决策 5), label/value/onTap 0 改 |
| app_colors.dart / app_tokens.dart | 删 tintedMetricSoft (0 caller, 决策 6) |

## 测试 (82 全绿)

- **vent_list_round18_test**: +2 case — ALS 结构 (0 Card + 1 ALS +
  systemPurple FAB 色断言) / 空列表无 FAB。
- **mood_list_page_round87_test**: +2 断言 — 1 ALS + "3 条记录" count title。
- **medication_page_round101_test**: +1 case — 4 tile metricId 断言
  (widgetList skipOffstage:false 拿全部 4 个)。
- **assessment_history_round13b_test**: +2 断言 — 3 ALS (summary/chart/list)
  + 0 Card。
- 既有测试同步过: vent 18 / swipe hint / mood_list 全套 / mood_detail
  factors / assessment 全套 / daily_tracking_page / medication_page = 82
  全绿。

## 验证

- `flutter analyze` 我名下 12 文件: 0 error / 0 warning / 0 info
- `flutter test` 全量: **2460 pass / 1 skip / 5 fail** — 5 fail 明细:
  - 4 × iOS 资产占位 (app_icon_size / launch_image_size, R108 起跨期
    设计师外部依赖, 非本批)
  - 1 × `app_tokens_lock_in_round95_test.dart` (EdgeInsets 计数 ≤250):
    **跨期预红** — 我改动前基线实测 271 (其他 agent R112 WIP 已超),
    我改动 +17 → 288。非我独有; 阈值需主 agent 按锁-in 惯例 (R110
    "251 实测 → 阈值 260") 复核后上调 + 记 buffer。
- `python scripts/check_cross_feature.py`: 0 violation
- `python scripts/check_strings_hardcoded.py`: 0 (inline)
- `dart scripts/check_all.dart`: 纯度 + 一致性 ✅
- `check_apple_health_claim.py` / `check_orphan_arb_keys.py`: OK (0 新 ARB key)

## Concerns

1. **lock-in EdgeInsets 阈值** (见上): 需主 agent 拍板阈值数字; 我名下
   +17 全部是 `EdgeInsets.zero` (ALS margin, 既有样板模式) + 2 处
   `EdgeInsets.only(top/bottom)` — 无 magic number, 无"修正回退"。
2. **ALS doc "ListTile OK" 与 debug 断言矛盾** — apple_list_section.dart
   (非我所有权) 文档注释需修正, 否则后续 agent 会再踩。
3. **TrackingItemCard 内 Card 未清** (决策 3) — daily_tracking 视觉上
   还有描边块, 是否彻底平铺需主 agent 定 + 拆参数。
4. **vent FAB 与 AppBar "+" 并存** — 跟 medication 样板一致 (两入口),
   若主 agent 认为重复可在后续删 AppBar action (业务行为 0 影响)。
5. C1 报告 03 提到 `/mood/detail/:id` 生产路由注册待主 agent — 我的
   mood_list onTap 依赖该路由, 未注册前生产环境 push 会 404 (测试走
   inline GoRouter 不受影响)。
