// v0.32 round 8 (R112-03 修复): 影响因素 key → 本地化文案派发 (单源)
//
// 之前 mood_influence_chips (mood) 与 mood_detail_page (mood_list) 各持
// 一份 26-case 私有 switch (注释称"跨 feature import 被 check_cross_feature
// 拦截"), R112 修 mood_factor_analysis 时会变 3 份。与 scale_name_l10n 同
// 款: 放 presentation/services/ 作跨 feature 共享纯函数 helper, 三处统一
// 调用, 26 个预设因素只维护一份。
//
// 默认分支: 未知 key (用户自定义值) 原样返回, 保证自定义数据不丢。
import 'package:chroniccare/l10n/app_localizations.dart';

/// 影响因素 key → 当前 locale 文案; 未知 key 原样返回 (自定义值上屏)。
String influenceFactorL10nLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'influenceFactorFamily':
      return l10n.influenceFactorFamily;
    case 'influenceFactorFriend':
      return l10n.influenceFactorFriend;
    case 'influenceFactorPartner':
      return l10n.influenceFactorPartner;
    case 'influenceFactorChild':
      return l10n.influenceFactorChild;
    case 'influenceFactorColleague':
      return l10n.influenceFactorColleague;
    case 'influenceFactorExercise':
      return l10n.influenceFactorExercise;
    case 'influenceFactorSick':
      return l10n.influenceFactorSick;
    case 'influenceFactorGoodSleep':
      return l10n.influenceFactorGoodSleep;
    case 'influenceFactorHealthyDiet':
      return l10n.influenceFactorHealthyDiet;
    case 'influenceFactorWork':
      return l10n.influenceFactorWork;
    case 'influenceFactorHobby':
      return l10n.influenceFactorHobby;
    case 'influenceFactorTravel':
      return l10n.influenceFactorTravel;
    case 'influenceFactorCommute':
      return l10n.influenceFactorCommute;
    case 'influenceFactorShopping':
      return l10n.influenceFactorShopping;
    case 'influenceFactorGaming':
      return l10n.influenceFactorGaming;
    case 'influenceFactorReading':
      return l10n.influenceFactorReading;
    case 'influenceFactorEntertainment':
      return l10n.influenceFactorEntertainment;
    case 'influenceFactorMeditation':
      return l10n.influenceFactorMeditation;
    case 'influenceFactorBreathing':
      return l10n.influenceFactorBreathing;
    case 'influenceFactorJournaling':
      return l10n.influenceFactorJournaling;
    case 'influenceFactorYoga':
      return l10n.influenceFactorYoga;
    case 'influenceFactorSunny':
      return l10n.influenceFactorSunny;
    case 'influenceFactorCloudy':
      return l10n.influenceFactorCloudy;
    case 'influenceFactorRainy':
      return l10n.influenceFactorRainy;
    case 'influenceFactorSnowy':
      return l10n.influenceFactorSnowy;
    case 'influenceFactorWindy':
      return l10n.influenceFactorWindy;
    default:
      return key;
  }
}
