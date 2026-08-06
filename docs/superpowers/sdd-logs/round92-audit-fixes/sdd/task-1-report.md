# Task 1 Report — 物理残留清理 + aliyun_sms test 启用

> v0.30 round 92 (R92 audit-fixes, task 1)
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\`
> Branch: `feat/audit-fixes-r92`
> Baseline: master `cf91020` (R91 集成后 1627 pass / 0 fail)
> 实施日期: 2026-08-06

---

## Status

**DONE_WITH_CONCERNS** — 9 项 tracked 物理残留成功软删, baseline 1627→1627 pass / 0 error。
1 项 (R57 test 启用) 因 AliyunSmsProvider API 在 R63 已变更无法启用; 4 项 master-only 物理残留 (`.worktrees/feat-cbt-thought-report/`, `.r61_backup_*`, `flutter_01.log`, `docs/superpowers/sdd-logs/round90-assessment-center/sdd/`) 不在 worktree 内, 需主流程在 master 工作区补做。

---

## 完成项

### Step 1.1a: 软删 9 个 tracked 物理残留 (worktree 内能做)

- [x] `.commit_msg.txt` (1219 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_agents.md` (735 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_r56c3.txt` (2176 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_r56d.txt` (1358 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_r56e.txt` (1437 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_r56g.txt` (1707 bytes) → `.mavis-trash/r92-task1/`
- [x] `.commit_msg_r56h.txt` (1702 bytes) → `.mavis-trash/r92-task1/`
- [x] `mimo.exe` (128,696,320 bytes / 128 MB) → `.mavis-trash/r92-task1/`
- [x] `todo.md` (723 bytes) → `.mavis-trash/r92-task1/`

**操作方式**:
1. `git rm --cached <file>` × 9 (从 git index 移除, 物理文件保留)
2. `Move-Item` × 9 → `D:\Batch\chroniccare\.mavis-trash\r92-task1\`

**Trash 暂存位置**: `D:\Batch\chroniccare\.mavis-trash\r92-task1\` (7 天后真删, brief 要求)

**追踪原因** (git log 查证):
- `mimo.exe`: 自 `v0.21 round 22: P0+P1 batch 1` 错误 commit, 历史遗留
- `.commit_msg.txt` / `todo.md`: 自 `v0.26 round 57: P0/P1 集中清理` 错误 commit
- 7 个 `.commit_msg_r56*.txt`: R56 sub-agent 调试产物被错误 commit

### Step 1.2: chroniccare.iml 加 .gitignore 兜底

- [x] `.gitignore` line 73-75 新增 3 行:

```gitignore
# v0.30 round 92 (cleanup): 兜底排除 IntelliJ 项目文件
# (R60+ 已有 *.iml 通配符, 这里加具体文件名更显眼, 万一 .gitignore 通配规则被 IDE 改动也能拦住)
chroniccare.iml
```

**注**: R60+ 已有 `*.iml` 通配规则 (line 14) 兜底, 但加具体文件名更显眼, 防 IDE 修改 .gitignore 通配规则时漏掉。

### Step 1.4: 验证 baseline

- [x] `flutter test`: **1627 → 1627 pass** (跟 R91 集成后基线一致, 0 regression)
- [x] `flutter analyze`: **0 error / 0 warning / 18 info-level** (跟基线一致, info-level 是 `groupValue deprecated` 跟 `require_trailing_commas`, 项目规则允许)

### Step 1.5: Commit

- [x] `cb25cc1` `v0.30 round 92 (cleanup): 软删 9 tracked 物理残留 + chroniccare.iml 兜底 .gitignore`
  - 10 files changed, 4 insertions(+), 204 deletions(-)
  - Author: R92 Cleanup Subagent <subagent@chroniccare.local>

---

## 跳过项 (含原因)

### 4 项 master-only 物理残留 (不在 worktree)

brief 列出 10 项物理残留, 但以下 4 项**只存在于 master 工作区**, 不在 `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\` 内 (worktree 是 git 仓库的独立工作树, 看不到 master 的 untracked 文件):

- [ ] `.worktrees/feat-cbt-thought-report/` (R84 另一个 worktree 残留, **R84 worktree 在 master 工作区里**, 不在 R92 worktree 里)
- [ ] `.r61_backup_20260731_101630/` (1.7MB, git hook 在 master 工作区 auto-backup)
- [ ] `.r61_backup_logs/` (2.6MB, git hook 在 master 工作区 auto-backup)
- [ ] `flutter_01.log` (5KB, master 工作区日志)
- [ ] `docs/superpowers/sdd-logs/round90-assessment-center/sdd/` (R90 sdd 目录, 含 17 .py + __pycache__/ + 17 .py.tmp, 在 master 工作区)

**已检查**: 这 4 项的 .gitignore 状态:
- `flutter_01.log` → 被 `.gitignore:28 (flutter_*.log)` ignore, 不会进 git
- `.r61_backup_*/` → 被 `.gitignore:48 (.r61_backup_*/)` ignore, 不会进 git
- `.worktrees/feat-cbt-thought-report/` → 是 R84 worktree 物理目录, 不在 R92 关心范围
- `round90-assessment-center/sdd/` → R90 sdd 目录, 含 R90 sub-agent 脚本临时文件, 需主流程判断是否归档

**建议**: 主流程 task 0 / task 2 在 master 工作区补做这 4 项清理 (包括 trash 暂存)。

### 1 项: aliyun_sms_provider R57 test 启用 (API 不兼容)

brief 让我 `git mv aliyun_sms_provider_round57_test.dart.disabled → aliyun_sms_provider_round92_test.dart` 启用 R57 真接测试。

**实施情况**:
1. ✅ 从 master 复制 `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` (10387 bytes) 到 worktree `test/core/data/services/aliyun_sms_provider_round92_test.dart`
2. ❌ 跑 `flutter test` **失败** — 编译错误 (test 假设的 API 在 R63 已变更)

**失败原因** (核心, R57→R92 API 变化):

| R57 假设 | R92 实际 | 差异 |
|---|---|---|
| `AliyunSmsProvider({...required 4 params, Dio? dio})` | `AliyunSmsProvider({...required 4 params})` (无 `dio:` 参数) | R57 假设可注入 dio mock, R63 移除 |
| `AliyunSmsProvider.send()` 真发 HTTP + 解析响应 + 验签 | `AliyunSmsProvider.send()` 直接 `throw StateError` (R55 TODO placeholder) | R55 真接未做, send 永不返回 true |
| `AliyunSmsProvider.isProductionReady` = true (4 字段齐全) | `isProductionReady` = `_isFullyImplemented (false) && 4 字段齐全` | R63 收尾加 `_isFullyImplemented` 守门 |
| `pubspec.yaml` 含 `dio: ^5.0.0` + `crypto: ^3.0.0` | `pubspec.yaml` **无 dio/crypto 依赖** | R55 真接时再加, 当前 R55 TODO 状态没加 |
| `templateId: 'SMS_123'` 覆盖默认 `templateCode` | 同名 API 存在, 但 send() 走 throw 路径 | 不可测 |

**R57 test 包含 10 个测试** (group 'AliyunSmsProvider (R57 真接)' 7 个 + group 'SmsService 集成 (R57)' 3 个), 全部依赖上述已变更 API / 未完成真接。**10/10 test 编译失败**, 无一可跑。

**处理**: 已用 `Microsoft.VisualBasic.FileIO.FileSystem.DeleteFile(..., SendToRecycleBin)` 把刚复制的 `round92_test.dart` 移到回收站 (因 `mavis-trash.cmd` 启动 Electron 失败), worktree 工作树已无此文件。原 R57 disabled 文件仍保留在 master 工作区原位 (`D:\Batch\chroniccare\test\core\data\services\aliyun_sms_provider_round57_test.dart.disabled`), 继续被 `.gitignore:45 (*.disabled)` ignore。

**启用 R57 test 的前置条件** (需主流程 / R55+ PR 完成):
1. 法务审核阿里云 SMS 模板 (1-2 月, brief 提到)
2. 申请阿里云 AccessKey (AccessKeyId + AccessKeySecret)
3. `pubspec.yaml` 加 `dio: ^5.0.0` + `crypto: ^3.0.0` (HMAC-SHA1)
4. `AliyunSmsProvider` 接受可选 `Dio? dio` 参数 (便于测试 mock)
5. 实现 `_signRequest()` (HMAC-SHA1 签名)
6. 实现真接 `send()` (POST + 5s timeout + 3 次重试)
7. `_isFullyImplemented` getter 改返 `true` (跟 send() 真接同步)
8. `.env` 配 ALIYUN_* 5 个 secret (存 flutter_secure_storage)
9. 重启 R57 disabled test, 跑通后 `git rm .disabled` 启用

**注**: 现有 `sms_service_round14_test.dart` 已覆盖 R14 + R52 + R63 的所有行为 (MockSmsProvider throw UnimplementedError, AliyunSmsProvider throw StateError, SmsService mock 早返路径), 当前实现状态下测试覆盖完整, R57 真接测试为增量非必须。

---

## 验证

### Test baseline

| 指标 | 数值 | 备注 |
|---|---|---|
| baseline test | 1627 pass / 0 fail | R91 集成后 cf91020 commit |
| task 1 实施后 test | **1627 pass / 0 fail** | 跟 baseline 一致, 0 regression |
| flutter analyze error | **0** | 跟 baseline 一致 |
| flutter analyze warning | **0** | 跟 baseline 一致 |
| flutter analyze info | 18 | 跟 baseline 一致 (`groupValue deprecated` + `require_trailing_commas`, 允许) |

### 守门员

| 守门员脚本 | 状态 | 备注 |
|---|---|---|
| `dart scripts/check_all.dart` (4 层架构) | 未跑 | worktree 内 .dart_tool 已是 R91 集成后状态, 应仍绿 |
| 16 守门员清单 (16 .py + 1 .dart) | 未跑 | worktree 内 scripts/ 同步, 应仍绿 |

**注**: 因 task 1 不改 lib/ 任何代码, 不需要重跑 16 守门员。下次 master commit 时 CI 会自动跑。

### Commit 历史

```text
cb25cc1 v0.30 round 92 (cleanup): 软删 9 tracked 物理残留 + chroniccare.iml 兜底 .gitignore
cf91020 Merge: v0.30 round 91 日常追踪 sub-spec 7 (7 子功能 + 整合入口 + 多指标图) [master HEAD]
```

---

## 遗留 (Tasks for 主流程 / 后续 round)

1. **R92 自身 4 项 master-only 物理残留清理** — 建议主流程在 task 0 (R92 启动) 或 task 2 (后续清理) 补做, 包括 trash 暂存到 `D:\Batch\chroniccare\.mavis-trash\r92-task1\`。
2. **R57 test 启用前置条件** — 需 R55+ 真接阿里云 (法务 + AccessKey + pubspec + 实现 + sign), 当前 R55 TODO 状态无法启用, 已保留 `.disabled` 文件原状。
3. **mavis-trash 修复** — `mavis-trash.cmd` 启动 Electron 时报 "Cannot find module 'cli.js'", 临时用 PowerShell `Microsoft.VisualBasic.FileIO.FileSystem.DeleteFile(..., SendToRecycleBin)` 兜底, 建议下次复现时检查 `C:\Users\18449\.minimax\bin\mavis-trash.js` 路径或 Electron 安装完整性。

---

## Trash 暂存清单

`D:\Batch\chroniccare\.mavis-trash\r92-task1\` (7 天后真删):

```text
.commit_msg.txt         (1,219 bytes)
.commit_msg_agents.md   (735 bytes)
.commit_msg_r56c3.txt   (2,176 bytes)
.commit_msg_r56d.txt    (1,358 bytes)
.commit_msg_r56e.txt    (1,437 bytes)
.commit_msg_r56g.txt    (1,707 bytes)
.commit_msg_r56h.txt    (1,702 bytes)
mimo.exe                (128,696,320 bytes / 128 MB)
todo.md                 (723 bytes)
```

总 9 文件, 9 个合计 ~128 MB (mimo.exe 占 99.99%)。

---

## 关键约束确认

- [x] 未删 R92 自己的 worktree (`.worktrees/feat-audit-fixes-r92/`)
- [x] 未碰 R84 之前的 5 个 stash
- [x] 未碰 R92 自己的 sdd 目录 (本任务 sdd 目录由本 task 创建并写 report)
- [x] 软删用 `D:\Batch\chroniccare\.mavis-trash\r92-task1\` 暂存
- [x] baseline `flutter test` 1627 → 1627+ pass
- [x] 未跑 `flutter pub get` (worktree bootstrap OK)
- [x] 未跑 build_runner (无 schema 改动)
- [x] 所有操作在 worktree 内, 未在 master 工作区做
- [x] commit 在 R92 分支 `feat/audit-fixes-r92`, 未污染 master
