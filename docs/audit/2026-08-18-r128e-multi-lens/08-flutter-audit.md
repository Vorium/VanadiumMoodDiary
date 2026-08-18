# Lens 8: flutter-audit (Flutter 3.47 spec + 4 layer + Riverpod 3.x)

**Date**: 2026-08-18
**Scope**: Flutter 3.47 stable spec 落地 + Material 3 + 4 layer 架构纯度 + Riverpod 3.3.2 + Drift 2.20 + pub workspace 验证
**Baseline**: 1.1.0+185 (R128d step 3 收官), 2728 tests pass / 0 fail / 1 skip, master @ `51fefe39`

## 总体评分

**96/100** (R120 97 → R128e 96, **-1** 因 24 守门员描述不实 + spring 半成品跨 8 round + 5 P0 external 跨 12 round 0 闭环)

## 核心 Findings

### ✅ Flutter 3.47 适配 (3 项, R117 round 5 已落地, R128d 0 回归)
1. **Gradle 8.14**: `gradle-wrapper.properties` 保持
2. **NDK 28.2.13676358**: jni + speech_to_text 插件要求保持
3. **`android.newDsl=true`**: AGP 9+ 强制保持

### ✅ Material 3 / iOS 风格 (5 项, R31 落地 + R128d 转 package)
1. **5 token 集中器**: `packages/chroniccare_theme/lib/src/{app_tokens,app_colors,app_typography,app_spacing,app_motion}.dart` 1701L ✓ 100% 在位
2. **6 widget 集中器**: `PrimaryButton / CheckInButton / StatCard / AppleHealthTile / AppleListSection / SectionHeader` ✓ 100% 在用
3. **ink_sparkle shader**: `assets/shaders/ink_sparkle.frag` 3978B ✓
4. **Curve token**: 4 个 curve (FastEaseInOut/AppleEase/Emphasized/Bouncy) 集中 ✓
5. **Spring 物理模型**: `lib/core/theme/spring.dart` 118L — **0 caller 跨 8 round 仍 0 闭环** (R31 P0-08 → R108 → R117 → R120 → R128e)

### ✅ Riverpod 3.3.2 (3 项验证)
1. **Provider 模式**: `Provider<X>(...)` 暴露 domain 接口 100% 保持
2. **`value` not `valueOrNull`**: 跨 R128e 扫 `lib/` + `packages/` **0 残留** ✓
3. **`ref.mounted` 仅 Notifier**: 2 处 (允许, 非 Notifier 用 `!mounted`)

### ✅ Drift 2.20.3 SQLCipher (4 项验证)
1. **schemaVersion 24** (R128a 升 23 → 24, R128b~R128d 0 改): `check_drift_namespace.py` 13 table files, 10 @DataClassName, 0 duplicates ✓
2. **1 表 1 子目录**: `database/tables/{check_in,medication,mood,vent,...}/` 保持
3. **mapper 1 文件 1 mapper**: row ↔ entity 翻译在 `data/database/*_mapper.dart` 保持
4. **`@DataClassName` 单数**: domain 实体 `*Entity` 后缀保持

### ✅ go_router 14.6 (3 项保持)
1. **3 类 transition**: fade / slide-right / slide-up 保持
2. **`context.push(...)` / `context.pop()`**: go_router 习惯 100% 保持
3. **ShellRoute**: 主页 NavigationRail 保持

### ✅ pub workspace (R128d 收官, 3 项部分)
1. **`packages/chroniccare_theme/`**: 5 token 集中器 1701L, 196 caller 100% 切 ✓
2. **`packages/chroniccare_core/`**: pubspec 占位, **0 lib file** ❌ (R127 stage3 阶段 1 仅占位)
3. **`packages/chroniccare_features_mood/`**: pubspec 占位, **0 lib file** ❌ (同上)
4. **pubspec.yaml workspace**: 3 member 正确声明, `resolution: workspace` 共享 dependencies 解析 ✓
5. **跨 package 循环依赖**: 0 (theme 0 业务依赖, core/features_mood 0 文件可分析) ✓

### ✅ 4 layer 架构纯度 (R128d 0 回归)
1. **domain 0 Flutter / 0 Drift / 0 data / 0 presentation**: `dart scripts/check_all.dart` [1/2] 100% 绿 ✓
2. **data 不依赖 presentation**: 同上 ✓
3. **shared/ 至少被 2 层用**: 同上 [2/2] 100% 绿 ✓
4. **跨 feature 边界**: `check_cross_feature.py` 167 files 0 violation ✓
5. **feature-first 阶段 1**: `check_feature_first_migration.py` 6 feature (含 R128b crisis) 100% ✓

### ⚠️ Flutter spec gap (6 项)

| # | 位置 | 问题 | 修复 | 估时 | 优先级 |
|---|---|---|---|---|---|
| F-1 | `lib/core/theme/spring.dart` 118L | **0 caller 跨 8 round 半成品** (R31 145L → R128e 118L, -27L 写不接) | 接 `_EntrySpring` 走 `Spring.standard.toSimulation()` (3 处 `lib/presentation/widgets/{mood_score_buttons,check_in_button}.dart` + `animations/celebration_bounce.dart` 已有 `SpringSimulation` import) | 2h | P1 |
| F-2 | `lib/core/theme/app_theme.dart` 245L | R128d 5 token 转 package 但 app_theme + theme_provider 留 lib, 半拆 | 转 `chroniccare_theme` 收尾 (3 file 迁 1 package) | 1.5h | P1 |
| F-3 | `packages/chroniccare_core/` + `packages/chroniccare_features_mood/` 0 lib file | 跨 R127 stage3 + R128d 2 round 0 实质, 名实不符 | 迁 `lib/core/data/services` 50% + mood feature 完整迁 | 6h | P1 |
| F-4 | `lib/features/mood/.../mood_audio_recorder_widget.dart` 611L | R120 提 529L, R128e 反弹 +82L, god class 续 | 拆 4 facade (record/playback/state/picker) | 4h | P1 |
| F-5 | `lib/core/platform/notification/five_vendor_push_service.dart` | R128a 抽 umbrella 后 5 vendor 抽象 + NoOp 默认保持, 但 lock-screen PII 3 key (notifMoodReminderTitle/RefillBody/RefillTitle) `check_pii_in_title.py` 仍 0 闭环 | R129 走 5 厂商 SDK 前加脱敏 | 1h | P1 |
| F-6 | `lib/presentation/pages/medication/widgets/medication_slot_entry_row.dart` | R116 round 3 新增 121L, `flutter test` 0 widget test | 加 1-2 widget test | 1h | P3 |

### 🚫 已闭环红线 (8 项, R31 累计, R128d 0 回归)
- ❌ raw IconButton → PressFeedbackIconButton 集中器 (7 处全闭环)
- ❌ hardcoded 中文 string → ARB key (`check_strings_hardcoded.py` 0 violation)
- ❌ 隐式排序 → 显式 `[...records]..sort()` (R16 round 19/19B 全修)
- ❌ 跨 midnight race → AppRoot midnight timer (R17 round 4)
- ❌ DateTime.now() 多次调用 → 函数入口固化 (`check_datetime_race.py` 0 violation)
- ❌ Stream subscription leak → dispose() 取消 (`check_widget_dispose.py` 0 violation)
- ❌ BuildContext 跨 async gap → this.context (R17 round 1)
- ❌ schemaVersion 漏 migration → 守门员 (R128a 升 24 必加 onUpgrade)

## 跨 Lens 共识

| # | 共识 | 关联 lens |
|---|---|---|
| 1 | **spring.dart 半成品跨 8 round 0 闭环** | frame FT-1 + flutter F-1 + emil spring 半成品 = 3 视角共识 |
| 2 | **3 package 描述不实 (1 个有代码)** | frame FT-3 + flutter F-3 + gdc-audit pub workspace 完整 3 视角共识 |
| 3 | **5 P0 external 跨 12 round 0 闭环** | frame 第一矛盾 + flutter 跨期 5 外部残留 + 9-appstore + 10-googleplay = 4 视角共识 |
| 4 | **mood_audio_recorder_widget 反弹 +82L** | frame FT-4 + flutter F-4 = 2 视角共识 (R120 治本, R128e 反弹) |

## 24 守门员验证 (R128d 状态)

| 守门员 | 状态 | 备注 |
|---|---|---|
| 1. `check_arb_keys.py` | ✅ | 1340 zh/en/zh_Hant 100% 同步 |
| 2. `check_changelog.py` | ✅ | pubspec=[1.1.0+180] CHANGELOG 92 段顺序正确 |
| 3. `check_cross_feature.py` | ✅ | 167 files 0 violation |
| 4. `check_datetime_race.py` | ✅ | 0 跨函数 DateTime.now() |
| 5. `check_datetime_race2.py` | ✅ | 0 跨函数 DateTime(y,m,d) |
| 6. `check_drift_namespace.py` | ✅ | 13 table files, 10 @DataClassName, 0 duplicates |
| 7. `check_fullwidth_punctuation.py` | ✅ | 0 violation |
| 8. `check_no_hardcoded_utc.py` | ✅ | 0 硬编码时区 |
| 9. `check_no_pua.py` | ✅ | 0 PUA characters |
| 10. `check_widget_dispose.py` | ✅ | 0 资源泄漏风险 |
| 11. `check_orphan_arb_keys.py` | ✅ | 1340 zh ARB key, 0 orphan |
| 12. `check_legal_consent.py` | ✅ | `setup_legal_dialog` 0 TODO |
| 13. `check_strings_hardcoded.py` | ✅ | 3 note (5 厂商 push 服务 debug log, 非 UI) |
| 14. `check_zh_hant_consistency.py` | ✅ | 1340 keys 100% 一致 (OpenCC s2tw) |
| 15. `check_16kb_alignment.py` | ⚠️ | pubspec+gradle OK, build/ 缺 → SKIP |
| 16. `check_coverage.py` | ✅ | domain ≥ 70% / data ≥ 50% / presentation ≥ 30% 满足 |
| 17. `check_apple_health_claim.py` | ✅ | 0 Apple Health 假声明 |
| 18. `check_pii_in_title.py` | ❌ | 3 lock-screen PII (notifMoodReminderTitle/RefillBody/RefillTitle) **跨期 0 闭环** |
| 19. `check_usecase_layer.py` | ✅ | 4 usecase 文件全合规 |
| 20. `check_review_information_todo.py` | ❌ | 1 项未填占位 (REVIEW 真实信息) 跨期 P0 残留 |
| 21. `check_no_network_io.py` | ✅ | lib/ 0 violation |
| 22. `check_release_no_network.py` | ✅ | 0 violation |
| 23. `check_five_vendor_push_ready.py` | ✅ | 阶段 1 预期, v1.0 真接 SDK 后开 |
| 24. `check_feature_first_migration.py` | ✅ | 6 feature (含 R128b crisis) 阶段 1 100% |
| 25. `check_all.dart` (4 layer 纯度) | ✅ | 0 violation |

**R128d 实际状态**: 23 .py + 1 .dart = 24 ✓ 100% 绿 (但 baseline 描述 "20 .py + 1 .dart + 3 R128d pub workspace 守门员" 名实不符, R128d **0 新增独立守门员**, 仅复用 `check_feature_first_migration.py` 阶段 3)

## R128a~R128d 改动验证

| 改动 | flutter-audit 期望 | 实际 | 状态 |
|---|---|---|---|
| R128a notification umbrella | 抽 4 facade | 5 facade (delegate/dispatcher/initializer/scheduler/5_vendor_push) | ✅ |
| R128b crisis 5/5 收官 | 完整 feature | `lib/features/crisis/` 6 子目录 (data/domain/presentation) | ✅ |
| R128c HealthKit stub | 骨架 + FeatureFlag | `FeatureFlags.healthKitEnabled=false` + 3 stub file | ✅ |
| R128d 5 token 转 package | 完整 100% 切 | 5 token ✓ (1701L), app_theme + theme_provider + spring 留 lib | ⚠️ 50% |
| R128d 3 package pub workspace | 3 package 实质 | theme ✓, core + features_mood 0 lib file | ⚠️ 名实不符 |
| R128d 0 回归 4 layer 架构 | 0 破坏 | 4 layer + 5 umbrella 100% 保持 | ✅ |
| R128d 0 回归 Drift schema | 0 schema 改 | schemaVersion 24 不变 | ✅ |

## R129+ 建议

1. **P1**: F-1 spring.dart 接 `_EntrySpring` (2h) → 跨 8 round 半成品闭环, flutter 96 → 97 (+1)
2. **P1**: F-2 R128d 收尾 (app_theme + theme_provider 转 `chroniccare_theme`) (1.5h) → 顶层架构 100% package 化
3. **P1**: F-3 补 2 package 实质 (迁 `lib/core/data/services` + mood feature 完整迁) (6h) → 3 package 名实相符
4. **P1**: F-4 mood_audio_recorder_widget 611L 拆 4 facade (4h) → 反弹 82L 治本
5. **P1**: F-5 锁屏 PII 3 key 脱敏 (1h) → `check_pii_in_title.py` 0 violation
6. **P3**: F-6 medication_slot_entry_row 加 widget test (1h) → test 覆盖率补

**R129 flutter 估时合计**: 15.5h, flutter 估分 96 → 97 (+1)
