// v0.30 round 91 (sub-spec 7 日常追踪 / Task 5 整合入口): 7 卡片通用 widget
//
// - title (子功能名) + lastValue ("上次 X" 摘要, 可空)
// - tap card → push 子功能 route
// - 跟 R90 assessment_center_card 1:1 同模式 (Card + InkWell + Padding
//   + Column title/Spacer/lastValue/FilledButton.tonal)
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
//
// 用法 (Task 5 daily_tracking_page):
// - 7 张卡片共享本 widget, 每张传 title + route + lastValue
// - 整合页 i18n placeholder (Task 7 一次性换 5 string placeholder)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 7 卡片通用 widget (整合入口页用)
///
/// - [title]: 子功能名 (e.g. "情绪日记" / "睡眠" / "体重")
/// - [route]: tap card 跳子功能 route (e.g. "/mood-diary" / "/sleep")
/// - [lastValue]: "上次记录" 摘要 (e.g. "4/5 (早)"), null 时显示 fallback 文案
///
/// R90 assessment_center_card 1:1 同结构, 简化版 (R90 有 score severity badge
/// / format time, 本 widget 简化为单一 lastValue 字符串 — 各子功能 lastValue
/// 格式差异大, 整合页 caller 自己 format)。
class DailyTrackingCard extends StatelessWidget {
  final String title;
  final String route;
  final String? lastValue;

  const DailyTrackingCard({
    super.key,
    required this.title,
    required this.route,
    this.lastValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 子功能名 (大) — 跟 R90 同款
              Text(
                title,
                style: AppTokens.textStyleTitle(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // 上次记录 (caption) — null 时显示 fallback
              Text(
                lastValue ?? '尚未记录',
                style: AppTokens.textStyleCaption(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTokens.spacingXs),
              // CTA 按钮 (走 FilledButton.tonal, 跟 R90 卡片风格一致)
              FilledButton.tonal(
                onPressed: () => context.push(route),
                child: const Text('记录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
