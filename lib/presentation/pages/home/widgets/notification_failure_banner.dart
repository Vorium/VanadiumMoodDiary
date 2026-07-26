import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// v0.18 round 14 (P1-21): 通知初始化失败时显示的顶部 banner
///
/// P17 fix: 用户点了主打卡按钮 = 信任 app 在后台提醒。提醒没设上必须
/// 让用户知道。显示原因 + "去系统设置"按钮 + 可关闭。
///
/// 之前是 _NotificationFailureBanner 内联在 home_page.dart(300+ 行 private
/// widget),现在抽到 home/widgets/ 下，方便复用 + 让 home_page god-page
/// 减肥(P1-27 配套)。
class NotificationFailureBanner extends StatefulWidget {
  final String? error;
  const NotificationFailureBanner({super.key, this.error});

  @override
  State<NotificationFailureBanner> createState() =>
      _NotificationFailureBannerState();
}

class _NotificationFailureBannerState extends State<NotificationFailureBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spacingSm),
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppTokens.tintedWarningSoft(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.tintedWarningBorder(context)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppTokens.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).homeNotifBannerText,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => setState(() => _dismissed = true),
            tooltip: AppLocalizations.of(context).homeNotifBannerDismiss,
          ),
        ],
      ),
    );
  }
}
