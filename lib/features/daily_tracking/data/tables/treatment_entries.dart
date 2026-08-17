// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — treatment 子表
// (R125 + R126 step 1+2 样板, R126 收官 3 子表之 3/3)

import 'package:drift/drift.dart';

/// 治疗记录表 (R126 阶段 2 step 3 迁移, 收官子表 3/3)
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
