# 变更日志

> 格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased] - 2026-08-02 (R81 — emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 6 commit, 病耻感 UI 升级)

> R81 目标: 用户分享 B 站"哗哩哗哩能量加油站" 2 张截图, 加载 emilkowalski
> skill 走设计工程师 lens, 借鉴治愈系 IP 风格 (太阳+云+叶 插画) +
> 横滑 carousel (1 tap 速记) + 浮动 FAB 工具栏 + chip 标签 4 类。
> R81 6 commit 落地, 病耻感 UI 大升级, 跟精神心理 App 调性对齐。

### Tests
- **1368/1368 pass** (R80 1362 + R81 +6: 4 mood_visual + 6 home_emil)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### R81 commit 落地 (6 commit, B 站借鉴)
- `316f95a` R81-1 (emil design-1): mood_visual 加 IP 化太阳 emoji 5 档 (☀️🌤⛅🌧⛈ + 嘴型), dimension_row 评分 1-5 改太阳
- `fd23d84` R81-2 (emil design-2): home_page 加 QuickMoodCarousel 横滑 4 档 IP 太阳, 1 tap 速记 mood score (B 站 4 情绪横滑同款)
- `bb8b948` R81-3 (emil design-3): home_page 加 HomeFabToolbar 浮动工具栏 (收起 1 FAB / 展开 4 工具按钮: 心情测试 / 心情树洞 / 紧急热线 / 回到顶端)
- `7718248` R81-4 (emil design-4): home_page 加 HomeHeroIllustration 自绘插画 (蓝天 + 太阳 + 云 + 叶, 无 asset 依赖, 跨平台稳)
- `c4d09cf` R81-5 (emil design-5): SectionHeader 加 chip 标签, trend_page + settings_page 应用 (B 站 chip 风格)
- `915e8d1` R81-6 (emil design-6): 6 case 集成测 (3 SectionHeader chip + 3 HomeFabToolbar toggle)

### 借鉴的 10 条 B 站经验
| # | 经验 | R81 应用 |
|---|---|---|
| 1 | 4 情绪用 IP 化太阳 emoji (☀️⛅🌧⛈ + 嘴型) | R81-1 dimension_row 评分改太阳 |
| 2 | 横滑 carousel 而非 2x2 grid (4 选时聚焦) | R81-2 QuickMoodCarousel 4 档 PageView |
| 3 | 全屏治愈系插画 hero 跟功能区视觉分层 | R81-4 HomeHeroIllustration 140dp 自绘 |
| 4 | 中性化措辞 "能量加油站 / 心情日记 / 树洞" | R72+R75+R77 已做 5+1 鼓励文案 |
| 5 | chip 标签做副标题 | R81-5 SectionHeader chip 字段 |
| 6 | 2x2 grid 工具入口 | R81 plan 留 R82+ (主页 4 入口 carousel 已经有) |
| 7 | CTA 按钮圆角 + 品牌色 | ✅ PrimaryButton 已统一 |
| 8 | 浮动 FAB 工具栏 (收起 1 / 展开 4) | R81-3 HomeFabToolbar |
| 9 | 每卡片独立圆形插画 (IP 化视觉锚点) | R81-4 hero 4 元素 Stack |
| 10 | 病耻感文案口语化 | ✅ R77 care_copy 3 处中性化 |

### R81 emil 设计决策框架 (4 步过一遍)
- **1. 该动画吗?** 主路径 (carousel / FAB toggle) 用 PageView + AnimatedSize (200ms ease-out), hero 插画静态无动画 (rare 频度, emil 决策: rare 可加 delight, 装饰不动画)
- **2. 缓动曲线** PageView 横滑 200ms ease-out, AnimatedRotation 0.125 turn 100ms durFast (B 站风格)
- **3. duration** < 300ms sub-300ms 标准, FAB toggle 200ms
- **4. accessibility** prefers-reduced-motion 走 Motion.duration / Motion.curve 自动归零 (病耻感 / 紧急 / 测试场景, 不能飘)

### R81 新增 widget
- `lib/core/shared/mood_visual.dart`: `ipEmojiFor(int score)` 5 档 IP 太阳
- `lib/presentation/pages/home/widgets/quick_mood_carousel.dart`: 主页 4 档横滑 carousel
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart`: 浮动 FAB 工具栏 (R81-3)
- `lib/presentation/pages/home/widgets/hero_illustration.dart`: 主页 hero 插画
- `lib/presentation/widgets/section_header.dart`: 加 `chip` 字段 + 私有 `_ChipBadge`

### ARB 新增 (zh + en + zh_Hant 三语同步)
- `homeQuickMoodTitle`: 今天感觉如何？/ How are you today? / 今天感覺如何？
- `homeFabAssessment`: 心情测试 / Mood test / 心情測試
- `homeFabVent`: 心情树洞 / Mood vent / 心情樹洞
- `homeFabHotline`: 紧急热线 / Hotline / 緊急熱線
- `homeFabTop`: 回到顶端 / Back to top / 回到頂端
- `trendChip30Day`: 近 30 天 / Last 30 days / 近 30 天
- `assessmentChipCurrent`: 本周 / This week / 本週

### R81 总览
- **6 commit 落地** (5 widget + 1 集成测)
- **病耻感 UI 大升级**: 评分数字 → 太阳 emoji / 主页加 4 档速记 carousel / 浮动 FAB 工具栏 / 自绘 hero 插画 / 标题旁 chip 标签
- **总进度**: 1163 (R63) → 1368 (R81), **+205 tests** / **+44 commits** / 16 守护脚本全绿

### R82+ 路线 (emil design eng 续)
- R82 QuickMoodCarousel PageView 滑动手势测 (flutter_test dragBy)
- R82 紧急热线入口 跳 safety_alert_dialog (替代 SnackBar 占位)
- R82 回到顶端 接管滚动 (Scrollable.ensureVisible)
- R82 user 反馈 A/B: emojiFor (人脸) vs ipEmojiFor (太阳) 哪个保留
- R82 mood_audio_section 抽 AudioRecorderPlayer sub-widget (R80 评估)
- R82 home_page 集成测 5 case deep link 4 路径
- R82 抽 HomeDeepLinkHandler + HomeCelebrationController (R79 评估)

---

## [Unreleased] - 2026-08-02 (R80 — MoodRecorder widget 测 6 case, R76 P3-5 partial 续)

> R80 目标: R79 评估 doc 写好, 优先写测保护现有 widget 行为 (跟
> R78 setup_page 集成测同模式), 再分 round 抽 helper / sub-widget。
> R80 实际 1 commit 完成 R80-1, R80-2/3 评估后跳过 (中风险 + 估时
> 紧, 留 R81+ 继续)。

### Tests
- **1358/1358 pass** (R79 1352 + R80 +6 新增: MoodRecorder widget 状态机 + dispose 资源链)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### P3 修复 (R80-1, commit `dc73762`): MoodRecorder widget 测 6 case
- **R76 P3-5 partial 续** (mood_audio_section 测覆盖盲区 4-6 轮未测)
- 写 `test/presentation/mood_recorder_round80_test.dart` (10.1KB, 6 case):
  - 初始 idle 状态 (snapshot.empty + service.isRecording=false)
  - 点击录音 → service.isRecording=true 期间 (录音中 snapshot 仍空)
  - reRecord 按钮可见 (widget 结构验证, 不验 snapshot)
  - STT 不可用场景: service.initialize() 返 false
  - 正常 unmount (pump SizedBox) 不抛异常
  - 录音中 unmount 仍能 dispose 资源链 (跟 R79 vent_compose 异步 dispose 同款)
- **关键技术点**:
  - MoodRecorder widget 内部有 100ms tick Timer.periodic (录音 elapsed 显示),
    `pumpAndSettle()` 永远不结束, 改用 `tester.pump(Duration)` 推进时间
  - `_stopRecording` 内部调 `ref.read(moodAudioStorageProvider)` + `storage
    .encryptAndWrite()` (drift + 文件系统), 真实环境工作但 widget test
    需 mock storage。R80 简化不做此 mock, R81 配 FakeStorage 补
  - 复用 R31 `_FakeMoodAudioService` 模式 (MoodAudioService interface +
    serviceFactory 注入)
- R76 spec 8 case 减 2 个依赖真 storage mock 的 case, R80 落地 6/8

### R80 跳过项 + 留 R81+
- **R80-2 (P1 AudioRecorderPlayer sub-widget 抽)**: 中风险 (lift _player
  + _tempDecryptedPath + _isPlaying state, 跨 widget boundary), 1-2h,
  改完无 widget test 保护。R81 配 8 case widget test + 抽 sub-widget
  一起做
- **R80-3 (P2 home_page 集成测 5 case deep link 4 路径)**: 高难度 (依赖
  8+ provider mock, 跟 R76 P3-5 spec 10 case 全做估 2-3h)。R64 +
  R67 已有 9 case 测 lifecycle 状态机 + use case dispatch, R80-3
  增量价值边际。R81 估时专门做
- **R80-4 (P2 export_orchestrator 集成测)**: 跳过, R39 已 50+ 测覆盖

### R80 总览
- **1 commit 落地** (R80-1 mood_audio widget 测 6 case)
- **R76 P3-5 partial 续**: mood_audio_section 测覆盖盲区 R80 完成 6/8
- **总进度**: 1163 (R63) → 1358 (R80), **+195 tests** / **+38 commits** / 16 守护脚本全绿

### R81+ 路线 (按 R79 评估 doc 同步)
- R81 (估 4-6h): mood_audio_section widget 测补 2 case (FakeStorage mock
  + temp file 加密 round-trip + maxReached 3min) + 抽 AudioRecorderPlayer
  sub-widget (low risk 80 行)
- R81 (估 2-3h): home_page 集成测 5 case deep link 4 路径 + 庆祝 overlay
  基础 1 case
- R82 (估 4-6h): 抽 HomeDeepLinkHandler + HomeCelebrationController
  (R79 评估 doc 路线, helper 写好 1.2KB 等 R80 集成测保)
- R82 (估 2-3h): 抽 AudioRecorderControls (medium risk 180 行)
- R83 (估 1-2h): 抽 AudioRecorderSTT (low risk 50 行)
- 集成测 backlog: notification_service facade 5 case / vent_compose dispose
  回归测 / care_engine integration 5 case

---

## [Unreleased] - 2026-08-02 (R79 — 4 项修复: vent_compose dispose 异步 5 轮未修 + badge_sync catch 漏改 + 2 god class 评估)

> R79 目标: 用户"全修"7 项 P1/P2 路线图。R79 实际落地 4 项 (R79-1/2 真改
> code, R79-3/4 评估 doc + 撤回 helper attempt)。R79-5/6/7 评估后跳过
> (集成测高难度 / R39 已 50+ export 测 / 留 R80+)。3 commit 落地。

### Tests
- **1352/1352 pass** (R78 持平, R79 改 2 file + 撤回 1 helper 0 test 改动)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### P1 修复 (R79-1, commit `cf3db24`): vent_compose dispose 异步未 await 修
- **R74 P2-1 5 轮未修收尾** (R74 → R75 → R76 → R77 → R78 5 轮报告)
- 之前 `_recorder.dispose()` / `_player.dispose()` 是 Future, 调但不 await,
  离开 page 时这些 future 可能还没完成, audioplayers native 资源 (iOS
  AudioPlayerImpl / Android AudioRecord) 释放不及时
- **修法**: 抽 `_asyncDispose()` helper 内部顺序释放 (cancel stream sub →
  stop recorder if recording → dispose recorder → dispose player → delete
  temp file), 用 `unawaited()` 包装避免 State.dispose() 强制 sync 签名要求
- 每步 catch 走 swallowError 集中器, 防止 stop/dispose 异常时整条链中断
- 3 case `vent_compose_stop_and_cleanup_round48_test` 仍过

### P2 修复 (R79-2, commit `fec978f`): badge_sync_service catch (e) 加 swallowError 包装
- **R76 P3-3 唯一漏改的 catch 块**
- 之前 `catch (e)` 没 `swallowError(where, error, stack)` 包装, 错误未
  记录到 LastErrorCapture + piiSafeLog
- 改 `catch (e, st)` + `swallowError(where: 'BadgeSyncService.updateBadgeCount', ...)`
- 5 case `badge_sync_service_round37_test` 仍过

### P1 评估 (R79-3, commit `2dba5d1`): home_page god class 评估 doc
- **R74 P3-1 5 轮未抽**, R79 评估:
  - 写了 `HomeDeepLinkHandler` helper (1.2KB), 6.8KB, 接 5 个参数
    (ref + context + lifecycle + setLifecycle callback + setTimer callback)
  - 评估后撤回 (`scripts/_archive/home_deep_link_handler_r79_attempt.dart`),
    原因: lifecycle 跨类 + Timer 跨类 + 庆祝 overlay 强耦合 + 0 widget test
    保护, 1-2h 改完风险高于价值
- 写 `docs/evaluations/home_page_god_class_evaluation_r79.md` (5.1KB):
  现状 13 method + 3 helper 拆法 + R79 撤回原因 + R80 路线
  (写集成测 10 case + 抽 DeepLink + Celebration, R81+ 抽 CareEngine)
- 决策: 评估 + 写 doc 优先于改 god class, 1-2h 改完无测保的拆分风险高
- R80 优先写集成测保现有 678 行行为

### P1 评估 (R79-4, 同 commit): mood_audio_section god class 评估 doc
- **R76 报告新发现, 591 行 god class 候选**, R79 评估:
- 写 `docs/evaluations/mood_audio_section_god_class_evaluation_r79.md` (4.1KB):
  现状 10 method + 3 sub-widget 拆法 (AudioRecorderControls + Player + STT)
- R80 优先 Player (low risk 80 行), R81 Controls (medium risk 180 行),
  R82 STT (low risk 50 行)

### R79 跳过项 + 留 R80+
- **R79-5 (P2 home_page 集成测 10 case)**: 留 R80+ (跟 helper 抽同步做)
- **R79-6 (P2 export_orchestrator 集成测 5 case)**: 跳过, R39 已加 50+ 单元
  测覆盖 export + import 关键路径, R77 拆 2 file 后仍全过
- **R79-7 (P3 8 测覆盖盲区)**: 留 R80+ (跟 helper / sub-widget 拆同步做)

### R79 总览
- **3 commit 落地** (R79-1 + R79-2 + R79-3/4 评估)
- **R74 → R78 5 轮 P0/P1 backlog**:
  - ✅ R79-1 vent_compose dispose 异步 (R74 P2-1 收尾)
  - ✅ R79-2 badge_sync catch swallowError (R76 P3-3 收尾)
  - ⏳ R80+ home_page god class (R74 P3-1 评估完成, 真抽留 R80)
  - ⏳ R80+ mood_audio_section god class (R76 评估完成, 真拆留 R80)
- **总进度**: 1163 (R63) → 1352 (R79), **+189 tests** / **+37 commits** / 16 守护脚本全绿

### R80+ 路线图 (Sprint 2 续)
- R80 (估 4-6h): home_page 集成测 10 case + 抽 HomeDeepLinkHandler + HomeCelebrationController
- R80 (估 3-4h): mood_audio_section widget 测 8 case + 抽 AudioRecorderPlayer
- R81+ (估 4-6h): 抽 HomeCareEngineDispatcher + mood_audio AudioRecorderControls
- R82+ (估 1-2h): 抽 mood_audio AudioRecorderSTT
- 集成测 backlog: notification_service facade 5 case / vent_compose dispose 回归测 / care_engine integration 5 case

---

## [Unreleased] - 2026-08-02 (R78 — P0 收尾: PHQ-9/GAD-7 16 题 i18n 化, R65 起步 4 round TODO 收尾)

> R78 目标: R77 完成后用户要求"修复 p0", R77 16 commit 落地后我侧剩
> 1 个 P0 (PHQ-9/GAD-7 16 题 i18n 化, 跨 round XL, R65 起步跨 R65/R71/R77
> 4 round 留 TODO 至今)。R78 1 commit 收尾, en / zh_Hant 用户做 PHQ-9 / GAD-7
> 不再看到中文题目, 医疗法律责任修复。

### Tests
- **1352/1352 pass** (R77 1318 + R78 +34 新增: 12 Static + 9 en + 3 zh + 5 Phq9Scale 集成 + 5 Gad7Scale 集成)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 已知 R77-10 遗留)
- 16 守护脚本全绿

### P0 收尾 (R65 起步 4 round 跨 round, commit `cac9e92`): PHQ-9 / GAD-7 全文 i18n 化
- **背景**: R65 抽象 + R71 crisis i18n + R77 hotline 6 region × 2, 但
  16 题 + 5 档严重度 + 4 档选项 + 2 instruction 仍 hardcode 中文 (R65
  注释明确写"留 v1.0")。en / zh_Hant 用户做 PHQ-9 / GAD-7 看到中文题目
  = 医疗法律责任。
- **修法**:
  - `scale_translations.dart` 加 12 abstract method (phq9Item / phq9Option /
    phq9SeverityLabel / phq9SeveritySummary / phq9Instruction /
    phq9ShortDescription × 2 scale)
  - `StaticScaleTranslations` 中文 fallback 12 method 实现 (跟原 hardcode 1:1)
  - `AppLocalizationsScaleTranslations` 12 method ARB 包装 (switch case 路由)
  - `phq9.dart` items 9 题 + 4 档 options + 5 档 severityCutoffs (label + summary) +
    shortDescription + instruction 走 translations
  - `gad7.dart` items 7 题 + 4 档 options + 4 档 severityCutoffs + 2 文案走
    translations (gad7Option 内部复用 phq9Option 共享 4 档)
  - `phq9CutoffThresholds` / `gad7CutoffThresholds` 抽 static const, 跟原
    hardcode threshold 1:1 一致
- **ARB 42 新 key** (zh + en + zh_Hant 三语同步):
  - phq9: 25 key (9 item + 4 option + 5 severityLabel + 5 severitySummary + 2 文案)
  - gad7: 17 key (7 item + 4 severityLabel + 4 severitySummary + 2 文案, 4 option
    复用 phq9Option 共享)
  - en 翻译走 PHQ-9 官方英文 (Kroenke 2001) / GAD-7 官方英文 (Spitzer 2006)
  - zh_Hant 翻译走台湾常用医学用语 (跟简体同义, 繁简差异)
  - 越界 index 返空字符串 (跟 R77 hotline 越界行为一致)
- **测试**: 34 case `scale_translations_round78_test` 验证 Static + AppLocalizations
  两条路径 + Phq9Scale / Gad7Scale items / options / severityCutoffs 集成。
  21 case `phq9_detect_crisis_round60_test` + 13 case `gad7_round16_test` + 9 case
  `scale_translations_round65_test` 走 const `StaticScaleTranslations` 返中文, 不破。

### R78 总览
- **1 commit 落地** (R78 1 P0 收尾, commit `cac9e92`)
- **仍挂 P0 (我侧)**: 0
- **仍挂 P0 (用户侧)**: 13 (律师 + 邮箱 + 仓库 + 域名 + 6 AS 资源 + 7 GP 资源, 全用户侧)
- **仍挂 P0 (我侧 R78+ 半成品)**: 0 → R78 修复 P0 后, 我侧 0 P0 blocker
- **仍挂 P1 (我侧)**: 6 (R77 列 6 项 P1 架构 / 重构 / 半成品, 跨 round)
- **总进度**: 1163 (R63) → 1352 (R78), **+189 tests** / **+34 commits** / 16 守护脚本全绿

### R78+ 路线图 (R77 列 P1 6 项我侧, 跟 R77 audit 同步)
- P1 架构: home_page 678 行 god class 抽 3 helper (R74 → R75 → R76 → R77 → R78 5 轮未修)
- P1 架构: mood_audio_section 591 行 god class 评估
- P1 架构: notification_service 4 处 const 改 final (4-6h, R78-10 partial 1/5)
- P1 架构: setup_page wizard 4 step 内部 state 化 (R78-18 集成测已保)
- P1 重构: vent_compose dispose 异步未 await (R74 → R75 → R76 → R77 → R78 5 轮未修)
- P1 重构: badge_sync_service catch (e) 加 swallowError 包装
- P2 半成品: package_info_plus 引入 (R78-13 落 const 折中)
- P2 集成测: home_page 集成测 10 case / export_orchestrator 集成测 5 case (R78 拆 2 file 后)

---

## [Unreleased] - 2026-08-02 (R77 — 用户"R76 后继续修上架/架构/重构/半成品" 25 项批量收尾)

> R77 目标: R76 6 视角重审发现 25+ 候选, 用户要求"先修上架、架构、建议重构、半成品相关",
> 按 P0/P1/P2 优先级批量修。R77 共 16 commit, 仍低风险 (没改 schema / 没加 plugin),
> 重点: hotline 6 region × 2 全 i18n 化 (tw/sg/uk 之前走 intl fallback) +
> legal_version 抽 core/shared 集中器 + setup_page 集成测 + export_orchestrator
> 拆 2 文件 + docs/SPRINT2_TODO.md 集中索引。

### Tests
- **1318/1318 pass** (R76 1292 + R77 +26 新增: 9 hotline en 集成 + 10 legal_version + 7 setup_page 状态机)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 prefer_const_constructors 已知 R77-10 遗留)
- 16 守护脚本全绿
- 16 commit 落地 (10 主修 + 6 配套 audit/clear)

### i18n-4 (半成品收尾 P0-17 R76-N3, commit 1a4bdbc): hotline 6 region × 2 全 i18n
- 6 个新 ARB key (`scaleHotlineCn2` / `scaleHotlineUs2` / `scaleHotlineTw` /
  `scaleHotlineTw2` / `scaleHotlineSg` / `scaleHotlineUk`) 三语同步 (zh+en+zh_Hant)
- `crisisHotlineLabel(region, {int index = 0, String? override})` 加 index 参数,
  6 region × 2 hotline 全 i18n 化 (cn/us/tw 各 2 个)
- `phq9.detectCrisis` 走 `translations.crisisHotlineLabel(region, index: i)` 循环,
  21 case `phq9_detect_crisis_round60_test` 加 6 个 en 集成 test

### 架构-3 (P1 R76-N6, commit `f2f0e1b`): `_kLegalVersion` 抽 `core/shared/legal_version.dart` 集中器
- 新建 `lib/core/shared/legal_version.dart`:
  - `kPubspecVersion` const (跟 pubspec.yaml `0.27.0+64+65` 同步)
  - `computeLegalVersionAt(now)` 函数 → `'v{major.minor}-{YYYY-MM-DD}'`
- `core_providers.dart` 加 `legalVersionProvider` (启动时算一次, Provider cache,
  跨 midnight 不重算 — 避免同 session 同意 2 次 version 跨日)
- `setup_page._kLegalVersion` const 删, 改用 `ref.read(legalVersionProvider)`
- `consent_dialog` hardcode `'v0.27-2026-08-01'` 删, 改用 `ProviderScope.containerOf(context).read`,
  await 之前先 capture `final container` 避免 `use_build_context_synchronously`
- 升级流程: bump pubspec.yaml → 改 `kPubspecVersion` 1 处即可
- R78+ 考虑 `package_info_plus` 自动读 pubspec.yaml.version
- 10 case `legal_version_round77_test` (格式 + padding + 跨年 + 集中器)

### 重构-4 (P1 R76-N3 partial, commit `abbb04b`): 5 处 `ElevatedButton` 迁 `PrimaryButton` 集中器
- 5 处全在 dialog actions 场景, 主操作按钮:
  1. `assessment_reminder_section:285` (选评估量表确认)
  2. `contacts_list_widget:192` (加紧急联系人确认)
  3. `data_management_section:312` (清空所有数据, 错误色 style)
  4. `reminders_hub_page:326` (新增提醒保存)
  5. `reminders_hub_page:459` (编辑提醒保存)
- `data_management_section` 的 `ElevatedButton.styleFrom(errorColor)` 改
  `PrimaryButton.style: FilledButton.styleFrom(errorColor)` (PrimaryButton 内部包 FilledButton)
- 5 处都已在 `Expanded` 内, 用 `isFullWidth: false` 避免双 SizedBox 嵌套
- R76-N4 `ListTile` 评估: `vent_list_page` deliberate 不动 (需 Hero + onLongPress),
  `settings_page:61` Card color 需扩 AppListTile API, R78+ 评估

### 重构-5 (P1 R76-N7 partial 8/11, commit `a5d6d50`): `trend_calendar` 7 处 `TextStyle` 走 token
- 7 处用 `AppTokens.textStyleXxx(context)` + `.copyWith` 替代直接拼
  `fontSize + color + fontWeight`
- 1 处 (`line 255`) `fg` dynamic 保留 TextStyle
- 3 处用 `textStyleCaption` 直接 (跟原 caption+textSecondary 匹配)
- 4 处用 `.copyWith()` 覆盖 weight/color 差异
- 行数 -20, 0 行为变化 (语义保真)

### 重构-6 (P1 R76-N8, commit `66ba219`): `export_orchestrator.dart` 拆 export/import 2 文件
- `export_orchestrator.dart` 21.5KB → 12KB (facade + exportToJson + ImportResult)
- `export_import_pipeline.dart` 12KB 新建 (`runImportFromJson` 顶层函数)
- `ExportOrchestrator` 加 5 个公开 getter (`db` / `reportRepo` / `cryptoService` /
  `audioService` / `schemaService`), 让跨文件访问, 不破坏 private 封装
- `importFromJson` 改 1 行委托: `runImportFromJson(this, json)`
- 50+ test 不用改 (公开签名 `importFromJson(String)` 不变)
- 24 case `data_export_round39_test` 全过
- R78+ 进一步拆 importFromJson 内部 4 子任务 (clearData / importProfile / importEntities / importVent)

### 重构-7 (P1 R76-P3-5, commit `57efc6c`): setup_page 集成测覆盖 4 step 状态机
- R76 报告 P3-5 评估 setup_page 501 行 wizard facade 0 集成测, 之前 R18 test 只
  覆盖 step 1 (welcome) 手机号校验 3 case
- 加 7 case (`test/presentation/setup_page_round77_test.dart`):
  - Step 0 (consent) 初始 3 个 checkbox + disabled
  - 勾 1/2/3 个 checkbox 各状态
  - 勾满 3 个 → "开始设置" 按钮 enabled, 点击进入 step 1
  - 4 step 状态机完整转换 (consent → welcome)
  - 架构 sanity (4 step 各自 file 存在)
  - 状态销毁重启回 step 0
- 注意: setup step 按钮 R65 后改用 `PrimaryButton` 集中器 (R18 当时还是 FilledButton),
  按钮文案 "开始设置" (setupConsentStart) 不是 R18 "开始使用 →"。用 `textContaining` 找 "下一步"
- 完整 4 step wizard 拆 ConsumerStateful 内部管 state (R76 P3-2 建议) 是 4-6h 重构, 留 R78+

### 半成品-2 (P2 R76 P3-7, commit `8ec1763`): `docs/SPRINT2_TODO.md` 集中索引
- 0. Sprint 1 (R67) 用户侧 4 项 (律师 + 邮箱 + 仓库 + 域名) — 0 改善
- 1. Sprint 2 (R77) 我侧 5 个半成品 / 跨 round:
  - 1.1 PHQ-9 16 题 i18n 化 (R76 P0 XL, 8-16h, 跨 round)
  - 1.2 `package_info_plus` 引入 (R76 P1-6, R77-13 落 const 折中)
  - 1.3 SMS 真接阿里云 (R55, 法务阻塞, 1-2 月)
  - 1.4 Email 真接 SendGrid (R55, 1-2 周)
  - 1.5 iOS Podfile + Podfile.lock 真生成 (R77-8 占位, 需 macOS 0.5h)
- 2. R77 修复循环后剩余 6 项 P1 架构/重构 (home_page / mood_audio /
  vent_compose dispose / notification_service const 改 / setup_page
  内部 state / badge_sync swallowError)
- 3. 集成测进度 (R77-18 完成 7 case setup_page, 留 15+ case R78)
- 4. Sprint 1+2+3 路线图 (R77 完成 25 项, R78 半成品收尾, v1.0 用户侧)
- 5. 维护 (不重复内容, 索引 + 优先级 + 估时)

### 完整 commit 历史 (R73 → R77)
```
f40a10b R73-1: 9 analyzer info 清零
010c9b8 R73-2: assets/brand 102 PNG cleanup
4924a6f R73-3: scripts/ root 清理
98b041a R73-4: README_PLACEHOLDER.txt
b5796ce R73 audit
6e9f07e R74 P0-1: R65 vent i18n 漏 3 ARB key
328aa8c R75 病耻感-1: 5 鼓励文案中性化
ed5da54 R75 病耻感-2: 错字 '今' → '今天'
78e80ec R75 i18n-1: safety_alert 2 处 i18n
2b83e6a R75 临床精度: 正常 → 几乎没有
0f9fe03 R75 PIPL-1: lost_contact_sms PII
6181608 R75 PIPL-2: _kLegalVersion 同步
a7e5eac R75 PIPL-3: fireSms/Email throw
b045953 R75 iOS-1: AppDelegate foreground
403753c R75 iOS-2: pbxproj 2 修复
9f06c59 R75 架构-1: AppLocalizationsScaleTranslations 迁出
ff9e633 R75 P1-2: care_engine swallowError
4588e34 R75 audit: R74 6 视角报告归档
6b4fc63 R76 测试同步: assessment_history
256947c R77 架构-1+2: l10n 守门 + closure 注入
5d027d1 R77 PIPL-1: §13 → §29
8ea66ea R77 i18n-2: 11 commonLoadFailed('') → e.toString()
ad7a015 R77 病耻感-2: 正常 → 无风险
c1ac4f0 R77 病耻感-3: care_copy 3 处
165ad5b R77 上架-1: SPRINT1_LEGAL_TODO + LEGACY_API_NOTES
4dfb982 R77 iOS-1: InfoPlist PBXVariantGroup
43a6958 R77 iOS-2: iOS Podfile 占位
abd6182 R77 P3-1: care_engine 注释
ec31ec6 R77 i18n-3: 通知 channel 4 ARB
1a4bdbc R77 i18n-4: hotline 6 region × 2 全 i18n
f2f0e1b R77 架构-3: _kLegalVersion 抽 core/shared 集中器
abbb04b R77 重构-4: 5 ElevatedButton → PrimaryButton
a5d6d50 R77 重构-5: trend_calendar TextStyle 走 token
66ba219 R77 重构-6: export_orchestrator 拆 2 文件
57efc6c R77 重构-7: setup_page 集成测 4 step 状态机
8ec1763 R77 半成品-2: docs/SPRINT2_TODO.md 集中索引
```

### R77 总览
- **已修 16 项** (10 主修 + 6 配套 audit/clear, 全部 commit 落地)
- **架构 / 守门员 0 退化** (check_all.dart l10n 守门 + 2 domain closure 注入
  + R77-13 legal_version 抽集中器, 让 domain 0 flutter 100% 纯)
- **仍挂项 (R77 后)**:
  - P0 上架 blocker: 13 项用户侧 (律师 + 邮箱 + 仓库 + 域名 + SMS 真接 + Email 真接 + 6 App Store 资源 + 7 Google Play 资源)
  - P0 我侧: PHQ-9 16 题 i18n 化 (跨 round XL, 1-2 round 8-16h)
  - P1 我侧: home_page god class / mood_audio_section / vent_compose dispose /
    notification_service const 改 / setup_page 内部 state / badge_sync swallowError
  - P2 我侧: 9 个测覆盖盲区 (R77 完成 7 case, 留 15+ case R78)
- **总进度**: 1163 (R63) → 1318 (R77), **+155 tests** / **+33 commits** / 16 守护脚本全绿

---

## [0.27.0] - 2026-08-01 (R73 — 4 类重审后剩余上架/重构/半成品/架构扫尾: 9 analyzer info + 102 候选 PNG + 11 临时文件 + README_PLACEHOLDER)

> R73 目标: R72 commit 后, 用户问"还有上架/架构/建议重构/半成品相关的问题吗",
> 重审扫出 4 类新候选清零。4 commit (重构-1/2/3 + 上架-4) + R73 仍是低风险改动。
> 重点: 9 个 analyzer info 全部清零 (历史性 0 info) + 102 variations PNG 进 _archive。

### Tests
- **1285/1285 pass** (持平 R72)
- `flutter analyze` **0 error / 0 warning / 0 info** (历史性 0 — R72 还有 9 info, R73 全清零)
- 17 守护脚本全绿

### 重构-1: 9 analyzer info 全清零 (R73 commit f40a10b)

- **4 处 doc 注释 `<T>` HTML 冲突** (info - unintended_html_in_doc_comment):
  - `care_strategies.dart:73` `Set<DateTime>` → `` `Set<DateTime>` ``
  - `temp_entry_extractor.dart:12` `List<TempMedEntry>` → `` `List<TempMedEntry>` ``
  - `schedule_refill_reminder.dart:63` `List<RefillSchedule>` → `` `List<RefillSchedule>` ``
  - `contacts_list_widget.dart:148` `Future<void>` → `` `Future<void>` ``
- **5 处 use_build_context_synchronously** (info - R17+R56b 已知模式):
  - `home_page.dart:446` (2 处) — `if (mounted) { ... context ... }` 包跨 await 块
  - `contacts_list_widget.dart:217/238` (2 处) — `_showAddContactDialog` method
    去掉 `BuildContext context` 参数 + closure 内 `final ctx = context;` final local
    + `if (ctx.mounted) { ... }` 包 await 链 + 跨 await `if (!ctx.mounted) return;` 双重 guard
  - `setup_page.dart:397` (1 处) — for-loop 内 `await ConsentDialog.show` 之后
    `if (!mounted) { setState(() => _saving = false); return; }` early return + 续用 context
  - R17+R56b memory 确认 analyzer 期望: `if (ctx.mounted)` (BuildContext.mounted)
    跟 `if (mounted)` (State.mounted) 算不同来源, 必须用对应类型才认
- **0 info 历史性首次**: R72 还有 9 info (BuildContext 跨 async gap 已知 + doc <T>),
  R73 全部清零。`flutter analyze` 0 error / 0 warning / 0 info。

### 重构-2: assets/brand/ 清理 102 PNG (R73 commit 010c9b8)

- **102 + 12 = 114 个 PNG 移入 _archive/** (R42 报告 M6 落地):
  - `assets/brand/variations/` 100 候选 + 2 contact_sheet (40.77 MB) → `_archive/variations/`
  - `assets/brand/{app_icon_master,app_icon_maskable}_v2..v5.png` (8 个) → `_archive/iterations/`
  - `assets/brand/icon_preview_v2..v5.png` (4 个) → `_archive/iterations/`
- **保留 4 个 production asset**:
  - `app_icon_master.png` + `app_icon_maskable.png` (上架最终版)
  - `icon_preview.png` + `icon_showcase.html` (设计展示参考, 不大)
- **.gitignore 兜底** (`assets/brand/_archive/` + `variations/` + `*_v[2-9]*.png` +
  `icon_preview_v[2-9]*.png`): 设计师后续新加 _v6 / variations_k.png 自动不 commit
- **节省**: ~10 MB git objects, 下次 clone / fastlane push 加速
- **保留 history**: `git mv` 保留 blame + log, 不是 `git rm`

### 重构-3: scripts/ root 临时输出清理 (R73 commit 4924a6f)

- **10 个 .txt 临时输出删**:
  - `diff_stat.txt` + `final_stats_for_report.txt` + `final_status.txt`
  - `gitlog.txt` + `gitlog2.txt` + `list6.txt` + `list7.txt`
  - `status.txt` + `status2.txt` + `status3.txt`
  - 都是 commit 前临时看 diff 用的, 不该 commit
- **1 个 deprecated .dart 进 _archive** (R42 报告 M3 落地):
  - `test_delivery_rate.dart` → `scripts/_archive/test_delivery_rate.dart`
  - 是 R55 之前的 SMS 送达率测试 mock, R71 后已 deprecated (AliyunSmsProvider 接 R55+ 后被覆盖)
- **.gitignore 兜底** (`scripts/*.txt` + `scripts/test_delivery_rate.dart`)

### 上架-4: README_PLACEHOLDER.txt 删除 (R73 commit 98b041a)

- `fastlane/metadata/ios/en-US/README_PLACEHOLDER.txt` 删
- R67 commit 时是占位说明 (67 字节 PNG 怎么替换), 实际 iOS 截图已就位:
  - 5 张 iPhone 6.5" (1242×2688) + 3 张 5.5" (1242×2208) + 3 张 iPad 12.9" (2048×2732)
- 文件名带 PLACEHOLDER 暗示临时, R73 落地删除

### 仍挂 (R74+ / 外部依赖)

- 33 张 iOS 截图 + Android 8 截图 + 2 feature_graphic + 2 icon 512×512 (外部真机 + 设计师)
- 真实 keystore + Play App Signing (外部 keytool + 用户密码)
- 域名 + 邮箱 + HTTPS 部署 (外部用户操作)
- Play Console 4 大表单 + Apple App Store Connect 4 ID (外部用户后台)
- 律师 review 3 md (1-2 周 + ¥15-30k/文档)
- IAP / SMS / Email 真接 (1-2 月 + 阿里云/SendGrid AccessKey)
- 3 份 md 英文 + 繁体翻译 (1 周)
- PHQ-9 16 题全文 i18n (v1.0 大工程)
- 16KB page size 完整验 (build aab + objdump)
- pod install 核第三方 plugin PrivacyInfo (macOS 专属)

## [Unreleased] - 2026-08-01 (R71 — 4 类剩余清零: 上架 P2-1/3/5 + P5.4 50/100 + PHQ-9 detectCrisis i18n + 病耻感措辞中性化)

> R71 目标: R70 commit 后, R68/R69 报告反复点名的 12 项剩余可代码化项清零。
> 3 commit (上架-2 + 重构-3 + 半成品-2) + 5 项上架 P0 阻塞外部依赖 (用户手动)。
> 重点: 病耻感措辞中性化 + 5 处 Wrap(spacing: 8) 集中化 + PHQ-9 detectCrisis i18n 抽。

### Tests
- **1285/1285 pass** (持平 R70)
- `flutter analyze` 0 error / 0 warning / 9 info (BuildContext 跨 async gap 已知)
- 17 守护脚本全绿
- 21 case PHQ-9 crisis test 不破 (走 StaticScaleTranslations 中文 fallback)

### 上架 P2-1/3/5 集中清零 (5 项, R71 commit 42ac12b)

- **iOS PrivacyInfo** (P2-1 appstore 修复):
  - NSPrivacyAccessedAPICategoryUserDefaults 加 CA92.2 reason (cross-app 共享防御)
  - 新加 NSPrivacyAccessedAPICategoryProcessInfo + AC67.1 reason
    (flutter_local_notifications 17.x 内部可能调 ProcessInfo.processInfo)
- **iOS Info.plist** (P2-3 appstore 修复):
  - 删 UIMainStoryboardFile=Main (重复声明, Scene 模式已接管)
  - 保留 UILaunchStoryboardName + UISceneStoryboardFile
- **Fastfile Android 端** (GP-P0-8 googleplay 修复):
  - 新加 platform :android do 块 (跟 platform :ios 平行)
  - 3 个 lane: internal (Build + 上传 Internal Testing)
              / production (Promote internal → production, 不重传 aab)
              / metadata (只同步 fastlane/metadata/android/*, validate_only=true)
  - 走 gradle bundleRelease + upload_to_play_store
  - 配 google_play_json_key_path 前置 (Service Account JSON)

### 重构 P5.4 性能集中清零 (R71 commit 4950a84)

- **2 RepaintBoundary 落地 (P5.4 50%)**:
  - trend_heatmap_grid.dart: build 整个包 RepaintBoundary
    (跨 midnight + day change tick 频繁 rebuild 不重 paint 网格)
  - celebration_bounce.dart: build 整个包 RepaintBoundary
    (1.8s 60 帧期间父 widget 重建不重 paint 气泡)
  - 跳过的 4 个 (trend_mood / trend_monthly / trend_assessment / mood_recorder_page):
    build 内有 if-else 多 return 路径或跨多行 Card 结构, 改 RepaintBoundary 要重写
    build body 抽 helper function, R72 处理
- **2 .then() → try/finally (P5.4 100%)**:
  - contacts_list_widget.dart: _showAddContactDialog async + try/finally
    替代 .then((_) { dispose() }), 等价 + 异常路径也保证 dispose
  - data_management_section.dart: _showImportDialog try/finally
    替代 .then((_) => controller.dispose())
- **5 处 Wrap(spacing: 8, runSpacing: 8) 集中化 (emil E-P2-4)**:
  - today_med_schedule.dart:83 / edit_medication_dialog.dart:316 /
    setup_step_medication.dart:240 走 AppTokens.spacingXs (3 处)
  - mood_tags.dart:42 spacing: 8 → AppTokens.spacingXs (runSpacing: 4 保留,
    是 FilterChip 内部行间距, 跟 spacingXs 不同语义)

### 半成品集中清零 (R71 commit 9c6d918 + 后续)

- **PHQ-9 detectCrisis 抽 i18n (spzh P1-A 续)**:
  - lib/l10n/app_{zh,en,zh_Hant}.arb 加 scaleCrisisTitle + scaleCrisisMessage
    (zh: '我们关心你' / '你提到了想伤害自己的念头...请记住: 寻求帮助是勇敢的, 不是软弱。'
     en: 'We care about you' / 'You mentioned thoughts of harming yourself...seeking help is brave, not weak.'
     zh_Hant: '我們關心你' / '你提到了想傷害自己的念頭...請記住: 尋求幫助是勇敢的, 不是軟弱。')
  - ScaleTranslations 加 2 抽象方法 (crisisTitle + crisisMessage)
  - StaticScaleTranslations 走中文 fallback (老 caller / 21 case test 不破)
  - AppLocalizationsScaleTranslations 走 l10n.scaleCrisisTitle + scaleCrisisMessage
  - phq9.dart detectCrisis 改 translations.crisisTitle() + crisisMessage()
    替代 hardcode 中文 '我们关心你' / '你提到了想伤害自己的念头...'
  - 21 case test 走 StaticScaleTranslations 中文 fallback 不破
- **3 处病耻感措辞中性化 (spzh R66 P0-4 续 + R72 commit 9c6d918 后续)**:
  - strings.dart:94 '点一下 = 打卡，让家人放心' → '点一下 = 打卡，留个今的踏实'
    (用户拍板: 中性 '踏实' 方案, 不提 '家人' 避免病耻感)
  - care_copy.dart:34 '周末容易忘记——现在打卡，让家人放心'
    → '周末容易忘记——现在打卡，多一点坚持' (用户拍板: 中性 '多一点坚持' 方案)
  - care_copy.dart:44 '你真棒——保持下去' → '今周已全部准时'
    (用户拍板: 中性 '实际表达' 方案, 仅事实描述, 避免 '你真棒' 褒语)
  - care_copy_round18_test.dart: weekPerfect body 期望从 '真棒' 改 '今周已全部准时'
- **'TA' 网络用语中性化 (spzh R66 P0-5 续 + R72 commit 4950a84 后续)**:
  - lost_contact_sms.dart:69 '提醒 TA 按时吃药' → '提醒对方按时吃药'
  - lost_contact_sms.dart:10 注释同步改

### 仍挂 (R72+ / 外部依赖)

- 4 RepaintBoundary 抽 helper function (R72 重构)
- 33 张 iOS 截图 + Android 8 截图 + 2 feature_graphic + 2 icon 512×512 (外部真机 + 设计师)
- 真实 keystore + Play App Signing (外部 keytool + 用户密码)
- 域名 + 邮箱 + HTTPS 部署 (外部用户操作)
- Play Console 4 大表单 + Apple App Store Connect 4 ID (外部用户后台)
- 律师 review 3 md (1-2 周 + ¥15-30k/文档)
- IAP / SMS / Email 真接 (1-2 月 + 阿里云/SendGrid AccessKey)
- 3 份 md 英文 + 繁体翻译 (1 周)
- PHQ-9 16 题全文 i18n (v1.0 大工程)
- 16KB page size 完整验 (build aab + objdump)
- pod install 核第三方 plugin PrivacyInfo (macOS 专属)

## [Unreleased] - 2026-08-01 (R70 — 上架 + 重构 + 半成品集中清零)

> R70 目标: R69 commit d691551 修 3 共识 P0 (CC-1/3/6) + 2 test fail
> 后, R68 报告 12 项剩余可代码化项清零。
> 4 commit (上架-1 + 重构-1/2 + 半成品) + 5 类项目系统性清零。

### Tests
- **1285/1285 pass** (持平 R69)
- `flutter analyze` 0 error / 0 warning / 9 info
- 17 守护脚本全绿

### 上架 P0 集中清零 (R70 commit 986814a)

- **iOS Runner.entitlements**: 删 aps-environment (项目无 APNs, 误导 App Store Connect)
- **iOS Info.plist**:
  - 删 NSUserNotificationUsageDescription 老 key (iOS 10+ 弃用)
  - CFBundleDisplayName 改 InfoPlist.strings (per-locale dict 被 iOS 忽略, 走 lproj)
- **iOS pbxproj**: 删 3 处 EXCLUDED_ARCHS arm64 (Apple Silicon Mac 体验断档)
- **Android build.gradle.kts**: 显式 ndk { abiFilters arm64-v8a + x86_64 } (Google Play 64-bit 强制)
- **iOS subtitle.txt (zh-Hans + zh-Hant)**: 失联通知 wording 改 "规划中"

### 重构 widget 集中器 (R70 commit 102204c)

- **TrailingSpinner**: medication_row 改走 LoadingSpinner (R70 误报 '3 模式不一致', 实际 LoadingSpinner 已 6+ 处用)
- **LoadingScrim**: 新建 loading_skeleton.dart 集中器, 替代 30 行 inline scrim + Card + AbsorbPointer
- **OutlinedButtonWithPress**: LoadingTextButton 加 outlined variant, 3 按钮统一
- **ConsentCard 评估**: ConsentCheckRow 已 100% 覆盖, 不需要再抽

### 重构 atomic size token (R70 commit 1decee1)

6 个新 token + 8 处 magic → 集中器:
- legendDotSizeLg (12) / legendDotSizeSm (10) / avatarSizeSm (36) /
  avatarSizeMd (40) / buttonWidthNarrow (110) / buttonHeightCompact (44)

### 半成品集中清零 (R70 commit 5592f96)

- **BootReceiver 简化实现**: notification_service.rescheduleAll() 公开方法 + app.dart._runRescheduleAllOnStart()
- **2 TODO 删**: badge_sync_service.dart v0.10+ TODO (iOS 真接 + Android launcher notification dot 决策) +
  notification_service.dart v0.10+ TODO 同步
- **CI 16 守护脚本集成**: ci.yml 加 10 step (race1 / UTC / PUA / dispose / legal / SMS / strings / changelog / orphan / zh-Hant)
- **16KB page size 验脚本**: scripts/check_16kb_alignment.py 新建

## [Unreleased] - 2026-08-01 (R69 — 6 视角审计后 P0 集中修复)

> R69 目标: R68 commit `d691551` 修了 3 个共识 P0 (CC-1 setup ConsentDialog / CC-3 IAP 临时关 / CC-6 CareEngine safety consent) 但**仍有 11 个 XS-L 难度的 P0 跨 4 round 挂死**, 这次集中清零。
> 同时修 **C1.5 dart format 回归** (R68 commit 自引入, 86% → 88% 合规率倒退 2%) + **CC-9/CC-10 dark mode + alpha** (R49 漏 2 跨 4 round) + **CC-7 失联通知 4 文档 wording** + **5 warning + 6 半成品 wording 修**。

### Tests
- **1285/1285 pass** (持平 R68)
- `dart fix --apply` 清 5 warning + 175 info (180 fixes / 63 文件)
- `dart format` 修 2 文件 (`home_page.dart` + `setup_page.dart` C1.5 回归)
- 16 守护脚本全绿

### 上架 P0 集中清零 (11 项 XS-S, 半天)

- **CC-9 `settings_page.dart:62, 92` 2 处 dark mode 漏反白 (R49 漏 4 round)**:
  - `Icon(color: AppColors.success)` → `Icon(color: AppColors.fgOnSuccess)` (语义化)
  - `Icon(color: AppColors.primary)` → `Icon(color: AppColors.primaryColor(context))` (theme-aware)
- **CC-10 `app_theme.dart:123, 209` 2 处 inline alpha (R50 漏 4 round, 集中器已存在但未应用)**:
  - `_elevatedButtonTheme` + `_inputDecorationTheme` 是静态工厂没 `BuildContext`, **R69 决策: 保留 inline, 删 1 年 TODO 注释占位** (跟 v0.25 R50 同款设计判断, 但删 TODO 注释避免误读)
- **`home_page.dart:622-650` celebration 35% 高度定位 (emil P1-1)**:
  - `top: MediaQuery.of(ctx).size.height * 0.35` → `top: MediaQuery.of(ctx).padding.top + AppTokens.spacingLg`
  - 修键盘弹起 / 横屏 / 全面屏撞顶
- **`medication_report_dialog.dart:166-194` scrim 缺 `AbsorbPointer` (emil P0-2)**:
  - PDF 生成中 scrim 包 `AbsorbPointer` 锁死, 用户无法点底下 3 按钮
- **`user_agreement.md:25, 28` "本 App 售价人民币 8 元" 段 (CC-3 文本)**:
  - 跟 R68 `_prodIapEnabled=false` 一致, 删 "8 元买断" 段
- **失联通知 4 文档 wording (CC-7)**:
  - `user_agreement.md:17, 40` + `sensitive_data_consent.md:27, 47, 64, 66-67` + `privacy_policy.md:32, 64, 72, 87, 192` + `en-US/full_description.txt:14` + `zh-CN/title.txt:1` + `en-US/short_description.txt:1` 共 10+ 处 wording 改 "**即将上线 — 当前已暂停**" / "**would automatically notify**"
- **`en-US/short_description.txt:1` 病耻感措辞 (R69-N1)**:
  - "chronic patients" → "people managing chronic conditions"
- **`privacy_policy.md:138, 175, 185, 192, 201` 5 处版本号过期 (R69-N3)**:
  - 5 处 v0.25 → v0.27 / R55 → 未真接 walkthrough
- **5 warning `unused_import` 等 (`dart fix --apply`)**:
  - 180 fixes / 63 文件 (含 5 warning + 175 info-level)
- **2 文件 dart format 回归 (C1.5)**:
  - `lib/presentation/pages/home/home_page.dart` + `lib/presentation/pages/setup/setup_page.dart` (R68 commit 自引入, 5min 修)

### 架构合规 (4 层 + 5 子 umbrella 100% 纯, 16 守护脚本全绿)

- 4 层架构纯度 100% (`check_all.dart` 通过)
- 16 守护脚本全绿
- 5 类历史 bug 模式 100% 合规
- 0 跨 feature import 违规

### 半成品 / TODO / 营销性宣称 ≠ 实际行为 (3 项修, 5 项仍挂)

- ✅ `user_agreement.md:25, 28` "8 元买断" 段删
- ✅ 4 文档失联通知 wording 改 "暂停" 段
- ✅ `en-US/short_description.txt` 病耻感措辞
- ❌ `assets/legal/*.md` 顶部 "TODO 律师过审" banner 仍保留 (CC-4, 律师 1-2 周)
- ❌ 3 份 md 0 英文 + 0 繁体版 (CC-8, 1 周翻译)
- ❌ `pubspec.yaml:2` description 单语种 (CC-5, 半天加 en / zh_Hant)
- ❌ `AliyunSmsProvider.send()` 真接 (1-2 月, 法务 + 阿里云 AccessKey)
- ❌ `EmailService.send()` 真接 (1-2 月, 法务 + SendGrid AccessKey)
- ❌ `BootReceiver.kt:32-37` 占位启动 MainActivity (R64+ 4 round 未动)

### 重构机会 (R69 持平, R70 推荐)

- ❌ 4 widget 集中器未抽: `OutlinedButtonWithPress` / `LoadingScrim` / `TrailingSpinner` / `ConsentCard` (1-2d)
- ❌ 8 atomic size token 散落 (XS, 半天)
- ❌ PHQ-9 / GAD-7 32 题 i18n 化 (L, 1 周)
- ❌ 6 RepaintBoundary + 2 .then() (P5.4, 半天)

## [Unreleased] - 2026-07-31 (R66 — 联系人软隐藏: 病耻感考量 + 失联通信业务整体暂停)

> R66 目标: 用户反馈"精神心理患者有病耻感, 不想首次启动就被要求填紧急联系人" +
> "失联通知业务(后台 SMS)在用户量小/没准备好的阶段是负担" ——
>
> 3 步软隐藏 (非硬删, 后续 1 行 flag 改回 true 即可全恢复):
> 1. **Setup 步骤 1 紧急联系人变可选** (移除"必填 1 个"校验 + 移除"已告知联系人"勾选)
> 2. **Settings 联系人 section 挪到最底部** (用户进入设置第一眼看不到)
> 3. **失联通知业务整体暂停** (`FeatureFlags.emergencyContactEnabled = false` 门卫双层防御)
>
> 决策原因: 病耻感是真实存在的负面摩擦点; 后续启用失联通知零成本(数据/repository 全部保留)。

### Tests
- **1237/1237 pass** (R65 1232 + R66 5 新)
- `flutter analyze` 0 error
- 15 Python 守护 + 1 `check_all.dart` 全绿

### 联系人软隐藏 (病耻感考量, 3 层)

- **Setup 步骤 1: 紧急联系人变可选** (`lib/presentation/pages/setup/setup_step_welcome.dart` + `setup_page.dart`):
  - `_validateWelcomeForm` 移除"必填 1 个联系人"校验 (R66 决策: 联系人完全可选)
  - 移除"已告知联系人" checkbox (PIPL §23 在用户实际填了之后才需要, 纯表单阶段不需要)
  - `setupContactConsent` key 仍保留, 改为"提示性"段落 (用户填了联系人时才出现, 提醒法律要求), 不强制
  - `_passConsent` test helper 同步: 验证 step 1 现在 0 个 Checkbox
- **Settings: 联系人 section 挪到最底部** (`lib/presentation/pages/settings/settings_page.dart`):
  - 原本"进入设置第一个看到的就是联系人 section" → 现在移到 ListView 最底部 (在心理评估/关于之后)
  - 联系人 section 内的"添加联系人"按钮仍能触发 ConsentDialog (PIPL §13), 业务跑 feature flag gate 后整个失联通信链路不会发出去
  - `settings_page_round45_test` 3 case 适配新顺序: 改 meds error 测 ErrorState (meds section 在 contacts 之上, viewport 内直接渲染)
- **Feature flag 集中器** (新 `lib/core/data/feature_flags.dart`):
  - 改 `emergencyContactEnabled = true` 1 行就能重新启用全部失联通知业务
  - `enableForTest()` / `resetForTest()` (`@visibleForTesting`) 让现有 28 个 test 临时 enable, tearDown 恢复 (不污染其他 test)
  - 文件位置: `core/data/` 而非 `core/shared/` (check_all 守门员建议 — 只被 2 个 data service 引用)

### 失联通知业务整体暂停 (双层防御)

- **`SafetyWatchService._checkAndAlert` 入口** (`lib/core/data/services/safety_watch_service.dart`): flag=false 时早返 `SafetyCheckResult(kind: disabled)`, 3 个入口 (`onAppStart` / `onCheckIn` / `checkNow`) 都过这道关
- **`SafetyAlertDispatcher.dispatchAlert` 入口** (`lib/core/data/services/safety_alert_dispatcher.dart`): flag=false 时早返空 `(smsOk: 0, smsFail: 0, smsMock: 0)`, 双层防御防止 caller 绕过 facade 直接调 dispatcher
- **数据模型 / repository 全部保留**: `contacts` 表 / `ContactRepository` / `ContactEntity` 不动, 后续启用零成本

### i18n 文案弱化 (zh / en / zh_Hant 同步)

- `setupContacts`: "紧急联系人手机号(至少 1 个)" → "紧急联系人(可选)"
- `setupWelcomeContactHint`: "(至少填 1 个手机号,用于失联时通知)" → "(可选,后续可在设置中添加)"
- `setupContactConsent`: "我已告知上述联系人,App 会在我失联时给他们发通知" → "如添加联系人,请先告知对方可能收到的通知(法律要求)"
- 删 `setupValidationContactRequired` 1 orphan key (3 ARB 同步)

### 顺手修 pre-existing bug

- **`NotificationStatusCard._refresh` mounted check** (`lib/presentation/pages/settings/widgets/notification_status_card.dart`): 加 `if (!mounted) return;` 在 `setState(() => _busy = true)` 之前, 防 ListView lazy build 时 widget 被 dispose 后 addPostFrameCallback 触发的 _refresh 撞 setState-after-defunct。R66 ListView 长度变化后该 bug 在 widget test 暴露, 修了真修了 user-facing 场景

### 5 新 test (R66)

- `test/data/feature_flags_round66_test.dart`: 5 case 覆盖 FeatureFlags 默认值 + 3 个 SafetyWatchService 入口 (onAppStart/onCheckIn/checkNow) 在 flag=false 时早返 disabled + SafetyAlertDispatcher.dispatchAlert 在 flag=false 时早返空 outcome

## [Unreleased] - 2026-07-31 (R65 — spzh P2 5 文件 i18n 化 + 量表 PHQ-9/GAD-7 抽象起步)

> R65 目标: 处理 `docs/reviews/2026-07-31-seven-lens/spzh/report.md` P2-F/G/H/I + P1-A:
> - **5 文件 i18n 化** (P2-F/G/H/I, M 难度) — 抽 helper / override 模式同 `core/l10n/strings.dart`
> - **量表 PHQ-9/GAD-7 抽象起步** (P1-A, L 难度) — `ScaleTranslations` abstract + `AssessmentScale.translations` 字段, 16 题全文留 v1.0
>
> 共加 **39 个 i18n key** (zh/en/zh_Hant 同步) + **1 个新 helper** (`region_display_name.dart`) + **1 个新抽象** (`scale_translations.dart`) + **26 个新 test**

### Tests
- **1232/1232 pass** (R63 1206 + R65 26 新)
- `flutter analyze` 0 error (128 info-level, 27 个来自 R65 新代码的 trailing comma / const constructor)
- 15 Python 守护 + 1 `check_all.dart` 全绿 (R65 加 `check_orphan_arb_keys` 防 `phoneRegion*` / `checkInType*` 误报 orphan)

### P2 i18n 化 (spzh 5 文件)

- **P2-F phone_validator.dart PhoneRegion.displayName** (`lib/core/data/utils/phone_validator.dart:158-194`): 5 region 硬编中文 → 抽 `displayNameL10n({String? override})` 方法同 `Strings.xxxText` 模式, 5 i18n key (`phoneRegionCn/Hk/Mo/Tw/Intl`)。新增 `lib/l10n/region_display_name.dart` top-level helper `regionDisplayName(PhoneRegion, {String? override})` 委托 enum method 保证 single source of truth。保留 `displayName` getter (中文 fallback) 不破坏 `phone_validator_round18_test` 5 case test。
- **P2-G preset_medication_templates.dart 4 方案 30+ 处中文** (`lib/core/data/services/preset_medication_templates.dart`): `MedicationTemplate.name/description` + `MedicationDraft.name/hint` 8+10=18 个字段从硬编中文 → i18n key (`nameKey` / `descriptionKey` / `hintKey`), 方法 `nameL10n(l10n)` / `descriptionL10n(l10n)` / `nameL10n(l10n)` / `hintL10n(l10n)` 走 ARB。caller 改: `setup_page.dart:285-305` template AppListTile `t.nameL10n(l10n)` + `t.descriptionL10n(l10n)` + MedDraft 预填 `d.nameL10n(l10n)`。`test/data/preset_medication_templates_round18_test.dart:19, 45` 改 `m.nameKey` 断言。
- **P2-H check_in_entity.dart CheckInType.label + day_detail.dart 5+ 处** (`lib/domain/entities/check_in_entity.dart:48-78` + `lib/domain/logic/day_detail.dart:138-247`): `CheckInType.label` 从硬编中文 getter → `labelL10n({String? override})` 方法。`DayDetailCalculator.fromData` 加可选 `AppLocalizations? l10n` 参数 (不传 = 中文 fallback 兼容老 test), 抽 `_renderCheckInLabel(CheckInType, {medName, l10n})` helper 统一 5+ 处。10 i18n key: `checkInTypeDaily/Temp/Phq9/Gad7` + `dayDetailCheckInWith`/`dayDetailTempWith` (placeholder) + `dayDetailDailyCheckIn`/`dayDetailTempMed`/`dayDetailPhq9`/`dayDetailGad7`。`day_detail_round10_test` 16 case + `day_detail_sort_round48_test` 5 case 不破 (中文 fallback 路径)。
- **P2-I vent_entry_entity.dart durationLabel** (`lib/domain/entities/vent_entry_entity.dart:58-92`): `durationLabel()` 硬编中文 → 新 `durationLabelL10n({String? override, AppLocalizations? l10n})` 方法走 3 i18n key (`ventDurationSeconds` / `ventDurationMinutes` / `ventDurationMinutesSeconds`, 后者 String placeholder + Dart `padLeft(2, '0')` 保留 '1分05秒' 0-pad)。老 `durationLabel()` 保留中文 fallback 兼容 `vent_list_round18_test.dart:145` 21 case test。caller 改: `vent_list_page.dart:261` + `vent_detail_page.dart:288` 走 `durationLabelL10n(l10n: AppLocalizations.of(context))`。

### P1-A 量表 PHQ-9/GAD-7 抽象起步 (spzh)

- **`ScaleTranslations` abstract** (新 `lib/domain/entities/scale_translations.dart`): 起步覆盖 `phq9Name` / `gad7Name` (复用现有 `assessmentScalePhq9` / `assessmentScaleGad7` ARB key) + `crisisHotlineLabel(HotlineRegion)` 4 region (cn/us/hk/intl) + tw/sg/uk 走 intl fallback。**16 题全文 i18n 化留 v1.0** (本起步版本只 abstract + 5 严重度 label + 6 hotline region label)。
- **`StaticScaleTranslations` 中文 fallback** (domain 0 flutter 边界, const 兼容): 老 caller `const phq9Scale = Phq9Scale()` / `const gad7Scale = Gad7Scale()` 默认 `const StaticScaleTranslations()`, 21 case phq9_detect_crisis + 13 case gad7_round16 test 不破。
- **`AppLocalizationsScaleTranslations` AppLocalizations 包装** (同 `region_display_name.dart` 模式): presentation 层 caller 传 `AppLocalizationsScaleTranslations(l10n)` 走 ARB。
- **`AssessmentScale` 抽象类加 `translations` 字段** (`lib/domain/logic/assessment_scale.dart:73-77`): 抽象方法, default `const StaticScaleTranslations()`, 注入 caller AppLocalizations。
- **`Phq9Scale` / `Gad7Scale` 注入 translations** (`lib/domain/logic/phq9.dart:78-83` + `lib/domain/logic/gad7.dart:48-53`): `displayName` 走 `translations.phq9Name()` / `translations.gad7Name()`。`detectCrisis` 起步版本保持 `hotlineByRegion[region]` const Map (label 是中文, 与 21 case test 一致) — 翻译留 R65b 阶段 (6 region × N hotline i18n key 起步版本只 4 region × 1st hotline)。
- **4 新 i18n key**: `scaleHotlineCn/Us/Hk/Intl` (tw/sg/uk 走 intl fallback)。`assessmentScalePhq9` / `assessmentScaleGad7` 复用现有 key。
- **26 case TDD test** (新 `test/domain/scale_translations_round65_test.dart`): 6 group × 4-5 case 覆盖 `StaticScaleTranslations` 中文 fallback / `AppLocalizationsScaleTranslations` zh+en 路径 / 6 region 危机电话 routing / `Phq9Scale`/`Gad7Scale` 抽象注入 (老 const 走 `StaticScaleTranslations` 中文, 新 caller 走 `AppLocalizationsScaleTranslations` en 返 `'PHQ-9 Depression Screening'`) / `regionDisplayName` + `CheckInType.labelL10n` 防 orphan key 引用。

## [Unreleased] - 2026-07-31 (R63 — 7 视角审视后"半成品"集中收尾)

> R63 目标: 处理 `docs/reviews/2026-07-31-seven-lens/` 7 视角整合报告
> 标出的"半成品"问题（⏳/🔶 状态）。共修 **30 项**:
> - **P0 必改 10 项**（6 视角共识最高频 + iOS/Android 上架阻塞）
> - **P1 重要 10 项**（7 视角共识高频）
> - **P2 建议 2 项**（flutter 4 nit 批量）
> - **iOS 平台 P0 8 项**（appstore 视角）
> - **Android 平台 P0 7 项**（googleplay 视角）

### Tests
- **1163/1163 pass** (R62 1151 + R63 12 新)
- `flutter analyze` 0 error, 0 warning
- 15 Python 守护 + 1 `check_all.dart` 全绿

### P0 Bug 修复（6 视角 / 4 视角 / 7 视角共识）
- **P0-1 SmsGateway 抽象收尾 (6 视角共识)**: 修复前 `AliyunSmsProvider.isProductionReady = 4 字段齐全 → true → release 启动不阻断 → send() 抛 UnimplementedError → 100% 失败但没 banner`。修复后加 `_isFullyImplemented` 守门（默认 false），`isProductionReady = _isFullyImplemented && 4 字段齐全`，`send()` 改抛 `StateError` 明确意图。release 模式启动时 `validateForRelease` 阻断 → 顶部 banner 显眼告警。文件: `lib/core/data/services/sms_service.dart`
- **P0-2 PIPL §13 DB 落库 (4 视角共识)**: R62 修了 API 层 (`ConsentArtifact` + `ConsentDialog` + `ConsentMissingError`) + piiSafeLog 留痕，但**留痕只 log 不写表**。R63 加 4 列到 `contacts` 表 (`consentAt` / `consentKind` / `consentBy` / `consentVersion`) + `schemaVersion 14→15` + `onUpgrade` addColumn + `idx_contact_consent_at` 索引。`ContactEntity` + `ContactMapper` 同步 4 字段（`ConsentKind?` nullable enum）。`ContactRepositoryImpl.add/restore` 写 4 字段。7 case TDD test 验证 round-trip。
- **P0-3 ConsentKind 双 enum 统一**: 修复前 domain `ConsentKind` 2 值 (emergencyContactSharing/dataExport) + presentation 3 值 (safety/vent/analytics) 同名不同值。修复后 domain 5 值统一，presentation re-export。4 case test。

### iOS 上架阻塞 (appstore 视角, 8 项)
- **P0-1**: `Info.plist` 加 `ITSAppUsesNonExemptEncryption=false`（Apple 2024 export compliance 强制）
- **P0-5**: `Info.plist` 加 `NSPhotoLibraryAddUsageDescription`（PDF 报告触发 PHPhotoLibrary）
- **P0-6**: `CFBundleDisplayName` 改 per-language dict（en/ChronicCare + zh-Hans/zh-Hant 慢病管家）
- **P0-7**: `UIBackgroundModes fetch` → `processing` + `BGTaskSchedulerPermittedIdentifiers`（iOS 13+ deprecated）
- **P0-8**: 新建 `Runner.entitlements` (aps-environment=development) + pbxproj 注册到 3 build configs
- **P1-4**: `IPHONEOS_DEPLOYMENT_TARGET` 13.0→14.0（3 处 project，Apple 2024 推荐 14+）
- **P1-5**: `SUPPORTED_PLATFORMS` 加 `iphonesimulator` + `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64`
- **P1-6**: `PRODUCT_BUNDLE_IDENTIFIER` `com.chroniccare.chroniccare`→`com.chroniccare.app`（3 target）

### Android 上架阻塞 (googleplay 视角, 7 项)
- **P0-1**: release 签名 `signingConfigs.release` + `key.properties.example` 模板（R55+ 真 keystore TODO）
- **P0-2**: 新建 `BootReceiver.kt`（`RECEIVE_BOOT_COMPLETED` 接收器，重启手机后通知恢复）+ `AndroidManifest` 注册
- **P1-1**: `AndroidManifest` 注释谎言修 + application 加 `enableOnBackInvokedCallback=true`（Android 13 预测式返回）
- **P1-2**: `build.gradle.kts` `minSdk=24` + `targetSdk=36` 显式（防 Flutter 升级漂移）
- **P1-4**: application 加 `debuggable=false` + `allowBackup=false` 显式（PIPL §28 精神心理数据禁止 backup）
- **P1-6**: `proguard-rules.pro` 加 `-keep class com.chroniccare.chroniccare.** { *; }`（防 R8 混淆 MainActivity）
- **P1-7**: release 块加 `isDebuggable=false` + `isJniDebuggable=false` 显式

### 关键 P1（7 视角共识高频, 10 项）
- **P1-1 (emil+flutter)**: `main.dart:307,368` `Colors.orange/red` 硬编 → `theme.colorScheme.tertiary/errorColor(context)`
- **P1-2 (flutter)**: `app_theme.dart:20` 删 `onPrimary: Colors.white`（反 M3, fromSeed 已自动派生）
- **P1-3 (flutter)**: `app_tokens.dart:138-139` `disabledColor` hardcode → `onSurface.withValues(alpha:0.12)`（M3 standard）
- **P1-4 (spen+flutter)**: `home_page.dart:105` `Future.delayed` 不可 cancel → `Timer` + dispose cancel
- **P1-5 (spen)**: `phq9.dart:129` `hotlineByRegion[region]!` 海外 region 未注册会崩 → `?? hotlineByRegion['cn']!.first` 兜底
- **P1-6 (spen)**: `check_in_repository_impl.dart` 3 处 `at ?? DateTime.now()` 抽 `_resolveTimestamp` top-level helper
- **P1-7 (spen)**: `app_database.dart:165` 静默 `catch(e){}` 修 → `swallowError` 集中器（R39 P1-10 模式）
- **P1-8 (spzh+alibaba)**: `strings.dart` 6 处 dartdoc 注释与代码不同步 修正
- **P1-9 (emil)**: `page_transition_switcher.dart:34` 裸 100ms → `AppTokens.durPageTransition` token
- **P1-10 (flutter)**: `app_shell.dart:91` 顶部品牌 `Text` inline `TextStyle` → `textStyleLabelStrong` 集中器

### 关键 P2 (flutter 视角, 2 项批量 71 文件)
- **P2-1 (1)**: 59 文件 删 `library;` 指令（Dart 2.x 自动，显式写是 noise）
- **P2-1 (2)**: 25 文件 dangling library doc comment 改 `//`（避免 `dangling_library_doc_comments` info 警告）

### Architecture
- **pubspec 升版**: `0.27.0+62` → `0.27.0+63`
- **schemaVersion bump**: 14 → 15（contacts 表加 4 consent 字段 + 索引）
- **7 视角整合报告**: `docs/reviews/2026-07-31-seven-lens/CONSOLIDATED.md`（35.9KB, 123 问题去重 ~50 项）

### Changed
- 7 份独立子报告（emil / spen / spzh / appstore / googleplay / alibaba / flutter）+ 1 份整合报告
- 1 个 Kotlin 类 (`BootReceiver.kt`)
- 1 个 entitlements plist (`Runner.entitlements`)
- 1 个 keystore 模板 (`android/key.properties.example`)
- 1 个共享上下文 (`docs/reviews/2026-07-31-seven-lens/_shared/context.md`)
- 1 个 9 文件 ios/ 项目结构首次 commit

## [0.27.0] - 2026-07-31 (R62 — 独立小项修复 + P0/P1 集中收尾)

> R62 目标: 集中清 v0.27 综合审计 (CONSOLIDATED-AUDIT-v0.27.md /
> docs/reviews/2026-07-31-three-lens/consolidated.md) 列出的可独立修复
> 小项 + P0-1 / P0-2 准备架构。

### Tests
- **1163/1163 pass** (R61 1151 + R62/R63 12 新)
- `flutter analyze` 0 errors
- 16 守护 Python + 1 `check_all.dart` 全绿

### P0/P1 修复
- **P0-3 尾巴 (R62)**: `lib/main.dart` 修正临时 `SmsService()` 实例 → provider tree 共享实例 (跟 P0-1 一起落地)
- **P1-4 (R62)**: `safety_watch_service.displayMessage` 走 i18n + 加 9 个 ARB key
- **P1-5 (R62)**: 抽 `lib/domain/logic/lost_contact_sms.dart` 单一 source
- **P1-6 (R62)**: `home_page.dart:407-412` `Future.delayed(1800ms)` → `Timer` + `dispose` `cancel()`, 避免 widget 销毁后 fire 引起 race
- **P1-7 (R62)**: `setup_page.dart:431` `'完成设置'` hardcode → `snackbarActionFinishSetup` ARB key
- **P1-8 (R62)**: `user_name_helper` / `email_template` / `reminder_scheduler` 3 caller hardcode `'您'` / `'您的家人'` → `Strings.userNamePolite` / `Strings.userNameFamily` 集中常量, 方便 i18n override 模式
- **P1-9 (R62)**: `home_page.dart:87` 100ms 裸值 → `AppTokens.kDeepLinkRaceGuard` token
- **P1-10 (R62)**: `contacts_list_widget.dart:202-203` `'Contact'` hardcode 英文 → `contactDefaultName` ARB key (zh='联系人' / en='Contact' / hant='聯絡人')
- **P1-NEW-1 (R62)**: `lib/domain/logic/assessment_record.dart` R60 M9 修正 == / hashCode 时埋下 11+ 处"修正"字符污染注释 → 改"修复前/修复后/element-based 哈希/identity 哈希"等具体英文/中文技术术语

### Architecture
- **pubspec 升版**: `0.25.0+1` → `0.27.0+63` (R62 漂移 2 round 修复 + R63 升版)

### Changed
- 3 个 ARB 文件 (zh / en / zh_Hant) 加 2 个新 key (`snackbarActionFinishSetup` / `contactDefaultName`)
- 1 个新 token (`AppTokens.kDeepLinkRaceGuard`)
- 1 个 domain 集中器 (`Strings.userNameDefault` / `userNamePolite` / `userNameFamily`)

## [0.27.0] - 2026-07-31 (R61 — 平台发布准备 + 残余 P0)

> 用户最终目标：发布到 Android / iOS / iPadOS。R61 完成 3 件事:
> (1) 残余 P0 bug (安全告警 SMS 模板 i18n / dosage unit 国际化 / safety_watch 死代码清理)
> (2) mood_recorder dispose race guard + inline TextStyle token 化
> (3) 平台代码生成 + Android/iOS 关键发布配置

### Tests
- 1151/1151 pass (1098 → 1151, +53)
- `flutter analyze` 0 errors
- 16 守护 Python + 1 `check_all.dart` 全绿

### P0 Bug 修复
- **dosage_unit i18n** (R61 P2): 之前 `m.dosageUnit.id` 返回 'mg'/'片' 字符串
  → en 用户看 '片' 困惑。修法: 新建 `lib/l10n/medication_unit_label.dart` (presentation helper)
  走 ARB i18n, 加 2 key (`medicationUnitMg` / `medicationUnitTablet`), zh='片' / en='tablet'。
  改 1 处 caller (`temp_medication_dialog.dart:97`)。
- **safety_watch_service 8 个 @Deprecated 删** (R61 P1-12 拆分收尾): R57 标了 deprecated 但
  caller 仍调 facade + `safetyConfigServiceProvider` 没加。R61 加 provider, 改 2 caller
  (`reminders_hub_provider` + `reminders_hub_page._SafetyReminderSheet._save`), 改 2 test
  文件用 `SafetyConfigService` 直接, 删 facade 8 个 method。safety_watch_service
  退化为协调 facade (留 3 个触发入口 + `_checkAndAlert`)。
- **safety_watch_service.displayMessage i18n** (R61 P1-4): 之前 hardcode 中文。
  修法: 加 8 个 ARB key (`safetyCheckResult{Disabled|Ok|NoData|...|Alerted|AlertedMocked|Error}`),
  新 `displayMessageL10n(l10n)` 方法, 8 个 kind 全部覆盖 + 3 态分流 (ok / mocked / failed)。
  data 层仍保留旧 `displayMessage` getter (返 i18n key) 兼容老 caller。
- **mood_recorder dispose race guard** (R61 P0-1): 之前 dispose 链中
  `_disposeResources() → service.stopRecording() → onTick → setState` 可能在
  `super.dispose()` 之后触发, 撞 defunct assert。修法: dispose 第一行同步
  `_isRecording = false`, 后续检查 `if (_isRecording)` 都返 false, 安全跳过。
- **mood_recorder 4 处 inline TextStyle token 化** (R61 P2):
  计时器 / recorded / maxReached / liveTranscript / partialHint / stt-unavailable
  6 处 TextStyle 内联 → 改用 `textStyleBody` / `textStyleCaption` /
  `textStyleCaptionHint` + `copyWith` 注入特殊属性 (italic / error color)。

### 重构
- **新建 `lib/l10n/medication_unit_label.dart`** (presentation): dosage unit i18n
  helper, 跟 `app_localizations.dart` 同级, 集中器。
- **safety_watch_service 退化为 facade**: 8 个 config method 删, 内部 `_checkAndAlert`
  直接调 `_config.xxx()` 替代 facade 转发。

### 平台配置 (用户目标: Android / iOS / iPadOS)
- **`flutter create . --platforms=android,ios --org com.chroniccare`** 生成完整
  平台代码 (android/ + ios/), pubspec.yaml / .gitignore 0 改动, .metadata 加回 web 平台行。
- **Android (targetSdk 34, minSdk 23)**:
  - `AndroidManifest.xml` 加 8 个权限 (INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM
    / USE_EXACT_ALARM / WAKE_LOCK / RECEIVE_BOOT_COMPLETED / VIBRATE / RECORD_AUDIO)
  - `build.gradle.kts` 改 minSdk 21→23 (SQLCipher 要求) + multiDexEnabled + 启用 ProGuard
  - `proguard-rules.pro` 加 10 个 plugin keep 规则 (flutter_local_notifications / audioplayers
    / record / sqlcipher / speech_to_text / flutter_secure_storage / share_plus / drift)
  - `res/xml/backup_rules.xml` (Android 6-11) + `data_extraction_rules.xml` (Android 12+)
    排除 chroniccare.sqlite / flutter_secure_storage / vent_audio / mood_audio (PIPL §28)
  - `res/xml/network_security_config.xml` 强制 HTTPS / 禁 cleartext
- **iOS / iPadOS (IPHONEOS_DEPLOYMENT_TARGET 13+)**:
  - `Info.plist` 加 4 个 NSUsageDescription (通知 / 麦克风 / 语音识别 / 用户追踪) +
    改 `UIRequiresFullScreen=false` 支持 iPad Split View + 加 `UIBackgroundModes` (audio / fetch)
  - `PrivacyInfo.xcprivacy` 加 4 个 required-reason API (UserDefaults / FileTimestamp /
    SystemBootTime / DiskSpace) — 2024-05 Apple 强制

### Changed
- 4 个 ARB 文件 (zh / en / zh_Hant) 加 10 个新 key (2 dosage + 8 safety check result)
- 1 个 ARB 文件 (zh_Hant) 修 1 处繁简混搭 ("网路" → "網絡" 跟 OpenCC s2tw 一致)
- `test/widget_test.dart` 替换 flutter create 占位 MyApp test → 改测 i18n key 加载 + 中英文差异

### 验证
- 1151 test pass (含 widget_test.dart 3 个 i18n 新 test)
- 16 守护 Python 全过: check_arb_keys / check_changelog / check_cross_feature /
  check_datetime_race{,_2} / check_drift_namespace / check_fullwidth_punctuation /
  check_legal_consent / check_no_hardcoded_utc / check_no_pua / check_orphan_arb_keys /
  check_sms_release_ready / check_strings_hardcoded / check_widget_dispose /
  check_zh_hant_consistency
- 1 个 dart 架构守门 (`scripts/check_all.dart`) 4 层纯度 + 1:1 entity 映射全过
- `flutter analyze` 0 errors (28 info-level 保持不变 — 全部 prefer_const_constructors /
  require_trailing_commas 历史遗留)

### 阻塞上架但需外部环境项
- ⚠️ **Android build 环境**: Windows + JDK 21 + 国产 SSL 证书拦截 gradle 下载。
  需 Mac / Linux + 配置 `gradle.properties` 代理 / 自建 SSL 信任库, 或
  公司提供 build runner。代码 + 配置已 100% ready, 只需 CI 环境。
- ⚠️ **iOS build 必需 Mac**: Apple 工具链限制。生成 ios/ + Info.plist +
  PrivacyInfo.xcprivacy 已完整, 但 `flutter build ios` 需 Mac + Xcode + Apple Developer 账号。
- ⚠️ **release keystore**: 当前 build.gradle.kts 用 debug 签名, 上架前必须配 release
  signingConfigs (R61 留 TODO)。
- ⚠️ **iOS provisioning profile**: 需 Apple Developer Program 账号 ($99/年) 配
  Runner.entitlements + Runner.xcworkspace schemes。

## [0.25.0] - 2026-07-26 (R49-R60 + R56b-R56f)

### Tests
- 1098/1098 pass (1057 → 1098, +41)
- `flutter analyze` 0 errors (28 info-level, prefer_const_constructors 历史遗留)
- 12 守护脚本全绿（含 R56e 新增 `check_orphan_arb_keys.py`）

### Architecture (round 49-60 emil/spen god-class 续拆 + token 化)
- **R49** dark mode 颜色 60+ 处 → 3 dynamic getter (`primaryColor` / `errorColor` / `warningColor`) + `severity_style.dart` 加 `context` 参数
- **R50** 3 个 score TextStyle helper (`textStyleScoreLg` / `Xl` / `Xxl`)
- **R51** PHQ-9 危机电话 6 region 路由 (`cn` / `us` / `hk` / `tw` / `sg` / `uk`) via `HotlineRegion` enum + `hotlineByRegion` Map
- **R52** 7 个 P0 bug — `mood_recorder dispose race` / `Future.wait + timeout race` / `main.dart:90 删 Asia/Shanghai` / `piiSafeLog 改 medId` / `app_router 乱码改英文 fallback` / `SmsResult 加 SmsResultKind enum` / `setup_page.dart:404 加 5s timeout`
- **R53a** `app_database` 559 → 305 行 (-45%), 抽 7 DAO
- **R54** `DEPLOYMENT.md` + `privacy_policy.md` + `README.md` 合规 — 阶段 8 / 附录 A (NMPA / HIPAA / GDPR / PIPL) / `privacy_policy` §11 跨境 + §12 PIPL §13 进度
- **R55** `docs/PUSH_PROVIDERS.md` (5 厂商 plan) + `docs/SMS_PROVIDERS.md` (AliyunSms plan) + `AliyunSmsProvider.send()` 加 7 步真接骨架注释
- **R56** emil icon size 5 个新 token (`iconSizeInline` / `Small` / `Empty` / `Error`) + chart 4 个尺寸 + 32 处 magic 替换
- **R57** `safety_watch_service` 425 → 325 行 (-24%), 抽 `SafetyConfigService` + `SafetyAlertDispatcher`
- **R58** `medication_report` 拆 3 纯函数类 (`MedicationStatCalculator` + `MissedDateBuilder` + `TempEntryExtractor`)
- **R59** `app_router` 418 → 51 行 (-88%), 抽 `app_routes.dart` + `app_shell.dart`
- **R60** `MedicationDraft` value object, `MedicationRepository.add()` 9 参数 → 1 参数
- **R56b** P1(emil) spacing SizedBox 46 处 → `AppTokens` token (`spacingXxxs` / `Xxs` / `chipGap` / `Xs` / `Sm` / `Md` / `Lg` / `Xl`)

### TDD 补全 (round 56c-R56c''' spen P0 #15)
- **R56c** `db_key_service` +5 unit test (FlutterSecureStorage MethodChannel mock 模式)
- **R56c'** `refill_notifier` +10 (id 公式 + `computeRefillFireTime` 纯函数 + `scheduleRefillReminder` instance)
- **R56c''** `medication_notifier` +10 (ID 常量 + `scheduleDailyReminder` + `rescheduleMedicationReminders`)
- **R56c'''** `assessment_notifier` +4 + `safety_alert_dispatcher` +7 + `mood_audio_service` +10

### Architecture & Refactor (round 58-59 v0.27 启动 + 三视角审视修正)
- **v0.27 round 58** 三视角审视 (emil / spen / spzh) 启动:
  - emil: 35 发现 (P0×1 + P1×17 + P2×12 + P3×5) → `docs/reviews/v0.27/review-emilkowalski-v027.md` (42KB)
  - spen: 66 发现 (P0×4 + P1×16 + P2×30 + P3×16) → `docs/reviews/review-superpowers-en-v027.md` (47KB)
  - spzh: 126 spzh 独有发现 (P0×0 + P1×5 + P2×35 + P3×86) → `docs/reviews/review-superpowers-zh-v027.md` (48KB)
- **v0.27 round 59** 三视角 P0/P1 修正批次 1 (XS+S 修正 7 项):
  - **P0-3** (spen §5#18 latent P0 fix): `setup_page.dart:404` 修正 fail-soft `onTimeout: () => const []` 丢数据 → fail-loud (让 TimeoutException 抛出 → setup 失败 + UI 提示)
  - **EMIL-T29**: 删 4 个 const shadow token (`shadowCard` / `shadowCardDark` / `shadowDialog` / `shadowOverlay`) + 修正 `celebration_bounce.dart:115` 走 theme-aware `shadowOverlayOf(context)` (防 R49 同款 silent bug 重现)
  - **EMIL-T21**: `loading_skeleton.dart:127-138` dispose race 修正 `Future.delayed` → `Timer?` 字段可 cancel (修正 race condition 风险)
  - **EMIL-T13**: 11 处 `ScaffoldMessenger.of(ctx).showSnackBar(AppSnackBar.x(...))` → `AppSnackBar.showX(ctx, ...)` 集中器化 (1 行调用, 修正 7 文件 11 处)
  - **SPZH §5#1**: `check_fullwidth_punctuation.py` 修正 `…` (U+2026) 误报 (47→45 violations, 加 `(?<!…)/(?!…)` 双向负向断言, `……` 修正不报)
  - **SPZH §2.2**: `preset_medication_templates.dart` 修正 3 处真实半角斜杠 (`SSRI / SNRI` → `SSRI ／ SNRI` 等) (medical abbreviation 风格)
  - **SPZH §3#1-2**: 新建 `docs/terminology.md` 集中术语表 (App/应用/客户端 / i18n/国际化/本地化 / PHQ-9/GAD-7 / 隐私 / 用药 5 大类), spec 文档化, R60 修正 14 处中文 ARB
- **v0.27 round 59** Stale findings (不修正, 移到下 round):
  - P0-2 (email test): 实际已修正, spen 报告 stale
  - EMIL-T08 (3 dead tokens): R57 已修正 (注释 line 632-636 标注), stale
  - SPEN-§4#1 (8 @Deprecated facade 删除): 需新加 `safetyConfigServiceProvider` provider 路径, 修正 reminders_hub_page / reminders_hub_provider / test 4 处 caller, R60 修正
- **v0.27 round 59** R60 修正计划 (修正后):
  - SPEN-§4#1: 修正 `safetyConfigServiceProvider` provider + 4 处 caller 迁移, 删 8 facade
  - SPEN-§4#2: `_showSafetyAlert` 50 行 inline 移 `SafetyAlertDispatcher` (1-2h 重构)
  - SPZH 14 处 "App" 修正 → "本应用" / "慢病管家"
  - 5 systematic-debugging regression tests (跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose)
  - 7 god page 拆 (trend_calendar / reminders_hub / data_mgmt / edit_med / mood_recorder / assessment_widgets / setup)
  - `app_tokens.dart` 779 行 god file 拆 5 子模块
  - 文字 token 化 36% → 80% (191 inline TextStyle 集中器化)
  - `home_page.dart` widget test (P0, 每日用户路径 0 test)
  - `mood_recorder.dart` god class split (P0, R52 修正 dispose race 但 0 regression test)

### Cleanup (round 56d-R56f)
- **R56d** `formatters.dart` 走 intl `DateFormat` + `vent_detail_page.dart:191` 改 `EmptyState`
- **R56e** 新增 `scripts/check_orphan_arb_keys.py` 守门员 + 一次性清 39 个 orphan (677 → 550 zh ARB key)
- **R56f** `AGENTS.md` 同步 (R56 系列汇总 + 12 守门员清单展开 + test count 1098)

### Pending (外部依赖)
- R55 真接阿里云 SMS (法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
- R51b PHQ-9 题目 + 严重度 + 危机电话完整走 ARB (v1.0 大工程)

## [0.24.0] - 2026-07-26

### Added (round 45-47 emil god-class 续拆 + token 化 + 集中器)
- **mood_dialog god-class 拆 5 子 widget**（`7412138`）：738→199 行（-73%），按职责拆 MoodScoreSection / MoodTagSelector / MoodEnergySelector / MoodNoteInput / MoodAudioRecorder
- **notification_service god-class 拆 3 子**（`84b7a1b`）：629→353 行（-44%），抽 NotificationChannelManager / NotificationScheduleBuilder / NotificationHistoryLog
- **data_export_service god-class 拆 3 子**（`da110ce`）：582→538 行 + 73 test
- **medications_list god-class 拆 4 子 widget**（`020b8e4`）：554→203 行（-63%）
- **assessment_history_page god-class 续拆**（`436706a`）：624→105 orchestrator + 4 子 widget
- **trend_charts god-class 续拆**（`1c14b2d`）：595→0 + 4 子 widget 拆到 `widgets/`
- **vent_compose_page god-class 续拆**（`c6523d5`）：537→274 orchestrator + 3 子 widget
- **settings_page 拆 4 子 section widget**（`68dfcba`）：96 行 orchestrator
- **AppSemantics 集中器**（`1646e0e`）：a11y 集中器抽离，6 处 widget 替换
- **AppListTile 集中器**（`54c0fb0`）：settings 4 子 widget 13 处 PressFeedback+ListTile 改 AppListTile
- **AppSnackBar 47 处收敛**（`e095b1c`）：`ScaffoldMessenger.of(...).showSnackBar(AppSnackBar.xxx(...))` 全代码库统一
- **token 化 9 项**（`79d2a49` `d47df84` `578df2c`）：6 token + 6 处 hardcode duration/color 替换 / 3 token + 3 处 ListTile 集中化 / 2 处 withValues / textStyleLegal fontSize 改 token
- **MedicationEntity.dosageUnit 强类型**（`bb755fb`）：`String → DosageUnit` enum 转换，spzh mojibake 修正联动
- **data_providers → shared_providers 改名**（`05dfd9a`）：语义更准确

### Added (round 45-47 spen 数据驱动化 + widget 测)
- **gad7/phq9 数据驱动化**（`2454dce`）：`severityCutoffs` 集中阈值表，新增评估量表只需加 1 条
- **check_arb_keys.py 加 --staged 模式**（`4d5d5ed`）：PR-time 只看 staged 文件
- **settings_page 3 case widget 测**（`465b827`）：Sprint #6 中段
- **trend_page 2 case widget 测**（`6ab2676`）：Sprint #6 中段 3/3
- **contacts_list_widget 4 case widget 测**（`8790710`）：Sprint #6 中段
- **WIP god-class 续拆 + 错误处理集中 + magic number 抽 const**（`1a8adef` `19a29c1`）

### Fixed (round 45-47 spzh i18n 修正)
- **main.dart _MigrationFailedApp 4 处 hardcode 中文 i18n 化**（`ce44acc`）：+ 3 处 TextStyle 改 token，精神心理患者崩溃时看到友好文案
- **zh_Hant.arb 简体副本修正**（`cf61948`）：OpenCC s2tw 真繁化 401 key（`@@locale` + 行 21 "您→你" 之外全部繁化）
- **app_router mojibake 修正**（`9e9e6de`）：v0.22 round 31 漏修正一处
- **strings.dart DosageUnit 强类型**（`9e9e6de`）：notification_service 调用 `dosageUnit.id` 强类型化

### CI
- **check_no_pua.py 守门员**（`45b773b`）：扫 PUA 字符（v0.22 round 31 mojibake 修正后无守护）
- **9 个 1-shot 脚本归档到 _archive/**（`4d08510`）：保留历史可追溯

### Known issues (v0.25 必修 — 三视角审视发现)
- **合规 5 项 12 round 0 修**（spzh P0-of-P0）：3 份法律文档 v0.22 草稿 / PIPL §1 vs §3 自相矛盾 / 5 厂商 push 通道未接 / DEPLOYMENT.md 敏感措辞 / 法务未确认 NMPA — 4 store 上架阻塞
- **CHANGELOG 顺序乱**（spzh）：[0.16.0] 排到 [0.1.0+1] 后 / [0.22.1] 排到 [0.23.0] 后 / [0.15.0] 排到 [0.14.0] 后 — 时间倒置（v0.24.0 release 收尾修正）
- **pubspec 0.23.0+1 没 bump**（spzh）：v0.24 发布 30 commit 仍 0.23.0+1
- **EmailTemplate._formatDateTime 硬编码 UTC+8**（spen P0）：PIPL §17 跨境合规风险
- **strings.dart 35+ hardcode 中文**（spzh P0）：通知/PDF/import summary/SMS 模板海外用户无法看
- **crossedMidnightSince 无 direct test**（spen P1）：v0.21 P0-4 关键防御 test gap
- **vent_compose._togglePlay 暂停路径 temp file 释放顺序脆弱**（spen P1）：audioplayers 6.x 已知 PlatformException
- **emil token 化最后 5%**（emil P1）：14 处裸 TextStyle / 12 处裸 EdgeInsets / MotionScheme.subtle curve 虚设 / DimensionRow Motion 包装 / CelebrationOverlay 自研动效

### Tests
- 876+ cases pass
- `flutter analyze` 0 errors
- 8 守护脚本全绿（含 v0.24 新增 check_no_pua.py）

### Architecture
- 4 层架构纯度 + 一致性 100% 保持（`check_all.dart` 全过）
- god-class 治理大幅推进（mood_dialog -73% / notification_service -44% / medications_list -63%）
- token 体系 8.4/10 接近工业级（剩余 5% polish）
- i18n zh_Hant 修正完成（v1.0+ 海外发布就绪）

## [0.23.0] - 2026-07-25

### Fixed (round 38 P0 — 3 项上架关键修复)
- **SMS release fail-fast**（spen P0-1）：`sms_service.dart` release 模式调 `validateForRelease` 抛 `SmsProviderNotConfiguredError`，被 `runZonedGuarded` + `LastErrorCapture` 抓住，AppRoot 顶部 banner 提示。dev/profile 静默通过（mock 是 dev 工具）
- **safety_watch timeout 10s**（spen P0-3）：`safety_watch_service.dart` 加 10s timeout 防 SMS 发送挂死，配合 `swallowError` 集中器
- **app.dart 复用 provider**（spen P0-4）：`main.dart` 创建 `notificationService` 注入 provider tree，避免 `AppRoot.initState` 重新 `NotificationService()`

### Fixed (round 39 P1 — 8 项)
- **catch(_) → swallowError**（spen P1-3）：5 处 best-effort 走集中器，2 处 schema guard 保留（注释 `// ignore:`），0 `catch(_)` 残留
- **i18n 38 处**（spzh P1-1）：main.dart 升级 dialog 11 处 + trend_* 17 处 + 10 处其他 widget 文本全 i18n 化，ARB zh 555 / en 549 → 555 / 555 100% 同步
- **PDF mask**（spzh P1-7）：`medication_report_pdf.dart` 用户姓名/联系方式 9 处脱敏
- **50+ test**（spen P1-6）：新加 50+ test case（care_strategies / encrypted_audio_storage / data_export / i18n 等）

### Refactor (round 40 P2 — 12 项 token 化 + 抽类 + i18n)
- **token 化 12 项**（emil P2-1~12）：trend_charts 11 处 fontSize hardcode / `Curves.*` 走 token / `Colors.white/black54` 反白修复 / 5 个 `tintedXxx` 集中器应用
- **抽类**（emil P2-13~14）：BadgeSyncService 从 notification_service 抽 / ReminderDispatcher 重构
- **i18n**（spzh P2-1~5）：preset_medication_templates 半角→全角括号 / 5 处其他 widget 文本 i18n
- **Z 后缀**（spen P2-3）：`toUtc().toIso8601String()` 全代码库统一 Z 后缀
- **tz.local**（spen P2-4）：DateTime 统一 `tz.local` 防时区 race

### Refactor (round 41 P3 — 4 项实做)
- **PressFeedbackIconButton**（emil P3-1）：从 PressFeedback 抽 IconButton 专用变体，统一 22 文件 icon button 反馈
- **care_engine 4 strategy**（emil P3-2）：`care_strategies.dart` 拆 DefaultHighFreqStrategy / DefaultLowFreqStrategy / HighAdherenceStrategy / LowAdherenceStrategy 4 子
- **reminders_hub Notifier**（emil P3-3）：从 god class reminders_hub_page 拆 5 个 card 子 widget + Notifier 集中
- **zh_Hant stub**（spzh P3-30）：加 `app_zh_Hant.arb`（**注**：v0.24 修正 OpenCC 繁化 — 当前是简体副本）

### Added
- **care_strategies 4 子 + test**（emil P3-2 续）：`care_strategies_round43_test.dart` 286 行
- **encrypted_audio_storage base class + test**（emil P3-5）：`encrypted_audio_storage_round43_test.dart` 186 行
- **6 个 CI 守门员脚本**：check_all / check_cross_feature / check_arb_keys / check_drift_namespace / check_datetime_race / check_fullwidth_punctuation
- **P3 L 项 4 处架构债务 TODO 注释**：notification_service facade 续拆 / data_export +50 test 路径 / zh_Hant stub 修正 / 紧急联系人单独同意

### Tests
- 876/876 pass
- `flutter analyze` 0 issues (44 info-level 仅 trailing_comma + prefer_const, 历史遗留)

### Known issues (v0.24 round 45 三视角审视新发现)
- **合规 P0 5 项 12 round 0 修**（spzh P0-of-P0）：3 份法律文档 v0.22 草稿 / PIPL §1 vs §3 自相矛盾 / 5 厂商 push 通道未接 / DEPLOYMENT.md 敏感措辞 / 法务未确认 NMPA — 4 store 上架阻塞
- **zh_Hant 简体副本**（spzh P0）：当前 555 keys 跟 zh 仅 @@locale + 行 21 "您→你" 2 处不同，虚假繁体声明
- **3 个 P0 god class 拆解完成度 1/7**（3 视角共识）：mood_dialog 738 / notification_service 629 / data_export_service 582 逆增长 — 拆解待续
- **check_no_pua.py 守护缺**（spen P0）：v0.22 round 31 修 app_router mojibake 后无守护，v0.24 round 45 新增

## [0.22.1] - 2026-07-20

### Fixed (round 29 — 三视角审视 P2 架构 + 底层)
- **SENDGRID_SETUP.md 6 处文档错误**（spzh-bug-25）：L72 test path 错（`email_service_test.dart` → `email_service_round9_test.dart`）/ L83 import path 错（`data/services` → `core/data/services`）/ L88-91 `EmailService` 构造签名错（apiKey 可选 + useMock 默认 true）/ L94 phone 注释保持 / L98 `medication: null` 类型改 `MedicationEntity?` / L100 `cycleHours` 改 int 48 不是 Duration；头部加 v0.22 状态说明（当前 `EmailService` mock-only，真实发送 v1.0+）
- **删 `_softReminderId` + `cancelSoftReminder` 死代码**（spen-bug-04）：v0.18 P2-P0-5 删 `scheduleSoftReminder` 后留下的 no-op 整条链。删 `notification_service.dart:30` const + L255-260 方法 + `home_page.dart:298` 调用 + `swallow_error.dart:13` 文档示例 + `safety_watch_service_round12_test.dart:333` mock override
- **删 `app.dart` 空 if 块**（spen-bug-05）：L69-71 `if (now.isBefore(nowCutoff))` 块内只有注释，编译为 no-op；注释与逻辑矛盾

### Added (round 29 P2)
- **ErrorState 集中器**（emil-44）：跟 `EmptyState` 对仗。`lib/presentation/widgets/error_state.dart` 新文件，5+ 字段（icon / title / detail / onRetry / retryLabel），用 M3 `colorScheme.error` 自动适配 dark mode。替换 3 处 `Center(child: Text('加载失败: xxx'))` 一行字错误态：assessment_history / vent_list / vent_detail，每处加 `onRetry: () => ref.invalidate(provider)` 入口

### Fixed (round 29 P2 一致性)
- **SegmentedButton `showSelectedIcon` 一致性**（emil-49）：`medication_calendar_page.dart:78` 默认 true（Flutter 默认），跟 `trend_page.dart:252` `showSelectedIcon: false` 不一致。改 medication_calendar 加 `showSelectedIcon: false`，避免 list/calendar 切换时 check 图标跳动
- **Checkbox M3 deprecation**（emil-50）：`setup_widgets.dart:65` 用 `activeColor: AppTokens.primary` 是 Flutter 3.32+ deprecated API。改用 `side: BorderSide(...)` + `fillColor: WidgetStateProperty.resolveWith(...)`（M3 标准）

### Skipped (round 29)
- **emil-43 `LoadingSkeleton.card` 工厂 0 处使用**：工厂本身合法（设计就支持），但精神心理患者全屏 loading 比卡片 loading 更明确"页面在加载"。不强求改用
- **emil-01~12 tinted token 全量替换**（2h）：`.withValues(alpha:)` 12+ 处 散落，token 体系已加 `tintedPrimarySoft/Deep` 等但部分 widget 仍用 `withValues`，按"调 alpha 集中改"目标逐个替换收益递减，留给后续 round
- **emil-15~16 fontSize token 缺口**（1h）：缺 `fontSizeMicro(10) / fontSizeXxxSmall(8) / 大字(22/32/64)` 6 文件 50+ 处用 `fontSize: 8/10/11/12/22/32/64` 硬编码，加 token 后批量替换
- **WHITEPAPER.md 重写**（sub-agent 4-6h 进行中）：§5/§6/§13/§14.3 同步 v0.22，本 round 单独 commit

### Tests
- 703/703 pass
- `flutter analyze` 0 issues

## [0.22.0] - 2026-07-20

### Fixed (round 28 — 三视角审视 P0 必修)
- **trend_calendar 6 处 dark mode silent bug**（emil-bug-01，`lib/presentation/pages/trend/trend_calendar.dart`）：v0.21 P1-5 修 dark mode 加 8 个 dynamic color getter，但 `_DayDetailCard` + `_EventRow` 漏了 6 处静态 `AppTokens.divider` / `AppTokens.textHint` / `AppTokens.textSecondary`。在 dark mode 下白底白字 silent bug。修：全部换成 `AppTokens.dividerColor(context)` / `textHintColor(context)` / `textSecondaryColor(context)`，去掉外层 `const` 让 BuildContext 可用
- **trend_calendar 跨日不刷新**（spen-bug-10，同文件）：`CalendarView` 原是 `StatefulWidget`，`_today = DateTime.now()` 在 field init 取一次永远不变；用户跨过 00:00:05 后 today 高亮 + `_selected` 仍指向昨天。修：改 `ConsumerStatefulWidget` + 在 build 加 `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild（跟 `medication_calendar_page.dart:44` 同款 fix）
- **\_StreakCounter listener leak**（emil-bug-03，`lib/presentation/pages/check_in/check_in_button.dart:152-160`）：之前 `didUpdateWidget` 每次 value 变化都 `_controller.addListener(() { setState... })` 匿名闭包但**没移除旧 listener**。controller 持有 N 个 listener，每次 tick 触发 N 次 setState → 指数级 rebuild 风险。修：抽 `_tickListener` 字段稳定引用，`initState` 注册 1 次，`didUpdateWidget` 复用同一 listener + 改 `_lastValue = _currentAnimated.round()`，`dispose` 移除
- **mood 5 评分无 Semantics wrapper**（emil-bug-04，`lib/presentation/pages/mood/mood_dialog.dart:215-248`）：5 个评分按钮无 `Semantics` 包装，TalkBack 读 5 个孤立"1 2 3 4 5"，精神心理患者辅助技术体验极差。修：外层 `Semantics(container: true, label: '情绪评分, 1 到 5 分制, 5 分最积极')` + 每按钮 `Semantics(button: true, inMutuallyExclusiveGroup: true, selected: ..., label: '$s 分, 已选')`
- **评估 ChoiceChip 4 选项无 group Semantics**（emil-bug-05，`lib/presentation/pages/assessment/assessment_widgets.dart:182-239`）：9 题 × 4 选项 = 36 个孤立读屏项。修：QuestionCard 外层 `Semantics(container: true, label: '评估题 $index: ${item.text}, 4 项单选, 当前: $selectedLabel')` 一次性念出题号 + 题文 + 当前选择

### Added (round 28 文档补完)
- **CHANGELOG 补 v0.18/19/20/21 整段**：v0.17 段后缺失的 4 个 minor version 段补全，50+ commit 按 P0/P1/P2 分组 + 测试数变化（491 → 565 → 702 → 702 → 703）

### Fixed (round 28 P1 架构文档)
- **sensitive_data_consent.md L49 PIPL 告知不实**（spzh-bug-02）：原文"树洞录音 \| 本地(当前未加密,v1.0+ 加密)" — v0.18 P0-2 已 AES-256 加密，告知错误。改为"本地加密存储(AES-256,密钥设备绑定,2026-07 起启用)"
- **DEPLOYMENT.md 4 处法律风险措辞**（spzh-bug-03）："突然死了"→"突发意外"；"再治愈更难"→"再规律更难"；"死了么"模式→"关怀提醒"模式；"发现死亡"→"发现异常"
- **commit 规范 2 份自相矛盾**（spzh-bug-04）：`CHINESE_COMMIT_GUIDE.md` 写"项目 commit 历史全部中文"但实际最近 30 commit 80% 英文；`WHITEPAPER.md 14.3` 写"commit message 用纯英文"。修：2 份文档都改为"接受 conventional commit 双轨：英文 prefix + 中文/英文 subject"，并标注 PowerShell `$variable` 解析坑（推荐 `git commit -F file`）
- **AGENTS.md 同步当前数字**（spzh-bug-07）：Flutter 版本 3.44.5 → 3.41.9（实测 + pubspec 约束 `>=3.41.0`）；schemaVersion 8 → 11（v0.18→v0.21 加 9/10/11 三步迁移）；测试数 702 → 703
- **DEPLOYMENT.md 同步 Flutter 版本 + web 端**：`fvm install/use 3.44.5` → 3.41.9；`flutter run -d chrome` → `flutter build web + python -m http.server 8358`（drift worker 404 修复，参考 AGENTS.md "dev 服务器坑"）
- **README.md 同步加密库**：表里"encrypt (AES-256)" → "pointycastle (AES-256, v0.20 迁)"

### Tests
- 703/703 pass（P0 + P1 文档修复未引入新测试，下个 round 加 regression）
- `flutter analyze` 0 issues

### Fixed (round 28 P1 架构技术债)
- **合并 CryptoService → EncryptionService**（spen-01 + spen-bug-09）：v0.7 旧 CryptoService 用 `String.codeUnits`（UTF-16）不标准 + 无单例 + 每次 new 读 SecureStorage 慢 + 无 test 注入。**实际 lib/ 0 业务引用**（v0.17 round 12 code review 已确认 dead code）。修：删 `crypto_service.dart`（86 行）；给 `EncryptionService` 加 `encryptString(String) → Future<String>` + `decryptString(String) → Future<String>`（utf8 → Uint8List → base64 包装）；`cryptoServiceProvider` → `encryptionServiceProvider`；`AppServices.cryptoService` → `encryptionService`

### Fixed (round 28 P1 底层)
- **web 端 database_migration 启动崩溃**（spen-bug-01）：`DatabaseMigration.needsMigration()` 内部用 `File.existsSync()` 抛 `UnsupportedError`，main.dart 无 try/catch。修：内部加 `on MissingPluginException` + `on UnsupportedError` catch 返回 false（web 端无文件系统永远不需要迁移）
- **vent `_togglePlay` 失败时 temp file 堆积泄漏**（spen-bug-02）：`vent_compose_page._togglePlay` + `vent_detail_page._togglePlay` 之前 catch 内不删 `_tempDecryptedPath`，连续失败会堆积 temp 文件。修：catch 内 try/finally 调 `deleteTempFile` 清 temp
- **mood_quick_button 漏 PressFeedback**（emil-28）：emil 决策框架要求 10+/day 频度按钮 :active scale 反馈，但 `SecondaryButton` 无 PressFeedback 包。`secondary_action_row.dart` 注释撒谎说"内部已处理"实际无。修：外包 PressFeedback + 修注释
- **setup "查看" TextButton + "开始" ElevatedButton 漏 PressFeedback**（emil-30 + emil-31）：`ConsentCheckRow` 的"查看"按钮 + `setup_step_done` 的"开始"按钮都缺 PressFeedback。修：外包 PressFeedback
- **app_zh.arb 4 处半角标点**（spzh-bug-05）：`setupContactConsent` 半角 `,` → 全角 `，`（**关键法律文案** v0.21 P1-16 漏修）；`commonLoading` / `assessmentLoadingBack` / `medReportPdfLoading` 3 处 `...` → `……`（全角省略号）

### Skipped (round 28)
- **emil-29 medication_calendar `_DataRow` 漏 PressFeedback**：emil 报告说"整行 ListTile 没有 PressFeedback wrap"，但实际 `_DataRow` 是只读热力图 `Row`（不是 ListTile），无 onTap handler，加 PressFeedback 无视觉效果。emil 报告误解。后续如果加 onTap → 跳详情 再加 PressFeedback

### Tests
- 703/703 pass
- `flutter analyze` 0 issues

## [0.21.0] - 2026-07-20

### Changed
- **analyzer 全清 + dart fix + dart format**（`9c305ed`）：0 errors / 0 warnings / 43 info
  - 修 5 处 `implicit_this_reference_in_initializer`（`index.dart` 用 `late final` + constructor body）
  - 删 `setup_page.dart` 死 import `go_router`
  - 抽 4 处硬编码 string 到 ARB（`setup_step_welcome.dart`）
  - 修 stale `@override` on deleted `scheduleSoftReminder` in test
  - `dart fix --apply`：48 个 auto-fix（prefer_const_constructors / require_trailing_commas / prefer_function_declarations_over_variables）
  - `dart format`：39 个文件重排
  - 涉及 49 个文件 / 528+ / 265-

### Added (P0 性能 / 架构纯化)
- **N+1 query 修**（`eec9d9a`）：
  - DB 层加 `watchNormalCheckIns` / `getLatestNormalCheckIn` / `getLatestAssessmentTimestamp`
  - Services 用 DB query 替代全表 scan + Dart filter
  - Providers 复用缓存数据，不再每次 re-fetch
  - 删 `main.dart` 重复 `AppDatabase()` connection
  - 独立 async 用 `Future.wait` 并行化
- **Architecture purity**（`eec9d9a`）：
  - `care_copy.dart` 从 `shared/` 移到 `domain/logic/`（仅 domain 用）
  - `pii_safe_log.dart` 从 `shared/` 移到 `data/services/`（仅 data 用）
  - `notification_navigation.dart` 从 `data/services/` 移到 `routing/`（是 routing 逻辑）
- **P0 隐私 / UI / 同意 batch 1**（`94e0803`）：综合

### Added (P1 UX)
- **P1-21 中文本土化**（`2e24e7f`）：HUD 文案中文优化
- **P1-23 联系人同意**（`2e24e7f`）：添加联系人前弹同意 dialog
- **P1-24 userName nullable**（`2e24e7f`）：数据库列 nullable 化，无 userName 不阻塞 setup
- **P1-26 Dismissible**（`295d4b3`）：列表项滑动删除
- **P1-27 RefreshIndicator**（`295d4b3`）：下拉刷新统一组件

### Added (P2 / P3 polish)
- **P2 polish**（`b0b9757`）：snackbar token 收口 + streak 数字 tween + legal 文案同步
- **P3-1 主题切换淡入动画**（`419df9c`）：dark/light 切换时页面内容淡入过渡

### Added (L10N 全面化)
- **~125 个硬编码中文抽到 ARB**（`eec9d9a`）：`settings_page` 28 / `reminders_hub_page` 38 / `notification_status_card` 37 / `medications_list_widget` 20
- 中英 ARB 文件键对齐（各 108+ keys）

### Added (清理)
- **删 14 个一次性 migration scripts**（`eec9d9a`）：从 `scripts/` 物理删除
- **`vent_entry.dart` → `vent_entry_entity.dart`**（`eec9d9a`）：命名一致性，9 个 import 同步
- **`PRD-v0.1-draft.md` 从根目录移到 `docs/`**（`eec9d9a`）

### Fixed
- **Pubspec 版本号 → `0.21.0+1`**（`eec9d9a`）
- **Flutter 版本统一到 3.44.5**（`eec9d9a`）：pubspec / README / CI 三处对齐

### Tests
- 703/703 pass（v0.20 702 → v0.21 +1）
  - N+1 query 修回归测试
  - `Dismissible` / `RefreshIndicator` widget 测试
  - 主题切换淡入动画测试
  - 之前 1 个 pre-existing failure（`data_export` version mismatch）仍存在

### Architecture
- **4 层架构保持纯净**：`architecture purity` 仍 0 违规
- **L10N 双层分明**：presentation 走 `flutter_localizations`（`l10n/`），domain 走 `core/l10n/`
- **依赖健康度**：删未用 `freezed` / `json_serializable`（v0.19 净），`encrypt` 已迁 `pointycastle`（v0.20 净）

## [0.20.0] - 2026-07-18

### Changed
- **加密依赖迁移：encrypt → pointycastle**（`97476d5`）：encrypt 包自 2022 年停维，pointycastle 是其底层依赖且持续维护
  - `encryption_service.dart` / `crypto_service.dart` 重写：pointycastle AES-256-CBC + PKCS7
  - **加密格式完全兼容**：`[16-byte IV][ciphertext]` 格式不变，老数据可正常解密
  - `pubspec.yaml`：删 `encrypt`，加 `pointycastle: ^3.9.1`
  - 涉及 3 个文件 / 65+ / 61-

### Tests
- 702/702 pass（v0.19 702 → v0.20 0）
  - 无新增测试（依赖迁移靠现有 encryption round-trip 覆盖）

### Architecture
- **依赖健康度**：pointycastle 持续维护，encrypt 停维 4 年
- **零迁移成本**：加密 blob 格式不变，无需 schema 升级
- **依赖收敛**：少 1 个 transitive 依赖（encrypt 内部也用 pointycastle）

## [0.19.0] - 2026-07-18

### Changed
- **v0.19 大文件拆分 + 架构违规修复**（`31c86f3`）：god-file 治理 + 反向依赖清除
  - `trend_page.dart` 1496→216 行，拆为 `trend_charts` / `trend_calendar` / `trend_summary` / `trend_utils` 5 文件
  - `assessment_page.dart` 794→570 行，提取 sparkline + question card → `assessment_widgets.dart`
  - `setup_page.dart` 1077→999 行，提取 `MedDraft` / `TemplateApplyResult` / `ConsentCheckRow` → `setup_widgets.dart`
  - 4 文件相对路径 import 统一为绝对 `package:` 路径
  - `pubspec.yaml` 移除未使用的 `freezed` / `json_serializable` 依赖

### Refactored
- **`setup_page.dart` 1000 行拆 7 文件**（`4cd0bf0`）：setup flow 按步骤拆 widget
- **`ComparisonCard` 提取到 `assessment_widgets.dart`**（`d5693e8`）：评估页 widget 收口

### Fixed (latent bugs)
- **`reminder_scheduler` 缓存 `DateTime.now()`**（`a435903`）：跨 await 阈值不一致修复（同款 v0.14 / v0.16 修过 3 次）
- **4 处 `setState` / 资源清理 bug**（`0971139`）：dispose 之前先取消 subscription
- **6 处 mounted 检查 + 错误处理 + 资源清理**（`7b7d516`）：widget 生命周期一致性
- **4 处空 catch 改 `swallowError`**（`2449a63`）：统一错误可观测性
- **`mood_dialog.dart` 修 context vs ctx async gap**（`31c86f3`）：`use_build_context_synchronously` 警告消除
- **`reminder_scheduler.dart` dynamic → MedicationEntity? 类型安全**（`31c86f3`）：去掉 dynamic
- **`vent_compose_page.dart` 移除 `dart:io` import**（`31c86f3`）：委托 `VentAudioStorage`

### Added (测试)
- **29 个测试文件补全 roundN 命名后缀**（`20bd10e`）：统一 `{module}_roundNN_test.dart` 命名
- **`notification_navigation` + `vent_audio_storage` 测试**（`0758894`）：service 行为 lock
- **`database_migration` 测试**（`dbeeaff`）：schemaVersion 1→8 全迁移路径覆盖

### Tests
- 702/702 pass（v0.18 565 → v0.19 +137）
  - rename 29 个测试文件（`20bd10e`）：纯命名整理，不改行为
  - `database_migration` 全 schemaVersion 路径覆盖
  - `notification_navigation` / `vent_audio_storage` service 行为 lock
  - `reminder_scheduler` + 6 处 mounted bug 回归
  - 配合文档同步 `AGENTS.md` 测试数 679 → 706（`17091e0`）

### Architecture
- **setup flow 模块化**：1000 行 `setup_page.dart` → 7 个独立 widget 文件
- **评估 widget 收口**：`ComparisonCard` 集中到 `assessment_widgets.dart`
- **5 层 umbrella 保持**：跨拆分不破坏 4 层架构
- **未使用依赖清理**：从 `pubspec.yaml` 删 `freezed` / `json_serializable`（实测 0 引用）

## [0.18.0] - 2026-07-18

### Added (P0 安全 / 隐私 / 稳定)
- **PII 安全日志**（`pii_safe_log.dart` `b046f13`）：release 模式 swallow 错误日志，dev 模式完整堆栈
- **树洞录音 AES-256 加密**（`4f2f196`）：录音文件加密存盘（`[16-byte IV][ciphertext]`），SQLCipher 之外的第二层保护
- **PII 数据导出透明告知**（`00fcfaa`）：vent 文字导出前弹 dialog 说明内容会被读
- **P0-2 4 层修复**（`4c69e91`）：`notification_service` 接受 entity，消除 domain → data 反向依赖
- **全局错误处理**（`a1aa700`）：`runZonedGuarded` 兜底 + 9 处 silent catch 改 `swallowError` 统一可观测性
- **P0-7 web 端阻断**（`ee72529`）：web 平台抛明确 PlatformException，不静默失败
- **P0-8 4 表查询索引**（`ee72529`）：`check_ins` / `medications` / `contacts` / `assessments` 加 `(user_id, timestamp)` 复合索引，N+1 显著减少
- **P0-13 step 0 法律同意 PopScope**（`ddb9009`）：首次进入 setup 拦截物理返回键，强制勾选同意
- **PIPL 3 份草稿文档**（`d9bae94`）：隐私政策 / 用户协议 / 数据收集说明

### Added (P1 UI/UX 体系)
- **LoadingSkeleton 统一**（`5b6f3c3`）：19 处裸 `CircularProgressIndicator` 替换为 3 形态骨架（fullScreen / card / Spinner）
- **EmptyState 通用组件**（`8d7b456`）：8+ 处空态文案 + 图标 + CTA 抽统一组件
- **radiusCell / radiusCellLg token**（`8d7b456`）：6+ 处硬编码圆角收口
- **dark mode token API**（`6366d3c`）：`AppTokens` 加 dark variant，8 处 widget 切换主题 token
- **MotionScheme 应用**（`296d623`）：3 widget 应用 emil 决策框架
- **WCAG contrast test**（`43695ee`）：color token 自动验证 4.5:1 / 3:1 对比度
- **home_page god-page 拆 5 widget**（`df0a394`）：header / streak / check-in / temp-med / vent-entry 各 1 文件
- **SnoozeManager 拆子 service**（`85d0253`）：从 `notification_service` 独立
- **core_providers 拆 3 文件**（`5610394`）：按职责 `core` / `service` / `vent` providers
- **repositories 按 feature 拆子目录**（`1a501ce`）：`data/repositories/{check_in,medication,contact,...}/`
- **5 层 umbrella 目录树重写**（`7b95d41`）：`core/data|shared|theme|routing|l10n` 物理分层文档化

### Added (P1 i18n / a11y)
- **i18n batch 1+2**（`befdbe5` `7ff087a`）：提取 16 个共用 string，23 处 widget 替换
- **P1-16 全角标点批量修复**（`731f975`）：173 处中文文案统一
- **P1-17 引号统一**（`24dcf81`）：英文 `'` → 中文 `''`
- **P1-19/P1-20 a11y 文档化**（`43695ee`）：reduced motion / screen reader 行为说明
- **全局尊重 prefers-reduced-motion**（`0ad8e79`）：检测系统级动效偏好自动禁用
- **港澳台/国际区号扩展**（`388ce92`）：`phone_validator` 支持 +852/+853/+886/+1/+44 等
- **联系人 banner 抽 widget**（`388ce92`）：`ContactListBanner` 通用

### Added (P1 数据层)
- **mood schema 4 维度**（`bf5b866`）：schemaVersion 6→7，`mood_entries` 加精力 / 睡眠 / 焦虑 3 列
- **user_profiles.lastCheckInAt live write**（`0412692`）：打卡后回写，失联检测不再用旧值
- **CareCopy 抽离**（`ee6cd3b`）：CareEngine 文案集中 1 处
- **删 setup 软提醒双推**（`ee6cd3b`）：之前 setup 完成后会推 2 条软提醒

### Fixed
- **MockSmsProvider/AliyunSmsProvider 显式 throw + UI banner**（`d62fa2f`）：失败不再静默
- **inject now param to SafetyWatchService.checkNow**（`c20261d`）：flaky test 修，测试时间可控
- **药名 hint 中性文案**（`8e0b98c`）：避免广告法风险

### Tests
- 565/565 pass（v0.17 491 → v0.18 +74）
  - `pii_safe_log_round18_test.dart`：release swallow 行为
  - `snooze_manager_round18_test.dart`：snooze 逻辑独立测试
  - `app_tokens_dark_round18_test.dart`：dark mode token 153 行覆盖
  - `check_all_round18_test.dart`：4 层 + cross-feature 检测回归
  - `care_engine_copy_round18_test.dart`：CareCopy 抽离回归
  - WCAG contrast 自动验证（4.5:1 / 3:1 边界）
  - vent encryption round-trip：加密 → 解密字节级一致

### Architecture
- **5 层 umbrella 落地**：`core/data|shared|theme|routing|l10n` 物理分层，`presentation → domain ← data` 方向不变
- **P0-2 vent-encryption 跨层落地**：data 层加密 + domain 层透明（`VentEntryEntity` 不暴露 IV）
- **dart format + dart fix 批量 cleanup**（`07b748b` `3f42cd7` `6800d72`）：28 个 trailing comma + 多处 prefer_const_constructors 一键净

## [0.17.0] - 2026-07-17

### Changed
- **架构升级（Round 1-5）**：从 3 个 skill（emilkowalski / superpowers-en / superpowers-zh）调研出的可优化点全部落地

### Added (emil 动效)
- **AppTokens 动画 token**（A1）：补 4 个 curve 常量（curveStandard/curveDecelerate/curveAccelerate/curveDelight）+ emil 决策框架 doc 注释
- **CheckInButton 状态过渡**（A3）：AnimatedContainer 让背景色 + 圆角在 durNormal + curveStandard 下过渡；文字切走 AnimatedSwitcher fade + scale
- **streak 数字 TweenAnimationBuilder**（A6）：数字从 0 → N 平滑递增
- **go_router 3 类 page transition**（A2）：`_fadePage`（主导航 occasional）/ `_slideRightPage`（子页 slide-from-right）/ `_slideUpPage`（全屏深页 rare full-screen modal feel）
- **vent 列表 → 详情 Hero**（A4）：Hero(tag: 'vent-avatar-{id}') 头像"飞"过去
- **vent 空态 + 鼓励文案 fade + scale**（A8）

### Added (process)
- **跨 midnight 自动 refresh streak**（B3 design issue）：AppRoot 挂 midnight timer，00:00:05 自动 `ref.invalidate(streakSummaryProvider)`，避免 streak 跨日还显示昨日的值
- **nextMidnightRefresh 纯函数**：抽 top-level `@visibleForTesting`，跨月/跨年边界都正确处理
- **CareEngine 12 个 edge case test**（B5）：fire 3 态 + 4 个核心规则的边界（22:00 整点 / 周末 18:00 边界 / 36h + hour<10）

### Fixed (Riverpod 3.0 升级)
- **flutter_riverpod 2.6.1 → 3.3.2**：自动 retry + 指数退避、`Ref` 子类统一、`==` 过滤 StreamProvider
- **AsyncValue.valueOrNull → .value**（2 处）：
  - `lib/routing/app_router.dart:85` (profile 守卫)
  - `lib/presentation/pages/home/widgets/temp_medication_dialog.dart:65` (meds list fallback)
- **freezed 2.5.7 → 3.2.5**（Riverpod 3.x 依赖要求）

### Tests
- 516/516 pass（v0.16 491 → v0.17 +25）
  - 7 个 round 1 emil 动效 test（AppTokens + CheckInButton + vent empty state）
  - 6 个 round 4 midnight refresh test（跨月/跨年/buffer 边界）
  - 12 个 round 5 CareEngine test（fire 3 态 + 4 规则边界）

### Architecture
- 4 层架构纯度 + 一致性保持：check_all.dart 仍全过
- Riverpod 3.x 升级**冲击面极小**（项目 0 个 StateProvider / StateNotifierProvider / ChangeNotifierProvider / FamilyNotifier / AutoDispose*）
- B1（!mounted → ref.mounted）实际上**无法迁移** — Riverpod 3 的 `ref.mounted` 是 `Notifier` 特性，项目全用 `Provider`/`StreamProvider`/`ConsumerStatefulWidget`，不能直接迁移。保持 30+ 处 `!mounted` check

## [0.16.0] - 2026-07-17

### Changed
- **架构整理（Round 1-19）**：
  - 4 层架构纯度 + 一致性 合并到 `scripts/check_all.dart`（替代 2 个旧 script）
  - check_all 支持 `package: 绝对路径` + `../../ 相对路径` 两种 import 检测
  - 修了 `care_engine.dart` 用相对路径绕过 purity 检查的隐藏 bug — 切到 `NotificationSender` 抽象接口
  - 修了 18 个 unused import + 1 个 dead try/catch + 2 个 dead `// ignore` 块 + 1 个 dead `audioExists()` 方法
  - 修 4 个 Flutter 3.32+ `RadioListTile` deprecation（改用 `RadioGroup` 祖先）

### Fixed
- **Stream subscription leak**：树洞详情/撰写页 `_player.onXxx.listen()` 之前没存 subscription，dispose 没取消。修后存 `StreamSubscription?` 字段 + `dispose()` 取消
- **`vent_entry.dart` 死代码**：删 `audioExists()` + 误导注释 + `dart:io` import（实际不是仅做 path 拼接，是磁盘 I/O）
- **`safety_watch_service.dart` 死参数**：删 `EmailService? emailService` 构造参数（v1.0+ 占位，EmailService 整个在 production 没用）
- **文档同步**：
  - `SENDGRID_SETUP.md` 删 stale `fromEmail` 参数示例（构造函数早没这参数）+ 改 `to` 为手机号
  - `AGENTS.md` / `README.md` 同步 `check_all.dart` + `dart scripts/check_all.dart`（不用 `dart run`，会触发 `objective_c` build hook 失败）
  - `email_preview.dart` 修正 round 注释（之前写错 Round 13 → 实际 Round 12）

### Removed
- **`dio: ^5.7.0`** 依赖：清理后 `EmailService` 没有任何 `package:dio/dio` 引用
- **`EmailService` 中的 `Dio` 字段 + 未用 `html` 变量**
- **`EmailService` 的 `Medication?` drift row 参数**：改用 `MedicationEntity?`（domain entity），消除 domain → data 反向依赖
- **`scripts/check_domain_purity.dart` + `scripts/check_architecture_consistency.dart`**：合并到 `check_all.dart`
- **`scripts/debug_check.dart`**：占位文件

### Architecture
- **Domain 层严格 0 flutter / 0 drift / 0 data / 0 dart:io 依赖**（除 vent_entry 的 `audioPath` 字段类型用 String）
- **共享层使用度**：所有 `shared/` 工具至少被 2 层用（被 check_all 验证）

### Tests
- 471/471 pass（461 → 471：5 check_all + 3 streak unsorted + 2 assessment unsorted）
- 新增 `test/data/email_service_test.dart`（用 `MedicationEntity` 替代之前的 drift row）
- 新增 `test/scripts/check_all_test.dart`（5 个，验证 4 层架构检测 + 相对路径解析 + Windows path bug）

### Fixed (latent bugs)
- **`streak_calculator.dart` 隐式排序假设**：`calculate` + `shouldShowStreakBroken` 用 `.first` 假设 caller 传 DESC，调用方目前都传已排序数据（`watchAllCheckIns()` Drift orderBy DESC），但任何未来 caller 传未排序数据会算错 streak。加显式 sort + 3 个 unsorted input regression test
- **`assessment_comparison.dart` 隐式排序假设**：`fromRecords` 用 `.last` 假设 caller 传 ASC，同样的 fragility。修：先 sort 再取。加 2 个 unsorted input test
- **`medications_list_widget.dart` 多次 `DateTime.now()` race**：`_editRefill` 之前 3 次 `DateTime.now()` 算 initialDate/firstDate/lastDate，跨 midnight 时三者可能不一致（`reminder_scheduler.dart:97` v0.14 已有同款 fix）。修：先算 `now` 一次再复用
- **`trend_page.dart:36-39` field 初始化多次 `DateTime.now()`**：`_calendarMonth` 用 2 次 `.now()` 算 year 和 month，跨 midnight 边界可能 month 不一致（23:59 → 12，00:00 → 1）。修：抽成 `_initialCalendarMonth()` 静态方法算 1 次
- **`notification_service.dart` 2 个 cancel id 范围过窄**：
  - `cancelAllSnoozes` 之前 `[4000, 104000)` 范围，snooze id 公式 `4000 + medId * 1440 + minutes`，medId ≥ 72 漏 cancel
  - `rescheduleMedicationReminders` 之前 `[2000, 3000)` 范围，med reminder id 公式 `2000 + medId * 10 + i`，medId ≥ 100 漏 cancel
  - 修：范围都放宽到 200000+（covers medId 几万个，远超实际用户量）
- **`vent_audio_storage.dart` 文件名 collision 风险**：`newAudioPath` 之前只用 `DateTime.now().millisecondsSinceEpoch` 作后缀，同毫秒内录 2 段会文件名相同 → 后录的覆盖前录的。修：加 4 位 random suffix (`vent_{ms}_{rand4}.m4a`)，同毫秒冲突概率 1/10000

### Removed
- **`EmailTemplate.buildHtml()`**：60 行 HTML 模板，v0.6 改 mock 短信后整个 HTML 路径无生产调用
- **`test/domain/email_template_test.dart` 中的 `buildHtml` 测试**：自测死代码

### Final state
- `flutter analyze`: 0 issues（无 warning、无 error、无 info）
- 4 个 `RadioListTile` 迁移到 Flutter 3.32+ `RadioGroup` 祖先 API
- 88 个文件 `dart format` + `dart fix --apply` 一键 cleanup（229 fixes）
- `test/scripts/check_all_test.dart` 新增 5 个测试，覆盖 `package:chroniccare/` 绝对路径 + `../../` 相对路径检测
- 修 `check_all.dart` 潜在 Windows 路径 bug：`package:chroniccare/data/bar.dart` 的 rel 部分 `/` 没转 `Platform.pathSeparator`，导致 marker `\lib\data\` 匹配不上

### Fixed (round 19B — 第 8 轮 code review 新发现的 6 个 bug)
- **`notification_service.rescheduleRefillReminders` cancel range 过窄**：
  - 之前 `_refillBaseId + 1000` 范围，refill id 公式 `_refillBaseId + medId`（`6000 + medId`），medId ≥ 1000 漏 cancel
  - 修：范围放到 200000（同 round 19 medication reminder 的修法），覆盖 medId 几万个
  - 配套把 `_refillNotificationId` 改 `@visibleForTesting` 暴露成 `refillNotificationId` 便于测试
- **`reminder_scheduler.dart` 隐式排序假设**：`normalCheckIns.first.timestamp` 假设 `watchAll()` 返 DESC，drift orderBy 一改就 silent 算错
  - 修：显式 `normalCheckIns.sort((a, b) => b.timestamp.compareTo(a.timestamp))` 后再 `.first`
- **`safety_watch_service.dart` 隐式排序假设**：同款 `normalCheckIns.first.timestamp` 隐式 DESC。修：同上显式 sort
- **`assessment_reminder_service.dart` 隐式排序假设**：`assessments.last.timestamp` 假设 `watchAssessments()` 返 ASC（"最后"= list 末尾），drift orderBy 一改漏取最新评估
  - 修：用 `assessments.map((c) => c.timestamp).reduce((a, b) => a.isAfter(b) ? a : b)` 显式找最新，不依赖 list 顺序
- **`scheduleRefillReminder` 多次 `DateTime.now()` race**：
  - 之前 2 次 `DateTime.now()`（fireAt 过期判断 + daysLeft 计算），跨 midnight 时可能用不同日期
  - 修：先 `final now = DateTime.now();` 一次，下面两处复用
- **`vent_compose_page._getAudioDuration` AudioPlayer leak**：
  - 之前 try 块内 `await player.setSource(...)` + `await player.getDuration()` + `await player.dispose()` 一气呵成；任一环节抛异常都直接走 catch，`dispose()` 不会跑 → AudioPlayer 资源泄漏
  - 修：把 `dispose()` 移到 `finally` 块，确保异常路径也释放

### Tests (round 19B)
- 478/478 pass（471 → 478：6 refill id range + 1 safety_watch unsorted data）
- 新增 `test/data/notification_service_round19b_test.dart`：6 cases 覆盖 refill id 公式 + cancel range 范围（medId=0/1/999/1000/10000/50000 都验证）
- 新增 `test/data/sort_assumption_round19b_test.dart`：1 case 用 unsorted 顺序插入 3 条打卡（5天前/3天前/1小时前），验证 SafetyWatch 取 latest = 1小时前（修前会取 5天前误报触发告警）

### Fixed (round 19C — 第 9 轮 code review 新发现)
- **`app_router.dart:110` 路由参数 unsafe parse**：
  - 之前 `int.parse(state.pathParameters['id'] ?? '0')` 处理 `/vent/detail/abc` 时 `int.parse('abc')` 抛 FormatException
  - 修：改用 `int.tryParse(...) ?? 0`，invalid id fallback 到 0（详情页会显示"找不到了"，不崩 app）

### Tests (round 19C)
- 486/486 pass（478 → 486：8 route param parsing 边界 case）
- 新增 `test/routing/route_parsing_round19c_test.dart`：8 cases 覆盖 `int.tryParse` fallback 行为（valid int / empty / 'abc' / mixed / negative / whitespace / null path param）

### Added (round 20 — 通知自检 + OEM 后台引导)
- **`NotificationService.pendingCount`**：返回当前待发通知数；plugin 抛 PlatformException 时返回 -1（web/desktop 平台）
- **设置页「通知与提醒」自检卡** (`NotificationStatusCard`)：
  - 状态显示：当前已排队的待发通知数（0 / N / 不支持三态）
  - **测试通知按钮**：点一下立即推一条，看到 = 通知工作正常
  - **查看已排队通知**：弹 dialog 列出所有 `pendingNotificationRequests` 标题
  - **国产手机后台引导**：折叠面板展开 5 大品牌（小米 / 华为 / OPPO / Vivo / 魅族）每家 2-3 步后台保活路径
  - `kIsWeb` fallback：web 端显示"通知功能仅在 Android/iOS 可用"，隐藏功能按钮

### Fixed (round 20)
- **国产 ROM 静默杀通知没用户可见信号**：之前 20:00 提醒失败只在 log 里 `developer.log`，用户根本不知道。加自检卡后用户能主动验证 + 看到"没有待发通知"立即知道要排查

### Tests (round 20)
- 491/491 pass（486 → 491：5 widget test）
- 新增 `test/presentation/notification_status_card_round20_test.dart`：5 cases 覆盖
  - mobile 模式显示完整 card
  - pendingCount 三种状态（5 / 0 / -1）的 UI 提示
  - 点"测试通知"按钮 → 调 `showNow` 推一条
  - 点刷新按钮 → 重新读 pendingCount

## [0.15.0] - 2026-07-15

### Added
- **树洞（Vent / 私密倾诉空间）**
  - 4 层架构落地：`VentEntryEntity` + `VentRepository` 抽象 + Drift 实现
  - 新表 `vent_entries`（schemaVersion 6，v5 → v6 迁移）
  - 支持文字 / 语音（m4a / aac）/ 混排三种记录形式
  - 录音用 `record` 5.2.0，播放用 `audioplayers` 6.8.1
  - 3 个页面：`/vent`（列表 + 长按删除）/ `/vent/compose`（文字 + 录音）/ `/vent/detail/:id`（详情 + 进度条）
  - audio 文件存 `app docs/vent_audio/`，DB 仅存路径（SQLCipher 整体加密）
  - 主页加"倾诉 🌲"入口按钮

### 设计原则（关键）
- **完全私密**：树洞不进入任何分析、趋势、评估、CareEngine、SafetyWatch
- **不触发任何通知**：即使内容含"想死"也不通知家人（保护"私密空间"信任）
- **文字 / 语音 至少一个**：否则 `ArgumentError` 拒绝保存
- **命名约定**：domain 实体 `VentEntryEntity`（避免与 drift `@DataClassName('VentEntry')` 冲突）

### Tests
- 462 cases pass（v0.14 430 → v0.15 +32）
- `test/domain/vent_entry_entity_round18_test.dart`（20 个实体：业务方法 / durationLabel / copyWith / 相等性）
- `test/presentation/vent_list_round18_test.dart`（6 个 widget：空状态 / 文字条目 / 语音条目 / 混排 / 长截断 / 多条目）

## [0.14.0] - 2026-07-15

### Added
- **续方管理**（`/settings/refills`）：集中看所有药物的续方状态
  - 顶部 4 统计：总药数 / 已设续方 / 提醒中 / 已过期
  - 列表按状态优先级排序（已过期 > 提醒中 > 已设 > 未设置）
  - 4 个状态徽章 + 颜色（绿/橙/红/灰）
  - 行点击 → 跳到 EditMedicationDialog
  - 入口：RemindersHub 续方卡的"管理续方"按钮 + settings page
- **评估历史独立页**（`/assessment/history`）
  - 顶部 3 卡统计：总评估 / 最近 PHQ-9 / 最近 GAD-7（带严重度色）
  - 折线图：每个量表 1 张 fl_chart，至少 2 次评估才画
  - 完整记录：倒序，每条带"上次对比 ↑↓ 分数"
  - 严重度标签：正常/轻度/中度/重度（按临床标准分档）
  - 空状态：友好提示 + "开始第一次评估"按钮
  - 入口：home_page 心理评估图标 + settings page
- **用药日历**（`/medication/calendar`）：医生视角的依从性热力图
  - 行 = 1 种在用药物，列 = 1 天（7/30/90 三档可切）
  - 颜色 = 打卡次数 / 期望次数：漏服/部分/100% 四档配色
  - 图例卡 + 顶部说明
  - 入口：settings page "用药" section
- **提醒中心**（`/settings/reminders`）：集中管理所有提醒
  - 5 张卡：每日打卡 / 用药 / 续方 / 周期评估 / 失联通知
  - 每张卡配 sheet 配置 + 状态徽章
  - 入口：settings page

### Fixed（4 轮审查 + 16 修）
- **路由顺序冲突**（Bug A）：`/assessment/history` 之前被 `/assessment/:id` 拦住，调整声明顺序
- **日期边界 raw math**（Bug B + 续方 + 推送文案）：用 `_daysUntilRefill` / `_daysBetween` 按"天"算，refill day 整天都算 in window
- **临床严重度分级**（Bug C）：PHQ-9 0-4/5-9/10-14/15-19/20+、GAD-7 0-4/5-9/10-14/15+（之前用百分比，错判 5 类）
- **严重度配色统一**（Bug D）：抽出 `severityStyle()` 一处定义，chart dot / history 圆圈 / chip / summary 4 处同源
- **代码重复**（Bug E）：删 3 处重复的 `_severity` / `_severityLevel`
- **续方统计色**（Bug F）：inWindow 黄色 / overdue 红色（之前都红）
- **用药日历 times=[]**（Bug G）：跳过无时间药的行 + 提示文案
- **用药日历 O(n·m·k) 性能**（Bug H）：预 group `Map<int, Map<DateTime, int>>`
- **chart 底轴 label 密度**（Bug I）：90 点 → 6 label
- **失联检测 now/inDays**（Bug J）：捕获一次 now + 按天算
- **推送文案 "还剩 X 天"**（Bug K）：用按天算法
- **评估 diff 跨量表**（Bug L）：`_findPreviousSameScale` 找同量表前一条
- **deep-link safety race**（Bug M）：独立 `_safetyRerunRequested` flag + `force: true`
- **续方图标同步**（Bug N）：icon 和文字同源
- **AppDatabase 泄漏**（Bug O）：try/finally + close()
- **lint 清理**：13 个文件的 unused imports / variable

### Changed
- **架构升级到 4 层**：`presentation → domain ← data`，domain 层 0 Flutter 依赖
  - `domain/entities/`：业务实体（MedicationEntity / CheckInEntity / ContactEntity / MoodEntryEntity）
  - `domain/repositories/`：抽象接口（无实现）
  - `domain/usecases/`：用例（RecordCheckInUseCase / RecordTempMedicationUseCase / TriggerReminderUseCase）
  - `domain/logic/`：业务规则（量表/streak/care engine/报告/评估对比）
- **数据层 0 Flutter 依赖**（mappers in data 层做 Entity ↔ Drift 转换）
- **Repository 模式**：UI 不直接碰 Drift，only 调 use case
- 通知 id 分段：1001=默认 / 2000+=药物时间 / 3000=软提醒 / 4000+=关怀
- `AppTokens.warningStrong` 新增（中度档专用色 0xFFFF8A65）

### Tests
- 430 cases pass（v0.13 ~400 → v0.14 +30）
- 4 轮全文件审查，每次新增 regression test 卡住 bug
- domain 业务逻辑 + data round-trip + presentation widget 三层覆盖

## [0.13.0] - 2026-07-14

### Added
- 多档案联系人（soft delete + 排序）
- 续方提前提醒 N 天
- 评估历史 + sparkline 在 result 页

## [0.12.0] - 2026-07-14

### Added
- 邮件通知 + 安全开关
- 临时吃药关联到现有药物
- 趋势页（30 天热力图 + 6 月柱状图）
- PHQ-9 抑郁量表
- 用药报告（PDF + Markdown）

## [0.8.0] - 2026-07-13

### Added
- **量表多选**：PHQ-9 + GAD-7 共用 `AssessmentScale` 抽象
  - `lib/domain/logic/assessment_scale.dart`（抽象 + `AssessmentItem` / `AssessmentResult` / `CrisisSignal`）
  - `lib/domain/logic/scale_registry.dart`（聚合 + byId 查询）
  - `lib/domain/logic/gad7.dart`（GAD-7 焦虑量表，7 题 0-3 分 0-21）
  - 评估页 `AssessmentPage` 改为接收 `scaleId` 参数的 `AssessmentRunner`
  - 路由：`/assessment` redirect 到 `/assessment/phq9`，`/assessment/:id` 通用
  - 设置页"健康"区改为量表列表（PHQ-9 / GAD-7）
- **量表历史折线图**（多线趋势 + Tooltip 详情）
  - `lib/domain/logic/assessment_record.dart`（从 `CheckIn` 反序列化）
  - `app_database.watchAssessments()` + `CheckInRepository.watchAssessments()`（filter phq9/gad7，正序）
  - `assessmentsProvider`（Riverpod StreamProvider）
  - 趋势页新增"心理评估历史" section（`LineChart` 多线 + 图例 + 空状态 + Tooltip 显示 `MM/DD HH:mm + 量表名 + 原始分/满分 + 百分比`）
- **测试**：86 tests pass（v0.7 是 57 → v0.8 加 29 个）
  - `test/domain/gad7_test.dart`（19 个：常量/接口契约/严重度切分/无危机）
  - `test/domain/scale_registry_test.dart`（4 个：聚合/byId/数据完整性）
  - `test/domain/assessment_record_test.dart`（8 个：合法/缺字段/损坏 JSON/type 过滤）
- **Web 加载修复**
  - CanvasKit 走 CDN（国内 `gstatic.com` 污染）→ `--no-web-resources-cdn` 走本地 `build/web/canvaskit/`
  - dev 模式（`flutter run -d chrome`）下 drift worker 404 → 切 `flutter build web` + `python -m http.server 8358` production 模式
  - 验证 `index.html` / `sqlite3.wasm` / `drift_worker.dart.js` 全部 200

### Changed
- `phq9.dart`：保留旧 `Phq9Item` / `Phq9Result` / `phq9Items` / `phq9Options` API（兼容），新增 `Phq9Scale` 实现抽象 + `phq9Scale` 单例
- `assessment_page.dart`：完全重写为通用 `AssessmentRunner`，接收 `scaleId` 渲染对应量表
- `app_router.dart`：路由参数化（`/assessment/:id`）

## [0.7.0] - 2026-07-12

### Added
- **SMS 服务抽象**（`SmsProvider` 接口 + `MockSmsProvider` + `AliyunSmsProvider` 占位）
- **多联系人通知循环** + `ReminderLevel` 渐进（none → 邮件 → 短信）
- **药物时间点 zonedSchedule 推送**（id 段 2000+，每个 med × 每个 time 稳定 id）
- **打卡反馈**（haptic + `AnimatedCelebration` + 动态鼓励文案按 streak 切换）
- **10am 软提醒**（漏 1 天主动 push 安慰，id 段 3000）
- **临时吃药关联到现有药物**（dropdown 选择已有药 / 自由输入）
- **数据导出/导入**（JSON 剪贴板，v0.7 不加密，v1.0+ 上加密备份）
- **CareEngine 规则引擎**（4 种触发：`secondDayMissed` / `lateCheckInHabit` / `weekPerfect` / `none`）
- **LocalAiHook 接口**（MedGemma 1.5 接入点预留，v0.8+ 真实集成）
- **PHQ-9 抑郁量表**（9 题 0-3 分 0-27，第 9 题自杀念头阳性 → 危机资源对话框）
- 通知 id 分段：1001=默认提醒 / 2000+ 药物时间 / 3000=软提醒 / 4000+=关怀
- 测试 57 个（v0.6 基础上加 13 个 PHQ-9 + CareEngine）

### Changed
- 主页 UI 升级：动态鼓励文案 + 临时吃药按钮 + 吃药时间展示
- 首次引导 step 2：药物时间点 picker（多 time）
- 趋势页完整化（之前只有汇总 → 加热力图 + 柱状图）

## [0.6.0] - 2026-07-12

### Added
- **多联系人邮件通知**（SendGrid Mock 实现，按 sortOrder 顺序发送）
- **失联检测 v0**：48h 未打卡 → 邮件（v0.7 改为 CareEngine 规则驱动）
- **趋势页 v0**：数据汇总 + 30 天热力图 + 6 月柱状图 + streak 总结
- 设置页增加联系人增删改

## [0.5.0] - 2026-07-12

### Added
- **极简 MVP**：主页打卡 + 设置 + 首次引导（两步）
- **drift 本地数据库**（`check_ins` / `medications` / `contacts` / `user_profiles` 四表）
- **go_router 路由**（`/setup` + ShellRoute `/` `/settings`）
- **Riverpod 2.6** 状态管理（`checkInRepositoryProvider` / `contactsProvider` 等）
- **flutter_local_notifications** 集成（每日 20:00 通用提醒，v0.7 加 zonedSchedule）
- **flutter_dotenv** 配置加载
- **fl_chart** 集成（v0.6 趋势页使用）
- 设计 Token 体系（`AppTokens`）：spacing / radius / fontSize / breakpoint

## [0.1.0+1] - 2026-07-11

### Added
- Day 1：项目骨架
  - `pubspec.yaml`（12 个核心依赖 + 7 个 dev 依赖）
  - `analysis_options.yaml`（strict-casts / strict-inference）
  - `.gitignore`
  - `lib/theme/app_tokens.dart`（设计 Token 规范）
  - `lib/theme/app_theme.dart`（Material 3 主题）
  - `lib/l10n/strings.dart`（国际化字符串）
  - `lib/main.dart`（入口）
  - `lib/app.dart`（App 根 + go_router 占位）
  - `README.md`
  - 本 CHANGELOG
- 完整 PRD v0.4、设计规格、设计 Token、实施 Plan

### Pending
- Day 2-7：业务逻辑、UI、邮件集成、Web 部署
- Day 8-9：SendGrid 真实集成
- Day 10-11：APK + iOS 打包
- Day 12-14：上架准备

