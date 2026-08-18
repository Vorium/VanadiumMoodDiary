# R108 iOS Assets 设计 Brief (转交设计师)

> **作者**: P0 必修 subagent B (v0.30 R108)
> **基线**: v0.30.0+85
> **目标读者**: 设计师 (本任务接手人)
> **状态**: ⏳ 待设计师产出真实图 (本任务只占位 + 写 brief)

---

## 背景

R107 报告 §2.2 + §5 appstore P0 阻断项 5:

- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` 68B (空白 1×1 透明 PNG) → App 启动瞬间白屏
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 10932B (占位) → App Store Connect 上传被审核员标 "low quality icon"

R108 subagent B 不生成真实图 (无图像生成工具), 仅提供:
- 设计师 brief (本文)
- 占位生成脚本 `scripts/generate_ios_assets.sh` (Mac / Linux)
- lock-in test 防御 67B 假图 / 10932B 占位回归

---

## 1. AppIcon 1024×1024 (主图标, App Store 上传必看)

### 尺寸规格

| 平台 | 尺寸 | DPI | 用途 |
|------|------|-----|------|
| App Store | 1024×1024 | 72 | 主图标 (iTunes Connect 上传) |
| iPhone | 60×60 @2x (120×120) | 326 | iPhone home screen |
| iPhone | 60×60 @3x (180×180) | 458 | iPhone Plus / Pro Max |
| iPad | 76×76 @1x | 163 | iPad home screen |
| iPad | 76×76 @2x (152×152) | 326 | iPad Pro |
| iPad Pro | 83.5×83.5 @2x (167×167) | 326 | iPad Pro 12.9" |
| Settings | 29×29 @1x/2x/3x | — | 系统设置 / Spotlight |
| Notification | 20×20 @1x/2x/3x | — | 通知中心 |
| Spotlight | 40×40 @1x/2x/3x | — | Spotlight 搜索结果 |

### 设计要求

- **主色**: `#34C759` (Apple Health 绿) — 跟品牌 "Health & Fitness → Medical" 类别呼应
- **次色**: `#FFFFFF` (文字) / `#F2F2F7` (背景) — 跟 Apple HIG 对齐
- **图形**: 中间放 ChronicCare logo (心形 + "CC" 字)
- **风格**: 圆角 (iOS 自动), 渐变背景, 简洁
- **最小体积**: 1024×1024 ≥ 50KB (App Store Icon Guide 2024 强制)
- **其它尺寸**: ≥ 200B (避免 67B 假图模式)

### 输出文件

所有文件在 `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:

```
Icon-App-20x20@1x.png
Icon-App-20x20@2x.png
Icon-App-20x20@3x.png
Icon-App-29x29@1x.png
Icon-App-29x29@2x.png
Icon-App-29x29@3x.png
Icon-App-40x40@1x.png
Icon-App-40x40@2x.png
Icon-App-40x40@3x.png
Icon-App-60x60@2x.png
Icon-App-60x60@3x.png
Icon-App-76x76@1x.png
Icon-App-76x76@2x.png
Icon-App-83.5x83.5@2x.png
Icon-App-1024x1024@1x.png  ← 主图标 (App Store 上传)
```

### 占位生成

设计师交付前可跑占位脚本:

```bash
# Mac (sips + python3 + pillow)
brew install python pillow  # 仅首次
chmod +x scripts/generate_ios_assets.sh
./scripts/generate_ios_assets.sh

# Linux (ImageMagick)
sudo apt install imagemagick
./scripts/generate_ios_assets.sh
```

占位图通过 lock-in test (1024 ≥ 50KB, 小尺寸 ≥ 200B), 业务可上架但审核员会标 "low quality", 设计师替换为真实图后才正式提交。

---

## 2. LaunchImage (启动屏, 替代 LaunchScreen.storyboard)

### 尺寸规格

| 设备 | 尺寸 | 用途 |
|------|------|------|
| iPhone 5/SE | 640×960 | @2x |
| iPhone 6/7/8 | 750×1334 | 4.7" |
| iPhone 6+/7+/8+ | 1242×2208 | @3x (主尺寸) |
| iPhone X/XS | 1125×2436 | Super Retina |
| iPhone XR/XS Max | 1242×2688 | Super Retina HD |
| iPhone 11 Pro Max | 1242×2688 | 同上 |
| iPhone 12/13/14/15 | 1170×2532 | Super Retina XDR |

### 设计要求

- **主色**: `#34C759` (跟 AppIcon 呼应, 启动瞬间品牌一致)
- **图形**: 中间放 ChronicCare logo (心形 + "CC" 字), 跟 AppIcon 一致
- **风格**: 极简, 纯色 + 中间 logo, 避免文字 (启动瞬间用户来不及看)
- **最小体积**: 1024×1024 ≥ 1KB (避免 68B 空白模式)
- **当前状态**: iOS 12+ 推荐用 `LaunchScreen.storyboard` 替代 LaunchImage, 但项目仍保留 LaunchImage.imageset 兼容旧设备

### 输出文件

所有文件在 `ios/Runner/Assets.xcassets/LaunchImage.imageset/`:

```
LaunchImage.png      (320×480,  @1x)
LaunchImage@2x.png   (640×960,  @2x)
LaunchImage@3x.png   (1242×2208, @3x, 主尺寸)
```

### 占位生成

同 AppIcon, 跑 `scripts/generate_ios_assets.sh` 一次生成全部 3 个尺寸。

---

## 3. 设计师交付清单

- [ ] AppIcon 15 个尺寸 PNG (≥ 50KB 主图, ≥ 200B 小尺寸)
- [ ] LaunchImage 3 个尺寸 PNG (≥ 1KB, 避免 68B 空白)
- [ ] 跑 `flutter test test/ios/app_icon_size_round108_test.dart` 验证
- [ ] 跑 `flutter test test/ios/launch_image_size_round108_test.dart` 验证
- [ ] 跑 `flutter build ios --release` 验证 Xcode 接受所有图
- [ ] App Store Connect 上传测试 (用 Transporter 工具)

---

## 4. R108 subagent B 交付清单 (已完成)

- [x] 设计师 brief (本文)
- [x] 占位生成脚本 `scripts/generate_ios_assets.sh` (Mac + Linux)
- [x] lock-in test `test/ios/app_icon_size_round108_test.dart` (1024 ≥ 50KB + 14 小尺寸 ≥ 200B)
- [x] lock-in test `test/ios/launch_image_size_round108_test.dart` (3 尺寸 ≥ 1KB)
- [x] R108 注释标记 + R107 占位背景, 防御未来再误用 67B 假图

## 5. 业务上线前 TODO 清单

- [ ] 设计师产出 AppIcon + LaunchImage 真实图
- [ ] 覆盖到 `ios/Runner/Assets.xcassets/{AppIcon,LaunchImage}.imageset/`
- [ ] 跑 lock-in test 验证 (4 case 全过)
- [ ] App Store Connect 上传 + Transporter 工具验证
- [ ] Android 端同样需要 Play Store icon (512×512, 跟 R107 §6 googleplay P0 同步处理)
