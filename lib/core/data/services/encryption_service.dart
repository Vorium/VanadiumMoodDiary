// v0.18 round 14 (P0-2) EncryptionService — 树洞音频文件加密
//
// 设计目标:
// - 设备绑定的 AES-256 加密 key,不存在应用目录外的任何地方
// - 启动时 lazy load (第一次用时从 SecureStorage 取 / 生成)
// - 加密 blob 自带随机 IV(每文件不同),格式: [16-byte IV][N-byte ciphertext]
// - key 不存明文在磁盘，只在内存中
//
// v0.20 (Q4): 从 encrypt 包迁移到 pointycastle 直接使用
// - encrypt 包自 2022 年停维，pointycastle 是其底层依赖且持续维护
// - 保持 AES-256-CBC + PKCS7 padding，加密格式完全兼容
//
// v0.22 round 28 (spen-01 + spen-bug-09): 合并 v0.7 旧 CryptoService
// - CryptoService 用 String.codeUnits (UTF-16) 不标准, 无单例, 每次 new
// - 实际 lib/ 0 业务引用 (v0.17 round 12 code review 已记录 dead code)
// - 加 encryptString/decryptString 用 utf8 编码 Uint8List → base64 包装
// - 老 key 不兼容 (key 名称不同), 但无用户数据依赖
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256 加密 / 解密服务(树洞音频 + 文字 v0.21 Round 22+)
class EncryptionService {
  static const _keyName = 'vent_audio_encryption_key_v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// 全局共享单例 —— 同一进程内所有 mapper / repository / service
  /// 用同一份 key cache,避免测试环境 setKeyForTest 后 mapper 仍用
  /// 独立 instance 拿不到 key。
  static final EncryptionService _shared = EncryptionService._internal();
  factory EncryptionService() => _shared;
  EncryptionService._internal();

  Uint8List? _cachedKey;

  /// 测试用：直接注入固定 key,跳过 SecureStorage (platform channel 不可用)
  ///
  /// 单元测试 / widget test 环境下 `FlutterSecureStorage` 走 platform channel
  /// 抛 `MissingPluginException`,导致 encrypt/decrypt 失败。设这个 flag 后
  /// 用注入的 key 加解密,不走 storage。
  @visibleForTesting
  void setKeyForTest(Uint8List key) {
    if (key.length != 32) {
      throw ArgumentError('key must be 32 bytes (AES-256)');
    }
    _cachedKey = key;
  }

  /// 取或创建 device-bound 32-byte key
  Future<Uint8List> getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final existing = await _storage.read(key: _keyName);
    Uint8List keyBytes;
    if (existing != null) {
      keyBytes = base64Decode(existing);
      if (keyBytes.length != 32) {
        keyBytes = _randomBytes(32);
        await _storage.write(key: _keyName, value: base64Encode(keyBytes));
      }
    } else {
      keyBytes = _randomBytes(32);
      await _storage.write(key: _keyName, value: base64Encode(keyBytes));
    }
    _cachedKey = keyBytes;
    return _cachedKey!;
  }

  /// 加密字节数组 → 加密 blob(IV + ciphertext 拼接)
  ///
  /// 格式: [16-byte IV][N-byte ciphertext]
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final key = await getOrCreateKey();
    final iv = _randomBytes(16);

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      true, // encrypt
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    final encrypted = cipher.process(plaintext);

    final out = Uint8List(iv.length + encrypted.length);
    out.setRange(0, iv.length, iv);
    out.setRange(iv.length, out.length, encrypted);
    return out;
  }

  /// 解密 blob → 明文字节
  ///
  /// [blob] 必须是 [encrypt] 产生的格式([16-byte IV][ciphertext])
  Future<Uint8List> decrypt(Uint8List blob) async {
    if (blob.length < 16) {
      throw const FormatException('Encrypted blob too short (< 16 bytes)');
    }
    final iv = blob.sublist(0, 16);
    final ciphertext = blob.sublist(16);
    final key = await getOrCreateKey();

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      false, // decrypt
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );
    return cipher.process(ciphertext);
  }

  /// 加密字符串 → base64 字符串 (v0.22 round 28 合并 CryptoService 后的统一 String API)
  ///
  /// v0.7 CryptoService 旧 API 是 String ↔ String (用 codeUnits 不标准),
  /// 现在统一用 utf8 编码 Uint8List → encrypt → base64(iv+ciphertext)
  /// 老 key 不兼容 (key 名称不同),但 v0.7 之后没人用 CryptoService (spen-01 验证 0 引用)
  Future<String> encryptString(String plain) async {
    final bytes = Uint8List.fromList(utf8.encode(plain));
    final encrypted = await encrypt(bytes);
    return base64Encode(encrypted);
  }

  /// 解密 base64 字符串 → 明文字符串 (跟 [encryptString] 配对)
  Future<String> decryptString(String base64) async {
    final blob = base64Decode(base64);
    final bytes = await decrypt(blob);
    return utf8.decode(bytes);
  }

  /// 测试用: 重置 key (清缓存 + 删 SecureStorage)
  Future<void> resetForTest() async {
    _cachedKey = null;
    await _storage.delete(key: _keyName);
  }

  /// 用 SecureRandom 生成 N 个随机字节
  static Uint8List _randomBytes(int n) {
    final rng = Random.secure();
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}
