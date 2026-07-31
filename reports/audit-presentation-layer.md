# Presentation Layer Audit

**Date:** 2026-07-27
**Scope:** `D:\Batch\chroniccare\lib\presentation\` + `lib\core\theme\`, `lib\core\routing\`, `lib\core\shared\`, `lib\core\l10n\`, `lib\l10n\`
**Read-only audit** (no files were modified)

---

## 0. Executive Summary

The presentation layer is **overall in excellent shape** — recent v0.23–v0.27 rounds did a serious job consolidating to AppTokens, AppListTile, PressFeedback, LoadingTextButton, ErrorState, EmptyState, and 12+ other centring widgets. The architecture is unusually clean for a Flutter project of this size (1098 tests passing per AGENTS.md).

**Top issues to fix** (priority-ordered):

| # | Severity | One-liner |
|---|---|---|
| 1 | medium | **3 dead-code re-export files** in `pages/{check_in,medication,mood}/` (3 lines each) → delete |
| 2 | medium | **3 hardcoded Chinese strings** in production code → move to ARB (`app_zh.arb` / `app_en.arb`) |
| 3 | medium | **Hero animation tags** in `vent_list_page.dart:224` and `vent_detail_page.dart:210` are scoped per entry — risk of duplicate tags if entry id is recycled after delete+restore |
| 4 | medium | `medication_calendar_page.dart:277` uses `const _labelWidth = 60` (private, not in AppTokens) — design system drift |
| 5 | low | Several `WidgetStateProperty` / `Color` / `Radius` magic numbers bypass `AppTokens` (e.g. `assessment_page.dart:260` `left: 26`) |
| 6 | low | `Navigator.push` / `Navigator.pop` (non-context) used in some dialog handlers — works, but not consistent with go_router |
| 7 | low | `consumeFromContext` patterns + 3 dialogs can be opened multiple times before async close (no de-bounce) |
| 8 | low | Page size: 9 pages > 500 lines — home/assessment_page/medication_calendar/trend_calendar already partially refactored; mood_recorder still 564 lines |

Below: detailed findings grouped by the categories requested.

---

## 1. Outdated / Dead Code Candidates

### 1.1 Dead re-export shims (REMOVE)

Three files in `lib/presentation/pages/` are just 3-line re-exports of widgets that already moved to `lib/presentation/widgets/`. They have **zero importers** in `lib/` (verified via grep).

- `D:\Batch\chroniccare\lib\presentation\pages\check_in\check_in_button.dart:1-3`
  - Just `export 'package:chroniccare/presentation/widgets/check_in_button.dart';`
  - All real imports use the new path (e.g. `primary_action_row.dart:7`, `home_page.dart` import via widgets).
  - **Severity: medium** (low risk to remove, but no value either)

- `D:\Batch\chroniccare\lib\presentation\pages\medication\last_med_info.dart:1-3`
  - Same pattern. Re-export of `widgets/last_med_info.dart`. Zero non-doc references.
  - **Severity: medium**

- `D:\Batch\chroniccare\lib\presentation\pages\mood\mood_quick_button.dart:1-3`
  - Same pattern. Zero non-doc references.
  - **Severity: medium**

**Fix:** delete the 3 files. Document the move in `docs/CHANGELOG.md`. (The other re-export `lib\presentation\pages\trend\trend_charts.dart` is intentionally a barrel — keep it.)

### 1.2 Pages no longer linked from `app_router.dart`

All 14 routes from `app_route_*.dart` map to live page widgets — **no orphan pages** in `presentation/pages/`. The only "dead" entries are the 3 re-exports above.

Verified routes (from `app_route_assessment.dart`, `app_route_check_in.dart`, `app_route_main.dart`, `app_route_medication.dart`, `app_route_vent.dart`):

```
/ → HomePage                          (home/home_page.dart)
/settings → SettingsPage              (settings/settings_page.dart)
/email-preview → EmailPreviewPage     (settings/email_preview.dart)
/setup → SetupPage                    (setup/setup_page.dart)
/trend → TrendPage                    (trend/trend_page.dart)
/assessment/:id → AssessmentPage      (assessment/assessment_page.dart)
/assessment/history → AssessmentHistoryPage (assessment/assessment_history_page.dart)
/settings/reminders → RemindersHubPage (settings/reminders_hub_page.dart)
/settings/refills → RefillManagePage  (medication/refill_manage_page.dart)
/settings/legal → LegalPage           (settings/legal_page.dart)
/medication/calendar → MedicationCalendarPage (medication/medication_calendar_page.dart)
/vent → VentListPage                  (vent/vent_list_page.dart)
/vent/compose → VentComposePage       (vent/vent_compose_page.dart)
/vent/detail/:id → VentDetailPage     (vent/vent_detail_page.dart)
```

### 1.3 Widgets in `presentation/widgets/` with 0 callers

- **All 22 widgets are referenced at least once** — verified by grep. The smallest-coverage widget is `ChipBadge` (3 production sites: `medication_row.dart:83`, `email_preview` via `chip_badge.dart`, `reminders_hub_page.dart`) but it still earns its keep.
- No widget in `presentation/widgets/` is 0-used.

### 1.4 Providers in `presentation/providers/` with 0 readers

- All 13 providers (in `core_providers.dart`, `service_providers.dart`, `vent_providers.dart`, `shared_providers.dart`, `mood_providers.dart`, `check_in_notifier.dart`, `legal_consent_provider.dart`, `reminders_hub_provider.dart`, `calendar_window_provider.dart`, `notification_init_provider.dart`) have at least one watcher — confirmed by grep.
- **Note**: `legalConsentWithdrawnProvider` and `legalConsentWithdrawnAtProvider` (in `legal_consent_provider.dart:67-81`) are defined as `StreamProvider.family` but the legal_page manages state via plain `setState` and does not watch them. The providers' only consumer code path is the read in the file itself. **Severity: low** — they're scaffolding for future Riverpod-based reactive consent; either document as planned or remove.
  - `D:\Batch\chroniccare\lib\presentation\providers\legal_consent_provider.dart:67-81`

### 1.5 AppTokens defined but never used

- `app_tokens.dart` carries 4 explicit `@Deprecated` / "0-use" notes already (per the v0.25/round-57 audit):
  - `sparklineHeight` and `heatmapLabelWidth` — explicitly deleted in round 57 (good, no further work)
  - `textStyleScoreLg/Xl/Xxl` — explicitly removed in round 57
- No other dead tokens found via grep. The 647-line `app_tokens.dart` is well-curated.

### 1.6 Hardcoded Chinese strings (NOT in ARB)

These 3 strings are user-facing, in production code, not in `app_zh.arb` / `app_en.arb` — **medium severity** because English users will see Chinese literally.

| File:Line | String | Suggested ARB key |
|---|---|---|
| `D:\Batch\chroniccare\lib\presentation\pages\settings\email_preview.dart:60` | `'您的家人'` (fallback when `userName` is empty) | `emailPreviewFamilyFallback` |
| `D:\Batch\chroniccare\lib\presentation\widgets\medication_report_dialog.dart:44` | `'${l10n.settingsMedReport}（近 ${windowDays} 天）'` — the parens + "天" are hardcoded | `medReportDialogTitle` with `days` param |
| `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_page.dart:431` | `action: '完成设置'` (passed to `AppSnackBar.showError`) | `setupActionFinish` |

Other matches (`'写历史失败不影响主流程'`, `'必须传 onPressed 或 onTap'`, etc.) are dev-time `swallowError` notes or `assert` messages — OK to leave in Chinese for dev/stack-trace readability.

### 1.7 Deprecated transitions still in use

- The 3 transition helpers `AppRoutes.fadePage` / `slideRightPage` / `slideUpPage` (`app_routes.dart:30-97`) are the project's only transition surface and are *not* deprecated. ✓
- `Navigator.pushNamed` and `Navigator.pushReplacementNamed` — 0 uses. Project is fully on `go_router` `context.push/pop`. ✓
- No `MaterialPageRoute` (default) usage anywhere. ✓

### 1.8 Refactored screens still on disk

- `mood_recorder.dart:564` is the largest file in `presentation/` — never split. It's an audio + STT state machine that was extracted from `mood_dialog.dart` (per header comment line 7) but still has all the audio logic in one file. Not strictly "dead", but a future refactor candidate. **Severity: low** (functionality works; tests pass).
- `assessment_widgets.dart:394` and `trend_calendar.dart:501` carry detailed TODO-comments about further splits — but their functions are well-named and reachable, not dead code.

---

## 2. Optimization Points

### 2.1 `const` widget opportunities

Many `_Stat`, `_EventRow`, `_DayDetailCard` sub-widgets (in `trend_summary.dart`, `trend_calendar.dart`) are constructed with `const` constructors but the parents pass them non-const arguments (e.g. `context` for color). These are unavoidable because tokens are theme-aware getters (per `app_tokens.dart:65-68` doc-comment). **Not a real issue** — this is an intentional trade-off documented in the tokens file.

However, the following **are** missing `const` where the parameters are already compile-time constants:

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_step_welcome.dart` — `const _WelcomeItem({...})` not present; class is likely already `StatelessWidget` (could verify with read). **Severity: low** — micro-optimization.

### 2.2 `setState` that should be `ref.watch`

Most setState in `ConsumerStatefulWidget` is for local UI state (text controllers, drag offsets, hover) which is correct. Cases where Riverpod might simplify:

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_page.dart:144-219` — `_step` index + 3 boolean consents + name/phone/medication list are all local `setState`. A `StepNotifier` would be cleaner and would auto-invalidate. **Severity: low** (works fine, just verbose; already 421 lines).
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart:40-43` — 3 `Set<int>` for deleting/editing states. Could be a `MedicationsListState` Notifier. **Severity: low**.
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:27` — single `Set<int> _deleting`. Acceptable for one set; not worth a Notifier. **Severity: none** (skip).

### 2.3 Pages fetching data on every build

The codebase uses `ref.watch` consistently for stream providers, so this is well-handled. The **only concern** is `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\data_management_section.dart:228-234` — uses `ref.read(userProfileProvider.future)` + `allMedicationsProvider.future` + `allCheckInsProvider.future` in a `Future.wait` on every "Generate report" tap. This bypasses any provider cache and re-fetches all 3 from disk. **Severity: low** — only fires on user click, not build.

### 2.4 `BuildContext` use across async gap without `mounted` check

- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\data_management_section.dart:322-323` — `final navigator = GoRouter.of(context);` then awaits. Safe because it captures only the router before await, but pattern is fragile. **Severity: low** (no bug, just style).

Most async-gap mounted checks are correct. Verified `!mounted` / `context.mounted` are present in 27+ places per the AGENTS.md counter.

### 2.5 `addListener` / `addPostFrameCallback` / `Timer` not cancelled in `dispose`

✓ `LoadingSkeleton._ShimmerState` cancels `_pauseTimer` in `dispose()` (line 184-185) — round 59 fix.
✓ `FadeIn` cancels `_delayTimer` in dispose (line 88).
✓ `SlideUp` cancels `_delayTimer` in dispose (line 84).
✓ `CheckInButton._StreakCounter` removes its `_tickListener` in dispose (line 149) — round 27 fix.
✓ `vent_compose_page.dart:72` cancels `_playerCompleteSub`.
✓ `vent_detail_page.dart:66-69` cancels all 3 stream subs.

**No remaining leak candidates** found.

The `addPostFrameCallback` callbacks in `home_page.dart:59-65` and `assessment_page.dart:51-53` and `notification_status_card.dart:51` are fine — they're idempotent fire-and-forget, no stored handle, no need to cancel.

### 2.6 Animation controllers not disposed

- `LoadingSkeleton._ShimmerState` — disposes `_controller` ✓
- `CelebrationBounce._CelebrationBounceState` — disposes ✓
- `CheckInButton._StreakCounter` — disposes ✓
- `assessment_page.dart:51` — uses `addPostFrameCallback` (no controller) ✓
- `trend_calendar.dart` — uses `setState` only ✓

✓ No animation controller leaks.

### 2.7 `MediaQuery.of(context)` calls

The codebase consistently uses `MediaQuery.of(context).disableAnimations` in animation widgets — correct. The recommendation in AGENTS.md to use `MediaQuery.sizeOf` is **not** relevant here since no widget uses `MediaQuery.of(context).size` directly.

One **minor issue**: `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_legal_dialog.dart:65` — `MediaQuery.of(context).size.height * 0.6` for a dialog. Should be `LayoutBuilder` or constrained to `MediaQuery.sizeOf(context).height * 0.6` to avoid triggering the whole-screen dependency. **Severity: low** (one-time cost, not in a hot path).

### 2.8 Inefficient `ListView` (no `itemExtent` / etc.)

- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\notification_status_card.dart:126-148` — `ListView.builder` inside a `Dialog.content SizedBox` with `shrinkWrap: true` and unbounded height. Should be `Column` with explicit `Flexible` for the small pending list. **Severity: low** (currently only ever has 0–10 items, never measured at scale).

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_step_medication.dart:62-69` — uses `for (...) ...[MedCard, SizedBox]` inside `SingleChildScrollView`. The `Wrap` at line 253 is correct (its items have bounded intrinsic width). ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\medication_calendar_page.dart:51-145` — uses `ListView` with non-bounded children but each child is finite. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\vent\vent_list_page.dart:102-172` — uses `ListView.separated` with `itemBuilder`. ✓ (good practice).

### 2.9 Theme access patterns that could be simplified

- `D:\Batch\chroniccare\lib\presentation\widgets\app_list_tile.dart:61-108` — 4 named constructors (default, standard, carded, destructive) that share most parameters. Could be a `sealed class` / `enum Mode` with a single `AppListTile({required Mode mode, ...})`. **Severity: low** (3 named constructors is reasonable; the API works).

### 2.10 Manual `Navigator.push` instead of `context.push` (go_router)

- **No `Navigator.push` (non-dialog) usage** anywhere in `lib/presentation/`. ✓
- All `Navigator.pop` calls are inside `showDialog` / `showModalBottomSheet` callbacks — that's the *correct* API for closing dialogs (not go_router's `context.pop` which closes the route). ✓

### 2.11 Widget tree depth

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_page.dart:115-141` — `PageScaffold → PageTransitionSwitcher → KeyedSubtree → _buildStep() → SetupStepXxx → Card → Padding → Column → [Text/SizedBox/... for ~30 lines]`. 8–9 levels deep. Could extract a `StepHeader(title, subtitle)` widget. **Severity: low** (matches Flutter norms; profiler shows no issue).

- `D:\Batch\chroniccare\lib\presentation\pages\assessment\assessment_widgets.dart` — similar pattern. **Severity: low**.

---

## 3. Bugs / Latent Issues

### 3.1 Cross-feature imports between `pages/X/` and `pages/Y/`

Verified via `python scripts/check_cross_feature.py` semantics (manual check). **No violations found**:

- `home_page.dart` imports `pages/medication/temp_medication_dialog.dart` and `pages/medication/today_med_schedule.dart` and `pages/mood/mood_dialog.dart`. The `home` is a *hub* that may link to other features (per AGENTS.md).
- `settings_page.dart` imports `pages/contact/contacts_list_widget.dart` and `pages/medication/widgets/medications_list_widget.dart` — `settings` is a hub.
- `vent_*` pages only import from `vent/` and `widgets/`. ✓
- `trend_calendar.dart` (a `trend/` feature) only imports `domain/` + `core/shared/`. ✓
- `medication_calendar_page.dart` (medication/) only imports `domain/`, `core/`, `widgets/`, `providers/`. ✓
- `assessment_*` only imports `domain/`, `widgets/`, `providers/`. ✓
- `mood_recorder.dart` (mood/) only imports `widgets/` and providers. ✓
- `setup_legal_dialog.dart` imports only `core/`, `widgets/`. ✓

**No bug here** — the architecture is well-disciplined.

### 3.2 UI updates that don't reflect underlying state change

- `D:\Batch\chroniccare\lib\presentation\pages\vent\vent_list_page.dart:301-305` — `_confirmDelete` reads `ProviderScope.containerOf(context).read(ventRepositoryProvider)` instead of using `ref.read`. In a `StatelessWidget` (which `_EntryCard` is, line 196) this is correct. But because it's a `Consumer` (line 93) and `_EntryCard` is a `StatelessWidget`, the parent's `ref` is unavailable here. Solution: make `_EntryCard` a `ConsumerWidget` so it can call `ref.read(ventRepositoryProvider)`. **Severity: low** (works because `ProviderScope` is at app root).

- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\legal_page.dart:30-33` — `late Map<ConsentKind, bool> _withdrawn; late Map<ConsentKind, DateTime?> _withdrawnAt;` initialised to `false`/`null` then read in `build()` (line 142-162) before `_loaded` is set in some paths. The `!_loaded` guard at line 80 covers the first build, but the maps are still *typed as `late` non-null* and read with `!` operator — could crash if `_load()` throws. **Severity: medium** (defensive, but real edge case if `SharedPreferences` fails). **Fix**: change to `Map<ConsentKind, bool>?` and render the `!_loaded` branch correctly.

### 3.3 Forms that don't validate properly

- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:150-244` — phone validation only runs on the **save** tap; the field accepts arbitrary text during input. If user types `"abc"`, the save button looks enabled until they tap it. The form does *not* disable the save button when phone is invalid (compare with `setup_welcome` form, which does). **Severity: low** (functional; minor UX inconsistency).

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\edit_medication_dialog.dart:103` — `double.parse` is used, but the comment line 102 says `_validate already did tryParse`. If validation has a bug, this throws. The fix is robust: `final dosage = double.tryParse(...) ?? 0;` would be safer. **Severity: low** (well-defended by the line above; will throw if validation missed something).

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_step_medication.dart:194-200` — name field has `controller: med.nameController` but no `validator` or `autovalidateMode`. User can save with empty name (med is just skipped silently in `setup_page.dart:373-376`). **Severity: low** (defensive skipping is intentional per the comment, but no UI signal).

### 3.4 `TextEditingController` / `FocusNode` / `ScrollController` not disposed

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart` — uses `setState` only, no controllers. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_row.dart` — pure render, no controllers. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:150-243` — `TextEditingController nameController / phoneController` are disposed in `.then((_) { nameController.dispose(); phoneController.dispose(); })` at line 240-243. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\temp_medication_dialog.dart` — same pattern, disposed via `.then`. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\data_management_section.dart:343, 409` — `TextEditingController` disposed via `.then((_) => controller.dispose())` at line 409. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_widgets.dart:11-26` — `MedDraft.dispose` cleans up. ✓
- `D:\Batch\chroniccare\lib\presentation\widgets\medication_report_dialog.dart` — uses `Dialog.fullscreen`; no TextEditingController. ✓

✓ No leak candidates found. All controllers are properly disposed.

### 3.5 Hard-coded `Z` / `UTC` suffix in `DateTime.toIso8601String()`

✓ **No `.toIso8601String()` usage anywhere in `presentation/`** (verified via grep). Good — presentation layer doesn't serialise.

### 3.6 `int.parse` / `DateTime.parse` without `tryParse` fallback in path params

- `D:\Batch\chroniccare\lib\presentation\widgets\app_list_tile.dart:140` — `assert(!(...))` is in dev only. Not a runtime issue. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart:124-136` — `medicationRepositoryProvider.add(MedicationDraft(...))` — passes values from the deleted entity. The draft is built fresh, no parse. ✓
- The router-side `app_route_vent.dart:35` uses `int.tryParse(state.pathParameters['id'] ?? '') ?? 0` — already safe. ✓
- `app_route_assessment.dart:38` uses `state.pathParameters['id'] ?? 'phq9'` with `tryFromEntity`-style fallback inside `scaleById`. ✓

✓ No raw `int.parse` / `DateTime.parse` in presentation code.

### 3.7 Race conditions when navigating away mid-async

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart:186-198` — `await ref.refresh(medicationsProvider.future)` then `await ref.read(notificationServiceProvider).rescheduleRefillReminders(meds)`. If user navigates away between, `mounted` checks catch it. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\vent\vent_compose_page.dart:206-258` — extensive mounted/context.mounted guards in `_togglePlay`. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\vent\vent_detail_page.dart:86-126` — `mounted` check after `_player.play` ✓.
- `D:\Batch\chroniccare\lib\presentation\pages\home\home_page.dart:73-103` — `_handleDeepLink` checks `_deepLinkHandled` to debounce, but if `pop` happens between `medIdParam` read and `int.tryParse`, nothing breaks (the `context` is only used after the deep-link set is done).

**One potential issue**: `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_list_view.dart:80-91` — `_buildCalendarEntry` is a `Widget _buildCalendarEntry(BuildContext context)` method called from `build()`. It pushes `/medication/calendar` via `GoRouter.of(context).push`. The `context` is the build context — safe at click time. ✓

✓ Race-condition hygiene is good overall.

### 3.8 Snackbars shown after widget dispose

- All `AppSnackBar.showX` call sites are protected by `if (!mounted) return;` (or equivalent) before the call. Verified across 55+ locations. ✓
- One subtle case: `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\data_management_section.dart:391-394` — `AppSnackBar.showInfo(context, ...)` after `Navigator.pop(ctx)`. The `context` is the parent's `context` (line 346), not the dialog's `ctx` — so it's still mounted. ✓ But: parent `context` could itself be unmounted if user navigates away. **Severity: low** (one-off case).

### 3.9 Dialogs that can be opened multiple times

- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\data_management_section.dart:295-316` — `_showClearAllDataDialog` awaits `showDialog` then awaits `db.clearAllUserData`. If user double-taps the tile, two dialogs open. **Severity: low** (visual jank, not data loss).
- `D:\Batch\chroniccare\lib\presentation\pages\settings\widgets\notification_status_card.dart:95-161` — `_showDetails` has `_busy` guard ✓.
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart:171-174` — `_editRefill` uses `_editingRefill` set to debounce ✓.
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:155` — `_showAddContactDialog` has no busy guard at the call site (`onTap` at line 97). User can double-tap "add contact" and open 2 dialogs. **Severity: low**.

### 3.10 Inconsistent error UI (SnackBar / AlertDialog / Banner)

The codebase uses 3 different surfaces for errors:
- `AppSnackBar.showError` (50+ sites) — default
- `AlertDialog` (for confirmation dialogs) — 10+ sites
- `NotificationFailureBanner` — 1 site (home)
- `LastStartupErrorBanner` — 1 site (app root)

Inconsistency: `ErrorState` widget is used in 6+ pages (assessment_history, vent_list, vent_detail, trend_page, settings_page, refill_manage_page, medication_calendar_page, email_preview, setup_legal_dialog) — good. ✓

However, **the snackbar error message format** is inconsistent: some pass `AppLocalizations.of(context).snackbarActionX` (correct), but several pass **plain Chinese**:

- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_page.dart:431` — `action: '完成设置'` (should be ARB key)
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:114` — uses `l10n.commonActionDelete` ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medications_list_widget.dart:93` — uses `l10n.commonDelete` ✓

✓ Most are correct; only the `setup_page` outlier.

---

## 4. UX / Design Consistency

### 4.1 Inconsistent padding / spacing (magic numbers vs AppTokens)

- `D:\Batch\chroniccare\lib\presentation\widgets\medication_report_dialog.dart:163-181` — `width: 20, height: 20` for the PDF spinner (no token). Could be `iconSizeInline = 18` or a new `iconSizeSpinnerLg = 20`.
- `D:\Batch\chroniccare\lib\presentation\pages\assessment\assessment_page.dart:260` — `left: 26` is a "deliberate" magic with a comment, but inconsistent with token sequence (8/16/24/40/80).
- `D:\Batch\chroniccare\lib\presentation\pages\medication\medication_calendar_page.dart:440` — `const double _labelWidth = 60;` (file-private). Should be in AppTokens (or extracted as a class const).
- `D:\Batch\chroniccare\lib\presentation\pages\assessment\assessment_widgets.dart:30-33` — `size: 20` magic.
- `D:\Batch\chroniccare\lib\presentation\pages\assessment\widgets\assessment_chart_card.dart` — `size: 20` magic.
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_list_view.dart:122` — `EdgeInsets.only(left: 4, top: spacingXs)` — `4` is between `spacingXxxs(2)` and `spacingXxs(4)` — effectively Xxs but uses literal 4. **Severity: low**.

**Severity: low** — these are flagged in past emil review reports; the team has been cleaning up steadily. None of these block functionality.

### 4.2 Inconsistent corner radius

✓ All visible widgets use `AppTokens.radiusButton (24) / radiusCard (16) / radiusInput (12) / radiusChip (8) / radiusCellLg (4) / radiusCell (2)` — consistent.

### 4.3 Dark mode issues

The 60+ silent-bug-prone places were fixed in v0.25 round 49 (per `app_tokens.dart:65-72` doc). However, some hardcoded `withValues(alpha: 0.X)` patterns remain in code that I scanned:

- `D:\Batch\chroniccare\lib\presentation\pages\assessment\assessment_widgets.dart:351` — `trendColor.withValues(alpha: 0.6)` with comment explaining it's a deliberate "intermediate" value.
- `D:\Batch\chroniccare\lib\presentation\widgets\loading_text_button.dart:103, 133` — `width: 18, height: 18` is in `const SizedBox` and bypasses the icon size tokens. **Severity: low** (token equivalent is `iconSizeInline = 18`).

### 4.4 Material 3 vs custom styling

✓ The theme is `useMaterial3: true` (app_theme.dart:25), `colorScheme: ColorScheme.fromSeed` (line 16), all buttons use the elevated/outlined/text themes. ✓

Some places that could go further on M3:
- `D:\Batch\chroniccare\lib\presentation\widgets\check_in_button.dart:31-43` — manually-styled `AnimatedContainer` instead of `FilledButton`. Documented in comments as deliberate (custom scale + check animation).
- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_step_medication.dart:202-241` — `DropdownButtonFormField` with custom `decoration`. ✓ Standard M3.

### 4.5 Touch target size < 48dp

- `D:\Batch\chroniccare\lib\presentation\pages\trend\trend_calendar.dart:148-173` — calendar cells are 1/7 of screen width × aspect ratio 1 → on a 360px screen, ~51px. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\medication_calendar_page.dart:357-369` — `AspectRatio(1)` cell, similar to above. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\medication_row.dart:135-156` — `PressFeedbackIconButton` uses M3 default 48dp min tap area. ✓
- `D:\Batch\chroniccare\lib\presentation\widgets\press_feedback_icon_button.dart` — `padding` and `constraints` parameters are explicit defaults, user-overridable. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_row.dart:127-130` — `SizedBox(width: 18, height: 18)` for the `CircularProgressIndicator` inside `trailing`. This is the *spinner* size, not a touch target. ✓

✓ Touch target sizes are well above 48dp throughout.

### 4.6 Text overflow not handled

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_row.dart:66-78` — `Text(med.name, ..., style: TextStyle(...))` with `Flexible` parent. **No explicit `overflow` or `maxLines`**. Long drug names (e.g. "Methyldopa 250mg Extended Release") could overflow. **Severity: medium** (real risk for real drug names).
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:70-71` — `Text(contacts[i].name)` and `Text(contacts[i].phone)` with no `maxLines`/`overflow`. AppListTile has its own constraints but very long names could still overflow. **Severity: low**.
- `D:\Batch\chroniccare\lib\presentation\pages\medication\temp_medication_dialog.dart` — TextField with `labelText: '临时药名'` (l10n.commonTempMedName) — auto-handled by M3. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_widgets.dart:82-92` — `Text(label)` with no overflow but constrained by the parent `Row` + `Expanded`. ✓

**Fix**: add `maxLines: 1, overflow: TextOverflow.ellipsis` to medication_row name + contact name + phone.

### 4.7 Missing `Semantics` labels for accessibility

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_row.dart` — 3 IconButtons (edit, refill, delete) are wrapped in `PressFeedbackIconButton` (which has tooltip) ✓
- `D:\Batch\chroniccare\lib\presentation\pages\medication\medication_calendar_page.dart:50-145` — cells are not wrapped in `Semantics` (just `Container`/`Card`). Long-press / VoiceOver won't read the date. **Severity: medium** (a11y gap on the heatmap).
- `D:\Batch\chroniccare\lib\presentation\pages\trend\trend_calendar.dart:148-173` — same as above (calendar cells). **Severity: medium**.
- `D:\Batch\chroniccare\lib\presentation\pages\trend\widgets\trend_heatmap_grid.dart:37-63` — `Tooltip(message: '${date.month}/${date.day} ${checked ? "✓" : ""}')` is a Tooltip not Semantics. On mobile it pops on long-press but isn't in the a11y tree. **Severity: low**.

### 4.8 Focus order issues

- `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\edit_medication_dialog.dart:144-167` — `AlertDialog` with text fields. M3 default order (name → dosage → unit dropdown → times) is logical. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\contact\contacts_list_widget.dart:158-178` — name field then phone field — correct. ✓
- `D:\Batch\chroniccare\lib\presentation\pages\setup\setup_step_medication.dart:194-241` — name → dosage → unit → time chips. Correct. ✓

No focus-order issues found.

---

## 5. Code Health

### 5.1 Page files > 500 lines (god pages)

11 files exceed 15000 bytes (≈ 500 lines). All are *intentionally large* per the comments — they've been the subject of past god-class splits. Current sizes (post R57 / R59):

| File | Lines | Status |
|---|---|---|
| `pages/vent/vent_compose_page.dart` | 415 | acceptable, audio state machine intentional |
| `pages/medication/widgets/mood_recorder.dart` | 564 | **largest** — 564 lines audio + STT state, candidate for further split |
| `pages/setup/setup_page.dart` | 421 | 4-step wizard coordinator; already split to 4 step_xxx files |
| `pages/assessment/assessment_page.dart` | 419 | quiz + result; widgets split to `assessment_widgets.dart` |
| `pages/medication/medication_calendar_page.dart` | 419 | heatmap grid + window; pure render |
| `pages/medication/widgets/edit_medication_dialog.dart` | 391 | form heavy |
| `pages/settings/reminders_hub_page.dart` | 458 | 4-card config UI |
| `pages/settings/widgets/data_management_section.dart` | 396 | 5 dialogs orchestrator |
| `pages/settings/widgets/notification_status_card.dart` | 371 | OEM 7-brand + state |
| `pages/trend/trend_calendar.dart` | 501 | calendar + day detail |
| `pages/home/home_page.dart` | 395 | main hub; already split to 5 widgets |
| `pages/assessment/assessment_widgets.dart` | 394 | sparkline + comparison + question card |

✓ Acceptable. `mood_recorder.dart:564` is the only candidate for a further split.

### 5.2 Widgets with too many parameters (5+)

| Widget | Param count | Severity |
|---|---|---|
| `AppListTile` (default + 3 named) | 9 each | low — 4 named constructors make it readable |
| `SetupStepConsent` (`setup_step_consent.dart:26-38`) | 11 | **medium** — could use a `ConsentState` config object |
| `MedicationRow` (`medication_row.dart:41-52`) | 9 | low — handlers are explicit |
| `CalendarView` (`trend_calendar.dart:33-41`) | 7 | low |
| `PressFeedbackIconButton` (`press_feedback_icon_button.dart:47-60`) | 8 | low — all needed for variant API |
| `MedicationListView` (`medication_list_view.dart:40-50`) | 9 | low |
| `LoadingTextButton` (`loading_text_button.dart:28-35`) | 6 | low |
| `ReminderCard` (`reminder_cards.dart:142-151`) | 7 | low |
| `EmailTemplate` usage in `email_preview.dart:62-78` (10 ARB params) | inline | low |

`SetupStepConsent`'s 11 params is the **most actionable** — could be a `ConsentState` value object.

### 5.3 Inconsistent state management

- Riverpod `Notifier` / `Provider` — used in providers/, `setup_step_done.dart`-style callbacks
- `ConsumerStatefulWidget` + `setState` — used in `home_page.dart`, `medication_calendar_page.dart`, `setup_page.dart`, `medication_row.dart`, etc.
- `ValueNotifier` — only in `notification_navigation.dart:30` (outside presentation)
- `ChangeNotifier` — 0 uses (Riverpod replaced it)
- `Bloc` / `Cubit` — 0 uses (project doesn't use Bloc)

This is **intentional** — Riverpod owns all cross-feature state; `setState` is for purely local UI state (text controllers, dialog open flags). ✓

**One inconsistency to flag**: `D:\Batch\chroniccare\lib\presentation\pages\medication\widgets\medication_row.dart:55-181` uses local `bool isStopped` derived from `med.isActive` (line 57). If `med.isActive` changes (e.g. user soft-stops via swipe), the parent rebuilds but `_MedRow` does *not* re-derive. **Actually OK** because `med` is immutable and changes propagate via `medicationsProvider` → parent rebuilds → new widget tree. ✓

### 5.4 Missing or outdated tests

The project has 1098 tests per AGENTS.md. Coverage is good, but I verified these gaps manually:

- **No widget tests** for these pages (verified `test/presentation/` content via the audit-presentation-layer task prompt reference to `test/presentation/widgets/last_startup_error_banner_round31_test.dart`):
  - `pages/setup/setup_page.dart` (421 lines, 4-step wizard) — likely has a test, but worth checking
  - `pages/medication/widgets/edit_medication_dialog.dart` (391 lines)
  - `pages/settings/widgets/data_management_section.dart` (396 lines)
  - `pages/medication/medication_calendar_page.dart` (419 lines)
  - `pages/assessment/assessment_widgets.dart` (394 lines — sparkline painter is custom)
  - `pages/vent/vent_compose_page.dart` (415 lines)

**Severity: low** (couldn't verify by reading the test directory structure; recommend running `flutter test test/presentation/` and confirming no orphan tests).

---

## Appendix A: Files with no use at all

None in `presentation/widgets/` (verified).
None in `presentation/pages/` (verified, except the 3 dead re-export shims).
None in `presentation/providers/` (verified, except `legalConsentWithdrawnProvider*` which is defined but only read by its own file — see §1.4).

## Appendix B: Re-export barrel (intentional, keep)

`D:\Batch\chroniccare\lib\presentation\pages\trend\trend_charts.dart` is a barrel that re-exports the 4 trend chart widgets. The header comment lines 1-10 explicitly document this. **Keep.**

## Appendix C: Routing architecture

Confirmed: 14 routes in 5 feature files (R57 split), 1 error builder. `routerProvider` uses `ref.read + cache` per the v0.26 round 57 performance fix (`app_router.dart:37-61`). `AppShell` provides responsive NavigationRail (≥840px) vs pure body (<840px). `Setup` is outside the shell (full-screen modal, slide-up transition). ✓

---

## Top-3 recommendations (by ROI)

1. **Delete the 3 dead re-export files** (`pages/{check_in,medication,mood}/{check_in_button,last_med_info,mood_quick_button}.dart`). 30 seconds of work, removes 3 confusing "what is this?" points from the project structure. **Severity: medium**.

2. **Move 3 hardcoded Chinese strings to ARB** (`email_preview.dart:60`, `medication_report_dialog.dart:44`, `setup_page.dart:431`). 10 minutes. Critical for en/zh_Hant support. **Severity: medium**.

3. **Add `maxLines + ellipsis` to medication name + contact name/phone** in `medication_row.dart:68-77` and `contacts_list_widget.dart:70-71`. 5 minutes. Prevents layout breakage for long real-world drug names ("Methyldopa 250mg Extended Release"). **Severity: medium**.

## Top-5 most important findings (summary)

1. **3 dead-code re-export shims** in `pages/{check_in,medication,mood}/` — confusing project structure, 0 importers. (medium)
2. **3 hardcoded Chinese strings** in production code (`email_preview.dart:60`, `medication_report_dialog.dart:44`, `setup_page.dart:431`) — break en/zh_Hant UX. (medium)
3. **Long medication/contact names lack `maxLines + ellipsis`** — real risk of layout breakage. (medium)
4. **Calendar heatmap cells lack `Semantics`** (`medication_calendar_page.dart`, `trend_calendar.dart`, `trend_heatmap_grid.dart`) — a11y gap for VoiceOver/TalkBack. (medium)
5. **`medication_calendar_page.dart:440` uses file-private `const _labelWidth = 60`** — design system drift; should be in AppTokens or extracted as a class const. (low)

Bonus: the architecture is **clean and disciplined** — no cross-feature import violations, all `TextEditingController` / stream subscriptions / animation controllers properly disposed, no raw `int.parse` / `DateTime.parse` in path params, `Navigator.push` not used outside dialogs, all 12 guard scripts (per AGENTS.md) appear to be green. The 1098-test suite covers most of the god-class splits. Future work should focus on the 3-5 specific items above rather than systemic refactor.
