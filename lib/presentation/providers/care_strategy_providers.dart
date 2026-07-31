// v0.27 round 67 (B-2 修复): FireCareStrategyUseCase provider
//
// 之前 R65 抽了 use case (`lib/domain/usecases/fire_care_strategy.dart`),
// 但没在 Riverpod tree 里注册 provider → caller (home_page._fireCareEngine)
// 仍直接调 CareEngine.evaluate + CareEngine.fire 静态方法 → use case
// 是 dead code。本文件补注册。
//
// use case 是纯函数 (const constructor), 0 依赖, 所以 provider 也极简:
// `Provider<FireCareStrategyUseCase>((ref) => const FireCareStrategyUseCase())`
//
// 跟项目其他 use case provider 命名一致 (`recordCheckInUseCaseProvider` 等),
// 让 caller 拿 use case 不直接拿 repository / 静态方法。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';

/// v0.27 round 67 (B-2 修复): FireCareStrategyUseCase provider
///
/// caller (home_page._fireCareEngine) 拿 use case, 不再直接调
/// `CareEngine.evaluate` / `CareEngine.fire` 静态方法 (legacy API, v0.28 删除)。
///
/// 用法:
/// ```dart
/// final useCase = ref.read(fireCareStrategyUseCaseProvider);
/// final result = useCase(FireCareStrategyInput(
///   checkIns: all,
///   now: DateTime.now(),
///   userProfile: null,
///   contacts: const [],
///   config: CareChannelConfig.defaultConfig,  // careCopy
/// ));
/// ```
///
/// 0 副作用: use case 内部不调 service, 不发通知, 不写 DB。
/// caller 拿 result 自行 fire (call notification service / sms / email)。
final fireCareStrategyUseCaseProvider =
    Provider<FireCareStrategyUseCase>((ref) => const FireCareStrategyUseCase());
