// v0.27 round 62 (P0-2 修复): ConsentArtifact 实体
//
// 背景: PIPL §13 单独同意要求处理敏感个人信息 (精神心理患者数据 + 紧急
// 联系人数据) 需明确告知数据接收方 + 单独取得同意。修复前添加紧急联系人
// 0 consent 流程 → 通知家人动作 = 未经同意把数据传给第三方。
//
// 设计: domain 0 flutter, 纯 Dart 数据类。`ContactRepository.add()` 强制
// caller 传 `ConsentArtifact` (可空表示显式选择不接受, UI 层需走 ConsentDialog
// 收集)。
//
// 字段:
// - [kind] 同意类型 (emergencyContactSharing / dataExport / ...)
// - [grantedAt] 同意时间 (PIPL §17 数据准确性)
// - [grantedBy] 同意主体 (用户本人 / 代理人, 未来支持紧急联系人代同意)
// - [contactId] 关联 contact id (kind=emergencyContactSharing 时必填)
// - [version] 同意版本号 (e.g. "v1" 法务模板版本, 模板更新需重新同意)
class ConsentArtifact {
  final ConsentKind kind;
  final DateTime grantedAt;
  final String grantedBy;
  final int? contactId;
  final String version;

  const ConsentArtifact({
    required this.kind,
    required this.grantedAt,
    required this.grantedBy,
    this.contactId,
    required this.version,
  });
}

enum ConsentKind {
  /// 紧急联系人数据共享 (PIPL §13, 失联通知 → 通知家人)
  emergencyContactSharing,

  /// 数据导出 (PIPL §13 + §44, 数据可携权)
  dataExport,
}
