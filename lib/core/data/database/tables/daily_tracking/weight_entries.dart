import 'package:chroniccare/domain/logic/bmi_calculator.dart' show BmiCalculator;
import 'package:drift/drift.dart';

/// 体重记录表
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 天可多次 (e.g. morning/evening)
/// - timestamp: 称重时间
/// - weightKg: 体重 (kg, 1 decimal, 范围 30-200)
/// - bmi: 自动算 (nullable, profile.height 缺失时 null)
///   算法在 [BmiCalculator.compute] (weight / (height_m)²)
/// - note: 自由备注
@DataClassName('WeightEntry')
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bmi => real().nullable()();
  TextColumn get note => text().nullable()();
}
