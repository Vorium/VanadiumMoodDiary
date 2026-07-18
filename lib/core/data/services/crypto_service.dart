import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256 加密服务
///
/// 用于加密本地敏感数据（联系人邮箱、用户姓名等）
/// Key 存在 flutter_secure_storage（iOS Keychain / Android Keystore）
///
/// v0.20 (Q4): 从 encrypt 包迁移到 pointycastle 直接使用
class CryptoService {
  static const _keyStorageKey = 'chroniccare.aes.key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// 加密字符串
  Future<String> encrypt(String plain) async {
    final key = await _getOrCreateKey();
    final iv = _generateIV();

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      true,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    final encrypted = cipher.process(Uint8List.fromList(plain.codeUnits));
    return base64Encode(Uint8List.fromList(iv + encrypted));
  }

  /// 解密字符串
  Future<String> decrypt(String encrypted) async {
    final key = await _getOrCreateKey();
    final bytes = base64Decode(encrypted);
    final iv = bytes.sublist(0, 16);
    final ciphertext = bytes.sublist(16);

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      false,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    final decrypted = cipher.process(ciphertext);
    return String.fromCharCodes(decrypted);
  }

  /// 获取或创建 AES-256 Key
  Future<Uint8List> _getOrCreateKey() async {
    final stored = await _secureStorage.read(key: _keyStorageKey);
    if (stored != null) {
      return base64Decode(stored);
    }
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    await _secureStorage.write(
      key: _keyStorageKey,
      value: base64Encode(keyBytes),
    );
    return keyBytes;
  }

  /// 生成 16 字节 IV
  Uint8List _generateIV() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// 删除 Key（危险操作，仅用于完全重置）
  Future<void> resetKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }
}
