import 'package:flutter/material.dart';

import '../../../../theme/app_tokens.dart';

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
              color: AppTokens.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: const Text(
              '少 1 次没关系，明天继续 🌱',
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.textSecondary,
              ),
            ),
          ),
        if (lastCheckIn != null)
          Text(
            '最后吃药：${_formatDateTime(lastCheckIn!)}',
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
        if (nextReminder != null) ...[
          const SizedBox(height: AppTokens.spacingXs),
          Text(
            '下次提醒：${_formatTime(nextReminder!)}',
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
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
