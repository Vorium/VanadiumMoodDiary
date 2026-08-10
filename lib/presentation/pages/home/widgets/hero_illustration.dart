// v0.28 R81 (emil design-4): HomeHeroIllustration 主页 hero 插画
//
// 背景 (R81 emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 截图):
//   B 站主页全屏治愈系插画 hero (蓝天 + 太阳 + 云 + 熊猫 + 蝴蝶 +
//   叶子), 跟功能区 (粉色卡片) 视觉分层, 提升"温暖感", 跟精神
//   心理 App 调性对齐 (用户进首页, 视觉冲击是'温暖/治愈' 不是
//   '冷数据/打卡任务')。
//
// 修法: 自绘 hero (无 asset 依赖, 跨平台稳), 渐变天空 + emoji
// 太阳云 + 主页 CTA 上方 1 个 hero area (200dp 高, 横滑不限)。
// Stack + Positioned 组合 4 元素:
// - 顶层: ☀️ 大太阳 + 表情 (IP 化, R81-1 ipEmojiFor 复用)
// - 中层: ⛅ 2 个云 (不同位置)
// - 底层: LinearGradient 天空 (lightTheme 浅蓝, darkTheme 深紫)
// - 底层: Container 圆角 (radiusCard) + 阴影
//
// emil 频度: rare (用户每次进首页看 1 次, 跟主页其他 widget 比
// 不高频), rare 频度可加 delight (装饰性, 不影响主交互)。
// 静态 widget, 不动画 (避免频度问题)。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 主页 hero 插画 — 治愈系 + IP 化太阳云 (B 站风格)
class HomeHeroIllustration extends StatelessWidget {
  final double height;

  const HomeHeroIllustration({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
      ),
      decoration: BoxDecoration(
        // v0.28 R81: 渐变天空 (lightTheme 浅蓝 → 淡黄; darkTheme 深紫 → 暗蓝)
        // 跟 B 站蓝天风格一致, 病耻感场景降冷色调
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTokens.tintedPrimaryDeep(context).withValues(alpha: 0.08),
            AppTokens.tintedPrimarySoft(context).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        boxShadow: [
          // R102 (P1): 改用 Theme.of(context).colorScheme.shadow 替代
          // Colors.black 硬编码, dark mode 下阴影自动适配
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Stack(
        children: [
          // 底层云 (左侧)
          Positioned(
            left: 24,
            top: 36,
            child: Text(
              '⛅',
              style: TextStyle(
                fontSize: 36,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          // 底层云 (右侧)
          Positioned(
            right: 60,
            top: 18,
            child: Text(
              '☁️',
              style: TextStyle(
                fontSize: 28,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          // 顶层太阳 (大, 居中偏右)
          Positioned(
            right: 18,
            bottom: 12,
            child: Text(
              MoodVisual.ipEmojiFor(5), // ☀️ 晴
              style: const TextStyle(fontSize: 56),
            ),
          ),
          // 顶层叶子 (左下, 装饰)
          Positioned(
            left: 12,
            bottom: 8,
            child: Text(
              '🌿',
              style: TextStyle(
                fontSize: 32,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
        ),
      ), // ExcludeSemantics
    );
  }
}
