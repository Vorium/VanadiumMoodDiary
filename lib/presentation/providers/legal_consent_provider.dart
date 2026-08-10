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

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
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
///
/// v0.28 round 82 (R82.5 法务审核续): 加 [seal]/[unseal]/[isSealed]/[sealedAt],
/// 给 vent kind 走"PIPL §47 删除权"合规路径: 撤回 vent 同意时, 用户
/// 必选 "立即删除" 或 "加密封存" 二选一 (法务 Q7b 必改)。"封存"= 数据
/// 保留在 DB 但 UI 不可见, 重新同意后可恢复; "删除"= 物理删 DB 行 +
/// 删 audio 文件 (PIPL §47 删除权)。
class LegalConsentStore {
  static const _kPrefix = 'legal_consent_withdrawn_';

  /// v0.27 R82: dataExport audit log key
  /// 跟 [_kPrefix] 区分, 不混。`getStringList` 存累积 JSON 字符串。
  static const _kDataExportLog = 'legal_consent_data_export_log';

  /// v0.28 R82.5: vent "加密封存" 标志 key
  /// 跟 withdrawn 标志区分 (封存 ≠ 撤回)。
  static const _kVentSealedAt = 'legal_consent_vent_sealed_at';

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
    // v0.28 R82.5: reset 也清封存标志 (用户重新同意 = 解封, 数据应该重新可见)
    if (kind == ConsentKind.vent) {
      await prefs.remove(_kVentSealedAt);
    }
    // v0.30 R95 (sub-spec 7 task 31b): reset(ConsentKind.dataExport) 同步清
    // dataExport audit log (PIPL §47 删除权 — 用户撤回数据导出同意 = 撤回
    // 留痕, 之前累积的同意记录也一起清)。非 dataExport kind 不动 audit log
    // (PIPL §17 要求其他 kind 的同意记录保留)。
    if (kind == ConsentKind.dataExport) {
      await prefs.remove(_kDataExportLog);
    }
  }

  /// v0.30 R95 (sub-spec 7 task 31b): 显式清空 dataExport audit log
  ///
  /// PIPL §47 删除权: 用户撤回 dataExport 同意时, 累积的 audit log 也应清
  /// (consent 撤回 = 留痕撤回)。跟 [reset(ConsentKind.dataExport)] 自动清
  /// 路径等价, 但这里提供**显式**入口给"用户主动要求清 audit log" 场景
  /// (e.g. settings 加"清空我的同意记录"按钮)。
  ///
  /// 注意: 法务 Q7b 修订后, audit log 应保留 7 年 (PIPL §17 + §47 冲突),
  /// 这里仅清 **本地** log, 不影响云端 (项目当前零云端, 等于全清)。
  Future<void> clearDataExportAuditLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDataExportLog);
  }

  // ===== v0.28 R82.5: vent "加密封存" 状态 (PIPL §47 撤回 vent 同意时 2 选 1) =====

  /// vent 是否处于"加密封存"状态
  ///
  /// 封存 ≠ 撤回。撤回 = 用户关掉功能, 数据仍可看; 封存 = 数据物理上还在
  /// 但 UI 隐藏, vent_list_page 不展示 (PIPL §47 法务要求"撤回后应提供
  /// 删除选项", 封存 = 用户选了"暂不删但锁住", 跟"立即删除"并列的二选一)。
  Future<bool> isSealed(ConsentKind kind) async {
    if (kind != ConsentKind.vent) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kVentSealedAt) != null;
  }

  /// 封存时间 (撤回 vent 同意时, 选了"加密封存"的时刻)
  Future<DateTime?> sealedAt(ConsentKind kind) async {
    if (kind != ConsentKind.vent) return null;
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_kVentSealedAt);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// 标记 vent 为"加密封存"状态 (撤回同意时选"加密封存"走此路径)
  ///
  /// 不删数据, 只设标志 + 时间。vent_list_page 启动时检测 sealed → 隐藏列表。
  /// 重新同意 = [reset] → 清标志, 数据重新可见。
  Future<void> seal(ConsentKind kind) async {
    if (kind != ConsentKind.vent) {
      throw ArgumentError('seal 当前只支持 ConsentKind.vent');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kVentSealedAt, DateTime.now().millisecondsSinceEpoch);
  }

  /// 解封 (撤回封存状态) — 同 reset 路径
  Future<void> unseal(ConsentKind kind) async {
    if (kind != ConsentKind.vent) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVentSealedAt);
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
  ///
  /// v0.30 R95 (sub-spec 7 task 31a): audit log 走 AES-256 加密存储
  /// - 复用 [EncryptionService.encryptString] (跟 R21 vent contentTextEnc
  ///   BLOB 模式同源密钥, device-bound)
  /// - 加密前 JSON 含 PII 标记 (grantedBy / contactId), 设备 root / 备份偷走
  ///   → 明文泄露违反 PIPL §28
  /// - SharedPreferences 仍存 string list, 但每条 entry 是 base64(iv+ciphertext),
  ///   加密失败 → 走 [swallowError] 集中器 (跟 R21 vent 加密失败模式一致)
  /// - 读取时 [readDataExportConsentLog] 解密失败 → 该条 skip + 走 swallowError
  ///   (避免一条坏数据阻塞整个 audit log 列表)
  Future<void> recordDataExportConsent(ConsentArtifact artifact) async {
    assert(
      artifact.kind == ConsentKind.dataExport,
      'recordDataExportConsent 仅接受 ConsentKind.dataExport, 实际是 ${artifact.kind}',
    );
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kDataExportLog) ?? <String>[];
    final plain = jsonEncode({
      'kind': artifact.kind.name,
      // v0.30 R108 revisit (P0-017): 统一 UTC + 'Z' 后缀,避免跨时区 audit
      // log 时间"瞬移" (北京→纽约 -12/13h) 触发 PIPL §13 法定记录时间不准。
      // 跟 export_orchestrator / safety_config_service / last_error_capture 同
      // 模式,加 .toUtc() 保证 `DateTime.parse()` 反序列化永远当 UTC 读,
      // 不会因为设备 tz 漂移 (DST / 用户改设置) 出现同日/跨日计算错误。
      'grantedAt': artifact.grantedAt.toUtc().toIso8601String(),
      'grantedBy': artifact.grantedBy,
      'contactId': artifact.contactId,
      'version': artifact.version,
    });
    try {
      // v0.30 R95 task 31a: encrypt + base64 后存 (PIPL §28 设备 root 防护)
      final encrypted = await EncryptionService().encryptString(plain);
      await prefs.setStringList(_kDataExportLog, [...existing, encrypted]);
    } catch (e, st) {
      // 加密失败 (R21 vent 模式一致): 走 swallowError, 不抛, 不写
      swallowError(
        where: 'legal_consent.recordDataExportConsent.encrypt',
        error: e,
        stack: st,
        note: 'audit log 加密失败, 跳过本次记录 (不影响主流程)',
      );
    }
  }

  /// v0.27 R82: 读回 dataExport 同意 audit log
  ///
  /// 返回按写入顺序 (FIFO, 时间从早到晚) 的 [ConsentArtifact] 列表。
  /// 法务复查 / 监管审计时给这份 list 即可。
  ///
  /// v0.30 R95 (sub-spec 7 task 31a): 逐条 AES-256 解密, 失败条目 skip
  /// (走 swallowError 集中器, 不阻塞列表其他条目)
  Future<List<ConsentArtifact>> readDataExportConsentLog() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_kDataExportLog) ?? <String>[];
    final out = <ConsentArtifact>[];
    for (final e in entries) {
      try {
        final plain = await EncryptionService().decryptString(e);
        final map = jsonDecode(plain) as Map<String, dynamic>;
        out.add(
          ConsentArtifact(
            kind: ConsentKind.values
                .firstWhere((k) => k.name == map['kind'] as String),
            grantedAt: DateTime.parse(map['grantedAt'] as String),
            grantedBy: map['grantedBy'] as String,
            contactId: map['contactId'] as int?,
            version: map['version'] as String,
          ),
        );
      } catch (err, st) {
        // 单条坏数据: skip + swallow, 不阻塞其他条目
        swallowError(
          where: 'legal_consent.readDataExportConsentLog.decrypt',
          error: err,
          stack: st,
          note: '单条 audit log 解密失败, skip (其他条目继续)',
        );
      }
    }
    return out;
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
