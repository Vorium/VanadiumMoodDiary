# R95 sub-spec 3 task 9 — stale audit 模式确认 + lock-in tests

## 状态: IN PROGRESS (跟 task 8 / 9-audit / 25 / 26 模式完全一致)

## 关键发现 (诚实, 不假装做了 refactor)

### R95 报告 §6.5 audit 是 stale (跟 task 8 / 9-audit / 25 / 26 一致)

任务 spec 估"scale_translations 3056 字符 + strings 1543 字符 → 估 +50 ARB keys", 实测:

| 范围 | R95 估 | 实测已走 ARB | 实测待走 (P0) | 状态 |
|------|--------|--------------|---------------|------|
| scale_translations PHQ-9 21 method | "16 题中文题目" | ✅ 全部 21 method 走 ARB (R65/R78) | 0 | R65/R78 完成 |
| scale_translations GAD-7 17 method | (含 16 题) | ✅ 全部 17 method 走 ARB (R78) | 0 | R78 完成 |
| scale_translations 8 新量表 6 类 × 8 = 186 method | "严重度 + 危机电话" | ✅ 全部 6 类 (name/shortDescription/instruction/option0..4/severityLabel0..4/severitySummary0..3) 走 ARB (R90) | 0 | R90 完成 |
| scale_translations 8 新量表 items 0..N (62 题) | (漏估) | ❌ 故意留 v1.0 (R90 决策) | 0 (R90 决策 v1.0) | 故意 v1.0, 非 stale |
| strings.dart 30 const 字段 | "domain 层中文常量" | ✅ 30 const 字段 + 30 *Text pair + 30 ARB key 走 ARB (R23/R39/R57) | 0 | R23/R39/R57 完成 |
| strings.dart 6 email 函数 + 8 pdf 函数 + 6 importSummary + moodLabel | (含上面) | ✅ 全有 override 参数 + 函数化 (R57) | 0 | R57 完成 |
| strings.dart caller 改用 *Text + l10n.override | (未估) | ⚠️ 部分 caller 仍用 const 编译期常量 | P1 维护负担 (audit 11.3/11.5 标, 非 P0) | P1 决策 |

**实测 0 改动需要** (跟 task 8 / 9-audit / 25 / 26 stale audit 模式完全一致)。

## 真正可做的

### 1. lock-in tests 防御 (跟 task 8 一致)

把"已走 ARB"的状态锁住, 防止未来 refactor 退回:
- (a) PHQ-9 / GAD-7 全 38 method 走 ARB
- (b) 8 新量表 6 类全 186 method 走 ARB
- (c) 8 新量表 items stub 故意 v1.0 (R90 决策)
- (d) strings.dart 30 const + 30 *Text pair 完整
- (e) strings.dart 6 email + 8 pdf + 6 importSummary + moodLabel 函数化
- (f) const compatibility 保持 (R57 design 意图 — Android channel ID 必须 const compile-time)
- (g) domain 0 flutter 边界保持 (check_all.dart 守门员)
- (h) 3 语 ARB 同步 1045 keys (check_arb_keys.py 守门员)

### 2. 诚实报告

不假装做了 refactor, 跟 task 8 / 9-audit / 25 / 26 一样:
- 0 改动需要 (跟 stale audit 模式一致)
- 数字低估 2-4 倍 (R92 baseline 漏 R88-91 增量)
- 真正 P0 = 0 待修 (R65/R78/R90/R23/R39/R57 已修完)
- 真正 P1 = caller 改 *Text (audit 标, 但 P1 维护负担非 P0)

## 时间预算
- 估 1-2 commit (不是 task spec 的 3-4 commit, 因 0 code 改动)
- 30-45 分钟 (写 lock-in tests + 跑守门员 + 报告)
