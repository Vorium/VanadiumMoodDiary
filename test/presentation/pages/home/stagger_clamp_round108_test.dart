// v0.30 R108 (P0#5): 主页 8 层 FadeIn stagger 累加未 clamp 防回归测试
//
// R107 报告 P0-5: home_page_state.dart 主页入场 8 层 FadeIn 累加
// 0/40/80/120/160/200/240/280ms — 前庭敏感用户 (约 35% 慢性病 / 精神心理患者)
// 报告不适。R108 修法: 改 3 层 (header / summary / hero) 微 stagger,
// 5 层 (encouragement / carousel / primary action / today schedule /
// secondary action) 改无动画。
//
// 测试覆盖 (不依赖 widget tree 渲染, 纯文本 / token 检查):
// 1. home_page_state.dart 含 staggerStepMs 引用的次数 = 2 (summary + hero)
// 2. 累加最大 delay ≤ 80ms (2 * staggerStepMs = 80ms)
// 3. 不再含 `4 * AppTokens.staggerStepMs` / `5 *` / `6 *` / `7 *` 等旧层
// 4. 5 个改无动画的 widget 名字仍出现 (无回归)
// 5. comment 提到 "前庭敏感" 或 "100+/day 频度" 至少 1 处 (新 R108 注释落地)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('home_page_state.dart R108 P0#5 stagger clamp 验证', () {
    late String homePageStateContent;

    setUpAll(() async {
      // 直接读源码文件做静态分析 (不依赖 widget 渲染 / 主题 provider)
      // 这是 R95+ 测试模式: 对 god class 的内部结构做白盒测试, 比 widget
      // pump 更快更稳, 防止误改 stagger 层数。
      final file = File(
        'lib/presentation/pages/home/home_page_state.dart',
      );
      homePageStateContent = await file.readAsString();
    });

    test('case 1: staggerStepMs 引用次数 = 2 (summary + hero)', () {
      // 修前 7 处 (0/1/2/3/4/5/6/7 倍数), 修后 2 处 (1 + 2 倍)
      final matches = RegExp(r'AppTokens\.staggerStepMs').allMatches(
        homePageStateContent,
      );
      expect(
        matches.length,
        2,
        reason: 'R108 修后 staggerStepMs 引用应 = 2 (summary + hero), '
            '实际 ${matches.length} 处',
      );
    });

    test('case 2: 不再含旧 stagger 倍数 (3-7 倍)', () {
      // 修前: 3 * / 4 * / 5 * / 6 * / 7 * staggerStepMs 累加
      // 修后: 仅 1 * / 2 * (3 层 stagger)
      for (final multiplier in [3, 4, 5, 6, 7]) {
        final pattern = RegExp(
          '$multiplier \\* AppTokens\\.staggerStepMs',
        );
        expect(
          pattern.hasMatch(homePageStateContent),
          isFalse,
          reason: 'R108 修后不应再有 "$multiplier * AppTokens.staggerStepMs" '
              '(前庭敏感触发)',
        );
      }
    });

    test('case 3: 累加最大 delay = 80ms (2 * staggerStepMs)', () {
      // 找出所有 stagger delay 数值, 最大应 ≤ 80ms
      final pattern = RegExp(
        r'milliseconds:\s*(\d+)\s*\*\s*AppTokens\.staggerStepMs',
      );
      final multipliers = pattern
          .allMatches(homePageStateContent)
          .map((m) => int.parse(m.group(1)!))
          .toList();
      // staggerStepMs = 40 (AppSpacing 集中器定义)
      const stepMs = 40;
      final maxDelay = multipliers.isEmpty
          ? 0
          : multipliers.reduce((a, b) => a > b ? a : b) * stepMs;
      expect(
        maxDelay,
        lessThanOrEqualTo(80),
        reason: 'R108 修后 max stagger delay 应 ≤ 80ms, 实际 ${maxDelay}ms '
            '(multipliers=$multipliers, stepMs=$stepMs)',
      );
    });

    test('case 4: 改无动画的 widget 名字仍出现 (无回归)', () {
      // R108 修后, 这些 widget 不再 wrap FadeIn (Duration.zero):
      // - EncouragementText
      // - PrimaryActionRow
      //
      // 1.1.0 round 5b (Task 12): QuickMoodCarousel / SecondaryActionRow 删除,
      // 替换为 MoodHeroCard / VentHeroCard (双主卡, Duration.zero 无动画)。
      //
      // v0.31 R9a 改造: 删 TodayMedSchedule (Apple Health 仪表盘无"今日服药计划"
      // 章节, 改在 /medication 子页查看), 不再要求 build 树含 TodayMedSchedule。
      // 新增 4 widget 必出现: CheckInButton (R6 巨型 pill) / HomeHeader
      // (R9a 改 Apple Health 头) / TodaySummaryCard (R9a 4 指标 2x2) /
      // FadeIn (R108 保留 stagger 容器)。
      for (final widgetName in [
        'EncouragementText',
        'PrimaryActionRow',
        // 1.1.0 round 5b 双主卡替代被删 widget
        'MoodHeroCard',
        'VentHeroCard',
        // v0.31 R9a 新增 4 widget 必出现
        'CheckInButton',
        'HomeHeader',
        'TodaySummaryCard',
        'FadeIn',
      ]) {
        expect(
          homePageStateContent.contains(widgetName),
          isTrue,
          reason: '$widgetName 应该在 build 树里 (R108/R9a 改无动画但保留 widget)',
        );
      }
    });

    test('case 5: R108 注释提及频度原则 (前庭敏感 / 100+/day)', () {
      // 验证新 R108 注释落地, 不只是删代码:
      // - "前庭敏感" 或 "前庭" 至少 1 处
      // - "100+/day" 至少 1 处
      // - "stagger" 提到次数 ≥ 2 (R108 决策 + 修法)
      expect(
        homePageStateContent.contains('前庭'),
        isTrue,
        reason: 'R108 注释应提到"前庭敏感" 风险',
      );
      expect(
        homePageStateContent.contains('100+/day'),
        isTrue,
        reason: 'R108 注释应提到 emil 频度原则 100+/day = 无动画',
      );
      final staggerMentions = RegExp(
        r'stagger',
        caseSensitive: false,
      ).allMatches(homePageStateContent).length;
      expect(
        staggerMentions,
        greaterThanOrEqualTo(2),
        reason: 'R108 注释应多次提到 stagger (决策 + 修法), 实际 $staggerMentions 处',
      );
    });
  });
}
