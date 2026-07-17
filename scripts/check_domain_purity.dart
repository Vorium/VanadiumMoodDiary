// 验证 domain 层纯度（v0.16 Round 9）
//
// 4 层架构的核心约束：
// - domain/ 0 flutter 依赖（不 import 'package:flutter/...'）
// - domain/ 0 drift 依赖（不 import 'package:drift/...'）
// - domain/ 不依赖 data/ 或 presentation/
// - shared/ 不依赖 data/ 或 presentation/
//
// 用法：dart run scripts/check_domain_purity.dart
//
// 退出码：0 = 通过, 1 = 有违规

// ignore_for_file: avoid_print

import 'dart:io';

const _allowedRootImports = <String>[
  'dart:',
  'package:chroniccare/domain/',
  'package:chroniccare/shared/',
  'package:meta/',
  'package:flutter_riverpod/', // 用于 Notifier 构造时（domain/usecases 偶尔用）
];

/// 哪些前缀严禁 domain/shared 引用
const _forbiddenInDomain = <String>[
  'package:flutter/', // 所有 material / widgets / cupertino
  'package:drift/', // ORM
  'package:chroniccare/data/', // 4 层反向依赖
  'package:chroniccare/presentation/', // 4 层反向依赖
];

const _forbiddenInShared = <String>[
  'package:flutter/',
  'package:drift/',
  'package:chroniccare/data/',
  'package:chroniccare/presentation/',
];

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
  final domainDir = Directory('$root${Platform.pathSeparator}lib${Platform.pathSeparator}domain');
  final sharedDir = Directory('$root${Platform.pathSeparator}lib${Platform.pathSeparator}shared');

  final violations = <Violation>[];

  if (domainDir.existsSync()) {
    violations.addAll(_scan(domainDir, _forbiddenInDomain, 'domain'));
  }
  if (sharedDir.existsSync()) {
    violations.addAll(_scan(sharedDir, _forbiddenInShared, 'shared'));
  }

  if (violations.isEmpty) {
    print('✅ 4 层架构纯度检查通过');
    print('   - domain/ 0 flutter / 0 drift / 0 data / 0 presentation');
    print('   - shared/ 0 flutter / 0 drift / 0 data / 0 presentation');
    exit(0);
  } else {
    print('❌ 4 层架构纯度违规 ${violations.length} 处:\n');
    for (final v in violations) {
      print(v);
    }
    print('\n修复方法：');
    print('  - domain/ 不能 import flutter/drift/data/presentation');
    print('  - shared/ 不能 import flutter/drift/data/presentation');
    print('  - 放错地方的代码应搬到合适的层（data / presentation）');
    exit(1);
  }
}

List<Violation> _scan(
  Directory dir,
  List<String> forbiddenPrefixes,
  String layer,
) {
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
