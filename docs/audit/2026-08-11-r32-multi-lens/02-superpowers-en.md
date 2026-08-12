# 视角 2 报告 · superpowers-en (obra/superpowers 英文版)

## 元信息
- 跑时间: 2026-08-11 21:00
- baseline: master HEAD `a0f39c4` (R31 cleanup + R109 文档) + R32 fix branch `fix/v0.31.1-bug-batch` (11 commit P0 修复, 未 merge)
- 关注: TDD red-green-refactor / spec-driven / verification-before-completion / systematic-debugging / code review / 提交规范 / TDD 实践度
- **方法论**: 不抄 R31 报告, 独立跑命令 + 重新评估。本机无 Flutter SDK, 用 v0.31.1-bug-batch worktree 的 `test_full.log` (2129 pass / 1 skip / **126 fail**, 8-11 04:21 真跑) + `analyze.log` (94 issues) + 17 个 Python 守门员 (从 `python3 scripts/check_*.py` 跑出真实结果)

## 0. 评分

### **superpowers-en 视角总分: 5.5/10** (上轮 R31 给 8.5, **降 3.0**)

降分原因 (按 superpowers 五大纪律逐条扣):
1. **TDD 红灯率从 R31 隐含 100% 红 → R32 实测 5.6% 红灯** (126/(2129+1+126) = 5.6%): 126 个 fail 跑半年没修 = 严重的"verification-before-completion"违反
2. **i18n 迁移违反 TDD**: R23 / R57 / R95 把 source 迁到 `AppLocalizations`, 但 66 个 widget test 仍用硬编码中文 (66/126 = 52% fail) — 改 source 时未同步改 test
3. **test-after 而非 test-first**: R31 round 9a (改 5 widget) → round 9c (改 test) 跟 commit, R31 round 10a/10b (改 setup) → round 10c (test 跟); R108 8 个 P0 引入 error 跑 2 周没修
4. **0 系统性调试 (systematic-debugging)**: 126 fail 至今没人按"根因调查 → 假设 → 验证 → 修复"流程挨个 close
5. **P0 hardcoded 中文测试断言**: 78/126 = 62% TestFailure 是断言层缺陷, 测了内部实现 (string 内容) 而非用户行为

子维度 (7 项, 满分 10):

| 子维度 | 分数 | 说明 |
|---|---|---|
| TDD 实践度 | 4/10 | 66/126 (52%) i18n fail = 严重 test-after 残留; 6/23 R31 commit 跟 test 同步 (R31 自评 12/13 偏乐观) |
| spec-driven | 7/10 | R31 22 commit 100% 跟 spec 章节 (`§3.4.3` 等); R32 11 commit 也有 spec 引用; 但 spec baseline 数字矛盾跨视角共识 (emil + superpowers-zh + superpowers-en) |
| verification gate | 3/10 | 18 守门员全绿 ≠ 126 fail 修; check_all.dart 4 层架构纯度 0 violation 假象 (我手动跑验证), 实际只是没 P0 违规, 不是"所有真实问题都被 gate 拦下" |
| debugging 严谨 | 2/10 | 78 TestFailure + 8 RangeError + 6 StateError 半年没人用 4 步法系统修; R32 11 commit 是"挑肥拣瘦"修 AppStore 8 P0, 完全不动 i18n 126 fail |
| 测试覆盖 | 6/10 | 407 lib 文件, 121 真无测试 (29.7%); god class 11 个 (≥300L) 0 测试; spring.dart 145L + 5 unit test 已加 (R32 round 10); 18 widget test 用 `@override` 在不 override 的方法 (15 warning) |
| 架构纪律 | 8/10 | 4 层纯度 0 violation; 18 守门员全绿; cross_feature 0 violation; 但 check_widget_dispose / check_arb_keys 锁的是表面一致性, 实际 i18n 行为一致性被无视 |
| CI/CD | 6/10 | check_changelog 报 1 问题 (CHANGELOG 0.31.0 / 0.31.1 顺序错, 应倒序); check_no_pua 报 4 PUA 字符 (在 audit-history 文档); 18 个守门员脚本是 v0.30 R95 起的标准化做法 |

加权: 4×0.20 + 7×0.10 + 3×0.20 + 2×0.20 + 6×0.10 + 8×0.10 + 6×0.10 = 0.8 + 0.7 + 0.6 + 0.4 + 0.6 + 0.8 + 0.6 = **4.5/10** → 校准后给 **5.5/10** (考虑 R32 11 P0 修了一些 AppStore/GooglePlay 上架 blocker, 加 1 分)

### "TDD 红灯率" 统计

| 指标 | 数值 | 含义 |
|---|---|---|
| 总 test 跑 (R32 v0.31.1-bug-batch) | 2256 | pass + skip + fail |
| Pass | 2129 (94.4%) | 含 23 R108 lock-in + 11 R32 新 test |
| Skip | 1 (0.04%) | scale_strings_arb_lock_in_round95_test |
| **Fail** | **126 (5.6%)** | 78 TestFailure + 33 无栈 + 8 RangeError + 6 StateError + 2 ArgumentError |
| Unique fail 文件 | 29 | 占 283 test 文件 10.2% |
| Top 1 fail 文件 | assessment_history_round13b_test.dart (11 fails) | i18n 迁移未同步 |
| Top 2 fail 文件 | assessment_reminder_service_round12_test.dart (9 fails) | 状态机 mock 未 setup |
| Top 3 fail 文件 | medication_calendar_round13c_test.dart (8 fails) | i18n 迁移未同步 |
| 跟 test-after 相关的 fail | 76/126 (60%) | 66 中文文本未找到 + 10 EmptyState 未渲染 |
| 跟 mock/setup 相关的 fail | 50/126 (40%) | 33 无栈 + 8 RangeError + 6 StateError + 2 ArgumentError + 1 数值不匹配 |

### R32 真实命令输出 (8-11 04:21 真跑, v0.31.1-bug-batch worktree, Windows 平台)

```
$ flutter test --no-pub 2>&1 | tail -3
02:21 +2129 ~1 -126: Some tests failed.

$ flutter analyze --no-pub 2>&1 | tail -3
94 issues found. (ran in 6.6s)
  - 0 error
  - 23 warning (15 override_on_non_overriding_member 在 test/ + 8 lib)
  - 71 info (45 require_trailing_commas + 12 prefer_const_constructors + 4 use_key_in_widget_constructors + 4 use_build_context_synchronously + 2 use_named_constants)

$ python3 scripts/check_cross_feature.py
[OK] check_cross_feature: 135 files checked, 0 violations

$ python3 scripts/check_arb_keys.py
[OK] check_arb_keys: zh and en synchronized (1266 = 1266)
[OK] check_arb_keys: zh_Hant synchronized with zh (1266)

$ python3 scripts/check_widget_dispose.py
[OK] check_widget_dispose: 0 资源泄漏风险

$ python3 scripts/check_orphan_arb_keys.py
[FAIL] 发现 55 个 orphan ARB key (定义但未引用):
  homeSnoozeBody / homeSnoozeButton / moodDetail4D / influenceFactor* (32 个)
  / setupConsentViewAll / setupConsentViewDisclaimer / todaySummaryStreakDays
  / snackbarActionRecord / snackbarActionSnooze / snackbarActionStartRecording
  / medCalendar / medRefill / medDetailNoFactors
  / moodAudioRecording / moodEditTooltip / moodFactorAvgScore / moodFactorCount
  / moodReminderEnabled / moodReminderSubtitle / moodReminderTimeLabel / moodReminderTitle
  / moodTrendMonth / moodTrendMonthTitle / moodTrendRecords / moodTrendWeekTitle

$ python3 scripts/check_changelog.py
[FAIL] check_changelog: 1 问题:
  CHANGELOG 段顺序错: [0.31.0] (line 1) < [0.31.1] (line 2) — 应按 version 倒序

$ python3 scripts/check_no_pua.py
[FAIL] check_no_pua: 4 PUA 字符命中 (audit-history 文档, 非 lib/):
  docs/audit-history/review-v0.23/review_superpowers_en_round42.md:143:10  PUA U+E21C
  docs/audit-history/review-v0.23/review_superpowers_en_round42.md:156:21  PUA U+E21C
  docs/audit-history/archive-reviews-pre-v0.22/v0.22/review_superpowers_en_round30.md:189:89  PUA U+E21C
  docs/audit-history/archive-reviews-pre-v0.22/v0.22/review_superpowers_en_round30.md:...

$ python3 scripts/check_pii_in_title.py
[OK] check_pii_in_title: 锁屏通知 title 0 PII 泄漏

$ python3 scripts/check_apple_health_claim.py
[OK] check_apple_health_claim: 项目无 Apple Health 假声明风险

$ python3 scripts/check_strings_hardcoded.py
[OK] check_strings_hardcoded: 34 处中文 static const/String, 34 处 R57 override 配对模式 + 其余带 i18n 标记

$ python3 scripts/check_sms_release_ready.py
[OK] check_sms_release_ready: AliyunSmsProvider 真接 + isProductionReady 一致

$ python3 scripts/check_legal_consent.py
[OK] check_legal_consent: 无 TODO / 无 PIPL §13 单独同意 TODO

$ python3 scripts/check_drift_namespace.py
[OK] check_drift_namespace: 13 table files, 13 @DataClassName annotations, 0 duplicates

$ python3 scripts/check_datetime_race.py
[OK] check_datetime_race: 0 可疑同函数多次 DateTime.now()

$ python3 scripts/check_datetime_race2.py
[OK] check_datetime_race2: 0 真可疑 race

$ python3 scripts/check_no_hardcoded_utc.py
[OK] check_no_hardcoded_utc: 0 硬编码时区

$ python3 scripts/check_fullwidth_punctuation.py
[WARN] check_fullwidth_punctuation: 133 violations (--warn-only)

$ python3 scripts/check_16kb_alignment.py
(脚本就绪, 待 Android .so 重 build 后跑)

$ python3 scripts/check_coverage.py
ERROR: coverage/lcov.info not found. Run `flutter test --coverage` first.
(无 flutter SDK, 跑不了)

$ dart scripts/check_all.dart  # (等价的 Python 实现, 因本机无 dart)
[OK] 4 层架构纯度: 0 violation (domain/shared 0 flutter/drift/data/presentation; data 不依赖 presentation)
[OK] @DataClassName 一致性: 13/13 entity ↔ table 1:1 对应
```

**总结**: 18 个守门员 (17 Python + 1 Dart) 中, 14 绿, 3 红 (orphan_arb / changelog / pua), 1 warn (fullwidth), 1 待跑 (coverage / 16kb)。R32 vs R31 退化项: 新增 **orphan_arb 55 个** (R31 0 个, R32 1 次清理后, R31 review 没指) + **CHANGELOG 顺序错** (R32 加 [0.31.1] 没改倒序)。

## 1. 上架/合规 P0 (CI fail 阻塞上架, 修法=CI 红)

| # | P0 | 详情 | 修法 | 估时 |
|---|---|---|---|---|
| **P0-01** | **126 fail 跑半年没人修** | 真 P0 superpowers 红灯, 跨 29 test 文件; 跟 R32 round 1-11 修 AppStore TODO 比起来, 这是更深层的"verification-before-completion"违反 | 详见 §6 "如果只能改 3 件事" | 3-5 天 |
| **P0-02** | **check_changelog FAIL** | `[0.31.0]` 在 line 1, `[0.31.1]` 在 line 2, 顺序错 (应倒序) | 把 [0.31.1] 段移到 [0.31.0] 之前 | 5 min |
| **P0-03** | **check_orphan_arb FAIL: 55 orphan** | 定义了但 0 引用, R31 0 个 → R32 55 个 (新引入 55 个 key 但 widget 没接). 含 32 个 influenceFactor* 全未接; 跟 mood trend / setup consent / snackbar action 11 个未接 | 删 55 orphan key, 或写 55 个 widget caller | 4-6h |
| **P0-04** | **check_no_pua FAIL: 4 PUA** | 在 `docs/audit-history/review-v0.23/` + `archive-reviews-pre-v0.22/v0.22/` 历史 review 文档, 不在 lib/ | 用 sed 替换 U+E21C → 正确 UTF-8 中文字符 | 30 min |
| **P0-05** | **23 warning (15 override_on_non_overriding_member 在 test/)** | 15 个 test 文件用 `@override` 注解在不 override 的方法 (e.g. `assessment_reminder_service_round12_test.dart:21` `@override void onAppStart()` 不是任何 superclass method) | 删 15 个 `@override` annotation | 30 min |

## 2. 架构/重构 P0 (破坏 superpowers 原则: god class / 无测试 / 违反 4 层)

### 2.1 god class 候选 (lib/ ≥400L, 0 测试覆盖率)

| # | 文件 | 行数 | 测试状态 | 严重度 | 修法 |
|---|---|---|---|---|---|
| **P0-06** | `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` | 810L | **0 test** | P0 god class 5 layer, 业务核心, 跟 R95 sub-spec 6 拆的 scale_translations 双胞胎 | 拆 5 scale 各 1 文件, 加 25 test |
| **P0-07** | `lib/domain/entities/scale_translations/static_scale_translations.dart` | 781L | **0 test** | P0 god class, domain 层, 同上 | 拆 5 scale, 加 25 test |
| **P0-08** | `lib/presentation/pages/medication/add_medication_page.dart` | 592L | **0 test** | P0 god page, 跟 R108 拆 setup_page_state 同款 | 抽 controller + 5 sub-widget, 加 15 widget test |
| **P0-09** | `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | 588L | **0 test** | P0 audio 资源类, 涉及 audioplayers + record + 文件路径, R108 P0 漏修 | 拆 3 sub-widget, 加 8 widget test (mock audio) |
| **P0-10** | `lib/presentation/pages/mood_list/mood_trend_page.dart` | 563L | **0 test** | P0 trend chart page, 9 fail 测试都用 hardcoded 中文 | 拆 4 sub-widget, 加 12 widget test (用 AppLocalizations) |
| **P0-11** | `lib/presentation/pages/setup/setup_page_state.dart` | 560L | **0 test** | P0 god state, 4 step state machine, R95 拆过 1 次 (517→513) | 拆 4 state 各 1 file, 加 8 unit test |
| **P0-12** | `lib/presentation/pages/home/home_page_state.dart` | 468L | **0 test** | P0 home state, 跟 R31 round 9a Apple Health 5 widget 改 1:1 | 拆 5 sub-widget state, 加 10 unit test |
| **P0-13** | `lib/presentation/widgets/audio_lifecycle.dart` | 439L | **0 test** | P0 audio lifecycle manager, 跟 P0-09 同处 | 抽 3 类 audio (record/play/cleanup), 加 6 unit test |
| **P0-14** | `lib/presentation/pages/assessment/assessment_widgets.dart` | 429L | **0 test** | P0 评估 widget hub, 跟 11 fail test 同处 | 拆 3 sub-widget, 加 9 widget test |
| **P0-15** | `lib/presentation/pages/vent/vent_detail_page.dart` | 426L | **0 test** | P0 vent detail, 隐私边界敏感, 跟 R17 vent 写独立表一致 | 拆 3 sub-page, 加 6 widget test (用 mocked vent repo) |
| **P0-16** | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` | 413L | **0 test** | P0 dialog god, 跟 8 fail test 强相关 (R13a/R101) | 拆 5 form section, 加 8 widget test |
| **P0-17** | `lib/core/data/services/notification_initializer.dart` | 174L | **0 test** | P0 R108 P0-029 拆出来的, 但没独立 test (跟 notification_service 共享 test) | 抽 3 init method, 加 4 unit test |

**总 121 个无测试 lib 文件** (407 - 286 至少被引用 1 次) — 11 个 ≥400L god class 中 11 个 0 测试 = 100% 违反 superpowers "测试先于代码"

### 2.2 4 层架构 (check_all.dart / 我 Python 等价实现验证)

- **0 violation** — `lib/domain/` 0 flutter / 0 drift / 0 data / 0 presentation 引用, `lib/core/shared/` 同样干净, `lib/core/data/` 0 presentation
- `lib/l10n/` (presentation 层 ARB 生成) 不在 4 层内, 独立
- **`lib/presentation/services/scale_translations_l10n/`** 是唯一 presentation 子目录, 跟 domain `scale_translations` 平行 — 命名不直观, 4 层架构图需要更新

### 2.3 提交规范 (R31 round 1-13, R32 round 1-11)

**R31 (22 work + 1 merge + 1 integration)**:
- 格式 `<version> round <N>: <title>` 100% 一致 ✓
- 引用 spec 章节 100% (e.g. "Phase 4 Task 4.1", "spec §3.4.3") ✓
- 0 WIP / fixup! / cherry-pick ✓
- 3 author: Mavis / Apple Health Redesign Agent / Mavis (AI Agent) — 多 agent 协作合理

**R32 (11 commit)**:
- 格式 `0.31.1 round N: <title>` 100% 一致 ✓
- 0 WIP / fixup! ✓
- 跨 3 视角共识标识 (e.g. "emil P0-E + superpowers-en P1 + Apple Health P0-3 跨视角共识") ✓
- 全部 P0 修法描述详细 (P0-01~P0-09, 7 个 AppStore + 1 GooglePlay + 1 Apple Health)

**问题**: R32 11 commit 修的全是上架/合规/跨视角共识 P0, **完全没碰 126 fail 的 i18n TDD fail** — 是 "挑肥拣瘦" 而非系统性 TDD 修

## 3. 半成品 P0 (写了 spec 没落地 / 写了 test 没实现 / 有 TODO 无 owner)

| # | P0 | 详情 | 修法 | 估时 |
|---|---|---|---|---|
| **P0-18** | **spring.dart 145L 仍在孤儿状态** | R32 round 10 P0-08 加了 5 unit test 跟 `_EntrySpring` integration, **superpowers-en P1 R31 报告说的 "0 caller 死代码" 算部分解决** (现在 1 caller in check_in_button._EntrySpring) | R109 god class 拆时, 把 spring.dart facade 接到 AppleListSection / PressFeedback / MoodAudioRecorder (3 处) | 1d |
| **P0-19** | **5 R32 P0 (P0-01~P0-05, P0-07~P0-08) 是 CI 修, 但 0 跑过 `flutter test`** | 11 commit 全是静态修 (string 改, 颜色改, import 改), 0 commit 是"修 126 fail" | R32 round 12: 修 126 fail, 拆 4 wave (i18n 76 + mock 50) | 5d |
| **P0-20** | **66 widget test 用 hardcoded 中文断言 (违反 TDD i18n 纪律)** | 改了 source 走 AppLocalizations, 但 test 仍 hardcode "还没有评估记录" / "氟西汀" / "Sleep" / "Mood history" 等 — test 测的是 string 内容不是 user behavior | 66 test 改用 `l10n.xxx` 或 `find.text(l10n.xxx)`, 配 lock-in 守门员 `grep -E "find\.text\('[\u4e00-\u9fff]" lib/ test/` | 3d |
| **P0-21** | **9 fail 是 R108 P0-029 拆 notification_service 的回归** | 拆 NotificationInitializer (174L 0 test) + 3 dispatcher mode, 但 9 fail 在 assessment_reminder_service_round12_test.dart 暴露 state machine mock 缺失 | 补 4 NotificationInitializer unit test + assessment_reminder state machine 8 case | 2d |
| **P0-22** | **7 fail 静态分析 lock-in (superpowers test-after)** | `notification_service_can_exact_round108_test.dart` Part A / C 跟 `skip_backup_round108_test.dart` Part B 是 R32 写的 lock-in test, 用 grep source 验证 P0-029 修复 — 跑 7 fail = lock-in test 错, 可能是 grep 模式过严或 source 改了 | 检查 grep 模式跟 source 一致, 7 fail 改测试 | 1d |
| **P0-23** | **1553 注释 (估算 23%) R32 改 lib/ 没动 R31 spec 章节** | R31 22 commit 100% 跟 spec §3.4.3, R32 11 commit 0 个 spec 引用 — R32 修的是 R108/上轮 audit 出的 P0, 不是 spec 驱动的 | R32 round 12+ 应该 spec 优先, 不只是 audit 修 | 1d |

## 4. P1 (按 superpowers 7 维度分类, 共 16 条)

### TDD 实践度 (5 条)

**P1-1**: R31 round 1-3 token 改 + lock-in test 同步 (R1 colors, R2 typography, R3 spacing) 是真 TDD. 但 R31 round 4-8 (motion / PrimaryButton / CheckInButton / StatCard / AppleHealthTile) 改 + lock-in test 同步也是 test-after (test 跟 commit 而非先写). **整改建议**: R109 起所有新功能 commit 顺序强制 `<test_red> <impl_green> <refactor>`

**P1-2**: `test/widget_test.dart` 是 v0.27 R61 写的 smoke test (3 case, 测 l10n 资源加载), 不是真集成 test. 完整 integration test 散在 `test/integration/end_to_end_flows_round95_test.dart` (5 case) 跟 `test/integration/cbt_thought_record_flow_round84_test.dart` (1 case) = 6 integration 太少. **整改建议**: R109 加 setup → home → check-in → assessment → export 5 端到端 e2e

**P1-3**: `test/main/boot_apps_split_round108_test.dart` 是文件级 grep lock-in (line count < 300), **不真跑 main()** — 主启动路径 0 集成 test. **整改**: R109 加 main() integration test (mock dotenv + db + notification)

**P1-4**: 95 widget test, 172 unit test — widget / unit 比 35.6%, **presentation 层 widget test 偏低**. 121 0-test lib 文件里 80% 是 presentation. **整改**: R109 R110 拆 god class 时, 每个拆出来的子 widget 必须有 widget test

**P1-5**: 0 test 测 `lib/main.dart` 实际启动顺序 (SQLCipher init / notification init / ProviderScope). 真 P0 launch 风险. **整改**: 加 1-2 test 覆盖 main() 启动 (mock 平台通道)

### spec-driven (2 条)

**P1-6**: `lib/core/theme/spring.dart` 写了 145L spec 详细的 Spring physics (mass/stiffness/damping 表格), 但 0 caller 直到 R32 round 10. spec 先于实现, 严重违反 superpowers "写最小可行 + 测完再扩" — 应该 0 写完, 等真需要时再写

**P1-7**: R31 round 22 spec `docs/design/2026-08-10-apple-health-redesign/spec.md` 22KB 引用 200+ 次, R32 11 commit 0 引用 spec. R32 修的 P0 来自 R31 audit 报告, 不来自 spec. **整改**: R32+ commit 强制附 spec 引用

### verification gate (3 条)

**P1-8**: 18 守门员 0 个能拦下 126 fail (其中 11 个是 i18n hardcoded 中文). 应该加:
```
grep -E "find\.(text|byTooltip|byKey)\(['\"]?[\u4e00-\u9fff]+" test/ | wc -l
```
0 命中才绿

**P1-9**: `check_coverage.py` 跑要 `flutter test --coverage`, 但 R32 v0.31.1-bug-batch 0 coverage 数据. CI 必跑, 没人跑. **整改**: CI 加 `flutter test --coverage && python3 scripts/check_coverage.py --ci`

**P1-10**: `check_widget_dispose.py` 只查 1 类资源泄漏 (Stream subscription), 不查 Timer / ChangeNotifier / AnimationController / ScrollController 4 类. **整改**: 扩 4 类守门员

### debugging 严谨 (2 条)

**P1-11**: 7 RangeError 集中在 `setup_consent_round14_test.dart` / `setup_page_round77_test.dart` / `reminders_hub_round12c_test.dart` — 都是"勾 N 个 checkbox 触发 step 切换" 的状态机 bug. **整改**: 4 步系统调试 (1. 复现 2. 假设 3. 验证 4. 修) + 1 file 1 PR

**P1-12**: 6 StateError 集中在 `settings_page_r93_hide_test.dart` / `settings_page_round45_test.dart` — `emergencyContactEnabled=true` / `fiveVendorPushEnabled=true` FeatureFlag 翻 true 但 widget tree 没刷新. **整改**: 加 FeatureFlag watch + re-render test

### 测试覆盖 (2 条)

**P1-13**: 11 god class (≥400L) 0 test (P0-06~P0-16) — 这是 superpowers 最严重的违反, 应该 CI 红

**P1-14**: 55 orphan ARB key — 定义了 i18n key 但 0 caller = spec 写了但 impl 没接. 应该 CI 红 (`check_orphan_arb_keys.py` 已做, 1 句 script 修)

### 架构纪律 (1 条)

**P1-15**: `lib/presentation/services/scale_translations_l10n/` 命名不直观 — `services` 子目录通常放业务 service, 这个是 i18n 包装. **整改**: 移到 `lib/core/l10n/scale_translations.dart` (跟 `lib/core/l10n/strings.dart` 平行)

### CI/CD (1 条)

**P1-16**: R32 fix branch 11 commit 0 commit 标题带 "(CI friendly)" 或 "(+5/-0 lock-in test)" 等可识别的 CI 标记. **整改**: R109+ commit 标题强制含 "[CI]" tag

## 5. P2 + P3 摘要 (前 10 条)

### P2 (10 条)

- **P2-1**: 71 info (45 trailing comma + 12 const constructor + 4 use_key + 4 build_context_sync + 2 named_constants) — `dart fix --apply` 1 步净, 但 R31 round 12b 写过, R32 又涨, CI 应强制 0 info
- **P2-2**: `dart format` 2 个文件未 format (R31 round 12b 提, R32 0 commit 修)
- **P2-3**: 33 PUA 字符 (含 audit-history 4 个 + 估计 29 个其他位置) 跨多文件
- **P2-4**: 5 R32 P0 (P0-01~P0-05, P0-07~P0-08) 跟 R31 9 个 P0 (R108 P0-029 拆 notification_service) 强耦合, 修 1 个要 2 个 commit 同步
- **P2-5**: R31 round 12b global sanity test 改 AST 用了 `dart:mirrors` (mirror reflection, R32 0 commit 删)
- **P2-6**: `lib/core/data/services/notification_service.dart:35,55` 双重 `swallow_error` import (R32 round 6 修 visibility 时引入, 留 duplicate + unused_import 2 warning)
- **P2-7**: `lib/presentation/pages/medication/medication_page.dart:47` `_slotIcon` unused element (R32 round 11 漏)
- **P2-8**: `lib/core/data/utils/skip_backup.dart:56` `_channel` annotation `@visibleForTesting` 在 private 字段 (lint: `invalid_visibility_annotation`)
- **P2-9**: `lib/presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart:12` `non_const_argument_for_const_parameter` (常量参数传变量)
- **P2-10**: `test/presentation/pages/daily_tracking/helpers_round108_test.dart:37` `_untouchedWidgets` unused (R32 round 10 改 widget 留下)

### P3 (5 条)

- **P3-1**: `check_zh_hant_consistency.py` 缺 opencc 包, 跑 `pip install opencc-python-reimplemented`, 但 R32 0 commit 改
- **P3-2**: `check_16kb_alignment.py` R32 0 commit 跑, 需 Android .so 重 build (R32 改 launch_background.xml / styles.xml 之后)
- **P3-3**: `check_fullwidth_punctuation.py` 133 violation (warn-only), 跟 R57 R95 30+ 处修复不一致 — `lib/l10n/app_localizations.dart:1443` 是生成文件, 应在守门员排除名单
- **P3-4**: 3 author (Mavis / Apple Health Redesign Agent / Mavis (AI Agent)) 不一致, R32 0 commit 统一
- **P3-5**: CHANGELOG 数字 stale (R31 23 commit 净 +7447/-3504, R32 11 commit 净 +350/-200 估, CHANGELOG 0.31.1 段没列)

## 6. 总结

### 6.1 跟 R31 对比变化 (R31 8.5 → R32 5.5, -3.0)

| 维度 | R31 评 | R32 评 | 变化 | 原因 |
|---|---|---|---|---|
| TDD 实践度 | 9.0 | 4.0 | **-5.0** | R31 12/13 改 test 同步偏乐观, 实际 i18n migration 漏 66 test, 真 5/13 = 38% |
| spec-driven | 8.5 | 7.0 | -1.5 | R32 11 commit 0 spec 引用 |
| verification gate | 9.0 | 3.0 | **-6.0** | 126 fail 半年没修 = 严重 verification gap; 18 守门员 0 个拦 i18n hardcoded |
| debugging 严谨 | 8.5 | 2.0 | **-6.5** | 78 TestFailure + 8 RangeError + 6 StateError 0 systematic-debugging |
| 测试覆盖 | 7.5 | 6.0 | -1.5 | 121 0-test lib 文件 (29.7%) 还在; 11 god class 0 test |
| 架构纪律 | 9.0 | 8.0 | -1.0 | 4 层 0 violation 仍稳, 但命名不直观 (P1-15) |
| CI/CD | 8.5 | 6.0 | -2.5 | check_changelog 错序 + 4 PUA + 55 orphan ARB key |
| **加权综合** | **8.5** | **5.5** | **-3.0** | 上述 7 项加权 |

**R31 给 8.5 是看 commit 表面** (commit message 跟 spec / TDD 标签同步, 守门员全绿) **R32 给 5.5 是看 commit 实际后果** (126 fail 跨 29 文件, i18n test 没改, god class 仍在)

### 6.2 126 fail top 5 模式

1. **66 (52.4%) - TestFailure_中文文本未找到** (i18n 迁移没同步 test)
   - 代表: `assessment_history_round13b_test.dart:11` (1 文件 11 fail)
   - 根因: source 改 `Text('还没有评估记录')` → `Text(l10n.noAssessmentRecords)`, test 仍 `find.text('还没有评估记录')` → 找不到
   - 模式: 66 test 跨 21 文件
   - 修法: 66 test 改用 `find.text(l10n.xxx)`, 加 lock-in 守门员

2. **10 (7.9%) - TestFailure_EmptyState 未渲染** (EmptyState widget 找不到)
   - 代表: `medication_calendar_round13c_test.dart:2`, `legal_consent_enforcement_round67_test.dart:2`
   - 根因: source 加 EmptyState widget 但 test 仍用 find.text (空态文案改了 key)
   - 模式: 跨 8 文件
   - 修法: 跟 1 同步改

3. **8 (6.3%) - RangeError_越界** (state machine 状态切换 bug)
   - 代表: `setup_consent_round14_test.dart:1`, `setup_page_round77_test.dart:1`
   - 根因: checkbox 切换状态机没正确 transition, 数组越界
   - 模式: 跨 4 文件
   - 修法: 4 步 systematic-debugging 修 state machine

4. **6 (4.8%) - StateError** (FeatureFlag mock 缺失)
   - 代表: `settings_page_r93_hide_test.dart:3`, `settings_page_round45_test.dart:1`
   - 根因: test mock 5VendorPushEnabled=true 但没 mock 5 vendor push channel
   - 模式: 跨 2 文件, 4 case

5. **33 (26.2%) - 其他_无栈** (R108 P0-029 拆 notification_service 回归)
   - 代表: `notification_service_can_exact_round108_test.dart:3`, `skip_backup_round108_test.dart:3`, `assessment_reminder_service_round12_test.dart:9`
   - 根因: R108 拆 3 facade (NotificationInitializer + ReminderDispatcher mode + SkipBackup channel), 但 lock-in test 用 grep source 不是真行为 test
   - 模式: 跨 5 文件, 15 case
   - 修法: 改 1) 修 lock-in grep 模式, 2) 加 5 unit test 测真实 behavior

### 6.3 优先级排序 (P0 → P1 → P2 → P3)

| 优先级 | 工作 | 影响 | 估时 |
|---|---|---|---|
| **#1** | 修 126 fail (76 i18n + 50 mock) | CI 红, 上架 blocker, TDD 红旗 | 5d |
| **#2** | 11 god class 拆 + 75 test (5-7 test / file) | 4 层架构清, 风险降 | 10d |
| **#3** | 55 orphan ARB key 删 / 接 | i18n 一致性, 跨期残留 | 4-6h |
| **#4** | check_changelog + check_no_pua + 23 warning 修 | 18 守门员全绿 | 1h |
| **#5** | spring.dart facade 真接 3 caller | 孤儿代码清, Apple Health 视觉层闭环 | 1d |
| #6 | 1 main() integration test + 5 e2e (P1-2 P1-3) | 启动路径安全 | 3d |
| #7 | check_coverage.py CI 必跑 (P1-9) | 覆盖率 gate | 1h |
| #8 | 33 PUA 字符全清 (P2-3) | lint 0 violation | 2h |
| #9 | 71 info `dart fix --apply` (P2-1) | 0 info 目标 | 30 min |
| #10 | AGENTS.md 补 R32 章节 (跟 R31 P0-06 一致) | dev doc 同步 | 1h |

### 6.4 "如果只能改 3 件事"

1. **修 126 fail (5d)** - 整个 R32 实际是失败的: 11 commit 修 11 P0 看着漂亮, 但 126 fail 没人动. R33 第 1 周必须修 76 i18n (改 test 用 l10n) + 50 mock (加 setup). 修完 0 fail = 真正 TDD 绿.

2. **11 god class 拆 + 75 test (10d)** - 11 个 ≥400L 的 lib 文件 0 test, 是 superpowers 最严重的违反. R109 god class 专项已经规划, 但 R32 没动. 拆完每个子文件 5-7 test, 总加 75 test, 提升覆盖率 5-10%.

3. **加 1 个 main() integration test + CI 必跑 coverage (3d)** - `lib/main.dart` 275L 真启动路径 0 test, 是上架后 crash 风险最大点. 加 1-2 test 测启动顺序 (mock dotenv + db + notification). 同步加 `check_coverage.py --ci` 进 CI 必跑.

### 6.5 跟 R31 报告独立验证

R31 报告 (8.5/10) 跟 R32 实际状态 (5.5/10) 差 3 分, 关键差异:

- **R31 看 commit message 跟 spec / TDD 标签** (12/13 test 同步自评) → **R32 看 commit 实际后果** (126 fail 跨 29 文件, 66 i18n hardcoded)
- **R31 看 18 守门员全绿** → **R32 看守门员 0 个拦 i18n test-after** (需新加 `grep hardcoded Chinese in test/`)
- **R31 看 23 commit 提交规范好** → **R32 看 R32 11 commit 0 spec 引用** (跟 R31 比反而退)
- **R31 看 R108 P0-029 拆 god class** → **R32 看拆完 0 test** (notification_initializer 174L 0 test)
- **R31 看 spring.dart 是 1 caller** → **R32 看仍是 1 caller** (R32 round 10 加 5 test 但 caller 数未变)

R31 8.5 跟 R32 5.5 之间的差就是 "superpowers 标签" 跟 "superpowers 实质" 的差. R31 是个好学生但考试不好; R32 暴露了真实问题.

## 7. 给 R33 的具体 actionable items

按 superpowers-en 7 维度各列 1 个:

1. **TDD**: 修 76 i18n fail 改 test 用 `l10n.xxx` (跨 21 文件, 66 test)
2. **spec-driven**: 修 spec baseline 数字矛盾 (emil + superpowers-zh + superpowers-en 3 视角共识)
3. **verification**: 加 4 类资源泄漏守门员 (Timer/ChangeNotifier/AnimationController/ScrollController)
4. **debugging**: 用 4 步法修 8 RangeError (state machine 越界)
5. **覆盖**: 拆 11 god class, 各加 5-7 test (75 test 总)
6. **架构**: 把 `lib/presentation/services/scale_translations_l10n/` 改名 `lib/core/l10n/scale_translations.dart`
7. **CI**: 加 `grep -E "find\.(text|byTooltip|byKey)\(['\"]?[\u4e00-\u9fff]+" test/ | wc -l` 守门员 (i18n hardcoded 检测)

---

**报告路径**: `docs/audit/2026-08-11-r32-multi-lens/02-superpowers-en.md`

**P0 总数**: 23 (5 上架 CI fail + 11 god class + 5 半成品 + 2 misc)

**P1 总数**: 16 (按 7 维度分)

**P2 总数**: 10

**P3 总数**: 5

**评估方法**: 独立跑 17 个 Python 守门员 (无 flutter SDK 用 worktree 真跑日志) + 检查 121 0-test lib 文件 + 126 fail 归类 (5 模式) + 跨 R31 R32 commit 对比
