// v0.32 R112-03: 影响因素 zh 字面量 → i18n key 归一化 (domain 纯函数)
//
// 背景: kInfluenceFactorKeys ARB key map 0 caller, 录入侧存中文。
// 修复: influenceFactorNormalizeKey 把 key 原样返回 / zh 字面量反查成 key /
// 未知值原样返回。展示侧再走 ARB 派发。
//
// 覆盖:
// 1. key → key (幂等)
// 2. 全部 26 个 zh 字面量 → 对应 key (与 kInfluenceFactorKeys 1:1 对齐)
// 3. 未知值 → 原样
// 4. InfluenceCodec encode/decode round-trip 保持 key

import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('1) key → key 幂等', () {
    expect(
      influenceFactorNormalizeKey('influenceFactorFamily'),
      'influenceFactorFamily',
    );
  });

  test('2) 全部 26 个 zh 字面量 → key (1:1 对齐)', () {
    final zhList = kInfluenceFactors.values.expand((l) => l).toList();
    final keyList = kInfluenceFactorKeys.values.expand((l) => l).toList();
    expect(zhList.length, keyList.length, reason: 'zh 与 key 必须 1:1');
    expect(keyList.length, 26);
    // 每个 zh 字面量都能反查到 key
    for (int i = 0; i < zhList.length; i++) {
      final key = influenceFactorNormalizeKey(zhList[i]);
      expect(key, isNot(zhList[i]), reason: '${zhList[i]} 应反查成 key');
      expect(keyList, contains(key));
    }
    // 且 key 唯一 (反查无碰撞)
    final normalized = zhList.map(influenceFactorNormalizeKey).toSet();
    expect(normalized.length, 26, reason: '反查结果必须唯一');
  });

  test('3) 未知值 → 原样', () {
    expect(influenceFactorNormalizeKey('自定义因素'), '自定义因素');
    expect(influenceFactorNormalizeKey(''), '');
  });

  test('4) encode/decode round-trip 保持 key', () {
    const keys = ['influenceFactorFamily', 'influenceFactorSunny'];
    final json = InfluenceCodec.encode(keys);
    expect(json, contains('influenceFactorFamily'));
    expect(InfluenceCodec.decode(json), keys);
  });
}
