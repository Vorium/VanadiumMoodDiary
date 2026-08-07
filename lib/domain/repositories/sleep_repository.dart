// v0.30 round 91 (sub-spec 7 日常追踪): SleepRepository — domain 层 abstract
//
// R97-P1-1 (2026-08-07): 新增 abstract interface, 修复 4 层架构违规。
// 修前: daily_tracking_providers.dart 用 `Provider<SleepRepositoryImpl>`
// 直接暴露 data 层 impl type, 违反 AGENTS.md 约束
// "presentation provider 用 Provider<X>(...) 暴露 XRepository (domain 接口),
// 不暴露 impl"。修后: provider 改 `Provider<SleepRepository>`, impl 类
// `implements SleepRepository`。
//
// 跟 mood_repository.dart / vent_repository.dart 同模式 (1 file 1 abstract)。
import 'package:chroniccare/domain/entities/sleep_entry.dart';

/// 睡眠仓库 (domain 接口)
abstract class SleepRepository {
  /// 监听所有 sleep 条目 (按 date DESC)
  Stream<List<SleepEntryEntity>> watchAll();

  /// 新增 sleep entry
  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  });

  /// 删除一条
  Future<int> delete(int id);
}
