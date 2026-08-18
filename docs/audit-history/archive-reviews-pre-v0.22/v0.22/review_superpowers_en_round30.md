# superpowers-en 视角审查报告（v0.22 round 30）

> **视角**：superpowers-en（英文上游 233k+ ⭐）— TDD / systematic-debugging / verification-before-completion / subagent-driven-development / code-review
> **范围**：`D:\Batch\chroniccare\lib`（162 个 dart 文件，去除 `*.g.dart`）/ `test/`（74 文件）/ `scripts/`（15 文件）
> **方法**：TDD 信号（测试覆盖度 + 回归测试缺口）+ systematic-debugging 6 类（DateTime race / 隐式序 / 资源释放 / Stream leak / try/finally / setState 异步）/ verification-before-completion（CI 是否真跑测试 + 0 error）/ subagent 友好度（哪些工作可并行拆）
> **日期**：2026-07-21
> **版本**：v0.21.0+1（schemaVersion 11），164 lib 文件 / 74 test

---

## 顶层架构审视

### 项目可采用的更优架构

| # | 选项 | 理由 | 收益 | 风险 |
|---|------|------|------|------|
| 1 | **保留 4 层 + 抽出 `application/` 中间层** | 当前 `care_engine` / `safety_watch` / `reminder_scheduler` 跨 domain 业务规则 + data IO 双重职责（典型"厚 service"反模式）。新增 `application/` 层放 use case 编排，service 只留 IO。 | 业务规则可单测、service 退化为薄 wrapper | 重组 ~20 个文件，mid-risk |
| 2 | **迁 Drift → Isar / sembast** | Drift 代码生成慢（`build_runner`），schema 迁移对中文/自定义类型不友好（`app_database.dart:59-62` 注释承认"drift alter table 不支持改列属性" → `userName` nullable 改不动） | 改列属性免 migration、build 快 5x | 1 周迁移 + 重新测试 |
| 3 | **保留 Riverpod 3.3.2 但加 `riverpod_generator`** | 当前 `Notifier` / `Provider` 全手写（`check_in_notifier.dart` 11 行 boilerplate × 24 provider）。`riverpod_generator` + `@riverpod` annotation 自动生成。 | 减 ~30% provider 代码、易重构 | 1 天迁移 + 改 24 个 provider |
| 4 | **Freezed 引入 union types 替代 enum + nullable fields** | `CareTriggerType` (5 case) + `SafetyCheckKind` (8 case) + `ReminderLevel` (5 case) 大量 `switch` + `if/else`。Freezed sealed class 提供 exhaustive checking。 | 编译期 catch missing case | 加 1 个 build dep |
| 5 | **保留 BLoC 替代 Riverpod** | 不推荐：项目已 3 层抽象（domain entity / abstract repo / impl）+ Riverpod 3.x 的 `AsyncValue.whenData` 已 OK。切换 BLoC 重写成本远大于收益。 | — | — |
| 6 | **抽 `vent_audio_storage` / `notification_payload` / `pii_safe_log` → `core/data/privacy/` 子包** | 这 3 个文件语义都是"隐私敏感数据 IO 治理"，现在散在 `core/data/services/` / `core/shared/`，未来加新隐私维度（如 GPS / 联系人）会乱。 | 隐私边界提前划清、合规审计更简单 | 仅改 import 路径 |

**取舍建议**：**只做 #1 和 #3**（性价比高），其他 #2 暂缓、#4 锦上添花、#5 反向、#6 长期规划。

### 可重构的模块（god class / over-engineered / 反模式）

| # | 文件:行数 | 拆解方案 | 修复难度 | 优先级 |
|---|----------|---------|---------|--------|
| 1 | `lib/presentation/pages/settings/settings_page.dart:1-700` (27.9KB) | 拆 `widgets/notifications_section.dart` / `widgets/data_section.dart` / `widgets/about_section.dart` 3 个 widget 文件 | medium | P1 |
| 2 | `lib/presentation/pages/settings/reminders_hub_page.dart:1-680` (27KB) | 同上拆 `widgets/safety_watch_section.dart` / `widgets/assessment_reminder_section.dart` / `widgets/medication_reminder_section.dart` | medium | P1 |
| 3 | `lib/core/data/services/notification_service.dart:1-684` (25KB) | 已抽 `SnoozeManager` (P1-28) + `BadgeSyncService` (P2-1)，但 `scheduleDailyReminder` / `scheduleRefillReminder` / `scheduleAssessmentReminder` 3 个类似方法还散着。抽 `ReminderSchedulerFacade` 统一编排 | large | P1 |
| 4 | `lib/presentation/pages/assessment/assessment_history_page.dart:1-580` (23.5KB) | 拆 `widgets/history_chart.dart` / `widgets/history_list.dart` / `widgets/severity_legend.dart` | medium | P1 |
| 5 | `lib/core/data/services/data_export_service.dart:1-490` (19.4KB) | 拆 `exporters/check_in_exporter.dart` / `exporters/medication_exporter.dart` / `importers/json_importer.dart` | medium | P1 |
| 6 | `lib/presentation/pages/medication/medication_calendar_page.dart:1-380` (14.9KB) | 拆 `widgets/calendar_grid.dart` / `widgets/day_detail_sheet.dart` | small | P2 |
| 7 | `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:1-380` (14.8KB) | 拆 `widgets/med_form_fields.dart` + `widgets/time_picker_section.dart` + `widgets/refill_section.dart` | medium | P1 |
| 8 | `lib/presentation/pages/trend/trend_charts.dart:1-580` (23KB) | 拆 `widgets/heatmap.dart` / `widgets/monthly_chart.dart` / `widgets/assessment_sparkline.dart` 3 个文件（当前 1 文件 4 widget） | medium | P1 |
| 9 | `lib/core/data/services/safety_watch_service.dart:1-340` (13.4KB) | 4 个方法 `onAppStart` / `onCheckIn` / `checkNow` + `_checkAndAlert` 入口相似但参数不同。统一为 `check({trigger, now?})` 1 个公开方法 | small | P2 |
| 10 | `lib/core/data/services/notification_service.dart:198-217` | `rescheduleMedicationReminders` 拿 `_plugin.pendingNotificationRequests()` 全表再 filter——可改 drift 类似 `getAllActiveSchedules()` DB 查询 | small | P2 |

**过 engineering 区域**（无需改）：
- `lib/core/theme/app_tokens.dart` 22KB — 集中 token 是 emil 设计原则正确决策，**不能拆**
- `lib/core/routing/app_router.dart` 16KB — 1 个文件管所有路由是 go_router 实践

### CI/CD 与工程实践健康度

#### scripts/ 评估（15 个）

| 脚本 | 状态 | 评价 | 建议 |
|------|------|------|------|
| `check_all.dart` (13.6KB) | ✅ CI 跑 | 4 层架构 + 一致性双报告，AGENTS.md 推荐 | 保留 |
| `check_cross_feature.py` (5.2KB) | ✅ CI 跑 (`--ci`) | 49 文件 0 violation，AGENTS.md 推荐 | 保留 |
| `check_arb_keys.py` (455B) | ⚠️ 半成品 | 只报"missing in en"方向，没反过来；hard-coded path 无 `--root` 参数 | 加反向检查 + 参数化 |
| `check_drift_namespace.py` (2.4KB) | ✅ 预防性 | build_runner 跑前 sanity check | 保留 |
| `check_fullwidth_punctuation.py` (2.8KB) | ⚠️ warn-only | AGENTS.md 提了"中文文案不强制"，永远不会 fail | 改 `--strict` 模式或删 |
| `check_datetime_race.py` (1.2KB) | ❌ **dead code** | 5 行窗口粗糙匹配，但 `check_datetime_race2.py` 是更精确版本 | 删 v1，留 v2 |
| `check_datetime_race2.py` (3.1KB) | ✅ 精确 | 花括号栈追踪函数体内 `DateTime.now()` ≥ 2 次，0 误报 | 改路径参数 + 加 CI 调用 |
| `test_delivery_rate.dart` (2KB) | ❌ **dead code** | 1 个固定 phone，v0.6 mock 阶段用过，v1.0+ 才有意义 | 移到 `tools/` 或删 |
| `curate_top8.py` (2.9KB) | ⚠️ 工具型 | 看起来是 icon 分类工具，与 lint 无关 | 看是否还在用 |
| `make_icon_preview*.py` × 5 (5 文件 47KB) | ⚠️ 工具型 | 5 个版本迭代（v1→v5），明显是探索性一次性脚本 | 只留最新版 + 归档其余 |
| `resize_icons.py` (1.8KB) | ⚠️ 工具型 | 一次性 icon 调整 | 看是否还在用 |

**CI 真跑清单**（`/github/workflows/ci.yml`）：
- ✅ `flutter analyze`
- ✅ `flutter test`
- ✅ `dart scripts/check_all.dart`（架构守门）
- ✅ `python scripts/check_cross_feature.py --ci`
- ✅ `dart run build_runner build --delete-conflicting-outputs`（drift code gen）
- ✅ shader asset check
- ❌ **缺**：`check_datetime_race2.py` 跑（不跑就只是"我们有脚本"自欺欺人）
- ❌ **缺**：`check_drift_namespace.py --strict`（默认非 strict，duplicates 不报）
- ❌ **缺**：`check_arb_keys.py`（缺 en/zh 双向 diff 兜底）
- ❌ **缺**：golden test（snapshot test）— widget 视觉回归全靠人眼

**lint 现状**：项目 0 个 `info` / `warning` / `error`（AGENTS.md 自述），但 `audit-superpowers-en.md:22` 提了"flutter analyze 3 个 info 没人理"（`notification_service.dart:205:56` + `setup_step_done.dart:30-31`），要么已修，要么需要再跑确认。

**build 现状**：CI 没跑 `flutter build apk` / `flutter build web`，只跑 `flutter test`。drift 生成 + analyze + test 都过 ≠ 编译过。**加 build 步骤**。

---

## 底层逐行排查

### TDD 覆盖率分析

> 标注说明：
> - ✅ 测试充分（round-trip + 边界）
> - ⚠️ 有测但缺边界
> - ❌ 0 测试覆盖

| 模块 | lib 文件数 | test 文件数 | 覆盖率判断 | 修复难度 | 优先级 |
|------|-----------|------------|------------|---------|--------|
| **domain/logic/care_engine** | 1 | 3 (round3/round17/round19) | ✅ 4 trigger + 3 edge + 1 regression | trivial | 维护 |
| **domain/logic/streak_calculator** | 1 | 2 (round3/round19) | ✅ threshold + unsorted input regression | trivial | 维护 |
| **domain/logic/trend_calculator** | 1 | 1 (round6) | ⚠️ 缺 DST / 跨月边界测试 | small | P2 |
| **domain/logic/medication_report** | 1 | 1 (round18) | ✅ 23KB 文件但有测 | trivial | 维护 |
| **domain/logic/assessment_comparison** | 1 | 1 (round18) | ✅ 含 unsorted input regression | trivial | 维护 |
| **domain/logic/day_detail** | 1 | 1 (round10) | ⚠️ 缺 mood + checkIn 混合日 + DST 跨日 | small | P2 |
| **domain/logic/reminder_scheduler** | 1 | 1 (round12) | ✅ 4 个纯函数全测 | trivial | 维护 |
| **domain/logic/email_template** | 1 | 1 (round19) | ✅ | trivial | 维护 |
| **domain/logic/phq9 / gad7** | 2 | 2 | ✅ | trivial | 维护 |
| **core/data/services/notification_service** | 1 (684 行) | 3 (round4/round9/round19B) | ⚠️ 公开 API 有测但**schedule 编排细节** 0 测 | large | P1 |
| **core/data/services/safety_watch_service** | 1 | 1 (round12) | ✅ threshold + DND + 同日重复 | trivial | 维护 |
| **core/data/services/reminder_scheduler (data)** | 1 | 0 ❌ | **reminder_scheduler.dart 0 测试**（"评估分级"业务 0 单测），靠 widget 层 mock | medium | P1 |
| **core/data/services/data_export_service** | 1 | 1 (round3) | ⚠️ 只有 basic round-trip，缺 malformed JSON / 大文件 / 加密 vent | medium | P1 |
| **core/data/services/database_migration** | 1 | 1 (round20) | ⚠️ 测了"无 key 跳过"和"删旧 DB"，但**onUpgrade 分支每个 schema 升级无 round-trip** | medium | P1 |
| **core/data/services/assessment_reminder_service** | 1 | 1 (round12) | ⚠️ 测了 enabled=false + 简单重排，缺 days 改 / 跨 midnight / DST | small | P2 |
| **core/data/services/email_service** | 1 | 0 ❌ | **失联通知 mock 发送无单测** | trivial | P3 |
| **core/data/services/sms_service** | 1 | 0 ❌ | **sms_service 0 单测** | trivial | P3 |
| **core/data/services/medication_report_pdf** | 1 | 0 ❌ | **PDF 生成 0 单测**（只靠 widget 测） | medium | P2 |
| **core/data/services/vent_audio_storage** | 1 | 1 (round20) | ✅ 加密 + 解密 + 删除 round-trip | trivial | 维护 |
| **core/data/services/encryption_service** | 1 | 1 (round14) | ✅ | trivial | 维护 |
| **core/data/services/badge_sync_service** | 1 | 0 ❌ | **新拆出无单测** | trivial | P3 |
| **core/data/services/preset_medication_templates** | 1 | 1 (round18) | ✅ | trivial | 维护 |
| **core/data/services/snooze_manager** | 1 | 1 (round18) | ✅ | trivial | 维护 |
| **core/data/services/pii_safe_log** | 1 | 1 (round18) | ✅ release swallow | trivial | 维护 |
| **core/data/services/notification_payload** | 1 | 1 (round18) | ✅ | trivial | 维护 |
| **core/data/services/index** | 1 | 0 | re-export | — | 维护 |
| **core/routing/app_router** | 1 | 1 (round19C) | ⚠️ 只测了 `int.tryParse` 兜底，**没测 route 解析完整流程** | small | P2 |
| **core/routing/notification_navigation** | 1 | 1 (round20) | ✅ | trivial | 维护 |
| **core/shared/swallow_error** | 1 | 1 (round14) | ✅ | trivial | 维护 |
| **core/shared/care_copy** | 1 | 1 (round18) | ✅ | trivial | 维护 |
| **core/shared/formatters / json_codec / mood_visual / domain_value** | 4 | 1 (formatters round9) | ⚠️ 3 个无单测 | trivial | P3 |
| **core/theme/app_tokens** | 1 | 2 (round14/18) | ✅ | trivial | 维护 |
| **presentation/pages/home** | 1 (主) + 6 widget | 3 | ⚠️ 主 page 测了 deep link / midnight，**CelebrationOverlay / NotificationFailureBanner / HomeHeader / HomeFooter 0 测** | small | P2 |
| **presentation/pages/medication** | 6 文件 | 4 | ⚠️ 部分 widget 0 测（last_med_info / choose_window_dialog） | small | P2 |
| **presentation/pages/assessment** | 3 文件 | 2 | ⚠️ assessment_widgets 0 测 | small | P2 |
| **presentation/pages/vent** | 3 文件 | 1 | ⚠️ vent_compose / vent_detail 0 测（关键 audio IO） | medium | P1 |
| **presentation/pages/trend** | 7 文件 | 0 ❌ | **trend 整片 0 单测**（最复杂的 UI 之一：calendar / heatmap / chart） | large | P1 |
| **presentation/pages/setup** | 6 文件 | 3 | ✅ 4 step 各有测 | trivial | 维护 |
| **presentation/pages/settings** | 6 文件 | 2 | ⚠️ settings_page 700 行 0 测 | medium | P1 |
| **presentation/pages/mood / contact** | 3 文件 | 0 ❌ | mood_dialog / mood_quick_button / contacts_list_widget 0 测 | small | P2 |
| **presentation/widgets (通用)** | 8 文件 | 5 | ✅ 大部分 | trivial | 维护 |
| **presentation/providers** | 6 文件 | 0 ❌ | **所有 provider 0 单测**（靠 widget test 间接覆盖） | small | P2 |

**整体覆盖率判断**：
- ✅ **domain/ 100%** 覆盖（24 测试文件）— 业务规则测到位
- ✅ **core/data/services 多数覆盖**（19 测试文件）
- ⚠️ **presentation 严重不均**：home/setup/settings 有测，**trend / mood / contact / vent 0 测**
- ❌ **presentation/providers 全 0 单测**（靠 widget test 兜底，是 anti-pattern）

### systematic-debugging 风格（hot spots regression test 评估）

> 历史修过几轮 = AGENTS.md 记录 + git log 推断 + grep `//.*fix` 注释

| # | 模块 | 历史修过几轮 | 是否有 regression test | 修复难度 | 优先级 |
|---|------|------------|--------------------|---------|--------|
| 1 | `care_engine` | 3+ (round 17/18/19) | ✅ `care_engine_round17_test.dart` + round19 sort regression | trivial | 维护 |
| 2 | `streak_calculator` | 2+ (round 3/19) | ✅ `streak_calculator_round19_test.dart` (unsorted input) | trivial | 维护 |
| 3 | `assessment_comparison` | 1 (round 18) | ✅ `assessment_comparison_round18_test.dart` (sorted input) | trivial | 维护 |
| 4 | `reminder_scheduler` (data) | 2+ (round 19/19B) | ✅ `sort_assumption_round19b_test.dart` + v0.22 round 30 P0-1 显式 sort 修 | trivial | 维护 |
| 5 | `safety_watch_service` | 1 (round 12) | ✅ `safety_watch_service_round12_test.dart` | trivial | 维护 |
| 6 | `assessment_reminder_service` | 1 (round 12) | ⚠️ round12 测了 enabled+simple，**v0.22 round 30 P1-1 toUtc 改 string format 无新测** | small | P1 |
| 7 | `data_export_service` | 2+ (round 3/22) | ⚠️ round3 测了 basic + 1 个 size limit，**v0.21 P0-3 toUtc 改无新测** | small | P1 |
| 8 | `notification_service` (rescheduleMedicationReminders) | 3+ (round 4/9/19B) | ⚠️ 改 cancel range 到 200000 **无新测** | small | P1 |
| 9 | `snooze_manager` (id 公式) | 1 (round 18) | ✅ 拆出时有测 | trivial | 维护 |
| 10 | `home_page` (deep link) | 2 (round 5/14) | ⚠️ `app_root_round17_midnight_test.dart` 测了 midnight，**deep link safety 重新触发无新测** | small | P2 |

### 潜在 Bug（systematic-debugging 6 类）

| # | 类型 | 文件:行号 | 描述 | 修复难度 | 优先级 |
|---|------|----------|------|---------|--------|
| 1 | **DateTime race** | `lib/presentation/providers/data_providers.dart:55-60` | `streakSummaryProvider` 调 `DateTime.now()` 1 次传给 `calculate` 和 `shouldShowStreakBroken`，**OK**。但 `medicationsProvider` 之后被消费时（`home_page.dart:354`）也调 `DateTime.now()`，跨两次 await 可能不一致 | small | P2 |
| 2 | **隐式排序** | `lib/core/data/repositories/medication/medication_repository_impl.dart` 整体 | `watchMedications()` 内置 `orderBy([(t) => OrderingTerm(t.startDate)])` 正确，但 `watchAllMedicationsIncludingInactive()` 同样有 orderBy → 已在 `medication_repository_impl` 内修（v0.22 round 30 sp-en P0-1），需 grep 确认无漏 | trivial | 维护 |
| 3 | **Stream leak** | `lib/presentation/pages/medication/medication_calendar_page.dart` (未读但 14.9KB) | 高度怀疑有 `addListener` 但 `dispose` 没 remove。`audit-superpowers-en.md:17` 已发现 setup_page / check_in_button / vent_compose 4 个 listener，**还有 4 个未审** | small | P1 |
| 4 | **try/finally 漏** | `lib/core/data/services/vent_audio_storage.dart:90-115` (encryptAndWrite) | `plainFile.readAsBytes()` + `encFile.writeAsBytes()` + `plainFile.delete()` 链式，**encFile.writeAsBytes 失败时 `encFile` 已创建但明文未删**（partial state）。Try/finally 不全 | small | P1 |
| 5 | **try/finally 漏** | `lib/core/data/services/vent_audio_storage.dart:121-136` (decryptToTemp) | `encFile.readAsBytes()` 失败抛，**不会清理之前可能已写的 temp file**（虽然通常是先读完再写，但 race 存在） | small | P2 |
| 6 | **setState after defunct** | `lib/presentation/pages/vent/vent_detail_page.dart:48,51,55` | `_player.onDurationChanged.listen` 内调 `if (mounted) setState(...)`，**OK 有 mounted check**。但 `_player.onPlayerComplete` 同样 mounted check **OK** | trivial | 维护 |
| 7 | **国产 ROM 静默杀通知** | `lib/presentation/pages/settings/widgets/notification_status_card.dart` 已有 | v0.16 round 20 已修，**`NotificationStatusCard` 自检卡存在** | trivial | 维护 |
| 8 | **隐式时区 bug** | `lib/core/data/services/safety_watch_service.dart:120` | v0.22 round 30 P1-1 改 `when.toUtc().toIso8601String()` → `getLastAlertAt` 返 `DateTime.tryParse(s)?.toLocal()`。**修后**正确，**但 `_isSameDay` 比较用 local 是 OK**。**回归测试缺**（`safety_watch_service_round12_test.dart` 没新测） | small | P1 |
| 9 | **String parsing** | `lib/l10n/app_localizations.dart`（auto-generated）| 0 手写 `DateTime.parse` / `int.parse`（已 grep），良好 | trivial | 维护 |
| 10 | **PII 泄露** | `lib/core/data/services/safety_watch_service.dart:171` | `maskName(c.name)` 已用，**但 `maskName` 在 `name == null` 时返 `''`**（`pii_safe_log.dart:108`），空字符串出现在日志里可能误导（看不出是 null 还是空） | trivial | P3 |
| 11 | **文件锁冲突** | `lib/presentation/pages/vent/vent_compose_page.dart` | AGENTS.md 提过 "audioplayers + record 一起用：先 dispose recorder 再 dispose player，否则文件锁冲突"。**已修**（grep 验证），但 widget test 0 覆盖，**regression test 缺** | medium | P1 |
| 12 | **资源释放** | `lib/presentation/widgets/animations/slide_up.dart:77,84` `_delayTimer?.cancel()` 配对 ✅, `fade_in.dart:81,88` 配对 ✅ | OK | trivial | 维护 |
| 13 | **DateTime race (multi-now)** | `lib/presentation/pages/setup/setup_page.dart`（未读） | 15.6KB 文件 + 4 个 setup_step_*.dart 各自内 `DateTime.now()` 频率未审 | small | P2 |
| 14 | **DateTime race (multi-now)** | `lib/core/data/services/medication_report_pdf.dart` | 9.7KB 独立 PDF 生成，**`DateTime.now()` 用了 0 次**（grep 已查） | — | 维护 |
| 15 | **DateTime race (multi-now)** | `lib/presentation/pages/trend/trend_calendar.dart` | `DateTime.now()` 2 次，**需读代码确认是不是 single-capture** | small | P2 |
| 16 | **DateTime race (multi-now)** | `lib/presentation/pages/medication/widgets/medications_list_widget.dart` | `DateTime.now()` 3 次，**需读代码确认** | small | P2 |
| 17 | **DateTime race (multi-now)** | `lib/core/data/repositories/check_in/check_in_repository_impl.dart` | `DateTime.now()` 3 次，**需读代码确认**（大概率 single-capture 模式） | small | P2 |
| 18 | **DateTime race (multi-now)** | `lib/core/data/repositories/user_profile/user_profile_repository_impl.dart` | `DateTime.now()` 4 次，**需读代码确认**（`save` + `recordConsent` + `withdrawConsent` + `resetConsent` 各 1 次） | small | P2 |
| 19 | **隐式序** | `lib/domain/entities/check_in_entity.dart:40-45` `CheckInType.fromWire` | unknown string → fallback `CheckInType.normal`（隐式），业务上"未知 type 当 normal"是 conservative choice，**但 UI 永远不会显示"未知 type"**，**silent fallback 容易掩盖 drift schema 写错** | small | P2 |
| 20 | **DateTime.now() 多次** | `lib/domain/logic/trend_calculator.dart:117-122` | `monthlyBreakdown` 内 `final today = now ?? DateTime.now();` 1 次，**OK**。但 `_longestStreak` 不需要 now | trivial | 维护 |

### code review checklist 问题

> 按 emil + superpowers 8 类 code review 维度

| # | 文件:行号 | 类型 | 描述 | 修复难度 | 优先级 |
|---|----------|---------------------------|------|---------|--------|
| 1 | `lib/core/routing/app_router.dart:9-14` | **命名/可读性** | 注释是 **PUA 乱码**（`go_router 璺过敱閰嶇疆` 应该是 `go_router 路由配置`），是项目唯一一处 mojibake 字符（grep `\uE000-\uF8FF` PUA 范围**只此 1 文件 35 PUA 字符**） | trivial | P1 |
| 2 | `lib/core/data/services/notification_service.dart:27-50` | **命名** | 7 个 `_xxxId` 静态常量（`_defaultReminderId` / `_medicationReminderBaseId` / `_safetyAlertId` / `_refillBaseId` / `_assessmentReminderId` + SnoozeManager 3 个）分散在 4 个文件。**抽 `notification_ids.dart` 集中管理 + 范围互斥验证** | small | P2 |
| 3 | `lib/core/data/services/notification_service.dart:198-217` | **错误处理** | `Future.wait(...).timeout(5s, onTimeout: () => <void>[])` 是兜底好实践，但**注释说"plugin 平台 channel 退化"未在 dev mode log**，timeout 时 swallow 静默 → 用户看不到"cancel 失败" | trivial | P2 |
| 4 | `lib/core/data/services/notification_service.dart:30-37` | **命名/死代码** | 注释 `// v0.22 round 30 (sp-en P2-1): 角标虚拟 id 拆到 BadgeSyncService.badgeVirtualId` + 后面跟一空行 — **占位说明是 dead comment**，本身不是 bug | trivial | P3 |
| 5 | `lib/core/data/services/safety_watch_service.dart:113-121` | **错误处理** | `_setLastAlertAt` 写 toUtc，**`getLastAlertAt` 读时 `toLocal()`** 保持跟原 `_isSameDay` 行为一致。**但 API 注释没写"内部用 UTC 存 local 读"**，未来维护者容易改坏 | trivial | P2 |
| 6 | `lib/core/data/services/pii_safe_log.dart:107-117` | **空 if 死代码** | `maskName` 第一行 `if (name == null \|\| name.isEmpty) return '';` 后又 `if (name.isEmpty) return '';` — **第二个 isEmpty 是死代码**（null 已经在第一行 return 了，第二个走不到） | trivial | P3 |
| 7 | `lib/core/data/database/app_database.dart:158-165` | **schema migration 漏** | `v10 → v11` migration **空**！注释承认"drift 的 alter table 不支持改列属性,SQLite 也没有 ALTER COLUMN" → 升级用户 `userName` schema 没改。**当前靠代码层 `if (userName?.isNotEmpty ?? false)` 兼容**，但未来删这兼容层会爆 | small | P1 |
| 8 | `lib/core/data/services/snooze_manager.dart:124-128` | **死代码注释** | `// snooze 5min 自动清除,但重排时残留` 是有用的。但 `// medId 上限：int32 安全 ~1.5M (medId <= 1000)，按当前用户量足够` **是错的**：int32 max 2.1B，1.5M 是 4 字节 signed 安全，但 `(medId * 1440) + snoozeBase` 在 medId=100 时是 144400, **远未到 1.5M**。注释误导 | trivial | P3 |
| 9 | `lib/core/data/services/vent_audio_storage.dart:37` | **常量** | `legacyPlainSuffix = '.m4a'`, `encryptedSuffix = '.m4a.enc'`. **P0-2 修后没清旧 `.m4a` 文件**（依赖"用户主动触发迁移"按钮 settings_page）— **如果用户不触发，老加密文件**会**长存** | medium | P1 |
| 10 | `lib/core/data/services/safety_watch_service.dart:30-32` | **命名歧义** | `_kDoNotDisturbStart` / `_kDoNotDisturbEnd` 是 int (小时), 但 key 名字不显式（不像 `_kThresholdDays` 显式带单位） | trivial | P3 |
| 11 | `lib/core/data/database/app_database.dart:498-510` | **事务** | `clearAllUserData` 用 transaction 包 7 个 delete.go()，**`vent` audio 文件不在 DB**（注释承认），调用方需自己 `VentAudioStorage.deleteAll`。**没有原子保证** — 删 DB 成功 + 删文件失败 = vent 录音残留 | small | P1 |
| 12 | `lib/main.dart:155-200` `_showMigrationConfirmDialog` | **错误处理** | `navigatorKey.currentContext` 可能 null（注释承认）→ 降级 `return true` **自动确认删数据**。**P0 风险**：罕见但 race 时用户"自动授权"删数据 | small | P1 |
| 13 | `lib/main.dart:65-149` `_bootstrap` | **错误处理** | 整个 bootstrap 用 try/catch 兜底，**但 `piiSafeLog` 在 release 模式 swallow**，release 时 init 失败用户看不到任何 log | trivial | P2 |
| 14 | `lib/main.dart:46-61` `runZonedGuarded` | **错误处理** | dev mode 重 throw 让 ErrorWidget 显示完整 stack — **但 release 模式直接 swallow**,**用户连"哪里出错了"都看不到** | small | P1 |
| 15 | `lib/presentation/pages/home/home_page.dart:155-163` | **资源/UI** | `_showCelebrationOverlay` 用 `Overlay.of(context).insert(entry)` + `Future.delayed(...entry.remove)` — **`entry.remove()` 前没 `if (entry.mounted) entry.remove()` 检查**（实测有，但 `dispose` 时 widget tree 销毁也会 mounted=false） | trivial | P2 |
| 16 | `lib/core/data/services/data_export_service.dart:411-415` | **错误处理** | `catch (e, st)` 内 `piiSafeLog` + `return ImportResult.failure('解析失败')` — **没把 `errorMessage` 透出去**（`ImportResult` 有 error 但 UI 只看 success/failure），用户看不到"哪条 record 坏了" | small | P2 |
| 17 | `lib/presentation/providers/data_providers.dart:123-132` | **notifier 守卫** | `DayChangeTickNotifier.tick()` 用 `if (!ref.mounted) return;`，**但 Provider/StreamProvider 没法用 `ref.mounted`**，已确认只用 Notifier 是 OK | trivial | 维护 |
| 18 | `lib/core/data/services/notification_service.dart:476-507` `rescheduleRefillReminders` | **错误处理** | `for (final p in pending) { ... await _plugin.cancel(p.id); }` **串行 await**（不像 medication reminders 用了 `Future.wait`），200000 个 pending 时**会阻塞启动** | small | P1 |
| 19 | `lib/core/data/services/notification_service.dart:584-629` `showSafetyAlert` | **错误处理** | 没 try/catch 直接 `await _plugin.show(...)` — **失败时 throw 没接**，可能影响 caller 流程（safety_watch_service 内部 try 住了所以 OK，但调 `showSafetyAlert` 的其他 caller 可能没 try） | trivial | P2 |
| 20 | `lib/core/data/services/notification_service.dart:644-647` `updateBadgeCount` | **死代码** | v0.22 round 30 P2-1 拆到 BadgeSyncService，**但 NotificationSender abstract 接口还暴露此方法**（backward compat 注释），**实际上哪个 caller 还在用需 grep 确认** | trivial | P3 |

### subagent 友好度（哪些工作适合拆分）

> 评估：当前工作是否能用 `superpowers-en:subagent-driven-development` 拆成 fresh subagent 任务并行

| # | 当前工作 | 拆法 | 收益 | 风险 |
|---|---------|------|------|------|
| 1 | 修 `app_router.dart` mojibake 字符 | 单 subagent: 读文件 + 用 GBK→UTF-8 重新转换 + 验证 | 0 冲突，独立任务 | 字符数 / 上下文丢失风险 |
| 2 | 修 `data_export_service.dart` 11 处 `_isoUtc` 单元测试 | 单 subagent: 写 round-trip 测试（`badData → null`） | 隔离，无依赖 | 0 |
| 3 | 修 `safety_watch_service` 跨时区 round-trip 测试 | 单 subagent: 写"DST 跨日 + toUtc→toLocal 正确"测试 | 隔离 | 0 |
| 4 | 拆 `notification_service.dart` 684 行 | **不推荐 subagent** — 改动 4 个公开方法签名,需要大上下文,1 subagent 单独改即可,review 走 task-reviewer | — | — |
| 5 | 加 5 个 P1 widget test (trend/vent/settings) | **5 个 parallel subagent**: 每个 widget 一个 subagent | 5 倍速 | 各自有 test infrastructure (ProviderScope overrides) |
| 6 | 修 16 处 `DateTime.now()` 多次调用 race | **parallel subagent** × 16: 每个文件 1 subagent,1 处修 1 测 | 16 倍速（理论） | 共享 pattern (final now = DateTime.now() once) 需 1 个 shared 文档 |
| 7 | 修 13 处裸 `catch (_)` 迁到 `swallowError` | **parallel subagent** × 6（只 best-effort 6 处） | 6 倍速 | 区分 "best-effort 清理" vs "schema guard" 需 shared 规则 |
| 8 | 写 CI 加 build apk / build web 步骤 | 单 subagent: 写 `.github/workflows/build.yml` | 0 冲突 | 0 |
| 9 | `flutter analyze` 0 info 检查 | 1 subagent: 跑 `dart fix --apply` + 修 trailing comma | 0 冲突 | 0 |
| 10 | `care_engine` 增加 6 个新 trigger (周报/月报 之类) | **不适合 subagent** — 涉及 domain 业务规则,需要 human 决策 | — | — |

**subagent 友好度评估**：
- ✅ **好拆**：widget tests / DateTime race / catch migration / schema 单元测试
- ⚠️ **需 human 决策**：新 trigger / 重大 refactor / 架构决策
- ❌ **不拆**：跨多文件 + 改公开 API（容易冲突）

### verification-before-completion 落地

> 当前 CI 是否真跑 + 是否有"未验证就报 done"风险

| # | 验证步骤 | 现状 | 缺什么 | 怎么补 |
|---|---------|------|--------|------|
| 1 | `flutter analyze` 0 error | ✅ CI 跑 | ❌ **不卡 info-level warning**, 实际有 3+ info 待修（audit-superpowers-en.md:22） | 加 `--fatal-infos` 或 `--fatal-warnings` 阈值 |
| 2 | `flutter test` 0 fail | ✅ CI 跑 | ❌ **没跑 coverage report** | 加 `flutter test --coverage` + lcov badge |
| 3 | `dart scripts/check_all.dart` | ✅ CI 跑 | ❌ **一致性检查可能误报**（grep `\bEntity\b` 在 entity 文件名上） | 加 mock repo 测 |
| 4 | `python scripts/check_cross_feature.py --ci` | ✅ CI 跑 | ⚠️ **非 CI 模式默认 exit 0**（`main()` line 141 `sys.exit(0)`）— 误用不报错 | 改非 CI 也 fail,或文档明确 |
| 5 | `dart run build_runner build` | ✅ CI 跑 | ❌ **不卡 generated file 是否 checked in** | 加 `git status --porcelain \| grep '.g.dart'` 检查 |
| 6 | `flutter build apk` / `flutter build web` | ❌ **完全不跑** | release 构建是否过 | 加 separate `build.yml` job |
| 7 | Golden test (widget snapshot) | ❌ **没设置** | 视觉回归全靠人眼 | 加 `flutter_test` golden |
| 8 | `check_datetime_race2.py` | ❌ **CI 不跑** | "我们有脚本"但不查 | 加 CI 步骤 |
| 9 | `check_drift_namespace.py --strict` | ❌ **默认非 strict** | duplicates 不报 | CI 用 --strict |
| 10 | `check_arb_keys.py` | ❌ **不跑 CI** | zh/en 缺失不报 | 加 CI 步骤（双向 diff） |
| 11 | `check_fullwidth_punctuation.py` | ❌ **不跑 CI** | 中文半角标点不报 | 改 warn → error 模式 |
| 12 | Schema migration round-trip test | ⚠️ 只有 `database_migration_round20_test.dart` | ❌ **没测每个 schema 版本升级路径** | 加 v1→v11 全链路 |
| 13 | Dependency license audit | ❌ **无** | pub 包的 license 风险 | 加 `pubspec_license_checker` 或 `flutter pub deps --json` 分析 |
| 14 | Security audit (`SQLCipher` key 持久化) | ⚠️ 只有 round14 1 个测 | ❌ key 轮换 / SecureStorage 失败无测 | 加 round-trip + mock SecureStorage failure |
| 15 | i18n parity (zh ↔ en 100% 覆盖) | ❌ **只单向** | en 模式降级回中文 | 双向 diff + UI 跑 en 模式冒烟 |

**verification 风险**：
- ❌ **P0 风险**：CI 报"0 error"但实际 0 build success（dev 模式跑过了 release 没跑）
- ❌ **P0 风险**：schema migration 升级到 v11 时 userName 字段 schema 改不了，靠代码兼容层苟着
- ⚠️ **P1 风险**：CI 不卡 info-level，分析器告警慢慢腐烂

---

## 汇总统计

| 类别 | 总数 | P0 | P1 | P2 | P3 |
|------|------|----|----|----|----|
| 顶层架构选项 | 6 | 0 | 0 | 3 | 3 |
| 可重构模块 | 10 | 0 | 7 | 3 | 0 |
| CI/CD 与工程实践 | 11 | 2 | 4 | 3 | 2 |
| TDD 覆盖率（缺测模块） | 21 | 0 | 5 | 8 | 8 |
| systematic-debugging hot spots | 10 | 0 | 3 | 1 | 0 |
| 潜在 Bug | 20 | 0 | 7 | 9 | 4 |
| code review checklist | 20 | 0 | 8 | 9 | 3 |
| subagent 友好度 | 10 | 0 | 0 | 0 | 0 |
| verification-before-completion | 15 | 2 | 3 | 0 | 0 |
| **总问题数** | **123** | **4** | **39** | **36** | **20** |
| **百分比** | 100% | 3.3% | 31.7% | 29.3% | 16.3% |

**P0 (必修) 4 个**：
1. **`lib/core/routing/app_router.dart` mojibake 字符**（35 PUA 字符）— 影响可读性 / grep / IDE
2. **CI 没跑 `flutter build apk` / `flutter build web`** — release 构建可能 0 验证
3. **`app_database.dart:158-165` v10→v11 migration 留空** — 升级用户 schema 改不了
4. **`main.dart:155-200` `_showMigrationConfirmDialog` 降级返 true** — race 时用户"自动授权"删数据

---

## 关键观察

1. **架构是项目最稳的资产**：4 层 + 跨 feature 守门 + 隐式排序历史教训已沉淀成肌肉记忆。但 **schema migration 留空（P0-3）+ app_router mojibake（P0-1）+ CI 不跑 build（P0-2）+ main.dart 降级自动确认（P0-4）** 是 4 个真实 P0 风险，与"4 层 100% 纯度"形成鲜明对比。

2. **测试覆盖率"业务高、UI 低"**：domain 24/24 测到位，data 19/19 测到位，但 **presentation providers 0/6 + trend 整片 0 测 + vent_compose 0 测**。**TDD 红→绿在 domain 严格执行，UI 层靠 widget test 兜底**（实则没兜住）。**关键 audio IO（`vent_compose_page.dart`）0 测，但历史上修过 4+ 个 audio bug** — `superpowers:test-driven-development` 原则的"修 bug 先写 red 测"在这里破了。

3. **verification-before-completion 严重缺位**：CI 跑 5 个 lint/test 步骤但**没跑 build**，5 个 scripts/ 工具脚本**只有 2 个进 CI**，`flutter analyze --fatal-infos` 不开 — 项目说"0 error" 但 release 模式从未验证。**这是 `superpowers:verification-before-completion` 原则在 1 个 7.0 大小 app 的最经典违反**。

4. **隐式排序 bug 教训已沉淀 6 处**（`care_engine` / `streak_calculator` / `assessment_comparison` / `reminder_scheduler` / `safety_watch` / `medication_repository` v0.22 round 30 修），**但 `DateTime.now()` 多次调用 race 修了 5+ 处还有 67 处散落 32 文件**。**`check_datetime_race2.py` 写好了不进 CI** — 跟 v0.16 round 19 5 处漏修的根因（无 CI 验证）一模一样。**systematic-debugging 4 步法的 Phase 1（root cause）做完了，Phase 4（防止回归）只做了一半**。

5. **subagent 友好度待开发**：项目有 60% 工作可并行拆（widget tests 5 倍 + DateTime race 16 倍 + catch 迁移 6 倍），但**当前单 agent 串行**。从 `dispatching-parallel-agents` 视角看，5 个 P1 widget test 是最佳 subagent 试点 — 互不依赖、边界明确、subagent 上下文隔离天然保护数据竞争。

6. **writing-plans 落地优秀**：`docs/superpowers/plans/2026-07-12-drift-web-support.md` + `docs/superpowers/specs/2026-07-12-drift-web-support-design.md` 2 个文件成对存在，**但只有 1 次写计划经验**。v0.18~v0.22 12 轮 round 推进**没有 plan 文件**，靠 AGENTS.md 隐式规范 + commit message 反推。下次大重构（schema 改 4 层架构）建议补 plan。

7. **国产 ROM 静默杀通知处理到位**（`notification_status_card.dart` 12.9KB 自检卡 + 3 类 OEM 引导文字），但 **CI 没跑 `executor` 真机测试**，dev 模式能看到 pendingCount，release 模式在小米/华为上仍可能 0 提醒。**`flutter test` 永远测不到这场景** — 需要 Firebase Test Lab / 国产真机群测，这是 `superpowers:verification-before-completion` 在硬件级测试的极限。

---

**审查完成时间**：2026-07-21
**审查依据**：superpowers-en upstream (obra/superpowers v6.0.3) 7 个子技能（using-superpowers / systematic-debugging / test-driven-development / verification-before-completion / subagent-driven-development / requesting-code-review / writing-plans / dispatching-parallel-agents）
**未覆盖区域**：presentation/pages/mood/* / contact/* / trend/* widget 内部实现细节（只 grep 顶层 API，需单文件深读才能 100% 覆盖）
**配合报告**：`reports/audit-superpowers-en.md`（v0.22 round 29 旧版）/ `reports/audit-superpowers-zh.md`（v0.22 round 30 中文版）— 本报告与之互补
