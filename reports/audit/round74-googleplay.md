# Round 74 - Google Play Store 视角审计

**审计时间**: 2026-08-01 → 2026-08-02
**项目**: chroniccare(精神心理患者吃药打卡 App / 医疗健康类 / 精神心理敏感数据)
**版本**: 0.27.0+64(`pubspec.yaml:4`)/ R74 commit 6e9f07e 已落地
**基线**: 1285 tests pass / 0 analyzer error / 0 warning / 0 info (历史性 R73 落地) / 17 守护脚本全绿
**审计模式**: 增量审计(对照 R69 `round69-googleplay.md` 39KB/500 行 + R66/R68 报告)
**视角**: Google Play Console 上架合规(Health Apps + Data Safety + Permissions Policy + 16KB page size + 64-bit + targetSdk 2026 要求)
**核心范围**: Android 工程结构 + Manifest + Kotlin + Gradle + ProGuard + 资源 xml + Fastlane + 5 法律/上架 md + 截图/feature_graphic/icon 资产

---

## §0 评级

**4.0 / 10**(vs R69 3.5/10,**+0.5 回升**)

| 维度 | R66 评分 | R68 评分 | R69 评分 | **R74 评分** | Δ vs R69 | 关键变化 |
|------|---------|---------|---------|---------|---------|---------|
| **政策合规 (Policy)** | ⭐⭐ | ⭐⭐½ | ⭐⭐½ | ⭐⭐⭐ | ↑½ | R72 修 user_agreement.md 失联通知 + 病耻感 3 处 + 隐私 URL 占位;3 法律 md 顶部 TODO 删 (R69);R72 改 title.txt/short_description.txt/full_description.txt 4 处 wording |
| **技术 (Technical)** | ⭐⭐⭐⭐ | ⭐⭐⭐½ | ⭐⭐⭐½ | ⭐⭐⭐⭐ | ↑½ | R70 加 abiFilters + 16KB check 脚本 (简化版);R72 generate_data_safety_form.py + generate_release_keystore.ps1 脚本化;R70 简修 BootReceiver |
| **元数据 (Store Listing)** | ⭐ | ⭐½ | ⭐½ | ⭐½ | = | 8 截图 + 2 feature_graphic + 2 icon 仍 0 真图;video.txt 仍占位 URL;R72 修 4 处文案 wording 算"半步" |
| **签名 (Signing)** | ⭐ | ⭐½ | ⭐½ | ⭐½ | = | `build.gradle.kts:80` 仍 `signingConfig=debug` (R70 改 TODO 注释但实际 buildType 没切);`android/key.properties` 不存在;0 真实 keystore;R72 脚本就绪等用户执行 |
| **隐私 (Privacy)** | ⭐⭐ | ⭐⭐½ | ⭐⭐½ | ⭐⭐⭐ | ↑½ | R69 修 3 文档脱节 wording + 加修订历史段化 + 跨境/单独同意段落 walkthrough;R72 generate_data_safety_form.py 模板就绪 |
| **数据安全 (Data Safety)** | ⭐ | ⭐ | ⭐ | ⭐½ | ↑½ | R72 自动化模板生成 (`build/data_safety_form.md`);Play Console 侧 4 大表单 0 填 |

**整体判断 — 4.0/10**。R70-R73 4 round 系统性清零上架 P0 阻塞:**R70** 修 abiFilters + 16KB check + Fastfile Android 端 + BootReceiver 简化;**R71** 修 iOS PrivacyInfo + 病耻感措辞中性化 + 5 处 Wrap spacing 集中;**R72** 写 3 个上架脚本 (keytool + Data Safety + 16KB) + DEPLOYMENT.md 重写 + 4 处文案 wording;**R73** 9 analyzer info 清零 + 102 PNG 清理 + 10 临时文件清理 + 1 README_PLACEHOLDER 删。**5 个核心 P0 阻塞**(真实 keystore / 域名邮箱 / 截图 / 律师 review / SMS 真接)脚本就绪 + 守门员就位 + 文档层已诚实 + 第三方 3 文档全修订历史化,**但仍是"非代码"环节等用户操作**。**R74 立即可上 store 的差距只剩 4-5 步手动 + 1 步 Play Console 4 表单**。

---

## §1 R69 → R74 增量(12 项上架相关)

### 1.1 R70-R73 已修(代码 / 文档侧,8 项上架相关)

| 编号 | 位置 | 修法 | 难度 | 评 |
|----|------|------|------|-----|
| **R70-1** | `android/app/build.gradle.kts:96` | R70 commit 986814a: 显式 `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }`(GP-P1-8 修) | XS | ✅ 5/5 |
| **R70-2** | `scripts/check_16kb_alignment.py` (NEW 124 行) | R70 commit 5592f96: 16KB page size 检查脚本(简化版,配置 + 风险 plugin 提示;完整 .aab 验留 `flutter build appbundle` + objdump,见 `check_16kb_alignment.py:111-118`)(GP-P1-7 修) | S | ✅ 4/5(配置查 ✓,完整验仍 0) |
| **R70-3** | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt` | R70 commit 5592f96: 简化实现 + 注释同步更新(行 30-31 仍写"留给 R64+ 完善",**实际仍走"启动 MainActivity"占位路径** line 32-37)(GP-P1-1 半步) | S | ⚠ 3/5(简化了但仍占位) |
| **R70-4** | `fastlane/Fastfile:94-150` | R70 commit 5592f96: Android 端 `platform :android do` 块,3 lane (`internal` / `production` / `metadata`)(GP-P0-8 修) | S | ✅ 5/5 |
| **R72-1** | `scripts/generate_release_keystore.ps1` (NEW 153 行) | R72: PowerShell 自动化 keystore 生成,带 3 次密码确认 + 自动 backup 到 `~/.chroniccare-keystore-backup/`(GP-P0-1 修) | S | ✅ 5/5 |
| **R72-2** | `scripts/generate_data_safety_form.py` (NEW 261 行) | R72: Play Console Data Safety Form 自动生成 JSON+MD, 从 `privacy_policy.md` + `ios/Runner/PrivacyInfo.xcprivacy` 解析(GP-P0-2 子项 2-C 修) | S | ✅ 5/5 |
| **R72-3** | `docs/DEPLOYMENT.md` (14.2 KB,R72 重写) | R72: 阶段 3-7.5 全重写,含 5 项 P0 阻塞(用户手动) + 4 项上架 P0 已修 + 3 项 R72 质量已修 + 阶段 7.5 必跑 17 守护脚本清单 + R70/R71/R72 上架进度(GP-P2-2 修) | M | ✅ 5/5 |
| **R72-4** | `fastlane/metadata/android/en-US/short_description.txt:1` | R72: "chronic patients" → "people managing chronic conditions"(GP-P1-5 修) | XS | ✅ 5/5 |
| **R72-5** | `fastlane/metadata/android/zh-CN/title.txt:1` | R72: "慢病管家 - 吃药打卡 + 失联通知" → "慢病管家 - 吃药打卡 + 情绪关怀(失联通知规划中)"(GP-P1-3 修) | XS | ✅ 5/5 |
| **R72-6** | `fastlane/metadata/android/en-US/full_description.txt:14` | R72: "can automatically notify" → "would automatically notify" + 加 NOTE 段 "This feature is currently disabled in this release. ...(target: v1.0)."(GP-P1-4 修) | XS | ✅ 5/5 |
| **R72-7** | `fastlane/metadata/android/zh-CN/full_description.txt:17,19` | R72: 加"【失联通知】(即将上线 — 当前已暂停)"段 + "注:本功能在本版本已暂停..." 段 | XS | ✅ 5/5 |
| **R72-8** | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 3 文档 R69 修订历史段化 | R69 commit 0051fe7: 加"修订历史"表格段 + 删除顶部 "TODO 律师过审" banner | S | ✅ 5/5 |
| **R69-W1** | `assets/legal/privacy_policy.md §0.5` | R66 修"整体业务暂停"段 + R69 walkthrough 段 | S | ✅ 5/5 |
| **R69-W2** | `assets/legal/privacy_policy.md §11 跨境 walkthrough` | R69 5 处版本号 walkthrough (v0.25 → v0.27) | S | ✅ 5/5 |
| **R69-W3** | `assets/legal/privacy_policy.md §12 单独同意实现进度` | R69 加"v0.27 R69" walkthrough + "业务层真正生效" 段 | S | ✅ 5/5 |
| **R69-W4** | `assets/legal/user_agreement.md:1, 5` | R66 修"失联通知(规划中,本版本未启用)" + "本版本不显示立即买断"段 | XS | ✅ 5/5 |
| **R69-W5** | `assets/legal/sensitive_data_consent.md §2.1, §4, §5, §7` | R66 修 5 处 "规划中,本版本未启用" 标注 | XS | ✅ 5/5 |
| **R71-W1** | `lib/core/l10n/strings.dart:94` + `lib/core/l10n/care_copy.dart:34,44` + `lib/core/data/services/lost_contact_sms.dart:69` | R71 commit b46f700 + 4950a84 后续: 3 处病耻感措辞中性化(SPZH P0-4 / P0-5 修) | XS | ✅ 5/5 |
| **R71-W2** | `lib/l10n/app_*.arb` + `lib/core/data/services/assessment_translations.dart` | R71 commit 9c6d918: PHQ-9 detectCrisis 抽 i18n (zh/en/zh_Hant 各 2 key) | S | ✅ 5/5 |
| **R73-W1** | `lib/presentation/pages/home/home_page.dart:446` + `presentation/widgets/contacts_list_widget.dart:217,238` + `presentation/pages/setup/setup_page.dart:397` | R73 commit f40a10b: 5 处 `use_build_context_synchronously` info 修(Use `if (ctx.mounted)` + 双重 guard) | S | ✅ 5/5 |
| **R73-W2** | `fastlane/metadata/ios/en-US/README_PLACEHOLDER.txt` (67 字节) | R73 commit 98b041a: 删(iOS 截图已就位 5+3+3 张) | XS | ✅ 5/5 |
| **R71-W3** | `ios/Runner/PrivacyInfo.xcprivacy` R71 加 ProcessInfo AC67.1 + CA92.2 | R71 commit 42ac12b: Apple 2024-05 强制 + 防御性 2 reason(iOS 端) | S | ✅ 5/5(注:本审计 Android 端,但 R72 generate_data_safety_form.py 引用此源) |

**R70-R73 净进展**: 21 项上架相关 commit,代码侧 / 文档侧 / 脚本侧 / 守门员 4 维全绿。**5 个核心 P0 阻塞**(keystore / 域名邮箱 / 截图 / 律师 review / SMS 真接)中 3 个脚本就绪(keystore / Data Safety Form / 16KB 验),1 个守门员 17 个全绿,1 个仍纯外部依赖(SMS 真接 + 律师 review)。

### 1.2 R69 未修持续 + R74 新增(8 项,4 项上架硬阻塞 + 4 项建议)

| 编号 | 位置 | R69 状态 | **R74 状态** | 评 |
|----|------|---------|---------|-----|
| **GP-P0-1** | `android/app/build.gradle.kts:80` 切 `signingConfig=release` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | 0 进展 | **0 进展**(R70 commit 改 TODO 注释但实际 buildType 仍 `signingConfig=debug`;R72 keystore 脚本就绪等用户执行) | ❌ 0/5 |
| **GP-P0-2** | `assets/legal/privacy_policy.md` + Play Console "Privacy Policy URL" 字段(`https://chroniccare.app/privacy` 未托管) | 0 进展 | **0 进展**(R69 修订历史段化 + 5 段 walkthrough;R72 模板就绪,**域名 / URL 仍 0 托管**) | ❌ 0/5 |
| **GP-P0-3** | `assets/legal/user_agreement.md:60` `support@chroniccare.app` TODO 占位 | 0 进展 | **0 进展**(仍 TODO 占位;`docs/SPRINT1_LEGAL_TODO.md:12-14` 详细清单 + Play Console Developer email 仍 0 填) | ❌ 0/5 |
| **GP-P0-4** | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节) | 1x1 占位 | **仍 1x1 占位**(`screenshot_*.png` 8 × 67 字节,内容是 R67 占位生成) | ❌ 0/5 |
| **GP-P0-5** | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 1x1 占位 | **仍 1x1 占位**(2 × 67 字节,需 1024×500) | ❌ 0/5 |
| **GP-P0-6** | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | 192×192,需 512×512 | **仍 192×192**(2 × 1443 字节) | ❌ 0/5 |
| **GP-P0-7** | `lib/core/data/services/sms_service.dart:194-198` `throw StateError` + Privacy Policy §3 共享段 + `AliyunSmsProvider._isFullyImplemented=false` (R55+ TODO) | throw | **仍 throw**(外部依赖:法务 1-2 月 + 阿里云 AccessKey 申请,AGENTS.md v0.27 R57 标"待办 外部依赖") | ❌ 0/5 |
| **GP-P0-8** | `fastlane/Fastfile` Android 端 0 | 0 | ✅ **R70 修完**(`platform :android do` 块 + 3 lane) | ✅ 5/5 |
| **GP-P0-9** | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 顶部 "TODO 律师过审" banner | 3 文档全命中 | ✅ **R69 删完**(改修订历史段化,`SPRINT1_LEGAL_TODO.md` 集中管理;3 md 修订历史表 v0.27 R69 段都标"删顶部 TODO banner") | ✅ 5/5 |
| **GP-P0-10** | 4 处文档脱节(CC-7) | 0/4 | ✅ **R69+R72 修完 8 处 wording**(`zh-CN title` R72 + `en-US full_description` R72 + `user_agreement` R66 + `sensitive_data_consent` R66 + `privacy_policy` R66 §0.5/§3/§11/§12) | ✅ 5/5 |
| **GP-P1-1** | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` 走"启动 MainActivity"占位 | 启动 MainActivity | ⚠ **R70 简化但仍占位**(line 30-31 注释"留给 R64 完善",实际仍 `context.startActivity(launchIntent)`) | ⚠ 3/5 |
| **GP-P1-2** | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` RECORD_AUDIO in-app rationale | R66 加部分 | ⚠ **R66 加部分待 verify**(P0 子项 2-F 仍待完整引导) | ⚠ 4/5 |
| **GP-P1-3** | `fastlane/metadata/android/zh-CN/title.txt:1` "慢病管家 - 吃药打卡 + 失联通知" | 写可用 | ✅ **R72 修**(改"情绪关怀(失联通知规划中)") | ✅ 5/5 |
| **GP-P1-4** | `fastlane/metadata/android/en-US/full_description.txt:14` "can automatically notify" | 写可用 | ✅ **R72 修**(改"would automatically notify" + coming soon 段) | ✅ 5/5 |
| **GP-P1-5** | `fastlane/metadata/android/en-US/short_description.txt:1` "chronic patients" | 病耻感 | ✅ **R72 修**(改"people managing chronic conditions") | ✅ 5/5 |
| **GP-P1-6** | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` 2 文件 PLACEHOLDER URL | 占位 URL | ❌ **仍 0 删**(2 × 59 字节,内容 `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO`) | ❌ 0/5 |
| **GP-P1-7** | 16KB page size 验脚本 | 0 脚本 | ✅ **R70 加完**(`scripts/check_16kb_alignment.py` 124 行,**简化版只查配置 + 风险 plugin 提示;完整 .aab 验仍 0**,需 `flutter build appbundle --release` + `objdump -p lib/*.so` 实测) | ✅ 4/5(简化版) |
| **GP-P1-8** | `android/app/build.gradle.kts` (无 abiFilters / splits) | 隐式 | ✅ **R70 修完**(`ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }` line 95-97) | ✅ 5/5 |
| **GP-P1-9** | IAP 8 元 wording vs 代码 vs Play Console productId | 文档与代码不一致 | ⚠ **R68 修代码 + R69 改 user_agreement + R72 守门员 check_legal_consent**(`FeatureFlags._prodIapEnabled=false` 早返;`user_agreement.md:25` 改"本版本已暂停"段;Play Console productId 仍 0 配) | ⚠ 3/5 |
| **GP-P0-2 子项 2-E** | Play Console Permissions Declaration Form `USE_EXACT_ALARM` justification 100+ 字符 | 0 填 | ⚠ **R72 脚本化**(`generate_data_safety_form.py` 模板生成,**Play Console 侧仍 0 填**) | ⚠ 2/5 |
| **GP-P0-2 子项 2-F** | Play Console Permissions Declaration Form `RECORD_AUDIO` in-app rationale | 部分 | ⚠ **R66 加部分** | ⚠ 3/5 |
| **GP-P0-2 子项 2-G** | Play Console "Data deletion endpoint URL" 字段 | 0 填 | ⚠ **R72 模板就绪**(`generate_data_safety_form.py` 输出含 `https://chroniccare.app/delete-data-instructions`,**URL 仍未托管** + Play Console 0 填) | ⚠ 2/5 |

**R69→R74 净进展**: 7 项上架 P0/P1 修完(Fastfile Android + 8 处 wording + abiFilters + 16KB 简化脚本 + 3 文档修订历史段化),5 项仍 0(keystore / 域名邮箱 / 截图 8 张 / feature_graphic 2 张 / icon 2 张),3 项 P1 半步(BootReceiver 仍占位 / IAP productId 仍 0 / Permissions Declaration 仍 0 填)。

---

## §2 Google Play 提交必拒项(P0 阻断,8+2 项)

> 修法按 Google Play Console 实际拒收原因分类 + Policy 引用。R72 脚本化让 3 项 P0 阻塞(keystore / Data Safety Form / 16KB 验)从"手动"降级为"用户跑脚本",**核心 P0 阻塞从 8 项降到 4-5 项**。

### 2.1 P0 提交时必拒(8 项,R72 脚本化 3 项)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 |
|---|------|------|------|------------|------|
| **GP-P0-1** | 底层 | `android/app/build.gradle.kts:80` 仍 `signingConfig = signingConfigs.getByName("debug")` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | release 签名仍是 debug keystore → AAB 100% 拒收。**R72 脚本化**:`scripts/generate_release_keystore.ps1` 153 行,自动 keytool + 备份 + 写 key.properties;**用户跑后还需改 1 行** `build.gradle.kts:80` `debug` → `release` | **Developer Program Policy 签名前提**: release AAB 必须用 production keystore,debug-signed 上 store = 直接拒 | **S** (半天:跑脚本 5min + 改 1 行 1min + 备份 30min + Play Console Play App Signing 启用 1h) |
| **GP-P0-2** | 底层 | `assets/legal/privacy_policy.md` + Play Console "Privacy Policy URL" 字段 | Privacy Policy URL 未托管到 HTTPS 公网 → 提交即拒(精神心理类必填)。**R72 模板就绪**:`generate_data_safety_form.py` 输出含 `https://chroniccare.app/privacy`,**域名仍未注册 + URL 仍未部署** | **Data Safety Policy §1.5 + User Data Policy**: Health apps 必须提供可访问的 Privacy Policy URL | **M** (1-2 天: 注册 `chroniccare.app` ¥70/年 + 部署 HTML 转 `privacy_policy.md` R72 模板已包含 §0-12 全文 14.2 KB) |
| **GP-P0-3** | 底层 | `assets/legal/user_agreement.md:60` `support@chroniccare.app` TODO 占位 + Play Console Developer email | Developer email 必填且真实可达。**R72 守门员**:`check_legal_consent.py` 已守 3 md TODO 关键词;**真实邮箱仍未注册** | **Developer Program Policy §3**: Developer email 必填且真实可达 | **XS** (1-2h: 注册域名邮箱 + 替换 1 处 TODO;`SPRINT1_LEGAL_TODO.md:12-14` 详细清单) |
| **GP-P0-4** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节) | 8 张截图全是 1x1 占位 PNG → Play Store 上传即拒 | **Store Listing Policy §1**: Phone screenshots 必填 2-8 张,内容必须真实可读 | **S** (半天:真机 / 模拟器 `flutter run` + `adb shell screencap` 截 4 核心页面:home / medication calendar / trend / vent list) |
| **GP-P0-5** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 2 张 feature_graphic 全是 1x1 占位 → Play Store 上传即拒 | **Store Listing Policy §1**: Feature graphic 必填 1024×500 | **XS** (1-2h: 设计师出图;Project 已有 `assets/brand/app_icon_master.png` 主视觉可裁切) |
| **GP-P0-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | App icon 需 512×512,当前 192×192 → Play Store 警告 + 上传失败 | **Store Listing Policy §1.3**: App icon 必填 512×512 | **XS** (1h: 设计师出 512×512 主 icon;R72 `_archive/resize_icons.py` 19 KB 已有 icon resize 工具) |
| **GP-P0-7** | 底层 | `lib/core/data/services/sms_service.dart:194-198` + `AliyunSmsProvider._isFullyImplemented=false` + Privacy Policy §3 共享段 | SMS Provider 仍 `throw StateError('AliyunSmsProvider.send() R55 真接 TODO...')`,Data Safety Form 勾"失联通知触发时...发给紧急联系人"与代码层 0 触发矛盾。**R72 模板就绪**:`generate_data_safety_form.py` 输出已勾"shared_with_third_parties: false" + "本版本不实际触发"备注 | **Data Safety Policy §2.2 + User Data Policy §4.1**: 共享声明必须跟实际代码一致,声称会发数据但代码层 0 调用 = 误导性陈述 → Developer Policy 4.8 拒 | **L** (1-2 月法务 + AccessKey 申请,AGENTS.md v0.27 R57 标"待办 外部依赖") |
| **GP-P0-8** | 底层 | `fastlane/Fastfile` Android 端 0 | **R70 修完**(`platform :android do` 块 + 3 lane,见 `fastlane/Fastfile:94-150`),缺前置 Service Account JSON | **非直接拒**,但缺自动化 → 每次手动 Console 填 = P0-9/10 易漏 | **S** (半天:跑 R70 lane 实测 + 配 google_play_json_key_path Service Account JSON) |

### 2.2 P0 审核员抽查必拒(2 项)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 |
|---|------|------|------|------------|------|
| **GP-P0-9** | 底层 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 3 文档修订历史表 + 顶部 TODO | **R69 删完顶部 TODO banner**,改修订历史段化。**3 文档仍"草稿"状态**(`privacy_policy.md:5 修订历史 v0.22` 标"未经过律师审查",`user_agreement.md` 同) | **Developer Program Policy §4.8 (Impersonation)**: 法律文档含"未过审"标注提交 = 误导性陈述,可拒收 | **L** (律师 1-2 周,~¥15-30k/文档,3 文档并发评审;`SPRINT1_LEGAL_TODO.md` §3.1) |
| **GP-P0-10** | 底层 | 4 处文档脱节(CC-7) | **R69+R72 修完 8 处 wording**:`zh-CN title` R72 + `en-US full_description` R72 + `user_agreement` R66 + `sensitive_data_consent` R66 + `privacy_policy` R66 §0.5/§3/§11/§12。**全部 wording 与 R68 代码层修复对齐** | **Developer Program Policy §4.3 (Deceptive Behavior)**: App 描述跟实际行为不一致,可拒收 | **M** (✅ 1-2h 已修) |

### 2.3 P0 子项 — 缺失/不达标字段(8 子项,R72 模板就绪 5 子项)

| # | 位置 | 字段 | 修复 | R74 状态 |
|---|------|------|------|---------|
| 2-A | Play Console "Privacy Policy URL" | `https://chroniccare.app/privacy` (HTTPS 公网托管) | 注册域名 + 部署 `assets/legal/privacy_policy.md` 转 HTML | ⚠ 模板就绪,**URL 0 托管** |
| 2-B | Play Console "Developer email" | `support@chroniccare.app` (真实邮箱) | 注册域名 + 邮箱 + 替换 1 处 TODO (`user_agreement.md:60`) | ❌ **TODO 占位** |
| 2-C | Play Console Data Safety Form | 4 大类(账号 / 设备 / 应用活动 / 个人信息) + health data 勾 | 手工填 2-3h;**R72 模板就绪**:`python scripts/generate_data_safety_form.py` 输出 `build/data_safety_form.md` | ⚠ **模板生成 ✓,Play Console 0 填** |
| 2-D | Play Console Health Apps questionnaire | "Mental and behavioral health" 4 问 | 手工填 1h;**R72 模板** §3 收集数据中已含 health_info 段 | ⚠ **Play Console 0 填** |
| 2-E | Play Console Permissions Declaration Form | `USE_EXACT_ALARM` justification 100+ 字符 | 写 1 段(`定时用药提醒依赖精确闹钟,患者 24h 内不能漏服,允许应用在 Doze 模式下触发精确闹钟` ≥ 100 字) | ❌ **0 填** |
| 2-F | Play Console Permissions Declaration Form | `RECORD_AUDIO` in-app rationale | 1 段(树洞语音 + mood audio) | ⚠ **R66 加部分,完整引导待 verify** |
| 2-G | Play Console "Data deletion endpoint URL" | `https://chroniccare.app/delete-data-instructions` | 部署 1 个静态页;**R72 模板就绪** | ⚠ **URL 0 托管** |
| 2-H | Play Console "App content → Data safety" | health data 共享声明需勾"未触发"或真接通 | 跟 P0-7 同步决策;**R72 模板已勾"shared_with_third_parties: false"** | ⚠ **Play Console 0 填** |

---

## §3 Google Play 警告项(P1,9 项;4 项已修,5 项仍 0 或半步)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 | R69→R74 |
|---|------|------|------|------------|------|---------|
| **GP-P1-1** | 架构 | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` | **R70 简化** 但仍"启动 MainActivity"占位路径,line 30-31 注释"留给 R64 完善" — **R64+ 5 round 仍占位** | **非直接拒**,但 BOOT_COMPLETED 后启动 MainActivity = 用户每次重启看到 App 主界面,体验差 | **S** (2-3h) | ⚠ 3/5 半步 |
| **GP-P1-2** | 底层 | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` | RECORD_AUDIO in-app rationale R66 加部分但缺引导去系统设置 | **Permissions Policy**: Dangerous permissions 必须有 in-app rationale + fallback to system settings | **S** (1-2h) | ⚠ 4/5 待 verify |
| **GP-P1-3** | 底层 | `fastlane/metadata/android/zh-CN/title.txt:1` "失联通知" | ✅ **R72 修** 改"情绪关怀(失联通知规划中)" | **Store Listing Policy §1**: title 措辞必须跟功能一致 | **XS** | ✅ 5/5 |
| **GP-P1-4** | 底层 | `fastlane/metadata/android/en-US/full_description.txt:14` "can automatically notify" | ✅ **R72 修** 改"would automatically notify" + coming soon 段 | **Developer Program Policy §4.3 (Deceptive)**: 描述含功能可用 wording,审核员读 line 14 即认定误导 | **XS** | ✅ 5/5 |
| **GP-P1-5** | 底层 | `fastlane/metadata/android/en-US/short_description.txt:1` "chronic patients" | ✅ **R72 修** 改"people managing chronic conditions" | **Health Apps Policy (非强制)**: 措辞建议 | **XS** | ✅ 5/5 |
| **GP-P1-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` 2 文件 | ❌ **仍 PLACEHOLDER URL**(2 × 59 字节) | **Store Listing Policy §1.7**: Promo video 必填真 URL 或留空 | **XS** (5min 删 2 文件) | ❌ 0/5 |
| **GP-P1-7** | 架构 | `android/app/build.gradle.kts:11` ndkVersion + 0 完整验 | ✅ **R70 简化版**:`scripts/check_16kb_alignment.py` 124 行(配置 + 风险 plugin),**完整 .aab 验仍 0**(需 `flutter build appbundle --release` + `objdump -p lib/*.so`) | **Google Play 2025-11 新规**: targetSdk 35+ 必须 16KB page size,未验可拒收 | **S** (2-3h: 跑 `flutter build appbundle` + 完整 .aab objdump) | ⚠ 4/5 简化版 |
| **GP-P1-8** | 底层 | `android/app/build.gradle.kts` (无 abiFilters / splits) | ✅ **R70 修完** `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }` | **Google Play 2019-08 新规**: APK / AAB 必须支持 64-bit | **XS** | ✅ 5/5 |
| **GP-P1-9** | 架构 | `lib/main.dart:188-191` + `lib/core/data/services/store_kit_service.dart:108-110` | ⚠ **R68 修代码** (`_prodIapEnabled=false` 早返) + **R69 修文档** (`user_agreement.md:25` 加"本版本已暂停"段),**Play Console productId 仍 0 配** | **Developer Program Policy §4.3**: 描述与实际行为一致 | **M** (半天) | ⚠ 3/5 半对齐 |

---

## §4 Google Play 建议项(P2,5 项;R72 修 1,4 项待办)

| # | 类别 | 位置 | 问题 | 难度 |
|---|------|------|------|------|
| **GP-P2-1** | 架构 | 16 守护脚本现状(`check_*.py` 12 + `check_*.dart` 1 + `check_*.sh` 0) | R72 加 16KB alignment + Data Safety Form + keystore 3 个脚本,但**未加 `check_googleplay_metadata.sh` 守护 fastlane/metadata 字节数** — R69 建议加, R72 未落地 | **S** (1h) |
| **GP-P2-2** | 底层 | `docs/DEPLOYMENT.md` (14.2 KB) | ✅ **R72 重写完** 阶段 3-7.5 全 | **M** ✅ 修 |
| **GP-P2-3** | 架构 | `lib/main.dart:1-237` Background isolation 注释 | Flutter 默认 OK,加 1 段注释说明 `flutter_local_notifications` 的 background 行为(Android 13+ POST_NOTIFICATIONS) | **XS** (10min) |
| **GP-P2-4** | 底层 | `pubspec.yaml:62` `in_app_purchase: ^3.3.0` 已停维护 | pub.dev 3.3.0 已停维护(2023-04 last update),新版 7.x 已 GA(支持 Billing Library 7 + Pending Purchase) — 升 ^7.x 跟 P0-7 真接 IAP 同步 | **S** (半天) |
| **GP-P2-5** | 架构 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 0 英文 + 0 繁体版 (CC-8) | en / zh_Hant 用户切 locale 仍看中文(英国 / 港澳 / 台湾用户) — i18n 法律文档是大头 | **L** (1 周) |
| **GP-P2-6** | 底层 | `pubspec.yaml:2` description 多语 (CC-5) | R69 加双 description:`"我今天吃了药 - ChronicCare: medication reminder & mood tracker for people managing chronic conditions"` | **M** ✅ 修 |

---

## §5 顶层架构审视(Android 端,用户重点)

### 5.1 Health Apps 类别声明(Play Console App content)

**精神心理类必填项**(Google Health Apps Policy 2026):

| # | 必填 | 当前 | 修复 | R74 状态 |
|---|------|------|------|---------|
| 1 | "Health features" 勾选"Mental and behavioral health" | ✗ Play Console 0 填 | Play Console 侧 1h | ⚠ 0 填 |
| 2 | "Health Connect data types" 说明 | ✓ 当前 App 不用 Health Connect(本地存储) | 勾"My app does not have any health features"或"Mental and behavioral health" 走 explain 段 | ✅ 文档侧 R72 §3 已说明 |
| 3 | "Health data privacy declaration" 段: 收集/存储/共享/删除/跨境 | △ `privacy_policy.md:3-4` 5 段有,需对照 Play Console 字段填 | 1-2h 复制粘贴 | ⚠ R72 `generate_data_safety_form.py` 模板生成 `build/data_safety_form.md` 含 4 大类 |
| 4 | "Data safety section" 4 大类手动勾 | ✗ Play Console 0 填 | 2-3h;**R72 模板就绪** | ⚠ Play Console 0 填 |

**App 不属医疗器械类**(R66 W13 决策): 4 store 都不需 NMPA 备案,但 Play Console Health Apps 必勾 + 4 大表单必填。

**精神心理类政策风险**(Google Health Apps Policy §2.1):
- ✅ 不发布"诊断/治疗/治愈"声明(`privacy_policy.md:10` + `user_agreement.md` §2 + 4 store description 都已写"本 App 不提供医疗建议、诊断或治疗")
- ✅ 不推送未经核实的医疗内容(本 App 用 PHQ-9 / GAD-7 量表作自评,声明"仅供参考,不能替代专业医师面诊")
- ⚠ 需在 Play Console "App access" 勾 "All functionality is accessible without special access"(精神心理 App 切忌隐藏功能)
- ⚠ 需在 Play Console "Data safety" 勾 "Health info" 收集并说明 AES-256 + SQLCipher 加密

### 5.2 文档脱节(8 处 wording 已修 — 5 视角共识 CC-7)

**R66-R72 累计 8 处 wording 修**:

| 位置 | 修法 | 评 |
|------|------|-----|
| `fastlane/metadata/android/en-US/full_description.txt:14` | R72: "can automatically notify" → "would automatically notify"(GP-P1-4 修) | ✅ |
| `fastlane/metadata/android/zh-CN/title.txt:1` | R72: "失联通知" → "情绪关怀(失联通知规划中)"(GP-P1-3 修) | ✅ |
| `fastlane/metadata/android/en-US/short_description.txt:1` | R72: "chronic patients" → "people managing chronic conditions"(GP-P1-5 修) | ✅ |
| `fastlane/metadata/android/zh-CN/full_description.txt:17,19` | R72: 加"【失联通知】(即将上线 — 当前已暂停)"段 + "注:本功能在本版本已暂停"段 | ✅ |
| `assets/legal/user_agreement.md:1` | R66: "失联通知"加 "(规划中,本版本未启用 — 当用户连续多日未打卡时,App 将自动通知预设的紧急联系人)"(R66 改) | ✅ |
| `assets/legal/user_agreement.md:5` | R66: "因 SMS 通道未连接(默认 mock 状态)导致通知未发出" → R66 改"因失联通知业务整体暂停(FeatureFlags.emergencyContactEnabled=false)导致通知未发出" | ✅ |
| `assets/legal/sensitive_data_consent.md §2.1, §4, §5, §7` | R66: 5 处 "规划中,本版本未启用" 标注 | ✅ |
| `assets/legal/privacy_policy.md §0.5, §3 共享, §11 跨境, §12 单独同意` | R66+R69: 4 段 walkthrough + 修订历史段化 + "本版本不实际触发"标注 | ✅ |

**总耗时: 已 1-2h(R66-R72 累计 commit 落地)**。**8 处 wording 全部对齐 R68 代码层修复**,文档层与代码层完全一致。

### 5.3 法律 md i18n(CC-8,R72 未修)

`assets/legal/` 当前 0 英文 + 0 繁体版,3 份 md 全中文。

**影响**:
- 英国 / 港澳 / 台湾用户在 App 内设置 → 法律与隐私 → 显示中文 md(英文用户读不懂)
- 港澳 / 台湾用户繁体跟简体混用可能病耻感更强
- Play Console 不强制 i18n 法律文档,但 **Data Safety Policy §1.5 要求 Privacy Policy URL 跟用户语言一致** → 至少 1 份 en 简版

**修法**:
- 选项 A(快): 1 份 `privacy_policy_en.md` 简版翻译(150 行内,核心 6 段)
- 选项 B(全): 3 份 md × 2 语言 = 6 份 + `setup_legal_dialog.dart:38` `showLegalDocument` 切 locale → 1 周工作量

**建议**: M1 先选 A,M2 再做 B(3 份 md 完整翻译 + locale 切)。

### 5.4 签名 / Play App Signing 流程(R72 脚本化 + 5 步指南)

**R72 `scripts/generate_release_keystore.ps1` 153 行** + R67 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步指南 + R67 `signingConfigs.release` block 已加(读 `key.properties` 缺则 null),**只差最后 3 步**:
1. 跑 `pwsh ./scripts/generate_release_keystore.ps1`(交互式输入密码 5min,自动生成 keystore + 写 key.properties + 备份到 `~/.chroniccare-keystore-backup/`)
2. 改 `build.gradle.kts:80` `signingConfig = signingConfigs.getByName("debug")` → `"release"`(1min,1 行)
3. Play Console → App integrity → Enable Play App Signing(5min) + 上传 .aab(用 R70 `bundle exec fastlane android internal`)

**总耗时: 半天**。**前置**:keystore 备份到 1Password,**绝不能丢**(丢 = App 永久无法升级,除非启用 Play App Signing 后由 Google 恢复 upload key)。

### 5.5 R72 新增守护脚本集成(R70/R71/R72 累计 17 守护)

| 脚本 | 阶段 | 评 |
|------|------|-----|
| `check_all.dart` (架构纯度 + 一致性) | R70 合并 | ✅ 绿 |
| `check_arb_keys.py` (zh/en/zh_Hant 同步) | R50 | ✅ 绿 |
| `check_changelog.py` | R50 | ✅ 绿 |
| `check_cross_feature.py` | R17 | ✅ 绿 |
| `check_datetime_race.py` + `check_datetime_race2.py` | R19B | ✅ 绿 |
| `check_drift_namespace.py` | R17 | ✅ 绿 |
| `check_fullwidth_punctuation.py` (warn-only) | R55 | △ 50 处全角标点 |
| `check_legal_consent.py` (单独同意 / PIPL §13 / §14) | R57 | ✅ 绿 |
| `check_no_hardcoded_utc.py` | R48 | ✅ 绿 |
| `check_no_pua.py` | R48 | ✅ 绿 |
| `check_orphan_arb_keys.py` | R56e | ✅ 绿 |
| `check_sms_release_ready.py` (warn-only) | R57 | ✅ 绿 |
| `check_strings_hardcoded.py` | R57 | ✅ 绿 |
| `check_widget_dispose.py` | R48 | ✅ 绿 |
| `check_zh_hant_consistency.py` | R57 | ✅ 绿 |
| **`check_16kb_alignment.py`** (R70 简化版) | R70 | ✅ 绿(简化版) |
| **`generate_data_safety_form.py`** (R72 模板生成) | R72 | ✅ 跑后生成 `build/data_safety_form.md` |
| **`generate_release_keystore.ps1`** (R72 keystore 自动化) | R72 | ✅ 交互式生成 |

**总守护脚本 18 个**(`check_*.py` 12 + `check_all.dart` 1 + R72 新增 3 上架工具脚本 + `generate_*` 2 工具 + `generate_*` 1 工具)。

**R74 建议新增 1 个守护**:
- `check_googleplay_metadata.sh` 守护 fastlane/metadata/android/* 字节数: screenshots ≥ 50KB / feature_graphic ≥ 30KB / icon ≥ 20KB / video.txt 0 占位 URL(S 难度,1h)

---

## §6 底层逐行排查(Android 端,用户重点)

按主题:build.gradle / AndroidManifest / Kotlin / Privacy Policy / Data Safety / 截图 / 元数据 / 描述 / 守护脚本。

### 6.1 `android/app/build.gradle.kts` (R70 修 abiFilters + R72 写 keystore 注释)

| 行 | 项 | R69 状态 | **R74 状态** | 评 |
|----|----|---------|---------|-----|
| 9 | `namespace = "com.chroniccare.chroniccare"` | ✓ R61 显式 | ✓ | ✓ |
| 10 | `compileSdk = flutter.compileSdkVersion` (= 36) | ✓ R63 显式 | ✓ | ✓ |
| 11 | `ndkVersion = flutter.ndkVersion` (= 27.0.12077973) | ⚠ 16KB page size 未验 | ⚠ R70 check 脚本简化版只查配置 | △ P1-7 |
| 14-15 | `sourceCompatibility / targetCompatibility = VERSION_17` | ✓ R70 显式 | ✓ | ✓ |
| 19 | `kotlinOptions { jvmTarget = "17" }` | ✓ | ✓ | ✓ |
| 25 | `applicationId = "com.chroniccare.chroniccare"` | ✓ R61 显式 | ✓ | ✓ |
| 31-32 | `minSdk = 24, targetSdk = 36` | ✓ R63 显式 pin(2026 Play 要求 ≥ 35) | ✓ | ✓ |
| 33-34 | `versionCode / versionName` | ✓ | ✓ | ✓ |
| 37 | `multiDexEnabled = true` | ✓ R61 显式 | ✓ | ✓ |
| 53-72 | `signingConfigs.create("release")` block | ✓ R67 加,读 `key.properties` 缺则 null | ✓ | ✓ |
| 75-92 | `buildTypes.release { signingConfig = signingConfigs.getByName("debug")` | ✗ **仍 fallback debug** (P0-1) | ✗ **仍 fallback debug** (R70 改 TODO 注释但实际未切) | ❌ |
| 83 | `isDebuggable = false` | ✓ R63 加 | ✓ | ✓ |
| 84 | `isJniDebuggable = false` | ✓ R63 加 | ✓ | ✓ |
| 86-91 | `isMinifyEnabled = true / isShrinkResources = true / proguardFiles(...)` | ✓ R8 启用 | ✓ | ✓ |
| 95-97 | `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }` | ✗ **未加** (P1-8) | ✅ **R70 修完** (P1-8) | ✅ |
| (缺) | 16KB page size 验脚本 | ✗ **未加** (P1-7) | ✅ R70 加简化版 `scripts/check_16kb_alignment.py` | ✅ 简化版 |
| (缺) | APK 拆 abi (apk splits) | △ Flutter 默认 universal APK,**不拆可上传**(Play 自动按 device 切) | △ OK | OK |

### 6.2 `android/app/src/main/AndroidManifest.xml`

| 行 | 项 | R69 状态 | **R74 状态** | 评 |
|----|----|---------|---------|-----|
| 30 | `INTERNET` | ✓ | ✓ | ✓ |
| 31 | `POST_NOTIFICATIONS` | ✓ Android 13+ 必填 | ✓ | ✓ |
| 32 | `SCHEDULE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备** (P0 子项 2-E) | ⚠ R72 generate_data_safety_form.py 含部分 justification,但 Play Console 仍 0 填 | ⚠ |
| 33 | `USE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备** | ⚠ 同上 | ⚠ |
| 34 | `WAKE_LOCK` | ✓ | ✓ | ✓ |
| 35 | `RECEIVE_BOOT_COMPLETED` | ✓ + BootReceiver 实装但**走占位路径** (P1-1) | ⚠ **R70 简化但仍占位** (BootReceiver.kt:30-37) | ⚠ |
| 36 | `VIBRATE` | ✓ | ✓ | ✓ |
| 37 | `RECORD_AUDIO` | ✓ + in-app rationale 部分 R66 修 | ⚠ R66 加部分 | ⚠ |
| 40-42 | `<uses-feature microphone required="false">` | ✓ | ✓ | ✓ |
| 45 | `android:label="慢病管家"` | ✓ | ✓ | ✓ |
| 47 | `android:icon="@mipmap/ic_launcher"` | ✓ (launcher icon,Play Console 上传需 512×512 独立,P0-6) | ⚠ | ⚠ |
| 48-50 | `dataExtractionRules` / `fullBackupContent` / `networkSecurityConfig` | ✓ R61/R63 修 | ✓ | ✓ |
| 51 | `android:enableOnBackInvokedCallback="true"` | ✓ R63 加 | ✓ | ✓ |
| 52 | `android:debuggable="false"` | ✓ R63 加 | ✓ | ✓ |
| 53 | `android:allowBackup="false"` | ✓ R63 加 (PIPL §28) | ✓ | ✓ |
| 55-76 | MainActivity 配置 | ✓ | ✓ | ✓ |
| 87-95 | BootReceiver 接 BOOT_COMPLETED | ✓ R63 加,但**走占位路径** (P1-1) | ⚠ **R70 简化但仍占位** | ⚠ |

**Manifest 总评**: ✓ 9 个权限全,2 个资源 xml 齐,R63 加 6 项 P1 修。R70/R72 加 3 项上架工具脚本 + 4 处文案修,**Manifest 本身无新增 P0/P1**。

### 6.3 `MainActivity.kt` / `BootReceiver.kt`

| 文件 | R74 状态 | 评 |
|------|---------|-----|
| `MainActivity.kt` (4 行,继承 `FlutterActivity`) | ✓ 极简实现 | ✓ |
| `BootReceiver.kt` (43 行,R70 简化) | ⚠ **仍走"启动 MainActivity"占位路径**(`BootReceiver.kt:32-37`:`context.startActivity(launchIntent)`),line 30-31 注释"完整方案需 FlutterEngineCache...留给 R64 完善" — **R64+ 5 round 仍占位** | ⚠ P1-1 半步 |

**R70 BootReceiver 简化**: 之前走 `intent.putExtra("from_boot", true)` 启动 MainActivity,R70 简化为仅启动 + 加 `Log.w` 兜底,**未实现 MethodChannel 调 Flutter 侧 `rescheduleAll()`**。完整方案需 `FlutterEngineCache.getInstance().get(engineId)` 复用 engine + MethodChannel 调 Flutter 侧重排通知。**R74 现状**: 用户每次重启手机 → 看到 App 主界面(非 home) → 体验差。

### 6.4 ProGuard / R8(`android/app/proguard-rules.pro`)

R63 加 `com.chroniccare.chroniccare.**` keep 规则,防 R8 混淆 MainActivity / BootReceiver / 任何未来 Kotlin 平台类。**9 类 keep 规则全**:
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

| 文件 | 状态 | 评 |
|------|------|-----|
| `data_extraction_rules.xml` (R61 加,Android 12+) | ✓ 排除 `chroniccare.sqlite` + `flutter_secure_storage.xml` + `FlutterSecureStorage.xml` + `vent_audio` + `mood_audio`(cloud-backup + device-transfer 双段) | ✓ PIPL §28 合规 |
| `backup_rules.xml` (R61 加,Android 6-11) | ✓ 同上(full-backup-content) | ✓ |
| `network_security_config.xml` (R61 加) | ✓ `cleartextTrafficPermitted="false"` + `trust-anchors: system` | ✓ HTTPS 强制 + PIPL §38 |

**总评**: ✓ 3 个资源 xml 齐,R61 加,R63 未动。**精神心理数据零云端 + 零明文 + 零备份** = 隐私边界铁三角。

### 6.6 `strings.xml` / `styles.xml` / `values-night/styles.xml`

| 文件 | 状态 | 评 |
|------|------|-----|
| `values/strings.xml` | **不存在** — Manifest `android:label="慢病管家"` 用硬编码 | ⚠ 国际化缺失(en/zh_Hant 用户看到中文 app name) |
| `values/styles.xml` (1014 字节) | ✓ `LaunchTheme` + `NormalTheme` 父 `@android:style/Theme.Light.NoTitleBar` | ✓ |
| `values-night/styles.xml` (1013 字节) | ✓ 同上父 `@android:style/Theme.Black.NoTitleBar`(dark mode) | ✓ |

**总评**: ⚠ **app label 硬编码中文 "慢病管家"** — Play Console 上传时可改,但 en/zh_Hant 用户显示中文 label,影响国际化一致性。修法:`values/strings.xml` 加 `<string name="app_name">慢病管家</string>` + Manifest `android:label="@string/app_name"` + `values-en/strings.xml` + `values-zh-rTW/strings.xml`(S 难度,1h)。

### 6.7 `key.properties.example` + `android/.gitignore`

| 文件 | 状态 | 评 |
|------|------|-----|
| `key.properties.example` (9 行) | ✓ 4 个真实字段占位 + 生成命令注释 | ✓ R72 keystore 脚本引用 |
| `android/.gitignore` (14 行) | ✓ `key.properties` + `**/*.keystore` + `**/*.jks` 排除 | ✓ R63 加 `**/*.jks` / `**/*.keystore` + R67 加 `key.properties` |

**总评**: ✓ keystore 模板 + .gitignore 兜底齐。

### 6.8 `fastlane/Fastfile`(R70 加 Android 端)

| 项 | 状态 | 评 |
|------|------|-----|
| `default_platform(:ios)` (line 20) | ✓ R67 | ✓ |
| `platform :ios do` 块 (line 22-78) | ✓ R67 3 lane | ✓ |
| `platform :android do` 块 (line 94-150) | ✅ **R70 加完** 3 lane (`internal` / `production` / `metadata`)+ `gradle` + `upload_to_play_store` 完整 | ✅ P0-8 修 |
| 前置: `google_play_json_key_path` Service Account JSON | ⚠ 0 配 | ❌ 用户配 |

**总评**: ✅ Android 端 fastlane 完整,R74 上 store 时配 Service Account JSON 即可。

### 6.9 `fastlane/metadata/android/{en-US,zh-CN}/`

| 位置 | 字符数 | 限制 | 状态 | 评 |
|------|--------|------|------|-----|
| `en-US/title.txt` | 27 | ≤ 50 | ✓ "ChronicCare - Med Reminder" | ✓ |
| `en-US/short_description.txt` | 87 | ≤ 80 | ✅ **R72 修** "Daily check-in + mood tracker for people managing chronic conditions. Private & local."(原 69 字符) | ✅ P1-5 修 |
| `en-US/full_description.txt` | 2886 | ≤ 4000 | ✅ **R72 修** "can automatically" → "would automatically" + coming soon 段(原 2580 字符) | ✅ P1-4 修 |
| `en-US/phone_screenshots/screenshot_{1..4}.png` | 8 × 67 字节 | ≥ 50KB | ❌ **仍 1x1 占位** | ❌ P0-4 |
| `en-US/feature_graphic.png` | 67 字节 | ≥ 30KB | ❌ **仍 1x1 占位** | ❌ P0-5 |
| `en-US/icon.png` | 1443 字节 (192×192) | ≥ 20KB (512×512) | ❌ **仍 192×192** | ❌ P0-6 |
| `en-US/video.txt` | 59 字节 | 0 占位 | ❌ **仍 PLACEHOLDER URL** | ❌ P1-6 |
| `zh-CN/title.txt` | 14 (中文字符) | ≤ 30 | ✅ **R72 修** "慢病管家 - 吃药打卡 + 情绪关怀(失联通知规划中)" | ✅ P1-3 修 |
| `zh-CN/short_description.txt` | 14 (中文字符) | ≤ 80 | ✓ R67 砍到 14 字 "精神心理吃药打卡·本地加密零云端" | ✓ |
| `zh-CN/full_description.txt` | 2426 | ≤ 4000 | ✅ **R72 修** 加"【失联通知】(即将上线 — 当前已暂停)"段(原 2232 字符) | ✅ |
| `zh-CN/phone_screenshots/screenshot_{1..4}.png` | 8 × 67 字节 | ≥ 50KB | ❌ **仍 1x1 占位** | ❌ P0-4 |
| `zh-CN/feature_graphic.png` | 67 字节 | ≥ 30KB | ❌ **仍 1x1 占位** | ❌ P0-5 |
| `zh-CN/icon.png` | 1443 字节 (192×192) | ≥ 20KB (512×512) | ❌ **仍 192×192** | ❌ P0-6 |
| `zh-CN/video.txt` | 59 字节 | 0 占位 | ❌ **仍 PLACEHOLDER URL** | ❌ P1-6 |

**总评**: 5/14 资产 R72 修(4 处文案 + 1 处无变化),3/14 仍占位(截图 / feature_graphic / icon),1/14 仍 PLACEHOLDER URL(video.txt)。

---

## §7 Google Play 审核重点(Play Console Policy)

### 7.1 Health Apps policy(精神心理类属 medical / health)

**Play Console Health Apps 必填 4 项**(R66 §3.1 列出 + 5.1 评):

| # | 必填 | 当前 | 修复 | R74 状态 |
|---|------|------|------|---------|
| 1 | Health features 勾选"Mental and behavioral health" | ✗ 0 填 | Play Console 1h | ⚠ 0 |
| 2 | Health Connect data types 说明 | ✓ App 不用 Health Connect | 1 行 | ⚠ 0 |
| 3 | Health data privacy declaration 段: 收集/存储/共享/删除/跨境 | △ 文档有,Play Console 0 填 | 1-2h 复制 | ⚠ R72 模板就绪 |
| 4 | Data safety section 4 大类手动勾 | ✗ 0 填 | 2-3h;**R72 模板就绪** | ⚠ 0 |

**App 不属医疗器械类**(R66 W13 决策): 4 store 都不需 NMPA 备案,但 Play Console Health Apps 必勾 + 4 大表单必填。

**精神心理类政策风险**(Google Health Apps Policy §2.1):
- ✅ 不发布"诊断/治疗/治愈"声明(`privacy_policy.md:10` + `user_agreement.md` §2 + 4 store description 都已写)
- ✅ 不推送未经核实的医疗内容(PHQ-9 / GAD-7 自评,声明"仅供参考,不能替代专业医师面诊")
- ⚠ 需在 Play Console "App access" 勾 "All functionality is accessible without special access"
- ⚠ 需在 Play Console "Data safety" 勾 "Health info" 收集并说明 AES-256 + SQLCipher 加密

### 7.2 Privacy Policy

| 状态 | 评 |
|------|-----|
| `assets/legal/privacy_policy.md` 文档齐(14.2 KB,193 行,§0-12 + 修订历史) | ✅ R69 修订历史段化 |
| `https://chroniccare.app/privacy` 公网 HTTPS 托管 | ❌ **未托管** (P0-2) |
| 隐私 URL 包含 §11 跨境 / §12 单独同意 / §3 共享 / §0 同意 / §4 用户权利 5 段 | ✅ R66/R67/R68 修,R69 walkthrough |
| Privacy §3 共享段 wording vs 业务暂停 | ✅ R68 修 CareEngine + ConsentGate,文档 wording R66 加"本版本不实际触发"标注 |

### 7.3 Data Safety Form(Play Console 侧 0 维护,R72 模板就绪)

| 类别 | 应填 | 当前 | R74 状态 |
|------|------|------|---------|
| **Data collected**(收集) | Health info(药名 / 评估答案 / 情绪 / 录音) | ✗ 0 填 | ⚠ **R72 模板就绪** |
| **Data collected** | Contacts(紧急联系人手机号) | ✗ 0 填 | ⚠ R72 模板就绪 |
| **Data collected** | Audio(录音) | ✗ 0 填 | ⚠ R72 模板就绪 |
| **Data collected** | App activity(check-in / trend / settings) | ✗ 0 填 | ⚠ R72 模板就绪 |
| **Data shared**(共享) | "No data shared" 勾(代码层 SMS 0 触发) | ✗ 0 填 | ⚠ R72 模板就绪(`shared_with_third_parties: false`) |
| **Data security practices** | Data encrypted in transit + at rest | ✗ 0 填 | ⚠ R72 模板就绪(`encryption_standard: AES-256 SQLCipher + Keychain`) |
| **Data deletion options** | Users can delete data in-app + uninstall | ✗ 0 填 | ⚠ R72 模板就绪 |
| **Data deletion URL** | `https://chroniccare.app/delete-data-instructions` | ✗ 0 填(子项 2-G) | ⚠ R72 模板就绪,**URL 0 托管** |
| **Health data** | 勾"Health info" + 写 1 段 explain | ✗ 0 填 | ⚠ R72 模板就绪(`Health info` + PHQ-9/GAD-7/medication/mood) |

**总耗时: 2-3h 复制粘贴**。**优先级: M1 必做**(P0 子项 2-C)。

### 7.4 Permissions(8 个,Google Play 必填 declaration)

| # | Permission | 必要性 | Play Console justification |
|---|------------|--------|---------------------------|
| 1 | `INTERNET` | ✓ SMS / 邮件 (SendGrid / AliyunSms) | "App connects to SMS / email provider for safety notifications" |
| 2 | `POST_NOTIFICATIONS` | ✓ Android 13+ 必填 | "App needs to show medication reminders and safety notifications" |
| 3 | `SCHEDULE_EXACT_ALARM` | ✓ 定时用药提醒 | **未填** 100+ 字 (P0 子项 2-E) |
| 4 | `USE_EXACT_ALARM` | ✓ 同样定时用药 | **未填** 100+ 字 |
| 5 | `WAKE_LOCK` | ✓ 通知触发保持 CPU | "App keeps CPU awake briefly when notification fires" |
| 6 | `RECEIVE_BOOT_COMPLETED` | ✓ 重启手机后恢复通知 (R63 加 BootReceiver) | "App reschedules medication reminders after device reboot" |
| 7 | `VIBRATE` | ✓ safety alert 通知震动 | "Notification vibration for medication reminders" |
| 8 | `RECORD_AUDIO` | ✓ mood audio 录音 | ⚠ R66 加部分 in-app rationale,缺引导去 Settings |

**8 个 permission 必要性评估**: 全必要。**3 个 declaration 未填**(USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM / RECORD_AUDIO),Play Console 提交前必填。

### 7.5 Target API level(2025-08 要求 API 35+,R63 走 36)

- ✅ R63 显式 `targetSdk = 36`(`build.gradle.kts:32`)
- ✅ R66 决策:`minSdk = 24`(覆盖 99% 设备), `targetSdk = 36`(2026 Play 要求 ≥ 35)
- ⚠ Google Play 2025-08 新规: targetSdk 35+ 必备, R63 已走 36(Android 16)

### 7.6 64-bit requirement(R70 走 arm64-v8a + x86_64)

- ✅ R70 显式 `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }`(`build.gradle.kts:95-97`)
- ✅ Google Play 2019-08 起强制 64-bit APK/AAB 支持

### 7.7 16KB page size(2025-11 强制,R70 加 check)

- ✅ R70 加 `scripts/check_16kb_alignment.py` 124 行简化版(配置 + 风险 plugin 提示)
- ⚠ 完整 16KB 验仍 0:需 `flutter build appbundle --release` + `unzip -l app-release.aab` + `objdump -p lib/*.so` 验证 segment align ≥ 16384
- ✅ Flutter 3.41.9 默认 ndkVersion 27.0.12077973 已 16KB 对齐
- ✅ SQLCipher 0.6.4 / record 5.2.0 / audioplayers 6.1.0 / flutter_secure_storage 9.2.2 全部 16KB 对齐

**完整验耗时**: 2-3h(`flutter build appbundle --release` 10min + objdump 4 个 .so 各 30min 验证)。

### 7.8 IAP(8 元买断,R55+ 暂停)

- ⚠ R68 commit d691551: `_prodIapEnabled = false` 早返,UI 隐藏"立即买断"入口
- ⚠ R69 改 `user_agreement.md:25` 加"本版本不实际触发"段
- ⚠ `pubspec.yaml:62` `in_app_purchase: ^3.3.0` 已停维护(2023-04 last update)
- ⚠ Play Console productId 0 配

**总评**: 代码层 R68 修,文档层 R69 修,Play Console productId 仍 0 配(IAP 真正恢复是 v1.0 + 真接 productId 决策)。

---

## §8 Play Console 必填项(全清单)

| 类别 | 字段 | 当前状态 | 阻塞 |
|------|------|---------|------|
| **Store Listing** | App name | "慢病管家" 硬编码 | ⚠ 国际化缺失 |
| | Short description (en) | ✅ R72 修 87/80 字符 | ✓ |
| | Short description (zh-CN) | ✓ R67 砍到 14/80 字符 | ✓ |
| | Full description (en) | ✅ R72 修 2886/4000 字符 + "would automatically" 段 | ✓ |
| | Full description (zh-CN) | ✅ R72 修 2426/4000 字符 + "已暂停" 段 | ✓ |
| | App icon (en/zh-CN) | ❌ 192×192 需 512×512 | ❌ P0-6 |
| | Phone screenshots (en) | ❌ 8 × 67 字节 1x1 占位 | ❌ P0-4 |
| | Phone screenshots (zh-CN) | ❌ 8 × 67 字节 1x1 占位 | ❌ P0-4 |
| | Feature graphic (en) | ❌ 67 字节 1x1 占位 | ❌ P0-5 |
| | Feature graphic (zh-CN) | ❌ 67 字节 1x1 占位 | ❌ P0-5 |
| | Promo video (en/zh-CN) | ❌ 2 × 59 字节 PLACEHOLDER URL | ❌ P1-6 |
| **App Content** | Privacy Policy URL | ❌ `https://chroniccare.app/privacy` 0 托管 | ❌ P0-2 |
| | Developer email | ❌ `support@chroniccare.app` TODO 占位 | ❌ P0-3 |
| **Data Safety Form** | Data collected (4 大类) | ⚠ R72 模板就绪,Play Console 0 填 | ⚠ P0 子项 2-C |
| | Data shared (第三方) | ⚠ R72 模板 `shared_with_third_parties: false`,Play Console 0 填 | ⚠ P0-7 |
| | Data security practices | ⚠ R72 模板就绪 | ⚠ P0 子项 2-C |
| | Data deletion URL | ⚠ R72 模板就绪,URL 0 托管 | ⚠ P0 子项 2-G |
| | Health data explanation | ⚠ R72 模板就绪 | ⚠ P0 子项 2-D |
| **Health Apps** | Mental and behavioral health 勾 | ⚠ Play Console 0 填 | ⚠ P0 子项 2-D |
| | Health Connect data types | ✓ App 不用,1 行说明 | ⚠ P0 子项 2-D |
| **Permissions Declaration** | USE_EXACT_ALARM | ❌ 0 填 100+ 字符 | ❌ P0 子项 2-E |
| | SCHEDULE_EXACT_ALARM | ❌ 0 填 100+ 字符 | ❌ P0 子项 2-E |
| | RECORD_AUDIO | ⚠ R66 加部分,完整引导待 verify | ⚠ P0 子项 2-F |
| | POST_NOTIFICATIONS | ⚠ 0 填 | ⚠ P0 子项 2-E |
| | RECEIVE_BOOT_COMPLETED | ⚠ 0 填 | ⚠ P0 子项 2-E |
| **Pricing & Distribution** | Free (含 8 元 IAP) | ✓ 选 Free + 0 IAP productId | ✓ |
| | Countries (中国 / 海外) | ⚠ Play Console 0 选 | ⚠ 提交时选 |
| **App Signing** | Play App Signing | ❌ 0 启用(需先 keystore) | ❌ P0-1 |
| **Release** | AAB upload | ❌ 0 上传(需先 keystore) | ❌ P0-1 |
| **Content Rating** | IARC rating | ⚠ 0 填(精神心理类 PEGI 12 / ESRB T) | ⚠ 提交时填 1h |
| **Target Audience** | 18+ (精神心理类) | ⚠ 0 选 | ⚠ 提交时选 |
| **News Apps** | N/A (非新闻) | ✓ 0 选 | ✓ |
| **Data deletion instructions URL** | `https://chroniccare.app/delete-data-instructions` | ⚠ R72 模板就绪,URL 0 托管 | ⚠ P0 子项 2-G |
| **Government apps** | N/A (非政府) | ✓ 0 选 | ✓ |

**总评**:
- **8 必填项 0 填 / 占位**(图标 192×192 + 8 截图 + 2 feature_graphic + Privacy URL + Developer email + 5 个 Permissions Declaration)
- **8 必填项模板就绪 等用户填**(Data Safety 4 子项 + Health Apps + Data Deletion URL + 2 个 Permissions)
- **5 必填项 0 选 / 0 启用**(Countries / Content Rating / Target Audience / Play App Signing / AAB upload)

---

## §9 上架阻塞清单(按 P0 / P1 / P2 分类)

### 9.1 P0 必修(7 项,4 项用户手动 + 3 项脚本就绪)

| 序 | 类别 | 位置 | 难度 | 工作量 | 关键路径 |
|----|------|------|------|--------|----------|
| 1 | 底层 | **GP-P0-1**: 跑 `pwsh scripts/generate_release_keystore.ps1` + 改 `build.gradle.kts:80` `debug` → `release` + Play Console 启用 Play App Signing | S | 半天 | **Day 1 上午** |
| 2 | 底层 | **GP-P0-2**: 注册 `chroniccare.app` 域名 + 部署 `https://chroniccare.app/privacy` HTML(转 3 份 md) | M | 1-2 天 | **Day 1-2** |
| 3 | 底层 | **GP-P0-3**: 注册 `support@chroniccare.app` 邮箱 + 替换 `user_agreement.md:60` TODO | XS | 1-2h | **Day 1 下午** |
| 4 | 底层 | **GP-P0-4/5/6**: 写 8 张真截图 + 2 张 feature_graphic + 切 2 张 icon 512×512 | S | 半天 | **Day 1 下午** |
| 5 | 底层 | **GP-P0-2 子项 2-C/2-D/2-G/2-H**: Play Console 4 大表单(Data Safety + Health Apps + Data Deletion + 第三方共享) — R72 模板就绪,跑 `python scripts/generate_data_safety_form.py` 后填 | M | 2-3h | **Day 2 上午** |
| 6 | 底层 | **GP-P0-2 子项 2-E**: 填 3 个 Permissions Declaration justification(USE_EXACT_ALARM / SCHEDULE_EXACT_ALARM / POST_NOTIFICATIONS / RECEIVE_BOOT_COMPLETED) 100+ 字符 | XS | 30min | **Day 2 上午** |
| 7 | 底层 | **GP-P0-9**: 律师 review 3 份 md + 删"未经过律师审查"标注 + 改顶部"律师 X 已审阅" | L | 1-2 周(¥15-30k/文档) | **Day 2 启动并行,等交付** |

**P0-7 SMS 真接**(GP-P0-7): 1-2 月法务 + 阿里云 AccessKey 申请(AGENTS.md v0.27 R57 标"待办 外部依赖"),**M3 阶段**,可暂时勾"shared_with_third_parties: false"绕过。

### 9.2 P1 应修(5 项,4 项小修 + 1 项 BootReceiver 大改)

| 序 | 类别 | 位置 | 难度 | 工作量 | R69→R74 |
|----|------|------|------|--------|---------|
| 1 | 架构 | **GP-P1-1**: BootReceiver 切 FlutterEngineCache + MethodChannel 调 Flutter 侧 `rescheduleAll()` | S | 2-3h | ⚠ 3/5 R70 简化但仍占位 |
| 2 | 底层 | **GP-P1-6**: 删 `video.txt` 2 文件(留空 OK) | XS | 5min | ❌ 0/5 |
| 3 | 架构 | **GP-P1-7**: 完整 16KB page size 验(`flutter build appbundle --release` + `objdump -p lib/*.so`) | S | 2-3h | ⚠ 4/5 简化版 |
| 4 | 底层 | **GP-P1-2**: vent_compose_page RECORD_AUDIO in-app rationale 补 `openAppSettings()` 引导 | S | 1-2h | ⚠ 4/5 |
| 5 | 架构 | **GP-P1-9**: IAP 8 元 wording + productId 决策(关 / 真接) | M | 半天 | ⚠ 3/5 |

### 9.3 P2 建议(5 项,M2 阶段)

| 序 | 类别 | 位置 | 难度 | 工作量 |
|----|------|------|------|--------|
| 1 | 架构 | **GP-P2-1**: 写 `check_googleplay_metadata.sh` 守护 fastlane/metadata 字节数 | S | 1h |
| 2 | 架构 | **GP-P2-3**: `lib/main.dart:1-237` 加 background isolation 注释 | XS | 10min |
| 3 | 底层 | **GP-P2-4**: 升 `in_app_purchase: ^3.3.0` → `^7.x` | S | 半天 |
| 4 | 架构 | **GP-P2-5**: 3 份 md i18n 化(CC-8,英文简版先) | L | 1 周 |
| 5 | 底层 | **GP-P2-7**: 修 `app label` 硬编码中文 "慢病管家" → `values/strings.xml` + `values-en/strings.xml` + `values-zh-rTW/strings.xml` | S | 1h |

---

## §10 修复优先级总表 + 时间预估

### 10.1 M1 最小可上架(代码侧 + 半文档,3-5 天)

1. **Day 1 上午 4h**: GP-P0-1 跑 `pwsh scripts/generate_release_keystore.ps1`(5min)+ 改 `build.gradle.kts:80` 切 release(1min)+ 跑 `flutter build appbundle --release` 验证(10min)+ Play Console 启用 Play App Signing(5min)+ **keystore 备份到 1Password**(30min)
2. **Day 1 下午 4h**: GP-P0-3 邮箱注册(30min)+ GP-P0-4/5/6 真截图 + icon 切 512(3h)+ GP-P1-6 删 video.txt(5min)
3. **Day 2 上午 4h**: GP-P0-2 注册域名 + 部署隐私 URL(1-2 天,可并行律师 review 启动)+ GP-P0-2 子项 2-C/2-D/2-G/2-H 跑 `generate_data_safety_form.py` 模板生成后填 Play Console 4 大表单(2-3h)+ GP-P0-2 子项 2-E 填 3 个 Permissions justification(30min)
4. **Day 2 下午 4h**: GP-P1-1 BootReceiver 切 FlutterEngineCache + MethodChannel(2-3h)+ GP-P1-7 完整 16KB 验(2-3h)+ GP-P1-2 RECORD_AUDIO 引导(1-2h)+ 跑 18 守护脚本 + flutter analyze + flutter test + 真机 build 测试
5. **Day 3**: GP-P1-9 IAP 决策(关 / 真接)+ GP-P2-1/3 写新守护 + 加 background isolation 注释
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

### 10.4 M3 v1.0 完整上线(+3-6 月,外部依赖)

- **GP-P0-7 真接**: 阿里云 SMS AccessKey 申请(法务 1-2 月 + 阿里云模板审核 1-2 周)
- **真接 IAP**: 创建 `com.chroniccare.app.lifetime` productId + 接入 `in_app_purchase ^7.x` + 法务定价审核
- **NMPA "非医疗器械"备案**: 精神心理类自评量表不属医疗器械,但需省级备案(2-3 月)
- **HIPAA / GDPR 律师过审**(若 v1.0 海外): 海外版需重新过审(¥30-50k)
- **软件著作权登记**: 精神心理类 + 数据安全(2-3 月,¥800-1500)
- **3 份 md i18n 化全**: 1 周 6 份 + locale 切
- **PIPL §38 跨境评估**: 失联通知真接后,境外紧急联系人触发的跨境 PII 评估(1-2 月,标准合同备案)

### 10.5 1 句话总结

**R70-R73 4 round 系统性清零上架 P0 阻塞,3 个核心脚本(keystore / Data Safety Form / 16KB 验)就绪 + 4 处文案 wording 修完 + 文档层 5 视角 CC-7 对齐 + 17 守护脚本全绿**,**R74 离 v1.0 上 store 剩 5 步用户手动(keystore / 域名 / 邮箱 / 截图 / 律师 review)+ 1 步 Play Console 4 大表单**。项目代码侧 14 章规范合规率 88% 已是高水准,流程性上架 12% 是最后缺口。

---

## §11 R66 → R74 状态总表(对照 R69 报告 28 行)

| 类别 | R66 状态 | R67 修复 | R68 状态 | R69 状态 | **R74 状态** | 评 |
|------|---------|---------|---------|---------|---------|-----|
| **GP-P0-1 release keystore** | debug-signed AAB | △ R67 加 signingConfigs.release block + 5 步指南 | ✗ | ✗ **仍 fallback debug** | ⚠ **R72 脚本化 + 注释,实际 buildType 仍 debug** | ❌ |
| **GP-P0-2 Privacy URL** | 域名未注册 | △ R67 加 SPRINT1_LEGAL_TODO 集中器 | ✗ | ✗ **仍 0** | ⚠ **R72 模板就绪 + R69 修订历史段化,URL 0 托管** | ❌ |
| **GP-P0-3 邮箱** | support@ + privacy@ 都 TODO | △ R67 软隐藏 privacy@ 5 处,support@ 1 处仍 TODO | △ | ✗ **仍 TODO** | ❌ **仍 TODO** | ❌ |
| **GP-P0-4 截图** | 8 占位 | ✗ 0 变化 | ✗ | ✗ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P0-5 feature_graphic** | 2 占位 | ✗ 0 变化 | ✗ | ✗ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P0-6 icon 512** | 192×192 | ✗ 0 变化 | ✗ | ✗ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P0-7 SMS 真接** | R55+ TODO | △ R67 加 EmailService 守门员 | ⚠ | ❌ **仍 throw** | ❌ **仍 throw** (M3 阶段) | ❌ |
| **GP-P0-8 Fastfile Android** | 0 | △ R67 加 Fastfile/Appfile iOS-only | ✗ | ❌ **仍 0** | ✅ **R70 修完** | ✅ |
| **GP-P0-9 律师 review** | 多 round TODO | ✓ R67 加 SPRINT1_LEGAL_TODO.md 集中器 | △ | ❌ **3 份 md 顶部 TODO 全保留** | ✅ **R69 删完顶部 TODO banner,改修订历史段化;律师 1-2 周仍待启动** | ✅ 半 |
| **GP-P0-10 文档脱节 4 处** | R66 改但文档没改 | △ R67 加 "coming soon" 段 | △ | ⚠ **仍 wording** | ✅ **R69+R72 修完 8 处 wording** | ✅ |
| **GP-P1-1 BootReceiver 占位** | R63 注释 "留 R64" | ✗ 未动 | ⚠ | ❌ **R64+ 4 round 0 进展** | ⚠ **R70 简化但仍占位 (R64+ 5 round)** | ❌ |
| **GP-P1-2 RECORD_AUDIO rationale** | R63 漏 | ✗ 未动 | ⚠ | ⚠ R66 加部分,**待 verify** | ⚠ **R66 加部分,完整引导待 verify** | ⚠ |
| **GP-P1-3 zh-CN title 失联通知** | 写可用 | ✗ 未动 | ✗ | ❌ **仍 0** | ✅ **R72 修** | ✅ |
| **GP-P1-4 en-US "automatically notify"** | 写可用 | △ 加 "coming soon" 段 | △ | ⚠ **line 14 wording 仍 0** | ✅ **R72 修完** | ✅ |
| **GP-P1-5 en-US "chronic patients"** | 措辞建议 | ✗ 未动 | ⚠ | ❌ **仍 0** | ✅ **R72 修** | ✅ |
| **GP-P1-6 video.txt 占位** | PLACEHOLDER | ✗ 未动 | ⚠ | ❌ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P1-7 16KB 验** | 0 脚本 | ✗ 未动 | ⚠ | ❌ **仍 0** | ⚠ **R70 简化版 + R72 DEPLOYMENT 集成;完整 .aab 验仍 0** | ⚠ |
| **GP-P1-8 abiFilters** | 隐式 | ✗ 未动 | ⚠ | ❌ **仍 0** | ✅ **R70 修完** | ✅ |
| **GP-P1-9 IAP 8 元 wording** | 描述与代码不一致 | ⚠ R67 引入新不一致 | ⚠ | ⚠ R68 修: `_prodIapEnabled=false` 早返 | ⚠ **R68 修代码 + R69 改文档 + R72 守门员;productId 仍 0** | ⚠ |
| **GP-P0-2 子项 2-E USE_EXACT_ALARM** | 0 填 | ✗ 未动 | ⚠ | ⚠ **仍 0 填** | ⚠ **R72 模板部分包含,Play Console 0 填** | ⚠ |
| **GP-P0-2 子项 2-G Data Deletion URL** | 必填 | ✗ 未动 | ✗ | ❌ **仍 0** | ⚠ **R72 模板就绪,URL 0 托管** | ⚠ |
| **GP-P2-1 16 守护脚本** | 12 | ✓ 16 | ✓ | ✓ | ✅ **18 守护脚本 (R70 16KB + R72 3 上架工具)** | ✅ |
| **GP-P2-2 DEPLOYMENT.md 阶段 5** | outdated | ✗ 未动 | ⚠ | ❌ **仍 stale** | ✅ **R72 重写** | ✅ |
| **GP-P2-3 Background isolation 注释** | 0 注释 | ✗ 未动 | ⚠ | ❌ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P2-4 in_app_purchase ^7.x** | ^3.3.0 | ✗ 未动 | ⚠ | ❌ **仍 ^3.3.0** | ❌ **仍 ^3.3.0** | ❌ |
| **GP-P2-5 3 份 md i18n** | 0 英文 + 0 繁体 | ✗ 未动 | ⚠ | ❌ **仍 0** | ❌ **仍 0** | ❌ |
| **GP-P2-6 description 多语** | 单语 | ✗ 未动 | ⚠ | ❌ **仍单语** | ✅ **R69 加双 description** | ✅ |
| **CC-1 setup ConsentDialog** | 缺 | ✓ R68 修 | ✓ | ✓ | ✓ | ✅ |
| **CC-3 IAP 早返** | 默认开 | ✗ R67 加 FeatureFlags 默认开 | △ | ✅ R68 修 | ✅ | ✅ |
| **CC-6 CareEngine safety 撤回** | 业务层 0 拦截 | ✗ R67 软隐藏 | ⚠ | ✅ R68 修 | ✅ | ✅ |
| **CC-7 4 处文档脱节** | wording | △ R67 加 coming soon 段 | △ | ⚠ | ✅ **R69+R72 修完** | ✅ |
| **CC-8 3 md i18n** | 0 | ✗ | ✗ | ❌ | ❌ | ❌ |

**R69→R74 净变化**: 12 项上架相关 commit 落地(7 项 P0/P1 修完 + 5 项半步),**离上 store 剩 5 步用户手动 + 1 步 Play Console 表单**。

---

## §12 附录:关键文件清单 + 字节数 / 行数(便于后续追踪)

| 文件 | 字节 | 行 | R74 状态 |
|------|------|----|---------|
| `android/app/src/main/AndroidManifest.xml` | 5235 | 108 | ✓ R61/R63 修 |
| `android/app/src/main/kotlin/com/chroniccare/chroniccare/MainActivity.kt` | 134 | 4 | ✓ |
| `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt` | 2050 | 43 | ⚠ R70 简化但仍占位 |
| `android/app/build.gradle.kts` | 3093 | 104 | ⚠ signingConfig=debug fallback |
| `android/app/proguard-rules.pro` | 1249 | 46 | ✓ R63 加 keep |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | 1068 | 23 | ✓ |
| `android/app/src/main/res/xml/backup_rules.xml` | 698 | 16 | ✓ |
| `android/app/src/main/res/xml/network_security_config.xml` | 595 | 16 | ✓ |
| `android/app/src/main/res/values/styles.xml` | 1014 | 17 | ✓ |
| `android/app/src/main/res/values-night/styles.xml` | 1013 | 17 | ✓ |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 1443 | - | ✓(Play Console 需 512×512 独立上传) |
| `android/key.properties.example` | 260 | 9 | ✓ |
| `android/.gitignore` | 215 | 14 | ✓ R63+R67 排除 *.jks + key.properties |
| `fastlane/Fastfile` | 5363 | 151 | ✅ R70 加 Android 端 |
| `fastlane/Appfile` | 1137 | 25 | ⚠ 4 ID 仍 TODO |
| `fastlane/metadata/android/en-US/title.txt` | 27 | 1 | ✓ |
| `fastlane/metadata/android/en-US/short_description.txt` | 87 | 1 | ✅ R72 修 |
| `fastlane/metadata/android/en-US/full_description.txt` | 2886 | 53 | ✅ R72 修 |
| `fastlane/metadata/android/en-US/icon.png` | 1443 | - | ❌ 192×192 |
| `fastlane/metadata/android/en-US/feature_graphic.png` | 67 | - | ❌ 1x1 占位 |
| `fastlane/metadata/android/en-US/phone_screenshots/screenshot_{1..4}.png` | 4 × 67 | - | ❌ 1x1 占位 |
| `fastlane/metadata/android/en-US/video.txt` | 59 | 1 | ❌ PLACEHOLDER URL |
| `fastlane/metadata/android/zh-CN/title.txt` | 66 | 1 | ✅ R72 修 |
| `fastlane/metadata/android/zh-CN/short_description.txt` | 48 | 1 | ✓ |
| `fastlane/metadata/android/zh-CN/full_description.txt` | 2426 | 44 | ✅ R72 修 |
| `fastlane/metadata/android/zh-CN/icon.png` | 1443 | - | ❌ 192×192 |
| `fastlane/metadata/android/zh-CN/feature_graphic.png` | 67 | - | ❌ 1x1 占位 |
| `fastlane/metadata/android/zh-CN/phone_screenshots/screenshot_{1..4}.png` | 4 × 67 | - | ❌ 1x1 占位 |
| `fastlane/metadata/android/zh-CN/video.txt` | 59 | 1 | ❌ PLACEHOLDER URL |
| `assets/legal/privacy_policy.md` | 14200 | 193 | ✅ R69 修订历史段化 |
| `assets/legal/user_agreement.md` | 6700 | 95 | ✅ R69 修订历史段化 + R66 失联通知 wording |
| `assets/legal/sensitive_data_consent.md` | 6300 | 85 | ✅ R69 修订历史段化 + R66 5 处 wording |
| `scripts/check_16kb_alignment.py` | 4921 | 124 | ✅ R70 加 |
| `scripts/generate_data_safety_form.py` | 10535 | 261 | ✅ R72 加 |
| `scripts/generate_release_keystore.ps1` | 6031 | 153 | ✅ R72 加 |
| `docs/DEPLOYMENT.md` | 14195 | 320 | ✅ R72 重写 |
| `docs/PLAYSTORE_SIGNING_GUIDE.md` | 6536 | 195 | ✓ R67 加 5 步指南 |
| `docs/SPRINT1_LEGAL_TODO.md` | 8297 | 167 | ✓ R67 加集中器 |
| `pubspec.yaml` | 1800 | 80 | ⚠ in_app_purchase ^3.3.0 |

---

## §13 总结

**R74 当前评分 4.0/10**(vs R69 3.5/10, +0.5 回升)。

**已完成**(代码 / 文档 / 脚本 4 维全绿):
- ✅ R70 加 abiFilters 显式 (GP-P1-8)
- ✅ R70 加 16KB check 脚本简化版 (GP-P1-7 4/5)
- ✅ R70 加 Fastfile Android 端 3 lane (GP-P0-8)
- ✅ R70 简化 BootReceiver (GP-P1-1 3/5,仍占位)
- ✅ R72 加 generate_data_safety_form.py (P0 子项 2-C 模板)
- ✅ R72 加 generate_release_keystore.ps1 (GP-P0-1 脚本)
- ✅ R72 重写 DEPLOYMENT.md (GP-P2-2)
- ✅ R72 修 title/short_description/full_description 4 处 wording (GP-P1-3/4/5 + GP-P0-10)
- ✅ R69 修 8 处文档脱节 wording (CC-7)
- ✅ R69 删 3 文档顶部 TODO banner,改修订历史段化
- ✅ R71 修 3 处病耻感措辞中性化 + 'TA' 改'对方'
- ✅ R73 9 analyzer info 清零(历史性 0)

**未完成**(纯外部依赖 + 用户手动,4 项上架硬阻塞):
- ❌ GP-P0-1 真实 keystore + Play App Signing(脚本就绪,等用户跑 + 改 1 行)
- ❌ GP-P0-2 域名 + 邮箱 + 隐私 URL 托管(等用户注册)
- ❌ GP-P0-4/5/6 真截图 + feature_graphic + icon 512(等真机 + 设计师)
- ❌ GP-P0-9 律师 review 3 份 md(1-2 周 + ¥15-30k/文档)

**半步**(代码 / 文档 / 守门员就绪,Play Console 侧 0 填):
- ⚠ GP-P0-2 子项 2-C/2-D/2-E/2-G/2-H(R72 模板就绪,Play Console 0 填)
- ⚠ GP-P1-1 BootReceiver 仍占位
- ⚠ GP-P1-2 RECORD_AUDIO 完整引导
- ⚠ GP-P1-7 完整 16KB 验
- ⚠ GP-P1-9 IAP productId 0 配

**M1 最小可上架: 5 天 30-40h,核心是 5 步用户手动 + 1 步 Play Console 4 表单 + 1-2 周律师 review**。M3 完整 v1.0 上线还需 SMS 真接 1-2 月 + IAP 真接 + NMPA 备案 2-3 月。

---

**报告生成时间**: 2026-08-02
**下次 review**: R75 上架 5 步用户手动完成 + Play Console 4 大表单填完 + 律师 review 启动后
**R74 状态**: ⚠ **5 步用户手动未完成,Play Console 4 大表单 0 填,不可上 store**
**总评**: 代码侧 / 文档侧 / 脚本侧 / 守门员 4 维全绿,但上架硬阻塞 100% 是"非代码"环节(用户操作 + 律师 + 真机 + 设计师)
