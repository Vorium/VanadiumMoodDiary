// v0.24 round 47 (emil B-09): 1 处 PressFeedback+ListTile 改 AppListTile
// v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card → AppleListSection
// (iOS insetGrouped 风格, spec §4.5)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 法律与隐私 section — 进入法律页入口
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
///
/// v0.24 round 47 (emil B-09): 1 处 PressFeedback+ListTile 改 AppListTile
///
/// v0.32 round 13 (R112 EM-02/AH-04): Card 容器改 AppleListSection,
/// AppListTile contentPadding 归零 (cell padding 由 AppleListSection 提供)
class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        // v0.32 round 13: 透明 Material 包 ListTile, 防 Flutter debug assert
        // (ListTile 在 AppleListSection 白色 DecoratedBox 容器内 ink 不可见)
        Material(
          type: MaterialType.transparency,
          child: AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.gavel_outlined,
              color: AppTokens.primaryColor(context),
            ),
            title: Text(
              AppLocalizations.of(context).settingsLegalAndPrivacy,
            ),
            subtitle: Text(
              AppLocalizations.of(context).settingsLegalAndPrivacySubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/legal'),
          ),
        ),
      ],
    );
  }
}
