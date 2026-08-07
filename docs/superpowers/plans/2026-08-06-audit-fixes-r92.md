# 6 视角审计修复 (R92 阶段 1) — Implementation Plan

> v0.30 round 92 (sub-spec 8) — 阶段 1
> Spec: `docs/superpowers/specs/2026-08-06-audit-fixes-r92-design.md` (16423 bytes)
> Plan author: Mavis (R84-R91 SDD 流程延续)
> Plan date: 2026-08-06

## Goal

按 6 视角审计 (总 410KB / 6.5 万字) 阶段 1 修复, **20 项 P0 上架 blocker + 物理残留 + 半成品**, 6 task, 1-2 周。

## Architecture (沿用 R91 风格)

- 4 层架构 + 5 子层 umbrella, 不动
- TDD 风格, 写失败 test → 跑红 → 写实现 → 跑绿 → commit
- 1 task 1-2 commit, 跟项目自定 `<version> round <N> (xxx): <title>` 风格
- baseline 1627 pass / 0 fail
- master commit: cf91020 (R91 集成后)

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- `domain/` 0 flutter 0 drift 0 data (守门员 `check_all.dart` 跑过)
- 17 守门员脚本 (R60 后 +1 `check_16kb_alignment.py`)
- 跨 feature import 守门 (`check_cross_feature.py`)
- ARB key 同步 (3 语 zh / en / zh_Hant, `check_arb_keys.py` 跑过)
- 中文 commit 风格 (跟 AGENTS.md 习惯)

## File Structure

### 新增
- `lib/presentation/pages/crisis_hotline_page.dart` (homeFabHotline 真路由)
- `lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart` (拆 god page)
- `lib/presentation/pages/assessment/widgets/assessment_result_panel.dart`
- `lib/presentation/pages/assessment/widgets/assessment_progress_header.dart`
- `lib/presentation/pages/daily_tracking/treatment_page.dart` (R91 placeholder 替换)
- `lib/presentation/pages/daily_tracking/widgets/treatment_add_dialog.dart`
- `lib/presentation/pages/daily_tracking/widgets/treatment_list.dart`
- `test/core/data/database/vent_content_text_drop_round92_test.dart`
- `test/presentation/pages/mood/cbt_wizard_save_round92_test.dart`
- `test/presentation/pages/home/home_fab_toolbar_round92_test.dart`
- `test/presentation/pages/assessment/assessment_center_chart_round92_test.dart`
- `test/presentation/pages/assessment/assessment_page_split_round92_test.dart`
- `test/presentation/pages/daily_tracking/treatment_page_round92_test.dart`
- 5+ catch (_) test 各加 1 case

### 修改
- `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105` (5/7 栏 save 修复)
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:84-104` (2 个 FAB 真功能)
- `lib/presentation/pages/assessment/assessment_center_page.dart:64-67` (顶部 chart)
- `lib/presentation/pages/assessment/assessment_page.dart` (拆 3 sub-widget)
- `lib/core/data/database/app_database.dart` (schemaVersion 18→19 + onUpgrade)
- `lib/core/data/database/tables/vent/vent_entries.dart` (DROP contentText 列)
- `lib/core/shared/logger.dart` (新增 `swallowError` 集中器, 如不存在)
- 11 处 catch (_) (9-10 个文件)
- `AGENTS.md` (17 守门员补)
- 6 份文档 "App" 混用
- 14 文件 45 处硬编码中文 → 走 l10n
- `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` (启用 → 去 .disabled)
- `docs/CHANGELOG.md` (增 R92 entry)

### 删除
- 10 项物理残留
- `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart`
- catch (_) 改写时同步删冗余

## Tasks (6 task, 1-2 周, 估 23 commit)

### Task 1: 物理残留清理 + 启用 aliyun_sms test (0.5d, 5 commit)

**Step 1.1 (TDD 不需要, 直接干)**:
- 软删 `.worktrees/feat-cbt-thought-report/` (按 memory `mavis-trash` 模式, 7 天后真删)
- 软删 `.r61_backup_20260731_101630/` (1.7MB)
- 软删 `.r61_backup_logs/` (2.6MB)
- 软删 `mimo.exe` (128MB)
- 软删 `flutter_01.log` (5KB)
- 软删 `todo.md` (723 bytes)
- 软删 `commit_msg_r56c3/r56d/r56e/r56g/r56h` + `.commit_msg_agents.md` + `.commit_msg.txt`
- 软删 `docs/superpowers/sdd-logs/round90-assessment-center/sdd/` 17 .py + __pycache__/ + 17 .py.tmp

**Step 1.2 (TDD 不需要, 直接干)**:
- `chroniccare.iml` 加 `.gitignore` (`echo 'chroniccare.iml' >> .gitignore`)

**Step 1.3 (TDD 跑通)**:
- `git mv test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled test/core/data/services/aliyun_sms_provider_round92_test.dart`
- 跑 `flutter test test/core/data/services/aliyun_sms_provider_round92_test.dart` → 应该 pass (R57 写过)
- 不需要改实现, 只改文件名 + 加 `round92_test` 标记

**Step 1.4 (验证)**:
- `git status --short` 看 10 项物理残留都 untracked
- `flutter test test/core/data/services/aliyun_sms_provider_round92_test.dart` pass

**Step 1.5 (commit)**:
- `git add .gitignore test/ docs/superpowers/sdd-logs/round90-assessment-center/sdd/` (软删项用 `git rm --cached`)
- `git commit -m "v0.30 round 92 (cleanup): 10 物理残留 + chroniccare.iml .gitignore + 启用 aliyun_sms R57 test"`

### Task 2: 3 个 P0 半成品 widget 修复 (3-5d, 6 commit)

#### Step 2.1: CBT wizard 5/7 栏 save 修复

**Step 2.1.1 (TDD 红)**:
- 写 `test/presentation/pages/mood/cbt_wizard_save_round92_test.dart`
  - ProviderScope override `cbtDraftProvider` + `cbtEntryRepositoryProvider`
  - pump CBT wizard, 走完 5 栏, 点"完成"
  - 验证 `cbtEntryRepository.add(...)` 被调 1 次 (不是 0)
  - 验证 wizard pop 后 entry 落库

**Step 2.1.2 (跑红)**:
- `flutter test test/presentation/pages/mood/cbt_wizard_save_round92_test.dart` → fail (现 onPressed 是 `Navigator.pop()`, 不调 save)

**Step 2.1.3 (实现)**:
- 改 `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105`
  - onPressed: `ref.read(cbtDraftProvider.notifier).save().then((_) => Navigator.pop(context))`
  - 加 ref import (ConsumerStatefulWidget)
  - 加 error handling (try/catch → snackbar + 不 pop)

**Step 2.1.4 (跑绿)**:
- `flutter test test/presentation/pages/mood/cbt_wizard_save_round92_test.dart` → pass

**Step 2.1.5 (commit)**:
- `git add lib/presentation/pages/mood/widgets/cbt_wizard.dart test/presentation/pages/mood/cbt_wizard_save_round92_test.dart`
- `git commit -m "v0.30 round 92 (fix): CBT wizard 5/7 栏完成按钮触发 save, 字段不丢"`

#### Step 2.2: homeFabHotline / homeFabTop 真功能

**Step 2.2.1 (TDD 红)**:
- 写 `test/presentation/pages/home/home_fab_toolbar_round92_test.dart`
  - tap homeFabHotline → 跳 `/crisis-hotline` 路由
  - tap homeFabTop → Scrollable.ensureVisible 到 `_scrollController.position.minScrollExtent`
  - 不再 snackbar info stub

**Step 2.2.2 (跑红)**:
- `flutter test test/presentation/pages/home/home_fab_toolbar_round92_test.dart` → fail (现 onPressed 是 `AppSnackBar.showInfo`)

**Step 2.2.3 (实现)**:
- 改 `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:84-104`
  - homeFabHotline onPressed: `context.push('/crisis-hotline')`
  - homeFabTop onPressed: `Scrollable.ensureVisible(_scrollController.position.context, duration: durNormal, curve: curveStandard)`
  - 需要 ref `_scrollController` (HomePage 已传过来, 或 ProviderScope override)
- 新增 `lib/presentation/pages/crisis_hotline_page.dart` (R75 hotlineByRegion 路由)
  - 复用 R75 `lib/domain/entities/hotline.dart` + `lib/l10n/app_zh.arb` (hotlineByRegion)
  - 5 地区 (大陆 / 香港 / 台湾 / 美国 / 国际) + 800-810-1117

**Step 2.2.4 (跑绿)**:
- `flutter test test/presentation/pages/home/home_fab_toolbar_round92_test.dart` → pass

**Step 2.2.5 (commit x2)**:
- `git commit -m "v0.30 round 92 (fix): homeFabHotline / homeFabTop 真功能 (路由 + Scrollable.ensureVisible)"`
- `git commit -m "v0.30 round 92 (i18n): crisis_hotline_page + 5 地区热线 ARB"`

#### Step 2.3: assessment_center 顶部 mini 趋势图

**Step 2.3.1 (TDD 红)**:
- 写 `test/presentation/pages/assessment/assessment_center_chart_round92_test.dart`
  - pump assessment_center_page
  - 验证顶部 chart 渲染 (不是 SizedBox)
  - 验证 chart 走 assessmentHistoryProvider

**Step 2.3.2 (跑红)**:
- `flutter test test/presentation/pages/assessment/assessment_center_chart_round92_test.dart` → fail (现顶部是 SizedBox)

**Step 2.3.3 (实现)**:
- 改 `lib/presentation/pages/assessment/assessment_center_page.dart:64-67`
  - `const SizedBox.shrink()` → `AssessmentMultiLineChart(provider: ..., height: 80)` 复用 R90 widget

**Step 2.3.4 (跑绿)**:
- `flutter test test/presentation/pages/assessment/assessment_center_chart_round92_test.dart` → pass

**Step 2.3.5 (commit)**:
- `git commit -m "v0.30 round 92 (ui): assessment_center 顶部 mini 趋势图 (复用 R90 chart widget)"`

#### Step 2.4: treatment_placeholder 真页面

**Step 2.4.1 (TDD 红)**:
- 写 `test/presentation/pages/daily_tracking/treatment_page_round92_test.dart`
  - pump treatment_page
  - 验证 ListView 显示已有 entry
  - tap + button → AddTreatmentDialog
  - 填表 → save → entry 落库 + list 更新

**Step 2.4.2 (跑红)**:
- `flutter test test/presentation/pages/daily_tracking/treatment_page_round92_test.dart` → fail (现文件不存在 / placeholder)

**Step 2.4.3 (实现)**:
- 新增 `lib/presentation/pages/daily_tracking/treatment_page.dart` (300 行)
  - State (selected date / entries)
  - ListView (按日期分组)
  - + FAB → AddTreatmentDialog
- 新增 `lib/presentation/pages/daily_tracking/widgets/treatment_add_dialog.dart` (200 行)
  - 4 字段: date / category (4 选 1) / provider (String) / note (String)
- 新增 `lib/presentation/pages/daily_tracking/widgets/treatment_list.dart` (150 行)
  - SectionHeader (按月) + AppListTile (entry)
- 复用 `PageScaffold` + `SectionHeader` + `AppListTile` + `EmptyState`
- 删 `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart`

**Step 2.4.4 (跑绿)**:
- `flutter test test/presentation/pages/daily_tracking/treatment_page_round92_test.dart` → pass

**Step 2.4.5 (commit)**:
- `git commit -m "v0.30 round 92 (ui): treatment_page 真页面 (R91 placeholder 替换) + 4 字段 AddDialog"`

### Task 3: 文档同步 (1d, 4 commit)

#### Step 3.1: AGENTS.md 17 守门员补

**Step 3.1.1**:
- 读 `AGENTS.md` "16 守门员清单" 章节
- 补 `check_16kb_alignment.py` (R60 后新增, AGENTS 漏列)
- 17 守门员 → 16 → 17 守门员

**Step 3.1.2 (commit)**:
- `git commit -m "v0.30 round 92 (docs): AGENTS.md 补 check_16kb_alignment.py (16→17 守门员)"`

#### Step 3.2: 6 份文档"App" 混用修

**Step 3.2.1**:
- 读 `core/l10n/strings.dart` L30/38/58/96
- 读 `assets/legal/sensitive_data_consent.md` L36/88/91
- 读 `assets/legal/privacy_policy.md` L73
- 读 `docs/SMS_PROVIDERS.md` L33
- 按 `docs/terminology.md §2` 统一名词
- "App" → "本应用" (中文) / "this app" (en) / "本應用" (zh_Hant)

**Step 3.2.2 (验证)**:
- `grep -rn '"App"\|"App"' lib/l10n/ assets/legal/ docs/SMS_PROVIDERS.md` → 0 命中
- 或保持小写 "App" (iOS 风格) → 看项目习惯

**Step 3.2.3 (commit)**:
- `git commit -m "v0.30 round 92 (docs): 6 文档 'App' 混用修 (按 terminology.md §2)"`

#### Step 3.3: 14 文件 45 处硬编码中文 → 走 l10n

**Step 3.3.1 (grep 找文件)**:
- `grep -rln 'Text(\u4e2d\u6587' lib/` 找 14 文件
- 实际 grep: `grep -rln 'Text(.[\u4e00-\u9fff]' lib/`

**Step 3.3.2 (走 l10n)**:
- 每个文件每处加 `AppLocalizations.of(context).xxxKey` 调用
- 缺 ARB key 加 zh/en/zh_Hant 翻译
- 跑 `flutter gen-l10n` 自动生成

**Step 3.3.3 (跑 check_strings_hardcoded 守门)**:
- 跑 `python scripts/check_strings_hardcoded.py` → 0 violation

**Step 3.3.4 (commit x2)**:
- `git commit -m "v0.30 round 92 (i18n): 14 文件 45 处硬编码中文 → 走 l10n (新 12 ARB keys)"`
- `git commit -m "v0.30 round 92 (i18n): 3 lang 同步 + check_strings_hardcoded 守门 0 violation"`

#### Step 3.4: 更新 R92 CHANGELOG entry

**Step 3.4.1**:
- 读 `docs/CHANGELOG.md` `[0.30.0]` 章节
- 增 R92 section: "**v0.30 round 92 (audit-fixes)**: 6 视角审计 410KB → 20 项 P0 修复; 物理残留 10 项清理; 3 个 P0 半成品 widget 修复; 文档同步; vent contentText DROP; 11+ 处 catch (_) 集中器化; 拆 1 个 600+ 行 god page; ..."

**Step 3.4.2 (commit)**:
- `git commit -m "v0.30 round 92 (docs): CHANGELOG [0.30.0] 增 R92 entry"`

### Task 4: vent contentText DROP + aliyun_sms test 启用 (1-2d, 4 commit)

#### Step 4.1: vent schemaVersion 18→19

**Step 4.1.1 (TDD 红)**:
- 写 `test/core/data/database/vent_content_text_drop_round92_test.dart`
  - 4 case: 0→19 / 8→19 / 18→19 / 19→19 (新装)
  - 验证升级后 vent_entries 表没 `contentText` 列
  - 验证升级后 entry 仍能读 (`encryptedContent` 解密正常)

**Step 4.1.2 (跑红)**:
- `flutter test test/core/data/database/vent_content_text_drop_round92_test.dart` → fail (现 schemaVersion=18, 没 DROP)

**Step 4.1.3 (实现)**:
- 改 `lib/core/data/database/app_database.dart`:
  - `schemaVersion = 19` (从 18 升)
  - `onUpgrade: (m, from, to) async { ... if (from >= 8 && from < 19) { await m.alterTable(TableMigration(ventEntries, columnTransformer: { ventEntries.contentText: Constant<String?>(null) })); } ... }`
- 改 `lib/core/data/database/tables/vent/vent_entries.dart`:
  - 删 `TextColumn get contentText => text().nullable()();`
  - 删 mapper 引用 (R21 之后 mapper 都不用 contentText)

**Step 4.1.4 (跑 build_runner)**:
- `dart run build_runner build --delete-conflicting-outputs`

**Step 4.1.5 (跑绿)**:
- `flutter test test/core/data/database/vent_content_text_drop_round92_test.dart` → pass

**Step 4.1.6 (commit)**:
- `git commit -m "v0.30 round 92 (schema): vent contentText DROP (schemaVersion 18→19, onUpgrade 一次性清理)"`

#### Step 4.2: aliyun_sms test 启用 (跟 task 1 一起做)

(见 task 1.3)

### Task 5: 11+ 处 catch (_) 改 swallowError 集中器 (2d, 5 commit)

#### Step 5.1: 写 swallowError 集中器 (如不存在)

**Step 5.1.1 (TDD 红)**:
- 找 `lib/core/shared/logger.dart` 或 `lib/core/shared/swallow_error.dart`
- 如不存在, 写 `test/core/shared/swallow_error_round92_test.dart`
  - swallowError(where: 'a:b', error: e) → log + 不抛
  - swallowError(where: 'a:b', error: e, level: 'warning') → log warning
- 跑红

**Step 5.1.2 (实现)**:
- 新增 `lib/core/shared/swallow_error.dart`
  ```dart
  void swallowError({
    required String where,
    required Object error,
    StackTrace? stackTrace,
    String level = 'error',
  }) {
    // 用 developer.log 记录
    developer.log(
      'Swallowed: $where',
      name: 'swallowError',
      error: error,
      stackTrace: stackTrace,
    );
  }
  ```
- 跑绿

**Step 5.1.3 (commit)**:
- `git commit -m "v0.30 round 92 (refactor): 新增 swallowError 集中器 (R17 模式)"`

#### Step 5.2: 11 处 catch (_) 改 swallowError

**Step 5.2.1 (grep 找)**:
- `grep -rn 'catch (_)' lib/` 列 11+ 位置

**Step 5.2.2 (改)**:
- 每个文件:
  ```dart
  // 改前
  } catch (_) {
    // fallback 逻辑
  }
  // 改后
  } catch (e, st) {
    swallowError(where: '<file>:<line>', error: e, stackTrace: st);
    // fallback 逻辑
  }
  ```
- 11 处涉及 9-10 文件:
  - `lib/core/data/database/daos/assessment_dao.dart:137`
  - `lib/core/data/database/mappers/medication/medication_times.dart:54`
  - `lib/core/data/services/data_export_service.dart` (1-2 处)
  - `lib/core/data/services/export/export_schema_service.dart` (3 处)
  - `lib/core/shared/json_codec.dart`
  - `lib/core/theme/theme_provider.dart`
  - `lib/domain/logic/assessment_record.dart`
  - `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart`
  - `lib/presentation/pages/mood/widgets/mood_recorder_page.dart`
  - (1-2 处其他, 跑 grep 找)

**Step 5.2.3 (加 test)**:
- 每个文件对应 round92 test 加 1 case: 抛异常 → swallowError 调 → 业务 fallback 走

**Step 5.2.4 (跑守门员)**:
- `grep -rn 'catch (_)' lib/` → 只剩 `swallowError` 自身
- 跑 `flutter test` baseline pass

**Step 5.2.5 (commit x4)**:
- 4 个 commit 按文件 group:
  - `git commit -m "v0.30 round 92 (refactor): assessment_dao + medication_times catch (_) → swallowError"`
  - `git commit -m "v0.30 round 92 (refactor): data_export_service + export_schema_service (4 处) catch (_) → swallowError"`
  - `git commit -m "v0.30 round 92 (refactor): json_codec + theme_provider catch (_) → swallowError"`
  - `git commit -m "v0.30 round 92 (refactor): assessment_record + weight_widgets + mood_recorder_page catch (_) → swallowError"`

### Task 6: 拆 1 个 600+ 行 god page (assessment_page) (2-3d, 4 commit)

#### Step 6.1: 写 snapshot test (baseline)

**Step 6.1.1 (TDD 红 → 绿)**:
- 写 `test/presentation/pages/assessment/assessment_page_split_round92_test.dart`
  - pump assessment_page (3 个状态: 答题中 / 结果 / 危机)
  - snapshot 3 个状态
  - 跑绿 (旧 god page 渲染快照)

**Step 6.1.2 (commit)**:
- `git commit -m "v0.30 round 92 (test): assessment_page 3 状态 snapshot test (拆前 baseline)"`

#### Step 6.2: 拆 QuizPanel

**Step 6.2.1 (TDD)**:
- 写 test 验证 QuizPanel 独立渲染 (跟原 god page 一致)

**Step 6.2.2 (实现)**:
- 新增 `lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart`
  - 答题 widget (题目 / 选项 / 进度 / 下一题)
- 改 `lib/presentation/pages/assessment/assessment_page.dart`
  - 答题 widget → `QuizPanel(...)`

**Step 6.2.3 (跑绿)**:
- snapshot test 验证 UI 一致

**Step 6.2.4 (commit)**:
- `git commit -m "v0.30 round 92 (refactor): assessment_page 拆 QuizPanel (436 → 350 行)"`

#### Step 6.3: 拆 ResultPanel

(同 6.2 模式)

#### Step 6.4: 拆 ProgressHeader

(同 6.2 模式)

#### Step 6.5: 最终验证

- `flutter analyze` 0 error
- `flutter test` baseline 1627 → 1650+ pass
- `wc -l lib/presentation/pages/assessment/assessment_page.dart` < 200 行
- 17 守门员全绿

## Pre-existing baseline (跑前必记)

- master commit: cf91020 (R91 集成后)
- baseline 1627 pass / 0 fail (R91 + I-1/I-2 fixes)
- 17 守门员全绿 (worktree bootstrap 后)

## 验收标准 (按 spec §7)

- `flutter analyze` 0 error / 0 warning
- `flutter test` baseline 1627 → ≥1650 pass
- 17 守门员脚本全绿
- `grep -rn 'catch (_) {' lib/` → 0 (除 `swallowError` 自身)
- `grep -rn 'TODO (Task' lib/` → 0 命中 (3 个 P0 半成品 TODO 注释移除)
- `grep -rn '硬编码中文' lib/` → 0 命中 (14 文件 45 处走 l10n)
- 物理残留 10 项 0 命中
- `wc -l lib/presentation/pages/assessment/assessment_page.dart` < 200

## 风险与缓解 (按 spec §6)

| # | 风险 | 缓解 |
|---|------|------|
| 1 | vent schemaVersion 升级漏写 migration | onUpgrade 加 `if (from >= 8 && from < 19)` 双保险 + 4 测试覆盖 |
| 2 | CBT wizard 改后父 save 双触发 | Provider scope 走 state 隔离 + 1 test 验证只触发 1 次 |
| 3 | 11 处 catch (_) 改后漏 1 处 | grep 守门员 `} catch (_) {` 跑 0 |
| 4 | god page 拆完 UI 不一致 | snapshot test 验证 |
| 5 | 14 文件 45 处硬编码中文 l10n 后 overflow | 走现有 ARB key 优先, 缺 key 加 R92 提交 |
| 6 | treatment_page 跟 mood / medication FK | R92 不加 FK (跟 R91 一致) |
| 7 | 物理残留删错文件 | 软删 (`mavis-trash` 模式, 7 天后真删) |
| 8 | worktree .gitignore 状态不同步 | merge 前跑 baseline test |

## 一句话总结

按 6 视角审计 (总 410KB) 合并的 **20 项 P0 阶段 1 修复**, 6 task, 1-2 周, 估 23 commit, 1627 → 1650+ tests pass。
