import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 副信息：最后吃药时间 / 下次提醒
class LastMedInfo extends StatelessWidget {
  final DateTime? lastCheckIn;
  final DateTime? nextReminder;
  final bool showStreakBroken;

  const LastMedInfo({
    super.key,
    required this.lastCheckIn,
    required this.nextReminder,
    required this.showStreakBroken,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showStreakBroken)
          Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMd,
              vertical: AppTokens.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppTokens.tintedWarningSoft(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: Text(
              AppLocalizations.of(context).homeStreakBroken,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ),
        if (lastCheckIn != null)
          Text(
            AppLocalizations.of(context)
                .homeLastMed(_formatDateTime(lastCheckIn!)),
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
        if (nextReminder != null) ...[
          const SizedBox(height: AppTokens.spacingXs),
          Text(
            AppLocalizations.of(context)
                .homeNextReminder(_formatTime(nextReminder!)),
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _formatTime(DateTime dt) {
    return '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
