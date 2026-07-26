// v0.13 (Round 11) MedicationMapper — Drift row ↔ domain entity
//
// 边界处的"翻译官"。Drift 内部 schema（`Medication` row）变化时，
// 只需要改 mapper，UI 拿到的 entity 保持稳定。
//
// 设计：
// - 用 Dart extension 让 `Medication.toEntity()` / `MedicationEntity.toDriftRow()`
//   调用自然
// - JSON 序列化的细节（timesJson）封装在这里，UI 不感知
// - 复用 `MedicationTimes` extension（`med.times` getter）解析 timesJson，
//   避免重复实现 JSON 解析
library;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';

/// Drift row → entity
extension MedicationToEntity on Medication {
  /// 复用 MedicationTimes 扩展解析 timesJson 为 `List<HourMinute>`
  MedicationEntity toEntity() {
    return MedicationEntity(
      id: id,
      name: name,
      dosage: dosage,
      dosageUnit: DosageUnit.fromId(dosageUnit),
      times: times, // 用 MedicationTimes 扩展的 getter
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      refillAt: refillAt,
      refillReminderDays: refillReminderDays,
    );
  }
}

/// entity → Drift row
extension MedicationEntityToDrift on MedicationEntity {
  /// 把 entity 还原成 Drift row（用于 `update()`）
  Medication toDriftRow() {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      dosageUnit: dosageUnit.id,
      timesJson: encodeTimes(times),
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      refillAt: refillAt,
      refillReminderDays: refillReminderDays,
    );
  }

  /// 构造 insert 用的 Companion（用于 `add()`）
  ///
  /// 用 [Value.absent] 处理可空字段的"不传 = 用 SQL 默认"
  MedicationsCompanion toCompanion() {
    return MedicationsCompanion(
      id: const Value.absent(),
      name: Value(name),
      dosage: Value(dosage),
      dosageUnit: Value(dosageUnit.id),
      timesJson: Value(encodeTimes(times)),
      startDate: Value(startDate),
      endDate: Value(endDate),
      isActive: Value(isActive),
      refillAt: Value(refillAt),
      refillReminderDays: Value(refillReminderDays),
    );
  }
}
