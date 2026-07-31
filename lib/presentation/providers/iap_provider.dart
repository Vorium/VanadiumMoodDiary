// v0.27 round 65 (appstore P0-4 IAP 集成): IAP Riverpod provider
//
// 包装 StoreKitService.isPro() + buyLifetime() 为 Riverpod API,
// 让 UI 走 ref.watch(iapProProvider) 响应式读, 不用每次 await。
//
// Riverpod 3.x: `StateProvider` 已移除, 改用 `Notifier<bool>` 模式。
// - iapProProvider (NotifierProvider<IapNotifier, bool>): pro 状态
//   初始值走 StoreKitService.isProSync() (内存缓存)
//   用户买完: ref.read(iapProProvider.notifier).markAsPro()
// - buyLifetimeProvider (Provider<Future<bool> Function()>):
//   UI 在 onPressed 调, ref.read(buyLifetimeProvider)()

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/store_kit_service.dart';

/// v0.27 round 65 (appstore P0-4 IAP 集成): pro 状态 Notifier
///
/// Riverpod 3.x 替代 StateProvider 的标准模式。
/// 初始值: 同步读 StoreKitService.isProSync() (内存缓存)
/// 触发刷新: 启动时 main.dart bootstrap 调 StoreKitService.warmup()
/// 用户买完: ref.read(iapProProvider.notifier).markAsPro()
class IapNotifier extends Notifier<bool> {
  @override
  bool build() {
    return StoreKitService.isProSync();
  }

  /// 标记为 pro (购买成功后调)
  void markAsPro() {
    state = true;
  }

  /// 重置 (仅测试用)
  void reset() {
    state = false;
  }
}

/// v0.27 round 65 (appstore P0-4 IAP 集成): 当前是否 pro
final iapProProvider = NotifierProvider<IapNotifier, bool>(IapNotifier.new);

/// v0.27 round 65 (appstore P0-4 IAP 集成): 发起买断的回调
///
/// UI 在按钮 onPressed 调 ref.read(buyLifetimeProvider)()().
/// 返回 true = 已 mark as pro (成功), false = 失败 / 取消。
final buyLifetimeProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final ok = await StoreKitService.buyLifetime();
    if (ok) {
      // 同步 pro 状态
      ref.read(iapProProvider.notifier).markAsPro();
    }
    return ok;
  };
});
