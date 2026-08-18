# Apple Health / HealthKit 集成差距审计 (2026-08-10 / R106)

**项目**: ChronicCare v0.30.0+85 (schemaVersion **22**)
**审计日期**: 2026-08-10
**审计基线**: R105 `docs/audit/2026-08-09/review-round-105/07-apple-health.md` (12 项 AH-1 ~ AH-12, 评分 N/A)
**审计人**: AI Agent (Apple Health / HealthKit 视角)
**审计方式**: 全文件 grep + 逐项实读 + 上下游交叉比对

---

## 评分

**N/A → 维持 2/10** (vs R104 2/10 / R105 N/A)
**架构就绪度**: 8/10 (差最后一公里 — 数据模型、4 维情绪、影响因素标签、睡眠/体重/焦虑/应激全部就绪,只缺同步 service 层 + iOS 配置 + 平台包)
**功能就绪度**: 1/10 (无任何 HealthKit 运行时代码,无任何配置,无任何 UI 入口)

---

## 一、当前 HealthKit / Health Connect 集成状态 (精确逐项核验)

> 与 R105 一致性确认: 全部 7 项硬性零集成事实**维持**。本轮 R106 新增事实: schemaVersion 已升 22 (R105 当时是 21) + 新增 1 个 `recordingMode` 列 + `medication-redesign-apple-health.md` spec 已部分落地。

| 检查项 | 结论 | 证据 |
|--------|------|------|
| `health` 包 | ❌ 无依赖 | `pubspec.yaml:11-97` 全量扫描 0 命中;`pubspec.lock` 0 命中 |
| `health_kit` / `health_kit_reporter` | ❌ 无依赖 | 同上 |
| `health_connect` (Android) | ❌ 无依赖 | 同上 |
| `flutter_health_connect` | ❌ 无依赖 | 同上 |
| `com.apple.developer.healthkit` entitlement | ❌ 无 | `ios/Runner/Runner.entitlements` 为空 dict (R70 删 aps-environment 后仅留注释) |
| `NSHealthShareUsageDescription` | ❌ 无 | `ios/Runner/Info.plist:1-160` 0 命中 |
| `NSHealthUpdateUsageDescription` | ❌ 无 | 同上 |
| `NSHealthRecordsUsageDescription` | ❌ 无 | 同上 (Clinical Health Records 完全没考虑) |
| `android.permission.health.READ_*` (Health Connect) | ❌ 无 | `android/app/src/main/AndroidManifest.xml:39-48` 0 命中 |
| HKHealthStore / HKObserverQuery / HKAnchoredObjectQuery 代码 | ❌ 无 | `lib/` + `ios/Runner/*.swift` 全量 grep 0 命中 |
| HealthConnectClient (Android) | ❌ 无 | 同上 |
| `UIBackgroundModes` 后台能力 | ❌ 无 | R100 (2026-08-08) 删 audio/processing,HealthKit 也没占位 |
| `BGTaskScheduler.register` | ❌ 无 | R100 同上,`AppDelegate.swift:25-28` 注释明确"业务真接再加回" |
| `healthKitEnabled` / `healthConnectEnabled` FeatureFlag | ❌ 无 | `lib/core/data/feature_flags.dart:44-148` 8 个 flag 全不涉及 Health |
| ProviderScope HealthKit 服务注册 | ❌ 无 | `lib/presentation/providers/core_providers.dart` 0 命中 |
| PrivacyInfo.xcprivacy 适配 | ✅ 部分就绪 | `HealthAndFitness` 类型已声明 (Linked=false / Tracking=false / AppFunctionality) — 加 HealthKit 后**无需改类型** |
| Android `data_extraction_rules.xml` Health 声明 | ❌ 无 | 无 Health Connect 角色声明 |

**结论**: HealthKit 集成度维持 **0**。**所有零集成事实与 R105 完全一致**。本轮新增的是 schemaVersion 21→22 升级 (recordingMode 列),以及 R101 已落地的 `medication_page.dart` / `influenceFactorsJson` / `medication_form.dart` 与 Apple Health State of Mind + Medications 设计的字段对齐。

---

## 二、可同步的健康数据类型 (全表映射,10 类 + 6 类追踪 + 2 类元数据)

> 13 张业务表 + 1 张 `user_profiles` + 1 张 `report_histories` + 1 张 `contacts` 共 16 张表,逐一映射。

### 2.1 主映射表

| # | App 数据 | 存储位置 | HealthKit Type (iOS) | Health Connect (Android) | 双向价值 | 集成难度 | 阶段 |
|---|----------|----------|----------------------|--------------------------|----------|----------|------|
| 1 | **sleep** | `daily_tracking/sleep_entries.dart` | `HKCategoryTypeIdentifier.sleepAnalysis` (inBed + asleepCore + asleepDeep + asleepREM) | `SleepSessionRecord` (Google Sleep Stages 2024) | **HIGH** 双向:用户戴 Apple Watch / 床带 → App 自动拿;App 写 → Apple Health 趋势图 | 中 | **P0** |
| 2 | **weight** | `daily_tracking/weight_entries.dart` | `HKQuantityTypeIdentifier.bodyMass` (kg) | `WeightRecord` (kg) | **HIGH** 双向:智能秤 / Withings / Mi Body Scale 自动写 HK,App 镜像 | 简单 | **P0** |
| 3 | **mood** | `mood/mood_entries.dart` (score/period/influenceFactors) | `HKCategoryTypeIdentifier.stateOfMind` (iOS 17+, pleasantness 1-5 + labels) | `MoodRecord` (Google 2024 新增) | **HIGH** 单向 (App → HK):App 评分比 HK 滑动块精细 (4 维);Apple Health 趋势图补充 | 中 | **P0 写** / **P1 读** |
| 4 | **mindful minutes** (正念) | 无表(可衍生) | `HKCategoryTypeIdentifier.mindfulSession` | `MindfulnessSessionRecord` | **MEDIUM**:vent audio 录音可映射为 mindful session(保护隐私) | 简单 | **P1** |
| 5 | **medication dose** | `medication/medications.dart` + `check_in/check_ins.dart` | `HKMedicationDoseType` (iOS 16+) + `HKMedicationConcept` | `MedicationRecord` (Google 2024) | **MEDIUM** 单向 (App 写):但**卡点严重**(见 §5) | 大 | **P2** |
| 6 | **steps / exercise** | `social_rhythm_entries.exerciseMin` (粗粒度) | `HKQuantityTypeIdentifier.stepCount` + `appleExerciseTime` | `StepsRecord` + `ExerciseSessionRecord` | LOW:App 1 天 1 条粗粒度 vs HK 实时 | 简单 | **P3** |
| 7 | **anxiety 急躁** | `daily_tracking/anxiety_agitation_entries.dart` | 无直接对应;可映射到 `stateOfMind` 的次级维度 | 无 | LOW | — | 不映射 |
| 8 | **assessment (PHQ-9/GAD-7)** | `check_ins.dart` (note=JSON) | 无标准类型;Clinical Health Records 可走 CDA/FHIR | 无 | LOW:需医疗机构背书,不适配 | — | 不映射 |
| 9 | **social rhythm** | `daily_tracking/social_rhythm_entries.dart` | 无直接对应;可拆 meals/social → 日历事件 | 无 | LOW | — | 不映射 |
| 10 | **stress events** | `daily_tracking/stress_events.dart` | 无对应 | 无 | — | — | 不映射 |
| 11 | **treatment** | `daily_tracking/treatment_entries.dart` | 无对应 | 无 | — | — | 不映射 |
| 12 | **vent** | `mood/vent_entries.dart` (contentTextEnc + audio) | **严禁**映射 (隐私边界) | **严禁**映射 | — | — | 永久不映射 |
| 13 | **check-in (streak)** | `check_in/check_ins.dart` | 无对应;可走 `HKCorrelation` 自定义 | 无 | — | — | 不映射 |
| 14 | **mood audio** | `mood_entries.audioPath` | **严禁**映射 (隐私边界) | **严禁**映射 | — | — | 永久不映射 |
| 15 | **contact** | `contact/contacts.dart` | 无对应 | 无 | — | — | 不映射 |
| 16 | **user profile** | `user_profile/user_profiles.dart` | 无对应 (HK 无用户档案字段) | 无 | — | — | 不映射 |

### 2.2 阶段分组总结

| 阶段 | 数据类型 | 数量 | 业务理由 |
|------|----------|------|----------|
| **P0** (地基) | sleep + weight + mood (写) | 3 类 | 最常用 + 最成熟 HK API + 双向价值高 |
| **P1** (心智正念) | mood (读) + mindful minutes (vent→mindful) | 2 类 | mood 镜像 Apple Health 趋势图;vent 录音转化为正念会话 |
| **P2** (用药) | medication dose | 1 类 | 卡点大 (自由文本药名 + 按天打卡粒度),需要先做通用名映射表 + CheckIn 时点化 |
| **P3** (运动) | steps / exercise | 1 类 | 边角补充,粗粒度 |
| **不映射** | anxiety/assessment/social_rhythm/stress/treatment/vent/audio/check-in/profile/contact | 11 类 | HK 无对应或隐私边界 |

---

## 三、集成路径 (4 阶段,4-7 周)

> 通用前置: **Mac 必须** + Apple Developer Program ($99/年) + 真机 (HK 在模拟器不可用) + Windows 环境 0 项满足,需 R107+ 切到 Mac dev 链路。

### 阶段 0: 准备 (1 周,无 Mac 不阻塞)

**目标**: 提前在 Dart 层完成所有无平台依赖的代码,Mac 到位后只做 iOS 配置 + 真机测试。

- [ ] **P0-0.1** 加 `health: ^10.x` 到 `pubspec.yaml` (iOS HealthKit + Android Health Connect 双平台)
  - 候选: `health` (官方社区) | `health_kit` (iOS-only) | 自写 method_channel
  - **推荐 `health`** (生态最稳、文档全、跨平台)
- [ ] **P0-0.2** 加 `_prodHealthKitEnabled = false` + `_currentHealthKitEnabled` + 7 个 getter/setter 到 `lib/core/data/feature_flags.dart`
  - 沿用 R66/R93 模式: prod const + nullable override + 8 个 per-flag setter
- [ ] **P0-0.3** 新建 `lib/core/data/services/health/health_kit_service.dart` 抽象 (domain 接口 `HealthKitService` 放 `lib/domain/services/`)
  - 方法: `requestAuthorization()` / `readSleep()` / `readWeight()` / `readStateOfMind()` / `writeSleep()` / `writeWeight()` / `writeStateOfMind()` / `observeChanges()`
- [ ] **P0-0.4** schemaVersion **22 → 23**: `sleep_entries` / `weight_entries` / `mood_entries` 三表各加 2 列
  - `healthKitUuid TEXT NULL` (HKUUID 字符串,去重键)
  - `healthKitSource TEXT NULL` (HKSource.identifier,调试用)
  - 迁移脚本: `app_database.dart` 三表各 `addColumn` + `if (from < 23) { ... }` 守卫
- [ ] **P0-0.5** 写测试: `health_kit_service_mock.dart` + 5 个 unit test (mock HK 不依赖 platform channel)
- [ ] **P0-0.6** 业务侧不动: UI 入口全部 `if (FeatureFlags.healthKitEnabled) ...` 门控,默认隐藏

### 阶段 1: iOS HealthKit 接入 + 只读镜像 (1-2 周,需 Mac)

**目标**: 走通 `weight.bodyMass` 双向 + `sleepAnalysis` 单向读 + `stateOfMind` 写,获取真机跑通经验。

- [ ] **P1-1.1** Mac 环境就位 + `flutter create --platforms=ios .` + `pod install` 生成 `ios/Podfile`
- [ ] **P1-1.2** Apple Developer 后台: 给 `com.chroniccare.chroniccare` App ID 加 HealthKit capability + 重新生成 provisioning profile
- [ ] **P1-1.3** Xcode 打开 `ios/Runner.xcworkspace` → Target → Signing & Capabilities → **+ HealthKit** (自动写入 `Runner.entitlements` 加 `com.apple.developer.healthkit`)
- [ ] **P1-1.4** 改 `ios/Runner/Info.plist` 加 2 个 key (英文基线):
  ```xml
  <key>NSHealthShareUsageDescription</key>
  <string>Allow ChronicCare to read your sleep, weight, and mood data so your daily tracking stays complete even across devices.</string>
  <key>NSHealthUpdateUsageDescription</key>
  <string>Allow ChronicCare to write your medication, sleep, weight, and mood records to the Health app as a personal backup you control.</string>
  ```
- [ ] **P1-1.5** 同步改 `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` per-locale 覆盖 (沿用 R70/R100 多语规则)
- [ ] **P1-1.6** `HealthKitService` 写实现 `HealthKitServiceImpl` (用 `health` 包):授权 + `getHealthDataFromTypes(types: [HealthDataType.WEIGHT, SLEEP])` 拉历史 90 天
- [ ] **P1-1.7** 写 `HealthSyncOrchestrator`: 拉 HK 数据 → 按 `healthKitUuid` 去重 → 写本地 SQLCipher
- [ ] **P1-1.8** 写 `HealthRepository` (domain) + `HealthRepositoryImpl` (data),注册到 `core_providers.dart`
- [ ] **P1-1.9** UI: 设置页加 "Apple Health 同步" 入口 (FeatureFlag 门控),进入后:总开关 + 4 类数据分开关 + 上次同步时间 + 同步历史
- [ ] **P1-1.10** 测试: 1 个集成测试 (mock HK + ProviderScope override 走通 sync 流程) + 3 个 widget test (UI 状态)
- [ ] **P1-1.11** 隐私文案: `assets/legal/sensitive_data_consent.md` 加 HealthKit 章节,`assets/legal/privacy_policy.md` 改"零云端" → "经用户控制的 iCloud Health 同步"
- [ ] **P1-1.12** `check_legal_consent.py` 守门员同步加新章节白名单

### 阶段 2: 写入 + 冲突解决 + Android Health Connect (1-2 周)

**目标**: 双向同步上线 + Android 平价体验。

- [ ] **P2-1.1** `HealthKitServiceImpl` 写本地 → HK (`save` 体重/睡眠/情绪)
- [ ] **P2-1.2** 冲突解决: 比 `sourceRevision.modifiedDate`,新赢;`healthKitUuid` 幂等去重;App 本地优先 (不覆盖本地手工数据)
- [ ] **P2-1.3** 隐私过滤: 禁 HK 读 vent / mood audio 字段(尽管项目本来也不写这些,但加白名单防未来误传)
- [ ] **P2-1.4** Android: `pubspec.yaml` `health` 包自动支持 Health Connect → `android/app/src/main/AndroidManifest.xml` 加 `<uses-permission android:name="android.permission.health.READ_STEPS"/>` 等
- [ ] **P2-1.5** Android 11+ 设备需装 Health Connect App → 加 "Health Connect 未安装" 检测 + 引导
- [ ] **P2-1.6** 写回测试: 1 个 round-trip (App 写 → HK 读回 → 校验字段一致)
- [ ] **P2-1.7** App 内"同步总开关" + 4 类分开关 + 撤销权限入口 (Apple Guideline 要求)

### 阶段 3: 后台同步 + 用药 P3 (1-2 周,P3 nice-to-have)

- [ ] **P3-1.1** `HKObserverQuery` + `enableBackgroundDelivery(.immediate)` (iOS 后台,系统调度,不可控)
- [ ] **P3-1.2** `Info.plist` 加 `UIBackgroundModes = [processing]` + `BGTaskSchedulerPermittedIdentifiers` (沿用 R100 注释"业务真接再加回"原则)
- [ ] **P3-1.3** `AppDelegate.swift` 加 `BGTaskScheduler.register(forTaskWithIdentifier:)` + handler 调 `HealthSyncOrchestrator.sync()`
- [ ] **P3-1.4** Android: WorkManager + `PeriodicWorkRequest` 15min 周期
- [ ] **P3-1.5** 用药 P2 卡点 (见 §5): 自由文本药名映射 + CheckIn 时点化,工作量大,**不建议 P3 一起做**
- [ ] **P3-1.6** CDA/FHIR 临床记录导出 (R104 H4): 仅当需要"导出给医生"场景再做,维持 P3

---

## 四、隐私与合规 (Regulatory)

> HealthKit 数据 = 健康数据,受 Apple Developer Program License Agreement §3.3.15 + App Store Review Guideline 5.1.1/1.4.1 约束。本项目零广告 SDK / 零第三方统计,天然合规,但文案要改。

### 4.1 强制约束

| 规则 | 要求 | 本项目当前 |
|------|------|-----------|
| HealthKit 数据不得用于广告/再营销 | 不能给广告 SDK 任何字段 | ✅ 0 广告 SDK |
| HealthKit 数据不得出售 | 不能转给第三方 | ✅ 0 第三方分析 |
| 仅用于 App 功能 + 用户明确授权 | 隐私文案披露 | ⚠️ 需补 HealthKit 章节 |
| HealthKit 数据不能用于训练 ML/AI 模型 | Apple 加的 2024 新规 | ✅ 当前未训练模型 |
| 删除 Health 数据 = 同步删除 App 副本 | 用户撤销权限不能保留 | 需实现 |
| iOS Health App 是用户数据真源 | App 是"镜像/备份" | 需设计权限时清楚 |

### 4.2 与 zero-cloud 边界协调

- **本项目"零云端"=无第三方云端服务器 / 无我们自己的后端**,HealthKit **不违反此边界** (Health 数据在本机 Health App,iCloud Health 同步由用户自己的 iCloud 设置控制,用户可随时关闭)。
- **必须在隐私文案中如实披露** "数据会经用户控制的 iCloud Health 备份同步",**不能简单宣称"永不上传任何云端"**。
- `assets/legal/privacy_policy.md` 当前"零云端"表述**需改** (R106-P2-1)。
- `check_legal_consent.py` 守门员需同步加新章节白名单 (R106-P2-2)。

### 4.3 PIPL / GDPR / HIPAA

| 法规 | 适用 | 风险点 | 缓解 |
|------|------|--------|------|
| PIPL §13/§14 (中国) | 中国用户 | 写 Health = 第三方? 答: **否**(用户自主 iCloud 同步,不属于向第三方提供) | 隐私政策新加 HealthKit 章节 |
| PIPL §28 | 中国用户 | 设备 root / backup 偷数据 | 已有 `android:allowBackup="false"` ✅ |
| GDPR Art.9 (EU) | EU 用户 | 健康数据属特殊类别 | 默认零云端,Health 写需 explicit consent,App 内独立开关 |
| HIPAA (US) | US 用户 | 精神心理数据 = PHI,但本 App 不给医疗机构,所以**不构成 covered entity** | 隐私文案注明"非医疗器械,非诊疗工具" |
| Apple Guideline 1.4.1 (Medical) | iOS 上架 | 精神心理 = 医疗器械? 答: **不构成**(纯追踪,无诊断) | 现有医疗免责声明已写 ✅ |

### 4.4 隐私文案 + 同意流程

- [ ] **R106-P2-3** `sensitive_data_consent.md` 加 "Apple Health 同步同意" 独立章节 (沿用 R63 PIPL §13 模式)
- [ ] **R106-P2-4** HealthKit 同步首次进入前,弹 2 次确认: ①系统弹窗(HK 自动) ②App 内"我已了解"卡片 (用 `consent_artifact` 表,audit trail 完整)
- [ ] **R106-P2-5** 撤销入口: 设置页"健康数据同步" → 4 类分开关 + "全部撤销" 按钮
- [ ] **R106-P2-6** 撤销后**不删本地数据** (用户可能还想用 App),但**停止同步**

---

## 五、用药模块 (P2 卡点深度分析)

> R105 已识别两个卡点,本轮 R106 进一步展开 + 给出可执行方案。

### 5.1 卡点 A: 自由文本中文药名无法映射 `HKMedicationIdentifier`

- **HK 限制**: `HKMedicationDose.medicationIdentifier` 必须是 Apple 药物库中存在的 identifier (按英文/多语言通用名)。
- **App 现状**: `medication_entity.dart:21-22` `name` 是用户自由文本 (如"舍曲林"、"百忧解"、"草酸艾司西酞普兰片")。
- **方案对比**:
  - **A. 通用名映射表**: 收集 ~100 种常见精神科药 (舍曲林→sertraline / 氟西汀→fluoxetine / 文拉法辛→venlafaxine / 喹硫平→quetiapine / 阿普唑仑→alprazolam / 劳拉西泮→lorazepam / 奥氮平→olanzapine / 利培酮→risperidone / 阿立哌唑→aripiprazole / 碳酸锂→lithium / 丙戊酸钠→valproate / 拉莫三嗪→lamotrigine / 加巴喷丁→gabapentin / 丁螺环酮→buspirone / 米氮平→mirtazapine / 安非他酮→bupropion / 曲唑酮→trazodone / 黛力新→deanxit / 思瑞康→seroquel / 优必罗→abilify),覆盖 ~80% 精神科常用;小众药跳过,显示"无法同步"。
  - **B. 写通用名 + 用户辅助输入**: 添加药物时多 1 步"选择 Apple Health 药物",弹搜索框让用户从 Apple 库选。**最佳 UX**。
  - **C. 不写 medication 同步**: 跳过整个 P2。**最保守**。
- **推荐**: **A + B 组合** (映射表兜底 + 用户手动选补充),失败静默降级,绝不抛错。

### 5.2 卡点 B: 打卡粒度按天 vs `HKMedicationDose` 按时间点

- **HK 现状**: `HKMedicationDose` 是按**时间点**样本 (iOS 16+ 才有)。
- **App 现状**: `check_ins.dart:14` `type` 字段只存 normal/temp/phq9... 无时间点列;`medications.timesJson` 存**期望时间**(如 08:00/20:00),但打卡只记"今天吃了",不记"哪个时间点吃的"。
- **冲突**:
  - 方案 A: 给 `check_ins` 加 `timeSlotMin` 列,打卡时记录实际时间 (或用期望时间);架构级改动,需 schemaVersion +1。
  - 方案 B: 不改 schema,写 HK 时**为每个期望时间点生成一个 dose 样本**,用 `check_in` 关联的"今天是否打卡"布尔决定 dose 的 logStatus (taken/skipped)。
- **推荐**: **方案 B** (零 schema change,但 dose 数量 = medication count × times.length × days,长期会爆,需加 retention policy 90 天滚存)。

### 5.3 结论

- 用药同步 P2 阶段**最大工作量为映射表** (~100 个精神科常用药的中英文别名整理 + iOS 库 identifier 验证),**R107 启动前**可提前做。
- 不为同步强行升 `check_in` schema,沿用方案 B + retention 90 天。

---

## 六、Mindful Minutes 与 vent audio 关联价值 (R106 新视角)

> R105 未分析此角度。本轮 R106 单独评估 vent audio 是否可关联 `HKCategoryTypeIdentifier.mindfulSession`。

### 6.1 概念对齐

| 维度 | App vent audio | HealthKit Mindful Session |
|------|----------------|--------------------------|
| 本质 | 树洞情绪宣泄 / 私密记录 | 正念冥想 / 呼吸练习 / 自我关怀 |
| 时长 | 自由 (秒到 5 分钟,`audioDurationMs`) | 自由 (iOS 显示 mm:ss) |
| 隐私 | **绝对私密**,PIPL §28,contentTextEnc AES-256 | 用户 Health App,iCloud 同步可关 |
| 频次 | 高频 (情绪波动时) | 主动冥想时 (低频) |

### 6.2 映射价值评估

- **正向上**: vent audio 是**用户主动表达情绪**的瞬间,从精神健康角度属于"自我关怀"行为 (mood/mindfulness/日记分类已就绪于 `influenceFactorsJson`)。写 HK 可以在 Apple Health "Mindful Minutes" 周报里**多计一笔**,客观上鼓励用户继续表达。
- **风险**:
  1. **隐私边界被侵蚀**: vent 内容 (含 audio) **绝对不**进 HK,只能把"录音时长"作为 mindful session 写,**不能写 metadata**。
  2. **用户预期错位**: 写 HK 后,用户在 Apple Health 里看到"Mindful Minutes" 增长,但**实际是 vent 不是冥想**,可能被误读为"在正念"。
  3. **道德风险**: 精神心理患者用 vent 宣泄,被计为"正念" → 医生看到健康数据可能误判。

### 6.3 推荐方案

- **不写 vent audio → HK Mindful Minutes** (P3 阶段维持"严禁映射")。
- **替代方案**: vent audio 的时长**仅在本 App 内**计入"自我关怀"统计 (P1 阶段加),与 HK 无关。
- **HK 写 mindful 的入口** 留给 P1 阶段: 在 vent_compose_page 加 1 个开关 "这次记录算作正念会话",用户显式选择,默认 off,完全自愿。

---

## 七、Streak / Medication Adherence ↔ HealthKit Adherence (R106 新视角)

> R105 未分析。Apple Health 在 iOS 16+ 推出"Medication Adherence"概念,本轮评估 streak 系统的 HealthKit 映射价值。

### 7.1 概念对比

| 维度 | App streak | HK Medication Adherence |
|------|------------|--------------------------|
| 算法 | `streak_calculator.dart`:`连续打卡天数`,gap > 1 断 | HK 不算法,**纯 dose 记录**;前端 Health App 算"7 天内该 dose 的 taken/skipped 比" |
| 粒度 | 1 天 1 药 → bool | 1 dose 1 sample (按时间点) |
| 跨药 | 汇总 (整体 streak) | 单药 (medication 维度) |
| 显示位置 | 主页 hero 卡片 | Apple Health → Browse → Medications → 每个药 7 天柱状图 |

### 7.2 价值评估

- **双向价值 MEDIUM**: App streak 是产品核心卖点 (R95 主页 7 天日历热力图),写到 HK 后用户在 Apple Health 看 adherence,与 App streak 是同一数据的不同视角,**不是双倍价值**,只是**展示多一面**。
- **风险**:
  1. App streak 含"每日打卡" (不区分药) + "临时吃药" (不计入 streak),HK 不区分 → 映射语义不清晰。
  2. App streak 是产品特色 (主页 hero 突出),推到 HK 后被 Apple Health "通用化",反而**稀释产品感**。

### 7.3 推荐方案

- **不写 streak → HK** (P2 阶段跳过)。
- **替代方案**: 直接用 P2 阶段的 `HKMedicationDose` 写入,HK 自己在前端算 adherence,**不上传 App streak**。
- **同步方向**: 单向 (App → HK),HK 不回写 streak。

---

## 八、价值评估

### 8.1 用户价值 (10 分制)

| 维度 | 分 | 说明 |
|------|----|------|
| 数据完整性 | 9/10 | 体重秤/智能手表数据自动入 App,补全"忘记录入" |
| 数据可视化 | 8/10 | Apple Health 趋势图补 App 趋势图 (尤其 mood 影响因子关联) |
| 多 App 协同 | 7/10 | 用 Apple 提醒 / 第三方 Health App 都能看 |
| 用户主动选择 | 10/10 | App 内 4 类分开关,用户完全自主 |
| 隐私保护 | 8/10 | 沿用 zero-cloud 语义,iCloud 同步用户可控 |

### 8.2 上架加分

- **App Store 评分**: +0.1-0.3 (Apple Health 集成是 App Store 搜索的 boost 因子之一,但非必要)
- **类目优先级**: "Health & Fitness" 类别下,接 HealthKit 是**事实标准**,不接会被同品类竞品 (Daylio / Moodflow / Medisafe) 拉开身位
- **Editor Choice**: 健康类 Editor 审时,接 HealthKit 是 checklist 之一

### 8.3 长期意义 (战略级)

- **P1 上线后** = 进入 Apple Health 生态,可与 Apple Watch 第三方表盘、Shortcuts、Focus 模式联动
- **P2 上线后** = 接入 Apple Health 依从性数据,精神心理患者可与精神科医生共享"客观服药数据" (取代主观回忆)
- **P3+ 上线后** = 配合 Apple Health AI 趋势预测 (Apple 2025 在 iOS 19+ 推 Health AI),为"早期抑郁/焦虑预警"留接口

---

## 九、本轮 R106 新发现 (10+ 项,相对 R105 增量)

| # | 问题 | 文件:行 | 难度 | 优先级 | 来源 |
|---|------|---------|------|--------|------|
| AH-13 | 0 平台包 (health / health_connect / health_kit) | `pubspec.yaml:11-97` | 简单 | **P0** | R106 复核 |
| AH-14 | 0 FeatureFlag 门控 (`healthKitEnabled` / `healthConnectEnabled` 缺) | `lib/core/data/feature_flags.dart:44-148` | 简单 | **P0** | R106 复核 |
| AH-15 | schemaVersion 22 → 23 三表加 `healthKitUuid` + `healthKitSource` 列**未做** (R105 已识别,本轮确认仍未做) | `app_database.dart:143` (`schemaVersion = 22`);`sleep_entries.dart` / `weight_entries.dart` / `mood_entries.dart` 缺 2 列 | 中 | **P0** | R105+R106 |
| AH-16 | `core_providers.dart` 0 HealthKitService 注册 (R105 未提) | `lib/presentation/providers/core_providers.dart` | 简单 | **P0** | R106 复核 |
| AH-17 | `data_export_service.dart` 不支持 Health export (R104 H4 维持) | `lib/core/data/services/data_export_service.dart` | 中 | **P3** | R104+R106 |
| AH-18 | Android `data_extraction_rules.xml` 缺 Health Connect 角色声明 | `android/app/src/main/res/xml/data_extraction_rules.xml` | 简单 | **P1** | R106 新发现 |
| AH-19 | `medication-redesign-apple-health.md` spec 已落地 (R101) 但**没真接 HKMedicationDose 写入层** | `lib/presentation/pages/medication/medication_page.dart` + `add_medication_page.dart` (已 spec 化,未做同步层) | 大 | **P2** | R101 落地 + R106 评估 |
| AH-20 | vent audio ↔ `HKCategoryTypeIdentifier.mindfulSession` 映射**道德风险**(R105 未提) | `lib/core/data/services/vent_audio_storage.dart` + `mood/mood_entries.dart:audioPath` | — | **P3 禁止** | R106 新视角 |
| AH-21 | streak ↔ HK Medication Adherence 映射**稀释产品感**(R105 未提) | `lib/domain/logic/streak_calculator.dart` + `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` | — | **P3 禁止** | R106 新视角 |
| AH-22 | web 平台不支持 HealthKit / Health Connect (跨平台) | `flutter` 3.41.9 + health 包 0 web 实现 | — | 已知限制 | R106 评估 |
| AH-23 | `feature_flags.dart:69-70` `_prodVentAudioEnabled = true` 已 R104 启用,但 vent audio 同步 HK 仍禁 (与 AH-20 一致) | `lib/core/data/feature_flags.dart:69-70` | — | 锁定 | R106 复核 |
| AH-24 | `sensitive_data_consent.md` 无 HealthKit 章节 (R105 已识别 AH-4) | `assets/legal/sensitive_data_consent.md` | 中 | **P2** | R105+R106 |
| AH-25 | `privacy_policy.md` "零云端"表述需改 (R105 已识别 AH-4) | `assets/legal/privacy_policy.md` | 简单 | **P2** | R105+R106 |
| AH-26 | `medication_draft.dart` 无 `appleHealthIdentifier` 字段,真接 HKMedicationDose 时需加 (R105 未提) | `lib/domain/entities/medication_draft.dart` | 中 | **P2** | R106 新发现 |
| AH-27 | `influence_category.dart` 6 大类 30+ 标签**未映射** Apple `HKStateOfMindLabels` (R105 未提) | `lib/domain/entities/influence_category.dart` | 中 | **P1** | R106 新发现 |
| AH-28 | `daily_tracking_page.dart` + `tracking_item_config.dart` 不接 HK 类型 (架构无扩展点) | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` + `lib/domain/entities/tracking_item_config.dart` | 中 | **P2** | R106 新发现 |
| AH-29 | `assessment_reminder_service.dart` 不区分用户用不用 Health (双源时间冲突风险) | `lib/core/data/services/assessment_reminder_service.dart` | — | 已知 | R106 评估 |

---

## 十、推荐路径

### 短期 (P3, 1-2 周,不阻塞上架)

- **不接 HealthKit**。当前 R105/R106 一致认定:不阻塞 v1.0 上架。
- 任务: **锁定现状** + 把 R105 的 12 项 + R106 的 16 项 (累计 28 项 findings) 整理成 v1.1 backlog。

### 中期 (P2, v1.1, 4-6 周后)

1. **先做平台准备** (阶段 0,1 周): 加 `health` 包 + FeatureFlag + schemaVersion 23 + abstract service + 单元测试。**可在 Windows 环境下完成** (用 mock + ProviderScope override 测)。
2. **iOS 真接** (阶段 1, 1-2 周): 需要 Mac,**R107 切换到 Mac dev 链路后**才推进。
3. **隐私文案** (阶段 1.11-1.12, 与 iOS 并行): 加 HealthKit 章节 + 改"零云端"表述,过 `check_legal_consent.py`。

### 长期 (P1, v1.2+)

1. **双向 + Android Health Connect** (阶段 2, 1-2 周): P0 完成后。
2. **后台同步** (阶段 3, 1-2 周): UIBackgroundModes + BGAppRefreshTask,需谨慎测试系统预算。
3. **用药 P2** (阶段 3.5, 2-3 周): 通用名映射表 (R107+ 启动前可准备)。

### 战略决策点 (PM 待决定)

- **决策 D1**: HealthKit 集成排在 v1.1 还是 v1.2?
  - v1.1: 上架后立即做,赶 Apple Health 用户基础
  - v1.2: 先做 IAP 真接 + 失联通知等"未完成业务",HealthKit 排后
- **决策 D2**: 用药 P2 是否做?
  - 做: 收集通用名映射表工作量大,但**精神心理 App 用药依从性是 Apple Health 重点场景**
  - 不做: 简化 P2 范围,只做 sleep/weight/mood
- **决策 D3**: HealthKit 是否需国内安卓版替代方案?
  - 国内安卓: 微信运动 / 华为运动健康 / 小米健康 / OPPO 健康 各家独立,无统一标准
  - 建议: 国内安卓**不接**,等华为/小米接入 Health Connect 后再说

---

## 十一、与 R105 一致性 + R106 增量

| 维度 | R105 | R106 | 变化 |
|------|------|------|------|
| 评分 | N/A (新视角) | 2/10 | 量化 |
| 架构就绪度评估 | 8/10 | 8/10 | 持平 |
| 事实清单 | 7 项硬性零集成 | 7 项硬性零集成 + 2 项 R106 新发现 (AH-13/14/16/18) | +4 |
| Findings 数 | 12 项 (AH-1~AH-12) | 12 + 16 = 28 项 (AH-1~AH-29 编号连续) | +16 |
| 阶段数 | 4 阶段 (P0-P3) | 4 阶段 (P0-P3) + 阶段 0 准备 | +1 |
| schemaVersion 建议 | 22 | 23 (R105 当时 21,R106 修正为 23) | 同步 |
| 价值评估 | 战略级 3 段 | 5 段 (含上架加分) | +2 |
| 新视角 | — | vent audio 道德 + streak 稀释 + web 平台限制 | +3 |

---

## 十二、参考

- [Apple HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [Apple HealthKit API Reference](https://developer.apple.com/documentation/healthkit/hkhealthstore)
- [Apple HKObserverQuery](https://developer.apple.com/documentation/healthkit/hkobserverquery)
- [Apple HKAnchoredObjectQuery](https://developer.apple.com/documentation/healthkit/hkanchoredobjectquery)
- [Apple State of Mind (iOS 17+)](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/statistic)
- [Apple Mindful Session](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/mindfulsession)
- [Apple HealthKit Medication Dose (iOS 16+)](https://developer.apple.com/documentation/healthkit/hkmedicationdosetype)
- [Apple HealthKit Adherence](https://developer.apple.com/documentation/healthkit/sources_and_steps)
- [Apple PrivacyInfo.xcprivacy](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Apple App Store Review Guideline §1.4.1 Medical](https://developer.apple.com/app-store/review/guidelines/#physical-harm)
- [Apple App Store Review Guideline §5.1.1 Privacy](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Google Health Connect](https://developers.google.com/health-connect)
- [Google Health Connect Android API](https://developer.android.com/guide/health-connect)
- [Google Sleep Stages (2024)](https://developers.google.com/health-connect/data-types/sleep)
- [PIPL §13 (知情同意) / §14 (单独同意) / §28 (敏感个人信息)](http://www.gov.cn/xinwen/2021-08/20/content_5632326.htm)
- [Health App Package (`health` on pub.dev)](https://pub.dev/packages/health)
- [`health_kit` Package (iOS-only)](https://pub.dev/packages/health_kit)
- 项目内: `docs/audit/2026-08-09/07-apple-health.md` (R104 baseline)
- 项目内: `docs/audit/2026-08-09/review-round-105/07-apple-health.md` (R105 复查)
- 项目内: `docs/specs/mood-module-adjustment-apple-health.md` (R101 已落地)
- 项目内: `docs/specs/medication-redesign-apple-health.md` (R101 已落地)
