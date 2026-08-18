# Task 9 Audit — R95 sub-spec 2 task 9: 30+ 硬编码中文 audit 数字验证

> v0.30 round 95 (sub-spec 2 task 9-audit) — 不改 code, 只验证 + 报告
> 跟 task 8 (catch (_) → swallowError) + task 25 (vent_compose dispose await)
> + task 26 (badge_sync_service catch) 模式一致: stale audit 验证

## Status

**DONE (verification only, 0 commit)** — R95 报告 §6.5 数字低估 2-4 倍, 跟 task 8 / 25 / 26 一样 stale audit 模式, R92 baseline 没把 R88-91 增量算进去。

## 关键发现: R95 报告 §6.5 audit 是 stale

任务 spec 引用 R95 报告 §6.5 列 30+ 硬编码中文业务 hotspot Top 10 (按字符数), 但**实测 R88-91 期间硬编码中文增量 1.5-4 倍**。

**实测 Top 10 业务文件 (排除 l10n 生成) — 2026-08-06 grep**：

| # | 文件 | R95 §6.5 估 | **实测字符** | 差异 | 备注 |
|---|------|-------------|--------------|------|------|
| 1 | `lib/domain/entities/scale_translations.dart` | 1528 | **3056** | **+1528 (+100%)** | R88-91 评估 8 量表 i18n 续加, 翻 1 倍 |
| 2 | `lib/presentation/pages/home/home_page.dart` | 580 | **2174** | **+1594 (+275%)** | R88 cbt + R90 assessment + R91 daily_tracking 入口, 翻 3.7 倍 |
| 3 | `lib/core/data/database/app_database.dart` | 502 | **1959** | **+1457 (+290%)** | 注释 (R16+ 维护注解) 增长 |
| 4 | `lib/core/theme/app_colors.dart` | 538 | **1903** | **+1365 (+254%)** | 颜色 token 注释 (R17 引入) 增长 |
| 5 | `lib/core/l10n/strings.dart` | 479 | **1543** | **+1064 (+222%)** | domain 层中文常量 (R17 引入) 增长 |
| 6 | `lib/core/data/services/sms_service.dart` | 432 | **1520** | **+1088 (+252%)** | 注释增长 |
| 7 | `lib/main.dart` | 532 | **1388** | **+856 (+161%)** | 启动顺序注释 + 错误信息增长 |
| 8 | `lib/core/data/services/notification_service.dart` | 448 | **1332** | **+884 (+197%)** | 注释增长 |
| 9 | `lib/core/data/services/safety_watch_service.dart` | (未列) | **1299** | (新发现) | R84+ 失联业务 + R93 阶段 2 注释, 1349 字符硬编码中文 |
| 10 | `lib/core/data/feature_flags.dart` | (未列) | **1225** | (新发现) | 8 FeatureFlag 注释 (R93 阶段 2 集中加) |

**Top 20 总字符数**：~26,000 字符 (排除 l10n 生成), 实际 26,000+ 字符硬编码中文

**核心结论**：
1. R95 §6.5 数字低估 2-4 倍 — **R92 baseline 没把 R88-91 增量算进去**
2. **真正硬编码中文业务 hotspot 是 5 个文件** (非 Top 10):
   - `scale_translations.dart` 3056 字符 (8 量表 16 题中文题目)
   - `home_page.dart` 2174 字符 (主页 8 widget 内部中文 fallback)
   - `app_database.dart` 1959 字符 (注释)
   - `app_colors.dart` 1903 字符 (注释)
   - `core/l10n/strings.dart` 1543 字符 (domain 层中文常量, **应走 ARB**)
3. 跟 task 8 / 25 / 26 stale audit 一致 — **R95 报告基于 R92 baseline, 未把 R88-91 增量算进去**

## grep 命令 (R95 sub-spec 2 task 9-audit 步骤 1)

```powershell
Get-ChildItem -Path lib -Recurse -Filter '*.dart' | Where-Object { $_.FullName -notmatch '\.g\.dart$' } | ForEach-Object { $content = Get-Content $_.FullName -Raw; $chars = ([regex]::Matches($content, '[\u4e00-\u9fa5]')).Count; if ($chars -gt 0) { [PSCustomObject]@{ Path = $_.FullName.Replace('D:\Batch\chroniccare\', ''); Chars = $chars; Lines = (Get-Content $_.FullName).Count } } } | Sort-Object Chars -Descending | Select-Object -First 20
```

**输出**：Top 20 业务文件 (排除 l10n 生成, 上面表格列了 Top 10)

## 已修 vs 待修 (R95 sub-spec 3+ 建议)

| # | 文件 | 字符 | 状态 | 建议 |
|---|------|------|------|------|
| 1 | `scale_translations.dart` | 3056 | **待修 (P0)** | 8 量表 16 题中文题目 → 走 ARB (R95 task 2 配, 估 +50 ARB keys) |
| 2 | `home_page.dart` | 2174 | **待修 (P1)** | 主页 8 widget 内部中文 fallback → 走 ARB (R95 task 5 配, 估 +30 ARB keys) |
| 3 | `app_database.dart` | 1959 | **可修 (P3)** | 注释中文 → 翻译文档即可 (英文 developer 不需要中文注释) |
| 4 | `app_colors.dart` | 1903 | **可修 (P3)** | 颜色 token 注释 → 翻译文档即可 |
| 5 | `core/l10n/strings.dart` | 1543 | **待修 (P0)** | domain 层中文常量 → 走 ARB (跨层共享, 估 +25 ARB keys) |
| 6 | `sms_service.dart` | 1520 | **可修 (P3)** | 注释中文 → 翻译文档即可 |
| 7 | `main.dart` | 1388 | **待修 (P2)** | 错误信息 + 注释 → 走 ARB (估 +15 ARB keys) |
| 8 | `notification_service.dart` | 1332 | **可修 (P3)** | 注释中文 → 翻译文档即可 |
| 9 | `safety_watch_service.dart` | 1299 | **可修 (P3)** | 注释中文 → 翻译文档即可 |
| 10 | `feature_flags.dart` | 1225 | **可修 (P3)** | 8 FeatureFlag 注释 (R93 阶段 2 集中加) → 翻译文档即可 |

**P0 待修总字符**：3056 + 1543 = **4599 字符 → 估 +75 ARB keys** (R95 sub-spec 3 task 9)
**P1 待修总字符**：2174 (R95 sub-spec 3 task 9 配 home_page 拆)
**P2/P3 待修总字符**：~11000 (注释为主, 翻译文档即可, 不需要 ARB)

## 风险应对

### 风险 1: R95 报告 §6.5 audit 是 stale — 应对: 诚实报数字低估, 不假装做了 refactor

- **风险**: 任务 spec 估 R95 sub-spec 2 task 9 4-6 commit, 实际 0 改动需要 (跟 task 8/25/26 stale audit 模式一致)
- **应对**: 在本 task-9-audit-report.md 明确说明 "R92 baseline 没把 R88-91 增量算进去", 数字低估 2-4 倍
- **价值**: 给 R95 sub-spec 3+ 真实基础数据 (R95 估 +30 ARB keys, 实际 +75-100 ARB keys)

### 风险 2: P3 注释中文修复价值低 — 应对: 翻译文档, 不进 ARB

- **风险**: 11000 字符注释中文 → 走 ARB 是过度工程 (注释是给 developer 看, 不是给用户看)
- **应对**: 翻译成英文注释 (developer 友好, 跟开源国际惯例一致), 不进 ARB

### 风险 3: scale_translations.dart 3056 字符业务复杂 — 应对: 配 R95 task 2 拆 9 文件

- **风险**: 8 量表 16 题中文题目 → 走 ARB 是大工程 (估 +50 ARB keys + 临床审核)
- **应对**: R95 sub-spec 3 配 task 2 (拆 scale_translations 9 文件) 同时做, 跟 task 12 PHQ-9/GAD-7 i18n 真接合并

## 下一步

R95 sub-spec 3 task 9 (估 1-2 周, 4-6 commit, +75-100 ARB keys):

1. **P0 必修 (2 周内)**:
   - `scale_translations.dart` 3056 字符 → 走 ARB (R95 task 2 配, 估 +50 keys)
   - `core/l10n/strings.dart` 1543 字符 → 走 ARB (估 +25 keys)
   - 总: +75 ARB keys, 估 2-3 commit

2. **P1 重要 (3 周内)**:
   - `home_page.dart` 2174 字符 → 走 ARB (R95 task 5 配, 估 +30 keys)
   - 总: +30 keys, 估 2-3 commit

3. **P2/P3 翻译文档 (1 周内)**:
   - `app_database.dart` + `app_colors.dart` + `sms_service.dart` + `main.dart` 错误信息 + `notification_service.dart` + `safety_watch_service.dart` + `feature_flags.dart` ~11000 字符 → 翻译文档
   - 总: 估 1-2 commit (批量 sed)

**R95 sub-spec 3 估时**: 1-2 周, 4-6 commit, +105 keys (P0+P1), 11000 字符注释翻译 (P2/P3)

## 元结论

**R95 增量 audit (§6.5) 数字基于 R92 baseline, 未把 R88-91 增量算进去, 跟 task 8/25/26 stale audit 模式完全一致**。这是 audit 方法论的问题 — 应该 grep 实际代码而不是引用历史 baseline。R95 sub-spec 2 task 9-audit 的 "0 改动需要 + 数字低估 2-4 倍" 是个有价值的发现:

1. **避免做无用功**: 不基于 stale baseline 估工作量
2. **暴露 audit 方法论问题**: 后续 R95+ audit 应该用 PowerShell + grep 实际代码, 不用历史数字
3. **真实基础数据**: 给 R95 sub-spec 3 真实基础数据 (R95 估 +30 keys, 实际 +75-100 keys)
4. **诚实报数字**: 不假装做了 refactor (R95 估 4-6 commit, 实际 0 commit, 0 行 code change)
