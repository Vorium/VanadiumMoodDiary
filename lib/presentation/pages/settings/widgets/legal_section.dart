import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 法律与隐私 section — 进入法律页入口
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
///
/// v0.24 round 47 (emil B-09): 1 处 PressFeedback+ListTile 改 AppListTile
class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AppListTile(
        leading:Icon(
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
    );
  }
}
