# 6 视角审计修复 (R92 阶段 1) — Design Spec

> v0.30 round 92 (sub-spec 8) — 阶段 1
> Spec author: Mavis (R84-R91 SDD 流程延续)
> Spec date: 2026-08-06
> 审计材料: `docs/audit/2026-08-06/0[0-6]-*-report.md` (410 KB / 6.5 万字 / 6 视角)

## 1. Goal

按 6 视角 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-spec) 审计的 **P0 上架 blocker + 物理残留 + 半成品** 阶段 1 修复, **跳过所有外部依赖** (签名 / 域名 / 法务 / 阿里云 / Mac / 5 厂商 push), 只跑纯代码 / 文档 / 测试 / 架构改动。

**R92 是阶段 1 子集 (R92/R93/R94 三连击的 Round 1)**:
- R92 (本 spec): 阶段 1, 20 项 S 难度, 1 周
- R93 (后续 spec): 阶段 2, 20 项 M 难度, 1-2 周
- R94 (后续 spec): 阶段 3, 20 项 L 难度, 1-2 月 (含 IAP/Email 业务真接 + 拆 god service/facade + IAP/Email 真接)

## 2. 范围 vs 跳过

### 2.1 范围内 (阶段 1 20 项, S 难度)

#### A. 物理残留清理 (10 项, 0.5d)
1. `.worktrees/feat-cbt-thought-report/` R84 物理目录 (branch 已删)
2. `.r61_backup_20260731_101630/` (1.7MB) + `.r61_backup_logs/` (2.6MB) R61 backup 1.5 月残留
3. `.superpowers/sdd/` R89 没回收主目录
4. `mimo.exe` (128MB) 根目录残留
5. `flutter_01.log` (5KB) 根目录残留
6. `todo.md` (723 bytes) 根目录残留
7. `chroniccare.iml` (859 bytes) IntelliJ 项目文件, 应 `.gitignore`
8. `commit_msg_r56c3/r56d/r56e/r56g/r56h` + `.commit_msg_agents.md` + `.commit_msg.txt` R56 临时文件
9. `docs/superpowers/sdd-logs/round90-assessment-center/sdd/` 17 .py + __pycache__/ + 17 .py.tmp R90 残留
10. `test/core/data/services/aliyun_sms_provider_round57_test.dart.disabled` 启用

#### B. 3 个 P0 半成品 widget 修复 (4 项, 3-5d)
11. **CBT wizard 5/7 栏"完成"按钮触发父 save** (字段不丢)
12. **homeFabHotline 真功能** (R75 hotlineByRegion 已有, 接真路由)
13. **homeFabTop 真功能** (Scrollable.ensureVisible 回到主页顶端)
14. **assessment_center_page 顶部 mini 趋势图** (复用 R90 `AssessmentMultiLineChart` widget, 去掉 TODO SizedBox)
15. **treatment_placeholder.dart 真页面** (R91 task 3 集成入口, 治疗记录 7 子功能, 移除占位)

#### C. 文档同步 (3 项, 1d)
16. **AGENTS.md 漏列守门员补** (`check_16kb_alignment.py` 17 守门员, AGENTS 写 16)
17. **6 份文档"App" 混用修** (按 `terminology.md §2`, 改"App" 统一名词, 涉及 `core/l10n/strings.dart` L30/38/58/96 + `sensitive_data_consent.md` L36/88/91 + `privacy_policy.md` L73 + `SMS_PROVIDERS.md` L33)
18. **14 文件 45 处硬编码中文 → 走 l10n key** (R56+ R84+ review 漏, 涉及多 file)

#### D. vent contentText DROP + schemaVersion 升级 (2 项, 1-2d)
19. **vent 旧 `contentText` TEXT 列 DROP** (明文 + 加密双份存在, PIPL §28 泄露风险, schemaVersion 18→19, onUpgrade 写一次性清理)
20. **`aliyun_sms_provider_round57_test.dart.disabled` 启用** (R57 写, 至今未启用)

#### E. 架构收尾 (2 项, 2-3d)
21. **11+ 处 `catch (_) { ... }` 静默吞错 → `swallowError(...)` 集中器** (R17 模式, 涉及 `lib/core/data/database/daos/assessment_dao.dart:137` + `mappers/medication/medication_times.dart:54` + `data_export_service.dart` + `export/export_schema_service.dart`(3 处) + `json_codec.dart` + `theme_provider.dart` + `assessment_record.dart` + `weight_widgets.dart` + `mood_recorder_page.dart` + 1-2 处其他)
22. **拆 1 个 600+ 行 god page** (R95+ 再拆剩下 2 个, R92 拆 1 个降低风险, 选 `assessment_page.dart:436` 最熟)

### 2.2 跳过范围 (R93+ 处理)

#### 上架材料 / 外部资源 (阶段 2 部分)
- iOS 33 张截图 + AppIcon 1024 (设计师)
- iOS DEVELOPMENT_TEAM 填 (Apple Developer 账号)
- iOS fastlane/Appfile 4 ID 填 (Apple Developer 账号)
- iOS Podfile 真生成 (Mac 跑 `pod install`)
- iOS Dark Mode App Icon 4 套 (设计师)
- iOS LaunchImage.png 3 个占位删 (5min)
- iOS iCloud Backup 排除 (0.5d)
- iOS description.txt 改文案 (0.5d)
- 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
- 邮箱 `support@chroniccare.app` / `privacy@chroniccare.app` 注册
- Android keystore + Play App Signing (R72 脚本 + 你跑)
- TestFlight 跑 1 周期 (Mac + 2 tester)
- 5 厂商 push SDK 接入 (1-2 月审核)
- 阿里云 SMS 真接 (法务 1-2 月模板审核 + 阿里云 AccessKey)
- 3 份法律 md 律师过审 (¥45-90k)
- 文网文 / 互联网药品信息服务资格
- 软件著作权 / ICP 备案 / NMPA / HIPAA / GDPR
- 算法备案 (网信办) — 失联检测算法

#### 业务真接 (阶段 3 部分)
- IAP 8 元买断真接 (App Store Connect productId)
- SendGrid Email 真接
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 留 v1.0
- NSESSS / CRDPSS 2 量表 TODO
- 鸿蒙 / HarmonyOS NEXT 适配

#### 大量 P1/P2/P3 (60+ 项, R95+ 排期)
- 158 处 TextStyle 残留 (40% magic)
- 162 处 EdgeInsets 残留
- 50+ Duration + 50+ Curves 残留 (~30%)
- 主页 hero illustration / 主页 8 widget 堆叠重排
- 紧急联系人 5 步 → 3 步
- 数据导出 5 步 → 3 步
- notification_status_card 17 步纯文字加图
- 拆 2 个 600+ 行 god page (medication_calendar / data_management_section)
- 拆 3 facade (notification / safety_watch / data_export)
- 集成测试 1 → 3-5 个
- 18+ service 子类 sub-service 测试
- coverage 阈值 (≥ 70% domain / 50% data)
- ...

## 3. 架构决策

### 3.1 整体策略

按总报告 6 视角合并结论:
- **不重设顶层架构**: 4 层 + 5 子层 umbrella 已成
- **不拆 facade**: R92 只做收尾, R95+ 拆
- **不拆 2 个 600+ 行 god page**: R92 只拆 1 个 (assessment), 降低风险
- **TDD 维持**: 跟 R84-R91 风格一致, 红 → 绿 → commit

### 3.2 vent contentText DROP 设计 (P0 #19)

**风险**: vent 旧 `contentText` TEXT 列是 R21 之前 R0 早期版, R21 P0-1 升级到 `encryptedContent` BLOB 列后, 老 entry 同时有 contentText (明文) + encryptedContent (加密) 双份存在 DB。device root / backup 偷走 → PIPL §28 泄露。

**schemaVersion 升级**:
- `from < 19` → 删除 `contentText` TEXT 列
- `onUpgrade: (m, from, to) async { ... case 18: await m.alterTable(TableMigration(...)) ... }`
- 加 `if (from >= 8 && from < 19)` 判断覆盖 R21-P0-1 (8→9 是 vent 加密那次)

**测试**:
- `test/core/data/database/vent_content_text_drop_round92_test.dart` (R21 升级路径 + 新装用户)
- 验证升级后 vent_entry 表没 `contentText` 列
- 验证升级后 entry 仍能读 (`encryptedContent` 解密正常)

### 3.3 CBT wizard 5/7 栏"完成" 修复设计 (P0 #11)

**现状**: `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105` "完成" FilledButton → `Navigator.pop()`, **不调用父 save**。注释承认 "wizard 只负责关闭 dialog, 父组件 dispose 会 reset cbtDraftProvider"。

**修法**:
- 改 onPressed: 调 `ref.read(cbtDraftProvider.notifier).save()` → 触发父 widget watch
- 父 widget dispose 才 reset, 不在 pop 时重置
- 验证 7 栏全部完成后 entry 落库

**测试**:
- `test/presentation/pages/mood/cbt_wizard_save_round92_test.dart` (5/7 栏 + 7/7 栏完成都触发 save)

### 3.4 homeFabHotline / homeFabTop 真功能 (P0 #12, #13)

**homeFabHotline**:
- R75 已有 `hotlineByRegion` + `lib/domain/entities/hotline.dart`
- 接 `context.push('/crisis-hotline')` 路由 (新建)
- 5 地区心理危机热线 (R83.5 partial) + 800-810-1117 全国

**homeFabTop**:
- `Scrollable.ensureVisible(_scrollController.position.context, ...)` 回到主页顶端
- 加 200ms `curveStandard` 动画

**测试**:
- `test/presentation/pages/home/home_fab_toolbar_round92_test.dart` (验证 onPressed 不再是 stub)

### 3.5 assessment_center 顶部 mini 趋势图 (P0 #14)

**复用**: R90 `lib/presentation/widgets/charts/assessment_multi_line_chart.dart` (76 行, 12 量表)
- ProviderScope override `assessmentHistoryProvider` 拿最近 30 天数据
- 折线图 80dp 高 (跟 `spacingXl` 80 同值)
- 移除 `// TODO (Task 5)` 注释 + SizedBox

**测试**:
- `test/presentation/pages/assessment/assessment_center_chart_round92_test.dart` (验证 chart 渲染 + data flow)

### 3.6 treatment_placeholder 真页面 (P0 #15)

**R91 task 3 集成入口** (`daily_tracking_page.dart:88-110` 7 卡片) 已加 "治疗" 卡 → 跳 `treatment_placeholder.dart`。
- R91 临时是占位, R92 真做
- 治疗记录: 列表 + 添加 dialog + 跟 mood / medication 关联 (FK?)
- 治疗分类: 药物调整 / 心理咨询 / 住院 / 其他
- 时间: 30 天治疗记录 list + section header
- 复用 `lib/presentation/widgets/page_scaffold.dart` + `app_list_tile.dart` + `add_record_dialog.dart`

**测试**:
- `test/presentation/pages/daily_tracking/treatment_page_round92_test.dart` (entry CRUD)

### 3.7 11+ 处 catch (_) 改 swallowError (P0 #21)

**R17 集中器** (已建立, 复用):
- `lib/core/shared/swallow_error.dart` (假设存在, R17 引用过)
- 或新增 `lib/core/shared/logger.dart` 的 `swallowError(where: ..., error: ...)` 函数

**修法**:
- 11 处 `} catch (_) { ... }` 改 `} catch (e, st) { swallowError(where: '<file>:<line>', error: e, stackTrace: st); ... }`
- 不改 0 行的 catch (e.g. `} catch (_) {}` 是 `swallowError` 自身)
- 不改已经有 named variable 的 (e.g. `} catch (e) { ... }`)

**测试**:
- 每个文件对应 round92 test 加 1 case: 抛异常 → swallowError 调 → 业务 fallback 走

### 3.8 拆 assessment_page 436 行 (P0 #22)

**god page 拆分**:
- `lib/presentation/pages/assessment/assessment_page.dart` (436 行) → 拆 3-4 个 sub-widget
- `lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart` (答题面板)
- `lib/presentation/pages/assessment/widgets/assessment_result_panel.dart` (结果页)
- `lib/presentation/pages/assessment/widgets/assessment_progress_header.dart` (顶部进度)
- `lib/presentation/pages/assessment/widgets/assessment_crisis_dialog.dart` (已存在, 不动)
- `assessment_page.dart` 只剩 State (200 行内)

**测试**:
- `test/presentation/pages/assessment/assessment_page_split_round92_test.dart` (验证拆完 UI 一致)

## 4. 关键约束 (R84-R91 同款)

- Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 4 层架构 (`domain/` 0 flutter 0 drift 0 data, `check_all.dart` 守门员)
- 17 守门员脚本 (R60 后 +1 `check_16kb_alignment.py`)
- 跨 feature import 守门 (`check_cross_feature.py`)
- ARB key 同步 (3 语 zh/en/zh_Hant)
- TDD 风格: 写失败 test → 跑红 → 写实现 → 跑绿 → commit
- 1 task 1-2 commit, 每个 commit 跟项目自定 `<version> round <N> (xxx): <title>` 风格
- baseline 1627 pass / 0 fail (R91 后 + I-1/I-2 fixes)
- master commit: cf91020

## 5. 文件结构

### 新增
- `lib/presentation/pages/crisis_hotline_page.dart` (R75 hotlineByRegion 路由页面)
- `lib/presentation/pages/assessment/widgets/assessment_quiz_panel.dart`
- `lib/presentation/pages/assessment/widgets/assessment_result_panel.dart`
- `lib/presentation/pages/assessment/widgets/assessment_progress_header.dart`
- `lib/presentation/pages/daily_tracking/treatment_page.dart` (R91 placeholder 替换)
- `lib/presentation/pages/daily_tracking/widgets/treatment_add_dialog.dart`
- `lib/presentation/pages/daily_tracking/widgets/treatment_list.dart`
- `test/core/data/database/vent_content_text_drop_round92_test.dart`
- `test/presentation/pages/mood/cbt_wizard_save_round92_test.dart`
- `test/presentation/pages/home/home_fab_toolbar_round92_test.dart`
- `test/presentation/pages/assessment/assessment_center_chart_round92_test.dart`
- `test/presentation/pages/daily_tracking/treatment_page_round92_test.dart`
- `test/presentation/pages/assessment/assessment_page_split_round92_test.dart`
- 6 个 catch (_) 对应 round92 test 各加 1 case

### 修改
- `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105` (5/7 栏 save)
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

### 删除
- 10 项物理残留
- `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart` (R91 placeholder 替换)
- 6 个 catch (_) 改写时同步删 (按代码)

## 6. 风险与缓解

| # | 风险 | 等级 | 缓解 |
|---|------|------|------|
| 1 | vent schemaVersion 18→19 升级漏写 migration | 🔴 P0 | onUpgrade 加 `if (from >= 8 && from < 19)` 双保险 + 4 测试覆盖 (8→19, 18→19, 19→19, 0→19) |
| 2 | CBT wizard 改后父 save 双触发 | 🟠 P1 | 1 个 test 验证只触发 1 次 + Provider scope 走 state 隔离 |
| 3 | 11 处 catch (_) 改后漏 1 处 | 🟡 P2 | grep 守门员 `} catch (_) {` 跑 0 + 测试覆盖 |
| 4 | god page 拆完 UI 不一致 | 🟠 P1 | snapshot test 验证 (R91 widget test 模式) |
| 5 | 14 文件 45 处硬编码中文 l10n 后 overflow | 🟡 P2 | 走现有 ARB key 优先, 缺 key 加 R92 提交 |
| 6 | treatment_page 跟 mood / medication FK | 🟠 P1 | R92 不加 FK (跟 v0.30 R91 一致: 1 表 = 1 目录, 跨表引用走 id 字符串) |
| 7 | 物理残留删错文件 | 🔴 P0 | 用 `mavis-trash` 软删 (按 memory 经验), 7 天后真删 |
| 8 | worktree .gitignore 状态不同步 | 🟠 P1 | merge 前跑 baseline test |

## 7. 验收标准

- `flutter analyze` 0 error / 0 warning (info-level OK)
- `flutter test` baseline 1627 → ≥1650 pass (新增 23+ test)
- 17 守门员脚本全绿 (`check_all.dart` + 16 Python)
- `grep -rn 'catch (_) {' lib/` 返回 0 (除 `swallowError` 自身)
- `grep -rn 'TODO (Task' lib/` 0 命中 (3 个 P0 半成品 TODO 注释移除)
- `grep -rn '硬编码中文' lib/` 0 命中 (14 文件 45 处走 l10n)
- 物理残留 10 项 0 命中

## 8. 不在 R92 范围 (R93/R94/R95+ 排期)

| R93 (阶段 2, 20 项 M 难度) | R94 (阶段 3, 20 项 L 难度) | R95+ (P1/P2) |
|------|------|------|
| 拆 2 个 600+ 行 god page | 拆 3 facade (notification / safety_watch / data_export) | 158 处 TextStyle 残留 |
| 拆 1 个 facade (data_export) | 主页信息架构重排 | 162 处 EdgeInsets 残留 |
| 设置页 4 group 重构 | 设置页 IAP 商业卡 | 50+ Duration + Curves |
| 主页 hero illustration 修 | 紧急联系人 3 步流程 | 主页 8 widget 重排 |
| quick mood carousel 1 tap confirm | 数据导出 3 步流程 | 通知状态卡 17 步加图 |
| medication_calendar 30 天 tap 详情 | vent 长按/swipe tooltip | 主页 3 icon tooltip |
| EmailService mock 路径 test | CBT PDF strings i18n | 50+ 服务子测试 |
| 启动加 _bootstrapHealthCheck | AudioController 抽 | 集成测试 1 → 3-5 |
| safety_watch 失联检测 unit test | vent + mood 加密 key 拆 3 | coverage 阈值 |
| 14 文件 45 处中文 l10n (剩 30) | IAP 真接 (需 App Store Connect) | 等等 |
| 等等 | 等等 | 等等 |

## 9. 文档同步

- R92 CHANGELOG entry: `[0.30.0]` 后追加 R92 section, 5-7 task 概述
- AGENTS.md: 17 守门员补 1 (`check_16kb_alignment.py`)
- `docs/audit/2026-08-06/R92-fix-report.md` (本 spec 实施后总结)

## 10. 工作流 (superpowers-zh subagent-driven)

按 R84-R91 8 sub-spec 同款流程:
1. 写本 spec + plan (已完成)
2. 开 worktree `feat/audit-fixes-r92` (已完成)
3. 写 6 个 task-N-brief.md
4. 循环 6 task:
   - 1 subagent implementer
   - 1 subagent reviewer
   - 1-2 subagent fix per Critical/Important
5. final review (1 subagent)
6. 1-2 fix subagent per remaining Critical/Important
7. merge master (R92 → master)
8. cleanup worktree
9. Save SDD workspace → `docs/superpowers/sdd-logs/round92-audit-fixes/sdd/`
10. update `docs/CHANGELOG.md` [0.30.0] 增 R92 entry

## 11. 一句话总结

按 6 视角审计 (总 410KB) 合并的 **20 项 P0 阶段 1 修复**, 跳过所有外部资源 (签名 / 域名 / 法务 / 阿里云 / Mac), 6 task, 1-2 周, 1 sub-spec (R92), 1+5+1+2+2+1 ≈ 23 commit, 1627 → 1650+ tests pass。
