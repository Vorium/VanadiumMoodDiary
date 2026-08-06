// v0.30 round 95 (sub-spec 8 task 17): 提醒 group
//
// 用户档案 / 提醒 / 数据 / 法律 4 group 之一。包含原 3 个 section / 卡:
// - RemindersSection (提醒中心 + 续方管理)
// - CbtSection (思维记录档位)
// - NotificationStatusCard (通知自检 + 5 厂商 OEM 引导)
//
// 业务封装:
// - RemindersSection: 2 AppListTile (提醒中心 / 续方管理)
// - CbtSection: 3 选 1 RadioListTile<ThoughtRecordLevel>
// - NotificationStatusCard: 5 厂商 OEM 引导 + 测试通知 + 状态显示
//
// 模式 (R95 task 1 ConsumerWidget 模式 + onXxx callback 注入点):
// - ConsumerWidget 自包含
// - 接受 onReminderHubTap / onRefillTap / onCbtLevelChange 可选 callback
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/cbt_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 提醒 group — 提醒中心 + 续方管理 + 思维记录档位 + 通知自检
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 之一, 包原 RemindersSection
/// + CbtSection + NotificationStatusCard, 加 SectionHeader (跟原 settings_page 一致)。
///
/// 通知自检卡 (NotificationStatusCard) 挪到本 group 末尾 — emil 反复提的
/// 主页 header 3 icon button 0 tooltip / 通知自检卡 "在底部" 体验保持一致。
class RemindersGroup extends ConsumerWidget {
  const RemindersGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).settingsReminders,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        const RemindersSection(),
        // v0.29 round 84 (CBT 思维记录): 思维记录档位设置
        // 紧跟"提醒"主题 — 切档体验一致
        const SizedBox(height: AppTokens.spacingLg),
        const CbtSection(),
        const SizedBox(height: AppTokens.spacingLg),
        // 通知自检卡 (放本 group 末尾, 通知=reminders 主题相关)
        const NotificationStatusCard(),
      ],
    );
  }
}
