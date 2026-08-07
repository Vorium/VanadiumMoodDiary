// v0.27 round 67 (Sprint 1 上架前 P0): ConsentGate — 跨层同意状态网关
//
// 背景: R67 修复前 `legalConsentWithdrawnProvider` 只被 legal_page 自己读, 业务
// 层 (VentRepository / CareEngine / trend_page) 0 拦截 → PIPL §14 严重违反
// (spzh 视角 C-P0-6)。R67 修复路径: 业务层在 entry point 检查同意状态, 撤回
// 后该功能**真正停用** (而非只更新 SharedPreferences)。
//
// 架构原因: VentRepositoryImpl / CareEngine 在 data / domain 层, **不能 import
// flutter_riverpod** (4 层架构硬约束)。LegalConsentStore 内部用
// SharedPreferences (async), 注入到 data/domain 层需要"可注入的 future
// function" 或 domain 抽象接口。
//
// 方案: 在 [core/shared/] 加 [ConsentGate] 抽象接口 + [SharedPrefsConsentGate]
// 默认实现。Riverpod provider `consentGateProvider` (presentation 层) 实例化
// 默认实现, vent_repository_provider / care_engine 通过构造函数注入。
//
// 用法 (data 层):
// ```dart
// class VentRepositoryImpl {
//   final ConsentGate _gate;
//   VentRepositoryImpl(this._db, this._gate);
//   Future<int> add(...) async {
//     if (await _gate.isWithdrawn(ConsentKind.vent)) {
//       throw VentConsentWithdrawnError();
//     }
//     ...
//   }
// }
// ```
//
// 用法 (presentation 层, vent_providers.dart):
// ```dart
// final ventRepositoryProvider = Provider<VentRepository>(
//   (ref) => VentRepositoryImpl(
//     ref.watch(databaseProvider),
//     ref.watch(consentGateProvider),  // ← 注入 gate
//   ),
// );
// ```

import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';

/// 同意状态网关 (跨层接口)
abstract class ConsentGate {
  /// 某 [ConsentKind] 是否被用户撤回
  ///
  /// 返回 true = 撤回, 业务层应**拒绝**相关操作;
  /// 返回 false = 已同意 (或从未撤回), 业务层正常执行。
  Future<bool> isWithdrawn(ConsentKind kind);
}

/// SharedPreferences 实现的 ConsentGate (默认实现)
///
/// R97-P1-12 (2026-08-07): 移除 presentation 层 import (架构违规)。
/// 跟 presentation 层 LegalConsentStore 共享同一份 SharedPreferences key
/// 命名规则 (`legal_consent_withdrawn_<kind>`), 跟 presentation 层
/// legalConsentWithdrawnProvider 双向同步 (通过 key 约定, 非 import)。
class SharedPrefsConsentGate implements ConsentGate {
  static const _kPrefix = 'legal_consent_withdrawn_';

  const SharedPrefsConsentGate();

  @override
  Future<bool> isWithdrawn(ConsentKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kPrefix${kind.name}') ?? false;
  }
}
