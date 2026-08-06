// v0.27 round 67 (C-7 重构): FeatureFlags 推广 4 flag 测试
//
// R66 只 1 个 emergencyContactEnabled flag, R67 推广到 4 个独立 flag
// (emergencyContact + iap + phqGad7I18n + bootReceiver), 走
// "prod const + nullable override" 模式。

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/feature_flags.dart';

void main() {
  group('FeatureFlags (R67 C-7)', () {
    // 每个 case 后清 override, 避免污染后续 test
    tearDown(() {
      FeatureFlags.resetForTest();
    });

    test(
        '1. 默认值: emergencyContactEnabled=false, iapEnabled=false (R68), phqGad7I18nEnabled=false, bootReceiverEnabled=false (R93)',
        () {
      // R68 CC-3: iapEnabled 默认 false (临时关闭, 避免 "8 元买断" vs release buyLifetime() 返 false 不一致)
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      expect(FeatureFlags.iapEnabled, isFalse);
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
      // R93 阶段 2: bootReceiverEnabled 默认改为 false (v0.28 WorkManager 完善前)
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });

    test('2. setIapEnabledForTest(false): iapEnabled 返 false, 其他 3 个 flag 不变',
        () {
      FeatureFlags.setIapEnabledForTest(false);
      expect(FeatureFlags.iapEnabled, isFalse);
      // 其他 3 个 flag 不变
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
      // R93: bootReceiverEnabled 默认 false
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });

    test('3. setPhqGad7I18nEnabledForTest(true): phqGad7I18nEnabled 返 true',
        () {
      FeatureFlags.setPhqGad7I18nEnabledForTest(true);
      expect(FeatureFlags.phqGad7I18nEnabled, isTrue);
      // 其他 3 个 flag 不变
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      // R68: prod iapEnabled = false
      expect(FeatureFlags.iapEnabled, isFalse);
      // R93: bootReceiverEnabled 默认 false
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });

    test('4. setBootReceiverEnabledForTest(false): bootReceiverEnabled 返 false',
        () {
      FeatureFlags.setBootReceiverEnabledForTest(false);
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
      // 其他 3 个 flag 不变
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      // R68: prod iapEnabled = false
      expect(FeatureFlags.iapEnabled, isFalse);
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
    });

    test('5. setXxxForTest(null): 该 flag 恢复 prod 默认值', () {
      FeatureFlags.setIapEnabledForTest(true);
      expect(FeatureFlags.iapEnabled, isTrue);
      FeatureFlags.setIapEnabledForTest(null);
      // R68: 恢复 prod = false (之前 R67 = true)
      expect(FeatureFlags.iapEnabled, isFalse);
    });

    test('6. enableForTest (R66 兼容): 4 个 flag 全部 enable, resetForTest 全清', () {
      // 跟 R66 老 test 调用方式兼容
      FeatureFlags.enableForTest();
      expect(FeatureFlags.emergencyContactEnabled, isTrue);
      // enableForTest 强制 override, 不受 prod 默认影响
      expect(FeatureFlags.iapEnabled, isTrue);
      expect(FeatureFlags.phqGad7I18nEnabled, isTrue);
      expect(FeatureFlags.bootReceiverEnabled, isTrue);
      // resetForTest 全部清, 回到 prod 默认
      FeatureFlags.resetForTest();
      expect(FeatureFlags.emergencyContactEnabled, isFalse);
      // R68: prod = false
      expect(FeatureFlags.iapEnabled, isFalse);
      expect(FeatureFlags.phqGad7I18nEnabled, isFalse);
      // R93: prod bootReceiverEnabled = false
      expect(FeatureFlags.bootReceiverEnabled, isFalse);
    });
  });
}
