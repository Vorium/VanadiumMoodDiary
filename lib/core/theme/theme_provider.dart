import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';

/// 主题模式（系统 / 亮 / 暗）
///
/// 持久化用 [FlutterSecureStorage]（复用已有依赖）。
/// 单元测试时用 [themeModeProvider.overrideWith] 传一个 [useStorage]=false
/// 的实例避免平台通道在测试环境 hang。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  final bool useStorage;

  /// v0.32 round 8 (R112 竞态修): 手动 set 的 generation 计数。
  ///
  /// 竞态场景: 冷启动 `_load()` 读 secure storage (异步, 慢), 期间用户
  /// 手动点了主题切换 → `set()` 已把 state 改成新值; `_load` 晚到会用
  /// 旧持久化值覆盖新设置。修法: 每次 `set()` 递增 generation, `_load`
  /// 启动时快照, 结果晚到 (generation 已变) 即丢弃。
  int _generation = 0;

  ThemeModeNotifier({this.useStorage = true});

  @override
  ThemeMode build() {
    if (useStorage) {
      _load();
    }
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final generationAtStart = _generation;
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return;
      // R112 竞态修: 读期间用户手动 set 过 → 丢弃晚到的旧值
      if (generationAtStart != _generation) return;
      final i = int.tryParse(raw);
      if (i == null || i < 0 || i >= ThemeMode.values.length) return;
      state = ThemeMode.values[i];
    } catch (e, st) {
      // v0.22 round 30 (sp-en P1-3): 走 swallowError, dev 模式能看见
      // 之前 catch(_) 完全静默, 主题持久化失败时排查无线索
      swallowError(where: 'theme_provider._load', error: e, stack: st);
    }
  }

  Future<void> set(ThemeMode mode) async {
    _generation++;
    state = mode;
    if (!useStorage) return;
    try {
      await _storage.write(key: _key, value: mode.index.toString());
    } catch (e, st) {
      // v0.22 round 30 (sp-en P1-3): 走 swallowError
      swallowError(where: 'theme_provider._save', error: e, stack: st);
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
