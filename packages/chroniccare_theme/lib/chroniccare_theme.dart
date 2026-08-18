// v1.1.0+184 R128d (R110 阶段 5) — 5 token 集中器公共入口
// v1.1.0+185 R129 P0-3 修正: 加 spring export (跟 5 token 集中器同模式)
//
// 修正 Dart linter implementation_imports 警告:
// - Dart 默认禁止 import 'package:foo/src/X.dart' (内部路径)
// - 修正: 在 lib/ 顶层建 public 入口, export src/ 内部 file
// - caller 改 import 'package:chroniccare_theme/chroniccare_theme.dart'
//
// 6 token 集中器 (跨 5 feature + presentation/widgets + core/ + main 全 app 共享):
// - appTokens: 5 token 主入口 (colors + typography + spacing + motion + radius + 阴影)
// - appColors: iOS system color + 8 health metric palette (Apple Health 风格)
// - appTypography: 17pt body + 13pt caption + ultralight w200 大数字
// - appSpacing: 圆角 14/10 + buttonHeight 50 + 信息密度 +30%
// - appMotion: 0 阴影 + 3 Apple cubic-bezier (R31 视觉层 9.5/10 主因)
// - spring: Spring 物理模型 (R128d 漏拆 / R129 P0-3 修正闭环 6 集中器)

export 'src/app_tokens.dart';
export 'src/app_colors.dart';
export 'src/app_typography.dart';
export 'src/app_spacing.dart';
export 'src/app_motion.dart';
export 'src/spring.dart' show Spring, SpringType;