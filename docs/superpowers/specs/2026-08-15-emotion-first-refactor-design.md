# v1.1.0 情绪优先重构 — 设计规格书

> 日期 2026-08-15 · 基线 v1.0.0+147 (master `55f9dda5`) · 定位调整：树洞 + 情绪日记为主，吃药记录为辅，删除一切外联推送

## 1. 背景与目标

现有产品是"精神心理患者吃药打卡 app"（死了么模式）。v1.0 已发布。用户决策：

1. **删除**推送给联系人的功能（彻底删代码 + 删表），应用 100% 本地化（保留发给自己设备的本地提醒）
2. **弱化**吃药提醒与量表：功能保留，UI 权重下调
3. **增强**树洞与情绪日记：3 个新功能（树洞标签 / 情绪状态短语 / 情绪回顾页）
4. 保留危机热线页；不动 app 名称与商店定位

**成功标准**：schema 23 + export v6 无数据丢失升级；`flutter analyze` 0e/0w；`flutter test` 全过（除 4 个 iOS 资产占位）；21 守门员全绿；净删除 ≥ 5000 行。

## 2. 决策记录

| # | 决策 | 选择 |
|---|---|---|
| D1 | 外联删除力度 | 彻底删代码 + 删表 + migration |
| D2 | 吃药/量表 | 调 UI 权重，功能全保留 |
| D3 | 首页/导航 | 树洞+情绪双主卡；导航改 心情/树洞/趋势/设置 |
| D4 | 通知 | 保留全部本地提醒（吃药/评估/心情），删全部外联通知 |
| D5 | 品牌 | 名称与商店文案不动 |
| D6 | 危机热线 | 保留 |
| D7 | Care Engine | 连同失联功能一起删 |
| D8 | 树洞标签 | 预置 + 自定义 + 列表筛选 |
| D9 | 状态短语 | 预设短语库 + 自定义输入 |
| D10 | 情绪回顾页 | 周/月统计摘要页 |

## 3. Workstream A — 删除外联功能

### A1. 整文件删除（~24 个 lib 文件）

**data/services**：`sms_service.dart`(341L) / `email_service.dart`(177L) / `safety_watch_service.dart`(383L) / `safety_alert_builder.dart`(151L) / `safety_alert_sender_impl.dart`(105L) / `safety_config_service.dart`(132L) / `reminder_scheduler.dart`(232L, 失联 SMS 轮询版——与 `reminder_dispatcher.dart` 药物提醒版无关，需在实现时逐行确认无药物提醒逻辑混入)

**domain/logic**：`care_engine.dart` / `care_strategies.dart` / `care_copy.dart` / `lost_contact_sms.dart` / `safety_alert_policy.dart` / `safety_detector.dart` / `email_template.dart`

**domain/usecases**：`check_safety.dart` / `dispatch_safety_alert.dart` / `fire_care_strategy.dart`

**domain/repositories**：`safety_alert_sender.dart`

**presentation**：`services/safety_check_result_l10n.dart` / `providers/care_strategy_providers.dart` / `pages/contact/contacts_list_widget.dart` / `pages/setup/setup_contact_consent_flow.dart`

### A2. contact 数据链删除

- `database/tables/contact/contacts.dart`、`database/daos/contact_dao.dart`、`repositories/contact/contact_repository_impl.dart`、`database/mappers/contact/contact_mapper.dart`、`domain/entities/contact_entity.dart`、`domain/repositories/contact_repository.dart`
- `app_database.dart`：删 `Contacts` 表注册、contactDao、contact import
- `phone_validator.dart` 移到 `core/shared/`（删 contact 后仍被 `l10n/region_display_name.dart` 热线区号用）

### A3. schema 22→23 migration（一次完成）

```dart
// schemaVersion 22 → 23
onUpgrade: m.deleteTable('contacts');
           m.addColumn(ventEntries, ventEntries.tagsJson);        // TEXT default '[]'
           m.addColumn(moodEntries, moodEntries.statusPhrase);    // TEXT nullable
```

- `checkInCycleHours`（user_profiles）**保留**：domain/logic/reminder_scheduler.dart（药物提醒）仍在用
- 迁移前后 DB round-trip 测试：老 schema 22 数据升级后 contacts 消失、vent/mood 新列存在且默认值正确
- `dart run build_runner build --delete-conflicting-outputs` 重生成 `app_database.g.dart`

### A4. export v5→v6

- `export_schema_service.dart`: `currentVersion = 5` → `6`，版本范围校验同步
- `export_orchestrator.dart` / `export_import_pipeline.dart`：删 contacts 读取/序列化/导入循环/`db.delete(db.contacts)`/importSummaryContact 计数
- **导入 v5 兼容**：v5 文件导入时跳过 contacts 段（不报错），其余段照常
- **顺带补全**（沿 R111 E7/E8 思路，本次一并修）：mood 导出补 `statusPhrase`（及确认 v5 已含的 audio/period/influenceFactors/recordingMode 不丢）；vent 导出补 `tagsJson`
- 测试：v6 round-trip 7 case + v5 老文件导入兼容 case

### A5. consent 精简

- `ConsentKind` 删 `emergencyContactSharing` + `safety`（剩 `dataExport` / `vent` / `analytics`）
- `consent_preference_store.dart`：删 contactId 序列化（L166-225）与 safety 偏好段
- `consent_dialog.dart` / `core/shared/consent_gate.dart`：删 2 分支
- `legal_page.dart`：删 §14 safety 撤回卡（`legalPageWithdrawSafety*` keys）

### A6. setup / settings / home / 通知修改

- **setup**：`setup_step_welcome.dart` 删联系人表单（L42-55 参数、L121-131）；`setup_page_state.dart` 删 contact controllers；`setup_submit_flow.dart` / `setup_committer.dart` 删 contact 参数与 insert；`setup_legal_dialog.dart` 删 SMS 同意文案、保留热线 section
- **settings**：`widgets/profile_group.dart` 删联系人 section（L84-98）；`reminders_hub_page.dart` 删失联卡 + `_SafetyReminderSheet`（L355-431）；`reminders_hub_provider.dart` 删 safety 配置
- **home**：`home_page_state.dart` 删 `_runSafetyCheck`、safety imports、`HomeLifecycleState` 的 2 个 safety 状态；`home_care_engine_dispatcher.dart` **整删**；`home_deep_link_handler.dart` **保留**（打卡 autofire deep link 仍需），仅删 `scheduleSafetyRerun` 枚举值 + `reason=safety` 分支；`check_in_notifier.dart` 删 TriggerReminderUseCase 调试入口
- **通知**：`notification_service.dart` 删 `showSafetyAlert`（L348-402）、safety 频道 3 const、id band 5000000；`notification_payload.dart` 删 `safetyAlert` 枚举（4 处）；`notification_delegate.dart` 注释同步；`domain/logic/notification_deep_link_resolver.dart` 删 safety-alert 映射；`app_route_check_in.dart` 删 reason=safety 重定向；`badge_sync_service.dart` id band 注释同步
- **main.dart**：删 sms/email import、validateForRelease 块、2 个 provider override；`service_providers.dart` 删 5 个 safety/reminder provider（safetyAlertSender / dispatchSafetyAlertUseCase / safetyWatchService / safetyConfigService + reminderService 的 sms 参数）
- **user_profile_repository / reminder_checker**：删 safety 接口残留（具体以 analyze 报错为准）

### A7. FeatureFlags 7→4

删 `emergencyContactEnabled` / `aliyunSmsEnabled` / `emailServiceEnabled`（含 per-flag setter）。保留 `phqGad7I18nEnabled` / `bootReceiverEnabled` / `fiveVendorPushEnabled` / `ventAudioEnabled`。

## 4. Workstream B — UI 权重调整

### B1. 导航 4 tab

`app_shell.dart` `_destinations`：

| tab | 路径 | 图标 |
|---|---|---|
| 心情 | `/` | sentiment_satisfied |
| 树洞 | `/vent` | forum_outlined |
| 趋势 | `/trend` | show_chart |
| 设置 | `/settings` | settings |

- 宽屏 NavigationRail / 窄屏 NavigationBar 同步；`_currentIndex` 前缀匹配更新（`/vent/*` 归树洞 tab）
- `/medication` 从 tab 移除，路由保留（首页快捷操作 + 趋势页可达）
- `app_routes.dart` 注释同步；`navCheckIn`/`navMedication` ARB key 替换为 `navMood`/`navVent`/`navTrend`

### B2. 首页重构（`home_page_state.dart` build）

新顺序（自上而下）：

1. 通知失败 banner（保留）
2. **MoodHeroCard（新）**：最新一条 mood 的状态短语大字 + 4 维迷你分 + 上次记录时间 + "记录心情"按钮 → `MoodRecorderPage.show`
3. **VentHeroCard（新）**：最新树洞预览（1 行截断）+ "写心事"按钮 → `/vent/compose`
4. **打卡**：CheckInButton 保留但从 64pt 巨型 pill 改为次级尺寸（新 `compact: true` 变体，或复用 PrimaryButton pill）
5. 今日指标 TodaySummaryCard（保留）
6. 快捷操作 PrimaryActionRow：用药 / 量表 / **情绪回顾** / 热线（FAB 工具栏 4 工具保留，文案"心情测试"→"情绪日记"）
7. EncouragementText + HomeFooter（保留）

- QuickMoodCarousel 与 SecondaryActionRow 从首页移除（功能并入 MoodHeroCard / 快捷操作）
- 新增 widget 文件：`home/widgets/mood_hero_card.dart` / `home/widgets/vent_hero_card.dart`

### B3. home 状态机简化

删 safety 生命周期状态后 `HomeLifecycleState` 只剩 deep-link 相关分支；`home_care_engine_dispatcher.dart` 整删；`_onCheckIn` 里 care 编排调用删。

## 5. Workstream C — 新功能

### C1. 树洞标签

- **schema**：`vent_entries.tagsJson` TEXT default `'[]'`（A3 一并）
- **domain**：`domain/logic/vent_tag_library.dart` — 预置 8 标签（家庭/工作/学业/亲密关系/朋友/身体/情绪/其他）+ `presetVentTags` 常量；entity 加 `tagsJson`（沿用 mood tags 的 `List<String>` ↔ JSON 编解码模式，`core/shared/json_codec.dart`）
- **compose**：`vent_compose_page.dart` 加标签 chips 多选 section（预置 chips + 自定义标签输入，复用 mood_tags.dart 交互模式）
- **列表**：`vent_list_page.dart` 顶部筛选 chips（全部 + 已用标签）；**detail**：显示标签
- **隐私边界不变**：标签仅本地检索，不进趋势/分析/通知（守门员 `check_cross_feature.py` 已有 vent 边界规则）
- mapper round-trip + 筛选测试

### C2. 状态短语

- **schema**：`mood_entries.statusPhrase` TEXT nullable（A3 一并）
- **domain**：`domain/logic/status_phrase_library.dart` — 预设短语库按 4 情绪方向分组（各 4-6 条，如「疲惫但平静」「被治愈了」「有点慌」）
- **记录 dialog**：`mood_recorder_page.dart` 加"此刻状态"section：预设 chips（按当前所选 score 方向优先显示对应组）+ 自由输入覆盖（输入即自定义）
- **展示**：MoodHeroCard 大字显示最新短语；无短语退化显示 4 维概括；`mood_list_page` / `mood_detail_page` 行内显示
- **导出**：A4 一并补 statusPhrase

### C3. 情绪回顾页

- **路由**：`/mood-review`（`app_route_mood_list.dart`），页 `pages/mood_list/mood_review_page.dart`
- **domain**：`domain/logic/mood_review_aggregator.dart` 纯函数：

  ```
  MoodReviewSummary summarize(List<MoodEntryEntity> entries, DateTime start, DateTime end)
  // → 记录天数 / 4 维均分 + 环比(上周同维度) / 高频标签 top5 / 高频影响因素 top5
  //   / 时段分布(4 period) / CBT 次数 / 鼓励文案(按均分分档)
  ```

  0 Flutter 依赖；日期过滤用 `endInclusive` 语义；环比上周缺数据时显示"—"

- **UI**：周/月切换（默认周，SegmentedButton）；摘要卡 AppleListSection 风格；入口 = MoodHeroCard 尾部"回顾"链接 + 心情 tab
- 纯函数测试 ≥ 12 case（空集/单条/跨月边界/环比缺上周/鼓励分档）

## 6. i18n

- 删 ~80 key × 3 语言（safety*/contact*/care*/lostContact*/emergency*/reminderHubSafety*/legalPageWithdrawSafety*/setupContact*/importSummaryContact）
- 新增 key：mood hero/vent hero/标签/状态短语/回顾页 ≈ 30 key × 3 语言
- `core/l10n/strings.dart` 同步删 safety/lost-contact/careCopy 段
- 重跑 `flutter gen-l10n`；`check_arb_keys.py` / `check_orphan_arb_keys.py` / `check_zh_hant_consistency.py` 必须绿

## 7. 测试计划

- **整删 ~27 个测试文件**（safety/sms/email/contact/care/lost_contact/email_template 命名 + safety_test_helpers 等，~4500 行）
- **改 ~20 个**：home 系列（lifecycle/emil/fab/hide/controllers）、setup 系列（committer/page_state/consent/legal）、export v5/v6 系列、feature_flags 3 文件、notification 系列、r93_doc_consistency、reminders_hub_safety_gate、data_safety_form
- **新增**：vent_tag round-trip + 筛选、status_phrase 记录/大卡、mood_review_aggregator（≥12 case）、migration 22→23 升级、export v6 round-trip + v5 兼容
- 预期终态 ~2400+ pass / 4 fail（iOS 资产）/ 1 skip

## 8. 守门员变更

| 脚本 | 动作 |
|---|---|
| `check_sms_release_ready.py` | 整删（失联 SMS 已不存在） |
| `check_pii_in_title.py` | 删 `safetyAlertTitle` 与 contactName 相关黑名单项 |
| `check_legal_consent.py` | 删 §13 紧急联系人单独同意检测，保留 dataExport/vent 检测 |
| `check_cross_feature.py` | vent 边界规则保留，无 contact 规则需要改 |
| 其余 18 个 | 自动绿（arb/orphan/zh_hant/coverage 随代码同步） |

## 9. 文档

- `README.md`：副标题删"失联通知"，定位改"情绪日记 + 树洞倾诉优先、用药记录辅助"
- `docs/CHANGELOG.md`：新 `[1.1.0]` 条目（功能调整 + 3 新功能 + 删除外联）
- `AGENTS.md`：隐私边界表、FeatureFlag 清单 7→4、守门员清单 22→21、路线图
- `pubspec.yaml` 版本 `1.1.0+148`

## 10. 实施顺序（一个 round 系列，6 commit，TDD 全程）

| round | 内容 | 验证 |
|---|---|---|
| r1 | 新功能 domain 层（vent_tag_library / status_phrase_library / mood_review_aggregator + 纯函数测试） | domain test 绿 |
| r2 | schema 22→23 + entity/mapper + build_runner + migration 测试 | data test 绿 |
| r3 | export v6 + v5 兼容 + round-trip 测试 | export test 绿 |
| r4 | 外联全链删除（A1-A7 整删 + 修改），analyze 驱动清理残留 | analyze 0e + 剩余 test 绿 |
| r5 | UI：导航 4 tab + 首页重构 + vent 标签 UI + status phrase UI + 情绪回顾页 + i18n 重生成 | widget test 绿 |
| r6 | 测试收尾 + 守门员 + 文档 + CHANGELOG | 21 守门员绿 + 全量 test |

r4 是最大 commit，若 analyze 报错面过大可拆 r4a（setup/settings 摘除）+ r4b（services/domain 删除）+ r4c（通知/路由/feature flags）。

## 11. 验收标准

1. `flutter analyze` 0 error / 0 warning
2. `flutter test` 全过（除 4 个 iOS 资产占位 fail + 1 skip）
3. 21 个守门员脚本全绿（删 check_sms_release_ready 后）
4. `dart scripts/check_all.dart` 0 violation
5. schema 22→23 老数据升级测试通过；export v5 文件可导入
6. 树洞/情绪/提醒功能冒烟：记录心情带短语 → 首页大卡显示 → 回顾页有数据 → 树洞带标签可筛选 → 吃药提醒照常触发 → 热线页可开

## 12. 风险与缓解

| 风险 | 缓解 |
|---|---|
| `reminder_scheduler.dart`(data) 混有药物提醒逻辑 | 实现时逐行核对调用方；domain 版 reminder_scheduler 保留兜底 |
| l10n 删除波及 3 个生成文件 + gen-l10n 版本差异 | 只删 key、不手改生成文件，重跑 gen-l10n |
| 老用户升级丢联系人数据（不可逆） | 设计上明确接受（D1 决策）；migration 注释写明 |
| test 联动面大（~50 文件） | r4/r6 用 explore agent 先列全依赖再删 |
| home 状态机改动引发 race | lifecycle 简化为 2 态，保留现有 round67/round108 home 测试改跑 |

## 13. Out of scope（本轮不做）

- 商店文案/截图/应用名变更
- HealthKit / 鸿蒙 / 5 厂商 push（v1.0 路线图外延）
- 量表 i18n（R51b）、god class 长线拆解（AR-20）
- 树洞/情绪内容分析类功能（隐私边界）
