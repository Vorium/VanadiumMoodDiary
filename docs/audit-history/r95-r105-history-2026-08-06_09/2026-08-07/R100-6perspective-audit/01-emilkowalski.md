# R100 emilkowalski 视角报告（UI / 动效 / 交互 / 设计系统）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动（R99 修复后）
**方法**: 实测 `flutter analyze`（0 issue）+ token/动效/a11y 源码遍历

## 一、已达标（无需动）

| 项 | 证据 |
|---|---|
| 动效 token 集中 | `lib/core/theme/app_motion.dart`（dur + curve token + emil 决策框架注释：100+/day 无动画 / tens/day 微弱 / occasional 标准 / rare delight） |
| 间距/颜色/圆角 token | `app_tokens.dart` 17KB 集中器；R56b 后 46 处 magic spacing 已 token 化 |
| 按压反馈统一 | `press_feedback.dart` + `press_feedback_icon_button.dart`（:active scale） |
| 通用动效组件 | `widgets/animations/`（FadeIn / SlideUp）+ PageTransitionSwitcher |
| dark mode | `app_theme.dart` light + dark 双 ThemeData 就绪 |
| 3 tap 抵达 | R95 sub-spec 8：紧急联系人 5→3 步、数据导出 5→3 步已落地 |
| Tooltip | 主页 header 3 icon button 已加 Tooltip（R95 task 45） |
| 空状态统一 | EmptyState 组件（vent / mood_list 已接入） |

## 二、问题清单

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| E-1 | **a11y 覆盖不足**：全库仅 `app_semantics.dart` 1 个集中器（3 种模式）+ 2 处页面级调用；CheckInButton / MoodQuickButton / StatCard / vent swipe 删除等核心交互件无 Semantics 包装。精神心理用户群 a11y 需求高于平均 | `lib/presentation/widgets/app_semantics.dart` | 底层 | 中 | 中 |
| E-2 | **0 golden test**：60+ 自定义 widget 无视觉回归守护，token 改动靠人眼 | `test/` 无 `*golden*` | 底层 | 中 | 低 |
| E-3 | ThemeExtension 缺位：`app_colors.dart`（371 行）走 BuildContext 扩展函数而非 M3 标准 `ThemeExtension<T>`，第三方主题切换（如高对比模式）无法注入 | `lib/core/theme/app_colors.dart` | 架构 | 复杂 | 低 |
| E-4 | 半角标点视觉一致性：zh/zh_Hant ARB 各 58 key 中文后接半角 `,.;:`，与全角正文混排观感不一致（warn-only） | `lib/l10n/app_zh.arb` | 底层 | 简单 | 低 |
| E-5 | daily_tracking 系列 widget 硬编码中文（"体重 (kg)" / "社交时长 (分钟)" 等），en 模式用户看到中文 label，设计一致性破坏 | `daily_tracking/widgets/*.dart` 约 12 处 | 底层 | 中 | 中 |

## 三、结论

设计系统层面已是项目强项（token 化 + 集中器 + 守护脚本齐全）。剩余欠账集中在 **a11y（E-1）** 与 **视觉回归（E-2）**，均不阻塞上架；E-5 是 en locale 可见的 UI 缺陷，建议上架前修。
