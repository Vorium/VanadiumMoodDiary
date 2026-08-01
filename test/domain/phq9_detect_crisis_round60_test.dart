// v0.27 round 60 (审计 C1 修正): PHQ-9 detectCrisis + hotlineByRegion 单测
//
// 背景 (audit-domain-layer.md 3.1):
//   - PHQ-9 detectCrisis (lib/domain/logic/phq9.dart:118-133) **0 测试**。
//     v0.25 R51 修正海外用户 hotline routing, 决定 hotline 返回的代码
//     完全无单测保护。
//   - hotlineByRegion 6 region × 2 hotlines = 12 条数据 **0 测试**。
//   - HotlineRegion enum **0 测试**。
//
// 影响: 如果未来改 PHQ-9 第 9 题阈值 (scores[8] >= 1 → >= 2) 或改
// region map, 无测试 fail 提醒 → 用户自杀念头时显示错的危机电话
// = 医疗法律责任。
//
// 修正: 加完整单测覆盖 5 个维度 (阈值 / 边界 / 6 region 路由 / 数据
// 完整性 / enum 完整性)。

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/phq9.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/presentation/services/scale_translations_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // PHQ-9 标准 9 题, 全 0 = 无症状
  List<int> baseScores() => List<int>.filled(9, 0);
  // 制造一个有效 AssessmentResult (detectCrisis 不读 result 字段,
  // 但签名要传, 用 const fallback)
  const stubResult = AssessmentResult(
    total: 0,
    summary: 'stub',
    recommendDoctorVisit: false,
    urgentDoctorVisit: false,
  );

  group('Phq9Scale.detectCrisis — 第 9 题阈值', () {
    test('scores[8] = 0 (无自杀念头) → null', () {
      final s = phq9Scale;
      final scores = baseScores(); // 全 0
      final signal = s.detectCrisis(scores, stubResult);
      expect(signal, isNull);
    });

    test('scores[8] = 1 (阈值边界, 阳性) → CrisisSignal', () {
      final s = phq9Scale;
      final scores = baseScores();
      scores[8] = 1;
      final signal = s.detectCrisis(scores, stubResult);
      expect(signal, isNotNull);
      expect(signal!.title, isNotEmpty);
      expect(signal.message, isNotEmpty);
      expect(signal.hotlines, isNotEmpty);
    });

    test('scores[8] = 3 (几乎每天) → CrisisSignal', () {
      final s = phq9Scale;
      final scores = baseScores();
      scores[8] = 3;
      final signal = s.detectCrisis(scores, stubResult);
      expect(signal, isNotNull);
    });

    test('scores[8] = 1 + 其他题高分 → 仍 CrisisSignal (q9 是关键)', () {
      // 即便总分 < 10 (没建议就医), q9 阳性也必须触发
      final s = phq9Scale;
      final scores = baseScores();
      scores[8] = 1;
      // 其他 8 题全 0 → total = 1 < 10 (无 doctor visit)
      final signal = s.detectCrisis(scores, stubResult);
      expect(signal, isNotNull, reason: 'q9 阳性独立于总分, 必须独立触发');
    });

    test('scores.length = 8 (缺第 9 题) → null (no crash)', () {
      final s = phq9Scale;
      final scores = List<int>.filled(8, 0); // 缺第 9 题
      expect(() => s.detectCrisis(scores, stubResult), returnsNormally);
      expect(s.detectCrisis(scores, stubResult), isNull,
          reason: 'scores.length <= 8 → 不应触发',);
    });

    test('scores.length = 0 (全空) → null (no crash)', () {
      final s = phq9Scale;
      expect(() => s.detectCrisis(const [], stubResult), returnsNormally);
      expect(s.detectCrisis(const [], stubResult), isNull);
    });

    test('scores.length = 100 (超长) → 不应 crash (out of bounds check)', () {
      final s = phq9Scale;
      final scores = List<int>.filled(100, 0);
      scores[8] = 1;
      expect(() => s.detectCrisis(scores, stubResult), returnsNormally);
      // scores.length > 8 + scores[8] >= 1 → 触发
      expect(s.detectCrisis(scores, stubResult), isNotNull);
    });
  });

  group('Phq9Scale.detectCrisis — region 路由 (R51 修正核心)', () {
    void expectHotlineFor(HotlineRegion region, String mustContain) {
      final s = phq9Scale;
      final scores = baseScores();
      scores[8] = 1;
      final signal = s.detectCrisis(scores, stubResult, region: region);
      expect(signal, isNotNull, reason: 'region=$region 应触发');
      expect(signal!.hotlines, hotlineByRegion[region],
          reason: 'region=$region hotlines 必须 = hotlineByRegion[region]',);
      // 校验关键标识
      final allNumbers = signal.hotlines.map((h) => h.number).join('|');
      expect(allNumbers, contains(mustContain),
          reason: 'region=$region 必须含 "$mustContain"',);
    }

    test('region=cn (default) → 400-161-9995 / 010-82951332', () {
      expectHotlineFor(HotlineRegion.cn, '400-161-9995');
    });

    test('region=us → 988 Lifeline', () {
      expectHotlineFor(HotlineRegion.us, '988');
    });

    test('region=hk → 撒玛利亚 2389 2222', () {
      expectHotlineFor(HotlineRegion.hk, '2389');
    });

    test('region=tw → 1995 生命线', () {
      expectHotlineFor(HotlineRegion.tw, '1995');
    });

    test('region=sg → Samaritans of Singapore 1800-221-4444', () {
      expectHotlineFor(HotlineRegion.sg, '1800-221-4444');
    });

    test('region=uk → Samaritans 116 123', () {
      expectHotlineFor(HotlineRegion.uk, '116 123');
    });

    test('detectCrisis 不传 region → 默认 cn (旧行为兼容)', () {
      final s = phq9Scale;
      final scores = baseScores();
      scores[8] = 1;
      final signal = s.detectCrisis(scores, stubResult);
      expect(signal, isNotNull);
      expect(signal!.hotlines, hotlineByRegion[HotlineRegion.cn]);
    });
  });

  group('hotlineByRegion — 数据完整性 (CI 守门员可参考)', () {
    test('6 region 全覆盖, 无 missing', () {
      // 修正: 防止未来加 region 时漏配 hotlines
      for (final region in HotlineRegion.values) {
        expect(hotlineByRegion.containsKey(region), isTrue,
            reason: 'region=$region 必须在 hotlineByRegion',);
        expect(hotlineByRegion[region], isNotEmpty,
            reason: 'region=$region 必须有 ≥1 条 hotline',);
      }
    });

    test('每条 hotline label 和 number 非空', () {
      for (final region in HotlineRegion.values) {
        for (final h in hotlineByRegion[region]!) {
          expect(h.label, isNotEmpty,
              reason: 'region=$region 某条 hotline label 为空',);
          expect(h.number, isNotEmpty,
              reason: 'region=$region 某条 hotline number 为空',);
        }
      }
    });

    test('电话格式 sanity: 全部 hotline number 仅含数字/横线/空格/+', () {
      // 防止未来误填带字母的电话 (除了 Criris Text Line "text HOME"
      // 那种特殊 case, 暂时统一要求纯数字 + 标点)
      for (final region in HotlineRegion.values) {
        for (final h in hotlineByRegion[region]!) {
          // 允许数字 / 横线 / 空格 / 加号, 不允许字母
          final ok = RegExp(r'^[0-9\-\s\+()]+$').hasMatch(h.number);
          expect(ok, isTrue,
              reason: 'region=$region number "${h.number}" 含非数字/标点字符',);
        }
      }
    });

    test('每 region 至少 1 条 ≤ 2 条 (海外 1 条, 大陆 2 条)', () {
      // 修正动机: 防止某 region 突然被填 0 条 或 5 条 (data quality)
      for (final region in HotlineRegion.values) {
        final count = hotlineByRegion[region]!.length;
        expect(count, inInclusiveRange(1, 2),
            reason: 'region=$region 有 $count 条 hotline, 异常',);
      }
    });

    test('cn 有 2 条 (全国 + 北京中心), 其他 region 各 1-2 条', () {
      expect(hotlineByRegion[HotlineRegion.cn]!.length, 2);
    });
  });

  group('HotlineRegion enum', () {
    test('恰好 6 values (cn/us/hk/tw/sg/uk)', () {
      expect(HotlineRegion.values.length, 6);
    });

    test('所有 values 唯一', () {
      final set = HotlineRegion.values.toSet();
      expect(set.length, HotlineRegion.values.length);
    });
  });

  // v0.27 R77 (spzh P1-A 收尾): Phq9Scale.detectCrisis hotlines label 走
  // translations.crisisHotlineLabel (region, index), 6 region × 2 hotline
  // 全 i18n 化。注入 AppLocalizationsScaleTranslations(en) 验证 en label
  // ≠ hotlineByRegion[region][i].label (中文 fallback)。
  group('Phq9Scale.detectCrisis — hotlines label 走 translations (R77 收尾)', () {
    final enL10n = AppLocalizationsEn();
    final enTranslations = AppLocalizationsScaleTranslations(enL10n);
    final scale = Phq9Scale(translations: enTranslations);
    final scores = List<int>.filled(9, 0)..[8] = 1; // q9 阳性

    test('cn 返 2 条 en label (≠ const 中文 fallback)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.cn);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 2);
      expect(signal.hotlines[0].label, 'National 24h Psychological Aid Hotline');
      expect(signal.hotlines[1].label, 'Beijing Suicide Research & Prevention Center');
    });

    test('us 返 2 条 en label (988 + Crisis Text Line)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.us);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 2);
      expect(signal.hotlines[0].number, '988');
      expect(signal.hotlines[1].number, '741741');
    });

    test('tw 返 2 条 en label (Lifeline + 1925)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.tw);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 2);
      expect(signal.hotlines[0].label, 'Lifeline Taiwan (24h)');
      expect(signal.hotlines[1].label, '1925 Mental Health Counseling Line');
    });

    test('hk 返 1 条 en label (Samaritans HK)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.hk);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 1);
      expect(signal.hotlines[0].label, contains('Samaritans'));
    });

    test('sg 返 1 条 en label (Samaritans Singapore)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.sg);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 1);
      expect(signal.hotlines[0].label, 'Samaritans of Singapore (24h)');
    });

    test('uk 返 1 条 en label (Samaritans UK)', () {
      final signal = scale.detectCrisis(scores, stubResult, region: HotlineRegion.uk);
      expect(signal, isNotNull);
      expect(signal!.hotlines.length, 1);
      expect(signal.hotlines[0].label, 'Samaritans UK & ROI (24h free)');
    });
  });
}
