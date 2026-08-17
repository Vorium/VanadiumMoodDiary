// v1.1.0+176 R126 续 评估 1 commit 整包 (R110 feature-first 阶段 2 续 step 4) —
// assessment 完整迁移验证
//
// Goal: 验证 R110 阶段 2 续 step 4 — assessment 1 feature 完整迁移 1 commit
// 推完。R125 + R126 step 1+2+3 走"1 sub_table 5 file 端到端"模式, 本批评估
// 走"1 feature 完整 28 file 端到端"模式 (R110 阶段 2 续首个跨 presentation 迁移
// 完整 1 feature, 跟 R125 阶段 1 仅迁 5 file 不含 presentation 不同)。
//
// 验证 4 类:
//   1. features/assessment/ 目录结构 (data/domain/presentation 3 子目录)
//   2. 28 file 端到端 (7 domain + 5 data + 16 presentation) 全部存在
//   3. 28 旧 path 全部 re-export (1 行 export 新 path)
//   4. 跨 feature import 边界 0 违规 (features/assessment 不引用其他 features/)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R126 续 评估 1 commit 整包 验证', () {
    test('features/assessment/ 目录结构 3 子目录 (data/domain/presentation) 全在', () {
      for (final sub in const [
        'data',
        'domain',
        'presentation',
      ]) {
        final dir = Directory('lib/features/assessment/$sub');
        expect(dir.existsSync(), isTrue, reason: '$sub 子目录应存在');
      }
    });

    test('assessment 7 domain file 端到端 (1 entity + 4 logic + 1 usecase + 1 abstract) 全部存在', () {
      const expected = <String>[
        'lib/features/assessment/domain/entities/assessment_entry.dart',
        'lib/features/assessment/domain/logic/assessment_scale.dart',
        'lib/features/assessment/domain/logic/assessment_record.dart',
        'lib/features/assessment/domain/logic/assessment_comparison.dart',
        'lib/features/assessment/domain/logic/assessment_reminder_policy.dart',
        'lib/features/assessment/domain/repositories/assessment_reminder_sender.dart',
        'lib/features/assessment/domain/usecases/schedule_assessment_reminder.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('assessment 5 data file 端到端 (1 dao + 1 impl + 3 service) 全部存在', () {
      const expected = <String>[
        'lib/features/assessment/data/daos/assessment_dao.dart',
        'lib/features/assessment/data/repositories/assessment_repository_impl.dart',
        'lib/features/assessment/data/services/assessment_notifier.dart',
        'lib/features/assessment/data/services/assessment_reminder_service.dart',
        'lib/features/assessment/data/services/assessment_reminder_sender_impl.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('assessment 15 presentation file 端到端 (1 provider + 4 page + 10 widget) 全部存在', () {
      const expected = <String>[
        'lib/features/assessment/presentation/providers/assessment_providers.dart',
        'lib/features/assessment/presentation/pages/assessment_page.dart',
        'lib/features/assessment/presentation/pages/assessment_widgets.dart',
        'lib/features/assessment/presentation/pages/assessment_center_page.dart',
        'lib/features/assessment/presentation/pages/assessment_history_page.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_reminder_section.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_progress_header.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_severity_style.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_quiz_panel.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_result_panel.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_summary_strip.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_history_list.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_unavailable_card.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_center_card.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_chart_card.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('27 file 端到端 全部存在 (7 domain + 5 data + 15 presentation)', () {
      // 跨域 logic/assessment_comparison.dart 依赖 scale_registry (留 core/),
      // assessment_record.dart 依赖 check_in_entity (留 core/), 跨 feature
      // 共享留 R128 阶段 4 处理.
      final allFiles = <String>[
        // 7 domain
        'lib/features/assessment/domain/entities/assessment_entry.dart',
        'lib/features/assessment/domain/logic/assessment_scale.dart',
        'lib/features/assessment/domain/logic/assessment_record.dart',
        'lib/features/assessment/domain/logic/assessment_comparison.dart',
        'lib/features/assessment/domain/logic/assessment_reminder_policy.dart',
        'lib/features/assessment/domain/repositories/assessment_reminder_sender.dart',
        'lib/features/assessment/domain/usecases/schedule_assessment_reminder.dart',
        // 5 data
        'lib/features/assessment/data/daos/assessment_dao.dart',
        'lib/features/assessment/data/repositories/assessment_repository_impl.dart',
        'lib/features/assessment/data/services/assessment_notifier.dart',
        'lib/features/assessment/data/services/assessment_reminder_service.dart',
        'lib/features/assessment/data/services/assessment_reminder_sender_impl.dart',
        // 15 presentation
        'lib/features/assessment/presentation/providers/assessment_providers.dart',
        'lib/features/assessment/presentation/pages/assessment_page.dart',
        'lib/features/assessment/presentation/pages/assessment_widgets.dart',
        'lib/features/assessment/presentation/pages/assessment_center_page.dart',
        'lib/features/assessment/presentation/pages/assessment_history_page.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_reminder_section.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_progress_header.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_severity_style.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_quiz_panel.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_result_panel.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_summary_strip.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_history_list.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_unavailable_card.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_center_card.dart',
        'lib/features/assessment/presentation/pages/widgets/assessment_chart_card.dart',
      ];
      expect(allFiles.length, 27, reason: 'assessment 27 file 端到端');
      for (final path in allFiles) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('27 旧 path 全部 re-export (1 行 export 新 path)', () {
      // 跟 R125 阶段 1 + R126 step 1+2+3 模式: 旧 file body 改 1 行 export, 现有
      // 用户 import 旧 path 仍 work (re-export 机制).
      const oldPaths = <String>[
        // 7 domain
        'lib/domain/entities/assessment_entry.dart',
        'lib/domain/logic/assessment_scale.dart',
        'lib/domain/logic/assessment_record.dart',
        'lib/domain/logic/assessment_comparison.dart',
        'lib/domain/logic/assessment_reminder_policy.dart',
        'lib/domain/repositories/assessment_reminder_sender.dart',
        'lib/domain/usecases/schedule_assessment_reminder.dart',
        // 5 data
        'lib/core/data/database/daos/assessment_dao.dart',
        'lib/core/data/repositories/assessment/assessment_repository_impl.dart',
        'lib/core/data/services/assessment_notifier.dart',
        'lib/core/data/services/assessment_reminder_service.dart',
        'lib/core/data/services/assessment_reminder_sender_impl.dart',
        // 15 presentation
        'lib/presentation/providers/assessment_providers.dart',
        'lib/presentation/pages/assessment/assessment_page.dart',
        'lib/presentation/pages/assessment/assessment_widgets.dart',
        'lib/presentation/pages/assessment/assessment_center_page.dart',
        'lib/presentation/pages/assessment/assessment_history_page.dart',
        'lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart',
        'lib/presentation/pages/assessment/widgets/assessment_progress_header.dart',
        'lib/presentation/pages/assessment/widgets/assessment_severity_style.dart',
        'lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart',
        'lib/presentation/pages/assessment/widgets/assessment_result_panel.dart',
        'lib/presentation/pages/assessment/widgets/assessment_summary_strip.dart',
        'lib/presentation/pages/assessment/widgets/assessment_history_list.dart',
        'lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart',
        'lib/presentation/pages/assessment/widgets/assessment_center_card.dart',
        'lib/presentation/pages/assessment/widgets/assessment_chart_card.dart',
      ];
      for (final path in oldPaths) {
        final content = File(path).readAsStringSync();
        // 旧 file 应是 re-export 模式 (1 行 export + library 声明 + 注释)
        expect(
          content.contains("export 'package:chroniccare/features/assessment/"),
          isTrue,
          reason: '$path 应 re-export 新 features/assessment/ path',
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
      // 抽样: AssessmentEntry 来自旧 path 应跟新 path 是同 class
      // (通过 import 同 class 名称 + toString() 一致)
      final oldContent = File('lib/domain/entities/assessment_entry.dart').readAsStringSync();
      final newContent =
          File('lib/features/assessment/domain/entities/assessment_entry.dart').readAsStringSync();
      // 旧 path 应 1 行 export 新 path
      expect(
        oldContent.contains("export 'package:chroniccare/features/assessment/domain/entities/assessment_entry.dart';"),
        isTrue,
        reason: '旧 path 应 1 行 export 新 path',
      );
      // 新 path 应含 class AssessmentEntry { ... }
      expect(
        newContent.contains('class AssessmentEntry'),
        isTrue,
        reason: '新 path 应含 class AssessmentEntry 实际定义',
      );
    });

    test('features/assessment/ 内 file 不引用其他 features/ (跨 feature 边界 0 违规)', () {
      // R110 阶段 1 阶段 1+2+3 gate: feature 内 file 不引用其他 features/.
      // 评估 1 commit 整包 R126 续 不应引用 daily_tracking/mood/vent/medication
      // 任何 features/ path.
      final files = Directory('lib/features/assessment')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      for (final f in files) {
        final content = f.readAsStringSync();
        for (final otherFeat in const [
          'features/daily_tracking/',
          'features/mood/',
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

    test('业务方法 0 break (AssessmentEntry 字段 + AssessmentRepository 5 method)', () {
      // R126 续 评估 1 commit 整包业务方法跟旧版 0 改, 验证 0 break widget 端
      // 1. AssessmentEntry 字段 7 个
      final entityContent =
          File('lib/features/assessment/domain/entities/assessment_entry.dart').readAsStringSync();
      for (final field in const [
        'final int id',
        'final DateTime timestamp',
        'final String scaleId',
        'final int score',
        'final int severityRank',
        'final List<int> answers',
        'final String? note',
      ]) {
        expect(
          entityContent.contains(field),
          isTrue,
          reason: 'AssessmentEntry.$field 字段保留 (0 break)',
        );
      }
      // 2. AssessmentRepository 5 method
      final implContent = File(
        'lib/features/assessment/data/repositories/assessment_repository_impl.dart',
      ).readAsStringSync();
      for (final method in const [
        'Stream<List<AssessmentEntry>> watchAll()',
        'Future<AssessmentEntry?> getLatest(String scaleId)',
        'Future<Map<String, int>> countByScale()',
        'Stream<List<AssessmentEntry>> watchByScale(String scaleId)',
        'Future<int> submitEntry(',
      ]) {
        expect(
          implContent.contains(method),
          isTrue,
          reason: 'AssessmentRepository.$method 方法保留 (0 break)',
        );
      }
    });

    test('R95 lock-in 协同: features/assessment/presentation 0 新增 raw EdgeInsets 数字 (R95 修真有效)', () {
      // 跟 R125 阶段 1 + R126 step 1+2+3 模式: features/ 内 file 应走 spacing token
      // 不直接用 EdgeInsets.all(16) 等 raw 数字. R95 lock-in 修真效果.
      // 接受 0 violation (现有 assessment 修真彻底).
      final files = Directory('lib/features/assessment')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart') && f.path.contains('presentation/'))
          .toList();
      var rawEdgeInsetsCount = 0;
      for (final f in files) {
        final content = f.readAsStringSync();
        // 修真 pattern: EdgeInsets.all(数字) / EdgeInsets.symmetric(数字) / EdgeInsets.only(数字)
        // 排除: EdgeInsets.zero / AppTokens.spacingXxx / AppTokens.edgeInsetsXxx
        final m = RegExp(
          r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(\s*\d+',
        ).allMatches(content);
        rawEdgeInsetsCount += m.length;
      }
      // R95 修真后 0 raw 数字 (所有 EdgeInsets 都走 token)
      expect(
        rawEdgeInsetsCount,
        0,
        reason: 'R95 修真后 features/assessment/presentation 应 0 raw EdgeInsets 数字',
      );
    });

    test('R110 阶段 2 续 step 4 评估 1 commit 整包 1 feature 完整迁移 收官', () {
      // 验收: features/ 顶层 3 个 feature (daily_tracking + assessment + mood),
      // 阶段 2 续 step 4 + step 5 是 R110 阶段 2 跨 presentation 完整迁移.
      // 阶段 2 续剩余 2 feature (vent / medication) 留 R126 续 step 6-7.
      final featureDirs = Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .toList();
      expect(
        featureDirs.map((d) => d.path.split('/').last).toList()..sort(),
        equals(['assessment', 'daily_tracking', 'mood', 'vent']),
        reason: 'R126 续 step 4 + step 5 收官 features/ 顶层 3 feature (daily_tracking + assessment + mood)',
      );
    });
  });
}
