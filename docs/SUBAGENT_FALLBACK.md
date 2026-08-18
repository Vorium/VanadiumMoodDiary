# Subagent 派单 Fallback SOP (R129 修真)

> **目的**: 把 R108 综合审视 6 subagent 撞 `50111: Token Plan 用量上限` 教训固化为 SOP, 后续 5 worker × 2-3 lens 派单模板 + token 监控兜底。
>
> **适用范围**: 任何 ≥ 2 subagent 并行的综合审视 / 多视角派单 (R108 6 lens / R120 4 lens / R128e 11 lens 实战验证)。
>
> **维护人**: root session (Mavis orchestrator), 修真触发: 任何 token 撞 quota / subagent 失败 / brief 不清晰。

## 1. Token Quota 监控 (R108 教训: 6 subagent 撞 50111)

### 现象

```
Error 50111: Token Plan 用量上限
```

### 触发条件

- 6+ subagent 并行 (R108 6 subagent 撞)
- 11+ lens 单 subagent 跑 (R128e 5 worker × 2-3 lens 拆避免)
- 单 subagent prompt > 16K token (brief 模板 + 子任务 context)

### 预防 (修真 P1-13 cron self token 监控)

```bash
# 派单前 5 min 跑 quota check
mavis quota check --agent mavis

# 派单后立刻设兜底 cron (1h 兜底)
mavis cron self --cron-name "<name>-fallback" --every "1h" \
  --prompt "检查 subagent 状态: <task_ids>。如完成 → 整合; 如仍 running → 等下次 tick; 如 token 撞 quota → 改 N worker 串行重派"
```

### 应对 (撞 quota 时)

1. **立刻 abort 仍在跑的 subagent** (避免 token 持续扣)
2. **合并 6 → 3 subagent** (每个跑 2 lens)
3. **重派时用更短 brief** (去掉 3 round 流水, 只给 1 个 round)
4. **设 30 min 兜底 cron**, 兜底 cron 检测仍 0 完成 → 进一步合并 3 → 2 → 1 subagent

## 2. 5 Worker × 2-3 Lens 派单模板 (R128e 实战验证)

### 数量公式

```
subagent_count = ceil(lens_count / 2.5)
```

例: 11 lens → ceil(11/2.5) = 5 worker (2-3 lens each)

### 派单结构 (Mavis orchestrator)

```python
# brief 模板 (每个 worker 独立 brief, 避免 context 共享污染)
worker_brief = {
    "lens_ids": [1, 2],  # e.g. emil + superpowers-en
    "scope": "read-only on lib/ packages/ android/ ios/ docs/ scripts/ test/",
    "deliverable": f"docs/audit/<date>-<name>/<NN>-<lens_name>.md",
    "output_format": "≤ 8KB per lens, score (1-10) + ≥5 findings + ≥1 P0/P1 + cross-lens consensus",
    "context": "共享 R128e 报告路径 + 11 lens 总览表 + R128d 修真 baseline",
    "deadline": "30 min",
}
```

### 派单命令

```bash
# 5 worker 并行, run_in_background=true
mavis task --description "<name>-worker-1" \
  --prompt "<worker_brief_1>" --agent_name worker --run_in_background true
mavis task --description "<name>-worker-2" \
  --prompt "<worker_brief_2>" --agent_name worker --run_in_background true
# ... 5 worker
```

### 验证

- 5 worker 都进入 `running` 状态 → 不轮询, 等兜底 cron
- 5 worker 都 `succeeded` → 主 agent 整合
- 1+ worker `failed` 或 `lost` → fallback 见 §3

## 3. Subagent 失败 / 撞 Quota Fallback (5 段)

### Stage 1: 派单前预防 (5 min)

- [ ] `mavis quota check --agent mavis` 看 token 余量
- [ ] 设兜底 cron (30-60 min 间隔, 修真 P1-13 模板)
- [ ] brief 控制在 < 4K token (每 worker)

### Stage 2: 派单时隔离 (修真 P0-9 待 R129 git worktree)

- [ ] 5 worker 顺序 dispatch (避免 6 并行撞 R108 quota)
- [ ] 5 worker 改 5 git worktree 隔离 (修真 P0-9, 当前缺位)
- [ ] 每个 worker brief 独立 context (不共享大段 R120 报告)

### Stage 3: 撞 quota 应对 (R108 教训)

- [ ] 立即 `mavis task stop <task_id>` abort 仍跑 worker
- [ ] 合并 5 → 3 worker (每 worker 跑 3-4 lens)
- [ ] 修真 brief 到 < 2K token (去掉重复 context)
- [ ] 重派, 仍撞 → 3 → 2 → 1 worker 串行

### Stage 4: Subagent 失败 / lost 应对

- [ ] `mavis task query --task_id <id>` 看 status
- [ ] `failed` → 看 error, 修真 brief 重派
- [ ] `lost` → 30 min 后仍 lost → 视为失败, 重派
- [ ] 重派 > 3 次仍失败 → 主 agent 亲自跑该 lens (8KB 上限)

### Stage 5: 整合与兜底

- [ ] 5 worker 报告都到 → 主 agent 整合到 `00-FINAL-CONSOLIDATION.md`
- [ ] 兜底 cron 1h tick 触发 → 检测 0 完成 → 强 abort + 合并重派
- [ ] 兜底 cron 检测完成 → 整合 + 删除 cron (避免 cron 持续触发)

## 4. Brief 模板 (3 套, 修真 P1-12)

- **`docs/reviews/briefs/3-lens.md`** — 3 lens 短 brief (< 2K token)
- **`docs/reviews/briefs/6-lens.md`** — 6 lens 中 brief (< 4K token)
- **`docs/reviews/briefs/10-lens.md`** — 10+ lens 长 brief (< 6K token)

修真触发: 任何 brief > 8K token 或缺 context 共享 / output format 不清。

## 5. 验收 Checklist (修真 P0-8 配套)

- [ ] 派单前 token 余量检查通过
- [ ] 兜底 cron 已设 (修真 P1-13 模板)
- [ ] 5 worker brief 各自 < 4K token
- [ ] 5 worker 都 `succeeded` 或触发 fallback §3
- [ ] 11 lens 报告 ≤ 8KB each, 整合报告 ≤ 30KB
- [ ] 修真项 (P0/P1/P2) 在 `00-FINAL-CONSOLIDATION.md` 完整列出
- [ ] `docs/DEVELOPMENT_REQUIREMENTS.md` 已修真 (v2.0 → v3.0)
- [ ] `AGENTS.md` EN Summary + v0.32 R128e 章节已修真
- [ ] `docs/CHANGELOG.md` 修真 5 R128 entry (R127 + R128a/b/c/d)

## 6. 修真记录

- **R129 P0-8 (2026-08-18)**: 本 SOP 落地, R108 6 subagent 撞 `50111` 教训跨 8 round 0 闭环
- **R129 P0-9 (待)**: 5 worker 改 5 git worktree 隔离修真 (本批缺位)
- **R129 P1-12 (待)**: `docs/reviews/briefs/{3,6,10}-lens.md` 3 套 brief 模板
- **R129 P1-13 (待)**: `mavis cron self` token quota 监控模板
