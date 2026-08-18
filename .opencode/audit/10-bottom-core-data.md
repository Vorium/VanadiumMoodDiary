# 批次 1/4 — lib/core/data/ 底层逐行 bug-hunt 报告

**范围**: `lib/core/data/` 97 文件 (database/ + repositories/ + services/ + privacy/ + utils/ + feature_flags.dart)
**方法**: 全量逐行精读 (跳过 `app_database.g.dart` 生成文件 1 个), 与 AGENTS.md 已知 bug 模式 (DateTime race / 隐式排序 / 通知 id 区间 / 资源泄漏 / StreamSubscription) + R113 修复账本逐项交叉验证。
**日期**: 2026-08-16 | 基线: 1.1.0+149, schemaVersion 24, export v7, 2407 tests pass。

## 总体结论

R113 修复战役质量整体扎实 — 迁移链守卫、export v7 全 12 表覆盖、通知 PII 清理、id 固定带 (5M+) 均实锤到位。**本批新发现 15 项**, 其中 **2 个 P1** (1 个是 R113 BUG 4 同款"通知点击死链"漏网, 1 个是明文录音文件泄漏), **4 个 P2**, 9 个 P3。无 P0 (崩溃/数据丢失级)。最值得警惕的是**通知 payload 死链** (每日 20:00 打卡提醒点击无反应) 与**通知 cancel 区间重叠**两个系统性通知问题。

## 发现表

| # | 文件:行号 | 严重性 | 修复难度 | 优先级 | 类型 | 描述 | 建议 |
|---|---|---|---|---|---|---|---|
| 1 | `services/medication_notifier.dart:84` + `services/snooze_manager.dart:111` (vs `domain/logic/notification_deep_link_resolver.dart:37-57`) | P1 (用户可见功能死链) | 低 | P1 | 底层 | 每日 20:00 打卡提醒 payload 用原始字符串 `chroniccare://check-in/today`, 但 resolver 只认 host `today` / `medication` / `assessment` / `mood-diary` — host `check-in` 落 default → null → 点击通知完全无反应。与 R113 BUG 4 (mood-diary 无 case) 同款, 修 mood-diary 时漏了这 2 处 (snooze medId=0 同串)。`NotificationDeepLink.todayCheckIn().encode()` 输出的 `chroniccare://today` 反而无人使用 (仅 parse 内部)。 | 改 payload 为 `chroniccare://today` (或 resolver 加 `case 'check-in'`), 补 lock-in test 断言所有 5 类 payload 都能 resolve |
| 2 | `services/mood_audio_service.dart:341-362, 403-419` | P1 (PIPL §28 明文 PII 残留) | 低 | P1 | 底层/隐私 | `cancelRecording()` 只 `recorder.stop()` + 置 `_tempRecordPath = null`, **从不 delete 明文临时录音文件**; `dispose()` 同样不删。用户录音中途退出页面 (widget dispose → cancelRecording) → 明文 m4a 精神心理患者语音永久留在 `Directory.systemTemp` 直到 OS 碰巧清理。vent_compose_page 同款 (presentation, 本批范围外但同一模式)。 | cancelRecording/dispose 中 `File(_tempRecordPath).delete()` best-effort + audioErrorSink; vent 侧同步修 |
| 3 | `database/app_database.dart:236-249, 348-359` | P2 (新装用户性能退化) | 低 | P2 | 底层 | 6 个查询索引 (`idx_checkin_ts_type` / `idx_mood_ts` / `idx_vent_ts` / `idx_med_active_start` / `idx_checkin_med_id` / `idx_report_gen_at`) 只在 migration 链 `from <= 7/12/13` 块创建, table 类 0 `@TableIndex`。**全新安装 (schemaVersion 24 走 onCreate→createAll) 一个索引都不建** — 注释明确这些索引是为 1+ 年老用户避免全表扫描, 新用户却从 0 开始裸奔。 | 迁移块逻辑原样保留, 同时把 6 索引改为 `@TableIndex` 声明 (createAll 自动建) 或在 onCreate 后跑同一批 `CREATE INDEX IF NOT EXISTS` |
| 4 | `services/snooze_manager.dart:120` | P2 (提醒可靠性) | 低 | P2 | 底层 | `snoozeOnce` 硬编码 `AndroidScheduleMode.exactAllowWhileIdle`, 绕过 `rescheduleAll` 的 `_canScheduleExact()` 降级策略。R113 审视列为 bug #8, wave 2 修了 8 个 bug 但**不含此项** (账本复核: 未修)。Android 13+ 用户撤回 SCHEDULE_EXACT_ALARM 后主提醒走 inexact 兜底, snooze 却静默丢失/延迟。 | SnoozeManager 注入 `bool useExact` (dispatcher.setExactMode 同步) 或直接读 dispatcher 模式 |
| 5 | `services/reminder_dispatcher.dart:75-96` + `medication_notifier.dart:52,114` + `refill_notifier.dart:43,228` | P2 (通知静默丢失) | 低 | P2 | 底层 | medication cancel 带 [2000, 202000) **完全覆盖**所有 refill id (6000+medId); refill cancel 带 [6000, 206000) 覆盖 medication id (2000+medId*10+i, medId ∈ [400, 19999])。`rescheduleAll` 顺序 (med→refill) 自愈, 但: (a) `medications_list_widget.dart:200` 单独调 `rescheduleRefillReminders` → medId ≥ 400 的用药提醒被静默杀死直到下次启动; (b) med-cancel 后 refill-reschedule 中途抛异常 → 全部续方提醒丢失到下次启动。R110 只把固定带迁 5M+, 两个可变带互杀未修。 | 两个 cancel 带分家 (e.g. medication [2000, 202000) / refill 迁 2,100,000+) 或改为按公式精确算 id 再逐个 cancel |
| 6 | `database/daos/check_in_dao.dart:63,82` + `database/daos/mood_dao.dart:38` | P2 (跨 midnight 数据陈旧) | 中 | P2 | 底层 | `watchToday()` / `watchTodayAll()` 在 stream 创建时一次性捕获 `DateTime.now()` 边界。App 跨 00:00 长开, stream 不重建 → "今天"窗口永远停在昨天。R113 wave 7 只修了 presentation 5 处 (todayProvider), DAO 层 stale 根源还在 (riverpod StreamProvider 复用 stream 时触发)。 | 边界时间改为可注入参数或 `Stream` 内每 emit 重算 + 00:00 timer 触发重查; 或 provider 层 midnight invalidate 全覆盖 |
| 7 | `services/encryption_service.dart:66-70` | P3 (静默数据丢失风险) | 低 | P3 | 底层 | `getOrCreateKey()`: SecureStorage 中已有 key 但长度 ≠ 32 (存储损坏) → 直接生成新 key 覆盖 → 所有已加密 vent 文字 / mood+vent 音频 **永久不可解密**, 用户零提示。 | 损坏时抛错 (带指引) 或至少 piiSafeLog 警告 + 不覆盖旧 key (存 backup key name) |
| 8 | `services/swallow_log_sink.dart:86-107` | P3 (日志丢尾) | 低 | P3 | 底层 | `_flush()` 竞态: write 落在"drain 循环结束 → `_pendingFlush = null`"窗口内时, 新 `_flush` await 旧 future 后直接 return, 不再查 queue → 该条目滞留直到下一次 write (若之后无 write = 永久丢失)。 | await 旧 future 后再循环一次 drain; 或 completion 后检查 `_writeQueue.isNotEmpty` 再 flush |
| 9 | `services/snooze_manager.dart:109,136-160` | P3 | 低 | P3 | 底层 | (a) `snoozeOnce` 不调 `_ensureInitialized()` (其余 4 个 notifier 都调), `tz.TZDateTime.now(tz.local)` 在 try 块外 — tz DB 未初始化 (web / init 失败) 时抛异常到 caller; (b) `cancelSnoozeForMedication` / `cancelAllSnoozes` 循环内无 per-cancel try/catch (dispatcher.cancelByIdRange 有) — 单个 PlatformException 中止剩余 cancel。 | 入口 `_ensureInitialized()`; fireAt 计算移入 try; cancel 循环加 try/catch + errorSink |
| 10 | `services/refill_notifier.dart:229,237` | P3 | 低 | P3 | 底层 | `rescheduleRefillReminders` 入口取一次 now 判断 isExpired, 随后 `scheduleRefillReminder` 内部**再取一次 now** 重算 — 批量重排跨 midnight 时两个 now 不一致 → 同一批里个别药"外层未过期/内层已过期"错乱。AGENTS.md 已知模式 (同函数多次 now 已修, 跨函数两次 now 漏网)。 | `scheduleRefillReminder` 加可选 `now` 参数, reschedule 路径复用同一个 now |
| 11 | `services/export/import_shared.dart:14-21` + `import_entities.dart:30` | P3 (UX) | 低 | P3 | 底层 | `ImportResult` 摘要只计 meds/checkIns/reports/moods/vents — worryThreads + 6 张 daily tracking 表 (R112 E6 新导入段) 不计 → 用户导入后看到"已导入 0 条"式不全统计。 | ImportResultBuilder 加 worryCount / trackingCount, summary 拼入 |
| 12 | `repositories/vent/vent_repository_impl.dart:175-185` | P3 | 低 | P3 | 底层 | `deleteAll()` 在**事务外**先 `select` 全部 audioPath 再进事务删行 — 并发 add() 落在这两步之间 → 新条目 audio 文件不删 (DB 已清, 文件变孤儿; 下次启动 purgeOrphanPlainFiles 只清明文不清 .enc)。 | select 移入事务 (跟 delete() 的 TOCTOU 修复同款) |
| 13 | `repositories/user_profile/user_profile_repository_impl.dart:89,129` | P3 (法务) | 低 | P3 | 底层 | `recordConsent` / `resetConsent` 用 `consentRevokedAt: const Value.absent()` — 单行表上重新同意**永不清除** revokedAt, 审计记录永远显示"已撤回" (PIPL §14 留痕语义歧义: 是"保留撤回史"还是"重新同意应清"需法务定调)。 | 法务确认语义; 若"重同意应清"改为显式 `Value(null)` + `update().write` 路径 |
| 14 | `services/mood_audio_service.dart:216-226` | P3 | 低 | P3 | 底层 | `startRecording` 中 `recorder.start()` 抛异常 (mic 被占等) 后 `_tempRecordPath` 已生成但未回滚删除 → 空明文文件残留 (与 #2 同族)。 | start 失败路径 delete temp + 清字段 |
| 15 | `repositories/daily_tracking/treatment_repository_impl.dart:107` + `repositories/assessment/assessment_repository_impl.dart:71` | P3 | 低 | P3 | 底层 | `submitEntry` / `submitEntry` 直接 `DateTime.now()` 单次调用 — 无 race 但与其他 entry 的 `DateTimeResolvers.at()` 注入模式不一致 (测试无法注入时间, 跨 midnight 边界测试不可控)。 | 加可选 `at` 参数走 DateTimeResolvers.at (跟 check_in/vent/mood 一致) |

## PRIVACY violations (专项)

| # | 位置 | 内容 | 严重性 |
|---|---|---|---|
| PRIV-1 | `mood_audio_service.dart:341-419` (+ vent_compose_page 同款) | 录音取消/页面退出后明文 m4a 语音 (精神心理 PII) 永留 systemTemp — PIPL §28 | **P1** |
| PRIV-2 | `encryption_service.dart:66-70` | key 损坏被静默重生成 → 全部加密数据不可逆丢失 (可用性破坏, 非泄漏) | P3 |
| PRIV-3 | `notification_service.dart:196-202` | `_onResponse` piiSafeLog 打印完整 payload (含 scaleId 如 `phq9` — 心理健康量表身份信息, 属边缘 PII; debug-only 故降级) | P3 |

其余隐私边界复核通过: vent 数据 0 泄漏进通知/趋势/日志 (swallowError notes 只带 ventId/moodId); 通知 title/body 全走通用文案 (R108/R113 修复实锤); 导出 JSON 明文为主动用户操作且有二次确认; swallow.log 有 sanitizeForLog 脱敏; export/import 错误文案无 PII (kReleaseMode 守卫)。**无新隐私泄漏路径, 只有 #2 的明文 temp 残留一处**。

## Top 10 bugs (按优先级 + 难度排序)

1. **P1/低** `medication_notifier.dart:84` + `snooze_manager.dart:111` — 每日打卡提醒点击死链 (`check-in` host 无 resolver case, R113 BUG 4 同款漏网)
2. **P1/低** `mood_audio_service.dart:341` — 录音取消/dispose 不删明文临时 m4a, PIPL §28 明文 PII 残留
3. **P2/低** `app_database.dart:236` — 6 个性能索引只在迁移链建, 全新安装用户 0 索引
4. **P2/低** `snooze_manager.dart:120` — snooze 硬编码 exactAllowWhileIdle 绕过降级 (R113 bug #8 未修实锤)
5. **P2/低** `reminder_dispatcher.dart:75` — medication [2000,202000) 与 refill [6000,206000) cancel 带互杀, 单侧 reschedule 静默杀另一类提醒
6. **P2/中** `check_in_dao.dart:63` / `mood_dao.dart:38` — watchToday 跨 midnight 窗口冻结 (DAO 层根源未修)
7. **P3/低** `encryption_service.dart:66` — key 损坏静默重生成 → 加密数据永久不可解密
8. **P3/低** `swallow_log_sink.dart:86` — flush 竞态丢最后一条 release 日志
9. **P3/低** `snooze_manager.dart:109` — snoozeOnce 无 ensureInitialized, tz.local 在 try 外, web/未初始化即抛
10. **P3/低** `vent_repository_impl.dart:176` — deleteAll 事务外读 audioPath, 并发 add 留孤儿加密音频

## 已验证无问题 (高价值项复核)

- 迁移链 schemaVersion 24: 全部列操作有 `_addColumnIfMissing`/`_columnExists` 守卫 (round 8 P3 修复实锤), from<=3/5 老用户 createTable 幂等链闭环
- export v7: 12 张用户数据表全导出 (profile/meds/checkIns/reports/moods/vents/worry/6 tracking), id 重映射 (medIdMap/moodIdMap/worryIdMap) 完整, import clear-before-insert 覆盖全部表
- 通知固定带: assessment 5000001 / mood 5000002 / badge 5000100 全部在 snooze cancel 上界 2,300,000 之上 (R110 B1-1 实锤)
- 无 StreamSubscription 泄漏 (core/data 内 0 个 `StreamSubscription` 字段); Timer 全部有 cancel 路径
- refillReminderDays=0 双端防守 (import clamp 1 + scheduler 返 null) 实锤
- import_profile gate (profile 段存在) + update().write 全量替换语义实锤
- R113 修复的 8 个 S 级 bug 中 7 个在本范围文件内验证通过; snooze (#4 本报告) 为唯一未修项
