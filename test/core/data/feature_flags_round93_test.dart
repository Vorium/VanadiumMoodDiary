// v0.30 round 93 (test): FeatureFlags 4 flag 默认值 + enableForTest + resetForTest + 常量验证
//
// R93 阶段 2: `_prodXxxEnabled = const false` 业务暂停策略验证
// R105: ventAudioEnabled 由 false 改 true (R104 启用语音录制), 其余 flag 保持 false。
// v1.0.0+147: 永久免费定版, 8 flag → 7 flag。
// 1.1.0 round 4b (emotion-first refactor): 外联 3 flag 整摘
//   (emergencyContactEnabled / aliyunSmsEnabled / emailServiceEnabled), 7 → 4 flag:
//   - phqGad7I18nEnabled (R65b)
//   - bootReceiverEnabled (R93 阶段 2 默认 true → false)
//   - fiveVendorPushEnabled (R93 阶段 2 新增)
//   - ventAudioEnabled (R93 阶段 2 新增)
//
// 8 case:
//   - 4 case: 4 flag 各自默认值
//   - 1 case: enableForTest 翻 4 个全 true
//   - 1 case: resetForTest 恢复 prod (4 个全 null)
//   - 2 case: per-flag setter 单独 override
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 每个 case 跑完后恢复 prod 默认值, 避免污染后续 test
  setUp(FeatureFlags.resetForTest);
  tearDown(FeatureFlags.resetForTest);

  group('FeatureFlags R93 阶段 2 默认值 (3 flag false + ventAudio true)', () {
    test('phqGad7I18nEnabled 默认 false', () {
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
    });

    test('bootReceiverEnabled 默认 false (R93 阶段 2 改)', () {
      // R93 阶段 2: _prodBootReceiverEnabled = true → false
      // 之前默认 true 跟现有行为一致, 改 false 后业务暂停
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });

    test('fiveVendorPushEnabled 默认 false (R93 阶段 2 新增)', () {
      // 5 厂商 push SDK 接入前 (米/华/OPP/vivo/魅族, 1-2 月审核)
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse);
    });

    test('ventAudioEnabled 默认 true (R104 启用语音录制)', () {
      // R93 阶段 2 默认 false (录音业务暂停), R104 起启用语音录制 → 默认 true
      expect(FeatureFlags.ventAudioEnabled, isTrue);
    });
  });

  group('FeatureFlags R93 阶段 2 test override', () {
    test('enableForTest 翻 4 个全 true (兼容 R66 老 test)', () {
      // 老 test 调 enableForTest 走真实业务
      FeatureFlags.enableForTest();
      expect(FeatureFlags.phqGad7I18nEnabled, isTrue);
      expect(FeatureFlags.bootReceiverEnabled, isTrue);
      expect(FeatureFlags.fiveVendorPushEnabled, isTrue);
      expect(FeatureFlags.ventAudioEnabled, isTrue);
    });

    test('resetForTest 恢复 prod (4 个全 null → prod 默认)', () {
      // 先翻 enableForTest
      FeatureFlags.enableForTest();
      expect(FeatureFlags.fiveVendorPushEnabled, isTrue);
      // reset 恢复 prod 默认值
      FeatureFlags.resetForTest();
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse);
      // R104 起 ventAudio 默认 true
      expect(FeatureFlags.ventAudioEnabled, isTrue);
    });

    test('per-flag setter 单独 override (兼容 R67 模式)', () {
      // R67 阶段加的 per-flag setter 模式, R93 加新 setter
      FeatureFlags.setFiveVendorPushEnabledForTest(true);
      expect(FeatureFlags.fiveVendorPushEnabled, isTrue);
      // 其他 flag 不受影响
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);

      FeatureFlags.setVentAudioEnabledForTest(true);
      expect(FeatureFlags.ventAudioEnabled, isTrue);

      // 重置
      FeatureFlags.setFiveVendorPushEnabledForTest(null);
      FeatureFlags.setVentAudioEnabledForTest(null);
      expect(FeatureFlags.fiveVendorPushEnabled, isFalse);
      // R104 起 ventAudio 默认 true
      expect(FeatureFlags.ventAudioEnabled, isTrue);
    });
  });
}
