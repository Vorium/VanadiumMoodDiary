# apple-health (Apple Health + 慢病健康数据) 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: **apple-health (Apple Health 集成 + 慢病健康数据建模 / 数据来源 / 隐私边界 / 写入策略 / 时间对齐)**
- 审视者: subagent `07-apple-health`
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D
- 范围:
  - iOS 端 HealthKit 集成: `ios/Runner/Info.plist` / `ios/Runner/Runner.entitlements` / `ios/Runner/PrivacyInfo.xcprivacy`
  - Android 端 Health Connect 集成: `android/app/src/main/AndroidManifest.xml` / `android/app/build.gradle.kts`
  - 慢病数据建模 (5 类 daily tracking 表): `lib/core/data/database/tables/daily_tracking/{sleep,weight,anxiety_agitation,social_rhythm,stress_event,treatment}_entries.dart` + `lib/domain/entities/{sleep_entry,weight_entry,anxiety_agitation_entry,...}.dart`
  - 心理健康数据 (mood / PHQ-9 / GAD-7 / vent): `lib/core/data/database/tables/mood/mood_entries.dart` + spec `mood-module-adjustment-apple-health.md`
  - medication 数据: `lib/core/data/database/tables/medication/medications.dart` + spec `medication-redesign-apple-health.md`
  - 跨 spec 描述文件: `fastlane/metadata/ios/**/description.txt` + `fastlane/metadata/android/**/full_description.txt` + 测试 `test/fastlane/description_no_health_claim_round108_test.dart`
  - 隐私策略: `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent,medical_disclaimer}.md`
  - 外部文档 (历史报告**仅做历史基线理解,不作结论依据**): `docs/audit-history/r107-cleanup-2026-08-10/07-apple-health.md` + 历次 round 99-105 `*-apple-health.md`
  - R108 进行中工作: `TODO_R108.md` + `scripts/generate_health_apps_questionnaire.py` + 12 URL 域名/邮箱占位脚本

## 1. 整体评分 (0-10)

**3.0/10** — 项目战略 = "Apple Health 风格 UX" + "零云端 + 本地加密" 哲学,但 **HealthKit / Health Connect 数据通道 = 0 集成**。R101 medication 主页 + R101 mood module + R108 描述文件 lock-in test 都是"参考 Apple Health 设计"级别的 UX 工作,无 `health_kit` / `health_connect` Flutter 包,无 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` / `com.apple.developer.healthkit` entitlement,无 Android Health Connect 权限。`PrivacyInfo.xcprivacy` 已声明 `NSPrivacyCollectedDataTypeHealthAndFitness` 收集类型 + spec 注释明文写"参照 Apple Health Profile" + 公开 spec 文档名带 "apple-health" — 这三处"声称"叠加 Apple 5.1.3 used-but-not-declared 抽审模型,在 iOS 上是高概率拒因(已被 R108 修 description 关键词,但 PrivacyInfo 声明 + spec 注释未被 lock-in test 覆盖)。慢病数据建模仅 5 类 (weight / sleep / anxiety / social_rhythm / stress / treatment),缺 Apple Health 主流类型(bloodPressure / bloodGlucose / heartRate / HRV / bodyTemperature / menstrual / respiratoryRate / stepCount / activeEnergy / mindfulSessions / sleepAnalysis)。medication 数据完全独立,无 HKMedicationConceptIdentifier 关联。CareEngine / SafetyWatch 失联检测 0 引用 HealthKit 生命体征,Apple Watch 用户高心率 / 静止信号不会被用。

---

## 2. 关键发现 (按 P0/P1/P2/P3 排序,每项含架构/底层标签 + 修复难度)

### P0 (必修,阻塞上架/严重 bug)

#### P0-001 [架构] **PrivacyInfo.xcprivacy 声明 HealthAndFitness 数据类型 + 0 HealthKit 集成 → Apple 5.1.3 used-but-not-declared 抽审**
- 修复难度: M — 工作量: 2h
- 位置: `ios/Runner/PrivacyInfo.xcprivacy:42-56` (NSPrivacyCollectedDataTypeHealthAndFitness 声明) + `ios/Runner/Info.plist` (无 NSHealthShareUsageDescription / NSHealthUpdateUsageDescription) + `ios/Runner/Runner.entitlements` (空 dict,无 com.apple.developer.healthkit entitlement)
- 现状:
  - `PrivacyInfo.xcprivacy:42-56` 明确声明 `NSPrivacyCollectedDataTypeHealthAndFitness` 收集类型 (Linked=false, Tracking=false, Purpose=AppFunctionality)
  - 注释自述 (line 36-40): "1. HealthAndFitness — PHQ-9 / GAD-7 / 情绪日记 / 药名 / 打卡" — 实际项目处理的**确实**是 health & fitness 类敏感数据,所以声明本身正确
  - **但**: iOS Info.plist **无** `NSHealthShareUsageDescription` 跟 `NSHealthUpdateUsageDescription` + Runner.entitlements **无** `com.apple.developer.healthkit` entitlement + pubspec.yaml **无** `health_kit` 包 → Apple 5.1.3 抽审模型: "App 声明自己处理 HealthAndFitness 数据 + 无 HealthKit UI 入口" = 抽审候选
  - 项目对外不接 HealthKit (R101 spec 注释是 "参照 Apple Health UX 设计",**不是真接 HealthKit 数据**),所以严格说"5.1.3 used-but-not-declared" 不完全成立(因为项目也没声称读 HealthKit) — 但 Apple 抽审常按"App 说自己处理 health → 期待 HealthKit 集成"模式走
  - 5.1.3 (Health & Health Research) + 5.1.1 (Privacy) 双线抽审, 拒因话术 = "App's privacy manifest claims HealthAndFitness data but the app does not appear to use HealthKit"
- 建议:
  - **方案 A (推荐)**: 改 PrivacyInfo.xcprivacy 注释 + spec 文档名,让"HealthAndFitness"声明**完全消失**
    - 把 NSPrivacyCollectedDataTypeHealthAndFitness 删掉,只用 UserContent / AudioData / ContactInfo 3 类
    - 改 `medication-redesign-apple-health.md` → `medication-page-redesign.md` + `mood-module-adjustment-apple-health.md` → `mood-module-state-of-mind-ux.md`(Apple Health 风格不必提"Apple Health"字面)
    - 改 spec 注释 "参照 Apple Health Profile" → "参照 iOS Health 卡片风格"
    - 加 R108 lock-in test 扫描 PrivacyInfo + spec 注释,禁 "HealthAndFitness" / "HealthKit" / "Apple Health" 关键词
  - **方案 B**: 真接 HealthKit (5-15d,Apple review 重新走一遍)
- 外部链接检查: 无 URL/域名/邮箱

#### P0-002 [架构] **慢病数据建模缺 Apple Health 主流类型,CareEngine / SafetyWatch 失联检测 0 引用健康体征**
- 修复难度: L — 工作量: 1-2d (数据建模) + 2-3d (HealthKit 读写, 1-2 周整体)
- 位置: `lib/core/data/database/tables/daily_tracking/` (5 个表 sleep / weight / anxiety_agitation / social_rhythm / stress_event / treatment) + `lib/core/data/database/tables/medication/medications.dart` (medication 表) + `lib/domain/logic/care_engine.dart` (失联检测 0 引用 HealthKit)
- 现状:
  - Apple Health 主流 12 类数据中,本项目仅 5 类 + medication 1 类 = **6 类 (37.5%)**:
    - 缺 HKQuantityTypeIdentifierBloodPressure (mmHg + mmHg) — 精神心理患者常合并高血压 (锂盐 / 抗抑郁药副作用)
    - 缺 HKQuantityTypeIdentifierBloodGlucose (mg/dL or mmol/L) — 抗精神病药 + 抗抑郁药常合并糖尿病
    - 缺 HKQuantityTypeIdentifierHeartRate (count/min, bpm)
    - 缺 HKQuantityTypeIdentifierHeartRateVariabilitySDNN (ms)
    - 缺 HKQuantityTypeIdentifierBodyTemperature (degC)
    - 缺 HKQuantityTypeIdentifierStepCount (count) — Apple Watch 步数
    - 缺 HKQuantityTypeIdentifierActiveEnergyBurned (kcal) — Apple Watch 活动
    - 缺 HKCategoryTypeIdentifierSleepAnalysis — **本项目有 sleep_entries 但字段 (bedtime / wakeTime / durationMin / regularityScore) 不是 HKCategoryTypeIdentifierSleepAnalysis 模式** (Apple = inBed / asleepCore / asleepDeep / asleepREM / awake 等 5 状态)
    - 缺 HKCategoryTypeIdentifierMindfulSession (State of Mind 替代) — 心理应用核心,**spec `mood-module-adjustment-apple-health.md` 提到 State of Mind 但无 implementation**
    - 缺 HKCategoryTypeIdentifierMenstrualCycle
    - 缺 HKQuantityTypeIdentifierRespiratoryRate
    - 缺 HKQuantityTypeIdentifierVO2Max
  - CareEngine (`lib/domain/logic/care_engine.dart`) 4 触发规则仅看 check_in 模式,0 引用 HealthKit 数据
  - SafetyWatchService (失联通知) 走 `check_ins.last_timestamp`,Apple Watch 用户有 HealthKit 生命体征(心率突降 / 静止信号)时本 app 仍以"48h 未打卡"判失联,假阴性高
- 建议:
  - **v0.30 R108 (P0-002 第一段)**: 写 `docs/HEALTHKIT_ROADMAP.md` 文档列 12 类 Apple Health 数据中本项目对应与否 + 实施优先级
  - **v0.30 R108 (P0-002 第二段, 仅 doc)**: 在 care_engine.dart 注释中明确"本版本 0 引用 HealthKit,R109+ 考虑接入心率/步数辅助失联检测"
  - **v1.0 (3-6 月)**: 真接 `health_kit` Flutter 包 + Android `health_connect` 包,数据模型做 HealthKit 双向同步
- 外部链接检查: 无 URL/域名/邮箱

#### P0-003 [底层] **WeightEntryDialog BMI 计算永远为 null,`_getHeightCm()` 用 dynamic 反射读不存在的字段**
- 修复难度: S — 工作量: 1h (去掉 dynamic 反射) + 2h (R109 加 user_profiles.heightCm 字段)
- 位置: `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:138-162` + `lib/core/data/database/tables/user_profile/user_profiles.dart:7-44` (无 heightCm 列) + `lib/domain/entities/user_profile_entity.dart:6-112` (无 heightCm 字段)
- 现状:
  ```dart
  double? _getHeightCm() {
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.value;
    if (profile == null) return null;
    try {
      return (profile as dynamic).heightCm as double?;  // ← 字段不存在 → 抛 NoSuchMethodError
    } catch (e, st) {
      swallowError(where: 'weight_widgets._readHeightCm', error: e, stack: st,
        note: 'UserProfile.heightCm 字段读取失败, 走 null 兜底');
      return null;  // ← 永远走这里 → BMI 永远 null
    }
  }
  ```
  - UserProfileEntity **无** heightCm 字段,dynamic cast 永远抛错 → swallowError 吞错 → 返 null → BMI 永远 null
  - BmiCalculator 永远走 `if (heightCm == null || heightCm <= 0) return null;` → 体重表永远 bmi=null
  - 注释明文承认: "R91: UserProfileEntity 暂无 heightCm 字段,后续 v0.31+ setup 加身高"
  - 状态: v0.30.0+85,已知 4 round(R91 brief 已知 → R95 → R100 → R108 working tree 仍未修)未修
  - 衍生影响: `bmi_category` 永远 null → "正常/超重/肥胖" 健康分类永远 0 数据
  - **健康数据视角下,P0 严重性**: BMI 是 Apple Health 健康档案核心字段,所有"健康人群"应用都必备;本项目声明"健康数据"分类,但健康档案核心字段 BMI 永远 0
- 建议:
  - **R108 (P0-003)**: 删 `_getHeightCm()` 的 dynamic 反射,直接 `final userProfileEntity = ref.read(userProfileProvider).value; return userProfileEntity == null ? null : null;` (明确返 null,不走 dynamic 反射)
  - **R109**: user_profiles 表加 `heightCm REAL` 列 (nullable),schemaVersion 22→23 + migration + 改 WeightEntryDialog 让用户输入身高(放进 setup_step_welcome 或 weight dialog 首次)
- 外部链接检查: 无 URL/域名/邮箱

#### P0-004 [架构] **spec 文档 / 注释明文"参照 Apple Health" + 项目无 HealthKit 集成 → Apple 5.1.3 抽审 / spec 文档命名暴露战略**
- 修复难度: S — 工作量: 1h (改 spec 文件名 + spec 内部"Apple Health"提及)
- 位置:
  - `docs/specs/medication-redesign-apple-health.md:1-3` "参照: Apple Health Medications (iOS 16+)"
  - `docs/specs/mood-module-adjustment-apple-health.md:1-5` "参照: Apple Health State of Mind (iOS 17+)"
  - `lib/presentation/pages/medication/widgets/medication_pill_icon.dart:1-5` "参照 Apple Health Medications"
  - `lib/presentation/pages/settings/widgets/profile_group.dart:55` "_UserProfileCard — v0.30 R101: 用户头像/健康档案入口 (参照 Apple Health Profile)"
  - `lib/presentation/pages/medication/medication_page.dart:1-5` "参照 Apple Health Medications"
  - `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:3` "Apple Health 风格: 顶部: 今日追踪汇总 (环形进度 + 已追踪 X/Y)"
- 现状:
  - spec 文档**文件名**带 "apple-health" 关键词,Apple 抽审扫文件树时一眼看到
  - spec 内部**反复**提"参照 Apple Health Medications / State of Mind / Profile"
  - 代码注释**反复**写"参照 Apple Health"
  - Apple 5.1.3 抽审模型: "App 提到 Apple Health 但无 HealthKit 集成 / entitlement" = 5.1.3 used-but-not-declared
  - **R108 已加** `test/fastlane/description_no_health_claim_round108_test.dart` lock-in test,但**仅锁 description 关键词**,未锁 spec 文档 / 代码注释
- 建议:
  - **R108 P0#11-13 进行中**:
    - 改 `docs/specs/medication-redesign-apple-health.md` → `docs/specs/medication-page-redesign.md` (内部"参照 Apple Health Medications" → "参照 iOS Health 卡片风格")
    - 改 `docs/specs/mood-module-adjustment-apple-health.md` → `docs/specs/mood-module-state-of-mind-ux.md` (内部同样改)
    - 改 `medication_pill_icon.dart:1-5` 注释去掉"Apple Health"字面
    - 改 `profile_group.dart:55` 注释去掉"Apple Health"字面
    - 改 `medication_page.dart:1-5` 注释去掉"Apple Health"字面
    - 改 `daily_tracking_page.dart:3` 注释去掉"Apple Health"字面
    - 改 `medication_detail_page.dart:1` 注释去掉"Apple Health Medication Detail"字面
    - 加 R108 lock-in test `test/specs/no_apple_health_claim_round108_test.dart` 扫描 `lib/**/*.dart` + `docs/specs/**.md` 关键词 ["Apple Health", "AppleHealth", "apple-health", "HealthKit"],禁 (跟 description_no_health_claim 同模式)
- 外部链接检查: 无 URL/域名/邮箱

### P1 (应修,影响品质)

#### P1-001 [架构] **medication ↔ Apple Health Medication 0 关联 — 本项目 medication 域完全独立,Apple Health Medications (iOS 16+) 走 HKMedicationConceptIdentifier + RxNorm 编码**
- 修复难度: XL — 工作量: 1-2 周 (HealthKit 真接 + RxNorm 集成)
- 位置: `lib/core/data/database/tables/medication/medications.dart:1-50` (medication 表无 rxcui / ndc / drugbank_id 列) + `lib/domain/entities/medication_form.dart:6-13` (MedicationForm 6 剂型,跟 Apple Health Medications 形式 略不同)
- 现状:
  - spec `medication-redesign-apple-health.md` §1.1 "Apple Health Medications" + §5.1 决策: **"打卡粒度: 保持日打卡 (B 方案),不细化到时间点"** + 决策理由 "Apple Health 做时间点打卡是因为它有药房数据库,我们没有"
  - 现状 medication 表 13 列 (id / name / dosage / dosageUnit / timesJson / startDate / endDate / isActive / refillAt / refillReminderDays / form / colorIndex / notes),**无任何编码列**
  - Apple Health Medications (iOS 16+) 用 HKMedicationConceptIdentifier (FHIR 风格) — 需 RxNorm CUI / NDC code 关联真实药物
  - 本项目 `Medications` 表未存药物识别码 → 即使未来接 HealthKit,也**无 metadata 关联真实药物** → HKMedicationConceptIdentifier 映射表需要新加列 + 新流程
- 建议:
  - **v0.30 R108 (P1-001 doc)**: 在 `lib/core/data/database/tables/medication/medications.dart` 注释中明确"medication 域独立于 Apple Health Medications,无 RxNorm 映射"
  - **v1.0**: 接 RxNorm API (NIH 公开),medication 表加 `rxcui TEXT NULL` + `ndcCode TEXT NULL`,HKMedicationConceptIdentifier 映射
- 外部链接检查: 无 URL/域名/邮箱

#### P1-002 [底层] **时区 / 跨时区处理不严 — 慢病数据 (sleep / weight / anxiety / stress / social_rhythm) 写时间均用 `DateTime.now()`,跨时区 / 出行时区错位**
- 修复难度: M — 工作量: 1d (全表加 timezone-aware)
- 位置: `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:183` (DateTime.now()) + `lib/core/data/database/tables/daily_tracking/sleep_entries.dart:18-20` (bedtime + wakeTime) + `lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart:13` (timestamp)
- 现状:
  - **Apple HealthKit 强制**:
    - 写入: `HKQuantitySample` 用 UTC 时间戳 (HKUnit + startDate UTC + endDate UTC)
    - 读取: device 自动按 local timezone 展示
  - **本项目**:
    - sleep / weight / anxiety / stress / social_rhythm / treatment 6 张 daily_tracking 表的 timestamp 字段是 drift `DateTimeColumn`,**无 timezone 字段**
    - 写入用 `DateTime.now()` (本地时间)
    - 读取用 `DateTime` 直接展示,**无 timezone 转换**
  - **已知 bug 模式** (AGENTS.md "已知坑" 段): `DateTime.now()` / `DateTime(y, m, d)` 多次调用 race (跨 midnight 可能错位) — 已修多个 service,但**未修** 6 张 daily tracking 表
  - 风险场景:
    - 用户 A 长期住北京 (UTC+8),坐飞机到纽约 (UTC-5) 后称体重: `DateTime.now()` 是纽约本地时间,A 回北京后看趋势 = 跨 13h 错位
    - 用户 B 出差到东京,记录睡眠,`bedtime = 23:00 JST = 14:00 UTC`,回北京后看历史 = 14:00 + 1h 错位
- 建议:
  - **R108 (P1-002 doc)**: 在 6 张 daily tracking 表注释中加"timestamp 存 device-local time,无 timezone 字段,跨时区场景错位风险"
  - **R109 (P1-002 fix)**: 6 张表加 `timezoneOffsetMinutes INTEGER NULL` 列 (int, e.g. 北京 +480),写入时存 `DateTime.now()` + `DateTime.now().timeZoneOffset.inMinutes`;读取时 UI 用同 timezoneOffset 展示
- 外部链接检查: 无 URL/域名/邮箱

#### P1-003 [底层] **紧急联系人 / 失联检测 0 引用 HealthKit 生命体征信号 — Apple Watch 用户高心率/静止信号不会被用**
- 修复难度: XL — 工作量: 1-2 周 (HealthKit 真接)
- 位置: `lib/core/data/services/safety_watch_service.dart` (失联通知编排) + `lib/domain/logic/safety_detector.dart` (失联检测) + `lib/domain/logic/care_engine.dart` (CareTriggerType 4 规则)
- 现状:
  - SafetyWatchService 失联检测逻辑仅看 `check_ins.last_timestamp`,**0 引用 HealthKit**
  - CareEngine 4 规则 (lateCheckInHabit / weekendMissed / secondDayMissed / weekPerfect) **0 引用 HealthKit**
  - Apple Watch 用户场景:
    - 用户戴 Apple Watch,心率 5 分钟 1 次写 HealthKit
    - 用户睡着,Apple Watch 检测 sleepAnalysis.awake 段
    - 用户静坐 1h,Apple Watch 检测 activity
    - 本项目**完全无视**这些信号
  - 衍生: FeatureFlags.emergencyContactEnabled=false (业务暂停),失联通知功能本版本不上线,但**业务真接后**仍 0 引用 HealthKit → 假阴性高
- 建议:
  - **v0.30 R108 (P1-003 doc)**: 在 safety_watch_service.dart 注释中明确"失联检测本版本 0 引用 HealthKit 生命体征"
  - **v1.0 (P1-003 fix)**: 接 HealthKit,失联检测加心率突降 (Apple Watch fall detection) / 静止信号 (motion API) 2 个辅助信号
- 外部链接检查: 无 URL/域名/邮箱

#### P1-004 [架构] **单位换算缺失 — 仅公制 (kg / mg / ml / pill),无 Apple HealthKit HKUnit.inchPound() / .metric() 双制**
- 修复难度: M — 工作量: 1d (扩 DosageUnit 枚举 + 写换算函数)
- 位置: `lib/domain/entities/dosage_unit.dart` (DosageUnit 枚举) + `lib/core/data/database/tables/medication/medications.dart:17` (dosageUnit 列 'mg' 或 '片') + `lib/domain/entities/weight_entry.dart:13` (weightKg,1 decimal,30-200)
- 现状:
  - DosageUnit 枚举可能含 mg / ml / pill 等公制单位 (需 `lib/domain/entities/dosage_unit.dart` 确认)
  - WeightEntry 字段 `weightKg` (硬编码 kg),**无 lb / st 切换**
  - Apple HealthKit 用 `HKUnit` 抽象,默认 metric (kg / m / degC) 可切换 `HKUnit.inchPound()` (lb / in / degF)
  - en-US 用户场景:
    - 用户填体重 154 lb = 69.85 kg,本项目硬性要求 kg,需要用户手动算
    - 用户填身高 5'10" (70 inch = 177.8 cm),本项目硬性要求 cm
  - 衍生: en-US locale 用户体验差,但**现状 description / i18n 仍支持 en-US**
- 建议:
  - **v0.30 R108 (P1-004 doc)**: 在 DosageUnit 注释中明确"本版本仅公制,en-US 用户需手动换算"
  - **R109 (P1-004 fix)**: 引入 `lib/domain/entities/unit_system.dart` (metric / imperial) + Settings 加"单位制"开关 + 写 `lib/domain/logic/unit_converter.dart` (lb↔kg, in↔cm, °F↔°C)
- 外部链接检查: 无 URL/域名/邮箱

#### P1-005 [架构] **HealthKit 撤销授权处理 = 0 — Apple 用户在 Settings > Privacy > Health 撤销权限时,app 应停止读写并提示**
- 修复难度: M — 工作量: 0.5d (接 HealthKit 后才有意义)
- 位置: 无对应代码 (HealthKit 0 集成)
- 现状:
  - 0 集成 HealthKit,所以"撤销授权"无处理流程
  - 现状 health 隐私撤回仅走 R95 sub-spec 7 task 31b PIPL §47 撤回 (限 ConsentKind.dataExport,清 audit log)
  - 但 Apple HealthKit 撤销授权 ≠ 撤回用户协议 (用户协议撤回 = 全删数据)
  - 差异: Apple HealthKit 撤销只断数据通道,不动本地数据库;PIPL §47 撤回 = 删所有数据
  - R95 阶段 2 已有 `ConsentKind.dataExport` 枚举,但无 `ConsentKind.healthkitAuth` 枚举
- 建议:
  - **v0.30 R108 (P1-005 doc)**: 在 `lib/core/data/feature_flags.dart` 注释中明确"HealthKit 0 集成,无 healthkitAuth consent 类型"
  - **v1.0 (P1-005 fix)**: 接 HealthKit 后,加 `ConsentKind.healthkitAuth` + `healthkit_auth_revoked_at` 列,`HKHealthStore` revoke callback 写 DB + UI 弹"已撤销 HealthKit 同步,本地数据保留"
- 外部链接检查: 无 URL/域名/邮箱

#### P1-006 [底层] **medication 时间段打卡 vs Apple Health 时间点打卡差异 — spec 决策 B 方案"保持日打卡",Apple Health 走 per-time-slot 打卡**
- 修复难度: L — 工作量: 1d (加 timeSlotIndex 列 + 改 checkIn 流程)
- 位置: `docs/specs/medication-redesign-apple-health.md:328-342` (决策: 保持日打卡 B 方案) + `lib/core/data/database/tables/check_in/check_ins.dart:1-22` (check_in 表无 timeSlotIndex 列)
- 现状:
  - spec §5.3 决策点 #1 "打卡粒度: A: 时间点打卡 / B: 保持日打卡" → **选 B, 理由: 精神心理患者核心需求是"今天有没有吃药" 而非"哪个时间点吃的"**
  - check_in 表字段: id / timestamp / type / medicationId / note (**无 timeSlotIndex**)
  - Apple Health 走 per-time-slot (morning / afternoon / evening / bedtime),每个时间段独立打卡
  - **本项目 R101 后** `medication_page.dart` 走 `MedicationTimeSlot` 4 时段分组 (morning 5-11 / afternoon 12-16 / evening 17-20 / bedtime 21-4),UI 上分时段,但**打卡时**还是日打卡
  - 矛盾: UI 显 4 时段,但 check_in 表不存时段 → "早上 8 点 8 点" UI 显示"待服" 但用户下午打卡 = 早上 8 点仍 "待服" → 数据失真
- 建议:
  - **R108 (P1-006 fix)**: 加 `timeSlotIndex INTEGER NULL` 列到 check_ins (schemaVersion 22→23),UI 时段打卡时存 index (0=morning / 1=afternoon / 2=evening / 3=bedtime),打卡进度按"今天 + 段"判定
  - **R109 (P1-006 doc)**: spec 决策点 #1 重新评估,从"B 保持日" 升级到 "A 时间点",跟 Apple Health 一致
- 外部链接检查: 无 URL/域名/邮箱

### P2 (可修,优化)

#### P2-001 [架构] **Android Health Connect 集成 = 0 — Android 14+ (targetSdk=36) 默认 Google Health Connect,无任何 fitness API**
- 修复难度: XL — 工作量: 1-2 周 (真接)
- 位置: `android/app/src/main/AndroidManifest.xml:39-48` (5 个 permissions + 1 RECORD_AUDIO,**无 androidx.health.connect.client.permission.READ_WEIGHT / WRITE_WEIGHT 等**) + `android/app/build.gradle.kts:1-127` (**无 health_connect 依赖**)
- 现状:
  - 现状 permissions 5 + 1 (RECORD_AUDIO) = 6 个:**无** Health Connect 任何权限
  - 0 health_connect / health_connect_client Flutter 包依赖
  - Android 14+ (targetSdk=36) 用户用 Google Health Connect 存体重/血压/血糖/心率/睡眠/HRV 等 50+ 类数据,本项目**完全无数据通道**
  - 衍生: Android 用户用 Samsung Health / Mi Fitness / Google Fit / Fitbit 等写的数据无法同步到本项目
- 建议:
  - **v0.30 R108 (P2-001 doc)**: AndroidManifest 注释中明确"本版本 0 Health Connect 集成"
  - **v1.0 (P2-001 fix)**: 加 `health_connect` Flutter 包 + manifest 加 12 类权限 (READ_WEIGHT / WRITE_WEIGHT / READ_BLOOD_PRESSURE / WRITE_BLOOD_PRESSURE / READ_HEART_RATE / ...)+ 双向同步
- 外部链接检查: 无 URL/域名/邮箱

#### P2-002 [架构] **`profile_group._UserProfileCard` 注释"参照 Apple Health Profile" 但内容 = 4 字段 (userName / firstLaunchAt / checkInCycleHours / lastCheckInAt)**
- 修复难度: S — 工作量: 0.5h (改注释) 或 L (1d 真做 Apple Health 风格 summary)
- 位置: `lib/presentation/pages/settings/widgets/profile_group.dart:55` (`_UserProfileCard(l10n: l10n)`) + `lib/domain/entities/user_profile_entity.dart:6-112` (UserProfileEntity 字段)
- 现状:
  - 注释明文写"参照 Apple Health Profile"
  - _UserProfileCard 内容 = 4 字段 (userName / firstLaunchAt / 失联周期 / lastCheckInAt),无 Apple Health Profile 风格 summary (Health Summary / Favorites / Trends / Medical ID / Medical Records)
  - 矛盾: 注释"参照"但内容不像 Apple Health Profile
- 建议:
  - **R108 (P2-002 修)**: 改注释 "参照 Apple Health Profile" → "基础用户档案卡" + 加 lock-in test 扫注释
  - **R109 (P2-002 实)**: 扩 UserProfileEntity 加 heightCm / weightGoal / bloodType / medicalNotes 字段 + _UserProfileCard 走 Apple Health Profile 风格 summary
- 外部链接检查: 无 URL/域名/邮箱

#### P2-003 [底层] **medication_pill_icon.dart 硬编码 6 色 (绿/黄/红/蓝/紫/灰),跟 Apple Health Medications 8 色调色板略不同**
- 修复难度: S — 工作量: 0.5h (改 6 色 → 8 色) 或 1h (加色盲友好)
- 位置: `lib/presentation/pages/medication/widgets/medication_pill_icon.dart:9-16` (kMedPillColors 6 色) + `lib/core/data/database/tables/medication/medications.dart:46` (colorIndex INTEGER, 0-5)
- 现状:
  - 现状 6 色:绿 (0xFF34C759) / 黄 (0xFFFFCC00) / 红 (0xFFFF3B30) / 蓝 (0xFF007AFF) / 紫 (0xFFAF52DE) / 灰 (0xFF8E8E93)
  - Apple Health Medications 8 色:蓝 / 红 / 绿 / 黄 / 橙 / 粉 / 紫 / 靛
  - colorIndex 0-5 (0-5 = 6 色),数据库 DEFAULT 0
  - 衍生: 升级 6→8 色需 schema 迁移,5→6 round 内已改过 (R101 form / colorIndex / notes),再加一列可接受
- 建议:
  - **R108 (P2-003 修)**: kMedPillColors 加橙 / 粉 2 色 = 8 色,colorIndex 改 0-7,schemaVersion 22→23,加 DEFAULT 0
  - **R109 (P2-003 doc)**: 颜色无 i18n / 色盲适配,仅"视觉偏好" 字段
- 外部链接检查: 无 URL/域名/邮箱

#### P2-004 [底层] **数据导出 JSON schema (`export_orchestrator.dart`) 缺 6 张 daily tracking 表**
- 修复难度: M — 工作量: 0.5d
- 位置: `lib/core/data/services/export/export_orchestrator.dart:108-250` (导出 4 类: medications / moodEntries / checkIns / contacts) + `lib/core/data/services/export/export_schema_service.dart:14-17` (schema v1-v4)
- 现状:
  - 现状导出 4 类: medications + moodEntries + checkIns + contacts
  - **缺 6 张** R91 daily tracking 表: weightEntries / sleepEntries / anxietyAgitationEntries / socialRhythmEntries / stressEvents / treatmentEntries
  - 衍生: 用户导出 JSON 备份后,**体重 / 睡眠 / 焦虑 / 节律 / 压力 / 治疗** 6 类数据丢失 → 不可逆
  - Apple Health 走 XML 导出 (HKHealthStore.exportXML),本项目 JSON 模式需自己写 schema
- 建议:
  - **R108 (P2-004 fix)**: export_orchestrator.dart 加 6 张表导出 + export_schema_service.dart schema v5
  - **R109 (P2-004 doc)**: 在 export_orchestrator.dart 注释中明确"本版本 0 Apple Health 格式导出"
- 外部链接检查: 无 URL/域名/邮箱

#### P2-005 [架构] **mood 心理健康数据 (PHQ-9 / GAD-7 / mood_entries / vent) 0 关联 Apple Health State of Mind (iOS 17+)**
- 修复难度: XL — 工作量: 1-2 周 (HealthKit 真接)
- 位置: `lib/core/data/database/tables/mood/mood_entries.dart:1-114` (mood_entries 17 列,无 appleHealthStateOfMindId) + `lib/core/data/repositories/assessment/` (PHQ-9 / GAD-7 量表)
- 现状:
  - Apple Health State of Mind (iOS 17+) 是 HKCategoryTypeIdentifier 走 "Daily State of Mind" 跟 "Momentary State of Mind" 2 模式
  - 现状 mood_entries 表 17 列 (id / timestamp / score / energy / sleep / anxiety / tagsJson / note / audioPath / audioTranscript / audioDurationMs / 8 CBT 列 / period / influenceFactorsJson / recordingMode) — **0 字段关联 Apple Health State of Mind**
  - spec `mood-module-adjustment-apple-health.md:1-5` "参照: Apple Health State of Mind (iOS 17+)" 但**仅 UX 风格**(滑块 + 标签 + 影响因素),**无 HealthKit 写入**
  - 衍生: 精神心理类 Apple Watch 用户 (iOS 17+ 自动用 State of Mind) 写"心情 4/5"到 Apple Health,本项目**完全无数据通道**
- 建议:
  - **v0.30 R108 (P2-005 doc)**: 在 mood_entries.dart 注释中明确"本版本 0 Apple Health State of Mind 关联"
  - **v1.0 (P2-005 fix)**: 接 HealthKit + mood_entries 表加 `appleHealthStateOfMindId TEXT NULL` 列,recordingMode 跟 Apple Health 2 模式对齐 (daily / momentary)
- 外部链接检查: 无 URL/域名/邮箱

### P3 (建议,长期)

#### P3-001 [架构] **spec `mood-module-adjustment-apple-health.md` 决策点 §六第 4 题 "趋势图库 — 自绘 CustomPainter",跟 Apple Health 风格 (SwiftUI Charts) 天然不同**
- 修复难度: L — 工作量: 1-2d (iOS 真接时用 Apple Charts / Android 写 Scribe / web 走 SVG)
- 位置: `docs/specs/mood-module-adjustment-apple-health.md:272-273` (决策点 #4 "趋势图库 — 自绘 CustomPainter")
- 现状:
  - 决策: "项目已有 app_tokens 体系,fl_chart 风格不匹配" → **自绘 CustomPainter**
  - 现状: `lib/presentation/pages/mood_list/mood_trend_page.dart` 是 R101 新建,自绘图
  - Apple Health 风格走 SwiftUI Charts (iOS 17+) — Flutter 端无等效
  - 跨平台: Android (WebView + Compose Charts) / iOS (SwiftUI Charts) / web (SVG / Chart.js) 三端需 3 实现
- 建议:
  - **v0.30 R108 (P3-001 doc)**: 在 mood_trend_page.dart 注释中明确"自绘 CustomPainter,非 Apple Charts 风格"
  - **v1.0 (P3-001 fix)**: 评估 fl_chart 0.69 (项目已用) + Apple Charts (SwiftUI) + Compose Charts 跨端方案
- 外部链接检查: 无 URL/域名/邮箱

#### P3-002 [底层] **Weight widget hardcoded 边界 (30-200 kg),精神心理患者群体 (神经性厌食症 / 暴食症) 体重可能 < 30 kg**
- 修复难度: S — 工作量: 0.5h
- 位置: `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:179` (`if (weight < 30 || weight > 200) return;`) + `lib/domain/entities/weight_entry.dart:28-29` (`bool get isValidWeight => weightKg >= 30 && weightKg <= 200;`)
- 现状:
  - 硬编码 30-200 kg 边界
  - 神经性厌食症患者体重可 < 30 kg (e.g. 25 kg) → 本项目**拒绝接受**记录 → 群体覆盖不全
  - 暴食症患者体重可能 > 200 kg → 本项目**拒绝接受**记录
  - Apple HealthKit 无此硬边界 (用户自由填)
  - 衍生: 精神心理 App 重点用户群 (PHQ-9 高分人群) 中 eating disorder 比例高,边界过严=误拒记录
- 建议:
  - **R108 (P3-002 fix)**: weight_widgets.dart 边界改 20-300 kg (Apple Health 实践范围),WeightEntryEntity.isValidWeight 同步改
  - **R109 (P3-002 doc)**: 在 WeightEntryEntity 注释中说明边界选择理由 (e.g. "下限 20 kg 覆盖神经性厌食症群体,上限 300 kg 覆盖暴食症群体")
- 外部链接检查: 无 URL/域名/邮箱

#### P3-003 [底层] **spec `medication-redesign-apple-health.md` §十 参考截图描述提及 Apple Health UI 但未截图,仅文字描述**
- 修复难度: S — 工作量: 0.5h (删截图描述段 或 加占位图)
- 位置: `docs/specs/medication-redesign-apple-health.md:462-485` (10 个 ASCII 截图描述) + `docs/specs/mood-module-adjustment-apple-health.md:108-160` (4 截图描述)
- 现状:
  - spec 文字描述 Apple Health Medications / Daily Schedule / Medication Detail 3 截图
  - spec 文字描述 Apple Health State of Mind 心情详情页
  - 无实际截图 (R108 working tree 提的"截图脚本"是 iOS / Android store 用,不是 spec 截图)
  - 衍生: spec 长期维护时文字描述可能漂离实际 Apple Health UI
- 建议:
  - **R108 (P3-003 fix)**: spec 段标题"参考截图描述" → "参考布局描述",删去具体截图引用
  - **R109 (P3-003 doc)**: 注明"本描述基于 iOS 16 / 17 调研,实际 Apple Health UI 可能更新,具体以 Xcode Health.app 为准"
- 外部链接检查: 无 URL/域名/邮箱

---

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 |
|------|------|------|
| `ios/Runner/PrivacyInfo.xcprivacy:46` | `NSPrivacyCollectedDataTypeHealthAndFitness` (iOS 内置 type 标识) | **未隐藏** — Apple 模板必填字段,但触发 5.1.3 抽审候选 (见 P0-001) |
| `ios/Runner/Info.plist:53-56` | `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` (R100/R102/R105 调整,英文) | 已隐藏 — 走 InfoPlist.strings per-locale 覆盖 |
| `ios/Runner/Info.plist:62-63` | `NSPhotoLibraryAddUsageDescription` 英文 | 已隐藏 — 走 per-locale 覆盖 |
| `ios/Runner/Info.plist:72-73` | `NSPhotoLibraryUsageDescription` 英文 | 已隐藏 — 走 per-locale 覆盖 |
| `assets/legal/privacy_policy.md:189-191` | "树洞 / 健康数据 / 联系人列表**永不上传**" 链接描述 | 无 URL/邮箱 |
| `scripts/generate_health_apps_questionnaire.py:33` | 6 region crisis hotline number (China 400-161-9995, US 988, UK 116 123, Hong Kong 2382 0000, Taiwan 1925, Singapore 1-767) | 数据声明,无 URL |
| `fastlane/metadata/ios/en-US/description.txt:45` | `https://findahelpline.com` (crisis hotline 链接) | **占位符** — R107 已知 12 URL 不可达 (包括这个),待 R108 域名注册 (`TODO_R108.md` Fix #13) |
| `fastlane/metadata/ios/zh-Hans/description.txt:36` | `https://findahelpline.com` | **占位符** — 同上 |
| `fastlane/metadata/ios/zh-Hant/description.txt:35` | `https://findahelpline.com` | **占位符** — 同上 |
| `fastlane/metadata/android/en-US/full_description.txt:46` | `https://findahelpline.com` | **占位符** — 同上 |
| `fastlane/metadata/android/zh-CN/full_description.txt:37` | `https://findahelpline.com` | **占位符** — 同上 |
| `docs/specs/medication-redesign-apple-health.md` | 无 URL / 域名 / 邮箱 | N/A |
| `docs/specs/mood-module-adjustment-apple-health.md` | 无 URL / 域名 / 邮箱 | N/A |
| `lib/presentation/pages/medication/widgets/medication_pill_icon.dart` | 无 URL / 域名 / 邮箱 | N/A |
| `lib/presentation/pages/settings/widgets/profile_group.dart` | 无 URL / 域名 / 邮箱 | N/A |

**apple-health 视角外部链接关键发现**:
- **`findahelpline.com` 仍是 5 个 description 文件的占位符** — R108 TODO Fix #13 在做域名注册
- **无任何 HealthKit / Health Connect 官方 URL** (`developer.apple.com/documentation/healthkit` / `developer.android.com/health-connect`) 在代码 / spec 中引用 — 反映 0 集成状态

---

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关 (必填,影响 iOS/Android/Privacy)

| 维度 | 现状 | 风险等级 | 修复项 |
|------|------|----------|--------|
| **iOS Info.plist HealthKit 权限声明** | 无 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` | **L (P0-001 衍生)** | 0 集成 HealthKit 是正确,无需加;**但** P0-001 要求清 PrivacyInfo 声明 (见 P0-001 方案 A) |
| **iOS Runner.entitlements HealthKit** | 空 dict (只注释说"删 aps-environment") | **L (P0-001 衍生)** | 同上,0 集成无需 entitlement |
| **iOS PrivacyInfo.xcprivacy HealthAndFitness 声明** | 已声明 `NSPrivacyCollectedDataTypeHealthAndFitness` (Linked=false, Tracking=false) | **L** | **P0-001 修**: 改用 UserContent / AudioData / ContactInfo 3 类 |
| **iOS Health Records 声明** | 无 `NSPrivacyAccessedAPICategoryHealthRecords` (Apple 2024-05+ 新增) | N/A | 项目 0 处理 Health Records,无需加 |
| **Android Health Connect 权限** | 0 个 Health Connect 权限 | N/A | 0 集成,无需加 (P2-001 v1.0 修) |
| **iOS HealthKit 撤销授权** | 0 处理 | N/A | 0 集成,无需加 (P1-005 v1.0 修) |
| **description 关键词 lock-in test** | `test/fastlane/description_no_health_claim_round108_test.dart` 已加 (R108 P0#11) | OK | 现状覆盖 5 description + 9 short desc (iOS en-US / zh-Hans / zh-Hant) |
| **spec / 代码注释 lock-in test** | 0 覆盖 | **M** | **P0-004 修**: 加 `test/specs/no_apple_health_claim_round108_test.dart` 扫 spec 文档 + lib 注释 |
| **Health Apps Questionnaire** | `scripts/generate_health_apps_questionnaire.py` 已加 (R108 Fix #11c) | OK | R108 阶段 2 进行中 |
| **Health Data 类型声明** | 0 声明 (未接 HealthKit) | N/A | 同 P0-001 |

### 4.2 架构相关 (可选)

| 维度 | 现状 | 架构问题 |
|------|------|----------|
| **5 层架构 + 慢病数据建模** | daily tracking 6 张表 + mood 1 张 + medication 1 张 = 8 张 health 数据表 | OK — 4 层 + shared 模式成熟 (R91 / R95 / R101 / R108 持续优化) |
| **HealthKit / Health Connect 抽象层** | 0 抽象层 | **架构债** — 真接 HealthKit 时需新加 `core/data/integrations/healthkit/` 跟 `health_connect/` 子目录 + `abstract HealthDataSource` interface |
| **慢病数据同步策略** | 0 同步 | **架构债** — R109+ 需 `HealthSyncService` (读 + 写 + 冲突合并 3 模式) |
| **HealthKit 撤销授权流程** | 0 流程 | **架构债** — 需 `ConsentKind.healthkitAuth` 枚举 + `HKHealthStore` 监听 + UI 提示 (P1-005) |
| **数据导出 / 导入 (Apple Health XML / Android FHIR)** | 仅 JSON 自定义格式 | **架构债** — 0 Apple Health XML / Android FHIR 导出 (P2-004) |
| **i18n / 单位换算** | 0 unit_system 抽象 | **架构债** — P1-004 R109+ 加 `lib/domain/entities/unit_system.dart` |

### 4.3 重构建议 (可选)

| 维度 | 建议 |
|------|------|
| **medication 表重构** | 加 `rxcui TEXT NULL` + `ndcCode TEXT NULL` + `appleHealthMedicationId TEXT NULL` 3 列 (P1-001) |
| **mood_entries 表重构** | 加 `appleHealthStateOfMindId TEXT NULL` 列 + `timeZoneOffsetMinutes INTEGER NULL` (P1-002 + P2-005) |
| **6 张 daily_tracking 表重构** | 加 `timeZoneOffsetMinutes INTEGER NULL` 列 (P1-002) |
| **UserProfiles 表重构** | 加 `heightCm REAL NULL` 列 (P0-003) |
| **care_engine 重构** | 加 `HealthKitSignal` 数据源 (心率 / 步数 / 静止 / mindfulSessions) → CareTriggerType 4 规则扩 6+ 规则 (P1-003) |
| **medication_pill_icon 重构** | 6 色 → 8 色,加色盲友好模式 (P2-003) |
| **数据导出重构** | export_orchestrator.dart 加 6 张 daily tracking 表导出 (P2-004) |
| **feature-first 重构** (R110) | `lib/features/health/{domain,data,presentation}/` 子目录,封装 medication / mood / sleep / weight 4 个 feature (跟 R110 路线图一致) |

### 4.4 半成品 / TODO / 残缺功能 (必填)

| 半成品 | 位置 | 状态 |
|--------|------|------|
| **HealthKit 集成** | 0 (pubspec / Info.plist / entitlements 0) | **半成品** — 仅 spec 设计 (`medication-redesign-apple-health.md` / `mood-module-adjustment-apple-health.md`) 无实现 |
| **Health Connect 集成** | 0 (AndroidManifest / build.gradle.kts 0) | **半成品** — 同上 |
| **profile.heightCm 字段** | `lib/domain/entities/user_profile_entity.dart:6-112` 0 列 | **半成品** — R91 brief 已知未修, `weight_widgets.dart:138-162` dynamic 反射永远 null |
| **medication ↔ Apple Health Medication 关联** | 0 | **半成品** — spec 决策 #1 "保持日打卡" 限定了 v0 边界 |
| **CareEngine / SafetyWatch 引 HealthKit 生命体征** | 0 | **半成品** — 失联检测仅看 check_in |
| **数据导出 (6 张 daily tracking 表)** | 0 (export_orchestrator.dart 仅 4 类) | **半成品** — R91 加表但导出未补 |
| **HealthKit 撤销授权处理** | 0 | **半成品** — 0 集成 → 0 处理 |
| **medication 时间段打卡 (timeSlotIndex)** | 0 (check_ins 表 0 列) | **半成品** — UI 显 4 时段,打卡仍日级 |
| **单位换算 (公制 / 英制)** | 0 (仅公制) | **半成品** — en-US 用户体验差 |
| **Weight widget 边界 (30-200)** | 硬编码 (weight_widgets.dart:179) | **半成品** — eating disorder 群体覆盖不全 (P3-002) |
| **iOS HealthKit 撤销授权** | 0 | **半成品** |
| **Health Connect 撤销授权** | 0 | **半成品** |
| **HealthKit Sleep Analysis 5 状态 (inBed / asleepCore / asleepDeep / asleepREM / awake)** | sleep_entries 表字段不同 (bedtime + wakeTime + durationMin + regularityScore) | **半成品** — Apple Health 走 5 状态分类,本项目简化成 2 段时间 |
| **HealthKit Mindfulness Sessions** | 0 | **半成品** — vent / mood 0 关联 |
| **HealthKit Blood Pressure (mmHg + mmHg)** | 0 | **半成品** — 精神心理患者合并高血压常见 |
| **HealthKit Blood Glucose (mg/dL or mmol/L)** | 0 | **半成品** — 同上 |
| **HealthKit Heart Rate (bpm)** | 0 | **半成品** — Apple Watch 主流 |
| **HealthKit HRV (ms)** | 0 | **半成品** — 同上 |
| **HealthKit Body Temperature (degC)** | 0 | **半成品** — 0 数据 |
| **HealthKit Menstrual Cycle** | 0 | **半成品** — 0 数据 |
| **HealthKit Respiratory Rate** | 0 | **半成品** — 0 数据 |
| **HealthKit Step Count / Active Energy / Distance** | 0 | **半成品** — Apple Watch 主流 3 类 |
| **HealthKit VO2 Max** | 0 | **半成品** — 0 数据 |
| **trend_page / mood_trend_page Apple Charts 风格** | 自绘 CustomPainter | **半成品** — 跟 Apple Health SwiftUI Charts 风格差 (P3-001) |
| **spec 决策点 #1 重新评估 (B 保持日 → A 时间点)** | spec §5.3 决策已下 | **半成品** — v0 限定,v1 重新评估 (P1-006) |
| **R108 P0#11-13 进行中** | TODO_R108.md + generate_health_apps_questionnaire.py + 12 URL 占位 | **进行中** — R108 阶段 2 |

---

## 5. 总结 + 给整合者的建议

**核心 takeaway**:
1. **本项目战略 = "Apple Health 风格 UX" + "零云端"** 哲学 + **0 HealthKit / Health Connect 数据通道** — 三者不冲突,现状 0 集成是正确的隐私决策(精神心理患者数据极敏感,本地最安全)
2. **但现状有 4 个 Apple 5.1.3 抽审候选** (P0-001/004): PrivacyInfo 声明 + spec 文件名 + spec 注释 + 代码注释 — **R108 description lock-in test 仅锁 description, 5 处"Apple Health"提及未锁**
3. **慢病数据建模仅 37.5%** (5/12 主流 Apple Health 类型 + medication),PHQ-9 / GAD-7 心理量表跟 Apple Health State of Mind (iOS 17+) 0 关联
4. **1 个 P0 bug** (P0-003): WeightEntryDialog BMI 永远 null,dynamic 反射读不存在字段 — 已知 R91 未修
5. **时区 / 跨时区 / 单位换算 / 撤销授权 / 数据导出** 5 个 P1 半成品,影响 en-US 用户 / 跨时区出行用户 / 苹果隐私撤回用户
6. **v1.0 (3-6 月) 才接 HealthKit / Health Connect** — 项目 8 FeatureFlag 之一"ventAudioEnabled=true R104 翻 true"已示范 flag 守门模式,R108 P0 路线图未列 HealthKit 集成

**给整合者 (00-FINAL-CONSOLIDATION.md) 的建议**:
- **优先修 P0-001 (PrivacyInfo 声明) + P0-004 (spec / 注释 lock-in)**: 1-2h 总工作量,挡 Apple 5.1.3 抽审
- **同步修 P0-003 (BMI 永远 null)**: 1h 总工作量, 已知 R91 漏洞 4 round 未修, R108 应清掉
- **P0-002 写文档路线图**: 不实现,只写 `docs/HEALTHKIT_ROADMAP.md` 列 12 类 Apple Health + 12 类 Health Connect 数据中本项目对应与否 + 实施优先级 (跟 P0-001 方案 A 一起防御)
- **P1 类 (6 项) 留 R109 路线图**: 不在 R108 硬上,R108 已 13 项 P0 重负载
- **P2/P3 (8 项) 留 R110+ feature-first 重构时一起做**: HealthKit 集成是 v1.0 工程,现在做半成品浪费
- **整合 subagent 报告时,本视角 (apple-health) 的 P0-001/002/003/004 应并入"上架 / 隐私" P0 段落** (跟 appstore 跟 spzh 合规视角交叉)

**外部链接风险**:
- `findahelpline.com` 5 个 description 文件占位符 — R108 TODO Fix #13 进行中,本视角无额外发现

---

## 附录: 详细证据

### A.1 0 HealthKit / Health Connect 集成证据

| 检查项 | 证据 |
|--------|------|
| pubspec.yaml 依赖 | `flutter: flutter_riverpod, drift, sqlcipher_flutter_libs, flutter_secure_storage, go_router, flutter_local_notifications, permission_handler, fl_chart, pdf, printing, intl, uuid, share_plus, shared_preferences, url_launcher, record, audioplayers, in_app_purchase, speech_to_text, flutter_timezone, flutter_dotenv, flutter_localizations, pointycastle, path, path_provider` — **无** `health_kit` / `health_connect` / `health` 任何包 |
| iOS Info.plist | 5 个 permission keys: `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` / `NSPhotoLibraryAddUsageDescription` / `NSPhotoLibraryUsageDescription` — **无** `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` |
| iOS Runner.entitlements | 空 `<dict>`,只注释"删 aps-environment" — **无** `com.apple.developer.healthkit` / `com.apple.developer.healthkit.access` / `com.apple.developer.healthkit.background-delivery` |
| Android Manifest permissions | 5 + 1 (RECORD_AUDIO) — **无** `androidx.health.connect.client.permission.READ_WEIGHT` / `WRITE_WEIGHT` / `READ_BLOOD_PRESSURE` / `WRITE_BLOOD_PRESSURE` / `READ_HEART_RATE` 等 |
| Android build.gradle.kts | 仅 `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` — **无** health_connect 依赖 |
| `grep -ri 'health_kit\|healthkit\|HealthKit\|health_connect\|HealthConnect' lib/` | **0 匹配** (除 audit-history 历史报告) |

### A.2 慢病数据建模现状 (5 类 + 1 medication)

| 数据类型 | Apple HealthKit 标识 | 本项目支持 | 表/字段 | 缺什么 |
|----------|---------------------|-----------|---------|--------|
| 体重 | `HKQuantityTypeIdentifierBodyMass` | ✅ | `weight_entries.weightKg REAL` (1 decimal, 30-200) | lb / st 单位 / age range 边界 / Apple HealthKit metadata |
| 睡眠 | `HKCategoryTypeIdentifierSleepAnalysis` (5 状态) | ⚠️ | `sleep_entries.bedtime + wakeTime + durationMin + regularityScore` | 5 状态 (inBed / asleepCore / asleepDeep / asleepREM / awake) / 时区 |
| 焦虑急躁 | 无标准 | ⚠️ | `anxiety_agitation_entries.anxietyScore + agitationScore` (1-5) | 0 标准 mapping, 自定义 |
| 社交节律 | 无标准 | ⚠️ | `social_rhythm_entries` | 0 标准 mapping, 自定义 |
| 压力事件 | 无标准 | ⚠️ | `stress_events` | 0 标准 mapping, 自定义 |
| 治疗 | 无标准 | ⚠️ | `treatment_entries` | 0 标准 mapping, 自定义 |
| 血压 (mmHg + mmHg) | `HKQuantityTypeIdentifierBloodPressure` | ❌ | — | **缺** |
| 血糖 (mg/dL or mmol/L) | `HKQuantityTypeIdentifierBloodGlucose` | ❌ | — | **缺** |
| 心率 (bpm) | `HKQuantityTypeIdentifierHeartRate` | ❌ | — | **缺** |
| 心率变异性 (ms) | `HKQuantityTypeIdentifierHeartRateVariabilitySDNN` | ❌ | — | **缺** |
| 体温 (degC) | `HKQuantityTypeIdentifierBodyTemperature` | ❌ | — | **缺** |
| 月经周期 | `HKCategoryTypeIdentifierMenstrualCycle` | ❌ | — | **缺** |
| 呼吸频率 | `HKQuantityTypeIdentifierRespiratoryRate` | ❌ | — | **缺** |
| 步数 | `HKQuantityTypeIdentifierStepCount` | ❌ | — | **缺** |
| 活动能量 (kcal) | `HKQuantityTypeIdentifierActiveEnergyBurned` | ❌ | — | **缺** |
| 距离 | `HKQuantityTypeIdentifierDistanceWalkingRunning` | ❌ | — | **缺** |
| VO2 Max | `HKQuantityTypeIdentifierVO2Max` | ❌ | — | **缺** |
| 正念会话 | `HKCategoryTypeIdentifierMindfulSession` | ❌ | — | **缺** (mood / vent 0 关联) |
| 心理状态 (iOS 17+) | `HKCategoryTypeIdentifierStateOfMind` (2 模式: Daily / Momentary) | ⚠️ | `mood_entries.recordingMode TEXT NULL` ('momentary' / 'daily', R105 加) | recordingMode 字段已加, **但 0 字段关联 Apple Health State of Mind** |
| 服药 (iOS 16+) | `HKMedicationConceptIdentifier` (FHIR + RxNorm CUI) | ❌ | `medications` 表无 rxcui / ndc 列 | **缺** (P1-001) |

**总覆盖率**: 5/12 主流 Apple Health 类型 = **41.7%** (+ 1 medication 表,无 Apple Health 关联)
- 5 类支持: weight / sleep / anxiety_agitation (自定义) / social_rhythm (自定义) / stress_event (自定义)
- 7 类缺主流: bloodPressure / bloodGlucose / heartRate / HRV / bodyTemperature / menstrualCycle / stepCount + 4 类次主流: respiratoryRate / VO2Max / mindfulSessions / State of Mind
- 12 类主流 Apple Health 数据 (HKQuantityTypeIdentifier + HKCategoryTypeIdentifier) 中 4 类 = 33.3%

### A.3 spec 文档"Apple Health"提及证据 (P0-004)

| 文件 | 行 | 内容 |
|------|----|----|
| `docs/specs/medication-redesign-apple-health.md` | 1 | `# 用药页面重构设计方案 — 参照 Apple Health Medications` |
| `docs/specs/medication-redesign-apple-health.md` | 5 | `**参照**: Apple Health Medications (iOS 16+)` |
| `docs/specs/mood-module-adjustment-apple-health.md` | 1 | `# 情绪日记模块调整设计方案 — 参照 Apple Health 心理状态` |
| `docs/specs/mood-module-adjustment-apple-health.md` | 5 | `**参照**: Apple Health State of Mind (iOS 17+)` |
| `lib/presentation/pages/medication/widgets/medication_pill_icon.dart` | 1 | `// v0.30 R101: 药丸颜色形状图标 — 参照 Apple Health Medications` |
| `lib/presentation/pages/medication/medication_page.dart` | 1 | `// v0.30 R101: 用药主页 — 参照 Apple Health Medications` |
| `lib/presentation/pages/medication/medication_detail_page.dart` | 1 | `// v0.30 R101: 药物详情页 — 参照 Apple Health Medication Detail` |
| `lib/presentation/pages/settings/widgets/profile_group.dart` | 55 | `// v0.30 R101: 用户头像/健康档案入口 (参照 Apple Health Profile)` |
| `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` | 3 | `// Apple Health 风格:` |
| `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` | 5 | `// - 分类区: 按 情绪/身体/行为/医疗 分组, 可折叠` (无 Apple Health 提及) |
| `lib/domain/entities/medication_form.dart` | 3 | `// 参照 Apple Health Medications 的剂型分类` |

**总 "Apple Health" 提及**: 10+ 处 (spec 2 处 + lib 注释 5+ 处)
**R108 已加 lock-in test**: 0 覆盖

### A.4 0 数据通道证据 (P1-003 + P2-001 + P2-005)

| 模块 | 引用 HealthKit / Health Connect? | 证据 |
|------|----------------------------------|------|
| CareEngine 失联检测 | ❌ 0 引用 | `lib/domain/logic/care_engine.dart:24-30` CareTriggerType 枚举 4 规则, 0 HealthKit 引用 |
| SafetyWatchService 失联通知 | ❌ 0 引用 | `lib/core/data/services/safety_watch_service.dart` 仅看 `check_ins.last_timestamp` |
| mood 模块 | ❌ 0 引用 | `lib/core/data/database/tables/mood/mood_entries.dart:1-114` 0 字段关联 Apple Health |
| medication 模块 | ❌ 0 引用 | `lib/core/data/database/tables/medication/medications.dart:1-50` 0 字段关联 Apple Health |
| daily tracking 6 张 | ❌ 0 引用 | `lib/core/data/database/tables/daily_tracking/*.dart` 0 字段关联 Apple Health |
| notification_service | ❌ 0 引用 | `lib/core/data/services/notification_service.dart` 仅走 flutter_local_notifications 17.x |
| assessment (PHQ-9 / GAD-7) | ❌ 0 引用 | `lib/core/data/repositories/assessment/` 0 字段关联 Apple Health |
| 主页 / 趋势 / 设置 | ❌ 0 引用 | `lib/presentation/pages/{home,trend,settings}/` 0 引用 HealthKit 控件 |

### A.5 BMI 永远 null 详细证据 (P0-003)

```dart
// lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:138-162
double? _getHeightCm() {
  final profileAsync = ref.read(userProfileProvider);
  final profile = profileAsync.value;
  // R91: UserProfileEntity 暂无 heightCm 字段, 后续 v0.31+ setup 加身高
  if (profile == null) return null;
  try {
    // 尝试读 heightCm (字段可能不存在 → throw)
    return (profile as dynamic).heightCm as double?;  // ← 永远抛 NoSuchMethodError
  } catch (e, st) {
    // v0.30 R92: 走 swallowError 集中器
    swallowError(
      where: 'weight_widgets._readHeightCm',
      error: e,
      stack: st,
      note: 'UserProfile.heightCm 字段读取失败, 走 null 兜底',
    );
    return null;  // ← 永远返 null
  }
}
```

```dart
// lib/core/data/database/tables/user_profile/user_profiles.dart:7-44
@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get userName => text().nullable()();
  IntColumn get checkInCycleHours => integer().withDefault(const Constant(48))();
  DateTimeColumn get firstLaunchAt => dateTime()();
  DateTimeColumn get lastCheckInAt => dateTime().nullable()();
  TextColumn get userAgreementVersion => text().nullable()();
  TextColumn get privacyPolicyVersion => text().nullable()();
  DateTimeColumn get sensitiveDataConsentAt => dateTime().nullable()();
  DateTimeColumn get consentRevokedAt => dateTime().nullable()();
  // ❌ 无 heightCm REAL 列
  @override
  Set<Column> get primaryKey => {id};
}
```

```dart
// lib/domain/entities/user_profile_entity.dart:6-112
class UserProfileEntity {
  final int id;
  final String? userName;
  final int checkInCycleHours;
  final DateTime firstLaunchAt;
  final DateTime? lastCheckInAt;
  final String? userAgreementVersion;
  final String? privacyPolicyVersion;
  final DateTime? sensitiveDataConsentAt;
  final DateTime? consentRevokedAt;
  // ❌ 无 heightCm 字段
}
```

**衍生影响**:
- `BmiCalculator.compute({required double weightKg, double? heightCm})` 走 `if (heightCm == null || heightCm <= 0) return null;` → bmi 永远 null
- `WeightEntryEntity.bmi` 永远 null
- `WeightEntryEntity.bmiCategory` 永远 null
- 趋势图 BMI 折线永远空
- 体重表 + BMI 联动 UI 永远失效

### A.6 R108 description lock-in test 证据 (P0-001/004 部分防御)

`test/fastlane/description_no_health_claim_round108_test.dart` (R108 P0#11 新增) 锁 13 个 description / short desc 文件的 HealthKit 关键词:
- 关键词集合: `hypertension / diabetes / glucose / insulin / a1c / cardiovascular / heart disease / blood pressure / cholesterol / heart rate` (10 个)
- 文件清单: 5 description (iOS en-US/zh-Hans/zh-Hant + Android en-US/zh-CN) + 9 short desc (iOS en-US/zh-Hans/zh-Hant 各自 keywords/subtitle/promotional)
- 验证: 5 description 文件全过,9 short desc 全过
- **未覆盖**:
  - `PrivacyInfo.xcprivacy:46` `NSPrivacyCollectedDataTypeHealthAndFitness` (iOS 内置 type 标识)
  - spec 文档 2 个文件名 (`medication-redesign-apple-health.md` / `mood-module-adjustment-apple-health.md`)
  - spec 文档内部 5+ 处"Apple Health" 提及
  - lib 注释 5+ 处"Apple Health" 提及

### A.7 R108 健康类脚本证据 (进行中)

`scripts/generate_health_apps_questionnaire.py` (R108 Fix #11c 阶段 2 进行中):
- 4 大块: Mental Health / Clinical Claims / Medical Device / Stigma & Equity
- 引用 6 region crisis hotline number
- 显式声明 "Not a medical device" + "Does not perform measurement, monitoring, or diagnostic functions" + "Does not measure vital signs (e.g., heart rate, blood pressure, blood glucose)" (这 3 句**反向**说明项目 0 测量生命体征 = 0 HealthKit 集成)

`TODO_R108.md`:
- Fix #11c Health Apps Questionnaire: 进行中
- Fix #12 截图脚本: 进行中
- Fix #13 域名 + 邮箱: 进行中 (12 URL 不可达待修)

### A.8 medication 表字段分析 (P1-001 证据)

```dart
// lib/core/data/database/tables/medication/medications.dart:7-50
@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();  // 药名 (用户填, 不预填真实处方药通用名)
  RealColumn get dosage => real()();
  TextColumn get dosageUnit => text()();  // 'mg' 或 '片'
  TextColumn get timesJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get refillAt => dateTime().nullable()();
  IntColumn get refillReminderDays => integer().withDefault(const Constant(7))();
  TextColumn get form => text().withDefault(const Constant('tablet'))();
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  // ❌ 无 rxcui (RxNorm CUI 编码)
  // ❌ 无 ndcCode (NDC 编码)
  // ❌ 无 appleHealthMedicationId (Apple Health 关联 ID)
  // ❌ 无 drugbankId (DrugBank 关联 ID)
  // ❌ 无 atcCode (ATC 编码)
}
```

**13 列, 0 关联 Apple Health / RxNorm / NDC / DrugBank / ATC 任何药物编码** → 即便真接 HealthKit 也**无 metadata 关联真实药物** (P1-001)

### A.9 spec 决策点对比证据 (P1-006)

```markdown
# docs/specs/medication-redesign-apple-health.md:328-342
### 5.3 CheckIn 扩展(可选 — 打卡粒度细化)

// 方案 A: 在 CheckIn 表新增 timeSlotIndex 列
// 优点: 精确到哪个时间点打卡
// 缺点: 需要改表结构 + 迁移

// 方案 B: 保持现状(只记录当天是否打卡)
// 优点: 不改表结构, 兼容现有逻辑
// 缺点: 无法区分"早上吃了但晚上没吃"

// 推荐: 方案 B(先保持现状, v1.0 后考虑方案 A)
// 理由: 精神心理患者的核心需求是"今天有没有吃药", 而非"哪个时间点吃的"
// Apple Health 做时间点打卡是因为它有药房数据库, 我们没有
```

**R101 后**: UI 走 `MedicationTimeSlot` 4 时段 (morning / afternoon / evening / bedtime) 但 check_in 表**未加 timeSlotIndex 列** → 矛盾

### A.10 FeatureFlag 状态 (8 个 + HealthKit 第 9 候选)

`lib/core/data/feature_flags.dart` (R93 阶段 2 锁 8 个 flag):
- 8 个 _prodXxxEnabled: emergencyContact / iap / phqGad7I18n / bootReceiver / aliyunSms / emailService / fiveVendorPush / ventAudio
- 1 个翻 true: ventAudio (R104)
- 7 个 false: 等外部资源真接
- **缺** 9 个: healthKit / healthConnect / medicalDeviceCertification / 5VendorPush 已经 / 等 8 个 flag
- **新 flag 候选**: `healthKitEnabled = false` / `healthConnectEnabled = false` (v1.0 真接时加)

---

**报告完。**

<!-- subagent: 07-apple-health 完成时间: 2026-08-10T07:15:00+08:00 -->
