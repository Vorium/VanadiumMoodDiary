import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 提醒 section — 提醒中心 + 续方管理入口
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
///
/// v0.24 round 47 (emil B-09): 2 处 PressFeedback+ListTile 改 AppListTile
class RemindersSection extends StatelessWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          AppListTile(
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: AppTokens.primary,
            ),
            title: Text(
              AppLocalizations.of(context).settingsReminderCenter,
            ),
            subtitle: Text(
              AppLocalizations.of(context).settingsReminderCenterSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/reminders'),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: const Icon(
              Icons.shopping_cart_outlined,
              color: AppTokens.primary,
            ),
            title: Text(
              AppLocalizations.of(context).settingsRefillManagement,
            ),
            subtitle: Text(
              AppLocalizations.of(context).settingsRefillManagementSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/refills'),
          ),
        ],
      ),
    );
  }
}
