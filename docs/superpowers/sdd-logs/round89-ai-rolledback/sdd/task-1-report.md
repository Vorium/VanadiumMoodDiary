# Task 1 Report — AiService + abstract + 5 prompts + mock test

## Status: DONE

## What I implemented

按 spec 实现 5 个 AI 能力 CBT 辅助的核心骨架。**全在 `core/data/services/ai/` 下,零 presentation 依赖,符合 4 层架构。**

### Files created
- `lib/core/data/services/ai/ai_service.dart` — `AiService.generateAll({score, tags, cbtLevel})` 并行 5 prompt + `Future.wait(eagerError: false)` + `_safeCall` 双层 try-catch 保护
- `lib/core/data/services/ai/ai_provider.dart` — abstract `AiProvider.call(system, user)` (Task 2 DeepSeekProvider 复用此接口)
- `lib/core/data/services/ai/ai_response.dart` — `AiResponse` 5 字段 nullable DTO + `hasAny` getter
- `lib/core/data/services/ai/prompts/_loader.dart` — 5 prompt 硬编码常量 (source of truth)
- `lib/core/data/services/ai/prompts/alternative_thought.md` — 人读备份
- `lib/core/data/services/ai/prompts/emotion_recognition.md` — 人读备份
- `lib/core/data/services/ai/prompts/cognitive_distortion.md` — 人读备份 (含 11 种 Beck 认知扭曲完整列表)
- `lib/core/data/services/ai/prompts/core_belief.md` — 人读备份
- `lib/core/data/services/ai/prompts/action_suggestion.md` — 人读备份
- `test/core/data/services/ai/ai_service_round89_test.dart` — 3 mock test

### Files modified
- `docs/CHANGELOG.md` — 加 R89 entry (sub-spec 5 Task 1)

## What I tested

### TDD Evidence

**RED** (Step 2 — 验证测试失败):
```bash
$ flutter test test/core/data/services/ai/ai_service_round89_test.dart
test/core/data/services/ai/ai_service_round89_test.dart:10:8: Error: Error when reading 'lib/core/data/services/ai/ai_service.dart': 系统找不到指定的文件。
test/core/data/services/ai/ai_service_round89_test.dart:11:8: Error: Error when reading 'lib/core/data/services/ai/ai_response.dart': 系统找不到指定的文件。
test/core/data/services/ai/ai_service_round89_test.dart:12:8: Error: Error when reading 'lib/core/data/services/ai/ai_provider.dart': 系统找不到指定的文件。
...
```
失败原因 (符合预期): `AiProvider` / `AiService` / `AiResponse` 3 个符号未定义,因为本 task 是首次实现 — 跟 spec 的 Step 2 期望一致。

**GREEN** (Step 6 — 实现后跑测试):
```bash
$ flutter test test/core/data/services/ai/ai_service_round89_test.dart
00:00 +0: loading D:/Batch/chroniccare/.worktrees/feat-cbt-ai/test/core/data/services/ai/ai_service_round89_test.dart
00:00 +0: 5 prompt 并行调用, 5 字段全有
00:00 +1: 1 prompt 失败, 其他 4 个继续
00:00 +2: user prompt 脱敏 — 不含 note / automaticThought
00:00 +3: All tests passed!
```
3/3 pass,output pristine,无 stray warning。

### Test 覆盖 (3 个)

1. **`5 prompt 并行调用, 5 字段全有`** — `_MockProvider` 返固定 JSON,验 `callCount == 5` + 5 字段全 `isNotNull`
2. **`1 prompt 失败, 其他 4 个继续`** — `_CountingProvider(alternatingException: true)` 第 1 次抛,其他正常,验 `callCount == 5` + `alternativeThought == null` + 其他 4 字段 `isNotNull`
3. **`user prompt 脱敏 — 不含 note / automaticThought`** — 验 user prompt 含 {情绪分数, 失眠, CBT 档位}, 不含 `note` / `automaticThought` / `situation` 子串

### 全测 (Step 7)

```
$ flutter test --no-pub
01:17 +1490: All tests passed!
```
**1490 pass (1487 baseline + 3 new)**, 0 fail ✓ — 跟 spec 预期一致。

### Analyze

```
$ flutter analyze
9 issues found.
```
0 error,**0 warning** (我加的 unused import 在 import 修复后消除)。
剩 9 个都是 R84 pre-existing info-level deprecated `groupValue` (R84 `cbt_section_round84_test.dart`),跟本 task 无关,info-level 允许。

### 17 守门员 (16 py + 1 dart)

| # | Script | Result |
|---|---|---|
| 1 | check_arb_keys | ✓ |
| 2 | check_changelog | ✓ (28→29 段) |
| 3 | check_cross_feature | ✓ |
| 4 | check_datetime_race | ✓ |
| 5 | check_datetime_race2 | ✓ |
| 6 | check_drift_namespace | ✓ |
| 7 | check_fullwidth_punctuation | ✓ (warn-only) |
| 8 | check_no_hardcoded_utc | ✓ |
| 9 | check_no_pua | ✓ |
| 10 | check_widget_dispose | ✓ |
| 11 | check_orphan_arb_keys | ✓ |
| 12 | check_legal_consent | ✓ |
| 13 | check_sms_release_ready | ✓ |
| 14 | check_strings_hardcoded | ✓ |
| 15 | check_zh_hant_consistency | ✓ |
| 16 | check_16kb_alignment | ✓ |
| 17 | check_all.dart (架构) | ✓ (4 层架构纯度 + 一致性 100%) |

## Files changed
```
docs/CHANGELOG.md                                          | +42
lib/core/data/services/ai/ai_provider.dart                 | new
lib/core/data/services/ai/ai_response.dart                 | new
lib/core/data/services/ai/ai_service.dart                  | new
lib/core/data/services/ai/prompts/_loader.dart             | new
lib/core/data/services/ai/prompts/alternative_thought.md  | new
lib/core/data/services/ai/prompts/emotion_recognition.md   | new
lib/core/data/services/ai/prompts/cognitive_distortion.md  | new
lib/core/data/services/ai/prompts/core_belief.md           | new
lib/core/data/services/ai/prompts/action_suggestion.md     | new
test/core/data/services/ai/ai_service_round89_test.dart    | new
11 files, +344
```

## Self-review findings

### Completeness
- ✓ 5 个 prompt (替代思维/情绪识别/认知扭曲/核心信念/行动建议) 全部覆盖
- ✓ 5 字段全 nullable (符合"1 失败不阻塞其他"设计)
- ✓ 脱敏 user prompt 只含 {score, tags, cbtLevel} — 跟 spec §已知坑 #5 一致
- ✓ `Future.wait(eagerError: false)` + `_safeCall` 双层保护 (spec §设计 提到)
- ✓ `AiResponse.hasAny` getter 顺便实现 (spec 要求)
- ✓ 5 个 .md 人读备份 + 1 个 _loader source of truth (跟 spec §已知坑 #2 一致)

### Quality
- 文件头注释标明 `v0.30 round 89 (sub-spec 5)` + 关键设计决策 (跟现有 service 风格一致)
- import 按字母序, `package:` 路径 (跟 AGENTS.md 一致)
- `eagerError: false` 加行内注释 (1 个失败不阻塞其他)
- `_safeCall` 用 `catch (_)` 显式吞所有异常 (防止 1 个 LLM 异常击垮整个 wizard)

### Discipline (YAGNI)
- ❌ 没有做 JSON 解析 (Task 2+4 层)
- ❌ 没有做 HTTP (Task 2)
- ❌ 没有做 settings/同意 (Task 3)
- ❌ 没有做 wizard 集成 (Task 4)
- ❌ 没有 i18n (Task 5)
- ❌ 没有做 OpenAI/Claude provider (v0.31+)
- ✓ `AiResponse` 5 字段就 spec 写的 5 个,不加 extra (e.g. confidence, reasoning)

### Testing
- ✓ TDD 严格 red→green (先写测试看 fail, 再写实现)
- ✓ 测试真验证行为 (不只 mock behavior):
  - test #1 验 `callCount == 5` (真并行 5 次)
  - test #2 验第 1 次抛 → `alternativeThought == null` (真 fail-safe)
  - test #3 验 user prompt 内容 (真脱敏)
- ✓ 测试用 `implements AiProvider` 不是 `extends` (跟 `snooze_manager_round18_test.dart` 风格一致)
- ✓ 测试 output pristine (无 stray warning)

### Issue 修正 (在 self-review 期间)
- 第一版测试 import 了 `ai_response.dart` 但未引用 → `flutter analyze` 报 warning → 删 import → 0 warning。

## Concerns
无。Spec 全部 8 个 step 走完,所有守门员绿,3 test 覆盖 spec 要求 3 个核心不变量 (5 字段 / 1 失败 4 继续 / 脱敏)。

## 跟其他 task 的契约确认
- **Task 2 (DeepSeekProvider)**: 可直接 `implements AiProvider`,单方法 `Future<String> call(system, user)` ✓
- **Task 3 (AiSettings)**: 跟本 task 无关,只需 Riverpod 注入 `AiProvider` ✓
- **Task 4 (CbtWizard)**: 调 `aiService.generateAll(score, tags, cbtLevel)` 拿 `AiResponse` 填 5 栏 ✓
- **Task 5 (i18n)**: 加 ~16 ARB key (cbtAI* 前缀),本 task 0 i18n 依赖 ✓
