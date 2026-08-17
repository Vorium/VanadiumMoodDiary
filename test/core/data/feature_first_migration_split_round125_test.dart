// v1.1.0+171 R125 (R110 feature-first 阶段 1) — feature-first 迁移
// 样板验证: daily_tracking/anxiety_agitation 1 子表端到端
//
// Goal: 验证 R110 阶段 1 样板迁移设计 — 1 子表 5 file 端到端 (table + mapper
// + repo_impl + entity + abstract), 旧路径 re-export 兼容, 跨 feature
// import 边界 0 违规。
//
// 验证 4 类:
//   1. features/daily_tracking/ 目录结构 (data/domain/presentation 3 子目录)
//   2. 5 file 端到端 (table/mapper/repo_impl/entity/abstract) 全部存在
//   3. 旧路径 re-export 兼容 (现有用户 import 旧路径仍 work)
//   4. 跨 feature import 边界 0 违规 (features/daily_tracking 不 import 其他 feature)

import 'dart:io';

import 'package:chroniccare/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/repositories/anxiety_agitation_repository.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/anxiety_agitation_mapper.dart';
import 'package:chroniccare/features/daily_tracking/data/tables/anxiety_agitation_entries.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/anxiety_agitation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const featuresPath = 'lib/features';
  const featurePath = 'lib/features/daily_tracking';
  const newEntityPath =
      'lib/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart';
  const newRepoPath =
      'lib/features/daily_tracking/domain/repositories/anxiety_agitation_repository.dart';
  const newRepoImplPath =
      'lib/features/daily_tracking/data/repositories/anxiety_agitation_repository_impl.dart';
  const newTablePath =
      'lib/features/daily_tracking/data/tables/anxiety_agitation_entries.dart';
  const newMapperPath =
      'lib/features/daily_tracking/data/mappers/anxiety_agitation_mapper.dart';
  const oldEntityPath = 'lib/domain/entities/anxiety_agitation_entry.dart';
  const oldRepoPath = 'lib/domain/repositories/anxiety_agitation_repository.dart';

  group('R125 阶段 1 — feature 目录结构 (data/domain/presentation 3 子目录)', () {
    test('features/ 顶层目录存在', () {
      expect(Directory(featuresPath).existsSync(), isTrue,
          reason: 'R110 阶段 1 应有 lib/features/ 顶层目录');
    });

    test('daily_tracking feature 3 子目录 (data/domain/presentation) 全在', () {
      for (final sub in ['data', 'domain', 'presentation']) {
        expect(
          Directory('$featurePath/$sub').existsSync(),
          isTrue,
          reason: 'R110 阶段 1 必过: daily_tracking/$sub/ 子目录',
        );
      }
    });
  });

  group('R125 阶段 1 — 5 file 端到端 (table/mapper/repo_impl/entity/abstract)', () {
    test('anxiety_agitation table (drift) 在 features/daily_tracking/data/tables/', () {
      expect(File(newTablePath).existsSync(), isTrue,
          reason: 'drift table 迁到 features/daily_tracking/data/tables/');
      final content = File(newTablePath).readAsStringSync();
      expect(content.contains('class AnxietyAgitationEntries extends Table'),
          isTrue, reason: 'drift table class 完整');
    });

    test('anxiety_agitation mapper (R125 阶段 1 新增) 在 features/daily_tracking/data/mappers/', () {
      expect(File(newMapperPath).existsSync(), isTrue,
          reason: 'mapper (R125 阶段 1 新增, R110 阶段 2 抽 mapper 模式)');
      final content = File(newMapperPath).readAsStringSync();
      expect(
        content.contains('anxietyAgitationRowToEntity'),
        isTrue,
        reason: 'mapper 公开 row→entity 翻译 function',
      );
    });

    test('anxiety_agitation repository_impl 迁到 features/daily_tracking/data/repositories/', () {
      expect(File(newRepoImplPath).existsSync(), isTrue,
          reason: 'repository_impl 迁到 features/daily_tracking/data/repositories/');
    });

    test('anxiety_agitation entity (domain) 迁到 features/daily_tracking/domain/entities/', () {
      expect(File(newEntityPath).existsSync(), isTrue,
          reason: 'entity 迁到 features/daily_tracking/domain/entities/');
      final content = File(newEntityPath).readAsStringSync();
      expect(content.contains('class AnxietyAgitationEntryEntity'), isTrue,
          reason: 'entity class 完整');
    });

    test('anxiety_agitation repository abstract 迁到 features/daily_tracking/domain/repositories/', () {
      expect(File(newRepoPath).existsSync(), isTrue,
          reason: 'abstract interface 迁到 features/daily_tracking/domain/repositories/');
      final content = File(newRepoPath).readAsStringSync();
      expect(content.contains('abstract class AnxietyAgitationRepository'), isTrue,
          reason: 'abstract class 完整');
    });
  });

  group('R125 阶段 1 — 旧路径 re-export 兼容 (现有用户 0 改动)', () {
    test('旧 entity 路径 lib/domain/entities/anxiety_agitation_entry.dart 是 re-export', () {
      final content = File(oldEntityPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart'"),
        isTrue,
        reason: '旧路径保留为 re-export 兼容现有用户',
      );
    });

    test('旧 abstract 路径 lib/domain/repositories/anxiety_agitation_repository.dart 是 re-export', () {
      final content = File(oldRepoPath).readAsStringSync();
      expect(
        content.contains("export 'package:chroniccare/features/daily_tracking/domain/repositories/anxiety_agitation_repository.dart'"),
        isTrue,
        reason: '旧 abstract 路径保留为 re-export 兼容现有用户',
      );
    });

    test('旧路径 import 仍 work (现有用户 0 改动)', () {
      // 旧路径 import 的 AnxietyAgitationEntryEntity 跟新路径 import
      // 应该是同一 class (re-export 机制)
      final oldEntity = File(oldEntityPath)
          .readAsStringSync()
          .contains('show AnxietyAgitationEntryEntity');
      final newEntity = File(newEntityPath)
          .readAsStringSync()
          .contains('class AnxietyAgitationEntryEntity');
      expect(oldEntity, isTrue,
          reason: '旧路径 export AnxietyAgitationEntryEntity');
      expect(newEntity, isTrue,
          reason: '新路径定义 AnxietyAgitationEntryEntity');
    });
  });

  group('R125 阶段 1 — 跨 feature import 边界 0 违规', () {
    test('features/daily_tracking/ 内 file 不引用其他 feature', () {
      // 阶段 1 gate: 跨 feature 共享走 core/, feature 内不能 import 其他 feature
      final featureDir = Directory(featurePath);
      final violations = <String>[];
      for (final f in featureDir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final content = f.readAsStringSync();
        final importRegex = RegExp(
          r"import\s+'package:chroniccare/features/(\w+)/",
        );
        for (final m in importRegex.allMatches(content)) {
          final imported = m.group(1);
          if (imported != 'daily_tracking') {
            violations.add(
                '${f.path}: 跨 feature import $imported');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'R110 阶段 1 gate: feature 内不能 import 其他 feature');
    });

    test('features/daily_tracking/ 内 file 不引用 core/data/database/tables/ (drift 共享限制)', () {
      // drift table 必须在同 database 编译, 阶段 1 仍通过旧路径访问
      // app_database (R110 阶段 3 拆 workspace 时跨包共享 challenge)
      // 现阶段 0 阶段 1 内 file 直接引用 core/data/database/tables/
      final featureDir = Directory(featurePath);
      final violations = <String>[];
      for (final f in featureDir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        final content = f.readAsStringSync();
        if (content.contains(
            "import 'package:chroniccare/core/data/database/tables/")) {
          violations.add(
              '${f.path}: 直接引用 core/data/database/tables/ '
              '(R110 阶段 1: feature 内应该用 features/{name}/data/tables/ 引用)');
        }
      }
      expect(violations, isEmpty,
          reason: 'R110 阶段 1 gate: feature 不直接引用 core/data/database/tables/');
    });
  });

  group('R125 阶段 1 — 新旧路径 import 等价 (编译验证)', () {
    test('新旧 entity 路径 import 同一 class', () {
      // 旧路径: lib/domain/entities/anxiety_agitation_entry.dart (re-export)
      // 新路径: lib/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart
      // 两者 import 同一 AnxietyAgitationEntryEntity
      // 验证: 旧路径 import 编译通过 (跟新路径同一 class)
      final oldEntity = AnxietyAgitationEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 17),
        anxietyScore: 3,
        agitationScore: 2,
      );
      expect(oldEntity.id, 1);
      expect(oldEntity.anxietyScore, 3);
      expect(oldEntity.agitationScore, 2);
    });
  });
}
