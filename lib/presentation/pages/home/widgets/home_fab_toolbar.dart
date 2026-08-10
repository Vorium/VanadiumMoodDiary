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
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页浮动工具栏 — 收起 1 FAB, 展开 4 工具按钮
class HomeFabToolbar extends StatefulWidget {
  /// v0.30 round 92 (audit-fixes / P0 #13): homeFabTop 滚动目标
  ///
  /// 修前 bug: homeFabTop onPressed 调 `AppSnackBar.showInfo(homeFabTopTodo)`
  /// 占位。修法: home_page 创建一个 ScrollController 包在主页 ListView 上,
  /// 传给 toolbar; toolbar homeFabTop onPressed 调
  /// `Scrollable.ensureVisible(scrollController.position.context, ...)`
  /// 把主页滚到顶 (200ms curveStandard 动画)。
  final ScrollController? scrollController;

  const HomeFabToolbar({super.key, this.scrollController});

  @override
  State<HomeFabToolbar> createState() => _HomeFabToolbarState();
}

class _HomeFabToolbarState extends State<HomeFabToolbar>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() {
    Haptics.light();
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
                    FadeIn(
                      delay: Duration.zero,
                      child: _FabButton(
                        icon: Icons.psychology_outlined,
                        // v0.30 R91 Task 7: FAB label 改 dailyTrackingFab
                        // ("全部趋势") — 跟 FAB 跳 /daily-tracking 整合入口
                        // 保持一致 (原 homeFabAssessment "心情测试" 已过时).
                        label: l10n.dailyTrackingFab,
                        onTap: () {
                          setState(() => _expanded = false);
                          // v0.30 round 91 (sub-spec 7 日常追踪 / Task 5 整合入口):
                          // 改跳 /daily-tracking (7 子功能整合入口: 情绪日记 +
                          // 焦虑急躁 + 睡眠 + 社会节律 + 应激源 + 治疗 + 体重).
                          // 之前 R90 跳 /assessment-center, R91 Task 5 整合
                          // 入口取代单一评估入口, 用户从 7 卡片 grid 选子功能.
                          context.push('/daily-tracking');
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    FadeIn(
                      delay: const Duration(
                          milliseconds: AppTokens.staggerStepMs,),
                      child: _FabButton(
                        icon: Icons.forest_outlined,
                        label: l10n.homeFabVent,
                        onTap: () {
                          setState(() => _expanded = false);
                          context.push('/vent');
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    // R97-P0-2 (2026-08-07): 危机热线 FAB 永远显示。
                    //
                    // 修前 (R93 阶段 2): 危机热线入口被
                    // [FeatureFlags.emergencyContactEnabled] gate 守卫,
                    // 业务暂停时主页完全看不到任何危机干预入口, 违反
                    // Apple App Store Guideline 1.4.1 (Physical Harm) 强制要求
                    // "精神心理类 App 必须在主页有可见的自杀干预入口"。
                    //
                    // 修复: 危机热线是静态信息 (5 地区列表 + 全国热线,
                    // CrisisHotlinePage 已实现 + 路由 `/crisis-hotline` 已注册),
                    // 不依赖 SMS 业务。把 hotline FAB 从 emergencyContactEnabled
                    // 守卫中拆出来, 永远显示。SMS 业务继续独立 flag 守卫
                    // (safety_watch_service._checkAndAlert 内 FeatureFlag
                    // gate 不变)。
                    FadeIn(
                      delay: const Duration(
                          milliseconds: 2 * AppTokens.staggerStepMs,),
                      child: _FabButton(
                        icon: Icons.phone_in_talk_outlined,
                        label: l10n.homeFabHotline,
                        onTap: () {
                          setState(() => _expanded = false);
                          // v0.30 round 92 (audit-fixes / P0 #12): 紧急热线入口
                          // (1 tap 达, B 站'公益热线' 同款)。R75 已备
                          // hotlineByRegion 6 region + R83.5 partial 5 region
                          // ARB keys (crisisHotline{Cn,Tw,Hk,Mo,*}Label/Number/Desc)
                          // + R91 setup_legal_dialog _crisisHotlineSection 4 条
                          // 已用。R92 改 push `/crisis-hotline` 独立页面
                          // (5 地区列表 + 800-810-1117 全国)。
                          //
                          // 用 context.push (而非 GoRouter.of(context).go):
                          // push 保留 back stack, 用户返回仍回主页 (go 会
                          // 替换栈, 失去 home)。
                          context.push('/crisis-hotline');
                        },
                      ),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    FadeIn(
                      delay: const Duration(
                          milliseconds: 3 * AppTokens.staggerStepMs,),
                      child: _FabButton(
                        icon: Icons.vertical_align_top,
                        label: l10n.homeFabTop,
                        onTap: () {
                          setState(() => _expanded = false);
                          // v0.30 round 92 (audit-fixes / P0 #13): 回到顶端
                          // 走 `scrollController.animateTo(0, duration, curve)`
                          // 滚到 minScrollExtent (顶)。修前: AppSnackBar
                          // .showInfo(homeFabTopTodo) 占位 1.5 年。
                          //
                          // 用 scrollController.animateTo 而非
                          // Scrollable.ensureVisible(context, ...) 的原因:
                          // floatingActionButton 跟 Scaffold body 是 sibling
                          // (Flutter Scaffold 内部 layout), toolbar context
                          // 找不到 body 内的 Scrollable。直接用
                          // home_page 传来的 ScrollController, 通过 animateTo
                          // 不依赖 widget tree 路径, 行为可预期。
                          final ctrl = widget.scrollController;
                          if (ctrl != null && ctrl.hasClients) {
                            ctrl.animateTo(
                              0.0,
                              duration: Motion.duration(
                                  context, AppTokens.durNormal,),
                              curve: Motion.curve(
                                  context, AppTokens.curveStandard,),
                            );
                          }
                        },
                      ),
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
