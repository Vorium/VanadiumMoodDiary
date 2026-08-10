// v0.30 R101: 影响因素分类枚举 + 预设常量
//
// 参照 Apple Health State of Mind 的影响因素标签系统。
// 6 大类 30+ 预设标签，用户可多选。
//
// 设计决策:
// - 与现有"情绪状态标签"(焦虑/抑郁/平静/失眠/烦躁/能量低) 共存
// - 情绪状态标签 = "我现在感觉怎样"
// - 影响因素 = "什么导致我这样感觉"

import 'package:chroniccare/core/shared/json_codec.dart';

/// 影响因素分类
enum InfluenceCategory {
  relationships('relationships'),
  health('health'),
  activities('activities'),
  mindfulness('mindfulness'),
  weather('weather'),
  other('other');

  const InfluenceCategory(this.id);
  final String id;

  static InfluenceCategory fromId(String? id) {
    if (id == null) return other;
    for (final c in values) {
      if (c.id == id) return c;
    }
    return other;
  }
}

/// 预设影响因素 (按分类) — 中文 fallback
///
/// v0.31: presentation 层应走 [kInfluenceFactorsL10n] 拿 i18n key，
/// 本 const 仅作 domain 层 fallback + 老测试兼容。
const Map<InfluenceCategory, List<String>> kInfluenceFactors = {
  InfluenceCategory.relationships: [
    '家人',
    '朋友',
    '伴侣',
    '孩子',
    '同事',
  ],
  InfluenceCategory.health: [
    '运动',
    '生病',
    '睡眠好',
    '饮食健康',
  ],
  InfluenceCategory.activities: [
    '工作',
    '爱好',
    '旅行',
    '通勤',
    '购物',
    '游戏',
    '阅读',
    '娱乐',
  ],
  InfluenceCategory.mindfulness: [
    '冥想',
    '呼吸练习',
    '写日记',
    '瑜伽',
  ],
  InfluenceCategory.weather: [
    '晴天',
    '多云',
    '雨天',
    '雪天',
    '刮风',
  ],
};

/// 预设影响因素 i18n key (按分类)
///
/// v0.31: presentation 层走 `AppLocalizations.of(context).influenceFactorXxx`
/// 拿本地化文案。key 与 [kInfluenceFactors] 一一对应。
const Map<InfluenceCategory, List<String>> kInfluenceFactorKeys = {
  InfluenceCategory.relationships: [
    'influenceFactorFamily',
    'influenceFactorFriend',
    'influenceFactorPartner',
    'influenceFactorChild',
    'influenceFactorColleague',
  ],
  InfluenceCategory.health: [
    'influenceFactorExercise',
    'influenceFactorSick',
    'influenceFactorGoodSleep',
    'influenceFactorHealthyDiet',
  ],
  InfluenceCategory.activities: [
    'influenceFactorWork',
    'influenceFactorHobby',
    'influenceFactorTravel',
    'influenceFactorCommute',
    'influenceFactorShopping',
    'influenceFactorGaming',
    'influenceFactorReading',
    'influenceFactorEntertainment',
  ],
  InfluenceCategory.mindfulness: [
    'influenceFactorMeditation',
    'influenceFactorBreathing',
    'influenceFactorJournaling',
    'influenceFactorYoga',
  ],
  InfluenceCategory.weather: [
    'influenceFactorSunny',
    'influenceFactorCloudy',
    'influenceFactorRainy',
    'influenceFactorSnowy',
    'influenceFactorWindy',
  ],
};

/// 影响因素 JSON 编解码工具
class InfluenceCodec {
  InfluenceCodec._();

  /// 解析 JSON 字符串为因素列表
  static List<String> decode(String json) => JsonCodec.decodeStringList(json);

  /// 编码因素列表为 JSON 字符串
  static String encode(List<String> factors) =>
      JsonCodec.encodeStringList(factors);
}
