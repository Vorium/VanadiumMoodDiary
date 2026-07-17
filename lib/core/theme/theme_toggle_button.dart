import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/theme_provider.dart';

/// 主题切换按钮（在 system / light / dark 之间循环）
///
/// - system: 跟随系统（显示亮度自动图标）
/// - light: 亮色
/// - dark: 暗色
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    final next = switch (mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
    return IconButton(
      tooltip: '主题：${_modeLabel(mode)}（点击切换）',
      icon: Icon(icon),
      onPressed: () => notifier.set(next),
    );
  }

  String _modeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => '跟随系统',
        ThemeMode.light => '亮色',
        ThemeMode.dark => '暗色',
      };
}
