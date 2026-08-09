# chroniccare v0.27.0+62 — 七视角深度审视整合报告

> **日期**：2026-07-31
> **执行人**：Mavis (root session `mvs_13726450b44e4bd2a66f686b2cf7fce1`)
> **范围**：emil / superpowers-en / superpowers-zh / AppStore / GooglePlay / 阿里巴巴开发规范 / Flutter 开发规范 — 7 个独立视角
> **基础**：
> - `reports/CONSOLIDATED-AUDIT-v0.27.md`（700+ 行综合审计）
> - `docs/reviews/2026-07-31-three-lens/{consolidated,emil-v0.27+,spen-v0.27+}.md`（3 视角 + 整合）
> - `docs/CHANGELOG.md` Unreleased（R62 修正起点）
> - `AGENTS.md`（项目代码视角导览）
> **状态标注**：✅ 已修 / 🔶 部分修 / ⏳ 未修 / 🆕 本轮新发现
> **优先级**：P0（必修复才能上架/数据/安全/崩溃）/ P1（重要隐患/功能错误）/ P2（工程卫生/边界 case）/ P3（nit/风格）
> **修复难度**：S（< 1h）/ M（1-4h）/ L（1-3 day）/ XL（外部依赖 1 周+）
> **视角来源**：
> - **emil** = emilkowalski skill（设计工程）
> - **spen** = superpowers-en skill（英文上游方法论：TDD / 隐式排序 / DateTime race / null safety / dispose 完整性）
> - **spzh** = superpowers-zh skill（中文 / 合规 / PIPL / 命名 / 提交规范）
> - **appstore** = Apple App Store Review Guidelines 5.x + HIG + 4.3 医疗 App
> - **googleplay** = Google Play Console + Developer Policy + 国产 ROM 自检
> - **alibaba** = 阿里巴巴 Java 开发手册（泰山版 2020）+ 前端手册（2022）
> - **flutter** = Effective Dart + Flutter Best Practices + Material 3

---

## 0. 元信息：执行方式说明

> **本次成功拉到 7 个 sub-agent 并行审视**（上次 3 视角 sub-agent 全 stack overflow 失败，本轮 7 个 sub-agent 全部成功，**关键改进**：(1) 共享上下文文档约束扫描范围 (2) 强制 ripgrep 模式 + 关键文件 read (3) 输出 ≤ 30KB (4) 输出格式统一化）。

---

## 1. 一页总览

### 1.1 7 视角评分汇总

| 视角 | 评分 | 核心强项 | 最大短板 |
|---|---|---|---|
| **emil**（设计工程） | ⭐⭐⭐⭐ (4/5, **41/44**) | Token 集中化 ~90% / MotionScheme 4 档 / Timer+dispose 100% | main.dart 9 处裸 `Colors.orange/red` + 4 处 inline TextStyle + 30+ 处裸 spacing |
| **spen**（英文方法论） | ⭐⭐⭐⭐ (34/40) | 0 P0 隐式排序 / 0 P0 BuildContext race / 0 P0 dispose leak / TDD 1098→1151 cases | P0-1 SmsGateway 仍 throw UnimplementedError + 2 个 facade 待拆收尾 + use case 层弱化 |
| **spzh**（中文 + 合规） | ⭐⭐⭐ (3.7/5) | 提交规范 100% / PUA 0 / 繁简 100% / ARB 同步 100% / 16+1 守护全绿 | P0-2 联系人同意**留痕只 log 不写表** / 量表 PHQ-9 / GAD-7 16 题 + 9 档严重度 + 6 region 危机电话 label 100% 硬编中文 |
| **appstore**（iOS 上架） | **上架就绪度 3.5/10** | Info.plist 4 NSUsageDescription / PrivacyInfo.xcprivacy 4 required-reason / iPad 多任务 / SQLCipher | **法务 / IAP / 元数据 / TestFlight 4 维 0-30% ready** / ITSAppUsesNonExemptEncryption 缺 / Runner.entitlements 不存在 |
| **googleplay**（Android 上架） | **上架就绪度 3.0/10** | targetSdk=36 / minSdk=24 / ProGuard 启用 / 国产 ROM 自检卡 5 品牌 / 4 必声明权限 | **release 用 debug 签名** / `fastlane/metadata/` 0 文件 / 隐私政策仅 assets 3 件 P0 |
| **alibaba**（阿里规范） | ⭐⭐⭐⭐ (4.2/5) | A7 控制 5/5 / A9 异常 5/5 / A11 DB 5/5 / 7 DAO 拆 559→<100 行标杆 | A2 常量 (3/5) 9 处魔法值 + A4 OOP (4/5) 3 god class |
| **flutter**（Flutter 规范） | ⭐⭐⭐⭐ (4.2/5) | Effective Dart 强 / M3 强 / Riverpod 3.x 强 / 性能 disposal 强 / i18n 强 5/5 | 5 微观违规：硬编码颜色 4 处 / `library;` 10+ 处 / `ElevatedButton` 9 处未迁 / `.then()` 2 处 / `RepaintBoundary` 0 处 |

### 1.2 问题总览（去重 + 跨视角共识后）

| 指标 | 数值 | 备注 |
|---|---|---|
| **总问题** | **123** 条独立项（7 视角原始汇总，**去重后约 50 条**，以下展示关键项） | emil 12 + spen 18 + spzh 18 + appstore 26 + googleplay 21 + alibaba 23 + flutter 14 |
| **架构级** | 25 条 | 跨多个视角共识的 5 条 + 单一视角发现的 20 条 |
| **底层级** | 98 条 | 各自有 `文件:行` 定位 |
| **P0（必修）** | **17 条** | 跨 7 视角最阻塞项 |
| **P1（重要）** | **38 条** | 1-4 周内修 |
| **P2（建议）** | **47 条** | v1.0 前 |
| **P3（nit）** | **21 条** | 风格 / 文档一致性 |
| **修复难度 S (<1h)** | 56 | 1 周内可批量修 |
| **修复难度 M (1-4h)** | 47 | 1 个 sprint |
| **修复难度 L (1-3 day)** | 16 | 1-2 周 |
| **修复难度 XL（外部依赖）** | 4 | 1-2 月（法务 + 阿里云 + 律师 + 域名） |
| **上架就绪度 (iOS)** | 3.5/10 | 距上架 2-3 月 |
| **上架就绪度 (Android)** | 3.0/10 | 距上架 1-2 月（更顺） |

### 1.3 3 行总评

1. **架构稳定，4 层 + 5 umbrella 优秀；修复重点不在"换架构"，而在"清半成品 + 补上架"** — 5 视角共识（emil/spen/alibaba/flutter/spzh）：4 层架构不需切换，替代方案（Hexagonal/Clean/DDD）成本>收益；架构级 P0 只有 1 个（P0-2 PIPL §13 留痕未落库），其余都是微观收尾。
2. **P0 高度集中在 3 个"半修"陷阱**：(1) **P0-1 SmsGateway** `throw UnimplementedError`（6 视角共识：spen/alibaba/flutter/appstore/googleplay/spzh 全部发现）；(2) **P0-2 PIPL §13 联系人同意** API 强制了但 DB 落库未做（4 视角：spzh/alibaba/appstore/googleplay）；(3) **上架"非代码"环节** 法务 / 域名 / 邮箱 / 截图 / 元数据 / 签名（4 视角：spzh/appstore/googleplay/alibaba）。
3. **上架双平台离 1.0 还差 2-3 月**：iOS 9 个 P0 + 10 个 P1（最大阻塞：法务 + IAP + 建站 3 件并行），Android 5 个 P0 + 7 个 P1（最大阻塞：release 签名 + 元数据仓库 + 隐私 URL + 隐私邮箱 + BootReceiver）；3 个月可达 8.5/10 上架就绪度。

---

## 2. 顶层架构审视（跨视角共识）

### 2.1 架构健康度（7 视角共识）

| 维度 | 评分 | 共识理由 |
|---|---|---|
| **4 层 + 5 umbrella 架构** | ⭐⭐⭐⭐⭐ | emil/spen/alibaba/flutter 4 视角全高分；4 层 + `core/{data,shared,theme,routing,l10n}/` 5 umbrella 是最佳平衡 |
| **domain 0 flutter 0 drift 边界** | ⭐⭐⭐⭐⭐ | 4 视角共识 + `check_all.dart` 守护脚本验证 |
| **7 DAO 拆分 (R53a)** | ⭐⭐⭐⭐⭐ | spen/alibaba 共识：559→<100 行 × 7 = 阿里"god class 拆分"标杆 |
| **Riverpod 3.x + drift 2.20 + go_router 14.6** | ⭐⭐⭐⭐⭐ | 4 视角共识：技术栈选择得当 |
| **TDD 1098→1151 cases 覆盖** | ⭐⭐⭐⭐ | spen：高覆盖率 + R60 21 case crisis test + R56b-R56e +57 cases |
| **i18n 574 keys / 3 语 / 0 orphan** | ⭐⭐⭐⭐⭐ | spzh/flutter 共识：ARB 同步 + 繁简一致 + 类型安全 |
| **Token 集中化 90%+** | ⭐⭐⭐⭐ | emil/flutter：800 行 `app_tokens.dart` 单点入口，剩 main.dart 9 处漏 |
| **dispose 完整性 + Timer+dispose 100%** | ⭐⭐⭐⭐⭐ | emil/spen/flutter 共识：R62 P1-6 修 Future.delayed→Timer |
| **国产 ROM 自检** | ⭐⭐⭐⭐ | googleplay：5 品牌引导 + SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS 齐 |

### 2.2 顶层重构建议（5 视角共识 / 高内聚低耦合）

> **结论**：5 视角**不推荐切换到** Hexagonal/Clean/DDD/6 层阿里架构。4 层 + 5 umbrella 已是最佳平衡。推荐 3 个微观改造：

| # | 模块 | 现状 | 建议 | 视角 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| **A1** | **use case 层补** | `lib/domain/usecases/` 仅 1 文件 (check_in_usecases.dart 3025 字节),业务编排堆在 service (`CareEngine.fire()` / `SafetyWatchService._checkAndAlert()` / `RefillNotifier.scheduleRefillReminder()`) | 抽 `FireCareStrategy` / `CheckSafety` / `ScheduleRefillReminder` 3 个 use case,presentation 调 use case 而非 service | spen + alibaba | M | P2 |
| **A2** | **P0-1 SmsGateway abstract 抽离** | `sms_service.dart:83, 156, 171` 仍 `throw UnimplementedError`（R38 修过文案但底层 throw） | 抽 `SmsGateway` interface + `MockSmsGateway`（dev）+ `AliyunSmsGateway`（real, v1.0+）+ `NoopSmsGateway`（release 前）+ 构造注入 + `validateForRelease` 真验证 | spen + alibaba + flutter + appstore + googleplay + spzh (**6 视角共识**) | **L** | **P0** |
| **A3** | **P0-2 PIPL §13 联系人同意留痕** | `ContactRepositoryImpl.add` 只 `piiSafeLog` 不写表；`Contact` 表 0 consent 字段；`schemaVersion=14` 未 bump | 加 `Contacts` 表 4 个字段（`consentAt` / `consentKind` / `consentBy` / `consentVersion`）,bump `schemaVersion=15` + migration + 改 `into(contacts).insert(ContactsCompanion(..., consentAt: Value(consent.grantedAt), ...))` | spzh + alibaba + appstore + googleplay (**4 视角共识**) | **M** | **P0** |
| **A4** | **ConsentKind 双 enum 统一** | domain `{emergencyContactSharing, dataExport}` vs presentation `{safety, vent, analytics}` 同名不同值 | domain `ConsentKind` 加 3 值 + presentation import domain,删重复 enum | spzh | M | **P0** |
| **A5** | **`mood_recorder.dart` 562 行 god page 拆** | 1 文件 5 widget tree（录音 / 计时 / 波形 / 播放 / 提交） | 拆 4 文件（顶层 + 录音 + 回放 + 提交 panel） | emil + alibaba + spen | L | P2 |
| **A6** | **`safety_watch_service.dart` 354 行 god service** | 5 职责 facade + 1 入口 `_checkAndAlert` 122 行 | 抽 `_buildContacts` / `_dispatchAlerts` / `_notify` 3 private method + 拆 `SafetyDetector` 纯函数 + facade 协调 | spen + alibaba | M | P1 |
| **A7** | **`app_tokens.dart` 644 行 god constant 拆** | 1 文件 4 大类 100+ token（颜色 60+ / 字号 14 / 间距 10 / 圆角 8 / 动效 8 / alpha 12 / shadow 6 / 业务 10） | 拆 `app_colors.dart` + `app_typography.dart` + `app_spacing.dart` + `app_motion.dart` 4 文件 | alibaba | M | P2 |

### 2.3 架构级问题（按修复优先级排，跨视角）

| 序 | 视角 | 架构项 | 状态 | 难度 | 优先级 |
|---|------|--------|------|------|--------|
| **1** | 6 视角共识 | **P0-1 SmsGateway abstract 抽离** | ⏳ 仍 throw | L | **P0** |
| **2** | 4 视角共识 | **P0-2 PIPL §13 留痕** | 🔶 API 强制了,落库未做 | M | **P0** |
| **3** | spzh + alibaba | **A4 ConsentKind 双 enum 统一** | ⏳ 仍 2 enum | M | **P0** |
| **4** | appstore | **IAP StoreKit 集成**（8 元买断价在 user_agreement.md 已写） | ⏳ 0 集成 | M | **P0** |
| **5** | appstore + googleplay | **隐私政策 URL 化**（仅 assets 3 md） | ⏳ 0 URL | S | **P0** |
| **6** | spen + alibaba | **A1 use case 层补** | ⏳ 1 文件 3025 字节 | M | P2 |
| **7** | spen + alibaba | **A6 safety_watch god service 拆** | 🔶 拆 2/5 | M | P1 |
| **8** | emil + alibaba + spen | **A5 mood_recorder god page 拆** | ⏳ 0 拆 | L | P2 |
| **9** | alibaba | **A7 app_tokens god constant 拆** | ⏳ 0 拆 | M | P2 |
| **10** | appstore | **HealthKit 集成（可选）** | ⏳ 0 集成 | L | P2 |
| **11** | appstore | **iPad Pro 12.9" layout 重审** | 🔶 UIRequiresFullScreen=false ✓,layout 12.9" 未适配 | M | P2 |
| **12** | appstore | **Background Tasks `fetch` → `processing`** | ⏳ iOS 13+ deprecated | M | P1 |
| **13** | googleplay | **release 签名架构** | ⏳ debug keystore | S | **P0** |
| **14** | googleplay | **Play Console 元数据仓库（fastlane）** | ⏳ 0 文件 | M | **P0** |
| **15** | googleplay | **BootReceiver 通知恢复**（RECEIVE_BOOT_COMPLETED 失声明） | ⏳ 0 接收器 | S | **P0** |
| **16** | googleplay | **Health 类目合规包** | ⏳ 0 文件 | M | P1 |

---

## 3. 底层问题清单（按优先级 + 跨视角去重排序）

### 3.1 P0 必修复（17 条）

| # | 视角 | 文件:行 | 问题 | 修复 | 难度 | 状态 |
|---|------|--------|------|------|------|------|
| **P0-1** | 6 视角共识 | `lib/core/data/services/sms_service.dart:83, 156, 171` | `throw UnimplementedError` 当业务错误；release 模式失联通知 100% 失败；Data Safety Form 申报"SMS 触发时数据共享给阿里云"撒谎 | 抽 `SmsGateway` abstract + 3 impl + 构造注入 + `validateForRelease` 真验证 | L | ⏳ |
| **P0-2** | 4 视角共识 | `lib/core/data/repositories/contact/contact_repository_impl.dart:36-49` + `lib/core/data/database/tables/contact/contacts.dart` + `app_database.dart:82` | PIPL §13 联系人同意：API 强制 `ConsentArtifact` + `ConsentDialog` UI 已落地（R62 P0-2 修正），但**留痕只 piiSafeLog 不写表**（Contact 0 consent 字段，schemaVersion 未 bump） | 加 `consentAt/consentKind/consentBy/consentVersion` 4 列 + `schemaVersion=15` + migration + 改 `ContactsCompanion.insert(..., consentAt: Value(consent.grantedAt), ...)` | M | ⏳ 半修 |
| **P0-3** | spzh + alibaba + spen | `lib/domain/entities/consent_artifact.dart:33-39` + `lib/presentation/providers/legal_consent_provider.dart:20-29` | `ConsentKind` 双 enum 同名不同值（domain `{emergencyContactSharing, dataExport}` vs presentation `{safety, vent, analytics}`） | domain `ConsentKind` 加 3 值 + presentation 删本地 enum | M | ⏳ |
| **P0-4** | appstore | `ios/Runner/Info.plist:0` | 缺 `ITSAppUsesNonExemptEncryption` key（Apple 2024 强制） | 加 `<key>ITSAppUsesNonExemptEncryption</key><false/>` | S | ⏳ |
| **P0-5** | appstore + googleplay | `assets/legal/privacy_policy.md:111, 123, 150` | 3 处 `privacy@chroniccare.app` 占位邮箱 | 注册真实邮箱 + 替换 3 处 | S | ⏳ |
| **P0-6** | appstore + googleplay + spzh | `assets/legal/privacy_policy.md:3` + `sensitive_data_consent.md:3` + `user_agreement.md:3` | 3 份法律文档顶部都标"v0.24 草稿,未经律师过审" | 律师过审 3 份 + 删"草稿"字样 + 加律师签字 | **XL（法务 2-4 周）** | ⏳ |
| **P0-7** | appstore | `ios/Runner/Info.plist:0` + `pubspec.yaml:0` | IAP StoreKit 没集成（8 元买断价在 user_agreement.md 已写） | 加 `in_app_purchase: ^7.0.0` + `StoreKitService` + NonConsumable $1.19 product `com.chroniccare.app.lifetime` | M | ⏳ |
| **P0-8** | appstore | `lib/core/data/services/sms_service.dart:171-176` + `lib/main.dart:154` | AliyunSmsProvider.send() 抛 UnimplementedError | 真接阿里云 SMS（外部依赖：法务 1-2 月 + AccessKey） | **XL** | ⏳ |
| **P0-9** | appstore | `ios/Runner/Info.plist:0` | 缺 `NSPhotoLibraryAddUsageDescription`（PDF 报告分享触发 PHPhotoLibrary） | 加 usage description | S | ⏳ |
| **P0-10** | appstore | `ios/Runner/Info.plist:10` | `CFBundleDisplayName` 仅 4 字中文,没英文 / 繁体 | per-language dict（en + zh-Hans + zh-Hant） | S | ⏳ |
| **P0-11** | appstore | `ios/Runner/Info.plist:101` | UIBackgroundModes `fetch` iOS 13+ deprecated | 改 `processing` + `BGTaskSchedulerPermittedIdentifiers` | M | ⏳ |
| **P0-12** | appstore | `ios/Runner/project.pbxproj:0` | 缺 `Runner.entitlements` 文件（v1.0 扩展前必须） | 新建 entitlements + pbxproj `CODE_SIGN_ENTITLEMENTS` | S | ⏳ |
| **P0-13** | appstore | App Store Connect metadata | 6.7" / 6.5" / 5.5" / iPad Pro 12.9" 截图 0 张 | 设计 + 截图 12 张 + 上传 | M | ⏳ |
| **P0-14** | appstore | App Store Connect metadata | 170 字促销 / 4000 字描述 / 100 字关键词 / 副标题 / 类别 / 版权 / Support URL 0 | App Store Connect 填 | M | ⏳ |
| **P0-15** | appstore | 域名 | 缺 `chroniccare.app` 域名 + 隐私政策 URL | 买域名 + mkdocs 部署 + URL 填 | M | ⏳ |
| **P0-16** | googleplay | `android/app/build.gradle.kts:42` | release 用 debug 签名 | 配 `signingConfigs.release` + `key.properties` + Play App Signing | S | ⏳ |
| **P0-17** | googleplay | 新建 `fastlane/metadata/android/{en-US,zh-CN}/` | 0 文件 | 7 文件（title/short_description/full_description/icon/feature_graphic/phone_screenshots/promo_graphics） | M | ⏳ |

### 3.2 P1 重要（38 条 - 跨视角高频 Top 20）

> 完整 38 条见各视角分报告；以下展示跨视角高频 Top 20：

| # | 视角共识 | 文件:行 | 问题 | 修复 | 难度 |
|---|---------|--------|------|------|------|
| **P1-1** | emil + flutter | `lib/main.dart:307, 368` | `Colors.orange` / `Colors.red` 硬编（dark mode silent bug） | `theme.colorScheme.tertiary` / `errorColor(context)` | S |
| **P1-2** | flutter | `lib/core/theme/app_theme.dart:20` | `onPrimary: Colors.white` 显式覆盖（M3 fromSeed 已派生） | 删此行,让 fromSeed 自动派生 | S |
| **P1-3** | flutter | `lib/core/theme/app_tokens.dart:138-139` | `disabledColor` hardcode 2 个 `Color(0x...)` bypass M3 scheme | `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)` | S |
| **P1-4** | spen | `lib/core/data/repositories/check_in/check_in_repository_impl.dart:64, 79, 102` | 3 处 `at ?? DateTime.now()` pattern 重复 | 抽 `_resolveTimestamp(at)` helper | S |
| **P1-5** | spen | `lib/domain/logic/phq9.dart:129` | `hotlineByRegion[region]!` 海外 region 未注册会崩 | `?? defaultHotline` 兜底 | S |
| **P1-6** | spen | `lib/core/data/services/notification_service.dart:30-65, 360-417` (250 行 facade) | facade 仍 250 行 + showSafetyAlert 50 行独立 channel | 抽 `SafetyAlertBuilder` (l10n + 3 态) + facade 委派 | M |
| **P1-7** | spen | `lib/core/data/services/safety_watch_service.dart:123-245` (122 行 _checkAndAlert) | facade 协调 122 行核心逻辑 | 抽 `SafetyDetector` 纯函数 + facade 委派 | M |
| **P1-8** | spen | `lib/core/data/database/app_database.dart:234-285` (18 query facade 委托) | facade 18 个 1 行委托,R53a 7 DAO 抽离收尾 | 选 caller 集中点渐进删 facade | M |
| **P1-9** | spen | `lib/core/data/database/app_database.dart:165` | 唯一 1 处 `} catch (e) {}` 完全静默 | 走 `swallowError` 集中器 + where tag | S |
| **P1-10** | spen | `lib/presentation/pages/home/home_page.dart:105` | `Future<void>.delayed(AppTokens.kDeepLinkRaceGuard)` 仍不可 cancel | `Timer` + dispose cancel（跟 `_celebrationTimer` 一致） | S |
| **P1-11** | spen | `lib/presentation/pages/medication/refill_manage_page.dart:114, 215-218, 300` | 5 处 `!` 后缀,部分 redundant | `?? 0` 或 local copy | S |
| **P1-12** | spzh | `lib/domain/logic/phq9.dart:19-24, 70-103, 119-133` + `gad7.dart:15-31, 41-65` | 量表 16 题 + 9 档严重度 + 6 region 危机电话 label 100% 硬编中文 | `AssessmentScale` 改 abstract 注入 `ScaleTranslations` | L |
| **P1-13** | spzh | `lib/core/l10n/strings.dart:54-267` 6 处 dartdoc 与实际错位 | 注释撒谎 | 同步 6 处注释与实际代码 | S |
| **P1-14** | spzh | `lib/core/l10n/strings.dart` 50+ 处 fallback + 80% caller 未传 override | 跑 `check_strings_override.py` 守护 + 修正 | M |
| **P1-15** | spzh | `lib/main.dart:23-35, 151-191` (R62 SmsService 顶层 static) | top-level static 是 hidden global state | 改 `late final` 配 `smsServiceProvider.overrideWith((ref) => _smsService)` | S |
| **P1-16** | spen + alibaba | `lib/core/data/services/safety_watch_service.dart:131-205` (8 段 early-return) | 单方法 70+ 行,违反阿里"≤ 80 行" | 抽 2 private method | M |
| **P1-17** | alibaba | `lib/core/routing/app_router.dart:287 行` (17 路由 + 3 transition + AppShell) | god router | 拆 `app_router.dart` + `app_shell.dart` | M |
| **P1-18** | alibaba | `lib/core/data/services/notification_service.dart:418 行` | god service | 抽 `NotificationScheduler` / `DeepLinkHandler` facade | M |
| **P1-19** | googleplay | `android/app/src/main/AndroidManifest.xml:5-21` (comment) | comment 说加 2 属性但 application 标签无 | 加 `enableOnBackInvokedCallback="true"` | S |
| **P1-20** | googleplay + appstore | `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare` | 重复 2 次,趁 App Store 没锁改 `com.chroniccare.app` | S |

### 3.3 P2 建议（47 条 - 关键 15 条）

| # | 视角 | 文件:行 | 问题 | 修复 | 难度 |
|---|------|--------|------|------|------|
| **P2-1** | emil | `lib/presentation/widgets/animations/page_transition_switcher.dart:34` | `const Duration(milliseconds: 100)` 裸值（已有 `AppTokens.durPageTransition`） | `AppTokens.durPageTransition` | S |
| **P2-2** | emil | `lib/main.dart:234-401` 16 处裸 SizedBox/EdgeInsets/inline TextStyle | 走 token（spacingXxs/Xs/Sm/Md/Lg + textStyleButton/CaptionHint） | S |
| **P2-3** | emil | `lib/presentation/pages/trend/trend_page.dart:127-196` | 4 chart panel 无 stagger | 每个 SectionHeader + chart 套 `FadeIn(delay: i * staggerStepMs)` | S |
| **P2-4** | alibaba | `lib/core/theme/app_tokens.dart:644 行` | 1 文件 4 大类 100+ token 散 | 拆 `app_colors/typography/spacing/motion.dart` 4 文件 | M |
| **P2-5** | alibaba | `lib/presentation/pages/medication/refill_manage_page.dart:265, 329` + 3 文件 | 5 处 `withValues(alpha: X.XX)` 裸值 | 抽 `AppTokens.alphaTintSubtle` 等命名常量 | S |
| **P2-6** | spen | `lib/presentation/pages/medication/refill_manage_page.dart:90-219` | 6 处 `!` 后缀冗余 | 抽 nullable 返 `int?` | S |
| **P2-7** | spen | `lib/presentation/pages/setup/setup_page.dart:411-413` | R59 fail-loud 改 fail-soft 后 finally 双路径写 | 抽 private async helper | S |
| **P2-8** | spen | `lib/presentation/pages/vent/vent_compose_page.dart:122, 230, 273, 319` | 4 处 `_audioPath!` / `_tempDecryptedPath!` | 抽 `_audioPathOrThrow` getter | S |
| **P2-9** | spen | `lib/core/data/privacy/encrypted_audio_storage.dart:117, 128, 209` | 3 处 `Random().nextInt(10000)` 4 位 random suffix（撞 0.01%） | 抽 helper + 改 7 位（0.0001%） | S |
| **P2-10** | spen | `lib/presentation/pages/trend/trend_calendar.dart:56-57, 93-94` | initState 跟 build 各取 `now`,跨 midnight 错位 | 抽 `_today()` top-level 纯函数 | S |
| **P2-11** | spen | `lib/presentation/pages/home/home_page.dart:442-449` | `_nextReminderTime` build 内 2 次取 `now` | 抽 top-level `_nextReminderTime(now)` 纯函数 | S |
| **P2-12** | spzh | `lib/core/data/services/safety_watch_service.dart:308-315` | `displayMessage` getter 仍返 i18n key（老 caller 误用风险） | 升级 caller 到 `displayMessageL10n(l10n)` + 删 getter | S |
| **P2-13** | spzh | `lib/core/data/services/safety_watch_service.dart:381-387` | `toJson` 没序列化 `contactsMocked` 字段 | 加 `'contactsMocked': contactsMocked` | S |
| **P2-14** | spzh | `lib/core/data/services/snooze_manager.dart:80-82` + `notification_service.dart` 多处 | 通知 Channel name/desc 走 `Strings.xxxChannelXxxName` 未传 override | 改 `Strings.xxxChannelXxxNameText(override: l10n.xxx)` | S |
| **P2-15** | flutter | `lib/presentation/pages/assessment/assessment_page.dart:151, 273, 380` + 5 setup 4 dialog | 9 处 `ElevatedButton` 未迁 `FilledButton` (M3 推荐) | 加 `PrimaryButton` (FilledButton 包装) 集中器,9 处替换 | M |

### 3.4 P3 nit（21 条 - 关键 10 条）

| # | 视角 | 文件:行 | 问题 | 修复 | 难度 |
|---|------|--------|------|------|------|
| **P3-1** | emil + flutter | `lib/main.dart:36` | 顶层 static `_smsService`（R60 P0-3 修正妥协）| `late final` 模式 | S |
| **P3-2** | flutter | `lib/domain/usecases/check_in_usecases.dart:16` + 9 文件 | 10+ 处 `library;` 指令残存（Dart 2.x 自动） | 删 10 行 | S |
| **P3-3** | flutter | `lib/presentation/pages/contact/contacts_list_widget.dart:273` + `data_management_section.dart:409` | 2 处 `.then((_) { ... })` 残存 | 改 async/await 模式 | S |
| **P3-4** | flutter | `lib/presentation/pages/vent/vent_compose_page.dart:88-130` | try/catch 内部分 setState 漏 `if (mounted)` check | catch 块内补 mounted check | S |
| **P3-5** | flutter | `lib/core/routing/app_shell.dart:91-103` | 顶部品牌 `Text` 的 `TextStyle` inline | `AppTokens.textStyleLabelStrong(context)` | S |
| **P3-6** | flutter | `lib/core/theme/app_tokens.dart:301-345` 17 dynamic getter | 缺性能 trade-off 注释 | 加注释说明 | S |
| **P3-7** | spzh | `README.md:131` + `AGENTS.md:136` + `docs/CHANGELOG.md [Unreleased]` | 文档数字漂移（1098 → 实际 1151） | README + AGENTS 改 1151 | S |
| **P3-8** | spzh | `lib/core/data/services/medication_notifier.dart:91, 113, 142-150` + `refill_notifier.dart:114-204` | piiSafeLog 中文 4+5 处 + 未 mask medication name (PII) | 改 en 模式 + mask | S |
| **P3-9** | alibaba | `domain/logic/care_strategies.dart:16` | 6 个 const 命名 `camelCase` 应改 `UPPER_SNAKE` | `LATE_HOUR_THRESHOLD` | S |
| **P3-10** | alibaba | 散落 | 缺 `LogLevel` enum（`piiSafeLog` 60+ 处全 emoji 区分）| 加 `LogLevel.warn/info/error/debug` | S |

---

## 4. 跨视角共识矩阵

### 4.1 7 视角发现的独有 vs 共性问题

| 问题 | emil | spen | spzh | appstore | googleplay | alibaba | flutter | 共识数 |
|------|------|------|------|----------|------------|---------|---------|--------|
| **P0-1 SmsGateway abstract** | | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **6** |
| **P0-2 PIPL §13 留痕** | | | ✅ | ✅ | ✅ | ✅ | | **4** |
| **AliyunSmsProvider.send() throw** | | ✅ | ✅ | ✅ | ✅ | | ✅ | **5** |
| **暗色 mode 硬编颜色 (main.dart:307, 368)** | ✅ | | | | | | ✅ | **2** |
| **`Colors.orange` / `Colors.red` 残留** | ✅ | | | | | | ✅ | **2** |
| **Future.delayed 不可 cancel** | ✅ | ✅ | | | | | ✅ | **3** |
| **i18n 3 语同步 / 0 orphan** | | | ✅ | | | | ✅ | **2** |
| **PIPL §13 联系人同意（API 强制了）** | | | ✅ | | | ✅ | | **2** |
| **隐私政策 URL 化** | | | ✅ | ✅ | ✅ | | | **3** |
| **隐私邮箱占位** | | | ✅ | ✅ | ✅ | | | **3** |
| **隐私政策草稿未审** | | | ✅ | ✅ | ✅ | | | **3** |
| **release 签名 (debug)** | | | | | ✅ | | | **1** |
| **IAP StoreKit 没集成** | | | | ✅ | | | | **1** |
| **`ITSAppUsesNonExemptEncryption` 缺** | | | | ✅ | | | | **1** |
| **`Runner.entitlements` 不存在** | | | | ✅ | | | | **1** |
| **BootReceiver 失声明** | | | | | ✅ | | | **1** |
| **fastlane/metadata/ 0 文件** | | | | | ✅ | | | **1** |
| **量表 PHQ-9 / GAD-7 硬编中文** | | | ✅ | | | | | **1** |
| **ConsentKind 双 enum** | | | ✅ | | | | | **1** |
| **隐式排序 .first/.last** | | ✅ | | | | | | **1** |
| **DateTime race** | | ✅ | | | | ✅ | | **2** |
| **dispose 完整性** | ✅ | ✅ | | | | | ✅ | **3** |
| **god class 拆分** | | ✅ | | | | ✅ | | **2** |
| **app_tokens 集中化** | ✅ | | | | | ✅ | ✅ | **3** |
| **R8 / ProGuard** | | | | | ✅ | | | **1** |
| **targetSdk 36** | | | | | ✅ | | | **1** |
| **国产 ROM 自检** | | | | | ✅ | | | **1** |
| **`ElevatedButton` 未迁 FilledButton** | | | | | | | ✅ | **1** |
| **`library;` 指令** | | | | | | | ✅ | **1** |
| **`RepaintBoundary` 0 处** | | | | | | | ✅ | **1** |
| **`withValues(alpha:)` 裸值** | ✅ | | | | | ✅ | | **2** |

### 4.2 视角盲点（互不覆盖）

| 视角 | 盲点 | 其他视角不覆盖 |
|------|------|----------------|
| **emil** | 动效细节 / 频度决策 | spen/spzh 不看动效 |
| **spen** | 隐式排序 / BuildContext race | emil/spzh/flutter 偶尔提但无系统化 |
| **spzh** | PIPL / 命名 / 提交 / 繁简 / PUA | 其他 6 视角**完全不看**合规 / 中文 / 命名 |
| **appstore** | iOS 上架规范 / TestFlight / IAP / 4.3 医疗 | 其他 6 视角**完全不看** |
| **googleplay** | Android 上架 / 国产 ROM / 64-bit / Play Console | 其他 6 视角**完全不看** |
| **alibaba** | 11 类编程规约 / 控制语句 / 注释 / OOP | 其他视角偶提但无系统化 |
| **flutter** | Effective Dart / M3 / RepaintBoundary / 异步 / i18n 类型 | emil 偏动效 / spen 偏方法论 / 其他不专门看 |

### 4.3 视角独有最大贡献

| 视角 | 独有最大贡献 |
|------|-------------|
| **emil** | 暗色 mode silent bug 哲学 + 频度决策 + 动效 token 集中化 |
| **spen** | 隐式排序 / DateTime race / TDD 纪律 / dispose 完整性系统化（4 视角学不到） |
| **spzh** | PIPL / 量表 i18n / 繁简 / PUA / 提交规范（4 视角学不到） |
| **appstore** | 9 个上架 P0 阻塞项（独家） |
| **googleplay** | 5 个上架 P0 阻塞项 + 国产 ROM 自检（独家） |
| **alibaba** | 11 类规范系统化（god class / 注释 / OOP / 集合 / 并发）|
| **flutter** | Effective Dart / M3 / RepaintBoundary（独家） |

---

## 5. 修复路线（按优先级 + 难度综合排序）

### 5.1 Top 5 必改 P0（1 周内可启动）

> 含外部依赖 3 个（法务 + 阿里云 + 域名）需并行启动

1. **P0-1 SmsGateway abstract 抽离 (L, 6 视角共识)** — `lib/core/data/services/sms_service.dart:16-49, 61-88, 83, 156, 171, 269-272` + `lib/main.dart:140`。抽 `SmsGateway` abstract interface + `AliyunSmsGateway`（v1.0+ 真接）+ `MockSmsGateway`（dev）+ `NoopSmsGateway`（release 模式前）；`validateForRelease` 真验证。**关联所有 P0 收尾**。
2. **P0-2 PIPL §13 留痕 + P0-3 ConsentKind 统一 (M, 4 视角共识)** — `lib/core/data/repositories/contact/contact_repository_impl.dart:36-49` + `lib/core/data/database/tables/contact/contacts.dart` + `app_database.dart:82` + `domain/entities/consent_artifact.dart:33-39` + `presentation/providers/legal_consent_provider.dart:20-29`。加 4 列 + `schemaVersion=15` + migration + 改 `ContactsCompanion.insert(..., consentAt: Value(consent.grantedAt), ...)` + 双 enum 统一。
3. **P0-4/5/6/9/10/11/12/13/14/15 iOS 上架阻塞 (S-M, appstore 视角)** — Info.plist 加 3 key + 隐私邮箱替换 + 6 截图 + 元数据 + IAP StoreKit + Runner.entitlements + per-language displayName + UIBackgroundModes 改 processing + 买域名建站。
4. **P0-16/17 Android 上架阻塞 (S-M, googleplay 视角)** — release keystore + signingConfigs.release + fastlane/metadata 7 文件 + BootReceiver.kt。
5. **P0-8 AliyunSmsProvider 真接 (XL, 外部依赖)** — pubspec 加 `dio: ^5.0.0` + `crypto: ^3.0.0` + `_signRequest()` HMAC-SHA1 + POST `https://dysmsapi.aliyuncs.com/` + 5s timeout + 3 次重试。**外部阻塞**：法务 1-2 月审核短信模板 + 阿里云 AccessKey + SMS 签名备案。

### 5.2 Top 10 P1 重要（1-4 周）

1. **P1-1 main.dart 硬编颜色 (S, emil + flutter)** — `lib/main.dart:307, 368` 替换 `Colors.orange/red` → `theme.colorScheme.tertiary/errorColor(context)`
2. **P1-2 app_theme.dart onPrimary 显式覆盖 (S, flutter)** — `lib/core/theme/app_theme.dart:20` 删 `onPrimary: Colors.white`
3. **P1-3 app_tokens disabledColor hardcode (S, flutter)** — `lib/core/theme/app_tokens.dart:138-139` 改 `Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)`
4. **P1-4 check_in_repository `_resolveTimestamp` helper (S, spen)** — 3 处 pattern 抽 helper
5. **P1-5 phq9 hotlineByRegion `!` 兜底 (S, spen)** — `?? defaultHotline`
6. **P1-6/7 2 个 facade 收尾 (M, spen)** — SafetyAlertBuilder + SafetyDetector 抽离
7. **P1-8 app_database 18 query facade 委派清理 (M, spen)** — 选 caller 集中点渐进删
8. **P1-9 app_database 1 处静默 catch 修 (S, spen)** — 走 swallowError 集中器
9. **P1-10 home_page Future.delayed 仍不可 cancel (S, spen + flutter)** — 改 Timer + dispose cancel
10. **P1-12 量表 PHQ-9/GAD-7 i18n 化 (L, spzh)** — AssessmentScale 改 abstract

### 5.3 Top 20 P2 建议（v1.0 前修）

> 按"影响面 × 易修性"排，前 10 已列 §3.3 关键 15 条；后 10 略

### 5.4 Top 10 P3 nit（顺手修）

> 10 条已列 §3.4 关键 10 条

---

## 6. 上架就绪度

### 6.1 iOS App Store 上架清单（一次性 Checklist）

```
平台账号: [ ] Apple Developer Program $99/年 + [ ] Mac + [ ] Xcode
证书: [ ] iOS App IDs com.chroniccare.app + [ ] Distribution Cert + [ ] Provisioning Profile
App Store Connect: [ ] 创建 app + [ ] IAP product com.chroniccare.app.lifetime (Non-Consumable $1.19)
元数据: [ ] AppIcon 1024 + [ ] 4 尺寸 × 3 张截图 + [ ] 副标题 + [ ] 类别 Medical+Health + [ ] 版权 © 2026
       + [ ] 促销 170 字 + [ ] 描述 4000 字 + [ ] 关键词 100 字 + [ ] 17+ 年龄分级
URL: [ ] chroniccare.app 域名 + [ ] 隐私政策 URL + [ ] Support URL
合规: [ ] Privacy Nutrition Labels (Data Collection=None, Track=None) + [ ] ITSAppUsesNonExemptEncryption=false
测试: [ ] TestFlight 内部测试 ≥ 1 完整周期 (1-2 周) + [ ] 至少 2 tester 跑核心流程
审核: [ ] App Review 备注: 精神心理 + 医疗 + 失联通知 + PIPL + [ ] App Privacy 详情
```

### 6.2 Google Play Console 上架清单

```
平台账号: [ ] Google Play Console $25 一次性 + [ ] keystore
签名: [ ] release.jks + key.properties + Play App Signing
元数据: [ ] fastlane/metadata/android/{en-US,zh-CN}/ 7 文件 + [ ] 4 张截图 + [ ] feature_graphic
合规: [ ] Privacy Policy URL https://chroniccare.app/privacy + [ ] Data Safety Form + [ ] Permissions Declaration Form
类目: [ ] Health & Fitness + [ ] Medical
内容分级: [ ] IARC 16+
广告: [ ] 0 (无广告 SDK / 无 Firebase / 无 GA)
安全: [ ] Play Integrity (推荐) + [ ] isDebuggable=false 显式 + [ ] allowBackup=false 显式
PIPL: [ ] 隐私政策 + 单独同意条款 + 联系人留痕
NMPA: [ ] 律师评估 + "非医疗器械" 声明
测试: [ ] Internal testing ≥ 1 完整周期 (1-2 周)
```

### 6.3 上架就绪度

| 平台 | 评分 | 最大阻塞 | 3 月可达 |
|------|------|---------|---------|
| iOS App Store | 3.5/10 | 法务 + IAP + 建站 3 件并行 | 8.5/10 |
| Google Play | 3.0/10 | release 签名 + 元数据仓库 + 隐私 URL + 邮箱 + BootReceiver 5 件并行 | 8.5/10 |

### 6.4 3 个月时间表

| 阶段 | 周期 | iOS | Android |
|------|------|-----|---------|
| **Sprint 1** | W1-2 | S 难度 5 件 P0 (Info.plist + 邮箱 + displayName + 截图 + 元数据) | S 难度 5 件 P0 (签名 + BootReceiver + 元数据仓库 + 邮箱 + 隐私 URL) |
| **Sprint 2** | W3-4 | M 难度 5 件 (IAP StoreKit + BGTaskScheduler + entitlements + 部署建站 + NMPA 评估) | M 难度 (Data Safety Form + Permissions Declaration + Play Integrity) |
| **Sprint 3** | W5-8 | 法务过审 2-4 周（外部） + TestFlight 内测 | 法务过审 + 内测 |
| **Sprint 4** | W9-12 | TestFlight 外测 + 修反馈 + 提交审核 + AliyunSmsProvider 真接 | 内测 + 修反馈 + 提交审核 + AliyunSmsProvider 真接 |
| **同时修底层 P1/P2** | 持续 | 7 视角 Top 20 P1 + Top 20 P2 并行 | 同 |

---

## 7. 总结

### 7.1 7 视角共识

| 维度 | 共识 |
|------|------|
| **架构** | 4 层 + 5 umbrella 不需切换,3 个微观改造足够 |
| **最关键 P0** | P0-1 SmsGateway 6 视角共识 + P0-2 PIPL 留痕 4 视角共识 |
| **上架就绪** | 双平台离 1.0 还差 2-3 月,代码层 90% ready,卡在"非代码"环节 |
| **修复优先级** | P0 必改 17 条（5 个是 S 难度可立即修）+ P1 重要 38 条（1-4 周）+ P2 建议 47 条（v1.0 前） |

### 7.2 3 句话核心结论

1. **架构稳定,修复重点在"清半成品 + 补上架"** — 4 层 + 5 umbrella 7 视角共识不需切换;3 个微观改造（use case 层补 + SmsGateway 抽象 + ConsentKind 统一）足够;核心工作量在底层 P0 17 条 + 上架阻塞 10+ 件。
2. **P0 高度集中在 3 个"半修"陷阱 + 上架"非代码"环节** — (1) SmsGateway throw 6 视角共识; (2) PIPL §13 留痕 4 视角共识; (3) 法务/域名/邮箱/截图/元数据/签名 4 视角共识。前两者代码层 1 周可修,后者需 1-2 月外部依赖。
3. **3 个月内可达上架就绪度 8.5/10** — iOS 9 个 P0 + 10 个 P1（法务 + IAP + 建站并行）+ Android 5 个 P0 + 7 个 P1（签名 + 元数据 + 隐私 + BootReceiver 并行）;2 个 FTE + 律师 + 设计师 + 阿里云 + Apple/Google 团队协作,90 天可达上架 1.0。

### 7.3 7 份独立报告索引

| 视角 | 报告路径 | 问题数 | 评分 |
|------|---------|--------|------|
| emil（设计工程） | `emil/report.md` | 12 | 41/44 |
| spen（英文方法论） | `spen/report.md` | 18 | 34/40 |
| spzh（中文 + 合规） | `spzh/report.md` | 18 | 3.7/5 |
| appstore（iOS 上架） | `appstore/report.md` | 26 | 3.5/10 |
| googleplay（Android 上架） | `googleplay/report.md` | 21 | 3.0/10 |
| alibaba（阿里规范） | `alibaba/report.md` | 23 | 4.2/5 |
| flutter（Flutter 规范） | `flutter/report.md` | 14 | 4.2/5 |
| **整合报告** | **`CONSOLIDATED.md`**（本文件） | **123** | — |

---

**生成时间**：2026-07-31  
**生成人**：Mavis (root session `mvs_13726450b44e4bd2a66f686b2cf7fce1`)  
**执行方式**：7 sub-agent 并行（emil / spen / spzh / appstore / googleplay / alibaba / flutter）+ 主线程整合  
**关键改进**：共享上下文文档约束扫描范围 + ripgrep 模式 + 输出 ≤ 30KB + 输出格式统一化 → 7 sub-agent 全部成功（vs 上次 3 sub-agent 全 stack overflow 失败）
