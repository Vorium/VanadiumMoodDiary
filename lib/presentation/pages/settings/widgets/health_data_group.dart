// v1.1.0 round 11 (R115 视觉重构): 健康数据 group — 升入设置页顶部
//
// 历史:
// - v0.30 R95 4 group 拼装: ProfileGroup (用户档案) / RemindersGroup / DataGroup / LegalGroup
//   当时 medication + assessment 在 ProfileGroup, 跟 user profile 混在一起。
// - v1.1.0 round 11 (R115): emotion-first refactor 续作 — medication + assessment
//   从 ProfileGroup 抽出, 升入新 group「健康数据」, 置顶。理由:
//   1. Product positioning: 用药 + 评估是「次主功能」, 跟主功能 (心情/树洞) 平级
//   2. 入口弱化但仍可达: 跟 Home 「更多」BottomSheet 互为冗余, 用户能搜到
//   3. 视觉对称: 4 group 改 5 group, 顶部是数据入口, 底部是隐私
//
// 5 group 顺序 (R115):
// 1. HealthDataGroup (新) — 用药 / 心理评估, 加副标题
// 2. ProfileGroup — 个人资料 (只保留头像卡, 删 medication/assessment 段)
// 3. RemindersGroup — 提醒 + CBT 思维记录 + 通知自检
// 4. DataGroup — 导出/报告/历史/导入/清空
// 5. LegalGroup — 法律与隐私
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 健康数据 group — 用药 + 心理评估, 设置页置顶
///
/// v1.1.0 round 11 (R115): emotion-first refactor 续作 — 主页第一屏不再
/// 出现「用药」「量表」字样, 但用户仍可在设置页直达。副标题动态显示当前
/// 状态 (3 种药物 · 2/3 已服 / 8 个量表)。
class HealthDataGroup extends ConsumerWidget {
  const HealthDataGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // 实时计算 2 个副标题
    final meds = ref.watch(medicationsProvider).value ?? const <MedicationEntity>[];
    final activeMeds = meds.where((m) => m.isInUse).toList();
    final checkIns =
        ref.watch(todayAllCheckInsProvider).value ?? const <CheckInEntity>[];
    final todayMedIds = <int>{};
    for (final c in checkIns) {
      if (c.isNormal && c.medicationId != null) {
        todayMedIds.add(c.medicationId!);
      }
    }
    final assessments = ref.watch(assessmentsProvider).value ??
        const <CheckInEntity>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.settingsHealthData), // "健康数据" / "Health data"
        const SizedBox(height: AppTokens.spacingSm),
        AppleListSection(
          margin: EdgeInsets.zero,
          children: [
            // 用药管理
            _Cell(
              context: context,
              leadingIcon: Icons.medication_outlined,
              leadingColor: const Color(0xFFFF3B30), // iOS systemRed
              title: l10n.settingsMedication, // "常吃药" / "Medications"
              subtitle: activeMeds.isEmpty
                  ? '—'
                  : l10n.settingsHealthDataMedSub(
                      activeMeds.length, todayMedIds.length),
              onTap: () => context.push('/medication'),
            ),
            // 心理评估
            _Cell(
              context: context,
              leadingIcon: Icons.assignment_outlined,
              leadingColor: const Color(0xFF5E5CE6), // iOS systemIndigo
              title: l10n.settingsAssessment, // "心理评估" / "Assessment"
              subtitle: l10n.settingsHealthDataAssSub(assessments.length),
              onTap: () => context.push('/assessment-center'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.context,
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final BuildContext context;
  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: leadingColor,
          borderRadius: BorderRadius.circular(AppTokens.spacingXs),
        ),
        child: Icon(leadingIcon, color: Colors.white, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: AppTokens.textStyleCaption(context).copyWith(
          color: AppTokens.textHintColor(context),
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
