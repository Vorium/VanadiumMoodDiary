# 慢病管家 · 部署指南

> 4 周从零到上架 App Store + Google Play

---

## 阶段 0：开发环境（1 天）

### macOS（推荐）
```bash
# 1. 装 Xcode（App Store 搜 Xcode）
# 2. 装 Flutter
brew install fvm
fvm install 3.44.5
fvm use 3.44.5

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
flutter run -d chrome         # 跑 Web 版看 UI
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
精神心理疾病患者最大的健康风险不是"突然死了"，而是"突然停药"。
- 突然停 SSRI 类抗抑郁药 → 撤药反应（头晕、恶心、电击感）
- 停药 2 周是复发高峰
- 复发一次，再治愈更难

慢病管家用"死了么"模式 + 精神心理专版，把"善后"变成"主动干预"。
紧急联系人的角色从"发现死亡"变成"提醒吃药"。

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
- 多语言
