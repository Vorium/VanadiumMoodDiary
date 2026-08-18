// v1.1.0+182 R128b (R110 阶段 4) — crisis feature entity 抽出
//
// 背景:
// - R92 把 _HotlineEntry + _RegionGroup 当作 page-local private class, 跟
//   page 260L 一起粘在 lib/presentation/pages/crisis_hotline_page.dart
// - R128b 跟其他 5 feature 同构 (mood/vent/assessment/medication/daily_tracking
//   都 features/{name}/domain/entities/), 抽 public 化让 logic 复用
//
// 4 层架构: 0 flutter / 0 drift / 0 data / 0 presentation, pure entity
// (label + number + optional desc + RegionGroup title 列表), 让
// data/logic/hotline_regions.dart 5 region 模板复用, 跟 l10n 解耦。
//
// R128b 修正: private (_HotlineEntry) → public (HotlineEntry) + RegionGroup
// 同 public 化 (logic 调用需要构造 List<HotlineEntry> 给 RegionGroup)。
// (字段全 final, 已是 immutable, 不需要 @immutable 注解, 避免 depend_on_referenced_packages)

/// 单条热线 entry 数据 (label + number + 可选 desc)
class HotlineEntry {
  const HotlineEntry({
    required this.label,
    required this.number,
    this.desc,
  });

  final String label;
  final String number;
  final String? desc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotlineEntry &&
          other.label == label &&
          other.number == number &&
          other.desc == desc;

  @override
  int get hashCode => Object.hash(label, number, desc);
}

/// 地区分组的热线 entry 列表
class RegionGroup {
  const RegionGroup({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<HotlineEntry> entries;
}
