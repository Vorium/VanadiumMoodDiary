# R120 flutter-spec 视角审视

> **项目**: chroniccare v1.1.0+149 → +156
> **基线**: Flutter 3.47 (Gradle 8.14 + NDK 28.2 + newDsl=true) / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6
> **审视轮次**: R120 god class 续拆 3 round 后
> **任务范围**: 只覆盖 flutter-spec 视角

---

## 综合评分: 97% (R117 88% → R31 97% → R120 持平 97%)

R120 维持 R31 之后的 97% 高位, 0 倒退。**核心量化数据** (4 个): `flutter test` **2571 pass / 0 fail** (R119 baseline 2566, +5 regression); `flutter analyze` **0 error / 0 warning**; **27 守门员 = 20 ✅ + 5 上架 P0 external (预期 fail) + 2 warn**; `dart scripts/check_all.dart` **0 violation** (4 层纯度 + 实体表对应双报告均 0)。R118 (10 量表独立 class) + R119 (app_database 拆 part) + R120 (notification_service facade 收紧) 三轮 god class 续拆**全部用加性重构** (composition 委托 / part of 共享 library scope / 私有方法抽 + doc 外移), 公开 API 0 变化 → 0 跨层 import regression / 0 drift schema 破坏 / 0 测试 baseline 倒退。

**未到 98% 的原因**:
1. `lib/core/theme/spring.dart` 145L `gentle` 仍 0 caller (R31 P0 半成品)
2. `vent_list_page.dart` 684L + `mood_audio_service.dart` 496L 两个超 350L 文件**不在 R108 §六 god class 候选**
3. CI 仍**不跑** `flutter test --coverage` + `check_coverage.py` (R107 baseline 已列, 12 round 仍未接入)

3 项均非 R120 引入, 是 R31 → R117 跨期残留, 跟 R107 baseline report §"问题清单" #3 #4 #7 完全对得上。

---

## 1. 4 层架构纯度

**评估**: 0 violation, 4 层 + shared umbrella 落地 100% 干净。

**证据**:
1. `dart scripts/check_all.dart` 双报告 (`purity` + `consistency`) exit code 0 → 4 层之间 0 跨层 import, 0 forbidden package 引用
2. `lib/domain/entities/scale_translations/*.dart` 11 文件 (R118 P2-7 新增) grep `package:flutter|package:drift|package:chroniccare/core/data|package:chroniccare/presentation|package:chroniccare/l10n` **0 命中**
3. `lib/core/data/database/app_database_migrations.dart` (R119 新增 part 文件) 走 `part of 'app_database.dart'`, 共享 library scope, **0 import/export 额外管线**

**R120 评估**: 0 新 violation, 0 守门规则扩展需求。

---

## 2. Drift schema 安全

**评估**: schemaVersion 24 0 破坏, 24-version onUpgrade 1:1 保留。

**证据**:
1. `app_database.dart:87` `int get schemaVersion => 24` — R119 + R120 0 bump
2. `app_database_migrations.dart:140-145` `_runAppDatabaseMigrations(AppDatabase db, Migrator m, int from, int to)` 函数签名跟原 inline `onUpgrade: (m, from, to) async {...}` 完全一致, 1:1 行为保留
3. 24 个 `if (from <= N)` / `if (from == N)` 守卫全在 part 文件
4. P3 幂等守卫 `_columnExists` + `_addColumnIfMissing` 都在 part 文件
5. R119 regression test `app_database_split_round119_test.dart` 5 case 验证 (双文件 / part 指令 / 1-line 委托 / 24 守卫 / 主壳 < 200L, 实际 139L, **过 38% 余裕**)

**R120 评估**: 0 schema 风险, 0 migration 风险, drift schema 安全跨期 100% 保持。

---

## 3. Riverpod 3.x API

**评估**: `valueOrNull` → `value` 100% 迁移, `ref.mounted` 仅在 Notifier。

**证据**:
1. `grep "valueOrNull" lib/` **0 命中** — 整个 `lib/` 已无 `AsyncValue.valueOrNull` 残留
2. `grep "ref.mounted" lib/` 仅 2 文件: `shared_providers.dart:129` (跨日 tick Notifier) + `calendar_window_provider.dart:24` (设窗口大小 Notifier) — **全部是 Notifier 子类**
3. 27 处 `!mounted` widget check 保持
4. `app_router.dart:37-58` `ref.read + 内部 cache` 防 GoRouter 重建

**R120 评估**: 0 升级残留, 0 跨期回归。

---

## 4. 视觉 token 集中度

**评估**: 5 token 集中器 + 6 widget 集中器 100% 在位, 174 presentation 文件用集中 token。

**证据**:
1. **5 token 集中器** (R31 Apple Health 重设, R120 0 变化): `app_colors.dart` / `app_typography.dart` / `app_spacing.dart` / `app_motion.dart` / `spring.dart`
2. **6 widget 集中器** (R31, 174 file 调用): `PrimaryButton` / `CheckInButton` / `StatCard` / `AppleHealthTile` / `AppleListSection` / `SectionHeader`
3. **`spring.dart` 145L R120 状态**: standard + bouncy 各 1 runtime caller (R114 B2-9 接入), gentle 仍 0 caller

**R120 评估**: 0 散落硬编码, 0 视觉回归, 集中度跨期保持。

---

## 5. 守门员

**评估**: **27 守门员 = 20 ✅ + 5 上架 P0 external (预期 fail) + 2 warn**, 0 红线, 0 跨期回归。

**20 ✅**: check_arb_keys / check_changelog / check_cross_feature / check_datetime_race (+2) / check_drift_namespace / check_fullwidth_punctuation / check_no_hardcoded_utc / check_no_pua / check_widget_dispose / check_orphan_arb_keys / check_legal_consent / check_strings_hardcoded / check_zh_hant_consistency / check_16kb_alignment / check_coverage / check_apple_health_claim / check_pii_in_title / check_usecase_layer / check_review_information_todo

**5 上架 P0 external (预期 fail)**: 设计师资产 + 域名 ICP + 5 厂商 push SDK + 阿里云 SMS

**2 warn**: SMS release (1.1.0 round 4b 删) + EmailService 0 caller dead code

**R120 评估**: 27/27 守门员状态 0 变化, 0 跨期回归。

---

## 6. R118/R119/R120 规范回归深度排查

### R118 P2-7 (10 量表独立 class, 8 commit db920d50~b29d3bd7)
- 11 文件 (11 个 scale_translations 文件): phq9 94L + gad7 84L + isi 83L + pss 84L + whodas 90L + asrm 83L + level2_* 84+83+81+88L + 主壳 394L = **948L 合计** (主壳 R118 前 659L, **-40%**)
- composition 委托: 10 个 `static const _xxxXxx = XxxXxxTranslations()`, 70 method (7 × 10) 1:1 委托
- **0 跨层 import 风险**: 11 文件全在 `lib/domain/entities/scale_translations/`, grep 4 个 forbidden pattern 全部 0 命中
- **0 drift schema 风险**: 全部是 domain 层 const string, 不进 DB
- **0 测试回归**: `round118_direct_test.dart` 42 case
- **R118 verdict**: 0 规范 regression ✅

### R119 P1-1 (app_database 564L → 139L 主壳 + 480L part 文件, 1 commit 82fe9e9b)
- `app_database.dart` 139L: imports + `@DriftDatabase` + 2 构造 + `schemaVersion 24` + migration getter (1-line 委托) + 15 DAO facade
- `app_database_migrations.dart` 480L: 24-version 历史注释 (88L) + `_columnExists` / `_addColumnIfMissing` 守卫 (20L) + `_runAppDatabaseMigrations` 372L
- `part of 'app_database.dart'` 共享 library scope → drift 生成 TableInfo 在 part 文件**直接可访问**
- **0 drift schema 风险**: `schemaVersion 24` 不变, 24-version onUpgrade 1:1 保留
- **0 DAO 风险**: 15 `late final xxxDao` facade 0 改动
- **0 测试回归**: `app_database_split_round119_test.dart` 5 case + `database_migration_dryrun_round8_test.dart` 改读 main + part 双文件
- **R119 verdict**: 0 规范 regression ✅

### R120 P1-2 (notification_service 386L → 252L, 1 commit e07ae845)
- `_buildNotificationDetails()` 私有方法抽 30L `NotificationDetails` 内联块
- 40L 跨 sub-service ID range 文档 → `docs/architecture/NOTIFICATION_ID_BANDS.md` (54L 新文件)
- 32L 历史注释 → 12L 摘要
- **0 sub-service 接口风险**: 7 sub-service + 1 delegate + 1 initializer 全部 DI 注入
- **0 通知 id 公式风险**: 8 类 ID 全部迁出到 `NOTIFICATION_ID_BANDS.md`
- **0 测试回归**: `notification_service_split_round120_test.dart` 5 case
- **R120 verdict**: 0 规范 regression ✅

**3 round 共同规范特征**:
- 拆解单位适配: R118 量表 class / R119 1 part 文件 / R120 私有方法 + doc 外移
- 公开 API 0 变化: 全部加性重构
- drift / schema 风险 0
- 回归 test 模式一致: 主壳 < N + 关键 invariant

---

## 7. 跨期残留 (跟 R107 baseline 对照)

R107 baseline 18 项 → R120 累计关闭 11 项 + 跨期 7 P0 external。flutter-spec 视角跨期残留 3 项 (非 R120 引入, 是 R31→R117 历史问题):

| # | 位置 | 残留原因 | R121 候选 |
|---|---|---|---|
| 1 | `lib/core/theme/spring.dart:25-27` | `gentle` Spring 仍 0 caller, R31 P0 半成品闭环率 2/3 | drawer/sheet 接入 gentle, 1h |
| 2 | `.github/workflows/ci.yml` | `flutter test --coverage` + `check_coverage.py` 仍不在 CI, R107 #3 跨期 | 加 CI 步骤, 0.5h |
| 3 | `lib/core/data/services/mood_audio_service.dart` 496L | 跨 audio recording 业务 | R121 god class 候选 |

---

## 8. R121 建议

### 优先级 1 (本周, ≤2h, 立即可修)
1. **spring.dart `gentle` 接入** (1h, P0 半成品闭环)
2. **CI 接入 `flutter test --coverage`** (0.5h, R107 baseline #3 12 round 跨期)

### 优先级 2 (下周, 2-4h)
3. **`vent_list_page.dart` 684L 拆解** (3h, UI page god class)
4. **`mood_audio_service.dart` 496L 拆解** (3h, audio 业务跨期)
5. **`check_review_information_todo.py` 加 CI 步骤** (0.5h)

### 优先级 3 (R121+ 长期, ≥1 周)
6. **`pubspec.yaml` 收紧 SDK / Flutter 版本** (0.5h)
7. **Spring 物理模型专题 spec 文档** (1h)
8. **`check_pii_in_title.py` 扩 PR 模板守门** (1h, R32 跨期)
9. **`pubspec.yaml` 死依赖清理** (R107 baseline #1)

### 优先级 4 (v1.0 长期, 1-3 月, 外部依赖)
10. **5 上架 P0 external 闭环** (1-2 月)
11. **`audio_lifecycle.dart` 重审** (R117 误判候选)

---

**总行数**: 220 行 markdown
**视角纯度**: 0 跨视角内容
