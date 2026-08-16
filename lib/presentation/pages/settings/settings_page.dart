// v0.30 round 95 (sub-spec 8 task 17): 拆 settings_page 4 group
//
// 历史:
// - v0.22 (R30 P1-38): 713 → ~80 行
// - v0.23 (R41 P1-38): 6 section 抽 widgets/, 主壳 ~80 行
// - v0.30 (R95 sub-spec 8 task 17): 4 group 拼装, 主壳 ~70 行
// - v1.1.0 round 11 (R115): 4 group → 5 group, 升入「健康数据」置顶
//
// 5 group (R115 顺序, emotion-first):
// 1. HealthDataGroup (新): 用药管理 + 心理评估, 升入顶部 (跟 Home 「更多」入口互为冗余)
// 2. ProfileGroup: 头像卡 + 心理技巧入口 (删 medication/assessment/CBT, 已挪走)
// 3. RemindersGroup: 提醒 + CBT 思维记录 + 通知自检
// 4. DataGroup: 导出/报告/历史/导入/清空
// 5. LegalGroup: 法律与隐私
//
// 业务逻辑全在 5 group 子文件, 本文件纯拼装 + 顶部 spacing。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/health_data_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/profile_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_group.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 设置页
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 拼装主壳, ~70 行, 0 业务方法。
/// v1.1.0 round 11 (R115): 4 → 5 group, HealthDataGroup 置顶。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: AppLocalizations.of(context).settingsTitle,
      child: ListView(
        children: const [
          SizedBox(height: AppTokens.spacingMd),
          // v1.1.0 round 11 (R115): 健康数据置顶 — medication + assessment
          // 从 ProfileGroup 抽出, 升入新 group。跟 Home 「更多」入口互为冗余。
          HealthDataGroup(),
          SizedBox(height: AppTokens.spacingMd),
          ProfileGroup(),
          SizedBox(height: AppTokens.spacingMd),
          RemindersGroup(),
          SizedBox(height: AppTokens.spacingMd),
          DataGroup(),
          SizedBox(height: AppTokens.spacingMd),
          LegalGroup(),
          SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }
}
