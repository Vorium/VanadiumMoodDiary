/// ⚠️ DEPRECATED — moved to `lib/data/repositories/user_profile_repository_impl.dart`
/// + `lib/domain/repositories/user_profile_repository.dart` (v0.16 round 19)
///
/// 这个文件保留只是为了不破坏历史 import 路径。新代码请用：
/// - `import 'package:chroniccare/domain/repositories/user_profile_repository.dart';` (abstract)
/// - `import 'package:chroniccare/data/repositories/user_profile_repository_impl.dart';` (impl)
@Deprecated('Use lib/domain/repositories/user_profile_repository.dart (abstract) instead')
library;

export '../../domain/repositories/user_profile_repository.dart';
export 'user_profile_repository_impl.dart';
