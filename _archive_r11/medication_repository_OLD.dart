import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../utils/json_codec.dart';

/// 吃药信息仓库
class MedicationRepository {
  final AppDatabase _db;

  MedicationRepository(this._db);

  /// 监听所有启用的吃药信息
  Stream<List<Medication>> watchAll() => _db.watchMedications();

  /// 添加吃药
  Future<int> add({
    required String name,
    required double dosage,
    required String dosageUnit,
    required List<TimeOfDay> times,
    DateTime? startDate,
    DateTime? refillAt,
    int refillReminderDays = 7,
    bool isActive = true,
    DateTime? endDate,
  }) {
    return _db.insertMedication(
      MedicationsCompanion.insert(
        name: name,
        dosage: dosage,
        dosageUnit: dosageUnit,
        timesJson: Value(encodeTimes(times)),
        startDate: startDate ?? DateTime.now(),
        refillAt: Value(refillAt),
        refillReminderDays: Value(refillReminderDays),
        isActive: Value(isActive),
        endDate: Value(endDate),
      ),
    );
  }

  /// 更新
  Future<bool> update(Medication medication) => _db.updateMedication(medication);

  /// v0.13 (Round 9) 停药/恢复（软开关，保留历史）
  ///
  /// - isActive=false: 不在主页打卡列表里推送提醒，但历史数据保留
  /// - 用 endDate 标记"停药日期"（保留时间线信息）
  /// - 如果 isActive=true → false: 写 endDate = now
  /// - 如果 isActive=false → true: 清 endDate (恢复)
  Future<bool> setActive({
    required int medicationId,
    required bool isActive,
  }) async {
    final med = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(medicationId)))
        .getSingleOrNull();
    if (med == null) return false;
    final now = DateTime.now();
    final updated = med.copyWith(
      isActive: isActive,
      endDate: isActive
          ? const Value(null) // 恢复：清空 endDate
          : Value(now), // 停药：写 endDate
    );
    return _db.updateMedication(updated);
  }

  /// 删除（硬删除）
  Future<int> delete(int id) => _db.deleteMedication(id);

  /// v0.12 (Round 6) 续方设置
  ///
  /// 只更新续方相关字段，不动其他。
  /// [refillAt] 传 null 表示清空续方日期（同步取消提醒）。
  /// [reminderDays] 传 null 表示不动。
  Future<bool> updateRefill({
    required int medicationId,
    required DateTime? refillAt,
    int? reminderDays,
  }) async {
    final med = await (_db.select(_db.medications)
          ..where((t) => t.id.equals(medicationId)))
        .getSingleOrNull();
    if (med == null) return false;
    final updated = reminderDays != null
        ? med.copyWith(
            refillAt: Value(refillAt),
            refillReminderDays: reminderDays,
          )
        : med.copyWith(refillAt: Value(refillAt));
    return _db.updateMedication(updated);
  }

  /// TimeOfDay 列表序列化为 JSON：[{"h":8,"m":0},{"h":20,"m":0}]
  ///
  /// 用 [jsonEncode] 替代手写拼接，自动处理转义。
  /// **格式必须保持兼容**：老用户数据库里存的就是 `[{"h":N,"m":N}]`。
  static String encodeTimes(List<TimeOfDay> times) {
    if (times.isEmpty) return '[]';
    return jsonEncode([
      for (final t in times) {'h': t.hour, 'm': t.minute},
    ]);
  }
}

/// 旧版空格分隔解析（已废弃，仅向后兼容极老数据）
@Deprecated('Use MedicationTimes extension on Medication instead')
String? deprecatedTimesText(String timesJson) {
  final list = JsonCodec.decodeStringList(timesJson);
  if (list.isEmpty) return null;
  return ' · ${list.join(' / ')}';
}
