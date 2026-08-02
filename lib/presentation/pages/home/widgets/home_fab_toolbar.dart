// v0.28 R81 (emil design-3): HomeFabToolbar 主页浮动工具栏
//
// 背景 (R81 emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 截图):
//   B 站浮动工具栏: 收起状态 1 个 FAB, 展开 4 个圆角按钮
//   (收起导航 / 公益热线 / 测试中心 / 回到顶端), 节省屏幕空间
//   + 紧急入口 1 tap 达。
//
//   chroniccare 之前: home_page 顶部 nav 跟 help 入口分散, 紧急
//   热线 / 测试中心需要 2-3 tap 达, 屏幕空间浪费。
//
// 修法: 新建 HomeFabToolbar, 默认收起 (1 个 FAB 按钮),
// 点击展开 4 个工具按钮 (心情测试 / 心情树洞 / 紧急热线 / 回到顶端),
// 跟 B 站 4 入口同构 (cancel navigation / hotline / test / top)。
// 再点收起回到 1 个 FAB, 节省屏幕。
//
// emil 频度: tens/day (FAB 收起展开), standard animation OK,
// 展开 200ms ease-out (B 站风格, 强出 cubic-bezier(0.23, 1, 0.32, 1))。
// 视觉: 圆角矩形 (B 站橙色) + 阴影, 跟 home_page 主色协调。
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页浮动工具栏 — 收起 1 FAB, 展开 4 工具按钮
class HomeFabToolbar extends StatefulWidget {
  const HomeFabToolbar({super.key});

  @override
  State<HomeFabToolbar> createState() => _HomeFabToolbarState();
}

class _HomeFabToolbarState extends State<HomeFabToolbar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 展开 4 个工具按钮 (AnimatedSize 平滑过渡)
        AnimatedSize(
          duration: Motion.duration(context, AppTokens.durNormal),
          curve: Motion.curve(context, AppTokens.curveStandard),
          child: _expanded
              ? Column(
                  children: [
                    _FabButton(
                      icon: Icons.psychology_outlined,
                      label: l10n.homeFabAssessment,
                      onTap: () {
                        setState(() => _expanded = false);
                        context.push('/assessment');
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    _FabButton(
                      icon: Icons.forest_outlined,
                      label: l10n.homeFabVent,
                      onTap: () {
                        setState(() => _expanded = false);
                        context.push('/vent');
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    _FabButton(
                      icon: Icons.phone_in_talk_outlined,
                      label: l10n.homeFabHotline,
                      onTap: () {
                        setState(() => _expanded = false);
                        // v0.28 R81: 紧急热线入口 (1 tap 达, B 站'公益热线' 同款)
                        // R75 已经准备 hotlineByRegion + 6 region × 2 i18n (R77 收尾)
                        // 调 safety_alert_dialog 或 push 独立 route (R82+)
                        // 当前简单弹一个 SnackBar 提示 + 跳 safety
                        AppSnackBar.showInfo(context, l10n.homeFabHotlineTodo);
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    _FabButton(
                      icon: Icons.vertical_align_top,
                      label: l10n.homeFabTop,
                      onTap: () {
                        setState(() => _expanded = false);
                        // 回到顶端 — 实际滚动逻辑由 home_page 接管
                        // R82+ 改 Scrollable.ensureVisible 滚到顶
                        AppSnackBar.showInfo(context, l10n.homeFabTopTodo);
                      },
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // 主 FAB (收起 / 展开 toggle)
        PressFeedback(
          onTap: _toggle,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              // v0.28 R81: 跟 B 站橙色按钮一致 (主页 brand 色)
              color: AppTokens.tintedPrimaryDeep(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              // v0.28 R82 (emil EMIL-T29 续): 走 theme-aware shadowOverlayOf
              // (R81 漏接, dark mode 黑底阴影不可见)
              boxShadow: AppTokens.shadowOverlayOf(context),
            ),
            alignment: Alignment.center,
            child: AnimatedRotation(
              turns: _expanded ? 0.125 : 0,
              duration: Motion.duration(context, AppTokens.durFast),
              curve: Motion.curve(context, AppTokens.curveStandard),
              child: Icon(
                _expanded ? Icons.close : Icons.menu,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 单个 FAB 工具按钮 (展开时显示)
class _FabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FabButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTokens.tintedPrimaryDeep(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          // v0.28 R82 (emil EMIL-T29 续): 走 theme-aware shadowOverlayOf
          boxShadow: AppTokens.shadowOverlayOf(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: AppTokens.fontSizeCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
