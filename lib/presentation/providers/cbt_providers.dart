// v0.29 round 84 (CBT 思维记录): 栏位持久化 provider
//
// - 读: SharedPreferences key "mood.thought_record_level" (int 3/5/7)
// - 写: 用户在 settings 页改后立时同步
// - 默认: 3 (新手友好)
// - 异常: SP 读失败 fallback 3 (fail-safe)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/thought_record_level.dart';

const _kThoughtRecordLevelKey = 'mood.thought_record_level';

/// 启动时一次性读 SP, 给 provider 用
///
/// 公开命名 (无下划线) 让 [ProviderScope] override 入口可见;
/// 默认 throw 是 fail-loud — 不在 bootstrap 调 `SharedPreferences.getInstance()`
/// 就会立刻崩, 跟"显式初始化"的项目约定一致 (跟 [databaseProvider] /
/// [notificationServiceProvider] 同款模式, 都是 main.dart 注入)。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at app boot'),
);

/// v0.29 round 84: 思维记录栏位 (3/5/7)
class ThoughtRecordLevelNotifier extends Notifier<ThoughtRecordLevel> {
  @override
  ThoughtRecordLevel build() {
    final sp = ref.read(sharedPreferencesProvider);
    final raw = sp.getInt(_kThoughtRecordLevelKey);
    return ThoughtRecordLevel.fromInt(raw ?? 3);
  }

  /// 设置栏位 (settings 页调用)
  Future<void> setLevel(ThoughtRecordLevel level) async {
    state = level;
    final sp = ref.read(sharedPreferencesProvider);
    await sp.setInt(_kThoughtRecordLevelKey, level.columnCount);
  }
}

final thoughtRecordLevelProvider =
    NotifierProvider<ThoughtRecordLevelNotifier, ThoughtRecordLevel>(
  ThoughtRecordLevelNotifier.new,
);
