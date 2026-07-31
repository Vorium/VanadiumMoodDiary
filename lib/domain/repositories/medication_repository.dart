// v0.13 (Round 11) MedicationRepository — 抽象接口（domain 层）
//
// 4 层架构示范：domain 定义"业务能做什么"，data 层提供 Drift 实现。
// UI / UseCase 只依赖这个 abstract class，不直接 import Drift。
//
// 实现方在 `lib/data/repositories/medication_repository_impl.dart`。
//
// v0.25 round 60 (spen P1 #12 #4): add() 改接受 MedicationDraft value object
//   (之前 9 个参数, 拆到 MedicationDraft 更易维护, UI 编辑场景用 copyWith)

import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// 吃药信息仓库（domain 抽象接口）
///
/// UI / UseCase / tests 全部依赖这个接口，**不直接 import Drift**。
abstract class MedicationRepository {
  /// 监听所有启用的药物
  Stream<List<MedicationEntity>> watchAll();

  /// 监听所有药物（含已停药，给"用药报告"用）
  ///
  /// 历史用药可能在窗口内有打卡记录，但 medication.isActive=false，
  /// 报告必须包含这些数据才能完整还原用户服药历史。
  Stream<List<MedicationEntity>> watchAllIncludingInactive();

  /// 添加药物 (v0.25 R60: 用 MedicationDraft value object 替代 9 字段参数)
  Future<int> add(MedicationDraft draft);

  /// 整体更新（用 entity 接收，impl 内部转 Drift row）
  Future<bool> update(MedicationEntity medication);

  /// 软停药 / 恢复
  Future<bool> setActive({
    required int medicationId,
    required bool isActive,
  });

  /// 硬删除
  Future<int> delete(int id);

  /// 只更新续方相关字段
  Future<bool> updateRefill({
    required int medicationId,
    required DateTime? refillAt,
    int? reminderDays,
  });
}
