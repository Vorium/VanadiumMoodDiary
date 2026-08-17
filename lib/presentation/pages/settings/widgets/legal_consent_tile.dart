// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式):
// 抽 _ConsentTile 公开 widget — legal_page 撤回同意 toggle 行
//
// 公开 widget 命名: _ConsentTile → LegalConsentTile
// v0.30 R95 sub-spec 8 task 46: legal_page toggle 撤回时间 chip 标识
// (B 站风格 chip 标签, emil design 反复提 — 状态时间需有视觉标识,
// withdrawn 状态用 error 色 chip 强调, 正常状态用 hint 色 chip 低调)

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';

/// legal_page 撤回同意 toggle 行 (vent / analytics)
///
/// [withdrawn] = true → 红色 chip + 撤回时间显示
/// [withdrawn] = false → 灰色 chip + "从未撤回" 文字
class LegalConsentTile extends StatelessWidget {
  final ConsentKind kind;
  final String title;
  final String subtitle;
  final bool withdrawn;
  final DateTime? withdrawnAt;
  final ValueChanged<bool> onToggle;

  const LegalConsentTile({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.withdrawn,
    required this.withdrawnAt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeText = withdrawnAt == null
        ? l10n.legalPageConsentNever
        : l10n.legalPageConsentRecorded(
            '${withdrawnAt!.year.toString().padLeft(4, '0')}-'
            '${withdrawnAt!.month.toString().padLeft(2, '0')}-'
            '${withdrawnAt!.day.toString().padLeft(2, '0')} '
            '${withdrawnAt!.hour.toString().padLeft(2, '0')}:'
            '${withdrawnAt!.minute.toString().padLeft(2, '0')}',
          );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTokens.textStyleLabelMedium(context),
                    ),
                    const SizedBox(height: AppTokens.spacingXxs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeCaptionSm,
                        color: AppTokens.textHintColor(context),
                        height: AppTokens.lineHeightSnug,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: withdrawn,
                onChanged: onToggle,
                activeThumbColor: AppTokens.errorColor(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
            child: Chip(
              label: Text(
                timeText,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeLabelSm,
                  color: withdrawn
                      ? AppTokens.fgOnError(context)
                      : AppTokens.textHintColor(context),
                ),
              ),
              backgroundColor: withdrawn
                  ? AppTokens.tintedErrorSoft(context)
                  : AppTokens.dividerColor(context),
              side: BorderSide(
                color: withdrawn
                    ? AppTokens.errorColor(context)
                    : AppTokens.textHintColor(context),
                width: 0.5,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXs,
                vertical: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
