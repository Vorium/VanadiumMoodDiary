// v0.17 round 4: 跨 midnight 计算 next refresh 时刻的纯函数测
//
// 不测试 AppRoot widget (需要 mock path_provider + db + 一堆 provider)
// 只测核心逻辑:`nextMidnightRefresh(now)` 应该返回
// 第二天 00:00:05 - now 的 Duration,且正数
//
// v0.23 round 40 (sp-zh D-06 fix): 改用 TZDateTime (DST 安全)
// 旧测试用 DateTime 已不兼容, 全部加 .local 包装成 TZDateTime
import 'package:chroniccare/app.dart' show nextMidnightRefresh;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

tz.TZDateTime _local(int y, int m, int d, [int h = 0, int mi = 0, int s = 0]) {
  return tz.TZDateTime(tz.local, y, m, d, h, mi, s);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('nextMidnightRefresh (v0.17 round 4 跨 midnight 自动 refresh)', () {
    test('0:00:00 时返回 ~5 秒（buffer）', () {
      final now = _local(2026, 7, 17, 0, 0, 0);
      final delay = nextMidnightRefresh(now);
      expect(delay.inSeconds, 5);
    });

    test('12:00:00 时返回 12h + 5s', () {
      final now = _local(2026, 7, 17, 12, 0, 0);
      final delay = nextMidnightRefresh(now);
      // 43200s = 12h, + 5s = 43205
      expect(delay.inSeconds, 12 * 3600 + 5);
    });

    test('23:59:30 时返回 35s', () {
      final now = _local(2026, 7, 17, 23, 59, 30);
      final delay = nextMidnightRefresh(now);
      // 00:00:05 - 23:59:30 = 35s
      expect(delay.inSeconds, 35);
    });

    test('跨月边界 7月31 23:59:50 → 8月1 00:00:05 = 15s', () {
      final now = _local(2026, 7, 31, 23, 59, 50);
      final delay = nextMidnightRefresh(now);
      expect(delay.inSeconds, 15);
    });

    test('跨年边界 12月31 23:59:55 → 1月1 00:00:05 = 10s', () {
      final now = _local(2026, 12, 31, 23, 59, 55);
      final delay = nextMidnightRefresh(now);
      expect(delay.inSeconds, 10);
    });

    test('永远是正数（即便调用时刻紧贴 00:00:05 后）', () {
      // 0:00:06 时,下一天 00:00:05 = 23h 59m 59s
      final now = _local(2026, 7, 17, 0, 0, 6);
      final delay = nextMidnightRefresh(now);
      // ~86399s (24h - 1s)
      expect(delay.inSeconds, greaterThan(86300));
      expect(delay.inSeconds, lessThan(86400));
    });
  });
}
