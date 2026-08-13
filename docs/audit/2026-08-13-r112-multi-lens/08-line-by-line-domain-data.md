# 底层逐行 domain+data 审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: 底层逐行排查 第 1 路 (domain + data)
- 审视者: subagent 08 (line-by-line domain+data)
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M 13??
- 范围: `lib/domain/` 82 文件 (entities 26 / logic 33 / repositories 17 / usecases 6) + `lib/core/data/` 87 文件 (app_database + 14 DAO + 3 connection + 13 tables + 8 mappers + 16 repository impl + 39 services + export/ 5 + privacy 1 + utils 1 + feature_flags) + `lib/core/l10n/strings.dart`。**约 170 文件全部遍历** (大文件分段读, 纯数据类 entities/repos abstracts 走 grep 验证 0 逻辑)。
- R112 重点实读: export v5 (`export_schema_service` / `export_orchestrator` / `export_import_pipeline` + 新测试 `data_export_v5_round8_test.dart`) / `user_name_helper` 迁移 / `tracking_item_config` / `safety_alert_builder` + `safety_alert_sender_impl` + `dispatch_safety_alert` / 10 量表文件 (asrm/isi/pss/whodas/level2×4/phq9/gad7) / `app_database.saveSetup` E5 修复 / `static_scale_translations`。

## 1. 整体评分 (0-10)

**8.0** — 单文件层几乎 0 bug (日期时间 race / 空 catch / 隐式排序 / 资源泄漏 / 通知 ID / 锁屏 PII 全绿); R111 E1/E2/E3/E5 已真闭环 (代码 + 7 case 测试实锤); 扣分全在 **export v5 仍缺 6 张 daily tracking 表 + profile 同意留痕** 这两块数据完整性缺口, 以及 2 个展示层小 bug。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0 (必修, 阻塞上架/严重 bug)

- [底层] **[P0-001] R112-01 (E6): export v5 仍完全缺失 6 张 daily tracking 表 — 换机/重装静默丢整块健康数据** — 难度:M — 工作量:~1d
  - 位置: `lib/core/data/services/export/export_orchestrator.dart:103-249` (只导出 profile/contacts/medications/checkIns/reportHistories/moodEntries/ventEntries 7 段) vs `lib/core/data/database/app_database.dart:50-65` (DB 有 13 张表)
  - 现状: `sleep_entries / social_rhythm_entries / stress_events / treatment_entries / weight_entries / anxiety_agitation_entries` 6 张表 (v0.30 R91 加的日常追踪功能) **0 导出 0 导入**。用户"导出 → 新设备导入"后, 睡眠/体重/社会节律/应激事件/治疗记录/焦虑躁动全部**静默丢失**。import 也不 clear 这 6 表 (同设备 import 留下 stale 数据)。R111 E1 只对 medications/mood/contacts 做了逐字段对照, 漏了这 6 张整表。grep 证实 export/ 目录 0 处引用 sleepDao/weightDao 等 (见附录)。
  - 建议: v5 (或 v6) schema 补 6 段双向 + round-trip test; import 段同时 clear 这 6 表 (跟现有 checkIns/medications 处理一致)。

### P1 (应修, 影响品质)

- [底层] **[P1-001] R112-02 (E7): profile 层 PIPL §14 同意留痕 4 字段不导出 — 撤回状态跨设备断裂** — 难度:S — 工作量:~2h
  - 位置: `export_orchestrator.dart:130-139` (profile 只导 userName/checkInCycleHours/firstLaunchAt/lastCheckInAt) vs `user_profiles.dart:31-40` (userAgreementVersion/privacyPolicyVersion/sensitiveDataConsentAt/consentRevokedAt 4 列)
  - 现状: E2 只修了 contact 侧 4 字段, **profile 侧 4 字段仍漏**。用户在旧设备撤回同意 (consentRevokedAt 有值) → 换机导入后新设备 profile 无任何撤回记录 → PIPL §14 审计留痕断裂 + "撤回状态"重置 (功能层 Gate 走 prefs 不受影响, 但 DB 审计数据缺失)。R111 报告未发现此项。
  - 建议: profile 段导出 4 字段 + import 段写入 (走 `Value(...)` nullable, 老文件优雅降级), 与 contact E2 修法同款 + round-trip test。

- [底层] **[P1-002] R112-03 (E8): medications 导出走 watchActive() — 软停药 (inactive) 药名在换机后从历史消失** — 难度:M — 工作量:~4h
  - 位置: `export_orchestrator.dart:112-115` (`_db.medicationDao.watchActive()`)
  - 现状: 用户停用的药 (isActive=false, 软删) **整个 med 行不导出**。换机后: 该药名从用药报告/历史打卡 join 中永久消失, 关联 checkIns 的 medicationId 被 E3 重映射逻辑置 null (medIdMap 无此 id)。报告生成 (`medication_report`) 特意用 `watchAllIncludingInactive` 还原历史 (medication_repository_impl.dart:34-38), 导出却没用 — 自相矛盾。
  - 建议: 导出改 `watchAllIncludingInactive()`, import 保留 `isActive` 字段 (已实现), E3 映射自然覆盖 inactive 药。

- [底层] **[P1-003] R112-04 (E9): 趋势页日历选中日详情 — 8 个新量表显示 raw scaleId ("level2_depression")** — 难度:S — 工作量:~1h
  - 位置: `lib/domain/logic/day_detail.dart:371-394` (`_scaleName` default 分支 `return scaleId`) + `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart:55-56` (只注入 phq9Name/gad7Name 2 个 closure)
  - 现状: caller 只传 phq9/gad7 2 个 closure, isi/pss/whodas/asrm/level2×4 的评估事件 title 直接显示数据库 wire 字符串。用户做了 WHODAS 评估后, 日历详情显示 "whodas" 而不是量表名。
  - 建议: `_scaleName` 对未知 id 走 `scale_registry.scaleById(id)?.displayName ?? scaleId` (domain 内直接可用) 或 presentation 注入第 3 个 closure。

### P2 (可修, 优化)

- [底层] **[P2-001] R112-05: import `isActive` 字段 `as bool?` cast 遇脏数据抛 TypeError → 整个 import 失败** — 难度:S — 工作量:~0.5h
  - 位置: `export_import_pipeline.dart:139` (`m['isActive'] as bool? ?? true`)
  - 现状: v4 老文件若 isActive 是 0/1 (int) 或 "true" (string), `as bool?` 抛 TypeError → 外层 catch → 全部导入失败 (只给用户"解析失败"通用提示)。同文件其他字段全走 `validateString/validateInt` 优雅降级, 这是唯一裸 cast。
  - 建议: `m['isActive'] is bool ? m['isActive'] as bool : true`。

- [底层] **[P2-002] R112-06: lastCheckInAt 导出但 import 不读 — P0-10 意图未实现 + 死字段** — 难度:S — 工作量:~0.5h
  - 位置: `export_orchestrator.dart:136-138` (导出 `if (profile.lastCheckInAt != null) 'lastCheckInAt': ...`) vs `export_import_pipeline.dart:88-114` (import 只写 userName/checkInCycleHours/firstLaunchAt)
  - 现状: 导出注释明确写 "P0-10: 顺便带上 lastCheckInAt, 导入后立即可见", 但 import 段从不读该 key。换机后 lastCheckInAt 归 null (失联检测 UI 快查字段), 首屏"上次打卡"短暂错乱。
  - 建议: import 段补 `lastCheckInAt: Value(ExportSchemaService.validateDate(p['lastCheckInAt']))` (upsert 支持)。

- [底层] **[P2-003] R112-07: data_export_service.dart doc 仍写 "v4 (current)"** — 难度:S — 工作量:5min
  - 位置: `lib/core/data/services/data_export_service.dart:35`
  - 现状: v5 升级后 facade doc 未同步 (export_schema_service.dart 已更新, 此处漏)。
  - 建议: 改 "v5 (current, v0.32 round 8 R111 E1/E2/E3)…"。

- [底层] **[P2-004] R112-08: notification_delegate.dart 3 处 doc 注释仍写旧 id (8000/7000/9999)** — 难度:S — 工作量:5min
  - 位置: `lib/core/data/services/notification_delegate.dart:87, 94, 99`
  - 现状: mood/assessment/badge 已迁 5M+ 固定带 (B1-1), delegate 注释未同步, 与 notification_service.dart:410-422 的文档化列表矛盾, 后人改 cancel range 会被误导。
  - 建议: 3 处注释改 `5000002 / 5000001 / 5000100`。

### P3 (建议, 长期)

- [底层] **[P3-001] R112-09: showSafetyAlert 的 userName 参数死代码** — 难度:S — 工作量:5min
  - 位置: `lib/core/data/services/notification_service.dart:380-405` (签名有 `String? userName`, body 内 0 引用)
  - 现状: B1-5 只修了 `SafetyAlertBuilder.buildFor` (删参数), facade 签名没同步删 — 死参数残留, caller (safety_alert_sender_impl.dart:82-88) 仍传 userName 走空。
  - 建议: 删参数 + sender_impl 同步。

- [底层] **[P3-002] R112-10: NoOpDispatchSafetyAlertUseCase extends 具体类 + lib 层 test helper** — 难度:S — 工作量:10min
  - 位置: `lib/domain/usecases/dispatch_safety_alert.dart:89-132`
  - 现状: 继承 concrete UseCase 只为 override call(); `_NoOpSafetyAlertSenderState` 放 lib 生产文件。与同文件文档 "test 跨期 helper" 声明不符 (test helper 应进 test/ 或至少标 @visibleForTesting)。
  - 建议: 移到 `test/helpers/` 或标 @visibleForTesting + 改 implements。

- [底层] **[P3-003] R112-11: 8 个新量表 items/options/severityCutoffs 仍硬编码中文 (E4 只部分闭环)** — 难度:M-L — 工作量:~1d (R51b backlog)
  - 位置: `lib/domain/logic/{isi,pss,whodas,asrm,level2_*}.dart` items/options/severityCutoffs (硬编中文, 仅 displayName/shortDescription/instruction 走 translations)
  - 现状: R112 把 name/desc/instruction 接上 translations (en 用户量表名不再中文), 但题目正文+选项+严重度 label 仍是中文 — en locale 做 ISI 看到全中文题目。`ScaleTranslations` 接口的 `isiItem()` 等 50+ 方法仍是 **0 运行时 caller** (presentation 是否接上不在本 scope, 但 domain 侧 scale 类未消费)。
  - 建议: 接上 translations 或明确标 R51b; 保持现状则 items getter 与 translations.xxxItem 双源漂移风险 (已有: static_scale_translations._asrmItemsZh 与 asrm.dart items 两处同文案)。

- [底层] **[P3-004] R112-12: 老 v4 文件导入 checkIn.medicationId 全部置 null (关联丢失, 文档化取舍)** — 难度:0 — 工作量:0
  - 位置: `export_import_pipeline.dart:174-177, 246-249, 275-277`
  - 现状: v4 文件无 med 'id' → medIdMap 空 → 所有历史打卡失去药物关联 (已注释文档化, "旧 id 跨设备无意义")。可接受, 但可在 R112-03 (inactive med 修复) 时顺带用"导出顺序 index 对齐"恢复 v4 关联。
  - 建议: 记录为已知取舍, 不阻塞。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| lib/core/data/services/sms_service.dart:109 | https://dysmsapi.aliyuncs.com/ + help.aliyun.com (注释) | 占位符 (R55 TODO 注释) |
| lib/core/data/services/notification_payload.dart:82-89 | `chroniccare://` 自定义 scheme (本地 deep link, 非外链) | 正常 |

本 scope 无真实外部 URL/域名/邮箱泄露。

## 4. 四类问题 (用户点名)

### 4.1 上架相关
- 锁屏 PII: 通知 title/body 全走通用文案 0 药名 0 姓名 (`strings.dart:112-117` / `safety_alert_builder.dart:88-96` 决策注释) ✓; Android visibility=secret (reminder/snooze/badge/showNow) ✓; safety alert 有意 public (有注释决策) — 建议法务复核留档。
- SMS release 守卫 (`validateForRelease`) + Email 守卫双保险 ✓ (mock/未接 provider 启动即 banner)。
- IAP: `FeatureFlags.iapEnabled=false` 早返 + release 占位 return false ✓ (无假购买)。

### 4.2 架构相关
- domain 0 Flutter 0 Drift: R112 移动的 `user_name_helper.dart` → domain/logic 后 import 更新完整 (lost_contact_sms/email_template/test 3 处, 0 stale import) ✓; `dispatch_safety_alert.dart` 构造注入 FeatureFlag ✓; scale logic 走 `core/l10n/strings.dart` (domain 允许) ✓。
- 一致性: `safety_alert_sender.dart` (domain abstract) → `safety_alert_sender_impl.dart` (data impl) → `dispatch_safety_alert.dart` (use case) 链完整, 0 循环依赖。
- `static_scale_translations.dart` 810L 仍是 0-test 大户 + 与 10 个 scale class 双源文案 (SP-111-04 只给部分 scale 补了 test), 待 R111 路线图 AR-17 三源合一。

### 4.3 重构建议
- export/import: P0-001 修 6 表时可顺手抽 `_importDailyTracking(json)` / `_exportDailyTracking()` 两个 private 方法, 保持 `runImportFromJson` 单一职责 (现 530L 已在临界)。
- `export_import_pipeline.dart` 的 import profile 段 (88-114) 与 user_profile upsert 语义耦合 — 建议走 `userProfileDao.upsert` + 显式 4 consent 字段, 与 P1-001 合并修。

### 4.4 半成品 / TODO / 残缺功能
- AliyunSmsProvider.send / EmailService 真发 (R55 TODO) — 有 release 守卫兜底, 非缺陷。
- PHQ-9/GAD-7 16 题 i18n 已通; 8 新量表题目 i18n 未接 (P3-003)。
- `MoodPeriod.unspecified` 与 `period=null` 归一在 aggregator 层 ✓ (不在 DAO)。
- export audio: mood/vent 录音文件本体不导出 (跨设备 stale 路径, 文档化决策) ✓。

## 5. 总结 + 给整合者的建议

1) **R111 E1/E2/E3/E5 四项全部实锤闭环**: export v5 双向字段 + consent 4 字段 + checkIn FK 重映射 + saveSetup StateError, 均有 7 case round-trip 测试 (`test/data/data_export_v5_round8_test.dart`) 守门。B1-5 半闭环 (builder 修了, facade 死参数残留 → P3-001)。
2) **新发现 1 P0**: export v5 仍缺 6 张 daily tracking 表 (R91 加的睡眠/体重/社会节律/应激/治疗/焦虑躁动) — 与 E1 同类但严重一个量级 (整表丢失), R111 逐字段对照漏掉整表。建议 R112 收尾时直接补 (否则 v5 上线后还要再 bump v6)。
3) **新发现 2 P1**: profile PIPL §14 留痕 4 字段不导出 (E2 只修了 contact 侧) + inactive 药从导出消失 (报告用 watchAllIncludingInactive、导出用 watchActive 的自相矛盾)。
4) 健康项全绿 (与 R111 一致并复验): 43 处 DateTime.now() 单次调用纪律 / 0 空 catch / streak-comparison-reminder-care 全部显式 sort / Timer+try/finally 资源纪律 / 通知 ID 5M+ 固定带与 200000 cancel range 匹配 / 迁移链 v1→v22 guard 正确 / UTC 存 ISO 纪律 / 锁屏 PII 0 泄露。
5) 建议主 agent 整合时把 P0-001 (E6) 排 R112 收尾 (与 export v5 同批, 避免二次 schema bump), P1-001/002 可随 E6 一个 PR 一起做。

## 附录: 详细证据 (grep 输出、文件引用)

```
# E6 证据: export/ 目录 0 处引用 daily tracking DAO
$ grep -rn "sleepDao\|weightDao\|socialRhythmDao\|stressEventDao\|treatmentDao\|anxietyAgitationDao" lib/core/data/services/export/
(0 命中)

# E7 证据: profile 导出段无 consent 字段
export_orchestrator.dart:130-139  →  'profile': {userName, checkInCycleHours, firstLaunchAt, lastCheckInAt}
user_profiles.dart:31-40          →  userAgreementVersion / privacyPolicyVersion / sensitiveDataConsentAt / consentRevokedAt

# E8 证据
export_orchestrator.dart:112      →  _db.medicationDao.watchActive()
medication_repository_impl.dart:34-38 → watchAllIncludingInactive (报告用, 对比)

# E9 证据
day_detail.dart:391-393           →  default: return scaleId;
trend_day_detail_card.dart:55-56  →  只传 phq9Name/gad7Name

# E1/E2/E3 闭环证据
test/data/data_export_v5_round8_test.dart:47-249 (7 case 全过: 5 字段×2 / mood 5 字段×2 / consent 4 字段 / FK 重映射×2)

# 通知 ID 固定带 (B1-1 保持)
notification_service.dart:83      →  safetyAlertId = 5000000
assessment_notifier.dart:28       →  assessmentReminderId = 5000001
mood_reminder_notifier.dart:28    →  moodReminderId = 5000002
badge_sync_service.dart:29        →  badgeVirtualId = 5000100
reminder_dispatcher.dart:28       →  kReminderCancelRange = 200000 (cancel [base, base+200000))

# E5 闭环证据
app_database.dart:457-463         →  contactList.length != contactConsents.length → throw StateError (release 生效)
```

<!-- subagent: line-by-line-domain-data 完成时间: 2026-08-13T12:00:00Z -->
