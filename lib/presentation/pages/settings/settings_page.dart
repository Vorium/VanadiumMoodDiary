// v0.30 round 95 (sub-spec 8 task 17): 拆 settings_page 4 group
//
// 历史:
// - v0.22 (R30 P1-38): 713 → ~80 行
// - v0.23 (R41 P1-38): 6 section 抽 widgets/, 主壳 ~80 行
// - v0.30 (R95 sub-spec 8 task 17): 4 group 拼装, 主壳 ~70 行
//
// 4 group (emil "信息架构重排一致思路"):
// - ProfileGroup (用户档案): 药物 + 通知自检 + 心理评估 + 联系人
// - RemindersGroup (提醒): 提醒 + CBT 思维记录
// - DataGroup (数据): 数据管理
// - LegalGroup (法律): 法律与隐私
//
// 业务逻辑全在 4 group 子文件, 本文件纯拼装 + 顶部 spacing。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/profile_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_group.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 设置页
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 拼装主壳, ~70 行, 0 业务方法。
/// 4 group 各自 widget 内部 ConsumerWidget 自包含完整流程, 测试可注入回调。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageScaffold(
      title: AppLocalizations.of(context).settingsTitle,
      child: ListView(
        children: const [
          SizedBox(height: AppTokens.spacingMd),
          ProfileGroup(),
          // v0.32 round 13 (R112 EM-02/AH-04): spacingLg → spacingMd
          // (跟 home AppleListSection 章节间距 16 一致, spec §5.1)
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
