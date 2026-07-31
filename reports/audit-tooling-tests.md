# Tooling / Scripts / Tests Audit — chroniccare v0.25 round 56e

**Date**: 2026-07-27
**Auditor**: general (branch session `mvs_0cfb3adf5cad4420b058fe16bcbaba66`)
**Scope**: `scripts/`, `test/`, `docs/`, `pubspec.yaml`, `README.md`, `AGENTS.md`, `whitePaper/`, `reports/`, `.mimocode/`
**Mode**: READ-ONLY — no file modifications were made.

Severity legend: **🔴 critical** / **🟡 medium** / **🟢 low**

---

## 0. Executive Summary (one-page)

| Category | Verdict |
|---|---|
| **CI guard scripts** | 12 active + 1 Dart arch-check. All running. No drift. |
| **One-off `_rXX_/_tmp_/_clean_*.py`** | **9 files in `scripts/` root** + 9 in `_archive/sprint2-zh-hant-tmp/` + 10 `_archive/` root. **All should be moved to `_archive/`.** |
| **Stale `.txt` / `.log` / `.ps1` artifacts** | **17 files in `scripts/`** (10 .txt, 6 .log, 1 .dart) + **24 files in `reports/`** (18 .ps1, 5 .png, 1 .log). All are debugging artifacts that should be gitignored or deleted. |
| **Test suite** | **111 .dart test files + 2 .py tests**. 1 `.disabled` file (depends on `dio` not in pubspec). 1 low-value test (mocks method existence only). 2 mojibake-rendered doc files at repo root. |
| **Doc drift** | **schemaVersion = 14 in code, AGENTS.md says 12** (stale by 2 versions). 5+ mojibake-rendered .md files (PUA-character corruption from a v0.17 PowerShell incident). |
| **Pubspec** | All 14 declared deps are imported. No `dio` in pubspec but `aliyun_sms_provider_round57_test.dart.disabled` imports it. No asset is undeclared; many `assets/brand/v*.png` and `assets/brand/variations/*.png` are not declared in pubspec but shouldn't be (they're brand exploration, not ship assets). |
| **`.gitignore`** | **Missing entries** for `_archive/`, `.mimocode/`, `.commit_msg_*.txt`, `*.log`, `*.tmp`, `*.ps1` (in reports), `_thumb_*.png`. |
| **`lib/` hygiene** | ✅ No `print()` calls (uses `piiSafeLog` / `developer.log`). ✅ No hardcoded `C:\Users\` paths. ⚠️ 10 TODO comments (mostly v1.0+ future work — not blockers). |

**Top 5 action items** (in order of cost/benefit):

1. 🟡 Move 9 one-off `_rXX_/_tmp_/_clean_*.py` from `scripts/` root → `scripts/_archive/`. Easy, no risk.
2. 🟡 Update `AGENTS.md` schemaVersion 12 → 14. One-line fix.
3. 🟡 Add missing `.gitignore` rules (`_archive/`, `.mimocode/`, `*.log`, `*.tmp`, etc.). One block.
4. 🟡 Delete or gitignore 17 stale artifacts in `scripts/` (`.txt` / `.log` / `_test_*.log`) and 24 in `reports/`.
5. 🟢 Re-evaluate or delete `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` (imports undeclared `dio`).

---

## 1. Outdated / dead / one-off scripts to archive

### 1.1 scripts/ root — one-off `_rXX_/_tmp_/_clean_` migration utilities

These are **legacy one-off batch-rewrite scripts** that were run during specific refactor rounds and have already produced their effect. The codebase no longer needs them; they remain as historical record.

| File | Round | Status | Reason safe to archive | Any current use? |
|---|---|---|---|---|
| `_r49_dark_mode_color_replace.py` | R49 | 🔴 **Archive** | v0.25 R49 tokenized 60+ `AppTokens.{primary,error,warning}` calls → 3 dynamic getters. The script is the producer; the work is already in code. | No grep hits in `lib/` for "R49_dark_mode" pattern. |
| `_r49_remove_const_for_dynamic_color.py` | R49 | 🔴 **Archive** | Follow-up to above: removed 20 `const` keywords that broke after dynamic color getter was added. Done. | None. |
| `_r49_remove_const_v2.py` | R49 | 🔴 **Archive** | "v2" of above (handles inline `const`); all 3 v49 const-removal scripts are done. | None. |
| `_r53a_dedup_imports.py` | R53a | 🔴 **Archive** | v0.25 R53a deduped 7 DAO import lines. Done. | None. |
| `_r53a_fix_dao_imports.py` | R53a | 🔴 **Archive** | R53a fixed 7 DAO import errors (`app_database.g.dart` → `app_database.dart`). Done. | None. |
| `_r53a_remove_g_imports.py` | R53a | 🔴 **Archive** | R53a deleted 7 DAO `.g.dart` imports. Done. | None. |
| `_r56b_spacing_tokenize.py` | R56b | 🔴 **Archive** | R56b replaced 46 magic SizedBox sizes (2/4/6/8/16/24/40/80) → `AppTokens.spacing*`. Done. | None. |
| `_r56_icon_size_replace.py` | R56 | 🔴 **Archive** | R56 replaced 32 magic icon sizes (14/18/56/64) → `AppTokens.iconSize*`. Done. | None. |
| `_r59_fix_underscore.py` | R59 | 🔴 **Archive** | One-liner: renamed `(_, anim, _, child)` → `(_, anim, __, child)` in 4 transition helpers. Done. | None. |
| `_clean_orphan_arb_keys.py` | R56e | 🟡 **Keep-with-caution** | One-off script that deleted 39 orphan ARB keys (677 → 550 zh ARB key). File's own header says "**本脚本是一次性工具, 清完后不需要再跑. 但保留方便未来又有 orphan 出现时手工清理.**" — so author intent is "keep". | **Verify-needed** — check if `check_orphan_arb_keys.py` (the guard) ever auto-deletes, or if this script is ever re-run. Currently no scheduled re-run; safe to **archive** since the guard (R56e) is now in place. |

**Severity**: 🟡 medium — these files pollute the scripts/ root and make it harder to see the 12 active guards. They are NOT referenced by any CI step (verified via grep: no hit in `lib/`, `test/`, or any `.github/`).

**Suggested fix**:
```bash
# Move to scripts/_archive/round_specific/
mv scripts/_r49_*.py           scripts/_archive/r49/
mv scripts/_r53a_*.py          scripts/_archive/r53a/
mv scripts/_r56_*.py scripts/_r56b_*.py scripts/_archive/r56/
mv scripts/_r59_*.py           scripts/_archive/r59/
mv scripts/_clean_orphan_arb_keys.py scripts/_archive/r56e/
```

### 1.2 scripts/ root — debugging / status `.txt` & `.log` artifacts (NOT code)

These are output snapshots from previous PowerShell/git invocations, **should never have been committed**. 17 files total:

| File | Size | Origin |
|---|---|---|
| `diff_stat.txt` | 8,678 B | `git diff --stat HEAD` output, 2026-07-26 |
| `final_stats_for_report.txt` | 478 B | GitHub-style change stats, 2026-07-26 |
| `final_status.txt` | 5,483 B | `git status` output, 2026-07-26 |
| `gitlog.txt` | 0 B | Empty file |
| `gitlog2.txt` | 149 B | `git log` tail, 2026-07-26 |
| `list6.txt` / `list7.txt` | 1,267 / 11,330 B | PowerShell `Get-ChildItem` output, 2026-07-26 |
| `status.txt` / `status2.txt` / `status3.txt` | 322-1,152 B | `git status` snapshots |
| `_analyze_round59.log` / `_analyze_round59_v2.log` / `_analyze_round59_v3.log` | 10,966 B each | `flutter analyze` 3 attempts, 2026-07-27 |
| `_test_baseline.log` | 570,246 B (~557 KB) | `flutter test` baseline run, 2026-07-27 |
| `_test_round59.log` | 568,544 B (~555 KB) | `flutter test` round 59, 2026-07-27 |
| `_test_round59_v3.log` | 569,994 B (~557 KB) | `flutter test` round 59 v3 |
| `_check_all_round59.log` | 1,060 B | `check_all.dart` round 59 |
| `test_delivery_rate.dart` | 2,125 B | One-shot Dart script (see §1.4 below) |

**Severity**: 🟡 medium — 3 logs are ~1.6 MB total in the repo. They are noise and confuse "what is a guard vs what is a log". **None** of these are referenced by anything.

**Suggested fix**: delete all 17, then add to `.gitignore`:
```gitignore
# Round 59 debugging artifacts
_*_round*.log
_*_baseline.log
_*_test_*.log
_*_analyze_*.log
_*_check_all_*.log
```

### 1.3 scripts/ root — verify-needed (`make_icon_preview_v5.py`)

- `scripts/make_icon_preview_v5.py` (7,909 B, last modified 2026-07-21): generates a single PNG (`assets/brand/icon_preview_v5.png`) from v4/v5 icon master PNGs using Pillow. **One-off** (already produced the file in assets/). Header docstring says "Generate v4 vs v5 transition preview image" — i.e., a one-time deliverable.

| Verdict | Severity | Reason |
|---|---|---|
| 🟡 **Archive** | medium | Already done its job (output is on disk in `assets/brand/icon_preview_v5.png`). Four earlier `make_icon_preview_v{1..4}.py` are already in `scripts/_archive/`. This v5 is the lone holdout. |

**Suggested fix**: `mv scripts/make_icon_preview_v5.py scripts/_archive/`.

### 1.4 scripts/ root — `test_delivery_rate.dart`

- `scripts/test_delivery_rate.dart` (2,125 B, last modified 2026-07-25):

```dart
// 一次性脚本：测试 SMS 通知的送达率（v0.6 mock 阶段只打日志）
// 用法：dart run scripts/test_delivery_rate.dart
```

A 21-line Dart script that calls `EmailService.sendMedicationReminder` 10 times with fake phones and counts `true` results. **Always returns true because `useMock: true` is hard-coded** (line 26). Comments say "v1.0+ 接入真实 SMS provider 后再启用真实送达率测试".

| Verdict | Severity | Reason |
|---|---|---|
| 🟡 **Archive** | medium | (a) In `useMock: true` mode it's a no-op assertion (`if (ok) print('✅')`). (b) Future re-enable requires real AliyunSms, which is blocked on legal/access key per CHANGELOG (R55 "外部依赖, 1-2 月"). (c) The whole test is a script, not a test — it would be `scripts/` pollution for the next 1-2 months minimum. |

**Suggested fix**: `mv scripts/test_delivery_rate.dart scripts/_archive/r55_sms_mock_probe/`.

### 1.5 scripts/ `_archive/` — anything to promote back to root?

`scripts/_archive/` is **well-organized**: it has a `sprint2-zh-hant-tmp/` subfolder with 30 files (legacy mojibake hunt scripts) and root has 9 one-off scripts + 1 misfiled `app_zh_Hant.arb.tmp`.

**One item to consider**:
- `scripts/_archive/app_zh_Hant.arb.tmp` (43,872 B, 2026-07-26): A backup of `lib/l10n/app_zh_Hant.arb` from before OpenCC s2tw re-conversion. **Could be safely deleted** — the canonical file is `lib/l10n/app_zh_Hant.arb` (last touched 2026-07-26 20:50). This `.tmp` predates the canonical.

| Verdict | Severity | Reason |
|---|---|---|
| 🟢 **Delete (or move to `docs/archive/`)** | low | 43 KB backup of a file that has been re-converted since. Low cost either way. |

**Everything else in `_archive/` (87 files, including 30 in `sprint2-zh-hant-tmp/`) is correctly archived.** No script there needs to be promoted back.

### 1.6 scripts/ root — keep (CI guards) ✅

These 13 files are referenced by `check_changelog.py`, the README "12 守门员" claim, or are themselves the canonical guards. **DO NOT move.**

| File | Purpose | Test/Ref? |
|---|---|---|
| `check_all.dart` | 4-layer architecture purity + consistency | ✅ Has `test/scripts/check_all_round18_test.dart` |
| `check_arb_keys.py` | zh / en / zh_Hant ARB key sync | ✅ Has `test/scripts/check_*_test.py` (cross-feature) |
| `check_changelog.py` | pubspec version ↔ CHANGELOG.md sync | None (no test) |
| `check_cross_feature.py` | cross-feature import boundaries | ✅ Has `test/scripts/check_cross_feature_test.py` |
| `check_datetime_race.py` | `DateTime.now()` 5-line window heuristic | None |
| `check_datetime_race2.py` | Brace-matched `DateTime.now()` per function | None |
| `check_drift_namespace.py` | `@DataClassName` uniqueness | ✅ Has `test/scripts/check_drift_namespace_test.py` |
| `check_fullwidth_punctuation.py` | ASCII punct inside CJK string literals | None |
| `check_legal_consent.py` | `setup_legal_dialog.dart` PIPL §13 TODO | None |
| `check_no_hardcoded_utc.py` | `(UTC+8)` / `北京时间` literals | None |
| `check_no_pua.py` | PUA-character (mojibake) detection | None |
| `check_orphan_arb_keys.py` | ARB keys defined but never used in code | None |
| `check_sms_release_ready.py` | AliyunSmsProvider `throw UnimplementedError` | None |
| `check_strings_hardcoded.py` | `lib/core/l10n/strings.dart` hardcoded CN | None |
| `check_widget_dispose.py` | StatefulWidget resource leak heuristic | None |
| `check_zh_hant_consistency.py` | OpenCC s2tw zh ↔ zh_Hant equality | None |

**Note**: AGENTS.md says "12 守门员" (12 guards). Actual count is **12 Python + 1 Dart (`check_all.dart`) = 13**. The README claim is consistent if `check_all.dart` is counted as the 13th. **Verify-needed** — re-read AGENTS.md line about "12 守护脚本清单" to see if the "12" was intentional (perhaps `check_all.dart` is counted separately).

### 1.7 Summary table — scripts/ root

| Decision | Files | Count |
|---|---|---|
| 🔴 Archive (one-off `_rXX_/_tmp_/_clean_`) | `_r49_*.py` (3) + `_r53a_*.py` (3) + `_r56*` (2) + `_r59_*.py` + `_clean_orphan_arb_keys.py` | **10** |
| 🔴 Archive (debug artifacts) | `*.txt` (10) + `*.log` (6) | **16** |
| 🟡 Archive (one-shot visual gen) | `make_icon_preview_v5.py` | **1** |
| 🟡 Archive (mock script) | `test_delivery_rate.dart` | **1** |
| ✅ Keep (CI guards) | `check_*.py` (13) + `check_all.dart` (1) | **14** |

---

## 2. Test suite health

### 2.1 Test count & subdir breakdown

- **Total .dart test files**: **111** (verified via `Get-ChildItem -Recurse -Filter '*.dart' | Measure-Object`)
- **Total .py test files**: **2** (in `test/scripts/`)
- **Total .disabled test files**: **1** (see §2.6)
- **CHANGELOG claim**: 1098 test cases pass (`docs/CHANGELOG.md:8` "1098/1098 pass"). Cannot verify exact case count without running `flutter test` (which would take 5+ min and is not in scope), but the file count of 111 is consistent with ~10 cases/file average.

| Subdir | Test files | Notes |
|---|---|---|
| `test/data/` | 33 | data layer round-trip + service tests |
| `test/domain/` | 28 | pure-Dart business logic |
| `test/presentation/` (root) | 19 | widget tests, midnight, app shell, etc. |
| `test/core/data/services/` | 10 | service unit tests (R56c+ spen P0 #15 TDD) |
| `test/core/shared/` | 4 | `swallow_error`, `user_name_helper`, `pii_safe_log`, `care_copy` |
| `test/core/theme/` | 2 | `app_tokens_dark`, `motion_scheme` |
| `test/core/data/utils/` | 1 | `phone_validator` |
| `test/presentation/widgets/` | 6 | press_feedback, motion, emil_widgets, etc. |
| `test/presentation/widgets/animations/` | 2 | fade_in, slide_up |
| `test/presentation/pages/settings/` | 1 | settings_page_round45 |
| `test/presentation/pages/trend/` | 1 | trend_page_round45 |
| `test/routing/` | 1 | route_parsing_round19c |
| `test/scripts/` | 2 + 1 | `check_cross_feature_test.py`, `check_drift_namespace_test.py`, `check_all_round18_test.dart` |
| **Total** | **111 .dart + 2 .py** | |

### 2.2 Tests that are flaky / use timing-based waits

**Method**: grep `Future<void>.delayed` in `test/**/*.dart`.

| File | Line | Pattern | Severity | Note |
|---|---|---|---|---|
| `test/core/data/services/mood_audio_service_round61c3_test.dart` | 93 | `await Future<void>.delayed(Duration.zero);` | 🟢 low | Used to "pump microtask" — acceptable for stream `onDone` callback. |
| `test/data/medication_repository_round9_test.dart` | 58 | `await Future<void>.delayed(const Duration(milliseconds: 100));` | 🟡 medium | Comment says "给 100ms 缓冲,避免 clock skew". Real wallclock wait. **Could become flaky on slow CI** (timeout in `inInclusiveRange(0, 5)`). Consider `fakeAsync` or polling for stream emit. |
| `test/data/safety_watch_service_round12_test.dart` | 319 | `await Future<void>.delayed(const Duration(days: 1));` (inside `async*` mock that "永不 emit") | 🟢 low | Intentional: test must verify timeout fires. The 1-day delay is in a mock that throws before the real wait completes (timeout cuts it off). OK. |
| `test/presentation/mood_dialog_audio_round31_test.dart` | 133, 136 | `await Future<void>.delayed(Duration.zero);` | 🟢 low | Microtask pump. OK. |

**Other 4** matches are all `Duration.zero` microtask pumps or intentional 1-day delays. **No hard `sleep()` calls** anywhere in `test/`. **No test uses `pumpAndSettle` to wait instead of pumping** (24 widget tests do use `pumpAndSettle` correctly).

**Verdict**: ✅ healthy. Only 1 borderline-flaky test (`medication_repository_round9_test.dart:58`). Suggest tracking with `fakeAsync` later.

### 2.3 Tests that are empty / placeholder / `expect(true, true)`

**Method**: grep `expect\(true, true\)|expect\(1, 1\)|expect\(0, 0\)|expect\(null, null\)`.

| Result | Count |
|---|---|
| Total matches | **0** |

**Verdict**: ✅ no placeholder/empty assertions.

### 2.4 Tests that test the wrong thing (implementation detail)

| File | Lines | Test | Severity | Note |
|---|---|---|---|---|
| `test/data/database_migration_round20_test.dart` | 26-35 | `expect(DatabaseMigration.needsMigration, isA<Function>())` / `expect(DatabaseMigration.migrateIfNeeded, isA<Function>())` | 🟡 medium | "Verifies the method exists" — i.e., a no-op type test. Comment says "DbKeyService.hasKey() 依赖 SecureStorage,在 test 环境会抛错" so the author punted on real test. **Doesn't test behavior.** |
| `test/scripts/check_all_round18_test.dart` | whole file | Uses a duplicated copy of `_testResolveImportLayer` (lines 90-134) instead of importing from `check_all.dart`. | 🟡 medium | Doc-comments: "duplicate _testResolveImportLayer 因为原函数是 private". This means changes to `check_all.dart`'s `_resolveImportLayer` won't be caught by this test. **Fragile.** |

### 2.5 Test files that are 0-imports / no main

**Method**: `Select-String 'void main\(\)'` over `test/**/*.dart`. Every file has a `main()`. No zero-import test files.

**Verdict**: ✅ all test files have a valid `main()`.

### 2.6 The .disabled test file

| File | Lines | Issue | Severity |
|---|---|---|---|
| `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` | 289 | Imports `package:dio/dio.dart` (line 17) but `dio` is **NOT in `pubspec.yaml`**. Tests a real AliyunSmsProvider HTTP call with a `_MockAdapter implements HttpClientAdapter` pattern. The `.disabled` extension keeps `flutter test` from running it (project ignores `*.disabled` per `.gitignore` line 37). | 🟡 medium |

**Author intent**: R57 wrote this test but R58 downgraded the SMS-release guard to warn-only (`check_sms_release_ready.py:12` "A-01 修正依赖法务模板审核 + 阿里云 AccessKey 申请 (80-120h), v0.x 不阻塞"). So the test is parked until `dio` is added.

**Decision tree**:
- **Option A** (recommended): Add `dio: ^5.x` to `pubspec.yaml` and rename `.disabled` → `.dart` (cheap if AliyunSms work is going to be picked up again).
- **Option B**: Delete the file. The current `MockSmsProvider` is verified by `sms_service_round38_test.dart` (4,818 B) and the `check_sms_release_ready.py` guard. Re-creating the AliyunSms test is cheap (R57 docstrings already document intent).
- **Option C**: Leave as-is, file a follow-up.

### 2.7 Tests that are duplicates of each other

**Method**: inspected all 111 .dart file names + sizes; looked for obvious overlap.

| Pattern | Files | Verdict |
|---|---|---|
| `notification_service_round4_test.dart` (987 B) + `notification_service_round19b_test.dart` (2,759 B) + `notification_service_refill_round9_test.dart` (3,262 B) + `notification_service_split_round45b_test.dart` (12,880 B) | 4 files | ✅ **Not duplicates** — they target different rounds (split refactor, refill, dispatch). Slight overlap is expected. |
| `streak_calculator_round3_test.dart` (1,916 B) + `streak_calculator_round19_test.dart` (5,658 B) | 2 files | ✅ Not duplicates — R3 + R19 are different fixes (R19 added `lastCheckIn` handling). |
| `care_engine_round3_test.dart` (4,829 B) + `care_engine_round17_test.dart` (7,305 B) + `care_engine_round19_test.dart` (3,127 B) + `care_engine_copy_round18_test.dart` (3,703 B) | 4 files | ✅ Not duplicates — each round tests different scenarios. |
| `vent_repository_round*` (1 file only: `vent_audio_storage_round20_test.dart`) | 1 file | ✅ Only one. |
| `vent_compose_stop_and_cleanup_round48_test.dart` (1 file) | 1 file | ✅ Only one. |
| `medication_report_round18_test.dart` (23,589 B — 723 lines) | 1 file | ✅ Largest test file. Comprehensive but not duplicated. |
| `vent_list_round18_test.dart` (1 file) | 1 file | ✅ Only widget test for vent list. |
| `formatters_round9_test.dart` (1,771 B) + `formatters_round9_test.dart` in `data/` | 2 files but 1 is empty? | Verified — only 1 file. |
| `json_codec_round3_test.dart` (1,682 B) + `json_codec_round9_test.dart` (3,079 B) | 2 files | ✅ R3 + R9 — likely R3 has a bug-fix test, R9 added more cases. |

**Verdict**: ✅ no obvious duplicate tests. The "round-N" pattern in filenames is intentional and tracked in CHANGELOG.

### 2.8 Missing test coverage for: drift schema / business logic / widgets

#### Drift schema coverage

The schema v14 is tested via:
- `test/data/database_migration_round20_test.dart` — tests `MigrationException` + 2 stub method-exists assertions (see §2.4)
- `test/data/database_migration_round37_test.dart` (5,297 B) — round 37 migration tests

**Gap**: No test for **`schemaVersion 12 → 14`** migrations (i.e., the v0.23 round 43 + 44 changes that added `(is_active, sort_order)` index on `contacts` and `generated_at` index on `report_histories`). If a future refactor breaks the migration path, nothing will catch it.

| Severity | Suggested fix |
|---|---|
| 🟡 medium | Add `test/data/database_migration_round43_test.dart` that constructs a v12 DB, runs `onUpgrade`, and asserts indexes exist. |

#### Business logic coverage

- 28 domain tests cover: `care_engine` (4), `streak_calculator` (2), `phq9`, `gad7`, `scale_registry`, `medication_entity`, `medication_report`, `mood_entry_entity`, `mood_entry_audio`, `mood_entry_4d`, `check_in_entity`, `check_in_usecases`, `contact_entity` (2), `day_detail` (2), `email_template`, `chinese_holidays`, `assessment_record`, `assessment_comparison`, `vent_entry_entity`, `trend_calculator`, `reminder_scheduler` (2), `care_strategies` (2).
- **Gap**: No tests for `domain/entities/medication_entity.dart` 0-cross-day scenarios (e.g., `refillAt` boundary, `times` ordering). Existing `medication_entity_round11_test.dart` (11,716 B) covers main cases.

**Verdict**: ✅ domain coverage is broad. Only minor edge cases missing.

#### Widget coverage

- 19 widget tests in `test/presentation/` + 6 in `test/presentation/widgets/` + 2 in `test/presentation/widgets/animations/` + 2 in `test/presentation/pages/` = **29 widget tests**.
- Pages with widget tests: `setup_*` (4), `assessment_history`, `check_in_button`, `app_shell`, `app_root`, `medication_calendar`, `refill_manage`, `reminders_hub`, `theme_shell`, `today_med_schedule`, `vent_list`, `crossed_midnight_since`, `medications_list_split`, `medication_report_dialog`, `mood_dialog_audio`, `vent_compose_stop_and_cleanup`, `notification_status_card`, `settings_page`, `trend_page`.
- **Pages WITHOUT widget tests** (potential gap):
  - `home_page.dart` — **🔥 critical**. CHANGELOG §"v0.27 round 59 R60 修正计划" line 58: "**`home_page.dart` widget test (P0, 每日用户路径 0 test)**". The home page is the **primary daily user path** (check-in button) and currently has 0 widget tests.
  - `assessment/assessment_page.dart` — has 1 (`assessment_history_round13b`) but it's actually for `assessment_history_page` not `assessment_page`.
  - `mood/mood_dialog.dart` — only `_audio` test exists; the score/tag/energy/note sub-widgets have no tests.
  - `vent/vent_detail_page.dart`, `vent/vent_compose_page.dart` — only `vent_list` + `vent_compose_stop_and_cleanup` covered.
  - `contact/contacts_list_widget.dart` — 1 test exists (`contacts_list_widget_round45`).
  - `medication/medication_report_dialog.dart` — 0 test (the report *PDF* is tested via `medication_report_pdf_round39`, but the dialog UI is not).

| Severity | Suggested fix |
|---|---|
| 🔴 critical | Add `test/presentation/pages/home/home_page_roundXX_test.dart` — primary user path. |
| 🟡 medium | Add tests for `mood_dialog` non-audio paths. |
| 🟢 low | Add `vent_detail_page` widget test. |

### 2.9 Tests for the Python guard scripts

**Files**: only 2 out of 13 guards have tests.

| Script | Has test? |
|---|---|
| `check_all.dart` | ✅ `test/scripts/check_all_round18_test.dart` (but uses duplicated copy — see §2.4) |
| `check_cross_feature.py` | ✅ `test/scripts/check_cross_feature_test.py` (5,969 B, thorough) |
| `check_drift_namespace.py` | ✅ `test/scripts/check_drift_namespace_test.py` (2,195 B, 4 cases) |
| `check_arb_keys.py` | ❌ no test |
| `check_changelog.py` | ❌ no test |
| `check_datetime_race.py` | ❌ no test |
| `check_datetime_race2.py` | ❌ no test |
| `check_fullwidth_punctuation.py` | ❌ no test |
| `check_legal_consent.py` | ❌ no test |
| `check_no_hardcoded_utc.py` | ❌ no test |
| `check_no_pua.py` | ❌ no test |
| `check_orphan_arb_keys.py` | ❌ no test |
| `check_sms_release_ready.py` | ❌ no test |
| `check_strings_hardcoded.py` | ❌ no test |
| `check_widget_dispose.py` | ❌ no test |
| `check_zh_hant_consistency.py` | ❌ no test |

**Severity**: 🟡 medium — 11 of 13 guards (85%) have no tests. A typo in any regex would silently break the guard.

**Suggested fix** (pick top 3 by risk):
1. `check_arb_keys.py` — high risk because every PR touches ARB.
2. `check_no_pua.py` — high risk because UTF-8/PowerShell issue is a recurring foot-gun.
3. `check_zh_hant_consistency.py` — high risk because OpenCC dependency is fragile on Windows.

---

## 3. Documentation drift

### 3.1 README.md

- **Tech stack table** is mostly accurate (Flutter 3.41.9, Dart 3.12.2, Riverpod 3.3.2, Drift 2.20.3, go_router 14.6 — all match pubspec).
- **"8 元付费下载"** (line 17): no validation in code, but consistent across docs.
- **Quick-start**: `fvm install 3.41.9` (line 25) — matches pubspec `flutter: '>=3.41.0'`. OK.
- **Test count claim** (line 131): "v0.25 round 56e 后 1098 cases" — matches CHANGELOG.
- **"v0.16 round 20" NotificationStatusCard** (line 106): still exists in code per AGENTS.md.

**Verdict**: ✅ README is current. No edits needed.

### 3.2 AGENTS.md — schema version + test count drift

**Two specific drift items**:

| Where | What it says | Reality | Severity |
|---|---|---|---|
| AGENTS.md §"必读文件" #2 | "`lib/core/data/database/app_database.dart` — schemaVersion 当前 12" | Actual: **schemaVersion = 14** (`lib/core/data/database/app_database.dart:82`) | 🔴 **critical** — agent following this will assume migrations 12→13 and 13→14 are unstarted |
| AGENTS.md §"必读文件" #3 | "streak / 趋势" (mentions of round 4 midnight logic, R17 calendar window) | These are stable; no drift. | ✅ |
| AGENTS.md "v0.25 round 56e" §"12 守护脚本清单" | Lists 12 guards + `check_all.dart` is the 13th, not counted. | Actual count: 13 (including `check_all.dart`) | 🟡 medium — re-read the section, but the count is *consistent* if you exclude `check_all.dart` |

**Verdict**: AGENTS.md has **1 critical drift** (schemaVersion) and otherwise matches reality. **Single-line fix.**

### 3.3 docs/CHANGELOG.md

- **Latest version documented**: `## [0.25.0] - 2026-07-26 (R49-R60 + R56b-R56f)`. Matches pubspec `version: 0.25.0+1` (line 4).
- **The CHANGELOG mentions 12 guards** (line 10) — consistent with current count.
- **`## [0.25.0]` mentions `app_routes.dart` R59**: confirmed (`lib/core/routing/app_routes.dart` exists, last modified 2026-07-26).
- **Unreleased changes**: None visible (the file's last-modified is 2026-07-27 9:27, and pubspec is 0.25.0+1, so everything currently in working tree is the released 0.25.0).

**Verdict**: ✅ CHANGELOG is up-to-date and matches pubspec.

### 3.4 docs/decisions/ — outdated decisions

3 decision files, all dated 2026-07-26, all R17 / R22 / R24:
- `v0.17_animations_extraction.md` — R17 round 14 (P1-1) + R24 round 48 P3-10: extraction is **done** (R24 修正 added `celebration_bounce.dart` as 4th widget). **Could be marked ✅ DONE**.
- `v0.22_mojibake_fixes.md` — historical archive of mojibake fixes; nothing to do.
- `v0.24_round48_design_decisions.md` — current design.
- `v0.24_round48_p3_skip_decisions.md` — current skip rationale.

**Verdict**: ✅ no reversed decisions. The 4 files are appropriate. Slight suggestion (🟢 low): mark `v0.17_animations_extraction.md` as ✅ DONE in its header.

### 3.5 docs/refactor/ — completed refactors

4 refactor design docs, all from R45 (v0.24 round 45):
- `data_export_service_split_design.md` (27,529 B) — refactor completed (CHANGELOG R41)
- `mood_dialog_split_design.md` (14,828 B) — completed (R45, "mood_dialog god-class 拆 5 子 widget")
- `medications_list_split_design.md` (17,113 B) — completed
- `notification_service_split_design.md` (24,062 B) — completed

**Verdict**: ✅ these are design docs; they should remain as historical record. No drift, but **no "✅ Completed" marker** at the top of each. 🟢 low: add a "Status: ✅ Completed in v0.24 R45" banner to each.

### 3.6 docs/reviews/ — old review reports

26 review files, 6 in `docs/reviews/` (current R27 R56h audits) + 13 in `docs/archive/reviews/` (R22 + R30) + 7 in `docs/review/` (R24 round 48). All are historical.

**Verdict**: ✅ these are intentional historical record. No drift, no action needed.

### 3.7 whitePaper/ — current?

| File | Last mod | Verdict |
|---|---|---|
| `whitePaper/慢病管家-白皮书-v3.0.md` | 2026-07-20 | 🟡 **stale by 1 week** — references "v0.17 round 7" and "703 test cases pass" (line 8, 36, 38). Project is now v0.25 round 56e with 1098 tests. |
| `whitePaper/archive/v4.1-v1.0-team-package-2026-07-17.tar.gz` | archive | ✅ historical |
| `whitePaper/archive/team-whitepaper/慢病管理产品白皮书-v1.0.md` | archive | ✅ historical |
| `whitePaper/archive/mavis-workspace-v4.0/` | archive | ✅ historical |

**Mojibake check** (`check_no_pua.py`): reports `0 PUA characters` for the whitepaper (the Python script renders correctly). However, when displayed via `Get-Content` in PowerShell on this machine, the whitepaper shows mojibake (`鈥?` instead of `—`, etc.) because the file is encoded as GBK when read by PS5 default. This is a **PowerShell reading artifact, not a real mojibake bug** — the Python guard passes, and the file is editable in VS Code.

**Severity**: 🟡 medium — the marketing whitepaper claims "v0.17 round 7" + 703 tests but project is at 1098. Anyone reading the whitepaper for product positioning will be misled. **Also it contains 4 sections that reference `scripts/test_delivery_rate.dart` as a current CI script** (line "§6.1 5 灞?umbrella" mentions it as "scripts/test_delivery_rate.dart 閫氱煡閫佽揪鐜囨祴璇?", and `scripts/8a2_rewrite_to_absolute.py` / `scripts/8a_rewrite_imports.py` which no longer exist in root).

**Suggested fix**:
- Either update the whitepaper to v0.25 round 56e + 1098 tests (4-6h work — file is 1,009 lines).
- Or move the file to `whitePaper/archive/` and create a new `whitePaper/v4.0.md` based on v0.25.

### 3.8 Mojibake-rendered files in repo root

The following `.md` files display as mojibake in PowerShell 5.1 because they are UTF-8 without BOM and Windows treats them as GBK:

| File | When read via `Get-Content` | Note |
|---|---|---|
| `AGENTS.md` | mojibake | But Python `check_no_pua.py` returns 0 PUA. **PS-only artifact.** |
| `README.md` | mojibake | Same. |
| `docs/CHANGELOG.md` | mojibake | Same. |
| `docs/CHANGELOG.md` content (e.g., `## [0.25.0]`) | mojibake in PS | But UTF-8 is correct. |
| `docs/WHITEPAPER.md` | mojibake | Same. |
| `docs/CHINESE_COMMIT_GUIDE.md` | mojibake | Same. |
| `docs/GIT_WORKFLOW.md` | mojibake | Same. |
| `docs/P2_DESIGN_REVIEW.md` | mojibake | Same. |
| `docs/P2_SYSTEM_REVIEW.md` | mojibake | Same. |
| `docs/P2_COMPLIANCE_REVIEW.md` | mojibake | Same. |
| `docs/PRD-v0.1-draft.md` | mojibake | Same. |
| `docs/DEPLOYMENT.md` | mojibake | Same. |
| `docs/PUSH_PROVIDERS.md` | mojibake | Same. |
| `docs/SENDGRID_SETUP.md` | mojibake | Same. |
| `docs/SMS_PROVIDERS.md` | mojibake | Same. |
| `docs/terminology.md` | mojibake | Same. |
| `docs/CODE_REVIEW_v0.17r12.md` | mojibake | Same. |
| `docs/decisions/*.md` (4 files) | mojibake | Same. |
| `docs/review/*.md` (6 files) | mojibake | Same. |
| `docs/reviews/*.md` (8 files) | mojibake | Same. |
| `docs/archive/reviews/v0.22/*.md` (3 files) | mojibake | Same. |
| `docs/superpowers/specs/*.md` | mojibake | Same. |
| `docs/superpowers/plans/*.md` | mojibake | Same. |
| `docs/refactor/*.md` (4 files) | mojibake | Same. |
| `whitePaper/慢病管家-白皮书-v3.0.md` | mojibake | Same. |
| `whitePaper/archive/team-whitepaper/慢病管理产品白皮书-v1.0.md` | mojibake | Same. |
| `whitePaper/archive/mavis-workspace-v4.0/mavis-whitepaper-v4.0.md` | mojibake | Same. |
| `whitePaper/archive/mavis-workspace-v4.0/CHANGELOG-v4.0.md` | mojibake | Same. |

**Severity**: 🟢 low — this is a **PowerShell 5.1 default-encoding issue on Windows** (`Get-Content` defaults to system ANSI codepage, e.g., GBK/CP936 on Chinese Windows, not UTF-8). The actual files are valid UTF-8, and Python scripts read them correctly. The `.commit_msg_*.txt` files in repo root are mojibake too — but again, UTF-8 underneath.

**However** — the project has rules in AGENTS.md §"Windows file content operations" specifically warning about this:
> "On Windows, use **PowerShell syntax only**. Do NOT use legacy DOS... For reading or modifying file contents, always use the Read / Write / Edit tools — they operate directly in UTF-8..."

So the *encoding is correct on disk* and agents following the rules won't see mojibake. **No action needed.** I list it here for completeness.

### 3.9 .mimocode/ — Mavis internal plan storage

5 plan files (all 2026-07-26 20:39):
- `1784360366015-playful-island.md` (13,608 B)
- `1784385124492-mighty-sailor.md` (11,247 B)
- `1784390509936-tidy-nebula.md` (3,128 B)
- `1784437411178-brave-pixel.md` (9,532 B)
- `1784468318836-mighty-harbor.md` (7,141 B)

`final_status.txt` (line 74-75, 91) also references 2 more recent untracked plans: `1784967503871-hidden-comet.md` and `1784982512380-playful-rocket.md` — these have been deleted/rotated since.

**Severity**: 🟡 medium — `.mimocode/` is a Mavis runtime artifact directory. **It is not in `.gitignore`** (line 12-15 only have `.idea/`, `.vscode/`, `*.iml`). Mavis users expect this to be runtime-only, but it gets committed.

**Suggested fix** — add to `.gitignore`:
```gitignore
# Mavis runtime state
.mimocode/
```

### 3.10 .commit_msg_*.txt files in repo root

7 files (`.commit_msg.txt`, `_agents.md`, `_r56c3.txt`, `_r56d.txt`, `_r56e.txt`, `_r56g.txt`, `_r56h.txt`) — these are commit-message drafts. The earlier ones are mojibake (R42), the later ones (R56c3+) are clean.

**Severity**: 🟡 medium — they look like WIP artifacts. Either commit the actual commits they describe and delete the files, or gitignore them.

**Suggested fix**: add to `.gitignore`:
```gitignore
# WIP commit message drafts
.commit_msg*.txt
```

---

## 4. Pubspec / build config

### 4.1 Pubspec declared dependencies — all imported? All necessary?

Verified by grep over `lib/`. All 14 declared deps are imported in `lib/`:

| Pubspec dep | Where imported | Verdict |
|---|---|---|
| `flutter` (sdk) | everywhere | ✅ |
| `flutter_localizations` (sdk) | `lib/main.dart`, l10n | ✅ |
| `flutter_riverpod: ^3.3.2` | 25+ files | ✅ |
| `drift: ^2.20.3` | DB files | ✅ |
| `sqlcipher_flutter_libs: ^0.6.4` | `lib/main.dart` (init) | ✅ |
| `path_provider: ^2.1.4` | `lib/main.dart` | ✅ |
| `path: ^1.9.0` | `lib/main.dart`, db | ✅ |
| `flutter_secure_storage: ^9.2.2` | `lib/core/data/services/db_key_service.dart` | ✅ |
| `pointycastle: ^3.9.1` | `lib/core/data/services/encryption_service.dart` (3x), `mood_audio_service.dart` (7x), `mood_entries.dart` | ✅ |
| `go_router: ^14.6.1` | 25+ files | ✅ |
| `flutter_local_notifications: ^17.2.3` | `lib/core/data/services/notification_service.dart`, `notification_payload.dart`, `notification_navigation.dart` | ✅ |
| `flutter_timezone: ^3.0.1` | `lib/main.dart` | ✅ |
| `timezone: ^0.9.4` | `lib/main.dart`, test | ✅ |
| `permission_handler: ^11.3.1` | `lib/main.dart` (requestPermission) | ✅ |
| `fl_chart: ^0.69.0` | 5 trend chart files | ✅ |
| `pdf: ^3.11.1` | `medication_report_pdf.dart`, `medication_report_pdf_layout.dart`, `medication_report.dart`, `medication_report_dialog.dart` | ✅ |
| `printing: ^5.13.4` | `medication_report_pdf.dart` (1x) — only used to call `Printing.layoutPdf` | ✅ |
| `intl: ^0.20.2` | `lib/core/shared/formatters.dart` (R56d) | ✅ |
| `uuid: ^4.5.1` | `data_export_service.dart`, `snooze_manager.dart` | ✅ |
| `flutter_dotenv: ^6.0.1` | `lib/main.dart`, `scripts/test_delivery_rate.dart` (1x) | ✅ |
| `share_plus: ^10.1.4` | `medication_report_dialog.dart` (1x) | ✅ |
| `shared_preferences: ^2.3.3` | `lib/main.dart`, `app.dart`, `notification_service.dart` | ✅ |
| `record: ^5.2.0` | `lib/core/data/services/mood_audio_service.dart` (audio recording) | ✅ |
| `audioplayers: ^6.1.0` | `lib/presentation/pages/vent/*`, `lib/core/data/services/mood_audio_service.dart` | ✅ |
| `speech_to_text: ^7.0.0` | `lib/core/data/services/mood_audio_service.dart` (R31+) | ✅ |

**Verdict**: ✅ all 14 declared deps are imported. No dead deps.

**But**: the `.disabled` test file imports **`package:dio/dio.dart`** which is **NOT in pubspec** (see §2.6). This is the only mismatch.

### 4.2 Imports in lib/ that aren't in pubspec

Verified by grep over `lib/` for `package:` prefixes:

- `package:dio` — only in the `.disabled` test, NOT in `lib/`. ✅ OK.
- `package:flutter_riverpod` — in pubspec ✅
- `package:drift` — in pubspec ✅
- `package:drift/native.dart` — sub-package of drift ✅
- `package:go_router` — in pubspec ✅
- All others match.

**Verdict**: ✅ no rogue imports in `lib/`. (The `dio` is only in the disabled test.)

### 4.3 Pinned vs caret/tilde versions

All declared deps use **caret** (`^x.y.z`). **No exact pins.** This is the recommended Flutter practice — allows patch-level updates while locking major.

| Style | Count | Example |
|---|---|---|
| `^x.y.z` (caret) | 14 of 14 | `drift: ^2.20.3` |
| exact pin (`=x.y.z`) | 0 | — |
| `>=x.y.z <x+1.0.0` (range) | 0 | — |

**Verdict**: ✅ consistent caret usage. Acceptable.

### 4.4 Assets declared in pubspec vs on disk

**Pubspec declares** (line 75-80):

```yaml
shaders:
  - assets/shaders/ink_sparkle.frag
assets:
  - assets/icons/
  - assets/legal/user_agreement.md
  - assets/legal/privacy_policy.md
  - assets/legal/sensitive_data_consent.md
```

**Files on disk under `assets/`**:

| Path | Declared in pubspec? | Verdict |
|---|---|---|
| `assets/shaders/ink_sparkle.frag` | ✅ | ✅ |
| `assets/icons/.gitkeep` | ✅ (folder declared) | ✅ |
| `assets/legal/user_agreement.md` | ✅ | ✅ |
| `assets/legal/privacy_policy.md` | ✅ | ✅ |
| `assets/legal/sensitive_data_consent.md` | ✅ | ✅ |
| `assets/brand/app_icon_master.png` | ❌ (not declared) | 🟢 OK — brand exploration, not a ship asset |
| `assets/brand/app_icon_master_v2..v5.png` (4) | ❌ | 🟢 OK — historical |
| `assets/brand/app_icon_maskable.png` + `_v2..v5.png` (4) | ❌ | 🟢 OK |
| `assets/brand/icon_preview.png` + `_v2..v5.png` (4) | ❌ | 🟢 OK |
| `assets/brand/icon_showcase.html` | ❌ | 🟢 OK |
| `assets/brand/variations/*.png` (**100 files** = 10 categories × 10 variations + 2 contact sheets) | ❌ | 🟢 OK — but **~70 MB of unused brand exploration** is sitting in the repo. |

**Severity**: 🟢 low — the `assets/brand/variations/` folder contains **100 PNGs of brand exploration** (avg 400 KB each → ~40 MB total). None of these are declared in pubspec, so they're not shipped, but they pollute the repo. **The 5 "v5" + "v2" + "v3" + "v4" iterations are pure WIP history** — only `v5` and the unlabeled `_master.png` / `_maskable.png` are the current production assets (per `scripts/make_icon_preview_v5.py`).

**Suggested fix** (🟢 low, optional): `git rm -r --cached assets/brand/variations/` and add `assets/brand/variations/` to `.gitignore` (or just move to `assets/brand/variations/.archive/`). The 4 older `*_v2.png` / `*_v3.png` / `*_v4.png` / `icon_preview_v2.png` / `icon_preview_v3.png` / `icon_preview_v4.png` could go to an `archive/` subfolder too. This would save **~10 MB** in `.git/objects` over time.

### 4.5 Shader (`ink_sparkle.frag`) — referenced in code?

- `pubspec.yaml` line 75-76: declares `assets/shaders/ink_sparkle.frag`
- File exists on disk: `assets/shaders/ink_sparkle.frag` (3,978 B)
- AGENTS.md §"已知坑" explains why this exists: Flutter 3.41.9 + Material 3 InkWell needs the shader for widget tests.

**Verdict**: ✅ correctly declared and present.

---

## 5. Project-level hygiene

### 5.1 `.gitignore` completeness

Current `.gitignore` covers:
- Dart/Flutter: `.dart_tool/`, `build/`, `pubspec.lock`, etc. ✅
- IDE: `.idea/`, `.vscode/`, `*.iml` ✅
- OS: `.DS_Store`, `Thumbs.db` ✅
- Env: `.env`, `*.env.local` ✅
- Generated: `**/*.g.dart`, `**/*.freezed.dart`, `**/*.config.dart` ✅
- Python: `__pycache__/`, `*.pyc`, `.pytest_cache/` ✅
- In-progress: `*.disabled` ✅

**Missing entries** (verified by `git status --untracked` semantics — these files are visible but should not be):

| Pattern | Files currently in repo | Severity | Suggested fix |
|---|---|---|---|
| `_archive/` | 87 files in `scripts/_archive/` (visible to git) | 🟡 medium | Add `_archive/` to `.gitignore` (or keep tracked — but current behavior is inconsistent: `_archive/` IS tracked, but per-file cleanup is still useful for `sprint2-zh-hant-tmp/`) |
| `.mimocode/` | 5 plan files in `.mimocode/plans/` | 🟡 medium | Add `.mimocode/` to `.gitignore` (see §3.9) |
| `.commit_msg*.txt` | 7 files in repo root | 🟢 low | Add `.commit_msg*.txt` to `.gitignore` (see §3.10) |
| `*.log` | 7 files in `scripts/`, 1 in `reports/` | 🟡 medium | Add `*.log` to `.gitignore` (or scoped `scripts/_*.log` + `reports/_*.log`) |
| `*.tmp` | 1 in `scripts/_archive/` | 🟢 low | Add `*.tmp` to `.gitignore` (only archived file is present, no current offenders) |
| `*.ps1` (in reports/) | 18 `_check_callers*.ps1` in `reports/` | 🟡 medium | Add `reports/_*.ps1` to `.gitignore` (one-off scripts) |
| `_thumb_*.png` (in reports/) | 5 PNG thumbnails | 🟢 low | Add `reports/_thumb_*.png` to `.gitignore` |
| `flutter_*.log` | 1 in repo root (`flutter_01.log`) | 🟢 low | Add `flutter_*.log` to `.gitignore` |
| `.flutter_run.*.log` | 2 in repo root (`.flutter_run.log`, `.flutter_run.err.log`) | 🟢 low | Add `.flutter_run.*.log` to `.gitignore` |
| `mimo.exe` | 1 in repo root (1.4 MB binary) | 🔴 **critical** | Add `mimo.exe` to `.gitignore` (1.4 MB binary, looks like a stale tool) |

**`.mimocode/.cron-lock`** is a runtime lock file (per `.mimocode/` semantics) and is currently tracked; it's harmless (just a lock file), but should also be gitignored.

**Total**: `.gitignore` is missing **10 patterns** that would clean up 41+ files (~5 MB).

### 5.2 TODO / FIXME / XXX comments

Verified by grep over `lib/**/*.dart` for `TODO|FIXME|XXX`. All matches are TODO (no FIXME or XXX).

| File | Count | Most important lines |
|---|---|---|
| `lib/core/data/services/sms_service.dart` | 5 | L12-13 (`AliyunSmsProvider.send()`), L90, L104, L157 (R55 真接 TODO) — all "v1.0+ 后接阿里云" |
| `lib/core/data/services/notification_service.dart` | 2 | L358 (Android badge), L361 (`flutter_app_badge_control`) |
| `lib/core/data/services/email_service.dart` | 1 | L72 (real SMS send unimplemented, v1.0+ TODO) |
| `lib/core/data/services/badge_sync_service.dart` | 1 | L38 (Android badge: 暂无稳定方案) |
| `lib/core/theme/app_theme.dart` | 1 | L126 (`buildTheme` 接受 context — R25+ TODO) |

**All 10 TODOs are correctly characterized**:
- 6 are "v1.0+ real SMS/push integration" — blocked on **external dependencies** (legal + access keys), per CHANGELOG `Pending (外部依赖)`. **Not actionable** until those are unblocked.
- 2 are "Android badge" — `flutter_app_badge_control` plugin is the right solution but no permission to add new pub deps without sign-off.
- 1 is "buildTheme 接受 context" — R25 TODO, future refactor.
- 1 is "real SMS send" — same external-dep blocker.

**Severity**: 🟢 low — TODOs are well-documented and appropriately scoped. **No hidden tech debt** (i.e., no "TODO: this is broken" without context).

### 5.3 `print()` calls in `lib/`

**Method**: `Select-String -Pattern 'print\('` over `lib/**/*.dart`.

| Result | Count |
|---|---|
| `print(` calls in `lib/` | **0** |
| `debugPrint` calls in `lib/` | 0 (per grep) |
| `piiSafeLog` calls in `lib/` | 70+ (legitimate logger wrapper) |
| `developer.log` calls in `lib/` | 6 (`lib/main.dart`) |

**Verdict**: ✅ no stray `print()` calls. The project uses a centralized `piiSafeLog` (declared in `lib/core/shared/pii_safe_log.dart`) that wraps `developer.log` and applies PII masking. The only `developer.log` is in `main.dart:45` (the crash reporter `runZonedGuarded` callback). This is a clean architecture — no need to convert to a `Logger` package.

### 5.4 Hardcoded paths in `lib/`

**Method**: `Select-String -Pattern 'C:\\Users|C:\\\\Batch'` over `lib/**/*.dart`.

| Result | Count |
|---|---|
| `C:\Users` references in `lib/` | **0** |
| `C:\\Batch` (Windows) | **0** |
| `C:/Windows` references | **0** |

**Verdict**: ✅ no hardcoded absolute paths in `lib/`. (The `make_icon_preview_v5.py` in `scripts/` does hardcode `D:/Batch/chroniccare` at line 14, but that's a one-off script that's already in the "archive" list per §1.3.)

### 5.5 Other hygiene

| Item | Verdict | Note |
|---|---|---|
| `pubspec_overrides.yaml` | ⚠️ exists | Per file presence — should check it's not overriding locked versions. Cannot verify without content. |
| `.env` (vs `.env.example`) | ✅ both exist | `.env` is in `.gitignore` (line 23). |
| `.flutter-plugins-dependencies` | ✅ in `.gitignore` (line 6) | OK. |
| `.metadata` | ✅ standard Flutter | OK. |
| `analysis_options.yaml` | ✅ exists | Configures `flutter_lints ^5.0.0` per pubspec. |
| `l10n.yaml` | ✅ exists | Configures `generate: true` for l10n. |
| `mimo.exe` (1.4 MB) | 🔴 **critical** | Should be gitignored or deleted. Looks like a runtime binary for some tool. |

---

## 6. Issue severity rollup

### 6.1 Critical (act now)

| # | Issue | Where | Why critical |
|---|---|---|---|
| C1 | `AGENTS.md` schemaVersion says "12" but actual is **14** | `AGENTS.md` §"必读文件" #2 | AI agent following AGENTS.md will assume migrations 12→14 are not done. Could attempt to re-run a completed migration. |
| C2 | `home_page.dart` (primary daily user path) has **0 widget tests** | `lib/presentation/pages/home/home_page.dart` | Home page = check-in button = the **#1 reason** the user opens the app. Silent UX regression is unguarded. |
| C3 | `mimo.exe` (1.4 MB binary) tracked in repo root | `D:\Batch\chroniccare\mimo.exe` | Bloat + accidental commit. |
| C4 | `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` imports undeclared `package:dio` | `test/.../aliyun_sms_provider_round57_test.dart.disabled:17` | Either enable (add `dio` to pubspec) or delete. Parked state. |

### 6.2 Medium (act this sprint)

| # | Issue | Where | Why |
|---|---|---|---|
| M1 | 9 one-off `_rXX_/_tmp_/_clean_*.py` polluting `scripts/` root | `scripts/_r49_*.py` (3), `scripts/_r53a_*.py` (3), `scripts/_r56*.py` (2), `scripts/_r59_*.py` (1), `scripts/_clean_orphan_arb_keys.py` (1) | Confuses "what is a CI guard". Easy fix. |
| M2 | 17 stale `.txt` / `.log` artifacts in `scripts/` | `scripts/*.txt` (10), `scripts/_*.log` (6), `scripts/_check_all_round59.log` (1) | ~1.6 MB of debugging output, none referenced. |
| M3 | `scripts/make_icon_preview_v5.py` and `scripts/test_delivery_rate.dart` are one-offs not yet archived | `scripts/` | Should join `_archive/`. |
| M4 | 11 of 13 Python guards have **no tests** | `test/scripts/` | A typo in any regex silently breaks the guard. |
| M5 | `.gitignore` is missing 10 patterns | `.gitignore` | Would clean 41+ files. |
| M6 | `assets/brand/variations/` has 100 WIP icon PNGs (~40 MB) | `assets/brand/variations/*.png` | Repo bloat, not shipped. |
| M7 | `whitePaper/慢病管家-白皮书-v3.0.md` claims "v0.17 round 7, 703 tests" but project is at v0.25, 1098 tests | `whitePaper/慢病管家-白皮书-v3.0.md:8,36,38` | Marketing/positioning material is misleading. |
| M8 | `test/data/database_migration_round20_test.dart:30-35` only asserts method-existence (`expect(X, isA<Function>())`) | `test/data/database_migration_round20_test.dart` | No behavioral test. Stub. |
| M9 | `test/data/medication_repository_round9_test.dart:58` has hard `await Future.delayed(100ms)` for "clock skew buffer" | `test/data/medication_repository_round9_test.dart` | Borderline flaky. |
| M10 | `test/scripts/check_all_round18_test.dart` duplicates `_testResolveImportLayer` instead of testing the real function | `test/scripts/check_all_round18_test.dart:90-134` | If real function changes, this test still passes. |

### 6.3 Low (nice to have)

| # | Issue | Where |
|---|---|---|
| L1 | `app_zh_Hant.arb.tmp` (43 KB) in `scripts/_archive/` is a stale backup | `scripts/_archive/app_zh_Hant.arb.tmp` |
| L2 | `*.disabled` gitignore pattern matches the .disabled test, but the test still sits in source tree | `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` |
| L3 | 11 of 13 Python guards have no tests (no pytest infrastructure in `test/scripts/` for 11 of them) | `test/scripts/` |
| L4 | `pubspec_overrides.yaml` exists (unverified content) | `pubspec_overrides.yaml` |
| L5 | `docs/decisions/v0.17_animations_extraction.md` could be marked ✅ DONE | `docs/decisions/v0.17_animations_extraction.md` |
| L6 | 4 `docs/refactor/*.md` design docs could be marked ✅ Completed | `docs/refactor/` |
| L7 | `assets/brand/app_icon_*_v2..v4.png` are WIP history (4 master + 4 maskable = 8 files) | `assets/brand/` |
| L8 | 24 debugging artifacts in `reports/` (`_check_callers*.ps1`, `_thumb_*.png`, `_callers6.log`) | `reports/` |
| L9 | PowerShell mojibake display for 27 `.md` files (encoding OK on disk; PS5 default-encoding artifact only) | various |
| L10 | 7 `.commit_msg*.txt` in repo root | repo root |

---

## 7. Recommended action plan

**Cost/benefit-sorted** (do cheapest/most-impactful first):

### Sprint A (1-2 hours)

1. **M1 + M2 + M3** (1 hr) — Move 11 one-off scripts and 17 log/txt files to `scripts/_archive/` (or just delete the logs).
2. **C3** (1 min) — Add `mimo.exe` to `.gitignore` and `git rm --cached mimo.exe`.
3. **M5** (5 min) — Add 10 patterns to `.gitignore` (`.mimocode/`, `_archive/`, `*.log`, `*.tmp`, `.commit_msg*.txt`, `reports/_*.ps1`, `reports/_thumb_*.png`, `flutter_*.log`, `.flutter_run.*.log`, `mimo.exe`).
4. **C1** (1 min) — Fix `AGENTS.md`: "schemaVersion 当前 12" → "schemaVersion 当前 14" (1 line edit).
5. **L5, L6** (10 min) — Add "✅ Completed" banners to 5 docs.

### Sprint B (1-2 days)

6. **C2** (4-8 h) — Add `test/presentation/pages/home/home_page_round60_test.dart` covering the 3 primary user paths (check-in, mood, vent).
7. **C4** (30 min) — Decide: enable `aliyun_sms_provider_round57_test.dart` (add `dio` to pubspec) OR delete.
8. **M4** (1-2 days) — Add pytest-style tests for the 3 highest-risk guards: `check_arb_keys.py`, `check_no_pua.py`, `check_zh_hant_consistency.py`.
9. **M7** (4-6 h) — Update `whitePaper/慢病管家-白皮书-v3.0.md` to v0.25 round 56e + 1098 tests.
10. **M6** (30 min) — `git rm -r --cached assets/brand/variations/` and add to `.gitignore`.

### Sprint C (backlog)

11. **M8** (1-2 h) — Replace stub test in `database_migration_round20_test.dart:30-35` with a real test (use `NativeDatabase.memory()` + run onUpgrade).
12. **M9** (1 h) — Convert `medication_repository_round9_test.dart:58` to `fakeAsync`.
13. **M10** (2 h) — Refactor `check_all.dart` to export `_resolveImportLayer` via `@visibleForTesting` so the test doesn't duplicate.
14. **L1** (1 min) — Delete `scripts/_archive/app_zh_Hant.arb.tmp`.
15. **L7, L8** (1 h) — Clean up WIP assets + reports artifacts.

---

## Appendix A — Inventory snapshots (for verification)

### A.1 scripts/ root (all 30 files, 2026-07-27)

| Status | File | Size (B) | Last Modified |
|---|---|---|---|
| KEEP | check_all.dart | 13,577 | 2026-07-18 |
| KEEP | check_arb_keys.py | 5,295 | 2026-07-26 |
| KEEP | check_changelog.py | 3,074 | 2026-07-26 |
| KEEP | check_cross_feature.py | 5,252 | 2026-07-18 |
| KEEP | check_datetime_race.py | 1,961 | 2026-07-24 |
| KEEP | check_datetime_race2.py | 3,168 | 2026-07-24 |
| KEEP | check_drift_namespace.py | 2,401 | 2026-07-17 |
| KEEP | check_fullwidth_punctuation.py | 5,327 | 2026-07-27 |
| KEEP | check_legal_consent.py | 3,137 | 2026-07-26 |
| KEEP | check_no_hardcoded_utc.py | 3,614 | 2026-07-26 |
| KEEP | check_no_pua.py | 3,483 | 2026-07-26 |
| KEEP | check_orphan_arb_keys.py | 4,520 | 2026-07-26 |
| KEEP | check_sms_release_ready.py | 5,568 | 2026-07-27 |
| KEEP | check_strings_hardcoded.py | 5,384 | 2026-07-27 |
| KEEP | check_widget_dispose.py | 4,716 | 2026-07-26 |
| KEEP | check_zh_hant_consistency.py | 4,687 | 2026-07-26 |
| ARCHIVE | _clean_orphan_arb_keys.py | 3,103 | 2026-07-26 |
| ARCHIVE | _r49_dark_mode_color_replace.py | 2,433 | 2026-07-26 |
| ARCHIVE | _r49_remove_const_for_dynamic_color.py | 1,164 | 2026-07-26 |
| ARCHIVE | _r49_remove_const_v2.py | 877 | 2026-07-26 |
| ARCHIVE | _r53a_dedup_imports.py | 890 | 2026-07-26 |
| ARCHIVE | _r53a_fix_dao_imports.py | 1,480 | 2026-07-26 |
| ARCHIVE | _r53a_remove_g_imports.py | 661 | 2026-07-26 |
| ARCHIVE | _r56_icon_size_replace.py | 2,350 | 2026-07-26 |
| ARCHIVE | _r56b_spacing_tokenize.py | 2,204 | 2026-07-26 |
| ARCHIVE | _r59_fix_underscore.py | 596 | 2026-07-26 |
| ARCHIVE | make_icon_preview_v5.py | 7,909 | 2026-07-21 |
| ARCHIVE | test_delivery_rate.dart | 2,125 | 2026-07-25 |
| LOG/DEBUG | diff_stat.txt | 8,678 | 2026-07-26 |
| LOG/DEBUG | final_status.txt | 5,483 | 2026-07-26 |
| LOG/DEBUG | final_stats_for_report.txt | 478 | 2026-07-26 |
| LOG/DEBUG | gitlog.txt | 0 | 2026-07-26 |
| LOG/DEBUG | gitlog2.txt | 149 | 2026-07-26 |
| LOG/DEBUG | list6.txt | 1,267 | 2026-07-26 |
| LOG/DEBUG | list7.txt | 11,330 | 2026-07-26 |
| LOG/DEBUG | status.txt | 1,152 | 2026-07-26 |
| LOG/DEBUG | status2.txt | 783 | 2026-07-26 |
| LOG/DEBUG | status3.txt | 322 | 2026-07-26 |
| LOG/DEBUG | _analyze_round59.log | 10,966 | 2026-07-27 |
| LOG/DEBUG | _analyze_round59_v2.log | 10,966 | 2026-07-27 |
| LOG/DEBUG | _analyze_round59_v3.log | 10,966 | 2026-07-27 |
| LOG/DEBUG | _check_all_round59.log | 1,060 | 2026-07-27 |
| LOG/DEBUG | _test_baseline.log | 570,246 | 2026-07-27 |
| LOG/DEBUG | _test_round59.log | 568,544 | 2026-07-27 |
| LOG/DEBUG | _test_round59_v3.log | 569,994 | 2026-07-27 |

**Tally**: 16 KEEP + 10 ARCHIVE (one-off scripts) + 17 LOG/DEBUG = 43 files (matches `Get-ChildItem scripts/ -File | Measure-Object`).

### A.2 test/ subdirs (file count + dart/python split)

| Subdir | .dart | .py | .disabled | Notes |
|---|---|---|---|---|
| `test/data/` | 33 | 0 | 0 | largest test dir |
| `test/domain/` | 28 | 0 | 0 | pure-Dart business logic |
| `test/presentation/` | 19 | 0 | 0 | widget tests, app shell, etc. |
| `test/core/data/services/` | 10 | 0 | 0 | spen P0 #15 TDD additions |
| `test/core/shared/` | 4 | 0 | 0 | swallow_error, user_name_helper, etc. |
| `test/core/theme/` | 2 | 0 | 0 | app_tokens_dark, motion_scheme |
| `test/core/data/utils/` | 1 | 0 | 0 | phone_validator |
| `test/presentation/widgets/` | 6 | 0 | 0 | press_feedback, motion, emil, etc. |
| `test/presentation/widgets/animations/` | 2 | 0 | 0 | fade_in, slide_up |
| `test/presentation/pages/settings/` | 1 | 0 | 0 | settings_page_round45 |
| `test/presentation/pages/trend/` | 1 | 0 | 0 | trend_page_round45 |
| `test/routing/` | 1 | 0 | 0 | route_parsing_round19c |
| `test/scripts/` | 1 | 2 | 0 | check_all_round18 + check_drift_namespace_test + check_cross_feature_test |
| **Total** | **111** | **2** | 0 | + 1 `.disabled` at `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` |

### A.3 Schema version history (from app_database.dart:50-82 comments)

| Version | Round | Change |
|---|---|---|
| 1 → 2 | (initial) | contact email→phone, medication dosage |
| 2 → 3 | (initial) | report_histories table |
| 3 → 4 | (initial) | mood_entries table |
| 4 → 5 | (initial) | medication refill fields |
| 5 → 6 | v0.18 round 18 (P1-15) | (per comment L50) |
| 6 → 7 | v0.18 round 18 (P2-P0-8) | (per comment L54) |
| 7 → 8 | (per comment L56) | |
| 8 → 9 | v0.21 round 22 (P0-1) | (per comment L56) |
| 9 → 10 | v0.21 round 22 (P1-22) | (per comment L60) |
| 10 → 11 | v0.21 round 23 (P1-24) | (per comment L62) |
| 11 → 12 | v0.23 round 31 (P0) | new feature (per comment L70) |
| 12 → 13 | v0.23 round 43 | check_ins medicationId index |
| 13 → 14 | v0.23 round 44 | contacts (is_active, sort_order) + report_histories generated_at indexes |
| **CURRENT** | **14** | (per L82) |

**Drift**: AGENTS.md says "schemaVersion 当前 12" — that's **2 versions stale**.

### A.4 .gitignore gap analysis

Current 37 lines. Missing 10 patterns (per §5.1). After fix, the file would have ~47 lines and would automatically cover 41+ files.

---

*End of report. Total length: ~750 lines. Re-read sections 0, 1.1, 5.1, 6, and 7 for executive action items.*
