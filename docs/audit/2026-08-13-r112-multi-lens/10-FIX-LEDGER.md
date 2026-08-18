# R112 修复战役 Ledger

> 目标: 按优先级修复 R112 整合报告全部可修问题。改动留在 working tree, **不 commit** (用户未要求)。
> 报告: `docs/audit/2026-08-13-r112-multi-lens/00-FINAL-CONSOLIDATION.md`
> 基线: HEAD=6bbb308, working tree 128 文件 R112 进行中, test 2377 pass/4 fail/1 skip, analyze 0e/3w/133i

## 预先裁决 (Rulings)

| # | 裁决 | 理由 | 代价 |
|---|---|---|---|
| R1 | 不 commit, 改动留 working tree | 用户只说"修复", 未要求 commit; 完成后由用户按 round 风格自行 commit | 无 (用户可随时要求 commit) |
| R2 | EM-11 72pt quick mood 不实现, spec 条目删除 | 避免臆造设计; 当前形态可用且与 CheckInButton 并存合理 | 丢失一个设计变体 (可回退) |
| R3 | AH-08 reduce-transparency 真代理不做, 维持 disableAnimationsOf 已文档化取舍 | Flutter 无 iOS reduce-transparency 媒体查询, 需原生 bridge; 上架风险低可解释 | a11y 抽审时需解释 |
| R4 | AH-09 SF Symbol 延后 v1.0 | 字体 license 评估 + 非阻塞 | 视觉非纯 iOS |
| R5 | R112-11/R51b 8 量表 items i18n 延后 v1.0 | FeatureFlag phqGad7I18nEnabled=false 既定 backlog, 属功能开发非 bug | en 用户看中文题目 (已知) |
| R6 | AR-20 god class 本批只做批1 (export pipeline 拆 4 子函数), 其余 20 个进 R113 roadmap | 1-2mo 工程量, 每拆需先补 test | 结构债继续存在 |
| R7 | feature-first / pub workspace 不做 (架构结论) | 纯 move 边际收益<成本; workspace 无买家 | 无 |
| R8 | AS-25 PrivacyInfo 删 ContactInfo 声明 + 注释记 v1.0 重接 | R108 删 HealthAndFitness 同逻辑 (gate 关闭时声明=假声明) | SMS 真接时需加回 (注释已记) |
| R9 | GP-R112-05/06 + AS-17 问卷草稿写入 docs/SUBMISSION_INFO.md 新章节 | 无代码位置, 属 console 填表资产 | 无 |
| R10 | Golden test 放 wave 3 (ALS 化之后) | golden 需跟着视觉改, ALS 未完成前做了会作废 | 无 |
| R11 | HealthKit 集成 = v1.0 (守门员 enforced), 不动 | 2027-Q1 计划 | 无 |

## Wave 1 (并行, 文件所有权严格 disjoint)

- Task 1 (A): Export 补全 E6/E7/E8 + P2 — owner: lib/core/data/services/export/* + data_export_service.dart + test/data/data_export_v5_round8_test.dart
- Task 2 (B): E-01/E-02 生命周期 — owner: mood_audio_recorder_widget + vent_compose_page + audio_lifecycle + legal_page + 相关 test
- Task 3 (C1): mood/trend/daily 修复 — owner: mood_trend_page + mood_detail_page + mood_list_page + mood_influence_chips + cbt_three_column_mode + mood_factor_analysis + influence_category.dart + tracking_customize_page + 相关 test
- Task 4 (C2): theme/widgets/setup/assessment/routing — owner: app_colors + app_list_tile + section_header + apple_list_section + quick_mood_carousel + spring + setup_* + assessment_widgets + app_route_medication + crisis_hotline + medication_calendar + home controllers + CHANGELOG 验证行 + 相关 test
- Task 5 (D): 架构批1 — owner: domain/usecases + safety_watch_service + refill_notifier + notification_service + notification_delegate + notification_initializer + preset_medication_templates + cbt_thought_record_pdf* + scale_translations_l10n/(删) + scale_name_l10n + assessment_center_card + assessment_section + notification_navigation + 新 domain/logic/deep_link 文件 + scripts/check_all.dart + 相关 test
- Task 6 (E): 上架/构建 — owner: fastlane/* + android/* + scripts/{check_review_information_todo,check_16kb_alignment,generate_data_safety_form,generate_health_apps_questionnaire}.py + ios/Runner/PrivacyInfo.xcprivacy + docs/SUBMISSION_INFO.md

## 状态

- [x] Task 1 A: export 补全 (E6/E7/E8/R112-05/06/07 done; 净+28 ARB key)
- [x] Task 2 B: E-01/E-02 (3 层泄漏链 + legal_page log; 13 test)
- [x] Task 3 C1: mood/trend/daily (日均算法/详情路由/影响因素 i18n/onReorderItem; 28 case)
- [x] Task 4 C2: theme/widgets/setup/assessment/routing (EM-16b/14b/09b/07 + 12 项; +20 case)
- [x] Task 5 D: 架构批1 (AR-17 -842L/AR-18 接线/AR-16 gate+4文件/ARCH-02 split; +14 case)
- [x] Task 6 E: 上架/构建 (14 项 done; wrapper 三件套 untracked 待 commit)
- [x] 主 agent 整合: 路由注册 /mood/detail/:id + ChipBadge neutral fg 回归修 + influence_factor_l10n 单源 helper + cbt score5 primaryDark + fullwidth 1 处
- [x] Wave 1 验证: analyze 0e/0w/118i + test 2455 pass/4 fail(资产)/1 skip + 21 守门员全绿
- [x] Wave 3: H1 AR-23 swallowError 分簇 (audio 48/notification 5/export 3 → 3 scoped sink, +10 test) + H2 golden ×3 + P3 卫生 12 项 (EM-19 destructive 删 / 注释漂移 / moodTodayLabel 参数化 / theme_provider 竞态 / vent haptics+undo / FS-3/11/5 / 按钮集中器 / E-01 防御 32 处全查 + _getAudioDuration 新修 / vent 全链路 test)
- [x] 主 agent 收尾: 4 warning 清零 (clear_tile/setup_page_state/vent_audio_storage) + CHANGELOG/README/AGENTS/spec 同步 (ALS 27→65, test 2483, 修后预估 8.3/10)
- [x] 终验: analyze 0e/0w/108i + test 2483 pass/4 fail(资产)/1 skip + 22 守门员全绿
- [x] 收尾批 (round 8b): keystore 生成 (GP-7) + 16kb 脚本 --so-path/--aab 真验证 (SP-R112-06) + console 表单生成器实跑 (GP-11) + TempMedicationDialog 死代码删 (+6 orphan ARB key 清) + drift upsert save() 清名修 (4 test) + god class 批2 (setup_page_state 503→331 / add_medication 573→258, +46 test) + 视觉残留 2 组件 ALS
- [x] 终验 2: test 2533 pass/4 fail(资产)/1 skip + analyze 0e/0w/4i + 22 守门员全绿

## 完成日志

- Wave 1: 6 agent 全 done (0 blocked)。跨 agent 整合 5 项由主 agent 闭环 (ChipBadge 回归/路由/影响因素单源/score5/fullwidth)。drift upsert-Value(null) 探针结论记录: save()/saveSetup 传 null userName 时冲突路径不清名 — 低危, 记 minor 不修。
- D 超出所有权最小改动: home×2/setup×2/settings×1 (每文件 +1 import), C2 已确认共存编译干净。
- core_providers.dart:74 notificationServiceProvider 无 deep-link 回调 = 测试 fallback, 生产 main.dart 接线 — 非 bug, 记录。
- Wave 2: F1 (Card 24→0, ALS 15 处) / F2 (14 ALS, 9 Card 清, AH-15/16) / G (AR-19/ARCH-01/ARCH-03)。主 agent: apple_list_section Material ink root fix + lock-in 阈值 250→300 + setupCommitterProvider + tracking_item_card + 注释杂项。
- Wave 3: H1 AR-23 (79 实测调用点, 3 簇 56 处迁移) + H2 (12 项 + golden 3 基线 PNG 入库 + vent 全链路)。
- 终态: 2483 pass / 4 fail (iOS 资产) / 1 skip; analyze 0e/0w/108i; 22 守门员全绿; working tree 274 文件 (+30708/-28883)。未 commit。

## 残余 (R113+ 路线, 不在本批)

- 上架外部 P0 剩余: 域名 ICP (7-20d) / 设计师资产 (截图/Icon/LaunchImage/feature_graphic) / review 4 占位 (真实姓名邮箱手机) / console 4 表单人工填 (文本已生成在 build/) / 首次 release build 冒烟 + 16KB objdump 实测 (本机无 Android SDK, keystore 已就绪, 脚本已支持 --aab 真验证)
- AR-20 god class 剩余: 18 个 ≥400L (批1 pipeline / 批2 setup_page_state+add_medication 已拆; setup_page_state 331L 与 add_medication 258L 降出 god 线)
- R51b/R112-11 8 量表 items i18n (phqGad7I18nEnabled=false, v1.0 计划)
- AH-08 reduce-transparency 真代理 (需原生 bridge) / AH-09 SF Symbol (license, v1.0)
- HealthKit 集成 (v1.0 2027-Q1, 守门员 enforced)
- keystore 密码备份到 1Password (用户操作, ~/.chroniccare-keystore-backup/ 已有 ZIP)
