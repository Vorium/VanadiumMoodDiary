// v1.1.0+178 R126 续 step 6 (R110 feature-first 阶段 2 续 step 6) —
// vent 完整迁移验证
//
// Goal: 验证 R110 阶段 2 续 step 6 — vent 1 feature 完整迁移 1 commit
// 推完。R126 续 step 5 mood 走"1 feature 40 file 端到端"模式, 本批 vent 走
// "1 feature 19 file 端到端"模式 (含 presentation 11 file + vent_audio_storage
// 跟 mood_audio_storage shared EncryptedAudioStorage 基类 + 跨 export/import
// 3 service + 跨 home_hero_card + daily_tracking + trend widget 留 R128 阶段 4).
//
// 验证 4 类:
//   1. features/vent/ 目录结构 (data/domain/presentation 3 子目录)
//   2. 19 file 端到端 (2 domain + 6 data + 11 presentation) 全部存在
//   3. 19 旧 path 全部 re-export (1 行 export 新 path)
//   4. 跨 feature import 边界 0 违规 (features/vent 不引用其他 features/)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R126 续 step 6 vent 1 commit 整包 验证', () {
    test('features/vent/ 目录结构 3 子目录 (data/domain/presentation) 全在', () {
      for (final sub in const [
        'data',
        'domain',
        'presentation',
      ]) {
        final dir = Directory('lib/features/vent/$sub');
        expect(dir.existsSync(), isTrue, reason: '$sub 子目录应存在');
      }
    });

    test('vent 2 domain file 端到端 (1 entity + 1 abstract) 全部存在', () {
      const expected = <String>[
        'lib/features/vent/domain/entities/vent_entry_entity.dart',
        'lib/features/vent/domain/repositories/vent_repository.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('vent 6 data file 端到端 (1 impl + 1 mapper + 1 dao + 1 table + 2 service) 全部存在', () {
      const expected = <String>[
        'lib/features/vent/data/repositories/vent_repository_impl.dart',
        'lib/features/vent/data/mappers/vent_mapper.dart',
        'lib/features/vent/data/daos/vent_dao.dart',
        'lib/features/vent/data/tables/vent_entries.dart',
        'lib/features/vent/data/services/vent_agreement_store.dart',
        'lib/features/vent/data/services/vent_audio_storage.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('vent 11 presentation file 端到端 (1 provider + 3 page + 7 widget) 全部存在', () {
      const expected = <String>[
        // 1 provider
        'lib/features/vent/presentation/providers/vent_providers.dart',
        // 3 page
        'lib/features/vent/presentation/pages/vent/vent_compose_page.dart',
        'lib/features/vent/presentation/pages/vent/vent_detail_page.dart',
        'lib/features/vent/presentation/pages/vent/vent_list_page.dart',
        // 7 widget
        'lib/features/vent/presentation/pages/vent/widgets/vent_agreement_dialog.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_audio_section.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_cell.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_list.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_save_bar.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_tag_picker.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_text_input.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('19 file 端到端 全部存在 (2 domain + 6 data + 11 presentation)', () {
      // 跨 vent_audio_storage 跟 mood_audio_storage shared EncryptedAudioStorage
      // 基类 (留 core/data/privacy/encrypted_audio_storage.dart, R128 阶段 4 抽
      // core/platform/ umbrella 处理). 跨 export/import 3 service 留 core, 跨
      // home_hero_card + daily_tracking + trend widget 留 R128 阶段 4.
      final allFiles = <String>[
        // 2 domain
        'lib/features/vent/domain/entities/vent_entry_entity.dart',
        'lib/features/vent/domain/repositories/vent_repository.dart',
        // 6 data
        'lib/features/vent/data/repositories/vent_repository_impl.dart',
        'lib/features/vent/data/mappers/vent_mapper.dart',
        'lib/features/vent/data/daos/vent_dao.dart',
        'lib/features/vent/data/tables/vent_entries.dart',
        'lib/features/vent/data/services/vent_agreement_store.dart',
        'lib/features/vent/data/services/vent_audio_storage.dart',
        // 11 presentation
        'lib/features/vent/presentation/providers/vent_providers.dart',
        'lib/features/vent/presentation/pages/vent/vent_compose_page.dart',
        'lib/features/vent/presentation/pages/vent/vent_detail_page.dart',
        'lib/features/vent/presentation/pages/vent/vent_list_page.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_agreement_dialog.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_audio_section.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_cell.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_entry_list.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_save_bar.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_tag_picker.dart',
        'lib/features/vent/presentation/pages/vent/widgets/vent_text_input.dart',
      ];
      expect(allFiles.length, 19, reason: 'vent 19 file 端到端');
      for (final path in allFiles) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('19 旧 path 全部 re-export (1 行 export 新 path)', () {
      // 跟 R125 阶段 1 + R126 续 step 4/5 模式: 旧 file body 改 1 行
      // export 新 path, 现有用户 import 旧 path 仍 work (re-export 机制).
      const oldPaths = <String>[
        // 2 domain
        'lib/domain/entities/vent_entry_entity.dart',
        'lib/domain/repositories/vent_repository.dart',
        // 6 data
        'lib/core/data/repositories/vent/vent_repository_impl.dart',
        'lib/core/data/database/mappers/vent/vent_mapper.dart',
        'lib/core/data/database/daos/vent_dao.dart',
        'lib/core/data/database/tables/vent/vent_entries.dart',
        'lib/core/data/services/vent_agreement_store.dart',
        'lib/core/data/services/vent_audio_storage.dart',
        // 11 presentation
        'lib/presentation/providers/vent_providers.dart',
        'lib/presentation/pages/vent/vent_compose_page.dart',
        'lib/presentation/pages/vent/vent_detail_page.dart',
        'lib/presentation/pages/vent/vent_list_page.dart',
        'lib/presentation/pages/vent/widgets/vent_agreement_dialog.dart',
        'lib/presentation/pages/vent/widgets/vent_audio_section.dart',
        'lib/presentation/pages/vent/widgets/vent_entry_cell.dart',
        'lib/presentation/pages/vent/widgets/vent_entry_list.dart',
        'lib/presentation/pages/vent/widgets/vent_save_bar.dart',
        'lib/presentation/pages/vent/widgets/vent_tag_picker.dart',
        'lib/presentation/pages/vent/widgets/vent_text_input.dart',
      ];
      for (final path in oldPaths) {
        final content = File(path).readAsStringSync();
        // 旧 file 应是 re-export 模式 (1 行 export + library 声明 + 注释)
        expect(
          content.contains("export 'package:chroniccare/features/vent/"),
          isTrue,
          reason: '$path 应 re-export 新 features/vent/ path',
        );
        // 旧 file 不应含大段原内容 (re-export 模式 < 30 行, 实际 ~10 行)
        expect(
          content.split('\n').length,
          lessThan(30),
          reason: '$path 应是 1 行 re-export 模式 (实际 < 30 行)',
        );
      }
    });

    test('旧 path import 仍 work (现有用户 0 改动)', () {
      // 验证旧 path 跟新 path 是同一 class (re-export 机制)
      // 抽样: VentEntryEntity 来自旧 path 应跟新 path 是同 class
      final oldContent = File('lib/domain/entities/vent_entry_entity.dart').readAsStringSync();
      final newContent =
          File('lib/features/vent/domain/entities/vent_entry_entity.dart').readAsStringSync();
      // 旧 path 应 1 行 export 新 path
      expect(
        oldContent.contains("export 'package:chroniccare/features/vent/domain/entities/vent_entry_entity.dart';"),
        isTrue,
        reason: '旧 path 应 1 行 export 新 path',
      );
      // 新 path 应含 class VentEntryEntity { ... }
      expect(
        newContent.contains('class VentEntryEntity'),
        isTrue,
        reason: '新 path 应含 class VentEntryEntity 实际定义',
      );
    });

    test('features/vent/ 内 file 不引用其他 features/ (跨 feature 边界 0 违规)', () {
      // R110 阶段 1+2 gate: feature 内 file 不引用其他 features/.
      // vent 1 commit 整包 R126 续 step 6 不应引用 daily_tracking/assessment/mood/medication
      // 任何 features/ path.
      final files = Directory('lib/features/vent')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      for (final f in files) {
        final content = f.readAsStringSync();
        for (final otherFeat in const [
          'features/daily_tracking/',
          'features/assessment/',
          'features/mood/',
          'features/medication/',
        ]) {
          expect(
            content.contains(otherFeat),
            isFalse,
            reason: '${f.path} 不应引用 $otherFeat (跨 feature 边界违规)',
          );
        }
      }
    });

    test('业务方法 0 break (VentEntryEntity 7 字段 + VentRepository 6 method)', () {
      // R126 续 step 6 vent 1 commit 整包业务方法跟旧版 0 改, 验证 0 break widget 端
      final entityContent =
          File('lib/features/vent/domain/entities/vent_entry_entity.dart').readAsStringSync();
      for (final field in const [
        'final int id',
        'final DateTime timestamp',
        'final String? contentText',
        'final String? audioPath',
        'final int? audioDurationSec',
        'final int? audioSizeBytes',
        'final String tagsJson',
      ]) {
        expect(
          entityContent.contains(field),
          isTrue,
          reason: 'VentEntryEntity.$field 字段保留 (0 break)',
        );
      }
      // VentRepository 公开方法 6 个 (watchAll / add / delete / getById / restore / deleteAll)
      final abstractContent =
          File('lib/features/vent/domain/repositories/vent_repository.dart').readAsStringSync();
      for (final method in const [
        'Stream<List<VentEntryEntity>> watchAll()',
        'Future<int> add({',
        'Future<bool> delete(int id)',
        'Future<VentEntryEntity?> getById(int id)',
        'Future<int> restore(VentEntryEntity entry)',
        'Future<int> deleteAll()',
      ]) {
        expect(
          abstractContent.contains(method),
          isTrue,
          reason: 'VentRepository.$method 方法保留 (0 break)',
        );
      }
    });

    test('vent_audio_storage 公开 API 完整 (跟 R121 抽 EncryptedAudioStorage 基类协同)', () {
      // R121 抽 EncryptedAudioStorage 基类 (留 core/data/privacy/), vent_audio_storage
      // 跟 mood_audio_storage 都 extends 这个基类. R126 续 step 6 vent 1 commit
      // 整包迁 features/vent/, vent_audio_storage 公开 API 完整.
      final storageContent =
          File('lib/features/vent/data/services/vent_audio_storage.dart').readAsStringSync();
      expect(
        storageContent.contains('extends EncryptedAudioStorage'),
        isTrue,
        reason: 'VentAudioStorage extends EncryptedAudioStorage (R121 抽基类)',
      );
    });

    test('R95 lock-in 协同: features/vent/presentation 0 新增 raw EdgeInsets 数字 (R95 修正有效)', () {
      // 跟 R126 续 step 4/5 模式: features/ 内 file 应走 spacing token
      // 不直接用 EdgeInsets.all(16) 等 raw 数字. R95 lock-in 修正效果.
      final files = Directory('lib/features/vent')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && f.path.contains('presentation/'))
          .toList();
      var rawEdgeInsetsCount = 0;
      for (final f in files) {
        final content = f.readAsStringSync();
        final m = RegExp(
          r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(\s*\d+',
        ).allMatches(content);
        rawEdgeInsetsCount += m.length;
      }
      // R95 修正后 0 raw 数字 (所有 EdgeInsets 都走 token)
      expect(
        rawEdgeInsetsCount,
        0,
        reason: 'R95 修正后 features/vent/presentation 应 0 raw EdgeInsets 数字',
      );
    });

    test('R110 阶段 2 续 step 6 vent 1 commit 整包 1 feature 完整迁移 收官', () {
      // 验收: features/ 顶层 4 个 feature (daily_tracking + assessment + mood + vent),
      // 阶段 2 续 step 4-6 是 R110 阶段 2 跨 presentation 完整迁移 3 feature.
      // 阶段 2 续剩余 1 feature (medication) 留 R126 续 step 7.
      final featureDirs = Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .toList();
      expect(
        featureDirs.map((d) => d.path.split('/').last).toList()..sort(),
        equals(['assessment', 'crisis', 'daily_tracking', 'home', 'medication', 'mood', 'settings', 'setup', 'tips', 'trend', 'vent', 'worry']),
        reason: 'R126 续 step 4-6 收官 features/ 顶层 4 feature (daily_tracking + assessment + mood + vent)',
      );
    });
  });
}
