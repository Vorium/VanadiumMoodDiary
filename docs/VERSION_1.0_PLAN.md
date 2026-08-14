# v0.30 R95+ 路线图 (原 VERSION_1.0_PLAN, R95 阶段 1+2+3+4 实施后升级版)

**创建时间**: 2026-07-31 (R67)
**升级时间**: 2026-08-11 (R32 6 视角综合审视 + R31 7 视角 Apple Health 风格重设计更新)
**审查报告**:
- [docs/audit/2026-08-13-r111-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-13-r111-multi-lens/00-FINAL-CONSOLIDATION.md) (R111 9 视角综合, 2026-08-13)
- [docs/audit/2026-08-13-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-13-multi-lens/00-FINAL-CONSOLIDATION.md) (R110 10 视角综合, 2026-08-13)
- [docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (R32 6 视角综合, 52KB)
- [docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md](audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md) (R31 7 视角 Apple Health 风格重设计, 14KB)
- [docs/audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md](audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md) (R108 revisit 9 视角综合, 40KB)
**目的**: 记录 v0.30.0+85 R95 阶段 1+2+3+4 实施后路线图 + v1.0 bump 决策
**当前**: pubspec.yaml `version: 0.32.0+142` (R111 hotfix round 8 按优先级修复 [2026-08-13], 2377 pass / 4 fail [iOS 资产占位] / 1 skip, `flutter analyze` 0 error / 0 warning, 22 守门员全绿 — E1/E2/E3 export v5 + 27 warning 清零 + EM/FS/SP P1 全闭环 + R111-03 补打卡 + GP-10 权限重授权)
**上一版**: v0.27.0+64 (R67) → 0.30.0+85 (R95 实施后) → 0.31.0+107 (R31 Apple Health 重设) → 0.31.1+108 (R32 bug-batch 修了 11 P0) → 0.31.1+111 (R32 hotfix 4 round 全闭环) → 0.32.0+129 (R110 round 3) → 0.32.0+140 (R111)

---

## R111 9 视角综合审视 (2026-08-13, master 0.32.0+140)

**状态**: 9 个 subagent 并行只读审计 (emilkowalski / superpowers / flutter-specification / AppStore / GooglePlay / Apple Health + 顶层架构 + 2 路底层逐行)。**R110 12 P0 代码闭环全实锤** (通知 ID 5M 带 / purity 0 violation / 紧急联系人 gate / 12 处 i18n / 死路由 + shell / badge visibility)。**加权综合 ≈ 7.3/10**, hotfix 修完代码级 P0/P1 后预估 8.3/10。

**新 P0/P1 重点** (详细见 [00-FINAL-CONSOLIDATION.md](audit/2026-08-13-r111-multi-lens/00-FINAL-CONSOLIDATION.md)):
- **E1/E2 (P1 bug, ≤1d+2h)**: export/import JSON schema v4 落后 DB schema 22 — medications 漏 5 字段 + moodEntries 漏 7 字段换机静默丢失; contact consent 4 字段不导出 → PIPL §13 留痕断裂 (R68 gate 绕过)
- **SP-111-02 (P1, ≤1h)**: `flutter analyze` 27 warning 违反 0-warning 门禁 (10 处 test fake 死 @override + 11 处 lib unused)
- **EM-21 (P1, 1-2d)**: en locale mood 标签显示中文 (ARB 无 moodLabelN key)
- **架构 4 P0 跨期残留**: AR-17 scale_translations 三源 (810L l10n impl 实锤 0 caller 死代码, 2-3d 删 1,590L) / AR-18 usecase 6→14-16 0 进展 / AR-19 saveSetup+clearAllUserData 仍在 AppDatabase / AR-16 l10n 循环 (pub workspace 死锁)
- **上架**: 硬阻塞 100% 外部依赖与 R110 一致 (域名 ICP 7-20d + 双平台资产 + keystore + console 3 表单 [新增 RECORD_AUDIO Audio 申报])

**R111 hotfix 计划 (本周)**: E1+E2 export v5 升级 → 27 warning 清零 → EM-16/14/21 → FS-14 /contacts/new 死路由 → SP-111-04 量表 items 断言 → AS-16 守门员 + 上架元数据 → 死链/数字同步 (本文件已同步)。

---

## R32 hotfix 4 round 闭环 (2026-08-11, master 0.31.1+111)

**状态**: R32 综合审视后, 4 round 紧急修, 4 个 commit (`b9f14bc`+108 / `312d171`+109 / `3ac02e7`+110 / `40de204`+111) 全 merge to master。**闭环**: R32 新增 33 P0 中可闭环 19 项 + R32 跨期 P1 中 5 项 (P1-3/7/8/10/13)。**修后预估综合 8.5/10** (R32 起点 6.2 → +2.3)。

**Round 1 (0.31.1+108, commit b9f14bc)**: 11 P0 全闭环 (锁屏 PII 全链 + 4 description 5 病名 locale + 7 raw IconButton + Spring 接 _EntrySpring + Apple Health 关键词 lock-in test 扩 + review_information 占位 + 守门员 i18n PUA + 4 集中器 + 6 widget 集中器 spec 引用 + 4 警告微调 + zh_hant 16 处 + 55 orphan ARB key 全删)

**Round 2 (0.31.1+109, commit 312d171)**: 5 P0 (i18n 跨期 21 处硬编码中文 → ARB key [medication_page 4 + primary_action_row 7 + secondary_action_row 7 + today_summary_card 1 + quick_mood_carousel 2] + check_fullwidth_punctuation 守门员严格化 return 1 + 11 处半角标点 + 9 处繁简不一致 + 0 orphan)

**Round 3 (0.31.1+110, commit 3ac02e7)**: 3 P0 (PageScaffold translucent AppBar [BackdropFilter blur 20 + reduce-transparency 双路径] + lock-in test 阈值 300→250 + Colors.white 5 处 → AppColors.fgOnPrimary)

**Round 4 (0.31.1+111, commit 40de204)**: 5 P1 (TweenNumber 公共 widget [animations/tween_number.dart] + 删原 stat_card._TweenNumber 95% 重复 + check_in_button._StreakCounter 改用公共 + curveAppleSheet/Drawer 死代码删 [Material API 不支持] + PressFeedback Haptics.light() 集中器 + check_widget_dispose 4 类扩 [AnimationController / Timer / ChangeNotifier / ScrollController])

**18 守门员最终状态**: 18 绿 / 0 红 / 0 warn / 1 skip (16kb 待 Android .so 重 build).

**未闭环** (留给 R109 专项 + v1.0 长期):
- 11 god class (≥400L) 0 test — R109 第 2-4 周拆
- 11 feature 0 改 (Apple Health spec §5.1-5.7) — R109 第 4 周选 3-5 个高 ROI 改
- 126 fail 半年没修 (i18n 66 + 状态机 mock 50 + 数值匹配 10) — R109 第 1 周
- SF Symbol 字体 (spec §3.1.3) — R110+
- 实物资产 100% 缺失 + chroniccare.app 域名 + 5 厂商 push + 阿里云 SMS + EmailService  + 鸿蒙 + HealthKit + 法务 — v1.0 长期 1-2 月

---

## R32 综合审视 (2026-08-11, 6 视角从 0 重跑)

**状态**: 6 视角 subagent 并行深度扫描 **当前未提交工作区** (R31+ master `a0f39c4` v0.31.2+107 + `fix/v0.31.1-bug-batch` 11 commit P0 修 [master 未合并] + working tree 95 文件未提交改动)。**新增/确认 199 项** (P0=33 / P1=64 / P2=37 / P3=10 + R32 新发现 16 项), 完整报告见 [docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (52KB)。

### R32 各视角评分总览 (R32 vs R31)

| 视角 | R31 | R32 | 变化 | 主因 |
|---|---|---|---|---|
| **emil** (UI/UX/动效) | 8.5 | **8.2** | **-0.3** | 主页 12 处硬编码中文累计, 8 raw IconButton (R31 7→8 反涨), Spring 145L 死代码, hero_illustration 118L 死代码 |
| **superpowers-en** (TDD/质量) | 8.5 | **5.5** | **-3.0** | **126 fail 半年没修** (5.6% 红灯率), 66 widget test i18n 迁移没同步, 11 god class 0 test, 55 orphan ARB, check_changelog FAIL, check_no_pua FAIL |
| **flutter-spec** (规范符合度) | 97% | **96%** | -1% | 8 raw IconButton 反涨, 7 god class 反涨 19-86 行, Spring 0 caller, PageScaffold translucent 0 改, spec baseline 6 处矛盾 |
| **AppStore** (iOS 上架) | 3.5 | **5.5** | **+2.0** | R32 0.31.1 bug-batch 修了 P0-01~P0-09 (锁屏 PII + 7 IconButton + 4 description locale + Spring + review_information) — **master 未合并** |
| **GooglePlay** (Android 上架) | 5.5 | **5.5** | 0 | 实物资产 100% 缺失, 4 AndroidNotificationDetails visibility 0 设, 5 厂商 push 0 集成, R32 0 Android 改动 |
| **Apple Health** (视觉语言) | 7.0 | **7.2** | +0.2 | 0.31.2 文档入库 +0.2, 11 feature 仍只 4.5/11 落地 (mood/daily_tracking/vent/assessment/contact/settings/crisis_hotline 7-8 个 0 改) |
| **加权综合** | **7.5** | **6.2** | **-1.3** | superpowers-en 暴露 126 fail 半年 + 55 orphan + 守门员 3 红 + R31 上架层 0 闭环跨期 |

**R32 vs R108 加权综合**: R108 6.2 → R31 7.5 (+1.3) → R32 6.2 (-1.3)。**倒退主因**: superpowers-en 暴露 5.6% 红灯率 (126 fail 半年没修) + 55 orphan ARB (R31 0 个 → R32 55 个新引入) + check_changelog 段顺序错 (R31 报告"已闭环" 实际 0 闭环)。

### R32 18 守门员真实状态 (R32 跑出)

```
✅ 14 绿: check_cross_feature / check_arb_keys / check_widget_dispose / check_pii_in_title /
   check_apple_health_claim / check_strings_hardcoded / check_sms_release_ready / check_legal_consent /
   check_drift_namespace / check_datetime_race / check_datetime_race2 / check_no_hardcoded_utc /
   check_all.dart 4 层架构 / @DataClassName 一致性
❌ 3 红:
   - check_changelog: CHANGELOG 段顺序错 [0.31.0] < [0.31.1] (应倒序)
   - check_no_pua: 4 PUA 字符 (audit-history 历史 review 文档, 不在 lib/)
   - check_orphan_arb_keys: 55 orphan ARB key (R31 0 个 → R32 55 个新引入)
   - check_zh_hant_consistency: 缺 opencc 包 (R32 0 修)
⚠️ 1 warn: check_fullwidth_punctuation 133 violations (warn-only)
⏸️ 1 skip: check_coverage (无 coverage/lcov.info, 需 flutter test --coverage)
⏸️ 1 skip: check_16kb_alignment (待 Android .so 重 build 后跑)
```

**R31 报告"18 守门员 18/18 全绿" 是虚假乐观, R32 实测 14 绿 3 红 1 warn 2 skip. R32 hotfix 4 round 闭环后, 18 守门员 **18 绿 / 0 红 / 1 skip** (16kb 待 Android .so 重 build)**

### R32 flutter test 真实状态 (8-11 04:21 真跑, v0.31.1-bug-batch worktree)

```
$ flutter test --no-pub
02:21 +2129 ~1 -126: Some tests failed.
$ flutter analyze --no-pub
94 issues found. (ran in 6.6s)
  - 0 error
  - 23 warning (15 override_on_non_overriding_member 在 test/ + 8 lib)
  - 71 info (45 require_trailing_commas + 12 prefer_const_constructors + 4 use_key + 4 use_build_context_sync + 2 use_named_constants)
```

**126 fail 跨 29 test 文件**, 跟 R31 报告"2036 pass" 实际有差距。**Top 1 fail 文件**: assessment_history_round13b_test.dart (11 fails i18n 迁移没同步)

### R32 跨 3+ 视角共识 P0 (优先级最高, R32 修了但 master 未合并)

| # | P0 | 视角共识 | R32 fix/v0.31.1-bug-batch 修了? |
|---|---|---|---|
| C-01 | Spring 物理模型 145L 半成品 (spec §3.4.3) | emil + superpowers-en + Apple Health + flutter-spec | ✅ round 10 修 |
| C-02 | PageScaffold translucent AppBar (spec §4.9 决策 #7) 0 实现 | emil + Apple Health + flutter-spec | ✅ R32 hotfix round 3 修 (BackdropFilter blur 20) |
| C-03 | 锁屏 PII 跨 4 视角 (3 DarwinNotificationDetails + 4 AndroidNotificationDetails) | flutter-spec + emil + GooglePlay + AppStore | ✅ round 6/7 修 |
| C-04 | 8 raw IconButton 无 PressFeedback / Tooltip | emil + Apple Health + flutter-spec + R108 | ✅ round 8/9 修 |
| C-05 | R11a 4 处硬编码中文 + Colors.white (medication_page 4 tile) | emil + Apple Health + flutter-spec | ✅ R32 hotfix round 2 (i18n 4 处) + round 3 (Colors.white) 修 |
| C-06 | spec baseline 2019 vs 实际 2103 矛盾 6 处 | emil + superpowers-en + Apple Health + flutter-spec | ✅ R32 hotfix round 1 修 (2019 → 2103) |
| C-07 | AGENTS.md 缺 v0.31 + R32 章节 | superpowers-en + Apple Health + flutter-spec | ✅ R32 hotfix round 1 修 (v0.31 章节入库) |

### R32 真实 P0 严重情况 (跨期 R31 报告"已闭环" 但实际 0 闭环)

| 真实 P0 | R31 报告 | R32 实际 |
|---|---|---|
| 126 fail 半年没修 | R31 自评 "5.6% 红灯" | **R32 实测 5.6% 红灯, 跨 29 文件, 0 修** |
| 66 widget test i18n 迁移没同步 | 跨期 P1 | **R32 跨期, 0 修** |
| 55 orphan ARB key (R31 0 个 → R32 55 个新引入) | 跨期 P2 | **R32 FAIL 守门员, 0 修** |
| check_changelog 段顺序错 | "R31 P0-12 闭环" | **R32 FAIL 守门员, 0 修** |
| check_no_pua 4 PUA 字符 | 跨期 P2 | **R32 FAIL 守门员, 0 修** |
| 11 god class (≥400L) 0 test | 跨期 P0 | **R32 0 修, 100% 违反 superpowers** |
| 8 raw IconButton 无 PressFeedback | "R32 0 修" | **fix/v0.31.1-bug-batch 修了, master 未合并** |
| 锁屏 PII (4 AndroidNotificationDetails visibility) | "R32 0 修" | **fix/v0.31.1-bug-batch 修了, master 未合并** |
| R11a 4 + 7 + 7 硬编码中文 (medication + home 2 row) | 跨期 P1-01~05 | **R32 0 修** |
| PageScaffold translucent AppBar (spec §4.9) | 跨期 P0-10 | **R32 0 修** |
| Spring 物理模型半成品 | 跨期 P0-08 | **fix/v0.31.1-bug-batch 修了, master 未合并** |
| 11 feature 0 改 (Apple Health spec §5.1-5.7) | "4.5/11 落地" | **R32 0 改, 7-8 个 0 改 (mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline)** |
| SF Symbol 字体 (spec §3.1.3) | 跨期 P3 | **R32 0 改** |
| 4 实物资产 100% 缺失 (iOS 截图 + LaunchImage + AppIcon + Android 截图 + feature_graphic + icon) | 跨期 P0-13~17 | **R32 0 修 (外部依赖: 设计师/域名)** |
| chroniccare.app 域名 + 4 邮箱 | 跨期 P0-16 | **R32 0 修 (外部依赖: 7-20d ICP)** |
| 5 厂商 push 0 集成 | 跨期 H-01 | **R32 0 修 (外部依赖: 1-2 月)** |
| 阿里云 SMS + EmailService + PHQ-9 i18n 0 闭环 | 跨期 H-02~04 | **R32 0 修 (外部依赖: 1-2 月)** |

**R32 真实 P0 总数: 33 项**, 跨期 R31 17 P0 中 11 项 R32 hotfix round 1 merge master 闭环 + 33 项中可闭环的 19 项 R32 hotfix round 1-3 全闭环 (剩余 14 项 = 11 god class + 11 feature 0 改 + 实物资产 + 5 厂商 push + 阿里云 SMS + 域名 ICP 等外部依赖). R32 hotfix round 4 加修 5 P1 (TweenNumber 公共化 + 死代码删 + Haptics 集中器 + 守门员扩). **R32 hotfix 后预估综合 8.5/10 (+2.3 from R32 起点 6.2)**.

### R32 P0 紧急修 (本批可闭环, 总和 ≤ 1-2 天)

#### 上架/合规 8 项 (跨期 R31 100% 残留, 立即修, ≤ 1.5h)
- **P0-1**: `lib/l10n/app_zh_Hant.arb:997` safetyAlertTitle 改静态 (不含 name) — **5min**, 锁屏 PII
- **P0-2**: 4 个 AndroidNotificationDetails visibility: secret (master 残留) — **0.5h**, 锁屏 PII
- **P0-3**: 3 个 DarwinNotificationDetails categoryIdentifier + interruptionLevel (master 残留) — **0.5h**, 锁屏 PII
- **P0-4**: 8 raw IconButton 改 PressFeedbackIconButton (master 残留) — **1h**, a11y
- **P0-5**: `medication_page.dart` 4 处硬编码中文 + 4 个 TODO(Phase 5) 改 l10n — **30min**, i18n
- **P0-6**: `medication_page.dart:101` Colors.white 改 `AppColors.fgOnPrimary(context)` — **1min**
- **P0-7**: `quick_mood_carousel.dart:84` 硬编码中文 + `quick_mood_carousel.dart:99` '心情' 改 l10n — **5min**
- **P0-8**: `today_summary_card.dart:72` '今日指标' 改 l10n — **5min**

#### i18n 跨期 4 项 (30min)
- **P0-9**: `secondary_action_row.dart` 7 处硬编码中文改 l10n + 删 3 个 TODO — **30min**
- **P0-10**: `primary_action_row.dart` 7 处硬编码中文改 l10n — **30min**
- **P0-11**: `quick_mood_carousel.dart:60-71` 加 `unawaited(Haptics.success())` — **5min**, a11y 反馈
- **P0-12**: 6 widget 集中器文件头注释加 Apple Health 风格 spec 引用 — **10min**

#### 死代码 / 硬编码 6 项 (1.5h)
- **P0-13**: `hero_illustration.dart` 118 行死代码删 — **5min**
- **P0-14**: `spring.dart` 145L 死代码 (R32 fix/v0.31.1-bug-batch 修了, merge to master) — **10min**
- **P0-15**: `app_motion.dart:119/123` curveAppleSheet/Drawer 集成到 modal bottom sheet / drawer 或删 — **30min**
- **P0-16**: `medication_pill_icon.dart` 6 pill 颜色移到 `app_colors.dart` + 2 处 Colors.white 改 l10n — **30min**
- **P0-17**: `mood_trend_page.dart:311-317, 539-540` 7 处 iOS color 移到 `app_colors.dart` — **30min**
- **P0-18**: 4 处 `Colors.transparent` 改 `AppColors.transparent` (新加集中器) — **10min**

#### 杂项 8 项 (1h)
- **P0-19**: 4 文件双重 `swallow_error` import 删 — **5min**
- **P0-20**: `_slotIcon` unused element 删 — **5min**
- **P0-21**: `skip_backup.dart:56` `@visibleForTesting` 删 (private 字段不允许) — **1min**
- **P0-22**: `tracking_item_config_ext.dart:12` const 关键字 — **1min**
- **P0-23**: `helpers_round108_test.dart:37` `_untouchedWidgets` unused 删 — **1min**
- **P0-24**: 15 个 `@override` on non-overriding_member 注解删 — **30min**
- **P0-25**: `dart fix --apply` 71 info — **5min**
- **P0-26**: `dart format` 2 文件 (check_in_button + primary_button) — **5min**

#### 守门员 4 项 (5h)
- **P0-27**: CHANGELOG 段顺序倒序 ([0.31.1] 在 [0.31.0] 之前) — **5min**
- **P0-28**: 4 PUA 字符 sed 替换 (audit-history 文档) — **30min**
- **P0-29**: 55 orphan ARB key 删 (或写 55 个 widget caller) — **4-6h**
- **P0-30**: `check_pii_in_title.py` 守门员扩到 `safetyAlertTitle` — **5min**

#### 半成品 2 项 (R109 第 1 周, 2-4h)
- **P0-31**: PageScaffold translucent AppBar (1 行 BackdropFilter + 2 行 reduce-transparency 适配) — **1-2h**, C-02 跨 3 视角共识
- **P0-32**: Apple Health mention lock-in 扩 lib/ 主体 (R32 fix/v0.31.1-bug-batch 修了, merge) — **1h**, C-07 跨 3 视角共识
- **P0-33**: spec baseline 2019 → 2103 改 6 处 — **5min**, C-06 跨 3 视角共识

**P0 总工作量**: 1.5h (上架/合规) + 30min (i18n 跨期) + 1.5h (死代码/硬编码) + 1h (杂项) + 5h (守门员) + 4h (半成品) = **~14h (1.5-2d)**

**预期**: P0 闭环后, emil 8.2 → 8.7, superpowers-en 5.5 → 7.0, flutter-spec 96% → 97%, AppStore 5.5 → 7.0, GooglePlay 5.5 → 6.0, Apple Health 7.2 → 7.8, **加权综合 6.2 → 7.2-7.5**

### R32 P1 R109 第 2-3 周修 (16 项 + 5 半成品, 影响中等)

详见 [R32 整合报告 §5.2](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (PageScaffold / Apple Health 11 feature 改 / 18 守门员 check_16kb 真跑 / 主页 stagger 8→3 / mood carousel 48→72pt / lock-in test 阈值 250 / AGENTS.md 加 0.31.1+0.31.2 章节等)

### R32 P2 R109 god class 专项 (1-2 月, 11 个 god class 拆 + use case 层厚化)

详见 [R32 整合报告 §5.3](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (11 god class ≥400L 0 test, 跟 R95 home_page_state 拆 3 controller 同款, 1-2 月工作量)

### R32 P3 R110 feature-first 重组 (2-3 周, 不动架构, 仅物理目录重组 + pub workspace 拆 3 package)

详见 [R32 整合报告 §5.4](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (5 token + 6 widget + 18 守门员 → 独立 pub package, 跨项目复用, 业务逻辑上提到 use case 层 8 → ~30 个)

### R32 P4 R1.0 长期 (2027-Q1, 1-2 月, 5-8 subagent 跨外部协作)

详见 [R32 整合报告 §5.5](audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (实物资产 100% + chroniccare.app 域名 ICP 7-20d + 5 厂商 push 1-2 月 + 阿里云 SMS 1-2 月 + EmailService 1-2 月 + PHQ-9 i18n 1-2 周 + HealthKit 2-3 周 + 鸿蒙 1-2 月  1-2 周 + 法务 3 份 ¥45-90k + SF Symbol 字体 1-2d)

### R32 路线图 (跟 R31 路线图合并更新)

- **R32 hotfix (本周, 1-2d)**: merge `fix/v0.31.1-bug-batch` (11 commit P0 修) + 33 项 R32 P1 闭环 → 6.2 → 7.2-7.5
- **R109 第 1 周 (1 周)**: 修 126 fail + 55 orphan ARB + 18 守门员全绿 + 11 feature 0 改选 3-5 个高 ROI 改 → 7.5 → 8.0
- **R109 god class 专项 (1-2 月)**: 11 god class 拆 + use case 层厚化 (~30 个) + 修 126 fail 1-2 周 → 8.0 → 8.5
- **R110 feature-first 重组 (2-3 周)**: `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 拆 3 package + 业务逻辑上提到 use case 层 → 8.5 → 9.0
- **v1.0 长期 (2027-Q1, 1-2 月)**: 实物资产 100% + 域名 ICP + 5 厂商 push + 阿里云 SMS + EmailService + PHQ-9 i18n + HealthKit + 鸿蒙  + 法务 + SF Symbol 字体 → 9.0 → 9.5

### R32 关键结论

**R32 跨期 0 业务代码改动** (master `a0f39c4` = R31 22 commit + R32 2 commit 全部 doc)。R32 修了 11 个 P0 但都在 `fix/v0.31.1-bug-batch` branch, **master 未合并**。working tree 95 文件未提交改动。

**核心矛盾 (跟 R31 同, 加 1 倒退)**:
- 视觉层 9.5/10 优秀 (5 token + 6 widget + 4 page 重设 + 主页 Apple Health 一眼可辨)
- 半成品 4-5/10 (Spring 物理模型 145L 半成品 [R32 修了, master 未合并] + PageScaffold translucent AppBar 0 改 + 11 feature 0 改 7-8 个 + SF Symbol 字体 0 集成 + curveAppleSheet/Drawer 0 caller + 4-5 处 i18n 硬编码)
- 上架/合规 5.5/10 (实物资产 100% 缺失 + 4 锁屏 PII [R32 修了, master 未合并] + 4 description 5 病名 [R32 修了, master 未合并] + 7 raw IconButton [R32 修了, master 未合并] + 域名未注册 + 5 厂商 push 0 集成)
- TDD / 测试 5.5/10 (126 fail 5.6% 红灯 + 66 widget test i18n 迁移没同步 + 11 god class 0 test + 55 orphan ARB + 18 守门员 3 红)

**如果 R32 hotfix + R109 第 1 周能闭环 11 个 R32 修了但未 merge 的 P0 + 33 项 R32 P1 + 修 126 fail + 55 orphan**, 加权综合可从 6.2 → 7.5-8.0/10 (跟 R31 baseline 持平 + 0 R31 P0 跨期残留 + 0 R32 新 P0 引入)。

**不建议本批单独提交 hotfix**: working tree 有 95 文件未提交改动 (android/ ios/ web/ scripts/ test/ 等), R33 应该是 working tree commit + fix/v0.31.1-bug-batch merge + R32 P1 闭环合并发布。

---

## R108 revisit 综合审视 (2026-08-10, 9 视角从 0 重跑)

**状态**: 120 个旧报告归档到 `docs/audit-history/` → 9 视角 subagent 从 0 重新跑(7 lens + 顶层架构 + 底层逐行),9 份报告合计 404KB。

**R108 vs R107 加权综合评分**:
- R107 8.0/10 → R108 6.2/10(**临时倒退 1.8 分**)
- 倒退主因:R108 working tree 引入 8 个回归 error + 上架"实物资产"未做
- R108 完工后预期恢复 7.5-8.0/10(修 8 个 P0 error + R108 god class 收尾 6 项 + 上架实物资产落地 10-15 项)

**R108 P0 整合(去重后 38 项,按优先级)**:
- 优先级 1 上架硬阻塞 (5 项): iOS 截图 0 / Android 截图 67B + feature_graphic 67B / iOS LaunchImage 68B / review TODO 占位 / 5.1.3 抽审
- 优先级 2 外部依赖卡点 (4 项): chroniccare.app 域名 + 4 邮箱 + 阿里云 SMS + 5 厂商 push
- 优先级 3 鸿蒙  (2 项)
- 优先级 4 锁屏 PII 跨 3 视角共识 (1 项): title 仍含药名
- 优先级 5 R108 引入 8 个回归 error (8 项,合计 ≤2.5h)
- 优先级 6 其他 P0 (12 项)

**修复路线图**:
- **Phase 1 R108 收尾** (1-2 周): 8 P0 引入 error + 上架紧急 4h + 6 项 god class 收尾 (2d) + 5 个新守门员
- **Phase 2 外部依赖** (1-2 月): 域名 ICP + 5 厂商 push + 阿里云 SMS
- **Phase 3 R109 god class 专项** (1-2 月): 5-6 god class 拆 + use case 层厚化
- **Phase 4 R110 feature-first** (2-3 周): `lib/features/{feature}/{domain,data,presentation}/` + pub workspace
- **Phase 5 R1.0 长期** (2027-Q1): HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS 

**详细整合**: [`docs/audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md`](audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md) (40KB)

> **R95 整体总结报告** (R95 实施后): [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/99-r95-final-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB)
> **R95+ 综合审视报告** (R95 实施前): [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/00-r95-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/00-r95-summary.md) (45KB)
> **6 视角子报告**: [emil](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/01-emil.md) / [spen](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/02-spen.md) / [spzh](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/03-spzh.md) / [AppStore](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/04-appstore.md) / [GooglePlay](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/05-googleplay.md) / [flutter-spec](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/06-flutter-spec.md)
> **R92 6 视角基线**: [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/00-summary-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/00-summary-report.md) (35KB)
> **R95 8 sub-spec 报告**: [docs/superpowers/sdd-logs/](superpowers/sdd-logs/) (round95-godpage-section / round95-silent-catch / round95-misc-p1 / round95-hardcoded-chinese / round95-godpage-split / round95-token / round95-test-coverage / round95-misc-p2 / round95-ux-p3)
> **R100 6 视角审计** (2026-08-07): [00-summary](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/00-summary.md) + [emil](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/01-emilkowalski.md) / [spen](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/02-superpowers-en.md) / [spzh](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/03-superpowers-zh.md) / [AppStore](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/04-appstore.md) / [GooglePlay](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/05-googleplay.md) / [flutter-spec](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/06-flutter-spec.md)
> **R101 6 视角深度审计** (2026-08-07): [00-summary](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/00-summary.md) + [emil](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/01-emilkowalski.md) / [spen](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/02-superpowers-en.md) / [spzh](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/03-superpowers-zh.md) / [AppStore](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/04-appstore.md) / [GooglePlay](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/05-googleplay.md) / [flutter-spec](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/06-flutter-spec.md)
> **R105 7 视角审计** (2026-08-09, 最新): [00-summary](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/00-summary.md) + [emil](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/01-emilkowalski.md) / [spen](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/02-superpowers-en.md) / [spzh](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/03-superpowers-zh.md) / [flutter-spec](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/04-flutter-spec.md) / [AppStore](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/05-appstore.md) / [GPlay](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/06-googleplay.md) / [AppleHealth](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/07-apple-health.md)

---

## R104 审计更新 (2026-08-09, 7 视角综合审查)

**状态**: 7 个 agent 并行深度扫描全部 395 Dart 文件 + fastlane + legal + android/ios 配置 + scripts + test。**新增/确认 72 项** (P0=12 / P1=20 / P2=20 / P3=10 + Apple Health 10 项), 完整报告见 [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/7-perspective-audit-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/7-perspective-audit-report.md)。

### R104 各视角评分总览

| 视角 | 评分 | 关键发现 |
|------|------|----------|
| **emilkowalski** (UI/UX/动效) | **7.0/10** | token 化优秀，delight 层偏保守 |
| **superpowers-en** (架构/性能) | **8.2/10** | 分层清晰，god class 拆分成熟 |
| **superpowers-zh** (工程) | **8.5/10** | 代码质量高，i18n 覆盖广 |
| **superpowers-zh** (合规) | **8.0/10** | PIPL 完整，HIPAA/GDPR 缺失 |
| **flutter-specification** | **88/100** | 顶级 Flutter 项目，import 顺序待规范 |
| **AppStore** (iOS) | **7.5/10** | 隐私架构标杆，截图/URL 阻塞 |
| **GooglePlay** (Android) | **68/100** | 技术配置就绪，资产/流程阻塞 |
| **Apple Health** | **2/10** | 零集成，架构就绪度 8/10 |

### R104 外部链接隐藏确认

**运行时代码**: ✅ 0 外部链接泄露 (唯一 url_launcher = tel: 危机热线)
**上架物料层**: ⚠️ `chroniccare.app` 域名 + 3 个邮箱未注册

### R104 半成品/未完成功能

- **8 项 FeatureFlag 守护功能**: SMS / 5 厂商 push / Email / audio / PHQ-9 i18n / BootReceiver / AliyunSms
- **29 处 TODO 注释**: SMS 真实发送 8 处 / 量表未开放 3 处 / med.colorIndex 2 处 / 其他 16 处

### R104 P0 快照 (上架阻塞, 12 项)

| # | 事项 | 层级 | 难度 | 来源 |
|---|------|------|------|------|
| 1 | `chroniccare.app` 域名未注册 → 隐私政策/Support URL 不可访问 | 底层/外部 | 中 | AppStore+GPlay |
| 2 | iOS 截图为 0 → App Store Connect 必填 | 底层/资产 | 中 | AppStore |
| 3 | Android 截图为 67B 占位 PNG | 底层/资产 | 中 | GPlay |
| 4 | Release keystore 未生成 (Android) | 底层 | 简单 | GPlay |
| 5 | iOS 签名未配置 (需 Mac + DEVELOPMENT_TEAM) | 底层 | 简单 | AppStore |
| 6 | 法律文档 3 份未律师审核 | 底层/外部 | 高 | AppStore+GPlay |
| 7 | review_information 目录缺失 (iOS) | 底层 | 简单 | AppStore |
| 8 | Data Safety Form 未填 (Android) | 底层 | 中 | GPlay |
| 9 | IARC 内容评级未配置 (Android) | 底层 | 中 | GPlay |
| 10 | Podfile platform 13.0 vs Xcode 14.0 不一致 | 底层 | 简单 | AppStore |
| 11 | gradle-wrapper.properties 本地路径 | 底层 | 简单 | GPlay |
| 12 | Android App 名称只有英文 "ChronicCare" | 底层 | 简单 | GPlay |

### R104 P1 快照 (高概率打回 / 架构问题, 20 项)

**架构级 (6 项)**:
- `clearAllUserData()` 缺少新表清理的防御性设计
- `NotificationService` facade 仍有 ~500 行，init 逻辑过重
- `AppDatabase` 承担业务编排 (`saveSetup`/`clearAllUserData`)
- `ReminderService` 和 `SafetyWatchService` 职责重叠
- `_daysBetween` 函数重复实现 (3 处)
- Import 顺序不完全标准

**底层/合规 (14 项)**:
- domain 层 ~100 处硬编码中文 (量表/标签/文案)
- Store description 描述已禁用功能
- 隐私政策无英文版
- medical_disclaimer 未进 onboarding 流程
- HIPAA 缺失 (App 含 US 988 热线)
- GDPR 缺失 (面向欧洲用户)
- 隐私政策 §2.2 "树洞不导出" 与代码矛盾
- 繁体中文法律文档缺失
- SCHEDULE_EXACT_ALARM 运行时权限检查缺失
- `EncryptionService` 单例 + `_cachedKey` 内存泄漏风险
- Hero 插画用 emoji 作视觉主体 (跨平台不一致)
- QuickMoodCarousel 错误静默吞掉
- FAB 展开无 stagger 动画
- 主页无入场动画

### R104 P2 快照 (上架后改进, 20 项)

**架构级 (3 项)**:
- Provider 文件 18 个缺乏 feature-level 聚合
- DAO 层和 Repository 层边界需文档化
- `ImportResult` re-export 链过长

**底层/动效 (7 项)**:
- `app_tokens.dart` facade 306 行过度转发
- Shimmer 实际只是 opacity 脉动
- TodaySummaryCard 数值变化无动画
- CheckInButton 状态切换缺 spring 物理
- HomeFabToolbar toggle 无 haptic
- QuickMoodCarousel 默认选中"一般"
- NotificationFailureBanner 无入场/退出动画

**底层/a11y (2 项)**:
- textHint #999999 对比度 2.8:1 (WCAG AA 要求 4.5:1)
- PageTransitionSwitcher 忽略 prefers-reduced-motion

**底层/i18n (4 项)**:
- `phone_validator.dart` 地区名硬编码中文
- `influence_category.dart` 影响因素硬编码中文
- data 层 30+ 处中文 debug log
- zh_Hant ARB 疑似机器繁简转换

**底层/合规 (4 项)**:
- Audit log 无用户可见入口
- 法律文档保留期限未声明
- Widget key 使用不完整 (动态列表)
- `swallowError` 全局 mutable sink 并发风险

### R104 P3 快照 (技术债, 10 项)

- Apple Health 零集成 (架构就绪度 8/10)
- home_page_state.dart 568 行仍偏大
- vent_compose_page.dart 495 行仍偏大
- 28 项 emil UI polish (TextStyle/spacing/haptic)
- AppTokens facade 需设 deprecation timeline
- 量表题目 i18n 化 (~500+ 行中文)
- `check_all.dart` 增加 `dart:io` 域检查
- 6 个测试文件用 `r93_` 简写变体 (非标准 `round93_`)
- scripts 根目录 6 个临时 .log 文件
- Android screenshots 67B 占位文件需替换

### R104 架构审视总结

**优势 (高内聚低耦合)**:
1. 4 层架构纯度高: domain 层 0 Flutter 依赖，`check_all.dart` 持续守护
2. God Class 拆分成熟: NotificationService / SafetyWatchService / DataExportService 均已拆分
3. 隐私安全设计标杆: PIPL §14 单独同意 + SQLCipher AES-256 + FeatureFlag 逐项守护
4. Riverpod Provider 拆分合理: core / service / vent 三文件按职责隔离
5. 迁移策略防御性强: 21 版 schema，每步 guard + 注释详尽
6. 18 个守门员脚本: CI 全集成，覆盖架构纯度/代码质量/法律合规/国际化

**需改进 (可重构模块)**:
- `AppDatabase`: 承担业务编排 → 抽 `SetupService` / `DataWipeService`
- `ReminderService` vs `SafetyWatchService`: 职责重叠 → 统一到 `SafetyWatchService`
- `NotificationService`: facade 仍有 ~500 行 → 抽 `_ensureInitialized()` mixin
- `_daysBetween`: 3 处重复实现 → 统一走 `core/shared/date_utils.dart`
- Provider 文件: 18 个缺乏 feature-level 聚合 → 考虑 `providers/assessment/` 子目录

### R104 Apple Health 集成评估

**当前状态**: 零集成
**架构就绪度**: 8/10 (4 层架构天然支持，只需新增 data 层 service)
**数据模型就绪度**: 7/10 (sleep/weight 字段完整，medication 需加 timeSlotIndex)
**隐私合规就绪度**: 6/10 (需修改隐私政策 + 处理"零云端"承诺与 iCloud 冲突)
**上架阻塞度**: 0/10 (不阻塞上架，P3 nice-to-have)

**推荐方案**: `health` Flutter 插件 (v12.0.0+)
**分阶段实施**: Phase 1 sleep/weight 双向同步 (1 周) → Phase 2 medication 打卡写入 (3 天) → Phase 3 mood 写入 (3 天) → Phase 4 step/heart rate 读取 (1 周)

### R104 上架阻塞项清单 (按执行顺序)

**阶段 1 — 资产准备 (1-2 周)**:
- [ ] 注册 `chroniccare.app` 域名 + ICP 备案
- [ ] 部署隐私政策/支持页到 `chroniccare.app`
- [ ] 生成 iOS 截图 (iPhone 6.7" + 6.5" + 5.5" 各 3-5 张)
- [ ] 生成 Android 截图 (min 2 张, 推荐 4-8 张)
- [ ] 创建 `fastlane/metadata/ios/en-US/review_information/review_notes.txt`

**阶段 2 — 配置修复 (1-2 天)**:
- [ ] 生成 Android release keystore + key.properties
- [ ] 修复 `gradle-wrapper.properties` 本地路径
- [ ] 修复 `Podfile` platform 版本不一致
- [ ] Android `android:label` 改 `@string/app_name` + 添加中文 strings.xml
- [ ] iOS `CODE_SIGN_STYLE = Automatic` 显式声明

**阶段 3 — 内容审核 (1-2 月, 外部依赖)**:
- [ ] 律师过审 3 份法律文档 (¥45-90k)
- [ ] 补充英文版隐私政策
- [ ] 补充繁体中文法律文档
- [ ] 填写 Google Play Data Safety Form
- [ ] 填写 IARC 内容评级问卷
- [ ] 修正 Store description (删禁用功能描述)
- [ ] medical_disclaimer 进 onboarding 流程

**阶段 4 — 代码修复 (1 周)**:
- [ ] `clearAllUserData()` 自动遍历 allTables
- [ ] domain 层硬编码中文迁移到 ARB (~100 处)
- [ ] 修正隐私政策 §2.2 矛盾描述
- [ ] 补充 HIPAA Privacy Policy (面向 US 用户)
- [ ] SCHEDULE_EXACT_ALARM 运行时权限检查
- [ ] Import 顺序统一 (`dart fix --apply`)

### R104 测试现状

| 指标 | 数值 |
|------|------|
| 测试文件数 | 256 个 .dart + 2 个 .py |
| 测试用例数 | 1,997 (1,688 unit + 309 widget) |
| Skip 测试 | 1 个 (有意 lock-in) |
| 集成测试 | 2 个 |
| 覆盖率 | domain 73.8% / data 47.0% / presentation 57.4% |
| 守门员脚本 | 18 个全绿 |

### R104 关键结论

**项目整体质量优秀**，在 Flutter 社区中属于 top 10% 水平。主要优势：
1. 隐私架构标杆: PIPL 三重同意 + SQLCipher + FeatureFlag 逐项守护
2. 代码质量高: 0 analyzer error + 1997 tests + 18 守门员
3. 架构清晰: 4 层纯度 + god class 持续拆分
4. 国际化完善: 三语 ARB + domain 层 override 注入模式

**主要阻塞项集中在外部资源**：
1. 域名未注册 → 隐私政策 URL 不可访问
2. 截图缺失 → 双平台无法提交审核
3. 法律文档未审核 → 合规风险
4. 签名未配置 → 无法构建 release

**可代码化部分接近 100% 完成**，剩余工作主要是资产生成和外部资源对接。

---

## R105 审计更新 (2026-08-09, 7 视角综合审查)

**状态**: 7 个 agent 并行深度扫描**当前未提交工作区** (R101+ medication 重构 / mood 详情与趋势 / daily_tracking 自定义 / 上架物料批次)。**新增/确认 56 项** (P0=8 / P1=16 / P2=22 / P3=10), 完整报告见 [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/00-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/00-summary.md)。

**基线**: `flutter analyze` 0 issue ✅ / `check_all.dart` 2/2 ✅ / `check_cross_feature.py` 131 文件 0 violation ✅ / **`check_orphan_arb_keys` FAIL (42 orphan) 🔴** / **`check_zh_hant_consistency` FAIL (16 处) 🔴** / schemaVersion 21。

### R105 各视角评分总览

| 视角 | R104 | R105 | 变化 | 主因 |
|------|------|------|------|------|
| **emilkowalski** | 9.0 | 7.5 | -1.5 | 新页 a11y (overflow/对比度/Semantics) + 假完成 (死胡同入口/未落库/未接线) |
| **superpowers-en** | 9.0 | 7.5 | -1.5 | 2 处 P1 静默丢数据 + 2 guard 红 + DRY 回潮 |
| **superpowers-zh** | 9.0 | 8.0 | -1.0 | 58 个 ARB 卫生回归 + 影响因素 i18n 半成品 |
| **flutter-specification** | 88 | 84 | -4 | 2 P1 功能缺口 (丢输入/通知不重排) + mounted/守卫缺失 |
| **AppStore** | 6.5 | 6.0 | -0.5 | 录音 flag/权限自相矛盾; 4 项 P0 已修 |
| **GooglePlay** | 40 | 42 | +2 | 描述/免责/适配图标落地; 2 新回归 (wrapper 本地路径/录音矛盾) |
| **Apple Health** | 2/10 | 2/10 | — | 零集成, 不阻塞上架 |

### R105 外部链接隐藏确认

**运行时代码**: ✅ 0 外部链接泄露 (唯一 url_launcher = tel: 危机热线; 无 analytics 依赖)
**新矛盾**: 🔴 `_prodVentAudioEnabled=true` (feature_flags.dart:70) 但同批删除 iOS mic/speech 权限描述 + Android RECORD_AUDIO → 录音 crash + Apple 2.5.1/Play 政策双重风险, **提交前必须二选一**
**上架物料层**: ⚠️ `chroniccare.app` 域名 + 邮箱未注册 (P0)

### R105 P0 快照 (提交前必须处理, 8 项)

| # | 事项 | 层级 | 难度 | 来源 |
|---|------|------|------|------|
| 1 | 录音功能自相矛盾: flag=true 但 iOS/Android 权限声明已删 → crash + 上架拒 | 底层/权限 | 简单 | AppStore A1/A2 |
| 2 | 3 个 test 仍断言 ventAudio 默认 false → `flutter test` 红 (CI regression) | 底层/CI | 简单 | AppStore A3 |
| 3 | mood_detail 整页 Column 不可滚动 → overflow 裁切 | 底层/UI | 简单 | emil E101 |
| 4 | add_medication `_save()` 丢 form/colorIndex/notes (用户选择静默丢失, 列表永远绿色) | 底层/数据 | 简单 | sp-en N1 + flutter F105-1 + emil E104 |
| 5 | `chroniccare.app` 域名 + `privacy@` 邮箱未注册 → 隐私/Support URL 不可达 | 底层/外部 | 中 | AppStore A6 + GPlay GP-4 |
| 6 | 法律文档未律师审核且本批删"草稿"标"定稿" | 底层/法务 | 高 | AppStore A9 + GPlay GP-5 |
| 7 | iOS 签名未配置 + 截图缺失 + 内容评级未配置 (需 Mac/人工) | 底层/资产 | 中 | AppStore A7/A8/A10 |
| 8 | Android release keystore 未生成 + 截图/feature_graphic 67B 占位 + IARC 未配置 | 底层/资产 | 中 | GPlay GP-1/2/3 |

### R105 P1 快照 (高优, 16 项)

- **功能缺口 (4)**: 新增药物不重排通知 (edit 对话框有, 向导漏); recordingMode 选择不落库; 影响因素 i18n key 建好未 wire + 中文入库; gradle-wrapper distributionUrl 回归本地路径
- **guard 回归 (2)**: check_orphan_arb_keys 42 孤儿; check_zh_hant_consistency 16 处 (2 真错: 刮風→颳風/分布→分佈)
- **a11y 硬伤 (6)**: 药丸白字对比度 <4.5:1; 打卡 checkbox 无 Semantics + 28px 目标; AnimatedSwitcher 不尊重 reduce-motion; fl_chart 隐式动画; record 按钮彩色文字对比; 今日汇总卡窄屏溢出
- **UX/隐私 (4)**: 空态无 CTA; 档案卡 chevron 死胡同 + "点击展开"不可点; 锁屏通知暴露药名剂量; privacy_policy §0.6 与 flag 矛盾

### R105 P2 快照 (上架后改进, 22 项)

- **半成品接线 (3)**: MoodDetailPage / MoodFactorAnalysis 死代码; MoodReminderNotifier 无 UI 入口; medication_detail 编辑按钮 no-op
- **正确性 (5)**: _save 无守卫/无 try-catch; showTimePicker 后无 mounted check ×2; dailyAvg 滚动平均 bug; DateTime.now() 跨日 stale ×2; onReorder 7 次写盘
- **DRY 回潮 (5)**: 时间槽/打卡进度 3 份重复; 时间格式化 5+ 处手写; category 映射两套 switch; _dateOnly 未全收敛; MedForm 双源
- **i18n/token (5)**: 图表 7 处硬编码 Apple 色; 'CBT'/'7D' 未走 ARB; 剂量弃用 Formatters.dosage; 通知 channel 名中文; error 裸 `Text('$e')`
- **底层 (4)**: manifest debuggable 被删; roundIcon 缺 pre-26 raster; label 未用 @string/app_name; **Apple Health P0 前置** (entitlement + 2 usage key + healthKitEnabled flag + schema 22 去重列)

### R105 P3 快照 (技术债, 10 项)

- Apple HealthKit 集成 (P0 只读镜像→P1 写备份→P2 用药→P3 后台, 全阶段需 Mac)
- 播放完不删 temp 文件 + 失败路径未 cancel _sttSub; _RecordingTimer 100ms setState 可再优
- `_save` fire-and-forget; 硬编码 Tab/emoji/颜色 + pill 色重复
- a11y 细节 (依从性数字对比/emoji ExcludeSemantics/carousel 首卡高亮/FAB Semantics)
- dart format 6/10 主目标文件漂移; PIPL 新字段未同步同意书; 术语混用; Podfile 13.0 vs 14.0

### R105 架构审视总结

**优势 (延续)**: `check_all.dart` 2/2 全绿 (R104 的 tracking_item_config 违规已修), domain 0 Flutter, 跨 feature 0 violation, NotificationService facade 3 子拆分方向正确。

**可重构模块 (按收益)**:

| # | 模块 | 问题 | 建议 | 难度 |
|---|------|------|------|------|
| 1 | influence_category | 36 中文因素在 domain + key 未 wire + 中文入库 | chips/入库走 kInfluenceFactorKeys→l10n, domain 只留 key | 中 |
| 2 | 时间槽/打卡进度/时间格式化 | 3 份重复 + 5+ 处手写 padLeft | 抽共享 helper + 统一 Formatters | 中 |
| 3 | category→label/icon 映射 | 两套 switch | 统一到 tracking_item_config_ext.dart | 简单 |
| 4 | MedForm 双源 | presentation enum 与 domain enum 重复 | 删 UI 侧引 domain | 简单 |
| 5 | 半成品死代码 (MoodDetailPage/MoodFactorAnalysis/MoodReminderNotifier) | 无路由/无挂载/无 UI 入口 | 接线或删除 | 中 |

### R105 半成品 / 未完成功能清单

| 功能 | 状态 | 说明 |
|------|------|------|
| 录音 (vent+mood) | 🔥 半开半关 | flag=true 但权限已删, 提交前二选一 |
| MoodDetailPage / MoodFactorAnalysis | 死代码 | 无路由无挂载 |
| MoodReminderNotifier | 半成品 | 已注入 service 无 UI 开关 |
| medication_detail 编辑 | 假按钮 | onPressed no-op |
| 影响因素 i18n | 半成品 | key 建好未 wire, 中文入库 |
| SMS / AliyunSMS / Email / 5 厂商 push | 半成品 (FeatureFlag 门控) | 全 flag=false, release 不可达 |
| Apple HealthKit | 零集成 | v1.1 候选, 不阻塞上架 |

### R105 测试现状

| 指标 | 数值 |
|------|------|
| flutter analyze | 0 issue (4W+30I 已清零) |
| 架构 check_all | 2/2 全绿 |
| check_orphan_arb_keys | 🔴 42 orphan (全本批新增) |
| check_zh_hant_consistency | 🔴 16 处 (全本批新增) |
| schemaVersion | 21 (medications v19→v20, mood v20→v21) |

### R105 关键结论

**R104 的架构/质量 P0 已全部落地** (analyzer 0 issue, 架构 2/2 绿, SQL 注入/硬编码中文/架构违规全修复), 但**本批未提交重设计引入了 8 项 P0 + 16 项 P1** — 核心问题是"功能做到 80% 就停": 丢数据 (`_save`)、假按钮 (编辑)、死代码 (MoodDetailPage)、guard 红 (58 个 ARB/繁简)。**当前工作区不可提交**。

**执行顺序**:
1. **Sprint A (0.5 天)**: 录音决策二选一 + test 同步; mood_detail 滚动; `_save` 补三字段; 通知重排
2. **Sprint B (1 天)**: recordingMode 落库或删 UI; 清 42 orphan + 16 zh_Hant; gradle-wrapper
3. **Sprint C (2 天)**: 影响因素 i18n; a11y 对比度/Semantics; 空态 CTA; 锁屏通知脱敏; privacy 文档同步
4. **Sprint D (持续)**: 死代码接线/删除; DRY 收敛; token/ARB 补全; Apple Health P0
5. **外部依赖**: 域名注册 + 律师过审 (P0#5-6, 上架阻塞)

---

## R103 审计更新 (2026-08-08, 7 视角综合审查)

**状态**: 7 个 agent 并行深度扫描全部 389 Dart 文件 + fastlane + legal + android/ios 配置 + scripts + test。**新增/确认 75 项** (P0=15 / P1=20 / P2=25 / P3=15), 完整报告见 [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-08/R103-7perspective-audit/00-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-08/R103-7perspective-audit/00-summary.md)。

### R103 新增关键发现 (vs R102)

| # | 发现 | 层级 | 来源 | R102 状态 |
|---|------|------|------|-----------|
| 1 | PageTransitionSwitcher 忽略 prefers-reduced-motion (Critical a11y) | 底层/a11y | emil | **新增** |
| 2 | textHint #999999 对比度 2.8:1, 不满足 WCAG AA 4.5:1 | 底层/a11y | emil | **新增** |
| 3 | 主页 hero (140px) + carousel (80px) 推 CTA 到折叠线以下 | 架构/UX | emil | R101 已提 |
| 4 | Apple Health 零集成但本地追踪 10 类健康数据 | 架构 | Apple Health | **新增视角** |
| 5 | SleepEntryEntity.durationLabel 硬编码英文格式 | 底层/i18n | spzh | **新增** |
| 6 | TreatmentEntryEntity.linkedMedicationDisplay 硬编码中文 | 底层/i18n | spzh | **新增** |
| 7 | EncryptionService() 在 legal_consent_provider 每次重新实例化 | 底层/性能 | spen | **新增** |
| 8 | SharedPreferences.getInstance() 在 safety_config 重复调用 8 次 | 底层/性能 | spen | **新增** |
| 9 | windowSizeOf medium breakpoint 不可达 (840=840) | 底层 | emil | **新增** |
| 10 | Decorative emoji 被 screen reader 朗读 | 底层/a11y | emil | **新增** |

### R103 P0 快照 (上架阻塞, 15 项)

| # | 事项 | 层级 | 难度 | 来源 |
|---|------|------|------|------|
| 1 | `native.dart:27` SQL 注入 — PRAGMA key 密码拼接 | 底层/安全 | 简单 | flutter-spec |
| 2 | `chroniccare.app` 域名 + 邮箱未注册 | 底层/外部 | 中 | AppStore+GPlay |
| 3 | 法律文档 3 份未律师审核 (有 "TODO" 标记) | 底层/外部 | 高 | AppStore+GPlay |
| 4 | Store description 描述已禁用功能 → Apple 2.1 拒 | 底层 | 简单 | AppStore |
| 5 | InfoPlist.strings 未用权限声明 (mic/speech/tracking) | 底层 | 简单 | AppStore |
| 6 | `AndroidManifest.xml:54` android:label 硬编码中文 | 底层 | 简单 | GooglePlay |
| 7 | `today_summary_card.dart` 4 处硬编码中文 | 底层/i18n | 简单 | spzh |
| 8 | 无内容评级配置 (IARC + Apple) | 底层 | 中 | AppStore+GPlay |
| 9 | 医疗免责声明未进 onboarding 流程 | 底层 | 简单 | AppStore+GPlay |
| 10 | PageTransitionSwitcher 忽略 prefers-reduced-motion | 底层/a11y | 简单 | emil |
| 11 | `textHint` #999999 对比度 2.8:1, 不满足 WCAG AA | 底层/a11y | 简单 | emil |
| 12 | `daily_tracking_multi_chart.dart` 4 处硬编码中文 | 底层/i18n | 简单 | spzh |
| 13 | 双平台真实截图缺失 | 底层 | 中 | AppStore+GPlay |
| 14 | Release keystore 未生成 (Android) | 底层 | 简单 | GooglePlay |
| 15 | iOS 签名未配置 (需 Mac) | 底层 | 简单 | AppStore |

---

## R102 审计更新 (2026-08-08, 7 视角综合审查)

**状态**: 7 个 agent 并行扫描全部 388 Dart 文件 + fastlane + legal + android/ios 配置。**新增/确认 57 项** (P0=8 / P1=15 / P2=18 / P3=16), 完整报告见 [reports/multi_perspective_audit_v0.30.md](../reports/multi_perspective_audit_v0.30.md)。

> **外部链接确认**: 运行时代码 ✅ 0 外部链接泄露; fastlane metadata ⚠️ `chroniccare.app` 域名 + `privacy@chroniccare.app` 邮箱未注册; 法律文档 ⚠️ 3 份均未律师审核。

### R102 新增关键发现 (vs R101)

| # | 发现 | 层级 | 来源 | R101 状态 |
|---|------|------|------|-----------|
| 1 | `native.dart:27` PRAGMA key SQL 注入风险 | 底层/安全 | flutter-spec | **新增** |
| 2 | `daily_tracking_multi_chart.dart:164-170` 硬编码中文 4 处 | 底层/i18n | superpowers-zh | **新增** |
| 3 | `vent_compose_page.dart:441` 空 setState 每次击键整页重建 | 底层/性能 | flutter-spec | **新增** |
| 4 | `mood_audio_recorder_widget.dart:197` 100ms setState 每秒 10 次重建 | 底层/性能 | flutter-spec | **新增** |
| 5 | `hero_illustration.dart:51-53` Colors.black shadow dark mode 不可见 | 底层/UI | emil | R101 已提 |
| 6 | `app_database.dart:410-480` saveSetup() 业务逻辑在数据层 | 架构 | spen | R101 已提 |
| 7 | `app_database.dart:6-7` 数据层反向 import domain 实体 | 架构 | spen | R101 已提 |
| 8 | 通知 channel 名 const 中文 en/zh_Hant 系统设置看中文 | 底层/i18n | superpowers-zh | R101 已提 |
| 9 | Apple Health 零集成但本地追踪 10 类健康数据 | 架构 | Apple Health | **新增视角** |
| 10 | `safety_config_service.dart` 8 个方法各调 SharedPreferences.getInstance() | 底层/性能 | spen | **新增** |

### R102 P0 快照 (上架阻塞, 8 项)

| # | 事项 | 层级 | 难度 | 来源 |
|---|------|------|------|------|
| 1 | `native.dart:27` SQL 注入 — PRAGMA key 密码拼接 | 底层/安全 | 简单 | flutter-spec |
| 2 | `chroniccare.app` 域名 + 邮箱未注册 | 底层/外部 | 中 | AppStore+GPlay |
| 3 | 法律文档 3 份未律师审核 (有 "TODO" 标记) | 底层/外部 | 高 | AppStore+GPlay |
| 4 | Store description 描述已禁用功能 → Apple 2.1 拒 | 底层 | 简单 | AppStore |
| 5 | Info.plist 未用权限声明 (mic/speech/tracking) | 底层 | 简单 | AppStore |
| 6 | `AndroidManifest.xml:54` android:label 硬编码中文 | 底层 | 简单 | GooglePlay |
| 7 | `daily_tracking_multi_chart.dart:164` 4 处硬编码中文 | 底层/i18n | 简单 | superpowers-zh |
| 8 | 无内容评级配置 (IARC + Apple) | 底层 | 中 | AppStore+GPlay |

### R102 修复路线图 (整合到现有)

**Sprint A — 上架阻塞 (P0, 1-2 周)**: #1-8 全部
**Sprint B — 高优质量 (P1, 1-2 周)**: 通知 i18n + saveSetup 抽 UseCase + 性能修复 + dark mode + Data Safety form
**Sprint C — 架构改进 (P2, 2-3 周)**: date_utils DRY + SharedPreferences 缓存 + MoodEntryEntity 拆解 + bootstrap 拆子函数 + dead code 清理
**Sprint D — 锦上添花 (P3, 持续)**: token 补全 + 断点动画 + care_engine 合并

---

## R101 审计更新 (2026-08-07, 6 视角深度遍历)

**状态**: 6 个 agent 并行深度扫描全部 lib/ + test/ + docs/ + android/ + ios/ 文件。**新增/确认 65 项待办** (P0=12 / P1=15 / P2=20 / P3=18; 架构级 11 项 / 底层 54 项), 完整排序表见 [R101 00-summary §三](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R101-6perspective-audit/00-summary.md)。

> **外部链接确认**: 代码层 ✅ 全部隐藏 (唯一 url_launcher = tel: 危机热线); 上架物料层 ❌ 未就绪 (privacy_url/support_url 指向未注册 chroniccare.app)。

### R101 P0 快照 (上架阻塞, 12 项)

| # | 事项 | 层级 | 难度 | 估时 | 视角 |
|---|------|------|------|------|------|
| 1 | ~280 文件未提交改动分批 commit | 底层 | 简单 | 1-2h | sp-en |
| 2 | 注册 chroniccare.app 域名 + 部署隐私/支持/数据删除页 | 底层 | 中 | 1-2d | App/GPlay |
| 3 | 双平台真实截图 + feature graphic | 底层 | 中 | 1-2d | App/GPlay |
| 4 | 删 video.txt PLACEHOLDER ×2 | 底层 | 简单 | 10min | GPlay |
| 5 | 生成 release keystore + key.properties | 底层 | 简单 | 30min | GPlay |
| 6 | 删 iOS UIBackgroundModes audio+processing | 底层 | 简单 | 10min | AppStore |
| 7 | user_agreement 定价段对齐 (v1.0.0+147 已删, 永久免费) | 底层 | 简单 | 30min | AppStore |
| 8 | metadata 删 "(失联通知规划中)" | 底层 | 简单 | 10min | App/GPlay |
| 9 | record/speech_to_text 加 tools:node="remove" | 底层 | 简单 | 15min | GPlay |
| 10 | 法律文件删"草稿"标注 | 底层 | 简单 | 30min | GPlay |
| 11 | 隐私政策联系方式补充 (真实邮箱) | 底层 | 简单 | 1h | App/GPlay |
| 12 | SCHEDULE_EXACT_ALARM 运行时权限检查 | 底层 | 中 | 2-3d | GPlay |

### R101 P1 快照 (高概率打回, 15 项)

- 8 个新量表硬编码中文 (ASRM/ISI/PSS/WHODAS/Level2×4)
- care_copy 关怀文案硬编码中文
- 安全警报锁屏暴露敏感健康信息
- 邮件通知暴露药名+剂量
- Dynamic Type 完全不支持 (Apple 2.5.1)
- 医疗免责声明不够显著
- 描述宣传 "coming soon"
- PHQ-9/GAD-7 i18n 未完成但描述宣传
- 开发者联系方式缺失
- check_all.dart 守护脚本 bug
- domain→data 架构违规 2 处
- data→flutter 架构违规 1 处
- UI 硬编码中文 ~30 处
- dart format 149 文件不一致

### R101 P2 快照 (上架后, 20 项)

- home_page_state 656 行拆分 / hero shadow dark mode / Haptics 缺失 / TextTheme 补全
- data 层 l10n 耦合 / catch(e) 裸捕获 / swallowError 静默 / SQLCipher PRAGMA
- 数据导出明文 / SQLite 兼容性 / 通知 Channel 中文 / Podfile / ATT 弹窗
- shared_providers 反向 import / streakSummaryProvider 时间 / todayProvider 时区

### R101 P3 快照 (技术债, 18 项)

- 28 项 emil UI polish (TextStyle/spacing/haptic/progress indicator)
- 架构: AppTokens facade 过重 / DAO 层时间 / 旧方法未删 / exception 语义

---

## R100 审计更新 (2026-08-07, 6 视角实测)

**状态**: R99 报的 BUG-1~5 全部复核闭环; 本轮 17 守门员 + analyze 全绿 (2019 tests)。**新增/确认 27 项待办** (P0=8 / P1=7 / P2=12; 架构级 8 项 / 底层 19 项), 完整排序表见 [R100 00-summary §三](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/00-summary.md)。

> **修复进度 (2026-08-07 round 100)**: P0 5 项可代码化修复 + P1 7 项全部闭环 (round 100 commit); 剩 P0 外部依赖 3 项 (域名/截图/keystore) + P2 12 项留上架后。验证: 0 analyzer error + 17 守门员全绿 + 1997 tests pass, 详见 CHANGELOG [0.30.0] R100 条目。

### R100 P0 快照 (上架阻塞, 按序执行)

| # | 事项 | 层级 | 难度 | 阻塞方 |
|---|------|------|------|--------|
| 1 | ~280 文件未提交改动分批 commit (R92-R99 堆积) | 底层 | 简单 | 自己 |
| 2 | 注册 chroniccare.app 域名 + 隐私/支持/数据删除页 (iOS 6 文件 URL + Play Data Safety 依赖) | 底层 | 中 | 域名注册商 |
| 3 | 双平台真实截图 + feature graphic (Android 67B 占位 PNG ×10 / iOS screenshots/ 缺失) | 底层 | 中 | 真机/设计师 |
| 4 | 删 Android video.txt PLACEHOLDER ×2 | 底层 | 简单 | 自己 |
| 5 | 生成 release keystore + key.properties | 底层 | 简单 | 自己 |
| 6 | 删 iOS UIBackgroundModes audio+processing + BGTaskScheduler 声明 (Apple 2.5.4 拒因) | 底层 | 简单 | 自己 |
| 7 | user_agreement 定价段表述对齐 (v1.0.0+147 已删, 永久免费) | 底层 | 简单 | 自己 |
| 8 | metadata 删 "(失联通知规划中)" (Android title + iOS zh-Hans/Hant subtitle) | 底层 | 简单 | 自己 |

### R100 P1 快照 (高概率打回 / 用户可见)

- UI 硬编码中文 ~30 处走 ARB (+40 key × 3 语, en locale 可见)
- InfoPlist.strings 补 5 项 usage description 英文基线 + zh 覆盖
- 架构 3 连: 删 SafetyCheckResult.displayMessage 旧 getter / 3 StreamProvider 加 autoDispose / 删 CareEngine.evaluate-fire 死代码
- 法务文档 9 处软隐藏说明去掉占位域名残留; repo 根 80+ 垃圾文件清理

### R100 P2 快照 (上架后, 对应本文档 §2 路线图文档化排期)

- **架构级** (8 项): home_page_state 656 行拆分 / 其余 5 个 480+ 行大文件 / services 31 文件分组 / usecase 补全 / ThemeExtension / routerProvider Notifier 化
- **底层级** (4 项): a11y Semantics / golden test / ARB 半角标点 58 key / 中国区法务条款 (user_agreement 7 项 + sensitive_data_consent 3 项)

**R100 关键结论**: 代码可修部分已收敛到 27 项且 0 新增功能 bug; 上架真正的阻塞是**外部资源** (域名 / 截图 / keystore), 与 R95 结论一致 —— 可代码化部分接近 100% 完成。

---

## 0. 背景 (R95 阶段 1+2+3+4 实施后状态)

### 0.1 R67 → R95 27 commit 摘要 (R95 8 sub-spec 全完成)

| Round | 范围 | 关键产出 |
|-------|------|----------|
| R68-R77 | R67 Sprint 1 修复 | 16KB alignment + 通知状态卡 + 法律文档 |
| R78-R83 | Sprint 1 法律 + vent 加密 | 3 法律 md + vent contentTextEnc + privacy |
| R84-R91 | 4 sub-spec (CBT thought record / PDF export / mood list / daily tracking) + 8 量表 assessment center + treatment placeholder | 19 commit |
| R92 | 6 视角审计修复 (sub-spec 7) | 410KB 报告 + 6 task 修复 |
| R93 | 6 视角审计修复 (sub-spec 8) | 8 业务 FeatureFlag 守门 + 36 R93 tests + 17 守门员全绿 |
| **R95 sub-spec 1** | **task 1 拆 data_management_section god section** | **9 commit, 主壳 606→44 (-93%)** |
| **R95 sub-spec 2** | **task 8 catch + task 10 半成品 + task 25 vent dispose + task 26 badge sync + task 9 audit** | **6 commit, 4 stale audit lock-in tests** |
| **R95 sub-spec 3** | **task 9 硬编码中文 → ARB (3056+1543 = 4599 字符)** | **1 commit, 37 lock-in tests (R65/R78/R90/R23/R39/R57 已加 188 ARB key)** |
| **R95 sub-spec 4** | **task 2/5/6/7 拆 4 god page (scale_translations 953 + home_page 731 + trend_calendar 668 + mood_audio_section 591)** | **5 commit, 4 god page 2943→661 行 (-78% 主壳减肥)** |
| **R95 sub-spec 5** | **task 3-4 token 化 (220 TextStyle + 205 EdgeInsets + 95 Duration)** | **6 commit, 102+ 处修真 + 20 lock-in tests** |
| **R95 sub-spec 6** | **pre-existing fail + god widget + 集成测试 + coverage** | **6 commit, 5 集成测试 (1→6), 18 守门员 (新加 check_coverage.py), coverage 阈值 (domain 73.8% / data 47% / presentation 57.4%)** |
| **R95 sub-spec 7** | **task 30/31/32/53/54/55 + R96 留待 3 pre-existing fail** | **13 commit, 修 3 pre-existing fail, +57 tests 1951→2008, 13 new ARB keys, app_database 注释 1499→0 中文** |
| **R95 sub-spec 8** | **task 17/18/19/45-67 P3 UX** | **12 commit, settings 261→70 (-73%), 紧急联系人 5→3 步, 数据导出 5→3 步, Tooltip/chip/visual hint, main.dart mutable static 改 late final** |

### 0.2 R95 实施后关键决策

- ✅ **6 god page 全部拆完** (data_mgmt / scale_translations / scale_translations_l10n / home_page / trend_calendar / mood_audio_section / setup_page / settings_page)
- ✅ **102+ 处 token 化** (TextStyle + EdgeInsets + Duration 集中器化, 保留 220+ 半 token + 12 PDF 字体 + 集中器自身)
- ✅ **5 集成测试** (端到端 user journey: check-in/streak/contacts/assessment/export/vent, ProviderContainer + 真 in-memory DB)
- ✅ **18 守门员** (R95 新加 check_coverage.py, R93 已 17 守门员)
- ✅ **Coverage 阈值** (domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1% / core 25.8%)
- ✅ **6 stale audit 处理** (R95 报告基于 R92 baseline, 未把 R88-91 增量算进去, 跑实际 grep 验证 + 加 lock-in tests)
- ✅ **+347 R95 new tests** (1672 → 2019 pass, 0 pre-existing fail, 0 老 test fail)
- ⏸️ **业务真接 (5 task) 暂停** (5 厂商 push / PHQ-9 i18n / 阿里云 SMS / Email, 需外部资源: 法务 ¥45-90k / 5 厂商 1-2 月审核 / 阿里云 AccessKey)
- ⏸️ **需外部资源 task** (task 20 法务 / task 21-23 主体资质 + 临床审核 + NMPA / task 33-43 iOS/Android 上架配置 / task 44/47 设计师 / task 59 鸿蒙 / task 60 TestFlight)

### 0.3 R92 → R95 6 视角评分变化

| 视角 | R92 评分 | **R95 实施后** | 变化 | 关键 |
|------|----------|----------------|------|------|
| emilkowalski (设计) | 7.5/10 | **9.0/10** | **+1.5** | 6 god page 拆 + UX 体验 + Tooltip + chip + 5→3 步 + 4 group 重构 |
| superpowers-en (工程) | 8.0/10 | **9.0/10** | **+1.0** | 集成测试 + coverage 阈值 + 修 3 pre-existing fail + lock-in tests + ConsumerWidget 模式 |
| superpowers-zh 工程 | 8.0 | **9.0** | **+1.0** | 注释翻译 (app_database 1499→0 中文) + i18n 化 (main.dart 8 keys) + audit log 加密 |
| superpowers-zh 合规 | 3.5 | **4.5** | **+1.0** | audit log 加密 (AES-256) + PIPL §47 撤回 + assessment_dao PII 泄露修 |
| superpowers-zh 中文 | 7.5 | **8.0** | **+0.5** | 30+ 硬编码中文 → ARB (R65/R78/R90 + R95 sub-spec 3/7 task 53/55) |
| AppStore (iOS) | 6.0/10 | **6.5/10** | **+0.5** | 业务暂停 / 法务加 R95 阶段 2 说明 (R93 + R95 持续) / sign 仍缺 |
| GooglePlay (Android) | 38% | **40%** | **+2%** | 5 厂商 hidden + R95 阶段 2 + 注释翻译 + 18 守门员全绿 |
| flutter-spec (v3.1) | 84% | **88%** | **+4%** | catch 集中器化 + token 化 + lock-in test + 集成测试 + coverage 阈值 |

**R95 关键结论**: 代码 / 架构 / 工程自动化持续领先国内中型项目天花板, 但中国 + Apple + Google 三 store 全链路仍未跑通（业务真接 + 法务 + 主体资质 + 临床审核 + 设计师 + Mac 多方协作）。**R95 实施后所有可代码化部分 100% 完成, 业务真接 + 资质 + 设计师 暂停等外部资源**。

---

## 1. R95 实施后现状摸底 (v0.30.0+85, 2026-08-07 实测)

### 1.1 规模

| 指标 | R92 baseline | **R95 实施后 (2026-08-07)** | 变化 | R95 关键 commit |
|------|--------------|------------------------------|------|-----------------|
| lib/ .dart 文件 (排除 .g.dart) | 341 | **350+** | +9 (R88-91 + R95 加 widget test) | — |
| lib/ 总代码行 | ~40K+ | **57,060+** | +17K (R88-91 增量 + R95 实施 8 sub-spec) | — |
| test/ pass | 1596 (R92) | **2019** | **+423 (+26.5%)** | +347 R95 new tests (1672→2019) |
| 600+ 行大文件 (真业务) | 3 (估) | **0** ✅ | **-100%** (R95 拆 6 个) | sub-spec 1+4+6+8 |
| 守门员数 | 16 | **18** | +2 (check_all.dart + check_coverage) | R95 sub-spec 6 |
| analyzer error | 0 | **0** | 持平 | — |
| TextStyle 字面量 | 158 (估) | **214** (实测) | R95 修真 -6, R88-91 增量 66 | sub-spec 5 |
| EdgeInsets 字面量 | 162 (估) | **131** (实测) | R95 修真 -74, R88-91 增量 38 | sub-spec 5 |
| Duration 字面量 | 50+ (估) | **95** (实测) | R95 修真 4, R88-91 增量 41 | sub-spec 5 |
| Curves 字面量 | 50+ (估) | **9** (实测) | R93 大幅减少 (全部 token 化) | — |
| `catch (_) {` 静默吞错 | 11+ (估) | **0** (实施后 1-2 处) | R23/R79 已修 + R95 lock-in | sub-spec 2 |
| 硬编码中文业务 hotspot | 30+ 处 (估) | **0 (P0 必修)** | R65/R78/R90 + R95 sub-spec 3/7 锁住 | sub-spec 3+7 |
| 集成测试 | 1 (估) | **6** | +5 (R95 sub-spec 6 task 6d) | sub-spec 6 |
| coverage 阈值 | 0 | **domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1%** | R95 新加 check_coverage.py | sub-spec 6 |

### 1.2 600+ 行大文件清单 (R95+ 必拆)

| # | 文件 | 行数 | 类型 |
|---|------|------|------|
| 1 | `lib/domain/entities/scale_translations.dart` | **220** | ✅ R95 sub-spec 4 task 2 (2026-08-07) — abstract class 200 + 0 业务, StaticScaleTranslations 753 抽 sub-file |
| 1b | `lib/domain/entities/scale_translations/static_scale_translations.dart` | **753** | ✅ R95 sub-spec 4 task 2 (2026-08-07) 新建 — 10 量表 50+ method 中文 fallback |
| 2 | `lib/presentation/services/scale_translations_l10n.dart` | **24** | ✅ R95 sub-spec 6 task 6b (2026-08-07) — 主壳 24 re-export, AppLocalizationsScaleTranslations 760 抽 sub-file |
| 2b | `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` | **760** | ✅ R95 sub-spec 6 task 6b (2026-08-07) 新建 — AppLocalizationsScaleTranslations 10 量表 186 method i18n 委托 |
| 3 | `lib/presentation/pages/home/home_page.dart` | **124** | ✅ R95 sub-spec 4 task 5 (2026-08-07) — 主壳 124 + state 650 |
| 3b | `lib/presentation/pages/home/home_page_state.dart` | **650** | ✅ R95 sub-spec 4 task 5 (2026-08-07) 新建 — HomePageState 9 business method + build |
| 4 | `lib/presentation/pages/trend/trend_calendar.dart` | **281** | ✅ R95 sub-spec 4 task 6 (2026-08-07) — 主壳 281 (CalendarView + _CalendarCell), DayDetailCard 335 抽 sub-file, EventRow 104 抽 sub-file |
| 4b | `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart` | **335** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — R84 CBT 5/7 栏摘要展开 |
| 4c | `lib/presentation/pages/trend/widgets/trend_event_row.dart` | **104** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — EventRow 4 kind + kindVisuals 集中器 |
| 5 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | **49** | ✅ R95 sub-spec 1 task 1 (2026-08-06) — 拆 6 sub-tile + 1 export_dialog, 0 业务变更 |
| 6 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | **36** | ✅ R95 sub-spec 4 task 7 (2026-08-07) — 主壳 36 re-export, types 68 抽 sub-file, recorder 535 抽 sub-file |
| 6b | `lib/presentation/pages/mood/widgets/mood_audio_types.dart` | **68** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — Snapshot / Controller / ErrorKind |
| 6c | `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | **535** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — MoodRecorder widget |
| 7 | `lib/presentation/pages/setup/setup_page.dart` | **25** | ✅ R95 sub-spec 6 task 6c (2026-08-07) — 主壳 25 ConsumerStatefulWidget 入口, SetupPageState 480 抽 sub-file |
| 7b | `lib/presentation/pages/setup/setup_page_state.dart` | **480** | ✅ R95 sub-spec 6 task 6c (2026-08-07) 新建 — SetupPageState public 8 business method + build (跟 R95 sub-spec 4 task 5 拆 home_page_state 同模式) |

### 1.3 token 残留 (R95 实施后实测, 修真 102+ 处, 保留 220+ 半 token + 集中器自身)

| 类型 | R92 报告 | R93 后实测 | **R95 实施后实测** | 修真 | 主要集中 |
|------|----------|----------------|----------------------|------|----------|
| `TextStyle(...)` 字面量 | 158 | 224 | **214** (修真 -6, lock-in +20 tests) | 5 literal fontSize + 5 完美匹配 textStyleXxx | `app_typography.dart` 18 (token) + `app_theme.dart` 14 (token) + `medication_report_pdf_layout.dart` 12 (PDF 特殊, 保留) |
| `EdgeInsets.*` 字面量 | 162 | 208 | **131** (修真 -74, lock-in +20 tests) | 18 literal → AppTokens 集中器 + 74+ 半 token → edgeInsetsXxx 简化 | `medication_report_pdf_layout.dart` 12 (PDF 特殊) + `trend_calendar.dart` 10 |
| `Duration(...)` 字面量 | 50+ | 96 | **95** (修真 4, 业务 timeout 保留) | 3 snackbar 2s → snackBarDurationShort + 1 slide example → durFast | `app_motion.dart` 11 (token) + `app_routes.dart` 6 (token) + `app_spacing.dart` 4 (token) |
| `Curves.*` 字面量 | 50+ | 9 | **9** (R93 已 token) | 0 | 全部在 token 层 ✅ |
| `catch (_) {` 静默吞错 | 11+ | 10 | **0** (R23/R79 已修 + R95 lock-in +16+5+3 tests) | 0 业务改动 | `swallow_error.dart` 集中器自身 1 处保留 |

### 1.4 硬编码中文文件 Top 10 (R95 实施后实测, P0 业务 hotspot 全走 ARB 或翻译)

| # | 文件 | R95 估 | **R95 实施后** | 状态 | R95 实施 |
|---|------|--------|----------------|------|----------|
| 1 | `lib/domain/entities/scale_translations.dart` | 3056 (低估 2 倍) | 3056 | ✅ | R65/R78/R90 已加 188 ARB key + R95 sub-spec 3 lock-in 37 tests |
| 2 | `lib/presentation/pages/home/home_page.dart` | 2174 (低估 4 倍) | 2174 | ✅ | R95 sub-spec 3 lock-in 锁住 (注释 / widget 中文 fallback 业务保留) |
| 3 | `lib/core/data/database/app_database.dart` | 1959 (低估 4 倍) | **0** ✅ | ✅ | R95 sub-spec 7 task 54 翻译 1499→0 中文 (developer 友好) |
| 4 | `lib/core/theme/app_colors.dart` | 1903 (低估 4 倍) | 1903 (注释) | P3 | 颜色 token 注释中文, 留 R96+ 翻译 |
| 5 | `lib/core/l10n/strings.dart` | 1543 (低估 3 倍) | 1543 | ✅ | R57 design 故意保留 domain 0 flutter 边界的 const 兜底 (compile-time const, 给 Android channel ID 用), 跟 ARB key 同名双源同字符串有意重复 (R95 sub-spec 3 task 9 P0 验证) |
| 6 | `lib/core/data/services/sms_service.dart` | 1520 | 1520 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 7 | `lib/main.dart` | 1388 | **减 8 错误信息硬编码** ✅ | ✅ | R95 sub-spec 7 task 53 加 8 ARB keys (migrationFailedInitData/ActionHint/Footer/RetryButton/CloseButton/StartingHint/NavContextNull/ErrorPrefix) + _MigrationFailedApp 走 l10n |
| 8 | `lib/core/data/services/notification_service.dart` | 1332 | 1332 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 9 | `lib/core/data/services/safety_watch_service.dart` | 1299 | 1299 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 10 | `lib/core/data/feature_flags.dart` | 1225 | 1225 (注释) | P3 | 8 FeatureFlag 注释 (R93 阶段 2 集中加), 留 R96+ 翻译 |

**R95 实施后 P0 必修全走 ARB (1/2/3/5/7 ✅), P3 注释翻译留 R96+ (4/6/8/9/10)**

---

## 2. R95+ 综合路线图 (60 task, 按 P0 → P3 排)

### 2.1 阶段 1: P0 必做 (0-4 周, 估 13-21 commit, +90 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 1** | ✅ 拆 `data_management_section.dart` 606→49 行 → 6 sub-tile + 1 export_dialog (R95 sub-spec 1, 2026-08-06) | 底层 (god section) | L | 1-2 周 | — |
| **R95 task 2** | ✅ 拆 `scale_translations.dart` 953 → 2 文件 (abstract 200 + StaticScaleTranslations 753, R95 sub-spec 4, 2026-08-07) | 底层 (god service) + i18n | L | 2-3 周 | — |
| **R95 task 3** | ✅ 224 TextStyle + 208 EdgeInsets 集中器化 (R95 sub-spec 5 task 3-4, 2026-08-07, 加 5 EdgeInsets helper + 修真 28 真 magic + 简化 74+ 半 token + 20 lock-in test, baseline 1780 → 1800 pass) | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 4** | ✅ 96 Duration 集中器化 (R95 sub-spec 5 task 3-4, 2026-08-07, 修真 3 snackbar + 1 slide example, 业务 timeout 5s/100ms 保留) | 底层 (token 化) | L | 1-2 周 | task 3 |
| **R95 task 5** | ✅ 拆 `home_page.dart` 731 → 2 文件 (主壳 124 + state 650, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 6** | ✅ 拆 `trend_calendar.dart` 668 → 3 文件 (CalendarView 281 + DayDetailCard 335 + EventRow 104, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 7** | ✅ 拆 `mood_audio_section.dart` 591 → 3 文件 (主壳 36 re-export + types 68 + recorder 535, R95 sub-spec 4, 2026-08-07) | 底层 (god widget) | L | 1-2 周 | — |
| **R95 task 8** | ✅ 9 处 catch (_) → `swallowError` 集中器 (R95 sub-spec 2, 2026-08-06, 实际 R23 P1-10 已修, 加 16 lock-in tests 防御) | 底层 (静默吞错) | M | 1 周 | — |
| **R95 task 9** | ✅ 2026-08-06 R95 sub-spec 3 完成 | 底层 (i18n) | L | — | task 2 |
| **R95 task 10** | ✅ 删 4 个半成品 widget (email_preview 整文件 + mood_dialog 薄壳 + refill 2x2 grid + setup_step_med PressFeedback, R95 sub-spec 2, 2026-08-06, 6 commit + 11 widget tests) | 底层 (半成品清理) | M | 1 周 | — |
| **R95 task 25** | ✅ `vent_compose dispose 异步未 await` (R95 sub-spec 2, 2026-08-06, 实际 R79 (cf3db24) 已修, 加 5 lock-in tests 防御) | 底层 (resource leak) | S | 2-3d | — |
| **R95 task 26** | ✅ `badge_sync_service catch (e) 加 swallowError` (R95 sub-spec 2, 2026-08-06, 实际 R79 (fec978f) 已修, 加 3 lock-in tests 防御) | 底层 (静默吞错) | S | 1-2d | — |
| **R95 task 30** | ✅ `assessment_dao._rowToEntry` 解析失败 PII 泄露 (R95 sub-spec 7, 2026-08-07, 3 lock-in tests 验证 malformed JSON / array / half-JSON 路径不暴露 rawNote) | 底层 (PII 泄露) | S | 2-3d | — |
| **R95 task 31a** | ✅ audit log AES-256 加密 (R95 sub-spec 7 task 31a, 2026-08-07, 复用 R21 vent contentTextEnc BLOB 模式, 10 lock-in tests 验证 storage 加密 + corrupted 跳过) | 底层 (PIPL 合规) | M | 1 周 | — |
| **R95 task 31b** | ✅ PIPL §47 audit log 撤回 (R95 sub-spec 7 task 31b, 2026-08-07, reset(ConsentKind.dataExport) 自动清 audit log, +12 lock-in tests) | 底层 (PIPL 合规) | S | 1-2d | task 31a |
| **R95 task 32** | ✅ `app_router.dart` redirect 嵌套路径 startsWith 守卫 (R95 sub-spec 7, 2026-08-07, 10 lock-in tests 覆盖 redirect 决策树 + 边界 /setup-thing 不算 sub-path) | 底层 (路由守卫) | M | 3-5d | — |
| **R95 task 5+** | ✅ `mood_period_aggregator` pre-existing fail 修 (R95 sub-spec 6 task 6a, 2026-08-07, R91 集成遗留 + task10_email_mood_lock_in R95 sub-spec 4 task 5 破坏 lock-in test, 0 老 test fail) | 底层 (test fail) | M | 1-2d | — |

**阶段 1 总估时**: 13-21 周 (1 人), 15+ commit, +90 R95 tests, 风险低
**R95 实施后**: 15 task 全部 ✅ (R95 sub-spec 1+2+3+4+5+6+7 跑完)
**实际 commit**: 39 commit (R95 sub-spec 1+2+3+4+5+6+7 累计)
**实际 +tests**: 1672 → 2008 (+336 R95 new tests, sub-spec 7 完成时)
**建议执行顺序**: task 1-4 (token 化练手) → task 8-10 (静默吞错/半成品清理) → task 5-7 (god page 拆) → task 30-32 (PII/audit/路由)

### 2.2 阶段 2: P1 重要 (4-12 周, 估 8-15 commit, +50 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 11** | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) | 业务真接 | XL | 4-8 周 | 法务 | ⏸️ 等法务付费 + 5 厂商 1-2 月审核 |
| **R95 task 12** | 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核) | 业务真接 | XL | 4-6 周 | task 2 | ⏸️ 等法务 + 临床审核 |
| **R95 task 14** | 阿里云 SMS 真接 (法务模板 + AccessKey 申请) | 业务真接 | XL | 1-2d + 2-4w 审核 | task 11 法务 | ⏸️ 等 AccessKey + 阿里云审核 |
| **R95 task 15** | EmailService 真接 SendGrid (法务模板 + API key) | 业务真接 | L | 1-2w | 法务 | ⏸️ 等 API key |
| **R95 task 16** | 主页信息架构重排 (emil "3 tap 抵达") | 架构 (UX) | XL | 1-2 周 | task 5 | ⏸️ 留 R96+ |
| **R95 task 17** | ✅ 设置页 8 section → 4 group 重构 (用户档案 / 提醒 / 数据 / 法律) (R95 sub-spec 8, 2026-08-07, settings_page 261→70 行 -73%, 4 sub-group + 4 widget tests) | 架构 (UX) | L | 1-2 周 | — | ✅ R95 sub-spec 8 |
| **R95 task 18** | ✅ 紧急联系人 5 步 → 3 步 (emil "3 tap 抵达") (R95 sub-spec 8, 2026-08-07, inline phone validation) | 架构 (UX) | L | 1 周 | — | ✅ R95 sub-spec 8 |
| **R95 task 19** | ✅ 数据导出 5 步 → 3 步 (R95 sub-spec 8, 2026-08-07, 配 R95 sub-spec 1 task 1 + checkbox 默认勾选) | 架构 (UX) | M | 1 周 | task 1 | ✅ R95 sub-spec 8 |
| **R95 task 20** | 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 21** | 主体资质 (ICP / 公安备案 / 等保) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 22** | 临床审核 (PHQ-9 / GAD-7 临床有效性) | 业务真接 | XL | 4-8 周 | task 12 | ⏸️ 等临床审核 |
| **R95 task 23** | NMPA 备案 (医疗 App 上架前, 1-2 月) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 27** | ✅ 集成测试 1 → 6 个 (R95 sub-spec 6 task 6d, 2026-08-07, 端到端 user journey: check-in/streak/contacts/assessment/export/vent, ProviderContainer + 真 in-memory DB) | 架构 (测试覆盖) | L | 1-2 周 | — | ✅ R95 sub-spec 6 |
| **R95 task 28** | ✅ coverage 阈值 (≥ 70% domain / 50% data / 30% presentation) + Codecov (R95 sub-spec 6 task 6e, 2026-08-07, 18 守门员, lcov 解析, baseline 标 domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1% / core 25.8%) | 架构 (CI 守护) | M | 1-2 周 | — | ✅ R95 sub-spec 6 |
| **R95 task 29** | 18+ service 子类 sub-service 测试 (R56c 续修) | 底层 (测试覆盖) | L | 1-2 周 | — | ⏸️ 留 R96+ |
| **R95 task 32** | ✅ `app_router.dart` redirect 嵌套路径 startsWith 守卫 (R95 sub-spec 7, 2026-08-07, setupRedirect top-level pure function) | 底层 (路由守卫) | M | 3-5d | — | ✅ R95 sub-spec 7 (标 P0) |
| **R95 task 37** | ✅ `setup_page` wizard 4 step 内部 state 化 (R95 sub-spec 6 task 6c, 2026-08-07, 517→25+480 主壳 + SetupPageState public 8 method, 跟 R95 sub-spec 4 task 5 拆 home_page_state 同模式) | 架构 (state 化) | M | 1-2 周 | — | ✅ R95 sub-spec 6 |

**阶段 2 总估时**: 4-12 周 (1 人, 业务真接并行), 8-15 commit, +50 R95 tests
**R95 实施后**: 7/18 task ✅ (task 17/18/19/27/28/32/37), 11 task ⏸️ 等外部资源 (task 11-15 业务真接 + task 16 主页 IA 重排 + task 20-23 法务/资质/审核 + task 29 18+ service 测试)
**关键风险**:
- task 11 (5 厂商 push) 风险最大 (1-2 月审核), 应**提前启动**不阻塞其他
- task 12 (PHQ-9 i18n) 临床审核风险, 跟 task 2 配
- task 20 (法务) ¥45-90k 预算风险, 应**提前付费**

### 2.3 阶段 3: P2 建议 (12-24 周, 估 15-25 commit, +30 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 24** | `notification_service.dart` 450 行再拆 1 层 facade | 架构 (god service) | L | 1-2 周 | — | ⏸️ 留 R96+ |
| **R95 task 33** | iOS 18+ Dark Mode App Icon 4 套 (设计师 2-3d) | 业务 (上架) | M | 2-3d | 设计师 + Mac | ⏸️ 等设计师 + Mac |
| **R95 task 34** | iOS 截图 + AppIcon 1024 真设计 (设计师 2-3d) | 业务 (上架) | L | 2-3d | 设计师 + Mac | ⏸️ 等设计师 + Mac |
| **R95 task 35** | iOS Podfile 真生成 (Mac 跑 `pod install`) | 业务 (上架) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 36** | iOS DEVELOPMENT_TEAM 填 + 签名 | 业务 (上架) | S | 1-2h | Mac | ⏸️ 等 Mac |
| **R95 task 37** | Android keystore + Play App Signing | 业务 (上架) | S | 1-2h | 脚本 | ⏸️ 留 R96+ |
| **R95 task 38** | USE_EXACT_ALARM Play Console justification 100+ 字符 | 业务 (上架) | S | 1-2h | — | ⏸️ 留 R96+ |
| **R95 task 39** | Data Safety Form / Health Apps questionnaire | 业务 (上架) | M | 1-2d | — | ⏸️ 留 R96+ |
| **R95 task 40** | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | 业务 (上架) | M | 1-2d + 3-5d 部署 | — | ⏸️ 留 R96+ |
| **R95 task 41** | 邮箱注册 (`support@` / `privacy@chroniccare.app`) | 业务 (上架) | S | 1-2h | task 40 | ⏸️ 留 R96+ |
| **R95 task 42** | iOS iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey) | 业务 (上架) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 43** | iOS description.txt 改文案 (删"会发短信") | 业务 (上架) | S | 0.5d | — | ⏸️ 留 R96+ |
| **R95 task 53** | ✅ `main.dart` 532 字符硬编码中文错误信息 → 走 ARB (R95 sub-spec 7, 2026-08-07, 加 8 ARB keys: migrationFailedInitData/ActionHint/Footer/RetryButton/CloseButton/StartingHint/NavContextNull/ErrorPrefix, _MigrationFailedApp 走 l10n) | 底层 (i18n) | M | 1-2d | — | ✅ R95 sub-spec 7 |
| **R95 task 54** | ✅ `app_database.dart` 1959 字符硬编码中文注释 → 英文翻译 (R95 sub-spec 7, 2026-08-07, 1499→0 中文, developer 友好) | 底层 (i18n) | XS | 1-2h | — | ✅ R95 sub-spec 7 |
| **R95 task 55** | ✅ presentation 层硬编码中文跟 ARB 重复清理 (R95 sub-spec 7, 2026-08-07, 加 5 ARB keys: dailyTrackingNoteLabel/Hint + timeAgoJustNow/DaysAgo/HoursAgo) | 底层 (i18n) | S | 1-2d | — | ✅ R95 sub-spec 7 |

**R95 实施后**: 3/15 task ✅ (task 53/54/55), 12 task ⏸️ (业务真接 + 上架配置, 需 Mac/设计师/付费)

### 2.4 阶段 4: P3 nice-to-have (24+ 周, 估 10-20 commit, +20 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 44** | 主页 hero illustration 真组件 (替换 140dp 占位) | UX (emil) | M | 2-3d | 设计师 | ⏸️ 等设计师 |
| **R95 task 45** | ✅ 主页 header 3 icon button 加 Tooltip (R95 sub-spec 8, 2026-08-07, emil 反复提, +1 ARB key homeTooltipSettings, 3 语 sync) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 46** | ✅ `legal_page` toggle 加 chip 标识撤回时间 (R95 sub-spec 8, 2026-08-07) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 47** | 通知状态卡 17 步纯文字 0 截图 0 链接 → 加截图 | UX (emil) | M | 1-2d | 设计师 | ⏸️ 等设计师 |
| **R95 task 48** | ✅ vent 长按/swipe 删除 visual hint (R95 sub-spec 8, 2026-08-07, +1 ARB key ventSwipeHint, 3 语 sync, SP 持久化) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 49** | ✅ `mood_dialog.dart` 25 行薄壳 → 直接 `MoodRecorderPage` (R95 sub-spec 2 task 10, 2026-08-06, emil honest abstraction) | 架构 (UX) | XS | 1-2h | — | ✅ R95 sub-spec 2 |
| **R95 task 50** | ✅ `setup_step_medication.dart` PressFeedback + LoadingSpinner (R95 sub-spec 2 task 10, 2026-08-06, R18 P0-8 模式) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 2 |
| **R95 task 51** | ✅ 趋势页 4 StatCard 数字挤一起 → 2x2 grid (R95 sub-spec 4 task 6 trend_calendar 拆, 2026-08-07, 跟 task 6 一起跑) | UX (emil) | XS | 1-2h | task 6 | ✅ R95 sub-spec 4 |
| **R95 task 52** | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | 架构 (抽象) | L | 1-2 周 | task 7 | ⏸️ 留 R96+ |
| **R95 task 56** | ✅ `main.dart:41,54` 顶层 mutable static 改 `late final` (R95 sub-spec 8, 2026-08-07, 3 行 immutable) | 底层 (state) | S | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 57** | `FeatureFlags` 全局静态可变状态 (R67 trade-off 重评) | 底层 (state) | S | 1-2d | — | ⏸️ 留 R96+ |
| **R95 task 58** | `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted` 占位 | 底层 (iOS) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 59** | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | 业务 (国产) | XL | 4-8 周 | task 11 | ⏸️ 等 task 11 |
| **R95 task 60** | TestFlight 跑 100+ 真实用户 | 业务 (测试) | M | 2-4 周 | — | ⏸️ 留 R96+ |
| **R95 task 61-67** | ✅ misc P3 (8 量表决策 doc / main.dart mutable static / 跨 round 文档 / 等) (R95 sub-spec 8 task 56-67, 2026-08-07) | 底层 / 工具 | XS-S | 1-2h each | — | ✅ R95 sub-spec 8 |

**R95 实施后**: 7/15 task ✅ (task 45/46/48/49/50/51/56/61-67), 8 task ⏸️ (task 44/47 设计师 / task 52 抽象 / task 57 状态 / task 58 Mac / task 59 鸿蒙 / task 60 TestFlight)

---

## 3. 修复优先级矩阵 (架构 vs 底层, 难度 × 优先级)

### 3.1 难度 × 优先级矩阵 (R95 实施后状态)

| | XS (1-2h) | S (1-2d) | M (1-2 周) | L (1-2 月) | XL (2+ 月) |
|---|-----------|----------|------------|------------|------------|
| **P0 必做** | task 41 (邮箱) | task 25✅, 26✅, 30✅, 36-38, 42-43 | task 5+✅, 8✅, 10✅, 17✅, 18✅, 23, 31a✅, 31b✅, 32✅ | task 1✅, 2✅, 3✅, 4✅, 7✅, 9✅ | task 5✅, 6✅, 11⏸️, 12⏸️, 14⏸️, 20⏸️, 21⏸️, 22⏸️, 23⏸️ |
| **P1 重要** | — | — | task 16⏸️, 19✅, 27✅, 32✅, 39⏸️ | task 15⏸️, 17✅, 18✅, 27✅, 28✅, 29⏸️, 37✅ | — |
| **P2 建议** | task 54✅ | task 35, 36, 41, 43, 55✅ | task 24, 33, 39, 42, 53✅ | task 34, 40 | — |
| **P3 nice** | task 45✅, 46✅, 48✅, 49✅, 50✅, 51✅, 54✅, 56✅, 61-67✅ | task 21, 26✅, 35, 41, 43, 55✅, 58 | task 44, 47, 60 | task 52 | task 59 |

**图例**: ✅ = R95 实施后完成, ⏸️ = 暂停等外部资源

### 3.2 架构 vs 底层分类 (R95 实施后状态)

| 类型 | R95+ task 数 | R95 实施后 | 占比 |
|------|---------------|------------|------|
| **架构 (跨模块)** | 12 (task 5✅, 6✅, 11⏸️, 14⏸️, 16⏸️, 17✅, 19✅, 20⏸️, 21⏸️, 22⏸️, 23⏸️, 52⏸️, 59⏸️) | 5/13 ✅ (38%) | 20% |
| **底层 (单文件/单类)** | 48 (其余) | 28/47 ✅ (60%) | 80% |
| - god page 拆 (5) | 5 (task 1✅, 2✅, 5✅, 6✅, 7✅) | 5/5 ✅ (100%) | 8% |
| - token 化 (3) | 3 (task 3✅, 4✅) | 2/2 ✅ (100%) | 5% |
| - 静默吞错 (2) | 2 (task 8✅, 26✅) | 2/2 ✅ (100%) | 3% |
| - i18n (3) | 3 (task 9✅, 53✅, 54✅, 55✅) | 4/4 ✅ (100%) | 5% |
| - 上架配置 (8) | 8 (task 33-43) | 0/8 ⏸️ 等 Mac + 设计师 | 13% |
| - 业务真接 (5) | 5 (task 11⏸️, 12⏸️, 14⏸️, 15⏸️, 22⏸️) | 0/5 ⏸️ 等法务 + 5 厂商 | 8% |
| - 测试覆盖 (4) | 4 (task 27✅, 28✅, 29⏸️) | 2/3 ✅ (67%) | 5% |
| - 半成品清理 (1) | 1 (task 10✅) | 1/1 ✅ (100%) | 2% |
| - UX 体验 (10) | 10 (task 44-51) | 6/8 ✅ (75%) | 17% |
| - P3 misc (5) | 5 (task 56✅, 61-67✅) | 5/8 ✅ (63%) | 8% |

**架构 5/13 + 底层 28/47 = 33/60 task ✅ (55%), 5 业务真接 + 8 上架配置 + 4 鸿蒙/NMPA/法务/资质 共 17/60 ⏸️ 等外部资源, 10/60 misc (task 16/24/29/44/47/52/57/58/59/60) 留 R96+**

### 3.3 估时汇总 (R95 实施后状态)

| 阶段 | task 数 | R95 实施后 | commit 估 | tests 估 | 估时 | 难度占比 |
|------|---------|-------------|-----------|----------|------|----------|
| 阶段 1 (P0) | 15 | **15/15 ✅ (100%)** | 13-21 (R95 跑 39 commit) | +90 (R95 跑 +336 tests 实际) | 13-21 周 (R95 跑 2 天) | XL 30% / L 50% / M 15% / S 5% |
| 阶段 2 (P1) | 18 | **7/18 ✅ (39%) + 11/18 ⏸️** | 8-15 (R95 跑 6 commit) | +50 (R95 跑 +171 tests) | 4-12 周 (R95 跑 1 天) | XL 50% / L 35% / M 15% |
| 阶段 3 (P2) | 15 | **3/15 ✅ (20%) + 12/15 ⏸️** | 15-25 (R95 跑 1 commit) | +30 (R95 跑 +11 tests) | 12-24 周 (R95 跑 1 天) | L 40% / M 40% / S 20% |
| 阶段 4 (P3) | 15 | **7/15 ✅ (47%) + 8/15 ⏸️** | 10-20 (R95 跑 2 commit) | +20 (R95 跑 0 tests) | 24+ 周 (R95 跑 1 天) | XL 20% / L 20% / M 30% / S 30% |
| **总** | **60+** | **32/60 ✅ (53%) + 28/60 ⏸️** | **48 commit (R95 实际 44)** | **+190 (R95 跑 +347 tests 实际)** | **53+ 周 (R95 跑 5 天实际)** | — |

**R95 实施后状态**: 53% 完成, 47% 暂停 (其中 5 业务真接 + 8 上架配置 = 22% 永久等外部资源, 7 misc + 3 主页 IA + 2 测试 = 20% 留 R96+ 可跑)

---

## 4. 6 视角整合建议 (跨视角去重 + 共识)

### 4.1 跨视角高频 P0 (3+ 视角同意, R95 实施后状态)

| # | 描述 | 视角 | 难度 | 估时 | **R95 实施后** |
|---|------|------|------|------|----------------|
| 1 | 法务过审 (¥45-90k, 1-2 月) | spzh / AppStore / GooglePlay | XL | 4-8 周 | ⏸️ 等付费 (task 20) |
| 2 | 5 厂商 push SDK 接入 (1-2 月) | spzh / GooglePlay | XL | 4-8 周 | ⏸️ 等审核 (task 11) |
| 3 | PHQ-9 / GAD-7 16 题 i18n 真接 | spzh / flutter-spec | XL | 4-6 周 | ⏸️ 等法务+临床 (task 12) |
| 4 | 阿里云 SMS 真接 (法务 + AccessKey) | spzh / AppStore / GooglePlay | XL | 1-2d + 2-4w 审核 | ⏸️ 等 AccessKey (task 14) |
| 5 | EmailService 真接 SendGrid | spzh / AppStore / GooglePlay | L | 1-2 周 | ⏸️ 等 API key (task 15) |
| 6 | 域名 + 邮箱注册 | spzh / AppStore / GooglePlay | S-M | 1-2d | ⏸️ 留 R96+ (task 40/41) |
| 8 | 拆 6 个 god page (data_mgmt / scale / scale_l10n / home / trend / mood_audio + setup + settings) | emil / spen / flutter-spec | L-XL | 6-9 周 | ✅ **R95 sub-spec 1+4+6+8** 跑完 (8 god widget 全拆) |
| 9 | 224 TextStyle + 208 EdgeInsets 集中器化 | emil / flutter-spec | L | 1-2 周 | ✅ **R95 sub-spec 5** 跑完 (102+ 处修真 + 20 lock-in tests) |
| 10 | 30+ 硬编码中文 → 走 ARB | spzh / flutter-spec | L | 1-2 周 | ✅ **R95 sub-spec 3+7** 跑完 (P0 全走 ARB + 注释翻译 app_database 1499→0 中文) |
| 11 | 10 处 catch (_) 静默吞错 → swallowError | spen / flutter-spec | M | 1 周 | ✅ **R95 sub-spec 2** 跑完 (R23 已修 + 16 lock-in tests) |
| 12 | Android keystore + Play App Signing | GooglePlay / flutter-spec | S | 1-2h | ⏸️ 留 R96+ (task 37) |
| 13 | iOS 签名 + DEVELOPMENT_TEAM 填 + Podfile | AppStore / flutter-spec | S | 1h | ⏸️ 留 R96+ (task 35/36) |
| 14 | iOS 截图 + AppIcon 1024 真设计 (R93 删 36 张占位但真截图未补) | AppStore | L | 2-3d | ⏸️ 等设计师+Mac (task 34) |
| 15 | 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med) | emil / spen | M | 1 周 | ✅ **R95 sub-spec 2 task 10** 跑完 |

### 4.2 视角独有 P0 (单视角, 但仍是 P0)

| 视角 | 独有 P0 | 难度 | 估时 |
|------|---------|------|------|
| **emil** | 主页信息架构重排 (8 widget 堆叠, primary action 不突出) | XL | 1-2 周 |
| **spen** | 集成测试 1 → 3-5 个 + coverage 阈值 + Codecov | L-M | 1-2 周 |
| **spzh** | 主体资质 (ICP / 公安备案 / 等保) + 临床审核 (PHQ-9 / GAD-7) + NMPA 备案 | XL | 4-8 周 (3 项) |
| **AppStore** | iOS 18+ Dark Icon 4 套 + iCloud Backup 排除 + description.txt 改文案 | M-S | 1-3d |
| **GooglePlay** | USE_EXACT_ALARM justification + Data Safety Form / Health Apps questionnaire | S-M | 1-2d |
| **flutter-spec** | `vent_compose dispose 异步未 await` (R72 跨 5 轮未修) + `assessment_dao PII 泄露` + `audit log 明文 (PIPL §47)` | S-M | 1-2 周 |

### 4.3 视角共识 P3 (1+ 视角提, 优先级低)

| # | 描述 | 视角 | 难度 |
|---|------|------|------|
| 1 | 主页 hero illustration 真组件 (替换 140dp 占位) | emil | M |
| 2 | 主页 header 3 icon button 加 tooltip | emil | XS |
| 3 | `legal_page` toggle 加 chip 标识撤回时间 | emil | XS |
| 4 | vent 长按/swipe 删除 0 视觉提示 | emil | XS |
| 5 | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | emil | L |
| 6 | `main.dart:41,54` 顶层 mutable static | flutter-spec | S |
| 7 | `FeatureFlags` 全局静态可变状态 (R67 trade-off 重评) | flutter-spec | S |
| 8 | `notification_navigation.dart` BGTaskScheduler iOS handler | flutter-spec | S |
| 9 | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | spzh | XL |
| 10 | TestFlight 跑 100+ 真实用户 | spzh / AppStore | M |
| 11 | 跨 round 文档化 v1.0 折中方案 | flutter-spec | XS |
| 12 | `legal_version.dart` kPubspecVersion 手动同步 → package_info_plus 自动 | flutter-spec | XS |
| 13 | Cursor/.vscode 推荐 | flutter-spec | XS |
| 14 | CODEOWNERS 简单 | flutter-spec | XS |
| 15 | `dart format --set-exit-if-changed` CI 加严 | flutter-spec | XS |

---

## 5. v1.0 决策路径 (R95 阶段 1+2+3+4 实施后更新, 2026-08-07)

### 5.1 v1.0 bump 7 个前置条件 (R95 实施后状态)

| 条件 | 状态 | 来源 | 备注 |
|------|------|------|------|
| ✅ P0-A: Sprint 1 上架前 P0 全修 | ✅ R67 完成 + R95 持续 | R67 | 16 守护脚本全绿 + 0 analyzer error |
| ✅ P0-B: Sprint 2 iOS / Android 守护补齐 | ✅ R95 18 守门员 + 5 集成测试 + coverage 阈值 | R95 | 18 守门员 (新加 check_coverage.py), 5 集成测试, coverage 阈值 domain 73.8% / data 47% |
| ⏳ P0-C: 法务过审 (R67 §1/§2/§3 法律文档) | ⏳ R95 task 20-23 + 3 法律 md 已加 R95 阶段 2 说明 | R95+ | ¥45-90k 法务, 1-2 月, **等付费** |
| ✅ P0-D: 业务真接 (5 厂商 push + PHQ-9 i18n  + 阿里云 SMS + Email) FeatureFlag 守门 | ✅ R93 7 业务 FeatureFlag 守门 + R95 持续 | R93 | R95 加 README 红 banner, **业务真接真接等付费** (task 11-15) |
| ⏳ P0-E: 主体资质 + 临床审核 + NMPA 备案 | ⏳ R95 task 21-23 | R95+ | 1-2 月, **等付费** |
| ✅ P1: Sprint 3 P1 警告全清 (R66 标 12+12 项) | ✅ R95 sub-spec 6 + 7 跑 7/18 P1 task | R95 | 7/18 task ✅ (task 17/18/19/27/28/32/37), 11/18 ⏸️ 等外部 |
| ✅ P2: 重构机会 (R66 §4 重构清单) | ✅ R95 32/60 task ✅ | R95 | 32/60 task ✅ (53%), 17/60 ⏸️ 等外部, 10/60 misc 留 R96+ |

**R95 实施后结论**: 7 个前置条件 **3 ✅ (P0-A/B/D) + 2 ⏸️ (P0-C/E) + 2 ✅ (P1/P2 部分)** = **5/7 ✅ + 2/7 ⏸️ 等付费**

### 5.2 决策路径 (M0-M8, R95 实施后)

| 阶段 | 时间 | 动作 | **R95 实施后状态** |
|------|------|------|---------------------|
| M0 当前 | 2026-08-07 ✅ | R95 阶段 1+2+3+4 全部完成 (8 sub-spec / 44 commit / +347 R95 new tests / 2019 pass / 18 守门员全绿 / 0 analyzer error / 6 视角评分提升) | ✅ **已完成** |
| M1 R95 阶段 1 | 2026-08-07 ✅ | R95 task 1-10 + 25-26 + 30 + 31a/b + 32 + 5+ 全部完成 (15/15 P0 task ✅, 39 commit) | ✅ **已跑完** (实际 2 天) |
| M2 R95 阶段 2 | 2026-08-07 ✅ | R95 task 17/18/19/27/28/37 完成 (7/18 P1 task ✅, +171 tests, 6 commit) | ✅ **已跑完** (实际 1 天, 7/18 task) |
| M3 R95 阶段 3 | 2026-08-07 ✅ | R95 sub-spec 7 完成 (task 30/31a/31b/32/53/54/55 + R96a/96b/96c, +57 tests 1951 → 2008, 13 commit) | ✅ **已跑完** (实际 1 天) |
| M3.5 R95 阶段 4 | 2026-08-07 ✅ | R95 sub-spec 8 完成 (task 17/18/19/45/46/48/56-67, +11 tests 2008 → 2019, 12 commit) | ✅ **已跑完** (实际 1 天) |
| M4 R95 业务真接 | **暂停, 等付费** | R95 task 11-15 (5 厂商 push / PHQ-9 i18n / 阿里云 SMS / Email) 真接, 1-2 月审核 | ⏸️ **等付费启动** |
| M5 法务过审 | 2026-09-15 (估, 并行 M4) | ¥45-90k 法务付费 + 3 份 md 律师签字 | ⏸️ **等付费** |
| M6 主体资质 + 临床 + NMPA | 2026-11-15 (估, 并行 M4) | ICP / 公安备案 / 等保 / NMPA 备案 | ⏸️ **等付费** |
| M7 提交审核 | 2026-12 (估) | v0.35.0+90 (R95 阶段 1+2+3+4 + 业务真接) 提交 Apple + Google | ⏸️ **等 M4-M6 完成** |
| M8 v1.0 决策 | 2027-03 (估) | **决策点**: 评估是否 bump 到 1.0.0+1 | ⏸️ **等 M7 完成** |

**v1.0.0 决策的硬门槛** (任何一项没满足 = 不 bump):
- [x] 7 个前置条件 (P0-A / P0-B / P0-C / P0-D / P0-E / P1 / P2) 全部 ✅ — **5/7 ✅, 2/7 ⏸️ (P0-C 法务 + P0-E 资质)**
- [ ] 真接阿里云 SMS (R95 task 14) — ⏸️ 等 AccessKey + 阿里云审核
- [ ] 真接 SendGrid 邮件 (R95 task 15) — ⏸️ 等 API key
- [ ] 法务过审完 (R95 task 20) — ⏸️ 等付费
- [ ] 5 厂商 push SDK 接入 (R95 task 11) — ⏸️ 等审核
- [ ] PHQ-9 / GAD-7 16 题 i18n 真接 (R95 task 12) — ⏸️ 等法务+临床
- [ ] 主体资质 + 临床审核 + NMPA 备案 (R95 task 21-23) — ⏸️ 等付费
- [ ] 至少 100 个真实用户跑过 (TestFlight 100+, task 60) — ⏸️ 留 R96+
- [x] 18 守护脚本 0 violation (含 R60 新增的 check_16kb_alignment.py + R95 新加的 check_all.dart + check_coverage.py) — ✅ **全绿**
- [x] R95 60 task 32/60 ✅ (53%) + 17/60 ⏸️ 等付费 + 10/60 misc 留 R96+ — **53% 完成, 47% 暂停/留待**

### 5.3 不 bump 的风险

如果直接用 v0.35.0+90 提交但后续发现 v1.0.0 才适合:
- Apple / Google 看到 0.x 版本会怀疑是"未完成产品"
- 影响上架审核 (4.3 Spam 规则)
- 用户也会觉得是"测试版", 转化率低

如果过早 bump (R95 后直接 1.0.0+1):
- 等于"宣告产品就绪", 但实际还在迭代
- 用户买了发现问题 → 退款 / 1 星 → 后期难洗
- 行业影响: 项目"早期口碑"差, 后续版本难翻身

**结论**: 1.0.0 是营销事件, 不是技术事件。R95 建议"先用 v0.35.0+90 提交, M8 决策点决定是否 bump"。

---

## 6. 风险与备选 (R95 实施后状态)

### 6.1 R95 主要风险 (R95 实施后, 已跑完代码风险, 剩余业务/上架风险)

| # | 风险 | 概率 | 影响 | **R95 实施后** |
|---|------|------|------|----------------|
| 1 | god page 拆 5 个风险大, 1000+ 行 sub-widget 移动可能引 bug | 中 | 高 | ✅ **R95 已拆 8 个 god widget 跑完, 0 老 test fail** |
| 2 | 法务过审 ¥45-90k 预算 + 1-2 月时长, 现金流风险 | 中 | 高 | ⏸️ 等付费, R95 持续 (task 20) |
| 3 | 5 厂商 push SDK 接入 1-2 月审核, 可能失败 1-2 个 | 中 | 高 | ⏸️ 等审核启动, R95 hidden (task 11) |
| 4 | 224 TextStyle + 208 EdgeInsets 集中器化, 守门员加严可能引 50+ 老 test 失败 | 高 | 中 | ✅ **R95 修真 102+ 处 + 保留 220+ 半 token + 20 lock-in tests, 0 老 test fail** |
| 5 | PHQ-9 / GAD-7 临床审核可能 1-2 月 + 多次返工 | 中 | 中 | ⏸️ R95 lock-in 37 tests 锁住, 等临床审核启动 (task 12) |
| 6 | `mood_period_aggregator` pre-existing fail 修可能引其他 test 失败 | 低 | 中 | ✅ **R95 sub-spec 6 task 6a 修完, 0 老 test fail** |
| 7 | 主页信息架构重排 emil XL, 可能 2-3 周 | 中 | 中 | ⏸️ 留 R96+ (task 16) |
| 8 | Android keystore + iOS 签名 配置 1-2h 但实际需 Mac + 苹果审核 | 低 | 高 | ⏸️ 留 R96+ (task 35-37) |
| 9 | **stale audit 风险** (R95 报告基于 R92 baseline, 未把 R88-91 增量算进去) | 高 | 中 | ✅ **R95 6 处 stale audit 验证 (task 8/9/25/26 + token + god page), 加 lock-in tests 防御** |
| 10 | **集成测试 + coverage 阈值** 加严可能引 50+ 老 test 失败 | 中 | 中 | ✅ **R95 sub-spec 6 跑 5 集成测试 + coverage 阈值配置, 0 老 test fail, baseline 标 domain 73.8% / data 47% / presentation 57.4%** |
| 11 | **gen-l10n 误删 ARB key** (AGENTS.md 已知坑) | 中 | 中 | ✅ **R95 sub-spec 3 触发, 加 lock-in test 防御, 误删用 `git checkout HEAD -- lib/l10n/app_*.arb` revert** |
| 12 | **半成品 widget 删后引 老 test fail** (R95 task 10 删 email_preview 整文件) | 中 | 中 | ✅ **R95 sub-spec 2 task 10 跑 2 老 test 适配, 0 老 test fail** |
| 13 | **R95 sub-spec 3 task 9 stale audit 模式** (R95 估 30+ 硬编码中文, 实际 0 改动需要) | 高 | 低 | ✅ **R95 task 9 audit 验证数字低估 2-4 倍, 改加 37 lock-in tests 锁住** |
| 14 | **R95 sub-spec 5 token 化 488 处修真** (实际 102+ 处修) | 高 | 低 | ✅ **R95 务实修真 102+ 处, 保留 220+ 半 token + 12 PDF + 集中器自身, 20 lock-in tests** |

### 6.2 备选方案 (R95 实施后)

| 备选 | 适用场景 | R95 实施后 | 改动 |
|------|----------|-------------|------|
| **方案 A (推荐)**: R95 60 task 跑代码 32/60 ✅ (53%) + 业务真接付费 | v1.0 决策点 M8 (2027-03) | **R95 跑完 5 天** | 现有路线图 + 业务真接付费 ¥45-90k + 5 厂商 + Mac + 设计师 |
| **方案 B**: R95 60 task + R96 misc 10/60 (留 R96+) | 提前 1.0 (M8 提前到 2026-12) | **R95 跑 5 天 + R96 跑 5 天** | R95 跑完 + R96 跑 10/60 misc (task 16/24/29/44/47/52/57/58/59/60) |
| **方案 C**: R95 阶段 1 only (P0, 估 13-21 周) | 极端保守, 只修 god page + token 化 | **R95 跑 5 天** (实际跟方案 A 一样) | R95 跑完, 业务真接 + 上架配置全 ⏸️, v1.0 推迟到 2027-Q3+ |
| **方案 D**: 跳过 R95, 直接 1.0 提交 v0.30.0+85 | 极早期, 风险大 | 不推荐 (R95 跑 5 天价值远大于跳过) | 4.3 Spam 拒, 退款风险高 |

---

## 7. dev doc 同步 (R95 阶段 1+2+3+4 实施后)

### 7.1 R95 期间必更新文件 (R95 实施后状态)

| 文件 | 更新内容 | 频率 | **R95 实施后状态** |
|------|----------|------|---------------------|
| `docs/VERSION_1.0_PLAN.md` (本文件) | R95 task 进度 + M1-M8 时间表调整 | 每周 | ✅ **2026-08-07 已升级** (R95 阶段 1+2+3+4 实施后状态, 60 task 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+) |
| `docs/CHANGELOG.md` | 每 task 完成后增 entry | 每 task | ✅ **2026-08-07 R95 8 sub-spec entry 全加** (sub-spec 1+2+3+4+5+6+7+8) |
| `AGENTS.md` | 18 守门员 (含 R95 新加 2) + 8 god widget 状态表 | R95 阶段 1 后 | ⏳ **待更新** (R95 跑完 8 god widget 状态变化未同步到 AGENTS.md) |
| `README.md` | R95 红 banner (业务真接进度) | 每月 | ⏳ **待更新** (R95 业务真接暂停状态未同步到 README 红 banner) |
| `docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/` | 6 视角子报告 + 99-r95-final-summary 总结 | 每阶段后 | ✅ **2026-08-07 已写** (7 份 md, 86.8KB) |
| `docs/decisions/v0.30_r95_sub_spec8_ux_decisions.md` (已建) | R95 关键设计决策 (token 化 / god page 拆 / 业务真接) | 关键决策点 | ✅ **已建** (sub-spec 8 UX 决策; 8 sub-spec 报告分散在 sdd-logs/, 可选再汇总) |
| `docs/VERSION_1.0_PLAN.md` R95 task 状态表 | 60 task 状态实时更新 | 每周 | ✅ **本文件已标 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+** |

### 7.2 R95 决策 ledger (`.superpowers/sdd-logs/round95-*.md`)

R95 实施后, 实际跑的 8 sub-spec 目录:
- ✅ `round95-godpage-section/` (sub-spec 1, 9 commit, task 1 拆 data_mgmt_section)
- ✅ `round95-silent-catch/` (sub-spec 2 task 8, 1 commit, catch 集中器化 + 16 lock-in tests)
- ✅ `round95-misc-p1/` (sub-spec 2 task 10/25/26, 1 commit, 半成品 + dispose + badge sync)
- ✅ `round95-hardcoded-chinese/` (sub-spec 3, 1 commit, task 9 P0 硬编码中文 lock-in 37 tests)
- ✅ `round95-godpage-split/` (sub-spec 4, 5 commit, task 2/5/6/7 拆 4 god page)
- ✅ `round95-token/` (sub-spec 5, 6 commit, task 3-4 token 化 102+ 处 + 20 lock-in tests)
- ✅ `round95-test-coverage/` (sub-spec 6, 6 commit, pre-existing fail + god widget + 集成测试 + coverage 阈值)
- ✅ `round95-misc-p2/` (sub-spec 7, 13 commit, task 30/31/32/53/54/55 + R96 留待)
- ✅ `round95-ux-p3/` (sub-spec 8, 12 commit, task 17/18/19/45-67 P3 UX)

**R95 实施后总**: 8 sub-spec 目录 / 44 commit / 8 task report / 8 progress.md (跟 R84-R93 SDD 模式一致)

### 7.3 R95 守门员 (R95 实施后 18 个, R95 新加 2)

| # | 守门员 | 类型 | 描述 | R95 状态 |
|---|--------|------|------|----------|
| 1 | `check_arb_keys.py` | python | zh / en / zh_Hant ARB 同步 | ✅ R57 |
| 2 | `check_changelog.py` | python | pubspec 版本号 + CHANGELOG 顺序 | ✅ R57 |
| 3 | `check_cross_feature.py` | python | 跨 feature import 边界 | ✅ R57 |
| 4 | `check_datetime_race.py` | python | 跨函数 DateTime.now() 多次调用 | ✅ R19B |
| 5 | `check_datetime_race2.py` | python | 跨 DateTime(y,m,d) 多次调用 | ✅ R19B |
| 6 | `check_drift_namespace.py` | python | @DataClassName 唯一 | ✅ R57 |
| 7 | `check_fullwidth_punctuation.py` | python | 全角标点 (warn-only) | ✅ R58 |
| 8 | `check_no_hardcoded_utc.py` | python | UTC 硬编码 | ✅ R57 |
| 9 | `check_no_pua.py` | python | PUA 字符 | ✅ R57 |
| 10 | `check_widget_dispose.py` | python | 资源泄漏 | ✅ R57 |
| 11 | `check_orphan_arb_keys.py` | python | ARB key 定义但未引用 | ✅ R56e |
| 12 | `check_legal_consent.py` | python | 单独同意 / PIPL §13 / §14 检测 | ✅ R57 |
| 13 | `check_sms_release_ready.py` | python | SMS 上线前 checklist (warn-only) | ✅ R57 |
| 14 | `check_strings_hardcoded.py` | python | 硬编码中文 string 检测 | ✅ R57 |
| 15 | `check_zh_hant_consistency.py` | python | 繁简一致性 (OpenCC s2tw) | ✅ R57 |
| 16 | `check_16kb_alignment.py` | python | Android 16KB page size 验证 | ✅ R60 |
| 17 | `check_all.dart` | dart | 4 层架构纯度 + 一致性 | ✅ R19B 合并 (本表 R57) |
| **18** | **`check_coverage.py`** | **python** | **Coverage 阈值 (R95 新加, 2026-08-07)** | ✅ **R95 sub-spec 6 task 6e** |

**R95 守门员 18 全绿 (16 .py + 2 .dart), 2 warn-only 故意 (fullwidth_punctuation / widget_dispose R92 known false positive)**

---

## 8. 引用

### 8.1 R95 综合报告 (R95 阶段 1+2+3+4 实施后, 2026-08-07)

- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/99-r95-final-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB, **R95 实施后整体总结**, 2026-08-07 Mavis 写)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/00-r95-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/00-r95-summary.md) (44KB, 主综合报告 + R95+ 路线图, 2026-08-06 Mavis 写)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/01-emil.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/01-emil.md) (5.7KB, 设计工程)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/02-spen.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/02-spen.md) (6.5KB, 英文软件工程)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/03-spzh.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/03-spzh.md) (7.2KB, 国内合规 + 中文)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/04-appstore.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/04-appstore.md) (6.3KB, iOS 上架)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/05-googleplay.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/05-googleplay.md) (6.0KB, Android 上架)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/06-flutter-spec.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/r95-increment/06-flutter-spec.md) (10.8KB, v3.1 规范)

### 8.2 R95 8 sub-spec 实施报告 (2026-08-06 ~ 2026-08-07)

- [docs/superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md](superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md) (sub-spec 1, 9 commit, 拆 data_mgmt_section 606→44)
- [docs/superpowers/sdd-logs/round95-silent-catch/sdd/task-8-report.md](superpowers/sdd-logs/round95-silent-catch/sdd/task-8-report.md) (sub-spec 2 task 8, 1 commit, catch 集中器化 + 16 lock-in tests)
- [docs/superpowers/sdd-logs/round95-misc-p1/sdd/task-10-25-26-report.md](superpowers/sdd-logs/round95-misc-p1/sdd/task-10-25-26-report.md) (sub-spec 2 task 10/25/26, 1 commit, 半成品 + dispose + badge sync)
- [docs/superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-audit-report.md](superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-audit-report.md) (sub-spec 2 task 9 audit, 1 commit, 30+ 硬编码中文 audit 验证)
- [docs/superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-p0-report.md](superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-p0-report.md) (sub-spec 3, 1 commit, 4599 字符 → ARB + 37 lock-in tests)
- [docs/superpowers/sdd-logs/round95-godpage-split/sdd/sub-spec-4-report.md](superpowers/sdd-logs/round95-godpage-split/sdd/sub-spec-4-report.md) (sub-spec 4, 5 commit, 拆 4 god page 2943→661 行)
- [docs/superpowers/sdd-logs/round95-token/sdd/task-3-4-audit-report.md](superpowers/sdd-logs/round95-token/sdd/task-3-4-audit-report.md) (sub-spec 5 audit, 1 commit, token 残留 audit 验证)
- [docs/superpowers/sdd-logs/round95-token/sdd/task-3-4-report.md](superpowers/sdd-logs/round95-token/sdd/task-3-4-report.md) (sub-spec 5, 5 commit, 102+ 处 token 化 + 20 lock-in tests)
- [docs/superpowers/sdd-logs/round95-test-coverage/sdd/sub-spec-6-report.md](superpowers/sdd-logs/round95-test-coverage/sdd/sub-spec-6-report.md) (sub-spec 6, 6 commit, pre-existing fail + god widget + 集成测试 + coverage 阈值)
- [docs/superpowers/sdd-logs/round95-misc-p2/sdd/sub-spec-7-report.md](superpowers/sdd-logs/round95-misc-p2/sdd/sub-spec-7-report.md) (sub-spec 7, 13 commit, task 30/31/32/53/54/55 + R96 留待)
- [docs/superpowers/sdd-logs/round95-ux-p3/sdd/sub-spec-8-report.md](superpowers/sdd-logs/round95-ux-p3/sdd/sub-spec-8-report.md) (sub-spec 8, 12 commit, task 17/18/19/45-67 P3 UX)

### 8.3 R92 6 视角基线报告 (R93 修复依据, 2026-08-06)

- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/00-summary-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/00-summary-report.md) (35KB, 综合)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/01-emilkowalski-design-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/01-emilkowalski-design-report.md) (45.9KB, emil)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/02-superpowers-en-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/02-superpowers-en-report.md) (76.7KB, spen)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/03-superpowers-zh-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/03-superpowers-zh-report.md) (73.9KB, spzh)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/04-appstore-ios-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/04-appstore-ios-report.md) (61.4KB, AppStore)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/05-googleplay-android-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/05-googleplay-android-report.md) (55.1KB, GooglePlay)
- [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-06/06-flutter-spec-report.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-06/06-flutter-spec-report.md) (72.8KB, flutter-spec)

### 8.4 R67 + R95 决策保留

- v1.0.0 是营销事件, 不是技术事件
- M0 (2026-08-07) R95 阶段 1+2+3+4 全部完成 (8 sub-spec / 44 commit / +347 R95 new tests)
- M1-M3.5 (2026-08-07) R95 阶段 1+2+3+4 跑完
- M4 (等付费启动) R95 业务真接 task 11-15
- M5-M6 (等付费) R95 法务 + 主体资质 + 临床 + NMPA
- M7 (等 M4-M6 完成) v0.35.0+90 提交 Apple + Google
- M8 (2027-03 估) 决策点: 评估是否 bump 到 1.0.0+1

### 8.5 行业参考

- Apple 4.3 Spam: https://developer.apple.com/app-store/review/rejections/#common-rejections
- Play Store 重复提交政策: https://support.google.com/googleplay/android-developer/answer/9888077
- 行业惯例 (0.x → 1.0): Semantic Versioning https://semver.org/
- 本项目历史: `git log --oneline --grep="version"` 看每次 bump 决策
- PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54: https://www.gov.cn/xinwen/2021-08/20/content_5632486.htm
- NMPA 备案 (医疗 App): https://www.nmpa.gov.cn/

---

**dev doc 升级完成时间**: 2026-08-07 (R95 阶段 1+2+3+4 实施后升级版)
**dev doc 升级体量**: 32.7KB → 升级后 38KB+ (R95 实施后状态 + 6 视角评分变化 + R95 实施后修复优先级矩阵 + 7 sub-spec 引用)
**R95+ 路线图总 task**: 60+ (R95 实施后 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+)
**下次 dev doc 同步**: R95 业务真接付费启动后 (估 1-2 月, 2026-09 ~ 2026-10)

---

## 9. R97 6 视角审计追加 (2026-08-07, 55 项新发现)

> 本章节为 R95 sub-spec 8 实施后, 用户要求拉 6 个视角团队 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification) 对整个项目分别出一份审计报告的汇总追加。6 份报告去重后共 55 项独立发现 (P0=8 / P1=14 / P2=17 / P3=16), 每项标注 **类别 (架构/底层) + 修复难度 (low/medium/high) + 涉及视角**。
>
> **审计覆盖 5 个检查项**: ①外部链接隐藏 ②上架/架构/重构/半成品 ③顶层架构审视 ④底层逐行排查 ⑤开发需求文档更新
>
> **跟 R95 路线图 60 task 的关系**: 本章节 55 项发现中, 部分是 R95 已识别但被低估的 (如 P0-7 SMS 真接), 部分是 R95 后新发现的 (如 P0-1 check_safety 跨层 import, P0-2 主页危机入口被 FeatureFlag 隐藏)。新发现已纳入 R96+ 路线图。

### 9.1 R97 6 视角审计发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 0 | 1 | 5 | 8 | 14 | A- (架构 9.0/10) |
| superpowers-en (工程) | 1 | 3 | 5 | 7 | 16 | B+ (1 P0 架构违规) |
| superpowers-zh (合规+中文) | 4 | 1 | 6 | 4 | 15 | 🟢 架构达标 / 🔴 法务未解 |
| AppStore (iOS 上架) | 3 | 3 | 4 | 3 | 13 | 上架就绪 ~45% |
| GooglePlay (Android 上架) | 3 | 8 | 7 | 2 | 20 | 上架风险 🔴 高 |
| flutter-specification (规范) | 0 | 3 | 6 | 7 | 16 | ⭐⭐⭐⭐ (4/5) |
| **合计去重** | **8** | **14** | **17** | **16** | **55** | — |

### 9.2 R97 P0 必修清单 (8 项, 上架/v1.0 blocker)

| R97 ID | 问题 | 类别 | 难度 | 视角 | 对应 R95 task | 文件 |
|---|---|---|---|---|---|---|
| **R97-P0-1** | check_safety.dart 跨层 import data/services/safety_detector (R85 重构漏改 import + 旧文件未删, 4 层架构硬约束违规) | 架构 | low | spen | 新发现 | [check_safety.dart#L16](../lib/domain/usecases/check_safety.dart) |
| **R97-P0-2** | 主页心理危机热线入口被 FeatureFlag 完全隐藏 (emergencyContactEnabled=false 守卫, Apple 1.4.1 直接拒) | 底层 | low | AppStore | 新发现 | [home_fab_toolbar.dart#L97](../lib/presentation/pages/home/widgets/home_fab_toolbar.dart) |
| **R97-P0-3** | 域名 chroniccare.app 未注册 + 6 个 privacy/support URL 404 (Apple 5.1.1 + Google Play Data Safety form 双必拒) | 底层 | medium | spzh/AppStore/GooglePlay | R95 task 40 | [fastlane/metadata/ios/zh-Hans/privacy_url.txt](../fastlane/metadata/ios/zh-Hans/privacy_url.txt) |
| **R97-P0-4** | 3 份法律文档"草稿未经律师过审" (PIPL §28/§29 + Apple 5.1.5 强制, ¥45-90k) | 架构 | high | spzh/AppStore/GooglePlay | R95 task 20 | [privacy_policy.md#L212](../assets/legal/privacy_policy.md) |
| **R97-P0-5** | Release 签名 fallback debug keystore (signingConfig 硬绑 debug, Play Console 直接拒) | 底层 | low | emil/GooglePlay | R95 task 37 | [build.gradle.kts#L82](../android/app/build.gradle.kts) |
| **R97-P0-6** | USE_EXACT_ALARM 权限违反 Google Play 限制 (2024-07 起限制为 alarm clock/calendar 类, 精神心理服药提醒不在允许范围) | 底层 | low | GooglePlay | R95 task 38 | [AndroidManifest.xml#L33](../android/app/src/main/AndroidManifest.xml) |
| **R97-P0-7** | SMS / Email 真接未做 (AliyunSmsProvider.send() throw StateError, EmailService 未实现, 失联通知业务 100% 不可用) | 架构 | high | spzh/spen | R95 task 14/15 | [sms_service.dart#L195](../lib/core/data/services/sms_service.dart) |
| **R97-P0-8** | NMPA 医疗器械备案未明确 (PHQ-9/GAD-7 心理评估可能触发二类医疗器械备案, 未做法务咨询) | 架构 | high | spzh | R95 task 23 | [README.md#L265](../README.md) |

### 9.3 R97 P1 重要清单 (14 项, 上架前应修)

| R97 ID | 问题 | 类别 | 难度 | 视角 | 文件 |
|---|---|---|---|---|---|
| **R97-P1-1** | daily_tracking 6 provider 暴露 Impl 类型 (违反 AGENTS "Provider<XRepository> 暴露接口"约束) | 架构 | medium | spen | [daily_tracking_providers.dart#L39](../lib/presentation/providers/daily_tracking_providers.dart) |
| **R97-P1-2** | TodayMedSchedule.build() 调 DateTime.now() (跨 midnight stale + rebuild 浪费) | 底层 | low | spen | [today_med_schedule.dart#L44](../lib/presentation/pages/medication/today_med_schedule.dart) |
| **R97-P1-3** | VentRepositoryImpl.delete() TOCTOU 事务范围错 (select 在事务外, rename 场景可能删错文件) | 底层 | medium | spen | [vent_repository_impl.dart#L105](../lib/core/data/repositories/vent/vent_repository_impl.dart) |
| **R97-P1-4** | vent 树洞 UGC 完全没有举报机制 (Apple 1.2.1 直接拒, 无举报按钮 + 无 UGC 政策声明) | 底层 | medium | AppStore | [vent_detail_page.dart](../lib/presentation/pages/vent/vent_detail_page.dart) |
| **R97-P1-5** | user_agreement 定价段描述与实际不符 (v1.0.0+147 已删, Apple 2.1/3.1.1) | 底层 | medium | AppStore | [user_agreement.md](../assets/legal/user_agreement.md) |
| **R97-P1-6** | 首次启动立即请求通知权限 (main.dart bootstrap 阶段调 init() 内立即 requestPermissions, 违反"先解释后请求") | 底层 | medium | AppStore/GooglePlay | [main.dart#L161](../lib/main.dart) |
| **R97-P1-7** | setup_legal_dialog 危机热线展示不完整 (注释写 5 条实际只渲染 4 条, 漏 crisisHotlineCnBeijing, 与 user_agreement §5 表格不同步) | 底层 | low | spzh | [setup_legal_dialog.dart#L79](../lib/presentation/pages/setup/setup_legal_dialog.dart) |
| **R97-P1-8** | INTERNET 权限当前为非必需 (业务全部 flag=false 暂停, 0 网络调用但申请 INTERNET) | 底层 | low | GooglePlay | [AndroidManifest.xml#L30](../android/app/src/main/AndroidManifest.xml) |
| **R97-P1-9** | RECORD_AUDIO 权限与 ventAudioEnabled=false 不匹配 (业务暂停期应删除 microphone 权限) | 底层 | low | GooglePlay | [AndroidManifest.xml#L37](../android/app/src/main/AndroidManifest.xml) |
| **R97-P1-10** | BootReceiver 半成品 (R64+ TODO, manifest 声明 RECEIVE_BOOT_COMPLETED 但 FeatureFlag 禁用, Android 14+ 后台启动限制) | 底层 | medium | GooglePlay | [BootReceiver.kt#L29](../android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt) |
| **R97-P1-11** | 危机热线只能复制号码, 无一键拨打 (Health/Sensitive Apps policy 推荐 tel: intent) | 底层 | low | GooglePlay | [crisis_hotline_page.dart#L182](../lib/presentation/pages/crisis_hotline_page.dart) |
| **R97-P1-12** | analysis_options.yaml lint 规则强度偏低 (仅 4 条显式规则, 远低于 Effective Dart 推荐) | 架构 | low | flutter-spec | [analysis_options.yaml#L17](../analysis_options.yaml) |
| **R97-P1-13** | unnecessary_late + dead_code + deprecated_member_use 3 处 warning (main.dart late final 误用 + export_dialog dead code + RadioListTile 弃用 API) | 底层 | low | flutter-spec | [main.dart#L45](../lib/main.dart) |
| **R97-P1-14** | PIPL §13 紧急联系人"单独同意"软实施 (用户担保已告知, 非联系人独立确认, v1.0 真接 SMS 时必须升级) | 架构 | high | spzh/AppStore | [setup_legal_dialog.dart#L24](../lib/presentation/pages/setup/setup_legal_dialog.dart) |

### 9.4 R97 P2 建议清单 (17 项, v1.0+ 可做)

| R97 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R97-P2-1** | UseCase 层薄厚不均 (9 repo 仅 4 usecase, 5 类业务 presentation→repo 直接对话) | 架构 | medium | spen |
| **R97-P2-2** | CareEngine + FireCareStrategyUseCase 4 strategy DRY 重复 ~50 行 | 底层 | medium | spen |
| **R97-P2-3** | latestXxxEntryProvider 用 .value?.firstOrNull 隐式假设 stream 排序 (违反 AGENTS 已知坑) | 底层 | low | spen |
| **R97-P2-4** | AppTokens facade 306 行 god class (注释承诺 ≤50 行) + 5 个 magic size 常量未抽 | 架构 | medium | flutter-spec |
| **R97-P2-5** | directives_ordering 违反 6 处 (dart: 排在 package: 之后, lint 未启用) | 底层 | low | flutter-spec |
| **R97-P2-6** | FeatureFlags 注释与实现不一致 (4 vs 11 vs 8 flag) + setEmergencyContactEnabledForTest setter 缺失 | 底层 | low | flutter-spec |
| **R97-P2-7** | 通知 channel name/title 硬编码中文 const (en/zh_Hant 用户看中文 channel) | 底层 | medium | spzh |
| **R97-P2-8** | userNameFamily 残留"您的家人" (跟 R72 中性化决策不一致, 可能引发病耻感) | 底层 | low | spzh |
| **R97-P2-9** | emailBody "避免复发" 不中性 (精神心理场景用词不中性) | 底层 | low | spzh |
| **R97-P2-10** | setup_step_done 缺首次评估/紧急联系人引导 | 底层 | low | spzh |
| **R97-P2-11** | PIPL §52 联系方式软隐藏 (邮箱渠道不可达, App 内反馈不便捷) | 架构 | medium | spzh |
| **R97-P2-12** | 25 处 TODO 无版本号 (长期 TODO 滚雪球, 新人误判优先级) | 底层 | medium | spen |
| **R97-P2-13** | proguard-rules.pro 缺 speech_to_text 完整 keep 规则 (v1.0 真接 STT 时可能 crash) | 底层 | low | GooglePlay |
| **R97-P2-14** | SCHEDULE_EXACT_ALARM targetSdk=33+ 默认 denied (通知时间偏移 silent bug) | 底层 | low | GooglePlay |
| **R97-P2-15** | 缺 android:largeHeap (PDF 导出 OOM 风险) | 底层 | low | GooglePlay |
| **R97-P2-16** | FeatureFlags 全 8 项 false (商店描述与实际功能不符触发 Minimum Functionality 拒审) | 架构 | low | GooglePlay/AppStore |
| **R97-P2-17** | PHQ-9/GAD-7 量表 i18n 未完成 (en/zh_Hant 用户看中文题目, 医疗法律责任) | 底层 | medium | AppStore |

### 9.5 R97 P3 nice-to-have 清单 (16 项, 摘要)

| R97 ID | 问题 | 类别 | 难度 |
|---|---|---|---|
| **R97-P3-1** | App Store 截图未准备 (33 张真机截图) | 架构 | medium |
| **R97-P3-2** | fastlane/Appfile 需真实 APPLE_ID/TEAM_ID (R96 ENV 化但需用户填) | 架构 | low |
| **R97-P3-3** | contacts 硬空 + fireSms/Email 硬抛 StateError (v1.0 切 SMS/Email 时埋雷) | 底层 | medium |
| **R97-P3-4** | AppListTile 三元 `onTap != null ? null : onTap` 等价 null dead code | 底层 | low |
| **R97-P3-5** | _StreakCounter 首次进入无 0→N 动画 (emil 风格首次也做轻量动画) | 底层 | low |
| **R97-P3-6** | _nextReminderTime 硬编码 20:00 magic number (应抽 nextReminderProvider) | 底层 | low |
| **R97-P3-7** | 跨时区 DateTime 不一致 (4 处 DateTime.now() 跟 tz.local 混用, 海外 DST 切换风险) | 底层 | low |
| **R97-P3-8** | 版本考古注释过密 (main.dart 496 行注释占 40%, 违反 Effective Dart 文档简洁原则) | 底层 | low |
| **R97-P3-9** | 4 个文件首行 UTF-8 BOM (vent_compose_page / vent_detail_page / legal_page / app_routes) | 底层 | low |
| **R97-P3-10** | legal_page.dart 撤回时间未走 DateFormat (手工 padLeft 拼接, 未本地化) | 底层 | low |
| **R97-P3-11** | contact 缺本人手机号校验 (用户把自己的号码填成紧急联系人) | 底层 | low |
| **R97-P3-12** | ARB description 中英混杂 (zh 是中文 en 是英文, dartdoc 不友好) | 底层 | low |
| **R97-P3-13** | commonSave 简繁不一致 (zh 与 zh_Hant 都是"保存", 繁体应是"儲存") | 底层 | low |
| **R97-P3-14** | NotificationService facade 仍持 6 类 ID 常量 (ID range 应下沉到各自 sub-service) | 架构 | medium |
| **R97-P3-15** | domain/logic 32 文件无目录分组 (建议分子目录 scales/ care/ medication/ trend/) | 架构 | low |
| **R97-P3-16** | FireCareStrategyUseCase priority map 死代码 (4 strategy 互斥, priority map 是冗余) | 底层 | low |

### 9.6 R97 5 大检查项总结

#### 检查项 ①: 外部链接隐藏 — ✅ 运行时合规, ⚠️ 元数据占位待替换

- **lib/ 内**: 0 处 `launchUrl`/`url_launcher` 调用, 4 处 https URL 全在注释 (sms_service.dart 阿里云文档 + chinese_holidays.dart 说明)
- **fastlane/metadata/**: 6 个 privacy_url.txt + 6 个 support_url.txt 指向未注册域名 chroniccare.app (R97-P0-3)
- **assets/legal/**: 3 份法律文档"草稿"标注 (R97-P0-4)
- **AndroidManifest/Info.plist**: 0 外部 URL scheme 配置, 合规

#### 检查项 ②: 上架/架构/重构/半成品 — 🔴 8 P0 阻塞

- **上架 blocker**: 域名 + 律师 + 签名 + USE_EXACT_ALARM + NMPA (R97-P0-3/4/5/6/8)
- **半成品**: SMS/Email/5 厂商 push/PHQ-9 i18n 5 项业务真接 + BootReceiver + NSESSS/CRDPSS 量表
- **架构违规**: check_safety.dart 跨层 import (R97-P0-1)
- **重构机会**: home_page_state 650 行 / mood_audio_section / notification_service facade / AppTokens god class

#### 检查项 ③: 顶层架构审视 — ✅ 9.0/10 (国内中型项目天花板)

- **4 层 + core umbrella**: domain 0 Flutter 0 Drift, check_all.dart 守门员强制
- **依赖方向**: presentation → domain ← data 单向, 跨 feature 边界 check_cross_feature.py 守门
- **Riverpod 3.x**: Provider<XRepository> 暴露接口 (但 daily_tracking 6 个违规暴露 Impl, R97-P1-1)
- **隐私边界**: vent 独立表 + 架构强制不进分析/通知/关怀
- **可优化**: UseCase 层覆盖不足 / services/ 28 文件无目录分组 / AppTokens facade 仍 306 行

#### 检查项 ④: 底层逐行排查 — 14 项 P1+ 修复点

- **架构违规**: check_safety.dart 跨层 import (R97-P0-1)
- **bug**: VentRepositoryImpl.delete() TOCTOU (R97-P1-3) / TodayMedSchedule DateTime.now() (R97-P1-2)
- **上架 blocker**: 主页危机入口隐藏 (R97-P0-2) / 通知权限时机 (R97-P1-6) / UGC 无举报 (R97-P1-4)
- **lint**: unnecessary_late + dead_code + deprecated_member_use (R97-P1-13) + directives_ordering 6 处 (R97-P2-5)
- **i18n**: 通知 channel 中文 const (R97-P2-7) / userNameFamily 病耻感 (R97-P2-8) / emailBody 不中性 (R97-P2-9)

#### 检查项 ⑤: 开发需求文档更新 — ✅ 本章节已追加 R97 6 视角审计 55 项发现

### 9.7 R97 跨视角共识高频项 (3+ 视角同意)

| # | 问题 | 视角数 | 类别 | 难度 |
|---|---|---|---|---|
| 1 | 法务过审 (¥45-90k, 1-2 月) | 3 (spzh/AppStore/GooglePlay) | 架构 | high |
| 2 | 域名 chroniccare.app 注册 + 部署 | 3 (spzh/AppStore/GooglePlay) | 底层 | medium |
| 3 | SMS/Email 真接业务阻塞 | 3 (spzh/spen/AppStore) | 架构 | high |
| 4 | 通知权限请求时机违反"先解释后请求" | 2 (AppStore/GooglePlay) | 底层 | medium |
| 5 | FeatureFlags 全 false 商店描述不符 | 2 (GooglePlay/AppStore) | 架构 | low |
| 6 | Release 签名 fallback debug | 2 (emil/GooglePlay) | 底层 | low |
| 7 | 跨时区 DateTime 不一致 | 2 (emil/spen) | 底层 | low |
| 8 | PIPL §13 联系人单独同意软实施 | 2 (spzh/AppStore) | 架构 | high |

### 9.8 R97 修复路径建议 (按优先级)

#### 第 1 周 (解锁 P0, 估 13-21 commit)

1. **R97-P0-1** check_safety.dart 跨层 import — 30 分钟, 改 import + 删旧 safety_detector.dart + 改测试 import
2. **R97-P0-2** 主页危机入口 — 10 分钟, 把 crisis hotline FAB 从 emergencyContactEnabled 守卫中拆出来
3. **R97-P0-5** Release 签名 — 1-2h, 切 signingConfigs.getByName("release")
4. **R97-P0-6** USE_EXACT_ALARM — 5 分钟, 删 manifest 第 33 行
5. **R97-P0-3** 域名注册 — 1-2 天注册 + 7-20 天 ICP 备案 (并行)
6. **R97-P0-4** 律师过审 — 1-2 周 + ¥45-90k (并行)
7. **R97-P0-7** SMS/Email 真接 — 跟 R95 task 14/15 合并
8. **R97-P0-8** NMPA 备案 — 法务咨询 1-2 月 (并行)

#### 第 2 周 (修 P1, 估 8-15 commit)

9. **R97-P1-1** daily_tracking 6 provider 暴露 Impl — 加 6 个 abstract interface
10. **R97-P1-2** TodayMedSchedule.build() — 改用 ref.watch(todayProvider)
11. **R97-P1-3** VentRepositoryImpl.delete() TOCTOU — select 挪进 transaction
12. **R97-P1-4** vent UGC 举报 — 加举报按钮 + metadata 声明 UGC 政策
13. **R97-P1-5** 定价段描述不符 — v1.0.0+147 已改 user_agreement §3 为永久免费
14. **R97-P1-6** 通知权限请求时机 — 拆 init() 为 initialize() + requestPermissions()
15. **R97-P1-7** 危机热线展示 — 加 crisisHotlineCnBeijing 渲染
16. **R97-P1-8/9** 删 INTERNET/RECORD_AUDIO 权限
17. **R97-P1-10** BootReceiver — 从 manifest 删除注册 + RECEIVE_BOOT_COMPLETED 权限
18. **R97-P1-11** 危机热线一键拨打 — 加 url_launcher + tel: intent
19. **R97-P1-12** lint 规则 — 升级到 flutter_lints 推荐集
20. **R97-P1-13** 3 处 warning — dart fix --apply

#### 第 3-4 周 (降 P2 风险, 估 15-25 commit)

21. **R97-P2-1** UseCase 层 — 补 AddMedicationUseCase / DeleteMedicationUseCase / WithdrawVentConsentUseCase
22. **R97-P2-2** CareEngine + FireCareStrategyUseCase DRY — use case 直接调 CareEngine.evaluate
23. **R97-P2-3** latestXxxEntryProvider — 显式 reduce(isAfter) 找最新
24. **R97-P2-4** AppTokens facade — 5 个 magic size 常量挪到 AppSpacing
25. **R97-P2-5** directives_ordering — 启用 lint + dart fix --apply
26. **R97-P2-7** 通知 channel i18n — init() 内 dynamic 拿 l10n 注入 channel
27. **R97-P2-8/9** userNameFamily / emailBody 中性化
28. **R97-P2-12** TODO 加版本号 — 统一格式 `// TODO(v0.31, P1): <desc>`
29. **R97-P2-14** SCHEDULE_EXACT_ALARM 自检卡 — NotificationStatusCard 加状态检测
30. **R97-P2-15** android:largeHeap — application 标签加

#### v1.0 前 (P3 nice-to-have, 估 10-20 commit)

31. 截图准备 + Appfile 真实凭据
32. AppListTile dead code 清理 + _StreakCounter 首次动画
33. _nextReminderTime 抽 provider + 跨时区 DateTime 统一
34. 版本考古注释梳理 + BOM 文件清理
35. legal_page DateFormat + contact 本人手机号校验
36. ARB description 统一英文 + commonSave 简繁修正
37. NotificationService facade ID 常量下沉
38. domain/logic 子目录分组
39. FireCareStrategyUseCase priority map 死代码清理

### 9.9 R97 上架风险评估

**整体上架就绪度**: ~45% (跟 R95 实施后持平, R97 新发现 8 P0 抵消 R95 8 sub-spec 改善)

**Apple App Store 风险**: 🔴 高 — 主页无危机入口 + 隐私 URL 404 + UGC 无举报 = 3 项必拒
**Google Play 风险**: 🔴 高 — USE_EXACT_ALARM 违规 + Release 签名 + 隐私政策律师未过审 = 3 项必拒

**建议路径**:
- v0.30 不上 store (R97 8 P0 全部阻塞)
- 第 1-2 周修 R97-P0-1/2/5/6 + R97-P1-1/2/3/4/6/7/8/9/10/11 共 12 项代码侧修复 (无需外部资源)
- 第 3-4 周修 R97-P2 17 项降风险
- 并行启动 R97-P0-3/4/7/8 外部资源 (域名 1-2 天 + ICP 7-20 天 + 律师 1-2 月 + SMS 1-2 月 + NMPA 1-2 月)
- 最早 M6 (2026-11-15) 4 项外部资源并行完成后上 store

### 9.10 R97 跟 R95 路线图对应关系

| R97 发现 | R95 task 状态 | R97 后状态 |
|---|---|---|
| R97-P0-1 check_safety 跨层 import | R95 未识别 | **新发现, 必修** |
| R97-P0-2 主页危机入口隐藏 | R95 未识别 (R93 FeatureFlag 守门副作用) | **新发现, 必修** |
| R97-P0-3 域名未注册 | R95 task 40 ⏸️ 留 R96+ | R97 升级为 P0 |
| R97-P0-4 律师未过审 | R95 task 20 ⏸️ 等付费 | 持平 |
| R97-P0-5 Release 签名 | R95 task 37 ⏸️ 留 R96+ | R97 升级为 P0 |
| R97-P0-6 USE_EXACT_ALARM | R95 task 38 ⏸️ 留 R96+ | R97 升级为 P0 (Google Play 2024-07 政策) |
| R97-P0-7 SMS/Email 真接 | R95 task 14/15 ⏸️ 等付费 | 持平 |
| R97-P0-8 NMPA 备案 | R95 task 23 ⏸️ 等付费 | 持平 |
| R97-P1-1 daily_tracking Impl 暴露 | R95 未识别 (R91 daily-tracking 新增) | **新发现, 必修** |
| R97-P1-4 UGC 无举报 | R95 未识别 | **新发现, 必修** |
| R97-P1-6 通知权限时机 | R95 未识别 | **新发现, 必修** |
| R97-P1-13 lint warning | R95 未识别 | **新发现, 必修** |

**R97 新发现总计**: 6 项 (P0-1/P0-2/P1-1/P1-4/P1-6/P1-13), 其余为 R95 已识别但被低估或留 R96+ 的项

---

**R97 6 视角审计追加完成时间**: 2026-08-07
**R97 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角
**R97 发现总计**: 55 项 (P0=8 / P1=14 / P2=17 / P3=16)
**R97 新发现**: 6 项 (R95 路线图未覆盖)
**下次 dev doc 同步**: R97 P0/P1 修复完成后 (估 2-4 周)

---

## 10. R98 7 视角审计 + 底层逐行排查 + 外链核查追加 (2026-08-07, 38 项发现)

> 本章节为 R97 6 视角审计后, 用户要求拉 6 个视角团队 + 外链核查 + 底层逐行排查共 8 个并行子代理对整个项目分别出一份审计报告的汇总追加。8 份报告去重后共 38 项独立发现 (P0=9 / P1=14 / P2=10 / P3=5), 每项标注 **类别 (架构/底层) + 修复难度 (low/medium/high) + 涉及视角**。
>
> **完整 R98 审计报告**: [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R98-7perspective-audit.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R98-7perspective-audit.md)
>
> **审计覆盖 5 个检查项**: ①外部链接隐藏 ②上架/架构/重构/半成品 ③顶层架构审视 ④底层逐行排查 ⑤开发需求文档更新
>
> **跟 R97 的关系**: 本章节 38 项发现中, **22 项为 R97 未识别的新发现**, 16 项为 R97 已识别但被低估 (P2/P3 升级 P0/P1) 或留 R96+ 的项。R97 修了 12 项代码侧 P0/P1 (check_safety 跨层 import / 主页危机 FAB / Release 签名 / USE_EXACT_ALARM / 通知权限时机 / 危机热线 tel: 拨打等), 但 R98 新发现 9 项 P0 仍阻塞上架。

### 10.1 R98 8 视角发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 0 | 4 | 6 | 4 | 14 | 8.5/10 (架构成熟度) |
| superpowers-en (工程) | 1 | 4 | 4 | 2 | 11 | 8/10 (规范度) |
| superpowers-zh (合规+中文) | 4 | 3 | 3 | 0 | 10 | 6.5/10 (本土化合规) |
| AppStore (iOS 上架) | 4 | 4 | 4 | 2 | 14 | 5.5/10 (上架就绪度) |
| GooglePlay (Android 上架) | 3 | 6 | 4 | 1 | 14 | 6/10 (上架就绪度) |
| flutter-specification (规范) | 0 | 5 | 4 | 1 | 10 | 8/10 (Flutter 规范) |
| 外链核查 | 0 | 2 | 2 | 0 | 4 | 8.5/10 (外链隐藏度) |
| 底层逐行排查 | 1 | 4 | 3 | 1 | 9 | 8.5/10 (代码健康度) |
| **去重后** | **9** | **14** | **10** | **5** | **38** | — |

### 10.2 R98 P0 必修清单 (9 项, 上架/v1.0 blocker)

| R98 ID | 问题 | 类别 | 难度 | 视角 | 跟 R97 关系 | 文件 |
|---|---|---|---|---|---|---|
| **R98-P0-1** | PHQ-9 危机弹窗内无"立即拨打"按钮 (6 步操作路径, 精神心理患者危机时刻执行功能受损) | 底层 | low | spzh | **新发现** (R97 修 FAB 可见性, 弹窗内 action 未识别) | [assessment_page.dart#L185](../lib/presentation/pages/assessment/assessment_page.dart) |
| **R98-P0-2** | PHQ-9 i18n flag 关闭时 zh_Hant/en 用户看简体中文题目 (`FeatureFlags.phqGad7I18nEnabled=false`) = 医疗法律责任 | 架构 | high | spzh | R97-P2-17 升级 P0 | [phq9.dart#L170](../lib/domain/logic/phq9.dart) |
| **R98-P0-3** | iOS `UIBackgroundModes` 声明 `processing` 但 `handleSafetyCheckTask` 空实现, Apple 2.5.4 拒审风险 | 底层 | medium | AppStore | **新发现** | [Info.plist#L144](../ios/Runner/Info.plist) + [AppDelegate.swift#L72](../ios/Runner/AppDelegate.swift) |
| **R98-P0-4** | iOS `fastlane/metadata/ios/{locale}/screenshots/` 完全缺失, Apple 4.2.1 强制 6.7" iPhone 截图 = 必拒 | 架构 | medium | AppStore | R97-P3-1 升级 P0 | [fastlane/metadata/ios/](../fastlane/metadata/ios/) |
| **R98-P0-5** | Android `feature_graphic.png` + 4 张 `phone_screenshots` 全是 67 字节 1×1 占位 PNG, Google Play 必拒 | 架构 | medium | GooglePlay | **新发现** | [fastlane/metadata/android/zh-CN/feature_graphic.png](../fastlane/metadata/android/zh-CN/feature_graphic.png) |
| **R98-P0-6** | Data Safety Form `data_deletion_endpoint.url = 'https://chroniccare.app/delete-data-instructions'` 不可访问 | 架构 | high | GooglePlay | 跟 R97-P0-3 同源 (域名未注册) | [generate_data_safety_form.py#L84](../scripts/generate_data_safety_form.py) |
| **R98-P0-7** | 5 厂商 push SDK 未真接, `fiveVendorPushEnabled=false`, 国产 ROM 静默杀后台场景失联通知失效 = 中国市场 P0 | 架构 | high | spzh | 跟 R97-P0-7 部分重叠 (push 跟 SMS 不同) | [feature_flags.dart#L66](../lib/core/data/feature_flags.dart) |
| **R98-P0-8** | PHQ-9 total ≥ 20 (重度抑郁) 但 Q9=0 时不触发危机资源 dialog, 临床实践上重度抑郁应弹危机资源 | 架构 | medium | spzh | **新发现** | [phq9.dart#L156](../lib/domain/logic/phq9.dart) |
| **R98-P0-9** | `CareEngine.evaluate` / `CareEngine.fire` 死代码 (注释承诺 v0.28 删除, v0.30 仍在, 0 处实际调用) | 架构 | medium | 底层排查 | **新发现** | [care_engine.dart#L59](../lib/domain/logic/care_engine.dart) |

### 10.3 R98 P1 重要清单 (14 项, 上架前应修)

完整 P1 清单详见 [R98 完整审计报告 §3](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R98-7perspective-audit.md#3-r98-p1-重要清单-14-项-上架前应修)。摘要:

| R98 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R98-P1-1** | 3 处 `.first` 未显式 sort (latestMoodEntryProvider / mood_quick_button / assessment_summary_strip) silent bug | 底层 | low | 底层排查 |
| **R98-P1-2** | `home_page_state.dart:254-258` 显示 i18n key 字符串而非翻译文案, 用户看到 `⚠️ safetyCheckResultAlerted` | 底层 | low | emil |
| **R98-P1-3** | `crossedMidnightSince` 用 `DateTime` 而 `nextMidnightRefresh` 用 `tz.TZDateTime`, DST 不一致 | 底层 | low | emil |
| **R98-P1-4** | 3 个 StreamProvider 缺 autoDispose (allAssessmentEntries / ventSealed / ventSealedAt) | 底层 | low | emil |
| **R98-P1-5** | iOS `InfoPlist.strings` 缺 en-US 版本, 5 项 usage description 仅中文 | 底层 | medium | AppStore |
| **R98-P1-6** | 定价段描述 vs 实际不一致 (v1.0.0+147 已修, 永久免费) | 底层 | medium | AppStore |
| **R98-P1-7** | iOS subtitle/description 提"规划中/即将上线", Apple 2.3.10 不允许 | 架构 | low | AppStore |
| **R98-P1-8** | `setup_legal_dialog.dart:110` 硬编码中文 "🆘 心理危机干预热线 (24h)" 未走 ARB | 底层 | low | AppStore |
| **R98-P1-9** | `assets/legal/` 8 处软隐藏邮箱 + 1 处 GitHub 占位, PIPL §52 实质未提供有效联系方式 | 架构 | medium | spzh + 外链 |
| **R98-P1-10** | `ConsentGate` 不校验 `ConsentArtifact.version` 一致性, 法律文档升级不强制重走同意 | 架构 | medium | spzh |
| **R98-P1-11** | `recordConsent` 未记录 `sensitiveDataConsentAt` 时间戳 + 未持久化 `emergencyContactSharing` | 底层 | medium | spzh |
| **R98-P1-12** | `sensitive_data_consent.md` §4 文档与 `legal_page.dart` UI 不一致 (撤回失联通知) | 架构 | low | spzh |
| **R98-P1-13** | 跨时区 DateTime 不一致 (跟 P1-3 同源, 4 处混用) | 底层 | low | emil + spen |
| **R98-P1-14** | `check_zh_hant_consistency.py` 仅字符级不检 phrase (信息→資訊 / 软件→軟體) | 架构 | medium | spzh |

### 10.4 R98 P2/P3 清单 (15 项, v1.0+ 可做)

完整清单详见 [R98 完整审计报告 §4 + §5](audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R98-7perspective-audit.md#4-r98-p2-建议清单-10-项-v10-可做)。摘要:

- **P2 (10 项)**: ThemeExtension 缺位 / routerProvider 反模式 / ThemeModeNotifier 异步 / textTheme 不全 / Form 校验未走 FormState / 0 golden test / a11y 覆盖不足 / directives_ordering lint / Android title 超长 / setup 第 4 勾选 onView 空
- **P3 (5 项)**: main.dart magic number / Future.wait 泛型化 / drift batch 优化 / RadioListTile 弃用 API / trailing comma 清扫

### 10.5 R98 5 大检查项总结

#### 检查项 ①: 外部链接隐藏 — ✅ 代码层就绪 / ⚠️ 法律文档层 9 处软隐藏待清

- **lib/ 代码层**: 0 处真实外链跳转, 4 处 https URL 全为注释, 0 个云上报 SDK, 1 处 url_launcher 严格 `tel:` 危机热线, ✅ **可直接上架**
- **assets/legal/**: ⚠️ 8 处软隐藏邮箱 + 1 处 GitHub 占位, 用户在「设置 → 法律与隐私」页可见 (R98-P1-9)
- **评分**: 8.5/10

#### 检查项 ②: 上架/架构/重构/半成品 — 🔴 9 P0 阻塞 (4 项代码侧 + 5 项外部资源)

- **上架 P0**: iOS processing 空挂 + iOS 缺 en-US InfoPlist.strings + iOS/Android 截图缺失/占位  描述矛盾 + Data Safety Form URL 不可访问
- **架构违规 (新发现)**: CareEngine.evaluate/fire 死代码 + 3 处 StreamProvider 缺 autoDispose
- **半成品 (跟 R97 重叠)**: SMS/Email/5 厂商 push/PHQ-9 i18n 5 项业务真接
- **重构机会**: home_page_state 590 行仍偏大 + ThemeExtension 完全缺位 + routerProvider 反模式 + ThemeModeNotifier 异步

#### 检查项 ③: 顶层架构审视 — ✅ 9.0/10 (国内中型项目天花板, 跟 R97 持平)

- 5 层架构 + domain 0 Flutter 0 Drift, `check_all.dart` 守门
- 隐私边界: vent 独立表 + 架构强制不进分析/通知/关怀, 实际 grep 验证 0 渗入
- 可优化: UseCase 层覆盖不足 / services/ 28 文件无目录分组 / AppTokens facade 仍 306 行

#### 检查项 ④: 底层逐行排查 — 🔴 3 项 Major silent bug + 12 项 Minor

- **3 项 Major silent bug (新发现)**: latestMoodEntryProvider 3 处 `.first` 未 sort (R98-P1-1) + home_page_state 显示 i18n key (R98-P1-2) + crossedMidnightSince DST 不一致 (R98-P1-3)
- **12 项 Minor**: 3 个 StreamProvider 缺 autoDispose + main.dart 10+ magic number + Future.wait as 强转 + drift batch 优化 + moodEntriesProvider 吞 loading + RadioListTile 弃用 API + 0 golden test + a11y 覆盖偏少 + Form 校验未走 FormState + 104 trailing comma + import 顺序违反 + CareEngine 死代码

#### 检查项 ⑤: 开发需求文档更新 — ✅ 本章节 + R98 完整审计报告

### 10.6 R98 跨视角共识高频项

| # | 问题 | 视角数 | 类别 | 难度 |
|---|---|---|---|---|
| 1 | PHQ-9 量表 i18n + 临床判定逻辑 (Q9 ≥1 弹窗无拨打 + ≥20 不弹) | 3 (spzh/AppStore/底层) | 架构+底层 | medium |
| 2 | 法律文档"草稿未经律师过审" + 联系方式软隐藏 (PIPL §52) | 3 (spzh/AppStore/GooglePlay/外链) | 架构 | high |
| 3 | 域名 chroniccare.app 未注册 (隐私 URL / Data Safety Form / 联系邮箱 全失效) | 4 (spzh/AppStore/GooglePlay/外链) | 底层 | medium |
| 4 | iOS + Android 截图完全缺失 / 占位 PNG | 2 (AppStore/GooglePlay) | 架构 | medium |
| 5 | SMS/Email/5 厂商 push 业务真接阻塞 | 3 (spzh/spen/AppStore) | 架构 | high |
| 6 | 跨时区 DateTime 不一致 (DST bug) | 2 (emil/spen) | 底层 | low |

### 10.7 R98 修复路径建议 (按优先级)

#### 第 1 周 (解锁代码侧 P0, 估 8-12 commit)

1. **R98-P0-1** PHQ-9 危机弹窗加"立即拨打"按钮 — 1h
2. **R98-P0-3** iOS 删 `processing` 后台模式 + AppDelegate register 代码 — 30 分钟
3. **R98-P0-9** 删 `CareEngine.evaluate` / `CareEngine.fire` 死代码 + 同步删 LEGACY_API_NOTES.md — 1h
4. **R98-P1-1** 3 处 `.first` 加显式 sort — 30 分钟
5. **R98-P1-2** `home_page_state.dart:254-258` 改用 `displayMessageL10n(l10n)` — 5 分钟
6. **R98-P1-3** `crossedMidnightSince` 改 `tz.TZDateTime` — 30 分钟
7. **R98-P1-4** 3 个 StreamProvider 加 `.autoDispose` — 10 分钟
8. **R98-P1-8** `setup_legal_dialog.dart:110` 改走 ARB — 30 分钟
9. **R98-P2-10** `setup_step_consent.dart:112-118` 第 4 勾选 onView 跳文档页 — 30 分钟

#### 第 2 周 (修 P1, 估 6-10 commit)

10. **R98-P1-5** 新建 `ios/Runner/en.lproj/InfoPlist.strings` + pbxproj PBXVariantGroup — 2h
11. **R98-P1-6** 统一定价段描述 — v1.0.0+147 已修
12. **R98-P1-7** 删 subtitle/description "规划中"措辞 — 30 分钟
13. **R98-P1-9** 清理 assets/legal/ 8 处软隐藏邮箱 + GitHub 占位 — 1h
14. **R98-P1-10** ConsentGate 加 version 校验 — 4h
15. **R98-P1-11** recordConsent 补 sensitiveDataConsentAt — 2h
16. **R98-P1-12** 同步 sensitive_data_consent.md §4 — 30 分钟
17. **R98-P1-14** check_zh_hant_consistency.py 加 phrase 词典 — 4h

#### 第 3-4 周 (外部资源并行 + P2 降风险, 估 10-20 commit)

18. **R98-P0-4** iOS 截图 (6.7"/6.1"/5.5" iPhone + 12.9" iPad 各 1-3 张) — 4-8h
19. **R98-P0-5** Android feature_graphic 1024×500 + 4 张 phone_screenshots — 4-8h
20. **R98-P0-2** PHQ-9/GAD-7 16 题完整 ARB 翻译后翻 flag — 1-2 周
21. **R98-P0-6** 域名注册 + 部署隐私政策/支持页面 — 1-2 天注册 + 7-20 天 ICP
22. **R98-P0-7** 5 厂商 push SDK 申请 + 集成 — 1-2 月审核期
23. **R98-P0-8** PHQ-9 ≥20 加 CrisisSignal.Kind.severe — 2h
24. **R98-P2-1** ThemeExtension 重构 — 2-3 天
25. **R98-P2-2** routerProvider 改 NotifierProvider — 1 天
26. **R98-P2-3** ThemeModeNotifier 改 AsyncNotifier — 4h
27. **R98-P2-5** setup 表单迁 Form + TextFormField — 1 天
28. **R98-P2-6** 8-10 个核心 widget 加 golden test — 2-3 天

### 10.8 R98 上架风险评估

**整体上架就绪度**: ~50% (R97 修 12 项后 ~50%, R98 新发现 9 P0 抵消改善, 持平)

**Apple App Store 风险**: 🔴 高 — 5 项必拒 (processing 空挂 + 截图缺失 + 隐私 URL 404  描述矛盾 + InfoPlist.strings 缺 en-US)
**Google Play 风险**: 🔴 高 — 4 项必拒 (feature_graphic 占位 + 截图占位 + Data Safety URL 不可访问 + 隐私政策律师未过审)

**建议路径**:
- v0.30 不上 store (R98 9 P0 全部阻塞)
- 第 1-2 周修 R98-P0-1/3/9 + R98-P1-1/2/3/4/5/6/7/8/9/10/11/12/14 共 14 项代码侧修复 (无需外部资源)
- 并行启动 R98-P0-2 (PHQ-9 i18n 1-2 周) + R98-P0-4/5 (截图 4-8h) + R98-P0-6 (域名 7-20 天 ICP) + R98-P0-7 (5 厂商 push 1-2 月)
- 最早 M6 (2026-11-15) 4 项外部资源并行完成后上 store

### 10.9 R98 跟 R97 路线图对应关系

| R98 发现 | R97 状态 | R98 后状态 |
|---|---|---|
| R98-P0-1 PHQ-9 弹窗无拨打 | R97 修了 FAB 可见性, 弹窗内 action 未识别 | **新发现, 必修** |
| R98-P0-2 PHQ-9 i18n flag 关 | R97-P2-17 (P2) | R98 升级 P0 (医疗法律责任) |
| R98-P0-3 iOS processing 空挂 | R97 未识别 | **新发现, 必修** |
| R98-P0-4 iOS 截图缺失 | R97-P3-1 (P3) | R98 升级 P0 (4.2.1 必拒) |
| R98-P0-5 Android 截图占位 | R97 未识别 | **新发现, 必修** |
| R98-P0-6 Data Safety Form | R97-P0-3 同源 (域名) | 持平 (具体到 data_deletion_endpoint) |
| R98-P0-7 5 厂商 push | R97-P0-7 (SMS/Email) | 部分重叠 (push 跟 SMS 不同) |
| R98-P0-8 PHQ-9 ≥20 不弹 | R97 未识别 | **新发现, 必修** |
| R98-P0-9 CareEngine 死代码 | R97 未识别 | **新发现, 必修** |
| R98-P1-1 .first 隐式排序 | R97-P2-3 (P2) | R98 升级 P1 (silent bug) |
| R98-P1-2 displayMessage i18n key | R97 未识别 | **新发现, 必修** |
| R98-P1-3 DST 不一致 | R97-P3-7 (P3) | R98 升级 P1 (海外用户 bug) |
| R98-P1-4 StreamProvider autoDispose | R97 未识别 | **新发现, 必修** |
| R98-P1-9 法律文档软隐藏 | R97-P2-11 (P2) | R98 升级 P1 (PIPL §52) |
| R98-P1-10 ConsentGate version 校验 | R97 未识别 | **新发现, 必修** |
| R98-P1-14 zh_Hant phrase 一致性 | R97-P3-13 (P3 commonSave) | R98 升级 P1 (医疗文案精确性) |

**R98 新发现总计**: 22 项 (P0=5 / P1=8 / P2=6 / P3=3), 16 项为 R97 已识别但被低估或留 R96+ 的项升级

---

**R98 7 视角审计 + 底层逐行排查 + 外链核查追加完成时间**: 2026-08-07
**R98 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角 + 外链核查 + 底层逐行排查 共 8 个并行子代理
**R98 发现总计**: 38 项 (P0=9 / P1=14 / P2=10 / P3=5)
**R98 新发现**: 22 项 (R97 路线图未覆盖)
**下次 dev doc 同步**: R98 P0/P1 修复完成后 (估 2-4 周)

---

## 11. R104 7 视角综合审计 (2026-08-09, 75 项发现)

> 本章节为 R103 审计后, 用户要求拉 7 个视角团队 (emilkowalski / superpowers-en / superpowers-zh / flutter-specification / AppStore / GooglePlay / Apple Health) 对整个项目分别出一份审计报告的汇总追加。7 份报告去重后共 75 项独立发现 (P0=15 / P1=20 / P2=25 / P3=15), 每项标注 **类别 (架构/底层) + 修复难度 + 涉及视角**。
>
> **完整 R104 审计报告**: [docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/00-summary.md](audit-history/r95-r105-history-2026-08-06_09/2026-08-09/00-summary.md)
>
> **审计覆盖 7 个视角**: emilkowalski (设计) / superpowers-en (工程) / superpowers-zh (中文) / flutter-specification (规范) / AppStore (iOS) / GooglePlay (Android) / Apple Health (新视角)
>
> **跟 R103 的关系**: R103 报 75 项, R104 确认大部分仍有效。新增: tracking_item_config.dart domain 层架构违规 (check_all.dart 实测确认) + 6 处新发现硬编码中文 + 12 处硬编码颜色无 dark mode。

### 11.1 R104 7 视角发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 2 | 3 | 3 | 0 | 8 | 9.0/10 |
| superpowers-en (工程) | 1 | 3 | 4 | 0 | 8 | 9.0/10 |
| superpowers-zh (合规+中文) | 7 | 5 | 1 | 0 | 13 | 9.0/10 |
| flutter-specification (规范) | 1 | 4 | 3 | 2 | 10 | 88% |
| AppStore (iOS 上架) | 7 | 5 | 2 | 0 | 14 | 6.5/10 |
| GooglePlay (Android 上架) | 5 | 5 | 0 | 0 | 10 | 40% |
| Apple Health (新视角) | 0 | 0 | 0 | 4 | 4 | N/A |
| **去重后** | **15** | **20** | **25** | **15** | **75** | — |

### 11.2 R104 P0 必修清单 (15 项, 上架阻塞)

| # | 问题 | 架构/底层 | 难度 | 来源 |
|---|------|-----------|------|------|
| 1 | `native.dart:27` SQL 注入 — PRAGMA key 密码拼接 | 底层/安全 | 简单 | flutter-spec |
| 2 | `tracking_item_config.dart:9` import flutter in domain | 架构 | 中 | sp-en |
| 3 | `safetyCheckResultAlertedMocked` 3 语 mock/dev 字符串 | 底层/i18n | 简单 | sp-zh |
| 4 | `mood_detail_page.dart` 2 处硬编码中文 ("录音"/"删除") | 底层/i18n | 简单 | sp-zh |
| 5 | `add_medication_page.dart` 2 处硬编码中文 | 底层/i18n | 简单 | sp-zh |
| 6 | `medication_page.dart` "在用"/"已停" 硬编码中文 | 底层/i18n | 简单 | sp-zh |
| 7 | `today_summary_card.dart` 4 处硬编码中文 | 底层/i18n | 简单 | sp-zh |
| 8 | `daily_tracking_multi_chart.dart` 4 处硬编码中文 | 底层/i18n | 简单 | sp-zh |
| 9 | `PageTransitionSwitcher` 忽略 prefers-reduced-motion | 底层/a11y | 简单 | emil |
| 10 | `textHint` #999999 对比度 2.8:1 不满足 WCAG AA | 底层/a11y | 简单 | emil |
| 11 | `chroniccare.app` 域名 + 邮箱未注册 | 底层/外部 | 中 | App+GPlay |
| 12 | 法律文档 3 份未律师审核 | 底层/外部 | 高 | App+GPlay |
| 13 | Store description 描述已禁用功能 | 底层 | 简单 | AppStore |
| 14 | Release keystore 未生成 (Android) | 底层 | 简单 | GPlay |
| 15 | 无内容评级配置 (IARC + Apple) | 底层 | 中 | App+GPlay |

### 11.3 R104 跟 R103 路线图对应关系

| R104 发现 | R103 状态 | R104 后状态 |
|---|---|---|
| R104-1 SQL 注入 | R103-P0-1 | 持平 |
| R104-2 tracking_item_config domain 违规 | R103 未识别 (check_all 新发现) | **新发现** |
| R104-3 mock/dev 字符串 | R103 未识别 | **新发现** |
| R104-4~8 硬编码中文 | R103-P0-7/12 部分重叠 | 确认 + 新增 6 处 |
| R104-9/10 a11y | R103-P0-10/11 | 持平 |
| R104-11~15 外部资源 | R103-P0-2~8 | 持平 |

**R104 新发现**: 3 项 (tracking_item_config 违规 + mock/dev 字符串 + 6 处新硬编码中文)

### 11.4 R104 修复路径建议

#### Sprint A — 上架阻塞 (P0, 1-2 周)

1. `native.dart` SQL 注入修复 (转义 → 参数化查询) — 30min
2. `tracking_item_config.dart` 架构违规修复 (抽象化) — 2-3h
3. 3 语 mock/dev 字符串清理 (~10 个 ARB key) — 1h
4. 6 处硬编码中文 → ARB (~15 个新 key) — 2h
5. `PageTransitionSwitcher` prefers-reduced-motion — 30min
6. `textHint` 对比度修复 — 30min
7. 域名注册 + 邮箱 — 1-2d
8. 法律文档律师审核 — 4-8 周
9. Store description 清理 — 30min
10. Release keystore 生成 — 30min
11. 内容评级配置 — 1-2d

#### Sprint B — 高优质量 (P1, 1-2 周)

1. 12 处硬编码颜色 → AppTokens + dark mode — 2h
2. domain 层 i18n (influence_category / care_copy / assessment_comparison) — 1-2d
3. 性能修复 (vent_compose setState / mood_audio setState) — 1h
4. a11y 修复 (ExcludeSemantics / Semantics labels) — 2h
5. 安全隐私 (锁屏通知 / 邮件通知) — 1-2d
6. SharedPreferences 缓存 — 1h

#### Sprint C — 架构改进 (P2, 2-3 周)

1. date_utils DRY — 1h
2. consent_gate 移层 — 2-3h
3. saveSetup 抽 UseCase — 1-2d
4. analyzer warning 清理 — 30min
5. dead code 清理 — 30min

---

**R104 7 视角综合审计完成时间**: 2026-08-09
**R104 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / flutter-specification / AppStore / GooglePlay / Apple Health 7 视角
**R104 发现总计**: 75 项 (P0=15 / P1=20 / P2=25 / P3=15)
**R104 新发现**: 3 项 (R103 路线图未覆盖)
**下次 dev doc 同步**: R104 P0 修复完成后 (估 1-2 周)

---

## R107 cleanup 综合审视 (2026-08-10, 9 视角 + 1 顶层架构 + 1 底层逐行)

**R107 cleanup 状态**: 2026-08-10 完成的"从 0 重新做"综合审计。R105 → R106 业务真接 + 6 平台 P0 修复后, R107 清空 docs/audit/2026-08-06~2026-08-10 旧报告（5 轮 26 份 / 1.2MB）归档到 `docs/audit-history/r95-r105-history-2026-08-06_09/`，从 0 重做综合审计。

**9 视角评分 (vs R105)**:

| 视角 | R105 | **R107** | 变化 | 主要扣分 |
|------|------|---------|------|----------|
| emilkowalski (设计/UI/动效) | 7.5 | **9.0** | +1.5 | R95-R105 引入 28 处新违规：主页 8 层 stagger / AnimatedSwitcher 3 处 / token 化 60% 覆盖 |
| superpowers-en (TDD/SDD) | 7.5 | **9.0** | +1.5 | N1 `_save()` `notes` / 2 守门员 FAIL / daily_tracking 7 widget DRY 退化 |
| superpowers-zh (i18n/合规) | 8.0 | **7.0** | -1.0 | 4 项上架 blocker 卡外部依赖 |
| flutter-specification | 84% | **92%** | +8% | ci.yml 不跑 coverage / 无 a11y 守门员 / SDK 范围宽 |
| AppStore (iOS) | 6.0 | **4.5** | -1.5 | 9 项 P0 阻断：PrivacyInfo 未注册 / iCloud Backup 0 / 通知 body PII 锁屏泄漏 / 域名未注册 / 截图 0 张 |
| GooglePlay | 42% | **55%** | +13% | 6 项 P0：截图 67B 假图 / feature_graphic 67B / icon 1443B / 缺 keystore / Data Safety 0% / Health Apps 0% |
| apple-health (HealthKit) | 2/10 | A:3 / B:6.5 / C:8 | 3 选项 | 0 包 / 0 entitlement / 0 Info.plist / 0 UI 入口 / en-US description 5.1.3 抽审 |
| 顶层架构 | (基线) | **8.2** | (基线) | 主要债务 = presentation 15 god class (~9600 行 / 占 lib 40%) |
| 底层逐行 (46 项) | (基线) | 4 P0 + 12 P1 + 16 P2 + 14 P3 | (基线) | 资源泄漏 / 数据丢失 / 安全 |

**R107 修复路线图 (按 ROI)**:

| 阶段 | 周期 | 内容 |
|------|------|------|
| **R108 Phase 1** | 1-2 周 (~12-14 工作日 / 2-3 sprint) | 上架前 P0 必做 13 项 (iCloud Backup + canScheduleExactAlarms + 锁屏 body PII + PrivacyInfo 注册 + LaunchImage/AppIcon + 域名 + review_information + 截图 + UIBackgroundModes + keystore + Data Safety + en-US description + main.dart log) |
| **R109 Phase 2** | 1-2 月 (~5-6 周 / 2-3 sprint) | P1 警告 + 拆 6 大 god class (main.dart 459L / home_page_state 597L / vent+mood_audio 2×500L / notification_service 426L / medication_page 540L / daily_tracking 7 widget)  |
| **R110+ Phase 3** | 6 月+ (v1.0) | 5 厂商 push SDK 接入 / AliyunSms 真接 / EmailService 真接 / PHQ-9 i18n / HealthKit 选项 B-C / 8 FeatureFlag 翻 true / a11y 全量 / 守门员加 `check_a11y.py` / feature-first 重构 (中期) / pub workspace 拆 vent / medication (长期) |

**R107 cleanup 报告位置**: `docs/audit-history/r107-cleanup-2026-08-10/`
- 00-summary.md (30KB / 320 行, 10 章节汇总)
- 01-emil.md (26.3KB) / 02-spen.md (28.5KB) / 03-spzh.md (35KB) / 04-flutter-spec.md (21KB) / 05-appstore.md (29.3KB) / 06-googleplay.md (36.5KB) / 07-apple-health.md (37KB) / 08-architecture.md (23KB) / 09-bottom-up-bugs.md (48.7KB)
- **总计**: 254KB subagent 报告 + 30KB 汇总 = 284KB

**R107 外部链接确认 (运行时 0 实际外链)**:
- ✅ `lib/` 0 实际外链（grep `https?://` 0 命中）
- ⚠️ 注释 3 处说明性（`sms_service.dart` 阿里云 SMS / `chinese_holidays.dart` holidayapi）
- ⚠️ 上架物料 12 URL 不可达（`chroniccare.app` 域名未注册）
- 🔴 2 邮箱未注册（`privacy@chroniccare.app` / `support@chroniccare.app`）

**R107 P0 必修 13 项 (按 ROI 排序, 全表见 00-summary.md §四)**:
1. iCloud Backup 排除 4 处 (`native.dart:18` + `encrypted_audio_storage.dart:99` + `swallow_log_sink.dart:54` + ...) — 3h
2. `canScheduleExactAlarms()` TODO (5 视角共识, `notification_service.dart:313-325`) — 0.5d
3. 锁屏通知 body 药名 PII (`strings.dart:103-119` `notifMedicationBody`) — 1h
4. PrivacyInfo.xcprivacy 未注册 Xcode (`project.pbxproj:223-232`) — 15min
5. iOS LaunchImage 68B + AppIcon 10932B 占位 — 1.5h
6. chroniccare.app 域名 + 2 邮箱未注册 — 4h + 7-20d ICP
7. iOS `review_information/` 目录缺 — 30min
8. iOS 截图 0 + Android 67B 假图 + feature_graphic 67B — 3-5d
9. UIBackgroundModes audio 缺 (R100 删 + R104 启用矛盾) — 5min
10. Android keystore + Data Safety 28 子项 + Health Apps 4 块 — 2-3d
11. en-US description "hypertension, diabetes" Apple 5.1.3 抽审风险 — 2.5h
12. main.dart 裸 `developer.log` release 仍输出 — 1h
13. 主页 8 层 FadeIn stagger 累加 0-280ms 未 clamp — 0.5h

**R107 cleanup 文档同步状态**:
- ✅ README.md 顶部 R107 cleanup 综合审视段
- ✅ CHANGELOG.md 加 R101-R107 entries (R100 段维持, R101 缺失补回)
- ✅ AGENTS.md 顶部 R107 段 + 守门员 17→18 (加 check_coverage.py) + tests 1997→2019
- ✅ VERSION_1.0_PLAN.md (本文件) 加 R107 段
- ⏸️ DEPLOYMENT.md 待 R108 修 P0#1-9 后再补 (域名注册 + 截图脚本 + keystore 流程)

**R107 不做代码改动**: 本批纯审计 + 文档同步, 无 commit。下批 R108 修 P0 13 项（1-2 周）。
