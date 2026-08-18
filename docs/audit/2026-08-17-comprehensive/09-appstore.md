# Lens 9: AppStore (iOS 上架细节)

**Date**: 2026-08-17
**Scope**: AppStore Connect metadata + 5.1.3 抽审 + Info.plist + 截图 + LaunchImage
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**3.5/10** (持平 R31, 5 P0 跨期残留 0 闭环, 5.1.3 抽审待走)

## 核心 Findings

### ✅ 已闭环 (8 项, R31 R108 R115)

| # | 项 | 状态 |
|---|---|---|
| AS-1 | `NSMicrophoneUsageDescription` (vent + mood 录音) | ✓ |
| AS-2 | `NSSpeechRecognitionUsageDescription` (语音转写) | ✓ |
| AS-3 | `NSPhotoLibraryUsageDescription` (PDF 分享) | ✓ |
| AS-4 | `NSPhotoLibraryAddUsageDescription` (保存 PDF) | ✓ |
| AS-5 | `UIBackgroundModes` audio (R108 恢复, vent 录音) | ✓ |
| AS-6 | 锁屏 PII 净化 (check_pii_in_title.py 3 处) | ✓ |
| AS-7 | 16KB alignment (iOS 18 App Store 2025-04 强制) | ✓ |
| AS-8 | 5 厂商 push pre-check 守门员 | ✓ |

### ⚠️ P0 跨期残留 (5 项)

| # | 项 | 状态 | 阻塞 | 资源 |
|---|---|---|---|---|
| AS-9 | iOS 截图 0 张 (6.7" + 6.1" + 5.5" 3 套 × 5 张) | 阻塞 | AppStore 必须 | 设计师 |
| AS-10 | iOS LaunchImage 68B (缺 1024×1024 + 1242×2688 + 2688×1242) | 阻塞 | AppStore 必须 | 设计师 |
| AS-11 | AppIcon 1024×1024 ≥ 200KB | 阻塞 | AppStore 必须 | 设计师 |
| AS-12 | 5.1.3 (敏感 App) 抽审流程 | 待走 | Apple 审核 | 内部 |
| AS-13 | chroniccare.app 域名 ICP | 阻塞 | 失联通道 | 7-20d |

### ⚠️ AppStore Connect metadata (3 项)

| # | 项 | 状态 | 修复 |
|---|---|---|---|
| AS-14 | `description.txt` 5.1.1 (敏感 App 抽审) | 文本就绪 | 等 Apple 流程 |
| AS-15 | `review_information` 4 TODO 占位 | 已修 | 跟 AS-9 截图一起 |
| AS-16 | `notes.txt` 版本号跟 pubspec 同步 | 已同步 (1.1.0+149) | 等 release 1.1.0+154 final |

### ⚠️ 5.1.3 抽审 (1 项, 长期)

| # | 项 | 说明 |
|---|---|---|
| AS-17 | 5.1.3 健康/心理类 App | Apple 5.1.3 抽审流程, 需提交 4 文档: 医疗免责声明 / 隐私政策 / 用户协议 / 临床审核证据 (PHQ-9/GAD-7 等) |

> **注**: emotion-first 不需要 HealthKit, 但 PHQ-9/GAD-7 量表 16 题 i18n 走 fallback (FeatureFlag `phqGad7I18nEnabled=false`), 等法务 + 临床审核后翻 true

### 已闭环 4.7" / 12.9" iPad (0 项, 长期)

| # | 项 | 状态 |
|---|---|---|
| AS-18 | iPad multitasking | 未支持 (iPhone-only 当前) |
| AS-19 | iPad 12.9" 截图 | 阻塞 (跟 AS-9 一起) |

## 5 个上架检查脚本 (就绪)

```
scripts/check_appstore_screenshots.py   (iOS 6.7"/6.1"/5.5" 3 套)
scripts/check_ios_launchimage.py        (1024/1242/2688 三尺寸)
scripts/check_appicon_size.py           (1024×1024 ≥ 200KB)
scripts/check_domain_icp.py             (chroniccare.app + 4 邮箱)
scripts/check_appstore_metadata.py      (description / review / notes)
```

> 等 AS-9~AS-13 资源到位直接跑

## 跨 Lens 共识

- **跟 superpowers-zh**: AS-9~AS-13 = Z-1~Z-5 跨期残留
- **跟 pull-on-shelf**: 7 P0 = AS-9~AS-13 + AS-6 (P1) + AS-7 (P1)
- **跟 Apple Health**: AS-17 5.1.3 + AH-3 HealthKit 0 集成是 v1.0 长期

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 上架前 8 项闭环 | 8/8 | ✓ |
| 5 P0 跨期残留 0 | 0 | ✗ 5 跨期残留 |
| 5.1.3 抽审 | 1 流程 | 0 (长期) |

## 下轮建议 (R117 AppStore focus)

1. **P0 (外部)**: 等 AS-9~AS-11 设计师资产 → 跑 3 个上架脚本
2. **P0 (外部)**: 等 AS-13 域名 ICP (7-20d)
3. **P1**: AS-12 5.1.3 抽审流程 (内部可走)
4. **P3**: AS-17 / AS-18 / AS-19 长期 (iPad + HealthKit)
