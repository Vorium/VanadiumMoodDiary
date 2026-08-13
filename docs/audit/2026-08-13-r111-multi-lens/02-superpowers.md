# superpowers 工程实践视角审计 (2026-08-13, R111)

> 覆盖 superpowers-en (工程/TDD) + superpowers-zh (docs/i18n/卫生) 两个子视角。
> 基线: `docs/audit/2026-08-13-multi-lens/02-superpowers-en.md` (SP-en-01~18) + `03-superpowers-zh.md` (SP-zh-01~20)。
> 对象: master `6bbb308` (0.32.0+140 round 7b-6, working tree 干净)。纯只读, 未修改任何文件。

## 基线 → 现状

R110 审计后 R111 前共 20 commit (round 7a + round 7b-1~6 + R110 round 4-6), 核心是 **round 7b 系列 6 个 god class 补测试** (+42 test) + R110 round 5/6 收口残余 fail (8→4)。**SP-en-10 已验证闭环**: 全量 `flutter test` 实测 2311 pass / 4 fail / 1 skip, 4 fail 全部是 iOS 资产占位 (app_icon_size + launch_image_size ×3, 设计师外部依赖, 非代码)。**test:lib 映射从 36% 提升到 55%** (233/419 stems)。

## Findings

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| SP-111-01 | **test 有效性** | **round7b 新测试自带 override 失效 warning**: `_NoopNotificationService.scheduleDailyReminder` @override 无效 (R108 delegate 拆分后 NotificationService 已无此方法, 见 notification_service.dart:319 走 `delegate.scheduleDailyReminder()`), 全仓共 10 个 test fake 同款死 @override (setup_round14/18/77 / reminders_hub_round12c / refill_manage_round13a / medications_list_split_round45d / add_medication_page_round7b / edit_medication_dialog_round7b) | add_medication_page_round7b_test.dart:38:16 / edit_medication_dialog_round7b_test.dart:34:16 / flutter analyze 27 warning | ≤0.5h | **P1** |
| SP-111-02 | **analyzer 门禁** | **27 warning / 112 info (0 error) 违反 AGENTS.md "必保 0 warning"**: 12 unused import (含 round7b 新 test 1 处 + add_medication_page.dart 2 处) + 3 unused field (safety_watch_service._smsService/_notificationService / safety_alert_sender_impl._builder) + unnecessary_non_null_assertion + 非 const codePoint | `flutter analyze` 实测 139 issues | ≤1h | **P1** |
| SP-111-03 | test | round7b 新测试的 3 类 info 质量债: mood_audio_recorder_round7b close_sinks (StreamController 未 close) + annotate_overrides; vent_detail_page_round7b `audioplayers_platform_interface` 非 pubspec 直依赖 (depend_on_referenced_packages ×3); add_medication_page_round7b unawaited_futures | mood_audio_recorder_round7b_test.dart:32-33 / vent_detail_page_round7b_test.dart:16-20 / add_medication_page_round7b_test.dart:79 | ≤0.5h | P2 |
| SP-111-04 | test | **static_scale_translations 仍 0 专用测试 (781L domain + 810L l10n)**: round78 只断言 PHQ-9/GAD-7 经 translations 的中文 (含 8 新量表 name/shortDescription/instruction 走 l10n + item stub ''), 但 **domain 层 8 新量表真实中文 items (isiItemsZh 等 const 数组) 0 直接断言** | domain/entities/scale_translations/static_scale_translations.dart:243 / l10n stub 810L / round78_test 仅 phq9/gad7 | ≤1d | **P1** |
| SP-111-05 | test | **app_database 513L 仍无真实迁移 dry-run**: round37 只验 schemaVersion==22 + onUpgrade 可调用 + 21 steps 数量 + 12 关键列 raw query, 注释自认 "完整 SQLite dry-run 从 v1 模拟升级太重, 留给未来补" (SP-en-6 部分闭环) | test/data/database_migration_round37_test.dart:16-20 | ≤1d | P1 |
| SP-111-06 | test | setup_page_state 497L 无单测: round77 集成测覆盖 4 step 状态机 (8 case), 但 state 类本身 (表单验证/进度推进/跳转) 0 直接测试 | setup_page_round77_test.dart / pages/setup/setup_page_state.dart | ≤1d | P2 |
| SP-111-07 | usecase | **usecase 层厚化 0 进展 (R110 AR-4 P0 跨期残留)**: 仍 6 文件 736L, R110 路线图目标 14-16; `_NoOpSafetyAlertSender` 命名违规被 check_usecase_layer 标 warning | lib/domain/usecases/ / dispatch_safety_alert.dart / AGENTS.md:461 | 1-2d | **P1** |
| SP-111-08 | 迁移 | schemaVersion 22 升级 (R109 round 6 18→22) 后无新迁移测试, round37 的 "21 steps" 断言是 hand-count, 未跟 app_database.dart 迁移 block 自动比对 | database_migration_round37_test.dart:62-70 / app_database.dart | ≤2h | P2 |
| SP-111-09 | docs 滞后 | **AGENTS.md:136 "2019 cases" 仍过时** (实测 2311 pass), AGENTS.md:443 "15+ god class (≥400L) 0 test" 已过时 (round7b 后仅剩 4-5 个) | AGENTS.md:136,443 vs flutter test 实测 | ≤0.5h | **P1** |
| SP-111-10 | **死链** | **README 3 处死链**: r95-increment 2 报告已归档到 audit-history 未改 (README.md:212-213), 且 README:214 引 `VERSION_1.0_PLAN.md` (下划线) 实际文件是 `VERSION_1.0_PLAN.md` (点) | README.md:212-214 | ≤0.5h | P2 |
| SP-111-11 | 死链 | **CHANGELOG 11 处死链** (audit-archive-2026-08-10 / audit/2026-08-10-cleanup / reviews/ 全归档未改) + **VERSION_1.0_PLAN.md 21 处死链** (docs/audit/2026-08-06~09 全移 audit-history 未改, 含 decisions/v0.30_round95) | docs/CHANGELOG.md / docs/VERSION_1.0_PLAN.md | ≤1h | P2 |
| SP-111-12 | i18n | **SP-zh-17 跨期残留**: home_header `_formatDate` 硬编码 `年/月/日` 无 en 分支, 0 ARB key | home_header.dart:108-110 | ≤0.5h | P2 |
| SP-111-13 | smell | swallow sink 体系仍 31 调用点 (SP-en-13 跨期残留), 文件已改名 swallow_error.dart + swallow_log_sink.dart; notification_service.dart:35 unused import 指向 swallow_error.dart = R110 重构残留 | core/shared/swallow_error.dart / core/data/services/swallow_log_sink.dart | ≤1d | P2 |
| SP-111-14 | test | reminders_hub_page 487L 只有 round12c 老测试 (167L, 5 卡片渲染), 新增的 safety 卡 gate (R110 round 3) 0 测试 | reminders_hub_round12c_test.dart / reminders_hub_page.dart | ≤2h | P2 |
| SP-111-15 | docs | SP-zh-12 跨期残留: 2026-08-11-cleanup 报告文件名 R110/内容 R109 漂移未修 (P3) + SP-zh-19 20 处 dev 中文未复审 (P3) | docs/audit/2026-08-11-cleanup/ | ≤0.5h | P3 |
| SP-111-16 | 守门员 | check_usecase_layer 1 warning 长期未清: `_NoOpSafetyAlertSender` 不满足 UseCase/Policy/… 命名规范 (21 守门员中唯一红 warning) | lib/domain/usecases/dispatch_safety_alert.dart / check_usecase_layer.py | ≤0.5h | P2 |

## 守门员实测 (2026-08-13, master 6bbb308)

**20/21 跑了, 全绿** (check_16kb_alignment 需 build, 按 AGENTS 记为 1 skip):

| 脚本 | 结果 |
|---|---|
| check_arb_keys | [OK] zh/en/zh_Hant 1241 key 100% parity |
| check_orphan_arb_keys | [OK] 1241 key, 0 orphan |
| check_changelog | [OK] pubspec 0.32.0+140, 83 段顺序正确 |
| check_cross_feature | [OK] 138 files, 0 violations |
| check_strings_hardcoded | [OK] 规则 1 = 34 处 (全 R57 override 配对), **规则 2 inline = 0 处** (SP-zh-16 闭环) |
| check_usecase_layer | ✅ 0 error / **1 warning** (_NoOpSafetyAlertSender 命名) |
| check_pii_in_title | [OK] 锁屏 title 0 PII |
| check_zh_hant_consistency | [OK] 1241 keys 繁简 100% (OpenCC s2tw) |
| check_datetime_race / race2 | 0 / 0 (SP-en-14 闭环) |
| check_drift_namespace | [OK] 13 tables, 0 dup |
| check_no_hardcoded_utc / no_pua / widget_dispose / legal_consent / fullwidth / sms_release_ready | 全 [OK] |
| check_coverage | [PASS] 18 gatekeeper 全过 (streak 96.4% / sms 76.4% / notification 53.9%) |
| check_apple_health_claim | [OK] 0 假声明 |
| dart scripts/check_all.dart | ✅ 2/2 通过 (purity + consistency) |

**补充实测**: `flutter test` = 2311 pass / 4 fail (全 iOS 资产占位) / 1 skip; `flutter analyze` = **0 error / 27 warning / 112 info** (warning 非零, 违反 0-warning 门禁); aliyun_sms_provider_round57_test = 7 test pass (SP-en-7 闭环, R110 round 6 复活); round7b 新增 42 test 全部 pass。

## R110 跨期残留验证

**已闭环 (13/20)**: SP-en-2 (add_medication 6 test) ✅ / SP-en-4 (mood_trend 6 test) ✅ / SP-en-5 部分 (assessment_widgets 11 + edit_medication_dialog 8 + vent_detail 5 已补) ✅ / SP-en-7 (aliyun 复活) ✅ / SP-en-10 (126 fail → 4 资产 fail) ✅ / SP-en-11 (12 处硬编码 → 0) ✅ / SP-en-14 (datetime race 0) ✅ / SP-en-16 (audio_lifecycle try/catch + round108 test) ✅ / SP-zh-01 (schemaVersion 22) ✅ / SP-zh-03~07 / SP-zh-08 (R32 报告入库) ✅ / SP-zh-09 (.bak 0, worktree 仅 master) ✅ / SP-zh-13 (working tree 干净) ✅ / SP-zh-15+16 (12 处硬编码 + inline 守门员) ✅

**部分闭环 (4)**: SP-en-1 (round78+round95 lock-in 补了 PHQ/GAD + 8 新量表 name, 但 domain 8 新量表 items 0 断言 → SP-111-04) / SP-en-6 (round37 invariant, 无真实 dry-run → SP-111-05) / SP-en-8 (36%→55%) / SP-zh-20 (PHQ-9/GAD-7 已 i18n, 8 新量表仍 stub)

**未闭环跨期残留 (7)**: SP-zh-02 (AGENTS 2019 cases → SP-111-09) / SP-zh-17 (home_header 日期 → SP-111-12) / SP-en-13 (swallow sink → SP-111-13) / SP-en-12 (enum switch 无 default — Dart 3 exhaustive 编译器已强制, 自动缓解, 降 P3) / SP-en-18 (app_colors 502L 无直接 lock-in test, 仅间接引用) / SP-zh-12 (文件命名漂移) / SP-zh-19 (dev 中文)

**R110 AR-4 (usecase 厚化 6→14-16) = P0 顶层项, 0 进展** → SP-111-07。

## 总结

1) **TDD 纪律真实改善**: round 7b 系列 6 个 god class 补 42 test 全 pass, god class "0 专用测试" 从 ~15 缩到 ~4-5, test:lib 映射 36%→55%, 126 fail 收口到 4 个资产占位 (外部依赖)。
2) **#1 新问题 = analyzer 27 warning**: 其中 10 个 test fake 的 `@override scheduleDailyReminder` 在 R108 delegate 拆分后失效 (死代码 + 测试有效性隐患), round7b 新测试自带 6 处 warning/info 债 — 违反 AGENTS.md "必保 0 warning" 门禁, ≤1h 可清。
3) **最值得修 3 件事**: ① 清 27 warning (含 10 处死 @override fake, 0.5-1h); ② static_scale_translations 8 新量表 domain 中文 items 补直接断言 (≤1d, 堵最大 0-test 块); ③ 修 32 处死链 (README 3 + CHANGELOG 11 + VERSION_1.0_PLAN 21, ≤1h) + AGENTS.md 3 处过时数字 (2019 cases / 15+ god class 0 test / usecase 6→14-16 未动)。
4) 正面: 21 守门员 20 实测全绿 (唯一 warning 是 usecase 命名), 架构纯度 2/2, i18n 3 语 1241 key 100% parity, 迁移 invariant 有覆盖但真实 dry-run 仍是债。
