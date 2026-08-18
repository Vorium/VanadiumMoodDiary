// 规则 3 标记: canonical zh fallback, 显示层走 l10n preset_content_l10n.dart

/// 树洞预设标签分类 (R128e 论文 2 §2.1.1 三类分组: 学习工作 / 情感生活 / 身心健康)
enum VentTagCategory {
  /// 学习工作 — 学业 / 工作
  workLife,

  /// 情感生活 — 家庭 / 亲密关系 / 朋友
  emotionalLife,

  /// 身心健康 — 身体 / 情绪 / 其他
  wellBeing,
}

/// 树洞预设标签库（v1.1.0）
///
/// 隐私边界：标签仅用于本地整理检索，不进任何分析/趋势/通知。
/// 预置 8 标签 + 自定义标签长度上限 12。
///
/// v1.1.0 R128e (论文 2 吕沛强《微信小程序树洞》§2.1.1 优化):
/// 8 标签按 3 大类目分组, 便于前端分组渲染 (不影响 DB schema / 兼容性)。
class VentTagLibrary {
  VentTagLibrary._();

  /// 单个标签所属分类 (custom 标签归 wellBeing 默认)
  static VentTagCategory categoryOf(String tag) {
    switch (tag) {
      case '学业':
      case '工作':
        return VentTagCategory.workLife;
      case '家庭':
      case '亲密关系':
      case '朋友':
        return VentTagCategory.emotionalLife;
      case '身体':
      case '情绪':
      case '其他':
      default:
        return VentTagCategory.wellBeing;
    }
  }

  /// 分类的本地化显示名 (前端使用, 走 ARB)
  ///
  /// 注意: 分类顺序固定, 渲染时按此顺序遍历保证一致性
  static const List<VentTagCategory> categoryOrder = [
    VentTagCategory.workLife,
    VentTagCategory.emotionalLife,
    VentTagCategory.wellBeing,
  ];

  /// 分类 → 该分类下所有 preset 标签 (顺序保留)
  static List<String> tagsInCategory(VentTagCategory cat) {
    return presetTags.where((t) => categoryOf(t) == cat).toList();
  }

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
