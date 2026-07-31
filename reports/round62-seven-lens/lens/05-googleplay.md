# Lens 05 — Google Play Store 上架规范审查

> 视角:Google Play Console + Play Store Policy (2024-2026 健康类 / 医疗类 App)
> 范围:`android/app/` 平台代码 + `lib/main.dart` 启动链 + SMS 服务 + 隐私文档
> 评估时间:R61 (v0.25.0+1),目标发布日期 TBD (受外部法务/厂商审核制约)

---

## 0. 总评 (TL;DR)

| 维度 | 评分 | 一句话 |
|---|---|---|
| **目标 API 等级** | ✅ 达标 | targetSdk 34 已就绪,但 **2025-08 后必须升 35** |
| **权限最小化** | ⚠️ 8 个全部"必要",但 1 个需补理由 | RECORD_AUDIO / SCHEDULE_EXACT_ALARM / POST_NOTIFICATIONS 用途明确;USE_EXACT_ALARM 需 Play Console 二次声明 |
| **数据安全表 (Data safety)** | 🟡 部分失真 | "SMS 通知紧急联系人 = 数据分享"未在表里声明,会被下架 |
| **Account Deletion (2024-01 强制)** | ✅ 已实现 | `data_management_section._showClearAllDataDialog` 一键清库 + audio |
| **SMS 政策** | 🟠 **P0 阻塞** | `AliyunSmsProvider.send()` 仍 `throw UnimplementedError` — release 模式失联通知不可用,需真接 |
| **签名 / 签名配置** | 🔴 **P0 阻塞** | `build.gradle.kts:42` release 用 debug 签名 — 上架会被 Play 拒绝 |
| **AAB 强制 + 64-bit** | ✅ 达标 | Flutter 3.41.9 默认 AAB + arm64-v8a |
| **备份排除 (PII)** | ✅ 达标 | `backup_rules.xml` + `data_extraction_rules.xml` 已排除 chroniccare.sqlite / flutter_secure_storage / vent_audio / mood_audio |
| **Network Security (HTTPS 强制)** | ✅ 达标 | `network_security_config.xml` 禁 cleartext |
| **ProGuard / R8 keep 规则** | ✅ 完备 | 10 个 plugin keep 全覆盖 (含 sqlcipher / audioplayers / record / speech_to_text) |
| **隐私政策 URL** | 🟠 TODO | `privacy@chroniccare.app` 仍占位,GitHub Pages 链接未生成 |
| **医疗 App 特殊要求** | ✅ 已声明 | DEPLOYMENT.md §附录 A 提供 NMPA / HIPAA / GDPR / PIPL 4 份模板 |

**核心结论**:技术配置 90% ready,2 项 P0 阻塞(签名 + AliyunSms 真接),3 项 P1 必须上架前补完(隐私邮箱真邮箱 / Data safety 表 SMS 字段 / targetSdk 35 升级路径规划)。

---

## 1. P0 阻塞上架 (3 项)

### 1.1 🔴 release 签名仍是 debug keystore

**位置:** `android/app/build.gradle.kts:42`

```kotlin
release {
    // TODO 上架前必须改 release 签名 (keystore)
    signingConfig = signingConfigs.getByName("debug")  // ← debug 签名
    isMinifyEnabled = true
    isShrinkResources = true
    ...
}
```

**问题:** 上架 Google Play 必须用 release keystore 签名,且推荐开 **Play App Signing**(上传密钥 + 应用签名密钥分离)。当前 debug 签名 = Google 已知公开 key,Play Console 直接拒收。

**修复路径:**
1. `keytool -genkey` 生成 upload keystore
2. `android/key.properties` 存密码
3. 加 `signingConfigs.release { ... }` block
4. Play Console 启用 Play App Signing,把 upload 公钥上传
5. R61 TODO 注释删除

**估时:** 2-4h(含 CI secret 注入)。

---

### 1.2 🔴 AliyunSmsProvider 真接缺失

**位置:** `lib/core/data/services/sms_service.dart:155-161`

```dart
throw UnimplementedError(
    'AliyunSmsProvider.send() R55 真接 TODO — '
    '需 accessKey/secret/signName + 法务过审模板。\n'
    '完整 plan 见 docs/SMS_PROVIDERS.md §1。',
);
```

**问题:** release 模式 + 真实 provider(`AliyunSmsProvider` 是 `isProductionReady=true`)→ `validateForRelease` 不阻断 → 失联通知触发时 `send()` 抛 UnimplementedError → SafetyWatch 算 `smsFail` → 通知文案显示"通知发送失败"。**核心安全功能失联通知完全不可用**。精神心理患者 3 天未打卡,紧急联系人收不到通知 = **致命产品缺陷**。

**Play 政策影响:** Google Play "Health Apps Policy" 明确:App 描述宣传的功能必须能用。`DEPLOYMENT.md` 阶段 5 描述"漏 2 天没打卡,自动发邮件给紧急联系人" + 安全告警 push + "死亡 3 天通知家人"——失联通知是真接核心承诺,断连 = 虚假宣传,Play 会下架。

**修复路径:**
1. `pubspec.yaml` 加 `dio: ^5.0.0` + `crypto: ^3.0.0`
2. 法务过审"我已 N 天未打卡"模板(避用"病/药/死"等敏感词,2-3 次驳回)
3. `.env` 加 ALIYUN_ACCESS_KEY_ID / SECRET / SIGN_NAME / TEMPLATE_CODE(存 flutter_secure_storage 而非 dotenv)
4. 实现 HMAC-SHA1 签名 + POST https://dysmsapi.aliyuncs.com/ (5s timeout + 3 retry)
5. 跨境场景:海外号码走 TwilioSmsProvider,需 PIPL §38 跨境评估

**估时:** 4-6 周(含法务 1-2 月 + 阿里云 AccessKey 申请 + 模板审核)。

---

### 1.3 🟠 SMS Data safety 表字段未声明

**位置:** Data safety 表(Play Console 后台填)需手动声明,代码无对应配置。

**问题:** SMS 失联通知 = App 把用户昵称 + 失联天数发给紧急联系人手机号,经阿里云 SMS 网关。**这是数据"分享"**——按 Google Play Data Safety 政策必须:
- 声明"被分享的数据类型"(name / phone number / health info)
- 声明"接收方"(阿里云 SMS + 紧急联系人手机号)
- 声明"目的"(safety notification)
- 声明"传输是否加密"(HTTPS 强制,✅ 已配)
- 声明"用户可否撤回同意"(✅ 隐私政策 §4 + settings 撤回勾选)

**当前 PR61 CHANGELOG 显示 R61 已加 SMS provider 抽象层 + 跨号段路由 plan,但 Data safety 表**不会自动同步**——必须人工在 Play Console 后台填。**

**修复路径:**
1. Play Console → Data safety form → 勾选 "This app shares data with third parties"
2. 列出:
   - Personal info → User IDs (用户昵称) → Emergency contact SMS
   - Health & fitness → Health info (失联天数作为健康推断信号)
   - Personal info → Phone numbers (紧急联系人)
3. 接收方:Aliyun Cloud / Twilio (按真实 provider 切换)
4. 用途:Safety notifications
5. 数据是否加密传输:Yes
6. 用户可否删除:Yes (设置页清除数据)

**估时:** 1-2h(后台填表)。

---

## 2. P1 上架前必须补完 (5 项)

### 2.1 🟠 targetSdk 35 升级路径 (Android 15)

**当前:** `compileSdk = flutter.compileSdkVersion` (Flutter 3.41.9 默认 34) / `targetSdk = flutter.targetSdkVersion` (34)

**政策时间线:**
- 2024-08-31: targetSdk 34 强制
- **2025-08-31: targetSdk 35 (Android 15) 强制**(原计划 2024 H2,Google 推迟)

**风险:** v1.0 计划若在 2025-08 之后发,会被 Play Console 拒。需在 v0.26 / v0.27 规划升级。

**影响点 (Android 15 已知 breaking):**
- `foregroundServiceType` 必须显式声明(本项目未用 FGS,可能无影响)
- 边到边 (edge-to-edge) 默认强制
- 16KB page size (部分插件需更新 native .so)
- `BACKUP_SERVICE` 默认禁用(本项目 backup_rules.xml 已显式 exclude,可能无影响)

**修复路径:** 下一 round 升级 `flutter.compileSdkVersion` / `flutter.targetSdkVersion` → 35,跑全测试 + 手测国产 ROM 通知链路。

---

### 2.2 🟠 Privacy email 占位

**位置:** `assets/legal/privacy_policy.md:111,123,152`

```markdown
- 个人信息保护负责人:`privacy@chroniccare.app`(**TODO 占位,上 store 前必须注册并替换为真实邮箱**)
```

**问题:** Play Console 必填 "Privacy Policy URL" + "Developer contact email"。`privacy@chroniccare.app` 邮箱未注册 = 邮件被退信 = Google 视为"无有效联系方式",可能下架。

**修复路径:**
1. 注册 `privacy@chroniccare.app`(阿里云邮箱 / 腾讯企业邮 / 自建 postmaster)
2. 替换 `assets/legal/privacy_policy.md` 3 处 TODO
3. Play Console 后台填邮箱
4. 设置页 footer 链接加"联系我们"按钮

**估时:** 1h(含 DNS 解析 + 邮箱配置)。

---

### 2.3 🟡 USE_EXACT_ALARM Play Console 声明

**位置:** `AndroidManifest.xml:28`

```xml
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
```

**政策:** Android 14 (API 34) 起,USE_EXACT_ALARM 只能用于"alarm clock / calendar"类 App,且必须在 Play Console 后台填写 **"Use of USE_EXACT_ALARM" 表单**说明用途(精确到推送场景)。本项目用精确闹钟推用药提醒 — **勉强算"calendar reminder"**,但 Play 审核员主观判断可能打回。

**风险:** 被打回后要么改用 SCHEDULE_EXACT_ALARM(用户可拒授,提醒可能漏),要么提供"为何不降级"说明。

**修复路径:** Play Console → App content → Permissions → USE_EXACT_ALARM 用途填 "Medication reminders (medical app)" + 截屏说明,若审核被拒再降级 SCHEDULE_EXACT_ALARM + 准备 OEM 自启动引导 fallback。

---

### 2.4 🟡 Phone 归属地路由在 SMS 接入后必须做

**位置:** `lib/core/data/services/sms_service.dart:153-154`

```dart
// 跨境 PIPL §38:
// - +86 大陆号段 → AliyunSms
// - +1/+44/+852 海外号段 → TwilioSmsProvider (需 Twilio 境内代理备案)
// - SmsService.send 入口加号码归属地路由 (R55+)
```

**问题:** R55+ TODO,真接 SMS 时必须做——否则 +86 号段发 Twilio = 失败,或 +1 号段发阿里云 = 失败 / 拒发。

**修复:** 加 `PhoneNumberRegion.detect(phone)` helper,`SmsService.send` 入口按号段路由。

---

### 2.5 🟡 "Account Deletion" 路径走"清除全部数据" — 需 Play Console 配 URL

**位置:** `lib/presentation/pages/settings/widgets/data_management_section.dart:290-340`

```dart
Future<void> _showClearAllDataDialog(...) async {
    ...
    await db.clearAllUserData();
    final audioDeleted = await ventAudio.deleteAllWithRetry();
    ...
}
```

**实现现状:** ✅ 已有"清除全部数据"功能(等价于 Account Deletion,本项目无账号系统,数据=账号)。

**Play 政策 (2024-01 强制):** Account Deletion 必须满足:
- App 内一键删除 ✅ (现有 `_showClearAllDataDialog`)
- **Web URL**(Play Console 后台填"Data deletion URL"),让 Play 审核员从外部也能验证删除路径 ❌

**修复:** Play Console → App content → Data safety → "Data deletion" 填 `https://chroniccare.app/data-deletion`(或在隐私政策页加章节),并附"卸载 App = 立即清除所有本地数据"声明。

---

## 3. P2 推荐优化 (非阻塞,但建议)

### 3.1 `requestLegacyExternalStorage` + `enableOnBackInvokedCallback` 注释说加但未加

**位置:** `AndroidManifest.xml:8-11` 注释 / application 标签 `:39-45`

```xml
<application
    android:label="慢病管家"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules"
    android:networkSecurityConfig="@xml/network_security_config">  <!-- 缺 2 项注释里提到的属性 -->
```

**注释承诺 (line 10-11):**
- `android:requestLegacyExternalStorage` (Android 10 兼容) — **本项目 SQLCipher 用 getApplicationSupportDirectory,不用外部存储,可加可不加**
- `android:enableOnBackInvokedCallback` (Android 13 预测式返回) — **Flutter 3.41 引擎已支持,加 `targetSdk` 到 34 自动启用,无需 application 属性**

**建议:** 注释删除或同步到代码,避免 reviewer 困惑。

---

### 3.2 `compileSdk` 缺显式声明

**位置:** `build.gradle.kts:10-11`

```kotlin
compileSdk = flutter.compileSdkVersion
ndkVersion = flutter.ndkVersion
```

**优点:** 跟 Flutter SDK 版本绑定,Flutter 升 3.42 自动升 compileSdk 到 35。
**风险:** Flutter 3.41.9 的 `flutter.compileSdkVersion` 是 34(实证),若团队后续用 `fvm install 3.42` 自动升 35,需全 native 插件同步重测。

**建议:** 加注释说明依赖关系,或显式写 `compileSdk = 34` 配合 CI check 阻止 35 静默升级。

---

### 3.3 `<queries>` 元素只有 PROCESS_TEXT

**位置:** `AndroidManifest.xml:81-86`

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.PROCESS_TEXT"/>
        <data android:mimeType="text/plain"/>
    </intent>
</queries>
```

**建议:** 若 App 用 share_plus 分享数据给其它 App(导出 JSON 后分享到邮件/微信),应加 `<queries>` 块声明,Android 11+ package visibility 默认禁互相发现。

---

## 4. 医疗 App 特殊要求 (Health Apps Policy)

### 4.1 ✅ "非医疗器械"声明

**位置:** `docs/DEPLOYMENT.md:298-317`

`docs/DEPLOYMENT.md` 附录 A.1 完整提供 NMPA "非医疗器械" 声明模板(不诊断 / 不治疗 / 不监护 / 不申报),上架时建议做法务签字后转 PDF 上传 Play Console + App Store Connect。

**Play Console 后台:**
- "Health apps" 勾选
- 选 "Not a medical device"
- 上传 PDF 声明

### 4.2 ✅ HIPAA / GDPR 合规声明

**位置:** `docs/DEPLOYMENT.md:319-348`

A.2 (HIPAA 声明:本 App 不接收/维护/传输 PHI,所有数据本地 AES-256 加密) + A.3 (GDPR 声明:无跨境 + 无 cookie + 用户可在 App 内行使所有 GDPR 权利) 已成型。**但 A.2 HIPAA 是美国上架推荐,非必需**——App 不主动收集/传输 PHI,且全本地存储,Play 不会强制要求 HIPAA 合规声明。

### 4.3 ✅ IARC 问卷 (Content Rating)

**DEPLOYMENT.md:128-130:** "问卷(PEGI 12+ / ESRB T)" 暗示需在 Play Console 填 IARC 问卷。

**建议填法:**
- Category: Medical / Health & Fitness
- 是否有医疗建议:**No**(已声明非医疗器械)
- 是否有药物提醒:**Yes**(选 "medication reminders" / "personal health tracking")
- 暴力 / 性 / 赌博:全 No
- 用户生成内容:**No**(树洞文字不分享)
- IARC 自动给 **PEGI 12+ / ESRB T**

### 4.4 🟡 警告:App 名"慢病管家"含医疗暗示

**位置:** `AndroidManifest.xml:40` + `pubspec.yaml:2` description 含"精神心理患者吃药打卡 + 停药通知"

**风险:** "慢病管家" + "精神心理"在 Play Store 会被分类到"Medical",触发更严格的内容审核 + 可能被加 "Medical disclaimer" 标签。

**建议:** 短期不改名(国内已上架有用户),但 Play Store description 加显眼免责:"本 App 不提供医疗建议,不替代专业诊断与治疗"。

---

## 5. 风险矩阵 (汇总)

| # | 级别 | 项目 | 位置 | 估时 |
|---|---|---|---|---|
| 1 | **P0** | release 签名仍是 debug | `build.gradle.kts:42` | 2-4h |
| 2 | **P0** | AliyunSmsProvider 未真接 | `sms_service.dart:155` | 4-6 周 |
| 3 | **P0** | Data safety 表未声明 SMS 第三方分享 | Play Console 后台 | 1-2h |
| 4 | P1 | targetSdk 35 升级路径 (2025-08 强制) | `build.gradle.kts:10` | 下一 round |
| 5 | P1 | privacy@chroniccare.app 占位邮箱 | `assets/legal/privacy_policy.md:111,123,152` | 1h |
| 6 | P1 | USE_EXACT_ALARM Play Console 表单 | Play Console 后台 | 1-2h |
| 7 | P1 | SMS 号段路由(跨境) | `sms_service.dart:153` | 4-8h |
| 8 | P1 | Account Deletion Web URL | Play Console 后台 | 1h |
| 9 | P2 | 注释 vs 代码不一致 (requestLegacyExternalStorage) | `AndroidManifest.xml:8-11` | 5min |
| 10 | P2 | 医疗 App disclaimer 在 description 显眼 | Play Store listing | 30min |
| 11 | P2 | `<queries>` 补充 share intent | `AndroidManifest.xml:81` | 10min |

**上架最小可执行集:** P0-1 (签名) + P0-2 (SMS 真接) + P0-3 (Data safety) + P1-2 (邮箱) + P1-6 (USE_EXACT_ALARM 表单) + P1-8 (Deletion URL)。**总估时 6-8 周**(SMS 真接依赖外部法务 + 阿里云审核是瓶颈)。

---

## 6. 决策记录 (建议)

| 决策 | 原因 |
|---|---|
| **启用 Play App Signing** | 丢 keystore = 永远不能更新 App,Play App Signing 把上传 key + 签名 key 分离,丢上传 key 还能用 Google 找回 |
| **Data safety 表 100% 透明声明** | Google 用机器 + 人工双重审核 App 描述 vs 实际数据流,任何"隐瞒"会下架(参考 2023 批量下架事件) |
| **不删 RECORD_AUDIO 权限** | 树洞语音 + 情绪语音日记是真核心功能,放弃会砍半产品价值 |
| **不删 SCHEDULE_EXACT_ALARM** | 替代方案 `setRepeating` 漂移 5-10 分钟,精神心理患者漏 5-10 分钟等于失联通知失效,人命关天 |
| **Data deletion URL 用"卸载 App = 清除"声明** | 既然 0 云端,卸载 = 删除,比要求"web 表单"更符合产品现实 |

---

## 7. 参考 (Google Play 政策链接)

- Data safety form: https://support.google.com/googleplay/android-developer/answer/10787469
- Account Deletion: https://support.google.com/googleplay/android-developer/answer/13326859
- Health Apps Policy: https://support.google.com/googleplay/android-developer/answer/10065487
- Permissions Policy: https://support.google.com/googleplay/android-developer/answer/9888070
- Sensitive Permissions (SMS / Call Log): https://support.google.com/googleplay/android-developer/answer/9047303
- USE_EXACT_ALARM 表单: https://support.google.com/googleplay/android-developer/answer/16453421
- targetSdk 35 时间线: https://developer.android.com/google/play/requirements/target-sdk

---

**审查员结论:** 技术配置(权限 / 备份 / 网络安全 / ProGuard)已 100% ready,**3 个 P0 必须上架前解决**(签名 + SMS + Data safety 表),其中 SMS 真接是外部法务/阿里云审核的瓶颈,估 1-2 月。本 Lens 不重复 4-7 (emil / superpowers / 隐私 / 架构) 视角,只专注 Play 政策盲点。
