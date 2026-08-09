# R109 待修 Bug 清单 (2026-08-10)

> **作者**: Mavis
> **基线**: R108 P0 + P1 4 god class 拆完成（详 R108-overall-report.md）
> **状态**: R109+ 待跑（因 R108 Subagent E + F token 限制中断，R109 接续 P2/P3）
> **总剩余**: 3 半成品收尾 + 17 P2 + 10 P3 + 13 外部依赖 = 43 项

---

## 一、半成品收尾（R109 Phase 1, 1-2 天）

### S1-1: `notification_service.dart` 482L → 350L（-30%）
- ✅ 已用 `NotificationDelegate` 字段
- ⚠️ 12 委派 method 仍可能在 facade + delegate 都有（重复定义）
- ⚠️ 旧字段未删：`reminderDispatcher` / `snoozeManager` / `badgeSync` / `medicationNotifier` / `refillNotifier` / `assessmentNotifier` / `moodReminderNotifier`
- **修复**: 删 facade 重复 method，删 facade 旧字段（已搬到 delegate），保留 init / requestPermission / showNow / cancelAll / pendingCount / showSafetyAlert + delegate 字段

### S1-2: `mood_audio_recorder_widget.dart` 587L → 400L（-32%）
- ✅ `with AudioLifecycleMixin<MoodRecorder>` (line 59)
- ✅ 4 抽象方法 override
- ⚠️ 旧字段可能未删：`_isRecording` / `_isPlaying` / `_audioPath` / `_tempDecryptedPath` (mixin 已有)
- ⚠️ 旧 `_asyncDispose` 50 行可能仍在
- **修复**: 删旧字段 + 删旧 `_asyncDispose`，保留 mixin 引用

### S1-3: `medication_page.dart` 601L → 480L（-20%）
- ✅ `MedicationTimeSlot` 替代 `_TimeSlot` enum
- ✅ `_buildTimeSlots` 改用 MedicationTimeSlot
- ⚠️ `_TimeSlotCard` 周边新代码（slotIcon / slotLabel 映射）有 +50L 增量
- **修复**: 把 slotIcon/slotLabel 抽到 `medication_slot_calculator.dart` 或新 helper

---

## 二、P2 中度（17 项，估 1-2 周 subagent 跑）

### P2-i18n (3 项)
1. **i18n 36 因子** (`lib/domain/logic/influence_category.dart:36-71`) 走 enum + l10n.influenceCategoryXxx，3 语
2. **care_copy.dart 全文** (`lib/domain/logic/care_copy.dart:33-57`) 走 Strings.careCopyXxx
3. **assessment_comparison 趋势标签** (`lib/domain/logic/assessment_comparison.dart:68-79`) 走 Strings.assessmentComparisonXxx
4. **PHQ-9 / GAD-7 16 题 i18n**（3 视角共识）— 法务临床审核 4-6 周 + 48 翻译
5. **8 量表 i18n 完整化** + 严重度 + 危机电话 6 region 走 hot path

### P2-UI-Token (4 项)
6. **Dynamic Type 适配** — 81 文件 275 处 `fontSize:` → `MediaQuery.textScalerOf` (Apple 2.5.1 必查)
7. **medication_pill_icon 6 个 Color(0xFF...)** (`medication_pill_icon.dart:9-16, 63, 70`) → `AppColors` token
8. **mood_trend_page 5 个 Apple 系统色** 硬编码 → token
9. **AppTokens facade 306 行** 删 → 直接用 AppColors / AppMotion / AppSpacing / AppTypography

### P2-a11y (4 项)
10. **HomeFabToolbar 缺 Semantics label** (`home_fab_toolbar.dart:177-205`, R104 E7)
11. **QuickMoodCarousel 4 emoji 缺 Semantics** (`quick_mood_carousel.dart:160-198`, R104 E8)
12. **10+ 装饰 emoji 缺 ExcludeSemantics**
13. **装饰 icon 缺 ExcludeSemantics** (page_scaffold 周边)

### P2-集中化 (3 项)
14. **SnackBar 散落 12+ 处** → `AppSnackBar` 集中器
15. **loading/error 散落 12+ 处** → `LoadingSkeleton` / `ErrorState` 集中器
16. **windowSizeOf medium breakpoint 不可达** (`app_spacing.dart:132-153`, 调 breakpointMedium=600)

### P2-其他 (3 项)
17. **71 处 `padLeft(2,'0')` 替换** + `_dateOnly` 5 处私有收敛到 `core/shared/date_utils.dart`
18. **42 孤儿 ARB + 16 简繁不一致** (R105 check_orphan_arb_keys FAIL + check_zh_hant_consistency FAIL)
19. **export_import_pipeline 30+ 个 `as` 链** 接 `ExportSchemaService.validateXxx` 全链路

---

## 三、P3 优化（10 项，估 2-3 周）

### P3-工程卫生 (4 项)
1. **ci.yml 加 coverage gate** + a11y 守门员脚本 (`check_a11y.py`)
2. **`assets/brand/_archive/` 30+ MB** 移到 .mavis-trash
3. **dart format + dart fix --apply** 清 trailing_commas 200+ info
4. **6 个测试文件用 `r93_` 简写变体** → `round93_` 重命名

### P3-文档 (2 项)
5. **scripts 根目录 6 个临时 .log 文件** 移到 .mavis-trash
6. **4 类 v* 注释堆叠** (`strings.dart` 改 commit hash 索引)

### P3-god class 进一步拆 (2 项)
7. **home_page_state.dart 515L** (R109 目标 ~300L) — 进一步拆 9 业务方法到 controller
8. **vent_compose_page.dart 445L** — audio_lifecycle mixin 进一步去重 ~50L

### P3-业务 (2 项)
9. **mood_detail_page / mood_factor_analysis / mood_reminder_notifier 3 处死代码** 接线 or 删
10. **_save() notes 字段未持久化** + `colorIndex: 0` TODO (R105 N1)

---

## 四、外部依赖（13 项，估 1-2 月用户执行）

### 上架 (8 项)
1. **chroniccare.app 域名注册** (Cloudflare $15/yr + ICP 备案 7-20d)
2. **iOS 截图** (5 设备 × 3 locale = 15 张) — 需 Mac + Xcode
3. **Android 截图 + feature_graphic + icon** (8 + 4 + 2 张) — 需 Android Studio
4. **release keystore 生成 + Play App Signing** (需 Play Console)
5. **Data Safety Form 28 子项** (Play Console 后台手填)
6. **Health Apps Questionnaire 4 块** (Play Console 后台手填)
7. **iOS signature + DEVELOPMENT_TEAM** (需 Mac + Apple Developer 账号)
8. **TestFlight 100+ 真实用户** (R95 task 60)

### 业务真接 (5 项)
9. **5 厂商 push SDK 接入** (米/华/OPP/vivo/魅族 1-2 月审核) — `fiveVendorPushEnabled`
10. **AliyunSms 真接** (法务 1-2 月 + AccessKey) — `aliyunSmsEnabled`
11. **EmailService SendGrid 真接** — `emailServiceEnabled`
12. **PHQ-9 / GAD-7 16 题法务临床审核** — `phqGad7I18nEnabled`
13. **IAP 8 元买断真接 productId** (App Store Connect) — `iapEnabled`

---

## 五、R109 路线图（按 ROI 排序）

### R109 Phase 1: 半成品收尾 (1-2 天)
- S1-1 notification_service 半成品收尾 → 482→350L
- S1-2 mood_audio_recorder 半成品收尾 → 587→400L
- S1-3 medication_page 半成品收尾 → 601→480L
- 总减重: 168L
- 加 lock-in test 覆盖 audio_lifecycle / notification_delegate / MedicationTimeSlot

### R109 Phase 2: P2 中度 (1-2 周 subagent)
- 4 个 subagent 并行：
  - Subagent H: P2-i18n (5 项)
  - Subagent I: P2-UI-Token (4 项) + P2-集中化 (3 项)
  - Subagent J: P2-a11y (4 项) + P3-god class 进一步拆 (2 项)
  - Subagent K: P2-其他 (3 项: padLeft / orphan ARB / export schema) + P3-工程卫生 (4 项)

### R109 Phase 3: P3 优化 (2-3 周)
- 3 个 subagent 并行：
  - Subagent L: P3-工程卫生 (4 项) + P3-文档 (2 项)
  - Subagent M: P3-god class (2 项) + P3-业务 (2 项)

### R110+: 8 FeatureFlag 翻 true + 真实业务接入
- 13 外部依赖 (估 1-2 月)
- 8 FeatureFlag 翻 true (业务真接完成)
- feature-first 重构 (中期 1-2 周)
- pub workspace 拆 vent / medication (长期 3-6 月)

---

## 六、监控 + 验证

R109 跑完需验证：
- `flutter analyze` 0 error
- `flutter test` 全过（当前 2019 + R108 16 个新 test + R109 预计 20+ 新 test ≈ 2050+ pass）
- 18 守门员全绿（无新 regression）
- 6 视角重新审视（emil / spen / spzh / flutter-spec / appstore / googleplay）评分应提升 0.5-1.0

**加权综合 R109 估**: 8.0 → 8.5-9.0/10

**R110 估**: 8.5-9.0 → 9.0-9.5/10（v1.0 release candidate）
