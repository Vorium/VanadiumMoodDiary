// home_page.dart — 主页主壳 (R95 sub-spec 4 task 5 拆解)
//
// 职责:
// 1. [HomePage] ConsumerStatefulWidget — 主页入口
// 2. [HomeLifecycleState] 5 状态 enum (R64 L2 refactor, race 防御)
//
// **state class HomePageState 已搬到 home_page_state.dart** (v0.30 round 95
// sub-spec 4 task 5): 731 行 → 主壳 138 行 + state 590 行, 拆完业务方法 (9 个)
// 在 state 独立, 主壳纯 widget 入口 + 5 状态 enum 集中。
//
// 历史:
// - v0.10 (Round 4): 首版 HomePage
// - v0.18 (P1-27): build 拆 5 widget (Header / HeroIllustration / QuickMoodCarousel /
//   PrimaryActionRow / SecondaryActionRow)
// - v0.27 round 64 (L2 refactor): 3 bool flag → HomeLifecycleState enum
//   (race 防御, transition 集中)
// - v0.30 round 92 (audit-fixes / P0 #13): Column → SingleChildScrollView
//   + homeFabTop 走 Scrollable.ensureVisible
// - v0.30 round 95 (sub-spec 4 task 5): HomePageState 拆 home_page_state.dart
//   (原 _HomePageState 改成 public 避免循环 import)
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/pages/home/home_page_state.dart';

/// 主页
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

/// v0.27 round 64 (L2 refactor): 3 bool flag → enum 状态机
///
/// 之前 3 个独立 bool (`_safetyCheckTriggered` / `_safetyRerunRequested` /
/// `_deepLinkHandled`) 理论 8 种组合,实际只有 5 种有意义,另 3 种是 race 风险
/// (e.g. `safetyRerunRequested` 但 safety check 没跑过 / `deepLinkHandled`
/// 但 rerun 已请求 — 两个独立 flag 没法表达这类不变量)。
///
/// 状态机 5 个 named state + 3 个 transition method:
/// - 有效 transition 走 enum 映射 (`switch` expression 强制穷举)
/// - 重复 trigger (e.g. `initial.onSafetyCheckCompleted().onSafetyCheckCompleted()`)
///   idempotent 静默 no-op
/// - 真 race (`onDeepLinkHandled` 和 `onRerunRequested` 互斥) 抛 `StateError`,
///   debug 时早发现 invariant 违反
enum HomeLifecycleState {
  /// 启动初始态, safety check 未触发
  initial,

  /// safety check 跑完, 无 deep link
  safetyCheckCompleted,

  /// deep link 已处理 (from app start, `medId` query param 路径)
  deepLinkHandled,

  /// 强制重跑 safety check (R62 P1-9 race guard,
  /// `reason=safety` query param 路径, Timer 后调 `_runSafetyCheck(force: true)`)
  safetyRerunRequested,

  /// safety check 跑完 + deep link 同时 fire (两路分支都完成)
  bothHandled;

  /// Transition: safety check ran (无论初次还是 force rerun)。
  ///
  /// 允许 from: `initial` (首次) / `deepLinkHandled` / `safetyRerunRequested` (Timer 触发)
  /// idempotent from: `safetyCheckCompleted` / `bothHandled` (重复调用静默 no-op)
  HomeLifecycleState onSafetyCheckCompleted() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.safetyCheckCompleted,
      HomeLifecycleState.deepLinkHandled => HomeLifecycleState.bothHandled,
      HomeLifecycleState.safetyRerunRequested => HomeLifecycleState.bothHandled,
      // idempotent: 已经包含 safety check completed
      HomeLifecycleState.safetyCheckCompleted ||
      HomeLifecycleState.bothHandled =>
        this,
    };
  }

  /// Transition: deep link 带 `medId` 路径已处理。
  ///
  /// 允许 from: `initial` / `safetyCheckCompleted`
  /// idempotent from: `deepLinkHandled` / `bothHandled`
  /// RACE from: `safetyRerunRequested` (mutually exclusive — 同一 deep link
  /// 不会同时有 `medId` 和 `reason=safety`, 出现这种情况是 bug)
  HomeLifecycleState onDeepLinkHandled() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.deepLinkHandled,
      HomeLifecycleState.safetyCheckCompleted => HomeLifecycleState.bothHandled,
      // idempotent
      HomeLifecycleState.deepLinkHandled ||
      HomeLifecycleState.bothHandled =>
        this,
      // race guard: 不变量 `_handleDeepLink` 一次只走 medId 或 reason=safety 一条
      HomeLifecycleState.safetyRerunRequested => throw StateError(
          'HomeLifecycleState invariant violated: '
          'onDeepLinkHandled() called from $this. '
          'Rerun already requested, deep link medId path is mutually exclusive.',
        ),
    };
  }

  /// Transition: deep link 带 `reason=safety` 路径已请求重跑。
  ///
  /// 允许 from: `initial` / `safetyCheckCompleted`
  /// idempotent from: `safetyRerunRequested` / `bothHandled`
  /// RACE from: `deepLinkHandled`
  HomeLifecycleState onRerunRequested() {
    return switch (this) {
      HomeLifecycleState.initial => HomeLifecycleState.safetyRerunRequested,
      HomeLifecycleState.safetyCheckCompleted =>
        HomeLifecycleState.safetyRerunRequested,
      // idempotent
      HomeLifecycleState.safetyRerunRequested ||
      HomeLifecycleState.bothHandled =>
        this,
      // race guard
      HomeLifecycleState.deepLinkHandled => throw StateError(
          'HomeLifecycleState invariant violated: '
          'onRerunRequested() called from $this. '
          'Deep link medId already handled, rerun path is mutually exclusive.',
        ),
    };
  }
}
