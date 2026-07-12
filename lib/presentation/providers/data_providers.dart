import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import 'core_providers.dart';

/// 用户档案
final userProfileProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(userProfileRepositoryProvider).watch(),
);

/// 今天的打卡
final todayCheckInProvider = StreamProvider<CheckIn?>(
  (ref) => ref.watch(checkInRepositoryProvider).watchToday(),
);

/// 所有 normal 类型打卡（用于计算 streak）
final allNormalCheckInsProvider = StreamProvider<List<CheckIn>>(
  (ref) {
    return ref.watch(checkInRepositoryProvider).watchAll().map((all) {
      return all.where((c) => c.type == 'normal').toList();
    });
  },
);

/// 联系人列表
final contactsProvider = StreamProvider<List<Contact>>(
  (ref) => ref.watch(contactRepositoryProvider).watchAll(),
);

/// 吃药列表
final medicationsProvider = StreamProvider<List<Medication>>(
  (ref) => ref.watch(medicationRepositoryProvider).watchAll(),
);
