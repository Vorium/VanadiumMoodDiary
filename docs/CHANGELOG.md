# 变更日志

> 格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

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
