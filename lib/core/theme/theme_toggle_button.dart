import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/theme_provider.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

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
      tooltip:
          AppLocalizations.of(context).themeTooltip(_modeLabel(context, mode)),
      icon: Icon(icon),
      onPressed: () => notifier.set(next),
    );
  }

  String _modeLabel(BuildContext context, ThemeMode m) {
    final l10n = AppLocalizations.of(context);
    return switch (m) {
      ThemeMode.system => l10n.themeModeSystem,
      ThemeMode.light => l10n.themeModeLight,
      ThemeMode.dark => l10n.themeModeDark,
    };
  }
}
