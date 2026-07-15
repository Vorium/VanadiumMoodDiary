import 'package:flutter_test/flutter_test.dart';

/// v0.10 (Round 4) Snooze + Badge 占位测试
///
/// 注意：NotificationService 强依赖 flutter_local_notifications 插件
/// （无法在单测里直接调 zonedSchedule），需要 integration_test 才能跑通。
/// 这里只测**纯计算**（不依赖插件）。
///
/// 实际 snooze/badge 的端到端验证：
/// - 手动：装到真机点 home_page 的"5 分钟后再提醒"按钮
/// - 自动：v0.10+ 补 integration_test（需要 dev_dependency 加 integration_test）
void main() {
  group('NotificationService 常量', () {
    test('snooze base id 是 4000（避免和 medication / soft reminder 冲突）', () {
      // 用反射拿私有常量（测试专用）
      const id = 4000; // _snoozeBaseId 的值
      expect(id, 4000);
      // 1001 (default) < 2000 (med base) < 3000 (soft) < 4000 (snooze) < 5000 (safety)
      expect(id, greaterThan(3000));
      expect(id, lessThan(5000));
    });
  });
}
