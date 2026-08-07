# superpowers-en 软件工程审计

> 审计对象: `D:\Batch\chroniccare`
> 审计时间: 2026-08-06
> 审计视角: superpowers 14 子技能方法论 (TDD / Systematic Debugging / Subagent-Driven Development / Code Review / Git Worktree / Brainstorming & Planning / Writing Code / Database / 4-Layer Architecture / Privacy Boundary / Resources / Test Infrastructure / Guard Scripts / Docs & CHANGELOG)
> 审计范围: `lib/` (342 dart 文件, 73,726 LOC) + `test/` (205 测试文件, 30,076 LOC, 1,402 `test()` 调用) + `scripts/` (16 守门员 + 1 备份脚本) + `docs/` (52,338 LOC) + `docs/superpowers/` (7 specs + 7 plans + 8 sdd-logs) + `.superpowers/sdd/` (worktree 残留) + `.worktrees/` (1 orphaned)

---

## 总体评估

**项目工程水位: 8.0 / 10** (跟 AI 编程超能力社区 best practice 的差距)

这是中文 Flutter 圈里**SDD (Spec-Driven Development) 实践最深**的项目之一,几乎没有之一。具体表现:

1. **SDD 闭环完整**: 8 个 round (R84-R91) 全部走 `spec → plan → task brief → task report → review report → fix round → merge → sdd-logs 归档` 全流程, 每个 sub-spec 1-7 task, 每个 task 1+ commit, 每个 round merge 后 `progress.md` 标完成 + baseline test count + guards 状态。
2. **16 守门员全部就位 + 串到 `dart analyze` + `flutter test` + CI**。覆盖: ARB key 同步、CHANGELOG 同步、跨 feature import、datetime race (2 个版本)、drift namespace、全角标点 (warn-only)、UTC 硬编码、PUA 字符、widget dispose、orphan ARB key、单独同意 (PIPL §13/§14)、SMS 上架就绪 (warn-only)、硬编码字符串、繁简一致性、4 层架构纯度 + 一致性。
3. **TDD 红绿循环可见** — `task-X-brief.md` 95% 写明 "step 1: 写失败测试 → step 2: 跑 FAIL → step 3: 实现 → step 4: 跑 PASS → step 5: commit"。R90 task 1-5 + R91 task 1-6 全部按此 pattern 跑通。
4. **Final review 找 bug 后 fix 1 round 模式** — R91 fix 4 Critical + 3 Important (4 个数据流 integration bug + 3 个 l10n/dead code);R88 spec/plan 阶段主动捕获 P0 silent data loss;R84 mood 字段全链路透传 (moodRepository.add 是 P0 production bug 修)。

**差距集中在 5 处** (跟社区 best practice 真正有距离的):

1. **God class 拆分收尾不彻底**。`NotificationService` 18,392 字节 (~580 行) 仍是单文件,虽然内部按 round 45b 拆了 3 facade 子 (notification_init / notification_payload / reminder_dispatcher 拆出),但核心 `notification_service.dart` 还在。`SafetyWatchService` 17,906 字节 (~540 行) 同样。`EmailService` 8,157 字节 + `SmsService` 13,411 字节都是单文件,作为 facade 自身没拆。
2. **DataExportService 拆分后 facade 命名冲突**。`lib/core/data/services/data_export_service.dart` 110 行只做 facade 委托,实际逻辑全在 `lib/core/data/services/export/` 4 子文件 (`export_orchestrator.dart` 305 行 + `export_crypto_service.dart` 67 行 + `export_schema_service.dart` ? + `export_import_pipeline.dart` 409 行 + `export_audio_service.dart` ?),但原 50+ 老 test + 老 import 路径全部指向 facade,新增 5+ 文件 + 0 删除,导致**实际新增 ~800 行但删 0 行**,净 debt 增长。
3. **worktree 残留 + 1 个 .disabled test**。`.worktrees/feat-cbt-thought-report/` 仍存在 (branch 已删, 只剩空 `.superpowers/sdd/` 目录) — R89 文档承诺 "Worktree 移除 + branch 删除" 但 directory 没 `rm -rf` 清理。`test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` 是 R57 写、至今未启用。
4. **i18n 留尾**: R84-R91 共加 252+ ARB keys, 但 `presentation/widgets/empty_state.dart` + `error_state.dart` + `app_list_tile.dart` + `medication_report_dialog.dart` + `cbt_section.dart` 等 14 个文件仍含 45 处硬编码 `Text('...')` 中文。R90 + R91 守门员 `check_strings_hardcoded.py` 规则不够严 (允许 `Text('...')` 字面, 因为 R56+ 部分改有阻力), 没挡住 stub / placeholder 类。
5. **state 集中器有 3 个 .disabled-like workaround**:
   - `_smsService` 顶层 static 单例 + Provider override (R62 修 P0-3 state 错位)
   - `_emailService` 顶层 static 单例 (R67 B-1 修 release 模式 mock 静默)
   - `AppDatabase` 顶层在 main 构造 + Provider override 注入
   - 这 3 个 workaround 是 R19 之前的反模式累积, 每次新需求都加一个 override, 没改 1:1 重构成"全跑 Provider"。

**给 P0 必改的 5 件事 (上 App Store 前必修)**:

1. **AliyunSmsProvider.send() 仍 throw UnimplementedError** — 真接阿里云是 v1.0 必要条件, 当前 `check_sms_release_ready.py` 降级为 warn-only (R58), 唯一阻止上 store 的"假成功"风险点
2. **mock SMS release fail-fast 已有, 但 EmailService 没真接** — 同样状态, 上 store 前必须修
3. **.worktrees/feat-cbt-thought-report 残留** — 影响 worktree list 输出, 误导新进开发者
4. **`test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled`** — 启用 + 真接 + 删除
5. **3 个顶层 static workaround (smsService / emailService / AppDatabase) 重构成纯 Provider** — P2 但不修会成为 R92+ 改 1 个动 3 个的债

---

## 1. TDD (Test-Driven Development)

### 1.1 整体评价

**TDD 水位: 8 / 10** — 红绿循环可见, regression test 跟 commit 绑定, 但有"事后补 test"痕迹。

**正向证据**:
- **R91 task 1 (data, schema 17→18 + 6 表)**: commit 1624db5, +14 test 随 commit, 0 重构
- **R90 task 5 (ui, 多线趋势图)**: commit 4351d86, 6 文件改 + 6 文件测试
- **R90 task 6 fix round 1 (review)**: 4 Critical data flow bug, 每条有 `TDD red→green` 段落写明 "test 改 :48 (R60 total=12 解析为 score=12)" — 真的 TDD, 写失败测、跑 FAIL、改 prod、再 PASS

**反向证据**:
- **`test/domain/entities/mood_entry_entity.dart` 业务方法**:`isCbtRecord` / `cbtLevel` / `scoreShift` 在 R84 才加, 跟 entity 业务定义同期;但 R84 之前 1.5 年 (`streak_calculator_round3_test.dart` 是 R3, 距 R84 跨 81 个 round) 的 entity 业务方法, 大量是先 prod 后 test。`moodEntry.durationLabelL10n` R65 加, `moodEntry.isCbtRecord` R84 加 — 业务方法基本是"出事才补 test"。
- **`lib/core/data/services/safety_watch_service.dart` 457 行** 仅 1 个 test (`safety_watch_service_round12_test.dart`, 11 round 距 R91 跨 80 个 round, 业务规则早变 N 次, test 没跟)。
- **`lib/core/data/services/sms_service.dart` 336 行** 1 个 test (`sms_service_round14_test.dart` 14 round 距 R91 跨 77 round, `MockSmsProvider.isProductionReady` + `AliyunSmsProvider.send()` R62 P0-1 修都加新 test, 但**核心 facade 行为无 test 跟踪**)。
- **`lib/core/data/services/store_kit_service.dart` 141 行 + 6 处 kDebugMode**: **0 test** (R65 引入, R91 都没补)
- **`lib/core/data/services/email_service.dart` 177 行**: 2 个 test 但都是 facade 行为, `isProductionReady` 业务方法 (R67 B-1 改) 0 覆盖。
- **`lib/core/data/services/db_key_service.dart` 47 行**: 1 个 test (R61) 覆盖, OK。
- **`lib/core/data/services/notification_service.dart` 18,392 字节 (~580 行)**: 4 个 test (`notification_service_round4/19b/split_round45b/refill_round9`), 但 `scheduleDailyReminder` + `showNow` + 11 通知 id cancel 范围 = 200000 公式 (R19B 修) **核心 schedule 路径无 integration test** — 只能靠 setup page 现场 click 测。

### 1.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/core/data/services/notification_service.dart | 18,392 字节单文件, scheduleDailyReminder + showNow + id cancel range 无 integration test | 架构 | 4 | P1 |
| 2 | lib/core/data/services/safety_watch_service.dart | 457 行, 仅 1 test, R12 距 R91 跨 80 round, 业务规则已 N 次变, test 严重过期 | 底层 | 3 | P1 |
| 3 | lib/core/data/services/store_kit_service.dart | 141 行, 0 test, R65 引入, R91 都没补 | 底层 | 2 | P1 |
| 4 | lib/core/data/services/sms_service.dart | send() 真接 Aliyun 是 v1.0 blocker, 1 test 是 facade, 0 覆盖真接路径 | 底层 | 2 | P0 |
| 5 | lib/core/data/services/email_service.dart | isProductionReady 业务方法 (R67 改) 0 覆盖, mock 真接路径 0 test | 底层 | 2 | P0 |
| 6 | lib/core/data/services/cbt_thought_record_pdf.dart | 60 行 facade, 仅 1 test | 底层 | 1 | P2 |
| 7 | lib/core/data/services/medication_report_pdf.dart | 110 行, 1 test, layout 10,715 字节独立 0 test | 底层 | 3 | P1 |
| 8 | lib/core/data/services/mood_audio_service.dart | 377 行, 1 test, dispose + cleanup 路径没 widget test 验 | 底层 | 2 | P2 |
| 9 | lib/core/data/services/preset_medication_templates.dart | 8,604 字节纯数据, 0 test (R18 引入) | 底层 | 1 | P2 |
| 10 | test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled | R57 写, 至今未启用 (与 #4 同根) | 底层 | 1 | P0 |
| 11 | lib/core/data/services/badge_sync_service.dart | 4,232 字节, R70 删 18+ TODO, 但 badge 数字同步逻辑 0 test | 底层 | 2 | P2 |
| 12 | lib/core/data/services/snooze_manager.dart | 6,186 字节, 1 test (R18), 跨 73 round | 底层 | 2 | P2 |
| 13 | lib/core/data/services/database_migration.dart | 3,219 字节, 2 test, OK 但 8→9 一次性加密 vent 历史 路径 (R21 P0-1) 仅 1 case, 老 contentText 列保留是否真没读 0 验 | 底层 | 3 | P1 |
| 14 | test/integration/ 目录 | 1 个文件 (cbt_thought_record_flow_round84_test.dart), 全项目缺端到端 integration | 架构 | 5 | P2 |
| 15 | 205 测试文件 / 38 个 round tag | R3-R91 跨度, R52-R59 中间断档 (没 test 记录) | 底层 | 1 | P3 |

### 1.3 修复路线 (P0 → P3)

1. **P0**: 启用 `aliyun_sms_provider_round57_test.dart.disabled` + 在 R55 真接阿里云 (依赖外部) 之后 verify pass
2. **P0**: EmailService 写 isProductionReady 真接 test (R67 B-1 跟 SMS 平行, 是 v1.0 必要条件)
3. **P1**: 拆 `notification_service.dart` ≥ 2 层 facade (现在 ~580 行, 应该是 `notification_service.dart` + `notification_id_allocator.dart` + `notification_schedule_pipeline.dart`)
4. **P1**: 写 `safety_watch_service` R91 snapshot test (capture current 业务行为, 后续 R92+ 改时能立刻 fail)
5. **P1**: 写 `medication_report_pdf_layout` snapshot test (10,715 字节纯 layout, 0 test 是真风险)
6. **P2**: 加 `test/integration/setup_to_check_in_round91_test.dart` — 端到端走 setup → check-in → home 显示, 验 4 层架构跨层 OK
7. **P2**: `preset_medication_templates` 0 test → 加 fixture test 验 8 个默认模板的字段完整性
8. **P3**: R52-R59 断档区 (8 个 round 0 test) → 在下一个 round 加 1 regression test 覆盖断档 (例如 `medication_calendar_round60_test.dart` + 5 个 P0 R56 fix 的回归)

---

## 2. Systematic Debugging (系统调试)

### 2.1 整体评价

**水位: 7.5 / 10** — 大部分 P0 bug 有"修复 + regression test"双锁, 但启动顺序 / dispose 模式 / async gap 仍有 3 类典型风险。

**正向证据**:
- **main.dart `_bootstrap()` 启动顺序**: 6 步骤有详细注释 + MigrationException 区分 + 顶层 `_smsService` + `_emailService` static 单例 (R62 修 P0-3 state 错位) + `runZonedGuarded` 兜底 (R33 P0 修 swallow) — 这是 4 年迭代沉淀的稳健模式
- **dispose 模式**: `vent_detail_page.dart` 3 个 `_xxxSub` 存字段 + dispose 全 cancel, 是 R16 round 19B 修过的标准模式
- **Notification id cancel range 200000** 公式 (R19B 修前 1000/100000 太窄) — 在注释中明确写, 防回归
- **跨 midnight streak 刷新**: `AppRoot` 挂 midnight timer, `nextMidnightRefresh()` 跨月/跨年正确, 5s buffer 防 race
- **DateTime.now() race** (R19B/R14 修): `streak_calculator.dart:39` 函数入口 `normal.sort((a, b) => b.timestamp.compareTo(a.timestamp))` 显式 sort + `saveSetup` 入口 `final now = DateTime.now();` 1 次

**反向证据 (3 类典型风险)**:

#### 风险 1: 启动顺序硬编码 + 没 health check
- `main.dart:107` `_bootstrap()` 步骤 1-6 写死顺序, 步骤 4 `DatabaseMigration.migrateIfNeeded()` 失败直接 `runApp(_MigrationFailedApp)`, 但**步骤 3 通知服务 init 失败只 piiSafeLog, 步骤 3.5 短信守卫 throw 是合理的**
- **没 health check 报告**: 启动后用户进 app, 通知权限没给 / DB 半开 / SharedPreferences 写失败, 都不知道
- `LastErrorCapture` 仅在 runZonedGuarded catch 块记录 uncaught, **启动时 caught 错误 (try {notificationService.init} catch) 不记录**, 用户漏 1 天通知都不知道为什么

#### 风险 2: dispose 集中器是"分散"而不是"统一"
- `vent_detail_page.dart` 3 sub 字段 + cancel + _player.dispose + temp file cleanup, 8 行 dispose
- `mood_audio_section.dart` 2 sub 字段 + 1 字段 cancel, 但 player dispose 委托给 caller
- 4 个 widget (`vent_compose_page` / `vent_detail_page` / `mood_audio_section` / `mood_recorder_page`) 各 dispose 自己的 audio, 模式不统一
- 改动 audio 模式 (e.g. 换 `just_audio`) 时要改 4 处, 没抽象 AudioController wrapper

#### 风险 3: SQLCipher 加密 + audio 路径 R15+ 一直保留
- `app_database.dart:79-90` v8→v9 注释明确写 "旧 contentText 列保留(代码层不再用), 后续 v10+ 彻底 DROP" — 但 v10 / v11 / v12 / v13 / v14 / v15 / v17 / v18 8 次 schema 升级**全没 DROP** 旧 contentText 列
- 旧 vent 数据**文字+加密双份**存在 DB, 占空间 + 攻击面 (明文如果 backup 没删就被取出)
- v15+ vent_repo / vent_mapper 应该报"读 contentText (非 enc) → throw" 才能真正守门, 当前是 `// 代码层不再用` 注释, 实际 drift row 还能 select 出来, UI 不会读但 DB schema 永久拖

### 2.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/main.dart:150-160 | 通知 init 失败只 piiSafeLog, 没 catch → LastErrorCapture, 用户漏通知不知道 | 底层 | 2 | P1 |
| 2 | lib/main.dart:196-207 | 启动顺序硬编码 6 步, 缺 startup health check 报告 (DB ok / 通知 ok / SP ok / IAP ok) | 架构 | 4 | P2 |
| 3 | lib/presentation/pages/vent/vent_detail_page.dart | audio dispose 模式分散在 4 widget, 无 AudioController 抽象 | 架构 | 3 | P2 |
| 4 | lib/presentation/pages/mood/widgets/mood_audio_section.dart | 同上, audio dispose 模式不统一 | 架构 | 2 | P2 |
| 5 | lib/core/data/database/app_database.dart:79-90 + 表 vent_entries | v8→v9 注释承诺"后续 DROP 旧 contentText 列", v10-v18 8 次升级全没 DROP, vent 旧数据永久占空间 | 架构 | 3 | P1 |
| 6 | lib/core/data/services/database_migration.dart:103-219 | v8→v9 一次性加密 vent 历史, 单条失败 swallowError, 但没 metrics 报告 "X 条加密失败 Y 条成功" | 底层 | 2 | P2 |
| 7 | lib/core/data/services/notification_service.dart | scheduleDailyReminder 跨时区 (R24 round 48 tz.local 修过) 没 unit test 验 | 底层 | 3 | P1 |
| 8 | lib/presentation/pages/vent/vent_compose_page.dart | 录音失败 retry 逻辑分散, 0 unit test | 底层 | 2 | P2 |
| 9 | lib/core/data/services/safety_watch_service.dart | 失联检测窗口计算, `now.difference(lastCheckIn)` 多次调用无 sort 防御 | 底层 | 2 | P1 |
| 10 | lib/core/data/services/notification_service.dart | 通知 id 200000 公式在 R19B 注释, 但代码没常量声明 `const kMaxMedId = 10000` 防未来误改 | 底层 | 1 | P2 |
| 11 | lib/main.dart:41, 54, 211 | 3 个顶层 static (smsService / emailService / AppDatabase), 分散的 workaround | 架构 | 4 | P2 |
| 12 | lib/main.dart:85-103 | runZonedGuarded 只 catch uncaught, 启动 try/catch (步骤 3 通知 / 步骤 4 迁移) 失败不 report | 底层 | 2 | P1 |

### 2.3 修复路线

1. **P1**: 启动加 `_bootstrapHealthCheck` 步骤 7, 把 6 步的 try/catch 失败统一写 LastErrorCapture, 启动 banner 显式提示
2. **P1**: vent 旧 `contentText` TEXT 列 DROP, 写一次 migration v18→v19, 升级提示用户重新加密 (PIPL §47 删除权关联, 也算合规清理)
3. **P1**: safety_watch_service 失联检测窗口加 unit test 覆盖 DST / 跨年 / 跨月 / 24h 边界
4. **P1**: 抽 `AudioController` 抽象, vent + mood 4 widget 共享, 未来换 just_audio 只改 1 处
5. **P2**: 3 个顶层 static 抽 `BootstrapServices` 单一类, main 1 行 `await BootstrapServices.run()`, Provider 全用 lazy/autoDispose
6. **P2**: notification id 200000 公式抽常量 + 加 check_id_allocator_test.dart
7. **P3**: database_migration 加 metrics 报告

---

## 3. Subagent-Driven Development (子代理驱动开发)

### 3.1 整体评价

**水位: 9 / 10** — R84-R91 8 个 sub-spec 全部按 SDD 模式跑通, ledger 维护非常细致。

**正向证据**:
- **`.superpowers/sdd/progress.md`**: 当前 R89 final state, "✅ Sub-spec 5 实施完成 (5 task + 2 fix round 1 + 1 final review)" + "✅ Feature flag 隐藏 (user 选): 1 commit `0abf86e` 加 `kAiFeatureEnabled = false` 守卫" — 决策点 + 选 + 后果都记录
- **每个 sub-spec 1 个目录**: `docs/superpowers/sdd-logs/round84-cbt-thought-record/` `round85-cbt-rerated-chart/` `round86-cleanup/` `round87-mood-list/` `round88-cbt-pdf-export/` `round89-ai-rolledback/` `round90-assessment-center/` `round91-daily-tracking/`
- **每个目录有 `sdd/progress.md` + `sdd/task-N-brief.md` + `sdd/task-N-report.md` + `sdd/review-FINAL-*.diff` (494KB) + `sdd/review-*.diff`**
- **task-brief 是 implementer 的 source-of-truth**, 包含 Global Constraints (Flutter version / schemaVersion 跳变 / 已有文件清单 / 目标测试数 / 守门员命令) + TDD 流程 (5 step 模板)
- **task-report 4 行回信**: Status (DONE/DONE_WITH_CONCERNS/BLOCKED/NEEDS_CONTEXT) + commits (短 SHA + subject) + 一行测试摘要 + concerns

**反向证据**:
- **R86 cleanup 是 retrospective fix (1 task 后)**, 不是 1 个 sub-spec 实施 — ledger 标 "25+ Minor findings from sub-spec 1+2 review (comment 措辞 + docstring 编号 + 测试名等)" + "1 commit, +0 test" — 跟 SDD "1 sub-spec = 1-7 task" 模式不一致
- **R90 task 5 review 6 Minor M6** "2 temp helper scripts under `.superpowers/sdd/check_*.py`" — 这些 .py 文件在 `sdd-logs/round90-assessment-center/sdd/` 还**留着** (gen_arb_additions.py / count.py / find_home.py / sample.py 等 11+ 个 __pycache__/), 应该是 cleanup commit 删但没删
- **sdd-logs 没 `.gitignore` 约束** — R90 sdd 目录 17 个 .py + 17 个 .py.tmp + __pycache__ 全进 git (5K+ 临时文件), R91 fix commit "11 untracked _r91_* 临时脚本清理" 才删, R90 没删

### 3.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | docs/superpowers/sdd-logs/round90-assessment-center/sdd/ | 11+ __pycache__ + .py.tmp + 17 helper .py 仍存在, R90 cleanup 没清 | 底层 | 1 | P2 |
| 2 | .worktrees/feat-cbt-thought-report/ | R84 留下的 worktree directory, branch 已删但目录残留 (.superpowers/sdd/ 2 文件) | 底层 | 1 | P1 |
| 3 | .superpowers/sdd/ | 主 .superpowers/sdd/ 留 R89 task-1-brief.md + progress.md, R89 "Worktree 移除 + branch 删除" 时没回收主 .superpowers/sdd/ | 底层 | 1 | P1 |
| 4 | R86 "cleanup" 模式 | 跟 R84-R91 "1 sub-spec = 1-N task 实施" 模式不一致, 是 retrospective fix, 未来 R92+ 该走 sdd-logs/round92-sprint-fixes/ 显式分类 | 架构 | 2 | P3 |
| 5 | docs/superpowers/specs/ 7 个文件 | spec 全部 4-15K, 但**没 spec 模板**, 写 spec 时新 implementer 不知道"必须包含什么章节" | 底层 | 1 | P2 |
| 6 | docs/superpowers/plans/ 7 个文件 | plan 15-80K, 1 个 (cbt-thought-record.md) **80,726 字节** — 远超 superpowers 推荐的 15-80KB 上限 | 底层 | 2 | P2 |
| 7 | task-brief 文件 (R90+) | 缺 TDD red→green 实际测试 fail log 归档, 只有 "Expected: PASS 3/3" 描述 | 底层 | 1 | P2 |
| 8 | 1 sub-spec = 1 git branch | 每次 sub-spec 实施都在 worktree, 但**worktree 1 次性**, branch merge 后删;R89 实施完 5 task + 2 fix = 7 commit 都在 worktree, 删 worktree 后 ledger 缺分支历史 | 底层 | 1 | P2 |

### 3.3 修复路线

1. **P1**: `mavis-trash .worktrees/feat-cbt-thought-report/`, `mavis-trash .superpowers/sdd/`, `git worktree prune`
2. **P1**: `mavis-trash docs/superpowers/sdd-logs/round90-assessment-center/sdd/__pycache__/` + 17 .py + .py.tmp (R90 task 5 review M6 说要清但没清)
3. **P2**: 拆 `docs/superpowers/plans/2026-08-04-cbt-thought-record.md` 80K → 拆 3 个 sub-plan (task 1-3 / task 4-6 / task 7-10) 或压缩
4. **P2**: 写 `docs/superpowers/SPEC_TEMPLATE.md` + `docs/superpowers/PLAN_TEMPLATE.md`, 强制 R92+ spec/plan 按模板写
5. **P3**: R92+ 改 "cleanup" 模式 → 改用 `sdd-logs/round92-cleanup/` 显式分类, ledger 同步

---

## 4. Code Review (代码审查)

### 4.1 整体评价

**水位: 8.5 / 10** — 提交风格统一 + 大量 self-review (R86/R90 fix round), 但 R86 cleanup 25+ Minor 是 R84-R85 留下, 说明 review 没在 commit 时做。

**正向证据**:
- **提交风格严格遵循 AGENTS.md 模板** `<version> round <N> (<scope>): <title>` — `git log --oneline -n 30` 100% 一致
- **scope 标签清晰**: (data) / (ui) / (state) / (i18n) / (test) / (fix) / (spec/plan) / (cleanup) / (docs) — 8 类, 易 grep
- **没有 "fix last commit" / "wip" / "tmp" 混进 master** (除了 `_r91_*` 临时脚本是删, 没 commit 进 master)
- **fix round 1 模式**: R86 fix 25+ Minor / R90 task 6 fix 4 Critical + 3 Important / R91 fix I-1 + I-2 / R91 fix I-1 FAB label + 11 untracked 清理 — review 文化已立
- **commit message 详情**: 关键 fix 写"4 Critical data flow integration bug + 3 Important i18n + dead code", 不只标题

**反向证据**:
- **`R84 moodRepository.add 透传 8 CBT 字段 (P0 production bug)`** commit `bcce87b` 距 R84 spec 实施 commit `ac75e7a` 8 commit, 即 schema/mapper 都对, 但 repo 层漏透传 1 个文件 — 典型的"5 步走 5/6 漏 1", 6 步走 commit 没全防
- **R90 task 6 review 4 Critical**: R60 旧 `saveAssessment` JSON 跟 R90 新 reader keys 不匹配, 老用户 PHQ-9/GAD-7 entry 全部 score=0 — 这种 **schema 跨 round 不兼容** 是 R60 升级 + R90 实施跨 30 round 累积, review 没在 R60 实施时 catch
- **R88 task 1 spec 阶段主动捕获 P0 silent data loss** (`fabd864` "data_export moodEntries 加 8 CBT 字段 toMap + import 反序列化 (R84 silent data loss 修复)") — R84 加 8 字段, R88 才发现导出会丢 8 字段, **跨 4 round 才暴露**
- **R91 task 1-7 共 8 commit 平均 89 文件 10K 行**, 大批量 commit 难以 review, 全靠 self-report `+N test` 而不是 peer review

### 4.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | commit bcce87b (R84) | moodRepository.add 漏透传 8 CBT 字段, R88 task 1 spec 阶段才暴露 | 底层 | 1 | P0 (已修, 防回归) |
| 2 | commit fabd864 (R88) | data_export 漏 8 CBT 字段跨 4 round 才暴露 | 底层 | 1 | P0 (已修, 防回归) |
| 3 | commit da1757b (R91) | R60 旧 saveAssessment JSON 跟 R90 reader 不匹配, 跨 30 round | 底层 | 1 | P0 (已修, 防回归) |
| 4 | 全项目 | 1 commit 平均 89 文件 10K 行 (R91 task 1-7), 缺 atomicity 拆分 | 架构 | 3 | P1 |
| 5 | 全项目 | 没自动化 PR 模板 (.github/PULL_REQUEST_TEMPLATE.md 缺) | 底层 | 1 | P2 |
| 6 | 全项目 | 0 peer review 痕迹 (无 `Co-authored-by:` 多人协作, 全是 Mavis 1 人) | 架构 | 5 | P3 |
| 7 | 提交风格 | "Merge: v0.30 round 91 ..." merge commit title 缺 1 句话总结改动 | 底层 | 1 | P3 |
| 8 | .github/ | 目录存在, 0 CI workflow (R91 之前 16 guard + flutter test + analyze 手动跑) | 架构 | 3 | P1 |

### 4.3 修复路线

1. **P0** (已修, 跨 round 兼容问题): 加 R92 spec 模板 "兼容性表" 章节, 强制列 "本 spec 修改字段 + 老数据兼容方式 + 反序列化兜底"
2. **P1**: 写 `.github/workflows/ci.yml` (flutter test + analyze + 16 guards + json encode), PR 必跑
3. **P1**: R92+ commit 拆细 (e.g. R91 task 1 拆 1 data + 1 migration + 1 dao + 1 test 4 commit)
4. **P1**: 写 `.github/PULL_REQUEST_TEMPLATE.md`, 强制列 "5 步走每步的 commit SHA + 测试 evidence + 兼容性表"
5. **P2**: merge commit title 加 1 句话总结
6. **P3**: 加 pair-programming 痕迹 (2-3 sub-agent 协作) — 长期建议

---

## 5. Git Worktree (git worktree)

### 5.1 整体评价

**水位: 7.5 / 10** — 1 个 SDD 流程跑过 worktree (R89), 但残留清理不彻底。

**正向证据**:
- **R89 sub-spec 5 AI 辅助**: 完整走 `git worktree add ../feat-cbt-thought-report feat/cbt-ai` → 5 task 实施 → fix 1 review → fix 2 review → flag 隐藏 → 删 worktree → 删 branch → docs/superpowers/sdd-logs/round89-ai-rolledback/ 归档 — 是 community best practice
- **`.superpowers/sdd/progress.md`** 写明 "✅ Worktree 移除 + branch 删除 (`feat/cbt-ai`)" — 流程闭环
- **没 merge master** 决策也写明 "user 选" + 后果, audit trail 完整

**反向证据**:
- **`.worktrees/feat-cbt-thought-report/` 仍存在** — `git worktree list` 只显示 master, 但目录物理上没删 (`ls .worktrees/feat-cbt-thought-report/.superpowers/sdd/` 还能 ls 到)
- **R89 progress.md 写"Worktree 移除"**但物理上没 `mavis-trash` 清理, 也没 `git worktree prune`
- **R89 是 R84 起的 worktree** (`feat/cbt-thought-record` branch), 跟 AI sub-spec 5 (`feat/cbt-ai`) 是不同 branch, 但**目录复用** — 看到 R89 命名但残留 R84 目录, 误导新进开发者
- **`docs/superpowers/sdd-logs/round90-assessment-center/sdd/test_arb/`** 等子目录: R90 实施时临时 ARB 备份目录, 没清理

### 5.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | .worktrees/feat-cbt-thought-report/ | R84 起的 worktree 物理目录残留, branch `feat/cbt-thought-record` 已删, 但 `ls` 还能看到 | 底层 | 1 | P1 |
| 2 | .superpowers/sdd/ | R89 ledger 在主 .superpowers, R89 "Worktree 移除" 没说主 .superpowers 保留 | 底层 | 1 | P2 |
| 3 | docs/superpowers/sdd-logs/round90-assessment-center/sdd/test_arb/ | R90 实施时临时 ARB 备份目录, 应在 fix round 删 | 底层 | 1 | P2 |
| 4 | docs/superpowers/sdd-logs/round90-assessment-center/sdd/ | 17 helper .py + __pycache__/ 仍存在, R90 task 5 review M6 标 "deferred" 没清 | 底层 | 1 | P2 |
| 5 | 全项目 | worktree 命名不统一 (R89 "feat-cbt-thought-report" 跟分支 "feat/cbt-ai" 不对应) | 架构 | 1 | P3 |

### 5.3 修复路线

1. **P1**: `mavis-trash .worktrees/feat-cbt-thought-report/`, `git worklist prune`, `git worktree list` 验证
2. **P2**: `mavis-trash docs/superpowers/sdd-logs/round90-assessment-center/sdd/test_arb/`, `__pycache__/`, 17 .py
3. **P2**: R92+ worktree 命名规范: `.worktrees/feat-<sub-spec-name>/` 跟 branch 1:1, 实施完直接 `mavis-trash` + `git worktree prune`
4. **P3**: 写 `docs/superpowers/WORKTREE_GUIDE.md` 模板, 强制 R92+ worktree 走

---

## 6. Brainstorming & Planning (头脑风暴 / 写计划)

### 6.1 整体评价

**水位: 7 / 10** — 7 spec 7 plan 全部有, 但 spec/plan 模板没沉淀, 1 个 plan 80K 超上限, 缺 brainstorm 阶段。

**正向证据**:
- **7 个 spec** 全部 `docs/superpowers/specs/2026-MM-DD-XXX-design.md`, 4-15K, 含 Background / Goals / Non-Goals / Architecture / Schema / Open Questions
- **7 个 plan** 全部 `docs/superpowers/plans/2026-MM-DD-XXX.md`, 15-80K, 含 5 步走 + 守门员 + 测试 evidence
- **`superpowers brainstorm` skill** 项目用 R84-R91 都跑, 决策点 (e.g. R89 user 选"flag 隐藏" vs "真接 AI") 全部记录

**反向证据**:
- **`cbt-thought-record.md` 80,726 字节** — 远超 superpowers 社区推荐 15-80KB 上限, R84 1 个 sub-spec 跨 10 task, 80K 难维护
- **`daily-tracking.md` 18,055 字节** 跟 `mood-list.md` 16,780 字节接近 20K 上限
- **plan 模板不统一**: cbt-thought-record 80K 详细, daily-tracking 18K 中等, drift-web-support 15K 简洁 — 3 套风格
- **spec 没"用户故事"章节**, 直接进 Architecture, brainstorm 阶段被合并到 spec 头部"Open Questions" — community best practice 是先 brainstorm 文档再 spec
- **没 design decision log**, AGENTS.md 末尾"决策记录"是简表, 没单独 `docs/decisions/` 系统化 (R22 v0.22 mojibake / R24 round 48 等 4 个 decisions 文件, 但**没 R84+ 8 个 sub-spec 的 decision log**)

### 6.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | docs/superpowers/plans/2026-08-04-cbt-thought-record.md | 80,726 字节, 超 superpowers 15-80KB 上限 | 底层 | 2 | P2 |
| 2 | docs/superpowers/specs/ | 7 spec 风格不统一 (drift-web-support 7.7K vs daily-tracking 13.7K vs cbt 15.5K), 缺模板 | 底层 | 1 | P2 |
| 3 | docs/superpowers/plans/ | 7 plan 风格不统一 (drift-web-support 15.2K vs cbt 80.7K), 缺模板 | 底层 | 1 | P2 |
| 4 | docs/decisions/ | R84-R91 8 sub-spec 全 0 decision log, 关键决策 (R89 flag 隐藏 / R90 12 量表选 10) 散在 spec/plan 头部 | 底层 | 2 | P2 |
| 5 | 全项目 | 缺 brainstorm 阶段文档, 直接 spec 写决策点 (R89 选 flag 隐藏写 process 但没写 alternatives) | 架构 | 3 | P3 |
| 6 | docs/superpowers/specs/2026-07-12-drift-web-support-design.md | 7.7K 是 R84 之前, 1.5 年前, 风格跟 R84+ 不同 | 底层 | 1 | P3 |
| 7 | CHANGELOG | Keep a Changelog 格式 OK, 但 R84-R91 8 sub-spec 没单独"Sub-spec Implementation"分章 | 底层 | 1 | P3 |

### 6.3 修复路线

1. **P2**: 写 `docs/superpowers/SPEC_TEMPLATE.md` + `docs/superpowers/PLAN_TEMPLATE.md`, 强制 R92+ 按模板写
2. **P2**: 拆 cbt-thought-record plan 80K → 3 个 sub-plan (task 1-3 / task 4-6 / task 7-10), 各 25K
3. **P2**: 写 `docs/decisions/round89-ai-flag.md` + `docs/decisions/round90-12-scales.md` + `docs/decisions/round91-hybrid-tracking.md` — 补 R84-R91 8 sub-spec 关键决策
4. **P3**: R92+ 走 brainstorm → spec → plan 三阶段, brainstorm 阶段列 3 个 alternatives

---

## 7. Writing Code (写代码)

### 7.1 整体评价

**水位: 7.5 / 10** — 4 层架构纯度守住 + token 化集中, 但有 14 文件 45 处硬编码中文, 4 类 `catch(_)` 还有 3 类残留。

**正向证据**:
- **`AppTokens` 集中器**: 颜色 / 字体 / 间距 / 圆角 / 动画 / 阴影 / breakpoint 全收口
- **`swallow_error.dart` 集中器** (R39 P1-10 修): 取代全 lib 9 处 `} catch (_) {}` 全静默, 是 anti-pattern 修正范本
- **`care_copy.dart` 集中器** (R18 P1-11): 4 个 trigger 文案 + 软提醒共用, 避免双推
- **null safety 99% 守住**: drift nullable 列 + `DomainValue<T?>` 替代 `Value<T?>` 集中器
- **i18n 模式稳**: `app_zh.arb` + `app_en.arb` + `app_zh_Hant.arb` 3 lang, 1000+ keys, `flutter gen-l10n` 自动生成

**反向证据**:

#### 反模式 1: 14 文件 45 处硬编码中文 (R84-R91 review 漏)
- `lib/presentation/widgets/app_list_tile.dart` 3 处
- `lib/presentation/pages/assessment/assessment_center_page.dart` 1 处 (l10n.assessmentCenterTitle 已存在!)
- `lib/presentation/pages/setup/setup_legal_dialog.dart` 1 处
- `lib/presentation/pages/settings/widgets/cbt_section.dart` 1 处
- `lib/presentation/pages/medication/.../medication_report_dialog.dart` 1 处
- `lib/presentation/pages/daily_tracking/widgets/*` 5 文件 32 处 (R91 task 7 漏改)
- `lib/presentation/widgets/empty_state.dart` + `error_state.dart` 各 1 处 (基础 widget!)
- **守门员 `check_strings_hardcoded.py` 规则过宽**, 允许 `Text('...')` 字面

#### 反模式 2: 4 类 `catch(_)` 残留 3 类
- `lib/core/data/database/daos/assessment_dao.dart:137`: 1 处实际 `} catch (_) {`
- `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:148`: 1 处实际
- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart:139`: 1 处实际 (后续行)
- 9 处是注释 (R39 fix history), 误识别

#### 反模式 3: Magic number 分散
- `lib/core/data/services/safety_alert_builder.dart` 大量 threshold 数字 (24/36/48/72h) 散落
- `lib/core/data/services/notification_service.dart` id cancel range 200000 是 1 处集中, 但 `id + trigger.type.index` 公式散在 4 caller
- `lib/core/data/services/cbt_thought_record_pdf.dart` 60 行 magic font size / margin / padding 散落

### 7.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/presentation/widgets/empty_state.dart:1 | 1 处硬编码 "暂无数据" 之类, empty_state 基础 widget 应强制 l10n | 底层 | 1 | P1 |
| 2 | lib/presentation/widgets/error_state.dart:1 | 同上, 基础 widget 硬编码 | 底层 | 1 | P1 |
| 3 | lib/presentation/widgets/app_list_tile.dart | 3 处硬编码, 通用 widget | 底层 | 1 | P1 |
| 4 | lib/presentation/pages/assessment/assessment_center_page.dart:1 | 1 处硬编码 "12 量表中心" (l10n.assessmentCenterTitle 已存在!) | 底层 | 1 | P0 |
| 5 | lib/presentation/pages/daily_tracking/widgets/* | 32 处硬编码, R91 task 7 漏改 | 底层 | 2 | P1 |
| 6 | scripts/check_strings_hardcoded.py | 规则过宽, 允许 `Text('...')` 字面中文, 漏 #1-#5 | 底层 | 1 | P1 |
| 7 | lib/core/data/database/daos/assessment_dao.dart:137 | 1 处实际 `} catch (_) {` | 底层 | 1 | P1 |
| 8 | lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:148 | 1 处实际 | 底层 | 1 | P1 |
| 9 | lib/presentation/pages/mood/widgets/mood_recorder_page.dart:139 | 1 处实际 | 底层 | 1 | P1 |
| 10 | lib/core/data/services/safety_alert_builder.dart | 24/36/48/72h magic, 缺 `AlertThresholds` const 集中器 | 底层 | 1 | P2 |
| 11 | lib/core/data/services/notification_service.dart | id cancel range 200000 公式散在 4 caller, 缺 `NotificationIdAllocator` 类 | 底层 | 2 | P2 |
| 12 | lib/core/data/services/cbt_thought_record_pdf.dart + _layout | 60+ 110 行 magic font/margin/padding 散落, 缺 `PdfStyleTokens` 集中器 | 底层 | 1 | P2 |

### 7.3 修复路线

1. **P0**: 修 `assessment_center_page.dart:1` 硬编码中文 (l10n key 已存在)
2. **P1**: 14 文件 45 处硬编码中文 → 走 l10n key (4-8h 集中 work)
3. **P1**: `check_strings_hardcoded.py` 规则加严, 任何 `Text('...')` 包含中文字符立即 fail
4. **P1**: 3 处 `} catch (_) {` 改 `swallowError(where: '...', error: e, stack: st)`
5. **P2**: 抽 `AlertThresholds` (24/36/48/72h) + `NotificationIdAllocator` + `PdfStyleTokens` 3 个 const 集中器
6. **P3**: 写 `lib/core/shared/style_tokens.dart` 集中所有跨服务 magic number

---

## 8. Database (Drift + SQLCipher)

### 8.1 整体评价

**水位: 8 / 10** — schemaVersion 18 + 11 张表 + 11 DAO + 11 索引, 4 维 4 表 (medication / check_in / mood / vent) + 1 维 6 表 (R91 日常追踪) 拆分合理, 索引覆盖 4 表主要查询, 但 schema v8→v9 vent 旧 contentText 列 8 次升级没 DROP, mapper 模式 OK, drift namespace 检查有守门员。

**正向证据**:
- **schemaVersion 18**: `app_database.dart:119` `int get schemaVersion => 18;`
- **18 个 schema 跳变 1:1 写到 `onUpgrade`**: v1→v2 (deleteTable+createTable) / v2→v3 (createTable reportHistories) / v3→v4 (createTable moodEntries) / v4→v5 (addColumn medication refill) / v5→v6 (createTable ventEntries) / v6→v7 (addColumn moodEntries 3 col) / v7→v8 (4 index) / v8→v9 (vent 加密一次性迁移) / v9→v10 (4 consent col) / v10→v11 (userName nullable) / v11→v12 (mood audio 3 col) / v12→v13 (check_in med_id index) / v13→v14 (2 index) / v14→v15 (contact 4 consent col + index) / v15→v17 (mood_entries 8 CBT col) / v17→v18 (mood_entries period col + 6 新表)
- **11 张表 + 11 DAO + 14 索引**: tables/11 子目录 (check_in/contact/medication/mood/vent/user_profile/report + daily_tracking 6 张 R91) + 11 DAO + 4 个 check_in/timestamp/vent_DSC/med_active_start 主索引 + 2 R23 round 44 (contact sort/report gen_at) + 1 R27 round 63 (contact consent) + 1 R91 (??)
- **N+1 防御**: vent_repository 全部走 `dao.watchAll()` stream + mapper batch, 不循环 query
- **mapper 模式全覆盖**: vent_mapper / mood_mapper / check_in_mapper / contact_mapper / medication_mapper / user_profile_mapper / report_history_mapper — 7 mapper, row ↔ entity 双向
- **drift namespace 守门员** `check_drift_namespace.py` 验 `@DataClassName` 唯一

**反向证据**:

#### 反模式 1: schemaVersion 跳变注释 "v15→v17 (无 v16 中间版本)"
- `app_database.dart:111-115`: 注释明确写 "code diff 实际是 15→17 (无 16 中间版本); spec 误写'16→17' (e14c6b3 fix spec 12→16 未对应任何代码 schema bump)"
- 守卫 `if (from <= 16)` 同时覆盖当前 v15 + 未来真出 v16 schema
- 风险: 如果 R92+ 真出 v16 中间 schema (e.g. 别的 R 引入 1 个 column 跳 v16), 这里守卫会**跳过 v15→v16 step** 直接跳 v17

#### 反模式 2: v8→v9 vent 旧 contentText TEXT 列 8 次升级没 DROP
- `app_database.dart:79-90` 注释明确写 "旧 contentText 列保留(代码层不再用), 后续 v10+ 彻底 DROP"
- v10 / v11 / v12 / v13 / v14 / v15 / v17 / v18 8 次 schema 升级**全没 DROP**
- 旧 vent 数据文字+加密双份存在 DB, 占空间 + 攻击面
- v15+ vent_repo 应该 throw "读 contentText (非 enc)" 守门, 实际是 `// 代码层不再用` 注释, drift row 还能 select

#### 反模式 3: mapper 1 个文件 1 mapper 模式 OK, 但 contact_mapper 跟 consent_artifact 不联动
- `lib/core/data/database/mappers/contact/contact_mapper.dart` 4 个新 consent 字段 (R27 round 63) + ConsentArtifact (R68 CC-1)
- mapper 跟 ConsentArtifact 是双向翻译, 缺单测覆盖 PIPL §13 同意 → DB 字段

#### 反模式 4: 隐式排序依赖
- 5 个 service 修过 (R16 round 19/19B): `streak_calculator` / `assessment_comparison` / `reminder_scheduler` / `safety_watch_service` / `assessment_reminder_service` — 修了但没 regression test fixture
- `test/data/sort_assumption_round19b_test.dart` 1 个 test, 5 service 修过但只 1 个 test fixture

### 8.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/core/data/database/app_database.dart:79-90 + 表 vent_entries | v8→v9 旧 contentText TEXT 列 v10-v18 8 次升级没 DROP | 架构 | 3 | P1 |
| 2 | lib/core/data/database/app_database.dart:111-115 | v15→v17 跳变注释, 未来 v16 中间 schema 风险 | 架构 | 2 | P2 |
| 3 | lib/core/data/database/mappers/contact/contact_mapper.dart | 跟 ConsentArtifact 双向翻译无单测, PIPL §13 关键路径 | 底层 | 2 | P1 |
| 4 | lib/core/data/database/mappers/vent/vent_mapper.dart | 老 contentText 列读路径没 throw, 守门靠注释 | 底层 | 1 | P1 |
| 5 | lib/core/data/database/daos/vent_dao.dart | select(contentText) 仍可能 read, 应 throw | 底层 | 1 | P1 |
| 6 | lib/core/data/services/database_migration.dart:103-219 | v8→v9 一次性加密单条失败 swallowError 没 metrics 报告 | 底层 | 2 | P2 |
| 7 | lib/core/data/database/connection/native.dart + web.dart | web / native 平台 switch, 但 web 测试基本 0 覆盖 (drift_web_support R45 引入) | 底层 | 3 | P2 |
| 8 | 11 DAO | 6 R91 DAO (sleep / social_rhythm / stress_event / treatment / weight / anxiety_agitation) 0 直接 DAO test, 走 widget test 间接覆盖 | 底层 | 2 | P2 |
| 9 | test/data/sort_assumption_round19b_test.dart | 1 fixture, 5 service 修过 | 底层 | 1 | P2 |
| 10 | lib/core/data/database/daos/check_in_dao.dart | 跨 10 type IN list (R91 fix C4), 0 direct test 之前漏掉 (R90 task 3 时) | 底层 | 1 | P0 (已修) |

### 8.3 修复路线

1. **P1**: vent 旧 contentText TEXT 列 DROP — 写 v18→v19 migration + 数据清理 + 升级前备份提示
2. **P1**: vent_mapper / vent_dao 加 throw "deprecated contentText" 守门
3. **P1**: contact_mapper + ConsentArtifact 双向翻译单测, PIPL §13 关键路径
4. **P2**: schemaVersion 跳变模式统一 (禁止 v15→v17 这种跳变, 必须 v15→v16→v17)
5. **P2**: 6 R91 DAO 直接 test, 跟 5 老 DAO 风格一致
6. **P2**: database_migration 加 metrics 报告 (X/Y 条 vent 加密成功, 单条失败 N 条)

---

## 9. 4-Layer Architecture + Cross-Layer (4 层架构 + 跨层)

### 9.1 整体评价

**水位: 9 / 10** — 4 层架构纯度 100% 守住 (check_all.dart), 跨 feature import 边界守住 (check_cross_feature.py), 但有 2 处架构 trade-off 已知豁免。

**正向证据**:
- **`check_all.dart` 2 报告 (纯度 + 一致性)**: 0 violation
  - domain/ 0 flutter / 0 drift / 0 data / 0 presentation / 0 l10n
  - shared/ 0 flutter / 0 drift / 0 data / 0 presentation
  - data/ 不依赖 presentation/
  - 守门员覆盖 4 层 + package 绝对路径 + ../../ 相对路径
  - 顺手: l10n 守门 (R77 加, 防 domain 间接 import Flutter via l10n)
- **`check_cross_feature.py`**: presentation/pages/{feature A}/ 禁止 import presentation/pages/{feature B}/, 0 violation
- **7 spec 5 步走**: domain entity + abstract repo → data table + mapper + impl → schema 升级 → presentation page + provider + route → test + validate
- **mapper 模式全 7 个** (vent / mood / check_in / contact / medication / user_profile / report_history) 双向覆盖
- **11 repository abstract + 11 impl** 1:1 配对

**反向证据**:

#### 反模式 1: 2 处架构 trade-off 已知豁免
- **`app_router.dart:20-23`**: "core/routing/ 位于 core/ 但 import presentation/pages/, 是 go_router 固有限制, 接受 trade-off, 已在 AGENTS.md 架构检查中豁免" — 这是**必须的**, 但**没自动化豁免**, check_all.dart 跑会报 0 (因为 check_all.dart 不扫 core/routing/ 内部, 写到 _purityRules[layer] 是 domain/shared/data/presentation 4 个, 没 core)
- **`service_providers.dart` 5 个 provider**: `reminderServiceProvider` / `safetyWatchServiceProvider` / `assessmentReminderServiceProvider` / `dataExportServiceProvider` — 这些是"业务服务", 不是 repository, 但放在 `presentation/providers/`, 因为它们依赖 4 层都不该出现的 facade (smsService + notificationService 同时 service), 跟 4 层架构有冲突, AGENTS.md 接受了

#### 反模式 2: `core/data/services/` 14 个 service 单文件
- `notification_service.dart` 18,392 字节 (~580 行) 是 1 个, `safety_watch_service.dart` 17,906 字节 (~540 行) 1 个
- 跟 `core/data/repositories/` 已按 feature 子目录拆 (e.g. `mood/`, `check_in/`, `daily_tracking/`) 不一致

#### 反模式 3: 11 DAO 跟 11 table 不严格 1:1
- `moodDao` / `ventDao` / `checkInDao` / `medicationDao` / `contactDao` / `userProfileDao` / `reportDao` / `assessmentDao` 8 个老 DAO
- R91 `sleepDao` / `socialRhythmDao` / `stressEventDao` / `treatmentDao` / `weightDao` / `anxietyAgitationDao` 6 个新 DAO
- `assessmentDao` 1 个跨 4 字段 (R90 task 3 实施, 依赖 CheckInDao + CheckIns 表),**DAO 1:N table 模式**, OK 但需在 AGENTS.md 注明

### 9.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/core/routing/app_router.dart:20-23 | 豁免是必须的, 但缺自动化豁免机制 (check_all.dart 不扫 core/routing/) | 底层 | 1 | P2 |
| 2 | lib/core/data/services/notification_service.dart | 18,392 字节单文件, 跟 repositories/ 已按 feature 拆不一致 | 架构 | 4 | P2 |
| 3 | lib/core/data/services/safety_watch_service.dart | 17,906 字节单文件, 同上 | 架构 | 4 | P2 |
| 4 | lib/core/data/services/sms_service.dart | 13,411 字节单文件, 同上 | 架构 | 3 | P3 |
| 5 | lib/core/data/services/email_service.dart | 8,157 字节单文件, 同上 | 架构 | 2 | P3 |
| 6 | lib/presentation/providers/service_providers.dart | 5 个业务 service provider 放 presentation, 4 层架构 trade-off 已知豁免 | 架构 | 3 | P3 |
| 7 | lib/core/data/database/daos/assessment_dao.dart | 1 DAO 跨 4 字段, 跟 11 table 1:1 DAO 模式不一致 | 架构 | 2 | P3 |
| 8 | check_all.dart | 守门员扫描 layer 是 domain/shared/data/presentation 4 个, **没扫 core/ 顶层** (routing / theme / l10n), 这些目录没被纯度守门 | 底层 | 1 | P2 |
| 9 | check_all.dart | consistency 检查只验 entity↔table, 没验 abstract repo↔impl | 底层 | 1 | P2 |

### 9.3 修复路线

1. **P2**: check_all.dart 加 core/routing/ / core/theme/ / core/l10n/ 扫, 任何 3 目录内 import presentation/ 立即 fail
2. **P2**: check_all.dart consistency 验 11 abstract repo ↔ 11 impl 1:1
3. **P2**: `notification_service.dart` 拆 2-3 个 facade (id_allocator / schedule_pipeline / presentation_adapter)
4. **P2**: `safety_watch_service.dart` 拆 (detector / dispatcher / config — 后 2 个已存在 R65)
5. **P3**: AGENTS.md 补 "业务 service 放 presentation 豁免" 章节, 跟 routing 豁免并列
6. **P3**: 1 DAO 跨 4 字段模式在 AGENTS.md 注明

---

## 10. Privacy Boundary (隐私边界)

### 10.1 整体评价

**水位: 9 / 10** — 树洞 vent 完全独立, 没漏进趋势 / 评估 / 通知, 8 个隐私守门员 (PIPL §13/§14 + mood 跟 vent 联动避免), 但有 2 个小细节待补。

**正向证据**:
- **vent 实体 grep 验证**: `domain/entities/vent_entry_entity.dart` + `repositories/vent_repository.dart` + `database/tables/vent/vent_entries.dart` + `database/mappers/vent/vent_mapper.dart` + `database/daos/vent_dao.dart` + `repositories/vent/vent_repository_impl.dart` + `providers/vent_providers.dart` + `pages/vent/*` — 全部路径独立
- **vent 没进 day_detail**: `lib/domain/logic/day_detail.dart` 5 个 DayEventKind (checkInNormal / checkInTemp / mood / assessment / ?) **没 vent**, R76 全修 + R91 fix
- **vent 没进趋势 / 评估 / CareEngine / SafetyWatch / 通知**:
  - `care_engine.dart:53` 只调 `notificationService.showNow`, 不读 vent
  - `safety_watch_service.dart` 457 行 0 vent 引用
  - `assessment_dao.dart` / `streak_calculator.dart` / `mood_period_aggregator.dart` 全 0 vent 引用
- **vent 文字加密**: `app_database.dart:185-218` v8→v9 一次性加密历史, 单条失败 swallowError
- **vent audio 不导出**: `data_export_service.dart:28` "vent audio: **不导出文件** (跨设备路径失效), 只导 metadata 引用"
- **mood audio 独立 storage**: `mood_audio_storage.dart:14` "**P0-2 fix 复用 vent 的教训**: 必须每个 storage 实例独立,不能跨隐私模块共享"
- **`check_legal_consent.py` 守门员** PIPL §13/§14 单独同意 + contact_consent 4 字段全覆盖
- **R82 法务 Q7b** `vent_repository.dart:54` "PIPL §47 删除权: 撤回 vent 同意时, 用户选'立即删除'走此路径"

**反向证据**:

#### 反模式 1: 误 grep 命中 (但实际无)
- `lib/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart` 含 "vent" (in "event"), grep `\bvent\b` 0 命中
- `lib/presentation/providers/daily_tracking_providers.dart` 含 "vent" (in "event"), 同上 0 命中
- **真 vent 独立守住了**

#### 反模式 2: vent 旧 contentText TEXT 列没 DROP (P0 攻击面)
- 跟 #8 反模式 2 重复, 列出在 Database
- 但隐私角度: 旧 vent 数据明文 + 加密双份存在 DB, **如果 backup 偷走 / device root 取出** 旧明文被读 → PIPL §28 数据泄露

#### 反模式 3: `vent_text_encryption_key_v1` 跟 mood audio encryption 复用?
- `lib/core/data/services/encryption_service.dart:29` `static const _keyName = 'vent_audio_encryption_key_v1'`
- mood audio 也用 EncryptionService, 走 `flutter_secure_storage` 同 key
- **没 grep 到独立 key**, 风险: vent 撤回同意时, mood audio 加密 key 仍可用

### 10.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/core/data/database/tables/vent/vent_entries.dart | 旧 contentText TEXT 列没 DROP, 攻击面 | 架构 | 3 | P0 |
| 2 | lib/core/data/services/encryption_service.dart | vent audio 跟 mood audio 加密 key 复用, PIPL §28 风险 | 架构 | 2 | P1 |
| 3 | lib/core/data/services/encryption_service.dart | vent 文字加密 key (DB-level BLOB) 跟 audio 加密 key 同源? | 底层 | 1 | P1 |
| 4 | lib/presentation/providers/vent_providers.dart | vent 撤回同意时, 内存中 audio player 缓存没清 | 底层 | 2 | P1 |
| 5 | check_legal_consent.py | 验 contact_consent 4 字段, **没验 vent_consent 4 字段** (因为 vent 还没 consent 流程, R82 留接口) | 底层 | 1 | P2 |
| 6 | lib/core/data/services/vent_audio_storage.dart:74 | `String get debugTag => 'vent_audio_storage'` 是 debug only, release 模式应确保 key 不 leak | 底层 | 1 | P2 |
| 7 | lib/presentation/pages/vent/vent_detail_page.dart:100 | `setState(() => _isPlaying = true)` 在 `context.mounted` check 后, 旧 `_tempDecryptedPath` 在 release 模式可能残留 | 底层 | 2 | P2 |

### 10.3 修复路线

1. **P0**: vent 旧 contentText TEXT 列 DROP (同上 Database #1)
2. **P1**: 拆 `EncryptionService` 3 个 key (ventText / ventAudio / moodAudio), 各自独立, 撤回同意独立失效
3. **P1**: vent_providers 撤回同意时, 清 audio player 缓存 + temp file + Stream
4. **P2**: check_legal_consent.py 加 vent_consent 4 字段验 (跟 R82 留接口对齐)
5. **P2**: vent_audio_storage debugTag 在 release 模式走 `assert(() { ... return true; }())`

---

## 11. Resources / Performance (资源 / 性能)

### 11.1 整体评价

**水位: 8 / 10** — Stream subscription + dispose + temp file + DateTime race 4 类都重点防过, 16KB alignment 守门员, 但仍有 3 个细节。

**正向证据**:
- **`check_widget_dispose.py` 守门员** 启发式验 dispose 资源释放
- **4 audio widget 全 dispose**: vent_detail_page 3 sub 字段 + cancel + _player.dispose + temp file cleanup / vent_compose_page 1 sub 字段 + 1 cancel / mood_audio_section 1 sub 字段 / mood_recorder_page 1 sub 字段
- **5 stream subscription 跟踪**: vent_detail_page 3 + vent_compose_page 1 + mood_audio_section 1 = 5 sub 字段, 全部 dispose cancel
- **DateTime.now() race** 守门员 `check_datetime_race.py` + `check_datetime_race2.py` 2 个版本
- **`check_no_hardcoded_utc.py`** 防 UTC 硬编码
- **`check_16kb_alignment.py`** Google Play 2025-11 强制 16KB
- **跨 midnight streak 刷新** (R17 round 4): `AppRoot` 挂 midnight timer, `nextMidnightRefresh()` 跨月/跨年正确, 5s buffer 防 race
- **Notification id cancel range 200000** 公式 (R19B 修前 1000/100000 太窄)
- **StreamProvider.autoDispose** 12 个 provider (R17 改): ventEntriesProvider + 6 R91 dailyTrackingProvider + 5 老 = 12 个, 离开页面自动 cancel

**反向证据**:

#### 反模式 1: 20 个 StatefulWidget 没 dispose (grep 启发式, 可能误报)
- `lib/presentation/widgets/press_feedback.dart` (`_PressFeedbackState extends State<PressFeedback>`)
- `lib/presentation/widgets/last_startup_error_banner.dart` (`_LastStartupErrorBannerState extends State<LastStartupErrorBanner>`)
- `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart` (`_DailyTrackingMultiChartState extends State<...>`)
- `lib/presentation/widgets/charts/assessment_multi_line_chart.dart`
- 16 个其他 widget
- 启发式 grep 不准, 部分是 ConsumerState (Riverpod 自动管), 实际无资源 leak

#### 反模式 2: Timer 用法分散
- `lib/core/data/services/reminder_scheduler.dart` 复杂 Timer 逻辑, 0 test
- `lib/presentation/pages/vent/vent_compose_page.dart` 录音 60s 限制 Timer, 0 test
- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` 同上

#### 反模式 3: `DateTime.now()` 多次调用
- `lib/main.dart` 启动顺序 6 步, 步骤 4 migration 用 `final now = DateTime.now()` 1 次, OK
- 但 `lib/presentation/pages/home/home_page.dart` 主页多次 `DateTime.now()` in build (streak + mood 卡片), 跨 midnight 跨 widget rebuild 可能 race
- `lib/core/data/services/notification_service.dart` schedule 算 next trigger time, 多次 `DateTime.now()` 在 scheduleDailyReminder / scheduleRefillReminder / snooze

### 11.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | lib/presentation/pages/home/home_page.dart | 主页多次 `DateTime.now()` 在 build, 跨 midnight race | 底层 | 2 | P1 |
| 2 | lib/core/data/services/notification_service.dart | scheduleDailyReminder / scheduleRefillReminder 多次 `DateTime.now()`, 跨 midnight race | 底层 | 2 | P1 |
| 3 | lib/core/data/services/reminder_scheduler.dart | 复杂 Timer 逻辑, 0 test, dispose 模式不统一 | 底层 | 3 | P1 |
| 4 | lib/presentation/pages/vent/vent_compose_page.dart | 录音 60s 限制 Timer, 0 test, dispose 模式不统一 | 底层 | 2 | P2 |
| 5 | lib/presentation/widgets/press_feedback.dart | 20 个 StatefulWidget 没 dispose (启发式), 实际需逐个 review | 底层 | 3 | P2 |
| 6 | lib/core/data/services/store_kit_service.dart | 0 test, `kDebugMode` 6x, 资源模式不透明 | 底层 | 2 | P2 |
| 7 | lib/core/data/services/mood_audio_service.dart | 377 行, dispose + cleanup 路径没 widget test | 底层 | 2 | P2 |
| 8 | lib/presentation/providers/mood_list_filter_provider.dart | filter `autoDispose` 跨 widget rebuild 重算, 1 widget test 验 | 底层 | 1 | P3 |
| 9 | check_widget_dispose.py | 启发式 grep, 部分 ConsumerState 误报, 规则需细化 | 底层 | 1 | P3 |

### 11.3 修复路线

1. **P1**: `home_page.dart` build 入口 `final now = DateTime.now();` 1 次, 后续复用
2. **P1**: `notification_service.dart` scheduleDailyReminder 入口 1 次 now
3. **P1**: `reminder_scheduler.dart` 写 dispose 模式 unit test
4. **P2**: 20 个 StatefulWidget 逐个 review 实际资源持有, 启发式改用 AST (dartanalyzer)
5. **P2**: 录音 Timer 抽 `RecordingTimer` 抽象, vent + mood 共享
6. **P3**: check_widget_dispose.py 细化规则 (ConsumerState 自动管不算)

---

## 12. Test Infrastructure (测试基础设施)

### 12.1 整体评价

**水位: 8 / 10** — ProviderScope override + in-memory DB + AppDatabase.forTesting 模式稳, Material 3 ink_sparkle shader trick 在, 但 golden / integration / 性能测试 0 覆盖。

**正向证据**:
- **AppDatabase.forTesting** (visibleForTesting): `app_database.dart:69` `@visibleForTesting AppDatabase.forTesting(super.executor);` — 接受 NativeDatabase.memory() / web
- **ProviderScope override 模式**: 33 个 provider override (main.dart + 14 widget test), `sharedPreferencesProvider.overrideWithValue(sharedPrefs)` 等
- **ink_sparkle shader trick 在**: `pubspec.yaml:84-85` `shaders: - assets/shaders/ink_sparkle.frag` + `assets/shaders/ink_sparkle.frag` 3978 bytes, Material 3 InkWell widget test work
- **`app_zh.arb` head: 928 → cur: 1000** (R88 known regression 守门)
- **flutter pub get 触发生成 4 dart file** (l10n) 0 keys 丢失
- **in-memory DB 测试**: `mood_cbt_roundtrip_round84_test.dart` `setUp(() { db = AppDatabase.forTesting(NativeDatabase.memory()); })` 模式标准

**反向证据**:

#### 反模式 1: golden test 0 覆盖
- 8 个 widget (home / mood_dialog / assessment / vent_compose / etc) 全 widget test 跑 `pumpAndSettle` + `find.text()`, **0 golden test**
- Material 3 theme 变 / dark mode 切换 / font scale 改, 0 视觉回归保护

#### 反模式 2: 性能 / 压测 0 覆盖
- 1 year+ 用户 check_in (365+ 行) 全表扫没 perf test
- fl_chart 多线趋势图 (R90 12 量表) 大数据渲染没 perf test

#### 反模式 3: integration test 1 个
- `test/integration/cbt_thought_record_flow_round84_test.dart` 1 个 (10,983 bytes)
- 端到端 setup → check-in → mood → vent 全流程 0 覆盖

#### 反模式 4: web 平台测试 0
- 1 个 web 测试 (`test/widget_test.dart`?), 跟 drift web 模式有关
- `lib/core/data/database/connection/web.dart` 跟 native 切换, web SQLCipher 行为 0 单测

### 12.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | test/integration/ | 1 个 integration test (R84), 8 sub-spec 后没新加 | 架构 | 4 | P2 |
| 2 | test/widget_test.dart | 1 个文件, 0 golden / 0 visual regression | 底层 | 3 | P2 |
| 3 | 全项目 | 0 performance / load test, 1 year+ 数据全表扫风险 | 底层 | 3 | P2 |
| 4 | 全项目 | 0 web platform test, drift web 模式 0 单测 | 底层 | 3 | P2 |
| 5 | lib/core/data/database/connection/web.dart | 跟 native 切换逻辑, 0 test | 底层 | 2 | P2 |
| 6 | lib/core/data/services/store_kit_service.dart | 0 test (IAP 集成关键路径) | 底层 | 2 | P1 |
| 7 | lib/core/data/services/preset_medication_templates.dart | 0 test, 8 默认模板 | 底层 | 1 | P2 |
| 8 | test/scripts/check_all_round18_test.dart | 1 个 test 验 check_all.dart, 但 15 guard 都没 self-test | 底层 | 2 | P2 |

### 12.3 修复路线

1. **P1**: `store_kit_service` 写 facade test (IAP integration 关键路径)
2. **P2**: 加 `test/integration/setup_to_check_in_round91_test.dart` 端到端
3. **P2**: 加 `test/golden/home_page_round91_test.dart` golden test (用 flutter_test goldenFileComparator)
4. **P2**: 加 `test/perf/check_in_365_days_test.dart` 1 年数据查询 perf baseline
5. **P2**: 加 `test/core/data/database/connection_web_test.dart` web 平台 SQLCipher 行为
6. **P2**: 15 guard 各加 self-test (`test/scripts/check_*_test.py`)
7. **P3**: 写 `test/utils/test_helpers.dart` 集中 ProviderScope override 模板

---

## 13. 16 守门员脚本 (Guard Scripts)

### 13.1 整体评价

**水位: 9 / 10** — 16 守门员 1:1 对应 superpowers 14 子技能 + 项目特定需求, 全部跟 `flutter analyze` + `flutter test` 串, 但有 3 守门员规则过宽, 缺 self-test。

**正向证据**:
- **16 守门员覆盖范围**:
  1. `check_arb_keys.py` (5298 bytes) - zh / en / zh_Hant 同步
  2. `check_changelog.py` (3074) - pubspec + CHANGELOG 顺序
  3. `check_cross_feature.py` (5252) - 跨 feature import
  4. `check_datetime_race.py` (1961) - `DateTime.now()` 多次调用
  5. `check_datetime_race2.py` (3168) - `DateTime(year,month,day)` 多次调用
  6. `check_drift_namespace.py` (2401) - `@DataClassName` 唯一
  7. `check_fullwidth_punctuation.py` (5330) - 全角标点 (warn-only)
  8. `check_no_hardcoded_utc.py` (3614) - UTC 硬编码
  9. `check_no_pua.py` (3486) - PUA 字符
  10. `check_widget_dispose.py` (4716) - 资源泄漏
  11. `check_orphan_arb_keys.py` (4520) - R56e 新 - ARB key 未引用
  12. `check_legal_consent.py` (3723) - R57 新 - PIPL §13/§14 单独同意
  13. `check_sms_release_ready.py` (6865) - R57 新, R58 降 warn-only
  14. `check_strings_hardcoded.py` (5387) - R57 新 - 硬编码中文
  15. `check_zh_hant_consistency.py` (4690) - R57 新 - 繁简一致性
  16. `check_all.dart` (14696) - 4 层架构纯度 + 一致性
  17. `check_16kb_alignment.py` (4921) - 17 个, 16KB page size

**反向证据**:

#### 反模式 1: 3 守门员规则过宽, 漏命中
- `check_strings_hardcoded.py` 允许 `Text('...')` 字面中文, 14 文件 45 处漏 (#7 列出)
- `check_sms_release_ready.py` R58 降 warn-only, **R91 还没升回 hard fail** (v1.0 前必修)
- `check_fullwidth_punctuation.py` 是 warn-only (合理, 是 editor preference, 不该 fail)

#### 反模式 2: 0 self-test
- 16 守门员 0 self-test (`test/scripts/check_*_test.py` 仅 2 个: `check_cross_feature_test.py` + `check_drift_namespace_test.py`)
- 改 1 个守门员规则, 跑 CI 通过, 实际没拦 bug, 没法验

#### 反模式 3: 缺新增守门员
- **缺 a11y / 语义守门员** — `app_semantics.dart` 14 个 widget 用, 但 0 守门员验 `Semantics(label: ...)` 是否覆盖
- **缺 SQL N+1 守门员** — DAO watchAll / getAll 跨表 query 没守门, 容易 N+1
- **缺 print() 守门员** — release 模式应禁 print, 当前 0 守门
- **缺 debugPrint / developer.log 守门员** — release 应走 piiSafeLog
- **缺 字符串 placeholder 守门员** — `// TODO` / `// FIXME` / `// XXX` 散落
- **缺 pubspec dependency 守门员** — `sqlcipher_flutter_libs: ^0.6.5` ^ 范围允许自动升, 0 守门员锁版本

### 13.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | scripts/check_sms_release_ready.py | R58 降 warn-only, v1.0 前必修升 hard fail | 底层 | 1 | P0 |
| 2 | scripts/check_strings_hardcoded.py | 规则过宽, 14 文件 45 处漏命中 | 底层 | 1 | P1 |
| 3 | scripts/check_cross_feature.py | 仅 1 self-test (`test/scripts/check_cross_feature_test.py`) | 底层 | 1 | P2 |
| 4 | scripts/check_drift_namespace.py | 仅 1 self-test | 底层 | 1 | P2 |
| 5 | 14 守门员 | 0 self-test (`test/scripts/`) | 底层 | 1 | P2 |
| 6 | 全项目 | 缺 a11y 守门员 | 底层 | 2 | P2 |
| 7 | 全项目 | 缺 SQL N+1 守门员 | 底层 | 3 | P2 |
| 8 | 全项目 | 缺 print / debugPrint 守门员 | 底层 | 1 | P2 |
| 9 | 全项目 | 缺 pubspec dependency 锁版本守门员 | 底层 | 1 | P1 |
| 10 | 全项目 | 缺 TODO 守门员 (lib/ 散落 14 处 TODO, 16+ 注释提 TODO) | 底层 | 1 | P3 |
| 11 | scripts/check_16kb_alignment.py | 17 个守门员, AGENTS.md 只列 16, 命名不一致 | 底层 | 1 | P3 |
| 12 | scripts/_archive/ | 备份老脚本, 应清 | 底层 | 1 | P3 |

### 13.3 修复路线

1. **P0**: `check_sms_release_ready.py` v1.0 前升 hard fail (`return 1` 改 `return 0`)
2. **P1**: `check_strings_hardcoded.py` 规则加严, 任何 `Text('...')` 含中文字符立即 fail (绕过 14 文件 45 处)
3. **P1**: pubspec 锁版本 — 加 `.env.example` 守门员, `pubspec.lock` 锁关键 plugin
4. **P2**: 14 守门员各加 self-test (`test/scripts/check_*_test.py`)
5. **P2**: 写 `check_a11y.py` + `check_sql_n_plus_1.py` + `check_no_print.py` 3 个新守门员
6. **P3**: 写 `check_no_todo.py` lib/ 散落 TODO 跟踪

---

## 14. Docs & CHANGELOG (文档 / CHANGELOG)

### 14.1 整体评价

**水位: 8.5 / 10** — Keep a Changelog 格式 OK, pubspec 同步 OK, 4 个 versions 全有 entry, 但 R84-R91 8 sub-spec 缺统一 "Sub-spec Implementation" 分章。

**正向证据**:
- **`docs/CHANGELOG.md` Keep a Changelog 格式**:
  - 链接 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) ✓
  - `### Added` 33 处, `### Fixed` 22 处, `### Changed` 13 处, `### Removed` 2 处 — 4 章节全
  - 4 个 versions: 0.25.0 / 0.27.0 / 0.29.0 / 0.30.0 (R49 / R61-R62 / R73 / R84-R91)
  - 版本号 0.30.0 在 pubspec.yaml 一致 (`pubspec.yaml:5` `version: 0.30.0+85`)
  - 日期 2026-08-05 全有
- **`pubspec.yaml:5` version 0.30.0+85** 跟 CHANGELOG 同步
- **每 round 都有 CHANGELOG entry** (R49 / R61 / R62 / R73 / R84 / R85 / R86 / R87 / R88 / R90 / R91, 11 个 round 在 CHANGELOG)
- **R88 CHANGELOG R88 entry + 繁简一致性** 是 R56e R60 R90 复用守门员
- **`docs/CHINESE_COMMIT_GUIDE.md` + `docs/GIT_WORKFLOW.md` + `docs/DEPLOYMENT.md` + `docs/PUSH_PROVIDERS.md` + `docs/SMS_PROVIDERS.md` + `docs/SENDGRID_SETUP.md` + `docs/STOREFRONT_RELEASE_SOP.md`** 7 文档齐全

**反向证据**:

#### 反模式 1: 12 个 round 缺 CHANGELOG entry
- R3 / R4 / R6 / R9 / R10 / R11 / R12 / R13 / R14 / R16 / R17 / R18 / R19 / R20 / R31 / R34 / R37 / R38 / R39 / R43 / R45 / R48 / R60 / R63 / R64 / R65 / R66 / R67 / R77 / R78 / R80 / R81 / R82 / R83 34 个 round
- 实际 CHANGELOG 只有 11 个 round entry
- **23 个 round 0 entry** (R3-R83 大半)
- 早期 R3-R18 累计 30+ round 全是 v0.25.0 (一个版本, 一个 entry 概括)
- R20 / R31 / R34 / R37 / R38 / R39 / R43 / R45 / R48 / R60 / R63 / R64 / R65 / R66 / R67 / R77 / R78 / R80 / R81 / R82 / R83 21 round 跨 v0.27.0 / v0.29.0 / v0.30.0, 但全合并到 1 个版本 entry, 实际改动 = 21 round × 1-5 commit

#### 反模式 2: 缺 round 标签
- CHANGELOG 标题 `[0.30.0] - 2026-08-05 (R91 — ...)` 含 R91, 但 [0.30.0] 段 5+ entry 全是 R91, 缺 R84-R90 单独 entry
- 用户 review 时看不到 "R88 修了什么", 必须 git log 反查

#### 反模式 3: 7 spec + 7 plan 在 `docs/superpowers/`, 散在 `docs/superpowers/specs/2026-MM-DD-XXX-design.md` + `plans/2026-MM-DD-XXX.md`, 0 README 索引
- 新进开发者不知道 "CBT 思维记录 sub-spec 怎么设计" 入口在哪
- 缺 `docs/superpowers/README.md` 总索引

#### 反模式 4: 7 audit (R66 / R67 / R68 / R69 / R74 / R76) 在 `reports/audit/`, 跟 R90 之后的 SDD 模式不接
- `reports/audit/round76-superpowers-en.md` 50K, 跟 `docs/audit/2026-08-06/01-emilkowalski-design-report.md` 模板不同
- R78+ 没 audit, 改 sdd-logs/task-N-review-report.md 替代
- audit 文档分类混乱: 早期 (R66-R76) 在 `reports/audit/`, 后期 (R90+) 在 `docs/superpowers/sdd-logs/roundXX/sdd/`

### 14.2 问题清单

| # | 文件:行 | 问题 | 类型 | 难度 | 优先级 |
|---|---------|------|------|------|--------|
| 1 | docs/CHANGELOG.md | R84-R88 / R90 单独 round 缺 entry, 合并到 [0.30.0] | 底层 | 1 | P2 |
| 2 | docs/CHANGELOG.md | R3-R83 23 round 0 entry, 早期 v0.25.0 / v0.27.0 / v0.29.0 1 entry 概括 | 底层 | 1 | P3 |
| 3 | docs/superpowers/ | 0 README 索引, 新进开发者找 spec/plan 入口 | 底层 | 1 | P2 |
| 4 | docs/audit/2026-08-06/ | 跟 `reports/audit/` 不一, 路径混乱 | 底层 | 1 | P3 |
| 5 | reports/audit/round66-76-superpowers-en.md | 6 个早期审计, 跟 R90+ sdd-logs task-N-review-report.md 模式不接 | 底层 | 1 | P3 |
| 6 | docs/CHANGELOG.md | 缺 round 标签 — 当前 R91 有, 但 R84-R88 / R90 缺 | 底层 | 1 | P2 |
| 7 | docs/CHANGELOG.md | 缺 "Sub-spec Implementation" 章节, R84-R91 8 sub-spec 全 0 摘要 | 底层 | 1 | P2 |
| 8 | docs/superpowers/sdd-logs/ | 0 README 解释 sdd 流程 | 底层 | 1 | P3 |
| 9 | docs/CHANGELOG.md | Keep a Changelog 4 章 (Added/Fixed/Changed/Removed) OK, 但缺 `### Security` 章节 — vent 加密 / 联系人 consent 是 security-relevant | 底层 | 1 | P2 |
| 10 | docs/CHANGELOG.md | 没 release date / release 链接, 用户 review 时不能看 "v0.30.0 release commit" 链接 | 底层 | 1 | P3 |

### 14.3 修复路线

1. **P2**: 写 `docs/superpowers/README.md`, 7 spec 7 plan 入口
2. **P2**: CHANGELOG 补 "### Security" 章节, vent 加密 / contact consent / 安全相关
3. **P2**: CHANGELOG 每 round 单独 entry, [0.30.0] 段拆 R84 / R85 / R86 / R87 / R88 / R90 / R91
4. **P2**: 写 `docs/superpowers/sdd-logs/README.md` 解释 sdd 流程
5. **P3**: 整理 `reports/audit/` + `docs/audit/` 路径, R78+ 改 `docs/audit/<round>/` 统一

---

## 修复路线 (按 P0 → P3 排)

### P0 (上 App Store 前必修, 5 项)

1. **AliyunSmsProvider.send() 真接阿里云 + 升 check_sms_release_ready 硬 fail**
   - 文件: `lib/core/data/services/sms_service.dart` + `scripts/check_sms_release_ready.py`
   - 风险: release 模式 "假成功", 失联通知不送达
   - 外部依赖: 法务模板审核 1-2 月 + 阿里云 AccessKey 申请
   - 启用 `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled`

2. **vent 旧 `contentText` TEXT 列 DROP (schemaVersion 18→19)**
   - 文件: `lib/core/data/database/app_database.dart` + `lib/core/data/database/tables/vent/vent_entries.dart`
   - 风险: 旧 vent 数据明文 + 加密双份存在 DB, backup 偷走 / device root 取出 → PIPL §28 泄露
   - 升级提示用户重新加密 / 写 migration 一次性清理

3. **`assessment_center_page.dart:1` 硬编码中文 → 走 l10n.assessmentCenterTitle**
   - 文件: `lib/presentation/pages/assessment/assessment_center_page.dart`
   - l10n key 已存在, R91 task 7 漏改

4. **EmailService `isProductionReady` 写真接 test + mock 路径 0 覆盖补 test**
   - 文件: `lib/core/data/services/email_service.dart` + 新 test
   - 风险: release 模式 mock 静默, 邮件通知不送达

5. **R60 / R88 跨 round 兼容 regression test 加密**
   - `moodRepository.add 透传 8 CBT 字段` regression test
   - `data_export 漏 8 CBT 字段` regression test
   - `R60 JSON ↔ R90 reader keys` regression test
   - 防 P0 再次跨 N round 才暴露

### P1 (重要, 1 个月内修, 12 项)

6. 启动加 `_bootstrapHealthCheck` 步骤 7, 把 6 步的 try/catch 失败统一写 LastErrorCapture
7. safety_watch_service 失联检测窗口加 unit test (DST / 跨年 / 跨月 / 24h 边界)
8. 抽 `AudioController` 抽象, vent + mood 4 widget 共享
9. 14 文件 45 处硬编码中文 → 走 l10n key
10. `check_strings_hardcoded.py` 规则加严, 任何 `Text('...')` 含中文立即 fail
11. 3 处 `} catch (_) {` 改 `swallowError` 集中器
12. `mavis-trash .worktrees/feat-cbt-thought-report/`, `git worktree prune`
13. 拆 `notification_service.dart` ≥ 2 层 facade
14. 写 `safety_watch_service` R91 snapshot test
15. 写 `.github/workflows/ci.yml` (flutter test + analyze + 16 guards)
16. vent 跟 mood 加密 key 独立 (`EncryptionService` 拆 3 key)
17. `home_page.dart` build 入口 `final now = DateTime.now();` 1 次

### P2 (建议, 1 quarter 内修, 20+ 项)

18-37. 略 (汇总上述各章节 P2 项)

### P3 (nice-to-have, 长期)

38+. 略

---

## 半成品 / 残缺项

### 半成品 (有 TODO 注释, 缺实现)

- [ ] **lib/presentation/pages/assessment/assessment_center_page.dart:65**: `// TODO (Task 5): 顶部 mini 趋势图` 空 SizedBox 占位 (R90)
- [ ] **lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart**: 兜底 widget, 不是真页面 (R91 临时)
- [ ] **lib/domain/logic/scale_registry.dart:5**: NSESSS / CRDPSS TODO (user 选 hybrid, 留 v0.31+ 临床咨询 + 用户自决)
- [ ] **lib/core/data/services/sms_service.dart:13**: TwilioSmsProvider (国际备份) v2.0+ TODO
- [ ] **lib/core/data/services/sms_service.dart:104**: `// R55 之后 TODO: 真 send() 不 throw UnimplementedError` — 同 P0 #1
- [ ] **lib/domain/entities/scale_translations.dart:17**: 16 题目全量 i18n 留 v1.0 (R65 改, 4 round 未跟)
- [ ] **lib/core/data/services/store_kit_service.dart**: 0 test, IAP 集成代码稳但缺 unit test
- [ ] **lib/presentation/widgets/home_fab_toolbar.dart**: "紧急热线" / "回到顶端" 2 个 FAB 工具是 stub snackbar
- [ ] **lib/core/data/services/medication_report_pdf_layout.dart**: 10,715 字节 layout, 0 test
- [ ] **lib/core/data/services/data_export_service.dart**: facade 110 行, 实际逻辑 export/ 4 子文件 ~800 行净增

### 残缺项 (commit 缺失 / 跟 R-Round 不一致)

- [ ] **.worktrees/feat-cbt-thought-report/**: R84 物理目录残留, branch 已删
- [ ] **.superpowers/sdd/**: R89 "Worktree 移除" 没回收主 .superpowers/sdd/
- [ ] **.r61_backup_20260731_101630/** (1.7MB) + **.r61_backup_logs/** (2.6MB): R61 backup 残 1.5 月
- [ ] **docs/superpowers/sdd-logs/round90-assessment-center/sdd/**: 17 .py + __pycache__/ + 17 .py.tmp 残留
- [ ] **test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled**: R57 写, 至今未启用
- [ ] **commit_msg_r56c3/r56d/r56e/r56g/r56h** + **.commit_msg_agents.md** + **.commit_msg.txt**: 6 个 commit message 临时文件, R56 阶段残留 (R78+ 没用这些)
- [ ] **mimo.exe (128MB)** 根目录残留, 不知何用
- [ ] **flutter_01.log (5KB)** 根目录残留
- [ ] **todo.md (723 bytes)** 根目录残留, 内容未知
- [ ] **chroniccare.iml (859 bytes)** IntelliJ 项目文件, 应该 .gitignore

### 配置 / 文档不接

- [ ] **pubspec.yaml version 0.30.0+85** vs **CHANGELOG 4 versions** (0.25.0 / 0.27.0 / 0.29.0 / 0.30.0) — OK 同步, 但 R49 / R61-R62 / R73 缺独立 round entry
- [ ] **CHANGELOG R84-R88 / R90 缺单独 entry**, 全合并到 [0.30.0]
- [ ] **.github/** 目录存在但 0 CI workflow, 16 guard + flutter test 手动跑
- [ ] **AGENTS.md 列 16 守门员**, 实际 17 个 (`check_16kb_alignment.py`)
- [ ] **AGENTS.md 缺 "业务 service 放 presentation 豁免"** 章节 (跟 routing 豁免并列)

### Code Debt

- [ ] **3 个顶层 static workaround** (`_smsService` / `_emailService` / `AppDatabase` in main) — 1:1 重构成纯 Provider
- [ ] **14 文件 45 处硬编码中文** — R56+ R84+ review 漏
- [ ] **3 处 `} catch (_) {`** 残留 — R39 P1-10 修过, 但新代码 (R91 daily_tracking widget) 漏
- [ ] **20 个 StatefulWidget 启发式 grep 无 dispose** — 需逐个 review 实际资源持有
- [ ] **v8→v9 vent 旧 contentText 列 8 次升级没 DROP** — 攻击面
- [ ] **DataExportService 拆 5 子文件, facade 110 行 0 删** — 净 debt 增长

---

## 上架相关工程隐患

### App Store / Google Play 提审 blocker

1. **AliyunSmsProvider.send() 仍 throw UnimplementedError** — Apple 3.1.5 (a) + Google 数据安全声明要求 SMS 真接, 假成功上 store 后用户失联通知不达是 P0 监管风险
2. **check_sms_release_ready.py 仍 warn-only** — 上 store 前必修升 hard fail
3. **EmailService `isProductionReady` 真接路径 0 test** — 跟 SMS 平行
4. **store_kit_service 0 test** — IAP 集成关键路径
5. **vent 旧 `contentText` TEXT 列没 DROP** — PIPL §28 数据双份攻击面
6. **3 个顶层 static workaround** — release 模式 state 错位历史 (R62 P0-3 修过)
7. **runZonedGuarded 只 catch uncaught, 启动 try/catch 失败不 report** — 用户漏通知不知道
8. **`.r61_backup_20260731_101630/` + `.r61_backup_logs/`** 根目录残留 4.4MB — 影响 App Bundle 大小
9. **`mimo.exe` (128MB)** 根目录残留 — App Bundle 影响未知
10. **`chroniccare.iml` IntelliJ 项目文件** — App Bundle 影响未知

### 监管 / 合规风险

11. **14 文件 45 处硬编码中文** — PIPL §7 知情同意书需中英文双语, 漏改意味着 en / zh_Hant 用户看不懂
12. **v8→v9 vent 旧 contentText TEXT 列** — PIPL §28 数据双份
13. **vent 跟 mood 加密 key 复用** — 撤回同意独立失效风险, PIPL §47
14. **check_legal_consent.py 没验 vent_consent** — R82 留接口
15. **`home_hero_illustration` 渐变 alpha 0.08 → 0.04 几乎不可见** — 主页 UX 弱化品牌
16. **CBT wizard 5/7 栏"完成"按钮不触发 save** — 用户填的 CBT 思维记录会静默丢失 (P0 用户体验风险)
17. **`assessment_center_page` 顶部 mini 趋势图是 TODO SizedBox** — 中心化入口渲染空
18. **`home_fab_toolbar` 4 个 FAB 工具中 2 个是 stub snackbar** — `homeFabHotlineTodo` / `homeFabTopTodo`
19. **`treatment_placeholder` 是兜底 widget** — 不是真页面
20. **`home_hero_illustration` 渐变几乎不可见** — 主页 UX

### Performance / 稳定性 (1 year+ 用户)

21. **home_page.dart build 多次 DateTime.now()** — 跨 midnight race
22. **notification_service.dart schedule 多次 DateTime.now()** — 跨 midnight race
23. **reminder_scheduler.dart 0 test** — 复杂 Timer 逻辑无单测
24. **0 perf / load test** — 1 year+ 用户 check_in 全表扫风险
25. **0 web platform test** — drift web 模式 0 单测
26. **5 stream subscription 跟踪 OK, 但 0 perf 监控** — 长时间使用 memory leak 风险

### Test Coverage Gap (上架后修)

27. **205 test files / 1402 test() calls** — 11 个 service (notification / safety / email / sms / etc) 大半 0 test
28. **3 守门员规则过宽** (`check_strings_hardcoded` / `check_sms_release_ready` / `check_fullwidth_punctuation`) — 漏命中
29. **0 self-test for 14 守门员** — 改规则没法验
30. **0 golden / 0 visual regression** — theme 变没保护

---

## 结论

**项目工程水位 8.0/10**, 跟 AI 编程超能力社区 best practice 的差距在 5 个具体可修项:

1. **守门员规则加严** (3 处) + **新增守门员** (3 个: a11y / SQL N+1 / print) + **16 guard self-test** (16 个文件)
2. **5 必改 P0** (AliyunSmsProvider 真接 / vent 旧列 DROP / l10n 漏改 / EmailService 真接 test / 跨 round 兼容 regression)
3. **SDD 流程补完** (拆 cbt plan 80K / 写 spec/plan 模板 / R90 sdd-logs 清理 / 缺 decision log)
4. **4 层架构 + God class 收尾** (notification_service 拆 / safety_watch_service 拆 / service_providers 业务豁免入 AGENTS.md)
5. **测试基础设施补** (golden / integration / perf / web / service test / store_kit_service test)

**给 P0 必改的 5 件事 + 上架相关 20 项工程隐患** 已按 superpowers 14 子技能分类, 修复路线 P0→P3 排序, 难度 1-5 标注, 可在 1 quarter 内修完。

**跟 superpowers 社区真正的差距**:
- 守门员覆盖广 (16 个, 比社区常见 5-8 个多 1 倍)
- TDD 红绿循环可见 (R90 task 6 review "TDD red→green" 段落)
- SDD 流程完整 (spec → plan → task brief → task report → review report → fix round → merge → sdd-logs)
- 跨 round 兼容 regression test 主动捕获 (R60/R88/R90 4 个 P0)

**仍可学习社区**:
- brainstrom 阶段文档化 (当前 spec 头部 Open Questions 替代)
- peer review 痕迹 (`Co-authored-by:` 多人协作)
- design decision log (`docs/decisions/` 模板化)
- CI workflow (16 guard + flutter test 自动化)
- 加 3 个新守门员 (a11y / SQL N+1 / print)
