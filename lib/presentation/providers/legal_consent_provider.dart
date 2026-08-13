// v0.21 Round 22 (P0-2 修复): 撤回同意 状态管理
//
// PIPL §26: 应当提供撤回同意的便捷方式。
// setup step 0 已声明"可随时在 设置 → 法律与隐私 撤回同意",但 UI/状态
// 都不存在 = 虚假告知。本文件实现撤回/重新同意 状态读取 provider。
//
// **设计取舍**:
// - 状态存 SharedPreferences 而非 DB(轻量,不需要跨设备同步)
// - 撤回 = 该功能**停用**,数据**不删**(用户可手动删,也可"重新同意"恢复)
// - 业务层接驳放 v1.0+ —— 本次只解决"虚假告知"问题(PIPL §26),
//   不动 reminder_scheduler / vent_repository / care_engine 实际行为
//
// v0.27 round 63 (P0-3 修复续): 删本地 [ConsentKind] enum, 改 import domain
// 单 source of truth (lib/domain/entities/consent_artifact.dart)。修复前
// domain / presentation 同名不同值, legal_page 用 presentation 的 3 个值
// (safety/vent/analytics), ConsentDialog 用 domain 的 2 个值
// (emergencyContactSharing/dataExport), 类型推断易踩雷。
//
// v0.32 架构批 2 (R112-ARCH-01): 持久化抽到 data 层
// ConsentPreferenceStore (lib/core/data/services/consent_preference_store.dart)。
// 本文件变薄 facade: 只保留 provider 接线 + 读状态, 8+ 处
// SharedPreferences.getInstance() 直接 IO 全部移除。key 命名规则 /
// 加解密行为 / audit log 语义 100% 不变 (behavior-preserving, 测试全绿)。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/consent_preference_store.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart'
    show ConsentKind;
import 'package:chroniccare/presentation/providers/cbt_providers.dart';

// v0.27 round 63 (P0-3): re-export ConsentKind 让 legal_page.dart 等老
// caller 不用改 import。legal_page 通过本 provider 用 ConsentKind.values
// 等 — re-export 保留单 import 入口, 防止 enum 多 source。
export 'package:chroniccare/domain/entities/consent_artifact.dart'
    show ConsentKind;

/// 撤回同意状态存储 provider
///
/// v0.32 架构批 2 (R112-ARCH-01): 类型从 LegalConsentStore 变
/// ConsentPreferenceStore (data 层), 注入 sharedPreferencesProvider
/// (main.dart bootstrap override, 跟 databaseProvider 同款显式初始化模式)。
/// 测试可 overrideWithValue 直接注入 fake store (export_tile_round95 模式)。
final legalConsentStoreProvider = Provider<ConsentPreferenceStore>(
  (ref) => ConsentPreferenceStore(ref.watch(sharedPreferencesProvider)),
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

/// v0.28 R82.5: vent "加密封存" 状态 stream
///
/// vent_list_page 监听此 provider, sealed=true → 显示"已加密封存"占位
/// 不读 DB, 重新同意后 (reset) → 变 false → 正常显示。
/// R100 (N-3): 加 autoDispose — 离开 vent 页后释放 subscription。
final ventSealedProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final store = ref.watch(legalConsentStoreProvider);
  yield await store.isSealed(ConsentKind.vent);
});

/// v0.28 R82.5: vent 封存时间 stream (R100: 同上 autoDispose)
final ventSealedAtProvider = StreamProvider.autoDispose<DateTime?>((
  ref,
) async* {
  final store = ref.watch(legalConsentStoreProvider);
  yield await store.sealedAt(ConsentKind.vent);
});
