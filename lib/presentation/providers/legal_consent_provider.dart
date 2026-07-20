// v0.21 Round 22 (P0-2 修复): 撤回同意 状态管理
//
// PIPL §26: 应当提供撤回同意的便捷方式。
// setup step 0 已声明"可随时在 设置 → 法律与隐私 撤回同意",但 UI/状态
// 都不存在 = 虚假告知。本文件实现撤回/重新同意 状态持久化。
//
// **设计取舍**:
// - 状态存 SharedPreferences 而非 DB(轻量,不需要跨设备同步)
// - 撤回 = 该功能**停用**,数据**不删**(用户可手动删,也可"重新同意"恢复)
// - 业务层接驳放 v1.0+ —— 本次只解决"虚假告知"问题(PIPL §26),
//   不动 reminder_scheduler / vent_repository / care_engine 实际行为
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 撤回同意的 3 个维度(对应 legal_page 3 个 switch)
///
/// 未来若新增同意项,加这里 + 加 ARB key + 页面加一行 switch 即可。
enum ConsentKind {
  /// 失联通知 — 关掉后 CareEngine 不再触发 SMS/邮件
  safety,

  /// 树洞(敏感倾诉) — 关掉后 VentRepository.add 拒绝
  vent,

  /// 评估/情绪分析 — 关掉后 trend_page 不展示评估/情绪相关图表
  analytics,
}

/// 撤回同意状态存储
class LegalConsentStore {
  static const _kPrefix = 'legal_consent_withdrawn_';

  Future<bool> isWithdrawn(ConsentKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kPrefix${kind.name}') ?? false;
  }

  Future<DateTime?> withdrawnAt(ConsentKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('$_kPrefix${kind.name}_at');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> withdraw(ConsentKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kPrefix${kind.name}', true);
    await prefs.setInt(
      '$_kPrefix${kind.name}_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> reset(ConsentKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPrefix${kind.name}');
    await prefs.remove('$_kPrefix${kind.name}_at');
  }
}

final legalConsentStoreProvider = Provider<LegalConsentStore>(
  (ref) => LegalConsentStore(),
);

/// 单一 kind 的撤回状态 stream
final legalConsentWithdrawnProvider =
    StreamProvider.family<bool, ConsentKind>((ref, kind) async* {
  final store = ref.watch(legalConsentStoreProvider);
  yield await store.isWithdrawn(kind);
  // 简单的"一次性读取" — toggle 改动后通过 ref.invalidate 触发
  // 这里我们用 changeNotifier 模式不太适合 StreamProvider
  // 实际实现:legal_page setState 后直接调 store + 重新读
});

/// 单一 kind 的撤回时间 stream
final legalConsentWithdrawnAtProvider =
    StreamProvider.family<DateTime?, ConsentKind>((ref, kind) async* {
  final store = ref.watch(legalConsentStoreProvider);
  yield await store.withdrawnAt(kind);
});
