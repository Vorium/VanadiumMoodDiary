// v1.1.0 round 9 (F1 烦恼闭环): worry 专属 providers
//
// 烦恼主题流 (open / resolved) + 某烦恼主题下的情绪记录流。
// autoDispose: 离开页面时 stream subscription 自动取消 (跟 vent 同款
// 隐私/资源考量, 避免后台监听 DB)。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// 进行中的烦恼 (open)
final worryOpenProvider = StreamProvider.autoDispose<List<WorryThreadEntity>>(
  (ref) => ref.watch(worryThreadRepositoryProvider).watchOpen(),
);

/// 已闭环的烦恼 (resolved, 忆往昔)
final worryResolvedProvider =
    StreamProvider.autoDispose<List<WorryThreadEntity>>(
  (ref) => ref.watch(worryThreadRepositoryProvider).watchResolved(),
);

/// 某烦恼主题下的情绪记录 (时间正序, 走 MoodRepository 的 watchByThread)
final worryEntriesProvider =
    StreamProvider.autoDispose.family<List<MoodEntryEntity>, int>(
  (ref, threadId) => ref.watch(moodRepositoryProvider).watchByThread(threadId),
);
