# Lens 4: superpowers-dispatch (A+B 策略 + skill 派单)

**Date**: 2026-08-18
**Scope**: R108~R128d 跨 11 round 派单策略 + A+B token limit 应对 + main agent 整合 + R128e 5 worker × 2 lens = 10 subagent 派单实战
**Baseline**: 1.1.0+185, 2728 tests pass / 0 fail / 1 skip, 24 守门员全绿, 1340 ARB keys, 6 features (R128b +crisis)

## 总体评分

**7.5/10** (R120 7.0 → **+0.5**, R128e 5 worker × 2 lens = 10 subagent 派单实战 + A+B 策略落地 + R128d step 2 4-7 视角综合审视模板沉淀)

## 核心 Findings

### ✅ 优点 / 强项 (4 项)

1. **A+B 策略 R128e 实战落地**: R108 6 subagent 撞 `50111: Token Plan 用量上限` 失败后, 改 A+B 策略 — A: main agent 整合 (R120 4 视角) + B: brief 提前写 + 派 subagent 完整跑 (R128e 5 worker × 2 lens = 10 份报告, 本批为其中 2 份 lens 3+4)。本批 R128e brief 包含 R128a~R128d 4 round 跨期一致性验证表 + 跨期 5 P0 external 残留 + 24 守门员基线 = 完整 brief 模板。
2. **R120 brief 模板复用 + R128d step 2 综合审视模板沉淀**: R120 4 视角报告 (docs/audit/2026-08-17-round120/) 模式复用 → R128e 10 视角扩展; R128d step 2 计划 4-7 视角 (emil + superpowers-zh + superpowers-en + flutter-spec + frame-thinking + Apple Health + 顶层架构) 模板沉淀 (R108 revisit 9 视角 40KB 整合模式)。
3. **R128a~R128d 跨 4 round 派单 100% 合规**: R128a (1.1.0+181) / R128b (1.1.0+182) / R128c (1.1.0+183) / R128d (1.1.0+184) 每 round 1 commit 修真 + 修真基线 0 raw (0 error / 26 warn / 433 info) + 2728 tests 0 行为变化 + 守门员 0 新增 violation, 跨期 1 周综合审视 ⏸ (R128d step 2 跨期未跑)。
4. **dispatching-parallel-agents + git worktree 协同**: R108 6 subagent 撞 token 教训后, R128a~R128d 跨 4 round 都用 dispatching-parallel-agents skill 1 worker 1 commit 修真模式 + git worktree 隔离 (worktree list 1 主 worktree 0 副 worktree, 因为 1 worker 1 commit 修真走同 cwd 顺序 dispatch — 修真模式稳定, R128e 5 worker × 2 lens 派单 = 5 worker 顺序 dispatch 仍同 cwd)。

### ⚠️ 待优化 (5 项)

| # | 类别 | 内容 | 影响 | 估时 | 优先级 |
|---|---|---|---|---|---|
| D-5 | SOP 缺 | **R120 建议 `docs/SUBAGENT_FALLBACK.md` SOP 0 落地** | R108 6 subagent 撞 token fallback 步骤仍靠 main agent 经验, 缺 SOP 文档化, 后续跨期 8 round 撞同款风险 | 1h 写 SOP (含 token 监控 + brief 模板 + fallback 步骤) | **P0** |
| D-6 | 并行隔离 | **R128e 5 worker 派单 0 git worktree 隔离** | 5 worker × 2 lens 顺序 dispatch 同 cwd 串行, 修真 token 风险降 0 但修真时间 ×5, R108 教训应 push 5 worker 5 worktree 隔离 | 2h git worktree 改造 (5 worker 5 worktree) | **P0** |
| D-7 | 模板缺 | **R120 建议 `docs/reviews/{date}/briefs/` 模板 0 落地** | R120 报 D-1 P2 待办跨期 8 round 仍 0 落地, 当前 brief 都 inline 在主对话上下文, 跨 session 0 持久化 | 1h 写模板 (3 视角 / 6 视角 / 10 视角 3 套) | **P1** |
| D-8 | 监控缺 | **R120 建议 cron self-reminder 每 1h 检查 token quota 0 落地** | R108 撞 token 修真方案 1, 跨期 8 round 0 落地, R128e 5 worker 派单 0 撞 quota 是运气 (quota 充足) | 0.5h 加 cron self 模板 | **P1** |
| D-9 | 进度模板 | **R120 建议 `docs/sprint/{date}-progress.md` 0 落地** | 跨期 8 round 进度走 git log + AGENTS.md, 缺 sprint 进度单文件汇总, R128e 5 worker 进度靠 main agent context compaction | 0.5h 写模板 | **P2** |

### 🚫 红线 (0 项)
- ✅ R128e 5 worker 派单 0 撞 token quota (quota 充足)
- ✅ R128a~R128d 跨 4 round 修真基线 0 raw (修真基线稳定)
- ✅ 0 SUBAGENT_FALLBACK 失败案例 (R108 后 0 撞)

## 跨 Lens 共识

- **跟 Lens 3 superpowers-zh**: 24 守门员 (20 .py + 1 .dart + 3 规则) + 2728 tests = 派单决策的"数据基准", 缺 1 数据点 = 派单缺判断依据, 需跟 superpowers-zh 协同修真 doc 同步链路 (本批 03-superpowers-zh Z-15 + Z-16 + Z-17)
- **跟 frame-thinking**: A+B 策略是工具维度 vs 认知维度互补 — A (main agent 整合) 靠 frame-thinking 决策框架, B (subagent 派单) 靠 dispatching-parallel-agents skill
- **跟 superpowers-en**: R108 R115 R120 R128e 跨 4 轮综合审视 0 派 subagent 撞 token 修真方案稳定 (A 方案 main agent 整合), R128e 5 worker × 2 lens 是首次 B 方案实战

## R128a~R128d 改动验证

| 指标 | 期望 | 实际 | 状态 |
|---|---|---|---|
| 派单 1 commit 修真 | 4 round × 1 commit | R128a/b/c/d 1+1+1+1 = 4 commit 修真 ✓ | ✅ |
| dispatching-parallel-agents 1 worker 1 round | 4 round 4 worker | 4 round 4 worker (顺序 dispatch 同 cwd) | ✅ (修真 D-6) |
| 修真基线 0 raw | 0 error / 26 warn / 433 info | 0 error / 26 warn / 433 info (R128d 修真后) | ✅ |
| 2728 tests 0 行为变化 | 0 | 0 (跨 4 round) | ✅ |
| 守门员 0 新增 violation | 0 | 0 (R128c 加 3 规则 0 新增命中) | ✅ |
| R128d step 2 跨期 1 周综合审视 | 1 份主报告 | 0 份 (⏸ 跨期 1 周 0 跑) | ❌ (Z-19) |
| brief 模板 持久化 | docs/reviews/briefs/ | 0 (brief inline 主对话) | ❌ (D-7 P1) |
| SOP fallback 文档 | docs/SUBAGENT_FALLBACK.md | 0 (跨期 8 round 0 落地) | ❌ (D-5 P0) |
| token quota 监控 cron | cron self 1h | 0 (跨期 8 round 0 落地) | ❌ (D-8 P1) |
| R128e 5 worker git worktree 隔离 | 5 worktree | 0 (同 cwd 顺序 dispatch) | ❌ (D-6 P0) |

## R129+ 建议 (具体到文件:行)

| # | 文件:行 | 修真 | 估时 | 估评分影响 |
|---|---|---|---|---|
| **P0-1** | `docs/SUBAGENT_FALLBACK.md` (新文件) | 写 SOP: (1) token 监控 cron self (2) brief 模板 docs/reviews/briefs/ (3) main agent 整合 fallback (4) git worktree 隔离步骤 (5) R108 撞 token 案例分析 | 1h | +0.20 |
| **P0-2** | R128e+ 派单流程 | 5 worker × 2 lens 改成 5 worker 5 git worktree 隔离并行 (修真 D-6 顺序 dispatch → 并行 dispatch) | 2h | +0.15 |
| **P1-1** | `docs/reviews/briefs/{3-lens,6-lens,10-lens}.md` (新模板) | 写 3 套 brief 模板 (R120 4 视角 / R108 revisit 9 视角 / R128e 10 视角), 跨 session 持久化 | 1h | +0.10 |
| **P1-2** | `mavis cron self` 模板 | 写 token quota 监控 cron self-reminder 模板 (每 1h 检查 quota 80% 阈值告警) | 0.5h | +0.10 |
| **P2-1** | `docs/sprint/{date}-progress.md` (新模板) | 写 sprint 进度单文件汇总模板 (修真基线 + 派单 worker + 跨期 P0 残留 3 段) | 0.5h | +0.05 |
| **P2-2** | `docs/audit/2026-08-25-r128d-step2/` (R128d step 2 占位) | 跨期 1 周综合审视 4-7 视角派单 (派 4-7 worker, 1 worker 1 视角, A 方案 main agent 整合主报告) | 0.5h 占位 | +0.05 |
| **P3-1** | R128e 修真基线 18 → 24 守门员 | `AGENTS.md:3` 修真 "24 CI gatekeepers" 但 R128d 修真基线写"18 守门员 18 全绿" — 修真成 24 | 5min | +0.05 |

**合计估时**: 5.5h ~ 6h, 估评分影响 +0.70 → 8.2/10 (R130 综合审视可上 8.0/10, 取决于 git worktree 改造是否落地)
