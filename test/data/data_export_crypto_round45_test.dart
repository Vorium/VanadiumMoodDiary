// v0.24 round 45 (Sprint #5c P0 god class 拆解) — ExportCryptoService 子 service 测试
//
// Sprint #5c 把 data_export_service god class 拆 3 子 service, 这里是
// ExportCryptoService 的独立 test, 覆盖:
//
// 1. decrypt 失败 (PKCS7 pad / data corruption) → null (v0.23 round 39 P1-5 修复保留)
// 2. decrypt null blob → null (老数据 v8 schema 之前无加密字段)
// 3. encrypt 空字符串 / null → null
// 4. encrypt → decrypt round-trip (跟原 facade 行为一致)
// 5. encrypt 长文字 (> 100k 字符, vent 常长篇) → 仍可 round-trip
// 6. encrypt → 二次 encrypt (不同 IV) → 仍能 decrypt 回原文 (PKCS7 IV 随机性)
//
// 不依赖 facade, 100% 子 service 独立测。
import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EncryptionService enc;
  late ExportCryptoService svc;

  setUp(() {
    enc = EncryptionService();
    enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
    svc = ExportCryptoService(enc);
  });

  Future<Uint8List> encRaw(String s) async {
    return enc.encrypt(Uint8List.fromList(utf8.encode(s)));
  }

  group('v0.24 round 45 (Sprint #5c) — ExportCryptoService.decryptVentText',
      () {
    test('null blob → null (老数据兼容)', () async {
      final result = await svc.decryptVentText(null);
      expect(result, isNull);
    });

    test('损坏 BLOB (PKCS7 pad 错) → null, 不抛 (P1-5 修复保留)', () async {
      // 全 0xff 模拟损坏数据, decrypt 失败应返回 null
      final corrupt = Uint8List.fromList(List.filled(32, 0xff));
      final result = await svc.decryptVentText(corrupt);
      expect(result, isNull);
    });

    test('太短 BLOB (< 16 字节) → null (FormatException 容错)', () async {
      final tooShort = Uint8List.fromList([1, 2, 3]);
      final result = await svc.decryptVentText(tooShort);
      expect(result, isNull);
    });

    test('正常加密 BLOB → 明文', () async {
      final encrypted = await encRaw('今天心情很差');
      final result = await svc.decryptVentText(encrypted);
      expect(result, '今天心情很差');
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportCryptoService.encryptVentText',
      () {
    test('null → null', () async {
      final result = await svc.encryptVentText(null);
      expect(result, isNull);
    });

    test('空字符串 → null (跟 decrypt 对称)', () async {
      final result = await svc.encryptVentText('');
      expect(result, isNull);
    });

    test('正常文字 → BLOB (非空)', () async {
      final result = await svc.encryptVentText('hello world');
      expect(result, isNotNull);
      expect(result!.length, greaterThan(16)); // IV(16) + ciphertext(N)
    });

    test('encrypt → decrypt round-trip', () async {
      final original = '今天情绪低落, 工作压力大';
      final encrypted = await svc.encryptVentText(original);
      expect(encrypted, isNotNull);
      final decrypted = await svc.decryptVentText(encrypted);
      expect(decrypted, original);
    });

    test('同一文字二次 encrypt → 不同 BLOB (IV 随机性)', () async {
      final text = '测试 IV 随机性';
      final enc1 = await svc.encryptVentText(text);
      final enc2 = await svc.encryptVentText(text);
      expect(enc1, isNotNull);
      expect(enc2, isNotNull);
      // IV 不同 → 密文不同 (但长度相同)
      expect(enc1!.length, enc2!.length);
      expect(enc1, isNot(equals(enc2)));
      // 都能 decrypt 回原文
      expect(await svc.decryptVentText(enc1), text);
      expect(await svc.decryptVentText(enc2), text);
    });

    test('长文字 (> 100k 字符) encrypt → decrypt round-trip', () async {
      final longText = '树洞长篇测试' * 30000; // ~ 450k 字符
      final encrypted = await svc.encryptVentText(longText);
      expect(encrypted, isNotNull);
      final decrypted = await svc.decryptVentText(encrypted);
      expect(decrypted, longText);
    });
  });

  group('v0.24 round 45 (Sprint #5c) — ExportCryptoService 行为不变性', () {
    test('跟原 facade 行为一致: encrypt → decrypt 回明文', () async {
      // 跟 data_export_round39_test.dart 中 ventEntries round-trip 段对齐
      final encrypted = await encRaw('今天心情很差');
      final decrypted = await svc.decryptVentText(encrypted);
      expect(decrypted, '今天心情很差');
    });

    test('跟原 facade 行为一致: encrypt 短文字 → BLOB 短 (< 100 字节)', () async {
      // "hi" 加密后: IV(16) + "hi" ciphertext(32, PKCS7 padding 16-aligned) = 48 字节
      final encrypted = await svc.encryptVentText('hi');
      expect(encrypted!.length, lessThan(100));
    });
  });
}
