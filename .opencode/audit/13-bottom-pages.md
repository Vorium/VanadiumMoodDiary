# 13-bottom-pages.md — 批次 4/4 底层逐行 bug 猎手报告 (lib/presentation/pages/ 全 13 目录)

**审计范围**: `lib/presentation/pages/` 152 文件 / 26,363 行。全文件 glob + 大文件精读 (vent_list 645 / mood_audio_recorder 612 / mood_trend 609 / legal 555 / vent_compose 520 / notification_status_card 491 / mood_recorder 476 / vent_detail 464 / assessment_widgets 435 / mood_detail 432 / home_page_state 420 / edit_medication_dialog 417 等), 其余文件逐份读取或模式 grep。
**基线**: R113 修复战役已闭环 (8+8+5 bug 已修)。本报告只列 NEW/REMAINING。
**跨层实锤**: 本批发现 3 个 bug 根源在 domain/data 层、表现于 pages 层, 一并列明调用点。

---

## 发现表

| # | 文件:行号 | 严重性 | 修复难度 | 优先级 | 类型 | 描述 | 建议 |
|---|---|---|---|---|---|---|---|
| 1 | `domain/logic/assessment_record.dart:83-84` ↔ `core/data/repositories/assessment/assessment_repository_impl.dart:62-67`; 表现于 `pages/assessment/assessment_page.dart:279-296` / `pages/assessment/assessment_history_page.dart:43-45` / `domain/logic/day_detail.dart:243-256` / `pages/assessment/assessment_widgets.dart:51-101` | **P1 bug** | 低 | P1 | 底层 | **R90 写 `score`/`answers` 键, `AssessmentRecord.tryFromEntity` 只读 `total`/`scores` → 评估历史列表/对比上次/结果页 sparkline/趋势图表 对 round 91 之后所有评估 total 恒 0、scores 恒空** (R113 新发现 #9 "总分恒 0" 未闭环)。对照 `assessment_dao.dart:112` 已做 `score ?? total` 双读, 说明 domain 侧漏修 | `tryFromEntity` 双读 `json['score'] ?? json['total']` + `json['answers'] ?? json['scores']`; 加 v6→R90 混合 fixture round-trip 测试 |
| 2 | `pages/home/widgets/vent_hero_card.dart:26-30` + `core/data/repositories/vent/vent_repository_impl.dart:59-66` | **P1 隐私** | 低 | P1 | 底层 | **树洞封存内容泄漏**: 用户撤回树洞同意选"加密封存"后, 首页 VentHeroCard 仍显示最新树洞 contentText 预览 — `ventEntriesProvider` 直连 `watchAll()` (无 consent gate, gate 只在 `add`/delete 查), 且不 watch `ventSealedProvider` (vent_list_page 有 gate, home 没有)。PIPL §47 封存语义破坏 + legal_page 文案"UI 隐藏"不实 | VentHeroCard watch `ventSealedProvider` (同 vent_list_page.dart:61,84-86 模式, sealed → 不显示预览); 或 repo `watchAll` 注入 gate |
| 3 | `pages/medication/widgets/medication_row.dart:173-181` + `pages/medication/widgets/medications_list_widget.dart:112-156` | **P1 bug** | 低 | P1 | 底层 | **R113 BUG 7b 同款未修**: 用药 swipe 删除失败时 Dismissible 已 dismiss 但仍留在树 — key 无失败计数 (`ValueKey('medication-${med.id}')`), `_swipeDeleteMedication` catch 只弹 snackbar 不换 key 不 invalidate → DB 未删、条目仍在 `widget.meds` → 下次 rebuild 抛 "A dismissed Dismissible widget is still part of the tree"。R113 修了 vent_list/treatment, 漏 medication_row (任务提示的"找同类") | 照抄 vent_list_page.dart:307-314 的 key 失败计数方案 + catch 里换 key + invalidate `medicationsProvider` |
| 4 | `domain/logic/day_detail.dart:369-392` + `pages/trend/widgets/trend_day_detail_card.dart:46-57` | **P1 i18n** | 低 | P1 | 底层 | **趋势日历 8 新量表裸 scaleId**: `_scaleName` default 分支原样返 `scaleId` ("isi"/"pss"/"level2_depression"...), UI 只注入 phq9Name/gad7Name 2 个 closure → 8 个 R90 量表在趋势日详情直接显示裸 id (R113 新发现 #9 未闭环) | `_scaleName` default 走 `scale_registry.scaleById(scaleId)?.displayName ?? scaleId`, 或 UI 注入全量表 label closure |
| 5 | `pages/vent/vent_list_page.dart:584-594` | **P1 bug** | 低 | P1 | 底层 | **长按删除路径无 try/catch/ok 检查** (R113 BUG 7 只修了 swipe 路径): `_confirmDelete` 里 `await repo.delete(entry.id)` 裸 await — delete 抛异常 = unhandled async error + 无用户反馈 + 条目留存; `onUndo: () async { await repo.restore(entry); }` 也无 catch | 同 swipe 路径模式: try/catch + swallowError + 失败 snackbar + `ok==false` 时 invalidate 刷新 |
| 6 | `pages/vent/vent_detail_page.dart:232` | P1 bug | 低 | P1 | 底层 | `_delete` 中 `await ref.read(ventRepositoryProvider).delete(entry.id)` 裸 await 无 try/catch — 删除失败 = unhandled async error + 页面停留无提示; 且详情页删除无 Undo (列表页有, 体验不一致) | try/catch + AppSnackBar.showError; 可选对齐 Undo |
| 7 | `pages/mood/widgets/mood_audio_recorder_widget.dart:245,283` | **P2 隐私** | 低 | P2 | 底层 | **E-01 只修一半**: `stopRecordingImpl`(245) / `startPlaybackImpl`(283) 在 await (`stopRecording`/`decryptToTemp`) 之后仍 `ref.read(moodAudioStorageProvider)` — unmount 后抛 StateError 被 mixin catch 吞 → `result.plainPath` 明文临时文件永不加密/永不删除 (PIPL §28); `_storageField` 已存在 (cleanupTempFile 用了) 这两处没换 | 两处改 `_storageField!`; 或加密前置到 await 之前 |
| 8 | `pages/worry/worry_timeline_page.dart:212-218,221-227,256-260` | P1 bug | 低 | P2 | 底层 | `_resolve`/`_reopen`/`_rename` 三个 repo 调用全部裸 await 无 try/catch — DB 失败 = unhandled async error + UI 无反馈 (resolve 失败后烦恼卡在 open 态静默) | 统一 try/catch + AppSnackBar.showError (本页已在用裸 ScaffoldMessenger, 顺带换 AppSnackBar 集中器) |
| 9 | `pages/home/controllers/home_deep_link_handler.dart:196-201` + `app_zh.arb:926` | P1 i18n | 低 | P2 | 底层 | **deep link 提示显示裸数据库 id**: `showMedicationHint` 直接 `homeMedHint(medId)` → 用户看到 "💊 准备打卡药物 #5" (autofire 路径 165-173 已从 provider 解析药名, showHint 路径漏) | 同 autofire: `ref.read(medicationsProvider).value` 查名, 找不到再 fallback |
| 10 | `pages/setup/setup_page_state.dart:159-162` + `core/data/services/setup_committer.dart:33` | P2 bug | 中 | P2 | 底层 | **完成页可返回 → 重复提交**: `SetupStepDone(onBack: () => _step = 2)` — 用户从 done 返回用药步再按完成 → `completeSetup` 无幂等 guard, 重复插入药物 + 重复写 consent 留痕 | done 页禁 back (onBack 置 null) 或 SetupCommitter 加 setup 已完成 guard |
| 11 | `pages/settings/widgets/data_management_section/widgets/import_tile.dart:207` | P2 bug | 低 | P2 | 底层 | `await widget.service.importFromJson(input)` 无 try/catch — service 抛异常 (非返回 failure) 时 `_importing` 永真, 导入按钮永久 loading, unhandled async error | try/catch 包裹 + 失败 setState(_importing=false) + showError |
| 12 | `pages/trend/trend_page.dart:66-72` | P3 隐私 | 低 | P3 | 底层 | **analytics 撤回数据 flash**: `legalConsentWithdrawnProvider(analytics).value` 加载期为 null → `?? false` 走正常趋势渲染 — 撤回 analytics 的用户在 SP 读取完成前短暂看到趋势数据 (PIPL §14 语义边界) | loading 期渲染 loading 而非数据; orElse 默认 true 偏安全 |
| 13 | `pages/mood_list/mood_review_page.dart:183-184` | P3 i18n | 低 | P3 | 底层 | **EM-21 同类残留**: `s.topInfluenceFactors` Chip 直接 `Text(f)` 上屏 raw 值 — 存量中文数据在 en locale 显示中文 (mood_detail/mood_factor_analysis 已走 `influenceFactorL10nLabel`, 此页漏) | `influenceFactorNormalizeKey(f)` + `influenceFactorL10nLabel(l10n, key)` |
| 14 | `pages/mood/widgets/mood_audio_recorder_widget.dart:374,503-513` | P3 死代码 | 低 | P3 | 底层 | **`if (isRecording && maxReached)` 永假**: `_audioDurationMs` 只在 stopRecordingImpl 后赋值 (264), 录音中恒 null → "moodAudioMaxReached" 提示永不显示, 3min 自动停发生时用户看不到解释 | 由 service recordingElapsed 实时判断 (`service.recordingElapsed >= 3min`) |
| 15 | `pages/mood_list/mood_trend_page.dart:20-27,66,105` | P3 i18n | 低 | P3 | 底层 | 时间范围标签 `'7D'/'30D'/'6M'/'1Y'` 硬编码英文 (zh locale 也显示英文); `error: Center(child: Text('$e'))` 裸错误无 i18n 无 retry | 标签走 ARB; error 走 ErrorState 集中器 |
| 16 | `pages/home/home_page_state.dart:412-418` | P3 | 低 | P3 | 底层 | **Wave 7 漏修**: `_nextReminderTime()` 仍在 build 内 `DateTime.now()` — 跨午夜 footer "下次提醒" 时间 stale 到次日 (其余 5 处已改 todayProvider) | `ref.watch(todayProvider)` 传入 |
| 17 | `pages/daily_tracking/widgets/tracking_item_card.dart:269-272` | P3 | 低 | P3 | 底层 | **Wave 7 漏修 2**: `_moodLastValue` 的 `_isToday` 内部 `DateTime.now()` — 跨午夜 mood 卡"上次记录: 今天" stale | watch todayProvider 传入 |
| 18 | `pages/mood_list/widgets/mood_list_item.dart:114-117` | P3 i18n | 低 | P3 | 底层 | 时间戳 `MM-DD HH:mm` 无年份 — 跨年条目日期歧义 | 加年份 (老条目无年份显示时加) |
| 19 | `pages/worry/worry_timeline_page.dart:175` | P3 i18n | 低 | P3 | 底层 | `e.note ?? e.tags.join('、')` 硬编码中文顿号分隔符 (en locale 混入中文标点) | join 走 locale 分隔符或 ARB |
| 20 | `pages/medication/medication_detail_page.dart:231-236` | P3 导航 | 低 | P3 | 底层 | loading/error 分支用裸 `Scaffold` (无 AppBar) — 宽屏/iPad 无返回按钮, 错误态无法退出 | 换 PageScaffold + ErrorState(retry) |
| 21 | `pages/mood_list/mood_detail_page.dart:68-71` | P3 | 低 | P3 | 底层 | `error: Center(child: Text('$e'))` 裸错误字符串 + 无重试 (同页 loading 有 PageScaffold, error 没有) | ErrorState 集中器 |
| 22 | `pages/settings/legal_page.dart:479-487` | P3 死代码 | 低 | P3 | 底层 | `clearLegalConsentCache` 测试/调试 helper 定义在生产页面文件 (0 生产 caller) | 移 test/ 或标 @visibleForTesting |
| 23 | `pages/vent/vent_compose_page.dart:501-520` | P3 死代码 | 低 | P3 | 底层 | `stopAndCleanup` top-level helper 0 runtime caller (仅 round48 test) — mixin asyncDisposeAudio 已内建同样逻辑 | 删或改由 mixin 调用 |
| 24 | `pages/daily_tracking/widgets/tracking_item_card.dart:350-390` | P3 死代码 | 低 | P3 | 底层 | `TrackingCategoryHeader` R112 ALS 化后 0 caller (daily_tracking_page 只剩注释引用) | 删 |
| 25 | `pages/medication/medication_calendar_page.dart:192-203` | P3 | 低 | P3 | 底层 | 切换时间窗口 (7/30/90) 后 `_selectedDate` 可能落新窗口外, DayDetail 仍显示旧日期 | 窗口变化时校验/清 `_selectedDate` |
| 26 | `pages/medication/widgets/medication_calendar_day_detail.dart:136-137` | P3 i18n | 低 | P3 | 底层 | 未知药名 fallback `'?'` 硬编码上屏 (药已删但打卡保留时) | ARB key (deletedMedication fallback) |
| 27 | `pages/assessment/assessment_history_page.dart:119` | P3 | 低 | P3 | 底层 | 空态 CTA `context.push('/assessment/phq9')` 绕过 `phqGad7I18nEnabled` gate — PHQ-9 在量表中心被隐藏, 此入口仍直达答题页 (gate 语义不一致) | gate false 时 push 第一个开放量表或 /assessment-center |
| 28 | `pages/daily_tracking/widgets/sleep_widgets.dart:104-116` | P3 | 低 | P3 | 底层 | `_SleepEntryTile` 不显示每条睡眠记录的日期 — 多天记录列表无法区分 (仅 bedtime/wakeTime) | subtitle 加日期 |
| 29 | `pages/mood/widgets/mood_recorder_page.dart:77-82` | P3 | 低 | P3 | 底层 | `MoodRecorderPage.show(context, ref)` 的 `ref` 参数 unused; 且静态入口无法传 `initialWorryThreadId` (路由版可以) — home 两个入口 (mood_hero_card.dart:57,94) 记录的心情永不带烦恼绑定 | 删 unused ref; show 加可选 worryThreadId 透传 |
| 30 | `pages/mood/widgets/status_phrase_field.dart:89-92` | P3 | 低 | P3 | 底层 | "全部" 展开后 toggle 按钮文案仍显示"显示全部" (无"收起"态) | 展开态换 `moodStatusPhraseShowLess` 或同 key 带参数 |
| 31 | `pages/medication/widgets/medication_row.dart:196` + `pages/medication/refill_manage_page.dart:101` | P3 | 低 | P3 | 底层 | build 内 `DateTime.now()` (refill 相对天数) 跨 midnight stale — Wave 7 未覆盖 medication 域 | watch todayProvider |
| 32 | `pages/settings/widgets/reminder_cards.dart:206` | P3 导航 | 低 | P3 | 底层 | 用药提醒卡 "管理用药" 动作 push `/settings` (设置页) 而非 `/medication` — 文案与跳转目标不符 | push('/medication') |

---

## PRIVACY violations (按严重性排序)

1. **[P1] 树洞封存内容在首页泄漏** (#2) — VentHeroCard 直读未加 gate 的 `ventEntriesProvider`, 用户撤回树洞同意(加密封存)后首页仍显示最新树洞文字预览。PIPL §47 封存语义破坏, legal_page 承诺"UI 隐藏"不实。**这是本批最重要的隐私发现。**
2. **[P2] 明文录音临时文件可能永不删除** (#7) — mood 录音停止路径 post-async-gap `ref.read` 被吞后, `result.plainPath` 明文 m4a 残留 temp (PIPL §28, E-01 同类未修干净)。
3. **[P3] analytics 撤回后数据短暂可见** (#12) — trend_page consent 检查加载期默认放行。
4. **[P3] 评估通知/树洞以外无新锁屏 PII**: notification_status_card `_showDetails` 弹窗显示 pending 通知 body (含药名) — 仅在用户主动打开的应用内弹窗, 非锁屏, 但可顺带复核; 未发现树洞内容进趋势/通知 (隐私边界保持)。

## Top 10 bugs (优先级 + 难度 + 位置)

1. **P1/低** — 评估 total 恒 0 + scores 恒空: `domain/logic/assessment_record.dart:83` 读 `total` 但 R90 写 `score` (历史/对比/趋势全坏)
2. **P1/低** — 首页树洞封存泄漏: `pages/home/widgets/vent_hero_card.dart:26` 未走 sealed gate
3. **P1/低** — 用药 Dismissible 删除失败炸树: `pages/medication/widgets/medication_row.dart:174` key 无失败计数 (BUG 7b 漏修)
4. **P1/低** — 趋势日历裸 scaleId: `domain/logic/day_detail.dart:381` 8 新量表 default 返原 id (R113 #9 未闭环)
5. **P1/低** — vent 长按删除/详情删除裸 await 无 catch: `vent_list_page.dart:585` + `vent_detail_page.dart:232`
6. **P2/低** — deep link 提示显示裸 medId "#5": `home_deep_link_handler.dart:199`
7. **P2/低** — worry 三动作裸 await 无 catch: `worry_timeline_page.dart:212/222/257`
8. **P2/低** — mood 录音明文 temp 泄漏残留: `mood_audio_recorder_widget.dart:245,283` 仍 ref.read (E-01 半修)
9. **P2/中** — setup done 页可返回重提交重复药物: `setup_page_state.dart:160` + SetupCommitter 无幂等
10. **P2/低** — 导入无 try/catch 卡死 loading: `import_tile.dart:207`

## 统计

- **发现总数: 32** (P1×6 / P2×6 / P3×20; 底层 31 + 架构 1)
- 严重性: P1 bug 6 (其中 2 个是 R113 已报未闭环: #1/#4), P2 6, P3 20
- 类型: 底层 31, 架构 (SetupCommitter 幂等设计缺口) 1
- 修复难度: 低 30 / 中 2 / 高 0 — 本批无"高"难度, 全部是局部修复, 1-2 天可闭环
- 已修干净的领域: settings 4 group 壳 / tips 页 / crisis_hotline / assessment_quiz_panel / vent widgets / setup wizard 壳 / mood tags & period field
- 未覆盖到根因的跨层项: #1 (domain 解析器), #4 (domain scale 名) — 建议下批优先
