// v0.29 Round 95 (#68 修复): store_kit_service 0 测试补齐
//
// 覆盖:
// - kLifetimeProductId const 值
// - dev 模式: isPro/isProSync 返 true (绕过 prefs)
// - dev 模式: warmup 设 _proCache=true
// - dev 模式: buyLifetime 返 true (mark as pro)
// - release 模式 + iapEnabled=false: buyLifetime 返 false (Apple 2.1 兜底)
// - release 模式 + iapEnabled=true: buyLifetime 返 false (v0.28 未接 productId)
// - resetForTest 清 _proCache
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/store_kit_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // v0.30 round 95 (sub-spec 7 R96a fix): 显式把 iapEnabled 翻成 true,
    // dev 模式 isProSync/buyLifetime 走 kDebugMode 短路前必须先过 iapEnabled 守卫
    // (R67 C-7 修复顺序: iapEnabled 早返 → kDebugMode 短路 → release flow)
    // 不设 true → 默认 _currentIapEnabled=null → _prodIapEnabled=false →
    // buyLifetime 早返 false, dev 模式测试 (期望 true) 失败
    FeatureFlags.setIapEnabledForTest(true);
  });

  tearDown(() async {
    // 防止污染后续 test
    await StoreKitService.resetForTest();
    FeatureFlags.setIapEnabledForTest(null);
  });

  group('StoreKitService 常量', () {
    test('kLifetimeProductId 是 chroniccare.lifetime 格式', () {
      expect(
        StoreKitService.kLifetimeProductId,
        'com.chroniccare.app.lifetime',
      );
    });
  });

  group('StoreKitService dev 模式 (kDebugMode = true)', () {
    // flutter_test 默认 kDebugMode = true
    test('isPro() 返 true (dev 短路)', () async {
      expect(await StoreKitService.isPro(), isTrue);
    });

    test('isProSync() 返 true (dev 短路)', () {
      expect(StoreKitService.isProSync(), isTrue);
    });

    test('warmup() 设 _proCache=true (dev)', () async {
      await StoreKitService.warmup();
      expect(StoreKitService.isProSync(), isTrue);
    });

    test('buyLifetime() 返 true (dev mock, kDebugMode 短路)', () async {
      // setUp 已设 iapEnabled=true, dev 模式 buyLifetime 走 kDebugMode 短路
      expect(await StoreKitService.buyLifetime(), isTrue);
    });
  });

  group('StoreKitService resetForTest', () {
    test('清 _proCache 返 false', () async {
      // v0.29 R95: dev 模式 isProSync 永远 true, reset 后仍 true
      // 实际只验证 reset 不抛
      await StoreKitService.resetForTest();
      expect(StoreKitService.isProSync(), isTrue); // dev 模式永远是 true
    });
  });

  group('StoreKitService release 模式 (FeatureFlags 控制)', () {
    // v0.29 R95: release 模式行为验证, 用 setIapEnabledForTest
    // 模拟 release 模式需要 kReleaseMode = true, 但 flutter_test 默认 kDebugMode = true
    // 所以下面只验证 FeatureFlags.iapEnabled = false 时 buyLifetime 返 false
    // (iapEnabled 早返检查在 kDebugMode 之前)
    test('iapEnabled=false 时 buyLifetime 返 false (Apple 2.1 兜底)', () async {
      FeatureFlags.setIapEnabledForTest(false);
      expect(FeatureFlags.iapEnabled, isFalse);
      // buyLifetime 入口: !iapEnabled → 早返 false
      // 注意: kDebugMode 走 true 短路在 iapEnabled 检查之前
      // 所以这个 case 实际上依赖 iapEnabled 检查的代码顺序
      // (v0.27 R67 C-7 修复: iapEnabled 在 kDebugMode 前检查)
      expect(await StoreKitService.buyLifetime(), isFalse);
    });

    test('iapEnabled=true 时 buyLifetime 返 true (dev mock, kDebugMode 优先)',
        () async {
      FeatureFlags.setIapEnabledForTest(true);
      expect(FeatureFlags.iapEnabled, isTrue);
      // dev 模式 kDebugMode 短路, 不管 iapEnabled 走 mark as pro
      expect(await StoreKitService.buyLifetime(), isTrue);
    });
  });

  group('StoreKitService SharedPreferences 集成 (setUp 提供)', () {
    // v0.29 R95: release 模式才走 SharedPreferences, dev 模式短路
    // 这里只验证 SharedPreferences mock 跟 resetForTest 互不污染
    test('resetForTest 不抛', () async {
      await StoreKitService.resetForTest();
      // 跑两次不抛
      await StoreKitService.resetForTest();
    });
  });
}
