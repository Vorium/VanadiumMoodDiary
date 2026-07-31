// v0.27 round 67 (C-2 重构): InfoBanner 集中器测试
//
// 验证 4 个 tone 的 bg/fg 颜色对映射 + bordered 开关。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('InfoBanner (R67 C-2)', () {
    testWidgets('1. 默认 tone=info: primaryLight bg + primaryColor fg',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBanner(
              icon: Icons.info_outline,
              text: 'info tone test',
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('info tone test'), findsOneWidget);
      // bg 颜色 = primaryLightColor
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      final ctx = tester.element(find.byType(InfoBanner));
      expect(
        decoration.color,
        equals(AppTokens.primaryLightColor(ctx)),
      );
    });

    testWidgets(
        '2. tone=muted + bordered=true: primaryLight bg + secondary fg + border',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBanner(
              icon: Icons.info_outline,
              text: 'muted test',
              tone: InfoBannerTone.muted,
              bordered: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      // 边框存在
      expect(decoration.border, isNotNull);
      // radius = radiusCard (muted tone)
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(AppTokens.radiusCard)),
      );
    });

    testWidgets('3. tone=warning: tintedWarningSoft bg + warningColor fg',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InfoBanner(
              icon: Icons.warning_amber_outlined,
              text: 'warning test',
              tone: InfoBannerTone.warning,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.text('warning test'), findsOneWidget);
      final context = tester.element(find.byType(InfoBanner));
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppTokens.tintedWarningSoft(context)));
    });
  });
}
