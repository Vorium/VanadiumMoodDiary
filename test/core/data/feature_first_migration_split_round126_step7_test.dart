// v1.1.0+179 R126 续 step 7 (R110 feature-first 阶段 2 续 step 7) —
// medication 完整迁移验证 (R110 阶段 2 续 4 feature 最后 1 个, 4/4 = 100% 收官)
//
// Goal: 验证 R110 阶段 2 续 step 7 — medication 1 feature 完整迁移 1 commit
// 推完。R126 续 step 6 vent 走"1 feature 19 file 端到端"模式, 本批 medication
// 走"1 feature 39 file 端到端"模式 (含 presentation 28 file + medication_notifier
// 跨 notification + medication_report_pdf 跨 PDF 特殊排版).
//
// 验证 4 类:
//   1. features/medication/ 目录结构 (data/domain/presentation 3 子目录)
//   2. 39 file 端到端 (4 domain + 7 data + 28 presentation) 全部存在
//   3. 39 旧 path 全部 re-export (1 行 export 新 path)
//   4. 跨 feature import 边界 0 违规 (features/medication 不引用其他 features/)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R126 续 step 7 medication 1 commit 整包 验证', () {
    test('features/medication/ 目录结构 3 子目录 (data/domain/presentation) 全在', () {
      for (final sub in const [
        'data',
        'domain',
        'presentation',
      ]) {
        final dir = Directory('lib/features/medication/$sub');
        expect(dir.existsSync(), isTrue, reason: '$sub 子目录应存在');
      }
    });

    test('medication 4 domain file 端到端 (3 entity + 1 abstract) 全部存在', () {
      const expected = <String>[
        'lib/features/medication/domain/entities/medication_draft.dart',
        'lib/features/medication/domain/entities/medication_entity.dart',
        'lib/features/medication/domain/entities/medication_form.dart',
        'lib/features/medication/domain/repositories/medication_repository.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('medication 7 data file 端到端 (1 impl + 2 mapper + 1 table + 3 service) 全部存在', () {
      const expected = <String>[
        'lib/features/medication/data/repositories/medication_repository_impl.dart',
        'lib/features/medication/data/mappers/medication_mapper.dart',
        'lib/features/medication/data/mappers/medication_times.dart',
        'lib/features/medication/data/tables/medications.dart',
        'lib/features/medication/data/services/medication_notifier.dart',
        'lib/features/medication/data/services/medication_report_pdf.dart',
        'lib/features/medication/data/services/medication_report_pdf_layout.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('medication 28 presentation file 端到端 (4 page + 3 sub-page + 21 widget) 全部存在', () {
      // 实际 4 page (medication_page + medication_detail_page + medication_calendar_page + add_medication_page)
      // + 3 sub-page (add_medication_submit_flow + refill_manage_page + today_med_schedule)
      // + 21 widget (跟 grep 28 - 4 - 3 = 21 算)
      const expected = <String>[
        // 4 page
        'lib/features/medication/presentation/pages/medication/medication_page.dart',
        'lib/features/medication/presentation/pages/medication/medication_detail_page.dart',
        'lib/features/medication/presentation/pages/medication/medication_calendar_page.dart',
        'lib/features/medication/presentation/pages/medication/add_medication_page.dart',
        // 3 sub-page
        'lib/features/medication/presentation/pages/medication/add_medication_submit_flow.dart',
        'lib/features/medication/presentation/pages/medication/refill_manage_page.dart',
        'lib/features/medication/presentation/pages/medication/today_med_schedule.dart',
        // 21 widget
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_form_shared.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step1_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step2_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step3_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step_footer.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step_indicator.dart',
        'lib/features/medication/presentation/pages/medication/widgets/choose_window_dialog.dart',
        'lib/features/medication/presentation/pages/medication/widgets/edit_medication_dialog.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_day_detail.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_grid.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_legend.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_confirm_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_empty_state.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_empty_state_cards.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_list_cell.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_list_view.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_pill_icon.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_slot_entry_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medications_list_widget.dart',
        'lib/features/medication/presentation/pages/medication/widgets/refill_days_dialog.dart',
      ];
      for (final path in expected) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('39 file 端到端 全部存在 (4 domain + 7 data + 28 presentation)', () {
      // 跨域引用保持旧 path: domain/entities/check_in_entity (跨 check_in, 留 core/)
      // + domain/entities/dosage_unit + domain/entities/hour_minute (跨 logic 留 core/)
      // + domain/logic/medication_page_stats_calculator + domain/logic/medication_slot_calculator
      // (跨 logic 留 core/) + core/shared/formatters (跨层 留 core) + notification_payload
      // (跨 notification 留 core) + reminder_dispatcher (跨 notification 留 core).
      final allFiles = <String>[
        // 4 domain
        'lib/features/medication/domain/entities/medication_draft.dart',
        'lib/features/medication/domain/entities/medication_entity.dart',
        'lib/features/medication/domain/entities/medication_form.dart',
        'lib/features/medication/domain/repositories/medication_repository.dart',
        // 7 data
        'lib/features/medication/data/repositories/medication_repository_impl.dart',
        'lib/features/medication/data/mappers/medication_mapper.dart',
        'lib/features/medication/data/mappers/medication_times.dart',
        'lib/features/medication/data/tables/medications.dart',
        'lib/features/medication/data/services/medication_notifier.dart',
        'lib/features/medication/data/services/medication_report_pdf.dart',
        'lib/features/medication/data/services/medication_report_pdf_layout.dart',
        // 28 presentation
        'lib/features/medication/presentation/pages/medication/medication_page.dart',
        'lib/features/medication/presentation/pages/medication/medication_detail_page.dart',
        'lib/features/medication/presentation/pages/medication/medication_calendar_page.dart',
        'lib/features/medication/presentation/pages/medication/add_medication_page.dart',
        'lib/features/medication/presentation/pages/medication/add_medication_submit_flow.dart',
        'lib/features/medication/presentation/pages/medication/refill_manage_page.dart',
        'lib/features/medication/presentation/pages/medication/today_med_schedule.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_form_shared.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step1_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step2_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step3_form.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step_footer.dart',
        'lib/features/medication/presentation/pages/medication/widgets/add_medication_step_indicator.dart',
        'lib/features/medication/presentation/pages/medication/widgets/choose_window_dialog.dart',
        'lib/features/medication/presentation/pages/medication/widgets/edit_medication_dialog.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_day_detail.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_grid.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_calendar_legend.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_confirm_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_empty_state.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_empty_state_cards.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_list_cell.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_list_view.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_pill_icon.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medication_slot_entry_row.dart',
        'lib/features/medication/presentation/pages/medication/widgets/medications_list_widget.dart',
        'lib/features/medication/presentation/pages/medication/widgets/refill_days_dialog.dart',
      ];
      expect(allFiles.length, 39, reason: 'medication 39 file 端到端');
      for (final path in allFiles) {
        expect(File(path).existsSync(), isTrue, reason: '$path 应存在');
      }
    });

    test('39 旧 path 全部 re-export (1 行 export 新 path)', () {
      // 跟 R125 阶段 1 + R126 续 step 4/5/6 模式: 旧 file body 改 1 行
      // export 新 path, 现有用户 import 旧 path 仍 work (re-export 机制).
      const oldPaths = <String>[
        // 4 domain
        'lib/domain/entities/medication_draft.dart',
        'lib/domain/entities/medication_entity.dart',
        'lib/domain/entities/medication_form.dart',
        'lib/domain/repositories/medication_repository.dart',
        // 7 data
        'lib/core/data/database/tables/medication/medications.dart',
        'lib/core/data/database/mappers/medication/medication_mapper.dart',
        'lib/core/data/database/mappers/medication/medication_times.dart',
        'lib/core/data/repositories/medication/medication_repository_impl.dart',
        'lib/core/data/services/medication_notifier.dart',
        'lib/core/data/services/medication_report_pdf.dart',
        'lib/core/data/services/medication_report_pdf_layout.dart',
        // 28 presentation
        'lib/presentation/pages/medication/medication_page.dart',
        'lib/presentation/pages/medication/medication_detail_page.dart',
        'lib/presentation/pages/medication/medication_calendar_page.dart',
        'lib/presentation/pages/medication/add_medication_page.dart',
        'lib/presentation/pages/medication/add_medication_submit_flow.dart',
        'lib/presentation/pages/medication/refill_manage_page.dart',
        'lib/presentation/pages/medication/today_med_schedule.dart',
        'lib/presentation/pages/medication/widgets/add_medication_form_shared.dart',
        'lib/presentation/pages/medication/widgets/add_medication_step1_form.dart',
        'lib/presentation/pages/medication/widgets/add_medication_step2_form.dart',
        'lib/presentation/pages/medication/widgets/add_medication_step3_form.dart',
        'lib/presentation/pages/medication/widgets/add_medication_step_footer.dart',
        'lib/presentation/pages/medication/widgets/add_medication_step_indicator.dart',
        'lib/presentation/pages/medication/widgets/choose_window_dialog.dart',
        'lib/presentation/pages/medication/widgets/edit_medication_dialog.dart',
        'lib/presentation/pages/medication/widgets/medication_calendar_day_detail.dart',
        'lib/presentation/pages/medication/widgets/medication_calendar_grid.dart',
        'lib/presentation/pages/medication/widgets/medication_calendar_legend.dart',
        'lib/presentation/pages/medication/widgets/medication_confirm_row.dart',
        'lib/presentation/pages/medication/widgets/medication_empty_state.dart',
        'lib/presentation/pages/medication/widgets/medication_empty_state_cards.dart',
        'lib/presentation/pages/medication/widgets/medication_list_cell.dart',
        'lib/presentation/pages/medication/widgets/medication_list_view.dart',
        'lib/presentation/pages/medication/widgets/medication_pill_icon.dart',
        'lib/presentation/pages/medication/widgets/medication_row.dart',
        'lib/presentation/pages/medication/widgets/medication_slot_entry_row.dart',
        'lib/presentation/pages/medication/widgets/medications_list_widget.dart',
        'lib/presentation/pages/medication/widgets/refill_days_dialog.dart',
      ];
      for (final path in oldPaths) {
        final content = File(path).readAsStringSync();
        // 旧 file 应是 re-export 模式 (1 行 export + library 声明 + 注释)
        expect(
          content.contains("export 'package:chroniccare/features/medication/"),
          isTrue,
          reason: '$path 应 re-export 新 features/medication/ path',
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
      // 抽样: MedicationEntity 来自旧 path 应跟新 path 是同 class
      final oldContent = File('lib/domain/entities/medication_entity.dart').readAsStringSync();
      final newContent =
          File('lib/features/medication/domain/entities/medication_entity.dart').readAsStringSync();
      // 旧 path 应 1 行 export 新 path
      expect(
        oldContent.contains("export 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';"),
        isTrue,
        reason: '旧 path 应 1 行 export 新 path',
      );
      // 新 path 应含 class MedicationEntity { ... }
      expect(
        newContent.contains('class MedicationEntity'),
        isTrue,
        reason: '新 path 应含 class MedicationEntity 实际定义',
      );
    });

    test('features/medication/ 内 file 不引用其他 features/ (跨 feature 边界 0 违规)', () {
      // R110 阶段 1+2 gate: feature 内 file 不引用其他 features/.
      // medication 1 commit 整包 R126 续 step 7 不应引用 daily_tracking/assessment/mood/vent
      // 任何 features/ path.
      final files = Directory('lib/features/medication')
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
          'features/vent/',
        ]) {
          expect(
            content.contains(otherFeat),
            isFalse,
            reason: '${f.path} 不应引用 $otherFeat (跨 feature 边界违规)',
          );
        }
      }
    });

    test('业务方法 0 break (MedicationEntity 13 字段 + MedicationRepository 7 method)', () {
      // R126 续 step 7 medication 1 commit 整包业务方法跟旧版 0 改, 验证 0 break widget 端
      // 实际 13 字段 (id / name / dosage / dosageUnit / times / startDate / endDate / isActive /
      // refillAt / refillReminderDays / form / colorIndex / notes)
      final entityContent =
          File('lib/features/medication/domain/entities/medication_entity.dart').readAsStringSync();
      for (final field in const [
        'final int id',
        'final String name',
        'final double dosage',
        'final DosageUnit dosageUnit',
        'final List<HourMinute> times',
        'final DateTime startDate',
        'final DateTime? endDate',
        'final bool isActive',
        'final DateTime? refillAt',
        'final int refillReminderDays',
        'final MedicationForm form',
        'final int colorIndex',
        'final String? notes',
      ]) {
        expect(
          entityContent.contains(field),
          isTrue,
          reason: 'MedicationEntity.$field 字段保留 (0 break)',
        );
      }
      // MedicationRepository 公开方法 7 个 (watchAll / watchAllIncludingInactive / add / update / setActive / delete / updateRefill)
      final abstractContent =
          File('lib/features/medication/domain/repositories/medication_repository.dart').readAsStringSync();
      for (final method in const [
        'Stream<List<MedicationEntity>> watchAll()',
        'Stream<List<MedicationEntity>> watchAllIncludingInactive()',
        'Future<int> add(MedicationDraft draft)',
        'Future<bool> update(MedicationEntity medication)',
        'Future<bool> setActive({',
        'Future<int> delete(int id)',
        'Future<bool> updateRefill({',
      ]) {
        expect(
          abstractContent.contains(method),
          isTrue,
          reason: 'MedicationRepository.$method 方法保留 (0 break)',
        );
      }
    });

    test('medication_notifier 公开 API 完整 (跟 notification_service 桥)', () {
      // medication_notifier 跨 notification_service + reminder_dispatcher (留 core/),
      // R126 续 step 7 medication 1 commit 整包迁 features/medication/, 公开 API 完整.
      final notifierContent =
          File('lib/features/medication/data/services/medication_notifier.dart').readAsStringSync();
      expect(
        notifierContent.contains('class MedicationNotifier'),
        isTrue,
        reason: 'MedicationNotifier class 保留 (跨 notification_service 桥)',
      );
    });

    test('R95 lock-in 协同: features/medication/presentation ≤ 2 raw EdgeInsets 数字 (R95 修真 baseline)', () {
      // 跟 R126 续 step 4/5/6 模式: features/ 内 file 应走 spacing token
      // 不直接用 EdgeInsets.all(16) 等 raw 数字. R95 lock-in 修真效果.
      // R95 修真 baseline 漏修真 medication_calendar_grid (1 处 EdgeInsets.all(1)) +
      // add_medication_step3_form (1 处 EdgeInsets.all(3)) 2 处, 历史 baseline 已知,
      // 留 R31+ 跨期修真, 不在本批 R126 续 step 7 范围. 因此接受 ≤ 2 raw.
      final files = Directory('lib/features/medication')
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
      // R95 修真 baseline 接受 ≤ 2 (medication_calendar_grid + add_medication_step3_form 已知 2 处)
      expect(
        rawEdgeInsetsCount,
        lessThanOrEqualTo(2),
        reason: 'R95 修真 baseline 接受 ≤ 2 raw EdgeInsets 数字 (medication_calendar_grid + add_medication_step3_form 已知 2 处)',
      );
    });

    test('R110 阶段 2 续 step 7 medication 1 commit 整包 1 feature 完整迁移 收官', () {
      // 验收: features/ 顶层 5 个 feature (daily_tracking + assessment + mood + vent + medication),
      // 阶段 2 续 step 4-7 是 R110 阶段 2 跨 presentation 完整迁移 4 feature (评估 / 心情 / 树洞 / 用药).
      // 阶段 2 续 4/4 = 100% 收官, 下一站 R127 阶段 3 pub workspace 3 package 拆分.
      final featureDirs = Directory('lib/features')
          .listSync()
          .whereType<Directory>()
          .toList();
      expect(
        featureDirs.map((d) => d.path.split('/').last).toList()..sort(),
        equals(['assessment', 'daily_tracking', 'medication', 'mood', 'vent']),
        reason: 'R126 续 step 4-7 收官 features/ 顶层 5 feature (daily_tracking + assessment + medication + mood + vent)',
      );
    });
  });
}
