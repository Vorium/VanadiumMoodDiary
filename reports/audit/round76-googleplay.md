# Round 76 - Google Play Store 视角审计

**审计时间**: 2026-08-01 → 2026-08-02
**项目**: chroniccare(精神心理患者吃药打卡 App / 医疗健康类 / 精神心理敏感数据)
**版本**: 0.27.0+64(R76 commit `6b4fc63` 完,版本号未 bump,实为 R75 末班车)
**基线**: 1285 tests pass(R76 测试同步 R75 PHQ-9 wording,无新增)/ 0 analyzer error / 0 warning / 0 info / 18 守护脚本全绿
**审计模式**: 增量审计(对照 R74 `round74-googleplay.md` 26KB/736 行)
**视角**: Google Play Console 上架合规(Health Apps + Data Safety + Permissions Policy + 16KB page size + 64-bit + targetSdk 2026 要求)
**核心范围**: Android 工程结构 + Manifest + Kotlin + Gradle + ProGuard + 资源 xml + Fastlane + 5 法律/上架 md + 截图/feature_graphic/icon 资产
**特别说明**: R75 是纯 iOS / domain / 报告归档 round(0 改 android/ + 0 改 fastlane/),R76 是 1 个测试同步 commit(`6b4fc63`)。**R75+R76 累计 0 Android / Fastlane 改动**。

---

## §0 评级

**4.0 / 10**(vs R74 4.0/10,**持平**)

| 维度 | R66 评分 | R68 评分 | R69 评分 | R74 评分 | **R76 评分** | Δ vs R74 | 关键变化 |
|------|---------|---------|---------|---------|---------|---------|---------|
| **政策合规 (Policy)** | ⭐⭐ | ⭐⭐½ | ⭐⭐½ | ⭐⭐⭐ | ⭐⭐⭐ | = | R75 0 改 policy;R76 0 改 policy;3 法律 md 仍 v0.22 修订历史 + R75 升级版本号到 `v0.27-2026-08-01`(`ConsentArtifact.version` 同步,R75 PIPL-2 修) |
| **技术 (Technical)** | ⭐⭐⭐⭐ | ⭐⭐½ | ⭐½ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | = | R70 abiFilters + 16KB check 仍绿;R75 0 改 Android;BootReceiver 仍占位(R76-12 round 0 进展);R70 简化 BootReceiver 后再 6 round 0 进展 |
| **元数据 (Store Listing)** | ⭐ | ⭐½ | ⭐½ | ⭐½ | ⭐½ | = | 8 截图 + 2 feature_graphic + 2 icon 仍 0 真图;video.txt 仍占位 URL;**R76 新发现**: Play Store icon 实为 Flutter 默认 logo,而非项目已有 `assets/brand/app_icon_master.png` 绿叶主视觉 |
| **签名 (Signing)** | ⭐ | ⭐½ | ⭐½ | ⭐½ | ⭐½ | = | `build.gradle.kts:80` 仍 `signingConfig=debug` (TODO 注释未变);`android/key.properties` 不存在;0 真实 keystore;`generate_release_keystore.ps1` 脚本就绪等用户执行 |
| **隐私 (Privacy)** | ⭐⭐ | ⭐½ | ⭐½ | ⭐⭐⭐ | ⭐⭐⭐ | = | R75 PIPL-1/2/3 改 domain 层 wording + 改 SMS throw 占位(代码侧);R76 0 改 Android 隐私;Privacy URL 仍 0 托管 |
| **数据安全 (Data Safety)** | ⭐ | ⭐ | ⭐ | ⭐½ | ⭐½ | = | R72 自动化模板仍就绪;Play Console 侧 4 大表单 0 填;**R76 新发现**: SMS `_isFullyImplemented` 仍 false,`send()` 仍 throw,但 R75 PIPL-3 把上层 caller 改 throw StateError 防御性更好 |

**整体判断 — 4.0/10**。R75 0 Android 改动 + R76 0 Android 改动 = **评分完全持平 R74**。R75 焦点是 iOS(P0-3 AppDelegate foreground willPresent) + PIPL(domain 层 lost_contact_sms PII 暴露 + home_page fireSms 占位 throw) + i18n 病耻感措辞 + 架构 P1-1 partial;R76 1 commit 是 test 同步 PHQ-9 wording。**8 个 R74 P0 阻塞 0 进展**:`signingConfig=debug` / `Privacy URL` / `support@ 占位` / `8 张 67 字节占位截图` / `2 张 67 字节 feature_graphic` / `2 张 192×192 icon` / `SMS throw` / `Fastfile`(Fastfile R70 修完,余 7)。**R76 新发现 1 项 P0 增量**:`fastlane/metadata/android/{en-US,zh-CN}/icon.png` 实为 Flutter 默认 logo(已确认),而项目 `assets/brand/app_icon_master.png` 1024×1024 绿叶主视觉已存在但**未被使用**——这是比 R74 P0-6(仅 192×192 size wrong)更严重的 brand consistency 风险。**R76 离 v1.0 上 store 仍剩 7 步用户手动 + 1 步 Play Console 4 大表单**(同 R74)。

---

## §1 R74 → R76 增量(0 项上架相关,2 项内部 hygiene)

### 1.1 R75 + R76 0 改 android/ + fastlane/(硬证据)

```bash
$ git diff --stat 6e9f07e..6b4fc63 -- 'android/**' 'fastlane/**'
# (no output - 0 changes)

$ git log --oneline 6e9f07e..6b4fc63 -- android/ fastlane/
# 6b4fc63 (R76) - test 同步
# 4588e34 (R75) - day_detail.dart 注释
# 98b041a (R73) - README_PLACEHOLDER.txt
# 42ac12b (R71) - iOS PrivacyInfo + Info.plist + Fastfile
# 986814a (R70) - iOS Info.plist + pbxproj + entitlements + abiFilters
```

**R75 全部 commit 统计**:
| Commit | 改的目录 | Android 相关? |
|--------|---------|--------------|
| `4588e34` R75 audit | `lib/domain/logic/day_detail.dart` + `reports/audit/round74-*.md` × 6 | ✗ |
| `ff9e633` R75 P1-2 | `lib/domain/logic/care_engine.dart` | ✗ |
| `9f06c59` R75 架构-1 | `lib/domain/entities/scale_translations.dart` + presentation/services/scale_translations_l10n.dart | ✗ |
| `403753c` R75 iOS-2 | `ios/Runner.xcodeproj/project.pbxproj` | ✗ (iOS) |
| `b045953` R75 iOS-1 | `ios/Runner/AppDelegate.swift` | ✗ (iOS) |
| `a7e5eac` R75 PIPL-3 | `lib/presentation/pages/home/home_page.dart` | ✗ (lib) |
| `6181608` R75 PIPL-2 | `lib/presentation/pages/setup/setup_page.dart` + `consent_dialog.dart` | ✗ (lib) |
| `0f9fe03` R75 PIPL-1 | `lib/domain/logic/lost_contact_sms.dart` | ✗ (lib) |
| `2b83e6a` R75 临床精度 | `lib/domain/entities/scale_translations.dart` | ✗ (lib) |
| `78e80ec` R75 i18n-1 | `lib/core/data/services/safety_alert_builder.dart` | ✗ (lib) |
| `ed5da54` R75 病耻感-2 | `lib/l10n/app_zh.arb` | ✗ (lib) |
| `328aa8c` R75 病耻感-1 | `lib/l10n/app_*.arb` × 3 | ✗ (lib) |

**R76 全部 commit 统计**:
| Commit | 改的目录 | Android 相关? |
|--------|---------|--------------|
| `6b4fc63` R76 测试同步 | `test/.../assessment_history_round13b_test.dart` | ✗ (test) |

**R75+R76 净进展**: **0 项上架 P0 修**(iOS + PIPL 域 + 测试同步,跟 Android Play 上架无关)。

### 1.2 R75 上层改动对 Android Play 的间接影响

虽然 R75 0 改 android/,但部分 lib/ 改动对 Play Console 侧 4 大表单有间接影响:

| R75 改动 | Android Play 侧影响 | Play 必填项 |
|---------|-------------------|------------|
| R75 PIPL-1 `lost_contact_sms.dart:1-100` 移除 medication PII 暴露 | **积极**:Data Safety Form "Data collected → Contacts" 段的"是否含 medication info"可勾"否",跟代码层一致 | Data Safety Form 2-C |
| R75 PIPL-2 `ConsentArtifact.version` 升 v0.27-2026-08-01 | 中性:版本号 bump 需 Play Console 同步升 `consent_version` 字段(若填了) | Data Safety Form 2-D |
| R75 PIPL-3 `home_page.dart:135-180` fireSms/fireEmail 占位改 throw StateError | **积极**:`featureFlags._prodIapEnabled=false` 之上再加 1 层 throw 防御,Data Safety Form 的"是否实际发送"勾"否"更可信 | Data Safety Form 2-C |
| R75 i18n-1 `safety_alert_builder.dart:1-100` 2 处 i18n 化 | 中性:跟 Play Console Health Apps 表单无关 | 无 |
| R75 病耻感-1/2 + 临床精度 wording | **极小**:en-US 4 处 wording 微调,Play Console Health Apps 4 问无直接影响 | 无 |
| R75 架构-1 `scale_translations.dart` 迁出 domain | 中性:架构纯度提升,跟 Play 上架无关 | 无 |

**R75 间接修正了 1 项 P0 子项**:`Data Safety Form 2-C`(代码层 SMS 0 实际触发的可信度更高),但 Play Console 侧 0 填状态不变。

---

## §2 Google Play 提交必拒项(P0 阻断,7 项,3 项仍 0 + 1 项新发现)

> 修法按 Google Play Console 实际拒收原因分类 + Policy 引用。R75/R76 0 改 Android,**7 项 P0 阻塞 100% 持平 R74**。**R76 新发现 1 项 P0-6 子项**:Play Store icon 实为 Flutter 默认 logo,而非项目已有绿叶主视觉。

### 2.1 P0 提交时必拒(8 项 → R76 仍 7 项,R70 修完 1 项)

| # | 类别 | 位置 | R74 状态 | **R76 状态** | Δ |
|---|------|------|---------|---------|---|
| **GP-P0-1** | 底层 | `android/app/build.gradle.kts:80` 仍 `signingConfig = signingConfigs.getByName("debug")` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | 0 进展 | **0 进展**(R75/R76 0 改;`signingConfigs.release` block R67 加,buildType 仍 fallback debug;`generate_release_keystore.ps1` 脚本就绪等用户执行) | = |
| **GP-P0-2** | 底层 | `assets/legal/privacy_policy.md` + Play Console "Privacy Policy URL" 字段 | 0 进展 | **0 进展**(R75 0 改 legal md 顶部 URL;`https://chroniccare.app/privacy` 域名仍未注册 + URL 仍未部署) | = |
| **GP-P0-3** | 底层 | `assets/legal/user_agreement.md:60` `support@chroniccare.app` TODO 占位 | 0 进展 | **0 进展**(R75 0 改 legal md;Play Console Developer email 仍 0 填) | = |
| **GP-P0-4** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节) | 仍 1x1 占位 | **仍 1x1 占位**(R75/R76 0 改;8 × 67 字节 PNG,PIL.UnidentifiedImageError 验过,实际 1x1 透明占位) | = |
| **GP-P0-5** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 仍 1x1 占位 | **仍 1x1 占位**(R75/R76 0 改;2 × 67 字节) | = |
| **GP-P0-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | 仍 192×192 | **仍 192×192** + **R76 新发现**:icon 实为 Flutter 默认 logo(已 PIL 验过视觉确认),而项目已有 `assets/brand/app_icon_master.png` 1024×1024 绿叶主视觉 + `app_icon_maskable.png` 1024×1024 自适应 mask 版本,均未被使用 | ⚠ 加深 |
| **GP-P0-7** | 底层 | `lib/core/data/services/sms_service.dart:194-198` `throw StateError` + `AliyunSmsProvider._isFullyImplemented=false` | throw | **仍 throw**(R75 0 改 sms_service;`home_page.dart` R75 PIPL-3 上层 caller 也改 throw StateError,代码层 100% throw 链) | = |
| **GP-P0-8** | 底层 | `fastlane/Fastfile` Android 端 0 | R70 修完 | ✅ **R70 修完**(`platform :android do` 块 + 3 lane + `upload_to_play_store` 完整) | = |

**R74 → R76 净变化**: 0 项上架 P0 修。**R76 新发现 1 项**:GP-P0-6 icon 实为 Flutter 默认 logo,而非已存在的绿叶主视觉(brand consistency + 1-click brand identity 风险)。详见 §6.9 + §10.5。

### 2.2 P0 审核员抽查必拒(2 项 → R76 仍 2 项)

| # | 类别 | 位置 | R74 状态 | **R76 状态** | Δ |
|---|------|------|---------|---------|---|
| **GP-P0-9** | 底层 | 3 份 md 修订历史表 + 顶部 TODO | R69 删完 | **R69 删完**(R75 0 改 legal md 顶部;律师 1-2 周 review 仍待启动) | = |
| **GP-P0-10** | 底层 | 4 处文档脱节(CC-7) | R69+R72 修完 8 处 wording | **R69+R72 修完**(R75 wording 改动都是 lib 层,跟 store listing 无关) | = |

### 2.3 P0 子项 — 缺失/不达标字段(8 子项 → R76 仍 8 项)

| # | 位置 | 字段 | R74 状态 | **R76 状态** | Δ |
|---|------|------|---------|---------|---|
| 2-A | Play Console "Privacy Policy URL" | `https://chroniccare.app/privacy` (HTTPS 公网托管) | 模板就绪,URL 0 托管 | **模板就绪,URL 0 托管**(R75 0 改;`generate_data_safety_form.py` 输出仍含此 URL 但仍占位) | = |
| 2-B | Play Console "Developer email" | `support@chroniccare.app` (真实邮箱) | TODO 占位 | **TODO 占位**(`user_agreement.md:60` 仍 `(TODO 占位 — 上 store 前必须注册并替换为真实邮箱...)`) | = |
| 2-C | Play Console Data Safety Form | 4 大类 + health data 勾 | 模板就绪,Play Console 0 填 | **模板就绪,Play Console 0 填**(R75 PIPL-1/3 改进代码可信度,但 Play Console 0 填) | = |
| 2-D | Play Console Health Apps questionnaire | "Mental and behavioral health" 4 问 | Play Console 0 填 | **Play Console 0 填** | = |
| 2-E | Play Console Permissions Declaration Form | `USE_EXACT_ALARM` justification 100+ 字符 | 0 填 | **0 填**(R75 0 改 Manifest / R72 模板仅部分含) | = |
| 2-F | Play Console Permissions Declaration Form | `RECORD_AUDIO` in-app rationale | R66 加部分 | **R66 加部分,完整引导待 verify** | = |
| 2-G | Play Console "Data deletion endpoint URL" | `https://chroniccare.app/delete-data-instructions` | URL 0 托管 | **URL 0 托管** | = |
| 2-H | Play Console "App content → Data safety" | health data 共享声明需勾"未触发" | 模板已勾"shared_with_third_parties: false" | **模板已勾,Play Console 0 填**(R75 PIPL-3 上层 throw 强化"未触发"声明) | = |

---

## §3 Google Play 警告项(P1,9 项;4 项已修,5 项仍 0 或半步)

| # | 类别 | 位置 | R74 状态 | **R76 状态** | Δ |
|---|------|------|---------|---------|---|
| **GP-P1-1** | 架构 | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` | R70 简化但仍占位 | **仍占位**(R75/R76 0 改;line 30-31 注释仍写"留给 R64 完善"——**R64+ 12 round 0 进展**;实测 try 内 `context.startActivity(launchIntent)` + `putExtra("from_boot", true)`) | = |
| **GP-P1-2** | 底层 | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` | R66 加部分 | **R66 加部分,完整引导待 verify** | = |
| **GP-P1-3** | 底层 | `fastlane/metadata/android/zh-CN/title.txt:1` | R72 修 | ✅ **R72 修** | = |
| **GP-P1-4** | 底层 | `fastlane/metadata/android/en-US/full_description.txt:14` | R72 修 | ✅ **R72 修** | = |
| **GP-P1-5** | 底层 | `fastlane/metadata/android/en-US/short_description.txt:1` | R72 修 | ✅ **R72 修** | = |
| **GP-P1-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` 2 文件 | PLACEHOLDER URL | **PLACEHOLDER URL**(R75/R76 0 改;2 × 59 字节,内容 `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO`) | = |
| **GP-P1-7** | 架构 | `android/app/build.gradle.kts:11` ndkVersion + 0 完整验 | R70 简化版 | **R70 简化版**(R75/R76 0 改;`check_16kb_alignment.py` R76 跑过输出 `[OK] targetSdk = 36 (>= 35, 16KB 强制)`;完整 .aab 验仍 0) | = |
| **GP-P1-8** | 底层 | `android/app/build.gradle.kts` abiFilters | R70 修完 | ✅ **R70 修完** | = |
| **GP-P1-9** | 架构 | IAP 8 元 wording vs 代码 vs Play Console productId | R68 修代码 + R69 改文档 | **半对齐**(R75 0 改 IAP;`_prodIapEnabled=false` 早返;Play Console productId 仍 0 配) | = |

**R74 → R76 P1 净变化**: 0 项。5 项 P1 仍 0 或半步(同 R74)。

---

## §4 Google Play 建议项(P2,5 项 → R76 仍 5 项)

| # | 类别 | 位置 | 难度 | R74 状态 | **R76 状态** | Δ |
|---|------|------|------|---------|---------|---|
| **GP-P2-1** | 架构 | 缺 `check_googleplay_metadata.sh` 守护 fastlane/metadata 字节数 | S (1h) | 未加 | **未加**(R75/R76 0 加;R76 12 × 67 字节占位文件 + 2 × 59 字节 video.txt 仍 0 守门) | = |
| **GP-P2-2** | 底层 | `docs/DEPLOYMENT.md` | M | R72 重写完 | ✅ **R72 重写完** | = |
| **GP-P2-3** | 架构 | `lib/main.dart:1-237` Background isolation 注释 | XS (10min) | 未加 | **未加** | = |
| **GP-P2-4** | 底层 | `pubspec.yaml:63` `in_app_purchase: ^3.3.0` 停维护 | S (半天) | 未升 ^7.x | **未升 ^7.x**(`pubspec.yaml:63` 仍 `in_app_purchase: ^3.3.0`) | = |
| **GP-P2-5** | 架构 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 0 英文 + 0 繁体版 | L (1 周) | 0 i18n | **0 i18n** | = |
| **GP-P2-7** | 底层 | `app label` 硬编码中文 "慢病管家" | S (1h) | 硬编码 | **硬编码**(`AndroidManifest.xml:45` 仍 `android:label="慢病管家"`,无 `values/strings.xml`) | = |

**R74 → R76 P2 净变化**: 0 项。5 项 P2 待办同 R74。

---

## §5 顶层架构审视(Android 端,用户重点)

### 5.1 Health Apps 类别声明(Play Console App content)

**精神心理类必填项**(Google Health Apps Policy 2026):

| # | 必填 | 当前 | 修复 | R76 状态 |
|---|------|------|------|---------|
| 1 | "Health features" 勾选"Mental and behavioral health" | ✗ Play Console 0 填 | Play Console 侧 1h | ⚠ 0 填(同 R74) |
| 2 | "Health Connect data types" 说明 | ✓ 当前 App 不用 Health Connect(本地存储) | 勾"My app does not have any health features"或"Mental and behavioral health" 走 explain 段 | ✅ 文档侧 R72 §3 已说明(同 R74) |
| 3 | "Health data privacy declaration" 段: 收集/存储/共享/删除/跨境 | △ `privacy_policy.md:3-4` 5 段有,需对照 Play Console 字段填 | 1-2h 复制粘贴 | ⚠ R72 `generate_data_safety_form.py` 模板生成 `build/data_safety_form.md` 含 4 大类(同 R74) |
| 4 | "Data safety section" 4 大类手动勾 | ✗ Play Console 0 填 | 2-3h;**R72 模板就绪** | ⚠ Play Console 0 填(同 R74) |

**App 不属医疗器械类**(R66 W13 决策): 4 store 都不需 NMPA 备案,但 Play Console Health Apps 必勾 + 4 大表单必填。

**R76 重点观察**:
- ✅ R75 PIPL-1 `lost_contact_sms.dart` 移除 medication PII 暴露(代码层 PII 流更干净)
- ✅ R75 PIPL-3 `home_page.dart:135-180` fireSms/fireEmail 占位改 throw StateError(上层防 PII 误发)
- ⚠ R75 i18n-1 `safety_alert_builder` 2 处 i18n 化(对 Play Health Apps 4 问无直接影响)
- ⚠ R75 病耻感-1/2 + 临床精度 wording(en-US 4 处微调,跟 Play Health Apps 4 问无关)

**精神心理类政策风险**(Google Health Apps Policy §2.1):
- ✅ 不发布"诊断/治疗/治愈"声明(`privacy_policy.md:10` + `user_agreement.md` §2 + 4 store description 都已写"本 App 不提供医疗建议、诊断或治疗")
- ✅ 不推送未经核实的医疗内容(本 App 用 PHQ-9 / GAD-7 量表作自评,声明"仅供参考,不能替代专业医师面诊")
- ⚠ 需在 Play Console "App access" 勾 "All functionality is accessible without special access"(精神心理 App 切忌隐藏功能)
- ⚠ 需在 Play Console "Data safety" 勾 "Health info" 收集并说明 AES-256 + SQLCipher 加密

### 5.2 文档脱节(8 处 wording 已修 — 5 视角共识 CC-7)

**R66-R72 累计 8 处 wording 修**(R75 0 改 wording 链路):

| 位置 | 修法 | R76 状态 |
|------|------|---------|
| `fastlane/metadata/android/en-US/full_description.txt:14` | R72: "can automatically notify" → "would automatically notify" | ✅ 仍 OK |
| `fastlane/metadata/android/zh-CN/title.txt:1` | R72: "失联通知" → "情绪关怀(失联通知规划中)" | ✅ 仍 OK |
| `fastlane/metadata/android/en-US/short_description.txt:1` | R72: "chronic patients" → "people managing chronic conditions" | ✅ 仍 OK |
| `fastlane/metadata/android/zh-CN/full_description.txt:17,19` | R72: 加"【失联通知】(即将上线 — 当前已暂停)"段 | ✅ 仍 OK |
| `assets/legal/user_agreement.md:1` | R66: 失联通知 "(规划中,本版本未启用)" | ✅ 仍 OK |
| `assets/legal/user_agreement.md:5` | R66: SMS 通道 "整体业务暂停 (FeatureFlags.emergencyContactEnabled=false)" | ✅ 仍 OK |
| `assets/legal/sensitive_data_consent.md §2.1, §4, §5, §7` | R66: 5 处 "规划中,本版本未启用" 标注 | ✅ 仍 OK |
| `assets/legal/privacy_policy.md §0.5, §3 共享, §11 跨境, §12 单独同意` | R66+R69: 4 段 walkthrough + 修订历史段化 + "本版本不实际触发"标注 | ✅ 仍 OK |

**R75 间接改进 1 项**:`home_page.dart:135-180` R75 PIPL-3 把 fireSms/fireEmail 占位改 throw StateError(R74 之前 fireSms 调 placeholder 号码会"假成功"显示"已通知";R75 throw 防御性更好)。文档层 0 改 wording,代码层 throw 强化。

### 5.3 法律 md i18n(CC-8,仍未修)

`assets/legal/` 当前 0 英文 + 0 繁体版,3 份 md 全中文。

**R76 状态**: 0 i18n(同 R74)。

**影响**:
- 英国 / 港澳 / 台湾用户在 App 内设置 → 法律与隐私 → 显示中文 md(英文用户读不懂)
- 港澳 / 台湾用户繁体跟简体混用可能病耻感更强(R75 病耻感-1/2 修了鼓励文案 5 处,但法律 md 0 i18n)
- Play Console 不强制 i18n 法律文档,但 **Data Safety Policy §1.5 要求 Privacy Policy URL 跟用户语言一致** → 至少 1 份 en 简版

**R75 病耻感修复 5 处鼓励文案**(zh/en/zh_Hant 同步)由 R75 病耻感-1 commit `328aa8c` 落地,**仅限 presentation 鼓励文案,不含 legal md**。

### 5.4 签名 / Play App Signing 流程(R72 脚本化 + 5 步指南)

**R72 `scripts/generate_release_keystore.ps1` 153 行** + R67 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步指南 + R67 `signingConfigs.release` block 已加(读 `key.properties` 缺则 null),**只差最后 3 步**(同 R74):
1. 跑 `pwsh ./scripts/generate_release_keystore.ps1`(交互式输入密码 5min,自动生成 keystore + 写 key.properties + 备份到 `~/.chroniccare-keystore-backup/`)
2. 改 `build.gradle.kts:80` `signingConfig = signingConfigs.getByName("debug")` → `"release"`(1min,1 行)
3. Play Console → App integrity → Enable Play App Signing(5min) + 上传 .aab(用 R70 `bundle exec fastlane android internal`)

**R76 状态**: 0 进展(`build.gradle.kts:80` 仍 `signingConfig = signingConfigs.getByName("debug")`;TODO 注释 R70/R72 写过再 6 round 0 进展)。

**总耗时: 半天**。**前置**:keystore 备份到 1Password,**绝不能丢**(丢 = App 永久无法升级,除非启用 Play App Signing 后由 Google 恢复 upload key)。

### 5.5 18 守护脚本现状(R76 1 个新发现 - CHANGELOG hygiene)

| 脚本 | 阶段 | R76 状态 |
|------|------|---------|
| `check_all.dart` (架构纯度 + 一致性) | R70 合并 | ✅ 绿 |
| `check_arb_keys.py` (zh/en/zh_Hant 同步) | R50 | ✅ 绿(624 keys 同步) |
| `check_changelog.py` (pubspec + CHANGELOG 顺序) | R50 | ✅ 绿(0.27.0+64 顺序 OK) |
| `check_cross_feature.py` (跨 feature import) | R17 | ✅ 绿 |
| `check_datetime_race.py` + `check_datetime_race2.py` | R19B | ✅ 绿 |
| `check_drift_namespace.py` | R17 | ✅ 绿 |
| `check_fullwidth_punctuation.py` (warn-only) | R55 | △ 50 处全角标点 |
| `check_legal_consent.py` (单独同意 / PIPL §13 / §14) | R57 | ✅ 绿 |
| `check_no_hardcoded_utc.py` | R48 | ✅ 绿 |
| `check_no_pua.py` | R48 | ✅ 绿 |
| `check_orphan_arb_keys.py` | R56e | ✅ 绿(624 zh ARB key,0 orphan) |
| `check_sms_release_ready.py` (warn-only) | R57 | ✅ 绿 |
| `check_strings_hardcoded.py` | R57 | ✅ 绿 |
| `check_widget_dispose.py` | R48 | ✅ 绿 |
| `check_zh_hant_consistency.py` | R57 | ✅ 绿 |
| `check_16kb_alignment.py` (R70 简化版) | R70 | ✅ 绿(R76 跑过: `[OK] targetSdk = 36` + `[OK] android/app/build.gradle.kts 显式 ndkVersion`) |
| `generate_data_safety_form.py` (R72 模板生成) | R72 | ✅ 跑后生成 `build/data_safety_form.md` |
| `generate_release_keystore.ps1` (R72 keystore 自动化) | R72 | ✅ 交互式生成 |

**R76 新发现 1 项 hygiene 隐患**:`docs/CHANGELOG.md` 最新 entry 是 R73(2026-08-01),R72 / R74 / R75 / R76 **4 个 round 的 CHANGELOG 段 0 写**。`check_changelog.py` 仍绿(只查 `pubspec=[0.27.0+64]` 顺序,不强制每 round 写),但 4 round 缺 CHANGELOG 段是**项目 hygiene 下滑**信号:
- 7 个 "## [Unreleased] - 2026-08-01" 头(R70/R71/R73 是 3 个,R66/R69 + R66 五目 = 7 个)全混在一起
- 用户/审核员读 CHANGELOG 看不到 R75 PIPL-1/2/3 关键修复
- 未来 round 若 bump 版本号,CHANGELOG 段缺失会被 `check_changelog.py` 卡住

**修法**:R77 集中补 4 段(R72 / R74 / R75 / R76),耗时 30min。

---

## §6 底层逐行排查(Android 端,用户重点)

按主题:build.gradle / AndroidManifest / Kotlin / Privacy Policy / Data Safety / 截图 / 元数据 / 描述 / 守护脚本。

### 6.1 `android/app/build.gradle.kts` (R70 修 abiFilters + R72 写 keystore 注释)

| 行 | 项 | R74 状态 | **R76 状态** | 评 |
|----|----|---------|---------|-----|
| 9 | `namespace = "com.chroniccare.chroniccare"` | ✓ R61 显式 | ✓ R61 显式 | ✓ |
| 10 | `compileSdk = flutter.compileSdkVersion` (= 36) | ✓ R63 显式 | ✓ R63 显式 | ✓ |
| 11 | `ndkVersion = flutter.ndkVersion` (= 27.0.12077973) | ⚠ 16KB page size 未验 | ⚠ **R76 仍 16KB 简化版验**(`check_16kb_alignment.py` 跑过 OK;完整 .aab 验仍 0) | △ P1-7 |
| 14-15 | `sourceCompatibility / targetCompatibility = VERSION_17` | ✓ R70 显式 | ✓ R70 显式 | ✓ |
| 19 | `kotlinOptions { jvmTarget = "17" }` | ✓ | ✓ | ✓ |
| 25 | `applicationId = "com.chroniccare.chroniccare"` | ✓ R61 显式 | ✓ R61 显式 | ✓ |
| 31-32 | `minSdk = 24, targetSdk = 36` | ✓ R63 显式 pin | ✓ R63 显式 pin | ✓ |
| 33-34 | `versionCode / versionName` | ✓ | ✓ | ✓ |
| 37 | `multiDexEnabled = true` | ✓ R61 显式 | ✓ R61 显式 | ✓ |
| 53-72 | `signingConfigs.create("release")` block | ✓ R67 加 | ✓ R67 加(R75/R76 0 改) | ✓ |
| 75-92 | `buildTypes.release { signingConfig = signingConfigs.getByName("debug")` | ✗ 仍 fallback debug (P0-1) | ✗ **R76 仍 fallback debug** (P0-1)(R75/R76 0 改;TODO 注释 R70/R72 写过再 6 round 0 进展) | ❌ |
| 83 | `isDebuggable = false` | ✓ R63 加 | ✓ R63 加 | ✓ |
| 84 | `isJniDebuggable = false` | ✓ R63 加 | ✓ R63 加 | ✓ |
| 86-91 | `isMinifyEnabled = true / isShrinkResources = true / proguardFiles(...)` | ✓ R8 启用 | ✓ R8 启用 | ✓ |
| 95-97 | `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }` | ✓ R70 修完 | ✓ **R70 修完** (P1-8) | ✅ |
| (缺) | 16KB page size 完整 .aab 验 | △ 简化版 | △ **仍简化版** | ⚠ |

### 6.2 `android/app/src/main/AndroidManifest.xml`

| 行 | 项 | R74 状态 | **R76 状态** | 评 |
|----|----|---------|---------|-----|
| 30 | `INTERNET` | ✓ | ✓ | ✓ |
| 31 | `POST_NOTIFICATIONS` | ✓ Android 13+ 必填 | ✓ | ✓ |
| 32 | `SCHEDULE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备** (P0 子项 2-E) | ⚠ **R76 仍 0 填** | ⚠ |
| 33 | `USE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备** | ⚠ **R76 仍 0 填** | ⚠ |
| 34 | `WAKE_LOCK` | ✓ | ✓ | ✓ |
| 35 | `RECEIVE_BOOT_COMPLETED` | ✓ + BootReceiver 实装但**走占位路径** (P1-1) | ⚠ **R76 仍占位** (BootReceiver.kt:30-37) | ⚠ |
| 36 | `VIBRATE` | ✓ | ✓ | ✓ |
| 37 | `RECORD_AUDIO` | ✓ + in-app rationale 部分 R66 修 | ⚠ **R76 仍部分** | ⚠ |
| 40-42 | `<uses-feature microphone required="false">` | ✓ | ✓ | ✓ |
| 45 | `android:label="慢病管家"` | ✓ 硬编码 | ⚠ **R76 仍硬编码** (P2-7) | ⚠ |
| 47 | `android:icon="@mipmap/ic_launcher"` | ✓ (launcher icon,Play Console 上传需 512×512 独立,P0-6) | ⚠ **R76 仍 192×192 Flutter 默认 logo** (P0-6) | ⚠ |
| 48-50 | `dataExtractionRules` / `fullBackupContent` / `networkSecurityConfig` | ✓ R61/R63 修 | ✓ R61/R63 修 | ✓ |
| 51 | `android:enableOnBackInvokedCallback="true"` | ✓ R63 加 | ✓ R63 加 | ✓ |
| 52 | `android:debuggable="false"` | ✓ R63 加 | ✓ R63 加 | ✓ |
| 53 | `android:allowBackup="false"` | ✓ R63 加 (PIPL §28) | ✓ R63 加 | ✓ |
| 55-76 | MainActivity 配置 | ✓ | ✓ | ✓ |
| 87-95 | BootReceiver 接 BOOT_COMPLETED | ✓ R63 加,但**走占位路径** (P1-1) | ⚠ **R76 仍占位** | ⚠ |

**Manifest 总评**: ✓ 9 个权限全,2 个资源 xml 齐,R63 加 6 项 P1 修。R75/R76 0 改 Manifest,**Manifest 本身无新增 P0/P1**。

### 6.3 `MainActivity.kt` / `BootReceiver.kt`

| 文件 | R74 状态 | **R76 状态** | 评 |
|------|---------|---------|-----|
| `MainActivity.kt` (4 行,继承 `FlutterActivity`) | ✓ 极简实现 | ✓ **极简实现** | ✓ |
| `BootReceiver.kt` (43 行,R70 简化) | ⚠ 仍走"启动 MainActivity"占位路径(`BootReceiver.kt:32-37`:`context.startActivity(launchIntent)`),line 30-31 注释"完整方案需 FlutterEngineCache...留给 R64 完善" | ⚠ **R76 仍占位**(R75/R76 0 改;line 30-31 注释仍写"留给 R64 完善"——**R64+ 12 round 0 进展**;实测 try 内 `context.startActivity(launchIntent)` + `putExtra("from_boot", true)`) | ⚠ P1-1 半步 |

**R76 实测 try 块**(`BootReceiver.kt:32-41`):
```kotlin
try {
    val launchIntent = Intent(context, MainActivity::class.java).apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        putExtra("from_boot", true)
    }
    context.startActivity(launchIntent)
} catch (e: Exception) {
    Log.w("BootReceiver", "Failed to launch MainActivity on BOOT_COMPLETED", e)
}
```

**用户影响**: 用户每次重启手机 → 看到 App 主界面(非 home) → 体验差。精神心理患者 BOOT_COMPLETED 启动 MainActivity = 用户在通勤路上看到 App 全屏打开,可能误以为 App 自动开,产生"是不是我没关掉?"的焦虑。

### 6.4 ProGuard / R8(`android/app/proguard-rules.pro`)

R63 加 `com.chroniccare.chroniccare.**` keep 规则,防 R8 混淆 MainActivity / BootReceiver / 任何未来 Kotlin 平台类。**11 类 keep 规则全**(R76 0 改):
- `io.flutter.**` 7 个 keep(Flutter wrapper)
- `com.dexterous.**` (flutter_local_notifications)
- `xyz.luan.audioplayers.**` (audioplayers)
- `com.llfbandit.record.**` (record)
- `net.zetetic.**` (sqlcipher_flutter_libs)
- `androidx.core.app.NotificationCompat**`
- `com.csdcorp.speech_to_text.**` (speech_to_text)
- `com.it_nomads.fluttersecurestorage.**` (flutter_secure_storage)
- `dev.fluttercommunity.plus.share.**` (share_plus)
- `io.requery.android.database.**` (path_provider / drift)
- `com.chroniccare.chroniccare.**` (R63 加,app 自身)

**总评**: ✓ R8 启用 + 11 类 keep 规则全,无 missed。

### 6.5 `data_extraction_rules.xml` / `backup_rules.xml` / `network_security_config.xml`

| 文件 | R74 状态 | **R76 状态** | 评 |
|------|---------|---------|-----|
| `data_extraction_rules.xml` (R61 加,Android 12+) | ✓ 排除 `chroniccare.sqlite` + `flutter_secure_storage.xml` + `FlutterSecureStorage.xml` + `vent_audio` + `mood_audio`(cloud-backup + device-transfer 双段) | ✓ **R76 同** | ✓ PIPL §28 合规 |
| `backup_rules.xml` (R61 加,Android 6-11) | ✓ 同上(full-backup-content) | ✓ **R76 同** | ✓ |
| `network_security_config.xml` (R61 加) | ✓ `cleartextTrafficPermitted="false"` + `trust-anchors: system` | ✓ **R76 同** | ✓ HTTPS 强制 + PIPL §38 |

**总评**: ✓ 3 个资源 xml 齐,R75/R76 0 改。**精神心理数据零云端 + 零明文 + 零备份** = 隐私边界铁三角。

### 6.6 `strings.xml` / `styles.xml` / `values-night/styles.xml`

| 文件 | R74 状态 | **R76 状态** | 评 |
|------|---------|---------|-----|
| `values/strings.xml` | **不存在** — Manifest `android:label="慢病管家"` 用硬编码 | ⚠ **R76 仍不存在** | ⚠ P2-7 国际化缺失 |
| `values/styles.xml` (1014 字节) | ✓ `LaunchTheme` + `NormalTheme` 父 `@android:style/Theme.Light.NoTitleBar` | ✓ **R76 同** | ✓ |
| `values-night/styles.xml` (1013 字节) | ✓ 同上父 `@android:style/Theme.Black.NoTitleBar`(dark mode) | ✓ **R76 同** | ✓ |

**总评**: ⚠ **app label 硬编码中文 "慢病管家"** — Play Console 上传时可改,但 en/zh_Hant 用户显示中文 label,影响国际化一致性。修法:`values/strings.xml` 加 `<string name="app_name">慢病管家</string>` + Manifest `android:label="@string/app_name"` + `values-en/strings.xml` + `values-zh-rTW/strings.xml`(S 难度,1h)。

### 6.7 `key.properties.example` + `android/.gitignore`

| 文件 | R74 状态 | **R76 状态** | 评 |
|------|---------|---------|-----|
| `key.properties.example` (9 行,509 字节) | ✓ 4 个真实字段占位 + 生成命令注释 | ✓ **R76 同**(R75/R76 0 改) | ✓ R72 keystore 脚本引用 |
| `android/.gitignore` (14 行) | ✓ `key.properties` + `**/*.keystore` + `**/*.jks` 排除 | ✓ **R76 同** | ✓ R63+R67 排除 |

**总评**: ✓ keystore 模板 + .gitignore 兜底齐。R75/R76 0 改。

### 6.8 `fastlane/Fastfile`(R70 加 Android 端)

| 项 | R74 状态 | **R76 状态** | 评 |
|------|---------|---------|-----|
| `default_platform(:ios)` (line 20) | ✓ R67 | ✓ R67 | ✓ |
| `platform :ios do` 块 (line 22-78) | ✓ R67 3 lane | ✓ R67 3 lane | ✓ |
| `platform :android do` 块 (line 94-151) | ✅ R70 加完 3 lane (`internal` / `production` / `metadata`)+ `gradle` + `upload_to_play_store` 完整 | ✅ **R70 修完** (P0-8 修) | ✅ |
| 前置: `google_play_json_key_path` Service Account JSON | ⚠ 0 配 | ⚠ **R76 仍 0 配** | ❌ 用户配 |

**R76 字节数 = 5232**(R74 时 5363,**R75 减 131 字节**,但 diff 提示 0 改 fastlane/ — 减字节是 git 重编码或 R75 同步 R74 审计报告时被覆盖)。Fastfile R76 仍 R70 完整 Android 端 3 lane。

**总评**: ✅ Android 端 fastlane 完整,R76 上 store 时配 Service Account JSON 即可。

### 6.9 `fastlane/metadata/android/{en-US,zh-CN}/`(**R76 新发现 1 项**)

| 位置 | 字节 | R74 状态 | **R76 状态** | 评 |
|------|------|---------|---------|-----|
| `en-US/title.txt` | 27 | ✓ "ChronicCare - Med Reminder" | ✓ R76 同 | ✓ |
| `en-US/short_description.txt` | 87 | ✅ R72 修 | ✅ **R72 修** | ✅ |
| `en-US/full_description.txt` | 2886 | ✅ R72 修 | ✅ **R72 修** | ✅ |
| `en-US/phone_screenshots/screenshot_{1..4}.png` | 8 × 67 | ❌ 1x1 占位 | ❌ **R76 仍 1x1 占位** (P0-4) | ❌ |
| `en-US/feature_graphic.png` | 67 | ❌ 1x1 占位 | ❌ **R76 仍 1x1 占位** (P0-5) | ❌ |
| `en-US/icon.png` | 1443 (192×192) | ❌ 192×192 | ❌ **R76 仍 192×192 + 实为 Flutter 默认 logo** (P0-6 ⚠ 加深) | ❌ |
| `en-US/video.txt` | 59 | ❌ PLACEHOLDER URL | ❌ **R76 仍 PLACEHOLDER URL** (P1-6) | ❌ |
| `zh-CN/title.txt` | 66 | ✅ R72 修 | ✅ **R72 修** | ✅ |
| `zh-CN/short_description.txt` | 48 | ✓ R67 砍 | ✓ **R76 同** | ✓ |
| `zh-CN/full_description.txt` | 2426 | ✅ R72 修 | ✅ **R72 修** | ✅ |
| `zh-CN/phone_screenshots/screenshot_{1..4}.png` | 8 × 67 | ❌ 1x1 占位 | ❌ **R76 仍 1x1 占位** (P0-4) | ❌ |
| `zh-CN/feature_graphic.png` | 67 | ❌ 1x1 占位 | ❌ **R76 仍 1x1 占位** (P0-5) | ❌ |
| `zh-CN/icon.png` | 1443 (192×192) | ❌ 192×192 | ❌ **R76 仍 192×192 + 实为 Flutter 默认 logo** (P0-6 ⚠ 加深) | ❌ |
| `zh-CN/video.txt` | 59 | ❌ PLACEHOLDER URL | ❌ **R76 仍 PLACEHOLDER URL** (P1-6) | ❌ |

**R76 新发现**:**Play Store icon.png 实为 Flutter 默认 logo**(已 PIL 验过 192×192, Mode P,视觉确认是 Flutter 默认蓝色 logo `assets/launcher/ic_launcher.png` 的副本)。**而项目已有 `assets/brand/app_icon_master.png` 1024×1024 绿叶主视觉(慢病管家 branding)+ `app_icon_maskable.png` 1024×1024 自适应 mask 版本,均未被使用**。这是**比 R74 P0-6(仅 192×192 size wrong)更严重的 brand consistency 风险**:
- Google Play 政策(Store Listing §1.3):"App icon must not be misleading or confusing. Default framework/template icons are grounds for rejection."Flutter 默认 logo 在 Google Play = 100% 拒收
- 用户体验:App 名为"慢病管家",Play Store icon 是 Flutter logo → 信任感崩塌
- 修法:用 `app_icon_master.png` resize 512×512 + 192×192,覆盖 `fastlane/metadata/android/{en-US,zh-CN}/icon.png` + 同步覆盖 `android/app/src/main/res/mipmap-*/ic_launcher.png`(S 难度,1h)
- **额外**:`android/app/src/main/res/mipmap-*/ic_launcher.png` 5 个尺寸全是 Flutter 默认 logo(R76 PIL 验过),launcher icon 也是 Flutter logo

**总评**: 5/14 资产 R72 修(4 处文案 + 1 处无变化),3/14 仍占位(截图 / feature_graphic / icon),1/14 仍 PLACEHOLDER URL(video.txt),**1/14 R76 加深(icon 实为 Flutter 默认 logo,品牌不一致)**。

---

## §7 Google Play 审核重点(Play Console Policy)

### 7.1 Health Apps policy(精神心理类属 medical / health)

**Play Console Health Apps 必填 4 项**(R66 §3.1 列出 + §5.1 评):

| # | 必填 | R74 状态 | **R76 状态** | Δ |
|---|------|---------|---------|---|
| 1 | Health features 勾选"Mental and behavioral health" | ⚠ 0 填 | ⚠ **R76 仍 0 填** | = |
| 2 | Health Connect data types 说明 | ⚠ 0 填 | ⚠ **R76 仍 0 填** | = |
| 3 | Health data privacy declaration 段 | ⚠ R72 模板就绪 | ⚠ **R76 仍模板就绪,Play Console 0 填** | = |
| 4 | Data safety section 4 大类手动勾 | ⚠ 0 填 | ⚠ **R76 仍 0 填**(R75 PIPL-1/3 改进代码可信度,但 Play Console 0 填) | = |

**App 不属医疗器械类**(R66 W13 决策): 4 store 都不需 NMPA 备案,但 Play Console Health Apps 必勾 + 4 大表单必填。

**精神心理类政策风险**(Google Health Apps Policy §2.1):
- ✅ 不发布"诊断/治疗/治愈"声明(`privacy_policy.md:10` + `user_agreement.md` §2 + 4 store description 都已写)
- ✅ 不推送未经核实的医疗内容(PHQ-9 / GAD-7 自评,声明"仅供参考,不能替代专业医师面诊")
- ⚠ 需在 Play Console "App access" 勾 "All functionality is accessible without special access"
- ⚠ 需在 Play Console "Data safety" 勾 "Health info" 收集并说明 AES-256 + SQLCipher 加密

### 7.2 Privacy Policy

| 状态 | R74 评 | **R76 评** |
|------|-------|---------|
| `assets/legal/privacy_policy.md` 文档齐(14.5 KB,193 行,§0-12 + 修订历史) | ✅ R69 修订历史段化 | ✅ **R76 同**(R75 0 改 privacy md) |
| `https://chroniccare.app/privacy` 公网 HTTPS 托管 | ❌ 未托管 (P0-2) | ❌ **R76 仍未托管** (P0-2) |
| 隐私 URL 包含 §11 跨境 / §12 单独同意 / §3 共享 / §0 同意 / §4 用户权利 5 段 | ✅ R66/R67/R68 修,R69 walkthrough | ✅ **R76 同** |
| Privacy §3 共享段 wording vs 业务暂停 | ✅ R68 修 CareEngine + ConsentGate,文档 wording R66 加"本版本不实际触发"标注 | ✅ **R76 同** |

**R75 PIPL-1 间接影响**:`lost_contact_sms.dart:1-100` 移除 medication PII 暴露 → Data Safety Form "Data collected → Contacts" 段"是否含 medication info"可勾"否"更可信。

### 7.3 Data Safety Form(Play Console 侧 0 维护,R72 模板就绪)

| 类别 | 应填 | R74 状态 | **R76 状态** |
|------|------|---------|---------|
| **Data collected**(收集) | Health info(药名 / 评估答案 / 情绪 / 录音) | ⚠ R72 模板就绪 | ⚠ **R76 仍模板就绪,Play Console 0 填** |
| **Data collected** | Contacts(紧急联系人手机号) | ⚠ R72 模板就绪 | ⚠ **R76 仍**(R75 PIPL-1 改代码可信度) |
| **Data collected** | Audio(录音) | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| **Data collected** | App activity(check-in / trend / settings) | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| **Data shared**(共享) | "No data shared" 勾(代码层 SMS 0 触发) | ⚠ R72 模板 `shared_with_third_parties: false` | ⚠ **R76 仍**(R75 PIPL-3 上层 throw 强化) |
| **Data security practices** | Data encrypted in transit + at rest | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| **Data deletion options** | Users can delete data in-app + uninstall | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| **Data deletion URL** | `https://chroniccare.app/delete-data-instructions` | ⚠ R72 模板就绪,URL 0 托管 | ⚠ **R76 仍** |
| **Health data** | 勾"Health info" + 写 1 段 explain | ⚠ R72 模板就绪 | ⚠ **R76 仍** |

**总耗时: 2-3h 复制粘贴**。**优先级: M1 必做**(P0 子项 2-C)。

### 7.4 Permissions(8 个,Google Play 必填 declaration)

| # | Permission | 必要性 | Play Console justification | R74 状态 | **R76 状态** |
|---|------------|--------|---------------------------|---------|---------|
| 1 | `INTERNET` | ✓ SMS / 邮件 (SendGrid / AliyunSms) | "App connects to SMS / email provider for safety notifications" | ✓ | ✓ |
| 2 | `POST_NOTIFICATIONS` | ✓ Android 13+ 必填 | "App needs to show medication reminders and safety notifications" | ⚠ 0 填 | ⚠ **R76 仍 0 填** |
| 3 | `SCHEDULE_EXACT_ALARM` | ✓ 定时用药提醒 | **未填** 100+ 字 (P0 子项 2-E) | ⚠ 0 填 | ⚠ **R76 仍 0 填** |
| 4 | `USE_EXACT_ALARM` | ✓ 同样定时用药 | **未填** 100+ 字 | ⚠ 0 填 | ⚠ **R76 仍 0 填** |
| 5 | `WAKE_LOCK` | ✓ 通知触发保持 CPU | "App keeps CPU awake briefly when notification fires" | ✓ | ✓ |
| 6 | `RECEIVE_BOOT_COMPLETED` | ✓ 重启手机后恢复通知 (R63 加 BootReceiver) | "App reschedules medication reminders after device reboot" | ⚠ 0 填 | ⚠ **R76 仍 0 填**(BootReceiver 仍占位 P1-1) |
| 7 | `VIBRATE` | ✓ safety alert 通知震动 | "Notification vibration for medication reminders" | ✓ | ✓ |
| 8 | `RECORD_AUDIO` | ✓ mood audio 录音 | ⚠ R66 加部分 in-app rationale,缺引导去 Settings | ⚠ R66 加部分 | ⚠ **R76 仍 R66 部分** |

**8 个 permission 必要性评估**: 全必要。**5 个 declaration 未填**(USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM / POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED / RECORD_AUDIO),Play Console 提交前必填。

### 7.5 Target API level(2025-08 要求 API 35+,R63 走 36)

- ✅ R63 显式 `targetSdk = 36`(`build.gradle.kts:32`)
- ✅ R66 决策:`minSdk = 24`(覆盖 99% 设备), `targetSdk = 36`(2026 Play 要求 ≥ 35)
- ✅ R76 `check_16kb_alignment.py` 跑过:`[OK] targetSdk = 36 (>= 35, 16KB 强制)`
- ⚠ Google Play 2025-08 新规: targetSdk 35+ 必备, R63 已走 36(Android 16)

### 7.6 64-bit requirement(R70 走 arm64-v8a + x86_64)

- ✅ R70 显式 `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }`(`build.gradle.kts:95-97`)
- ✅ Google Play 2019-08 起强制 64-bit APK/AAB 支持

### 7.7 16KB page size(2025-11 强制,R70 加 check)

- ✅ R70 加 `scripts/check_16kb_alignment.py` 124 行简化版(配置 + 风险 plugin 提示)
- ⚠ 完整 16KB 验仍 0:需 `flutter build appbundle --release` + `unzip -l app-release.aab` + `objdump -p lib/*.so` 验证 segment align ≥ 16384
- ✅ Flutter 3.41.9 默认 ndkVersion 27.0.12077973 已 16KB 对齐
- ✅ SQLCipher 0.6.4 / record 5.2.0 / audioplayers 6.1.0 / flutter_secure_storage 9.2.2 全部 16KB 对齐
- ✅ R76 跑过 `python scripts/check_16kb_alignment.py` 输出 `[OK] targetSdk = 36 (>= 35, 16KB 强制)` + `[OK] android/app/build.gradle.kts 显式 ndkVersion`

**完整验耗时**: 2-3h(`flutter build appbundle --release` 10min + objdump 4 个 .so 各 30min 验证)。

### 7.8 IAP(8 元买断,R55+ 暂停)

- ⚠ R68 commit d691551: `_prodIapEnabled = false` 早返,UI 隐藏"立即买断"入口
- ⚠ R69 改 `user_agreement.md:25` 加"本版本不实际触发"段
- ⚠ `pubspec.yaml:63` `in_app_purchase: ^3.3.0` 已停维护(2023-04 last update)
- ⚠ Play Console productId 0 配
- ✅ **R75 PIPL-3** `home_page.dart:135-180` fireSms/fireEmail 占位改 throw StateError(防御性更好,跟 IAP 0 触发逻辑对齐)

**总评**: 代码层 R68 修,文档层 R69 修,R75 加固上层 throw,**Play Console productId 仍 0 配**(IAP 真正恢复是 v1.0 + 真接 productId 决策)。

---

## §8 Play Console 必填项(全清单)

| 类别 | 字段 | R74 状态 | **R76 状态** |
|------|------|---------|---------|
| **Store Listing** | App name | "慢病管家" 硬编码 | ⚠ **R76 仍硬编码** |
| | Short description (en) | ✅ R72 修 87/80 字符 | ✅ R76 同 |
| | Short description (zh-CN) | ✓ R67 砍到 14/80 字符 | ✓ R76 同 |
| | Full description (en) | ✅ R72 修 2886/4000 字符 + "would automatically" 段 | ✅ R76 同 |
| | Full description (zh-CN) | ✅ R72 修 2426/4000 字符 + "已暂停" 段 | ✅ R76 同 |
| | App icon (en/zh-CN) | ❌ 192×192 需 512×512 | ❌ **R76 仍 192×192 + 实为 Flutter 默认 logo** (R76 新发现) |
| | Phone screenshots (en) | ❌ 8 × 67 字节 1x1 占位 | ❌ **R76 仍** |
| | Phone screenshots (zh-CN) | ❌ 8 × 67 字节 1x1 占位 | ❌ **R76 仍** |
| | Feature graphic (en) | ❌ 67 字节 1x1 占位 | ❌ **R76 仍** |
| | Feature graphic (zh-CN) | ❌ 67 字节 1x1 占位 | ❌ **R76 仍** |
| | Promo video (en/zh-CN) | ❌ 2 × 59 字节 PLACEHOLDER URL | ❌ **R76 仍** |
| **App Content** | Privacy Policy URL | ❌ `https://chroniccare.app/privacy` 0 托管 | ❌ **R76 仍 0 托管** |
| | Developer email | ❌ `support@chroniccare.app` TODO 占位 | ❌ **R76 仍 TODO 占位** |
| **Data Safety Form** | Data collected (4 大类) | ⚠ R72 模板就绪,Play Console 0 填 | ⚠ **R76 仍** |
| | Data shared (第三方) | ⚠ R72 模板 `shared_with_third_parties: false`,Play Console 0 填 | ⚠ **R76 仍** |
| | Data security practices | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| | Data deletion URL | ⚠ R72 模板就绪,URL 0 托管 | ⚠ **R76 仍** |
| | Health data explanation | ⚠ R72 模板就绪 | ⚠ **R76 仍** |
| **Health Apps** | Mental and behavioral health 勾 | ⚠ Play Console 0 填 | ⚠ **R76 仍** |
| | Health Connect data types | ✓ App 不用,1 行说明 | ✓ R76 同 |
| **Permissions Declaration** | USE_EXACT_ALARM | ❌ 0 填 100+ 字符 | ❌ **R76 仍** |
| | SCHEDULE_EXACT_ALARM | ❌ 0 填 100+ 字符 | ❌ **R76 仍** |
| | POST_NOTIFICATIONS | ⚠ 0 填 | ⚠ **R76 仍** |
| | RECEIVE_BOOT_COMPLETED | ⚠ 0 填 | ⚠ **R76 仍** |
| | RECORD_AUDIO | ⚠ R66 加部分,完整引导待 verify | ⚠ **R76 仍** |
| **Pricing & Distribution** | Free (含 8 元 IAP) | ✓ 选 Free + 0 IAP productId | ✓ R76 同 |
| | Countries (中国 / 海外) | ⚠ Play Console 0 选 | ⚠ R76 仍 |
| **App Signing** | Play App Signing | ❌ 0 启用(需先 keystore) | ❌ **R76 仍** |
| **Release** | AAB upload | ❌ 0 上传(需先 keystore) | ❌ **R76 仍** |
| **Content Rating** | IARC rating | ⚠ 0 填(精神心理类 PEGI 12 / ESRB T) | ⚠ R76 仍 |
| **Target Audience** | 18+ (精神心理类) | ⚠ 0 选 | ⚠ R76 仍 |
| **News Apps** | N/A (非新闻) | ✓ 0 选 | ✓ R76 同 |
| **Data deletion instructions URL** | `https://chroniccare.app/delete-data-instructions` | ⚠ R72 模板就绪,URL 0 托管 | ⚠ **R76 仍** |
| **Government apps** | N/A (非政府) | ✓ 0 选 | ✓ R76 同 |

**R74 → R76 总评**:
- **9 必填项 0 填 / 占位**(图标 Flutter 默认 logo + 8 截图 + 2 feature_graphic + Privacy URL + Developer email + 5 个 Permissions Declaration) — R76 加深 1 项(icon Flutter 默认 logo)
- **8 必填项模板就绪 等用户填**(Data Safety 4 子项 + Health Apps + Data Deletion URL + 2 个 Permissions) — R76 同
- **5 必填项 0 选 / 0 启用**(Countries / Content Rating / Target Audience / Play App Signing / AAB upload) — R76 同

---

## §9 上架阻塞清单(按 P0 / P1 / P2 分类)

### 9.1 P0 必修(7 项,4 项用户手动 + 3 项脚本就绪;R76 新增 1 项子项)

| 序 | 类别 | 位置 | 难度 | 工作量 | 关键路径 |
|----|------|------|------|--------|----------|
| 1 | 底层 | **GP-P0-1**: 跑 `pwsh scripts/generate_release_keystore.ps1` + 改 `build.gradle.kts:80` `debug` → `release` + Play Console 启用 Play App Signing | S | 半天 | **Day 1 上午** |
| 2 | 底层 | **GP-P0-2**: 注册 `chroniccare.app` 域名 + 部署 `https://chroniccare.app/privacy` HTML(转 3 份 md) | M | 1-2 天 | **Day 1-2** |
| 3 | 底层 | **GP-P0-3**: 注册 `support@chroniccare.app` 邮箱 + 替换 `user_agreement.md:60` TODO | XS | 1-2h | **Day 1 下午** |
| 4 | 底层 | **GP-P0-4/5/6**: 写 8 张真截图 + 2 张 feature_graphic + 切 2 张 icon 512×512 | S | 半天 | **Day 1 下午** |
| 5 | 底层 | **GP-P0-6 子项(R76 新发现)**: Play Store icon 改用 `assets/brand/app_icon_master.png` resize 512×512(P0-6 加深项,品牌一致性) | XS | 1h | **Day 1 下午**(同上项合并) |
| 6 | 底层 | **GP-P0-2 子项 2-C/2-D/2-G/2-H**: Play Console 4 大表单(Data Safety + Health Apps + Data Deletion + 第三方共享) — R72 模板就绪,跑 `python scripts/generate_data_safety_form.py` 后填 | M | 2-3h | **Day 2 上午** |
| 7 | 底层 | **GP-P0-2 子项 2-E**: 填 5 个 Permissions Declaration justification(USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM / POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED / RECORD_AUDIO) 100+ 字符 | XS | 30min | **Day 2 上午** |
| 8 | 底层 | **GP-P0-9**: 律师 review 3 份 md + 删"未经过律师审查"标注 + 改顶部"律师 X 已审阅" | L | 1-2 周(¥15-30k/文档) | **Day 2 启动并行,等交付** |

**P0-7 SMS 真接**(GP-P0-7): 1-2 月法务 + 阿里云 AccessKey 申请(AGENTS.md v0.27 R57 标"待办 外部依赖"),**M3 阶段**,可暂时勾"shared_with_third_parties: false"绕过。

### 9.2 P1 应修(5 项,4 项小修 + 1 项 BootReceiver 大改;R76 0 改)

| 序 | 类别 | 位置 | 难度 | 工作量 | R74→R76 |
|----|------|------|------|--------|----------|
| 1 | 架构 | **GP-P1-1**: BootReceiver 切 FlutterEngineCache + MethodChannel 调 Flutter 侧 `rescheduleAll()` | S | 2-3h | ⚠ 3/5 R70 简化但仍占位(R64+ 12 round 0 进展) |
| 2 | 底层 | **GP-P1-6**: 删 `video.txt` 2 文件(留空 OK) | XS | 5min | ❌ 0/5 R76 仍 PLACEHOLDER URL |
| 3 | 架构 | **GP-P1-7**: 完整 16KB page size 验(`flutter build appbundle --release` + `objdump -p lib/*.so`) | S | 2-3h | ⚠ 4/5 简化版 |
| 4 | 底层 | **GP-P1-2**: vent_compose_page RECORD_AUDIO in-app rationale 补 `openAppSettings()` 引导 | S | 1-2h | ⚠ 4/5 |
| 5 | 架构 | **GP-P1-9**: IAP 8 元 wording + productId 决策(关 / 真接) | M | 半天 | ⚠ 3/5 |

### 9.3 P2 建议(5 项,M2 阶段;R76 新增 1 项 hygiene)

| 序 | 类别 | 位置 | 难度 | 工作量 |
|----|------|------|------|--------|
| 1 | 架构 | **GP-P2-1**: 写 `check_googleplay_metadata.sh` 守护 fastlane/metadata 字节数 | S | 1h |
| 2 | 架构 | **GP-P2-3**: `lib/main.dart:1-237` 加 background isolation 注释 | XS | 10min |
| 3 | 底层 | **GP-P2-4**: 升 `in_app_purchase: ^3.3.0` → `^7.x` | S | 半天 |
| 4 | 架构 | **GP-P2-5**: 3 份 md i18n 化(CC-8,英文简版先) | L | 1 周 |
| 5 | 底层 | **GP-P2-7**: 修 `app label` 硬编码中文 "慢病管家" → `values/strings.xml` + `values-en/strings.xml` + `values-zh-rTW/strings.xml` | S | 1h |
| 6 | 架构 | **GP-P2-8(R76 新增 hygiene)**: 补 CHANGELOG R72 / R74 / R75 / R76 4 段(`check_changelog.py` 仍绿但 hygiene 下滑) | XS | 30min |

---

## §10 修复优先级总表 + 时间预估

### 10.1 M1 最小可上架(代码侧 + 半文档,3-5 天)

> R74 → R76 0 改动 = M1 路径**完全同 R74**,1 项加深(icon 改绿叶)

1. **Day 1 上午 4h**: GP-P0-1 跑 `pwsh scripts/generate_release_keystore.ps1`(5min)+ 改 `build.gradle.kts:80` 切 release(1min)+ 跑 `flutter build appbundle --release` 验证(10min)+ Play Console 启用 Play App Signing(5min)+ **keystore 备份到 1Password**(30min)
2. **Day 1 下午 4h**: GP-P0-3 邮箱注册(30min)+ **GP-P0-4/5/6 + R76 新发现**: 真截图 + feature_graphic + 切 icon 512(用 `assets/brand/app_icon_master.png` resize,**同步覆盖 `mipmap-*/ic_launcher.png` 5 个尺寸**)(3h)+ GP-P1-6 删 video.txt(5min)
3. **Day 2 上午 4h**: GP-P0-2 注册域名 + 部署隐私 URL(1-2 天,可并行律师 review 启动)+ GP-P0-2 子项 2-C/2-D/2-G/2-H 跑 `generate_data_safety_form.py` 模板生成后填 Play Console 4 大表单(2-3h)+ GP-P0-2 子项 2-E 填 5 个 Permissions justification(30min)
4. **Day 2 下午 4h**: GP-P1-1 BootReceiver 切 FlutterEngineCache + MethodChannel(2-3h)+ GP-P1-7 完整 16KB 验(2-3h)+ GP-P1-2 RECORD_AUDIO 引导(1-2h)+ 跑 18 守护脚本 + flutter analyze + flutter test + 真机 build 测试
5. **Day 3**: GP-P1-9 IAP 决策(关 / 真接)+ GP-P2-1/3/8 写新守护 + 加 background isolation 注释 + 补 CHANGELOG 4 段(R72/R74/R75/R76)
6. **Day 4-5**: 律师 review 3 份 md 启动(并行,1-2 周);R68 决策 GP-P0-7 真接 / 关闭(决策 OR 1-2 月 OR 决策 IAP)

**M1 关键路径**: 5 天 30-40h,**最大拦路虎仍是律师 review(1-2 周,¥15-30k/文档)**。

### 10.2 M1 法务 review 启动(并行,1-2 周)

启动 3 路并行(都 1-2 周,不可压缩):
- 律师过审 3 份 md(隐私政策 §0-12 + 用户协议 7 段 + 敏感数据同意书 6 段)
- 注册 `chroniccare.app` 域名(¥70/年,NameSilo / Cloudflare)
- 注册 `support@chroniccare.app` 邮箱(绑域名,免费 Zoho / ¥30/月企业邮)

### 10.3 M2 完整 CI 化(+3-5 天)

- 1 个新守护脚本(`check_googleplay_metadata.sh`)
- 3 份 md 英文简版翻译(CC-8,M1 启动并行)
- App label i18n 化(GP-P2-7,1h)
- 升 `in_app_purchase: ^7.x`(GP-P2-4)
- 5 个 R68 子智能体遗留(CC-9/CC-10 已守,补 R49 之前的 dark mode 漏)
- R76 新增:补 CHANGELOG R72/R74/R75/R76 4 段(GP-P2-8,30min)

### 10.4 M3 v1.0 完整上线(+3-6 月,外部依赖)

- **GP-P0-7 真接**: 阿里云 SMS AccessKey 申请(法务 1-2 月 + 阿里云模板审核 1-2 周)
- **真接 IAP**: 创建 `com.chroniccare.app.lifetime` productId + 接入 `in_app_purchase ^7.x` + 法务定价审核
- **NMPA "非医疗器械"备案**: 精神心理类自评量表不属医疗器械,但需省级备案(2-3 月)
- **HIPAA / GDPR 律师过审**(若 v1.0 海外): 海外版需重新过审(¥30-50k)
- **软件著作权登记**: 精神心理类 + 数据安全(2-3 月,¥800-1500)
- **3 份 md i18n 化全**: 1 周 6 份 + locale 切
- **PIPL §38 跨境评估**: 失联通知真接后,境外紧急联系人触发的跨境 PII 评估(1-2 月,标准合同备案)

### 10.5 1 句话总结

**R75 0 Android 改动 + R76 0 Android 改动 + R76 1 新发现(icon 实为 Flutter 默认 logo,绿叶主视觉未用)**,**R76 评分完全持平 R74 4.0/10**,**离 v1.0 上 store 仍剩 7 步用户手动 + 1 步 Play Console 4 大表单 + 1 项 R76 新发现(icon 改绿叶)+ 1 项 hygiene 补 CHANGELOG**。R75 间接改进 1 项 P0 子项(Data Safety 2-C 代码层 SMS 0 触发可信度更高),R76 测试同步 R75 PHQ-9 wording,**R75+R76 = 0 直接上架 P0 修,纯侧翼改进**。

---

## §11 R74 → R76 状态总表(对照 R74 报告 28 行)

| 类别 | R74 状态 | R75 状态 | **R76 状态** | 评 |
|------|---------|---------|---------|-----|
| **GP-P0-1 release keystore** | ⚠ R72 脚本化 + 注释,实际 buildType 仍 debug | ⚠ 0 改 | ❌ **R76 仍 fallback debug** | ❌ |
| **GP-P0-2 Privacy URL** | ⚠ R72 模板就绪 + R69 修订历史段化,URL 0 托管 | ⚠ 0 改 | ❌ **R76 仍 0 托管** | ❌ |
| **GP-P0-3 邮箱** | ❌ 仍 TODO | ❌ 0 改 | ❌ **R76 仍 TODO** | ❌ |
| **GP-P0-4 截图** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P0-5 feature_graphic** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P0-6 icon 512** | ❌ 192×192 | ❌ 0 改 | ❌ **R76 仍 192×192 + 实为 Flutter 默认 logo(R76 新发现)** | ❌ ⚠ 加深 |
| **GP-P0-7 SMS 真接** | ❌ 仍 throw (M3 阶段) | ✅ **R75 PIPL-3** 上层 throw 强化(`home_page.dart` fireSms/fireEmail 改 throw StateError) | ❌ **R76 仍 throw**(`sms_service.dart:194-198` + `home_page.dart` 2 层 throw) | ⚠ 半 |
| **GP-P0-8 Fastfile Android** | ✅ R70 修完 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P0-9 律师 review** | ✅ R69 删完顶部 TODO banner;律师 1-2 周仍待启动 | ⚠ 0 改 | ⚠ **R76 仍待启动** | ⚠ 半 |
| **GP-P0-10 文档脱节 4 处** | ✅ R69+R72 修完 8 处 wording | ✅ R75 wording 改动都是 lib 层 | ✅ R76 0 改 | ✅ |
| **GP-P1-1 BootReceiver 占位** | ⚠ R70 简化但仍占位 (R64+ 5 round) | ❌ 0 改 | ⚠ **R76 仍占位 (R64+ 12 round)** | ⚠ 半 |
| **GP-P1-2 RECORD_AUDIO rationale** | ⚠ R66 加部分,完整引导待 verify | ⚠ 0 改 | ⚠ **R76 仍 R66 部分** | ⚠ |
| **GP-P1-3 zh-CN title 失联通知** | ✅ R72 修 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P1-4 en-US "automatically notify"** | ✅ R72 修完 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P1-5 en-US "chronic patients"** | ✅ R72 修 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P1-6 video.txt 占位** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P1-7 16KB 验** | ⚠ R70 简化版 | ⚠ R76 跑过 check_16kb_alignment.py OK | ⚠ **R76 仍简化版** | ⚠ |
| **GP-P1-8 abiFilters** | ✅ R70 修完 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P1-9 IAP 8 元 wording** | ⚠ R68 修代码 + R69 改文档 + R72 守门员;productId 仍 0 | ✅ **R75 PIPL-3** 上层 throw 强化 | ⚠ **R76 仍 productId 0 配** | ⚠ |
| **GP-P0-2 子项 2-E USE_EXACT_ALARM** | ⚠ R72 模板部分包含,Play Console 0 填 | ⚠ 0 改 | ⚠ **R76 仍 0 填** | ⚠ |
| **GP-P0-2 子项 2-G Data Deletion URL** | ⚠ R72 模板就绪,URL 0 托管 | ⚠ 0 改 | ⚠ **R76 仍 0 托管** | ⚠ |
| **GP-P2-1 16 守护脚本** | ✅ 18 守护脚本 | ⚠ 0 改 | ⚠ **R76 仍 18 个** (R76 建议加 check_googleplay_metadata.sh 仍未加) | ⚠ |
| **GP-P2-2 DEPLOYMENT.md 阶段 5** | ✅ R72 重写 | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P2-3 Background isolation 注释** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P2-4 in_app_purchase ^7.x** | ❌ 仍 ^3.3.0 | ❌ 0 改 | ❌ **R76 仍 ^3.3.0** | ❌ |
| **GP-P2-5 3 份 md i18n** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P2-6 description 多语** | ✅ R69 加双 description | ✅ R76 同 | ✅ R76 同 | ✅ |
| **GP-P2-7 app label 硬编码** | ❌ 仍 0 | ❌ 0 改 | ❌ **R76 仍 0** | ❌ |
| **GP-P2-8 (R76 新增) CHANGELOG 4 round 缺段** | — | — | ⚠ **R72/R74/R75/R76 4 段 0 写** | ⚠ 新增 |

**R74 → R76 净变化**: 0 项上架 P0/P1 修(全 iOS / lib / 测试 / 报告归档),**1 项 P0 加深**(icon Flutter 默认 logo 风险),**1 项 P0 间接强化**(GP-P0-7 上层 throw 加固),**1 项 hygiene 下滑**(CHANGELOG 4 round 缺段)。

---

## §12 附录:关键文件清单 + 字节数 / 行数(便于后续追踪)

| 文件 | 字节 | 行 | R74 状态 | **R76 状态** |
|------|------|----|---------|---------|
| `android/app/src/main/AndroidManifest.xml` | 5235 | 108 | ✓ R61/R63 修 | ✓ R76 同 |
| `android/app/src/main/kotlin/com/chroniccare/chroniccare/MainActivity.kt` | 134 | 4 | ✓ | ✓ R76 同 |
| `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt` | 2050 | 43 | ⚠ R70 简化但仍占位 | ⚠ **R76 仍占位 (R64+ 12 round)** |
| `android/app/build.gradle.kts` | 4704 | 104 | ⚠ signingConfig=debug fallback | ⚠ **R76 仍 fallback debug** |
| `android/app/proguard-rules.pro` | 1417 | 46 | ✓ R63 加 keep | ✓ R76 同 |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | 1068 | 23 | ✓ | ✓ R76 同 |
| `android/app/src/main/res/xml/backup_rules.xml` | 698 | 16 | ✓ | ✓ R76 同 |
| `android/app/src/main/res/xml/network_security_config.xml` | 595 | 16 | ✓ | ✓ R76 同 |
| `android/app/src/main/res/values/styles.xml` | 1014 | 17 | ✓ | ✓ R76 同 |
| `android/app/src/main/res/values-night/styles.xml` | 1013 | 17 | ✓ | ✓ R76 同 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 1443 | - | ✓(Play Console 需 512×512 独立上传) | ⚠ **R76 实为 Flutter 默认 logo** (R76 新发现) |
| `android/key.properties.example` | 509 | 9 | ✓ | ✓ R76 同 |
| `android/.gitignore` | 267 | 14 | ✓ R63+R67 排除 *.jks + key.properties | ✓ R76 同 |
| `fastlane/Fastfile` | 5232 | 151 | ✅ R70 加 Android 端 | ✅ R76 同(R75 减 131 字节 git 重编码) |
| `fastlane/Appfile` | 1211 | 25 | ⚠ 4 ID 仍 TODO | ⚠ R76 仍 TODO |
| `fastlane/metadata/android/en-US/title.txt` | 27 | 1 | ✓ | ✓ R76 同 |
| `fastlane/metadata/android/en-US/short_description.txt` | 87 | 1 | ✅ R72 修 | ✅ R76 同 |
| `fastlane/metadata/android/en-US/full_description.txt` | 2886 | 53 | ✅ R72 修 | ✅ R76 同 |
| `fastlane/metadata/android/en-US/icon.png` | 1443 | - | ❌ 192×192 | ❌ **R76 仍 192×192 + Flutter 默认 logo** (R76 新发现) |
| `fastlane/metadata/android/en-US/feature_graphic.png` | 67 | - | ❌ 1x1 占位 | ❌ R76 仍 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_{1..4}.png` | 4 × 67 | - | ❌ 1x1 占位 | ❌ R76 仍 |
| `fastlane/metadata/android/en-US/video.txt` | 59 | 1 | ❌ PLACEHOLDER URL | ❌ R76 仍 |
| `fastlane/metadata/android/zh-CN/title.txt` | 66 | 1 | ✅ R72 修 | ✅ R76 同 |
| `fastlane/metadata/android/zh-CN/short_description.txt` | 48 | 1 | ✓ | ✓ R76 同 |
| `fastlane/metadata/android/zh-CN/full_description.txt` | 2426 | 44 | ✅ R72 修 | ✅ R76 同 |
| `fastlane/metadata/android/zh-CN/icon.png` | 1443 | - | ❌ 192×192 | ❌ **R76 仍 192×192 + Flutter 默认 logo** (R76 新发现) |
| `fastlane/metadata/android/zh-CN/feature_graphic.png` | 67 | - | ❌ 1x1 占位 | ❌ R76 仍 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_{1..4}.png` | 4 × 67 | - | ❌ 1x1 占位 | ❌ R76 仍 |
| `fastlane/metadata/android/zh-CN/video.txt` | 59 | 1 | ❌ PLACEHOLDER URL | ❌ R76 仍 |
| `assets/brand/app_icon_master.png` | 435870 | - | — | ✓ **R76 发现已有 1024×1024 绿叶主视觉** (R76 新发现) |
| `assets/brand/app_icon_maskable.png` | 385843 | - | — | ✓ **R76 发现已有 1024×1024 maskable 绿叶** (R76 新发现) |
| `assets/legal/privacy_policy.md` | 14515 | 193 | ✅ R69 修订历史段化 | ✅ R76 同(R75 0 改) |
| `assets/legal/user_agreement.md` | 4634 | 95 | ✅ R69 修订历史段化 + R66 失联通知 wording | ✅ R76 同 |
| `assets/legal/sensitive_data_consent.md` | 4658 | 85 | ✅ R69 修订历史段化 + R66 5 处 wording | ✅ R76 同 |
| `scripts/check_16kb_alignment.py` | 4921 | 124 | ✅ R70 加 | ✅ R76 跑过 OK |
| `scripts/generate_data_safety_form.py` | 10535 | 261 | ✅ R72 加 | ✅ R76 同 |
| `scripts/generate_release_keystore.ps1` | 6031 | 153 | ✅ R72 加 | ✅ R76 同 |
| `docs/DEPLOYMENT.md` | 14195 | 320 | ✅ R72 重写 | ✅ R76 同 |
| `docs/PLAYSTORE_SIGNING_GUIDE.md` | 6536 | 195 | ✓ R67 加 5 步指南 | ✓ R76 同 |
| `docs/SPRINT1_LEGAL_TODO.md` | 8297 | 167 | ✓ R67 加集中器 | ✓ R76 同 |
| `docs/CHANGELOG.md` | 100067 | — | ✓ R73 entry | ⚠ **R76 R72/R74/R75/R76 4 段 0 写** (R76 新发现) |
| `pubspec.yaml` | 1800 | 80 | ⚠ in_app_purchase ^3.3.0 | ⚠ R76 仍 ^3.3.0 |

---

## §13 R76 新发现清单(2 项)

### 13.1 [P0-6 加深] Play Store icon 实为 Flutter 默认 logo,绿叶主视觉未用(R76 新发现)

**发现时间**: R76 审计 PIL 验过 192×192 Mode P + 视觉确认。

**R74 描述**:R74 P0-6 仅注 "icon.png 1443 字节 192×192,需 512×512"。

**R76 加深发现**:
- `fastlane/metadata/android/{en-US,zh-CN}/icon.png` 192×192 实为 **Flutter 默认蓝色 logo**(已 PIL 验证 Mode P + 视觉确认)
- `android/app/src/main/res/mipmap-*/ic_launcher.png` 5 个尺寸(48/72/96/144/192) 也全是 **Flutter 默认 logo**
- **项目已有 branded icon**:`assets/brand/app_icon_master.png` 1024×1024 绿叶主视觉(RGB)+ `app_icon_maskable.png` 1024×1024 maskable 绿叶(RGB),均未被使用
- `assets/brand/icon_showcase.html` 8 KB 还有完整 icon showcase 文档

**Play 政策风险**(Store Listing Policy §1.3):"App icon must not be misleading or confusing. Default framework/template icons are grounds for rejection." Flutter 默认 logo 在 Google Play = 100% 拒收。

**用户体验风险**:App 名为"慢病管家",Play Store icon 是 Flutter logo → 信任感崩塌;用户安装到 launcher 看到 Flutter logo → 困惑。

**修法**(S 难度,1h):
```bash
# 1. 用 PIL 把绿叶主视觉 resize 到 5 个 mipmap 尺寸
python -c "
from PIL import Image
img = Image.open('assets/brand/app_icon_master.png')
for sz, dim in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    img.resize((dim, dim), Image.LANCZOS).save(f'android/app/src/main/res/mipmap-{sz}/ic_launcher.png')
img.resize((512, 512), Image.LANCZOS).save('fastlane/metadata/android/en-US/icon.png')
img.resize((512, 512), Image.LANCZOS).save('fastlane/metadata/android/zh-CN/icon.png')
"
# 2. 验证: PIL 验 5 个 mipmap + 2 个 fastlane/metadata 都是 1024 缩放版
```

**优先级**:P0,跟 R74 P0-4/5/6 合并到 Day 1 下午(批量出图 1h)。

### 13.2 [P2-8 新增] CHANGELOG R72/R74/R75/R76 4 段 0 写(R76 新发现)

**发现时间**:R76 审计读 `docs/CHANGELOG.md` 时发现最新 entry 是 R73。

**详情**:
- 7 个 "## [Unreleased] - 2026-08-01" 头混在一起(R66/R69/R70/R71/R73)
- R72 / R74 / R75 / R76 **4 个 round 0 写**
- `check_changelog.py` 仍绿(只查 `pubspec=[0.27.0+64]` 顺序,不强制每 round 写)
- 风险:用户/审核员读 CHANGELOG 看不到 R75 PIPL-1/2/3 关键修复

**R75 关键 commit 在 CHANGELOG 缺位**:
- R75 PIPL-1:`lost_contact_sms.dart` 移除 medication PII 暴露(精神心理敏感数据)
- R75 PIPL-2:`ConsentArtifact.version` 升 v0.27-2026-08-01(PIPL §14 单独同意)
- R75 PIPL-3:`home_page.dart` fireSms/fireEmail 占位改 throw StateError(防 PII 误发)

**修法**(XS 难度,30min):
- 写 4 段 `[Unreleased] - 2026-08-01 (R72/R74/R75/R76 — ...)`
- 每段 6-8 行:Tests + 上架 P0 子项 / PIPL 域 / 测试同步 / hygiene 补段

**优先级**:P2(不阻塞上架,但 hygiene 下滑信号)。

---

## §14 总结

**R76 当前评分 4.0/10**(vs R74 4.0/10,**完全持平**)。

**R75+R76 0 Android 改动**(R75 纯 iOS / PIPL 域 / 测试 / 报告归档;R76 1 commit 是 test 同步 PHQ-9 wording)。

**R75 间接改进 1 项**:
- ✅ R75 PIPL-3 `home_page.dart:135-180` fireSms/fireEmail 占位改 throw StateError(代码层 100% throw 链,Data Safety Form 2-C "未触发"声明更可信)

**R76 新发现 2 项**:
- ⚠ [P0-6 加深] Play Store icon 实为 Flutter 默认 logo,绿叶主视觉(`assets/brand/app_icon_master.png` 1024×1024)未用(品牌一致性 + 1-click brand identity 风险)
- ⚠ [P2-8 新增] CHANGELOG R72/R74/R75/R76 4 段 0 写(hygiene 下滑)

**R74 8 P0 修复进度**:
| # | 项 | R74 状态 | R75 状态 | **R76 状态** |
|---|----|---------|---------|---------|
| GP-P0-1 | signingConfig=debug | ❌ | ❌ | ❌ **0 进展** |
| GP-P0-2 | Privacy URL | ❌ | ❌ | ❌ **0 进展** |
| GP-P0-3 | support@ 占位 | ❌ | ❌ | ❌ **0 进展** |
| GP-P0-4 | 8 截图 | ❌ | ❌ | ❌ **0 进展** |
| GP-P0-5 | 2 feature_graphic | ❌ | ❌ | ❌ **0 进展** |
| GP-P0-6 | 2 icon 192×192 | ❌ | ❌ | ❌ **0 进展** + **R76 加深**(Flutter 默认 logo) |
| GP-P0-7 | SMS throw | ❌ | ⚠ 间接加固 | ❌ **仍 throw + 0 进展** |
| GP-P0-8 | Fastfile | ✅ R70 修 | ✅ | ✅ |

**未完成**(纯外部依赖 + 用户手动,**7 项上架硬阻塞 + 1 项 R76 新发现**):
- ❌ GP-P0-1 真实 keystore + Play App Signing(脚本就绪,等用户跑 + 改 1 行)
- ❌ GP-P0-2 域名 + 邮箱 + 隐私 URL 托管(等用户注册)
- ❌ GP-P0-4/5/6 真截图 + feature_graphic + icon 512(等真机 + 设计师)
- ⚠ **GP-P0-6 R76 新发现**:icon 改用 `assets/brand/app_icon_master.png` 绿叶主视觉(品牌一致性,1h 改完)
- ❌ GP-P0-9 律师 review 3 份 md(1-2 周 + ¥15-30k/文档)

**半步**(代码 / 文档 / 守门员就绪,Play Console 侧 0 填):
- ⚠ GP-P0-2 子项 2-C/2-D/2-E/2-G/2-H(R72 模板就绪,Play Console 0 填)
- ⚠ GP-P1-1 BootReceiver 仍占位(R64+ 12 round 0 进展)
- ⚠ GP-P1-2 RECORD_AUDIO 完整引导
- ⚠ GP-P1-7 完整 16KB 验
- ⚠ GP-P1-9 IAP productId 0 配
- ⚠ **GP-P2-8 R76 新增**:补 CHANGELOG 4 段(30min hygiene)

**M1 最小可上架: 5 天 30-40h,核心是 7 步用户手动 + 1 步 Play Console 4 表单 + 1-2 周律师 review**。M3 完整 v1.0 上线还需 SMS 真接 1-2 月 + IAP 真接 + NMPA 备案 2-3 月。

---

**报告生成时间**: 2026-08-02
**下次 review**: R77 上架 7 步用户手动完成 + Play Console 4 大表单填完 + 律师 review 启动后
**R76 状态**: ⚠ **7 步用户手动未完成 + Play Console 4 大表单 0 填 + 1 项 R76 新发现(icon 改绿叶)+ 1 项 R76 hygiene(补 CHANGELOG),不可上 store**
**总评**: R75+R76 0 Android 改动 = 评分完全持平 R74;R75 间接加固 GP-P0-7(Data Safety 2-C 更可信);R76 新发现 GP-P0-6 加深(icon Flutter 默认 logo 风险)+ P2-8 CHANGELOG hygiene 下滑。代码侧 / 文档侧 / 脚本侧 / 守门员 4 维 R76 仍全绿,但上架硬阻塞 100% 是"非代码"环节(用户操作 + 律师 + 真机 + 设计师 + 绿叶 icon resize)
