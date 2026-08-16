// v0.30 round 95 (sub-spec 7 task 32): setupRedirect 纯函数 + 嵌套路径守卫 测试
//
// 覆盖:
// 1. 未完成 setup + 在 /setup → null (不 redirect, 用户在走 setup)
// 2. 未完成 setup + 在 /setup/any-sub-path → null (修前 == '/setup' 误判成 "不在 setup")
// 3. 未完成 setup + 在 / → /setup (引导去 setup)
// 4. 未完成 setup + 在 /settings → /setup
// 5. 已完成 setup + 在 / → null (用户正常使用)
// 6. 已完成 setup + 在 /setup → / (回根)
// 7. 已完成 setup + 在 /setup/any-sub-path → / (修前 == '/setup' 误判, 漏跳)
// 8. **lock-in 嵌套路径守卫**: 不会误匹配 /setup-thing (hypothetical 别的路径)

import 'package:chroniccare/core/routing/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('setupRedirect 决策树', () {
    test('未完成 setup + 在 /setup → null (不 redirect)', () {
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/setup'),
        isNull,
      );
    });

    test('未完成 setup + 在 /setup/any-sub-path → null (嵌套路径守卫, 修前 == bug)', () {
      // v0.30 R95 task 32 修: 之前 == '/setup' 严格匹配, 子路径走兜底被
      // 误判成 "不在 setup", 触发 redirect 跳 /setup → 跟当前路径相同
      // 但 state 会再次 trigger → 无限循环
      // 修后 startsWith('/setup/') 守卫嵌套, 子路径也算"在 setup"
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/setup/consent'),
        isNull,
      );
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/setup/welcome'),
        isNull,
      );
      expect(
        setupRedirect(
          isSetupDone: false,
          matchedLocation: '/setup/medication/confirm',
        ),
        isNull,
      );
    });

    test('未完成 setup + 在 / → /setup (引导)', () {
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/'),
        '/setup',
      );
    });

    test('未完成 setup + 在 /settings → /setup (引导)', () {
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/settings'),
        '/setup',
      );
    });

    test('未完成 setup + 在 /settings/reminders → /setup (嵌套子页也算引导)', () {
      expect(
        setupRedirect(
          isSetupDone: false,
          matchedLocation: '/settings/reminders',
        ),
        '/setup',
      );
    });

    test('已完成 setup + 在 / → null (正常使用)', () {
      expect(
        setupRedirect(isSetupDone: true, matchedLocation: '/'),
        isNull,
      );
    });

    test('已完成 setup + 在 /setup → / (回根, 用户已设置完不该再 setup)', () {
      expect(
        setupRedirect(isSetupDone: true, matchedLocation: '/setup'),
        '/',
      );
    });

    test('已完成 setup + 在 /setup/any-sub-path → / (修前 == bug 漏跳)', () {
      // v0.30 R95 task 32 修: 已完成 setup 用户访问 /setup/consent (假设未来
      // 加的子路径) 应跳根, 修前 == '/setup' 漏判 → 留在 /setup/consent
      expect(
        setupRedirect(isSetupDone: true, matchedLocation: '/setup/consent'),
        '/',
      );
    });
  });

  group('setupRedirect 边界 case', () {
    test('不误匹配 /setup-thing (hypothetical 别的路径, 非 /setup 子路径)', () {
      // 守卫用 == '/setup' || startsWith('/setup/') (有尾斜杠)
      // → 不会误匹配 /setup-thing 这种未来如果加的路径
      // 未完成 setup + 在 /setup-thing → 引导 /setup
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: '/setup-thing'),
        '/setup',
      );
    });

    test('空 matchedLocation 走 /setup 引导 (用户进未知路径)', () {
      expect(
        setupRedirect(isSetupDone: false, matchedLocation: ''),
        '/setup',
      );
    });
  });
}
