# 项目综合审计报告 (2026-08-06)

> **审计对象**: `D:\Batch\chroniccare` v0.30.0+85 (R91)
> **审计员**: 6 视角独立 subagent 并发审计
> **总报告体量**: 376.8 KB / 6 份独立报告 / 6.0 万字
> **审计方式**: 静态只读,未跑 `flutter analyze` / `flutter test` / build

---

## 6 视角评分总览

| # | 视角 | 评分 | 重点维度 | 上架就绪度 |
|---|------|------|----------|-----------|
| 01 | **emilkowalski** (设计工程) | **7.5 / 10** | token 化顶级,执行分裂,3 个 P0 半成品 | — |
| 02 | **superpowers-en** (英文软件工程) | **8.0 / 10** | SDD 闭环 + 16 守门员,5 P0 bug 漏测 | — |
| 03 | **superpowers-zh** (中文 + 国内合规) | 工程 8.0 / 合规 3.5 / 资质 1.0 / 中文 7.5 / Git 6.0 | 代码顶,合规掉底 | — |
| 04 | **AppStore** (iOS 上架) | **6.0 / 10** | 9 平台配置已修,3 法务 + IAP + SMS 未就绪 | iOS 6.0 / 10 |
| 05 | **GooglePlay** (Android 上架) | **38 %** | 代码层稳,法务 / 5 厂商 push / 失联业务 4 大块 TODO | Android 38 % |
| 06 | **flutter-spec** (v3.1 规范) | **84 % 合规** | 架构整体优秀,6 P0 阻断 (签名 / Podfile / SMS 守卫 / PIPL / PHQ i18n / web 端) | — |

**项目当前最准确的一句话**: **代码 / 架构 / 工程自动化是国内中型项目天花板,但中国 + Apple + Google 三 store 全链路未跑通**。海外 GitHub 可发,任何 store 都上不了。

---

## 顶层架构审视 (高内聚低耦合)

### 结论: **不需要重设顶层架构**。4 层 + 5 子层 umbrella 已成范式,需要的是「拆 facade / 收尾 god page / 修业务闭环」,不是换架构。

#### 1. 顶层架构现状 (4 层 + 5 子层 umbrella, 已成)

```
lib/
├── main.dart              # 入口 (R62 修 4 步启动顺序)
├── app.dart               # App root + AppLifecycleState (R64)
├── core/                  # 基础设施 umbrella
│   ├── data/             # DB (Drift+SQLCipher) + 18+ service + repos
│   ├── shared/           # 7 跨层 helper
│   ├── theme/            # AppTokens 5 子模块 + MotionScheme 4 档
│   ├── routing/          # go_router 7 子文件
│   └── l10n/             # domain Strings
├── l10n/                  # presentation ARB (3 语)
├── domain/                # 21 entity + 4 logic + 10 repo + 4 usecase
└── presentation/          # 18 provider + 11 feature/page
```

- ✅ **4 层纯度守住**: domain 0 flutter 0 drift 0 data (16 守门员 + `check_all.dart` 实测)
- ✅ **1 feature 1 目录**: 11 page 拆清楚
- ✅ **core 5 子层 umbrella** 干净 (`check_all.dart` 跑过)
- ✅ **Riverpod 3.x 抽象接口 + impl + Provider 暴露** 模式统一

#### 2. **不需要重设计**, 但需要 3 件事 (中等粒度, 估时 1-2 quarter)

| # | 模块 | 当前 | 建议 | 理由 | 估时 |
|---|------|------|------|------|------|
| A | `lib/core/data/services/notification_service.dart` (450 行) | facade + 6 sub (R65 拆过) | 评估是否再拆 1 层 facade (orchestrator + 6 sub) | sub 数量已 6,超 facade 边界 | 1-2 周 |
| B | `lib/core/data/services/safety_watch_service.dart` (388-457 行) | facade + 3 sub | 续拆为 `safety_detector` + `safety_alert_builder` + `safety_alert_dispatcher` + facade (R56c''' 已部分拆) | 失联检测 + 通知 + 升级 3 职责混 | 1-2 周 |
| C | 3 个 600+ 行 god page (`assessment_page.dart:436` / `medication_calendar_page.dart:642` / `data_management_section.dart:606`) | 单文件 600+ 行 | 拆 `pages/{feature}/widgets/{sub}_page.dart` 子目录 (已部分拆,继续) | god page 维护成本 + 单测困难 | 2-4 周 |

#### 3. 5 个**可独立拆出**的模块 (v1.0+ 评估, 当前不建议)

| 候选 package | 现状 | 拆出价值 | 当前建议 |
|---|---|---|---|
| `chroniccare_design_tokens` | 5 文件 1083 行 | token 独立发版 | ❌ 不建议 (1 应用内 feature cross-import 仍频繁, 拆 package 增 monorepo 复杂度) |
| `chroniccare_i18n` | 700+ keys / 3 语 | 翻译协作 | ❌ 同上 |
| `chroniccare_assessment` | 8 量表 1700+ 行 | 临床量表独立 | ❌ 同上 |
| `chroniccare_safety` | 失联检测 + 通知 | 失联业务独立 | ❌ 同上 (业务已暂停, 拆无价值) |
| `chroniccare_audio` | 树洞 + 情绪加密音频 | 加密音频独立 | ❌ 同上 |

#### 4. 高内聚低耦合「关键模块」评分

| 模块 | 内聚 | 耦合 | 评分 |
|------|------|------|------|
| `care_engine.dart` + `care_strategies.dart` | 单一 (4 策略 + 1 装配) | 0 flutter 0 drift 0 data | **A+** |
| `contact_dao.dart` | 单一 (4 method) | 仅 `_db` | **A** |
| `safety_watch_service.dart` (388-457 行) | facade + 3 sub | 5 repo + 3 service | **B+** (可继续拆 facade 编排) |
| `assessment_page.dart` (436 行) | god page (答题+状态机+危机) | 12 import | **C** (v1.0 必拆) |
| `medication_calendar_page.dart` (642 行) | god page | 15 import | **C-** (v1.0 必拆) |
| `export_orchestrator.dart` (266 行) | facade + 4 sub | 4 service + 1 db | **A** (R57 拆过) |
| `notification_service.dart` (450 行) | facade + 6 sub | 6 service + 1 plugin | **A** (R65 拆过) |

---

## 上架就绪度矩阵

| 维度 | Android (Google Play) | iOS (App Store) | 国内合规 | 备注 |
|------|----------------------|----------------|----------|------|
| **代码 / 工程** | ✅ 90% (签名 fallback debug 必修) | ✅ 90% (Podfile.lock 缺) | — | flutter-spec 84% 合规 |
| **4 层架构纯度** | ✅ 100% | ✅ 100% | — | check_all.dart 绿 |
| **16 守门员** | ✅ 14 全绿 + 1 warn + 1 已知 | ✅ 同上 | — | R60 修过 |
| **PIPL §13/§14/§17/§47/§50/§54** | ❌ 部分缺 | — | ❌ 部分缺 | 需法务过审 |
| **法务 3 份 md** | ❌ 标"草稿" | ❌ 同上 | ❌ 同上 | 律师签字 ¥45-90k |
| **失联通知** | ❌ mock + FeatureFlag 关 | ❌ mock | ❌ mock | 阿里云 SMS 1-2 月审核 |
| **5 厂商 push** | ❌ 0 接入 | — | ❌ 0 接入 | 推送送达率 < 70% |
| **IAP** | ❌ FeatureFlag 关 | ❌ FeatureFlag 关 | ❌ 关 | R68 关 避 Apple 2.1 拒 |
| **PHQ-9/GAD-7 16 题 i18n** | ❌ flag 关闭 | ❌ 同上 | ❌ 同上 | 医疗法律责任 |
| **隐私 / 删除 URL** | ❌ 占位 | ❌ 占位 | ❌ 占位 | 域名未注册 |
| **签名** | ❌ debug fallback | ❌ DEVELOPMENT_TEAM TODO | — | 必改 |
| **App Store 截图 / Icon** | — | ❌ 33 张 67B 占位 | — | 必拒 |
| **TestFlight 跑过** | — | ❌ 0 跑过 | — | 0 崩溃率数据 |
| **Apple Privacy Manifest** | — | ✅ R74 完成 | — | — |
| **16KB alignment** | ✅ R84 完成 | — | — | — |
| **AGENTS.md / README 同步** | ⚠️ 漏 1 守门员 | ⚠️ 同上 | ⚠️ 6 份"App"混用 | — |
| **3 个 P0 半成品 widget** | ⚠️ 全平台 | ⚠️ 全平台 | ⚠️ 全平台 | CBT wizard / FAB stub / treatment placeholder |
| **整体上架就绪度** | **38%** | **6.0/10** | **3.5/10** | — |

---

## 修复优先级 (按 P0 → P3)

### 🔴 P0 (上架 blocker, 必改)

> **合并去重后, 跨 6 视角累计 50+ P0 项, 关键核心 22 项, 实际必修 15-20 项**

#### A. 业务半成品 (跨视角高频)

| # | P0 项 | 视角 | 文件:行 | 难度 | 估时 |
|---|------|------|---------|------|------|
| 1 | **AliyunSms 真接** (release 永远 throw StateError) | 02/03/04/05/06 | `sms_service.dart:90-201` | XL | 1-2d + 2-4w 审核 |
| 2 | **EmailService 真接 SendGrid** | 02/03/04/05/06 | `email_service.dart:162-163` | L | 1-2w + 模板审核 |
| 3 | **CBT wizard 5/7 栏"完成"不触发 save → 字段静默丢失** | 01 | `cbt_wizard.dart:92-105` | M | 2-3d |
| 4 | **homeFabHotline / homeFabTop 是 stub snackbar** | 01 | `home_fab_toolbar.dart:84-104` | M | 3-5d |
| 5 | **assessment_center 顶部 mini 趋势图是 TODO SizedBox** | 01/02 | `assessment_center_page.dart:64-67` | M | 3-5d |
| 6 | **treatment_placeholder 整个文件是占位** | 01/02 | `daily_tracking/widgets/treatment_placeholder.dart` | M | 2-3d |
| 7 | **PHQ-9 / GAD-7 16 题 i18n 关闭 → 法律责任** | 03/06 | `scale_translations.dart:1-50` + `FeatureFlags._prodPhqGad7I18nEnabled=false` | L | 1-2w |

#### B. 上架 / 法务 (跨视角高频)

| # | P0 项 | 视角 | 文件:行 | 难度 | 估时 |
|---|------|------|---------|------|------|
| 8 | **3 份法律 md 律师过审** (¥45-90k) | 03/04/05 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 标"草稿" | XL | 4w (法务) |
| 9 | **域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署** | 03/04/05 | 占位 URL | M | 1-2d + 3-5d 部署 |
| 10 | **邮箱注册 (`support@` / `privacy@chroniccare.app`)** | 03/04/05 | md 内引用 | S | 1-2h |
| 11 | **5 厂商 push SDK 接入** (米/华/OPP/vivo/魅族, 1-2 月) | 03/05 | `PUSH_PROVIDERS.md` 仅有 plan | XL | 1-2 月 (并行) |
| 12 | **5 厂商 + 鸿蒙/HarmonyOS NEXT 适配** | 03/05 | — | XL | 1-2 月 |
| 13 | **iOS 33 张截图 + AppIcon 1024 替换占位** | 04 | `fastlane/metadata/ios/{3 locale}/screenshots/*.png` (67B 占位) | L | 设计师 2-3d + Mac |
| 14 | **iOS fastlane/Appfile 4 ID 填** (apple_id/team_id/itc_team_id) | 04 | `fastlane/Appfile:21,23,25` | S | 1h (Mac) |
| 15 | **iOS 签名 DEVELOPMENT_TEAM 填** | 04/06 | `ios/Runner.xcodeproj` 3 处 | S | 1h |
| 16 | **iOS iOS 18+ Dark Mode App Icon 4 套** | 04 | 缺 | M | 设计师 2-3d |
| 17 | **Android keystore + Play App Signing** | 03/05/06 | `key.properties` 不存在 + `build.gradle.kts:74-80` fallback debug | S | 1-2h (脚本) |
| 18 | **iOS Podfile 真生成** (macOS 跑 `pod install`) | 04/06 | `ios/Podfile:1-7` 占位 | S | 0.5d (Mac) |
| 19 | **PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54 全部法律条文合规** | 03 | 跨多文件 | XL | 1-2 月 (法务) |
| 20 | **PIPL §17 失联通知告知不准确 → 业务暂停 vs 文档矛盾** | 03 | 3 份 md + FeatureFlag | L | 1-2w |

#### C. 数据 / 架构

| # | P0 项 | 视角 | 文件:行 | 难度 | 估时 |
|---|------|------|---------|------|------|
| 21 | **vent 旧 `contentText` TEXT 列 DROP** (明文 + 加密双份存在 DB, PIPL §28 泄露) | 02 | `app_database.dart` schemaVersion 18→19 + `tables/vent/vent_entries.dart` | M | 1-2d |
| 22 | **`assessment_center_page` 第 1 行硬编码中文** → 走 `l10n.assessmentCenterTitle` | 02 | `assessment_center_page.dart:1` | S | 5min |

#### D. 设计 / UX (上架前必修)

| # | P0 项 | 视角 | 文件:行 | 难度 | 估时 |
|---|------|------|---------|------|------|
| 23 | **设置页 IAP 升级 Pro 商业卡当头炮** (精神心理患者 App 调性冲突) | 01 | `settings_page.dart:55-148` | L | 1w (改架构 4 group) |
| 24 | **设置页 8 section → 4 group 重构** (用户档案 / 提醒 / 数据 / 法律) | 01 | `settings_page.dart:34-242` | L | 1-2w |

---

### 🟠 P1 (重要, 1 个月内修, 跨 6 视角累计 60+ 项, 关键 30 项)

#### 设计 / UX (P1 = 体验问题)
- 主页 hero illustration 140dp 视觉几乎 0 (issue 1.2.10)
- 主页 8 widget 堆叠, primary action 不突出 (issue 2.2.3)
- 紧急联系人添加 5 步 → 3 步 (emil "3 tap 抵达")
- 数据导出 5 步 → 3 步
- quick mood carousel 1 tap 0 反馈 (误触落库)
- medication_calendar 30 天热力图 0 tap 详情
- 通知状态卡 17 步纯文字 0 截图 0 链接
- vent 长按/swipe 删除 0 视觉提示
- 主页 3 icon button 0 tooltip
- 158 处 TextStyle + 162 处 EdgeInsets 残留 (40% magic)

#### 工程 / 架构
- 启动加 `_bootstrapHealthCheck` 步骤 7 (superpowers-en #6)
- `safety_watch_service` 失联检测窗口加 unit test (DST/跨年/24h)
- 抽 `AudioController` 抽象, vent + mood 4 widget 共享
- 14 文件 45 处硬编码中文 → 走 l10n key
- `check_strings_hardcoded.py` 规则加严
- 3 处 `} catch (_) {` 改 `swallowError` 集中器 (R17 模式)
- `mavis-trash .worktrees/feat-cbt-thought-report/`, `git worktree prune`
- 拆 `notification_service.dart` ≥ 2 层 facade
- `.github/workflows/ci.yml` (flutter test + analyze + 16 guards)
- vent 跟 mood 加密 key 独立 (拆 `EncryptionService` 3 key)
- 11+ 处 `catch (_) { ... }` 静默吞错 (flutter-spec #2.9)
- 3 个 600+ 行 god page 拆 (assessment / medication_calendar / data_management_section)
- 集成测试 1 → 3-5 个
- 18+ service 子类 sub-service 测试 (R56c 续修)
- coverage 阈值 (≥ 70% domain / 50% data) + Codecov
- `assessment_dao._rowToEntry` 解析失败 PII 泄露
- audit log 明文 (PIPL §47 删除权)
- CI 缺 coverage / `flutter build appbundle` / release publish
- web 端 fail-fast (P0 #7 flutter-spec)
- `app_router.dart` redirect 嵌套路径 startsWith 守卫
- 9 个 600+ 行 god page 拆 (R19c 已评, 未拆)
- 50+ `Duration(milliseconds:)` + 50+ `Curves.easeXxx` 残留 (~30% token 化)
- email_preview.dart 整个文件是 v0.4 早期版残留 (失联是 SMS, 不是 email)
- email 主题 `[Medication Reminder] $safeName missed check-in for 2 days` 半中半英
- 主页 header 3 icon button 0 tooltip
- 趋势页 4 StatCard 改 narrative
- legal_page toggle 加 chip 标识撤回时间

---

### 🟡 P2 (建议, 1 quarter 内, 跨 6 视角累计 80+ 项, 关键 30 项)

(略, 详见各报告 P2 章节)

---

### 🟢 P3 (nice-to-have, 长期)

(略, 详见各报告 P3 章节)

---

## 半成品 / 残缺项 / TODO 总览 (跨 6 视角合并去重)

### 半成品 widget / 页面 (跨视角, 上架前必清)

| # | 文件 | 状态 | 视角 | 上架影响 |
|---|------|------|------|----------|
| 1 | `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105` | 5/7 栏"完成"不触发 save | 01 | 用户 CBT 字段静默丢失 (P0) |
| 2 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:84-104` | "紧急热线" / "回到顶端" stub snackbar | 01 | 用户点无反应 (P0) |
| 3 | `lib/presentation/pages/assessment/assessment_center_page.dart:64-67` | 顶部 mini 趋势图 TODO SizedBox | 01/02 | 页面 200dp 空 (P0) |
| 4 | `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart` | 整个文件是占位 widget | 01/02 | 整合页"治疗"卡进占位 (P0) |
| 5 | `lib/presentation/pages/settings/email_preview.dart:13-152` | 整个 email preview 页面残留 | 01/02 | 失联走 SMS, email 是 v0.4 早期版 (P2) |
| 6 | `lib/presentation/pages/mood/mood_dialog.dart:20-25` | 25 行薄壳 god-pattern 纯转发 | 01 | emil "honest abstraction" 应直接是 MoodRecorderPage (P3) |
| 7 | `lib/presentation/pages/medication/refill_manage_page.dart:78-85` | 4 StatCard 数字挤一起早期版 | 01 | 应改 2x2 grid (P2) |
| 8 | `lib/presentation/pages/setup/setup_step_medication.dart:106-132` | PrimaryButton 包在 110×44 narrow SizedBox + Stack (Text + Spinner overlay) hacky | 01 | 应改 PressFeedback + LoadingSpinner (P3) |

### 半成品 service (业务未真接)

| # | 文件 | 状态 | 视角 | 上架影响 |
|---|------|------|------|----------|
| 1 | `lib/core/data/services/sms_service.dart:90-201` | AliyunSmsProvider send() throw StateError | 02/03/04/05/06 | release 永远不工作 (P0) |
| 2 | `lib/core/data/services/email_service.dart:162-163` | sendMedicationReminder 返 false (mock) | 02/03/04/05/06 | 同上 (P0) |
| 3 | `lib/core/data/services/store_kit_service.dart:50,108-119` | IAP 0 test + `buyLifetime` release 返 false | 02/04 | 8 元买断用户买不到 (P0) |
| 4 | `lib/core/data/feature_flags.dart:35` | `_prodEmergencyContactEnabled = false` 失联通知暂停 | 02/03/05 | 跟 README "自动 SMS 通知紧急联系人" 不一致 (P0) |
| 5 | `lib/core/data/feature_flags.dart:38` | `_prodIapEnabled = false` 软隐藏 IAP | 02/03/04/05 | 跟 user_agreement §3 "8 元买断" 不一致 (P0) |
| 6 | `lib/core/data/feature_flags.dart:42` | `_prodBootReceiverEnabled = true` 但 0 实现 (R65) | 02/03 | 靠 flutter_local_notifications 兜底 (P1) |
| 7 | `lib/domain/logic/scale_registry.dart:5` | NSESSS / CRDPSS TODO | 02/06 | v0.31+ 法务审核 + 用户自决 (P1) |
| 8 | `lib/domain/entities/scale_translations.dart:1-50` | PHQ-9 / GAD-7 16 题 i18n 留 v1.0 | 02/03/06 | en / zh_Hant 法律责任 (P0) |
| 9 | `lib/core/shared/legal_version.dart:43-45` | `kPubspecVersion` 手动同步 | 06 | R78+ 考虑 `package_info_plus` 自动 (P3) |
| 10 | `lib/core/data/services/data_export_service.dart` | vent audio 不导出文件 (跨设备路径失效) | 06 | 只导 metadata 引用 (P1) |
| 11 | `lib/core/shared/consent_gate.dart:168-174` | ConsentKind.safety/vent/analytics 撤回 fallback 硬编中文 | 06 | 需 i18n 化 (P1) |
| 12 | `lib/core/routing/notification_navigation.dart` | BGTaskScheduler iOS handler `setTaskCompleted(success: true)` 占位 | 06 | 业务真接 SMS 时需调 Flutter MethodChannel (P1) |

### 残缺 / 物理残留 (跨视角合并)

| # | 项 | 视角 | 备注 |
|---|-----|------|------|
| 1 | `.worktrees/feat-cbt-thought-report/` | 02 | R84 物理目录残留, branch 已删 |
| 2 | `.superpowers/sdd/` | 02 | R89 "Worktree 移除" 没回收主目录 |
| 3 | `.r61_backup_20260731_101630/` (1.7MB) + `.r61_backup_logs/` (2.6MB) | 02 | R61 backup 残 1.5 月 |
| 4 | `docs/superpowers/sdd-logs/round90-assessment-center/sdd/` (17 .py + __pycache__/ + 17 .py.tmp) | 02 | R90 残留 |
| 5 | `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` | 02 | R57 写, 至今未启用 (P0 必修) |
| 6 | `commit_msg_r56c3/r56d/r56e/r56g/r56h` + `.commit_msg_agents.md` + `.commit_msg.txt` | 02 | 6 个 commit message 临时文件 R56 残留 |
| 7 | `mimo.exe` (128MB) 根目录 | 02 | 不知何用 |
| 8 | `flutter_01.log` (5KB) 根目录 | 02 | 残留 |
| 9 | `todo.md` (723 bytes) 根目录 | 02 | 内容未知 |
| 10 | `chroniccare.iml` (859 bytes) | 02 | IntelliJ 项目文件, 应 .gitignore |
| 11 | `assets/legal/{privacy_policy, user_agreement, sensitive_data_consent}.md` 标"草稿" | 03/04/05 | 3 份全标 (P0 必改) |
| 12 | `ios/Podfile:1-7` 占位 | 04/06 | "本 Podfile 是占位 (Windows 平台无法跑 `pod install`)" |
| 13 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` 3 个 68 字节 | 04 | 1×1 透明 PNG, 启动 1×1 黑屏 0.5s |
| 14 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_*_screenshots/*.png` 24 张 67B 占位 | 04 | 必拒 |
| 15 | `fastlane/Appfile:21,23,25` apple_id / team_id / itc_team_id 3 处 TODO | 04 | 必拒 |
| 16 | `lib/main.dart:41,54` 顶层 mutable static | 01/06 | 改 `late final` 3 行 |
| 17 | `analysis_options.yaml` 16 守门员在 CI 但 0 GitHub workflow | 02 | 手动跑 |
| 18 | AGENTS.md 列 16 守门员, 实际 17 个 (漏列 `check_16kb_alignment.py`) | 02 | 文档不接 |

### 业务暂停 vs 文档矛盾 (P0 必查)

| # | 业务 | 文档描述 | 实际状态 |
|---|------|----------|---------|
| 1 | 失联通知 | README "自动 SMS 通知紧急联系人" | FeatureFlag 关 + SMS mock + 启动守卫 |
| 2 | IAP 8 元买断 | user_agreement §3 | FeatureFlag 关 + buyLifetime release 返 false |
| 3 | 5 厂商 push | 文档 (R70 引入) | 0 接入, 国产 ROM 推送送达率 < 70% |
| 4 | PHQ-9 / GAD-7 | 全部量表可用 | en/zh_Hant flag 默认关闭, 题目看中文 |
| 5 | BootReceiver | 已实现 | 0 实现, 靠 flutter_local_notifications 兜底 |
| 6 | 树洞撤回 | vent 撤回 3 选 1 dialog | 已实现, 但 PIPL §47 物理删需确认 |

---

## 6 视角核心发现 (一句话)

1. **emilkowalski**: 项目设计水位 7.5/10, token 化顶级但执行分裂 (158 处 TextStyle 残留 + 162 处 EdgeInsets 残留), 5 个 P0 半成品 (CBT wizard / FAB stub / chart TODO / treatment placeholder / 设置页架构) 上架前必修。
2. **superpowers-en**: 工程水位 8.0/10, SDD 闭环 (8 sub-spec 走 spec→plan→task brief→report→review→fix→merge→ledger 全流程), 16 守门员覆盖, 5 P0 bug 漏测 (AliyunSms / vent contentText / 硬编码中文 / EmailService / 跨 round regression)。
3. **superpowers-zh**: 工程 8.0 / 国内合规 3.5 / 资质 1.0 / 中文规范 7.5 / Git 6.0, **36 P0 上架 blocker** (估总 3-6 月, ¥45-90k 法务), 业务暂停 3 处触发 PIPL §17 告知不准确 + Apple 2.1/4.3 Spam 三重风险。
4. **AppStore**: 上架就绪度 6.0/10, 9 平台配置已修, **14 P0 阻塞** (3 法务 + 域名 + 截图 + IAP 真接 + AliyunSms 真接 + Podfile + Team ID + Dark Icon + TestFlight + NMPA 备案), 短期建议推迟到 v0.32/v1.0。
5. **GooglePlay**: 上架就绪度 38%, **16 P0 红线**, 最大死结是失联通知业务上线后**无效** (5 厂商 push SDK 0 接, 国产 ROM 推送率 < 70%), 可上 8 月底 v0.30.0 基础版 (失联暂停 + IAP 关 + 国产 UX 适配), v1.0 完整版需 2-3 月。
6. **flutter-spec**: 总合规率 84% (120/143 项), 6 P0 阻断 (签名 / Podfile / SMS 守卫 / PIPL / PHQ i18n / web 端) + 19 P1 警告 + 25 P2/P3 建议, 架构整体优秀, 核心问题是**业务半成品 + 3 个 god page + silent catch 11+ 处**。

---

## 修复路线 (按 P0 → P3 排, 跨 6 视角合并去重)

### 阶段 1 (0-1 周, S 难度, 立即可做)

1. [P0] **Android release 签名切换** (flutter-spec B.1) — 1-2h
2. [P0] **iOS Podfile 真生成** (Mac 跑 `pod install`) — 0.5d
3. [P0] **iOS DEVELOPMENT_TEAM 填** — 1h
4. [P0] **iOS fastlane/Appfile 4 ID 填** — 1h
5. [P0] **iOS LaunchImage.png 3 个占位删** — 5min
6. [P0] **iOS description.txt 改文案** (删"会发短信") — 0.5d
7. [P0] **iOS iCloud Backup 排除** (kCFURLIsExcludedFromBackupKey) — 0.5d
8. [P0] **域名 + 邮箱注册** — 1-2d
9. [P0] **启用 `aliyun_sms_provider_round57_test.dart.disabled`** — 1h
10. [P0] **vent 旧 contentText 列 DROP** (schemaVersion 18→19) — 1-2d
11. [P0] **CBT wizard 5/7 栏 save 修复** — 2-3d
12. [P0] **homeFabHotline / homeFabTop 真功能** — 3-5d
13. [P0] **assessment_center 顶部 mini 趋势图** — 3-5d
14. [P0] **treatment_placeholder 真页面** — 2-3d
15. [P0] **`assessment_center_page:1` 硬编码中文 → l10n** — 5min
16. [P0] **6 份文档 "App" 混用修** — 0.5d
17. [P0] **AGENTS.md 补 17 守门员列表** — 0.5d
18. [P0] **`.worktrees/feat-cbt-thought-report/` 物理清理 + worktree prune** — 0.1d
19. [P0] **`.r61_backup_20260731_101630/` 物理清理** — 0.1d
20. [P0] **`mimo.exe` / `flutter_01.log` / `todo.md` / `chroniccare.iml` 清理** — 0.1d

**20 项 S 难度, 1 周内可清**。完成后上架就绪度: Android 38% → 65% / iOS 6.0 → 7.0 / 国内合规 3.5 → 5.0。

### 阶段 2 (1-2 周, M 难度)

21-40. (略, 20 项 M 难度, 包括: 设置页 4 group 重构 / 主页信息架构重排 / 主页 hero 修 / 紧急联系人 3 步流程 / 数据导出 3 步流程 / bootReceiver 简化 / 启动加 `_bootstrapHealthCheck` 步骤 7 / safety_watch 加 unit test / 抽 `AudioController` 抽象 / 14 文件 45 处硬编码中文 → l10n / `check_strings_hardcoded.py` 规则加严 / 3 处 `catch (_)` 改 `swallowError` / 11+ 处 catch (_) 静默吞错 / `app_router.dart` redirect 嵌套 startsWith 守卫 / assessment_dao._rowToEntry PII 修 / 9 个 600+ 行 god page 部分拆 / iOS 截图 33 张 / iOS Dark Mode App Icon / Apple 4 表单 / Google Play 4 表单 / DEPLOYMENT 阶段 5/6 补全 / DEPLOYMENT 阶段 7.5 红色 banner)

**完成后上架就绪度**: Android 65% → 80% / iOS 7.0 → 8.0 / 国内合规 5.0 → 6.5。

### 阶段 3 (1-2 月, L 难度, 部分需法务 / 外部)

41-60. (略, 20 项 L 难度, 包括: 3 份法律 md 律师过审 / AliyunSms 真接 / EmailService 真接 / IAP 真接 / TestFlight 跑 1 周期 / `app_router.dart` redirect cache 改 Notifier / 5 厂商 push SDK 接入 / 域名 HTTPS 部署 / 隐私 / 删除 URL / 邮箱注册 + md 替换 / GitHub 仓库创建 / NMPA "非医疗器械" 声明 / HIPAA / GDPR 律师过审 / Data Safety Form 提交 / Apple App Privacy 提交 / Android keystore + Play App Signing / iOS 签名 + Apple Team ID / PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54 全部条文合规 / 文网文 / 互联网药品信息服务资格 / 算法备案)

**完成后上架就绪度**: Android 80% → 92% / iOS 8.0 → 9.0 / 国内合规 6.5 → 8.5。

### 阶段 4 (2-3 月, XL 难度, 需法务 + 厂商审核)

61-80. (略, 20 项 XL 难度, 包括: PHQ-9 / GAD-7 16 题 i18n 真接 / 软件著作权登记 / ICP 备案 / 8 量表题目全文 v1.0 翻译 / 集成测试 1 → 3-5 / 18+ service sub-service 测试 / coverage 阈值 / CI 4 job / 第三方 SDK DPA 协议 / 鸿蒙 / HarmonyOS NEXT 适配 / 5 厂商 push 送达率回执监控 / 8 元买断平台一致性 / 未成年人 14-18 周岁验证 / 失联检测算法透明性 / 欧盟 GDPR DPO 任命 / CCPA / CPRA 评估 / 多设备同步策略 / 决策记录跨 R70+ 整理)

**完成后**: 全平台 v1.0 上架就绪。

---

## 顶层架构 vs 底层建议拆分

### 顶层架构 (高内聚低耦合)

**结论**: **不需要重设顶层架构**。4 层 + 5 子层 umbrella 已成, 当前问题是「拆 facade / 收尾 god page / 修业务闭环」,不是换架构。

#### 建议 1: 拆 3 个 facade (估时 2-3 月, R92-R94 可做)

| Facade | 现状 | 拆法 | 价值 |
|--------|------|------|------|
| `notification_service.dart` (450 行) | facade + 6 sub | 拆 1 层 orchestrator + 6 sub + provider 化 | sub 数量超 facade 边界 |
| `safety_watch_service.dart` (388-457 行) | facade + 3 sub | 续拆 `safety_detector` + `safety_alert_builder` + `safety_alert_dispatcher` + facade | 失联检测 + 通知 + 升级 3 职责混 |
| `data_export_service.dart` (110 行 + 4 sub 800 行) | facade + 4 sub | facade 删, 4 sub 直接 provider 暴露 | facade 价值低 |

#### 建议 2: 拆 3 个 600+ 行 god page (估时 2-4 月, R95-R98 可做)

| 文件 | 行数 | 拆法 |
|------|------|------|
| `assessment_page.dart` | 436 | `pages/assessment/{quiz,result,history,crisis_dialog}/` |
| `medication_calendar_page.dart` | 642 | `pages/medication/calendar/{heatmap_grid,day_detail,refill_card}/` |
| `data_management_section.dart` | 606 | `pages/settings/data/{export,backup,destroy,reports}/` |

#### 建议 3: 未来 v1.0+ 评估 5 个可拆 package (当前不建议)

- `chroniccare_design_tokens`
- `chroniccare_i18n`
- `chroniccare_assessment`
- `chroniccare_safety`
- `chroniccare_audio`

**当前不建议拆**: 1 应用内 feature cross-import 仍频繁, 拆 package 增 monorepo 复杂度, 团队规模不需要。

### 底层 (逐行排查, 跨 6 视角合并去重)

#### B. 业务层 (50+ P1, 关键 15 项)

- 14 文件 45 处硬编码中文 → 走 l10n key
- 3 处 `} catch (_) {` 改 `swallowError` 集中器
- 11+ 处 `catch (_) { ... }` 静默吞错 → swallowError
- `assessment_dao._rowToEntry` 解析失败返 rawNote PII 泄露
- `db_key_service.dart` `Random.secure()` 改 `pointycastle.SecureRandom`
- audit log 明文存 SharedPreferences → 加密 + 自动过期
- `home_page.dart` build 入口 `final now = DateTime.now();` 1 次
- `crossedMidnightSince` 用 `DateTime` 仍 DST 边界, 改 `tz.local`
- `legalConsentWithdrawnProvider` 伪 stream → Notifier
- `ventSealedProvider` / `ventSealedAtProvider` 同样伪 stream → Notifier
- vent 跟 mood 加密 key 独立 (拆 `EncryptionService` 3 key)
- vent audio **不导出文件** (跨设备路径失效) → 限制定文案
- `consent_gate.dart` 撤回 fallback body 硬编中文 → i18n
- `kPubspecVersion` 手动同步 → `package_info_plus` 自动读
- email_preview.dart 整个文件残留 → 删 / 标 deprecated

#### C. 工程层 (20+ P1, 关键 10 项)

- 启动加 `_bootstrapHealthCheck` 步骤 7
- `safety_watch_service` 失联检测窗口加 unit test (DST/跨年/24h)
- 抽 `AudioController` 抽象, vent + mood 4 widget 共享
- `check_strings_hardcoded.py` 规则加严
- 拆 `notification_service.dart` ≥ 2 层 facade
- `.github/workflows/ci.yml` (flutter test + analyze + 16 guards)
- 11+ 处 catch (_) 静默吞错 → swallowError
- 3 个 600+ 行 god page 拆
- 集成测试 1 → 3-5 个
- 18+ service 子类 sub-service 测试

#### D. UI / UX 层 (30+ P1, 关键 15 项)

- 主页 hero illustration 140dp 视觉几乎 0 → 100dp + 渐变 alpha 提到 0.15+
- 主页 8 widget 堆叠 → primary action 居中, secondary 折叠
- 紧急联系人 5 步 → 3 步
- 数据导出 5 步 → 3 步
- quick mood carousel 1 tap 0 反馈 → 加 confirm / snackbar
- medication_calendar 30 天热力图 0 tap 详情
- 通知状态卡 17 步纯文字 → 加截图 + 链接
- vent 长按/swipe 删除 → 加 1 次性 tooltip
- 主页 3 icon button 0 tooltip
- 158 处 TextStyle + 162 处 EdgeInsets 残留 (40% magic) → 集中器化
- 50+ `Duration(milliseconds:)` + 50+ `Curves.easeXxx` 残留 (~30%) → AppMotion token
- mood_dialog 25 行薄壳纯转发 → 直接是 MoodRecorderPage
- refill 4 StatCard → 2x2 grid
- 趋势页 4 StatCard 改 narrative
- legal_page toggle 加 chip 标识撤回时间

---

## 关键决策点 (3 个跨 6 视角共识)

### 决策 1: **IAP 业务真接 vs 删文案 vs 改定位** (3 选 1)

| 选项 | 估时 | 影响 |
|------|------|------|
| A. IAP 真接 (8 元买断 → App Store Connect 创建 productId + Restore 按钮 + sandbox tester) | L (1-2w) | 跟 user_agreement §3 一致, 但 Apple 30% 抽成 |
| B. 删 user_agreement §3 "8 元买断" 描述, 完全免费 | S (0.5d) | 短期最快, 但商业不可持续 |
| C. 改定位 (精神心理公益 / 临床辅助), 申请 Apple 减免 30% 抽成 | XL (1-2 月) | 长期最优, 但需 Apple 申请 + 法务 |

**短期建议**: B (1 周内), 同步规划 C (v1.0+)。A 投入大, 商业回报不明。

### 决策 2: **失联通知真接 vs APNs 替代 vs 改 App 内通知** (3 选 1)

| 选项 | 估时 | 影响 |
|------|------|------|
| A. 阿里云 SMS 真接 (HMAC-SHA1 + POST dysmsapi.aliyuncs.com) | XL (1-2 月法务审核) | 跟 README 一致, 但送达率受国产 ROM 限制 |
| B. APNs 替代 (iOS) + FCM (Android) + 5 厂商 push | XL (1-2 月) | 送达率高, 但 5 厂商 push 1-2 月审核 |
| C. 改 App 内通知 + 静默 (不通知家人) | M (1w) | 跟 README 矛盾, 但 PIPL §23 风险最低 |

**短期建议**: A + B 并行 (1-2 月), 业务上 release 时 SMS 走 R55+ 真接, push 走厂商审核。C 是 fallback, 不建议。

### 决策 3: **Mac + Apple Developer $99 + 设计师** 3 件必备 (iOS 上架前置)

iOS 上架必须:
- Mac (不能 Windows / Linux 跑 `pod install` / `xcodebuild`)
- Apple Developer Program $99/年 (Team ID + 签名 + TestFlight)
- 设计师 (33 张截图 + AppIcon 1024 + Dark Mode App Icon 4 套 + LaunchScreen 品牌化)

**短期建议**: v0.30.x 主战 Google Play + Android, iOS 推迟到 v0.32/v1.0 (法务 + IAP + 阿里云 SMS 三件外部依赖完备后)。

---

## 风险评估 (跨 6 视角)

| 风险 | 等级 | 视角 | 说明 |
|------|------|------|------|
| **release 签名未配** | 🔴 P0 | 06 | 上 store 必拒 |
| **iOS Podfile.lock 缺失** | 🔴 P0 | 04/06 | macOS 必跑 `pod install` |
| **PHQ-9 / GAD-7 16 题 i18n 留 v1.0** | 🔴 P0 | 03/06 | en/zh_Hant 医疗法律责任 |
| **AliyunSmsProvider send() throw StateError** | 🔴 P0 | 02/03/04/05/06 | release 失联通知 100% 失败 |
| **EmailService send() 返 false** | 🔴 P0 | 02/03/04/05/06 | 同上 |
| **PHQ-9 question 9 (自杀念头) 危机干预 i18n 硬编中文** | 🔴 P0 | 06 | 法律责任 |
| **God page 3 个 600+ 行** | 🟠 P1 | 01/02/06 | 维护成本高 |
| **集成测试 1 个** | 🟠 P1 | 02/06 | 关键 flow 风险 |
| **Sub-service 测试 0 覆盖** | 🟠 P1 | 02/06 | refactor 安全网不足 |
| **`catch (_) { ... }` 7+ 处** | 🟠 P1 | 02/06 | silent catch 风险 |
| **`Random.secure()` 密码学强度** | 🟡 P2 | 06 | 当前平台 SDK 兜底, v1.0 必改 |
| **drift `@References` 缺失** | 🟠 P1 | 06 | 应用层维护 FK 风险 |
| **`assessment_dao._rowToEntry` 解析失败 PII 暴露** | 🟠 P1 | 06 | 直接返 rawNote |
| **audit log 明文** | 🟠 P1 | 06 | GDPR/PIPL §47 删除权 |
| **CI 缺 coverage + release publish** | 🟠 P1 | 06 | DevOps 不足 |
| **Web 端阻断未 fail-fast** | 🟠 P1 | 06 | runtime crash 难发现 |

---

## 总结

- **总合规率 / 工程水位**: flutter-spec 84% / superpowers-en 8.0/10 / emil 7.5/10
- **上架就绪度**: Google Play 38% / App Store 6.0/10 / 国内合规 3.5/10
- **代码 + 架构**: 4 层 + 5 子层 umbrella + 16 守门员 + 1617 tests, 已是 v0.30.0 状态
- **核心问题**:
  1. **业务半成品**: SMS / Email / IAP / NSESSS 量表 / BootReceiver 等都是 R55+ 真接 TODO
  2. **签名 / Podfile.lock / key.properties 缺失**: 上 store 前必改
  3. **PHQ-9 / GAD-7 16 题 i18n 留 v1.0**: 医疗法律责任
  4. **God page 3 个 600+ 行 + god service 2 个 400+ 行**: v1.0 必拆
  5. **集成测试 + sub-service 测试 + coverage 阈值**: refactor 安全网不足
  6. **silent catch 11+ 处**: R17 集中器模式继续迁移
- **亮点**:
  - 8 守门员脚本 + 17 个 Python 守门员, 机械感强, 已成
  - PIPL §13 留痕 + §14 撤回 + §17 同意记录 + §47 删除权 + §6 最小化 全链路落地
  - Apple 2024 强制 ITSAppUsesNonExemptEncryption / PrivacyInfo.xcprivacy / UIBackgroundModes / BGTaskScheduler 全部就绪
  - Google Play 16KB page size + 64-bit ABI + minSdk 24 + targetSdk 36 全部就绪
  - 主入口 `runZonedGuarded` + `LastErrorCapture` + `LastStartupErrorBanner` 完整错误兜底
  - 18 个 Drift migration step + 5 个索引 (R7-R91 累计)
  - 7 类路由 transition helper + 3 sub-service 拆 + 30+ (R57/R65/R67/R77)
  - Riverpod 3.x 用法规范 (50+ autoDispose + 6 Notifier)

---

**报告生成时间**: 2026-08-06
**审计员**: 6 视角 subagent 并发审计 + 1 总报告整合
**审计范围**: `lib/` (341 dart) + `test/` (205 dart, 27142 行) + `pubspec.yaml` + `analysis_options.yaml` + `android/` + `ios/` + `scripts/` + `docs/`
**审计方式**: 静态只读, 未跑 `flutter analyze` / `flutter test` / `flutter build`
**下次审计建议**: R95 (R91 后 4 round) / v0.31 (GoRouter 15 / Flutter 4.0 升版本前)

---

## 附录: 6 份独立报告索引

| 视角 | 文件 | 大小 | 水位 |
|------|------|------|------|
| 01 emilkowalski | `01-emilkowalski-design-report.md` | 45.9 KB | 7.5/10 |
| 02 superpowers-en | `02-superpowers-en-report.md` | 76.7 KB | 8.0/10 |
| 03 superpowers-zh | `03-superpowers-zh-report.md` | 73.9 KB | 工程 8.0 / 合规 3.5 |
| 04 AppStore | `04-appstore-ios-report.md` | 61.4 KB | 上架 6.0/10 |
| 05 GooglePlay | `05-googleplay-android-report.md` | 55.1 KB | 上架 38% |
| 06 flutter-spec | `06-flutter-spec-report.md` | 72.8 KB | 84% 合规 |
| **合计** | 6 份 | **385.8 KB** | — |
