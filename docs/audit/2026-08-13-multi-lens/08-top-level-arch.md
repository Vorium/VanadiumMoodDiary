# 顶层架构视角审计 (2026-08-13)

实测: 421 dart / 89,984L (domain 9,959 / core.data 20,577 / presentation 34,686 / theme+routing+shared ~4.5K)。跑了 `dart scripts/check_all.dart` (3 违规)。

## A. Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| AR-1 | 边界 | **check_all 现运行 FAIL — 3 处真实 purity 违规, "100% purity" 声称已 stale** | setup_welcome_form_validator.dart:16 → core/data/utils/phone_validator / safety_alert_policy.dart:14 → core/data/feature_flags / schedule_assessment_reminder.dart:15 → flutter/foundation | ≤1h | **P0** |
| AR-2 | 边界 | **data→presentation l10n: 4 个 data 文件 import 生成 ARB (→flutter/widgets+flutter_localizations) = pub workspace 循环阻塞** | safety_watch_service.dart:17 / preset_medication_templates.dart:3 / cbt_thought_record_pdf.dart:22 / cbt_thought_record_pdf_layout.dart:20 | 1wk | **P0** |
| AR-3 | 内聚 | **scale_translations 三源: zh fallback 781L + AppLocalizations impl 810L + abstract 208L; 0 test; domain 781L 0 caller** | domain/entities/scale_translations/static_scale_translations.dart / presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart | 2-3d | **P0** |
| AR-4 | usecase | **usecase 层薄: 6 文件/731L (声称 8), 编排仍在 data services + presentation** (safety_watch_service 403L / notification_service rescheduleAll / refill_notifier 214 / reminder_scheduler 232 / home_care_engine_dispatcher 176 / streak 在 shared_providers:60) | domain/usecases/ + 上述 | 1-2wk | **P0** |
| AR-5 | 内聚 | AppDatabase 保存业务编排: saveSetup (1 tx 写 4 实体, :420-504) + clearAllUserData (:504+), 513L 文件还混 13 DAO + 迁移梯 | app_database.dart | 3-5d | P1 |
| AR-6 | 尺寸 | 15+/23 个 ≥400L god class 0 test, 多数相对 R32 不动或反涨 | 见 SP-en god-class 表 | 1-2mo | P1 |
| AR-7 | 耦合 | **core/routing 是 presentation 依赖者** (import 所有 pages + theme_toggle_button); 158 文件 import core/theme → routing 必须进 ui package; "core" umbrella 名不副实 | core/routing/app_route_*.dart 11 文件 1041L / app_shell.dart:11 | S | P3 |
| AR-8 | 边界 | ✅ 跨 feature 隔离干净 (仅 hub home/settings 跨; vent 仅路由引用; export 读 vent = PIPL 用户自数据, 建议 check_cross_feature 标记为 sanctioned exception) | 12 feature 全分析 | — | ✅ |
| AR-9 | DRY | 日期格式化 3 套 (DailyTrackingTimeFormat vs Formatters vs 各 widget _formatTime); 13 raw SnackBar vs 29 AppSnackBar; PhoneValidator 268L 与 setup validator 意图重复 | 多处 | 2-3d | P2 |
| AR-10 | 内聚 | **core/shared 不中性**: consent_gate→care_engine / date_utils→safety_detector / swallow_error 全局可变 sink 30 文件用 | core/shared/* | 3-5d | P1 |
| AR-11 | 尺寸 | domain/logic chunky 但纯: day_detail 395 / safety_detector 316 / medication_report 280 / assessment_comparison 274 / trend_calculator 264 (day_detail 需拆) | wc | S | P3 |
| AR-12 | 耦合 | ✅ 仓库层 17 abstract ↔ 17 impl 1:1 healthy, impl ≤182L 薄 mapper | grep implements | — | ✅ |
| AR-13 | 内聚 | 18 个 provider 文件 (composition root 散, 291L legal_consent / 247L mood_list_filter) — 文件散, 语义全暴露 domain 接口 | presentation/providers/ | S | P3 |
| AR-14 | 耦合 | feature-first 可行, **pub workspace 需 3 前置**: (a) AR-2 l10n 循环 (b) domain→shared+l10n 21+ 文件 (c) theme→shared; 3 包切法 = pkg_domain(domain+shared+l10n) / pkg_data(core/data minus l10n consumers) / pkg_ui(theme+routing+presentation+l10n) — AR-2 修后无环 | import graph | 2-3wk | P2 |

## B. 重构路线 (按风险调整价值排序)

1. **AR-1 (小时级, 先做)**: PhoneValidator (纯 268L) + FeatureFlags (编译期常量) 移 core/shared; visibleForTesting → package:meta。check_all 转绿 = 前置守门恢复可信任。
2. **AR-5+AR-4 核心 (1-2wk)**: SetupService + DataWipeService 抽出 → domain/usecases; home_care_engine_dispatcher 决策逻辑 + refill 调度规则入 usecases; safety_watch_service 变薄 orchestrator (CheckSafety/DispatchSafetyAlert usecase 已存在)。usecase 6→14-16, data 层机械化, god class -3。
3. **AR-3 scale_translations 合一 (2-3d, 纯 ROI 最高)**: 每量表 1 个数据源, domain 抽象, 单一生成 impl 喂 fallback + AppLocalizations; 删 781L 死 copy; +25 test。−1,500L 重复面。
4. **AR-2 l10n 循环解锁 (1wk)**: 4 个 data service 的 AppLocalizations 引用 → 可注入 NotificationStrings/MedString (经 core/l10n/strings.dart 既有模式)。
5. **Top-5 god class 拆 + 测试 (1mo)**: setup_page_state 497 (RangeError 源) / add_medication 568 / mood_audio_recorder_widget 589 / mood_trend 558 / app_database 余量。controller 抽取 + ≥5 test 每文件。
6. **AR-10 shared 分区 + AR-9 DRY (1wk)**: 拆 pure vs domain-adjacent; consent_gate 解耦 care_engine; date_utils 解耦 safety_detector; swallow_error → actor/isolate sink; 日期 unified Formatters; snackbar unified AppSnackBar。
7. **Feature-first 物理重组 → pub workspace (2-3wk, 最后)**: 1-6 后无环; lib/features/{feature}/{domain,data,presentation}/ 纯 move (双守门员验证); 再拆 3 包 (theme+routing 留 ui)。时间受限则只做物理重组得 80% 价值。**AR-2 前不要做 workspace, 会在 l10n 环死锁。**

## 验证闭环

每项: `dart scripts/check_all.dart` (现红, item 1 转绿) + `python scripts/check_cross_feature.py` + flutter analyze 0 err + flutter test (R109 收尾后 i18n fail 同步修)。