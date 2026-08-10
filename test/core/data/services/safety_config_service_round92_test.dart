// v0.29 R92 (deepseek P2-44 补测试): SafetyConfigService 8 个 SharedPreferences
// 配置 API 单元 test.
//
// SafetyConfigService 是 SharedPreferences 包装 (业务: 失联通知 enabled /
// thresholdDays / DND / lastAlertAt). 没测试覆盖, SharedPreferences 边界异常
// (null / 缺 key / 跨天 DND) 全靠 SharedPreferences mock 假设, 实际跑通
// safety_watch_service 集成测才知道.
//
// 测试目标:
// 1. 8 个 method default 值 + 写读往返
// 2. setThresholdDays 边界校验 (1-14, 抛 ArgumentError)
// 3. setDoNotDisturb null 删 key
// 4. setLastAlertAt UTC 序列化 (R22 P0-3 修过, 防跨时区 drift)
// 5. isInDnd 4 段: 无 DND / 同天 DND / 跨天 DND / 边界 hour
//
// 依赖: shared_preferences mockInitialValues (跟 R85 safety_watch 同款)
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 固定时间锚点, 避免跨 midnight flake (R19B 立的规矩)
  final fixedNow = DateTime(2026, 8, 3, 10, 0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('enabled', () {
    test('default: 未设 → false (R67 决策, 失联通知默认关)', () async {
      final s = SafetyConfigService();
      expect(await s.isEnabled(), isFalse);
    });

    test('setEnabled(true) → isEnabled() 返 true', () async {
      final s = SafetyConfigService();
      await s.setEnabled(true);
      expect(await s.isEnabled(), isTrue);
    });

    test('setEnabled(false) → isEnabled() 返 false (toggle 关)', () async {
      final s = SafetyConfigService();
      await s.setEnabled(true);
      await s.setEnabled(false);
      expect(await s.isEnabled(), isFalse);
    });
  });

  group('thresholdDays', () {
    test('default: 未设 → 2 天 (defaultThresholdDays)', () async {
      final s = SafetyConfigService();
      expect(await s.getThresholdDays(), 2);
    });

    test('setThresholdDays(7) → getThresholdDays() 返 7', () async {
      final s = SafetyConfigService();
      await s.setThresholdDays(7);
      expect(await s.getThresholdDays(), 7);
    });

    test('setThresholdDays(0) 抛 ArgumentError (边界 < 1)', () async {
      final s = SafetyConfigService();
      expect(
        () => s.setThresholdDays(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setThresholdDays(15) 抛 ArgumentError (边界 > 14)', () async {
      final s = SafetyConfigService();
      expect(
        () => s.setThresholdDays(15),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('setThresholdDays(1) / (14) 边界值通过', () async {
      final s = SafetyConfigService();
      await s.setThresholdDays(1);
      expect(await s.getThresholdDays(), 1);
      await s.setThresholdDays(14);
      expect(await s.getThresholdDays(), 14);
    });
  });

  group('doNotDisturb', () {
    test('default: start/end 都是 null', () async {
      final s = SafetyConfigService();
      final dnd = await s.getDoNotDisturb();
      expect(dnd.start, isNull);
      expect(dnd.end, isNull);
    });

    test('setDND 22~08 → 读出 22 / 8', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 22, endHour: 8);
      final dnd = await s.getDoNotDisturb();
      expect(dnd.start, 22);
      expect(dnd.end, 8);
    });

    test('setDND null → 删 key, 返 (null, null)', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 22, endHour: 8);
      await s.setDoNotDisturb(); // 都 null
      final dnd = await s.getDoNotDisturb();
      expect(dnd.start, isNull);
      expect(dnd.end, isNull);
    });

    test('setDND 只设 start → end 仍 null (允许单边)', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 9);
      final dnd = await s.getDoNotDisturb();
      expect(dnd.start, 9);
      expect(dnd.end, isNull);
    });
  });

  group('lastAlertAt', () {
    test('default: null', () async {
      final s = SafetyConfigService();
      expect(await s.getLastAlertAt(), isNull);
    });

    test('setLastAlertAt(local) → getLastAlertAt 返 local (R22 P0-3 UTC 存)',
        () async {
      final s = SafetyConfigService();
      // v0.22 R30 (sp-zh P1-1): setLastAlertAt 内部 toUtc 存, getLastAlertAt 内部
      // toLocal 读, 保持原 _isSameDay local day 比较行为. 跨时区不变.
      await s.setLastAlertAt(fixedNow);
      final got = await s.getLastAlertAt();
      expect(got, isNotNull);
      expect(got!.year, fixedNow.year);
      expect(got.month, fixedNow.month);
      expect(got.day, fixedNow.day);
      expect(got.hour, fixedNow.hour);
      expect(got.minute, fixedNow.minute);
    });
  });

  group('isInDnd', () {
    test('无 DND 设置 → 永远 false (不打扰逻辑短路)', () async {
      final s = SafetyConfigService();
      expect(await s.isInDnd(fixedNow), isFalse);
    });

    test('同天 DND 9~18, hour=10 → true', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 9, endHour: 18);
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 10, 0)),
        isTrue,
      );
    });

    test('同天 DND 9~18, hour=8 (start 前) → false', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 9, endHour: 18);
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 8, 0)),
        isFalse,
      );
    });

    test('同天 DND 9~18, hour=18 (end 等于, 区间 [start, end) 半开) → false', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 9, endHour: 18);
      // hour=18 不在 [9, 18) 区间内, 不打扰结束
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 18, 0)),
        isFalse,
      );
    });

    test('跨天 DND 22~08, hour=23 → true', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 22, endHour: 8);
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 23, 0)),
        isTrue,
      );
    });

    test('跨天 DND 22~08, hour=7 → true (跨过午夜)', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 22, endHour: 8);
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 7, 0)),
        isTrue,
      );
    });

    test('跨天 DND 22~08, hour=10 (白天) → false', () async {
      final s = SafetyConfigService();
      await s.setDoNotDisturb(startHour: 22, endHour: 8);
      expect(
        await s.isInDnd(DateTime(2026, 8, 3, 10, 0)),
        isFalse,
      );
    });
  });
}
