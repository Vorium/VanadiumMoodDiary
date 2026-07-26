# 慢病管家 · 部署指南

> 4 周从零到上架 App Store + Google Play

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

## 阶段 3：APK 打包（1 天）

```bash
# 1. 配签名
keytool -genkey -v -keystore ~/chroniccare-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare

# 2. 创建 android/key.properties
cat > android/key.properties <<EOF
storePassword=你的密码
keyPassword=你的密码
keyAlias=chroniccare
storeFile=/Users/你的名字/chroniccare-key.jks
EOF

# 3. 配置 build.gradle（签名）—— 略

# 4. 打包
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk

# 5. 测试
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 阶段 4：iOS 打包（1 天，仅 macOS）

```bash
# 1. Xcode 登录 Apple ID
# 2. 配 Bundle ID：app.chroniccare.you
# 3. 配签名（Apple Development Team）

# 4. 打包
flutter build ios --release

# 5. 用 Xcode 上传
open ios/Runner.xcworkspace
# Product → Archive → Distribute App
```

---

## 阶段 5：Google Play 上架（1 天）

1. 注册 Google Play Console（一次性 $25）
2. 创建 App：app.chroniccare
3. 填资料：
   - App 名称：慢病管家
   - 简短描述：「我今天吃了药」- 精神心理患者吃药打卡 + 停药通知
   - 完整描述：（见下）
   - 类别：医疗
   - 内容分级：问卷（PEGI 12+ / ESRB T）
   - 隐私政策 URL
4. 上传 AAB（不是 APK）：
   ```bash
   flutter build appbundle --release
   # 上传 build/app/outputs/bundle/release/app-release.aab
   ```
5. 定价：付费下载 ¥8.00
6. 提交审核（1-3 天）

### 完整描述模板

```
🌱 慢病管家 - 我今天吃了药

为精神心理疾病患者（焦虑/抑郁/双相/睡眠障碍）打造的"温和激励型"自我管理 App。

【核心功能】
✓ 每天点 1 下"我今天吃了药"
✓ 漏 2 天没打卡，自动发邮件给紧急联系人
✓ 紧急联系人用你的真朋友/家人，他们收到邮件说"请提醒我按时吃药"
✓ 数据本地加密，绝不上传云端（除邮件通知外）
✓ 0 注册 0 账号 0 手机号，30 秒开始用

【为什么需要这个 App】
精神心理疾病患者最大的健康风险不是"突发意外"，而是"突然停药"。
- 突然停 SSRI 类抗抑郁药 → 撤药反应（头晕、恶心、电击感）
- 停药 2 周是复发高峰
- 复发一次，再规律更难

慢病管家用"关怀提醒"模式 + 精神心理专版，把"善后"变成"主动干预"。
紧急联系人的角色从"发现异常"变成"提醒吃药"。

【隐私第一】
• 0 注册，开箱即用
• 你的数据本地 AES-256 加密
• 不会上传位置、通讯录、IP
• 邮件内容不包含医疗建议
• 8 元付费下载，无内购，无广告

【适合谁】
• 正在服用 SSRI / SNRI / 情绪稳定剂 / 助眠药的朋友
• 担心自己漏吃药想有"被提醒"机制的朋友
• 独居需要"安全网"的朋友
• 不想被传统精神科 App 标签刺眼的朋友
```

---

## 阶段 6：App Store 上架（1-2 天，仅 macOS）

1. 注册 Apple Developer（$99/年）
2. App Store Connect 创建 App
3. 填资料 + 截图（5+ 张）
4. 选类目：医疗
5. 内容审核：声明"非医疗器械"
6. 定价：8 元
7. 提交审核（1-7 天）

### App Store 描述

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

## 阶段 8: 国内 store + 5 厂商 push 通道 (v0.25 R54 增补)

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
