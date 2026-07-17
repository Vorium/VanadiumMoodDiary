import 'dart:convert';

import '../../domain/entities/hour_minute.dart';
import 'app_database.dart';

/// Medication 的扩展方法：把 timesJson 解析成 `List<HourMinute>`
///
/// 用法：`medication.times`
///
/// 格式：`[{"h":8,"m":0},{"h":20,"m":0}]`
/// 容错：解析失败返回空列表
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
    } catch (_) {
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
