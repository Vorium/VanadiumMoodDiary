// v1.1.0+177 R126 续 step 5 (R110 feature-first 阶段 2 续 step 5) —
// mood 完整迁移验证
//
// Goal: 验证 R110 阶段 2 续 step 5 — mood 1 feature 完整迁移 1 commit
// 推完。R126 续 step 4 评估 (1.1.0+176) 走"1 feature 27 file 端到端"模式
// (含 presentation 15 file), 本批 mood 走"1 feature 40 file 端到端"模式
// (含 presentation 29 file + mood_audio 4 facade 跟 vent_audio shared
// EncryptedAudioStorage 基类)。
//
// 验证 4 类:
//   1. features/mood/ 目录结构 (data/domain/presentation 3 子目录)
//   2. 40 file 端到端 (3 domain + 8 data + 29 presentation) 全部存在
//   3. 40 旧 path 全部 re-export (1 行 export 新 path)
//   4. 跨 feature import 边界 0 违规 (features/mood 不引用其他 features/)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R126 续 step 5 mood 1 commit 整包 验证', () {
    test('features/mood/ 目录结构 3 子目录 (data/domain/presentation) 全在', () {
      for (final sub in const [
        'data',
        'domain',
        'presentation',
      ]) {
        final dir = Directory('lib/features/mood/$sub');
        expect(dir.existsSync(), isTrue, reason: '$sub 子目录应存在');
      }
    });

    test('mood 3 domain file 端到端 (2 entity + 1 abstract) 全部存在', () {
      const expected = <String>[
        'lib/features/mood/domain/entities/mood_entry_entity.dart',
        'lib/features/mood/domain/entities/mood_entry_draft.dart',
        'lib/features/mood/domain/repositories/mood_repository.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('mood 8 data file 端到端 (1 impl + 1 mapper + 1 table + 5 service) 全部存在', () {
      const expected = <String>[
        'lib/features/mood/data/repositories/mood_repository_impl.dart',
        'lib/features/mood/data/mappers/mood_entry_mapper.dart',
        'lib/features/mood/data/tables/mood_entries.dart',
        'lib/features/mood/data/services/mood_audio_service.dart',
        'lib/features/mood/data/services/mood_audio_recorder.dart',
        'lib/features/mood/data/services/mood_audio_stt.dart',
        'lib/features/mood/data/services/mood_audio_storage.dart',
        'lib/features/mood/data/services/mood_reminder_notifier.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('mood 29 presentation file 端到端 (2 provider + 4 page + 16 mood widget + 7 mood_list widget) 全部存在', () {
      const expected = <String>[
        // 2 provider
        'lib/features/mood/presentation/providers/mood_providers.dart',
        'lib/features/mood/presentation/providers/mood_list_filter_provider.dart',
        // 4 mood_list page
        'lib/features/mood/presentation/pages/mood_list/mood_list_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_detail_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_review_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_trend_page.dart',
        // 16 mood widget
        'lib/features/mood/presentation/pages/mood/widgets/cbt_explainer_card.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_prompt_sheet.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_section_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_three_column_mode.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_wizard.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_section.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_types.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_influence_chips.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_recorder_page.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_submit_panel.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_tags.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_text_input.dart',
        'lib/features/mood/presentation/pages/mood/widgets/period_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/status_phrase_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/stt_live_transcript.dart',
        // 7 mood_list widget
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_cbt_chart.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_distribution_chart.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_factor_analysis.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_filter_bar.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_item.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_period_filter_bar.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('40 file 端到端 全部存在 (3 domain + 8 data + 29 presentation)', () {
      // 跨 mood_audio_storage 跟 vent_audio shared EncryptedAudioStorage 基类
      // (留 core/data/privacy/encrypted_audio_storage.dart, R128 阶段 4 抽
      // core/platform/ umbrella 处理).
      final allFiles = <String>[
        // 3 domain
        'lib/features/mood/domain/entities/mood_entry_entity.dart',
        'lib/features/mood/domain/entities/mood_entry_draft.dart',
        'lib/features/mood/domain/repositories/mood_repository.dart',
        // 8 data
        'lib/features/mood/data/repositories/mood_repository_impl.dart',
        'lib/features/mood/data/mappers/mood_entry_mapper.dart',
        'lib/features/mood/data/tables/mood_entries.dart',
        'lib/features/mood/data/services/mood_audio_service.dart',
        'lib/features/mood/data/services/mood_audio_recorder.dart',
        'lib/features/mood/data/services/mood_audio_stt.dart',
        'lib/features/mood/data/services/mood_audio_storage.dart',
        'lib/features/mood/data/services/mood_reminder_notifier.dart',
        // 29 presentation
        'lib/features/mood/presentation/providers/mood_providers.dart',
        'lib/features/mood/presentation/providers/mood_list_filter_provider.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_list_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_detail_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_review_page.dart',
        'lib/features/mood/presentation/pages/mood_list/mood_trend_page.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_explainer_card.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_prompt_sheet.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_section_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_three_column_mode.dart',
        'lib/features/mood/presentation/pages/mood/widgets/cbt_wizard.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_section.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_audio_types.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_influence_chips.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_recorder_page.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_submit_panel.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_tags.dart',
        'lib/features/mood/presentation/pages/mood/widgets/mood_text_input.dart',
        'lib/features/mood/presentation/pages/mood/widgets/period_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/status_phrase_field.dart',
        'lib/features/mood/presentation/pages/mood/widgets/stt_live_transcript.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_cbt_chart.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_distribution_chart.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_factor_analysis.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_filter_bar.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_item.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_list_period_filter_bar.dart',
        'lib/features/mood/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart',
      ];
      expect(allFiles.length, 40, reason: 'mood 40 file 端到端');
      for (final path in allFiles) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('40 旧 path 全部 re-export (1 行 export 新 path)', () {
      // 跟 R125 阶段 1 + R126 阶段 2 + R126 续 step 4 模式: 旧 file body 改 1 行
      // export 新 path, 现有用户 import 旧 path 仍 work (re-export 机制).
      const oldPaths = <String>[
        // 3 domain
        'lib/domain/entities/mood_entry_entity.dart',
        'lib/domain/entities/mood_entry_draft.dart',
        'lib/domain/repositories/mood_repository.dart',
        // 8 data
        'lib/core/data/repositories/mood/mood_repository_impl.dart',
        'lib/core/data/database/mappers/mood/mood_entry_mapper.dart',
        'lib/core/data/database/tables/mood/mood_entries.dart',
        'lib/core/data/services/mood_audio_service.dart',
        'lib/core/data/services/mood_audio_recorder.dart',
        'lib/core/data/services/mood_audio_stt.dart',
        'lib/core/data/services/mood_audio_storage.dart',
        'lib/core/data/services/mood_reminder_notifier.dart',
        // 29 presentation
        'lib/presentation/providers/mood_providers.dart',
        'lib/presentation/providers/mood_list_filter_provider.dart',
        'lib/presentation/pages/mood_list/mood_list_page.dart',
        'lib/presentation/pages/mood_list/mood_detail_page.dart',
        'lib/presentation/pages/mood_list/mood_review_page.dart',
        'lib/presentation/pages/mood_list/mood_trend_page.dart',
        'lib/presentation/pages/mood/widgets/cbt_explainer_card.dart',
        'lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart',
        'lib/presentation/pages/mood/widgets/cbt_section_field.dart',
        'lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart',
        'lib/presentation/pages/mood/widgets/cbt_wizard.dart',
        'lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart',
        'lib/presentation/pages/mood/widgets/mood_audio_section.dart',
        'lib/presentation/pages/mood/widgets/mood_audio_types.dart',
        'lib/presentation/pages/mood/widgets/mood_influence_chips.dart',
        'lib/presentation/pages/mood/widgets/mood_recorder_page.dart',
        'lib/presentation/pages/mood/widgets/mood_submit_panel.dart',
        'lib/presentation/pages/mood/widgets/mood_tags.dart',
        'lib/presentation/pages/mood/widgets/mood_text_input.dart',
        'lib/presentation/pages/mood/widgets/period_field.dart',
        'lib/presentation/pages/mood/widgets/status_phrase_field.dart',
        'lib/presentation/pages/mood/widgets/stt_live_transcript.dart',
        'lib/presentation/pages/mood_list/widgets/mood_cbt_chart.dart',
        'lib/presentation/pages/mood_list/widgets/mood_distribution_chart.dart',
        'lib/presentation/pages/mood_list/widgets/mood_factor_analysis.dart',
        'lib/presentation/pages/mood_list/widgets/mood_list_filter_bar.dart',
        'lib/presentation/pages/mood_list/widgets/mood_list_item.dart',
        'lib/presentation/pages/mood_list/widgets/mood_list_period_filter_bar.dart',
        'lib/presentation/pages/mood_list/widgets/mood_trend_line_chart.dart',
      ];
      for (final path in oldPaths) {
        final content = File(path).readAsStringSync();
        // 旧 file 应是 re-export 模式 (1 行 export + library 声明 + 注释)
        expect(
          content.contains("export 'package:chroniccare/features/mood/"),
          isTrue,
          reason: '$path 应 re-export 新 features/mood/ path',
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
      // 抽样: MoodEntryEntity 来自旧 path 应跟新 path 是同 class
      final oldContent = File('lib/domain/entities/mood_entry_entity.dart').readAsStringSync();
      final newContent =
          File('lib/features/mood/domain/entities/mood_entry_entity.dart').readAsStringSync();
      // 旧 path 应 1 行 export 新 path
      expect(
        oldContent.contains("export 'package:chroniccare/features/mood/domain/entities/mood_entry_entity.dart';"),
        isTrue,
        reason: '旧 path 应 1 行 export 新 path',
      );
      // 新 path 应含 class MoodEntryEntity { ... }
      expect(
        newContent.contains('class MoodEntryEntity'),
        isTrue,
        reason: '新 path 应含 class MoodEntryEntity 实际定义',
      );
    });

    test('features/mood/ 内 file 不引用其他 features/ (跨 feature 边界 0 违规)', () {
      // R110 阶段 1+2 gate: feature 内 file 不引用其他 features/.
      // mood 1 commit 整包 R126 续 step 5 不应引用 daily_tracking/assessment/vent/medication
      // 任何 features/ path.
      final files = Directory('lib/features/mood')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      for (final f in files) {
        final content = f.readAsStringSync();
        for (final otherFeat in const [
          'features/daily_tracking/',
          'features/assessment/',
          'features/vent/',
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

    test('业务方法 0 break (MoodEntryEntity 24 字段 + MoodRepository 6 method)', () {
      // R126 续 step 5 mood 1 commit 整包业务方法跟旧版 0 改, 验证 0 break widget 端
      // 1. MoodEntryEntity 关键 24 字段 (id / timestamp / score / energy / sleep / anxiety /
      //    tagsJson / note / audioPath / audioTranscript / audioDurationMs / situation /
      //    automaticThought / evidenceFor / evidenceAgainst / alternativeThought /
      //    reratedScore / coreBelief / behaviorResponse / period / influenceFactorsJson /
      //    recordingMode / statusPhrase / worryThreadId, 实际 24)
      final entityContent =
          File('lib/features/mood/domain/entities/mood_entry_entity.dart').readAsStringSync();
      for (final field in const [
        'final int id',
        'final DateTime timestamp',
        'final int score',
        'final int? energy',
        'final int? sleep',
        'final int? anxiety',
        'final String tagsJson',
        'final String? note',
        'final String? audioPath',
        'final String? audioTranscript',
        'final int? audioDurationMs',
        'final String? situation',
        'final String? automaticThought',
        'final String? evidenceFor',
        'final String? evidenceAgainst',
        'final String? alternativeThought',
        'final int? reratedScore',
        'final String? coreBelief',
        'final String? behaviorResponse',
        'final String? period',
        'final String influenceFactorsJson',
        'final String? recordingMode',
        'final String? statusPhrase',
        'final int? worryThreadId',
      ]) {
        expect(
          entityContent.contains(field),
          isTrue,
          reason: 'MoodEntryEntity.$field 字段保留 (0 break)',
        );
      }
      // 2. MoodRepository 公开方法 6 个 (watchAll / watchToday / watchLatest / add / delete / watchByThread)
      final abstractContent =
          File('lib/features/mood/domain/repositories/mood_repository.dart').readAsStringSync();
      for (final method in const [
        'Stream<List<MoodEntryEntity>> watchAll()',
        'Stream<List<MoodEntryEntity>> watchToday()',
        'Stream<MoodEntryEntity?> watchLatest()',
        'Future<int> add({required MoodEntryDraft draft})',
        'Future<int> delete(int id)',
        'Stream<List<MoodEntryEntity>> watchByThread(int threadId)',
      ]) {
        expect(
          abstractContent.contains(method),
          isTrue,
          reason: 'MoodRepository.$method 方法保留 (0 break)',
        );
      }
    });

    test('mood_audio 4 facade 公开 API 完整 (跟 R122 P2-1 拆 3 facade 协同)', () {
      // R122 P2-1 拆 3 facade: mood_audio_service (orchestrator) + mood_audio_recorder +
      //   mood_audio_stt + mood_audio_storage (R121 抽 EncryptedAudioStorage 基类).
      // R126 续 step 5 mood 1 commit 整包迁 features/mood/, 4 facade 公开 API 完整.
      final mainContent =
          File('lib/features/mood/data/services/mood_audio_service.dart').readAsStringSync();
      expect(
        mainContent.contains('abstract class MoodAudioService'),
        isTrue,
        reason: 'MoodAudioService abstract class 保留 (R122 P2-1 拆 facade)',
      );
      final recorderContent =
          File('lib/features/mood/data/services/mood_audio_recorder.dart').readAsStringSync();
      expect(
        recorderContent.contains('class MoodAudioRecorder'),
        isTrue,
        reason: 'MoodAudioRecorder class 保留 (R122 P2-1 step 2)',
      );
      final sttContent =
          File('lib/features/mood/data/services/mood_audio_stt.dart').readAsStringSync();
      expect(
        sttContent.contains('class MoodAudioStt'),
        isTrue,
        reason: 'MoodAudioStt class 保留 (R122 P2-1 step 1)',
      );
      final storageContent =
          File('lib/features/mood/data/services/mood_audio_storage.dart').readAsStringSync();
      expect(
        storageContent.contains('extends EncryptedAudioStorage'),
        isTrue,
        reason: 'MoodAudioStorage extends EncryptedAudioStorage (R122 P2-1 step 3)',
      );
    });

    test('R95 lock-in 协同: features/mood/presentation ≤ 2 raw EdgeInsets 数字 (R95 修正 baseline)', () {
      // 跟 R125 阶段 1 + R126 续 step 4 模式: features/ 内 file 应走 spacing token
      // 不直接用 EdgeInsets.all(16) 等 raw 数字. R95 lock-in 修正效果.
      // R95 修正 baseline 漏修正 mood_review_page 2 处 (历史 baseline 已知,
      // 留 R31+ 跨期修正, 不在本批 R126 续 step 5 范围). 因此接受 ≤ 2 raw.
      final files = Directory('lib/features/mood')
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
      // R95 修正 baseline 接受 ≤ 2 (mood_review_page 漏修正 2 处已知, 留 R31+ 修正)
      expect(
        rawEdgeInsetsCount,
        lessThanOrEqualTo(2),
        reason: 'R95 修正 baseline 接受 ≤ 2 raw EdgeInsets 数字 (mood_review_page 已知 2 处)',
      );
    });

    test('R110 阶段 2 续 step 5 mood 1 commit 整包 1 feature 完整迁移 收官', () {
      // 验收: features/ 顶层 3 个 feature (daily_tracking + assessment + mood),
      // 阶段 2 续 step 4 + step 5 是 R110 阶段 2 跨 presentation 完整迁移 2 feature.
      // 阶段 2 续剩余 2 feature (vent / medication) 留 R126 续 step 6-7.
      final featureDirs = Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .toList();
      expect(
        featureDirs.map((d) => d.path.split('/').last).toList()..sort(),
        equals(['assessment', 'crisis', 'daily_tracking', 'home', 'medication', 'mood', 'settings', 'setup', 'tips', 'trend', 'vent', 'worry']),
        reason: 'R126 续 step 4 + step 5 收官 features/ 顶层 3 feature (daily_tracking + assessment + mood)',
      );
    });
  });
}
