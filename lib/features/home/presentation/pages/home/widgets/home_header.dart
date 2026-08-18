// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1): HomeHeader 重设
//
// 历史:
// - v0.18 round 18 (P1-27): 从 home_page 抽出
// - v0.24 round 43 (emil P1-01 H-01): 3 个 IconButton 改用 PressFeedbackIconButton
//
// v0.31 R9a 改造 (Apple Health 主页头):
// - greeting 28pt w700 (textStyleTitle, Apple SF Pro Display 风格)
// - 副字日期 15pt textSecondary (textStyleLabel) — 显示 DateTime.now()
// - theme toggle 32x32 PressFeedback (IconButton 集中器替换) + dark_mode/light_mode
// - 上下 spacingXs 8 padding (从 16 减半, 跟 Apple Health 紧凑头部一致)
// - 整体: 透明背景 (页面背景 F2F2F7 自带, 不需要 surfaceColor 容器)
// - 单一 Container + Row 结构 (去掉 Padding 嵌套)
//
// 设计选择:
// - theme toggle 替换原 3 个 IconButton (趋势/评估/设置): 3 个入口分散注意力,
//   Apple Health 风格只保留 1 个右上角 toggle, 入口功能下放到 "快捷操作" 区块
// - dark mode 自动通过 themeMode provider 切换 icon (mode=dark → light_mode icon)
// - PressFeedbackIconButton 32x32 用 constraints 控制尺寸 (跟 R24 集中器一致)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/core/theme/theme_provider.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 主页顶部 header:大字 greeting + 副字日期 + theme toggle
///
/// v0.31 round 9a: 改 Apple Health 风格 — 28pt greeting + 15pt 日期 +
/// 32x32 主题切换按钮。
class HomeHeader extends ConsumerWidget {
  final String userName;
  final DateTime? date;

  /// R128e (论文2 §2.1.3 个人模块 "加入树洞一共多少天"): 陪伴天数
  /// null = 无 firstLaunchAt, 不显示陪伴天数。
  final int? daysCompanion;

  const HomeHeader({
    super.key,
    required this.userName,
    this.date,
    this.daysCompanion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    // dark/light 切到对应 icon (system 模式走 brightness_auto)
    final themeIcon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
    final nextMode = switch (mode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    final effectiveDate = date ?? DateTime.now();
    return Container(
      // 上下 spacingXs 8 padding (从 16 减半, 紧凑 Apple Health 头)
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      // 透明背景 (页面背景 F2F2F7 自带)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // greeting 28pt w700
                Text(
                  userName.isEmpty
                      ? l10n.homeHeaderDefaultTitle
                      : l10n.homeHeaderKeepGoing(userName),
                  style: AppTokens.textStyleTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // 副字日期 15pt textSecondary
                Text(
                  _formatDate(effectiveDate, l10n),
                  style: AppTokens.textStyleLabel(context).copyWith(
                    color: AppTokens.textSecondaryColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // R128e (论文2 个人模块): 陪伴天数副行
                if (daysCompanion != null && daysCompanion! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.homeCompanionDays(daysCompanion!),
                    style: AppTokens.textStyleLabel(context).copyWith(
                      color: AppTokens.textHintColor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 32x32 主题切换按钮
          PressFeedbackIconButton(
            icon: themeIcon,
            tooltip: l10n.themeTooltip(_modeLabel(l10n, mode)),
            onPressed: () => notifier.set(nextMode),
            size: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// 格式化日期 — zh: 2026年8月10日 / en: August 10, 2026
  /// v0.32 round 8 (R111 SP-111-12 fix): en 分支 (SP-zh-17 跨期残留,
  /// 之前 en locale 也显示中文 "年月日")
  String _formatDate(DateTime d, AppLocalizations l10n) {
    if (l10n.localeName.startsWith('zh')) {
      return '${d.year}年${d.month}月${d.day}日';
    }
    return DateFormat.yMMMMd('en').format(d);
  }

  String _modeLabel(AppLocalizations l10n, ThemeMode m) {
    return switch (m) {
      ThemeMode.system => l10n.themeModeSystem,
      ThemeMode.light => l10n.themeModeLight,
      ThemeMode.dark => l10n.themeModeDark,
    };
  }
}
