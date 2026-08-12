# superpowers-en 工程实践视角审计 (2026-08-13)

范围: 287 test 文件 / 420 非生成 lib 文件 ~90K 行。工作树 transient mid-R109, findings 标记 [TRANSIENT] 需 merge 后复验。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| SP-en-1 | test | **static_scale_translations 2× = 最大 0 测试块 (1591L)**: domain 781L + l10n 810L, 0 test 文件 | domain/entities/scale_translations/static_scale_translations.dart + presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart | ≤1w | **P0** |
| SP-en-2 | test | add_medication_page.dart 568L god class 0 test (R32 506→592→568) | pages/medication/add_medication_page.dart | ≤1w | **P0** |
| SP-en-3 | test | setup_page_state.dart 497L 4 步向导 0 test (RangeError 头号来源) | pages/setup/setup_page_state.dart | ≤1d | P1 |
| SP-en-4 | test | mood_trend_page.dart 558L 0 test, 9 个 i18n fail 关联 | pages/mood_list/mood_trend_page.dart | ≤1d | P1 |
| SP-en-5 | test | 6 个 ≥400L 页面/widget 0 test: vent_detail 426 / vent_list 406 / reminders_hub 481 / refill_manage 403 / assessment_widgets 429 / edit_medication_dialog 413 | presentation/pages/ | ≤1w | P1 |
| SP-en-6 | test | app_database.dart 513L schema 22 **无迁移测试** (7 DAO test 存在但无 app_database 级) | core/data/database/app_database.dart | ≤1d | P1 |
| SP-en-7 | test | aliyun_sms_provider_round57_test.dart.**disabled** 静默丢 SMS 覆盖率 | test/core/data/services/ | ≤0.5h | P1 |
| SP-en-8 | test | test:lib 映射仅 ~36% (151/420 stems), roundN 命名让真实覆盖率不可验证 | — | ≤1w | P2 |
| SP-en-9 | test | domain pure 覆盖强 (streak/safety_detector 等) vs presentation 28 页测试 vs 200+ 页文件 | — | >1w | P2 |
| SP-en-10 | tdd | [TRANSIENT] R32 "126 fail" (66 find.text 中文漂移 + 33 assertion + 8 RangeError) 需 R109 收尾复测 | — | — | **P0**(验证) |
| SP-en-11 | smell | **12 处 "Phase 5 再补" 硬编码 CJK** (medication 4 文件, en/zh_Hant 用户可见中文) | add_medication_page:237,316,459,506 / medication_calendar_page:95,151,204 / medication_detail_page:73,132,187 / refill_manage_page:146,210 | ≤1h | **P0** |
| SP-en-12 | smell | domain enum switch 无 default (新枚举静默 fallthrough) | assessment_comparison.dart:77 / care_copy.dart:34 / lost_contact_sms.dart:57 / safety_watch_service.dart:232,364 | ≤2h | P2 |
| SP-en-13 | smell | swallow_log_sink 全局可变 sink, 31 个 swallowError 调用点 | core/shared/swallow_log_sink.dart | ≤1d | P2 |
| SP-en-14 | smell | 5 处同函数多 DateTime.now() 窗口待审计 | app.dart:248-249 / trend_calculator.dart:94,121 / email_template.dart:98-99 / legal_page.dart:108-121 / encrypted_audio_storage.dart:122-133 | ≤2h | P2 |
| SP-en-16 | error | audio_lifecycle async-dispose 无 try/finally 包裹, 双重 dispose 风险 | presentation/widgets/audio_lifecycle.dart:354-423 | ≤2h | P2 |
| SP-en-18 | test | token 文件 0 lock-in test (app_colors 502L / app_motion 306L) | core/theme/ | ≤0.5h | P2 |

## 验证健康项 (R32 跨期已闭环)

spring.dart 已接线 · curveAppleSheet/Drawer 已删 · hero_illustration 已删 · 8 raw IconButton 全迁移 · catch(_){} ≈ 0 (31 swallowError 替代) · unawaited+catchError 纪律强 (26 处) · 守门员 check_changelog [OK] / check_orphan_arb_keys [OK] (R32 红 → 绿)

## God class 尺寸变化 (vs R32)

缩: medication_page 561→347 ✅ (脱离 400 线) / setup_page_state 560→497 / add_medication_page 592→568。平: static_scale 781/810 · mood_audio_recorder_widget 589 · mood_trend 558 · app_database 513 · legal 495 · reminders_hub 481 · home_page_state 468 · refill_manage 403。长: safety_watch_service 390→403。新上榜: vent_compose 445 / export_import_pipeline 416 / notification_status_card 413 / daily_tracking 403 / vent_list 406。**23 个 ≥400L 文件, ~15 个 0 专用测试**。

## 总结

1) TDD 结构健康但 15+ god class 0 test = R32 P0 积压未动; 2) 126 fail 是 #1 待验证项 (transient); 3) 纪律真实改善 (catch/排序/ID 范围/unawaited); 4) 残留 smell: enum default / swallow sink / now() 窗口 / token 无 test; 5) aliyun_sms test 被 disabled 是静默覆盖率洞 (P1 0.5h)。