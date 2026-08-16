// R114 Wave B2: 双重 20px inset 统一 (B2-4)
//
// apple F-01: PageScaffold 已包 pageMarginH=20, AppleListSection 默认再包
// 20 → 实际 40px; home/medication 传 margin: EdgeInsets.zero 但 trend 显式
// 再传 20 — 同 app 两套 inset。
//
// 裁决: 选 "20+0" — PageScaffold 唯一负责页边距 (20px), AppleListSection /
// LazyAppleListSection 默认 margin 改 zero (apple 审计建议 + 52 处现有
// zero caller 的多数模式)。trend_summary / add_medication 3 form /
// refill_manage 的显式 20 删除 (回到默认 zero)。
//
// 检查: 全部依赖默认 margin 的 ALS caller (mood_review / medication_detail
// / tips / calendar 等) 都在 PageScaffold 内, 默认改 zero 后恰得 20px,
// 无 flush-to-edge 回归。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: AppleListSection(
          title: 'section',
          children: [Text('cell')],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('AppleListSection 默认 margin → zero (PageScaffold 负责 20px)',
      (tester) async {
    await _pump(tester);

    // 根 Padding (包圆角 Material 容器的那个) 横向 = 0
    final material = find
        .descendant(
          of: find.byType(AppleListSection),
          matching: find.byType(Material),
        )
        .first;
    final padding =
        find.ancestor(of: material, matching: find.byType(Padding)).first;
    expect(
      tester.widget<Padding>(padding).padding.horizontal,
      0,
      reason: '修前默认 symmetric(horizontal: 20) 与 PageScaffold 20 叠加成 40',
    );
  });

  group('lock-in: 显式 pageMarginH margin 的残留 caller 清零', () {
    Future<String> read(String path) => File('lib/$path').readAsString();

    /// 去 `//` 注释后检查 (跟 scripts/check_datetime_race.py 同语义,
    /// 注释里提 "删 margin: pageMarginH" 不算)
    String stripComments(String src) => src.split('\n').map((l) {
          final i = l.indexOf('//');
          return i >= 0 ? l.substring(0, i) : l;
        }).join('\n');

    test('trend_summary.dart 不再显式传 20', () async {
      final src = await read('presentation/pages/trend/trend_summary.dart');
      expect(stripComments(src).contains('pageMarginH'), isFalse);
    });

    test('add_medication 3 form 不再显式传 20', () async {
      for (final p in [
        'presentation/pages/medication/widgets/add_medication_step1_form.dart',
        'presentation/pages/medication/widgets/add_medication_step2_form.dart',
        'presentation/pages/medication/widgets/add_medication_step3_form.dart',
      ]) {
        final src = await read(p);
        expect(stripComments(src).contains('pageMarginH'), isFalse, reason: p);
      }
    });

    test('refill_manage_page.dart ALS 不再显式传 20 (页面级 padding 保留)', () async {
      final src =
          await read('presentation/pages/medication/refill_manage_page.dart');
      expect(
        stripComments(src).contains(
          'margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH)',
        ),
        isFalse,
        reason: 'refill 页在 PageScaffold 内, ALS margin 应回默认 zero',
      );
    });

    test('LazyAppleListSection margin 死参数删除 (页边距统一 PageScaffold)', () async {
      final src =
          await read('presentation/widgets/lazy_apple_list_section.dart');
      expect(
        stripComments(src).contains('this.margin'),
        isFalse,
        reason: 'B1-1 引入的 margin 参数 0 caller + build 从未应用 → 删除',
      );
    });
  });
}
