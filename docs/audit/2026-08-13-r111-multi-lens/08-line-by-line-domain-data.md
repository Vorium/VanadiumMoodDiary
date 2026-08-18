# 底层逐行排查审计: domain + data (2026-08-13, R111)

范围: `lib/domain/**` (entities 26 / logic 33 / repositories 17 / usecases 6) + `lib/core/data/**` (app_database + 14 DAO + 3 connection + tables/mappers + 16 repository impl + 37 services + export/ 5) + `lib/core/shared/**` (10) + `lib/core/l10n/**` (1) + `scripts/` (21 守门员抽查 8) + `test/domain` (50) + `test/data` (43)。**约 170 文件**，纯只读，0 修改。

基线: `docs/audit/2026-08-13-multi-lens/09-line-by-line-domain-data.md` (B1-1 ~ B1-7)。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| E1 | data·数据完整性 | **export/import JSON schema v4 落后 DB schema 22 (R101 后 0 更新) — 换机/重装静默丢字段**: medications 漏 5 字段 (refillAt / refillReminderDays / form / colorIndex / notes), moodEntries 漏 7 字段 (audioPath / audioTranscript / audioDurationMs / period / influenceFactorsJson / recordingMode)。R88 只修了 8 CBT 字段 (R84 加的), 同族字段 R101/R105 又加 3+2 个仍漏。续方提醒配置、剂型/颜色/备注、心境时段聚合 (4 段全变 unspecified)、影响因素全丢 | export_orchestrator.dart:149-158 (medications map) / :178-204 (mood map) / export_import_pipeline.dart:164-183 (med insert) / :265-363 (mood insert) | ≤1d (v5 schema + 双向字段 + round-trip test) | **P1 bug** |
| E2 | 合规 | **contact consent 4 字段不导出/导入 — PIPL §13 留痕断裂**: R63 加了 consentAt/kind/by/version 4 列, export v4 schema 仍只带 name/phone/sortOrder/isActive。导出→删 DB→导入后 4 列全 null; R68 单独同意 gate 只挡 `add()` 路径, 导入路径绕过 → 联系人无有效同意记录 | export_orchestrator.dart:140-148 / export_import_pipeline.dart:132-141 / contact_repository_impl.dart:47-57 | ≤2h | **P1** |
| E3 | data·一致性 | **checkIn.medicationId 原样导入不重映射 → 孤儿 FK**: medications 导入重插 (新 autoIncrement id), checkIns 的 medicationId 仍指向旧 id。打卡↔药物关联错位 (日历/统计 join 不到), 且 validateInt 无 id 有效性校验 | export_import_pipeline.dart:196-213 (medicationId: validateInt 原样) / export_orchestrator.dart:160-168 | ≤1d (id 映射表) | P2 |
| B1-5 | hygiene | **R110 跨期残留 — SafetyAlertBuilder.buildFor 死 userName 参数**: `safeUserName()` 算完丢弃, `final _ = name;` + ignore 注释占位 (R32 锁屏 PII 决策后 title 有意无名字, 但参数/求值应删) | safety_alert_builder.dart:82, 115-116 | ≤0.5h | P3 |
| B1-6 | 鲁棒 | **R110 跨期残留 — SQLCipher key 丢失无恢复路径**: keychain 丢 key → 打开 garbage → "file is not a database" → 仅错误横幅 (MigrationFailedApp), 无导出/恢复入口 (已知取舍, 但未闭环) | connection/native.dart:36-45 / main.dart:177-186 / db_key_service.dart | ≤1d | P3 |
| E4 | 一致性 | **7 个量表声明 `translations` 字段但 0 使用**: IsiScale/WhodasScale/PssScale/AsrmScale/Level2×4 的 items/options/severityCutoffs 硬编码中文, bypass R78 i18n 模式 (Gad7Scale 已走 translations); `translations` 是死字段。已知 R51b backlog, 但字段死代码应删或接上 | isi.dart:27,45-93 / whodas.dart / pss.dart / asrm.dart / level2_*.dart (grep 0 命中 `translations.`) | ≤1d (i18n 真接) / ≤0.5h (删死字段) | P3 |
| E5 | robustness | **saveSetup 的 `assert(contactList.length == contactConsents.length)` release 失效**: assert 只 debug 生效; release 不一致 → contactConsents[i] RangeError (fail-fast 但无清晰错误) 或多余 consent 静默忽略 | app_database.dart:453-456 | ≤0.5h | P3 |

## R110 跨期残留验证 (基线 7 项)

| 基线 | 状态 | 证据 |
|---|---|---|
| B1-1 通知 ID 碰撞 (P0) | ✅ **已闭环** (R110 round 3): 固定 ID 移 5M+ 带 — assessment=5000001 / mood=5000002 / badge=5000100 / care push base=5000010, 远离 snooze [300000,2300000) + med [2000,202000) + refill [6000,206000); 有回归守卫 | assessment_notifier.dart:28 / mood_reminder_notifier.dart:28 / badge_sync_service.dart:29 / home_care_engine_dispatcher.dart:47 / test/core/data/services/notification_id_band_round110_test.dart |
| B1-2 domain purity 3 处 (P1) | ✅ **已闭环** (R110 round 3): phone_validator→core/shared, FeatureFlags 构造注入, visibleForTesting→meta; `dart scripts/check_all.dart` 2/2 ✅ | check_all.dart 实测通过 / dispatch_safety_alert.dart (构造注入) |
| B1-3 sleep 线性 mean 算圆形时间 (P2) | ✅ **已闭环** (R110 round 7a): Mardia 圆形标准差, 23:50/00:10 交替 → 5 分 | sleep_calculator.dart:46+ |
| B1-4 MedicationTimes 无边界 (P2) | ✅ **已闭环** (R110 round 6): `HourMinute.safe()` clamp 0..23/0..59, 老数据/脏 import 不再错/吞 | medication_times.dart:30-34 / hour_minute.dart:25-30 |
| B1-5 死 userName 参数 (P3) | ❌ **未闭环 (跨期残留)** | 见 Findings B1-5 |
| B1-6 key 丢失无恢复 (P3) | ❌ **未闭环 (跨期残留)** | 见 Findings B1-6 |
| B1-7 assessment past-fireAt 无 follow-up (P2) | ✅ **已闭环** (R110 round 6): 过去 fireAt 不再静默丢弃, catch-up now+1h, 与 policy 语义对齐 | assessment_notifier.dart:59-87 |

## 验证健康项 (全绿)

- **14 DAO 全读**: watch/orderBy/limit 纪律正确, watchToday 入口单次 now; AssessmentDao `_rowToEntry` 3 分支容错 (null/JSON/R60 老格式 + R90 优先) + 解析失败走 swallowError 且不泄露 PII (R95 修)
- **16 repository impl 全读**: entity 翻译 1:1; `setActive`/`updateRefill` 事务内 read-modify-write; vent delete TOCTOU 事务修复 (R97-P1-3) 保留; treatment 写时 snapshot name 缓存
- **DateTime.now() 纪律**: lib/core/data + lib/domain 共 43 处, 全部单次调用模式 (函数入口取 now), 0 处同函数多调 race
- **0 处空 catch**: 全库唯一历史 `catch (e) {}` 已改 swallowError (app_database.dart:233 注释确认)
- **UTC 纪律**: export isoUtc 9 处统一 (export_orchestrator.dart:44); last_error_capture / swallow_log_sink / safety_config lastAlertAt 全 toUtc — R108 "audit log 跨时区漂移" 未复发
- **迁移链**: schemaVersion 22, v1→v22 全段 guard (`from == 1` / `from <= 16` / `from < 18-22` 模式) 正确; v8→v9 明文加密一次性迁移 + 单行失败 swallowError 不阻塞; v19 DROP content_text (PIPL §28)
- **web 端阻断**: connection/web.dart 抛 UnsupportedError (明文 IndexedDB 拒绝), main.dart runZonedGuarded 捕获
- **锁屏 PII**: notifMedicationBody 无药名/剂量 (R108 P0-3), safety_alert title 静态无名字 (R32), DarwinNotificationDetails 空构造 (R32), Android visibility secret (R32) — 全闭环
- **守门员实测**: check_all 2/2 ✅ + check_arb_keys / check_changelog / check_cross_feature / check_pii_in_title / check_usecase_layer / check_coverage / check_orphan_arb_keys 7/7 PASS (master 6bbb308 0.32.0+140)
- **测试规模**: test/ 295 文件 (domain 50 + data 43 + 其余), R110 新增 notification_id_band / B1-9/10/11 回归已入库

## 总结

1) **P0 级系统性 bug (B1-1 通知 ID 碰撞) 已闭环** — 5M+ 固定带 + 回归守卫, 基线 7 项 5 闭 2 留 (B1-5/B1-6 均 P3 卫生); 2) **新发现 2 个 P1**: export/import schema v4 落后 DB schema 22 (R101+ 字段换机静默丢失, E1) + contact consent 4 字段不导出致 PIPL §13 留痕断裂 (E2) — 建议 R111 优先修 (共用 export/import 路径, 可一次 v5 schema 升级 + round-trip test 闭环); 3) P2: checkIn.medicationId 导入孤儿 FK (E3); 4) P3: 死参数/死字段/assert 失效 3 处卫生项; 5) 其余全部干净 — DAO/repository 层纪律、UTC、DateTime race、空 catch、隐私边界均 0 违规。
