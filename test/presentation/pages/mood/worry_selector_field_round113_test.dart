// v1.1.0 R113 (F1 烦恼闭环 audit gap 2): WorrySelectorField bottom sheet 3 分支测试
//
// 覆盖:
// a) initialThreadId 绑定 → field label 显示已选烦恼 title
// b) 点击 → bottom sheet 列出 3 选项 + 进行中烦恼列表 (worryOpenProvider)
// c) 点已有烦恼 → onChanged(WorrySelection(threadId, createNew: false)) + label 更新
// d) 点"新建烦恼" → onChanged(createNew: true) + label 更新
// e) 点"没有关联烦恼" → 清除绑定 (isNone) + label 回落
//
// 依赖: 仅 worryOpenProvider (fake stream), onChanged 回调捕获。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/worry_selector_field.dart';

WorryThreadEntity _open(int id, String title) => WorryThreadEntity(
      id: id,
      title: title,
      createdAt: DateTime(2026, 8, 15, 9),
      status: WorryStatus.open,
    );

Widget _wrap({
  int? initialThreadId,
  required List<WorryThreadEntity> open,
  required ValueChanged<WorrySelection> onChanged,
}) {
  return ProviderScope(
    overrides: [
      worryOpenProvider.overrideWith((ref) => Stream.value(open)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: WorrySelectorField(
          initialThreadId: initialThreadId,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

/// sheet 内点选项 (field label 可能跟 sheet 选项同文案, 需限定 BottomSheet 范围)
Finder _sheetText(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

void main() {
  testWidgets('a) initialThreadId 绑定 → label 显示已选烦恼 title', (tester) async {
    await tester.pumpWidget(_wrap(
      initialThreadId: 7,
      open: [_open(7, '考试焦虑'), _open(8, '工作压力')],
      onChanged: (_) {},
    ));
    await tester.pumpAndSettle();

    expect(find.text('考试焦虑'), findsOneWidget,
        reason: '预绑定时 field 应显示所选烦恼 title 而非"没有关联烦恼"');
  });

  testWidgets('b) 点击 → bottom sheet 显示 3 选项 + 进行中烦恼列表', (tester) async {
    await tester.pumpWidget(_wrap(
      open: [_open(7, '考试焦虑'), _open(8, '工作压力')],
      onChanged: (_) {},
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WorrySelectorField));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(_sheetText('关联烦恼'), findsOneWidget, reason: 'sheet header');
    expect(_sheetText('没有关联烦恼'), findsOneWidget);
    expect(_sheetText('新建烦恼'), findsOneWidget);
    expect(_sheetText('考试焦虑'), findsOneWidget, reason: 'open 烦恼列表项');
    expect(_sheetText('工作压力'), findsOneWidget);
  });

  testWidgets('c) 点已有烦恼 → onChanged(threadId) + label 更新', (tester) async {
    final selections = <WorrySelection>[];
    await tester.pumpWidget(_wrap(
      open: [_open(7, '考试焦虑'), _open(8, '工作压力')],
      onChanged: selections.add,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WorrySelectorField));
    await tester.pumpAndSettle();
    await tester.tap(_sheetText('工作压力'));
    await tester.pumpAndSettle();

    expect(selections, hasLength(1));
    expect(selections.last.threadId, 8, reason: '点已有烦恼 → 绑定该 threadId');
    expect(selections.last.createNew, isFalse);
    expect(find.text('工作压力'), findsOneWidget, reason: 'sheet 关闭后 label 更新');
  });

  testWidgets('d) 点"新建烦恼" → onChanged(createNew: true) + label 更新',
      (tester) async {
    final selections = <WorrySelection>[];
    await tester.pumpWidget(_wrap(
      open: [_open(7, '考试焦虑')],
      onChanged: selections.add,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(WorrySelectorField));
    await tester.pumpAndSettle();
    await tester.tap(_sheetText('新建烦恼'));
    await tester.pumpAndSettle();

    expect(selections, hasLength(1));
    expect(selections.last.threadId, isNull);
    expect(selections.last.createNew, isTrue,
        reason: '新建烦恼分支 → createNew: true (保存时由 note 生成 title)');
    expect(find.text('新建烦恼'), findsOneWidget, reason: 'label 切到"新建烦恼"');
  });

  testWidgets('e) 点"没有关联烦恼" → 清除绑定 (isNone)', (tester) async {
    final selections = <WorrySelection>[];
    await tester.pumpWidget(_wrap(
      initialThreadId: 7,
      open: [_open(7, '考试焦虑')],
      onChanged: selections.add,
    ));
    await tester.pumpAndSettle();
    expect(find.text('考试焦虑'), findsOneWidget, reason: '起点: 已绑定');

    await tester.tap(find.byType(WorrySelectorField));
    await tester.pumpAndSettle();
    await tester.tap(_sheetText('没有关联烦恼'));
    await tester.pumpAndSettle();

    expect(selections, hasLength(1));
    expect(selections.last.isNone, isTrue,
        reason: '不关联分支 → threadId null + createNew false');
    expect(find.text('没有关联烦恼'), findsOneWidget, reason: 'label 回落到"没有关联烦恼"');
  });

  testWidgets('f) initialThreadId 指向失效 thread → 降级 none + onChanged 同步',
      (tester) async {
    // P3-CLEAN-12: 修前 label 显示"不关联"但 _selection.threadId 仍绑定
    // 失效 thread → 显示与保存 (draft) 不一致。
    final selections = <WorrySelection>[];
    await tester.pumpWidget(
      _wrap(
        initialThreadId: 99,
        open: [_open(7, '考试焦虑')],
        onChanged: selections.add,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('没有关联烦恼'),
      findsOneWidget,
      reason: '失效绑定的 label 应回落"没有关联烦恼"',
    );
    expect(
      selections,
      hasLength(1),
      reason: '降级必须上抛 onChanged, 让 draft 侧同步清绑定',
    );
    expect(
      selections.last.isNone,
      isTrue,
      reason: 'draft 绑定必须与 label 一致 (threadId null + createNew false)',
    );
  });

  testWidgets('g) initialThreadId 有效时不触发降级 onChanged (0 次)', (tester) async {
    final selections = <WorrySelection>[];
    await tester.pumpWidget(
      _wrap(
        initialThreadId: 7,
        open: [_open(7, '考试焦虑')],
        onChanged: selections.add,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('考试焦虑'), findsOneWidget, reason: '有效绑定 label 不变');
    expect(selections, isEmpty, reason: '有效绑定不得误触发降级 onChanged');
  });
}
