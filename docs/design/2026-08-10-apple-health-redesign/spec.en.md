# iOS 17/18 Visual Language Redesign · Spec (EN Summary)

> **Status**: v0.31 round 11 (R31) landed · 2026-08-10
> **Source (中文 full)**: [spec.md](spec.md) (22KB, 10 sections)
> **Scope**: 11 feature pages redesigned · depth = tokens + key widgets
> **Style**: iOS 17/18 visual language · minimal / whitespace / 0 shadow (color-only hierarchy)
> **Owner**: Mavis orchestrator + subagent-driven implementation

## 1. Status (Closed Loop)

R31 (2026-08-10~11) completed 22 commits + 2 cleanup commits. R115 (2026-08-17) emotion-first refactor: 14 commits. R116 (2026-08-17) god class split: 4 rounds (mood_trend / reminders_hub / medication / add_medication). 27/27 gatekeepers green, 2515 tests pass.

## 2. 5 Token Concentrators (Phase 1)

| File | Scope |
|---|---|
| `app_colors.dart` | iOS system color + 8 health metric palette (red/pink/orange/green/blue/purple/...) |
| `app_typography.dart` | 17pt body + 13pt caption + ultralight w200 for large numbers (Apple Health signature) |
| `app_spacing.dart` | Corner radius 14/10 + buttonHeight 50 + info density +30% |
| `app_motion.dart` | 0 shadow + 3 Apple cubic-bezier curves |
| `spring.dart` | Spring physics model (mass/stiffness/damping), 145L, 3 runtime callers (mood_score_buttons / celebration_bounce / check_in_button) |

## 3. 6 Widget Concentrators (Phase 2)

| Widget | Purpose |
|---|---|
| `PrimaryButton` | Apple Pill 3 variants (default/secondary/tertiary) |
| `CheckInButton` | 64pt giant pill + spring entry |
| `StatCard` | Ultralight w200 4 variants + number tween |
| `AppleHealthTile` | 8 metric colored modules |
| `AppleListSection` | iOS grouped list (insetGrouped) |
| `SectionHeader` | iOS ALL CAPS 11pt gray |

## 4. 5 Page Redesigns (Phase 3)

- **Home**: 6 AppleListSection + spacing 16 + stagger 8→3 (closed loop) + 4 StatCard 2x2 + 5 mood carousel
- **Setup**: 4 steps progress bar 25/50/75/100%
- **Medication**: 4 AppleHealthTile horizontal scroll + systemRed FAB + 5 subpages
- **Trend / Vent**: chart + list + carousel patterns

## 5. 9 Page Follow-ups (Phase 4)

trend / mood / vent / assessment / settings / contact / daily_tracking buttons + dividers all iOS 17/18 style.

## 6. Spring Physics Model (1 half-done)

`Spring.standard` / `Spring.gentle` / `Spring.bouncy` 3 static instances. 3 runtime callers:
- `mood_score_buttons.dart:134` (Spring.standard, scale 0.92→1.0 entry)
- `celebration_bounce.dart:66` (Spring.bouncy, overshoot 1.12)
- `check_in_button.dart:268` (Spring.standard, scale 0.97 entry)

`Spring.gentle` 0 caller (drawer / sheet scenarios, available).

## 7. Apple 5.1.3 Sensitive Apps Compliance

R31 strictly avoids:
- ❌ "Apple Health" literal mention outside `docs/design/2026-08-10-apple-health-redesign/` (locked by `apple_health_mention_lock_in_round9_test.dart`)
- ❌ `health_kit` package / `HealthKit` / `HKHealthStore` / `HKQuantityType` keyword in lib/ (locked by `check_apple_health_claim.py`)
- ❌ HealthKit auth / NSHealthShareUsageDescription / NSHealthUpdateUsageDescription (0 added)

8 metric colored tiles (`AppleHealthTile`) display **in-app data only** (mood/vent/sleep/worry), NOT real HealthKit data. The visual is "iOS 17/18 language" not "HealthKit integration".

## 8. R31 17 P0 Landed (R31 hotfix + R108 R115 follow-up)

| P0 | Status |
|---|---|
| review_information 4 TODO | ✓ closed |
| notes.txt version sync | ✓ closed |
| AppIcon placeholder | ✗ designer (R118 wait) |
| 16KB alignment | ✓ closed (NDK 28.2 + Gradle 8.14) |
| spring.dart 接 _EntrySpring | ✓ (3 runtime callers) |
| PageScaffold translucent AppBar | ✓ landed |
| 5.1.3 Sensitive Apps 抽审准备 | ✓ 3/4 文档 |
| 7 P0 跨期残留 (iOS/Android 截图 + 域名 ICP) | ⏳ 外部依赖 |

## 9. Related

- 中文 spec: [spec.md](spec.md) (22KB)
- 5 token 集中器: `lib/core/theme/{app_colors,app_typography,app_spacing,app_motion,spring}.dart`
- 6 widget 集中器: `lib/presentation/widgets/{primary_button,check_in_button,stat_card,apple_health_tile,apple_list_section,section_header}.dart`
- AGENTS.md "已知坑": Material 3 ink_sparkle shader 3.44.5+ 注意
- `check_apple_health_claim.py` (R31) 守门员
- `apple_health_mention_lock_in_round9_test.dart` (R31 round 9) lock-in test
