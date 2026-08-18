# ChronicCare v0.30.0+85 — 9 视角总报告 (2026-08-10 cleanup)

> **汇总审计员**：MiniMax M3（顶层架构师视角） · **基线**：v0.30.0+85 / 395 dart / 2019 tests / 0 analyzer error · **守门员**：19 (17 python + 1 dart + 1 coverage) · **FeatureFlag**：8 · **方法**：Read 9 份 subagent + AGENTS.md + pubspec.yaml，**不跑** `flutter analyze` / `flutter test` · **上一轮 R105 基线**：emil 9.0 / spen 9.5 / spzh 7.0 / flutter-spec 88% / appstore 6.0 / googleplay 40%

---

## 一、6+2+1 视角评分总览

| # | 视角 | 评分 | vs R105 | 主要扣分 |
|---|------|------|---------|----------|
| 1 | **emil** (设计/UI/动效) | **9.0/10** | 持平 | R95-R105 引入 28 处新违规：主页 8 层 stagger / `AppMotion.X` 3 处 / AnimatedSwitcher 3 处 / 11 处 `Color(0xFF…)` / token 化 60% 覆盖（漏 `Icon(size:)` 30+） |
| 2 | **spen** (TDD/SDD) | **9.0/10** | **-0.5** | N1 `_save()` `notes` / N4-N6 死代码 3 处 / 2 守门员 FAIL（orphan 42 + zh_hant 16）/ daily_tracking 7 widget DRY 退化 |
| 3 | **spzh** (i18n/合规) | **工程 9.0 + 合规 4.5 = 7.0/10** | 持平 | R105 Z1-Z9 4 项残留 / R104 A11 iCloud Backup 0 / A12 Dynamic Type 0 / 4 项上架 blocker 卡外部依赖 |
| 4 | **flutter-spec v3.1** | **92%** | **+4%** | ci.yml 不跑 `check_coverage.py` / 无 a11y 守门员 / 集成测试 0 / `pubspec.yaml` SDK 太宽 / `assets/brand/_archive/` 30+ MB |
| 5 | **appstore** (Apple) | **4.5/10** | **-1.5** | 9 项 P0 阻断：PrivacyInfo 未注册 Xcode / iCloud Backup 0 / 通知 body PII 锁屏泄漏 / LaunchImage+AppIcon 占位 / 域名未注册 / review_information 缺 / `UIBackgroundModes audio` 缺 / 截图 0 张 |
| 6 | **googleplay** | **55%** | **+15%** | 6 项 P0：截图 67B 假图 / feature_graphic 67B / icon 1443B / 缺 keystore / Data Safety 0% / Health Apps 0% |
| 7 | **apple-health** (HealthKit) | **A:3 / B:6.5 / C:8** | N/A | 0 包 / 0 entitlement / 0 Info.plist / 0 UI 入口 / en-US description:27 "hypertension, diabetes" = Apple 5.1.3 抽审风险 |
| 8 | **architecture** | **8.2/10** | (基线) | 4 层 + 19 守门员成熟，**主要债务 = presentation 15 god class（~9600 行 / 1300KB / 占 lib/ ~40%）** |
| 9 | **bottom-up-bugs** (底层) | **46 项** (4 P0 + 12 P1 + 16 P2 + 14 P3, 去重 38) | (基线) | 4 P0 阻塞：iCloud Backup 0 / `canScheduleExactAlarms()` TODO / SMS+Email 真接 / vent_detail dispose 同步 |

**加权综合 ≈ 8.0/10**：项目处于"业务闭环 + 清理收尾"阶段。

---

## 二、用户 5 项核心结论

### 2.1 ✅ 外部链接（运行时 + 注释 + 文档 + 上架物料）

| 层 | 状态 | 详情 |
|---|---|---|
| **运行时代码 `lib/`** | ✅ **0 实际外链** | `grep "https\?://" lib/` 仅命中注释。`sms_service.dart:99,102,181` 注释提 `dysmsapi.aliyuncs.com`（说明性），实际 `send()` 走 mock（`aliyunSmsEnabled=false` 守门）；`chinese_holidays.dart:17` 注释提 `holidayapi.com` 解释"为何不接网络 API"（数据 hardcode 2024-2026） |
| **注释 / doc** | ⚠️ 3 处说明性 | 阿里云 SMS + holidayapi（等付费启动真接时启用） |
| **法务文档 `assets/legal/*.md`** | ✅ **0 外链** | 4 份 md（user_agreement / privacy_policy / sensitive_data_consent / medical_disclaimer）PIPL §13/§14/§17/§23/§28/§47 全覆盖 |
| **上架物料 `fastlane/metadata/**`** | 🔴 **12 个 URL 不可达** | 6 个 privacy_url.txt + support_url.txt（iOS 3 locale + Android 2 locale） + 4 截图占位 + 2 feature_graphic 全指向 **未注册** chroniccare.app 域名（Apple 5.1.1 + Google Play 拒因） |
| **邮箱** | 🔴 2 邮箱未注册 | `privacy@chroniccare.app` + `support@chroniccare.app`（R95 task 41） |
| **`mailto:` / `tel:`** | ✅ 1 处 tel: | R97-P1-11 `crisis_hotline_page.dart:233-252` `url_launcher` tel: 一键拨打 |

**结论**：**运行时代码 + 法务文档干净**（0 外链），**上架物料层未清理**（域名 + 邮箱未注册 + 12 个 URL 不可达）。R100 P0#14 已将 9 处占位改描述性措辞，但**实际可点击 URL 仍 12 个不可达**——上架前必修。

### 2.2 🔴 上架 / 架构 / 重构 / 半成品 4 大类

**上架（32 项 = 9 P0 + 14 P1 + 9 P2）**：(1) 域名 + 邮箱未注册（4 视角共识）；(2) iOS 截图 0 + Android 67B 假图 + feature_graphic 67B + icon 1443B；(3) `PrivacyInfo.xcprivacy` 未注册 Xcode；(4) iCloud Backup 0 排除（PIPL 风险，3 视角共识）；(5) 通知 body 药名 PII 锁屏泄漏（4 视角共识）；(6) vent audio 启用但 `UIBackgroundModes audio` 缺；(7) Data Safety Form + Health Apps Questionnaire 0% 未提交；(8) en-US description 5.1.3 抽审风险；(9) Dynamic Type 0 适配（28 处 fontSize 硬编码）

**架构（15 god class / ~9600 行 / 占 lib/ 40%）**：main.dart 459L + home_page_state 597L + medication_page 540L + vent_compose 495L + mood_audio_recorder 530L + notification_service 426L + setup_page_state 504L + app_database 494L + 7 daily_tracking widget 各 10-12KB + 4 个其他 15-20KB

**重构（6 类）**：(1) feature-first（中期 1-2 周）；(2) audio lifecycle mixin 抽 `audio_lifecycle.dart` 去重 ~150 行；(3) daily_tracking 7 widget 抽公共 helper；(4) medication `_SlotEntry` + `_ScheduleEntry` + summary 3 处重复；(5) `_dateOnly` 5 + `DateTime(y,m,d)` 4 → `isSameCalendarDay` / `calendarDaysBetween`；(6) `scale_registry` 统一 `_scaleName` 残缺映射

**半成品（8 项关键）**：

| # | 位置 | 阻塞 | 工时 |
|---|------|------|------|
| 1 | `notification_service.dart:313-325` `canScheduleExactAlarms()` | Android 12+ 静默降级 inexact（**5 视角共识**） | 0.5 day |
| 2 | `sms_service.dart` `AliyunSmsProvider.send()` + `email_service.dart` 0 caller | 法务 1-2 月 + 阿里云 AccessKey + SendGrid API key | 外部依赖 |
| 3 | `scale_translations.dart` PHQ-9/GAD-7 16 题 i18n | 法务临床审核 4-6 周 + 48 翻译（**3 视角共识**） | 4-6 周 |
| 4 | `scale_registry.dart` NSESSS/CRDPSS | v0.31+ 决定 | 1-2 day |
| 5 | `BootReceiver.kt` WorkManager + `feature_flags.dart ventAudio=true` vent audio export/import 闭环 | 等 R28 + 业务 | 1-2 day |
| 6 | `mood_detail_page` / `mood_factor_analysis` / `mood_reminder_notifier` 3 处死代码 | UI 入口缺 | 接线 or 删 |
| 7 | `_save()` `notes` 字段未持久化 + `colorIndex: 0` TODO | R105 N1 部分修 | 0.5 day |
| 8 | `medication_calendar_page.dart:202-221` `_onAddLogStub` + `legal_page` vent 撤回封存 UI 隐藏数据没真删 + `store_kit_service.dart` IAP 8 元买断 | 各自业务上线 | 0.5-1 day |

### 2.3 🏗️ 顶层架构审视（高内聚低耦合）

**当前健康度 8.2/10**：4 层 + core umbrella 边界严格（19 守门员），domain 0 Flutter 0 Drift 实证，16 abstract repo + 16 impl 接口稳定，cross_feature 0 violation。**主要债务 = presentation 层 15 god class**。

**4 个架构选项**：

| 选项 | 方案 | 工时 | 风险 | 推荐 |
|---|---|---|---|---|
| **1. feature-first** | `lib/features/{feature}/{domain,data,presentation}/` | 1-2 周 | 🟡 中 | ⭐⭐⭐⭐⭐ **中期推荐** |
| 2. Clean Architecture | 加 `interface_adapters/` + `frameworks/` | 3-4 周 | 🟠 高 | ⭐⭐ 过度工程 |
| 3. Modular / GetIt | 替代 Riverpod 注册 | 2-3 周 | 🟠 高 | ⭐⭐ 重复造轮子 |
| 4. pub workspace | 拆 `packages/chroniccare_vent` 等 | 1-2 月 | 🔴 很高 | ⭐ 等 50+ 文件/feature |

**推荐路径**：
- **短期（v0.31-0.32，~3 周）**：拆 P0+P1 6 大 god class，**不破坏 4 层架构**（main.dart / audio_lifecycle / home_page_state 3 controller / medication_slot_calculator / notification_service 委派合 namespace / daily_tracking helper）
- **中期（v0.33+，~1-2 月）**：feature-first 重构（选项 1）。约束：`features/{A}/` 不得 import `features/{B}/`（除 hub `home`/`settings`）；`core/` 仍被所有 features import
- **长期（v1.0+，~3-6 月）**：pub workspace 拆 vent / medication（选项 4）——触发条件：vent > 50 文件 + 团队分仓

### 2.4 🔍 底层逐行排查（46 项 bug 分布）

| 严重度 | 数量 | 主题 |
|---|---|---|
| 🔴 **P0 阻塞** | **4** | 资源泄漏 / 数据丢失 / 安全 |
| 🟠 **P1 警告** | **12** | 异步 race / 错误处理 / dispose 缺 cancel |
| 🟡 **P2 建议** | **16** | Magic number / 半成品 / i18n |
| 🟢 **P3 优化** | **14** | a11y / 文档 / token 化 |
| **总计** | **46** | 去重 ~38 独立修复点 |

**P0 必修 4 项**：
1. **P-05 iOS `isExcludedFromBackup` 全工程 0 标记**（3 视角共识）— SQLite + vent audio + SP 默认随 iCloud 备份 → 精神心理患者 PII 上 Apple iCloud。修：4 处 `getApplicationDocumentsDirectory()` 后 `setSkipBackupAttributeToItem(true)` + 1 iOS MethodChannel helper（**3h**）
2. **TD-01 `canScheduleExactAlarms()` TODO 12+ 月**（**5 视角共识**）— Android 12+ 撤回权限后 `zonedSchedule` 静默降级 inexact。修：rescheduleAll 入口调 `canScheduleExactNotifications()` + 引导系统设置（**0.5 day**）
3. **TD-02/03 SMS + Email 真接** — 外部依赖（法务 1-2 月 + 阿里云 AccessKey + SendGrid API key）
4. **L-14 `vent_detail_page._player.dispose()` 同步未 await** — 多次进出 page 累积 native handle。改 R79 模式 `unawaited(_asyncDispose())`（**0.5h**）

**Top 10 必修**（按 ROI）：① P-05 iCloud Backup 排除 ② TD-01 `canScheduleExactAlarms` ③ V-01 main.dart 裸 `developer.log` 加 `kReleaseMode` ④ V-05 锁屏 `VISIBILITY_SECRET` ⑤ A-02 vent_detail 删 1 行 guard ⑥ L-14 vent_detail R79 模式 ⑦ T-01 home `_nextReminderTime` DateTime race ⑧ N-09 weight_widgets 强类型 ⑨ M-02 + M-03 调色板 token 化 ⑩ N-07 export_import 接 `ExportSchemaService`

### 2.5 📚 文档更新建议（5 份）

**README.md** (1 day)：顶部 v0.30.0+85 → v0.31.0+86 / 截图+feature_graphic+icon 全部需重拍 / 5 步 setup 流程图加 2026-08-10 修订标记。**CHANGELOG.md** (2-3 day)：缺 R101-R107 entries / R100 段"两条同日同号"重复 → 区分 R100-1 / R100-2。**AGENTS.md** (1-2 day)：第 137 行 "1997 cases" → "2019 cases" / 守门员 17 → 19 / 加 v0.31 R106-R107 路线图。**VERSION_1.0_PLAN.md** (1-2 day)：加 R106 cleanup + 9 报告整合。**DEPLOYMENT.md** (1-2 day)：Apple/Android 截图脚本 / chroniccare.app 域名注册 + Cloudflare Pages / release keystore + Play App Signing / ci.yml 加 coverage gate。**附加**：写 `docs/spzh-trend-report.md` 跨 R95-R107 spzh 综合趋势（spzh P3 #40 提）。

---

## 三、跨视角问题合并去重

### 3.1 跨视角共识最强（≥3 视角）

| # | 问题 | 涉及视角数 | 优先级 |
|---|------|-----------|--------|
| 1 | `canScheduleExactAlarms()` TODO（`notification_service.dart:313-325`） | **5 视角**（spen + appstore + googleplay + bottom-up + architecture） | P0 |
| 2 | 锁屏 body 药名 PII（`strings.dart:103-119` `notifMedicationBody`） | **4 视角**（spzh + appstore + bottom-up + emil） | P0 |
| 3 | `home_page_state` 597L god class 拆 3 controller | **4 视角**（emil + spen + architecture + bottom-up） | P1 |
| 4 | chroniccare.app 域名未注册（4 法务文档 + 12 URL） | **4 视角**（spzh + appstore + googleplay + flutter-spec） | P0 |
| 5 | iCloud Backup 0 排除（`native.dart:18` + `encrypted_audio_storage.dart:99` + `swallow_log_sink.dart:54`） | **3 视角**（spzh + appstore + bottom-up） | P0 |
| 6 | 主页 8 层 stagger FadeIn 累加 0-280ms（`home_page_state.dart:334-430`）未 clamp | **3 视角**（emil + spzh + bottom-up） | P0 |
| 7 | `medication_pill_icon.dart:10-15,63,70` 6 个 `Color(0xFF…)` + 2 个 `Colors.white` | **3 视角**（emil + spen + bottom-up） | P1 |
| 8 | Dynamic Type 0 适配（28 处 `fontSize:` 硬编码） | **3 视角**（spzh + appstore + emil） | P1 |
| 9 | PHQ-9 / GAD-7 16 题 i18n TODO | **3 视角**（spen + spzh + bottom-up） | P1（v1.0） |
| 10 | `notification_service` 426L god class 拆 facade | **3 视角**（emil + spen + architecture） | P2 |
| 11 | `AliyunSmsProvider.send()` `throw UnimplementedError` | **3 视角**（spen + bottom-up + architecture） | P0（v1.0） |
| 12 | `EmailService` 0 caller dead code | **3 视角**（flutter-spec + bottom-up + architecture） | P0（v1.0） |
| 13 | `daily_tracking` 7 widget 各自 10-12KB god + 跨 widget 重复 helper | **2 视角**（spen + architecture） | P1 |
| 14 | `_save()` `notes` 字段未持久化 + `colorIndex: 0` TODO | **2 视角**（spen N1 + R101+ N15） | P1 |
| 15 | `mood_detail_page` / `mood_factor_analysis` / `mood_reminder_notifier` 3 处死代码 | **2 视角**（spen N4-N6 + spzh Z37） | P2 |
| 16 | `pubspec.yaml:71,76` `in_app_purchase` + `speech_to_text` 死依赖 | **2 视角**（spen + flutter-spec） | P2 |
| 17 | `Assets/brand/_archive/` 100+ PNG 30+ MB + `pubspec.yaml:8-9` SDK 范围太宽 + R95 sub-spec 5 token 化 60% 覆盖 + R100 段同日同号重复 | **各 2 视角** | P3 |

### 3.2 单视角独有问题（举例）
- **仅 emil**：`PressFeedback.curve` 漏 `Motion.curve` / `loading: Center(CircularProgressIndicator)` 散落 9+ 处
- **仅 spen**：71 处 `padLeft(2,'0')` 手写时间格式化 / `_dateOnly` 5 处私有
- **仅 spzh**：`care_copy.dart:33-57` 全部关怀文案硬编码 / `strings.dart` 类注释 4 项 v* 堆叠
- **仅 flutter-spec**：ci.yml 缺 coverage gate
- **仅 appstore**：Apple ASC Health Information Disclosure Questionnaire 6 问
- **仅 googleplay**：Data Safety Form 7 类×4 子项=28 子项 / Health Apps Questionnaire 4 大块
- **仅 apple-health**：3 选项决策（A 不接 / B 部分接 3-4 周 / C 全接 8-10 周）
- **仅 architecture**：4 架构选项对比 / 8 FeatureFlag 守门模式
- **仅 bottom-up**：18 模式 grep 命中统计（`DateTime.now()` 126 / `EdgeInsets.*` 100+ / `Color(0x…)` 30+ / `fontSize:` 30+ / `late` 45+ / `as Type` 30+ / `dynamic` 50+）

---

## 四、问题清单（按"修复优先级" P0 → P3 排序）

> Top 13 必看（完整 46 项见 `09-bottom-up-bugs.md` §5），按"修复优先级"合并去重 + 跨视角溯源。

| # | 文件:行 | 问题 | 难度 | 优先级 | 视角 | 修复建议 + 工时 |
|---|---------|------|------|--------|------|----------------|
| 1 | `strings.dart:103-119` `notifMedicationBody` | 锁屏 body 暴露药名 + 剂量 PII | 简单 | **P0** | 4 视角 | body 脱敏"点一下 = 打卡"。**1h** |
| 2 | `native.dart:17-19` + `encrypted_audio_storage.dart:99-104` + `swallow_log_sink.dart:54` | 4 处 `getApplicationDocumentsDirectory()` 全 0 标记 iCloud Backup → 精神心理 PII 上 Apple | 中 | **P0** | 3 视角 | 4 处后调 `setSkipBackupAttributeToItem(true)` + 1 iOS MethodChannel helper。**3h** |
| 3 | `project.pbxproj:223-232` | `PrivacyInfo.xcprivacy` 未注册到 Resources buildPhase → xcodebuild 不打包 | 简单 | **P0** | appstore | PBXFileReference + PBXBuildFile 2 处 edit。**15 min** |
| 4 | `LaunchImage.imageset/LaunchImage*.png` + `AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 3 个启动图 68B 空白 + AppIcon 10932B 占位 | 简单 | **P0** | appstore | 从 `assets/brand/app_icon_master.png` 生成 3 张真实图 + 复制 master 图。**1.5h** |
| 5 | `fastlane/metadata/{ios,android}/*/privacy_url.txt` + `support_url.txt` | chroniccare.app 域名未注册 → 12 URL 不可达 | 简单 | **P0** | 4 视角 | Cloudflare Registrar $15/yr + Pages 部署 4 HTML + ICP 备案 7-20d。**4h** |
| 6 | `fastlane/metadata/ios/review_information/` | 目录不存在（ASC 上传硬阻塞） | 简单 | **P0** | appstore | 创建 7 个 txt。**30 min** |
| 7 | `Info.plist:153-160` | R100 删 `UIBackgroundModes audio` + R104 vent audio 启用 → 声明 vs 实际矛盾 | 简单 | **P0** | appstore | 加回 `audio`。**5 min** |
| 8 | `fastlane/screenshots/**` (iOS 5 设备) + `android/*/phone_screenshots/` (4×2 locale) + 7"/10" 平板 | 0 张 PNG / 67 字节占位 | 中 | **P0** | appstore + googleplay | macOS 5 模拟器 × 3 locale × 5 屏 = 15 张 + Android emulator + Playwright 4 主流程 + 7"/10" 平板。**3-5 day** |
| 9 | `fastlane/metadata/android/*/{feature_graphic,icon}.png` + `android/key.properties` + `playstore_signing_key.jks` + Play Console Data Safety Form + Health Apps Questionnaire | 67B / 1443B 占位 + 缺 keystore + 0/7 类 + 0/4 块 | 简单-中 | **P0** | googleplay | 设计 1024×500 + 512×512 + 5 步 + Play App Signing + 手填 7 类×4 + 4 大块。**2-3 day** |
| 10 | `en-US/description.txt:27` + zh-Hans/zh-Hant/description.txt:32-35 | "hypertension, diabetes" → Apple 5.1.3 抽审风险 | 简单 | **P0** | apple-health | 改 1 行 "and other mental health conditions" + 危机电话首句。**2.5h** |
| 11 | `notification_service.dart:313-325` `canScheduleExactAlarms()` | Android 12+ 撤回后 zonedSchedule 静默降级 inexact | 简单 | **P0** | 5 视角 | rescheduleAll 入口调 `canScheduleExactNotifications()` + 引导。**0.5 day** |
| 12 | `main.dart:91,105` + `notification_service.dart:142-186` | 裸 `developer.log` release 仍输出 + `requestAlertPermission/Badge/Sound` 全 false | 简单 | **P0** | bottom-up + appstore | 加 `kReleaseMode` 守卫 + setup_page 加 `requestPermission()` + UI 引导。**1h** |
| 13 | `home_page_state.dart:334-430` | 8 层 FadeIn stagger 累加 0-280ms 未 clamp | 简单 | **P0** | 3 视角 | 8 处加 `.clamp(0, AppTokens.staggerCapMs)`。**0.5h** |
| 14-30 | P1-P2 警告 18 项 | `add_medication_page _save() notes` / `app_zh.arb 42 孤儿` / `influence_factor 36 因子` / `daily_tracking 7 widget god` / `medication_pill/mood_trend 12 Color` / `export_import 30+ as` / `loading/error 12+ 处散落` / `_SlotEntry DRY` / `71 padLeft` / `_dateOnly 5` / `care_copy 36 因子` / `assessment_comparison 趋势` / `main 459L 拆 bootstrap` / `home_page_state 597L 拆 3 controller` / `safety_watch 361L 拆 3` / `notification_service 426L 拆 facade` | 简单-中 | **P1-P2** | spen + emil + spzh + architecture + bottom-up | 详见各 subagent 报告 §3 / §2.1-2.11。**累计 1-4 week** |

**完整 P0/P1/P2/P3 全表（共 46 项）见 `09-bottom-up-bugs.md` §2.1-2.11**。

---

## 五、按"修复难度"分类

### 简单（1-4h，22 项）— token 化 / 硬编码 → ARB / 删 guard / 修 1 行
P-05 iCloud Backup / TD-01 canScheduleExactAlarms / V-01 V-05 / E-04 E-05 catch(_) → swallowError / L-14 vent_detail R79 / N-09 weight_widgets 强类型 / Z19 Z21 Z25 Z32 / T-01 home DateTime race / A-02 vent_detail 删 1 行 guard / M-15 scrimAlphaM3 / Z33 breakpointMedium=600 / Z23 strings.dart 注释 / stagger 8 处 / 锁屏 body 脱敏 / spen N1 _save() notes / appstore P0#1-5 #7-8 9 项 / googleplay P0#3 / apple-health AH-5 改 1 行 description

### 中（1-2 天，12 项）— god class 拆 / provider 重构 / FeatureFlag 翻转
M-02 M-03 调色板 token / L-01 mood_audio Timer / L-13 vent_compose AudioPlayer 验证 / Z28 loading/error 集中器 12+ 处 / spen N7 N11 N13 N16 / Z30 数字 TweenAnimationBuilder / Z34A daily_tracking_widgets 公共 helper / main.dart 488→80 / audio_lifecycle mixin 抽 vent+mood 共用

### 难（1-2 周，7 项）— 大架构重构 / 真实业务接入 / 上架物料
main.dart 488→80 拆 `bootstrap/`（1-2 week）/ home_page_state 拆 3 controller（1 week）/ safety_watch_service 拆 3 文件（1 week）/ notification_service 续拆 facade（3-5 day）/ medication_page 时间段算法抽 domain（1-2 day）/ app_database migration 表驱动（1 day）/ N-07 export_import 接 schema 校验（1 week）/ IAP 8 元买断真接 productId（8-12h）/ 上架物料：iOS 5 模拟器×3 locale×5 屏=15 张（3h+Mac）/ Android 4 主流程+7"/10" 平板=8-12 张（1.5 day）

### 极高（1-2 月，8 项）— 法务 / 临床 / NMPA / 5 厂商 SDK
**5 厂商 push SDK**（米/华/OPP/vivo/魅族）1-2 月审核（`fiveVendorPushEnabled`）/ **AliyunSms 真接** 法务 1-2 月 + 阿里云 AccessKey（`aliyunSmsEnabled`）/ **EmailService SendGrid 真接**（`emailServiceEnabled`）/ **PHQ-9/GAD-7 16 题 i18n** 法务临床审核 4-6 周 + 48 翻译（`phqGad7I18nEnabled`）/ **HealthKit 选项 B** Mac 必须 + 3-4 周 / **选项 C** Mac + 法务 + NMPA + 8-10 周 / **IAP 8 元买断** App Store Connect + 法务 1-2 月 / **NMPA 备案**（精神心理 App）1-2 月

---

## 六、按"层级"分类

**架构层（12 项）**：15 god class / audio state machine vent+mood 重复 / `medication_page` 时间段算法未进 domain / `notification_service` 13 个 1 行委派（architecture + spen）。

**底层（38 项去重）**：11+ `Color(0xFF…)` / 30+ `Icon(size:)` / 8+ `SizedBox` / 30+ `as Type` / 50+ `dynamic` / 4 P0 资源泄漏 / DateTime race 1 处 / 6 catch(_) 残 3 处（bottom-up + spen + emil）。

**i18n（18 项）**：36 因子名硬编 / 关怀文案硬编 / 趋势标签硬编 / 42 孤儿 ARB / 16 简繁 / PHQ-9 16 题 / `_save()` notes（spzh + spen）。

**合规（15 项）**：iCloud Backup 0 / 通知 body PII / 锁屏 safety 全文 / 域名+邮箱 / PrivacyInfo 未注册 / Data Safety + Health Apps 0% / PHQ-9 HIPAA 边界 / vent audio 隐式 INTERNET（spzh + appstore + googleplay + apple-health + bottom-up）。

**UI/UX（20 项）**：主页 8 层 stagger 累加 280ms / 11 处 loading/error 散落 / 10+ 处 SnackBar 散落 / Dynamic Type 0 适配 / a11y 5% 覆盖 / 4 档 emoji 缺 Semantics / 主页 IA 8 层累加视觉重量 800-1000px（emil + appstore + spzh + bottom-up）。

**上架（32 项 = 9 P0 + 14 P1 + 9 P2）**：iOS 0 截图 / Android 67B 假图 / iOS 截图+icon+launch 占位 / review_information 缺 / UIBackgroundModes audio 缺 / feature_graphic+icon 占位 / keystore 缺 / Data Safety + Health Apps 0%（appstore + googleplay + apple-health + flutter-spec + spzh）。

---

## 七、外部链接 / 半成品 / 8 FeatureFlag / 上架 blocker

### 7.1 外部链接汇总
详见 §2.1 — 运行时 0 / 注释 3 处说明性 / 法务 0 / 上架物料 12 不可达 / 邮箱 2 未注册 / tel: 1 处。

### 7.2 8 FeatureFlag 守门状态

| FeatureFlag | 默认 prod | 状态 | 真接条件 | UI 隐藏内容 |
|---|---|---|---|---|
| `iapEnabled` / `emergencyContactEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` / `aliyunSmsEnabled` / `emailServiceEnabled` / `fiveVendorPushEnabled` | false | 🟡 半成品 × 7 | 各自外部依赖（productId / SMS / Email / 5 厂商 SDK / 法务 / WorkManager） | 各自 UI 段（IAP 卡片 / 联系人 / 邮件 / 5 厂商引导） |
| `ventAudioEnabled` | **true** (R104) | ✅ 完整 | 已翻 | vent_compose + mood_recorder 录音 button |

**模式评价**：8 prod const + 8 nullable override + getter = `_currentXxx ?? _prodXxx`。`@visibleForTesting` setter 8 + `enableForTest()` + `resetForTest()` 还原，**28 test 已用**——是项目亮点。**风险**：6 个 prod const 全部 false，**没有 changelog 自动检测脚本**——建议加 `check_feature_flag_state.py`。

### 7.3 上架 Blocker 清单

**iOS App Store（30 项 = 9 P0 + 7 P1 + 9 P2 + 5 P3，~38h）**：P0 阻断 9 项 ~12.5h — `PrivacyInfo.xcprivacy` 未注册 Xcode / SQLite iCloud Backup 0 排除 / 通知 body PII 锁屏泄漏 / LaunchImage 68B 空白 / AppIcon 1024 占位 / 域名未注册 / `review_information/` 目录缺失 / `UIBackgroundModes audio` 缺 / 截图 0 张。P1 高概率打回 7 项：`NSPrivacyCollectedDataTypeSensitiveInfo` 缺 / `NSPrivacyAccessedAPICategoryActiveKeyboard` 防御性声明 / Dynamic Type 0 适配 / 装饰性 emoji 缺 `excludeSemantics` / `copyright.txt` 缺 © + 主体 / `keywords.txt` 7 词 / iPhone 16 Pro Max 6.9" 适配。

**Android Google Play（10 项 = 6 P0 + 4 P1，~5 day）**：P0 阻断 6 项 — 真实截图 4×2 locale + 7"/10" 平板 / feature_graphic 2 locale / icon 512×512 2 locale / release keystore + key.properties / Data Safety Form 28 子项 / Health Apps Questionnaire 4 块。P1 阻断 4 项：`fastlane/metadata/android/zh-TW/` / `values-zh-rTW/zh-rCN/strings.xml` / 7"/10" 平板截图 / `canScheduleExactAlarms()` 运行时检查。

**通用（4 项 ~4h）**：chroniccare.app 域名注册 + ICP 备案 7-20d / `pubspec.yaml` SDK 收紧 / ci.yml 加 coverage gate / `assets/brand/_archive/` 移 `.mavis-trash`。

---

## 八、架构改进建议（高内聚低耦合）

### 8.1 短期（v0.31-0.32，~3 周）— 维持 4 层 + 拆 god class

| God Class | 现状 → 目标 | ROI | 工时 |
|---|---|---|---|
| **main.dart (459L)** | 抽 `lib/main/boot_apps.dart` 含 4 占位 widget + MigrationPromptController；main.dart 只留 `main()` + `_bootstrap()` + 3 init helper | 🟢 极高 | 1 day |
| **vent_compose + mood_audio_recorder (2×500L)** | 抽 `lib/presentation/widgets/audio_lifecycle.dart` 含 `RecordingState` enum + `AsyncDispose` mixin；2 page 改用 mixin 去重 ~150 行 | 🟢 高 | 1-2 day |
| **notification_service (426L)** | 13 个 1 行委派合 `delegate` namespace；facade 主体留 6 method | 🟢 高 | 1 day |
| **home_page_state (597L)** | 抽 3 controller：`HomeDeepLinkHandler` (50L) / `HomeCareEngineDispatcher` (70L) / `HomeCelebrationController` (50L)；state class 保留 build + onCheckIn + snooze (~200L) | 🟠 中-高 | 2-3 day |
| **medication_page (540L)** | 抽 `domain/logic/medication_slot_calculator.dart` 含 `_TimeSlot` 纯函数；抽 `medication/widgets/medication_list_widgets.dart` | 🟠 中-高 | 1-2 day |
| **daily_tracking 7 widget god** | 抽 `daily_tracking_widgets.dart` 公共 helper | 🟢 高 | 2-3 day |

**累计**：P0 + P1 **12-15 天清 6 大 god class + 7 widget**。

### 8.2 中期（v0.33+，~1-2 月）— feature-first 重构（选项 1）

```
lib/
├── core/                          # 不变
├── features/
│   ├── check_in/ medication/ mood/ vent/ assessment/
│   │   ├── domain/  data/  presentation/
│   ├── safety/      (失联 + CareEngine + SMS)
│   ├── consent/     (PIPL §13/§14 + 法务文档)
│   └── home/        (主页 = 跨 feature coordinator)
└── shared/         # 跨 feature 复用
```

**约束**：`features/{A}/` 不得 import `features/{B}/`（除 hub `home`/`settings`）；`core/` 仍被所有 features import。**工时**：1-2 周（390+ 文件 move + import 重写）。**收益**：新 feature 边际成本 1-2 天 → 0.5-1 天。

### 8.3 长期（v1.0+，~3-6 月）— Workspace 拆分（选项 4）

**触发条件**：vent > 50 文件 + 团队分仓。**风险** 🔴 很高。**不推荐 v0.31-0.32 范围**。

---

## 九、文档更新建议

详见 §2.5 — README 1d / CHANGELOG 2-3d / AGENTS 1-2d / VERSION_1.0_PLAN 1-2d / DEPLOYMENT 1-2d / spzh-trend-report 1d / architecture-fixes 1-2d，**总 7-12 day**。

---

## 十、修复路线图（按 ROI 排序，3 阶段）

### Phase 1：1-2 周内（~5-7 工作日 / 1 sprint）— 上架前必做 + P0 必修
**目标**：**可提交 App Store / Google Play**。

1. iOS P0#1-9 阻断 9 项（PrivacyInfo / iCloud Backup / 通知 body 脱敏 / LaunchImage / AppIcon / 域名 / review_information / UIBackgroundModes / 截图）— **12.5h**
2. Android P0#1-6 阻断 6 项（截图 / feature_graphic / icon / keystore / Data Safety 28 子项 / Health Apps 4 块）— **4-5 day**
3. iCloud Backup P-05 + `canScheduleExactAlarms()` P-06 / TD-01 + vent_detail R79 L-14 + main.dart V-01 + 主页 8 层 stagger + 通知 body 脱敏 + `_save()` notes + apple-health 5.1.3 改 1 行 description — **1 day**
4. ci.yml 加 coverage gate + a11y 守门员脚本骨架 — **4h**

**Phase 1 累计**：~12-14 工作日 / **2-3 sprint**（含 2 个平台 P0 阻断）。

### Phase 2：1-2 月内（~3-4 周 / 2-3 sprint）— P1 警告 + god class 拆 + 真实业务接入
**目标**：**清 P1 警告 12 项 + 拆 6 大 god class + 真实业务接入**。

1. 42 孤儿 ARB + 16 简繁 + influence_factor 36 中文因子走 l10n — **3-4 day**
2. daily_tracking 7 widget 抽 `daily_tracking_widgets.dart` 公共 helper — **2-3 day**
3. medication_pill + mood_trend 调色板 token 化（dark mode 联动）— **0.5 day**
4. export_import_pipeline 30+ as 链接 `ExportSchemaService.validateXxx` 全链路 — **1 week**
5. main.dart 459L 拆 `bootstrap/` + home_page_state 597L 拆 3 controller + safety_watch_service 361L 拆 3 文件 — **3-4 week**
6. audio_lifecycle.dart mixin + notification_service 13 委派合 namespace + medication_page 时间段算法抽 `domain/logic/medication_slot_calculator.dart` — **3-5 day**
7. 71 处 `padLeft(2,'0')` 替换 + _dateOnly 5 + DateTime(y,m,d) 4 全替换 — **2 day**
8. IAP 8 元买断真接 productId — **8-12h**

**Phase 2 累计**：~5-6 周 / **2-3 sprint**。

### Phase 3：6 月+（v1.0）— 真实业务接入 + 临床 / 法务 / NMPA 备案

1-4. **5 厂商 push SDK** 接入（1-2 月审核）/ **AliyunSms 真接**（法务 1-2 月 + AccessKey）/ **EmailService SendGrid 真接** / **PHQ-9/GAD-7 16 题 i18n**（法务临床 4-6 周）— 累计 **6-9 月**
5-6. **HealthKit 选项 B**（mood + sleep + weight 同步，3-4 周+Mac）/ **选项 C**（medication 双向 + 后台 + Android HC，8-10 周+Mac+法务+NMPA）— **1-2 月**
7-9. **IAP 真接** / **8 FeatureFlag 翻 true** / **a11y 全量** + 新守门员 `check_a11y.py` — **1-2 周**
10-11. **feature-first 重构**（中期，1-2 周）/ **pub workspace 拆 vent / medication**（长期，3-6 月）— **4-8 月**

**Phase 3 累计**：~6 月+ / **业务闭环 + 上架稳态**。

---

## 附录：报告源（9 subagent 报告 + 本汇总）

| # | 视角 | 文件 | 字节 |
|---|------|------|------|
| 1 | emil | `01-emil.md` | 26.3KB |
| 2 | spen | `02-spen.md` | 28.5KB |
| 3 | spzh | `03-spzh.md` | 35.0KB |
| 4 | flutter-spec | `04-flutter-spec.md` | 21.0KB |
| 5 | appstore | `05-appstore.md` | 29.3KB |
| 6 | googleplay | `06-googleplay.md` | 36.5KB |
| 7 | apple-health | `07-apple-health.md` | 37.0KB |
| 8 | architecture | `08-architecture.md` | 23.0KB |
| 9 | bottom-up-bugs | `09-bottom-up-bugs.md` | 48.7KB |
| **本汇总** | **00-summary.md** | **(本文件)** | **~30KB** |

**不跑命令声明**：按 consolidation prompt 要求，本汇总**不跑** `flutter analyze` / `flutter test` / `flutter commit` / 任何 `check_*.py` 脚本，仅基于 9 份 subagent 报告 + AGENTS.md + pubspec.yaml 整合。

---

**报告生成**：2026-08-10 · **汇总审计员**：MiniMax M3（顶层架构师视角） · **关联**：9 份 subagent 报告 + AGENTS.md v0.30+85 + pubspec.yaml v0.30.0+85
