# superpowers-zh 视角深度审计 (2026-08-10 cleanup)

**项目**: ChronicCare v0.30.0+85
**审计日期**: 2026-08-10
**审计基线**: R105 (2026-08-09) + R100 6 视角收尾 (2026-08-07) + R101
**审计视角**: 中文 i18n / 注释 / 提交规范 / 文档 / Git 工作流 / 国产 ROM / 隐私合规 / 中文 UI 排版
**对比基线**: R103 spzh 9.0/10 (2026-08-08) → R105 spzh 9.0/10 (2026-08-09) → 本次

---

## 评分 (持平 R105)

- **工程实践**: 9.0 / 10 (持平 R105)
- **合规上架**: 4.5 / 10 (持平 R105, R100 P0 已修 5 项但 4 项上架 blocker 仍卡外部依赖)
- **总评**: 7.0 / 10 (持平 R105 综合分, R100 完成 12 项可代码化修复收尾)

**持平原因 (R100 → 本次)**:
- 加分: R100 P0 完成 (5 项上架阻塞可代码化部分) + P1 完成 (7 项高概率打回可代码化部分) — 12 项全闭环, 17 守门员全绿, 1997 tests pass
- 加分: 锁屏通知脱敏 (R101) — `safety_alert_builder.dart:100` 走 `l10n.safetyAlertTitle` 替代硬编码中文
- 加分: `app_database.dart` 1499 → 0 中文注释翻译 (R95 sub-spec 7 task 54)
- 加分: main.dart 8 段 i18n 化 (R95 sub-spec 7 task 53) — `_MigrationFailedApp` 走 l10n
- 加分: 13 文件 34 处硬编码中文 → ARB (R95 sub-spec 1 task 9) + zh_Hant 同步 1060 → 1091
- 持平: 5 厂商 push / 域名注册 / 5 截图 / PrivacyInfo 注册 — 4 项上架阻塞仍卡外部依赖 (法务审核 1-2 月 / Mac 不在开发机 / 阿里云 AccessKey 申请)
- 持平: R103 spzh Z1-Z9 硬编码中文仍部分残留 (R95 sub-spec 7 task 55 修了 5 个, 还剩 4 个在 mood_detail_page / medication_page)
- 持平: R104 A11/A12 P1 (iCloud Backup 排除 / Dynamic Type 适配) 仍未修

---

## 一、优点 (具体文件:行号引用)

### 1.1 中文 i18n 体系化 ✅
- **`lib/l10n/app_zh.arb` 3236 行 / `app_en.arb` 3142 行 / `app_zh_Hant.arb` 3181 行** — 3 语 100% 同步, 守门员 `scripts/check_arb_keys.py` + `check_orphan_arb_keys.py` + `check_zh_hant_consistency.py` (OpenCC s2tw) 三件套 0 violation
- **`lib/core/l10n/strings.dart`** — domain 层 fallback 集中器, 357 行覆盖通知 / 邮件 / PDF / 评估 / 关怀 / snooze / import / username fallback / scale / day detail, 走 `String? override` 模式 (v0.26 R57 决策), 后 caller 选 i18n 不破坏老 caller
- **`lib/core/data/services/safety_alert_builder.dart:100`** — 锁屏通知 title 走 `l10n.safetyAlertTitle(name, daysWithoutCheckIn)` 替代硬编码中文 (R101 R75 修复, 之前硬编码 "⚠️ 已 N 天未打卡" 全语言都是中文)
- **`lib/l10n/app_zh.arb:91-95`** — `settingsAboutVersion` 走 `kPubspecVersion.split('+').first` 动态注入 (R99 BUG-2), 不再硬编码 "v0.30.0+85"
- **18 守门员覆盖 i18n 全链路**: ARB 同步 / ARB orphan / zh_Hant 繁简 / 硬编码中文 / 全角标点 / PUA 字符

### 1.2 隐私合规架构完整 ✅
- **`assets/legal/`** — 4 份法务文档 (user_agreement / privacy_policy / sensitive_data_consent / medical_disclaimer) PIPL §13 §14 §17 §23 §28 §47 全部覆盖
- **`privacy_policy.md:6-20`** — 同意记录 3 字段 (userAgreementVersion / privacyPolicyVersion / sensitiveDataConsentAt) 写本地库, 可审计不可篡改
- **`privacy_policy.md:91-95`** — PIPL §14 撤回同意 R67 起真生效 (R67 前只更新 SharedPreferences 0 拦截业务层, spzh 视角 P0-6), 业务层真拒绝写入
- **`privacy_policy.md:32-48`** — 8 项 FeatureFlag 集中披露 (iapEnabled / emergencyContactEnabled / fiveVendorPushEnabled / emailServiceEnabled / ventAudioEnabled / phqGad7I18nEnabled / bootReceiverEnabled), UI hidden + SizeBox.shrink, 数据模型保留可瞬时恢复
- **`user_agreement.md:43-51`** — 危机热线 5 地区 (大陆 2 + 港澳台 3) 24h 全部声明, R83 律师审核集中修复
- **`scripts/check_legal_consent.py`** — PIPL §13 单独同意实施守门员, 严格豁免模式避免假阳性 (R62 收窄)

### 1.3 中文工程规范齐 ✅
- **`docs/CHINESE_COMMIT_GUIDE.md`** — commit subject 中文 + `<version> round <N>:` 前缀规范, body what+why+impact 3 段, 含 conventional commit 双轨说明
- **`docs/GIT_WORKFLOW.md`** — 单 master + round commit 节奏, 含改错指南 (amend / reset / clean) + CRLF 已知坑
- **`lib/core/data/services/notification_service.dart:1-25`** — 26 行注释详细描述 facade 拆解历史 (629 → 424 行) + 6 sub-service + 1 纯函数 builder + ID 范围公式, 维护性极佳
- **`lib/core/data/services/safety_alert_builder.dart:1-33`** — 33 行设计注释记录抽离动机 + 3 项设计原则 (0 副作用 / l10n 注入 / 0 flutter widget) + 跟 Dispatcher 职责边界

### 1.4 国产 ROM 适配 1 项落地 ✅
- **`lib/presentation/pages/settings/widgets/notification_status_card.dart`** — 自检卡显示 pendingCount + 一键测试 (R20 OEM 后台引导, 用户"20:00 没收到提醒" 99% 是 ROM 静默杀后台), 状态数 0 + OEM 引导文字
- **5 厂商 push SDK 接入** — `FeatureFlag.fiveVendorPushEnabled=false` 守门 (米/华/OPPO/vivo/魅族 1-2 月审核, 留 R95 阶段 2)
- **`notification_service.dart:313-325`** — P1-13 TODO 已注 SCHEDULE_EXACT_ALARM 运行时权限检查 (Android 12+ API 31 + 13+ 可撤销), 文档化待办

### 1.5 R100 6 视角收尾质量高 ✅
- **17 守门员全绿** (R100 P0#15 89 个临时垃圾文件清理 + 18 守门员含 check_coverage 阈值 + check_16kb_alignment Google Play 2025-11-01 强制)
- **P0 5 项全闭环**: fastlane video PLACEHOLDER 删 / iOS 后台声明删 / user_agreement "8 元" 措辞 / metadata "(失联通知规划中)" 误导表述
- **P1 7 项全闭环**: 13 文件 34 处硬编码 → 23 new ARB key × 3 语 (1068 → 1091) / iOS usage description 3 语 / SafetyCheckResult.displayMessage 编译期强制 / 3 StreamProvider autoDispose / CareEngine god class 164 → 34 行 / 9 处占位域名改描述性 / 89 个 root 垃圾清

### 1.6 R95 sub-spec 7+8 中文 i18n 收尾 ✅
- **`app_database.dart:0`** — 1499 中文 → 0 (task 54 注释翻译, 168 行 diff 纯注释)
- **`lib/main.dart:1`** — 8 段 i18n 化 (task 53) — `_MigrationFailedApp` 走 l10n
- **`app_router.dart:1`** — 嵌套 setup 路径 startsWith 守卫 (task 32), `/setup-thing` 不误匹配边界
- **5 widget 硬编码中文清理** (task 55) — `dailyTrackingNoteLabel/Hint` + `timeAgoJustNow/DaysAgo/HoursAgo` 走 l10n
- **weight_widgets** — 4+ 重复 `labelText: '备注' / hintText: '可选'` 模式 → l10n.dailyTrackingNoteLabel/Hint
- **assessment_center_card** — 硬编码相对时间 → l10n.timeAgoXxx
- **`home_page_state.dart:1`** — 主页 header 3 icon button 加 Tooltip (task 45) + 新 ARB key `homeTooltipSettings` = "设置" 3 语 sync
- **`vent_list_page.dart:1`** — vent 长按/swipe 删除 visual hint (task 48) SharedPreferences 持久化首次提示

---

## 二、问题清单 (按 P0 → P3 排序)

### 2.1 P0 上架阻塞 (5 项, 4 项卡外部依赖)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| **Z13** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 8 截图目录 | 0 张 PNG (iPhone 6.7"/6.5"/5.5"/iPad 12.9"/11") — App Store 2.1 必拒 | 资产/上架 | 中 | **P0** | macOS 跑 `flutter build ios` + 5 模拟器截 5 张 × 3 locale = 15 张 + 18 老设备 = 33 张 |
| **Z14** | `ios/Runner/PrivacyInfo.xcprivacy` | 文件存在但 `project.pbxproj` 0 引用 → xcodebuild 打包不进 .app → Apple 抽审 0 manifest 必拒 | iOS/上架 | 简单 | **P0** | Xcode → Add Files → target=Runner + Resources build phase, 或编辑 pbxproj 加 PBXFileReference + PBXBuildFile + files 列表 |
| **Z15** | `lib/core/l10n/strings.dart:103-119` `notifMedicationBody(dosage, unit, override)` | 仍硬编码 "$dosage${unit.id} · 点一下 = 打卡" 到锁屏 body (R100 P0#5 修了 title 但 body 留半成品, R105 A5 P1 重报), 锁屏仍暴露剂量 | 通知/隐私 | 简单 | **P0** | body 脱敏成 "点一下 = 打卡" (去掉 dosage 跟 unit), 详情进 app 才看; 或加 l10n 路径让 zh_Hant 锁屏也脱敏 |
| **Z16** | `assets/legal/{privacy_policy,user_agreement}.md` + `fastlane/metadata/ios/*/privacy_url.txt` 3 文件 | `chroniccare.app` 域名未注册 → Apple 5.1.1 强制 HTTPS 200, 12 个文件全不可达 | 法务/上架 | 中 | **P0** | Cloudflare Registrar $15/yr 注册 + 部署 4 HTML (privacy/support/agreement/consent) + ICP 备案 7-20d |
| **Z17** | `docs/CHANGELOG.md:107-116` R95 sub-spec 6 跳过项 | 5 厂商 push / 8 量表 i18n / IAP 8 元 productId / 主页面信息架构 / settings 4 group — 5 项 P0 上架阻塞留 R95 阶段 2, 法律审核 1-2 月 + 阿里云 AccessKey 申请 | 业务/上架 | 高 | **P0** | 注册阿里云账号申请 AccessKey + 5 厂商 push SDK 1-2 月审核 + PHQ-9/GAD-7 16 题翻译 4-6 周法务临床审核 |

### 2.2 P1 高概率打回 / 用户可见 (12 项, 5 项可代码化 + 7 项外部依赖)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| **Z18** | `lib/core/l10n/strings.dart:42-50` `emailMedInfo(name, dosage, unit)` + `pdfMedicationStatsValue` 等 PDF 文案 | PDF 报告 + 邮件导出含药名 + 剂量明文, 用户导出后给医生 (合规), 但**用户自己用** — 心理患者可能截图给家属导致隐私扩散, 无明文风险提示 | PDF/隐私 | 简单 | **P1** | PDF 标题加 "本报告含敏感健康信息, 请妥善保管" disclaimer, 跟 export_risk 模式一致 |
| **Z19** | `lib/presentation/widgets/animations/page_transition_switcher.dart:39` | 默认 `duration = AppTokens.durPageTransition` (100ms) — emil 框架 occasional 频度应 ≥ 200ms, 100ms 用户感知不到"切换" | 动效/UI | 简单 | **P1** | 提到 durNormal (300ms), setup 4 步切换已用 300ms 覆盖 |
| **Z20** | `lib/presentation/pages/home/widgets/today_summary_card.dart:130-141` | `_SummaryItem` AnimatedSwitcher 默认 fade 切换 — 数值变化无 spring 物理 / 数字 tween 递增 (R105 P2-5) | 动效/UI | 中 | **P1** | 数字走 TweenAnimationBuilder 0→target, 复用 CheckInButton._StreakCounter 模式 |
| **Z21** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:101-105` | 错误 SnackBar 硬编码中文 "记录失败, 请重试" — 跟 R95 mock/dev 字符串同款, 漏 AppSnackBar 集中器 | UI/i18n | 简单 | **P1** | 走 AppSnackBar.showError + 新 ARB key `moodRecordFailed` 3 语 |
| **Z22** | `lib/presentation/pages/daily_tracking/widgets/{weight,sleep,anxiety_agitation,social_rhythm,stress_event}_widgets.dart:198/266/151/197/179` | 5 widget `SnackBar(content: Text(...))` 裸 ScaffoldMessenger — R95 sub-spec 8 新引入漏统一 | UI/UX | 简单 | **P1** | 走 AppSnackBar 集中器 + l10n.moodRecordFailed 等复用 |
| **Z23** | `lib/core/l10n/strings.dart:0-22` 类注释 | 4 项 v0.23 R39 P1-9 + v0.27 R63 P1-8 + v0.26 R57 + v0.31 P1-5 注释叠加, 4 处 v* 决策记录堆叠, 阅读体验差 | 文档/规范 | 简单 | **P1** | 用 commit hash 索引替代 v* 注释 (跟 WHITEPAPER §18 决策记录风格一致), 1-2 行 `// see R57 (commit xxx), R63 (yyy)` |
| **Z24** | `lib/presentation/pages/settings/widgets/notification_status_card.dart:216-222` | `AnimatedSize` 用 `Motion.duration(context, AppTokens.durNormal)` 但 `curve: AppTokens.curveStandard` 直接走 token, 未走 `Motion.curve(context, ...)` — reduce-motion 用户下 duration=0 但 curve=easeOutCubic 仍是 acceleration curve | a11y | 简单 | **P1** | 改 `Motion.curve(context, AppTokens.curveStandard)` 包装 (R103 P0-7 决策 non-negotiable) |
| **Z25** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:160-198` | 4 档情绪 emoji + label 整 PressFeedback 缺 Semantics label — 4 emoji button 无 label, TalkBack 朗读 "☀️" 或 raw char 不可懂 (精神心理患者视觉障碍比例高于平均) | a11y | 简单 | **P1** | 加 `AppSemantics.button(label: l10n.moodScoreNLabel(score))` 包装 4 emoji |
| **Z26** | `lib/core/theme/app_tokens.dart:46-314` | AppTokens facade 314 行静态 const 转发, 仍依赖 4 个子模块 (AppColors / AppMotion / AppSpacing / AppTypography) — R105 P2-3 已报 | 规范/底层 | 中 | **P1** | 加 `@Deprecated('use AppColors.primary')` 提示, R100+ 删 facade 彻底 |
| **Z27** | `lib/l10n/app_zh.arb` 全文件 | 8 量表 PHQ-9 / GAD-7 16 题 + 严重度 + 危机电话仅 hotline 6 region 走 hot path, 题干 i18n 不完整 (R95 sub-spec 6 跳过 task 58) — 法律责任 | i18n/法务 | 高 | **P1** | 16 题 × 3 语 = 48 翻译 + 4-6 周法务临床审核 (留 R95 阶段 2) |
| **Z28** | `lib/presentation/pages/medication/medication_page.dart:161-162` + `medication_calendar_page.dart:212-213` | `loading: () => const Center(child: CircularProgressIndicator())` + `error: (e, _) => Center(child: Text('$e'))` 走裸 — 12+ 处散落未走 LoadingSkeleton/ErrorState/AppSnackBar 集中器 | 底层/UI | 简单 | **P1** | 走 LoadingSkeleton.fullScreen + ErrorState + AppSnackBar 集中器 (R31 模式) |
| **Z29** | `lib/core/theme/app_spacing.dart:132-153` | `breakpointMedium = 840` + `breakpointExpanded = 840` 边界相同, `windowSizeOf(width)` 在 width=840 时直接返 expanded, `WindowSize.medium` 实际不可达 — R104 E6 0 调用方走 medium 分支, 引入 dead enum case | 底层 | 简单 | **P1** | 调 breakpointMedium=600, 跟 Material 3 spec 一致 |

### 2.3 P2 中度 / 架构 (8 项)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| **Z30** | `lib/domain/logic/influence_category.dart:36-71` | 36 个中文影响因素 (情绪 / 饮食 / 运动 等) hardcoded — R95 sub-spec 6 跳过 | domain/i18n | 中 | **P2** | 走 enum + l10n.influenceCategoryXxx, 1 文件 36 翻译 × 3 语 |
| **Z31** | `lib/domain/logic/care_copy.dart:33-57` | 全部关怀文案硬编码中文 — R31 P1-5 修了 strings.dart 但 care_copy.dart 仍直接 hardcoded | domain/i18n | 中 | **P2** | 走 Strings.careCopyXxx (现有 8 函数复用) |
| **Z32** | `lib/domain/logic/assessment_comparison.dart:68-79` | 趋势标签硬编码中文 (好转/恶化/持平) — R31 P1-5 修了 strings.dart 但 assessment_comparison.dart 仍直接 | domain/i18n | 简单 | **P2** | 走 Strings.assessmentComparisonXxx (现有 7 函数复用) |
| **Z33** | `lib/presentation/widgets/medication_pill_icon.dart:9-16, 63, 70` | 6 个 iOS 系统色硬编码 (`#34C759/#FFCC00/#FF3B30/#007AFF/#AF52DE/#8E8E93`) + `Colors.white` 2 处 — R101 新引入, 跟 R22 round 30 emil P2-6 "Colors.white 18 处" 同款 bug | UI/规范 | 简单 | **P2** | 6 色进 AppColors (或 AppleHealthColors 子集), 改一处生效 |
| **Z34** | `lib/presentation/pages/home/home_page_state.dart:327-431` | 主页 8 层 stagger FadeIn 累加 0-280ms — emil "home 入场无动画" (100+/day 频度, R18 P1-8), 精神心理患者前庭敏感 | 动效/UX | 中 | **P2** | stagger 限 3 项 (header + today_summary + hero), 后续 carousel/primary/secondary 改无动画 |
| **Z35** | `lib/core/data/services/notification_service.dart:326-335` `rescheduleAll` 注释 P1-13 TODO | SCHEDULE_EXACT_ALARM 运行时权限检查 (Android 12+ API 31 + 13+ 可撤销), 用户撤回 → zonedSchedule 静默降级 inexact 延迟 ~15min | Android/通知 | 中 | **P2** | 入口调 `canScheduleExactAlarms()`, false 时引导系统设置 |
| **Z36** | `lib/core/data/services/notification_service.dart:263-272` `pendingCount` | web 平台 / 未实现 plugin 抛 PlatformException → swallowError 返 -1, 但 UI 仍显示数字 -1 不友好 | UI/UX | 简单 | **P2** | UI 改 "—" 占位 或 "不支持" 文案 |
| **Z37** | `lib/presentation/pages/mood_list/mood_detail_page.dart:219, 256` | "录音" / "删除" 按钮 — R103 spzh Z1/Z2 P0 标 2 轮未修, 仍硬编码 | UI/i18n | 简单 | **P2** | 走 l10n.audioRecord / l10n.delete 复用现有 key |

### 2.4 P3 文档 / 规范 (5 项)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| **Z38** | `docs/CHANGELOG.md:0` 全文 | R95 sub-spec 8 (10 commit) + R100 (12 项收尾) + R101 (mood reminder + user_agreement "8 元") 3 段已写, 但 R102-R105 review 报告 (emil E1-E30 + spen + spzh Z1-Z37 + 5 厂商 push 待办 + iOS Dynamic Type) 未进 changelog | 文档 | 简单 | **P3** | R105 entry 加 R102-R105 review 报告链接 (docs/audit-archive-2026-08-10/2026-08-09/7-perspective-audit-report.md) |
| **Z39** | `lib/core/data/services/notification_service.dart:280-299` `scheduleDailyReminder` 注释 | 缺少 v0.16 round 19 ID 范围公式注释 (notification_service 主类注释 line 14-16 有, 但 method 自身无), 维护者改 ID 容易超范围 | 文档/规范 | 简单 | **P3** | method 注释加 `// id=1001, cancel 范围覆盖 200000+ (v0.16 round 19 修)` |
| **Z40** | `docs/audit-archive-2026-08-10/2026-08-10/03-superpowers-zh.md` (本目录) | R95 6 视角 → R100 6 视角 → R101 6 视角 → R103 → R105 → 本次 6 轮 spzh 报告已 6 份, 但没有 master 综合 spzh 报告 (跨所有 round 趋势) | 文档 | 简单 | **P3** | 写 `docs/spzh-trend-report.md` 跨 R95-R105 spzh 评分 + Z 编号 + 修复率 |
| **Z41** | `lib/presentation/widgets/loading_skeleton.dart:255-267` | Shimmer 实际是 Opacity 脉动 (0.4-0.7), 不是真正骨架屏 — R105 P2-4 已报可保留 | UI/UX | 中 | **P3** | 注释加 "设计选择: 精神心理 App 高刺激度防御, 脉动优于 shimmer" |
| **Z42** | `assets/legal/{user_agreement,privacy_policy}.md` R95/R96/R100 修订历史 | 修订历史表 6 entry (R67/R69/R83/R93/R96/R101), 但 2026-08-08 R100 P0#4 "8 元" 措辞修订未入修订历史 | 文档 | 简单 | **P3** | 加 R100 entry "P0#4 措辞对齐, 草稿标注规范化" |

---

## 三、工程 + 合规双角度评估

### 3.1 工程 (持平 R105 9.0/10)

| 维度 | 评分 | 关键发现 |
|------|------|----------|
| 中文 i18n 覆盖 | 9.5/10 | 3 语 100% 同步 (zh 3236 / en 3142 / zh_Hant 3181 行) + 18 守门员覆盖 ARB / orphan / 繁简 / 硬编码 / 全角 / PUA |
| 注释中文规范 | 9.0/10 | strings.dart 决策注释堆叠 (Z23), 主类注释详细 (notification_service 26 行 + safety_alert_builder 33 行), 维护性优 |
| 提交规范 | 8.5/10 | CHINESE_COMMIT_GUIDE.md 完整, 实际 commit 80% 英文 / 20% 中文 (项目自承认偏实用), 守门员无 |
| 中文文档 | 9.0/10 | CHANGELOG 详细 (含 sub-spec 1-8 各自 commit 清单), 法务 4 份齐 + 修订历史表, R102-R105 review 报告 4 份独立 |
| Git 工作流 | 8.5/10 | 单 master + round commit 节奏 + 改错指南, 缺 PR/branch/CODEOWNERS (单 dev 不需要, 但 R95 跳过) |
| 国产 ROM 适配 | 7.5/10 | NotificationStatusCard 自检卡落地 ✅, 5 厂商 push FeatureFlag 守门但 0 接入 (1-2 月审核), SCHEDULE_EXACT_ALARM 权限 TODO |
| 隐私合规 | 8.0/10 | PIPL §13/§14/§17/§23/§28/§47 全覆盖, 4 法务 md + 3 同意字段写库可审计, 缺域名/邮箱/截图仍上架阻塞 |
| 中文 UI 字体 / 排版 | 7.0/10 | 275 处 fontSize 硬编码, 0 Dynamic Type 适配 (R104 A12 P1), fontFamily fallback 未审 |
| 拼音 / 简码 | 9.0/10 | user_name_helper "用户" fallback + trim(), phone_validator 已审 |
| 集成度 | 9.5/10 | 1997 tests pass, 18 守门员全绿, 0 analyzer error, 5 集成测试 (check-in/streak/contacts/assessment/export/vent) |

### 3.2 合规 (持平 R105 4.5/10)

| 维度 | 评分 | 关键发现 |
|------|------|----------|
| PIPL §13 单独同意 | 9.0/10 | 4 同意 (用户协议 / 隐私政策 / 敏感个人信息 / 医疗免责声明) 3 步勾选 + 时刻 + 版本号写库, check_legal_consent.py 守门 |
| PIPL §14 撤回 | 9.0/10 | R67 真生效 (业务层真拒绝写入, 不仅是 SharedPreferences), R95 sub-spec 7 task 31b 加 audit log withdraw + clearDataExportAuditLog 显式入口 |
| PIPL §17 上架 | 4.0/10 | export_risk_title/body/liability/acknowledge 4 段明示, 但 chroniccare.app 域名未注册, 12 个文件 URL 不可达 (Z16 P0) |
| PIPL §23 第三方 | 8.5/10 | 紧急联系人预存储 + 失联通知业务整体暂停 (FeatureFlag.emergencyContactEnabled=false), 不实际触发, 法律对齐清晰 |
| PIPL §28 健康医疗 | 8.0/10 | AES-256 加密本地库 + 录音 + 树洞, 密钥 SecureStorage 设备绑定, R95 task 31a 加密 audit log 防设备 root |
| PIPL §47 撤回 | 8.5/10 | reset(ConsentKind.dataExport) 自动清 audit log, clearDataExportAuditLog 显式入口 (R95 sub-spec 7 task 31b) |
| 数据本地化 | 10/10 | 0 云端 / 0 analytics / 0 第三方 SDK, 仅本地 SQLCipher AES-256 + FlutterSecureStorage |
| 锁定 iCloud Backup | 3.0/10 | iOS native.dart:18 + encrypted_audio_storage.dart:99-104 0 `setAttributesItem(.isExcludedFromBackup = true)`, 精神心理敏感数据上 iCloud (R104 A11 P1, 未修) |
| 锁定 SensitiveInfo | 3.0/10 | `PrivacyInfo.xcprivacy` 缺 `NSPrivacyCollectedDataTypeSensitiveInfo` (PHQ-9/GAD-7 = 敏感健康), 5 类必填类型完整但漏 1 类 (R105 5.3 报) |
| App Store / GPlay 上架 | 4.0/10 | 12 P0 上架阻塞 4 外部依赖 (域名/截图/keystore/真机测试) + 1 致命 (PrivacyInfo.xcprivacy 未注册) |

---

## 四、国际化质量

### 4.1 ARB 覆盖率

| 语言 | 行数 | 守门员 | 评估 |
|------|------|--------|------|
| **zh (app_zh.arb)** | 3236 | source of truth | 全部中文文案源, 跟 strings.dart 一致, settingsAboutVersion 动态注入 (R99 BUG-2) |
| **en (app_en.arb)** | 3142 | check_arb_keys 双向 | 完整英文翻译, 差异 94 行因 zh 多注释 metadata |
| **zh_Hant (app_zh_Hant.arb)** | 3181 | check_zh_hant_consistency (OpenCC s2tw) | 100% 繁简一致, 跟 zh 同步, 35 行差异因 OpenCC 繁化注释 + 量表专有译法 |

### 4.2 翻译质量

- **专有译法**: PHQ-9 / GAD-7 16 题题干 i18n 不完整 (R95 sub-spec 6 task 58 跳过), 仅 hotline 6 地区走 hot path, 题干 fallback 走 strings.dart 中文
- **通知文案**: 锁屏通知走 l10n 路径 (R101 R75 修复 title + body 3 态), 但 `notifMedicationBody` 仍暴露 dosage+unit (Z15 P0)
- **危机热线**: 6 地区 (大陆 2 + 港澳台 3) 走 user_agreement.md 文档 + crisis_hotline_page 路由, 3 语 OK, 但 zh_Hant 港澳台 3 地区 0 验证显示
- **繁简一致性**: 守门员 OpenCC s2tw 100%, R95 sub-spec 8 fixup 修过 `homeTooltipSettings` 改 `設置` 跟 OpenCC 同步
- **全角标点**: 守门员 warn-only (5 处历史 pre-existing), 新代码应走全角 (,。;；!？:： / ／ (（）) — R95 task 9 加 23 new ARB key 都已用全角

### 4.3 i18n 集成度

- **strings.dart (domain fallback)**: 357 行覆盖 8 大类 (通知 / 邮件 / PDF / 评估 / 关怀 / snooze / import / username), 走 `String? override` 模式, 新 caller 选 i18n 不破坏老 caller
- **AppLocalizations (flutter_localizations)**: 1091 key × 3 语, 覆盖 presentation 层全部 UI
- **缺失**: domain 8 量表题干 / 36 influence category / care_copy 5 关怀文案 / assessment_comparison 7 趋势标签 — 4 类 domain 层硬编码中文待迁 (Z30-Z32 P2)

---

## 五、中文 UI 排版 / 字体 / 标点

### 5.1 字体 / 排版

- **fontFamily fallback**: 0 处显式声明, 走 Material 3 默认 (Roboto + Noto Sans CJK SC), 中英文 fallback 平台默认 OK
- **行高 / letter-spacing**: 0 处显式声明, 走 Material 3 默认 (1.2-1.5 倍行高, 中文 1.5-1.7 倍推荐)
- **段落间距**: 走 `AppTokens.spacingXs/Sm/Md/Lg/Xl` 集中器, 18 守门员全绿, 0 magic
- **275 处 fontSize 硬编码** — R104 A12 P1, 精神心理 App 用户大字模式需求 (抑郁/双相低视力常见), 0 MediaQuery.textScalerOf(context) 调用, 0 textScaler 适配 — **P1 严重** (Z23)

### 5.2 标点

- **全角标点守门员**: check_fullwidth_punctuation.py 9 种 (,;!?/():… + U+2026), 扫描 .dart + .arb, 5 处历史 pre-existing warn-only
- **emoji + 中文混排**: 16 emoji × 中文文案 (🌱 💊 🛏️ ☀️ 🌿 🌟 等), emoji 跟中文之间无空格 (中文排版习惯), 但部分 emoji 字号硬编码 (hero_illustration.dart:67-114 4 emoji 36/28/56/32)

### 5.3 截断策略

- **中文长字符串**: 0 处 ellipsis 显式声明, 走 Material Text 默认 truncate, 中文断字点在字符边界 (无英文 hyphen 断字问题)
- **38 处 `maxLines:` 硬编码**: 走 token (maxLines1/2/3) 集中器, R95 sub-spec 5 task 3 已统一
- **276 处 `overflow: TextOverflow.ellipsis`**: 走 token (textOverflowEllipsis) 集中器

### 5.4 数字 / 时间 / 日期 / 货币

- **数字格式**: zh locale 用 `intl.DateFormat.yMd()` + `NumberFormat.decimalPattern()`, R56d formatters 走 intl (替换之前手写)
- **时间格式**: 24h 制, zh_Hant 同步, 0 12h 残留
- **日期格式**: yyyy-MM-dd (zh_Hant 一致, OpenCC 不改数字)
- **货币**: 无货币 (本 App 不收费, IAP 暂停), 占位 R93 决策 8 元描述删
- **计量单位**: 药剂量 mg/g/mL/IU 在 DosageUnit.id 集中, zh-Hant "毫克/克/毫升/国际单位" 同步

---

## 六、国产 ROM 适配现状 + 5 厂商 push 待办

### 6.1 已落地 ✅

- **NotificationStatusCard** (`lib/presentation/pages/settings/widgets/notification_status_card.dart:0`) — R20 OEM 后台引导, 自检卡显示 pendingCount + 一键测试
- **OEM 引导文字** — 主页 + 设置页提示用户去 ROM 自启动 / 后台运行 / 精确闹钟设置
- **`androidScheduleMode: exactAllowWhileIdle`** — R20 必要条件, 充分条件靠用户自检
- **BootReceiver** — R70 简化方案, 启动时调 `rescheduleAll`, 走 `bootReceiverEnabled` flag 守门

### 6.2 待办 (外部依赖, 1-2 月审核)

| 厂商 | SDK | 审核时长 | 阻塞原因 |
|------|-----|----------|----------|
| 小米 (MIUI) | MiPush | 1-2 月 | 厂商开发者账号 + 应用审核 + 推送权限 |
| 华为 (EMUI) | HMS Push | 1-2 月 | 华为开发者联盟 + 签名 + 隐私声明 |
| OPPO (ColorOS) | OPush | 1-2 月 | OPPO 开放平台 + 推送资质 |
| vivo (FuntouchOS) | VPush | 1-2 月 | vivo 开发者 + 推送服务申请 |
| 魅族 (Flyme) | FlymePush | 1-2 月 | 魅族开放平台 + 推送接入 |

**FeatureFlag 守门**: `lib/core/data/feature_flags.dart:FeatureFlag.fiveVendorPushEnabled=false`, 业务代码保留, 翻 flag 立即恢复

**P1-13 TODO**: SCHEDULE_EXACT_ALARM 运行时权限检查 (Android 12+ API 31 + 13+ 可撤销), 文档化待办 (notification_service.dart:313-325)

### 6.3 BGTaskScheduler iOS handler (R95 跳过)

- **R95 sub-spec 8 task 58 跳过**: iOS BGTaskScheduler handler 0 注册 (pubspec 未引 workmanager / background_fetch), 5 厂商 push 0 接入
- **影响**: iOS 后台拉活受限, 用户长期不开 App 时失联通知 / 续方提醒可能延迟
- **修复**: 接 5 厂商 push 后一并加 `setTaskCompleted(success: true)` 占位

---

## 七、隐私合规 / 法律文档质量

### 7.1 4 份法务 md 评估

| 文件 | 评分 | 评估 |
|------|------|------|
| `privacy_policy.md` | 9.0/10 | PIPL §13/§14/§17/§23/§28/§47 覆盖完整, 同意记录 3 字段, 8 FeatureFlag 集中披露, R67 真撤回 + R95 task 31b audit log withdraw, 缺域名/邮箱/截图 |
| `user_agreement.md` | 8.5/10 | 危机热线 6 地区齐 (大陆 2 + 港澳台 3), 8 元买断 R100 改"未来版本", 修订历史表 6 entry 完整, R95/R96 草稿标注规范化 |
| `sensitive_data_consent.md` | 8.0/10 | 单独同意链, AES-256 加密声明, 撤回路径, 缺域名/邮箱 |
| `medical_disclaimer.md` | 8.5/10 | R101 R83 律师审核, 危机热线 6 地区, 9 disclaimer 段, 5 字体类排版 (H1/H2/H3) |

### 7.2 PIPL 合规

- **§13 单独同意**: ✅ 4 同意 (用户协议 / 隐私政策 / 敏感个人信息 / 医疗免责声明) 3 步勾选 + 时刻 + 版本号写库, check_legal_consent.py 守门
- **§14 撤回**: ✅ R67 真生效 (业务层真拒绝写入), R95 sub-spec 7 task 31b 加 audit log withdraw + clearDataExportAuditLog 显式入口
- **§17 上架**: ⚠️ export_risk_title/body/liability/acknowledge 4 段明示, 但域名未注册 (Z16 P0)
- **§23 第三方**: ✅ 紧急联系人预存储 + 失联通知整体暂停 (FeatureFlag.emergencyContactEnabled=false), 不实际触发
- **§28 健康医疗**: ✅ AES-256 加密本地库 + 录音 + 树洞, 密钥 SecureStorage 设备绑定, R95 task 31a 加密 audit log
- **§47 撤回**: ✅ reset(ConsentKind.dataExport) 自动清 audit log

### 7.3 法律风险

- **Z16 P0**: chroniccare.app 域名未注册, 12 个文件 URL 不可达, Apple 5.1.1 强制 HTTPS 200
- **Z18 P1**: PDF 报告 + 邮件导出含药名+剂量明文, 心理患者可能截图给家属导致隐私扩散, 无明文风险提示
- **Z15 P0**: 锁屏通知 body 仍暴露 dosage+unit (R100 P0#5 修了 title 但 body 留半成品, R105 A5 P1 重报)
- **Z40 P3**: R102-R105 review 报告未进 changelog, 法律审计追溯链断

### 7.4 集成度

- **check_legal_consent.py** 守门: 0 violation
- **check_arb_keys.py / check_orphan_arb_keys.py / check_zh_hant_consistency.py** 守门: 0 violation
- **3 同意字段写库**: `userAgreementVersion` / `privacyPolicyVersion` / `sensitiveDataConsentAt` 全部可审计不可篡改
- **R67 真撤回**: 业务层真拒绝写入 (不是仅 SharedPreferences), 9 lock-in tests 覆盖

---

## 八、文档质量 (CHANGELOG / README / AGENTS / DEPLOYMENT / 5 法务 md)

### 8.1 7 份核心文档

| 文件 | 行数 | 评分 | 评估 |
|------|------|------|------|
| `docs/CHANGELOG.md` | 200+ | 9.0/10 | R95 sub-spec 1-8 + R100 + R101 详细 commit 清单, R102-R105 review 报告未进 changelog (Z38 P3) |
| `README.md` | 待审 | 8.0/10 | 产品视角, 缺 R100-R105 上架就绪度章节 |
| `AGENTS.md` | 279 | 9.5/10 | 17 守门员清单 + 4 层架构 + 已知坑 18 项, 维护极佳 |
| `docs/CHINESE_COMMIT_GUIDE.md` | 103 | 9.0/10 | subject 中文 + `<version> round <N>:` 前缀 + 实际 80% 英文偏实用说明 |
| `docs/GIT_WORKFLOW.md` | 108 | 8.5/10 | 单 master + round commit + 改错指南, 缺 PR/branch/CODEOWNERS |
| `docs/DEPLOYMENT.md` | 待审 | 7.5/10 | 缺 iOS 5 截图 / Android keystore 生成 / 5 国内 store (华为/小米/OPPO/vivo/魅族) |
| `docs/VERSION_1.0_PLAN.md` | 待审 | 8.0/10 | R95 阶段 1-4 完整, R96+ 待续 |

### 8.2 5 份法务 md 修订历史

| 文件 | 修订历史 | 评估 |
|------|----------|------|
| `privacy_policy.md` | 5 entry (v0.24 / R67 / R69 / R83 / R93 / R96) | 完整 |
| `user_agreement.md` | 6 entry (v0.24 / R67 / R69 / R83 / R93 / R96 / R101) | 完整 |
| `sensitive_data_consent.md` | 待审 | 待审 |
| `medical_disclaimer.md` | 待审 | 待审 |
| `docs/LEGAL_REVIEW_BRIEF.md` | 待审 | 待审 |

### 8.3 R102-R105 review 报告归档

- **R103 (2026-08-08)**: emil 8 项 + spen + spzh 12 项 + 4 视角, 路径 `docs/audit-archive-2026-08-10/2026-08-08/R103-7perspective-audit/`
- **R105 (2026-08-09)**: emil E1-E30 + spen P1-1~P2-18 + spzh Z1-Z37 + 4 视角, 路径 `docs/audit-archive-2026-08-10/2026-08-09/`
- **2026-08-10 4 视角**: emil 9.0 + appstore 5.8 + googleplay + apple-health, 路径 `docs/audit-archive-2026-08-10/2026-08-10/` (本目录是 cleanup pass)
- **6 轮 spzh 报告**: R95 / R100 / R101 / R103 / R105 / 本次 — **缺 master 综合 spzh 趋势报告** (Z40 P3)

---

## 九、问题清单总览 (按优先级排序)

### P0 上架阻塞 (5 项, 1 项可代码化 + 4 项外部依赖)

- **Z13** 8 截图目录 0 PNG (中, 1-2d)
- **Z14** PrivacyInfo.xcprivacy 未注册 pbxproj (简单, 30min)
- **Z15** 锁屏通知 body 仍暴露 dosage+unit (简单, R100 P0#5 半成品)
- **Z16** chroniccare.app 域名未注册 (中, 1-2d + ICP 7-20d)
- **Z17** 5 厂商 push / 8 量表 i18n / IAP 8 元 / 主页面信息架构 / settings 4 group (高, 法务 1-2 月)

### P1 高概率打回 / 用户可见 (12 项)

- **Z18** PDF 报告 + 邮件导出含药名+剂量明文, 无 disclaimer
- **Z19** PageTransitionSwitcher 默认 100ms 偏短
- **Z20** TodaySummaryCard 数值变化无 spring 物理
- **Z21** quick_mood_carousel 错误 SnackBar 硬编码中文
- **Z22** 5 daily_tracking widget 裸 SnackBar
- **Z23** strings.dart 4 处 v* 决策注释堆叠
- **Z24** notification_status_card Motion.curve 包装漏
- **Z25** quick_mood_carousel 4 emoji 缺 Semantics label
- **Z26** AppTokens facade 314 行转发待删
- **Z27** 8 量表 PHQ-9/GAD-7 16 题 i18n 不完整
- **Z28** medication_page 12+ 处 loading/error 走裸
- **Z29** breakpointMedium = breakpointExpanded dead enum case

### P2 中度 / 架构 (8 项)

- **Z30** influence_category 36 中文
- **Z31** care_copy 关怀文案
- **Z32** assessment_comparison 趋势标签
- **Z33** medication_pill_icon 6 iOS 系统色硬编码
- **Z34** 主页 8 层 stagger FadeIn 过密
- **Z35** SCHEDULE_EXACT_ALARM 运行时权限检查
- **Z36** pendingCount web -1 显示不友好
- **Z37** mood_detail_page "录音" / "删除" 硬编码

### P3 文档 / 规范 (5 项)

- **Z38** R102-R105 review 报告未进 changelog
- **Z39** notification_service method 注释缺 ID 范围公式
- **Z40** 缺 master 综合 spzh 趋势报告
- **Z41** loading_skeleton 注释加设计选择说明
- **Z42** R100 P0#4 "8 元" 措辞修订未入修订历史

---

## 十、结论与建议

### 10.1 持平 R105 评分 (7.0/10 综合)

- **工程持平 R105 9.0/10**: 18 守门员 + 1997 tests + 0 analyzer error 维持, R100 P0+P1 12 项收尾, strings.dart / safety_alert_builder / app_database / main.dart 4 文件 i18n 化
- **合规持平 R105 4.5/10**: 4 外部依赖上架阻塞 (域名/截图/keystore/真机) + 1 致命 (PrivacyInfo.xcprivacy 未注册) + 1 锁屏脱敏半成品 (Z15)
- **持平原因**: R100 已完成可代码化收尾, 剩余 P0 4 项 + P1 7 项全卡外部依赖 (法务审核 / 域名 / 厂商 push / 阿里云 AccessKey / Mac 测试机)

### 10.2 下一步 (按 ROI 排序)

1. **Z14 (P0, 30min)**: 修 PrivacyInfo.xcprivacy pbxproj 注册 — 致命上架阻塞, 1 行 pbxproj
2. **Z15 (P0, 简单)**: 锁屏通知 body 脱敏成 "点一下 = 打卡" — 隐私合规, 5 行代码
3. **Z38 (P3, 简单)**: R102-R105 review 报告进 changelog — 法律追溯链, 30min
4. **Z21+Z22 (P1, 简单)**: 5+1 SnackBar 走 AppSnackBar 集中器 — UX 一致性, 1-2h
5. **Z23 (P1, 简单)**: strings.dart 4 处 v* 注释改 commit hash 索引 — 维护性, 1h
6. **Z24-Z25 (P1, 简单)**: Motion.curve + Semantics label — a11y, 2-3h
7. **Z30-Z32 (P2, 中)**: 3 domain 文件 i18n 化 — 复用现有 Strings 函数, 半天
8. **Z40 (P3, 简单)**: 写 master spzh 趋势报告 — 跨 round 趋势, 1h

### 10.3 长期 (外部依赖)

- **Z13 Z16 Z17 (P0, 1-2 月)**: 域名注册 + 5 截图 + 5 厂商 push + 8 量表翻译 + IAP 真接 — 4 周
- **PHQ-9/GAD-7 16 题 i18n** (Z27 P1, 4-6 周法务临床审核)
- **iOS Dynamic Type 适配** (R104 A12 P1, 275 处 fontSize 改 Theme.textTheme)
- **iCloud Backup 排除** (R104 A11 P1, MethodChannel + Swift helper)
- **5 厂商 push SDK 接入** (1-2 月审核)

### 10.4 工程亮点 (跟 top 5% Flutter 项目比肩)

- 18 守门员 + 1997 tests + 0 analyzer error 维护纪律
- 3 语 i18n + OpenCC s2tw 繁简自动校验
- 4 层架构 + 共享 umbrella + 5 layer + drift SQLCipher
- 4 法务 md + PIPL §13/§14/§17/§23/§28/§47 全覆盖
- 8 FeatureFlag 集中披露 + 业务真撤回 R67
- 5 集成测试 + 6 轮 7 视角 review 闭环

---

**审计完成时间**: 2026-08-10
**审计员**: superpowers-zh 视角 (4 中国特色 skill + 工程实践)
**审计范围**: lib/ (395 dart) + docs/ (100+ md) + scripts/ (18 守门员) + assets/legal/ (4 md) + fastlane/ + ios/ + android/
**对比基线**: R103 (9.0) → R105 (9.0) → 本次 (9.0 持平, 4 P0 上架阻塞仍卡外部依赖)
