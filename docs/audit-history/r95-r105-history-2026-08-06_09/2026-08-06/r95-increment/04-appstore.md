# AppStore iOS 增量审视报告 (R93 后 → R95+)

> **视角**: Apple App Store 上架合规 (App Store Review Guidelines 2.1/2.3/4.0/5.0/4.3 Spam / Privacy Manifest / TestFlight / IAP)
> **审视人**: Mavis (orchestrator, AppStore 视角)
> **基线**: [R92 AppStore 报告](../04-appstore-ios-report.md) (61.4KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: 删 36 张 iOS 67B 占位 png (Apple 拒审点清理) + 3 法律 md 加 R93 阶段 2 业务暂停说明

---

## 0. 摘要 (TL;DR)

R92 AppStore 评分 6.0/10, 9 平台配置已修, 3 法务 + IAP + SMS 未就绪, **14 P0 阻塞**。R93 删了 36 张占位 png (拒审点清理), 加 3 法律 md R93 阶段 2 说明。**R93 后新发现**: iOS 截图 + AppIcon 1024 真设计仍未补, iOS 18+ Dark Icon 4 套仍未做, IAP / AliyunSms 仍 FeatureFlag 关, TestFlight 0 跑过。

---

## 1. R92 基线复盘

**R92 AppStore 6.0/10 14 P0 阻塞**:
- 3 法务 md 律师过审 (¥45-90k, 4 周)
- 域名 `chroniccare.app` 注册 + 隐私/删除 URL
- iOS 33 张截图 + AppIcon 1024 替换占位 (设计师 2-3d + Mac)
- iOS fastlane/Appfile 4 ID 填 (apple_id/team_id/itc_team_id) (1h + Mac)
- iOS 签名 DEVELOPMENT_TEAM 填 (1h)
- iOS 18+ Dark Mode App Icon 4 套 (设计师 2-3d)
- AliyunSms 真接 (release 永远 throw StateError, XL 1-2d + 2-4w 审核)
- IAP 8 元买断真接 productId (R68 关, P0)
- iOS Podfile 真生成 (macOS 跑 `pod install`, 0.5d)
- TestFlight 跑过 (0 崩溃率数据)
- NMPA 备案 (医疗 App 上架前, 1-2 月)
- Apple Privacy Manifest (R74 已完成, ✅)
- iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey, 0.5d)
- iOS description.txt 改文案 (删"会发短信", 0.5d)

**R93 已修**:
- ✅ 36 张 iOS 67B 占位 png 删 (Apple 拒审点清理)
- ✅ 3 法律 md 加 R93 阶段 2 业务暂停说明 (隐藏 8 业务, 避 Apple 2.1 拒)
- ✅ IAP FeatureFlag 关 (避 Apple 2.1 "未提供其他购买方式" 拒)
- ✅ AliyunSms FeatureFlag 关 (release 不 throw)
- ✅ ventAudio / phqGad7I18n / fiveVendorPush / emailService FeatureFlag 关

---

## 2. R93 后新发现

### 2.1 架构层 (1 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| A-1 | iOS 截图 + AppIcon 1024 真设计仍未补 (R93 删 36 张占位但真截图未补) | `fastlane/metadata/ios/{3 locale}/` | L | **P0** |

### 2.2 底层 (3 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| A-2 | iOS 18+ Dark Mode App Icon 4 套仍未做 (设计师 2-3d) | `ios/Runner/Assets.xcassets/AppIcon-*.appiconset/` | M | P1 |
| A-3 | iOS LaunchImage.png 3 个 68 字节占位 (1×1 透明 PNG, 启动 1×1 黑屏 0.5s) | `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | XS | **P0** |
| A-4 | iOS UIScene+UIMainStoryboardFile 重复声明 (flutter-spec P0 阻断) | `ios/Runner/Info.plist` | S | P1 |

---

## 3. R92 未修的 P0/P1 (现状)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| A-5 | 3 法务 md 律师过审 (¥45-90k) | XL | **未修** (R93 加 R93 阶段 2 说明, 仍标"草稿") | **P0** |
| A-6 | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | M | **未修** | **P0** |
| A-7 | 邮箱注册 (`support@` / `privacy@`) | S | **未修** | **P0** |
| A-8 | iOS fastlane/Appfile 4 ID 填 (apple_id/team_id/itc_team_id) | S | **未修** (1h + Mac) | **P0** |
| A-9 | iOS 签名 DEVELOPMENT_TEAM 填 (3 处) | S | **未修** (1h) | **P0** |
| A-10 | iOS Podfile 真生成 (macOS 跑 `pod install`) | S | **未修** (0.5d, 需 Mac) | **P0** |
| A-11 | iOS iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey) | S | **未修** (0.5d) | **P0** |
| A-12 | iOS description.txt 改文案 (删"会发短信") | S | **未修** (0.5d) | **P0** |
| A-13 | IAP 8 元买断真接 productId (App Store Connect) | M | **未修** (R93 hidden 入口) | **P0** |
| A-14 | AliyunSms 真接 (release 永远 throw StateError) | XL | **未修** (R93 hidden 入口) | **P0** |
| A-15 | NMPA 备案 (医疗 App 上架前, 1-2 月) | XL | **未修** | **P0** |
| A-16 | TestFlight 跑 100+ 真实用户 | M | **未修** (0 跑过) | P1 |
| A-17 | iOS 18+ Dark Mode App Icon 4 套 | M | **未修** (设计师 2-3d) | P1 |
| A-18 | iOS UIScene+UIMainStoryboardFile 重复声明 | S | **未修** | P1 |
| A-19 | iOS 截图 + AppIcon 1024 真设计 (R93 删 36 张占位但真截图未补) | L | **未修** (设计师 2-3d + Mac) | **P0** |
| A-20 | 4 store 4 套独立 metadata + 截图 | L | **未修** | P1 |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-4 周, ¥45-90k + 1-2 月法务)

1. **R95 task 3**: 删 iOS LaunchImage.png 3 个 68 字节占位 (XS, 5min, Apple 拒审点)
2. **R95 task 13**: IAP 8 元买断真接 productId (M, 1-2 周, 苹果审核)
3. **R95 task 14**: 阿里云 SMS 真接 (XL, 1-2d + 2-4w 审核)
4. **R95 task 19**: 4 store 4 套独立 metadata + 截图 (L, 1-2 周)
5. **R95 task 20**: 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字)
6. **R95 task 22**: NMPA 备案 (医疗 App 上架前, 1-2 月)
7. **R95 task 35**: iOS Podfile 真生成 (Mac 跑 `pod install`, 0.5d)
8. **R95 task 36**: iOS DEVELOPMENT_TEAM 填 + 签名 (S, 1-2h)
9. **R95 task 40**: 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
10. **R95 task 41**: 邮箱注册 (`support@` / `privacy@`)
11. **R95 task 42**: iOS iCloud Backup 排除 (0.5d)
12. **R95 task 43**: iOS description.txt 改文案 (删"会发短信", 0.5d)

### 4.2 P1 重要 (1-4 周)

13. **R95 task 33**: iOS 18+ Dark Mode App Icon 4 套 (M, 2-3d, 设计师)
14. **R95 task 34**: iOS 截图 + AppIcon 1024 真设计 (L, 2-3d, 设计师 + Mac)
15. **R95 task 55**: iOS UIScene+UIMainStoryboardFile 重复声明 (S, 1-2h)
16. **R95 task 58**: `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted(success: true)` 占位 (S, 0.5d, Mac)
17. **R95 task 60**: TestFlight 跑 100+ 真实用户 (M, 2-4 周)

### 4.3 P2 建议 (1+ 月)

18. **R95 task 8**: 4 store 4 套独立 metadata + 截图 (L, 1-2 周)

### 4.4 P3 nice-to-have (3+ 月)

19. **R95 task 8**: iOS App Store Optimization (ASO) 关键词优化 (S, 1-2d)

---

**AppStore 视角报告完成时间**: 2026-08-06
**AppStore 视角报告体量**: 4.0KB
**R95+ AppStore 建议总计**: 19 项 (12 P0 + 5 P1 + 1 P2 + 1 P3)
**参考**: [00-r95-summary.md §3.4](./00-r95-summary.md#34-appstore-ios-视角--r93-后增量)
