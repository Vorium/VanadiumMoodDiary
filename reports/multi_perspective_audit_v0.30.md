# ChronicCare v0.30.0+85 多视角综合审查报告

> 审查日期: 2026-08-08
> 审查视角: emilkowalski / superpowers-en / superpowers-zh / flutter-specification / AppStore / GooglePlay / Apple Health
> 代码规模: 388 Dart 文件, lib/ 5 层架构

---

## 一、外部链接隐藏确认

| 链接 | 位置 | 状态 |
|------|------|------|
| `https://chroniccare.app/privacy` | fastlane metadata (4 处) | ⚠️ **域名未注册**, 上架前必须注册 |
| `https://chroniccare.app/support` | fastlane metadata (3 处) | ⚠️ **域名未注册**, 上架前必须注册 |
| `https://findahelpline.com` | fastlane store description (4 处) | ✅ 外部危机热线链接, 合规保留 |
| `https://dysmsapi.aliyuncs.com` | sms_service.dart 注释 (3 处) | ✅ 仅注释, 非运行时, 已隐藏 |
| `https://holidayapi.com` | chinese_holidays.dart 注释 | ✅ 仅注释说明为什么不接 API |
| `privacy@chroniccare.app` | 法律文档 3 处 + privacy_policy.md | ⚠️ **邮箱未注册**, 上架前必须配置 |

**结论**: 运行时代码中**无外部链接泄露**。fastlane metadata 中的 URL 和邮箱需在上架前注册。

---

## 二、综合问题清单 (按修复优先级排序)

### P0 — 阻塞级 (必须修复才能上架/发布)

| # | 类别 | 来源视角 | 文件:行 | 问题描述 | 修复难度 |
|---|------|---------|---------|---------|---------|
| 1 | **安全** | flutter-spec | `native.dart:27` | `PRAGMA key = '$password'` SQL 注入风险 — 密码直接拼接 SQL, 含单引号时注入。应参数化或转义 | 低 |
| 2 | **上架** | AppStore | `fastlane/metadata/` | `chroniccare.app` 域名 + `privacy@chroniccare.app` 邮箱未注册, Apple **强制要求**可访问的隐私政策 URL | 中 (外部) |
| 3 | **上架** | AppStore | `assets/legal/user_agreement.md:89` | 法律文档仍有 "TODO 上 store 前必须由专业律师过审" 标记, 3 份文档均未律师审核 | 高 (外部) |
| 4 | **上架** | AppStore+Google | fastlane metadata | Store description 描述了已禁用功能 (trusted contacts / voice notes / password protection), 与实际不符 → Apple 2.1 拒 | 低 |
| 5 | **上架** | AppStore | `Info.plist:47-50` | `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` 声明但功能已禁用 (`ventAudioEnabled=false`), Apple 会拒 | 低 |
| 6 | **上架** | AppStore | `Info.plist:72` | `NSUserTrackingUsageDescription` 声明但无 IDFA 使用, 误导性声明可能被拒 | 低 |
| 7 | **上架** | Google | `AndroidManifest.xml:54` | `android:label="慢病管家"` 硬编码中文, 英文用户设备上显示中文 App 名 | 低 |
| 8 | **i18n** | superpowers-zh | `daily_tracking_multi_chart.dart:164-170` | `_metricName()` 硬编码中文 `'体重'`/`'睡眠'`/`'心境'`/`'应激源'`, en 用户看中文 | 低 |

### P1 — 高优先级 (严重影响体验/合规)

| # | 类别 | 来源视角 | 文件:行 | 问题描述 | 修复难度 |
|---|------|---------|---------|---------|---------|
| 9 | **上架** | AppStore+Google | (缺失) | 无内容评级配置 (IARC / Apple 内容分级), 心理健康 App 含 PHQ-9 筛查需特殊评级 | 中 |
| 10 | **上架** | Google | fastlane metadata | 缺 Google Play Data Safety form 数据, 健康类 App 面临额外审查 | 中 |
| 11 | **上架** | AppStore | `store_kit_service.dart:119` | IAP `buyLifetime()` release 返 false, 但 pubspec 有 `in_app_purchase` 依赖。若有任何 UI 引用 "购买" → Apple 2.1 拒 | 低 |
| 12 | **架构** | superpowers-en | `app_database.dart:410-480` | `saveSetup()` 是业务编排逻辑 (profile + contact + medication), 不应在数据层。应抽 UseCase | 中 |
| 13 | **架构** | superpowers-en | `app_database.dart:6-7` | 数据层反向 import domain 实体 (`consent_artifact.dart`, `hour_minute.dart`), 违反依赖方向 | 中 |
| 14 | **i18n** | superpowers-zh | `strings.dart:72-96` | 通知 Channel 名 + 每日打卡通知文本 const 中文, `badge_sync_service`/`notification_service` 直接用 const 不走 override, en/zh_Hant 系统设置看中文 | 中 |
| 15 | **i18n** | superpowers-zh | `phone_validator.dart:165-173` | `displayName` getter 硬编码中文 `'中国大陆'` 等, UI 可能直接调用 | 低 |
| 16 | **性能** | flutter-spec | `vent_compose_page.dart:441` | `onChanged: (_) => setState(() {})` 空 setState 每次击键触发整页重建 | 低 |
| 17 | **性能** | flutter-spec | `mood_audio_recorder_widget.dart:197` | `setState(() {})` 100ms 定时器 tick, 每秒重建 10 次整个 widget 树 | 低 |
| 18 | **UI** | emilkowalski | `hero_illustration.dart:51-53` | `Colors.black` shadow 硬编码, dark mode 下黑色阴影在暗背景上不可见 | 低 |
| 19 | **UI** | emilkowalski | `mood_trend_page.dart:266,282,545` | `Colors.white` 硬编码, dark mode 对比度问题 | 低 |
| 20 | **UI** | emilkowalski | `medication_detail_page.dart:319` | `Colors.white` 硬编码 chip 颜色 | 低 |
| 21 | **架构** | superpowers-en | `mood_entry_entity.dart:23-130` | 20 字段 entity + 20 参数 copyWith, CBT 字段应拆成独立 value object | 高 |
| 22 | **Dead Code** | superpowers-en | `sms_service.dart:107-203` | `AliyunSmsProvider` 97 行完全未实现 (`_isFullyImplemented => false`), 携带成本高 | 低 |
| 23 | **Dead Code** | superpowers-en | `email_service.dart:34-165` | `EmailService` 130 行 send 永远返 false, 同上 | 低 |

### P2 — 中优先级 (质量/一致性改进)

| # | 类别 | 来源视角 | 文件:行 | 问题描述 | 修复难度 |
|---|------|---------|---------|---------|---------|
| 24 | **DRY** | superpowers-en | 3 处 | `daysBetween()`/`isSameDay()` 在 `safety_config_service.dart:109-117`, `safety_detector.dart:82-93`, `assessment_comparison.dart:244-248` 重复 3 份 | 低 |
| 25 | **架构** | superpowers-en | `safety_config_service.dart:31-33` | 每个方法都调 `SharedPreferences.getInstance()` (异步平台调用), 应缓存实例 | 低 |
| 26 | **架构** | superpowers-en | `feature_flags.dart:72-79` | 8 个 `static bool?` 全局可变状态, 测试忘记 `resetForTest()` 会污染后续测试 | 中 |
| 27 | **i18n** | superpowers-zh | `app_en.arb:417` | `setupContactPhoneHint` 英文版也是 `'13800138000'` (中国号码), 应改当地格式 | 低 |
| 28 | **i18n** | superpowers-zh | `strings.dart:257-268` | 导入摘要 6 个函数 fallback 中文, en 用户导入后看中文摘要 | 低 |
| 29 | **i18n** | superpowers-zh | `strings.dart:273-283` | `moodLabel()` 情绪标签 fallback 中文 (`'很差'`/`'差'` 等) | 低 |
| 30 | **i18n** | superpowers-zh | store description | `settingsIapUpgradeSubtitle` en 版用 `'¥8'` 人民币符号, 海外应显示本地货币 | 低 |
| 31 | **UI** | emilkowalski | `vent_list_page.dart:358-370` | 日期格式手动 `padLeft` 拼接, 应走 `intl` `DateFormat` (R56d 决策) | 低 |
| 32 | **UI** | emilkowalski | `setup_step_done.dart:42-73` | 3 处 inline TextStyle 重复 `AppTokens.textStyleTitle(context)` 定义 | 低 |
| 33 | **UI** | emilkowalski | `quick_mood_carousel.dart:124` | 硬编码 `height: 80`, 应抽 token | 低 |
| 34 | **UI** | emilkowalski | `home_fab_toolbar.dart:163-164` | 硬编码 `width: 56, height: 56`, 应走 token | 低 |
| 35 | **UI** | emilkowalski | `empty_state.dart:57-59` | 硬编码 icon 容器 `96` + gradient alpha `0.08`/`0.02` | 低 |
| 36 | **兼容** | flutter-spec | `app_database.dart:10-11` | `dart.library.html` 条件导入在 Dart 3.x 已弃用, 应改 `dart.library.js_interop` | 低 |
| 37 | **兼容** | flutter-spec | `web/` 目录 | Web 平台已显式阻断 (`web.dart`) 但 `web/` 目录有 `sqlite3.wasm` + `drift_worker.dart.js` 死文件 | 低 |
| 38 | **兼容** | flutter-spec | `web/index.html:21` | `<title>` + `<meta description>` 硬编码中文 | 低 |
| 39 | **兼容** | flutter-spec | `app.dart:128` | `_lastCheck = DateTime.now()` 不用 `tz.TZDateTime.now(tz.local)`, DST 边界不一致 | 低 |
| 40 | **性能** | flutter-spec | `store_kit_service.dart:79-83` | `isProSync()` 读静态缓存, warmup 未完成时 UI 显示错误状态 | 低 |
| 41 | **架构** | superpowers-en | `main.dart:84-262` | `_bootstrap()` 180 行 god function, 应拆子函数 | 中 |
| 42 | **架构** | superpowers-en | `vent_repository_impl.dart:48-55` | 构造函数用 positional optional params, 调用方必须传 `null` 跳中间参数 | 中 |
| 43 | **上架** | AppStore | `Info.plist:66` | `NSPhotoLibraryUsageDescription` 可能不必要 (share_plus 用 UIActivityViewController 不需此权限) | 低 |
| 44 | **上架** | Google | `proguard-rules.pro:41` | `-renamesourcefileattribute SourceFile` 混淆 stack traces, 健康 App 崩溃报告应更清晰 | 低 |

### P3 — 低优先级 (改进/锦上添花)

| # | 类别 | 来源视角 | 文件:行 | 问题描述 | 修复难度 |
|---|------|---------|---------|---------|---------|
| 45 | **架构** | superpowers-en | `care_engine.dart` | 仅剩 30 行 enum, 应合并到 `care_strategies.dart` | 低 |
| 46 | **架构** | superpowers-en | `check_in_entity.dart:178` | `isAssessment` 用 String Set 查找, 新 scale 加入 enum 但未加 Set 会静默返 false | 低 |
| 47 | **架构** | superpowers-en | `medication_entity.dart:68-98` | `isRefillOverdue()` / `isInRefillWindow()` 的 `now` 参数有 null fallback, entity 方法应纯 | 低 |
| 48 | **架构** | superpowers-en | `notification_service.dart` | Facade 仍有 501 行, `init()` 45 行, 可抽 `NotificationInitializer` | 中 |
| 49 | **UI** | emilkowalski | `page_scaffold.dart:33` | 断点变化 (840px) 时布局 snap, 可加 `AnimatedContainer` | 低 |
| 50 | **UI** | emilkowalski | `hero_illustration.dart:62-100` | 4 个 `Positioned` offset 是 layout-critical magic numbers | 低 |
| 51 | **UI** | emilkowalski | `mood_trend_page.dart:311,382` | `const colors/labels` 在 build() 内, 应改 `static const` | 低 |
| 52 | **兼容** | flutter-spec | `build.gradle.kts:109-111` | 排除 `armeabi-v7a` (32-bit), 部分国产旧华为设备仍跑 32-bit | 低 |
| 53 | **兼容** | flutter-spec | `AndroidManifest.xml` | 缺 `android:enableOnBackInvokedCallback="true"`, Android 14+ 预测性返回手势需要 | 低 |
| 54 | **i18n** | superpowers-zh | `app_zh_Hant.arb` | 文件编码可能有问题 (PowerShell 读取出现截断乱码), 需验证 UTF-8 无 BOM | 低 |
| 55 | **半成品** | superpowers-en | `assessment_scale.dart` | NSESSS / CRDPSS 2 个量表 TODO 状态, 12 卡片中 2 张 unavailable | — |
| 56 | **半成品** | superpowers-en | `scale_translations.dart:17,45` | 16 题全文 i18n 化留 v1.0, PHQ-9 题目硬编中文 | — |
| 57 | **半成品** | superpowers-en | `medication_detail_page.dart:67,181` | `colorIndex: 0` TODO + "弹 EditMedicationDialog" TODO | — |

---

## 三、外部链接/内容隐藏状态总结

| 内容类型 | 状态 | 详情 |
|---------|------|------|
| **App 内外部 URL** | ✅ 已隐藏 | 运行时代码 0 外部 URL 泄露 |
| **App 内外部 API 调用** | ✅ 已隐藏 | 阿里云 SMS / SendGrid / 5 厂商 push 全部 feature flag 关闭 |
| **Store metadata URL** | ⚠️ 待注册 | `chroniccare.app` 域名 + 邮箱未注册 |
| **法律文档联系方式** | ✅ 已软隐藏 | `privacy@chroniccare.app` 占位, 用户通过 App 内反馈 |
| **IAP 购买入口** | ✅ 已隐藏 | `iapEnabled=false`, UI 不显示 |
| **录音功能** | ✅ 已隐藏 | `ventAudioEnabled=false`, mic 按钮不显示 |
| **紧急联系人** | ✅ 已隐藏 | `emergencyContactEnabled=false`, Setup 可选 + Settings 隐藏 |
| **BootReceiver** | ✅ 已隐藏 | `bootReceiverEnabled=false` |
| **5 厂商 Push** | ✅ 已隐藏 | `fiveVendorPushEnabled=false` |
| **硬编码中文 string** | ⚠️ 残留 4 处 | `daily_tracking_multi_chart.dart:164`, `phone_validator.dart:165`, 通知 channel const, store description |

---

## 四、上架问题总结

### Apple App Store

| 问题 | 严重性 | 状态 |
|------|--------|------|
| 域名 + 邮箱未注册 | P0 | 待外部 |
| 法律文档未律师审核 | P0 | 待外部 |
| Store description 与实际不符 | P0 | 待修 |
| 未用权限描述 (mic/speech/tracking) | P0 | 待修 |
| 无内容评级配置 | P1 | 待配 |
| IAP 声明但禁用 | P1 | 已隐藏入口 |
| 无 App Privacy Nutrition Labels | P1 | 待配 |
| `NSPhotoLibraryUsageDescription` 可能不必要 | P2 | 待评估 |

### Google Play Store

| 问题 | 严重性 | 状态 |
|------|--------|------|
| Store description 与实际不符 | P0 | 待修 |
| 无 Data Safety form | P1 | 待配 |
| `android:label` 硬编码中文 | P1 | 待修 |
| 无内容评级 | P1 | 待配 |
| 无 changelog 目录 | P2 | 待建 |
| 缺 tablet 截图 | P2 | 待截 |
| 16KB page alignment 未真机验证 | P2 | 待测 |

---

## 五、架构审视总结

### 优势
- 4 层架构 (presentation → domain ← data) + shared 层严格执行
- 17 个守护脚本 CI 化
- 隐私-by-design: SQLCipher + 零云端 + PIPL 合规
- God class 系统性拆解 (NotificationService / SafetyWatchService / DataExportService)
- 纯函数提取 + 防御性排序

### 需重构模块

| 模块 | 问题 | 建议 | 难度 |
|------|------|------|------|
| `AppDatabase.saveSetup()` | 业务逻辑在数据层 | 抽 `CompleteSetupUseCase` | 中 |
| `MoodEntryEntity` | 20 字段 god entity | 拆 `CbtThoughtRecord` + `MoodAudioAttachment` | 高 |
| `_bootstrap()` | 180 行 god function | 拆 5 个子函数 | 中 |
| `FeatureFlags` | 全局可变状态 | 改 inject 模式 | 中 |
| 日历日期工具 | 3 份重复 | 抽 `core/shared/date_utils.dart` | 低 |
| Dead code | AliyunSmsProvider + EmailService 230 行 | 移 `stubs/` | 低 |
| `VentRepositoryImpl` 构造函数 | positional optionals | 改 named params | 中 |

---

## 六、Apple Health 集成评估

### 现状
- **零 HealthKit 代码**, 无 `health` 依赖, 无权限声明
- 但本地已追踪 10 类健康数据 (mood/sleep/weight/BMI/social rhythm/anxiety/stress/treatment/medication/assessments)

### 可集成数据

| App 数据 | HealthKit 类型 | 方向 |
|---------|---------------|------|
| `sleep_entries` | `HKCategoryType.sleepAnalysis` | Write |
| `weight_entries` | `HKQuantityType.bodyMass` | Write + Read |
| `mood_entries` score | `HKCategoryType.stateOfMind` (iOS 17+) | Write |
| `exerciseMin` | `HKQuantityType.appleExerciseTime` | Read |

### 风险
- HealthKit 数据同步到 iCloud → 违反 "零云端" 原则
- 需新增 PIPL 同意种类 (`ConsentKind.healthSync`)
- 需更新 `sensitive_data_consent.md` 披露 iCloud 同步

### 预估工作量: 2-3 rounds

---

## 七、半成品/TODO 清单

| 项目 | 文件 | 状态 |
|------|------|------|
| 阿里云 SMS 真接 | `sms_service.dart` | `aliyunSmsEnabled=false`, 等法务模板审核 |
| SendGrid 邮件真接 | `email_service.dart` | `emailServiceEnabled=false`, 等 API key |
| IAP 8 元买断 | `store_kit_service.dart` | `iapEnabled=false`, 等 productId |
| 5 厂商 Push SDK | feature_flags | `fiveVendorPushEnabled=false`, 等审核 |
| Vent audio 录音 | feature_flags | `ventAudioEnabled=false`, 业务闭环不全 |
| BootReceiver | feature_flags | `bootReceiverEnabled=false`, 等 WorkManager |
| PHQ-9 16 题 i18n | `scale_translations.dart` | `phqGad7I18nEnabled=false`, 等 ARB 翻译 |
| NSESSS / CRDPSS 量表 | `scale_registry.dart` | TODO 状态, 2 张 unavailable 卡片 |
| EditMedicationDialog | `medication_detail_page.dart:181` | TODO 注释 |
| colorIndex | `medication_detail_page.dart:67` | TODO 硬编码 0 |
| 律师审核法律文档 | `assets/legal/` | 3 份文档均标记 "律师审核 ⚠️" |
| 域名注册 | fastlane metadata | `chroniccare.app` 未注册 |

---

## 八、修复优先级路线图

### Sprint A — 上架阻塞项 (P0, 预计 1-2 周)
1. 注册 `chroniccare.app` 域名 + 配置邮箱转发 (外部)
2. 委托律师审核 3 份法律文档 (外部)
3. 修复 store description 与实际功能一致 (删除已禁用功能描述)
4. 删除 Info.plist 中未用权限声明 (mic/speech/tracking)
5. 修复 `native.dart:27` SQL 注入风险
6. 修复 `daily_tracking_multi_chart.dart:164-170` 硬编码中文
7. 配置内容评级 (IARC + Apple questionnaire)

### Sprint B — 高优质量项 (P1, 预计 1-2 周)
1. 通知 channel 名 i18n 迁移 (const → `*Text({override})`)
2. `saveSetup()` 从数据库层抽到 UseCase
3. `vent_compose_page.dart:441` + `mood_audio_recorder_widget.dart:197` 性能修复
4. `hero_illustration.dart` + `mood_trend_page.dart` dark mode 修复
5. Google Play Data Safety form 填写
6. `phone_validator.dart` displayName i18n
7. `app_en.arb` 手机号 hint 本地化

### Sprint C — 架构改进 (P2, 预计 2-3 周)
1. 日历日期工具 DRY (抽 `core/shared/date_utils.dart`)
2. `SafetyConfigService` SharedPreferences 缓存
3. `MoodEntryEntity` 拆解 (CBT + Audio attachment)
4. `_bootstrap()` 拆子函数
5. `FeatureFlags` 改 inject 模式
6. Dead code 清理 (AliyunSmsProvider + EmailService → stubs/)
7. Web 目录死文件清理
8. `dart.library.html` → `dart.library.js_interop`

### Sprint D — 锦上添花 (P3, 持续)
1. 完善 icon size token scale
2. Hero illustration positioning tokens
3. `page_scaffold` 断点动画
4. `care_engine.dart` 合并
5. zh_Hant 文件编码验证
