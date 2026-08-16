// v1.1.0 round 9 (F1 烦恼闭环) — WorryThreadLibrary title 生成规则测试
//
// 纯 Dart domain 测试 (0 flutter 0 drift):
// - 前 20 字截断 + 省略号
// - 空白折叠 + 去首尾
// - 空 note → null (让 UI 兜底)
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/logic/worry_thread_library.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';

void main() {
  group('WorryThreadLibrary.generateTitle', () {
    test('短 note → 原样返回 (trim)', () {
      expect(WorryThreadLibrary.generateTitle('今天好累'), '今天好累');
      expect(WorryThreadLibrary.generateTitle('  今天好累  '), '今天好累');
    });

    test('20 字内不截断, 21 字截断到 20 + 省略号', () {
      const exactly20 = '一二三四五六七八九十一二三四五六七八九十';
      expect(exactly20.length, 20);
      expect(WorryThreadLibrary.generateTitle(exactly20), exactly20);

      const over21 = '一二三四五六七八九十一二三四五六七八九十一二';
      expect(over21.length, greaterThan(20));
      final t = WorryThreadLibrary.generateTitle(over21)!;
      expect(t.length, 21, reason: '20 字 + 省略号');
      expect(t, '一二三四五六七八九十一二三四五六七八九十…');
    });

    test('多行/多空格折叠成单空格', () {
      expect(
        WorryThreadLibrary.generateTitle('今天  心情\n 很糟'),
        '今天 心情 很糟',
      );
    });

    test('null / 空 / 全空白 → null (UI 兜底)', () {
      expect(WorryThreadLibrary.generateTitle(null), isNull);
      expect(WorryThreadLibrary.generateTitle(''), isNull);
      expect(WorryThreadLibrary.generateTitle('   \n  '), isNull);
    });
  });

  group('WorryStatus wire 映射', () {
    test('open/resolved 双向 wire 还原', () {
      expect(WorryStatus.open.wire, 'open');
      expect(WorryStatus.resolved.wire, 'resolved');
      expect(WorryStatus.fromWire('open'), WorryStatus.open);
      expect(WorryStatus.fromWire('resolved'), WorryStatus.resolved);
    });

    test('未知 wire → fallback open (兼容老数据)', () {
      expect(WorryStatus.fromWire(null), WorryStatus.open);
      expect(WorryStatus.fromWire('archived'), WorryStatus.open);
    });
  });

  group('WorryThreadEntity 状态语义', () {
    test('isResolved 跟随 status', () {
      final open = WorryThreadEntity(
        id: 1,
        title: '测试',
        createdAt: _t0,
        status: WorryStatus.open,
      );
      expect(open.isResolved, isFalse);

      final resolved = open.copyWith(
        status: WorryStatus.resolved,
        resolvedAt: DateTime(2026, 8, 16),
      );
      expect(resolved.isResolved, isTrue);
      expect(resolved.resolvedAt, DateTime(2026, 8, 16));
    });

    test('copyWith 保留未改字段', () {
      final base = WorryThreadEntity(
        id: 1,
        title: '标题',
        createdAt: _t0,
        status: WorryStatus.open,
      );
      final renamed = base.copyWith(title: '新标题');
      expect(renamed.id, 1);
      expect(renamed.title, '新标题');
      expect(renamed.createdAt, _t0);
      expect(renamed.status, WorryStatus.open);
    });
  });
}

final _t0 = DateTime(2026, 8, 15);
