// v0.31 round 2 (Apple Health redesign · Phase 1 Task 1.2): 字号 + 行高 + 字重 + 字符间距 token
//
// 历史:
// - v0.27 round 65 (alibaba B16 god constant 拆分): 字体 + TextStyle token 独立
//   拆解前: app_tokens.dart 644 行 8 大类混合。R65 拆 4 文件, 字体 + 行高 +
//   TextStyle helper 13 个全部在本文件。app_tokens.dart 留 facade re-export。
//
// v0.31 round 2 (Apple Health redesign · 3.2.1-3.2.4):
// - 字号阶梯改 iOS 14 档: button 20→17 / body 18→17 / label 16→15 /
//   caption 14→13 / micro 10→11 / xxxSmall 8→9 / bodySm 13→12 / captionSm 12→11
// - 新增 3 档 metric 字号: 22/28/34 (Apple Health 大数字 ultralight)
// - 行高改 Apple 紧凑: tight 1.2→1.1 / normal 1.5→1.4 / loose 1.8→1.6
// - 新增 2 档字重: ultralight w200 + light w300
// - 新增 3 个 textStyleMetric helper (大数字 ultralight 走 textPrimaryColor)
// - 7 个 textStyle helper 加 letterSpacing: title/headline -0.5, button/body -0.2, 其余 0
//
// 设计原则:
// - fontSize + lineHeight + fontWeight 走 const, 可在 const constructor 用
// - textStyleXxx 走 dynamic (接受 BuildContext), color 走 AppColors.dynamic getter
// - 老 caller 兼容: `AppTokens.fontSizeBody` 仍能用 (走 facade)
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:flutter/material.dart';

/// v0.31 round 2 (Apple Health redesign): 字体 + TextStyle token 集中器
///
/// 4 大类:
/// 1. **静态 fontSize** (17 个, Apple 14 档 + 3 metric 大数字)
/// 2. **静态 lineHeight** (5 个, 1.1/1.4/1.6 + snug 1.4 / relaxed 1.6)
/// 3. **静态 fontWeight** (2 个新增, ultralight w200 / light w300)
/// 4. **TextStyle helper** (18 个, dynamic, color 走 AppColors dynamic getter)
class AppTypography {
  AppTypography._();

  // ============= 字体 =============
  // v0.31 R2 (Apple Health redesign · 3.2.1): 字号阶梯改 iOS 14 档
  // body 18→17 (iOS body) / button 20→17 (iOS button) / label 16→15 (iOS subheadline)
  // caption 14→13 (iOS footnote) / micro 10→11 / xxxSmall 8→9
  // bodySm 13→12 (iOS caption2) / captionSm 12→11
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeButton =
      17.0; // v0.31 R2: 20→17 (iOS button standard)
  static const double fontSizeBody = 17.0; // v0.31 R2: 18→17 (iOS body)
  static const double fontSizeLabel = 15.0; // v0.31 R2: 16→15 (iOS subheadline)
  static const double fontSizeCaption = 13.0; // v0.31 R2: 14→13 (iOS footnote)
  // v0.22 round 29 (emil-16): 微小字 (10 / 8) 集中器, 日历 cell + 小标签统一
  static const double fontSizeMicro = 11.0; // v0.31 R2: 10→11
  static const double fontSizeXxxSmall = 9.0; // v0.31 R2: 8→9

  // v0.22 round 36 (emil 7.2): 中间档 + score 数字集中器
  // 11 / 12 / 13 是 Body / Label / Caption 之间的过渡尺寸
  static const double fontSizeBodySm = 12.0; // v0.31 R2: 13→12 (iOS caption2)
  static const double fontSizeCaptionSm = 11.0; // v0.31 R2: 12→11
  static const double fontSizeLabelSm = 11.0; // 保留 (R2 不动)

  // v0.31 R2 (Apple Health redesign · 3.2.1): 3 档 metric 大数字
  // 用于 StatCard / AppleHealthTile / QuickMoodCarousel 等 Apple Health 风格大数字
  // 字重走 ultralight (w200), 见 textStyleMetricXl/Lg/Md 3 个 helper
  static const double fontSizeMetricXl = 34.0; // v0.31 R2 新增
  static const double fontSizeMetricLg = 28.0; // v0.31 R2 新增
  static const double fontSizeMetricMd = 22.0; // v0.31 R2 新增

  // v0.25 R50 (emil R50) 添加 textStyleScoreLg/Xl/Xxl 3 个 helper, v0.26 R57 删
  // (0 处使用, 改 inline TextStyle)。fontSizeScoreLg/Xl/Xxl 3 个常量保留为 fallback。
  // v0.31 R2 不复活 (spec "别复活" 一致), PHQ-9 分数 / 周报数字走 textStyleTitle/Headline。
  static const double fontSizeScoreLg = 24.0;
  static const double fontSizeScoreXl = 32.0;
  static const double fontSizeScoreXxl = 64.0;

  // v0.31 R2 (Apple Health redesign · 3.2.3): 行高改 Apple 紧凑
  // tight 1.2→1.1 (大字) / normal 1.5→1.4 (body) / loose 1.8→1.6 (long-form)
  // snug 1.4 / relaxed 1.6 保留 (R2 不动)
  static const double lineHeightTight = 1.1; // v0.31 R2: 1.2→1.1
  static const double lineHeightNormal = 1.4; // v0.31 R2: 1.5→1.4
  static const double lineHeightLoose = 1.6; // v0.31 R2: 1.8→1.6
  // v0.22 round 30 (emil P0-4): 中间档 — legal/邮件/条款正文 (1.4) + 长文/日记 (1.6)
  // 之前散落 14+ 处 `height: 1.X` 硬编码
  static const double lineHeightSnug = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // v0.31 R2 (Apple Health redesign · 3.2.2): 新增 2 档字重
  // ultralight w200 = Apple Health 大数字 (StatCard / AppleHealthTile 数字)
  // light w300 = 次大数字 / secondary 强调
  // 现有 w400/w500/w600/w700 保留 (R2 不动)
  static const FontWeight fontWeightUltralight = FontWeight.w200; // v0.31 R2 新增
  static const FontWeight fontWeightLight = FontWeight.w300; // v0.31 R2 新增

  // ============= TextStyle token (v0.22 round 30 / emil P0-4) =============
  //
  // v0.31 R2 新增 letterSpacing 阶梯 (3.2.4):
  // - 大字 (≥ 22pt) letterSpacing -0.5 (Apple SF Pro Display 收紧)
  // - 中字 (17-20pt) letterSpacing -0.2
  // - 小字 (≤ 14pt) letterSpacing 0
  //
  // 命名规则:
  //   textStyle{Size}{Weight?} = size + 重量
  //   末尾加 Strong = w600（默认是 w400）
  //   末尾加 Inverse = 用 onPrimary 颜色（按钮反白）
  //
  // 用法:
  // ```dart
  // Text('hello', style: AppTypography.textStyleBody(context))
  // ```
  //
  // 全部 dynamic（接受 BuildContext），color 走 theme-aware getter
  // → 修复 dark mode 文字色 + 行高不一致 + 减 60+ 处硬编码
  //
  // 注意: 不能在 const constructor 里用 (跟 const optimization 互斥, 同 AppColors.surfaceColor)

  /// 28/w700 页面大标题 (用于主屏 Greeting) — letterSpacing -0.5 (大字收紧)
  static TextStyle textStyleTitle(BuildContext context) => TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        letterSpacing: -0.5, // v0.31 R2: 大字 Apple SF Pro Display 收紧
        color: AppColors.textPrimaryColor(context),
      );

  /// 24/w700 副标题 — letterSpacing -0.5 (大字收紧)
  static TextStyle textStyleHeadline(BuildContext context) => TextStyle(
        fontSize: fontSizeHeadline,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        letterSpacing: -0.5, // v0.31 R2: 大字 Apple SF Pro Display 收紧
        color: AppColors.textPrimaryColor(context),
      );

  /// 17/w400 正文 (iOS body) — letterSpacing -0.2 (中字收紧)
  static TextStyle textStyleBody(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        letterSpacing: -0.2, // v0.31 R2: 中字收紧
        color: AppColors.textPrimaryColor(context),
      );

  /// 17/w600 正文加粗 (用于 trend summary 数字) — 不动 (R2 不改)
  static TextStyle textStyleBodyStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 15/w400 label/正文 (iOS subheadline) — letterSpacing 0 (小字)
  static TextStyle textStyleLabel(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        letterSpacing: 0, // v0.31 R2: 小字 0
        color: AppColors.textPrimaryColor(context),
      );

  /// 15/w600 label 加粗 (ListTile title / section header) — 不动 (R2 不改)
  static TextStyle textStyleLabelStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 17/w600 按钮文字 (iOS button standard) — letterSpacing -0.2 (中字收紧)
  static TextStyle textStyleButton(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        letterSpacing: -0.2, // v0.31 R2: 中字收紧
        color: AppColors.textPrimaryColor(context),
      );

  /// 17/w600 按钮反白 (onPrimary 底色按钮, 文字用 onPrimary 颜色) — 不动 (R2 不改)
  static TextStyle textStyleButtonInverse(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: Theme.of(context).colorScheme.onPrimary,
      );

  /// 13/w400 caption / 小字 / hint (iOS footnote) — letterSpacing 0 (小字)
  static TextStyle textStyleCaption(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        letterSpacing: 0, // v0.31 R2: 小字 0
        color: AppColors.textSecondaryColor(context),
      );

  /// 13/w600 caption 加粗 (dialog 标题 / 状态数字) — 不动 (R2 不改)
  static TextStyle textStyleCaptionStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 11/w400 微小字 (日历 cell / 微标签 / 趋势小数字) — letterSpacing 0 (小字)
  static TextStyle textStyleMicro(BuildContext context) => TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        letterSpacing: 0, // v0.31 R2: 小字 0
        color: AppColors.textSecondaryColor(context),
      );

  /// 15/w500 label medium (历史标题 / section header, 跟 w600 label strong 区分) — 不动 (R2 不改)
  static TextStyle textStyleLabelMedium(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w500,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 13/w400 caption + hint color (次要 hint 文字, 比 textStyleCaption 更弱) — 不动 (R2 不改)
  static TextStyle textStyleCaptionHint(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textHintColor(context),
      );

  /// 11/w400 法律/邮件/条款正文 (lineHeightSnug 1.4) — 不动 (R2 不改)
  static TextStyle textStyleLegal(BuildContext context) => TextStyle(
        fontSize: fontSizeCaptionSm,
        fontWeight: FontWeight.w400,
        height: lineHeightSnug,
        color: AppColors.textSecondaryColor(context),
      );

  // v0.25 round 50 (emil R50) 添加的 textStyleScoreLg / Xl / Xxl 在 v0.26 round 57
  // 修正中被清掉: 经全代码库 grep, 这 3 个集中器 0 处使用 (R57 subagent 漏做
  // inline TextStyle 替换)。如果未来需要 (PHQ-9 分数 / 周报数字), 优先用
  // textStyleTitle/Headline 而非加新集中器 — emil 原则: "good defaults matter
  // more than options", 集中器过多反而增加选择成本。

  /// v0.26 round 57 (emil EMIL-INC-03): monospace 集中器 — 不动 (R2 不改)
  /// 替代散落 3 处 `TextStyle(fontFamily: 'monospace', fontSize: 12)` 硬编
  /// 缺省 fontSize = fontSizeBodySm (12) — 接近代码阅读舒适尺寸
  /// 透传 size 给 3 个使用场景 (fontSizeBodySm 12 / fontSizeCaptionSm 11)
  static TextStyle textStyleMono(BuildContext context, {double? size}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size ?? fontSizeBodySm,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  // ============= v0.31 R2 (Apple Health redesign · 3.2.2): 3 档 metric 大数字 helper =============
  //
  // 用于 StatCard / AppleHealthTile / QuickMoodCarousel 等 Apple Health 标志性 ultralight 大数字。
  // 字重走 ultralight (w200), color 走 textPrimaryColor, height 走 tight 1.1 (大字紧凑)。
  //
  // - metricXl (34) = 主页大数字 (今日打卡数 / 评估分数)
  // - metricLg (28) = 次大数字 (周报 / 月度)
  // - metricMd (22) = 中等数字 (小卡片 / inline)

  /// 34/w200 ultralight Apple Health 大数字 (主页 / StatCard)
  static TextStyle textStyleMetricXl(BuildContext context) => TextStyle(
        fontSize: fontSizeMetricXl,
        fontWeight: fontWeightUltralight,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );

  /// 28/w200 ultralight Apple Health 次大数字 (StatCard large)
  static TextStyle textStyleMetricLg(BuildContext context) => TextStyle(
        fontSize: fontSizeMetricLg,
        fontWeight: fontWeightUltralight,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );

  /// 22/w200 ultralight Apple Health 中等数字 (inline / 小卡片)
  static TextStyle textStyleMetricMd(BuildContext context) => TextStyle(
        fontSize: fontSizeMetricMd,
        fontWeight: fontWeightUltralight,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );
}
