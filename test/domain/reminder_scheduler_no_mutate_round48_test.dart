// v0.24 round 48 (sp-en P1-12): ReminderScheduler 不 mutate caller list 锁定
//
// 现状: selectFirstContact (line 44) + selectAllActiveContacts (line 53) 都做
//   final active = contacts.where((c) => c.isActive).toList();
//   active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
//
// 看起来 where().toList() 已经返回新 list (不 mutate caller),但 v0.16
// round 19 立的"隐式排序假设"反模式: 哪天有人手抖改成 in-place sort
// `contacts.sort(...)` (省 .where() 一行),caller 拿到的 list 会被翻,
// 多次 call 之间状态污染 (第一次 call 的"按 sortOrder 正序"假设被第二次
// call 推翻)。
//
// task 修法: 改 `active.sort(...)` → `final sorted = [...active]..sort(...)`,
// 让"caller 的 list 不被 mutate"在源码层显式表达 (双层防御)。
//
// RED 阶段锁 3 条不变量:
// 1. caller 传的 list (含 unsorted 顺序) → 函数返回后, caller 的 list 顺序不变
// 2. caller 拿到的返回值 caller 拿回去 modify → 下次再 call 不受污染
// 3. 同 list 调 2 次 → 两次返回 list 是独立 list (identity 不等)
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/logic/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

ContactEntity _contact({
  required int id,
  required String name,
  required int sortOrder,
  bool isActive = true,
}) {
  return ContactEntity(
    id: id,
    name: name,
    phone: '138001380$id',
    sortOrder: sortOrder,
    isActive: isActive,
  );
}

void main() {
  group('ReminderScheduler 不 mutate caller list (v0.24 round 48 sp-en P1-12)',
      () {
    test('selectFirstContact 不 mutate caller list (P1-12 RED-1)', () {
      // caller 故意传乱序 list
      final original = <ContactEntity>[
        _contact(id: 1, name: 'Bob', sortOrder: 2),
        _contact(id: 2, name: 'Alice', sortOrder: 0),
        _contact(id: 3, name: 'Carol', sortOrder: 1),
      ];
      // 拍 snapshot
      final snapshotBefore = List<ContactEntity>.from(original);

      ReminderScheduler.selectFirstContact(original);

      // caller 的 list identity + 顺序 + 字段 不应被函数改
      expect(original.length, snapshotBefore.length);
      for (int i = 0; i < original.length; i++) {
        expect(original[i].id, snapshotBefore[i].id,
            reason: 'caller list[$i] id 不应被改');
        expect(original[i].sortOrder, snapshotBefore[i].sortOrder);
      }
    });

    test('selectAllActiveContacts 不 mutate caller list', () {
      final original = <ContactEntity>[
        _contact(id: 1, name: 'Bob', sortOrder: 2),
        _contact(id: 2, name: 'Alice', sortOrder: 0),
        _contact(id: 3, name: 'Carol', sortOrder: 1),
      ];
      final snapshotBefore = List<ContactEntity>.from(original);

      ReminderScheduler.selectAllActiveContacts(original);

      for (int i = 0; i < original.length; i++) {
        expect(original[i].id, snapshotBefore[i].id);
        expect(original[i].sortOrder, snapshotBefore[i].sortOrder);
      }
    });

    test('caller modify 返回 list 不污染后续 call (P1-12 RED-2)', () {
      // v0.16 round 19 立的"多次 call 之间状态污染"防御
      final contacts = <ContactEntity>[
        _contact(id: 1, name: 'Bob', sortOrder: 2),
        _contact(id: 2, name: 'Alice', sortOrder: 0),
        _contact(id: 3, name: 'Carol', sortOrder: 1),
      ];

      // 第一次 call
      final result1 = ReminderScheduler.selectAllActiveContacts(contacts);
      // 期望正序: Alice(0), Carol(1), Bob(2)
      expect(result1[0].name, 'Alice');
      expect(result1[1].name, 'Carol');
      expect(result1[2].name, 'Bob');

      // caller 拿 result1 倒序 (污染)
      result1.sort((a, b) => b.sortOrder.compareTo(a.sortOrder));
      expect(result1[0].name, 'Bob'); // 已污染

      // 第二次 call — 不应受第一次污染影响, 仍返回正序
      final result2 = ReminderScheduler.selectAllActiveContacts(contacts);
      expect(result2[0].name, 'Alice');
      expect(result2[1].name, 'Carol');
      expect(result2[2].name, 'Bob');
    });

    test('同 input 调 2 次 → 返回 list identity 不等 (P1-12 RED-3)', () {
      // 验证每次 call 都返回新 list, 不复用内部缓存
      final contacts = <ContactEntity>[
        _contact(id: 1, name: 'Bob', sortOrder: 2),
        _contact(id: 2, name: 'Alice', sortOrder: 0),
        _contact(id: 3, name: 'Carol', sortOrder: 1),
      ];

      final result1 = ReminderScheduler.selectAllActiveContacts(contacts);
      final result2 = ReminderScheduler.selectAllActiveContacts(contacts);

      // identity 不等
      expect(identical(result1, result2), isFalse,
          reason: '每次 call 应返回独立 list, 不复用');
      // 但内容相等 (都是正序)
      expect(result1.length, result2.length);
      for (int i = 0; i < result1.length; i++) {
        expect(result1[i].id, result2[i].id);
      }
    });

    test('selectFirstContact 返回值 modify 不影响下次 call', () {
      final contacts = <ContactEntity>[
        _contact(id: 1, name: 'Bob', sortOrder: 2),
        _contact(id: 2, name: 'Alice', sortOrder: 0),
        _contact(id: 3, name: 'Carol', sortOrder: 1),
      ];

      // selectFirstContact 返回 nullable; 单个 entity caller 拿不到 list
      // 所以测的是 caller contacts 不被 mutate
      final r1 = ReminderScheduler.selectFirstContact(contacts);
      expect(r1, isNotNull);
      expect(r1!.name, 'Alice');

      // 第二次 call
      final r2 = ReminderScheduler.selectFirstContact(contacts);
      expect(r2, isNotNull);
      expect(r2!.name, 'Alice');
      expect(r2.id, r1.id, reason: '两次返回同一 contact');
    });
  });
}
