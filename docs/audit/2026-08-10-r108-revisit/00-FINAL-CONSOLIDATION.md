# R108 Revisit 最终整合 — 2026-08-10

> 9 视角 subagent 并行跑完的整合报告
> 9 份报告总和 404KB,本文件去重 + 标架构/底层 + 标修复难度 + 按优先级排序
> 9 份原始报告见 `lens/01-emil.md` ~ `lens/07-apple-health.md` + `08-architecture.md` + `09-bottom-up-bugs.md`

## 0. 元数据

- 整合时间: 2026-08-10
- 整合者: Mavis (主 agent)
- 整合源: 9 份 subagent 报告(已去重,跨视角共识 P0/P1 标 ⚠️⚠️⚠️)
- baseline: HEAD=`ac2be71 v0.30 round 100`, working tree=30+M 26D(R108 进行中)
- 跑得 subagent: emil / superpowers-en / superpowers-zh / appstore / googleplay / flutter-spec / apple-health / architecture / bottom-up
- 项目状态: `flutter analyze` 118 issue(45 error + 20 warning + 53 info),`flutter test` 124 fail + 1 skip + 1405 pass(R108 working tree,R108 完工后应恢复 R107 92% baseline)
- 清理:120 个旧报告归档到 `docs/audit-history/`(R107 cleanup 25 + 4 天历史 55 + 7 视角 17 + 旧 review 23)

---

## 1. 9 视角评分总览

| # | 视角 | 评分 | P0 | P1 | P2 | P3 | 视角定位 |
|---|---|---|---|---|---|---|---|
| 1 | emil(Emil Kowalski 设计工程) | 8.5 | 2 | 4 | 3 | - | 视觉/动效/触感 |
| 2 | superpowers-en(英文 superpowers) | 6.5 | 8 | 7 | 6 | 4 | 编程方法论/TDD/错误处理 |
| 3 | superpowers-zh(国内合规/PIPL) | 6.5 | 8 | 9 | 6 | 6 | PIPL/5 厂商 push/鸿蒙 |
| 4 | appstore(App Store iOS) | **3.5** | 8 | 7 | - | - | iOS 上架合规 |
| 5 | googleplay(Google Play Android) | 5.5 | 11 | 10 | - | - | Android 上架合规 |
| 6 | flutter-spec(Flutter 规范 v3.1) | 6.8 | 4 | 14 | 9 | 7 | 14 章 + 6 附录合规率 |
| 7 | apple-health(Apple Health 集成) | **3.0** | 4 | 6 | - | - | HealthKit/Health Connect |
| 8 | architecture(顶层架构) | 8.4 | 6 | 6 | 5 | 4 | 4 层架构/god class/SOLID |
| 9 | bottom-up(底层逐行) | 7.0 | 1 | 5 | 5 | 3 | 跨文件静态分析盲点 |
| **去重总计** | - | - | **~38 P0** | **~50 P1** | - | - | 跨 9 视角 |

**加权综合评分** = **6.2/10**(架构 8.4 + 设计 8.5 + 编程 6.5 + 规范 6.8 + 国内 6.5 + 底层 7.0 + iOS 3.5 + Android 5.5 + Health 3.0 加权平均,iOS/Android/Health 是上架硬伤,严重拉低综合分)

**R107 → R108 趋势**:
- R107 加权综合 8.0/10(R107 cleanup 报告)
- R108 加权综合 6.2/10(**临时倒退 1.8 分**)
- **倒退主因**:R108 进行中 working tree 引入 8 个回归 error + 上架"实物资产"未做(截图/LaunchImage/LaunchImage/Icon/域名/邮箱/keystore)
- **R108 完工后预期恢复 7.5-8.0/10**(修 8 个 P0 引入 error + R108 god class 收尾 6 项 + 上架实物资产落地 10-15 项)

---

## 2. P0 整合(去重后 ~38 项,按优先级排序)

> 排序逻辑:多视角共识(≥3 视角提及) > 上架硬阻塞 > 上架可改进 > 国内合规 > 架构 > 底层

### 优先级 1:上架硬阻塞(iOS / Android 实物资产未做 + review info TODO + 5.1.3 抽审)— 5 项

- ⚠️⚠️⚠️ **[P0-001]** iOS 截图 0 张 — `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/` 目录缺失
  - 修复难度: M | 工作量: 1-2d | 来源: appstore P0-001 + googleplay P0-001
  - 现状: Apple 强制要求 iPhone 6.5" + 6.7" 各 ≥ 3 张,fastlane `upload_to_app_store(skip_screenshots: false)` 0 文件 = build 卡住
  - 建议: 设计 6.5" + 6.7" + 12.9" iPad 三组截图,中英文各 5-7 张,先解决 iOS 模拟器真能跑(本机无 Mac,需 CI build 拿 simulator 截屏)

- ⚠️⚠️⚠️ **[P0-002]** Android 8 张截图 67B + feature_graphic 67B + Flutter 默认 icon
  - 修复难度: L | 工作量: 3-5d | 来源: googleplay P0-001/P0-002/P0-003 + emil P0-001
  - 现状: 8 张占位 + feature_graphic 67B + icon 是 Flutter 默认 logo
  - 建议: 设计师出 8 张真图(2K×2K)+ 1 张 feature_graphic(1024×500)+ 1 张 1024×1024 master icon

- ⚠️⚠️⚠️ **[P0-003]** iOS LaunchImage 3 个 68B 占位 PNG + AppIcon 1024x1024 10932B 偏小
  - 修复难度: M | 工作量: 1.5h + 设计师 0.5d | 来源: appstore P0-002 + googleplay P0-005 + emil 关联
  - 现状: LaunchImage 1×1 透明点 + AppIcon 1024×1024 10KB 偏小
  - 建议: 走 `UILaunchScreen` Info.plist key + 品牌色背景 + 居中 logo,设计师重做 1024×1024 master icon

- ⚠️⚠️⚠️ **[P0-004]** `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt` 4 文件含 TODO 占位
  - 修复难度: S | 工作量: 30min | 来源: appstore P0-004 + superpowers-zh P0-008
  - 现状: 4 文件 `TODO: 真实名字` / `TODO: 真实邮箱` / `TODO: +86 真实手机号`
  - 建议: 上 store 前 dev 填真实信息(域名注册后填 `reviewer@chroniccare.app`)

- ⚠️⚠️⚠️ **[P0-005]** en-US description 含 4 类精神疾病名 (depression / anxiety / bipolar / PTSD / ADHD) → Apple 5.1.3 抽审最长延期 2 周
  - 修复难度: M | 工作量: 1-2d | 来源: appstore P0-006 + googleplay P0-009
  - 现状: PHQ-9 / GAD-7 描述"self-reflection tools" 而非 "screening" 改"people managing mental health and chronic conditions"
  - 建议: 保守策略(1h)删 4 疾病名 + 改泛指;完整策略(1-2 周需 Mac)真接 HealthKit

### 优先级 2:外部依赖卡点(域名 + 4 邮箱 + 5 厂商 push + 阿里云 SMS + 鸿蒙)— 4 项

- ⚠️⚠️⚠️ **[P0-006]** `chroniccare.app` 域名未注册 → 12 URL 不可达(Apple 5.1.1 + Google Play Data Safety 必拒)
  - 修复难度: L | 工作量: 4h + 7-20d ICP | 来源: superpowers-zh P0-001 + appstore P0-003 + googleplay P0-006 + superpowers-en 外部链接 + flutter-spec 外部链接 + bottom-up 外部链接
  - 现状: 6 fastlane URL + 2 Data Safety URL + 4 HTML 模板 全 `https://chroniccare.app/{privacy,support,user-agreement,sensitive-data-consent,delete-data-instructions}` 全 404
  - 建议: Cloudflare Registrar 注册 `.app` ($15/年) + ICP 备案 7-20d(中国大陆必需)

- ⚠️⚠️⚠️ **[P0-007]** 4 邮箱 `privacy@/support@/noreply@/abuse@chroniccare.app` 占位 + 法律文档 5+ 处硬显示
  - 修复难度: S | 工作量: 1-2h | 来源: superpowers-zh P0-002 + superpowers-en 外部链接 + flutter-spec 外部链接
  - 现状: 隐私政策 + 用户协议 + 敏感数据同意书 5 处 "**privacy@chroniccare.app**" 占位
  - 建议: Cloudflare Email Routing 免费转发 4 邮箱 + 同步替换 3 文档 5 处

- ⚠️⚠️ **[P0-008]** `AliyunSmsProvider.send()` 仍 `throw StateError` + `emergencyContactEnabled=false` → 失联通知 100% 失效
  - 修复难度: XL | 工作量: 1-2 月(法务 + 模板) | 来源: superpowers-zh P0-003 + superpowers-en 关联
  - 现状: 项目核心承诺"漏 2 天自动 SMS 通知紧急联系人"失约 = 8 元买断核心交付失效 + PIPL §13/§23/§28 严重违反
  - 建议: 申请 AccessKey (1-2 月) + HMAC-SHA1 签名 + POST dysmsapi.aliyuncs.com + 升 `scripts/check_sms_release_ready.py` 从 warn-only 升 hard FAIL

- ⚠️⚠️ **[P0-009]** 5 厂商 push SDK 0 接入 + OEM 引导被 FeatureFlag `SizedBox.shrink()` 隐藏
  - 修复难度: XL | 工作量: 1-2 月(5 厂商审核) | 来源: superpowers-zh P0-004 + googleplay P0-011
  - 现状: 国产 ROM(MIUI/EMUI/ColorOS/OriginOS/Flyme)送达率 < 70% + 用户根本看不到引导
  - 建议: 即使未真接,OEM 引导 UI **不能被 FeatureFlag 隐藏**(改为显示文字 + 底部"完整 5 厂商 push 待接入"提示)

### 优先级 3:鸿蒙 + IAP — 2 项

- ⚠️ **[P0-010]** 鸿蒙 / OpenHarmony 完全 0 适配 → 失去 1+ 亿 HarmonyOS NEXT 设备
  - 修复难度: XL | 工作量: 1-2 月 | 来源: superpowers-zh P0-005
  - 现状: pubspec.yaml 无 `flutter_ohos` 依赖 + 0 `ohos/` 目录
  - 建议: 跟踪 `flutter_ohos` GA(预计 2025 Q1)+ 或暂时保留 APK + 华为应用市场声明"暂未支持 HarmonyOS NEXT"

- ⚠️ **[P0-011]** iOS/Android 包名 `com.chroniccare.chroniccare` vs `store_kit_service.dart` IAP productId `com.chroniccare.app.lifetime` 不一致
  - 修复难度: S | 工作量: 15min | 来源: superpowers-zh P0-007
  - 现状: App Store Connect 创建 IAP product 时 metadata 不匹配 = 拒因
  - 建议: 改 `kLifetimeProductId` 跟实际包名一致 `com.chroniccare.chroniccare.lifetime`

### 优先级 4:跨视角共识 — 锁屏通知 PII(同源 3 视角)— 1 项

- ⚠️⚠️ **[P0-012]** 锁屏通知 **title** 仍含药名(`notifMedicationTitle(medName)` + `notifRefillTitle(medName)`)→ iOS 锁屏 banner title+body 同步显示
  - 修复难度: S | 工作量: 1h | 来源: appstore P0-005 + super-zh 关联 + bottom-up 外部链接
  - 现状: R108 修了 body(body 改通用文案),但 title 模板仍把 `med.name` 拼进字符串
  - 字符串文件**自带注释承认**:"实际: iOS 通知 title 在锁屏横幅也显示, 药名仍可见 — 进一步修法见 v1.0+"
  - 建议: 改固定文案 `'💊 该吃药了'`,`med.name` 改 payload 携带,用户点通知进 App 后看具体药名
  - 加 lock-in test `notification_title_redact_test.dart` 验证

### 优先级 5:R108 引入的 8 个回归 error(同源 4 视角)— 8 项

> 全部 S 难度,合计 ≤ 2.5h,必须先修让 working tree 0 error 才能进 R109

- **[P0-013]** `audio_lifecycle.dart:30` 缺 `package:flutter/widgets.dart` import → 16 个 error cascade
  - 修复难度: S | 工作量: 0.5h | 来源: superpowers-en P0-002 + flutter-spec P0-001 + super-zh 关联 + bottom-up 关联
  - 现状: `setState` / `mounted` / `StatefulWidget` / `State` 全 undefined
  - 建议: 加 `import 'package:flutter/widgets.dart';`(1 行改动可解 16 个 error)

- **[P0-014]** `MoodEntry` drift `recordingMode` 字段没 regenerate `.g.dart` → 5 个 error
  - 修复难度: S | 工作量: 0.5h | 来源: superpowers-en P0-004 + flutter-spec P0-002
  - 现状: schemaVersion 22 已加 recordingMode,domain entity 也加好,但 `.g.dart` 未跑
  - 建议: `dart run build_runner build --delete-conflicting-outputs`

- **[P0-015]** `sharedPreferencesProvider` / `safetyWatchServiceProvider` undefined → 2 个 error
  - 修复难度: S | 工作量: 0.5h | 来源: superpowers-en P0-003 + flutter-spec P0-003
  - 现状: main.dart:199 + home_care_engine_dispatcher.dart:62
  - 建议: `core_providers.dart` 加 `sharedPreferencesProvider` + `home_care_engine_dispatcher.dart` 加 `import 'service_providers.dart'`

- **[P0-016]** `notification_service.dart:334` 跨类访问 `@visibleForTesting` 字段
  - 修复难度: S | 工作量: 0.5h | 来源: superpowers-en P0-005 + flutter-spec P0-004
  - 现状: `_dispatcher.useExactAllowWhileIdle` 在 production code 跨类写
  - 建议: `reminder_dispatcher.dart` 加 public method `setExactMode(bool)` 封装写入(更好,既解 lint 又收敛写入路径)

- **[P0-017]** `legal_consent_provider.dart:190` `toIso8601String()` 不带 UTC(AGENTS.md 已知坑)
  - 修复难度: S | 工作量: 0.5h | 来源: bottom-up P0-001
  - 现状: R108 P0-3 修过 export_orchestrator / safety_config_service / last_error_capture 3 处同模式,但漏了 audit log
  - 跨时区(北京→纽约)audit log 时间"瞬移" 12-13h = PIPL §13 法定记录时间不准确,法务复查风险
  - 建议: `artifact.grantedAt.toUtc().toIso8601String()` + 加 lock-in test 验证

- **[P0-018]** `vent_detail_page.dart:73` fire-and-forget `deleteTempFile` 漏 await → vent 用户 PII 残留
  - 修复难度: S | 工作量: 30min | 来源: superpowers-en P0-001 + bottom-up P1-004
  - 现状: 3+ round 未修(R22 / R46 / R79),R22 注释"走 swallowError"实际从未生效
  - 精神心理患者语音树洞明文文件残留 = PII 泄露风险
  - 建议: `unawaited(...) + .catchError(...)` 或 `async dispose` + 加 lock-in test

- **[P0-019]** `WeightEntryDialog._getHeightCm()` `(profile as dynamic).heightCm` 永远抛 NoSuchMethodError → BMI 永远 null
  - 修复难度: S | 工作量: 1h | 来源: apple-health P0-003 + bottom-up P1-003
  - 现状: UserProfileEntity 无 heightCm 字段 → dynamic cast 抛错 → swallowError 吞掉 → BMI 永远 null
  - 4 round 未修(R91 → R95 → R100 → R108)
  - 建议: 短期删 dynamic 反射改 `return null;` + 加 lock-in test 防回退;长期 R109 user_profiles 表加 `heightCm REAL` 列

- **[P0-020]** `PrivacyInfo.xcprivacy` 声明 `NSPrivacyCollectedDataTypeHealthAndFitness` + 0 HealthKit 集成 → Apple 5.1.3 used-but-not-declared 抽审
  - 修复难度: M | 工作量: 2h | 来源: apple-health P0-001 + appstore P0-006
  - 现状: PrivacyInfo 声明 + Info.plist 无 NSHealthShareUsageDescription + Runner.entitlements 空 + pubspec 无 `health_kit`
  - 建议: 方案 A(推荐)删 PrivacyInfo 中 HealthAndFitness 声明 + 改 spec 文档名(medication-redesign-apple-health.md → medication-page-redesign.md)+ 加 lock-in test 扫"Apple Health/HealthKit" 关键词;方案 B 真接 HealthKit 5-15d

### 优先级 6:其他 P0(单视角发现,优先级中)— 12 项

- **[P0-021]** Android 短描述 `fastlane/metadata/android/en-US/short_description.txt` 87 字符超 80 限制
  - 修复难度: S | 工作量: 5min | 来源: googleplay P0-008
  - 建议: 砍 7 字符

- **[P0-022]** Android `manifest android:label` 硬编未走 `@string/app_name`
  - 修复难度: S | 工作量: 5min | 来源: googleplay P0-007
  - 建议: 改 `@string/app_name`

- **[P0-023]** Android keystore 实际未生成(`scripts/generate_android_keystore.sh` 存在但没真跑)
  - 修复难度: S | 工作量: 2-3d | 来源: googleplay P0-010 + emil P0-001 关联
  - 建议: Mac 跑脚本生成 + 加 lock-in test

- **[P0-024]** Android NotificationDetails 没设 `setLockscreenVisibility(VISIBILITY_SECRET)` → 药名 PII 残留
  - 修复难度: S | 工作量: 10min | 来源: googleplay P0-006
  - 建议: 锁屏隐藏 body + title(跟 P0-012 一起)

- **[P0-025]** `app_zh.arb:1181` 简中混入繁中字"條"(守门员漏检)
  - 修复难度: XS | 工作量: 5min | 来源: super-zh P0-006
  - 建议: 改"第 13 条"+ 扩 `check_zh_hant_consistency.py` 反向检查

- **[P0-026]** `medication_page.dart:553` 拆 7 sub-widget 仍是顶层 god class
  - 修复难度: M | 工作量: 4h | 来源: architecture P0-002 + superpowers-en P1-002 + flutter-spec P1-001
  - 现状: R108 拆了 _TimeSlot enum 反而增 30L 注释
  - 建议: 抽 `widgets/{time_slot_card,slot_entry_row,medication_list_card,quick_action_card,empty_*,section_header}.dart`

- **[P0-027]** `setup_page_state.dart:506` 抽 wizard controller + 复用抽象
  - 修复难度: M | 工作量: 4h | 来源: architecture P0-003
  - 现状: 4 步 wizard + 5 consent bool + saving 全堆 1 个 _SetupPageState
  - 建议: 抽 `setup_consent_controller.dart` + `setup_step_router.dart`

- **[P0-028]** `add_medication_page.dart:506` 抽 wizard 抽象(跟 setup 复用)
  - 修复难度: M | 工作量: 4h | 来源: architecture P0-004
  - 现状: 4 步 wizard 跟 setup_page_state 同款但完全独立,没复用
  - 建议: 抽 `widgets/wizard/wizard_controller.dart` 抽象基类

- **[P0-029]** `notification_service.dart:417` 拆 `NotificationInitializer` + `NotificationOrchestrator`
  - 修复难度: M | 工作量: 3h | 来源: architecture P0-005 + superpowers-en P2-001 + flutter-spec P1-001
  - 现状: facade 主体 417L(目标 < 150L),R108 拆 12 委派到 delegate 但 facade 仍 god
  - 建议: facade 改 100% pure(5 method + 3 const),init/rescheduleAll 拆子类

- **[P0-030]** `static_scale_translations.dart:659` 拆 10 量表子文件
  - 修复难度: L | 工作量: 1d | 来源: architecture P0-006
  - 现状: 10 量表 × 23 method = 230 method 中文 fallback 在 1 个文件
  - 建议: 拆 `static/{phq9_zh,gad7_zh,isi_zh,pss_zh,whodas_zh,level2_*.dart,asrm_zh}.dart`,主壳 150L

- **[P0-031]** `main.dart:50,61` 顶层 `final SmsService()/EmailService()` 改 Provider override
  - 修复难度: S | 工作量: 2h | 来源: architecture P0-001 + superpowers-en P2-006
  - 现状: 顶层 mutable `final` 持有 + Provider 也定义,两路实例化,违反 Riverpod DI 哲学
  - 建议: `FutureProvider<SmsService>` + `smsServiceProvider.overrideWith((ref) => SmsService.init(env))`

- **[P0-032]** `spec 文档 / 注释明文"参照 Apple Health" + 0 HealthKit 集成` 暴露战略
  - 修复难度: S | 工作量: 1h | 来源: apple-health P0-004
  - 现状: `medication-redesign-apple-health.md` / `mood-module-adjustment-apple-health.md` / 4 处代码注释"参照 Apple Health"
  - 建议: 改 spec 文件名 + 内部"Apple Health"提及 + 加 lock-in test 扫"Apple Health/HealthKit" 关键词

### 优先级 7:其他(单视角发现,优先级低)— 6 项

- **[P0-033]** `app_zh.arb:1181` 简中混"條"已列 P0-025(去重后)
- **[P0-034]** `medication_slot_calculator` 已抽到 domain OK ✅
- **[P0-035]** 慢病数据建模缺 Apple Health 主流类型(37.5% 覆盖) — `apple-health P0-002`
  - 修复难度: L | 工作量: 1-2d
  - 现状: 12 类 Apple Health 主流数据中只 5 类 + medication = 6 类(37.5%)
  - 建议: 写 `docs/HEALTHKIT_ROADMAP.md` + R109+ 真接
- **[P0-036]** emil 主页 stagger 8→3 层已闭环 ✅
- **[P0-037]** emil main.dart `developer.log` 3 处 `!kReleaseMode` 守卫已闭环 ✅
- **[P0-038]** super-zh `app_zh.arb:1181` 简中混"條"已列 P0-025(去重后)

---

## 3. P1 整合(去重后 ~50 项,按视角归类)

> P1 优先级低于 P0,但工作量大,跨 R108 收尾 + R109 拆分阶段修复

### 3.1 跨视角共识(≥3 视角)— 5 项

- ⚠️⚠️ **[P1-001]** 5 处 `use_build_context_synchronously` 跨 async gap 漏 `mounted` 守卫
  - 来源: superpowers-en P1-001 + flutter-spec P1-006
  - 位置: `home_care_engine_dispatcher.dart:69` + `home_deep_link_handler.dart:198/207/208` + `home_page_state.dart:470`
  - 修复难度: S | 工作量: 1h

- ⚠️⚠️ **[P1-002]** `app_zh.arb:1181` 简中混"條"已列 P0(去重)

- ⚠️⚠️ **[P1-003]** `setupConsentAgreeAll` 一键全勾 5 项(含敏感数据同意书)→ PIPL §14 "单独同意"风险
  - 来源: super-zh P1-001
  - 修复难度: M | 工作量: 1d

- ⚠️⚠️ **[P1-004]** 隐私政策 + 用户协议 + 敏感数据同意书 13+ 处"未来规划 / 本版本未启用"措辞 → PIPL §17 透明度违反
  - 来源: super-zh P1-002
  - 修复难度: M | 工作量: 1-2d
  - 现状: 律师过审(¥45-90k 1-2 月)最常见拒因

- ⚠️⚠️ **[P1-005]** `check_legal_consent.py` 守门员只扫 1 文件,不扫 4 份 md
  - 来源: super-zh P1-009
  - 修复难度: S | 工作量: 1-2h

### 3.2 R108 进行中相关(8 项,落地 1-2 周)

- **[P1-006]** super-en 8 个 R108 引入的 P0(已转 P0-013~020,去重)
- **[P1-007]** super-en `mood_entry_mapper.dart` `recordingMode` 字段(已转 P0-014,去重)
- **[P1-008]** super-en `notification_service.dart:334` `@visibleForTesting`(已转 P0-016,去重)
- **[P1-009]** super-en `skip_backup.dart:56` 私有字段 `@visibleForTesting` annotation 无效
  - 修复难度: S | 工作量: 5min
- **[P1-010]** flutter-spec 4 widget 缺 `super.key`(`MigrationAbortedApp` / `MigrationPromptApp` / `MigrationFailedApp` / `EarlyLoadingApp`)
  - 修复难度: S | 工作量: 5min
- **[P1-011]** flutter-spec `main.dart:158` `EarlyLoadingApp` 缺 const
  - 修复难度: S | 工作量: 2min
- **[P1-012]** flutter-spec 4 test 文件 `override_on_non_overriding_member` 15 个(R45b/R45d notification 拆 facade 后 test 没同步)
  - 修复难度: S | 工作量: 1h
- **[P1-013]** flutter-spec notification_service 8 method 搬到 delegate 但 call site 没跟上(test expect 旧 facade)
  - 修复难度: M | 工作量: 0.5d

### 3.3 god class 拆解(R108 收尾 6 + R109 7)— 13 项

- 已在 P0-026~030 列出 5 个,剩 8 个 P1:
  - **[P1-014]** `home_page_state.dart:440` 抽 celebration overlay + 1 helper → 250L(architecture P1-001)
  - **[P1-015]** `mood_audio_recorder_widget.dart:529` + `vent_compose_page.dart:416` R108 共享 mixin 但仍 > 400L(architecture P1-002)
  - **[P1-016]** `legal_page.dart:460` + `reminders_hub_page.dart:441` 双 god(architecture P1-003)
  - **[P1-017]** use case 层利用率低 → 8 个 usecase 厚化(architecture P1-004)
  - **[P1-018]** `app_database.dart:494` 拆 schema/v01-v13/ 子目录(architecture P1-005)
  - **[P1-019]** daily_tracking 7 widget 6 repo "过工程化" 35 文件(architecture P1-006)
  - **[P1-020]** `safety_watch_service.dart:338` facade 拆 detector + decision 静态方法(super-en P1-005)
  - **[P1-021]** `mood_audio_service.dart:311` 拆 `MoodSttController` + `MoodRecorderController`(super-en P1-006)

### 3.4 emil 设计(4 项)

- **[P1-022]** 7 处 raw `IconButton` 漏 `PressFeedbackIconButton` 包装 — `page_scaffold.dart:43` back button 最严重
  - 修复难度: S | 工作量: 0.5h
- **[P1-023]** Stale dead 注释 in `home_celebration_controller.dart:73-74`
  - 修复难度: S | 工作量: 5min
- **[P1-024]** `QuickMoodCarousel:101-103` 硬编码中文 SnackBar 违反 i18n
  - 修复难度: S | 工作量: 0.5h
- **[P1-025]** `TODO_R108.md` UTF-8 mojibake 字符编码损坏
  - 修复难度: S | 工作量: 5min

### 3.5 iOS / Android 平台(8 项)

- **[P1-026]** appstore `iOS 16KB page size` 验证未跑
  - 修复难度: M | 工作量: 2-4h
- **[P1-027]** appstore iOS AppIcon 1024×1024 偏小 10932B
  - 修复难度: S | 工作量: 1h + 设计师 0.5d
- **[P1-028]** appstore `ios/Podfile` Windows 占位 + 缺 `Podfile.lock`
  - 修复难度: M | 工作量: 2-4h
- **[P1-029]** appstore `DEVELOPMENT_TEAM` 未设 + 包名 `com.chroniccare.chroniccare` 冗余
  - 修复难度: S | 工作量: 15min
- **[P1-030]** googleplay Android 缺 foreground service 声明
- **[P1-031]** googleplay Android 缺 `usesCleartextTraffic="false"`
- **[P1-032]** googleplay Android 缺 monochrome small icon + `setShowBadge false`
- **[P1-033]** googleplay Android 缺 v3/v4 signing scheme 显式 + 5 厂商 push `<queries>` + androidx.work

### 3.6 国内合规 / PIPL(5 项)

- **[P1-034]** super-zh §7 第三方依赖表 19 SDK 未区分 iOS/Android
  - 修复难度: S | 工作量: 1h
- **[P1-035]** super-zh 失联通知 0 lock-in test
  - 修复难度: M | 工作量: 1d
- **[P1-036]** super-zh `setupConsentViewDisclaimer` 标题无关联
  - 修复难度: XS | 工作量: 10min
- **[P1-037]** super-zh `ventAudioEnabled` R104 翻 true 但隐私政策未同步
  - 修复难度: S | 工作量: 30min
- **[P1-038]** super-zh 危机热线 5 条分散维护
  - 修复难度: S | 工作量: 1h

### 3.7 apple-health 集成(5 项)

- **[P1-039]** medication ↔ Apple Health Medication 0 关联(无 RxNorm)
  - 修复难度: XL | 工作量: 1-2 周
- **[P1-040]** 慢病数据时区 / 跨时区处理不严(sleep / weight / anxiety / stress / social_rhythm)
  - 修复难度: M | 工作量: 1d
- **[P1-041]** HealthKit 单元测试 0 个
  - 修复难度: M | 工作量: 1d
- **[P1-042]** `medication_slot_calculator` 跨时区 / 24h 切换
  - 修复难度: S | 工作量: 4h
- **[P1-043]** mood entry CBT 字段 + State of Mind 集成空缺
  - 修复难度: L | 工作量: 1-2 周

### 3.8 底层(5 项)

- **[P1-044]** `assessment_repository_impl.dart:71` `DateTime.now()` 不走集中器(R90 后加的漏)
  - 修复难度: S | 工作量: 10min
- **[P1-045]** `audio_lifecycle.dart:434-437` `await cleanupTempFile()` 不在 try-catch
  - 修复难度: S | 工作量: 15min
- **[P1-046]** `weight_widgets.dart:150` BMI 永远 null + 无 lock-in test(已转 P0-019,去重)
- **[P1-047]** `vent_detail_page.dart:73` 缺 lock-in test(已转 P0-018,去重)
- **[P1-048]** `mood_audio_recorder_widget.dart:559` 100ms Timer.periodic 不尊重 reduce-motion
  - 修复难度: S | 工作量: 0.5h
- **[P1-049]** `medication_slot_calculator_round108_test.dart:139/140` `use_named_constants` 2 个
  - 修复难度: S | 工作量: 5min
- **[P1-050]** `lib/main/boot_apps.dart:90/98/153/161/168/174/260/262/266/268` 6+4 处 magic SizedBox(emil P2-002 漏 4 处)
  - 修复难度: S | 工作量: 5min

---

## 4. 外部链接 / 域名 / 邮箱 / URL 隐藏检查汇总(9 视角交叉)

| 位置 | 内容 | 状态 | 来源 |
|---|---|---|---|
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` × 3 | `https://chroniccare.app/privacy` | ❌ 未注册 (Apple 5.1.1 拒因 P0-006) | appstore / sp-zh / googleplay / sp-en / flutter-spec / bottom-up (6 视角) |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` × 3 | `https://chroniccare.app/support` | ❌ 同上 | 同上 |
| `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` × 2 | `https://chroniccare.app/privacy` | ❌ Google Play 拒因 | 同上 |
| `fastlane/metadata/android/{en-US,zh-CN}/support_url.txt` × 2 | `https://chroniccare.app/support` | ❌ 同上 | 同上 |
| `assets/legal/privacy_policy.md:150` | `**privacy@chroniccare.app**` | ⚠️ 软隐藏 (R96),邮箱未注册 | 6 视角 |
| `assets/legal/privacy_policy.md:227` | `privacy@chroniccare.app` (changelog) | ⚠️ 同上 | flutter-spec |
| `assets/legal/user_agreement.md:67,69,88` | `privacy@chroniccare.app` × 3 | ⚠️ 同上 | 6 视角 |
| `assets/legal/sensitive_data_consent.md:46` | (同上) | ⚠️ | super-zh |
| `scripts/generate_data_safety_form.py:85,114` | `https://chroniccare.app/delete-data-instructions` + `/privacy` | ❌ 未隐藏(脚本生成器) | super-zh |
| `scripts/templates/*.html.tmpl` × 4 | `https://chroniccare.app/*` | ❌ 占位符 | super-zh |
| `lib/core/data/services/store_kit_service.dart:50` | `com.chroniccare.app.lifetime` productId | ⚠️ 跟包名 `com.chroniccare.chroniccare` 不一致 | super-zh P0-011 |
| `lib/core/l10n/strings.dart:112-116` | `notifMedicationTitle(medName)` 含药名 | ❌ 锁屏 PII 残留 | appstore P0-012 + bottom-up |
| `lib/core/l10n/strings.dart:139-140` | `notifRefillTitle(medName)` 含药名 | ❌ 同上 | 同上 |
| `lib/presentation/providers/legal_consent_provider.dart:190` | `grantedAt.toIso8601String()` | ❌ 不带 UTC 'Z' 后缀 | bottom-up P0-017 |
| `lib/core/data/services/sms_service.dart:99,102,181` | `https://dysmsapi.aliyuncs.com/` | ✅ 注释用,非用户面 | flutter-spec |
| `lib/main.dart` `https://` | 0 | ✅ | flutter-spec |
| `lib/presentation/` `https://` | 0 | ✅ 零云端架构 | flutter-spec |
| `lib/domain/` `https://` | 0 | ✅ 纯 Dart | flutter-spec |
| `lib/core/` `https://` | 0 (除 sms_service 注释) | ✅ | flutter-spec |
| `fastlane/metadata/ios/**/description.txt` + android 同 | `https://findahelpline.com` × 5 | ✅ 国际心理求助热线(应保留) | flutter-spec |
| 跨 spec 文档 + 代码注释 | "Apple Health / HealthKit" 关键词 5+ 处 | ❌ Apple 5.1.3 抽审 | apple-health P0-032 |

**总评**:
- **0 外部链接"故意隐藏"**(项目不主动藏,只是域名/邮箱未注册 + 锁屏 PII 漏脱敏)
- **12 URL + 5+ 邮箱 + 1 productId + 1 audit log 时间** = **P0 上架硬阻塞**
- **5 findahelpline.com** 是公开国际心理热线,应保留
- **整个 lib/ 0 硬编 https:// 业务外链** = 零云端架构完整

---

## 5. 上架 / 架构 / 重构 / 半成品问题汇总

### 5.1 上架相关(P0 整合已覆盖)

**iOS 上架**(`appstore` 评分 3.5/10):
- P0-001~005: 截图 / LaunchImage / 域名 / review TODO / 锁屏 PII title
- P0-006: Health 5.1.3 抽审
- P0-007: Podfile Windows 占位
- P0-008: DEVELOPMENT_TEAM + 包名
- P1-001~003: AppIcon 偏小 / 16KB / IAP 8 元买断声明
- **紧急 4h 修复(ROI 排序)**:P0-004 review info(30min)→ P0-012 锁屏 title(1h)→ P0-008 DEVELOPMENT_TEAM(15min)→ P0-005 en-US 描述(1h)

**Android 上架**(`googleplay` 评分 5.5/10):
- P0-001~011: 8 张截图 67B + feature_graphic 67B + icon + 平板截图 + 域名 + PII 残留 + label + 短描述 + 5.1.3 + keystore + 5 厂商 push
- P1-001~010: foreground service / cleartext / monochrome icon / v3-v4 signing / 5 厂商 push queries / androidx.work / zh-TW / Fastfile Closed Testing
- **紧急 4h 修复(ROI 排序)**:P0-008 short_description → P0-007 manifest label → P0-006 lockscreenVisibility → P0-001 跑截图脚本

**国内合规**(`super-zh` 评分 6.5/10):
- P0-001~008: 域名 + 4 邮箱 + AliyunSMS + 5 厂商 push + 鸿蒙 + 简繁混 + 包名不一致 + review info TODO
- P1-001~009: PIPL §14 一键全勾 + §17 未来规划措辞 + 第三方依赖表 + 失联通知 lock-in test + 标题无关联 + ventAudio 未同步 + 危机热线 + 守门员范围
- 5 项业务暂停:FeatureFlag 7/8 false(`iapEnabled` / `emergencyContactEnabled` / `fiveVendorPushEnabled` / `emailServiceEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` / `aliyunSmsEnabled`)

### 5.2 架构相关(`architecture` 评分 8.4/10)

**4 层架构纯度**: ✅ 100% 通过(`check_all.dart` 跑通)
- domain 0 flutter / 0 drift / 0 data / 0 presentation
- shared 0 flutter / 0 drift / 0 data / 0 presentation
- data 0 presentation
- drift `@DataClassName('X')` ↔ domain `*Entity` 1:1 对应

**5 层架构(use case)利用率**: ⚠️ 低(`lib/domain/usecases/` 仅 4 文件 425L,presentation 直接调 domain/logic)

**15 个 god class 候选**(R108 收尾 6 + R109 7 + R1.0 2):
- 已在 P0-026~030 列出 5 个 P0(medication_page / setup_page_state / add_medication_page / notification_service / static_scale_translations)
- 已在 P1-014~021 列出 8 个 P1
- 剩 2 个 R1.0 长期:`strings.dart` 80+ const 中文 fallback + `static_scale_translations_l10n.dart` 720L i18n 镜像

**SOLID 5 原则审计**:
- SRP: ⚠️ 15 god class 违规(分 3 批修)
- OCP: ✅ FeatureFlag + interface 抽象
- LSP: ✅ 100% 抽象层一致
- ISP: ✅ Repository 按 entity 拆
- DIP: ✅ presentation → domain / data → domain 0 反向

**DI 模式(Riverpod 3.x)**: ⚠️ 顶层 static mutable service 违反(P0-031)

**路由架构(go_router 14.6)**: ✅ 0 god router(11 文件,单文件最大 169L)

**跨 feature privacy 边界**: ✅ Vent 完全独立(5/5 行,`check_cross_feature.py` 0 violation)

**feature-first 重构**(`lib/features/{feature}/{domain,data,presentation}/`):
- 决策:R1.0 之后 1-2 月开 R110 专项(跟 pub workspace 叠加)

**pub workspace 拆分**: R1.0 之后评估

### 5.3 重构建议

**R108 收尾(2-3 天,优先级 1)**:
1. P0-031 main.dart 顶层 SmsService/EmailService 改 Provider (2h, S)
2. P0-026 medication_page 拆 7 sub-widget (4h, M)
3. P0-029 notification_service 拆 Initializer + Orchestrator (3h, M)
4. P1-014 home_page_state 抽 celebration overlay + helper (4h, M)
5. P1-015 mood_audio_recorder / vent_compose 删旧字段 (4h, M)
6. P1-050 mood_trend_page 拆 3 sub-file (4h, M)
- 总计 ~2d

**R109 god class 专项(1-2 月,优先级 2)**:
- P0-027 setup_page_state 抽 wizard controller + 复用抽象
- P0-028 add_medication_page 抽 wizard 抽象
- P1-016 legal_page + reminders_hub_page 双 god
- P1-020 safety_watch_service facade 拆 detector + decision
- P1-021 mood_audio_service 311L 拆
- P1-018 app_database 494L 拆 schema/v01-v13/
- P0-030 static_scale_translations 拆 10 量表
- P1-017 use case 层厚化 8 个 usecase
- P1-019 daily_tracking 7 widget 6 repo "过工程化" 收口

**R110 feature-first 重构(2-3 周,优先级 3)**:
- `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package
- 跟 use case 层厚化叠加

### 5.4 半成品 / TODO / 残缺功能

**R108 进行中半成品**(`R108 P0#11-#13 任务清单`):
- 18 个子任务,16 个 `[ ]` 未做,2 个 `[x]`(keystore PowerShell 复用 + data_safety_form.py 复用)
- 阻塞 R109 上 store

**业务真接(5 项,1-2 月)**:
- 阿里云 SMS(法务 + AccessKey 申请)
- SendGrid Email(SendGrid API key)
- 5 厂商 push(MIUI / EMUI / ColorOS / OriginOS / Flyme)
- 鸿蒙 / OpenHarmony NEXT(flutter_ohos GA)
- IAP 8 元买断(App Store Connect productId)

**FeatureFlag 8 项(7 false / 1 true)**:
- `_prodIapEnabled = false`
- `_prodEmergencyContactEnabled = false`(P0-008 失联通知)
- `_prodFiveVendorPushEnabled = false`(P0-009 5 厂商 push)
- `_prodEmailServiceEnabled = false`
- `_prodPhqGad7I18nEnabled = false`
- `_prodBootReceiverEnabled = false`
- `_prodAliyunSmsEnabled = false`
- `_prodVentAudioEnabled = true`(R104 翻 true)

**R107 12 项 P0 整改进度**:
- ✅ 已修 5:R108 P0#2 canScheduleExactAlarms / R108 P0#5 主页 stagger clamp / R108 P0#12 main.dart `developer.log` 3 处守卫 / R108 P0#4 PrivacyInfo 文件存在 / R108 P0#9 UIBackgroundModes audio
- ⏸️ 半成品 1:review_information(只 2/6 文件写好,4 个 TODO)
- ❌ 未做 6:锁屏 body 药名 → 转 P0-012 title / iCloud Backup 排除(已修,跨视角共识 4 caller + 4th defense-in-depth) / LaunchImage 占位 → P0-003 / 域名注册 → P0-006 / 截图 0 → P0-001 / 5 厂商 push → P0-009 / Android keystore → P0-023 / en-US description 5.1.3 → P0-005 / main.dart `developer.log` release 守卫 → 已闭环

---

## 6. 修复路线图(按优先级排序)

### Phase 1:R108 收尾(预计 1-2 周,2026-08 中旬前)

> 目的:让 working tree `flutter analyze 0 error` + `flutter test 0 fail` + R108 god class 拆 5/6 收尾

**Day 1: 修 8 个 R108 引入的 P0 error**(合计 ~2.5h)
- P0-013 audio_lifecycle 缺 imports(15min)
- P0-014 `dart run build_runner build`(30min)
- P0-015 main.dart + home_care_engine_dispatcher import 漏改(30min)
- P0-016 notification_service @visibleForTesting(30min)
- P0-017 legal_consent audit log toUtc(30min)
- P0-018 vent_detail_page deleteTempFile await(30min)
- P0-019 weight_widgets dynamic 反射删 + lock-in test(1h)
- P0-020 PrivacyInfo HealthAndFitness 删 + spec 文件名改(2h)

**Day 2-3: 上架紧急 4h**(优先级 1)
- P0-021 Android short_description 砍 7 字符(5min)
- P0-022 manifest label 改 @string/app_name(5min)
- P0-024 AndroidNotificationDetails setLockscreenVisibility(10min)
- P0-025 app_zh.arb "條" → "条"(5min)
- P0-011 store_kit_service productId 改(15min)
- P0-012 锁屏通知 title 改固定文案(1h)
- P0-004 review_information 4 文件 TODO 替换(30min)
- P0-008 ios DEVELOPMENT_TEAM 手动设 + 包名(15min,需 Mac)
- P0-005 en-US description 删 4 疾病名(1h)

**Day 4-7: R108 收尾 6 项 god class 拆解**(2d)
- P0-031 main.dart 顶层 SmsService/EmailService 改 Provider(2h)
- P0-026 medication_page 拆 7 sub-widget(4h)
- P0-029 notification_service 拆 Initializer + Orchestrator(3h)
- P1-014 home_page_state 抽 celebration overlay + helper(4h)
- P1-015 mood_audio_recorder / vent_compose 删旧字段(4h)
- P1-050 mood_trend_page 拆 3 sub-file(4h)

**Week 2: 守门员 + 守门员加 5 个新检查**(3-4d)
- `check_audit_log_tz.py`(P0-017 防回退)
- `check_apple_health_claim.py`(P0-020 关键词扫描)
- `check_review_information_todo.py`(P0-004 防回退)
- `check_pii_in_title.py`(P0-012 防回退)
- `check_analyze.py`(flutter analyze 0 error 强门)
- 跑 `dart fix --apply` + `dart format .` 清 53 个 require_trailing_commas

### Phase 2:外部依赖 4 卡点(预计 1-2 月,2026-09 前)

> 目的:解锁 R109 上 store 路径

**并行推进**:
- P0-006 chroniccare.app 域名(7-20d ICP,卡点) + 4 邮箱注册(2h)
- P0-008 阿里云 SMS 真接(1-2 月,AccessKey + 法务 + 模板审核)
- P0-009 5 厂商 push 真接(1-2 月,5 厂商并行审核)
- P0-010 鸿蒙 / OpenHarmony(1-2 月,跟踪 flutter_ohos GA)

### Phase 3:R109 god class 专项(预计 1-2 月,2026-09-10 月)

- P0-027 setup_page_state 抽 wizard controller
- P0-028 add_medication_page 抽 wizard 抽象
- P1-016 legal_page + reminders_hub_page 双 god
- P1-020 safety_watch_service facade 拆
- P1-021 mood_audio_service 311L 拆
- P1-018 app_database 494L 拆 schema/v01-v13/
- P0-030 static_scale_translations 拆 10 量表
- P1-017 use case 层厚化 8 个 usecase
- P1-019 daily_tracking 7 widget 6 repo 收口

### Phase 4:R110 feature-first 重构(预计 2-3 周,2026-Q4)

- `lib/features/{feature}/{domain,data,presentation}/` 重组
- pub workspace 3 package 拆分
- 跟 use case 层厚化叠加

### Phase 5:R1.0 长期(预计 2027-Q1 后)

- `core/l10n/strings.dart` 314L 改 domain 0 中文字面量
- `static_scale_translations_l10n.dart` 720L codegen 化
- drift 数据库拆 2-3 个 db
- care 业务 5 文件合并
- 鸿蒙原生 Hap 包(ArkTS 或 flutter_ohos)
- HealthKit 真接
- 微信 / QQ / 微博 / Apple ID OAuth 集成
- 隐私政策 §7 SDK 表 iOS/Android 拆分
- 5 文档危机热线 `crisis_hotlines.json` 单一来源

---

## 7. 加权综合评分趋势

| 阶段 | 加权综合评分 | 关键里程碑 |
|---|---|---|
| R107(2026-08-08) | 8.0/10 | 9 视角 + 顶层 + 底层完成,综合 8.0 |
| R108 中(2026-08-10) | **6.2/10** | R108 拆 god class 进行中,引入 8 个回归 error + 上架实物资产未做 |
| R108 完工(预计 2026-08 末) | **7.5-8.0/10** | Phase 1 全部完成,0 analyzer error,8 个上架 P0 闭环 |
| R109 完工(预计 2026-10) | **8.5/10** | 5-6 个 god class 拆完 + use case 层厚化 |
| R110 完工(预计 2026-Q4) | **9.0/10** | feature-first + pub workspace |
| R1.0(预计 2027-Q1) | **9.5/10** | HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS 真接 + IAP |

---

## 8. 给项目维护者的关键 takeaway

1. **R108 是"半成品收尾"**:8 个 P0 引入 error 是拆解漏 compile gate(没跑 `flutter analyze` 就 commit)。修这 8 个 P0 估计总耗时 ≤ 2.5h,即可恢复 R107 92% baseline。

2. **3 个上架硬阻塞**:
   - iOS 截图 0 / LaunchImage 68B / icon 偏小(实物资产 1-2 周)
   - 域名 + 4 邮箱未注册(7-20d ICP 卡点)
   - 5 厂商 push 0 接入(1-2 月审核)+ 阿里云 SMS 失联通知 100% 失效(1-2 月法务)
   - 这 3 卡点不解决,任何 1 项都能直接 reject

3. **4 个 P0 业务真接(1-2 月)**:
   - 阿里云 SMS = 失联通知核心承诺(8 元买断核心交付)
   - 5 厂商 push = 国产 ROM 实际送达
   - 鸿蒙 = 失去 1+ 亿 HarmonyOS NEXT 设备
   - IAP 8 元买断 = 商业模式闭环

4. **13 处"未来规划"措辞**(PIPL §17 透明度违反,律师过审 ¥45-90k 1-2 月最常见拒因)

5. **Vent 隐私边界 5/5 ✅**:0 violation,符合项目"零云端 + 树洞独立"哲学

6. **顶层 15 god class 路线图清晰**:R108 收尾 6 + R109 拆 7 + R1.0 长期 2

7. **跨视角共识 = 高优先级**:≥3 视角提及的 P0 优先做(锁屏 PII title 6 视角共识 = P0-012)

8. **R110 feature-first 重构不应在 R108 期间做**:layer-first 仍稳定,1-2 月 R109 完成后开 R110 专项

9. **appstore 评分 3.5 + apple-health 评分 3.0 = 上架硬伤**:iOS 上架比 Android 麻烦,HealthKit 集成 0 = Apple 5.1.3 抽审高概率拒因

10. **整合数据已写入 `00-FINAL-CONSOLIDATION.md`(本文件),AGENTS.md + README.md + VERSION_1.0_PLAN.md 同步更新**

---

## 9. 跨 9 视角的"金句"汇总

> emil(设计 8.5):"R108 是成熟收尾 + 关键上架前 P0 未完成 阶段"
> superpowers-en(6.5):"R108 是'拆解半成品',方向对,落地漏 compile gate"
> superpowers-zh(6.5):"3 大硬阻塞未解(域名 + 5 厂商 push + 阿里云 SMS)叠加 5 类半成品"
> appstore(3.5):"iOS 上架'必交资产'全部占位/TODO/未注册,任何一项触发拒因"
> googleplay(5.5):"R108 修了 13 项 P0 的'工具'层(脚本+文档+lock-in test),但 Play Console 提审必需的 11 项'实物资产'100% 缺失"
> flutter-spec(6.8):"R108 进行中破坏 0-error 基线,合规率从 92% 倒退到 88%"
> apple-health(3.0):"HealthKit/Health Connect 数据通道 = 0 集成,Apple 5.1.3 used-but-not-declared 高概率拒因"
> architecture(8.4):"4 层架构 1:1 落地,但 6 个 400+ 行 god class 候选仍待 R108 收尾"
> bottom-up(7.0):"底层真实 bug 集中在'老坑新发'模式,同款 bug pattern 在 R108 修 1 处但漏 1-2 处"

---

## 附录 A: 9 份报告文件清单

| # | 文件 | 大小 | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|---|
| 1 | `lens/01-emil.md` | 27KB | 2 | 4 | 3 | - |
| 2 | `lens/02-superpowers-en.md` | 39KB | 8 | 7 | 6 | 4 |
| 3 | `lens/03-superpowers-zh.md` | 60KB | 8 | 9 | 6 | 6 |
| 4 | `lens/04-appstore.md` | 38KB | 8 | 7 | - | - |
| 5 | `lens/05-googleplay.md` | 44KB | 11 | 10 | - | - |
| 6 | `lens/06-flutter-spec.md` | 46KB | 4 | 14 | 9 | 7 |
| 7 | `lens/07-apple-health.md` | 57KB | 4 | 6 | - | - |
| 8 | `08-architecture.md` | 46KB | 6 | 6 | 5 | 4 |
| 9 | `09-bottom-up-bugs.md` | 42KB | 1 | 5 | 5 | 3 |
| **整合** | **`00-FINAL-CONSOLIDATION.md`(本文件)** | - | **~38** | **~50** | - | - |

**9 份报告总和**:404KB(每个 27-60KB 平均 45KB)

---

<!-- 整合者: Mavis 主 agent 完成时间: 2026-08-10T07:30:00+08:00 -->
