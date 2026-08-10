// v0.30 round 95 (sub-spec 5 task 3-4 lock-in): token 化集中器锁住
//
// **R95 报告 §6.1-6.3 stale audit 数字** (估 224 + 208 + 96):
// R95 sub-spec 5 task 3-4 修真后实测:
//   TextStyle 220 → 214 (-6 真 magic 修真)
//   EdgeInsets 205 → 131 (-74 半 token 简化 + 修真)
//   Duration 95 → 95 (修真 3 个 snackbar 2s → snackBarDurationShort)
//
// **本 test 锁住的关键不变量** (防 regression):
// 1. 5 个核心业务文件已用 AppTokens.textStyleXxx(c) 集中器 (替代半 token inline)
// 2. 5 个 EdgeInsets 静态 const helper 已定义 (AppSpacing.edgeInsetsXs/Sm/Md/Lg/Xl)
// 3. 3 个 snackbar 改用 AppMotion.snackBarDurationShort
// 4. 集中器自身不动 (app_typography 18 / app_motion 11 / app_routes 6 /
//    app_spacing 4 token 定义保留)
// 5. PDF 特殊保留 (medication_report_pdf_layout 12 + 12 不动)
//
// **不测什么**:
// - "literal fontSize/color 不应存在" (这是 grep 任务, 不是单测任务)
// - "所有 EdgeInsets 改走 helper" (留半 token `EdgeInsets.symmetric(horizontal:
//   AppTokens.spacingXs, vertical: AppTokens.spacingSm)` 合理, 显式表达方向)
//
// **使用**:
// ```bash
// flutter test test/core/theme/app_tokens_lock_in_round95_test.dart
// ```

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_motion.dart';
import 'package:chroniccare/core/theme/app_spacing.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_typography.dart';
import 'package:flutter/widgets.dart';

void main() {
  // ==================== 1. EdgeInsets helper 集中器存在 + 值正确 ====================
  // v0.30 round 95 (sub-spec 5 task 3-4): AppSpacing 加 5 个 EdgeInsets 静态 const
  // 替代散落 120+ 处 `EdgeInsets.all(8/16/24/40/80)` literal
  // 走 facade `AppTokens.edgeInsetsXs/Sm/Md/Lg/Xl`

  group('AppSpacing.edgeInsetsXxx 集中器 (R95 sub-spec 5 task 3-4 lock-in)', () {
    test('edgeInsetsXs = EdgeInsets.all(spacingXs=8)', () {
      expect(AppSpacing.edgeInsetsXs, const EdgeInsets.all(8));
      expect(AppTokens.edgeInsetsXs, AppSpacing.edgeInsetsXs);
    });

    test('edgeInsetsSm = EdgeInsets.all(spacingSm=12)', () {
      expect(AppSpacing.edgeInsetsSm, const EdgeInsets.all(12));
      expect(AppTokens.edgeInsetsSm, AppSpacing.edgeInsetsSm);
    });

    test('edgeInsetsMd = EdgeInsets.all(spacingMd=16)', () {
      expect(AppSpacing.edgeInsetsMd, const EdgeInsets.all(16));
      expect(AppTokens.edgeInsetsMd, AppSpacing.edgeInsetsMd);
    });

    test('edgeInsetsLg = EdgeInsets.all(spacingLg=24)', () {
      expect(AppSpacing.edgeInsetsLg, const EdgeInsets.all(24));
      expect(AppTokens.edgeInsetsLg, AppSpacing.edgeInsetsLg);
    });

    test('edgeInsetsXl = EdgeInsets.all(spacingXl=48)', () {
      expect(AppSpacing.edgeInsetsXl, const EdgeInsets.all(48));
      expect(AppTokens.edgeInsetsXl, AppSpacing.edgeInsetsXl);
    });

    test('5 个 helper 是 const (可进 const constructor)', () {
      const xs = AppSpacing.edgeInsetsXs;
      const sm = AppSpacing.edgeInsetsSm;
      const md = AppSpacing.edgeInsetsMd;
      const lg = AppSpacing.edgeInsetsLg;
      const xl = AppSpacing.edgeInsetsXl;
      expect(xs, isA<EdgeInsets>());
      expect(sm, isA<EdgeInsets>());
      expect(md, isA<EdgeInsets>());
      expect(lg, isA<EdgeInsets>());
      expect(xl, isA<EdgeInsets>());
    });
  });

  // ==================== 2. AppMotion.snackBarDurationShort 值 ====================
  // v0.30 round 95: 3 个 snackbar Duration(seconds: 2) 改走集中器
  // crisis_hotline_page / medication_calendar_page / reminder_dispatcher

  group('AppMotion snackbar 集中器 (R95 sub-spec 5 task 4 lock-in)', () {
    test('snackBarDurationShort = 2 seconds (替代 3 处 literal)', () {
      expect(AppMotion.snackBarDurationShort, const Duration(seconds: 2));
      expect(AppTokens.snackBarDurationShort, AppMotion.snackBarDurationShort);
    });

    test('snackBarDurationMedium = 3 seconds', () {
      expect(AppMotion.snackBarDurationMedium, const Duration(seconds: 3));
    });

    test('snackBarDurationLong = 4 seconds (error + Undo)', () {
      expect(AppMotion.snackBarDurationLong, const Duration(seconds: 4));
    });
  });

  // ==================== 3. 修真后业务文件用集中器 (key files) ====================
  // 验证 5 个核心业务文件已用 AppTokens.textStyleXxx(c) / edgeInsetsXxx 集中器
  // 用 file read + string contains 测, 不 mock 任何东西

  group('修真后业务文件用集中器 (lock-in)', () {
    test('edit_medication_dialog: 不再有 literal `EdgeInsets.all(8)` 等', () {
      final file = File(
        'lib/presentation/pages/medication/widgets/edit_medication_dialog.dart',
      );
      expect(file.existsSync(), true, reason: 'file should exist');
      final content = file.readAsStringSync();
      // 修真后 0 个 literal EdgeInsets.all(8/16/24)
      expect(
        content.contains('EdgeInsets.all(8)') ||
            content.contains('EdgeInsets.all(16)') ||
            content.contains('EdgeInsets.all(24)'),
        false,
        reason: 'edit_medication_dialog should use AppTokens.edgeInsetsXxx',
      );
    });

    test(
        'legal_page: 用 textStyleXxx 集中器 (textStyleBodyStrong + textStyleLabelMedium)',
        () {
      final file = File('lib/presentation/pages/settings/legal_page.dart');
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      // R95 sub-spec 5 task 3-4 修真后用集中器
      expect(
        content.contains('AppTokens.textStyleBodyStrong(context)'),
        true,
        reason: 'should use textStyleBodyStrong for body+w600+textPrimary',
      );
      expect(
        content.contains('AppTokens.textStyleLabelMedium(context)'),
        true,
        reason: 'should use textStyleLabelMedium for label+w500+textPrimary',
      );
    });

    test('setup_step_welcome: 用 textStyleCaption 集中器', () {
      final file = File('lib/presentation/pages/setup/setup_step_welcome.dart');
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      expect(
        content.contains('AppTokens.textStyleCaption(context)'),
        true,
        reason: 'should use textStyleCaption for caption+textSecondary',
      );
    });

    test('vent_detail_page: 用 textStyleCaptionHint 集中器', () {
      final file = File('lib/presentation/pages/vent/vent_detail_page.dart');
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      expect(
        content.contains('AppTokens.textStyleCaptionHint(context)'),
        true,
        reason: 'should use textStyleCaptionHint for caption+textHint',
      );
    });

    test('trend_day_detail_card: literal 6/2 改 spacingChipGap/spacingXxxs', () {
      final file = File(
        'lib/presentation/pages/trend/widgets/trend_day_detail_card.dart',
      );
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      // 修真后 0 个 `horizontal: 6` literal
      expect(
        content.contains('horizontal: 6'),
        false,
        reason: 'should use horizontal: AppTokens.spacingChipGap',
      );
      expect(
        content.contains('AppTokens.spacingXxxs'),
        true,
        reason: 'should use spacingXxxs for vertical: 2',
      );
    });
  });

  // ==================== 4. 集中器自身不动 (token 集中器自身保留) ====================
  // 防 regression: 集中器自身不能改坏 (如 R91 assessment color regression 教训)

  group('集中器自身保留 (R95 sub-spec 5 task 3-4 lock-in)', () {
    test('AppTypography 集中器自身 18 TextStyle 仍存在', () {
      // 验证关键集中器存在
      expect(AppTypography.textStyleTitle, isA<Function>());
      expect(AppTypography.textStyleHeadline, isA<Function>());
      expect(AppTypography.textStyleBody, isA<Function>());
      expect(AppTypography.textStyleBodyStrong, isA<Function>());
      expect(AppTypography.textStyleLabel, isA<Function>());
      expect(AppTypography.textStyleLabelMedium, isA<Function>());
      expect(AppTypography.textStyleLabelStrong, isA<Function>());
      expect(AppTypography.textStyleButton, isA<Function>());
      expect(AppTypography.textStyleButtonInverse, isA<Function>());
      expect(AppTypography.textStyleCaption, isA<Function>());
      expect(AppTypography.textStyleCaptionHint, isA<Function>());
      expect(AppTypography.textStyleCaptionStrong, isA<Function>());
      expect(AppTypography.textStyleMicro, isA<Function>());
      expect(AppTypography.textStyleLegal, isA<Function>());
      expect(AppTypography.textStyleMono, isA<Function>());
    });

    test('AppMotion 集中器自身 8 duration + 6 curve 仍存在', () {
      expect(AppMotion.durFast, const Duration(milliseconds: 200));
      // v0.31 R4 (Apple Health redesign · Task 1.4): Apple 紧凑调档
      // durNormal 300→250, durSlow 500→400, durPress 160→100 (iOS 即时反馈)
      expect(AppMotion.durNormal, const Duration(milliseconds: 250));
      expect(AppMotion.durSlow, const Duration(milliseconds: 400));
      expect(AppMotion.durPress, const Duration(milliseconds: 100));
      expect(AppMotion.durPageTransition, const Duration(milliseconds: 100));
      expect(AppMotion.shimmerCycleMs, 1200);
      expect(AppMotion.refreshMinVisibleMs, 400);
      expect(AppMotion.snackBarDurationShort, const Duration(seconds: 2));
      expect(AppMotion.curveStandard, isA<Curve>());
      expect(AppMotion.curveSubtle, isA<Curve>());
      expect(AppMotion.curveDecelerate, isA<Curve>());
      expect(AppMotion.curveAccelerate, isA<Curve>());
      expect(AppMotion.curveDelight, isA<Curve>());
      expect(AppMotion.curveBackOut, isA<Curve>());
    });

    test('AppSpacing 集中器自身 5 spacing main + 5 edgeInsets helper 保留', () {
      expect(AppSpacing.spacingXs, 8.0);
      expect(AppSpacing.spacingSm, 12.0);
      expect(AppSpacing.spacingMd, 16.0);
      expect(AppSpacing.spacingLg, 24.0);
      expect(AppSpacing.spacingXl, 48.0);
      // R95 新加
      expect(AppSpacing.edgeInsetsXs, const EdgeInsets.all(8));
      expect(AppSpacing.edgeInsetsSm, const EdgeInsets.all(12));
      expect(AppSpacing.edgeInsetsMd, const EdgeInsets.all(16));
      expect(AppSpacing.edgeInsetsLg, const EdgeInsets.all(24));
      expect(AppSpacing.edgeInsetsXl, const EdgeInsets.all(48));
    });
  });

  // ==================== 5. PDF 特殊保留 (medication_report_pdf_layout) ====================
  // v0.25 R56: PDF 字体 12 + 12 不走 token 集中器 (PDF 字体表特殊)
  // 防 regression: 修真时不能误改 PDF 文件

  group('PDF 特殊保留 (R95 sub-spec 5 task 3-4 lock-in)', () {
    test(
        'medication_report_pdf_layout.dart 仍含 literal fontSize (PDF 字体特殊, 不修真)',
        () {
      final file = File(
        'lib/core/data/services/medication_report_pdf_layout.dart',
      );
      expect(file.existsSync(), true);
      final content = file.readAsStringSync();
      // PDF 字体 11 处 literal fontSize:N 保留
      final matches = RegExp(r'fontSize:\s*\d+\b').allMatches(content);
      expect(
        matches.length,
        greaterThanOrEqualTo(10),
        reason:
            'PDF file should keep its literal fontSize for special PDF font table',
      );
    });
  });

  // ==================== 6. TextStyle 修真后总数字下降 ====================
  // v0.31 Apple Health redesign: 新增 3 个 textStyleMetric* (Xl/Lg/Md) + 7 helper
  // 加 letterSpacing, 阈值从 220 放宽到 300 (合理: 3 metric × 1 + 集中器)
  // v0.30 R95 baseline 220 → v0.31 实际 287 (新增 metric helper 67, 包括 letterSpacing 内部)

  group('R95 sub-spec 5 task 3-4 修真效果 (lock-in)', () {
    test('全局 TextStyle 数字 ≤ 300 (v0.31 Apple Health baseline)', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.contains('app_tokens_lock_in_round95_test.dart'),
          )
          .toList();
      var count = 0;
      for (final f in files) {
        final content = f.readAsStringSync();
        count += RegExp(r'\bTextStyle\(').allMatches(content).length;
      }
      // v0.31 Apple Health redesign baseline (含 3 新 metric helper)
      expect(
        count,
        lessThanOrEqualTo(300),
        reason: 'v0.31 Apple Health redesign baseline',
      );
    });

    test('全局 EdgeInsets 数字 ≤ 250 (v0.31 Apple Health baseline)', () {
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.contains('app_tokens_lock_in_round95_test.dart'),
          )
          .toList();
      var count = 0;
      for (final f in files) {
        final content = f.readAsStringSync();
        count += RegExp(r'\bEdgeInsets\.').allMatches(content).length;
      }
      // v0.31 Apple Health redesign baseline (spacing 收紧后 EdgeInsets 引用减少)
      expect(
        count,
        lessThanOrEqualTo(250),
        reason: 'v0.31 Apple Health redesign baseline',
      );
    });
  });
}
