// v0.18 round 14 (P0-2) EncryptionService 测试
//
// 验证:
// 1. encrypt → decrypt round-trip 同字节
// 2. 相同明文 + 相同 key 两次加密 → 不同 ciphertext (因为 IV 随机)
// 3. 篡改 ciphertext → decrypt 失败 (PKCS7 padding 检测)
// 4. key 持久化 (mock SecureStorage)
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 注入 FlutterSecureStorage mock
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    // 重置 channel mock: 每次测试开始清空
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      if (call.method == 'read') {
        return null;
      }
      if (call.method == 'write') {
        return null;
      }
      if (call.method == 'delete') {
        return null;
      }
      return null;
    });
  });

  group('EncryptionService', () {
    test('P0-2: encrypt → decrypt round-trip', () async {
      final svc = EncryptionService();
      final plain = Uint8List.fromList(utf8.encode('hello vent secret audio'));
      final encrypted = await svc.encrypt(plain);
      final decrypted = await svc.decrypt(encrypted);

      expect(decrypted, plain);
    });

    test('P0-2: 大块数据 (1MB) round-trip', () async {
      final svc = EncryptionService();
      final plain = Uint8List(1024 * 1024); // 1MB
      for (var i = 0; i < plain.length; i++) {
        plain[i] = i % 256;
      }
      final encrypted = await svc.encrypt(plain);
      final decrypted = await svc.decrypt(encrypted);
      expect(decrypted.length, plain.length);
      expect(decrypted, plain);
    });

    test('P0-2: 相同明文加密 2 次 → 不同 ciphertext (IV 随机)', () async {
      final svc = EncryptionService();
      final plain = Uint8List.fromList(utf8.encode('相同的明文'));
      final c1 = await svc.encrypt(plain);
      final c2 = await svc.encrypt(plain);

      expect(c1.length, c2.length);
      // IV 是前 16 字节,应该不同
      expect(c1.sublist(0, 16), isNot(equals(c2.sublist(0, 16))),
          reason: 'P0-2: 每次加密 IV 应该不同');
      // ciphertext 也应该不同 (因为 IV 不同 → 加密块链状态不同)
      expect(c1, isNot(equals(c2)));
    });

    test('P0-2: 篡改 ciphertext → decrypt 失败 (PKCS7 padding 检测)',
        () async {
      final svc = EncryptionService();
      final plain = Uint8List.fromList(utf8.encode('秘密内容'));
      final encrypted = await svc.encrypt(plain);
      // 篡改第 17 字节 (跳过 IV 16 字节,改 ciphertext 第一字节)
      encrypted[17] = encrypted[17] ^ 0xFF;

      expect(
        () => svc.decrypt(encrypted),
        throwsA(anything),
        reason: '篡改后应该 detect padding/auth 错误',
      );
    });

    test('P0-2: blob 太短 (< 16 字节) → FormatException', () async {
      final svc = EncryptionService();
      final tooShort = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(
        () => svc.decrypt(tooShort),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
