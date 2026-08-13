# 底层逐行审计 C — presentation + core shared/theme/routing/l10n (2026-08-13, R112)

## 0. 元数据
- 视角: 底层逐行排查第 2 路 (presentation + core 共享层)
- 审视者: line-by-line-presentation (subagent 09)
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127 modified + 13 untracked (R112 进行中); analyze=0 error / 3 warning / 136 info; test=2377 pass / 4 fail (iOS 资产占位) / 1 skip
- 范围: `lib/presentation/**` 全部 199 文件 (providers 20 / pages 全 12 feature / widgets 40 / services 3) + `lib/core/shared/` 10 文件 + `lib/core/theme/` 8 文件 + `lib/core/routing/` 11 文件 + `lib/main.dart` + `lib/app.dart` + `lib/main/boot_apps.dart` + `lib/l10n/` 生成文件 + `lib/presentation/services/`。逐文件 read 覆盖 ≈ 200/237, 其余经 analyzer + 守门员脚本 (check_strings_hardcoded / check_arb_keys / check_orphan_arb_keys / check_cross_feature 全绿) + 目标 grep 交叉验证。
- 关键文件清单: routing 11 文件 / home (page+state+3 controller+8 widget) / medication 6 页 + 14 widget / mood 12 widget / mood_list 4 / vent 3 页 + 3 widget / trend 4 + 8 widget / assessment 4 页 + 12 widget / setup 6 + 2 widget / settings 3 页 + 15 widget / daily_tracking 3 页 + 13 widget / providers 20 / widgets 40 / theme 8 / shared 10 / main+app+boot。

## 1. 整体评分 (0-10)
**8.0/10** — 2 个 P1 (dispose 期 ref.read 资源泄漏链 + legal_page 裸 developer.log PII) / 9 个 P2, 其余全 P3; R111 待验证清单 8 项全部实读验证 (FS-14 死路由 / EM-21 mood label / R111-02 量表名 / R111-03 补打卡 / R111-10 mojibake / SP-111-02 warning 27→3 全属实闭环), R112 新增代码质量整体良好。

## 2. 关键发现

### P0
无。

### P1 (应修, 影响品质)

- [底层] **[E-01] dispose 期 ref.read → Riverpod 3 无条件 StateError → MoodAudioService 每次关闭泄漏 + vent/mood 明文 temp 文件残留** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:133-184` (`_disposeResources` 内 :164 `_service.cancelRecording()` / :176 `_service.dispose()` / mixin 链 :297 `cleanupTempFile`), `lib/presentation/pages/vent/vent_compose_page.dart:186-198` (`cleanupTempFile` :190)
  - 现状: Riverpod 3.4.2 实锤 `consumer.dart:561-562 read()` 无条件调 `_assertNotDisposed()`, `!context.mounted` 即 `throw StateError` (非 assert, release 也抛)。`dispose()` 用 `unawaited(_disposeResources()/asyncDisposeAudio(...))` 起链, 链内多个 await 后在 widget unmount 后才跑 `ref.read(...)` → 抛 StateError → 被各自 try/catch + swallowError 吞掉 → **`_service.dispose()` 永不执行 (AudioRecorder + SpeechToText native 句柄每次开 mood 弹窗泄漏, 频度 100+/day) + 播放后离开页面 temp 解密明文文件永不删除 (PIPL §28, 跟 R108 P0-018 vent_detail 同款漏洞)**。vent_detail 在 round 7b-5 (B1-11) 已用"字段缓存 storage"修, 这 2 处漏修; mood_recorder_page.dart:103 的 `_cbtDraftNotifier` initState 捕获是团队已知正确模式, 未推广到 storage/service。
  - 建议: 跟 B1-11 同款: initState/build 时把 `MoodAudioService` / `VentAudioStorage` / `MoodAudioStorage` 存 State 字段, dispose 链只用字段 (不碰 ref)。vent_compose 的 `stopRecordingImpl:142` / `_reRecord` 等在事件回调内合法, 不用动。

- [底层] **[E-02] legal_page 裸 `developer.log` 无 kReleaseMode 守卫 — 违反 R108 P0#12 release 静默策略, vent 删除失败时 stack trace 泄 PII 到 Xcode Console** — 修复难度:S — 工作量:0.2h
  - 位置: `lib/presentation/pages/settings/legal_page.dart:94`
  - 现状: 全 lib 6 处 developer.log, 5 处有守卫 (main.dart 3 处 kReleaseMode 或 kDebugMode, pii_safe_log/swallow_error 走 `_isProduct`), 仅此处裸写 `developer.log('vent deleteAll failed', error: e, stackTrace: st)` — 树洞删除失败时 release 模式把含文件路径/PII 的 stack 写进 console, 正是 R108 P0#12 锁定的漏洞类别 (lock-in 测试 `log_release_guard_round108_test` 只覆盖 main.dart)。
  - 建议: 删该行或换 `swallowError(where: 'legal_page.ventDeleteAll', ...)` (同文件 R94 附近已有 AppSnackBar.showError, developer.log 属冗余)。

### P2 (可修, 优化)

- [底层] **[R112-01] mood_trend_page 日均情绪值算法错 — 加权衰减平均而非均值, 偏袒最后一条** — 难度:S — 1h
  - 位置: `lib/presentation/pages/mood_list/mood_trend_page.dart:195-197`
  - 现状: `dailyAvg[day] = (dailyAvg[day] ?? 0) == 0 ? e.score : ((dailyAvg[day]! + e.score) / 2)` — 第 n 条权重 1/2^(n-1)。例 [5,1,1] → 2.0 (真均值 2.33); [2,4,4] → 3.5 (真 3.33)。趋势图数值系统性失真。
  - 建议: 改 count 累计 (`Map<DateTime, (int sum, int n)>`) 或先 group 再 mean; 补 3+ 条同日回归测试。

- [底层] **[R112-02] MoodDetailPage 死代码 + mood 列表条目无详情入口** — 难度:S — 0.5h
  - 位置: `lib/presentation/pages/mood_list/mood_detail_page.dart:19` (332 行, grep 全 lib 0 caller) / `lib/presentation/pages/mood_list/mood_list_page.dart:145` (`MoodListItem(entry: entries[i])` 无 onTap)
  - 现状: 情绪详情页 (完整 CBT 字段 / 转写 / 影响因素展示) 无路由无 caller; 用户从 /mood-list 点任何条目无反应, 唯一看详情的路径不存在。
  - 建议: 要么挂 onTap + 注册路由, 要么删 332 行死代码。

- [底层] **[R112-03] 影响因素 i18n 缺失 — en 用户看中文 chip** — 难度:M — 0.5d
  - 位置: `lib/presentation/pages/mood/widgets/mood_influence_chips.dart:91` (`Text(factor)`, factor 来自 domain `kInfluenceFactors` 硬编码中文 '工作'/'压力'...) / `lib/presentation/pages/mood_list/mood_detail_page.dart:137` (`Text(f)` 直接显示 DB 存的 `influenceFactorsJson` 中文串) / `lib/domain/entities/influence_category.dart:38-84` (`kInfluenceFactorsL10n` ARB key map **0 caller**)
  - 现状: EM-21 同族残留 — R111 hotfix 修了 moodLabel + 量表名, 但影响因子 chips + 详情页仍是中文硬编码。DB 已存中文串, 修需 key 化 (encode 存 key / 读时 zh→key 映射) 否则存量数据仍显示中文。
  - 建议: 录入侧改存 key (新数据) + 展示侧 zh 字面量→key 的反查映射 (旧数据), 走 kInfluenceFactorsL10n 的 ARB 派发。

- [底层] **[R112-04] setup_page_state `if (!mounted) { setState(...) }` 反模式** — 难度:S — 0.5h
  - 位置: `lib/presentation/pages/setup/setup_page_state.dart:373-376`
  - 现状: `_finishSetup` 联系人同意循环中, 用户经系统返回键离开 (PopScope canPop=true at step≠0) 后 ConsentDialog 返回 → `if (!mounted) { setState(() => _saving = false); return; }` — 在 unmounted State 上调 setState → release 也抛 StateError, 落 runZonedGuarded 记 LastErrorCapture (用户下次启动看到"上次启动出错" banner, 假阳性)。
  - 建议: `if (!mounted) return;` 即可 (`_saving` 随 widget 销毁无需复位)。

- [底层] **[R112-05] onReorder deprecated (Flutter 3.41) + ReorderableDragStartListener index 用 sortOrder 而非列表位置** — 难度:S — 1h
  - 位置: `lib/presentation/pages/daily_tracking/tracking_customize_page.dart:33` (analyzer deprecated_member_use) + `:165` (`index: config.sortOrder`)
  - 现状: onReorder 已 deprecated, 需迁 `onReorderItem` (新回调 newIndex 已自动补偿, 需删 `if (newIndex > oldIndex) newIndex--`)。`ReorderableDragStartListener.index` 必须是 itemBuilder 的位置 `i`, 当前用 sortOrder 只因 sortOrder 0..n-1 连续 + 列表按 sortOrder 排序碰巧相等; 若持久化数据非连续即拖拽错位。tile 未收到 `i`。
  - 建议: 迁 onReorderItem + 把 itemBuilder 的 `i` 传入 `_TrackingItemTile` 供 drag listener 用。

- [底层] **[R112-06] AssessmentSparkline maxTotal 写死 phq9 27 / 其他 21 — 8 个新量表数据画出界** — 难度:S — 1h
  - 位置: `lib/presentation/pages/assessment/assessment_widgets.dart:61` (`scaleId == 'phq9' ? 27 : 21`); 实际 WHODAS 48 / PSS 40 / ISI 28 / ASRM 20 (domain totalRange)
  - 现状: `/assessment/whodas` 等提交后 `_buildComparisonWidgets` 渲染 sparkline, y = size.height - (total/maxTotal)*height, total>21 → y 为负 → 点线画在组件外被裁剪; 均值虚线同错。
  - 建议: 由 `scaleById(scaleId)?.totalRange` 传 maxTotal, 0 值防御。

- [底层] **[R112-07] `/medication/detail/:id` int.parse 崩深链** — 难度:S — 0.2h
  - 位置: `lib/core/routing/app_route_medication.dart:96` (`int.parse(state.pathParameters['id']!)`)
  - 现状: 与 vent detail (`app_route_vent.dart:37` tryParse→0) 不一致; 恶意/损坏 URL `/medication/detail/abc` 在 pageBuilder 抛 FormatException (不属于 errorBuilder 覆盖路径) → release 崩溃日志。
  - 建议: `int.tryParse(...) ?? 0` + MedicationDetailPage 空态 (detail 页已有 medNotFound 分支)。

- [架构] **[R112-08] 量表翻译三源死代码仍 0 caller + scaleNameL10n 成第 4 份平行 switch** — 难度:L — 2-3d (R111 AR-17 跨期残留)
  - 位置: `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` (810L) + `scale_translations_l10n.dart` (32L) — 全 lib 0 import; 新 `scale_name_l10n.dart:15-40` 与 `assessment_center_card.dart:27-71` `_l10nName/_l10nShortDesc` 又是两份同 switch。
  - 现状: R112 修 R111-02 新增第 4 份派发而 842L 死代码原样保留; 4 处 switch 改一个新量表名要同步 4 份。
  - 建议: 按 R112 路线图: 三源合一 (删 842L + 收敛 center_card 私有 copy 到 scale_name_l10n), 顺带 static_scale_translations 的 items 走 R51b 一并决断。

- [底层] **[R112-09] setup MedCard 时间 chip 增删不触发重建 (瞬态 UI 滞后)** — 难度:S — 0.5h
  - 位置: `lib/presentation/pages/setup/setup_step_medication.dart:281` (`onDeleted: () => med.times.removeAt(tIdx)`)、`:297` (`med.times.add(picked)`) — `MedDraft` (setup_widgets.dart:17-32) 非 ChangeNotifier, attachListener 只挂 name/dosage controller
  - 现状: 删/加时间 chip 后 Wrap 不重建 (无 setState 路径), 直到用户动任一 TextField 触发父级 `_onTextChanged`→setState 才刷新 — 用户会看到"删除没反应"的假 bug。
  - 建议: onAddMed 同款, 把 times 变更通过回调 (如 onRemoveMed 模式) 或 MedDraft 加 timesChange 通知回调接 `_onTextChanged`。

### P3 (建议, 长期)

- **R111-04/05/06/07 跨期残留复验**: mood_trend_page:103 / medication_page:196 / medication_detail_page:229-231 仍 raw `Text('$e')`; consent_dialog:87,91 raw TextButton/FilledButton; `_formatTime/_formatDateTime` 手写 pad 绕过 Formatters (vent_detail:232 / vent_list:358 / mood_detail:273 / assessment_widgets:426 / medication_calendar_page 补打卡 snackbar / edit_medication_dialog:411 等 6+ 处); error_state.dart:86-87 raw ElevatedButton.icon (未复读, 沿用 R111 结论待验证)。
- **3 warning 明细 (基线已确认)**: crisis_hotline_page.dart:30 + medication_calendar_page.dart:27 unused_import(app_motion) + test/medication_backfill_round8_test.dart:12 unused_import — 0.1h 清。
- **4 use_build_context_synchronously 逐一核实为安全**: home_deep_link_handler.dart:198/207/208 + home_care_engine_dispatcher.dart:74 均有 `isMounted()`/`mounted` 闭包守卫 (闭包 = `() => mounted`), analyzer 无法证明但语义安全; 建议统一改 `if (!context.mounted)` 让 lint 消音。
- **2 unnecessary_import**: quick_mood_carousel.dart:31 + tween_number.dart:16 (app_motion 经 app_tokens 已导出); boot_apps.dart:57/76/139/220 4 个 public widget 缺 key 参数 (use_key_in_widget_constructors)。
- **notification_status_card.dart:135 测试 id 99001 落在 refill band [6000,206000) 内** — 注释声称"不会跟任何业务通知冲突"不准确 (需 medId≈93001 才撞, 实际安全), 建议测试 id 改 5M+ 带外或改注释。
- **AppListTile.dart:166 `_isDestructive` 0 使用** (dead 分支) + 模式 2 注释 "透传 onTap 给 ListTile" 与实际 (恒 null) 不符。
- **theme_provider `_load` 与 `set` 竞态**: 用户快速切主题时 `_load` 的异步读可能覆盖新设置 (冷启动特例)。
- **vent_list_page:327-356 `_confirmDelete` (长按) 无 Haptics.warning 无 undo snackbar**, 与 swipe 路径不一致; :353 用 `ProviderScope.containerOf(context).read` 绕过 WidgetRef (可行但模式怪异)。
- **setup_page_state:355 `thresholdDays: 2` 硬编码** (care_strategies.secondDayMissed 语义, 注释已标)。
- **tracking_customize_page:177-195 / tracking_item_card:164-204 默认分支返 raw ARB key 名** — 新追踪项漏加 switch 分支时用户看到 'moodDiaryName' 字面量。
- **mood_trend_page:66 `const Tab(text: 'CBT')`** — 3 tab 中 2 个走 l10n 1 个硬编码 (CBT 是缩写可接受, 留档)。
- **cbt_section_field.dart `TextButton.icon(label: const Text('?'))`** 与 mood_quick_button 等 raw 按钮残留 (emil 集中器待迁移)。
- **MedCard/QuickMoodCarousel 等 FilledButton/TextButton 少量未迁 PrimaryButton** (treatment_page:54 FilledButton.icon 等)。
- **E-01 同源防御缺失**: mood_audio_section.dart / preset_templates_sheet 等未复读文件建议 grep `unawaited(` + `ref.read` 复查 (本次已覆盖主要 6 处 asyncDispose 链)。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (lib/ 范围内)
- `tel:` scheme: crisis_hotline_page.dart:239 `Uri.parse('tel:$number')` — number 全来自 ARB, 无硬编码外链。
- 无 http(s) URL 硬编码于本范围文件 (grep 未命中)。
- 域名/邮箱均不在 presentation/core 层 (属 data 层 + fastlane, 由 04/05 视角覆盖)。

## 4. 四类问题 (用户点名)

### 4.1 上架相关
- E-02 (legal_page developer.log) 是唯一本范围的上架/PII 风险 (release console 泄 stack)。
- 锁屏 PII: 通知 title/body 属 data 层 (08 视角), presentation 无新增风险。

### 4.2 架构相关
- R112-08 (842L 死代码 + 4 份平行 switch) 是本范围最大架构债, 与 R111 AR-17 一致, 已列 R112 路线图"三源合一"。
- R112-09 (MedDraft times 无通知机制) 与 E-01 (storage 未字段缓存) 同源: "资源/状态归属不清"。
- 其余 4 层边界健康: check_cross_feature 138 文件 0 violation; domain purity 由 08 视角。

### 4.3 重构建议
- E-01 修复时把 AudioLifecycleMixin 增加一个 `onCleanupTemp` 注入点或让 mixin 收 `Future<void> Function(String path)?` 字段, 彻底移除 dispose 期 ref 依赖 (比逐处字段缓存更彻底)。
- R112-09 顺手把 MedDraft 改 ChangeNotifier (3 处 attachListener 自然覆盖 times)。

### 4.4 半成品 / TODO / 残缺功能
- R112-02 MoodDetailPage 死代码 = 情绪详情功能缺失 (列表不可点)。
- R112-03 影响因素 i18n = EM-21 修复的未完成部分。
- R112-06 sparkline 8 量表支持不完整。
- R111-03 补打卡已真实现 (round 8), 非残缺; R111-08 vent 全链路 widget test 仍未补 (0 新增相关测试文件, 本批 test 目录无 vent_compose 全链路)。

## 5. 总结 + 给整合者的建议

1) **0 P0 / 2 P1 / 9 P2 / 12 P3**, 评分 8.0/10 — R111 8 项待验证清单全部实读闭环属实 (FS-14 修 / EM-21 修 / R111-02 修 / R111-03 真实现 / mojibake 清 / warning 27→3 / EM-14 / EM-16)。
2) **hotfix 优先级**: E-02 (0.2h) → E-01 (0.5d, 复用 B1-11 字段缓存模式) → R112-01 (1h, 数值正确性) → R112-04 (0.5h, 假阳性错误 banner)。
3) **给 08 视角的交叉验证提示**: export v5 (E1/E2) 的 presentation 侧 import_tile 走 `dataExportServiceProvider.importFromJson` 已适配; `watchAll().first` 模式在 add_medication:114 / edit_dialog:148 / app.dart:190 三处使用, 建议 08 侧确认 repo stream 首次 emit 不会因空 DB 而 hang (timeout 仅 app.dart 有)。
4) **守门员盲区补刀**: check_strings_hardcoded.py 不扫 domain 静态 Map (`kInfluenceFactors`), R112-03 是继 R111-02 后的第二个 domain 中文泄漏样板 — 建议 R112 hotfix 给该脚本加 `lib/domain/` 中文字面量规则或把 kInfluenceFactors 迁 ARB key。

## 附录: 详细证据

- Riverpod ref-after-dispose: `/Users/vium/.pub-cache/hosted/pub.dev/flutter_riverpod-3.4.2/lib/src/core/consumer.dart:469-478 (_assertNotDisposed, throw StateError 非 assert)`, `:561-562 (read 无条件调用)`。
- E-01 链: mood_audio_recorder_widget.dart:116-127 dispose → :133-184 _disposeResources (await 链) → :293-305 cleanupTempFile (`ref.read(moodAudioStorageProvider)`); vent_compose_page.dart:91 unawaited(asyncDisposeAudio) → audio_lifecycle.dart:434-437 (`await cleanupTempFile()`); 对照已修样例 vent_detail_page.dart:72-100 (B1-11 字段缓存)。
- R111 闭环证据: contacts_list_widget.dart:42-45 (FS-14); mood_label.dart:9-16 + trend_mood_chart.dart:111/221 + mood_quick_button.dart:51 (EM-21); scale_name_l10n.dart + assessment_page.dart:88 + assessment_section.dart:60-61 + assessment_multi_line_chart.dart:143 (R111-02); medication_calendar_page.dart:239-330 (R111-03, diff 实测); `grep -c '�' reminders_hub_page.dart` = 0 (R111-10)。
- analyzer 全量: 0 error / 3 warning / 136 info (136 为本轮复测, 基线 133 + R112 新增 test trailing comma 等)。
- 守门员: check_strings_hardcoded OK (34 override 对 + inline 0) / check_arb_keys OK (zh=zh_Hant=1250) / check_orphan_arb_keys OK (0 orphan) / check_cross_feature OK (138 文件 0 violation)。

<!-- subagent: line-by-line-presentation 完成时间: 2026-08-13T18:30:00+08:00 -->
