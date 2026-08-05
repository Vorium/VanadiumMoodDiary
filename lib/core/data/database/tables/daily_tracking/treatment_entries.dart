import 'package:drift/drift.dart';

/// 治疗记录表
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 次治疗 = 1 条
/// - timestamp: 治疗时间
/// - treatmentType: 'medication' / 'consultation' / 'physiotherapy' / 'other'
///   (R60 模式: TextColumn 自由)
/// - description: 治疗描述
/// - linkedMedicationId: FK medications.id (nullable, R60 不强制外键)
/// - linkedMedicationName: 缓存, 写时 snapshot (R55 medication rename 后
///   历史 treatment 显示原名, 避免名字漂移)
/// - note: 自由备注
@DataClassName('TreatmentEntry')
class TreatmentEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get treatmentType => text()();
  TextColumn get description => text()();
  IntColumn get linkedMedicationId => integer().nullable()();
  TextColumn get linkedMedicationName => text().nullable()();
  TextColumn get note => text().nullable()();
}
