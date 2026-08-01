// v0.23 (Round 43 spen-2 + spen-5) EncryptedAudioStorage 基类回归测试
//
// 覆盖:
// 1. 抽基类后 vent / mood 子类行为不变(公共 API contract)
// 2. encryptAndWrite try/finally 兜底 — encryption 失败时 plain 仍要删
//    (spen-5 PII 残留防护)
// 3. decryptToTemp round-trip (加密 → 解密 → 字节相等)
// 4. 子类 directory + prefix 各不相同(隐私边界:vent 跟 mood 文件不混)
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';

/// v0.23 (Round 43) 共享 helper: 注入固定 AES-256 key 让
/// EncryptionService 走真加密 (不走 SecureStorage platform channel)。
void _useTestKey() {
  // 32 bytes (AES-256)
  final key = Uint8List.fromList(List.generate(32, (i) => i));
  EncryptionService().setKeyForTest(key);
}

void main() {
  setUpAll(() {
    _useTestKey();
  });

  // ============================================================
  // 1. 基类 metadata 契约
  // ============================================================
  group('EncryptedAudioStorage 常量 + metadata 契约 (spen-2)', () {
    test('encryptedSuffix 跟旧值一致 (.m4a.enc)', () {
      expect(EncryptedAudioStorage.encryptedSuffix, '.m4a.enc');
      expect(VentAudioStorage.encryptedSuffix, '.m4a.enc');
      expect(MoodAudioStorage.encryptedSuffix, '.m4a.enc');
    });

    test('legacyPlainSuffix 跟旧值一致 (.m4a)', () {
      expect(EncryptedAudioStorage.legacyPlainSuffix, '.m4a');
      expect(VentAudioStorage.legacyPlainSuffix, '.m4a');
      expect(MoodAudioStorage.legacyPlainSuffix, '.m4a');
    });

    test('vent 跟 mood 子类 directory + prefix 完全不同 (隐私边界)', () {
      final vent = VentAudioStorage();
      final mood = MoodAudioStorage();
      // dirName 必须不同 (避免跨 privacy 模块混读)
      expect(vent.dirName, 'vent_audio');
      expect(mood.dirName, 'mood_audio');
      expect(vent.dirName, isNot(mood.dirName));
      // prefix 也必须不同
      expect(vent.filePrefix, 'vent_');
      expect(mood.filePrefix, 'mood_');
      expect(vent.decryptPrefix, isNot(mood.decryptPrefix));
    });
  });

  // ============================================================
  // 2. encryptAndWrite 正常路径 + round-trip
  // ============================================================
  group('encryptAndWrite 正常路径 (spen-2 + spen-5)', () {
    late Directory tempDir;
    late String plainPath;
    late String encPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('eaudio_test_');
      plainPath = p.join(tempDir.path, 'plain.m4a');
      encPath = p.join(tempDir.path, 'encrypted.m4a.enc');
      // 写明文测试数据
      await File(plainPath).writeAsBytes(
        Uint8List.fromList(List.generate(64, (i) => i + 100)),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('加密成功 → 删明文 → 加密文件存在', () async {
      final vent = VentAudioStorage();
      await vent.encryptAndWrite(
        plainPath: plainPath,
        encryptedPath: encPath,
      );
      // 加密文件存在
      expect(await File(encPath).exists(), isTrue);
      // 明文已删
      expect(await File(plainPath).exists(), isFalse);
    });

    test('round-trip: encryptAndWrite → decryptToTemp 字节相等', () async {
      final vent = VentAudioStorage();
      await vent.encryptAndWrite(
        plainPath: plainPath,
        encryptedPath: encPath,
      );
      // 解密
      final decryptedPath = await vent.decryptToTemp(encPath);
      try {
        final decryptedBytes = await File(decryptedPath).readAsBytes();
        final originalBytes = List.generate(64, (i) => i + 100);
        expect(decryptedBytes, equals(originalBytes));
      } finally {
        await vent.deleteTempFile(decryptedPath);
      }
    });

    test('明文不存在 → 抛 FileSystemException', () async {
      final vent = VentAudioStorage();
      expect(
        () => vent.encryptAndWrite(
          plainPath: p.join(tempDir.path, 'nonexistent.m4a'),
          encryptedPath: encPath,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  // ============================================================
  // 3. spen-5: encryptAndWrite try/finally 兜底
  // ============================================================
  group('encryptAndWrite 失败清理 (spen-5 PII 防护)', () {
    test('encryption 抛异常 → 不应残留明文 (兜底清理)', () async {
      final tempDir = await Directory.systemTemp.createTemp('eaudio_fail_');
      addTearDown(() async {
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });

      final plainPath = p.join(tempDir.path, 'plain.m4a');
      // 写一个真实的明文文件
      final original = Uint8List.fromList(List.generate(32, (i) => i + 50));
      await File(plainPath).writeAsBytes(original);

      // 用一个"无法写入加密文件"的目录 — 把 encPath 指向一个不存在的目录
      // 这样 writeAsBytes 会抛 FileSystemException
      final badEncPath = p.join(tempDir.path, 'nonexistent_dir', 'bad.m4a.enc');

      // v0.23 (Round 43 spen-5 修法): 失败时仍要兜底删明文,避免 PII 残留
      // 注意:这里**不能**简单走 swallowError — vent 之前修过同款 bug
      // (round 22 P1-1), 现在的契约是"encrypt 失败 → 主动清理明文"
      // 修法是 wrap 整段在 try/finally
      final vent = VentAudioStorage();

      // 预期 encryptAndWrite 抛错
      Object? caught;
      try {
        await vent.encryptAndWrite(
          plainPath: plainPath,
          encryptedPath: badEncPath,
        );
      } catch (e) {
        caught = e;
      }
      expect(caught, isNotNull, reason: '应当抛错');

      // 关键断言:明文已被兜底删除(无 PII 残留)
      // v0.23 round 43 spen-5: encryptAndWrite 应当用 try/finally
      // 兜底清明文,即 writeAsBytes 抛错也要 delete plain
      final plainStillExists = await File(plainPath).exists();
      expect(
        plainStillExists,
        isFalse,
        reason: 'spen-5: encrypt 失败时明文必须删,避免 PII 残留',
      );
    });
  });

  // ============================================================
  // 4. vent 跟 mood 共享基类 API
  // ============================================================
  group('vent / mood 子类共享基类 API', () {
    test('两个子类都满足 EncryptedAudioStorage 抽象类型', () {
      final vent = VentAudioStorage();
      final mood = MoodAudioStorage();
      expect(vent, isA<EncryptedAudioStorage>());
      expect(mood, isA<EncryptedAudioStorage>());
    });

    test('decryptPrefix 不同 — vent_decrypt_ vs mood_decrypt_', () {
      final vent = VentAudioStorage();
      final mood = MoodAudioStorage();
      expect(vent.decryptPrefix, 'vent_decrypt_');
      expect(mood.decryptPrefix, 'mood_decrypt_');
    });

    test('tempRecordPrefix 不同 — vent_record_ vs mood_record_', () {
      final vent = VentAudioStorage();
      final mood = MoodAudioStorage();
      expect(vent.tempRecordPrefix, 'vent_record_');
      expect(mood.tempRecordPrefix, 'mood_record_');
    });

    test('debugTag 各自标识 — swallowError 定位用', () {
      final vent = VentAudioStorage();
      final mood = MoodAudioStorage();
      expect(vent.debugTag, 'vent_audio_storage');
      expect(mood.debugTag, 'mood_audio_storage');
    });
  });
}
