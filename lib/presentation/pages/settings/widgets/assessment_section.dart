import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_reminder_section.dart';

/// 心理评估 section — 评估历史 + 周期提醒 + 量表列表 + 邮件预览 + 关于
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
///
/// v0.24 round 47 (emil B-09): 4 处 PressFeedback+ListTile 改 AppListTile 集中器
class AssessmentSection extends StatelessWidget {
  const AssessmentSection({super.key});

  static final List<AssessmentScale> _scales = allScales();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 评估历史入口
        Card(
          child: AppListTile(
            leading:
                Icon(Icons.history, color: AppTokens.primaryColor(context)),
            title: Text(
              AppLocalizations.of(context).settingsAssessmentHistory,
            ),
            subtitle: Text(
              AppLocalizations.of(context).settingsAssessmentHistorySubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/assessment/history'),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        // 评估周期提醒
        const AssessmentReminderSection(),
        const SizedBox(height: AppTokens.spacingSm),
        // 量表列表
        Card(
          child: Column(
            children: [
              for (int i = 0; i < _scales.length; i++) ...[
                AppListTile(
                  leading: Icon(
                    _scales[i].id == 'phq9'
                        ? Icons.psychology_outlined
                        : Icons.psychology_alt_outlined,
                    color: AppTokens.primaryColor(context),
                  ),
                  title: Text(_scales[i].displayName),
                  subtitle: Text(_scales[i].shortDescription),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/assessment/${_scales[i].id}'),
                ),
                if (i < _scales.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppTokens.spacingMd),

        // 邮件预览
        Card(
          child: AppListTile(
            leading: Icon(
              Icons.email_outlined,
              color: AppTokens.primaryColor(context),
            ),
            title: Text(AppLocalizations.of(context).settingsEmailPreview),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/email-preview'),
          ),
        ),

        const SizedBox(height: AppTokens.spacingMd),

        // 关于
        Card(
          child: AppListTile(
            leading: Icon(Icons.info_outline,
                color: AppTokens.primaryColor(context),),
            title: Text(AppLocalizations.of(context).settingsAbout),
            subtitle: Text(AppLocalizations.of(context).settingsAboutVersion),
          ),
        ),

        // 免责声明
        Card(
          child: AppListTile(
            leading: Icon(
              Icons.shield_outlined,
              color: AppTokens.textSecondaryColor(context),
            ),
            title: Text(AppLocalizations.of(context).settingsDisclaimer),
            subtitle: Text(
              AppLocalizations.of(context).settingsDisclaimerText,
            ),
          ),
        ),
      ],
    );
  }
}
