工作目录: D:\Batch\chroniccare
视角: emilkowalski（设计工程师 / 动效）

【BUDGET 硬上限 250 调用，超过立即收工】
【已预读】AGENTS.md、CHANGELOG、pubspec.yaml（主对话已载入，你不需要再 read）
【策略】grep-first，不要 read 全文件

# 步骤

## 1. 一次拿全量问题清单（60 调用内）

并行跑以下 grep（output_mode=content，context=0）：

```
# 动效 hard-code
ripgrep "Curves\." lib/ -t dart
ripgrep "Duration\(milliseconds:" lib/ -t dart
ripgrep "Duration\(seconds:" lib/ -t dart

# 设计 token hard-code
ripgrep "Color\(0x" lib/ -t dart
ripgrep "EdgeInsets\.(all|symmetric|fromLTRB|only)\([0-9]" lib/ -t dart
ripgrep "BorderRadius\.(circular|all|only)\([0-9]" lib/ -t dart
ripgrep "fontSize: [0-9]" lib/ -t dart
ripgrep "elevation: [0-9]" lib/ -t dart

# ink 反馈
ripgrep "InkWell\(" lib/ -t dart -A 1
ripgrep "onPressed: null" lib/ -t dart

# 加载/空/错 态
ripgrep "CircularProgressIndicator" lib/ -t dart
ripgrep "loading_skeleton" lib/ -t dart
```

## 2. 抽样 read 关键 widget（30 调用内）

只 read 4 个文件，验证 grep 结果：
- `lib/core/theme/app_tokens.dart`（确认 token 完整度）
- `lib/core/theme/app_theme.dart`（dark mode 覆盖）
- `lib/presentation/widgets/loading_skeleton.dart`（看 3 态实现）
- `lib/presentation/widgets/press_feedback.dart`（v0.18 :active scale）

## 3. 抽样 read 3 个 page（15 调用内）

- `lib/presentation/pages/home/home_page.dart`（主路径，频度高）
- `lib/presentation/pages/vent/vent_list_page.dart`（频度中）
- `lib/presentation/pages/settings/settings_page.dart`（频度低）

## 4. 输出报告（不再调用工具，直接写文件）

写到 `D:\Batch\chroniccare\reports\audit-emilkowalski.md`（1 份综合，不分 topdown/linebyline）

格式：
```
# emilkowalski 视角审计

## 1. 顶层架构审视（最多 5 条）
- 每条：现象 / file:line / 改法 / 改造成本 / 用户感知收益

## 2. 底层逐行排查（按 P0/P1/P2/P3 排序）
- P0 必修（最多 3 条）
- P1 应修（最多 10 条）
- P2 可修（最多 10 条）
- P3 锦上添花

## 3. 整体评级
一句话（最多 50 字）

## 4. 关键 3 个发现
最关键 3 条 file:line + 一句话
```

【绝对禁止】
- 不要 read 任何 test/ 文件（不在 UI 视角）
- 不要 read domain/ 文件（不在 UI 视角）
- 不要 read 整个 presentation/pages/ 目录
- 不要重复跑同一个 grep
- 不要写长背景介绍，直接给问题
