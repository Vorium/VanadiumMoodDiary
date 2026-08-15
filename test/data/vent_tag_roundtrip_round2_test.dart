// 1.1.0 round 2b — vent_entries.tagsJson drift round-trip 测试
//
// 验证 tagsJson 字段在 drift DB (in-memory) 中能完整 insert → 读出 → toEntity
// 流转,无字段丢失;老数据(未显式传 tagsJson)默认 '[]'。
//
// 注意: VentDao 无 getById,按现有 vent repository impl 的取单条方式:
// watchAll().first + firstWhere(id) 改写 (见 brief caveat)。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'dart:typed_data';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // vent text 加密走 flutter_secure_storage platform channel,测试环境不可用,
    // setKeyForTest 注入固定 32 字节 key 绕过 (EncryptionService 是单例,
    // mapper 内 _ventTextEncryption 拿同一实例)。
    EncryptionService().setKeyForTest(
      Uint8List.fromList(List.generate(32, (i) => i)),
    );
  });
  tearDown(() async => db.close());

  Future<VentEntry> rowById(int id) async =>
      (await db.ventDao.watchAll().first).firstWhere((r) => r.id == id);

  test('vent tagsJson round-trip: insert 带标签 → 读出还原', () async {
    final id = await db.ventDao.insert(
      await VentEntryEntity(
        id: 0,
        timestamp: DateTime(2026, 8, 15, 12),
        contentText: '今天好累',
        tagsJson: '["家庭","工作"]',
      ).toCompanion(),
    );
    final row = await rowById(id);
    final entity = await row.toEntity();
    expect(entity.tagsJson, '["家庭","工作"]');
  });

  test('老数据默认 tagsJson = []', () async {
    final id = await db.ventDao.insert(
      await VentEntryEntity(
        id: 0,
        timestamp: DateTime(2026, 8, 15, 12),
        contentText: '无标签',
      ).toCompanion(),
    );
    final row = await rowById(id);
    final entity = await row.toEntity();
    expect(entity.tagsJson, '[]');
  });

  test('copyWith 保留/更新 tagsJson', () {
    final base = VentEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 15, 12),
      contentText: 'a',
      tagsJson: '["家庭"]',
    );
    final updated = base.copyWith(tagsJson: '["工作"]');
    expect(updated.tagsJson, '["工作"]');
    expect(base.copyWith().tagsJson, '["家庭"]');
  });
}
