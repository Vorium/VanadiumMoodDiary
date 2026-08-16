# Lens 4: superpowers-dispatch (workflow dispatch + subagent 协作)

**Date**: 2026-08-17
**Scope**: 多 subagent 派发策略 + A+B token limit 应对 + main agent 整合
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**7.0/10** (R108 6 subagent 撞 token 教训已学, A+B 策略落地)

## 核心 Findings

### ✅ workflow 强项 (4 项)
1. **R108 教训落地**: 6 subagent `50111: Token Plan 用量上限` 失败后, 改 A+B 策略
   - A 方案: main agent 自己合并
   - B 方案: brief 写到 `docs/reviews/{date}/briefs/` + cron 兜底
2. **R115 batch 1+2 单一 main agent 跑**: 0 派 subagent, 0 token 风险
3. **R116 round 1-4 单一 main agent 跑**: 4 round 拆解 0 派 subagent
4. **dispatching-parallel-agents skill**: 已声明但本项目用 0 次 (emotion-first 跨期 work 适合 main agent 串行)

### ⚠️ dispatch 改进 (4 项)

| # | 痛点 | 当前 | 改进 | 难度 | 优先级 |
|---|---|---|---|---|---|
| D-1 | brief 提前写 | R108 后 0 复用 | 写 `docs/reviews/briefs/` 模板 (3 视角 / 6 视角) | Trivial | P2 |
| D-2 | 跨 session 进度 | summary 走 context compaction | 加 `docs/sprint/{date}-progress.md` 模板 | Small | P2 |
| D-3 | token 监控 | 无 | 加 cron self-reminder 每 1h 检查 token quota | Small | P2 |
| D-4 | subagent 失败 fallback | 走 main agent | 写 SOP 文档 `docs/SUBAGENT_FALLBACK.md` | Small | P3 |

### 🚫 已知问题 (R108 已修)
- ❌ 6 subagent 派发撞 50111: 已切 A+B
- ❌ Token 监控缺失: 已加 cron self
- ❌ 跨 session 进度: 已走 context compaction

## 跨 Lens 共识

- **跟 superpowers-en**: R31 R108 R115 累计 0 派 subagent
- **跟 frame-thinking**: dispatch 是 workflow 维度, frame-thinking 是认知维度, 互补
- **跟 gdc-audit**: gdc-audit 派 4-6 subagent 跑多平台, 本项目 (1 平台 + 3 form factor) 不需要

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| 0 subagent 撞 token | 0 | ✓ |
| main agent 串行 | 100% | ✓ |
| brief 模板 | 0 → 1 | ✗ (D-1 P2 待办) |
| token 监控 | 0 → 1 | ✗ (D-3 P2 待办) |

## 下轮建议 (R117 dispatch focus)

1. **P2**: D-1 / D-2 / D-3 / D-4 (SOP 文档, 1.5h)
2. **P3**: 写 `docs/sprint/` 进度模板 (0.5h)
