// R128e (论文3 §5.3 引导化解决烦恼 / 图9 帮助打开思路): 烦恼引导提示
//
// 用户写下一个烦恼后, 给一句引导提示帮 ta 打开思路 (认知重构引导),
// 而不是只被动记录。提示按 thread.createdAt 稳定轮换 (同一个烦恼
// 每次看都是同一句, 不闪烁), 避免随机跳转造成干扰。
//
// domain 层 (0 Flutter), 只负责"选哪一条索引", 文案走 l10n
// (worryGuidance1..5, check_orphan_arb_keys 守门员防孤儿)。

class WorryGuidance {
  WorryGuidance._();

  /// 引导提示总条数 (跟 ARB worryGuidance1..5 对齐)
  static const int guidanceCount = 5;

  /// 按烦恼创建时刻稳定选一条引导索引 (1..5, 闭区间)。
  ///
  /// 用 createdAt.day + hour 做种子, 同一个烦恼每次打开都得到同一句,
  /// 不随页面重建闪烁。加 1 保证最小为 1 (避免 0)。
  static int guidanceIndexFor(DateTime createdAt) {
    final seed = createdAt.day + createdAt.hour;
    return (seed % guidanceCount) + 1;
  }
}
