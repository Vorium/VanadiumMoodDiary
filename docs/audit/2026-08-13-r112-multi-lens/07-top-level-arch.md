# 顶层架构审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: 顶层架构 (全局架构评估 + 高内聚低耦合 + 重构建议)
- 审视者: subagent 07 (top-level-arch)
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M 13?? (R112 进行中)
- 范围: 全 lib/ 分层纯度 + god class 普查 + usecase 层 + provider 组织 + 路由架构。关键文件: `scripts/check_all.dart` / `scripts/check_usecase_layer.py` / `scripts/check_cross_feature.py` / `lib/core/data/database/app_database.dart` / `lib/core/data/services/{safety_watch_service,notification_service,refill_notifier,export/*}.dart` / `lib/domain/usecases/*` / `lib/domain/entities/scale_translations/*` / `lib/presentation/services/*` / `lib/presentation/providers/*` / `lib/core/routing/*` / `lib/core/shared/*`。

## 1. 整体评分 (0-10)
**6.0/10** — 边界层 (纯度/一致性/跨 feature/仓库 17:17) 满血 0 violation, 但结构层 4 大债 (AR-16/17/18/19) 全部跨期残留: usecase 层 6 文件中 2 个是死代码, scale 名派发 R112 反增到 4 源, god class 21 个 ≥400L 基本反涨。与 R111 (6.0) 持平: R112 有 3 个小进步 (safety_watch_service 依赖收窄 / usecase 守门员唯一 warning 闭环 / user_name_helper 移到 domain 正确层), 但被 scale 名 4 源 + export_import_pipeline 530L 新 god class 入口抵消。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0 (必修, 阻塞上架/严重 bug)

- [架构] **[AR-16] data→生成 ARB 循环仍 4 文件 + check_all 守门盲区** — 难度:L — 工作量:1wk
  - 位置: `lib/core/data/services/safety_watch_service.dart:15` / `preset_medication_templates.dart:3` / `cbt_thought_record_pdf.dart:22` / `cbt_thought_record_pdf_layout.dart:20`
  - 现状: 4 个 data 文件 import `package:chroniccare/l10n/app_localizations.dart` (生成 ARB, 传递 import flutter/widgets)。实测 `scripts/check_all.dart` 的 `_purityRules['data']` 只禁 `package:chroniccare/presentation/`, **不禁 `package:chroniccare/l10n/`** (l10n 守门只挂在 domain 规则上, check_all.dart:40-43 vs :244)。所以 data→l10n→flutter 的传递依赖守门员 0 感知 — 这是 AR-16 跨 3 轮审计不动的原因之一: 没有任何 gate 会 fail。
  - 建议: (1) 把 `package:chroniccare/l10n/` 加入 `_purityRules['data']` 让 gate 先红 (半天); (2) 4 个 service 改走 `core/l10n/strings.dart` 或 caller 注入的字符串 resolver (safety_watch_service 已有 l10nResolver tear-off 方案注释, notification_service.dart:377 注释明示待删 import)。修完 pub workspace 前置 (AR-14) 才解锁。

- [架构] **[AR-17] scale 翻译 4 源并存 — R112 从 3 源恶化到 4 源 + 810L 死代码** — 难度:L — 工作量:2-3d
  - 位置: `lib/domain/entities/scale_translations/static_scale_translations.dart` (781L, 活跃 fallback) / `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` (810L, **0 运行时 caller**) / `lib/presentation/services/scale_name_l10n.dart` (40L, R112 新增, 3 caller) / `lib/presentation/pages/assessment/widgets/assessment_center_card.dart:37` (`_l10nName` 私有 switch, 与 scale_name_l10n 逐 case 重复, **R112 没迁走**)
  - 现状: R112 修 EM-21 (en 显示中文量表名) 加了 `scaleNameL10n` 公共 helper, 但: (a) assessment_center_card 的私有 `_l10nName` switch 原样保留 → name 派发现在 2 处平行; (b) 810L 的 `AppLocalizationsScaleTranslations` (10 量表 186 method) 仍 0 运行时 caller, 只有 test/domain/scale_translations_round78_test.dart 等 lock-in test 引用; (c) R90 加的 8 新量表 186 method stub 全返 `''`。合计 1,631L 中 ~850L 是无运行时价值代码。
  - 建议: 删 810L l10n impl (test 改测 scaleNameL10n + domain static); assessment_center_card 改用 `scaleNameL10n`; 短描述派发并入同 helper。预计净删 ~1,600L, 量表名 source of truth 收敛为 domain static (fallback) + 1 个 presentation helper (name/shortDesc) 2 源。items i18n (R51b) 另行规划。

- [架构] **[AR-18] usecase 层 6 文件 739L, 其中 2 个是死代码 (0 运行时 caller)** — 难度:M — 工作量:1-2wk
  - 位置: `lib/domain/usecases/check_safety.dart` (71L) / `lib/domain/usecases/schedule_refill_reminder.dart` (103L)
  - 现状: 全 lib/ + test/ 实扫: `CheckSafetyUseCase` 只有自身文件 + 自己 test 引用 — 实际判定走 `safety_watch_service.dart:175` 直接调 `SafetyDetector.detect` (绕过 usecase); `ScheduleRefillReminderUseCase` 同理, 实际调度走 `refill_notifier.dart` 直接调 `RefillScheduler.computeRefillFireTime`。即 usecase 层 174/739L (24%) 是"有 test 但无接线"的死代码。另有编排逻辑仍在别处: safety_watch_service 395L (load contacts + detect + result 翻译) / refill_notifier 214L / home_care_engine_dispatcher 182L (presentation) / legal_consent_provider 291L / streak 计算在 shared_providers provider。
  - 建议: 二选一 — 接线 (safety_watch_service 改调 CheckSafetyUseCase, RefillNotifier 改调 ScheduleRefillReminderUseCase, 半天即可) 或删 (承认 usecase 层只留 4 个有 wire 的)。推荐接线 + 顺手把 safety_watch_service 的 `_loadContacts`+`_translateResult` 收进 usecase 输入输出, service 变薄 orchestrator。R111 计划 "6→14-16" 不现实, 务实目标 6→8。

### P1 (应修, 影响品质)

- [架构] **[AR-19] saveSetup (1 tx 写 3 实体 70L) + clearAllUserData 仍在 AppDatabase** — 难度:XL — 工作量:3-5d
  - 位置: `lib/core/data/database/app_database.dart:420-489` (saveSetup) / `:511-519` (clearAllUserData)
  - 现状: 与 R111 一致, 文件注释 (:410-411) 明示"刻意保留 business orchestration"。app_database 520L (R111 513L, 反涨)。saveSetup 含 PIPL §13 consent 长度校验 StateError + 3 实体 upsert, 是标准 setup usecase 内容, 放 DB 门面违反单一职责; 但它也是唯一保证"setup 原子性"的位置, 抽走需保持 transaction 语义。
  - 建议: 抽 `SetupCommitter` (data service) 或 `CompleteSetupUseCase` (domain, 依赖 3 repo + transaction 注入)。注意: transaction 属 Drift 概念, usecase 化需要 repo 提供 `runInTransaction` 回调接口 — 属于"3-5d"难度来源。

- [架构] **[AR-20] god class 21 个 ≥400L (排除 3 个生成 ARB), 拆解仅 1/21 完成** — 难度:XL — 工作量:1-2mo
  - 位置: 见附录 A 全表
  - 现状: 我重新统计 lib/ 全量 (git ls-files, 排除 app_localizations_zh/en/app 3 个生成文件): **21 个 ≥400L**。与 R111 22 个基本持平, 拆成只有 medication_page (R110 553→347)。多数反涨: static_scale_translations 659→781 / add_medication 506→571 / mood_audio_recorder 529→589 / mood_trend 517→559 / app_database 494→520 / legal_page 460→496 / export_import_pipeline (R112 v5 升级) →530 新入口。仅 safety_watch_service 403→395 微降 + notification_service 417→445 (拆 facade 后回涨)。
  - 建议: 沿用 R110/R111 验证过的"先补 test 再拆"路径 (7b round 已给 6 个补 test)。下一批按 ROI 排: export_import_pipeline (530L 单函数顶层级, 4 子任务已注释待拆) → setup_page_state (496) → add_medication (571) → vent 3 连 (compose 445 / detail 442 / list 406 + audio_lifecycle 439 = 1,732L vent 簇)。拆分目标不是行数而是"职责数 ≤2"。

- [架构] **[AR-23] swallowError 全局 sink 77 处调用, 跨 40 文件** — 难度:L — 工作量:3-5d
  - 位置: `lib/core/shared/swallow_error.dart:38` + 77 call sites (lib/), 88 含 test
  - 现状: R111 报 134 处, 本次实测 `swallowError(` 直接调用 77 处 (lib/) — 可能 R111 把注释/定义也算进去。仍是最宽的跨层 sink: audio_lifecycle / mood_audio_service / vent 3 页 / export 4 文件 / theme_provider / app_database 全都在用。core/shared 是"跨层共享工具"定位, 一个错误吞噬函数不算违规, 但耦合面说明"分层错误处理策略"缺失 — data 层静默吞错在 UI 层无感, 而 presentation 层吞错也没有本地 fallback。
  - 建议: 不为删而删。给 3 个簇 (audio / notification-safety / export) 各留 1 个带 scope 的 wrapper (如 `AudioErrorSink`, `NotificationErrorSink`), 其余 40+ 处改调 wrapper, 集中位置以后加 Sentry/Firebase 只改 3 处。

- [架构] **[R112-ARCH-01] legal_consent_provider (presentation) 直接 SharedPreferences 持久化 + 8 处 getInstance — data 层职责泄漏进 presentation** — 难度:M — 工作量:1-2d
  - 位置: `lib/presentation/providers/legal_consent_provider.dart:68,73,79,88,114,127,...` (291L, 8+ 处 `SharedPreferences.getInstance()`)
  - 现状: `LegalConsentStore` 是 PIPL §26 撤回同意/§13 audit log 的**唯一持久化** (SharedPreferences 存 consent 状态 + dataExport audit JSON log)。持久化逻辑放 presentation provider, 违反"presentation 不碰 IO"的隐含分层; 且 audit log 是法务证据, 放 SharedPreferences 无加密 (EncryptionService 已 import 但只用于 dataExport 内容? 需底层 agent 复核)。
  - 建议: 抽 `ConsentPreferenceStore` (data service, 注入 SharedPreferences + EncryptionService), provider 变薄 facade。跟 AR-19 同批做 (都是"数据编排下沉"主题)。

- [架构] **[R112-ARCH-02] data→core/routing 传递 Flutter 依赖, check_all 不覆盖** — 难度:S — 工作量:≤1d
  - 位置: `lib/core/data/services/notification_service.dart:50` / `notification_initializer.dart:93` → `lib/core/routing/notification_navigation.dart:3` (import `flutter/widgets.dart` + go_router)
  - 现状: notification_navigation 是静态 GoRouter 深链入口, 自身 import flutter/widgets + go_router。data 层 2 个 service import 它 → data 传递依赖 Flutter (purity 脚本只查直接 import, 且 core/routing 不在 data 的 forbidden 列表)。这是 AR-16 同款守门盲区的第二实例。方向性修复: 把 deep-link 路由决策下沉为 domain 可测的纯函数 (payload → route string), GoRouter 绑定留在 presentation/app 层; notification_service 只拿 route string 回调。
  - 建议: 低成本版 — check_all 给 data 加 `package:chroniccare/core/routing/` forbidden (除了豁免列表), 让 gate 显式管控; 中成本版 — NotificationNavigation 拆 `DeepLinkResolver` (domain 纯函数) + `NavigationBinding` (presentation)。

- [架构] **[R112-ARCH-03] export_import_pipeline 530L 成新 god class 入口 (R112 v5 升级后)** — 难度:M — 工作量:1d
  - 位置: `lib/core/data/services/export/export_import_pipeline.dart` (530L, R111 时 ~400L)
  - 现状: R112 E1/E2 v5 升级 (medications +5 字段 / moodEntries +7 字段 + contact consent 4 字段, 实读确认 v5 字段已落码) 让 runImportFromJson 继续膨胀。文件自注释 (R77 背景) 说"后续拆 4 子任务 (clearData/importProfile/importEntities/importVent) 为 4 private method" — 该计划 5 轮未执行。
  - 建议: 拆 4 子函数 + `ImportResultBuilder`。已有 data_export_v5_round8_test.dart 兜底, 拆解低风险。

### P2 (可修, 优化)

- [架构] **[AR-21] app_colors.dart 502L 纯色值表** — 难度:S — 工作量:≤2h
  - 位置: `lib/core/theme/app_colors.dart`
  - 现状: 8 metric palette + iOS system color 全静态 const, 无逻辑。god class 列表里唯一"假阳性" (职责数 = 1, 只是长)。可选: 按 palette 拆 2-3 个 part 文件或生成。低优先级。

- [架构] **[R112-ARCH-04] /mood-diary 与 /mood-list 双路由指向同一 MoodListPage** — 难度:S — 工作量:≤1h
  - 位置: `lib/core/routing/app_route_daily_tracking.dart:56` (path: '/mood-diary' → MoodListPage) vs `app_route_mood_list.dart:24` (path: '/mood-list' → MoodListPage)
  - 现状: R87 有 /mood-list 后, R91 daily_tracking 又加 /mood-diary 复用同页 (注释说"兜底"), 2 个 URL 进同一页, deep-link 语义歧义。查一下 daily_tracking 页面实际 push 哪个, 把没用的那个删掉。

- [架构] **[AR-26] 18 个 provider 文件 1996L composition root 散装** — 难度:M — 工作量:1-2d
  - 位置: `lib/presentation/providers/` (core 131 / service 128 / shared 165 / legal_consent 291 / mood_list_filter 247 / cbt 239 / daily_tracking 168...)
  - 现状: 与 R111 相同。legal_consent 291L 是 provider 里最大, 且混 persistence (见 R112-ARCH-01)。mood_list_filter 247L 是纯 UI 状态 (filter/sort/search), 放 providers/ 平铺其实合理。真正的收束点只有 legal_consent 一个。
  - 建议: 只做 legal_consent 拆分 (归入 R112-ARCH-01), 其余 17 文件不动 — 平铺 provider 不是问题, 问题只在"provider 里藏持久化"。

### P3 (建议, 长期)

- [架构] **[AR-22] core/routing 11 文件 1054L 依赖全部 pages (core umbrella 名不副实)** — 难度:L — 工作量:1wk
  - 位置: `lib/core/routing/app_route_*.dart` (import 所有 presentation/pages/*)
  - 现状: app_router.dart:19-22 注释已承认此 trade-off (go_router 必须知道 widget)。11 文件 / 35 条 route 按 7 个 feature 文件拆分 (R57 拆成), 结构本身健康, 只是物理位置在 core/ 下。
  - 建议: feature-first 重构时整体移入 `lib/features/{feature}/routing/`。在 pub workspace 前不动。

- [架构] **[AR-14] feature-first / pub workspace 0 进展, 前置 AR-16 未解** — 难度:XL — 工作量:2-3wk (feature-first) / 1mo (workspace)
  - 位置: 无 lib/features/, 无 pub workspace
  - 现状: 与 R111 一致。AR-16 (data→生成 ARB) 是 workspace 拆分的死锁前提, 不修它 3-package 拆法必出循环。
  - 建议: 见 4.3 路线, 排在 AR-16/17/18 之后。

- [架构] **[AR-28] domain→core/shared 方向依赖 (设计使然)** — 记录
  - 位置: `lib/domain/usecases/check_in_usecases.dart:17` (date_time_resolver)
  - 现状: domain 可 import core/shared (check_all 只禁 flutter/drift/data/presentation/l10n), 与 3-package 切法兼容 (pkg_domain 含 shared)。仅记录。

- [架构] **[AR-27] ✅ R112 闭环** — check_usecase_layer 唯一 warning 已修
  - 位置: `lib/domain/usecases/dispatch_safety_alert.dart:91` (`_NoOpSafetyAlertSender` → `_NoOpSafetyAlertSenderState`, R111 SP-111-16 fix, git diff 实读确认)。守门员现在 6 文件全合规 0 warning。

- [架构] **[AR-24/25] ✅ 保持** — 跨 feature 0 violation (138 文件) + 仓库 17 abstract ↔ 17 impl 1:1 (impl 均 ≤182L 薄 mapper)

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| fastlane/metadata/ios/{zh-Hans,zh-Hant,en-US}/privacy_url.txt + support_url.txt | https://chroniccare.app/privacy / /support | 占位符 (域名 ICP 未办, R110 起跨期外部依赖) |
| fastlane/metadata/{ios,android}/description.txt | https://findahelpline.com (国际热线) | 真实第三方, 已隐藏产品内 (仅 metadata 文案) |
| lib/core/data/services/sms_service.dart:109,112,191 | dysmsapi.aliyuncs.com (注释 + 代码内 endpoint) | 未隐藏 (endpoint 非秘密, 可接受); 无 AccessKey 泄漏 (grep 0 命中) |
| lib/domain/logic/chinese_holidays.dart:17 | holidayapi.com (注释说明为何不接网络) | 未隐藏 (注释, 无实际调用) |

无硬编码 key / token / 邮箱密码。收件邮箱 (4 个) 未见硬编码 (待底层逐行 agent 复核 .env 引用)。

## 4. 四类问题 (用户点名)

### 4.1 上架相关
不在本视角范围 (04/05 subagent 负责)。架构层面相关项: AR-16 守门盲区 + R112-ARCH-02 传递依赖盲区 — 两者都是"gate 以为干净但实际有传递依赖", 若 pub workspace 化会直接爆循环。

### 4.2 架构相关 (深写)

**当前架构形态实测**: `presentation → domain ← data` + `core/{data,shared,theme,routing,l10n}` umbrella + `l10n/` (presentation 生成层)。实测量: domain 86 文件 9,987L / core/data 97 文件 11,615L / presentation 199 文件 34,939L / l10n 生成 3 文件 20,065L。全项目 421+ dart ≈ 81K 行 (git ls-files 口径)。

**分项健康度**:

| 维度 | 分数 | 实测证据 |
|---|---|---|
| 纯度 (check_all) | 9/10 | 0 violation, 但有 2 个守门盲区 (data→l10n / data→core/routing 传递依赖, AR-16 + R112-ARCH-02) |
| 一致性 (entity↔table) | 10/10 | 1:1 无漂移 |
| 跨 feature 隔离 | 10/10 | check_cross_feature 138 文件 0 violation; vent 仅路由引用 |
| 仓库层 17:17 | 10/10 | impl ≤182L 薄 mapper |
| usecase 层 | 3/10 | 6 文件 739L, 2 个死代码 (24%), 编排仍在 data services |
| god class | 4/10 | 21 个 ≥400L, 拆解 1/21, 多数反涨 |
| l10n 循环 | 2/10 | AR-16 4 文件原样 + 守门盲区 |
| scale 翻译内聚 | 2/10 | 4 源并存 + 810L 死代码 (R112 恶化) |
| 路由架构 | 8/10 | 35 route 拆 7 feature 文件, 只 1 个重复路由 (R112-ARCH-04) |
| feature-first 前置 | 1/10 | 0 进展 |

**核心判断 — "是否可采用更优架构"**:
1. **当前 4 层 + core umbrella 对这个规模 (81K 行 / 单 repo / 6-9 subagent 团队) 是够用的**。证据: 纯度守门 3 轮全绿、跨 feature 0 violation、repo 17:17、覆盖率 domain 72.6% / data 46.5% / presentation 53.8% (check_coverage 18 项全 PASS)。最大的架构痛感不在"分层错了", 而在"层内职责没落位" (编排散在 services/providers、死代码没删、god class 没拆)。
2. **feature-first (lib/features/) 是纯 move, 收益是物理内聚, 成本 2-3 周 + 全部 import 重写 + test 路径重排, 风险是打断 3 轮审计建立的守门员锚点**。当前 check_cross_feature 已经用 import 规则强制了逻辑上的 feature 边界, 物理重组的边际收益 < 成本, **不推荐现在做**。
3. **pub workspace 3 package 是更重的选项, 收益 (编译期强制 + 独立发布) 对"零云端本地 App"没有实际买家** — 没有第二个 App 复用 pkg_domain。且 AR-16 不修必死锁。**排在 v1.0+ (HealthKit/鸿蒙需要平台拆分时) 再评估**。
4. **更轻的重构 (ROI 最高)**: 见 4.3 路线第 1-2 步 — 删 1,600L 死代码 + 接线/删除 2 个死 usecase, 都是 ≤3d 的纯收益, 不动结构。

**依赖注入与 provider 组织实测**: Riverpod 3.3.2 用法健康 — 7 repo provider 暴露 domain 接口 (不暴露 impl, 符合 AGENTS 约定); routerProvider 用 ref.read + cache 避免 GoRouter 重建 (app_router.dart:37-59, R57 性能修复, 模式正确); usecase provider 全部 `Provider<XUseCase>` 薄包装 (fire_care_strategy_providers 38L 样板注释齐全)。**唯一病灶是 legal_consent_provider 291L 混入 SharedPreferences 持久化** (R112-ARCH-01)。Riverpod 3.x 的 `value`/`mounted` 坑未见新用法违规。

**路由架构实测**: app_router 95L (R59 拆后纯 provider 入口) + app_routes 178L facade (3 transition helper + errorBuilder) + 7 个 app_route_*.dart feature 文件 (main 含 ShellRoute 包 / + settings + medication 4 子路由进 shell, R110 已把 /medication 移入 ShellRoute)。35 条 route, 0 死路由 (FS-14 /contacts/new 实读确认已改), 1 个重复 (R112-ARCH-04)。ShellRoute 覆盖合理: 顶层全屏 (/setup /crisis-hotline) 在外, 主导航 + 用药 4 路由在内, 其余子页在外 (slide-right)。

**R112 进行中代码架构质量抽评**: (a) scale_name_l10n + mood_label — 方向对 (单一 dispatch helper), 但漏迁 assessment_center_card 私有 switch 导致 4 源 (AR-17); (b) user_name_helper core/shared→domain/logic — 正确分层 (git status 显示 D + untracked 新址, 方向合规); (c) safety_watch_service 删 2 个 service 依赖 (sms/notification 改为全走 dispatch usecase, git diff 实读) — 好重构; (d) export v5 — 字段落码完整但 pipeline 文件膨胀到 530L; (e) check_review_information_todo.py 新守门员已挂 22 个清单 (实测 22 = 21 .py + 1 .dart, 与 AGENTS 一致)。

### 4.3 重构建议 (深写, 风险调整价值排序)

**路线 (每步独立可提交, 按 ROI 排序)**:

1. **AR-17 scale 翻译合一 (2-3d, ROI 最高, 建议 R112 本批就做)**: 删 810L l10n impl 死代码 → assessment_center_card 私有 switch 迁到 scaleNameL10n → 量表名 source of truth = domain static (中文 fallback) + presentation scaleNameL10n (name/shortDesc) 2 源。净删 ~1,600L, 同时清掉 R90 186 个空 stub。风险: 4 个 lock-in test 需同步改 (scale_translations_round78/65 / scale_strings_arb_lock_in_round95 / phq9_detect_crisis_round60 里 AppLocalizationsScaleTranslations 引用)。
2. **AR-18 usecase 接线 (半天) + 编排收编 (1-2wk)**: 先半天把 CheckSafetyUseCase / ScheduleRefillReminderUseCase 接进 safety_watch_service / refill_notifier (死代码变活); 再抽 `CompleteSetupUseCase` (覆盖 AR-19 saveSetup, 需要 repo 加 transaction 回调) + `ConsentPreferenceStore` (R112-ARCH-01)。完成后 usecase 6→8, safety_watch_service 395→~200, legal_consent_provider 291→~100。
3. **AR-16 守门先红后修 (1wk)**: check_all data forbidden 加 l10n + core/routing → 4 个 PDF/template service 改 caller 注入字符串 → 修完 pub workspace 前置解锁。
4. **AR-20 god class 接力 (1-2mo, 分 4 批)**: 批1 export_import_pipeline 拆 4 子函数 (1d); 批2 setup_page_state + add_medication (已有 test 兜底); 批3 vent 簇 1,732L (compose/detail/list/audio_lifecycle); 批4 legal_page / reminders_hub / notification_status_card。每批遵循"先补 test 再拆"。
5. **AR-23 swallowError 分簇 (3-5d)**: audio / notification-safety / export 3 个 scoped sink。
6. **feature-first (R110 目标, 2-3wk)**: 仅当前 5 步完成后做 — 物理 move pages/domain/data 到 lib/features/{feature}/, 守门员脚本同步改路径锚点。
7. **pub workspace (v1.0+ 2027-Q1, 1mo)**: HealthKit/鸿蒙平台拆分需要时再上; 前置 AR-16 + feature-first。

**每步的验证锚点**: 全部跑 `dart scripts/check_all.dart` + `python scripts/check_usecase_layer.py` + `python scripts/check_cross_feature.py` + `flutter test`, 且步骤 3 后 check_all 的 data 规则变严 = 永不再犯。

### 4.4 半成品 / TODO / 残缺功能
- 810L scale l10n impl 是最大"半成品" (Task 2 stub 返 '' 后 Task 6 补 ARB 从未启动, 3 轮审计仍挂) — 归入 AR-17 一起处理。
- usecase 层 "6→14-16" 计划 (AGENTS R109 目标) 未达且方向要修正: 现有 6 个里 2 个没接线, 先接线再谈扩容。
- export_import_pipeline "拆 4 子任务" 注释计划 (R77 写) 5 轮未执行 — 归入 AR-20 批1。

## 5. 总结 + 给整合者的建议

架构的健康在边界层 (纯度 0 violation / 一致性 1:1 / 跨 feature 0 / repo 17:17 / 覆盖率全绿), 债在结构层 (AR-16/17/18/19 四大件跨 3 轮审计全部原样)。R112 的增量贡献是 3 个小进步 (safety_watch_service 依赖收窄 / usecase 守门唯一 warning 闭环 / user_name_helper 分层归位), 但新增 1 个回归 (scale 名 4 源)。**给整合者的 3 条建议**: (1) 把 AR-17 (删 1,600L 死代码 + 迁 assessment_center_card switch) 列为 R112 hotfix 收尾项, 这是唯一"2-3d 净删代码"的 P0; (2) AR-16 的正确打开方式是先让 check_all 变严 (data 禁 l10n/routing), 否则 4 文件永远"没 gate 管"; (3) 用 case 层目标从"6→14-16"修正为"先接线 2 个死 usecase 再谈扩容" — 死代码 usecase 比没有 usecase 更误导人。

## 附录: 详细证据

### A. god class 全表 (≥400L, 排除 3 个生成 ARB, git ls-files 口径, 2026-08-13 实测)

| # | 文件 | 行数 | 职责数 (估) | R111→R112 趋势 | 拆分难度 |
|---|---|---|---|---|---|
| 1 | presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart | 810 | 1 (但死代码) | 平 | S (直接删) |
| 2 | domain/entities/scale_translations/static_scale_translations.dart | 781 | 1 (纯数据表) | 659→781 反涨 | M |
| 3 | presentation/pages/mood/widgets/mood_audio_recorder_widget.dart | 589 | 3 (recorder UI + player + permission) | 529→589 反涨 | L |
| 4 | presentation/pages/medication/add_medication_page.dart | 571 | 3 (form + validation + submit) | 506→571 反涨 | L |
| 5 | presentation/pages/mood_list/mood_trend_page.dart | 559 | 3 (tab + chart + range picker) | 517→559 反涨 | M |
| 6 | core/data/services/export/export_import_pipeline.dart | 530 | 1 (但 530L 单顶层函数 + 4 子任务) | →530 新入口 | M |
| 7 | core/data/database/app_database.dart | 520 | 3 (DAO facade + saveSetup + clearAll) | 494→520 反涨 | L |
| 8 | core/theme/app_colors.dart | 502 | 1 (纯色值) | 平 | S |
| 9 | presentation/pages/setup/setup_page_state.dart | 496 | 3 (4 步导航 + consent 编排 + 提交) | 平 | L |
| 10 | presentation/pages/settings/legal_page.dart | 496 | 2 (load/toggle + 6 tile widgets 同文件) | 460→496 反涨 | M |
| 11 | presentation/pages/settings/reminders_hub_page.dart | 487 | 3 | 441→487 反涨 | M |
| 12 | presentation/pages/home/home_page_state.dart | 468 | 2 (R108 拆过, 剩 lifecycle + check-in 编排) | 平 | M |
| 13 | presentation/pages/settings/widgets/notification_status_card.dart | 460 | 2 | 平 | M |
| 14 | presentation/pages/vent/vent_compose_page.dart | 445 | 3 (text + audio + submit) | 平 | L |
| 15 | core/data/services/notification_service.dart | 445 | 2 (facade init + 12 委派) | 417→445 反涨 | M |
| 16 | presentation/pages/vent/vent_detail_page.dart | 442 | 3 (detail + player + edit) | 平 | M |
| 17 | presentation/widgets/audio_lifecycle.dart | 439 | 2 | 平 | M |
| 18 | presentation/pages/assessment/assessment_widgets.dart | 429 | 4 (question card + options + result + hotline) | 平 | M |
| 19 | presentation/pages/medication/widgets/edit_medication_dialog.dart | 416 | 2 | 平 | M |
| 20 | presentation/pages/vent/vent_list_page.dart | 406 | 2 | 平 | M |
| 21 | presentation/pages/medication/refill_manage_page.dart | 403 | 2 | 平 | M |

(注: 已拆成: medication_page 553→349, R110 完成, 唯一成功案例。day_detail.dart 395L 在阈值下未计入。)

### B. 关键 grep 证据
- `check_all.dart:38-43`: `_purityRules` — `'data': ['package:chroniccare/presentation/']` (无 l10n/routing 项) → 守门盲区实锤
- `check_all.dart:24-32`: `'shared'` 规则无 `package:chroniccare/l10n/` (domain 有, R77 加) → data/shared 都放行 l10n import
- `safety_watch_service.dart:175`: `final decision = SafetyDetector.detect(` → 绕过 CheckSafetyUseCase 实锤
- `notification_service.dart:50`: `import 'package:chroniccare/core/routing/notification_navigation.dart';` → data→routing 传递依赖实锤
- `check_usecase_layer.py` 输出: `✅ 6 usecase 文件全合规` (R111 的 1 warning 已闭环)
- `dart scripts/check_all.dart` 输出: `✅ 通过` 双项
- `python scripts/check_cross_feature.py`: `[OK] 138 files checked, 0 violations`
- `python scripts/check_coverage.py`: `[PASS] All thresholds met (18 gatekeeper)` — domain 72.6% / data 46.5% / presentation 53.8%
- `check_review_information_todo.py`: warn-only 3 个 review_information 占位 (外部依赖, 归 04 subagent)
- usecase 死代码: `grep -rln "CheckSafetyUseCase" lib/ test/` = 仅自身 + 自身 test; 同款 `ScheduleRefillReminderUseCase` = 自身 + refill_scheduler 注释 + 自身 test
- 死 l10n impl: `grep -rln "AppLocalizationsScaleTranslations" lib/` = 仅自身文件 + 注释; 运行时构造仅 test/ (round78/65/95 lock-in)

<!-- subagent: top-level-arch 完成时间: 2026-08-13 -->
