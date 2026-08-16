// v0.25 round 58: MedicationStatCalculator 抽离 (medication_report god class 拆分)
//
// 之前 medication_report.dart 347 行含 5 个 static method + 3 个 data
// class + toReportString, god class 标签。R58 拆 3 纯函数类:
//
//   - MedicationStatCalculator (本文件): 单个药统计 (_calcMedStat + _dayKey)
//   - TempEntryExtractor:       提取临时用药 (_calcTempEntries)
//   - MissedDateBuilder:        构造漏服日期 (_buildMissedDates + _dayKey)
//
// medication_report 留 facade + data class + toReportString, 协调
// 3 纯函数类 + 累计 expected/actual/missed/extra/onTime doses.
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart'
    show MedicationStat;

/// v0.25 round 58 (spen P1 #12 god class 拆分): 单个药统计纯函数
///
/// 接受 window 内 checkIns + 单个 med + 窗口天数, 返回 MedicationStat
/// (实际服药天数 / 漏服日期 / 期望剂量 / 实际剂量).
class MedicationStatCalculator {
  MedicationStatCalculator._();

  /// 单个药的统计 (从原 medication_report._calcMedStat 抽出)
  ///
  /// v0.13 Round 11 起接受 MedicationEntity (domain 抽象, 不依赖 drift row)
  ///
  /// expected = dosesPerDay * effectiveDays (考虑药物 startDate 在窗口
  /// 中途开始的边界, 避免依从率虚低)
  ///
  /// actual = window 内该药 normal 打卡的次数 (按"天"去重: 同一天多次
  /// 打卡算 1 天服药)
  static MedicationStat calculate({
    required MedicationEntity med,
    required int days,
    required List<CheckInEntity> inWindow,
    required DateTime periodStart,
  }) {
    final times = med.times;
    final dosesPerDay = times.isEmpty ? 1 : times.length;
    // 考虑药物 startDate: 如果药物在报告窗口中途才开始, expected
    // 应按实际可服药天数计算, 避免依从率虚低
    final effectiveStart =
        med.startDate.isAfter(periodStart) ? med.startDate : periodStart;
    final effectiveDays =
        periodStart.add(Duration(days: days)).difference(effectiveStart).inDays;
    final effectiveDaysClamped = effectiveDays.clamp(0, days);

    // v0.27 round 60 (审计 M1 修正): medication 未开始 (startDate > periodEnd)
    // 时早返 all-zero stat, 避免 phantom missedDates (报告生成 14 天
    // 假漏服). 修正前: 用户添加"未来某日开始"的药 (如预约挂号开药),
    // 立刻在报告里看到 14 天漏服警告, 显示错误.
    if (effectiveDaysClamped == 0) {
      return MedicationStat(
        medication: med,
        times: times,
        actualDoseDays: 0,
        missedDates: const [],
        actualDoseCount: 0,
        expectedDoseCount: 0,
      );
    }
    final expected = dosesPerDay * effectiveDaysClamped;

    // 按"天"去重: 一颗药同一天多次打卡算 1 天
    final daysWithDose = <String>{};
    int actualForMed = 0;

    for (final c in inWindow) {
      if (!c.isNormal) continue;
      if (c.medicationId != med.id) continue;
      daysWithDose.add(_dayKey(c.timestamp));
      actualForMed++;
    }

    // v0.27 round 60 (审计 M1 修正): missedDays 用 effectiveDaysClamped
    // 而非 full days, 跟 expected 一致. 修正前窗口中途开始的药仍报 14
    // 天漏服 (e.g. startDate = periodStart + 7, 实际只 7 天可服药, 但
    // 旧逻辑 days - daysWithDose = 14 - 0 = 14 phantom 漏服).
    final missedDays =
        (effectiveDaysClamped - daysWithDose.length).clamp(0, days);
    // R113 (BUG 5): missedDates 从 effectiveStart (max(periodStart,
    // med.startDate)) 开始构造, 而不是 periodStart — 修前窗口中途开始的药
    // (今天刚添加) 的漏服日期全部落在开药之前, 报告里"漏服 7/1、7/2..."
    // 用户根本没开始吃。
    final missedDates = MissedDateBuilder.build(
      periodStart: effectiveStart,
      daysWithDose: daysWithDose,
      missedDays: missedDays,
    );

    return MedicationStat(
      medication: med,
      times: times,
      actualDoseDays: daysWithDose.length,
      missedDates: missedDates,
      actualDoseCount: actualForMed,
      expectedDoseCount: expected,
    );
  }

  /// 共享 helper: DateTime → "YYYY-MM-DD" 字符串
  /// (R58 抽到顶层避免 3 个 calculator 重复)
  static String _dayKey(DateTime dt) => Formatters.date(dt);
}

/// v0.25 round 58: 漏服日期构造器 (R58 跟 MedicationStatCalculator 一起
/// 抽出, 共享 _dayKey helper)
class MissedDateBuilder {
  MissedDateBuilder._();

  /// 构造漏服日期列表: 按时间正序, 填前 missedDays 天未服药的日子
  ///
  /// R113 (BUG 5): [periodStart] 语义 = 漏服扫描起点, caller 应传
  /// effectiveStart = max(报告窗口起点, 药物 startDate), 保证不报
  /// "开药之前的漏服"。修前 caller 传窗口起点, 窗口中途开始/今天刚
  /// 添加的药会报一堆 startDate 之前的 phantom 漏服日期。
  static List<DateTime> build({
    required DateTime periodStart,
    required Set<String> daysWithDose,
    required int missedDays,
  }) {
    if (missedDays <= 0) return const [];
    final missed = <DateTime>[];
    for (int d = 0; d < daysWithDose.length + missedDays; d++) {
      final day = periodStart.add(Duration(days: d));
      if (!daysWithDose.contains(_dayKey(day))) {
        missed.add(day);
        if (missed.length >= missedDays) break;
      }
    }
    return missed;
  }

  static String _dayKey(DateTime dt) => Formatters.date(dt);
}
