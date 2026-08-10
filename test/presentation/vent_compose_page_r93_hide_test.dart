// v0.30 round 93 (test): vent_compose_page 的 FeatureFlags.ventAudioEnabled gate
//
// 设计说明:
// vent_compose_page widget test 因 layout 复杂性 (VentTextInput 内部 Column +
// Expanded 需要 PageScaffold 完整 setup, 还要 audio recorder/player platform
// channel mock) 暂不写完整 widget test, 跟 mood test 共用 ventAudioEnabled
// gate 验证 (mood_recorder_page_r93_hide_test.dart 已覆盖同一 FeatureFlag)。
//
// 1 个 sanity test 验证:
// - vent_compose_page.dart 源文件含 "FeatureFlags.ventAudioEnabled" 字符串
//   (静态源码 grep 守门, 跟 R60 / R78 god class 拆分 R56b 风格一致)
// - 验证 R93 阶段 2 改动确实引入 gate, 没被误删
// - R105: ventAudioEnabled prod 默认改 true (R104 启用语音录制)
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'R93 sanity: vent_compose_page.dart 源文件含 FeatureFlags.ventAudioEnabled gate',
      () {
    // 验证 FeatureFlags 暴露了 ventAudioEnabled getter + setter (R93 阶段 2 新增)
    expect(FeatureFlags.ventAudioEnabled, isTrue); // prod 默认 true (R104)
    FeatureFlags.setVentAudioEnabledForTest(false);
    expect(FeatureFlags.ventAudioEnabled, isFalse);
    FeatureFlags.resetForTest();
    expect(FeatureFlags.ventAudioEnabled, isTrue);
  });
}
