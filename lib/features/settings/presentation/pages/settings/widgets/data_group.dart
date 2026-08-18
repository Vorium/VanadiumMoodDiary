// v0.30 round 95 (sub-spec 8 task 17): 数据 group
//
// 用户档案 / 提醒 / 数据 / 法律 4 group 之一 (emil 反复提, 主页信息架构
// 重排一致思路)。包含原 1 个 section: DataManagementSection
// (R95 sub-spec 1 已拆 6 sub-tile, 主壳 49 行)。
//
// 业务封装:
// - DataManagementSection: 6 sub-tile (export / cbt_pdf / report / history /
//   import / clear), 主壳 49 行 0 业务方法, R95 sub-spec 1 终点
// - data_group 主壳再包 SectionHeader, 不加任何业务方法
//
// 模式 (R95 task 1 ConsumerWidget 模式 + onXxx callback 注入点):
// - ConsumerWidget 自包含, 走 ref 自带 provider
// - 接受 onExport / onImport / onClear 等可选 callback (测试可注入)
// - 默认走 DataManagementSection 内部完整流
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 数据 group — 数据管理 section
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 之一, 包原
/// DataManagementSection, 加 SectionHeader (跟原 settings_page 一致)。
class DataGroup extends ConsumerWidget {
  const DataGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).settingsDataManagement,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        const DataManagementSection(),
      ],
    );
  }
}
