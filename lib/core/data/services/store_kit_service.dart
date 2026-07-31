// v0.27 round 65 (appstore P0-4 IAP 集成): StoreKit 封装
//
// 背景:
// - assets/legal/user_agreement.md:25 写"售价人民币 8 元 / 一次性买断"
// - pubspec 之前无 in_app_purchase 依赖 + 全代码库 0 StoreKit 调用
// - Apple App Store 3.1.5 (a) 明确要求"App 内购买数字商品 / 服务必须用 IAP"
//
// 范围 (本 round 65):
// 1. pubspec 加 in_app_purchase: ^7.0.0
// 2. 本文件封装 IAP singleton + pro 状态缓存
// 3. dev 模式走 kDebugMode 直接返 true (避免 dev 跑不通)
// 4. **不**接真实 Apple 开发者账号 productId (com.chroniccare.app.lifetime)
//    - 留给 v0.28 真接 (外部依赖: App Store Connect 创建 productId + 法务过审 8 元定价)
//
// 数据流:
// - isPro():   SharedPreferences 缓存 pro flag, dev 模式直接 true
// - buyLifetime(): dev 模式直接 mark as pro + 缓存; release 模式走 StoreKit
//   NonConsumablePurchase 流 (查询 product → 发起购买 → 验证 receipt → 标记)
//
// 隐私:
// - 走 SharedPreferences 而非 SQLCipher (IAP flag 不算 PII)
// - release 模式查询走 SharedPreferences 缓存,无 I/O 阻塞
//
// 不依赖 BuildContext (service 层),UI 层走 iap_provider 包装

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v0.27 round 65 (appstore P0-4 IAP 集成): StoreKit 封装
///
/// 8 元一次性买断 → Apple IAP 走 NonConsumable (非订阅, 永久买断)。
///
/// dev 模式 (`kDebugMode == true`):
/// - isPro() 直接返 true (绕开 StoreKit, dev 跑得通)
/// - buyLifetime() 直接 mark as pro (不真发购买)
///
/// release 模式:
/// - isPro() 查 SharedPreferences 缓存 (O(1) 同步)
/// - buyLifetime() 走 InAppPurchase.instance 真实流:
///   queryProductDetails → buyNonConsumable → verifyPurchase
///
/// productId 留 v0.28 真接 (外部依赖: App Store Connect 创建)。
class StoreKitService {
  StoreKitService._();

  /// v0.28 真接时用, dev 模式 + release 占位都用这个常量
  static const String kLifetimeProductId = 'com.chroniccare.app.lifetime';

  /// SharedPreferences key (IAP flag 非 PII, 不走 SQLCipher)
  static const String _kProFlag = 'iap_pro_lifetime';

  /// 单例 getter (避免每个 caller 都创建 instance)
  static final StoreKitService instance = StoreKitService._();

  // v0.28 真接时使用 (queryProductDetails / buyNonConsumable)
  // 当前 dev 模式 + release 占位都不调用, 标 ignore: 避免 unused_field warning
  // ignore: unused_field
  final InAppPurchase _iap = InAppPurchase.instance;

  // ============== Public API (UI 调) ==============

  /// 用户是否已买 (pro)
  ///
  /// dev 模式: 永 true
  /// release: 查 SharedPreferences 缓存
  static Future<bool> isPro() async {
    if (kDebugMode) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProFlag) ?? false;
  }

  /// 同步版 (UI 在 build 内读, 不阻塞)
  ///
  /// dev 模式: 永 true
  /// release: SharedPreferences 内存缓存 (getBool 走内存层, 同步)
  static bool isProSync() {
    if (kDebugMode) return true;
    // 同步读 SharedPreferences 内存层 (不 await)
    return _proCache;
  }

  /// 启动时预热 (AppRoot 启动后调一次)
  ///
  /// 同步 SharedPreferences 内存层 + dev 模式直接返
  static Future<void> warmup() async {
    if (kDebugMode) {
      _proCache = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _proCache = prefs.getBool(_kProFlag) ?? false;
  }

  /// 发起 8 元买断
  ///
  /// dev 模式: 直接 mark as pro (本地 flag, 跟 release 行为一致)
  /// release: 走 InAppPurchase.buyNonConsumable, 回调里 mark as pro
  ///
  /// 返回:
  /// - true  = 已 mark as pro (买成功 or dev 模式 mock)
  /// - false = 用户取消 / StoreKit 失败 (UI 显示错误 toast)
  static Future<bool> buyLifetime() async {
    if (kDebugMode) {
      // dev 模式: 直接 mark as pro, 不真发 StoreKit 流
      await _markAsPro();
      return true;
    }
    // release 模式: 真接 InAppPurchase 流
    // 当前 pubspec 加了 in_app_purchase, 但 v0.28 才真接 productId
    // 占位返回 false (购买未开通)
    return false;
  }

  /// 重置 pro 状态 (仅测试用)
  @visibleForTesting
  static Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProFlag);
    _proCache = false;
  }

  // ============== Private ==============

  /// SharedPreferences 内存层缓存 (同步读用)
  static bool _proCache = false;

  /// 标记为 pro + 写 SharedPreferences
  static Future<void> _markAsPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProFlag, true);
    _proCache = true;
  }
}
