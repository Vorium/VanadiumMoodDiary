# v1.1.0 Round 10 九视角综合审视 (2026-08-16, 并行 subagent 只读审计)

> 日期 2026-08-16 · 基线 `f9f4e2b5` (1.1.0 round 8c, working tree = round 9 未 commit) · 版本 1.1.0+149 · schemaVersion 24 · 9 个并行 subagent (emil / superpowers / flutter-audit / gdc / AppStore / GooglePlay / AppleHealth + 2 路底层逐行)

## 评分总览

| 视角 | 评分 | 一句话 |
|---|---|---|
| emil 设计工程 | 7.5/10 | token+动效基建一流, 但主页入场动画每次 tab 切换整栈重播 + _EntrySpring 无视 reduce-motion |
| superpowers 流程 | 7.0/10 | "21 守门员全绿"不可复现 (2 红 + 1 工具缺失 + 1 skip), 5 守门员不在 CI, F1 UI 0 测试 |
| flutter-audit 规范 | 8.7/10 | 全库最接近规范; 0 致命, god class 反涨 931L, PDF 硬编码中文 + 守门员文件级豁免盲区 |
| gdc 顶层架构 | 架构健康 | 4 层 + core umbrella 足够, R112 六大架构债全闭环, 唯一真 god class = export_import_pipeline 931L |
| AppStore | 5.5/10 | 代码面 ~9/10 达提交水准; 3 硬闸门 100% 外部 (截图 0 / 域名 ICP / review 信息) |
| GooglePlay | 6.0/10 | 外联全链删除干净, 权限 6 个全在用, 锁屏 secret 全绿; 截图 67B 占位 + 域名 URL 占位 |
| Apple Health 视觉 | 8.0/10 | 13 页 9 个 ALS 化; mood 主流程 0 ALS (定位翻转后是 #1 路径) + spec 数字漂移 |
| Apple Health HealthKit | 0/10 (合规 10/10) | 集成 = 0 by design, 五处声明全一致, 无假声明风险 |
| 底层逐行 presentation | 22 发现 | 2 P1 (worry 路由遮蔽 / 打卡失败仍庆祝) + 0 隐私违规 |
| 底层逐行 core+domain | 21 发现 | 3 P1 (requestPermission 恒 true / mood-diary 通知无反应 / 漏服日期在开药前) + 0 隐私违规 |

**加权综合 ≈ 7.2/10** (代码面已高质量, 上架外部闸门 + 少量 P1 功能 bug 拉低)

## 1. 外部链接隐藏确认 (核心要求 #1) — ✅ 100% 干净

AppStore + GooglePlay 双视角独立实锤: 外联业务 (SMS / Email / 紧急联系人 / 失联 SafetyWatch / 5 厂商 push / FCM / 阿里云 / SendGrid) 代码、数据表、UI、ARB、权限全链删除。

| 外联功能 | 状态 | 残留 (全部非功能级) |
|---|---|---|
| SMS / 阿里云 SMS | ✅ 0 活代码, 0 SEND_SMS/RECEIVE_SMS 权限 | 删除注释 3 处 |
| Email / SendGrid | ✅ 0 活代码 | 注释 2 处 |
| 紧急联系人 / contacts 表 | ✅ 表 + DAO + repo + 路由全删 | 注释 + 3 处 ARB 文案残留 |
| 失联 SafetyWatch / CareEngine | ✅ 整摘 | 注释 4 处 |
| 5 厂商 push / FCM | ✅ 0 SDK, flag=false | — |
| tel: 危机热线 | ✅ 合法保留 (静态, 0 CALL_PHONE) | 保留 |
| http(s) UI 外链 | ✅ lib 0 命中 | — |

**残留文案 4 处 (P1-P3, 非功能, 需清理)**:
- **P1**: `fastlane/metadata/ios/en-US/release_notes.txt:1` 仍提 "(medications, mood entries, **contacts**)" + Android 14+ 内容混入 iOS 笔记
- **P2**: `app_zh.arb:121` / `app_en.arb:90` "删除全部…/contacts" 描述已删功能 (用户可见)
- **P2**: `app_en.arb:1019` example 元数据含 "emergency contacts"
- **P3**: `android/.../BootReceiver.kt` 死文件 (未注册 manifest, 不生效)

## 2. 上架阻塞 (核心要求 #2) — 与 R112 一致, 100% 外部依赖

| # | 阻塞 | 平台 | 谁动 |
|---|---|---|---|
| L1 | **截图 0 张 / 67B 空白占位** | 双平台 | 设计师 (2-3d) — 唯一纯资产闸门 |
| L2 | **chroniccare.app 域名未注册 + ICP (7-20d)** | 双平台 | 域名商 — privacy/support URL 6 处占位, 前置一切 |
| L3 | review_information 4 占位 | iOS | 域名后填真实信息 |
| L4 | 5.1.3 Health 问卷 | iOS | 提交周人工填 (草稿已在 SUBMISSION_INFO §2.5.3) |
| L5 | Console 4 表单 (Data Safety / Health / Permissions / 删除) | Android | 人工填 (生成器已备 build/) |
| L6 | 首次 release build + 16KB .so 实测 | Android | 本机 SDK 已就绪, ~1d |
| L7 | keystore 密码备份 1Password | Android | 用户 |
| L8 | 律师签字法务文档 | 双平台 | 律师 (1-2wk) |

**代码侧唯一红色项 (30min 可修)**: notes.txt 版本 1.1.0+148 滞后 pubspec 1.1.0+149 → `check_review_information_todo.py` FAIL。

## 3. 顶层架构审视 (核心要求 #3) — gdc 视角

**Verdict: 当前 4 层 + core umbrella 架构足够, 是本项目历史最健康状态。架构重构不是优先级。**

实测验证 R112 六大架构债全闭环: AR-16 (data→ARB) ✅ / AR-17 (scale 死代码 1,600L 删) ✅ / AR-18 (4 usecase 全活) ✅ / AR-19 (saveSetup 下沉 setup_committer) ✅ / ARCH-01 (ConsentPreferenceStore) ✅ / ARCH-02 (deep link resolver 落 domain) ✅。`check_all.dart` 纯度+一致性双 PASS, 跨 feature 152 文件 0 violation。

**唯一真 god class (P1, 1-1.5d)**: `export_import_pipeline.dart` 931L — 数据完整性脊柱, E6/E8 级 bug 全藏这里。拆 3 实体簇文件 (import_profile / import_entities / import_vent)。

**19 个 ≥400L 文件仅 1 个真 god class** (其余 = 页面规模/数据表, 拆解边际收益递减)。**明确不做**: feature-first 重构 ❌ / pub workspace ❌ / usecase 层厚化 ❌ / 追拆全部大文件 ❌。

## 4. 底层逐行发现 (核心要求 #4) — 汇总表

### P0 (0 项) / P1 (10 项, 合计 ~7h)

| # | 文件:行号 | 类型(架构/底层) | 难度 | 描述 | 建议 |
|---|---|---|---|---|---|
| P1-1 | `scripts/check_review_information_todo.py` + `fastlane/metadata/ios/review_information/notes.txt` | 底层 | S (2min) | notes.txt 1.1.0+148 != pubspec 1.1.0+149, 守门员 FAIL, "21 全绿"声明为假 | 同步版本; 立规则"写全绿前实跑" |
| P1-2 | `core/routing/app_route_worry.dart:11-19` + `widgets/worry_section.dart:63-67` | 底层 | S (0.5h) | **/worry/archive 被 /worry/:id 遮蔽成死路由** (go_router first-match-wins 实锤) → "忆往昔"入口打开 threadId=0 永远转圈 | literal 在前 param 在后; timeline 加 EmptyState |
| P1-3 | `home_page_state.dart:357-369` | 底层 | S (0.5h) | 打卡失败也弹成功庆祝 + streak+1 文案 (错误 snackbar 与庆祝同时) | 读 notifier state 有 error 则只 snackbar |
| P1-4 | `core/data/services/notification_initializer.dart:129-142` | 底层 | S (0.1h) | **requestPermission() 恒返 true** (`iosOk ?? true \|\| androidOk ?? true`) — 拒绝权限后引导路径永不触发 | 平台分支 return iosOk ?? false |
| P1-5 | `mood_reminder_notifier.dart:70` + `notification_deep_link_resolver.dart:35-51` | 底层 | S (0.2h) | **情绪提醒通知点击完全无反应**: payload `chroniccare://mood-diary` 无 resolver case | 加 case 返回 /mood-diary + 单测 |
| P1-6 | `domain/logic/medication_stat_calculator.dart:117-124` | 底层 | M (0.5h) | **漏服日期全部落在开药之前** (今天加的药 14 天报告显示"今天-13 天漏服") | build 加 effectiveStart 参数 + mid-window 回归测试 |
| P1-7 | `lib/core/data/services/export/export_import_pipeline.dart:1-931` | 架构 | M (1-1.5d) | 全库唯一真 god class, 6 段 import + 兼容层, E6 教训所在 | 拆 3 实体簇文件 + 每簇 round-trip test |
| P1-8 | test/presentation/pages/worry/ 仅 1 文件 | 底层 | M (1d) | F1 烦恼闭环 3 条 UI 路径 0 测试 (archive 页 / selector 3 分支 / query 绑定 / 保存新建链路) — 空列表 override 掩盖 | 补 4 widget test |
| P1-9 | `mood/` 全目录 AppleListSection = 0 | 架构 | XL (2-3d) | 1.1.0 情绪优先定位后 mood 是 #1 路径却唯一 0 ALS feature + 48pt 按钮 (spec §5.5 要 72pt + spring) | recorder 3 段 ALS + 72pt 评分按钮 |
| P1-10 | `app_route_main.dart:51-77` + `home_page_state.dart:262,279,309` | 架构 | M (2-4h) | 主页入场动画每次 tab 切换整栈重播 (~650ms 动画堆叠, 10+/day) | StatefulShellRoute 保活 或 首帧门控 |
| P1-11 | `check_in_button.dart:229-281` (_EntrySpring) + `medication_page.dart:330` | 底层 | S (1h) | 唯一未接 reduce-motion 的动画 (物理弹簧) + 打卡 AnimatedSwitcher 绕过 Motion | disableAnimations 归零 + Motion wrapper + PressFeedback |
| P1-12 | `cbt_thought_record_pdf_layout.dart:92` + `check_strings_hardcoded.py:88-92` | 底层 | S (1h) | PDF 导出硬编码中文 "CBT 7/5 栏" + 守门员文件头含 "i18n" 整文件豁免盲区 | 走 l10n getter; 豁免改逐行精确 token |
| P1-13 | `medication_list_cell.dart:96` + `medication_detail_page.dart:158` | 底层 | S (0.2h) | 2 处 AppColors.success (2.4:1) 作文字色, WCAG 不达标 (EM-16b 漏网) | 换 fgOnSuccess #2E7D32 |
| P1-14 | `assessment_notifier.dart:75,96` → strings.dart:105 | 底层 | S (15min) | 评估提醒 body 含量表名 "PHQ9" — iOS 锁屏横幅可见 PII (守门员只守 title 不守 body) | body 去量表名 或 扩守门员规则 |

### P2 (核心, 按收益排序)

| # | 文件:行号 | 类型 | 难度 | 描述 |
|---|---|---|---|---|
| P2-1 | `tracking_item_card.dart:254-258` | 底层 | S (0.5h) | mood 卡"上次记录"无条件显示"今天" (上周数据也说今天) |
| P2-2 | `vent_detail_page.dart:133` | 底层 | S (0.5h) | _togglePlay catch 路径绕过 _storage 缓存用 ref.read — unmount 后明文 temp 泄漏 |
| P2-3 | `mood_recorder_page.dart:216-224` | 底层 | M (1h) | 新建烦恼在保存前执行 — 保存失败留孤儿烦恼主题 |
| P2-4 | `vent_list_page.dart:324-338` + `treatment_list.dart:74-76` | 底层 | S (1h) | Dismissible fire-and-forget 删除无 try/catch, treatment 无 undo |
| P2-5 | `medication_page.dart:321-329` | 底层 | S (0.5h) | 直接打卡失败静默无反馈 (error 进 notifier 但本页无 listener) |
| P2-6 | `mood_trend_page.dart:211-219` | 底层 | S (0.5h) | 无数据日画 y=0 坠底, 视觉像 0 分抑郁日 |
| P2-7 | 5 处 (mood_trend:211 / vent_list:521 / daily_tracking:171 / assessment_center_card:106 / mood_review:96) | 底层 | S (2h) | build 内 DateTime.now() 不 watch dayChangeTick — 跨 midnight stale |
| P2-8 | `assessment_history_page.dart:73-102` | 底层 | M (2h) | 历史页只分组 phq9/gad7, 其余 8 量表记录永不显示 |
| P2-9 | `app_route_assessment.dart:9-33` + `assessment_center_page.dart:47-49` | 底层 | S (0.5h) | phqGad7I18nEnabled 假 gate — 中心页隐藏但 3 条路由全通 (审核风险) |
| P2-10 | 4 处 ListView(children) (vent/mood/medication/worry) | 底层 | M (4h) | 非懒加载全量构建 (mood 条目按年数千) |
| P2-11 | `worry_timeline_page.dart:44-49` | 底层 | S (0.5h) | thread==null 无限 spinner, 无 not-found 态 |
| P2-12 | `legal_page.dart:118` | 底层 | S (0.5h) | vent withdraw 在 try 块外 — 失败 unhandled |
| P2-13 | `export_import_pipeline.dart:200-205` | 底层 | S (0.2h) | profile 导入被 userName 空值整体跳过 → PIPL §14 留痕 4 字段丢失 |
| P2-14 | `export_import_pipeline.dart:352-359` + `refill_scheduler.dart:63` | 底层 | S (0.2h) | import 允许 refillReminderDays=0 → scheduler 抛 → 全部续方提醒静默中止 |
| P2-15 | `snooze_manager.dart:120` | 底层 | S (0.2h) | snooze 硬编码 exactAllowWhileIdle, 绕过降级策略 (Android 13+ 撤回权限后不可靠) |
| P2-16 | `day_detail.dart:371-394` + `trend_day_detail_card.dart:51-56` | 底层 | S (0.3h) | 趋势日历 8 新量表显示裸 scaleId + 总分恒 0 (R112 E9 未闭环: tryFromEntity 只读 total 但 R90 写 score) |
| P2-17 | `asrm.dart:69-114` | 底层 | M (需临床) | ASRM ≥6 是公认阈值但代码 rank>=2 (≥10) 才建议就医 — 6-9 分漏躁狂警示 |
| P2-18 | `medication_page_stats_calculator.dart:44-69` | 底层 | S (0.2h) | 时段打卡"已服"为药级粒度, 时段卡信息失真 |
| P2-19 | `.github/workflows/ci.yml` 缺 5 守门员 + format gate 红 142 文件 | 架构 | S (1h) | CI 只跑 16/21; check_coverage 不在 CI (lcov 缺失, 覆盖率守门实际关着) |
| P2-20 | `check_datetime_race.py` / `check_16kb_alignment.py` 无 exit | 底层 | S (1h) | 2 个守门员永不红 / 16KB 从不验证产物 |
| P2-21 | `check_pii_in_title.py` 只守 2/5 title | 底层 | S (1d) | 锁屏 PII 守门不完整 |
| P2-22 | domain 预设内容 (标签 8 + 短语 17 + 鼓励 5) 硬编码中文 | 架构 | M (1-2d) | en/zh_Hant 100% 中文泄漏, 已入 DB+导出 (跨视角共识) |
| P2-23 | `spec.md:320` + `app_typography.dart:40,78` + dividerTheme | 底层 | S (1.5h) | Apple Health spec-code 漂移 4 处 (数字第 3 次漂移 / 2 token 有意偏离无注释 / hairlineDivider 0 实现) |
| P2-24 | `spring.dart:71-84` gentle/bouncy 0 caller | 底层 | S (1h) | Spring 模型大半休眠 (仅 standard 有真 caller) |
| P2-25 | `secondary_button.dart:26-58` | 底层 | S (1h) | 集中器自身无 PressFeedback (当前 caller 恰好外包, 未来新 caller 静默失去反馈) |
| P2-26 | `celebration_bounce.dart:46-58` | 底层 | S (0.5h) | scale(0) 入场 (checklist: start ~0.95+opacity) |
| P2-27 | 法务文档 3 份残留已删功能 (privacy_policy / user_agreement / sensitive_data_consent) | 架构 | S (2-3h + 法务) | 用户签署文档描述已删功能 = 合规级 (跨视角共识, 实际 P0 级) |

### P3 (卫生/低优, 摘要)

| # | 文件 | 类型 | 难度 | 描述 |
|---|---|---|---|---|
| P3-1 | `sleep_widgets.dart:163-169` | 底层 | S (0.5h) | 跨午夜判定错误: 22:00 睡 22:30 起算 30min |
| P3-2 | `mood_quick_button.dart` + MoodFactorAnalysis | 底层 | S (1h) | 死代码 (无 caller) |
| P3-3 | `worry_timeline_page.dart:223` | 底层 | S (10min) | _rename controller 不 dispose |
| P3-4 | `mood_recorder_page.dart:76-81` | 底层 | S (10min) | show() 的 ref 参数未用 |
| P3-5 | `mood_audio_recorder_widget.dart:455-456` | 底层 | S (10min) | _RecordingTimer 不认 serviceFactory 注入 |
| P3-6 | `legal_page.dart:119` + `consent_dialog.dart:103` | 底层 | S (0.5h) | 撤回时间戳本地时间渲染 vs audit log UTC |
| P3-7 | `app_router.dart:85-95` | 底层 | S (10min) | setup 未完成时 /crisis-hotline 不可达 (1.4.1 边缘) |
| P3-8 | `notification_initializer.dart:165-168` | 底层 | S | can ?? true 与注释矛盾 |
| P3-9 | `badge_sync_service.dart:79-86` | 底层 | S | Android 空白常驻通知 (不可划掉) |
| P3-10 | `assessment_comparison.dart:219-222` | 底层 | S | 未来时间戳记录当"当前"基准 |
| P3-11 | `mood_audio_service.dart:299-318` | 底层 | S | stopRecording 失败不清理 temp 明文 |
| P3-12 | `mood_dao.dart:37-54` + `check_in_dao.dart:62-96` | 底层 | M | watchToday 流创建时捕获 now — 跨 midnight 长活 provider 绑定旧日期 |
| P3-13 | `export_orchestrator.dart:105-127` | 底层 | S | 导出无排序, JSON 顺序不稳定 |
| P3-14 | `notification_payload.dart:99` | 底层 | S | malformed deep link → medId 0 → 404 路由 |
| P3-15 | pubspec `uuid` 未使用 | 底层 | S (0.1h) | 删依赖 |
| P3-16 | `app.dart:211` 20:00 硬编码 | 底层 | S (0.2h) | 抽常量 + 注释 |
| P3-17 | `worry_section.dart:64` 裸 fontSize 14 | 底层 | S (0.1h) | 走 token |
| P3-18 | `export_schema_service.dart` 6 处 dynamic | 底层 | S (0.5h) | 收窄 Object? |
| P3-19 | 6 文件 16-18 层嵌套 | 底层 | S (0.5h) | 拆 1-2 个子 widget |
| P3-20 | `slide_up.dart` 0 caller | 底层 | S (0.5h) | 死代码 |
| P3-21 | `mood_hero_card.dart:80,85,90` magic 间距 4 处 | 底层 | S (10min) | 走 token |
| P3-22 | 142 文件未格式化 (format gate 红) | 底层 | S (0.5h) | dart format + dart fix --apply |
| P3-23 | `scale_strings_arb_lock_in_round95_test.dart` 937L 182 条 info | 底层 | M (2h) | 抽生成器脚本产出 |
| P3-24 | `safetyCheckResultDisabled` ARB key 3 语死残留 (测试续命) | 底层 | S (0.5h) | 删 key + orphan 检查加 --prod-only |
| P3-25 | 7 文件命名不符 {module}_{roundN} | 底层 | S (0.5h) | 1.1.0 起用高位 round 号 |
| P3-26 | `check_all.dart` firstMatch 只检第 1 个 Entity | 底层 | S (0.5h) | 改 allMatches |
| P3-27 | `check_zh_hant_consistency.py` 需 OpenCC (exit 2) | 底层 | S (10min) | CI 装依赖 |
| P3-28 | 锁屏/状态色对比度 dark mode 6 处 [待人工] | 底层 | — | 真机/工具确认 |
| P3-29 | fl_chart 9 文件真机性能 [待人工] | 底层 | — | 低端机型 60fps 实测 |
| P3-30 | AppShell tab 切换页面状态重建 (滚动/录音) [待人工] | 底层 | — | 真机验证 vent 录音切 tab |

## 5. 开发需求文档更新 (核心要求 #5)

按本轮发现, 开发需求文档 (AGENTS.md / README.md / docs) 更新要点:
1. **AGENTS.md**: 新增本节 (v1.1.0 round 10 综合审视) + 修正"21 守门员全绿"为实测状态 (17 绿 / 2 红 / 1 工具缺失 / 1 skip) + notes.txt 同步 + "写全绿前必实跑"
2. **README.md**: 测试数实测 2338 pass / 0 fail / 1 skip
3. **CHANGELOG**: 补 [1.1.0+149] 条目 + 去掉 "0 warning" 不实宣称 (219 info)
4. **上架文档**: DEPLOYMENT.md §8.2 外联规划段标注已删除 (round 8b 已同步, 复核)

## 修复顺序建议 (R113 计划)

1. **wave 1 (30min)**: P1-1 notes.txt 版本 + P2-23 spec 数字 + 文档同步 → 守门员转绿
2. **wave 2 (~2h)**: P1-2~P1-6, P1-11, P1-13, P1-14 (8 个 S 级功能 bug)
3. **wave 3 (~2h)**: P1-12 PDF i18n + 守门员豁免盲区; P2-1~P2-6, P2-12 (S 级 UI bug)
4. **wave 4 (~2d)**: P2-19/20/21 守门员收口 (CI 5 个 + exit + 产物验证) + P2-22 domain i18n 四路合一
5. **wave 5 (1-1.5d)**: P1-7 export_import_pipeline 拆 3 文件 (最后真 god class)
6. **wave 6 (1d)**: P1-8 F1 烦恼闭环 UI 测试补全
7. **wave 7 (2-4h)**: P1-10 主页动画停播 (StatefulShellRoute) + P2-7 跨 midnight stale
8. **长线**: P1-9 mood ALS 化 (2-3d) + P2-27 法务文档 (外部) + 上架外部闸门 (域名→资产→keystore→console→review)
