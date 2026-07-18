// v0.17 round 14 (P2-8): report_history mapper 抽离
//
// 之前 _toEntity 内联在 ReportHistoryRepositoryImpl 里。round 11 抽其他
// feature 的 mapper 时漏了这两个 (user_profile + report_history),这次补齐。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/report_history_entity.dart';

/// Drift row → domain entity
ReportHistoryEntity reportHistoryFromRow(ReportHistory r) =>
    ReportHistoryEntity(
      id: r.id,
      windowDays: r.windowDays,
      generatedAt: r.generatedAt,
      userName: r.userName,
      reportText: r.reportText,
    );
