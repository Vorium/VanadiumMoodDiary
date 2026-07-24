# superpowers-en 视角审计 (v2, 2026-07-21 第二轮)

> 审计基线：v0.22 round 36 / schemaVersion 12 / 178 commit / 748 test cases / 0 analyze issue
> 工具：grep-first + `dart scripts/check_all.dart` (✅) + `python scripts/check_cross_feature.py` (✅) + `python scripts/check_arb_keys.py` (6 missing) + `python scripts/check_datetime_race.py` (5 false-positive)
> 上次审计（v1, 7/20）后已修 9 轮 (round 28-36)，本轮聚焦"剩余 + 新发现"

---

## 1. 顶层架构审视（5 条）

### 1.1 CI 守门员脚本已扩展到 5 个，但 datetime race 脚本规则需改进 ⭐⭐⭐
- **现状**：
  - `dart scripts/check_all.dart` (purity + consistency) ✅
  - `python scripts/check_cross_feature.py` (49 → 50 files, 0 violation) ✅
  - `python scripts/check_arb_keys.py` (zh 555 / en 549, 6 missing) ✅ 抓到 round 33 漏 en
  - `python scripts/check_datetime_race.py` (5 "race" — 全部误报)
  - `python scripts/check_drift_namespace.py` ✅
  - `python scripts/check_fullwidth_punctuation.py` ✅
- **datetime race 误报分析**（5 文件）：
  - `medications_list_widget.dart:233` — 函数入口 `final now = DateTime.now();` ✅ 正确
  - `app_database.dart:456` — `final now = DateTime.now();` 后用 `now.year/month/day` ✅
  - `notification_service.dart:415` — `final now = DateTime.now();` ✅
  - `reminder_scheduler.dart:82` — `final now = DateTime.now();` ✅
  - `safety_watch_service.dart:145` — 函数接收 `now` 参数 ✅
  - **脚本规则问题**：`if 'DateTime.now()' in line` 把 `now.xxx` 也算上（因为 `now.year` 包含 `now` 但不算 `DateTime.now()`）。实际**所有 5 处都已经按 v0.16 round 19 修过**。
- **改法**：脚本改为"5 行窗口内 `DateTime.now()` 字面量 ≥2 次"，排除 `now.xxx`。
- **改造成本**：🟢 15 分钟
- **用户感知收益**：⭐ — CI 误报会让"真 race 漏过"被忽视

### 1.2 swallowError 集中器已 49 处，但 catch (_) 8 处剩 5 处合理 + 2 处应走集中器 ⭐⭐
- **现状**：v0.17 round 14 引入 swallowError + v0.22 round 30 (023d6ef) 迁 6 处 best-effort 后，目前 **49 处调用**。但 `catch (_)` 仍 8 处：
  - ✅ `data_export_service.dart:199, 204, 210` schema guard（注释加 ignore 注释，合理）
  - ✅ `json_codec.dart:37` 解析容错（"宁愿空也不能崩"）
  - ✅ `domain/logic/assessment_record.dart:51` 解析容错（返回 null）
  - ✅ `medication_times.dart:32` mapper 容错（返回 const []）
  - ⚠️ `settings_page.dart:520` 写历史失败（注释"不影响主流程"，**应走 swallowError**）
  - ⚠️ `notification_status_card.dart:106` web PlatformException（**应走 swallowError**）
- **改法**：2 处换 `swallowError(where: '...', error: e, stack: st)`。10 分钟。
- **改造成本**：🟢 10 分钟
- **用户感知收益**：⭐⭐ — dev mode 能看到清理失败日志

### 1.3 Flutter widget test 缺 golden / visual regression ⭐
- **现状**：748 test cases 全是 unit / widget / round-trip，**0 golden test**。一旦调整主题 token 颜色 / 间距 / 字体，唯一回归手段是手动截图。
- **改法**：3-5 个关键 page（home / vent / medication / trend / settings）加 golden test。
- **改造成本**：🟠 1-2 天
- **用户感知收益**：⭐ — 长期项目资产

### 1.4 5 个 god class 仍未拆（P0-2 mood_dialog 838 行 / P1-1 notification_service 631 行） ⭐⭐
- 见 emil 报告 1.1 + 1.2。
- 现状：mood_dialog 838 / settings_page 681 / notification_service 631 / assessment_history_page 624 / trend_charts 595 / medications_list_widget 536 / vent_compose_page 530。
- v0.22 round 35 (spen) 已拆 `reminders_hub_page` 16401 bytes → 450 行 + 5 个 card，**是 god class 拆解的样板**。
- 改法：mood_dialog 优先（最大 + 状态机复杂），其他 5 个下个 sprint 排期。

### 1.5 隐式排序假设 + Notification id cancel range 全部已修（"v0.16 round 19" 教训彻底沉淀） ⭐
- **现状**：上次报告 5 处隐式排序修过 + 上次新发现 1 处 P0（reminder_scheduler:103）。本轮 grep `.first/.last` 6 处命中，**全部已经显式 sort**：
  - `care_engine.dart:78 sort + :79 first.timestamp` ✅
  - `streak_calculator.dart:39 sort + :46 first` ✅
  - `streak_calculator.dart:95 first`（在 sort 后）✅
  - `reminder_scheduler.dart:48 sort + :49 first` ✅
  - `assessment_comparison.dart:190-191 sort + :192 last` ✅
  - `day_detail.dart:237 parts.first`（**非时序数据**，OK）
- Notification id cancel range 200000（v0.16 round 19B 修过）✅
- DateTime.now() race 5 处全部已修（虽然脚本误报）✅
- `int.parse / DateTime.parse / double.parse` 0 处裸用（注释里有 2 处提及但实际代码 0 命中）✅
- `addListener 8 ↔ removeListener 8`（每个 addListener 都能找到对应 removeListener + dispose）✅
- `setState 100+ 命中`，mounted check 109 处覆盖（上次 27 → 109，**+82**）✅

---

## 2. 底层逐行排查

### 🔴 P0 — 必修（2 条）

| # | 位置 | 问题 | 修法 |
|---|------|------|------|
| 1 | `lib/l10n/app_en.arb` | 缺 6 个 OEM key（`notificationStatusCardOemBrandOthers/Samsung/StepOthers1-2/StepSamsung1-2`），v0.22 round 33 加 zh 时漏 en。`check_arb_keys.py` 已自动检测。 | 补 6 个 en 翻译。10 分钟。 |
| 2 | `lib/presentation/pages/mood/mood_dialog.dart` (838 行) | 加录音 + STT 后涨出来。状态机 7 字段 + 2 个 StreamSubscription + 4 维度评分。**真 god class**。 | 抽 4 子组件（`MoodScoreRow` / `MoodRecorder` / `MoodTags` / `MoodDialogActions`）。1-2 天。 |

### 🟡 P1 — 应修（10 条）

| # | 位置 | 问题 | 修法 |
|---|------|------|------|
| 3 | `core/data/services/notification_service.dart:631` | 仍 631 行（抽 BadgeSyncService -40、SnoozeManager -90 后还这么长）。6 类通知 + 权限 + 路由全在 facade。 | 抽 `MedicationNotifier` 200 行 + `AssessmentNotifier` / `RefillNotifier`。1-2 天。 |
| 4 | `settings_page.dart:520` + `notification_status_card.dart:106` | 2 处 best-effort catch (_) 绕开 swallowError。 | 换 `swallowError(where: '...', error: e, stack: st)`。10 分钟。 |
| 5 | `scripts/check_datetime_race.py` | 5 行窗口规则把 `now.year` 当 `DateTime.now()`，导致 5 个误报（实际都是真修了）。 | 改为 `DateTime.now()` 字面量正则匹配。15 分钟。 |
| 6 | 5 个 god class 候选（settings_page 681 / assessment_history_page 624 / trend_charts 595 / medications_list_widget 536 / vent_compose_page 530） | 单文件 500+ 行。 | 跟 mood_dialog 同样模板拆。1-2 天/file。 |
| 7 | 全部 `lib/presentation/pages/**/*.dart` (除 home / vent 已抽) | `Semantics()` 仅 6 处，重要 ListTile 大量无 a11y wrapper。 | 关键 ListTile 加 `Semantics(label: ..., button: true)`。1-2 天。 |
| 8 | 全部 `lib/presentation/pages/**/*.dart` | `ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(...)))` 55 处直接调用，AppSnackBar 集中器覆盖率 57%。 | 全部走 `AppSnackBar.xxx(context, ...)`。半天。 |
| 9 | `lib/main.dart:178-205` + `lib/presentation/widgets/empty_state.dart:9` + `error_state.dart:8` | 中文 hardcode（升级 dialog + 注释）。`empty_state` / `error_state` 注释可接受。 | 升级 dialog 11 处加 l10n key。1-2 小时。 |
| 10 | 缺 golden test | 748 cases 全是 unit / widget / round-trip，0 visual regression。 | 3-5 个关键 page 加 golden。1-2 天。 |
| 11 | `app_database.dart:68` schemaVersion=12 | 每次 schema++ 必做 dry-run migration smoke test（AGENTS.md "v0.16 round 19" 教训）。 | 加 `test/database_migration_round12_test.dart` dry-run 1→12 路径。半天。 |
| 12 | `flutter analyze` 0 issue 但仍有可继续清理的 info-level 警告 | 上次报告 3 info 已修（v0.22 round 30 + 31）。 | 当前 0，保持。 |

### 🟢 P2 — 应该改（下个 sprint）

| # | 位置 | 问题 | 修法 |
|---|------|------|------|
| 13 | `lib/presentation/pages/medication/widgets/medications_list_widget.dart` (536 行) | medication 列表 + edit + delete + refill 全在 1 个文件。 | 拆 `medication_list` + `medication_edit_dialog` + `medication_refill` 3 文件。1 天。 |
| 14 | `lib/presentation/pages/medication/medication_calendar_page.dart` (398 行) | 日历 + 当日 + 统计 + 状态切换。 | 拆 `med_calendar_header` + `med_day_detail` + `med_calendar_stats`。1 天。 |
| 15 | `lib/presentation/pages/assessment/assessment_history_page.dart` (624 行) | 历史 + 趋势图 + 周期提醒 + 详情。 | 拆 4 个 widget。1-2 天。 |
| 16 | `lib/core/data/services/notification_service.dart` (631 行) | 0 测试覆盖（widget 层 mock 掉）。 | 单测补 schedule 编排 + cancel range 公式。半天。 |
| 17 | `lib/core/data/services/safety_watch_service.dart` (360+ 行) | 失联检测核心，0 测试覆盖（widget 层 mock 掉）。 | 单测补 evaluateLevel + daysSince + cross-midnight。半天。 |
| 18 | `lib/core/data/services/assessment_reminder_service.dart` | 心理评估周期提醒，0 测试覆盖。 | 单测补 schedule 编排 + 同款 cross-midnight。半天。 |
| 19 | `lib/core/data/services/badge_sync_service.dart` | v0.22 round 30 抽出，但缺单测。 | 单测补。1h。 |
| 20 | `lib/core/data/services/snooze_manager.dart` | 5KB 单文件 0 测试。 | 单测补 id 公式 + cancel range。1h。 |
| 21 | `lib/presentation/pages/vent/vent_compose_page.dart` (530 行) | 录音 + 编辑 + 播放 + 提交。 | 拆 `vent_audio_recorder` + `vent_audio_player` + `vent_compose_form`。1-2 天。 |
| 22 | `lib/presentation/pages/trend/trend_charts.dart` (595 行) | 4 种图（line/bar/heatmap/empty state）。 | 拆 4 个子文件（之前 placeholder 已删除，注释说留 trend_charts 是因 SpotKey typedef 来自 fl_chart 未导出。已修 `trend_utils.dart`？需 verify）。半天。 |

### ⚪ P3 — 锦上添花
- **P3-1**. 文档 drift 监控：AGENTS.md 已知坑 13 条已 100% 修过（v0.16 round 19/19B / v0.16 round 19B DateTime race / v0.16 round 20 国产 ROM / v0.17 round 1-4 / v0.17 round 8 shader），AGENTS.md 没更新"已修条目可移除"——可加个 "已沉淀" vs "活跃坑" 标记
- **P3-2**. `DateTime.now()` 73 处散落 35 文件，5 处"真 race"全修，但仍可在 CI 加 `prefer_early_return_to_capture_time` 自定义 lint
- **P3-3**. `legal_page.dart:64-67` `SnackBar(content: Text(withdraw ? '已撤回 (1/3)' : '已重新同意 (1/3)'))` — 2 个 l10n key 缺
- **P3-4**. `legal_page.dart` 协议版本号 `v0.22-2026-08-01` 跟 pubspec.yaml version 字段未自动同步
- **P3-5**. `core/data/services/data_export_service.dart:488` (488 行) — 导出 + 加密 + 音频 + JSON schema 全在 1 个 service
- **P3-6**. `core/theme/app_tokens.dart` 483 行 — token 集中器本身偏厚，但功能完整
- **P3-7**. `setup_page.dart:429` (429 行) — 4 步骤全在 1 个 state，state 字段多
- **P3-8**. `core/data/services/medication_report_pdf.dart` (488 行) — PDF 端 god class

---

## 3. 整体评级
**A-**。上次报告 5 处 P0/P1 全部修完（隐式排序 6 处全部 sort / 时区 2 处漏修全 toUtc / 吞错 6 处 best-effort 走 swallowError / 3 个 flutter analyze info / vent 隐私边界），**新发现 1 条 P0 (l10n 6 个 OEM key 缺 en)** + 5 个 god class 待拆 + a11y / ScaffoldMessenger 集中器覆盖率待提升。

## 4. 关键 3 个发现
1. 🔥 **P0-1 l10n**：en.arb 缺 6 个 OEM key（round 33 加 zh 时漏 en），`check_arb_keys.py` 已自动检测。10 分钟修。
2. 🔥 **P0-2 结构**：mood_dialog 838 行 god class 拆 4 子组件，1-2 天。
3. ⚠️ **脚本误报风险**：datetime race 脚本 5 行窗口规则把 `now.year` 当 `DateTime.now()`，5 个误报 = 真 race 漏过风险。15 分钟改正则。
