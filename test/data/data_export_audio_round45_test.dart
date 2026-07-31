// v0.24 round 45 (Sprint #5c P0 god class 拆解) — ExportAudioService 子 service 测试
//
// Sprint #5c 把 data_export_service god class 拆 3 子 service, 这里是
// ExportAudioService 的独立 test, 覆盖:
//
// 1. buildAudioMetadata 3 字段序列化 (duration / sizeBytes / hadAudio 标志)
// 2. audioPath 不在序列化结果 (跨设备路径失效)
// 3. parseAudioDurationSec 边界 (0 / 86400 / 越界 / null / 非 int)
// 4. parseAudioSizeBytes 边界 (0 / 1GB / 越界 / null / 非 int)
//
// 不依赖 facade, 100% 子 service 独立测。
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = ExportAudioService();

  group('v0.24 round 45 (Sprint #5c) — ExportAudioService.buildAudioMetadata',
      () {
    test('3 字段全有 + 有 audioPath → hadAudio=true', () {
      final result = svc.buildAudioMetadata(
        audioDurationSec: 30,
        audioSizeBytes: 1024,
        audioPath: 'audio_2026_07_01.m4a.enc',
      );
      expect(result['audioDurationSec'], 30);
      expect(result['audioSizeBytes'], 1024);
      expect(result['hadAudio'], true);
      // audioPath 永远不在序列化结果
      expect(result.containsKey('audioPath'), isFalse);
    });

    test('3 字段全有 + audioPath=null → hadAudio 字段不存在', () {
      final result = svc.buildAudioMetadata(
        audioDurationSec: 30,
        audioSizeBytes: 1024,
        audioPath: null,
      );
      expect(result['audioDurationSec'], 30);
      expect(result['audioSizeBytes'], 1024);
      expect(result.containsKey('hadAudio'), isFalse);
    });

    test('3 字段全 null + audioPath=null → 全 null map, 无 hadAudio', () {
      final result = svc.buildAudioMetadata(
        audioDurationSec: null,
        audioSizeBytes: null,
        audioPath: null,
      );
      expect(result['audioDurationSec'], isNull);
      expect(result['audioSizeBytes'], isNull);
      expect(result.containsKey('hadAudio'), isFalse);
    });

    test('纯文字 vent (audioPath=null, duration/size 也有) → 无 hadAudio', () {
      // 模拟用户在 vent 表只存了文字, 没录音
      final result = svc.buildAudioMetadata(
        audioDurationSec: null,
        audioSizeBytes: null,
        audioPath: null,
      );
      expect(result.containsKey('hadAudio'), isFalse);
    });
  });

  group(
      'v0.24 round 45 (Sprint #5c) — ExportAudioService.parseAudioDurationSec',
      () {
    test('正常 int 30 → 30', () {
      expect(svc.parseAudioDurationSec(30), 30);
    });

    test('边界 0 → 0 (最小值)', () {
      expect(svc.parseAudioDurationSec(0), 0);
    });

    test('边界 86400 → 86400 (24h 上限)', () {
      expect(svc.parseAudioDurationSec(86400), 86400);
    });

    test('越界 86401 → 0 (defaultValue)', () {
      expect(svc.parseAudioDurationSec(86401), 0);
    });

    test('越界 -1 → 0', () {
      expect(svc.parseAudioDurationSec(-1), 0);
    });

    test('null → 0', () {
      expect(svc.parseAudioDurationSec(null), 0);
    });

    test('非 int 字符串 → 0', () {
      expect(svc.parseAudioDurationSec('30'), 0);
    });

    test('非 int double → 0 (Drift int column 不接受 double)', () {
      expect(svc.parseAudioDurationSec(30.5), 0);
    });

    test('custom defaultValue 兜底', () {
      expect(svc.parseAudioDurationSec(null, defaultValue: 999), 999);
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportAudioService.parseAudioSizeBytes',
      () {
    test('正常 int 1024 → 1024', () {
      expect(svc.parseAudioSizeBytes(1024), 1024);
    });

    test('边界 0 → 0', () {
      expect(svc.parseAudioSizeBytes(0), 0);
    });

    test('边界 1073741824 (1GB) → 1073741824', () {
      expect(svc.parseAudioSizeBytes(1073741824), 1073741824);
    });

    test('越界 1073741825 (1GB+1) → 0 (defaultValue)', () {
      expect(svc.parseAudioSizeBytes(1073741825), 0);
    });

    test('越界 -1 → 0', () {
      expect(svc.parseAudioSizeBytes(-1), 0);
    });

    test('null → 0', () {
      expect(svc.parseAudioSizeBytes(null), 0);
    });

    test('非 int 字符串 → 0', () {
      expect(svc.parseAudioSizeBytes('1024'), 0);
    });
  });
}
