// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — daily_tracking 收官
// (weight + social_rhythm + treatment 3 子表 端到端, 6/6 子表迁移 100%)
//
// Goal: 验证 R126 阶段 2 step 3 收官, daily_tracking 6/6 子表全迁
// (anxiety + stress + sleep + weight + social_rhythm + treatment)。

import 'dart:io';

import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/social_rhythm_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/treatment_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/weight_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/repositories/social_rhythm_repository_impl.dart';
import 'package:chroniccare/features/daily_tracking/data/repositories/treatment_repository_impl.dart';
import 'package:chroniccare/features/daily_tracking/data/repositories/weight_repository_impl.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/social_rhythm_entries.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/treatment_entries.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/weight_entries.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/treatment_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/weight_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/social_rhythm_repository.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/treatment_repository.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/weight_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const newWeightTable =
      'lib/features/daily_tracking/data/tables/weight_entries.dart';
  const newWeightMapper =
      'lib/features/daily_tracking/data/mappers/weight_mapper.dart';
  const newWeightImpl =
      'lib/features/daily_tracking/data/repositories/weight_repository_impl.dart';
  const newWeightEntity =
      'lib/features/daily_tracking/domain/entities/weight_entry.dart';
  const newWeightRepo =
      'lib/features/daily_tracking/domain/repositories/weight_repository.dart';
  const oldWeightEntity = 'lib/domain/entities/weight_entry.dart';
  const oldWeightRepo = 'lib/domain/repositories/weight_repository.dart';

  const newSrTable =
      'lib/features/daily_tracking/data/tables/social_rhythm_entries.dart';
  const newSrMapper =
      'lib/features/daily_tracking/data/mappers/social_rhythm_mapper.dart';
  const newSrImpl =
      'lib/features/daily_tracking/data/repositories/social_rhythm_repository_impl.dart';
  const newSrEntity =
      'lib/features/daily_tracking/domain/entities/social_rhythm_entry.dart';
  const newSrRepo =
      'lib/features/daily_tracking/domain/repositories/social_rhythm_repository.dart';
  const oldSrEntity = 'lib/domain/entities/social_rhythm_entry.dart';
  const oldSrRepo = 'lib/domain/repositories/social_rhythm_repository.dart';

  const newTxTable =
      'lib/features/daily_tracking/data/tables/treatment_entries.dart';
  const newTxMapper =
      'lib/features/daily_tracking/data/mappers/treatment_mapper.dart';
  const newTxImpl =
      'lib/features/daily_tracking/data/repositories/treatment_repository_impl.dart';
  const newTxEntity =
      'lib/features/daily_tracking/domain/entities/treatment_entry.dart';
  const newTxRepo =
      'lib/features/daily_tracking/domain/repositories/treatment_repository.dart';
  const oldTxEntity = 'lib/domain/entities/treatment_entry.dart';
  const oldTxRepo = 'lib/domain/repositories/treatment_repository.dart';

  group('R126 step 3 收官 — weight 5 file 端到端 (R125 样板扩展)', () {
    test('drift table 迁到 features/daily_tracking/data/tables/', () {
      expect(File(newWeightTable).existsSync(), isTrue);
      final content = File(newWeightTable).readAsStringSync();
      expect(content.contains('class WeightEntries extends Table'), isTrue);
      expect(content.contains('weightKg'), isTrue);
    });

    test('mapper / impl / entity / abstract 全部在新路径', () {
      expect(File(newWeightMapper).existsSync(), isTrue);
      expect(File(newWeightImpl).existsSync(), isTrue);
      expect(File(newWeightEntity).existsSync(), isTrue);
      expect(File(newWeightRepo).existsSync(), isTrue);
    });

    test('业务方法 (isValidWeight / bmiCategory) 跟旧版一致', () {
      final content = File(newWeightEntity).readAsStringSync();
      expect(content.contains('isValidWeight'), isTrue,
          reason: '业务方法 isValidWeight (30-200 kg 范围) 0 break widget 端');
      expect(content.contains('bmiCategory'), isTrue,
          reason: '业务方法 bmiCategory (英文 i18n key, 跟旧版一致)');
    });
  });

  group('R126 step 3 收官 — social_rhythm 5 file 端到端', () {
    test('drift table + 4 file 全部在新路径', () {
      expect(File(newSrTable).existsSync(), isTrue);
      final content = File(newSrTable).readAsStringSync();
      expect(content.contains('class SocialRhythmEntries extends Table'), isTrue);
      expect(content.contains('socialMin'), isTrue,
          reason: '含 socialMin / workMin / exerciseMin 3 个时长字段');
      expect(File(newSrMapper).existsSync(), isTrue);
      expect(File(newSrImpl).existsSync(), isTrue);
      expect(File(newSrEntity).existsSync(), isTrue);
      expect(File(newSrRepo).existsSync(), isTrue);
    });
  });

  group('R126 step 3 收官 — treatment 5 file 端到端', () {
    test('drift table + 4 file 全部在新路径', () {
      expect(File(newTxTable).existsSync(), isTrue);
      final content = File(newTxTable).readAsStringSync();
      expect(content.contains('class TreatmentEntries extends Table'), isTrue);
      expect(content.contains('linkedMedicationName'), isTrue,
          reason: '含 linkedMedicationName 缓存 (R55 medication rename 后历史显示原名)');
      expect(File(newTxMapper).existsSync(), isTrue);
      expect(File(newTxImpl).existsSync(), isTrue);
      expect(File(newTxEntity).existsSync(), isTrue);
      expect(File(newTxRepo).existsSync(), isTrue);
    });

    test('业务方法 (isLinkedToMedication / linkedMedicationDisplay) 跟旧版一致', () {
      final content = File(newTxEntity).readAsStringSync();
      expect(content.contains('isLinkedToMedication'), isTrue);
      expect(content.contains('linkedMedicationDisplay'), isTrue,
          reason: '业务方法 linkedMedicationDisplay (中文 fallback "无关联")');
    });
  });

  group('R126 step 3 收官 — 6 旧路径全部 re-export (现有用户 0 改动)', () {
    test('weight + social_rhythm + treatment 6 file 旧路径全部 re-export', () {
      for (final (entity, repo, newEntity, newRepo) in [
        (oldWeightEntity, oldWeightRepo, newWeightEntity, newWeightRepo),
        (oldSrEntity, oldSrRepo, newSrEntity, newSrRepo),
        (oldTxEntity, oldTxRepo, newTxEntity, newTxRepo),
      ]) {
        final entityContent = File(entity).readAsStringSync();
        final repoContent = File(repo).readAsStringSync();
        expect(
          entityContent.contains("export 'package:chroniccare/features/daily_tracking/domain/entities/${newEntity.split('/').last}'"),
          isTrue,
          reason: '$entity 旧路径 re-export 新路径',
        );
        expect(
          repoContent.contains("export 'package:chroniccare/features/daily_tracking/domain/repositories/${newRepo.split('/').last}'"),
          isTrue,
          reason: '$repo 旧路径 re-export 新路径',
        );
      }
    });
  });

  group('R126 step 3 收官 — 新旧 entity 路径编译验证 + 业务方法', () {
    test('weight entity 业务方法 work (新 + 旧路径 import 同 class)', () {
      final w = WeightEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 17),
        weightKg: 70.0,
        bmi: 22.5,
      );
      expect(w.isValidWeight, isTrue, reason: '70kg 在 30-200 范围');
      expect(w.bmiCategory, 'normal', reason: 'bmi 22.5 算 normal');
      expect(WeightEntryEntity(
        id: 2,
        timestamp: DateTime(2026, 8, 17),
        weightKg: 100.0,
        bmi: 32.0,
      ).bmiCategory, 'obese', reason: 'bmi 32 算 obese');
    });

    test('social_rhythm entity 0 业务方法 (跟旧版一致)', () {
      final sr = SocialRhythmEntryEntity(
        id: 1,
        date: DateTime(2026, 8, 17),
        wakeTime: DateTime(2026, 8, 17, 7),
        firstMealTime: DateTime(2026, 8, 17, 8),
        lastMealTime: DateTime(2026, 8, 17, 19),
        socialMin: 60,
        workMin: 480,
        exerciseMin: 30,
      );
      expect(sr.socialMin, 60);
      expect(sr.workMin, 480);
      expect(sr.exerciseMin, 30);
    });

    test('treatment entity 业务方法 work (linkedMedicationDisplay)', () {
      final t1 = TreatmentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 17),
        treatmentType: 'medication',
        description: '服药',
      );
      expect(t1.isLinkedToMedication, isFalse);
      expect(t1.linkedMedicationDisplay, '无关联',
          reason: 'linkedMedicationName = null 时 fallback "无关联"');

      final t2 = TreatmentEntryEntity(
        id: 2,
        timestamp: DateTime(2026, 8, 17),
        treatmentType: 'medication',
        description: '服药',
        linkedMedicationId: 5,
        linkedMedicationName: 'Aspirin',
      );
      expect(t2.isLinkedToMedication, isTrue);
      expect(t2.linkedMedicationDisplay, 'Aspirin',
          reason: 'linkedMedicationName 缓存优先 (R55 medication rename 后历史显示原名)');
    });
  });

  group('R126 step 3 收官 — daily_tracking 6/6 子表全迁 (100% 收官)', () {
    test('6/6 子表全已迁 (anxiety + stress + sleep + weight + social_rhythm + treatment)', () {
      // R125 + R126 step 1+2+3 累计 daily_tracking 6/6 子表全迁
      // daily_tracking feature 在 R110 阶段 2 收官 100%
      final allTables = [
        'anxiety_agitation_entries.dart',  // R125
        'stress_events.dart',                // R126 step 1
        'sleep_entries.dart',                // R126 step 2
        'weight_entries.dart',               // R126 step 3
        'social_rhythm_entries.dart',        // R126 step 3
        'treatment_entries.dart',            // R126 step 3
      ];
      for (final f in allTables) {
        expect(
          File('lib/features/daily_tracking/data/tables/$f').existsSync(),
          isTrue,
          reason: '$f 已迁 (R125 + R126 step 1+2+3 daily_tracking 收官 100%)',
        );
      }
    });

    test('旧路径 12 file 全部 re-export (6 entity + 6 abstract)', () {
      // 6 子表 × (entity + abstract) = 12 旧路径 file
      final oldFiles = [
        'lib/domain/entities/anxiety_agitation_entry.dart',
        'lib/domain/entities/stress_event.dart',
        'lib/domain/entities/sleep_entry.dart',
        'lib/domain/entities/weight_entry.dart',
        'lib/domain/entities/social_rhythm_entry.dart',
        'lib/domain/entities/treatment_entry.dart',
        'lib/domain/repositories/anxiety_agitation_repository.dart',
        'lib/domain/repositories/stress_event_repository.dart',
        'lib/domain/repositories/sleep_repository.dart',
        'lib/domain/repositories/weight_repository.dart',
        'lib/domain/repositories/social_rhythm_repository.dart',
        'lib/domain/repositories/treatment_repository.dart',
      ];
      for (final f in oldFiles) {
        final content = File(f).readAsStringSync();
        expect(
          content.contains("export 'package:chroniccare/features/daily_tracking/"),
          isTrue,
          reason: '$f 旧路径 re-export 新路径',
        );
      }
    });
  });
}
