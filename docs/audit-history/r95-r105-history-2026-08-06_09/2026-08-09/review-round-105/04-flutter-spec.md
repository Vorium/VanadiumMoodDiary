# flutter-specification 视角报告 — R105 重设计批次 (2026-08-09)

**评分**: 84/100 (vs R104 基线 88, 本批无新 P0, 但有 2 项 P1 功能缺口 + 多项 P2)
**基线**: R104 (2026-08-09)
**范围**: uncommitted 重设计批次 — medication 3 页 / mood_list 3 页 / mood audio recorder / tracking customize / mood_reminder_notifier / tracking_config_provider / date_utils

## 已验证无问题项 (R104 修复确认落地, 不重复上报)

- F1 SQL 注入 (native.dart:27): 已加 base64 字符白名单 + 单引号转义 → ✅ 已修
- F2 空 setState 整页重建 (vent_compose): 不在本批改动, R104 未动 → 不评
- F3 100ms setState (mood_audio_recorder): R102 已缩到 `_RecordingTimer` 30 行 widget 内 → 残留 P3 (见 F105-11)
- Z1-Z5 硬编码中文 (mood_detail / add_medication / medication_page): 全部走 l10n ✅ 已修
- F8/F9 analyzer 4 warning + 30 info: `flutter analyze` 当前 **No issues found!** → ✅ 已清零
- 架构违规 S1 (tracking_item_config.dart): R104 已改 int 码点 + ext 层转换 ✅ 已修
- `check_datetime_race.py` / `check_datetime_race2.py`: 本批新代码 **0 race** ✅
- `check_cross_feature.py`: 131 files 0 violations ✅
- schema 迁移: medications +3 列 (v19→v20) + mood_entries +1 列 (v20→v21) 均在 app_database.dart 有 onUpgrade ✅
- dispose 链抽查: add_medication 2 controller / mood_trend TabController / recorder timer / service._sttController.close 全部正确 ✅

## 问题表

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|------|------|---------|-----------|------|--------|------|
| F105-1 | 添加药物向导丢弃 form + colorIndex 用户输入 | add_medication_page.dart:91-98 | 数据正确性 | 简单 | P1 | `MedicationDraft` 补 `form: _form.id 映射到 MedicationForm` + `colorIndex: _colorIndex`; 顺带删掉 presentation 层重复枚举 `MedForm` (与 domain `MedicationForm` 双源) | 新 |
| F105-2 | 新药添加后不重排通知 — 新增药物无提醒直到重启 | add_medication_page.dart:100-103 | 功能缺口 | 中 | P1 | 参照 edit_medication_dialog.dart:141-150, `_save` 成功后 `ref.refresh(medicationsProvider.future)` + `notificationServiceProvider.rescheduleMedicationReminders(meds)` + `rescheduleRefillReminders(meds)` | 新 |
| F105-3 | `_save()` 无 `_saving` 守卫 — 双击保存重复插入药物 | add_medication_page.dart:85-105 | 正确性 | 简单 | P2 | 加 `_saving` bool, 入口早返, 参照 MoodRecorderPage._save 模式 | 新 |
| F105-4 | `_save()` 无 try/catch — DB 失败 → unhandled async error | add_medication_page.dart:85-105 | 健壮性 | 简单 | P2 | try/catch + `if (mounted)` + AppSnackBar.showError | 新 |
| F105-5 | `await showTimePicker` 后无 mounted check × 2 — setState-after-dispose 风险 | add_medication_page.dart:336-340, 352-356 | 生命周期 | 简单 | P2 | 改为 `if (picked != null && mounted)` — 本项目 edit_medication_dialog.dart:171 已有同款先例 | 新 |
| F105-6 | MoodDetailPage 死代码 — 无路由 + MoodListItem.onTap 未接线 + 注释声称"录音播放"但只有时长无播放 | mood_detail_page.dart:17, mood_list_item.dart:19-32, app_route_mood_list.dart | 架构 | 中 | P2 | 接线: route `/mood-list/detail` + `MoodListItem(onTap:)`; 若要播放需走 mood_audio_storage.decryptToTemp + AudioPlayer (dispose 链参照 MoodRecorder) | 新 |
| F105-7 | `_DistributionChart` / `_CbtEffectChart` 硬编码 Apple 色 (0xFF34C759 等 7 处) 不走 AppTokens, dark mode 无适配 | mood_trend_page.dart:311-317, 538-540 | UI/规范 | 简单 | P2 | 移入 AppTokens (同 R104 F4/F5 模式) | 新 |
| F105-8 | `dailyAvg` 滚动平均 bug: [1,2,5] 算成 3.25 非 2.67 | mood_trend_page.dart:193-195 | 正确性 | 简单 | P2 | 改为先求和再除 count, 或取当日首条 | 新 |
| F105-9 | 趋势页不 watch todayProvider — 跨 midnight 后 `DateTime.now()` stale, 图不刷新 | mood_trend_page.dart:186 | 生命周期 | 简单 | P3 | 同 medication_page 模式, watch todayProvider 注入 now | 新 |
| F105-10 | onReorder 循环内 7 次 `reorder()` → 7 次 provider state set + 7 次 `_prefs.setString` 全量写盘 | tracking_customize_page.dart:32-57 | 性能 | 简单 | P2 | Notifier 加 `reorderAll(Map<id,order>)`: 一次 state + 一次 _save | 新 |
| F105-11 | 播放自然结束 onPlayerComplete 不删 `_tempDecryptedPath` — 磁盘临时文件残留到 dispose | mood_audio_recorder_widget.dart:73-76, 302-341 | 资源 | 简单 | P3 | onPlayerComplete 内清理 temp (try/finally), 残留自 R102 优化范围 | 残留 |
| F105-12 | `_startRecording` 失败路径未 cancel `_sttSub` | mood_audio_recorder_widget.dart:189-204 | 资源 | 简单 | P3 | catch 内 `unawaited(_sttSub?.cancel())` | 新 |
| F105-13 | `_RecordingTimer` 仍 100ms `setState((){})` 重建计时 widget (已缩范围但可再优) | mood_audio_recorder_widget.dart:543-561 | 性能 | 中 | P3 | service 暴露 ValueNotifier<Duration> + ValueListenableBuilder, 去掉 Timer | 残留 |
| F105-14 | 硬编码 'CBT' Tab label 未走 ARB | mood_trend_page.dart:64 | i18n | 简单 | P2 | 加 ARB key (zh/en/zh_Hant 3 语同步) | 新 |
| F105-15 | medication_detail: 依从性加载期显示 0% (`checkInsAsync.value ?? []`), 编辑按钮为 TODO 空实现, `colorIndex: 0` 硬编码 | medication_detail_page.dart:38, 181, 67 | 正确性/半成品 | 简单 | P3 | loading 态显示骨架; 编辑按钮先禁用或跳 edit dialog; 用 `med.colorIndex` | 新 |
| F105-16 | medication_page: `error: Text('$e')` 裸错误文案 + `_SlotEntryRow` 无必要 ConsumerWidget (无 watch) | medication_page.dart:162, 332 | 规范 | 简单 | P3 | 错误走 EmptyState/l10n; ConsumerWidget 改 StatelessWidget + onCheckIn 回调 | 新 |
| F105-17 | 6/10 主目标文件 `dart format` 未跑 — format drift | medication_page / add_medication_page / medication_detail_page / mood_detail_page / mood_trend_page / tracking_customize_page | lint | 简单 | P3 | `dart format` + `dart fix --apply` (AGENTS.md 组合) | 新 |

## 总结

本批重设计整体质量高: **0 analyzer error / 0 race / 0 跨 feature 违规 / 0 新 StreamSubscription 泄漏**, R104 的 P0 (SQL 注入、硬编码中文、架构违规) 全部确认修复落地, 4 warning + 30 info 也清零。

最需要优先修的是 **2 个 P1 功能缺口**:
1. **F105-1** 添加向导收集的剂型 + 颜色根本没存进 DB — 用户输入静默丢弃 (medication_page / detail_page 的 `colorIndex: 0 // TODO` 同源)。
2. **F105-2** 新增药物不触发通知重排 — 用户添加新药后直到下次重启都收不到服药提醒 (edit_medication_dialog 有此逻辑, 新向导漏了)。

其余为 P2 正确性/规范 (mounted check、重复插入守卫、reorder 批量写盘、图表平均算法、ARB/颜色 token 化) 与 P3 清理项。无 P0 crash/leak。
