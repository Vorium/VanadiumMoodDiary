# Lens 3: superpowers-zh (中文 doc + 法务/上架)

**Date**: 2026-08-17
**Scope**: 中文文档完整性 + 法务合规 + 上架前 P0 落地
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**7.5/10** (R31 持平, 6 大跨期 P0 跨期残留拉分)

## 核心 Findings

### ✅ 法务/上架 强项 (5 项)
1. **3 法务文档完整**: `user_agreement.md` / `privacy_policy.md` / `sensitive_data_consent.md` / `medical_disclaimer.md` 全部 assets/legal/ 落地
2. **隐私硬化 R115 batch 2**: 5 守门员 + `docs/PRIVACY_HARDENING.md` 落地证据
3. **PIPL §13 单独同意**: `check_legal_consent.py` 守门员 (R57 加, R65 完善)
4. **零外联 1.1.0 round 4b**: SMS/Email/Contacts/IAP/SafetyWatch 业务整摘, 0 残留
5. **法务文案 3 语 ARB 同步**: 1340 key (R116 round 4 清 9 orphan 后)

### ⚠️ 跨期 P0 残留 (6 项, 都是外部依赖)

| # | 内容 | 阻塞原因 | 预计解封 | 优先级 |
|---|---|---|---|---|
| Z-1 | iOS 截图 0 张 | 设计师资产 | 等设计师 | P0 (上架硬阻塞) |
| Z-2 | iOS LaunchImage 68B | 设计师资产 (缺多尺寸) | 等设计师 | P0 (上架硬阻塞) |
| Z-3 | Android 截图 67B + feature_graphic 67B | 设计师资产 (缺分辨率) | 等设计师 | P0 (上架硬阻塞) |
| Z-4 | chroniccare.app 域名 + 4 邮箱 ICP | 7-20 天 ICP 审核 | 1-2 月 | P0 (上架硬阻塞) |
| Z-5 | AppIcon 1024×1024 ≥ 200KB | 设计师资产 | 等设计师 | P0 (上架硬阻塞) |
| Z-6 | 5 厂商 push (米/华/OPP/vivo/魅族) | 1-2 月各厂商审核 | 1-2 月 | P1 (失联通知) |
| Z-7 | 阿里云 SMS | 失联通知 100% 失效 | 1-2 月 | P1 (失联通知) |

> **注**: 7 个 P0 是外部依赖, 5 个 `scripts/` 守门员已就绪, 等资源到位直接跑

### ⚠️ 5.1.3 抽审 残留 (3 项)

| # | 内容 | 状态 | 修复 |
|---|---|---|---|
| Z-8 | `description.txt` 5.1.1 (敏感 App) 抽审 | 待抽审 | 已声明, 等 Apple 5.1.3 流程 |
| Z-9 | `review_information` 4 TODO 占位 | 已修但需复审 | 跟 Z-1 截图一起 |
| Z-10 | `notes.txt` 版本号 | 已跟 pubspec 同步 | 等 release 1.1.0+154 final |

### ⚠️ 半成品 / 待办 (4 项)

| # | 位置 | 标记 | 建议 |
|---|---|---|---|
| Z-11 | `lib/core/data/services/encryption_service.dart` | `TODO(v1.0): AES-256-CBC 无完整性认证` | v1.0 加 HMAC/GCM, 当前 OK |
| Z-12 | `lib/domain/logic/scale_registry.dart` | `TODO (v0.31+ 决定, user 选 hybrid)` | v0.31 已过, 选 hybrid 决策 |
| Z-13 | `lib/presentation/pages/assessment/assessment_center_page.dart` | `// TODO (Task 5)` | 12 量表卡片堆叠待加趋势图 |
| Z-14 | `lib/core/theme/app_theme.dart` | 1 TODO | 主题切换细节 |

## 跨 Lens 共识

- **跟 superpowers-en**: 中文 doc 完整, EN 摘要是 gap (S-EN-1~4)
- **跟 gdc-audit / pull-on-shelf**: 7 个 P0 跨期残留一致
- **跟 Apple Health**: 5.1.3 + HealthKit 是 v1.0 长期, 当前 emotion-first 不依赖

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 27 守门员 | 全绿 | ✓ |
| 0 外联 import | 0 | ✓ |
| 法务 3 文档 3 语 ARB | 同步 | ✓ |
| 1340 key | 0 orphan | ✓ |

## 下轮建议 (R117 ZH focus)

1. **P0 (外部)**: 等 Z-1~Z-5 设计师资产到 → 跑 5 个上架脚本
2. **P1**: Z-6 / Z-7 (1-2 月外部)
3. **P2**: Z-12 hybrid 决策 + Z-13 量表趋势图
4. **P3**: Z-14 主题细节
