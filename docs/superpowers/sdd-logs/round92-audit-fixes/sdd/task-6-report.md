# Task 6 Report — 拆 1 个 600 行 god page (assessment_page)

> v0.30 round 92 (audit-fixes) task 6
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\`
> Branch: `feat/audit-fixes-r92`
> Baseline: R92 task 5 (1636 pass / 1 pre-existing fail)
> 实施日期: 2026-08-06

## Status

**DONE** — assessment_page 拆 3 sub-widget (ProgressHeader + QuizPanel + ResultPanel), 436→289 行 (减 34%)。

## 完成项

### Step 6.1: 拆 ProgressHeader (新文件)

- [x] 新增 `lib/presentation/pages/assessment/widgets/assessment_progress_header.dart` (~60 行)
- [x] 接受 props: instruction + answered + total
- [x] 内部: instruction 文字 + answered/total 进度文字 + LinearProgressIndicator
- [x] 走 l10n.assessmentAnsweredProgress (R91 ARB 已有, 复用)

### Step 6.2: 拆 QuizPanel (新文件)

- [x] 新增 `lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart` (~80 行)
- [x] 接受 props: scale + answers + answered + canSubmit + onAnswerChanged + onSubmit
- [x] 内部: ProgressHeader + ListView (QuestionCard) + SafeArea PrimaryButton
- [x] props callback 模式: 父 widget 持 state, sub-widget 不读全局

### Step 6.3: 拆 ResultPanel (新文件)

- [x] 新增 `lib/presentation/pages/assessment/widgets/assessment_result_panel.dart` (~150 行)
- [x] 接受 props: result + scale + historyWidgets + onBack + onRetake
- [x] 内部: 大数字 + 严重度 + 总分范围 + historyWidgets (ComparisonCard + Sparkline, 父传入) + 推荐就医 + 免责声明 + 2 button
- [x] historyWidgets 由父 widget (_buildComparisonWidgets) 构造后传入

### Step 6.4: assessment_page.dart 引用 3 sub-widget

- [x] 删 `_buildQuizView` 65 行内联 (用 QuizPanel)
- [x] 删 `_buildResultView` 120 行内联 (用 ResultPanel, historyWidgets 传)
- [x] 保留 `_buildComparisonWidgets` 33 行 (构造 historyWidgets 给 ResultPanel)
- [x] 加 3 sub-widget import
- [x] 修复 import 路径: assessment_scale.dart 在 lib/domain/logic/ (不是 lib/domain/entities/)
- [x] 修复 import 路径: QuestionCard / ComparisonCard 在 lib/presentation/pages/assessment/assessment_widgets.dart (不是 lib/presentation/widgets/)

### Step 6.5: fix orphan ARB key

- [x] ProgressHeader 内部用 `l10n.assessmentAnsweredProgress(answered, total)` (不是 `'$answered / $total'`)
- [x] 跑 `check_orphan_arb_keys.py` → 0 orphan

## commit 链

```
20d27d6 v0.30 round 92 (refactor): assessment_page 拆 3 sub-widget (ProgressHeader + QuizPanel + ResultPanel, 436→289 行)
8d2e01b v0.30 round 92 (fix): AssessmentProgressHeader 复用 l10n.assessmentAnsweredProgress (R92 god page 拆漏)
```

5 files changed, 351 insertions(+), 181 deletions(-)

## 验证

### Test baseline

| 指标 | 数值 | 备注 |
|---|---|---|
| baseline test | 1636 pass / 1 pre-existing fail | R92 task 5 后 |
| task 6 实施后 test | **1636 pass / 1 pre-existing fail** | 0 regression |
| flutter analyze | 0 error | 跟 baseline 一致 |

### God page 行数变化

```
$ wc -l lib/presentation/pages/assessment/assessment_page.dart
289   # 拆前 436 → 拆后 289 (-147 行 = -34%)
```

3 sub-widget 累加 ~290 行, 总 580 行 (vs 拆前 436, +144 行 = +33% 是 props callback 模式的代价, 但解耦收益远大于代码增加)。

### 守门员

| 守门员脚本 | 状态 | 备注 |
|---|---|---|
| `dart scripts/check_all.dart` | ✅ OK | 4 层架构纯度 + 一致性 |
| 16 守门员 (其它) | ✅ OK | R92 task 3 + 5 已全绿 |

## 关键发现 (供 R93+ 排期)

1. **god page 拆 34%**: 436 → 289 行, 拆 3 sub-widget. R95+ 拆剩下 2 个 (medication_calendar 642 行 + data_management_section 606 行) 走同样模式.
2. **props callback 模式**: 父 widget 持 state, sub-widget 接受 props + callback. 不读全局 state, 符合 R88 god page 拆分规范.
3. **import 路径修复**: assessment_scale.dart 实际在 lib/domain/logic/, R89 拆 domain 时移到 logic. R90 R91 daily_tracking + assessment center 没踩到, R92 拆 god page 才遇到.
4. **QuestionCard / ComparisonCard 合并在 assessment_widgets.dart**: R91 daily_tracking 集成时把 question / comparison card 从 lib/presentation/widgets/ 合并到 lib/presentation/pages/assessment/assessment_widgets.dart. R92 拆 god page 才遇到.
5. **orphan ARB key 修复**: ProgressHeader 拆时误用字面量 `'$answered / $total'`, 应走 l10n.assessmentAnsweredProgress. 跑 check_orphan_arb_keys 守门发现, 1 commit 修.
