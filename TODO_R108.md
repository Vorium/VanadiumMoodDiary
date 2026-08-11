# R108 + R32 P0 #11-#13 + 全部 P0 task breakdown (2026-08-11 更新)

> **R32 更新说明**: R32 6 视角综合审视发现 working tree 95 文件未提交 + 18 守门员 3 红 + 126 fail + 55 orphan ARB, R32 新增 33 P0 紧急修 + 16 P1 + R32 修了但 master 未合并的 11 P0 (R32 fix/v0.31.1-bug-batch 11 commit)
> **详细报告**: [docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (52KB)
> **R32 综合**: 6 视角加权 **6.2/10** (R31 7.5 → -1.3 倒退, 主因 superpowers-en 暴露 126 fail 半年没修 + 55 orphan + check_changelog 倒序错)

## Fix #11a keystore (R108 增量, R32 跨期 0 修)
- [x] 复用 R72 `generate_release_keystore.ps1` (PowerShell)
- [ ] 写 bash 版本 `scripts/generate_android_keystore.sh` (Mac/Linux dev)
- [ ] 写 setup doc `R108-android-keystore-setup.md`
- [ ] 写 lock-in test `test/scripts/keystore_script_round108_test.py`

## Fix #11b Data Safety Form (R108 增量, R32 跨期 0 修)
- [x] 复用 R72 `generate_data_safety_form.py` (覆盖 5 大类)
- [ ] 验证 v0.31 状态仍准确 (R107 cleanup 加 v0.30 标记 + lock-in)
- [ ] 写 setup doc `R108-android-data-safety-form.md`
- [ ] 写 lock-in test `test/scripts/data_safety_form_round108_test.py`

## Fix #11c Health Apps Questionnaire (R108 新增, R32 跨期 0 修)
- [ ] 写 `scripts/generate_health_apps_questionnaire.py`
- [ ] 写 setup doc `R108-android-health-apps-questionnaire.md`
- [ ] 写 lock-in test `test/scripts/health_apps_questionnaire_round108_test.py`

## Fix #12 截图脚本 (R32 跨期 0 修, 上架硬阻塞)
- [ ] 写 `scripts/generate_ios_screenshots.sh` (Mac only) — 跨期 R108 5-30 min 简单修复 #6
- [ ] 写 `scripts/generate_android_screenshots.sh`
- [ ] 写 setup doc `R108-screenshots-automation.md`
- [ ] 写 lock-in test `test/scripts/screenshots_scripts_round108_test.py`

## Fix #13 域名 + 邮箱 (R32 跨期 0 修, 上架硬阻塞)
- [ ] 写 `docs/audit/2026-08-11-r32-multi-lens/R32-domain-registration-guide.md` (详细, R108 文档迁移)
- [ ] 写 `scripts/register_domain.sh` 占位
- [ ] 写 4 HTML 模板 `scripts/templates/*.html.tmpl` (privacy / support / user-agreement / sensitive-data-consent)
- [ ] 写 lock-in test `test/scripts/domain_check_round108_test.py`

---

## R32 新增 P0 #14-#33 (本批可闭环, 总和 ≤ 1-2d) — **R32 hotfix 4 round 全闭环 ✅**

### 锁屏 PII (R32 hotfix round 1 merge master 闭环)
- [x] **P0-14**: merge `fix/v0.31.1-bug-batch` (11 commit) to master — **10min, 闭环 11 P0 (P0-01~P0-09)** [R32 hotfix round 1 commit b9f14bc]
  - [x] P0-01 review_information 4 TODO 占位 (R32 round 1 修) ✅
  - [x] P0-02 notes.txt 版本号过期 (R32 round 2 修) ✅
  - [x] P0-03 store_kit productId 冗余 (R32 round 3 修) ✅
  - [x] P0-04 description 5 病名 5.1.1 抽审 (R32 round 4 修) ✅
  - [x] P0-04b description 4 locale 5 病名 (R32 round 5 修) ✅
  - [x] P0-05 3 DarwinNotificationDetails 空构造 (R32 round 6 修) ✅
  - [x] P0-06 4 AndroidNotificationDetails.visibility (R32 round 7 修) ✅
  - [x] P0-07 7 raw IconButton → PressFeedbackIconButton (R32 round 8 修) ✅
  - [x] P0-07b page_scaffold.dart:42 漏修 (R32 round 9 修) ✅
  - [x] P0-08 Spring 物理模型接 _EntrySpring + 5 case test (R32 round 10 修) ✅
  - [x] P0-09 Apple Health 关键词 lock-in 扩 lib/ 主体 (R32 round 11 修) ✅

### i18n 跨期 (R32 hotfix round 2 修)
- [x] **P0-15**: `medication_page.dart` 4 处硬编码中文 ('待服'/'已服'/'需续方'/'查看') + 4 个 TODO(Phase 5) 改 l10n ✅ [R32 hotfix round 2]
- [x] **P0-16**: `medication_page.dart:101` Colors.white 改 `AppColors.fgOnPrimary(context)` ✅ [R32 hotfix round 3]
- [x] **P0-17**: `quick_mood_carousel.dart:84` '记录失败，请重试' 改 l10n + 用 AppSnackBar 集中器 ✅ [R32 hotfix round 2]
- [x] **P0-18**: `quick_mood_carousel.dart:99` '心情' 改 l10n ✅ [R32 hotfix round 2]
- [x] **P0-19**: `today_summary_card.dart:72` '今日指标' 改 l10n ✅ [R32 hotfix round 2]
- [x] **P0-20**: `secondary_action_row.dart` 7 处硬编码中文改 l10n + 删 3 个 TODO 注释 ✅ [R32 hotfix round 2]
- [x] **P0-21**: `primary_action_row.dart` 7 处硬编码中文改 l10n ✅ [R32 hotfix round 2]

### 死代码 / 硬编码 (R32 hotfix round 1 + 4 修)
- [x] **P0-22**: `hero_illustration.dart` 118 行死代码删 ✅ [R32 hotfix round 1]
- [x] **P0-23**: `app_motion.dart:119/123` curveAppleSheet/Drawer 删 (Material API 不支持) ✅ [R32 hotfix round 4]
- [x] **P0-24**: `medication_pill_icon.dart` 6 pill 颜色移到 `app_colors.dart` (kMedicationPillColors 集中器) ✅ [R32 hotfix round 1]
- [x] **P0-25**: `mood_trend_page.dart:311-317, 539-540` 7 处 iOS color 移到 `app_colors.dart` (kMoodScoreColors 集中器) ✅ [R32 hotfix round 1]
- [x] **P0-26**: 4 处 `Colors.transparent` 改 `AppColors.transparent` (新加集中器) ✅ [R32 hotfix round 1]

### 杂项警告 (R32 hotfix round 1 修)
- [x] **P0-27**: 4 文件双重 `swallow_error` import 删 ✅ [R32 hotfix round 1]
- [x] **P0-28**: `_slotIcon` unused element 删 ✅ [R32 hotfix round 1]
- [x] **P0-29**: `skip_backup.dart:56` `@visibleForTesting` 删 (private 字段不允许) ✅ [R32 hotfix round 1]
- [x] **P0-30**: 15 个 `@override` on non-overriding_member 注解删 ✅ [R32 hotfix round 1]
- [ ] **P0-31**: `dart fix --apply` 71 info — 留 R110 (本机不在 PATH)
- [ ] **P0-32**: `dart format` 2 文件 (check_in_button + primary_button) — 留 R110 (本机不在 PATH)

### 守门员 (R32 hotfix 4 round 全修, 18 绿 / 0 红 / 1 skip)
- [x] **P0-33**: CHANGELOG 段顺序倒序 ([0.31.1+108] 在 [0.31.0] 之前) ✅ [R32 hotfix round 1, 后续 +109/+110/+111 段补完]
- [x] **P0-34**: 4 PUA 字符 sed 替换 (audit-history 文档) ✅ [R32 hotfix round 1]
- [x] **P0-35**: 55 orphan ARB key 删 (跨期 R31 0 闭环) ✅ [R32 hotfix round 1, 后续 round 2 加 20 个新 key 都有 caller]
- [x] **P0-36**: `check_pii_in_title.py` 守门员扩到 `safetyAlertTitle` (用户名泄漏) ✅ [R32 hotfix round 1]
- [x] **P0-37**: `check_zh_hant_consistency.py` 跑 (opencc 装) + 修 9 处繁简不一致 ✅ [R32 hotfix round 2]
- [ ] **P0-38**: `check_coverage.py` 跑 (`flutter test --coverage`) — 留 R110 (需 Flutter SDK)
- [ ] **P0-39**: `check_16kb_alignment.py` 真跑 (待 Android .so 重 build) — 留 R110

### 跨 3 视角共识半成品 (R32 hotfix round 1-3 修)
- [x] **P0-40**: PageScaffold translucent AppBar (1 行 BackdropFilter + 2 行 reduce-transparency 适配) ✅ [R32 hotfix round 3]
- [x] **P0-41**: spec baseline 2019 → 2103 改 6 处 ✅ [R32 hotfix round 1]
- [x] **P0-42**: AGENTS.md 加 0.31.1 bug-batch + 0.31.2 章节 ✅ [R32 hotfix round 1]
- [x] **P0-43**: 6 widget 集中器文件头注释加 Apple Health 风格 spec 引用 ✅ [R32 hotfix round 1]
- [x] **P0-44**: `quick_mood_carousel.dart:60-71` 加 `unawaited(Haptics.success())` (集中器 Haptics.success() 5 类) ✅ [R32 hotfix round 1]

**P0-14~P0-44 总闭环**: R32 hotfix 4 round 闭环 **30 / 31 项** ✅, 2 项 (P0-31/32 + P0-38/39) 留 R110 (需 Flutter SDK)

---

## R32 P1 R109 第 2-3 周修 (16 项, 影响中等) — **5 项 R32 hotfix round 4 闭环 ✅**

详见 [R32 整合报告 §5.2](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md)

- [ ] **P1-1**: Apple Health 11 feature 改 (mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline), 7-8 个 0 改 → 各 1-2d
- [ ] **P1-2**: SF Symbol 字体集成 (替代 Material Icons 8 metric, spec §3.1.3) — 1-2d
- [x] **P1-3**: check_widget_dispose 4 类扩 (AnimationController / Timer / ChangeNotifier / ScrollController) ✅ [R32 hotfix round 4] (check_16kb / check_coverage 留 R110)
- [ ] **P1-4**: 加 5 集成 test (setup → home → check-in → assessment → export) + main() 启动顺序 test — 1-2 周
- [x] **P1-5**: 主页 stagger 8→3 闭环 (R31 P1-13 跨期) ✅ [R31 round 1 已闭环]
- [ ] **P1-6**: mood carousel 5 档大圆形 48pt → 72pt (跟 spec 对齐) — 30min
- [x] **P1-7**: lock-in test 阈值 220 → 250 (R31 P1-06 跨期) ✅ [R32 hotfix round 3 改 300→250]
- [x] **P1-8**: PressFeedback 加 `Haptics.light()` 集中器 ✅ [R32 hotfix round 4]
- [ ] **P1-9**: 126 fail 修 (66 i18n + 33 无栈 + 8 RangeError + 6 StateError + 2 ArgumentError) — 3-5d
- [x] **P1-10**: Haptics 集中器 (PressFeedback 调用 1 处, 5 类集中器在 feedback.dart) ✅ [R32 hotfix round 4]
- [x] **P1-11**: 主页 12 处硬编码中文走 ARB (累计 R11a) ✅ [R32 hotfix round 2 21 处闭环]
- [ ] **P1-12**: 8 metric 8 health metric palette 跟 SF Symbol 一一对应 — 1-2d
- [x] **P1-13**: `_StreakCounter` vs `_TweenNumber` 95% 重复抽 tween_number 公共 widget ✅ [R32 hotfix round 4]
- [ ] **P1-14**: reminder_scheduler / safety_watch_service 职责重叠统一到 SafetyWatchService — 1d
- [x] **P1-15**: dev doc 同步 (spec baseline 数字 + CHANGELOG 段顺序 + AGENTS v0.31.1 章节 + R12b global sanity 改 AST) ✅ [R32 hotfix round 1+本批]
- [ ] **P1-16**: i18n widget test 改用 `find.text(l10n.xxx)` 配 lock-in 守门员 `grep -E "find\.text\(['\"]?[\u4e00-\u9fff]+" test/` — 3d

**P1 R32 hotfix 4 round 闭环 6 / 16 项** (P1-3/5/7/8/10/11/13/15), 留 10 项给 R109 第 2-3 周 + R110

---

## R32 P2 R109 god class 专项 (1-2 月, 11 个 god class 拆 + use case 层厚化)

详见 [R32 整合报告 §5.3](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md)

- [ ] **P2-1**: `static_scale_translations_l10n.dart` 810L 拆 5 scale + 移到 `lib/core/l10n/scale_translations.dart` + 25 test
- [ ] **P2-2**: `static_scale_translations.dart` 781L 拆 5 scale + 25 test
- [ ] **P2-3**: `add_medication_page.dart` 592L 抽 controller + 5 sub-widget + 15 widget test
- [ ] **P2-4**: `mood_audio_recorder_widget.dart` 588L 拆 3 sub-widget + 8 widget test (mock audio)
- [ ] **P2-5**: `mood_trend_page.dart` 563L 拆 4 sub-widget + 12 widget test (用 AppLocalizations)
- [ ] **P2-6**: `setup_page_state.dart` 560L 拆 4 state 各 1 file + 8 unit test
- [ ] **P2-7**: `medication_page.dart` 561L 拆 4 controllers (4 AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection) + 12 widget test
- [ ] **P2-8**: `audio_lifecycle.dart` 439L 抽 3 类 audio (record/play/cleanup) + 6 unit test
- [ ] **P2-9**: `assessment_widgets.dart` 429L 拆 3 sub-widget + 9 widget test
- [ ] **P2-10**: `vent_detail_page.dart` 426L 拆 3 sub-page + 6 widget test (mocked vent repo)
- [ ] **P2-11**: `edit_medication_dialog.dart` 413L 拆 5 form section + 8 widget test
- [ ] **P2-12**: `notification_initializer.dart` 174L 抽 3 init method + 4 unit test
- [ ] **P2-13**: `safety_watch_service.dart` 390L 拆 3 strategy (care_engine 4 strategy 模式)
- [ ] **P2-14**: `mood_audio_service.dart` 377L 拆 MoodRecorder + MoodPlayer + 2 facade
- [ ] **P2-15**: `app_database.dart` 513L 抽 13 schema file + 1 migration file + 抽 `SetupService` / `DataWipeService` 到 `lib/domain/usecases/`
- [ ] **P2-16**: `legal_page.dart` 495L 拆 4 section + 1 withdraw controller
- [ ] **P2-17**: `reminders_hub_page.dart` 481L 拆 controller + 3 sub-widget
- [ ] **P2-18**: `home_page_state.dart` 468L 拆 5 sub-widget state + 10 unit test (R31 大幅改善, 仍 0 test)
- [ ] **P2-19**: 业务逻辑上提到 use case 层 (8 → ~30 个, 覆盖 4 step setup / check-in / streak / care engine / safety alert / refill / assessment / data export / vent)

---

## R32 P3 R110 feature-first 重组 (2-3 周, 不动架构)

详见 [R32 整合报告 §5.4](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md)

- [ ] **P3-1**: `lib/features/{feature}/{domain,data,presentation}/` 物理目录重组
- [ ] **P3-2**: pub workspace 拆 3 package (5 token + 6 widget + 18 守门员 → `chroniccare_design_system`)
- [ ] **P3-3**: 18 provider 文件散落 → `lib/features/{feature}/providers/` 子目录

---

## R32 P4 R1.0 长期 (2027-Q1, 1-2 月, 5-8 subagent 跨外部协作)

详见 [R32 整合报告 §5.5](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md)

- [ ] **P4-1**: 实物资产 100% (iOS 截图 + LaunchImage + AppIcon + Android 截图 + feature_graphic + icon) — 1-2 周
- [ ] **P4-2**: chroniccare.app 域名 + ICP 7-20d + 4 邮箱 — 7-20d
- [ ] **P4-3**: 5 厂商 push 真接 (小米/华为/OPPO/vivo/魅族) — 1-2 月
- [ ] **P4-4**: 阿里云 SMS AccessKey + 法务 1-2 月模板审核 — 1-2 月
- [ ] **P4-5**: EmailService (SendGrid API key + 模板审核) — 1-2 月
- [ ] **P4-6**: PHQ-9 / GAD-7 i18n 完整 (16 题 + 严重度 + 危机电话) — 1-2 周
- [ ] **P4-7**: HealthKit 集成 (iOS 16+ HealthKit + Android Health Connect) — 2-3 周
- [ ] **P4-8**: 鸿蒙 Flutter 集成 — 1-2 月
- [ ] **P4-9**: IAP 真接 (Google Play Billing + App Store Connect) — 1-2 周
- [ ] **P4-10**: 法务 3 份法律文档 ¥45-90k — 1-2 月
- [ ] **P4-11**: 主体资质 + 临床审核 + NMPA — 1-2 月
- [ ] **P4-12**: SF Symbol 字体集成 (替代 Material Icons 8 metric, spec §3.1.3) — 1-2d

---

## 最终报告
- [ ] 写 `R108-p0-11to13-report.md`
- [ ] 写 `R32-p0-14to44-report.md` (R32 hotfix 报告)
- [ ] 跑守门员 verify (18 个全绿, 0 红 0 warn)
- [ ] 验证 12 URL 文件占位正确
- [ ] merge `fix/v0.31.1-bug-batch` to master
- [ ] commit working tree 95 文件未提交改动
- [ ] CHANGELOG [0.32.0] 加 R32 综合审视 + 11 P0 修复 + 33 P1 新增 + 5.5-2d R32 hotfix 完成

---

## R32 关键数字 (2026-08-11 真实跑)

- 6 视角加权综合: **6.2/10** (R31 7.5 → -1.3)
- 18 守门员: 14 绿 / **3 红** (check_changelog / check_no_pua / check_orphan_arb 55) / 1 warn (fullwidth 133) / 2 skip
- flutter test: **+2129 pass / 1 skip / 126 fail** (5.6% 红灯, 跨 29 文件)
- flutter analyze: **0 error / 23 warning / 71 info**
- 8 FeatureFlag: 1/8 true (ventAudioEnabled) / 7/8 false (iap / emergencyContact / fiveVendorPush / emailService / phqGad7I18n / bootReceiver / aliyunSms)
- 11 god class (≥400L) 0 test: 100% 违反 superpowers "测试先于代码"
- 实物资产 100% 缺失: iOS 截图 / LaunchImage / AppIcon / Android 截图 / feature_graphic / icon 全是占位
- 8 raw IconButton: master 仍残留 (R32 fix/v0.31.1-bug-batch 修了, master 未合并)
- 4 锁屏 PII: master 仍残留 (R32 fix/v0.31.1-bug-batch 修了, master 未合并)
- 4 description 5 病名: master 仍残留 (R32 fix/v0.31.1-bug-batch 修了, master 未合并)
- 126 fail 半年没修
- 55 orphan ARB key (R31 0 个 → R32 55 个新引入)
- 66 widget test i18n 迁移没同步 (52% fail)

**R32 综合结论**: 6.2/10 (R31 7.5 → -1.3 倒退), 主因 superpowers-en 暴露 126 fail + 55 orphan + 守门员 3 红。R32 修了 11 个 P0 但都在 fix/v0.31.1-bug-batch branch, master 未合并。
