// v0.32 round 8 (R111 R111-02 fix): scaleNameL10n / scaleShortDescL10n 派发测试
//
// 背景: 3 处 en 可见位置 (assessment_page AppBar / settings assessment_section /
// 趋势图 tooltip) 之前直接 scale.displayName (const 单例中文 fallback) →
// en 用户看中文量表名。新 helper 走 l10n getter, 本 test 锁:
// 1. 10 量表 zh → 中文名 (跟 ARB 一致)
// 2. 10 量表 en → 英文名 (AppLocalizationsEn getter)
// 3. 未知 id → 原样返回 id (兜底)
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ids = [
    'phq9',
    'gad7',
    'isi',
    'pss',
    'whodas',
    'level2_depression',
    'level2_anxiety',
    'level2_mania',
    'asrm',
    'level2_psychosis',
  ];

  group('v0.32 round 8 (R111-02) — scaleNameL10n 派发', () {
    test('1. zh locale → 10 量表名非空 (ARB 中文)', () {
      final l10n = AppLocalizationsZh();
      for (final id in ids) {
        final name = scaleNameL10n(id, l10n);
        expect(name, isNotEmpty, reason: '$id zh 名非空');
        expect(name, isNot(id), reason: '$id 不能兜底返回 id 自己');
      }
    });

    test('2. en locale → 10 量表名非空且是英文 (R111-02 核心回归)', () {
      final l10n = AppLocalizationsEn();
      for (final id in ids) {
        final name = scaleNameL10n(id, l10n);
        expect(name, isNotEmpty, reason: '$id en 名非空');
        // 英文名不应含中文字符 (en 用户不应看中文)
        expect(
          RegExp(r'[\u4e00-\u9fff]').hasMatch(name),
          isFalse,
          reason: '$id en 名含中文: $name (R111-02 回归)',
        );
      }
    });

    test('3. 未知 id → debug 断言炸 (release 返 id 兜底)', () {
      final l10n = AppLocalizationsZh();
      expect(
        () => scaleNameL10n('unknown_scale', l10n),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => scaleShortDescL10n('unknown_scale', l10n),
        throwsA(isA<AssertionError>()),
      );
    });

    test('4. 10 量表 shortDescription zh/en 非空且非裸 id (全 id 覆盖)', () {
      final zh = AppLocalizationsZh();
      final en = AppLocalizationsEn();
      for (final id in ids) {
        final zhDesc = scaleShortDescL10n(id, zh);
        expect(zhDesc, isNotEmpty, reason: '$id zh 描述');
        expect(zhDesc, isNot(id), reason: '$id zh 描述不能兜底返 id 自己');
        final enDesc = scaleShortDescL10n(id, en);
        expect(enDesc, isNotEmpty, reason: '$id en 描述');
        expect(enDesc, isNot(id), reason: '$id en 描述不能兜底返 id 自己');
        expect(
          RegExp(r'[\u4e00-\u9fff]').hasMatch(enDesc),
          isFalse,
          reason: '$id en 描述含中文: $enDesc',
        );
      }
    });
  });
}
