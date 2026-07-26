// v0.25 round 56c (spen P0 #15 TDD 补全): DbKeyService unit test
//
// 之前 0 test — 32 字节 random key 生成 + SecureStorage 写入是
// 加密唯一 source of truth, spen 报告 P0 #15 标"关键加密 key 生成无单测"
// R56c 补这个 test.
//
// 测 4 个场景:
// 1. 首次启动 (SecureStorage 空) → getOrCreate() 生成 32 字节 base64 key
// 2. 第二次调 (SecureStorage 有) → 返同一个 key (不重新生成)
// 3. hasKey() 跟 getOrCreate() 行为一致
// 4. 2 次连续 getOrCreate 调用不重新生成 (幂等)
//
// Mock 模式: 跟 encryption_round14_test 一致, 拦截
// 'plugins.it_nomads.com/flutter_secure_storage' MethodChannel
// 用 in-memory Map<String, String> 模拟 SecureStorage.
import 'dart:convert';

import 'package:chroniccare/core/data/services/db_key_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  // 内存模拟 SecureStorage
  final mockStorage = <String, String>{};

  setUp(() {
    // 每次 test 开始清空 mock storage
    mockStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;

      if (call.method == 'read' && key != null) {
        return mockStorage[key];
      }
      if (call.method == 'readAll') {
        return Map<String, String>.from(mockStorage);
      }
      if (call.method == 'write' && key != null) {
        final value = args['value'] as String?;
        if (value != null) {
          mockStorage[key] = value;
        }
        return null;
      }
      if (call.method == 'delete' && key != null) {
        mockStorage.remove(key);
        return null;
      }
      if (call.method == 'containsKey' && key != null) {
        return mockStorage.containsKey(key);
      }
      if (call.method == 'deleteAll') {
        mockStorage.clear();
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  group('DbKeyService.getOrCreate', () {
    test('SecureStorage 空 → 生成 32 字节 base64 key', () async {
      expect(mockStorage, isEmpty);

      final key = await DbKeyService.getOrCreate();

      // 32 字节 → base64 编码固定 44 字符 (含 padding '=')
      expect(key, isNotEmpty);
      expect(key.length, 44);
      expect(key, matches(RegExp(r'^[A-Za-z0-9+/=]+$')));

      // SecureStorage 写入新 key
      expect(mockStorage['db_encryption_key'], isNotNull);
      expect(mockStorage['db_encryption_key'], equals(key));

      // base64 解码回 32 字节
      final decoded = base64.decode(key);
      expect(decoded.length, 32);
    });

    test('2 次调 getOrCreate 返同一 key (幂等)', () async {
      final first = await DbKeyService.getOrCreate();
      expect(first, isNotEmpty);

      final second = await DbKeyService.getOrCreate();
      expect(second, equals(first),
          reason: '第二次调应返 SecureStorage 已有 key, 不重新生成');

      // SecureStorage 仍只 1 个 key (没被覆盖)
      expect(mockStorage.length, 1);
    });

    test('预填 SecureStorage → getOrCreate 返预填的 key', () async {
      const preFilled = 'pre_existing_base64_key_32_bytes_padded==';
      mockStorage['db_encryption_key'] = preFilled;

      final key = await DbKeyService.getOrCreate();
      expect(key, equals(preFilled),
          reason: '预填的 key 应优先使用, 不重新生成');
    });
  });

  group('DbKeyService.hasKey', () {
    test('初始 → false', () async {
      expect(await DbKeyService.hasKey(), isFalse);
    });

    test('getOrCreate 后 → true', () async {
      await DbKeyService.getOrCreate();
      expect(await DbKeyService.hasKey(), isTrue);
    });
  });
}
