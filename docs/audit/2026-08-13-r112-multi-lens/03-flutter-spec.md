# flutter-spec 视角审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: Flutter SDK 规范 / 最佳实践合规 (flutter-specification)
- 审视者: subagent 03
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M 13??
- 范围: 实读 `docs/design/2026-08-10-apple-health-redesign/spec.md` 全文建立 checklist → 验证 5 token 文件 (`lib/core/theme/` 7 文件全读) + 6 widget 集中器 + PageScaffold + Spring → grep 全量覆盖 `lib/presentation/pages/` 13 feature 目录 ALS 使用率 → `lib/core/routing/` 9 文件全路由比对 push 调用点 → R112 新代码实读 (export v5 3 文件 1033 行 / scale_name_l10n.dart / mood_label.dart / user_name_helper.dart / safety_alert_* diff / 量表 diff) → R112 新测试实读 (data_export_v5_round8 250 行 / static_scale_translations_round8 / scale_name_l10n_round8) + 实跑 52 个新 test 全过 → `flutter analyze` 实跑 (0 error / 3 warning / 133 info) + `check_all.dart` + `check_cross_feature` + `check_widget_dispose` 实跑全绿。旧报告 R111 03-flutter-specification.md 只当待验证清单, 逐项实读代码复核。

## 1. 整体评分 (0-10)

**8.5/10** — R111 flutter-spec 遗留项本批闭环率极高 (FS-4/7/14/16/19 + EM-14/EM-16/EM-21 + E1/E2/E3 全部实锤), export v5 代码质量与 TDD 是 R112 最大亮点; 扣分在 3 处 warning 仍违反 0-warning 门禁、spec §8.2 golden test 承诺 0 落地、mood/vent/assessment 3 feature 的 ALS 化 (spec §5.5-5.7) 仍 0 进度。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0 (必修, 阻塞上架/严重 bug)

无。export v5 双向 round-trip 7 test 实跑全过, E1/E2/E3 数据丢失级 bug 已闭环。

### P1 (应修, 影响品质)

- [底层] **[P1-001] spec §5.5-5.7 三 feature ALS 化仍 0 进度** — 修复难度:M — 工作量:3-6d
  - 位置: `lib/presentation/pages/mood/`、`lib/presentation/pages/vent/`、`lib/presentation/pages/assessment/` (grep AppleListSection = 0 文件, 与 R111 AH-04 一致, R112 未动)
  - 现状: spec 明确列为"中等改"的 3 个 feature (mood 5 档圆形按钮 spring 选中 / vent FAB systemPurple + pill 录音按钮 / assessment 历史 ALS), 与 home(5 文件)/setup(4)/medication(9)/trend(1) 形成鲜明反差。note: contact/settings/daily_tracking/check_in 属 spec §5.8"自动适配"类不算债。
  - 建议: 按 spec §5.5-5.7 逐 feature 1-2d 一个做, 优先 mood (高频路径)。

### P2 (可修, 优化)

- [底层] **[P2-001] 3 处 warning 违反"0 warning"门禁 (R111 FS-16 收尾残留 2 处)** — 修复难度:S — 工作量:15min
  - 位置: `lib/presentation/pages/crisis_hotline_page.dart:30` (unused_import app_motion) / `lib/presentation/pages/medication/medication_calendar_page.dart:27` (unused_import app_motion) / `test/presentation/pages/medication/medication_backfill_round8_test.dart:12` (unused_import)
  - 现状: R111 报 11 处 lib/ warning, R112 修了 9 处 (safety_watch_service/safety_alert_sender_impl 死字段删除实锤), 剩 2 处 lib + 1 处 test 未清。AGENTS 硬约束"任何 PR 必保 0 error / 0 warning"。
  - 建议: 删 3 个 import 即绿。

- [底层] **[P2-002] `onReorder` deprecated API 使用 (deprecated after 3.41.0)** — 修复难度:S — 工作量:1h
  - 位置: `lib/presentation/pages/daily_tracking/tracking_customize_page.dart:33`
  - 现状: 项目跑 Flutter 3.41.9, `ReorderableListView.builder(onReorder:)` 已被官方标记 deprecated (推荐 `onReorderItem`), analyze 报 `deprecated_member_use` info。当前功能正常但下个 SDK 升级前必清。
  - 建议: 换 `onReorderItem` (语义: newIndex 已自动校正 oldIndex 移除偏移, 现手写的 `if (newIndex > oldIndex) newIndex--` 逻辑要删)。

- [底层] **[P2-003] spec §8.2 golden test 承诺 0 落地** — 修复难度:M — 工作量:2-3d
  - 位置: 全 repo `matchesGoldenFile` = 0 处 (grep test/ 0 匹配); spec §8.2 "每个新 widget 必须有 1 个 golden test (检查关键视觉属性: 圆角/字号/颜色)"
  - 现状: 6 个 widget 集中器 + 5 token 集中器的视觉回归全部靠"property assertion" (find.byIcon + color 对照, 见 apple_health_tile_round7b_test) 替代 golden。防回归力弱于 golden (如 letterSpacing/lineHeight/opacity 不可断言)。
  - 建议: 至少给 PrimaryButton / StatCard / AppleListSection 3 个核心 widget 补 golden (有 ink_sparkle shader 资产前例, 环境已支持)。

- [底层] **[P2-004] scale_name_l10n.dart 与 assessment_center_card 私有 switch 双 dispatch 源** — 修复难度:S — 工作量:1h
  - 位置: `lib/presentation/services/scale_name_l10n.dart:15-40` (新公共 helper) vs `lib/presentation/pages/assessment/widgets/assessment_center_card.dart:37-86` (旧私有 `_l10nName`/`_l10nShortDesc` 仍在用)
  - 现状: R112 注释声称"抽成公共 helper 让 3 处共享", 但第 4 处 (assessment_center_card) 的私有 switch 没删 → 加第 11 个量表要改 2 处, 漂移风险。默认分支语义也不同 (公共 helper `_ => id` vs 私有 `_ => scale.displayName`)。
  - 建议: assessment_center_card 改调公共 helper, 删私有 switch (或反过来, 只留一处)。

- [底层] **[P2-005] test 直接 import audioplayers_platform_interface (非 pubspec 直依赖)** — 修复难度:S — 工作量:0.5h
  - 位置: `test/presentation/pages/vent/vent_detail_page_round7b_test.dart:16-20` (`depend_on_referenced_packages` ×3, R111 SP-111-03 跨期残留 0 闭环)
  - 现状: 直接 import 三方包内部 src, 包升级/去 transitive 即断。
  - 建议: 改走 audioplayers 公开 API mock, 或 pubspec dev_dependencies 显式声明。

### P3 (建议, 长期)

- [底层] **[P3-001] 4 处 use_build_context_synchronously info (isMounted 闭包 guard, analyzer 穿透不了)** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/presentation/pages/home/controllers/home_deep_link_handler.dart:198,207,208` + `home_care_engine_dispatcher.dart:74`
  - 现状: 实际安全性 OK (每处 async gap 后都有 `isMounted()` 闭包判定, 与 AGENTS 文档化的 27 处 `!mounted` 模式一致), 但 analyzer 无法识别闭包 guard → 4 处 info 常驻。R111 已报, R112 未动。
  - 建议: 在 async gap 前把 `context`/`l10n` 提到 await 前取 (如 line 65 的 l10n 已提前取), 或挂 `// ignore` + 说明。

- [底层] **[P3-002] `Spring.of(context, ...)` 工厂 0 caller (仅 _EntrySpring 直用 Spring.standard)** — 修复难度:S — 工作量:2h
  - 位置: `lib/core/theme/spring.dart:133-144` (唯一真实 caller: `check_in_button.dart:245`)
  - 现状: spec §3.4.3 双轨制落地但只有 1 个消费点; §3.4.6 的 `Spring.of` 工厂 (含 context 未来扩展设计) 0 调用。push 转场仍走 CustomTransitionPage curve。
  - 建议: 路由 push 转场或 QuickMoodCarousel 选中放大 (§5.5 场景) 接第 2 个 Spring caller, 兑现"手势/状态切换用 spring"原则。

- [底层] **[P3-003] tracking_item_config iconCodePoint 硬编码 codepoint 脆弱** — 修复难度:S — 工作量:1d
  - 位置: `lib/domain/entities/tracking_item_config.dart:90-155` (R112 批量改 7 个 codepoint, 如 0xe3a2→0xf1e5)
  - 现状: domain 0-flutter 约束下的既有 workaround, 但 codepoint 随 Material Icons 字体版本漂移, 本次已实际发生一次全量漂移修正。有 helpers_round108_test 锁当前值。
  - 建议: 长期考虑 codepoint → semantic name 映射表放 presentation 层。

- [底层] **[P3-004] R111 跨期残留小项 3 处 (确认未修)** — 修复难度:S — 工作量:2h
  - 位置: temp_medication_dialog.dart:49 (`ref.read(...).value ?? []` 冷启动闪空, FS-3) / home_fab_toolbar.dart:46 (SingleTickerProviderStateMixin 无 ticker, FS-11) / check_in_button.dart:86 (`child: _EntrySpring(` 多余缩进 2 空格, dart format 未跑)
  - 现状: 均 P3 级, 运行正确性无影响。
  - 建议: 跟 P2-001 一起 1 个 commit 清掉。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)

flutter-spec 视角范围内无外链硬编码; 上架元数据外链由 04-appstore subagent 负责。抽查 `lib/presentation/` 无 http/https URL 字面量。

## 4. 四类问题 (用户点名)

### 4.1 上架相关
- 0 假声明 (check_apple_health_claim 守门员 R31 起全绿, 本批未动相关代码)
- 锁屏 PII: R112 删除 SafetyAlertBuilder 死 userName 参数是 R32 锁屏决策的收尾 (title 静态不含名), 无新增 PII 面

### 4.2 架构相关
- **export v5 分层合规 (P0 验证通过)**: `export_import_pipeline.dart` 530L 仍在 data 层, 只 import data/l10n 层, 0 flutter 0 presentation; 校验 helper 全 public static 纯函数; medicationId old→new 重映射逻辑清晰 (export_orchestrator:156-176 + pipeline:177-251)
- **user_name_helper 迁移合规**: `core/shared/` → `domain/logic/` 后 check_all.dart 一致性门禁恢复全绿 (shared/ 文件至少 2 层使用规则), domain 层 0 flutter import 保持
- **presentation/services/ 新目录**: scale_name_l10n.dart / legal_version.dart 无 StatefulWidget 无 provider, 纯函数派发 — 分层合理; 但 static_scale_translations_l10n.dart 810L 是 presentation 层最大 god class (跨期 AR-17, 2-3d 三源合一待做)
- **provider 暴露规范**: core_providers.dart 12 个 `Provider<XRepository>` 全暴露 domain 接口 (实读确认), routerProvider 用 ref.read + cache 不重建 GoRouter (app_router.dart:37-47 注释实测一致)

### 4.3 重构建议
1. (P2-004) 量表名 l10n 派发单源化 — assessment_center_card 私有 switch 删掉改调公共 helper
2. (P3-002) Spring 消费点扩到 2-3 个 (push 转场 / mood carousel 选中)
3. (跨期) static_scale_translations_l10n 810L + assessment_center_card 双 dispatch → 建议 R109 里跟 scale_translations 三源合一一起做

### 4.4 半成品 / TODO / 残缺功能
- spec §5.5-5.7: mood / vent / assessment 3 feature ALS 化 0 进度 (P1-001), 其余 4 个 §5.8 自动适配类按 spec 不需要
- spec §8.2 golden test: 0 落地 (P2-003)
- Spring.of 工厂: 空转 (P3-002)

## 5. 总结 + 给整合者的建议

**R112 从 flutter-spec 视角是高质量收尾批**: R111 报告的 12 项遗留中 8 项实锤闭环 (FS-4/7/14/16/19 + EM-14/EM-16/EM-21 修复 + E1/E2/E3), 每项都有对应回归 test; 新代码 export v5 (7 test RED→GREEN)、mood_label (EM-21)、scale_name_l10n (4 test 含 en 无中文锁) 全部 TDD 且通过; 52 个 R112 新 test 实跑全过; check_all / cross_feature / widget_dispose 门禁实跑全绿; 无新 P0。

**整合建议 (按性价比排序)**:
1. P2-001 (15min): 删 3 个 unused import, 恢复 0-warning
2. P2-004 (1h): 量表名 dispatch 单源化 (R112 新代码自身一致性收尾)
3. P2-002 (1h): onReorder → onReorderItem (升级前必清)
4. P1-001 (3-6d): mood/vent/assessment ALS 化 — 建议 R113 视觉专项, 与 emil/apple-health 视角合并排期
5. P2-003 golden (2-3d): 长期防视觉回归, 可后置到 ALS 化完成后再补 (golden 要跟着视觉改)
6. P3 项打包 1 个 cleanup commit

**评分 8.5/10** (R111 flutter-spec 97% 基础上: 修 8 留 4, 新增 3 项小发现, 无 P0; 扣分主因 = spec §5.5-5.7 视觉债跨期 3 个月仍 0 进度 + 0-warning 门禁未恢复)。

## 附录: 详细证据 (grep 输出、文件引用)

**spec.md 逐节核对表**:
| spec 节 | 要求 | 状态 | 证据 |
|---|---|---|---|
| §3.1.1-3.1.5 app_colors | #F2F2F7 / #34C759 / 8 metric | ✅ 全落地 | app_colors.dart:47-57,427,476 |
| §3.2.1-3.2.4 typography | 17pt body/13pt caption/w200 | ✅ | app_typography.dart (fontSizeCaption=13) |
| §3.3.1-3.3.4 spacing | radiusButton 14 / buttonHeight 50 / pageMarginH 20 | ✅ | app_spacing.dart:111,126-127 |
| §3.4.1-3.4.6 motion+Spring | durNormal 250 / 3 spring / 0 阴影 | ✅ 双轨制 | app_motion.dart:114 + spring.dart:77-99 |
| §4.1-4.8 6 widget 集中器 | PrimaryButton 3 variant / CheckInButton 64 pill / StatCard 4 variant / AppleHealthTile / AppleListSection / SectionHeader ALL CAPS | ✅ 全存在 | lib/presentation/widgets/ (primary_button 211L / check_in_button 307L / stat_card 140L / apple_health_tile 177L / apple_list_section 257L / section_header 161L) |
| §4.9 PageScaffold translucent | blur(20) + 0.6/0.4 alpha + reduce 代理 | ✅ | page_scaffold.dart:86-103 (MediaQuery.disableAnimationsOf 代理, AH-08 P2 已知取舍) |
| §5.1-5.4 5 page 重设 | home/setup/medication/trend | ✅ | ALS grep: home 5 / setup 4 / medication 9 / trend 1 文件 |
| §5.5-5.7 mood/vent/assessment | ALS 化 | ❌ 0 文件 | grep AppleListSection = 0 |
| §5.8 4 feature 自动适配 | token 自动升级 | ✅ (spec 约定无需 ALS) | — |
| §8.2 golden test | 每新 widget 1 golden | ❌ 0 matchesGoldenFile 全 repo | grep test/ = 0 |

**R111 遗留 12 项复核结果**: FS-3 未修 (temp_medication_dialog:49) / FS-4 已修 (shared_providers.dart diff 删 page import) / FS-7 已修 (quick_mood_carousel.dart:93-95 走 AppSnackBar) / FS-8 部分 (medication_page 553→349, 其余 god class 未动) / FS-9 未动 / FS-11 未修 (home_fab_toolbar:46) / FS-13 未动 (app_database 编排债) / FS-14 已修 (contacts_list_widget.dart:42 改 dialog, 全路由比对 0 死路由) / FS-15 已修 (analyze 27→3 warning) / FS-16 剩 2 处 (P2-001) / FS-17 未核 (medication_page:194) / FS-19 已修 (reminders_hub_page header 重写, � = 0) / FS-20 保持。

**R112 新代码实读结论**:
- `export_import_pipeline.dart` 530L: import 侧 3 段新增 (contact consent ×4 / med 5 字段 + medIdMap / mood 5 字段) 校验严 (maxLen/pattern/range), 事务内原子, ImportResult 摘要完整 — 无 P0
- `export_orchestrator.dart` 337L: export 侧对称补字段, `if (x != null)` 条件键避免 null 进 JSON, medication id 导出 — 无 P0
- `scale_name_l10n.dart` / `mood_label.dart`: 纯函数 switch 派发, `_ => id` / `_ => moodLabel3` 兜底不炸, i18n key 3 语齐全 (moodLabel1-5 × zh/en/zh_Hant 实查) — 仅 P2-004 双源问题
- 量表 const 类 displayName→translations getter (E4): 老 caller 0 行为变化, static_scale_translations_round8_test 一致性断言锁住 (越界 '' / 无 stub / override 优先)

**实跑命令记录**:
- `flutter analyze`: 0 error / 3 warning / 133 info (本人实测, 与主 agent baseline 一致)
- `flutter test` (R112 新 4 文件): 52 pass / 0 fail
- `dart scripts/check_all.dart`: 纯度 ✅ + 一致性 ✅
- `python scripts/check_cross_feature.py`: 0 violations; `check_widget_dispose.py`: 0 资源泄漏
- `grep matchesGoldenFile test/`: 0; `grep pumpAndSettle test/`: 87 文件 469 处 (R111 451, 增长 18 处全在新 test, 无 pumpAndSettle 死等回归 — mood_audio_recorder 周期 timer 场景显式 pump() 模式保持)
- `grep use_build_context_synchronously`: 4 处 info (全 isMounted 闭包 guard)

<!-- subagent: flutter-spec 完成时间: 2026-08-13T12:00:00Z -->
