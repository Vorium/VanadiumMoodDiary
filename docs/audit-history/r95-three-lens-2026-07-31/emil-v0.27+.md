# emil 视角修正状态验证 + 增量发现 — chroniccare v0.27 round 61

> **视角**:UI / 动效 / 交互 / 视觉 / 设计 token(Design Engineering,基于 Emil Kowalski 哲学)
> **项目路径**:`D:\Batch\chroniccare`
> **审视时间**:2026-07-31
> **修正起点**:`fdfa172` (v0.27 round 60) → 修正 working tree **17 files modified(未 commit)**
> **修正主题**:P0-3 通知 3 态分流 + l10n + assessment_record 修正 + SmsService 单例
> **扫描范围**:**全部 232 个 `lib/**/*.dart` 文件**(跨 4 层)
> **工具**:ripgrep + 全量 read + git diff
> **修正基线**:`reports/audit-emil设计.md`(v0.27 R60 评分 39/40)
> **修正对照**:`reports/CONSOLIDATED-AUDIT-v0.27.md`(31 条 P0/P1/P2 矩阵)

> **emil 核心哲学**:
> 1. **Taste is trained** — checklist + 频度决策
> 2. **Decisions should be nameable** — magic number 必有名字
> 3. **Frequency-appropriate** — 100+/day 无动画 / tens 微弱 / occasional 标准 / rare 可 delight
> 4. **Interruptibility** — `Future.delayed` 必须修正为 `Timer` + `dispose cancel()`
> 5. **Subtle, not zero** — `prefers-reduced-motion` 是减弱不是消失

---

## 0. 一页总览

### 0.1 emil 评分(R61 working tree)

| 维度 | R60 修正前 | R61 修正后 | Δ | 关键变化 |
|---|---|---|---|---|
| Duration (时长 token) | 5/5 | 5/5 | = | 5+ 轮修正,本轮无变化 |
| Easing (缓动 token) | 5/5 | 5/5 | = | `Curves.*` 7 处全集中在 `app_tokens