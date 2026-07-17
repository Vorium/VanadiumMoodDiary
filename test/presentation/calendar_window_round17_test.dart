// v0.17 round 7 (B1+B2 TDD demo): CalendarWindowNotifier test
//
// 这个 test 文件本身就是 B4 (TDD 纪律) 的 demo:
// 1. 先写失败 test (验证行为)
// 2. 实现 Notifier
// 3. test 通过
// 4. widget 接 provider
//
// 覆盖:
// - build 默认值是 30
// - setDays(7/30/90) 接受
// - setDays(invalid value) 抛 ArgumentError
// - setDays(same value) dedup,state 不变
// - 跨 container 独立(每个 ProviderContainer 自己的 state)
import 'package:chroniccare/presentation/providers/calendar_window_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarWindowNotifier (v0.17 round 7 B1+B2)', () {
    test('build 默认值 = 30', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(calendarWindowProvider), 30);
    });

    test('setDays(7) 接受 → state = 7', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(calendarWindowProvider.notifier).setDays(7);
      expect(container.read(calendarWindowProvider), 7);
    });

    test('setDays(30/90) 接受', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(calendarWindowProvider.notifier).setDays(30);
      expect(container.read(calendarWindowProvider), 30);
      container.read(calendarWindowProvider.notifier).setDays(90);
      expect(container.read(calendarWindowProvider), 90);
    });

    test('setDays(invalid value) 抛 ArgumentError', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(calendarWindowProvider.notifier).setDays(45),
        throwsA(isA<ArgumentError>()),
      );
      // state 保持原值
      expect(container.read(calendarWindowProvider), 30);
    });

    test('setDays(same as current) dedup, state 不变', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // 默认 30,再设 30
      container.read(calendarWindowProvider.notifier).setDays(30);
      expect(container.read(calendarWindowProvider), 30);
    });

    test('不同 container 状态独立', () {
      final c1 = ProviderContainer();
      final c2 = ProviderContainer();
      addTearDown(() {
        c1.dispose();
        c2.dispose();
      });
      c1.read(calendarWindowProvider.notifier).setDays(7);
      expect(c1.read(calendarWindowProvider), 7);
      expect(c2.read(calendarWindowProvider), 30); // c2 不受 c1 影响
    });
  });
}
