# R103 七视角综合审查报告

**审查日期**: 2026-08-08
**项目版本**: v0.30.0+85 (schema v21, 1997 tests, 18 guard scripts)
**审查范围**: 全部 389 Dart 文件 + fastlane + legal + android/ios 配置 + scripts + test
**审查视角**: emilkowalski / superpowers-en / superpowers-zh / flutter-specification / AppStore / GooglePlay / Apple Health

---

## 一、总览评分

| 视角 | 评分 | 上次 (R101) | 变化 | 关键发现 |
|------|------|-------------|------|----------|
| emilkowalski (UI/UX) | **8.5/10** | 9.0 | -0.5 | PageTransitionSwitcher 忽略 reduced-motion (Critical); textHint 对比度不足; 主页 CTA 被推到折叠线以下 |
| superpowers-en (工程) | **9.0/10** | 9.0 | 0 | 架构纯度 PASS; 4 个 Medium 级跨层依赖; domain 层 0 flutter/drift import |
| superpowers-zh (中文) | **8.0/10** | 8.0 | 0 | 1 处 P0 硬编码 (today_summary_card); ISI/PSS/WHODAS/ASRM 未走 translations; snooze/Mood 混英 |
| flutter-specification | **92%** | 88% | +4% | 0 High/Medium; 4 Low (deprecated dividerColor, tz double init); 50+ PASS |
| AppStore (iOS) | **6.5/10** | 6.5 | 0 | InfoPlist.strings 未用权限声明; 医疗免责声明未进 onboarding; 域名未注册 |
| GooglePlay (Android) | **40%** | 40% | 0 | Data Safety form 未填; IARC 未配; keystore 未生成 |
| Apple Health | **0/10** | N/A | 新视角 | 零集成; 本地追踪 10 类健康数据但不写入 HealthKit |

---

## 二、跨视角共识问题 (3+ 视角认同)

| # | 问题 | 层级 | 视角 | 修复难度 | 优先级 |
|---|------|------|------|----------|--------|
| 1 | `chroniccare.app` 域名 + 邮箱未注册 | 底层/外部 | AppStore + GPlay + spzh | 中 (1-2d + ICP 7-20d) | P0 |
| 2 | 法律文档 3 份未律师审核 (有 "TODO" 标记) | 底层/外部 | AppStore + GPlay + spzh | 高 (¥45-90k, 1-2 月) | P0 |
| 3 | 无内容评级配置 (IARC + Apple) | 底层 | AppStore + GPlay | 中 (1-2d) | P0 |
| 4 | Store description 描述已禁用功能 | 底层 | AppStore + GPlay | 简单 (30min) | P0 |
| 5 | 医疗免责声明未进 onboarding 流程 | 底层 | AppStore + GPlay | 简单 (2-3h) | P0 |
| 6 | 8 量表硬编码中文 (ISI/PSS/WHODAS/ASRM/Level2×4) | 底层/i18n | spzh + flutter-spec | 中 (1-2 周) | P1 |
| 7 | today_summary_card 4 处硬编码中文 | 底层/i18n | spzh + flutter-spec | 简单 (1-2h) | P0 |
| 8 | 无 Apple Health 集成 | 架构 | Apple Health | 高 (2-4 周) | P2 |
| 9 | home_page 信息密度太高, CTA 被推到折叠线以下 | 架构/UX | emil + spzh | 中 (1-2 周) | P1 |
| 10 | PageTransitionSwitcher 忽略 prefers-reduced-motion | 底层/a11y | emil | 简单 (5min) | P0 |

---

## 三、按优先级排序的完整问题清单

### P0 — 上架阻塞 / 必须修复 (15 项)

| # | 问题 | 层级 | 视角 | 难度 | 估时 |
|---|------|------|------|------|------|
| **1** | `native.dart:27` PRAGMA key SQL 注入风险 — 密码单引号转义不充分 | 底层/安全 | flutter-spec | 简单 | 1h |
| **2** | `chroniccare.app` 域名 + 邮箱未注册 (隐私政策 URL / 支持邮箱) | 底层/外部 | AppStore + GPlay | 中 | 1-2d + ICP |
| **3** | 法律文档 3 份未律师审核 (privacy_policy / user_agreement / sensitive_data_consent) | 底层/外部 | AppStore + GPlay | 高 | ¥45-90k |
| **4** | Store description 描述已禁用功能 (Apple 2.1 拒因) | 底层 | AppStore | 简单 | 30min |
| **5** | InfoPlist.strings 未用权限声明 (NSMicrophone / NSSpeechRecognition / NSUserTracking) | 底层 | AppStore | 简单 | 15min |
| **6** | `AndroidManifest.xml:54` android:label 硬编码中文 | 底层 | GooglePlay | 简单 | 10min |
| **7** | `today_summary_card.dart` 4 处硬编码中文 ('打卡'/'药物'/'心情'/'连续') | 底层/i18n | spzh | 简单 | 1-2h |
| **8** | 无内容评级配置 (IARC + Apple Age Rating) | 底层 | AppStore + GPlay | 中 | 1-2d |
| **9** | 医疗免责声明未进 onboarding 流程 (4 checkbox 缺 medical disclaimer) | 底层 | AppStore + GPlay | 简单 | 2-3h |
| **10** | PageTransitionSwitcher 忽略 prefers-reduced-motion (a11y 违规) | 底层/a11y | emil | 简单 | 5min |
| **11** | `textHint` (#999999) 在浅色背景对比度 2.8:1, 不满足 WCAG AA 4.5:1 | 底层/a11y | emil | 简单 | 30min |
| **12** | `daily_tracking_multi_chart.dart:164-170` 4 处硬编码中文 | 底层/i18n | spzh | 简单 | 1h |
| **13** | 双平台真实截图缺失 (36 张占位 PNG 已删) | 底层 | AppStore + GPlay | 中 | 1-2d |
| **14** | Release keystore 未生成 (Android) | 底层 | GooglePlay | 简单 | 30min |
| **15** | iOS 签名未配置 (需 Mac) | 底层 | AppStore | 简单 | 1h |

### P1 — 高概率打回 / 用户可见 (20 项)

| # | 问题 | 层级 | 视角 | 难度 | 估时 |
|---|------|------|------|------|------|
| **1** | ISI/PSS/WHODAS/ASRM 4 量表 displayName/items/options 硬编码中文, 未走 translations | 底层/i18n | spzh | 中 | 1-2 周 |
| **2** | Level2 Depression/Anxiety/Mania/Psychosis 4 量表同上 | 底层/i18n | spzh | 中 | 1-2 周 |
| **3** | `SleepEntryEntity.durationLabel` 硬编码英文格式 ('8h30min') | 底层/i18n | spzh | 简单 | 2-3h |
| **4** | `TreatmentEntryEntity.linkedMedicationDisplay` 硬编码中文 ('无关联') | 底层/i18n | spzh | 简单 | 1h |
| **5** | `AssessmentComparison.trendLabel/deltaLabel` 硬编码中文 ('好转'/'恶化'/'持平') | 底层/i18n | spzh | 简单 | 2-3h |
| **6** | `InfluenceCategory.kInfluenceFactors` 30+ 预设标签硬编码中文 | 底层/i18n | spzh | 中 | 1-2d |
| **7** | `care_copy.dart` 4 个触发文案硬编码中文 | 底层/i18n | spzh | 简单 | 1-2h |
| **8** | `medication_report.dart toReportString()` 多处硬编码中文 | 底层/i18n | spzh | 中 | 1-2d |
| **9** | 通知 channel 名 const 中文, en/zh_Hant 系统设置看中文 | 底层/i18n | spzh | 简单 | 1-2h |
| **10** | Medication page error state 显示原始异常字符串 (无 ErrorState widget) | 底层/UX | emil | 简单 | 1-2h |
| **11** | 主页 hero (140px) + carousel (80px) 推 CTA 到折叠线以下 | 架构/UX | emil | 中 | 1-2 周 |
| **12** | `success` 与 `primary` 颜色太接近, 用户无法区分 | 底层/UX | emil | 简单 | 1h |
| **13** | `windowSizeOf` medium breakpoint 不可达 (840=840) | 底层 | emil | 简单 | 30min |
| **14** | hero illustration 用 emoji — 跨平台渲染不一致 | 底层/UX | emil | 中 | 1-2d |
| **15** | Decorative emoji 被 screen reader 朗读 | 底层/a11y | emil | 简单 | 30min |
| **16** | `minTapArea` token 定义但未系统性强制 | 底层/a11y | emil | 中 | 1-2d |
| **17** | `app_database.dart saveSetup()` 业务逻辑在数据层 (60+ 行) | 架构 | spen | 中 | 1-2 周 |
| **18** | `SharedPrefsConsentGate` 在 shared 层 import shared_preferences | 架构 | spen | 简单 | 1-2h |
| **19** | `FeatureFlags` data 层 import flutter/foundation | 架构 | spen | 简单 | 30min |
| **20** | 6 个 daily tracking entity + repository 无 domain 层测试 | 底层/测试 | spen | 中 | 1-2 周 |

### P2 — 上架后改进 (25 项)

| # | 问题 | 层级 | 视角 | 难度 |
|---|------|------|------|------|
| 1 | 无 Apple Health 集成 (本地追踪 10 类数据但不写入 HealthKit) | 架构 | Apple Health | 高 |
| 2 | 通知 service 450 行 god class 再拆 1 层 facade | 架构 | spen | L |
| 3 | `home_page_state.dart` 650 行拆分 | 架构 | spen | L |
| 4 | iOS iCloud Backup 未排除 (敏感健康数据可能同步到 iCloud) | 底层 | AppStore | S |
| 5 | 13 步字体太多 (建议 8-9 步) | 底层/UX | emil | M |
| 6 | Button text 20px 对所有按钮一样大, 无 primary/secondary 区分 | 底层/UX | emil | S |
| 7 | Medication empty states 未用共享 EmptyState widget | 底层/UX | emil | S |
| 8 | QuickMoodCarousel 固定高度不尊重文本缩放 | 底层/a11y | emil | S |
| 9 | PressFeedback mode 2 无桌面 hover cursor | 底层/a11y | emil | S |
| 10 | 无 focus indicator 样式 (按钮/卡片) | 底层/a11y | emil | M |
| 11 | `day_detail.dart` / `check_in_entity.dart` 中文 fallback 对 en 用户不友好 | 底层/i18n | spzh | S |
| 12 | `strings.dart` moodLabel 中文 fallback 无 override | 底层/i18n | spzh | S |
| 13 | snooze 混英 ('💊 提醒吃药（snooze）') | 底层/i18n | spzh | XS |
| 14 | Mood 混英 ('Mood 历史' / '还没有 mood 记录') | 底层/i18n | spzh | XS |
| 15 | ASRM 题目 L0 混入英文 '(elevated mood)' | 底层/i18n | spzh | XS |
| 16 | 节假日数据不含 2031+ 年份 | 底层 | spzh | XS |
| 17 | `Theme.of(context).dividerColor` deprecated (2 处) | 底层 | flutter-spec | XS |
| 18 | `_nextReminderTime()` 未用 tz.TZDateTime | 底层 | flutter-spec | XS |
| 19 | `tz_data.initializeTimeZones()` 重复调用 | 底层 | flutter-spec | XS |
| 20 | SharedPreferences.getInstance() 在 safety_config_service 重复调用 8 次 | 底层/性能 | spen | S |
| 21 | `EncryptionService()` 在 legal_consent_provider 每次调用重新实例化 | 底层/性能 | spen | S |
| 22 | phone validation regex domain/data 间重复 | 架构 | spen | S |
| 23 | `backgroundColor` 与 `surfaceColor` 返回相同值 | 底层/UX | emil | XS |
| 24 | `warningStrong` 属于 domain 层语义, 不应在 token 层 | 架构 | emil | XS |
| 25 | 无 crash reporting (Firebase Crashlytics / Sentry) | 底层 | AppStore + GPlay | M |

### P3 — 技术债 / 锦上添花 (15 项)

| # | 问题 | 层级 | 视角 |
|---|------|------|------|
| 1 | 间距 scale 24/40 与小 token 组合重叠 | 底层/UX | emil |
| 2 | `SizedBox(height: 2)` 等未使用 token | 底层/UX | emil |
| 3 | `EmptyState` 容器 96x96 未 token 化 | 底层/UX | emil |
| 4 | Emoji 尺寸在 hero illustration 中是 magic number | 底层/UX | emil |
| 5 | Cards 用 border 不用 shadow — 设计选择 | 底层/UX | emil |
| 6 | `sharedPreferencesProvider` throw UnimplementedError 消息不够详细 | 底层 | flutter-spec |
| 7 | 无 typed routes (string-based paths) | 架构 | flutter-spec |
| 8 | flutter_lints 可迁移到 very_good_analysis | 底层 | flutter-spec |
| 9 | `Random.secure()` vs `FortunaRandom` (理论安全差异) | 底层/安全 | flutter-spec |
| 10 | FeatureFlags 全局静态可变状态 | 底层 | flutter-spec |
| 11 | 5 厂商 + 鸿蒙适配 | 架构 | spzh |
| 12 | TestFlight 100+ 真实用户测试 | 底层 | spzh + AppStore |
| 13 | AudioController 抽象 (vent + mood 共享) | 架构 | emil |
| 14 | 无 CI/CD 配置文件在 repo 中 | 架构 | spen |
| 15 | Integration test 仅 2 文件, 覆盖不足 | 底层/测试 | spen |

---

## 四、视角独有发现

### 4.1 emilkowalski 视角 (UI/UX)

**Critical (1)**:
- `page_transition_switcher.dart:56-57`: `switchInCurve/switchOutCurve` 未用 `Motion.curve(context, ...)` 包装, 忽略 prefers-reduced-motion

**High (3)**:
- `medication_page.dart:162`: error state 显示原始异常, 未用 ErrorState widget
- `home_page_state.dart:339-364`: hero + carousel 推 CTA 到折叠线以下
- `app_colors.dart:42`: textHint #999999 对比度 2.8:1, 不满足 WCAG AA

**Medium (9)**:
- 字体 13 步太多; button 20px 无主次区分; success/primary 颜色接近; windowSizeOf medium 不可达; emoji 跨平台不一致; minTapArea 未强制; decorative emoji 被朗读; QuickMoodCarousel 固定高度; 无 focus indicator

### 4.2 superpowers-en 视角 (工程)

**Domain 纯度**: PASS (0 violations, 70 文件全部通过)
**架构一致性**: PASS (Entity ↔ @DataClassName 1:1 mapping)
**跨层依赖**: 4 个 Medium
- `consent_gate.dart` shared 层 import shared_preferences
- `feature_flags.dart` data 层 import flutter/foundation
- `app_database.dart` saveSetup() 60+ 行业务逻辑在数据层
- phone validation regex domain/data 间重复

**SQL 注入**: PASS (Drift 参数化查询, 唯一 raw SQL 是 PRAGMA/ALTER)
**资源泄漏**: PASS (所有 StreamSubscription.cancel / AnimationController.dispose / Timer.cancel 正确)
**竞态条件**: PASS (历史修复已应用: streak_calculator/assessment_comparison/reminder_scheduler 显式排序)

### 4.3 superpowers-zh 视角 (中文体验)

**正面发现 (9)**:
- zh/zh_Hant 同步机制完善 (OpenCC s2tw 自动校验)
- 精神心理术语去病耻感化 (R72/R77 系列修复)
- PHQ-9/GAD-7 翻译与标准中文版高度一致
- 危机热线覆盖中国四地 + 海外
- PIPL 法律合规文案准确
- 全角标点规范
- 17 个守门员脚本覆盖全面
- 用药预置方案术语准确
- 日期时间格式规范

**问题**: 1 P0 + 2 P1 + 7 P2 + 7 P3 (详见 §三)

### 4.4 flutter-specification 视角

**50+ 项 PASS, 0 High, 0 Medium, 4 Low, 5 Info**

关键 PASS:
- SDK constraint >=3.4.0 <4.0.0
- strict-casts/strict-inference/strict-raw-types 全开
- Riverpod 3.x 正确用法 (ref.watch in build, ref.read in callback)
- Drift 2.x 正确用法 (DAO, migration, connection)
- go_router ShellRoute + CustomTransitionPage
- runZonedGuarded + LastErrorCapture 全局错误处理
- FlutterSecureStorage + AES-256-CBC 加密
- unawaited() + swallowError 模式

### 4.5 AppStore (iOS) 视角

**28 项检查: 20 PASS / 3 Warning / 2 Fail / 3 Not Submitted**

Fail:
- 域名未注册 (隐私政策 URL 不可达)
- 支持 URL 不存在

Warning:
- InfoPlist.strings 仍声明未用权限 (mic/speech/tracking)
- 年龄评级不一致 (12+ vs 17+)
- IARC 未配

### 4.6 GooglePlay (Android) 视角

**22 项检查: 16 PASS / 1 Warning / 0 Fail / 5 Not Submitted**

PASS:
- targetSdk=36, minSdk=24
- 16KB page alignment (sqlcipher_flutter_libs >= 0.6.5)
- ProGuard/R8 enabled
- 64-bit ABI only
- 无 SMS/Call 权限
- 无 Advertising ID

Not Submitted:
- Data Safety form
- Health Apps questionnaire
- Content rating (IARC)
- Release keystore
- iOS signing

### 4.7 Apple Health 视角

**零集成**: 项目不引用 `health_kit` / `HKHealthStore` / 任何 Apple Health SDK。但本地追踪 10 类健康数据:
1. 用药打卡 (CheckIns)
2. 情绪日记 (MoodEntries, 4 维度 + CBT)
3. 睡眠追踪 (SleepEntries)
4. 社交节律 (SocialRhythmEntries)
5. 压力事件 (StressEvents)
6. 治疗记录 (TreatmentEntries)
7. 体重 BMI (WeightEntries)
8. 焦虑激越 (AnxietyAgitationEntries)
9. 心理评估 (10 量表)
10. 树洞倾诉 (VentEntries, 加密)

**建议**: v1.0 后考虑 `health` package 双向同步 (写入 HealthKit: medication/weight/sleep; 读取 HealthKit: step count/heart rate)。当前架构 (domain 层纯 Dart) 为此预留了良好基础 — HealthKit 集成可作为 data 层 service 实现, 不影响 domain 纯度。

---

## 五、架构审视

### 5.1 高内聚低耦合评估

**做得好的**:
- 4 层架构 (presentation → domain ← data) + shared umbrella 严格维护
- domain 层 0 flutter/drift import (check_all.dart 自动验证)
- presentation 按 feature 拆目录, check_cross_feature.py 防止跨 feature 耦合
- 14 DAO 从 AppDatabase 提取, 职责清晰
- Entity ↔ @DataClassName 1:1 映射, mapper 层翻译完整

**需改进的**:
- `app_database.dart` saveSetup() 60+ 行业务逻辑 (应在 usecase 层)
- `SharedPrefsConsentGate` 在 shared 层 import SharedPreferences (应移 data 层)
- `FeatureFlags` data 层 import flutter/foundation (仅 @visibleForTesting 注解)
- `notification_service.dart` 450 行 god class (R78 已拆 facade, 但可再拆)
- `home_page_state.dart` 650 行 (R95 已拆, 但仍包含 9 个 business method)

### 5.2 可重构模块

| 模块 | 当前状态 | 建议 | 难度 |
|------|----------|------|------|
| notification_service | 450 行, 6 sub-service | 再拆 1 层 facade (按 channel 类型) | L |
| home_page_state | 650 行, 9 method | 抽 HomeViewModel usecase | M |
| app_database.saveSetup | 60+ 行业务逻辑 | 抽 SaveSetupUseCase | M |
| ISI/PSS/WHODAS/ASRM | 硬编码中文 | 参照 PHQ-9/GAD-7 走 translations | M |
| AudioController | vent + mood 各自实现 | 抽共享 AudioController 抽象 | L |
| MoodEntryDraft | 20+ 参数构造函数 | 改用 copyWith 模式 | S |

---

## 六、半成品 / 待完成清单

| # | 模块 | 状态 | 说明 |
|---|------|------|------|
| 1 | IAP | FeatureFlag=false | 无 productId, 无 App Store Connect 配置 |
| 2 | SMS (阿里云) | MockSmsProvider | send() 抛 UnimplementedError |
| 3 | Email (SendGrid) | MockEmailProvider | 无 API key |
| 4 | 5 厂商 push | 未接入 | 需 1-2 月审核 |
| 5 | vent audio | FeatureFlag=false | 录音/播放功能已实现但开关关闭 |
| 6 | boot receiver | FeatureFlag=false | 半实现 |
| 7 | PHQ-9/GAD-7 i18n | 部分完成 | ARB key 存在但临床审核未做 |
| 8 | Apple Health | 未开始 | 零集成 |
| 9 | crash reporting | 未接入 | 无 Firebase/Sentry |
| 10 | TestFlight/beta | 未做 | 无真实用户测试 |

---

## 七、外部链接安全确认

**运行时代码**: ✅ 0 外部链接泄露
- 唯一 url_launcher 使用 = `tel:` 危机热线 (phq9.dart:161-188)
- 无 http/https URL 硬编码
- 无第三方 SDK 泄露设备信息

**上架物料层**: ⚠️ 未就绪
- `chroniccare.app` 域名未注册
- `privacy@chroniccare.app` / `support@chroniccare.app` 邮箱不存在
- fastlane metadata 有占位 URL

---

## 八、Apple Health 集成建议

### 8.1 推荐集成方案

| 优先级 | 数据类型 | 方向 | 说明 |
|--------|----------|------|------|
| P1 | 用药打卡 | 写入 HealthKit | HKCategoryType.medicationTracking (iOS 16+) |
| P1 | 体重 BMI | 双向同步 | HKQuantityType.bodyMass + bodyMassIndex |
| P1 | 睡眠 | 双向同步 | HKCategoryType.sleepAnalysis |
| P2 | 情绪 | 写入 HealthKit | HKStateOfMind (iOS 17.4+) |
| P2 | 心率/步数 | 读取 HealthKit | 作为情绪影响因素参考 |
| P3 | 运动时间 | 读取 HealthKit | 社交节律 exercise minutes |

### 8.2 技术方案

```yaml
# pubspec.yaml 新增
health: ^12.0.0  # Flutter HealthKit/Health Connect plugin
```

```
lib/core/data/services/
  health_sync_service.dart    # 新增 — HealthKit 读写
  health_sync_repository_impl.dart  # 新增 — 实现 domain 接口
lib/domain/repositories/
  health_sync_repository.dart  # 新增 — 抽象接口
```

**关键约束**: domain 层不引入 health package, 通过 repository 接口解耦。

---

## 九、修复执行计划

### Sprint A — 上架阻塞 (P0, 1-2 周)

| Day | Task | 难度 |
|-----|------|------|
| D1 | #1 PRAGMA key SQL 注入修复 | 简单 |
| D1 | #5 InfoPlist.strings 清理未用权限 | 简单 |
| D1 | #6 AndroidManifest 硬编码中文 | 简单 |
| D1 | #7 today_summary_card 硬编码中文 → ARB | 简单 |
| D1 | #10 PageTransitionSwitcher reduced-motion | 简单 |
| D1 | #11 textHint 对比度修复 | 简单 |
| D1 | #12 daily_tracking_multi_chart 硬编码中文 | 简单 |
| D2 | #4 Store description 删禁用功能描述 | 简单 |
| D2 | #9 医疗免责声明加到 onboarding | 简单 |
| D2 | #14 生成 release keystore | 简单 |
| D3-5 | #8 IARC 内容评级配置 | 中 |
| D3-5 | #13 真实截图制作 | 中 |
| D1-20 | #2 域名注册 + ICP 备案 | 中 |
| D1-60 | #3 法律文档律师审核 | 高 |

### Sprint B — 高优质量 (P1, 1-2 周)

| Task | 难度 |
|------|------|
| ISI/PSS/WHODAS/ASRM/Level2×4 走 translations | 中 |
| SleepEntryEntity/TreatmentEntryEntity i18n | 简单 |
| AssessmentComparison i18n | 简单 |
| care_copy / medication_report i18n | 中 |
| 通知 channel 名 i18n | 简单 |
| Medication page error state 用 ErrorState | 简单 |
| 主页信息架构重排 (hero 高度缩减) | 中 |
| windowSizeOf breakpoint 修复 | 简单 |

### Sprint C — 架构改进 (P2, 2-3 周)

| Task | 难度 |
|------|------|
| saveSetup 抽 UseCase | 中 |
| SharedPrefsConsentGate 移到 data 层 | 简单 |
| FeatureFlags 去 flutter import | 简单 |
| daily tracking entity 测试补全 | 中 |
| notification_service 再拆 | 高 |
| home_page_state 再拆 | 中 |
| Apple Health 集成 (P1: 用药/体重/睡眠) | 高 |
| iCloud Backup 排除 | 简单 |

---

## 十、统计摘要

| 分类 | 数量 |
|------|------|
| P0 (上架阻塞) | 15 |
| P1 (高概率打回) | 20 |
| P2 (上架后改进) | 25 |
| P3 (技术债) | 15 |
| **合计** | **75** |
| 可代码化修复 | 62 (83%) |
| 需外部资源 | 13 (17%) |
| 架构级 | 15 (20%) |
| 底层级 | 60 (80%) |

**与 R101 对比**: R101 报 65 项, 本轮新增 10 项 (Apple Health 视角 + emil a11y 发现 + 性能问题), 合并去重后 75 项。
