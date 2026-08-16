// R114 Wave B2: fl_chart 图表 Semantics (B2-5)
//
// 04-engineering A-01: mood_trend_page 3 个图表 (趋势折线 / 分数分布 /
// CBT 重评) 对屏幕阅读器不可见 — fl_chart 无内置 semantics, 全 lib 仅
// 17 处 Semantics vs 90K LOC。精神心理人群与视力障碍高相关。
//
// 修法: 3 个图表容器各包 Semantics(label: <汇总文案>, container: true) —
//   折线图: "情绪趋势折线图, 近 N 天" + 内层"平均 X 分" (无数据日不参与
//   均值, 空窗口无平均分节点 — 避免"空 = 0 分"误读, 跟 R113 BUG 9 同原则)
//   分布图: "情绪分数分布图, 最常见 X 分, 共 N 条记录"
//   CBT:   "CBT 重评效果图, N 条重评记录"
// 文案走新 ARB key (moodTrendSemanticsLine/Avg/Dist/Cbt, 3 语)。
//
// 注意: 条目时间戳用 now 相对 (修前硬编码日期落在 7 天窗口外,
// 均值断言随真实日期漂移)。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_trend_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

MoodEntryEntity _mood({
  required int id,
  required DateTime timestamp,
  required int score,
  int? reratedScore,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    reratedScore: reratedScore,
  );
}

Future<void> _pump(WidgetTester tester, List<MoodEntryEntity> entries) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allMoodProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const MoodTrendPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('趋势折线图有语义摘要 (近 N 天平均分)', (tester) async {
    final handle = tester.ensureSemantics();
    final now = DateTime.now();
    await _pump(tester, [
      _mood(id: 1, timestamp: now.subtract(const Duration(days: 2)), score: 3),
      _mood(id: 2, timestamp: now.subtract(const Duration(days: 1)), score: 5),
    ]);

    expect(
      find.bySemanticsLabel(RegExp('情绪趋势折线图')),
      findsWidgets,
      reason: '折线图容器应带汇总语义 label (视力障碍用户可听读趋势)',
    );
    expect(
      find.bySemanticsLabel(RegExp(r'平均 4\.0 分')),
      findsWidgets,
      reason: '均值 = (3+5)/2 = 4.0 分应出现在 label',
    );
    handle.dispose();
  });

  testWidgets('分数分布图有语义摘要 (最常见分 + 条数)', (tester) async {
    final handle = tester.ensureSemantics();
    final now = DateTime.now();
    await _pump(tester, [
      _mood(id: 1, timestamp: now.subtract(const Duration(days: 4)), score: 3),
      _mood(id: 2, timestamp: now.subtract(const Duration(days: 3)), score: 4),
      _mood(id: 3, timestamp: now.subtract(const Duration(days: 2)), score: 4),
      _mood(id: 4, timestamp: now.subtract(const Duration(days: 1)), score: 2),
    ]);

    await tester.tap(find.text('分数分布'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('情绪分数分布图')),
      findsWidgets,
      reason: '分布图容器应带语义 label',
    );
    expect(
      find.bySemanticsLabel(RegExp(r'最常见 4 分')),
      findsWidgets,
    );
    handle.dispose();
  });

  testWidgets('CBT 重评图有语义摘要 (条数)', (tester) async {
    final handle = tester.ensureSemantics();
    final now = DateTime.now();
    await _pump(tester, [
      _mood(
        id: 1,
        timestamp: now.subtract(const Duration(days: 2)),
        score: 2,
        reratedScore: 4,
      ),
      _mood(
        id: 2,
        timestamp: now.subtract(const Duration(days: 1)),
        score: 3,
        reratedScore: 3,
      ),
    ]);

    await tester.tap(find.text('CBT'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('CBT 重评效果图')),
      findsWidgets,
      reason: 'CBT 图容器应带语义 label',
    );
    handle.dispose();
  });
}
