// v0.30 R108 (P1 medication_page 拆): MedicationTimeSlot 抽 domain 防回归测试
//
// R107 报告 P1-3: medication_page 540L god class 拆分, 抽 _TimeSlot enum +
// contains() 算法到 `domain/logic/medication_slot_calculator.dart`, 让 domain
// 测试可 0 Flutter 0 Drift 直接覆盖 (跟 StreakCalculator / SleepCalculator
// 等逻辑 calculator 模式一致)。
//
// 测试覆盖:
// 1. 4 时段定义 (morning/afternoon/evening/bedtime)
// 2. fromHour 判定 (各时段 representative 小时 + 跨日 bedtime)
// 3. contains 边界 (含 startHour / endHour, 跨日, 非时段小时)
// 4. == / hashCode 一致性 (Dart const 数据正确)
// 5. 静态分析: medication_page.dart 不再含 _TimeSlot enum
// 6. 静态分析: presentation 层只 import MedicationTimeSlot, 不 import 旧
//    _TimeSlot (已删)

import 'dart:io';

import 'package:chroniccare/domain/logic/medication_slot_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicationTimeSlot 4 时段定义 (R108 P1 medication_page 拆)', () {
    test('case 1: 4 个时段常量 (morning/afternoon/evening/bedtime)', () {
      expect(MedicationTimeSlot.morning.name, 'morning');
      expect(MedicationTimeSlot.morning.startHour, 5);
      expect(MedicationTimeSlot.morning.endHour, 11);

      expect(MedicationTimeSlot.afternoon.name, 'afternoon');
      expect(MedicationTimeSlot.afternoon.startHour, 12);
      expect(MedicationTimeSlot.afternoon.endHour, 16);

      expect(MedicationTimeSlot.evening.name, 'evening');
      expect(MedicationTimeSlot.evening.startHour, 17);
      expect(MedicationTimeSlot.evening.endHour, 20);

      expect(MedicationTimeSlot.bedtime.name, 'bedtime');
      // bedtime 跨日: startHour (21) > endHour (4)
      expect(MedicationTimeSlot.bedtime.startHour, 21);
      expect(MedicationTimeSlot.bedtime.endHour, 4);
    });

    test('case 2: MedicationTimeSlot.all 列表按时间顺序 (morning→bedtime)', () {
      expect(MedicationTimeSlot.all.length, 4);
      expect(MedicationTimeSlot.all[0], MedicationTimeSlot.morning);
      expect(MedicationTimeSlot.all[1], MedicationTimeSlot.afternoon);
      expect(MedicationTimeSlot.all[2], MedicationTimeSlot.evening);
      expect(MedicationTimeSlot.all[3], MedicationTimeSlot.bedtime);
    });
  });

  group('MedicationTimeSlot.fromHour 判定 (各时段 representative)', () {
    test('case 3: fromHour(8) = morning (早晨 5-11)', () {
      expect(MedicationTimeSlot.fromHour(8), MedicationTimeSlot.morning);
    });

    test('case 4: fromHour(14) = afternoon (下午 12-16)', () {
      expect(MedicationTimeSlot.fromHour(14), MedicationTimeSlot.afternoon);
    });

    test('case 5: fromHour(20) = evening (傍晚 17-20)', () {
      // 20 在 evening 17-20 闭区间内, 是 evening
      expect(MedicationTimeSlot.fromHour(20), MedicationTimeSlot.evening);
    });

    test('case 6: fromHour(2) = bedtime (跨日 21-4)', () {
      // 2 在 bedtime 21-4 跨日: hour >= 21 || hour <= 4 → 2 <= 4 → true
      expect(MedicationTimeSlot.fromHour(2), MedicationTimeSlot.bedtime);
    });

    test('case 7: fromHour(22) = bedtime (晚间 22 在 21-4 范围内)', () {
      // 22 在 bedtime 21-4: 22 >= 21 → true
      expect(MedicationTimeSlot.fromHour(22), MedicationTimeSlot.bedtime);
    });

    test('case 8: fromHour(0) = bedtime (凌晨 0 在 21-4 范围内)', () {
      // 0 在 bedtime 21-4: 0 <= 4 → true
      expect(MedicationTimeSlot.fromHour(0), MedicationTimeSlot.bedtime);
    });
  });

  group('MedicationTimeSlot.contains 跨日判定', () {
    test('case 9: morning.contains(5) = true (下界 inclusive)', () {
      expect(MedicationTimeSlot.morning.contains(5), isTrue);
    });

    test('case 10: morning.contains(11) = true (上界 inclusive)', () {
      expect(MedicationTimeSlot.morning.contains(11), isTrue);
    });

    test('case 11: morning.contains(4) = false (不属 morning)', () {
      expect(MedicationTimeSlot.morning.contains(4), isFalse);
    });

    test('case 12: morning.contains(12) = false (不属 morning)', () {
      expect(MedicationTimeSlot.morning.contains(12), isFalse);
    });

    test('case 13: bedtime.contains(21) = true (下界 inclusive)', () {
      // 21 == startHour 21
      expect(MedicationTimeSlot.bedtime.contains(21), isTrue);
    });

    test('case 14: bedtime.contains(4) = true (上界 inclusive, 跨日)', () {
      // 4 == endHour 4, 跨日下 hour <= 4 → true
      expect(MedicationTimeSlot.bedtime.contains(4), isTrue);
    });

    test('case 15: bedtime.contains(5) = false (跨日后 5 不属 bedtime)', () {
      // 5 不在 [21, 4] 范围内 (5 < 21 跨日后 5 也不 <= 4)
      expect(MedicationTimeSlot.bedtime.contains(5), isFalse);
    });

    test('case 16: bedtime.contains(20) = false (20 不属 bedtime)', () {
      // 20 < 21 且 20 > 4, 不在 bedtime 范围内
      expect(MedicationTimeSlot.bedtime.contains(20), isFalse);
    });

    test('case 17: bedtime.contains(23) = true (23 在 21-4 跨日范围)', () {
      // 23 >= 21 → true
      expect(MedicationTimeSlot.bedtime.contains(23), isTrue);
    });
  });

  group('MedicationTimeSlot == / hashCode (Dart const 数据正确)', () {
    test('case 18: 相同时段 == 为 true (同 const 实例)', () {
      expect(MedicationTimeSlot.morning == MedicationTimeSlot.morning, isTrue);
      expect(
        MedicationTimeSlot.morning.hashCode,
        MedicationTimeSlot.morning.hashCode,
      );
    });

    test('case 19: 不同时段 == 为 false', () {
      expect(
          MedicationTimeSlot.morning == MedicationTimeSlot.afternoon, isFalse);
    });

    test('case 20: const 构造同 name+hour == 为 true', () {
      const a = MedicationTimeSlot.morning;
      const b = MedicationTimeSlot.morning;
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('case 21: toString 包含 name + hour 范围', () {
      final s = MedicationTimeSlot.bedtime.toString();
      expect(s, contains('bedtime'));
      expect(s, contains('21'));
      expect(s, contains('4'));
    });
  });

  group('静态分析: medication_page.dart 已抽 _TimeSlot 到 domain', () {
    late String medicationPageContent;

    setUpAll(() async {
      // 静态分析 medication_page.dart, 验证 _TimeSlot enum 已删, 改用
      // MedicationTimeSlot (R108 P1 medication_page 拆 防回退)。
      final file =
          File('lib/presentation/pages/medication/medication_page.dart');
      medicationPageContent = await file.readAsString();
    });

    test('case 22: medication_page.dart 不再含 _TimeSlot enum 定义', () {
      // 防回退: 不应再定义 _TimeSlot enum (presentation-private)
      expect(
        RegExp(r'enum\s+_TimeSlot').hasMatch(medicationPageContent),
        isFalse,
        reason: 'R108 修后 _TimeSlot enum 应已删, 改用 MedicationTimeSlot',
      );
    });

    test('case 23: medication_page.dart 不再含 _TimeSlot.values', () {
      expect(
        medicationPageContent.contains('_TimeSlot.values'),
        isFalse,
        reason: 'R108 修后不应再用 _TimeSlot.values, 改用 MedicationTimeSlot.all',
      );
    });

    test('case 24: medication_page.dart 不再含 _TimeSlot.morning 等成员', () {
      // 防御性: 即使 enum 删了, 也不应残留 _TimeSlot.morning 引用
      expect(
        RegExp(r'_TimeSlot\.(morning|afternoon|evening|bedtime)')
            .hasMatch(medicationPageContent),
        isFalse,
        reason: 'R108 修后不应再有 _TimeSlot.xxx 成员访问',
      );
    });

    test('case 25: medication_page.dart 改用 MedicationTimeSlot.all', () {
      // 验证新 API 落地
      expect(
        medicationPageContent.contains('MedicationTimeSlot.all'),
        isTrue,
        reason: 'R108 修后 _buildTimeSlots 应改用 MedicationTimeSlot.all',
      );
    });

    test('case 26: medication_page.dart import MedicationTimeSlot', () {
      expect(
        RegExp(
          r"import\s+'package:chroniccare/domain/logic/medication_slot_calculator\.dart'",
        ).hasMatch(medicationPageContent),
        isTrue,
        reason: 'R108 修后应 import domain/logic/medication_slot_calculator.dart',
      );
    });
  });
}
