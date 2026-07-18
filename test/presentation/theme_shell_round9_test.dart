// 验证 theme 切换（用 useStorage:false 避免 secure_storage 平台通道在测试 hang）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_theme.dart';
import 'package:chroniccare/core/theme/theme_provider.dart';

ThemeModeNotifier _mem() => ThemeModeNotifier(useStorage: false);

Widget _wrap(ProviderContainer c) {
  return UncontrolledProviderScope(
    container: c,
    child: Consumer(
      builder: (context, ref, _) {
        final mode = ref.watch(themeModeProvider);
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const Scaffold(body: Text('hello')),
        );
      },
    ),
  );
}

void main() {
  testWidgets('theme 切换: 亮色 → 暗色 → 亮色', (tester) async {
    final c = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(_mem)],
    );
    addTearDown(c.dispose);

    await tester.pumpWidget(_wrap(c));
    await tester.pump();
    expect(
      Theme.of(tester.element(find.text('hello'))).brightness,
      Brightness.light,
      reason: '默认 system，平台默认 brightness 影响结果——这里默认是 light',
    );

    // 切到 dark
    await c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    // 重新取 element（pump 后 widget tree 重建）
    final ctx2 = tester.element(find.text('hello'));
    expect(
      Theme.of(ctx2).brightness,
      Brightness.dark,
    );

    // 切回 light
    await c.read(themeModeProvider.notifier).set(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('hello'))).brightness,
      Brightness.light,
    );
  });

  test('themeProvider 默认 system', () {
    final c = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(_mem)],
    );
    addTearDown(c.dispose);
    expect(c.read(themeModeProvider), ThemeMode.system);
  });
}
