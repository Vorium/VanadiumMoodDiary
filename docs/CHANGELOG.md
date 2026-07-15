# 变更日志

> 格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

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
