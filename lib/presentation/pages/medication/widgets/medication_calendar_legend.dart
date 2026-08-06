// v0.30 round 93 (audit-fixes task 1.4): MedicationCalendarLegend
// 拆 medication_calendar_page.dart god page 第 3 步
// - 颜色图例 widget: 4 个色块 (漏服 / < 50% / < 100% / 100%) + 文字
// - 走 l10n 集中器 (medsCalendarLegend* 4 个 key × 3 lang)
// - 之前在 medication_calendar_page._Legend L375-436 内联, 62 行
// - 之前 _LegendInline (Step 1.2 临时 wrapper) 75 行
//
// R92 props callback 模式: 无 props, 纯 stateless 渲染
// (颜色取自 token, 文案取自 l10n, 跟主题/语言切换一致)

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 用药日历颜色图例 widget
///
/// 显示 4 种颜色编码对应的依从率:
/// - 漏服 (灰, ratio = 0)
/// - < 50% (浅橙, 0 < ratio < 0.5)
/// - < 100% (almost, 0.5 ≤ ratio < 1)
/// - 100% (深绿, ratio = 1)
///
/// 父 widget 负责传 BuildContext 让 l10n 解析。
/// 本 widget 无 state, 无 callback, 是纯渲染 widget。
class MedicationCalendarLegend extends StatelessWidget {
  const MedicationCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingSm),
        child: Row(
          children: [
            Text(
              l10n.medsCalendarLegendLabel,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            _legendItem(
              context,
              color: AppTokens.dividerColor(context),
              label: l10n.medsCalendarLegendMissed,
            ),
            _legendItem(
              context,
              color: AppTokens.adherencePartial,
              label: l10n.medsCalendarLegendPartial,
            ),
            _legendItem(
              context,
              color: AppTokens.adherenceAlmost,
              label: l10n.medsCalendarLegendAlmost,
            ),
            _legendItem(
              context,
              color: AppTokens.primaryColor(context),
              label: l10n.medsCalendarLegendFull,
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTokens.spacingSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppTokens.legendDotSizeLg,
            height: AppTokens.legendDotSizeLg,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTokens.radiusCell),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXxs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeMicro,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
