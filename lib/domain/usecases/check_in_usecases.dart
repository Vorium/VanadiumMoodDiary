// v0.14 (Round 12B) CheckIn 业务用例
//
// 4 层架构：UseCase 放 domain 层（业务规则），调 abstract CheckInRepository
// UI 层（Notifier）只调 use case，不直接碰 repository
//
// 设计原则：
// - 一个 use case = 一个原子业务操作
// - 接受抽象（CheckInRepository），不依赖具体实现
// - 业务规则（如：失败重试、event 触发）放 use case 里，不放 notifier
// - call() 入口：`(args) => repo.xxx()` 的薄封装，业务规则逐步丰富
//
// 当前 3 个 use case 对应 CheckInNotifier 之前的 3 个方法：
// - RecordCheckInUseCase.checkIn()         → 每日打卡
// - RecordTempMedicationUseCase.addTemp()  → 临时吃药
// - TriggerReminderUseCase.trigger()       → 手动触发失联检测（debug 入口）

import 'package:chroniccare/core/shared/date_time_resolver.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/reminder_checker.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';

/// 每日打卡 use case
class RecordCheckInUseCase {
  final CheckInRepository _checkInRepo;

  /// P0-10 fix: check-in 后同步更新 user_profiles.lastCheckInAt。
  /// 之前这个列是 write-only dead code,现在接上。
  final UserProfileRepository _userProfileRepo;

  RecordCheckInUseCase(this._checkInRepo, this._userProfileRepo);

  /// 记录一次"今天吃了药"打卡
  ///
  /// [medicationId] 用于 deep linking 通知 → 自动打卡该药（v0.11 Round 5）
  /// [at] 注入时间（测试用），默认 DateTime.now()
  ///
  /// 返回新插入的 check_in id
  ///
  /// 副作用: 同时更新 user_profiles.lastCheckInAt,让 UI 快速拿到
  /// 「上次打卡」而不必 JOIN check_ins 表。
  Future<int> call({int? medicationId, DateTime? at}) async {
    final time = DateTimeResolvers.at(at);
    final id = await _checkInRepo.checkIn(medicationId: medicationId, at: time);
    await _userProfileRepo.updateLastCheckIn(time);
    return id;
  }
}

/// 临时吃药 use case
class RecordTempMedicationUseCase {
  final CheckInRepository _repo;
  RecordTempMedicationUseCase(this._repo);

  /// 记录一次临时吃药（不影响 streak）
  ///
  /// [name] 药名
  /// [note] 备注（reason, 病情描述等）
  /// [at] 注入时间（测试用）
  Future<int> call({
    required String name,
    required String note,
    DateTime? at,
  }) {
    return _repo.addTempMedication(name: name, note: note, at: at);
  }
}

/// 手动触发失联检测（debug / settings 入口）
class TriggerReminderUseCase {
  final ReminderChecker _checker;
  TriggerReminderUseCase(this._checker);

  /// 主动跑一次失联检测 + 发送通知
  ///
  /// 返回 true = 通知已发送，false = 跳过了（未到时间或没联系人）
  Future<bool> call() async {
    final result = await _checker.checkAndSend();
    return result.level != ReminderLevel.none;
  }
}
