# v1.1.0 round 11 (R115) Zero-Exfil Privacy Hardening Evidence

> **Status**: 5/5 new gatekeepers green, total 22→27 (+5)
> **Goal**: Lock in "zero cloud + zero push + zero exfil" product positioning, prevent future commits from sneaking in network/permission
> **Date**: 2026-08-17
> **Source (中文)**: [PRIVACY_HARDENING.md](PRIVACY_HARDENING.md)

## 1. Design Principles (why)

**Mental health / chronic disease data compliance**:
- **PIPL §28** (China Personal Information Protection Law): Sensitive personal info (health/medical) requires encrypted storage + minimal collection
- **HIPAA field-level encryption**: Encryption at rest + encryption in transit — zero-exfil architecture natively satisfies this
- **Apple 5.1.3 Sensitive Apps policy**: Emergency functions (one-tap call) cannot upload any data
- **Google Play Health/Sensitive Apps policy**: Notification/reminder features must be local, no exfil

**Product positioning shift (1.1.0 round 4b emotion-first refactor)**: Mental health self-care app, permanently free + zero cloud + zero push, SQLCipher local encryption. This document is hard-constraint evidence for the R115 visual refactor (Batch 2) to lock in zero-exfil architecture.

## 2. 5 New Gatekeepers (R115 landed)

### 2.1 `check_permissions_whitelist.py` (B1)

**Purpose**: Scan `android/app/src/main/AndroidManifest.xml` + `ios/Runner/Info.plist`, verify permissions **strict whitelist** (no extras).

**Whitelist**:
- Android 6: `INTERNET` / `POST_NOTIFICATIONS` / `SCHEDULE_EXACT_ALARM` / `WAKE_LOCK` / `VIBRATE` / `RECORD_AUDIO`
- iOS 4: `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` / `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`

**Blacklist (explicitly forbidden, revival → fail)**: Contacts / Location / SMS / Camera / Bluetooth / Accounts / System overlays / Notification background activity / 30+ more

**Live check**:
```bash
$ python3 scripts/check_permissions_whitelist.py
✅ 0 violation — permissions strictly whitelisted
```

### 2.2 `check_no_network_io.py` (B2)

**Purpose**: Scan `lib/**/*.dart`, verify zero network exfil.

**Forbidden imports (10)**: `package:http` / `package:dio` / `package:web_socket_channel` / `package:firebase_*` / `package:sentry_*` / `package:cloud_firestore` / `package:googleapis` / `package:aws_*` / `package:azure_*` / `package:crypto_`

**Forbidden `dart:io` calls**: `HttpClient()` / `WebSocket.connect()` / `HttpServer.bind()` / `Socket.connect(<remote>)` — remote = non-localhost / non-127.0.0.1

**`url_launcher` whitelisted schemes**: Only `tel:` / `mailto:` / `sms:` (system calls, no INTERNET needed)

**Live check**:
```bash
$ python3 scripts/check_no_network_io.py
✅ 0 violation — lib/ zero network exfil
```

### 2.3 `check_encryption_at_rest.py` (B3)

**Purpose**: Scan `lib/**/*.dart` file-write logic, verify **must go through encryption** (PIPL §28).

**Encryption whitelist**:
- SQLCipher database (`AppDatabase()`)
- `.m4a.enc` encrypted audio (`EncryptedFileStorage`)
- `swallow.log` encrypted audit log
- `flutter_secure_storage` (Keychain/Keystore)

**Live check**:
```bash
$ python3 scripts/check_encryption_at_rest.py
✅ 0 violation — all docs writes encrypted
```

### 2.4 `check_pii_in_assets.py` (B4)

**Purpose**: Scan `assets/**/*.md` + `assets/**/*.txt`, verify **0 PII leak** (no real phone / email / ID / address).

**Whitelist**: `+86 12345` (test fixture hotline) / `cron_test_at_2026_01_01` / `audit_log_id` / etc.

**Line-level escape**: `// @pii-ok` marks the line as intentionally PII (test fixture).

**Live check**:
```bash
$ python3 scripts/check_pii_in_assets.py
✅ 0 violation — assets/ 0 PII leak
```

### 2.5 `check_release_no_network.py` (B5)

**Purpose**: Scan `lib/` + `android/app/src/main/res/xml/network_security_config.xml` + `ios/Runner/Info.plist`, verify **release build 0 network** (no production domain).

**Forbidden**: Any HTTPS/HTTP/WSS domain (except static `apple.com` / `google.com` for store ID validation).

**Live check**:
```bash
$ python3 scripts/check_release_no_network.py
✅ 0 violation — release zero network
```

## 3. Integration with 22 Existing Gatekeepers

R115 added 5 → total 22→27 gatekeepers. New gatekeepers complement the existing architecture/i18n/privacy/test stack:

| Layer | Gatekeeper | R115 impact |
|---|---|---|
| Architecture | `check_all.dart` (4 layers + cross-feature) | ✓ no regression |
| Architecture | `check_cross_feature.py` | ✓ no regression |
| Privacy | `check_no_pua.py` | ✓ no regression |
| Privacy | `check_no_hardcoded_utc.py` | ✓ no regression |
| Privacy | `check_pii_in_title.py` (R32 lock-in) | ✓ no regression |
| Privacy | `check_legal_consent.py` (PIPL §13) | ✓ no regression (1.1.0 round 4b removed §13) |

## 4. Failure Modes & Recovery

| Failure | Cause | Recovery |
|---|---|---|
| New permission added | Dev unaware of whitelist | Update whitelist + document why in commit message |
| `package:http` import | Dev unaware of B2 | Use `url_launcher` with `tel:` / `mailto:` / `sms:` instead |
| `assets/` PII leak | Test fixture not marked | Add `// @pii-ok` line comment |
| Release domain found | Marketing site config slipped in | Remove from `lib/` + `network_security_config.xml` |

## 5. CI Integration

Pre-commit hook + CI:
```bash
for s in scripts/check_*.py; do python "$s"; done  # 26 py + 1 dart = 27 gatekeepers
flutter test --coverage                              # coverage gate
flutter analyze                                       # 0 error / 0 warning
```

## 6. Related Documents

- 中文版: [PRIVACY_HARDENING.md](PRIVACY_HARDENING.md) (full)
- 4 legal docs: `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent,medical_disclaimer}.md`
- 4 FeatureFlag current state: `lib/core/data/feature_flags.dart`
- App architecture: `AGENTS.md` (4 layers + 27 gatekeepers)
- v1.1.0 round 4b emotion-first refactor: deleted 3 exfil flags (emergencyContact / aliyunSms / emailService)
