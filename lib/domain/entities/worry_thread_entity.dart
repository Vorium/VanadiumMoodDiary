// v1.1.0 round 9 (论文落地 F1 烦恼闭环): 烦恼主题 (Worry Thread)
//
// 用户记录情绪时可把记录绑定到一个"烦恼主题"。同一烦恼的多条记录组成
// 一个时间线, 闭环后归档到"忆往昔"。
//
// 纯 Dart domain entity (0 flutter 0 drift), 跟 [MoodEntryEntity] 同层。

/// 烦恼主题状态
///
/// - [open]: 进行中 (可继续倾诉 / 可闭环)
/// - [resolved]: 已闭环 (进入忆往昔, 可 reopen)
enum WorryStatus {
  open,
  resolved;

  /// Drift 存储字符串
  String get wire => name;

  /// 从 Drift 字符串还原 (未知值 fallback [open], 兼容老数据)
  static WorryStatus fromWire(String? value) {
    return switch (value) {
      'resolved' => WorryStatus.resolved,
      _ => WorryStatus.open,
    };
  }
}

/// 烦恼主题实体
class WorryThreadEntity {
  final int id;
  final String title;
  final DateTime createdAt;

  /// 当前状态 (open / resolved)
  final WorryStatus status;

  /// 闭环时间 (status == resolved 时非空)
  final DateTime? resolvedAt;

  const WorryThreadEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.status,
    this.resolvedAt,
  });

  /// 是否已闭环 (进入忆往昔)
  bool get isResolved => status == WorryStatus.resolved;

  WorryThreadEntity copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    WorryStatus? status,
    DateTime? resolvedAt,
  }) {
    return WorryThreadEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
