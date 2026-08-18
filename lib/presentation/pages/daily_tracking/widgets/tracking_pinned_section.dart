// gdc R128e audit 2026-08-18: 抽 _PinnedSection (原 daily_tracking_page.dart:289-345,
// 96L private) → public widget, 让其他 page 也能复用 (例如 settings customize page)。
//
// 收藏区 — 横向滚动的追踪卡片, 卡片自 watch 自己的流 (R110 round 7a 子树隔离)。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';

/// 收藏区 (横向滚动卡片) — 卡片自 watch 自己的流
class TrackingPinnedSection extends StatelessWidget {
  final List<DailyTrackingItemConfig> items;

  const TrackingPinnedSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppTokens.spacingXs,
            left: AppTokens.spacingXxs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                size: 14,
                color: AppTokens.textHintColor(context),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.trackingPinned,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTokens.textHintColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTokens.spacingSm),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 260,
                child: TrackingItemCard(
                  config: item,
                  onRecord: () => context.push(item.route),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}