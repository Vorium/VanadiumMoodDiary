# CBT 重评效果图 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 trend page 新加 `ReratedScoreChart` widget, 跟 `MoodHistoryChart` 平行, 显示 5/7 栏 CBT 重评效果 (score vs reratedScore 双线对比)

**Architecture:** 1 个 provider (filter entries) + 1 个 widget (fl_chart 双线) + trend_page 集成 + 3 个 ARB keys

**Tech Stack:** Flutter 3.41.9 / fl_chart 0.69+ / Riverpod 3.x

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0, `flutter test` 全过, 16 脚本全绿
- TDD: red → green → commit
- baseline test 1424 pass (sub-spec 1 后) / 16 pre-existing fail (R77 残留, 非本批)

## File Structure

### 新增
- `lib/presentation/providers/cbt_rerated_entries_provider.dart`
- `lib/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart`
- `test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart`
- `test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart`

### 修改
- `lib/presentation/pages/trend/trend_page.dart` (在 MoodHistoryChart 后加 ReratedScoreChart)
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (3 keys)

---

### Task 1: 数据层 provider

**Files:**
- Create: `lib/presentation/providers/cbt_rerated_entries_provider.dart`
- Test: `test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart`

**Interfaces:**
- Produces: `cbtReratedEntriesProvider` (Provider.autoDispose<List<MoodEntryEntity>>)

- [ ] **Step 1: 写失败测试**

`test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  group('cbtReratedEntriesProvider (v0.30 round 85)', () {
    test('过滤 3 栏 entries (cbtLevel null), 只返回 5/7 栏', () {
      final container = ProviderContainer(overrides: [
        moodEntriesProvider.overrideWith((ref) => [
          MoodEntryEntity(id: 1, timestamp: DateTime(2026, 8, 1), score: 3, note: '3-栏'),
          MoodEntryEntity(id: 2, timestamp: DateTime(2026, 8, 2), score: 4,
            situation: 's', automaticThought: 'at', evidenceFor: 'ef', evidenceAgainst: 'ea',
            alternativeThought: 'alt', reratedScore: 3,
          ),
        ]),
      ]);
      addTearDown(container.dispose);
      final result = container.read(cbtReratedEntriesProvider);
      expect(result.length, 1);
      expect(result[0].id, 2);
    });

    test('7 栏 entries 也返回', () {
      final container = ProviderContainer(overrides: [
        moodEntriesProvider.overrideWith((ref) => [
          MoodEntryEntity(id: 1, timestamp: DateTime(2026, 8, 1), score: 2,
            situation: 's', automaticThought: 'at', evidenceFor: 'ef', evidenceAgainst: 'ea',
            alternativeThought: 'alt', reratedScore: 4,
            coreBelief: 'cb', behaviorResponse: 'br',
          ),
        ]),
      ]);
      addTearDown(container.dispose);
      expect(container.read(cbtReratedEntriesProvider).length, 1);
    });

    test('空 list 返回空', () {
      final container = ProviderContainer(overrides: [
        moodEntriesProvider.overrideWith((ref) => <MoodEntryEntity>[]),
      ]);
      addTearDown(container.dispose);
      expect(container.read(cbtReratedEntriesProvider), isEmpty);
    });
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart
```

Expected: FAIL — `cbtReratedEntriesProvider` 不存在.

- [ ] **Step 3: 实现 provider**

`lib/presentation/providers/cbt_rerated_entries_provider.dart`:

```dart
// v0.30 round 85 (CBT 重评效果图): 过滤 5/7 栏 entries
//
// moodEntriesProvider (已有) 全部 entries, 过滤 cbtLevel >= 5 给重评图用

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/presentation/providers/mood_entries_provider.dart'  // 找现有 import 路径
    if (dart.library.io) '...'
    // TODO: 跟 project 实际 import 风格, 看 mood_providers.dart / shared_providers.dart 哪个暴露 moodEntriesProvider
    ;

/// 5/7 栏 CBT entries (cbtLevel >= 5), 给 ReratedScoreChart 用
final cbtReratedEntriesProvider = Provider.autoDispose<List<MoodEntryEntity>>((ref) {
  final all = ref.watch(moodEntriesProvider);  // TODO: 实际 provider 名 (moodEntriesProvider vs moodAsync)
  return all.where((e) => (e.cbtLevel ?? 0) >= 5).toList();
});
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart
```

Expected: PASS 3/3.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/providers/cbt_rerated_entries_provider.dart test/presentation/providers/cbt_rerated_entries_provider_round85_test.dart
git commit -m 'v0.30 round 85 (data): cbtReratedEntriesProvider filter 5/7 栏 entries'
```

---

### Task 2: ReratedScoreChart widget

**Files:**
- Create: `lib/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart`
- Test: `test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart`

**Interfaces:**
- Produces: `ReratedScoreChart` widget, 输入 `List<MoodEntryEntity>`, 渲染 fl_chart 双线

- [ ] **Step 1: 写失败测试**

`test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: child),
  );

  testWidgets('5 栏 entries > 3 渲染标题', (tester) async {
    final entries = List.generate(5, (i) => MoodEntryEntity(
      id: i, timestamp: DateTime(2026, 8, 1 + i), score: 4 - i,
      situation: 's', automaticThought: 'at', evidenceFor: 'ef', evidenceAgainst: 'ea',
      alternativeThought: 'alt', reratedScore: 3 - i,
    ));
    await tester.pumpWidget(wrap(ReratedScoreChart(entries: entries)));
    await tester.pumpAndSettle();
    expect(find.text('重评效果'), findsOneWidget);
  });

  testWidgets('5 栏 entries < 3 显示空态', (tester) async {
    final entries = [MoodEntryEntity(
      id: 1, timestamp: DateTime(2026, 8, 1), score: 4,
      situation: 's', automaticThought: 'at', evidenceFor: 'ef', evidenceAgainst: 'ea',
      alternativeThought: 'alt', reratedScore: 3,
    )];
    await tester.pumpWidget(wrap(ReratedScoreChart(entries: entries)));
    await tester.pumpAndSettle();
    expect(find.textContaining('CBT'), findsWidgets);  // 空态文案
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart
```

Expected: FAIL — `ReratedScoreChart` 不存在.

- [ ] **Step 3: 实现 widget**

`lib/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart`:

```dart
// v0.30 round 85 (CBT 重评效果图): score vs reratedScore 双线对比
//
// 跟 MoodHistoryChart 同模式 (fl_chart + RepaintBoundary + EmptyState)

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class ReratedScoreChart extends StatelessWidget {
  final List<MoodEntryEntity> entries;
  const ReratedScoreChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    // 空态: < 3 条 5/7 栏 entries
    if (entries.length < 3) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            children: [
              Icon(Icons.insights, size: 40, color: AppTokens.textSecondaryColor(context)),
              const SizedBox(height: AppTokens.spacingSm),
              Text(AppLocalizations.of(context).trendCbtReratedEmptyTitle,
                style: AppTokens.textStyleCaptionStrong(context)),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(AppLocalizations.of(context).trendCbtReratedEmptyHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: AppTokens.fontSizeCaption, color: AppTokens.textSecondaryColor(context))),
            ],
          ),
        ),
      );
    }
    // 双线 chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).trendCbtReratedChartTitle,
              style: AppTokens.textStyleTitleSmall(context)),
            const SizedBox(height: AppTokens.spacingMd),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 1, maxY: 5,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLine(context, entries.map((e) => FlSpot(e.timestamp.millisecondsSinceEpoch.toDouble(), e.score.toDouble())).toList(), isOriginal: true),
                    _buildLine(context, entries.map((e) => FlSpot(e.timestamp.millisecondsSinceEpoch.toDouble(), e.reratedScore!.toDouble())).toList(), isOriginal: false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _buildLine(BuildContext context, List<FlSpot> spots, {required bool isOriginal}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 2,
      color: isOriginal ? AppTokens.primaryColor(context) : Colors.green,
      dashArray: isOriginal ? null : [5, 5],
      dotData: const FlDotData(show: false),
    );
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart
```

Expected: PASS 2/2.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart test/presentation/pages/trend/trend_cbt_rerated_chart_round85_test.dart
git commit -m 'v0.30 round 85 (ui): ReratedScoreChart 双线 fl_chart (score 实线 + rerated 虚线)'
```

---

### Task 3: trend_page 集成

**Files:**
- Modify: `lib/presentation/pages/trend/trend_page.dart`

- [ ] **Step 1: 在 MoodHistoryChart 后加 ReratedScoreChart section**

`lib/presentation/pages/trend/trend_page.dart` — 找 `MoodHistoryChart` 引用处, 在其后加:

```dart
// v0.30 round 85: 重评效果图 (5/7 栏 CBT 重评前后对比)
ReratedScoreChart(entries: ref.watch(cbtReratedEntriesProvider)),
const SizedBox(height: AppTokens.spacingMd),
```

- [ ] **Step 2: 跑 trend_page test 验证**

```bash
flutter test test/presentation/pages/trend/ 2>&1 | Select-String -Pattern 'All tests|tests passed' | Select-Object -Last 2
```

Expected: PASS (现有 trend_page test 应该已经覆盖 MoodHistoryChart, 新加的 ReratedScoreChart 不破坏现有).

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/trend/trend_page.dart
git commit -m 'v0.30 round 85 (trend): ReratedScoreChart 集成到 trend_page'
```

---

### Task 4: ARB i18n + final review

**Files:**
- Modify: `lib/l10n/app_{zh,en,zh_Hant}.arb`

- [ ] **Step 1: 加 3 keys (zh)**

`lib/l10n/app_zh.arb` 末尾加:

```json
,
  "trendCbtReratedChartTitle": "重评效果",
  "trendCbtReratedEmptyTitle": "还没有 5/7 栏 CBT 数据",
  "trendCbtReratedEmptyHint": "先用 5/7 栏 CBT 填表, 才能看到重评效果"
```

- [ ] **Step 2: 加 3 keys (en)**

`lib/l10n/app_en.arb`:

```json
,
  "trendCbtReratedChartTitle": "Rerating effect",
  "trendCbtReratedEmptyTitle": "No 5/7-column CBT data yet",
  "trendCbtReratedEmptyHint": "Fill in a 5/7-column CBT thought record first to see your rerating effect"
```

- [ ] **Step 3: 加 3 keys (zh_Hant)**

`lib/l10n/app_zh_Hant.arb`:

```json
,
  "trendCbtReratedChartTitle": "重評效果",
  "trendCbtReratedEmptyTitle": "還沒有 5/7 欄 CBT 資料",
  "trendCbtReratedEmptyHint": "先用 5/7 欄 CBT 填表, 才能看到重評效果"
```

- [ ] **Step 4: flutter gen-l10n**

```bash
flutter gen-l10n
```

- [ ] **Step 5: 跑守门员验证 i18n**

```bash
python scripts/check_arb_keys.py
python scripts/check_orphan_arb_keys.py
python scripts/check_zh_hant_consistency.py
python scripts/check_strings_hardcoded.py
```

Expected: 4 个脚本全绿.

- [ ] **Step 6: 跑全量分析 + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, ~1429 pass (1424 + 5 new = 1429, 16 pre-existing fail 不变).

- [ ] **Step 7: 更新 CHANGELOG**

`docs/CHANGELOG.md` 顶部加:

```markdown
## [0.30.0] - 2026-08-05

### Added (v0.30 round 85)
- **CBT 重评效果图 (sub-spec 2)**: 5/7 栏 CBT 重评前后对比
  - 新加 `ReratedScoreChart` widget (fl_chart 双线: score 实线 + reratedScore 虚线)
  - 集成到 trend page MoodHistoryChart 下方
  - 3 个 ARB key (zh / en / zh_Hant)
  - 空态: 5/7 栏数据 < 3 条时显示
```

- [ ] **Step 8: Commit final**

```bash
git add lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/l10n/app_zh_Hant.arb lib/l10n/app_localizations*.dart docs/CHANGELOG.md
git commit -m 'v0.30 round 85 (i18n): 3 ARB keys + CHANGELOG + 重评图 spec/plan'
```

---

## Self-Review

- [x] Spec coverage: data layer (Task 1) / widget (Task 2) / trend_page 集成 (Task 3) / i18n (Task 4)
- [x] No placeholders / TBD
- [x] Type consistency: `cbtReratedEntriesProvider` 返回 `List<MoodEntryEntity>`, `ReratedScoreChart` 接收同类型
- [x] TDD: red → green → commit per task
- [x] DRY: 复用 MoodHistoryChart 模式 (fl_chart + RepaintBoundary + EmptyState)
- [x] YAGNI: 不做重评统计 / 不做 AI / 不做多重评对比 (留 v0.30+)
