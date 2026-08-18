// v0.24 round 47 (emil B-09): 2 处 PressFeedback+ListTile 改 AppListTile
// v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card → AppleListSection
// (iOS insetGrouped 风格: 0 阴影圆角白块 + hairline 0.5 分隔,
// 跟 home/setup/medication 样板一致, spec §4.5)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 提醒 section — 提醒中心 + 续方管理入口
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
///
/// v0.24 round 47 (emil B-09): 2 处 PressFeedback+ListTile 改 AppListTile
///
/// v0.32 round 13 (R112 EM-02/AH-04): Card 容器改 AppleListSection
/// (hairline Divider 由 AppleListSection 自动串联, 删手写 Divider;
/// AppListTile contentPadding 归零, 外边距由 AppleListSection cell padding 提供)
class RemindersSection extends StatelessWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        _alsCell(
          AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.notifications_active_outlined,
              color: AppTokens.primaryColor(context),
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
        ),
        _alsCell(
          AppListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.shopping_cart_outlined,
              color: AppTokens.primaryColor(context),
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
        ),
      ],
    );
  }
}

/// v0.32 round 13 (R112 EM-02/AH-04): ListTile 在 AppleListSection 的
/// 白色 DecoratedBox 容器内会触发 Flutter debug assert ("ListTile
/// background color or ink splashes may be invisible") — ListTile 的
/// ink 画在最近 Material 祖先上, 包一层透明 Material 让检查通过
/// (home/medication 样板用自定义 Row 无此问题)
Widget _alsCell(Widget child) {
  return Material(type: MaterialType.transparency, child: child);
}
