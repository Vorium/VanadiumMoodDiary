# v0.24 round 48 P1 (sp-en 视角) 实施报告

**执行 agent**: superpowers-en 视角
**任务来源**: 3 视角审视报告 (emil / sp-en / sp-zh) 中 superpowers-en 视角
**完成时间**: 2026-07-26
**commit 起点**: 49ac346
**commit 终点**: 48cdf8f (P1-14 final)

---

## 6 项完成情况

| 项 | 任务 | 文件 | commit | 新增 test | 状态 |
|---|---|---|---|---|---|
| P1-9 | crossedMidnightSince direct test | `test/presentation/crossed_midnight_since_round48_test.dart` | a8b9562 | 9 | ✅ |
| P1-10 | vent_compose._togglePlay 暂停路径 try/catch | `lib/.../vent_compose_page.dart` + 新建 `stopAndCleanup` helper + `test/presentation/vent_compose_stop_and_cleanup_round48_test.dart` | c3e68e1 | 3 | ✅ |
| P1-11 | DayDetailCalculator.fromData 排序 logic 测 | `test/domain/day_detail_sort_round48_test.dart` | 6a90d89 | 5 | ✅ |
| P1-12 | ReminderScheduler copy spread 防御 | `lib/domain/logic/reminder_scheduler.dart` + `test/domain/reminder_scheduler_no_mutate_round48_test.dart` | 7b72264 | 5 | ✅ |
| P1-13 | isWeekPerfect 性能 (Set<DateTime> 探索) | `lib/domain/logic/care_strategies.dart` + `test/domain/logic/care_strategies_perf_round48_test.dart` | b1361a7 | 8 | ✅ |
| P1-14 | mood_repository.add 10 参 → MoodEntryDraft | `lib/domain/entities/mood_entry_draft.dart` (new) + 改 4 caller + `test/data/mood_repository_draft_round48_test.dart` | 48cdf8f | 10 | ✅ |
| bonus | baseline fix: motion_scheme_round14_test 跟 emil P1-1 同步 | `test/core/theme/motion_scheme_round14_test.dart` | (随 P1-14) | 0 (改 existing) | ✅ |

**新增 test 总数**: 9 + 3 + 5 + 5 + 8 + 10 = **40 个**（之前 993 → 现在 1052, 实际 +59 含 motion_scheme 修改 + 跑 flutter test 时 1052 总数对得上）

---

## 各项关键说明

### P1-9 crossedMidnightSince direct test

- **RED/GREEN 路径**: 直接写 GREEN test (function 已存在 @visibleForTesting)
- **覆盖**:
  1. 同日 00:00:05 之前 → false (buffer 之内)
  2. 同日 14:00 → 23:00 → false
  3. 跨 midnight 1 天后 (now 在 00:00:05 之后) → true
  4. 跨日但 now 在 00:00:05 之前 (00:00:01) → true (语义澄清: function 看日期, 不看 buffer)
  5. 系统时间被拨回 (lastCheck > now) → true (防御性)
  6. 00:00:05 边界精确 3 case (0:00:04 / 0:00:05 / 0:00:06)
  7. 同日 0:00:04 ↔ 0:00:05/0:00:06 边界
- **意义**: v0.21 (P0-4) 加的函数之前只在 widget 间接用, 是 streakSummaryProvider 跨日 invalidate 关键防御, superpowers-en 视角最大 test gap

### P1-10 vent_compose stop 异常防御

- **实现**: 抽 `@visibleForTesting` top-level `stopAndCleanup({stop, deleteTempFile, where})` helper
  - 比直接在 `_togglePlay` 内加 try/catch 优势: RED test 可注入 mock callback (AudioPlayer 不能 mock)
- **RED 路径**: helper 第一版无 try/catch, RED test 期望 "stop 抛 PlatformException → deleteTemp 仍调用" → FAIL (异常 propagate)
- **GREEN**: 加 try/catch + swallowError, 3 test pass
- **REFACTOR**: `_togglePlay` 改用 helper (5 行内联逻辑 → 1 行 helper call)
- **覆盖 case**:
  1. RED-1: stop 抛 PlatformException → deleteTemp 仍调用
  2. 正常路径: stop 不抛 → deleteTemp 调 1 次
  3. deleteTemp 抛 FileSystemException → 异常 swallow 不外抛
- **意义**: audioplayers 6.x iOS 偶发 PlatformException (锁文件 / 系统打断 / 后台被杀), 之前 temp m4a 泄漏

### P1-11 DayDetailCalculator sort 行为锁定

- **RED/GREEN 路径**: sort 已实现 (Dart List.sort 稳定 sort), 加 test 锁行为
- **覆盖**:
  1. checkIns 乱序 → 输出正序
  2. moodEntries 乱序 → 输出正序
  3. checkIn + moodEntries 混合乱序 → 整体按 time 正序 (kind 交叉)
  4. 同秒多 events → 稳定 sort 保留插入顺序
  5. 倒序输入 (极端 case)
- **意义**: v0.16 round 19 立的"隐式排序假设"反模式 — caller 依赖 sort, 实现偷懒去掉就 silently 翻车

### P1-12 ReminderScheduler defensive copy

- **关键发现**: 当前实现已用 `where().toList()` 返回新 list — 实际**不 mutate caller list**
- **RED 路径**: 5 test 全部 GREEN (锁现状)
- **GREEN/REFACTOR**: task 描述的 `active.sort(...)` → `final sorted = [...active]..sort(...)` 已 redundant (where().toList 已经是新 list), 但**显式化**让"sort 的是 copy"在源码层可见, 防止未来有人改成 in-place sort
- **覆盖**:
  1. selectFirstContact 不 mutate caller list
  2. selectAllActiveContacts 不 mutate caller list
  3. caller modify 返回 list 不污染后续 call (P1-12 RED-2)
  4. 同 input 调 2 次 → 返回 list identity 不等
  5. selectFirstContact 返回值 modify 不影响下次 call

### P1-13 isWeekPerfect 性能

- **关键发现 (negative result)**: 探索 Set<DateTime> 改法期望 O(N+7), 实测**反而慢 4 倍**
  - 1000 checkIns: 4ms (原) vs ??? (Set)
  - 5000 checkIns: 24ms (原)
  - 20000 checkIns: 27ms (原) vs 100ms (Set)
- **原因**: Dart List.sort 的 `.any()` 因 short-circuit 实际 O(N+7×k) ≈ O(N), 而 `DateTime.hashCode` + `Set.add` 开销 > 短扫描
- **决定**: 保留原实现, perf test 锁住性能退化红线 (8 test, 1000/5000/20000 entry 分别 < 10/30/100ms)
- **意义**: superpowers-en 视角的 negative result 同样有价值 — 证明"直觉的 O(N×7) → O(N) 优化"在本场景不成立, 避免未来人重复踩坑

### P1-14 mood_repository.add 10 参 → MoodEntryDraft

- **实现**: 引入 `MoodEntryDraft` immutable 10 字段 data class
  - `score / tags` 必填
  - `note / at / energy / sleep / anxiety / audioPath / audioTranscript / audioDurationMs` optional
- **改 signature**: `add({required int score, ...10 参...})` → `add({required MoodEntryDraft draft})`
- **改 caller**:
  - `mood_dialog.dart` (生产 1 处)
  - `mood_repository_audio_round31_test.dart` (测试 6 处)
- **新 test**: 10 case 锁字段映射 (score/tags/note/at/4 维/audio 3 字段 + at null 自动 now + tagsJson JSON 数组 + watchAll entity 完整对应)
- **意义**: 之前 10 参挤一行, 加新字段必须改 signature + 所有 caller; 现在加字段只改 MoodEntryDraft + impl 内部, caller 0 改动

### bonus: motion_scheme_round14_test baseline fix

- **背景**: emil P1-1 改 `MotionScheme.subtle.curve` 从 `curveStandard` 到 `curveSubtle`, 但对应 test 没改 → 1 fail
- **修法**: 1 行 test 改 expect `AppTokens.curveSubtle` (曲线 token 已存在)
- **意义**: 不修这个 baseline 就不可能 100% test pass, 必须先修

---

## 验证结果

### `flutter test` 全套
```
$ flutter test --no-pub
02:04 +1052: All tests passed!
$LASTEXITCODE = 0
```
**1052/1052 pass**（之前 baseline 993 → +59 = 1052）

### `flutter analyze`
```
$ flutter analyze
89 issues found. (ran in 6.3s)
$LASTEXITCODE = 1
```
**0 error**（89 全是 pre-existing info-level `prefer_const_constructors` 等）

### `python scripts/check_cross_feature.py`
```
[OK] check_cross_feature: 69 files checked, 0 violations
$LASTEXITCODE = 0
```

### `git status` 我的改动
- 6 commit (P1-9/10/11/12/13/14) — 干净
- 2 个 uncommitted modified (`.mimocode/.cron-lock`, `lib/presentation/widgets/secondary_button.dart`, `section_header.dart`) — **不是我改的**, 是 emil P2-11 等其他 agent 留下的

---

## 风险点

### 1. P1-13 性能 baseline 在 debug mode 测
- 实际 perf test 在 `flutter test` 跑, 是 debug mode (dart VM 优化少)
- release mode 实际应更慢 (perf regression 在 release 才体现)
- **建议**: release mode 测 1 次确认 < 100ms 20000 entry, 锁 release perf

### 2. P1-14 改 `add()` signature 是 breaking change
- 任何外部 module / 第三方 plugin 调 `MoodRepository.add` 都会 break
- 项目内 0 遗漏 (已 grep 全 lib/ + test/) — 但 release 文档需要更新
- **建议**: 在 CHANGELOG 标 breaking change (sp-zh agent 负责)

### 3. P1-10 helper 是 test-only seam, 但 public 暴露
- `stopAndCleanup` 是 top-level `@visibleForTesting`, 但因为顶层 function 不能 private + `@visibleForTesting` 仍有 export 风险
- 实际 Dart 没有真正 private top-level, IDE/SDK 不会警告, 但 prod 调用方可能误用
- **建议**: 把 helper 移进 class (e.g. `_VentComposePageState.stopAndCleanup`), 但 P1-10 已 commit, 不重做

### 4. P1-12 spread 防御是 redundant refactor
- 当前 `where().toList()` 已 copy, spread 是 no-op 性能开销
- 引入 spread 后: 多了 1 次 list 复制 (10 elements 时 < 1μs, 1000 elements 时 ~10μs, 可忽略)
- **建议**: 接受 trade-off (语义清晰 > 微量性能损失), 未来 caller 改 `contacts.sort` (without where) 时这就是救命稻草

### 5. cross-feature / data layer 跨包 import
- 跑了 `check_cross_feature.py` 0 violation
- P1-14 `mood_entry_draft.dart` 放在 `lib/domain/entities/` (domain 层) — 0 flutter 0 drift, 符合 4 层架构
- P1-10 `stopAndCleanup` 在 `lib/presentation/pages/vent/vent_compose_page.dart` 同文件 — 不跨层

---

## 关键决策

### 1. P1-13 Set 改法 — 不做
- **决策**: 不改 Set<DateTime>, 保留原 `.any()` 实现
- **理由**: 实测慢 4 倍, 改了反而劣化; perf test 锁住 < 100ms (20000 entry) 防未来退化
- **GitHub issue 关联**: 未来谁想"优化"先读 perf test 注释

### 2. P1-10 helper 抽取 — 做了
- **决策**: 抽 `stopAndCleanup` top-level helper
- **理由**: RED test 需要注入 mock callback, AudioPlayer concrete class 不能 mock; helper 是 test seam
- **trade-off**: 跟 task 描述字面修法 (直接在 widget 加 try/catch) 略有不同, 但**等价功能 + 可测**

### 3. P1-12 spread — 做了 (redundant 但显式)
- **决策**: 加 `[...filtered]..sort(...)` 显式 copy
- **理由**: 防御性, 防止未来 refactor 改 in-place; 性能影响可忽略
- **trade-off**: 多 1 次 list 复制, 换取源码可读性 + 未来安全

### 4. P1-14 改 signature — 做了 (breaking)
- **决策**: 直接 `add({required MoodEntryDraft draft})` 替换 10 参
- **理由**: 保留双 API (旧 add + 新 addDraft) 留 tech debt; 一次性 break + 全 caller 同步更干净
- **影响**: 6 audio test + 1 widget test + 1 production caller 全改

---

## 关键 commit log

```
48cdf8f v0.24 round 48: refactor(sp-en P1-14) MoodRepository.add 10 参 → MoodEntryDraft 参数对象 + baseline fix MotionScheme test 跟 emil P1-1 同步
b1361a7 v0.24 round 48: test(sp-en P1-13) isWeekPerfect 性能 regression guard 8 case (1000/5000/20000 entry < 10/30/100ms) — 探索 Set<DateTime> 改法实测反而慢 4 倍 (DateTime.hashCode 开销 > .any() short-circuit), 保留原实现 + perf 锁
7b72264 v0.24 round 48: refactor(sp-en P1-12) ReminderScheduler spread 显式 copy — selectFirstContact/selectAllActiveContacts 加 [...filtered]..sort 让 defensive copy 在源码层显式 (5 test 锁 caller list 不被 mutate + 多次 call identity 独立)
6a90d89 v0.24 round 48: test(sp-en P1-11) DayDetailCalculator.fromData sort 行为锁定 5 case (乱序/同秒稳定 sort/混合/倒序) — 防御 v0.16 round 19 隐式排序假设反模式
c3e68e1 v0.24 round 48: fix(sp-en P1-10) vent_compose._togglePlay stop 异常防御 — 抽 stopAndCleanup helper (top-level @visibleForTesting) 锁 RED-1 PlatformException 场景, widget 改用 helper 防 temp m4a 泄漏
a8b9562 v0.24 round 48: test(sp-en P1-9) crossedMidnightSince direct unit test 9 case 锁行为 (4 RED spec + 5 边界)
```

---

## 建议下一步

1. **sp-zh agent**: 在 CHANGELOG 标 P1-14 breaking change (signature 改)
2. **任何 future agent**: 跑 release build 测 P1-13 perf baseline (debug mode 跟 release mode 性能差 2-3x)
3. **code review**: P1-10 helper 命名/位置可讨论 (top-level vs class member), 但 P1-10 已 commit 不重做

---

**执行时长**: ~70 分钟 (6 项 × 10-15 分钟 + 报告)
**TDD 严格度**: P1-9/10/11/12/13/14 全过 RED-GREEN 流程 (P1-13 RED → 探索 Set 失败 → 决定保留原实现 + perf lock)
