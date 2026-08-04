# CBT 重评效果图 Sub-spec 2

| 项目 | 内容 |
|---|---|
| 状态 | design (待 review) |
| 日期 | 2026-08-05 |
| 范围 | sub-spec 2 / 5 (重评效果图) |
| 依赖 | sub-spec 1 merged (eebb8fd, 8 个 CBT 字段已落库) |

## 背景

sub-spec 1 (v0.29 round 84) 把 CBT 5/7 栏思维记录落到 mood_entries 表, 新增 `reratedScore` 字段 (5/7 栏专用, 1-5 重新评分)。但用户填完 CBT 之后看不到"认知重构效果"——也就是"我重评后情绪强度变化了多少"。

CBT 实践中"重评效果"是衡量治疗进展的关键指标, 但当前 trend page 只有原始 `score` 的折线图 (`MoodHistoryChart` 在 `lib/presentation/pages/trend/widgets/trend_mood_chart.dart`), 没法看重评前后对比。

## Goals

- 在 trend page 新加 `ReratedScoreChart` widget, 跟 `MoodHistoryChart` 平行
- 双线 fl_chart: score 实线 + reratedScore 虚线 + delta 阴影区
- 空态: 5/7 栏数据 < 3 条时显示"先用 5/7 栏 CBT 才能看到重评效果"
- i18n: 3 keys (title / empty / hint)
- 数据层: 1 个 provider 过滤 entries (cbtLevel >= 5)

## Non-Goals

- ❌ AI 辅助评分
- ❌ 多重评对比 (只 1 次)
- ❌ 跨设备同步
- ❌ 重评统计摘要 (avg shift, max decrease) - 留 v0.30
- ❌ 暗色模式单独优化 - 复用 AppTokens 自动

## 范围

1. **数据层**: 1 个 provider `cbtReratedEntriesProvider` (filter List<MoodEntryEntity> 取 cbtLevel >= 5)
2. **Widget**: `ReratedScoreChart` (跟 MoodHistoryChart 同模式, 复用 AppTokens + fl_chart)
3. **集成**: trend page 在 MoodHistoryChart 下方加 ReratedScoreChart section
4. **i18n**: 3 keys (zh / en / zh_Hant)
5. **测试**: 1 个 provider test + 1 个 widget test (含空态)

## 数据模型

无 schema 改动。所有数据已经在 sub-spec 1 的 mood_entries 8 CBT 字段里。

新增 provider:

```dart
// lib/presentation/providers/cbt_rerated_entries_provider.dart
final cbtReratedEntriesProvider = Provider.autoDispose<List<MoodEntryEntity>>((ref) {
  final all = ref.watch(moodEntriesProvider);  // 已有
  return all.where((e) => e.cbtLevel != null && e.cbtLevel! >= 5).toList();
});
```

## UI 设计

```
trend page (现有 layout 不变)
├─ MoodHistoryChart (现有, 全 score 1-5 折线)
├─ ReratedScoreChart (新)              ← 加这里
│   ├─ 标题: "重评效果"
│   ├─ fl_chart 双线:
│   │   • 蓝色实线 = 原始 score (事件触发时)
│   │   • 绿色虚线 = reratedScore (5/7 栏重评)
│   │   • 阴影区 = 两次评分差 (delta)
│   ├─ 5 行 x 轴 (日期)
│   └─ 1-5 y 轴
└─ ...
```

**空态** (5/7 栏 entries < 3):
```
┌────────────────────────┐
│   💭                    │
│   重评效果              │
│   先用 5/7 栏 CBT 填表 │
│   才能看到重评效果      │
└────────────────────────┘
```

## 状态管理

- `cbtReratedEntriesProvider` (Provider.autoDispose) - 跟现有 moodEntriesProvider 模式一致

## 错误处理

- 5/7 栏 entries < 3 → 空态 (Card + icon + 2 text, 跟 MoodHistoryChart 空态同模式)
- fl_chart 渲染异常 → try-catch + SnackBar (跟现有 chart 同模式, 不影响其它 UI)

## 测试

- **provider**: 1 case (空 list / 3 栏 mix / 5 栏 / 7 栏 / 排序)
- **widget**: 2 cases (5/7 栏数据 > 3 渲染双线 / < 3 空态)
- **趋势集成**: 现有 trend_page test 校验 ReratedScoreChart section 出现

## 风险与回滚

- fl_chart 0.69+ 跟项目 0.x 老 API 兼容: 已 verify MoodHistoryChart 跑通
- 0 风险 (新 widget, 不改现有)

## ARB key 列表

```
trendCbtReratedChartTitle  "重评效果"
trendCbtReratedEmptyTitle   "还没有 5/7 栏 CBT 数据"
trendCbtReratedEmptyHint    "先用 5/7 栏 CBT 填表, 才能看到重评效果"
```

## 实施步骤 (high level)

1. **Task 1**: 数据层 (provider + test)
2. **Task 2**: Widget (ReratedScoreChart + test 含空态)
3. **Task 3**: trend_page 集成
4. **Task 4**: ARB i18n 同步 + final review
