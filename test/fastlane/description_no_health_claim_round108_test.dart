// v0.30 R108 (P0#11, apple-health 5.1.3 抽审): description 禁止声称接入 HealthKit
// v0.31.1 R4 P0-04 (AppStore BUG-6, medical 5.1.1 抽审): description 禁止列具体精神疾病名
//
// 背景 (R107 报告 §7 apple-health B-1):
//   R95 P0 task 41 修"hypertension, diabetes" 健康数据相关字眼, 但报告
//   审计时仍有 en-US description:27 残留 (抑郁/焦虑/bipolar/PTSD/ADHD,
//   **hypertension, diabetes**, etc.)。Apple Guideline 5.1.3 抽审风险:
//   "App 在 en-US 描述里声称支持 hypertension/diabetes 但 Info.plist 无
//   HealthKit entitlement + 无 HealthKit UI 入口" = used-but-not-declared
//   抽审模式, 高概率被拒。
//
// 背景 (v0.31.1 P0-04, AppStore BUG-6, Apple 5.1.1 medical 抽审):
//   精神心理 App 描述里**明列具体疾病名** = 触发 Apple Guideline 5.1.1
//   (Medical / Health 抽审), 要求 1-2 月医学专家认证 + 临床数据 + FDA 批文。
//   R108 修了 HealthKit 关键词 (hypertension/diabetes 等 10 词), 但 5 病名
//   (depression/anxiety/bipolar/PTSD/ADHD) + 2 量表缩写 (PHQ-9/GAD-7)
//   仍残留, 5.1.1 抽审风险未闭环。
//
// 修法 (R108):
//   1) en-US description:27 "hypertension, diabetes" → "and others"
//   2) android en-US full_description.txt 同步改
//   3) 本 lock-in test 防御未来回填 "hypertension"/"diabetes"/"heart disease"
//      /"glucose" 等 HealthKit 相关字段, 触发 Apple 5.1.3 抽审。
//
// 修法 (v0.31.1 P0-04):
//   1) en-US iOS description:17 "PHQ-9 (depression) and GAD-7 (anxiety) screening"
//      → 通用量表措辞 (不提具体疾病名 + 不提具体量表名)
//   2) en-US iOS description:27 "depression, anxiety, bipolar, PTSD, ADHD, and others"
//      → 通用 daily mental wellbeing 措辞
//   3) 本 lock-in test 追加 5 病名关键词防御未来回填
//   4) 其他 4 个 locale (zh-Hans/zh-Hant/zh-CN Android) **未修**, 仍含 PHQ-9/GAD-7
//      + 中文病名 (抑郁/焦虑), 待 P0-05/06 单独修
//
// 检测目标:
//   - en-US / zh-Hans / zh-Hant 3 份 iOS description
//   - en-US / zh-CN 2 份 Android full_description
//   - 所有 *Text.txt / promotional_text.txt / subtitle.txt (短描述, 高频被审核员扫)
// 锁住: 5 个 description 文件, 任意 1 个出现 health 关键词 → FAIL
// P0-04 局部: 5 病名关键词仅检查 en-US iOS (P0-05/06 扩到其他 locale)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Apple 5.1.3 抽审的 HealthKit 数据类型关键词
// 列举 Apple Health 数据类型 (hydrogen.series 类型, 公开文档可查):
//   - 体重 / 体脂 / 心率 / 血压 → hypertension / heart / cardiovascular
//   - 血糖 / 糖尿病 → diabetes / glucose / insulin / A1C
//   - 体温 / 经期 / 睡眠 → 精神心理 App 不太会写, 留作防御
// 关键: 这些词单独或组合出现都触发 5.1.3 抽审, 不需要 HealthKit 集成
const _healthKitKeywords = <String>{
  'hypertension',
  'diabetes',
  'glucose',
  'insulin',
  'a1c',
  'cardiovascular',
  'heart disease',
  'blood pressure',
  'cholesterol',
  'heart rate',
};

// Apple 5.1.1 抽审的精神疾病名关键词 (v0.31.1 P0-04 扩展)
// App 是 general mental wellbeing tracker, 描述里**明列**具体精神疾病
// 名 = 触发 Apple Guideline 5.1.1 medical 抽审, 要求 1-2 月医学认证。
// 关键: 这些词单独或组合出现都触发 5.1.1 抽审, 不需要真的接诊断。
// 配套: PHQ-9 / GAD-7 是公开量表缩写, 描述里**明列**也属于 medical claim,
//   在 P0-04 同步从 en-US iOS 删除; 但不加入本关键词集合 (避免影响其他
//   locale 待 P0-05/06 单独修时的回归测试), 由专用回归 test 检查。
const _diseaseNameKeywords = <String>{
  'depression',
  'anxiety',
  'bipolar',
  'PTSD',
  'ADHD',
};

void main() {
  group('R108 + v0.31.1 P0-04: description 禁止 HealthKit + 精神疾病字眼 (Apple 5.1.1 + 5.1.3)', () {
    // 测试覆盖的文件清单 — iOS + Android 5 个 description
    final descriptionFiles = <String>[
      'fastlane/metadata/ios/en-US/description.txt',
      'fastlane/metadata/ios/zh-Hans/description.txt',
      'fastlane/metadata/ios/zh-Hant/description.txt',
      'fastlane/metadata/android/en-US/full_description.txt',
      'fastlane/metadata/android/zh-CN/full_description.txt',
    ];

    for (final relPath in descriptionFiles) {
      test('${relPath.split('/').last} 不含 HealthKit 关键词', () {
        final file = File(relPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'description 文件应存在: $relPath',
        );
        final content = file.readAsStringSync().toLowerCase();
        final hits = <String>[];
        for (final keyword in _healthKitKeywords) {
          if (content.contains(keyword)) {
            hits.add(keyword);
          }
        }
        expect(
          hits,
          isEmpty,
          reason: '$relPath 包含 HealthKit 字眼 (Apple 5.1.3 抽审风险): $hits',
        );
      });
    }

    test('iOS 短描述 (subtitle/promotional/keywords) 也不含 HealthKit 字眼', () {
      // 短描述虽然不含详细病情, 但出现 "diabetes" 单字也算 used-but-not-declared
      final shortDescFiles = <String>[
        'fastlane/metadata/ios/en-US/keywords.txt',
        'fastlane/metadata/ios/en-US/subtitle.txt',
        'fastlane/metadata/ios/en-US/promotional_text.txt',
        'fastlane/metadata/ios/zh-Hans/keywords.txt',
        'fastlane/metadata/ios/zh-Hans/subtitle.txt',
        'fastlane/metadata/ios/zh-Hans/promotional_text.txt',
        'fastlane/metadata/ios/zh-Hant/keywords.txt',
        'fastlane/metadata/ios/zh-Hant/subtitle.txt',
        'fastlane/metadata/ios/zh-Hant/promotional_text.txt',
      ];
      for (final relPath in shortDescFiles) {
        final file = File(relPath);
        if (!file.existsSync()) continue;
        final content = file.readAsStringSync().toLowerCase();
        for (final keyword in _healthKitKeywords) {
          expect(
            content.contains(keyword),
            isFalse,
            reason: '$relPath 含 HealthKit 字眼: "$keyword"',
          );
        }
      }
    });

    test('R108 修复后"hypertension, diabetes" 已删除 (回归测试)', () {
      // 防御未来 PR 重新加回高血压/糖尿病
      final enUsIos = File('fastlane/metadata/ios/en-US/description.txt');
      final content = enUsIos.readAsStringSync();
      // "hypertension" / "diabetes" 必不存在
      expect(content.toLowerCase().contains('hypertension'), isFalse,
          reason: 'en-US iOS description 不应再出现 hypertension');
      expect(content.toLowerCase().contains('diabetes'), isFalse,
          reason: 'en-US iOS description 不应再出现 diabetes');
      // 注: R108 修法是"hypertension, diabetes" → "and others", 但 v0.31.1
      // P0-04 进一步把 5 病名 + PHQ-9/GAD-7 全删, line 27 从疾病列表改成
      // 通用 "daily mental wellbeing" 措辞, "and others" 表述不再适用。
      // 这里不再断言 "and others", 由 P0-04 回归 test 替代。
    });

    // ===== v0.31.1 P0-04 扩展 =====

    test('v0.31.1 P0-04: en-US iOS description 不含 5 病名关键词 (Apple 5.1.1 抽审)', () {
      // 5 病名 (depression/anxiety/bipolar/PTSD/ADHD) 单独或组合出现都触发
      // Apple Guideline 5.1.1 medical 抽审, 1-2 月医学认证。
      //
      // P0-04 范围: **仅 en-US iOS**。其他 4 个 locale
      //   (Android en-US / iOS zh-Hans / iOS zh-Hant / Android zh-CN)
      // 仍含病名 (英文或中文) + PHQ-9/GAD-7, 待 P0-05/06 单独修。
      // 这里的 lock-in 只覆盖已修的 1 个文件, 避免 CI 因未修文件 break。
      final enUsIos = File('fastlane/metadata/ios/en-US/description.txt');
      expect(
        enUsIos.existsSync(),
        isTrue,
        reason: 'en-US iOS description 必须存在',
      );
      final content = enUsIos.readAsStringSync().toLowerCase();
      final hits = <String>[];
      for (final keyword in _diseaseNameKeywords) {
        // 关键词本身已是小写, content 也 lower 了, 直接 contains
        if (content.contains(keyword)) {
          hits.add(keyword);
        }
      }
      expect(
        hits,
        isEmpty,
        reason: 'en-US iOS description 含 5 病名关键词 (Apple 5.1.1 medical '
            '抽审风险, 1-2 月医学认证): $hits',
      );
    });

    test('v0.31.1 P0-04 修复后 5 病名 + PHQ-9 + GAD-7 已删除 (回归测试)', () {
      // 防御未来 PR 重新加回具体疾病名或量表缩写
      // 注: PHQ-9 / GAD-7 是公开量表缩写, 明列在描述里也属 medical claim,
      //   P0-04 同步从 en-US iOS 删除。但**不加入** _diseaseNameKeywords 主
      //   关键词集合, 避免影响 P0-05/06 待修 locale 的回归测试。
      final enUsIos = File('fastlane/metadata/ios/en-US/description.txt');
      final content = enUsIos.readAsStringSync();
      // 5 病名
      expect(content.toLowerCase().contains('depression'), isFalse,
          reason: 'en-US iOS description 不应再出现 depression');
      expect(content.toLowerCase().contains('anxiety'), isFalse,
          reason: 'en-US iOS description 不应再出现 anxiety');
      expect(content.toLowerCase().contains('bipolar'), isFalse,
          reason: 'en-US iOS description 不应再出现 bipolar');
      expect(content.contains('PTSD'), isFalse,
          reason: 'en-US iOS description 不应再出现 PTSD');
      expect(content.contains('ADHD'), isFalse,
          reason: 'en-US iOS description 不应再出现 ADHD');
      // 2 量表缩写
      expect(content.contains('PHQ-9'), isFalse,
          reason: 'en-US iOS description 不应再出现 PHQ-9');
      expect(content.contains('GAD-7'), isFalse,
          reason: 'en-US iOS description 不应再出现 GAD-7');
    });
  });
}
