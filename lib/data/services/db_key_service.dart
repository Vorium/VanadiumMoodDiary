import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 数据库加密密钥管理
///
/// 存储：32 字节随机 key，base64 编码后存 flutter_secure_storage
/// key 名字：`db_encryption_key`
///
/// 安全：
/// - key 在 iOS 上存 Keychain，Android 上存 EncryptedSharedPreferences，
///   Windows 上存 DPAPI（flutter_secure_storage 内部处理）
/// - key 永不落盘到明文
/// - 同一台设备重装 app 后 key 还在（Android 取决于 secure storage 实现）
///
/// 迁移：
/// - 首次启动（v0.9 之前的老数据）→ 没有 key，但可能有非加密 DB
/// - DB 迁移由 [DatabaseMigration] 处理：检测 + 删旧 + 建新
class DbKeyService {
  DbKeyService._();

  static const _keyName = 'db_encryption_key';

  /// Android 用 EncryptedSharedPreferences，更安全
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 拿 key；如果没有就生成 32 字节随机 key 并存
  static Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final pwd = base64.encode(random);
    await _storage.write(key: _keyName, value: pwd);
    return pwd;
  }

  /// 检查是否已有 key（用于判断是否需要迁移）
  static Future<bool> hasKey() async {
    final v = await _storage.read(key: _keyName);
    return v != null && v.isNotEmpty;
  }
}
