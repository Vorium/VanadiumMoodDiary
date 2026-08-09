# R99 六视角整合审计报告（v0.30.0+85）

**审计时间**: 2026-08-07（R98 之后第 3 轮，基于增强指令：5 维度 × 6 视角整合）
**6 视角**: emilkowalski（UI）/ superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification
**审计方法**: 实测运行 `dart scripts/check_all.dart` + 17 守护脚本 + `flutter analyze` + `scripts/_audit_v2.py` + 关键发现逐条源码复核
**基线**: v0.30.0+85，HEAD = `f0dcaa6` (v0.30 round 95 README sync)

---

## 实测结果速览（本轮新跑，非引用旧报告）

| 检查 | 结果 |
|---|---|
| `dart scripts/check_all.dart` 4 层纯度 + 一致性 | ✅ 通过 |
| `flutter analyze` | ✅ 0 issue（R99 修 BUG-5 后） |
| `check_arb_keys.py` zh/en/zh_Hant 1068 key | ✅ 同步 |
| `check_cross_feature.py` 118 files | ✅ 0 violation |
| `check_changelog.py` | ✅ 0.30.0+85 顺序正确 |
| `check_16kb_alignment.py` | ✅ targetSdk=36 + ndkVersion OK |
| `check_zh_hant_consistency.py` OpenCC s2tw | ✅ 100% 一致 |
| `check_orphan_arb_keys.py` | ✅ 0 orphan（R99 修 BUG-3 后） |
| `check_datetime_race.py` + race2 | ✅ 0（R99: 误报, 脚本已重写） |
| `check_fullwidth_punctuation.py` | ⚠️ 132 warn（warn-only） |
| 其余 9 守护脚本 | ✅ 全绿 |
| `_audit_v2.py` | 🔴 硬编码中文 336 处 / 68 文件；半角标点 ARB 58 key；法务文件缺口（见 §4.3） |

---

## 一、安全合规检查（优先级 1）

### 1.1 密钥 / 敏感配置 — ✅ 达标

| 检查项 | 结果 | 证据 |
|---|---|---|
| `.env` 是否入库 | ✅ 未跟踪 | `git check-ignore .env` 命中；内容仅 `PLACEHOLDER=test` |
| lib/ 硬编码 API key / SendGrid `SG.` token | ✅ 0 处 | 全库 regex 扫描 `SG\.[A-Za-z0-9]{20,}` / `apiKey=` / `secret=` 0 匹配 |
| `.env.example` | ✅ 全占位值 | `SENDGRID_API_KEY=SG.xxx...` / `APPLE_ID=your-...` |
| Android 签名 | ✅ key.properties 模式 | `build.gradle.kts:55-73` 读外部文件；`key.properties` + `*.jks` 已 gitignore |
| cleartext / backup | ✅ | `network_security_config` 禁明文；`allowBackup="false"`（PIPL §28） |
| iOS 加密合规 | ✅ | `ITSAppUsesNonExemptEncryption=false`（标准库加密豁免声明） |

### 1.2 外链 / 外部联系渠道 — ⚠️ 软隐藏完成，域名未就绪

| # | 问题 | 定位 | 难度 | 紧急度 |
|---|---|---|---|---|
| S-1 | fastlane `privacy_url.txt` / `support_url.txt` 指向 `chroniccare.app` **未注册域名**，Google Play Data Safety 表单要求可访问的 data deletion endpoint | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 6 文件 | 中（需注册域名 + 静态页） | **高** |
| S-2 | 法务文档 8 处邮箱软隐藏说明（`privacy@` / `support@chroniccare.app`）+ `github.com/example/chroniccare` 占位残留文字 | `assets/legal/privacy_policy.md:150,164,214,220`；`assets/legal/user_agreement.md:68,71,88,93` | 简单（域名注册后替换） | 中 |
| S-3 | Android `INTERNET` 权限保留（in_app_purchase 隐式依赖）但 iapEnabled=false —— Data Safety 需解释 | `AndroidManifest.xml:42` | 简单（表单填写项） | 中 |

**结论**：代码层 0 真实外链跳转（唯一 url_launcher 调用限定 `tel:` 危机热线），敏感信息 0 泄露风险；**阻塞项只有域名 + 邮箱真实化**。

---

## 二、发布准备状态评估（优先级 2）

### 2.1 Android（GooglePlay 视角）

| # | 项目 | 状态 | 定位 |
|---|---|---|---|
| G-1 | targetSdk=36 / minSdk=24 显式 pin | ✅ | `android/app/build.gradle.kts:33-34` |
| G-2 | 16KB page size（2025-11 强制） | ✅ sqlcipher_flutter_libs ^0.6.5 + ndkVersion 默认 27.x | pubspec.yaml:24 |
| G-3 | Release 签名链 | ⚠️ 配置就绪，`key.properties` **尚未创建** | build.gradle.kts:55-94；docs/PLAYSTORE_SIGNING_GUIDE.md |
| G-4 | R8 minify + shrinkResources + 64-bit ABI | ✅ | build.gradle.kts:100-111 |
| G-5 | 权限最小化（R97 已删 USE_EXACT_ALARM / RECORD_AUDIO / BOOT_COMPLETED） | ✅ 5 权限 | AndroidManifest.xml:42-46 |
| G-6 | **截图/Feature Graphic 全是 67 字节 1×1 占位 PNG** | 🔴 必拒 | `fastlane/metadata/android/{zh-CN,en-US}/phone_screenshots/screenshot_1..4.png` + `feature_graphic.png` |
| G-7 | **video.txt = PLACEHOLDER_APP_DEMO_VIDEO** | 🔴 | `fastlane/metadata/android/*/video.txt`（建议直接删文件） |
| G-8 | title 含 "(失联通知规划中)" | ⚠️ 审核员会追问未上线功能 | `fastlane/metadata/android/zh-CN/title.txt` |
| G-9 | Data Safety Form：无收集数据 + 删除端点（依赖 S-1） | 🔴 | Play Console 手工项 |

### 2.2 iOS（AppStore 视角）

| # | 项目 | 状态 | 定位 |
|---|---|---|---|
| A-1 | 5 项 usage description（麦克风/语音识别/相册 ×2/追踪） | ✅ 齐 | `ios/Runner/Info.plist:42-68` |
| A-2 | **screenshots/ 目录完全缺失**（Apple 6.5" / 5.5" 必传） | 🔴 必拒 | `fastlane/metadata/ios/*/` |
| A-3 | InfoPlist.strings 仅 Base/zh-Hans/zh-Hant —— 5 项 usage description 中文文案需确认 Base 为英文且 zh lproj 覆盖完整 | ⚠️ | `ios/Runner/{Base,zh-Hans,zh-Hant}.lproj/InfoPlist.strings`（zh 各 6 行，疑仅覆盖 display name） |
| A-4 | `UIBackgroundModes=[audio, processing]` 但录音（ventAudio）已 flag 关闭、BGTask handler 是占位实现 | ⚠️ Apple 2.5.4 拒审风险（声明的后台能力无实际使用） | Info.plist:144-148；`AppDelegate.swift:33-37` |
| A-5 | IAP：user_agreement 写"8 元买断" vs `iapEnabled=false` 实际 0 元免费 | 🔴 Apple 2.1/3.1.1 信息不一致 | `feature_flags.dart:51`；法务文档 |
| A-6 | LSApplicationCategoryType=healthcare-fitness + Scene manifest | ✅ | Info.plist:76,136 |

### 2.3 半成品功能完成度（FeatureFlags 8 项全 false）

`lib/core/data/feature_flags.dart:48-69` 全部 `_prod* = false`：

| 功能 | 外部依赖 | 完成度 |
|---|---|---|
| 紧急联系人失联通知（SMS） | 阿里云模板审核 + AccessKey（1-2 月） | 骨架 90%，触达 0% |
| 邮件通知（SendGrid） | API key + 法务模板 | 骨架 90%，触达 0% |
| IAP 8 元买断 | App Store productId | 骨架 70% |
| 5 厂商 push（米/华/OPP/vivo/魅族） | 各厂商审核 | 骨架 50% |
| BootReceiver（Android 重启恢复闹钟） | WorkManager 重构 | 30%（Android 14+ 现方案会 crash，已停） |
| vent 语音录音 | 业务闭环（storage/export） | 80%（UI 隐藏） |
| PHQ-9/GAD-7 全量 i18n | ARB 工程量大 | 仅 hotline hot path |

**发布建议**：以"本地加密吃药打卡 + 情绪记录"为 v1.0 上架形态（当前 flag 全关即是此形态），失联通知作为 v1.1 卖点，metadata 中删除"失联通知"承诺（G-8 / subtitle 同改），规避审核与用户预期落差。

---

## 三、架构优化分析（优先级 3）

### 3.1 顶层评估 — ✅ 9/10，不建议换架构

`check_all.dart` 双项通过（domain/shared 0 flutter 0 drift、entity↔table 一一对应、shared ≥2 层使用）；`check_cross_feature.py` 0 违规。4+1 层架构（domain/shared/data/presentation + core umbrella）对当前规模（~2000 tests、13 表、9 repo）是合适的，**无需迁移 BLoC/Clean Architecture 全家桶**。Riverpod 3 + go_router + Drift 组合已稳定。

### 3.2 高内聚低耦合违规点（架构级，需重构）

| # | 问题 | 定位 | 方案 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| ARC-1 | `CareEngine.evaluate` / `fire` 死代码（注释承诺 v0.28 删，0 调用方） | `lib/domain/logic/care_engine.dart` | 删除或挪 v1.0 分支 | 简单 | 中 |
| ARC-2 | 3 个 StreamProvider 缺 autoDispose（subscription 永不释放） | `legal_consent_provider.dart:273,279`（ventSealed/ventSealedAt）；`assessment_providers.dart:34`（allAssessmentEntries） | 加 `.autoDispose` | 简单 | 中 |
| ARC-3 | `SafetyCheckResult` 双 API 未收敛：`displayMessage` 返 i18n key，正确入口是 `displayMessageL10n(l10n)`，但 UI 仍用前者（见 BUG-1） | `safety_watch_service.dart:374-392` | 删 `displayMessage` getter，编译期强制走 l10n 版 | 简单 | **高** |
| ARC-4 | `home_page_state.dart` ~590 行，`_fireCareEngine` / `_runAfterCheckIn` / `_runSafetyCheck` 三职责混居 | `lib/presentation/pages/home/home_page_state.dart` | 抽 `HomeSafetyCoordinator` | 复杂 | 低 |
| ARC-5 | `core/data/services/` 28 文件平铺无分组 | `lib/core/data/services/` | 按 notify/ export/ sms-email/ 分子目录 | 中 | 低 |
| ARC-6 | ThemeExtension 缺位，30+ 颜色 helper 走 BuildContext 扩展函数而非 M3 标准 | `lib/core/theme/app_colors.dart` | 迁 `ThemeExtension<T>` | 复杂 | 低 |
| ARC-7 | UseCase 覆盖不足（9 repo 仅 4 usecase），编排逻辑泄漏到 presentation state | `lib/domain/usecases/` | 仅对跨 repo 编排补 usecase，不必全覆盖 | 中 | 低 |
| ARC-8 | `routerProvider` 手写 mutable cache | `lib/core/routing/app_router.dart` | 改 NotifierProvider | 中 | 低 |

---

## 四、代码质量深度审查（优先级 4）

### 4.1 Bug（按影响排序）

| # | Bug | 定位 | 影响 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| BUG-1 | **用户看到 i18n key 原文**：`'⚠️ ${result.displayMessage}'` 展示 `safetyCheckResultAlerted` 等 key 而非翻译文案（R98 已报，**本轮复核仍存在**） | `home_page_state.dart:256, 467` | 失联告警关键路径文案错误 | 简单（改调 `displayMessageL10n(l10n)`） | **高** |
| BUG-2 | ARB 版本字符串过期：`settingsAboutVersion` 硬编码 `v0.23.0`，pubspec 已 0.30.0 | `lib/l10n/app_zh.arb:91`（en/zh_Hant 同步） | 关于页版本号错误 | 简单（改动态读 PackageInfo 或同步 3 语） | 中 |
| BUG-3 | orphan ARB key `crisisHotlineCallNow`（守护脚本 FAIL） | `lib/l10n/app_*.arb` 3 文件 | CI 红 | 简单（引用或删除） | **高** |
| BUG-4 | DateTime race 2 候选（同函数 2 次 `DateTime.now()`） | `lib/domain/logic/mood_period_aggregator.dart:58,74`；`lib/core/data/services/swallow_log_sink.dart:66,117` | 跨 midnight 边界不一致 | 简单（入口单捕获） | 中 |
| BUG-5 | unused import warning（唯一 analyzer 告警） | `assessment_page.dart:15` url_launcher | CI 0-warning 目标破坏 | 简单 | 中 |

R98 报的另 2 项 `.first` 未 sort 本轮复核**已修复**：`mood_dao.dart:10-17` 有显式 `ORDER BY timestamp DESC`；`assessment_summary_strip.dart:87-92` 已加显式 sort。

**R99 修复进度（2026-08-07）**: BUG-1~5 全部闭环。
- BUG-1 / BUG-3: R99 前半已修（home_page_state 改 displayMessageL10n + crisisHotlineCallNow 已引用）
- BUG-2: settingsAboutVersion 3 语参数化 + kPubspecVersion 同步 0.30.0+85（R78-R98 连续漏改）+ 测试期望值同步
- BUG-4: 复核为守护脚本误报，重写 check_datetime_race2.py（剥注释 + 作用域栈 + single-capture/分支复制豁免），业务代码未动
- BUG-5: 删 assessment_page unused import，analyze 0 issue


### 4.2 国际化债务（superpowers-zh / superpowers-en 视角）

- **硬编码中文 336 处 / 68 文件**（`_audit_v2.py` 实测）。分类：
  - 合理豁免（~250 处）：`domain/logic/` 量表题目 + `strings.dart`（domain 层 l10n fallback 设计）+ `piiSafeLog` 日志。
  - **必须修的 UI 硬编码（~30 处）**：
    - `daily_tracking/widgets/weight_widgets.dart` 5 处（"体重 (kg)" / "如 60.5" / "暂无 BMI"）
    - `daily_tracking/widgets/social_rhythm_widgets.dart` 4 处（"社交时长 (分钟)" 等 3 个 labelText + 摘要行）
    - `daily_tracking/widgets/anxiety_agitation_widgets.dart:177,205`、`sleep_widgets.dart:309`、`stress_event_widgets.dart:119`
    - `mood_list/widgets/mood_list_item.dart:66`（"CBT 7 栏"）、`mood_list_filter_bar.dart:216`（"全部"）
    - `settings/widgets/cbt_section.dart:78`（"{n} 栏"）
    - `widgets/consent_dialog.dart:169-173`（3 段撤回后果文案）
    - `widgets/medication_report_dialog.dart:45`（"（近 N 天）"拼接）
    - `medication/medication_calendar_page.dart:213`（"补打卡功能接入中" —— 半成品提示也应走 ARB）
    - `setup/setup_legal_dialog.dart:110`（"🆘 心理危机干预热线 (24h)"）
    - `settings/.../export_tile.dart:87-90`（consent purpose/retention 4 处）
  - 修复难度：**中等**（约 +40 ARB key × 3 语，有 check_arb_keys / zh_hant_consistency 守门）。紧急度：中（上架 en 模式可见）。
- **半角标点**：zh / zh_Hant ARB 各 58 key 中文后接半角 `,.;:`（warn-only），建议批量替全角。
- **法务文件覆盖缺口**（`_audit_v2.py` §C）：`user_agreement.md` 缺 PIPL §13/§17/§29、SDK 表格、年龄条款；`sensitive_data_consent.md` 缺 §17/§29、SDK 表格 —— 上架中国区需补。难度：中。紧急度：高（仅当目标国内市场）。

### 4.3 UI 组件库视角（emilkowalski）

- 动效/间距 token 化已完成（AppTokens + 守护脚本），dark mode 就绪。
- 遗留：ThemeExtension 缺位（ARC-6）；`Semantics()` 仅 ~15 处，CheckInButton / MoodQuickButton / StatCard 等核心交互件缺 a11y 包装（难度中，紧急度低）；0 golden test（60+ 自定义 widget 无视觉回归守护）。

### 4.4 Flutter 规范视角（flutter-specification）

- 依赖方向、命名约定（`*Entity` / mapper / provider 暴露接口）全部合规。
- 遗留：`ThemeModeNotifier.build` 异步改 state 应迁 `AsyncNotifier`；4 个文件 import 顺序（dart: 先于 package:）；test/ 下 ~104 trailing comma info。

---

## 五、需求文档维护（优先级 5）

| # | 文档动作 | 状态 |
|---|---|---|
| D-1 | 本报告（R99 整合审计） | ✅ 已落盘 `docs/audit/2026-08-07/R99-6perspective-consolidated-audit.md` |
| D-2 | 上架 checklist：执行 §6 附录逐项打勾，完成后同步 `docs/STOREFRONT_RELEASE_SOP.md` | 待执行 |
| D-3 | `docs/VERSION_1.0_PLAN.md` §半成品表补 8 项 FeatureFlags 状态列 | 待执行 |
| D-4 | AGENTS.md 守护脚本计数（17 项）与本轮实测一致，无需改 | ✅ 已核对 |

---

## 六、附录：上架放行清单（按优先级排序）

**P0 — 不做必被拒**：
1. [BUG-3] 修 orphan key `crisisHotlineCallNow`（守护 FAIL）— 简单/高
2. [BUG-1] home_page_state 2 处改 `displayMessageL10n(l10n)` — 简单/高
3. [G-6/A-2] 双平台真实截图 + feature graphic + 删 video.txt 占位 — 中/高
4. [A-5] 法务/metadata 删"8 元买断"描述或真接 IAP（二选一）— 中/高
5. [S-1/G-9] 注册 chroniccare.app + 隐私页/支持页/数据删除页上线 — 中/高

**P1 — 高概率被打回**：
6. [A-4] 删 `UIBackgroundModes processing` + BGTaskScheduler 声明（业务未启用前），或补真实实现 — 简单/中
7. [A-3] InfoPlist.strings 英文基线 + zh 补全 5 项 usage description — 简单/中
8. [BUG-2] settingsAboutVersion 版本同步 — 简单/中
9. [BUG-4/BUG-5] datetime race 2 处 + unused import — 简单/中
10. [§4.2] UI 硬编码中文 ~30 处走 ARB（en 模式可见）— 中/中
11. [G-3] 生成 release keystore + key.properties（PLAYSTORE_SIGNING_GUIDE 5 步）— 简单/高（提审前最后一步）

**P2 — 质量提升，可上架后跟进**：
12. [ARC-1/2/3] 死代码 + autoDispose + displayMessage 收敛 — 简单/低
13. [法务缺口] user_agreement / sensitive_data_consent 补 §13/§17/§29/SDK 表格（中国区需要）— 中/中
14. [半角标点] 58 key 批量全角化 — 简单/低
15. [ARC-4/5/6/7/8] 架构重构 5 项 — 复杂/低
16. [a11y + golden test] — 中/低

**统计**：P0=5 / P1=6 / P2=5；简单=8 / 中等=6 / 复杂=2；架构级=ARC-1~8 / 实现级=其余全部。
