// v0.30 R108 (P0#5, appstore A-5): LaunchImage 资源占位防御
//
// 背景 (R107 报告 §2.2 + §5 appstore P0):
//   ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png 68B
//   (空白 1×1 透明 PNG) → App 启动瞬间白屏 / 黑屏, 用户体验 + Apple HIG 违。
//   实际最小可用 LaunchImage ≥ 1KB (320x480 纯色 ~3KB)。
//
// 修法 (R108):
//   1) docs/audit/2026-08-10-cleanup/R108-ios-assets-design-brief.md
//      设计师 brief (1024×1024 主色 + 心形 + CC 字)
//   2) scripts/generate_ios_assets.sh 占位生成器 (sips / ImageMagick)
//   3) 本 lock-in test: LaunchImage.png + @2x + @3x 都 ≥ 1KB
//
// 锁住: 上架前设计师替换为真实图, 文件大小超过 1KB 占位阈值。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #10: LaunchImage 占位防御 (≥ 1KB)', () {
    final launchDir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    const requiredFiles = <String>[
      'LaunchImage.png',
      'LaunchImage@2x.png',
      'LaunchImage@3x.png',
    ];

    for (final filename in requiredFiles) {
      test('$filename 存在且 ≥ 1KB (非 68B 空白占位)', () {
        final file = File('$launchDir/$filename');
        expect(file.existsSync(), isTrue, reason: '$filename 必须存在');
        final size = file.lengthSync();
        expect(
          size,
          greaterThanOrEqualTo(1024),
          reason:
              '$filename 太小 ($size bytes), 是 R107 报告的 68B 空白占位, '
              '请用 scripts/generate_ios_assets.sh 生成或设计师提供真实图',
        );
      });
    }

    test('LaunchImage.imageset/Contents.json 引用 3 个文件名', () {
      final file = File('$launchDir/Contents.json');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      for (final filename in requiredFiles) {
        expect(content.contains(filename), isTrue,
            reason: 'Contents.json 应引用 $filename');
      }
    });

    test('scripts/generate_ios_assets.sh 存在 (设计师/CI 用占位生成器)', () {
      final file = File('scripts/generate_ios_assets.sh');
      expect(file.existsSync(), isTrue,
          reason: '占位生成器脚本应存在, 设计师可一键生成占位图通过 lock-in test');
      final content = file.readAsStringSync();
      expect(content.contains('LaunchImage'), isTrue,
          reason: '脚本应处理 LaunchImage');
    });
  });
}
