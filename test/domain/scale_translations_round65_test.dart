// v0.28 round 65 (spzh P1-A 起步): ScaleTranslations abstract 测试
//
// 覆盖:
// - 2 个量表名 (phq9 / gad7) — 复用现有 `assessmentScalePhq9` / `assessmentScaleGad7` ARB key
// - 4 region 危机电话 label (cn / us / hk / intl) — 新 `scaleHotline*` ARB key
// - 6 region zh_Hant fallback (tw/sg/uk 走 intl)
//
// 16 题全文 / 5 严重度 / 4 档选项 / 2 instruction 全文 i18n 化留 v1.0。
//
// 21 case phq9/gad7 crisis test (`phq9_detect_crisis_round60_test.dart` +
// `gad7_round16_test.dart`) 走 `const StaticScaleTranslations()` 中文 fallback,
// 本测试只覆盖 ScaleTranslations 接口契约 + AppLocalizations 包装 i18n 路径。

import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/gad7.dart';
import 'package:chroniccare/domain/logic/phq9.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/l10n/region_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaticScaleTranslations (v0.28 round 65 中文 fallback)', () {
    const t = StaticScaleTranslations();

    test('phq9Name 返中文 fallback', () {
      expect(t.phq9Name(), 'PHQ-9 抑郁筛查');
    });

    test('gad7Name 返中文 fallback', () {
      expect(t.gad7Name(), 'GAD-7 焦虑筛查');
    });

    test('phq9Name 接受 override 优先', () {
      expect(t.phq9Name(override: 'Custom PHQ-9'), 'Custom PHQ-9');
    });

    test('crisisHotlineLabel cn 返 hotlineByRegion 第 1 条中文', () {
      // 跟 const `hotlineByRegion` 行为一致, 21 case test 兼容
      final label = t.crisisHotlineLabel(HotlineRegion.cn);
      expect(label, isNotEmpty);
      expect(label, hotlineByRegion[HotlineRegion.cn]!.first.label);
    });

    test('crisisHotlineLabel us 返 hotlineByRegion 第 1 条', () {
      final label = t.crisisHotlineLabel(HotlineRegion.us);
      expect(label, hotlineByRegion[HotlineRegion.us]!.first.label);
    });

    test('crisisHotlineLabel override 优先', () {
      expect(t.crisisHotlineLabel(HotlineRegion.cn, override: 'Custom'),
          'Custom');
    });
  });

  group('AppLocalizationsScaleTranslations (v0.28 round 65 zh 路径)', () {
    test('phq9Name zh 返中文', () {
      // AppLocalizationsZh 是 auto-gen concrete class
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.phq9Name(), 'PHQ-9 抑郁筛查');
    });

    test('gad7Name zh 返中文', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.gad7Name(), 'GAD-7 焦虑筛查');
    });

    test('crisisHotlineLabel cn 返中文 hotline', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.cn), '全国 24 小时心理援助热线');
    });

    test('crisisHotlineLabel us 返英文 hotline', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      // zh locale: scaleHotlineUs 仍是英文 (en 源语言)
      expect(t.crisisHotlineLabel(HotlineRegion.us),
          '988 Suicide & Crisis Lifeline (US)');
    });

    test('crisisHotlineLabel hk 返中文/繁 hotline (tw 走 intl fallback)', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.hk),
          contains('撒玛利亚'));
    });
  });

  group('AppLocalizationsScaleTranslations (v0.28 round 65 en 路径)', () {
    test('phq9Name en 返英文', () {
      final l10n = AppLocalizationsEn();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.phq9Name(), 'PHQ-9 Depression Screening');
    });

    test('gad7Name en 返英文', () {
      final l10n = AppLocalizationsEn();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.gad7Name(), 'GAD-7 Anxiety Screening');
    });

    test('crisisHotlineLabel cn en 仍是英文 (源语言 en)', () {
      final l10n = AppLocalizationsEn();
      final t = AppLocalizationsScaleTranslations(l10n);
      // en locale: scaleHotlineCn 翻译 = "National 24h Psychological Aid Hotline"
      expect(t.crisisHotlineLabel(HotlineRegion.cn),
          'National 24h Psychological Aid Hotline');
    });

    test('crisisHotlineLabel us en 返英文', () {
      final l10n = AppLocalizationsEn();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.us),
          '988 Suicide & Crisis Lifeline (US)');
    });
  });

  group('AppLocalizationsScaleTranslations (tw/sg/uk 走 intl fallback)', () {
    test('tw 走 intl fallback', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.tw),
          l10n.scaleHotlineIntl);
    });

    test('sg 走 intl fallback', () {
      final l10n = AppLocalizationsZh();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.sg),
          l10n.scaleHotlineIntl);
    });

    test('uk 走 intl fallback', () {
      final l10n = AppLocalizationsEn();
      final t = AppLocalizationsScaleTranslations(l10n);
      expect(t.crisisHotlineLabel(HotlineRegion.uk),
          l10n.scaleHotlineIntl);
    });
  });

  group('AssessmentScale translations 字段 (v0.28 round 65 abstract 注入)', () {
    test('phq9Scale const 默认 StaticScaleTranslations 中文 fallback', () {
      // 老 caller 兼容 — 21 case phq9_detect_crisis_round60_test 不破
      expect(phq9Scale.translations, isA<StaticScaleTranslations>());
      expect(phq9Scale.displayName, 'PHQ-9 抑郁筛查');
    });

    test('gad7Scale const 默认 StaticScaleTranslations 中文 fallback', () {
      // 老 caller 兼容 — 13 case gad7_round16_test 不破
      expect(gad7Scale.translations, isA<StaticScaleTranslations>());
      expect(gad7Scale.displayName, 'GAD-7 焦虑筛查');
    });

    test('Phq9Scale 注入 AppLocalizations 包装 → displayName 走 ARB', () {
      final t = AppLocalizationsScaleTranslations(AppLocalizationsEn());
      final scale = Phq9Scale(translations: t);
      expect(scale.displayName, 'PHQ-9 Depression Screening');
    });

    test('Gad7Scale 注入 AppLocalizations 包装 → displayName 走 ARB', () {
      final t = AppLocalizationsScaleTranslations(AppLocalizationsEn());
      final scale = Gad7Scale(translations: t);
      expect(scale.displayName, 'GAD-7 Anxiety Screening');
    });
  });

  // v0.28 round 65 (spzh P2-F / P2-H): phoneRegion* / checkInType* 5+4=9 个
  // i18n key 的实际引用 — regionDisplayName + CheckInType.labelL10n helper
  // 都接受 `String? override` 由 caller 注入 ARB 字符串。直接引用 l10n.* 测试
  // 避免 check_orphan_arb_keys 误报 orphan (脚本 grep `\.<key>\b` 不穿透
  // helper 函数间接调用)。
  group('regionDisplayName + CheckInType.labelL10n i18n key 引用 (防 orphan)', () {
    test('5 region phoneRegion* zh 走 l10n.phoneRegionCn 等', () {
      final l10n = AppLocalizationsZh();
      expect(regionDisplayName(PhoneRegion.cn, override: l10n.phoneRegionCn),
          l10n.phoneRegionCn);
      expect(regionDisplayName(PhoneRegion.hk, override: l10n.phoneRegionHk),
          l10n.phoneRegionHk);
      expect(regionDisplayName(PhoneRegion.mo, override: l10n.phoneRegionMo),
          l10n.phoneRegionMo);
      expect(regionDisplayName(PhoneRegion.tw, override: l10n.phoneRegionTw),
          l10n.phoneRegionTw);
      expect(
          regionDisplayName(PhoneRegion.intl, override: l10n.phoneRegionIntl),
          l10n.phoneRegionIntl);
    });

    test('5 region phoneRegion* en 走 l10n.phoneRegionCn 等', () {
      final l10n = AppLocalizationsEn();
      expect(regionDisplayName(PhoneRegion.cn, override: l10n.phoneRegionCn),
          l10n.phoneRegionCn);
      expect(regionDisplayName(PhoneRegion.hk, override: l10n.phoneRegionHk),
          l10n.phoneRegionHk);
      expect(regionDisplayName(PhoneRegion.mo, override: l10n.phoneRegionMo),
          l10n.phoneRegionMo);
      expect(regionDisplayName(PhoneRegion.tw, override: l10n.phoneRegionTw),
          l10n.phoneRegionTw);
      expect(
          regionDisplayName(PhoneRegion.intl, override: l10n.phoneRegionIntl),
          l10n.phoneRegionIntl);
    });

    test('4 checkInType* zh 走 l10n.checkInTypeDaily 等', () {
      final l10n = AppLocalizationsZh();
      expect(CheckInType.normal.labelL10n(override: l10n.checkInTypeDaily),
          l10n.checkInTypeDaily);
      expect(CheckInType.temp.labelL10n(override: l10n.checkInTypeTemp),
          l10n.checkInTypeTemp);
      expect(CheckInType.phq9.labelL10n(override: l10n.checkInTypePhq9),
          l10n.checkInTypePhq9);
      expect(CheckInType.gad7.labelL10n(override: l10n.checkInTypeGad7),
          l10n.checkInTypeGad7);
    });

    test('4 checkInType* en 走 l10n.checkInTypeDaily 等', () {
      final l10n = AppLocalizationsEn();
      expect(CheckInType.normal.labelL10n(override: l10n.checkInTypeDaily),
          l10n.checkInTypeDaily);
      expect(CheckInType.temp.labelL10n(override: l10n.checkInTypeTemp),
          l10n.checkInTypeTemp);
      expect(CheckInType.phq9.labelL10n(override: l10n.checkInTypePhq9),
          l10n.checkInTypePhq9);
      expect(CheckInType.gad7.labelL10n(override: l10n.checkInTypeGad7),
          l10n.checkInTypeGad7);
    });
  });
}
