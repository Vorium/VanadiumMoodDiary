// v0.32 R112 (AR-20 god class 批2b): 抽 add_medication_page 提交流程
//
// 改前: `add_medication_page.dart` 573L, `_save` (line 89-133) 内联
//   repo.add + repo.watchAll().first + 双 reschedule, page 同时管 form +
//   validation + submit 3 职责。
// 改后: 抽 AddMedicationSubmitFlow 静态编排 (repo.add → 最新列表 →
//   双提醒重排), 0 UI 0 context (snackbar / pop / _saving 状态留在 page)。
//   跟 R108 delegate namespace + R112 AR-20 批1 export pipeline 拆
//   同款 "编排集中" 模式。
//
// B1-8 (R110 round 7b) 语义保留: 原来 `ref.refresh(medicationsProvider.future)`
// 在 autoDispose provider 无监听者时会在 loading 态被 dispose →
// "disposed during loading state" Bad state → 保存成功却报失败。
// 改用 repository.watchAll().first 拿最新列表 (repo 非 autoDispose, 无
// 生命周期问题), 语义等价 (单次最新快照)。不回归。

import 'package:chroniccare/core/data/services/notification_delegate.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';

/// 新增用药提交流程 (R112 AR-20 批2b 抽静态编排)
///
/// 0 UI 0 context: repo.add + 重排双提醒。异常原样上抛由 page catch
/// (snackbar / _saving 恢复归 page 管)。
class AddMedicationSubmitFlow {
  // 不可实例化 — 纯编排函数类
  const AddMedicationSubmitFlow._();

  /// repo.add(draft) → 最新列表 → 双 reschedule
  ///
  /// 跟原 `_save` (line 106-116) 1:1。B1-8: watchAll().first 单次快照
  /// 避免 autoDispose provider dispose-while-loading (见文件头注释)。
  static Future<void> run({
    required MedicationRepository repo,
    required NotificationDelegate delegate,
    required MedicationDraft draft,
  }) async {
    await repo.add(draft);
    // 新增药物后重排提醒 (edit_medication_dialog 同款模式),
    // 否则新药无提醒直到重启
    final meds = await repo.watchAll().first;
    await delegate.rescheduleMedicationReminders(meds);
    await delegate.rescheduleRefillReminders(meds);
  }
}
