# 修复报告 09 — 架构批 2 (AR-19 / R112-ARCH-01 / R112-ARCH-03)

- 批次: v0.32 R112 fix-reports #09 (architecture batch 2: 数据编排下沉 + pipeline 拆分)
- 执行者: 实现 subagent (09-architecture-batch2)
- 日期: 2026-08-14
- 基线: HEAD=6bbb308 (R112 working tree 进行中, 有其他 agent 在并行改文件 — 见 Concerns)
- 范围: 3 个任务, 见 `07-top-level-arch.md` AR-19 / R112-ARCH-01 / R112-ARCH-03

## 结论速览

| 任务 | 状态 | 验证 |
|---|---|---|
| 1. AR-19 SetupCommitter (saveSetup + clearAllUserData 下沉) | **done** | setup_committer_round112_test 4 case 绿 + end_to_end 集成 2 绿 |
| 2. R112-ARCH-01 ConsentPreferenceStore (persistence 下沉) | **done** | vent_seal_round82 (10 case) + consent_artifact_data_export_round82 (11 case) + export_tile_round95 (5 case) 全绿, 行为/key 100% 不变 |
| 3. R112-ARCH-03 export_import_pipeline 拆 4 子函数 + ImportResultBuilder | **done** | data_export_v5_round8 + v5_daily_tracking + pipeline_round99 + cbt + round39 + round3 共 67 case 全绿 |

**验证汇总** (实测):
- `flutter test test/data/ test/integration/ test/domain/ test/presentation/pages/settings/...` → **1329 pass** (含我改的全部文件; 排除 2 个 pre-existing 失败文件, 见下)
- `flutter analyze` → 我的文件 **0 error / 0 warning**。全仓仍有 pre-existing error (其他 agent 在改的文件: vent_list_page → contacts_list_widget → cbt_section 语法错误在 session 期间漂移, 非我引入)
- `dart scripts/check_all.dart` → 纯度 ✅ + 一致性 ✅
- `python scripts/check_cross_feature.py` → 0 violation
- 14 个 check_*.py 守门员全绿 (strings_hardcoded / usecase_layer / datetime_race×2 / widget_dispose / drift_namespace / arb_keys / orphan_arb_keys / pii_in_title / no_hardcoded_utc / no_pua / legal_consent / zh_hant / apple_health; review_information_todo 为 warn-only 外部占位, 同基线)

## 任务 1: AR-19 — SetupCommitter (done)

**改动**:
- 新建 `lib/core/data/services/setup_committer.dart` (130L): `SetupCommitter(AppDatabase db)` 收编 `completeSetup(...)` (原 saveSetup, 1 transaction 写 3 实体 + PIPL §13 长度 StateError 校验原样) + `clearAllUserData()` (PIPL §47, allTables 全删)
- `lib/core/data/database/app_database.dart` 520L → 410L: 删 2 个编排方法 + 4 个随之无用的 import (ConsentArtifact / HourMinute / encodeTimes / VentAudioStorage), 只留 DAO facade + schema/migration
- 调用点最小改动:
  - `setup_page_state.dart:412` → `SetupCommitter(ref.read(databaseProvider)).completeSetup(...)` + 1 import
  - `clear_tile.dart:121` → `SetupCommitter(db).clearAllUserData()` + 1 import (头注释同步)
- 测试: 迁移 `app_database_save_setup_round112_test.dart` (SP-R112-04, 未入库 untracked → 删除) → 新建 `test/data/setup_committer_round112_test.dart` (176L, 4 case): StateError 回滚 / 成功写 3 实体+4 consent 字段 / clear 后重设 / clearAllUserData 清全部表。`end_to_end_flows_round95_test.dart` 集成 2 改调 completeSetup

**发现 (重要, 写进测试注释)**: 原 saveSetup 的 `insertOnConflictUpdate` 在 PK (id=1, `withDefault(Constant(1))`) 不在 companion 内时**不会覆盖已有行** (drift 2.20 行为, probe 实测 userName 不变)。这是原代码 1:1 语义 (非迁移引入的回归), 且真实世界不可达 (setup 只跑一次; 清空数据后行已删)。测试改为锁"clearAllUserData → 重新 completeSetup"的真实路径, 不锁那个 quirk。

## 任务 2: R112-ARCH-01 — ConsentPreferenceStore (done)

**改动**:
- 新建 `lib/core/data/services/consent_preference_store.dart` (241L): `ConsentPreferenceStore(SharedPreferences prefs, {EncryptionService? encryption})` — 10 个方法从 LegalConsentStore 原样迁移, key 命名 (`legal_consent_withdrawn_<kind>` / `_at` / `legal_consent_data_export_log` / `legal_consent_vent_sealed_at`) 与 swallowError where 标签不变 (只把 `legal_consent.` 前缀改 `consent_preference_store.`), audit log 仍走 EncryptionService AES-256 (PIPL §28)。与 `core/shared/consent_gate.dart` SharedPrefsConsentGate 的 key 约定保持双向同步 (未动)
- `legal_consent_provider.dart` 291L → 81L: 删 LegalConsentStore 类 + 8 处 `SharedPreferences.getInstance()`, 留 4 个 provider + `export ConsentKind` re-export (legal_page 等老 caller 零改动)
- 测试迁移 (行为 100% 不变的回归套):
  - `vent_seal_round82_test.dart` → 改测 ConsentPreferenceStore (10 case, 含 clearLegalConsentCache 调试入口完整性)
  - `consent_artifact_data_export_round82_test.dart` → 改测 ConsentPreferenceStore (11 case, 含密文 lock-in + 坏数据 skip + reset 清 audit log)
  - `export_tile_round95_test.dart` → `_FailingLegalConsentStore extends ConsentPreferenceStore`, provider override 类型同步

**架构点**: legal_consent_provider 现在 `import cbt_providers.dart` 取 `sharedPreferencesProvider` (presentation→presentation/providers 允许, check_cross_feature 0 violation)。`legal_page.dart` / `export_tile.dart` / `fire_care_strategy.dart` 注释 0 代码改动 (provider 名不变)。

## 任务 3: R112-ARCH-03 — export_import_pipeline 拆 4 子函数 (done)

**改动**: `export_import_pipeline.dart` 851L → 923L (净 +72 来自子函数 doc 注释):
- `runImportFromJson` 从 780L 单函数拆成: 顶层编排 (~60L) + 4 private 顶层函数:
  - `_clearData(db, schemaService)` — 12 表清空
  - `_importProfile(db, data)` — R112 E7 的 update().write() 语义原样
  - `_importEntities(db, reportRepo, data, version, counts)` — contacts / medications / checkIns / reportHistories / moodEntries / 6 daily tracking 表; **medIdMap + moodIdMap 老→新 id 映射在此函数内闭环** (不跨子任务泄漏)
  - `_importVent(db, cryptoService, audioService, data, version, counts)` — version<3 早退
- 新 `ImportResultBuilder` (public, 聚合 7 计数 → `build()` → ImportResult.success)
- 行为 100% 不变: 67 个 data export 相关 case 全绿 (含 v5 daily tracking / pipeline_round99 三态 / vent 密文 round-trip)

## 需要你 (整合者) 接线的 provider 行

两个新 data service 目前用"每次调用构造"的最小方式接入, 若想走 composition root 请加:

```dart
// lib/presentation/providers/core_providers.dart (我没动这个文件, 归属权外)
final setupCommitterProvider = Provider<SetupCommitter>(
  (ref) => SetupCommitter(ref.watch(databaseProvider)),
);
// lib/presentation/providers/legal_consent_provider.dart 已接线 (我改的):
//   legalConsentStoreProvider = Provider<ConsentPreferenceStore>(
//     (ref) => ConsentPreferenceStore(ref.watch(sharedPreferencesProvider)));
// main.dart bootstrap 已 override sharedPreferencesProvider, 无需新接线。
// 接线后 caller 可改 ref.read(setupCommitterProvider), 但非必需 (SetupCommitter 无状态)。
```

## Concerns / 注意事项

1. **working tree 并发修改**: 我的 session 期间其他 agent 在改文件 — `vent_list_page.dart:367` → `contacts_list_widget.dart:58` → `cbt_section.dart:92` 语法错误在漂移。这些 pre-existing error 非我引入, 但会影响任何全量 `flutter test` 的结论。我的验证基于: 我触碰的 14 个文件 0 error/0 warning + 相关测试 1329 pass。
2. **2 个 pre-existing 测试失败** (与我的改动无关, 实测复现): `settings_page_r93_hide_test` (contacts_list_widget 编译错误) + `cbt_section_round84_test` ×3 (Flutter ListTile/DecoratedBox ink 断言, 框架版本行为)。
3. **pipeline 文件净行数 +72** (851→923): 拆分是按 R77 注释的字面 4 子任务执行, 子函数 doc 注释 + ImportResultBuilder 增加行数。`_importEntities` 仍 ~400L (内含 6 张 daily tracking 表段)。若还要压 god-class 指标, 可再拆第 5 个 `_importDailyTracking` (1h 工作量, 本轮没做因为会偏离"4 子任务"原计划)。
4. **跨 ownership 的 doc 引用未动**: `vent_audio_storage.dart:80` / `swallow_log_sink.dart:156` 注释提到 `AppDatabase.clearAllUserData` / `saveSetup`, 仍在 file ownership 外; `comment_references` lint 未启用所以 analyze 不报, 建议后续清理。
5. **consent_dialog.dart:150** 注释仍写 `LegalConsentStore` 旧类名 (consent_dialog 不在我的 ownership, 无代码引用)。已核对: 全 lib/ 0 代码引用旧类名, 只有 consent_dialog 这一条注释残留。
6. **E5 行为保持**: StateError 中文消息逐字保留在 SetupCommitter (check_strings_hardcoded 规则 2 不匹配 error message 模式, 守门员绿)。
7. **未 commit** (按指令)。新文件为 untracked: setup_committer.dart / consent_preference_store.dart / setup_committer_round112_test.dart; 删除的 app_database_save_setup_round112_test.dart 本身是 untracked (R112 未入库)。

## 测试数变化

| 文件 | 前 | 后 |
|---|---|---|
| setup_committer_round112_test.dart | — (SP-R112-04 1 case, untracked) | 4 case (1 迁移 + 3 新) |
| vent_seal_round82_test.dart | 10 (测 LegalConsentStore) | 10 (测 ConsentPreferenceStore, 0 语义变) |
| consent_artifact_data_export_round82_test.dart | 11 | 11 (同上) |
| export_tile_round95_test.dart | 5 | 5 (同上) |
| end_to_end_flows_round95_test.dart | 5 | 5 (集成 2 改调用) |
| data export 组 (v5×2 / pipeline_round99 / cbt / round39 / round3) | 67 | 67 (0 语义变) |
