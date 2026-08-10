// v0.29 Round 95 (#66 修复): temp_entry_extractor 0 测试补齐
//
// 覆盖:
// - extract 空 list / 非 temp 全部过滤 / temp 顺序 / temp 描述空退化为 "—"
// - 解析 note JSON {name, desc} (v0.25 round 58 JSON key 用 desc 不是 description) 老格式 "name:desc" 容错
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/temp_entry_extractor.dart';

CheckInEntity _ci({
  int id = 1,
  required DateTime timestamp,
  CheckInType type = CheckInType.temp,
  String? note,
}) {
  return CheckInEntity(
    id: id,
    timestamp: timestamp,
    type: type,
    note: note,
  );
}

void main() {
  group('TempEntryExtractor.extract 空 / 边界', () {
    test('空 list 返回空', () {
      expect(TempEntryExtractor.extract([]), isEmpty);
    });

    test('全是 normal checkIn 过滤后空', () {
      final list = [
        _ci(timestamp: DateTime(2026, 7, 15, 8), type: CheckInType.normal),
        _ci(
            id: 2,
            timestamp: DateTime(2026, 7, 15, 9),
            type: CheckInType.normal,),
      ];
      expect(TempEntryExtractor.extract(list), isEmpty);
    });
  });

  group('TempEntryExtractor.extract temp 顺序', () {
    test('单 temp 新格式 JSON {name, desc}', () {
      final list = [
        _ci(
          timestamp: DateTime(2026, 7, 15, 14),
          note: '{"name":"布洛芬","desc":"头痛"}',
        ),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.length, 1);
      expect(result.first.name, '布洛芬');
      expect(result.first.description, '头痛');
    });

    test('多 temp 按时间倒序', () {
      final list = [
        _ci(
          id: 1,
          timestamp: DateTime(2026, 7, 15, 8),
          note: '{"name":"A","desc":"a"}',
        ),
        _ci(
          id: 2,
          timestamp: DateTime(2026, 7, 15, 20),
          note: '{"name":"B","desc":"b"}',
        ),
        _ci(
          id: 3,
          timestamp: DateTime(2026, 7, 15, 14),
          note: '{"name":"C","desc":"c"}',
        ),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.length, 3);
      // 倒序: 20 -> 14 -> 8
      expect(result[0].name, 'B');
      expect(result[1].name, 'C');
      expect(result[2].name, 'A');
    });

    test('老格式 "name:desc" 也解析', () {
      final list = [
        _ci(
          timestamp: DateTime(2026, 7, 15, 14),
          note: '布洛芬:头痛',
        ),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.length, 1);
      expect(result.first.name, '布洛芬');
      expect(result.first.description, '头痛');
    });
  });

  group('TempEntryExtractor.extract description 退化', () {
    test('空 desc 退化为占位符', () {
      final list = [
        _ci(
          timestamp: DateTime(2026, 7, 15, 14),
          note: '{"name":"布洛芬","desc":""}',
        ),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.first.description, '—');
    });

    test('note null 全部空 desc 退化为占位符', () {
      final list = [
        _ci(timestamp: DateTime(2026, 7, 15, 14), note: null),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.first.name, '');
      expect(result.first.description, '—');
    });
  });

  group('TempEntryExtractor.extract 混合 normal + temp', () {
    test('normal 全部过滤 temp 按时间倒序保留', () {
      final list = [
        _ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 8),
            type: CheckInType.normal,),
        _ci(
          id: 2,
          timestamp: DateTime(2026, 7, 15, 10),
          type: CheckInType.temp,
          note: '{"name":"X","desc":"x"}',
        ),
        _ci(
            id: 3,
            timestamp: DateTime(2026, 7, 15, 12),
            type: CheckInType.normal,),
        _ci(
          id: 4,
          timestamp: DateTime(2026, 7, 15, 18),
          type: CheckInType.temp,
          note: '{"name":"Y","desc":"y"}',
        ),
      ];
      final result = TempEntryExtractor.extract(list);
      expect(result.length, 2);
      expect(result[0].name, 'Y');
      expect(result[1].name, 'X');
    });
  });
}
