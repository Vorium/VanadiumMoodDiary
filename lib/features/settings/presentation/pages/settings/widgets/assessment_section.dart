// 心理评估 section — 评估历史 + 周期提醒 + 量表列表 + 邮件预览 + 关于
//
// 从 settings_page.dart 提取 (v0.23 P1 refactor)
//
// v0.24 round 47 (emil B-09): 4 处 PressFeedback+ListTile 改 AppListTile 集中器
//
// v0.32 round 13 (R112 EM-02/AH-04 视觉债): 4 处 Card 改 AppleListSection
// (iOS insetGrouped 风格, spec §4.5)。AssessmentReminderSection 是
// assessment feature 的 Card, 跨 feature 不动 (由该 feature 自转)。
// scaleNameL10n 调用是 R111 D agent 改的 l10n 派发, 原样保留。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/services/legal_version.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_reminder_section.dart';

class AssessmentSection extends StatelessWidget {
  const AssessmentSection({super.key});

  static final List<AssessmentScale> _scales = allScales();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // 评估历史入口
        AppleListSection(
          margin: EdgeInsets.zero,
          children: [
            _alsCell(
              AppListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.history, color: AppTokens.primaryColor(context)),
                title: Text(
                  AppLocalizations.of(context).settingsAssessmentHistory,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)
                      .settingsAssessmentHistorySubtitle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/assessment/history'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingSm),
        // 评估周期提醒 (assessment feature 的 Card, 跨 feature 不动)
        const AssessmentReminderSection(),
        const SizedBox(height: AppTokens.spacingSm),
        // 量表列表
        AppleListSection(
          margin: EdgeInsets.zero,
          children: [
            for (final scale in _scales)
              _alsCell(
                AppListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    scale.id == 'phq9'
                        ? Icons.psychology_outlined
                        : Icons.psychology_alt_outlined,
                    color: AppTokens.primaryColor(context),
                  ),
                  // v0.32 round 8 (R111 R111-02 fix): 走 l10n 派发
                  title: Text(scaleNameL10n(scale.id, l10n)),
                  subtitle: Text(scaleShortDescL10n(scale.id, l10n)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/assessment/${scale.id}'),
                ),
              ),
          ],
        ),

        // v0.30 round 90 (sub-spec 6 量表中心): 末尾加"打开量表中心"按钮
        // 走 FilledButton.tonalIcon + grid_view icon, 跟 settings 风格一致
        // v0.30 round 91 (fix): Task 6 漏改 widget, 补 l10n.assessmentCenterTitle
        const SizedBox(height: AppTokens.spacingSm),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.grid_view),
          label: Text(l10n.assessmentCenterTitle),
          onPressed: () => context.push('/assessment-center'),
        ),

        const SizedBox(height: AppTokens.spacingMd),

        // v0.30 round 95 (sub-spec 2 task 10): 删邮件预览入口 + EmailPreviewPage
        // (失联是 SMS 不是 email, R93 业务暂停后真无用)。原 entry 走
        // [FeatureFlags.emailServiceEnabled] gate 默认 false → SizedBox.shrink,
        // 实际从未显示; 业务上线时改 SMS 路径真接。

        const SizedBox(height: AppTokens.spacingMd),

        // 关于 + 免责声明 (2 个静态行, 无 onTap → AppListTile disabled)
        AppleListSection(
          margin: EdgeInsets.zero,
          children: [
            _alsCell(
              AppListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.info_outline,
                  color: AppTokens.primaryColor(context),
                ),
                title: Text(AppLocalizations.of(context).settingsAbout),
                subtitle: Text(
                  AppLocalizations.of(context)
                      .settingsAboutVersion(kPubspecVersion.split('+').first),
                ),
              ),
            ),
            _alsCell(
              AppListTile(
                contentPadding: EdgeInsets.zero,
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
        ),
      ],
    );
  }
}

/// v0.32 round 13 (R112 EM-02/AH-04): ListTile 在 AppleListSection 的
/// 白色 DecoratedBox 容器内会触发 Flutter debug assert ("ListTile
/// background color or ink splashes may be invisible") — 包一层透明
/// Material 让 ListTile ink 画在最近的 Material 祖先上
/// (home/medication 样板用自定义 Row 无此问题)
Widget _alsCell(Widget child) {
  return Material(type: MaterialType.transparency, child: child);
}
