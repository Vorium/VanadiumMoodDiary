/// 树洞预设标签库（v1.1.0）
///
/// 隐私边界：标签仅用于本地整理检索，不进任何分析/趋势/通知。
/// 预置 8 标签 + 自定义标签长度上限 12。
class VentTagLibrary {
  VentTagLibrary._();

  static const List<String> presetTags = [
    '家庭',
    '工作',
    '学业',
    '亲密关系',
    '朋友',
    '身体',
    '情绪',
    '其他',
  ];

  /// 自定义标签最大长度（字符）
  static const int maxCustomTagLength = 12;

  /// 标签合法性：非空 + 不超过 [maxCustomTagLength]
  static bool isValidTag(String tag) {
    final t = tag.trim();
    return t.isNotEmpty && t.length <= maxCustomTagLength;
  }
}
