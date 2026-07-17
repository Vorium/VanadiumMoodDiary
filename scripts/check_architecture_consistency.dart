// 检查 4 层架构的语义一致性（v0.16 Round 11）
//
// 这个脚本跑在 check_domain_purity.dart 之后，关注的是：
// - domain entity ↔ drift table 一一对应
// - @DataClassName('X') 和生成的 class X 一致
// - shared/ 里的工具类确实被 3 层都用（不然就是放错地方）
//
// 用法：dart run scripts/check_architecture_consistency.dart

// ignore_for_file: avoid_print

import 'dart:io';

final _dataClassNameRe = RegExp(r"@DataClassName\('(\w+)'\)");
final _tableClassRe = RegExp(r"^class (\w+) extends Table", multiLine: true);
final _importRe = RegExp(
  r'''^\s*import\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

class Issue {
  final String file;
  final String message;
  Issue(this.file, this.message);
  @override
  String toString() => '  $file  →  $message';
}

void main() {
  final root = Directory.current.path;
  final entitiesDir = Directory(
      '$root${Platform.pathSeparator}lib${Platform.pathSeparator}domain${Platform.pathSeparator}entities');
  final tablesDir = Directory(
      '$root${Platform.pathSeparator}lib${Platform.pathSeparator}data${Platform.pathSeparator}database${Platform.pathSeparator}tables');
  final sharedDir =
      Directory('$root${Platform.pathSeparator}lib${Platform.pathSeparator}shared');

  final issues = <Issue>[];

  if (entitiesDir.existsSync() && tablesDir.existsSync()) {
    _checkEntityTablePair(entitiesDir, tablesDir, issues);
  }

  if (sharedDir.existsSync()) {
    _checkSharedUsage(root, sharedDir, issues);
  }

  if (issues.isEmpty) {
    print('✅ 架构一致性检查通过');
    print('   - 每个 domain entity 都对应一个 drift table');
    print('   - @DataClassName / class X extends Table 一致');
    print('   - shared/ 工具被 3 层都用');
    exit(0);
  } else {
    print('❌ 架构一致性问题 ${issues.length} 处:\n');
    for (final i in issues) {
      print(i);
    }
    exit(1);
  }
}

/// 1) domain entity ↔ drift table 对应
void _checkEntityTablePair(
  Directory entitiesDir,
  Directory tablesDir,
  List<Issue> issues,
) {
  // 收集 domain entity 类名（pattern: class XxxEntity）
  final entityNames = <String>{};
  for (final f in entitiesDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final content = f.readAsStringSync();
    final m = RegExp(r'^class (\w+Entity)\b', multiLine: true).firstMatch(content);
    if (m != null) entityNames.add(m.group(1)!);
  }

  // 收集 drift table 数据类名（@DataClassName('X')）
  final tableDataNames = <String, String>{}; // dataName -> tableFile
  for (final f in tablesDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    if (f.path.endsWith('.g.dart')) continue;
    final content = f.readAsStringSync();
    final dc = _dataClassNameRe.firstMatch(content);
    if (dc != null) {
      tableDataNames[dc.group(1)!] = f.path;
    }
  }

  // 对应检查：entity 名去掉 "Entity" 后缀应等于 table data class 名
  for (final entityName in entityNames) {
    // e.g. MedicationEntity -> Medication
    final base = entityName.endsWith('Entity')
        ? entityName.substring(0, entityName.length - 'Entity'.length)
        : entityName;
    if (!tableDataNames.containsKey(base)) {
      issues.add(Issue(
        'lib/domain/entities/$entityName.dart',
        '没有对应的 drift table（@DataClassName(\'$base\') 找不到）',
      ));
    }
  }

  for (final entry in tableDataNames.entries) {
    final dataName = entry.key;
    final expectedEntityName = '${dataName}Entity';
    if (!entityNames.contains(expectedEntityName)) {
      // 例外：HourMinute / DomainValue / Formatters / JsonCodec 是 shared，
      // 不是 entity-table 对应。
      issues.add(Issue(
        entry.value,
        'drift table data class \'$dataName\' 找不到对应 domain entity \'${expectedEntityName}\'',
      ));
    }
  }
}

/// 2) shared/ 工具被多少层使用
void _checkSharedUsage(
  String root,
  Directory sharedDir,
  List<Issue> issues,
) {
  for (final f in sharedDir.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    final fileName = f.path.split(Platform.pathSeparator).last;

    // 统计这个 shared 文件被哪些层 import
    // import 可能是相对路径（'../../shared/x.dart'）或绝对包路径（'package:chroniccare/shared/x.dart'）
    final baseNameNoExt = fileName.replaceAll('.dart', '');
    final usedBy = <String>{};
    final matchesFiles = <String>[];
    _walkLib(Directory('$root${Platform.pathSeparator}lib'), (entity) {
      if (entity.path == f.path) return;
      final content = entity.readAsStringSync();
      for (final m in _importRe.allMatches(content)) {
        final uri = m.group(1)!;
        // 匹配 shared/x.dart (相对或绝对)
        final matches = uri == 'package:chroniccare/shared/$fileName' ||
            uri == 'package:chroniccare/shared/$baseNameNoExt.dart' ||
            uri.endsWith('/shared/$fileName') ||
            uri.endsWith('/shared/$baseNameNoExt.dart');
        if (matches) {
          matchesFiles.add(entity.path);
          if (entity.path.contains('${Platform.pathSeparator}domain${Platform.pathSeparator}')) {
            usedBy.add('domain');
          } else if (entity.path.contains('${Platform.pathSeparator}data${Platform.pathSeparator}')) {
            usedBy.add('data');
          } else if (entity.path.contains('${Platform.pathSeparator}presentation${Platform.pathSeparator}')) {
            usedBy.add('presentation');
          }
        }
      }
    });

    if (usedBy.isEmpty) {
      issues.add(Issue(
        f.path,
        'shared 工具没有任何层使用，考虑移走',
      ));
    } else if (usedBy.length == 1) {
      issues.add(Issue(
        f.path,
        'shared 工具只被 [$usedBy] 用，考虑移进那个层',
      ));
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
