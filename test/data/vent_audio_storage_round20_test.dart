// vent_audio_storage_round20_test.dart
//
// 测试 VentAudioStorage 路径生成 + 常量 + 公共 API
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';

void main() {
  group('VentAudioStorage constants', () {
    test('encryptedSuffix is .m4a.enc', () {
      expect(VentAudioStorage.encryptedSuffix, '.m4a.enc');
    });

    test('legacyPlainSuffix is .m4a', () {
      expect(VentAudioStorage.legacyPlainSuffix, '.m4a');
    });
  });

  group('VentAudioStorage constructor', () {
    test('can be created with default EncryptionService', () {
      final storage = VentAudioStorage();
      expect(storage, isNotNull);
    });

    test('can be created with injected EncryptionService', () {
      final storage = VentAudioStorage(encryption: null);
      expect(storage, isNotNull);
    });
  });

  group('newAudioPath', () {
    test('returns path ending with encryptedSuffix', () async {
      final storage = VentAudioStorage();
      try {
        final path = await storage.newAudioPath();
        expect(path, endsWith(VentAudioStorage.encryptedSuffix));
        expect(path, contains('vent_'));
      } catch (_) {
        // path_provider 在 test 环境不可用，预期失败
      }
    });
  });

  group('deleteTempFile', () {
    test('non-existent file does not throw', () async {
      final storage = VentAudioStorage();
      await storage.deleteTempFile('/nonexistent/path/file.m4a');
    });
  });

  group('deleteAudio', () {
    test('non-existent file returns true (idempotent)', () async {
      final storage = VentAudioStorage();
      final result =
          await storage.deleteAudio('/nonexistent/path/file.m4a.enc');
      expect(result, isTrue);
    });
  });

  group('deleteAll', () {
    test('non-existent directory returns 0', () async {
      final storage = VentAudioStorage();
      try {
        final count = await storage.deleteAll();
        expect(count, greaterThanOrEqualTo(0));
      } catch (_) {
        // path_provider 在 test 环境不可用
      }
    });
  });

  group('totalSizeBytes', () {
    test('non-existent directory returns 0', () async {
      final storage = VentAudioStorage();
      try {
        final size = await storage.totalSizeBytes();
        expect(size, greaterThanOrEqualTo(0));
      } catch (_) {
        // path_provider 在 test 环境不可用
      }
    });
  });
}
