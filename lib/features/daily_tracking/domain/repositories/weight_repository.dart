// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — weight abstract
import 'package:chroniccare/features/daily_tracking/domain/entities/weight_entry.dart';

abstract class WeightRepository {
  Stream<List<WeightEntryEntity>> watchAll();

  Future<int> add({
    required DateTime timestamp,
    required double weightKg,
    double? bmi,
    String? note,
  });

  Future<int> delete(int id);
}
