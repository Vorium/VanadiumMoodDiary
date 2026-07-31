v0.27 round 65: 4 sub-agent 并行修 7 视角审视 ⏳ 项 + R65 收尾

A1 use case 层补 + app_database 32 facade 委派清理 (spen + alibaba 共识)
============================================================

任务 A (sub-agent A, M 难度):

A1 use case 层补 — 3 个 use case 抽离 (presentation 不再 import data/services):
- lib/domain/usecases/fire_care_strategy.dart (FireCareStrategyUseCase 4 strategy 评分, 返 5 值 FireCareDecision)
- lib/domain/usecases/check_safety.dart (CheckSafetyUseCase 包装 SafetyDetector.detect, 8 sealed decision)
- lib/domain/usecases/schedule_refill_reminder.dart (ScheduleRefillReminderUseCase 给 medications 算 fire time)
- 3 个 use case test (test/domain/usecases/*_round65_test.dart) 各 5 case (deterministic + 边界)

app_database 32 行 facade 委派清理 (spen P1-11):
- 删 app_database.dart line 264-316 全部 (7 section header + 32 method)
- 8 lib 文件 + 10 test 文件 94 处 caller 改成 _db.xxxDao.xxx() / db.xxxDao.xxx()
- saveSetup + clearAllUserData 业务编排保留
- 32 行委派 (line 264-316 段)

任务 B (sub-agent B, M 难度):

notification_service 250 行 facade 收尾 (spen P1-12):
- 抽 lib/core/data/services/safety_alert_builder.dart (121 行) SafetyAlertBuilder 纯函数类
- notification_service.dart showSafetyAlert 50 → 28 行 (纯实现 19 行)
- 9 case TDD test (test/core/data/services/safety_alert_builder_round65_test.dart)

app_tokens 644 行 god constant 拆 4 文件 (alibaba P2):
- 拆 lib/core/theme/app_colors.dart (223) / app_typography.dart (190) / app_spacing.dart (130) / app_motion.dart (221)
- app_tokens.dart 644 → 206 行 re-export facade 形式 (89 caller 1238+ AppTokens.xxx 用法零改动)
- 4 文件每个 < 250 行 ✓

任务 C (sub-agent C, M 难度):

IAP StoreKit 集成 (appstore P0-4):
- pubspec.yaml 加 in_app_purchase: ^3.3.0 (latest stable)
- 新建 lib/core/data/services/store_kit_service.dart (122 行) 封装 isPro / buyLifetime / warmup
- 新建 lib/presentation/providers/iap_provider.dart (64 行) Riverpod 3.x IapNotifier
- 改 main.dart bootstrap 加 await StoreKitService.warmup()
- 改 settings_page.dart 加 Pro 升级卡片 + 已购状态卡 + 6 个新 i18n key (zh/en/zh_Hant)

fastlane/metadata/android/ 22 文件 (googleplay P0-3):
- en-US/ + zh-CN/ 各 title.txt / short_description.txt / full_description.txt / video.txt / icon.png / feature_graphic.png / phone_screenshots/4 张 PNG
- 双语精神心理患者 + 失联通知卖点
- 截图是 mock PNG 占位 (实际截图留待设计师 v0.28)

9 处 ElevatedButton 迁 FilledButton (flutter L10):
- 新建 lib/presentation/widgets/primary_button.dart (65 行) PrimaryButton 包 FilledButton 集中器
- 9 处迁: assessment_page × 3 / setup_step_consent / setup_step_welcome / setup_step_medication / setup_step_done / empty_state / choose_window_dialog
- 3 个老 test 更新 + 4 case TDD test

3 处 withValues(alpha:) 抽 token (emil/alibaba P2):
- AppMotion.scrimAlpha = 0.54 (medication_report_dialog)
- AppColors.tintedStatusSoft(ctx, base) = 0.15 (refill_manage_page × 2)
- AppColors.tintChartLine(ctx, base) = 0.6 (assessment_widgets)
- 加到 R65 拆出去的子文件

任务 D (sub-agent D, M+L 难度):

5 文件 i18n 化 (spzh P2, 40 个新 i18n key):
- lib/core/data/utils/phone_validator.dart 抽 regionDisplayName(int, {override}) helper
- lib/core/data/services/preset_medication_templates.dart MedicationTemplate data class + 18 个 i18n key
- lib/domain/entities/check_in_entity.dart CheckInType.label(l10n) + 4 个 i18n key
- lib/domain/logic/day_detail.dart 抽 _renderCheckInLabel helper + 6 个 i18n key
- lib/domain/entities/vent_entry_entity.dart durationLabel(l10n) + 3 个 i18n key

量表 PHQ-9/GAD-7 i18n 起步 (spzh P1-A, L 难度):
- 抽 lib/domain/entities/scale_translations.dart abstract class
- 抽 lib/l10n/scale_translations_impl.dart AppLocalizationsScaleTranslations
- AssessmentScale 加 translations 字段, Phq9Scale + Gad7Scale 注入
- displayName 走 ARB, 4 个新 scaleHotline key
- detectCrisis 16 题全文 i18n 化留 R65b (本批只做基础设施)

R65 收尾:
- lib/l10n/app_zh_Hant.arb 2 处"進階" → "高級" 修 (check_zh_hant_consistency 通过)

结果:
- 1232/1232 tests pass (R64 1178 + R65 +54)
- flutter analyze 0 error
- 15 Python 守护全绿 (含 check_zh_hant_consistency 繁简 620 key 100% 一致)
- check_all.dart 4 层架构 + 一致性双绿
- pubspec.version 0.27.0+63 (R65 不 bump, 等 v0.28 上架时再 bump)
