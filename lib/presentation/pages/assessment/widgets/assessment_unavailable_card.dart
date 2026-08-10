// v0.30 round 90 (sub-spec 6 量表中心): NSESSS / CRDPSS unavailable 卡片
//
// 灰色 + 锁 icon + "需法务/临床审核" badge
// 走 surfaceVariant 50% opacity (M3 兼容 dark/light)
//
// 不在 scale_registry.allScales() 里 (TODO 状态), 卡片独立 widget 渲染,
// UI 提示用户"暂未开放"。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 不可用量表卡片 (NSESSS / CRDPSS — 收费 / 内部, 法务审核中)
class AssessmentUnavailableCard extends StatelessWidget {
  final String scaleId;
  const AssessmentUnavailableCard({super.key, required this.scaleId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      // M3 surfaceVariant 50% opacity 兼容 dark/light
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _displayName(scaleId),
                    style: AppTokens.textStyleTitle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              l10n.assessmentCenterNotAvailable,
              style: const TextStyle(fontSize: AppTokens.fontSizeLabelSm),
            ),
            Text(
              l10n.assessmentCenterComingSoon,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabelSm,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NSESSS / CRDPSS 的 fallback 显示名 (Task 6 走 ARB)
  ///
  /// scale_registry.unavailableScaleIds 里只放 'nsesss' / 'crdpss' 2 个 id,
  /// 但 NSESSS 量表实际英文缩写是 "NSESSS", 这里用 static const 集中映射,
  /// 后续 ARB 加 nsesssName / crdpssName 后走 translations.
  String _displayName(String id) {
    switch (id) {
      case 'nsesss':
        return 'NSESSS PTSD';
      case 'crdpss':
        return 'CRDPSS';
      default:
        return id;
    }
  }
}
