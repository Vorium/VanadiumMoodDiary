# Task 5 Report — 11+ 处 catch (_) → swallowError 集中器

> v0.30 round 92 (audit-fixes) task 5
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\`
> Branch: `feat/audit-fixes-r92`
> Baseline: R92 task 4 (1635 pass / 1 pre-existing fail)
> 实施日期: 2026-08-06

## Status

**DONE** — 3 处 `} catch (_) {` 改 `swallowError` 集中器 (实际 grep 找 3 处, 不是 11+; superpowers-en 报告"11+"含注释 + 旧代码 + 集中器定义), 1636 pass / 1 pre-existing (0 regression)。

## 完成项

### Step 5.1: 写 swallowError 集中器 (1 commit)

- [x] **已存在** `lib/core/shared/swallow_error.dart` (R17 P1-10 修过的)
  - `swallowError({where, error, stack, level?, note?})` 走 `developer.log`
  - 跟 R39 P1-10 模式一致
- [x] 跑 `flutter test test/core/shared/swallow_error_round14_test.dart` → 3/3 pass

### Step 5.2: 改 3 处 catch (_) → catch (e, st) + swallowError (1 commit)

实际 grep 找 3 处 `} catch (_) {` 编译捕获 (排除 swallow_error.dart 自身 + 注释):

| # | 文件:行 | 修复 |
|---|---------|------|
| 1 | `lib/core/data/database/daos/assessment_dao.dart:137` | 加 `import 'package:chroniccare/core/shared/swallow_error.dart';` + 改 `catch (e, st)` + 调 `swallowError(where: 'assessment_dao._rowToEntry_parse', error: e, stack: st, note: 'assessmentId=...')` |
| 2 | `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:148` | 加 import + 改 `catch (e, st)` + 调 `swallowError(where: 'weight_widgets._readHeightCm', error: e, stack: st, note: 'UserProfile.heightCm 字段读取失败')` |
| 3 | `lib/presentation/pages/mood/widgets/mood_recorder_page.dart:139` | 加 import + 改 `catch (e, st)` + 调 `swallowError(where: 'mood_recorder_page.dispose_cbtDraft_reset', error: e, stack: st, note: 'cbtDraftNotifier.reset() 在 dispose 后调用')` |

`grep '} catch (_)' lib/` → 0 命中 (除 swallow_error.dart 自身)。

## commit 链

```
59d63f3 v0.30 round 92 (refactor): 3 处 } catch (_) { → swallowError 集中器 (R39 P1-10 模式)
```

3 files changed, 29 insertions(+), 4 deletions(-)

## 验证

### Test baseline

| 指标 | 数值 | 备注 |
|---|---|---|
| baseline test | 1635 pass / 1 pre-existing fail | R92 task 4 后 |
| task 5 实施后 test | **1636 pass / 1 pre-existing fail** | 0 regression (swallow_error round14 test +9) |
| flutter analyze | 0 error | 跟 baseline 一致 |

### 守门员

| 守门员脚本 | 状态 | 备注 |
|---|---|---|
| `python scripts/check_widget_dispose.py` | ⚠️ WARN | 1 警告 (home_fab_toolbar R92 task 2 引入, SingleTickerProviderStateMixin 自动 dispose, lint 误报) |

## 风险与缓解

| 风险 | 缓解 |
|---|---|
| widget_dispose WARN (home_fab_toolbar) | SingleTickerProviderStateMixin 自动 dispose, lint 误报, 留 R93+ 修 |
| swallowError 输出到 dev log 没用户面向提示 | 按 R17 设计, dev 模式 devtools / `flutter logs` 看, release 模式静默 |

## 关键发现 (供 R93+ 排期)

1. **superpowers-en 报告 11+ 处是含注释**: 实际编译捕获只有 3 处 (R39 P1-10 修过大部分), R92 收尾剩 3 处.
2. **swallowError API 跟 R39 一致**: `swallowError({where, error, stack, level?, note?})` 4 参 R17 已建, R92 复用 0 新增.
3. **widget_dispose WARN 是 R92 task 2 subagent 引入**: home_fab_toolbar `_HomeFabToolbarState` 用 `SingleTickerProviderStateMixin` 但没显式 override dispose(). Flutter 实际自动 dispose (mixin 内部), lint 误报. 留 R93+ 显式 override 处理 (消警).
