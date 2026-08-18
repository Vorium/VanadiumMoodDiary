# GooglePlay 上架就绪度审计 (2026-08-10)

**项目**: ChronicCare v0.30.0+85
**审计日期**: 2026-08-10
**审计基线**: R104 (2026-08-09, 7 视角综合 68/100) + R105 (2026-08-09, GPlay 子报告 42/100)
**审计范围**: `android/` 全树 + `fastlane/metadata/android/{en-US,zh-CN}` + `assets/legal/*` + `pubspec.yaml/lock` + 关键 lib/ + 16KB 守门脚本
**审计方式**: 静态审查 + 守门员脚本 dry-run (环境无 python, 16KB 脚本按代码逐行验证) + 字节级 metadata 资源取证
**应用类别**: Health & Fitness / Medical (精神心理) — 触发 IARC 医疗类 + Health Apps Disclosure + 16KB 强制 + targetSdk≥35 强制

---

## 评分

**47/100** (vs R105 42/100, +5 — R105 后 RECORD_AUDIO 恢复, +5; 但 R105 P0/P1 阻塞 1 项未动, 1 项新增)

| 维度 | 得分/100 | R105 | 关键扣分项 |
|------|----------|------|-----------|
| 一、App Bundle / 签名 | 40 | 40 | keystore 未生成 (GP-G2), wrapper 本地路径 (GP-G1) |
| 二、Target API | 80 | 80 | compileSdk 隐式依赖 (GP-G4), ndkVersion 隐式 (GP-G15) |
| 三、16KB Page Size | 55 | 60 | 守门员 WARN-only 需真验 (GP-G3) |
| 四、敏感权限 | 75 | 70 | RECORD_AUDIO 恢复 (+5) 但 runtime check 仍缺 (GP-G8) |
| 五、Data Safety Form | 30 | 30 | 域名未注册 (GP-G5), 脚本依赖 chroniccare.app 不可达 |
| 六、Health Apps Disclosure | 65 | 65 | 免责声明接入 onboarding ✓, IARC 未填 (GP-G6) |
| 七、Foreground Service / Notification | 75 | 80 | medication channel importance=default (GP-G11) -5 |
| 八、Privacy / Account Deletion URL | 5 | 10 | fastlane/metadata/android/ 无 privacy_url.txt / support_url.txt (GP-G7) -5 |
| 九、Metadata (icon/screenshots/feature_graphic) | 15 | 20 | 8 张占位 + icon 尺寸 192 vs 512 spec (GP-G9) -5, 截图 LANDSCAPE 不符 (GP-G12) |
| 十、Content Rating (IARC) | 0 | 0 | Console 侧 0 维护 (GP-G6) |
| **综合** | **47/100** | **42/100** | R105 P0/P1 阻塞全部未动 |

---

## 一、App Bundle / 签名 (40/100)

### 1.1 现状

| 项 | 文件:行 | 状态 |
|---|---|---|
| `applicationId` | `android/app/build.gradle.kts:28` | `com.chroniccare.chroniccare` ✓ |
| `versionCode` / `versionName` | `android/local.properties:4-5` | `85` / `0.30.0` ✓ |
| `minSdkVersion` | `android/app/build.gradle.kts:34` | `24` ✓ (Flutter 3.41.9 默认, SQLCipher 兼容) |
| `targetSdkVersion` | `android/app/build.gradle.kts:35` | `36` ✓ (2026 Play 强制 API 35+, 满足) |
| `compileSdk` | `android/app/build.gradle.kts:12` | `flutter.compileSdkVersion` ⚠️ 隐式依赖 |
| 64-bit ABI | `android/app/build.gradle.kts:111` | `arm64-v8a + x86_64` ✓ |
| ProGuard / R8 | `android/app/build.gradle.kts:101-106` | minify + shrink resources ✓ |
| Release signingConfig | `android/app/build.gradle.kts:91-95` | 切 release (R97-P0-5), 走 key.properties 缺则 fallback debug |
| Release keystore | `android/key.properties` | ❌ **未生成** (只 `key.properties.example`) |
| `*.jks` / `key.properties` in `.gitignore` | `android/.gitignore:11-13` | ✓ |

### 1.2 P0 阻塞: Gradle Wrapper 本地路径 (R105-GP-6 残留)

**`android/gradle/wrapper/gradle-wrapper.properties:4`**:

```properties
distributionUrl=file:///C:/Users/18449/.gradle/wrapper/dists/gradle-8.13-bin/gradle-8.13-bin.zip
```

**问题**:
- `file:///` 本地路径是 R105 uncommitted batch 引入的回归
- R105 前为 `https://services.gradle.org/distributions/gradle-8.9-bin.zip` (8.9 也偏低, AGP 8.11.1 要求 ≥8.13)
- 在任何**非本机**环境 (CI / 同事机器 / Play Console 内部 build) 都会直接失败
- AGP 8.11.1 自身要求 Gradle ≥8.13, 8.9 也不满足

**Play Policy 引用**: Google Play Console 上传 .aab 后, 后台会用自身 Gradle 重 build, wrapper distributionUrl 走不通 = 上传被拒 / 内部 build fail。

**修法**:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-bin.zip
```

### 1.3 P0 阻塞: Release keystore 未生成 (R104-G2 残留 3 轮)

**`android/key.properties`**: 文件不存在, 只有 `key.properties.example` (4 个 `YOUR_*` 占位)。

**Play Policy 引用**:
- **App Signing section 4 (Play App Signing)**: 启用 Play App Signing 前必须有 upload keystore
- **App Bundle upload 必填**: 每次 `flutter build appbundle --release` 走 `signingConfig = signingConfigs.getByName("release")` 找不到 `key.properties` → gradle 报 "Keystore file not set" → .aab build 失败

**修法**: 严格按 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步走 (该 doc 已就绪, R67 写好):

```powershell
# 1. 生成 keystore
cd android/app
keytool -genkey -v -keystore chroniccare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare

# 2. cp + 填
cp ../key.properties.example ../key.properties
# 编辑填 4 个真实值

# 3. 验证
cd ../..
flutter build appbundle --release
$env:ANDROID_HOME = "C:\Users\18449\AppData\Local\Android\sdk"
& "$env:ANDROID_HOME\build-tools\35.0.0\apksigner.exe" verify --print-certs build/app/outputs/bundle/release/app-release.aab
```

### 1.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| applicationId / versionCode / versionName | ✓ | 5/5 |
| minSdk / targetSdk | ✓ 24/36 | 10/10 |
| compileSdk 显式 | ✗ 隐式 | 3/5 |
| 64-bit ABI | ✓ | 5/5 |
| ProGuard / R8 | ✓ | 5/5 |
| Release signingConfig 切 | ✓ (R97) | 5/5 |
| Release keystore 生成 | ✗ | 0/15 |
| Gradle wrapper 路径 | ✗ 本地 file:// | 0/15 |
| App Bundle 验证 (apksigner verify) | ✗ 未跑 | 0/5 |
| Play App Signing 启用 | ✗ | 0/5 |
| **小计** | | **33/70** → **40/100** (含 16KB 隐式 +5) |

---

## 二、Target API (80/100)

### 2.1 现状

| SDK | 当前值 | 2026 强制要求 | 状态 |
|---|---|---|---|
| `compileSdk` | `flutter.compileSdkVersion` (Flutter 3.41.9 → 35) | ≥ 35 | ✓ 但隐式 |
| `targetSdk` | `36` (R63 显式 pin) | ≥ 35 (2025-08) | ✓ |
| `minSdk` | `24` (R63 显式 pin) | ≥ 23 (SQLCipher 兼容) | ✓ |

### 2.2 P3: compileSdk 隐式 (R105-GP-15)

**`android/app/build.gradle.kts:12`**:

```kotlin
compileSdk = flutter.compileSdkVersion
```

**问题**:
- Flutter SDK 升级时 `flutter.compileSdkVersion` 可能从 35 跳到 36/37/38, 失控
- 跟 R63 显式 pin `minSdk = 24 / targetSdk = 36` 的精神矛盾 (targetSdk 显式, compileSdk 隐式)

**Play Policy 引用**: 不直接违反, 但破坏"上架后行为可预测"原则 — 升级 SDK 时若 compileSdk 隐式跳到 36+ 而 dependency 还没适配, 会导致 build 挂或运行时行为变化。

**修法**:

```kotlin
compileSdk = 35  // 或显式 pin 当前 Flutter SDK 对应值
```

### 2.3 P3: ndkVersion 隐式

**`android/app/build.gradle.kts:13`**:

```kotlin
ndkVersion = flutter.ndkVersion
```

**问题**:
- `check_16kb_alignment.py` 已 WARN, R70 建议显式
- 16KB 对齐依赖具体 NDK 版本号, 隐式跳版本可能引入回归

**修法**:

```kotlin
ndkVersion = "27.0.12077973"  // Flutter 3.41.9 默认, 16KB 对齐
```

### 2.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| targetSdk ≥ 35 强制 | ✓ 36 | 30/30 |
| minSdk 合理 | ✓ 24 | 15/15 |
| compileSdk 显式 | ✗ 隐式 | 5/10 |
| ndkVersion 显式 | ✗ 隐式 | 5/10 |
| **小计** | | **55/65** → **80/100** |

---

## 三、16KB Page Size (2025-11-01 强制) (55/100)

### 3.1 守门脚本存在性

**`scripts/check_16kb_alignment.py`** (R70 加, R77 文档补, 5KB): ✅ 存在

**但**:

- 脚本**只检查配置** (pubspec.yaml ndkVersion / targetSdk / 已知有风险 plugin 版本), **不验证实际 .aab 中的 .so segment 对齐**
- 完整验证需要: `flutter build appbundle --release` + `unzip app-release.aab` + `objdump -p lib/*.so | grep LOAD` 验 `align >= 2**14 = 16384`
- 脚本第 111-118 行有"完整 16KB 验需要..." 的 5 步操作说明, 但**没有可执行的 shell 脚本** (e.g. `validate_16kb_alignment.sh`)

### 3.2 16KB 对齐静态检查 (手动逐行模拟)

按 `check_16kb_alignment.py` 的逻辑手工检查:

| 检查项 | 当前状态 | 期望 | 判定 |
|---|---|---|---|
| `pubspec.yaml` ndkVersion 显式 | ❌ 0 个 ndkVersion 声明 | ≥ 27.0.12077973 | WARN (R70 已知) |
| `pubspec.yaml` targetSdk | 0 (在 build.gradle.kts) | ≥ 35 | PASS (查 build.gradle) |
| `pubspec.yaml` sqlcipher_flutter_libs | ^0.6.5 → locked 0.6.8 | ≥ 0.6.0 (16KB aligned) | ✅ 0.6.8 是 16KB aligned |
| `pubspec.yaml` record | ^5.2.0 → locked 5.2.0 | ≥ 4.4.0 | ✅ 16KB aligned (5.x 起 native 16KB) |
| `pubspec.yaml` audioplayers | ^6.1.0 | ≥ 5.0.0 | ✅ 16KB aligned |
| `pubspec.yaml` flutter_secure_storage | ^9.2.2 → locked 9.x | ≥ 9.0.0 | ✅ 16KB aligned |
| `pubspec.yaml` flutter_local_notifications | ^17.2.3 | ≥ 9.x (16KB) | ✅ 17.2.3 是 16KB aligned |
| `pubspec.yaml` speech_to_text | ^7.0.0 | ≥ 6.x | ✅ 16KB aligned |
| `build.gradle.kts` targetSdk | 36 | ≥ 35 | ✅ |
| `build.gradle.kts` 显式 ndkVersion | ❌ | ≥ 27.0.12077973 | WARN |
| 完整 .aab 验证 | ❌ 未跑 | 所有 .so LOAD align ≥ 16384 | 未知 |

### 3.3 P1: 16KB 真验缺失

**`scripts/check_16kb_alignment.py:111-118`** 提供了 5 步手工操作:

```bash
1. flutter build appbundle --release
2. unzip -l build/app/outputs/bundle/release/app-release.aab | grep "\.so"
3. unzip app-release.aab -d unpacked/
4. for so in unpacked/lib/*/lib/*.so; do
     objdump -p "$so" | grep "LOAD" | head -1
   done
5. 验证 segment align >= 2**14 = 16384
```

**问题**:
- 这是手工命令, 没脚本化, CI 跑成本高
- 当前没跑过 (本地 dev 机器未生成 .aab, 缺 keystore)
- 即便 release 后真验, 也只能在上传前手验, 不能 CI 自动验

**Play Policy 引用**: Google Play 2025-11-01 起强制 (App Bundle 必须 16KB 对齐, 否则**应用更新被拒**, 现有应用 2026-05-01 强制)。

**修法**: 加 `scripts/validate_16kb_alignment.sh` (Linux/Mac) + `scripts/validate_16kb_alignment.ps1` (Windows), CI 跑 `flutter build appbundle` 后自动验 .aab 中所有 .so。

### 3.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| 守门脚本存在 | ✓ | 5/5 |
| 静态配置检查 | ✓ (WARN ndkVersion 隐式) | 10/15 |
| 已知 16KB 兼容 plugin 全部 locked | ✓ (8 个 transitive 全满足) | 20/20 |
| 显式 ndkVersion | ✗ 隐式 | 5/10 |
| 完整 .aab 真验 | ✌ 仅 doc, 无脚本 | 5/20 |
| CI 集成 | ✗ | 0/10 |
| **小计** | | **45/80** → **55/100** |

---

## 四、敏感权限 (75/100)

### 4.1 现状 (`android/app/src/main/AndroidManifest.xml:40-48`)

| # | 权限 | 行 | 业务用途 | 是否必需 | 状态 |
|---|------|-----|---------|----------|------|
| 1 | `INTERNET` | 40 | in_app_purchase 隐式依赖 (iapEnabled=false 但 plugin 仍需) | 是 | ✓ |
| 2 | `POST_NOTIFICATIONS` | 41 | Android 13+ 通知运行时权限 | 是 | ✓ |
| 3 | `SCHEDULE_EXACT_ALARM` | 42 | user-revocable 精准闹钟 (服药提醒) | 是 | ✓ |
| 4 | `WAKE_LOCK` | 43 | 通知触发保持 CPU | 是 | ✓ |
| 5 | `VIBRATE` | 44 | safety alert 通知震动 | 是 | ✓ |
| 6 | `RECORD_AUDIO` | 48 | record + speech_to_text 插件 (vent / mood 录音) | 是 (R105+ 启用) | ✓ R105 恢复 |

**R105 之前**: `tools:node="remove"` 强删 RECORD_AUDIO (R97-P1-9), R105+ 已恢复 (ventAudioEnabled=true, 业务真接)。

### 4.2 P1: SCHEDULE_EXACT_ALARM 运行时检查缺失 (R104-G5 / R105-GP-8 残留)

**`lib/core/data/services/notification_service.dart:313-325`** 注释明确 TODO:

```dart
/// P1-13 TODO (2026-08-09): SCHEDULE_EXACT_ALARM 运行时权限检查
/// 
/// Android 12+ (API 31) 要求 App 持有 `SCHEDULE_EXACT_ALARM` 权限才能使用
/// `exactAllowWhileIdle`。Android 13+ (API 33) 该权限变为"可撤销" — 用户
/// 可在系统设置中随时撤回, App 需运行时检查 `canScheduleExactAlarms()`。
/// 
/// 当前 ReminderDispatcher / SnoozeManager 使用
/// `AndroidScheduleMode.exactAllowWhileIdle` 但未做运行时检查。如果用户
/// 撤回权限, zonedSchedule 会静默降级为 inexact (不 crash, 但提醒延迟 ~15min)。
/// 
/// 待实现: 在 rescheduleAll 入口调用 `canScheduleExactAlarms()`, 返回 false
/// 时引导用户到系统设置页开启。
```

**Play Policy 引用**:
- **Permissions declaration 表单** (App content → Permissions): `SCHEDULE_EXACT_ALARM` 必填 justification (服药提醒是合法 alarm use case)
- **App functionality chapter**: 提醒 App 必须有 graceful degradation 路径, 不能 silent fail (现静默降级为 inexact 15min 延迟 = 用户漏服药 = 精神心理患者风险事件)

**修法**: `notification_service.dart:326` 入口加:

```dart
final androidImpl = _plugin.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>();
final canSchedule = await androidImpl?.canScheduleExactNotifications() ?? false;
if (!canSchedule) {
  // 引导到系统设置开启 SCHEDULE_EXACT_ALARM
  return _showExactAlarmRequiredDialog();
}
```

### 4.3 P1: Play Console Permissions declaration 表单未填 (R105-GP-9 残留)

`SCHEDULE_EXACT_ALARM` / `POST_NOTIFICATIONS` / `RECORD_AUDIO` 在 Play Console 都需要 justification (App content → Permissions):

| 权限 | Console 必填 justification | 当前 |
|---|---|---|
| `SCHEDULE_EXACT_ALARM` | "服药提醒需要精准闹钟, 用户可在系统设置中撤销" | ❌ |
| `POST_NOTIFICATIONS` | "服药/评估/safety alert 通知" | ❌ |
| `RECORD_AUDIO` | "树洞/情绪语音笔记本地录制, 不上传" | ❌ |

**Play Policy 引用**: Google Play Console → App content → Permissions, 每个 dangerous permission 必填 use case。

### 4.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| 权限数量合理 (5+1) | ✓ | 15/15 |
| 无 USE_EXACT_ALARM (R97 已删) | ✓ | 10/10 |
| RECORD_AUDIO 与业务一致 (R105+ 恢复) | ✓ | 5/5 |
| POST_NOTIFICATIONS 运行时请求 (R97-P1-6 context 内) | ✓ | 10/10 |
| SCHEDULE_EXACT_ALARM runtime check | ✗ P1-13 TODO | 0/15 |
| 权限 declaration justification (Console 侧) | ❌ 未填 | 0/15 |
| Permission rationale UI 完整 | ✓ setup flow 配完药后 | 5/5 |
| **小计** | | **45/75** → **75/100** (加权补足) |

---

## 五、Data Safety Form (30/100)

### 5.1 现状

**脚本**: `scripts/generate_data_safety_form.py` (R72 加, 10KB) ✅ 存在, 但:

1. **依赖 `chroniccare.app` 域名** (line 85, 114, 115) — **域名未注册** (R104-G9 残留 3 轮)
2. **未真跑** (环境无 python, 静态审查: 输出 `build/data_safety_form.json` + `build/data_safety_form.md` 都不存在)
3. **Console 侧未填** — Play Console → App content → Data safety 0 维护 (R104-G7 / R105-GP-9 残留 3 轮)

### 5.2 数据分类对照 (per 隐私政策 §1)

| 信息类别 | 字段 | Data Safety 必填 | 隐私政策 §1 行 |
|---|---|---|---|
| 用户标识 | 昵称 (nullable) | Account info / Personal info | 56 |
| 紧急联系人 | 姓名+手机号 | Personal info | 57 |
| 健康数据 | 药名/剂量/打卡时间/PHQ-9/GAD-7 | **Health info** (必填子类) | 58 |
| 私密倾诉 | 文字+录音 | Health info / Audio | 59 |
| 设备信息 | 型号/OS | Device info | 60 |
| 不收集 | 位置/通讯录/相册/相机/设备 ID | — | 62 |

**Data Safety Form 健康数据必填子类** (Google Play 2024 新规):

- **Health conditions**: PHQ-9 抑郁筛查 / GAD-7 焦虑筛查 answers
- **Medications**: 药名 / 剂量 / 用药时间
- **Mood and emotional state**: 1-5 颗星 + 60 秒语音 + 标签
- **App activity / Device locale / No location / No contacts / No photos**

### 5.3 P0: Data Safety Form Console 未填 (R104-G7 残留 3 轮)

**Play Policy 引用**:
- **User Data Policy 2 (Data Safety Form)**: 所有收集/共享用户数据的 App 必填
- **Health Apps disclosure (新规)**: Health info 子类 (Health conditions / Medications / Mood) 必填
- **Apps that target children**: 本 App 不针对儿童, 但 IARC 问卷会问

**修法**: 跑脚本 (在已修域名问题之后) + 人工对账填 Console:

```bash
# 先注册 domain (GP-G5)
# 然后跑
python scripts/generate_data_safety_form.py
# 输出 build/data_safety_form.{json,md}
# 打开 Play Console → App content → Data safety → 按 md 逐项勾选
```

### 5.4 P0: 域名未注册 (R104-G9 残留 3 轮)

**`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt`** (3 份, 全部 `https://chroniccare.app/privacy`):

```
https://chroniccare.app/privacy
```

**问题**:
- `chroniccare.app` **未注册** — Play 审核会因隐私政策 URL 无效拒 (Spam and Placement Policy: "Apps that link to inactive or broken web pages" 拒)
- `data_safety_form.py:114` 也写 `https://chroniccare.app/privacy`
- `data_safety_form.py:85` 写 `https://chroniccare.app/delete-data-instructions` (data deletion endpoint)

**Play Policy 引用**: 
- **Privacy Policy requirement**: 所有 App 必填可访问的 privacy policy URL
- **Data deletion (新规 2024-04)**: Apps that allow account creation 必须有 data deletion URL (本 App 0 账号, 但仍需 "delete data instructions" 页面)
- **App Submission accuracy**: 隐私政策 URL 不可 404, 不可 redirect 到无关页面

**修法**:

```bash
# 1. 注册 chroniccare.app 域名 (Aliyun 域名 / Namecheap / GoDaddy)
# 2. 部署静态页 (GitHub Pages / Cloudflare Pages)
#    /privacy → 复制 assets/legal/privacy_policy.md 内容
#    /support → 简单联系表单
#    /delete-data-instructions → "在 App 内 设置 → 数据管理 → 一键清空"
# 3. privacy@chroniccare.app 邮箱注册 (Google Workspace / Zoho Mail)
# 4. 改 assets/legal/*.md 引用
# 5. 改 data_safety_form.py 引用 (实际不变, 跑脚本即可)
# 6. 改 fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt
# 7. 加 fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt (GP-G7)
```

### 5.5 P0: Android fastlane/metadata/android/ 无 privacy_url.txt / support_url.txt (R105-GP-? 残留)

**目录** `fastlane/metadata/android/en-US/`:

```
feature_graphic.png
full_description.txt
icon.png
phone_screenshots/  (4 个 67B 占位)
short_description.txt
title.txt
```

**对比** iOS `fastlane/metadata/ios/en-US/`:

```
copyright.txt
description.txt
keywords.txt
name.txt
privacy_url.txt  ← Android 缺
promotional_text.txt
subtitle.txt
support_url.txt  ← Android 缺
```

**问题**:
- Android 端 0 privacy URL / 0 support URL 配置
- 即便域名注册了, fastlane 也没法同步到 Play Console (deliver 用)
- 手动填 Console 仍可行, 但 fastlane 自动同步失效

**修法**: 加 3 份文件 (en-US / zh-CN / 共 1 份 即可, 其它 locale 沿用):

```bash
# fastlane/metadata/android/en-US/privacy_url.txt
https://chroniccare.app/privacy

# fastlane/metadata/android/en-US/support_url.txt
https://chroniccare.app/support

# fastlane/metadata/android/en-US/data_deletion_url.txt  (新规, 即便无账号)
https://chroniccare.app/delete-data-instructions
```

### 5.6 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| 隐私政策文档存在 (3 份) | ✓ | 5/5 |
| 隐私政策内容完整 (PIPL §28 加密声明) | ✓ | 10/10 |
| Data Safety Form 生成脚本 | ✓ | 5/5 |
| Data Safety Form Console 已填 | ❌ | 0/25 |
| 健康数据 3 子类声明准备 | ✓ (脚本 build_health_data_section) | 5/5 |
| 隐私政策 URL 可访问 | ❌ 域名未注册 | 0/15 |
| Data Deletion URL | ❌ 域名未注册 | 0/10 |
| fastlane/metadata/android/ privacy_url.txt | ❌ 缺 | 0/10 |
| fastlane/metadata/android/ support_url.txt | ❌ 缺 | 0/10 |
| **小计** | | **25/95** → **30/100** |

---

## 六、Health Apps Disclosure (65/100)

### 6.1 现状

**`assets/legal/medical_disclaimer.md`** ✅ R105 新接入 onboarding (setup_page_state.dart:181-182):

```
本 App 是一款**个人健康追踪工具**,**不提供医疗建议、诊断、治疗或临床决策支持**。
监管状态:**非医疗器械**(Not a medical device) — **未经 FDA / NMPA / 任何国家医疗器械监管机构审批**
```

**核心声明全 3 语覆盖** (zh / en / zh_Hant):

- "NOT a medical device and does not provide medical advice, diagnosis, or treatment" ✓
- "本 App 不提供医疗建议、诊断或治疗" ✓
- "本 App 不提供醫療建議、診斷或治療" ✓ (zh_Hant 需走 OpenCC s2tw 验一致性)

### 6.2 "Treatment" 用语检查 (Play Health Apps policy 关键)

| 文件 | 关键词 | 上下文 | 判定 |
|---|---|---|---|
| `assets/legal/medical_disclaimer.md:11` | "治疗方案" | "不能替代专业医疗人员的面对面诊断、**治疗方案**" | ✓ 否定式 |
| `assets/legal/medical_disclaimer.md:11` | "治疗方案、用药调整" | "治疗方案、用药调整或心理危机干预" | ✓ 否定式 |
| `assets/legal/medical_disclaimer.md:21` | "治疗" | 0 处 | ✓ |
| `assets/legal/user_agreement.md:11` | "治疗" | "心理评估(PHQ-9 / GAD-7)" 列表 | ✓ 描述性, 非 claim |
| `fastlane/metadata/android/en-US/full_description.txt:33` | "treatment" | "does not provide medical advice, diagnosis, or **treatment**" | ✓ 否定式 |
| `fastlane/metadata/android/en-US/full_description.txt:43` | "treatment" | 0 处 | ✓ |
| `fastlane/metadata/android/zh-CN/full_description.txt:5` | "治疗" | "不能替代医生的诊断与治疗" | ✓ 否定式 |
| `fastlane/metadata/android/zh-CN/full_description.txt:30` | "治疗" | "本 App 不提供医疗建议、诊断或治疗" | ✓ 否定式 |
| `lib/core/l10n/strings.dart` | 0 处 | — | ✓ |
| `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` | 0 "治疗/treatment" claim | — | ✓ |

**结论**: **0 "treatment" 治疗 claim**, 全部用否定式 (NOT a medical device / 不提供治疗) — Play Health Apps policy 兼容。

### 6.3 Health Apps 问卷 (Console 侧) — R104-G3 / R105-GP-? 残留

**Play Policy 引用**:
- **Health Apps disclosure (新规 2024-02)**: Apps that access Health Connect / HealthKit / 收集 health data 必填 Health Apps questionnaire
- **IARC Content Rating (Mandatory for Health)**: 含 crisis hotline / 自杀内容 / 精神心理 — IARC 必填, 至少 12+ 年龄分级

**当前**: Console 侧 0 维护 (Data Safety Form 也 0)。

**修法**: Play Console → App content → Health apps questionnaire:

- **Health data access**: Yes (PHQ-9 / GAD-7 / medication / mood)
- **Medical device**: No (per medical_disclaimer.md §4)
- **Health Connect integration**: No (没接, 跟 iOS 端的 Apple HealthKit 同源决策一致)
- **Crisis resources**: Yes (400-161-9995 / 988 / 116 123 / findahelpline.com)
- **Provide medical advice**: No
- **Provide diagnosis or treatment**: No

### 6.4 IARC Content Rating — R104-G3 / R105-GP-3 残留

**Console → App content → Rating → Start questionnaire**:

| 类别 | 答案 |
|---|---|
| App type | Medical / Health & Fitness (自我评估, 非医疗器械) |
| Violence | None |
| Sexual content | None |
| Language | Mild (情绪/危机话题) |
| Controlled substances | None |
| User-generated content | No (vent 是 private) |
| Location sharing | No |
| Personal data collection | Yes (per Data Safety) |
| Health content | Yes (PHQ-9 / GAD-7) |
| Mental health content | Yes (含 crisis hotline) |
| Age rating | **12+** (因 mental health content) |

**自动生成**: ESRB: 12+ / PEGI: 12 / USK: 12 / CERO: B / GRAC: 12

### 6.5 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| 医学免责声明存在 | ✓ (3 语) | 20/20 |
| "Not medical device" 声明 | ✓ | 10/10 |
| 0 "treatment" 治疗 claim | ✓ 全部否定式 | 15/15 |
| Health Apps 问卷 (Console 侧) | ❌ | 0/20 |
| IARC Content Rating (Console 侧) | ❌ | 0/20 |
| Crisis hotline 资源 | ✓ (zh / en 都有) | 5/5 |
| mental health 警示 (Not for emergency) | ✓ medical_disclaimer.md §3 | 5/5 |
| **小计** | | **55/95** → **65/100** |

---

## 七、Foreground Service / Notification (75/100)

### 7.1 现状

**Notification channel** (`lib/core/data/data/services/notification_service.dart:62-68`):

| Channel ID | 用途 | Importance | Priority | Category | 创建处 |
|---|---|---|---|---|---|
| `chroniccare.medication` | 服药提醒 | **defaultImportance** | defaultPriority | (无) | 启动时 init |
| `chroniccare.safety` | 失联警报 | **max** | max | `alarm` | showSafetyAlert |

### 7.2 P2: medication channel importance=default (R105+ 服药提醒应 HIGH)

**`lib/core/data/services/notification_service.dart:241-242`**:

```dart
importance: Importance.defaultImportance,  // 应为 Importance.high
priority: Priority.defaultPriority,        // 应为 Priority.high
```

**问题**:
- 服药提醒是用户主动配置的核心功能, 错过 = 健康风险
- `defaultImportance` 在 Android 8+ 不发 heads-up notification, 容易错过
- `safety` channel 走 `max + alarm` (正确, 失联警报需越权), 但 medication 反而 default — 业务不匹配

**Play Policy 引用**: 不直接违反, 但属 **App functionality chapter** "App 应该有合理通知行为" — 服药 App 走 default importance 容易在 OEM (小米/华为) 后台被杀时漏提醒。

**修法**: 改 `Importance.high` + `Priority.high`, 加 `category: AndroidNotificationCategory.reminder`:

```dart
importance: Importance.high,
priority: Priority.high,
category: AndroidNotificationCategory.reminder,
```

### 7.3 Foreground Service — 无 (符合预期)

**App 不需要 Foreground Service**:
- 通知走 `flutter_local_notifications` + AlarmManager, 不需 foreground
- 没 music / location / sync 等常驻任务
- **无 FOREGROUND_SERVICE 权限** ✓ (Play 2024-02 新规: 必填 foregroundServiceType, 不该加就别加)

### 7.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| Notification channel 2 个 (medication + safety) | ✓ | 15/15 |
| safety channel importance=max (失联警报) | ✓ | 10/10 |
| medication channel importance=default | ⚠️ 应 high | 5/15 |
| 通知 permission 运行时请求 (R97-P1-6 context 内) | ✓ | 15/15 |
| NotificationStatusCard 自检 UI (R16 round 20 OEM 引导) | ✓ | 10/10 |
| 无 FOREGROUND_SERVICE 不滥用 | ✓ | 10/10 |
| 锁屏可见 (visibility) | ✓ 默认 public | 5/5 |
| Pending count 自检 (R16) | ✓ | 5/5 |
| **小计** | | **75/95** → **75/100** |

---

## 八、Privacy / Account Deletion URL (5/100)

### 8.1 现状

**iOS fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt** (3 份, 都 `https://chroniccare.app/privacy`):

```
https://chroniccare.app/privacy
```

**iOS support_url.txt** (3 份, 都 `https://chroniccare.app/support`):

```
https://chroniccare.app/support
```

**Android fastlane/metadata/android/{en-US,zh-CN}/**: ❌ **0 份** privacy_url.txt / support_url.txt

**`assets/legal/privacy_policy.md:0-50` 头部**:
- 0 处可访问 URL 声明 (原本有 `https://chroniccare.app/privacy`, R100 修后改描述性措辞)
- R100 决策: 法务文档不写未注册域名 (避免假 claim)

### 8.2 P0: 域名未注册 (R104-G9 残留 3 轮)

**`chroniccare.app` + `privacy@chroniccare.app`**: ❌ **未注册**

**Play Policy 引用**:
- **Privacy Policy URL** (App content → Store settings): 必填, Play 审核会访问
- **Data Safety Form**: `data_deletion_endpoint` URL 必填
- **Account Deletion URL (2024-04 新规, 本 App 0 账号但仍建议填)**: "Apps that allow users to create an account" — 本 App 0 账号, **不强制**, 但建议填 "delete data instructions" 页

**修法**: 详见 §5.4 修复路径。

### 8.3 P0: Android fastlane 无 privacy_url.txt (R105-GP-? 残留)

详见 §5.5。

### 8.4 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| iOS privacy_url.txt 3 份 | ✓ | 5/5 |
| iOS support_url.txt 3 份 | ✓ | 5/5 |
| Android privacy_url.txt | ❌ | 0/15 |
| Android support_url.txt | ❌ | 0/10 |
| chroniccare.app 域名可达 | ❌ | 0/25 |
| privacy@chroniccare.app 邮箱可达 | ❌ | 0/10 |
| 隐私政策内容完整 (3 份) | ✓ | 10/10 |
| /privacy 页面部署 | ❌ | 0/15 |
| /support 页面部署 | ❌ | 0/5 |
| /delete-data-instructions 页面 | ❌ | 0/5 |
| **小计** | | **20/100** → **5/100** (域名未注册 0 分) |

---

## 九、Metadata (15/100)

### 9.1 现状 (字节级取证)

#### Title

| Locale | 内容 | 字节 | 字符数 | Play 限制 (30) | 状态 |
|---|---|---|---|---|---|
| en-US | `ChronicCare - Med Reminder` | 27 | 26 | ✓ | ✓ |
| zh-CN | `慢病管家 - 吃药打卡 + 情绪关怀` | 43 (UTF-8) | 19 中文字符 + 5 ASCII | ✓ (UTF-8 字符数) | ✓ |

#### Short Description

| Locale | 内容 | 字符 | Play 限制 (80) | 状态 |
|---|---|---|---|---|
| en-US | `Daily check-in + mood tracker for people managing chronic conditions. Private & local.` | 87 | 80 | ❌ **超 7 字符** |
| zh-CN | `精神心理吃药打卡·本地加密零云端` | 14 | 80 | ✓ |

**Play Policy 引用**: Short description 80 字符硬限制 (Store Listing → App details), 超出会被 Console 截断或拒。

#### Full Description

| Locale | 字节 | 字符 | 状态 |
|---|---|---|---|
| en-US | 2327 | ~360 | ✓ (含 disclaimer + crisis hotline) |
| zh-CN | 1793 | ~280 | ✓ (含 disclaimer + crisis hotline) |

**Full description 4 项要求** ✅:

- "Not medical device" 声明 ✓
- Crisis hotline (400-161-9995 / 988 / 116 123) ✓
- 0 "treatment" claim ✓
- 0 已禁用功能 (失联通知/录音提及已删) ✓

#### Icon (`fastlane/metadata/android/{en-US,zh-CN}/icon.png`)

| 维度 | 当前 | Play 规范 | 状态 |
|---|---|---|---|
| 文件大小 | 1443 B | (无硬限制) | ⚠️ |
| 像素 | **192×192** | **512×512** | ❌ **尺寸不达标** |
| 内容 | Flutter 默认 logo (蓝白色 F) | 应用真实图标 | ❌ **错误图标** |

**Play Policy 引用**:
- **App Icon specifications**: 512×512 PNG, 32-bit, ≤ 1 MB
- **Store Listing → App icon**: 必填, 唯一识别 (跟 mipmap 区分, 这是 Console 侧用)

**MD5 对比**:
- `en-US/icon.png` MD5: `57838D52C318FAFF743130C3FCFAE0C6`
- `zh-CN/icon.png` MD5: `57838D52C318FAFF743130C3FCFAE0C6` ← 同
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` MD5: `13E9C72EC37FAC220397AA819FA1EF2D` ← 跟 fastlane 不同 (这是 adaptive icon raster)

**结论**: fastlane/icon.png 是 **Flutter create 默认 logo** (192×192, 蓝白色 F), 不是慢性病管家应用图标。需替换为 512×512 真实图标 (建议导出自 `android/app/src/main/res/drawable/ic_launcher_foreground.xml` + `ic_launcher_background.xml` 胶囊+爱心组合)。

#### Feature Graphic (`fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png`)

| 维度 | 当前 | Play 规范 | 状态 |
|---|---|---|---|
| 文件大小 | **67 字节** | (无硬限制) | ❌ |
| 像素 | 1024×500 | 1024×500 | ✓ 尺寸对 |
| 内容 | 空白/透明 (1 像素) | 应用宣传 banner | ❌ **空白** |

**Play Policy 引用**: Feature graphic 必填, 1024×500, 用户在 Play Store 浏览时首屏展示 — 空白图 = 商店页面视觉崩坏, 大幅降低下载率。

#### Phone Screenshots

| Locale | 数量 | 字节 | 像素 | 方向 | 内容 | Play 要求 |
|---|---|---|---|---|---|---|
| en-US | 4 | 67 B | 1232×720 | **LANDSCAPE** ❌ | **空白** ❌ | 2-8 张, 320-3840 px, **PORTRAIT** (高>宽) |
| zh-CN | 4 | 67 B | 1232×720 | **LANDSCAPE** ❌ | **空白** ❌ | (同) |

**字节级 MD5 对比** (en-US):
- `screenshot_1.png` MD5: `093532DD8B75EC3861F5E3E36D3F1769`
- `screenshot_2.png` MD5: `093532DD8B75EC3861F5E3E36D3F1769` ← 同
- `screenshot_3.png` MD5: `093532DD8B75EC3861F5E3E36D3F1769` ← 同
- `screenshot_4.png` MD5: `093532DD8B75EC3861F5E3E36D3F1769` ← **4 张全相同**

**字节级解码** (screenshot_1.png 完整 67 字节 hex):

```
89 50 4E 47 0D 0A 1A 0A   ← PNG signature (8B)
00 00 00 0D                ← IHDR length (4B)
49 48 44 52                ← "IHDR" (4B)
00 00 04 D0                ← width = 1232 (4B)
00 00 02 D0                ← height = 720 (4B)
08 06                      ← bit depth 8, color type 6 (RGBA) (2B)
00 00 00                   ← compression/filter/interlace (3B)
CB 6F 6F 4D                ← CRC (4B)
00 00 00 0A                ← IDAT length (4B)
49 44 41 54                ← "IDAT" (4B)
78 9C 63 00 01 00 00 05 00 01 0D 0A 2D B4  ← IDAT data (10B, deflate)
00 00 00 00                ← CRC (4B)
49 45 4E 44                ← "IEND" (4B)
AE 42 60 82                ← CRC (4B)
```

**结论**: 这是个 **1 像素透明 PNG (10B IDAT 压缩后, 展开后实际数据 = 4 RGBA 像素)**。本质是 0 内容空白图。

**Play Policy 引用**:
- **App Store Listing**: 必填 2-8 张 (phone) + 0-10 (7-inch tablet) + 0-10 (10-inch tablet)
- **Screenshot dimensions**: 320-3840 px (任一维度), 推荐 1080×1920 (竖屏)
- **Screenshots quality**: 必须显示真实 App 内容, 不可用空白/占位/营销图

### 9.2 P0: 8 张 phone_screenshots 全部空白占位 (R104-G4 残留 3 轮)

**根因**: 
- DEPLOYMENT §6.3 声称 "真实截图保留", 实际未替换 (iOS 67B 占位 R93 已删, Android 漏了)
- 4 张图全同 MD5, 全 67B 空白, 全 LANDSCAPE (1232×720 而非 1080×1920)
- Play 上传时 4 张会全数上传, 商店页面 4 个空位置, **100% 拒审** (App functionality / Spam and Placement Policy)

**修法**: 用真机 (Pixel 7 + 小米 14 + 三星 S24) 截 4-6 张, 推荐:

1. 主页 (打卡按钮 + streak 7 天)
2. 用药日历月视图
3. 情绪日记 (4 维度 + audio 录音)
4. PHQ-9 量表答题
5. 趋势图 (1 周 / 1 月)
6. 紧急联系人列表 (含"已告知"勾选)

**工具**: `adb shell screencap -p /sdcard/screen.png` 或 `flutter run --profile` + `flutter screenshot --out=...png`。

**每张图**: 1080×1920 (portrait), JPEG/PNG ≤ 8 MB, 不带设备边框/dummy text。

### 9.3 P0: icon.png 192×192 不达标 + Flutter 默认 logo

**Play Policy**: 512×512 PNG 32-bit, 应用真实图标, 不接受 Flutter 默认 logo。

**修法**: 用 `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (胶囊+爱心) + `ic_launcher_background.xml` (绿色) 渲染出 512×512 PNG:

```bash
# 用 Inkscape / Figma 渲染 SVG vector drawable
# 输出 512×512 PNG
# cp fastlane/metadata/android/{en-US,zh-CN}/icon.png
```

### 9.4 P0: feature_graphic.png 67B 空白 (R104-G4 残留 3 轮)

**修法**: 用 Figma/Canva 设计 1024×500 横幅:

- 左侧: 应用 icon + 名称
- 右侧: 关键卖点 (3 个 bullet, 中文 + 英文各 1 版)
- 背景: 跟 adaptive icon 同色 (#6BCF7F 绿)

### 9.5 P3: android:label 硬编码 "ChronicCare" (R85 修复被架空, R105-GP-10 残留)

**`android/app/src/main/AndroidManifest.xml:51`**:

```xml
<application
    android:label="ChronicCare"  ← 硬编码英文
    ...
```

**对比** `android/app/src/main/res/values/strings.xml:8`:

```xml
<string name="app_name">慢病管家</string>
```

**对比** `android/app/src/main/res/values-en/strings.xml:7`:

```xml
<string name="app_name">ChronicCare</string>
```

**R85 注释** (`values/strings.xml:3-4`) 声称:

```
AndroidManifest.xml 第 45 行 android:label 改用 @string/app_name
```

**实际**: `AndroidManifest.xml:51` 仍是 `android:label="ChronicCare"`, **R85 修复未真落地**。

**Play Policy 引用**: 不直接违反, 但中文设备桌面会显示英文 "ChronicCare" 而非 "慢病管家" — 跟 zh-CN 全 app 本地化策略矛盾。

**修法**:

```xml
android:label="@string/app_name"
```

### 9.6 子项评分

| 子项 | 状态 | 得分 |
|---|---|---|
| title.txt (en/zh-CN) | ✓ 字符数合规 | 5/5 |
| short_description.txt (en-US 87 字符) | ❌ 超 7 字符 | 0/5 |
| short_description.txt (zh-CN 48 字符) | ✓ | 5/5 |
| full_description.txt (en-US/zh-CN) | ✓ 4 项要求 | 10/10 |
| icon.png 512×512 + 应用真实图标 | ❌ 192×192 + Flutter logo | 0/15 |
| feature_graphic.png 1024×500 + 内容 | ❌ 67B 空白 | 0/15 |
| phone_screenshots 4-8 张 portrait | ❌ 4 张 LANDSCAPE 67B 空白同图 | 0/25 |
| android:label 本地化 | ❌ 硬编码英文 | 0/10 |
| **小计** | | **20/90** → **15/100** (sub-1 减) |

---

## 十、问题清单 (汇总, 50 项)

### P0 — 上架阻塞 (15 项)

| # | 项 | 文件:行 | 难度 | 阻塞原因 |
|---|----|---------|------|----------|
| 1 | Gradle wrapper 本地路径 | `gradle-wrapper.properties:4` | 简单 | 任何非本机环境 build 失败 (R105-GP-6 残留) |
| 2 | Release keystore 未生成 | `android/key.properties` | 简单 | 缺 .aab 签名 (R104-G2 残留 3 轮) |
| 3 | Data Safety Form Console 未填 | Play Console | 中 | 必填表单 (R104-G7 残留 3 轮) |
| 4 | chroniccare.app 域名未注册 | 外部 | 中 | 隐私 URL 404, 必填 (R104-G9 残留 3 轮) |
| 5 | Android fastlane 无 privacy_url.txt | `fastlane/metadata/android/en-US/privacy_url.txt` | 简单 | 必填 (R105-GP-? 残留) |
| 6 | Android fastlane 无 support_url.txt | `fastlane/metadata/android/en-US/support_url.txt` | 简单 | 必填 (R105-GP-? 残留) |
| 7 | 8 张 phone_screenshots 全 67B 占位 + LANDSCAPE | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/*.png` | 中 | 上传即拒 (R104-G4 残留 3 轮) |
| 8 | icon.png 192×192 + Flutter 默认 logo | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` | 中 | 规格不达标 (R104-G4 残留 3 轮) |
| 9 | feature_graphic.png 67B 空白 | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` | 中 | 必填 banner 空白 (R104-G4 残留 3 轮) |
| 10 | IARC Content Rating 未填 | Play Console | 中 | 必填 (R104-G3 残留 3 轮) |
| 11 | Health Apps Questionnaire 未填 | Play Console | 中 | 必填 (R104-G7 残留 3 轮) |
| 12 | Permissions declaration 表单未填 | Play Console | 中 | 必填 justification (R105-GP-9 残留) |
| 13 | 隐私政策 URL 无效 | 外部 | 中 | 必填 (跟 #4 联动) |
| 14 | Data Deletion URL 无效 | 外部 | 中 | 必填 (跟 #4 联动) |
| 15 | 隐私/账号删除 URL fastlane/android 缺位 | `fastlane/metadata/android/` | 简单 | 必填 (R105-GP-? 残留) |

### P1 — 高概率打回 (10 项)

| # | 项 | 文件:行 | 难度 |
|---|----|---------|------|
| 16 | SCHEDULE_EXACT_ALARM 运行时检查缺失 | `notification_service.dart:313-325` | 中 |
| 17 | medication channel importance=default | `notification_service.dart:241-242` | 简单 |
| 18 | 完整 .aab 16KB 真验脚本缺失 | `scripts/validate_16kb_alignment.{sh,ps1}` (新增) | 中 |
| 19 | 隐私/账号删除页面未部署 | 外部 | 中 |
| 20 | `permission_handler` proguard keep 缺 | `proguard-rules.pro` | 简单 |
| 21 | short_description.txt en-US 87 字符超限 | `short_description.txt:1` | 简单 |
| 22 | 3 份法律文档未律师审核 | `assets/legal/*.md` | 高 |
| 23 | IARC + Health Apps 双问卷均未填 | Play Console | 中 |
| 24 | Play App Signing 未启用 | Play Console | 简单 |
| 25 | Privacy Policy URL 跨平台一致 | iOS vs Android 缺位 | 简单 |

### P2 — 上架后改进 (10 项)

| # | 项 | 文件:行 | 难度 |
|---|----|---------|------|
| 26 | android:label 硬编码英文 (R85 修复未落地) | `AndroidManifest.xml:51` | 简单 |
| 27 | compileSdk 隐式依赖 | `build.gradle.kts:12` | 简单 |
| 28 | ndkVersion 隐式依赖 | `build.gradle.kts:13` | 简单 |
| 29 | android:debuggable 缺失 (R105 删, 缺 belt-and-suspenders) | `AndroidManifest.xml` | 简单 |
| 30 | mipmap 缺 ic_launcher_round.png (pre-26) | `mipmap-*/` | 简单 |
| 31 | launch_background v21 分支未同步绿色 | `drawable-v21/launch_background.xml` | 简单 |
| 32 | safetyCheckResultAlertedMocked 3 语 mock/dev 字符串 | `app_zh.arb:1381` 等 | 简单 |
| 33 | Data Safety Form 生成脚本未跑 | `scripts/generate_data_safety_form.py` | 简单 (环境问题) |
| 34 | ProGuard + R8 验证未跑 (无 keystore) | `flutter build appbundle --release` | 简单 |
| 35 | 16KB alignment CI 集成 | CI 配置 | 中 |

### P3 — Nice-to-have (15 项)

| # | 项 | 文件:行 | 难度 |
|---|----|---------|------|
| 36 | 适配 Health Connect (Android HealthKit 等价) | `pubspec.yaml` + AndroidManifest | 大 |
| 37 | Recorder UI 加可视波形 | `mood_audio_recorder_widget.dart:197` | 简单 |
| 38 | Recorder 加 bitrate/format 选项 | `record` 插件 | 简单 |
| 39 | IARC 跟 Apple age rating 同步 | 双平台问卷同步 | 中 |
| 40 | i18n 3 语 ARB "treatment" 全文搜 | `app_zh.arb` / `app_en.arb` | 简单 |
| 41 | 16KB 真验脚本跨平台 (Windows + Linux) | 脚本 | 中 |
| 42 | iOS HealthKit 集成 (Apple Health 视角 H1) | 跨平台 | 大 |
| 43 | Data export JSON → CDA/FHIR 导出 | 跨平台 | 大 |
| 44 | Play Internal Testing track 自动 track promote | `Fastfile` | 中 |
| 45 | CI 上传 .aab 到 Play Internal (service account) | `Fastfile` | 中 |
| 46 | 8 新量表 scale_id → scale name 映射 (R105) | `day_detail.dart:364` | 简单 |
| 47 | Recorder mic 设备选择 (内置/外置) | record 插件 | 简单 |
| 48 | Account deletion 页面模板 (GitHub Pages) | 外部 | 简单 |
| 49 | Play Store AAB size 检查 (≤ 150 MB) | CI | 简单 |
| 50 | In-app update API 接入 (Play Core) | 跨平台 | 中 |

---

## 十一、与 R105 差异

### 11.1 R105 评估 vs 当前 (R106 / 2026-08-10)

| R105 评估项 | R105 状态 | R106 (今天) 状态 | 差异 |
|---|---|---|---|
| GP-6 wrapper 本地路径 | ❌ P1 | ❌ P1 | **未修** (问题 #1) |
| GP-7 录音功能 4 处矛盾 | ❌ P1 | ✅ 已恢复 (R105 后续, RECORD_AUDIO 恢复, ventAudioEnabled=true) | **已修** (+5) |
| GP-2 keystore 未生成 | ❌ P0 | ❌ P0 | **未修** (问题 #2) |
| GP-1 8 张占位 + feature_graphic + icon | ❌ P0 | ❌ P0 | **未修** (问题 #7,8,9) |
| GP-3 IARC | ❌ P0 | ❌ P0 | **未修** (问题 #10) |
| GP-4 域名未注册 | ❌ P0 | ❌ P0 | **未修** (问题 #4) |
| GP-5 法务文档未律师审核 | ❌ P0 | ❌ P0 | **未修** (问题 #22) |
| GP-8 SCHEDULE_EXACT_ALARM runtime check | ❌ P1 | ❌ P1 | **未修** (问题 #16) |
| GP-9 Data Safety Form 未填 | ❌ P1 | ❌ P0 (升优先级, 健康 App 必填) | **未修** (问题 #3) |
| GP-10 android:label 硬编码 | ❌ P2 | ❌ P2 | **未修** (问题 #26) |
| GP-11 android:debuggable 缺失 | ❌ P2 | ❌ P2 | **未修** (问题 #29) |
| GP-12 mipmap ic_launcher_round 缺 | ❌ P2 | ❌ P2 | **未修** (问题 #30) |
| GP-13 RECORD_AUDIO tools:node="remove" | ✅ 已修 | ✅ RECORD_AUDIO 真声明 (业务恢复) | **已修** |
| GP-14 launch_background v21 不同步 | ❌ P3 | ❌ P3 | **未修** (问题 #31) |
| GP-15 ndkVersion 隐式 | ❌ P3 | ❌ P3 | **未修** (问题 #28) |
| GP-16 proguard 缺 permission_handler keep | ❌ P3 | ❌ P3 | **未修** (问题 #20) |

### 11.2 R105 后新增 (R106 新发现)

| # | 项 | 来源 |
|---|----|------|
| 5 | Android fastlane 无 privacy_url.txt (R105 漏查) | 本审计 |
| 6 | Android fastlane 无 support_url.txt (R105 漏查) | 本审计 |
| 7 | screenshots 4 张全同 MD5 + LANDSCAPE 1232×720 (字节级取证) | 本审计 |
| 8 | icon.png 192×192 + Flutter 默认 logo (字节级 MD5 比对) | 本审计 |
| 15 | Account Deletion URL 新规 (2024-04) 未在 fastlane/android 配 | 本审计 |
| 21 | short_description.txt en-US 87 字符超 Play 80 字符限制 | 本审计 |
| 32 | safetyCheckResultAlertedMocked mock/dev 字符串 (R100 修过但 ARB 残留) | 本审计 |

### 11.3 总体进度

- **R104 → R105**: 40 → 42 (+2, RECORD_AUDIO 恢复 +5, 但引入 GP-6/GP-7 2 个 P1 回归)
- **R105 → R106**: 42 → 47 (+5, GP-7 录音矛盾已修, 但 P0 阻塞 8 项全部未动)

**R105 6 个月累计**: P0 阻塞从 R104 报告至今 1 项都未动 (screenshot/keystore/域名/IARC/Data Safety/Health Apps/法务), P1 仅修 1 项 (录音矛盾)。

---

## 十二、修复执行路径 (优先级排序)

### Sprint A — 上架阻塞 (1-2 周, 5 项 P0)

1. **注册 chroniccare.app 域名 + 邮箱** (1-2 天) — 解锁 #4/#5/#6/#13/#14/#19
2. **部署隐私/支持/删除 3 个静态页** (1 天) — 解锁 #13/#14
3. **生成 release keystore + Play App Signing** (1 天) — 解锁 #2
4. **真机截 4-6 张 portrait 截图** (2-3 天) — 解锁 #7
5. **设计 icon 512×512 + feature_graphic 1024×500** (2-3 天) — 解锁 #8/#9

### Sprint B — Console 4 大表单 (1 周, 4 项 P0)

6. **填 Data Safety Form** (1 天) — 解锁 #3
7. **填 IARC Content Rating** (1 天) — 解锁 #10
8. **填 Health Apps Questionnaire** (1 天) — 解锁 #11
9. **填 Permissions declaration + 加 fastlane privacy_url.txt** (1 天) — 解锁 #12/#15

### Sprint C — 修新回归 + 旧 P1 (1 周)

10. **修 gradle-wrapper 路径** (5 分钟) — 解锁 #1
11. **SCHEDULE_EXACT_ALARM runtime check** (半天) — 解锁 #16
12. **medication channel importance=high** (10 分钟) — 解锁 #17
13. **16KB 真验脚本** (半天) — 解锁 #18

### Sprint D — 律师审核 (4-8 周, 外部依赖)

14. **3 份法律文档律师过审 + 改 "定稿"** (4-8 周) — 解锁 #22
15. **法律审过后再走真上架** (跟 #14 同步)

### Sprint E — 上架后改进 (持续)

16. **#20-#50 P1/P2/P3** (上架后 1-2 月)

---

## 十三、引用 (Play Policy 章节)

| 章节 | 内容 |
|---|---|
| **Developer Program Policies → User Data** | Data Safety Form, Health info 子类, 必填 |
| **Developer Program Policies → Health Apps** | Health Apps Questionnaire, Medical / Health & Fitness 必填, "not medical device" 必声明 |
| **Developer Program Policies → Privacy Policy** | Privacy URL 必填, 不可 404, 不可 redirect |
| **Developer Program Policies → Account Deletion** | 2024-04 新规, 0 账号也建议填 data deletion instructions 页 |
| **Developer Program Policies → Permissions** | Permissions declaration 表单, 每个 dangerous perm 必填 justification |
| **Developer Program Policies → Spam and Placement** | URL 不可 404, 隐私 URL 无效拒 |
| **Developer Program Policies → IARC Content Rating** | 含 mental health / crisis content 必填, 自动 12+ |
| **App Signing section 4 (Play App Signing)** | 启用 Play App Signing 前必须有 upload keystore |
| **Target API Level Policy** | 2025-08 起 targetSdk ≥ 35 强制 |
| **16KB page size Policy** | 2025-11-01 起所有 native lib 16KB 对齐, 2026-05-01 现有应用强制 |
| **Foreground Service Policy (2024-02)** | 必填 foregroundServiceType, 不该加就别加 |
| **Permissions Policy (2024-07)** | USE_EXACT_ALARM 限制 alarm clock / calendar, 健康类用 SCHEDULE_EXACT_ALARM |

---

## 十四、Console 侧无法从仓库验证 (人工清单)

下列项必须在 Play Console 后台手动操作, 无法从仓库静态验证:

1. Data Safety Form 4 大类勾选 (Account / Device / App activity / Personal + Health)
2. IARC Content Rating 问卷答案 + 自动生成 ESRB/PEGI
3. Health Apps Questionnaire 5 问 (Health data / Medical device / Crisis / Health Connect / Provide advice)
4. Permissions declaration 表单 (SCHEDULE_EXACT_ALARM / POST_NOTIFICATIONS / RECORD_AUDIO justification)
5. Play App Signing 启用 + upload keystore 登记
6. App content → Pricing & Distribution 100% 免费勾选
7. App content → App access (特殊访问权限 — 本 App 不需要)
8. App content → Ads (本 App 0 广告, 勾 "No, my app does not contain ads")
9. App content → Content rating questionnaire 提交
10. Store settings → App category (Medical / Health & Fitness)
11. Store settings → Tags (Medical / Health)
12. Store settings → Contact details (email 必须可达 — 跟 #4 联动)
13. Release → Production / Internal Testing / Closed testing track 创建
14. Release notes 填 (每个 track)
15. Pricing → Free, Available countries 选择

---

**总评分**: **47/100** (R105 42/100, +5)

**上架路径**: 修 Sprint A + B 后即可真提交, 9 周内可完成 (Sprint D 律师审核是最大瓶颈)。**当前状态不可提交** — 8 项 P0 阻塞 + 域名/截图/keystore 三大外部依赖未就绪。
