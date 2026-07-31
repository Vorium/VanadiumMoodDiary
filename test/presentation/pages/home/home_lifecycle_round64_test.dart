// v0.27 round 64 (L2 refactor): HomePage 3 bool flag → enum 状态机
//
// 测 [HomeLifecycleState] 状态机的 5 个语义 case:
// 1. 初始态 = initial
// 2. safety check 跑完 = safetyCheckCompleted
// 3. deep link 跑完 = deepLinkHandled
// 4. 两者都跑 = bothHandled (经 rerun 路径, 顺带覆盖 safetyRerunRequested)
// 5. race 防护: onDeepLinkHandled() 和 onRerunRequested() 互斥, 违反 invariant
//    抛 StateError (debug 时早发现)
//
// 状态机本身是纯 enum + 静态 transition method, 不依赖 Flutter / Riverpod,
// 所以 0 widget overhead, 直接 `test()` 跑。
import 'package:chroniccare/presentation/pages/home/home_page.dart'
    show HomeLifecycleState;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeLifecycleState 状态机 (round 64 L2 refactor)', () {
    test('case 1: 初始态 = HomeLifecycleState.initial', () {
      // 字段默认值
      const s = HomeLifecycleState.initial;
      expect(s, HomeLifecycleState.initial);
      expect(s.name, 'initial');
    });

    test('case 2: initial → onSafetyCheckCompleted() = safetyCheckCompleted', () {
      // 模拟 _runSafetyCheck 首次跑完
      const initial = HomeLifecycleState.initial;
      final next = initial.onSafetyCheckCompleted();
      expect(next, HomeLifecycleState.safetyCheckCompleted);
    });

    test('case 3: initial → onDeepLinkHandled() = deepLinkHandled', () {
      // 模拟 _handleDeepLink 带 medId query param 走完
      const initial = HomeLifecycleState.initial;
      final next = initial.onDeepLinkHandled();
      expect(next, HomeLifecycleState.deepLinkHandled);
    });

    test(
      'case 4: initial → onRerunRequested() (safetyRerunRequested) → '
      'onSafetyCheckCompleted() = bothHandled (模拟 Timer 触发 force rerun)',
      () {
        // 模拟: 通知 deep link 带 reason=safety → _handleDeepLink 调度 Timer
        //       → 走 _lifecycle.onRerunRequested() = safetyRerunRequested
        //       → Timer 到点 → _runSafetyCheck(force: true)
        //       → 走 onSafetyCheckCompleted() = bothHandled
        const initial = HomeLifecycleState.initial;
        final afterRerun = initial.onRerunRequested();
        expect(afterRerun, HomeLifecycleState.safetyRerunRequested,
            reason: 'onRerunRequested() 应该推进到 safetyRerunRequested');
        final afterSafety = afterRerun.onSafetyCheckCompleted();
        expect(afterSafety, HomeLifecycleState.bothHandled,
            reason: 'Timer 触发 force rerun 后, 推进到 bothHandled');
      },
    );

    test(
      'case 5: race 防护 — deepLinkHandled.onRerunRequested() 抛 StateError '
      '(invariant: 同一 deep link 不会同时有 medId 和 reason=safety)',
      () {
        // _handleDeepLink 一次只走 medId 或 reason=safety 一条。
        // 走到 deepLinkHandled 后再调 onRerunRequested() 是不变量违反,
        // 状态机抛 StateError 早发现 bug。
        const s = HomeLifecycleState.deepLinkHandled;
        expect(
          () => s.onRerunRequested(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('invariant violated'),
          )),
          reason: 'medId 路径走完后, 不能又请求 rerun (互斥)',
        );

        // 镜像: rerun 请求后再走 medId 也抛
        const r = HomeLifecycleState.safetyRerunRequested;
        expect(
          () => r.onDeepLinkHandled(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('invariant violated'),
          )),
          reason: 'rerun 请求后, 不能又走 medId 路径 (互斥)',
        );
      },
    );
  });
}
