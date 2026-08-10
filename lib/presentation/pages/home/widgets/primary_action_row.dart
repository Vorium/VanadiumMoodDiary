// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// PrimaryActionRow 重设
//
// 历史:
// - v0.18 round 18 (P1-27): 从 home_page 抽出
// - v0.21 Round 22 (P0-9): PressFeedback 集中器
//
// v0.31 R9a 改造 (Apple Health "快捷操作" 2x2 彩色 tile 网格):
// - AppleListSection("快捷操作") 包装 (iOS 群组列表风格)
// - 2x2 AppleHealthTile 网格: medication(red) / mood(pink) / vent(purple) /
//   assessment(indigo) — 4 个 Apple Health "favorites" 彩色 metric 模块
// - 间距 12 (spacingSm) — 2x2 tile 紧凑布局
// - onTap 走 caller 决定的路由 (本 widget 不 hardcode context.push, 让 home_page
//   注入 onXxxTap 回调, 跟其他 widget 模式一致)
//
// 设计选择:
// - 4 个 tile 各 1 个 metric: spec §3.1.3 表映射, 4 个核心 feature 入口
// - 删了原 temp med / snooze SecondaryButton: 不在 Apple Health 仪表盘风格内
//   (snooze 5min 是次要动作, 后续如需可在 "更多" 区块加)
// - CheckInButton 巨型 pill 移到 build 段单独 1 个 section (跟 spec §5.1 1:1),
//   不再藏在 PrimaryActionRow 内
// - 4 个 tile label / value 暂时 hardcode 中文 (Phase 5 会通过 ARB 正式化, 本 task
//   不允许动 l10n 文件, 见 plan §I)

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 主页"快捷操作" 2x2 Apple Health 彩色 tile 网格
///
/// v0.31 R9a: 4 个 AppleHealthTile 替代原 3 个 button column
/// (CheckIn / TempMed / Snooze)。
class PrimaryActionRow extends StatelessWidget {
  final VoidCallback onMedicationTap;
  final VoidCallback onMoodTap;
  final VoidCallback onVentTap;
  final VoidCallback onAssessmentTap;

  const PrimaryActionRow({
    super.key,
    required this.onMedicationTap,
    required this.onMoodTap,
    required this.onVentTap,
    required this.onAssessmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppleListSection(
      title: l10n.medQuickActions, // "快捷操作" / "Quick Actions"
      margin: EdgeInsets.zero,
      children: [
        // 2x2 AppleHealthTile 网格
        IntrinsicHeight(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'medication',
                      // TODO(Phase 5): 用 ARB key 替换 hardcode
                      label: '用药',
                      value: '查看',
                      onTap: onMedicationTap,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'mood',
                      label: '心情',
                      value: '记录',
                      onTap: onMoodTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'vent',
                      label: l10n.homeVentButton.replaceAll(' 🌲', ''), // "树洞"
                      value: '倾诉',
                      onTap: onVentTap,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'assessment',
                      label: '评估',
                      value: '开始',
                      onTap: onAssessmentTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
