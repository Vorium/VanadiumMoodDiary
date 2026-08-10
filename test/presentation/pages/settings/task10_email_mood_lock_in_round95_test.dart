// v0.30 round 95 (sub-spec 2 task 10): email_preview + mood_dialog 删 lock-in
//
// **任务 A1 + A2**:
// - email_preview.dart 整个文件删 (失联是 SMS, 不是 email, R93 业务暂停后
//   真无用), 4 处引用清理: app_route_main.dart 删 /email-preview 路由 +
//   app_shell.dart 删 currentLocation 检查 + reminders_hub_page.dart onAction
//   改 null + assessment_section.dart 删 FeatureFlag 守门 if/else 块。
//   删 9 ARB key (emailPreview* 6 + settingsEmailPreview + emailBodyI18n
//   + emailFooterI18n)。
// - mood_dialog.dart 25 行薄壳 god-pattern 纯转发 → 删文件 + caller
//   (home_page.dart 2 处) 改直接调 MoodRecorderPage.show()。
//
// 跟 R95 sub-spec 2 task 8/25/26 模式一致: 不依赖 widget test (改 .arb 后
// flutter pub get 自动 regen, runtime lock-in 已通过 settings_page_r93_hide_test
// + reminders_hub_round12c_test 验证)。本 test 静态源码 grep 守门, 防御
// 未来 refactor 重新引入这 2 个半成品 widget (emil honest abstraction 原则)。
//
// 6 case:
// 1. email_preview.dart 文件不存在 (R95 task 10 移到 .mavis-trash 目录)
// 2. app_route_main.dart 无 /email-preview 路由
// 3. 3 ARB 文件无 emailPreview* / settingsEmailPreview / emailBodyI18n /
//    emailFooterI18n key
// 4. mood_dialog.dart 文件不存在
// 5. home_page.dart 调 MoodRecorderPage.show() (不调 MoodDialog.show)
// 6. MoodRecorderPage 静态入口仍可用
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email_preview 整文件删 lock-in (R95 sub-spec 2 task 10 A1)', () {
    test('R95 fix 1: email_preview.dart 文件不存在', () {
      // 验证 email_preview.dart 整文件已删 (移到 .mavis-trash)
      final file = File('lib/presentation/pages/settings/email_preview.dart');
      expect(
        file.existsSync(),
        isFalse,
        reason: 'email_preview.dart 应已删, 失联是 SMS 不是 email '
            '(R93 业务暂停后真无用, R95 task 10 移走)',
      );
    });

    test('R95 fix 2: app_route_main.dart 无 /email-preview 路由', () {
      final source = File(
        'lib/core/routing/app_route_main.dart',
      ).readAsStringSync();
      expect(
        source.contains("path: '/email-preview'"),
        isFalse,
        reason: '/email-preview 路由应已删 (失联是 SMS, 真无用)',
      );
      expect(
        source.contains('EmailPreviewPage()'),
        isFalse,
        reason: 'EmailPreviewPage() 实例化应已删',
      );
      // email_preview.dart 字符串只在注释里 (R95 task 10 marker), 验证
      // 真 import 删 (注释中 = 1 处, 真 import = 0 处)
      final importMatches = RegExp(
        r"^import\s+'package:chroniccare/presentation/pages/settings/email_preview\.dart'",
        multiLine: true,
      ).allMatches(source);
      expect(
        importMatches.length,
        0,
        reason: 'email_preview.dart 真 import 应已删, 仅允许注释提及 (R95 marker)',
      );
    });

    test(
        'R95 fix 3: 3 ARB 文件无 emailPreview*/settingsEmailPreview/emailBodyI18n/emailFooterI18n',
        () {
      for (final path in [
        'lib/l10n/app_zh.arb',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_zh_Hant.arb',
      ]) {
        final source = File(path).readAsStringSync();
        for (final key in [
          'emailPreviewTitle',
          'emailPreviewSetupRequired',
          'emailPreviewDescription',
          'emailPreviewNoContact',
          'emailPreviewDisclaimer',
          'settingsEmailPreview',
          'emailBodyI18n',
          'emailFooterI18n',
        ]) {
          expect(
            source.contains('"$key":'),
            isFalse,
            reason: '$path 应已删 $key ARB key (R95 task 10 整 widget 删)',
          );
        }
      }
    });
  });

  group('mood_dialog 整文件删 lock-in (R95 sub-spec 2 task 10 A2)', () {
    test('R95 fix 1: mood_dialog.dart 文件不存在', () {
      final file = File('lib/presentation/pages/mood/mood_dialog.dart');
      expect(
        file.existsSync(),
        isFalse,
        reason: 'mood_dialog.dart 应已删, 25 行薄壳 god-pattern 纯转发 '
            '(emil honest abstraction: caller 直接调 MoodRecorderPage.show)',
      );
    });

    test(
        'R95 fix 2: home_page*.dart 调 MoodRecorderPage.show() (不调 MoodDialog.show)',
        () {
      // R95 sub-spec 6 task 6a fix: R95 sub-spec 4 task 5 拆 home_page → 主壳
      // + home_page_state, MoodRecorderPage.show() 2 caller 都在
      // home_page_state.dart, 主壳 home_page.dart 不再含业务调用
      final homePageSource = File(
        'lib/presentation/pages/home/home_page.dart',
      ).readAsStringSync();
      expect(
        homePageSource.contains('MoodDialog.show('),
        isFalse,
        reason: 'home_page.dart 不应再调 MoodDialog.show (薄壳已删), '
            '应直接调 MoodRecorderPage.show()',
      );

      final homePageStateSource = File(
        'lib/presentation/pages/home/home_page_state.dart',
      ).readAsStringSync();
      // 应有 ≥ 2 处 MoodRecorderPage.show (R95 sub-spec 4 task 5 拆后)
      // onOpenFullDialog + onMoodTap 2 caller 都在 home_page_state.dart
      final matches =
          'MoodRecorderPage.show('.allMatches(homePageStateSource).length;
      expect(
        matches,
        greaterThanOrEqualTo(2),
        reason: 'home_page_state.dart 应有 ≥ 2 处 MoodRecorderPage.show() '
            '(onOpenFullDialog + onMoodTap 2 caller), 实际 $matches',
      );
      // home_page_state.dart 也不应调 MoodDialog.show (薄壳已删)
      expect(
        homePageStateSource.contains('MoodDialog.show('),
        isFalse,
        reason: 'home_page_state.dart 也不应调 MoodDialog.show (薄壳已删)',
      );
    });

    test('R95 fix 3: MoodRecorderPage 静态入口 show() 仍存在', () {
      // 验证 MoodRecorderPage.show 公开 API 仍存在 (caller 调用面不变)
      final source = File(
        'lib/presentation/pages/mood/widgets/mood_recorder_page.dart',
      ).readAsStringSync();
      expect(
        source.contains('static Future<void> show('),
        isTrue,
        reason: 'MoodRecorderPage.show() 静态入口应保留 (caller 改后调用面)',
      );
    });
  });
}
