// v0.27 round 64 (L2 refactor): HomePage 3 bool flag → enum 状态机
//
// 1.1.0 round 4 (emotion-first refactor): safety check 路径整摘后
// [HomeLifecycleState] 5 状态简化为 2 状态 (initial / deepLinkHandled)。
// 本文件改测 2 态语义:
// 1. 初始态 = initial
// 2. initial → onDeepLinkHandled() = deepLinkHandled
// 3. deepLinkHandled → onDeepLinkHandled() = deepLinkHandled (idempotent)
//
// 状态机本身是纯 enum + 静态 transition method, 不依赖 Flutter / Riverpod,
// 所以 0 widget overhead, 直接 `test()` 跑。
import 'package:chroniccare/presentation/pages/home/home_page.dart'
    show HomeLifecycleState;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeLifecycleState 状态机 (1.1.0 round 4 2 态简化)', () {
    test('case 1: 初始态 = HomeLifecycleState.initial', () {
      const s = HomeLifecycleState.initial;
      expect(s, HomeLifecycleState.initial);
      expect(s.name, 'initial');
    });

    test('case 2: initial → onDeepLinkHandled() = deepLinkHandled', () {
      const initial = HomeLifecycleState.initial;
      final next = initial.onDeepLinkHandled();
      expect(next, HomeLifecycleState.deepLinkHandled);
    });

    test('case 3: deepLinkHandled → onDeepLinkHandled() 幂等 no-op', () {
      const handled = HomeLifecycleState.deepLinkHandled;
      final next = handled.onDeepLinkHandled();
      expect(next, HomeLifecycleState.deepLinkHandled);
    });

    test('case 4: enum 只有 2 个值 (safety 状态全摘)', () {
      expect(
        HomeLifecycleState.values.map((s) => s.name).toList(),
        ['initial', 'deepLinkHandled'],
      );
    });
  });
}
