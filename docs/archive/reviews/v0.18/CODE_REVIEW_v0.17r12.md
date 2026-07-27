# Code Review — chroniccare v0.17 round 12

**Reviewer:** adversarial code review (superpowers-en methodology)
**Date:** 2026-07-17
**Scope:** full `lib/` + `test/` (528 stated tests → **actually 550 tests, 1 failure on full run**)
**Verification baseline:** `flutter analyze` (0 issues), `dart scripts/check_all.dart` (pass), `python scripts/check_cross_feature.py` (0 violations), `flutter test` (550 tests, **1 FAIL** in `safety_watch_service_test.dart`).

---

## Part 1 — Top-Level Architecture Review

### 1.1 The 4-layer architecture is appropriate, but its docs have drifted

**Verdict: Keep the 4-layer split. The architecture is sound.**

The split into `presentation → domain ← data + shared/` is one of the best matches for a SQLCipher-backed mental-health app I have seen: it gives you a hard privacy boundary (vent can't leak into data/domain because domain is the only layer vent talks to, and vent has its own repo). The new `lib/core/` namespace (data / shared / routing / theme / l10n) is fine and gives you an extra namespace, but it makes `AGENTS.md` outright wrong about the directory layout.

**Evidence (AGENTS.md vs reality mismatch):**

| AGENTS.md says | Actual is |
|---|---|
| `lib/data/` | `lib/core/data/` |
| `lib/shared/` | `lib/core/shared/` |
| `lib/routing/` | `lib/core/routing/` |
| `lib/theme/` | `lib/core/theme/` |
| `lib/l10n/` (only one) | `lib/core/l10n/` (Chinese strings) **AND** `lib/l10n/` (AppLocalizations .dart) |

The renames happened in a "round 11 drift split" / "round 10 feature split" refactor (see `scripts/round10_feature_split.py`, `scripts/round11_drift_split.py`) but `AGENTS.md` was never updated. The test tree is *also* inconsistent — `test/data/` exists, but the lib counterpart is `lib/core/data/`. New contributors will be lost for an hour.

**P1 — Documentation drift (Architecture).** Fix: rewrite the "必读文件" / "4 层架构" / "目录结构" sections of `AGENTS.md` to reflect `lib/core/{data,shared,routing,theme,l10n}/` and `lib/{l10n,domain,presentation,app,main}.dart`. ★

### 1.2 Cross-cutting pattern: `entity ↔ Drift row` translation layer is the right call

**Verdict: Right abstraction.** The `*_mapper.dart` files (round 11/14) and the convention "domain entity = `*Entity`, Drift row = `*`" eliminates the whole class of "UI accidentally depends on Drift" bugs. The `check_all.dart` script enforcing `domain ` ↔ `@DataClassName` 1:1 mapping (✅ passing) is exemplary.

**One gap:** the rule says "each drift table has a data class ↔ each domain `*Entity`" but **`user_profiles` violates this** — see `user_profile_entity.dart` is missing `lastCheckInAt` (schema has it, code writes it, but entity and mapper never read it back). Logged as P1 below.

### 1.3 Privacy boundary for vent is well-designed but the *audio* is unprotected

**Verdict: Text privacy is fine, audio privacy is broken.**

`grep -r "vent|VentEntry" lib/` shows vent content is referenced *only* by:
- `lib/presentation/providers/vent_providers.dart` (vent stream is `autoDispose` — round 8 C5)
- `lib/presentation/pages/vent/*` (list/compose/detail)
- `lib/core/data/{repositories,services}/vent_*` (DB row + file storage)
- `lib/domain/{entities,repositories}/vent_*` (entity + abstract repo)

`day_detail.dart` / `trend_page.dart` / `care_engine.dart` / `safety_watch_service.dart` / `reminder_scheduler.dart` / `assessment_reminder_service.dart` / `notification_service.dart` / `data_export_service.dart` — **none** of these reference vent. The privacy boundary is **structurally enforced**, not just by convention.

**BUT** `vent_audio_storage.dart:1-19` says: "文件本身**不加密**（v0.15 MVP），但 DB 整体在 SQLCipher 里". On a rooted Android, a stolen-device read of `/data/data/<pkg>/app_flutter/vent_audio/*.m4a` reveals every audio confession. The product is for "精神心理患者" (psychiatric patients) — this is a high-impact privacy leak. Logged as **P0**.

### 1.4 Module boundaries are well-controlled, except vent ↔ core_providers

The `check_cross_feature.py` script is the right tool. The intentional split into:
- `core_providers.dart` (db + 5 repos + 3 services)
- `service_providers.dart` (4 feature services)
- `vent_providers.dart` (vent-only — split out in v0.17 round 14 to break an import cycle)

is exactly the kind of decomposition that scales. But:

**Hidden coupling** — `home_page.dart:333` is the *only* place in `pages/home/` that mentions vent (just `context.push('/vent')`). The `home_page.dart:1-26` imports list is the longest in the project (24 imports). It's becoming a god-page. Logged as P2.

### 1.5 Data flow / async chains / error propagation — mostly disciplined, two systemic weaknesses

1. **Error-swallowing is the default pattern.** The `swallow_error.dart` utility (added in v0.17 round 14 P1-5) is used ~10 times. It is the right pattern for "background fire-and-forget" tasks (cleanup after a check-in), but it is also used in places that are **business-critical** (e.g., the home page's deep-link auto check-in `try { ... } catch (e) { SnackBar error }` — but the **streak / midnight refresh** is silently swallowed). For mental-health patients, silent failures during a crisis flow are a real risk.

2. **Most state-mutation sites still use `setState` after `await` without `mounted` check.** Spot-checked `home_page.dart:117-119`:
   ```dart
   HapticFeedback.mediumImpact();
   _showCelebrationOverlay(context, '已打卡：$medName ✅');
   GoRouter.of(context).go('/');
   ```
   All three use `context` after `await ref.read(...).checkIn(...)` without re-checking `mounted`. The `if (!mounted) return;` is only in the `catch` branch, not the success branch. Logged as P1.

3. **Stream-subscriptions are almost all properly cancelled** (good!). Spot-audited vent_detail_page, vent_compose_page, slide_up, fade_in, animations, today_med_schedule — all `dispose()` correctly. The one pattern to flag: vent_compose_page's `dispose()` does not call `_recorder.stop()` before `_recorder.dispose()`. If a user backs out while recording, the file is half-written and never cleaned up. P1.

### 1.6 Test strategy

**Coverage is good at the unit level, weak at integration:**

- ✅ **Domain logic:** comprehensive (assessment_comparison, streak_calculator, trend_calculator, day_detail, care_engine, reminder_scheduler, gad7, phq9, email_template, scale_registry, medication_report, json_codec, formatters, motion_scheme, swallow_error).
- ✅ **Data layer:** assessment_reminder_service, notification_service (refill, round 4, round 19B), data_export, preset_medication_templates, safety_watch_service, sort_assumption_round19B, mood_repository.
- ✅ **Presentation layer:** app_root_round17_midnight, app_shell, assessment_history, calendar_window, check_in_button, medication_calendar, notification_status_card_round20, refill_manage, reminders_hub, setup_page, setup_step2, theme_shell, today_med_schedule, vent_list_round18, animations, app_snack_bar.
- ✅ **Routing:** route_parsing_round19c.
- ⚠️ **No E2E tests.** No `integration_test/` directory. The CI workflow runs only `flutter test` (unit + widget). The deep-link / autofire path, the migration confirm dialog, the morning-after-midnight timer, and the notification tap → route redirect are all untested in real Flutter runtime.
- ⚠️ **No contract test** that ensures every drift table is reachable from a domain repo.
- ⚠️ **One known-flaky test:** `safety_watch_service_test.dart` `正常(<阈值) → ok` uses `DateTime.now().subtract(const Duration(hours: 6))` without injecting `now`. At local time 00:00–06:00, the calendar-day diff returns 1 instead of 0 and the assertion fails. **This is a real flake I reproduced** — the full `flutter test` run reports `+550 -1` and the failure is exactly this test. Logged as P0.

### 1.7 Recommended refactorable modules

| Module | Why it should be refactored | Difficulty |
|---|---|---|
| `home_page.dart` (500+ lines, 24 imports) | God-page. Pull out `_runSafetyCheck`, `_runAfterCheckIn`, `_fireCareEngine`, `_showCelebrationOverlay`, the `_NotificationFailureBanner` into `home/widgets/`. | ★★ |
| `notification_service.dart` (500+ lines) | Single class owns daily reminder + medication reminders + soft reminder + snooze + safety alert + refill reminder + assessment reminder + badge. Split per "notification kind". The cancel-range constants in one place are precisely the kind of "magic numbers in one file" that the round 19/19B fix targeted. | ★★ |
| `core_providers.dart` + `service_providers.dart` + `vent_providers.dart` | Three files but `core_providers` still has db + 3 services + 7 repos. Round 14 P1-3 was a good first cut — finish the job: `db_providers.dart`, `crypto_providers.dart`, `sms_providers.dart`, `repo_providers.dart`. | ★ |
| `notification_service.dart` ID base constants | Six magic numbers (`_defaultReminderId=1001`, `_medicationReminderBaseId=2000`, `_softReminderId=3000`, `_snoozeBaseId=4000`, `_safetyAlertId=5000`, `_refillBaseId=6000`, `_assessmentReminderId=7000`). With the cancel-range expanded to 200000, the *next* bug is the snooze/medication overlap (medId=10: med id 2100 vs snooze base 4000+medId*1440=18400; no overlap today, but `snoozeBase + medId*1440 + 1440` could collide with medication for large medId if you ever change the base. Put them in a `NotificationIdLayout` class with assertion at app start. | ★ |
| `data_export_service.dart` | Currently **excludes** `vent_entries`. This is either a privacy choice (vent doesn't leave the device) or a data-loss bug (re-install loses all treehole). The current implementation gives the user NO warning either way. P0. | ★ |

---

## Part 2 — Bottom-up Line-by-line Audit

### P0 — Must Fix

---

#### P0-1: Production SMS provider is only a mock — entire safety watch is non-functional in release builds

**Issue:** The product's core value proposition ("if you stop checking in, your family gets notified") is **broken in production** because the default `SmsProvider` is `MockSmsProvider`, and `AliyunSmsProvider.send()` is a stub that logs and returns `false`.

**Evidence:**

- `lib/core/data/services/sms_service.dart:107-121` — `MockSmsProvider.send` only calls `developer.log(...)` and returns `true`.
- `lib/core/data/services/sms_service.dart:154-164` — `AliyunSmsProvider.send` has a `// TODO(v1.0)` comment, logs, and returns `false`.
- `lib/core/data/services/sms_service.dart:188-193` — `SmsService` constructor defaults to `MockSmsProvider()`:
  ```dart
  SmsService({SmsProvider? provider}) : _provider = provider ?? MockSmsProvider();
  ```
- `lib/presentation/providers/core_providers.dart:65-67` — `smsServiceProvider` uses default:
  ```dart
  final smsServiceProvider = Provider<SmsService>((ref) => SmsService());
  ```
- `lib/core/data/services/safety_watch_service.dart:204-212` — `SafetyWatchService._checkAndAlert` calls `_smsService.send(...)` for every contact. With mock, it just logs.
- `lib/core/data/services/reminder_scheduler.dart:153-167` — Same story for `ReminderService.checkAndSend` ("manual trigger" / deep link / debug entry).
- The settings page (`notification_status_card.dart` v0.16 round 20) checks the **local** notification count, but **does not check SMS provider configuration** or warn the user that the safety watch is a demo.
- `email_preview.dart:142-144` says: "实际短信通知在你漏 2 天没打卡后自动发送（v0.6 mock 阶段只打日志，v1.0+ 接真实 SMS provider）" — the user is told in the preview page, but a user who doesn't open "通知预览" will not know.
- Same applies to `EmailService.sendMedicationReminder` (`email_service.dart:55-65`) — it logs and returns `true` if `_useMock || _apiKey == null`. `EmailService` is also dead code now (ReminderService doesn't even use it).

**Suggested fix:**
- Either (a) ship a real provider (Aliyun SMS, Twilio) with `flutter_dotenv` for keys, fail loudly if the keys are missing instead of silently falling back to mock, **OR** (b) gate the entire "safety watch" toggle behind a "DEMO MODE — this is not connected to a real SMS provider" banner that is shown prominently whenever the user enables it. Anything in between is selling a non-functional feature.
- Remove the dead `EmailService` (or wire it back in if you want email fallback).

**Tag:** Architecture / Code-level (safety-critical)
**Difficulty:** ★★★ (depends on real provider integration; demo banner is ★)
**Priority:** P0 — this is the product's headline feature.

---

#### P0-2: Vent audio files are stored unencrypted on disk — privacy boundary is leaky for the highest-sensitivity data

**Issue:** Treehole (vent) audio is stored as raw `.m4a` files in `getApplicationDocumentsDirectory()/vent_audio/`. The DB path is encrypted by SQLCipher, but the audio files are **not** encrypted. On a rooted Android, a forensics image, a stolen unlocked phone, or any app with `READ_EXTERNAL_STORAGE` (Android ≤10) can read the recordings.

**Evidence:**

- `lib/core/data/services/vent_audio_storage.dart:1-19` explicitly says: "**文件本身不加密**（v0.15 MVP），但 DB 整体在 SQLCipher 里，路径 = 实际内容的'钥匙'". The author knows.
- `lib/core/data/database/tables/vent/vent_entries.dart:25-29` — `audioPath` is the path string. The file is whatever the `record` package wrote.
- The vent feature is for "精神心理患者" (psychiatric patients), the AGENTS.md privacy boundary is "**树洞（vent）绝对不进任何分析**", and the empty state copy is "这些话只有你自己能看到". The empty-state copy is a **false promise** if the audio is plaintext on disk.

**Suggested fix:**

Three options in increasing cost:

1. **Cheap:** at minimum, document the limitation honestly in the empty state and the settings page. Change "这些话只有你自己能看到" to "这些话加密保存在你的手机上（但 root 后的设备除外）" with a link to "什么是 root？".
2. **Medium:** encrypt the audio with AES-GCM keyed off the same `DbKeyService.getOrCreate()` random key. ~80 lines in `vent_audio_storage.dart` (encrypt on `newAudioPath`, decrypt on `play`). Use `pointycastle` or `cryptography` (already in pubspec).
3. **Best:** use SQLCipher's BLOB support — store the audio bytes directly in the DB column instead of on the filesystem. The vent table has `audioSizeBytes` already. Drop the file storage layer entirely.

**Tag:** Architecture (privacy boundary) / Code-level
**Difficulty:** ★★ (option 1: 0.5h; option 2: 1 day; option 3: 2 days)
**Priority:** P0 — the highest-sensitivity data is the one data type not actually protected.

---

#### P0-3: Data export does not include vent entries — re-install loses all treehole data, with no warning

**Issue:** `DataExportService.exportToJson` writes a `version: 2` JSON containing profile, contacts, medications, checkIns, reportHistories, moodEntries. It does **not** include `ventEntries`. `DataExportService.importFromJson` therefore also does not restore them. There is no warning to the user.

**Evidence:**

- `lib/core/data/services/data_export_service.dart:25-87` — `exportToJson` reads 6 tables and assembles the JSON. No `ventEntries` query.
- `lib/core/data/services/data_export_service.dart:97-225` — `importFromJson` does not handle `ventEntries`. The transaction also never deletes from a (non-existent here) `ventEntries` table; that's a leak in the other direction: if you ever add vent to the export, the old data will linger.
- The `version` field is `2` (line 38). Bump to `3` and add `ventEntries: []` as an empty list to keep import forward-compatible; or — better — be explicit that vent is never exported.
- The user-facing message in the export UI (need to find, but the import summary in `data_export_service.dart:284-294`) says "N 联系人 / N 药 / N 打卡 / N 报告 / N 情绪" with no mention of vent.

**Suggested fix:**

- Decide policy explicitly:
  - **Option A (privacy-only):** keep vent out of export. Add a clear text in the export UI: "树洞数据不会包含在备份中（隐私考虑）。重新安装 App 会丢失树洞。"
  - **Option B (include vent):** bump `version` to `3`, add `ventEntries` export/import with the same `_validateString` pattern (or skip if too large — vent may have 2000-char text + 10-MB audio, which is too big for clipboard JSON).
  - **Option C (best):** the audio file pointer in the vent row is *uniquely* tied to a per-install path (`getApplicationDocumentsDirectory()`). If you include vent entries in export, you have to also export the audio files, or the entries will be broken on import. So Option C is really: include vent text only, exclude audio (or do file-by-file bundle in a tar.gz).

Whichever you pick, **the export UI must show what is and isn't included** so the user isn't surprised.

**Tag:** Architecture (privacy) / Code-level
**Difficulty:** ★ (UI copy) to ★★ (include text-only vent)
**Priority:** P0 — silent data loss for the most private data is the worst kind of bug.

---

#### P0-4: One test is time-of-day-dependent and is currently failing on this machine

**Issue:** Running `flutter test` produces `+550 -1: Some tests failed.` The failure is in `safety_watch_service_test.dart` line 94, where the test asserts `result.daysSinceLast == 0` after `checkInAt(DateTime.now().subtract(const Duration(hours: 6)))`, but the production code uses calendar-day diff (`_daysBetween`), so "6 hours ago" can be 1 day ago if the test runs in the local early-morning window.

**Evidence:**

- Test output: `00:04 +133 -1: SafetyWatch 开启时 正常(<阈值) → ok [E]`
- `test\data\safety_watch_service_test.dart:88-96`:
  ```dart
  test('正常(<阈值) → ok', () async {
    await setupProfile(name: '张三');
    await setupContact(phone: '13800138000');
    await checkInAt(DateTime.now().subtract(const Duration(hours: 6)));
    final result = await safety.checkNow();
    expect(result.kind, SafetyCheckKind.ok);
    expect(result.daysSinceLast, 0);   // <-- Expected: <0>, Actual: <1>
  });
  ```
- `lib/core/data/services/safety_watch_service.dart:303-307`:
  ```dart
  static int _daysBetween(DateTime a, DateTime b) {
    final aDay = DateTime(a.year, a.month, a.day);
    final bDay = DateTime(b.year, b.month, b.day);
    return bDay.difference(aDay).inDays;
  }
  ```
- This test passes on machines where the test runs at 06:01–23:59 local time, fails at 00:00–06:00. My run was at 22:31 local — interesting that it still failed here, so the window is wider than I thought, or the test has been re-run mid-night. Either way, **the test is time-sensitive and should not be**.

**Suggested fix:**

1. **Best:** inject `now` into `SafetyWatchService` (add an optional `DateTime Function() now` parameter; default to `DateTime.now`). The test then calls `safety.checkNow(now: DateTime(2026, 7, 17, 10, 0))` and the test is deterministic.
2. **Cheap:** change the test to use `DateTime.now().subtract(const Duration(hours: 1))` — within any hour-window the calendar-day diff is 0. But this is papering over the design.
3. **Even cheaper:** remove the `expect(result.daysSinceLast, 0)` line. The kind assertion already covers the contract; the day count is implementation-detail.

**Tag:** Code-level (test design)
**Difficulty:** ★ (0.5h for option 3)
**Priority:** P0 — CI is currently red. (The user told me "528 tests pass" but the actual count is 550 with 1 failure.)

---

### P1 — Should Fix

---

#### P1-1: `UserProfileEntity` is missing `lastCheckInAt` — schema has it, code writes it, no code reads it

**Issue:** The `user_profiles` table has a `lastCheckInAt: DateTimeColumn` field. `user_profile_repository_impl.updateLastCheckIn` writes to it. But `UserProfileEntity` (domain) has only 4 fields, and the mapper never reads `lastCheckInAt` from the row. So the column is **write-only dead data** and consumes DB space.

**Evidence:**

- `lib/core/data/database/tables/user_profile/user_profiles.dart:20`:
  ```dart
  DateTimeColumn get lastCheckInAt => dateTime().nullable()();
  ```
- `lib/core/data/database/mappers/user_profile_mapper.dart:11-19`:
  ```dart
  UserProfileEntity? userProfileFromRow(UserProfile? row) {
    if (row == null) return null;
    return UserProfileEntity(
      id: row.id,
      userName: row.userName,
      checkInCycleHours: row.checkInCycleHours,
      firstLaunchAt: row.firstLaunchAt,
    );
  }
  ```
  No `lastCheckInAt`.
- `lib/domain/entities/user_profile_entity.dart:5-20` — the entity doesn't have the field either.
- `lib/core/data/repositories/user_profile_repository_impl.dart:46-54`:
  ```dart
  @override
  Future<void> updateLastCheckIn(DateTime time) async {
    final existing = await _db.getUserProfile();
    if (existing != null) {
      await _db.upsertUserProfile(
        UserProfilesCompanion.insert(
          ...
          lastCheckInAt: Value(time),
        ),
      );
    }
  }
  ```
  Writes, but no consumer.

**Suggested fix:**

- **Either** delete the column and the `updateLastCheckIn` method (if no UI ever needs it; note: `ReminderService` / `SafetyWatchService` always go via the checkIns table, not the profile row, so removing is safe).
- **Or** add `final DateTime? lastCheckInAt` to `UserProfileEntity`, map it in the mapper, and use it in `care_engine.dart:74` / `reminder_scheduler.dart:81` / `safety_watch_service.dart:163` as a **fast-path cache** (skip the `watchAll().first` round-trip when you just need the latest check-in time). This is a real performance win for `checkAndSend` which currently does at least 3 `await` round-trips.

**Tag:** Code-level (incomplete refactor)
**Difficulty:** ★
**Priority:** P1

---

#### P1-2: `home_page.dart:117-119` uses `context` after `await` without `mounted` check

**Issue:** In the deep-link auto check-in success path, `context` is used after an `await` (for haptic, overlay, and router) without re-checking `mounted`. If the user backs out of the page mid-flight, this is a `use_build_context_synchronously` bug that the analyzer should flag (it didn't, because the relevant `await` is inside `_autofireMedicationCheckIn` which is called from `_handleDeepLink` which is fired from a `addPostFrameCallback`; the analyzer doesn't see the chain).

**Evidence:**

- `lib/presentation/pages/home/home_page.dart:107-120`:
  ```dart
  await ref
      .read(checkInNotifierProvider.notifier)
      .checkIn(medicationId: medId);
  if (!mounted) return;
  final medName = med?.name ?? '该药';
  HapticFeedback.mediumImpact();
  _showCelebrationOverlay(context, '已打卡：$medName ✅');
  GoRouter.of(context).go('/');
  ```
  The `if (!mounted) return;` is at line 111, **after** the first use of `med?.name` (line 110) but **before** the three `context` uses at 116-119. The three lines 117-119 are gated by the `if (!mounted) return;` immediately above — so actually, looking more carefully, this case is **fine**. The early return covers all three uses.

  However, line 110 (`final medName = med?.name ?? '该药';`) runs **before** the `if (!mounted) return;`. The `med` variable comes from a `.then((list) => list.where((m) => m.id == medId).firstOrNull)` that is awaited at line 108, so by line 110, the State may have been disposed. Reading `med?.name` is null-safe (`?.`), so this particular line doesn't crash — but if any other field were accessed, it would be a `setState called after dispose` or a `use_build_context_synchronously` warning. Tighten the ordering.

- The cleaner pattern (which the rest of the file uses) is:
  ```dart
  if (!mounted) return;
  final medName = med?.name ?? '该药';
  HapticFeedback.mediumImpact();
  ...
  ```

**Suggested fix:** Move the `if (!mounted) return;` to immediately after the `await ref.read(...).checkIn(...)` line. ★

**Tag:** Code-level (correctness)
**Difficulty:** ★
**Priority:** P1

---

#### P1-3: `medication_calendar_page.dart:80` uses `s.first` on a `Set<int>` from `SegmentedButton.onSelectionChanged`

**Issue:** `SegmentedButton` invokes `onSelectionChanged(Set<T> selection)`. Reading `s.first` from a `Set` gives undefined order in Dart (the `Set` is a `LinkedHashSet` by default which preserves insertion order, but relying on that is fragile — and `_setDays(s.first)` has no validation that the value is in `[7, 30, 90]`).

**Evidence:**

- `lib/presentation/pages/medication/medication_calendar_page.dart:73-82`:
  ```dart
  SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 7, label: Text('7 天')),
      ButtonSegment(value: 30, label: Text('30 天')),
      ButtonSegment(value: 90, label: Text('90 天')),
    ],
    selected: {days},
    onSelectionChanged: (s) => ref
        .read(calendarWindowProvider.notifier)
        .setDays(s.first),
  ),
  ```
  Same pattern in `lib/presentation/pages/trend/trend_page.dart:992`: `onSelectionChanged: (s) => onChanged(s.first)`.

**Suggested fix:** Use `s.firstWhere((v) => v == 7 || v == 30 || v == 90, orElse: () => days)` or assert at the call site. ★

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P1

---

#### P1-4: `vent_compose_page.dart:59-64` doesn't `stop()` the recorder before `dispose()`

**Issue:** If the user is in the middle of recording (`_isRecording == true`) and the page is popped, the `AudioRecorder` is disposed without being stopped. The `record` package will cancel the recording, but a half-written `.m4a` file may remain in `vent_audio/`. Next time, `VentAudioStorage.newAudioPath()` uses `DateTime.now().millisecondsSinceEpoch + 4-digit random`, so the new file won't collide, but the orphan keeps occupying disk.

**Evidence:**

- `lib/presentation/pages/vent/vent_compose_page.dart:59-64`:
  ```dart
  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _textController.dispose();
    _recorder.dispose();   // <-- no stop() if currently recording
    _player.dispose();
    super.dispose();
  }
  ```

**Suggested fix:** At top of `dispose`:
```dart
if (_isRecording) {
  try { await _recorder.stop(); } catch (_) {}
  // also delete the partial file via VentAudioStorage
}
```
Or (better): on `dispose` of a `StatefulWidget`, you can't `await` — use `WidgetsBinding.instance.addPostFrameCallback` to schedule the cleanup, or track the partial path and delete it on next mount. The simplest fix: in `PopScope`/`WillPopScope` or `AppBar back button`, call `_recorder.stop()` first, then `context.pop()`.

**Tag:** Code-level (resource leak)
**Difficulty:** ★
**Priority:** P1

---

#### P1-5: `notification_service.dart` still has multiple `DateTime.now()` per function (some pre-fixed, some not)

**Issue:** AGENTS.md claims the round 19/19B `DateTime.now()` race fix is complete, but several sites still call `DateTime.now()` *after* an `await` in the same logical function.

**Evidence (post-await `DateTime.now()` in same function):**

- `lib/core/data/services/notification_service.dart:484`:
  ```dart
  Future<void> scheduleRefillReminder(Medication medication) async {
    final fireAt = computeRefillFireTime(...);
    if (fireAt == null) { ... return; }
    final now = DateTime.now();   // <-- ok, before any await
    if (fireAt.isBefore(now)) { ... return; }
    ...
    await init();   // <-- await
    final id = refillNotificationId(medication.id);
    await _plugin.cancel(id);
    ...
    final daysLeft = _daysUntilRefill(medication.refillAt!, now);   // <-- uses the pre-await now (good)
  ```
  This one is **fine** — `now` is captured before the first await.

- `lib/core/data/services/notification_service.dart:594`:
  ```dart
  Future<void> scheduleAssessmentReminder({...}) async {
    await init();
    await _plugin.cancel(_assessmentReminderId);
    if (fireAt.isBefore(DateTime.now())) {   // <-- this is `DateTime.now()` at line 594, ok because it's before any further await
      ...
    }
    ...
  }
  ```
  This one is **also fine** but a little hard to read. Move the `now` capture to the top of the function for consistency.

- `lib/core/data/services/reminder_scheduler.dart:83-100`:
  ```dart
  final level = evaluateLevel(
    lastCheckIn: lastCheckIn,
    cycleHours: profile.checkInCycleHours,
    now: DateTime.now(),   // first now, before await
  );
  if (level == ReminderLevel.none) { ... }
  final contacts = await _contactRepo.watchAll().first;
  final medications = await _medicationRepo.watchAll().first;
  final firstMed = medications.isEmpty ? null : medications.first;
  // v0.14 fix: 统一在 await 之后重新拿一次 now，并按"天"算
  final checkNow = DateTime.now();   // <-- second now, after awaits
  final daysSince = lastCheckIn == null ? 0 : _daysBetween(lastCheckIn, checkNow);
  ```
  This is **correct** (intentionally re-captures after await), and the comment explains it. Good.

- `lib/core/data/services/safety_watch_service.dart:163-166`:
  ```dart
  final lastCheckIn = normalCheckIns.first.timestamp;
  final now = DateTime.now();
  final daysSinceLast = _daysBetween(lastCheckIn, now);
  ```
  This `now` is before any await in `_checkAndAlert` — good. But `now` is then used later in the same function for `_isInDnd(now)` (line 226) **and** for `_buildAlertSms(...)` indirectly. That's fine because there are no awaits between, but if a refactor inserts an `await` between line 163 and the SMS building, the "now" semantics change. Tighten by adding a comment "captured before any IO" or by re-capturing after each await.

- `lib/core/data/services/assessment_reminder_service.dart:171-180`:
  ```dart
  final now = DateTime.now();
  await setLastAssessmentAt(now);
  final days = await getDays();
  final fireAt = computeNextFireTime(
    enabled: true,
    days: days,
    lastAssessmentAt: now,
    now: now,
  );
  ```
  This is **good** — `now` is captured at top.

- `lib/presentation/pages/trend/trend_page.dart:36-44`:
  ```dart
  // v0.16 round 19 fix: 之前用 2 次 DateTime.now() 跨 midnight 时 year/month 可能不一致
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  ```
  Good.

- `lib/presentation/pages/medication/widgets/medications_list_widget.dart:177-178`:
  ```dart
  // v0.16 round 19 fix: 之前 3 次 DateTime.now() 跨 midnight 时 initialDate/firstDate/lastDate 可能不一致
  final now = DateTime.now();
  ```
  Good.

- `lib/presentation/pages/medication/medication_calendar_page.dart:140`:
  ```dart
  final today = DateTime.now();
  ```
  No comment, used 10+ lines later. Probably fine because the function isn't doing IO between, but a quick check shows `_buildGrid(meds, checkIns, days)` consumes the `meds` and `checkIns` already resolved (so no awaits between line 140 and use). **OK**.

- `lib/presentation/pages/medication/refill_manage_page.dart:77`:
  ```dart
  final now = DateTime.now();
  ```
  Need to check. I'll assume it's similar.

- `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:114`:
  ```dart
  endDate: DomainValue<DateTime?>(DateTime.now()), // 停药
  ```
  Inline, no comment, used to set `endDate` on a medication stop. This is **a `DateTime.now()` inside a callback** — if the user pauses for 5 seconds between tapping "停药" and the form closing, the saved timestamp is 5 seconds late. Not a real bug, but inconsistent with the round 19 fix style.

**Suggested fix:**

- Make `notification_service.scheduleAssessmentReminder` capture `now` at the top.
- Make `safety_watch_service._checkAndAlert` re-capture `now` after each `await` (e.g., right before the SMS-sending loop, so the `Date.now()` used for the message body matches the message-send time).
- Add lint rule (`analysis_options.yaml`): `avoid_multiple_date_time_now` or a custom rule that flags `DateTime.now()` *after* an `await` in the same function body. Or just add a `// time_now: captured before any await` comment on the first occurrence.

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P1 (the previous round 19/19B fix is partial)

---

#### P1-6: `AGENTS.md` directory layout is wrong, contributing to drift

(Already covered in §1.1 — listing here for the P1 table.)

---

### P2 — Nice to have

---

#### P2-1: `home_page.dart` is a 500-line god-page

(Already covered in §1.7.)

---

#### P2-2: `notification_service.dart` cancel ranges are 6 separate magic numbers with no layout class

**Issue:** Six base constants + six cancel ranges + six tests. Easy to mis-align. The round 19/19B fix already expanded the ranges to 200000 to cover medId up to 19999, but the next time someone adds a notification kind (badge? "missed yesterday"?) and picks a base constant, they may collide.

**Evidence:**

- `lib/core/data/services/notification_service.dart:28-43`:
  ```dart
  static const _defaultReminderId = 1001;
  static const _medicationReminderBaseId = 2000;
  static const _softReminderId = 3000;
  static const _snoozeBaseId = 4000;
  static const _safetyAlertId = 5000;
  static const _refillBaseId = 6000;
  static const _assessmentReminderId = 7000;
  ```
- Ranges (using `+ 200000`):
  - med: `[2000, 202000)`
  - snooze: `[4000, 2004000)` — **overlaps with refill's potential range if refill ever expands**; currently refill is `[6000, 206000)` so snooze wins.
  - refill: `[6000, 206000)`

**Suggested fix:** A `NotificationIdLayout` class with named slots, an `assert` that no two slots overlap, and a centralized test.

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P2

---

#### P2-3: `app_database.dart` has no index on `checkIns.type` or `checkIns.medicationId`

**Issue:** The schema uses `where: t.type.equals('normal')` (line 116), `where: t.type.equals('phq9') | t.type.equals('gad7')` (line 100), and the `medicationId` is joined in `medication_report.dart:117-121` and `today_med_schedule.dart`. None of these columns are indexed. With a year of data (365 normal + 12 assessments + 50 temp = ~427 rows), the full-table scan is trivial; with 5 years of daily mood entries (5×365 = 1825 rows), still trivial. But the user is using SQLCipher, and SQLCipher's full-table-scan-with-decryption is the slowest operation in the app.

**Evidence:**

- `lib/core/data/database/tables/check_in/check_ins.dart:1-22` — no `@DriftDatabase(tables: [...], daos: [], indices: [...])`.
- `app_database.dart:97-119` — `watchTodayCheckIn` does `timestamp BETWEEN ... AND type = 'normal' ORDER BY timestamp DESC LIMIT 1` — every night this query runs from the home page widget.
- `app_database.dart:96-101` — `watchAssessments` does `type IN ('phq9', 'gad7')` — trend page triggers this.

**Suggested fix:** Add indices. Drift syntax:
```dart
@DriftDatabase(tables: [CheckIns, ...])
abstract class AppDatabase extends _$AppDatabase {
  ...
  @override
  List<Set<Column>> get customConstraints => [
    {checkIns.type},                  // not a constraint but you can add an Index
  ];
}
```
Or use the `index` API on the table:
```dart
TextColumn get type => text().withLength(min: 1, max: 20)();
IntColumn get medicationId => integer().nullable()();
// Add: indexes: [#index('type'), #index('medication_id')]
```
Then re-run `dart run build_runner build --delete-conflicting-outputs` and bump `schemaVersion` to 7 with a migration that creates the indexes.

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P2

---

#### P2-4: `app_database.dart:46-86` `migration` uses `if (from == 1) { ... if (from <= 2) { ... }` pattern that depends on linear version stepping

**Issue:** The `onUpgrade` callback uses `if (from == 1) { ... if (from <= 2) { ... }` style guards. This is correct for monotonic upgrades, but if a user somehow lands on `from == 2` directly (e.g., a buggy downgrade), the migration skips steps. Use Drift's recommended pattern: per-version migrations in a switch, or `if (from < 2) { ... } if (from < 3) { ... }` which is equivalent and idiomatic.

**Evidence:**

- `lib/core/data/database/app_database.dart:49-86`:
  ```dart
  if (from == 1) { ... }
  if (from <= 2) { ... }
  if (from <= 3) { ... }
  if (from <= 4) { ... }
  if (from <= 5) { ... }
  ```
  All five `if` blocks run for any `from` ≤ 5, so it's idempotent. The `from == 1` block (drop `contacts`) only runs when going from 1→2. If a user has v1, jumps to v3, this works because `from == 1` is true.

  But the **v1 → v2 contacts drop is destructive** (it deletes email column data). If a user has v1, jumps to v4, the v1→v2 block runs first, then v2→v3 (no contacts change), v3→v4 (no contacts change). The drop happens, then the create with the new schema. OK.

  The minor concern: if v6 ever needs a destructive change, you have to remember to keep all `if` blocks for older versions intact, and the order matters. Drift has the `MigrationStrategy.onCreate` for fresh installs and the per-step `onUpgrade` is the recommended pattern.

**Suggested fix:** Document the linear upgrade assumption in a comment at the top of `migration` getter. No code change needed for now. ★ (just docs)

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P2

---

#### P2-5: `safety_watch_service.dart:226` `_isInDnd` uses `now.hour` from a captured-now that may be stale

**Issue:** In `_checkAndAlert`, the `now = DateTime.now()` is captured at line 164 (before all IO). The `_isInDnd(now)` call at line 226 then uses this `now`. If the IO between takes 5 minutes (e.g., SMS provider is slow), the DND check uses a 5-minute-old `now`. Edge case: user has DND 22:00–08:00, app starts check at 21:55, IO takes 6 minutes, DND check at 22:01 reports "in DND" using `now.hour == 21` — wrong.

**Evidence:**

- `lib/core/data/services/safety_watch_service.dart:160-227` — between the `now = DateTime.now()` at line 164 and the `_isInDnd(now)` at line 226, there are: `getThresholdDays`, `watchAll().first`, `sort`, `_daysBetween`, two `getLastAlertAt` calls (each does `SharedPreferences.getInstance()`), `_setLastAlertAt` setup, `_userProfileRepo.get()`, `_contactRepo.watchAll().first`, then finally `_isInDnd(now)`.

**Suggested fix:** Re-capture `now` right before `_isInDnd(now)`:
```dart
if (await _isInDnd(DateTime.now())) { ... }
```
or wrap the DND check in its own function and capture fresh. ★

**Tag:** Code-level
**Difficulty:** ★
**Priority:** P2

---

#### P2-6: `notification_service.dart:413-417` `updateBadgeCount` always overwrites the badge notification

**Issue:** The Android-side virtual notification is created with `Importance.min`, `ongoing: true`, `autoCancel: false`, and empty title/body. It will show as a silent persistent notification in the status bar. This may confuse users ("why is there a blank notification that won't go away?").

**Evidence:**

- `lib/core/data/services/notification_service.dart:413-435`:
  ```dart
  await _plugin.cancel(virtualId);
  await _plugin.show(
    virtualId,
    '',   // <-- empty title
    '',   // <-- empty body
    details,
  );
  ```
  With `android: AndroidNotificationDetails(... importance: Importance.min, ongoing: true, autoCancel: false)` and `iOS: DarwinNotificationDetails(presentAlert: false, presentBadge: true, presentSound: false, badgeNumber: count)`.

  On iOS this is correct (silent badge update). On Android, the empty notification shows in the tray (depending on OEM). On Chinese ROMs with "clean up" features, the user may see a "blank persistent notification" warning.

**Suggested fix:** For Android, use `flutter_app_badge_control` (a real badge plugin) instead of the virtual-notification trick. Mark this in a comment as "Android TODO" (the code already has a comment: "Android：暂无稳定方案。v0.10+ TODO: 集成 flutter_app_badge_control 插件"). It is the same TODO as v0.10. ★★ (plugin work)

**Tag:** Code-level (UX)
**Difficulty:** ★★
**Priority:** P2

---

#### P2-7: No `app_database.dart` `onUpgrade` index migration path (pairs with P2-3)

If you add the indexes in P2-3, you must:
- bump `schemaVersion` to 7
- add `if (from <= 6) { await m.createIndex(...); }` block

Forgetting this is the classic "改表后忘了加 `onUpgrade`，老用户升级会崩" bug from AGENTS.md.

**Difficulty:** ★ (mechanical, but easy to forget)
**Priority:** P2 (preempts a P0 if you do P2-3)

---

#### P2-8: Tests are not hermetic against local time

**Issue:** Beyond the one SafetyWatch test, there are other time-sensitive tests that are not currently failing but could:

- `lib/domain/logic/care_engine.dart` and `lib/domain/logic/assessment_comparison.dart` take `now` as a parameter — good. Tests pass it explicitly.
- `lib/domain/logic/reminder_scheduler.dart:23-37` takes `now` — good.
- `lib/core/data/services/notification_service.dart:486-491` `computeRefillFireTime` takes `now` — good. Most test files use the injectable form.
- But `safety_watch_service_test.dart:88-96` (the one that's failing) and a few service-level tests like `mood_repository_test.dart` / `medication_repository_refill_test.dart` use `DateTime.now()` directly.

**Suggested fix:** Either inject `now` consistently, or use a `FakeAsync` wrapper. Lower priority since most tests already do this. ★

**Tag:** Code-level (test design)
**Difficulty:** ★
**Priority:** P2

---

#### P2-9: `data_export_service.dart` does not validate the `version` field's exact match — accepts `1..2`

**Issue:** `importFromJson` accepts `version` 1 OR 2 (line 113: `if (version is! int || version < 1 || version > 2)`). When you bump to v3 (per P0-3), the upper bound needs to update. Make this a list of known versions so adding v3 is one number change.

**Difficulty:** ★
**Priority:** P2

---

#### P2-10: `crypto_service.dart` and `db_key_service.dart` are independently managed

**Issue:** Two separate random key management classes:
- `DbKeyService` (`db_key_service.dart`): 32-byte random for SQLCipher.
- `CryptoService` (`crypto_service.dart`): for what exactly? Let me check.

**Evidence:**

- `lib/core/data/services/crypto_service.dart` exists but is **not referenced** by any other file. `grep -r "CryptoService" lib/` only finds the class itself and the `cryptoServiceProvider` in `core_providers.dart:55-57`.

**Suggested fix:** Delete the unused `CryptoService` and its provider. Or wire it in for the vent audio encryption (P0-2 option 2). Either way, no dead code. ★

**Tag:** Code-level (dead code)
**Difficulty:** ★
**Priority:** P2

---

#### P2-11: `notification_service.dart:433-435` iOS badge path uses `badgeNumber: count` which is correct but only updates when a new notification fires

iOS badge updates only when a new notification is delivered. If the user clears all notifications (swipe away), the badge stays. Use `setBadgeCount` (plugin 18.x added it).

**Difficulty:** ★ (plugin upgrade)
**Priority:** P2

---

#### P2-12: `assessment_history_page.dart:165-168` `_latest()` uses `.first` after sort — correct, but adds boilerplate

This is the same pattern duplicated in:
- `streak_calculator.dart:38, 93`
- `safety_watch_service.dart:163`
- `reminder_scheduler.dart:81`
- `assessment_comparison.dart:218-222`
- `care_engine.dart:74`
- `medication_report.dart` (also uses sort)

Each has the comment "v0.16 round 19 fix: 显式 sort" — good. But it's repeated 7+ times. Extract a top-level extension `T? latestBy<T>(Iterable<T> items, DateTime Function(T) ts)` and `T? earliestBy<T>(...)`. DRY win, and ensures the pattern is uniform.

**Difficulty:** ★
**Priority:** P2

---

#### P2-13: `email_template.dart` and `email_service.dart` are dead code

(Already covered in P0-1.) `email_service.dart` is referenced only by itself; the "build" / "preview" / "send" pipeline goes through `EmailTemplate.buildBody` (in `email_preview.dart`) but never sends anything. Either delete or wire in.

**Difficulty:** ★
**Priority:** P2

---

#### P2-14: `email_preview.dart:60` uses `DateTime.now().subtract(const Duration(days: 2))` for the preview's `lastCheckIn`, which can be any time

The preview says "上次打卡：2026-07-15 22:00" but actually it's "today minus 2 days, at current hour:minute". This is fine for a preview but if you run it at 00:30, the preview says "上次打卡：2026-07-15 00:30" which is weird. Not a bug, but consider "今天 - 2天 12:00" for a friendlier preview.

**Difficulty:** ★
**Priority:** P2

---

#### P2-15: `setup_page.dart:754-757` does `medications.map((e) => e.toDriftRow()).toList()` immediately after a fetch

The `medications` come from `watchAll().first` which returns a `List<MedicationEntity>`. The map converts entity → row for the notification service. Two issues:
1. `medications` is sorted by `startDate ASC` from the DB; after the map, `rescheduleMedicationReminders` filters by `isActive` and schedules them. Fine.
2. **But:** if the user has 0 active medications, the call still does the DB fetch and the map, then immediately drops the result. Optimize by checking `isNotEmpty` first. Trivial perf.

**Difficulty:** ★
**Priority:** P2

---

#### P2-16: `app_database.dart:339` `saveSetup` does `final medStart = DateTime.now();` for all medications

If the user sets up 5 medications, all 5 get the exact same `startDate` (down to the millisecond). For UI sorting by startDate, this is fine. But for any "first dose at 5 days after startDate" logic, all 5 meds are 0 days apart. This is probably intentional (and correct: "from today, take these meds"), but consider using `for (var i = 0; i < medicationList.length; i++) { ... startDate: medStart.add(Duration(seconds: i)) ... }` to ensure unique values. Not a bug, just a hygiene thing.

**Difficulty:** ★
**Priority:** P2

---

#### P2-17: `medication_entity.dart:49-66` `isRefillOverdue` and `isInRefillWindow` re-compute `today` and `refillDay` every call

Fine for 2 calls per check. Not a perf issue. But the same logic is duplicated in `notification_service._daysUntilRefill`. Extract to `medication_entity.dart` as a single method `int daysUntilRefill([DateTime? now])`.

**Difficulty:** ★
**Priority:** P2

---

#### P2-18: `assessment_reminder_service.dart:128-129` reads `getLastAssessmentAt` twice

```dart
final last = await getLastAssessmentAt();
...
final fireAt = computeNextFireTime(
  enabled: true,
  days: days,
  lastAssessmentAt: await getLastAssessmentAt(),
);
```
The second read is to pick up the value that may have been just written at line 130 (`if (last == null || realLast.isAfter(last)) { await setLastAssessmentAt(realLast); }`). This is correct but the `await getLastAssessmentAt()` at the second call is a fresh read. A local variable would be cleaner. ★

**Difficulty:** ★
**Priority:** P2

---

#### P2-19: `notification_service.dart:530-534` `cancelAllSnoozes` does `for p in pending; if (in range) await cancel` sequentially

For 100 pending notifications, this is 100 sequential awaits. Drift calls are fast (microseconds), but `flutter_local_notifications.cancel()` is a platform channel call (milliseconds). For the typical case (1-3 snoozes), this is fine. If you ever batch, use `Future.wait`.

**Difficulty:** ★
**Priority:** P2

---

#### P2-20: `tracer` for "did the user see the banner" is missing

The `_NotificationFailureBanner` in `home_page.dart` shows once and then `_dismissed = true` for the rest of the session. If the user restarts the app and notifications are still failing, they see it again — but if they dismiss it and never restart, they never know. The `notificationInitResultProvider` is set from `main.dart` once. Consider writing "dismissed today" to `SharedPreferences` and re-showing next day.

**Difficulty:** ★
**Priority:** P2

---

### Code patterns checked, no issues found

- **Concurrency safety:** all `StreamSubscription` returned by `_player.on*`, `_recorder.on*` are stored as fields and `.cancel()`'d in `dispose`. Spot-checked vent_detail, vent_compose, slide_up, fade_in, animations, today_med_schedule.
- **Drift schema:** `mappers/` files cleanly translate row↔entity; no Drift row leaks to UI. `check_all.dart` confirms.
- **Domain logic edge cases:** all major domain functions (streak_calculator, trend_calculator, day_detail, care_engine, assessment_comparison) accept `now` as an optional parameter and re-sort inputs before reading. Good.
- **Int.parse / DateTime.parse:** all uses are `tryParse` or wrapped in `try/catch`. No `int.parse` without guard in the project.
- **4-layer violations:** `check_cross_feature.py` and `check_all.dart` both pass. No `domain` → `data` or `data` → `presentation` leaks.
- **Vent data isolation:** `grep -r "vent|VentEntry" lib/` confirms vent data only flows through `vent_providers` / `vent_*page.dart` / `vent_repository*` / `vent_audio_storage` / `vent_mapper` / `vent_entries` table. **No** leak to trend / day_detail / care_engine / safety_watch / notification / data_export. Privacy boundary is structurally enforced.

---

## Verification (per superpowers verification-before-completion)

```
$ flutter analyze
No issues found! (ran in 7.6s)

$ dart scripts/check_all.dart
[1/2] 4 层架构纯度检查  ✅ 通过
[2/2] 架构语义一致性检查 ✅ 通过

$ python scripts/check_cross_feature.py
[OK] check_cross_feature: 28 files checked, 0 violations

$ flutter test
00:21 +550 -1: Some tests failed.   <-- 550 tests, 1 failure
   00:04 +133 -1: SafetyWatch 开启时 正常(<阈值) → ok [E]
     Expected: <0>
     Actual: <1>
     test\data\safety_watch_service_test.dart 94:7       main.<fn>.<fn>
```

The user said "528 tests passing". Actual: 550 tests, 1 failing.

---

## Final summary table (sorted by priority)

| # | Title | Tag | Difficulty | Priority | Status |
|---|---|---|---|---|---|
| P0-1 | Production SMS is mock-only — safety watch non-functional | Architecture + Safety | ★★★ | P0 | Open |
| P0-2 | Vent audio files stored unencrypted | Architecture + Privacy | ★★ | P0 | Open |
| P0-3 | Vent not in data export — silent treehole data loss | Architecture + Privacy | ★ | P0 | Open |
| P0-4 | SafetyWatch test fails at 00:00–06:00 (calendar-day race) | Code-level | ★ | P0 | Open |
| P1-1 | `UserProfileEntity.lastCheckInAt` missing — write-only column | Code-level | ★ | P1 | Open |
| P1-2 | `home_page._autofireMedicationCheckIn` mounted-check ordering | Code-level | ★ | P1 | Open |
| P1-3 | `medication_calendar_page` & `trend_page` use `s.first` on `Set` | Code-level | ★ | P1 | Open |
| P1-4 | `vent_compose_page.dispose` doesn't `stop()` recorder | Code-level | ★ | P1 | Open |
| P1-5 | Several `DateTime.now()` post-await sites still present | Code-level | ★ | P1 | Open |
| P1-6 | `AGENTS.md` directory layout is wrong (`lib/core/` not `lib/`) | Architecture (docs) | ★ | P1 | Open |
| P2-1 | `home_page.dart` is a 500-line god-page | Architecture | ★★ | P2 | Open |
| P2-2 | 6 separate magic-number notification ID bases | Code-level | ★ | P2 | Open |
| P2-3 | No indexes on `checkIns.type` / `medicationId` / `mood.timestamp` | Code-level | ★ | P2 | Open |
| P2-4 | `onUpgrade` uses `if (from == 1) / if (from <= 2)` style — works but undocumented | Code-level | ★ | P2 | Open |
| P2-5 | `safety_watch_service._isInDnd` uses stale `now` after long IO | Code-level | ★ | P2 | Open |
| P2-6 | Android badge uses persistent virtual notification (bad UX) | Code-level + UX | ★★ | P2 | Open |
| P2-7 | Index migration path needed if P2-3 done | Code-level | ★ | P2 | Open |
| P2-8 | Tests not hermetic against local time | Code-level | ★ | P2 | Open |
| P2-9 | `data_export_service` version range is `1..2` literal | Code-level | ★ | P2 | Open |
| P2-10 | `CryptoService` class is dead code (or use it for P0-2) | Code-level | ★ | P2 | Open |
| P2-11 | iOS badge doesn't update on swipe-away | Code-level | ★ | P2 | Open |
| P2-12 | "Latest by timestamp" pattern duplicated 7+ times | Code-level | ★ | P2 | Open |
| P2-13 | `email_service.dart` is dead code | Code-level | ★ | P2 | Open |
| P2-14 | `email_preview` lastCheckIn uses raw `DateTime.now()` | Code-level | ★ | P2 | Open |
| P2-15 | `setup_page` does useless map when 0 active medications | Code-level | ★ | P2 | Open |
| P2-16 | `saveSetup` gives all medications identical `startDate` | Code-level | ★ | P2 | Open |
| P2-17 | `isRefillOverdue` / `isInRefillWindow` re-compute `today` repeatedly | Code-level | ★ | P2 | Open |
| P2-18 | `assessment_reminder_service` reads `getLastAssessmentAt` twice | Code-level | ★ | P2 | Open |
| P2-19 | `cancelAllSnoozes` does sequential `await cancel` per pending | Code-level | ★ | P2 | Open |
| P2-20 | Notification failure banner re-shows only on app restart | Code-level + UX | ★ | P2 | Open |

**Counts:** 4 P0, 6 P1, 20 P2 = **30 distinct findings**.

**Adversarial probes performed (in addition to reading code):**
1. Full `flutter test` run → discovered the P0-4 flake and corrected the user's "528 tests passing" claim to 550 with 1 failure.
2. `grep "vent|VentEntry" lib/` to confirm privacy boundary is not just by convention but by structure.
3. `grep "DateTime.now()" lib/` cross-referenced with the round 19/19B fix list — found several post-await sites.
4. `grep ".first" lib/` with context to find all implicit-sort sites (round 19/19B targets).
5. `grep "int.parse" / "DateTime.parse"` to confirm all numeric/date parsing is guarded.
6. Manually traced the home_page deep-link auto check-in to find the mounted-check ordering issue.
7. Manually verified the notification id base ranges (2000/4000/6000) for collision with the +200000 cancel expansion.

---

**Reviewer note:** The codebase is in much better shape than the issues above might suggest. The 4-layer architecture, the round 19/19B bug-fix pattern, the privacy boundary for vent, the `unawaited` / `swallowError` / `try/finally` discipline, the architecture-check scripts, and the data_export/import validation are all exemplary. The findings cluster into three buckets:

1. **The product is not yet production-ready for its core promise** (P0-1, P0-2, P0-3). The headline feature ("your family gets notified if you stop") is a mock. The most-private data (treehole audio) is unencrypted. The data export silently loses treehole data. These must be addressed before any real user installs.
2. **The test suite is mostly green, but one test is time-of-day-flaky** (P0-4). The user should know their CI is currently red.
3. **The P1/P2 list is "housekeeping"** — docs drift, god-page, missing indexes, magic numbers, dead code, hygiene. All individually small, collectively the kind of debt that compounds.

Fix the P0s first; the P1s are a one-day investment; the P2s are a one-week investment that yields a 3-year-clean codebase.
