// v0.29 round 84 (CBT 思维记录): 三档可切换的思维记录深度
//
// - three: 3 栏（入门版，情境/自动思维/情绪）
// - five: 5 栏（Beck 标准，加支持-反对证据 + 替代思维 + 重新评分）
// - seven: 7 栏（深度版，再加核心信念 + 行为应对）
//
// 设计要点:
// 1. 0 flutter 0 drift — domain 层纯 Dart,易测试
// 2. columnCount 跟 drift schema (mood_entries CBT 列) 1:1 对应
// 3. fromInt 非法值 fallback 到 three (跟老 SP 数据 + 手改配置场景容错)
enum ThoughtRecordLevel {
  three,
  five,
  seven;

  /// 栏位数 (3 / 5 / 7), 跟 mood_entries 表 CBT 列 1:1 对应
  int get columnCount {
    switch (this) {
      case ThoughtRecordLevel.three:
        return 3;
      case ThoughtRecordLevel.five:
        return 5;
      case ThoughtRecordLevel.seven:
        return 7;
    }
  }

  /// 反向解析: 3/5/7 → enum, 非法值 fallback 到 three
  ///
  /// 兼容场景:
  /// - SP 里存了意外值 (e.g. schema 升级中临时写盘)
  /// - 用户手改配置 / debug 时把 int 改坏
  /// - 未来从外部导入的备份数据
  static ThoughtRecordLevel fromInt(int value) {
    switch (value) {
      case 3:
        return ThoughtRecordLevel.three;
      case 5:
        return ThoughtRecordLevel.five;
      case 7:
        return ThoughtRecordLevel.seven;
      default:
        return ThoughtRecordLevel.three;
    }
  }
}
