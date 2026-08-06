# 6 视角审计修复 (R93 阶段 2) — Design Spec

> v0.30 round 93 (sub-spec 9) — 阶段 2
> Spec author: Mavis (R84-R92 SDD 流程延续)
> Spec date: 2026-08-06
> 审计材料: `docs/audit/2026-08-06/0[0-6]-*-report.md` (410 KB / 6.5 万字 / 6 视角)
> 前置: R92 阶段 1 修复完成 (cf91020 → 1220c16, 17 commit, baseline 1627 → 1636 +9 pass)

## 1. Goal

按 6 视角审计合并的 **阶段 2 中等粒度修复 (M 难度 20 项)**, 跳过所有外部资源 (签名 / 域名 / 法务 / 阿里云 / Mac / 5 厂商 push), 只跑纯代码 / 文档 / 测试 / 架构改动。

**R93 是 R92/R93/R94 三连击的 Round 2**:
- R92 (已完成): 阶段 1, 20 项 S 难度, 1-2 周
- R93 (本 spec): 阶段 2, 20 项 M 难度, 1-2 周
- R94 (后续 spec): 阶段 3, 20 项 L 难度, 1-2 月

## 2. 范围内 (20 项 M 难度)

### A. 架构收尾 (5 项, 1-2 周)

| # | 项 | 文件 | 难度 |
|---|----|------|------|
| 1 | 拆 `medication_calendar_page.dart` (642 行 god page) 拆 3-4 sub-widget | `lib/presentation/pages/medication/medication_calendar_page.dart` | L |
| 2 | 拆 `data_management_section.dart` (606 行 god section) 拆 3-4 sub-widget | `lib/presentation/pages/settings/widgets/data_management_section.dart` | L |
| 3 | 设置页 8 section → 4 group 重构 (用户档案 / 提醒 / 数据 / 法律) | `lib/presentation/pages/settings/settings_page.dart` | M |
| 4 | 拆 `data_export_service.dart` facade (1 个 + 4 sub) → 删 facade, 4 sub 直接 provider 化 | `lib/core/data/services/export/` | M |
| 5 | 主页信息架构重排 (8 widget 堆叠 → primary 居中, secondary 折叠) | `lib/presentation/pages/home/home_page.dart` | M |

### B. UI / UX 修复 (8 项, 1 周)

| # | 项 | 文件 | 难度 |
|---|----|------|------|
| 6 | 主页 hero illustration 140dp 视觉几乎 0 → 100dp + 渐变 alpha 0.15+ | `lib/presentation/pages/home/widgets/home_hero_illustration.dart` | S |
| 7 | quick mood carousel 1 tap 0 反馈 → 加 confirm / snackbar | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart` | S |
| 8 | medication_calendar 30 天热力图 0 tap 详情 → 点 cell 跳 day detail | `lib/presentation/pages/medication/medication_calendar_page.dart` | M |
| 9 | 紧急联系人添加 5 步 → 3 步流程 (emil "3 tap 抵达") | `lib/presentation/pages/contact/contacts_list_widget.dart` | M |
| 10 | 数据导出 5 步 → 3 步流程 + 风险文字简明 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | M |
| 11 | vent 长按/swipe 删除 → 加 1 次性 tooltip 提示 | `lib/presentation/pages/vent/vent_list_page.dart` | S |
| 12 | 主页 3 icon button (HeaderAction) 加 tooltip + 1 句小字 | `lib/presentation/pages/home/home_page.dart` | S |
| 13 | 趋势页 4 StatCard → 1 narrative ("连续 5 天, 总 23 天") | `lib/presentation/pages/trend/trend_summary.dart` | S |

### C. 业务加固 (4 项, 1 周)

| # | 项 | 文件 | 难度 |
|---|----|------|------|
| 14 | 启动加 `_bootstrapHealthCheck` 步骤 7 (把 6 步 try/catch 失败统一写 LastErrorCapture) | `lib/main.dart` | M |
| 15 | `safety_watch_service` 失联检测窗口加 unit test (DST / 跨年 / 24h 边界) | `test/core/data/services/safety_watch_service_round93_test.dart` (新) | M |
| 16 | EmailService mock 路径补 test (R67 漏的, 跟 SMS round57 模式一致) | `test/core/data/services/email_service_round93_test.dart` (新) | M |
| 17 | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | `lib/presentation/widgets/audio_controller.dart` (新) | M |

### D. 文档 + i18n (3 项, 0.5 周)

| # | 项 | 文件 | 难度 |
|---|----|------|------|
| 18 | 14 文件 45 处硬编码中文 → 走 l10n (剩 30 处, R92 已修 31) | 多文件 | S |
| 19 | DEPLOYMENT.md 阶段 5/6/7 补全 (Apple 完整 metadata + 上架前 checklist) | `docs/DEPLOYMENT.md` | S |
| 20 | `progress.md` 跨 R70+ 整理 (CI/CD / keystore / 部署决策记录) | `docs/` | S |

## 3. 范围 vs 跳过

### 3.1 跳过范围 (R94+ 排期)

#### 阶段 3 (L 难度) - R94
- IAP 真接 (需 App Store Connect productId)
- EmailService 真接 SendGrid (法务模板审核)
- 拆 3 facade (notification / safety_watch / data_export 部分)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (en / zh_Hant 法律责任)
- 鸿蒙 / HarmonyOS NEXT 适配
- 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族, 1-2 月审核)

#### 外部资源 (跟 R92 同)
- iOS 33 截图 + AppIcon 1024 (设计师)
- iOS DEVELOPMENT_TEAM + 4 ID (Apple Developer $99)
- iOS Podfile 真生成 (Mac 跑 `pod install`)
- iOS Dark Mode App Icon 4 套 (设计师)
- iOS LaunchImage.png 3 个占位删
- iOS iCloud Backup 排除
- iOS description.txt 改文案
- 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
- 邮箱 `support@chroniccare.app` / `privacy@chroniccare.app` 注册
- Android keystore + Play App Signing
- TestFlight 跑 1 周期 (Mac + 2 tester)
- 3 份法律 md 律师过审 (¥45-90k)
- 文网文 / 互联网药品信息服务资格
- 软件著作权 / ICP 备案 / NMPA / HIPAA / GDPR
- 算法备案 (网信办) — 失联检测算法

#### 长期 P1/P2/P3 (R95+ 排期)
- 158 处 TextStyle 残留 (40% magic)
- 162 处 EdgeInsets 残留
- 50+ Duration + 50+ Curves 残留 (~30%)
- 主页 8 widget 重排 (R93 task 5 部分做)
- 通知状态卡 17 步加图
- 集成测试 1 → 3-5 个
- 18+ service 子类 sub-service 测试
- coverage 阈值 (≥ 70% domain / 50% data)
- 50+ 服务子测试
- CI 4 job (coverage / build appbundle / release publish)

## 4. 架构决策 (跟 R92 一致)

### 4.1 整体策略

- **不重设顶层架构**: 4 层 + 5 子层 umbrella 已成
- **不拆 facade**: R93 部分拆 data_export facade (task 4, 1 个), R94+ 拆 notification / safety_watch (2 个)
- **不拆第 3 个 god page**: R93 拆 2 个 (medication_calendar + data_management_section), R92 已拆 1 个 (assessment), 留 R95+ 拆 trend_page 165+ 行
- **TDD 风格**: 跟 R92 一致, 红 → 绿 → commit

### 4.2 关键设计

#### Task 1-2: 拆 medication_calendar + data_management_section

参考 R92 task 6 (assessment_page 拆 3 sub-widget) 模式:
- props callback 模式 (父 widget 持 state, sub-widget 接受 props)
- 复用 R60 R90 R91 已有 widget (PageScaffold / SectionHeader / AppListTile / EmptyState / PrimaryButton)
- 不加 FK 跨表引用

#### Task 3: 设置页 4 group 重构

| 现状 8 section | 重构 4 group |
|----------------|------------|
| 用户档案 (头像 / 昵称 / 主题) | 用户档案 (同) |
| 提醒 (每日 / 用药 / 续方 / 评估) | 提醒 (同) |
| 评估 (提醒 / 历史 / 危机) | 评估 (挪到 /assessment 路由, 不放设置) |
| 用药 (时区 / 续方 / 历史) | 用药 (同) |
| 树洞 (录音 / 加密 / 撤回) | 树洞 (同) |
| 数据 (导出 / 备份 / 销毁) | 数据 (合并 6 行 → 3 group: 备份 / 报告 / 销毁) |
| 法律 (同意 / 撤回 / 隐私) | 法律 (同) |
| 关于 (版本 / 开源 / 联系) | 关于 (同) |

评估 section 挪到 /assessment 路由, 设置页从 8 section 减到 7, 然后 4 group 分类。

#### Task 4: data_export_service facade 拆

现状: `data_export_service.dart` (110 行 facade) + `export/` 子目录 4 文件 (~800 行)
- 4 sub: `export_orchestrator.dart` (266 行) + `export_pipeline.dart` + `export_schema_service.dart` + `export_import_pipeline.dart`
- facade 价值低 (4 sub 不需要二次委派), 直接删 facade, 4 sub 改 provider 化
- 改动 6-8 个 import 路径 + 4-5 个 provider

#### Task 5: 主页信息架构重排

| 现状 8 widget | 重构 5 widget |
|----------------|----------------|
| HomeHeroIllustration (140dp 几乎不可见) | 删 / 缩到 60dp |
| EncouragementText | 同 |
| QuickMoodCarousel | 同 |
| PrimaryActionRow (3 button ~200dp) | 居中, 打卡 88dp 高 |
| TodayMedSchedule | 折叠到抽屉 |
| SecondaryActionRow (2 button) | 折叠 |
| Spacer(1) | 删 |
| HomeFooter | 缩到 40dp |

#### Task 14: 启动 _bootstrapHealthCheck

现状: `main()` 6 步 (load dotenv / migrate / init notification / validate release / migrateIfNeeded / runApp)
加 7 步: 跑完 6 步后 `_bootstrapHealthCheck` 跑 `LastErrorCapture.lastError` 检查 + `runZonedGuarded` 启动。

#### Task 17: AudioController 抽象

现状: vent (vent_compose_page / vent_detail_page) + mood (mood_recorder_page) 4 widget 各有独立 audio play/record 代码
抽 `lib/presentation/widgets/audio_controller.dart`:
- `AudioController` interface (play / pause / stop / recordStart / recordStop / position stream)
- 4 widget 接受 AudioController, 共享 record / play 逻辑
- 减少 ~200 行重复代码

## 5. 关键约束 (跟 R92 同款)

- Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 4 层架构 (`domain/` 0 flutter 0 drift 0 data, `check_all.dart` 守门员)
- 17 守门员脚本 (R92 已补 check_16kb_alignment 17 个)
- 跨 feature import 守门 (`check_cross_feature.py`)
- ARB key 同步 (3 语 zh / en / zh_Hant, 4 i18n 守门员)
- TDD 风格: 写失败 test → 跑红 → 写实现 → 跑绿 → commit
- 1 task 1-2 commit, 跟项目自定 `<version> round <N> (xxx): <title>` 风格
- baseline 1636 pass / 0 regression (R92 + 1 pre-existing mood_period_aggregator 跟 R93 无关, 期望 R93 修)
- master commit: 1220c16 (R92 merge 后)
- worktree: `.worktrees/feat-audit-fixes-r93/`

## 6. 文件结构 (估)

### 新增 (~20 文件)
- `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` (180 行)
- `lib/presentation/pages/medication/widgets/medication_calendar_day_detail.dart` (150 行)
- `lib/presentation/pages/medication/widgets/medication_calendar_legend.dart` (60 行)
- `lib/presentation/pages/settings/widgets/data_management_export.dart` (180 行)
- `lib/presentation/pages/settings/widgets/data_management_reports.dart` (160 行)
- `lib/presentation/pages/settings/widgets/data_management_destroy.dart` (160 行)
- `lib/presentation/providers/export_providers.dart` (新, 4 provider 替代 facade)
- `lib/presentation/widgets/audio_controller.dart` (interface, 100 行)
- `lib/presentation/widgets/audio_recorder_widget.dart` (150 行, 共享)
- `lib/presentation/widgets/audio_player_widget.dart` (120 行, 共享)
- `test/core/data/services/safety_watch_service_round93_test.dart` (5 case)
- `test/core/data/services/email_service_round93_test.dart` (5 case)
- + task-1/2/3 brief + report

### 修改 (~25 文件)
- `lib/presentation/pages/medication/medication_calendar_page.dart` (642 → ~250 行)
- `lib/presentation/pages/settings/widgets/data_management_section.dart` (606 → ~200 行)
- `lib/presentation/pages/settings/settings_page.dart` (8 section → 4 group)
- `lib/presentation/pages/home/home_page.dart` (8 widget → 5 widget)
- `lib/main.dart` (加 _bootstrapHealthCheck 步骤 7)
- `lib/core/data/services/data_export_service.dart` (删 facade, sub 直接 provider)
- 多文件: vent_compose / vent_detail / mood_recorder (用 AudioController)
- 多文件: 14 文件 45 处硬编码中文 (剩 30 处, R92 已修 31)
- `docs/DEPLOYMENT.md` (阶段 5/6/7 补全)

### 删除
- `lib/core/data/services/data_export_service.dart` (facade 删)
- 1 个 god page 子方法 (内联到 sub-widget)

## 7. 风险与缓解

| # | 风险 | 等级 | 缓解 |
|---|------|------|------|
| 1 | 拆 2 个 600+ 行 god page 引入新 bug | 🔴 P0 | snapshot test 验证 (R92 模式) + props callback 模式 |
| 2 | 主页信息架构重排破坏现有用户习惯 | 🟠 P1 | FeatureFlag `homeRedesignEnabled` 控制 (默认 true 走新, false 走旧) |
| 3 | AudioController 抽象 vent + mood 不兼容 (API 差异) | 🟠 P1 | 抽 interface + 4 widget 各自 adapter, 不强制统一 |
| 4 | safety_watch_service unit test 跨 DST 边界不准确 | 🟠 P1 | 用 `tz.local` 不用 `DateTime` (R40 fix 模式) |
| 5 | 30 处硬编码中文 l10n 后 ARB key 数量破 1100 | 🟡 P2 | 跑 `check_arb_keys.py` 守门, key 数量不限 |
| 6 | worktree .gitignore 状态不同步 | 🟠 P1 | merge 前跑 baseline test |

## 8. 验收标准 (跟 R92 §7 一致)

- `flutter analyze` 0 error / 0 warning
- `flutter test` baseline 1636 → ≥1670 pass (R93 估 +30 test: 拆 2 god page 各 +1 snapshot, safety_watch +5, email +5, audio +4, 主页 +2, 数据管理 +2, 设置页 +2, vent tooltip +1, contact 3-step +2, 14 文件 30 处中文 l10n +6)
- 17 守门员脚本全绿
- `grep -rn 'catch (_) {' lib/` → 0 (除 `swallowError` 自身, R92 已修)
- `grep -rn 'TODO (Task' lib/` → 0
- `grep -rn '硬编码中文' lib/` → 0
- `wc -l lib/presentation/pages/medication/medication_calendar_page.dart` < 250
- `wc -l lib/presentation/pages/settings/widgets/data_management_section.dart` < 200
- `wc -l lib/presentation/pages/settings/settings_page.dart` 4 group 分类

## 9. 不在 R93 范围 (R94+ 排期)

| R94 (阶段 3, 20 项 L 难度) | R95+ (P1/P2) |
|------|------|
| IAP 真接 (需 App Store Connect productId) | 158 处 TextStyle 残留 |
| EmailService 真接 SendGrid | 162 处 EdgeInsets 残留 |
| 拆 3 facade (notification / safety_watch / data_export 部分) | 50+ Duration + Curves |
| 主页信息架构重排 R93 部分, 主页 8 widget 残 1 | 趋势页 4 StatCard narrative |
| 8 量表 PHQ-9 / GAD-7 16 题 i18n | 主页 3 icon tooltip (R93 task 12) |
| AudioController 完整化 | 通知状态卡 17 步加图 |
| vent + mood 加密 key 拆 3 | 50+ 服务子测试 |
| BootReceiver WorkManager 真接 | 集成测试 1 → 3-5 |
| 鸿蒙 / HarmonyOS NEXT 适配 | coverage 阈值 |
| 5 厂商 push SDK 接入 (1-2 月审核) | 等等 |

## 10. 文档同步 (R93)

- R93 CHANGELOG entry: `[0.30.0]` 增 R93 section, 5-7 task 概述
- AGENTS.md: R93 改动后守门员 + 16 → 17 列表保持
- `docs/DEPLOYMENT.md`: 阶段 5/6/7 补全 (task 19)
- `docs/audit/2026-08-06/R93-fix-report.md` (本 spec 实施后总结)

## 11. 工作流 (superpowers-zh subagent-driven, 跟 R92 同款)

按 R84-R92 9 sub-spec 同款流程:
1. 写本 spec + plan (已完成)
2. 开 worktree `feat/audit-fixes-r93` (已完成)
3. 写 5-7 task-N-brief.md
4. 循环 5-7 task:
   - 1 subagent implementer (background)
   - 1 subagent reviewer
   - 1-2 subagent fix per Critical/Important
5. final review (1 subagent, 跨整个 R93 branch)
6. 1-2 fix subagent per remaining Critical/Important
7. merge master (R93 → master, --no-ff)
8. cleanup worktree (R93 + R93 branch)
9. Save SDD workspace → `docs/superpowers/sdd-logs/round93-audit-fixes/sdd/`
10. update `docs/CHANGELOG.md` [0.30.0] 增 R93 entry

## 12. 一句话总结

按 6 视角审计 (总 410KB) 合并的 **20 项 P0 阶段 2 M 难度修复**, 5-7 task, 1-2 周, 估 25-35 commit, 1636 → 1670+ tests pass。
