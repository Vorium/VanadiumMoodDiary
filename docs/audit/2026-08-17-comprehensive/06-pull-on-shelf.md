# Lens 6: pull-on-shelf (上架前 P0/P1 checklist)

**Date**: 2026-08-17
**Scope**: AppStore + Google Play 上架前硬阻塞 + 业务完整性
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**4.0/10** (R31 3.5 → +0.5, R115 +0.5 业务收尾, 但 7 P0 跨期残留 0 闭环拉分)

## 上架硬阻塞 (P0 跨期残留, 7 项)

| # | 项 | 阻塞 | 资源 | 预计 | 状态 |
|---|---|---|---|---|---|
| PS-1 | iOS 截图 0 张 | AppStore 必须 | 设计师 | - | 阻塞 |
| PS-2 | iOS LaunchImage 68B (缺多尺寸) | AppStore 必须 | 设计师 | - | 阻塞 |
| PS-3 | Android 截图 67B + feature_graphic 67B (缺分辨率) | Google Play 必须 | 设计师 | - | 阻塞 |
| PS-4 | chroniccare.app 域名 + 4 邮箱 ICP | 失联通道 | 域名商 | 7-20d | 阻塞 |
| PS-5 | AppIcon 1024×1024 ≥ 200KB | AppStore 必须 | 设计师 | - | 阻塞 |
| PS-6 | 5 厂商 push SDK 接入 | 国产 ROM 通知 | 5 厂商 | 1-2 月 | 阻塞 |
| PS-7 | 阿里云 SMS | 失联通知 100% 失效 | 阿里云 | 1-2 月 | 阻塞 |

> **脚本就绪**: 5 个上架检查脚本在 `scripts/` (iOS 截图 / Android 截图 / LaunchImage / 域名 ICP / AppIcon), 等 PS-1~PS-5 资源到位直接跑

## 5.1.3 抽审 (3 项)

| # | 项 | 状态 | 修复 |
|---|---|---|---|
| PS-8 | `description.txt` 5.1.1 (敏感 App) 抽审 | 文本就绪 | 等 Apple 流程 |
| PS-9 | `review_information` 4 TODO 占位 | 已修 | 跟 PS-1 截图一起 |
| PS-10 | `notes.txt` 版本号跟 pubspec 同步 | 已同步 | 1.1.0+154 final |

## 已闭环上架项 (8 项, R31 R108 R115)

| # | 项 | 状态 |
|---|---|---|
| PS-11 | 6 Android 权限白名单 | ✓ |
| PS-12 | 4 iOS usage description 白名单 | ✓ |
| PS-13 | 隐私政策 3 文档 assets/legal/ | ✓ |
| PS-14 | PIPL §13 单独同意 (check_legal_consent.py) | ✓ |
| PS-15 | 27 守门员全绿 | ✓ |
| PS-16 | 0 网络外联 (check_no_network_io.py) | ✓ |
| PS-17 | 锁屏 PII 净化 (check_pii_in_title.py) | ✓ |
| PS-18 | review_information TODO 守门员 (check_review_information_todo.py) | ✓ |

## 跨 Lens 共识

- **跟 superpowers-zh**: 7 P0 一致
- **跟 gdc-audit**: PS-1~PS-5 截图/LaunchImage/AppIcon 都是设计师资产
- **跟 Apple Health**: 5.1.3 抽审 + HealthKit 0 集成是 v1.0 长期

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 上架前 P0 闭环 | 18/18 | 11/18 (61%) |
| 上架硬阻塞 0 | 0 | ✗ 7 跨期残留 |
| 业务完整性 | 0 半成品 | ⚠ 4 半成品 (Z-11~Z-14) |

## 下轮建议 (R117 pull-on-shelf focus)

1. **P0 (外部)**: 等 PS-1~PS-5 设计师资产 → 跑 5 上架脚本
2. **P0 (外部)**: 等 PS-4 域名 ICP (7-20d)
3. **P1 (外部)**: 等 PS-6 / PS-7 (1-2 月)
4. **P2**: Z-12 hybrid 决策 + Z-13 量表趋势图 (业务完整性)
5. **P3**: 5.1.3 抽审流程对接 Apple
