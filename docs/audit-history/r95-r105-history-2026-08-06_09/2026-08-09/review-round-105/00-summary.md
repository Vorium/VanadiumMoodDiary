# R105 7 视角综合审计报告 (2026-08-09, round 105)

**版本**: v0.30.0+85 (schemaVersion 21)
**基线**: R104 (2026-08-09) + R103 (2026-08-08)
**审查对象**: **当前未提交工作区** — R101+ medication 重构 / mood 详情与趋势 / daily_tracking 自定义 / 8 新量表 / 上架物料批次 (含 uncommitted 修改)
**验证手段**: 7 agent 并行 + 人工复核关键项 (`flutter analyze` / `check_all.dart` / `check_cross_feature.py` / `check_orphan_arb_keys.py` / `check_zh_hant_consistency.py` / git diff)

**基线结果**:
- `flutter analyze`: **0 issue** ✅
- `check_all.dart` (架构纯度 + 一致性): **2/2 全绿** ✅ (R104 的 tracking_item_config 违规已修)
- `check_cross_feature.py`: 131 文件 **0 violation** ✅
- `check_arb_keys.py` (3 语同步): **全绿** ✅ (1265 key)
- `check_orphan_arb_keys.py`: **FAIL — 42 个孤儿 key** 🔴 (全为本批新增)
- `check_zh_hant_consistency.py`: **FAIL — 16 处繁简不一致** 🔴 (全为本批新增)
- schema 迁移: medications +3 列 (v19→v20), mood_entries +1 列 (v20→v21), onUpgrade 齐全 ✅

---

## 一、外部链接隐藏检查 (需求 1)

### 1.1 运行时代码 ✅ 全部隐藏

| 检查项 | 状态 | 详情 |
|--------|------|------|
| HTTP/HTTPS URL | ✅ | 仅注释中 4 处 (sms_service 3 + chinese_holidays 1), 0 运行时调用 |
| 外部 API 端点 | ✅ | AliyunSmsProvider.send() / EmailService.send() / 5 厂商 push 全早返 false |
| Firebase / Sentry / Analytics | ✅ | 0 依赖, pubspec 无任何 analytics 包 |
| IAP 购买 UI | ✅ | `iapEnabled=false`, profile_group Pro 卡 `if (FeatureFlags.iapEnabled)`, buyLifetime 早返 false, main warmup 跳过 → release 无购买 UI |
| `kDebugMode` 门控 | ✅ | 所有 debug 行为均被门控 |
| `tel:` 危机热线 | ✅ | 唯一 url_launcher 用法, scheme 合法 |
| PrivacyInfo.xcprivacy | ✅ | 5 类 required-reason API 齐全, 声明 HealthAndFitness |
| 后台声明 | ✅ | UIBackgroundModes / aps-environment 已删, 无假声明 |

### 1.2 ⚠️ 新矛盾 — 录音功能半开半关 (上架物料层不一致)

`feature_flags.dart:70` 将 `_prodVentAudioEnabled` 改为 `true` (启用语音录制), 但**同一批次**删除了录音权限声明 → **录音既无法工作也破坏上架一致性**。详见二、P0 清单。

### 1.3 用户可见字符串

- `safetyCheckResultAlertedMocked` mock/dev 字符串仍在 3 语 ARB (release 不可达, 低风险, P2)
- 无其他 mock/dev 残留

---

## 二、上架 / 架构 / 重构 / 半成品问题 (需求 2 + 修复优先级矩阵)

### 🔴 P0 — 提交前必须处理 (8 项)

| # | 问题 | 架构/底层 | 难度 | 来源 | 文件:行 |
|---|------|-----------|------|------|---------|
| 1 | **录音功能自相矛盾**: flag=true 但 iOS 权限描述已删 (NSMicrophone/NSSpeechRecognition 3 语) + Android `tools:node="remove"` 删 RECORD_AUDIO → iOS 录音 crash + Android SecurityException + Apple 2.5.1 拒 | 底层/权限 | 简单 | AppStore A1/A2 | feature_flags.dart:70 vs Info.plist / AndroidManifest.xml:51 |
| 2 | **3 个 test 仍断言 ventAudio 默认 false** → `flutter test` 必红 (CI regression) | 底层/CI | 简单 | AppStore A3 | feature_flags_round93_test.dart:61 / vent_compose_page_r93_hide_test.dart:21 / mood_recorder_page_r93_hide_test.dart:82 |
| 3 | **mood_detail 整页 Column 不可滚动** → CBT 字段多时 RenderFlex overflow, release 内容被裁 | 底层/UI | 简单 | emil E101 | mood_detail_page.dart:34 |
| 4 | **添加药物向导丢数据**: `_save()` 硬编码 form/colorIndex/notes, 用户 Step1 选剂型 Step3 选颜色全部静默丢失 (列表永远绿色) | 底层/数据 | 简单 | sp-en N1 + flutter F105-1 + sp-zh ZH-09 + emil E104 | add_medication_page.dart:85-98 / medication_page.dart:415 / medication_detail_page.dart:67 |
| 5 | **`chroniccare.app` 域名 + `privacy@` 邮箱未注册** → 隐私政策/Support URL 不可达, 必拒 | 底层/外部 | 中 | AppStore A6 + GPlay GP-4 | fastlane/*/privacy_url.txt |
| 6 | **法律文档 3 份未律师审核且本批删"草稿"标"定稿"** → 误导风险, PIPL §28 前提缺失 | 底层/法务 | 高 | AppStore A9 + GPlay GP-5 | assets/legal/*.md 修订历史 |
| 7 | **iOS 签名未配置 + 截图缺失 + 内容评级未配置** (无 Mac, 需人工) | 底层/资产 | 中 | AppStore A7/A8/A10 | ios/ / fastlane |
| 8 | **Android Release keystore 未生成 + 8 张截图/feature_graphic 为 67B 占位 + IARC 未配置** | 底层/资产 | 中 | GPlay GP-1/GP-2/GP-3 | android/ / fastlane/metadata/android |

### 🟠 P1 — 高优 (功能缺口 / guard 回归 / a11y 硬伤) (16 项)

| # | 问题 | 架构/底层 | 难度 | 来源 |
|---|------|-----------|------|------|
| 1 | **新增药物不重排通知**: add 流程缺 `rescheduleMedicationReminders`/`rescheduleRefillReminders` (edit_medication_dialog:143-150 有此逻辑, 新向导漏了) → 新药无提醒直到重启 | 底层/功能缺口 | 中 | flutter F105-2 |
| 2 | **mood 录音模式选择不落库**: `recordingMode` 仅存 draft, 表/mapper/repo 均无列 | 底层/数据 | 简单 | sp-en N2 |
| 3 | **check_orphan_arb_keys 42 个孤儿 key** (全本批新增: 26×influenceFactor + moodReminder* + moodTrend* + setupConsentView*) → CI 红 | 底层/guard | 简单 | sp-zh ZH-02 + sp-en N3 |
| 4 | **check_zh_hant_consistency 16 处** (2 真错: 刮風→颳風, 分布→分佈; 14 人工改良 vs 守门员) → CI 红 | 底层/guard | 简单 | sp-zh ZH-03 + sp-en N3 |
| 5 | **影响因素 i18n 半成品**: `kInfluenceFactorKeys` (26 ARB key) 建好未 wire, chips 直读中文 fallback `kInfluenceFactors` 且**以中文入库** → en/zh_Hant 用户见中文 | 架构/i18n | 中 | sp-zh ZH-01 + sp-en N15 |
| 6 | **药丸图标白字对比度失败** (黄 ~1.3:1 / 灰 / 绿 / 红) | 底层/a11y | 简单 | emil E103 |
| 7 | **打卡 checkbox 无 Semantics + 28px 触摸目标 <48dp** | 底层/a11y | 简单 | emil E105 |
| 8 | **新 AnimatedSwitcher 不尊重 prefers-reduced-motion** (R104 E1 蔓延) | 底层/a11y | 简单 | emil E106 |
| 9 | **mood_trend 3 张 fl_chart 隐式动画未关 reduce-motion** | 底层/a11y | 中 | emil E107 |
| 10 | **空态不一致无 CTA**: medication 自定义空卡无"添加药物"按钮; mood_trend 裸 Center(Text) | 架构/UX | 简单 | emil E108 |
| 11 | **tracking record 按钮彩色文字 on 12% tint 对比 ~2:1** | 底层/a11y | 简单 | emil E109 |
| 12 | **设置档案卡 chevron 死胡同 + today_summary_header"点击展开"不可点** | UX | 简单 | emil E110/E111 |
| 13 | **今日汇总卡 4 列窄屏溢出 + streak"0天" vs"—"不一致** | 底层/a11y | 简单 | emil E114 |
| 14 | **锁屏通知暴露药名+剂量** (病耻感 + 5.1.1) | 底层/隐私 | 中 | AppStore A5 |
| 15 | **privacy_policy §0.6"录音暂停"与 flag=true 矛盾** | 文档 | 简单 | AppStore A4 |
| 16 | **gradle-wrapper distributionUrl 回归本地路径** `file:///C:/Users/...` (原 https), AGP 8.11.1 需 Gradle ≥8.13 | 底层/构建 | 简单 | GPlay GP-6 |

### 🟡 P2 — 上架后改进 (22 项)

| # | 问题 | 架构/底层 | 难度 | 来源 |
|---|------|-----------|------|------|
| 1 | MoodDetailPage / MoodFactorAnalysis 死代码 (无路由, 无挂载点, itemBuilder 未传 onTap) | 半成品 | 简单 | emil E102 + sp-en N4/N5 + flutter F105-6 |
| 2 | MoodReminderNotifier 无 UI 入口 (settings 无开关) → 功能半成品 + moodReminder* ARB key 孤儿 | 半成品 | 简单 | sp-en N6 |
| 3 | medication_detail 编辑按钮 `onPressed: () {}` no-op | 半成品 | 中 | emil E123 + sp-en N7 + flutter F105-15 |
| 4 | `_save()` 无 `_saving` 守卫 (双击重复插入) + 无 try/catch | 正确性 | 简单 | flutter F105-3/F105-4 |
| 5 | `await showTimePicker` 后无 mounted check × 2 | 生命周期 | 简单 | flutter F105-5 |
| 6 | mood_trend dailyAvg 滚动平均 bug ([1,2,5]→3.25 非 2.67) + build 内 DateTime.now() 跨日 stale | 正确性 | 简单 | flutter F105-8 + sp-en N8 |
| 7 | daily_tracking `_isToday` 跨 midnight stale (未 watch todayProvider) | 正确性 | 简单 | sp-en N9 |
| 8 | onReorder 7 次 state + 7 次全量写盘 | 性能 | 简单 | flutter F105-10 |
| 9 | 时间槽/打卡进度 3 份重复 + 时间格式化 5+ 处手写未走 Formatters | DRY | 中 | sp-en N10/N11 + sp-zh ZH-05 |
| 10 | _getLocalizedName/_getCategoryLabel 两套 switch 重复 | DRY | 简单 | sp-en N12 |
| 11 | R104 S5 残留: _dateOnly/inline DateTime 未全收敛 date_utils | DRY | 简单 | sp-en N13 |
| 12 | R104 S6 残留: EncryptedAudioStorage 用 Random() 非 secure | 安全 | 简单 | sp-en N14 |
| 13 | 图表 7 处硬编码 Apple 色不走 AppTokens | UI | 简单 | flutter F105-7 |
| 14 | 硬编码 'CBT' Tab / '7D/6M/1Y' 未走 ARB | i18n | 简单 | sp-zh ZH-04 + flutter F105-14 |
| 15 | 剂量显示 `'${dosage}${unit.id}'` 弃用 Formatters.dosage | i18n | 简单 | sp-zh ZH-06 |
| 16 | 通知 channel 名 const 中文 (Z12 残留) | i18n | 简单 | sp-zh ZH-07 |
| 17 | error 分支裸 `Text('$e')` 无重试 | 一致性 | 简单 | emil E113 + sp-zh ZH-08 |
| 18 | 新页 loading 用裸 CircularProgressIndicator 非 LoadingSkeleton | 一致性 | 简单 | emil E112 |
| 19 | 颜色选择器无 Semantics/无 PressFeedback; toggle 无 Haptics; Reorderable 无 Semantics label | a11y | 简单 | emil E115/E117/E118 |
| 20 | moodTrendCbtHint 半角逗号 | 文案 | 简单 | sp-zh ZH-10 |
| 21 | manifest debuggable="false" 被删 (R63 回退) + roundIcon 缺 pre-26 raster + label 未用 @string/app_name | 底层 | 简单 | GPlay GP-10/11/12 |
| 22 | **Apple Health P0 前置**: healthkit entitlement + 2 个 usage key + healthKitEnabled flag + schema 22 去重列 | 架构 | 中 | AppleHealth AH-2/7/9 |

### 🟢 P3 — 技术债 / Nice-to-have (10 项)

| # | 问题 | 架构/底层 | 难度 | 来源 |
|---|------|-----------|------|------|
| 1 | Apple HealthKit 集成 (P0 只读镜像 → P1 写备份 → P2 用药 → P3 后台) | 架构 | 大 | AppleHealth AH-1/5/6/10/11 |
| 2 | 播放结束不删 temp 解密文件 + `_startRecording` 失败未 cancel `_sttSub` | 资源 | 简单 | flutter F105-11/12 |
| 3 | _RecordingTimer 100ms setState 可再优 (ValueNotifier) | 性能 | 中 | flutter F105-13 |
| 4 | `_save` fire-and-forget + 未知 id 静默回退 | 正确性 | 简单 | sp-en N18 |
| 5 | 硬编码 Tab/CBT/emoji/颜色 + pill 色重复 | DRY | 简单 | sp-en N17 |
| 6 | 依从性数字 warning/success 彩色对比不足; mood_detail emoji 无 ExcludeSemantics; carousel 首卡无高亮 | a11y | 简单 | emil E119/E120/E121 |
| 7 | R104 E7/E8 残留: FAB Semantics + carousel emoji label; mood_factor 硬编码 Apple 状态色 | a11y | 简单 | emil E125/E126 |
| 8 | 时间段卡 header 只显示首剂量时间; 向导步骤无过渡 | UX | 简单 | emil E116/E124 |
| 9 | 6/10 主目标文件 dart format 未跑 | lint | 简单 | flutter F105-17 |
| 10 | PIPL 新字段(剂型/颜色/notes)未同步同意书; 术语混用; careCopy"今周"不通顺; Podfile 13.0 vs 14.0 | 合规/文案 | 简单 | sp-zh ZH-11/12/13 + AppStore A15 |

---

## 三、顶层架构审视 (需求 3 — 高内聚低耦合)

### 3.1 总体评估

当前 `presentation → domain ← data` + `shared/` umbrella 架构**方向正确且执行力强**:
- ✅ R104 的架构 P0 (tracking_item_config import flutter) 已修 → `check_all.dart` 2/2 全绿
- ✅ domain 层 0 Flutter 依赖 (仅影响因素的领域层中文文案问题)
- ✅ 跨 feature 边界 131 文件 0 violation
- ✅ privacy 边界 (vent 不进 trend/assessment) 持续保持

### 3.2 可重构模块 (按收益排序)

| # | 模块 | 当前问题 | 建议方案 | 收益 | 难度 |
|---|------|----------|----------|------|------|
| 1 | **influence_category** | 36 个中文因素在 domain 层, key 建好未 wire, 中文入库 | chips/入库走 `kInfluenceFactorKeys`→l10n, domain 只留 key | i18n 完整 + en/zh_Hant 可用 | 中 |
| 2 | **时间槽/打卡进度/时间格式化** | medication_page / today_med_schedule / today_summary_card 3 份重复 + 5+ 处手写 padLeft | 抽共享 helper + 统一 Formatters/HourMinute | DRY | 中 |
| 3 | **category→label/icon 映射** | tracking_item_card / tracking_customize_page 两套 switch | 统一到 tracking_item_config_ext.dart | DRY | 简单 |
| 4 | **_dateOnly/_daysBetween** | R104 S5 未收敛完 (trend_calculator / care_strategies 仍内联) | 全量换 date_utils | DRY | 简单 |
| 5 | **MedForm 双源** | presentation MedForm enum 与 domain MedicationForm 重复 | 删 UI 侧, 引 domain enum | 单真源 | 简单 |
| 6 | **MoodReminderNotifier / MoodDetailPage / MoodFactorAnalysis** | 半成品死代码, 要么接线要么删 | 接 UI (settings 开关 / mood-list onTap) 或删除 | 一致性 | 中 |
| 7 | **add 向导通知重排** | 新增药不 reschedule (edit 对话框有) | 复用 notification_service 的重排入口 | 功能完整 | 中 |

### 3.3 健康架构亮点 (不需动)

- NotificationService facade 拆 3 子 (medication/refill/mood_reminder notifier) 方向正确
- FeatureFlag 门控 8 项未完成功能, 模式成熟
- R104 的 SQL 注入 / god page / saveSetup 均已在早期 round 修复

---

## 四、底层逐行排查 — Bug 清单 (需求 4)

### 4.1 明确 Bug (需修)

| # | 文件:行 | Bug | 严重度 | 难度 |
|---|---------|-----|--------|------|
| 1 | add_medication_page.dart:85-98 | `_save()` 丢 form/colorIndex/notes (用户输入静默丢失) | HIGH | 简单 |
| 2 | mood_detail_page.dart:34 | 整页 Column 不可滚动 → overflow 裁切 | HIGH | 简单 |
| 3 | feature_flags.dart:70 + Info.plist + AndroidManifest.xml:51 | 录音 flag 开但权限声明已删 → crash | HIGH | 简单 |
| 4 | add_medication_page.dart:100 | 新增药物不 reschedule 通知 | HIGH | 中 |
| 5 | mood_recorder_page.dart:88,222 | recordingMode 选择不落库 | HIGH | 简单 |
| 6 | mood_trend_page.dart:193-195 | dailyAvg 滚动平均算法错 | MED | 简单 |
| 7 | mood_trend_page.dart:186 / daily_tracking_page.dart:55 | build 内 DateTime.now() 跨 midnight stale | MED | 简单 |
| 8 | add_medication_page.dart:85 | _save 无 _saving 守卫 + 无 try/catch | MED | 简单 |
| 9 | add_medication_page.dart:336-356 | showTimePicker 后无 mounted check ×2 | MED | 简单 |
| 10 | tracking_customize_page.dart:32-57 | onReorder 7 次 state + 7 次写盘 | LOW | 简单 |
| 11 | medication_detail_page.dart:181 | 编辑按钮 no-op | MED | 中 |
| 12 | gradle-wrapper.properties:4 | distributionUrl 本地路径 (构建不可移植) | MED | 简单 |
| 13 | medication_page.dart:300-307 | 时间段卡 header 只显示首剂量时间 | LOW | 简单 |
| 14 | mood_audio_recorder_widget.dart:302-341 | 播放完不删 temp 文件; 失败路径未 cancel _sttSub | LOW | 简单 |

### 4.2 代码质量统计

| 指标 | 数值 | 状态 |
|------|------|------|
| Analyzer error | 0 | ✅ |
| Analyzer warning/info | 0 | ✅ (R104 的 4W+30I 已清零) |
| 架构 check_all | 2/2 | ✅ |
| 跨 feature violation | 0 | ✅ |
| check_orphan_arb_keys | 42 孤儿 | 🔴 |
| check_zh_hant_consistency | 16 处 | 🔴 |
| dart format | 6/10 主目标文件漂移 | ⚠️ |
| 硬编码中文 (用户可见, 新批) | ~10 处 (影响因素 fallback 等) | ⚠️ |

---

## 五、半成品 / 未完成功能清单 (需求 2)

| # | 功能 | 状态 | 说明 |
|---|------|------|------|
| 1 | **录音 (vent + mood)** | 🔥 半开半关 | flag=true 但权限已删 → 既不可用又破坏上架一致性, 提交前必须二选一 |
| 2 | **MoodDetailPage** | 死代码 | 无路由, itemBuilder 未传 onTap |
| 3 | **MoodFactorAnalysis** | 死代码 | 无挂载点, _analyze 在 build 内无 memo |
| 4 | **MoodReminderNotifier** | 半成品 | 已注入 service 但无 UI 开关 |
| 5 | **medication_detail 编辑** | 假按钮 | onPressed no-op |
| 6 | **影响因素 i18n** | 半成品 | ARB key 建好未 wire, 中文入库 |
| 7 | **紧急联系人 SMS / IAP / 阿里云 SMS / Email / 5 厂商 push** | 半成品 (FeatureFlag 门控) | 全部 flag=false, release 不可达 (P3 外部依赖) |
| 8 | **Apple HealthKit** | 零集成 | 不阻塞上架, v1.1 候选 (AH 路线图) |

---

## 六、评分汇总 (vs R104)

| 视角 | R104 | R105 | 变化 | 主因 |
|------|------|------|------|------|
| emilkowalski | 9.0 | 7.5 | -1.5 | 新页 a11y (overflow/对比度/Semantics) + 假完成 |
| superpowers-en | 9.0 | 7.5 | -1.5 | 2 处静默丢数据 + 2 guard 红 + DRY 回潮 |
| superpowers-zh | 9.0 | 8.0 | -1.0 | 58 个 ARB 卫生回归 + 影响因素 i18n 半成品 |
| flutter-spec | 88 | 84 | -4 | 2 P1 功能缺口 + mounted/守卫缺失 |
| AppStore | 6.5 | 6.0 | -0.5 | 录音 flag/权限自相矛盾, 但 4 项 P0 修复落地 |
| GooglePlay | 40 | 42 | +2 | 描述/免责/适配图标, 但 2 新回归 |
| AppleHealth | 2/10 | 2/10 | — | 零集成 (P3) |

**综合结论**: R104 的架构/质量 P0 已全部落地 (analyzer 0 issue, 架构 2/2 绿), 但**本批未提交重设计引入了 8 项 P0 + 16 项 P1** — 核心问题是"功能做到了 80% 就停" (丢数据、假按钮、死代码、guard 红)。**当前工作区不可提交**。

## 七、建议执行顺序

1. **Sprint A (0.5 天)**: P0#1-4 — 录音决策二选一 + test 同步、mood_detail 滚动、_save 补三字段、通知重排
2. **Sprint B (1 天)**: P1#1-4 — recordingMode 落库或删 UI、清 42+16 ARB/繁简、gradle-wrapper
3. **Sprint C (2 天)**: P1#5-16 — 影响因素 i18n、a11y 对比度/Semantics、空态 CTA、锁屏通知脱敏、privacy 文档同步
4. **Sprint D (持续)**: P2 死代码接线/删除、DRY 收敛、token/ARB 补全、Apple Health P0
5. **外部依赖**: 域名注册 + 律师过审 (P0#5-6, 上架阻塞)

**下次审计**: v0.31 或本批提交后, 重点复查 42 orphan + 16 zh_Hant 清零 + MoodDetailPage 接线。
