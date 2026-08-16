// v1.1.0 round 9 (论文落地 F1 烦恼闭环): 烦恼主题业务规则
//
// 纯 Dart domain logic (0 flutter 0 drift)。title 生成规则、状态流转等
// 集中在这里, UI / data 层不各自实现。
class WorryThreadLibrary {
  /// title 自动生成规则: 取首条倾诉 note 的前 [maxTitleChars] 字
  ///
  /// - 空白折叠 + 去首尾空白
  /// - 超过上限截断并加省略号
  /// - note 为空 → 通用标题 (UI 提供"未命名烦恼"兜底, 这里保持 null
  ///   让调用方决定; 返回值非空时用返回值)
  static const int maxTitleChars = 20;

  static String? generateTitle(String? note) {
    final text = note?.trim();
    if (text == null || text.isEmpty) return null;
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= maxTitleChars) return collapsed;
    return '${collapsed.substring(0, maxTitleChars)}…';
  }
}
