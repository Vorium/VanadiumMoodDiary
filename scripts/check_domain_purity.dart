// 验证 4 层架构纯度（v0.16 Round 10 加强版）
//
// 4 层架构的核心约束：
// - domain/  0 flutter / 0 drift / 0 data / 0 presentation
// - shared/  0 flutter / 0 drift / 0 data / 0 presentation
// - data/    不依赖 presentation/（反之亦然 — UI 和 基础设施 不能互穿）
// - domain/  不依赖 package:meta 这种纯 dart 之外的元包（meta 允许）
//
// 用法：dart run scripts/check_domain_purity.dart
//
// 退出码：0 = 通过, 1 = 有违规

// ignore_for_file: avoid_print

import 'dart:io';

/// 每个层级的 forbidden import 前缀
const _rules = <String, List<String>>{
  'domain': [
    'package:flutter/', // 所有 material / widgets / cupertino
    'package:drift/', // ORM
    'package:chroniccare/data/', // 4 层反向依赖
    'package:chroniccare/presentation/', // 4 层反向依赖
  ],
  'shared': [
    'package:flutter/',
    'package:drift/',
    'package:chroniccare/data/',
    'package:chroniccare/presentation/',
  ],
  'data': [
    'package:chroniccare/presentation/', // 基础设施不依赖 UI
  ],
  'presentation': [
    // presentation 可以用 flutter / drift 都行（drift 通过 repo 间接）
    // 但不应该直接 import 别的 presentation 业务页（应走路由）
    // 暂时不强制
  ],
};

const _layerDirs = <String, String>{
  'domain': 'domain',
  'shared': 'shared',
  'data': 'data',
  'presentation': 'presentation',
};

final _importPrefix = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');

class Violation {
  final String file;
  final int line;
  final String uri;
  final String rule;
  Violation(this.file, this.line, this.uri, this.rule);
  @override
  String toString() => '  $file:$line  →  $uri  ($rule)';
}

void main() {
  final root = Directory.current.path;
  final violations = <Violation>[];

  for (final layer in _layerDirs.keys) {
    final dirPath = '$root${Platform.pathSeparator}lib${Platform.pathSeparator}${_layerDirs[layer]}';
    final dir = Directory(dirPath);
    if (!dir.existsSync()) continue;
    violations.addAll(_scan(dir, _rules[layer] ?? const [], layer));
  }

  if (violations.isEmpty) {
    print('✅ 4 层架构纯度检查通过');
    print('   - domain/  0 flutter / 0 drift / 0 data / 0 presentation');
    print('   - shared/  0 flutter / 0 drift / 0 data / 0 presentation');
    print('   - data/    不依赖 presentation/');
    exit(0);
  } else {
    print('❌ 4 层架构纯度违规 ${violations.length} 处:\n');
    for (final v in violations) {
      print(v);
    }
    print('\n修复方法：');
    print('  - domain/ 不能 import flutter / drift / data / presentation');
    print('  - shared/ 不能 import flutter / drift / data / presentation');
    print('  - data/   不能 import presentation');
    print('  - 放错地方的代码应搬到合适的层');
    exit(1);
  }
}

List<Violation> _scan(
  Directory dir,
  List<String> forbiddenPrefixes,
  String layer,
) {
  if (forbiddenPrefixes.isEmpty) return const [];

  final violations = <Violation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    // 跳过 .g.dart（drift 生成）
    if (entity.path.endsWith('.g.dart')) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final m = _importPrefix.firstMatch(line);
      if (m == null) continue;
      final uri = m.group(1)!;
      for (final forbidden in forbiddenPrefixes) {
        if (uri.startsWith(forbidden)) {
          violations.add(Violation(
            entity.path,
            i + 1,
            uri,
            '[$layer] 不应引用 $forbidden',
          ));
        }
      }
    }
  }
  return violations;
}
