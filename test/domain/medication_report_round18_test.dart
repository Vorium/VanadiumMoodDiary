import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 固定"今天"= 2026-07-13，方便断言窗口边界
  final now = DateTime(2026, 7, 13, 14, 8);

  MedicationEntity med({
    int id = 1,
    String name = '氟西汀',
    double dosage = 40,
    DosageUnit unit = DosageUnit.mg,
    String timesJson = '[{"h":8,"m":0}]', // 每日 1 次（保留旧 API 兼容）
    List<HourMinute>? times,
    DateTime? startDate,
  }) {
    return MedicationEntity(
      id: id,
      name: name,
      dosage: dosage,
      dosageUnit: unit,
      times: times ?? const [HourMinute(hour: 8, minute: 0)],
      startDate: startDate ?? DateTime(2026, 5, 1),
      endDate: null,
      isActive: true,
      refillAt: null,
      refillReminderDays: 7,
    );
  }

  CheckInEntity normalCI({
    required int medicationId,
    required DateTime at,
  }) {
    return CheckInEntity(
      id: at.millisecondsSinceEpoch,
      timestamp: at,
      type: CheckInType.normal,
      medicationId: medicationId,
      note: null,
    );
  }

  CheckInEntity tempCI({
    required DateTime at,
    required String note,
  }) {
    return CheckInEntity(
      id: at.millisecondsSinceEpoch,
      timestamp: at,
      type: CheckInType.temp,
      medicationId: null,
      note: note,
    );
  }

  group('MedicationReport.compute', () {
    test('空数据：报告标记 hasAnyData=false', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: const [],
        now: now,
      );
      expect(r.hasAnyData, false);
      expect(r.medicationStats, isEmpty);
      expect(r.tempMedications, isEmpty);
    });

    test('窗口边界：[today - 13, today]（共 14 天）', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: const [],
        now: now,
      );
      expect(r.windowDays, 14);
      expect(r.periodStart, DateTime(2026, 6, 30));
      expect(r.periodEnd, DateTime(2026, 7, 13));
    });

    test('窗口 = 7 天：[today - 6, today]', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: const [],
        days: 7,
        now: now,
      );
      expect(r.windowDays, 7);
      expect(r.periodStart, DateTime(2026, 7, 7));
      expect(r.periodEnd, DateTime(2026, 7, 13));
      expect(r.expectedDoses, 7); // 每日 1 次 × 7
    });

    test('窗口 = 30 天：[today - 29, today]', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: const [],
        days: 30,
        now: now,
      );
      expect(r.windowDays, 30);
      expect(r.periodStart, DateTime(2026, 6, 14));
      expect(r.periodEnd, DateTime(2026, 7, 13));
      expect(r.expectedDoses, 30);
    });

    test('期望次数 = 每日次数 × 窗口天数', () {
      // 每日 2 次 × 14 天 = 28
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [
          med(
            times: const [
              HourMinute(hour: 8, minute: 0),
              HourMinute(hour: 20, minute: 0),
            ],
          ),
        ],
        checkIns: const [],
        now: now,
      );
      expect(r.expectedDoses, 28);
      expect(r.actualDoses, 0);
      expect(r.missedDoses, 28);
      expect(r.adherencePct, 0);
    });

    test('timesJson 为空：按每日 1 次计算（兜底）', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med(timesJson: '[]')],
        checkIns: const [],
        now: now,
      );
      expect(r.expectedDoses, 14);
    });

    test('完全按时服药：依从率 100%，无漏服', () {
      // 每日 1 次 × 14 天 = 14 次打卡
      final checkIns = <CheckInEntity>[];
      for (int d = 0; d < 14; d++) {
        final at = DateTime(2026, 6, 30).add(Duration(days: d, hours: 8));
        checkIns.add(normalCI(medicationId: 1, at: at));
      }
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: checkIns,
        now: now,
      );
      expect(r.actualDoses, 14);
      expect(r.expectedDoses, 14);
      expect(r.missedDoses, 0);
      expect(r.adherencePct, 100);
      expect(r.medicationStats.first.missedDates, isEmpty);
    });

    test('漏服 1 天：实际天数 13/14', () {
      // 缺 7/5 那一天
      final checkIns = <CheckInEntity>[];
      for (int d = 0; d < 14; d++) {
        final day = DateTime(2026, 6, 30).add(Duration(days: d));
        if (day == DateTime(2026, 7, 5)) continue;
        checkIns.add(
          normalCI(
            medicationId: 1,
            at: day.add(const Duration(hours: 8)),
          ),
        );
      }
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: checkIns,
        now: now,
      );
      expect(r.actualDoses, 13);
      expect(r.missedDoses, 1);
      expect(r.adherencePct, 93); // 13/14 = 92.86 → round 93
      expect(r.medicationStats.first.missedDates.length, 1);
      expect(r.medicationStats.first.missedDates.first, DateTime(2026, 7, 5));
    });

    test('同一天多次打卡：按"天"算 1 天，次数照加', () {
      // 7/3 打了 2 次卡，7/5 没打
      final checkIns = <CheckInEntity>[];
      for (int d = 0; d < 14; d++) {
        final day = DateTime(2026, 6, 30).add(Duration(days: d));
        if (day == DateTime(2026, 7, 5)) continue;
        checkIns.add(
          normalCI(
            medicationId: 1,
            at: day.add(const Duration(hours: 8)),
          ),
        );
      }
      // 7/3 第二次
      checkIns.add(
        normalCI(
          medicationId: 1,
          at: DateTime(2026, 7, 3, 20, 0),
        ),
      );
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: checkIns,
        now: now,
      );
      final s = r.medicationStats.first;
      expect(s.actualDoseDays, 13); // 14 - 1 漏服天
      expect(s.actualDoseCount, 14); // 13 天 + 7/3 那次重复
      expect(s.missedDates.length, 1);
    });

    test('窗口外的打卡不计入', () {
      // 7/14 之后才打卡（窗口外）→ 期望 14 实际 0
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          normalCI(medicationId: 1, at: DateTime(2026, 7, 14, 8, 0)),
        ],
        now: now,
      );
      expect(r.actualDoses, 0);
      expect(r.missedDoses, 14);
    });

    test('窗口外的打卡不影响漏服日期', () {
      // 7/3 + 7/4 打卡，7/14（窗口外）也打卡 → 7/5-7/13 仍漏服
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          normalCI(medicationId: 1, at: DateTime(2026, 7, 3, 8, 0)),
          normalCI(medicationId: 1, at: DateTime(2026, 7, 4, 8, 0)),
        ],
        now: now,
      );
      expect(r.medicationStats.first.actualDoseDays, 2);
      expect(r.medicationStats.first.missedDates.length, 12);
    });

    test('多药独立统计', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [
          med(
            id: 1,
            name: '氟西汀',
            times: const [HourMinute(hour: 8, minute: 0)],
          ),
          med(
            id: 2,
            name: '碳酸锂',
            times: const [
              HourMinute(hour: 8, minute: 0),
              HourMinute(hour: 20, minute: 0),
            ],
          ),
        ],
        checkIns: [
          // 氟西汀：全 14 天
          for (int d = 0; d < 14; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
          // 碳酸锂：只在 7 天里早晚打卡
          for (int d = 0; d < 7; d++) ...[
            normalCI(
              medicationId: 2,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
            normalCI(
              medicationId: 2,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 20)),
            ),
          ],
        ],
        now: now,
      );
      expect(r.medicationStats.length, 2);
      // 氟西汀：14/14 天，0 漏服
      final s1 =
          r.medicationStats.firstWhere((s) => s.medication.name == '氟西汀');
      expect(s1.actualDoseDays, 14);
      expect(s1.missedDates, isEmpty);
      // 碳酸锂：7/14 天，7 漏服
      final s2 =
          r.medicationStats.firstWhere((s) => s.medication.name == '碳酸锂');
      expect(s2.actualDoseDays, 7);
      expect(s2.missedDates.length, 7);
      // 总览：14 + 14 = 28 实际；14 + 28 = 42 期望
      expect(r.actualDoses, 28);
      expect(r.expectedDoses, 42);
      expect(r.missedDoses, 14);
      expect(r.adherencePct, 67); // 28/42 = 66.67 → 67
    });

    test('用户多打：补服维度拆出，依从率 clamp 到 100%', () {
      // 每日 1 次的药但用户每天打 3 次 → 期望 14 实际 42
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          for (int d = 0; d < 14; d++) ...[
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 12)),
            ),
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 20)),
            ),
          ],
        ],
        now: now,
      );
      expect(r.actualDoses, 42);
      expect(r.expectedDoses, 14);
      expect(r.missedDoses, 0);
      expect(r.onTimeDoses, 14); // 按时 = min(42, 14)
      expect(r.extraDoses, 28); // 补服 = 42 - 14
      expect(r.adherencePct, 100); // clamp，不显示 300%
    });

    test('按时/漏服都有的混合场景', () {
      // 每日 1 次，14 天期望；实际打了 10 次（漏 4 天）
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          for (int d = 0; d < 10; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
        ],
        now: now,
      );
      expect(r.actualDoses, 10);
      expect(r.expectedDoses, 14);
      expect(r.onTimeDoses, 10);
      expect(r.missedDoses, 4);
      expect(r.extraDoses, 0);
      expect(r.adherencePct, 71); // 10/14 = 71.4 → 71
    });

    test('补服 + 漏服混合：按时 = onTimeDoses', () {
      // 7 天打了 1 次，3 天打了 2 次（其中 1 次算补服），3 天没打
      // 期望 14；实际：7 + 3*2 = 13；按时 = min(13,14) = 13
      // 漏服 = 14 - 13 = 1；补服 = 13 - 14 = 0
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          for (int d = 0; d < 7; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
          for (int d = 7; d < 10; d++) ...[
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 20)),
            ),
          ],
        ],
        now: now,
      );
      expect(r.actualDoses, 13);
      expect(r.onTimeDoses, 13);
      expect(r.missedDoses, 1);
      expect(r.extraDoses, 0);
    });

    test('临时用药：按时间倒序，note "药名: 备注" 解析', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          tempCI(at: DateTime(2026, 7, 6, 22, 15), note: '右佐匹克隆: 失眠'),
          tempCI(at: DateTime(2026, 7, 2, 14, 30), note: '阿普唑仑: 睡前焦虑'),
        ],
        now: now,
      );
      expect(r.tempMedications.length, 2);
      // 倒序：7/6 在前
      expect(r.tempMedications.first.name, '右佐匹克隆');
      expect(r.tempMedications.first.description, '失眠');
      expect(r.tempMedications.last.name, '阿普唑仑');
    });

    test('临时用药：note 没有冒号 → 整段作为药名', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          tempCI(at: DateTime(2026, 7, 6, 22, 15), note: '布洛芬 200mg'),
        ],
        now: now,
      );
      expect(r.tempMedications.first.name, '布洛芬 200mg');
      expect(r.tempMedications.first.description, '—');
    });

    test('非 normal 非 temp 的打卡（如 phq9 评估）不计入', () {
      // phq9 评估不算常吃药、也不算临时用药
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 3, 10, 0),
            type: CheckInType.phq9,
            medicationId: null,
            note: '{"scale":"phq9","scores":[1,2,3],"total":6}',
          ),
        ],
        now: now,
      );
      expect(r.actualDoses, 0);
      expect(r.tempMedications, isEmpty);
    });
  });

  group('MedicationReportData.toReportString', () {
    test('空数据：渲染"暂无用药数据"', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: const [],
        now: now,
      );
      final s = r.toReportString();
      expect(s, contains('慢病管家 · 用药报告'));
      expect(s, contains('小明'));
      expect(s, contains('2026-06-30'));
      expect(s, contains('2026-07-13'));
      expect(s, contains('暂无用药数据'));
      expect(s, contains('不提供医疗建议'));
    });

    test('完整数据：含常吃药 + 临时用药 + 总览', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          for (int d = 0; d < 14; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
          tempCI(at: DateTime(2026, 7, 6, 22, 15), note: '右佐匹克隆: 失眠'),
        ],
        now: now,
      );
      final s = r.toReportString();
      // 标题段
      expect(s, contains('患者: 小明'));
      expect(s, contains('共 14 天'));
      // 常吃药段
      expect(s, contains('━━━ 常吃药方案 ━━━'));
      expect(s, contains('氟西汀'));
      expect(s, contains('40mg'));
      expect(s, contains('14/14 天'));
      expect(s, contains('✓ 无漏服'));
      // 临时用药段
      expect(s, contains('━━━ 临时用药 ━━━'));
      expect(s, contains('右佐匹克隆'));
      expect(s, contains('07/06'));
      expect(s, contains('22:15'));
      expect(s, contains('共 1 次'));
      // 总览段
      expect(s, contains('━━━ 总览 ━━━'));
      expect(s, contains('依从率: 100%'));
      // 免责声明
      expect(s, contains('本应用不提供医疗建议，仅供医生参考'));
    });

    test('漏服时显示具体日期', () {
      // 缺 7/5 和 7/10
      final checkIns = <CheckInEntity>[];
      for (int d = 0; d < 14; d++) {
        final day = DateTime(2026, 6, 30).add(Duration(days: d));
        if (day == DateTime(2026, 7, 5) || day == DateTime(2026, 7, 10)) {
          continue;
        }
        checkIns.add(
          normalCI(
            medicationId: 1,
            at: day.add(const Duration(hours: 8)),
          ),
        );
      }
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: checkIns,
        now: now,
      );
      final s = r.toReportString();
      expect(s, contains('12/14 天'));
      expect(s, contains('⚠️ 漏服'));
      expect(s, contains('07/05'));
      expect(s, contains('07/10'));
    });

    test('整数剂量不显示小数点', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med(dosage: 40, unit: DosageUnit.mg)],
        checkIns: const [],
        now: now,
      );
      final s = r.toReportString();
      expect(s, contains('40mg'));
      expect(s, isNot(contains('40.0mg')));
    });

    test('小数剂量显示小数', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med(dosage: 0.4, unit: DosageUnit.mg)],
        checkIns: const [],
        now: now,
      );
      final s = r.toReportString();
      expect(s, contains('0.4mg'));
    });

    test('用户名为空时显示"未设置"', () {
      final r = MedicationReport.compute(
        userName: '',
        meds: [med()],
        checkIns: const [],
        now: now,
      );
      expect(r.toReportString(), contains('患者: 未设置'));
    });
  });

  // ============================================================
  // B3 fix: 已停药的历史数据保留
  // ============================================================
  group('B3: 已停药历史保留', () {
    test('isActive=false 的药仍计入报告', () {
      // 用户上月停了一个药，但窗口内仍有打卡
      final stoppedMed = MedicationEntity(
        id: 1,
        name: '氟西汀',
        dosage: 40,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 7, 5), // 7/5 停药
        isActive: false, // 但已经在软删除
        refillAt: null,
        refillReminderDays: 7,
      );
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [stoppedMed], // 报告里仍传入
        checkIns: [
          for (int d = 0; d < 10; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
        ],
        now: now,
      );
      // 14 天内这个药仍应出现（即使 isActive=false）
      expect(r.medicationStats, hasLength(1));
      expect(r.medicationStats.first.medication.name, '氟西汀');
      expect(r.actualDoses, 10);
      expect(r.expectedDoses, 14);
    });
  });

  // ============================================================
  // B6 fix: adherencePct == 0 误导 → 返回 null
  // ============================================================
  group('B6: adherencePct 无期望时返回 null', () {
    test('空 meds + 空 checkIns：adherencePct 为 null', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: const [],
        now: now,
      );
      expect(r.adherencePct, isNull);
    });

    test('只有临时用药：adherencePct 仍为 null（无常吃药）', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          tempCI(at: DateTime(2026, 7, 6, 22, 15), note: '右佐匹克隆: 失眠'),
        ],
        now: now,
      );
      expect(r.adherencePct, isNull);
    });

    test('有常吃药且按时：adherencePct = 100', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: [med()],
        checkIns: [
          for (int d = 0; d < 14; d++)
            normalCI(
              medicationId: 1,
              at: DateTime(2026, 6, 30).add(Duration(days: d, hours: 8)),
            ),
        ],
        now: now,
      );
      expect(r.adherencePct, 100);
    });

    test('报告文本：无期望时显示 "—"，不显示 "0%"', () {
      // 用临时用药触发 hasAnyData=true，expectedDoses=0 的分支
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          tempCI(at: DateTime(2026, 7, 6, 22, 15), note: '右佐匹克隆: 失眠'),
        ],
        now: now,
      );
      final s = r.toReportString();
      expect(s, contains('依从率: —'));
      expect(s, isNot(contains('依从率: 0%')));
    });
  });

  // ============================================================
  // B7 fix: 临时用药 note 现在是 JSON 格式
  // ============================================================
  group('B7: 临时用药 JSON 格式', () {
    test('新格式 note 直接被识别', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 6, 22, 15),
            type: CheckInType.temp,
            medicationId: null,
            note: '{"name":"右佐匹克隆","desc":"失眠"}', // 新格式
          ),
        ],
        now: now,
      );
      expect(r.tempMedications.first.name, '右佐匹克隆');
      expect(r.tempMedications.first.description, '失眠');
    });

    test('老格式 "name: desc" 仍兼容', () {
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 6, 22, 15),
            type: CheckInType.temp,
            medicationId: null,
            note: '右佐匹克隆: 失眠', // 老格式
          ),
        ],
        now: now,
      );
      expect(r.tempMedications.first.name, '右佐匹克隆');
      expect(r.tempMedications.first.description, '失眠');
    });

    test('name 中含冒号：新格式正确切分', () {
      // B7 修的边界：name = "洛尔: 200mg"
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 6, 22, 15),
            type: CheckInType.temp,
            medicationId: null,
            note: '{"name":"洛尔","desc":"200mg 头痛"}',
          ),
        ],
        now: now,
      );
      expect(r.tempMedications.first.name, '洛尔');
      expect(r.tempMedications.first.description, '200mg 头痛');
    });

    test('老格式下 name 含冒号会被截断（已知遗留，等老数据迁移完移除）', () {
      // 这是 B7 修复前的行为，documented 保留
      final r = MedicationReport.compute(
        userName: '小明',
        meds: const [],
        checkIns: [
          CheckInEntity(
            id: 1,
            timestamp: DateTime(2026, 7, 6, 22, 15),
            type: CheckInType.temp,
            medicationId: null,
            note: '洛尔: 200mg: 头痛', // 老格式多冒号
          ),
        ],
        now: now,
      );
      // 行为：只取第一个冒号前的
      expect(r.tempMedications.first.name, '洛尔');
      expect(r.tempMedications.first.description, '200mg: 头痛');
    });
  });
}
