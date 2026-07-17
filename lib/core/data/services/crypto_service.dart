import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256 加密服务
///
/// 用于加密本地敏感数据（联系人邮箱、用户姓名等）
/// Key 存在 flutter_secure_storage（iOS Keychain / Android Keystore）
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
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    // 把 IV + 密文一起编码
    return base64Encode(Uint8List.fromList(iv.bytes + encrypted.bytes));
  }

  /// 解密字符串
  Future<String> decrypt(String encrypted) async {
    final key = await _getOrCreateKey();
    final bytes = base64Decode(encrypted);
    final iv = IV(Uint8List.fromList(bytes.sublist(0, 16)));
    final cipher = Encrypted(Uint8List.fromList(bytes.sublist(16)));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(cipher, iv: iv);
  }

  /// 获取或创建 AES-256 Key
  Future<Key> _getOrCreateKey() async {
    final stored = await _secureStorage.read(key: _keyStorageKey);
    if (stored != null) {
      return Key.fromBase64(stored);
    }
    // 生成新 Key
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final key = Key(keyBytes);
    await _secureStorage.write(
      key: _keyStorageKey,
      value: key.base64,
    );
    return key;
  }

  /// 生成 16 字节 IV
  IV _generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return IV(ivBytes);
  }

  /// 删除 Key（危险操作，仅用于完全重置）
  Future<void> resetKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }
}
