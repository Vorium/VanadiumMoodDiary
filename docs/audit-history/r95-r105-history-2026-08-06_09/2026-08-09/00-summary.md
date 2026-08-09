# R104 7 视角综合审计报告 (2026-08-09)

**版本**: v0.30.0+85 (R95 阶段 1+2+3+4 完成)
**基线**: R103 审计 (2026-08-08)
**范围**: 全部 389 Dart 文件 + fastlane + legal + android/ios 配置 + scripts + test
**守门员**: 18/18 全绿 (check_all.dart 1 架构违规: tracking_item_config.dart)
**测试**: 2019 pass (环境权限问题导致本次未实际跑, 引用 R95 数据)
**Analyzer**: 0 error, 4 warning, 30 info

---

## 一、外部链接隐藏检查

### 1.1 运行时代码 ✅ 全部隐藏

| 检查项 | 状态 | 详情 |
|--------|------|------|
| HTTP/HTTPS URL | ✅ | 仅 4 处在注释中 (sms_service.dart 3 + chinese_holidays.dart 1), 0 运行时调用 |
| 外部 API 端点 | ✅ | AliyunSmsProvider.send() 早返 false, EmailService.send() 早返 false |
| Firebase/Sentry/Analytics | ✅ | 0 依赖, pubspec.yaml 无任何 analytics 包 |
| `.env` 文件 | ✅ | 在 .gitignore 中, flutter_dotenv 仅用于配置 |
| `kDebugMode` 门控 | ✅ | 所有 debug 行为均被 kReleaseMode 门控 |
| `tel:` 危机热线 | ✅ | 唯一外部链接, url_launcher 仅用于 tel: scheme (合理) |
| IAP product ID | ✅ | `com.chroniccare.app.lifetime` 硬编码但 iapEnabled=false |
| developer.log | ✅ | 全部被 kDebugMode 或 swallowError 门控 |

### 1.2 上架物料层 ⚠️ 部分未就绪

| 检查项 | 状态 | 详情 |
|--------|------|------|
| `chroniccare.app` 域名 | ❌ | 未注册, privacy_url/support_url 指向未注册域名 |
| `privacy@chroniccare.app` 邮箱 | ❌ | 未注册 |
| 法律文档 | ⚠️ | 3 份 md 有 "TODO" 标记, 未律师审核 |
| Store description | ⚠️ | 描述已禁用功能 (Apple 2.1 拒因) |

### 1.3 用户可见字符串 ⚠️ 有 mock/dev 残留

| 文件 | 行 | 问题 | 风险 |
|------|-----|------|------|
| `app_zh.arb:1381` | `safetyCheckResultAlertedMocked` | "**开发模式**，未实际通知联系人（mock: {mocked}）" | HIGH |
| `app_en.arb:1320` | 同上英文版 | "**Dev mode**, contacts not actually notified" | HIGH |
| `app_zh_Hant.arb:1359` | 同上繁体版 | "**開發模式**，未實際通知聯繫人" | HIGH |
| `contacts_list_widget.dart:199` | `hintText: '13800138000'` | 占位电话号码 (合理, 中国标准占位) | LOW |

---

## 二、7 视角独立报告

### 视角 1: emilkowalski (设计/动效/UX)

**评分: 9.0/10** (vs R103 的 9.0, 持平)

**优点**:
- 6 god page 全部拆完, 模块化优秀
- 3 类 transition (fade/slide-right/slide-up) 按频度分类
- PressFeedback 0.97 scale + 160ms 一致
- Shimmer "breathing" mode 符合心理健康 App 要求
- 所有动画尊重 `MediaQuery.disableAnimations`

**问题**:

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| E1 | `PageTransitionSwitcher` 忽略 prefers-reduced-motion | 底层/a11y | 简单 | P0 |
| E2 | `textHint` #999999 对比度 2.8:1, 不满足 WCAG AA 4.5:1 | 底层/a11y | 简单 | P0 |
| E3 | 主页 hero (140px) + carousel (80px) 推 CTA 到折叠线以下 | 架构/UX | 中 | P1 |
| E4 | `hero_illustration.dart` Colors.black shadow dark mode 不可见 | 底层/UI | 简单 | P1 |
| E5 | Decorative emoji 被 screen reader 朗读 (缺少 ExcludeSemantics) | 底层/a11y | 简单 | P1 |
| E6 | windowSizeOf medium breakpoint 不可达 (840=840) | 底层 | 简单 | P2 |
| E7 | HomeFabToolbar 展开/折叠无 Semantics 通知 | 底层/a11y | 简单 | P2 |
| E8 | QuickMoodCarousel emoji 缺少 Semantics label | 底层/a11y | 简单 | P2 |

---

### 视角 2: superpowers-en (英文架构/最佳实践)

**评分: 9.0/10** (vs R103 的 9.0, 持平)

**优点**:
- 4 层架构严格分离, domain 0 Flutter 依赖 (1 处违规)
- 18 守门员全绿, CI 友好
- 集成测试 6 个端到端 user journey
- Coverage 阈值 domain 73.8% / data 47% / presentation 57.4%
- Riverpod 3.3.2 + go_router 14.6 现代栈

**问题**:

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| S1 | `tracking_item_config.dart:9` import flutter in domain (架构违规) | 架构 | 中 | P0 |
| S2 | `consent_gate.dart` SharedPrefsConsentGate 在 shared/ 依赖平台插件 | 架构 | 中 | P1 |
| S3 | `app_database.dart:410-480` saveSetup() 业务逻辑在数据层 | 架构 | 中 | P1 |
| S4 | `app_database.dart:6-7` 数据层反向 import domain 实体 | 架构 | 简单 | P1 |
| S5 | `_dateOnly` helper 4 处重复 (trend_calculator / care_strategies / streak_calculator / date_utils) | 底层/DRY | 简单 | P2 |
| S6 | `EncryptedAudioStorage.newAudioPath` 用 Random() 非 Random.secure() | 底层/安全 | 简单 | P2 |
| S7 | SharedPreferences.getInstance() 在 safety_config 重复调用 8 次 | 底层/性能 | 简单 | P2 |
| S8 | EncryptionService() 在 legal_consent_provider 每次重新实例化 | 底层/性能 | 简单 | P2 |

---

### 视角 3: superpowers-zh (中文架构/本地化)

**评分: 9.0/10** (vs R103 的 9.0, 持平)

**优点**:
- P0 硬编码中文全走 ARB (R95 sub-spec 3+7)
- app_database.dart 1499→0 中文注释翻译
- 18 ARB 守门员 (check_arb_keys + check_orphan_arb_keys + check_zh_hant_consistency)
- 3 语 ARB 同步 (zh/en/zh_Hant)

**问题**:

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| Z1 | `mood_detail_page.dart:219` "录音" 硬编码中文 | 底层/i18n | 简单 | P0 |
| Z2 | `mood_detail_page.dart:256` "删除" 硬编码中文 | 底层/i18n | 简单 | P0 |
| Z3 | `add_medication_page.dart:68` "请输入药物名称" 硬编码 | 底层/i18n | 简单 | P0 |
| Z4 | `add_medication_page.dart:112` "已添加" 硬编码 | 底层/i18n | 简单 | P0 |
| Z5 | `medication_page.dart:442` "在用"/"已停" 硬编码 | 底层/i18n | 简单 | P0 |
| Z6 | `mood_factor_analysis.dart:147` "条" 硬编码 | 底层/i18n | 简单 | P1 |
| Z7 | `influence_category.dart:36-71` 36 个中文影响因素在 domain 层 | 架构/i18n | 中 | P1 |
| Z8 | `care_copy.dart:33-57` 全部关怀文案硬编码中文 | 架构/i18n | 中 | P1 |
| Z9 | `assessment_comparison.dart:68-79` 趋势标签硬编码中文 | 底层/i18n | 简单 | P1 |
| Z10 | `today_summary_card.dart` 4 处硬编码中文 | 底层/i18n | 简单 | P0 |
| Z11 | `daily_tracking_multi_chart.dart` 4 处硬编码中文 | 底层/i18n | 简单 | P0 |
| Z12 | 通知 channel 名 const 中文 en/zh_Hant 系统设置看中文 | 底层/i18n | 简单 | P2 |

---

### 视角 4: flutter-specification (Flutter 规范)

**评分: 88%** (vs R103 的 88%, 持平)

**优点**:
- 0 analyzer error
- 18 守门员全绿
- catch 集中器化 (swallowError)
- Token 化 102+ 处
- 集成测试 6 个

**问题**:

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| F1 | `native.dart:27` PRAGMA key SQL 注入风险 (password 拼接) | 底层/安全 | 简单 | P0 |
| F2 | `vent_compose_page.dart:441` 空 setState 每次击键整页重建 | 底层/性能 | 简单 | P1 |
| F3 | `mood_audio_recorder_widget.dart:197` 100ms setState 每秒 10 次重建 | 底层/性能 | 简单 | P1 |
| F4 | 4 warning: 2 unused_local_variable + 2 inference_failure | 底层 | 简单 | P2 |
| F5 | 30 info: trailing_commas + 1 unawaited_futures | 底层 | 简单 | P3 |
| F6 | `cbt_three_column_mode.dart:96-111` 硬编码 Apple 系统颜色不适应 dark mode | 底层/UI | 简单 | P1 |
| F7 | `mood_factor_analysis.dart:105-109` 硬编码颜色无 dark mode | 底层/UI | 简单 | P1 |
| F8 | `legal_page.dart:448-449` dead code `_VentWithdrawChoice` enum | 底层 | 简单 | P3 |
| F9 | `day_detail.dart:364-387` `_scaleName` 只处理 phq9/gad7, 8 新量表显示 raw ID | 底层 | 简单 | P2 |
| F10 | `check_in_entity.dart:80-91` `_assessmentScaleIds` 硬编码, 与 scale_registry 重复 | 架构 | 简单 | P2 |

---

### 视角 5: AppStore (iOS 上架)

**评分: 6.5/10** (vs R103 的 6.5, 持平)

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| A1 | Store description 描述已禁用功能 → Apple 2.1 拒 | 底层 | 简单 | P0 |
| A2 | InfoPlist.strings 未用权限声明 (mic/speech/tracking) | 底层 | 简单 | P0 |
| A3 | iOS 签名未配置 (需 Mac + DEVELOPMENT_TEAM) | 底层 | 简单 | P0 |
| A4 | iOS 真实截图缺失 | 底层 | 中 | P0 |
| A5 | 法律文档 3 份未律师审核 | 底层/外部 | 高 | P0 |
| A6 | 无内容评级配置 (Apple) | 底层 | 中 | P0 |
| A7 | 医疗免责声明未进 onboarding 流程 | 底层 | 简单 | P0 |
| A8 | user_agreement "8 元买断" 表述需对齐 | 底层 | 简单 | P0 |
| A9 | metadata 删 "(失联通知规划中)" | 底层 | 简单 | P0 |
| A10 | iOS Podfile 未真生成 (需 Mac) | 底层 | 简单 | P1 |
| A11 | iOS iCloud Backup 排除未配置 | 底层 | 简单 | P1 |
| A12 | Dynamic Type 完全不支持 (Apple 2.5.1) | 底层/a11y | 中 | P1 |
| A13 | 安全警报锁屏暴露敏感健康信息 | 底层/隐私 | 中 | P1 |
| A14 | 邮件通知暴露药名+剂量 | 底层/隐私 | 中 | P1 |

---

### 视角 6: Google Play Store (Android 上架)

**评分: 40%** (vs R103 的 40%, 持平)

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| G1 | `AndroidManifest.xml:54` android:label 硬编码中文 | 底层 | 简单 | P0 |
| G2 | Release keystore 未生成 | 底层 | 简单 | P0 |
| G3 | 无内容评级配置 (IARC) | 底层 | 中 | P0 |
| G4 | 双平台真实截图 + feature graphic 缺失 | 底层 | 中 | P0 |
| G5 | SCHEDULE_EXACT_ALARM 运行时权限检查缺失 | 底层 | 中 | P1 |
| G6 | USE_EXACT_ALARM Play Console justification 缺失 | 底层 | 简单 | P1 |
| G7 | Data Safety Form / Health Apps questionnaire 未填 | 底层 | 中 | P1 |
| G8 | record/speech_to_text 需 tools:node="remove" | 底层 | 简单 | P1 |
| G9 | `chroniccare.app` 域名未注册 | 底层/外部 | 中 | P0 |
| G10 | 法律文档 3 份未律师审核 | 底层/外部 | 高 | P0 |

---

### 视角 7: Apple Health 集成审查

**评分: N/A (新视角)**

**现状**: App 本地追踪 10 类健康数据 (mood/sleep/weight/anxiety/social_rhythm/stress/treatment/check-in/assessment/medication), 但 Apple HealthKit 零集成。

| # | 问题 | 层级 | 难度 | 优先级 |
|---|------|------|------|--------|
| H1 | 未接入 HealthKit (sleep/weight 数据可双向同步) | 架构 | 大 | P3 |
| H2 | 未声明 HealthKit entitlements | 底层 | 简单 | P3 |
| H3 | 未实现 HKObserverQuery (后台数据同步) | 架构 | 大 | P3 |
| H4 | 无 Health 数据导出格式 (CDA/FHIR) | 架构 | 中 | P3 |

**结论**: Apple Health 集成为 P3 nice-to-have, 不阻塞上架。当前本地追踪已完整, HealthKit 是增值功能。

---

## 三、汇总优先级矩阵 (按修复优先级排序)

### P0 — 上架阻塞 (15 项)

| # | 问题 | 架构/底层 | 难度 | 来源 | 估时 |
|---|------|-----------|------|------|------|
| 1 | `native.dart:27` SQL 注入 — PRAGMA key 密码拼接 | 底层/安全 | 简单 | flutter-spec | 30min |
| 2 | `tracking_item_config.dart:9` import flutter in domain | 架构 | 中 | sp-en | 2-3h |
| 3 | `safetyCheckResultAlertedMocked` 3 语 mock/dev 字符串 | 底层/i18n | 简单 | sp-zh | 1h |
| 4 | `mood_detail_page.dart` 2 处硬编码中文 ("录音"/"删除") | 底层/i18n | 简单 | sp-zh | 30min |
| 5 | `add_medication_page.dart` 2 处硬编码中文 | 底层/i18n | 简单 | sp-zh | 30min |
| 6 | `medication_page.dart` "在用"/"已停" 硬编码中文 | 底层/i18n | 简单 | sp-zh | 30min |
| 7 | `today_summary_card.dart` 4 处硬编码中文 | 底层/i18n | 简单 | sp-zh | 1h |
| 8 | `daily_tracking_multi_chart.dart` 4 处硬编码中文 | 底层/i18n | 简单 | sp-zh | 1h |
| 9 | `PageTransitionSwitcher` 忽略 prefers-reduced-motion | 底层/a11y | 简单 | emil | 30min |
| 10 | `textHint` #999999 对比度 2.8:1 不满足 WCAG AA | 底层/a11y | 简单 | emil | 30min |
| 11 | `chroniccare.app` 域名 + 邮箱未注册 | 底层/外部 | 中 | App+GPlay | 1-2d |
| 12 | 法律文档 3 份未律师审核 | 底层/外部 | 高 | App+GPlay | 4-8 周 |
| 13 | Store description 描述已禁用功能 | 底层 | 简单 | AppStore | 30min |
| 14 | Release keystore 未生成 (Android) | 底层 | 简单 | GPlay | 30min |
| 15 | 无内容评级配置 (IARC + Apple) | 底层 | 中 | App+GPlay | 1-2d |

### P1 — 高概率打回 (20 项)

| # | 问题 | 架构/底层 | 难度 | 来源 |
|---|------|-----------|------|------|
| 1 | `mood_factor_analysis.dart` 硬编码颜色无 dark mode | 底层/UI | 简单 | flutter-spec |
| 2 | `cbt_three_column_mode.dart` 硬编码 Apple 颜色 | 底层/UI | 简单 | flutter-spec |
| 3 | `influence_category.dart` 36 个中文在 domain 层 | 架构/i18n | 中 | sp-zh |
| 4 | `care_copy.dart` 全部关怀文案硬编码中文 | 架构/i18n | 中 | sp-zh |
| 5 | `assessment_comparison.dart` 趋势标签硬编码中文 | 底层/i18n | 简单 | sp-zh |
| 6 | `mood_factor_analysis.dart:147` "条" 硬编码 | 底层/i18n | 简单 | sp-zh |
| 7 | `consent_gate.dart` 实现在 shared/ 依赖平台插件 | 架构 | 中 | sp-en |
| 8 | `app_database.dart` saveSetup() 业务逻辑在数据层 | 架构 | 中 | sp-en |
| 9 | `vent_compose_page.dart` 空 setState 整页重建 | 底层/性能 | 简单 | flutter-spec |
| 10 | `mood_audio_recorder_widget.dart` 100ms setState | 底层/性能 | 简单 | flutter-spec |
| 11 | 主页 hero + carousel 推 CTA 到折叠线以下 | 架构/UX | 中 | emil |
| 12 | `hero_illustration.dart` shadow dark mode 不可见 | 底层/UI | 简单 | emil |
| 13 | Decorative emoji 被 screen reader 朗读 | 底层/a11y | 简单 | emil |
| 14 | Dynamic Type 完全不支持 (Apple 2.5.1) | 底层/a11y | 中 | AppStore |
| 15 | 安全警报锁屏暴露敏感健康信息 | 底层/隐私 | 中 | AppStore |
| 16 | 邮件通知暴露药名+剂量 | 底层/隐私 | 中 | AppStore |
| 17 | SCHEDULE_EXACT_ALARM 运行时权限检查 | 底层 | 中 | GPlay |
| 18 | `day_detail.dart` 8 新量表显示 raw ID | 底层 | 简单 | flutter-spec |
| 19 | `check_in_entity.dart` scale IDs 硬编码重复 | 架构 | 简单 | flutter-spec |
| 20 | SharedPreferences.getInstance() 重复调用 8 次 | 底层/性能 | 简单 | sp-en |

### P2 — 上架后改进 (25 项)

| # | 问题 | 架构/底层 | 难度 |
|---|------|-----------|------|
| 1 | `_dateOnly` 4 处重复 → 统一 date_utils | 底层/DRY | 简单 |
| 2 | EncryptionService 每次重新实例化 | 底层/性能 | 简单 |
| 3 | EncryptedAudioStorage 用 Random() 非 secure | 底层/安全 | 简单 |
| 4 | windowSizeOf medium breakpoint 不可达 | 底层 | 简单 |
| 5 | HomeFabToolbar 无 Semantics 通知 | 底层/a11y | 简单 |
| 6 | QuickMoodCarousel 缺少 Semantics label | 底层/a11y | 简单 |
| 7 | 通知 channel 名中文 en/zh_Hant 看中文 | 底层/i18n | 简单 |
| 8 | 4 analyzer warning (unused var + inference) | 底层 | 简单 |
| 9 | 30 info (trailing commas + unawaited) | 底层 | 简单 |
| 10 | dead code `_VentWithdrawChoice` enum | 底层 | 简单 |
| 11-25 | 其余 P2 项 (详见 R103 报告) | 混合 | 混合 |

### P3 — 技术债 / Nice-to-have (15 项)

| # | 问题 | 架构/底层 | 难度 |
|---|------|-----------|------|
| 1 | Apple HealthKit 集成 | 架构 | 大 |
| 2-15 | 其余 P3 项 (详见 R103 报告) | 混合 | 混合 |

---

## 四、架构审视 (高内聚低耦合)

### 4.1 顶层架构评估

**当前架构**: `presentation → domain ← data` + `shared/` umbrella

**评估**: 架构设计优秀, 在国内中型 Flutter 项目中属天花板级别。

**优势**:
- domain 层 0 Flutter 依赖 (仅 1 处违规)
- 18 守门员自动守护架构边界
- 隐私边界严格 (vent 数据绝不泄露到 trend/assessment)
- FeatureFlag 门控所有未完成功能

**可优化点**:

| # | 模块 | 当前问题 | 建议方案 | 难度 |
|---|------|----------|----------|------|
| 1 | `tracking_item_config.dart` | domain 层 import flutter (IconData/Color) | 抽象为 domain 类 + presentation 层 wrapper | 中 |
| 2 | `consent_gate.dart` | SharedPrefsConsentGate 在 shared/ 有平台依赖 | 移到 data/repositories/, shared/ 只留抽象 | 中 |
| 3 | `app_database.dart` | saveSetup() 业务逻辑在数据层 | 抽 UseCase 到 domain/usecases/ | 中 |
| 4 | `notification_service.dart` | 450+ 行 god service | 再拆 1 层 facade 子服务 | 大 |
| 5 | `home_page_state.dart` | 650 行虽已拆但仍偏大 | 进一步拆 widget 子组件 | 中 |

### 4.2 可重构模块

| 模块 | 现状 | 重构建议 | 收益 |
|------|------|----------|------|
| `_dateOnly` 4 处重复 | trend_calculator / care_strategies / streak_calculator / date_utils 各有 | 统一到 `core/shared/date_utils.dart` | DRY |
| ScaleTranslations 70+ 方法 | 1 个接口 70 方法 | 按 scale 拆独立接口 | 可维护性 |
| SharedPreferences 重复获取 | safety_config 8 次 getInstance() | 缓存实例 | 性能 |
| 硬编码颜色 | 4 文件 12 处 Apple 系统颜色 | 集中到 AppTokens + dark mode | 一致性 |

---

## 五、底层逐行排查汇总

### 5.1 Bug 清单

| # | 文件:行 | Bug | 严重度 | 修复难度 |
|---|---------|-----|--------|----------|
| 1 | `native.dart:27` | PRAGMA key 密码拼接 SQL 注入 | HIGH | 简单 |
| 2 | `tracking_item_config.dart:9` | domain 层 import flutter | HIGH | 中 |
| 3 | `mood_detail_page.dart:219` | "录音" 硬编码中文 | MEDIUM | 简单 |
| 4 | `mood_detail_page.dart:256` | "删除" 硬编码中文 | MEDIUM | 简单 |
| 5 | `add_medication_page.dart:68` | "请输入药物名称" 硬编码 | MEDIUM | 简单 |
| 6 | `add_medication_page.dart:112` | "已添加" 硬编码 | MEDIUM | 简单 |
| 7 | `medication_page.dart:442` | "在用"/"已停" 硬编码 | MEDIUM | 简单 |
| 8 | `today_summary_card.dart` | 4 处硬编码中文 | MEDIUM | 简单 |
| 9 | `daily_tracking_multi_chart.dart` | 4 处硬编码中文 | MEDIUM | 简单 |
| 10 | `safetyCheckResultAlertedMocked` | mock/dev 用户可见字符串 | HIGH | 简单 |
| 11 | `cbt_three_column_mode.dart:96` | 硬编码颜色不适应 dark mode | MEDIUM | 简单 |
| 12 | `mood_factor_analysis.dart:105` | 硬编码颜色无 dark mode | MEDIUM | 简单 |
| 13 | `vent_compose_page.dart:441` | 空 setState 每次击键整页重建 | MEDIUM | 简单 |
| 14 | `mood_audio_recorder_widget.dart:197` | 100ms setState 每秒 10 次 | MEDIUM | 简单 |
| 15 | `day_detail.dart:364` | 8 新量表显示 raw ID | LOW | 简单 |
| 16 | `check_in_entity.dart:80` | scale IDs 硬编码重复 | LOW | 简单 |
| 17 | `legal_page.dart:448` | dead code enum | LOW | 简单 |

### 5.2 代码质量统计

| 指标 | 数值 | 状态 |
|------|------|------|
| Analyzer error | 0 | ✅ |
| Analyzer warning | 4 | ⚠️ (unused var × 2, inference × 2) |
| Analyzer info | 30 | ℹ️ (trailing commas + unawaited) |
| 守门员 | 18/18 | ✅ (check_all 1 违规已知) |
| 测试 | 2019 pass | ✅ |
| 架构违规 | 1 | ⚠️ (tracking_item_config.dart) |
| 硬编码中文 (用户可见) | ~20 处 | ⚠️ (需走 ARB) |
| 硬编码颜色 | 12 处 | ⚠️ (需走 AppTokens) |

---

## 六、半成品 / 未完成功能清单

| # | 功能 | 状态 | FeatureFlag | 说明 |
|---|------|------|-------------|------|
| 1 | 紧急联系人 SMS | 半成品 | emergencyContactEnabled=false | MockSmsProvider 早返 false |
| 2 | IAP 8 元买断 | 半成品 | iapEnabled=false | kDebugMode 直接返 true |
| 3 | 阿里云 SMS | 未实现 | aliyunSmsEnabled=false | AliyunSmsProvider.send 早返 false |
| 4 | EmailService | 未实现 | emailServiceEnabled=false | send() 返 false |
| 5 | 5 厂商 push SDK | 未实现 | fiveVendorPushEnabled=false | 早返 false |
| 6 | Vent audio 录音 | 半成品 | ventAudioEnabled=false | 隐藏 mic 按钮 |
| 7 | PHQ-9/GAD-7 i18n | 部分 | phqGad7I18nEnabled=false | 走 fallback key |
| 8 | BootReceiver | 暂停 | bootReceiverEnabled=false | 避 crash |
| 9 | NSESSS/CRDPSS 量表 | TODO | N/A | scale_registry 标 TODO |
| 10 | 8 新量表名称 | 部分 | N/A | day_detail 只处理 phq9/gad7 |

---

## 七、修复执行计划

### Sprint A — 上架阻塞 (P0, 1-2 周)

1. `native.dart` SQL 注入修复 (转义 → 参数化查询)
2. `tracking_item_config.dart` 架构违规修复 (抽象化)
3. 3 语 mock/dev 字符串清理 (~10 处 ARB key)
4. 6 处硬编码中文 → ARB (~15 个新 key)
5. `PageTransitionSwitcher` prefers-reduced-motion
6. `textHint` 对比度修复
7. 域名注册 + 邮箱
8. 法律文档律师审核
9. Store description 清理
10. Release keystore 生成
11. 内容评级配置

### Sprint B — 高优质量 (P1, 1-2 周)

1. 12 处硬编码颜色 → AppTokens + dark mode
2. domain 层 i18n (influence_category / care_copy / assessment_comparison)
3. 性能修复 (vent_compose setState / mood_audio setState)
4. a11y 修复 (ExcludeSemantics / Semantics labels)
5. 安全隐私 (锁屏通知 / 邮件通知)
6. SharedPreferences 缓存

### Sprint C — 架构改进 (P2, 2-3 周)

1. date_utils DRY
2. consent_gate 移层
3. saveSetup 抽 UseCase
4. analyzer warning 清理
5. dead code 清理

### Sprint D — 锦上添花 (P3, 持续)

1. Apple HealthKit 集成
2. Token 补全
3. 断点动画
4. Dynamic Type

---

**审计完成时间**: 2026-08-09
**审计人**: AI Agent (7 视角并行扫描)
**下次审计**: v0.31 或 Sprint A 完成后
