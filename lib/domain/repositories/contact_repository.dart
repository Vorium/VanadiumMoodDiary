// v0.14 (Round 12A) ContactRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';

/// 紧急联系人仓库（domain 接口）
abstract class ContactRepository {
  /// 监听所有启用的联系人（按 sortOrder 升序）
  Stream<List<ContactEntity>> watchAll();

  /// 添加联系人
  ///
  /// v0.27 round 62 (P0-2 修复): 加 `consentArtifact` 参数, 强制 caller
  /// 传 [ConsentArtifact] (PIPL §13 单独同意)。`null` 表示明确选择不
  /// 同意 → 抛 [ConsentMissingError]。UI 层应走 ConsentDialog 收集同意,
  /// 不允许传 `null` 跳过。
  Future<int> add({
    required String name,
    required String phone,
    required ConsentArtifact consentArtifact,
    int sortOrder = 0,
  });

  /// 更新（保留以备 API 稳定，UI 暂未调用）
  Future<bool> update(ContactEntity contact);

  /// 删除（物理删除）
  Future<int> delete(int id);

  /// v0.21 Round 23 (P1-26): 恢复单条(用于 Dismissible 误删 Undo)
  ///
  /// 重新插入原 contact (id 会变,sortOrder/name/phone 保留)
  ///
  /// v0.27 round 62 (P0-2 修复): restore 不需要新 consent, 复用原 contact 的
  /// consent 历史。但 UI 层 Dismissible Undo 时 contact 已删除, 关联 consent
  /// 记录可能已 cascade delete, 这里**不**强制 consentArtifact — restore
  /// 走审计日志, 不走 consent 流程。
  Future<int> restore(ContactEntity contact);
}

/// v0.27 round 62 (P0-2 修复): consent 缺失异常
///
/// 修复前: ContactRepository.add() 0 consent 检查 → UI 可不告知用户就
/// 添 contact → PIPL §13 违规。修复后 add() 强制 `ConsentArtifact`,
/// null / 缺失 → 抛本错, 被 UI 捕走 ConsentDialog 重新收集。
class ConsentMissingError extends Error {
  final String message;
  ConsentMissingError(this.message);
  @override
  String toString() => 'ConsentMissingError: $message';
}
