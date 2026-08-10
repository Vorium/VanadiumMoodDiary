import 'dart:convert';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/medication/medication_repository_impl.dart'
    show MedicationRepositoryImpl;
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';

/// Medication 的扩展方法：把 timesJson 解析成 `List<HourMinute>`
///
/// 用法：`medication.times`
///
/// 格式：`[{"h":8,"m":0},{"h":20,"m":0}]`
/// 容错：解析失败返回空列表(通过 [swallowError] 集中记录,便于排查)
///
/// v0.16 (Round 19): 从 `List<TimeOfDay>` 改成 `List<HourMinute>`，消除 data → flutter/material 依赖
extension MedicationTimes on Medication {
  List<HourMinute> get times {
    final raw = timesJson;
    if (raw.isEmpty || raw == '[]') return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final result = <HourMinute>[];
      for (final item in decoded) {
        if (item is Map) {
          final h = item['h'];
          final m = item['m'];
          if (h is int && m is int) {
            result.add(HourMinute(hour: h, minute: m));
          }
        }
      }
      return result;
    } catch (e, st) {
      // v0.23 round 39 (P1-10 fix): 不再 `catch (_)` 完全静默,
      // 走 swallowError 集中器。release 模式不打印,debug 模式打 developer.log
      swallowError(
        where: 'MedicationTimes.times',
        error: e,
        stack: st,
        note: 'timesJson 解析失败: 返回空列表',
      );
      return const [];
    }
  }
}

/// v0.13 (Round 11) 顶层函数：`List<HourMinute>` → JSON
///
/// 从 [MedicationRepositoryImpl] 抽出来，放这里和 parser 成对。
/// **JSON 格式必须保持向后兼容**：`[{"h":8,"m":0},{"h":20,"m":0}]`。
String encodeTimes(List<HourMinute> times) {
  if (times.isEmpty) return '[]';
  return jsonEncode([
    for (final t in times) {'h': t.hour, 'm': t.minute},
  ]);
}
