# 顶层架构视角审计 (2026-08-13, R111)

基线: 421 dart / 90,303L (R110: 421 / 89,984L, +319L)。实测 `dart scripts/check_all.dart` (直接 dart 跑) **0 violation 通过** (R110 3 违规已修), `python scripts/check_cross_feature.py` 138 文件 0 violation, `flutter analyze` 0 error / 0 warning / 139 info, `python scripts/check_coverage.py` 18 gatekeeper PASS, 295 个 test 文件。

## 架构健康度分项打分 (0-10)

| 维度 | 分数 | 说明 |
|---|---|---|
| 纯度 (check_all) | 10/10 | AR-1 3 处违规全修, 守门员恢复可信任 |
| 一致性 (entity↔table) | 10/10 | 1:1 无漂移 |
| usecase 层 | 3/10 | 仍 6 文件/736L (R110: 731L), 6→14-16 计划 0 进展; 编排仍在 data services |
| god class 拆解 | 4/10 | 22 个 ≥400L (R110 "15+"), 仅 medication_page 553→347 拆成; 6 个补 test 但多数反涨 |
| l10n 循环 (AR-2) | 2/10 | 4 个 data 文件仍 import 生成 ARB → pub workspace 仍死锁 |
| feature-first 前置 | 1/10 | 无 lib/features、无 pub workspace, 前置 2 项未满足 |
| 仓库层 17:17 | 10/10 | impl ≤182L 薄 mapper, 健康 |
| core/shared 中性 | 5/10 | swallow_error 134 处跨层 sink; consent_gate 仍 shared 持 domain 概念 |

加权综合 ≈ **6.0/10** (纯度/一致性满血, 结构重组 0 进展 — 与 R110 相比仅 +0.2 来自守门员转绿与 medication_page 拆成)。

## Findings

| ID | 类别 | 标题 | 证据 (file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| AR-15 | 边界 | **check_all 已转绿 — R110 3 处 purity 违规确认闭环** (phone_validator→core/shared / FeatureFlags 构造注入 / visibleForTesting→meta) | `dart scripts/check_all.dart` 0 violation; core/shared/phone_validator.dart 存在; safety_alert_policy.dart:5 构造注入 | ≤1h | ✅ |
| AR-16 | 边界 | **AR-2 跨期残留: 4 个 data 文件仍 import 生成 ARB** — pub workspace 死锁未解 | safety_watch_service.dart:17 / preset_medication_templates.dart:3 / cbt_thought_record_pdf.dart:22 / cbt_thought_record_pdf_layout.dart:20 | 1wk | **P0** |
| AR-17 | 内聚 | **scale_translations 三源仍在, 且 l10n impl 810L 0 运行时 caller** — 只被 test/domain/scale_translations_round78_test.dart 引用; 活跃路径全走 static 781L (phq9/gad7/whodas/level2_* 默认注入); R90 stub 返 `''` 空壳 | domain/entities/scale_translations/static_scale_translations.dart 781L / presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart 810L / scale_translations.dart 208L | 2-3d | **P0** |
| AR-18 | usecase | **AR-4 跨期残留: usecase 6 文件/736L 未厚化** (计划 14-16); 编排仍在 safety_watch_service 403L / refill_notifier 214L / home_care_engine_dispatcher 176L / streak 在 shared_providers.dart:46-60; schedule_assessment_reminder.dart 0 直接测试 | domain/usecases/ + 上述 | 1-2wk | **P0** |
| AR-19 | 内聚 | **AR-5 跨期残留: saveSetup (1 tx 写 4 实体 + consent assert, :420-490) + clearAllUserData (:504-510) 仍在 AppDatabase** — 513L (R110 494L), 文件注释明示刻意保留 | app_database.dart:410-510 | 3-5d | P1 |
| AR-20 | 尺寸 | **god class 22 个 ≥400L (R110 "15+" 反涨), 仅 medication_page 553→347 拆成**; 7b round 给 6 个 god class 补 test 是好路径 (add_medication 6 / edit_medication 8 / assessment_widgets 11 / mood_audio_recorder 6 / mood_trend 6 / vent_detail 5), 但拆解 0 进展且多数反涨: safety_watch_service 338→403 / static_scale_translations 659→781 / legal_page 460→495 / reminders_hub 441→487 / mood_trend 517→558 / app_database 494→513 / add_medication 568→573 | find lib -name "*.dart" \| wc -l 全表 | 1-2mo | P1 |
| AR-21 | 尺寸 | **app_colors.dart 502L 新 god class** (R31 Apple Health token 集中器, 纯色值表) — 低风险但含 8 metric palette, 可拆 data 文件或生成 | lib/core/theme/app_colors.dart | ≤2h | P2 |
| AR-22 | 耦合 | **AR-7 跨期残留: core/routing 11 文件 1054L 仍是 presentation 依赖者** (import 全部 pages + app_shell.dart:11 theme_toggle_button) — "core" umbrella 名不副实持续 | core/routing/app_route_*.dart / app_shell.dart:11 | 1wk | P3 |
| AR-23 | 内聚 | **AR-10 部分残留: swallow_error 全局 sink 134 处调用** (audio_lifecycle 20 / mood_audio_recorder 10 / mood_audio_service 8 / vent_compose 7...); consent_gate 仍 shared 持 domain 概念 (fire_care_strategy.dart:143 由 caller 注入 — 方向已 OK); date_utils 已纯化 0 import | core/shared/swallow_error.dart + 134 call sites | 3-5d | P1 |
| AR-24 | 边界 | ✅ 跨 feature 隔离保持 0 violation (138 文件), vent 仅路由引用 | check_cross_feature.py | — | ✅ |
| AR-25 | 耦合 | ✅ 仓库层 17 abstract ↔ 17 impl 1:1 healthy, impl 总 1246L / 13 文件 (daily_tracking 6 impl 同目录) | grep implements | — | ✅ |
| AR-26 | 内聚 | AR-13 残留: 18 个 provider 文件 2002L composition root 仍散 (legal_consent 291 / mood_list_filter 247 / cbt 239) | presentation/providers/ | 1-2d | P3 |
| AR-27 | 测试 | 新: check_usecase_layer 有 1 warning — dispatch_safety_alert.dart 内部类 `_NoOpSafetyAlertSender` 命名不符 R109 规范 (info 级, 0 error) | scripts/check_usecase_layer.py 输出 | ≤1h | P3 |
| AR-28 | 边界 | 新: check_in_usecases.dart import core/shared/date_time_resolver — domain→shared 方向被 check_all 放行 (shared 跨层设计使然), 但与 AR-14 3 包切法 (pkg_domain 含 shared) 兼容, 记录即可 | domain/usecases/check_in_usecases.dart:11 | — | P3 |

## R110 跨期残留验证

| AR | R110 状态 | R111 实测 | 结论 |
|---|---|---|---|
| AR-1 purity 3 处 | 待修 | check_all 0 violation | ✅ 闭环 |
| AR-2 data→ARB 循环 | P0 | 4 文件原样 | ❌ 跨期残留 |
| AR-3 scale_translations 三源 | P0 | 三源仍在 + l10n impl 810L 0 运行时 caller | ❌ 跨期残留 (恶化: 确认死代码) |
| AR-4 usecase 薄 | P0 | 6 文件 736L, 计划 14-16 未动 | ❌ 跨期残留 |
| AR-5 saveSetup/clearAllUserData | P1 | app_database:420-510 原样, 文件 494→513 | ❌ 跨期残留 |
| AR-6 god class 15+ | P1 | 22 个, 仅 medication_page 拆成 (553→347) | ⚠️ 部分进展 (测试先行, 拆解 0) |
| AR-7 routing 依赖者 | P3 | 原样 1054L | ❌ 跨期残留 |
| AR-8 跨 feature | ✅ | 0 violation | ✅ 保持 |
| AR-9 DRY | P2 | phone_validator 已移 shared; 日期 3 套 / snackbar 2 套仍存 | ⚠️ 部分 |
| AR-10 shared 不中性 | P1 | swallow_error 134 处; date_utils 已纯化 | ⚠️ 部分 |
| AR-11 day_detail 395 | P3 | 未拆 (3 class 同文件) | ❌ 跨期残留 |
| AR-12 仓库 17:17 | ✅ | 1:1 healthy | ✅ 保持 |
| AR-13 providers 18 文件 | P3 | 原样 2002L | ❌ 跨期残留 |
| AR-14 feature-first/workspace | P2 | 无 lib/features / 无 pub workspace, 前置 AR-2 未修 | ❌ 跨期残留 |

## 重构路线建议 (按风险调整价值排序)

1. **AR-17 scale_translations 合一 (2-3d, 纯 ROI 最高, 本批可做)**: 每量表 1 数据源; 810L l10n impl 已确认 0 运行时 caller — 先删死代码或并入 static (保留 1 个 source of truth), 删 R90 空 stub。−1,590L 重复面。
2. **AR-18/AR-19 usecase + DB 编排下沉 (1-2wk)**: 抽 SetupService / DataWipeService (2 usecase); safety_watch_service 的决策→usecase, service 变 orchestrator (403L→薄); refill 调度规则入 usecase; streak provider 计算入 domain logic。usecase 6→12+, god class −4。
3. **AR-20 god class 拆解接力 (1mo)**: medication_page 已示范拆法 (553→347 + 15 widgets 子文件); 按 7b 模式先补 test 再拆: setup_page_state 497 / add_medication 573 / mood_audio_recorder_widget 589 / mood_trend 558。
4. **AR-16 l10n 循环解锁 (1wk)**: 4 个 data service 的 AppLocalizations → 可注入 NotificationStrings/MedString (core/l10n/strings.dart 既有模式), 之后 pub workspace 才不死锁。
5. **AR-23 swallow_error 治理 (3-5d)**: 全局 sink 134 处 → 分层: audio/vent/mood 各自带 scope 的 error sink, release 只留 debug 日志。
6. **AR-22 routing + AR-26 providers (1-2wk, 最后)**: routing 变纯配置 (pages import 移入各自 feature), providers 按 feature 聚合; 之后 feature-first 物理重组 (lib/features/) 才是纯 move。

## 总结

纯度与一致性满血回归 (check_all 0 violation 恢复守门员可信任), 跨 feature 隔离与仓库 17:17 保持健康 — **边界层 8.5/10, 结构层 4/10**。R110 的 P0 项 (AR-2 l10n 循环 / AR-3 scale_translations / AR-4 usecase / AR-5 DB 编排) 四项全数跨期残留, god class 不降反涨 (22 个, 唯一亮点是 medication_page 553→347 拆成 + 7b round 为 6 个 god class 补 test 验证了"先测试后拆解"路径可行)。加权综合 ≈ 6.0/10 — 与 R110 持平略升, 架构的"健康"在边界守护, "债"在结构重组 — 后者的成本随时间 (每个反涨的 god class) 复利增长, 建议 R111 优先做 AR-17 (2-3d 删 1,590L 重复) + AR-18/19 (1-2wk 收 usecase/DB 编排) 两个高 ROI 项。
