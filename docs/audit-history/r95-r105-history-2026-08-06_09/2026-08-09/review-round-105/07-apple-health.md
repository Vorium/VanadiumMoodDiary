# Apple Health / HealthKit 视角复查报告 (R105)

**审查时间**: 2026-08-09
**版本基线**: v0.30.0+85 (schemaVersion 21)
**审查人**: AI Agent (Apple Health / HealthKit 视角)
**上一轮**: R104 `docs/audit/2026-08-09/07-apple-health.md` (评分 N/A, 4 项 H1-H4, 全 P3)

---

## 一、现状 (Current State Verification)

本轮实际逐文件核验，确认 **HealthKit 集成度 = 0**：

| 检查项 | 结论 | 证据 |
|--------|------|------|
| `health` / `health_kit` 等包 | ❌ 无依赖 | `pubspec.yaml` 全量扫描 0 命中；`pubspec.lock` 0 命中 |
| `com.apple.developer.healthkit` entitlement | ❌ 无 | `ios/Runner/Runner.entitlements` 为空 dict（仅剩 R70 删 aps-environment 的注释） |
| `NSHealthShareUsageDescription` | ❌ 无 | `ios/Runner/Info.plist` 0 命中 |
| `NSHealthUpdateUsageDescription` | ❌ 无 | 同上 |
| HKHealthStore / HKObserverQuery 代码 | ❌ 无 | `lib/` + `ios/Runner/*.swift` 全量 grep 0 命中 |
| `UIBackgroundModes` 后台能力 | ❌ 无 | R100 已删 (audio/processing)；注释明确"业务真接时再加回" (`Info.plist:150-156`) |
| 物理设备 / Mac 构建 | ❌ 未具备 | AppStore 视角 A3/A10：iOS 签名未配置、Podfile 未生成（Windows 环境无法产） |
| PrivacyInfo.xcprivacy | ✅ 已就绪 | 已声明 `HealthAndFitness` (Linked=false / Tracking=false / AppFunctionality) |

**与 R104 一致性**: R104 的 H1-H4 (未接入 / 未声明 entitlement / 无 HKObserverQuery / 无 CDA-FHIR) 现状**全部维持**。R104 评分"P3 nice-to-have 不阻塞上架"结论不变。

**本轮新增事实**:
1. 用药模块已按 `docs/specs/medication-redesign-apple-health.md` 落地 (R101，未提交): `medication_page.dart` / `add_medication_page.dart` / `medication_detail_page.dart` + `MedicationForm` 枚举 (`medication_form.dart`) + `form/colorIndex/notes` 三列已进 `medications.dart` (schemaVersion 20) + `influenceFactorsJson` 已进 `mood_entries.dart` (schemaVersion 21)。
2. 情绪模块已落地 `influenceFactorsJson` (`mood_entries.dart:102-108`) + `mood_detail_page.dart` / `mood_trend_page.dart` — 与 Apple Health State of Mind (iOS 17+) 对齐的字段就绪。
3. schemaVersion 已是 **21**，HealthKit 接入如需去重列需升 **22**。

---

## 二、数据映射表 (App → HealthKit)

| App 数据类型 | 存储位置 | HealthKit 类型 | 单位 | 方向 | 优先级 | 备注 |
|---|---|---|---|---|---|---|
| sleep (睡眠) | `sleep_entries.dart` (date/bedtime/wakeTime/durationMin) | `HKCategoryTypeIdentifier.sleepAnalysis` (inBed / asleep 两段) + `HKQuantityTypeIdentifier.awakeDuration` (iOS16+) | min (App) ↔ sec/segments (HK) | read + write | P0(读) / P1(写) | 最优映射；`date` = 入睡当天，跨午夜天然匹配 HK sample start |
| weight (体重) | `weight_entries.dart` (timestamp/weightKg/bmi) | `HKQuantityTypeIdentifier.bodyMass` | kg (App) ↔ HKUnit 自动转换 | read + write | P0 | 最简映射；体重秤数据读入价值最高 |
| mood (情绪) | `mood_entries.dart` (score 1-5 / influenceFactorsJson / period) | `HKCategoryTypeIdentifier.stateOfMind` (iOS17+, pleasantness 1-5) + `mindfulSession` (正念) | 无 | write (主) / read (可选) | P1 | score 1-5 ↔ pleasantness 直接对齐；influenceFactors ↔ HKStateOfMindLabels 需映射 |
| medication (用药) | `check_ins.dart` (type/medicationId/timestamp) + `medications.dart` | `HKMedicationDoseType` (iOS16+) | mg | write (难) | P2 | ⚠️ 卡点见 §5：需合法 HKMedicationIdentifier |
| assessment (PHQ-9/GAD-7) | `assessment_*` 表 | 无标准类型 | — | 不映射 | — | HealthKit 无心理量表类型；CDA/FHIR 临床记录需医疗机构背书，不适用 |
| anxiety / social_rhythm / stress / treatment | daily_tracking/* | 无标准类型 | — | 不映射 | — | 保持本地 |
| heart / HRV | 无（App 未追踪） | bodyMass 已含 / 无 | — | 无 | — | 若 v2 加心率追踪 → `heartRate` + `heartRateVariabilitySDNN` (P3 未来) |

**核心结论**: 10 类数据中 **3 类可映射** (sleep/weight/mood)，1 类条件映射 (medication)，6 类无对应保持本地。评估/压力/节律类不可上 HealthKit。

---

## 三、Entitlement / Info.plist / Package 检查清单 (精确内容)

### 3.1 `ios/Runner/Runner.entitlements` — 加 1 个 key

```xml
<key>com.apple.developer.healthkit</key>
<true/>
```

Xcode 侧: Target → Signing & Capabilities → **+ HealthKit** 能力（自动写入 entitlement + 配置 provisioning profile）。注意：**HealthKit 能力要求 Development Team 且需重新生成 profile**。

### 3.2 `ios/Runner/Info.plist` — 加 2 个 key（两把都要，缺一不可）

```xml
<key>NSHealthShareUsageDescription</key>
<string>Allow ChronicCare to read your sleep, weight, and mood data so your daily tracking stays complete even across devices.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Allow ChronicCare to write your medication, sleep, weight, and mood records to the Health app as a personal backup you control.</string>
```

⚠️ 项目约定 (R70/R100): usage description 用**英文基线**，中文走 `zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` per-locale 覆盖。每个 locale 文件都需同步新增 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` 两个 key。

### 3.3 后台能力（Phase 3 才需要，防 2.5.4 拒）

```xml
<key>UIBackgroundModes</key>
<array>
  <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.chroniccare.healthkit-sync</string>
</array>
```
同步改 `AppDelegate.swift` 加 `BGTaskScheduler.register`。**声明即用，不声明不写**（沿用 R100 已删、业务真接再加回的原则）。

### 3.4 包依赖 (`pubspec.yaml`)

| 包 | 版本 | 理由 | 风险 |
|---|---|---|---|
| `health` (官方社区) | ^10.x / ^12.x | iOS HealthKit (读/写/observe 全支持) + Android Health Connect 可选 | iOS 12+；写需 HKQuantityUnit；后台 observe 需 iOS 平台侧处理 |
| 或 `health_kit` (社区 fork) | 最新 | 更细粒度 iOS-only，HKObserverQuery 更成熟 | 依赖作者维护 |
| 备选: 自写 `method_channel` | — | 零第三方依赖，完全掌控（符合本项目 0 依赖洁癖） | 开发量大 (P3) |

**推荐**: Phase 0 用 `health` 包起步（生态最稳、文档全），若后台 observe 不顺再评估 `health_kit` 或自写 channel。改完必跑 `flutter pub get`。

### 3.5 硬前置（本轮 Windows 环境无法做）

- **Mac 必须**：iOS 构建 + Xcode 加 Capability + 重签 profile，Windows 全部不可执行。
- **Apple Developer Program**（$99/年）：HealthKit entitlement 需真签名。
- **真机必须**：HealthKit **在模拟器不可用**（无 HKStore / Health App），只能 `flutter run -d <真机>`。
- **App Store Connect 后台**：App 描述 + 隐私问题需补"使用 HealthKit"。

---

## 四、隐私架构建议 (维持 zero-cloud + SQLCipher)

### 4.1 定位表述

- HealthKit 数据写的是 **用户本机 Health App**，iCloud Health 同步由用户自己的 iCloud 设置控制（可随时关闭）。
- 本项目"零云端" = **无第三方云端服务器 / 无我们自己的后端**，HealthKit 不违反此边界；但**必须在隐私文案中如实披露**"数据会经用户控制的 iCloud Health 备份同步"，不能简单宣称"永不上传任何云端"。

### 4.2 推荐同步方向 (分阶段)

| 阶段 | 方向 | 机制 | 谁是真源 |
|---|---|---|---|
| 1 (本阶段先做) | **read-into-local 单向镜像** | `HKAnchoredObjectQuery` + anchor 增量拉取 → 写 SQLCipher 本地表 | Health 是"外部源"，App 本地为镜像 |
| 2 (次阶段) | **write-out 备份** | 本地写入 → `HKHealthStore.save` (App 为 HKSource) | App 本地为真源，Health 为备份 |
| 3 (可选) | 双向 | 冲突处理（见下） | 逐类型仲裁 |

### 4.3 冲突解决策略

1. **每条样本一个稳定 UUID**（新列 `healthKitUuid`，schemaVersion 22）。HealthKit sample 的 `HKUUID` 持久不变 → 去重键。
2. **write-out 幂等**：save 前查本表 uuid 是否已写；已写则 skip。HK 无 update，改值 = `delete + re-save`（同 uuid）或直接重新 save（HK 按 uuid 覆盖行为需实测）。
3. **read-in 去重**：按 `healthKitUuid` skip 已导入；已存在相同 (type,date) 的 App 手工数据时，**不覆盖** App 数据（App 本地优先），仅记 pending。
4. **冲突仲裁规则**：同一 (type, day) 双源都有 → 比 `sourceRevision.modifiedDate`，新的赢；写回只影响"我方来源"样本，绝不覆盖其他 App (HKSource) 写入的数据。
5. **删除策略**：App 内删除本地记录时，若 Health 有对应 uuid → 同步 `HKHealthStore.delete`；用户撤销权限 → 停止同步不删本地。

### 4.4 后台同步限制（Phase 3）

| 机制 | 限制 |
|---|---|
| `HKObserverQuery` + `enableBackgroundDelivery(.immediate)` | App 被系统唤醒跑约 1 分钟预算；唤醒时机系统调度，不可控 |
| `BGAppRefreshTask` | 系统智能调度，**不可预测**；不能保证 5 分钟级新鲜度 |
| 前台/冷启动兜底 | 每次 `applicationDidBecomeActive` + 每天首次打开做 anchor 全量核对 = 主要同步通道 |
| 建议 | **不要**追求"实时双向"；HealthKit 定位为"下次打开 App 时同步"，后台只做尽最大努力 |

---

## 五、Schema 兼容性分析

### 5.1 sleep（`sleep_entries.dart`）

| 维度 | App | HealthKit | 处理 |
|---|---|---|---|
| 主键/日期 | `date` = 入睡当天 (calendar day) | sample `start`/`end` Date + `timeZone` | 读入: `date = sample.start` 当地日历日 |
| 时间 | `bedtime` / `wakeTime` (Drift local DateTime) | `start` / `end` (UTC + timeZone) | 必须 `TZDateTime` → local；HK 有 `timeZone` 字段要存下来，避免时区漂移 |
| 时长 | `durationMin` (int, 分钟) | 无 duration 字段，= end-start | 读入重算; 写入时 App 不必传 duration |
| 跨午夜 | 天然跨午夜 (21:00→07:00 算 bedtime 当天) | 单 sample 跨日正常 | 无冲突，`date` 用 start |
| 粒度 | 1 天 1 条粗粒度 | inBed + asleep 多段细粒度 | 写入映射: inBed(start=bedtime, end=wakeTime) + asleep(近似同区间)；读入可**降采样合并**为 App 1 条 (segment 求和) |

### 5.2 weight（`weight_entries.dart`）

| 维度 | App | HealthKit | 处理 |
|---|---|---|---|
| 值 | `weightKg` (kg, 1 位小数, 30-200 校验) | `bodyMass` 单位可配 (kg/lb) | **一律用 `HKUnit.kilogram()` 读写**，让 HK 自动做 kg↔lb 转换，App 永存 kg，杜绝双转换误差 |
| 时间 | `timestamp` | sample start | 1:1 |
| 频次 | 1 天可多次 | 天然多样本 | 1:1 写读 |
| 去重 | 无外部 ID | `HKUUID` | 新增 `healthKitUuid` 列 |

### 5.3 mood（`mood_entries.dart`）

| App | HealthKit stateOfMind (iOS 17+) |
|---|---|
| `score` 1-5 (1=很差 5=很好) | `pleasantness` 1-5 直接映射 ✅ |
| `influenceFactors` (6 大类 30+ 标签) | `HKStateOfMindLabels` + `associatedSentiment`（需做 中文标签→HK label 常量映射表，无法 1:1 全映射，缺失的跳过） |
| `period` (morning/noon/evening/night) | HK 无直接时段概念 → 不映射 |
| `energy`/`sleep`/`anxiety` 子维度 | stateOfMind 无子维度 → 不映射 |
| CBT 字段 | 纯本地 → 不映射 |

### 5.4 需要的新列（schemaVersion 22）

```dart
// sleep_entries / weight_entries / mood_entries 各加 1 列
TextColumn get healthKitUuid => text().nullable()();   // unique，HKUUID 字符串
TextColumn get healthKitSource => text().nullable()();  // HKSource.identifier (可选, 调试用)
```
迁移脚本 `app_database.dart` 三表各 `addColumn` + `schemaVersion 21 → 22`。不加则 read-in 无法幂等去重 → **重复导入 bug**（这是最可能翻车的点）。

---

## 六、用药模块重构 ↔ HKMedicationDose 对齐分析

### 6.1 已对齐的部分 (R101 落地，好消息)

| 新字段 | HKMedicationDose 对应 | 对齐度 |
|---|---|---|
| `form` (tablet/capsule/liquid/patch/injection/other) | `route`/`HKMedication` 形态 | 高 (枚举 ID 一致) |
| `dosage` + `dosageUnit` (mg/ml/片) | `doseQuantity` (HKQuantity value+unit) | 高 (单位需统一 mg) |
| `times[]` (每日多时间点) | `scheduleType` / `timingType` (iOS 16+) | 中 (App 无 weekday 粒度) |
| `colorIndex` / `notes` | 无对应 | 纯本地 |

### 6.2 卡点（架构级）

1. **HKMedicationIdentifier 必须合法**：`HKMedicationDose.medicationIdentifier` 必须是 Apple 药物库中存在的 identifier（按英文/多语言通用名）。App 药名是**用户自由文本中文**（如"舍曲林"），无法直接映射。
   - 选项 A: 写通用名对照表（药物别名→generic identifier），覆盖常见精神科药（舍曲林→sertraline 等），小众药跳过。
   - 选项 B: 不写 medication 到 Health，仅做"iOS Medications 依从性读入"（用户用 iOS 自带药物模块打卡，App 读入补全本地依从性日历）。
   - 选项 C: 放弃 medication 同步。
   - **推荐**: P2 阶段做 A (映射表) + 失败静默降级；不做 B（读入 iOS 药库打卡数据依赖用户在 iOS 里也维护一份药单，双份维护负担大）。

2. **打卡粒度**：App 目前**按天打卡**（spec 决策点 1 方案 B，`check_ins.dart` 无时间点），而 `HKMedicationDose` 是**按时间点样本**。要写 dose 必须先升 方案 A（CheckIn 加 timeSlot 列）——这是**连锁架构改动**，不能只加同步层。
   - **建议**：v1.0 前保持方案 B，medication 同步整块放 P2+，别为同步强行升方案 A。

3. **结论**: 新用药 schema **设计方向**与 Apple Medications 对齐（这是好事），但**落地同步**被"自由文本药名 + 按天打卡"两座山挡住。P2 前不要承诺"用药同步 Health"。

---

## 七、合规/监管注意 (Regulatory)

1. **Apple 健康数据规则**：HealthKit 数据 = 健康数据，受 Apple Developer Program License Agreement §3.3.15 + App Store Review Guideline 5.1.1/1.4.1 约束：
   - ❌ 禁止用于广告/再营销/数据经纪人
   - ❌ 禁止出售
   - ✅ 仅用于 App 功能 + 用户明确授权用途
   - 本项目零广告 SDK / 零第三方统计，**天然合规**，但要在 HealthKit 授权流程中写明"仅用于你的本地追踪，永不上传"。
2. **PIPL §13/§14（中国语境）**：数据写 Health = 用户自主 iCloud 同步，不属于"向第三方提供"，但**隐私政策必须新增 HealthKit 章节**：读什么/写什么/如何撤销/如何删除 Health 数据（用户可在 Health App 全量删除）。
   - 现有 `assets/legal/sensitive_data_consent.md` 需补 HealthKit 独立同意（项目已有 check_legal_consent.py 守门员，新增章节后脚本要放行）。
3. **PrivacyInfo.xcprivacy**：已声明 `HealthAndFitness` ✅。加 HealthKit 后**无需改类型**（仍是 AppFunctionality / Linked=false / Tracking=false）。如经 Health 同步回 App 的数据落库，隐私口径仍一致。
4. **内容评级/上架问答**：App Store Connect "App Privacy" 页需如实勾选 Health & Fitness 数据用途 = AppFunctionality；且不能答 "data collected but not linked" 与实际不符。
5. **App 内首次同步必须显式二次授权**：HealthKit 授权是逐数据类型的系统弹窗，App 内还应有"同步总开关"（撤权入口），不能只有系统弹窗。

---

## 八、分阶段路线图 (Phased Roadmap)

> 前置依赖对全部分阶段通用：**Mac 必须 + Apple Developer Program + 真机**，当前 Windows 环境 0 项满足。

| 阶段 | 内容 | 难度 | 优先级 | 依赖 | 估时 |
|---|---|---|---|---|---|
| **P0 — 基础接入 + 只读镜像** | entitlements + Info.plist 2 key + `health` 包 + `HealthKitService` 骨架 + FeatureFlag `healthKitEnabled` + 权限流程 + 单向读入 (weight → bodyMass, sleep → sleepAnalysis, mood → stateOfMind) + schemaVersion 22 去重列 + 单元/集成测试 | 中 | **P1** (做 HealthKit 前的必由之路; 相对 R104 的 P3 提级, 因为它是后续所有阶段的地基) | Mac / Developer / 真机 / `health` 包 | 1-2 周 |
| **P1 — write-out 备份** | sleep/weight/mood 本地 → HK save + uuid 幂等 + 冲突仲裁 + App 内同步开关/撤权 | 中 | P2 | P0 完成 | 1 周 |
| **P2 — 用药同步** | 通用名→HKMedicationIdentifier 映射表 + (可选) CheckIn 时间点打卡方案 A + HKMedicationDose 写入 | 大 | P3 | P0 + 药名映射表 | 2-3 周 |
| **P3 — 后台同步** | HKObserverQuery + BGAppRefreshTask + UIBackgroundModes processing + anchor resync + AppDelegate 注册 | 大 | P3 | P0/P1 + 后台预算调试 | 2 周 |

**建议总序**: P0 放在 v1.0 之后第一个小版本 (v1.1)，P1 紧随，P2/P3 视用户反馈。R104 "不阻塞上架" 结论保持。

---

## 九、发现清单 (Findings Table)

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|---|---|---|---|---|---|---|
| AH-1 | HealthKit 零集成（无包/无 entitlement/无 HK 代码/无 Info.plist key） | `pubspec.yaml` 全文件; `Runner.entitlements:4`; `Info.plist` 全文件 | 架构 | 大 | P3 | 按 §8 P0 阶段接入; 先 `health` 包起步 |
| AH-2 | 缺 `com.apple.developer.healthkit` entitlement + `NSHealthShare/UpdateUsageDescription` | `ios/Runner/Runner.entitlements:4`; `ios/Runner/Info.plist:157` | 底层 | 简单 | P1 | 按 §3.1-3.2 精确添加 (含 zh-Hans/zh-Hant InfoPlist.strings 同步) |
| AH-3 | 无 Mac 构建环境 + iOS 签名未配置 + Podfile 未生成 | `ios/` (AppStore 视角 A3/A10) | 外部依赖 | 中 | P0(阻塞) | HealthKit 全阶段前置; Windows 环境无法推进，需 Mac + Developer Program |
| AH-4 | 隐私文案缺失 HealthKit 章节 ("零云端"表述需改为"经用户控制的 iCloud Health 同步") | `assets/legal/sensitive_data_consent.md`; `assets/legal/privacy_policy.md` | 底层/合规 | 中 | P2 | 补 HealthKit 独立同意 + PIPL 说明; 过 check_legal_consent.py |
| AH-5 | 用药自由文本中文名无法映射 `HKMedicationIdentifier` | `lib/domain/entities/medication_entity.dart:21`; `add_medication_page.dart:208` | 架构 | 大 | P3 | P2 阶段建通用名映射表 (精神科常用药), 映射失败静默跳过; 不上前承诺 |
| AH-6 | 打卡粒度按天 vs `HKMedicationDose` 按时间点 | `lib/core/data/database/tables/check_in/check_ins.dart:14` | 架构 | 中 | P3 | 保持方案 B; 用药同步整块 P2+，别为同步强升方案 A |
| AH-7 | sleep/weight/mood 表无 `healthKitUuid` 去重列 → 重复导入 | `sleep_entries.dart` / `weight_entries.dart` / `mood_entries.dart` | 架构 | 中 | P2 | schemaVersion 22 三表各加 `healthKitUuid` + `healthKitSource` nullable 列 |
| AH-8 | 单位/时区未规范化 (weight kg↔lb 双转换风险; sleep timeZone 未存) | `weight_entries.dart:17`; `sleep_entries.dart:19-20` | 底层 | 简单 | P2 | HK 侧一律 `HKUnit.kilogram()` 自动转; 存 HK `timeZone` 字段 |
| AH-9 | 无 `healthKitEnabled` FeatureFlag 门控（违反项目 R93 flag 模式） | `lib/core/data/feature_flags.dart:44` | 架构 | 简单 | P2 | 加 1 个 prod-const flag + test override, 未接入前 UI 无入口 |
| AH-10 | 无 HKObserverQuery + 后台同步机制 | `ios/Runner/AppDelegate.swift:25` (R100 已删占位) | 架构 | 大 | P3 | P3 阶段按 §3.3 补 UIBackgroundModes + BGTaskScheduler; 声明即用不声明不写 |
| AH-11 | 无 CDA/FHIR 健康数据导出 (R104 H4) | 全项目 | 架构 | 中 | P3 | 非必需; 仅当需要"导出给医生"场景再做, 维持 P3 nice-to-have |
| AH-12 | ✅ 正向: PrivacyInfo.xcprivacy 已声明 HealthAndFitness (Linked=false/Tracking=false/AppFunctionality) | `ios/Runner/PrivacyInfo.xcprivacy:46` | 合规 | — | — | 无需改; 加 HealthKit 后隐私口径不变 |

---

## 十、结论

- **现状确认**: HealthKit 集成度 = 0，R104 的 4 项问题 (H1-H4) 全部维持，**不阻塞上架**。
- **最大增量发现**: ① 用药模块 R101 新 schema 与 Apple Medications **设计对齐但落地被"自由文本药名 + 按天打卡"两座山挡住** (AH-5/AH-6)；② 去重列缺失是接入时最可能的翻车点 (AH-7)；③ 硬前置 Mac + Developer Program + 真机在当前 Windows 环境全部不满足 (AH-3)。
- **推荐路径**: v1.0 后 v1.1 做 P0 (只读镜像) → P1 (写备份)，保持"App 本地 SQLCipher = 真源，Health = 镜像/备份"的 zero-cloud 语义；用药 (P2) 与后台 (P3) 视反馈再定。
