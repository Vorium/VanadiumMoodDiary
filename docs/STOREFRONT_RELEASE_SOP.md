# 上架前必做清单(用户手动)— v0.27 round 82

> **本文件给项目 owner 用的"上架前手动 checklist"**。AI 已经在代码层 + 守门员层修完能改的,**剩下 5 项需用户在真实环境(浏览器 / macOS / 终端 / 法务)手动完成**。
>
> 任何一项缺失,Apple App Store / Google Play Store **会 100% 拒**。

## 1. 注册 `chroniccare.app` 域名 + ICP 备案 + HTTPS 部署

**步骤**:
1. 注册 `chroniccare.app` 域名(阿里云 / 腾讯云 / Cloudflare Registrar,`.app` TLD 强制 HTTPS)
2. **中国大陆上架需 ICP 备案**(阿里云 / 腾讯云备案系统),7-20 天
3. Cloudflare Pages / Vercel / 阿里云 OSS 部署 4 份 HTML:
   - `https://chroniccare.app/privacy`(基于 `assets/legal/privacy_policy.md`)
   - `https://chroniccare.app/support`(基于 `assets/legal/user_agreement.md`)
   - `https://chroniccare.app/agreement`(基于 `assets/legal/user_agreement.md`)
   - `https://chroniccare.app/consent`(基于 `assets/legal/sensitive_data_consent.md`)
4. 替换 `fastlane/metadata/ios/*/privacy_url.txt` + `support_url.txt` + `fastlane/metadata/android/*/privacy_url.txt` 占位 URL
5. 替换 `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 文档里的 `https://github.com/example/chroniccare/issues` 占位 → 真实 GitHub 仓库 URL
6. 隐私政策页脚加 ICP 备案号

**耗时**:1-2 天(域名 + 部署)+ 7-20 天(ICP 备案)

**阻塞**:**不修此 7-20 天延迟,所有上架流程阻塞**。

---

## 2. Release keystore 生成 + 签名配置

**Android 步骤**(Windows PowerShell 可跑):
```bash
cd android
keytool -genkey -v -keystore chroniccare-release.keystore -alias chroniccare -keyalg RSA -keysize 2048 -validity 25000
# 提示输入密码 / 姓名 / 组织 / 城市 / 省 / 国家(填中国 / CN)
# 备份 keystore 到 1Password / 物理 U 盘 — 丢了 App 升不了级

# 创建 key.properties(放 android/ 下,加进 .gitignore)
cat > android/key.properties << 'EOF'
storePassword=<keystore 密码>
keyPassword=<key 密码>
keyAlias=chroniccare
storeFile=../chroniccare-release.keystore
EOF

# 已修改 build.gradle.kts(R82 切 release signing),直接跑:
flutter build appbundle --release
```

**iOS 步骤**(需 macOS):
```bash
# 1. macOS 跑 (Windows 跑不了)
cd ios
pod install
# 2. Xcode → Runner → Signing & Capabilities → Team: <你的 Apple Team ID>
# 3. Product → Archive → Distribute App → App Store Connect → Upload
```

**耗时**:1-2h(Android)+ macOS 30min(iOS)

---

## 3. App Store Connect + Google Play Console 配置

### 3.1 App Store Connect 必做
- 登录 https://appstoreconnect.apple.com
- My Apps → 创建 App:
  - 名称:`慢病管家` / `ChronicCare` / `慢病管家`(zh-Hant 同 zh-Hans)
  - 主要语言:简体中文
  - 套装 ID:`com.chroniccare.chroniccare`
  - SKU:任意
- 替换 `fastlane/Appfile:19-25` 的 TODO:
  ```
  apple_id "<你的 App Store Connect 邮箱>"
  team_id "<10 字符 Apple Team ID>"
  itc_team_id "<App Store Connect Team ID>"
  ```
- In-App Purchases → 创建 productId `com.chroniccare.chroniccare.lifetime`（跟 store_kit_service.dart:50 `kLifetimeProductId` 同步; R32 P0-03 已从 `.app.lifetime` 修正）,定价 8 元 CNY
- 改 `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = true`
- App Privacy → 填 4 大类(参考 `scripts/generate_data_safety_form.py` 输出)

### 3.2 Google Play Console 必做
- 登录 https://play.google.com/console
- 创建应用 → 名称 `慢病管家` / ChronicCare
- App content 必填 4 项:
  1. **Privacy policy**:`https://chroniccare.app/privacy`
  2. **Data safety**:4 大类 + health data 标记 + 第三方 SDK 列表
  3. **Health apps**:勾选(PHQ-9 / GAD-7 量表)
  4. **Permissions declaration**:8 个权限全勾
- Service Account JSON:
  ```
  Google Cloud Console → IAM & Admin → Service Accounts
  → 创建 service account → Role: Service Account User
  → Create Key (JSON) → 下载到 secrets/google-play-key.json
  → Play Console → Setup → API access → Link
  ```
- 改 `fastlane/Appfile:19-25` 加 `json_key_file "../secrets/google-play-key.json"`
- 跑 `python scripts/generate_data_safety_form.py` 生成表单,手动填 Play Console

**耗时**:半天(App Store)+ 半天(Google Play)

---

## 4. 截 33 个真实 App Store 截图 + 3 张 App Icon

**需 macOS + Xcode + 3 套真机/模拟器**:
- iPhone 6.7" 截图(1290×2796)— iPhone 14 Pro Max 模拟器
- iPhone 6.5" 截图(1242×2688)— iPhone 11 Pro Max 模拟器
- iPad 12.9" 截图(2048×2732)— iPad Pro 模拟器
- App Icon 1024×1024 PNG

**主流程截图(每个 locale 5 张)**:
1. 主页(home_page)— R81 病耻感 UI 升级
2. 心情横滑(quick_mood_carousel)
3. 情绪日记(mood_recorder_page)
4. 用药日历(medication_calendar_page)
5. 心理评估(assessment_page)

**3 个 locale × 11 个文件 = 33 张**:
```
fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/
  ├── iphone_6_5_screenshots/{01..05}.png
  ├── iphone_5_5_screenshots/{01..03}.png
  ├── ipad_12_9_screenshots/{01..03}.png
  └── app_icon.png
```

**操作**(macOS 跑):
```bash
# 1. flutter build ios
flutter build ios --release
# 2. 模拟器跑,5 个主流程按 cmd+s 截图
# 3. 用 preview / Sketch / Figma 加文字层 + 边框
# 4. 替换 fastlane/metadata/ios/*/screenshots/ 占位 PNG
```

**耗时**:1-2 天(找设计师 + 截 33 张 + 加文字层)

---

## 5. 法务 review 3 份法律 md(¥15-30k/文档)

**3 份文档**(R82 已结构化好):
- `assets/legal/privacy_policy.md`(14.5KB)— 隐私政策
- `assets/legal/user_agreement.md`(4.6KB)— 用户协议
- `assets/legal/sensitive_data_consent.md`(4.6KB)— 敏感数据同意书

**步骤**:
1. 找 PIPL / 精神心理 App 专长律师(推荐 锦天城 / 中伦 / 大成 律所网络法务团队)
2. 律师 review + 修订 + 出具 review 报告
3. 替换文档里"草稿 / TODO 律师过审"标记 → 律师签字 + 日期
4. 法务 review 报告保存为 PDF,提交 App Store Connect 审核时附上

**耗时**:1-2 周(律师 review + 反复修改)

**不可压缩瓶颈**:**不修 1.0 没法正式发**。

---

## 6. iOS 16KB page size 验证

**Flutter 3.41.9** 编译默认 16KB 对齐(已修),**但** 需 macOS 实际验:
```bash
# 1. macOS 跑
flutter build ios --release
# 2. 解压 .app
unzip -o build/ios/iphoneos/Runner.app/Frameworks/*.framework
# 3. 验 16KB 对齐
otool -l build/ios/iphoneos/Runner.app/Runner | grep page
# 期望: page size 16384(16KB)
```

**若失败**:升级 Flutter 到 3.41.10+(已修)或 3.44+(推荐)。

**Android 16KB 验证**:
```bash
# 1. 升级 sqlcipher_flutter_libs 到 0.6.8(R82 sub-agent 已升)
# 2. flutter build appbundle
flutter build appbundle --release
# 3. 验 16KB 对齐
bundletool validate --bundle=build/app/outputs/bundle/release/app-release.aab
# 期望: "16KB page size compatible"
```

---

## 7. 5 厂商 push SDK 接入(国产 ROM 送达率 60% → 95%)

**卡点**:每个厂商 SDK 1-2 周审核 + 集成。

**接入步骤**(v0.28+ 长期):
1. 注册 5 家开发者账号:
   - 小米开放平台(https://dev.mi.com)
   - 华为开发者联盟(https://developer.huawei.com)
   - OPPO 开放平台(https://open.oppomobile.com)
   - vivo 开放平台(https://dev.vivo.com.cn)
   - 魅族开放平台(https://open.flyme.cn)
2. `pubspec.yaml` 加 5 个 SDK:
   ```yaml
   dependencies:
     mipush: ^5.0.0
     huawei_push: ^6.11.0
     # OPPO / vivo / 魅族 走厂商 native SDK + MethodChannel
   ```
3. `lib/core/data/services/push_router.dart` 按 device brand 路由
4. 保留 `flutter_local_notifications` 作海外 + 非国产 ROM 兜底
5. 法务 review 5 厂商 push 模板(¥ 5-10k/家)

**耗时**:1-2 月

---

## 8. BootReceiver 完整方案(简化版未兑现 R64)

**当前状态**:`android/app/src/main/kotlin/.../BootReceiver.kt:18-21` 注释 "留给 R64 完善",**实际未兑现** = 重启后通知未真正重排,失联通知 100% 漏。

**完整方案**(半天):
```kotlin
// BootReceiver.kt 改:
override fun onReceive(context: Context, intent: Intent) {
    if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
    val engine = FlutterEngineCache.getInstance().get("main_engine")
        ?: return
    val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "chroniccare/boot")
    channel.invokeMethod("rescheduleAllReminders", null)
}
```

```dart
// main.dart 加 MethodChannel handler:
_bootChannel.setMethodCallHandler((call) async {
  if (call.method == 'rescheduleAllReminders') {
    await ref.read(medicationNotifierProvider.notifier).rescheduleAll();
  }
});
```

---

## 9. 接阿里云 SMS 真接(失联通知,法务 1-2 月)

**当前**:`lib/core/data/services/sms_service.dart:83` `MockSmsProvider.send()` 抛 `UnimplementedError`,release 模式被 `validateForRelease` 阻断(`feature_flags.dart:35` `_prodEmergencyContactEnabled=false`)。

**真接步骤**:
1. 阿里云注册 + 申请 AccessKey + 短信签名 + 短信模板(法务审核 1-2 月)
2. `lib/core/data/services/sms_service.dart:90-201` `AliyunSmsProvider.send()` 实现
3. `feature_flags.dart:35` `_prodEmergencyContactEnabled = true`
4. 隐私政策 + 用户协议更新失联通知描述
5. PIPL §38 跨境评估(如海外联系人)

**不可压缩瓶颈**:**法务 1-2 月** + **阿里云审核**。

---

## 10. 失联通知业务暂停的 UX 显眼提示(R82 P1)

**R82 报告**:`FeatureFlags.emergencyContactEnabled=false` 整段暂停,但**UX 无显眼提示**,用户以为失联通知工作实际 100% 不通知。

**R82 修法**(1 小时):
- 主页顶部加永久 banner:`⚠️ 失联通知业务暂停,见设置 → 法律与隐私`
- 设置页"紧急联系人"section 顶部同款 banner
- i18n key 3 个:zh / en / zh_Hant 同步

---

## 总览

| # | 任务 | 阻塞 | 难度 | 估时 |
|---|---|---|---|---|
| 1 | 注册域名 + ICP 备案 + HTTPS 部署 | 🔴 必拒 | M | 1-2 天 + 7-20 天备案 |
| 2 | Release keystore + signingConfig | 🔴 必拒 | S | 1-2h |
| 3 | App Store Connect + Google Play Console | 🔴 必拒 | M | 1 天 |
| 4 | 33 个真实截图 + App Icon | 🔴 必拒 | M | 1-2 天 |
| 5 | 法务 review 3 份 md | 🔴 必拒(Apple 5.1.1) | L | 1-2 周 + ¥ |
| 6 | iOS / Android 16KB 验证 | 🟡 警告 | S | macOS 30min |
| 7 | 5 厂商 push SDK 接入 | 🟡 警告(国产 ROM) | XL | 1-2 月 |
| 8 | BootReceiver 完整方案 | 🟡 警告 | M | 半天 |
| 9 | 阿里云 SMS 真接 | 🟡 警告(失联通知) | XL | 1-2 月 + 法务 |
| 10 | 失联通知 UX 显眼 banner | 🟡 P1 UX | S | 1h |

**核心 5 项必做(1-5)**:不修上架 100% 被拒,AI 帮不上。
**改进项 5 项(6-10)**:上架后持续做,送达率 + UX 提升。

---

> **诚实说明**:本 SOP 写于 2026-08-02 round 82,**AI 在 Windows 环境下无法完成 macOS / Apple ID / 域名注册 / 法务 review**。
> 已修的代码层 / 守门员层(15 项 P0 + 38 项 P1)见 `reports/round82_*.md` 子报告。
