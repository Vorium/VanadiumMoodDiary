// v0.23 (Round 31 P0-11): 用药剂量单位 enum
//
// 之前 8+ 处文件硬编码 'mg' / '片' 字符串值 + String 相等比较:
// - `lib/core/data/services/preset_medication_templates.dart` 6 个默认模板
// - `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` 校验 + dropdown
// - `lib/presentation/pages/setup/setup_step_medication.dart` dropdown
//
// 抽 enum:
// 1. 类型安全 (IDE 自动补全, 重命名一处全改)
// 2. 集中化 ('mg' / '片' 只在 enum 出现, 易发现)
// 3. 静态 fromId() 容错 (未来 enum 改名 / 加值, 老 DB 数据能兜底)
//
// v0.23 设计:
// - id 字段保留 'mg' / '片' 字符串（跟现有 DB 数据兼容, 无需 schema 迁移）
// - v1.0+ 计划迁 '片' → 'tablet' (跟英文 locale 一致), 届时走 migration + 一次性数据迁移脚本
enum DosageUnit {
  mg('mg'),
  tablet('片');

  const DosageUnit(this.id);

  /// 存储到 DB / 跟现有数据兼容的字符串值
  final String id;

  /// 从 DB 字符串反序列化
  ///
  /// 容错: 未知 id 走 [tablet] (兜底, 跟 v0.22 round 30 之前的"未知单位"行为一致)
  static DosageUnit fromId(String? id) {
    if (id == null) return tablet;
    for (final unit in DosageUnit.values) {
      if (unit.id == id) return unit;
    }
    return tablet;
  }
}
