// home_page.dart — 主页主壳 (R95 sub-spec 4 task 5 拆解)
//
// 职责:
// 1. [HomePage] ConsumerStatefulWidget — 主页入口
// 2. [HomeLifecycleState] 2 状态 enum (1.1.0 round 4 简化)
//
// **state class HomePageState 已搬到 home_page_state.dart** (v0.30 round 95
// sub-spec 4 task 5): 731 行 → 主壳 138 行 + state 590 行, 拆完业务方法 (9 个)
// 在 state 独立, 主壳纯 widget 入口 + 状态 enum 集中。
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
// - 1.1.0 round 4 (emotion-first refactor): safety check 路径整摘
//   (care engine dispatcher / _runSafetyCheck / reason=safety deep link 全删),
//   5 状态 → 2 状态 (initial / deepLinkHandled)
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
/// 1.1.0 round 4 (emotion-first refactor): safety check 路径整摘后, 状态机
/// 只剩 deep link 一个推进源, 5 状态 (safetyCheckCompleted /
/// safetyRerunRequested / bothHandled) 全删, 简化为 2 状态:
///
/// - [initial] 启动初始态, deep link 未处理
/// - [deepLinkHandled] deep link 带 medId 已处理
///
/// transition 走 [onDeepLinkHandled], 重复调用 idempotent 静默 no-op。
enum HomeLifecycleState {
  initial,
  deepLinkHandled;

  HomeLifecycleState onDeepLinkHandled() => switch (this) {
        HomeLifecycleState.initial => HomeLifecycleState.deepLinkHandled,
        HomeLifecycleState.deepLinkHandled => this,
      };
}
