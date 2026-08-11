// v0.31.1 round 11 P0-09 (Apple Health P0-1): lib/ 主体 + docs 范围
//   锁 "Apple Health" 字面提及范围, 防止 Apple 5.1.3 used-but-not-declared 抽审
//
// 背景 (audit/2026-08-11-cleanup/07-apple-health.md P0-1):
//   v0.31.0 Apple Health 风格重设计 23 commit 把 "Apple Health" 字面提及 134 处
//   写进 lib/ 50+ 文件 (R1-R13, 主在 `app_typography.dart` / `spring.dart` /
//   `apple_health_tile.dart` / `apple_list_section.dart` / `check_in_button.dart`
//   / `primary_button.dart` / `medication_page.dart` 等)。这些提及**全部**
//   位于 `///` dartdoc 注释或 `//` 单行注释里, 是"设计参考白名单" (类似
//   "Apple Health 风格" / "借鉴 Apple Health" / "参照 Apple Health Medications
//   的剂型分类")。但 grep 工具 (审计脚本 + 人工审查) 可能误判为"功能依赖
//   Apple Health" → Apple Guideline 5.1.3 抽审风险。
//
//  R108 + P0-04 + P0-04b 守门员 (test/fastlane/description_no_health_claim_round108_test.dart
//   + scripts/check_apple_health_claim.py) 只覆盖 5 个 description 文件 +
//   0 个 lib/ + 0 个 docs/, 留下空隙。
//
// 修法 (P0-09, round 11):
//   新增本 lock-in test, 扩 3 类扫描:
//     1) lib/ 主体代码 (import / 字符串 / 函数名 / class 名等非注释代码) 不含
//        "Apple Health" 字面 → 防止 import health_kit 或字符串拼接入 HealthKit
//     2) lib/ 注释中"Apple Health 风格/借鉴/类似/参照" 是设计参考白名单 →
//        必须 ≥ 1 命中 (证明白名单仍存在, 未被回退)
//     3) docs/design/2026-08-10-apple-health-redesign/*.md 是 Apple Health
//        设计 spec 唯一正档, 之外的 docs 路径含 "Apple Health" → fail
//        (防止审计报告 / CHANGELOG / plan.md 等被 Apple 团队误读为功能依赖)
//
// 范围:
//   - 扫描: lib/**/*.dart (按 Dart 注释规则剥除 // + /* */ 后再 grep)
//   - 扫描: docs/**/*.md (markdown 无注释剥离, 直接 grep "Apple Health")
//   - 不扫: scripts/ (守门员自己) + test/ (test 自己可能需要 "Apple Health"
//     关键词, 不构成产品声明) + pubspec.yaml / ios/ (R108 守门员已扫)
//
// 已知例外 (R108 precedent, 已固化为 R108 守门员):
//   - R108 守门员 (scripts/check_apple_health_claim.py + description_no_health_claim_round108_test.dart)
//     不扫 docs/*, 例外是 docs/superpowers/ + docs/audit*/ 文档可提 "Apple Health"
//     (设计意图)。本 lock-in test 同样认可 audit + superpowers 例外。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ===== 关键词 =====
const _kAppleHealth = 'Apple Health';

// 设计参考白名单关键词 (lib/ 注释里允许这些 + "Apple Health" 组合)
const _whitelistPatterns = <String>[
  'Apple Health 风格',
  'Apple Health风格',
  '借鉴 Apple Health',
  '借鉴Apple Health',
  '类似 Apple Health',
  '类似Apple Health',
  '参照 Apple Health',
  '参照Apple Health',
  'Apple Health 设计',
  'Apple Health设计',
  'Apple Health 巨型',
  'Apple Health 大数字',
  'Apple Health 物理',
  'Apple Health 标志性',
  'Apple Health 全程',
  'Apple Health 仪表盘',
  'Apple Health 卡片',
  'Apple Health 群组',
  'Apple Health 巨型 pill',
  'Apple Health 风格彩色',
  'Apple Health "favorites"',
  'Apple Health / iOS',
  'Apple Health (R',
];

// docs 允许的"设计意图"路径 (R108 precedent 扩展)
// 注: 仅 "设计 spec" 类文档允许含 "Apple Health", 包括:
//   - docs/design/<date>/ (按日期分桶的设计 spec, 含 2026-08-10-apple-health-redesign/)
//   - docs/specs/ (持续维护的设计 spec, 2 文件: medication-page-redesign.md
//     + mood-module-adjustment-apple-health.md, 都明确"参照 Apple Health" 作设计源)
const _allowedDocsPrefixes = <String>[
  'docs/design/',
  'docs/specs/',
  'docs/audit/',
  'docs/audit-history/',
  'docs/superpowers/',
];

// docs 允许的具体文件 (CHANGELOG / VERSION_1.0_PLAN 历史提及)
const _allowedDocsFiles = <String>{
  'docs/CHANGELOG.md',
  'docs/VERSION_1.0_PLAN.md',
};

// ===== lib/ 注释剥离 + 计数 helper =====

/// 剥除 // 行注释 + /* */ 块注释, 返回"非注释代码"字符串。
///
/// 简化实现: 对每行找第一个 `//` (不在字符串内做精准判断, 假定测试关键词
/// "Apple Health" 不会出现在 URL/字符串中)。块注释用 `/\*[\s\S]*?\*/`
/// 一次性 strip。
String _stripCommentsForCode(String src) {
  final noBlock = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ');
  final lines = noBlock.split('\n');
  final kept = <String>[];
  for (final line in lines) {
    final idx = line.indexOf('//');
    kept.add(idx < 0 ? line : line.substring(0, idx));
  }
  return kept.join('\n');
}

/// 提取所有 // + /* */ 注释内容, 拼接返回 (用于白名单扫描)。
String _extractComments(String src) {
  final buf = StringBuffer();
  for (final m in RegExp(r'/\*[\s\S]*?\*/').allMatches(src)) {
    buf.write(m.group(0));
    buf.write('\n');
  }
  final noBlock = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), ' ');
  for (final line in noBlock.split('\n')) {
    final idx = line.indexOf('//');
    if (idx >= 0) {
      buf.write(line.substring(idx));
      buf.write('\n');
    }
  }
  return buf.toString();
}

int _countOccurrences(String haystack, String needle) =>
    needle.allMatches(haystack).length;

void main() {
  group('v0.31.1 round 11 P0-09: Apple Health 字面提及 lock-in (Apple 5.1.3 抽审防护)', () {
    // ===== Test 1: lib/ 主体代码 (非注释) 不含 "Apple Health" =====
    test('lib/ 主体代码 (import / 字符串 / 标识符) 不含 "Apple Health" 字面', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ 目录必须存在');

      final violations = <String>[];
      var totalHits = 0;

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll('\\', '/');
        final src = entity.readAsStringSync();
        final code = _stripCommentsForCode(src);
        final hits = _countOccurrences(code, _kAppleHealth);
        if (hits > 0) {
          violations.add('$rel: $hits 命中 (非注释代码)');
          totalHits += hits;
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'lib/ 主体代码含 $_kAppleHealth 字面 (Apple 5.1.3 used-but-not-declared '
            '抽审风险, 注释是设计参考白名单 OK, 但实际 import / 字符串 / 标识符 '
            '必须 0):\n${violations.join('\n')}',
      );
      // verbose: 总命中数 (测试通过时为 0, 失败时供排查)
      expect(
        totalHits,
        0,
        reason: 'lib/ 主体代码 "$_kAppleHealth" 总命中应 = 0',
      );
    });

    // ===== Test 2: lib/ 注释含白名单关键词 (设计参考保留) =====
    test('lib/ 注释含 "Apple Health 风格/借鉴/参照" 等白名单 (设计参考保留)', () {
      // 防回退: 如果未来有人批量删除所有 "Apple Health" 注释提及, 本 test fail
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ 目录必须存在');

      final mentionHits = <String, int>{};
      var totalCommentHits = 0;
      final whitelistHits = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll('\\', '/');
        final src = entity.readAsStringSync();
        final comments = _extractComments(src);
        final allHits = _countOccurrences(comments, _kAppleHealth);
        if (allHits > 0) {
          mentionHits[rel] = allHits;
          totalCommentHits += allHits;
          // 检查是否至少匹配一个白名单 pattern
          for (final pattern in _whitelistPatterns) {
            if (comments.contains(pattern)) {
              whitelistHits.add(rel);
              break;
            }
          }
        }
      }

      expect(
        totalCommentHits,
        greaterThan(0),
        reason: 'lib/ 注释里 "$_kAppleHealth" 总命中应 ≥ 1 (设计参考白名单应保留)。'
            '如果 = 0, 说明有人误删了所有 "Apple Health 风格" 注释, 失去设计参考。',
      );

      // 至少 1 个文件用白名单 pattern (例: "Apple Health 风格")
      // 注: 实际有 50+ 文件命中白名单, 这里只要求 ≥ 1 防止整体回退
      expect(
        whitelistHits.isNotEmpty,
        isTrue,
        reason: '至少 1 个 lib/ 注释应含白名单关键词 (例 "Apple Health 风格" / '
            '"借鉴 Apple Health" / "参照 Apple Health" 等), 当前命中 0 个, '
            '说明 50+ 文件的设计参考注释格式被破坏',
      );
    });

    // ===== Test 3: docs/ 范围 (仅 design spec 允许) =====
    test('docs/design/2026-08-10-apple-health-redesign/ 之外 docs 不含 "Apple Health" 字面', () {
      // 防止审计报告 / CHANGELOG / 其它 spec 被 Apple 团队误读为产品功能依赖
      // 允许的路径:
      //   - docs/design/* (设计 spec, 含 2026-08-10-apple-health-redesign/)
      //   - docs/specs/* (设计 spec, 2 文件参照 Apple Health 作设计源)
      //   - docs/audit*/ (审计报告, 必然提及被审计的工作)
      //   - docs/audit-history*/ (历史审计, R108 precedent)
      //   - docs/superpowers/* (superpowers 报告, R108 precedent)
      //   - docs/CHANGELOG.md (commit history)
      //   - docs/VERSION_1.0_PLAN.md (项目计划)
      final docsDir = Directory('docs');
      if (!docsDir.existsSync()) {
        // docs 目录不存在 → 0 命中 → test vacuously pass
        return;
      }

      bool isAllowed(String relPath) {
        for (final prefix in _allowedDocsPrefixes) {
          if (relPath.startsWith(prefix)) return true;
        }
        if (_allowedDocsFiles.contains(relPath)) return true;
        return false;
      }

      final violations = <String>[];
      var totalHits = 0;
      var scannedFiles = 0;

      for (final entity in docsDir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.md')) continue;
        scannedFiles++;
        final rel = entity.path.replaceAll('\\', '/');
        if (isAllowed(rel)) continue;
        final content = entity.readAsStringSync();
        final hits = _countOccurrences(content, _kAppleHealth);
        if (hits > 0) {
          violations.add('$rel: $hits 命中');
          totalHits += hits;
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'docs/ 路径含 "$_kAppleHealth" 但不在 design spec 白名单:'
            '\n  允许: docs/design/* + docs/specs/* + docs/audit*/ + '
            'docs/audit-history*/ + docs/superpowers/* + docs/CHANGELOG.md + '
            'docs/VERSION_1.0_PLAN.md'
            '\n  违规: ${violations.length} 文件, 总 $totalHits 命中'
            '\n  (审计报告 / 其它 spec 误传 Apple 团队 → 5.1.3 抽审风险)'
            '\n${violations.take(20).join('\n')}'
            '${violations.length > 20 ? '\n  ... 还有 ${violations.length - 20} 个' : ''}',
      );
      // 扫描统计 (供日志, 通过时也打印)
      // ignore: avoid_print
      print('[P0-09 test 3] docs/ 扫描 $scannedFiles 个 .md 文件, '
          'design spec 之外违规 ${violations.length} 个, 总 $totalHits 命中');
    });
  });
}
