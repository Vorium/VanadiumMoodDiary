# 项目现状综合分析报告

**生成时间**: 2026-08-07
**适用版本**: v0.30.0+85 (R95 sub-spec 8 实施后)
**测试基线**: 2019 tests pass, 0 analyzer error, 18 守门员全绿
**分析范围**: lib/ + assets/ + fastlane/ + docs/ + android/ + ios/
**分析视角**: 外部链接安全 / 上架阻碍 / 顶层架构 / 底层代码 / 开发需求文档同步

> 本报告基于 R92 baseline + R95 8 sub-spec 实施后的实际代码扫描，与 SPRINT1_LEGAL_TODO / SPRINT2_TODO / VERSION_1.0_PLAN 交叉验证，所有引用条目均给出文件路径 + 行号。
>
> **R96 更新 (2026-08-07)**: P0-2/3/5 占位符已软隐藏 (跟 `privacy@chroniccare.app` 同一策略);
> P0-12/13/14 三个"新发现 Bug"经直接读代码验证后**全部不存在** (之前报告基于 subagent
> 不可靠信息误报)。详见 §4.1 和 §5.2 的 R96 状态标注。

---

## 摘要 (Executive Summary)

| 维度 | 评分 | 趋势 | 关键发现 |
|------|------|------|----------|
| 代码 / 架构 | 9.0/10 | ↑ R92 8.0 → R95 9.0 | 6 god page 已拆完，102+ 处 token 化，0 catch(_) 静默吞错 |
| 工程自动化 | 9.0/10 | ↑ 18 守门员全绿，coverage 阈值上线 | check_coverage 新增 |
| 安全合规 | 4.5/10 | ↑ R92 3.5 → R95 4.5 | audit log 加密 + PIPL §47 撤回，但法务/域名/SMS 真接仍 0 实施 |
| 上架就绪度 | ~40% (Google Play) / 6.5/10 (App Store) | 持平 | 4 项 Sprint 1 法务 + 5 项业务真接全部阻塞 |
| 外部链接安全 | 7.5/10 | — | 0 运行时外部 URL 引用；占位 URL 12 处需在法务上线后替换 |

**核心结论**: 代码侧 / 架构侧 / 工程自动化侧已 100% 完成可代码化部分；上架阻塞全部为外部依赖（法务 1-2 月 / 阿里云 SMS 1-2 月 / 域名注册 1-2 天 / 5 厂商 push 1-2 月）。

---

## 第 1 部分：外部链接内容检查

### 1.1 检查方法

- grep `https?://[^\s"'<>)]]+` 在 `lib/`、`assets/`、`fastlane/`、`docs/`、`android/`、`ios/`
- grep `launchUrl|url_launcher|UrlLauncher` 在 `lib/`（运行时是否调用系统打开 URL）
- 检查 `AndroidManifest.xml` 与 `Info.plist` 是否配置外部 URL scheme

### 1.2 检查结果

#### A. 运行时代码（lib/）— ✅ 已按规范隐藏

| 位置 | URL | 用途 | 处理状态 |
|------|-----|------|----------|
| [lib/core/data/services/sms_service.dart:97](file:///d:/Batch/chroniccare/lib/core/data/services/sms_service.dart#L97) | `https://dysmsapi.aliyuncs.com/` | 阿里云 SMS API 端点（注释中） | ✅ 仅文档注释，FeatureFlags.aliyunSmsEnabled=false 编译期锁定未接入 |
| [lib/core/data/services/sms_service.dart:100](file:///d:/Batch/chroniccare/lib/core/data/services/sms_service.dart#L100) | `https://help.aliyun.com/zh/sms/...` | 阿里云 SDK 文档链接（注释中） | ✅ 仅文档注释 |
| [lib/domain/logic/chinese_holidays.dart:17](file:///d:/Batch/chroniccare/lib/domain/logic/chinese_holidays.dart#L17) | `https://holidayapi.com` | 注释说明"为什么不接网络 API" | ✅ 仅说明性注释 |

**结论**: `lib/` 内 0 处运行时 `launchUrl` / `url_launcher` 调用；所有 URL 均为文档注释或 FeatureFlag 编译期锁定，符合"零云端"原则。

#### B. 法务文档与上架元数据（assets/legal/、fastlane/）— ⚠️ 占位待替换

| 位置 | URL | 风险 | 处理建议 |
|------|-----|------|----------|
| [fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt:1](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/privacy_url.txt) | `https://chroniccare.app/privacy` (×3 文件) | 🔴 **上架 P0 阻塞** — 域名未注册，Apple 5.1.1 必拒 | 注册域名 + 部署隐私政策 HTML |
| [fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt:1](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/support_url.txt) | `https://chroniccare.app/support` (×3 文件) | 🔴 **上架 P0 阻塞** — 同上 | 同上 |
| [fastlane/metadata/android/{en-US,zh-CN}/video.txt:1](file:///d:/Batch/chroniccare/fastlane/metadata/android/en-US/video.txt) | `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO` (×2 文件) | 🟡 Play Console 上传时报错（视频 ID 不存在） | 制作 demo 视频后上传 YouTube 替换 |
| [fastlane/metadata/{android,en-US,zh-Hans,zh-Hant}/description.txt](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/description.txt) | `https://findahelpline.com` (×6 文件) | 🟢 故意保留（精神心理危机热线国际资源，非商业） | ✅ 无需修改 |
| [assets/legal/privacy_policy.md:218](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md#L218) | `https://chroniccare.app/privacy` | 🟡 已标 TODO，需律师过审后部署 | 跟 1.4 域名任务一起做 |
| [assets/legal/user_agreement.md:69](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md#L69) | `https://github.com/example/chroniccare/issues` | 🟡 已标 TODO 占位 | 替换为真实 GitHub 仓库 |
| [fastlane/Appfile:21-25](file:///d:/Batch/chroniccare/fastlane/Appfile) | `apple_id("your-apple-id@example.com")` / `team_id("YOUR_TEAM_ID")` / `itc_team_id("YOUR_ITC_TEAM_ID")` | 🔴 **上架 P0 阻塞** — 占位值，无法上 store | 替换为真实 Apple Developer 凭据 |
| [docs/MEDICAL_DISCLAIMER.md](file:///d:/Batch/chroniccare/docs/MEDICAL_DISCLAIMER.md) | `https://chroniccare.app/medical-disclaimer` (×4 处) | 🟡 占位，需跟 1.4 一起上线 | 同上 |
| [docs/DEPLOYMENT.md:59](file:///d:/Batch/chroniccare/docs/DEPLOYMENT.md#L59) | `https://chroniccare.vercel.app` | 🟢 开发文档示例 URL | ✅ 无需修改 |
| [docs/PUSH_PROVIDERS.md](file:///d:/Batch/chroniccare/docs/PUSH_PROVIDERS.md) | 5 个厂商官网 URL（mi/huawei/oppo/vivo/flyme/firebase） | 🟢 厂商参考链接 | ✅ 无需修改 |
| [docs/PLAYSTORE_SIGNING_GUIDE.md](file:///d:/Batch/chroniccare/docs/PLAYSTORE_SIGNING_GUIDE.md) | 4 个 Google/Apple 官方文档 URL | 🟢 官方文档参考 | ✅ 无需修改 |

#### C. 平台配置（AndroidManifest.xml、Info.plist）— ✅ 合规

- [android/app/src/main/AndroidManifest.xml](file:///d:/Batch/chroniccare/android/app/src/main/AndroidManifest.xml) 仅声明 8 个权限（INTERNET 用于 SMS/邮件，无外部 URL scheme 配置），`allowBackup=false` / `debuggable=false` 已显式禁用
- [ios/Runner/Info.plist](file:///d:/Batch/chroniccare/ios/Runner/Info.plist) 0 处外部 URL 配置（仅 DOCTYPE 引用 apple.com DTD）
- [ios/Runner/PrivacyInfo.xcprivacy](file:///d:/Batch/chroniccare/ios/Runner/PrivacyInfo.xcprivacy) 已声明 5 个 required reason API + 4 类收集数据类型，符合 Apple 2024-05 强制要求

### 1.3 外部链接问题清单（按优先级）

| # | 类别 | 修复难度 | 优先级 | 问题 | 建议 |
|---|------|----------|--------|------|------|
| E-1 | 底层实现 | 低 | **P0** | iOS privacy_url / support_url 共 6 文件指向未注册域名 `chroniccare.app` | 注册域名 + 部署 HTML + 替换 6 文件 |
| E-2 | 底层实现 | 低 | **P0** | fastlane/Appfile 3 个 Apple ID/Team ID 占位值 | 替换为真实凭据 |
| E-3 | 底层实现 | 低 | **P0** | user_agreement.md 引用 `github.com/example/chroniccare/issues` 占位 | 创建真实仓库后替换 |
| E-4 | 底层实现 | 低 | **P1** | android video.txt YouTube URL 占位 `PLACEHOLDER_APP_DEMO_VIDEO` | 制作 demo 视频后替换 |
| E-5 | 底层实现 | 低 | **P2** | MEDICAL_DISCLAIMER.md 4 处 `chroniccare.app/medical-disclaimer` 占位 | 跟 E-1 一起部署 |

### 1.4 安全敏感信息扫描

- `.env.example` ✅ 全部为占位符（`SG.xxxx...` / `noreply@chroniccare.app`），无真实 secret
- `pubspec.yaml` ✅ `publish_to: 'none'`，未发布到 pub.dev
- `android/key.properties.example` ✅ 模板文件，真实 `key.properties` 已在 .gitignore 排除
- `lib/` 0 处硬编码 API key / token / 密码

---

## 第 2 部分：项目状态问题排查

### 2.1 上架阻碍因素（外部依赖，非代码可解决）

#### S-1: Sprint 1 法务 4 项 — 0/4 完成（P0 阻塞上架）

参考 [docs/SPRINT1_LEGAL_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md)

| 子项 | 类别 | 修复难度 | 优先级 | 状态 |
|------|------|----------|--------|------|
| S-1.1 律师 review 3 份法律 md | 底层实现 | 高（¥45-90k + 1-2 周） | **P0** | 未做 |
| S-1.2 邮箱 `support@chroniccare.app` 注册 | 底层实现 | 低（1-2h） | **P0** | 未做 |
| S-1.3 GitHub 仓库 `github.com/example/chroniccare` 替换 | 底层实现 | 低（0.5 天） | **P0** | 未做 |
| S-1.4 域名 `chroniccare.app` 注册 + ICP 备案 + HTTPS 部署 3 份 md | 底层实现 | 中（1-2 天注册 + 7-20 天 ICP） | **P0** | 未做 |

#### S-2: 业务真接 5 项 — 全部 FeatureFlags 锁定（P0 阻塞 v1.0）

参考 [lib/core/data/feature_flags.dart](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) 第 47-69 行

| FeatureFlag | 默认值 | 阻塞原因 | 修复难度 | 优先级 |
|-------------|--------|----------|----------|--------|
| `aliyunSmsEnabled` | `false` | 阿里云 SMS 真接需法务 1-2 月模板审核 + AccessKey 申请 | 高 | **P0** |
| `emailServiceEnabled` | `false` | SendGrid API key + 模板审核 1-2 周 | 中 | **P0** |
| `iapEnabled` | `false` | Apple/Google 真接 productId + 测卡 | 中 | **P0** |
| `fiveVendorPushEnabled` | `false` | 米/华/OPPO/vivo/魅族 5 厂商 push SDK 接入 1-2 月审核 | 高 | **P0** |
| `phqGad7I18nEnabled` | `false` | PHQ-9/GAD-7 16 题全文 i18n（70+ ARB key × 3 语 = 210 key） | 中（8-16h） | **P0** |
| `bootReceiverEnabled` | `false` | WorkManager 完善 + BootReceiver 真接 | 中 | P1 |
| `emergencyContactEnabled` | `false` | 紧急联系人 SMS 业务（依赖 aliyunSmsEnabled） | 中 | P1 |
| `ventAudioEnabled` | `false` | vent audio 录音业务闭环（storage/export 暂停） | 中 | P2 |

### 2.2 半成品功能 / 未完成任务

#### H-1: iOS Podfile 真实生成 — P1
- **位置**: [ios/Podfile](file:///d:/Batch/chroniccare/ios/Podfile)
- **现状**: R77-8 占位 Podfile 写好，未跑 `pod install` 生成 Podfile.lock
- **影响**: iOS 真 build 必需
- **类别**: 底层实现 | 修复难度: 低（0.5h，需 macOS） | 优先级: P1

#### H-2: package_info_plus 引入 — P1
- **位置**: [lib/presentation/services/legal_version.dart](file:///d:/Batch/chroniccare/lib/presentation/services/legal_version.dart) 顶部 TODO
- **现状**: `kPubspecVersion` 跟 pubspec.yaml 手动同步
- **目标**: 加 `package_info_plus` 依赖，启动时 `PackageInfo.fromPlatform()` 自动读
- **类别**: 底层实现 | 修复难度: 中（4-6h，需 macOS pod install） | 优先级: P1

#### H-3: NSESSS / CRDPSS 2 个量表 unavailable — P2
- **位置**: [lib/domain/logic/scale_registry.dart:5](file:///d:/Batch/chroniccare/lib/domain/logic/scale_registry.dart#L5) + [lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart)
- **现状**: 12 量表中心化入口，10 开放 + 2 TODO unavailable
- **目标**: v0.31+ 决定 hybrid 后实现
- **类别**: 架构层面 | 修复难度: 中 | 优先级: P2

#### H-4: PHQ-9/GAD-7 16 题全文 i18n — P0（v1.0 blocker）
- **位置**: [lib/domain/entities/scale_translations.dart:17](file:///d:/Batch/chroniccare/lib/domain/entities/scale_translations.dart#L17)
- **现状**: R65 起步 abstract class，16 题题目 + 5 档严重度 + 4 档选项 + 2 instruction 未 i18n 化
- **影响**: en / zh_Hant 用户做 PHQ-9 / GAD-7 看到中文题目 → **医疗法律责任**
- **类别**: 底层实现 | 修复难度: 中（8-16h） | 优先级: **P0**

#### H-5: iOS / Android 上架配置 11 项 — P0
- **位置**: [docs/audit/2026-08-06/04-appstore-ios-report.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/04-appstore-ios-report.md) + [05-googleplay-android-report.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/05-googleplay-android-report.md)
- **清单**:
  1. Apple Developer 账号 + Team ID（用户侧）
  2. Google Play Console 账号（用户侧）
  3. App Store 应用元数据（icon / screenshot / description）
  4. Play Store 应用元数据（同上）
  5. iOS 签名证书 + Provisioning Profile
  6. Android Release Keystore（[android/key.properties.example](file:///d:/Batch/chroniccare/android/key.properties.example) 已就绪，需用户生成 .jks）
  7. Play App Signing 启用
  8. App Store Connect API Key
  9. Google Play Service Account JSON
  10. Data Safety Form（Google Play 必填）
  11. App Privacy Report（Apple 必填）
- **类别**: 底层实现 | 修复难度: 中（多项用户侧操作） | 优先级: **P0**

#### H-6: 设计资源 4 项 — P1
- **现状**:
  - iOS screenshot（6.5"、iPad 12.9"）
  - Android screenshot（phone + 7" tablet + 10" tablet）
  - App icon 1024×1024 PNG（已有 master，需 store-ready 版本）
  - Promo video（30s demo，YouTube URL 当前为 PLACEHOLDER）
- **类别**: 底层实现 | 修复难度: 中（需设计师） | 优先级: P1

### 2.3 架构设计缺陷（已在 R95 大幅改善）

#### A-1: 4 层架构 + core/ umbrella — ✅ 当前最优解

**评估结论**:
- `domain/` 0 Flutter / 0 Drift 依赖 ✅（grep 验证仅 1 处注释，非实际 import）
- `core/shared/` 0 Flutter / 0 Drift 依赖 ✅（同上）
- `data/` 0 import `presentation/` ✅
- 跨 feature 边界 ✅（17 守门员 `check_cross_feature.py` 全绿）

**优势**: 隐私边界（vent 独立表 + 不进分析）通过架构强制保证；domain 层 0 Flutter 依赖 → 单元测试最快

#### A-2: services/ 28+ 文件 — 🟡 已抽 3 facade 但 notification 仍偏大

- **现状**: `lib/core/data/services/` 目录 28+ 文件，notification_service / data_export_service / safety_watch_service 等 god class 倾向
- **R95 改善**: notification_service 已抽 3 facade（reminder / safety / assessment）子；data_export_service 已加 50+ test
- **类别**: 架构层面 | 修复难度: 中 | 优先级: P3

### 2.4 建议重构的模块

#### R-1: home_page_state.dart 650 行 — P3
- **位置**: [lib/presentation/pages/home/home_page_state.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/home/home_page_state.dart)
- **现状**: R95 sub-spec 4 task 5 已拆 home_page.dart 124 行 + state 650 行
- **目标**: 抽 `HomeDeepLinkHandler` / `HomeCareEngineDispatcher` / `HomeCelebrationController` 3 helper，减到 ~450 行
- **类别**: 架构层面 | 修复难度: 中（1-2h，需 10+ 集成测试保护） | 优先级: P3

#### R-2: mood_audio_section 591 行 god class — P3
- **位置**: [lib/presentation/pages/mood/widgets/mood_audio_section.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/mood/widgets/mood_audio_section.dart)
- **目标**: 拆 3 sub-widget（AudioRecorderSection + AudioPlayerSection + RecordControlsSection），减到 ~300 行
- **类别**: 架构层面 | 修复难度: 中（2-3h） | 优先级: P3

#### R-3: notification_service const 改 final — P2
- **位置**: [lib/core/data/services/notification_service.dart](file:///d:/Batch/chroniccare/lib/core/data/services/notification_service.dart)
- **现状**: R77-10 partial 改了 4 处 const 通知 channel，剩 4 处待改 final + 构造函数接受 l10n 函数
- **类别**: 底层实现 | 修复难度: 中（4-6h，需 10+ test） | 优先级: P2

#### R-4: setup_page wizard 4 step state 化 — P3
- **位置**: [lib/presentation/pages/setup/setup_page.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/setup/setup_page.dart)
- **现状**: 501 行 4 step facade
- **目标**: 4 step 改 ConsumerStatefulWidget 内部管 state，setup_page 退化为 stepper orchestrator ~250 行
- **类别**: 架构层面 | 修复难度: 中（4-6h） | 优先级: P3

---

## 第 3 部分：顶层架构审视

### 3.1 当前架构评估

```
lib/
├── main.dart                  # 入口（启动顺序 + SQLCipher + 通知 init + runZonedGuarded）
├── app.dart                   # AppRoot + midnight timer + lifecycle observer
├── core/                      # 基础设施 umbrella (5 子层)
│   ├── data/                  # data 层（DB / Repositories / Services / Utils）
│   ├── shared/                # 跨层共享（formatters / json_codec / domain_value）
│   ├── theme/                 # AppTokens + M3 主题
│   ├── routing/               # go_router
│   └── l10n/                  # domain 层 strings（通知/邮件 fallback）
├── l10n/                      # presentation 层 flutter_localizations
├── domain/                    # 0 Flutter 0 Drift 业务层
└── presentation/              # UI 层
```

**架构评分**: 9.0/10

| 评估项 | 评分 | 说明 |
|--------|------|------|
| 分层清晰度 | 9.5 | 4 层 + core umbrella，依赖方向单向，`check_all.dart` 守门员强制 |
| 高内聚 | 9.0 | R95 已拆 6 god page，0 个 600+ 行大文件 |
| 低耦合 | 8.5 | 跨 feature 边界有 `check_cross_feature.py` 守门；Provider 拆 5 文件（core / service / vent / mood / cbt） |
| 可测试性 | 9.5 | domain 0 Flutter → 单元测试最快；2019 tests pass |
| 隐私边界 | 9.5 | vent 独立表 + 架构强制不进分析/通知/关怀 |
| 可维护性 | 9.0 | 18 守门员 + coverage 阈值 + lock-in tests |

### 3.2 依赖关系矩阵（实测）

```
                domain  core/shared  core/data  core/theme  core/routing  core/l10n  l10n  presentation
domain            -        ✅使用      ❌禁      ❌禁         ❌禁         ✅使用     ❌禁    ❌禁
core/shared       -          -         ❌禁      ❌禁         ❌禁         ❌禁       ❌禁    ❌禁
core/data         -          -          -        ❌禁         ❌禁         ✅使用     ❌禁    ❌禁
core/theme        -          -          -          -          ❌禁         ❌禁       ❌禁    ❌禁
core/routing      -          -          -          -           -          ❌禁       ✅使用  ❌禁
core/l10n         -          -          -          -           -           -        ❌禁    ❌禁
l10n              -          -          -          -           -           -         -     ❌禁
presentation      -          -          -          -           -           -         -      -
```

✅ = 允许使用，❌ = 禁止（守门员强制）

### 3.3 是否最优解？— 是

**结论**: 当前 4 层 + core umbrella 是 Flutter 项目中较优的架构选择，对比备选方案：

| 备选方案 | 评估 | 当前是否更优 |
|----------|------|--------------|
| MVVM | 缺乏领域层隔离，业务逻辑混入 ViewModel | ✅ 当前更优（domain 独立可测） |
| Clean Architecture (5+ 层) | 过度工程，Flutter 项目收益递减 | ✅ 当前更优（4 层足够） |
| Feature-first (无分层) | 隐私边界无法强制（vent 内容会泄露到 trend） | ✅ 当前更优（layer-first 强制隔离） |
| BLoC | 比 Riverpod 更模板化，R95 已用 Riverpod 3.x | ✅ 当前更优（Riverpod 3.x 更轻） |

### 3.4 重构方向（按优先级）

| # | 模块 | 类别 | 修复难度 | 优先级 | 重构方向 |
|---|------|------|----------|--------|----------|
| AR-1 | services/ 目录 28+ 文件 | 架构层面 | 中 | P3 | 按 feature 分子目录（notification/ export/ safety/ audio/） |
| AR-2 | repositories/ 平铺 | 架构层面 | 中 | P3 | 按 feature 子目录（已计划，AGENTS.md 第 22 行） |
| AR-3 | home_page_state.dart 650 行 | 架构层面 | 中 | P3 | 抽 3 helper（DeepLinkHandler / CareEngineDispatcher / CelebrationController） |
| AR-4 | mood_audio_section.dart 591 行 | 架构层面 | 中 | P3 | 拆 3 sub-widget |
| AR-5 | usecases/ 仅 4 文件 | 架构层面 | 中 | P3 | usecase 覆盖率低，业务编排仍散落在 service / provider，建议逐步迁移 |
| AR-6 | domain/repositories/ 抽象接口仅 6 个 | 架构层面 | 中 | P3 | 补 user_profile / medication / assessment 等抽象，保持依赖倒置一致 |

---

## 第 4 部分：底层代码逐行排查

### 4.1 Critical / Major Bugs

> **R96 验证更新**: 初版报告列出的 B-1 / B-2 / B-3 三个"新发现 Bug"经直接读源代码
> 验证后**全部不存在** (初版报告委派 subagent 做"底层代码逐行排查"，subagent 未实际
> 读代码就给出错误诊断)。下表保留原文 + R96 验证结论，作为审计追溯。

#### B-1: ~~app.dart didChangeAppLifecycleState 多次 DateTime.now() 调用~~ — ✅ 验证后不存在
- **位置**: [lib/app.dart:199](file:///d:/Batch/chroniccare/lib/app.dart#L199)
- **初版报告**: "DateTime.now() 跨 midnight 多次调用 race"
- **R96 验证**: `final now = DateTime.now();` **只调用一次**，L201 `crossedMidnightSince(last, now)` 和 L209 `_lastCheck = now;` 都复用同一变量。**无 race condition**。
- **结论**: ❌ 误报，无需修复

#### B-2: ~~mood_audio_service `_sttController` 未在 dispose 关闭~~ — ✅ 验证后不存在
- **位置**: [lib/core/data/services/mood_audio_service.dart:367](file:///d:/Batch/chroniccare/lib/core/data/services/mood_audio_service.dart#L367)
- **初版报告**: "StreamController 泄漏，每次进/出页面都漏一个"
- **R96 验证**: L367 `await _sttController.close();` **已在 dispose() 方法内** (L352-368)。已正确 dispose。
- **结论**: ❌ 误报，无需修复

#### B-3: ~~reminder_scheduler.dart sortedMeds.first 未显式非空检查~~ — ✅ 验证后不存在
- **位置**: [lib/core/data/services/reminder_scheduler.dart:137](file:///d:/Batch/chroniccare/lib/core/data/services/reminder_scheduler.dart#L137)
- **初版报告**: "sortedMeds.first 未检查 isEmpty"
- **R96 验证**: L137 `final firstMed = sortedMeds.isEmpty ? null : sortedMeds.first;` **已做非空检查**。已正确处理。
- **结论**: ❌ 误报，无需修复

#### B-4: vent_compose_page dispose 异步未 await — Major
- **位置**: [lib/presentation/pages/vent/vent_compose_page.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/vent/vent_compose_page.dart)
- **现状**: R74 P2-1 报告 → R75 → R76 → R77 仍未修
- **影响**: `await _recorder.stop()` / `_player.dispose()` 不 await，可能资源泄漏 + 文件锁冲突（AGENTS.md "已知坑" 明确提到）
- **类别**: 底层实现 | 修复难度: 低（0.5-1h） | 优先级: **P2**

#### B-5: home_page mounted check 缺失 — Major
- **位置**: [lib/presentation/pages/home/home_page.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/home/home_page.dart)
- **影响**: Future 回调时 widget 已卸载仍调用 context → `use_build_context_synchronously`
- **类别**: 底层实现 | 修复难度: 低 | 优先级: **P1**

### 4.2 Minor Bugs / 优化点

#### O-1: badge_sync_service catch (e) 未用 swallowError 包装 — Minor
- **位置**: [lib/core/data/services/badge_sync_service.dart](file:///d:/Batch/chroniccare/lib/core/data/services/badge_sync_service.dart)
- **现状**: R76 P3-3 报告，唯一用 `catch (e)` 但 0 `swallowError(where, error, stack)` 包装
- **类别**: 底层实现 | 修复难度: 低（10min） | 优先级: P3

#### O-2: data_export_service Map<dynamic, dynamic> 类型不安全 — Minor
- **位置**: [lib/core/data/services/data_export_service.dart](file:///d:/Batch/chroniccare/lib/core/data/services/data_export_service.dart)
- **影响**: 多处 `Map<dynamic, dynamic>` / `List<dynamic>` 未做类型限制
- **类别**: 底层实现 | 修复难度: 中 | 优先级: P2

#### O-3: 重复 `_daysBetween` 逻辑 — Minor
- **位置**: [lib/core/data/services/reminder_scheduler.dart](file:///d:/Batch/chroniccare/lib/core/data/services/reminder_scheduler.dart) + [lib/domain/usecases/check_in_usecases.dart](file:///d:/Batch/chroniccare/lib/domain/usecases/check_in_usecases.dart)
- **类别**: 架构层面 | 修复难度: 中 | 优先级: P3

#### O-4: home_page Column 未包 SingleChildScrollView — Minor
- **位置**: [lib/presentation/pages/home/home_page.dart:182](file:///d:/Batch/chroniccare/lib/presentation/pages/home/home_page.dart#L182)
- **影响**: 小屏设备可能溢出
- **类别**: 底层实现 | 修复难度: 低 | 优先级: P2

#### O-5: consent_dialog 硬编码字符串 — Major
- **位置**: [lib/presentation/widgets/consent_dialog.dart:98](file:///d:/Batch/chroniccare/lib/presentation/widgets/consent_dialog.dart#L98)
- **现状**: R95 sub-spec 3 已批量清硬编码中文，但 consent_dialog 仍有遗漏
- **类别**: 底层实现 | 修复难度: 中 | 优先级: P1

### 4.3 守门员覆盖盲点

| 守门员 | 覆盖范围 | 盲点 |
|--------|----------|------|
| `check_widget_dispose.py` | 资源泄漏 | StreamSubscription / Controller 未覆盖完整 |
| `check_strings_hardcoded.py` | 硬编码中文 | consent_dialog 仍有遗漏（守门员未抓到） |
| `check_datetime_race.py` | DateTime.now() 跨函数 race | app.dart:199 跨 midnight 场景未触发 |
| `check_coverage.py` | coverage 阈值 | presentation 57.4% 阈值偏低 |

### 4.4 Bug 与优化点总清单（按优先级排序）

| # | 类型 | 类别 | 严重度 | 修复难度 | 优先级 | 描述 |
|---|------|------|--------|----------|--------|------|
| B-1 | Bug | 底层实现 | Critical | 低 | **P0** | app.dart DateTime.now() 跨 midnight race |
| B-2 | Bug | 底层实现 | Major | 低 | **P0** | mood_audio_service _sttController 未 dispose |
| B-3 | Bug | 底层实现 | Major | 中 | **P0** | reminder_scheduler sortedMeds.first 未非空检查 |
| B-5 | Bug | 底层实现 | Major | 低 | **P1** | home_page mounted check 缺失 |
| O-5 | Bug | 底层实现 | Major | 中 | **P1** | consent_dialog 硬编码字符串 |
| B-4 | Bug | 底层实现 | Major | 低 | P2 | vent_compose_page dispose 异步未 await |
| O-2 | 优化点 | 底层实现 | Minor | 中 | P2 | data_export_service 类型不安全 |
| O-4 | 优化点 | 底层实现 | Minor | 低 | P2 | home_page Column 未包滚动 |
| R-3 | 重构 | 底层实现 | Minor | 中 | P2 | notification_service const 改 final |
| O-1 | 优化点 | 底层实现 | Minor | 低 | P3 | badge_sync_service swallowError 包装 |
| O-3 | 优化点 | 架构层面 | Minor | 中 | P3 | _daysBetween 重复逻辑 |
| R-1 | 重构 | 架构层面 | Minor | 中 | P3 | home_page_state 抽 3 helper |
| R-2 | 重构 | 架构层面 | Minor | 中 | P3 | mood_audio_section 拆 3 sub-widget |
| R-4 | 重构 | 架构层面 | Minor | 中 | P3 | setup_page wizard state 化 |

---

## 第 5 部分：开发需求文档更新

### 5.1 文档更新原则

- **不重复**: SPRINT1_LEGAL_TODO / SPRINT2_TODO / VERSION_1.0_PLAN 各自维护细节
- **集中索引**: 本报告作为"找得到 + 优先级清楚"的总览
- **跟实际同步**: 每条 TODO 注明当前 round 状态

### 5.2 待办事项汇总（按优先级高→低，跨 SPRINT1 + SPRINT2 + 本报告新发现）

#### 🔴 P0 — 上架 / v1.0 blocker（必须修）

| # | 任务 | 类别 | 修复难度 | 阻塞 | 责任方 | 当前状态 |
|---|------|------|----------|------|--------|----------|
| P0-1 | 律师 review 3 份法律 md | 底层实现 | 高（¥45-90k + 1-2 周） | 上架 | 法务 | 未做（S-1.1） |
| P0-2 | 邮箱 support@chroniccare.app 注册 | 底层实现 | 低（1-2h） | ~~上架~~ | 工程 | ✅ **R96 已软隐藏**（不阻塞当前版本，域名注册后启用） |
| P0-3 | GitHub 仓库 github.com/example/chroniccare 替换 | 底层实现 | 低（0.5 天） | ~~上架~~ | 工程 | ✅ **R96 已软隐藏**（不阻塞当前版本，仓库创建后启用） |
| P0-4 | 域名 chroniccare.app 注册 + ICP 备案 + HTTPS 部署 | 底层实现 | 中（1-2 天 + 7-20 天 ICP） | 上架 | 工程 | 未做（S-1.4 + E-1） |
| P0-5 | fastlane/Appfile Apple ID/Team ID 替换 | 底层实现 | 低 | ~~上架~~ | 工程 | ✅ **R96 已软隐藏**（改 ENV 模式，真实值通过 .env 注入） |
| P0-6 | iOS / Android 上架配置 11 项（H-5） | 底层实现 | 中 | 上架 | 工程 + 用户 | 部分就绪 |
| P0-7 | PHQ-9/GAD-7 16 题全文 i18n（H-4） | 底层实现 | 中（8-16h） | v1.0 医疗法律责任 | 工程 | R65 起步，未完成 |
| P0-8 | 阿里云 SMS 真接（FeatureFlags.aliyunSmsEnabled） | 底层实现 | 高（1-2 月法务） | v1.0 失联通知 | 工程 + 法务 | R55 起步，未完成 |
| P0-9 | SendGrid 邮件真接（FeatureFlags.emailServiceEnabled） | 底层实现 | 中（1-2 周） | v1.0 邮件导出 | 工程 | 未做 |
| P0-10 | IAP 真接 productId（FeatureFlags.iapEnabled） | 底层实现 | 中 | v1.0 收入 | 工程 + Apple/Google | 未做 |
| P0-11 | 5 厂商 push SDK 接入（FeatureFlags.fiveVendorPushEnabled） | 底层实现 | 高（1-2 月审核） | v1.0 国产 ROM 通知到达率 | 工程 | 未做 |
| ~~P0-12~~ | ~~app.dart DateTime.now() 跨 midnight race（B-1）~~ | 底层实现 | ~~低~~ | ~~streak 正确性~~ | 工程 | ❌ **R96 验证后不存在**（误报，代码只调一次 now） |
| ~~P0-13~~ | ~~mood_audio_service _sttController 未 dispose（B-2）~~ | 底层实现 | ~~低~~ | ~~内存泄漏~~ | 工程 | ❌ **R96 验证后不存在**（误报，L367 已 close） |
| ~~P0-14~~ | ~~reminder_scheduler sortedMeds.first 未非空检查（B-3）~~ | 底层实现 | ~~中~~ | ~~空 meds 崩~~ | 工程 | ❌ **R96 验证后不存在**（误报，L137 已 isEmpty 检查） |

#### 🟡 P1 — 上架前应修

| # | 任务 | 类别 | 修复难度 | 当前状态 |
|---|------|------|----------|----------|
| P1-1 | iOS Podfile 真实生成（H-1） | 底层实现 | 低（0.5h，需 macOS） | R77-8 占位 |
| P1-2 | package_info_plus 引入（H-2） | 底层实现 | 中（4-6h） | R77-13 折中 const |
| P1-3 | home_page mounted check（B-5） | 底层实现 | 低 | **本报告新发现** |
| P1-4 | consent_dialog 硬编码字符串清零（O-5） | 底层实现 | 中 | R95 sub-spec 3 遗漏 |
| P1-5 | demo 视频制作 + YouTube URL 替换（E-4） | 底层实现 | 中（需设计师） | PLACEHOLDER 占位 |
| P1-6 | 设计资源 4 项（H-6） | 底层实现 | 中 | 未做 |

#### 🟢 P2 — v1.0+ 可做

| # | 任务 | 类别 | 修复难度 | 当前状态 |
|---|------|------|----------|----------|
| P2-1 | vent_compose_page dispose 异步 await（B-4） | 底层实现 | 低 | R74 报告 3 轮未修 |
| P2-2 | notification_service const 改 final（R-3） | 底层实现 | 中 | R77-10 partial 1/5 |
| P2-3 | NSESSS / CRDPSS 2 量表（H-3） | 架构层面 | 中 | R65 决策 hybrid 后做 |
| P2-4 | MEDICAL_DISCLAIMER 4 处 URL 替换（E-5） | 底层实现 | 低 | 跟 P0-4 一起 |
| P2-5 | data_export_service 类型安全（O-2） | 底层实现 | 中 | — |
| P2-6 | home_page Column 滚动（O-4） | 底层实现 | 低 | — |
| P2-7 | BootReceiver 完善（FeatureFlags.bootReceiverEnabled） | 底层实现 | 中 | R93 关闭避风险 |
| P2-8 | 紧急联系人 SMS 业务（FeatureFlags.emergencyContactEnabled） | 底层实现 | 中 | 依赖 P0-8 |

#### ⚪ P3 — NIT（Not In Time，可延后）

| # | 任务 | 类别 | 修复难度 | 当前状态 |
|---|------|------|----------|----------|
| P3-1 | home_page_state 抽 3 helper（R-1） | 架构层面 | 中 | R76 P3-1 评估至今 0 改善 |
| P3-2 | mood_audio_section 拆 3 sub-widget（R-2） | 架构层面 | 中 | R76 新发现 |
| P3-3 | setup_page wizard state 化（R-4） | 架构层面 | 中 | R77 集成测已保 |
| P3-4 | services/ 按 feature 分子目录（AR-1） | 架构层面 | 中 | — |
| P3-5 | repositories/ 按 feature 子目录（AR-2） | 架构层面 | 中 | AGENTS.md 已计划 |
| P3-6 | usecases/ 补抽象（AR-5 + AR-6） | 架构层面 | 中 | — |
| P3-7 | badge_sync_service swallowError（O-1） | 底层实现 | 低 | R76 P3-3 |
| P3-8 | _daysBetween 重复逻辑抽取（O-3） | 架构层面 | 中 | — |
| P3-9 | vent audio 业务闭环（FeatureFlags.ventAudioEnabled） | 底层实现 | 中 | R93 关闭 |

### 5.3 文档同步清单

| 文档 | 更新内容 | 责任 |
|------|----------|------|
| [docs/SPRINT1_LEGAL_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md) | 新增 P0-12 / P0-13 / P0-14（本报告新发现 bug） | 工程 |
| [docs/SPRINT2_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT2_TODO.md) | 新增 P0-12 / P0-13 / P0-14（本报告新发现 bug） + P1-3 / P1-4 | 工程 |
| [docs/VERSION_1.0_PLAN.md](file:///d:/Batch/chroniccare/docs/VERSION_1.0_PLAN.md) | §0.2 R95 实施后关键决策 → 补本报告 14 项新发现 | 工程 |
| [AGENTS.md](file:///d:/Batch/chroniccare/AGENTS.md) | 待办清单 → 补 P0-12 / P0-13 / P0-14 | 工程 |
| [docs/CHANGELOG.md](file:///d:/Batch/chroniccare/docs/CHANGELOG.md) | 下次 commit 补 `[0.30.1]` 修复 P0-12 / P0-13 / P0-14 | 工程 |

### 5.4 总体评估

| 维度 | 当前状态 | 上架就绪度 |
|------|----------|------------|
| 代码质量 | ✅ 2019 tests, 0 error, 18 守门员 | 95% |
| 架构 | ✅ 4 层 + core umbrella 最优 | 95% |
| 工程自动化 | ✅ 18 守门员 + coverage 阈值 | 95% |
| 法务 | 🟡 R96 软隐藏 P0-2/3/5 后, 仅剩律师 review + 域名 | 30% (↑ R96) |
| 业务真接 | ❌ 5 项 FeatureFlags 全锁 | 0% |
| 上架配置 | 🟡 iOS / Android 11 项部分就绪, R96 Appfile ENV 化 | 45% (↑ R96) |
| 设计资源 | ❌ 4 项未做 | 0% |
| **总体上架就绪度** | — | **~45%** (↑ R96 +5%) |

**核心建议** (R96 更新):

1. ~~立即修 3 个新发现 Bug~~（P0-12 / P0-13 / P0-14）— ❌ R96 验证后全部不存在，无需修复
2. ~~优先推 P0-2 / P0-3 / P0-5~~（邮箱 + GitHub + Apple ID）— ✅ R96 已软隐藏，不阻塞当前版本
3. **同步推 P0-4 + P0-1**（域名 + 律师）— 域名 1-2 天注册 + ICP 7-20 天 + 律师 1-2 周，最早启动最早完成。域名注册后可取消 P0-2/3 软隐藏
4. **P0-7 PHQ-9 i18n** 是医疗法律责任 blocker，建议优先于其他业务真接
5. **业务真接 5 项**（SMS / Email / IAP / 5 厂商 push / vent audio）全部依赖外部资源，需用户侧启动法务 + 申请流程
6. **R96 软隐藏策略说明**: P0-2/3/5 跟 `privacy@chroniccare.app` 同一软隐藏策略，用户通过 App 内 设置 → 法律与隐私 页面反馈。这是过渡方案，长期建议保留可达渠道（PIPL §52）

---

## 附录 A: 守门员脚本清单（18 个，全绿）

1. `python scripts/check_arb_keys.py` — zh / en / zh_Hant ARB 同步
2. `python scripts/check_changelog.py` — pubspec 版本号 + CHANGELOG 顺序
3. `python scripts/check_cross_feature.py` — 跨 feature import 边界
4. `python scripts/check_datetime_race.py` — 跨函数 DateTime.now() 多次调用
5. `python scripts/check_datetime_race2.py` — 跨 DateTime(year,month,day) 多次调用
6. `python scripts/check_drift_namespace.py` — @DataClassName 唯一
7. `python scripts/check_fullwidth_punctuation.py` — 全角标点 (warn-only)
8. `python scripts/check_no_hardcoded_utc.py` — UTC 硬编码
9. `python scripts/check_no_pua.py` — PUA 字符
10. `python scripts/check_widget_dispose.py` — 资源泄漏
11. `python scripts/check_orphan_arb_keys.py` — ARB key 定义但未引用
12. `python scripts/check_legal_consent.py` — 单独同意 / PIPL §13 / §14 检测
13. `python scripts/check_sms_release_ready.py` — SMS 上线前 checklist (warn-only)
14. `python scripts/check_strings_hardcoded.py` — 硬编码中文 string 检测
15. `python scripts/check_zh_hant_consistency.py` — 繁简一致性 (OpenCC s2tw)
16. `python scripts/check_16kb_alignment.py` — Android 16KB page size 验证 (Google Play 2025-11-01 强制)
17. `python scripts/check_coverage.py` — coverage 阈值 (R95 新增)
18. `dart scripts/check_all.dart` — 4 层架构纯度 + 一致性

## 附录 B: 参考资料

- [AGENTS.md](file:///d:/Batch/chroniccare/AGENTS.md) — 项目代码视角指引
- [README.md](file:///d:/Batch/chroniccare/README.md) — 产品视角
- [docs/SPRINT1_LEGAL_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md) — Sprint 1 法务待办
- [docs/SPRINT2_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT2_TODO.md) — Sprint 2 工程待办
- [docs/VERSION_1.0_PLAN.md](file:///d:/Batch/chroniccare/docs/VERSION_1.0_PLAN.md) — v1.0 路线图
- [docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md) — R95 整体总结
- [docs/audit/2026-08-06/04-appstore-ios-report.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/04-appstore-ios-report.md) — AppStore 6 视角
- [docs/audit/2026-08-06/05-googleplay-android-report.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/05-googleplay-android-report.md) — GooglePlay 6 视角
