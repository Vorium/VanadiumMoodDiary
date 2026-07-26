import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 法律与隐私 section — 进入法律页入口
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: PressFeedback(
        onTap: () => context.push('/settings/legal'),
        child: ListTile(
          leading: const Icon(
            Icons.gavel_outlined,
            color: AppTokens.primary,
          ),
          title: Text(
            AppLocalizations.of(context).settingsLegalAndPrivacy,
          ),
          subtitle: Text(
            AppLocalizations.of(context).settingsLegalAndPrivacySubtitle,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
