# 项目审计汇总报告 (standard skill · 2026-08-16)

> 审计日期 2026-08-16 · 技术栈 Flutter 3.41.9 / Dart 3.12.2 · 平台 iOS + Android (+web 开发用) · 版本 1.1.0+149 · 规范版本见 .opencode/standards/manifest.md
> 团队: 10 并行子代理 (6 视角 + 4 底层分批) · 基线 = R113 修复战役终态 (2407 test / 0 fail / 1 skip, 21 守门员全绿)

## 一、问题总览

| 优先级 | 类型 | 难度 | 视角 | 问题摘要 | 位置 |
|---|---|---|---|---|---|
| P0 | 底层 | 低 | onshelf | privacy/support URL [PENDING_DOMAIN] 占位 ×6 | fastlane/metadata/ios/*/privacy_url.txt 等 |
| P0 | 底层 | 低 | onshelf | review_information 4 占位 | fastlane/metadata/ios/review_information/*.txt |
| P0 | 底层 | 低 | onshelf | iOS 0 截图 / Android 67B 空白截图 ×8 | fastlane/metadata/*/ |
| P0 | 底层 | 高 | onshelf | ICP 备案 + 软著缺失 (国内商店硬门槛) | 外部资质 |
| P0 | 架构 | 低 | gdc | 工程闭环 vs 用户闭环脱节 — 上架第一步 7 天未启动 | 项目决策层 |
| P1 | 底层 | 低 | onshelf | 隐私政策联系邮箱「待启用」占位 | assets/legal/privacy_policy.md:134 |
| P1 | 底层 | 低 | 底层批1 | 20:00 打卡提醒 payload `check-in/today` 无 resolver case 点击死链 (R113 BUG4 同款) | medication_notifier.dart:84 |
| P1 | 底层 | 低 | 底层批1+04 | 录音取消/dispose 不删明文 temp m4a — PIPL §28 (多视角共识, 取严) | mood_audio_service.dart:341 + audio_lifecycle.dart:520 |
| P1 | 底层 | 低 | 底层批2+4 | 评估历史/趋势总分恒 0 — R90 写 `score`/`answers`, 读取只认 `total`/`scores` (R112 E9 实锤未闭环) | assessment_record.dart:83 |
| P1 | 底层 | 低 | 底层批2+4 | 8 新量表趋势日详情显示裸 scaleId | day_detail.dart:381 |
| P1 | 底层 | 低 | 底层批4 | 首页树洞预览读未 gate 流 — 封存后仍泄漏 (PIPL §47) | vent_hero_card.dart:26 |
| P1 | 底层 | 低 | 底层批4 | medication_row Dismissible key 无失败计数 (R113 BUG 7b 同类漏修) | medication_row.dart:174 |
| P1 | 底层 | 低 | 底层批4 | vent 长按/详情删除裸 await 无 try/catch | vent_list_page.dart:585 / vent_detail_page.dart:232 |
| P1 | 架构 | 中 | apple-design+emil | mood 主流程 0 ALS + Material Dialog (产品第一路径, 跨期) | mood_recorder_page.dart |
| P1 | 架构 | 中 | apple-design | 3 个 CustomTransitionPage 无 iOS swipe-back | app_routes.dart:49-109 |
| P2 | 底层 | 中 | 02-code | R112 ALS 化把 builder 列表改 eager ListView(children) 长列表无虚拟化 | mood_list_page.dart:151 / vent_list_page.dart:286 |
| P2 | 架构 | 中 | 02-code | god class 仍 20 个 ≥400L, import_entities 664L 等 3 个真 god class | import_entities.dart 等 |
| P2 | 底层 | 低 | emil+apple | tab 切换 3 类 transition 混用 (vent slide-up 400ms 全屏 modal 感) | app_route_vent.dart:24 |
| P2 | 底层 | 低 | 底层批1 | snooze 硬编码 exactAllowWhileIdle 绕过降级策略 | snooze_manager.dart:120 |
| P2 | 底层 | 低 | 底层批1 | medication/refill cancel 带互杀 | reminder_dispatcher.dart:75 |
| P2 | 底层 | 中 | 底层批1 | watchToday DAO 跨 midnight 窗口冻结 (根源未修) | check_in_dao.dart:63 |
| P2 | 底层 | 低 | 底层批2 | mood 事件中文 fallback 无 override — en locale 看中文 | day_detail.dart:271 |
| P2 | 底层 | 低 | 底层批2 | 当月打卡率分母用整月天数 — 依从率系统性偏低 | trend_calculator.dart:135 |
| P2 | 底层 | 低 | 底层批2 | date_utils 注释称避 DST 但实现用 inDays | date_utils.dart:19 |
| P2 | 底层 | 低 | 底层批3 | provider `.value ?? const []` 吞 error — DB 失败静默空列表 | cbt_rerated_entries_provider.dart:28 |
| P2 | 底层 | 低 | 底层批4 | 通知点击提示显示裸 db id "#5" 而非药名 | home_deep_link_handler.dart:199 |
| P2 | 底层 | 中 | 底层批4 | done 页可返回重提交, completeSetup 无幂等 — 重复药物+重复 consent | setup_page_state.dart:160 |
| P2 | 底层 | 中 | 04 | DB key 失配 (Android 备份恢复) 无恢复路径卡死启动 | database_migration.dart:39 |
| P2 | 底层 | 低 | 04 | fl_chart 图表 0 Semantics (全 lib 仅 17 处) | mood_trend_page.dart |
| P2 | 底层 | 低 | apple | StatCard 大数字无 tabularFigures 抖动 / tile 固定尺寸 Dynamic Type 挤压 | stat_card.dart:94 |
| P3 | 底层 | 低 | 多视角 | 死代码: uuid 依赖 / MoodQuickButton / flutter_dotenv load 不用 / gentle+bouncy spring / encryptionServiceProvider / windowSizeOf | 多文件 |
| P3 | 底层 | 低 | 多视角 | 注释漂移 / magic spacing 4 处 / build>80 行 39 文件 / trailing comma 15 处 / dynamic 3 处 / AES-CBC 无 HMAC / 对比度 [待人工] | 多文件 |

完整明细: .opencode/audit/01~13 各报告 (6 视角 + 4 底层分批 + 本汇总)。

## 二、按优先级排序的修复清单

### P0（紧急 — 全部为上架阻塞 + 1 项决策级）

- [ ] [底层] 难度:低 — privacy/support URL 占位 ×6（`.opencode/audit/01-onshelf.md` §URL）
  - 来源: onshelf-01 · 规范: appstore 5.1.1 / googleplay 数据安全 · 建议: 注册 chroniccare.app + ICP → 一次替换 6 文件
- [ ] [底层] 难度:低 — review_information 4 占位 · 建议: 域名后建 dev@ 邮箱 + 真实姓名/电话
- [ ] [底层] 难度:低 — iOS 0 截图 / Android 67B 空白截图 · 建议: 设计师出图 (phone 4-8 + tablet 2)
- [ ] [底层] 难度:高 — ICP 备案 + 软著（国内商店）· 建议: 用户启动备案流程 (7-20d), 软著代办
- [ ] [架构] 难度:低 — **工程闭环 vs 用户闭环脱节**（gdc 主矛盾判定）· 建议: 今天注册域名 (5 分钟) + 本周 sideload APK 给 10 个真实用户, 用留存数据替代第 11 轮审计

### P1（高 — 合规残留 + 功能 bug, 合计 ~2d）

- [ ] [底层] 难度:低 — 隐私政策邮箱「待启用」占位 → 注册邮箱后替换（assets/legal/privacy_policy.md:134 + 其他 2 文档同步）
- [ ] [底层] 难度:低 — `check-in/today` 死链: medication_notifier.dart:84 payload 与 notification_deep_link_resolver 对齐 (R113 BUG4 同款修法 + 单测)
- [ ] [底层] 难度:低 — 录音明文 temp 清理: mood_audio_service stopRecording/cancelRecording/dispose 全路径 deleteTempFile (PIPL §28)
- [ ] [底层] 难度:低 — 评估总分 0: AssessmentRecord.tryFromEntity 兼容 `score`/`answers` key + 回归测试 (R90 写入格式)
- [ ] [底层] 难度:低 — 裸 scaleId: day_detail._scaleName 接受 closure, caller 传 scaleById(id)?.displayName
- [ ] [底层] 难度:低 — vent_hero_card 封存 gate: 预览流 watch sealed 状态, 封存后不显示内容
- [ ] [底层] 难度:低 — medication_row Dismissible key 加失败计数 (R113 BUG 7b 同款 key rotation)
- [ ] [底层] 难度:低 — vent 删除路径 try/catch + swallowError (2 处)
- [ ] [架构] 难度:中 — mood 主流程 ALS 化: recorder dialog 3 段 + 72pt 评分按钮 (2-3d, 跨期 P1)
- [ ] [架构] 难度:中 — CustomTransitionPage 加 iOS swipe-back (CupertinoPageTransitionsBuilder 或手势检测)

### P2（中 — 数据正确性 + 一致性, ~1-2d）

- [ ] [底层] 难度:中 — eager ListView 改 builder (mood_list/vent_list 2 处, 高收益)
- [ ] [架构] 难度:中 — import_entities 664L 拆 _importDailyTracking (R113 已预留 seam)
- [ ] [底层] 难度:低 — tab 过渡统一 fade (app_route_vent slide-up → fade)
- [ ] [底层] 难度:低 — snooze 走 dispatcher exact flag (R113 遗留)
- [ ] [底层] 难度:低 — cancel 带互杀: reschedule 单侧时保留另一类 id 段
- [ ] [底层] 难度:中 — watchToday 跨 midnight: 挂 midnight invalidate 或流内 now 重算
- [ ] [底层] 难度:低 — day_detail mood 事件 override 注入 (与裸 scaleId 同批)
- [ ] [底层] 难度:低 — 打卡率分母: 用 elapsing days 或窗口内起算日
- [ ] [底层] 难度:低 — date_utils inDays → calendarDaysBetween (DST)
- [ ] [底层] 难度:低 — provider 吞 error: `.value ?? []` → AsyncValue.when 或 hasError 传播
- [ ] [底层] 难度:低 — home_deep_link_handler 药名代替裸 id
- [ ] [底层] 难度:中 — completeSetup 幂等: done 页禁返回 + repo upsert
- [ ] [底层] 难度:中 — DB key 失配恢复路径: 检测失配引导"重置本地数据"确认流
- [ ] [底层] 难度:低 — fl_chart Semantics (aria 等价)
- [ ] [底层] 难度:低 — StatCard tabularFigures + tile textScaler 挤压

### P3（低 — 卫生/可选, 汇总见各报告）

- 死代码清理: uuid 依赖 / MoodQuickButton + todayMoodProvider / flutter_dotenv / gentle+bouncy spring / encryptionServiceProvider / windowSizeOf / slide_up.dart
- 注释漂移 / magic spacing (mood_hero_card 4 处) / build>80 行 39 文件 / 15 处 trailing comma + 1 dangling doc / export_schema 3 处 dynamic / AES-CBC 无 HMAC (v1.0 换 GCM) / page_scaffold title! 无条件构建 / loading_text_button spinner 色

## 三、上架 / 架构 / 重构 / 半成品专项检查

- **上架**: 3 商店均"未就绪"; 代码面 9.5/10, 阻塞 100% 外部依赖 (URL/截图/review 信息/ICP/软著/console 表单)。Android INTERNET 权限理由过期、release_notes 宣传已删 contacts 功能 (P1, 30min 可修)。
- **架构**: gdc 实锤健康 (双路审计), 不构成矛盾。唯一真 god class = import_entities 664L。feature-first / pub workspace 维持"不做"判定。
- **半成品**: spring gentle/bouncy 死代码、hairlineDivider 未落地、mood ALS 0 化、reduce-transparency 假代理、SF Symbol 0 (均 P2-P3, 非阻塞)。

## 四、顶层架构审视

- **更优架构建议**: 无。4 层 + core umbrella 对 90K LOC 零云端 App 足够; 结论与 R112/R113 一致。
- **可重构模块 (高内聚低耦合)**:
  1. import_entities.dart 664L → 拆 _importDailyTracking (已预留 seam)
  2. mood_recorder_page 主流程 ALS 化 (交互层, 非结构层)
  3. 通知 payload ↔ resolver 对齐 (medication_notifier / deep_link_resolver 单向依赖)

## 五、底层逐行排查汇总

- 可优化点: 33 项 P3 (死代码 8 / 注释与 token 漂移 / 性能微项)
- 需修复 Bug: P1×9 (明细见 §二) + P2×16 (明细见 §二)

## 六、决策审计（gdc 视角）

- **主要矛盾**: 工程闭环 vs 用户闭环脱节 — 10 天 10+ 轮审计、上架第一步 (域名注册 5 分钟) 7 天未启动、App 0 真实用户。上架只是显性阻塞, 被主矛盾锁死。
- **选型合理性**: 技术栈全成立; 21 守门员"修而不增"有仪式化风险; 8 张新量表无用户可见入口却背三重债务, 建议砍留。
- **聚焦/知止**: 审计循环该停; 免费化决策悬空 (README vs WHITEPAPER 矛盾) 需裁决。
- **反证条件**: ① 注册域名 + sideload 10 用户后 2 周留存 <20% → 情绪优先定位假设错, 需回滚评估; ② 第 3 个月无上架实质进展 → 审计循环坐实为拖延机制, 停审。

## 七、规范状态

- 使用规范: .opencode/standards/ (appstore/googleplay/cn-android-stores/flutter-code/architecture/manifest, 2026-08-16 生成)
- googleplay / cn-android-stores 为知识库生成, `[待人工核验]`; appstore 联网获取; flutter-code/architecture 与项目现状配套。
- 需更新: 无 (首次生成)。下次审计前人工复核 googleplay/cn 两份。
