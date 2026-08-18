// v1.1.0+182 R128b (R110 阶段 4) — crisis feature 5 region 模板抽 logic
//
// 背景:
// - R92 把 5 region 列表 (大陆/台湾/香港/美国/国际) 直接 inline 在
//   CrisisHotlinePage.build() 里, page 260L 拆 1 行 call list 后剩 100L
//   真正 UI 代码。R128b 抽 public pure logic, 让 page 只关注 UI。
//
// 4 层架构: 0 flutter / 0 drift / 0 data / 0 presentation。
// (注: data/logic/ 是 features 内部的 "logic" 层, 跟 domain/logic 区别:
//  - domain/logic = 跨 feature 共享业务规则 (e.g. streak_calculator)
//  - features/{name}/data/logic = feature 内部组合 (e.g. crisis hotline
//    5 region 模板, mood audio service facade), 用 l10n 但 0 flutter widgets)
//
// 修正: buildHotlineGroups(AppLocalizations l10n) 接收 l10n 实例,
// 返 List<RegionGroup> 给 page 渲染。5 region 模板跟 R92 一致。

import 'package:chroniccare/l10n/app_localizations.dart';

import 'package:chroniccare/features/crisis/domain/entities/hotline_entry.dart';

/// 5 地区 hotline 模板 (按 R92 + R75 hotlineByRegion const Map 设计):
/// - 大陆: R75 cn[0] 400-161-9995 + 800-810-1117 + R75 cn[1] 010-82951332
/// - 台湾: R75 tw[0] 1995 + tw[1] 1925
/// - 香港: R75 hk[0] 2389 2222
/// - 美国: R75 us[0] 988 + us[1] 741741
/// - 国际: fallback 提示
List<RegionGroup> buildHotlineGroups(AppLocalizations l10n) {
  return <RegionGroup>[
    RegionGroup(
      title: l10n.crisisHotlineRegionCn,
      entries: [
        HotlineEntry(
          label: l10n.crisisHotlineCnLabel,
          number: l10n.crisisHotlineCnNumber,
          desc: l10n.crisisHotlineCnDesc,
        ),
        HotlineEntry(
          label: l10n.crisisHotlineCn2Label,
          number: l10n.crisisHotlineCn2Number,
          desc: l10n.crisisHotlineCn2Desc,
        ),
        HotlineEntry(
          label: l10n.crisisHotlineCnBeijingLabel,
          number: l10n.crisisHotlineCnBeijingNumber,
          desc: l10n.crisisHotlineCnBeijingDesc,
        ),
      ],
    ),
    RegionGroup(
      title: l10n.crisisHotlineRegionTw,
      entries: [
        HotlineEntry(
          label: l10n.crisisHotlineTw1995Label,
          number: l10n.crisisHotlineTw1995Number,
          desc: l10n.crisisHotlineTw1995Desc,
        ),
        HotlineEntry(
          label: l10n.crisisHotlineTwLabel,
          number: l10n.crisisHotlineTwNumber,
          desc: l10n.crisisHotlineTwDesc,
        ),
      ],
    ),
    RegionGroup(
      title: l10n.crisisHotlineRegionHk,
      entries: [
        HotlineEntry(
          label: l10n.crisisHotlineHkLabel,
          number: l10n.crisisHotlineHkNumber,
          desc: l10n.crisisHotlineHkDesc,
        ),
      ],
    ),
    RegionGroup(
      title: l10n.crisisHotlineRegionUs,
      entries: [
        HotlineEntry(
          label: l10n.crisisHotlineUsLabel,
          number: l10n.crisisHotlineUsNumber,
          desc: l10n.crisisHotlineUsDesc,
        ),
        HotlineEntry(
          label: l10n.crisisHotlineUsTextLineLabel,
          number: l10n.crisisHotlineUsTextLineNumber,
          desc: l10n.crisisHotlineUsTextLineDesc,
        ),
      ],
    ),
    RegionGroup(
      title: l10n.crisisHotlineRegionIntl,
      entries: [
        HotlineEntry(
          label: l10n.crisisHotlineIntlLabel,
          number: l10n.crisisHotlineIntlNumber,
          desc: l10n.crisisHotlineIntlDesc,
        ),
      ],
    ),
  ];
}
