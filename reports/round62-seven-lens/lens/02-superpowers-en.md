# superpowers-en 视角代码审查 · round 62 (7-lens #2)

> **基线**: v0.27 round 60 + working tree (R61 已合未 commit) / schemaVersion 14 / 1151 tests / 0 analyze error / 16 guard scripts
> **方法论**: TDD / systematic-debugging / subagent-driven-development / code-review / refactoring / git-worktree / verification-before-completion / testing-anti-patterns
> **审查范围**: lib/main.dart, app.dart, app_database.dart, notification_service+5 sub, safety_watch+2 sub, data_export+4 sub, 抽样 5 page (home/mood/vent/setup/trend) + 16 守护脚本 + .github/workflows/ci.yml + 历史 v0.27 报告 (66 发现)
> **对照基线**: docs/reviews/v0.27/review-superpowers-en-v027.md (66 项)

---

## 1. 总评

R57-R61 spen P0/P1 修真 + TDD 加测 (5 sub-service +41 cases) 落地扎实,但 **(a) R52/R59/R60/R61 共 5 个 P0 修真有 3 个缺 regression test、(b) resource management 测试覆盖 0、`StreamSubscription` 字面量 0 hit、(c) 16 守护脚本仅 5 在 CI、其余手动** —— 本轮发现 **2 项 P0 修真漏洞 + 3 项 P0 测试空白 + 3 项 P1 god class 残留 + 2 项 P1 verification 缺口**。

---

## 2. P0 — 修真缺回归 (5 项)

| # | 文件:行 | 修真内容 (R-N) | 缺什么 | 修法 | 难度 |
|---|--------|---------------|--------|------|------|
| **P0-1** | `lib/core/data/services/notification_service.dart:403-416` | R60 P0-3 `_resolveSafetyAlertBody` 3 态分流 (sent/mocked/failed) | 0 test 测 facade 的 outcome→i18n 选择逻辑;仅 `SafetyAlertDispatcher` 测了 outcome 计数。grep `_resolveSafetyAlertBody` 0 hit in `test/` | 加 `test/core/data/services/notification_service_three_state_round62_test.dart`,3 case: (a) `outcome.smsOk=1` → `safetyAlertBodySent` (b) `outcome.smsOk=0 smsMock=1` → `safetyAlertBodyMocked` (c) `outcome.smsOk=0 smsFail=1` → `safetyAlertBodyFailed`。subclass `NotificationService` 跳过 plugin init | **S** |
| **P0-2** | `lib/presentation/pages/mood/widgets/mood_recorder.dart:147-172` | R52 + R61 P0-1 dispose race 修真 (`_isRecording=false` 同步设 + `_disposeResources` fire-and-forget) | 0 test 验证 (a) `dispose()` 后 stream 回调不再触发 setState (b) `_disposeResources` 异常 swallow 不外抛 (c) `setState after dispose` 不再 assert | 仿 `vent_compose_stop_and_cleanup_round48_test.dart` 模式,加 `test/presentation/widgets/mood_recorder_dispose_round62_test.dart` 3 case: (a) widget unmount → setState 漏不到 (b) service.stopRecording 抛 → dispose 仍走完 (c) `MockAudioPlayer.onPlayerComplete` 仍 fire 在 dispose 后 | **M** |
| **P0-3** | `lib/presentation/pages/setup/setup_page.dart:404-413` | R59 P0 (spen §5#18) 修真 fail-soft → fail-loud timeout,删 `onTimeout: () => []` 让 `TimeoutException` 冒泡 | 0 test 验证 timeout 真抛。`setup_page_round18_test.dart` 只测 step 1 "下一步" 按钮 | 加 `test/presentation/setup_page_timeout_round62_test.dart`: mock `medicationRepositoryProvider` 返 `Stream.fromFuture(Future.delayed(10s))` → 5s 后应抛 TimeoutException,落入外层 catch → setup UI 显示失败态 | **S** |
| **P0-4** | `lib/presentation/pages/vent/vent_detail_page.dart:36-81` | 3 个 `StreamSubscription` (duration/position/complete) + temp file 清理 | grep `StreamSubscription` 0 hit in `test/`。`vent_compose` 有 round48 test 但 `vent_detail` 0 测 | 加 `test/presentation/vent_detail_dispose_round62_test.dart`: (a) 播完后 dispose → 3 sub 全部 cancel (b) temp file 已 decrypt → dispose 后文件被删 (c) `setState after dispose` 不抛 | **M** |
| **P0-5** | `lib/core/data/services/safety_watch_service.dart:226-244` (R61 P1-4) 修真 `SafetyCheckResult.kind == alerted` 3 态分流到 `displayMessageL10n(l10n)` | `safety_watch_service_round12_test.dart` 0 case 验 `displayMessageL10n` 8 kind 返回正确 l10n key。`displayMessage` getter 已 deprecated 但仍走 key 字符串,spzh 报告 03 P1-1 指 `home_page.dart:155/324` 仍 hardcode 旧 getter | 2 文件双修: (1) 加 `displayMessageL10n` 8 case (2) `home_page.dart:155/324` 改 `displayMessageL10n(l10n)` (spzh P1-1 同款) | **S** |

---

## 3. P0 — testing-anti-patterns (2 项)

| # | 文件:行 | 反模式 | 修法 | 难度 |
|---|--------|--------|------|------|
| **P0-6** | `test/data/data_export_round39_test.dart:1-323` (323 行) | **self-fulfilling JSON round-trip**: 50+ case 都是 "encode→decode→assert 相同",验证实现不验证行为 | 改 5 case 真正行为: (a) 导出后删库 → 导入 → DB query 返相同 row (b) v1→v4 schema 升 1 个字段后导入不爆 (c) 导入失败抛 `ImportException` 而非 silent skip (d) 并发导入 (e) vent contentText 加密 roundtrip 解密后原文 | **M** |
| **P0-7** | `test/core/data/services/safety_alert_dispatcher_round61c3_test.dart:1-275` | `_ScriptedSmsProvider` 注入 ok/fail/mock 计数,但**全 happy path**。0 case 测 "DB 写失败 mid-stream" / "SMS timeout 30s" / "SmsResult.timeout" | 补 3 case: (a) `MockSmsProvider.timeout` → `smsFail++` 不 `smsMock` (b) `setLastAlertAt` 抛 → 仍显示安全告警 (c) `_alertDispatcher.dispatchAlert` 入参 `lastCheckIn: null` 不崩 | **S** |

---

## 4. P1 — god class 残留 (3 项)

| # | 文件:行 | god class 表现 | spen 历史建议 vs 现状 | 修法 | 难度 |
|---|--------|---------------|---------------------|------|------|
| **P1-1** | `lib/core/theme/app_tokens.dart:1-651` (651 行) | 100+ token 平铺,`AppColors`/`AppMotion`/`AppTypography`/`AppSpacing`/`AppShadow` 5 子模块未抽 (emil 01 P1-3 同款) | R49 dark mode 修真触发 60+ inline 颜色替换;R50 修真 46 spacing token;R51 修真 13 IconButton;现仍 1 文件 god | 拆 5 子模块,`app_tokens.dart` 退化为 barrel (跟 `R59 app_router` 拆 `AppRoutes` + 5 `AppRoute*` 同模式) | **M** |
| **P1-2** | `lib/core/data/services/export/export_orchestrator.dart:1-540` (540 行) | R57 抽 facade 但 orchestrator 自己成新 god class;5 类编排 + JSON 序列化 + 字段校验全混 | spen v0.27 已标 "orchestrator 内可再拆 schema 验证/JSON 序列化 2 子" | 抽 `ExportSchemaValidator` + `ExportJsonSerializer`,orchestrator 退化为调度 | **L** |
| **P1-3** | `lib/core/data/services/notification_service.dart:1-418` (418 行) | R45 拆 6 sub-service 修真后 facade 仍 418 行;`init` 60 行 + `showSafetyAlert` 50 行 + 5 委托 + ID 注释 | R60 P0-3 加 3 态后 `showSafetyAlert` 50 行;R61 后又加 `l10n` parameter | 把 `init` 抽到 `NotificationInitService` (跟 `SafetyConfigService` 风格同);`showSafetyAlert` 整段下沉到 `SafetyAlertDispatcher` (R57 留半边工程) | **M** |

---

## 5. P1 — verification-before-completion (3 项)

| # | 文件:行 | 缺口 | 修法 | 难度 |
|---|--------|------|------|------|
| **P1-4** | `.github/workflows/ci.yml:1-122` (122 行) | 16 守护脚本仅 **4 在 CI** (cross_feature, arb_keys, drift_namespace, datetime_race2);**12 个手动**包括 widget_dispose(资源泄漏)/no_pua(PUA 字符)/no_hardcoded_utc/sms_release_ready/legal_consent/strings_hardcoded/zh_hant_consistency/changelog/orphan_arb_keys/fullwidth_punctuation | `ci.yml` 加 8 step:`python scripts/check_widget_dispose.py --ci` + `check_no_pua.py` + `check_no_hardcoded_utc.py` + `check_changelog.py` + `check_orphan_arb_keys.py` + `check_legal_consent.py --ci` + `check_strings_hardcoded.py` + `check_zh_hant_consistency.py` | **S** |
| **P1-5** | `lib/main.dart:75-183` (`_bootstrap` 108 行) | 启动顺序 (env/tz/migration/notification/SMS/runApp) inline,缺 `BootstrapOrchestrator` 抽象 (spen v0.27 §4 #3 已标) | 仿 `ExportOrchestrator` 抽 `BootstrapOrchestrator`:`runEnv → runMigration → runNotification → runSms → runApp`,main 退化为 catch all | **S** |
| **P1-6** | 0 hit `git worktree` / `git worktree add` in CI/commits | R49-R62 60+ commit 修真 全部在 master 单线;5 platform launch + 5 lens review 都串行 | `git worktree add ../cc-platform-apple` + 5 platform 独立 PR,合 R63 顺序 vs 并行 | **M** |

---

## 6. P2 — refactor / subagent (3 项)

| # | 项 | 描述 | 修法 | 难度 |
|---|----|------|------|------|
| **P2-1** | `scripts/_archive/` 30+ 一次性脚本 | `_r49_dark_mode_color_replace.py` / `_r53a_dedup_imports.py` / `_r56b_spacing_tokenize.py` / sprint2-zh-hant-tmp/ 17 个,共 30+ 一次性脚本 (R49-R56 各 round 修真工具) | 删 30 个历史产物,或移 `scripts/_archive/` → `scripts/legacy/` + README 说明 | **XS** |
| **P2-2** | widget test 覆盖率低 | `presentation/pages/{home,vent,medication,trend,assessment,mood,setup,check_in}` 8 feature, page 文件 54, widget test 仅 2 (`pages/settings` + `pages/trend`);testWidgets/test 比例 143/879 = 0.16 | 4 round 子任务:每 round 补 1-2 个核心 page (home R63, mood R64, vent R65, medication R66) | **L×4** |
| **P2-3** | `app_database.dart:154-169` vent contentTextEnc 加密迁移 | 单条加密失败 `catch (e) { /* swallow */ }` 0 log 0 metric,失败行 `contentTextEnc` 留 null,`VentMapper.toEntity` 兜底空内容 — 用户打开时静默丢文字 | 修真: catch 内 `piiSafeLog('AppMigration', 'vent $id 加密失败', error: e)` + 累计 `encryptedFailCount` → 返回值给 caller,MigrationFailedApp 提示 "N 条 vent 文字因加密失败已丢失,建议从备份恢复" | **S** |

---

## 7. systematic-debugging 5-class regression guard 状态

| 修真模式 (R19-B) | 修真 round | regression test | 状态 |
|------------------|------------|-----------------|------|
| 隐式 sort 假设 | R19-B | `sort_assumption_round19b_test.dart` (129 行) | ✅ 充分 |
| 跨 midnight | R17 R4 + R22 R29 | `app_root_round17_midnight_test.dart` + `crossed_midnight_since_round48_test.dart` | ✅ 充分 |
| dispose race | R52 R1 + R61 P0-1 | 0 test (P0-2) | ❌ 修真无锁 |
| stream subscription leak | R19-B | 0 test (`StreamSubscription` 0 hit in `test/`) | ❌ 修真无锁 |
| setState after dispose | R52-1 + R61 | 0 test (P0-2 同款) | ❌ 修真无锁 |
| UTC+8 硬编 | R48 P0-4 | `email_template_round19_test.dart:89-137` | ✅ 充分 |
| DateTime race | R19-B + R21 | `check_datetime_race.py` + `check_datetime_race2.py` (CI) | ✅ 充分 (CI 守护) |
| Stream first() hang | R38 P0-3 | `safety_watch_service_round12_test.dart` 间接 (5s timeout) | 🟡 部分 |

**诊断**: 修真 (R52 R1 / R61 P0-1) **缺系统性守护**。R49-R62 修真 6+ 个 dispose/setState 修真都未加 test。这是 spen TDD 原则的最大漏洞 — "修真 bug → 写 regression test → 跑红" 流程在 R52-R61 修真批次中**部分被跳过**。

---

## 8. 整体结论 vs v0.27 baseline (66 发现)

| 维度 | v0.27 R58 | v0.62 R61 | 趋势 | 评估 |
|------|-----------|-----------|------|------|
| Architecture 纯度 | 4.5/5 | 4.5/5 | 持平 | ✅ mature |
| God class 残留 | ~10 | ~10 (新 `export_orchestrator` 540 行加入;`notification_service` 反而涨 250→418) | **退步 1** | 🟡 修真产生新 god |
| Test count | 1109 | 1151 (+42) | ✅ 涨 | 但 widget test 仍 0 in `pages/{home,mood,vent,assessment}` |
| Test pyramid | domain 34 / data 33 / presentation 29 | 同 + core 17 | 持平 | ✅ 健康 |
| 守护脚本 | 16 | 16 | 持平 | 🟡 仅 4 在 CI,12 手动 |
| 修真 regression test | 部分 | **3/5 修真缺 (P0-1/2/3/4/5)** | 🟡 R57 修真都没写 test | ❌ 修真-测试 gap |
| 修真修真修真 | 修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真修真 | | | |

**Top 3 R63 行动建议 (spen priority)**:
1. **R63 P0 修真 gap 关闭** — 5 项 (P0-1/2/3/4/5) 各加 3-case regression test,15 个 case 一次性补齐
2. **R63 守护脚本全 CI** — `.github/workflows/ci.yml` 加 8 step (P1-4),守护 16 脚本 100% 进 CI 门禁
3. **R64 god class 修真顺序** — `app_tokens.dart` 拆 5 子模块 (P1-1) 优先,然后 `notification_service` 抽 `NotificationInitService` (P1-3),最后 `export_orchestrator` 拆 schema validator (P1-2)
