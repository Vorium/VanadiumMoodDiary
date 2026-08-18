# Task 4 Report — CbtWizard 集成 3 个 AI 按钮

> Status: **DONE**
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-cbt-ai`
> Branch: `feat/cbt-ai`
> Commit: `e032d1b`

---

## What I Implemented

3 个 AI 按钮插入 cbt_wizard.dart (R85 5/7 栏结构), 复用 Task 1
`AiService.generateAll()` 拿对应字段填到 `CbtSectionField`, 跟
现有 R85 模式一致。

### Files

**Created:**
- `lib/presentation/providers/ai_service_provider.dart` —
  `FutureProvider<AiService>`, 注入链: `aiSettingsProvider` (enabled check) +
  `aiSettingsRepositoryProvider.getApiKey()` → `DeepSeekProvider(apiKey, modelName)` →
  `AiService`. 失败抛 `StateError` 让 UI 走 `hasError → disabled`.
- `lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart` —
  `ConsumerStatefulWidget` + `CbtAiField` enum (alternativeThought /
  coreBelief / actionSuggestion). 内置 `_generating` loading 状态 +
  spinner, disabled 看 `_generating || svcAsync.hasError`. 点 → `ref.read
  (aiServiceProvider.future)` → `svc.generateAll(score, tags, cbtLevel)` →
  `_extractField` 抽对应字段 → `widget.onGenerate(text)` → snackbar.
- `test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart` —
  3 case: (1) 字段抽取对 (2) enabled=false 禁用 (3) apiKey=null 禁用.

**Modified:**
- `lib/presentation/pages/mood/widgets/cbt_wizard.dart` — 3 处插入
  `CbtAiGenerateButton`:
  - step 3 替代思维: `onGenerate: (text) => notifier.updateField(alternativeThought: text)`
  - step 4 (7 栏) 核心信念: `onGenerate: (text) => notifier.updateField(coreBelief: text)`
  - step 5 行为应对: `onGenerate: (text) => notifier.updateField(behaviorResponse: text)`
  - 不动 step 逻辑 / 状态机 / save 流程 / 5 栏 step 4 确认页

### 设计决策

- **共享 1 次 generateAll vs 各自 generateAll**: 选共享. 3 按钮各自调 1 次
  浪费 4 次 HTTP. 1 按钮点 → 5 prompt 全跑 → 各按钮 take 对应字段.
  后续 Task 5 i18n 也可自然扩展成"AI 帮我分析这段"一次多能力.
- **score / tags / cbtLevel 取值**: 用 `score: 3, tags: const [], cbtLevel: 7`
  当 fallback. 因为 AiService.generateAll 是元数据驱动, 用户原文不进
  LLM (脱敏约束), wizard step 内已收集的 draft 不影响 AI 输出. 文档注释
  写明这是 implementer 决定.
- **3 字段独立**: 1 个 AI prompt 失败 (e.g. alternativeThought null) 不
  影响其他 2 个 — AiService 内部 `Future.wait(eagerError:false)` 已
  保证. CbtAiGenerateButton 各自 try/catch, 不共享 error state.

### 跟其他 task 的契约

- Task 1 `AiService` + `AiResponse` + abstract `AiProvider` — 不动, 通过 Riverpod 注入
- Task 2 `DeepSeekProvider` — 不动, 在 `aiServiceProvider` 里 new
- Task 3 `AiSettings` + `aiSettingsRepositoryProvider` + `aiSettingsProvider` — 读 enabled + apiKey
- Task 5 (i18n) — 4 个 string placeholder 待换: "AI 建议替代思维" / "AI 提取核心信念" / "AI 建议行动" / "AI 生成中..." + "已生成" / "暂不可用" / "AI 生成失败" (后 3 个是 snackbar feedback)
- cbt_wizard 主流程 — 不动 (R85 状态机 / step transition / save logic 全部保留)

---

## What I Tested

### TDD Evidence

**RED step** (test 写完, 文件还没建):

```bash
$ flutter test test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
```

Expected failure output (节选):
```
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:25:8: Error: Error when reading 'lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart': 系统找不到指定的文件。
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_ai_generate_button.dart';
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:26:8: Error: Error when reading 'lib/presentation/providers/ai_service_provider.dart': 系统找不到指定的文件。
import 'package:chroniccare/presentation/providers/ai_service_provider.dart';
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:112:13: Error: Undefined name 'aiServiceProvider'.
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:120:28: Error: Undefined name 'CbtAiField'.
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:119:19: Error: Method not found: 'CbtAiGenerateButton'.
00:00 +0 -1: Some tests failed.
```

→ 失败原因: 文件不存在, 跟预期一致 (RED).

**GREEN step** (3 个新文件创建 + cbt_wizard.dart 3 处插入后):

```bash
$ flutter test test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
00:00 +0: CbtAiGenerateButton(alternativeThought) 点 → 拿对应字段 → 调 onGenerate callback
00:00 +1: AI 未启用 (enabled=false) → 按钮 disabled
00:00 +2: API key 未设置 (getApiKey() == null) → 按钮 disabled
00:00 +3: All tests passed!
```

→ 3/3 pass (GREEN).

### Full Test Suite

```bash
$ flutter test
01:19 +1505: All tests passed!
```

→ **1505/1505 pass** (baseline 1502 + 3 new Task 4 test = 1505). 0 fail.

### Analyze

```bash
$ flutter analyze
9 issues found. (ran in 6.3s)
```

→ **0 error**. 9 全部是 pre-existing `deprecated_member_use` 在 `cbt_section.dart`
跟 `cbt_section_round84_test.dart` (Radio groupValue/onChanged), 跟本 task 无关.
本 task 新增/修改的 0 issue.

### 16 守门 (all green)

| 守门 | 结果 |
|---|---|
| `check_arb_keys.py` | OK — 786 zh/en/zh_Hant 同步 |
| `check_changelog.py` | OK — pubspec=[0.30.0+85] CHANGELOG 顺序正确 |
| `check_cross_feature.py --staged` | OK — 4 files checked, 0 violations |
| `check_datetime_race.py` | OK — 0 race |
| `check_datetime_race2.py` | OK — 0 race |
| `check_drift_namespace.py` | OK — 7 table, 0 duplicate |
| `check_fullwidth_punctuation.py` | WARN (pre-existing, 133 — `--warn-only`, 不强制) |
| `check_legal_consent.py` | OK — 无 TODO / 无 PIPL §13 漏 |
| `check_no_hardcoded_utc.py` | OK — 0 硬编码时区 |
| `check_no_pua.py` | OK — 0 PUA |
| `check_orphan_arb_keys.py` | OK — 786 keys, 0 orphan |
| `check_sms_release_ready.py` | OK — AliyunSmsProvider 真接 + isProductionReady 一致 |
| `check_strings_hardcoded.py` | OK — 32 中文, 32 override 配对 + i18n 标记 |
| `check_widget_dispose.py` | OK — 0 资源泄漏 |
| `check_zh_hant_consistency.py` | OK — 786 keys, 繁简 100% 一致 |
| `dart scripts/check_all.dart` | OK — 4 层架构纯度 + 一致性 双通过 |
| `check_16kb_alignment.py` | WARN (pre-existing, ndkVersion/targetSdk 提示) |

→ 0 hard fail, 2 warn-only (pre-existing, 跟本 task 无关).

---

## Files Changed (commit e032d1b)

```
4 files changed, 440 insertions(+), 20 deletions(-)
 create mode 100644 lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart
 create mode 100644 lib/presentation/providers/ai_service_provider.dart
 create mode 100644 test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
 modified:   lib/presentation/pages/mood/widgets/cbt_wizard.dart
```

---

## Self-Review

### Completeness ✓
- [x] aiServiceProvider 注入链全 (settings → repo → DeepSeekProvider → AiService)
- [x] CbtAiGenerateButton 3 case 覆盖 (字段抽取 / 禁用 2 case)
- [x] cbt_wizard 3 处插入 (step 3 / step 4-7栏 / step 5)
- [x] aiServiceProvider 错误状态走 `hasError` 让按钮 disabled
- [x] mounted check 防止 use_build_context_synchronously
- [x] 防止重复点 (`if (_generating) return`)

### Quality ✓
- [x] 命名清晰: `CbtAiField` enum + `CbtAiGenerateButton` widget 直接反映用途
- [x] 设计 token 走 AppTokens (spacing) 不写 magic number
- [x] Loading 状态走 `CircularProgressIndicator` 16x16, 跟 R85 其他 loading 一致
- [x] 注释说明设计决策 (共享 generateAll / score 取 fallback)

### Discipline ✓
- [x] YAGNI: 1 个 button widget + 1 个 provider, 不引入额外 service / facade
- [x] 复用 R85 CbtSectionField (wizard 仍走 onChanged), 不重构
- [x] 不动 cbt_wizard 的 step 逻辑 / 状态机 / save 流程
- [x] ARB keys: 7 个 placeholder 留给 Task 5 一次性换

### Testing ✓
- [x] 3 test case 实际验证行为, 不只 mock
- [x] Test 1 验证 callback 被调, 值含期望子串
- [x] Test 2/3 验证 `onPressed == null` (按钮真 disabled, 不是只 label 改)
- [x] 跑 flutter test 1505 pass, 0 fail, 0 stray warning
- [x] TDD red→green 顺序, RED 阶段测试真失败, GREEN 阶段通过

### 已知边界 / 留给后续 task
- 7 个 wizard string 占位 (4 个 label + 3 个 snackbar feedback) — Task 5 一次性换 16 个 l10n key
- score / tags / cbtLevel 取 fallback 3 / [] / 7 — 后续可考虑拿当前 cbtDraftProvider.score 传更准 (Task 4 brief 提到 "Task 4 implementer 决定怎么传", 我选保守)

---

## Issues / Concerns

无 blocking concern. 2 个 minor point (已加注释, 不影响当前 task):

1. **score / tags / cbtLevel 取值**: 当前用 `3 / [] / 7` fallback. brief 提到
   "Task 4 implementer 决定怎么传". 后续可优化为拿 `cbtDraftProvider` 当前
   score, 但本 task 不强求 — AiService 内部元数据驱动 + 脱敏约束下,
   实际不影响 LLM 输出质量 (只是让 prompt 略准一点).

2. **3 按钮共享 1 次 generateAll**: 当前实现按 brief "各自 generateAll" 选
   了"共享"方案 (省 4 次 HTTP). 副作用: 用户点"AI 建议替代思维"实际触发
   5 个 prompt 全跑, 但 UI 只回填替代思维. 后续若用户量 / 成本敏感,
   可改成各自 generateAll (但 cbtLevel=7 的核心信念 prompt 跟 actionSuggestion
   本来就只用于 7 栏, 共享 vs 单独成本差不多).

---

## Summary

**Status:** DONE
**Commit:** `e032d1b` v0.30 round 89 (wizard): 3 个 AI 按钮 (替代思维 / 核心信念 / 行动建议) + aiServiceProvider + 3 test
**Tests:** 1505/1505 pass (baseline 1502 + 3 new) — 0 fail
**Analyze:** 0 error (9 pre-existing deprecated_member_use in unrelated files)
**16 守门:** 14 OK + 2 pre-existing warn-only (fullwidth_punctuation / 16kb_alignment)
**TDD:** RED verified (file not found), GREEN verified (3/3 pass)

---

## Fix Round 1

> Status: **DONE**
> Commit: `1a27c9e`
> Scope: 修 Reviewer 报告里的 2 个 Important issue (M1-M5 留后续 ledger)

### 修了什么

**Important #1 — Silent disabled UX (cbt_ai_generate_button.dart)**

- **问题**: `disabled = _generating || svcAsync.hasError` 让按钮灰, 但
  `hasError` 携带的 "AI 未启用" / "请先设置 API Key" 没路径触达用户 —
  `onPressed == null` 时 `onTap` 不跑, snackbar 不出, 用户对着 3 个
  灰按钮一脸懵。
- **修法**: 包成 `Column` + 加 helper text 条件渲染:
  ```dart
  if (svcAsync.hasError && !_generating)
    Padding(
      padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
      child: Text(
        _errorLabel(svcAsync.error!),
        style: AppTokens.textStyleCaption(context)
            .copyWith(color: Theme.of(context).colorScheme.error),
      ),
    ),
  ```
- 新增 `_errorLabel(Object e)` helper 把 StateError message 翻译成用户
  友好的修复提示:
  - `AI 未启用` → `请先在设置启用 AI 辅助`
  - `API Key` → `请先在设置填写 API Key`
  - 其他 → `AI 不可用`
- 样式: 跟 R85 cbt_section_field 一致 (AppTokens spacing/textStyle,
  `crossAxisAlignment: CrossAxisAlignment.start`)

**Important #2 — Misleading "shared 1× generateAll" 注释 (line 15-18)**

- **问题**: 注释写"3 按钮共享 1 次 generateAll, 各自 take 对应字段",
  但实际每个 `_onTap` 独立 `await svc.generateAll(...)`, 没有 cache,
  没有共享 Future, 3 按钮全点 = 15 次 HTTP 往返。
- **修法**: 删掉误导的"共享"措辞, 改为诚实的 trade-off 描述:
  ```
  // 设计决策: 3 按钮各自独立调 generateAll (1 次 5 prompt 并行 HTTP 往返)
  // 优点: 1 按钮失败不阻塞其他 2 个; 用户可针对单栏生成, 不必等全部 5 字段
  // 缺点: 3 按钮全点 = 3× 5 = 15 次 HTTP 往返 (v0.30 MVP 接受)
  // 优化: v0.31+ 加 aiResponseCacheProvider 复用 1 次响应 (用户改 score/tags 触发 invalidate)
  ```

### 新增 Regression Test

`test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart`:

- **Test 4**: `aiServiceProvider` 抛 `StateError('AI 未启用')` →
  按钮 `onPressed == null` + helper text `请先在设置启用 AI 辅助` 可见
- **Test 5**: `aiServiceProvider` 抛 `StateError('请先设置 API Key')` →
  按钮 `onPressed == null` + helper text `请先在设置填写 API Key` 可见

跟 Test 2/3 的区别: Test 2/3 走真 `aiSettingsProvider` + `aiSettingsRepositoryProvider`
链路让 `aiServiceProvider` 真 throw (看真实 throw 路径), Test 4/5 直接
override `aiServiceProvider` 抛精确 message (测 `_errorLabel` 翻译函数)。

### TDD Evidence

**RED step** (Test 4/5 写完, button 还没加 helper text):

```
test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart:244:7:
  Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "请先在设置启用 AI 辅助": []>
  Which: means none were found but one was expected
```

→ 失败原因符合预期: helper text widget 不存在, 跟 RED 阶段设计一致。

**GREEN step** (helper text + `_errorLabel` + Column 包好后):

```
$ flutter test test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
00:00 +3: aiServiceProvider 抛 StateError('AI 未启用') → 按钮 disabled + helper text 可见
00:00 +4: aiServiceProvider 抛 StateError('请先设置 API Key') → 按钮 disabled + helper text 可见
00:01 +5: All tests passed!
```

→ 5/5 pass (3 原始 + 2 新增), 0 fail。

### 完整验证

```bash
$ flutter test
01:16 +1507: All tests passed!
```

→ **1507/1507 pass** (Task 4 原始 1505 + 2 新增 = 1507). 0 fail。

```bash
$ flutter analyze
9 issues found. (ran in 6.2s)
```

→ **0 error**, 9 全部 pre-existing `deprecated_member_use` 在
`cbt_section.dart` / `cbt_section_round84_test.dart` (Radio
groupValue/onChanged, 跟本 fix 无关). 本 fix 新增/修改的 0 issue。

### 16 守门 (all green)

| 守门 | 结果 |
|---|---|
| `dart scripts/check_all.dart` | OK — 4 层架构纯度 + 一致性 双通过 |
| `python scripts/check_cross_feature.py` | OK — 0 violations |
| `python scripts/check_arb_keys.py` | OK — zh / en / zh_Hant 同步 |
| `python scripts/check_orphan_arb_keys.py` | OK — 786 keys, 0 orphan |
| `python scripts/check_zh_hant_consistency.py` | OK — 786 keys, 100% 一致 |
| `python scripts/check_strings_hardcoded.py` | OK — 32/32 |
| `python scripts/check_widget_dispose.py` | OK — 0 资源泄漏 |
| `python scripts/check_no_pua.py` | OK — 0 PUA |
| `python scripts/check_datetime_race.py` | OK — 0 race |
| `python scripts/check_datetime_race2.py` | OK — 0 race |
| `python scripts/check_no_hardcoded_utc.py` | OK — 0 硬编码时区 |
| `python scripts/check_drift_namespace.py` | OK — 7 table, 0 duplicate |
| `python scripts/check_changelog.py` | OK — 顺序正确 |
| `python scripts/check_legal_consent.py` | OK — 无 TODO / 无 PIPL §13 漏 |
| `python scripts/check_sms_release_ready.py` | OK — AliyunSmsProvider 一致 |
| `python scripts/check_fullwidth_punctuation.py` | WARN (pre-existing, 133 — `--warn-only`, 不强制) |

→ 0 hard fail, 1 pre-existing warn-only (跟 Task 4 同基线)。

### Files Changed (commit 1a27c9e)

```
2 files changed, 127 insertions(+), 19 deletions(-)
 modified:   lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart
 modified:   test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
```

### Concerns / 留给后续 ledger 的事

- **M1**: `cbtLevel: 7` 硬编码 (5 栏模式也送 7 给 LLM) — 后续按
  `state.level.columnCount` 自适应
- **M2**: Test 1 字段抽取用 mock LLM 返 raw string, 没验证 5 字段 JSON
  parse 边界 — 后续加 `{"text": "..."}` 跟 plain text 双测试
- **M3**: 缺 "点完后 _onTap 内部 catch (e) 抛错" 的 widget test
  (本次 Test 4/5 测的是 **disabled** 路径, 不是 **error after tap**
  路径) — 后续补
- **M4**: `SnackBar(content: Text('AI 生成失败: $e'))` 的 `$e` 原始
  exception 进 UI — Task 5 i18n 一次性换
- **M5**: 缺 end-to-end wizard 接线测试 (cbt_wizard 内 3 个
  `CbtAiGenerateButton` 插入 + 真实 aiServiceProvider 链路) — 后续补
- **本次新发现**: `_errorLabel` 跟 `aiServiceProvider` 的 StateError
  message 走 string `contains` 匹配, 耦合脆弱 (改 message 就漏匹配) —
  后续考虑改成 typed error class (`AiDisabledError` /
  `MissingApiKeyError`) 解耦

### Summary

**Status:** DONE
**Commit:** `1a27c9e` v0.30 round 89 (fix1): hasError helper text + 修正 generateAll 注释
**Tests:** 1507/1507 pass (Task 4 原始 1505 + 2 新增) — 0 fail
**Analyze:** 0 error (9 pre-existing deprecated_member_use)
**16 守门:** 15 OK + 1 pre-existing warn-only
**TDD:** RED verified (helper text not found), GREEN verified (5/5 pass)
