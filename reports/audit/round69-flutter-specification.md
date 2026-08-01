# v0.27 R69 flutter-specification 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64 / `HEAD=d691551` (R68 commit "5 视角共识 P0 集中修复")
**审计模式**: 增量 (vs R68 ⭐⭐⭐⭐ 4.5/5 / 88%, 跟踪 R68 commit d691551 落地 + 212 文件 → 5 文件 working tree)
**基线实测**: `dart format` **2 changed (C1.5 回归!)** / 0 analyzer error / **5 warning / 183 info** / **1285 pass + 0 fail** / 16 守护脚本全绿
**参考**: R68 `round68-flutter-specification.md` (16KB / 137 行) + R68 `round68-CONSOLIDATED.md` (CC-1/3/6)

---

## §0 评级

⭐⭐⭐⭐ **4.5/5**(持平 R68)
**合规率 86%** (vs R68 88%, -2%)

**核心判断**:
- ✅ **R68 commit d691551 真修了 3 个 P0 + 2 个 test fail** — CC-3 (IAP 临时关) / CC-6 (CareEngine safety consent 真接) / CC-1 (setup ConsentDialog 真接) + 时区漂移 2 fail → 1285 全过
- ❌ **C1.5 dart format 回归** — R68 commit 改了 `home_page.dart` + `setup_page.dart` 2 文件未 `dart format`,**比 R66 baseline 还差**(R66 修了 C1.5,R68 commit 自己引入回归)
- ❌ **CC-4 + CC-5 + CC-9 + CC-10 4 个 R68 spec 报告的 P0-P1 全未修** — 3 份法律 md TODO banner / pubspec description 单语 / settings_page dark mode 2 处 / app_theme alpha 2 处
- ❌ **E10.6 CI 漏 9 守护脚本** — R68 E10.3 修了 dart format 护栏(加分),但其它 9 个守护脚本仍依赖本地运行
- ✅ **架构 100% 纯** — 4 层 + 5 子 umbrella / 16 守护脚本全绿 / 6 R67 集中器广泛使用(90 命中 / 27 文件)/ 0 Color(0xFF) 散落

**R68 → R69 Δ**:净 -1% 合规率(88%→87%,E10.3 修了 +C1.5 自己回归 -1 + G11 working tree 清了 -1 持平 + CC-3/6/1 修了 加分);**P0 实质改善**(代码层最严重 3 个 P0 + 2 test fail 全清),**流程细节 1 步进 1 步退**(C1.5 回归需 commit 时 `dart format` 防再发)

---

## §1 R68 → R69 增量

### 1.1 R68 commit d691551 已修(3 + 1)

| # | 问题 | 位置 | 修复方式 | R69 验证 |
|---|------|------|---------|----------|
| **CC-3** | IAP 8 元买断 vs `buyLifetime()` 返 false | `feature_flags.dart:38` `_prodIapEnabled = false` | main.dart warmup 跳过 + StoreKitService.buyLifetime 早返 false + UI 隐藏按钮 | ✅ 验证 `_prodIapEnabled = false` 注释 "R68: IAP 8 元买断 ... 临时关闭 IAP 入口" |
| **CC-6** | 隐私政策撒谎 (CareEngine safety consent 撤回未真接) | `fire_care_strategy.dart:155, 163, 202` | `FireCareStrategyInput` 加 `isSafetyConsentWithdrawn` 字段 + `call()` 入口早返 disabled + home_page.dart:533 注入 | ✅ 验证 `home_page._fireCareEngine` 真注入 `isSafetyConsentWithdrawn: isSafetyWithdrawn` |
| **CC-1** | setup 阶段 `saveSetup` 绕过 ConsentDialog | `app_database.dart:307-315` + `setup_page.dart:369-440` | `saveSetup` 加 `contactConsents: List<ConsentArtifact>` 参数 + setup 阶段对每个填了的联系人弹 `ConsentDialog(kind: emergencyContactSharing)` + assert 验证等长 | ✅ 验证 `setup_page._finishSetup` 真弹 ConsentDialog + 拒绝任一 → 终止 setup |
| **回归** | 2 test fail 时区漂移 (`sort_assumption_round19b_test.dart:125` + `safety_watch_service_round12_test.dart:260`) | — | R68 commit 信息 "R66 baseline 是 1283 + 2 fail 时区漂移, R68 1285 pass" | ✅ **1285 pass, 0 fail** |

### 1.2 R68 spec 报告 P0-P1 未修(7 项)

| # | 章节 | 问题 | R68 位置 | R69 状态 |
|---|------|------|---------|---------|
| **CC-4** | 架构 / 法律 | 3 份法律 md 顶部 "**TODO 律师过审**" banner 仍保留 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md:3-4` | ❌ **未修** — 3 份 md 顶部仍标 "TODO (上 store 前必须由专业律师过审)" |
| **CC-5** | 底层 | pubspec description 单语中文 | `pubspec.yaml:2` | ❌ **未修** — `description: "我今天吃了药 - 精神心理患者吃药打卡 + 停药通知"` 仍单语 |
| **CC-7** | 底层 | 4 处文档写"失联通知"功能可用 vs 业务暂停 | `full_description.txt:14` + `zh-CN/title.txt:1` + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | ❌ **未修** |
| **CC-9** | 底层 | `settings_page.dart:63, 92` 2 处 dark mode 漏 | `lib/presentation/pages/settings/settings_page.dart:63, 92` | ❌ **未修** — 仍 `Icon(color: AppColors.success)` / `AppColors.primary` 硬编 |
| **CC-10** | 底层 | `app_theme.dart:123, 209` 2 处 inline `withValues(alpha: 0.5/0.6)` | `lib/core/theme/app_theme.dart:123, 209` | ❌ **未修** — 集中器 `fgDisabled` / `fgHintInput` 早就在 app_colors.dart:219,225 存在 |
| **P0-9** | 底层 | `home_page.dart:622-650` `_showCelebrationOverlay` 35% 高度定位 | (R66/R68 持平) | ❌ **未修** |
| **P0-10** | 底层 | `medication_report_dialog.dart:166-194` scrim 缺 `AbsorbPointer` | (R66/R68 持平) | ❌ **未修** (搜出 0 `AbsorbPointer` 命中) |

### 1.3 R69 新增发现(2 项)

| # | 章节 | 问题 | 位置 | 严重度 |
|---|------|------|------|--------|
| **NEW-1** | C1 代码规范 | **`dart format` 改了 2 文件** — R68 commit d691551 改 `home_page.dart` + `setup_page.dart` 引入 C1.5 回归 | `lib/presentation/pages/home/home_page.dart` + `lib/presentation/pages/setup/setup_page.dart` | ⭐⭐⭐ 阻断 |
| **NEW-2** | E10 工程化 | **CI 漏 9 守护脚本** — R68 E10.3 加了 dart format 护栏,但其它 9 个守护(orphan_arb / legal_consent / sms_release / strings_hardcoded / zh_hant / utc / no_pua / widget_dispose / changelog)仍依赖本地跑 | `.github/workflows/ci.yml` | ⭐⭐ 警告 |

### 1.4 R68 持平项(15 项未变)

- 5 warning (`unused_import` 5 处 test 文件)
- 183 info-level (vs R68 181, +2 持平微增)
- 0 `RepaintBoundary` (P5.4 持平, 6 处待加)
- 2 `.then()` 残存 (P5.4 持平, `contacts_list_widget.dart:269` + `data_management_section.dart:416`)
- 0 `addTimingsCallback` / 启动埋点 (M9.3 持平)
- 0 `AbsorbPointer` (R66/R68 持平, scrim 锁死)
- 0 `test/integration_test/` (T8.4 持平)
- 0 `coverage/` (T8.3 持平)
- 0 `.github/PULL_REQUEST_TEMPLATE.md` (G11.3 持平)
- 0 `flutter build apk --analyze-size` CI step (P5.7 持平)
- 0 APM SDK 接入 (M9.1 持平, 零 APM 决策维持)
- 2 god class (mood_dialog 1204 行 + data_export_service 5490 行)
- 4 widget 集中器 (OutlinedButtonWithPress / LoadingScrim / TrailingSpinner / ConsentCard) 未抽
- 8+ atomic size token 散落 (SizedBox 12/16/36/40/110/115 魔法值)
- 5 半成品 (email_service v1.0+ TODO / sms_service v1.0+ TODO / home_page R55+ TODO / app_theme v0.25 TODO / badge_sync v0.10+ TODO)

---

## §2 14 章规范合规表

| 章节 | R66 | R68 | **R69** | Δ | 阻断 | 警告 | 建议 | 关键问题 |
|------|-----|-----|-----|---|------|------|------|----------|
| C1 代码规范 | 6/7 | 7/7 | **6/7** | -1 | 1(C1.5 回归) | 0 | 1(info 183) | **NEW-1 dart format 2 文件 changed** |
| N2 命名规范 | 6/6 | 6/6 | **6/6** | = | 0 | 0 | 0 | 全合规(0 `^class [a-z]` / 0 中文文件名) |
| D3 目录结构 | 3/3 | 3/3 | **3/3** | = | 0 | 0 | 0 | 4 层 + 5 子 umbrella 100% 纯 |
| H4 混合开发 | 5/5 | 5/5 | **5/5** | = | 0 | 0 | 0 | 0 `flutter_boost` / go_router 14.6 路由集中 |
| P5 性能规范 | 6/7 | 6/7 | **5/7** | -1 | 0 | 2(P5.4/P5.7) | 0 | 0 RepaintBoundary + 2 .then() + 0 analyze-size |
| S6 状态管理 | 2/2 | 2/2 | **2/2** | = | 0 | 0 | 0 | Riverpod 3.3.2 单一, R67 use case 抽离加分 |
| U7 UI 与设计 | 6/6 | 6/6 | **6/6** | = | 0 | 0 | 0 | 0 `Color(0xFF)` 散落(只在 app_colors.dart) / 6 集中器使用 90 命中 |
| T8 测试规范 | 3/5 | 2/5 | **3/5** | +1 | 0 | 2(T8.3/T8.4) | 0 | **1285 pass ✅ / 0 coverage / 0 integration** |
| M9 监控稳定性 | 2/4 | 2/4 | **2/4** | = | 0 | 2(M9.1/M9.3) | 0 | 0 APM + 0 启动埋点(零云端决策维持) |
| E10 工程化 CI/CD | 4/6 | 3/6 | **4/6** | +1 | 0 | 2(E10.6/E10.?) | 0 | **E10.3 修!(+1) / E10.6 NEW-2 仍漏 9 守护** |
| G11 Git 协作 | 3/4 | 2/4 | **3/4** | +1 | 0 | 1(G11.3) | 0 | **working tree 212→5 ✅ / 0 PR 模板** |
| DE12 依赖环境 | 5/6 | 5/6 | **5/6** | = | 0 | 1(DE12.4) | 0 | 0 `version: any` / 0 git: 依赖(CC-5 description 算 DE12.4) |
| DR13 数据资源 | 6/7 | 6/7 | **6/7** | = | 0 | 1(DR13.5) | 0 | 0 `SharedPreferences.*token` / 0 `http.get` in widget |
| LE14 日志与错误 | 5/5 | 5/5 | **5/5** | = | 0 | 0 | 0 | R67 EmailService 守门员 / `swallowError` 84 处 |
| APP 附录 | 2/3 | 2/3 | **2/3** | = | 0 | 1(无 PR 模板) | 0 | 0 PULL_REQUEST_TEMPLATE.md |
| **总** | **65/73 (89%)** | **64/73 (88%)** | **63/73 (86%)** | **-2%** | **1** | **11** | **1** | C1.5 回归 + E10.6 / T8.3-4 / M9.1,3 持平 |

**R66→R68→R69 合规率**: 89% → 88% → **86%** (R69 净 -2%,E10.3 / T8.2 / G11.4 修了 3 项 +C1.5 自己回归 1 项 + 待修项持平)

---

## §3 6 附录合规表

| 附录 | R68 状态 | **R69 状态** | 关键问题 |
|------|---------|-------|----------|
| A PR 模板 | ❌ 0 模板 | ❌ 0 模板 | 5 视角共识建议:加 5 条要点(命名/测试/资源/架构/可读性), 1h |
| B 状态管理选型 | ✅ README/AGENTS.md 记录 | ✅ 记录维持 | Riverpod 3.3.2 选型说明, R67 use case 抽离强化 |
| C 架构分层基线 | ✅ 4 层 + 5 子 umbrella | ✅ 100% 纯 | `check_all.dart` 通过, 0 跨层 import |
| D 安全 | ✅ SQLCipher / flutter_secure_storage / 0 SharedPreferences token | ✅ 同 | DR13.4 token 走 secure_storage 合规 |
| E 兼容性 | ⚠️ Flutter 3.41.9 / Dart 3.12.2 / iOS+Android | ✅ 维持 | SDK >=3.4.0, 16KB page size 未验证(googleplay P1) |
| F 发布 | ⚠️ R67 soft-launch 模式 + 守门员链完整 | ✅ 维持 | R67 B-1 EmailService 守门 + R68 CC-3 IAP 临时关, 4 守门员链完整 |

---

## §4 顶层架构审视(用户重点)

### 4.1 4 层架构 + 跨 feature 边界

| 检查项 | R68 | **R69** | 状态 |
|--------|-----|-------|------|
| `check_all.dart` 4 层纯度 | ✅ | ✅ | domain/shared 0 flutter/drift/data/presentation, data 不依赖 presentation |
| `check_cross_feature.py` 67 文件 0 违规 | ✅ | ✅ | 跨 feature import 边界 0 违规 |
| `check_drift_namespace.py` 7/7 唯一 | ✅ | ✅ | @DataClassName 0 重复 |
| `check_no_hardcoded_utc.py` 0 命中 | ✅ | ✅ | 0 硬编 UTC |
| `check_widget_dispose.py` 0 资源泄漏 | ✅ | ✅ | 5 类历史 bug 100% 合规 |
| `check_no_pua.py` 0 PUA 字符 | ✅ | ✅ | 全局 GBK 编码干净 |
| 0 `Color(0xFF` 散落(只在 app_colors.dart) | ✅ | ✅ | 全部 16+ 命中集中在 1 个 token 文件 |

**架构纯度 100%** — 跟 R68 完全持平,这是 v3.1 规范 §D3 / §S6 14 章的最强项。

### 4.2 守护脚本健康度(16 项全跑)

```
[OK] check_arb_keys              zh/en/zh_Hant 100% 同步 (623 keys)
[OK] check_changelog             pubspec=0.27.0+64 / CHANGELOG 顺序正确
[OK] check_cross_feature         67 files / 0 violations
[OK] check_datetime_race         0 multi-capture
[OK] check_datetime_race2        0 race (>=2 DateTime.now())
[OK] check_drift_namespace       7/7 unique @DataClassName
[WARN] check_fullwidth_punctuation  50 violations (warn-only, 已知决策)
[OK] check_no_hardcoded_utc      0 UTC 硬编
[OK] check_no_pua                0 PUA characters
[OK] check_widget_dispose        0 资源泄漏
[OK] check_orphan_arb_keys       623 keys / 0 orphan
[OK] check_legal_consent         no TODO (R68 CC-1 修后)
[OK] check_sms_release_ready     AliyunSmsProvider 真接 + isProductionReady
[OK] check_strings_hardcoded     32 static const + 32 i18n override
[OK] check_zh_hant_consistency   623 keys / 100% OpenCC s2tw 一致
[OK] check_all.dart              4 层架构 + 语义一致性 ✅

CI 实际运行: ci.yml inline 5 个 (drift_namespace / datetime_race2 / fullwidth / cross_feature / arb_keys)
CI 漏 9 个: orphan_arb / legal_consent / sms_release / strings_hardcoded / zh_hant / utc / no_pua / widget_dispose / changelog
```

**E10.6 NEW-2**: 16 个守护脚本全绿(本地),但 CI 只跑 5 个,9 个仍依赖本地执行 — 风险点:本地跑 ≠ CI 跑,可能引入回归。

### 4.3 god class / 半成品清单(用户重点)

#### 4.3.1 god class (2 个, R66 持平 18 月)

| 模块 | 行数 | 类别 | R66 评级 | R69 评级 | 建议拆法 |
|------|------|------|---------|---------|---------|
| `lib/presentation/pages/mood/mood_dialog.dart` | **1204** | 业务编排 + UI | god class | **持平** | 抽 `MoodDialogOrchestrator` 状态机(7 字段 → enum) + 业务委派 `mood_usecases.dart`, 走 R64 home_page 3 bool → enum 模式 |
| `lib/core/data/services/data_export_service.dart` | **5490** (~21K) | orchestrator | god class | **持平** | 抽 `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) |

#### 4.3.2 R68 spec 推荐继续抽(4 widget 集中器, 仍未动)

| 重复模式 | 出现位置 | 建议集中器 | 难度 | R69 状态 |
|---------|---------|-----------|------|---------|
| 3 段重复 ConsentCheckRow | `setup_step_consent.dart:75-94` | `ConsentCard(title, checked, onTap, onView)` | S | ❌ 未抽 |
| OutlinedButton.icon + PressFeedback(3 模式不一致) | `medication_report_dialog.dart:110-156` | `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` | S | ❌ 未抽 |
| scrim + 中心 Card(spinner + 文字)(PDF loading) | `medication_report_dialog.dart:166-194` | `LoadingScrim(message, isLoading)` | S | ❌ 未抽 |
| InlineSpinnerInTrailing(3 模式不一致) | `medication_row.dart:131` / `contacts_list_widget.dart:75-83` / `notification_status_card.dart:219-224` | `TrailingSpinner` | XS | ❌ 未抽 |

#### 4.3.3 atomic size token 散落(8+ 处, R66 持平)

| 散落处 | magic | 建议 token | R69 状态 |
|--------|-------|-----------|---------|
| `main.dart:271, 277, 356, 422` | `SizedBox(height: 12)` × 4 | `AppTokens.spacingXs` (12) | ❌ 散落 |
| `medication_row.dart:131-132` | `SizedBox(width: 18, height: 18)` | `AppTokens.iconSizeTrailing` (18) | ❌ 散落 |
| `medication_report_dialog.dart:180-183` | `SizedBox(width: 20, height: 20)` | `AppTokens.spinnerSizePdf` (20) | ❌ 散落 |
| `setup_step_medication.dart:103-104` | `SizedBox(width: 110, height: 44)` | `AppTokens.buttonWidthNarrow` (110) | ❌ 散落 |
| `medication_calendar_page.dart:414-415` | `width: 12, height: 12` | `AppTokens.legendDotSizeLg` (12) | ❌ 散落 |
| `refill_manage_page.dart:326-327` | `width: 36, height: 36` | `AppTokens.avatarSizeSm` (36) | ❌ 散落 |
| `setup/widgets/reminder_cards.dart:162-163` | `width: 40, height: 40` | `AppTokens.avatarSizeMd` (40) | ❌ 散落 |

#### 4.3.4 半成品(5 处, R66 持平 12-18 月)

| 位置 | 半成品 | 外部依赖 | 修复路径 |
|------|--------|---------|---------|
| `email_service.dart:19, 40, 94, 162` | R55+ 真接 SendGrid / "v1.0+ TODO 真实邮件 发送未实现" | 法务模板审核 + SendGrid AccessKey | R67 B-1 加守门员(`validateForRelease`),真接待 v0.28 |
| `sms_service.dart:90, 104, 195` | R55+ 真接阿里云 / "真实 send() 仍 throw UnimplementedError" | 法务模板审核 + 阿里云 AccessKey | 守门员到位, 真接待 v0.28 |
| `home_page.dart:557, 567` | R55+ TODO 拿 input.contacts.first.phone / placeholder@invalid.local | 跟 SMS / Email 真接同 | 守门员到位, 真接待 v0.28 |
| `app_theme.dart:128` | "TODO v0.25: 评估 buildTheme 接受 context" (挂 1 年) | — | 1h 评估 + 加可选 `BuildContext?` 参数 |
| `badge_sync_service.dart:45` | "TODO v0.10+ 集成 flutter_app_badge_control" (挂 18+ 月) | Android 第三方 plugin 评估 | 评估后决策(集成 / 永久移除) |

---

## §5 底层逐行排查(用户重点)

### 5.1 5 类历史 bug(R66/R67/R68 100% 合规,R69 持平)

| bug 类 | 守护脚本 | R66 命中 | R68 命中 | **R69 命中** | 持平 |
|-------|---------|---------|---------|----------|------|
| 隐式排序 | `grep '\.first\.timestamp\|\\.last\.timestamp'` | 0 | 0 | **0** | ✅ |
| DateTime race | `check_datetime_race.py` | 0 | 0 | **0** | ✅ |
| 静默 `catch(_)` | `swallowError` 集中器 | 49/12 | 84/26 | **84/26(估)** | ✅ |
| StreamSubscription cancel | `check_widget_dispose.py` | 0 | 0 | **0** | ✅ |
| BuildContext 跨 async gap | grep `use_build_context_synchronously` | 0 | 0 | **0** | ✅ |
| Resource acquire-release | grep `try {.*setSource.*dispose` | 0 | 0 | **0** | ✅ |

### 5.2 命名 / 注释 / 错误处理 / 性能 / 安全 / 测试 / 资源管理

| 维度 | 检查 | R69 结果 | 状态 |
|------|------|---------|------|
| **命名** | `^class [a-z]` | 0 命中 | ✅ 全合规 |
| | 中文文件名 | 0 | ✅ |
| | `const [A-Z_]+` 公开常量 | 0(改用 lowerCamelCase) | ✅ |
| **注释** | TODO/FIXME/XXX 总数 | 21 / 11 文件(都是 v1.0+ future) | ⚠️ 多但合理 |
| | `/// v0.27 round N:` 注释 | 38 命中 / 32 文件 | ✅ 历史可追溯 |
| **错误处理** | 0 `print(` 业务代码 | ✅ | ✅ |
| | `swallowError` 集中器使用 | 84 处(估) | ✅ |
| | `runZonedGuarded` 全局兜底 | main.dart:83 | ✅ |
| | `FlutterError.onError` | main.dart:74 | ✅ |
| **性能** | 0 `RepaintBoundary` | 0 | ❌ P5.4 |
| | 2 `.then()` 残存 | 2 | ❌ P5.4(R66 持平) |
| | 0 `cacheWidth` 检查 | 缺 | ❌ P5.5 |
| | 0 `flutter build apk --analyze-size` CI | 缺 | ❌ P5.7 |
| **安全** | 0 `SharedPreferences.*token` | 0 | ✅ DR13.4 |
| | flutter_secure_storage 使用 | DB key / SMS key / Email key / IAP key 14 处 | ✅ |
| | SQLCipher 加密 | ✅ | ✅ |
| | .env 内容 `PLACEHOLDER=test` | 38 bytes | ✅ |
| **测试** | 1285 pass + 0 fail | ✅ T8.2 | ✅ R68 修了 2 fail |
| | 0 coverage/ | 缺 | ❌ T8.3 |
| | 0 integration_test/ | 缺 | ❌ T8.4 |
| | Mock 规范(mocktail) | 用 | ✅ |
| **资源管理** | 0 资源泄漏 | ✅ check_widget_dispose | ✅ |
| | 0 mounted 漏 | grep 0 | ✅ |
| | 0 `cacheWidth` 缺 | 缺 | ❌ P5.5 |

### 5.3 跨视角共识 X-P0/X-P1(2 视角以上,spec 章节映射)

| ID | 视角 | 共识 | spec 章节 | R69 状态 |
|----|------|------|---------|---------|
| X-P0-1 | spzh + appstore + googleplay | 3 法律 md TODO banner 仍保留 | G11.3 + DE12.4 | ❌ **未修** |
| X-P0-2 | emil + spzh + appstore | 隐私政策撒谎 (CC-6) | S6.1 + LE14.4 | ✅ **R68 commit 修** |
| X-P0-3 | spzh + appstore | AliyunSmsProvider throw StateError | LE14.5 + DR13.7 | ❌ 未修(守门员到位但契约未变) |
| X-P0-4 | 4 视角共识 | 212 文件 working tree 未 commit | G11.2 + G11.4 | ✅ **R68 commit 修了** |
| X-P1-1 | spzh + emil | ConsentKind.safety 撤回未拦截 | S6.1 + LE14.4 | ✅ **R68 commit 修了** |
| X-P1-2 | emil + appstore | CFBundleDisplayName per-locale | DE12.3 + D3.3 | ❌ 未修 |
| X-P1-3 | emil + appstore | 15+ hardcoded 字符串 | U7.5 | ❌ 未修 |
| X-P1-4 | googleplay + appstore | 33 张截图占位 | DR13.5 | ❌ 未修 |
| X-P2-1 | emil | setup 阶段 saveSetup 绕过 ConsentDialog | DR13.2 | ✅ **R68 commit 修了** |
| X-P2-2 | emil | 6 个 widget 集中器 | U7.1 | ✅ 90 命中 / 27 文件 |

---

## §6 上架相关(spec 视角)

### 6.1 C8 安全(已合规, R67 守门员 + R68 强化)

| 项 | R68 | **R69** | 状态 |
|----|-----|-------|------|
| SQLCipher 本地加密 | ✅ | ✅ | `sqlcipher_flutter_libs: ^0.6.4` |
| flutter_secure_storage 14 处 | ✅ | ✅ | DB key / SMS / Email / IAP key 全在 secure storage |
| 0 SharedPreferences token | ✅ | ✅ | DR13.4 合规 |
| 隐私政策 (CC-6 撒谎) | ❌ | ✅ R68 修了 | §4/§9/§12 表格跟 use case 行为对齐 |
| ConsentDialog (CC-1 绕过) | ❌ | ✅ R68 修了 | setup 阶段每个填了的联系人必走 ConsentDialog |
| PIPL §13 单独同意 | ❌ | ✅ R68 修了 | setup 必弹 + 拒绝终止 |
| PIPL §14 撤回同意 | ❌ | ✅ R67+R68 修了 | ConsentGate 集中器双向同步 + use case 入口拦截 |
| 3 法律 md TODO banner(CC-4) | ❌ | ❌ | 法律性, 需律师过审(L 级, 1-2 周) |
| pubspec description 单语(CC-5) | ❌ | ❌ | 加 en / zh_Hant 描述(M 级, 半天) |
| 4 文档失联通知 wording(CC-7) | ❌ | ❌ | 改 4 处文档措辞(XS, 1-2h) |

### 6.2 F 发布 + 上架流程

| 项 | R68 | **R69** | spec 章节 |
|----|-----|-------|---------|
| 守门员链(SMS / Email / IAP / DB) | ✅ R67 加 Email | ✅ 维持 | LE14.5 |
| release keystore debug(googleplay) | ❌ | ❌ | F 发布(外部) |
| iOS 33 截图 + 3 app_icon 占位 | ❌ | ❌ | DR13.5(外部) |
| Android 8 截图 + 2 feature_graphic + 2 icon | ❌ | ❌ | DR13.5(外部) |
| 4 视角共识 5 流程性 P0(commit / test 漂移 / CI 护栏 / 上架元数据) | ❌ | partial(working tree 修了) | G11 / E10 / F |

---

## §7 修复优先级总表

### ⭐⭐⭐ 阻断(1 项)

| # | 类别 | 位置 | 难度 | 章节 | 关键修复 |
|---|------|------|------|------|----------|
| 1 | 底层 | `home_page.dart` + `setup_page.dart` dart format 2 changed | XS | **C1.5** | `dart format lib/presentation/pages/home/home_page.dart lib/presentation/pages/setup/setup_page.dart` 立即修, 同时 CI 护栏检查 commit 流程 |

### ⭐⭐ 警告(11 项,按难度排)

| # | 类别 | 位置 | 难度 | 章节 | 关键修复 |
|---|------|------|------|------|----------|
| 2 | 流程 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md:3-4` TODO banner | **L** | G11.3 / DE12.4 / CC-4 | 律师过审 1-2 周(¥15-30k/文档) |
| 3 | 流程 | `pubspec.yaml:2` description 单语 | M | DE12.4 / CC-5 | 加 en / zh_Hant 描述, 半天 |
| 4 | 流程 | 4 文档失联通知 wording | XS | DE12.4 / CC-7 | 改 4 处文档措辞, 1-2h |
| 5 | 底层 | `settings_page.dart:63, 92` dark mode 2 处 | XS | U7 / CC-9 | 改 `AppColors.fgOnSuccess(context)` + `AppColors.primaryColor(context)`, 5min |
| 6 | 底层 | `app_theme.dart:123, 209` inline alpha 2 处 | XS | U7 / CC-10 | 改 `AppColors.fgDisabled(context)` + `fgHintInput(context)`, 5min |
| 7 | 底层 | `home_page.dart:622-650` celebration 35% 高度 | XS | U7 P0-9 | 改 `MediaQuery.padding.top + spacingLg`, 5min |
| 8 | 底层 | `medication_report_dialog.dart:166-194` scrim 缺 `AbsorbPointer` | XS | P5.4 P0-10 | 加 `AbsorbPointer`, 5min |
| 9 | 工程化 | CI 漏 9 守护脚本 (E10.6 NEW-2) | M | E10.6 | ci.yml 加 `make lint` 聚合或 9 个 step, 半天 |
| 10 | 底层 | 5 warning `unused_import` 走 `dart fix --apply` | XS | C1.6 | 1 行命令, 0 风险 |
| 11 | 性能 | 6 处加 `RepaintBoundary`(trend 4 段 + celebration + recorder) | XS | P5.4 | 1h 零侵入 |
| 12 | 性能 | 修 2 处 `.then()` 残存(`contacts_list_widget.dart:269` + `data_management_section.dart:416`) | XS | P5.4 | 改 `await + if (!mounted)` 模式, 30min |

### ℹ️ 建议(13 项,按主题排)

| 类别 | 项 | 难度 |
|------|---|------|
| 集中器 | 抽 4 widget 集中器(OutlinedButtonWithPress / LoadingScrim / TrailingSpinner / ConsentCard) | S / S / XS / S |
| god class | mood_dialog 1204 → MoodDialogOrchestrator + mood_usecases | M-L |
| god class | data_export_service 5490 → ExportPlanBuilder + ExportPreview | M |
| atomic token | 8+ 处 SizedBox 散落 → 抽 AppTokens 集中器 | XS |
| 半成品 | app_theme.dart:128 "TODO v0.25" 1h 评估 | XS |
| 半成品 | badge_sync_service.dart:45 "TODO v0.10+" 评估 | XS |
| 启动 | M9.3 `addTimingsCallback` 启动埋点 | S |
| 监控 | M9.1 零 APM 决策文档化 5-10 行 | XS |
| 测试 | T8.3 `flutter test --coverage` + lcov 60% | M |
| 测试 | T8.4 加 `test/integration_test/home_checkin_flow_test.dart` | M |
| 流程 | G11.3 加 `.github/PULL_REQUEST_TEMPLATE.md` 5 条要点 | XS |
| 性能 | P5.7 CI 加 `flutter build apk --analyze-size` 验 <50MB | XS |
| 上架 | CC-8 3 份 markdown 0 英文/繁体版(`setup_legal_dialog` 分 locale) | L |

**修复总工作量**: 1 阻断 + 11 警告 + 13 建议 = **2-3 周**(M 难度占主)

---

## §8 3-5 句精炼建议

1. **C1.5 回归必修** — R68 commit d691551 自己改了 `home_page.dart` + `setup_page.dart` 2 文件但**没跑** `dart format`,**比 R66 baseline 倒退 1 步**。5 分钟 `dart format` 两个文件 + 同 PR 加 `dart format` pre-commit hook(`.git/hooks/pre-commit`), 防止下次 commit 又复发。这是 1 个 P0 阻断 + 0 风险。

2. **R68 commit 实质改善 v1.0 上 store 工程质量** — CC-3(IAP 临时关)+ CC-6(CareEngine safety consent 真接)+ CC-1(setup ConsentDialog 真接)+ 2 test fail 修复 = **5 项 P0 集中清零**(commit 信息 "baseline: 1285 pass / 0 fail")。16 守护脚本全绿 + 6 widget 集中器 90 命中 / 27 文件 + 0 Color(0xFF) 散落 — 14 章规范 86% 合规率持平 R66 高水准(R67 持平是 R66 / R68 微降到 86% 是 C1.5 回归拖累), v1.0 工程质量**已达标**。

3. **剩下的 P0 都是"非代码"环节** — 7 项 R68 spec 报告 P0-P1 全是上架元数据(CC-4 律师过审 / CC-5 pubspec 多语 / CC-7 文档措辞 / CC-9-10 dark mode + alpha)+ 半成品(email / sms / badge_sync 3 处"v0.10+ / v0.28" 占位)。**3 周工作量 = 1 周代码(2 god class + 4 widget 集中器 + 8 atomic token + 5 warning + dart format 护栏 + 9 守护 CI)+ 2 周外部(律师 + 截图 + 域名 + 邮箱)**, 跟主 P0 修复分头推进。

4. **架构 / 守护脚本 100% 纯** — 4 层 + 5 子 umbrella / check_all.dart / check_cross_feature / check_drift_namespace 全绿;5 类历史 bug(隐式排序 / DateTime race / 静默 catch / StreamSubscription / BuildContext 跨 async / Resource acquire-release)100% 合规 — 这是 v3.1 规范 §D3 / §S6 / §LE14 / §P5 的最强项,R69 持平 R68,R66/R67/R68 3 轮未退。

5. **总体评级**: ⭐⭐⭐⭐ **4.5/5** (持平 R66 / R68)。R68 commit d691551 是 v0.27 集中修复(CC-3/6/1 + 2 test fail + working tree 清零),**让 5 视角共识 10 项 P0 中 4 项(CC-1/2/3/6)被代码层解决**, 但流程细节(C1.5 回归 + E10.6 漏 9 守护)+ 上架元数据(CC-4/5/7)+ 2 god class + 4 widget 集中器 + 8 atomic token 仍是 v1.0 路上**最后 14% 缺口**。建议 R70 立即 commit C1.5 修复 + 同 PR 修 5 warning + 2 .then() + 6 RepaintBoundary, 半天工作量拿回 88%。

---

## §9 R68 spec 报告 vs R69 spec 报告对照

| 维度 | R68 spec | **R69 spec** | 变化 |
|------|---------|-----------|------|
| 总评级 | ⭐⭐⭐⭐ 4.5/5 | ⭐⭐⭐⭐ 4.5/5 | 持平 |
| 合规率 | 88% (64/73) | 86% (63/73) | **-2%** (C1.5 回归) |
| 阻断 | 5 | **1** | **-4** (R68 commit 修了 CC-1/3/6 + 2 test fail) |
| 警告 | 5 | **11** | +6 (E10.6 NEW-2 + 6 处 P5.4/U7) |
| 建议 | 5 | **13** | +8 (R69 重构机会显化) |
| 跨视角 X-P0 共识 | 4 项 (CC-1/3/4/6) | **3 项 (CC-4/5/7)** | CC-1/3/6 修 |
| R67 守门员链 | 4 项 (SMS/Email/IAP/DB) | 4 项 | 持平 |
| CI 护栏 | 0 → E10.3 修 (R66) | **E10.6 漏 9 守护** | 部分修 |
| 6 widget 集中器 | 0 (R66) → 6 抽(R67) | 90 命中 / 27 文件 | 持平(R67 集中器) |
| 4 widget 集中器 (R68 spec 推荐) | 0 | **0 仍未抽** | 持平 |
| 2 god class (R66 持平 18 月) | 2 | **2** | 持平 |

---

**报告完毕。** R69 是 R68 commit 后的**增量审计**,基线从 R68 spec 的 88% → R69 实际 86%(C1.5 回归 -2%),**P0 实质改善**。**真正卡 v1.0 上 store 的不是 14 章规范合规率**(86% 已是高水准),而是上架元数据(律师过审 1-2 周 + 33 张截图 + 真实 keystore + 真实 support@ 邮箱)**这些 L 级 1-2 周不可压缩**。建议 R70 commit C1.5 修复 + 同 PR 修 5 warning + 2 .then() + 6 RepaintBoundary, 半天拿回 88% 合规率。
