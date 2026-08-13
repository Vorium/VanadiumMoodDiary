# Fix Report: export/import 数据完整性 (E6/E7/E8 + R112-05/06/07)

日期: 2026-08-13 · 状态: 全部 done · 测试: 全绿 (见文末)

## E6 (P0, done) — export v5 补 6 张 daily tracking 表

**修了什么**:
- `export_orchestrator.dart`: `exportToJson` 新增 6 段 — `sleepEntries`
  / `socialRhythmEntries` / `stressEvents` / `treatmentEntries`
  / `weightEntries` / `anxietyAgitationEntries`, 每张表全字段导出 (走
  既有 `isoUtc` + `if (x != null)` 模式, 5s stream timeout 防 hang)。
- `export_import_pipeline.dart`: import 前先 `deleteOldDataSafely` clear
  6 表 (跟 reportHistories/moodEntries/ventEntries 一致), 再逐段
  `validateXxx` 校验插入。
- 外键重映射 (E3 同款):
  - `treatment.linkedMedicationId` → medIdMap (E3 已有映射)
  - `stress.linkedMoodEntryId` → 新增 moodIdMap; moodEntries 导出补
    `'id'` 字段供映射 (老 v4 文件无 id → 无映射 → null, 不导入孤儿 FK)
- `export_schema_service.dart`: v5 注释补 daily tracking + 本批全部扩展
  (schemaVersion 保持 5, 未发布不 bump)。

**测试** (`test/data/data_export_v5_daily_tracking_round8_test.dart`, 6 case 全过):
1. sleep_entries round-trip 2. social_rhythm_entries round-trip
3. stress_events round-trip + linkedMoodEntryId 重映射
4. treatment_entries round-trip + linkedMedicationId 重映射
5. weight_entries round-trip 6. anxiety_agitation_entries round-trip

## E7 (P1, done) — profile PIPL §14 同意留痕 4 字段

**修了什么**:
- `export_orchestrator.dart`: profile 段导出 `userAgreementVersion`
  / `privacyPolicyVersion` / `sensitiveDataConsentAt` / `consentRevokedAt`
  (nullable, `if != null` 优雅降级)。
- `export_import_pipeline.dart`: profile import 补 4 字段
  `Value(validateXxx(...))` (老 v4 文件 → null)。
- **额外发现**: drift `insertOnConflictUpdate` **忽略** `Value(null)` —
  probe 实测旧设备残留 consent 字段不会被老文件清空。修法: profile 行
  存在时改用 `db.update(...).write(companion)` (显式 SET NULL),
  import = 全量替换语义; 行不存在仍走 upsert。

**测试** (`data_export_v5_round8_test.dart` case 9/10 全过):
- 9. 导出含 4 字段, import 后保留 (换机留痕不断)
- 10. 老 v4 文件无 4 字段 → 导入后 null (优雅降级)

## E8 (P1, done) — 软停药整行导出不丢

**修了什么**:
- `export_orchestrator.dart:112`: medications 改 `watchAllIncludingInactive()`
  (参考 medication_repository_impl.dart:34-38 报告用法), 软停药
  (isActive=false) 不再整行消失。
- 顺手补 `endDate` 导出 (import 侧 v5 早有反序列化, 停药日期换机不丢)。
- import 侧 isActive 字段已实现, E3 medIdMap 重映射自然覆盖 inactive 药。

**测试** (`data_export_v5_round8_test.dart` case 7 重写 + 8 新增, 全过):
- 7. (重写) checkIn 引用 inactive 药 → import 后 FK 重映射到新 id, isActive=false 保留
- 8. inactive 药 round-trip: isActive=false + endDate 全字段保留

## R112-05 (P2, done) — isActive 裸 cast 脏数据崩溃

**修了什么**: `export_import_pipeline.dart` contact + medication 两处
(审计只点 139 行, 同文件 211 行同款漏网) `m['isActive'] as bool? ?? true`
→ `m['isActive'] is bool ? m['isActive'] as bool : true`, 脏数据
(0/1 int / "true" string) 降级 true 不崩导入。

**测试**: case 11 — v4 脏数据 isActive (int 1 / string "true") → 导入成功降级 true。

## R112-06 (P2, done) — lastCheckInAt 导入

**修了什么**: profile import 补 `lastCheckInAt: Value(validateDate(...))`
(P0-10 注释意图补完), 走 write() 全量替换。

**测试**: case 12 — 导出含 lastCheckInAt, import 后恢复。

## R112-07 (P2, done) — doc 注释 v4 → v5

**修了什么**: `data_export_service.dart:35` 一行 doc 注释
`v4 (current)` → `v5 (current)`。

## 验证

- `flutter test test/data/data_export_v5_round8_test.dart` — 12/12 全过
- `flutter test test/data/data_export_v5_daily_tracking_round8_test.dart` — 6/6 全过
- 9 个 export 相关测试文件合计 139/139 全过 (round3/39/45/schema/crypto/audio/cbt/pipeline_round99)
- `flutter analyze` 我的 4 lib 文件 + 2 test 文件: 0 warning, 0 新 issue
  (仅 1 个 pre-existing info `require_trailing_commas`, R111 E1 引入非本批)
- 全量 `flutter test`: 2411 pass / 8 fail / 1 skip — 8 fail 全部 pre-existing
  (4 iOS 资产占位 + 4 个 l10n 编译 loading, 其他 agent R112 进行中), 本批 0 新 fail

## Concerns

1. **drift `insertOnConflictUpdate` 忽略 `Value(null)`** (probe 实测): 任何"用
   upsert 写 null 清残留"的模式在本项目都会静默失效, 值得全库 grep 同类用法。
2. E8 改 watchAllIncludingInactive 后, 导出文件变大 (停用药全量), 且老 v4
   文件导入的 inactive 药会有 `isActive` 缺省 true 的脏数据 — R112-05 已容错。
3. stress.linkedMoodEntryId / treatment.linkedMedicationId 重映射依赖 mood/med
   导出的 'id' 字段, 老 v4 文件无 id → 映射为空 → FK 置 null (可接受, 跟 E3
   一致); 但 v4 文件的 moodEntries 无 'id' 导致 stress 段 FK 全 null, 属
   老数据降级而非数据丢失。
