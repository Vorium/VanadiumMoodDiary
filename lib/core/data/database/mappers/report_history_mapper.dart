// v0.17 round 14 (P2-8): report_history mapper 抽离
// v0.23 round 44: 函数风格 → extension 风格，与其他 mapper 统一

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/report_history_entity.dart';

/// Drift row → domain entity
extension ReportHistoryToEntity on ReportHistory {
  ReportHistoryEntity toEntity() => ReportHistoryEntity(
        id: id,
        windowDays: windowDays,
        generatedAt: generatedAt,
        userName: userName,
        reportText: reportText,
      );
}
