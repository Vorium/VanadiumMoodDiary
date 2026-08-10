// v0.30 R108 (P0#4): scripts/register_ios_privacy_info.py 防回归测试
//
// R107 报告 P0-4: ios/Runner/PrivacyInfo.xcprivacy 文件存在但
// ios/Runner.xcodeproj/project.pbxproj 0 引用 → xcodebuild 不打包
// → App Store 5.1.1(4) 隐私清单 2024-05 起强制 = 上架拒。
//
// 修法: scripts/register_ios_privacy_info.py 注入 PBXBuildFile +
// PBXFileReference + PBXResourcesBuildPhase + PBXGroup 4 处, idempotent
// (已注册则跳过)。
//
// 测试覆盖 (静态分析 + python 脚本检查, 不调 python 真跑):
// 1. scripts/register_ios_privacy_info.py 存在
// 2. 脚本含 4 个注入函数: PBXBuildFile / PBXFileReference / Resources / Group
// 3. 脚本 idempotent check: is_already_registered()
// 4. 脚本 --check-only CI mode 支持
// 5. iOS AppDelegate.swift 不依赖 pbxproj 修改 (Swift MethodChannel 自包含)
import 'dart:io' as dart_io;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Part A: scripts/register_ios_privacy_info.py R108 P0#4 静态分析', () {
    test('A1: 脚本文件存在', () async {
      final file = dart_io.File(
        'scripts/register_ios_privacy_info.py',
      );
      expect(
        await file.exists(),
        isTrue,
        reason: 'scripts/register_ios_privacy_info.py 必须存在',
      );
    });

    test('A2: 脚本含 4 处 pbxproj 注入逻辑', () async {
      final content = await dart_io.File(
        'scripts/register_ios_privacy_info.py',
      ).readAsString();
      // 4 处注入: PBXBuildFile / PBXFileReference / Resources build phase / Group children
      expect(
        content.contains('PBXBuildFile section'),
        isTrue,
        reason: '脚本应注入 PBXBuildFile section',
      );
      expect(
        content.contains('PBXFileReference section'),
        isTrue,
        reason: '脚本应注入 PBXFileReference section',
      );
      expect(
        content.contains('PBXResourcesBuildPhase'),
        isTrue,
        reason: '脚本应注入 PBXResourcesBuildPhase (Runner target resources)',
      );
      expect(
        content.contains('PBXGroup'),
        isTrue,
        reason: '脚本应注入 PBXGroup (Runner group children)',
      );
    });

    test('A3: 脚本 idempotent (is_already_registered check)', () async {
      final content = await dart_io.File(
        'scripts/register_ios_privacy_info.py',
      ).readAsString();
      expect(
        content.contains('is_already_registered'),
        isTrue,
        reason: '脚本应实现 is_already_registered() 幂等检查',
      );
      // 三处都需有: PBXFileReference + PBXBuildFile + Resources
      expect(
        content.contains('has_fileref'),
        isTrue,
        reason: 'idempotent 检查应含 has_fileref',
      );
      expect(
        content.contains('has_buildfile'),
        isTrue,
        reason: 'idempotent 检查应含 has_buildfile',
      );
      expect(
        content.contains('has_resource'),
        isTrue,
        reason: 'idempotent 检查应含 has_resource',
      );
    });

    test('A4: 脚本支持 --check-only CI mode', () async {
      final content = await dart_io.File(
        'scripts/register_ios_privacy_info.py',
      ).readAsString();
      expect(
        content.contains('--check-only'),
        isTrue,
        reason: '脚本应支持 --check-only CI 模式',
      );
      expect(
        content.contains('argparse'),
        isTrue,
        reason: '脚本应使用 argparse 解析参数',
      );
      // CI mode 应返 exit 1 (未注册), 0 (已注册)
      expect(
        content.contains('return 1'),
        isTrue,
        reason: 'CI 模式未注册应 return 1',
      );
      expect(
        content.contains('return 0'),
        isTrue,
        reason: 'CI 模式已注册应 return 0',
      );
    });
  });

  group('Part B: iOS AppDelegate.swift 不依赖 pbxproj 修改', () {
    test('B1: AppDelegate.swift 仍有慢性护理/backup channel (P0#1 修复独立)', () async {
      // 验证 P0#1 (iCloud Backup) 和 P0#4 (PrivacyInfo) 修复独立:
      // P0#1 走 Swift MethodChannel, 不依赖 pbxproj;
      // P0#4 走 pbxproj 注册 PrivacyInfo.xcprivacy。
      // 两个修复互不依赖, 一个修失败不影响另一个。
      final content = await dart_io.File(
        'ios/Runner/AppDelegate.swift',
      ).readAsString();
      expect(
        content.contains('"chroniccare/backup"'),
        isTrue,
        reason: 'P0#1 修复 (iCloud Backup MethodChannel) 应保持',
      );
    });
  });
}
