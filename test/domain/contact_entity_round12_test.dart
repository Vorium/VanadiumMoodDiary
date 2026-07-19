// v0.14 (Round 12A) ContactEntity / mapper 单元测试
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/contact/contact_mapper.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Contact _driftRow({
  int id = 1,
  String name = '妈妈',
  String phone = '13800138000',
  int sortOrder = 0,
  bool isActive = true,
}) {
  return Contact(
    id: id,
    name: name,
    phone: phone,
    sortOrder: sortOrder,
    isActive: isActive,
  );
}

void main() {
  group('ContactToEntity (Drift → Entity)', () {
    test('基础字段正确映射', () {
      final row =
          _driftRow(id: 7, name: '爸爸', phone: '13900139000', sortOrder: 1);
      final entity = row.toEntity();
      expect(entity.id, 7);
      expect(entity.name, '爸爸');
      expect(entity.phone, '13900139000');
      expect(entity.sortOrder, 1);
    });

    test('isActive=true 是默认（与 schema 一致）', () {
      expect(_driftRow().toEntity().isActive, isTrue);
      expect(_driftRow(isActive: false).toEntity().isActive, isFalse);
    });
  });

  group('ContactEntityToDrift (Entity → row / Companion)', () {
    test('toDriftRow 完整 row', () {
      final e = const ContactEntity(
        id: 5,
        name: '姐姐',
        phone: '13700137000',
        sortOrder: 2,
        isActive: false,
      );
      final row = e.toDriftRow();
      expect(row.id, 5);
      expect(row.name, '姐姐');
      expect(row.phone, '13700137000');
      expect(row.sortOrder, 2);
      expect(row.isActive, false);
    });

    test('toCompanion 默认 sortOrder=0 isActive=true', () {
      final e = const ContactEntity(id: 0, name: 'X', phone: '13800138000');
      final c = e.toCompanion();
      expect(c.sortOrder.value, 0);
      expect(c.isActive.value, true);
    });
  });

  group('Round trip (Drift → Entity → Drift)', () {
    test('完整数据无丢失', () {
      final original =
          _driftRow(id: 12, name: '医生', phone: '13600136000', sortOrder: 3);
      final roundTripped = original.toEntity().toDriftRow();
      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.phone, original.phone);
      expect(roundTripped.sortOrder, original.sortOrder);
      expect(roundTripped.isActive, original.isActive);
    });
  });

  group('业务方法', () {
    test('active == isActive', () {
      expect(
        const ContactEntity(
          id: 1,
          name: 'A',
          phone: '13800138000',
          isActive: true,
        ).active,
        isTrue,
      );
      expect(
        const ContactEntity(
          id: 1,
          name: 'A',
          phone: '13800138000',
          isActive: false,
        ).active,
        isFalse,
      );
    });

    test('isValidPhone 11 位数字通过', () {
      final c = const ContactEntity(id: 1, name: 'X', phone: '13800138000');
      expect(c.isValidPhone, isTrue);
    });

    test('isValidPhone +86 前缀通过', () {
      final c = const ContactEntity(id: 1, name: 'X', phone: '+8613800138000');
      expect(c.isValidPhone, isTrue);
    });

    test('isValidPhone 非数字 / 长度错', () {
      expect(
        const ContactEntity(id: 1, name: 'X', phone: '123').isValidPhone,
        isFalse,
      );
      expect(
        const ContactEntity(id: 1, name: 'X', phone: '1380013800a')
            .isValidPhone,
        isFalse,
      );
      expect(
        const ContactEntity(id: 1, name: 'X', phone: '138001380000')
            .isValidPhone,
        isFalse,
      );
    });

    test('bySortOrder 静态比较器', () {
      final a = const ContactEntity(
        id: 1,
        name: 'A',
        phone: '13800138000',
        sortOrder: 2,
      );
      final b = const ContactEntity(
        id: 2,
        name: 'B',
        phone: '13800138001',
        sortOrder: 1,
      );
      final c = const ContactEntity(
        id: 3,
        name: 'C',
        phone: '13800138002',
        sortOrder: 3,
      );
      final list = [a, b, c]..sort(ContactEntity.bySortOrder);
      expect(list[0].id, 2);
      expect(list[1].id, 1);
      expect(list[2].id, 3);
    });

    test('copyWith 基础字段', () {
      final original =
          const ContactEntity(id: 1, name: 'A', phone: '13800138000');
      final copy = original.copyWith(name: 'B');
      expect(copy.name, 'B');
      expect(copy.id, original.id);
    });

    test('copyWith isActive', () {
      final original = const ContactEntity(
        id: 1,
        name: 'A',
        phone: '13800138000',
        isActive: true,
      );
      final copy = original.copyWith(isActive: false);
      expect(copy.isActive, isFalse);
    });
  });

  group('等值', () {
    test('== hashCode 字段全等才相等', () {
      final a = const ContactEntity(
        id: 1,
        name: 'A',
        phone: '13800138000',
        sortOrder: 0,
      );
      final b = const ContactEntity(
        id: 1,
        name: 'A',
        phone: '13800138000',
        sortOrder: 0,
      );
      final c = const ContactEntity(
        id: 1,
        name: 'B',
        phone: '13800138000',
        sortOrder: 0,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('集成：从 DB 读 Contact → toEntity → UI 流程', () {
    test('内存 DB 写一条 → 读 → 转 entity → 字段一致', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => await db.close());

      await db.insertContact(
        ContactsCompanion.insert(
          name: '妈妈',
          phone: '13800138000',
          sortOrder: const Value(0),
        ),
      );

      final rows = await db.watchContacts().first;
      expect(rows.length, 1);

      final entity = rows.first.toEntity();
      expect(entity.name, '妈妈');
      expect(entity.phone, '13800138000');
      expect(entity.sortOrder, 0);
      expect(entity.isActive, isTrue);
    });
  });
}
