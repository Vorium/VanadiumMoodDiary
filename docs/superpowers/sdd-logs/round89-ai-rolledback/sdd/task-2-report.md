# Task 2 Report — DeepSeekProvider HTTP impl

**Status:** DONE
**Commit:** `757c70a` — `v0.30 round 89 (data): DeepSeekProvider HTTP impl (https://api.deepseek.com/v1/chat/completions) + 4 mock test`
**Worktree:** `D:\Batch\chroniccare\.worktrees\feat-cbt-ai` (branch `feat/cbt-ai`)

---

## What I Implemented

`lib/core/data/services/ai/deepseek_provider.dart` — 唯一 AiProvider (国内 DeepSeek API),66 行:

- `class DeepSeekProvider implements AiProvider`
- Constructor: `apiKey` (required String), `modelName` (required String), `client` (optional `http.Client`, defaults to `http.Client()`)
- Private constant `_endpoint = 'https://api.deepseek.com/v1/chat/completions'`
- `Future<String> call(systemPrompt, userPrompt)`:
  1. POST with headers `Content-Type: application/json` + `Authorization: Bearer $apiKey`
  2. Body: `{model, messages[{role:system,content:systemPrompt},{role:user,content:userPrompt}], temperature: 0.7, max_tokens: 500}`
  3. `statusCode != 200` → `developer.log` + `throw Exception('DeepSeek API ${statusCode}: ${body}')`
  4. `choices` null/empty → `throw Exception('DeepSeek API: empty choices')`
  5. `content` null → `throw Exception('DeepSeek API: empty content')` (defensive)
  6. Return `content`

依赖调整: `pubspec.yaml` 加 `http: ^1.6.0` (transitive → direct, 已经在 lockfile 1.6.0,直接 add 即可)。

---

## Files Changed

| File | Action | Lines |
|---|---|---|
| `lib/core/data/services/ai/deepseek_provider.dart` | create | 66 |
| `test/core/data/services/ai/deepseek_provider_round89_test.dart` | create | 94 |
| `pubspec.yaml` | modify (1 line: +http) | +1 |

Total: 3 files, +161 lines, commit `757c70a`.

---

## TDD Evidence (REQUIRED)

### RED — failing test before implementation

Command:
```bash
flutter test test/core/data/services/ai/deepseek_provider_round89_test.dart
```

Relevant output:
```
test/core/data/services/ai/deepseek_provider_round89_test.dart:14:8: Error: Error when reading 'lib/core/data/services/ai/deepseek_provider.dart': 系统找不到指定的文件。
  import 'package:chroniccare/core/data/services/ai/deepseek_provider.dart';
test/core/data/services/ai/deepseek_provider_round89_test.dart:36:22: Error: Method not found: 'DeepSeekProvider'.
    final provider = DeepSeekProvider(
test/core/data/services/ai/deepseek_provider_round89_test.dart:49:22: Error: Method not found: 'DeepSeekProvider'.
    final provider = DeepSeekProvider(
test/core/data/services/ai/deepseek_provider_round89_test.dart:64:22: Error: Method not found: 'DeepSeekProvider'.
    final provider = DeepSeekProvider(
test/core/data/services/ai/deepseek_provider_round89_test.dart:82:22: Error: Method not found: 'DeepSeekProvider'.
    final provider = DeepSeekProvider(
00:00 +0 -1: Some tests failed.
```

Why expected: `DeepSeekProvider` class does not exist yet, so the import fails to resolve and the 4 test bodies reference an unknown symbol. Compiler errors, not test runtime errors — exactly what TDD looks like at the RED step when the file under test doesn't exist.

### GREEN — passing tests after implementation

Command (after creating `lib/core/data/services/ai/deepseek_provider.dart`):
```bash
flutter test test/core/data/services/ai/deepseek_provider_round89_test.dart
```

Relevant output:
```
00:00 +0: loading D:/Batch/chroniccare/.worktrees/feat-cbt-ai/test/core/data/services/ai/deepseek_provider_round89_test.dart
00:00 +0: DeepSeek 200: 解析 choices[0].message.content
00:00 +1: DeepSeek 401: 抛 Exception, 包含 statusCode + body
00:00 +2: DeepSeek 500: 抛 Exception
00:00 +3: DeepSeek 200 但 choices 空: 抛 Exception (防御)
00:00 +4: All tests passed!
```

All 4 tests pass. Output pristine (no stray warnings, no skipped tests).

### Full suite (Task 1 + Task 2 + everything else)

Command:
```bash
flutter test
```

Relevant output:
```
01:10 +1494: All tests passed!
```

1494 / 1494 pass (1490 baseline + 4 new from this task). Zero failures.

---

## Verification Summary

| Check | Result |
|---|---|
| `flutter test test/core/data/services/ai/` (Task 1 + 2) | ✅ 7/7 pass |
| `flutter test test/core/data/services/ai/deepseek_provider_round89_test.dart` (Task 2 only) | ✅ 4/4 pass |
| `flutter test` (full suite) | ✅ 1494/1494 pass (was 1490) |
| `flutter analyze` | ✅ 0 issues in new files (9 pre-existing info in cbt_section.dart / cbt_section_round84_test.dart, not from this task) |
| `dart scripts/check_all.dart` (4-layer purity + consistency) | ✅ both sub-checks pass |
| `python scripts/check_cross_feature.py` | ✅ 80 files checked, 0 violations |

---

## Self-Review Findings

**Completeness:** ✅ All 4 spec test cases implemented and passing (200, 401, 500, empty-choices). Implementation follows brief exactly: same constructor signature, same endpoint, same headers, same body fields, same `temperature: 0.7` / `max_tokens: 500` defaults, same `developer.log` on failure, same 3-tier defensive parsing (statusCode → choices → content).

**Quality:** ✅ Defensive parsing on 3 levels (statusCode, choices, content), each throws a distinct `Exception` message for log triage. `apiKey` not included in `developer.log` (only statusCode + body). Naming matches domain (DeepSeekProvider, _endpoint, _client). No magic strings beyond brief specs.

**Discipline (YAGNI):** ✅ Built only what was asked. No retry, no streaming, no JSON parsing in AiService, no setup UI, no wizard integration — all marked "不在 scope" by the brief.

**Testing:** ✅ Tests use `http.testing.MockClient` (stdlib `package:http/testing.dart`), no real LLM call. Each test asserts a distinct behavior:
- Test 1 (200): asserts URL, Authorization header, Content-Type header, body model, message roles
- Test 2 (401): asserts throws Exception
- Test 3 (500): asserts throws Exception
- Test 4 (empty choices): asserts throws Exception (defensive path)

Output pristine. No skipped tests, no `setUp`/`tearDown` noise.

---

## Issues / Concerns

### Concern 1: Test fix deviates from brief (test-side only, not impl)

The brief specified `http.Response(jsonEncode({...}), 200)` with no Content-Type. When the test ran with Chinese chars (`'示例 AI 回复'`), it failed with:

```
Invalid argument (string): Contains invalid characters.: "{\"choices\":[{\"message\":{\"content\":\"示例 AI 回复\"}}]}"
  dart:convert  Latin1Codec.encode
  package:http/src/response.dart 39:49  new Response
```

Root cause: `http.Response` constructor (v1.6.0) has **no `encoding` parameter** — encoding is derived from the `Content-Type` header. Without a Content-Type, it defaults to Latin1, which can't represent CJK. Fix: add `headers: {'content-type': 'application/json; charset=utf-8'}` to the two Response calls in the test (lines 34, 81). This is a more idiomatic approach anyway (the real DeepSeek API also returns `application/json; charset=utf-8`).

The **implementation file is unchanged from the brief** — this is purely a test-side correctness fix. The 4 test cases still verify the same behaviors. If reviewers prefer a different mock-encoding strategy, it's a 2-line revert.

### Concern 2: Lint cleanups in test file

Three lints from the project's own `flutter_lints` config had to be fixed in the new test file:
1. `require_trailing_commas` on lines 30/31 (jsonEncode payload) — added trailing commas
2. `inference_failure_on_collection_literal` on the empty-choices Response — explicitly typed `jsonEncode(<String, dynamic>{'choices': <dynamic>[]})` instead of bare map literal

Both are repo-wide lint rules. The pre-existing 9 info issues in `cbt_section.dart` and `cbt_section_round84_test.dart` (deprecated `groupValue`/`onChanged` from R84) are not touched by this task.

### Concern 3: pubspec.yaml placement

`flutter pub add http` placed `http: ^1.6.0` at the bottom of dependencies (after `speech_to_text`), not in any logical "utilities" group. Acceptable — pub add always appends, and the file already has utilities and a STT block at the bottom. Not worth manually reordering for this task.

### Concern 4: No `http.Client.close()` lifecycle

`DeepSeekProvider` creates `http.Client()` by default in the constructor. The class doesn't expose a `dispose()` method. For a singleton with the lifetime of the app (created in Task 4 via Riverpod), this is fine — the OS reclaims the socket at process exit. But if someone instantiates many short-lived providers (e.g., per-test, or per-request), they'd leak sockets. Out of scope for this task (brief says no lifecycle), but worth a follow-up if Task 4 (CbtWizard) creates new providers per-call. **Flagging for Task 4 awareness, not blocking.**

---

## What's Next (Hand-off)

- **Task 3** (AiSettings + 同意 dialog) — depends on `DeepSeekProvider` being constructible. Now unblocked.
- **Task 4** (CbtWizard) — `DeepSeekProvider` is injected into `AiService` via constructor; no provider changes needed in the data layer. Watch the lifecycle concern (above) when wiring the Riverpod provider.
- **Real API verification** — once Tasks 3/4 are done, manual smoke test with a real DeepSeek API key is the last gate (R55 dependency — Aliyun SMS ready check pattern suggests adding a `validateForRelease`-style check at startup before showing the AI section in settings, mirroring `SmsProviderNotConfiguredError`).
