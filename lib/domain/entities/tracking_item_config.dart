// v0.30 round 100: 日常追踪模块化配置
//
// Apple Health 风格: 每个追踪项 = 1 个可配置模块
// 支持收藏置顶、隐藏不用的项、按分类分组、自定义排序
// 配置持久化到 SharedPreferences (JSON)
//
// R104 (P0-2 fix): domain 层不 import flutter, 用 int 代替 IconData/Color。
// presentation 层扩展见 tracking_item_config_ext.dart。

import 'dart:convert';

/// 追踪项分类（Apple Health 风格分组）
enum TrackingCategory {
  emotional, // 情绪状态
  physical, // 身体指标
  behavioral, // 行为节律
  medical, // 医疗记录
}

/// 单个追踪项的配置 (domain 层, 0 flutter 依赖)
class DailyTrackingItemConfig {
  final String id;
  final String nameKey; // l10n key
  final String descKey; // l10n key for short description
  final int iconCodePoint; // IconData.codePoint (presentation 层转 IconData)
  final int colorValue; // Color.value (presentation 层转 Color)
  final TrackingCategory category;
  final String route;
  final bool isPinned;
  final bool isHidden;
  final int sortOrder;

  const DailyTrackingItemConfig({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.iconCodePoint,
    required this.colorValue,
    required this.category,
    required this.route,
    this.isPinned = false,
    this.isHidden = false,
    this.sortOrder = 0,
  });

  DailyTrackingItemConfig copyWith({
    bool? isPinned,
    bool? isHidden,
    int? sortOrder,
  }) {
    return DailyTrackingItemConfig(
      id: id,
      nameKey: nameKey,
      descKey: descKey,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      category: category,
      route: route,
      isPinned: isPinned ?? this.isPinned,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'isPinned': isPinned,
        'isHidden': isHidden,
        'sortOrder': sortOrder,
      };

  factory DailyTrackingItemConfig.fromJson(
    Map<String, dynamic> json,
    DailyTrackingItemConfig defaults,
  ) {
    return defaults.copyWith(
      isPinned: json['isPinned'] as bool? ?? defaults.isPinned,
      isHidden: json['isHidden'] as bool? ?? defaults.isHidden,
      sortOrder: json['sortOrder'] as int? ?? defaults.sortOrder,
    );
  }
}

/// 7 个追踪项的默认配置（硬编码，不可变）
const List<DailyTrackingItemConfig> kDefaultTrackingItems = [
  DailyTrackingItemConfig(
    id: 'mood',
    nameKey: 'moodDiaryName',
    descKey: 'moodDiaryShortDesc',
    iconCodePoint: 0xf1e5, // Icons.mood_outlined
    colorValue: 0xFFFF9500,
    category: TrackingCategory.emotional,
    route: '/mood-diary',
    isPinned: true,
    sortOrder: 0,
  ),
  DailyTrackingItemConfig(
    id: 'anxiety',
    nameKey: 'anxietyAgitationName',
    descKey: 'anxietyAgitationShortDesc',
    iconCodePoint: 0xf2d2, // Icons.psychology_outlined
    colorValue: 0xFF5856D6,
    category: TrackingCategory.emotional,
    route: '/anxiety-agitation',
    sortOrder: 1,
  ),
  DailyTrackingItemConfig(
    id: 'sleep',
    nameKey: 'sleepName',
    descKey: 'sleepShortDesc',
    iconCodePoint: 0xeecb, // Icons.bedtime_outlined
    colorValue: 0xFF5AC8FA,
    category: TrackingCategory.physical,
    route: '/sleep',
    isPinned: true,
    sortOrder: 2,
  ),
  DailyTrackingItemConfig(
    id: 'weight',
    nameKey: 'weightName',
    descKey: 'weightShortDesc',
    iconCodePoint: 0xf1e2, // Icons.monitor_weight_outlined
    colorValue: 0xFF34C759,
    category: TrackingCategory.physical,
    route: '/weight',
    sortOrder: 3,
  ),
  DailyTrackingItemConfig(
    id: 'social_rhythm',
    nameKey: 'socialRhythmName',
    descKey: 'socialRhythmShortDesc',
    iconCodePoint: 0xf339, // Icons.schedule_outlined
    colorValue: 0xFF007AFF,
    category: TrackingCategory.behavioral,
    route: '/social-rhythm',
    sortOrder: 4,
  ),
  DailyTrackingItemConfig(
    id: 'stress',
    nameKey: 'stressEventName',
    descKey: 'stressEventShortDesc',
    iconCodePoint: 0xeedd, // Icons.bolt_outlined
    colorValue: 0xFFFF3B30,
    category: TrackingCategory.behavioral,
    route: '/stress-events',
    sortOrder: 5,
  ),
  DailyTrackingItemConfig(
    id: 'treatment',
    nameKey: 'treatmentName',
    descKey: 'treatmentShortDesc',
    iconCodePoint: 0xf1be, // Icons.medical_services_outlined
    colorValue: 0xFFAF52DE,
    category: TrackingCategory.medical,
    route: '/treatment',
    sortOrder: 6,
  ),
];

/// 序列化/反序列化辅助
class TrackingConfigPersistence {
  static const _key = 'daily_tracking_item_configs';

  static String encode(List<DailyTrackingItemConfig> configs) {
    return jsonEncode(configs.map((c) => c.toJson()).toList());
  }

  static Map<String, DailyTrackingItemConfig> decode(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    final result = <String, DailyTrackingItemConfig>{};
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String;
      final defaults = kDefaultTrackingItems.firstWhere(
        (d) => d.id == id,
        orElse: () => kDefaultTrackingItems.first,
      );
      final config = DailyTrackingItemConfig.fromJson(map, defaults);
      result[id] = config;
    }
    return result;
  }

  static String get storageKey => _key;
}
