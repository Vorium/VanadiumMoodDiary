// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// 抽 CheckSafetyUseCase (SafetyDetector 的 domain 层包装)
//
// v0.29 R85 (spzh P1 架构修复): SafetyDetector 已从 lib/core/data/services/
// 挪到 lib/domain/logic/safety_detector.dart, 满足 4 层架构"domain 不依赖
// data"硬约束。本 use case 改 import 新路径, 同时旧 lib/core/data/services/
// safety_detector.dart 已删除 (避免 DRY + 死代码)。
//
// 0 副作用: 纯函数 wrapper, 0 Flutter / 0 Drift / 0 service 调。

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/safety_detector.dart';

/// Use case 输入
///
/// 8 个 input 必传 (含 nullable 的"缺席"语义)。所有 inputs 由 caller 注入
/// (presentation 不调 SharedPreferences / DB, 只把 facade 拿到的值传进来)。
class CheckSafetyInput {
  final bool enabled;
  final int threshold;
  final DateTime? lastCheckInAt;
  final DateTime now;
  final DateTime? lastAlertAt;
  final bool inDnd;
  final UserProfileEntity? profile;
  final List<ContactEntity> contacts;

  const CheckSafetyInput({
    required this.enabled,
    required this.threshold,
    required this.lastCheckInAt,
    required this.now,
    required this.lastAlertAt,
    required this.inDnd,
    required this.profile,
    required this.contacts,
  });
}

/// 抽 CheckSafety 业务判定
///
/// v0.27 round 65: SafetyDetector 已经是纯函数 (0 副作用, 8 sealed decision),
/// 本 use case 是它的 domain 层包装, 让 presentation 不再 import
/// data/services/safety_detector (符合"presentation 只 import domain"原则)。
///
/// 业务规则: 跟 SafetyDetector.detect 1:1 — 7 段 early-return:
/// 1. enabled == false          → SafetyDecisionDisabled
/// 2. lastCheckInAt == null     → SafetyDecisionNoData
/// 3. daysSinceLast < threshold → SafetyDecisionOk
/// 4. lastAlertAt isSameDay(now) → SafetyDecisionAlertedToday
/// 5. inDnd                     → SafetyDecisionDndSuppressed
/// 6. profile == null           → SafetyDecisionNoData
/// 7. contacts.isEmpty          → SafetyDecisionNoContacts
/// 8. otherwise                 → SafetyDecisionAlert (走 facade dispatch)
class CheckSafetyUseCase {
  const CheckSafetyUseCase();

  SafetyDecision call(CheckSafetyInput input) {
    return SafetyDetector.detect(
      enabled: input.enabled,
      threshold: input.threshold,
      lastCheckInAt: input.lastCheckInAt,
      now: input.now,
      lastAlertAt: input.lastAlertAt,
      inDnd: input.inDnd,
      profile: input.profile,
      contacts: input.contacts,
    );
  }
}
