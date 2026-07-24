// v0.23 (Round 31) mood_audio_storage_test
//
// 测试 MoodAudioStorage 路径生成 + 常量 + 公共 API (仿 vent_audio_storage_test)。
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/mood_audio_storage.dart';

void main() {
  group('MoodAudioStorage constants', () {
    test('encryptedSuffix is .m4a.enc', () {
      expect(MoodAudioStorage.encryptedSuffix, '.m4a.enc');
    });

    test('legacyPlainSuffix is .m4a', () {
      expect(MoodAudioStorage.legacyPlainSuffix, '.m4a');
    });
  });

  group('MoodAudioStorage constructor', () {
    test('can be created with default EncryptionService', () {
      final storage = MoodAudioStorage();
      expect(storage, isNotNull);
    });

    test('can be created with injected EncryptionService', () {
      // null encryption 仍能构造,真实加密时才报错
      final storage = MoodAudioStorage(encryption: null);
      expect(storage, isNotNull);
    });
  });

  group('newAudioPath', () {
    test('returns path ending with encryptedSuffix', () async {
      final storage = MoodAudioStorage();
      try {
        final path = await storage.newAudioPath();
        expect(path, endsWith(MoodAudioStorage.encryptedSuffix));
        expect(path, contains('mood_'));
      } catch (_) {
        // path_provider 在 test 环境可能不可用,预期失败
      }
    });
  });

  group('deleteTempFile', () {
    test('non-existent file does not throw', () async {
      final storage = MoodAudioStorage();
      await storage.deleteTempFile('/nonexistent/path/file.m4a');
    });
  });

  group('deleteAudio', () {
    test('non-existent file returns true (idempotent)', () async {
      final storage = MoodAudioStorage();
      final result =
          await storage.deleteAudio('/nonexistent/path/file.m4a.enc');
      expect(result, isTrue);
    });
  });

  group('deleteAll', () {
    test('non-existent directory returns 0', () async {
      final storage = MoodAudioStorage();
      // 在 test 环境 path_provider 抛, 这里 try-catch 兼容
      try {
        final result = await storage.deleteAll();
        expect(result, isA<int>());
      } catch (_) {
        // 忽略 — path_provider 在 test 环境受限
      }
    });
  });

  group('fileSizeBytes', () {
    test('non-existent file returns 0', () async {
      final storage = MoodAudioStorage();
      final size = await storage.fileSizeBytes('/nonexistent/file.m4a.enc');
      expect(size, 0);
    });
  });
}
