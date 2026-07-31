v0.27 round 67 (Sprint 1 上架前 P0, appstore C-P0-11): iOS App Store metadata 67 字节占位

本目录所有 .png 都是 67 字节透明占位 PNG, 跟 Android 端 fastlane/metadata/android/
用的占位一致 (见 reports/audit/round66-CONSOLIDATED.md §2.1 A-5)。

上 store 前必须替换为真实截图:
- iPhone 6.5" (1242×2688 px) — 至少 3 张, 最多 10 张
- iPhone 5.5" (1242×2208 px) — 至少 3 张, 最多 10 张
- iPad 12.9" (2048×2732 px) — 至少 3 张, 最多 10 张
- app_icon (1024×1024 px, 不透明, 不能 alpha)

推荐:
1. iOS Simulator 跑 `flutter run -d "iPhone 15 Pro Max"` 截 5 个主页面
2. 实在没设备时, 用 [Screenshot.pro](https://screenshot.pro/) 生成 mockup
3. fastlane deliver 时 `skip_screenshots=false` 会自动上传
