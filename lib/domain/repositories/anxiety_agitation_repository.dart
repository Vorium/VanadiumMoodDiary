// v0.30 round 91 (sub-spec 7 日常追踪): AnxietyAgitationRepository — domain 层 abstract
//
// R97-P1-1 (2026-08-07): 新增 abstract interface, 修复 4 层架构违规
// (跟 sleep_repository.dart 同模式, 详见该文件注释)。
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';

/// 焦虑急躁仓库 (domain 接口)
abstract class AnxietyAgitationRepository {
  Stream<List<AnxietyAgitationEntryEntity>> watchAll();

  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  });

  Future<int> delete(int id);
}
