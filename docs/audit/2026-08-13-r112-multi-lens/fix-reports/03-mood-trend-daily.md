# R112 hotfix 修复报告: 03-mood-trend-daily (mood / trend / daily_tracking)

> 实现 subagent · 2026-08-13 · 7 个任务全部按 TDD (先测试红 → 实现绿 → 守门员验证)

## 任务状态总览

| # | 任务 | 状态 | 测试数 | 备注 |
|---|---|---|---|---|
| 1 | R112-01 日均情绪值算法 | **done** | 6 | 抽 `computeDailyAverages` 纯函数 (sum/count 真均值) |
| 2 | R112-02 详情页导航 | **done (需主 agent 介入)** | 2 | onTap + `/mood/detail/:id` 挂好; **生产路由注册待主 agent 加** |
| 3 | R112-03 影响因素 i18n | **done** | 4+4+5=13 | 存 key + zh→key 反查 + ARB 派发 (28 新 key × 3 语) |
| 4 | R112-05 拖拽重排 | **done** | 5 | 迁 onReorderItem + 纯函数 `computeReorderOrders` + tile 收 `i` |
| 5 | P3 default 分支兜底 | **done** | 2 | 返 `l10n.trackingUnknownItem` (弃 assert: debug 测试会崩) |
| 6 | P3 CBT tab 缩写 | **不改** | - | 3 tab 中 2 个走 l10n, 'CBT' 是通用缩写, 按任务指示仅注明 |

**合计新增 28 个测试** (26 因素 key 相关 13 / 趋势 6 / 导航 2 / 重排 5 / 兜底 2)。

## 任务 1: R112-01 日均情绪值算法 (done)

- **修前**: `dailyAvg[day] = (dailyAvg[day]! + e.score) / 2` 加权衰减平均, `[5,1,1]` → 2.0 (真均值 2.33)。
- **修法**: 抽纯函数 `computeDailyAverages(entries, cutoff)` (mood_trend_page.dart:195), `Map<DateTime, (int sum, int count)>` 累计后除, 同日多条等权。`_MoodLineChart.build` 调用之。
- **测试** (`mood_trend_page_round112_test.dart`): 同日 3 条 [5,1,1]→2.333 / 多日分组 / 乱序无关 / cutoff 排除 / 单条原值 / 2 条 4.0。

## 任务 2: R112-02 详情页导航 (done, 路由注册需主 agent)

- `mood_list_page.dart:145` MoodListItem 挂 `onTap: () => context.push('/mood/detail/${entries[i].id}')`。
- `MoodDetailPage` 重构: `MoodDetailPage({entry, entryId})` (assert 至少传一个); `entryId` 场景 watch `allMoodProvider` 反查, loading/not-found 兜底 (新 ARB key `moodEntryNotFound`)。`entry:` 直传场景保留 (测试/老调用)。
- **⚠️ 需要主 agent 介入**: `lib/core/routing/app_route_mood_list.dart` (不在本 agent 所有权) 需加以下路由, 否则生产环境 push 404:

```dart
// /mood/detail/:id: 情绪详情 (从 mood 列表条目点击进入, occasional 频度, slide-right)
GoRoute(
  path: '/mood/detail/:id',
  pageBuilder: (context, state) => AppRoutes.slideRightPage(
    state.pageKey,
    MoodDetailPage(
      entryId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
    ),
    context,
  ),
),
```
(需 import `mood_detail_page.dart`; 风格照抄同文件 vent 的 `/vent/detail/:id` 段。)

## 任务 3: R112-03 影响因素 i18n (done)

- **domain** (`influence_category.dart`): 新增 `kInfluenceFactorZhToKey` (26 zh→key 反查表) + `influenceFactorNormalizeKey(raw)` 纯函数 (key 幂等 / zh 反查 / 未知值原样)。
- **录入侧** (`mood_influence_chips.dart`): chip label 走 `kInfluenceFactorKeys` + ARB 派发; `onChanged` 返回 **key**; 选中态按归一化 key 匹配 (兼容历史 zh 选中值)。recorder 页 encode 存 key 自动生效 (该文件非本 agent 所有权, 无需改)。
- **展示侧** (`mood_detail_page.dart:137`): `influenceFactorNormalizeKey(f)` 反查后走 `_influenceFactorLabel` ARB 派发; 未知自定义值原样上屏不丢数据。
- **ARB**: 26 `influenceFactor*` + `moodEntryNotFound` + `trackingUnknownItem` = 28 key × 3 语 (zh/en/zh_Hant 经 OpenCC s2tw 校验 100% 一致), `flutter gen-l10n` 重新生成。
- **测试**: domain 4 (幂等/26 全反查唯一/未知原样/codec round-trip) + chips 4 (zh label 无 raw key/tap 返 key/en label/key 选中态) + detail 4 (key zh 显示/旧 zh 反查/en/未知原样) + nav 文件 1 条隐含验证。
- **重复 switch 说明**: `_influenceFactorLabel` 在 mood_influence_chips.dart 与 mood_detail_page.dart 各持一份 (26 case) — mood/mood_list 分属两个 feature, 跨 feature import 被 check_cross_feature 拦 (实测确认), 故不抽共享文件 (所有权外不能新建 lib 文件)。

## 任务 4: R112-05 拖拽重排 (done)

- 迁 `onReorderItem` (删手动 `newIndex--` 补偿)。
- 抽纯函数 `computeReorderOrders(length, oldIndex, newIndex)` — removeAt+insert 后求各原项新位置, 语义与原分支逻辑等价 (4 case 验证)。
- `_TrackingItemTile` 新增 `index` 字段, `ReorderableDragStartListener(index: i)` (修前用 `config.sortOrder`)。
- **测试坑 (值得记录)**: 拖拽需跨过下一个 item **中线** (1.5× extent) 才触发 reorder; `extent*1.5` 恰好在边界 → 框架判"放回原位"不回调。用实测卡距 `extent*2` + `pump(kPressTimeout)` (flutter SDK 自家 reorderable_list_test 同款) 稳定 1 位移位。真实设备人手拖动无此问题。

## 任务 5: P3 default 分支兜底 (done)

- `tracking_customize_page.dart` + `tracking_item_card.dart` 的 `_getLocalizedName` default 返 `l10n.trackingUnknownItem` ("未知项目"/"Unknown item"/"未知項目")。**弃 assert 方案**: widget test 在 debug 模式跑, `assert(false)` 会让测试和 dev UI 直接崩, 兜底文案已足够防 key 名上屏。

## 任务 6: P3 CBT tab (不改)

mood_trend_page.dart:66 `const Tab(text: 'CBT')` — 3 tab 中 2 个走 l10n; CBT 是行业通用缩写 (页面内其余文案均已本地化), 按任务指示不改代码。

## 验证结果

- `flutter test test/presentation/pages/mood/ test/presentation/pages/mood_list/ test/domain/entities/ test/presentation/pages/daily_tracking/ test/integration/` → **136 pass / 0 fail**
- `flutter analyze` (本 agent 全部 lib + 测试文件) → **0 issue**
- 全库 analyze 的 error 为其他 agent 进行中工作 (CbtPdfL10n 重构: cbt_pdf_tile.dart / feature_flags_round66 / sort_assumption_round19b), 与本 agent 无关
- 守门员: check_arb_keys ✅ / check_zh_hant_consistency ✅ (1278 key 繁简 100%) / check_cross_feature ✅ (138 files 0 violation) / check_strings_hardcoded ✅ / check_all.dart ✅ / check_pii_in_title ✅
- `check_orphan_arb_keys`: FAIL 111 个 — **全部为存量 orphan** (asrmOption0 等), 本 agent 28 新 key 全部被 lib 引用 (0 新增 orphan, 已逐 key 验证)
- `check_fullwidth_punctuation` (warn-only): 1 处违规在 setup_widgets.dart (其他 agent 文件)

## Concerns (需要主 agent / C2 agent 注意)

1. **路由注册 (最重要)**: 见任务 2 代码块 — 不加的话点击条目 404。
2. **mood_factor_analysis.dart (C2 所有)**: 第 68 行用原始 `e.influenceFactors` 分组并直接上屏 `factor` — 新数据是 key, 该文件会显示 `influenceFactorFamily` 字面量。修法: C2 用 domain 的 `influenceFactorNormalizeKey` + ARB 派发 (跟 mood_detail_page 同款 switch)。**本 agent 按约束未动该文件。**
3. 历史存量中文数据: 本方案 display 侧反查兼容, 无需数据迁移; 若将来要彻底清洗 DB 可在 encode 路径归一化 (当前非必要)。
4. gen-l10n 是全局再生成 — 与其他 agent 的 ARB 改动共享当前工作树状态 (本 agent 仅新增 28 key, 未删未改其他 key)。
