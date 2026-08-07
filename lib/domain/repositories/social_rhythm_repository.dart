// v0.30 round 91 (sub-spec 7 日常追踪): SocialRhythmRepository — domain 层 abstract
//
// R97-P1-1 (2026-08-07): 新增 abstract interface, 修复 4 层架构违规
// (跟 sleep_repository.dart 同模式, 详见该文件注释)。
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';

/// 社会节律仓库 (domain 接口)
abstract class SocialRhythmRepository {
  Stream<List<SocialRhythmEntryEntity>> watchAll();

  Future<int> add({
    required DateTime date,
    required DateTime wakeTime,
    required DateTime firstMealTime,
    required DateTime lastMealTime,
    int socialMin = 0,
    int workMin = 0,
    int exerciseMin = 0,
  });

  Future<int> delete(int id);
}
