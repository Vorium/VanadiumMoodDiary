// v0.30 round 95 (sub-spec 8 task 17): 用户档案 group
//
// 用户档案 / 提醒 / 数据 / 法律 4 group 之一。包含原 3 个 section / 卡:
//   - 药物 section (medsAsync.when 渲染 MedicationsListWidget)
//   - 通知自检卡 (NotificationStatusCard)
//   - 心理评估 section (AssessmentSection)
//
// v1.0.0+147: 永久免费, 删商业卡整段 (workspace_premium)。
//
// 1.1.0 round 4: 联系人 section 整摘 (outbound contact 业务暂停定版)。
//
// v1.1.0 round 11 (R115 emotion-first): medication + assessment 整段挪到
// 新 HealthDataGroup (置顶), 本 group 只剩: 用户头像卡 + 心理技巧入口。
//
// 业务封装:
// - 用户头像卡: Apple Health Profile 风格
// - 心理技巧: 5 个本地正念/情绪调节技巧 → /tips
//
// 模式 (R95 task 1 ConsumerWidget 模式 + onXxx callback 注入点):
// - ConsumerWidget 自包含, 走 ref 自带 provider
// - 接受 onMedRetry 可选 callback (测试注入)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 用户档案 group — 用户头像卡 + 心理技巧入口
///
/// v0.30 round 95 (sub-spec 8 task 17): 4 group 之一, 包原 3 section。
/// v1.1.0 round 11 (R115): medication + assessment 段已挪到 HealthDataGroup
/// (置顶), 本 group 只剩 2 section。
class ProfileGroup extends ConsumerWidget {
  const ProfileGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // v0.30 R101: 用户头像/健康档案入口 (参照 Apple Health Profile)
        _UserProfileCard(l10n: l10n),

        const SizedBox(height: AppTokens.spacingMd),

        // === 心理技巧 (v1.1.0 论文落地 F3) ===
        // 本地正念/情绪调节技巧库入口 → /tips
        SectionHeader(title: l10n.psychoTipsTitle),
        const SizedBox(height: AppTokens.spacingSm),
        AppleListSection(
          margin: EdgeInsets.zero,
          children: [
            _alsCell(
              AppListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.self_improvement,
                  color: AppTokens.primaryColor(context),
                ),
                title: Text(l10n.psychoTipsTitle),
                subtitle: Text(l10n.psychoTipBreathSummary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tips'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingMd),
      ],
    );
  }
}

/// AppListTile 在 AppleListSection 白色容器内需包透明 Material
Widget _alsCell(Widget child) {
  return Material(type: MaterialType.transparency, child: child);
}

/// 用户头像/健康档案入口卡 (参照 Apple Health Profile)
///
/// v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card 改 AppleListSection
class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  AppTokens.primaryColor(context).withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 32,
                color: AppTokens.primaryColor(context),
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            // 用户名 + 描述
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsProfileTitle,
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.settingsProfileSubtitle,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            // v0.32 round 8 (R111 EM-17 fix): 删 chevron — 本卡是静态展示
            // (无 profile 路由可跳), chevron 假 affordance 误导可点
          ],
        ),
      ],
    );
  }
}
