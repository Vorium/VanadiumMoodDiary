# Lens 10: Googleplaystore (Android 上架细节)

**Date**: 2026-08-17
**Scope**: Google Play Console metadata + AndroidManifest + 截图 + feature_graphic + 16KB alignment
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**5.5/10** (持平 R31, R117 round 5 工具链适配 +0.5, 2 P0 跨期残留拉分)

## 核心 Findings

### ✅ 已闭环 (10 项, R31 R108 R115 R117 round 5)

| # | 项 | 状态 |
|---|---|---|
| GP-1 | 6 Android 权限白名单 | ✓ |
| GP-2 | 30+ 权限黑名单 (SMS/位置/相机/Contacts/存储写 等) | ✓ |
| GP-3 | `INTERNET` 权限保留 (R114 注释"未来预留", 当前 0 网络) | ✓ |
| GP-4 | `POST_NOTIFICATIONS` (Android 13+) | ✓ |
| GP-5 | `SCHEDULE_EXACT_ALARM` (精准闹钟) | ✓ |
| GP-6 | `WAKE_LOCK` (通知触发) | ✓ |
| GP-7 | `VIBRATE` (通知震动) | ✓ |
| GP-8 | `RECORD_AUDIO` (vent + mood 录音) | ✓ |
| GP-9 | 16KB alignment (Google Play 2025-11-01 强制) | ✓ |
| GP-10 | Gradle 8.14 + NDK 28.2.13676358 (R117 round 5 落地) | ✓ |

### ⚠️ P0 跨期残留 (2 项)

| # | 项 | 状态 | 阻塞 | 资源 |
|---|---|---|---|---|
| GP-11 | Android 截图 67B (缺多分辨率) | 阻塞 | Google Play 必须 | 设计师 |
| GP-12 | feature_graphic 67B (1024×500) | 阻塞 | Google Play 必须 | 设计师 |

### ⚠️ Google Play Console metadata (2 项)

| # | 项 | 状态 | 修复 |
|---|---|---|---|
| GP-13 | `description.txt` 中文主, EN 备用 | ✓ | R115 落地 |
| GP-14 | `data_safety` 0 数据外发声明 | ✓ | R115 落地 |
| GP-15 | 18 gatekeeper 守门员 (含 16KB alignment) | ✓ | R108 R115 累计 |

### ⚠️ 国产 ROM 适配 (5 项, 长期)

| # | 项 | 说明 |
|---|---|---|
| GP-16 | 5 厂商 push (米/华/OPP/vivo/魅族) | 1-2 月审核, FeatureFlag `fiveVendorPushEnabled=false` |
| GP-17 | 国产 ROM 静默杀后台 | 已加 NotificationStatusCard 自检卡 (R16 round 20) |
| GP-18 | OEM 自启动引导 | 设置页加引导文字 |
| GP-19 | 精确闹钟权限引导 | `USE_EXACT_ALARM` (Android 14+) 替代 SCHEDULE_EXACT_ALARM |
| GP-20 | 应用商店签名 (Play App Signing) | R67 上架前 P0 已配 |

## 4 FeatureFlag 状态

| Flag | 当前 | 翻 true 条件 | 优先级 |
|---|---|---|---|
| `phqGad7I18nEnabled` | **false** | PHQ-9/GAD-7 16 题 i18n 走完 ARB | P2 |
| `bootReceiverEnabled` | **false** | WorkManager 完善 (R55 阶段) | P3 |
| `fiveVendorPushEnabled` | **false** | 5 厂商 push SDK 接入 | P1 (1-2 月) |
| `ventAudioEnabled` | **true** | R104 已翻 true | - |

## 跨 Lens 共识

- **跟 superpowers-zh**: GP-11 / GP-12 = Z-3 跨期残留
- **跟 pull-on-shelf**: 2 P0 + 5 厂商 push (GP-16) = 7 P0
- **跟 gdc-audit**: GP-17~GP-19 国产 ROM 长期

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 10 项闭环 | 10/10 | ✓ |
| 16KB alignment | 守门员 + Gradle 8.14 + NDK 28.2 | ✓ (R117 round 5 落地) |
| 2 P0 跨期残留 0 | 0 | ✗ 2 跨期残留 |

## 下轮建议 (R117 GooglePlay focus)

1. **P0 (外部)**: 等 GP-11 / GP-12 设计师资产 → 跑 2 个上架脚本
2. **P1 (外部)**: GP-16 5 厂商 push (1-2 月)
3. **P2**: GP-19 USE_EXACT_ALARM 迁移 (Android 14+)
4. **P3**: GP-17 / GP-18 ROM 自检 + 引导
