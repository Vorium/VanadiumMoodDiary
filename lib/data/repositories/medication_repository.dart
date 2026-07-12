import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 吃药信息仓库
class MedicationRepository {
  final AppDatabase _db;

  MedicationRepository(this._db);

  /// 监听所有启用的吃药信息
  Stream<List<Medication>> watchAll() => _db.watchMedications();

  /// 添加吃药
  Future<int> add({
    required String name,
    int frequencyPerDay = 1,
    String timesJson = '[]',
    DateTime? startDate,
  }) {
    return _db.insertMedication(
      MedicationsCompanion.insert(
        name: name,
        frequencyPerDay: Value(frequencyPerDay),
        timesJson: Value(timesJson),
        startDate: startDate ?? DateTime.now(),
      ),
    );
  }

  /// 更新
  Future<bool> update(Medication medication) => _db.updateMedication(medication);

  /// 删除（软删除）
  Future<int> delete(int id) => _db.deleteMedication(id);
}
