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
//
// v0.27 round 63 (P0-3 修复续): 删本地 [ConsentKind] enum, 改 import domain
// 单 source of truth (lib/domain/entities/consent_artifact.dart)。修复前
// domain / presentation 同名不同值, legal_page 用 presentation 的 3 个值
// (safety/vent/analytics), ConsentDialog 用 domain 的 2 个值
// (emergencyContactSharing/dataExport), 类型推断易踩雷。
//
// v0.27 round 82 (PIPL §13 数据导出同意): 加 [recordDataExportConsent] /
// [readDataExportConsentLog] — 每次用户同意导出时, 把 ConsentArtifact 5
// 字段 json 化追加到 SharedPreferences string list, 留 audit log。修复前
// 数据导出只有"敏感文字警告" dialog, 没生成 ConsentArtifact, 没留痕 =
// 法务复查时缺证据。

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart'
    show ConsentKind, ConsentArtifact;

// v0.27 round 63 (P0-3): re-export ConsentKind 让 legal_page.dart 等老
// caller 不用改 import。legal_page 通过本 provider 用 ConsentKind.values
// 等 — re-export 保留单 import 入口, 防止 enum 多 source。
export 'package:chroniccare/domain/entities/consent_artifact.dart'
    show ConsentKind;

/// 撤回同意状态存储
///
/// v0.27 round 63: 操作 [ConsentKind] 5 个 kind — 包括 PIPL §13 强场景
/// (emergencyContactSharing / dataExport) 和 §14 撤回场景 (safety / vent /
/// analytics)。撤回只对 §14 3 个 kind 实际生效 (§13 是单独同意强场景,
/// 撤回流程在 v1.0 走联系人本人确认 "Y" 通道, 不在本类管理)。
///
/// v0.27 round 82: 加 [recordDataExportConsent] / [readDataExportConsentLog],
/// 给 dataExport kind 留 audit log (PIPL §13 单独同意强场景需可追溯)。
class LegalConsentStore {
  static const _kPrefix = 'legal_consent_withdrawn_';

  /// v0.27 R82: dataExport audit log key
  /// 跟 [_kPrefix] 区分, 不混。`getStringList` 存累积 JSON 字符串。
  static const _kDataExportLog = 'legal_consent_data_export_log';

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

  /// v0.27 R82: 记录一次数据导出同意, 写 audit log
  ///
  /// PIPL §13 + §17 要求单独同意可追溯。每次用户在 ConsentDialog 选
  /// "我了解并同意导出" → call 收下 [ConsentArtifact] (kind 必为
  /// [ConsentKind.dataExport]) → 本方法把 5 字段 jsonEncode 追加到
  /// SharedPreferences string list。
  ///
  /// 设计:
  /// - 累积而非覆盖 (每次同意都留痕, 满足 PIPL §17 同意记录要求)
  /// - 不在 dataExport 同意时 clear (撤回走 [reset(ConsentKind.dataExport)]
  ///   单独的语义路径, 不污染本方法)
  /// - 反序列化 [readDataExportConsentLog] 用 ConsentKind.name 找 enum,
  ///   跟写入时 `kind.name` 对称 (R63 验证 identity 一致)
  Future<void> recordDataExportConsent(ConsentArtifact artifact) async {
    assert(
      artifact.kind == ConsentKind.dataExport,
      'recordDataExportConsent 仅接受 ConsentKind.dataExport, 实际是 ${artifact.kind}',
    );
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kDataExportLog) ?? <String>[];
    final entry = jsonEncode({
      'kind': artifact.kind.name,
      'grantedAt': artifact.grantedAt.toIso8601String(),
      'grantedBy': artifact.grantedBy,
      'contactId': artifact.contactId,
      'version': artifact.version,
    });
    await prefs.setStringList(_kDataExportLog, [...existing, entry]);
  }

  /// v0.27 R82: 读回 dataExport 同意 audit log
  ///
  /// 返回按写入顺序 (FIFO, 时间从早到晚) 的 [ConsentArtifact] 列表。
  /// 法务复查 / 监管审计时给这份 list 即可。
  Future<List<ConsentArtifact>> readDataExportConsentLog() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_kDataExportLog) ?? <String>[];
    return entries.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return ConsentArtifact(
        kind: ConsentKind.values
            .firstWhere((k) => k.name == map['kind'] as String),
        grantedAt: DateTime.parse(map['grantedAt'] as String),
        grantedBy: map['grantedBy'] as String,
        contactId: map['contactId'] as int?,
        version: map['version'] as String,
      );
    }).toList();
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
