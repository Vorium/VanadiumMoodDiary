# 7 视角综合审视 Spec · 2026-08-11

> **触发**: v0.31.0 Apple Health 风格重设计 23 commit 落地后 (master HEAD `01d8f4a`)，跑综合审视确认无新引入问题
> **基线**: master +2036/1/128 pre-Apple Health → master +2102/1/127 post-Apple Health（净改善 +66 pass / -1 fail）
> **前次审计**: docs/audit/2026-08-10-cleanup/R108-overall-report.md (16.7KB) + 10 个 sub-report (R107 cleanup 9 视角)

## 7 视角分工

| # | 视角 | 关注点 | 输出位置 |
|---|---|---|---|
| 1 | **emilkowalski** | 动效 / 组件设计 / 看不见的细节 / 按钮 / iOS HIG | `01-emil.md` |
| 2 | **superpowers-en** | 工程师实操 / TDD / 调试 / code review | `02-superpowers-en.md` |
| 3 | **superpowers-zh** | 中文版实操 / 中国开发者习惯 | `03-superpowers-zh.md` |
| 4 | **flutter-specification** | Flutter v3.1 规范 14 章 + 6 附录 | `04-flutter-spec.md` |
| 5 | **AppStore** | iOS 上架 / 5.1.3 抽审 / Info.plist / LaunchImage | `05-appstore.md` |
| 6 | **GooglePlay** | Android 上架 / Data Safety / 16KB / PrivacyInfo | `06-googleplay.md` |
| 7 | **Apple Health** | Apple Health app 设计语言 / iOS 17/18 视觉 / 11 个 feature 视觉 | `07-apple-health.md` |

## 5 维度评估（每个 subagent 必查）

1. **确认需要外部链接的内容是否已全部隐藏**（import 'package:...' 全部对内 / 远程 API 全部白名单）
2. **检查是否还有上架 / 架构 / 建议重构 / 半成品相关问题**（跟 R108 报告 §六 R109+ 43 项对照）
3. **顶层架构审视**（高内聚低耦合 / 是否可走 feature-first / 是否可拆 pub workspace）
4. **底层逐行排查**（遍历所有文件 / 列出可优化点 / 待修 bug）
5. **遍历完后更新 dev doc**（AGENTS.md / CHANGELOG / docs/）

## 整合 subagent

**1 个** subagent 读 7 份视角报告 → 整合 1 份 `00-FINAL-CONSOLIDATION.md`：
- 标出每条 finding 是**架构级**还是**底层**（emil 哲学：架构是"什么"，底层是"怎么做"）
- **修复难度**（低 1-3h / 中 1-2d / 高 1w+）
- **按修复优先级排序**（P0 上架阻塞 / P1 R109+ / P2 R110+ / P3 长期）
- 去重（7 视角可能重复发现同一问题）

## 输出格式

每份 sub-report ≤ 200 行 markdown：

```markdown
# 视角 N 报告 · [视角名]

## 元信息
- 跑时间: [YYYY-MM-DD HH:MM]
- baseline: master HEAD `01d8f4a` (v0.31.0)
- 关注: [本视角核心]

## 5 维度评估

### 1. 外部链接检查
- [OK] / [ISSUE] + 文件:行号

### 2. 上架 / 架构 / 重构 / 半成品
- [OK] / [ISSUE + R108 §六对照]

### 3. 顶层架构审视
- 整体评价: [1-2 段]
- 高内聚低耦合度: [N/10]
- 重构建议: [列表]

### 4. 底层逐行排查
- 已遍历: [N 个文件 / N 行]
- 找到 bug: [列表 + 难度 + 优先级]
- 优化点: [列表]

### 5. dev doc 更新
- AGENTS.md: [改了 / 没改 + 原因]
- CHANGELOG: [加了 / 没加 + 原因]

## 总结
[本视角对项目 1-2 段总评]
```

## 时间线

- 现在 + 0min: 写 spec/plan + 派 7 subagent 并行
- 现在 + 1-2h: 7 subagent 完跑 → 派整合 subagent
- 现在 + 2-3h: 整合完跑 → 报告
- 现在 + 3-4h: 更新 dev doc + CHANGELOG

## 工作目录

`D:\Batch\chroniccare` （master 主目录）
- Flutter: `D:\Batch\Software\flutter\bin\flutter.bat`
- Git: `D:\Batch\Software\flutter\bin\mingit\cmd\git.exe`
- Python: `python scripts/check_*.py` (18 守门员)
- Dart: `dart scripts/check_all.dart` (1 个)

报告输出: `docs/audit/2026-08-11-cleanup/01-emil.md` ... `07-apple-health.md` + `00-FINAL-CONSOLIDATION.md`

## 跑前 baseline 锁定

- master HEAD: `01d8f4a` v0.31.0
- test baseline: +2102 pass / 1 skip / 127 pre-existing fail
- analyze: 0 error / 90 issues
- 已知 pre-existing fail 列表: R108 §六

## 重要约束

- **不重写**任何功能代码
- **不修改** master HEAD
- **新文件可写** (报告 markdown)
- 每个 subagent **只读** `lib/` `test/` `docs/` `scripts/` `pubspec.yaml` `README.md` `AGENTS.md` 5 类文件
- 业务逻辑 / domain / data 层**不重新审视**（R108 已审）→ 重点：presentation 层 + 跨层交互

## 跟 R108 差异

- R108 9 视角覆盖了 R107 cleanup 全部 1.2MB 历史报告
- 这次 7 视角**只针对 v0.31.0 新引入的 23 commit** (Apple Health redesign)，重点找新问题
- R108 的 9 视角报告可作 baseline 对照（"这问题 R108 有吗？"）
