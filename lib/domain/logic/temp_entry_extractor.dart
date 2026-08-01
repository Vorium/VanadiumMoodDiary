// v0.25 round 58: TempEntryExtractor 抽离 (medication_report god class 拆分)
//
// 装 1 个职责: 从 window 内 checkIns 提取临时用药条目 (按时间倒序).
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart'
    show TempMedEntry;

/// v0.25 round 58 (spen P1 #12 god class 拆分): 临时用药条目提取器
///
/// 接受 window 内 checkIns, 过滤 isTemp + 解析 note JSON, 按时间倒序
/// 返回 `List<TempMedEntry>`. 临时用药空 description 退化为 '—' 占位符.
class TempEntryExtractor {
  TempEntryExtractor._();

  /// 提取临时用药条目 (按时间倒序)
  static List<TempMedEntry> extract(List<CheckInEntity> inWindow) {
    final result = <TempMedEntry>[];
    final sorted = [...inWindow]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    for (final c in sorted) {
      if (!c.isTemp) continue;
      final parsed = JsonCodec.parseTempMedNote(c.note);
      result.add(
        TempMedEntry(
          timestamp: c.timestamp,
          name: parsed.name,
          description: parsed.description.isEmpty ? '—' : parsed.description,
        ),
      );
    }
    return result;
  }
}
