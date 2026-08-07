# R98 7 视角审计 + 底层逐行排查 + 外链核查追加报告

**审计时间**: 2026-08-07 (R97 6 视角审计后的第 2 轮, 增补底层逐行排查 + 外链核查 2 个独立子代理)
**审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角 + 外链核查 + 底层逐行排查 共 8 个并行子代理
**审计目的**: 上架前 5 大检查项 ①外部链接隐藏 ②上架/架构/重构/半成品 ③顶层架构审视 ④底层逐行排查 ⑤开发需求文档更新
**审计基线**: v0.30.0+85, R97 6 视角审计已修 12 项代码侧 P0/P1 (check_safety 跨层 import / 主页危机 FAB / Release 签名 / USE_EXACT_ALARM / 通知权限时机 / 危机热线 tel: 拨打等)
**新发现总计**: 38 项 (P0=9 / P1=14 / P2=10 / P3=5), 其中 **22 项为 R97 未识别的新发现**, 16 项为 R97 已识别但被低估或留 R96+ 的项

---

## 0. R98 5 大检查项总结

### 检查项 ①: 外部链接隐藏 — ✅ 代码层就绪 / ⚠️ 法律文档层 9 处软隐藏待清

- **lib/ 代码层**: 0 处真实外链跳转, 4 处 https URL 全为注释, 0 个云上报 SDK, 1 处 url_launcher 调用严格限定 `tel:` 危机热线, ✅ **可直接上架**
- **assets/legal/ 法律文档层**: ⚠️ 8 处 `privacy@chroniccare.app` / `support@chroniccare.app` 软隐藏 (privacy_policy.md:150,164,214,220 + user_agreement.md:68,71,88,93), 1 处 `github.com/example/chroniccare` 占位 (user_agreement.md:68,93), 用户在「设置 → 法律与隐私」页可见
- **fastlane metadata**: ⚠️ 6 个 `privacy_url.txt` + `support_url.txt` 指向 `chroniccare.app` 未注册域名 (跟 R97-P0-3 重叠)
- **iOS/Android manifest**: ✅ 0 外部 URL scheme 注册, ATS 默认强制 HTTPS, network_security_config 禁 cleartext
- **评分**: 8.5/10 (代码层满分 10, 法律文档软隐藏扣 1.5)

### 检查项 ②: 上架/架构/重构/半成品 — 🔴 9 P0 阻塞 (4 项代码侧 + 5 项外部资源)

**上架 P0 阻塞**:
- iOS `UIBackgroundModes` `processing` 空挂 (Apple 2.5.4 拒审风险)
- iOS `InfoPlist.strings` 缺 en-US 版本 (5 项 usage description 仅中文)
- iOS `fastlane/metadata/ios/{locale}/screenshots/` 完全缺失 (Apple 4.2.1 必拒)
- Android `fastlane/metadata/android/{locale}/feature_graphic.png` + 4 张 screenshots 全是 67 字节 1×1 占位 PNG (Google Play 必拒)
- IAP "8 元买断" 描述 vs 实际 0 元免费 + iapEnabled=false 矛盾 (Apple 2.1/3.1.1)
- Data Safety Form `data_deletion_endpoint.url` 不可访问 (Google Play 第 4 步必拒)

**架构违规 (新发现)**:
- `CareEngine.evaluate` / `CareEngine.fire` 死代码 (注释承诺 v0.28 删除, v0.30 仍在, 0 处实际调用)
- 3 处 StreamProvider 缺 autoDispose (`allAssessmentEntriesProvider` / `ventSealedProvider` / `ventSealedAtProvider`)
- `core/routing/` 反向依赖 `presentation/pages/` (R97 已豁免但 trade-off 未机器校验)

**半成品 (跟 R97 重叠)**:
- SMS/Email/IAP/5 厂商 push/PHQ-9 i18n 5 项业务真接 + BootReceiver + NSESSS/CRDPSS 量表 (R97-P0-7 / R97-P2-17)
- AGENTS.md v0.30 后仍有 15+ TODO 无版本号 (R97-P2-12)

**重构机会 (新发现)**:
- `home_page_state.dart` 590 行仍偏大, `_fireCareEngine` + `_runAfterCheckIn` + `_runSafetyCheck` 3 个方法可抽 `HomeSafetyCoordinator`
- `app_database.dart` schemaVersion 注释 54 行应挪 `docs/MIGRATION_HISTORY.md`
- `SafetyCheckResult` 双 API (`displayMessage` 返 key + `displayMessageL10n(l10n)` 返翻译) 应收敛
- `ThemeExtension` 完全缺位, 30+ 颜色 helper 走 BuildContext 函数而非 M3 标准
- `ThemeModeNotifier.build` 异步改 state 应改 `AsyncNotifier`
- `routerProvider` 手写 mutable cache 应改 `NotifierProvider<RouterProfileNotifier, GoRouter>`

### 检查项 ③: 顶层架构审视 — ✅ 9.0/10 (国内中型项目天花板, 跟 R97 持平)

- **5 层架构**: domain 0 Flutter 0 Drift, `check_all.dart` 守门员强制
- **依赖方向**: presentation → domain ← data 单向, `check_cross_feature.py` 守门
- **Riverpod 3.x**: Provider<XRepository> 暴露接口 (R97-P1-1 daily_tracking 6 个 Impl 暴露违规未修)
- **隐私边界**: vent 独立表 + 架构强制不进分析/通知/关怀, 实际 grep 验证 0 渗入
- **可优化项**: UseCase 层覆盖不足 (9 repo 仅 4 usecase) / services/ 28 文件无目录分组 / `AppTokens` facade 仍 306 行 (R97-P2-4)

### 检查项 ④: 底层逐行排查 — 🔴 3 项 Major silent bug + 12 项 Minor

**3 项 Major silent bug (新发现)**:
1. `latestMoodEntryProvider` / `mood_quick_button.dart:27` / `assessment_summary_strip.dart:91` 3 处 `.first` 未显式 sort, 返回最旧而非最新 entry (违反 AGENTS.md 已知坑)
2. `home_page_state.dart:254-258` 显示 `result.displayMessage` 返 i18n **key 字符串**而非翻译文案 (用户看到 `⚠️ safetyCheckResultAlerted`)
3. `crossedMidnightSince` 用 `DateTime` 而 `nextMidnightRefresh` 用 `tz.TZDateTime`, DST 跳变点跨午夜不一致

**12 项 Minor**:
- 3 个 StreamProvider 缺 autoDispose (stream subscription 永不释放)
- main.dart 10+ 处 SizedBox / FontWeight magic number 未走 AppTokens
- `Future.wait` 结果 `as` 强转 2 处 (应改泛型 `Future.wait<T>`)
- `saveSetup` / `clearAllUserData` 可用 drift batch 优化减少 round-trip
- `moodEntriesProvider` 用 `Provider.autoDispose` 包装 StreamProvider 结果吞 loading state
- `ventRepositoryProvider` 内部传 null EncryptionService 难 mock
- `cbt_section.dart:67-68` RadioListTile 弃用 API (groupValue/onChanged)
- 0 个 golden test (60+ 自定义 widget 无视觉 regression 守护)
- a11y 实际覆盖偏少 (`Semantics()` 仅 15 处, MoodQuickButton/CheckInButton/StatCard 等核心 widget 缺包装)
- `setup_step_welcome` 手写 String? 校验未走 Form + FormState
- 104 个 trailing comma info-level warnings (test/ 下未清扫)
- 4 个文件 import 顺序违反 Effective Dart §21 (dart: 应在 package: 之前)

### 检查项 ⑤: 开发需求文档更新 — ✅ 本报告 + VERSION_1.0_PLAN.md §10 章节

---

## 1. R98 7 视角审计发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 0 | 4 | 6 | 4 | 14 | 8.5/10 (架构成熟度) |
| superpowers-en (工程) | 1 | 4 | 4 | 2 | 11 | 8/10 (规范度) |
| superpowers-zh (合规+中文) | 4 | 3 | 3 | 0 | 10 | 6.5/10 (本土化合规) |
| AppStore (iOS 上架) | 4 | 4 | 4 | 2 | 14 | 5.5/10 (上架就绪度) |
| GooglePlay (Android 上架) | 3 | 6 | 4 | 1 | 14 | 6/10 (上架就绪度) |
| flutter-specification (规范) | 0 | 5 | 4 | 1 | 10 | 8/10 (Flutter 规范遵守度) |
| 外链核查 | 0 | 2 | 2 | 0 | 4 | 8.5/10 (外链隐藏度) |
| 底层逐行排查 | 1 | 4 | 3 | 1 | 9 | 8.5/10 (代码健康度) |
| **去重后** | **9** | **14** | **10** | **5** | **38** | — |

**R98 评分对比 R97**:
- emil 9.0 → 8.5 (新发现 silent bug + 死代码扣分)
- spen 9.0 → 8 (新发现 0 golden test + a11y 不足扣分)
- spzh 4.5 → 6.5 (R97 修了 FAB 危机入口, 但 PHQ-9 弹窗仍无拨打 + i18n 仍是 P0)
- AppStore 6.5 → 5.5 (新发现 processing 空挂 + 截图完全缺失)
- GooglePlay 40% → 60% (R97 修了 USE_EXACT_ALARM + 签名, 但 16KB 未实测 + 截图占位)
- flutter-spec 88% → 80% (新发现 ThemeExtension 缺位 + Riverpod 反模式)
- 外链 8.5/10 (新视角)
- 底层代码健康度 8.5/10 (新视角)

---

## 2. R98 P0 必修清单 (9 项, 上架/v1.0 blocker)

| R98 ID | 问题 | 类别 | 难度 | 视角 | 跟 R97 关系 | 文件 |
|---|---|---|---|---|---|---|
| **R98-P0-1** | PHQ-9 危机弹窗内无"立即拨打"按钮 (6 步操作路径: 弹窗"我知道了" → 返回评估页 → 返回主页 → 找热线 FAB → 进热线页 → 拨打), 精神心理患者危机时刻执行功能受损 = 精神心理专科 App P0 阻断 | 底层 | low | spzh | **新发现** (R97-P0-2 修的是 FAB 可见性, 这里是弹窗内 action) | [assessment_page.dart#L185-L246](file:///d:/Batch/chroniccare/lib/presentation/pages/assessment/assessment_page.dart) |
| **R98-P0-2** | PHQ-9 i18n flag 关闭时 zh_Hant/en 用户做 PHQ-9 看简体中文题目 (`FeatureFlags.phqGad7I18nEnabled=false` + `phq9.dart:170-185` 走 const 中文 fallback) = 医疗法律责任 | 架构 | high | spzh | R97-P2-17 升级为 P0 | [phq9.dart#L170](file:///d:/Batch/chroniccare/lib/domain/logic/phq9.dart) |
| **R98-P0-3** | iOS `UIBackgroundModes` 声明 `processing` 但 `handleSafetyCheckTask` 空实现 (仅 `setTaskCompleted(success: true)`), Apple 2.5.4 "Multitasking apps may only use background services for their intended purposes" 拒审风险 | 底层 | medium | AppStore | **新发现** | [Info.plist#L144](file:///d:/Batch/chroniccare/ios/Runner/Info.plist) + [AppDelegate.swift#L72](file:///d:/Batch/chroniccare/ios/Runner/AppDelegate.swift) |
| **R98-P0-4** | iOS `fastlane/metadata/ios/{zh-Hans,zh-Hant,en-US}/screenshots/` 完全缺失, Apple 4.2.1 强制至少 6.7" iPhone 截图 = 必拒 | 架构 | medium | AppStore | **新发现** (R97-P3-1 升级为 P0) | [fastlane/metadata/ios/](file:///d:/Batch/chroniccare/fastlane/metadata/ios/) |
| **R98-P0-5** | Android `fastlane/metadata/android/{zh-CN,en-US}/feature_graphic.png` + 4 张 `phone_screenshots/screenshot_{1-4}.png` 全是 67 字节 1×1 占位 PNG, Play Console 要求 1024×500 + ≥320px 宽截图 = 必拒 | 架构 | medium | GooglePlay | **新发现** | [fastlane/metadata/android/zh-CN/feature_graphic.png](file:///d:/Batch/chroniccare/fastlane/metadata/android/zh-CN/feature_graphic.png) |
| **R98-P0-6** | Data Safety Form `data_deletion_endpoint.url = 'https://chroniccare.app/delete-data-instructions'` 不可访问, Play Console Data Safety 第 4 步必拒 | 架构 | high | GooglePlay | **新发现** (跟 R97-P0-3 同源: 域名未注册) | [scripts/generate_data_safety_form.py#L84](file:///d:/Batch/chroniccare/scripts/generate_data_safety_form.py) |
| **R98-P0-7** | 5 厂商 push SDK (小米/华为/OPPO/vivo/魅族) 未真接, `FeatureFlags.fiveVendorPushEnabled=false`, 国产 ROM 静默杀后台场景下失联通知 100% 失效 = 中国市场 v1.0 P0 业务依赖 | 架构 | high | spzh | **新发现** (跟 R97-P0-7 部分重叠) | [feature_flags.dart#L66](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) |
| **R98-P0-8** | PHQ-9 total ≥ 20 (重度抑郁) 但 Q9=0 时不触发危机资源 dialog, 仅 `urgentDoctorVisit` getter 显示文字"强烈建议就医", 临床实践上重度抑郁即便无自杀念头也应弹危机资源 | 架构 | medium | spzh | **新发现** | [phq9.dart#L156](file:///d:/Batch/chroniccare/lib/domain/logic/phq9.dart) |
| **R98-P0-9** | `CareEngine.evaluate` / `CareEngine.fire` 死代码 (注释承诺 v0.28 删除, 当前 v0.30 仍在, grep 全 lib/ 0 处实际调用), 仍可被误用 | 架构 | medium | 底层排查 | **新发现** | [care_engine.dart#L59-L162](file:///d:/Batch/chroniccare/lib/domain/logic/care_engine.dart) |

---

## 3. R98 P1 重要清单 (14 项, 上架前应修)

| R98 ID | 问题 | 类别 | 难度 | 视角 | 文件 |
|---|---|---|---|---|---|
| **R98-P1-1** | `latestMoodEntryProvider` / `mood_quick_button.dart:27` / `assessment_summary_strip.dart:91` 3 处 `.first` 未显式 sort, drift `watchAll()` 默认插入序, Provider 名 `latest` 实际返回最旧 entry = silent bug | 底层 | low | 底层排查 | [cbt_rerated_entries_provider.dart#L50](file:///d:/Batch/chroniccare/lib/presentation/providers/cbt_rerated_entries_provider.dart) |
| **R98-P1-2** | `home_page_state.dart:254-258` 显示 `result.displayMessage` 返 i18n **key 字符串**而非翻译文案, 用户看到 `⚠️ safetyCheckResultAlerted` 而非中文 = 真实 UI bug | 底层 | low | emil | [home_page_state.dart#L256](file:///d:/Batch/chroniccare/lib/presentation/pages/home/home_page_state.dart) |
| **R98-P1-3** | `crossedMidnightSince` 用 `DateTime` 而 `nextMidnightRefresh` 用 `tz.TZDateTime`, DST 跳变点跨午夜不一致, 海外用户跨日 bug | 底层 | low | emil | [app.dart#L75](file:///d:/Batch/chroniccare/lib/app.dart) |
| **R98-P1-4** | 3 个 StreamProvider 缺 autoDispose (`allAssessmentEntriesProvider` / `ventSealedProvider` / `ventSealedAtProvider`), stream subscription 永不释放 | 底层 | low | emil | [assessment_providers.dart#L34](file:///d:/Batch/chroniccare/lib/presentation/providers/assessment_providers.dart) |
| **R98-P1-5** | iOS `ios/Runner/Base.lproj/InfoPlist.strings` 缺 en-US 版本, 5 项 NSXxxUsageDescription 仅中文, en-US 审核员看到中文可能要求英文版 | 底层 | medium | AppStore | [ios/Runner/Base.lproj/InfoPlist.strings#L10](file:///d:/Batch/chroniccare/ios/Runner/Base.lproj/InfoPlist.strings) |
| **R98-P1-6** | IAP "8 元买断" 描述 vs 实际 0 元 + iapEnabled=false 矛盾 (R97-P1-5 未修, AppStore 报告仍 flag 为 Major) | 底层 | medium | AppStore | [user_agreement.md#L22](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md) |
| **R98-P1-7** | iOS `subtitle.txt` + `description.txt` 提"失联通知规划中/即将上线", Apple 2.3.10 不允许 subtitle/description 提未实际可用的功能 | 架构 | low | AppStore | [fastlane/metadata/ios/zh-Hans/subtitle.txt](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/subtitle.txt) |
| **R98-P1-8** | `setup_legal_dialog.dart:110` 硬编码中文 "🆘 心理危机干预热线 (24h)" 直接写入 `Text()`, en-US / zh-Hant 用户看到中文, 跟 R83 已 i18n 化的 12 个 crisisHotline* ARB key 不一致 | 底层 | low | AppStore | [setup_legal_dialog.dart#L110](file:///d:/Batch/chroniccare/lib/presentation/pages/setup/setup_legal_dialog.dart) |
| **R98-P1-9** | `assets/legal/` 8 处软隐藏 `privacy@chroniccare.app` / `support@chroniccare.app` + 1 处 `github.com/example/chroniccare` 占位, PIPL §52 要求开发者披露有效联系方式, 软隐藏 = 实质未提供 | 架构 | medium | spzh + 外链核查 | [privacy_policy.md#L150](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md) |
| **R98-P1-10** | `ConsentGate` 仅检查 `isWithdrawn(ConsentKind)` boolean, 不验证 `ConsentArtifact.version` 与当前 `legalVersionProvider` 一致, 法律文档升级后旧版本同意的用户不会被强制重新同意 = PIPL §17 数据准确性违反 | 架构 | medium | spzh | [consent_gate.dart#L46](file:///d:/Batch/chroniccare/lib/core/shared/consent_gate.dart) |
| **R98-P1-11** | `setup_page_state.dart:459-464` `recordConsent` 只记录 2 个版本号, 未记录 `sensitiveDataConsentAt` 时间戳, 也未持久化 setup 阶段收集的 `emergencyContactSharing` ConsentArtifact | 底层 | medium | spzh | [setup_page_state.dart#L459](file:///d:/Batch/chroniccare/lib/presentation/pages/setup/setup_page_state.dart) |
| **R98-P1-12** | `assets/legal/sensitive_data_consent.md` §4 撤回方式写"失联通知功能规划中, 无可关闭项", 但 `legal_page.dart` UI 实际有"撤回失联通知同意" toggle = 文档与 UI 不一致 | 架构 | low | spzh | [sensitive_data_consent.md#L55](file:///d:/Batch/chroniccare/assets/legal/sensitive_data_consent.md) |
| **R98-P1-13** | `crossedMidnightSince` + 3 处其他位置用 `DateTime` 而非 `tz.TZDateTime`, 跟 R97-P3-7 部分重叠但具体到 DST 不一致 (4 处混用) | 底层 | low | emil + spen | [app.dart#L75](file:///d:/Batch/chroniccare/lib/app.dart) |
| **R98-P1-14** | `scripts/check_zh_hant_consistency.py:37-49` 仅用 OpenCC `s2tw` 做**字符级**简繁转换, 不检 phrase conversion (信息→資訊 / 软件→軟體 / 默认→預設 / 网络→網路), 医疗 App 文案精确性要求高 | 架构 | medium | spzh | [scripts/check_zh_hant_consistency.py#L37](file:///d:/Batch/chroniccare/scripts/check_zh_hant_consistency.py) |

---

## 4. R98 P2 建议清单 (10 项, v1.0+ 可做)

| R98 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R98-P2-1** | `ThemeExtension` 完全缺位, 30+ 颜色 helper 走 `BuildContext` 函数而非 M3 标准 `Theme.of(context).extension<T>()!`, 不能在 const constructor 用 | 架构 | high | flutter-spec |
| **R98-P2-2** | `routerProvider` 用 `ref.read` + 自定义 `_RouterProfileCache` mutable class + `ref.listen` 手动同步 cache, Riverpod 反模式, 应改 `NotifierProvider<RouterProfileNotifier, GoRouter>` | 架构 | medium | flutter-spec |
| **R98-P2-3** | `ThemeModeNotifier.build()` 返回 `ThemeMode.system` 后异步 `_load()` 改 `state`, Riverpod 3.x `Notifier.build` 应同步返回初始 state, 异步初始化应用 `AsyncNotifier` | 架构 | medium | flutter-spec |
| **R98-P2-4** | `app_theme.dart` textTheme 只设 6 个 style (displayLarge/Medium, bodyLarge/Medium, labelLarge/Medium), M3 spec 13 个 (display/headline/title/body/label × Large/Medium/Small) 没设全, fallback 到 M3 默认 (Roboto) 跟项目 token 不一致 | 架构 | medium | flutter-spec |
| **R98-P2-5** | `setup_step_welcome` + `setup_step_medication` 手写 String? 校验 + TextField 无 validator, 应走 `Form` + `GlobalKey<FormState>` + `TextFormField` Flutter 官方模式 | 架构 | medium | flutter-spec |
| **R98-P2-6** | 0 个 golden test (60+ 自定义 widget 无视觉 regression 守护), M3 主题切换 + AppTokens 改值无视觉验证 | 架构 | medium | spen |
| **R98-P2-7** | a11y 实际覆盖偏少, `Semantics()` 仅 15 处, MoodQuickButton/CheckInButton/StatCard/TrendHeatmapGrid 等核心 widget 缺 `AppSemantics.*` 包装 | 底层 | medium | spen |
| **R98-P2-8** | `analysis_options.yaml` 未启用 `directives_ordering` lint, 4 个文件 import 顺序违反 Effective Dart §21 (dart: 应在 package: 之前) | 底层 | low | spen |
| **R98-P2-9** | `fastlane/metadata/android/zh-CN/title.txt` 66 字节超 Play 30 字符限制, "慢病管家 - 吃药打卡 + 情绪关怀(失联通知规划中)" 截断或拒 | 底层 | low | GooglePlay |
| **R98-P2-10** | `setup_step_consent.dart:112-118` 第 4 个勾选 (年龄严正声明) 的 `onView: () {}` 为空, 用户点击"查看"无反应, 其他 3 个协议都有文档可看 | 底层 | low | spzh |

---

## 5. R98 P3 nice-to-have 清单 (5 项)

| R98 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R98-P3-1** | main.dart 10+ 处 SizedBox / FontWeight magic number 未走 AppTokens.spacingXxx / textStyle | 底层 | low | 底层排查 |
| **R98-P3-2** | `Future.wait` 结果 `as` 强转 2 处 (`reminder_scheduler.dart:119` + `report_tile.dart:97`), 应改泛型 `Future.wait<T>` | 底层 | low | 底层排查 |
| **R98-P3-3** | `saveSetup` / `clearAllUserData` 用 for-loop 逐条 insert/delete, 可改 `batch((b) => b.insertAll(...))` 减少 DB round-trip | 底层 | low | 底层排查 |
| **R98-P3-4** | `cbt_section.dart:67-68` RadioListTile 仍用 `groupValue` + `onChanged` 弃用 API (Flutter 3.32+ 提示用 RadioGroup) | 底层 | low | spen |
| **R98-P3-5** | 104 个 trailing comma info-level warnings (test/ 下未清扫), 应跑 `dart fix --apply` 配合 | 底层 | low | spen |

---

## 6. R98 跨视角共识高频项 (3+ 视角同意)

| # | 问题 | 视角数 | 类别 | 难度 |
|---|---|---|---|---|
| 1 | PHQ-9 量表 i18n + 临床判定逻辑 (Q9 ≥1 弹窗无拨打 + ≥20 不弹) | 3 (spzh/AppStore/底层) | 架构+底层 | medium |
| 2 | 法律文档"草稿未经律师过审" + 联系方式软隐藏 (PIPL §52) | 3 (spzh/AppStore/GooglePlay/外链) | 架构 | high |
| 3 | 域名 chroniccare.app 未注册 (隐私 URL / Data Safety Form / 联系邮箱 全失效) | 4 (spzh/AppStore/GooglePlay/外链) | 底层 | medium |
| 4 | iOS + Android 截图完全缺失 / 占位 PNG | 2 (AppStore/GooglePlay) | 架构 | medium |
| 5 | SMS/Email/IAP/5 厂商 push 业务真接阻塞 | 3 (spzh/spen/AppStore) | 架构 | high |
| 6 | 跨时区 DateTime 不一致 (DST bug) | 2 (emil/spen) | 底层 | low |

---

## 7. R98 修复路径建议 (按优先级)

### 第 1 周 (解锁代码侧 P0, 估 8-12 commit)

1. **R98-P0-1** PHQ-9 危机弹窗加"立即拨打"按钮 — 1h, 修 `_showCrisisDialog` 加 `url_launcher` tel: 按钮
2. **R98-P0-3** iOS 删 `processing` 后台模式 + BGTaskSchedulerPermittedIdentifiers + AppDelegate register 代码 — 30 分钟
3. **R98-P0-9** 删 `CareEngine.evaluate` / `CareEngine.fire` 死代码 + 同步删 LEGACY_API_NOTES.md — 1h
4. **R98-P1-1** 3 处 `.first` 加显式 `..sort((a, b) => b.timestamp.compareTo(a.timestamp))` — 30 分钟
5. **R98-P1-2** `home_page_state.dart:254-258` 改用 `result.displayMessageL10n(AppLocalizations.of(context))` — 5 分钟
6. **R98-P1-3** `crossedMidnightSince` 改用 `tz.TZDateTime` 跟 `nextMidnightRefresh` 统一 — 30 分钟
7. **R98-P1-4** 3 个 StreamProvider 加 `.autoDispose` — 10 分钟
8. **R98-P1-8** `setup_legal_dialog.dart:110` 硬编码中文改走 `AppLocalizations.crisisHotlineSectionTitle` ARB key — 30 分钟
9. **R98-P2-10** `setup_step_consent.dart:112-118` 第 4 个勾选的 `onView` 跳转到严正声明文档页 — 30 分钟

### 第 2 周 (修 P1, 估 6-10 commit)

10. **R98-P1-5** 新建 `ios/Runner/en.lproj/InfoPlist.strings` 翻译 5 项 usage description + pbxproj PBXVariantGroup 加 en 引用 — 2h
11. **R98-P1-6** 统一 IAP 描述 (改 user_agreement §3 + README §商业模式 或真接 productId) — 1h
12. **R98-P1-7** 删 `subtitle.txt` + `description.txt` 中"规划中/即将上线"措辞 — 30 分钟
13. **R98-P1-9** 清理 `assets/legal/` 8 处软隐藏邮箱 + 1 处 GitHub 占位 — 1h
14. **R98-P1-10** `ConsentGate` 加 `version` 一致性校验 + 法律版本升级强制重走同意流 — 4h
15. **R98-P1-11** `recordConsent` 补 `sensitiveDataConsentAt` + 持久化 `emergencyContactSharing` ConsentArtifact — 2h
16. **R98-P1-12** 同步 `sensitive_data_consent.md` §4 文档跟 UI 一致 — 30 分钟
17. **R98-P1-14** `check_zh_hant_consistency.py` 加 phrase-level 词典校验 — 4h

### 第 3-4 周 (外部资源并行 + P2 降风险, 估 10-20 commit)

18. **R98-P0-4** iOS 截图: 模拟器跑 `flutter run -d iphone` + 截 6.7"/6.1"/5.5" iPhone + 12.9" iPad 各 1-3 张 — 4-8h
19. **R98-P0-5** Android feature_graphic 1024×500 + 4 张 phone_screenshots 真机截 — 4-8h
20. **R98-P0-2** PHQ-9/GAD-7 16 题完整 ARB 翻译后翻 `phqGad7I18nEnabled=true` — 1-2 周
21. **R98-P0-6** 域名注册 + 部署隐私政策/支持页面到 chroniccare.app — 1-2 天注册 + 7-20 天 ICP 备案
22. **R98-P0-7** 5 厂商 push SDK 申请 + 集成 — 1-2 月审核期
23. **R98-P0-8** PHQ-9 ≥20 加 `CrisisSignal.Kind.severe` 类型, 弹不同文案 — 2h
24. **R98-P2-1** ThemeExtension 重构 (30+ 颜色 helper 迁移到 `Theme.of(context).extension<T>()`) — 2-3 天
25. **R98-P2-2** `routerProvider` 改 `NotifierProvider` — 1 天
26. **R98-P2-3** `ThemeModeNotifier` 改 `AsyncNotifier` — 4h
27. **R98-P2-5** setup 表单迁到 `Form` + `TextFormField` + `validator` — 1 天
28. **R98-P2-6** 给 8-10 个核心 widget 加 golden test (light + dark) — 2-3 天

### v1.0 前 (P3 nice-to-have)

29. main.dart magic number 走 AppTokens
30. `Future.wait<T>` 泛型化
31. drift batch 优化
32. 弃用 API 迁移
33. trailing comma 清扫
34. directives_ordering lint 启用
35. a11y 核心 widget 加 AppSemantics 包装
36. textTheme 补全 13 个 style

---

## 8. R98 跟 R97 路线图对应关系

| R98 发现 | R97 状态 | R98 后状态 |
|---|---|---|
| R98-P0-1 PHQ-9 弹窗无拨打 | R97 修了 FAB 可见性, 弹窗内 action 未识别 | **新发现, 必修** |
| R98-P0-2 PHQ-9 i18n flag 关 | R97-P2-17 (P2) | R98 升级 P0 (医疗法律责任) |
| R98-P0-3 iOS processing 空挂 | R97 未识别 | **新发现, 必修** |
| R98-P0-4 iOS 截图缺失 | R97-P3-1 (P3) | R98 升级 P0 (4.2.1 必拒) |
| R98-P0-5 Android 截图占位 | R97 未识别 | **新发现, 必修** |
| R98-P0-6 Data Safety Form | R97-P0-3 同源 (域名) | 持平 (具体到 data_deletion_endpoint) |
| R98-P0-7 5 厂商 push | R97-P0-7 (SMS/Email) | 部分重叠 (push 跟 SMS 不同) |
| R98-P0-8 PHQ-9 ≥20 不弹 | R97 未识别 | **新发现, 必修** |
| R98-P0-9 CareEngine 死代码 | R97 未识别 | **新发现, 必修** |
| R98-P1-1 .first 隐式排序 | R97-P2-3 (P2) | R98 升级 P1 (silent bug) |
| R98-P1-2 displayMessage i18n key | R97 未识别 | **新发现, 必修** |
| R98-P1-3 DST 不一致 | R97-P3-7 (P3) | R98 升级 P1 (海外用户 bug) |
| R98-P1-4 StreamProvider autoDispose | R97 未识别 | **新发现, 必修** |
| R98-P1-9 法律文档软隐藏 | R97-P2-11 (P2) | R98 升级 P1 (PIPL §52) |
| R98-P1-10 ConsentGate version 校验 | R97 未识别 | **新发现, 必修** |
| R98-P1-14 zh_Hant phrase 一致性 | R97-P3-13 (P3 commonSave) | R98 升级 P1 (医疗文案精确性) |

**R98 新发现总计**: 22 项 (P0=5 / P1=8 / P2=6 / P3=3), 16 项为 R97 已识别但被低估或留 R96+ 的项升级

---

## 9. R98 上架风险评估

**整体上架就绪度**: ~50% (R97 修 12 项后 ~50%, R98 新发现 9 P0 抵消改善, 持平)

**Apple App Store 风险**: 🔴 高 — 5 项必拒 (processing 空挂 + 截图缺失 + 隐私 URL 404 + IAP 描述矛盾 + InfoPlist.strings 缺 en-US)
**Google Play 风险**: 🔴 高 — 4 项必拒 (feature_graphic 占位 + 截图占位 + Data Safety URL 不可访问 + 隐私政策律师未过审)

**建议路径**:
- v0.30 不上 store (R98 9 P0 全部阻塞)
- 第 1 周修 R98-P0-1/3/9 + R98-P1-1/2/3/4/8 共 8 项代码侧修复 (无需外部资源)
- 第 2 周修 R98-P1-5/6/7/9/10/11/12/14 共 8 项代码侧修复 (无需外部资源)
- 并行启动 R98-P0-2 (PHQ-9 i18n 1-2 周) + R98-P0-4/5 (截图 4-8h) + R98-P0-6 (域名 7-20 天 ICP) + R98-P0-7 (5 厂商 push 1-2 月)
- 最早 M6 (2026-11-15) 4 项外部资源并行完成后上 store

---

**R98 7 视角审计 + 底层逐行排查 + 外链核查追加完成时间**: 2026-08-07
**R98 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角 + 外链核查 + 底层逐行排查 共 8 个并行子代理
**R98 发现总计**: 38 项 (P0=9 / P1=14 / P2=10 / P3=5)
**R98 新发现**: 22 项 (R97 路线图未覆盖)
**下次 dev doc 同步**: R98 P0/P1 修复完成后 (估 2-4 周)
