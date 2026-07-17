# 中文 Commit 消息指南 (v0.17 round 14 / P3-1)

> 项目 commit message **subject 用中文, body 可中英混合**。参考 `git log --oneline` 看范例。

## 格式

```
<version> round <N>: <中文标题 (≤ 60 字)>

<body — 解释 what + why, 多段用空行, 关键决策用 bullet>
```

## Subject 规则

- ✅ 开头: `<version> round <N>:`  (例: `v0.17 round 14: P1-3 split core_providers into 3 files`)
- ✅ 标题: 中文, 动词开头 (split / add / fix / migrate / extract)
- ❌ 不用英文 (项目 commit 历史全部中文)
- ❌ 不用 emoji (除 `🔒` 等真正能传达的)
- ❌ 不写具体行号 (cherry-pick 时会过时)

## Body 规则

- 第一段: **What** — 改了什么 (1-2 句)
- 第二段: **Why** — 为什么改 (设计决策, 业务原因)
- 后续: **Impact** — 文件数 / LOC / 风险 (e.g. "Verification: 0 issues, 543/543 pass")
- 用 bullet (`-`) 列举多文件改动

## 范例

```
v0.17 round 14: P1-3 split core_providers into 3 files

- core_providers.dart (10 providers, 1.5KB): db + crypto/notification/sms + 7 repos
- service_providers.dart (5 providers, 1.6KB): reminderService/Checker,
  safetyWatch, assessmentReminder, dataExport
- vent_providers.dart (4 providers, 1.2KB): ventAudioStorage, ventRepository,
  ventEntries (StreamProvider.autoDispose), ventEntryById (FutureProvider.autoDispose)

vent_providers contains ventRepository to break a core_providers <-> vent_providers
circular import. autoDispose is preserved for vent stream providers (round 8 C5
decision: privacy boundary + release DB watch on page leave).

Verification:
- flutter analyze: 0 issues
- flutter test: 528/528 pass
- check_cross_feature.py --ci: 0 violations
```

## 多文件 commit 模板

```
<title>

Before: <1-2 句之前的痛点>
After: <1-2 句修法>

- file1: 改动 1
- file2: 改动 2

<可选: 决策注释 / 引用 round X>
<可选: 跟之前 round 的关系>

Verification:
- flutter analyze: 0 issues
- flutter test: N/M pass (±delta)
- check_cross_feature.py --ci: 0 violations
```

## 拆分 commit vs squash

| 情况 | 建议 |
|---|---|
| 1 个 round 改 1 个主题 | 单 commit (例: round 14 拆 core_providers) |
| 1 个 round 改 2 个独立主题 | 拆 2 commit (例: round 11 drift 拆 + cross-feature lint) |
| 重构 + bug fix 混合 | 拆 — 重构 1 commit, fix 另 1 commit (cherry-pick 友好) |
| "WIP" 或半成品 | 拆 — 写完整 1 commit 再 push, 不要 amend 跨 round |

## 不该做的

- ❌ "fix bug" / "update" / "WIP" (太抽象)
- ❌ 把 5 个 round squash 成 1 commit (失去 history 价值)
- ❌ subject 写 "v0.17 round 14: update various things" (vague)
- ❌ body 留空 (commit 没解释 why, 后续 reviewer / 自己 3 个月后看不懂)

## 参考

- `git log --oneline` 看最近 30 个 commit 的实际风格
- `AGENTS.md` "提交风格" 段
- `docs/WHITEPAPER.md` § 18 决策记录 (commit hash 索引)
