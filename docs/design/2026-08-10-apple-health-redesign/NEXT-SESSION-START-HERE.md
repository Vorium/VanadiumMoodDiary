# Apple Health Redesign · 新 Session 启动指南

> **Status**: Phase 1.1 ✅ 已完成（commit `739f399`）
> **Next**: 跑 Task 1.2 → 1.3 → 1.4 → Phase 2 (widget) → Phase 3 (3 页面) → Phase 4 (8 页) → Phase 5 (验证)

## 1. 当前状态（git 视角）

- **branch**: `feat/apple-health-redesign`（worktree 内）
- **worktree 路径**: `D:\Batch\chroniccare\.worktrees\apple-health-redesign`
- **git log**:
  ```
  739f399 0.31.0 round 1: app_colors.dart 重写为 iOS system color + 8 health metric palette
  1b851a8 v0.30 R108 revisit god class 收尾 #2 (master 起点)
  ```
- **baseline** (master 锁定, 跨 worktree 一致):
  - analyze: 0 error / 21 warning / 53 info
  - test: **+2036 pass / ~1 skip / -125 pre-existing fail** (fail 不增加 = 零回归)

## 2. 工作目录 + 工具

- **必须 cd 到 worktree**: `Set-Location D:\Batch\chroniccare\.worktrees\apple-health-redesign`
- **flutter**: `& "D:\Batch\Software\flutter\bin\flutter.bat" <cmd>`
- **dart**: `& "D:\Batch\Software\flutter\bin\dart.bat" <cmd>`
- **git**: `& "D:\Batch\Software\flutter\bin\mingit\cmd\git.exe" <cmd>`

每个 bash 命令都是 non-interactive shell，**PATH 不会自动加载**，必须用全路径或每条命令前 `$env:Path = "..."`。

## 3. 文档入口

- **spec**: `docs/design/2026-08-10-apple-health-redesign/spec.md` (22KB, 读 §3.1-3.4 + §6 决策表)
- **plan**: `docs/design/2026-08-10-apple-health-redesign/plan.md` (16KB, 读 Phase 1 Task 1.2/1.3/1.4 + Phase 2/3/4/5)

## 4. 决策（已锁定 · 用户确认）

| # | 决策 | 值 |
|---|---|---|
| 1 | 主色 | iOS green `#34C759` |
| 2 | 大数字 ultralight | 全部 StatCard 用 w200 |
| 3+4 | 按钮 | buttonHeight 88 → 50 + radiusButton 24 → 14 |
| 5 | 彩色 metric tile | 8 个全面板 |
| 6 | Spring | 引入 Spring class + 保留 MotionScheme 双轨 |
| 7 | translucent AppBar | 引入 (BackdropFilter blur) |
| 8 | dark mode | 一次到位 |

## 5. 跑 Task 1.2 的 subagent prompt

新 session 第一句让 Mavis： "跑 Apple Health Phase 1 Task 1.2"。Mavis 会读 spec/plan 自动生成 prompt。

或者直接复制下面 prompt 启动 coder subagent：

```
工作目录: D:\Batch\chroniccare\.worktrees\apple-health-redesign

上下文:
- Flutter 3.44.9 / Dart 3.12.2 (PATH: D:\Batch\Software\flutter\bin)
- Git: D:\Batch\Software\flutter\bin\mingit\cmd\git.exe
- 慢病管理 App, 4 层架构 (presentation / domain / data / core)
- 不要碰业务逻辑 / domain 层 / data 层 / ARB / CHANGELOG

设计文档:
- docs/design/2026-08-10-apple-health-redesign/spec.md (读 §3.2 typography)
- docs/design/2026-08-10-apple-health-redesign/plan.md (读 Phase 1 Task 1.2)

上游完成: Task 1.1 commit 739f3997 (主色改 iOS green)

Baseline:
- analyze: 0 error / 21 warning / 53 info
- test: 2036 pass / 1 skip / 125 pre-existing fail (master 一致)

任务: Phase 1 Task 1.2 — 重写 app_typography.dart

14 step (按顺序):
1. fontSizeButton 20 → 17 (iOS button standard)
2. fontSizeBody 18 → 17 (iOS body)
3. fontSizeLabel 16 → 15
4. fontSizeCaption 14 → 13
5. fontSizeMicro 10 → 11 / fontSizeXxxSmall 8 → 9
6. fontSizeBodySm 13 → 12 / fontSizeCaptionSm 12 → 11
7. 新增 fontSizeMetricXl 34 / fontSizeMetricLg 28 / fontSizeMetricMd 22
8. lineHeightTight 1.2 → 1.1
9. lineHeightNormal 1.5 → 1.4 / lineHeightLoose 1.8 → 1.6
10. 新增 static const FontWeight fontWeightUltralight = FontWeight.w200
11. 新增 static const FontWeight fontWeightLight = FontWeight.w300
12. 新增 textStyleMetricXl(c) / textStyleMetricLg(c) / textStyleMetricMd(c) 3 helper (ultralight, color 走 AppColors.textPrimaryColor)
13. 现有 textStyleTitle/Headline/Body/Label/Button/Caption/Micro 7 helper 加 letterSpacing:
    - title (28) / headline (22): -0.5
    - button (17) / body (17): -0.2
    - label (15) / caption (13) / micro (11): 0
14. textStyleButton 同步改字号到 17

不要改:
- lineHeightSnug / lineHeightRelaxed (保留)
- fontSizeLabelSm 11 (保留)
- textStyleLabelStrong / textStyleBodyStrong / textStyleButtonInverse / textStyleLabelMedium / textStyleCaptionHint / textStyleCaptionStrong / textStyleLegal / textStyleMono 8 helper (不改)
- fontSizeScoreLg/Xl/Xxl 3 老 token (v0.26 R57 已删, 别复活)

facade 同步: lib/core/theme/app_tokens.dart
- 加 fontSizeMetricXl/Lg/Md 3 转发
- 加 fontWeightUltralight/Light 2 转发
- 现有字号/行高/weight 不变 (已存在)

验证 (必跑):
Set-Location D:\Batch\chroniccare\.worktrees\apple-health-redesign
& "D:\Batch\Software\flutter\bin\flutter.bat" analyze --no-pub
& "D:\Batch\Software\flutter\bin\flutter.bat" test --reporter compact

- flutter analyze 必须 0 error
- flutter test 必须 baseline +2036 ~1 -125 (fail 数不增加)
- 如果 fail 增加 5+: 停下报告, 修到不增加

Git:
- 1 commit: "0.31.0 round 2: app_typography.dart 改 iOS 17pt body + 13pt caption + ultralight w200 大数字"
- 不 push, commit 到 feat/apple-health-redesign
- 不改 docs/ / CHANGELOG.md / pubspec.yaml / ARB

输出要求 (报告 ≤200 字):
1. 改了哪几个 token (列具体值)
2. 新增了哪几个 helper/weight
3. flutter analyze 末行
4. flutter test 末行
5. 1 个 commit hash
6. 跟 baseline 偏离的 fail (如有) 和修复

工作流约束:
- 你只改 lib/core/theme/app_typography.dart + lib/core/theme/app_tokens.dart 2 个文件
- 不要改其他文件
- 严格按 14 step 走, 别发挥

异常处理:
- build_runner 缺 .g.dart: 跑 flutter pub run build_runner build
- 路径问题: 上面路径都给了, 别用相对

完成后给我报告。
```

## 6. 跑完后

- 检查 commit hash + 报告
- 跑 Task 1.3 (app_spacing.dart) + Task 1.4 (app_motion.dart)
- Phase 1 完跑 1 个 reviewer subagent
- 进 Phase 2 (widget 重写)

## 7. 完整 5 phase 概览

| Phase | 内容 | 估时 | 并行 |
|---|---|---|---|
| 1 | Token 4 文件（1.1-1.4） | 4-6h | 1 subagent 串行 |
| 2 | 5 widget 重写 + 3 widget 新增 | 6-8h | 4 subagent 并行 |
| 3 | Home / Setup / Medication 重设 | 6-8h | 3 subagent 并行 |
| 4 | 8 页 follow | 4-5h | 1 subagent |
| 5 | 验证 + CHANGELOG | 2-3h | 1 reviewer |
| **总计** | | **22-30h** | **5-8 session** |
