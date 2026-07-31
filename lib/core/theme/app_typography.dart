// v0.27 round 65 (alibaba B16 god constant 拆分): 字体 + TextStyle token 独立
//
// 拆解前: app_tokens.dart 644 行 8 大类混合。R65 拆 4 文件, 字体 + 行高 +
// TextStyle helper 13 个全部在本文件。app_tokens.dart 留 facade re-export。
//
// 设计原则:
// - fontSize + lineHeight 走 const, 可在 const constructor 用
// - textStyleXxx 走 dynamic (接受 BuildContext), color 走 AppColors.dynamic getter
// - 老 caller 兼容: `AppTokens.fontSizeBody` 仍能用 (走 facade)
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// v0.27 round 65 (alibaba B16 god constant 拆分): 字体 + TextStyle token 集中器
///
/// 3 大类:
/// 1. **静态 fontSize** (14 个, 跟 design system 8/10/12/14/16/18/20/24/32/64 对齐)
/// 2. **静态 lineHeight** (5 个, 1.2/1.4/1.5/1.6/1.8 适配 5 类内容)
/// 3. **TextStyle helper** (13 个, dynamic, color 走 AppColors dynamic getter)
class AppTypography {
  AppTypography._();

  // ============= 字体 =============
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeButton = 20.0;
  static const double fontSizeBody = 18.0;
  static const double fontSizeLabel = 16.0;
  static const double fontSizeCaption = 14.0;
  // v0.22 round 29 (emil-16): 微小字 (10 / 8) 集中器, 日历 cell + 小标签统一
  static const double fontSizeMicro = 10.0;
  static const double fontSizeXxxSmall = 8.0;

  // v0.22 round 36 (emil 7.2): 中间档 + score 数字集中器
  // 11 / 12 / 13 是 Body / Label / Caption 之间的过渡尺寸
  // 24 / 32 / 64 是 3 个大数字 score (评估 24h / 周报 / 季度)
  static const double fontSizeBodySm = 13.0;
  static const double fontSizeCaptionSm = 12.0;
  static const double fontSizeLabelSm = 11.0;
  static const double fontSizeScoreLg = 24.0;
  static const double fontSizeScoreXl = 32.0;
  static const double fontSizeScoreXxl = 64.0;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightLoose = 1.8;
  // v0.22 round 30 (emil P0-4): 中间档 — legal/邮件/条款正文 (1.4) + 长文/日记 (1.6)
  // 之前散落 14+ 处 `height: 1.X` 硬编码
  static const double lineHeightSnug = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // ============= TextStyle token (v0.22 round 30 / emil P0-4) =============
  //
  // **架构级修复**: 之前 60+ 处直接 `TextStyle(fontSize, fontWeight, height)`
  // 散在 trend / assessment / medication / settings 等 8+ page。
  // 跟动效 token 化水平严重不匹配（动效 85%，文字 40%）。
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

  /// 28/w700 页面大标题 (用于主屏 Greeting)
  static TextStyle textStyleTitle(BuildContext context) => TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );

  /// 24/w700 副标题
  static TextStyle textStyleHeadline(BuildContext context) => TextStyle(
        fontSize: fontSizeHeadline,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );

  /// 18/w400 正文
  static TextStyle textStyleBody(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 18/w600 正文加粗 (用于 trend summary 数字)
  static TextStyle textStyleBodyStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 16/w400 label/正文
  static TextStyle textStyleLabel(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 16/w600 label 加粗 (ListTile title / section header)
  static TextStyle textStyleLabelStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 20/w600 按钮文字
  static TextStyle textStyleButton(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: AppColors.textPrimaryColor(context),
      );

  /// 20/w600 按钮反白 (onPrimary 底色按钮, 文字用 onPrimary 颜色)
  static TextStyle textStyleButtonInverse(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: Theme.of(context).colorScheme.onPrimary,
      );

  /// 14/w400 caption / 小字 / hint
  static TextStyle textStyleCaption(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textSecondaryColor(context),
      );

  /// 14/w600 caption 加粗 (dialog 标题 / 状态数字)
  static TextStyle textStyleCaptionStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// 10/w400 微小字 (日历 cell / 微标签 / 趋势小数字)
  static TextStyle textStyleMicro(BuildContext context) => TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textSecondaryColor(context),
      );

  /// v0.23 (P0-3 emil): 16/w500 label medium (历史标题 / section header
  /// 之前用 (fontSizeLabel + w500) 直拼, 跟 w600 label strong 区分)
  static TextStyle textStyleLabelMedium(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w500,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );

  /// v0.23 (P0-3 emil): 14/w400 caption + hint color (次要 hint 文字, 比
  /// textStyleCaption 更弱的提示, 例 "上次回答 X 月 X 日")
  static TextStyle textStyleCaptionHint(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: AppColors.textHintColor(context),
      );

  /// 12/w400 法律/邮件/条款正文 (lineHeightSnug 1.4)
  /// 替代散落 8+ 处 `TextStyle(fontSize: 12, height: 1.4)`
  /// v0.24 round 46: 内部 `fontSize: 12` 改 `fontSizeCaptionSm` (复用既有 token, 不另造 fontSizeLegal)
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

  /// v0.26 round 57 (emil EMIL-INC-03): monospace 集中器
  /// 替代散落 3 处 `TextStyle(fontFamily: 'monospace', fontSize: 12)` 硬编
  /// 缺省 fontSize = fontSizeBodySm (13) — 接近代码阅读舒适尺寸
  /// 透传 size 给 3 个使用场景 (fontSizeBodySm 13 / fontSizeCaptionSm 12)
  static TextStyle textStyleMono(BuildContext context, {double? size}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: size ?? fontSizeBodySm,
        height: lineHeightNormal,
        color: AppColors.textPrimaryColor(context),
      );
}
