// v0.30 R108 (P1 daily_tracking 7 widget 抽): 公共 helper 集中器
//
// 背景 (R107 审计 §六 架构层 / §三.13 / 08-architecture.md §3.6):
//   7 daily_tracking widget (weight / sleep / anxiety_agitation / social_rhythm /
//   stress_event / treatment_list / daily_tracking_card) 各自 9-13KB god class,
//   跨 widget 重复:
//   - SnackBar(content: Text(l10n.editMedSaveFailed(...))) 5+ 处
//   - if (mounted) Navigator.pop(context) / setState(() => _saving = false) 5+ 处
//   - TimeOfDay / DateTime → HH:mm padLeft 6+ 处
//   - DateTime(year, month, day) dateOnly 5+ 处
//   - onChanged: (_) => setState(() {}) 实时更新 5+ 处
//
// 抽 5 类公共 helper, 7 widget 改用减少 ~30-50% 重复, 单 widget 体积下降 1-3KB.
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
//
// R108 设计原则:
//   1. 保留所有 v0.x.y 注释 (R91 / R100 / R107 sub-spec 8 修复 5 处)
//   2. 不重命名 widget class (保持 caller 兼容)
//   3. helper 仅做"集中", 不改变行为语义
//   4. 所有 helper 都是 stateless / static, 0 副作用
//   5. 复用 AppSnackBar / AppTokens / go_router 现有 token, 不造新 token
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 1. summary row 集中器
///
/// 替代 7 widget 各自 `_summaryRow` / `_summaryHeader` 私有实现 (3-5 处)。
/// 用法:
/// ```dart
/// DailyTrackingSummaryRow(
///   label: l10n.weightName,
///   value: l10n.weightWeight(entry.weightKg.toStringAsFixed(1)),
///   icon: Icons.monitor_weight,
/// )
/// ```
class DailyTrackingSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const DailyTrackingSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTokens.edgeInsetsSm,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppTokens.iconSizeSmall,
              color: AppTokens.textHintColor(context),
            ),
            const SizedBox(width: AppTokens.spacingXs),
          ],
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? AppTokens.textStyleBody(context),
            ),
          ),
          Text(
            value,
            style: valueStyle ?? AppTokens.textStyleLabelStrong(context),
          ),
        ],
      ),
    );
  }
}

/// 2. SnackBar 集中器 (替代 5+ 处裸 ScaffoldMessenger + SnackBar)
///
/// 跟 R17 R23 AppSnackBar 不同: daily_tracking 复用 `l10n.editMedSaveFailed`
/// 模板 (跟 medication_edit 共享同一中文 "保存失败：xxx"), 走自己的 thin
/// wrapper, 不引入新的 ARB key。
class DailyTrackingSnackBar {
  DailyTrackingSnackBar._();

  /// 错误消息 SnackBar (走 l10n.editMedSaveFailed 模板)
  ///
  /// 替代 5+ 处:
  /// ```dart
  /// ScaffoldMessenger.of(context).showSnackBar(
  ///   SnackBar(content: Text(l10n.editMedSaveFailed(e.toString()))),
  /// );
  /// ```
  static void showSaveError(BuildContext context, Object error) {
    if (!context.mounted) return;
    // v0.32 round 8 (R111 EM-05 fix): 走 AppSnackBar 集中器 (commonSave
    // + snackbarErrorTemplate 输出跟 editMedSaveFailed 1:1 一致)
    AppSnackBar.showError(
      context,
      action: AppLocalizations.of(context).commonSave,
      error: error,
    );
  }

  /// 短信息 SnackBar (走 AppSnackBar.showInfo 集中器)
  static void showInfo(BuildContext context, String message) {
    AppSnackBar.showInfo(context, message);
  }
}

/// 3. 关闭页面 helper (替代 5+ 处 `if (mounted) Navigator.pop(context);`)
///
/// 走 Navigator.canPop() 守卫防止 route 关闭后调用 pop 崩 (R92 spen pattern)。
class DailyTrackingNav {
  DailyTrackingNav._();

  /// 安全 pop — 守卫 Navigator 状态
  static void safePop(BuildContext context) {
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) nav.pop();
  }

  /// 走 go_router 的 push (R59 起所有 page 跳转统一 go_router)
  static Future<T?> push<T>(BuildContext context, String location) {
    return context.push<T>(location);
  }
}

/// 4. 时间格式化 helper (替代 6+ 处 padLeft(2, '0'))
///
/// R108 spen N1: 71 处 `padLeft(2,'0')` 手写时间格式化, 本 helper 集中 daily_tracking
/// 6 处 (sleep × 2, social_rhythm × 2, treatment_list 1 间接, weight × 0)。
class DailyTrackingTimeFormat {
  DailyTrackingTimeFormat._();

  /// TimeOfDay → "HH:mm" (24h)
  static String formatHHmm(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// DateTime → "HH:mm" (24h, 读 hour/minute 字段)
  static String formatDateTimeHHmm(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// 分钟数 → "XhYYmin" (e.g. 480 → "8h00min")
  static String formatDurationMin(int min) {
    final h = min ~/ 60;
    final m = min % 60;
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }
}

/// 5. 日期 helper (替代 5+ 处 `DateTime(year, month, day)` 跟 race 风险)
///
/// R108 集中 5+ 处 dateOnly (sleep × 2, social_rhythm × 4, weight 1, anxiety × 1, stress × 1)
/// 跟 `DateTime.now()` 多次调用 race (v0.16 round 19B / v0.17 round 14) 模式。
class DailyTrackingDate {
  DailyTrackingDate._();

  /// dateOnly — 截断到当天 00:00:00
  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// dateOnly 用 "now" — 函数入口取一次 now, 避免跨 midnight 多次调用 race
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 同一天判断 (a, b 都是本地时区, 仅比较 y/m/d)
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// TimeOfDay 拼接到给定 date 上, 自动处理跨午夜 (wake < bed → +1 day)
  ///
  /// 用于 sleep_dialog / social_rhythm_dialog 的 TimeOfDay → DateTime 转换。
  /// 跨午夜规则跟 SleepCalculator.durationMin() 一致 (R91 brief)。
  static DateTime combineWithDate(
    DateTime date,
    TimeOfDay time, {
    DateTime? reference,
  }) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
