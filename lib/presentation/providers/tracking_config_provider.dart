// v0.30 round 100: 追踪项配置 Provider
//
// 持久化到 SharedPreferences: 收藏/隐藏/排序
// Notifier 模式 (Riverpod 3.x), 跟 theme_provider 一致

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';

/// 追踪项配置状态
class TrackingConfigState {
  final Map<String, DailyTrackingItemConfig> configs;
  final bool loaded;

  const TrackingConfigState({
    this.configs = const {},
    this.loaded = false,
  });

  /// 获取单个项的配置（找不到返回默认值）
  DailyTrackingItemConfig get(String id) {
    return configs[id] ??
        kDefaultTrackingItems.firstWhere(
          (d) => d.id == id,
          orElse: () => kDefaultTrackingItems.first,
        );
  }

  /// 收藏的项（按 sortOrder 排序）
  List<DailyTrackingItemConfig> get pinnedItems {
    final items = kDefaultTrackingItems.map((d) => get(d.id)).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items.where((c) => c.isPinned && !c.isHidden).toList();
  }

  /// 按分类分组的未隐藏项（不含收藏）
  Map<TrackingCategory, List<DailyTrackingItemConfig>> get itemsByCategory {
    final items = kDefaultTrackingItems.map((d) => get(d.id)).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final visible = items.where((c) => !c.isHidden && !c.isPinned).toList();
    final result = <TrackingCategory, List<DailyTrackingItemConfig>>{};
    for (final cat in TrackingCategory.values) {
      final catItems = visible.where((c) => c.category == cat).toList();
      if (catItems.isNotEmpty) {
        result[cat] = catItems;
      }
    }
    return result;
  }

  /// 所有可见项（收藏 + 分类内, 按 sortOrder 排序）
  List<DailyTrackingItemConfig> get allVisibleItems {
    final items = kDefaultTrackingItems.map((d) => get(d.id)).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items.where((c) => !c.isHidden).toList();
  }

  /// 所有项（含隐藏, 用于自定义页）
  List<DailyTrackingItemConfig> get allItems {
    final items = kDefaultTrackingItems.map((d) => get(d.id)).toList();
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }
}

class TrackingConfigNotifier extends Notifier<TrackingConfigState> {
  late final SharedPreferences _prefs;

  @override
  TrackingConfigState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return _load();
  }

  TrackingConfigState _load() {
    final json = _prefs.getString(TrackingConfigPersistence.storageKey);
    if (json != null) {
      try {
        final configs = TrackingConfigPersistence.decode(json);
        return TrackingConfigState(configs: configs, loaded: true);
      } catch (_) {
        return const TrackingConfigState(configs: {}, loaded: true);
      }
    }
    return const TrackingConfigState(configs: {}, loaded: true);
  }

  Future<void> _save() async {
    await _prefs.setString(
      TrackingConfigPersistence.storageKey,
      TrackingConfigPersistence.encode(state.allItems),
    );
  }

  /// 切换收藏状态
  Future<void> togglePin(String id) async {
    final current = state.get(id);
    final updated = current.copyWith(isPinned: !current.isPinned);
    state = TrackingConfigState(
      configs: {...state.configs, id: updated},
      loaded: true,
    );
    await _save();
  }

  /// 切换隐藏状态
  Future<void> toggleHide(String id) async {
    final current = state.get(id);
    final updated = current.copyWith(isHidden: !current.isHidden);
    state = TrackingConfigState(
      configs: {...state.configs, id: updated},
      loaded: true,
    );
    await _save();
  }

  /// 更新排序
  Future<void> reorder(String id, int newSortOrder) async {
    final current = state.get(id);
    final updated = current.copyWith(sortOrder: newSortOrder);
    state = TrackingConfigState(
      configs: {...state.configs, id: updated},
      loaded: true,
    );
    await _save();
  }
}

/// 追踪项配置 Provider
final trackingConfigProvider =
    NotifierProvider<TrackingConfigNotifier, TrackingConfigState>(
  TrackingConfigNotifier.new,
);
