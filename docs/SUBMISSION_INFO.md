# 上架前必填信息 Checklist (v0.31.1+)

> **来源**: P0-01 修复（`docs/audit/2026-08-10-r108-revisit/lens/04-appstore.md` P0-004 / `docs/audit/2026-08-11-cleanup/05-appstore.md` BUG-1）
> **状态**: 4 个 TODO 占位已改为清晰 placeholder（`[REPLACE_BEFORE_APPLE_REVIEW: ...]`），上架前**必须**替换为真实信息
> **修复 commit**: 0.31.1 round 1 P0-01

## 背景

Apple App Store Connect 提交时，`fastlane/metadata/ios/review_information/` 下的文件是**审核团队联系的官方信息**。当前 4 个文件（`first_name.txt` / `last_name.txt` / `email_address.txt` / `phone_number.txt`）是 `TODO:` 字符串字面值：

- `fastlane` 上传时会**直接把这 4 个 `TODO:` 字符串字面值**发到 App Store Connect
- Apple 收到 `"TODO: 真实邮箱"` / `"TODO: +86 真实手机号"` 后审核系统**卡住 / 邮件无法送达 reviewer** = **拒因**或**审核周期无限期延长**

R107 阶段半完成：4 文件是 R71 commit 创建时占位；v0.31.1 P0-01 阶段（本次修复）改为清晰 placeholder + 必填 checklist 文档；**真正填真实信息 = 上架前 1-2 周**（依赖域名注册 / 法务签字 / ICP 备案等外部流程，详见下文）。

---

## 1. Apple App Store Connect 必填（fastlane 上传）

### 1.1 reviewer 联系信息（`fastlane/metadata/ios/review_information/`）

| 文件 | 当前 | 上架前必填 | 状态 |
|---|---|---|---|
| `first_name.txt` | `[REPLACE_BEFORE_APPLE_REVIEW: 真实名字 (first name) — Apple App Store Connect 联系人名，上架前必填真实信息]` | 真实**名**（first name）| ⏳ 等真实信息 |
| `last_name.txt` | `[REPLACE_BEFORE_APPLE_REVIEW: 真实姓 (last name) — Apple App Store Connect 联系人姓，上架前必填真实信息]` | 真实**姓**（last name）| ⏳ 等真实信息 |
| `email_address.txt` | `[REPLACE_BEFORE_APPLE_REVIEW: 紧急联系邮箱 — 推荐 dev@chroniccare.app (域名注册后填入), 上架前必填真实信息]` | `dev@chroniccare.app`（**域名注册后**）| ⏳ 依赖 P0-16 域名 |
| `phone_number.txt` | `[REPLACE_BEFORE_APPLE_REVIEW: +86 中国手机号 — 上架前必填真实信息 (Apple 审核联系用, 必填可接收短信/电话)]` | `+86 138 XXXX XXXX`（真实可接收短信/电话）| ⏳ 等真实信息 |
| `notes.txt` | 当前 `v0.30.0+85` 详细 App Reviewer Guide（**保留不动**） | **P0-02 单独修**：版本号升 `v0.31.1+86` 同步 CHANGELOG | ⏳ 等 P0-02 |
| `demo_user.txt` | "This app does not require login..." | **保留不动**（正确）| ✅ |

**修复路径**：
1. 域名注册后创建 `dev@chroniccare.app`（P0-16）
2. 替换 4 文件为真实字符串（**不保留 placeholder**）
3. 跑 `python scripts/check_review_information_todo.py`（R108 P0-004 建议加的防回退守门员，等 v0.31.2+ 阶段加）

### 1.2 Apple 上架其他 P0（v0.31.1 阶段）

| 编号 | 项 | 文件 | 状态 | 预计修复阶段 |
|---|---|---|---|---|
| **P0-02** | `notes.txt` 同步发布版本号 | `fastlane/metadata/ios/review_information/notes.txt` | ✅ v0.32.0+142 已同步 + check_review_information_todo.py 守门员防回退 | — |
| **P0-03** | 锁屏通知 title 移除药名（PII 锁屏泄漏）| `lib/core/l10n/strings.dart:112,139` | ⏳ | v0.31.1 round 3 |
| **P0-04** | en-US description.txt 改写（"standardized questionnaires" → "guided self-reflection"，避免 5.1.3 抽审）| `fastlane/metadata/ios/en-US/description.txt` | ✅ v0.32 round 8 (R111 AS-17: en + zh-Hans + zh-Hant 三语中性化) | — |
| **P0-05** | 5 厂商 push 通道接入 | `android/app/build.gradle.kts` + 5 厂商 SDK | ⏳ | 1-2 月（外部）|
| **P0-06** | en-US "chronic mental health conditions (depression, anxiety, bipolar, PTSD, ADHD)" 措辞中性化 | `fastlane/metadata/ios/en-US/description.txt` | ✅ R110 round 6 已闭环 (grep 0 病名) | — |
| **P0-07** | `Info.plist` 加 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`（P0-03 HealthKit 集成时）| `ios/Runner/Info.plist` | ⏳ | R110+ 阶段 |
| **P0-08** | `fastlane/Appfile` apple_id / team_id / itc_team_id 占位替换 | `fastlane/Appfile:21-24` | ⏳ | 上架前 1 周 |
| **P0-09** | `ios/Podfile` Mac 首次重生成 + commit `Podfile.lock` | `ios/Podfile` | ⏳ | 首次 Mac build |
| **P0-10** | Xcode `DEVELOPMENT_TEAM` 设置 + `PRODUCT_BUNDLE_IDENTIFIER` 命名规范 | `ios/Runner.xcodeproj/project.pbxproj` | ⏳ | 首次 Mac build |
| **P0-11** | `Runner.entitlements` 加 `com.apple.developer.healthkit`（P0-07 时）| `ios/Runner/Runner.entitlements` | ⏳ | R110+ |
| **P0-12** | `scripts/register_ios_privacy_info.py` 真跑（PrivacyInfo.xcprivacy Xcode 注册）| `ios/Runner/PrivacyInfo.xcprivacy` | ⏳ | 上架前 1 周 |
| **P0-13** | iOS 截图 6+ 张（iPhone 6.7" + 5.5"）| `fastlane/metadata/ios/en-US/iphone_*/` | ⏳ | 设计师出图（外部）|
| **P0-14** | iOS LaunchImage 3 张 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | ⏳ | 设计师出图（外部）|
| **P0-15** | iOS AppIcon 1024×1024 重做 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | ⏳ | 设计师出图（外部）|
| **P0-17** | 5.1.3 (Kids Category / Medical / Health Apps) 抽审风险应对 | App Store Connect Health Information Disclosure Questionnaire | ⏳ | 上架前 1 周 |

### 1.3 iOS 实物资产（P0-13 / P0-14 / P0-15）

**当前状态**（R108 报告实测）：
- iOS 截图：**0 张**（目录空）
- iOS LaunchImage：**0 张**（`LaunchImage.imageset` 仅 1× 像素占位）
- iOS AppIcon：1024×1024 是 10932B（10KB，正常品牌 PNG 应 50-300KB，疑似占位）
- 其他 15 个 icon 尺寸（20×20 到 83.5×83.5）全部 282B-1674B 异常小

**修法**：设计师出图后替换 / `AppIcon Generator` 工具批量从 1 张 1024 导出。

---

## 2. Google Play Console 必填（fastlane 上传）

### 2.1 上架前 P0（v0.31.1 阶段）

| 编号 | 项 | 文件 | 状态 | 预计修复阶段 |
|---|---|---|---|---|
| **P0-15** | Android 截图 8 张（7" + 10" tablet）+ feature_graphic | `fastlane/metadata/android/en-US/phone_screenshots/` + `feature_graphic.png` | ⏳ | 设计师出图（外部）|
| **P0-16** | Android keystore 跑 `scripts/generate_android_keystore.sh` | `android/app/key.properties` + `android/chroniccare-release.keystore` | ⏳ | 上架前 1 周 |
| **P0-17** | Android short_description 87 字符超 80 限制 | `fastlane/metadata/android/en-US/short_description.txt` | ⏳ | v0.31.1 round 5 |
| **P0-18** | Android manifest `android:label` 改 `@string/app_name` | `android/app/src/main/AndroidManifest.xml:51` | ⏳ | v0.31.1 round 6 |
| **P0-19** | Android `setLockscreenVisibility(VISIBILITY_SECRET)`（R108 P0#3 半成品）| `lib/core/data/services/notification_service.dart` | ⏳ | v0.31.1 round 7 |
| **P0-20** | `<supports-screens android:largeScreens="true">` 平板适配声明 | `AndroidManifest.xml` | ⏳ | v0.31.1 round 8 |
| **P0-21** | `usesCleartextTraffic="false"` 显式 | `AndroidManifest.xml` | ⏳ | v0.31.1 round 9 |
| **P0-22** | `FOREGROUND_SERVICE` 权限（5 厂商 push 时）| `AndroidManifest.xml` | ⏳ | 1-2 月（外部）|
| **P0-23** | Data Safety Form（4 大类 28 子项）+ Health Apps Questionnaire | Google Play Console | ⏳ | 上架前 1 周 |
| **P0-24** | 16KB page size 验证（Google Play 2025-11-01 强制）| CI pipeline | ⏳ | 上架前 1 周（已有 `check_16kb_alignment.py` 守门员，需 CI 实跑）|

### 2.2 Android 实物资产（P0-15 / P0-16）

**当前状态**（R108 报告实测）：
- Android 截图：**67 字节占位**（`screenshot_1.png` 到 `screenshot_8.png`）
- feature_graphic：**67 字节占位**
- Android icon：**1443 字节 Flutter 默认 logo**

**修法**：设计师出图后替换 / 跑 `scripts/generate_android_screenshots.sh`（脚本就位但需真跑 + AVD 名 placeholder 替换）。

---

## 2.5 Play Console 表单文案 (R112)

> **来源**: `docs/audit/2026-08-13-r112-multi-lens/05-googleplay.md` GP-R112-05/06 + `04-appstore.md` P1-04 (AS-17)
> **状态**: 草稿就绪, 提交周复制粘贴进 console。3 表单 = Exact Alarm + Permissions Declaration (麦克风) + App Store 5.1.3 Health Disclosure。

### 2.5.1 Exact Alarm 申报 (Play Console → App content → Exact alarm)

**填写值**: Declare use of `SCHEDULE_EXACT_ALARM` → "Core functionality: 定时服药依从性提醒"

**申报理由 (英文, 粘贴用)**:

> ChronicCare's core functionality is medication adherence: users rely on scheduled medication reminders that must fire at the exact dose time set by their clinician (e.g., 8:00, 12:00, 20:00). An inexact alarm that drifts by minutes-to-hours would defeat the app's primary purpose and could cause missed doses. The alarm is user-configured and the app fully supports a graceful fallback: on Android 14+ it checks `canScheduleExactAlarms()`, and when permission is denied or revoked it degrades to inexact scheduling automatically (code already in place), so the user experience remains functional without the permission.

**技术侧降级已就绪**: `lib/core/data/services/reminder_dispatcher.dart:149-153,195-199` (canScheduleExactAlarms 检查 + inexact 兜底, R108 P0#2 闭环)。**被驳回即删权限走 inexact, 代码零改动**。

### 2.5.2 Permissions Declaration — Microphone (RECORD_AUDIO)

**填写值 (video/audio statement)**:

> The microphone is used only for the user's own voice notes in the private "vent space" and mood journal. Recordings are initiated by the user, stored locally on the device with AES-256 encryption, never uploaded, never shared with third parties, and never used for advertising or diagnosis. The user can delete any recording at any time from within the app.

**中文备份**:

> 麦克风仅用于用户主动录制"树洞"与情绪日记中的语音笔记。录音仅本地加密存储 (AES-256), 不上传、不与第三方共享、不用于广告或诊断。用户可随时在 App 内删除任何录音。

### 2.5.3 App Store 5.1.3 Health Information Disclosure Questionnaire 草稿

> **触发**: App 内含自我评估量表 + 严重度提示 + 危机资源 → 提交时几乎必然触发 Health 类问卷 (AS-17)。文案与 description 中性化口径一致。

| 问卷项 | 草稿回答 |
|---|---|
| App 是否属于医疗/健康 App? | Yes (mental wellbeing self-management) |
| 是否提供诊断/治疗? | No — self-assessment & tracking only |
| 是否为医疗器械 (FDA/NMPA/CE)? | No — wellness tool, no regulated functions |
| 健康内容来源 | Standardized public self-assessment scales, presented for self-monitoring only |
| 是否向用户提供医疗建议? | No — always advises consulting a qualified healthcare professional |
| 严重度提示如何措辞? | 温和提示 "结果仅供参考, 若持续困扰建议咨询专业人士", 非诊断结论 |
| 危机处理 | 提供各地区危机热线 (tel: 链接), 明确声明非危机干预服务 |
| 数据位置 | 100% on-device, SQLCipher AES-256, 零云端 |

**说明**: 问卷答案与 `scripts/generate_health_apps_questionnaire.py` 4 大块 disclosure 保持一致 (R112 已把 PHQ-9/GAD-7 点名改通用量表措辞 + 补录音声明)。

---

## 3. 域名 / 邮箱（外部依赖 P0-16）

### 3.1 域名注册

**目标**：`chroniccare.app`

**步骤**：
1. 注册商选 1 个（阿里云 / Cloudflare / Namecheap），约 ¥80-150/年
2. DNS 配置：
   - `chroniccare.app` → 主站（GitHub Pages / Vercel / Cloudflare Pages）
   - `privacy.chroniccare.app` → `https://chroniccare.app/privacy`（或 CNAME flat）
   - `support.chroniccare.app` → `https://chroniccare.app/support`
3. 部署 4 HTML：
   - `/privacy` → `assets/legal/privacy_policy.md` 渲染
   - `/user-agreement` → `assets/legal/user_agreement.md` 渲染
   - `/sensitive-data-consent` → `assets/legal/sensitive_data_consent.md` 渲染
   - `/support` → 简单 `support.html`（邮件 + FAQ）
4. ICP 备案（**国内服务器**）：7-20 天；走 Cloudflare Pages 海外节点可免 ICP（国内访问慢）

### 3.2 邮箱注册（域名注册后）

| 邮箱 | 用途 | 优先级 |
|---|---|---|
| `dev@chroniccare.app` | Apple App Store Connect reviewer 联系 + fastlane review_information email_address.txt | P0（v0.31.1 上架前）|
| `privacy@chroniccare.app` | Data Subject Access Request (DSAR) 邮箱（PIPL §38 强制）| P0 |
| `support@chroniccare.app` | Apple/Google 用户支持邮箱 + fastlane support_url 关联 | P0 |
| `legal@chroniccare.app` | 法务联系 + 3 法务 md 文档顶部"联系邮箱" | P1 |

**fastlane URL 文件替换**（P0-08 / P0-16）：
- `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` → `https://chroniccare.app/privacy`
- `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` → `https://chroniccare.app/support`
- `fastlane/metadata/android/{en-US,zh-Hans,zh-Hant}/` 同样

**内部文档**（`assets/legal/*.md`）顶部加 `**正式发布 URL**: https://chroniccare.app/...` 标识。

---

## 4. ICP 备案（中国法律实体，外部依赖）

- **必要性**：国内服务器托管 + 中国大陆 App Store 审核
- **周期**：7-20 天（主体网站备案）+ 7 天（公安备案）
- **主体**：中国法律实体（公司 / 个体工商户）
- **负责人**：法务 / 行政
- **阻塞**：无中国法律实体 = 必须走 Cloudflare Pages 海外节点 / Apple 美国区 + Google Play 海外区

---

## 5. 法务过审（外部依赖，P0-of-P0）

3 份法律文档 v0.22 草稿（`assets/legal/privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md`）+ 2 份元信息（`DEPLOYMENT.md` / `MEDICAL_DISCLAIMER.md` / `WHITEPAPER.md`），需执业律师签字：

| 文档 | 现状 | 必改 |
|---|---|---|
| `privacy_policy.md` | v0.22 草稿，标注"未经律师过审" | 律师签字 + 删"草稿" + 删 v0.28+ TODO 段 + 加 chroniccare.app URL + HealthKit 章节（接 P0-07 时）|
| `user_agreement.md` | v0.22 草稿 | 律师签字 + 删"草稿" + 删定价段（v1.0.0+147 已完成, 永久免费）|
| `sensitive_data_consent.md` | v0.22 草稿 | 律师签字 + 删"草稿" + 树洞录音部分"当前未加密"改"已加密 (AES-256, 2026-07 起启用)" |
| `DEPLOYMENT.md` | R72 spzh 部分修正 | 律师复审敏感措辞 |
| `MEDICAL_DISCLAIMER.md` | v0.22 草稿 | 律师签字 + 加 NMPA 监管声明 |
| `WHITEPAPER.md` | v0.22 草稿 | 律师签字（对外宣传材料）|

**周期**：2-4 周（外部律师审核）
**阻塞**：上架前 P0 必做

---

## 6. 设计师实物资产（外部依赖）

| 资产 | 文件 | 规格 | 状态 |
|---|---|---|---|
| iOS 截图 6+ 张 | `fastlane/metadata/ios/en-US/iphone_6.7/` + `iphone_5.5/` | 6.7" 1290×2796 + 5.5" 1242×2208 | ❌ 缺 |
| iOS LaunchImage 3 张 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | iPhone XS / 8 Plus / 8 各 1 张 | ❌ 缺 |
| iOS AppIcon 1024×1024 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 1024×1024 ≥ 200KB 品牌 PNG | ⚠️ 10KB 疑似占位 |
| Android 截图 8 张 | `fastlane/metadata/android/en-US/phone_screenshots/` + `seven_inch_screenshots/` + `ten_inch_screenshots/` | 各分辨率（7" / 10" tablet 必填）| ❌ 67B 占位 |
| Android feature_graphic | `fastlane/metadata/android/en-US/feature_graphic.png` | 1024×500 | ❌ 67B 占位 |
| Android icon | `fastlane/metadata/android/en-US/icon.png` | 512×512 | ❌ 1443B Flutter 默认 |

**修法**：
- 设计师出图 → 替换上述路径文件
- iOS AppIcon 可用 `AppIcon Generator` 工具批量从 1 张 1024 导出其他 15 尺寸
- 脚本就位但未跑：`scripts/generate_android_screenshots.sh`（AVD 名 placeholder 需替换）

---

## 7. 当前 commit 修复内容（P0-01）

```
fastlane/metadata/ios/review_information/first_name.txt
fastlane/metadata/ios/review_information/last_name.txt
fastlane/metadata/ios/review_information/email_address.txt
fastlane/metadata/ios/review_information/phone_number.txt
docs/SUBMISSION_INFO.md
```

**commit 风格**：`0.31.1 round 1: P0-01 修 review_information 4 TODO 占位 + 写 SUBMISSION_INFO.md checklist (AppStore BUG-1)`

---

## 8. 后续 P0 路线图

v0.31.1 阶段（1-2 周内）：
- P0-02 notes.txt 版本号同步
- P0-03 锁屏通知 title 药名移除
- P0-04 en-US description 措辞中性化
- P0-17 / P0-18 / P0-19 / P0-20 / P0-21 Android manifest 系列

v0.31.2 阶段（1-2 月内）：
- 域名注册 + 4 邮箱创建 + 4 HTML 部署
- 设计师出图（iOS 截图 / LaunchImage / AppIcon / Android 截图 / feature_graphic）
- 法务 6 文档过审
- 上架前 1 周：Apple ID / Team ID / keystore / PrivacyInfo 注册 / Data Safety 填表

R109+ 阶段：
- 5 厂商 push SDK 接入
- HealthKit 接入（可选）
- 鸿蒙 / OpenHarmony 适配（可选）

---

## 9. 参考

- R108 报告: `docs/audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md`
- R108 AppStore 视角: `docs/audit/2026-08-10-r108-revisit/lens/04-appstore.md`
- R108 GooglePlay 视角: `docs/audit/2026-08-10-r108-revisit/lens/05-googleplay.md`
- STOREFRONT_RELEASE_SOP: `docs/STOREFRONT_RELEASE_SOP.md`
- VERSION_1.0_PLAN: `docs/VERSION_1.0_PLAN.md` (R108 路线图)
- DEPLOYMENT: `docs/DEPLOYMENT.md` (R72 修正 + 当前部署步骤)
- AGENTS.md 18 守门员: `AGENTS.md` (R107 cleanup 阶段 18 = 17 .py + 1 .dart)
