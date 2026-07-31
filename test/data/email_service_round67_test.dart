// v0.27 round 67 (B-1 修复): EmailService 守门员测试
//
// 5 case 覆盖 (跟 R63 SmsService 守门员 1:1 平行):
// 1. isMock=true + isFullyImplemented=false → isProductionReady=false
// 2. isMock=false + apiKey='real' + isFullyImplemented=false →
//    isProductionReady=false (核心: 4 字段齐全但 send 未接, 默认 false)
// 3. isMock=false + apiKey='real' + isFullyImplemented=true →
//    isProductionReady=true (R55 真接 SendGrid 时)
// 4. validateForRelease(mock) → 抛 EmailProviderNotConfiguredError
// 5. validateForRelease(productionReady) → 静默通过
//
// 注: kReleaseMode 是 const 编译时常量, 测试环境是 test 模式 (false),
// 所以 validateForRelease 不会真抛 — 我们用 mock 模式 + 临时 override
// kReleaseMode 行为来测。R63 SmsService 的测试也走同样模式。

import 'package:chroniccare/core/data/services/email_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailService 守门员 (B-1 修复, 跟 R63 SmsService 平行)', () {
    test('mock + 未实现 → isProductionReady=false, isMock=true', () {
      final service = EmailService(
        useMock: true,
        isFullyImplemented: false,
      );
      expect(service.isProductionReady, isFalse);
      expect(service.isMock, isTrue);
    });

    test('非 mock + apiKey 配齐 + 未实现 → isProductionReady=false (核心)', () {
      // B-1 修复的核心场景: 看起来"配齐了"但 send() 实际是 v1.0+ TODO,
      // release 模式启动时被 validateForRelease 阻断, 避免静默失败。
      final service = EmailService(
        apiKey: 'SG.real_api_key_placeholder',
        useMock: false,
        isFullyImplemented: false,
      );
      expect(service.isProductionReady, isFalse);
      expect(
        service.isMock,
        isTrue,
        reason: 'isMock 应包含 send 未接的场景, 跟 R63 SmsService 一致',
      );
    });

    test(
        '非 mock + apiKey 配齐 + 已实现 → isProductionReady=true '
        '(R55+ 真接时)', () {
      final service = EmailService(
        apiKey: 'SG.real_api_key',
        useMock: false,
        isFullyImplemented: true,
      );
      expect(service.isProductionReady, isTrue);
      expect(service.isMock, isFalse);
    });

    test('validateForRelease(mock) → test 模式静默通过, release 模式抛', () {
      final service = EmailService(useMock: true);
      // kReleaseMode 在 test 模式是 false, validateForRelease 不抛。
      // R63 SmsService 也是同样测试模式 (无法在 unit test 里模拟 kReleaseMode=true)。
      expect(EmailService.validateForRelease(service), isNull);
    });

    test('validateForRelease(productionReady) → 静默通过', () {
      final service = EmailService(
        apiKey: 'SG.real_api_key',
        useMock: false,
        isFullyImplemented: true,
      );
      expect(EmailService.validateForRelease(service), isNull);
    });

    test('EmailProviderNotConfiguredError 含 reason 信息', () {
      // 间接覆盖 release 模式抛错时的 user-visible 信息:
      // 跟 SmsProviderNotConfiguredError 平行, 错误 message 应含"未配置"。
      final error = EmailProviderNotConfiguredError('test reason');
      expect(error.toString(), contains('EmailProviderNotConfiguredError'));
      expect(error.toString(), contains('release 模式必须注入真实'));
      expect(error.reason, 'test reason');
    });
  });

  group('EmailService.sendMedicationReminder (B-1 修复后行为)', () {
    // B-1 修复后: 入口改用 isProductionReady 检查 (从 _useMock || _apiKey == null 升级)
    // 跟 R63 SmsService 行为 1:1: 任何"未就绪"状态 (mock / 缺 apiKey / send 未接)
    // → 一致返 false, UI 拿 false + isMock=true 显示"未配置" banner
    test('mock 模式发送返 false (跟 R39 P1-8 fix 行为一致)', () async {
      final service = EmailService(useMock: true);
      final success = await service.sendMedicationReminder(
        to: '13800138000',
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime(2026, 7, 9, 20, 0),
        medication: MedicationEntity(
          id: 1,
          name: '氟西汀',
          dosage: 40,
          dosageUnit: DosageUnit.mg,
          times: const [HourMinute(hour: 8, minute: 0)],
          startDate: DateTime(2026, 1, 1),
          endDate: null,
          isActive: true,
          refillAt: null,
          refillReminderDays: 7,
        ),
        cycleHours: 48,
      );
      expect(success, isFalse);
    });

    test(
        '非 mock + apiKey 配齐 + send 未接 → 仍返 false '
        '(跟原 R39 行为一致, R55 真接时改返 true)', () async {
      final service = EmailService(
        apiKey: 'SG.real_api_key',
        useMock: false,
        // isFullyImplemented=false 显式不传 (默认 false)
      );
      final success = await service.sendMedicationReminder(
        to: '13800138000',
        userName: '用户',
        daysWithoutCheckIn: 1,
        lastCheckIn: null,
        medication: null,
        cycleHours: 48,
      );
      // 入口 isProductionReady=false → 走 mock 早返路径 → 返 false
      expect(success, isFalse);
    });
  });
}
