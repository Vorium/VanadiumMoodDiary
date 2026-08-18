# 视角 6 报告 · GooglePlay (Android)

## 元信息

- 跑时间: 2026-08-11
- baseline: master HEAD `01d8f4a` v0.31.0
- 关注: Android 上架 / Data Safety / 16KB / PrivacyInfo / keystore / Health Apps Questionnaire / 实物资产
- R108 baseline: 5.5/10 = 55% (`docs/audit/2026-08-10-r108-revisit/lens/05-googleplay.md`, 26 P0 + 多 P1/P2)

## 核心结论 (1 段)

**Apple Health 23 commit 对 Android 上架 = 0 影响, 评分持平 5.5/10**。
23 commit 改动 100% 在 `lib/presentation/` (UI) + `lib/core/theme/` (token) + 测试, 0 个 `android/` / `ios/` / `pubspec.yaml` 依赖 / `lib/core/data/` / `lib/domain/` 改动。
CHANGELOG v0.31.0 显式声明 "业务逻辑 0 改动"。flutter analyze 0 error / 90 issues (跟 spec baseline 一致, 无新增)。
R108 报告 26 P0 在 Apple Health 23 commit 范围内命中 = **0/26** (R108 26 P0 全是 native / 实物资产 / 业务层, Apple Health 23 commit 在 UI 主题层)。

## 5 维度评估

### 1. 外部链接检查

- [OK] `pubspec.yaml:6` `0.30.0+85` → `0.31.0+107` 仅 version 字段, 0 依赖新增
- [OK] `android/app/src/main/AndroidManifest.xml` 全文 0 URL (仅 `PROCESS_TEXT` queries)
- [OK] 5 个新增 Apple Health widget (`apple_health_tile.dart` / `apple_list_section.dart` / `check_in_button.dart` / `primary_button.dart` / `section_header.dart`) **0 Cupertino import** (grep 验证), 全部走 Material 3, cross-platform OK
- [OK] `lib/core/theme/app_theme.dart:18` `ColorScheme.fromSeed(brightness: brightness)` M3 派生 light/dark, 跨平台 OK
- [ISSUE**R108 沿袭**] `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` + `support_url.txt` (4 文件) 仍 `https://chroniccare.app/...` 占位 (R108 P0-005)
- [ISSUE**R108 沿袭**] `assets/legal/privacy_policy.md:9,150` `privacy@chroniccare.app` 邮箱占位 (R108 P0-005)
- [ISSUE**R108 沿袭**] `scripts/generate_data_safety_form.py:85,114` + `register_domain.sh:30-33` 4 邮箱 `chroniccare.app` 占位 (R108 P0-005)
- [INFO] `full_description.txt:46` `https://findahelpline.com` (helpline 官方, 真实可达) — OK

### 2. 上架 / 架构 / 重构 / 半成品 (R108 §六 26 P0 对照)

| 类别 | 数量 | 跟 Apple Health 23 commit 关系 |
|---|---|---|
| R108 26 P0 在 diff 范围内命中 | **0/26** | 全在 native / 实物资产 / 业务层, Apple Health 23 commit 100% UI 主题层 |
| Apple Health 23 commit 引入新 P0 | **0** | analyze 0 error, 0 native 改动 |
| R108 26 P0 中"被 Apple Health 23 commit 顺带修" | **0** | `notification_service.dart` (P0-006 锁屏) 不在 diff |
| R108 26 P0 仍阻塞上架 | **12 P0 仍存在** | 8 张截图 67B / feature_graphic 67B / icon Flutter logo / 缺平板截图 / 域名 + 4 邮箱 / 锁屏 visibility / manifest label 硬编 / short_description 87 字 / 5 病种名 / keystore / 5 厂商 push |

**关键 0 影响证据**:
- `git diff 1b851a8..01d8f4a -- android/ ios/ pubspec.yaml` → 仅 1 行 version bump, 0 依赖, 0 配置
- 23 commit 文件清单: `lib/core/theme/*.dart` (6) + `lib/presentation/{pages,widgets}/*.dart` (40) + test (15) + CHANGELOG, **0 android/** 改动
- 5 个新增/改写 Apple Health widget 0 Cupertino import (grep 验证) → Android Material 3 渲染正常

**仍阻塞上架的 12 P0 (R108 沿袭, Apple Health 23 commit 未触及)**:
1. **P0-001** 8 张 phone screenshots 67B 占位 (8 个文件实测确认)
2. **P0-002** feature_graphic.png 67B × 2 locale
3. **P0-003** icon.png 1443B Flutter 默认 logo
4. **P0-004** 缺 7"/10" 平板截图目录
5. **P0-005** chroniccare.app 域名 + 4 邮箱未注册 (7-20d ICP)
6. **P0-006** `AndroidNotificationDetails.visibility` 4 处未设 `NotificationVisibility.secret`
7. **P0-007** `AndroidManifest.xml:51` `android:label="ChronicCare"` 硬编, 未走 `@string/app_name`
8. **P0-008** en-US short_description.txt 87 字符 > 80 上限
9. **P0-009** en-US full_description 含 bipolar/PTSD/ADHD 5.1.3 抽审触发词
10. **P0-010** 实际 keystore 未生成 (`android/key.properties` 不存在)
11. **P0-011** 5 厂商 push SDK 完全未集成
12. (其他 P1-001/002/004/005/009/010 详见 R108 报告)

### 3. 顶层架构审视

**整体评价**: Android native 配置已成熟 (R61-R97 多轮加固), R108 13 P0 工具层 (脚本 + 文档 + lock-in test) 全部就位, 实物资产 100% 缺失是"半上架"状态。Apple Health 23 commit 100% UI 主题层 = 0 影响 native。

**跨平台兼容性** (Apple Health 23 commit 关键验证):
- **Android Material 3 dark mode**: ✅ `app_theme.dart:18` `ColorScheme.fromSeed(brightness: Brightness.dark)` 仍 M3 派生, `values-night/styles.xml` 用 `Theme.Black.NoTitleBar` (R97 改)
- **iOS 风格色 vs Android 派生色**: ⚠️ v0.31.0 R1 brand color = iOS systemGreen `0xFF34C759`, Android M3 ColorScheme.fromSeed 用 seed 派生 → Material 3 原生 widget (Switch/TimePicker/Slider) 颜色跟自定义 Apple Pill 按钮 / AppleListSection 颜色**轻微不一致** (P3 观察, 非 P0, Apple Health 本意就是 iOS 风格)
- **iOS 字体 vs Android 字体**: ✅ `app_typography.dart` 17pt body / 13pt caption / w200 ultralight, theme.fontFamily 默认 Roboto (Android) / SF Pro Text (iOS), 跨平台 font fallback OK
- **iOS spacing vs Android density**: ✅ spacing 50/16/14 是 Flutter widget 内部逻辑, 不影响 Android 原生 widget
- **iOS radius vs Android corner**: ✅ Flutter Container 圆角, 跨平台一致

**Android 13 预测式返回** (R63 已开): ✅ `AndroidManifest.xml:58` `enableOnBackInvokedCallback="true"`
**Android 12+ SplashScreen**: ⚠️ `values/styles.xml:4` 用 `@android:style/Theme.Light.NoTitleBar` (旧 Theme), 没用 Android 12+ `Theme.SplashScreen` 新 API → **P3 观察** (Google Play 2022-12 强制 Android 12+ 适配, 当前用 Flutter 旧 Theme 仍可, 但建议未来用 SplashScreen API)
**Android 16KB page size** (R77 + R92 已做): ✅ ndkVersion=Flutter 3.41.9 默认 27.0.12077973 (16KB 对齐), `check_16kb_alignment.py` 验基础配置, R92 文档补"完整 16KB 验需 `unzip .aab` + `objdump segment >= 16384`" → CI 阶段真验

**AGP / Kotlin / Gradle**: ✅ AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.13 显式声明, 不变

**8 FeatureFlag** (不变): 1 true (ventAudioEnabled) + 7 false (iapEnabled / emergencyContactEnabled / fiveVendorPushEnabled / emailServiceEnabled / phqGad7I18nEnabled / bootReceiverEnabled / aliyunSmsEnabled)

### 4. 底层逐行排查

**AndroidManifest.xml 完整权限 / 配置清单** (R108 P0-007 仍 P0, 其他 R108 P0 沿袭):

| 类型 | 声明 | 状态 |
|---|---|---|
| 权限 | INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE / RECORD_AUDIO | ✅ 6 项 R61/R97/R105 已审 |
| 权限 | **FOREGROUND_SERVICE** | ❌ P1-001 缺 (5 厂商 push 真接需) |
| application | `android:label="ChronicCare"` | ❌ P0-007 硬编 |
| application | `allowBackup="false"` | ✅ PIPL §28 |
| application | `dataExtractionRules` / `fullBackupContent` / `networkSecurityConfig` / `enableOnBackInvokedCallback` | ✅ R61/R63 完整 |
| application | **`usesCleartextTraffic="false"`** | ❌ P1-002 缺显式 (隐式 OK) |
| application | **`<supports-screens android:largeScreens="true">`** | ❌ P0-004 缺 (平板适配声明) |
| queries | PROCESS_TEXT 1 个 | ❌ P1-005 缺 5 厂商 push 预留 |
| 死代码 | `BootReceiver.kt` 文件在 + ProGuard keep, manifest 不注册 | ❌ R97 注释说"v1.0 WorkManager 替代", 等 R109 删 |

**已遍历文件** (本次):
- `android/app/src/main/AndroidManifest.xml` (101 行)
- `android/app/build.gradle.kts` (132 行, R67 keystore + R70 ABI + R97 release signing + R70 multidex)
- `android/app/src/main/res/{values,values-night}/styles.xml` (2 × 18 行)
- `android/app/src/main/res/xml/{network_security_config,data_extraction_rules,backup_rules}.xml` (3 文件, 完整 PIPL §28 排除)
- `android/settings.gradle.kts` (AGP 8.11.1 / Kotlin 2.2.20 显式)
- `android/gradle/wrapper/gradle-wrapper.properties` (Gradle 8.13)
- `lib/core/theme/app_theme.dart` (ColorScheme.fromSeed 验证) + `app_colors.dart` (iOS systemGreen) + `app_typography.dart` + `app_spacing.dart` + `app_motion.dart` + `app_tokens.dart` + `spring.dart`
- 5 新增/改写 widget (`apple_health_tile.dart` / `apple_list_section.dart` / `check_in_button.dart` / `primary_button.dart` / `section_header.dart`)

**找到 bug** (按 R108 baseline 对账, 全部 R108 沿袭, Apple Health 23 commit 未引入新 bug):
- **0 个 P0** 由 Apple Health 23 commit 引入
- **0 个 P1** 由 Apple Health 23 commit 引入
- **0 个新 P0/P1/P2** 由 Apple Health 23 commit 引入
- **12 个 R108 P0 仍阻塞上架** (跟 Apple Health 23 commit 0 关系)

**P3 观察 (新增, 跨视角共识)**:
- [底层] **[P3-NEW-01] `app_colors.dart:42` brand color = iOS systemGreen `0xFF34C759`, Android M3 ColorScheme.fromSeed 派生绿 ≈ 0xFF4CAF50, Material 3 原生 widget (Switch / TimePicker / Slider) 颜色跟自定义 Apple 风格 widget 颜色轻微不一致** — 修复难度: S, 工作量: 0.5h, 优先级: P3 (Apple Health 本意就是 iOS 风格, Android 上颜色轻微不同是设计选择不是 bug)
- [架构] **[P3-NEW-02] `values/styles.xml:4` 用 `@android:style/Theme.Light.NoTitleBar` (旧 Theme API), Google Play 2022-12 起对 Android 12+ App 推荐用 `Theme.SplashScreen` 新 API 适配 12+ splash screen** — 修复难度: M, 工作量: 1d, 优先级: P3 (Flutter 旧 Theme 仍可上架, 但建议未来升级)

### 5. dev doc 更新

- **AGENTS.md**: ❌ 未改 (R108 GooglePlay 55% 段已存在, v0.31.0 Apple Health 23 commit 对 Android 0 影响, 不需更新 GooglePlay 评分段落)
- **CHANGELOG.md**: ✅ v0.31.0 [0.31.0] 段落已加 (R108 → v0.31.0 跨 22 commit), 明确说 "业务逻辑 0 改动", 跨 Android 端 0 native 改动
- **`docs/PLAYSTORE_SIGNING_GUIDE.md`**: ❌ R67 已存在, 0 改
- **`docs/policies/data-safety-collection.md`**: ❌ R108 P2-004 缺, Apple Health 23 commit 不需新增
- **锁屏 PII 文档**: ❌ R108 P0-006 仍 P0, 0 改

## 总结

**R108 GooglePlay 5.5/10 (55%) 在 v0.31.0 Apple Health 23 commit 后评分 = 5.5/10 持平**。23 commit 100% 在 UI 主题层 (`lib/presentation/` + `lib/core/theme/`), 0 个 `android/` / `ios/` / `pubspec.yaml` 依赖 / `lib/core/data/` / `lib/domain/` 改动。**0 新 P0 引入, 0 R108 P0 修复**。

R108 26 P0 中 12 P0 仍阻塞 Google Play 上架 (8 截图 + feature_graphic + icon + 平板截图 + 域名邮箱 + 锁屏 visibility + manifest label + short_description + 5 病种名 + keystore + 5 厂商 push), 全部是 1-2 月外部依赖 (法务 / 域名 ICP / 5 厂商审核 / 设计师出图) 或 5-30min 简单修复 (P0-007 改 manifest 5min / P0-008 改 short_description 10min / P0-006 加 visibility 0.5h), 不在 UI 主题层。

**给整合者的 2 条建议**:
1. **GooglePlay 评分持平 5.5/10, Apple Health 23 commit 不修任何 R108 P0**。R108 整合者 §六 26 P0 一条不需要重写 (Apple Health 23 commit 不影响)。
2. **P3-NEW-01/02 是新增观察, 非阻塞**, 可写进 P3 长期路线, 不必本期修。

**对项目 1-2 段总评**: Android native 配置 0 退步, 仍 R61-R97 多轮加固状态; 5 个新增/改写 Apple Health widget 全部 Material 3 跨平台兼容; 唯一关注点是 brand color 改 iOS systemGreen 后 Android M3 派生色跟自定义 widget 颜色轻微不一致 (P3, 设计选择)。
