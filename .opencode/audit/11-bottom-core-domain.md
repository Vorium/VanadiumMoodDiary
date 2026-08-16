# 批次 2/4 — 底层逐行 bug-hunt 报告: core/shared + core/theme + core/routing + core/l10n + domain

日期: 2026-08-16 · 范围: 134 文件 (8 shared + 8 theme + 13 routing + 1 l10n + 24 entities + 16 repositories + 4 usecases + 40 logic) · 方法: glob 后逐文件完整读取 + 关键断言 grep 实锤 (0 代码修改)

---

## 发现表

| # | 文件:行号 | 严重性 | 修复难度 | 优先级 | 类型 | 描述 | 建议 |
|---|---|---|---|---|---|---|---|
| 1 | `lib/domain/logic/assessment_record.dart:83` (+ `lib/core/data/repositories/assessment/assessment_repository_impl.dart:63`) | 高 | 低 | P1 | 底层 | **量表中心提交的评估在趋势日历显示"总分 0"** — R113 报告第 9 项"未闭环"实锤。`AssessmentRepositoryImpl.submitEntry` 写 note JSON 用 `'score'` key, 而 `AssessmentRecord.tryFromEntity` 只读 `json['total'] as int? ?? 0` → 经量表中心 (R90 路径, 含 8 个新量表 + 新入口 phq9/gad7) 提交的所有评估, `day_detail` 展示的总分恒为 0。数据层 `assessment_dao.dart:112` 已双 key 兼容 (`score ?? total`), 只有 domain 这个解析器漏 | `total = (json['total'] as int?) ?? (json['score'] as int?) ?? 0`, 加 case test 锁定两种 key 格式 |
| 2 | `lib/domain/logic/day_detail.dart:369-392` | 中 | 低 | P1 | 底层 | **趋势日历 8 新量表事件标题显示裸 scaleId** (如 "pss" / "whodas")。`_scaleName` 只认 phq9/gad7 (default 分支 `return scaleId`), 而唯一生产 caller `trend_day_detail_card.dart:46-57` 只传 `phq9Name`/`gad7Name` 2 个 closure, 8 个新量表无 closure → raw id 上屏 (R112 E9 / R113 #9 同源, 仍未闭环) | 把 8 个新量表纳入 closure 注入 (或 `scaleNameL10n` helper), 加全 id 覆盖 + `isNot(id)` 断言测试 (R111 裸 id 回归同款修法) |
| 3 | `lib/core/theme/app_spacing.dart:181-185` | 低 | 低 | P2 | 架构+底层 | **`windowSizeOf` 死代码 + 逻辑错误**: `breakpointMedium == breakpointExpanded == 840` (同值), 于是 `width < 840 → compact; width < 840 → medium` — medium 档**永远不可达**, 600-840px (手机横屏/小平板) 被误判 compact。且全 lib 0 caller (grep 实锤: 仅定义 + app_tokens re-export) — 死代码带着隐藏 bug | 要么删 (0 caller), 要么修: `width < 600 → compact; width < 840 → medium; else expanded` (M3 标准三档) + 单测 |
| 4 | `lib/domain/logic/day_detail.dart:271` (+ `lib/core/shared/mood_visual.dart:76` + `lib/core/l10n/strings.dart:253-263`) | 中 | 低 | P2 | 底层 | **趋势日历情绪事件 title/subtitle 在 en locale 显示中文** ("😄 很好" / "总分 2" 中文后缀)。`MoodVisual.labelFor` → `Strings.moodLabel` 中文 fallback, 无 override 参数可注入; `Strings.dayDetailTotalScore` 同理。R112 EM-21 只修了 presentation 3 处硬编码, domain 侧这条路径漏网 | `DayDetailCalculator.fromData` 加 `moodLabelFn`/`totalScoreFn` closure 注入 (跟既有 `checkInLabel` 模式一致), 让 trend_day_detail_card 传 l10n |
| 5 | `lib/domain/logic/trend_calculator.dart:131-144` | 低 | 低 | P2 | 底层 | **当月打卡率分母用整月天数** — `totalDays = nextMonth.difference(m).inDays` 对当前月 (i=0) 返回完整月长 (如 8 月=31), 但 checkedDays 最多只到今天 → 当月依从率**系统性偏低** (8/16 时上限 16/31=52%), 柱状图首柱永久偏低 | 当前月 `totalDays = today.day` (已过天数), 历史月保留整月; 加跨月 case test |
| 6 | `lib/domain/logic/date_utils.dart:16-20` (+ `streak_calculator.dart:70`, `trend_calculator.dart:104,169-170`) | 低 | 低 | P2 | 底层 | **`difference().inDays` 用于本地午夜 → DST 假中断**。注释声称"不直接用 Duration.inDays 因为 DST", 但实现恰恰用 inDays: DST 春季调表日两相邻本地午夜只差 23h → `inDays == 0` → streak 误断、日历 heatmap 差一格 (中国无 DST 不触发, 海外/香港用户踩) | 用 `DateTime.utc(y,m,d)` 归一化后相减, 或 `isSameCalendarDay` 逐日步进; 补 DST case test |
| 7 | `lib/domain/logic/medication_page_stats_calculator.dart:97` | 低 | 低 | P3 | 底层 | **`refillAlertCount` 内部直接 `DateTime.now()`** — 违反本类自身"0 副作用/now 注入"纪律 (buildTimeSlots 接收 now 参数, 同一 build 内两处"今天"可能跨 midnight 不一致), 也踩 AGENTS "DateTime.now() 多次调用 race" 已知坑 | 加 `DateTime now` 参数, caller 与 buildTimeSlots 复用同一次 now |
| 8 | `lib/core/routing/app_route_check_in.dart:19-20` | 低 | 低 | P3 | 底层 | **redirect 把 URL 参数原样注入 query string** — `/check-in/medication/:id` 的 `medId` 未校验/未 URL-encode 直接拼 `'/?medId=$medId&autofire=1'`, 恶意 payload (如 `1%26key=value`) 可注入额外 query 参数 | `int.tryParse` 校验 + 用 Uri 构造, 非法值跳 `/` 不带参数 |
| 9 | `lib/core/theme/app_colors.dart:463-472` | 低 | 低 | P3 | 架构 | **`healthMetricsIds` 含已删 feature 的 'contact'** (1.1.0 round 4 外联删除后 contact 页已整摘) — 死 metric id; 同时 'sleep' 标注"R1 暂未接入"。`kMedicationPillColors` 注释"6 元素"与 usage 需同步核对 | 删 'contact' (保留 palette 位宽或整体重排), 更新注释 |
| 10 | `lib/domain/usecases/schedule_assessment_reminder.dart:39-50` | 低 | 低 | P3 | 架构 | **`resolveFireTime` 0 caller 死 API** (grep 实锤, 文件注释自认"无人引用") — 纯透传 policy 的 static 方法, 留着只会误导 caller 绕过 usecase 主入口 | 删掉 (policy 可直接 import), 或删注释中的自我矛盾说明 |
| 11 | `lib/domain/entities/tracking_item_config.dart:168-182` | 低 | 低 | P3 | 底层 | **`TrackingConfigPersistence.decode` 无容错** — prefs JSON 损坏 (`jsonDecode` 抛 / 类型不符 `as List` 抛) → 崩溃; 未知 id fallback 拿第一个 defaults 的 mood 配置但**保留未知 id** → ghost 条目混入列表 | decode 包 try/catch 返空 map + 未知 id 直接跳过 (或入灰名单); 补损坏 JSON case test |
| 12 | `lib/core/shared/swallow_error.dart:30-31` | 低 | 低 | P3 | 底层 | **web release 不静默** — `dart.vm.product` 在 web 平台恒 false → release web build 仍 `developer.log` 全部 swallowError (项目支持 web 部署: `flutter build web` + http.server 是官方 dev 路径) | 用 `kReleaseMode` (foundation) 或 `identical(0, 0.0)` 双平台 release 检测; web 发布前必改 |
| 13 | `lib/domain/logic/chinese_holidays.dart:27-89` | 低 | 低 | P3 | 底层 | **节假日表 2026-2030 硬编码, 2031+ 全空** — 2031-01-01 起 `isHoliday` 恒 false, 续方提醒不再避节假/春节 (长期静默退化, 无失败提示) | 顶部加"数据过期检查" (date > 2030-12-31 → dev log 警告) 或每年 release 前人工更新 + 守门员年份断言 |
| 14 | `lib/domain/entities/scale_translations/static_scale_translations.dart` (785L) | 低 | 高 | P3 | 架构 | **8 新量表 items/options/severity 全走中文 const fallback, `AppLocalizationsScaleTranslations` 无 1 处 runtime caller** (grep 实锤) — en/zh_Hant 用户做 ISI/PSS/WHODAS 等看到中文题目+选项 (R51b 已知 backlog, 但"0 runtime caller"意味着接入工作量被低估) | 属 v1.0 R51b 既定计划, 本批仅登记; 短期可先给 8 量表 name/shortDesc 接 scaleNameL10n 已完成的路径 |
| 15 | `lib/domain/logic/streak_calculator.dart:97-98` | 低 | 低 | P3 | 底层 | `shouldShowStreakBroken` 语义 = ">=24h 没打卡" 而非注释声称的"今天还没打卡" — 36h 宽限期内 (24-36h) 会同时显示"streak 未断"+"少 1 次没关系"提示, 文案矛盾 | 对齐语义: 要么改用 calendar day 判断 (昨天没打卡), 要么改注释/文案 |
| 16 | `lib/core/shared/consent_gate.dart:68-71` | 低 | 低 | P3 | 底层 | `SharedPrefsConsentGate.isWithdrawn` 每次 `SharedPreferences.getInstance()` (async 开销 × 每次 vent add) — 高频路径 (树洞每次保存都查) | 单例缓存 prefs 实例或注入; 非正确性 bug, 性能项 |
| 17 | `lib/domain/logic/assessment_comparison.dart:179` | 低 | 低 | P3 | 底层 | `severityRankFor` 未知量表兜底 `(total / 5).floor().clamp(0, 4)` — 与 `severityLabelFor` 的兜底 (`Strings.assessmentSeverityRank`) 输出语义错位 (rank vs 中文标签) | 未知量表是防御路径, 但两个兜底不一致 → 统一或删兜底走 throw (registry 已覆盖 10 量表) |
| 18 | `lib/core/routing/notification_navigation.dart:66-72` | 低 | 低 | P3 | 底层 | `handleTap` 对 payload 解析 2 次 (`resolveNotificationDeepLinkRoute` + `NotificationDeepLink.parse`), 且 `resolve` 返回 null 时 `onLink` 不更新 — 调试埋点漏事件 | 解析 1 次复用; 或接受 (性能可忽略), 仅登记 |

**已核对无 bug 区** (抽验): 10 个量表 severity cutoffs 升序 + totalRange 正确 (phq9 4/9/14/19/27, gad7 4/9/14/21, isi 7/14/21/28, pss 13/26/40, whodas 4/9/15/24/48, asrm 0/5/10/15/20, level2×4 一致); PSS 反向计分 index {3,4,6,7} 正确; SleepCalculator 圆形统计 (Mardia) 数学正确; MedicationTimeSlot 4 时段覆盖 0-23 无 gap; 路由注册 0 duplicate、/worry/archive 顺序修复生效、/assessment/history 在 :id 前; worry 死路由 R113 修复已落地 (app_route_worry.dart 顺序对调); ConsentGate key 与 legal_page/consent_preference_store 三方 `legal_consent_withdrawn_` 前缀一致; RecordCheckInUseCase 事务顺序合理; JsonCodec 容错完备。

---

## Top 10 Bugs

1. **[P1 / 低] `lib/domain/logic/assessment_record.dart:83`** — 量表中心写的 note 用 `'score'` key, 这里只读 `'total'` → 趋势日历评估事件"总分 0" (R113 #9 实锤未闭环; DAO 已兼容, 只漏 domain 解析器)
2. **[P1 / 低] `lib/domain/logic/day_detail.dart:381,390`** — 8 新量表无 closure 注入 → 趋势日历显示裸 scaleId ("pss") (R112 E9 残留)
3. **[P2 / 低] `lib/core/theme/app_spacing.dart:181`** — `windowSizeOf` 死代码 + breakpointMedium==breakpointExpanded==840 → medium 档永远不可达, 600-840px 误判 compact (0 caller)
4. **[P2 / 低] `lib/domain/logic/day_detail.dart:271`** — mood 事件走中文 fallback 无 override → en locale 趋势日历看中文 ("😄 很好"), R112 EM-21 domain 侧漏网
5. **[P2 / 低] `lib/domain/logic/trend_calculator.dart:135`** — 当月打卡率分母用整月天数 → 当月柱状图依从率系统性偏低
6. **[P2 / 低] `lib/domain/logic/date_utils.dart:19`** — 注释宣称避 DST, 实现仍 `difference().inDays` → DST 区 23h 午夜差=0 天, streak 假断/heatmap 差格 (海外用户)
7. **[P3 / 低] `lib/domain/logic/medication_page_stats_calculator.dart:97`** — `refillAlertCount` 内部 `DateTime.now()` 违反 now 注入纪律, build 期两次取"今天"跨 midnight race
8. **[P3 / 低] `lib/core/routing/app_route_check_in.dart:20`** — medId 原样拼 query string, URL 注入额外参数
9. **[P3 / 低] `lib/core/theme/app_colors.dart:463`** — `healthMetricsIds` 含已删 feature 的 'contact' 死 id
10. **[P3 / 低] `lib/domain/entities/tracking_item_config.dart:168`** — decode 无 try/catch, prefs JSON 损坏即崩溃 + 未知 id 生成 ghost 条目

**总发现数: 18** (P1×2 / P2×4 / P3×12) · 其中 2 项是 R112/R113 报告条目"宣称已闭环/待闭环"的实锤复核 (发现 1、2), 其余 16 项为本批新发现。
