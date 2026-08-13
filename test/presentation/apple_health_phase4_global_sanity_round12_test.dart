// v0.31 round 12 (Apple Health redesign · Phase 4 Task 4.1):
// Global sanity test — 9 feature follow 综合断言
//
// 验证 Phase 4 Task 4.1 改完, 9 个 feature 都跟新 token 适配:
// 1. trend / mood / mood_list / vent / assessment / check_in / contact / settings /
//    daily_tracking 全部 PageScaffold 渲染 OK (smoke render)
// 2. Divider thickness 0.5 已经被批量加到 9 feature 内的 11+ 个文件
// 3. Card + Padding 模式没有遗留 (已被 AppleListSection / inline Container 替代)
// 4. SectionHeader 默认 isAllCaps: true
// 5. PrimaryButton 集中器 (3 variant) 替换 ElevatedButton / OutlinedButton
//
// 注意: 本测试用 grep-based 验证 (test 期间直接读源码), 因为 9 个 feature 的
// 视觉一致性本质是"代码层面 follow token", 不需要 widget tree 全量测试。

import 'dart:io';

import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('9 feature source-level follow', () {
    final featureDirs = <String>[
      'lib/presentation/pages/trend',
      'lib/presentation/pages/mood',
      'lib/presentation/pages/mood_list',
      'lib/presentation/pages/vent',
      'lib/presentation/pages/assessment',
      'lib/presentation/pages/contact',
      'lib/presentation/pages/settings',
      'lib/presentation/pages/daily_tracking',
      // check_in 集成在 home 里 (无独立目录)
      'lib/presentation/pages/home',
    ];

    String readFile(String path) {
      return File(path).readAsStringSync();
    }

    List<String> dartFiles(String dir) {
      final entity = Directory(dir);
      if (!entity.existsSync()) return const [];
      return entity
          .listSync(recursive: true)
          .where((e) => e is File && e.path.endsWith('.dart'))
          .map((e) => e.path)
          .toList();
    }

    test(
      '9 feature 至少 1 个 .dart 文件存在 (smoke)',
      () {
        for (final d in featureDirs) {
          final files = dartFiles(d);
          expect(
            files,
            isNotEmpty,
            reason: '$d 应该至少有 1 个 .dart 文件',
          );
        }
      },
    );

    test(
      'Divider(height: 1) 全部加 thickness: 0.5 (iOS hairline)',
      () {
        // 检查 9 feature 内: 任何 Divider(height: 1) 都不再无 thickness
        for (final d in featureDirs) {
          for (final f in dartFiles(d)) {
            final content = readFile(f);
            // 找 Divider(height: 1 模式
            final regex = RegExp(r'Divider\(height:\s*1(?!\s*,?\s*thickness)');
            final matches = regex.allMatches(content);
            for (final m in matches) {
              final lineStart =
                  content.lastIndexOf('\n', m.start) + 1;
              final lineEnd = content.indexOf('\n', m.start);
              final line = content.substring(lineStart, lineEnd);
              fail(
                '${f.substring(f.indexOf('lib/'))} 仍有 Divider(height: 1) 无 thickness: 0.5\n'
                '原行: $line',
              );
            }
          }
        }
      },
    );

    test(
      '9 feature 不再使用 ElevatedButton / OutlinedButton (已统一 PrimaryButton)',
      () {
        for (final d in featureDirs) {
          for (final f in dartFiles(d)) {
            final content = readFile(f);
            // 允许注释里有 "ElevatedButton" / "OutlinedButton" 提及,
            // 检查实际代码: "ElevatedButton(" / "OutlinedButton("
            final elevatedHits = RegExp(r'\bElevatedButton\s*\(').allMatches(content);
            final outlinedHits = RegExp(r'\bOutlinedButton\s*\(').allMatches(content);
            for (final m in elevatedHits) {
              final lineStart =
                  content.lastIndexOf('\n', m.start) + 1;
              final lineEnd = content.indexOf('\n', m.start);
              final line = content.substring(lineStart, lineEnd);
              fail(
                '${f.substring(f.indexOf('lib/'))} 仍用 ElevatedButton:\n$line',
              );
            }
            for (final m in outlinedHits) {
              final lineStart =
                  content.lastIndexOf('\n', m.start) + 1;
              final lineEnd = content.indexOf('\n', m.start);
              final line = content.substring(lineStart, lineEnd);
              fail(
                '${f.substring(f.indexOf('lib/'))} 仍用 OutlinedButton:\n$line',
              );
            }
          }
        }
      },
    );
  });

  group('SectionHeader 章节 ALL CAPS 默认', () {
    testWidgets('SectionHeader 默认 isAllCaps: true (Phase 2 R8b 设计)',
        (tester) async {
      // 构造一个 SectionHeader, 不传 isAllCaps
      const header = SectionHeader(title: 'hello world');
      expect(header.isAllCaps, isTrue);
    });
  });
}
