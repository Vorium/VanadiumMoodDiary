// v1.1.0+166 R122 P2-1 (mood_audio_service 拆 3 facade step 3) regression
// test: storage review — 拆 3 facade 闭环验证。
//
// Goal: verify 拆 3 facade 完成后, MoodAudioStorage 已 100% 独立, 主 service
// 不再含 storage 业务逻辑 (委派链路 recorder → storage 完整)。
//
// 测试 3 个 structural properties:
//
//   1. MoodAudioStorage 文件 < 100L (67L 已独立, 0 业务逻辑) — 业务逻辑全在
//      EncryptedAudioStorage 基类
//   2. MoodAudioStorage 0 业务方法, 仅 5 个 override getter + 2 个 alias 常量
//   3. 拆 3 facade 完整: 主 service + stt + recorder + storage 4 文件全存在
//      + 0 跨 facade 私有访问 (main service 不 import EncryptedAudioStorage 基类)
//
// Functional correctness: integration tests under `test/presentation/`
// (mood_dialog_audio_round31 + mood_audio_recorder_round7b + ...)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R122 P2-1 step 3 — mood_audio_storage 独立验证 (拆 3 facade 闭环)', () {
    const mainPath = 'lib/core/data/services/mood_audio_service.dart';
    const sttPath = 'lib/core/data/services/mood_audio_stt.dart';
    const recorderPath = 'lib/core/data/services/mood_audio_recorder.dart';
    const storagePath = 'lib/core/data/services/mood_audio_storage.dart';

    test('拆 3 facade 4 文件双存在 (主 service + stt + recorder + storage)', () {
      // 验证: 拆 3 facade 后 4 个独立文件全在 — 缺一即 facade 跨边界 bug
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(sttPath).existsSync(), isTrue, reason: sttPath);
      expect(File(recorderPath).existsSync(), isTrue, reason: recorderPath);
      expect(File(storagePath).existsSync(), isTrue, reason: storagePath);
    });

    test('MoodAudioStorage 文件 < 100L (67L 业务逻辑全在 EncryptedAudioStorage 基类)',
        () {
      final lines = File(storagePath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(100),
        reason:
            'MoodAudioStorage 仅 mood-specific 配置 (目录名 + 前缀), 应保持精简 (R122 step 3 验证 67L)',
      );
    });

    test('MoodAudioStorage 0 业务方法 — 仅 5 个 override getter + 2 个 alias 常量',
        () {
      final storage = File(storagePath).readAsStringSync();
      // 5 个 override getter (R0.23 round 43 抽 EncryptedAudioStorage 基类)
      expect(storage.contains('String get dirName'), isTrue,
          reason: 'MoodAudioStorage 应有 dirName getter');
      expect(storage.contains('String get filePrefix'), isTrue,
          reason: 'MoodAudioStorage 应有 filePrefix getter');
      expect(storage.contains('String get tempRecordPrefix'), isTrue,
          reason: 'MoodAudioStorage 应有 tempRecordPrefix getter');
      expect(storage.contains('String get decryptPrefix'), isTrue,
          reason: 'MoodAudioStorage 应有 decryptPrefix getter');
      expect(storage.contains('String get debugTag'), isTrue,
          reason: 'MoodAudioStorage 应有 debugTag getter');
      // 0 业务方法: 不应有 encryptAndWrite / decryptToTemp / deleteFile 等
      // (这些全在 EncryptedAudioStorage 基类)
      expect(storage, isNot(contains('Future<String> encryptAndWrite(')),
          reason: 'MoodAudioStorage 不应有 encryptAndWrite (在基类)');
      expect(storage, isNot(contains('Future<String> decryptToTemp(')),
          reason: 'MoodAudioStorage 不应有 decryptToTemp (在基类)');
      expect(storage, isNot(contains('Future<void> deleteFile(')),
          reason: 'MoodAudioStorage 不应有 deleteFile (在基类)');
      // 不应 import dart:io (基类已 import, 子类不需要)
      expect(storage, isNot(contains("import 'dart:io'")),
          reason: 'MoodAudioStorage 不应再 import dart:io (基类已封装)');
    });

    test('MoodAudioStorage extends EncryptedAudioStorage (复用基类)', () {
      final storage = File(storagePath).readAsStringSync();
      expect(
        storage,
        contains('class MoodAudioStorage extends EncryptedAudioStorage'),
        reason:
            'MoodAudioStorage 应 extends EncryptedAudioStorage 基类 (R0.23 round 43 spen-2 抽离)',
      );
      // 公开基类供测试用
      expect(
        storage,
        contains("export 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart'"),
        reason: 'MoodAudioStorage 应 export 基类 (供 widget 测试 mock 注入)',
      );
    });

    test('主 service 不 import EncryptedAudioStorage 基类 (委派路径完整)', () {
      // 验证: 拆 3 facade 后主 service 不直接 import 基类 — 所有 storage 操作
      // 走 MoodAudioStorage 子类 (recorder 内部持)
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains("import 'package:chroniccare/core/data/privacy/encrypted_audio_storage.dart'")),
        reason:
            '主 service 不应 import EncryptedAudioStorage 基类 (拆 3 facade 边界: 仅 recorder 持 storage)',
      );
    });

    test('拆 3 facade 闭环: 主 service + stt + recorder + storage 4 文件总和 < 800L',
        () {
      // 验证: 拆 facade 不应让总行数爆涨 (R31 误判"已闭环" cross-residual)
      // baseline: 拆前 496L; step 1+2+3 拆后预期 ~780L (业务注释 + 文档 overhead)
      final main = File(mainPath).readAsLinesSync().length;
      final stt = File(sttPath).readAsLinesSync().length;
      final recorder = File(recorderPath).readAsLinesSync().length;
      final storage = File(storagePath).readAsLinesSync().length;
      final total = main + stt + recorder + storage;
      expect(
        total,
        lessThan(800),
        reason:
            '拆 3 facade 后 4 文件总和应保持 < 800L (拆前 496L, +overhead 限 < 60%), '
            '回归到 800+L 表示有 facade 业务回填',
      );
      // 打印拆分比例 (test 失败时能看到)
      // ignore: avoid_print
      print(
        '拆 3 facade L 数: main=$main stt=$stt recorder=$recorder storage=$storage total=$total',
      );
    });
  });
}
