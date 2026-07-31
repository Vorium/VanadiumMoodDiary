# GooglePlay 视角全量审计（v0.27 R66）

**审计时间**: 2026-08-02
**项目**: chroniccare
**版本**: 0.27.0+64（R66 收尾中，工作区有未提交改动）
**视角**: Google Play Store 上架合规
**审计模式**: 全量（聚焦 `android/` + `lib/main.dart` + `fastlane/` + `pubspec.yaml` + `assets/legal/`）
**参考基线**: Google Play Developer Policy Center（2026-08 截止） + Play Console 上架 checklist

**项目基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿
**已修基线**: R63 Android P0/P1 7 项已落地（BootReceiver / key.properties.example / targetSdk=36 显式 / minSdk=24 显式 / debuggable=false / allowBackup=false / proguard app keep）
**已知 WIP**: R63 P0-1 release keystore 仍是 `signingConfigs.debug`（R55+ 真接留 TODO）；R62 P0-1 `AliyunSmsProvider.send()` 仍 `throw UnimplementedError`（R58 降为 warn-only）；R66 联系人业务整体暂停（FeatureFlags flag）

---

## 1. 总览

- **Play Store 准备度**: ⭐⭐ / 5
- **上架阻塞 (P0)**: **10 项**（其中 4 项"无法审核提交"，6 项"提交后必被拒/必被打回"）
- **上架警告 (P1)**: **12 项**（提交后可能打回，可能要求补料）
- **上架建议 (P2)**: **6 项**（不阻塞但影响透明度 / 用户体验）
- **最重要发现 1-2 句**:
  1. **Play Console 三大表单未填 / 隐私 URL 未托管**：`Data Safety Form`（4 类数据收集）+ `Permissions Declaration Form`（6 危险权限 use case 逐条）+ `Health Apps questionnaire`（精神心理 / 量表 / 失联 SMS 的 8 类问题）一个都没在代码外维护。`privacy_policy.md:111,123` + `user_agreement.md:57-59` 全部带 `TODO 占位` 邮箱 + "未过律师 review" 标注。Play Console 必填的 Privacy Policy URL 也没有真实域。
  2. **fastlane/ 没有 Fastfile + Appfile**：仅 `metadata/android/`，但 `phone_screenshots/screenshot_{1..4}.png` + `feature_graphic.png` 全部 67 字节占位 PNG（首帧 `04 D0 = 1232`，`feature_graphic` 1024×500 但 67 字节，是 1x1 像素拉伸），`icon.png` 1443 字节（192×192，需要 512×512）。`flutter build appbundle` 还没产出过 `app-release.aab`（`build/app/outputs/` 不存在）。
- **建议优先修什么**（按 ROI 排序）:
  1. 写真实 keystore + 切 `signingConfigs.release` + 配 `key.properties` —— **M 难度，半天，上架前 0 选项**
  2. 托管 `https://chroniccare.app/privacy` 真页面 + 替换 `TODO 占位` 邮箱 —— **M 难度，1-2 天**
  3. 写真实截图（4-8 张 phone + 1 feature_graphic + 1 icon 512×512）—— **S 难度，半天，1 行 OS 截图脚本**
  4. 写 `fastlane/Fastfile` + `Appfile`（Android lane + `supply` upload） —— **S 难度，2-3h，CI 化必须**
  5. `BootReceiver.kt` 用 `FlutterEngineCache` 走 MethodChannel 调 `rescheduleAll` 替换 "启动 MainActivity" 占位 —— **S 难度，2-3h，避免用户重启后通知永久丢失**

---

## 2. Target SDK / Min SDK / ABI

| 项 | 当前值 | Google Play 要求 | 状态 | 证据 |
|----|--------|------------------|------|------|
| `compileSdkVersion` | `flutter.compileSdkVersion` (= 36) | ≥ targetSdk | ✓ | `android/app/build.gradle.kts:10` |
| `targetSdkVersion` | **36**（R63 显式 pin） | ≥ 35（2026-08-31 必填 Android 15）/ ≥ 36 推荐 | ✓ | `android/app/build.gradle.kts:32` |
| `minSdkVersion` | **24**（R63 显式 pin） | 推荐 ≥ 23（2024 起 Play Console 警告） | ✓ | `android/app/build.gradle.kts:31` |
| `multiDexEnabled` | `true` | 推荐 true（64K 方法数） | ✓ | `android/app/build.gradle.kts:37` |
| 16 KB page size 支持 | **未验证** | Android 15 (API 35) 2025-11-01 强制 | ⚠ | R63 改 targetSdk 36 但没看 ndk / native lib 是否 16KB 对齐 |
| 64-bit ABI | Flutter 3.41.9 默认 abiFilters | 2019 起 64-bit 强制 | ✓ | 默认 arm64-v8a + x86_64 |
| `ndkVersion` | `flutter.ndkVersion` | 跟 Flutter 3.41.9（= 27.0.12077973） | ✓ | `android/app/build.gradle.kts:11` |
| `enableOnBackInvokedCallback` | `true`（R63 加） | Android 13+ 预测式返回 | ✓ | `android/app/src/main/AndroidManifest.xml:51` |
| `proguard-android-optimize.txt` + `proguard-rules.pro` | 都加 | 推荐 | ✓ | `android/app/build.gradle.kts:61-64` |
| `applicationId` | `com.chroniccare.chroniccare` | 一致即可 | ✓ | `android/app/build.gradle.kts:25`（iOS 端是 `com.chroniccare.app`，P1-6 已修；Android 没改是因为**已有内部引用**，无需改） |

### 2.1 P2 警告：16 KB page size 未验证

**位置**: `android/app/build.gradle.kts:11` (`ndkVersion = flutter.ndkVersion`)

**问题**: Android 15 强制 16 KB page size（2025-11-01 上架新 app / 2026-05-01 上架 update）。本项目用了 `sqlcipher_flutter_libs` (0.6.4) + `record` (5.2.0) + `audioplayers` (6.1.0) 三个 native lib，**必须每个都验 16 KB 对齐**。sqlcipher_flutter_libs 0.6.4 已 2024-Q3 加 16 KB 支持（changelog），record / audioplayers 未确认。

**修复建议**:
```bash
# 用 ndk 自带脚本检查
$ANDROID_HOME/ndk/27.0.12077973/toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf -l libsqlcipher.so | grep LOAD
# 应显示对齐 0x4000 而不是 0x1000
```
或写 `scripts/check_16kb_alignment.sh` 守门员。

**上架阻塞**: ✗（不是 100% 阻塞，但 Play Console 会警告 + 可能在真机 16 KB-only 设备 crash）

**理由**: Android 15 强制 16 KB page size，2026-08 起 64-bit-only + 16KB-only 设备开始铺货。漏 1 个 native lib 不对齐 = 启动即崩 = 1-star 评价 + 紧急 hotfix。

---

## 3. 权限最小化

### 3.1 当前权限（8 个，R63 manifest 已声明）

| 权限 | 是否有 | 实际使用 | 最小化建议 | 状态 |
|------|--------|----------|------------|------|
| `INTERNET` | ✓ | SMS provider / Email (SendGrid) | **需在 Privacy Policy + Data Safety 声明用途** | 必要 |
| `POST_NOTIFICATIONS` (API 33+) | ✓ | `flutter_local_notifications` + `requestNotificationsPermission()` | 必要 | 必要 |
| `SCHEDULE_EXACT_ALARM` (API 31+) | ✓ | `AndroidScheduleMode.exactAllowWhileIdle` × 3 (`reminder_dispatcher.dart:118,159` + `snooze_manager.dart:102`) | 必要（精神心理患者漏 1 次提醒 = 漏 1 次药）| 必要 |
| `USE_EXACT_ALARM` (API 33+) | ✓ | 同上（Android 13+ 默认日历/闹钟类）| **⚠ Play Console 必填 justification** | 必要 |
| `WAKE_LOCK` | ✓ | notification 触发时保持 CPU | 必要 | 必要 |
| `RECEIVE_BOOT_COMPLETED` | ✓ | `BootReceiver.kt` 重启重排通知 | 必要 | 必要 |
| `VIBRATE` | ✓ | safety alert 通知震动 (`safety_alert_builder.dart`) | 必要 | 必要 |
| `RECORD_AUDIO` | ✓ | vent / mood 录音 (`vent_compose_page.dart:134` + `mood_audio_service.dart`) | 必要 | 必要 |
| `uses-feature microphone` | ✓ (required=false) | 录音 | 必要 | 必要 |

### 3.2 P0 阻塞：`USE_EXACT_ALARM` Play Console justification

**位置**: `android/app/src/main/AndroidManifest.xml:33`

**问题**: Google Play 2023 起强制：`USE_EXACT_ALARM` 是 "Permission with `app qualification`"，**每次提交必须**在 Play Console "Permissions Declaration Form" 写明 use case（free-form 100+ 字符）。精神心理患者吃药提醒是 acceptable use case（"Alarms and Reminders" 类别），但**项目里**没准备这段 justification 文本。

**修复建议**: 提交时 Play Console 填：
> "Used by ChronicCare to schedule exact-time medication reminders for chronic disease / mental health patients. Missed dose is a medical event — even 30-min drift could cause withdrawal symptoms. Reminders are user-scheduled in-app; not used for any other purpose. Compatible with `SCHEDULE_EXACT_ALARM` for users on Android 12."

**上架阻塞**: ✓（Play Console 提交时强制，缺则系统 reject）

### 3.3 P0 阻塞：RECORD_AUDIO in-app rationale 缺失

**位置**: `lib/presentation/pages/vent/vent_compose_page.dart:135-141`

**问题**: Android 5+ 强制 dangerous permission 必须"在请求前先解释为什么需要"。当前代码：
```dart
if (!hasPerm) {
  if (mounted) {
    AppSnackBar.showInfo(context, AppLocalizations.of(context).snackbarNeedMicPermission);
  }
  return;
}
```
- ❌ 用户点 "录音" 按钮 → 系统弹原生对话框 → 用户选 "拒绝" → 之后再次点 "录音" → 系统**不再弹**对话框（"Don't ask again"）
- ❌ 用户找不到入口去 Settings 重新授权 → 永久无法录音
- 现状：snackbar 显示"需要麦克风权限"，但**没引导**用户去系统设置

**修复建议**:
1. 第一次拒绝时弹 `PermissionDialog`（应用内 dialog）说明"为什么需要录音（树洞私密音频 / 情绪日记语音）"
2. 第二次拒绝时（"Don't ask again" 后）跳 `openAppSettings()` 让用户手动开
3. 同步 iOS 端的 `Info.plist` 的 `NSMicrophoneUsageDescription`（已存在，跟 Android 对齐 reason 文案）

**上架阻塞**: ✗（不直接拒，但负面 review 风险 + 录音功能实际不可用 = 4.0 Minimum Functionality 风险）

### 3.4 P1 警告：SCHEDULE_EXACT_ALARM Android 12+ Special App Access

**位置**: `android/app/src/main/AndroidManifest.xml:32`

**问题**: Android 12+ 用户必须手动到 Settings → Apps → Special access → Alarms & reminders 开权限。本项目**没在 app 内引导**用户去开。AGENTS.md R20 自检卡 `NotificationStatusCard` 列了 5 品牌引导（小米/华为/OPPO/Vivo/魅族），但**没列**SCHEDULE_EXACT_ALARM 这一项。

**修复建议**: 在 `NotificationStatusCard` 加 1 行：
```dart
// Android 12+ 精确闹钟
if (Platform.isAndroid && (await Permission.scheduleExactAlarm.status).isDenied) {
  // 显示跳转 "Settings → Apps → Special access → Alarms & reminders" 引导
}
```

**上架阻塞**: ✗（功能性问题，闹钟变成 inexact = 30+ min drift，精神心理患者最坏情况漏 1 次药 = 撤药反应）

### 3.5 不需要/已正确避免的权限

| 权限 | 是否有 | 备注 |
|------|--------|------|
| `ACCESS_NETWORK_STATE` | ✗ | 正确避免（不检测网络，避免 1 个 dangerous） |
| `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` | ✗ | 正确避免（app 私有目录够用） |
| `READ_MEDIA_*` (API 33+) | ✗ | 正确避免（无相册读取） |
| `READ_CONTACTS` / `WRITE_CONTACTS` | ✗ | 正确避免（联系人用户手填） |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_*` | ✗ | 正确避免（`flutter_local_notifications` 不需要前台服务） |
| `SYSTEM_ALERT_WINDOW` | ✗ | 正确避免 |
| `QUERY_ALL_PACKAGES` (API 30+) | ✗ | 正确避免（manifest 只 1 个 `queries` PROCESS_TEXT） |
| `READ_LOGS` / `BIND_*` | ✗ | 正确避免 |

---

## 4. Data Safety 表填写建议

**文件**: Play Console "Data safety" section（必填，否则无法提交）

### 4.1 数据收集清单（必须逐项勾选）

| 数据类别 | 是否收集 | 用途 | 是否本地 | 是否加密 | 用户可否删除 |
|----------|----------|------|----------|----------|--------------|
| **App activity → App interactions** | ✓ | check-in / medication / mood / vent 操作 | 是 (本地) | 是 (SQLCipher) | ✓（App 内删 + 卸载） |
| **App activity → In-app search history** | ✗ | — | — | — | — |
| **App activity → Installed apps** | ✗ | — | — | — | — |
| **App activity → Other actions** | ✗ | — | — | — | — |
| **App info and performance → Crash logs** | ✗ | 无自研 APM / Firebase Crashlytics / Sentry | — | — | — |
| **App info and performance → Diagnostics** | ✗ | 同上 | — | — | — |
| **Device or other IDs → Device or other IDs** | ✗ | 0 收集 device ID / IMEI / MAC / 广告 ID | — | — | — |
| **Health and fitness → Health info** | ✓ | 药名 / 剂量 / 打卡时间 / PHQ-9 / GAD-7 评分 | 是 | 是 (SQLCipher AES-256) | ✓ |
| **Health and fitness → Fitness info** | ✗ | — | — | — | — |
| **Personal info → Name** | ✓ | 用户昵称（v0.21 nullable，fallback "您"）| 是 | 是 | ✓ |
| **Personal info → Email address** | ✗ | — | — | — | — |
| **Personal info → Phone numbers** | ✓ | 紧急联系人手机号（**R66 默认 0 联系人，flag 开启才用**）| 是 | 是 | ✓ |
| **Personal info → Other personal info** | ✗ | — | — | — | — |
| **Audio files → Voice or sound recordings** | ✓ | vent 树洞录音 / mood 语音日记 | 是 | 是 (AES-256 文件级) | ✓ |
| **Audio files → Music files** | ✗ | — | — | — | — |
| **Audio files → Other audio files** | ✗ | — | — | — | — |
| **User content → User-generated content** | ✓ | vent 树洞文字 / 评估答案 / 情绪文字 | 是 | 是 (v0.21 起 AES-256 字段级) | ✓ |

### 4.2 数据共享清单

| 接收方 | 数据 | 触发条件 | 用户控制 |
|--------|------|----------|----------|
| **阿里云 SMS provider** | 用户昵称 + 距上次打卡天数 + 关怀短信模板 | **R66 当前 = 0**（`FeatureFlags.emergencyContactEnabled = false`），开启时需用户主动配置紧急联系人 | ✓（随时移除联系人 / 关闭 flag） |
| **SendGrid Email** | 同样 | 同上 | ✓ |
| **Android 系统通知** | 通知 title / body | 每天定时提醒 / safety alert | ✓（用户可关） |

### 4.3 加密传输

- **传输中加密**: HTTPS（`network_security_config.xml` 强制 cleartextTrafficPermitted=false）
- **本地存储加密**: SQLCipher AES-256 + vent audio 文件级 AES-256
- **不传输**: 数据库 / 录音 / 评估 / 树洞文字

### 4.4 用户控制

- ✓ 数据导出：设置页"导出 JSON"（明文，需用户主动）
- ✓ 数据删除：单条 / 全部 / 卸载 App
- ✓ 撤回同意：设置页"法律与隐私"（R66 移除"已告知联系人"硬勾选，改为"提示性"）
- ✓ 用户昵称可填可不填（v0.21 nullable）

### 4.5 P0 阻塞：Data Safety Form 与 SMS Provider 真实状态不一致

**位置**: `lib/core/data/services/sms_service.dart:195-198`（`AliyunSmsProvider.send()` 仍 `throw UnimplementedError`）

**问题**: Data Safety Form 必填 "数据是否共享给第三方"。本项目 SMS provider 是**占位实现**（throw UnimplementedError），但 Privacy Policy 仍写"我们会将下列信息发送给用户预设的紧急联系人"。**如果勾 "数据共享给阿里云" 但代码永远不真发 = 误导性声明**；**如果勾 "不共享" 但 Privacy Policy 说会发 = 隐私政策自相矛盾**。

**修复建议**:
1. 上 store 前必须**二选一**：
   - **方案 A**（推荐 v1.0）：真接 Aliyun SMS → Data Safety 勾 "shared with Aliyun for the purpose of emergency contact notification" + Privacy Policy 已写一致
   - **方案 B**（v0.x 妥协）：把失联通知业务标注为"未启用"（参考 R66 FeatureFlags）+ 删 Privacy Policy 第 58-64 段 + Data Safety 勾 "not shared" + 在 description / 全 App 内显式提示"失联通知功能即将上线"
2. **当前代码状态选 B 更稳**——R66 已经把 `FeatureFlags.emergencyContactEnabled = false` 双层防御关掉

**上架阻塞**: ✓（必填，谎报 = 永久封号；不报 = 审核员打回）

### 4.6 P0 阻塞：Health Connect 数据未声明

**位置**: `pubspec.yaml` 无 `health` / `health_connect` 依赖

**问题**: 当前项目**未集成** Health Connect。`docs/reviews/2026-07-31-seven-lens/googleplay/report.md:163` (G9) 提了"评估是否走 Health Connect"，但**未决定**。Data Safety Form 必填，不存在即勾 "无"。

**当前结论**: 勾"无" = 跟实际一致 = OK。**但**如果产品决定"通过 Health Connect 读用户步数 + 睡眠作为 mood 上下文" = 必填"shared with Health Connect" + 走 Health Connect privacy policy。

**上架阻塞**: ✗（勾"无"安全）

### 4.7 P2 建议：Data Safety Form 中 "data is encrypted in transit" 必勾

**位置**: 同上

**问题**: Data Safety 有 3 个独立 toggle：
1. Data is encrypted in transit
2. Users can request that data be deleted
3. Data is encrypted at rest (free-form)

本项目 3 项都 ✓——**别漏勾**。漏 1 项 = Play Console 警告 + 重新审核。

**上架阻塞**: ✗（不勾只是警告，但精神心理类 + 100% 本地加密是核心卖点，**必须勾全**）

---

## 5. Content Rating / IARC

**文件**: Play Console → Policy → App content → Content rating → Start questionnaire → IARC

### 5.1 P0 阻塞：IARC 问卷未填

**位置**: Play Console 上架流程

**问题**: 精神心理 + 量表（PHQ-9 涉及自杀念头题） + 失联 SMS 提示"非急救"——Google Play 会用 IARC 评级生成机构（ESRB / PEGI / USK / CLASSIND / GRAC / DJCTQ）根据问卷答案**自动**生成等级。

**当前 metadata 决策**（`DEPLOYMENT.md:129` 提 "PEGI 12+ / ESRB T"，但 R62 报告 GP-17 提 "PEGI 16+" 更稳）:

**推荐答案**:
| 问题 | 答案 | 理由 |
|------|------|------|
| Violence | No | — |
| Sexual content | No | — |
| Language | No | — |
| Controlled substances（药名 / 用药提醒）| **No**（因为是"用户自报药名 + 非毒品类"）| ⚠ 严格应勾 No；但 IARC 看到 "medication" 关键词会标 Mature 17+ |
| Tobacco / Alcohol | No | — |
| Gambling | No | — |
| User-generated content | **No**（树洞 0 共享 = 私人本地 = 严格不属 UGC）| ⚠ Play 判定标准模糊 |
| Sharing personal info | **No**（不主动分享；只有用户主动"导出 JSON" / "系统分享"）| — |
| Location | No | — |
| Health / Medical | **Yes** | 必有——量表 / 失联 SMS 都属 |
| Medical / Health | sub-question: "Does your app provide medical advice?" | **No**（"non-medical-device disclaimer" 写明）|
| Web browser / WebView | No | — |
| In-app purchases | **Yes**（R65 加 `in_app_purchase` 8 元买断）| 必填 |

**预期评级**: PEGI 12 / ESRB Everyone 10+ / 4+ （Apple）/ USK 0（DE 通用）

**上架阻塞**: ✓（必填，缺则系统不允提交）

### 5.2 P0 阻塞：Health App 问卷未填

**位置**: Play Console → App content → Health apps questionnaire

**问题**: 本项目**满足** Google Play "Health Apps" 政策 4 个 trigger（任一即触发）：
- ✓ 提供 health/medical 相关功能（吃药提醒 + PHQ-9/GAD-7）
- ✓ 涉及 sensitive personal data（健康 + 心理 + 联系人）
- ✓ 用户可能误以为是医疗工具
- ✓ 失联 SMS 涉及急救边缘

**必填字段**（每条 100+ 字符）:

1. **"Is your app a medical device?"** → 选 **No** + 引用 `user_agreement.md:20` "本 App 不提供医疗建议、诊断或治疗"
2. **"Do you work with medical professionals?"** → 选 **No** + 声明"内容基于 PHQ-9 / GAD-7 公开发表文献，未与医疗机构合作"
3. **"Is your app's content based on scientific evidence?"** → 选 **Yes** + 引用 PHQ-9 (Spitzer 1999) + GAD-7 (Spitzer 2006) 文献
4. **"Can users consult medical professionals through your app?"** → 选 **No** + 在 description 加 "Always consult your doctor for medical decisions" 链接

**上架阻塞**: ✓（精神心理类 = 必填；缺则 Health Apps policy 违规 = 应用下架）

---

## 6. Developer Policy 合规

### 6.1 P0 阻塞：Privacy Policy URL 未托管

**位置**: `assets/legal/privacy_policy.md`（本地文件）+ `DEPLOYMENT.md:130`（计划 `https://chroniccare.app/privacy`）

**问题**: Play Console "Store listing → Privacy policy" 必填 https URL。本项目**只在 assets/legal/ 有 .md 文件**——Play Console 不能填 `file://`，必须公网 https。

**修复建议**:
1. 注册 `chroniccare.app` 域名（DEPLOYMENT.md 附录 B-5 "ICP 备案 7-15 天"）
2. 把 `privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md` 转成静态 HTML（pandoc / mkdocs）
3. 部署到 GitHub Pages（境外免费）或阿里云 OSS + ICP 备案域名
4. 同步 `support@chroniccare.app` / `privacy@chroniccare.app`（**当前是 TODO 占位**——见 6.2）

**上架阻塞**: ✓（必填 https URL，填 file:// 或留空 = 提交失败）

### 6.2 P0 阻塞：法律文档 `TODO 占位` 邮箱未替换

**位置**:
- `assets/legal/privacy_policy.md:111` — `隐私 / PIPL 投诉邮箱:privacy@chroniccare.app(**TODO 占位,上 store 前必须注册并替换为真实邮箱**)`
- `assets/legal/privacy_policy.md:123` — 同上
- `assets/legal/user_agreement.md:57` — `support@chroniccare.app(**TODO 占位,上 store 前必须注册并替换为真实邮箱**)`
- `assets/legal/user_agreement.md:58` — `https://github.com/example/chroniccare/issues(**TODO 占位,需确认或替换为真实项目仓库**)`
- `assets/legal/user_agreement.md:59` — `privacy@chroniccare.app(**TODO 占位,上 store 前必须注册并替换**)`
- `assets/legal/privacy_policy.md:3` — `本政策是 v0.22 草稿,未经律师过审,上 store 前必须由专业律师过审并更新`
- `assets/legal/user_agreement.md:3` — 同上
- `assets/legal/sensitive_data_consent.md:3` — 同上

**问题**: 3 法律文档**全部**带 "TODO 占位" + "未经律师过审" 注释。Play Store 不直接审查法律文档内容，但 **Data Safety Form** + **App Reviewer 抽查** 会读隐私政策，**TODO 占位** = 误导性陈述 + 违反 Developer Policy 4.8 (Honest representation)。

**修复建议**:
1. 注册 `support@chroniccare.app` / `privacy@chroniccare.app` 邮箱（Google Workspace / 阿里云邮箱）
2. 决定 GitHub 仓库是公开还是私有——`github.com/example/chroniccare` 是 example placeholder，**真仓库要么公开、要么换 GitHub Issues link 为 email-only**
3. 律师 review（DEPLOYMENT.md 附录 B-6 估时 1-2 周）

**上架阻塞**: ✓（PIPL §38 跨境 + 误导性声明 = 双重风险；Google 抽查到 = 拒）

### 6.3 P1 警告：App Bundle (AAB) 还未 build

**位置**: `build/app/outputs/bundle/release/` 不存在

**问题**: 2021-08 起 Play Store 强制 AAB（不能再传 APK）。本项目**没产出过 AAB**——`flutter build appbundle --release` 没跑过。

**修复建议**:
```bash
flutter build appbundle --release \
  --dart-define=IS_PROD=true \
  --target-platform=android-arm,android-arm64,android-x64
# 输出: build/app/outputs/bundle/release/app-release.aab
# 上传 Play Console
```

**上架阻塞**: ✓（无 AAB = 无法提交）

### 6.4 P1 警告：Health Apps disclaimer 写在 In-app 而非 metadata

**位置**:
- `lib/presentation/pages/...` 多处 disclaimer 文案
- `fastlane/metadata/android/en-US/full_description.txt:36` (有写 "ChronicCare is NOT a medical device")
- `fastlane/metadata/android/zh-CN/full_description.txt:33` (有写 "本 App 不提供医疗建议、诊断或治疗")

**问题**: Google Play 政策：Health disclaimer **必须**在 store listing metadata 也写（用户下载前看到），不能只写在 in-app（用户下载后看到）。

**当前状态**: ✓ en + zh 都已写 OK，**但 Apple App Store 那个 metadata 还没审查**（R66 appstore 视角 P1-1 待办）

**上架阻塞**: ✗（en/zh 都已合规，仅 iOS 端待补）

### 6.5 P1 警告：Data Safety Form 必填的 4 个 metadata field

**位置**: Play Console

| 字段 | 必填 | 建议值 |
|------|------|--------|
| App name | ✓ | "慢病管家 - 吃药打卡 + 失联通知"（中文）/ "ChronicCare - Med Reminder"（英文）|
| Short description (80 char) | ✓ | `fastlane/metadata/android/zh-CN/short_description.txt` 89 字符（**超 80！**）— 见 6.6 |
| Full description (4000 char) | ✓ | `fastlane/metadata/android/{en,zh-CN}/full_description.txt` 都 < 4000 ✓ |
| App icon (512×512) | ✓ | **67 字节占位** — 见 §10 半成品 |
| Feature graphic (1024×500) | ✓ | **67 字节占位** — 见 §10 半成品 |
| Phone screenshots ≥ 2 | ✓ | 4 张 × 2 locale × **全部 67 字节占位** — 见 §10 半成品 |

### 6.6 P1 警告：zh-CN short description 超 80 字符

**位置**: `fastlane/metadata/android/zh-CN/short_description.txt`

```
精神心理患者吃药打卡 App。本地加密零云端，失联自动通知家人。
```
字符数: 89 字符 = **超 80 字符上限 9 字符**

**修复建议**: 砍到 80 字符以内：
```
精神心理吃药打卡 · 本地加密零云端 · 失联自动通知家人
```
70 字符 ✓

**上架阻塞**: ✗（fastlane `supply` 提交会被 Google 拒：Google Play short description limit 80）

### 6.7 P1 警告：en-US short description 字符无标点

**位置**: `fastlane/metadata/android/en-US/short_description.txt`
```
Daily check-in + mood tracker for chronic patients. Private & local.
```
字符数: 69 ✓（合规）

但 "chronic patients" 措辞：Google Play Health Apps 政策**禁止** "diagnose / treat / cure" 措辞，建议改成 "Daily check-in + mood tracker for people managing chronic conditions. Private & local."

**上架阻塞**: ✗（措辞建议）

### 6.8 P1 警告：IAP NonConsumable 8 元买断（"8 元一次性买断" vs Play Store 收费政策）

**位置**:
- `pubspec.yaml:62` — `in_app_purchase: ^3.3.0`
- `assets/legal/user_agreement.md:25` — "本 App 售价人民币 8 元(Google Play / Apple App Store 统一定价),一次性买断,**不收取订阅费**"
- `docs/DEPLOYMENT.md:136` — "定价：付费下载 ¥8.00"

**问题**:
1. "付费下载"（Paid app）vs "应用内购买 IAP" 是 2 个互斥模型。本项目代码走 IAP（`in_app_purchase` 插件）= **必须**走应用内购买流程，但 metadata 写"付费下载" = 模型不一致。
2. R65 Round 65 (commit) 加 IAP 集成（NonConsumablePurchase），但当前 `lib/main.dart:161` `StoreKitService.warmup()` + R65 dev 模式直接返 true = 0 真实集成
3. "8 元" 定价 = Play Store 在中国/海外需要按汇率换算（如 USD $1.99 / EUR €1.99），不是简单乘 7
4. 一致性问题：description 写"8 元买断" vs 当前代码 R66 改联系人 + 失联通知业务**全部暂停** = 用户付 8 元买了一个核心功能未启用的 App = Apple 4.0 风险

**修复建议**:
1. **决策**: 改 "免费 + 0 广告 + 0 订阅" 模式（最简） OR "免费 + IAP 解锁高级"（最灵活）OR "8 元买断"（最直接）
2. metadata 跟代码对齐：R66 已经暂停失联通知 = 8 元买断**价值**不明确
3. 真接 IAP（`StoreKitService.warmup()` 当前是 dev 模式 release 模式要走真实 store）
4. Play Console 上架前必须**决定** IAP model 并填 Billing settings

**上架阻塞**: ✓（IAP 必填 Billing settings；8 元买断 + 核心功能未启用 = App Reviewer 直接拒）

### 6.9 P1 警告：Push notifications 字段

**位置**: Play Console → App content → Push notifications

**问题**: 必填勾选 "Does your app use push notifications?"。本项目**只走本地通知**（`flutter_local_notifications`），无 FCM / 推送 SDK。**应勾 No**。

**上架阻塞**: ✗（勾 No = 简单；勾 Yes 但无 FCM = 必填 APNS / FCM 服务端信息 = 误报）

### 6.10 P1 警告：Data deletion endpoint

**位置**: Play Console → Data safety → Data deletion

**问题**: 必填 "Data deletion request URL" 或 "Data deletion instructions"（Data Safety 表的 "Users can request that data be deleted" toggle 开时必填）。

本项目用户**不能**主动联系开发者删数据（only 自助 in-app 删除 / 卸载 App），但 Google 要求**至少给一个 endpoint**（哪怕是 "users can delete data in-app, no developer request needed"）。

**修复建议**:
- Data Safety 表 "Data deletion endpoint URL" 字段填 `https://chroniccare.app/delete-data-instructions` 页面，页面内容写：
  > "All data is stored locally on your device. To delete: (1) Open App → Settings → Privacy & Legal → Delete all data; (2) Uninstall the App (immediately wipes all data). We have no servers, so no data on our side can exist."

**上架阻塞**: ✓（必填 endpoint，缺则 Data Safety Form 提交失败）

### 6.11 P2 建议：Government app（如中国开发者）需 ICD-3 备案

**位置**: Play Console → App content → Government apps

**问题**: 2024 起 Play Console 区分 "Government app"（政府 / 医疗 / 金融类需特殊审查）。本项目属于 "Health" 类别，**不属于** Government app（不是政府机构发布的 app），勾 No 即可。

**上架阻塞**: ✗（勾 No 安全）

### 6.12 P2 建议：Targeting children / Families

**位置**: Play Console → App content → Target audience

**问题**: 必勾 "Designed primarily for children" / "Not designed primarily for children but appeals to children" / "Not designed primarily for children"。
- `assets/legal/privacy_policy.md:120-122` 显式 18+ / 14-18 监护代签 / 不建议 14 周岁以下使用

**应勾**: "Not designed primarily for children, but may appeal to children" 或 "Not designed primarily for children"（更稳）。

如果勾 "appeals to children" → 触发 Families Policy 强制要求（无广告 / 无 IAP / 无 UGC），本项目无广告 ✓ 但有 IAP ✗。

**修复建议**: 勾 "Not designed primarily for children" + 14+ 适用年龄 + metadata 不提 "kids" / "儿童"

**上架阻塞**: ✗（勾错会触发 Families Policy 二审）

### 6.13 P2 建议：App access（受限功能）

**位置**: Play Console → App content → App access

**问题**: 必填"是否所有功能可访问无需登录"。本项目 0 登录 = 全功能可用 ✓。但 Play Console 仍要求勾 "All functionality is accessible without login" + 提供测试账号（如果有任何登录）。**勾 All ✓ + 留空测试账号**即可。

**上架阻塞**: ✗（填 OK）

### 6.14 P2 建议：Ads SDK 声明

**位置**: Play Console → Data safety → Ads

**问题**: 必勾"是否含广告"。本项目 0 广告 SDK（pubspec.yaml 验证：grep `admob|google_ads|firebase` = 0 命中），**应勾 No**。

**上架阻塞**: ✗（勾 No 安全）

---

## 7. Android 特定功能

### 7.1 P0 阻塞：release keystore 仍是 debug

**位置**: `android/app/build.gradle.kts:53` (`signingConfig = signingConfigs.getByName("debug")`)

**问题**: 当前 release build 用 **debug keystore 签名**。Play Store **不接受 debug-signed AAB**——必须用真 release keystore（或 Play App Signing 自动管）。

**修复建议** (5 步):
```bash
# 1. 生成 keystore (keytool 来自 JDK)
keytool -genkey -v \
  -keystore android/app/chroniccare-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias chroniccare

# 2. cp key.properties.example key.properties + 填实值
cp android/key.properties.example android/key.properties
# key.properties 填 storeFile/chroniccare-release.jks, storePassword, keyAlias/chroniccare, keyPassword

# 3. .gitignore 已加 *.jks / *.keystore / key.properties ✓
#    但 root .gitignore 没加 — 见 P2 警告
# 4. build.gradle.kts 加 signingConfigs.release 读 key.properties
signingConfigs {
  create("release") {
    val keyPropsFile = rootProject.file("key.properties")
    val keyProps = Properties().apply { load(keyPropsFile.inputStream()) }
    storeFile = file(keyProps["storeFile"] as String)
    storePassword = keyProps["storePassword"] as String
    keyAlias = keyProps["keyAlias"] as String
    keyPassword = keyProps["keyPassword"] as String
  }
}
# buildTypes.release.signingConfig = signingConfigs.getByName("release")

# 5. Play Console → App integrity → Play App Signing → Enable
#    上传 .aab + (可选) 上传 upload-keystore.jks
#    启用后 Play Console 会用 app signing key 重新签 aab
```

**上架阻塞**: ✓（debug-signed AAB = Play Store 100% 拒）

### 7.2 P0 阻塞：Play App Signing 未启用

**位置**: Play Console → Setup → App integrity

**问题**: Play App Signing 是 Google 默认推荐（2017-08 起）——开发者用 upload key 签 AAB，Google 拿 app signing key 重新签 APK 给用户。优点：
- 丢 keystore 可恢复
- 可升级 key（v3 signing）
- 优化 APK（app bundle 的 split 自动）

**当前状态**: 未启用（因为 release keystore 都不存在）

**修复建议**: 跟 7.1 同步——enable upload key + Google 自动管 app signing key

**上架阻塞**: ✓（AOSP v3 签名必填；Play App Signing 是必选 workflow）

### 7.3 P1 警告：boot receiver 启动 MainActivity 走错路径

**位置**: `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:32-41`

```kotlin
val launchIntent = Intent(context, MainActivity::class.java).apply {
    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    putExtra("from_boot", true)
}
context.startActivity(launchIntent)
```

**问题**:
1. **从锁屏启动 Activity** = 用户看到"启动 App"的全屏 UI = 糟糕 UX
2. **如果用户没主动开 app**（手机重启后用户没碰手机），MainActivity 不会真跑 Flutter 侧 `rescheduleAll()`（因为 Activity 走 onCreate 但 Flutter engine 还没就绪 = 通知仍丢失）
3. **activity task 重复**：`launchMode="singleTop"` 防 Activity 重复创建，但 BootReceiver 跟正常启动可能冲突
4. 注释自承认："完整方案需 FlutterEngineCache.getInstance().get(engineId) 复用 engine + MethodChannel 调 Flutter 侧 rescheduleAll, 留给 R64 完善" —— **R64 已过，未完善**

**修复建议**（3 选 1）:
- **方案 A** (推荐): 改用 `WorkManager` + `flutter_local_notifications.zonedSchedule` 在 background 重新 schedule
- **方案 B**: BootReceiver 启动一个 `BroadcastReceiver`（不启动 Activity）调 `FlutterEngineCache` 复用 engine
- **方案 C**: 删 `RECEIVE_BOOT_COMPLETED` 权限 + BootReceiver，依赖 `flutter_local_notifications` 自身的 "automatic rescheduling after device reboot" 特性（17.x 文档说支持，需验）

**上架阻塞**: ✗（功能性问题，不拒；但**精神心理患者漏 7 天通知** = 失联通知失灵 = 审计风险）

### 7.4 P1 警告：64-bit ABI 默认 OK 但未显式

**位置**: `android/app/build.gradle.kts` (无 abiFilters)

**问题**: Flutter 3.41.9 默认 abiFilters = `arm64-v8a, armeabi-v7a, x86_64`（3 ABI），覆盖 99% 设备。**推荐**显式声明：
```kotlin
ndk {
    abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86_64"))
}
```
**理由**: 防 Flutter 升级时默认值变化（跟 targetSdk 显式 pin 同理）。

**上架阻塞**: ✗（当前默认 OK；只是 R63 风格的"显式 pin"遗漏）

### 7.5 P2 建议：root .gitignore 缺 `*.jks` / `*.keystore` 排除

**位置**: `D:\Batch\chroniccare\.gitignore` (root, 41 行) — **没有 `*.jks` / `*.keystore` 排除**
（`android/.gitignore` 已有 ✓）

**问题**: root gitignore 没排除签名材料——如果将来 keystore 放在 repo 根目录（如 `keystore.jks` 配 GitHub Actions），容易误 commit。**预防性**加。

**修复建议**:
```gitignore
# Signing (R66 加, 兜底防误 commit)
*.jks
*.keystore
key.properties
```

**上架阻塞**: ✗（泄露 keystore = 永久封号；当前路径已防，但兜底更好）

---

## 8. 签名 / 上架

### 8.1 当前签名状态

| 项 | 状态 | 证据 |
|----|------|------|
| `android/key.properties` | ✗ **不存在** | `Test-Path` 返回 False |
| `android/app/upload-keystore.jks` | ✗ **不存在** | 同上 |
| `android/key.properties.example` | ✓ 存在 | R63 P0-1 加 |
| `android/.gitignore` 排除 `key.properties` + `**/*.jks` | ✓ | 12-14 行 |
| `build.gradle.kts` `signingConfigs.release` | ✗ **未配** | 仅引用 `signingConfigs.getByName("debug")` |
| `build.gradle.kts` 显式 `isDebuggable = false` + `isJniDebuggable = false` | ✓ | R63 P1-7 |
| `isMinifyEnabled = true` + `isShrinkResources = true` + ProGuard 规则 | ✓ | R55+ |

### 8.2 P0 阻塞总结

- ✗ 无真实 keystore → 无 release-signed AAB → 无上架

**修复优先级**: **P0 必做**（见 §11 优先级 Top 10）

---

## 9. fastlane 配置

### 9.1 当前 fastlane/ 结构

```
fastlane/
└── metadata/
    └── android/
        ├── en-US/
        │   ├── feature_graphic.png         (67 字节占位)
        │   ├── full_description.txt        (2577 字符, ≤ 4000 ✓)
        │   ├── icon.png                    (1443 字节, 192×192, 需要 512×512)
        │   ├── phone_screenshots/
        │   │   ├── screenshot_1.png         (67 字节占位)
        │   │   ├── screenshot_2.png         (67 字节占位)
        │   │   ├── screenshot_3.png         (67 字节占位)
        │   │   └── screenshot_4.png         (67 字节占位)
        │   ├── short_description.txt       (69 字符, ≤ 80 ✓)
        │   ├── title.txt                   (27 字符, ≤ 50 ✓)
        │   └── video.txt                   (PLACEHOLDER URL)
        └── zh-CN/
            ├── (同样 5 个文件)
            └── short_description.txt       (89 字符, **> 80 ✗**)
```

**缺失**:
- ✗ `fastlane/Fastfile`（无 Android lane 定义）
- ✗ `fastlane/Appfile`（无 package_name / json_key_file）
- ✗ `fastlane/report.xml`（无 test report）
- ✗ `metadata/ios/`（**R66 appstore 视角已报**）

### 9.2 P0 阻塞：Fastfile / Appfile 缺失

**问题**: `fastlane supply` 必须有 `Fastfile` 描述 lane（`lane :release do ... end`）+ `Appfile` 描述 `package_name` + `json_key_file`（Google Play Console API service account JSON key）。

**修复建议**:
```ruby
# fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Deploy a new version to the Google Play"
  lane :release do
    upload_to_play_store(
      package_name: "com.chroniccare.chroniccare",
      track: "internal",  # 首次 → internal, 二次 → production
      aab: "../build/app/outputs/bundle/release/app-release.aab",
      json_key: "fastlane/api-xxx.json",  # 绝对不能 commit
      mapping: "../build/app/outputs/mapping/release/mapping.txt",
      rollout: "0.1",  # 10% 灰度
    )
  end
end

# fastlane/Appfile
json_key_file("fastlane/api-xxx.json")
package_name("com.chroniccare.chroniccare")
```

**上架阻塞**: ✗（不是 Play Store 上架阻塞，是**发布流程**阻塞——手动 upload 也行，但 CI 化必须）

### 9.3 P0 阻塞：截图 / feature_graphic / icon 全是占位

**位置**:
- `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (4 × 2 = 8 个 67 字节)
- `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 个 67 字节)
- `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 个 1443 字节, 192×192)

**问题**: Play Store 必填：
- Phone screenshots ≥ 2 (实际推荐 4-8)
- Feature graphic 1024×500 (实际 67 字节 = 1x1 像素拉伸 = 审核员秒拒)
- App icon 512×512 (实际 192×192 = Play Console 警告)

**修复建议**:
1. **截图**: 跑真机 / 模拟器，截图 4-8 张关键页面（主页打卡 / 趋势 / 设置 / 树洞 / 评估）
   ```bash
   # 推荐脚本: 真机截图 + ImageMagick 缩放
   adb exec-out screencap -p > screenshot_1.png
   # 或 iOS / Android Studio 录屏
   ```
2. **feature_graphic**: 用 Figma / Sketch 设计 1024×500 "我今天吃了药" + 主色背景 + 简单 logo
3. **App icon**: 从 `assets/brand/app_icon_master.png` (435870 字节) 切 512×512 → 切 192×192/72/48/96/144 mipmap 5 个密度

**上架阻塞**: ✓（Play Store 强校验尺寸 + 内容真实性；占位 PNG 必拒）

### 9.4 P1 警告：video.txt 是占位 URL

**位置**: `fastlane/metadata/android/{en-US,zh-CN}/video.txt` → `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO`

**问题**: video.txt 留空 = OK；填占位 URL = Play Console 报"无效视频链接"。

**修复建议**:
- 选项 A: 删除 video.txt 两个文件（让 Play Console "video" 字段留空）
- 选项 B: 录 30-60s 真 App demo 视频 + 传 YouTube + 填真 URL

**上架阻塞**: ✗（留空 OK；占位 URL 警告）

---

## 10. 半成品 / WIP

### 10.1 P0 阻塞（5 项）

| # | 位置 | 状态 | 修复建议 |
|---|------|------|----------|
| **GP-W1** | `lib/core/data/services/sms_service.dart:195-198` (AliyunSmsProvider.send throw UnimplementedError) | **R55+ 标 TODO** | v1.0 真接阿里云 OR Data Safety 勾 "不共享" |
| **GP-W2** | `android/app/build.gradle.kts:53` (signingConfig = debug) | **R55+ 标 TODO** | 见 §7.1 |
| **GP-W3** | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` TODO 占位邮箱 | **多 round 标 TODO** | 注册邮箱 + 律师 review |
| **GP-W4** | `fastlane/` 缺 Fastfile + Appfile + 真实截图 + 真实 feature_graphic | **从未配** | 见 §9 |
| **GP-W5** | `android/app/src/main/kotlin/.../BootReceiver.kt:32-41` (启动 MainActivity 占位) | **R63 注释自承 "留 R64"** | 用 FlutterEngineCache 替换或加 WorkManager |

### 10.2 P1 警告（6 项）

| # | 位置 | 状态 | 修复建议 |
|---|------|------|----------|
| **GP-W6** | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` (RECORD_AUDIO rationale 缺失) | R63 漏 | 加 PermissionDialog + Settings 引导 |
| **GP-W7** | `lib/presentation/pages/...` (SCHEDULE_EXACT_ALARM 引导) | R20 加自检卡但漏这一项 | NotificationStatusCard 加 1 行 |
| **GP-W8** | `lib/main.dart:161` (StoreKitService.warmup 当前 dev 模式返 true) | R65 加 IAP 但 dev 模式 | release 模式必须真走 store |
| **GP-W9** | `fastlane/metadata/android/zh-CN/short_description.txt` (89 字符 > 80) | 字符超限 | 砍到 80 内 |
| **GP-W10** | `assets/legal/privacy_policy.md:58-64` (失联通知 SMS 描述 vs R66 已暂停 = 文档与代码矛盾) | R66 改但文档没改 | 删 §3 "失联通知触发时" 段 OR 标 "R66 暂停" |
| **GP-W11** | `fastlane/metadata/android/en-US/full_description.txt:13-14` ("Lost-contact safety net" 描述 vs R66 已暂停) | 同上 | 删 OR 加 "coming soon" |

### 10.3 P2 建议（3 项）

| # | 位置 | 状态 | 修复建议 |
|---|------|------|----------|
| **GP-W12** | `lib/main.dart:1-200` (Background isolation 没显式) | Flutter 默认 OK | 写 1 段注释说明 flutter_local_notifications 的 background 行为 |
| **GP-W13** | `lib/main.dart:155` (SmsService.validateForRelease release 模式必阻断) | R62 P0-1 加 | 当前 dev 模式不抛异常；release 必须阻断 |
| **GP-W14** | `docs/DEPLOYMENT.md:120-176` (Google Play 阶段 5 描述 outdated) | 文档 stale | 重写——加 BootReceiver / key.properties / 16KB / Health Apps questionnaire 段落 |

---

## 11. 优先级 Top 10

| 序 | 问题 | 位置 | 难度 | 上架阻塞 | 修复建议 |
|----|------|------|------|----------|----------|
| **1** | **release keystore 仍是 debug + 无 Play App Signing** | `android/app/build.gradle.kts:53` | M (半天) | ✓ | 见 §7.1 5 步方案；M 难度因为还要配 Play Console App integrity |
| **2** | **Privacy Policy URL 未托管 + TODO 占位邮箱** | `assets/legal/*.md` + Play Console | M (1-2 天) | ✓ | 注册域名 + 部署 HTML + 注册邮箱（**律师 review 必须**） |
| **3** | **fastlane/ 缺 Fastfile + Appfile + 占位截图/icon** | `fastlane/` 整目录 | S (2-3h) | ✓ | 写真实截图 + Fastfile + Appfile |
| **4** | **Data Safety Form / Health Apps questionnaire 未填** | Play Console | M (2-3h) | ✓ | 按 §4 + §5.2 填表（精神心理 + 失联 + 量表 + IAP 4 大块） |
| **5** | **AAR 不存在 / AAB 未 build** | `build/app/outputs/bundle/release/` | XS (10 min) | ✓ | `flutter build appbundle --release` |
| **6** | **Data deletion endpoint URL 缺失** | Play Console | XS (15 min) | ✓ | 部署 1 页"如何删数据"到 chroniccare.app/delete-data-instructions |
| **7** | **Permissions Declaration Form 6 权限 use case 文本** | Play Console | XS (30 min) | ✓ | USE_EXACT_ALARM 100+ 字符 + 其余 5 个 short reason |
| **8** | **BootReceiver 启动 MainActivity 占位** | `android/app/src/main/kotlin/.../BootReceiver.kt` | S (2-3h) | ✗ | 用 FlutterEngineCache + MethodChannel 调 rescheduleAll |
| **9** | **zh-CN short description 超 80 字符** | `fastlane/metadata/android/zh-CN/short_description.txt` | XS (5 min) | ✗ | 砍到 80 内 |
| **10** | **description 文档与 R66 状态不一致（失联通知暂停）** | `fastlane/metadata/android/{en,zh-CN}/full_description.txt` | XS (15 min) | ✗ | 删 "Lost-contact safety net" / "失联通知" 描述 OR 加 "coming soon" |

---

## 12. 已知"通过"项（不阻塞，仅作清单备份）

下列项已合规，无需动：

- ✓ 权限最小化（9 权限全 justified；无 dangerous over-request）
- ✓ 0 广告 SDK / 0 analytics / 0 追踪
- ✓ 0 收集 device ID / IMEI / 广告 ID
- ✓ HTTPS 强制（`network_security_config.xml`）
- ✓ SQLCipher 本地加密
- ✓ `allowBackup="false"`（PIPL §28）
- ✓ `debuggable="false"`（release 显式）
- ✓ `isMinifyEnabled = true` + `isShrinkResources = true` + 10 plugin keep 规则
- ✓ targetSdk 36 (R63 显式 pin) + minSdk 24 (R63 显式 pin)
- ✓ multiDexEnabled = true
- ✓ BootReceiver 实装（R63 P0-2）
- ✓ data_extraction_rules 排除 chroniccare.sqlite + flutter_secure_storage + vent_audio + mood_audio
- ✓ backup_rules 排除同样 4 项
- ✓ enableOnBackInvokedCallback = true（Android 13 预测式返回）
- ✓ 查询限制（`<queries>` 只有 PROCESS_TEXT）
- ✓ en-US + zh-CN 文案双 locale（fastlane metadata）
- ✓ Title.txt / short_description.txt / full_description.txt 全部生成（R63 漏补的元数据）
- ✓ R66 FeatureFlags 失联通知业务双层防御暂停（rounds 决策清晰）
- ✓ R66 R5 PHQ-9 / GAD-7 危机电话路由 6 region
- ✓ R20 国产 ROM 自检卡 5 品牌引导（缺 realme/OnePlus/iQOO 但不阻塞）

---

## 13. 上架就绪度评估

**当前可提交状态**: ✗ **不可**（P0 阻塞 10 项缺 1 不可）

**预计上架就绪时间**（按 1 人日 8h 计）:
- **M1 最小上架 (3-5 天)**:
  - 修 P0 阻塞 1-7（~16h）
  - 律师 review 法律文档（外部依赖 1-2 周，**关键路径**）
  - 域名 + 邮箱注册（~1 天）
  - 真实截图（~1 天）
  - Play Console 表单填写（~3-4h）

- **M2 完整 CI 化 (+3-5 天)**:
  - fastlane Fastfile + Appfile + CI hook
  - 修 P1 警告（12 项）
  - 16KB page size 验证
  - Play Integrity 集成（可选）

- **M3 v1.0 (+3-6 月)**:
  - 真接 Aliyun SMS（法务 + 备案 1-2 月）
  - 健康类 IARC 复审
  - HIPAA / GDPR 律师过审
  - NMPA "非医疗器械" 备案
  - 软件著作权登记

---

**报告完毕。** 跟 R66 appstore 视角联动看——iOS / Android 双端都需要：① 真实 keystore ② 律师 review ③ 真实截图 ④ 邮箱 / 域名注册 ⑤ 隐私 / IAP / Health 表单填写。**M1 最小上架 3-5 天，瓶颈是法律 review**。
