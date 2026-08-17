// v0.30 R108 (P0#3): 锁屏通知 body 不暴露药名 + 剂量 (PII) 防回归测试
//
// R107 报告 P0-3: notification_service.dart 锁屏 body 含 dosage + unit
// (e.g. "2.5mg · 点一下 = 打卡"), 任何旁人 (同事 / 家人 / 公共交通) 都能
// 从锁屏看到用户吃的药 + 剂量, 暴露精神心理 / 慢性病身份。
//
// 修法:
// 1. Strings.notifMedicationBody 签名: (double dosage, DosageUnit unit, {override})
//    → ({override}) (无 dosage / unit 入参), body 改通用文案
// 2. medication_notifier.dart caller 改用 Strings.notifMedicationBody() (无参版)
// 3. 旧版 (有 dosage 入参) 走 @Deprecated notifMedicationBodyLegacy, 防止新 caller
//    误用
//
// 测试覆盖 (纯 Dart 域测试, 0 Flutter / 0 plugin 依赖):
// 1. Strings.notifMedicationBody() 不再含 dosage / unit 字面量
// 2. Strings.notifMedicationBody() 默认返回 "点一下 = 打卡" 通用文案
// 3. medication_notifier.dart 调的是无参版 (Strings.notifMedicationBody())
// 4. medication_notifier.dart 不再传 dosage / unit 给 body
// 5. DosageUnit.id (e.g. "mg", "片") 仍出现在 title 之外 (med.name 仍用)
// 6. body 含 "点一下" 或 "打卡" 字面 (确认是引导文案, 不是 dosage)
import 'dart:io' as dart_io;

import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Strings.notifMedicationBody R108 P0#3 锁屏 body 脱敏验证', () {
    test('case 1: 默认 body 不含 dosage / unit 字面量', () {
      // 修前: "$dosage${unit.id} · 点一下 = 打卡" = "2.5mg · 点一下 = 打卡"
      //   → 锁屏可见 mg / 片 等 PII
      // 修后: 固定文案, 不含 dosage / unit
      final body = Strings.notifMedicationBody();
      // DosageUnit.id 取值: "mg" / "片" / "ml" 等
      for (final unit in DosageUnit.values) {
        expect(
          body.contains(unit.id),
          isFalse,
          reason: 'body 不应含 DosageUnit.id="${unit.id}" (锁屏 PII 风险)',
        );
      }
      // 也不应含数字 dosage 形式 (e.g. "2.5", "10.0", "1")
      // — 0.0 是浮点零, 包含会误判, 用更严格 regex
      expect(
        RegExp(r'\d+\.?\d*').hasMatch(body),
        isFalse,
        reason: 'body 不应含数字 (dosage 形式), 实际: "$body"',
      );
    });

    test('case 2: 默认 body 是引导文案 (含"点一下"或"打卡")', () {
      final body = Strings.notifMedicationBody();
      // 修后文案: "该吃药了 · 点一下 = 打卡"
      // — 引导用户点, 不暴露具体药名
      expect(
        body.contains('点一下') || body.contains('打卡'),
        isTrue,
        reason: 'body 应该是引导文案 (点一下 / 打卡的某种), 实际: "$body"',
      );
    });

    test('case 3: override 参数支持 i18n 注入', () {
      // override 是 R57 加的, R108 保留 (presentation 层可注入 l10n)
      final customBody = Strings.notifMedicationBody(
        override: 'Custom i18n body',
      );
      expect(customBody, 'Custom i18n body');
    });

    test('case 4: @Deprecated notifMedicationBodyLegacy 也脱敏 (safety net)', () {
      // 旧版 (有 dosage / unit 入参) 即使被历史代码调到, 也不返回 dosage
      // 这是"安全网": 万一有遗留 caller 没改, 也不会泄漏 PII
      // ignore: deprecated_member_use_from_same_package
      final legacyBody = Strings.notifMedicationBodyLegacy(
        2.5,
        DosageUnit.mg,
      );
      expect(
        legacyBody.contains('2.5'),
        isFalse,
        reason: 'deprecated legacy 函数也不应返回 dosage 字符串',
      );
      expect(
        legacyBody.contains('mg'),
        isFalse,
        reason: 'deprecated legacy 函数也不应返回 unit 字符串',
      );
    });
  });

  group('medication_notifier.dart R108 P0#3 caller 静态分析', () {
    test(
        'caller 1: medication_notifier.dart 调无参版 Strings.notifMedicationBody()',
        () async {
      // 读源文件做静态检查
      final file = dart_io.File(
        'lib/core/data/services/medication_notifier.dart',
      );
      final content = await file.readAsString();
      // 应调无参版: Strings.notifMedicationBody()
      expect(
        content.contains('Strings.notifMedicationBody()'),
        isTrue,
        reason: 'medication_notifier.dart 应调无参版 Strings.notifMedicationBody()',
      );
      // 不应传 dosage 给 body (修前: Strings.notifMedicationBody(med.dosage, ...))
      // 这里的 pattern: "Strings.notifMedicationBody(" 后跟 med.dosage
      final oldPattern = RegExp(
        r'Strings\.notifMedicationBody\(\s*med\.dosage',
      );
      expect(
        oldPattern.hasMatch(content),
        isFalse,
        reason: 'medication_notifier.dart 不应再传 med.dosage 给 body (PII 风险)',
      );
    });
  });

  group('Strings.notifAssessmentBody R113 BUG 8 锁屏 body 脱敏验证', () {
    test('case 1: 默认 body 不含量表名 (PHQ9 / GAD7 等 scaleId)', () {
      // 修前: "已经 X 天没做 PHQ9 了，请花 2 分钟做一下评估" —
      //   PHQ9 是精神健康量表名, iOS 锁屏横幅可见 = 健康 PII
      final body = Strings.notifAssessmentBody(14);
      for (final scale in ['PHQ9', 'PHQ-9', 'GAD7', 'GAD-7', 'phq9', 'gad7']) {
        expect(
          body.contains(scale),
          isFalse,
          reason: 'body 不应含量表名 "$scale" (锁屏 PII 风险)',
        );
      }
    });

    test('case 2: 默认 body 是通用引导文案 (含"评估", 不含量表名)', () {
      final body = Strings.notifAssessmentBody(14);
      expect(
        body.contains('评估'),
        isTrue,
        reason: 'body 应保留通用"评估"引导语义, 实际: "$body"',
      );
      expect(
        RegExp(r'[A-Z]{2,}\d*').hasMatch(body),
        isFalse,
        reason: 'body 不应含大写缩写量表名 (PHQ9/GAD7 形态), 实际: "$body"',
      );
    });

    test('case 3: override 参数支持 i18n 注入', () {
      final customBody = Strings.notifAssessmentBody(
        14,
        override: 'Custom assessment reminder body',
      );
      expect(customBody, 'Custom assessment reminder body');
    });

    test('case 4: 签名不再接收 scaleIdUppercase 参数 (编译期防泄漏)', () async {
      final file = dart_io.File('lib/core/l10n/strings.dart');
      final content = await file.readAsString();
      expect(
        content.contains('scaleIdUppercase'),
        isFalse,
        reason: 'notifAssessmentBody 不应再接收 scaleId 参数 (R113 BUG 8)',
      );
    });
  });

  group('assessment_notifier.dart R113 BUG 8 caller 静态分析', () {
    test('caller: assessment_notifier.dart 不再传 scaleId 给 body', () async {
      // R126 续 评估 1 commit 整包 (1.1.0+176): assessment_notifier.dart 实际定义
      // 已迁到 lib/features/assessment/data/services/assessment_notifier.dart,
      // 旧 lib/core/data/services/assessment_notifier.dart 改 1 行 re-export.
      // 跟 R122 P2-2 R95 lock-in 适配 1 case 同模式, 读新路径检查 pattern.
      final file = dart_io.File(
        'lib/features/assessment/data/services/assessment_notifier.dart',
      );
      final content = await file.readAsString();
      // 应调无 scaleId 版: Strings.notifAssessmentBody(days)
      expect(
        RegExp(r'Strings\.notifAssessmentBody\(\s*days\s*\)').hasMatch(content),
        isTrue,
        reason:
            'assessment_notifier.dart 应调无 scaleId 版 notifAssessmentBody(days)',
      );
      // 不应再把 scaleId.toUpperCase() 拼进 body (修前: notifAssessmentBody(days, scaleId.toUpperCase()))
      expect(
        content.contains('scaleId.toUpperCase()'),
        isFalse,
        reason: 'assessment_notifier.dart 不应再把 scaleId 拼进 body (锁屏 PII)',
      );
    });
  });
}
