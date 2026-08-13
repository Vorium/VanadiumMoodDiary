// v0.30 R108 (P0#5, appstore A-5): AppIcon 资源占位防御
//
// 背景 (R107 报告 §2.2 + §5 appstore P0):
//   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
//   10932B (占位) → App Store Connect 上传会被审核员标 "low quality icon"。
//   实际 iOS App Store 强制 ≥ 1024×1024 且 ≥ 50KB (App Store Icon Guide 2024)。
//   其它小尺寸 (20/29/40/60/76/83.5 @1x/@2x/@3x) 应 ≥ 200B (避免 67B 假图模式)。
//
// 修法 (R108): 见 launch_image_size_round108_test.dart
// 本测试只锁住 1024×1024 尺寸 (App Store 上传必看), 其它尺寸 lock-in
// 防御 67B 假图 (R107 报告 §6 googleplay 截图也提了)。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #10: AppIcon 占位防御 (1024 ≥ 50KB, 小尺寸 ≥ 200B)', () {
    const iconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

    test('Icon-App-1024x1024@1x.png ≥ 50KB (App Store 上传必看)', () {
      final file = File('$iconDir/Icon-App-1024x1024@1x.png');
      expect(file.existsSync(), isTrue);
      final size = file.lengthSync();
      expect(
        size,
        greaterThanOrEqualTo(50 * 1024),
        reason:
            '1024×1024 icon 太小 ($size bytes), 应 ≥ 50KB 满足 App Store Icon Guide。'
            '请用 scripts/generate_ios_assets.sh 或设计师提供真实图',
      );
    });

    test('其它小尺寸 icon 全部 ≥ 200B (避免 67B 假图模式)', () {
      // R107 报告 §6 googleplay 截图 67B 假图问题
      // 防御: 20/29/40/60/76/83.5 @1x/@2x/@3x 都至少 200B
      const sizes = <String>[
        'Icon-App-20x20@1x.png',
        'Icon-App-20x20@2x.png',
        'Icon-App-20x20@3x.png',
        'Icon-App-29x29@1x.png',
        'Icon-App-29x29@2x.png',
        'Icon-App-29x29@3x.png',
        'Icon-App-40x40@1x.png',
        'Icon-App-40x40@2x.png',
        'Icon-App-40x40@3x.png',
        'Icon-App-60x60@2x.png',
        'Icon-App-60x60@3x.png',
        'Icon-App-76x76@1x.png',
        'Icon-App-76x76@2x.png',
        'Icon-App-83.5x83.5@2x.png',
      ];
      for (final filename in sizes) {
        final file = File('$iconDir/$filename');
        expect(file.existsSync(), isTrue, reason: '$filename 必须存在');
        final size = file.lengthSync();
        expect(
          size,
          greaterThanOrEqualTo(200),
          reason: '$filename 太小 ($size bytes), 是 67B 假图模式, 需设计师替换',
        );
      }
    });

    test('AppIcon.appiconset/Contents.json 引用所有尺寸', () {
      final file = File('$iconDir/Contents.json');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      // Contents.json 应至少引用 1024 (主尺寸) + 60@3x (iPhone App icon)
      expect(content.contains('1024x1024'), isTrue,
          reason: 'Contents.json 应引用 1024×1024 (App Store 主尺寸)',);
      expect(content.contains('60x60'), isTrue,
          reason: 'Contents.json 应引用 60×60 (iPhone App icon)',);
    });
  });
}
