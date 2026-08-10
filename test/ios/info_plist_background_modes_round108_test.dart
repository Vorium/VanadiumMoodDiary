// v0.30 R108 (P0#2, appstore A-3): UIBackgroundModes audio 必须存在
//
// 背景:
//   R100 (2026-08-08) 因 ventAudio / 失联通知业务 FeatureFlags 关闭, 删 Info.plist
//   UIBackgroundModes audio+processing 声明, 理由 "used-but-not-declared = Apple 2.5.4 拒"。
//   R104 (2026-08-09) FeatureFlags.ventAudioEnabled 翻 true (vent+mood 语音录音真接),
//   业务实际已启用但 Info.plist 仍无 audio 声明 = 矛盾:
//
//   1. Apple 2.5.4 仍会拒 (声明跟实际不匹配: vent 录音功能启用却没声明 audio 后台)
//   2. iOS 系统在 App 进后台时会杀录音, vent 用户体验崩 (录音中收到通知切走 = 数据丢失)
//
// 修法 (R108): Info.plist 恢复 UIBackgroundModes = [audio], AppDelegate.swift 同步注释
// 防御未来再误删: 锁住 audio 必须存在 + processing 暂时不恢复 (等 SMS 真接)。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #7: UIBackgroundModes audio', () {
    test('Info.plist 含 UIBackgroundModes array', () {
      final plist = File('ios/Runner/Info.plist');
      expect(plist.existsSync(), isTrue, reason: 'Info.plist 必须存在');
      final content = plist.readAsStringSync();
      // UIBackgroundModes 声明必须存在
      expect(
        content.contains('<key>UIBackgroundModes</key>'),
        isTrue,
        reason: 'Info.plist 必须声明 UIBackgroundModes key',
      );
    });

    test('UIBackgroundModes 包含 audio (vent 录音后台需要)', () {
      final plist = File('ios/Runner/Info.plist');
      final content = plist.readAsStringSync();
      // 简单 XML 字符串匹配: <key>UIBackgroundModes</key> 后 <array><string>audio</string>
      final idxKey = content.indexOf('<key>UIBackgroundModes</key>');
      expect(idxKey, greaterThan(-1), reason: '找不到 UIBackgroundModes key');
      // 找下一个 </array> 段
      final arrayStart = content.indexOf('<array>', idxKey);
      final arrayEnd = content.indexOf('</array>', arrayStart);
      expect(arrayStart, greaterThan(-1));
      expect(arrayEnd, greaterThan(arrayStart));
      final arrayContent = content.substring(arrayStart, arrayEnd);
      expect(
        arrayContent.contains('<string>audio</string>'),
        isTrue,
        reason: 'UIBackgroundModes 必须含 audio 字符串 (vent 录音后台)',
      );
    });

    test('UIBackgroundModes 不应包含 processing (BGProcessingTask 暂未真接)', () {
      // processing = BGProcessingTask 失联检测, 阿里云 SMS 真接后再加
      // 当前 FeatureFlags.aliyunSmsEnabled=false, 加 processing 会触发 2.5.4
      final plist = File('ios/Runner/Info.plist');
      final content = plist.readAsStringSync();
      final idxKey = content.indexOf('<key>UIBackgroundModes</key>');
      if (idxKey < 0) {
        // 整体声明都没, 自然不含 processing
        return;
      }
      final arrayStart = content.indexOf('<array>', idxKey);
      final arrayEnd = content.indexOf('</array>', arrayStart);
      final arrayContent = content.substring(arrayStart, arrayEnd);
      expect(
        arrayContent.contains('<string>processing</string>'),
        isFalse,
        reason:
            'UIBackgroundModes 不应包含 processing (BGProcessingTask 失联检测未真接, '
            '加会触发 Apple 2.5.4 拒)',
      );
    });

    test('AppDelegate.swift 含 R108 恢复注释 (来龙去脉)', () {
      // 防御未来 R110+ refactor 误以为 R100 删除是终态, 再次删除
      final appDelegate = File('ios/Runner/AppDelegate.swift');
      expect(appDelegate.existsSync(), isTrue);
      final content = appDelegate.readAsStringSync();
      expect(
        content.contains('R108'),
        isTrue,
        reason: 'AppDelegate.swift 应有 R108 注释标记',
      );
      expect(
        content.contains('UIBackgroundModes audio'),
        isTrue,
        reason: 'AppDelegate.swift 应说明 audio 后台模式由 Info.plist 接管',
      );
    });

    test('project.pbxproj 引用 Info.plist 路径不变 (R108 不动 pbxproj)', () {
      // INFOPLIST_FILE = Runner/Info.plist 是 Xcode 标准模式, 加 key 不改 pbxproj
      // 锁住 INFOPLIST_FILE 仍指向 Runner/Info.plist, 防御 refactor 误改
      final pbxproj = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(pbxproj.existsSync(), isTrue);
      final content = pbxproj.readAsStringSync();
      expect(
        content.contains('INFOPLIST_FILE = Runner/Info.plist'),
        isTrue,
        reason: 'project.pbxproj 应仍引用 Runner/Info.plist',
      );
    });
  });
}
