// v0.27 round 60 (审计 M8): MedicationEntity.hashCode 契约回归测试
//
// 审计 (audit-domain-layer.md 3.7) 怀疑:
//   `hashCode` 用 `Object.hashAll(times)` — identity-based, 不是
//   element-based → 修正后应改用 element-based.
//
// 验证 (修正前): 通过 Dart 官方文档 (api.dart.dev Object.hashAll):
//   - `Object.hashAll(Iterable)` 迭代 elements, 组合 element.hashCode
//   - 不是 list 的 identity hash
//   - 官方 example: `int get hashCode => Object.hashAll(path);`
//     正是 MedicationEntity 用的 pattern.
//
// 结论: 审计误报. MedicationEntity.hashCode 已 element-based,
// 修正撤回. 但保留 6 个 test case 作契约回归测试, 防止未来
// refactor 误改成 `times.hashCode` (那才是 identity-based, 真正
// 违反契约).

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MedicationEntity baseMed({List<HourMinute>? times}) {
    return MedicationEntity(
      id: 1,
      name: '氟西汀',
      dosage: 40,
      dosageUnit: DosageUnit.mg,
      times: times ?? const [HourMinute(hour: 8, minute: 0)],
      startDate: DateTime(2026, 1, 1),
      endDate: null,
      isActive: true,
      refillAt: null,
      refillReminderDays: 7,
    );
  }

  group('MedicationEntity == / hashCode 契约', () {
    test('相同 times (literal 复用) → == 成立 + hashCode 一致 (baseline)', () {
      // 修正前后都应 pass
      const sharedTimes = [HourMinute(hour: 8, minute: 0)];
      final a = baseMed(times: sharedTimes);
      final b = baseMed(times: sharedTimes);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('相同 times 但不同 List instance → == 成立 + hashCode 一致 (修正)', () {
      // 修正前: == 成立但 hashCode 不同 (因 Object.hashAll identity)
      // 修正后: 两者都一致
      // 关键: 必须用非常量 list 构造 2 个不同 instance, 否则 Dart
      // compiler 把 const 列表 canonicalize 成同一实例, 触发不到 bug.
      final a = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      final b = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      expect(identical(a.times, b.times), isFalse,
          reason: 'sanity: 2 个 list 必须不同 instance 才能测 hashCode');
      expect(a, equals(b), reason: '修正前 == 已成立 (== 用 _listEq element 比较)');
      expect(a.hashCode, b.hashCode,
          reason: '修正后 hashCode 必须 element-based, 跟 == 一致');
    });

    test('times 元素顺序不同 → == 不成立 (sanity check)', () {
      final a = baseMed(times: const [
        HourMinute(hour: 8, minute: 0),
        HourMinute(hour: 20, minute: 0),
      ]);
      final b = baseMed(times: const [
        HourMinute(hour: 20, minute: 0),
        HourMinute(hour: 8, minute: 0),
      ]);
      expect(a, isNot(equals(b)), reason: 'times 顺序不同 = 不同 med');
    });

    test('不同 id → hashCode 不同 (sanity check)', () {
      final a = baseMed();
      final b = MedicationEntity(
        id: 2, // different
        name: '氟西汀',
        dosage: 40,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2026, 1, 1),
        endDate: null,
        isActive: true,
        refillAt: null,
        refillReminderDays: 7,
      );
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('修正核心: Set 查找 — 修正后能 round-trip', () {
      // 修正前 bug: 2 个 == 的 med, Set 查不到对方
      // 修正后: 修正前已能 (用 _listEq 修正 ==), 但 hashCode 不同
      //         → Set/Dict 内部 bucket 错位 → 找不到对方
      final med1 = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      final med2 = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      // 修正前后 == 都成立
      expect(med1, equals(med2));
      // 修正后 Set 查找 round-trip
      final set = <MedicationEntity>{med1};
      expect(set.contains(med2), isTrue,
          reason: '修正后 hashCode 一致 → Set 能找到 == 元素');
    });

    test('修正核心: Map key 查找 — 修正后能 round-trip', () {
      // Map 内部用 hashCode 分 bucket, hashCode 错 → key 找不到
      final med1 = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      final med2 = baseMed(times: [HourMinute(hour: 8, minute: 0)]);
      final map = <MedicationEntity, String>{med1: 'value'};
      expect(map[med2], 'value',
          reason: '修正后 hashCode 一致 → Map 能用 == 元素查 value');
    });
  });
}
