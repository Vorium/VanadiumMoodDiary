# R105 三视角审视 — superpowers-en（架构纯净 / 一致性 / 可维护性 / 正确性 / 工程守门员）

- 日期：2026-08-09
- 基线：R104 报告 `docs/audit/2026-08-09/02-superpowers-en.md`（9.0/10，S1-S8）
- 审查对象：R101+ 未提交批次（medication 重构 / mood 详情与趋势 / daily-tracking 自定义 / 8 新量表 / R104 修复）
- 验证方式：`flutter analyze`（0 issue）+ `check_all.dart`（2/2 全绿，domain 0 flutter/drift/data/presentation，shared 2+ 层使用）+ `check_cross_feature.py`（131 文件 0 violation）+ 守门员脚本批量执行

## 已修复（R104 → R105，不再重复报告）

| R104 项 | 状态 |
|---|---|
| S1 P0 tracking_item_config.dart import flutter | 已修：改纯 Dart（int iconCodePoint/colorValue），IconData/Color 由 tracking_item_config_ext.dart 扩展恢复；`check_all.dart` 由 1 violation → 2/2 全绿 |
| F1 native.dart `PRAGMA` 拼接 | 已修（转义 + 校验） |
| F3 mood audio 100ms setState | 已修（`_RecordingTimer`） |
| Z8 care_copy / Z9 assessment_comparison 硬编码 | 已修（`toReportString`/文案走 `Strings.*` override） |
| S7 SharedPreferences.getInstance() 8 次 | 已修：SafetyConfigService 缓存 `_prefs`（R102） |

## 评分：7.5 / 10

**总结**：R104 全部 P0/P1 架构项基本清零，4 层纯净度（check_all 2/2）、跨 feature 边界（131 文件 0 violation）、`flutter analyze` 0 issue 均达标，date_utils 收敛了半数 R104 S5 日期重复。但本批（R101+）自身引入了 **2 处 P1 静默丢数据**（新增药物表单的 form/colorIndex/notes 三字段被 `_save()` 丢弃；mood 录音模式 UI 可选但不落库）、**守门员 2 项变红**（`check_orphan_arb_keys` 42 个孤儿 key + `check_zh_hant_consistency` 16 处不一致，CI 会 fail），以及一批**半成品死代码**（MoodDetailPage 无路由、MoodFactorAnalysis 无挂载、MoodReminderNotifier 无 UI 入口、medication_detail 编辑按钮 no-op）。新页面大量手写时间格式化、时间槽/打卡进度 3 份重复，DRY 回潮明显。建议下轮优先：① `_save()` 补齐三字段 + recordingMode 落库或删 UI；② 清 58 个 ARB/繁简问题恢复守门员全绿；③ 死代码接线或删除。

## 发现清单

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|---|---|---|---|---|---|---|
| N1 (新) | `_save()` 硬编码 `form: MedicationForm.tablet / colorIndex: 0 / notes: null`，用户选择的剂型/颜色/备注被静默丢弃；列表/详情页同款 TODO | add_medication_page.dart:91-98；medication_page.dart:415；medication_detail_page.dart:67 | 正确性/静默数据丢失 | 简单 | **P1** | `_save()` 传 `form: _form.id`（映射 MedicationForm）+ `colorIndex: _colorIndex` + `notes`；三处 `colorIndex: 0` TODO 改为取实体值 |
| N2 (新) | mood 录音模式 SegmentedButton 可选（momentary/daily），但 draft→repo→mapper→表均无 recordingMode 列，选择不落库 | mood_recorder_page.dart:88,222；mood_entry_draft.dart:102；mood_repository_impl.dart | 正确性/静默数据丢失 | 简单 | **P1** | 二选一：加 `recording_mode` 列 + migration(from<22) + 双向 mapper 映射；或删掉该 UI 与 draft 字段（避免假功能） |
| N3 (新) | 守门员变红：`check_orphan_arb_keys` 42 个孤儿 key（25×influenceFactor*、moodReminder*、moodTrend*、moodFactorAvgScore/Count、medDetailNoFactors、moodDetail4D、moodEditTooltip、moodAudioRecording、setupConsentView*）；`check_zh_hant_consistency` 16 处（medAdd/medEmpty*「添加 vs 新增」） | lib/l10n/app_zh.arb 等 | 工程守门员/CI | 简单 | **P1** | 新 feature 的 ARB key 接线或删除；zh_Hant 走 OpenCC s2tw 校正（medAddTooltip/medEmptyTitle/medEmptySubtitle/medAddTitle/medAddStep1Title …） |
| N4 (新) | MoodDetailPage 定义但无任何路由/导航引用（死代码）；mood 列表项未传 onTap → detail 永远不可达 | mood_detail_page.dart:17；mood_list_page.dart:145 | 半成品/一致性 | 简单 | **P2** | 给 MoodListItem 传 onTap → push `/mood-detail` 路由；或删除死代码 + 对应 ARB key |
| N5 (新) | MoodFactorAnalysis 定义但全工程无挂载点（死代码），且 `_analyze(entries)` 在 build 内对全量 entries 重算、无 memo | mood_factor_analysis.dart:17,96-130 | 半成品/性能 | 中 | **P2** | 挂到 mood_trend 或 mood_list 详情；`_analyze` 结果抽成 computed provider 或 memo |
| N6 (新) | MoodReminderNotifier 已注入 NotificationService（:83/:116/:287-299），但全工程无 UI 开关调用 `scheduleMoodReminder`，功能半成品；对应 moodReminder* ARB key 成孤儿 | core/data/services/mood_reminder_notifier.dart；notification_service.dart:287-299 | 半成品/一致性 | 简单 | **P2** | reminders_hub/settings 加开关接线；否则移除 service + ARB key |
| N7 (新) | medication_detail_page 编辑按钮 `onPressed: () {}` no-op（TODO 未实现） | medication_detail_page.dart:181 | 半成品 | 中 | **P2** | 接 EditMedicationDialog 或先隐藏按钮（no-op 按钮比没有更糟） |
| N8 (新) | `_MoodLineChart` 日均值用「运行平均」`total/seen`（各点权重不均，非当日真均值）；且 build 内 `DateTime.now()` 未挂 todayProvider，跨 midnight 数据 stale（违反 AGENTS 已知坑） | mood_trend_page.dart:186-202,152 | 正确性 | 简单 | **P2** | 按日 sum/count 求真平均；图表 watch todayProvider 复用 now |
| N9 (新) | daily_tracking_page `_isToday` 在 build 内 `DateTime.now()`（未用 todayProvider），跨 midnight 判定 stale | daily_tracking_page.dart:55-61,153 | 正确性 | 简单 | **P2** | watch todayProvider 复用同一 now |
| N10 (新) | DRY 回潮：medication_page `_buildTimeSlots`/`_SlotEntry` 复制 today_med_schedule `_buildEntries`/`_ScheduleEntry`；today_summary_card 再实现一份「今日药物进度」 | medication_page.dart:168-214；today_med_schedule.dart:112-150；today_summary_card.dart:34-42 | 架构/DRY | 中 | **P2** | 抽共享 helper（activeMeds×times 展平 + 当日已打卡 medIds），3 处复用 |
| N11 (新) | 新页面手写 `_formatTime`/`_formatTimestamp`（padLeft 散落），未复用 HourMinute.toTimeString()/Formatters；全工程 padLeft(2,'0') 71 处 | medication_page.dart:302,428；medication_detail_page.dart:82；add_medication_page.dart:332,373；mood_detail_page.dart:264；mood_list_item.dart:83 | 架构/DRY | 简单 | **P2** | 全部改 `t.toTimeString()` / Formatters.dateTime |
| N12 (新) | `_getLocalizedName`（tracking_item_card:152-235）与 `_getCategoryLabel`（tracking_customize_page:175-207）两套 switch 重复，category→label/icon 映射散落 | tracking_item_card.dart；tracking_customize_page.dart | 架构/DRY | 简单 | **P2** | 抽到 tracking_item_config_ext.dart 统一 nameKey/categoryKey → l10n 映射 |
| N13 (残留) | R104 S5 未收敛完：trend_calculator 私有 `_dateOnly` 仍在（:188），care_strategies:29,32,46 仍内联 `DateTime(y,m,d)`；date_utils.dart 已建但只被 2 处引用 | trend_calculator.dart:188；care_strategies.dart:29,32,46 | 底层/DRY | 简单 | **P2** | 全量替换为 `isSameCalendarDay`/`calendarDaysBetween`；assessment_comparison:273 冗余 `_daysBetween` wrapper 一并删除 |
| N14 (残留) | R104 S6：EncryptedAudioStorage 文件名用 `Random()` 非 `Random.secure()`（db_key_service/encryption_service 已是 secure，此处不一致） | core/data/privacy/encrypted_audio_storage.dart:116,127,208 | 安全 | 简单 | **P2** | 改 `Random.secure()` |
| N15 (残留) | R104 Z7：influence_category 36 个因素名硬编码中文在 domain（进中文违反 domain 文案约束），chips 直接显示原始中文；`kInfluenceFactorKeys` 定义了但未使用，注释引用的 `kInfluenceFactorsL10n` 不存在（死引用） | influence_category.dart:36-118；mood_influence_chips.dart:97-141 | 架构/i18n | 中 | **P1** | chips 走 `kInfluenceFactorKeys` → `l10n`（配套 25 个 influenceFactor* ARB key 即被接线）；删除死 map/注释；domain 只留 key 定义 |
| N16 (残留) | R104 F9/F10：day_detail `_scaleName` 仍只映射 phq9/gad7（其余 6 新量表显示 raw id）；check_in_entity `_assessmentScaleIds` 仍硬编码 3 个量表 | day_detail.dart:371-394；check_in_entity.dart:85-95 | 底层/i18n | 简单 | **P2** | scale_registry 统一 displayName 与 id 集 |
| N17 (新) | mood_trend_page 硬编码 `Tab('CBT')`、'7D/30D/6M/1Y'、emoji 数组、hex 颜色（未走 ARB / MoodVisual.emojiFor / AppTokens）；kMedPillColors 与 tracking 色值重复 | mood_trend_page.dart:64,20-21,311-317,382,539-540；medication_pill_icon.dart | 底层/i18n+UI | 简单 | **P3** | 文案/区间走 ARB，emoji 走 MoodVisual，颜色走 AppTokens；pill 色复用 tracking 色 token |
| N18 (新) | tracking_config_provider `_save` fire-and-forget（快速连续 toggle 可能丢写）；`get(id)` 未知 id 静默回退 mood 配置 | tracking_config_provider.dart:90-128,23-29 | 正确性 | 简单 | **P3** | 合并写/队列化；未知 id 按 `kDefaultTrackingItems` 逐 id 找，找不到返回空 config |

## 守门员状态（本批执行）

| 脚本 | 结果 |
|---|---|
| `flutter analyze` | OK（0 issue） |
| `dart scripts/check_all.dart` | OK（2/2：纯度 + 一致性） |
| `python scripts/check_cross_feature.py` | OK（131 文件，0 violation） |
| `python scripts/check_arb_keys.py` | OK |
| `python scripts/check_changelog.py` | OK（0.30.0+85） |
| `python scripts/check_no_pua.py` / `check_legal_consent.py` / `check_datetime_race.py` | OK |
| `python scripts/check_orphan_arb_keys.py` | **FAIL：42 个孤儿 key**（新引入，N3） |
| `python scripts/check_zh_hant_consistency.py` | **FAIL：16 处繁简不一致**（medAdd/medEmpty*，新引入，N3） |
| `python scripts/check_fullwidth_punctuation.py` | WARN-only：132（既有，不影响） |
