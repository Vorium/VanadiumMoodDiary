// v0.30 round 93 (test): FeatureFlags 8 flag 默认值 + enableForTest + resetForTest + 8 常量全 false 验证
//
// R93 阶段 2: 11 项 `_prodXxxEnabled = const false` 业务暂停策略验证
// 8 个 flag:
//   - emergencyContactEnabled (R66)
//   - iapEnabled (R68)
//   - phqGad7I18nEnabled (R65b)
//   - bootReceiverEnabled (R93 阶段 2 默认 true → false)
//   - aliyunSmsEnabled (R93 阶段 2 新增)
//   - emailServiceEnabled (R93 阶段 2 新增)
//   - fiveVendorPushEnabled (R93 阶段 2 新增)
//   - ventAudioEnabled (R93 阶段 2 新增)
//
// 11 case:
//   - 8 case: 8 flag 各自默认值 false
//   - 1 case: enableForTest 翻 8 个全 true
//   - 1 case: resetForTest 恢复 prod (8 个全 null)
//   - 1 case: 8 项 prod 常量全 false (compile-time 验证)
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 每个 case 跑完后恢复 prod 默认值, 避免污染后续 test
  setUp(FeatureFlags.resetForTest);
  tearDown(FeatureFlags.resetForTest);

  group('FeatureFlags R93 阶段 2 默认值 (8 flag 全 false)', () {
    test('emergencyContactEnabled 默认 false', () {
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
    });

    test('iapEnabled 默认 false', () {
      expect(FeatureFlags.iapEnabled, isFalse);
    });

    test('phqGad7I18nEnabled 默认 false', () {
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
    });

    test('bootReceiverEnabled 默认 false (R93 阶段 2 改)', () {
      // R93 阶段 2: _prodBootReceiverEnabled = true → false
      // 之前默认 true 跟现有行为一致, 改 false 后业务暂停
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });

    test('aliyunSmsEnabled 默认 false (R93 阶段 2 新增)', () {
      // 阿里云 SMS 真接前 (依赖法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
      expect(FeatureFlags.aliyunSmsEnabled, isFalse);
    });

    test('emailServiceEnabled 默认 false (R93 阶段 2 新增)', () {
      // EmailService 真接 SendGrid 前 (依赖法务模板审核 + SendGrid API key)
      expect(FeatureFlags.emailServiceEnabled, isFalse);
    });

    test('fiveVendorPushEnabled 默认 false (R93 阶段 2 新增)', () {
      // 5 厂商 push SDK 接入前 (米/华/OPP/vivo/魅族, 1-2 月审核)
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse);
    });

    test('ventAudioEnabled 默认 false (R93 阶段 2 新增)', () {
      // vent audio 录音业务闭环不全 (storage / export 业务暂停)
      expect(FeatureFlags.ventAudioEnabled, isFalse);
    });
  });

  group('FeatureFlags R93 阶段 2 test override', () {
    test('enableForTest 翻 8 个全 true (兼容 R66 老 test)', () {
      // 28 个老 test 调 enableForTest 走真实业务
      // R93 阶段 2 翻 8 个全 true (含新增 4 个) 保证老 test 不破
      FeatureFlags.enableForTest();
      expect(FeatureFlags.emergencyContactEnabled, isTrue);
      expect(FeatureFlags.iapEnabled, isTrue);
      expect(FeatureFlags.phqGad7I18nEnabled, isTrue);
      expect(FeatureFlags.bootReceiverEnabled, isTrue);
      expect(FeatureFlags.aliyunSmsEnabled, isTrue);
      expect(FeatureFlags.emailServiceEnabled, isTrue);
      expect(FeatureFlags.fiveVendorPushEnabled, isTrue);
      expect(FeatureFlags.ventAudioEnabled, isTrue);
    });

    test('resetForTest 恢复 prod (8 个全 null → 8 个全 false)', () {
      // 先翻 enableForTest
      FeatureFlags.enableForTest();
      expect(FeatureFlags.iapEnabled, isTrue);
      // reset 恢复 prod 默认值
      FeatureFlags.resetForTest();
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      expect(FeatureFlags.iapEnabled, isFalse);
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
      expect(FeatureFlags.aliyunSmsEnabled, isFalse);
      expect(FeatureFlags.emailServiceEnabled, isFalse);
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse);
      expect(FeatureFlags.ventAudioEnabled, isFalse);
    });

    test('per-flag setter 单独 override (兼容 R67 模式)', () {
      // R67 阶段加的 4 个 per-flag setter 模式, R93 加 4 个新 setter
      FeatureFlags.setIapEnabledForTest(true);
      expect(FeatureFlags.iapEnabled, isTrue);
      // 其他 flag 不受影响
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      expect(FeatureFlags.aliyunSmsEnabled, isFalse);

      FeatureFlags.setAliyunSmsEnabledForTest(true);
      expect(FeatureFlags.aliyunSmsEnabled, isTrue);

      FeatureFlags.setVentAudioEnabledForTest(true);
      expect(FeatureFlags.ventAudioEnabled, isTrue);

      // 重置
      FeatureFlags.setIapEnabledForTest(null);
      FeatureFlags.setAliyunSmsEnabledForTest(null);
      FeatureFlags.setVentAudioEnabledForTest(null);
      expect(FeatureFlags.iapEnabled, isFalse);
      expect(FeatureFlags.aliyunSmsEnabled, isFalse);
      expect(FeatureFlags.ventAudioEnabled, isFalse);
    });
  });
}
