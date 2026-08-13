// v0.32 round 8 (R112 theme_provider 竞态修): _load 晚到覆盖手动 set 的回归测试
//
// 竞态场景:
// - 冷启动 build() fire-and-forget _load() (secure storage 读慢)
// - 用户手动 set(ThemeMode.dark) → state = dark
// - _load 晚到返回旧持久化值 (light) → 修前覆盖 dark (用户设置丢失)
// - 修后: set() 递增 generation, _load 结果晚到 (generation 变) 即丢弃
//
// Mock 模式: 跟 db_key_service_round61_test 一致, 拦截
// 'plugins.it_nomads.com/flutter_secure_storage' MethodChannel,
// read 用 Completer 手动控制完成时机 (模拟慢读)。
import 'dart:async';

import 'package:chroniccare/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  Completer<void>? pendingRead;

  setUp(() {
    pendingRead = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      if (call.method == 'read') {
        // 慢读: 等测试手动 complete 才返回持久化值 (ThemeMode.light = 1)
        pendingRead = Completer<void>();
        await pendingRead!.future;
        return '1';
      }
      if (call.method == 'write') return null;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  test('手动 set 后 _load 晚到 → 丢弃旧值 (不覆盖用户新设置)', () async {
    final container = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(ThemeModeNotifier.new)],
    );
    addTearDown(container.dispose);

    // 冷启动: build() 同步返 system + fire-and-forget _load (慢读 pending)
    expect(container.read(themeModeProvider), ThemeMode.system);

    // 用户手动 set dark
    await container.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // _load 晚到 (旧持久化值 light)
    pendingRead!.complete();
    await pumpEventQueue();

    // 修前: 被覆盖回 light; 修后: 保持用户新设置 dark
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('无手动 set 时 _load 晚到 → 正常应用持久化值', () async {
    final container = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(ThemeModeNotifier.new)],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    pendingRead!.complete();
    await pumpEventQueue();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
