// v1.1.0 论文落地 (F3 心理技巧知识库): TipsListPage
//
// 心理技巧列表页 — 展示 PsychologyTipsLibrary 全部技巧 (5 条):
// - AppleListSection 分组, 每条 AppListTile (icon + 本地化 title + summary)
// - 点击 → /tips/:id 详情
//
// 取数: 纯静态 domain 常量 (PsychologyTipsLibrary.all), 0 DB / 0 采集。
// 显示层 localize 走 preset_content_l10n.dart (localizedPsychologyTip)。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/psychology_tips_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 心理技巧列表页
class TipsListPage extends StatelessWidget {
  const TipsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.psychoTipsTitle,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingSm),
          AppleListSection(
            children: [
              for (final tip in PsychologyTipsLibrary.all)
                _alsCell(
                  AppListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.self_improvement,
                      color: AppTokens.primaryColor(context),
                    ),
                    title: Text(
                      localizedPsychologyTip(context, tip).title,
                    ),
                    subtitle: Text(
                      localizedPsychologyTip(context, tip).summary,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/tips/${tip.id}'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }
}

/// AppListTile 在 AppleListSection 白色容器内需包透明 Material
/// (ListTile ink 画在最近 Material 祖先上, 防 debug assert)
Widget _alsCell(Widget child) {
  return Material(type: MaterialType.transparency, child: child);
}
