// v0.23 round 40 (emil F4 fix): 抽 [SectionHeader] public widget
//
// 之前 settings_page 抽了 `_SectionHeader` (private),但 trend_page 4 处
// 重复 inline 完全相同的 TextStyle(fontSize/fontWeight/color)。
// emil "DRY for taste" — 同一 App 两套写法就是破窗。
// 把 _SectionHeader 提到 public,trend_page 复用。
//
// v0.31 round 8b (Apple Health redesign · Phase 2 Task 2.4):
// iOS ALL CAPS section header 改造:
// - 字号 16 → 11 → 13 (v0.31 round 8b 16→11, v0.32 round 8 11→13 跟 AppleListSection
//   title 统一, iOS insetGrouped section header 实际是 13pt)
// - 字重 w500 (不变)
// - 颜色 textSecondary → textHint (iOS section header 弱化色)
// - 新增 `isAllCaps` (默认 true) — toUpperCase() + letterSpacing 0.6
// - 保留 API: title / leading / action / chip (4 字段不破)
import 'package:flutter/material.dart';
// Apple Health 风格 (spec §4.5 section header (13pt w500 ALL CAPS letter-spacing 0.6 textHint)) [R32 集中器注释, 防后续误改为 Material 3 风格]

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';

/// section 标题文字
///
/// 用法:
/// ```dart
/// SectionHeader(title: '近 30 天')                    // 默认 ALL CAPS + 13pt + letterSpacing 0.6
/// SectionHeader(title: '近 30 天', isAllCaps: false)   // 关闭 ALL CAPS (大小写敏感标题)
/// SectionHeader(title: '设置', leading: Icon(...))     // + 前置 icon
/// SectionHeader(title: '导出', action: TextButton(...)) // + 右侧 action button
/// ```
///
/// v0.23 round 40 (emil F4 fix): 之前是 settings_page.dart:714 私有,
/// 提到 public 供 trend_page 4 处 inline 复用
///
/// v0.24 round 48 (emil P2-9): 加 leading + action 模式
/// 之前 settings_page 多处 inline `Row(Text + IconButton)` / `Row(Text + TextButton)`
/// emil "DRY for taste" — 抽 SectionHeader 的 Row 包装
///
/// v0.28 R81 (emil design-5): 加 chip 字段 (B 站"哗哩哗哩能量加油站"风格)
///
/// v0.31 round 8b (Apple Health redesign · Phase 2 Task 2.4):
/// 字号 16 → 11 → 13 (v0.32 round 8 11→13 跟 AppleListSection title 统一),
/// 颜色 textSecondary → textHint,
/// 新增 `isAllCaps` (默认 true) — iOS section header ALL CAPS + letterSpacing 0.6
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.leading,
    this.action,
    this.chip,
    this.isAllCaps = true,
  });

  /// v0.24 round 48 (emil P2-9): 可选 leading icon (左侧)
  final Widget? leading;

  /// v0.24 round 48 (emil P2-9): 可选 action button (右侧)
  /// 典型用法: TextButton('查看全部')
  final Widget? action;

  /// v0.28 R81 (emil design-5): 可选 chip 标签 (title 右侧)
  /// B 站"哗哩哗哩能量加油站" 风格 chip (心情测试 / 关于B站 / 等等),
  /// 跟 AppLocalizations 标准化 ARB key 集成
  ///
  /// v0.32 round 8 (R112 EM-09b fix): 走公共 widgets/ChipBadge 集中器
  /// (修前本文件私有 _ChipBadge 副本, 跟 ChipBadge + AppleListSection 副本
  /// 3 份同视觉代码)
  final String? chip;

  /// v0.31 round 8b (Apple Health redesign · Phase 2 Task 2.4):
  /// 是否 ALL CAPS (iOS section header 标准)
  ///
  /// 默认 true — 配合 iOS 13pt + letterSpacing 0.6 的 ALL CAPS 视觉。
  /// 传 false 让标题保持原始大小写 (适用于中文标题 / 品牌名 / 缩写敏感的文案)。
  final bool isAllCaps;

  final String title;

  /// v0.31 round 8b: 字号 16 → 11 (fontSizeCaptionSm, iOS section header 11pt)
  /// v0.32 round 8 (R111 EM-02b fix): 11 → 13 (fontSizeCaption) 跟
  /// AppleListSection title 统一 — 修前同屏两套 header 字号 (SectionHeader
  /// 11pt vs AppleListSection 13pt, Apple iOS insetGrouped 实际是 13pt)
  /// → 最终 13pt (fontSizeCaption)
  static const double _fontSize = AppTokens.fontSizeCaption; // 13.0

  /// v0.31 round 8b: 字重 w500 (不变)
  static const FontWeight _fontWeight = FontWeight.w500;

  /// v0.31 round 8b: iOS ALL CAPS letter-spacing (跟 AppleListSection 一致)
  static const double _letterSpacing = 0.6;

  @override
  Widget build(BuildContext context) {
    // v0.31 round 8b: 标题文本 — ALL CAPS + letterSpacing 0.6 (iOS 风格)
    final displayText = isAllCaps ? title.toUpperCase() : title;
    final titleStyle = TextStyle(
      fontSize: _fontSize,
      color: AppTokens.textHintColor(context),
      fontWeight: _fontWeight,
      letterSpacing: isAllCaps ? _letterSpacing : 0,
    );

    // 纯文字模式: 无 leading + action
    if (leading == null && action == null) {
      if (chip == null) {
        return Text(displayText, style: titleStyle);
      }
      return Row(
        children: [
          // v0.32 R112 round 8i: 窄屏/大字号防溢出
          Flexible(
            child: Text(
              displayText,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),
          ChipBadge(label: chip!),
        ],
      );
    }
    // 复合模式: Row(leading + title + chip + action)
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppTokens.spacingXs),
        ],
        // v0.32 R112 round 8i: 窄屏/大字号防溢出
        Flexible(
          child: Text(
            displayText,
            style: titleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (chip != null) ...[
          const SizedBox(width: AppTokens.spacingXs),
          ChipBadge(label: chip!),
        ],
        const Spacer(),
        if (action != null) ...[
          const SizedBox(width: AppTokens.spacingXs),
          action!,
        ],
      ],
    );
  }
}
