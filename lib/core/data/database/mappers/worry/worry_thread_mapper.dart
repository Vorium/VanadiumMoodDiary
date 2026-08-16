// v1.1.0 round 9 (F1 烦恼闭环): WorryThread 映射层
//
// Drift row ↔ WorryThreadEntity 翻译官。
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';

extension WorryThreadToEntity on WorryThread {
  WorryThreadEntity toEntity() {
    return WorryThreadEntity(
      id: id,
      title: title,
      createdAt: createdAt,
      status: WorryStatus.fromWire(status),
      resolvedAt: resolvedAt,
    );
  }
}
