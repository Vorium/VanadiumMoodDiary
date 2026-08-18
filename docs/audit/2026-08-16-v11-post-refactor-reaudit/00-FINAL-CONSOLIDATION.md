# v1.1.0 重构后项目重审 — 多视角整合报告

> 日期 2026-08-16 · 基线 master `9c4934e0`（1.1.0 round 6d）· 6 视角并行只读审查

## 评分总览

| 视角 | 评分 | 一句话 |
|---|---|---|
| 1 架构纯度 | 9.0/10 | check_all 双绿、删除彻底、0 悬挂 provider；扣分 = data/domain 中文 fallback 泄漏 |
| 2 数据安全 | 7.5/10 | 核心防护健壮；扣分 = 同意对话框文案与实际不符 + 存量老库升级链缺陷 |
| 3 新功能质量 | 7.5/10 | 聚合器/picker 扎实；扣分 = i18n 中文泄漏 + 已选短语换分后不可见 |
| 4 UI/UX + i18n | 6.5/10 | 结构设计到位；扣分 = 新功能对 en/zh_Hant 100% 中文 + audio-only 树洞空态误导 |
| 5 测试与守门员 | 7.0/10 | 新测试质量高；扣分 = 3 个守门员盲区静默放行 |
| 6 文档一致性 | 5.0/10 | 核心三件套干净；扣分 = 法务文档/ARB 文案/商店元数据/部署 SOP 仍描述已删功能 |

**加权综合 ≈ 7.0/10**（重构前 R112 基线 7.1，功能面提升、文档面拖低）

## 主矛盾判断

代码层外联删除彻底（视角 1 实锤 0 live 残留），但**删除的"影子"仍在三个传播面**：
① 用户签署的 3 份法务文档 + 5 个活跃 UI 文案 key 仍描述失联/紧急联系人（合规级）；
② domain 预设内容（标签/短语/鼓励文案/导出 summary）硬编码中文，en/zh_Hant 用户 100% 看到中文（4 视角共识）；
③ 守门员在删除型重构后出现 3 个盲区（domain 中文不扫、coverage 假绿、锁屏 PII 只守 2/5）。

## 发现清单（按优先级）

### P0 合规/用户可见误导（合计 ~3h + 法务确认）

| # | 发现 | 视角 | 证据 |
|---|---|---|---|
| 1 | 3 份法务文档残留已删功能（紧急联系人告知段/SMS/邮件 SDK 表/PII 表），修订历史停 v0.30 | 6-F1 | assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md |
| 2 | 5 个活跃 ARB key 在 3 语显示已删功能（reminderHubDescription/settingsReminderCenterSubtitle/settingsExportRiskBody/settingsClearAllDataDialogBody/dataExportDataCategories） | 6-F2 / 2-F2 | app_zh.arb:80,97,123,307,2832；后者是 PIPL §13 同意缺陷级 |
| 3 | VentHeroCard audio-only 条目显示"写第一条心事"空态误导 | 4-#9 | vent_hero_card.dart:37-38；对照 vent_list_page.dart:369-373 已有正确实现 |
| 4 | README 测试数漂移（"2277 pass / 1 fail"已不存在；skip 标注"16KB"实际是 migration i18n 测试） | 5-B4/D / 6-M1 | README.md:106 |

### P1 i18n 结构化（~1-2d）

| # | 发现 | 视角 | 证据 |
|---|---|---|---|
| 5 | 预设标签 8 + 短语 17 + 鼓励文案 5 硬编码中文，en/zh_Hant 全泄漏，且已入 DB/导出 | 3-F1/F3 / 4-#11/#12 / 1-F2 | vent_tag_library / status_phrase_library / mood_review_aggregator:_encouragement |
| 6 | 已选预设短语换 score 后 chip 不可见且静默入库 | 3-F2 | status_phrase_field.dart:70-75 |
| 7 | 导出 summary 中文 fallback 泄漏（data 层 Strings 不传 override） | 1-F1 | export_orchestrator.dart:420-430 |
| 8 | 状态短语无 maxLength（导入 cap 100 不对称，超长静默丢弃）+ 列表行无溢出保护 | 2-F3 / 3-F8 | status_phrase_field.dart:113-124 |

### P2 守门员修复（~1d）

| # | 发现 | 视角 | 证据 |
|---|---|---|---|
| 9 | check_strings_hardcoded 对 domain 中文常量完全盲区（35 处 CJK 静默通过） | 5-A1 | 规则 1 只扫 strings.dart、规则 2 只扫 widget inline |
| 10 | check_coverage 假绿：lcov 过期 3 天 + 已删 sms_service 条目被跳过 + 死配置 | 5-A2 | coverage/lcov.info mtime 8-13 |
| 11 | check_pii_in_title 只守 2/5 通知 title（notifDailyCheckIn/Assessment/MoodReminder 未覆盖） | 5-A3 | 脚本硬编码 title_func_names |
| 12 | 死路由 /mood-list /mood-trend 无 UI 入口（round 5b 删首页入口后未补） | 4-#5 | app_route_mood_list.dart:26,35 |

### P3 存量缺陷（跨期，非本重构引入）

| # | 发现 | 视角 | 证据 |
|---|---|---|---|
| 13 | 老库升级链（≤v5 起点）`createTable` 用当前 schema 建表 + 后续 addColumn 重复列 → DB 崩溃 | 2-F1 | app_database.dart:164-166+179-183 等；dry-run 只覆盖 v19→v23 |
| 14 | 宽屏顶层路由（/mood-review 等）无 AppBar 返回按钮 | 4-#2 | page_scaffold.dart:88 + app_shell 宽屏分支 |
| 15 | med cancel 区间 [2000,202000) 与 refill id 带重叠（潜伏地雷） | 2-F5 | notification_service.dart:339-340 |
| 16 | 通知 title/body 中文 fallback（en 用户收到中文通知，AGENTS 已知） | 4-#14 | medication_notifier.dart:86-87 |

### 轻微（下轮 cleanup 批量处理）

- 注释残留引述已删模块（home_fab_toolbar.dart:114-115 等）
- check_legal_consent 缩成单文件 TODO 扫描，vent/export 门只靠测试
- 测试反向锁定中文文案（i18n 修复时需同步重写）
- CHANGELOG [1.1.0] 漏记 round 4c/6c/6d 内容与 2 个 API 级变化（ConsentKind 5→3、VentRepository.add 签名）
- docs/DEPLOYMENT.md、STOREFRONT_RELEASE_SOP、SPRINT2_TODO、SMS_PROVIDERS、SENDGRID_SETUP 描述已删功能
- fastlane release_notes/changelogs 仍提联系人
- 状态短语"全部"无收起 label；月模式空态文案"这周"；entriesCount vs "记录天数"语义；负 delta/1 月 edge/vent detail chips 测试盲区

## 修复路线建议

- **hotfix（本周，~1d）**：P0 全部（法务文档措辞需用户确认后重写）+ #12 死路由 + README 数字
- **v1.1.1（1-2 周）**：P1 i18n override 模式（预设/短语/鼓励/export summary 四路合一）+ 守门员 3 盲区
- **v1.2+**：P3 存量（老库升级链 dry-run 补测最优先，DB 崩溃级）

## 审查方式

6 个 explore subagent 并行只读审查（架构/数据安全/新功能/UI-i18n/测试守门员/文档），每视角跑对应只读检查脚本实测。报告原文见本次会话 task 输出。
