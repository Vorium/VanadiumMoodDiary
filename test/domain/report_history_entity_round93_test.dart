// v0.28 Round 93 (#73 修复): report_history_entity 0 测试补齐
//
// 覆盖:
// - 5 字段构造
// - copyWith: nullable userName 用 DomainValue 区分 "保持" / "清空"
// - == / hashCode / toString
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/report_history_entity.dart';

void main() {
  final generatedAt = DateTime(2026, 8, 3, 12, 0);

  group('ReportHistoryEntity 构造', () {
    test('全字段', () {
      final e = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: '小李',
        reportText: '...',
      );
      expect(e.id, 1);
      expect(e.windowDays, 30);
      expect(e.userName, '小李');
      expect(e.reportText, '...');
    });

    test('userName nullable (v0.21 R23 改)', () {
      final e = ReportHistoryEntity(
        id: 2,
        windowDays: 7,
        generatedAt: generatedAt,
        userName: null,
        reportText: '...',
      );
      expect(e.userName, isNull);
    });
  });

  group('ReportHistoryEntity.copyWith', () {
    test('改 windowDays', () {
      final e = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      final e2 = e.copyWith(windowDays: 7);
      expect(e2.windowDays, 7);
      expect(e2.userName, 'A');
    });

    test('userName DomainValue(null) 显式清空', () {
      final e = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      final e2 = e.copyWith(userName: const DomainValue(null));
      expect(e2.userName, isNull);
    });

    test('userName 传 null = 保持原值', () {
      final e = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      final e2 = e.copyWith();
      expect(e2.userName, 'A');
    });
  });

  group('ReportHistoryEntity == / hashCode / toString', () {
    test('字段全等 → ==', () {
      final e1 = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      final e2 = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      expect(e1, e2);
      expect(e1.hashCode, e2.hashCode);
    });

    test('id 不同 → !=', () {
      final e1 = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      final e2 = ReportHistoryEntity(
        id: 2,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: 'A',
        reportText: 'X',
      );
      expect(e1, isNot(e2));
    });

    test('toString 不暴露 reportText (PII 安全)', () {
      final e = ReportHistoryEntity(
        id: 1,
        windowDays: 30,
        generatedAt: generatedAt,
        userName: '小李',
        reportText: '包含患者 PII 的长报告...',
      );
      final s = e.toString();
      expect(s, contains('1'));
      expect(s, contains('30'));
      expect(s, isNot(contains('包含患者 PII'))); // 不含 PII
    });
  });
}
