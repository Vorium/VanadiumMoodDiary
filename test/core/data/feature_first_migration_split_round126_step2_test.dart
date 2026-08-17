// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep 子表
// 端到端迁移验证 (R125 样板扩展, daily_tracking 第 3 子表)
//
// Goal: 验证 R126 阶段 2 step 2 (daily_tracking 第 3 子表 sleep)
// 端到端 5 file 迁移跟 R125 样板同模式, 旧路径 re-export 兼容, 0 回归。

import 'dart:io';

import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/sleep_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/sleep_entries.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/sleep_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/sleep_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const newTablePath =
      'lib/features/daily_tracking/data/tables/sleep_entries.dart';
  const newMapperPath =
      'lib/features/daily_tracking/data/mappers/sleep_mapper.dart';
  const newRepoImplPath =
      'lib/features/daily_tracking/data/repositories/sleep_repository_impl.dart';
  const newEntityPath =
      'lib/features/daily_tracking/domain/entities/sleep_entry.dart';
  const newRepoPath =
      'lib/features/daily_tracking/domain/repositories/sleep_repository.dart';
  const oldEntityPath = 'lib/domain/entities/sleep_entry.dart';
  const oldRepoPath = 'lib/domain/repositories/sleep_repository.dart';

  group('R126 阶段 2 step 2 — sleep 5 file 端到端 (R125 样板扩展)', () {
    test('drift table 迁到 features/daily_tracking/data/tables/', () {
      expect(File(newTablePath).existsSync(), isTrue);
      final content = File(newTablePath).readAsStringSync();
      expect(content.contains('class SleepEntries extends Table'), isTrue);
      // 6 字段 (vs anxiety 4 字段 / stress 5 字段)
      expect(content.contains('regularityScore'), isTrue,
          reason: '含 regularityScore 1-5 评分字段 (nullable)');
      expect(content.contains('durationMin'), isTrue,
          reason: '含 durationMin 自动算字段');
    });

    test('mapper (R125 样板扩展) 在 features/daily_tracking/data/mappers/', () {
      expect(File(newMapperPath).existsSync(), isTrue);
      final content = File(newMapperPath).readAsStringSync();
      expect(content.contains('sleepRowToEntity'), isTrue);
    });

    test('repository_impl 迁到 features/daily_tracking/data/repositories/', () {
      expect(File(newRepoImplPath).existsSync(), isTrue);
    });

    test('entity (domain) 迁到 features/daily_tracking/domain/entities/', () {
      expect(File(newEntityPath).existsSync(), isTrue);
      final content = File(newEntityPath).readAsStringSync();
      expect(content.contains('class SleepEntryEntity'), isTrue);
      // 业务方法 (跟旧 entity 字段一致, 避免 widget 端 break)
      expect(content.contains('durationLabel'), isTrue,
          reason: 'durationLabel 业务方法 (旧 widget 端依赖)');
      expect(content.contains('hasRegularityScore'), isTrue,
          reason: 'hasRegularityScore 业务方法 (旧 widget 端依赖)');
    });

    test('repository abstract 迁到 features/daily_tracking/domain/repositories/', () {
      expect(File(newRepoPath).existsSync(), isTrue);
      final content = File(newRepoPath).readAsStringSync();
      expect(content.contains('abstract class SleepRepository'), isTrue);
    });
  });

  group('R126 阶段 2 step 2 — 旧路径 re-export 兼容 (现有用户 0 改动)', () {
    test('旧 entity 路径 lib/domain/entities/sleep_entry.dart 是 re-export', () {
      final content = File(oldEntityPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/entities/sleep_entry.dart'"),
        isTrue,
      );
    });

    test('旧 abstract 路径 lib/domain/repositories/sleep_repository.dart 是 re-export', () {
      final content = File(oldRepoPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/repositories/sleep_repository.dart'"),
        isTrue,
      );
    });
  });

  group('R126 阶段 2 step 2 — 新旧路径 import 等价 (编译验证)', () {
    test('新旧 entity 路径 import 同一 class + 业务方法 work', () {
      // 旧路径 import 编译通过 (跟新路径同一 class, re-export 机制)
      // 同时验证业务方法 durationLabel / hasRegularityScore 0 break (旧 widget 端依赖)
      final entity = SleepEntryEntity(
        id: 1,
        date: DateTime(2026, 8, 17),
        bedtime: DateTime(2026, 8, 16, 23, 30),
        wakeTime: DateTime(2026, 8, 17, 7, 0),
        durationMin: 450, // 7h30min
        regularityScore: 4,
        note: 'sleep well',
      );
      expect(entity.id, 1);
      expect(entity.durationMin, 450);
      expect(entity.durationLabel, '7h30min',
          reason: '业务方法 durationLabel 跟旧 entity 一致 (450min = 7h30min)');
      expect(entity.hasRegularityScore, isTrue,
          reason: '业务方法 hasRegularityScore 跟旧 entity 一致 (1-5 范围)');
      expect(SleepEntryEntity(
        id: 2,
        date: DateTime(2026, 8, 18),
        bedtime: DateTime(2026, 8, 17, 23, 0),
        wakeTime: DateTime(2026, 8, 18, 6, 0),
        durationMin: 420,
        regularityScore: null,
      ).hasRegularityScore, isFalse,
          reason: 'regularityScore = null 时 hasRegularityScore = false');
    });
  });

  group('R126 阶段 2 step 2 + step 3 — daily_tracking 6/6 子表收官 100%', () {
    test('6/6 子表全已迁 (anxiety + stress + sleep + weight + social_rhythm + treatment)', () {
      // R125 + R126 step 1+2+3 累计 daily_tracking 6/6 子表全迁
      final migrated = [
        'anxiety_agitation_entries.dart',
        'stress_events.dart',
        'sleep_entries.dart',
        'weight_entries.dart',
        'social_rhythm_entries.dart',
        'treatment_entries.dart',
      ];
      for (final f in migrated) {
        expect(
          File('lib/features/daily_tracking/data/tables/$f').existsSync(),
          isTrue,
          reason: '$f 已迁 (R125 + R126 step 1+2+3 收官)',
        );
      }
    });
  });
}
