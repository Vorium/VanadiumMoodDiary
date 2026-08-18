# R95+ 综合审视报告 (慢性病管家 chroniccare)

> **审视人**: Mavis (orchestrator, 综合 6 视角增量)
> **审视范围**: R93 后增量 + 现状摸底 + R95+ 路线图
> **基线**: [R92 6 视角报告](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/00-summary-report.md) (376.8KB / 6 视角 / R91 基线)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **审视日期**: 2026-08-06
> **报告位置**: `docs/audit/2026-08-06/r95-increment/`

---

## 0. 摘要 (TL;DR)

**一句话**: R92 6 视角基线已覆盖 50+ P0 + 60+ P1 + 80+ P2 + 长尾 P3, R93 已按 P0 修 7 task (28 commit / +36 tests), 但 R93 后**新发现 3 大遗留 + 1 个数字低估**:

- **新发现 1**: 600+ 行大文件**不止 3 个** (R92 评估 3 个, 实际 5 个) — `scale_translations.dart 784` + `scale_translations_l10n.dart 708` + `home_page.dart 679` + `trend_calendar.dart 642` + `data_management_section.dart 606` + `mood_audio_section.dart 553` = **6 个 500+ 行真业务文件**
- **新发现 2**: TextStyle / EdgeInsets 实际比 R92 报告**多 30-40%** (224 vs 158 / 208 vs 162) — 集中在 `app_typography.dart` (18) + `medication_report_pdf_layout.dart` (12) + `app_theme.dart` (14) — **主题层 token 化未完成**
- **新发现 3**: 30+ 硬编码中文**真实集中在 5 个业务文件** (排除 l10n 生成文件): `scale_translations.dart` 1528 字符 + `home_page.dart` 580 + `app_colors.dart` 538 + `main.dart` 532 + `app_database.dart` 502 — R92 报告"30+" 准确, 但**未列文件分布**

**R95+ 关键路径 (按修复优先级)**:

1. **P0 必做 (2 周内)**: 拆 `data_management_section.dart` 606 行 → 6 sub-widget (R95 task 1)
2. **P0 必做 (2 周内)**: `scale_translations.dart` 1528 字符硬编码中文 → 走 ARB (R95 task 2)
3. **P0 必做 (1 周内)**: `app_typography.dart` 18 TextStyle + `medication_report_pdf_layout.dart` 12 TextStyle → token 集中器 (R95 task 3)
4. **P1 重要 (3 周内)**: 主页信息架构重排 (emil 反复提到的 hero illustration + 3 icon button 0 tooltip + 8 widget 堆叠)
5. **P1 重要 (3 周内)**: 5 厂商 push SDK 接入 / 法务过审 (业务真接)

---

## 1. 背景与基线

### 1.1 R92 6 视角基线 (2026-08-06 完成)

| 视角 | 评分 | 上架就绪 | 报告体量 |
|------|------|----------|----------|
| emilkowalski (设计) | 7.5/10 | — | 45.9KB |
| superpowers-en (英文工程) | 8.0/10 | — | 76.7KB |
| superpowers-zh (国内合规) | 工程 8.0 / 合规 3.5 / 资质 1.0 / 中文 7.5 / Git 6.0 | — | 73.9KB |
| AppStore (iOS 上架) | 6.0/10 | iOS 6.0/10 | 61.4KB |
| GooglePlay (Android 上架) | 38% | Android 38% | 55.1KB |
| flutter-spec (v3.1 规范) | 84% 合规 | — | 72.8KB |
| **总报告** | **代码 8.0 / 上架 6.0** | — | **376.8KB / 6.0 万字** |

**R92 关键结论**: 代码 / 架构 / 工程自动化是国内中型项目天花板, 但中国 + Apple + Google 三 store 全链路未跑通。海外 GitHub 可发, 任何 store 都上不了。

### 1.2 R93 修复 (28 commit / +36 tests / 0 regression)

按 R92 P0 上架 blocker 7 task 实施:
- **Task 1**: 拆 medication_calendar god page 642→209 行
- **Task 2-7**: 8 业务 FeatureFlag 守门 (IAP / 失联 / 5 厂商 / Email / vent audio / PHQ-9 / GAD-7 / bootReceiver) + UI 完全 hidden (`SizeBox.shrink`)
- **Task 7**: 删 36 张 iOS 67B 占位 png + 3 法律 md 加 R93 阶段 2 业务暂停说明

**R93 影响**:
- 7 个老 test 适配 (feature_flags_round67 / notification_status_card_round20 / settings_page_round45 / home_emil_round81 / home_fab_toolbar_round92 / assessment_center_page_round90)
- 1 baseline 1636 → 1672 pass, +36 R93 tests
- 17 守门员全绿 (16 .py + 1 .dart)
- CHANGELOG [0.30.0] 顶部列出**留待 R95+ 排期** 7 项

### 1.3 R93 留待 R95+ 排期 (CHANGELOG [0.30.0] 顶部确认)

```
- 拆 data_management_section 606 行 god section (R93 v1 留 R95+)
- 158 处 TextStyle + 162 处 EdgeInsets 残留 → 集中器化
- 50+ Duration + 50+ Curves 残留 → AppMotion token 化
- 主页信息架构重排 / 紧急联系人 5→3 步 / 数据导出 5→3 步
- 主页 emotion hero + 设置 4 group 重构
- 30+ 处硬编码中文 → l10n (R92 已修 31, 剩 30)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接
```

---

## 2. 现状摸底 (硬数据, R93 后实测)

### 2.1 规模

| 指标 | 数值 | 备注 |
|------|------|------|
| lib/ .dart 文件 (排除 .g.dart) | **350** | R92 报告"341", +9 (R88-91 新增 scale/assessment/mood_list) |
| lib/ 总代码行 | **57,060** | R92 报告"40K+", +17K (4 个 sub-spec 实施) |
| test/ .dart 文件 | 205+ | R91 baseline 1596 → R93 1672 = +76 tests |
| 600+ 行大文件 (真业务) | **6 个** | R92 报告"3 个", **低估 2 倍** |
| 500+ 行大文件 (真业务) | **8 个** | 含以上 6 个 + setup_step_medication + report_dialog |

### 2.2 600+ 行大文件清单 (R95+ 必拆)

| # | 文件 | 行数 | 类型 | 拆解难度 | 优先级 |
|---|------|------|------|----------|--------|
| 1 | `lib/domain/entities/scale_translations.dart` | **784** | domain 实体 (8 量表 16 题) | L | P0 |
| 2 | `lib/presentation/services/scale_translations_l10n.dart` | **708** | presentation i18n 适配器 | L | P0 |
| 3 | `lib/presentation/pages/home/home_page.dart` | **679** | god page (R92 已评 god) | XL | P1 |
| 4 | `lib/presentation/pages/trend/trend_calendar.dart` | **642** | god page (R92 已评 god) | XL | P1 |
| 5 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | **606** | god section (R92 已评 god) | L | **P0 (R95 task 1)** |
| 6 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | **553** | god widget (R92 已评 god) | L | P1 |
| 7 | `lib/presentation/pages/medication/widgets/medication_calendar_grid.dart` | 510 | god widget (R93 task 1 拆剩 209 后衍生) | M | P2 |
| 8 | `lib/presentation/widgets/medication_report_dialog.dart` | 500+ | god widget | M | P2 |

**新发现**: 6 个 600+ 行文件**集中在 4 个 feature** (home / trend / medication / mood / scale + 1 个 settings) — R95 应做"按 feature god page 拆解包"。

### 2.3 token 残留 (R92 数字低估)

| 类型 | R92 报告 | **R93 后实测** | 差异 | 主要集中 |
|------|----------|----------------|------|----------|
| `TextStyle(...)` 字面量 | 158 | **224** | **+66 (+42%)** | `app_typography.dart` 18 + `app_theme.dart` 14 + `medication_report_pdf_layout.dart` 12 + `edit_medication_dialog.dart` 7 |
| `EdgeInsets.*` 字面量 | 162 | **208** | **+46 (+28%)** | `medication_report_pdf_layout.dart` 12 + `trend_calendar.dart` 10 + `refill_manage_page.dart` 5 + `legal_page.dart` 5 + `cbt_wizard.dart` 5 |
| `Duration(...)` 字面量 | 50+ | **96** | **+46 (+92%)** | `app_motion.dart` 11 (已 token) + `app_routes.dart` 6 (已 token) + 79 个 magic 残留 |
| `Curves.*` 字面量 | 50+ | **9** | **-41 (R93 大幅减少)** | 集中在 `app_motion.dart` 跟 `app_routes.dart` (已 token 化) |
| `catch (_) {` 静默吞错 | 11+ | **10** | -1 (R92→R93 改善) | `export_schema_service.dart` 3 + 7 个其他文件 |

**分析**:
- TextStyle 224 中 32 个**在主题层** (app_typography / app_theme) — 这部分**已算 token** (集中器), 真正"magic 残留" 估算 **192 个**
- EdgeInsets 208 中**全部 magic** (没集中器), 但 `app_spacing.dart` 应有 `spacingXs/Sm/Md/Lg/Xl` 集中器, 应该走那个不直接 `EdgeInsets.all(X)`
- Duration 96 中 17 个**在 token 层** (app_motion / app_routes), 真正"magic 残留" 估算 **79 个**
- Curves 9 个**全部在 token 层** (R93 大幅改善, emil 动效 token 化项目)

**结论**: R92 报告"158+162+50+50" = 420, 实际"192+208+79+9" = **488 个 token 残留**, **低估 16%**。

### 2.4 硬编码中文文件分布 (R92 报 30+ 处)

按字符数 Top 10 (排除 l10n 生成文件):

| # | 文件 | 中文字符 | 行数 | 备注 |
|---|------|----------|------|------|
| 1 | `lib/domain/entities/scale_translations.dart` | **1528** | 326 | **业务文件 (P0 必修)** |
| 2 | `lib/presentation/pages/home/home_page.dart` | 580 | 204 | 主页 (P1 重要) |
| 3 | `lib/core/theme/app_colors.dart` | 538 | 176 | 颜色 token (注释中文, P3) |
| 4 | `lib/main.dart` | 532 | 137 | 注释 + 错误信息 (P2) |
| 5 | `lib/core/data/database/app_database.dart` | 502 | 163 | 注释 (P3) |
| 6 | `lib/core/l10n/strings.dart` | 479 | 155 | **中文常量集中器 (P0 必修, 应走 ARB)** |
| 7 | `lib/core/data/services/notification_service.dart` | 448 | 124 | 注释 (P3) |
| 8 | `lib/core/data/services/sms_service.dart` | 432 | 128 | 注释 (P3) |
| 9 | `lib/presentation/services/scale_translations_l10n.dart` | ~400 | 708 | 业务 (与 scale_translations 配对) |
| 10 | `lib/core/data/services/email_service.dart` | ~350 | 200+ | 注释 + 错误信息 (P3) |

**新发现**: R92 报告"30+ 处" 准确, 但**未列文件分布**。**真正的硬编码中文业务 hotspot 是 3 个文件**:
- `scale_translations.dart` (1528 字符) — 8 量表 16 题中文题目, 应走 ARB
- `home_page.dart` (580 字符) — 主页 8 widget 内部中文 fallback, 应走 ARB
- `core/l10n/strings.dart` (479 字符) — domain 层中文常量, **应走 ARB** (跨层共享)

---

## 3. 6 视角增量审视 (摘要)

详细 6 视角子报告见:
- [01-emil.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/01-emil.md) (设计工程)
- [02-spen.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/02-spen.md) (英文软件工程)
- [03-spzh.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/03-spzh.md) (国内合规 + 中文)
- [04-appstore.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/04-appstore.md) (iOS 上架)
- [05-googleplay.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/05-googleplay.md) (Android 上架)
- [06-flutter-spec.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/r95-increment/06-flutter-spec.md) (v3.1 规范)

### 3.1 emilkowalski 视角 (设计工程) — R93 后增量

**R92 评分**: 7.5/10, token 化顶级但执行分裂, 3 个 P0 半成品
**R93 修复**: CBT wizard save 修 (字段不丢) + homeFabHotline/hotline 真功能 + assessment_center 顶部 chart (复用 R90 chart widget) + treatment_placeholder 真页面 + 设 4 section hidden
**R93 后新发现**:
- 主页 hero illustration 140dp 视觉几乎 0 (R92 已提, 未修)
- 主页 8 widget 堆叠, primary action 不突出 (R92 已提, 未修)
- 224 TextStyle 中 18 个在 `app_typography.dart` 应是 token 集中器, 但 6 个 `setup_step_welcome` / 6 个 `assessment_widgets` / 6 个 `vent_detail_page` / 5 个 `trend_calendar` 仍是 widget 内 magic
- 主页 header 3 icon button 0 tooltip (R92 已提, R93 hidden 但 0 tooltip 仍未加)
- `legal_page` toggle 缺 chip 标识撤回时间 (R92 已提)
- 主页 8 widget 实际在 679 行 home_page.dart (R92 估 436 行, R93 加了 cbt / vent / mood_list 入口后涨到 679)

**R95+ 必做 (P0/P1)**:
- 拆 home_page 679 行 god page → 3 sub-section (streak / check_in / cbt_vent_mood)
- 主页加 hero illustration 真组件 (替换 140dp 占位)
- 主页 header 3 icon button 加 tooltip
- legal_page toggle 撤回 chip 标识

### 3.2 superpowers-en 视角 (英文软件工程) — R93 后增量

**R92 评分**: 8.0/10, SDD 闭环 + 16 守门员, 5 P0 bug 漏测
**R93 修复**: 7 task 完整 SDD 流程 (spec→plan→task brief→report→review→fix→merge→ledger), +36 R93 tests
**R93 后新发现**:
- `.worktrees/feat-cbt-thought-report/` (R92 提, R93 task 1 拆 medication_calendar 时已 prune)
- `.r61_backup_20260731_101630/` + `.r61_backup_logs/` (R92 提, R93 task 1 物理残留清理**未清这俩**, 应 R95+ 清)
- 集成测试 1 → 3-5 个 (R92 提, R93 仍只有 1 个, R95 应做)
- 18+ service 子类 sub-service 测试 (R56c 续修, R93 仍未修)
- coverage 阈值 (≥ 70% domain / 50% data) + Codecov (R92 提, R93 仍未加)
- 9 个 600+ 行 god page 拆 (R92 提, R93 task 1 拆 1 个剩 8 个)
- `vent_compose dispose 异步未 await` (R72 P2-1 → R75 → R76 → R77 → R93 仍未修)
- `badge_sync_service catch (e) 加 swallowError 包装` (R76 P3-3, R93 仍未修)
- `notification_service const 改 final 风险大` (R77-10 partial 1/5, R93 仍未修完)
- `setup_page wizard 4 step 内部 state 化` (R76 P3-2 完整版, R93 仍未做)
- `home_page god class 抽 3 helper` (R76 P3-1, R93 仍未做, 反而涨到 679 行)
- `mood_audio_section 591 行 god class 评估` (R76 新发现, R93 减到 553 行但仍 god)
- 1 pre-existing fail mood_period_aggregator R91 集成时遗留 (R93 CHANGELOG 标, R95 必修)

**R95+ 必做 (P0/P1)**:
- 拆 8 个 god page 剩 5 个 (home / trend / data_mgmt / mood_audio / scale)
- 集成测试 1 → 3-5 个
- vent_compose dispose await + notification_service final 化
- mood_period_aggregator pre-existing fail 修
- coverage 阈值加 Codecov

### 3.3 superpowers-zh 视角 (国内合规 + 中文) — R93 后增量

**R92 评分**: 工程 8.0 / **合规 3.5 / 资质 1.0 / 中文 7.5 / Git 6.0**
**R93 修复**: 3 法律 md (privacy_policy / user_agreement / sensitive_data_consent) 加 R93 阶段 2 业务暂停说明 (8 FeatureFlag 列表), README 红 banner, DEPLOYMENT 阶段 5/6/7 补全
**R93 后新发现**:
- 8 业务 FeatureFlag 守门**只是技术暂停, 法务过审**才是业务上线硬门槛 (R92 提 ¥45-90k 法务, R93 仍未付费过审)
- 5 厂商 push SDK 接入**仍未启动** (R92 提 1-2 月, R93 仍 0 接入)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 仍 flag 关闭 (R92 提法律责任, R93 仍 flag false)
- `core/l10n/strings.dart` 479 字符硬编码中文 (PIPL §17 告知不准确风险)
- 7 业务暂停 vs README 红 banner 矛盾**已部分修** (R93 task 7 README 红 banner 列出 7 项 FeatureFlag)
- 5 厂商 OEM 引导 + 鸿蒙/HarmonyOS NEXT 适配**仍未启动**
- 业务暂停 vs 文档矛盾**已部分修** (R93 修 6 处, 还剩 bootReceiver 已实现但 0 实现 / vent 撤回已实现但 PIPL §47 物理删)

**R95+ 必做 (P0/P1)**:
- 法务过审 (¥45-90k, 1-2 月) — 3 份法律 md 律师签字
- 5 厂商 push SDK 接入 (1-2 月, 并行)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核)
- 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
- 邮箱注册 (`support@` / `privacy@chroniccare.app`)
- `core/l10n/strings.dart` 479 字符硬编码中文 → 走 ARB

### 3.4 AppStore iOS 视角 — R93 后增量

**R92 评分**: 6.0/10, 9 平台配置已修, 3 法务 + IAP + SMS 未就绪
**R93 修复**: 删 36 张 iOS 67B 占位 png (Apple 拒审点清理)
**R93 后新发现**:
- 9 平台配置中**漏 DEVELOPMENT_TEAM TODO** (R92 提 S 难度 1h, R93 仍未填)
- iOS Podfile 真生成 (R92 提 S 难度 0.5d, R93 仍未跑, 需 Mac)
- iOS 截图 + AppIcon 1024 替换占位 (R92 提 33 张, R93 删了 36 张占位但**真截图未补**)
- iOS 18+ Dark Mode App Icon 4 套 (R92 提 M 难度 2-3d, R93 仍未做)
- IAP 8 元买断仍 FeatureFlag 关 (R92 提 P0, R93 仍 flag false, App Store Connect productId 未填)
- AliyunSms 仍 FeatureFlag 关 (R92 提 XL 1-2d + 2-4w 审核, R93 仍 flag false)
- TestFlight 0 跑过 (R92 提 0 崩溃率数据, R93 仍未跑)
- iOS iCloud Backup 排除 (R92 提 0.5d, R93 仍未做)
- iOS description.txt 改文案 (R92 提 0.5d, R93 仍未改"会发短信")
- Apple Privacy Manifest (R74 完成, R93 仍保持)

**R95+ 必做 (P0/P1)**:
- iOS DEVELOPMENT_TEAM 填 (1h)
- iOS Podfile 真生成 (0.5d, 需 Mac)
- iOS 截图 + AppIcon 1024 真设计 (设计师 2-3d, 需 Mac)
- iOS 18+ Dark Icon 4 套 (设计师 2-3d)
- IAP 8 元买断真接 productId (1-2d)
- TestFlight 跑 100+ 真实用户
- iCloud Backup 排除 (0.5d)
- iOS description.txt 改文案 (0.5d)

### 3.5 GooglePlay Android 视角 — R93 后增量

**R92 评分**: 38%, 16 P0 红线, 失联业务无效 (5 厂商 push 0 接)
**R93 修复**: BootReceiver FeatureFlag 关 (避 R65 crash) + OEM push 引导 hidden
**R93 后新发现**:
- 5 厂商 push SDK 接入**仍未启动** (R92 提 XL 1-2 月, R93 仍 0 接入, 推送送达率 < 70%)
- 失联通知业务**仍无效** (R92 提 P0, R93 仍 flag false + 5 厂商 0 接)
- Android keystore + Play App Signing (R92 提 S 难度 1-2h 脚本, R93 仍未做)
- 16KB alignment (R84 完成, R93 保持)
- USE_EXACT_ALARM Play Console justification 100+ 字符 (R92 提, R93 仍未填)
- Data Safety Form / Health Apps questionnaire (R92 提, R93 仍未填)
- 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 (R92 提 XL 1-2 月, R93 仍未启动)
- Android 5 厂商 OEM 引导 hidden (R93 task 3 hidden, 仍 0 接)
- APK vs AAB 决策 (R92 提未明确, R93 仍 AAB 上传但 keystore 缺)

**R95+ 必做 (P0/P1)**:
- Android keystore + Play App Signing (1-2h 脚本)
- USE_EXACT_ALARM justification 100+ 字符填
- Data Safety Form / Health Apps questionnaire 填
- 5 厂商 push SDK 接入 (1-2 月, 并行, 失联业务上线前必做)
- 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配
- 域名 + 邮箱注册

### 3.6 flutter-spec v3.1 视角 — R93 后增量

**R92 评分**: 84% 合规 (120/143), 6 P0 阻断 (签名 / Podfile / SMS 守卫 / PIPL / PHQ i18n / web 端) + 19 P1 警告 + 25 P2/P3 建议
**R93 修复**: vent contentText DROP (schemaVersion 18→19) + 3 处 catch (_) → swallowError 集中器 + 36 R93 test 加固
**R93 后新发现**:
- 6 P0 阻断中**签名 / Podfile / SMS 守卫 仍未修** (R92 提, R93 仍未做)
- PIPL §13 同意留痕 (R82 已修, R93 保持)
- PHQ i18n (R92 提 flag false, R93 仍 flag false)
- web 端 fail-fast (R92 提 P0, R93 仍未做)
- ink_sparkle shader (R17 修过, R93 保持)
- iOS UIScene+UIMainStoryboardFile 重复声明 (R92 提, R93 仍未修)
- 19 P1 警告中 11+ 处 catch (_) 静默吞错 (R92 提, R93 修 3 处剩 10 处)
- 25 P2/P3 建议中 224 TextStyle + 208 EdgeInsets 集中器化 (R92 提, R93 数字不降反升)
- `app_database.dart` 502 字符硬编码中文注释 (R92 提, R93 仍未走 ARB)
- `main.dart` 532 字符硬编码中文错误信息 (R92 提, R93 仍未走 ARB)
- `legal_version.dart` kPubspecVersion 手动同步 (R78+ 考虑 package_info_plus, R93 仍未做)
- `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted(success: true)` 占位 (R92 提, R93 仍未做)
- `data_export_service.dart` vent audio 不导出文件 (R92 提, R93 仍未做)

**R95+ 必做 (P0/P1)**:
- 224 TextStyle + 208 EdgeInsets 集中器化 (R95 task 3-4)
- 10 处 catch (_) 静默吞错 → swallowError 集中器 (剩 3 处)
- 96 Duration 中 79 个 magic 残留 → app_motion 集中器化
- PHQ-9 / GAD-7 16 题 i18n 真接
- `data_export_service.dart` vent audio 文件导出
- iOS UIScene+UIMainStoryboardFile 重复声明
- `main.dart` 532 字符 + `app_database.dart` 502 字符硬编码中文 → 走 ARB

---

## 4. 顶层架构审视 (高内聚低耦合)

### 4.1 结论: **不需要重设顶层架构**

R92 已确认 4 层 + 5 子层 umbrella 是 R95+ 范式, 继续维护即可。**R95+ 重点是"修尾", 不是"重设"**。

### 4.2 5 个 600+ 行大文件的"内聚 + 耦合"评分

| 文件 | 内聚 | 耦合 | 评分 | 拆解建议 |
|------|------|------|------|----------|
| `scale_translations.dart` (784) | 8 量表混合 (PHQ / GAD / ISI / PSS / WHODAS / Level2-*/ASRM) | domain 0 flutter 0 drift | **C+** | 拆 `scale_translations/{phq,gad,isi,pss,whodas,level2_sleep,level2_depression,level2_anxiety,asrm}.dart` 9 文件 (R95 task 2 配) |
| `scale_translations_l10n.dart` (708) | 8 量表 i18n 适配器 | presentation 1 文件 | **C+** | 跟 scale_translations 同步拆 9 文件 (R95 task 2 配) |
| `home_page.dart` (679) | 8 widget 堆叠 (streak / check_in / cbt / vent / mood / assessment / safety) | presentation 11 import + 6 provider | **C-** | 拆 `home_page/{streak,check_in,cbt_vent_mood,assessment_safety}_section.dart` 4 文件 (R95 task 5) |
| `trend_calendar.dart` (642) | 30 天热力图 + StatCard 4 + narrative | presentation 8 import + 3 provider | **C-** | 拆 `trend_calendar/{stat_cards,heatmap,narrative}_section.dart` 3 文件 (R95 task 6) |
| `data_management_section.dart` (606) | 6 入口 (导出 / CBT PDF / 报告 / 历史 / 导入 / 清空) | presentation 22 import + 8 provider | **C** | 拆 `data_management_section/{export,cbt_pdf,report,history,import,clear}_tile.dart` 6 文件 (R95 task 1) |
| `mood_audio_section.dart` (553) | 录音 / 播放 / 波形 / 加密 | presentation 12 import | **C** | 拆 `mood_audio_section/{recorder,player,waveform,encrypted}_widget.dart` 4 文件 (R95 task 7) |

### 4.3 4 层架构纯度复检 (R95+ 必保持)

R92 已用 `dart scripts/check_all.dart` 验证:
- domain/ 0 flutter 0 drift 0 data 0 presentation ✅
- data/ 不依赖 presentation ✅
- domain `*Entity` ↔ drift `@DataClassName` 一一对应 ✅
- shared/ 每个文件至少被 2 层用 ✅

**R95+ 重点**: 保持, 不破坏。特别是:
- `scale_translations.dart` 拆 9 文件时, **每文件仍要 0 flutter** (domain 层)
- `scale_translations_l10n.dart` 拆 9 文件时, **每文件仍放 presentation/services/** (跟原位置一致)
- `home_page.dart` 拆 4 文件时, 走 `home_page/{section}.dart` 子目录模式 (跟 `medication/` 拆 `widgets/` 一致)
- `data_management_section.dart` 拆 6 文件时, 走 `data_management_section/{tile}.dart` 子目录模式

### 4.4 8 个 FeatureFlag 守门员 (R95+ 必保持)

R93 task 2 加的 8 flag:
- `emergencyContactEnabled` (失联通知)
- `iapEnabled` (IAP 8 元买断)
- `phqGad7I18nEnabled` (PHQ-9 / GAD-7 16 题 i18n)
- `bootReceiverEnabled` (BootReceiver 完善)
- `aliyunSmsEnabled` (阿里云 SMS 真接)
- `emailServiceEnabled` (EmailService 真接 SendGrid)
- `fiveVendorPushEnabled` (5 厂商 push SDK)
- `ventAudioEnabled` (vent audio 录音业务)

**R95+ 重点**:
- 业务真接时翻 true (法务 + SDK + AccessKey 都到位)
- 加新业务时**先加 flag** (R93 模式推广)
- 不在 prod 暴露未实现的 service (flutter-spec 2.5/2.6 建议)

---

## 5. 关键文件逐行审阅

### 5.1 `data_management_section.dart` 606 行 (R95 task 1 必拆)

**结构分析** (基于 R93 task 1 拆 medication_calendar god page 模式):
- **22 import** (settings / providers / services / widgets / l10n / domain / theme)
- 1 个 `DataManagementSection extends ConsumerWidget` build:
  - 1 Card > Column 6 children
  - 6 AppListTile (export / cbt_pdf / med_report / report_history / import / clear)
- 6 个方法:
  - `_exportData` (200+ 行, 含 ConsentDialog + audit log + JSON 弹窗)
  - `_exportCbtPdf` (R88 新增, 5/7 栏 CBT PDF 导出)
  - `_chooseAndShowReport` (medication report dialog)
  - `_showReportHistory` (history dialog)
  - `_showImportDialog` (JSON 导入)
  - `_showClearAllDataDialog` (清空数据)

**R95 task 1 拆解** (估时 1-2 周, 6-9 commit):
- `data_management_section.dart` (主壳, 30-50 行, 6 ListTile 拼装)
- `widgets/export_tile.dart` (50-80 行, 走 ConsentDialog + audit log + JSON 弹窗)
- `widgets/cbt_pdf_tile.dart` (40-60 行, 走 date range picker + CbtThoughtRecordPdf.build)
- `widgets/report_tile.dart` (40-60 行, 走 medication report dialog)
- `widgets/history_tile.dart` (30-50 行, 走 history dialog)
- `widgets/import_tile.dart` (50-80 行, 走 JSON 导入)
- `widgets/clear_tile.dart` (40-60 行, 走清空数据 dialog)

**R95 task 1 复用 R93 task 1 模式** (medication_calendar 642→209):
- 抽 `widgets/{sub}_tile.dart` 子目录
- 主壳 props 持 ref / context, sub-tile 接受 props + callback
- 复用 `app_list_tile.dart` 公共组件 (R75 引入)

### 5.2 `home_page.dart` 679 行 (R95 task 5 必拆)

**R92 估 436 行, R93 加 cbt / vent / mood_list 入口后涨到 679 行 (+243 行)** — 验证了 R92 "主页信息架构重排" P1。

**已知内嵌 widget** (R92 + R93):
- streak summary
- check_in button (主)
- quick mood carousel
- cbt_thought_record 入口 (R88)
- vent 入口 (R84)
- mood_list 入口 (R87)
- assessment_center 入口 (R90)
- daily_tracking 入口 (R91)

**R95 task 5 拆解** (估时 1-2 周, 6-9 commit):
- `home_page.dart` (主壳, 80-120 行, scrollable Column 8 section 拼装)
- `widgets/streak_section.dart` (60-80 行)
- `widgets/check_in_section.dart` (40-60 行, 含主按钮 + 庆祝)
- `widgets/quick_mood_section.dart` (40-60 行, carousel)
- `widgets/feature_grid_section.dart` (80-120 行, cbt / vent / mood_list / assessment 4 grid)
- `widgets/daily_tracking_section.dart` (40-60 行)

**配合 R95 task 5 应同时做**:
- emil "主页 hero illustration 真组件" (替换 140dp 占位)
- 主页 header 3 icon button 加 tooltip
- primary action 不突出 (R92 P1-2.2.3) — 改 Card 阴影 + 字号

### 5.3 `trend_calendar.dart` 642 行 (R95 task 6 必拆)

**已知内嵌 widget** (R92):
- 30 天热力图 (含 0 tap 详情 — R92 P1)
- 4 StatCard 数字挤一起 (R92 改 narrative)
- narrative 文字

**R95 task 6 拆解** (估时 1-2 周, 4-6 commit):
- `trend_calendar.dart` (主壳, 80-120 行)
- `widgets/heatmap_section.dart` (200+ 行, 30 天 grid + tap 详情)
- `widgets/stat_cards_section.dart` (150+ 行, 4 StatCard 改 2x2 grid)
- `widgets/narrative_section.dart` (100+ 行)

**R95 task 6 配合**:
- 30 天热力图 0 tap 详情 → 加 tap 弹 day detail (R92 P1)
- 4 StatCard 数字挤一起 → 2x2 grid (R92 P1)
- 趋势页 narrative 增强 (R92 P1)

### 5.4 `mood_audio_section.dart` 553 行 (R95 task 7 必拆)

**已知内嵌 widget** (R92 + R93):
- 录音按钮 (R93 task 6 ventAudioEnabled hidden)
- 播放按钮
- 波形显示
- 加密 (R21 v0.21 contentTextEnc BLOB)

**R95 task 7 拆解** (估时 1-2 周, 4-6 commit):
- `mood_audio_section.dart` (主壳, 50-80 行)
- `widgets/recorder_widget.dart` (100+ 行, R93 hidden 时返 SizedBox.shrink)
- `widgets/player_widget.dart` (100+ 行)
- `widgets/waveform_widget.dart` (100+ 行)
- `widgets/encrypted_storage_widget.dart` (100+ 行)

**R95 task 7 配合**:
- 抽 `AudioController` 抽象 (R92 P1) — vent + mood 4 widget 共享
- vent 跟 mood 加密 key 独立 (R92 P1) — 拆 `EncryptionService` 3 key

### 5.5 `scale_translations.dart` 784 行 / `scale_translations_l10n.dart` 708 行 (R95 task 2 必拆)

**结构**:
- 8 量表: PHQ-9 / GAD-7 (R93 hidden) + ISI / PSS / WHODAS / Level2-Sleep / Level2-Depression / Level2-Anxiety / ASRM
- 16 题 / 5 选项 / 严重度 / 危机电话
- 1528 字符硬编码中文 (P0 必修)

**R95 task 2 拆解** (估时 2-3 周, 8-12 commit):
- `scale_translations.dart` 拆 9 文件:
  - `scale_translations.dart` (主壳, 50-80 行, 8 量表 enum + registry)
  - `scale_translations/phq.dart` (150+ 行, PHQ-9 16 题 ARB key)
  - `scale_translations/gad.dart` (150+ 行, GAD-7 16 题 ARB key, R93 hidden 时仍编译)
  - `scale_translations/isi.dart`
  - `scale_translations/pss.dart`
  - `scale_translations/whodas.dart`
  - `scale_translations/level2_sleep.dart`
  - `scale_translations/level2_depression.dart`
  - `scale_translations/level2_anxiety.dart`
  - `scale_translations/asrm.dart`
- `scale_translations_l10n.dart` 拆 9 文件 (跟上面一一对应)
- 1528 字符硬编码中文 → 走 ARB (R95 task 2 配, 估 +18 ARB keys)
- PHQ-9 / GAD-7 16 题 i18n 真接 (R95 task 2 配, 法务 + 临床审核)

**R95 task 2 配合**:
- 加 `phqGad7I18nEnabled` flag 守护 (R93 已加)
- 业务真接翻 true 时, 16 题英文 / zh_Hant 翻译完整
- ARB 走 `app_zh.arb` + `app_en.arb` + `app_zh_Hant.arb` (3 语)

---

## 6. 底层逐行排查 (token 化 / 静默吞错 / 半成品)

### 6.1 224 TextStyle 残留分析 (R95 task 3)

按 R92 报告 158 + R93 后实测 224 = **+66 新增**。R93 期间**没修反而新增**, 主要原因:
- R88-91 多个 sub-spec 加新 widget (cbt_thought_record / mood_list / daily_tracking) 时硬编
- `medication_report_pdf_layout.dart` 12 个 TextStyle (R88 新增, PDF 字体)
- `setup_step_welcome.dart` 6 个 (R90 加)
- `vent_detail_page.dart` 6 个 (R85 加)

**R95 task 3 集中器化方案** (估时 1-2 周, 4-6 commit):
- `app_typography.dart` 18 个已**算 token 集中器**, 验证
- `app_theme.dart` 14 个 (跟 typography 重叠, 验证是否去重)
- `medication_report_pdf_layout.dart` 12 个 PDF 字体 — **特殊, PDF 字体不走 token**, 保留
- `edit_medication_dialog.dart` 7 个 → 改 `AppTokens.textStyleXxx` 引用
- `setup_step_welcome.dart` 6 个 → 改 token
- `assessment_widgets.dart` 6 个 → 改 token
- `vent_detail_page.dart` 6 个 → 改 token
- `legal_page.dart` 6 个 → 改 token
- `setup_step_medication.dart` 5 个 → 改 token
- `trend_calendar.dart` 5 个 → 改 token

**总估时**: 1-2 周, 4-6 commit, +10 R95 tests (守门员加严)

### 6.2 208 EdgeInsets 残留分析 (R95 task 4)

按 R92 报告 162 + R93 后实测 208 = **+46 新增**。R93 期间**没修反而新增**, 原因跟 TextStyle 类似。

**R95 task 4 集中器化方案** (估时 1-2 周, 4-6 commit):
- `medication_report_pdf_layout.dart` 12 个 PDF 边距 — **特殊, PDF 边距不走 token**, 保留
- `trend_calendar.dart` 10 个 → 改 `AppTokens.spacingXxx` 引用
- `refill_manage_page.dart` 5 个 → 改 token
- `legal_page.dart` 5 个 → 改 token
- `cbt_wizard.dart` 5 个 → 改 token
- `sleep_widgets.dart` 5 个 → 改 token
- `social_rhythm_widgets.dart` 5 个 → 改 token
- `reminder_cards.dart` 4 个 → 改 token
- `reminders_hub_page.dart` 4 个 → 改 token
- `assessment_history_list.dart` 4 个 → 改 token

**总估时**: 1-2 周, 4-6 commit, +10 R95 tests (守门员加严)

### 6.3 96 Duration 残留分析 (R95 task 4 配)

按 R92 报告 50+ + R93 后实测 96 = **+46 新增**。**R95 应"集中器化" 79 个 magic 残留** (17 个已 token 化):
- `app_motion.dart` 11 个 — **token 层** ✅
- `app_routes.dart` 6 个 — **token 层** ✅
- `app_spacing.dart` 4 个 — **token 层** ✅
- 79 个 magic 在 widget / service / logic 里散落

**R95 task 4 配**:
- 加 `app_motion.dart` `durations: {fast: 100, normal: 200, slow: 300, page: 250, snackbar: 4000, debounce: 500, ...}` 集中器
- 79 个 widget / service / logic 的 magic Duration 改引用
- +8 R95 tests 验证 motion token 集中

### 6.4 10 处 catch (_) 静默吞错 (R95 task 8 必清)

按 R92 报告 11+ + R93 后实测 10 = **-1 改善** (R92→R93 修了 3 处, 但 `export_schema_service.dart` 加了 2 处)。

**R95 task 8 集中器化方案** (估时 1 周, 2-3 commit):
- `export_schema_service.dart` 3 处 → `swallowError` 集中器
- `data_export_service.dart` 1 处 → `swallowError` 集中器
- `export_import_pipeline.dart` 1 处 → `swallowError` 集中器
- `swallow_error.dart` 自身 1 处 (特殊, 集中器自己 catch) → **保留** (R17 模式)
- `theme_provider.dart` 1 处 → `swallowError` 集中器
- `assessment_record.dart` 1 处 (domain 层) → `swallowError` 集中器
- `json_codec.dart` 1 处 → `swallowError` 集中器
- `medication_times.dart` 1 处 → `swallowError` 集中器

**总估时**: 1 周, 2-3 commit, +5 R95 tests (守门员加严)

### 6.5 30+ 硬编码中文 (R95 task 9 必修)

按 R92 报告 30+ + 字符数 Top 10 文件, 真实业务 hotspot 是 3 个:

**R95 task 9 集中器化方案** (估时 1-2 周, 4-6 commit):
- `scale_translations.dart` 1528 字符 → 走 ARB (R95 task 2 配, 估 +18 ARB keys)
- `home_page.dart` 580 字符 → 走 ARB (R95 task 5 配, 估 +8 ARB keys)
- `core/l10n/strings.dart` 479 字符 → **走 ARB** (跨层共享, 估 +12 ARB keys)
- `app_colors.dart` 538 字符 → **注释中文, 翻译文档即可** (P3)
- `main.dart` 532 字符 → 注释 + 错误信息, **走 ARB** 错误信息 (估 +6 ARB keys, P2)
- `app_database.dart` 502 字符 → 注释中文, **翻译文档即可** (P3)
- `notification_service.dart` 448 字符 → 注释, **翻译文档即可** (P3)
- `sms_service.dart` 432 字符 → 注释, **翻译文档即可** (P3)
- `email_service.dart` ~350 字符 → 注释 + 错误信息, **翻译文档即可** (P3)

**总估时**: 1-2 周, 4-6 commit, **+30 ARB keys**, +10 R95 tests (守门员加严)

### 6.6 半成品 widget / 页面 (R95+ 必清)

R92 已列 8 项, R93 修 4 项 (CBT wizard / FAB / chart / treatment placeholder), 剩 4 项:

| # | 文件 | 状态 | 视角 | R95+ 优先级 |
|---|------|------|------|-----------|
| 1 | `lib/presentation/pages/settings/email_preview.dart:13-152` | 整个 email preview 页面残留 | 01/02 | **P0 必删 (失联是 SMS, 不是 email, R93 业务暂停后彻底无用)** |
| 2 | `lib/presentation/pages/mood/mood_dialog.dart:20-25` | 25 行薄壳 god-pattern 纯转发 | 01 | P3 (emil "honest abstraction") |
| 3 | `lib/presentation/pages/medication/refill_manage_page.dart:78-85` | 4 StatCard 数字挤一起 | 01 | P2 (改 2x2 grid) |
| 4 | `lib/presentation/pages/setup/setup_step_medication.dart:106-132` | PrimaryButton 包在 110×44 narrow SizedBox + Stack hacky | 01 | P3 (改 PressFeedback + LoadingSpinner) |

**R95 task 10** (估时 1 周, 1-2 commit):
- 删 `email_preview.dart` 整个文件 (R93 业务暂停后**真无用**, R94 doc inconsistency)
- 改 `mood_dialog.dart` 直接是 `MoodRecorderPage` (emil honest abstraction)
- 改 `refill_manage_page.dart` 2x2 grid
- 改 `setup_step_medication.dart` PressFeedback + LoadingSpinner

---

## 7. R95+ 路线图 (按 P0 → P3 排, 架构 vs 底层, 难度 + 优先级)

### 7.1 阶段 1: P0 必做 (0-4 周, 估 13-21 commit, +90 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 1** | 拆 `data_management_section.dart` 606 行 → 6 sub-tile | 底层 (god section) | L | 1-2 周 | — |
| **R95 task 2** | 拆 `scale_translations.dart` 784 + `scale_translations_l10n.dart` 708 → 18 文件 | 底层 (god service) + i18n | L | 2-3 周 | — |
| **R95 task 3** | 224 TextStyle 集中器化 (保留 PDF 字体 12 个) | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 4** | 208 EdgeInsets + 96 Duration 中 79 个 magic 集中器化 | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 5** | 拆 `home_page.dart` 679 行 → 5 sub-section | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 6** | 拆 `trend_calendar.dart` 642 行 → 3 sub-section | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 7** | 拆 `mood_audio_section.dart` 553 行 → 4 sub-widget | 底层 (god widget) | L | 1-2 周 | — |
| **R95 task 8** | 10 处 catch (_) 静默吞错 → `swallowError` 集中器 | 底层 (静默吞错) | M | 1 周 | — |
| **R95 task 9** | 30+ 硬编码中文业务 hotspot → 走 ARB (估 +30 keys) | 底层 (i18n) | L | 1-2 周 | task 2 |
| **R95 task 10** | 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med) | 底层 (半成品清理) | M | 1 周 | — |

**阶段 1 总估时**: 13-21 周 (1 人), 13-21 commit, +90 R95 tests, 风险低

**风险**:
- task 5 (home_page) 风险最大 (主页面), 应**先做 task 1-4** 练手
- task 2 (scale_translations) 风险中 (8 量表业务复杂), 应**配 PHQ-9/GAD-7 法务** 跟业务真接
- task 3-4 (token 化) 风险低, 但**守门员加严** 一次性跑

### 7.2 阶段 2: P1 重要 (4-12 周, 估 8-15 commit, +50 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 11** | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) | 业务真接 (1-2 月审核) | XL | 4-8 周 | 法务 |
| **R95 task 12** | 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核) | 业务真接 | XL | 4-6 周 | task 2 |
| **R95 task 13** | IAP 8 元买断真接 productId (App Store Connect) | 业务真接 | M | 1-2 周 | 苹果审核 |
| **R95 task 14** | 阿里云 SMS 真接 (法务模板 + AccessKey 申请) | 业务真接 | XL | 1-2d + 2-4w 审核 | task 11 法务 |
| **R95 task 15** | EmailService 真接 SendGrid (法务模板 + API key) | 业务真接 | L | 1-2w | 法务 |
| **R95 task 16** | 主页信息架构重排 (emil "3 tap 抵达") | 架构 (UX) | XL | 1-2 周 | task 5 |
| **R95 task 17** | 设置页 8 section → 4 group 重构 (用户档案 / 提醒 / 数据 / 法律) | 架构 (UX) | L | 1-2 周 | — |
| **R95 task 18** | 紧急联系人 5 步 → 3 步 (emil "3 tap 抵达") | 架构 (UX) | L | 1 周 | — |
| **R95 task 19** | 数据导出 5 步 → 3 步 | 架构 (UX) | M | 1 周 | task 1 |
| **R95 task 20** | 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字) | 业务真接 | XL | 4-8 周 | — |

**阶段 2 总估时**: 4-12 周 (1 人, 业务真接并行), 8-15 commit, +50 R95 tests

**风险**:
- task 11 (5 厂商 push) 风险最大 (1-2 月审核), 应**提前启动** 不阻塞其他
- task 12 (PHQ-9 i18n) 临床审核风险, 跟 task 2 配
- task 20 (法务) ¥45-90k 预算风险, 应**提前付费**

### 7.3 阶段 3: P2 建议 (12-24 周, 估 15-25 commit, +30 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 21** | `notification_service.dart` 450 行再拆 1 层 facade | 架构 (god service) | L | 1-2 周 | — |
| **R95 task 22** | `safety_watch_service.dart` 388-457 行续拆 detector/builder/dispatcher | 架构 (god service) | L | 1-2 周 | task 14 |
| **R95 task 23** | `setup_page` wizard 4 step 内部 state 化 (R76 P3-2 完整版) | 架构 (state 化) | M | 1-2 周 | — |
| **R95 task 24** | `notification_service` const 改 final 风险大 (R77-10 partial 1/5) | 底层 (const → final) | M | 1 周 | — |
| **R95 task 25** | `vent_compose dispose 异步未 await` (R72 P2-1 跨 5 轮未修) | 底层 (resource leak) | S | 2-3d | — |
| **R95 task 26** | `badge_sync_service catch (e) 加 swallowError 包装` (R76 P3-3) | 底层 (静默吞错) | S | 1-2d | task 8 |
| **R95 task 27** | 集成测试 1 → 3-5 个 | 架构 (测试覆盖) | L | 1-2 周 | — |
| **R95 task 28** | coverage 阈值 (≥ 70% domain / 50% data) + Codecov | 架构 (CI 守护) | M | 1-2 周 | — |
| **R95 task 29** | 18+ service 子类 sub-service 测试 (R56c 续修) | 底层 (测试覆盖) | L | 1-2 周 | — |
| **R95 task 30** | `assessment_dao._rowToEntry` 解析失败 PII 泄露 | 底层 (PII 泄露) | S | 2-3d | — |
| **R95 task 31** | audit log 明文 (PIPL §47 删除权) | 底层 (PIPL 合规) | M | 1 周 | — |
| **R95 task 32** | `app_router.dart` redirect 嵌套路径 startsWith 守卫 | 底层 (路由守卫) | M | 3-5d | — |
| **R95 task 33** | iOS 18+ Dark Mode App Icon 4 套 (设计师 2-3d) | 业务 (上架) | M | 2-3d | 设计师 + Mac |
| **R95 task 34** | iOS 截图 + AppIcon 1024 真设计 (设计师 2-3d) | 业务 (上架) | L | 2-3d | 设计师 + Mac |
| **R95 task 35** | iOS Podfile 真生成 (Mac 跑 `pod install`) | 业务 (上架) | S | 0.5d | Mac |
| **R95 task 36** | iOS DEVELOPMENT_TEAM 填 + 签名 | 业务 (上架) | S | 1-2h | Mac |
| **R95 task 37** | Android keystore + Play App Signing | 业务 (上架) | S | 1-2h | 脚本 |
| **R95 task 38** | USE_EXACT_ALARM Play Console justification 100+ 字符 | 业务 (上架) | S | 1-2h | — |
| **R95 task 39** | Data Safety Form / Health Apps questionnaire | 业务 (上架) | M | 1-2d | — |
| **R95 task 40** | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | 业务 (上架) | M | 1-2d + 3-5d 部署 | — |
| **R95 task 41** | 邮箱注册 (`support@` / `privacy@chroniccare.app`) | 业务 (上架) | S | 1-2h | task 40 |
| **R95 task 42** | iOS iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey) | 业务 (上架) | S | 0.5d | Mac |
| **R95 task 43** | iOS description.txt 改文案 (删"会发短信") | 业务 (上架) | S | 0.5d | — |

**阶段 3 总估时**: 12-24 周 (1 人), 15-25 commit, +30 R95 tests

**风险**:
- task 22 (safety 续拆) 风险中 (失联业务未上线, 拆了不立即用), 应**等 task 11 业务上线**
- task 27-29 (测试覆盖) 风险低, 但**跟其他并行** 节省时间

### 7.4 阶段 4: P3 nice-to-have (24+ 周, 估 10-20 commit, +20 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 44** | 主页 hero illustration 真组件 (替换 140dp 占位) | UX (emil) | M | 2-3d | 设计师 |
| **R95 task 45** | 主页 header 3 icon button 加 tooltip | UX (emil) | XS | 1-2h | — |
| **R95 task 46** | `legal_page` toggle 加 chip 标识撤回时间 | UX (emil) | XS | 1-2h | — |
| **R95 task 47** | 通知状态卡 17 步纯文字 0 截图 0 链接 → 加截图 | UX (emil) | M | 1-2d | 设计师 |
| **R95 task 48** | vent 长按/swipe 删除 0 视觉提示 → 加 visual hint | UX (emil) | XS | 1-2h | — |
| **R95 task 49** | `mood_dialog.dart` 25 行薄壳 → 直接 `MoodRecorderPage` (emil honest abstraction) | 架构 (UX) | XS | 1-2h | — |
| **R95 task 50** | `setup_step_medication.dart` PrimaryButton + Stack hack → PressFeedback + LoadingSpinner | UX (emil) | XS | 1-2h | — |
| **R95 task 51** | 趋势页 4 StatCard 数字挤一起 → 2x2 grid | UX (emil) | XS | 1-2h | task 6 |
| **R95 task 52** | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | 架构 (抽象) | L | 1-2 周 | task 7 |
| **R95 task 53** | vent 跟 mood 加密 key 独立 (拆 `EncryptionService` 3 key) | 架构 (安全) | M | 1 周 | — |
| **R95 task 54** | `data_export_service.dart` vent audio 不导出文件 → 真导文件 | 业务 (导出) | M | 1-2 周 | — |
| **R95 task 55** | iOS UIScene+UIMainStoryboardFile 重复声明 | 底层 (iOS 配置) | S | 1-2h | Mac |
| **R95 task 56** | web 端 fail-fast (flutter-spec P0) | 业务 (web) | M | 1-2d | — |
| **R95 task 57** | `legal_version.dart` `kPubspecVersion` 手动同步 → `package_info_plus` 自动 | 底层 (配置) | XS | 1-2h | — |
| **R95 task 58** | `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted(success: true)` 占位 | 底层 (iOS) | S | 0.5d | Mac |
| **R95 task 59** | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | 业务 (国产) | XL | 4-8 周 | task 11 |
| **R95 task 60** | TestFlight 跑 100+ 真实用户 | 业务 (测试) | M | 2-4 周 | — |

**阶段 4 总估时**: 24+ 周 (1 人), 10-20 commit, +20 R95 tests

---

## 8. dev doc 更新建议

### 8.1 `docs/VERSION_1.0_PLAN.md` 升级为 R95+ 路线图

R95+ 必更新:
- 0. 背景: v0.30.0+85 R93 后, 8 业务 FeatureFlag 守门 + 36 R93 tests
- 1. R95+ 路线图 (按 P0 → P3 排, 60 task, 估 13-21 周 P0 + 4-12 周 P1 + 12-24 周 P2 + 24+ 周 P3)
- 2. 6 视角建议整合 (引用本报告)
- 3. 修复优先级 (XS / S / M / L / XL 难度 + P0 / P1 / P2 / P3 优先级)

详见 [docs/VERSION_1.0_PLAN.md](file:///D:/Batch/chroniccare/docs/VERSION_1.0_PLAN.md) (R95+ 升级版)。

### 8.2 `AGENTS.md` 必更新

- 17 守门员补 `check_16kb_alignment.py` (R60 漏列, R92 标)
- 5 大文件状态表 (R93 后实测 6 个 600+ 行真业务文件)
- R95+ 路线图引用 (本文档)

### 8.3 `CHANGELOG.md` 顶部待办更新

R93 已列 R95+ 待办 7 项, **R95+ 实施期间** 持续更新:
- R95 task 1-10 P0 完成进度
- R95 task 11-20 P1 业务真接进度
- R95 task 21-43 P2 上架 + 测试覆盖进度
- R95 task 44-60 P3 nice-to-have 进度

---

## 9. 附录: 数据来源 + 验证方法

### 9.1 现状硬数据验证

```powershell
# 1. TextStyle 字面量
$allDart = Get-ChildItem -Path 'D:\Batch\chroniccare\lib' -Recurse -Filter '*.dart' | Where-Object { $_.FullName -notmatch '\.g\.dart$' }
($allDart | Select-String -Pattern '\bTextStyle\(' | Measure-Object).Count
# 实测: 224

# 2. EdgeInsets 字面量
($allDart | Select-String -Pattern '\bEdgeInsets\.' | Measure-Object).Count
# 实测: 208

# 3. Duration 字面量
($allDart | Select-String -Pattern '\bDuration\(' | Measure-Object).Count
# 实测: 96

# 4. catch (_) 静默吞错
($allDart | Select-String -Pattern 'catch\s*\(_\s*\)' | Measure-Object).Count
# 实测: 10

# 5. 600+ 行大文件
$allDart | ForEach-Object {
    [PSCustomObject]@{ File = $_.Name; Lines = (Get-Content $_.FullName | Measure-Object -Line).Lines }
} | Where-Object Lines -ge 600 | Sort-Object Lines -Descending
# 实测: 6 个真业务文件 + 3 个 l10n 生成文件
```

### 9.2 R92 报告引用

- [00-summary-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/00-summary-report.md) (35KB)
- [01-emilkowalski-design-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/01-emilkowalski-design-report.md) (45.9KB)
- [02-superpowers-en-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/02-superpowers-en-report.md) (76.7KB)
- [03-superpowers-zh-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/03-superpowers-zh-report.md) (73.9KB)
- [04-appstore-ios-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/04-appstore-ios-report.md) (61.4KB)
- [05-googleplay-android-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/05-googleplay-android-report.md) (55.1KB)
- [06-flutter-spec-report.md](file:///D:/Batch/chroniccare/docs/audit/2026-08-06/06-flutter-spec-report.md) (72.8KB)

### 9.3 R93 commit 历史

详见 [docs/CHANGELOG.md](file:///D:/Batch/chroniccare/docs/CHANGELOG.md) [0.30.0] R93 entry (28 commit, 7 task)。

---

**报告完成时间**: 2026-08-06
**报告体量**: 28KB / 9 章 / 60 R95+ task
**下次审视建议**: R95+ 阶段 1 完成后 (估 4 周后), 跑 R96 增量审视
