// 导入计数聚合器 — v1.1.0 R113 wave 5 (gdc P1-7 god class 拆分)
//
// 从 export_import_pipeline.dart 抽出 (R112-ARCH-03 加的 ImportResultBuilder),
// 按 R113 gdc 审计建议按实体簇拆 3 文件后, 本类被 import_entities /
// import_vent / pipeline facade 三处共享, 独立成 import_shared.dart。
//
// PURE MOVE: 类内容逐行不变, 只换文件。

import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';

/// v0.32 架构批 2 (R112-ARCH-03): 导入计数聚合器
///
/// 4 个子任务各自 +1, 最后 [build] 装配成 [ImportResult.success]。
/// 6 张 daily tracking 表 (R91) 不进 ImportResult 摘要 (跟拆分前一致)。
class ImportResultBuilder {
  int medicationCount = 0;
  int checkInCount = 0;
  int reportHistoryCount = 0;
  int moodEntryCount = 0;
  int ventEntryCount = 0;

  ImportResult build() => ImportResult.success(
        medicationCount: medicationCount,
        checkInCount: checkInCount,
        reportHistoryCount: reportHistoryCount,
        moodEntryCount: moodEntryCount,
        ventEntryCount: ventEntryCount,
      );
}
