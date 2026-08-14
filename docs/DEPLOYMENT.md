# 慢病管家 · 部署指南

> 4 周从零到上架 App Store + Google Play

> **🚧 R107 cleanup (2026-08-10) 9 视角综合审视后状态**:
> - 18 守门员全绿 / 2019 tests pass / 0 analyzer error
> - 7 FeatureFlag 守门 (失联 / 5 厂商 push / email / vent audio / phq-gad7 / boot / 阿里云 sms; v1.0.0+147 删 iap — 永久免费)
> - **R107 P0 13 项上架阻塞 必修** (R108 修, 1-2 周): 详见 `docs/audit-history/r107-cleanup-2026-08-10/00-summary.md` §四
> - **关键: chroniccare.app 域名未注册 (4 视角共识)** — Apple 5.1.1 + Google Play 隐私 URL 不可达拒因
> - **R108 修复流程**: 域名注册 (Cloudflare $15/yr + ICP 备案 7-20d) → iOS P0#1-9 (12.5h) → Android P0#1-6 (4-5d) → 通用 P0 (4h) → 总 ~12-14 工作日

---

## 阶段 0：开发环境（1 天）

### macOS（推荐）
```bash
# 1. 装 Xcode（App Store 搜 Xcode）
# 2. 装 Flutter
brew install fvm
fvm install 3.41.9
fvm use 3.41.9

# 3. 装 Android Studio（要 SDK + JDK）
brew install --cask android-studio

# 4. 装 CocoaPods
sudo gem install cocoapods
```

### Windows（只支持 Android）
- 装 Flutter SDK（官网下载）
- 装 Android Studio
- 装 Git for Windows

---

## 阶段 1：本地跑通（1 天）

```bash
git clone <your-repo>
cd chroniccare
fvm use 3.41.9
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test                  # 全部测试应该全过
flutter build web             # web 端 drift worker 走 production 模式
python -m http.server 8358    # 替代 flutter run -d chrome (drift worker 404)
# 浏览器打开 http://localhost:8358
```

---

## 阶段 2：Web 部署（1 天）

### Vercel（推荐，免费）
```bash
# 1. 装 Vercel CLI
npm install -g vercel

# 2. 构建
flutter build web --release

# 3. 部署
vercel --prod
# 输出：https://chroniccare.vercel.app
```

### Cloudflare Pages
```bash
flutter build web --release
# 上传 build/web/ 到 Cloudflare Pages
```

### GitHub Pages
```bash
flutter build web --release --base-href /chroniccare/
# 上传 build/web/ 到 gh-pages 分支
```

---

## 阶段 3：APK 打包（R72 重写 — 自动 keystore 脚本）

```bash
# 1. 装 Java JDK 17+ (keytool 命令行工具)
# 2. 跑 R72 自动脚本 (交互式输入密码, 自动写 key.properties + 备份)
pwsh ./scripts/generate_release_keystore.ps1
# 备份到 1Password / Bitwarden (丢 keystore = App 永久无法升级)

# 3. 验证签名
flutter build appbundle --release
aapt dump badging build/app/outputs/bundle/release/app-release.aab | grep package

# 4. 测试
adb install build/app/outputs/bundle/release/app-release.apk
```

> **R72 优势:** 跟原始 keytool 命令比, 脚本化:
> - 自动 keysize / validity 默认 (2048 / 10000 days)
> - 自动写 key.properties (不再手填 4 个字段)
> - 自动备份到 ~/.chroniccare-keystore-backup/
> - .gitignore 已排除 *.jks + key.properties (R67 已加)

### 故障排查

| 错误 | 原因 | 修复 |
|------|------|------|
| `keytool 找不到` | Java JDK 未装或 PATH 没配 | 装 JDK 17+ + 加 `JAVA_HOME` 到 PATH |
| `Keystore was tampered with, or password was incorrect` | 密码错 | 跑脚本时正确输入 storePassword |
| `Build failed: Execution failed for task ':app:signingConfig'` | build.gradle.kts 没切 release | R70 commit 1decee1 已加 `signingConfigs.release`, 验证 `android/app/build.gradle.kts:80` |

---

## 阶段 4：iOS 打包（R71 重写 — fastlane 自动化）

```bash
# 1. 装 fastlane
sudo gem install fastlane

# 2. 配 fastlane/Appfile 4 ID (apple_id / team_id / itc_team_id / app_identifier)
# 之前是 TODO 占位, R71 后需用户填真实值

# 3. 跑 fastlane (R71 新加 platform :android 块也支持)
bundle exec fastlane ios beta       # → TestFlight
bundle exec fastlane ios release    # → App Store (自动上传 + 提交审核)
bundle exec fastlane ios metadata   # → 只同步 metadata, 不 build

# 4. Android 端 (R71 新加)
bundle exec fastlane android internal      # → Google Play Internal Testing
bundle exec fastlane android production    # → Promote internal → production
bundle exec fastlane android metadata      # → 只同步 metadata
```

> **R71 优势:** 跟原始 Xcode Archive / Play Console 手传比, fastlane:
> - 1 条命令替代 7 步手传 (Build → 签名 → 上传 → 元数据 → 截图 → 提交审核)
> - 跟 CI/CD 集成 (`.github/workflows/ci.yml` 集成 16 守护脚本)
> - R71 加 Android 端 platform :android do 块 (跟 iOS 平行, 3 lane)

### App Store 描述 + 完整描述模板

> **R69 update:** 失联通知业务整体暂停, 描述里加 "Lost-contact safety net
> (coming soon — currently disabled)" 段, 跟 user_agreement.md CC-7 wording 修一致.

类似 Google Play，但加上：
- 适用年龄：12+
- 隐私 URL：可以是 GitHub Pages
- 版权：© 2026 Mavis
- 客服邮箱

---

## 阶段 7：发布后（持续）

### 监控
- SendGrid Dashboard：每日送达率
- Google Play Console：下载、评分、崩溃
- App Store Connect：下载、评分、崩溃
- 邮箱：用户反馈

### 运营
- 4.5+ 星好评 → 自然增长
- 评分 < 4.0 → 看差评改
- 黑产/刷量 → 监控异常下载

### 迭代（v1.0+）
- 短信通知（已加到 plan）
- 量表自评
- 趋势图

---

## 阶段 7.5: v0.27 R72 上架前 must-check 清单

> 上架前必跑, 17 守护脚本 + dart format + flutter analyze + flutter test 4 道护栏全过

```bash
# 1. 跑 17 守护脚本 (R70/R71 CI 集成 16 + R72 新增 16KB alignment)
for s in scripts/check_*.py; do python "$s" || break; done
# 期望: 16 OK + 1 WARN (fullwidth_punctuation warn-only)

# 2. 4 层架构纯度 + 一致性 (R70 加)
dart scripts/check_all.dart
# 期望: ✅ 通过 (4 层 + 5 子 umbrella + 共享层 + 架构语义一致性)

# 3. dart format (R66 + R67 护栏, C1.5 回归防御)
dart format --output=none --set-exit-if-changed lib/ test/ scripts/

# 4. flutter analyze
flutter analyze
# 期望: 0 error / 0 warning (info 已知 R17+R56b BuildContext 跨 async gap 可忽略)

# 5. flutter test
flutter test
# 期望: All tests passed! 1285 cases, 0 fail

# 6. CHANGELOG / pubspec 版本号同步
python scripts/check_changelog.py
# 期望: pubspec=0.27.0+64 CHANGELOG 顺序正确 (22 头)
```

### 提交前 5 项 P0 阻塞 (外部依赖, 用户手动)

- [ ] **真实 keystore + Play App Signing** (R72 commit `generate_release_keystore.ps1` 已脚本化, 跑后上传 .aab 到 Play Console)
- [ ] **`support@chroniccare.app` 邮箱 + `chroniccare.app` 域名 + HTTPS 站点** (隐私 URL `https://chroniccare.app/privacy` 部署, R72 待办)
- [ ] **Play Console 4 大表单** (Data Safety + Health Apps + Permissions Declaration + Data Deletion, R72 脚本 `generate_data_safety_form.py` 自动生成, 用户登录填)
- [ ] **Apple App Store Connect 4 ID** (`fastlane/Appfile` 4 个 TODO 替换真实值, R71 commit 42ac12b 后)
- [ ] **律师 review 3 法律 md** (1-2 周 + ¥15-30k/文档, 不可压缩)

### 提交前 4 项上架 P0 (技术性, R70/R71 已修)

- [x] iOS Info.plist: 删 aps-environment + NSUserNotificationUsageDescription (R70)
- [x] iOS Info.plist: CFBundleDisplayName 走 InfoPlist.strings (R70)
- [x] iOS pbxproj: 删 EXCLUDED_ARCHS arm64 (R70)
- [x] Android build.gradle.kts: 显式 abiFilters 64-bit (R70)
- [x] Android build.gradle.kts: targetSdk=36 + 16KB page size 验 (R70 + R72 验脚本)
- [x] iOS PrivacyInfo: 加 ProcessInfo + CA92.2 reason (R71)
- [x] iOS Info.plist: 删 UIMainStoryboardFile 重复 (R71)
- [x] fastlane Fastfile: Android 端 platform :android do 块 (R71)

### 提交前 3 项 R72 代码质量 (R72 已修)

- [x] **4 widget 集中器抽取** (LoadingSpinner/LoadingScrim/LoadingTextButton.outlined/ConsentCheckRow 评估, R70 完成)
- [x] **8 atomic size token 集中化** (legendDotSizeLg/Sm/avatarSizeSm/Md/buttonWidthNarrow/buttonHeightCompact, R70 完成)
- [x] **2 .then() 改 try/finally** (P5.4 100% 落地, R71 完成)
- [x] **5 处 Wrap(spacing: 8) 集中化** (R72 完成, emil E-P2-4)
- [x] **2 RepaintBoundary** (P5.4 50%, R71 完成; 剩 4 个 R72 后续)
- [x] **3 处病耻感措辞中性化** ("让家人放心" → "踏实"/"多一点坚持", "你真棒" → "今周已全部准时", R72 完成)
- [x] **"TA" 改 "对方"** (R72 完成, spzh R66 P0-5 续)

---

> **背景:** spzh 视角 P0 #5: 之前 DEPLOYMENT.md 只简略提 Google Play + App
> Store,**国内 5 大应用市场** + **5 厂商 push 通道** 0 提及 = 国产 ROM
> 静默杀后台通知 → 推送送达率 < 70% → 失联通知失效 → 用户死亡风险。

### 8.1 国内 5 大应用市场 (必须上)

| # | 商店 | 备案要求 | 上架材料 | 周期 |
|---|------|----------|----------|------|
| 1 | **华为应用市场** | 实名认证 + 营业执照 + ICP 备案 | AAB + 隐私 URL + 软件著作权 | 1-3 天审核 |
| 2 | **小米应用商店** | 实名认证 + 营业执照 | AAB + 隐私 URL | 1-2 天 |
| 3 | **OPPO 软件商店** | 实名认证 + 营业执照 + ICP 备案 | AAB + 隐私 URL | 1-3 天 |
| 4 | **vivo 应用商店** | 实名认证 + 营业执照 | AAB + 隐私 URL | 1-2 天 |
| 5 | **腾讯应用宝** | 实名认证 + 营业执照 + ICP 备案 | AAB + 隐私 URL | 1-3 天 |

> **共性材料准备:** 隐私政策 URL (`assets/legal/privacy_policy.md`
> 上传到 GitHub Pages 或自有域名) + 软件著作权登记证书 (CPDA
> 受理 1-2 月) + 营业执照 + ICP 备案 (域名备案 7-15 天)。

### 8.2 5 厂商 push 通道接入 (送达率 95%+)

**问题:** 国产 ROM (MIUI / EMUI / ColorOS / OriginOS / Flyme) 默认
禁止 App 后台运行 + 自启动 + 精确闹钟 + 静默杀后台推送。`flutter_local_
notifications 17.x` 在 iOS 完美,但 Android 上需接入厂商 push SDK
(走系统级 push 通道,不受 ROM 静默杀限制)。

**接入步骤(每厂商 1-2 周):**

1. **小米推送 (Mi Push)**
   - 注册: https://dev.mi.com/console/appservice/push.html
   - SDK: `mipush: ^5.0.0` 或 `xiaomi-push: ^1.0.0`
   - AndroidManifest: `<service android:name="com.xiaomi.push.service.XMPushService" />`
   - 厂商审核: 1 周

2. **华为 PUSH (HMS Core Push)**
   - 注册: https://developer.huawei.com/consumer/cn/hms/huawei-pushkit
   - SDK: `huawei_push: ^6.11.0`
   - 厂商审核: 2 周

3. **OPPO PUSH (PUSH 2.0)**
   - 注册: https://push.oppo.com/
   - SDK: 集成 OPPO Pusher SDK
   - 厂商审核: 2 周

4. **vivo PUSH**
   - 注册: https://dev.vivo.com.cn/push
   - 厂商审核: 1 周

5. **魅族 PUSH (Flyme Push)**
   - 注册: https://open.flyme.cn/
   - 厂商审核: 1 周

> **总周期: 1-2 月全部接入。** 同时保留 `flutter_local_notifications` 作为
> 兜底通道(其他 Android 设备 + 海外)。

**架构:** `NotificationService` 抽象 `PushProvider` 接口(类似
`SmsProvider`),按设备型号路由到对应厂商 SDK,统一封装。

### 8.3 上架材料 checklist (4 store 共用)

- [ ] 软件著作权登记证书 (CPDA 受理 1-2 月)
- [ ] 营业执照副本
- [ ] ICP 备案 (域名 7-15 天)
- [ ] 隐私政策 URL (GitHub Pages)
- [ ] 3 项法律协议 (用户协议 / 隐私政策 / 敏感数据同意书) 见 `assets/legal/`
- [ ] 应用图标 (1024×1024 高清 PNG)
- [ ] 5+ 张应用截图 (1920×1080)
- [ ] 视频预览 (可选,30s)
- [ ] 应用描述 (见阶段 5 模板)
- [ ] "非医疗器械" 声明 PDF (见附录 A)

---

## 附录 A: 合规声明模板 (NMPA / HIPAA / GDPR)

> **背景:** spzh 视角 P0 #4: 之前 DEPLOYMENT.md 提"非医疗器械"但没具体
> 模板。App Store / Google Play 审核需要正式声明 PDF。本附录提供 4 类
> 合规声明模板,法务过审后使用。

### A.1 NMPA "非医疗器械" 声明 (中国大陆上架必需)

> **声明**
>
> 本应用「慢病管家」(chroniccare) 经开发者自查,符合以下全部条件:
>
> 1. **不涉及疾病诊断**:本应用不提供任何医学诊断,所有 PHQ-9 / GAD-7
>    评估结果仅供用户自我参考,**不替代医生诊断**。
> 2. **不涉及治疗方案**:本应用不推荐任何药物或治疗方案,所有用药
>    提醒由用户**自行**或**医生**配置。
> 3. **不作为医疗决策依据**:本应用的失联通知机制是用户主动设置
>    的"安全网"功能,**不构成医疗监护**。
> 4. **未申请医疗器械注册**:本应用未在国家药品监督管理局(NMPA)
>    申请任何医疗器械注册证。
>
> 依据《医疗器械分类目录》和《医疗器械监督管理条例》,本应用属于
> **非医疗器械**,**不属于** 6810 类 (疾病诊断 / 治疗 / 监护仪器)
> 监管范围。
>
> 开发者: [公司名] | 日期: [YYYY-MM-DD] | 法人签字: [ ]

### A.2 HIPAA Compliance Statement (美国上架推荐)

> This application does not create, receive, maintain, or transmit
> Protected Health Information (PHI) on behalf of a Covered Entity
> or Business Associate. All user data is stored locally on the
> user's device, encrypted with AES-256, and is not transmitted to
> any cloud server or third party. This application is therefore
> not subject to HIPAA regulations.

### A.3 GDPR Compliance Statement (欧洲上架必需)

> This application does not transfer personal data outside the
> European Economic Area. All processing is performed locally on
> the user's device. No cookies, tracking pixels, or third-party
> analytics are used. The user can exercise all GDPR rights
> (access, rectification, erasure, restriction, portability)
> through in-app settings.

### A.4 PIPL Compliance Summary (中国法律汇总)

> 本应用严格遵守《中华人民共和国个人信息保护法》(PIPL):
>
> - §13/§14 处理 PII 前取得用户单独同意
> - §23 向紧急联系人提供 PII 前取得单独告知
> - §28 处理敏感 PII(健康医疗)取得单独同意
> - §38/§39 跨境 PII 传输合规(详见 `privacy_policy.md` §11)
> - §47 用户删除权(应用内一键删除 + 卸载清除)
> - §54 PII 处理活动记录(本地审计日志)

---

## 附录 B: 已知 v0.25 阻塞上 store 的合规 TODO

| # | 阻塞项 | 依赖 | 估时 | 计划 round |
|---|--------|------|------|-----------|
| 1 | **PIPL §13 单独同意实现** (联系人回复 Y) | SMS provider 真接 | 4-8h | R55 |
| 2 | **AliyunSmsProvider 真接** | 阿里云备案 + 签名 + 模板审核 | 2+ 月 | R55 |
| 3 | **5 厂商 push SDK 接入** | 各厂商审核 | 1-2 月 | R55 |
| 4 | **软件著作权登记** | CPDA 受理 | 1-2 月 | 法务负责 |
| 5 | **ICP 备案** | 域名注册 | 7-15 天 | 法务负责 |
| 6 | **法务 review 3 法律文档** | 律师 | 1-2 周 | 法务负责 |
| 7 | **HIPAA / GDPR 律师过审** | 国际律师 | 1-2 周 | 法务负责 |

> 上 store 路径: 4 store 缺一不可 + 5 厂商 push 缺一不可 + 法务 review 缺一不可。
> 估总: 3-6 月 (法务 + 厂商审核是瓶颈)。- 多语言

---

## 阶段 5：Apple 完整 metadata 模板 (R93 阶段 2 集中补全)

### 5.1 iOS App Store Connect metadata

**App Information**
- App 名: `慢病管家` (zh-Hans) / `ChronicCare` (en-US) / `慢病管家` (zh-Hant)
- Subtitle (30 字符): `精神健康吃药打卡 + 危机热线` (zh-Hans)
- Category: Primary = Medical, Secondary = Health & Fitness
- Content Rights: 选 "No, it does not contain, show, or access any third-party content"
- Age Rating: 17+ (Medical/Treatment Information)

**Pricing**
- **永久完全免费** (v1.0.0+147 定版): 无任何购买入口 / 收费行为 / 内购 / 订阅, 全部功能免费开放

**App Privacy** (PIPL §13/§14/§17/§28)
- Data Used to Track You: No
- Data Linked to You: Yes (Health & Fitness, Usage Data)
- Data Not Linked to You: Yes (Diagnostics)
- 详细字段: 见 `assets/legal/privacy_policy.md` §1

**Privacy Policy URL**: `https://chroniccare.app/privacy` (TODO: 域名注册后替换, R55+)

### 5.2 iOS 截图规范

| 设备 | 尺寸 | 数量 | 状态 |
|------|------|------|------|
| iPhone 6.5" | 1242 × 2688 | 3-10 张 | 需设计师出图 |
| iPhone 5.5" | 1242 × 2208 | 3-10 张 | 需设计师出图 |
| iPad 12.9" | 2048 × 2732 | 3-10 张 | 需设计师出图 |

> **R93 阶段 2 清理**: 36 张 67 字节占位 png 已删 (`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/*screenshots/*.png` + `app_icon.png`)。Apple 拒审点: 67 字节占位 = 明显未设计完成。

### 5.3 Android Google Play metadata

- App 名: `慢病管家`
- Short Description (80 字符): `精神心理患者吃药打卡 + 情绪追踪 + 危机热线`
- Full Description: 参考 `docs/CHANGELOG.md` + 用户故事
- Category: Medical
- Content Rating: PEGI 12 / USK 12
- Data Safety: 跟 iOS App Privacy 一致

---

## 阶段 6：5 项上架前手动 checklist (R93 阶段 2 红色 banner)

> 上 store 前必过 5 项检查, **R93 阶段 2 新增**集中守门, 避免上架后被拒:

### 6.1 ✅ 6 项 FeatureFlag 全部 hidden (R93 阶段 2 已完成, v1.0.0+147 删已取消业务)

- [x] 失联通知 (`emergencyContactEnabled=false`) — 设置页联系人 section + 主页 homeFabHotline hidden
- [x] 5 厂商 push (`fiveVendorPushEnabled=false`) — NotificationStatusCard OEM 引导 hidden
- [x] EmailService 邮件 (`emailServiceEnabled=false`) — AssessmentSection 邮件预览 hidden
- [x] vent + mood 录音 (`ventAudioEnabled=false`) — VentAudioSection + MoodRecorder hidden
- [x] PHQ-9 / GAD-7 量表 (`phqGad7I18nEnabled=false`) — AssessmentCenter 8 量表保留 6 显
- [x] BootReceiver (`bootReceiverEnabled=false`) — SafetyWatchService.onAppStart 跳过 rescheduleAll

### 6.2 ✅ 文档一致性 (R93 阶段 2 已完成)

- [x] README.md 顶部加 R93 红 banner
- [x] `assets/legal/privacy_policy.md` §0.6 "v0.30 业务暂停" section
- [x] `assets/legal/sensitive_data_consent.md` 修订历史加 R93 entry
- [x] `assets/legal/user_agreement.md` 修订历史加 R93 entry
- [x] `docs/CHANGELOG.md` [0.30.0] 累加 R93 entry (待 final review 提交)
- [x] `docs/DEPLOYMENT.md` 阶段 5/6/7 补全 (本节)

### 6.3 ✅ fastlane 清理 (R93 阶段 2 已完成)

- [x] 36 张 iOS 67 字节占位 png 删 (Apple 拒审点)
- [x] Android 真实截图保留 (designer 出的)
- [x] 文本 metadata (description.txt / keywords.txt / name.txt 等) 保留

### 6.4 ⚠️ 仍需手动完成 (R93+ 业务真接时)

- [ ] 阿里云 SMS 真接 (法务模板审核 + AccessKey 申请)
- [ ] EmailService 真接 (SendGrid API key + 法务模板审核)
- [ ] 5 厂商 push SDK 接入 (米/华/OPPO/vivo/魅族审核)
- [ ] PHQ-9 / GAD-7 en / zh_Hant 翻译完整 (法务 + 临床审核)
- [ ] Android WorkManager 完善 (BootReceiver 真接)
- [ ] 3 法律 md 律师过审 (¥45-90k)
- [ ] 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
- [ ] 邮箱 `support@chroniccare.app` / `privacy@chroniccare.app` 注册
- [ ] Android keystore + Play App Signing
- [ ] TestFlight 跑 1 周期 (Mac + 2 tester)

### 6.5 ⚠️ 4 store 4 套独立 metadata (R93+ 业务真接时)

- App Store (iOS): Apple 描述 + 截图 + AppIcon 1024
- Google Play (Android): Google 描述 + 截图 + Feature Graphic
- 华为应用市场 (国内 Android): 独立审核 + ICP 备案
- 小米/OPPO/vivo/魅族 应用商店 (国内 Android): 各厂商独立审核

---

## 阶段 7：部署 + 上线监控 (R93 阶段 2 集中补全)

### 7.1 CI/CD 流水线 (已有, R62/R72 阶段搭建)

- **GitHub Actions** (4 job): test / build web / build appbundle / release publish
- **CodeMagic** (iOS Mac runner): R60+ 阶段启用, iOS 编译 + 签名
- **Fastlane** (Android): R67 阶段启用, 自动生成 metadata + 上传

### 7.2 上线监控 (R93+ 业务真接时)

- **崩溃监控**: 接 Firebase Crashlytics / Sentry (本项目不接, 走本地 SQLite 错误日志)
- **性能监控**: 接 Firebase Performance (R94+ 待定)
- **用户行为**: 走本地 AnalyticsEvent (R72 阶段实施, 不接 Firebase Analytics)
- **服务器监控**: 无 (本项目零云端)

### 7.3 版本回滚流程 (R93+ 业务真接时)

```bash
# 1. 发现问题 → git revert <commit>
git revert HEAD

# 2. 重新打 tag
git tag v0.30.1

# 3. 推 master → CI 自动重新构建
git push origin master

# 4. App Store Connect / Google Play Console 紧急发布
# 4 store 都需要审核, 紧急情况走 expedited review
```

### 7.4 数据迁移 (R93+ 业务真接时)

- 业务真接时 (SMS / Email / 5 厂商 push) 涉及 schema 改动
- drift schemaVersion +1 + migration (R92 阶段 1 模式)
- 备份用户数据 → DB 升级 → 数据恢复
- 不动数据模型字段 (零迁移成本, FeatureFlag 守护)

### 7.5 用户通知 (R93+ 业务真接时)

- 业务真接时通过 in-app 通知用户"X 功能已上线"
- 走本地 NotificationService (已有, 跟日常打卡提醒同一通道)
- 不接 push (5 厂商 SDK 仍未真接)
- 邮件通知走 EmailService 真接后启用

