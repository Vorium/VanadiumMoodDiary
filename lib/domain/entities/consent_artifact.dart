// v0.27 round 63 (P0-3 修复): ConsentArtifact 实体
//
// 背景: PIPL §13 单独同意要求处理敏感个人信息 (精神心理患者数据) 需明确
// 告知数据接收方 + 单独取得同意。修复前添加紧急联系人 0 consent 流程 →
// 通知家人动作 = 未经同意把数据传给第三方。
//
// 设计: domain 0 flutter, 纯 Dart 数据类。数据导出 (PIPL §13 数据可携权)
// 时 caller 传 `ConsentArtifact` 走 ConsentDialog 收集。
//
// v0.27 round 63 (P0-3 修复续): ConsentKind 统一
// 修复前 domain 跟 presentation 各有同名不同值的 ConsentKind enum (domain:
// emergencyContactSharing/dataExport, presentation: safety/vent/analytics)。
// 同名 enum 是未来踩雷的根源 (类型推断错误 + 切换层风险)。修复后 domain
// enum 是 single source of truth, 5 个 kind 全集中在这里, presentation 层
// import 使用。
//
// 1.1.0 round 4b (emotion-first refactor): 外联通信业务删除定版 —
// emergencyContactSharing / safety 2 值整摘 (剩 dataExport / vent /
// analytics 3 值), contactId 字段随 contacts 表整摘删除。
//
// 字段:
// - [kind] 同意类型 (见下方 [ConsentKind] 枚举)
// - [grantedAt] 同意时间 (PIPL §17 数据准确性)
// - [grantedBy] 同意主体 (用户本人 / 代理人)
// - [version] 同意版本号 (e.g. "v1" 法务模板版本, 模板更新需重新同意)
class ConsentArtifact {
  final ConsentKind kind;
  final DateTime grantedAt;
  final String grantedBy;
  final String version;

  const ConsentArtifact({
    required this.kind,
    required this.grantedAt,
    required this.grantedBy,
    required this.version,
  });
}

/// 同意类型 (single source of truth — v0.27 round 63 统一)
///
/// 1.1.0 round 4b: 外联 2 值 (emergencyContactSharing / safety) 整摘, 剩 3 值:
///
/// 1. [dataExport] — PIPL §13 单独同意强场景
///    (数据导出时弹 ConsentDialog 走法务留痕)
/// 2. [vent] / [analytics] — PIPL §14 撤回场景
///    (设置 → 法律与隐私 2 toggle, 关掉后对应功能停用)
enum ConsentKind {
  /// 数据导出 (PIPL §13 + §44, 数据可携权)
  dataExport,

  /// 树洞(敏感倾诉) (PIPL §14) — 关掉后 VentRepository.add 拒绝
  vent,

  /// 评估/情绪分析 (PIPL §14) — 关掉后 trend_page 不展示评估/情绪相关图表
  analytics,
}
