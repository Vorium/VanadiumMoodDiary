// v1.1.0 论文落地 (F3 心理技巧知识库): TipsDetailPage
//
// 技巧详情页 — 单条技巧: 标题 + 摘要 + 步骤 (编号列表):
// - PageScaffold title = 本地化技巧标题
// - AppleListSection 显示摘要 + 步骤 (每步带序号圆点)
//
// 取数: 路由 /tips/:id → PsychologyTipsLibrary.byId, 未知 id 走 error state。
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/logic/psychology_tips_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 心理技巧详情页
class TipsDetailPage extends StatelessWidget {
  const TipsDetailPage({super.key, required this.tipId});

  final String tipId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tip = PsychologyTipsLibrary.byId(tipId);
    if (tip == null) {
      return PageScaffold(
        title: l10n.psychoTipsTitle,
        child: Center(
          child: Text(
            l10n.commonLoadFailed(tipId),
            style: AppTokens.textStyleCaption(context),
          ),
        ),
      );
    }
    final localized = localizedPsychologyTip(context, tip);
    return PageScaffold(
      title: localized.title,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingSm),
          AppleListSection(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
                child: Text(
                  localized.summary,
                  style: AppTokens.textStyleBody(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
          AppleListSection(
            title: l10n.psychoTipsTitle,
            children: [
              for (var i = 0; i < localized.steps.length; i++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 步骤序号圆点
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTokens.primaryColor(context).withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeCaptionSm,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.primaryColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Expanded(
                      child: Text(
                        localized.steps[i],
                        style: AppTokens.textStyleBody(context),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}
