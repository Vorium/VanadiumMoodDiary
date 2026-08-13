// v0.31.1 round 8: P0-07 守门员 — 全 lib/ 0 raw IconButton( 走 PressFeedbackIconButton
//
// 背景: R23 round 41 抽 [PressFeedbackIconButton] 集中器 (emil P3-32 "cohesion"),
// R26 round 57 扩 color / size / padding / constraints 替换 17 处 (emil B-11)。
// 但 R108 P1 漏修 7 处 + emil 2026-08-11 P0-C 又补 2 处, 累计 7 处 raw
// IconButton( 散落 lib/。本守门员 grep 拦截回归, 避免新页面继续走 raw。
//
// 排除名单 (集中器自身):
// 1. press_feedback_icon_button.dart — 集中器内部 build 用 IconButton( 2 处
// (page_scaffold.dart:42 默认 leading back button 已在 P0-07b round 9 修)
//
// 验证: 全 lib/ 其它 .dart 文件 grep `IconButton(` 不在 PressFeedback 前,
// 命中数 = 0。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P0-07: 全 lib/ 不应再有 raw IconButton(', () {
    test('lib/ 0 raw IconButton( 漏网 (排除集中器自身)', () async {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue,
          reason: 'lib/ 目录必须存在 (从项目根运行)',);

      // 排除名单 (集中器自身)
      const excludedFiles = <String>{
        'lib/presentation/widgets/press_feedback_icon_button.dart',
      };

      // 负向 lookbehind regex: 'IconButton(' not preceded by 'PressFeedback'
      final rawIconButtonRe = RegExp(r'(?<!PressFeedback)IconButton\(');

      final violations = <String>[];

      await for (final entity
          in libDir.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        // 路径用 \ 分隔符 (Windows), 转成 /
        final normalized = entity.path.replaceAll(r'\', '/');

        if (excludedFiles.contains(normalized)) continue;

        final content = await entity.readAsString();

        // 注释行 / 文档行不算 (避免 /* IconButton( */ 误报)
        for (final lineMatch
            in content.split('\n').asMap().entries.where((e) {
          final line = e.value.trimLeft();
          // 跳过纯注释行 + dartdoc 行
          return !line.startsWith('//') && !line.startsWith('*');
        })) {
          final lineNo = lineMatch.key + 1;
          if (rawIconButtonRe.hasMatch(lineMatch.value)) {
            violations.add(
              '$normalized:$lineNo: ${lineMatch.value.trim()}',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '发现 ${violations.length} 处 raw IconButton( 漏修, '
            '应改用 PressFeedbackIconButton 集中器:\n'
            '${violations.join('\n')}\n\n'
            '排除名单 (已知合规):\n'
            '${excludedFiles.join('\n')}',
      );
    });
  });
}
