// v0.30 R108 (P0#11, apple-health 5.1.3 抽审): description 禁止声称接入 HealthKit
//
// 背景 (R107 报告 §7 apple-health B-1):
//   R95 P0 task 41 修"hypertension, diabetes" 健康数据相关字眼, 但报告
//   审计时仍有 en-US description:27 残留 (抑郁/焦虑/bipolar/PTSD/ADHD,
//   **hypertension, diabetes**, etc.)。Apple Guideline 5.1.3 抽审风险:
//   "App 在 en-US 描述里声称支持 hypertension/diabetes 但 Info.plist 无
//   HealthKit entitlement + 无 HealthKit UI 入口" = used-but-not-declared
//   抽审模式, 高概率被拒。
//
// 修法 (R108):
//   1) en-US description:27 "hypertension, diabetes" → "and others"
//   2) android en-US full_description.txt 同步改
//   3) 本 lock-in test 防御未来回填 "hypertension"/"diabetes"/"heart disease"
//      /"glucose" 等 HealthKit 相关字段, 触发 Apple 5.1.3 抽审。
//
// 检测目标:
//   - en-US / zh-Hans / zh-Hant 3 份 iOS description
//   - en-US / zh-CN 2 份 Android full_description
//   - 所有 *Text.txt / promotional_text.txt / subtitle.txt (短描述, 高频被审核员扫)
// 锁住: 5 个 description 文件, 任意 1 个出现 health 关键词 → FAIL

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

void main() {
  group('R108 Fix #6: description 禁止 HealthKit 字眼 (Apple 5.1.3)', () {
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
      // 替换表述 "and others" 应在
      expect(
        content.contains('and others') || content.contains('etc.'),
        isTrue,
        reason: 'en-US iOS description 应有概括表述 (and others / etc.)',
      );
    });
  });
}
