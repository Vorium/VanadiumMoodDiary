# 慢性照护项目 · 多视角综合审计报告 (7 视角)

> **审计日期**: 2026-08-18
> **项目版本**: chroniccare 1.1.0+185
> **代码量**: lib/ 633 dart, 200+ 测试, 58 守门员, 21 round 编号迭代
> **近期变更**: 322 文档删除 + 12 文件重建 (commit `b2d9744f` + `154f7787`)
> **审计模式**: 7 视角并行深度只读扫描

---

## 7 视角评分总览

| 视角 | 评分 | P0 | P1 | P2 | P3 | 关键发现 |
|---|---|---|---|---|---|---|
| **emil-kowalski** (设计哲学) | **8.6/10** | 0 | 2 | 6 | 8 | 业内 reference-grade, 剩余 P2/P3 微调 |
| **superpowers** (TDD/质量) | **6/10** | 2 | 4 | 4 | 2 | 47 lock-in tests / encryption_service HMAC / healthkit import |
| **flutter-audit** (规范) | **8.6/10** | 0 | 6 | 12 | — | 4 大支柱健全, 剩 module-first 残留 |
| **gdc** (决策严谨) | **4/10** | 3 | 3 | 2 | 2 | **322 文件删除 0 风险评估 (致命)** |
| **AppStore** (iOS 上架) | **3/10** | **5** | 3 | 4 | 5 | 截图/域名/联系信息 5 项 P0 硬阻断 |
| **Google Play** | **5.5/10** | **1** | 6 | 6 | 4 | 域名+ICP + Data Safety + 5 厂商 push |
| **Apple Health** (集成) | **2/10** | 0 | 5 | 5 | 3 | 视觉 9/10 + 集成 0/10, 5 守门员绿但 6 盲区 |
| **加权平均** | **5.4/10** | **11** | **29** | **39** | **24** | gdc + AppStore + Apple Health 是 3 大风险域 |

---

## 一、上架 / 架构 / 建议重构 / 半成品相关问题

### 1.1 上架阻断 (合并 AppStore + GooglePlay + Apple Health)

| 严重性 | 问题 | 视角 | 修复难度 | 依赖 |
|---|---|---|---|---|
| **P0** | iOS Screenshots 全部缺失 (`fastlane/metadata/ios/*/screenshots/` = 0) | AppStore | XL | 设计师 1-2 周 |
| **P0** | Privacy Policy URL = `[PENDING_DOMAIN]` (3 locale) | AppStore + GooglePlay | M | 域名注册 |
| **P0** | Support URL = `[PENDING_DOMAIN]` (3 locale) | AppStore + GooglePlay | M | 域名注册 |
| **P0** | `review_information` 4 字段 = `REPLACE_BEFORE_APPLE_REVIEW` 占位 | AppStore | S | 真人填字段 |
| **P0** | iOS Podfile 占位 (R77 标注, macOS build 重新生成) | AppStore | S | macOS build |
| **P0** | Android 域名 + ICP (中国上架必备, 7-20 天流程) | GooglePlay | XL | 域名注册 + ICP 备案 |
| **P0** | `git revert b2d9744f` 恢复 322 文件 (gdc 视角) | gdc | S | `git revert` 无冲突 |
| **P0** | `encryption_service.dart:83` "TODO(v1.0): AES-256-CBC 无完整性认证" | super | L | HMAC/GCM 升级 (PIPL §38) |
| ~~**P0**~~ | ~~R93 重建 spec 5 flag → 实际 1 flag 矛盾~~ ⚠️ **误报** | gdc | S | 已撤销 (revert 后原版正确, 我重建版才错了) |
| **P0** | 盘点 2 个空 package (`chroniccare_core/` + `chroniccare_features_mood/` 只有 .gitkeep) | gdc | S 或 L | 撤 OR 完整迁 |

**P0 总数: 10 项** (AppStore 5 + GooglePlay 1 + gdc 3 + super 1)

### 1.2 架构问题 (合并 emil + superpowers + flutter + gdc)

| 严重性 | 问题 | 视角 | 修复难度 | 类别 |
|---|---|---|---|---|
| **P1** | 6 个 `lib/presentation/pages/<module>/` 与 feature-first 共存 (`daily_tracking/home/setup/crisis_hotline_page` 等) | flutter | S | 模块布局混用 |
| **P1** | `mood_detail_page.dart` 431L (`_content` 方法 265L, god class 跨 audio+cbt+delete+view) | super | XL | god class |
| **P1** | `boot_apps.dart` 466L (R108 拆后还超 400 阈值) | super | M | god class |
| **P1** | `home_page_state.dart` 430L (R117 续拆未完) | super | M | god class |
| **P1** | 47 个结构性 lock-in 测试 (readAsStringSync/existsSync) 混在 `test/core/data/`/`test/main/` | super | M | 测试架构 |
| **P1** | `mood_hero_card.dart:109` fontSize 24 + 57/101 padding 18 未 token 化 | emil | S | token 残留 |
| **P1** | `press_feedback_icon_button.dart:57-60` release strip assert 风险 | emil | S | assert 文档化 |
| **P1** | 修 3 个 prod-false flag 触发条件 (bootReceiver/fiveVendorPush/healthKit) | gdc | S | 半成品决策 |
| **P1** | 修路线图 gap (FEATURE_FIRST_PLAN 阶段 2 迁 core 未发生, 路线图修正) | gdc | M | 决策跟踪 |
| **P1** | Apple Health 守门员盲区 3 项 (entitlement / NSHealthUpdateUsageDescription / pbxproj) | AppleHealth | S | 守门员扩展 |
| **P1** | Android HealthConnect 完全 0 抽象 (iOS 单平台 stub) | AppleHealth | L | 跨平台一致性 |
| **P1** | HealthKitFactory 不分 platform (永远 NoOp) | AppleHealth | M | 真接窗口 |

### 1.3 重构机会 (合并 emil + superpowers + flutter)

| 严重性 | 问题 | 视角 | 修复难度 | 类别 |
|---|---|---|---|---|
| **P2** | `empty_state.dart:65-74` 3 处 alpha magic (0.08/0.02/0.6) 应抽 token | emil + flutter | S | token 化 |
| **P2** | `apple_list_section.dart` vs `lazy_apple_list_section.dart` 双轨常量复制 | emil | M | 集中器去重 |
| **P2** | `home_fab_toolbar.dart:208` FAB 旋转 0.125 turns (45°) → 0.5 turns (180°) | emil | S | 视觉直觉 |
| **P2** | `preset_content_l10n.dart:24-57` 35 条中文字面量 lookup → enum | flutter | S | i18n 鲁棒 |
| **P2** | `mood_detail_page.dart` + `assessment_page.dart` 内联 TextStyle 集中化 | flutter | M | 性能 |
| **P2** | `daily_tracking_page.dart:289-345` `_PinnedSection` 96L 未抽 public | flutter | S | widget 拆分 |
| **P2** | 9 处 `Colors.white` 硬编码 → `AppColors.fgOnPrimary(context)` | flutter | S | dark mode |
| **P2** | 11 处 `var X = non-reassign` → `final X = ...` | flutter | S | 风格 |
| **P2** | `_isToday(dynamic entity)` → sealed class pattern matching | flutter | S | 类型安全 |
| **P2** | 95 处 `dynamic` 用法扫描 (mapper 已豁免, `_isToday` 多态用 sealed 改) | flutter | L | 类型安全 |
| **P2** | `scripts/_archive/` (9 个 R99 死代码) + `_audit_*.py` + `_r101_*.py` 清理 | super | S | 死代码 |
| **P2** | `notification_service.dart` 278L 续拆 (R120 已拆但仍大) | super | L | god class |
| **P2** | `secondary_button.dart:46` SizedBox magic 16 → buttonSize | emil | S | token 化 |
| **P2** | `mood_hero_card.dart` LineSpacing 跟 VentHeroCard 一致性 | emil | S | 视觉一致性 |
| **P2** | 全 lib Semantics/tooltip 覆盖补全 (仅 63 处) | flutter | M | 无障碍 |
| **P2** | 文本输入无 minHeight 48 (WCAG 2.5.5) | flutter | L | 无障碍 |
| **P2** | `core/routing/` 按 feature 分散 (14 文件集中) | flutter | L | 模块路由 |
| **P2** | 修真机制 (`cc08c347` × 21) 改回详细 commit 描述模式 | super | M | 流程纪律 |
| **P2** | 30+ Navigator.pop 散落抽 `showAppDialog<T>` 集中器 | flutter | L | 路由统一 |
| **P2** | 跨期 P0 修真产物 `medication_page.dart:131-137` '修正' 注释残留 | emil + gdc | S | 文档清理 |
| **P2** | R127 阶段 2 决策文档补 (路线图转变 R127→R128d 原因) | gdc | M | 决策记录 |

### 1.4 半成品 (合并 gdc + superpowers + Apple Health)

| 严重性 | 半成品 | 视角 | 修复难度 | 决策标记 |
|---|---|---|---|---|
| **P1** | `health_kit_service.dart` 204 行 (NoOpHealthKitChannel 永远早返) | AppleHealth + gdc | L | 触发条件 "5-6 月后真接" 不明 |
| **P1** | `five_vendor_push_service.dart` 316 行 (5 抽象 + NoOp + 5 占位 impl) | super + gdc | L | 触发条件 "1-2 月审核" 不明 |
| **P1** | `bootReceiver` FeatureFlag 默认 false (4 round 仍 false) | gdc | S | "等 v0.28 WorkManager 完善后翻 true" |
| **P1** | `packages/chroniccare_core/lib/src/.gitkeep` (1 行占位, 0 业务代码) | gdc | L | R127 阶段 2 计划 "迁 core" 未发生 |
| **P1** | `packages/chroniccare_features_mood/lib/src/.gitkeep` (1 行占位, 0 业务代码) | gdc | L | R127 阶段 3 计划 "迁 mood presentation" 未发生 |
| **P2** | `assessment_unavailable_card.dart:6` TODO 注释 | super | S | 设计意图, 非 bug |
| **P2** | `scale_translations.dart:17` 16 题 i18n 化 v1.0 长期 | flutter + super | XL | 心理学术语审核依赖外部 |
| **P2** | `scale_registry.dart:6` R117 P2-6 TODO | super | S | 注释清理 |
| **P2** | `assessment_center_page.dart:34-37` PHQ-9/GAD-7 admin-only flag (`phqGad7I18nEnabled`) | flutter | M | v1.0+ 完整 i18n |
| **P3** | 12 处 TODO 注释 (跨期修真残留) | flutter | S | 改 NOTE/deferred |
| **P3** | `apple_health_tile.dart:104` tooltip 长按触发 (移动端难发现) | AppleHealth | M | 设置页加显式说明 |

---

## 二、顶层架构审视 (高内聚低耦合)

### 2.1 综合架构评分

| 维度 | 评分 | 评估 |
|---|---|---|
| **依赖方向纯净度** | 9/10 | 4 层 (presentation → domain → data) 严格, 无反向依赖 (守门员 `check_cross_feature.py` + `check_all.dart` 守护) |
| **模块自治性** | 7/10 | feature-first 已铺 (6 feature 在 `lib/features/`), 但 6 个 module 残留在 `lib/presentation/pages/` 混用 |
| **路由集中度** | 8/10 | go_router 统一 + 7 feature AppRoute*.dart + 3 transition helper, 但全集中在 `lib/core/routing/` (14 文件) |
| **状态管理一致性** | 10/10 | Riverpod 3.3.2 单选, 0 混用 (Provider/Bloc/GetX) |
| **数据层抽象** | 9/10 | Drift + SQLCipher + 14 DAO + 10 Repository 抽象 + 10 Repository impl, 完整 |
| **设计 token 集中度** | 9.5/10 | `packages/chroniccare_theme/` 6 token 集中器 (colors/typography/spacing/motion/spring/app_tokens), 但 `mood_hero_card` 2 处 hero fontSize/padding 未 token 化 |
| **Widget 集中度** | 9/10 | 35+ 通用 widget 集中在 `lib/presentation/widgets/`, `AppleListSection` / `AppleHealthTile` / `PressFeedback` / `AppSnackBar` 等核心集中器覆盖广 |
| **守门员体系** | 9/10 | 21 个 `check_*.py` + 47 lock-in test, 覆盖 4 层 + cross-feature + i18n + iOS + Android + AppleHealth + 5 厂商 + 16KB + PII |
| **跨平台一致性** | 6/10 | iOS HealthKit stub + Android HealthConnect 0 抽象 + Web N/A |
| **Feature flag 决策透明** | 4/10 | 4 flag (3 false + 1 true), 但 3 false 触发条件不明, "临时" 已成事实永久 |
| **整体架构评分** | **7.6/10** | 4 层依赖方向 + 设计 token + 守门员 = 业内顶级, 但跨平台一致性 + 半成品决策透明 = 短板 |

### 2.2 可重构模块清单 (按 ROI 排序)

| 优先级 | 模块 | 当前状态 | 重构方案 | 难度 | 收益 |
|---|---|---|---|---|---|
| **P1** | `lib/core/data/services/encryption_service.dart` | 204L, TODO 缺完整性认证 (PIPL §38 风险) | 加 HMAC 包装或换 AES-256-GCM | L | 法务合规 + 数据完整性 |
| **P1** | `lib/features/mood/presentation/pages/mood_list/mood_detail_page.dart` | 431L, `_content` 265L (audio+cbt+delete+view 4 职责) | 拆 3 section widget (`_MoodAudioSection` / `_MoodCbtSection` / `_MoodActionsSection`) | XL | 核心用户路径, 改一处易碰回归 |
| **P1** | `lib/main/boot_apps.dart` | 466L, 刚拆完还超 400 阈值 | 续拆 `_MigrationFailedApp` (UI + 错误显示 + 重试 3 职责) | M | 启动期稳定性 |
| **P1** | `lib/presentation/pages/` 6 module → `lib/features/<f>/presentation/pages/` | module-first 残留 | 机械搬迁 + 改 import | S | 架构一致性 |
| **P2** | `lib/core/routing/app_routes.dart` 258L + 7 AppRoute*.dart | 14 文件全在 `core/routing/` | 迁 `app_route_<f>.dart` 到 `lib/features/<f>/presentation/routing/`, 聚合文件保留 | L | feature 自治性 |
| **P2** | `lib/presentation/providers/cbt_providers.dart` (8.7KB) + `daily_tracking_providers.dart` (8.7KB) | 业务复杂 provider | 拆 provider per concern | M | 测试性 + 可读性 |
| **P2** | `packages/chroniccare_core/` + `packages/chroniccare_features_mood/` | 2 个空 package (只有 .gitkeep) | 完成 R127 阶段 2 迁 core / 阶段 3 迁 mood OR 撤销 pubspec workspace | L | pub workspace 价值 |
| **P3** | `lib/core/platform/notification/notification_service.dart` 278L | R120 已拆但仍大 | 续拆 per 5 厂商 | L | 通知职责清晰 |
| **P3** | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` 346L | R110 round 7a 已拆 3 子节但 build 仍 65L + `_PinnedSection` 96L 未抽 public | 抽 `_PinnedSection` → `widgets/tracking_pinned_section.dart` | S | widget 复用 |

### 2.3 跨平台架构问题

| 问题 | 现状 | 影响 | 建议 |
|---|---|---|---|
| iOS HealthKit | stub (204L, 0 caller) | 视觉 9/10 + 集成 0/10, 5-6 月后真接 | 加 `health_kit: ^4.x` 依赖 + entitlement + Info.plist |
| Android HealthConnect | 完全 0 抽象 (grep 0 命中) | 跨平台一致性 gap | 加 `health_connect: ^x.x` 依赖 + abstract channel |
| Web 适配 | N/A (Flutter Web 通用适配) | 无 | 不需修 |
| iOS Podfile | 占位 (R77 标注) | macOS build 重新生成 | 跑 `pod install` + commit `Podfile.lock` |
| iOS Deployment Target | 14.0 (2020) | 落后 1.5 个大版本 | 升 15.0+ (S 难度) |
| 16KB page size | sqlcipher_flutter_libs 0.6.5 满足 | 未自动验证 | 加 `check_16kb_alignment.py` 自动跑 |

---

## 三、底层逐行排查 (按 Bug 严重性)

### 3.1 致命 P0 Bug (必须立即修, 否则上架/法务/数据完整性受损)

| # | Bug | 文件:行号 | 视角 | 修复难度 |
|---|---|---|---|---|
| 1 | encryption_service 缺 HMAC 完整性认证 (PIPL §38 风险) | `lib/core/data/services/encryption_service.dart:83` | super | L |
| 2 | R93 spec 5 flag → 1 flag 矛盾 (误导未来读者) | `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md:28-34` vs `feature_flags.dart:53` | gdc | S |
| 3 | R93 spec 4 → 3 删除 flag 数量不符 | `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md:38-42` vs `feature_flags.dart:14-16` | gdc | S |
| 4 | iOS Screenshots 全部缺失 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/` = 0 | AppStore | XL |
| 5 | iOS Privacy Policy URL = `[PENDING_DOMAIN]` 占位 | `fastlane/metadata/ios/en-US/privacy_url.txt:1` + 2 locale | AppStore | M |
| 6 | iOS Support URL = `[PENDING_DOMAIN]` 占位 | `fastlane/metadata/ios/en-US/support_url.txt:1` + 2 locale | AppStore | M |
| 7 | iOS `review_information` 4 字段 = `REPLACE_BEFORE_APPLE_REVIEW` | `fastlane/metadata/ios/review_information/{first,last,email,phone}_name.txt` | AppStore | S |
| 8 | iOS Podfile 占位 (未生成 Podfile.lock) | `ios/Podfile:1-60` | AppStore | S |
| 9 | Android 域名 + ICP 备案缺失 | `fastlane/metadata/android/{en-US,zh-CN}/{privacy,support}_url.txt` | GooglePlay | XL |
| 10 | `git revert b2d9744f` 恢复 322 文件 (gdc 决策严谨度致死) | git history | gdc | S |

### 3.2 重大 P1 Bug (上架会被退回 / 架构缺陷 / 半年内回归)

| # | Bug | 文件:行号 | 视角 | 修复难度 |
|---|---|---|---|---|
| 1 | `mood_detail_page.dart` `_content` 265L god method | `lib/features/mood/presentation/pages/mood_list/mood_detail_page.dart:74-340` | super + flutter | XL |
| 2 | `boot_apps.dart` 466L god class (R108 拆后还超 400) | `lib/main/boot_apps.dart` | super | M |
| 3 | 47 个结构性 lock-in tests (readAsStringSync/existsSync) 混在 test core/main | `test/{main,core/data,domain}/` | super | M |
| 4 | 6 module 残留在 `lib/presentation/pages/` 混用 feature-first | `lib/presentation/pages/{home,setup,daily_tracking,settings,tips,trend,vent,worry,assessment,medication,mood,mood_list,crisis_hotline_page}.dart` | flutter | S |
| 5 | `preset_content_l10n.dart` 35 条中文字面量 lookup (zh_Hant 切换数据反查失败风险) | `lib/l10n/preset_content_l10n.dart:24-57` | flutter | S |
| 6 | 全局缺 `MediaQuery.withClampedTextScaling(1.5)` 兜底 (仅 AppleHealthTile 1 处 clamp) | `lib/presentation/widgets/apple_health_tile.dart:98-99` | flutter | S |
| 7 | `_PinnedSection` (96L) 未抽 public widget | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:289-345` | flutter | S |
| 8 | 9 处 `Colors.white` 硬编码 (dark mode 对比度) | `lib/features/mood/.../mood_trend_line_chart.dart:194,211` 等 9 处 | flutter | S |
| 9 | 3 个 prod-false flag 触发条件不明 (bootReceiver/fiveVendorPush/healthKit) | `lib/core/data/feature_flags.dart:46-58` | gdc | S |
| 10 | FEATURE_FIRST_PLAN 路线图 gap (R127 阶段 2 迁 core 未发生) | `docs/architecture/FEATURE_FIRST_PLAN.md:84,122-127` | gdc | M |
| 11 | iOS user_agreement.md:83 TODO 律师过审 | `assets/legal/user_agreement.md:83` | AppStore | M |
| 12 | 3 处邮箱 `【邮箱待启用】` 占位 (PIPL §14 + Apple 5.1.1) | `assets/legal/{privacy_policy,user_agreement}.md` 3 处 | AppStore | S |
| 13 | zh-Hant description 缺大陆热线 2 条 | `fastlane/metadata/ios/zh-Hant/description.txt:32-35` | AppStore | S |
| 14 | iOS Appfile 用 ENV 占位 (fastlane 上传失败) | `fastlane/Appfile:26-29` | AppStore | S |
| 15 | Google Play Data Safety form 0 填写 | Play Console 后台 | GooglePlay | M |
| 16 | 16KB page size 未自动验证 (仅注释承诺) | `pubspec.yaml:38-40` | GooglePlay + Apple | S |
| 17 | 截图仅 4 张横屏 1232×720 (需 8 张竖屏) | `fastlane/metadata/android/*/phoneScreenshots/` | GooglePlay | XL |
| 18 | Android changelogs 仅 default.txt v1.0.0 (实际 1.1.0+185) | `fastlane/metadata/android/zh-CN/changelogs/default.txt` | GooglePlay | S |
| 19 | Android 0 FCM 远程推送 (5 厂商 push 占位) | `lib/core/platform/notification/five_vendor_push_service.dart:63` × 5 | GooglePlay + super | L |
| 20 | Apple Health 守门员 3 盲区 (entitlement / NSHealthUpdateUsageDescription / pbxproj) | `scripts/check_apple_health_claim.py:154` | AppleHealth | S |
| 21 | Android HealthConnect 0 抽象 | `lib/core/platform/health_connect/` 不存在 | AppleHealth | L |
| 22 | HealthKitFactory 不分 platform | `lib/core/platform/health_kit/health_kit_service.dart:108` | AppleHealth | M |
| 23 | `mood_hero_card.dart:109` fontSize 24 未 token 化 | `lib/features/mood/presentation/pages/mood_list/mood_hero_card.dart:109` | emil | S |
| 24 | `press_feedback_icon_button.dart:57-60` release strip assert 风险 | `lib/presentation/widgets/press_feedback_icon_button.dart:57-60` | emil | S |

### 3.3 显著 P2 Bug (可上架但需说明 / 微调)

| # | Bug | 文件:行号 | 视角 | 修复难度 |
|---|---|---|---|---|
| 1 | `empty_state.dart:65-74` 3 处 alpha magic 应抽 token | `lib/presentation/widgets/empty_state.dart:65-74` | emil + flutter | S |
| 2 | `AppleListSection` vs `LazyAppleListSection` 双轨常量复制 | `apple_list_section.dart:14-16` + `lazy_apple_list_section.dart:1-15` | emil | M |
| 3 | `home_fab_toolbar.dart:208` FAB 旋转 0.125 turns (45°) 应改 0.5 | `lib/presentation/widgets/home_fab_toolbar.dart:208-217` | emil | S |
| 4 | `mood_detail_page` + `assessment_page` 内联 TextStyle 集中化 | `mood_detail_page.dart:118,135-141,147-157` + `assessment_page.dart:217,234,244` | flutter | M |
| 5 | 11 处 `var X = non-reassign` → `final` | 11 处散落 | flutter | S |
| 6 | `_isToday(dynamic entity)` → sealed class | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:172` | flutter | S |
| 7 | 95 处 `dynamic` 用法扫描 | 多文件散落 | flutter | L |
| 8 | `scripts/_archive/` (9 个) + `_audit_*.py` + `_r101_*.py` 死代码清理 | `scripts/_archive/` | super | S |
| 9 | `notification_service.dart` 278L 续拆 | `lib/core/platform/notification/notification_service.dart` | super | L |
| 10 | `secondary_button.dart:46` SizedBox magic 16 → buttonSize | `lib/presentation/widgets/secondary_button.dart:46` | emil | S |
| 11 | 全 lib Semantics/tooltip 覆盖补全 (仅 63 处) | 全局 | flutter | M |
| 12 | 文本输入无 minHeight 48 (WCAG 2.5.5) | 多文件散落 | flutter | L |
| 13 | `core/routing/` 按 feature 分散 (14 文件集中) | `lib/core/routing/` | flutter | L |
| 14 | 修真机制 (`cc08c347` × 21) 改回详细 commit 描述 | git log | super | M |
| 15 | 30+ Navigator.pop 散落抽 `showAppDialog<T>` 集中器 | 多文件散落 | flutter | L |
| 16 | `medication_page.dart:131-137` '修正' 注释残留 | `lib/features/medication/presentation/pages/medication/medication_page.dart:131-137` | emil + gdc | S |
| 17 | `home_page_state.dart` 430L (R117 续拆未完) | `lib/presentation/pages/home/home_page_state.dart` | super | M |
| 18 | 修真 commit message 频密 (修真 × 21) | `cc08c347` `73361cd8` 等 | super + gdc | M |
| 19 | R127 阶段 2 决策文档补 (路线图 R127→R128d 原因) | 缺失 | gdc | M |
| 20 | iPhone App Icon `@1x` 文件 < 1KB (可疑 placeholder) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{20,29,40}@1x.png` | AppStore | S |
| 21 | iOS Deployment Target 14.0 (2020 落后) | `ios/Podfile:3` 或 `ios/Flutter/AppFrameworkInfo.plist` | AppStore | S |
| 22 | iOS LaunchImage 用旧模式非 LaunchScreen.storyboard | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | AppStore | M |
| 23 | `appstore_metadata/` 统一元数据目录缺失 | `appstore_metadata/` | AppStore | S |
| 24 | `healthMetricsIds` 孤儿 `'contact'` (v1.1.0 round 4b contact 已删) | `app_colors.dart:471` + `apple_health_tile.dart:183-184` | AppleHealth | S |
| 25 | `healthMetricsIds` 未接入 `'sleep'` | `app_colors.dart:472` | AppleHealth | S |
| 26 | `spec.md:108-112` 提及虚假 `moodToAppleHealthSyncEnabled` flag | `docs/design/2026-08-10-apple-health-redesign/spec.md:111` | AppleHealth + gdc | S |
| 27 | `health_kit_service.dart:149` 注释 "用户首次点同步" UI入口 | `lib/core/platform/health_kit/health_kit_service.dart:149` | AppleHealth | S |
| 28 | mockup 目录命名不一致 | `docs/design/2026-08-17-redesign-mockup/` vs `2026-08-10-apple-health-redesign/` | AppleHealth | S |
| 29 | 12 处 TODO 注释改 NOTE/deferred | 多文件散落 | flutter | S |
| 30 | R124 5 厂商 push NoOp 真接排期 | `lib/core/platform/notification/five_vendor_push_service.dart` | super | L |
| 31 | 修真 commit message 含 '修真' × 21 退化信号 | `git log cc08c347 73361cd8` 等 | super + gdc | M |
| 32 | `mood_hero_card.dart` LineSpacing 跟 VentHeroCard 一致性 | `mood_hero_card.dart` | emil | S |
| 33 | `assessment_unavailable_card.dart:6` TODO 注释移除 | `lib/features/assessment/presentation/pages/widgets/assessment_unavailable_card.dart:6` | super | S |
| 34 | `scale_translations.dart:17` 16 题 i18n 化 (v1.0 长期) | `lib/domain/entities/scale_translations.dart:17` | flutter + super | XL |
| 35 | AGENTS / README / CHANGELOG / VERSION_1.0_PLAN / SUBMISSION_INFO 缺失 | 5 个项目根目录关键文档 | AppStore + super | M |
| 36 | PHQ-9 / GAD-7 admin-only flag (`phqGad7I18nEnabled`) v1.0 完整 i18n | `lib/features/assessment/presentation/pages/assessment_center_page.dart:34-37` | flutter | M |
| 37 | 5 厂商 push 占位 15 处 UnimplementedError | `five_vendor_push_service.dart:63` × 5 | GooglePlay + super | L |

---

## 四、合并优先级清单 (架构 vs 底层 + 难度 + 优先级)

### 4.1 架构级问题 (跨文件 / 跨 feature / 决策级)

| # | 问题 | 难度 | 优先级 | 类别 | 视角 |
|---|---|---|---|---|---|
| A1 | `git revert b2d9744f` 恢复 322 文件 (gdc 致死) | S | **P0** | 决策 | gdc |
| A2 | 修 R93 spec 5→1 flag + 4→3 删除 flag 矛盾 (gdc) | S | **P0** | 决策 | gdc |
| A3 | 盘点 2 个空 package (chroniccare_core/ + chroniccare_features_mood/) | S 或 L | **P0** | 决策 | gdc |
| A4 | 6 module → features 迁移 (presentation/pages → features/*/presentation/pages) | S | **P1** | 架构 | flutter |
| A5 | `mood_detail_page` 265L `_content` 拆 3 section | XL | **P1** | 架构 | super + flutter |
| A6 | `boot_apps.dart` 466L 续拆 (刚拆完还超 400) | M | **P1** | 架构 | super |
| A7 | 47 个 lock-in tests 迁 `test/lock_in/` 独立目录 | M | **P1** | 架构 | super |
| A8 | 3 prod-false flag 触发条件文档化 | S | **P1** | 决策 | gdc |
| A9 | FEATURE_FIRST_PLAN 路线图 gap 修正 (R127→R128d) | M | **P1** | 决策 | gdc |
| A10 | `home_page_state.dart` 430L 续拆 | M | **P1** | 架构 | super |
| A11 | 修真机制 (`cc08c347` × 21) 改回详细 commit 描述 | M | **P2** | 流程 | super + gdc |
| A12 | `core/routing/` 按 feature 分散 (14 文件) | L | **P2** | 架构 | flutter |
| A13 | `notification_service.dart` 278L 续拆 | L | **P2** | 架构 | super |
| A14 | R127 阶段 2 决策文档补 (路线图转变原因) | M | **P2** | 决策 | gdc |
| A15 | Apple Health 守门员扩 3 项 (entitlement / update / pbxproj) | S | **P1** | 架构 | AppleHealth |
| A16 | Android HealthConnect 抽象 (跨平台一致性) | L | **P1** | 架构 | AppleHealth |
| A17 | HealthKitFactory 分 platform 分支 | M | **P1** | 架构 | AppleHealth |
| A18 | `packages/chroniccare_core/` + `chroniccare_features_mood/` 完整迁移 OR 撤销 | L | **P1** | 架构 | gdc |
| A19 | AGENTS / CHANGELOG / VERSION_1.0_PLAN / SUBMISSION_INFO 重建 | M | **P1** | 架构 | AppStore + super |
| A20 | R124 5 厂商 push NoOp 真接排期 | L | **P2** | 架构 | super + GooglePlay |

### 4.2 底层问题 (单文件 / 单函数 / 视觉微调)

| # | 问题 | 难度 | 优先级 | 类别 | 视角 |
|---|---|---|---|---|---|
| B1 | encryption_service HMAC 完整性认证 (PIPL §38) | L | **P0** | 安全 | super |
| B2 | iOS Screenshots 缺失 (3 locale × 3 尺寸 × 5-8 张) | XL | **P0** | 上架 | AppStore |
| B3 | iOS Privacy Policy URL = `[PENDING_DOMAIN]` (3 locale) | M | **P0** | 上架 | AppStore + GooglePlay |
| B4 | iOS Support URL = `[PENDING_DOMAIN]` (3 locale) | M | **P0** | 上架 | AppStore + GooglePlay |
| B5 | iOS `review_information` 4 字段填真实值 | S | **P0** | 上架 | AppStore |
| B6 | iOS Podfile 占位 → macOS 跑 `pod install` | S | **P0** | 上架 | AppStore |
| B7 | Android 域名 + ICP 备案 | XL | **P0** | 上架 | GooglePlay |
| B8 | `preset_content_l10n.dart` 35 条中文 lookup → enum | S | **P1** | i18n | flutter |
| B9 | 全局 `MediaQuery.withClampedTextScaling(1.5)` 兜底 | S | **P1** | 无障碍 | flutter |
| B10 | `_PinnedSection` (96L) 抽 public widget | S | **P1** | 性能 | flutter |
| B11 | 9 处 `Colors.white` → `AppColors.fgOnPrimary` | S | **P1** | UI | flutter |
| B12 | iOS user_agreement.md:83 TODO 律师过审 | M | **P1** | 上架 | AppStore |
| B13 | 3 处邮箱 `【邮箱待启用】` 替换 | S | **P1** | 上架 | AppStore |
| B14 | zh-Hant description 补大陆热线 2 条 | S | **P1** | 上架 | AppStore |
| B15 | iOS Appfile 用 ENV 占位 → cp .env.example .env | S | **P1** | 上架 | AppStore |
| B16 | Google Play Data Safety form 填写 | M | **P1** | 上架 | GooglePlay |
| B17 | 16KB page size 自动验证脚本 | S | **P1** | 上架 | GooglePlay + Apple |
| B18 | Android 截图补 8 张竖屏 | XL | **P1** | 上架 | GooglePlay |
| B19 | Android changelogs 补 1.1.0+185 版本 | S | **P1** | 上架 | GooglePlay |
| B20 | `mood_hero_card.dart:109` fontSize 24 + 57/101 padding 18 → token | S | **P1** | token | emil |
| B21 | `press_feedback_icon_button.dart:57-60` release strip assert 注释 | S | **P1** | 文档 | emil |
| B22 | `empty_state.dart:65-74` 3 处 alpha magic → token | S | **P2** | token | emil + flutter |
| B23 | `AppleListSection` vs `LazyAppleListSection` 双轨常量抽公共 | M | **P2** | 集中器 | emil |
| B24 | `home_fab_toolbar.dart:208` FAB 旋转 0.125 → 0.5 | S | **P2** | 视觉 | emil |
| B25 | `mood_detail_page` + `assessment_page` 内联 TextStyle 集中化 | M | **P2** | 性能 | flutter |
| B26 | 11 处 `var X` → `final X` | S | **P2** | 风格 | flutter |
| B27 | `_isToday(dynamic entity)` → sealed class pattern matching | S | **P2** | 类型 | flutter |
| B28 | 95 处 `dynamic` 用法扫描 (mapper 豁免) | L | **P2** | 类型 | flutter |
| B29 | `scripts/_archive/` + `_audit_*.py` + `_r101_*.py` 清理 | S | **P2** | 死代码 | super |
| B30 | `secondary_button.dart:46` SizedBox 16 → buttonSize token | S | **P2** | token | emil |
| B31 | 全 lib Semantics/tooltip 覆盖补全 (63 处 → 全覆盖) | M | **P2** | 无障碍 | flutter |
| B32 | 文本输入无 minHeight 48 (WCAG 2.5.5) | L | **P2** | 无障碍 | flutter |
| B33 | 30+ Navigator.pop 抽 `showAppDialog<T>` 集中器 | L | **P2** | 路由 | flutter |
| B34 | `medication_page.dart:131-137` '修正' 注释残留清理 | S | **P2** | 文档 | emil + gdc |
| B35 | iPhone App Icon `@1x` 文件 < 1KB 重出 | S | **P2** | 上架 | AppStore |
| B36 | iOS Deployment Target 14.0 → 15.0 | S | **P2** | 上架 | AppStore |
| B37 | `healthMetricsIds` 孤儿 `'contact'` 删除 | S | **P2** | 视觉 | AppleHealth |
| B38 | `healthMetricsIds` 未接入 `'sleep'` 加 flag | S | **P2** | 视觉 | AppleHealth |
| B39 | `spec.md:111` 提及虚假 `moodToAppleHealthSyncEnabled` flag 清理 | S | **P2** | 文档 | AppleHealth + gdc |
| B40 | `health_kit_service.dart:149` 注释 "用户首次点同步" 修正 | S | **P2** | 文档 | AppleHealth |
| B41 | mockup 目录命名不一致 (2026-08-17 vs 2026-08-10) | S | **P2** | 文档 | AppleHealth |
| B42 | 12 处 TODO 注释改 NOTE/deferred | S | **P2** | 文档 | flutter |
| B43 | `mood_hero_card` LineSpacing 跟 VentHeroCard 一致性 | S | **P2** | 视觉 | emil |
| B44 | `assessment_unavailable_card.dart:6` TODO 注释移除 | S | **P3** | 文档 | super |
| B45 | `scale_translations.dart:17` 16 题 i18n 化 (v1.0 长期) | XL | **P3** | i18n | flutter + super |
| B46 | PHQ-9 / GAD-7 admin-only flag v1.0 完整 i18n | M | **P3** | i18n | flutter |
| B47 | iOS LaunchImage 旧模式 → LaunchScreen.storyboard | M | **P3** | 上架 | AppStore |
| B48 | `appstore_metadata/` 统一元数据目录补建 | S | **P3** | 文档 | AppStore |
| B49 | AppleHealthTile tooltip 长按触发 → 设置页显式说明 | M | **P3** | UI | AppleHealth |
| B50 | R32 9 fail 残留跨期收敛 | M | **P3** | 测试 | super |

### 4.3 难度分布统计

| 难度 | 架构级 | 底层 | 合计 | 占比 |
|---|---|---|---|---|
| **S** (< 1h) | 2 (A11, A8) | 18 (B3-B7, B8-B11, B13-B15, B17, B19-B21, B26, B29, B30, B34-B36, B37-B42) | **20** | 39% |
| **M** (1-4h) | 5 (A6, A9, A11, A14, A17, A19) | 11 (B12, B16, B23, B25, B31, B46-B47, B49-B50) | **17** | 33% |
| **L** (1d+) | 3 (A12, A13, A16, A18) | 6 (B1, B27, B28, B32, B33, B45) | **12** | 24% |
| **XL** (1wk+) | 1 (A5) | 2 (B2, B7, B18) | **4** | 8% |

### 4.4 优先级分布统计

| 优先级 | 架构级 | 底层 | 合计 | 占比 |
|---|---|---|---|---|
| **P0** (致命) | 3 (A1-A3) | 7 (B1-B7) | **10** | 20% |
| **P1** (重大) | 11 (A4-A10, A15-A19) | 14 (B8-B21) | **25** | 49% |
| **P2** (中等) | 3 (A11-A14) | 22 (B22-B43) | **25** | 24% |
| **P3** (软建议) | 0 | 6 (B44-B50) | **6** | 12% |

---

## 五、7 视角交叉一致性观察

1. **gdc + AppleHealth 共识**: "5-6 月后真接" HealthKit 没有触发条件 / 没有反向论证 — AppleHealth P1-1/2/3 守门员盲区补正是 gdc 决策严谨度缺失的具体表现
2. **AppStore + GooglePlay 共识**: 5 大上架 P0 几乎全是"占位符 + 外部依赖(域名/ICP)" — 短期无法 100% 修复, 必须先做域名 + ICP 备案 (XL 难度)
3. **emil + flutter 共识**: token 集中度差 1-2% — 全部 P2 微调, 不影响主路径
4. **super + gdc 共识**: 文档与代码一致性 / 修真机制 / lock-in tests 混入主测试 是"流程纪律"问题的不同表现
5. **AppStore + AppleHealth 共识**: iOS 上架与 Apple Health 集成是相关但独立的两个维度 — 守门员 P1-1/2/3 补正后, App Store 5.1.3 抽审风险 8/10 → 9/10
6. **flutter + super 共识**: 47 lock-in tests (12% 测试基数) 反映 "测试纪律 vs 行为测试" 的认知混淆, 是 superpowers 视角的 P1, flutter-audit 视角的间接证据
7. **跨平台一致性 (AppleHealth + GooglePlay + AppStore)**: iOS HealthKit stub / Android HealthConnect 0 / Web N/A / 5 厂商 push 占位 = 项目跨平台架构只有 iOS 完整, Android 半成品, Web N/A

---

## 六、修复路线图建议

### 第一阶段 (1 周内, P0 全部 10 项)
- **架构级** (3 项, S 难度): git revert + 修 spec + 撤/迁 2 空 package
- **底层** (7 项, 1 项 L 难度 + 6 项 S-XL): encryption HMAC + 5 项 iOS/Android 上架占位符 + 1 项 Podfile

### 第二阶段 (1 月内, P1 全部 25 项)
- 架构级 11 项: 6 module 迁移 / god class 拆 / lock-in tests 迁移 / flag 触发条件 / 路线图修正 / 守门员扩展 / HealthConnect 抽象 / HealthKitFactory 分 platform / 空 package 完整迁移 / 5 文档重建
- 底层 14 项: preset_content_l10n / textScaler / TextStyle 集中化 / Colors.white / iOS 文档 4 项 / Appfile / Data Safety / 16KB 自动 / 截图 / changelogs / hero fontSize token / press_feedback assert 注释

### 第三阶段 (1 季度内, P2 全部 25 项)
- 架构级 3 项: 修真机制 / routing 分散 / notification 续拆
- 底层 22 项: token 化 / 视觉微调 / 死代码清理 / 无障碍补全 / 风格统一

### 第四阶段 (1 半年内, P3 全部 6 项 + P0 XL)
- P3 软建议 6 项: 长期 TODO 清理 + LaunchImage 升级 + appstore_metadata 补建 + tooltip 显式说明 + 9 fail 收敛
- P0 XL 2 项: iOS Screenshots 出图 + Android 域名 ICP

---

## 七、7 视角局限 (合并)

| 视角 | 局限 |
|---|---|
| emil | Git history 抹去 (R128e "修真修真..." 频密) → R-number 注释只能引用现象, 不能验证 "为何 X 路径胜出" 完整 reasoning 历史; Pixel-perfect 视觉对标 Apple Health 无 screenshots 比对 |
| superpowers | 无法验证 runtime (本机无 Flutter); 结构性 lock-in vs 真 TDD 比例 12.4% 是下限估算; build_runner 生成文件未单独验证 |
| flutter-audit | 仅静态扫描, lint 配置链确认生效 ✓ 但 Flutter 性能 overlay / Skia rendering 无 benchmarks; dark mode ≥ WCAG AA 全覆盖待外部 contrast check tool |
| gdc | 不能验证 R93 真实决策场景 (5 flag → 1 flag 是否真计划后改); b2d9744f commit 之前用户对话上下文; lib/core/platform/health_kit/ 实际内容未深读; 80+ audit 报告具体内容 |
| AppStore | 无法从代码验证 HealthKit 真接时间; iOS 18+ 16KB 强制时间表; macOS 环境下 pod install 实际生成 Pods 完整性未跑; App Store Connect 后台实际填写主分类/副分类/年龄分级/隐私回答17 题 |
| GooglePlay | 域名前置评估需联网 (跨网络); Play Console 后台状态无法访问; flutter build appbundle 全流程未跑 |
| AppleHealth | 无法从代码验证 HealthKit 真接时间; mock vs production 不可区分; mockup HTML 未完整读; 9 follow-up 微调未逐项验证 |

---

## 八、综合判断

**项目当前状态**: 慢性照护 (chroniccare) Flutter 1.1.0+185 是一个 **业内 reference-grade 实现** (emil 8.6/10 + flutter 8.6/10), 在 4 层依赖方向、Design Token 集中、Widget 集中器、a11y reduce-motion、守门员体系 5 大支柱已规范化。

**3 大风险域**:
1. **gdc 4/10** — 决策基础设施被破坏 (322 文件删除 0 风险评估), 重建未做一致性验证 (R93 spec 5→1 flag 矛盾)
2. **AppStore 3/10** — 5 项 P0 上架硬阻断 (域名/截图/联系信息/Podfile), 短期无法 100% 修复 (依赖外部域名注册 + 设计师出图)
3. **AppleHealth 集成 2/10** — 视觉 9/10 但集成 0/10, 5 守门员 6 盲区, 跨平台一致性 gap (Android HealthConnect 0 抽象)

**最严重的 1 步修正 (gdc 视角)**: 24h 内 `git revert b2d9744f` 恢复 322 文件 + 修复 R93 spec 5→1 flag 矛盾 + 立 ADR 模板 (10 行), 修复决策基础设施。

**上架准备度**: 技术 9/10 (功能完整 + a11y 充分 + reduce-motion 黄金标准), 元数据 0/10 (5 项 P0 全是占位符)。**建议 5-6 周内完成所有 P0+P1, 即可上 iOS + Google Play 双 store**。

---

*审计员: 7 视角综合 (emil-kowalski + superpowers + flutter-audit + gdc + AppStore + Google Play + Apple Health)*
*审计日期: 2026-08-18*
*审计模式: 并行深度只读扫描 + 交叉一致性验证*
*综合 P0: 10 项 | P1: 25 项 | P2: 25 项 | P3: 6 项 | 加权平均分: 5.4/10*