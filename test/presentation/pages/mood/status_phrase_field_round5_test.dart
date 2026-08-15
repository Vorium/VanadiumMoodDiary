// v1.1.0 round 5d (Task 14): StatusPhraseField widget 测试
//
// 覆盖 (TDD red→green):
// 1. score 4 → positive 组 5 个 chip 渲染, 其他组 (低落) 不渲染
// 2. tap '被治愈了' → onChanged('被治愈了') (选中)
// 3. 已选 chip 再 tap → onChanged(null) (清除)
// 4. "全部" 展开 → StatusPhraseLibrary.all 全 17 条渲染
// 5. TextField 输入 '自定义一句' + submit → onChanged('自定义一句')
// 6. 自定义值 → 显示一个额外的已选 chip, tap → onChanged(null)
// 7. round 7b: 已选预设短语换 score 后 chip 仍可见 (额外选中 chip), tap → 清除
//
// 设计要点: host StatefulWidget 持有 value (跟 mood_recorder_page 同款
// state-hoisting 模式), onChanged 记录调用序列。

import 'package:chroniccare/domain/logic/status_phrase_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/status_phrase_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Host extends StatefulWidget {
  const _Host({required this.score});
  final int score;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? value;
  final List<String?> calls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: StatusPhraseField(
          score: widget.score,
          value: value,
          onChanged: (v) {
            calls.add(v);
            setState(() => value = v);
          },
        ),
      ),
    );
  }
}

/// 1.1.0 round 7b: 可切换 score 的 host (模拟记录 dialog 里 score 改变
/// 但已选短语保留 — MoodRecorderPage 真实场景)
class _ScoreSwitchHost extends StatefulWidget {
  const _ScoreSwitchHost();
  @override
  State<_ScoreSwitchHost> createState() => _ScoreSwitchHostState();
}

class _ScoreSwitchHostState extends State<_ScoreSwitchHost> {
  int score = 4;
  String? value;
  final List<String?> calls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              onPressed: () => setState(() => score = 1),
              child: const Text('switch-score'),
            ),
            StatusPhraseField(
              score: score,
              value: value,
              onChanged: (v) {
                calls.add(v);
                setState(() => value = v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Widget wrap(int score) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: _Host(score: score),
      );

  testWidgets('1) score 4 → positive 组 5 个 chip 渲染, 其他组不渲染', (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    for (final phrase in StatusPhraseLibrary.positive) {
      expect(find.text(phrase), findsOneWidget);
    }
    expect(find.text('被治愈了'), findsOneWidget);
    // 低落组默认折叠
    expect(find.text('有点难过'), findsNothing);
    expect(find.text('平静'), findsNothing);
  });

  testWidgets('2) tap 预设 chip → onChanged 收到短语 + chip 选中态', (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.calls.last, '被治愈了');
    final chip = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('被治愈了'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('3) 已选 chip 再 tap → onChanged(null) (清除)', (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.calls.last, isNull);
  });

  testWidgets('4) "全部" 展开 → StatusPhraseLibrary.all 全量渲染', (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    for (final phrase in StatusPhraseLibrary.all) {
      expect(find.text(phrase), findsOneWidget);
    }
    expect(find.text('有点难过'), findsOneWidget);
    expect(find.text('平静'), findsOneWidget);
  });

  testWidgets('5) TextField 自定义输入 + submit → onChanged(trimmed)',
      (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == '或输入一句此刻的心情……',
    );
    expect(field, findsOneWidget);
    await tester.enterText(field, '  自定义一句  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.calls.last, '自定义一句');
  });

  testWidgets('6) 自定义值 → 显示额外已选 chip, tap → onChanged(null)', (tester) async {
    await tester.pumpWidget(wrap(4));
    await tester.pumpAndSettle();

    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == '或输入一句此刻的心情……',
    );
    await tester.enterText(field, '自定义一句');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 自定义 chip (值不在预设 all 里) 出现且已选
    final chip = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('自定义一句'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(chip.selected, isTrue);

    await tester.tap(
      find.descendant(
        of: find.byType(FilterChip),
        matching: find.text('自定义一句'),
      ),
    );
    await tester.pumpAndSettle();
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.calls.last, isNull);
  });

  testWidgets('7) round 7b: 已选预设短语换 score 后 chip 仍可见 + 可取消', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const _ScoreSwitchHost(),
      ),
    );
    await tester.pumpAndSettle();

    // score 4 → 选 '被治愈了' (positive 组)
    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();

    // score 切到 1 → positive 组折叠; 已选值必须以额外选中 chip 保留
    await tester.tap(find.text('switch-score'));
    await tester.pumpAndSettle();

    expect(
      find.text('被治愈了'),
      findsOneWidget,
      reason: '换 score 后已选短语 chip 应仍可见',
    );
    final chip = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('被治愈了'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(chip.selected, isTrue, reason: '额外 chip 应保持选中态');

    // tap → 清除
    await tester.tap(find.text('被治愈了'));
    await tester.pumpAndSettle();
    final host = tester.state<_ScoreSwitchHostState>(
      find.byType(_ScoreSwitchHost),
    );
    expect(host.calls.last, isNull, reason: 'tap 已选额外 chip → onChanged(null)');
  });
}
