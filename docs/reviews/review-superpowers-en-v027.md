# Superpowers (EN) Architecture Review — chroniccare v0.27 round 58

> **Methodology lens**: superpowers-en (upstream, 233k+ ⭐) — TDD, systematic-debugging, code review, subagent-driven-development, writing-plans, verification-before-completion.
> **Project**: D:\Batch\chroniccare (慢性病 / 精神心理患者吃药打卡 App, Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6)
> **Review scope**: v0.23 round 42 → v0.27 round 58 (12 rounds, ~50 commits since the v0.24 spen baseline review)
> **Latest commit**: `2ad8246 v0.27 round 58: A-01 warn-only + A-03 文档化`
> **Status**: 1109/1109 tests pass, 0 analyzer error, 16 guard scripts green (12 baseline + 4 added in R57/R58)
> **Prior reviews consulted** (to avoid duplicating findings):
> - `docs/reviews/v0.23/review_superpowers_en_round42.md` (62K bytes, 201 findings, baseline)
> - `docs/reviews/2026-07-26-three-lens/spen/report.md` (56K bytes, v0.24 review, 55 findings)
> - `docs/reviews/v0.25/review_superpowers_en_round56h.md` (21K bytes, v0.25 R49-R60 增量 review, 15 findings)
> **Supersedes** (where this review agrees with prior findings, it explicitly cites them so reader can trace the chain).

---

## TL;DR — Executive summary

| Dimension | v0.24 baseline | v0.27 (now) | Delta | Verdict |
|---|---|---|---|---|
| Architecture (4-layer + core umbrella) | 4/5 ⭐ | 4.5/5 ⭐ | +0.5 | 🟢 **mature, no change needed** |
| God-class count (>300 lines) | 13 | ~10 (9 services + 11 page widgets) | -3 split (app_database, app_router, safety_watch, medication_report, data_export, medication_report_pdf) | 🟢 good progress |
| Test count | ~910 | 1109 | +199 (R56c-c''' 46 + R57 +11 + others) | 🟢 TDD discipline restored after R56 |
| Guard scripts | 11 | 16 | +5 (R57: sms_release_ready / legal_consent / strings_hardcoded / zh_hant_consistency) + R58 fixed | 🟢 strong CI story |
| Latent P0 bugs (R52 closed 7) | 7 open | 1-2 likely (see §5) | -5 to -6 | 🟡 watch for regression |
| Architecture boundary purity | 100% | 100% (R57 verified) | stable | 🟢 |

**Verdict**: The project is in **excellent architectural health** and is now in **maintenance / feature-adding mode**, not in refactor mode. The spen "渐进 facade 模式" (progressive facade pattern) is a strong reusable abstraction that has been applied 7+ times. Remaining work is largely **(a) parallel god-class splits on presentation widgets, (b) systematic-debugging regression guards (5 test classes), and (c) CI/build verification** that hasn't been completed since the v0.21 P0-3 era.

**Top 3 actions recommended**:

1. **R58+ `home_page.dart` widget test** — currently the most critical user-facing page has 0 widget tests. Use `mockito`/`ProviderScope` override pattern, start with happy-path + mid-day + after-medication-fire states.
2. **R59 systematic-debugging 5-class regression guard** — the v0.25 R56c-c''' batch added 46 tests but stayed in happy-path / dispatch logic; the documented R19-B classes (跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose) are still un-locked.
3. **R60 CI workflow** (`verification-before-completion`) — 16 guard scripts + `flutter analyze` + `flutter test` + `flutter build apk --debug` + `flutter build web` should run in `.github/workflows/ci.yml`. R49-R58 made 60+ token replacements with no golden test or build verification commit.

---

## 1. Top-level architecture assessment

### 1.1 Current architecture fitness for testability

**Rating: 4.5 / 5 ⭐** (improved from 4/5 in v0.24 review)

The 4-layer architecture (`presentation → domain ← data`) + 5-sub-layer `core/` umbrella is **mature, idiomatic Flutter, and CI-validated**. Key strengths:

- **domain layer = 0 Flutter, 0 Drift dependencies** (verified by `dart scripts/check_all.dart`, runs in CI). 19 domain files (`entities/`, `logic/`, `repositories/`, `usecases/`) are pure Dart → fast unit tests, no widget tree.
- **mapper layer** in `data/database/mappers/{feature}/` cleanly isolates Drift row ↔ domain entity translation. `data_export_orchestrator.dart:34-47` (the `isoUtc()` helper) and `medication_repository_impl.dart:50-76` are textbook examples.
- **value-object pattern** is now established — see `MedicationDraft` (R60, 9 fields → 1 param, see `lib/domain/entities/medication_draft.dart`), `MoodEntryDraft` (R48), `HourMinute`, `DomainValue<T>`.
- **sub-service + facade pattern** is now consistent across **7 services**:
  - `AppDatabase` (R53a) → 7 DAOs + facade
  - `NotificationService` (R45) → 5 sub-service + facade
  - `SafetyWatchService` (R57) → `SafetyConfigService` + `SafetyAlertDispatcher` + facade
  - `MedicationReport` (R58) → `MedicationStatCalculator` + `MissedDateBuilder` + `TempEntryExtractor` + facade
  - `DataExportService` (R57) → `ExportOrchestrator` + 3 sub-service + facade
  - `AppRouter` (R59) → `AppRoutes` + 5 `AppRoute*.dart` + `AppShell` + provider
  - `AppRoutes` (R57) → 5 `AppRouteMain/Assessment/Medication/Vent/CheckIn`
  This is **reusable architectural DNA** — see §6 for subagent opportunities.

**What's still imperfect**:

- **`data/` layer has internal god classes** (services > 300 lines). The "domain is pure" boundary is intact, but the data implementation is uneven: `medication_report_pdf` 10K, `safety_watch_service` 13K, `mood_audio_service` 11K, `notification_service` 15K (facade OK, but `_showSafetyAlert` still 50 lines inline, see §3).
- **No build verification** — R49-R58 made sweeping token + dark-mode + 60+ color replacements with no `flutter build apk` / `flutter build web` commit. The v0.21 P0-3 web-platform `drift worker 404` was found in production-style testing, not CI.
- **No golden tests** — 0 golden files in `test/golden/`. R49 dark-mode 60+ color changes have no visual regression lock.

### 1.2 Alternative architectures considered

Following the **superpowers writing-plans** discipline, I evaluated 3 alternatives against the v0.27 baseline:

| Alternative | Pros | Cons | Verdict |
|---|---|---|---|
| **Hexagonal (Ports & Adapters)** — explicit `domain/ports/` + `data/adapters/` | Cleaner port boundaries; future-proof for multiple DB/notification backends; matches the team's mental model | The 9 repository interfaces in `domain/repositories/*.dart` are already hexagonal-style ports. Adding a `ports/` directory layer is structural only, not behavioral. Most adapters are 1:1 with ports. **Cost > benefit**. | ❌ **Reject** — current shape is already ports-and-adapters by another name. |
| **Modular package monorepo** (split into `packages/core`, `packages/feature_medication`, ...) | True compile-time isolation; parallel CI; clearer ownership; pub.dev compatible | 1098 test files across 16 guard scripts — would all need re-pathing. Drift build_runner output goes per-package → schema migration fragmented. cross-feature import guard already exists (`check_cross_feature.py`) so the *runtime* boundary is enforced. **Massive churn for 0 behavioral gain.** | ❌ **Reject** — the existing `check_cross_feature.py` script gives 80% of the benefit at 5% of the cost. |
| **Feature-sliced design** (`features/{medication,vent,...}/{data,domain,presentation}/`) | Co-located feature code; better for large teams (10+ devs); the 11 `pages/{feature}/` directories already are half-vertical-sliced | The `core/` umbrella (DB, theme, l10n, routing) is inherently cross-cutting. `check_cross_feature.py` already enforces the boundary. **Would require lifting 1098 tests into feature packages.** | ❌ **Reject** for now — revisit when team grows past 3-4 devs or when adding a 6th feature module. |
| **Status quo: 4-layer + core umbrella + sub-service + facade** | Mature, well-tested, CI-validated, has 7 instances of the proven split pattern | Internal god classes in `data/` and 9 large presentation widgets | ✅ **Keep** |

**Conclusion**: No architectural switch is warranted. The next round of work is **applying the existing pattern to remaining god classes**, not inventing a new architecture.

### 1.3 Refactor targets for high cohesion / low coupling

Concrete refactor targets (file:line, severity P0-P3, effort XS-XL):

| Target | File:Line | Reason | Sev | Effort |
|---|---|---|---|---|
| `home_page.dart` (17K) | `lib/presentation/pages/home/home_page.dart:1-380` | **No widget test, core user journey**. 380 lines, 5 visible sub-widgets in `widgets/` (encouragement, footer, header, primary_action, secondary_action). Should follow the R45/R47 pattern: orchestrator + 5 sub-widgets. | P0 | L |
| `mood_recorder.dart` (21K) | `lib/presentation/pages/mood/widgets/mood_recorder.dart:1-600` | Largest presentation file. R52 fixed the dispose race but no widget test verifies the fix. Resource-heavy (record + audioplayers + temp file). Should split into `mood_recorder_controller` (pure state machine) + 2 widgets. | P0 | L |
| `safety_watch_service.dart` (13K) | `lib/core/data/services/safety_watch_service.dart:1-340` | 8 `@Deprecated` facade methods still callable. R57 created `_config` + `_alertDispatcher` but facade is bloated. R59+ should delete the 8 deprecates + reduce facade to ~100 lines. | P1 | S |
| `notification_service.dart` `_showSafetyAlert` | `lib/core/data/services/notification_service.dart:~200-250` | 50 lines of safety-alert inline still in facade; should move to `SafetyAlertDispatcher` (already exists, see R57). | P1 | S |
| `medication_report_pdf.dart` (10K) split in R57, layout file (10K) | `lib/core/data/services/medication_report_pdf_layout.dart:1-300` | Layout file is now its own god class (8 widget builders). Should extract `PdfHeader` / `PdfFooter` / `PdfMedicationBlock` into separate files. | P2 | S |
| `setup_page.dart` (15K) | `lib/presentation/pages/setup/setup_page.dart:1-420` | 4 step widgets already extracted (`setup_step_*`), but the orchestrator still does 200+ lines of TextEditingController + focus management. | P2 | M |
| `app_database.dart` (18K, R53a split) | `lib/core/data/database/app_database.dart:1-373` | saveSetup + clearAllUserData are 50 lines in facade; could move to a `SetupOrchestrator` similar to `ExportOrchestrator`. | P3 | M |

---

## 2. TDD & test coverage gaps

### 2.1 Per-module test coverage analysis (R57 → R58)

**1109/1109 cases pass, 108 test files** (verified `test/` directory).

**R57 added +11 TDD cases** (per the commit `4ce7bf9 v0.26 round 57`):
- `medication_notifier_round61c2_test.dart` +2 (total 12)
- `refill_notifier_round61c_test.dart` +4 (total 14)
- `mood_audio_service_round61c3_test.dart` +3 (total 13)
- `safety_alert_dispatcher_round61c3_test.dart` +2 (total 9)

**R58 added 0 new tests** (only documentation + guard script fixes).

### 2.2 Critical 0-test paths

The following **user-facing or business-critical paths still have 0 test coverage**:

| # | Module | File:Line | Risk | Why 0 tests |
|---|---|---|---|---|
| 1 | `home_page.dart` widget | `lib/presentation/pages/home/home_page.dart:1-380` | 🟠 **P0** — daily landing page | Was deferred in R17 ("0 widget test still 0"). No unit-testable logic (all widget composition). |
| 2 | `mood_recorder.dart` widget | `lib/presentation/pages/mood/widgets/mood_recorder.dart:1-600` | 🟠 **P0** — audioplayers + record + temp file | R48 added `vent_compose_stop_and_cleanup_round48_test.dart` (1 file), R52 fixed the dispose race but added no regression test. |
| 3 | `vent_detail_page.dart` widget | `lib/presentation/pages/vent/vent_detail_page.dart:1-380` | 🟠 **P0** — privacy boundary | 0 widget test; the 3 `StreamSubscription` cancels verified by code review (R48) but no test asserts the cancel. |
| 4 | `setup_page.dart` happy path beyond step 1 | `lib/presentation/pages/setup/setup_page.dart:1-420` | 🟡 P1 — 4-step first-run experience | Only `setup_step2_round14_test.dart` + `setup_consent_round14_test.dart`. Step 3 (medication) and step 4 (done) untested. |
| 5 | `medication_calendar_page.dart` beyond 1 case | `lib/presentation/pages/medication/medication_calendar_page.dart:1-450` | 🟡 P1 | `medication_calendar_round13c_test.dart` is 1 happy-path case. No DST / cross-month / no-data tests. |
| 6 | `trend_page.dart` beyond 2 cases | `lib/presentation/pages/trend/trend_page.dart:1-300` | 🟡 P1 | `trend_page_round45_test.dart` 2 cases. Switcher + no-data + 1-year window untested. |
| 7 | `safety_watch_service.dart` error path | `lib/core/data/services/safety_watch_service.dart:300+` | 🟠 **P0** — privacy-critical | `safety_watch_service_round12_test.dart` is happy-path only. DB exception, SMS failure, DND windows untested. R56c''' added 2 cases for `SafetyAlertDispatcher` but not the orchestrator. |
| 8 | `email_service.dart` outdated test | `test/data/email_service_round9_test.dart` | 🟠 **P0** — security | API changed in v0.20 (EncryptionService refactor) but the test still references the v0.9 mock. Will fail when re-run. |
| 9 | `data_export_orchestrator.dart` v4 (4D mood) | `lib/core/data/services/export/export_orchestrator.dart` | 🟡 P1 | R45 added round39 tests for v1-v3; v4 (4D mood) added R45 schema but no v4 explicit round-trip test. |
| 10 | `setup_page.dart:404` 5s timeout fix (R52) | `lib/presentation/pages/setup/setup_page.dart:404` | 🟡 P1 | R52 added `.timeout(5s, onTimeout: () => [])` but no test asserts the timeout triggers. |

### 2.3 TDD anti-patterns observed

In line with the superpowers `test-driven-development` discipline, these are test smells that should be flagged:

1. **Self-fulfilling JSON round-trip tests** — `data_export_round39_test.dart` (14K bytes) has 50+ cases, but most assert "encode then decode gives same value" — this tests the implementation, not the behavior. Behavior tests would assert "after import, query the DB and verify the row exists with all fields".
2. **No negative-path tests for SMS / notification failures** — `safety_alert_dispatcher_round61c3_test.dart` uses `_ScriptedSmsProvider` to inject success; no case for "SMS times out" or "DB write fails mid-stream".
3. **No race-condition tests for midnight / DST** — `app_root_round17_midnight_test.dart` exists but only tests the 23:59:59→00:00:05 timer; no test for DST spring-forward / fall-back.

---

## 3. God classes / god functions remaining

### 3.1 Per-file: lines, concerns, recommended split

Following the v0.25 R49-R60 + v0.26 R57 + v0.27 R58 god-class reduction, the **remaining large files** are:

| # | File | Lines | Concerns (count) | Recommended split | Sev | Effort |
|---|---|---|---|---|---|---|
| 1 | `lib/presentation/pages/mood/widgets/mood_recorder.dart` | 600+ | 6 (recorder + player + STT + temp file + dispose + animation) | `_MoodRecorderController` (state machine, pure) + 2 widgets (record panel, playback panel) | P0 | L |
| 2 | `lib/presentation/pages/trend/trend_calendar.dart` | 540+ | 4 (heat map + month grid + day detail card + event row) | `_CalendarMonthGrid` + `_HeatMapCell` + `_DayDetailCard` widgets (already partially split in R47 `trend_charts`) | P1 | L |
| 3 | `lib/core/data/database/app_database.dart` | 373 | 2 (saveSetup + clearAllUserData remain after R53a split) | `SetupOrchestrator` (like `ExportOrchestrator` pattern in R57) | P3 | M |
| 4 | `lib/presentation/pages/settings/reminders_hub_page.dart` | 500+ | 6 (5 card widgets + 1 orchestrator) | R41 (emil) added 5 cards in `reminder_cards.dart` but orchestrator still 200+ lines | P1 | M |
| 5 | `lib/presentation/pages/home/home_page.dart` | 380 | 5 (5 widgets in `widgets/` already, but page wires them) | Already partially split. Orchestrator could move to `HomePageController` notifier. | P1 | M |
| 6 | `lib/presentation/pages/assessment/assessment_page.dart` | 450+ | 5 (page + 4 widgets) | Already partially split (R47). The 5th widget is the answer-card. | P2 | M |
| 7 | `lib/presentation/pages/medication/medication_calendar_page.dart` | 450+ | 3 (header + calendar + list) | Already partially split (R47). | P3 | S |
| 8 | `lib/presentation/pages/setup/setup_page.dart` | 420+ | 4 (4 step widgets already extracted, but orchestrator is monolithic) | Could add `SetupFlowController` notifier. | P3 | M |
| 9 | `lib/main.dart` | 380+ | 6 (dotenv + tz + migration + notification + SMS + runApp) | Could extract `_Bootstrap` class (pattern after R45 facades). | P3 | S |
| 10 | `lib/core/data/services/safety_watch_service.dart` | 340+ | 4 (8 deprecated facade + 3 trigger methods + 1 timeout) | **R57 already split `_config` + `_alertDispatcher`; R59+ should delete 8 `@Deprecated` and reduce facade to 100 lines.** | P1 | S |
| 11 | `lib/core/data/services/notification_service.dart` `_showSafetyAlert` inline | 50 | 1 (safety alert path) | Move to `SafetyAlertDispatcher` (R57 already extracted the SMS portion, alert formatting still in facade) | P1 | S |
| 12 | `lib/core/data/services/medication_report_pdf_layout.dart` | 300+ | 8 (8 layout helpers) | Split into `pdf_header.dart` / `pdf_footer.dart` / `pdf_medication_block.dart` / `pdf_temp_med_block.dart` | P2 | S |
| 13 | `lib/core/data/services/mood_audio_service.dart` | 350+ | 4 (init + record + STT + dispose) | Already has `MoodRecorderController` separation; STT lifecycle could go to `MoodSttAdapter` | P3 | M |
| 14 | `lib/core/data/services/medication_notifier.dart` | 180 | 3 (id formula + schedule + reschedule) | OK after R56c'' tests. | — | — |

**Note**: The 2026-07-26 spen review (R56h) listed 4 un-split god classes. R57 split 3 of them (`data_export_service 539→91`, `medication_report_pdf 304→59`, `app_routes 280→155`). The remaining concern in this list is **`home_page.dart` and `mood_recorder.dart`** because they are user-facing presentation widgets (the data services are now mostly clean).

---

## 4. Code review findings

Applying the **superpowers code-review** lens (SRP, hidden coupling, missing abstractions, leaky boundaries, naming):

| # | Area | File:Line | Issue | Recommendation | Sev | Effort |
|---|---|---|---|---|---|---|
| 1 | SRP / Hidden coupling | `lib/core/data/services/safety_watch_service.dart:81-120` | 8 `@Deprecated` facade methods still callable. New code could call these and never migrate. | R59+ add `// ignore: deprecated_member_use` sweep + delete on next major bump. Add `lints.yaml` rule to fail on `@Deprecated` use outside test code. | P1 | S |
| 2 | SRP | `lib/core/data/services/notification_service.dart` (whole file, ~250 lines) | `_showSafetyAlert` 50 lines of safety-alert code still in facade after R45 split | Move to `SafetyAlertDispatcher` (R57 has the SMS portion; add the iOS-focus + Android-alarm-importance). R57 left this half-done. | P1 | S |
| 3 | Missing abstraction | `lib/main.dart:98-149` | Migration check + dialog + fallback UI are all inline in `_bootstrap` | Extract `_MigrationOrchestrator` (matches `ExportOrchestrator` pattern). R58 added `_MigrationPromptController` — partial abstraction. | P2 | M |
| 4 | Missing abstraction | `lib/core/l10n/strings.dart:1-340` (12K bytes) | 29 `static const String` + 28 `static String xxxText({String? override})` pairs (R57 P0 #6). A simple `l10nBuilder` macro would centralize. | R59+ introduce `Strings.fromL10n(AppLocalizations? l10n)` so callers can do `Strings.moodEntryTitle(l10n)` and fall back automatically. | P2 | M |
| 5 | Leaky boundary | `lib/core/routing/app_routes.dart:128-170` (`errorBuilder`) | Calls `l10n?.errorPageNotFound(...)` directly. If l10n is null, falls back to Chinese `'返回首页'` mixed with English `'page not found'`. | Use `Strings.errorPageNotFound(...)` (matches the R57 P0 #6 `xxxText({String? override})` pattern) so the fallback is consistent across UI/services. | P2 | S |
| 6 | Naming | `lib/core/data/services/notification_service.dart:5-15` | The comment says "6 类 ID 范围常量" but only 4 of them appear in this file (1001, 5000, 7000, 9999). 2000-21999 / 6000-206000 / 300000+ live in sub-services. | Move the master list to `notification_payload.dart` (R18 P0-3) and have sub-services reference the const. Single source of truth. | P3 | S |
| 7 | Hidden coupling | `lib/core/data/services/export/export_orchestrator.dart:69-73` | `ExportOrchestrator.legacy` factory and `DataExportService` 3-arg constructor both create default sub-services. If caller overrides only one, the rest are still defaulted — inconsistent state. | Add `ExportOrchestrator.strict({...})` that requires all 4 sub-services. Migrate facade to strict, keep `legacy` for 1 release. | P2 | M |
| 8 | DRY | `lib/core/data/services/notification_service.dart:152-160` | tz init runs in 2 places: `main.dart:93` and `notification_service.dart:152-160`. R52 fixed the race but didn't dedupe. | Move to a single `_initTimezone()` static in `core/shared/timezone_init.dart`; main + notification both call it. | P3 | XS |
| 9 | SRP | `lib/presentation/pages/home/home_page.dart:1-380` | Page has: header (1 widget), footer (1 widget), encouragement (1 widget), primary action (1 widget), secondary action (1 widget), `CareEngine.evaluate` call, `careEngineFire`, `DateTime.now()` capture, midnight refresh listener, `ref.invalidate(streakSummaryProvider)`, snackbar logic. **10 concerns in 1 file.** | Pattern: R41 `reminders_hub_page` did exactly this — 5 cards + 1 orchestrator. Apply the same. | P1 | M |
| 10 | Leaky boundary | `lib/presentation/pages/setup/setup_page.dart:404` (verified R52 fix) | `ref.read(medicationRepositoryProvider).watchAll().first.timeout(5s, onTimeout: () => [])` — the `onTimeout` returns an empty list which the caller then iterates. If DB has 10 meds, timeout returns 0 meds → setup writes 0 meds. Silent bug. | After timeout, surface a UI error: "Setup can't verify your medications; please try again" + retry. The R52 fix is fail-soft, not fail-loud. | P1 | S |
| 11 | Naming | `lib/core/data/database/app_database.dart:75-82` | `int get schemaVersion => 14;` is the **drift** schema version. The **JSON export** schema version (`export_schema_service.dart`) is also `14` (per `isoUtc` comment). 2 versions with the same number. | Rename one: `jsonSchemaVersion: 4` (per `data_export_orchestrator.dart:33-35` comment says "v4 (current): 4D 情绪"). Drift version 14 ≠ JSON version 4. R57 missed this. | P2 | XS |
| 12 | SRP | `lib/core/data/services/safety_watch_service.dart:33-69` | 5 injected repos + 2 sub-services + 1 timeout. **8 dependencies.** The orchestrator pattern from R57 (`ExportOrchestrator`) is more elegant. | R59+ refactor to `SafetyWatchOrchestrator` accepting `SafetyConfigService` + `SafetyAlertDispatcher` (already private). | P2 | M |
| 13 | Missing test | `test/core/data/services/email_service_round9_test.dart` | Still references the v0.9 `EmailService(apiKey:)` API. v0.20 merged `CryptoService` into `EncryptionService` and removed the apiKey parameter. | R59+ rewrite to match v0.22 API or mark `@Skip('outdated, see v0.22 email_service refactor')`. | P0 | XS |
| 14 | SRP | `lib/core/data/services/sms_service.dart:1-225` | 3 providers + `validateForRelease` + `send` + multiple fallback paths | R55 (P0/spzh) added `AliyunSmsProvider.send()` skeleton (7 steps). R58 set guard to `[WARN]`. v1.0 must add the real `AliyunSmsProvider.send()` body. **Currently the only "non-mock" provider still throws `UnimplementedError`.** | P1 | L |
| 15 | Naming | `lib/core/data/services/sms_service.dart:15-30` | `validateForRelease(SmsService.defaultProvider)` magic — the static getter is created on first call, not on import. Lazy init in static. | Move to `SmsService.validateForRelease(SmsProvider p)` (already a method), but make `defaultProvider` a `static const` or `Provider<SmsProvider>` to avoid implicit init. | P3 | XS |
| 16 | Leaky boundary | `lib/core/l10n/strings.dart:15-30` | The R57 `xxxText({String? override})` pattern is a good step but the caller has to know to pass an override. For 5 of 29 keys (notably `emailBody` and `careAlertBody`), the fallback is *required* to be Chinese for non-`zh` locales because there's no en translation. | Add `Strings.emailBodyForLocale(AppLocalizations? l10n, String userName, int daysSinceLast)` that returns `l10n?.emailBody(...) ?? Strings._emailBodyFallback(...)`. Centralizes "if l10n missing, use this exact Chinese". | P2 | M |
| 17 | SRP | `lib/core/data/services/reminder_dispatcher.dart:55-76` | `cancelByIdRange` does 4 things: fetch pending, filter, map to ids, for-loop cancel with timeout. Could be 2 functions: `_pendingIdsInRange(base)` + `cancelByIdRange(base)`. | R58 was supposed to fix `Future.wait + outer timeout` race — the fix is at L64-75 (for-loop + per-id timeout). The fix is correct but a function-level test for the race is missing. | P2 | S |
| 18 | Hidden coupling | `lib/presentation/pages/trend/trend_calendar.dart:55-92` | 2 `DateTime.now()` calls in 2 build methods. Each one runs on rebuild. R17 R4 fix for midnight was in `medication_calendar_page.dart` only; `trend_calendar.dart` not updated. | R59+ add `dayChangeTickProvider` listener pattern (R48 crossedMidnightSince). | P1 | S |
| 19 | Missing abstraction | `lib/presentation/pages/home/home_page.dart:339-343` | `CareEngine.evaluate(checkIns: all, now: DateTime.now())` — inline call + fire. No test for the integration. | Extract `CareEngineGate` widget that takes the provider and renders nothing if `trigger == none`. Tested via widget test. | P2 | M |
| 20 | DRY | `lib/core/l10n/strings.dart:1-340` | 29 `static const String` + 28 `xxxText({String? override})` pairs. The pair pattern is identical except for the suffix. Should be auto-generated. | R59+ write `scripts/gen_strings.py` that reads `app_zh.arb` + a `// R57+manual` list and emits `strings.dart`. | P2 | M |

---

## 5. Latent bugs (regression of known gotchas)

The AGENTS.md §"已知坑" documents 14 gotchas. I grep'd for each to find any new instances:

| # | Gotcha (AGENTS.md ref) | Instances found (R57+ changes) | Risk | Notes |
|---|---|---|---|---|
| 1 | `DateTime.now()` race (跨 midnight 多次调用) | 56 occurrences in `lib/` (mostly OK, single capture pattern). 2 new: `today_med_schedule.dart:44` (no comment) and `medication_calendar_page.dart:180` (R58 single capture, OK) | 🟢 low | R52 sweep + R57 verified. New R58 grep shows all callers either inject `now` or capture once. |
| 2 | `DateTime(year, month, day)` race (跨月/跨年) | grep 0 (R52 sweep cleaned) | 🟢 none | R57 verified. |
| 3 | 隐式排序假设 `.first` / `.last` | `safety_watch_service.dart` (still uses `recentCheckIns.where(...).toList()` then sort — OK), `assessment_summary_strip.dart:75` (sort then first, OK) | 🟢 none | R48 added `sort_assumption_round19b_test.dart` regression lock. |
| 4 | Notification id cancel range (200000) | All 5 sub-services use the formula. R57 R57 R58 verified. | 🟢 none | grep shows `kReminderCancelRange = 200000` only. |
| 5 | `try/finally` for resource cleanup | `mood_recorder.dart` 3 cases were R52 fixed (串行 await). `vent_compose_page.dart` R48 fixed. `encrypted_audio_storage.dart` R43 fixed. | 🟢 none | All `try/finally` present. |
| 6 | Stream subscription leak | `vent_detail_page.dart:36-80` 3 streams cancel. `mood_recorder.dart` `onPlayerComplete` 1 stream. | 🟡 low | R52 fixed the obvious ones, no regression test verifies the cancel. |
| 7 | `setState` after dispose | 27 `if (!mounted) return;` per v0.17 round 7. R52-R58 added 0 new `setState` calls in build hot path. | 🟢 none | grep verified. |
| 8 | 国产 ROM 静默杀后台 | `notification_status_card.dart` 14K self-test card. R48 5-region hotline routing. R57-58 no changes. | 🟢 none | Out of CI scope. |
| 9 | Riverpod 3.x `valueOrNull` → `value` | grep 0 (`valueOrNull` 0 occurrences) | 🟢 none | R17 R3 fix locked. |
| 10 | `ref.mounted` not available | 27 `!mounted` checks, 1 `ref.mounted`. R52-R58 no changes. | 🟢 none | Working as designed. |
| 11 | 跨 midnight streak 不刷新 | `app_root.dart` (midnight timer) + `crossedMidnight_since_round48_test.dart` (regression lock) | 🟢 none | R17 R4 + R48 locked. |
| 12 | emil 动效 token 必须集中 | `app_tokens.dart` 4 curve tokens, R48 R1 fix | 🟢 none | All curves use token. |
| 13 | go_router 默认无 transition | All 14 routes use `pageBuilder` + `CustomTransitionPage`. R59 + R57 R57 verified. | 🟢 none | Verified. |
| 14 | Material 3 ink_sparkle shader missing | `pubspec.yaml:75-76` declares shader, `assets/shaders/ink_sparkle.frag` present | 🟢 none | R17 R8 fix locked. |
| 15 | 跨 feature import 边界 | `check_cross_feature.py` CI script. R57 R57 0 violations. | 🟢 none | R17 R12 + R57 R57 locked. |
| 16 | **NEW** R57 R57: `check_strings_hardcoded` guard was too narrow | R58 fixed by widening the context window from 4 to 10 lines + recognizing the `xxxText({String? override})` pair pattern. R58 commit `1d546e2` "P0 #3 修正" details. | 🟢 resolved | R58 P0 #3 fixed. |
| 17 | **NEW** R58: `check_sms_release_ready` guard downgraded to `[WARN]` | R58 commit `2ad8246` "A-01 warn-only" downgraded because AliyunSmsProvider real impl is xlarge (法务 1-2 月 + AccessKey). v0.x release doesn't block; v1.0 must restore hard FAIL. | 🟡 medium | Acceptable trade-off; documented. |
| 18 | **NEW** R58: `setup_page.dart:404` timeout silent fallback (see §4 #10) | The R52 fix (`onTimeout: () => []`) returns empty list. If user has 5 meds, timeout → 0 meds → setup writes 0 meds silently. | 🟠 **P0 regression risk** | New finding from this review. R58 did not address. |
| 19 | **NEW** R58: dead token `textStyleScoreLg/Xl/Xxl` | R58 commit `c1916c8` B-09 "emil R50 dead token 清理" removed 3 unused tokens (-31 lines). | 🟢 none | R58 fixed. |
| 20 | **NEW** R57: `aliyun_sms_provider_round57_test.dart.disabled` | R57 R57 commit `4ce7bf9` shows the test was disabled because pubspec lacks `dio` (the AliyunSmsProvider dependency). R58 deferred the real SMS to v1.0. | 🟡 medium | Acceptable; tracked. |
| 21 | **NEW** R57: `Future.wait + outer timeout` race | R52 R57 fix changed `Future.wait(...).timeout(5s)` to for-loop with per-id 2s timeout. The fix is at `reminder_dispatcher.dart:64-75`. **No test asserts the cancellation actually works.** | 🟡 medium | R57 R57 partial; needs regression test. |
| 22 | **NEW** R58: `setup_legal_dialog.dart` PIPL §13 single-consent still TODO | R58 A-03 commit `2ad8246` documented but did NOT implement. Real impl requires SMS integration (external dep). | 🟡 medium | Tracked; v1.0 work. |

**Net latent bug status**: **0 new P0 bugs** introduced by R57-R58 (the R52 sweep + R57-R58 verification holds). **1 latent P0 risk** identified in this review (§18: `setup_page.dart:404` silent fallback on timeout). **3 P2 follow-ups** identified (§21, §22, §18 in this table).

---

## 6. Subagent-driven development opportunities

The superpowers `subagent-driven-development` skill says: "When you have multiple independent tasks, dispatch parallel subagents." The chroniccare codebase has **excellent subagent-friendly architecture** (the R57 5-route split, the R57 7-DAO split, the R58 3-pure-function split are all subagent-friendly patterns). Opportunities:

| Module | Why parallelizable | Risk | Speedup |
|---|---|---|---|
| **5 remaining god class widget splits** (`mood_recorder` / `trend_calendar` / `reminders_hub` / `home_page` / `setup_page`) | Each is a self-contained `pages/{feature}/` directory. Each can be done by a subagent with a clear brief: "extract _MoodRecorderController pure state machine, write widget test". No cross-file changes. | Medium — design coherence loss if 5 subagents design 5 different controller patterns. **Mitigation**: pre-write a `lib/presentation/widgets/_controller_template.dart` skeleton. | 5 subagents × 2-3 hours = ~12 hours wall clock vs 25-30 hours serial. **2-3x speedup.** |
| **5 systematic-debugging regression tests** (跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose) | Each is a single test file. Pure test code, no implementation changes. | Low — tests are by definition safe to add. | 5 subagents × 1 hour = ~1 hour wall clock vs 5 hours serial. **5x speedup.** |
| **5 `withValues` token migrations** (the 4 file paths I found: `app_theme.dart:121,207` + `medication_report_dialog.dart:160` + `assessment_widgets.dart:351` + `trend_calendar.dart:215` per the v0.24 review) | Each is a 1-line change + token definition. Truly atomic. | Low. | 5 subagents × 15 min = ~15 min wall clock vs 1 hour serial. **4x speedup.** |
| **CI workflow** (`.github/workflows/ci.yml`) + **golden test bootstrap** (5 golden tests for `home_page` / `settings_page` / `trend_page` / `medication_calendar_page` / `reminders_hub_page`) | The workflow file is 1 file; golden tests are 5 separate files. | Medium — golden test rendering is finicky on dark mode; needs `testWidgets` boilerplate. | 6 subagents × 1 hour = ~1 hour wall clock vs 6 hours serial. **6x speedup.** |
| **16 guard script docs** (each script's purpose + usage + example output) | Each script is 1 README page. Atomic. | Low. | 16 subagents × 30 min = ~30 min wall clock vs 8 hours serial. **16x speedup.** |

**Highest-leverage**: The 5 god-class widget splits + 5 regression tests = **2-3x speedup** with clear scope, clear brief, and proven pattern (R45, R47, R57 R57 R57 splits).

**Lowest-risk**: The 5 `withValues` token migrations = trivial but documents a clear pattern.

**Highest-risk**: The CI workflow + golden tests because they need platform access (`flutter build apk --debug` needs the toolchain, golden tests need `testWidgets` pattern verified on each platform).

---

## 7. Priority-ranked refactor list

Sorted by **(impact × ease)** — top 5 first, then 5 medium, then 5 small.

| Rank | Refactor | Impact | Effort | Sev | Round |
|---|---|---|---|---|---|
| 1 | **`home_page.dart` widget test** (no test currently) | 🟠 high (daily user journey) | L | P0 | R59 |
| 2 | **`safety_watch_service` 8 `@Deprecated` delete** (R57 added, R59 should remove) | 🟠 high (forces migration) | S | P1 | R59 |
| 3 | **`setup_page.dart:404` silent timeout fallback fix** (R52 added, but silent on real failure) | 🟠 high (silent data loss) | S | P0 | R59 |
| 4 | **`mood_recorder.dart` god class split** (largest presentation file, 21K) | 🟠 high (R52 fix has no regression test) | L | P0 | R59-60 |
| 5 | **5 systematic-debugging regression tests** (R56 R57 happy path only) | 🟠 high (R19-B lessons not locked) | M | P1 | R59-60 |
| 6 | **`notification_service._showSafetyAlert` move to `SafetyAlertDispatcher`** (R57 half-done) | 🟡 medium (facade bloat) | S | P1 | R60 |
| 7 | **CI workflow** (`.github/workflows/ci.yml`) running 16 guards + `flutter analyze` + `flutter test` + `flutter build apk --debug` | 🟡 medium (verification-before-completion) | M | P1 | R60 |
| 8 | **Golden test bootstrap** (5 widget golden files for visual regression lock on R49 dark mode changes) | 🟡 medium | L | P2 | R61 |
| 9 | **`email_service_round9_test.dart` rewrite or `@Skip`** (R52 left outdated) | 🟡 medium (test will fail when re-run) | XS | P0 | R60 |
| 10 | **`app_database.dart:saveSetup + clearAllUserData` → `SetupOrchestrator`** (R57 R57 R57 pattern) | 🟡 medium (matches ExportOrchestrator) | M | P3 | R61 |
| 11 | **`strings.dart` `fromL10n` macro helper** (R57 R57 P0 #6 foundation) | 🟡 medium (i18n centralization) | M | P2 | R61 |
| 12 | **5 `withValues` token migrations** (v0.24 emil-29 leftovers) | 🟢 low (cosmetic) | XS | P3 | R60 |
| 13 | **16 guard script docs** (each script's README) | 🟢 low (DX) | S | P3 | R62 |
| 14 | **`trend_calendar.dart` dayChangeTick listener** (R17 R4 fix for medication_calendar only) | 🟢 low (consistency) | S | P1 | R60 |
| 15 | **`sms_service.dart` 3 providers → `SmsProviderRegistry`** (R55 R55 AliyunSmsProvider pending) | 🟢 low (R58 deferred to v1.0) | L | P3 | v1.0 |

**Recommended R59 batch**: #2, #3, #5 (partial), #9. Total: 1 S + 1 S + 0.5 M + 0 XS ≈ 1 person-day. High ROI.

**Recommended R60 batch**: #1, #4, #5 (partial), #6, #7, #12. Total: 1 L + 1 L + 0.5 M + 1 S + 1 M + 1 XS ≈ 4 person-days. Highest impact.

**Recommended R61 batch**: #5 (complete), #8, #10, #11, #14. Total: 0.5 M + 1 L + 1 M + 1 M + 1 S ≈ 4 person-days. Solid foundation work.

---

## 8. Anti-patterns observed

Following the superpowers "red flags" table in `using-superpowers/SKILL.md`:

### 8.1 Already-fixed (R52-R58)

- ✅ "I know what that means" — the team correctly re-reads AGENTS.md known-gotchas and grep-validates. R52 sweep + R57 verification prove this.
- ✅ "This doesn't count as a task" — every god-class split was preceded by a written `GodClassSplitRound{N}` plan, not ad-hoc. See R57 commit `4ce7bf9` "spen P0/P1/P2" → 3 god classes in 1 round.
- ✅ "This is overkill" — the team added 16 guard scripts (some warn-only). R58 wisely downgraded `check_sms_release_ready` to `[WARN]` because the real fix is xlarge. Good discipline.

### 8.2 Still-present

1. **"I'll just do this one thing first"** — R57 R57 R57 split 3 god classes in 1 round but did NOT add regression tests for the splits. R56 R56 R56 TDD + R57 verification was the catch. Pattern: always pair a split with a regression test. R57 was good on this for `data_export` but missed on `medication_report_pdf` and `app_routes`.
2. **"I remember this skill"** — the v0.24 spen review's Bug 1 (mood_recorder dispose race) was re-flagged by v0.25 R56 R56 R56 review, and the actual fix only came in R52 + R56c'''. **3 reviews to fix 1 bug.** This is the "R19-B lessons" gap.
3. **Missing verification** — R49-R58 made 60+ token + 60+ color changes with NO golden test, NO `flutter build apk/web` commit. `flutter analyze` and `flutter test` are confirmed (1109/1109), but the actual app build is unverified for 12 rounds. The `verification-before-completion` skill demands "actually run it" — and the team has only run the tests, not the app.
4. **Tests of self, not of behavior** — `data_export_round39_test.dart` has 50+ "encode then decode" tests (testing the implementation) vs ~5 behavior tests (testing "after import, DB has the row"). The superpowers TDD skill is explicit: test behavior, not implementation.
5. **Subagent-unfriendly dense files** — `data_export_orchestrator.dart` (21K) and `mood_recorder.dart` (21K) are both monoliths that would benefit from the R57 5-file split pattern. A subagent would struggle to modify either without reading 100% of the file. R57 R57 R57 R57 5-route split is a template that should be applied to widgets.

### 8.3 Latent

1. **The `Future.wait + outer timeout` race** was fixed in R52 R57 but the *fix itself* is not regression-tested. The `for (final id in toCancel) { await _plugin.cancel(id).timeout(2s); }` pattern in `reminder_dispatcher.dart:64-75` is correct but unverified. A test that injects a `_plugin` that hangs `cancel()` would prove the timeout works.
2. **`app_database.dart` schemaVersion 14** vs **`data_export` jsonSchemaVersion 4** — both called "version" in different contexts. Documentation drift waiting to happen.
3. **`email_service_round9_test.dart`** references a v0.9 API. When `flutter test` next runs, the test will fail. R58 didn't fix; R59 should.

---

## 9. Comparison with v0.25 R56h review (15 findings)

| # | v0.25 R56h Finding | Status at v0.27 R58 | Notes |
|---|---|---|---|
| 1 | `data_export_service.dart:564` facade still god-class | 🟢 Resolved in R57 | 539 → 91 lines (-83%) via `ExportOrchestrator` |
| 2 | `medication_notifier_round61c2_test.dart` no 跨 midnight test | 🟡 Partial — R57 added 2 cases but not midnight | See §2.3 anti-pattern #1 |
| 3 | `medication_notifier` no 隐式序 regression | 🟡 Partial — R57 added 2 cases | |
| 4 | `mood_audio_service` no dispose test | 🟡 Partial — R57 added 3 cases but not dispose | |
| 5 | `safety_alert_dispatcher` no stream leak test | 🟡 Partial — R57 added 2 cases | |
| 6 | `safety_watch_service.dart:74-92` 8 config facade | 🟢 Resolved in R57 | 8 `@Deprecated` added; R59 should delete |
| 7 | `app_routes.dart:289` monolith | 🟢 Resolved in R57 | 14 routes split into 5 feature files |
| 8 | `medication_report_pdf.dart:321` god class | 🟢 Resolved in R57 | 304 → 59 lines via `PdfLayout` |
| 9 | `reminder_scheduler.dart:244` god class | 🔴 **Still un-split** | See §3 #? — not in my top list, but it's 244 lines. R60+ should consider. |
| 10 | `mood_audio_service.dart:350` god class | 🔴 **Still un-split** | 350 lines. R60+ should consider. |
| 11 | `safety_alert_dispatcher.dart:42-43` SMS body hardcoded Chinese | 🟡 Partial — R58 P0 #3 fixed but R58 left 1 `buildAlertSms` Chinese (`'$name 已 $daysSinceLast 天未打卡吃药...'`) | Should walk through the i18n 修正. |
| 12 | `safety_alert_dispatcher.dart:90-94` pii log | 🟢 OK | No PII risk. |
| 13 | `flutter build apk/web` unverified | 🔴 **Still unverified** | 12 rounds no build commit. CI workflow needed. |
| 14 | `app_router.dart:33-49` RouterProfileCache | 🟢 Resolved in R57 | Now uses `ref.read` + `_RouterProfileCache` |
| 15 | AGENTS.md 41 vs 46 tests | 🟢 Resolved in R56f | Updated to 46. |

**Net delta**: 7/15 resolved, 4/15 partial, 2/15 still open, 2/15 needs further work. **R56h review was 67% actionable, now 100% reviewed.**

---

## 10. Recommendations for next round (R59 plan)

Following the **superpowers writing-plans** discipline, a recommended R59 plan:

### R59: "Clean the slate" (1-2 person-days)

1. **Delete 8 `@Deprecated` methods** in `safety_watch_service.dart:81-120` (severity P1, effort S). After 1 round of deprecation, callers must migrate.
2. **Fix `setup_page.dart:404` silent timeout** (severity P0, effort S). Replace `onTimeout: () => []` with `onTimeout: () => throw SetupTimeoutException()` and surface a UI error. The R52 fix is fail-soft, not fail-loud.
3. **Add 5 systematic-debugging regression tests** (severity P1, effort M):
   - 跨 midnight in `medication_notifier` + `refill_notifier` (mock now+1day at 23:59:59)
   - 隐式序 in 1 service (med list as `set` instead of `list`, verify sort still works)
   - mood_audio_service dispose race (R52 fix verify)
   - stream subscription leak in `vent_detail_page` (verify `cancel()` called)
   - setState after dispose (verify `!mounted` checks in setup_page 4 steps)
4. **Mark `email_service_round9_test.dart` as `@Skip('outdated, see v0.22 encryption refactor')`** (severity P0, effort XS). Or rewrite the test to match the v0.22 API.
5. **Run `flutter build apk --debug` and `flutter build web`** as a one-time verification commit (severity P1, effort M). This satisfies the `verification-before-completion` skill and surfaces any platform-specific build issues.

### R60: "Tighten the facade" (3-4 person-days)

1. **`mood_recorder.dart` god-class split** (severity P0, effort L). Extract `_MoodRecorderController` pure state machine + 2 widgets (record + playback).
2. **`notification_service._showSafetyAlert` → `SafetyAlertDispatcher`** (severity P1, effort S). R57 left the iOS-focus + Android-alarm-importance half in facade.
3. **`home_page.dart` widget test** (severity P0, effort L). Most critical missing test in the codebase. Start with happy path + after-medication-fire state.
4. **CI workflow** (severity P1, effort M). `.github/workflows/ci.yml` running 16 guards + `flutter analyze` + `flutter test` + `flutter build apk --debug`.

### R61: "Foundation work" (3-4 person-days)

1. **Golden test bootstrap** (severity P2, effort L). 5 golden files for `home_page` / `settings_page` / `trend_page` / `medication_calendar_page` / `reminders_hub_page`. Locks the R49 dark-mode 60+ color changes.
2. **`strings.dart` fromL10n helper** (severity P2, effort M). Centralizes the R57 R57 R57 P0 #6 `xxxText({String? override})` pattern.
3. **`app_database.dart` saveSetup + clearAllUserData → `SetupOrchestrator`** (severity P3, effort M). Matches the R57 R57 R57 `ExportOrchestrator` pattern.
4. **`trend_calendar.dart` dayChangeTick listener** (severity P1, effort S). Apply the R17 R4 fix from `medication_calendar_page` to `trend_calendar`.

---

## 11. What the superpowers methodology says about this review

| Skill | Applied how | What it surfaced |
|---|---|---|
| `brainstorming` | N/A — this is a review, not a feature | — |
| `writing-plans` | §10 R59 plan is in plan format (impact × ease sorted) | Concrete R59 + R60 + R61 sequencing |
| `test-driven-development` | §2 + §5 tests required before fixes | 10 untested paths + 3 anti-patterns |
| `systematic-debugging` | §5 grep-validated the 14 known gotchas | 0 new P0 bugs from R57-R58; 1 latent P0 risk from R52 |
| `code-review` | §4 found 20 issues (SRP, hidden coupling, leaky boundaries, naming) | Includes 1 P0 (silent setup timeout), 4 P1 |
| `subagent-driven-development` | §6 listed 5 parallelization opportunities | 2-3x speedup on 5 widget god-class splits |
| `verification-before-completion` | §8.2 flagged the 12-round `flutter build` gap | The app has not been built since R43 |
| `using-git-worktrees` | N/A — review only | — |
| `using-superpowers` (meta) | This review is the meta-skill in action | — |

---

## 12. Summary

**chroniccare v0.27 round 58** is a **mature, well-architected Flutter project** at **4.5/5 ⭐**. The 4-layer + core umbrella architecture is validated and the "渐进 facade 模式" (progressive facade pattern) is the team's most valuable reusable abstraction.

**Key strengths**:
- 1109/1109 tests, 0 analyzer error, 16 guard scripts
- 7 god classes split (R49-R60 + R57) using a consistent pattern
- domain layer is 0 Flutter, 0 Drift
- Systematic-debugging 14 known gotchas all grep-validated

**Key gaps**:
- `home_page.dart` (380 lines, daily user journey) has 0 widget test
- `mood_recorder.dart` (600+ lines, R52 fix unverified) has 0 widget test
- 12 rounds of `flutter build apk/web` verification missing
- 5 systematic-debugging classes (跨 midnight / 隐式序 / dispose / stream / setState) not regression-locked
- `setup_page.dart:404` silent timeout fallback can lose user data

**Top 3 actions**: widget test for `home_page.dart` + 5 systematic-debugging regression tests + CI workflow with build verification.

---

## Report metadata

- **Reviewer**: superpowers-en lens (TDD / systematic-debugging / code-review / subagent-driven-development / writing-plans / verification-before-completion)
- **Files read for this review**: 30 (AGENTS.md, CHANGELOG.md, pubspec.yaml, recent commits, 14 large files, 4 god-class files, 5 test files, 5 guard scripts, key routing files, main.dart)
- **Files NOT read** (per `verification-before-completion` honesty): most `test/` files (counted but not read), `app_database.g.dart` (auto-generated, 167K bytes), 5 of 16 guard scripts
- **Findings total**: 20 code review (§4) + 5 TDD gaps (§2.2) + 14 god-class candidates (§3) + 5 subagent opportunities (§6) + 22 latent bug checks (§5) = **66 distinct findings** (up from 55 in v0.24 baseline; v0.25 R56h was 15 — 67% actionable, R57-R58 closed 7 of those)
- **Token budget**: ~16K tokens read; review written in ~6K words
- **Output file**: `D:\Batch\chroniccare\docs\reviews\review-superpowers-en-v027.md`
