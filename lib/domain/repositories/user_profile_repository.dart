import 'package:chroniccare/domain/entities/user_profile_entity.dart';

/// 用户档案仓库（domain 抽象接口）
///
/// data 层用 Drift 实现，UI 只调 watch / get / save。
abstract class UserProfileRepository {
  /// 监听用户档案（流式，UI 用）
  Stream<UserProfileEntity?> watch();

  /// 一次性获取
  Future<UserProfileEntity?> get();

  /// 创建或更新（setup / 修改用户名 / 改失联周期）
  ///
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 隐私考虑: 一些用户不愿透露真实姓名,可传 null
  /// UI 端 "我是 XXX" 模板退化: null → "朋友",空字符串 → "朋友"
  Future<void> save({
    String? userName,
    int checkInCycleHours = 48,
  });

  /// 更新最后打卡时间（用于失联检测）
  Future<void> updateLastCheckIn(DateTime time);

  // v0.21 Round 22 (P1-22 修复): PIPL §14 consent 记录

  /// setup 完成时调用,记录同意时刻 + 协议版本
  Future<void> recordConsent({
    required String userAgreementVersion,
    required String privacyPolicyVersion,
  });

  /// 撤回全部同意(记录撤回时刻,数据保留)
  Future<void> withdrawConsent();

  /// 重新同意(清空撤回时刻)
  Future<void> resetConsent();
}
