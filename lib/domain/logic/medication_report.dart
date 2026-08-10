import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_stat_calculator.dart';
import 'package:chroniccare/domain/logic/temp_entry_extractor.dart';

/// 用药报告：最近 N 天（默认 14 天）的用药情况，给医生看的纯文本
///
/// 设计原则：
/// - 受众是医生，不是用户备份：所以不复用 data_export_service 的 JSON 格式
/// - 按"天"统计实际服药（不是按打卡次数），符合医患沟通习惯）
/// - 纯函数：compute() 不读 IO，方便单测
///
/// v0.25 round 58 (spen P1 #12 god class 拆分): 拆 3 纯函数类
///   - MedicationStatCalculator: 单个药统计
///   - TempEntryExtractor:       临时用药提取
///   - MissedDateBuilder:        漏服日期构造
/// MedicationReport 退化为 facade, 协调 3 纯函数 + 累计 stats
class MedicationReport {
  MedicationReport._();

  /// 从 DB 数据计算报告
  ///
  /// 注意：调用方传**所有** checkIns，compute 内部按 [periodStart, periodEnd]
  /// 窗口 filter 一次（避免调用方重复实现，也防止窗口外打卡误入）
  ///
  /// [days] 报告窗口天数，默认 14
  /// [now] 注入当前时间（测试用）
  static MedicationReportData compute({
    required String userName,
    required List<MedicationEntity> meds,
    required List<CheckInEntity> checkIns,
    int days = 14,
    DateTime? now,
  }) {
    final generatedAt = now ?? DateTime.now();
    // 窗口：[today - days + 1, today]（含两端）
    final today =
        DateTime(generatedAt.year, generatedAt.month, generatedAt.day);
    final periodStart = today.subtract(Duration(days: days - 1));
    final periodEnd = today;

    // ===== 窗口内 filter =====
    // 含 periodStart 当天 00:00 到 periodEnd 当天 23:59:59
    final periodEndExclusive = periodEnd.add(const Duration(days: 1));
    final inWindow = checkIns.where((c) {
      return !c.timestamp.isBefore(periodStart) &&
          c.timestamp.isBefore(periodEndExclusive);
    }).toList();

    // 注意：如果 stop 后 medication 行被硬删（目前是软删 isActive=false），
    // 当前 meds 列表（仅 isActive=true）会漏。我们用 callSite 的 medsAllProvider 解决。
    // 这里仅做防御：medById 仍以 meds 入参为准。

    // ===== 临时用药 (R58 抽到 TempEntryExtractor) =====
    final tempEntries = TempEntryExtractor.extract(inWindow);

    // ===== 常吃药统计 (R58 抽到 MedicationStatCalculator) =====
    final medStats = <MedicationStat>[];
    int expectedDoses = 0;
    int actualDoses = 0;

    for (final med in meds) {
      final stat = MedicationStatCalculator.calculate(
        med: med,
        days: days,
        inWindow: inWindow,
        periodStart: periodStart,
      );
      medStats.add(stat);
      expectedDoses += stat.expectedDoseCount;
      actualDoses += stat.actualDoseCount;
    }

    // 漏服 = 期望 - 实际；多打的情况 clamp 到 0
    final missedDoses = (expectedDoses - actualDoses).clamp(0, expectedDoses);
    // 补服 = 实际 - 期望（多打的，反映"漏服后补救"或"加量"）
    final extraDoses = (actualDoses - expectedDoses).clamp(0, 1 << 30);
    // 按时服药 = min(实际, 期望)
    final onTimeDoses = actualDoses.clamp(0, expectedDoses);

    return MedicationReportData(
      userName: userName,
      periodStart: periodStart,
      periodEnd: periodEnd,
      windowDays: days,
      generatedAt: generatedAt,
      medicationStats: medStats,
      tempMedications: tempEntries,
      expectedDoses: expectedDoses,
      actualDoses: actualDoses,
      missedDoses: missedDoses,
      extraDoses: extraDoses,
      onTimeDoses: onTimeDoses,
      hasAnyData: meds.isNotEmpty || tempEntries.isNotEmpty,
    );
  }

  // v0.25 round 58: 4 个 private static method (_calcMedStat /
  // _calcTempEntries / _dayKey / _buildMissedDates) 已拆到
  // MedicationStatCalculator + MissedDateBuilder + TempEntryExtractor.
  // 保留 MedicationStat / TempMedEntry / MedicationReportData 3 个
  // data class (跨纯函数类共享, 不拆).
}

/// 单个药的统计
class MedicationStat {
  // v0.13 (Round 11): 4 层架构 — 持有 domain entity
  final MedicationEntity medication;
  final List<HourMinute> times;
  final int actualDoseDays; // 窗口内实际服药的天数
  final List<DateTime> missedDates; // 漏服的具体日期
  final int actualDoseCount; // 窗口内实际服药次数（一天多次算多次）
  final int expectedDoseCount; // 期望服药次数

  const MedicationStat({
    required this.medication,
    required this.times,
    required this.actualDoseDays,
    required this.missedDates,
    required this.actualDoseCount,
    required this.expectedDoseCount,
  });
}

/// 临时用药条目
class TempMedEntry {
  final DateTime timestamp;
  final String name;
  final String description;

  const TempMedEntry({
    required this.timestamp,
    required this.name,
    required this.description,
  });
}

/// 完整报告数据（计算结果）
class MedicationReportData {
  final String userName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int windowDays;
  final DateTime generatedAt;
  final List<MedicationStat> medicationStats;
  final List<TempMedEntry> tempMedications;
  final int expectedDoses;
  final int actualDoses;
  final int missedDoses;
  final int extraDoses; // 补服次数（actual - expected 的正部分）
  final int onTimeDoses; // 按时服药次数（min(actual, expected)）
  final bool hasAnyData;

  const MedicationReportData({
    required this.userName,
    required this.periodStart,
    required this.periodEnd,
    required this.windowDays,
    required this.generatedAt,
    required this.medicationStats,
    required this.tempMedications,
    required this.expectedDoses,
    required this.actualDoses,
    required this.missedDoses,
    required this.extraDoses,
    required this.onTimeDoses,
    required this.hasAnyData,
  });

  /// 依从率（0-100），无期望时为 `null`（B6 fix）
  ///
  /// 返回 null 表示"无可比较的期望"，UI 应当显示 "—" 而非 "0%"。
  /// 原因：没常吃药的用户若用临时用药，0% 会让医生误以为很差。
  int? get adherencePct {
    if (expectedDoses == 0) return null;
    final raw = (onTimeDoses * 100) / expectedDoses;
    return raw.round().clamp(0, 100);
  }

  /// 渲染为纯文本报告
  ///
  /// v0.25 round 56h (spzh P1 #9 toReportString 重复硬编): 改用 Strings 单一 source
  /// 跟 medication_report_pdf.dart 的 Strings.pdfTitle / pdfFooterNotice /
  /// pdfSection* 保持一致 (PDF + text 双格式同源).
  String toReportString() {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════════');
    buf.writeln('  ${Strings.pdfTitle}');
    buf.writeln('═══════════════════════════════════');
    buf.writeln();
    buf.writeln('患者: ${userName.isEmpty ? '未设置' : userName}');
    buf.writeln(
      '报告周期: ${Formatters.date(periodStart)} 至 ${Formatters.date(periodEnd)}（共 $windowDays 天）',
    );
    buf.writeln('生成时间: ${Formatters.dateTime(generatedAt)}');
    buf.writeln();

    if (!hasAnyData) {
      buf.writeln('—— 暂无用药数据 ——');
      buf.writeln();
      buf.writeln('═══════════════════════════════════');
      buf.writeln(Strings.pdfFooterNotice);
      buf.writeln('═══════════════════════════════════');
      return buf.toString();
    }

    // === 常吃药方案 ===
    buf.writeln('━━━ ${Strings.pdfSectionRoutineMeds} ━━━');
    buf.writeln();
    if (medicationStats.isEmpty) {
      buf.writeln('  （无）');
      buf.writeln();
    } else {
      for (int i = 0; i < medicationStats.length; i++) {
        final s = medicationStats[i];
        final m = s.medication;
        final timesStr = s.times.isEmpty
            ? '未设置时间'
            : s.times
                .map(
                  (t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                )
                .join(' / ');
        final freqStr =
            s.times.isEmpty ? '未设置' : '每日 ${s.times.length} 次（$timesStr）';
        buf.writeln(
          '${i + 1}. ${m.name} ${Formatters.dosage(m.dosage, m.dosageUnit)} · $freqStr',
        );
        buf.writeln('   起始: ${Formatters.date(m.startDate)}');
        buf.writeln(
          '   $windowDays 天内实际服药: ${s.actualDoseDays}/$windowDays 天 (${s.actualDoseCount}/${s.expectedDoseCount} 次)',
        );
        if (s.missedDates.isNotEmpty) {
          final missedStr = s.missedDates.map(Formatters.monthDay).join('、');
          buf.writeln('   ⚠️ 漏服: $missedStr');
        } else {
          buf.writeln('   ✓ 无漏服');
        }
        buf.writeln();
      }
    }

    // === 临时用药 ===
    buf.writeln('━━━ ${Strings.pdfSectionTempMeds} ━━━');
    buf.writeln();
    if (tempMedications.isEmpty) {
      buf.writeln('  （无）');
      buf.writeln();
    } else {
      for (final t in tempMedications) {
        buf.writeln(
          '${Formatters.monthDay(t.timestamp)} ${Formatters.time(t.timestamp)}  ${t.name}  ${t.description}',
        );
      }
      buf.writeln('共 ${tempMedications.length} 次');
      buf.writeln();
    }

    // === 总览 ===
    buf.writeln('━━━ ${Strings.pdfSectionSummary} ━━━');
    buf.writeln();
    buf.writeln('按时服药: $onTimeDoses 次');
    buf.writeln('漏服: $missedDoses 次');
    if (extraDoses > 0) {
      buf.writeln('补服: $extraDoses 次（漏服后补救或加量）');
    }
    buf.writeln('临时用药: ${tempMedications.length} 次');
    final adh = adherencePct;
    buf.writeln('依从率: ${adh == null ? '—' : '$adh%'}');
    buf.writeln();
    buf.writeln('═══════════════════════════════════');
    buf.writeln(Strings.pdfFooterNotice);
    buf.writeln('═══════════════════════════════════');
    return buf.toString();
  }
}
