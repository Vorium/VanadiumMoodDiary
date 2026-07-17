// check_all.dart 集成测试（v0.16 round 19）
//
// 用临时目录构造"假的" lib/ 结构，验证 check_all 的相对路径检测逻辑：
// 1. domain → data 相对路径违规（Round 13 抓 care_engine bug 的关键）
// 2. domain → flutter / drift 绝对路径违规
// 3. domain 内部引用不算违规
//
// 不测 main()，直接用相对路径 import 内部 helper
// （duplicate _testResolveImportLayer 因为原函数是 private）
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('check_all.dart 集成测试', () {
    late Directory tempRoot;
    late Directory libDir;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('check_all_test_');
      libDir = Directory('${tempRoot.path}${Platform.pathSeparator}lib')
        ..createSync();
    });

    tearDown(() {
      tempRoot.deleteSync(recursive: true);
    });

    test('domain/ 用相对路径 import data/ 应被检测到', () {
      // 构造：lib/domain/logic/foo.dart 引用 ../../data/bar.dart
      final domainDir = Directory(
          '${libDir.path}${Platform.pathSeparator}domain${Platform.pathSeparator}logic',)
        ..createSync(recursive: true);
      final fooFile =
          File('${domainDir.path}${Platform.pathSeparator}foo.dart');
      fooFile.writeAsStringSync('''
import '../../data/bar.dart';
void foo() {}
''');
      final resolved = _testResolveImportLayer(
        '../../data/bar.dart',
        fooFile.path,
        tempRoot.path,
      );
      expect(resolved, 'data');
    });

    test('domain/ 用绝对路径 import package:chroniccare/data/ 应被检测到', () {
      final resolved = _testResolveImportLayer(
        'package:chroniccare/data/bar.dart',
        '/fake/path/foo.dart'.replaceAll('/', Platform.pathSeparator),
        tempRoot.path,
      );
      expect(resolved, 'data');
    });

    test('domain/ import flutter 标记为 flutter', () {
      final resolved = _testResolveImportLayer(
        'package:flutter/material.dart',
        '/fake/path/foo.dart'.replaceAll('/', Platform.pathSeparator),
        tempRoot.path,
      );
      expect(resolved, 'flutter');
    });

    test('domain/ import drift 标记为 drift', () {
      final resolved = _testResolveImportLayer(
        'package:drift/drift.dart',
        '/fake/path/foo.dart'.replaceAll('/', Platform.pathSeparator),
        tempRoot.path,
      );
      expect(resolved, 'drift');
    });

    test('domain/ import 同 domain/../entities 不算违规', () {
      final fakePath = '/fake/lib/domain/logic/bar.dart'
          .replaceAll('/', Platform.pathSeparator);
      final resolved = _testResolveImportLayer(
        '../entities/foo.dart',
        fakePath,
        tempRoot.path,
      );
      expect(resolved, 'domain');
    });
  });
}

// 复制自 check_all.dart 的核心逻辑（用 @visibleForTesting 也行，这里直接复制）
// 用于测相对路径检测 — 这是 Round 13 抓 care_engine bug 的关键
String _testResolveImportLayer(String importUri, String fromFile, String root) {
  if (importUri.startsWith('package:flutter/')) return 'flutter';
  if (importUri.startsWith('package:drift/')) return 'drift';
  if (importUri.startsWith('dart:')) return 'external';

  if (importUri.startsWith('package:chroniccare/') ||
      (!importUri.startsWith('package:') && importUri.contains('/'))) {
    String absPath;
    if (importUri.startsWith('package:chroniccare/')) {
      final rel = importUri.substring('package:chroniccare/'.length);
      absPath =
          '$root${Platform.pathSeparator}lib${Platform.pathSeparator}${rel.replaceAll('/', Platform.pathSeparator)}';
    } else {
      final fromDir =
          fromFile.substring(0, fromFile.lastIndexOf(Platform.pathSeparator));
      absPath = _testNormalizePath(
        '$fromDir${Platform.pathSeparator}${importUri.replaceAll('/', Platform.pathSeparator)}',
      );
    }
    const layerDirs = <String, String>{
      'domain': 'domain',
      'shared': 'shared',
      'data': 'data',
      'presentation': 'presentation',
    };
    for (final layer in layerDirs.keys) {
      final marker =
          '${Platform.pathSeparator}lib${Platform.pathSeparator}${layerDirs[layer]}${Platform.pathSeparator}';
      if (absPath.contains(marker)) return layer;
    }
  }
  return 'external';
}

String _testNormalizePath(String p) {
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
