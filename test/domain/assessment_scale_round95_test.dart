// v0.29 Round 95 (#65 修复): assessment_scale 0 测试补齐
//
// 覆盖:
// - HotlineRegion 6 enum 值
// - hotlineByRegion 6 region 各 1+ 项 + cn 兜底
// - CrisisSignal 构造
// - SeverityCutoff 构造 + 边界
// - AssessmentItem 构造
// - AssessmentResult 构造
// - Phq9Scale 关键路径 (id / items 9 个 / options 4 档 / severityCutoffs 5 档 /
//   computeResult 严重度映射 / detectCrisis 第 9 题触发)
// - StaticScaleTranslations 中文 fallback (const 兼容老 caller)
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/phq9.dart';

void main() {
  group('HotlineRegion enum', () {
    test('6 region 值', () {
      expect(HotlineRegion.values, [
        HotlineRegion.cn,
        HotlineRegion.us,
        HotlineRegion.hk,
        HotlineRegion.tw,
        HotlineRegion.sg,
        HotlineRegion.uk,
      ]);
    });
  });

  group('hotlineByRegion 6 region 路由', () {
    test('cn: 全国 + 北京 2 条', () {
      final list = hotlineByRegion[HotlineRegion.cn]!;
      expect(list.length, 2);
      expect(list[0].number, '400-161-9995');
      expect(list[1].number, '010-82951332');
    });

    test('us: 988 + Crisis Text Line 2 条', () {
      final list = hotlineByRegion[HotlineRegion.us]!;
      expect(list.length, 2);
      expect(list[0].number, '988');
      expect(list[1].number, '741741');
    });

    test('hk: 撒玛利亚 1 条', () {
      expect(hotlineByRegion[HotlineRegion.hk]!.length, 1);
      expect(hotlineByRegion[HotlineRegion.hk]!.first.number, '2389 2222');
    });

    test('tw: 生命线 + 安心 2 条', () {
      final list = hotlineByRegion[HotlineRegion.tw]!;
      expect(list.length, 2);
      expect(list[0].number, '1995');
      expect(list[1].number, '1925');
    });

    test('sg: Samaritans 1 条', () {
      expect(hotlineByRegion[HotlineRegion.sg]!.length, 1);
      expect(hotlineByRegion[HotlineRegion.sg]!.first.number, '1800-221-4444');
    });

    test('uk: Samaritans 1 条', () {
      expect(hotlineByRegion[HotlineRegion.uk]!.length, 1);
      expect(hotlineByRegion[HotlineRegion.uk]!.first.number, '116 123');
    });

    test('所有 region number 都是非空 + 不是 0 长度', () {
      for (final region in HotlineRegion.values) {
        final list = hotlineByRegion[region];
        expect(list, isNotNull, reason: '$region 缺失');
        for (final entry in list!) {
          expect(entry.number, isNotEmpty, reason: '$region number 空');
        }
      }
    });
  });

  group('CrisisSignal 构造', () {
    test('title + message + hotlines', () {
      const c = CrisisSignal(
        title: '关心你',
        message: '我们关心你',
        hotlines: [(label: '热线', number: '400-161-9995')],
      );
      expect(c.title, '关心你');
      expect(c.message, '我们关心你');
      expect(c.hotlines.length, 1);
      expect(c.hotlines.first.label, '热线');
    });
  });

  group('SeverityCutoff 构造', () {
    test('threshold + rank + label + summary', () {
      const s = SeverityCutoff(
        threshold: 4,
        rank: 0,
        label: '无',
        summary: '无抑郁',
      );
      expect(s.threshold, 4);
      expect(s.rank, 0);
      expect(s.label, '无');
      expect(s.summary, '无抑郁');
    });
  });

  group('AssessmentItem 构造', () {
    test('index 0-based + text', () {
      const item = AssessmentItem(0, '过去两周内...');
      expect(item.index, 0);
      expect(item.text, '过去两周内...');
    });
  });

  group('AssessmentResult 构造', () {
    test('total + summary + recommend/urgent flags', () {
      const r = AssessmentResult(
        total: 5,
        summary: '轻度',
        recommendDoctorVisit: true,
        urgentDoctorVisit: false,
      );
      expect(r.total, 5);
      expect(r.summary, '轻度');
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isFalse);
    });
  });

  group('Phq9Scale 关键路径', () {
    // v0.27 R78: const phq9Scale 走 StaticScaleTranslations fallback
    const phq9Scale = Phq9Scale();

    test('id == "phq9"', () {
      expect(phq9Scale.id, 'phq9');
    });

    test('totalRange == 27 (PHQ-9 9 题 × 3 上限)', () {
      expect(phq9Scale.totalRange, 27);
    });

    test('items 共 9 题 (0-based index)', () {
      expect(phq9Scale.items.length, 9);
      for (var i = 0; i < 9; i++) {
        expect(phq9Scale.items[i].index, i);
        expect(phq9Scale.items[i].text, isNotEmpty);
      }
    });

    test('options 4 档 (0/1/2/3)', () {
      expect(phq9Scale.options.length, 4);
      expect(phq9Scale.options.keys.toList(), [0, 1, 2, 3]);
      for (final label in phq9Scale.options.values) {
        expect(label, isNotEmpty);
      }
    });

    test('severityCutoffs 5 档 (rank 0-4, threshold 4/9/14/19/27)', () {
      expect(phq9Scale.severityCutoffs.length, 5);
      final thresholds = phq9Scale.severityCutoffs.map((c) => c.threshold).toList();
      expect(thresholds, [4, 9, 14, 19, 27]);
      for (var i = 0; i < 5; i++) {
        expect(phq9Scale.severityCutoffs[i].rank, i);
        expect(phq9Scale.severityCutoffs[i].label, isNotEmpty);
        expect(phq9Scale.severityCutoffs[i].summary, isNotEmpty);
      }
    });

    test('computeResult: 全 0 (total=0) → 无抑郁 (rank 0)', () {
      final r = phq9Scale.computeResult(List.filled(9, 0));
      expect(r.total, 0);
      expect(r.recommendDoctorVisit, isFalse);
      expect(r.urgentDoctorVisit, isFalse);
    });

    test('computeResult: 中度 (total=10) → 建议就诊', () {
      // 9 题共 10 分 (2+1+1+1+1+1+1+1+1)
      final scores = [2, 1, 1, 1, 1, 1, 1, 1, 1];
      final r = phq9Scale.computeResult(scores);
      expect(r.total, 10);
      expect(r.recommendDoctorVisit, isTrue);
    });

    test('computeResult: 重度 (total=20) → 紧急就诊', () {
      // 9 题共 20 分 (3+3+2+2+2+2+2+2+2)
      final scores = [3, 3, 2, 2, 2, 2, 2, 2, 2];
      final r = phq9Scale.computeResult(scores);
      expect(r.total, 20);
      expect(r.recommendDoctorVisit, isTrue);
      expect(r.urgentDoctorVisit, isTrue);
    });

    test('detectCrisis: 第 9 题 (index 8) >= 1 → 危机信号', () {
      final scores = [0, 0, 0, 0, 0, 0, 0, 0, 1];
      final r = phq9Scale.computeResult(scores);
      final signal = phq9Scale.detectCrisis(scores, r);
      expect(signal, isNotNull);
      expect(signal!.title, isNotEmpty);
      expect(signal.message, isNotEmpty);
      expect(signal.hotlines, isNotEmpty);
    });

    test('detectCrisis: 第 9 题 = 0 → 无危机', () {
      final scores = [1, 1, 1, 1, 1, 1, 1, 1, 0];
      final r = phq9Scale.computeResult(scores);
      final signal = phq9Scale.detectCrisis(scores, r);
      expect(signal, isNull);
    });

    test('detectCrisis region=us 走 us hotlines', () {
      final scores = [0, 0, 0, 0, 0, 0, 0, 0, 1];
      final r = phq9Scale.computeResult(scores);
      final signal =
          phq9Scale.detectCrisis(scores, r, region: HotlineRegion.us);
      expect(signal, isNotNull);
      // us hotlines 第 1 条是 988
      expect(signal!.hotlines.first.number, '988');
    });

    test('detectCrisis: scores 长度 < 9 → 无危机 (安全边界)', () {
      final scores = [0, 0, 0];
      final r = phq9Scale.computeResult(scores);
      final signal = phq9Scale.detectCrisis(scores, r);
      expect(signal, isNull);
    });
  });

  group('StaticScaleTranslations fallback', () {
    // v0.27 R78: const 兼容老 caller, StaticScaleTranslations 返中文 fallback
    const translations = StaticScaleTranslations();

    test('phq9Name 返中文', () {
      expect(translations.phq9Name(), isNotEmpty);
    });

    test('phq9Item(0) 返中文题', () {
      expect(translations.phq9Item(0), isNotEmpty);
    });

    test('phq9Option(0..3) 返中文', () {
      for (var i = 0; i < 4; i++) {
        expect(translations.phq9Option(i), isNotEmpty);
      }
    });

    test('phq9SeverityLabel(0..4) 返中文', () {
      for (var i = 0; i < 5; i++) {
        expect(translations.phq9SeverityLabel(i), isNotEmpty);
        expect(translations.phq9SeveritySummary(i), isNotEmpty);
      }
    });

    test('crisisHotlineLabel 6 region × 2 index 兜底', () {
      for (final region in HotlineRegion.values) {
        for (var i = 0; i < 2; i++) {
          expect(
            translations.crisisHotlineLabel(region, index: i),
            isNotEmpty,
            reason: 'region=$region i=$i',
          );
        }
      }
    });
  });
}
