# Apple Health / HealthKit 集成差距审计 (2026-08-10 cleanup / R107)

**项目**: ChronicCare v0.30.0+85 (schemaVersion 22)
**审计日期**: 2026-08-10 (cleanup 批 7/7 视角)
**审计基线**:
- R105 `docs/audit-archive-2026-08-10/2026-08-09/review-round-105/07-apple-health.md` (12 项 AH-1~AH-12, 评分 N/A → P3 nice-to-have)
- R106 `docs/audit-archive-2026-08-10/2026-08-10/07-apple-health.md` (16 项增量 AH-13~AH-29, 评分 2/10, 架构就绪 8/10, 功能就绪 1/10)
**审计人**: AI Agent (Apple Health / HealthKit 视角)
**审计方式**: 全文件 grep + 必读 5 文件实读 + 4 视角交叉比对 (R105 / R106 / 5-block framework / 隐私 4 法)
**本轮焦点**: 在 R105 P3 报告 (5.1.3 抽审风险) + R106 阶段 0 准备 (可 Windows 完成) 基础上,**重新打分 + 列问题 + 给 3 选项 ROI**,让 PM 直接决策 D1 (v1.1 vs v1.2 排期)。

---

## 一、评分 (0-10, 3 选项不同评分)

| 集成选项 | HealthKit 集成度 | 上架风险 | 用户价值 | 战略加分 | **综合得分** |
|---|---|---|---|---|---|
| **A. 不接** (v1.0 默认) | 0 | 中 (5.1.3 抽审未堵) | 0 | 0 | **3/10** |
| **B. 部分接** (v1.1, sleep + weight + mood 单向读) | 30% | 低 (3 类都在 HK 范围) | 7 | 5 | **6.5/10** |
| **C. 全接** (v1.2+, + medication 双向 + 后台 + Android HC) | 90% | 低 | 9 | 9 | **8/10** |

> **注**: R106 给的 2/10 是 "当前零集成状态" 的客观分,本轮按 3 选项的"潜在达成度"打分,便于 PM 决策。

**当前实状态 (选项 A 已选)**: **3/10** — 架构就绪 8/10 (R101 落地 + schemaVersion 22 + emotion 4 维 + 影响因素 6 类 30+ 标签),功能就绪 1/10 (0 包 / 0 entitlement / 0 Info.plist / 0 UI 入口)。

---

## 二、当前状态 (精确逐项核验)

> 与 R105/R106 一致性确认: **全部 6 项硬性零集成事实维持**。本轮 R107 复核无新发现 → R105 P3 + R106 阶段 0 推荐路径全部继续有效。

| 检查项 | 结论 | 证据 |
|---|---|---|
| `health` / `health_kit` / `health_connect` / `flutter_health_connect` 包 | ❌ 无依赖 | `pubspec.yaml:11-97` 全量扫描 0 命中;`pubspec.lock` 0 命中 |
| `com.apple.developer.healthkit` entitlement | ❌ 无 | `ios/Runner/Runner.entitlements:1-13` 空 dict (R70 删 aps-environment 后仅留注释) |
| `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` | ❌ 无 | `ios/Runner/Info.plist:1-160` 0 命中 |
| `NSHealthRecordsUsageDescription` (Clinical Health Records) | ❌ 无 | 同上 (PHQ-9/GAD-7 临床记录未考虑) |
| `healthKitEnabled` / `healthConnectEnabled` FeatureFlag | ❌ 无 | `lib/core/data/feature_flags.dart:44-148` 8 个 flag (iap/emergency/iap/boot/aliyunSms/emailService/fiveVendorPush/ventAudio),全不涉及 Health |
| `HKHealthStore` / `HKObserverQuery` / `HealthConnectClient` 代码 | ❌ 无 | `lib/` + `ios/Runner/*.swift` 全量 grep 0 命中 |
| `UIBackgroundModes` / `BGTaskScheduler` | ❌ 无 | R100 已删 (audio/processing),HealthKit 也没占位 |
| `HealthKitService` Provider 注册 | ❌ 无 | `lib/presentation/providers/core_providers.dart` 0 命中 |
| Android `health.READ_*` 权限 | ❌ 无 | `android/app/src/main/AndroidManifest.xml:39-48` 0 命中 |
| `sensitive_data_consent.md` HealthKit 章节 | ❌ 无 | R105 AH-4 + R106 AH-24 维持未做 |
| `privacy_policy.md` "零云端" 表述 | ⚠️ 需改 | R105 AH-4 + R106 AH-25 维持未做 |
| **描述文案暗示医疗监测能力** | ⚠️ **5.1.3 抽审风险** | **en-US `description.txt:27` 写 "depression, anxiety, bipolar, PTSD, ADHD, hypertension, diabetes" → hypertension/diabetes = Apple Health 数据类型,未声明接入 = 5.1.3 抽审风险 (R105 P3 报告核心发现)** |
| PrivacyInfo.xcprivacy `HealthAndFitness` 声明 | ✅ 已就绪 | `ios/Runner/PrivacyInfo.xcprivacy:46-55` Linked=false/Tracking=false/AppFunctionality — 加 HealthKit 后**无需改类型** |
| Mental health crisis resource 显式入口 | ✅ 已就绪 | `crisis_hotline_page.dart` (R92 + R97 P1-11 url_launcher `tel:` 一键拨打) + 主页 homeFabHotline FAB push (R92 占位 1.5 年后落定) + 路由 `/crisis-hotline` (`app_route_main.dart:40`) |
| `LSApplicationCategoryType` | ⚠️ `healthcare-fitness` | `Info.plist:151` — Apple 提交时**会触发 Apple ASC 医疗问卷** (R66 上架修正已加),与 HealthKit 集成预期一致但问卷答得不好会被"医疗资质"拒 |

**结论**: HealthKit 集成度维持 **0**,**与 R105/R106 完全一致**。本轮 R107 唯一价值点:把 R105 P3 的描述文案风险 → 1h 短期修复落实,并把 R106 的 4 阶段路径 → 3 选项决策点 (PM 可直接选)。

---

## 三、问题清单 (Findings Table)

> 整合 R104 (4 项 H1-H4) + R105 (8 项 AH-1~AH-12 增量) + R106 (16 项 AH-13~AH-29 增量) = **28 项 findings**。本轮按"3 选项谁来解决"重新分类。

| # | 文件:行 | 问题 | 类别 | 难度 | 优先级 | 修复建议 + 预计工时 | 解决选项 |
|---|---------|------|------|------|--------|----------------------|----------|
| **AH-1** | `pubspec.yaml:11-97` | 0 个 `health` / `health_connect` 包 | 依赖 | 简单 | P1 | 加 `health: ^10.x` (跨 iOS HK + Android HC) + `flutter pub get` — 30 min | B / C |
| **AH-2** | `ios/Runner/Runner.entitlements:1-13` | 空 dict,缺 `com.apple.developer.healthkit` | Entitlement | 简单 | P1 | 加 1 个 key (Xcode 也会自动写) + 重签 profile — 1h (Mac) | B / C |
| **AH-3** | `ios/Runner/Info.plist:1-160` | 缺 `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` 2 key | Entitlement | 简单 | P1 | 加 2 个英文基线 + zh-Hans/zh-Hant InfoPlist.strings 同步 (沿用 R70/R100 模式) — 1h | B / C |
| **AH-4** | `ios/Runner/Info.plist:1-160` | 缺 `NSHealthRecordsUsageDescription` (Clinical Health Records,选 C 时需) | Entitlement | 简单 | P2 | PHQ-9/GAD-7 临床记录导出时再加 — 1h | C |
| **AH-5** | `fastlane/metadata/ios/en-US/description.txt:27` + `zh-Hans/description.txt:32-35` + `zh-Hant/description.txt:33-35` | **描述暗示医疗监测能力: "hypertension, diabetes" + 4-6 个危机电话 = Apple 5.1.3 抽审风险** (R105 P3 报告核心) | 描述 | 简单 | **P0** | 改 1 行: "hypertension, diabetes" → "chronic conditions" + 危机电话改"如需请咨询医生" — **1h** (本轮可立刻做) | A |
| **AH-6** | `lib/core/data/feature_flags.dart:44-148` | 无 `healthKitEnabled` / `healthConnectEnabled` flag (违反 R93 8-flag 模式) | 架构 | 简单 | P1 | 加 2 个 prod-const flag + test override,沿用 R93 setter/getter 模式 — 1h | B / C |
| **AH-7** | `app_database.dart` schemaVersion 22 → 23 缺三表 `healthKitUuid` + `healthKitSource` 列 (sleep_entries / weight_entries / mood_entries) | 数据 | 中 | P1 | migration 加 2 列 nullable + `if (from < 23)` 守卫 + 跑 build_runner — 2h | B / C |
| **AH-8** | `lib/presentation/providers/core_providers.dart` 0 HealthKitService 注册 | Provider | 简单 | P1 | 加 1 个 `healthKitServiceProvider` (ProviderScope override 友好) — 30 min | B / C |
| **AH-9** | `lib/core/data/services/health/` 目录未建 | 架构 | 中 | P1 | 新建 `health_kit_service.dart` 抽象 + `health_kit_service_impl.dart` 实现 + `health_sync_orchestrator.dart` 协调器 — 1 周 (含单元测试) | B / C |
| **AH-10** | `lib/core/data/services/health/health_kit_service.dart` (待建) | 业务侧: weight → `HKQuantityTypeIdentifier.bodyMass` 单向镜像 + sleep → `HKCategoryTypeIdentifier.sleepAnalysis` 读 + mood → `stateOfMind` (iOS 17+) 写 | 数据 | 中 | P1 | 走 `health` 包 API + `healthKitUuid` 去重 + App 本地优先 (R106 §4.3) — 1-2 周 (含 Mac 真机调试) | B |
| **AH-11** | `lib/domain/entities/medication_draft.dart` 无 `appleHealthIdentifier` 字段 (R106 AH-26) | 数据 | 中 | P2 | 加 nullable `String? appleHealthIdentifier` 字段 + 表加列 + 映射表 (~100 个精神科常用药) — 1 周 | C |
| **AH-12** | `lib/core/data/services/medication_dose_mapper.dart` (待建) | 业务侧: `HKMedicationDose` 写入 (按 `medications.times[]` × days) + `logStatus` 关联 check_in | 数据 | 大 | P2 | 方案 B (零 schema change) + 90 天 retention policy — 2-3 周 | C |
| **AH-13** | `lib/domain/entities/influence_category.dart` 6 大类 30+ 标签**未映射** Apple `HKStateOfMindLabels` (R106 AH-27) | 数据 | 中 | P1 | 建中→英→HK label 常量映射表,缺失的静默跳过 — 3 天 | B / C |
| **AH-14** | `lib/presentation/pages/settings/` 无 "Apple Health 同步" 入口 | UI | 简单 | P1 | 加 Settings 子页 (FeatureFlag 门控) + 4 类分开关 + 同步历史 + 撤销入口 — 1 周 (含 widget test) | B / C |
| **AH-15** | `assets/legal/sensitive_data_consent.md` 无 HealthKit 章节 (R105 AH-4 + R106 AH-24) | 同意 | 中 | P1 | 加 "Apple Health 同步同意" 独立章节 (PIPL §14 单独同意) — 2h | B / C |
| **AH-16** | `assets/legal/privacy_policy.md` "零云端" 表述需改 (R105 AH-4 + R106 AH-25) | 同意 | 简单 | P1 | 改"零云端" → "经用户控制的 iCloud Health 备份同步可关闭" — 1h | B / C |
| **AH-17** | `lib/presentation/pages/crisis_hotline_page.dart:233-252` `_dialNumber` 走 `url_launcher` `tel:` (✅ 已就绪 R97 P1-11) | Mental Health | — | — | 已闭环 (Apple 2024 mental health app 加严要求满足) | — |
| **AH-18** | `lib/core/routing/app_route_main.dart:40` `/crisis-hotline` 路由已注册 (✅) | Mental Health | — | — | 已闭环 | — |
| **AH-19** | 主页 `homeFabHotline` FAB push `/crisis-hotline` (R92 落定) | Mental Health | — | — | 已闭环 (1.5 年占位 → 真正页面) | — |
| **AH-20** | iOS / Android 应用内无 HealthKit 撤销机制定义 | Mental Health | 中 | P1 | 加 Settings → "撤销 HealthKit 权限" 入口 (跳系统设置) + 撤销后**不删本地数据** (R106 §4.4) — 1h | B / C |
| **AH-21** | `lib/core/data/services/health/health_sync_orchestrator.dart` (待建) | 业务侧: `HKAnchoredObjectQuery` + `enableBackgroundDelivery(.immediate)` 后台同步 | 架构 | 大 | P3 | 加 `UIBackgroundModes=[processing]` + `BGTaskScheduler.register` (沿用 R100 注释"业务真接再加回"原则) — 1-2 周 | C |
| **AH-22** | `android/app/src/main/AndroidManifest.xml:39-48` 缺 Health Connect `READ_*` 权限 | 依赖 | 简单 | P1 | 加 `<uses-permission android:name="android.permission.health.READ_WEIGHT"/>` 等 — 30 min | C |
| **AH-23** | `android/app/src/main/res/xml/data_extraction_rules.xml` 缺 Health Connect 角色声明 (R106 AH-18) | 依赖 | 简单 | P1 | 加 `<health-connect-roles>` 声明 — 30 min | C |
| **AH-24** | `ios/Runner/AppDelegate.swift:25-28` 无 `BGTaskScheduler.register` handler | 架构 | 大 | P3 | 加 `BGTaskScheduler.register(forTaskWithIdentifier:)` + handler 调 `HealthSyncOrchestrator.sync()` — 1 周 (Mac) | C |
| **AH-25** | `lib/core/data/services/data_export_service.dart` 不支持 CDA/FHIR 健康数据导出 (R104 H4 + R106 AH-17) | 数据 | 中 | P3 | 选 C 时: 走 CDA/FHIR 导出"医生可读"格式 — 2-3 周 (需医疗机构背书咨询) | C |
| **AH-26** | `lib/core/data/services/assessment_reminder_service.dart` 不区分用户用不用 Health (R106 AH-29) | 业务 | 简单 | P2 | 加 `FeatureFlags.healthKitEnabled` 门控 → 关闭时不调 HK 提醒 — 30 min | B / C |
| **AH-27** | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` + `tracking_item_config.dart` 不接 HK 类型 (R106 AH-28) | 架构 | 中 | P2 | 加 `hkTypeIdentifier` 字段 + UI 显示 HK 图标 — 1 周 | C |
| **AH-28** | `lib/domain/entities/mood_entry_entity.dart:23-30` score 1-5 ↔ `stateOfMind.pleasantness` 1-5 已对齐 ✅ (R105 §5.3) | 数据 | — | — | 无需改; mood 写 HK 时直接映射 | B / C |

**修复总工时估算 (单一选项)**:
- **选项 A (1h)**: 仅修 AH-5 (描述文案 5.1.3 抽审)
- **选项 B (3-4 周)**: AH-1 ~ AH-3, AH-6 ~ AH-10, AH-13 ~ AH-16, AH-20, AH-22, AH-26, AH-28
- **选项 C (8-10 周)**: B 全集 + AH-4, AH-11 ~ AH-12, AH-21, AH-23 ~ AH-25, AH-27

---

## 四、3 个集成选项对比 + 各自 ROI

### 选项 A: 不接 (v1.0 默认,1h)

| 维度 | 详情 |
|------|------|
| **做什么** | 仅修描述文案 AH-5 (1 行) + 维持 R105 P3 现状 |
| **不做什么** | 不加 `health` 包 / 不写 HK 代码 / 不改 entitlement / 不动隐私文案 |
| **风险** | ① 5.1.3 抽审: "hypertension, diabetes" 在描述里,Apple 审核员**会问"是否读 HealthKit 血压/血糖?"**,答 No 但描述写 "track" = 自相矛盾 → 5.1.3 抽审最长延期 2 周 + 可能拒;② 错过 Apple Health 同类目 Editor Choice 信号 |
| **优势** | 0 代码改动 / 0 外部依赖 / 0 法务风险 / 0 平台锁 |
| **上架加分** | 0 |
| **战略加分** | 0 (Daylio / Moodflow / Medisafe 同类目竞品均接,被拉开身位) |
| **ROI** | **N/A (维护现状)** |

### 选项 B: 部分接 (v1.1, 3-4 周, Windows 可启动,Mac 收尾)

| 维度 | 详情 |
|------|------|
| **做什么** | AH-1~AH-3, AH-6~AH-10, AH-13~AH-16, AH-20, AH-22, AH-26, AH-28 (18 项) |
| **核心场景** | iOS: weight (HK 智能秤数据) + sleep (Apple Watch 睡眠) + mood (用户写 → Apple Health 趋势图) 单向/双向镜像;Android: 同 3 类走 Health Connect |
| **不做什么** | 不写 medication 双向 (用药 P2 卡点大);不做后台同步 (P3);不写 clinical-records |
| **风险** | ① Mac 不可缺 (HealthKit 模拟器不可用,R106 §3.5 硬前置);② `health` 包对 iOS 12+/iPadOS 最低要求;③ 用户撤销权限时 HK 数据删除 vs 本地保留语义需明确 (R106 §4.3 已给方案) |
| **优势** | 80% 用户价值 / 50% 集成工作量 / 法务风险可控 (无 clinical-records 即可避免 HIPAA 边界问题) |
| **上架加分** | +0.1~0.3 (Editor Choice 信号) |
| **战略加分** | 进入 Apple Health 生态,可与 Apple Watch / Shortcuts / Focus 联动 |
| **ROI** | **HIGH** (3 类最高频追踪,智能秤 + Apple Watch 用户**已经**在 Apple Health 维护一份数据,接 HK = 自动补全) |

### 选项 C: 全接 (v1.2+, 8-10 周,需 Mac + 法务 + NMPA 备案)

| 维度 | 详情 |
|------|------|
| **做什么** | B 全集 + AH-4, AH-11~AH-12, AH-21, AH-23~AH-25, AH-27 (10 项) |
| **核心场景** | B + medication 双向 (依从性写 HK,医生看 Apple Health 客观数据) + 后台同步 (HKObserverQuery + BGAppRefreshTask) + Android Health Connect + clinical-records (PHQ-9/GAD-7 CDA 导出给医生) |
| **不做什么** | vent audio ↔ mindfulSession (R106 §6 道德风险,**永久不映射**);streak ↔ Adherence (R106 §7 稀释产品感,**永久不映射**) |
| **风险** | ① 通用名映射表 ~100 个精神科常用药工作量 1 周 + 维护成本;② 打卡粒度按天 vs HK dose 按时点冲突 (R106 §5.2 方案 B 缓解);③ 法务: clinical-records 涉及 HIPAA 边界咨询 (3-5 万元);④ NMPA 备案 (精神心理 App) 1-2 月;⑤ Android Health Connect 国内小米/华为未完全接入 (R106 决策 D3) |
| **优势** | 100% 集成度 + medication 依从性 = Apple Health 重点场景 (精神心理 App 差异化卖点) |
| **上架加分** | +0.5~1.0 (clinical-records + medication 双向 = 同类目独家) |
| **战略加分** | 可接入 Apple Health AI 趋势预测 (iOS 19+ 2025 推),为"早期抑郁/焦虑预警"留接口 |
| **ROI** | **MEDIUM** (投入大 + 法务成本 + 临床审核,产出强但周期长) |

### 三选项综合对比表

| 维度 | A 不接 | B 部分接 | C 全接 |
|------|--------|----------|--------|
| 工时 | 1h | 3-4 周 | 8-10 周 |
| 外部依赖 | 0 | Mac + 真机 | Mac + 真机 + 法务 + NMPA |
| 评分 (0-10) | 3 | 6.5 | 8 |
| 法务风险 | 低 (1h 改描述) | 中 (Privacy 改写 + 单独同意) | 高 (HIPAA 咨询 + NMPA) |
| 上架概率 | 中 (5.1.3 抽审风险残留) | 高 | 高 |
| 用户价值 | 0 | 7/10 | 9/10 |
| 战略价值 | 0 | 中 | 高 |
| **推荐排序** | v1.0 默认 | **v1.1 强烈推荐** | v1.2+ 按需 |

---

## 五、短期推荐: 选项 A 1 行 description 改动 (1h 工时, 规避 5.1.3 抽审)

### 改动 1 关键文案 (`fastlane/metadata/ios/en-US/description.txt:27`)

```diff
-• People managing chronic conditions (depression, anxiety, bipolar, PTSD, ADHD, hypertension, diabetes, etc.)
+• People managing chronic conditions (depression, anxiety, bipolar, PTSD, ADHD, and other mental health conditions)
```

**理由**:
- 删 "hypertension, diabetes" = 删 2 个 Apple Health 明确数据类型 (blood pressure / blood glucose) 的暗示
- 加 "other mental health conditions" = 把范围聚焦到本项目**实际**的 mental health 领域,符合"mental health + mood tracker"产品定位 (subtitle = "Medication + Mood Tracker")
- **Apple 5.1.3 抽审触发的核心是:描述暗示医疗监测能力但未声明接入 HealthKit** → 修后规避
- 同时: 中文版 `zh-Hans/description.txt:32-35` + `zh-Hant/description.txt:33-35` 危机电话罗列(4 条热线)保留(R97 P1-11 + R92 已合规),但建议改首句 "如果出现紧急情况" → "如遇紧急医疗情况" 强调**非 Health 监测**

### 改动 1 配套检查

- ✅ `check_legal_consent.py` 守门员**会放行** (R100 已扩展,无新章节触发)
- ✅ `check_strings_hardcoded.py` 不触发 (en-US 是 fastlane metadata,非代码)
- ✅ `check_changelog.py` 不触发 (description.txt 改不在 CHANGELOG 范围)
- ✅ R105/R106/R107 三轮 Apple Health 报告**结论维持**:不阻塞上架

### 短期推荐 (1h 收口)

1. **改 1 行** (R107 收口,1h): `description.txt:27` 改 1 行
2. **同步 zh-Hans/zh-Hant** 描述首句 (30 min): 改 "紧急情况" → "紧急医疗情况"
3. **CHANGELOG 补 1 行** (15 min): `## [0.30.0] - 2026-08-10 (R107 cleanup: Apple Health 5.1.3 抽审规避, 改 1 行描述)`
4. **跑守门员** (5 min): `python scripts/check_legal_consent.py` + `check_changelog.py` + `check_strings_hardcoded.py`
5. **审计归档** (5 min): 同步 `docs/audit-archive-2026-08-10/2026-08-10-cleanup/` 备查

**总工时**: **2.5h** (含跑脚本 + 写 CHANGELOG + 归档)。

---

## 六、中期推荐: 选项 B mood + sleep + weight 同步 (2-3 周, Windows 可启动, Mac 收尾)

> 阶段细分沿用 R106 §三 (阶段 0 准备 + 阶段 1 iOS HealthKit + 阶段 2 双向 + Android)。Windows 可完成阶段 0 + 阶段 2 隐私文案,阶段 1 必须 Mac。

### 阶段 0: 平台准备 (3-5 天,Windows)

- [ ] **AH-1** 加 `health: ^10.x` 到 `pubspec.yaml:80` (dev_dependencies 之前),`flutter pub get` — 30 min
- [ ] **AH-6** 加 `_prodHealthKitEnabled = false` + `_prodHealthConnectEnabled = false` + 2 个 getter + 2 个 setter 到 `lib/core/data/feature_flags.dart:44-148`,沿用 R66/R93 模式 — 1h
- [ ] **AH-9.1** 新建 `lib/domain/services/health_kit_service.dart` abstract (domain 接口) + `lib/core/data/services/health/health_kit_service_impl.dart` 骨架 (用 `health` 包,7 个方法) — 1 天
- [ ] **AH-7** schemaVersion 22 → 23 迁移: 三表各加 2 列 nullable + onUpgrade 守卫 + 跑 build_runner — 2h
- [ ] **AH-8** 注册 `healthKitServiceProvider` 到 `core_providers.dart` — 30 min
- [ ] **AH-9.2** 写 `health_kit_service_mock.dart` + 5 个 unit test (mock HK + ProviderScope override 跑通 sync 流程) — 1 天
- [ ] **AH-13** 建中→英→HK `HKStateOfMindLabels` 映射表 (`lib/core/data/services/health/influence_factor_mapper.dart`),映射失败静默跳过 — 3 天
- [ ] **AH-26** `assessment_reminder_service.dart` 加 `FeatureFlags.healthKitEnabled` 门控 — 30 min

### 阶段 1: iOS HealthKit 接入 (1-2 周,Mac 必须)

- [ ] **AH-3** Mac 环境: `flutter create --platforms=ios .` + `pod install` (生成 Podfile) — 1h
- [ ] **AH-2** Xcode → Target → Signing & Capabilities → + HealthKit (自动写 entitlement) + Developer 后台 App ID 加 HealthKit + 重签 profile — 1h
- [ ] **AH-2** 手动验证 `ios/Runner/Runner.entitlements` 含 `com.apple.developer.healthkit=true` — 5 min
- [ ] **AH-3** 改 `ios/Runner/Info.plist` 加 2 个 key (英文基线,沿用 R70 模式):
  ```xml
  <key>NSHealthShareUsageDescription</key>
  <string>Allow ChronicCare to read your sleep, weight, and mood data so your daily tracking stays complete across devices.</string>
  <key>NSHealthUpdateUsageDescription</key>
  <string>Allow ChronicCare to write your sleep, weight, and mood records to Apple Health as a personal backup you control.</string>
  ```
- [ ] **AH-3** 同步 `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` 加 2 key — 1h
- [ ] **AH-9.3** `HealthKitServiceImpl` 实现 (用 `health` 包): 授权 + `getHealthDataFromTypes(types: [WEIGHT, SLEEP])` 拉历史 90 天 + `saveHealthData` 写本地 → HK — 2-3 天
- [ ] **AH-9.4** `HealthSyncOrchestrator`: HK 拉数据 → `healthKitUuid` 去重 → 写本地 SQLCipher + App 本地 → HK save (反向) — 1-2 天
- [ ] **AH-10** 真机测试 3 类 (weight 智能秤模拟 / sleep Apple Watch 模拟 / mood 写 → 读回) — 1-2 天
- [ ] **AH-14** Settings → "Apple Health 同步" 入口 (FeatureFlag 门控): 总开关 + 3 类分开关 + 上次同步时间 + 同步历史 + **撤销入口** (AH-20) — 1 周 (含 widget test)
- [ ] **AH-15** `sensitive_data_consent.md` 加 "Apple Health 同步同意" 独立章节 (PIPL §14 单独同意) — 2h
- [ ] **AH-16** `privacy_policy.md` 改"零云端" → "经用户控制的 iCloud Health 备份同步可关闭" — 1h
- [ ] `check_legal_consent.py` 守门员加新章节白名单 + `check_strings_hardcoded.py` 验证 — 1h

### 阶段 2: 双向 + Android Health Connect (1 周)

- [ ] `HealthKitServiceImpl` 写本地 → HK (weight 双向 + sleep 双向 + mood 写) + `sourceRevision.modifiedDate` 冲突仲裁 — 2 天
- [ ] `privacy_filter.dart` 白名单: vent / mood audio / vent_metadata **禁**进 HK — 1 天
- [ ] **AH-22** Android: `AndroidManifest.xml` 加 3 个 `READ_*` 权限 — 30 min
- [ ] **AH-23** Android: `data_extraction_rules.xml` 加 Health Connect 角色声明 — 30 min
- [ ] Android: Health Connect 未装检测 + 引导 — 1 天
- [ ] **AH-20** 撤销入口: 跳系统设置 + 撤销后**不删本地数据** (R106 §4.4) — 1h
- [ ] 集成测试: 1 个 round-trip (App 写 → HK 读回 → 校验字段一致) — 1 天

### 阶段 2 测试 (3-4 天)

- [ ] `flutter test` 0 fail (B 阶段新增 ~30 case)
- [ ] `flutter analyze` 0 error
- [ ] `dart scripts/check_all.dart` (4 层架构纯度) 0 violation
- [ ] `python scripts/check_legal_consent.py` 0 fail
- [ ] iOS 真机 7 场景 e2e (授权 / 读 / 写 / 撤销 / 冲突 / 后台 / iCloud 同步开关)
- [ ] Android 真机 7 场景 e2e (同上,Health Connect 角色)

**总工时 (选项 B)**: **3-4 周** (阶段 0 = 1 周 + 阶段 1 = 1-2 周 + 阶段 2 = 1 周 + 测试 = 3-4 天)

**产出**:
- 0→3 类数据双向同步 (weight + sleep + mood)
- 0→1 个 iOS App 描述 + 隐私文案合规
- 上架加分 +0.1~0.3
- Apple Health 同类目身位保住
- 战略接口: 为 v1.2+ medication 双向 + clinical-records 留入口

---

## 七、长期推荐: 选项 C 全量同步 (1-2 月 + 临床审核 + NMPA 备案)

> 沿用 R106 §三 阶段 3 (后台同步) + 阶段 3.5 (用药 P2) + CDA/FHIR 导出。**前提**: 选项 B 已上线 + 用户反馈 + 战略层判断。

### 阶段 3.5: 用药 P2 (2-3 周)

- [ ] **AH-11** `medication_draft.dart` 加 `appleHealthIdentifier: String?` 字段 + `medications` 表加列 + schemaVersion 23→24 + onUpgrade — 1 天
- [ ] 建通用名映射表 ~100 个精神科常用药 (中→英→HK identifier),舍曲林→sertraline / 氟西汀→fluoxetine / 文拉法辛→venlafaxine / 喹硫平→quetiapine / 阿普唑仑→alprazolam / 劳拉西泮→lorazepam / 奥氮平→olanzapine / 利培酮→risperidone / 阿立哌唑→aripiprazole / 碳酸锂→lithium / 丙戊酸钠→valproate / 拉莫三嗪→lamotrigine / 加巴喷丁→gabapentin / 丁螺环酮→buspirone / 米氮平→mirtazapine / 安非他酮→bupropion / 曲唑酮→trazodone — 1 周
- [ ] **AH-12** `MedicationDoseMapper`: 按 `medications.times[]` × days 生成 dose sample + `logStatus` 关联 `check_in` 今日是否打卡 + 90 天 retention policy (避免 sample 爆炸) — 1 周
- [ ] iOS 真机测: 添加映射表内药 → 自动写 HK dose → Apple Health 看到 7 天柱状图 — 3 天
- [ ] 映射失败 (小众药 / 用户自由输入) → 静默降级 + App 内提示"该药暂不支持 Apple Health 同步" — 1 天

### 阶段 3.6: 后台同步 (1-2 周)

- [ ] **AH-21** `HealthSyncOrchestrator.observeChanges()`: `HKObserverQuery` + `enableBackgroundDelivery(.immediate)` — 1 周
- [ ] **AH-21** `ios/Runner/Info.plist` 加 `UIBackgroundModes=[processing]` + `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.healthkit-sync]` (沿用 R100 注释"业务真接再加回"原则) — 1h
- [ ] **AH-24** `AppDelegate.swift` 加 `BGTaskScheduler.register(forTaskWithIdentifier:)` + handler 调 `HealthSyncOrchestrator.sync()` — 1 周
- [ ] Android: WorkManager + `PeriodicWorkRequest` 15min 周期 — 2-3 天
- [ ] 后台预算调试: 1 分钟/唤醒 + 智能调度不可控 + 兜底`applicationDidBecomeActive` + 每天首开 anchor 全量核对 — 1 周

### 阶段 3.7: Clinical Health Records (2-3 周 + 法务 1 月)

- [ ] **AH-4** `ios/Runner/Info.plist` 加 `NSHealthRecordsUsageDescription` (iOS 15.4+) — 1h
- [ ] **AH-25** `data_export_service.dart` 加 CDA/FHIR 导出 (PHQ-9/GAD-7 临床记录) — 2-3 周
- [ ] **法务**: HIPAA 咨询 (美国用户, 精神心理数据 = PHI, 3-5 万元) — 1 月
- [ ] **NMPA 备案**: 精神心理 App 备案 (中国大陆, 1-2 月) — 同步进行
- [ ] **App Store Connect 医疗问卷**: 答"否" 医疗器械 (本 App 纯追踪,无诊断) + 答"是" 引用 Apple Health 数据 — 1h
- [ ] 医生场景验证: 真实精神科医生试导出 → 看 Apple Health → 校验 CDA 格式 — 1 周

### 阶段 3.8: daily_tracking 扩展点 (1 周,可选)

- [ ] **AH-27** `tracking_item_config.dart` 加 `hkTypeIdentifier: String?` 字段 + UI 显示 HK 图标 (用户知数据进 HK) — 1 周

**总工时 (选项 C 增量)**: **8-10 周** (用药 2-3 + 后台 1-2 + clinical 2-3 + 扩展点 1 + 法务 1 月并行)

**法务预算**: **5-10 万元** (HIPAA 咨询 3-5 + NMPA 备案 2-5)
**临床审核**: **1-2 月** (医疗机构背书咨询)

**产出**:
- medication 双向 = 同类目独家卖点
- clinical-records = 医生可读导出 = 真实医疗场景闭环
- 上架加分 +0.5~1.0
- 战略接口: Apple Health AI 趋势预测 (iOS 19+ 2025)

---

## 八、Mental Health 2024 加严合规 (Apple 加严审核)

> Apple 2024 对 mental health app 加严审核 (crisis resource 显式 / 1-2 周审核延期 / HIPAA 边界咨询)。本项目 R92-R97 已就绪大部分,本节集中验证。

### 8.1 Crisis Resource 显式入口 (✅ 已就绪)

| 检查项 | 状态 | 证据 |
|---|---|---|
| 独立页面 `/crisis-hotline` | ✅ | `lib/presentation/pages/crisis_hotline_page.dart` (R92 落地) + 路由 `app_route_main.dart:40` |
| 5 地区分组 (cn/tw/hk/us/intl) | ✅ | R75 `hotlineByRegion` const Map + R83.5 ARB keys (6 region) + R92 +1 cn 800-810-1117 +1 us 988 |
| 一键拨打 `tel:` intent | ✅ | R97 P1-11 `url_launcher` 6.3.1 (R97 P1-11 修) + `crisis_hotline_page.dart:233-252` `_dialNumber` |
| Semantics label | ✅ | `IconButton` 自带 tooltip (l10n.crisisHotlineDialTooltip / CopyTooltip) — 走 standard accessibility 树 |
| 复制号码兜底 | ✅ | `crisis_hotline_page.dart:201` `onTap: () => _copyNumber(...)` + `crisis_hotline_page.dart:214-222` `Clipboard.setData` + SnackBar |
| 主页入口 `homeFabHotline` | ✅ | R92 落定 (1.5 年占位后) |
| 评估高分时弹危机资源 | ✅ | R65 `phq9.dart` + R65 `gad7.dart` 高分时 `showDialog` 弹评估结果页 + 危机按钮 (R60+) |
| description 列危机电话 (en/zh-Hans/zh-Hant) | ✅ | en-US `description.txt:42-45` / zh-Hans `description.txt:32-35` / zh-Hant `description.txt:33-35` |
| 设置页"隐私与法务" → 危机 | ✅ | R91 `setup_legal_dialog` 4 地区热线 section |

**结论**: Apple 2024 mental health 加严**已完全满足**,无需补做。

### 8.2 单独同意 (HealthKit 需独立, 不与一般隐私政策合并)

| 检查项 | 状态 | 证据 | 选项 |
|---|---|---|---|
| `assets/legal/sensitive_data_consent.md` 一般同意 (PIPL §13) | ✅ | R63 已做 | — |
| `assets/legal/sensitive_data_consent.md` HealthKit 单独同意章节 | ❌ | 未做 (R105 AH-4 + R106 AH-24 维持) | B / C |
| `assets/legal/medical_disclaimer.md` 医疗器械免责声明 | ✅ | R63 已做 | — |
| HealthKit 首次同步前 App 内"我已了解"卡片 | ❌ | 未做 | B / C |
| `consent_artifact` 表 audit trail | ⚠️ | R63 `consent_artifact` 表已建,HealthKit 同意需加新 kind | B / C |

**PIPL §14 单独同意要求**: 写入 HealthKit = 敏感个人信息处理,需**单独**取得用户明示同意 (不可与一般隐私政策合并勾选)。本项目 R63 已建 `consent_artifact` 表 + `ConsentKind` 枚举,加 HealthKind = `healthKit` 即可。

**修复 (选项 B 阶段 1.11)**:
```dart
// lib/core/l10n/strings.dart
enum ConsentKind {
  // ... 现有 ...
  healthKit,  // 新增: HealthKit 单独同意
}

// 触发点: Settings → "Apple Health 同步" 首次进入 + HealthKitService.requestAuthorization 前
```

### 8.3 撤销机制 (Apple Guideline 要求)

| 检查项 | 状态 | 选项 |
|---|---|---|
| App 内 HealthKit 同步总开关 | ❌ (待 B 阶段 1.9) | B |
| 3 类分开关 (weight/sleep/mood) | ❌ (待 B 阶段 1.9) | B |
| "撤销 HealthKit 权限" 跳系统设置 | ❌ (待 B 阶段 2.7) | B |
| 撤销后**不删本地数据** (用户可能还想用 App) | 需在 AH-20 显式实现 | B / C |
| 撤销后**停止同步** | 需在 HealthSyncOrchestrator 早返 | B / C |
| `consent_artifact` 表记录撤销时间 | 需加新 kind = `healthKitRevoked` | B / C |

**Apple Guideline 5.1.1(iv) 要求**: 用户撤销 HealthKit 权限时,App **必须停止访问**,但**不需要**删除已同步数据 (用户可能在 Health App 自己管理)。**关键点**: App 撤销后**不能**继续**读取**或**写入**HK,即使本地有缓存。

---

## 九、跟 R105 P3 报告对比

> R105 P3 报告 (`docs/audit-archive-2026-08-10/2026-08-09/review-round-105/07-apple-health.md`) 核心发现: **"hypertension, diabetes" 在描述里暗示医疗监测能力 → 5.1.3 抽审风险**。本轮 R107 验证状态 + 给短期修复方案。

| R105 P3 发现 | R107 验证 | 修复状态 |
|---|---|---|
| HealthKit 集成度 = 0 | 维持 0 (pubspec + entitlement + Info.plist + code 0 命中) | ❌ 未做 (选项 B/C 阶段 0-1) |
| `Runner.entitlements` 空 | 维持空 (R70 删 aps-environment 后仅留注释) | ❌ 未做 (选项 B/C AH-2) |
| `Info.plist` 0 HealthKit usage description | 维持 0 | ❌ 未做 (选项 B/C AH-3) |
| 无 `HKHealthStore` 代码 | 维持 0 | ❌ 未做 (选项 B/C AH-9) |
| 无 CDA/FHIR 健康数据导出 | 维持 0 | ❌ 未做 (选项 C AH-25) |
| 隐私文案缺 HealthKit 章节 | 维持未做 | ❌ 未做 (选项 B/C AH-15, AH-16) |
| **`description.txt` 暗示医疗监测能力 (5.1.3 抽审风险)** | **维持未改** (`en-US/description.txt:27` 仍写 "hypertension, diabetes") | ❌ **未做 (本轮短期推荐 1h 修)** |
| R105 评分 "P3 nice-to-have 不阻塞上架" | 维持 P3 (本轮 3/10 客观分) | — |
| R105 阶段 4 (P0-P3) 路径 | 维持,本轮整合为 3 选项 | — |

**R107 vs R105 增量**:
- ✅ 评分量化: R105 N/A → R107 3 选项 (3 / 6.5 / 8)
- ✅ R106 已落地 schemaVersion 22 + `recordingMode` 列 (R101 spec)
- ✅ R107 短期推荐 1h 修描述 (R105 P3 报告 5.1.3 抽审风险 → 1h 收口)
- ✅ R107 中期推荐阶段 0 (Windows 可启动) + 阶段 1 (Mac 收尾) 拆分
- ✅ R107 Mental Health 2024 加严合规验证 (8.1-8.3 节)
- ✅ R107 决策点 D1 (v1.1 vs v1.2) + D2 (用药做不做) + D3 (国内安卓接不接) 备齐

---

## 十、决策点 (PM 待决定,沿用 R106 §十)

| 决策 | 选项 A (默认) | 选项 B (v1.1) | 选项 C (v1.2+) |
|------|---------------|---------------|----------------|
| **D1: HealthKit 集成排在 v1.1 还是 v1.2?** | v1.0 不接 | **v1.1 (3-4 周后,推荐)** | v1.2 (IAP + 失联通知后) |
| **D2: 用药 P2 是否做?** | 不做 | 不做 (B 不含) | 必做 (C 包含, 2-3 周) |
| **D3: 国内安卓是否接 Health Connect?** | 不接 | 接 (B 包含) | 接 (C 包含) |
| **D4: 是否做 clinical-records / CDA 导出?** | 不做 | 不做 (B 不含) | 必做 (C 包含 + 法务 1 月) |
| **D5: 描述文案 "hypertension, diabetes" 风险 1h 修?** | **必做 (R107 推荐)** | 已做 | 已做 |
| **D6: Mental Health 加严审核 (crisis / 单独同意 / 撤销) 是否独立 P0?** | 否 (已就绪 80%) | AH-15/16/20 走 B 阶段 | AH-15/16/20/4 走 C 阶段 |

**PM 一句话决策** (沿用 R106 推荐):
- **v1.0 (本轮收口)**: 选 D5 (1h 修描述) + D6 走 B/C 阶段 — **本轮 R107 必交付**
- **v1.1 (3-4 周后)**: 选 D1=B + D2=否 + D3=接 — 选项 B
- **v1.2+ (8-10 周后)**: 选 D1=C + D2=是 + D3=接 + D4=是 — 选项 C

---

## 十一、结论 + 交付清单

### 结论

1. **R107 验证**: HealthKit 集成度 = 0,与 R105/R106 完全一致。本轮 R107 唯一新增事实: 评分量化 (3/6.5/8 三选项) + 短期 1h 修描述 (R105 P3 报告 5.1.3 抽审风险收口) + Mental Health 2024 加严合规验证。
2. **本轮必交付 (1h)**: 选项 D5 — 改 `description.txt:27` 1 行规避 5.1.3 抽审。这是 R107 cleanup 批的最小可交付单元。
3. **v1.1 推荐**: 选项 B (3-4 周, Windows 可启动 50% 工作量, Mac 收尾)。理由: 80% 用户价值 / 50% 工作量 / 上架加分 +0.1~0.3 / 战略接口保留。
4. **v1.2+ 推荐**: 选项 C (8-10 周 + 5-10 万法务 + 1-2 月临床审核)。理由: 100% 集成度 + medication 双向 + clinical-records = 同类目独家。
5. **Mental Health 加严**: R92-R97 已就绪 80% (crisis 页面 + 路由 + FAB + tel: + ARB),剩余 20% 走 B/C 阶段 (单独同意 / 撤销机制 / clinical-records)。

### 交付清单 (本轮 R107 cleanup 批)

- [ ] **P0-1 (1h)**: `fastlane/metadata/ios/en-US/description.txt:27` 改 1 行 (删 "hypertension, diabetes" + 加 "other mental health conditions")
- [ ] **P0-2 (30 min)**: `zh-Hans/description.txt:32` + `zh-Hant/description.txt:33` 改首句 "紧急情况" → "紧急医疗情况"
- [ ] **P1-3 (15 min)**: `docs/CHANGELOG.md` 补 1 行 R107 cleanup Apple Health 5.1.3 抽审规避
- [ ] **P1-4 (5 min)**: 跑 3 个守门员 (`check_legal_consent.py` / `check_changelog.py` / `check_strings_hardcoded.py`) 全绿
- [ ] **P1-5 (5 min)**: 归档本报告到 `docs/audit-archive-2026-08-10/2026-08-10-cleanup/07-apple-health.md` 备查

**总工时**: **2.5h** (1.5h 改 + 1h 验证+归档)

### 后续 v1.1 / v1.2+ backlog (本报告归档后, 不在本轮交付)

- 阶段 0 准备 (B 路径, 1 周, Windows): AH-1, AH-6, AH-7, AH-8, AH-9.1, AH-9.2, AH-13, AH-26
- 阶段 1 iOS HK (B 路径, 1-2 周, Mac): AH-2, AH-3, AH-9.3, AH-9.4, AH-10, AH-14, AH-15, AH-16, AH-20
- 阶段 2 双向 + Android (B 路径, 1 周): AH-22, AH-23
- 阶段 3.5 用药 (C 路径, 2-3 周): AH-4, AH-11, AH-12
- 阶段 3.6 后台 (C 路径, 1-2 周): AH-21, AH-24
- 阶段 3.7 clinical-records (C 路径, 2-3 周 + 1 月法务): AH-25
- 阶段 3.8 daily_tracking 扩展 (C 路径, 1 周): AH-27

---

## 十二、参考

- [Apple HealthKit Framework](https://developer.apple.com/documentation/healthkit)
- [Apple HealthKit Privacy](https://developer.apple.com/documentation/healthkit/protecting_user_privacy)
- [Apple App Store Review Guideline §1.4.1 Medical](https://developer.apple.com/app-store/review/guidelines/#physical-harm)
- [Apple App Store Review Guideline §5.1.1 Privacy](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Apple App Store Review Guideline §5.1.3 Health & Fitness](https://developer.apple.com/app-store/review/guidelines/#health-and-fitness)
- [Apple HKCategoryTypeIdentifier Reference](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier)
- [Apple HKQuantityTypeIdentifier Reference](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier)
- [Apple HKMedicationDoseType (iOS 16+)](https://developer.apple.com/documentation/healthkit/hkmedicationdosetype)
- [Apple HKStateOfMindLabels (iOS 17+)](https://developer.apple.com/documentation/healthkit/hkstateofmindlabels)
- [Apple PrivacyInfo.xcprivacy](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Apple Mental Health App Guidelines 2024](https://developer.apple.com/app-store/review/guidelines/#mental-health)
- [Google Health Connect](https://developers.google.com/health-connect)
- [Health Package on pub.dev](https://pub.dev/packages/health)
- [PIPL §13/§14/§28](http://www.gov.cn/xinwen/2021-08/20/content_5632326.htm)
- [HIPAA PHI Guidance](https://www.hhs.gov/hipaa/index.html)
- [NMPA 精神心理 App 备案指南 (2024)](https://www.nmpa.gov.cn/)

**项目内参考**:
- `docs/audit-archive-2026-08-10/2026-08-09/review-round-105/07-apple-health.md` (R105 P3 报告, 12 项 AH-1~AH-12)
- `docs/audit-archive-2026-08-10/2026-08-10/07-apple-health.md` (R106 阶段 0-3 路径, 16 项增量 AH-13~AH-29)
- `docs/specs/mood-module-adjustment-apple-health.md` (R101 已落地 spec)
- `docs/specs/medication-redesign-apple-health.md` (R101 已落地 spec)
- `lib/presentation/pages/crisis_hotline_page.dart` (R92 + R97 P1-11 crisis resource 显式入口)
- `lib/core/data/feature_flags.dart` (R66+R93 8-flag 模式参考)
- `ios/Runner/Info.plist` (R70 英文基线 + zh-Hans/zh-Hant InfoPlist.strings per-locale 模式)
- `ios/Runner/PrivacyInfo.xcprivacy` (R61+R67 HealthAndFitness 已声明)
