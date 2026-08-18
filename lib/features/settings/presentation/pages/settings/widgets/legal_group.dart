// v0.30 round 95 (sub-spec 8 task 17): 法律 group
//
// 用户档案 / 提醒 / 数据 / 法律 4 group 之一。包含原 1 个 section:
// LegalSection (进入 /settings/legal 页面入口)。
//
// 业务封装:
// - LegalSection: 1 个 AppListTile, 跳 /settings/legal 法律页
// - legal_group 主壳再包 SectionHeader, 不加任何业务方法
//
// 模式 (R95 task 1 ConsumerWidget 模式 + onXxx callback 注入点):
// - ConsumerWidget 自包含
// - 接受 onTapLegal 可选 callback (测试可注入跳自定义页)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 法律 group — 法律与隐私 section
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 之一, 包原 LegalSection,
/// 加 SectionHeader (跟原 settings_page 一致)。
class LegalGroup extends ConsumerWidget {
  const LegalGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context).settingsLegalAndPrivacy,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        const LegalSection(),
      ],
    );
  }
}
