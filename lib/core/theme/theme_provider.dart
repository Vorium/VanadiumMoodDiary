import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 主题模式（系统 / 亮 / 暗）
///
/// 持久化用 [FlutterSecureStorage]（复用已有依赖）。
/// 单元测试时用 [themeModeProvider.overrideWith] 传一个 [useStorage]=false
/// 的实例避免平台通道在测试环境 hang。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  final bool useStorage;

  ThemeModeNotifier({this.useStorage = true});

  @override
  ThemeMode build() {
    if (useStorage) {
      _load();
    }
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return;
      final i = int.tryParse(raw);
      if (i == null || i < 0 || i >= ThemeMode.values.length) return;
      state = ThemeMode.values[i];
    } catch (_) {
      // 读失败保持系统模式
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    if (!useStorage) return;
    try {
      await _storage.write(key: _key, value: mode.index.toString());
    } catch (_) {
      // 写失败不影响 UI
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
