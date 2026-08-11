// v0.31 round 4 (Apple Health redesign · Phase 1 Task 1.4): 动效 token 大调
//
// 历史:
// - v0.17 round 1 (emil 动效 token): 之前只有 duration 缺 curve / easing
// - v0.22 round 29: 加 4 个 const shadow
// - v0.24 round 43 (emil D-04 P2): 加 4 个 theme-aware shadow 替代
// - v0.27 round 59 (emil EMIL-T29): 删 4 个 const shadow, 强制 theme-aware
// - v0.27 round 65 (alibaba B16 god constant 拆分): duration/curve/shadow/
//   MotionScheme/Motion 全部在本文件; app_tokens.dart 留 facade re-export。
// - v0.31 R4 (Apple Health redesign · Task 1.4):
//   · Duration 调档 (durNormal 300→250, durSlow 500→400, durPress 160→100)
//   · Curve 加 3 个 Apple 自定义 cubic-bezier (curveSpring / curveAppleSheet /
//     curveAppleDrawer), 保留 6 个旧 curve
//   · Shadow 大改: shadowCardOf/shadowCardDarkOf → [] 空 (Apple Health 0 阴影),
//     shadowDialogOf 极轻 (blur 24, offset 0,8, alpha 0.08),
//     shadowOverlayOf 极轻 (blur 16, offset 0,4, alpha 0.06)
//   · Spring 走独立 spring.dart (本文件不嵌)
//
// 设计原则:
// - duration/curve 走 const (可在 const constructor 用, 跟 textStyleXxx 互补)
// - shadow 走 dynamic (接受 BuildContext, 走 M3 ColorScheme.shadow 适配 dark mode)
// - MotionScheme 走 enum + extension, 强制 caller 选档 (emil 4 档决策框架)
// - Motion class 提供 prefers-reduced-motion 包装 (P0-7 a11y 修正)
// - Spring 走 spring.dart (spec §3.4.3, 物理模型而非 duration-based)
// - 老 caller 兼容: `AppTokens.durNormal` 仍能用 (走 facade)
import 'package:flutter/material.dart';

/// v0.31 round 4 (Apple Health redesign): 动效 / 阴影 token 集中器
///
/// 4 大类:
/// 1. **Duration** (8 个, fast/normal/slow/press/pageTransition + snackbar 3 档)
/// 2. **Curve** (9 个, 6 旧 + 3 Apple 自定义 cubic-bezier)
/// 3. **BoxShadow** (4 个 dynamic getter, 走 M3 ColorScheme.shadow 适配 dark mode)
/// 4. **MotionScheme enum + Motion class** (4 档决策 + prefers-reduced-motion 包装)
///
/// Spring 物理模型见 `lib/core/theme/spring.dart` (本文件不嵌)。
class AppMotion {
  AppMotion._();

  // ============= 动画 =============
  // v0.17 round 1 (emil 动效 token): 之前只有 duration 缺 curve / easing
  // 各 widget 各写各的 → 风格不统一
  // 频度决策（emil 框架）：
  //   100+/day（键盘 / 核心导航）→ 无动画
  //   tens/day（hover）→ 微弱
  //   occasional（modal / drawer / snackbar）→ durNormal + curveStandard
  //   rare（onboarding / 庆祝）→ durSlow + curveDelight
  static const Duration durFast = Duration(milliseconds: 200);
  // v0.31 R4 (Apple Health redesign · Task 1.4): 略快, Apple 紧凑 (300→250)
  static const Duration durNormal = Duration(milliseconds: 250);
  // v0.31 R4 (Apple Health redesign · Task 1.4): 略快 (500→400)
  static const Duration durSlow = Duration(milliseconds: 400);

  // v0.24 round 45 (emil P1-16): 4 个细小 duration 抽 token
  // emil "magic numbers should be named" — 之前散落 6 处 hardcode
  // - durPress: PressFeedback 按下→回弹周期 (160ms, 比 durFast 短 — 必须感觉"快")
  // - shimmerCycleMs: LoadingSkeleton shimmer 完整循环周期 (1200ms, 是 magic 不是动画)
  // - durPageTransition: PageTransitionSwitcher fade 100ms (默认 fade 100, override 时)
  // - refreshMinVisibleMs: pull-to-refresh 最小可见时间 400ms (避免 "瞬闪" 感觉没刷新)
  // v0.31 R4 (Apple Health redesign · Task 1.4): 关键改 — iOS 即时反馈 100ms
  // (160→100, spec §3.4.1 "PressFeedback 必须感觉"快" — 100ms 内必须看到反馈")
  static const Duration durPress = Duration(milliseconds: 100);
  static const int shimmerCycleMs = 1200;
  static const Duration durPageTransition = Duration(milliseconds: 100);
  static const int refreshMinVisibleMs = 400;

  // v0.21 Round 25 (P2 polish): snackbar 时长统一
  // 之前 10+ 处 SnackBar duration: const Duration(seconds: 2|3|4) 硬编码
  // 频度: occasional (偶尔 1 次) → 标准时长
  // - short (2s): 普通 info / 成功提示
  // - medium (3s): 多行 info
  // - long (4s): error 错误信息 (用户需要时间读) + Undo 撤销操作 (4s 反应窗口)
  static const Duration snackBarDurationShort = Duration(seconds: 2);
  static const Duration snackBarDurationMedium = Duration(seconds: 3);
  static const Duration snackBarDurationLong = Duration(seconds: 4);

  /// 标准进入/出场缓动 — `easeOutCubic`：开始快、收尾慢
  /// 替代 Flutter 默认 `easeInOut`（emil: 延迟了用户最关注的入场瞬间）
  /// 适用：modal / drawer / 状态切换 / fade in
  static const Curve curveStandard = Curves.easeOutCubic;

  /// 微弱缓动 — `easeOut`：比 standard 弱 30%，"几乎察觉不到"
  /// v0.24 round 48 (emil P1-1): 之前 MotionScheme.subtle 跟 standard 共用 curveStandard
  /// 导致 subtle 频度档位虚设（emil "decisions should be nameable"）
  /// 现在 subtle 用专属 curve，频度档位可命名
  /// 适用：tens/day 微弱反馈（hover 类 / list item 选中态）
  static const Curve curveSubtle = Curves.easeOut;

  /// 强减速缓动 — `easeOutQuart`：比 standard 更明显的"快速起步、缓慢收尾"
  /// 适用：celebration / 大数字递增（streak 数字）
  static const Curve curveDecelerate = Curves.easeOutQuart;

  /// 入场缓动 — `easeInCubic`：开始慢、结束快
  /// 适用：exit / dismiss 动画（离开屏幕要"果断"）
  static const Curve curveAccelerate = Curves.easeInCubic;

  /// 弹性缓动 — `elasticOut`：超过目标再回弹
  /// 适用：onboarding 首次 / 庆祝反馈（rare 频度，emil: 禁滥用）
  static const Curve curveDelight = Curves.elasticOut;

  /// v0.23 round 40 (emil F2 fix): 回弹缓动 — `easeOutBack`：过冲但不弹多次
  /// 适用：庆祝 overlay 主弹跳 (celebration_overlay:32)
  /// 跟 curveDelight (elasticOut) 区别: easeOutBack 一次过冲,elasticOut 多次回弹
  /// 主庆祝用 easeOutBack 更"稳",副粒子可用 elasticOut
  static const Curve curveBackOut = Curves.easeOutBack;

  // v0.31 R4 (Apple Health redesign · Task 1.4): 3 Apple 自定义 cubic-bezier
  // (spec §3.4.2, apple-design skill §4)
  // 用 Cubic 而非 Curves, 可走 const constructor。

  /// Apple springOut 近似 — `cubic-bezier(0.23, 1, 0.32, 1)`
  /// 适用: 通用 spring 收敛 (celebration / tile hover / push 反馈)
  /// 跟 `Spring` 物理模型配对: Spring.standard (stiffness 200, damping 20)
  /// 用 `curve` 模拟; 真实 spring 见 spring.dart。
  static const Cubic curveSpring = Cubic(0.23, 1, 0.32, 1);

  /// iOS 抽屉/Sheet 曲线 — `cubic-bezier(0.32, 0.72, 0, 1)`
  /// 适用: modal 从底部升起 (急停, 不回弹) — apple-design §4
  static const Cubic curveAppleSheet = Cubic(0.32, 0.72, 0, 1);

  /// iOS Drawer 曲线 — `cubic-bezier(0.77, 0, 0.175, 1)`
  /// 适用: drawer / nav 滑入/滑出 (平滑长尾) — apple-design §4
  static const Cubic curveAppleDrawer = Cubic(0.77, 0, 0.175, 1);

  // ============= 阴影 (v0.31 R4 Apple Health 0 阴影) =============
  //
  // 历史 (R22 → R27 → R31):
  // - v0.22 round 29 加 4 个 const shadow (shadowCard / shadowCardDark /
  //   shadowDialog / shadowOverlay), 全黑色 0x14-0x33 透明度。
  //   **dark mode 完全不可见** (黑色阴影打在 dark surface 上 = 透明),
  //   这是 R49 修正过的 60+ 处 silent bug 同款风险。
  // - v0.24 round 43 (emil D-04 P2) 加 4 个 theme-aware 替代。
  // - v0.27 round 59 (emil EMIL-T29): 删 4 个 const 版本, 强制走 theme-aware。
  // - v0.31 R4 (Apple Health redesign · Task 1.4): 大改 — Apple Health 完全
  //   不用 shadow 表达层次, 改用 hairline divider + container color。
  //   · shadowCardOf / shadowCardDarkOf → `[]` 空 (0 阴影)
  //   · shadowDialogOf → 极轻 (blur 24, offset 0,8, alpha 0.08)
  //   · shadowOverlayOf → 极轻 (blur 16, offset 0,4, alpha 0.06)
  //   保留 dynamic getter 签名, 方便未来 dark mode 微调。
  //
  // 用法: `boxShadow: AppMotion.shadowCardOf(context)` ← 直接走 `[]`

  /// Apple Health 卡片阴影: **0 阴影** (空 list, 跟 spec §3.4.4 一致)
  ///
  /// Apple Health 不用 shadow 表达层次, 改用:
  /// - `Container.decoration.color` 容器色
  /// - `Divider(thickness: 0.5)` hairline 分隔
  /// - `background: F2F2F7` systemGroupedBackground 衬底
  ///
  /// 保留 theme-aware getter 签名 (走 BuildContext), 当前固定返 `[]`。
  /// 调用方无感知, 0 渲染开销。
  static List<BoxShadow> shadowCardOf(BuildContext context) => const <BoxShadow>[];

  /// Apple Health 卡片深阴影: **0 阴影** (空 list, 跟 shadowCardOf 同步)
  ///
  /// 保留独立 API 方便未来 dark mode 对"主色卡片"用低 alpha shadow 表达
  /// (如 checkIn 按钮完成态 — main color 卡片可能要 1px 1px 极轻 shadow)。
  static List<BoxShadow> shadowCardDarkOf(BuildContext context) =>
      const <BoxShadow>[];

  /// 极轻对话框阴影 (iOS modal 标准 1 层)
  ///
  /// spec §3.4.4 step 8: blurRadius 24, offset Offset(0, 8), alpha 0.08
  /// (M3 主题 ColorScheme.shadow 通常 alpha 0.16~0.20, 这里用 0.08 = 一半,
  /// 走 scheme.shadow.withValues(alpha: 0.08) 自动 dark mode 适配)
  static List<BoxShadow> shadowDialogOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// 极轻浮层阴影 (snackbar / tooltip / dropdown)
  ///
  /// spec §3.4.4 step 9: blurRadius 16, offset Offset(0, 4), alpha 0.06
  /// 比 shadowDialogOf 略轻, 给 snackbar / popover 用
  static List<BoxShadow> shadowOverlayOf(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ============= Scrim (v0.27 round 65 alibaba B9 magic alpha) =============
  //
  // 之前 medication_report_dialog.dart:162 散落
  // `Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54)` 魔法值。
  // 0.54 是 M3 long-task modal scrim 标准 (高于 dialog 0.32, 低于 0.7 全黑)。
  // 抽常量后, dark mode 调 scrim 适配时一处生效。
  //
  // emil "decisions should be nameable" — 0.54 不应裸用，命名 "scrimAlpha"。

  /// Modal scrim alpha — 0.54 (long-task modal 标准, 高于 dialog 0.32)
  static const double scrimAlpha = 0.54;
}

// ============= MotionScheme (v0.17 round 14 / P2-14) =============
//
// emil 决策框架: 4 档动画强度，按"用户一天看到几次"分。
// 用 enum 强制 caller 选档，避免在 widget 里直接传
// (Duration, Curve) 导致风格不统一。
//
// 用法:
// ```dart
// final motion = MotionScheme.standard;  // most UI
// AnimatedContainer(
//   duration: motion.duration,
//   curve: motion.curve,
//   ...
// )
// ```
//
// 选择规则:
// - none:      100+/day (键盘 / 核心导航 / 日常按钮) → 用户已经熟，无动画
// - subtle:    tens/day (hover / press feedback) → 微弱反馈
// - standard:  occasional (modal / drawer / snackbar / 状态切换)
// - delight:   rare (onboarding 首次 / 庆祝 / 解锁成就) → 弹性，可加 highlight
enum MotionScheme {
  /// 100+/day — 不加动画，直接切换
  none,

  /// tens/day — 微弱反馈 (e.g. button press)
  subtle,

  /// occasional — modal / drawer / snackbar 默认档
  /// durNormal + curveStandard (easeOutCubic)
  standard,

  /// rare — onboarding 首次 / 庆祝 / 解锁
  /// durSlow + curveDelight (elasticOut)
  delight,
}

extension MotionSchemeTokens on MotionScheme {
  Duration get duration {
    switch (this) {
      case MotionScheme.none:
        return Duration.zero;
      case MotionScheme.subtle:
        return AppMotion.durFast;
      case MotionScheme.standard:
        return AppMotion.durNormal;
      case MotionScheme.delight:
        return AppMotion.durSlow;
    }
  }

  Curve get curve {
    switch (this) {
      case MotionScheme.none:
        return Curves.linear;
      case MotionScheme.subtle:
        // v0.24 round 48 (emil P1-1): 之前跟 standard 共用 curveStandard
        // 频度档位虚设。现在用 curveSubtle (Curves.easeOut) 跟 standard 区分
        return AppMotion.curveSubtle;
      case MotionScheme.standard:
        return AppMotion.curveStandard;
      case MotionScheme.delight:
        return AppMotion.curveDelight;
    }
  }
}

// ============= Motion (v0.18 round 14 / P0-7) =============
//
// **P0-7 fix**: 之前没有任何代码处理 `prefers-reduced-motion: reduce` 媒体查询。
// 精神心理患者前庭功能敏感比例高于普通用户，长时间用 App 可能眩晕。
// emil 原则第 8 条: reduced-motion 是 non-negotiable a11y 标准。
//
// 用法:
// ```dart
// AnimatedContainer(
//   duration: Motion.duration(context, AppMotion.durNormal),
//   curve: Motion.curve(context, AppMotion.curveStandard),
//   ...
// )
// ```
//
// 系统没开 reduce motion → 走原 duration/curve
// 系统开了 reduce motion → duration = 0 + curve = linear
class Motion {
  Motion._();

  /// 系统是否启用了"减少动画"
  ///
  /// Flutter 内置 API: [MediaQuery.disableAnimations]
  static bool prefersReduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// 包装 duration: 系统开了 reduce motion → 0
  ///
  /// [base] 通常是 AppMotion.durNormal / durFast / durSlow。
  static Duration duration(BuildContext context, Duration base) =>
      prefersReduced(context) ? Duration.zero : base;

  /// 包装 curve: 系统开了 reduce motion → linear (避免任何加速/减速)
  static Curve curve(BuildContext context, Curve base) =>
      prefersReduced(context) ? Curves.linear : base;
}
