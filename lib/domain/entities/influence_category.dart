// 规则 3 标记: 影响因素中文 fallback — v1.0+ i18n (显示层走 ARB)
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

/// zh 字面量 → i18n key 反查表 (兼容存量中文数据)
///
/// v0.32 R112-03: 录入侧改存 key 之前, DB 里存的是中文 (kInfluenceFactors
/// 字面量)。展示侧先走 [influenceFactorNormalizeKey] 反查成 key, 再走
/// ARB 派发, 老数据也能正确本地化。
/// 与 [kInfluenceFactors] / [kInfluenceFactorKeys] 索引一一对应。
const Map<String, String> kInfluenceFactorZhToKey = {
  '家人': 'influenceFactorFamily',
  '朋友': 'influenceFactorFriend',
  '伴侣': 'influenceFactorPartner',
  '孩子': 'influenceFactorChild',
  '同事': 'influenceFactorColleague',
  '运动': 'influenceFactorExercise',
  '生病': 'influenceFactorSick',
  '睡眠好': 'influenceFactorGoodSleep',
  '饮食健康': 'influenceFactorHealthyDiet',
  '工作': 'influenceFactorWork',
  '爱好': 'influenceFactorHobby',
  '旅行': 'influenceFactorTravel',
  '通勤': 'influenceFactorCommute',
  '购物': 'influenceFactorShopping',
  '游戏': 'influenceFactorGaming',
  '阅读': 'influenceFactorReading',
  '娱乐': 'influenceFactorEntertainment',
  '冥想': 'influenceFactorMeditation',
  '呼吸练习': 'influenceFactorBreathing',
  '写日记': 'influenceFactorJournaling',
  '瑜伽': 'influenceFactorYoga',
  '晴天': 'influenceFactorSunny',
  '多云': 'influenceFactorCloudy',
  '雨天': 'influenceFactorRainy',
  '雪天': 'influenceFactorSnowy',
  '刮风': 'influenceFactorWindy',
};

/// 归一化影响因素存储值为 i18n key
///
/// v0.32 R112-03:
/// - 已是 key → 原样返回 (幂等)
/// - 旧中文数据 (kInfluenceFactors 字面量) → 反查成 key
/// - 未知自定义值 → 原样返回 (展示侧直接上屏, 不丢数据)
String influenceFactorNormalizeKey(String raw) {
  for (final keys in kInfluenceFactorKeys.values) {
    if (keys.contains(raw)) return raw;
  }
  return kInfluenceFactorZhToKey[raw] ?? raw;
}

/// 影响因素 JSON 编解码工具
class InfluenceCodec {
  InfluenceCodec._();

  /// 解析 JSON 字符串为因素列表
  static List<String> decode(String json) => JsonCodec.decodeStringList(json);

  /// 编码因素列表为 JSON 字符串
  static String encode(List<String> factors) =>
      JsonCodec.encodeStringList(factors);
}
// rule3-whitelist: 48-51, 54-61, 64-67, 70-74, 132-153
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
