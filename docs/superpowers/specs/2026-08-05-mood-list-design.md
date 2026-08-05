# Mood 列表页 Sub-spec 3

| 项目 | 内容 |
|---|---|
| 状态 | design (待 review) |
| 日期 | 2026-08-05 |
| 范围 | sub-spec 3 / 5 (mood 列表页) |
| 依赖 | sub-spec 1+2 merged (v0.30 round 84+85+86) |

## 背景

当前看 mood entry 的入口:
- `trend_calendar` DayDetailCard: 只能看"某天"的 entry
- `home_page` 主页: 显示当天 mood + 录音入口
- 没有"看所有 mood entries"的入口

CBT 治疗中患者常需要"回看过去 N 天的 mood 变化"或"找带特定 tag 的 entry", 但当前 UI 强迫走 calendar 一个个点开。

mood list page = 1 个列表视图, 跟 trend page 平行, 让用户能:
- 时间倒序看所有 entries
- 按 score 范围 / CBT level / 标签 / 日期范围 filter
- 搜索 note 关键字
- 点开看 detail (复用现有 DayDetailCard 的内容)

## Goals

- 新加 `MoodListPage` widget (`lib/presentation/pages/mood_list/`)
- 时间倒序列表 (新→旧)
- Filter: date range + score range + CBT level (3/5/7/全部)
- Search: note 关键字 (case-insensitive, 实时过滤)
- Sort: timestamp desc (默认) / score asc / score desc
- Empty state: 无 entry + 无 filter 结果两种
- i18n: ~10 keys (zh / en / zh_Hant)
- 入口: home page 主页加按钮 OR trend page 加 tab

## Non-Goals

- ❌ Edit entry (留 v0.31)
- ❌ Delete entry (现有 trend_calendar 已支持, 不重复)
- ❌ Export selected entries (sub-spec 4 PDF 范围)
- ❌ Bulk action (多选 + 批量 tag / delete)
- ❌ Pagination (假设 < 10000 条, ListView 一次过)
- ❌ Detail page 新建 (复用 DayDetailCard 内容)

## 范围

1. **数据层**: 1 个 `moodListFilterProvider` (filter + search + sort state)
2. **Widget**: `MoodListPage` + 1 个 `MoodListItem` (单行渲染)
3. **Filter UI**: date range / score range / CBT level chips
4. **Search UI**: TextField + 实时过滤
5. **入口**: home page 主页加 "查看所有" 按钮 → `context.push('/mood-list')`
6. **i18n**: 10 keys (zh / en / zh_Hant)
7. **测试**: 1 filter logic + 1 widget test (空 / 搜索 / 过滤 / sort)

## 数据模型

无 schema 改动 (所有数据已在 mood_entries)。

新增 provider:
- `moodListFilterProvider` (NotifierProvider<MoodListFilter>) — 持有 filter 状态
- `filteredMoodEntriesProvider` (Provider<List<MoodEntryEntity>>) — 现有 moodEntriesProvider 基础上 apply filter + search + sort

```dart
class MoodListFilter {
  final DateTimeRange? dateRange;
  final int? minScore;
  final int? maxScore;
  final int? cbtLevel;  // 3 / 5 / 7 / null=全部
  final String searchQuery;
  final MoodListSort sort;  // timestamp desc (default) / score asc / score desc
}
```

## UI 设计

```
┌───────────────────────────────┐
│  ← Mood 历史                   │
│  [🔍 搜索 note...]              │  ← TextField
│  [日期 📅] [分数 1-5] [CBT ▾]   │  ← filter chips
│  [↕ 时间倒序 ▼]                │  ← sort dropdown
├───────────────────────────────┤
│  2026-08-04 14:32              │
│  💚 4/5  开会迟到              │  ← 1 个 MoodListItem
│       📝 CBT 5 栏 自动思维...  │
├───────────────────────────────┤
│  2026-08-03 09:15              │
│  💛 3/5  普通                  │
│       今天还行                │
└───────────────────────────────┘
```

**Empty state** (无 entry 或 filter 结果空):
```
┌─────────────────┐
│   📭             │
│   还没有 mood 记录│
│   (或: 没有匹配的) │
└─────────────────┘
```

## 状态管理

- `moodListFilterProvider` (NotifierProvider<MoodListFilter>) — UI 改 filter
- `filteredMoodEntriesProvider` (Provider.autoDispose) — filter + search + sort 后的 list
- 用 go_router `context.push('/mood-list')` 导航

## 错误处理

- search query 空 → 不过滤 (跟默认 list 一样)
- filter 全空 → 显示所有
- filter 结果 0 → empty state ("没有匹配的")

## 测试

- **filter logic**: 1 case (date range + score range + cbtLevel + search 综合)
- **widget**: 3 cases (空 / 搜索 / filter 生效)
- **provider**: 1 case (filter state changes)

## ARB key 列表

```
moodListPageTitle       "Mood 历史"
moodListSearchHint      "搜索 note..."
moodListFilterDate      "日期"
moodListFilterScore     "分数"
moodListFilterCbt       "CBT 档位"
moodListSortBy          "排序"
moodListSortTimestamp   "时间倒序"
moodListSortScoreAsc    "分数升序"
moodListSortScoreDesc   "分数降序"
moodListEmpty           "还没有 mood 记录"
moodListNoMatch         "没有匹配的记录"
moodListEntryCount      "{count} 条记录"
```

## 实施步骤 (high level)

1. **Task 1**: 数据层 (filter + search + sort logic + provider)
2. **Task 2**: MoodListItem widget (单行渲染)
3. **Task 3**: MoodListPage (filter chips + search + sort dropdown + ListView)
4. **Task 4**: home page 入口 + go_router 路由
5. **Task 5**: ARB i18n + final review + merge
