# iOS + Android 截图自动化设置指南 (R108)

> **范围**: v0.30 R108 P0 #12 — Android + iOS 上架 P0 阻塞之四
> **基线**: v0.30.0+85 / 2026-08-10 cleanup
> **读者**: 需要上架 App Store + Google Play 的 dev / DevOps
> **关联**: `scripts/generate_ios_screenshots.sh` (R108) + `scripts/generate_android_screenshots.sh` (R108)

---

## 一、为什么是 P0 阻塞

| 平台 | 需求 | 当前状态 | 拒因 |
|---|---|---|---|
| **iOS** | 5 设备 × 3 locale × 5 屏 = 75 张 | 0 张 (R100 删了占位) | "Screenshots required" |
| **Android 手机** | 4 张 × 2 locale = 8 张 | 8 张 67B 占位 (1×1 透明 PNG) | "Screenshots required" |
| **Android 7" 平板** | ≥1 张 × 2 locale = 2 张 | ❌ 不存在 | "Tablet design required" |
| **Android 10" 平板** | ≥1 张 × 2 locale = 2 张 | ❌ 不存在 | "Tablet design required" |

**R108 自动化**: 写 2 个脚本, 跑完生成所有占位 → 真实截图。

---

## 二、平台选择

| 平台 | 脚本 | 何时用 |
|---|---|---|
| **iOS** | `scripts/generate_ios_screenshots.sh` (R108) | **Mac only** (Xcode 必需), 用 xcrun simctl 模拟器 |
| **Android** | `scripts/generate_android_screenshots.sh` (R108) | Mac/Linux/WSL (Android Studio 必需), 用 adb + emulator |

iOS 不能在 Windows/Linux 跑 (Apple 限制), Android 跨平台。

---

## 三、5 设备 + 3 locale + 5 屏 = 75 张 (iOS)

### 5 设备

| 设备 | 模拟器名 | 屏幕分辨率 | fastlane 子目录 |
|---|---|---|---|
| iPhone 16 Pro Max | iPhone 16 Pro Max | 1290 × 2796 | `iphone_6_7_screenshots/` |
| iPhone 11 Pro Max | iPhone 11 Pro Max | 1242 × 2688 | `iphone_6_5_screenshots/` |
| iPhone 8 Plus | iPhone 8 Plus | 1242 × 2208 | `iphone_5_5_screenshots/` |
| iPad Pro 12.9" (3rd gen) | iPad Pro 12.9-inch (3rd generation) | 2048 × 2732 | `ipad_12_9_screenshots/` |
| iPad Pro 11" (M4) | iPad Pro 11-inch (M4) | 1668 × 2388 | `ipad_11_screenshots/` |

### 3 locale

- `en-US` (英语)
- `zh-Hans` (简体中文)
- `zh-Hant` (繁体中文)

### 5 屏 (用 deep link 切)

| 屏 | 路径 | deep link |
|---|---|---|
| 1. 主页 | `/home` | `chroniccare://home` |
| 2. 心情 | `/mood` | `chroniccare://mood` |
| 3. 树洞 | `/vent` | `chroniccare://vent` |
| 4. 用药 | `/medication` | `chroniccare://medication` |
| 5. 评估 | `/assessment` | `chroniccare://assessment` |

**总产出**: 5 × 3 × 5 = **75 张** PNG, 按 fastlane 实际目录结构放到 15 个子目录。

---

## 四、4 主流程 + 3 设备 + 2 locale = 10 张 (Android)

### 3 设备 (AVD 名需根据实际调整)

| 设备 | AVD 名 (建议) | 屏幕分辨率 | fastlane 子目录 |
|---|---|---|---|
| Pixel 8 phone | Pixel_8_API_34 | 1080 × 2400 | `phoneScreenshots/` |
| 7" 平板 | Pixel_Tablet_7_API_34 | 1024 × 600 | `sevenInchScreenshots/` |
| 10" 平板 | Pixel_Tablet_10_API_34 | 2560 × 1600 | `tenInchScreenshots/` |

> **重要**: 实际 AVD 名以 `emulator -list-avds` 输出为准。R108 脚本里 `Pixel_Tablet_7_API_34` 是占位, 第一次跑前需:
> ```bash
> emulator -list-avds
> # 输出形如: Pixel_7_Tablet_API_34, Pixel_10_Tablet_API_34
> # 编辑脚本 DEVICES 数组, 改占位为真实 AVD 名
> ```

### 2 locale

- `en-US` (英语)
- `zh-CN` (简体中文)

### 4 屏 (用 deep link 切)

| 屏 | 路径 | deep link |
|---|---|---|
| 1. 主页 | `/home` | `chroniccare://home` |
| 2. 心情 | `/mood` | `chroniccare://mood` |
| 3. 树洞 | `/vent` | `chroniccare://vent` |
| 4. 用药 | `/medication` | `chroniccare://medication` |

> **R108 简化**: Android 只截 4 屏 (业务核心), 评估 5 屏留给 iOS (Apple 强制要更多屏)。

**总产出**: (4 × 2) + 2 + 2 = **12 张** (4 屏 × 2 locale 手机 + 2 平板 × 2 locale)。

---

## 五、5 步生成 + 上架流程 (iOS)

### Step 1: 装 Mac + Xcode 15+ (必备)

```bash
# 验证环境
sw_vers                   # macOS 13+ (Ventura)
xcodebuild -version       # Xcode 15+ (含 iOS 17 SDK)
flutter --version         # Flutter 3.41+ (本项目 3.41.9)

# 装 iOS 模拟器 (Xcode → Settings → Platforms)
# 5 设备模拟器: Xcode → Window → Devices and Simulators → + 按钮
#   - iPhone 16 Pro Max (iOS 17.0+)
#   - iPhone 11 Pro Max (iOS 14.0+)
#   - iPhone 8 Plus (iOS 14.0+)
#   - iPad Pro 12.9-inch (3rd generation) (iOS 16.0+)
#   - iPad Pro 11-inch (M4) (iOS 17.0+)
```

### Step 2: 装 ffmpeg (iPhone 6.5"/5.5" 缩放用)

```bash
brew install ffmpeg
```

### Step 3: 跑脚本

```bash
chmod +x scripts/generate_ios_screenshots.sh
./scripts/generate_ios_screenshots.sh

# 跑完输出:
#   [OK] iOS 截图生成完成! 总计 75 张
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_7,iphone_6_5,iphone_5_5,ipad_12_9,ipad_11}_screenshots/screenshot_1..5.png
```

### Step 4: 人工 review

```bash
# macOS 预览
open fastlane/metadata/ios/en-US/iphone_6_7_screenshots/

# 检查项:
# 1. 5 屏顺序对 (home → mood → vent → medication → assessment)
# 2. 没有 PII (用户名 / 头像 / 真实数据)
# 3. 没有 UI bug (错位 / 文字截断 / 颜色异常)
# 4. 关键功能突出 (打卡按钮 / 危机电话 / 隐私承诺)
```

### Step 5: 上传 App Store Connect

```bash
# 选 1: Transporter (Apple 官方)
# 1. 打开 Transporter
# 2. 登录 Apple ID
# 3. 拖入 build/ios/Runner.ipa + fastlane/metadata/ios/ 整个目录
# 4. Transporter 自动按 fastlane 目录结构上传

# 选 2: fastlane (推荐, CI 友好)
bundle exec fastlane ios upload_screenshots
# (Fastfile 需配 deliver 步骤, 见 R108 后续 R110)
```

App Store Connect → App Store 版本信息 → 截图 → 选 5 设备各 5 张。

---

## 六、5 步生成 + 上架流程 (Android)

### Step 1: 装 Android Studio + SDK (必备)

```bash
# 验证
adb --version             # Android Debug Bridge 1.0.41+
emulator -version         # Android Emulator 34.0.0+
flutter --version         # Flutter 3.41+

# 配 PATH (Mac 示例)
export PATH="$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"

# 装 3 个 AVD (Android Studio → Virtual Device Manager)
#   - Pixel 8 (API 34, 手机)
#   - Pixel Tablet 7" (API 34, 平板)
#   - Pixel Tablet 10" (API 34, 平板)
```

### Step 2: 准备 App deep link (R108 简化)

App `AndroidManifest.xml` 需注册 deep link scheme `chroniccare://`:

```xml
<activity android:name=".MainActivity" android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="chroniccare" android:host="mood" />
    <!-- ... -->
  </intent-filter>
</activity>
```

go_router 配:

```dart
GoRouter(
  routes: [
    GoRoute(path: '/mood', builder: (context, state) => MoodPage()),
    // ...
  ],
);
// URL: chroniccare://mood
```

> **⚠️ R108 简化**: 如果 App 还没注册 deep link, 脚本会用 adb input tap 模拟 (基于 UI 坐标)。但更可靠是先注册 deep link。

### Step 3: 跑脚本

```bash
chmod +x scripts/generate_android_screenshots.sh
./scripts/generate_android_screenshots.sh

# 跑完输出:
#   [OK] Android 截图生成完成! 总计 12 张
#   fastlane/metadata/android/{en-US,zh-CN}/{phoneScreenshots,sevenInchScreenshots,tenInchScreenshots}/screenshot_*.png
```

### Step 4: 人工 review

```bash
# Windows / Mac / Linux 任意看图工具
# 检查项同 iOS
```

### Step 5: 上传 Google Play Console

```bash
# 选 1: Google Play Console 网页手动
# 1. 打开 https://play.google.com/console
# 2. 选 ChronicCare → Store presence → Main store listing
# 3. Phone / 7" tablet / 10" tablet tab 各上传 4 / 1 / 1 张

# 选 2: fastlane (推荐, CI 友好)
bundle exec fastlane supply \
  --package_name app.chroniccare.patient \
  --metadata_path fastlane/metadata/android \
  --track internal \
  --validate_only
```

---

## 七、5 屏内容建议 (每屏放什么)

### 屏 1: 主页 (home)

- 打卡按钮 (大, 突出)
- 当日 streak (e.g., "已坚持 30 天")
- 今日心情 emoji
- 底部: 树洞 / 设置入口

### 屏 2: 心情 (mood)

- 1-5 颗星选择
- 标签 (焦虑 / 平静 / 沮丧 / 开心)
- "点一下 = 30 秒内可记录"

### 屏 3: 树洞 (vent)

- 大录音按钮
- 60 秒限时提示
- "本地加密, 永不云端" 强调

### 屏 4: 用药 (medication)

- 药名 (脱敏, 不写真实药名)
- 剂量
- 打卡勾
- "下次用药" 倒计时

### 屏 5: 评估 (assessment, iOS only)

- PHQ-9 / GAD-7 入口
- "临床量表" 标签
- "结果不出现在医疗决策" 免责

> **PII 警告**: 截图时用 mock 数据, 不能用真实患者姓名 / 头像 / 真实药名 (e.g., "Zoloft 50mg" → 改 "抗抑郁药 A 50mg")。

---

## 八、CI 集成 (参考)

### GitHub Actions 例 (iOS, Mac runner)

```yaml
# .github/workflows/ios-screenshots.yml
jobs:
  ios-screenshots:
    runs-on: macos-14   # Apple Silicon
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.9"
      - name: Build + screenshots
        run: ./scripts/generate_ios_screenshots.sh
      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/ios/Runner.ipa
```

### GitHub Actions 例 (Android, Linux runner)

```yaml
# .github/workflows/android-screenshots.yml
jobs:
  android-screenshots:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.9"
      - uses: android-actions/setup-android@v3
      - name: Build + screenshots
        run: ./scripts/generate_android_screenshots.sh
      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_CONSOLE_SA_JSON }}
          packageName: app.chroniccare.patient
          metadataPath: fastlane/metadata/android
          track: internal
```

---

## 九、未做 / 风险 / 下一步

### 已知限制

- **deep link 注册需 R108 提前做** — 当前 App 还没注册, 脚本第 1 次跑会失败, 需 dev 先加 `<intent-filter>`
- **5 设备 iOS 模拟器首次启动慢** — 整个脚本 5 设备 × 3 locale × 5 屏 = 75 张, 预计 60-90 分钟
- **截图内容是 mock 数据** — 真实业务跑前需在 App 内 prepopulate 测试数据 (避免空白屏)
- **Apple review_information/ 目录** — R108 单独 P0 #6, 见 `R108-ios-review-information.md` (后续 R110)

### 后续优化 (R109+)

- R109: 集成 Maestro (`https://maestro.mobile.dev/`) 替代 deep link, 真实 UI 自动化
- R109: 加 `feature_graphic.png 1024×500` 自动生成 (从主页截图裁切)
- R110: 集成 Figma API 替换 mock 截图 (让设计师审过再生成)
- R110: 集成 BrowserStack / Sauce Labs 跨真机测试

---

## 十、Checklist (上架前逐项过)

### iOS

- [ ] 5 设备 iOS 模拟器已装 (Xcode → Devices and Simulators)
- [ ] `flutter build ios --release --no-codesign --simulator` 成功
- [ ] ffmpeg 已装 (`brew install ffmpeg`)
- [ ] `./scripts/generate_ios_screenshots.sh` 跑完, 总计 75 张
- [ ] 5 设备 × 3 locale 目录都有 5 张 PNG, 每张 > 100KB
- [ ] 人工 review 完 (无 PII, 5 屏顺序对, 关键功能突出)
- [ ] App Store Connect → 截图 → 5 设备各 5 张已上传

### Android

- [ ] 3 设备 AVD 已建 (Pixel 8 + 7" + 10" 平板)
- [ ] `emulator -list-avds` 输出 ≥ 3 个 AVD
- [ ] 脚本 `DEVICES` 数组已改为真实 AVD 名
- [ ] App `<intent-filter>` 已注册 `chroniccare://` deep link
- [ ] go_router 配好 deep link → page 路由
- [ ] `flutter build apk --release` 成功
- [ ] `./scripts/generate_android_screenshots.sh` 跑完, 总计 12 张
- [ ] 2 locale × 3 form factor 目录都有 PNG, 每张 > 50KB
- [ ] 人工 review 完
- [ ] Google Play Console → 商店发布 → 3 设备目录各上传

---

## 十一、相关文件清单

| 文件 | 类型 | 作用 |
|---|---|---|
| `scripts/generate_ios_screenshots.sh` | Bash 脚本 (R108, Mac only) | iOS 5 设备 × 3 locale × 5 屏 = 75 张 |
| `scripts/generate_android_screenshots.sh` | Bash 脚本 (R108, Mac/Linux/WSL) | Android 3 设备 × 2 locale × 4 屏 = 12 张 |
| `android/app/src/main/AndroidManifest.xml` | App config (R108 需求) | 注册 `chroniccare://` deep link |
| `lib/core/routing/app_router.dart` | App config (R108 需求) | 配 goRouter + deep link |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/**` | 输出 | 75 张 iOS 截图 |
| `fastlane/metadata/android/{en-US,zh-CN}/**` | 输出 | 12 张 Android 截图 |
