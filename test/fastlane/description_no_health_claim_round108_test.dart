// v0.30 R108 (P0#11, apple-health 5.1.3 抽审): description 禁止声称接入 HealthKit
// v0.31.1 R4 P0-04 (AppStore BUG-6, medical 5.1.1 抽审): description 禁止列具体精神疾病名
// v0.31.1 R5 P0-04b: 4 其他 locale (zh-Hans/zh-Hant iOS + en-US/zh-CN Android) 同步修
//   + 守门员从 1 locale 扩到 5 locale, 关键词加 4 中文病名 (抑郁/焦虑/憂鬱/焦慮)
//   + 2 量表缩写 (PHQ-9/GAD-7)
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
//   4) P0-04 修 1 个 locale (en-US iOS), 其他 4 个 locale 由 P0-04b 同步修
//
// 修法 (v0.31.1 P0-04b, R5, AppStore BUG-6 衍生 + GooglePlay 5.1.3 抽审):
//   1) iOS zh-Hans/zh-Hant description:18 PHQ-9/GAD-7 + 中文病名 → 通用量表
//   2) Android en-US full_description.txt:17 + :27 同步改
//   3) Android zh-CN full_description.txt:18 PHQ-9/GAD-7 + 中文病名 → 通用量表
//   4) 守门员扩到 5 locale, 关键词加 4 中文病名 (抑郁/焦虑/憂鬱/焦虑) + 2 量表缩写
//
// 检测目标:
//   - en-US / zh-Hans / zh-Hant 3 份 iOS description
//   - en-US / zh-CN 2 份 Android full_description
//   - 所有 *Text.txt / promotional_text.txt / subtitle.txt (短描述, 高频被审核员扫)
// 锁住: 5 个 description 文件, 任意 1 个出现 health/疾病/量表 关键词 → FAIL
// P0-04b: 5 病名 + 中文病名 + PHQ-9/GAD-7 全部 locale 防御

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

// Apple 5.1.1 抽审的精神疾病名关键词 (v0.31.1 P0-04 扩展, P0-04b 加中文)
// App 是 general mental wellbeing tracker, 描述里**明列**具体精神疾病
// 名 = 触发 Apple Guideline 5.1.1 medical 抽审, 要求 1-2 月医学认证。
// 关键: 这些词单独或组合出现都触发 5.1.1 抽审, 不需要真的接诊断。
//
// 全部以小写形式存储, 比较时对 content 做 toLowerCase() (CJK 字符不受影响),
// 修复 P0-04 时 'PTSD'/'ADHD' 大写关键词 + content.toLowerCase() 导致永远
// 命中不到的 silent bug (当时测试 vacuously pass 是因为文件已修, 但若有人
// 加回 'ptsd' 小写形式测试也漏报)。
//
// 配套: PHQ-9 / GAD-7 是公开量表缩写, 描述里**明列**也属于 medical claim,
// 由 _scaleAbbreviations 单独管理, 语义更清晰 (疾病名 vs 量表缩写)。
const _diseaseNameKeywords = <String>{
  // English (5)
  'depression',
  'anxiety',
  'bipolar',
  'ptsd',
  'adhd',
  // Chinese Simplified (2)
  '抑郁',
  '焦虑',
  // Chinese Traditional (2)
  '憂鬱',
  '焦慮',
};

// 公开心理量表缩写 (P0-04b 扩展, 5 locale 全部防御)
// PHQ-9 (Patient Health Questionnaire) / GAD-7 (Generalized Anxiety Disorder)
// 是临床常用的抑郁/焦虑筛查量表, 描述里明列也属 medical claim。
const _scaleAbbreviations = <String>{
  'phq-9',
  'gad-7',
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
          reason: 'en-US iOS description 不应再出现 hypertension',);
      expect(content.toLowerCase().contains('diabetes'), isFalse,
          reason: 'en-US iOS description 不应再出现 diabetes',);
      // 注: R108 修法是"hypertension, diabetes" → "and others", 但 v0.31.1
      // P0-04 进一步把 5 病名 + PHQ-9/GAD-7 全删, line 27 从疾病列表改成
      // 通用 "daily mental wellbeing" 措辞, "and others" 表述不再适用。
      // 这里不再断言 "and others", 由 P0-04 回归 test 替代。
    });

    // ===== v0.31.1 P0-04 + P0-04b 扩展 =====

    // P0-04b: 把 5 病名 + 中文病名 关键词检查从 en-US iOS 1 个 locale 扩到
    // 5 个 locale (iOS 3 + Android 2)。每个文件 1 个独立 test, 失败信息
    // 精确到文件, 便于后续 PR 修哪 1 个 locale。
    for (final relPath in descriptionFiles) {
      test(
        'v0.31.1 P0-04b: ${relPath.split('/').last} 不含 5 病名 + 中文病名关键词 '
        '(Apple 5.1.1 + GooglePlay 5.1.3 抽审)',
        () {
          // 5 病名 (英文) + 4 中文病名 (简/繁) 单独或组合出现都触发
          // Apple Guideline 5.1.1 medical 抽审 (1-2 月医学认证) +
          // GooglePlay 5.1.3 medical 抽审 (类似流程)。
          final file = File(relPath);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'description 文件应存在: $relPath',
          );
          final contentLower = file.readAsStringSync().toLowerCase();
          final hits = <String>[];
          for (final keyword in _diseaseNameKeywords) {
            // _diseaseNameKeywords 全部小写, contentLower 也小写, 直接 contains
            // CJK 字符 toLowerCase 不变, 自动正确比较
            if (contentLower.contains(keyword)) {
              hits.add(keyword);
            }
          }
          expect(
            hits,
            isEmpty,
            reason: '$relPath 含精神疾病名 (Apple 5.1.1 / GooglePlay 5.1.3 '
                'medical 抽审风险): $hits',
          );
        },
      );
    }

    test('v0.31.1 P0-04b 修复后 5 病名 + 中文病名 + PHQ-9 + GAD-7 已从 5 locale 全删 (回归测试)', () {
      // 防御未来 PR 重新加回具体疾病名 / 量表缩写
      // 覆盖范围: iOS en-US/zh-Hans/zh-Hant + Android en-US/zh-CN
      // 5 份 description, 任意 1 份漏掉任一关键词 → FAIL
      for (final relPath in descriptionFiles) {
        final content = File(relPath).readAsStringSync().toLowerCase();
        // 5 英文病名
        for (final keyword in const [
          'depression',
          'anxiety',
          'bipolar',
          'ptsd',
          'adhd',
        ]) {
          expect(content.contains(keyword), isFalse,
              reason: '$relPath 不应再出现 $keyword',);
        }
        // 2 中文病名 (简体)
        expect(content.contains('抑郁'), isFalse,
            reason: '$relPath 不应再出现 抑郁',);
        expect(content.contains('焦虑'), isFalse,
            reason: '$relPath 不应再出现 焦虑',);
        // 2 中文病名 (繁体) — zh-Hant iOS 原 line 18 用了繁体
        expect(content.contains('憂鬱'), isFalse,
            reason: '$relPath 不应再出现 憂鬱',);
        expect(content.contains('焦慮'), isFalse,
            reason: '$relPath 不应再出现 焦慮',);
        // 2 量表缩写
        for (final keyword in _scaleAbbreviations) {
          expect(content.contains(keyword), isFalse,
              reason: '$relPath 不应再出现 ${keyword.toUpperCase()}',);
        }
      }
    });
  });
}
