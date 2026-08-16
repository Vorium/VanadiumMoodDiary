# Lens 11: Apple Health (HealthKit + 5.1.3 抽审)

**Date**: 2026-08-17
**Scope**: HealthKit 集成 + 5.1.3 抽审 + Apple 5.1.1 敏感 App + 视觉风格 lock-in
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**7.0/10** (R31 7.0 持平, 视觉层 9.5/10 优秀, 11 feature 仍 0 改是减分项)

## 核心 Findings

### ✅ 视觉风格 (1 项, R31 优秀)
- **5 token + 6 widget 集中器**: iOS 17/18 视觉语言 100% 落地
- **AppleListSection**: iOS insetGrouped 风格 6 section + 5 group + 4 subpage
- **AppleHealthTile**: 8 metric 彩色模块 (但内容 0 集成 HealthKit, 走应用内数据)

### ✅ 5.1.3 抽审准备 (3 项)

| # | 项 | 状态 |
|---|---|---|
| AH-1 | 4 文档准备: 医疗免责声明 / 隐私政策 / 用户协议 / 临床审核证据 | ✓ 3/4 (临床审核待法务) |
| AH-2 | PHQ-9 / GAD-7 16 题 i18n 走 fallback (FeatureFlag `phqGad7I18nEnabled=false`) | ✓ |
| AH-3 | emotion-first 定位 (不上 HealthKit, 不上 ResearchKit) | ✓ 1.1.0 round 4b |

### ⚠️ HealthKit 0 集成 (1 项, v1.0 长期)

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| AH-4 | HealthKit auth 集成 | 0 集成 | 11 health metric 在 AppleHealthTile 展示但都走应用内数据 |
| AH-5 | ResearchKit / CareKit | 0 集成 | v1.0 长期 |
| AH-6 | `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` | 0 添加 | 走 emotion-first 不依赖 HealthKit |
| AH-7 | `health_kit` 文档声明 lock-in (R31 P0-004) | ✓ 0 声明 | R31 spec 守门员 `check_apple_health_claim.py` |

### ⚠️ 5.1.1 敏感 App 抽审 (1 项)

| # | 项 | 状态 | 说明 |
|---|---|---|---|
| AH-8 | `description.txt` 5.1.1 抽审声明 | 文本就绪 | 等 Apple 流程 |

### 视觉层 vs 数据层 矛盾 (3 项)

| # | 矛盾 | 当前 | 风险 |
|---|---|---|---|
| AH-9 | AppleHealthTile 视觉 8 metric 都"看起来像 HealthKit" | 实际 0 集成 | 用户疑惑"为什么没数据" |
| AH-10 | "5.1.3 敏感 App 抽审"声明 + "0 HealthKit" | 5.1.3 适用所有健康类 | Apple 抽审可能问"为何不接 HealthKit" |
| AH-11 | "Apple Health 风格" 文档 lock-in | spec.md 22KB 中性 | 不在 doc / 注释 lock-in "Apple Health" 关键词 |

## 跨 Lens 共识

- **跟 superpowers-zh**: AH-1 = Z-12 / Z-13 半成品
- **跟 pull-on-shelf**: AH-8 5.1.1 抽审 = PS-8
- **跟 gdc-audit**: AH-4~AH-7 HealthKit 0 集成跨期残留
- **跟 emil / flutter-audit**: AppleHealthTile 8 metric 视觉 vs 数据 gap (AH-9)

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 视觉层 9.5/10 | 5 token + 6 widget + AppleListSection | ✓ |
| HealthKit 0 集成 | 0 声明 | ✓ |
| 5.1.3 抽审准备 | 3/4 文档 | ✓ |
| AppleHealthTile 视觉 vs 数据 gap | 0 | ✗ AH-9 待说明 |

## 下轮建议 (R117 Apple Health focus)

1. **P0 (外部)**: AH-8 5.1.1 抽审流程 (内部可走)
2. **P2**: AH-9 视觉 vs 数据 gap 加 tooltip 解释"应用内数据,不上 HealthKit"
3. **P3**: AH-4~AH-7 HealthKit 集成 v1.0 长期

## 关键设计决策 (lock-in)

- **emotion-first 优先 HealthKit**: 1.1.0 round 4b 删除 4 文档 "HealthKit 集成" 段落
- **5.1.3 抽审必须**: 4 文档 + PHQ-9/GAD-7 法务 + 临床审核
- **AppleHealthTile 是视觉 0 数据**: 不假装 HealthKit, 不写 `health_kit` 文档声明
- **守门员 `check_apple_health_claim.py`**: 0 "Apple Health" 关键词 + 0 `health_kit` 声明 lock-in
