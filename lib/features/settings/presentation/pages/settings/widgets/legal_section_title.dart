// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式):
// 抽 _SectionTitle 公开 widget — legal_page section 标题渲染
//
// 公开 widget 命名: _SectionTitle → LegalSectionTitle
// 提供 `super.key` 跟 project widget 集中器模式一致

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

/// legal_page section 标题渲染
///
/// 跟 project 其他 section title (SectionHeader, 集中器) 视觉对齐:
/// 字号 headline + 字重 w600 + text primary + 左 padding xs + 底 padding sm
class LegalSectionTitle extends StatelessWidget {
  final String text;
  const LegalSectionTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: AppTokens.spacingXs,
          bottom: AppTokens.spacingSm,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppTokens.fontSizeHeadline,
            fontWeight: FontWeight.w600,
            color: AppTokens.textPrimaryColor(context),
          ),
        ),
      );
}
