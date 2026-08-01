// 4 层架构综合检查（v0.18 Round 19 — 更新路径至 core/ umbrella 结构）
//
// 跑一次出两份报告：
// 1) 纯度（purity）—— 4 层之间不能跨层引用
//    - domain/  0 flutter / 0 drift / 0 data / 0 presentation
//    - shared/  0 flutter / 0 drift / 0 data / 0 presentation
//    - data/    不依赖 presentation/
//    - 同时检测 package: 绝对路径 和 ../../ 相对路径
// 2) 一致性（consistency）—— 实体和表对应 + shared 使用度
//    - 每个 domain *Entity 都对应一个 drift @DataClassName('X') table
//    - 每个 drift table data class 都对应一个 domain *Entity
//    - shared/ 工具被 ≥2 层用（否则考虑移走）
//
// 用法：dart scripts/check_all.dart
// 退出码：0 = 通过, 1 = 有违规
// 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑即可。

// ignore_for_file: avoid_print

import 'dart:io';

const _purityRules = <String, List<String>>{
  'domain': [
    'package:flutter/',
    'package:drift/',
    'package:chroniccare/core/data/',
    'package:chroniccare/presentation/',
    // v0.27 round 77 (R76-N4 修): 之前不抓 `package:chroniccare/l10n/`,
    // 导致 day_detail.dart / vent_entry_entity.dart 间接 import Flutter (软
    // 违规) 持续, R75 修 1/3 file 是 reviewer 手工扫。R77 加守门, 新加
    // l10n import 立即 CI fail。
    'package:chroniccare/l10n/',
  ],
  'shared': [
    'package:flutter/',
    'package:drift/',
    'package:chroniccare/core/data/',
    'package:chroniccare/presentation/',
  ],
  'data': [
    'package:chroniccare/presentation/',
  ],
  'presentation': <String>[],
};

const _layerDirs = <String, String>{
  'domain': 'domain',
  'shared': 'core/shared',
  'data': 'core/data',
  'presentation': 'presentation',
};

final _importRe = RegExp(
  r'''^\s*import\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final _dataClassNameRe = RegExp(r"@DataClassName\('(\w+)'\)");
final _entityClassRe = RegExp(r'^class (\w+Entity)\b', multiLine: true);

class PurityViolation {
  final String file;
  final int line;
  final String uri;
  final String rule;
  PurityViolation(this.file, this.line, this.uri, this.rule);
  @override
  String toString() => '  $file:$line  →  $uri  ($rule)';
}

class ConsistencyIssue {
  final String file;
  final String message;
  ConsistencyIssue(this.file, this.message);
  @override
  String toString() => '  $file  →  $message';
}

void main() {
  final root = Directory.current.path;
  final purityViolations = _runPurityCheck(root);
  final consistencyIssues = _runConsistencyCheck(root);

  print('=' * 60);
  print('4 层架构综合检查（v0.18 Round 19）');
  print('=' * 60);

  _printPurityReport(purityViolations);
  print('');
  _printConsistencyReport(consistencyIssues);

  final exitCode =
      (purityViolations.isEmpty && consistencyIssues.isEmpty) ? 0 : 1;
  exit(exitCode);
}

// =============================================================================
// Part 1: 4 层架构纯度检查
// =============================================================================

List<PurityViolation> _runPurityCheck(String root) {
  final violations = <PurityViolation>[];
  for (final layer in _layerDirs.keys) {
    final dirPath =
        '$root${Platform.pathSeparator}lib${Platform.pathSeparator}${_layerDirs[layer]}';
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    violations
        .addAll(_scanPurity(dir, _purityRules[layer] ?? const [], layer, root));
  }
  return violations;
}

List<PurityViolation> _scanPurity(
  Directory dir,
  List<String> forbiddenPrefixes,
  String layer,
  String root,
) {
  if (forbiddenPrefixes.isEmpty) return const [];

  final violations = <PurityViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final m = _importRe.firstMatch(line);
      if (m == null) continue;
      final uri = m.group(1)!;
      // 解析 import：包路径 / 相对路径 / dart: 内置
      final resolvedLayer = _resolveImportLayer(uri, entity.path, root);
      for (final forbidden in forbiddenPrefixes) {
        if (_isForbiddenImport(uri, resolvedLayer, forbidden)) {
          violations.add(
            PurityViolation(
              entity.path,
              i + 1,
              uri,
              '[$layer] 不应引用 $forbidden',
            ),
          );
        }
      }
    }
  }
  return violations;
}

/// 把 import 解析成"层归属"：
/// - 'package:chroniccare/data/...' → 'data'
/// - '../../data/...' → 'data' (从 fromFile 解析)
/// - 'package:flutter/...' → 'flutter'
/// - 'package:drift/...' → 'drift'
/// - 'dart:...' / 其他 → 'external'
String _resolveImportLayer(String importUri, String fromFile, String root) {
  if (importUri.startsWith('package:flutter/')) return 'flutter';
  if (importUri.startsWith('package:drift/')) return 'drift';
  if (importUri.startsWith('dart:')) return 'external';

  // 相对路径
  if (importUri.startsWith('package:chroniccare/') ||
      (!importUri.startsWith('package:') && importUri.contains('/'))) {
    String absPath;
    if (importUri.startsWith('package:chroniccare/')) {
      final rel = importUri.substring('package:chroniccare/'.length);
      absPath =
          '$root${Platform.pathSeparator}lib${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
    } else {
      // 相对路径（importUri 用 '/'，先转 Platform 分隔符才能让 _normalizePath 正确处理 ..）
      final fromDir =
          fromFile.substring(0, fromFile.lastIndexOf(Platform.pathSeparator));
      absPath = _normalizePath(
        '$fromDir${Platform.pathSeparator}${importUri.replaceAll('/', Platform.pathSeparator)}',
      );
    }
    // 找层
    for (final layer in _layerDirs.keys) {
      final marker =
          '${Platform.pathSeparator}lib${Platform.pathSeparator}${_layerDirs[layer]}${Platform.pathSeparator}';
      if (absPath.contains(marker)) return layer;
    }
  }
  return 'external';
}

/// 路径规范化：处理 .. 和 .
String _normalizePath(String p) {
  final parts = p.split(Platform.pathSeparator);
  final result = <String>[];
  for (final part in parts) {
    if (part == '..') {
      if (result.isNotEmpty) result.removeLast();
    } else if (part != '.') {
      result.add(part);
    }
  }
  return result.join(Platform.pathSeparator);
}

/// import URI 规范化：Dart 导入路径总是用 '/'，处理 ../ 和 ./
/// 输入: '../../shared/domain_value.dart' → 'shared/domain_value.dart'
String _normalizeImportUri(String uri) {
  final parts = uri.split('/');
  final result = <String>[];
  for (final part in parts) {
    if (part == '..') {
      if (result.isNotEmpty && result.last != '..') result.removeLast();
    } else if (part != '.') {
      result.add(part);
    }
  }
  return result.join('/');
}

/// 判断一个 import 是否违反 [forbidden] 规则
/// - forbidden = 'package:flutter/'  → importUri 以 'package:flutter/' 开头
/// - forbidden = 'package:drift/'   → importUri 以 'package:drift/' 开头
/// - forbidden = 'package:chroniccare/data/'  → importUri 以它开头 OR resolvedLayer == 'data'
/// - forbidden = 'package:chroniccare/presentation/' → 同上
/// - forbidden = 'package:chroniccare/l10n/' → importUri 以它开头 (R77 软违规守门)
bool _isForbiddenImport(
    String importUri, String resolvedLayer, String forbidden,) {
  if (forbidden == 'package:flutter/' || forbidden == 'package:drift/') {
    return importUri.startsWith(forbidden);
  }
  if (forbidden == 'package:chroniccare/data/') {
    return importUri.startsWith(forbidden) || resolvedLayer == 'data';
  }
  if (forbidden == 'package:chroniccare/presentation/') {
    return importUri.startsWith(forbidden) || resolvedLayer == 'presentation';
  }
  // v0.27 round 77 (R76-N4 修): l10n 软违规守门 — domain 间接 import Flutter
  // (通过 l10n → package:flutter/widgets.dart) 不报, R75 修 1/3 file 是
  // reviewer 手工扫, 守门失效。R77 加 l10n 守门, 任何 domain 文件 import
  // `package:chroniccare/l10n/` 立即 CI fail。
  if (forbidden == 'package:chroniccare/l10n/') {
    return importUri.startsWith(forbidden);
  }
  return false;
}

void _printPurityReport(List<PurityViolation> violations) {
  print('--- [1/2] 4 层架构纯度检查 ---');
  if (violations.isEmpty) {
    print('✅ 通过');
    print('   - domain/  0 flutter / 0 drift / 0 data / 0 presentation');
    print('   - shared/  0 flutter / 0 drift / 0 data / 0 presentation');
    print('   - data/    不依赖 presentation/');
    print('   - 同时检测 package: 绝对路径 + ../../ 相对路径');
  } else {
    print('❌ 违规 ${violations.length} 处:\n');
    for (final v in violations) {
      print(v);
    }
    print('\n修复方法：');
    print('  - domain/shared/ 不能 import flutter / drift / data / presentation');
    print('  - data/   不能 import presentation');
    print('  - 放错地方的代码应搬到合适的层');
  }
}

// =============================================================================
// Part 2: 架构语义一致性检查
// =============================================================================

List<ConsistencyIssue> _runConsistencyCheck(String root) {
  final issues = <ConsistencyIssue>[];
  final entitiesDir = Directory(
    '$root${Platform.pathSeparator}lib${Platform.pathSeparator}domain${Platform.pathSeparator}entities',
  );
  final tablesDir = Directory(
    '$root${Platform.pathSeparator}lib${Platform.pathSeparator}core${Platform.pathSeparator}data${Platform.pathSeparator}database${Platform.pathSeparator}tables',
  );
  final sharedDir = Directory(
      '$root${Platform.pathSeparator}lib${Platform.pathSeparator}core${Platform.pathSeparator}shared',);

  if (entitiesDir.existsSync() && tablesDir.existsSync()) {
    _checkEntityTablePair(entitiesDir, tablesDir, issues);
  }
  if (sharedDir.existsSync()) {
    _checkSharedUsage(root, sharedDir, issues);
  }
  return issues;
}

void _checkEntityTablePair(
  Directory entitiesDir,
  Directory tablesDir,
  List<ConsistencyIssue> issues,
) {
  // 收集 domain entity 类名
  final entityNames = <String>{};
  for (final f in entitiesDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final content = f.readAsStringSync();
    final m = _entityClassRe.firstMatch(content);
    if (m != null) entityNames.add(m.group(1)!);
  }

  // 收集 drift table data class 名（@DataClassName('X')）
  final tableDataNames = <String, String>{};
  for (final f in tablesDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart')) continue;
    final content = f.readAsStringSync();
    final dc = _dataClassNameRe.firstMatch(content);
    if (dc != null) {
      tableDataNames[dc.group(1)!] = f.path;
    }
  }

  // entity → table
  for (final entityName in entityNames) {
    final base = entityName.endsWith('Entity')
        ? entityName.substring(0, entityName.length - 'Entity'.length)
        : entityName;
    if (!tableDataNames.containsKey(base)) {
      issues.add(
        ConsistencyIssue(
          'lib/domain/entities/$entityName.dart',
          "没有对应的 drift table（@DataClassName('$base') 找不到）",
        ),
      );
    }
  }
  // table → entity
  for (final entry in tableDataNames.entries) {
    final expected = '${entry.key}Entity';
    if (!entityNames.contains(expected)) {
      issues.add(
        ConsistencyIssue(
          entry.value,
          "drift table data class '${entry.key}' 找不到对应 domain entity '$expected'",
        ),
      );
    }
  }
}

void _checkSharedUsage(
  String root,
  Directory sharedDir,
  List<ConsistencyIssue> issues,
) {
  for (final f in sharedDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final fileName = f.path.split(Platform.pathSeparator).last;
    final baseNameNoExt = fileName.replaceAll('.dart', '');

    final usedBy = <String>{};
    _walkLib(Directory('$root${Platform.pathSeparator}lib'), (entity) {
      if (entity.path == f.path) return;
      final content = entity.readAsStringSync();
      for (final m in _importRe.allMatches(content)) {
        final uri = m.group(1)!;
        // 规范化路径：处理 ../ 和 ./
        final normalized = _normalizeImportUri(uri);
        final matches =
            normalized == 'package:chroniccare/core/shared/$fileName' ||
                normalized ==
                    'package:chroniccare/core/shared/$baseNameNoExt.dart' ||
                normalized.endsWith('core/shared/$fileName') ||
                normalized.endsWith('core/shared/$baseNameNoExt.dart');
        if (matches) {
          if (entity.path.contains(
              '${Platform.pathSeparator}domain${Platform.pathSeparator}',)) {
            usedBy.add('domain');
          } else if (entity.path.contains(
              '${Platform.pathSeparator}data${Platform.pathSeparator}',)) {
            usedBy.add('data');
          } else if (entity.path.contains(
              '${Platform.pathSeparator}presentation${Platform.pathSeparator}',)) {
            usedBy.add('presentation');
          }
        }
      }
    });

    if (usedBy.isEmpty) {
      issues.add(
        ConsistencyIssue(
          f.path,
          'shared 工具没有任何层使用，考虑移走',
        ),
      );
    } else if (usedBy.length == 1) {
      issues.add(
        ConsistencyIssue(
          f.path,
          'shared 工具只被 [$usedBy] 用，考虑移进那个层',
        ),
      );
    }
  }
}

void _walkLib(Directory dir, void Function(File) onFile) {
  for (final e in dir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      onFile(e);
    }
  }
}

void _printConsistencyReport(List<ConsistencyIssue> issues) {
  print('--- [2/2] 架构语义一致性检查 ---');
  if (issues.isEmpty) {
    print('✅ 通过');
    print('   - 每个 domain *Entity 都对应一个 drift table');
    print('   - 每个 drift table data class 都对应一个 domain *Entity');
    print('   - shared/ 工具被 ≥2 层使用');
  } else {
    print('❌ 问题 ${issues.length} 处:\n');
    for (final i in issues) {
      print(i);
    }
  }
}
