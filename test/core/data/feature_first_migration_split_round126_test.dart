// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event 子表
// 端到端迁移验证 (跟 R125 anxiety_agitation 样板同模式)
//
// Goal: 验证 R126 阶段 2 step 1 (daily_tracking 第 2 子表 stress_event)
// 端到端 5 file 迁移跟 R125 样板同模式, 旧路径 re-export 兼容, 0 回归。

import 'dart:io';

import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/repositories/stress_event_repository.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/stress_event_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/stress_events.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/stress_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const newTablePath =
      'lib/features/daily_tracking/data/tables/stress_events.dart';
  const newMapperPath =
      'lib/features/daily_tracking/data/mappers/stress_event_mapper.dart';
  const newRepoImplPath =
      'lib/features/daily_tracking/data/repositories/stress_event_repository_impl.dart';
  const newEntityPath =
      'lib/features/daily_tracking/domain/entities/stress_event.dart';
  const newRepoPath =
      'lib/features/daily_tracking/domain/repositories/stress_event_repository.dart';
  const oldEntityPath = 'lib/domain/entities/stress_event.dart';
  const oldRepoPath = 'lib/domain/repositories/stress_event_repository.dart';

  group('R126 阶段 2 step 1 — stress_event 5 file 端到端 (R125 样板扩展)', () {
    test('drift table 迁到 features/daily_tracking/data/tables/', () {
      expect(File(newTablePath).existsSync(), isTrue,
          reason: 'drift table 5 字段 (含 linkedMoodEntryId 弱 FK)');
      final content = File(newTablePath).readAsStringSync();
      expect(content.contains('class StressEvents extends Table'), isTrue,
          reason: 'drift table class 完整');
      expect(content.contains('linkedMoodEntryId'), isTrue,
          reason: '含 linkedMoodEntryId 弱 FK 字段');
    });

    test('mapper (R125 样板扩展) 在 features/daily_tracking/data/mappers/', () {
      expect(File(newMapperPath).existsSync(), isTrue);
      final content = File(newMapperPath).readAsStringSync();
      expect(content.contains('stressEventRowToEntity'), isTrue,
          reason: 'mapper 公开 row→entity 翻译 function');
    });

    test('repository_impl 迁到 features/daily_tracking/data/repositories/', () {
      expect(File(newRepoImplPath).existsSync(), isTrue);
    });

    test('entity (domain) 迁到 features/daily_tracking/domain/entities/', () {
      expect(File(newEntityPath).existsSync(), isTrue);
      final content = File(newEntityPath).readAsStringSync();
      expect(content.contains('class StressEventEntity'), isTrue,
          reason: 'entity class 完整');
    });

    test('repository abstract 迁到 features/daily_tracking/domain/repositories/', () {
      expect(File(newRepoPath).existsSync(), isTrue);
      final content = File(newRepoPath).readAsStringSync();
      expect(content.contains('abstract class StressEventRepository'), isTrue,
          reason: 'abstract class 完整');
    });
  });

  group('R126 阶段 2 step 1 — 旧路径 re-export 兼容 (现有用户 0 改动)', () {
    test('旧 entity 路径 lib/domain/entities/stress_event.dart 是 re-export', () {
      final content = File(oldEntityPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart'"),
        isTrue,
        reason: '旧路径保留为 re-export 兼容现有用户',
      );
    });

    test('旧 abstract 路径 lib/domain/repositories/stress_event_repository.dart 是 re-export', () {
      final content = File(oldRepoPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/repositories/stress_event_repository.dart'"),
        isTrue,
        reason: '旧 abstract 路径保留为 re-export 兼容现有用户',
      );
    });
  });

  group('R126 阶段 2 step 1 — 新旧路径 import 等价 (编译验证)', () {
    test('新旧 entity 路径 import 同一 class', () {
      // 旧路径 import 编译通过 (跟新路径同一 class, re-export 机制)
      final oldEntity = StressEventEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 17),
        eventType: 'work',
        intensity: 3,
      );
      expect(oldEntity.id, 1);
      expect(oldEntity.eventType, 'work');
      expect(oldEntity.intensity, 3);
    });
  });

  group('R126 阶段 2 step 1 — R125 + R126 同一 feature 2 子表共存 (daily_tracking)', () {
    test('R125 anxiety_agitation + R126 stress_event 同一 features/daily_tracking/', () {
      // R125 + R126 阶段 2 step 1 同一 feature 2 子表共存, 验证 R110 阶段 2
      // step 1 "扩第 2 子表" 设计
      final dailyTrackingDir = Directory('lib/features/daily_tracking');
      expect(dailyTrackingDir.existsSync(), isTrue);
      // 6 子表中 2 个已迁 (R125 anxiety_agitation + R126 stress_event)
      expect(
        File('lib/features/daily_tracking/data/tables/anxiety_agitation_entries.dart')
            .existsSync(),
        isTrue,
        reason: 'R125 anxiety_agitation 子表已迁',
      );
      expect(
        File('lib/features/daily_tracking/data/tables/stress_events.dart')
            .existsSync(),
        isTrue,
        reason: 'R126 stress_event 子表已迁 (R110 阶段 2 step 1)',
      );
      // 4 子表仍未迁 (sleep / weight / social_rhythm / treatment)
      expect(
        File('lib/features/daily_tracking/data/tables/sleep_entries.dart')
            .existsSync(),
        isFalse,
        reason: 'sleep 子表未迁 (R126 step 2+)',
      );
    });

    test('R125 + R126 旧路径 re-export 共存 2 个 (anxiety + stress)', () {
      // 2 子表旧路径都改 re-export, 现有用户 (repository_impl 等) 0 改动
      final oldEntityAnxiety =
          File('lib/domain/entities/anxiety_agitation_entry.dart')
              .readAsStringSync();
      final oldEntityStress =
          File('lib/domain/entities/stress_event.dart').readAsStringSync();
      expect(
        oldEntityAnxiety.contains(
            "export 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart'"),
        isTrue,
      );
      expect(
        oldEntityStress.contains(
            "export 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart'"),
        isTrue,
      );
    });
  });
}
