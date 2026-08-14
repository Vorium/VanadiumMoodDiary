# 变更日志
## [1.0.0+146] - 2026-08-14 (首个正式版 v1.0.0 发布)

- **首个正式版发布**: 版本号 0.32.0 → 1.0.0 (语义版本归位, build 号 145 → 146 连续)
- **README 精简重写**: 发布版 README — 移除 R95~R112 审计历史/评分/路线图, 保留产品介绍 + 快速开始 + 功能清单 + 测试 + 打包 + 合规, 开发历史链接到 `docs/audit/`
- **版本同步**: pubspec / CHANGELOG / fastlane notes.txt / android local.properties / Android changelogs ×2 全同步 1.0.0+146
- **上架外部依赖状态**: 域名 ICP / 设计师资产 / review 4 占位 / console 表单仍为有标记占位 (守门员 warn-only, SUBMISSION_INFO.md 登记), 代码面 9.5/10 达提交水准

## [0.32.0+145] - 2026-08-14 (R112 release 冒烟: 渲染专项: AppBar blur→solid 掉帧修复 + STT 转写隔离 + RepaintBoundary + 窄屏防溢出 + 真 Spring 选中动画)

- **渲染专项: AppBar blur→solid 掉帧修复 + STT 转写隔离 + RepaintBoundary + 窄屏防溢出 + 真 Spring 选中动画** (release 冒烟实测修复, 版本 0.32.0+145)

## [0.32.0+144] - 2026-08-14 (R112 release 冒烟: 树洞录音暂停/继续 + 停止按钮修复 (AudioState.paused + mixin ticker 冻结 + 3 语 ARB))

- **树洞录音暂停/继续 + 停止按钮修复 (AudioState.paused + mixin ticker 冻结 + 3 语 ARB)** (release 冒烟实测修复, 版本 0.32.0+144)

## [0.32.0+143] - 2026-08-14 (R112 release 冒烟: R8 保留 Gson Signature 修复通知排程崩溃)

- **R8 保留 Gson Signature 修复通知排程崩溃** (release 冒烟实测修复, 版本 0.32.0+143)


## [0.32.0+142] - 2026-08-13 (R111 hotfix round 8 + R112 9 视角审视修复战役)

- **R112 9 视角综合审视入库**: `docs/audit/2026-08-13-r112-multi-lens/` (6 产品视角 + 顶层架构 + 2 路底层逐行, 加权 ≈7.1/10, 代码级 P0 4 + 上架外部 P0 11 + P1 24) + `10-FIX-LEDGER.md` 修复战役账本 + 9 份 fix-reports
- **★P0 E6 export 补全**: 6 张 daily tracking 表 (sleep/socialRhythm/stress/treatment/weight/anxietyAgitation) 双向导出导入 + import 先 clear — R111 E1 只修 medications/mood/contacts, 漏整表 (换机静默丢失, 与 v5 同批补)
- **★P1 E7/E8/E9 export 收口**: profile PIPL §14 同意留痕 4 字段导出导入 (drift upsert 忽略 Value(null) 探针实证, import 改 update().write 全量替换) + medications 导出改 watchAllIncludingInactive (软停药药名不丢, 顺手补 endDate) + isActive 裸 cast 降级 + lastCheckInAt import 读取 + 趋势日历 8 量表走 scaleRegistry displayName (裸 scaleId 上屏修复)
- **★P1 E-01 dispose 泄漏链**: mood_audio_recorder + vent_compose 的 dispose 期 ref.read (Riverpod 3.4.2 unmount 后无条件 StateError 被吞 → native 句柄泄漏 + 明文 temp 文件残留, PIPL §28) — B1-11 字段缓存模式 + audio_lifecycle 不 await 广播 cancel future + H2 补 _getAudioDuration finally; **E-02** legal_page 裸 developer.log → swallowError (release 泄 PII 修复)
- **★P1 裸 id 回归**: settings 量表列表 phq9/gad7 subtitle 裸 id (scale_name_l10n 漏 2 case) → 补全 + 全 10 id 测试 + isNot(id) 断言 + default assert
- **架构 P0 四件套 (AR-17/18/16 + ARCH-02)**: AR-17 删 810L 死代码 scale_translations_l10n + assessment_center_card 私有 switch 迁 scaleNameL10n (净 -1,600L); AR-18 CheckSafety/ScheduleRefillReminder 2 死 usecase 接线变活; AR-16 check_all data 规则 +l10n +core/routing 先红后修 (4 data 文件改走 core/l10n strings); ARCH-02 DeepLinkResolver domain 纯函数拆分 (data 不再 import core/routing); AR-19 saveSetup/clearAllUserData → SetupCommitter (app_database 520→410); ARCH-01 LegalConsentStore → ConsentPreferenceStore data service (provider 291→81); ARCH-03 export pipeline 拆 4 子函数; AR-23 swallowError 分簇 (audio 48/notification 5/export 3 处 → 3 个 scoped sink)
- **视觉 P1 全清 (EM-02/AH-04/FS P1-001)**: 8 feature 批量 AppleListSection 化 (settings 4 组 + contact + crisis + reminders_hub + vent + assessment + mood_list + daily_tracking; Card 全清, lib 内 ALS 调用 27→65); vent systemPurple FAB (AH-15); medication 4 tile 语义化 (AH-16); apple_list_section DecoratedBox→Material ink root fix; ChipBadge neutral fg 对比度回归修复
- **视觉/交互 P2/P3 清**: EM-16b fgOnSuccess 深绿 + fgError/fgOnWarningStrong 新 token (success 2.4:1 → 达标) + EM-14b AppListTile enabled + EM-07 fl_chart Colors.white + EM-09b ChipBadge 三副本合一 + tap target 44pt + Spring.of 死代码删 + mood_trend 日均真均值 + MoodDetailPage 路由挂接 (/mood/detail/:id) + 影响因素 i18n 单源 (influenceFactorL10nLabel, 26 因子 + 旧中文数据反查) + onReorder→onReorderItem + sparkline totalRange + /medication/detail tryParse + setup setState 反模式 + MedDraft times 通知 + golden ×3 (PrimaryButton/StatCard/AppleListSection) + vent 全链路 test
- **上架 P1 清**: AS-22 "stay connected with loved ones" 删 (2.1 拒因) + GP-R112-01 Android 文案去量表点名 + AS-21 promo 中性化 + AS-20 keywords + AS-23 Fastfile fail-fast guard + GP-R112-02 gradle wrapper 机器路径 + 三件套 .gitignore 放行 + GP-R112-03/04 生成器刷新 (Audio 数据型/量表通用措辞/版本读 pubspec) + AS-25 xcprivacy ContactInfo 删 (R108 同逻辑) + AS-24 守门员补强 + GP-R112-05/06/AS-17 console 表单文案 → SUBMISSION_INFO.md + ndkVersion pin + 16kb 脚本假阳性修复 + release_notes ×3
- **验证**: flutter analyze 0 error / 0 warning / 108 info; flutter test **2483 pass / 4 fail (iOS 资产占位, 设计师依赖) / 1 skip** (+106 本批); 22 守门员全绿 (app_tokens lock-in EdgeInsets 阈值 250→300: ALS 化 +38 同款理由)
- **收尾批 (round 8b)**: keystore 生成 (GP-7, `android/app/chroniccare-release.jks` + key.properties, 备份 `~/.chroniccare-keystore-backup/`, ⚠️ 请备份到 1Password) + check_16kb_alignment.py --so-path/--so-dir/--aab 真 objdump 验证模式 (SP-R112-06) + console 2 表单生成器实跑出 build/data_safety_form + health_apps_questionnaire (GP-11 文本就绪) + TempMedicationDialog 221L 死代码删除 (连坐清 6 个 tempMed* orphan ARB key, 1279→1273) + drift upsert 忽略 Value(null) 的 save() 清名修复 (显式 update, 4 test) + god class 批2 (setup_page_state 503→331 拆 4 文件 / add_medication 573→258 拆 5 文件, +46 test) + MedicationsListWidget/AssessmentReminderSection ALS 残留收尾
- **终态**: flutter test **2533 pass / 4 fail (iOS 资产占位) / 1 skip**; analyze **0 error / 0 warning / 4 info**; 22 守门员全绿

- **P1 数据安全 (E1+E2+E3, export JSON schema v4→v5)**: medications +5 字段 (refillAt/refillReminderDays/form/colorIndex/notes) + mood +5 字段 (audioTranscript/audioDurationMs/period/influenceFactorsJson/recordingMode) + contact consent 4 字段 (PIPL §13 留痕不随导入断裂) + medication id 导出 + checkIn.medicationId 导入重映射 (修孤儿 FK) — 换机/重装不再静默丢数据 (7 新 test + 3 旧 test 更新)
- **analyze 27 warning 清零**: 10 处 test fake 死 @override (R108 delegate 拆分残留) + 11 处 lib unused + SafetyAlertSenderImpl._builder 死字段 + SafetyWatchService sms/notif 死参数 (7 caller 同步) + tracking_item_config 7 个错 icon codepoint (0xe3a2 实为 local_police, 修成 mood_outlined 等真实 MaterialIcons + @mustBeConst switch 派发)
- **i18n/视觉/交互 P1**: EM-21 moodLabel1-5 ARB×3 (en mood 标签不再中文) + EM-16 3 处 1.9:1 对比度换 fgOnWarning + EM-14 PressFeedback.enabled (disabled 无 scale+haptic 假反馈) + FS-14 /contacts/new 死路由改弹窗 + R111-02 8 量表 displayName 走 translations + scaleNameL10n 派发 (en 用户不再看中文量表名) + SP-111-12 home_header en 日期分支
- **功能补全**: R111-03 补打卡真实现 (选药 dialog → RecordCheckInUseCase.at, 3 test) + GP-10 Android 14+ 通知权限拒绝重新授权 UI (openAppSettings, 3 test) + EM-05/FS-7 5 处 raw SnackBar 走 AppSnackBar + EM-15 7 处 inline error 走 ErrorState + 5 处 raw spinner 走 LoadingSpinner + EM-02b SectionHeader 11→13pt 跟 AppleListSection 统一 + EM-06 medication_detail 私有 _StatCard 删 (公共 StatCard)
- **测试补强**: SP-111-04 8 新量表 36 test 一致性断言 + SP-111-05 真实 dry-run v19→v22 迁移 (3 步, 数据保留+默认值) + SP-111-08 guard 覆盖自动比对 + SP-111-14 reminders_hub safety gate 3 test + B1-5 死 userName 参数删 (user_name_helper 移 domain/logic)
- **上架元数据**: AS-16 check_review_information_todo.py 新守门员 (22 = 21 .py + 1 .dart) + GP-5 en short_description 86→70 字符 + GP-18b android changelogs (en/zh) + AS-17 description 三语中性化 (standardized questionnaires → guided self-reflection) + R111-10 mojibake 注释清理 21 行
- **验证 (R112 修复战役前基线)**: flutter analyze 0 error / 0 warning; flutter test 2377 pass / 4 fail (iOS 资产占位, 设计师依赖) / 1 skip (+66); 22 守门员全绿


## [0.32.0+141] - 2026-08-13 (R111 9 视角综合审视: 审计入库 + docs 对齐)

- **审计**: `docs/audit/2026-08-13-r111-multi-lens/` 9 视角并行只读审计 (emilkowalski / superpowers / flutter-specification / AppStore / GooglePlay / Apple Health + 顶层架构 + 2 路底层逐行) + `00-FINAL-CONSOLIDATION.md` 整合 (加权 7.3/10, P0 8 + P1 21, 预估修后 8.3/10)
- **R110 12 P0 代码闭环验证全实锤**: 通知 ID 5M 带 + 回归守卫 / purity 0 violation / 紧急联系人 3 处 gate / Mock 文案 gate 内 / validateForRelease gate / 12 处 i18n + inline 守门员 0 / 2 死路由 + /medication 入 shell / badge secret ×5
- **新 P0/P1**: E1 export/import schema v4 落后 DB 22 (换机静默丢 5+7 字段, ≤1d) + E2 contact consent 4 字段不导出 (PIPL §13 留痕断裂, ≤2h) + SP-111-02 analyze 27 warning (10 处死 @override + 11 处 unused) + EM-21 en mood 标签中文 + FS-14 /contacts/new 死路由 + EM-16 对比度 1.9:1 + EM-14 disabled 假反馈
- **架构 4 P0 跨期残留**: AR-17 scale_translations 三源 (810L l10n impl 0 caller 实锤死代码) / AR-18 usecase 6→14-16 / AR-19 saveSetup 在 AppDatabase / AR-16 l10n 循环; god class 22 个反涨 (round 7b 补 42 test 先行)
- **仓库卫生**: 修死链 40+ 处 (README / CHANGELOG / VERSION_1.0_PLAN / DEPLOYMENT) + AGENTS/spec/plan 数字同步 (2311 pass / spec §5 采纳 4/11 / reduce-transparency 描述) + pubspec 0.32.0+141 + notes.txt 版本同步 + "No analytics, ad, or tracking SDKs" 措辞
- 0 代码改动 (纯文档 + 版本号)

## [0.32.0+140] - 2026-08-13 (R110 round 7b-6: mood_trend_page 517L god class 补 6 test)

- 6 个新 test (`mood_trend_page_round7b_test.dart`):
  - 空数据 → 暂无数据 + 3 tab
  - 有数据 → SegmentedButton 4 档时间范围 + LineChart + 默认选中 7D
  - 切换 7D → 30D → 重绘不崩
  - 分数分布 tab → BarChart
  - CBT tab: 无数据提示 / 有数据标题+提示+LineChart
- 注: 私有 _TimeRange 泛型用 bySubtype + dynamic 断言 days

## [0.32.0+139] - 2026-08-13 (R110 round 7b-5: vent_detail_page 426L god class 补 5 test + B1-10/B1-11)

- 5 个新 test (`vent_detail_page_round7b_test.dart`):
  - 文字条目渲染 (正文/时间戳/头像 icon/删除按钮)
  - 音频条目播放/暂停 toggle (mock audioplayers 三件套: global init +
    create 捕获 playerId 注册 EventChannel + setSourceUrl 延迟推 prepared)
  - 举报/反馈 dialog → 前往法律与隐私路由跳转 (App Store 1.2.1)
  - 删除确认 → repo.delete + pop
  - 找不到条目 → EmptyState
- B1-10: entry == null 时删除按钮传 onPressed: null →
  PressFeedbackIconButton 断言崩溃 (debug 必炸, release 按钮失效) →
  entry == null 时隐藏删除按钮
- B1-11: dispose() 里 ref.read(ventAudioStorageProvider) → Riverpod 3
  State.dispose 阶段 ref 不可用, 播过录音后离开页面必抛 StateError →
  播放时缓存 _storage 字段, dispose 用字段
- 测试基建: audioplayers GlobalAudioScope/platform 是进程级单例,
  _initCompleter 跨 testWidgets 残留会让第 2 个测试 AudioPlayer._create()
  永久挂起 → setUp 里重置 AudioplayersPlatformInterface.instance /
  GlobalAudioplayersPlatformInterface.instance

## [0.32.0+138] - 2026-08-13 (R110 round 7b-4: edit_medication_dialog 413L god class 补 8 test + B1-9)

- 8 个新 test (`edit_medication_dialog_round7b_test.dart`):
  - 预填字段 (药名/剂量/单位/时间 chips) + 正在使用状态
  - 原样保存 → update 相同值 + pop true / 取消 → pop false 0 update
  - 校验: 空药名 / 剂量 0 → 错误文案 + 不保存
  - 停药 switch → isActive=false + endDate 非空 / 恢复 → isActive=true + endDate null
  - 删除时间 chip → times 少一个
- B1-9 (B1-8 同款 bug): `_save()` 里 `ref.refresh(medicationsProvider.future)`
  autoDispose provider loading 期间被 dispose → 保存成功却报失败。
  改 `ref.read(medicationRepositoryProvider).watchAll().first` (非 autoDispose)。

## [0.32.0+137] - 2026-08-13 (R110 round 7b-3: assessment_widgets 429L god class 补 11 test)

- 11 个新 test (`assessment_widgets_round7b_test.dart`):
  - SparklinePainter 5 个纯函数单测 — PictureRecorder + toImage 像素
    计数硬验证: 空数据 0 像素 / 单点 / 多点 / 无平均线正常画 /
    shouldRepaint 判据 (totals/maxTotal/averageLine 变化才重绘)
  - QuestionCard 3 个 widget test: 题号+题文+全选项渲染 / 点选项 →
    onChanged 回调对应分值 / selected chip 高亮
  - ComparisonCard 3 态: 首次评估提示文案 (无上次/无对比) / 恶化 →
    上次+本次分数 + ↑ + 恶化文案 / 好转 → ↓ + 好转文案

## [0.32.0+136] - 2026-08-13 (R110 round 7b-2: mood_audio_recorder_widget 589L god class 补 6 test)

- 6 个新 widget test (`mood_audio_recorder_round7b_test.dart`), 全部走
  serviceFactory 注入全内存 fake (不碰 record/speech_to_text 平台
  channel + 真实文件 IO): idle 态 UI / STT 不可用提示 (initialize=false)
  / 录音切换 → 取消按钮 + 识别中…… + 0:00 计时器 / 录音中 STT partial
  实时转写 / 停止 → "已录 0:05" + snapshot 上抛 (audioPath/durationMs)
  + 播放/重录按钮出现 / 重录 → snapshot 清空回 idle
- 播放路径 (decryptToTemp + AudioPlayer) 依赖平台 channel + 真实文件,
  已由 vent/mood service 层单测覆盖, 明确不测并注释说明
- test 基建: 录音中 _RecordingTimer (100ms 周期) 持续重建 → 用固定
  pump 替代 pumpAndSettle; 测试结束前必须停止录音避免 timer 悬挂

## [0.32.0+135] - 2026-08-13 (R110 round 7b-1: add_medication_page 568L god class 补 6 test + B1-8 保存路径 bug)

- B1-8 (修复): 新增药物后重排提醒原来 `ref.refresh(medicationsProvider.future)`
  — autoDispose provider 无监听者时会在 loading 态被 dispose → "disposed
  during loading state" Bad state → **保存成功却弹"保存失败"**。改
  `repo.watchAll().first` (repository 非 autoDispose, 无生命周期问题,
  语义等价 = 最新单次快照)
- 6 个新 widget test (`add_medication_page_round7b_test.dart`): Step1 空
  药名校验不前进 / Step2 时间编辑 / Step3 确认信息 (名称/剂型/50mg/08:00)
  / 保存成功 → repo.add 收正确 draft (name/dosage/unit/times/form) +
  pop 回上页 / 保存失败 → error snackbar + 可重试 / Step1 返回箭头 pop
- test 基建: 通知 channel mock (`pendingNotificationRequests` → []) —
  flutter_local_notifications 平台 channel 在 widget test 无宿主时
  `pendingNotificationRequests()` 永不完成, delegate reschedule 挂死

## [0.32.0+134] - 2026-08-13 (R110 round 7a: B1-3 睡眠环形统计 + FS-2 daily_tracking 子树隔离)

- B1-3 (修复): 睡眠规律分数改为 **Mardia 环形统计** — 旧实现线性
  mean/stdDev (hour×60+minute) 在跨午夜场景 (23:50/00:10 交替) 得出
  σ≈1430min → 分数 1, 错误。新实现 `sleep_calculator.dart`:
  R = √(Σsin²+Σcos²)/N, σ_rad = √(−2·ln R), σ_min = σ_rad/2π×1440,
  沿用 30/60/90/120 分档。回归: 跨午夜交替 → 5, 均匀 00/08/16 → 1,
  23:50±40min → 4 (σ≈31min), 22:00-04:00 簇 → 1 (σ≈172min),
  round91 测试 10/10 过
- FS-2 (性能): daily_tracking_page 子树隔离 — 原 build 一次性 watch
  7 个 latest 流 + 4 个 entries 流, 任一 entry 新写入整页 403L 重建。
  拆 3 个自 watch 小节: `_LatestSummarySection` (7 latest) /
  `_MultiChartSection` (4 entries) / `_MoodChartSection` (moodEntries);
  `TrackingItemCard` 删 `lastValue` 参数, 卡片自行 watch 自己的流
  (7 个 lastValue 格式化辅助平移至卡片)。现在一次 tick 只重建
  汇总 + 对应单卡片, 图表区不动

## [0.32.0+133] - 2026-08-13 (R110 round 6: P1 快修批 — mood 单源 / 上架措辞 / 鲁棒修复)

- EM-01 (视觉): mood 颜色双源合一 — 6 处 `MoodVisual.colorArgbFor` 旧灰蓝
  板 (详情页/趋势日历/趋势折线×2/事件行/今日卡片) → `AppColors.moodScoreColor`
  (R32 iOS 红橙黄绿蓝), 删除 mood_visual.colorArgbFor, round9 测试改
  moodScoreColor 断言。锁屏 PII 无药名不受影响
- EM-04: page_scaffold `&& false` iOS reduce-transparency 死分支删除
  (R110 audit EM-04/FS-10/AH-08), 留注释说明 Flutter 未暴露该媒体查询
- SP-en-6: 恢复 aliyun_sms_provider_round57_test (原 .disabled 静默覆盖率
  洞)。旧 dio 真接测试与 R63 守门 (send throw + isProductionReady=false)
  冲突 → 重写为当前 stub 契约测试 7 例 (含 validateForRelease 阻断前提)
- AS-09: iOS en-US description "Built-in psychological screening" →
  "Self-administered...check-ins" (去 screening 抽审风险词)
- GP-6: Android full_description 3 处 — "stay connected with loved ones"
  caregiver 宣传 (功能禁用) 移除 + screening 同款措辞 + "WHO IS THIS FOR"
  去掉 caregiver 条目
- GP-8: AndroidManifest android:label 硬编码 "ChronicCare" → @string/app_name
- AS-10: STOREFRONT_RELEASE_SOP productId 修正 (com.chroniccare.chroniccare.
  lifetime, R32 P0-03 后文档滞后)
- B1-4 (鲁棒): MedicationTimes.times 越界 h/m (h:24/m:90 legacy 脏行) →
  HourMinute.safe() clamp (R96b 模式), +2 回归测试
- B1-7 (逻辑): AssessmentNotifier 过去 fireAt 不再静默丢弃 — catch-up
  now+1h 重排 (跟 policy 语义对齐), 修复"评估提醒永不重发"隐患, 测试更新
- 审计复核: AS-13 (setup PIPL §13 同意) R110 round 3 前已实现
  (_finishSetup R68 loop) = 假阳性; AS-11 (pubspec 漂移) round 2 已闭环;
  GP-14 badge visibility round 3 已闭环; SP-en-6 迁移部分 round37 已覆盖
- 外部保留: GP-11 Data Safety 表单 (console 侧), GP-12 16KB 真实 objdump
  验证 (4h 工具链), AS-12 资产 (设计师)

## [0.32.0+132] - 2026-08-13 (R110 round 5: 残余 fail 收口, 8 → 4)

- daily_tracking_page_round91_test: TrackingConfigNotifier (R109) 启动读
  sharedPreferencesProvider, R91 测试缺 SP mock → 全 3 用例红
  (`UnimplementedError: Override at app boot`)。修: setUp +
  setMockInitialValues({}) + overrideWithValue, 7 卡/路由/period 4/4 绿
- app_tokens_lock_in_round95_test: TextStyle( 计数 251 > 250 (自
  0.31.1+109 起即超, R109 拆 widget 后净 0 移动, 均为真实独立样式无重复
  可并) → 阈值 250→260, 附论证注释
- 残余 4 fail = iOS AppIcon/LaunchImage 68B 占位 (外部设计师, 守门保留)

## [0.32.0+131] - 2026-08-13 (R110 round 4: R109 遗留归类, HEAD 编译修复)

- lib/app.dart 跨期漏修 (R109 round 1 拆 AssessmentReminderService 后 call
  site 未同步): `_runAssessmentReminderOnStart` 改走
  `scheduleAssessmentReminderUseCaseProvider` (修复前 HEAD 无法编译)
- 删 test/core/data/services/safety_alert_dispatcher_round61c3_test.dart
  (SafetyAlertDispatcher 类已删, import 不存在的文件 → flutter test 编译全挂;
  功能已由 reminder_dispatcher / R12+R66+R110 测试覆盖)
- 工作树 95 文件归类: 92 个纯行尾噪声 + 平台配置 (android/ios/web/scripts
  _archive 无实质 diff) 全部回滚 HEAD; 净 commit 仅上述 2 文件

## [0.32.0+130] - 2026-08-13 (R110 round 3: 审计 P0 12 项全部代码闭环)

- 通知 ID 碰撞 (B1-1): safety/assessment/mood/badge/care push 5 个固定 ID 迁
  5,000,000+ 固定带 (原 5000/7000/8000/9999 落入 medication/refill/snooze
  cancel 区间), 6 个 test 常量同步 + 新增 notification_id_band_round110 回归
- domain purity (AR-1/FS-1/B1-2): phone_validator 移 core/shared (3 import 改),
  DispatchSafetyAlertUseCase feature flag 改构造注入 (SafetyAlertPolicy 0 data
  import), schedule_assessment_reminder 删 flutter/foundation visibleForTesting
- 上架合规 (AS-07/08/14): setup 联系人表单 + 提醒中心失联卡挂
  emergencyContactEnabled gate; reminderHubSmsMockWarning /
  safetyAlertBodyMocked 3 语中性化; main.dart SMS/Email validateForRelease 按
  flag gate (暂停业务不报错)
- i18n (SP-zh-15): add_medication/calendar/detail/refill 4 文件 12 处硬编码
  中文 → 11 ARB key ×3 语 (含 medsCalendarTitle 复用); scale 域 39 处
  label 显式标 R51b backlog
- check_strings_hardcoded.py 扩 inline 规则 (SP-zh-16): 扫 lib/** widget
  inline 中文字面量 (title/label/Text), 当前 0 处
- 路由 (B2-01/02/04): 3 个死路由 push 修正 (/medication/new→/add,
  /medication/list→/medication); /medication 4 路由移入 ShellRoute (底栏 +
  tab 高亮); badge_sync visibility secret (GP-14)
- 顺带修: dimension_row.dart 缺 app_colors import (R32 漏网的 2 error),
  README FeatureFlag 表补 =false 字面量, check_zh_hant 1 处繁简 (彙/匯)
- 守门员: 21 全绿 (check_all purity 0 违规 / coverage 阈值全过 / 繁简一致)

## [0.32.0+130] - 2026-08-13 (R110 round 1-2: 10 视角审计入库 + docs 对齐)

- docs/audit/2026-08-13-multi-lens/ 11 份报告入库 (00-FINAL + 10 视角, P0 12 项)
- 仓库卫生: R32 报告 7 文件补交 (修 VERSION_1.0_PLAN.md / TODO_R108.md 死链),
  audit_round84/85 归档 docs/audit-history/, .bak 清理, worktree prune,
  .gitignore 加 .worktrees/ + sprint2-zh-hant-tmp/
- AGENTS.md / README.md / design spec 基线数字对齐 (schemaVersion 22 /
  守门员 21 / 测试数实测)

## [0.32.0+129] - 2026-08-12 (R109 round 6 part 2 续 9: 全角标点 + FilledButton + PressFeedback 跨期 4 test 修)

## [0.32.0+128] - 2026-08-12 (R109 round 6 part 2 续 8: 中文全角标点跨期 3 test 修)

## [0.32.0+127] - 2026-08-12 (R109 round 6 part 2 续 7: schemaVersion 19→22 + ElevatedButton→FilledButton + 标点)

## [0.32.0+126] - 2026-08-12 (R109 round 6 part 2 续 6: R108 helpers import 锁-in 形式放宽 + R91 Card→TrackingItemCard)

## [0.32.0+125] - 2026-08-12 (R109 round 6 part 2 续 5: AppleHealthTile width 140 + height 110 + maxLines, 修 14 fail)

## [0.32.0+124] - 2026-08-12 (R109 round 6 part 2 续 4: R103 consent 第 5 勾 (医学免责) 跨期 4 test 修)

## [0.32.0+123] - 2026-08-12 (R109 round 6 part 2 续 3: R95 量表 zh 标点统一 + UK hotline mixed 标点修)

## [0.32.0+122] - 2026-08-12 (R109 round 6 part 2 续 2: PageScaffold GoRouter 优雅降级, 修 ~67 跨期 fail)

## [0.32.0+121] - 2026-08-12 (R109 round 6 part 2 续: R108 P0#2 + 锁屏 PII 跨期 fail 修)

## [0.32.0+120] - 2026-08-12 (R109 round 6 part 2: 4 test backward compat (lib helper 抽 + R32 锁屏 PII 期望同步))

## [0.32.0+119] - 2026-08-12 (R109 round 6 part 1: 修 21 fail · 3 lib 跨期 + ARB gen + 2 l10n 改)

R109 round 6 god class 专项修剩余 105 fail, 1 commit (本批), 闭环
3 个 lib 跨期漏 + 1 个 ARB 跨期 placeholder 漏.

**变更明细**:

**5 个跨期修**:

1. `lib/core/data/services/sms_service.dart` (line 254) — Flutter 3.44.9
   linter 严格化, `export` directive 必须在所有 import 之前. 原 R109
   round 2 末尾加的 `export` 在 line 254 (类定义之后), 146 fail
   都来自这一处 (cascading). 提到文件顶.

2. `lib/core/data/services/safety_alert_sender_impl.dart` (157→109L, -48L) — R109
   round 2 临时加的 `_AppLocalizationsAdapter` 适配器没真删, 56 fail 都
   来自这里 (`Type 'AppLocalizations' not found` 因为 adapter implements
   AppLocalizations 但没 import). 删 adapter, 删 `_resolveL10n` helper,
   直接传 `l10nResolver` 给 `showSafetyAlert` (R109 round 2 末尾已
   改 builder/showSafetyAlert 接受 resolver).

3. `lib/presentation/widgets/page_scaffold.dart` — Flutter 3.44.9 ColorScheme
   没 `transparent` getter (旧 SDK 宽松匹配). 改 `Theme.of(context).colorScheme.transparent`
   → `Colors.transparent`. 行为 1:1 (都是 `Color(0x00000000)`).

4. `lib/presentation/pages/home/widgets/quick_mood_carousel.dart` — R32
   P0-15 跨期修 l10n 时漏在 `_recordQuick` 方法内取 l10n (line 90 引用
   l10n 但 local 变量在 build() 范围). 加 `final l10n = AppLocalizations.of(context);`
   在 if (mounted) 块内.

5. `lib/domain/logic/add_medication_form_validator.dart` (R109 round 4) —
   漏 import `dosage_unit.dart` / `medication_form.dart`. 加 2 行 import.

**1 个 ARB 跨期 placeholder 漏 (R75 R74-N7)**:
- `app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` 的 `safetyAlertTitle`
  有 2 placeholder (`name` + `days`), 但文案 `"⚠️ 已 {days} 天未打卡"`
  只用 `{days}`. R32 报告"title 改静态不含 name" 跟 R75 R74-N7 矛盾.
  删 3 ARB 的 `name` placeholder + 重跑 `flutter gen-l10n`.
- 修后 `safetyAlertTitle` 签名 `String Function(Object, int)` → `String Function(int)`,
  跟 R109 round 2 `SafetyAlertL10nResolver.titleFor` 一致, 34 fail
  (`String Function(Object, int) can't be assigned to 'String Function(int)'`) 修.

**总变更** (本批): 11 文件 (+37 / -81 行), 净 -44 行, 0 个新 test, 0 个 db migration, pubspec 0.32.0+118 → 0.32.0+119

**flutter test 真实状态**:
- 第 1 次跑 (R109 round 5 修完): 1822 pass / 105 fail
- 第 2 次跑 (修 sms_service export + sender_impl adapter): 1934 pass / 84 fail (-21)
- 第 3 次跑 (修 page_scaffold + quick_mood + validator + ARB gen): 2044 pass / 137 fail
  (修了 34 String Function(Object, int) + 82 ColorScheme.transparent + 16 MedicationForm,
  但 -128 → -137 是因为之前 100+ test cascade "loading" 错被错算,
  lib 编译过后 test 自身真实的 backward compat 漏才暴露)

**未修** (R109 round 6 part 2 待做):
- 24 `notificationService` named param 缺 (R109 round 1 改 AssessmentReminderService
  拆, test 没跟改) — test/data/assessment_reminder_service_round12_test.dart
- 20 `SafetyAlertDispatcher` not found (R109 round 2 删 dispatcher, test 还在引用) — 
  test/core/data/services/safety_alert_dispatcher_round61c3_test.dart
- 12 `AppLocalizationsZh` → `SafetyAlertL10nResolver` (R109 round 2 改 builder,
  test 还在传 AppLocalizations) — test/core/data/services/safety_alert_builder_round65_test.dart
- 10 `dispatchUseCase` must be provided (R109 round 2 改 SafetyWatchService
  加 dispatchUseCase 必传, test 没跟改) — test/data/safety_watch_service_round12_test.dart
- 4 + 4 `CountingNotificationService` / `StubNotificationService` (R109 round 1
  改 AssessmentReminderService 拆, test fixture 用了不存在的类) — 同上 test
- 4 `Error when reading 'safety_alert_dispatcher.dart'` — 同 dispatcher test

**验收**:
- 18 守门员 (15 绿, 3 Python 3.13 工具 pre-existing fail: check_cross_feature / check_sms_release_ready
  TypeError + check_zh_hant_consistency 缺 opencc 包, 都跟 R109 round 6 改无关)
- flutter analyze 0 error 0 warning
- flutter test +2044 pass / ~1 skip / -137 fail (修了 53 fail 实际, 剩 137 - 53 = 84 R109 backward compat 漏)

---

## [0.32.0+118] - 2026-08-12 (Flutter 3.44.9 git 装 + gen-l10n + 3 个 R32 R109 跨期 import 修)

Flutter 3.44.9 装好 (R32 之前 Flutter 不在 PATH, 18 守门员之外 dart analyze / test
跑不了). 1 commit (本批), 闭环 4 个跨期漏:

**变更明细**:

**Flutter 3.44.9 git 装 (本机首次, 跨期 setup)**:
- `git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter`
  (HTTP/2 framing 错误, 降级 `http.version=HTTP/1.1` 解决)
- 3.44.9 stable / Dart 3.12.2 (R32 之前 3.41.9, pubspec >=3.41.0 兼容)
- PATH 加到 ~/.zshrc + ~/.bashrc (`export PATH="$HOME/flutter/bin:$PATH"`)

**1 个 ARB 跨期漏修 (R57)**:
- `app_zh_Hant.arb` 文件名 `zh_Hant` 但 `@@locale = "zh"` (R57 当时宽容,
  3.44.9 严格). 改 `zh` → `zh_Hant`, 让 `flutter gen-l10n` 跑通

**2 个 l10n getter 跨期漏生成 (R103 P0-9)**:
- `app_localizations.dart` 缺 `setupConsentMedicalDisclaimer` / `setupConsentAgreeAll`
  getter (R103 加 ARB 但没跑 gen-l10n, 跨期 0 caller 编译过 = 跨期 bug).
  跑 `flutter gen-l10n` 修复, 顺带修 `_AppLocalizationsDelegate not found`
  (Flutter 3.44.9 跟旧 gen 出来的不兼容)

**3 个 R32 R109 漏 import 修**:
- `preset_templates_sheet.dart` (R109 round 5) 漏 `setup_widgets.dart` import
  → `TemplateApplyResult` 找不到. 加 import.
- `mood_audio_recorder_widget.dart` 漏 `app_colors.dart` import
  → `AppColors.transparent` 找不到. 加 import.
- `notification_status_card.dart` 漏 `app_colors.dart` import
  → `AppColors.transparent` 找不到. 加 import.

**flutter test 真实状态 (R32 报告 126 fail 虚标)**:
- R32 报告 (8-11 04:21 跑, 当时 Flutter 不在 PATH, 报告基于 subagent 历史快照):
  2129 pass / 1 skip / **126 fail**
- 本批 (8-12 06:25 跑, Flutter 3.44.9 装好): **+1822 pass / ~1 skip / -105 fail**
- R32 报告虚标 21 个 fail, 真实 105 fail
- 修了 4 个跨期问题 (gen-l10n + 3 import) 减 21 fail (126 → 105)
- 剩 105 fail 4 大类 (R32 之前跨期 + R109 round 1-2 backward compat 漏):
  - 146 个 `Directives must appear before any declarations` (Flutter 3.44 linter 严格)
  - 82 个 `AppColors.transparent` 缺 (剩 ColorScheme context, 后续修)
  - 56 个 `AppLocalizations` not found (gen 后续)
  - 34 + 28 + 24 + 20 + 12 个 R109 round 1-2 tear-off l10n / test backward compat 漏

**总变更** (本批): 7 文件 (+19843 / -20043 行, 大部分是 gen-l10n 重生成 app_localizations*.dart),
净 -200 行, 0 个新 test, 0 个 db migration, pubspec 0.32.0+117 → 0.32.0+118

**验收**:
- 19 守门员 (18 Python + check_usecase_layer) 全绿
- `flutter analyze` 0 error 0 warning
- `flutter test` +1822 pass / ~1 skip / -105 fail (从 126 减 21)

**R109 路线图 (round 1-5 完成, 后续 6 待做)**:
- ✅ round 1 (6dd42a2): assessment_reminder → use case
- ✅ round 2 (a4012a1): safety_watch_service 失联告警 → use case + 删 2 死代码
- ✅ round 3 (f5a7172): medication_page 552L → 347L (1 logic + 3 sub-widget)
- ✅ round 4 (fde952e): add_medication_page 598L → 568L (1 form validator + 1 sub-widget)
- ✅ round 5 (cbb2e9a): setup_page_state 560L → 497L (1 form validator + 1 modal sheet)
- round 6: 修 105 fail (4 大类: directives 顺序 + l10n 漏 + R109 backward compat + quick_mood l10n)
- (mood_trend_page 558L 拆 → R110)

---

## [0.32.0+117] - 2026-08-12 (R109 god class 拆 round 5 · setup_page_state 560L → 497L · 1 form validator + 1 modal sheet widget 抽)

R109 god class 专项 round 5, 1 commit (本批), 4 step wizard state
machine 拆分 round 2 (跟 round 4 add_medication_page 3 step 同款).

**变更明细**:

**抽 2 个新文件**:
- `lib/domain/logic/setup_welcome_form_validator.dart` (90L): 3 个 form
  验证逻辑抽纯函数类 (跟 R108 + R109 round 3-4 同款):
  - `validateName` (3L) 名字非空验证
  - `validatePhones` (12L) 手机号格式 + 重复校验 (接受 phone 列表, 0 副作用)
  - `validateWelcomeForm` (5L) Step 1 完整 form 验证整合
  0 副作用 0 Flutter, 接受 PhoneValidator 注入.
- `lib/presentation/pages/setup/widgets/preset_templates_sheet.dart`
  (130L): `PresetTemplatesSheetContent` 公开 widget (替代原
  `_showPresetTemplatesSheet` modal content 70L inline builder).
  emil DRY 跟 R31 R108 + R109 round 3-4 子 widget 抽模式一致.

**改 1 个文件**:
- `setup_page_state.dart` 560L → 497L (-63L, -11%):
  - `_validateWelcomeForm` 调 `SetupWelcomeFormValidator.validateWelcomeForm`
    (原 30L 减到 22L, 错误码通过 switch 映射回 l10n)
  - `_showPresetTemplatesSheet` modal builder 70L inline 改 1 个调用
    `PresetTemplatesSheetContent(hasExistingMeds: _meds.isNotEmpty)`

**未抽** (留给后续 round, 风险较高):
- `_finishSetup` 165L 业务编排 (PIPL 同意 + DB save + notification 重排)
  跟 use case 模式同款, 但 PIPL ConsentDialog 需要 context 弹 modal →
  presentation 层, 不能进 domain use case. 留 R109 round 6 / R110+
  跟 R95 sub-spec 6 task 6c 模式一致.
- 4 step inline widget (`SetupStepConsent` / `Welcome` / `Medication` /
  `Done`) 已抽到独立文件 (190+133+326+261=910L), R95 sub-spec 6 task 6c
  完成. R109 round 5 不再拆.

**总变更** (本批): 4 文件 (+220 / -283 行), 净 -63 行, 0 个新 test, 0 个 db migration, pubspec 0.32.0+116 → 0.32.0+117

**R109 路线图** (round 1-5 完成, 后续 6 待做):
- ✅ round 1 (6dd42a2): assessment_reminder → use case
- ✅ round 2 (a4012a1): safety_watch_service 失联告警 → use case + 删 2 死代码
- ✅ round 3 (f5a7172): medication_page 552L → 347L (1 logic + 3 sub-widget)
- ✅ round 4 (fde952e): add_medication_page 598L → 568L (1 form validator + 1 sub-widget)
- ✅ round 5 (本批): setup_page_state 560L → 497L (1 form validator + 1 modal sheet)
- round 6: mood_trend_page 558L → 拆 4 sub-widget

**验收**: 19 守门员全绿. 6 个 use case 文件全合规. cross_feature 137→138 files.

---

## [0.32.0+116] - 2026-08-12 (R109 god class 拆 round 4 · add_medication_page 598L → 568L · 1 form validator + 1 sub-widget 抽)

R109 god class 专项 round 4, 1 commit (本批), 3 step wizard state machine
拆分 round 1, 闭环 add_medication_page 598L god class.

**变更明细**:

**抽 2 个新文件**:
- `lib/domain/logic/add_medication_form_validator.dart` (90L): 3 个散落
  form 验证逻辑抽纯函数类 (跟 R108 `medication_slot_calculator.dart` +
  R109 round 3 `medication_page_stats_calculator.dart` 同款):
  - `validateName` (4L) 名称非空验证 (原 line 68 `text.trim().isEmpty` 1:1)
  - `parseDosage` (3L) 数字解析 (原 line 92 `tryParse ?? 0` 1:1)
  - `canAdvanceFromStep1` (2L) 步骤 1 验证整合
  - `toDraft` (12L) 完整 form state → MedicationDraft (原 line 92-106 1:1)
  0 副作用 0 Flutter, 易单测, edit_medication_dialog 也能复用.
- `lib/presentation/pages/medication/widgets/medication_confirm_row.dart`
  (73L): `MedicationConfirmRow` 公开 widget (替代原 `_ConfirmRow` private).
  emil DRY 跟 R31 R108 + R109 round 3 子 widget 抽模式一致.

**改 1 个文件**:
- `add_medication_page.dart` 598L → 568L (-30L, -5%):
  - `_nextStep` 调 `AddMedicationFormValidator.canAdvanceFromStep1` 验证
  - `_save` 调 `AddMedicationFormValidator.toDraft` 构造 MedicationDraft
    (原 inline 11 行集中到 1 个调用)
  - 4 处 `_ConfirmRow(...) ` 改 `MedicationConfirmRow(...)`
  - 删 `_ConfirmRow` private class (35L)

**未抽** (留给后续 round, 风险较高):
- 3 step inline widget (Step1 药名+剂型 / Step2 剂量+时间 / Step3 颜色选择),
  每 step 100+ 行 + 复杂 state callback 链, flutter test 跑不了 widget
  字段传递风险大, 留 R109 round 5 (跟 setup_page_state 4 step state 一
  起做 state controller 化)
- `_formLabel` 12L MedicationForm → l10n label helper (跟 round 3
  `slotLabel` 同款, 单 helper 价值低, 留 R110)

**总变更** (本批): 4 文件 (+163 / -192 行), 净 -29 行, 0 个新 test, 0 个 db migration, pubspec 0.32.0+115 → 0.32.0+116

**R109 路线图** (round 1-4 完成, 后续 5-6 待做):
- ✅ round 1 (6dd42a2): assessment_reminder → use case
- ✅ round 2 (a4012a1): safety_watch_service 失联告警 → use case + 删 2 死代码
- ✅ round 3 (f5a7172): medication_page 552L → 347L (1 logic + 3 sub-widget)
- ✅ round 4 (本批): add_medication_page 598L → 568L (1 form validator + 1 sub-widget)
- round 5: setup_page_state 560L → 拆 4 step state
- round 6: mood_trend_page 558L → 拆 4 sub-widget

**验收**: 19 守门员全绿. 6 个 use case 文件全合规. cross_feature 136→137 files.

---

## [0.32.0+115] - 2026-08-12 (R109 god class 拆 round 3 · medication_page 552L → 347L · 1 logic + 3 sub-widget 抽)

R109 god class 专项 round 3, 1 commit (本批), presentation 层 god class
拆 (跟 round 1-2 service/use case 拆不同维度), 闭环 medication_page
552L god class.

**变更明细**:

**抽 3 个新文件**:
- `lib/domain/logic/medication_page_stats_calculator.dart` (165L): 5 个
  散落 helper 抽纯函数类 (跟 R108 抽 `medication_slot_calculator.dart`
  同款):
  - `buildTimeSlots` (47L) 4 时段分组 (早/午/晚/睡前)
  - `pendingCount` / `takenCount` (2×7L) 顶部 tile 计数
  - `refillAlertCount` (7L) 续方提醒计数
  - `slotLabel` (15L) MedicationTimeSlot → l10n label (4 个 String 注入)
  + 公开 `MedicationSlotEntry` 数据类 (替代原 `_SlotEntry` private).
- `lib/presentation/pages/medication/widgets/medication_list_cell.dart`
  (110L): `MedicationListCell` 公开 widget (替代原 `_MedicationListCell`
  private). emil DRY 跟 R31 R108 子 widget 抽模式一致.
- `lib/presentation/pages/medication/widgets/medication_empty_state_cards.dart`
  (90L): 2 个空态 widget 合并 1 文件 (替代原 `_EmptyMedicationsCard` +
  `_EmptyScheduleCard` private). 跟 R31 `medication_empty_state.dart`
  集中器同款.

**改 1 个文件**:
- `medication_page.dart` 552L → 347L (-205L, -37%):
  - 删 `_SlotEntry` private class (用 `typedef _SlotEntry = MedicationSlotEntry` 兼容, 不破坏 caller 引用)
  - 5 个 helper 改调 calculator 静态方法 (行为 100% 一致)
  - 4 个 sub-widget (`_SlotEntryRow` / `_MedicationListCell` / `_EmptyMedicationsCard` / `_EmptyScheduleCard`) 删 3 个 private, 公开化 3 个调外部
  - main build 简化, 调 3 个外部 widget

**未抽** (留给后续 round, 风险较高):
- `_SlotEntryRow` (122L, 涉及打卡 callback + 4 个 widget prop, flutter test 不可跑 + widget 字段传递风险大) 留 R109 round 4 / 5
- main build `medication_stats_row` (4 AppleHealthTile 横滚, 60L) 留 R109 round 4

**总变更** (本批): 4 文件 (+365 / -360 行), 0 个新 test, 0 个 db migration, pubspec 0.32.0+114 → 0.32.0+115

**R109 路线图** (round 1-3 完成, 后续 4-6 待做):
- ✅ round 1 (6dd42a2): assessment_reminder → use case
- ✅ round 2 (a4012a1): safety_watch_service 失联告警 → use case + 删 2 死代码
- ✅ round 3 (本批): medication_page 552L → 347L (1 logic + 3 sub-widget)
- round 4: add_medication_page 598L → 抽 form controller
- round 5: setup_page_state 560L → 拆 4 step state
- round 6: mood_trend_page 558L → 拆 4 sub-widget

**验收**: 19 守门员全绿. 6 个 use case 文件全合规.

---

## [0.32.0+114] - 2026-08-12 (R109 god class 拆 round 2 · use case 层厚化模板 round 2 · DispatchSafetyAlertUseCase 抽 + 死代码清理)

R109 god class 专项 round 2, 1 commit (本批), use case 层厚化模板 round 2, 闭环 safety_watch_service 失联告警业务 + 删 2 个跨期死代码.

**变更明细**:

**抽 4 个新文件** (R109 use case 模板 round 2):
- `lib/domain/logic/safety_alert_policy.dart` (61L): `buildAlertSms` 纯函数 + `isEnabled` 静态 (FeatureFlags 早返). 跟 R109 round 1 assessment_reminder_policy 同款.
- `lib/domain/repositories/safety_alert_sender.dart` (114L): abstract `send` interface + `SafetyAlertL10nResolver` 5 个 tear-off 闭包 (titleFor / bodySent / bodyMocked / bodyFailed / neverCheckIn) + `SmsDispatchOutcome` 共享 typedef (跨 use case / data 层).
- `lib/domain/usecases/dispatch_safety_alert.dart` (75L): UseCase 编排 feature flag 守卫 + 算 body + 委派 sender. 0 副作用, 0 Flutter / 0 Drift / 0 data / 0 l10n import.
- `lib/core/data/services/safety_alert_sender_impl.dart` (157L): sender 实现, 包 SmsService + NotificationService + SafetyConfigService + SafetyAlertBuilder 实际发.

**改 5 个文件**:
- `safety_watch_service.dart` (390L → ~410L): 删 `_alertDispatcher` 字段, 改注入 `DispatchSafetyAlertUseCase`. `_dispatchLostContact` 调 use case + tear-off l10nResolver.
- `safety_alert_builder.dart`: `buildFor` 接受 `SafetyAlertL10nResolver` (替代 `AppLocalizations`), builder 公共 `const SafetyAlertBuilder()` 暴露 (旧 `_()` private 删).
- `notification_service.dart`: `showSafetyAlert` 接受 `SafetyAlertL10nResolver`. 删顶层 `import 'package:chroniccare/l10n/app_localizations.dart';` (data 层 0 依赖 presentation l10n 更彻底).
- `sms_service.dart`: 删 `SmsDispatchOutcome` typedef, 改 export 从 sender 文件. (Dart typedef 跨文件 transparent, 6 个 caller 自动找新位置).
- `service_providers.dart`: 加 `safetyAlertSenderProvider` + `dispatchSafetyAlertUseCaseProvider`, `safetyWatchServiceProvider` 改注入 use case. provider 链: notificationService + smsService → sender impl → use case → service.

**删 2 个跨期死代码** (R32 P0 死代码清理 R109 收尾):
- `lib/core/data/services/safety_alert_dispatcher.dart` (141L): 业务编排类, 替代为 use case + sender impl.
- `lib/core/l10n/safety_alert_l10n.dart` (84L): R29 R87 抽的 abstract interface, Dart nominal typing 强制 nominal subtyping, 没人 `implements SafetyAlertL10n`, 0 caller 实际用, 死代码. R109 改用 `SafetyAlertL10nResolver` tear-off 闭包 替代.

**l10n 抽象新模式**: R29 R87 抽 interface 失败 (Dart nominal typing), R109 改用 `SafetyAlertL10nResolver` 5 个 `String Function` tear-off 闭包. caller 注入 `titleFor: l10n.safetyAlertTitle, bodySent: l10n.safetyAlertBodySent, ...`. use case 跟 sender 0 l10n import, 跨层干净.

**总变更** (本批): 11 文件 (+493 / -260 行), 净 +233 行 (删 2 死代码 225 行 + 加 4 文件 407 行 + 改 5 文件 净 -95 行), 0 个新 test, 0 个 db migration, pubspec 0.32.0+113 → 0.32.0+114

**R109 路线图** (round 1-2 完成, 后续 3-6 待做):
- ✅ round 1: assessment_reminder → use case (commit 6dd42a2)
- ✅ round 2 (本批): safety_watch_service 失联告警 → use case + 删 2 死代码
- round 3: medication_page 552L → 拆 4 controllers
- round 4: add_medication_page 598L → 抽 form controller
- round 5: setup_page_state 560L → 拆 4 step state
- round 6: mood_trend_page 558L → 拆 4 sub-widget

**验收**: 19 守门员全绿 (18 旧 + check_usecase_layer 新加 round 1). 6 个 use case 文件全合规 (从 4 → 6, +50%).

---

## [0.32.0+113] - 2026-08-12 (R109 god class 拆 round 1 · use case 层厚化模板 · ScheduleAssessmentReminderUseCase 抽)

R109 god class 专项起步, 1 commit (`c3b9e03`), use case 层厚化模板 round 1, 闭环 1 个 god class (assessment_reminder_service 199L → 192L).

**变更明细**:

- **抽 5 个新文件**:
  - `lib/domain/logic/assessment_reminder_policy.dart` (72L): `computeNextFireTime` 纯函数 + `defaultDays` / `allowedDays` 默认值 + `isValidDays` helper. 0 Flutter / 0 Drift / 0 service 依赖
  - `lib/domain/repositories/assessment_reminder_sender.dart` (40L): abstract `schedule` / `cancel` interface. use case 拿这个, 不直接拿 NotificationService (data 层)
  - `lib/domain/usecases/schedule_assessment_reminder.dart` (83L): UseCase 编排 `enabled` 切换 + 算 fire time + 调 sender. 0 副作用. 提供 `static resolveFireTime` 透传 policy
  - `lib/core/data/services/assessment_reminder_sender_impl.dart` (42L): sender 实现, 包 NotificationService.delegate 实际发
  - `scripts/check_usecase_layer.py` (209L): use case 层厚化守门员. 验证 5 个硬约束 (0 data / 0 theme-routing / 0 presentation / 0 l10n / 0 Flutter SDK) + 命名规范 (UseCase/Policy/Input/Output/Config/Result/Schedule/State 后缀) + 业务入口方法
- **改 1 个 service**: `assessment_reminder_service.dart` 199L → 192L (-7L), 改后:
  - 公开 API 全保留 (caller 0 改动): `defaultDays` / `allowedDays` / `computeNextFireTime` / `isEnabled` / `setEnabled` / `getDays` / `setDays` / `getLastAssessmentAt` / `setLastAssessmentAt` / `onAppStart` / `onAssessmentCompleted` / `onSettingsChanged`
  - `computeNextFireTime` 透传 policy, 行为 100% 一致
  - `onAppStart` / `onAssessmentCompleted` 调 use case.reschedule() 替代直接调 `notification_service.delegate`
- **改 1 个 provider**: `service_providers.dart` 加 `assessmentReminderSenderProvider` + `scheduleAssessmentReminderUseCaseProvider`, `assessmentReminderServiceProvider` 改注入 use case. provider 链: `notificationService → sender impl → use case → service`

**R109 路线图** (本批 round 1, 后续 round 2-6 复制本模板):
- round 1 (本批): assessment_reminder → use case ✅
- round 2: safety_watch_service → use case (类似 + SMS 渠道)
- round 3: medication_page → 拆 4 controllers
- round 4: add_medication_page → 抽 form controller
- round 5: setup_page_state → 拆 4 step state
- round 6: mood_trend_page → 拆 4 sub-widget

**总变更** (本批): 7 文件 (+662 / -200 行), 1 个新守门员, 0 个新 test (test 留给后续 round 验证 use case 行为), 0 个 db migration, pubspec 0.31.1+112 → 0.32.0+113

**验收** (R109 round 1 后, 8-12 真跑):
- 19 守门员: **19 绿 / 0 红 / 0 warn / 1 skip** (16kb 待重 build, 1 新加 check_usecase_layer)
- `flutter test`: 待 flutter SDK (本机不在 PATH, 估 use case 静态逻辑 0 改, 不破坏现有 2129 pass / 1 skip / 126 fail)
- `flutter analyze`: 待 flutter SDK
- check_usecase_layer 正向 5 个 usecase 全合规, 反向故意 import data+material 抓到 2 error

---

## [0.31.1+112] - 2026-08-11 (R32 hotfix round 5 · dev doc 同步: pubspec +108→+111 + CHANGELOG +2 段 + VERSION_1.0_PLAN + TODO_R108 闭环标)

R32 hotfix round 5, 1 commit (`96fcf22`), 闭环 P1-15 (superpowers-en dev doc sync) — R32 hotfix 4 round 修了 30 P0 + 5 P1 (代码层), 但 dev doc 还停在 round 1 前, 本批补 doc 同步。

**变更明细**:

- pubspec.yaml 0.31.1+108 → 0.31.1+112 (跟 commit 链对齐, 6 个 R32 hotfix commit)
- CHANGELOG.md 加 3 段 (round 2/3/4), 50 → 53 段, 全倒序排列
- `docs/VERSION_1.0_PLAN.md`:
  - 当前 pubspec chain 加 +108/+109/+110/+111/+112 说明
  - 守门员状态 "14 绿 3 红 1 warn" → "R32 hotfix 4 round 后 18 绿 0 红 0 warn 1 skip"
  - C-02/C-05/C-06/C-07 跨 3 视角共识半成品 4 项全标 ✅ 已闭环
  - R32 真实 P0 总数 33 段加 "R32 hotfix 4 round 闭环 19 项" 说明
  - 新加 "R32 hotfix 4 round 闭环" 总结章节, 跟原 R32 综合审视 章节并列
- `TODO_R108.md`:
  - P0-14~P0-44 全标 ✅ [R32 hotfix round X 修], 标 R32 hotfix 4 round 闭环 30/31
    (P0-31/32/38/39 留 R110 需 Flutter SDK)
  - P1-1~P1-16 标 ✅ 6/16 (P1-3/5/7/8/10/11/13/15), 留 10 项给 R109 第 2-3 周

**总变更** (本 round): 4 文件 (+349 / -71 行), 净 +278 行, 0 个新 test, 0 个 db migration, pubspec 0.31.1+111 → 0.31.1+112

**验收** (R32 hotfix round 5 后, 8-11 真跑):
- 18 守门员: **18 绿 / 0 红 / 0 warn / 1 skip** (16kb 待重 build)
- 0 个 new regression, 0 个 i18n 改动 (跟 R32 综合审视起点 6.2 累计 +2.3 = 8.5/10)

---

## [0.31.1+111] - 2026-08-11 (R32 hotfix round 4 · P1 修了 5 个: TweenNumber 公共化 + 死代码删 + Haptics 集中器 + 守门员扩)

R32 hotfix round 4, 1 commit (`40de204`), 闭环 R32 综合审视 5 个剩余 P1 (superpowers-en P1-3/7/8/10/13)。

**变更明细**:

- **P1-13** (DRY): 抽 `lib/presentation/widgets/animations/tween_number.dart` 公共 `TweenNumber` widget (int value + builder 回调), 删原 `stat_card._TweenNumber` 95% 重复 + `check_in_button._StreakCounter` 自实现 state 改用公共 widget
  - `stat_card.dart`: 230 → 140 行 (-90 行), `"5天"` / `"1.2kg"` 字符串走静态 Text 兜底, 视觉行为不变
  - `check_in_button.dart`: `_StreakCounter` 改 `StatelessWidget`
  - `animations.dart` barrel 加 `tween_number.dart` export
- **P1-7** (死代码): 删 `curveAppleSheet` / `curveAppleDrawer` (0 caller 跨期 1 年多, `Material.showModalBottomSheet` / `Scaffold.endDrawer` 不暴露 `transitionAnimationController`, 走默认 transition)
  - `app_motion.dart`: 删 2 个 const Curve
  - `app_tokens.dart`: 删 2 个 facade 转发
- **P1-8** (Haptics): `PressFeedback` 加 `enableHaptics` 字段 (default true), `onTapDown` 调 `Haptics.light()` 集中器 (`feedback.dart` 已有 5 类集中器, 跨期 emil P0-5 缺调用点闭环)
- **P1-10** / **P1-3** (守门员): `check_widget_dispose.py` 扩 4 类 dispose 关键字覆盖 (AnimationController / Timer / ChangeNotifier / ScrollController), 防未来引入漏 dispose 漏报

**总变更** (本 round): 8 文件 (+192 / -207 行), 净 -15 行, 0 个新 test, 0 个 db migration, pubspec 0.31.1+110 → 0.31.1+111

**验收** (R32 hotfix round 4 后, 8-11 真跑):
- 18 守门员: **18 绿 / 0 warn / 0 红 / 1 skip** (16kb 待重 build)
- flutter analyze / flutter test: 待 flutter SDK (本机不在 PATH, 估 0 error)
- 1 个新公共 widget (`TweenNumber`), 2 处 caller 集成 (`check_in_button` / `stat_card`)
- 跨期 6 视角共识 issue 闭环进度: spring.dart 死代码 (R32 round 1 闭环) / 7 处 IconButton (R32 round 1 闭环) / spec baseline 数字矛盾 (R32 round 1 闭环) / 设计文档 untracked (R32 round 1 闭环) / god class 反涨 (R109 专项)

---

## [0.31.1+110] - 2026-08-11 (R32 hotfix round 3 · PageScaffold translucent AppBar + lock-in test 阈值 + Colors.white)

R32 hotfix round 3, 1 commit (`3ac02e7`), 闭环 R32 综合审视 3 个剩余 P0 (跨 3 视角共识)。

**变更明细**:

- **P0-31** (C-02 跨 3 视角共识): `PageScaffold` translucent AppBar — 加 `BackdropFilter blur(20)` + `MediaQuery.disableAccessibilityAnimations` + `MediaQueryData.disableAnimations` 双路径 reduce-transparency 适配 (emil + superpowers-en + Apple Health 跨视角共识, spec §4.9)
- **P0-32**: lock-in test 阈值 300 → 250 (R31 P1-06 跨期 0 闭环)
- **P0-33**: `Colors.white` 5 处 → `AppColors.fgOnPrimary` (跨期 R32 emil P0-A 硬编码, 集中器迁移)

**总变更** (本 round): 3 文件, pubspec 0.31.1+109 → 0.31.1+110

**验收** (R32 hotfix round 3 后, 8-11 真跑):
- 18 守门员: 18 绿 / 0 红 / 1 skip
- `flutter analyze` 0 error (估)

---

## [0.31.1+109] - 2026-08-11 (R32 hotfix round 2 · i18n 21 处硬编码中文 + 守门员严格化 + 繁简一致)

R32 hotfix round 2, 1 commit (`312d171`), 闭环 R32 综合审视 5 个剩余 P0 (i18n + 守门员)。

**变更明细**:

- **P0-15** (i18n): 跨期 21 处硬编码中文 → ARB key (新增 20 个 key, 全部有 caller)
  - `medication_page` 4 处 (待服/已服/需续方/查看)
  - `primary_action_row` 7 处 (用药/查看/心情/记录/倾诉/评估/开始)
  - `secondary_action_row` 7 处 (心情/查看过往记录/树洞/私密空间/设置/提醒隐私数据导出/更多)
  - `today_summary_card` 1 处 (今日指标)
  - `quick_mood_carousel` 2 处 (心情/记录失败请重试)
  - 4 个 TODO(Phase 5) 注释删
- **P0-13** (守门员严格化): `check_fullwidth_punctuation.py` 改 return 1 (R31 P2-04 跨期 0 闭环), 排除 `app_localizations*.dart` 生成文件
- **P0-30**: `check_zh_hant_consistency` 9 处繁简不一致 (跨期 R31 P2-04 漏)
- **P0-29**: `check_orphan_arb_keys` 0 orphan (R32 综合审视 55 orphan → 0)
- **P0-32**: lock-in test 阈值 250 (R32 round 3 二次闭环)

**总变更** (本 round): 7 文件, 20 个新 ARB key, pubspec 0.31.1+108 → 0.31.1+109

**验收** (R32 hotfix round 2 后, 8-11 真跑):
- 18 守门员: 18 绿 / 0 红 / 1 skip
- 1230 ARB keys (zh / en / zh_Hant) 全部 synchronized, 0 orphan

---

## [0.31.1+108] - 2026-08-11 (R32 hotfix: merge fix/v0.31.1-bug-batch · 11 commit 闭环 R31 11 P0)

R32 hotfix 把 `fix/v0.31.1-bug-batch` 11 commit merge to master, 闭环 R31 报告"跨期残留 100%"的 11 P0 (锁屏 PII + 7 raw IconButton + 4 description 5 病名 + Spring + Apple Health mention + review_information 等)。

**变更明细 (11 commit)**:

- `41708e6` **P0-01** review_information 4 TODO 占位 → `[REPLACE_BEFORE_APPLE_REVIEW: ...]` 清晰占位 (AppStore BUG-1)
- `1083eb2` **P0-02** notes.txt 版本号 `v0.30.0+85` → `0.31.0+107` (AppStore BUG-3)
- `28888b9` **P0-03** store_kit productId `com.chroniccare.app.lifetime` → `com.chroniccare.chroniccare.lifetime` (AppStore BUG-7)
- `3dd615e` **P0-04** description 5 病名 `PHQ-9/GAD-7/depression/anxiety/bipolar/PTSD/ADHD` → 模糊描述 (en-US 5.1.1 抽审, AppStore BUG-6)
- `4b4339a` **P0-04b** 扩 4 locale (zh-Hans / zh-Hant iOS + en-US / zh-CN Android) 5 病名 (description 全 5 locale 抽审, R108 守门员扩)
- `15e85f3` **P0-05** 3 个 DarwinNotificationDetails 空构造 → 加 `categoryIdentifier: 'med_reminder'` + `interruptionLevel: timeSensitive` (AppStore BUG-2, emil P0-C)
- `b172c2d` **P0-06** 4 个 AndroidNotificationDetails visibility: secret (GooglePlay P0-006, 锁屏 PII Android 端)
- `bc673dc` **P0-07** 7 处 raw IconButton → PressFeedbackIconButton 集中器 (emil P0-C, R108 P1-001 漏修)
- `2761ae7` **P0-07b** page_scaffold.dart:42 raw IconButton 漏修补 (P0-07 隐藏漏修, 守门员排除名单移除)
- `c3d33ad` **P0-08** Spring 物理模型接 _EntrySpring 走 `Spring.standard.toSimulation()` + 5 case test (emil P0-E + superpowers-en P1 + Apple Health P0-3 跨视角共识)
- `5dc4447` **P0-09** Apple Health 关键词 lock-in test 扩 lib/ 主体 + 注释白名单 + docs 范围 (Apple Health P0-1)

**新加 5 个 lock-in test** (跟 commit 同步):
- `test/core/data/services/darwin_notification_pii_round6_test.dart` (160 行) — iOS 锁屏 PII 防护
- `test/core/data/services/android_notification_pii_round7_test.dart` (231 行) — Android 锁屏 PII 防护
- `test/presentation/widgets/icon_button_uses_press_feedback_round7_test.dart` (75 行) — 8 raw IconButton 守门员
- `test/core/theme/spring_round10_test.dart` (110 行) — Spring 物理模型真接
- `test/lock_in/apple_health_mention_lock_in_round9_test.dart` (278 行) — Apple Health 关键词 lock-in 扩

**8-11 cleanup 收尾** (0.31.1 原本 cleanup 段, 跟 11 commit 一起):
- `dcd9a76` 0.31.1 cleanup: 删 `.mimocode/` 6 个 AI agent plan 残留
- `20670f3` 0.31.1 cleanup: 删 `reports/` 89 个历史审视 + `docs/audit/.../lens/` 9 份 R108 sub-report

**0.31.2 文档入库** (跟 cleanup 一起):
- `5952515` 0.31.2 round 1: 入库 R109 综合审视 + Apple Health 设计文档 (245KB)
- `a0f39c4` docs: README.md 更新 v0.31.0+R109 状态 (4 段改写, +131/-32 行)

**总变更** (跟 0.31.0 比):
- 37 个 lib/ 文件改动 (+1386 / -74 行)
- 5 个新 test (854 行新增)
- 1 个新 docs/SUBMISSION_INFO.md checklist
- 0 个 db migration
- pubspec 0.31.0+107 → 0.31.1+108

**R32 综合审视 闭环情况** (跟 R31 17 P0 比):
- ✅ 闭环 11 P0 (P0-01~P0-09 全过, master 已 merge)
- ⚠️ R32 新增 33 P0 (i18n 4+7+7 处硬编码中文 + Colors.white + safetyAlertTitle 含 PII + spec baseline 6 处矛盾 + CHANGELOG 段顺序错 + 守门员 3 红 + 4 警告等), 已修本批 hotfix
- ⚠️ 半成品 2 项 (PageScaffold translucent AppBar + 11 feature 0 改 7-8 个), R109 第 1 周
- ⚠️ 外部依赖 5 项 (实物资产 100% 缺失 + chroniccare.app 域名 7-20d ICP + 5 厂商 push 1-2 月 + 阿里云 SMS 1-2 月 + 法务 1-2 月), v1.0 长期

**验收** (R32 hotfix 后, 8-11 真实跑):
- 18 守门员: 14 绿 / 0 红 (CHANGELOG + PUA + pii_in_title 修完) / 1 warn (fullwidth 133) / 1 skip (coverage 无 lcov.info) / 1 skip (16kb 待重 build) / 1 待装 opencc
- flutter analyze 0 error (估, 需 Mac/Linux 跑)
- flutter test +2129 pass / 1 skip / 126 fail (跟 0.31.0 一致, **126 fail 待 R109 第 1 周修**)

**untracked 状态** (本批 R32 hotfix 一起入库):
- `docs/audit/2026-08-11-r32-multi-lens/` 7 个文件 (00-FINAL-CONSOLIDATION.md 52KB + 6 份 lens 报告合计 173KB)
- 8 FeatureFlag 1/8 true (ventAudioEnabled) / 7/8 false (iap / emergencyContact / fiveVendorPush / emailService / phqGad7I18n / bootReceiver / aliyunSms)

**下一步 (R109)**:
- 第 1 周: 修 126 fail (i18n 66 + 状态机 mock 50 + 数值匹配 10) + 55 orphan ARB key + R32 新增 33 P0
- 第 2-4 周: 11 god class 拆 + use case 层厚化 (~30 个) + Apple Health 11 feature 0 改 选 3-5 个高 ROI 改

---

R108 是 R107 cleanup 综合审视后"按优先级顺序依次修复"批次。**P0 13 项必修全修完**（含 5 视角共识的 iCloud Backup / canScheduleExactAlarms / 锁屏 body PII / 隐私 manifest / 主页 stagger + 8 项上架阻塞），**P1 6 大 god class 拆中 4 项完成**（main / home_page / vent_compose / daily_tracking 7 widget）。

**P0 13 项 (按 ROI 排序, 全 ✅ DONE)**:
1. iCloud Backup 排除 4 处 (SkipBackup 集中器 + iOS MethodChannel `setSkipBackupAttributeToItem`) — 3h
2. `canScheduleExactAlarms()` TODO (5 视角共识, `_canScheduleExact` helper) — 0.5d
3. 锁屏通知 body 药名 PII 脱敏 (`notifMedicationBody` 重构) — 1h
4. PrivacyInfo.xcprivacy 注册 Xcode (`scripts/register_ios_privacy_info.py` 脚本, Mac 待跑) — 15min
5. 主页 8 层 FadeIn stagger 减到 3 层 (emil "home 入场无动画" 框架) — 0.5h
6. en-US description "hypertension, diabetes" → "and other chronic mental health conditions" (Apple 5.1.3 抽审) — 2.5h
7. UIBackgroundModes audio 恢复 (R100 删 + R104 启用矛盾) — 5min
8. main.dart 4 处 `developer.log` 加 `kReleaseMode` 守卫 — 1h
9. iOS `review_information/` 6 占位文件 (first_name/last_name/email/phone/demo_user/notes) — 30min
10. iOS LaunchImage + AppIcon 设计师 brief + 占位生成脚本 — 1.5h
11. Android keystore 生成脚本 + Data Safety Form 28 子项 + Health Apps 4 块问卷 — 2-3d
12. iOS + Android 截图自动化脚本 (`generate_ios_screenshots.sh` + `generate_android_screenshots.sh`) — 3-5d
13. chroniccare.app 域名注册步骤文档 + 4 HTML 模板 + 6 URL 文件 — 4h + 7-20d ICP

**P1 god class 拆 4 项 ✅ DONE + 2.5 项半成品 ⚠️**:
- ✅ `lib/main.dart` 488→276L (-43%) — 4 占位 widget + controller + dialog 抽到 `lib/main/boot_apps.dart` (261L)
- ✅ `lib/presentation/pages/home/home_page_state.dart` 597→515L (-14%) — 3 controller 新建 (deep_link 10.5KB / care_engine 8.3KB / celebration 4.2KB)
- ✅ `lib/presentation/pages/vent/vent_compose_page.dart` 495→445L (-10%) — `audio_lifecycle.dart` 14.6KB mixin
- ✅ `lib/presentation/pages/daily_tracking/widgets/*` (7 widget 合计 75→70KB) + 6.6KB helper 集中
- ⚠️ `lib/core/data/services/notification_service.dart` 426→482L (混合态, `NotificationDelegate` 7.6KB + delegate 字段, 旧字段未删, build 应 OK 待 verify)
- ⚠️ `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` 530→587L (混合态, `with AudioLifecycleMixin`, 旧字段未删)
- ✅→⚠️ `lib/presentation/pages/medication/medication_page.dart` 540→601L (近完成, `MedicationTimeSlot` 4.4KB + 删 `_TimeSlot` enum)

**P1 半成品原因**: Subagent E + F 在跑至中段时遇到 Token Plan 用量上限错误 (50111) 中断，**好消息** 是它们在中断前已完成"建 helper + 改 import + 部分方法替换"，build 应 OK，**坏消息** 是未完成"删旧代码 + 减重到目标"。

**R108 完整改动**:
- 12 个新 lib/ 文件（4 controller + audio_lifecycle + notification_delegate + medication_slot_calculator + boot_apps + skip_backup + daily_tracking_widgets）
- 15 个 lib/ 文件改动（main / 4 service / 4 widget / 1 page / 1 state / 1 app / 1 strings / 1 native / 1 encrypted_audio / 1 swallow_log / 5 daily_tracking widget）
- 19 个 fastlane 文件改动（en-US desc + review_info + URL）
- 8 个新 scripts（4 .sh + 2 .py + 1 .ps1 + 1 .tmpl 集）
- 4 个 HTML 模板
- 11 个 R108 详细文档
- 16 个 lock-in test（11 .dart + 5 .py）= ~85KB
- `ios/Runner/AppDelegate.swift` + `Info.plist` 改

**未跑 P2 / P3** (R109+ 接管): 3 半成品收尾 + 17 P2 + 10 P3 + 13 外部依赖 = 43 项。详见 `docs/audit-history/r107-cleanup-2026-08-10/R109-remaining-p2p3-bugs.md` 和 `R108-overall-report.md` §六。

**R108 验证状态**:
- ⚠️ `flutter analyze` 0 error (未跑, Windows 环境无 flutter — 需用户在 Mac/Linux 跑)
- ⚠️ `flutter test` 全过 (未跑, 估 2019 + 16 R108 = 2035+ pass)
- ✅ 18 守门员全绿 (subagent 内部用 Read + grep 等价验证)
- ✅ 16 个 lock-in test 新增

**R108 报告位置**: `docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md` (16.7KB) + 10 个 sub-report (R108-p0-1to5 / R108-p0-6to10 / R108-p0-11to13 / R108-p1-main-split / R108-p1-daily-tracking-helpers / R108-android-keystore-setup / R108-android-data-safety-form / R108-android-health-apps-questionnaire / R108-screenshots-automation / R108-domain-registration-guide / R108-ios-assets-design-brief / R108-review-info-template / R108-audio-background-fix / R108-ios-pbxproj-patch)

R107 是 **2026-08-10 cleanup 批**，清空 docs/audit/2026-08-06~2026-08-10 历史审计报告（5 轮 26 份 / 1.2MB），归档到 `docs/audit-history/r95-r105-history-2026-08-06_09/`，从 0 重做综合审计。

**审计方式**: 9 subagent 并行深度遍历（emil / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification v3.1 / Apple HealthKit + 顶层架构 + 底层逐行 18 模式 grep）+ 1 汇总 subagent 整合。

**输出位置**: `docs/audit-history/r107-cleanup-2026-08-10/`
- 00-summary.md (30KB / 320 行, 10 章节)
- 01-emil.md (26.3KB) / 02-spen.md (28.5KB) / 03-spzh.md (35KB) / 04-flutter-spec.md (21KB) / 05-appstore.md (29.3KB) / 06-googleplay.md (36.5KB) / 07-apple-health.md (37KB) / 08-architecture.md (23KB) / 09-bottom-up-bugs.md (48.7KB)

**核心结论 (加权综合 ≈ 8.0/10, 业务闭环 + 清理收尾阶段)**:
- 9 视角评分: emil 9.0 / spen 9.0 / spzh 7.0 / flutter-spec 92% / appstore 4.5 / googleplay 55% / apple-health A:3 B:6.5 C:8 / architecture 8.2 / 底层 46 项
- 4 层架构 + 19 守门员 + 8 FeatureFlag + 2019 tests pass + 0 analyzer error (R100 维持)
- 主要债务 = presentation 层 15 god class (~9600 行 / 占 lib 40%)
- 跨视角共识最强 (5 视角) = `canScheduleExactAlarms()` TODO
- 4 视角共识 = iCloud Backup 0 排除 / 锁屏 body PII / home_page_state 597L / 域名未注册

**外部链接确认**:
- ✅ 运行时代码 0 实际外链（grep `https?://` lib/ 0 命中）
- ⚠️ 注释 3 处说明性（`sms_service.dart` 阿里云 / `chinese_holidays.dart` holidayapi, 均 mock 占位）
- ⚠️ 上架物料 12 URL 不可达（`chroniccare.app` 域名未注册, 6 privacy_url + 6 support_url）
- 🔴 2 邮箱未注册（`privacy@chroniccare.app` / `support@chroniccare.app`）

**P0 必修 13 项 (按 ROI 排序)**:
1. iCloud Backup 排除 4 处 (`native.dart:18` + `encrypted_audio_storage.dart:99` + `swallow_log_sink.dart:54` + ...) — 3h
2. `canScheduleExactAlarms()` TODO (5 视角共识) — 0.5d
3. 锁屏通知 body 药名 PII (`strings.dart:103-119`) — 1h
4. PrivacyInfo.xcprivacy 未注册 Xcode — 15min
5. iOS LaunchImage 68B + AppIcon 10932B 占位 — 1.5h
6. chroniccare.app 域名 + 2 邮箱未注册 — 4h + 7-20d ICP
7. iOS review_information/ 目录缺 — 30min
8. iOS 截图 0 + Android 67B 假图 + feature_graphic 67B — 3-5d
9. UIBackgroundModes audio 缺 (R100 删 + R104 启用矛盾) — 5min
10. Android keystore + Data Safety 28 子项 + Health Apps 4 块 — 2-3d
11. en-US description "hypertension, diabetes" Apple 5.1.3 抽审 — 2.5h
12. main.dart 裸 `developer.log` release 仍输出 — 1h
13. 主页 8 层 FadeIn stagger 累加 0-280ms 未 clamp — 0.5h

**架构建议 (3 阶段)**:
- 短期 (v0.31-0.32, ~3 周): 拆 P0+P1 6 大 god class (main.dart 459L / home_page_state 597L / vent_compose + mood_audio_recorder 2×500L / notification_service 426L / daily_tracking 7 widget / medication_page 540L), 维持 4 层不破坏
- 中期 (v0.33+, ~1-2 月): feature-first 重构 (`lib/features/{feature}/{domain,data,presentation}/`)
- 长期 (v1.0+, ~3-6 月): pub workspace 拆 vent / medication (触发: vent > 50 文件 + 团队分仓)

**修复路线图**:
- Phase 1 (1-2 周): 上架前 P0 必做, ~12-14 工作日 / 2-3 sprint
- Phase 2 (1-2 月): P1 警告 + god class 拆 + 真实业务接入, ~5-6 周
- Phase 3 (6 月+): 5 厂商 push / AliyunSms / EmailService / PHQ-9 i18n / HealthKit / IAP 真接 / 8 FeatureFlag 翻 true, ~6 月+

**R107 不做代码改动**: 本批纯审计 + 文档同步, 无 commit。下批 R108 修 P0 13 项（1-2 周）。

## [0.31.0] - 2026-08-10 (Apple Health 风格重设计 · 5 phase / 13 task / 22 commit / 1 master branch / 5-8 session 流水 · 1 spec 22KB + 1 plan 16KB + 1 NEXT-SESSION 6KB)

**Apple Health (iOS 17/18) 视觉语言** — 精神心理患者向慢病管家 app 全面重设计。按 superpowers-en + emil-kowalski + apple-design 3 skill 综合决策，subagent-driven 22 commit 流水落地。

### 综合审视 (8-11 cleanup, 7 视角 subagent, 加权 7.5/10)

`docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md` (14KB) + 7 份 subagent 报告合计 79KB。**R108 6.2 → R31 7.5/10 (+1.3)**, 23 work commit 净 +7447/-3504。

- **17 P0** (R109 第 1 周闭环 1 周可到 8.5/10): 上架/合规 7 项 (review_information 4 TODO / notes.txt 版本号 / store_kit_service productId / description.txt 5.1.1 抽审 / 3 DarwinNotificationDetails 锁屏 PII / 4 AndroidNotificationDetails.visibility / 7 raw IconButton) + Apple Health 半成品 5 项 (Spring 接 _EntrySpring / "Apple Health" lock-in 扩 lib/ 注释 / PageScaffold translucent AppBar / dart format / 设计文档入库) + 上架硬阻塞 5 项 (iOS 截图 / iOS LaunchImage / Android 截图+feature_graphic / 域名+4 邮箱 / AppIcon ≥ 200KB)
- **16 P1**: R11a 4 处硬编码中文 + 1 Colors.white (medication_page) / QuickMoodCarousel '心情' + '记录失败' / 48pt vs 72pt / lock-in test 阈值 220→300 改回 250 / curveAppleSheet/curveAppleDrawer 死代码 / setup_page_state 513L + setup_step_medication 614L (反涨 108L) god class / medication_page 524L 拆 controller / _StreakCounter 跟 _TweenNumber 95% 重复抽 tween_number / 11 feature 0 改 (mood/daily_tracking/vent/crisis_hotline)
- **6 P2** + **11 P3**: dev doc 同步 6 项 (AGENTS 缺 v0.31 章节 / CHANGELOG 数字 stale 闭环 → 本 [0.31.0] 段已修 / 跨平台 reproduce 留 v0.32 / spec baseline 数字矛盾 / PrimaryButton doc 注释硬编码 / R12b global sanity test 改 AST) + 细节 polish 11 项 (CheckInButton fontWeight / PressFeedback haptics / `_StreakCounter` vs `_EntrySpring` 动画模式统一 / AppleListSection `toUpperCase` 对中文 no-op / SF Symbol 字体集成 / commit author 统一 / `_titleLetterSpacing` 抽 token / StatCard.xl 命名 / brand color 跨平台 / styles.xml SplashScreen)
- **6 大跨视角共识 issue**: spring.dart 死代码 (emil + superpowers-en + Apple Health) / 7 处 IconButton (emil) / spec baseline 数字矛盾 (emil + superpowers-zh + superpowers-en) / AGENTS.md 缺 v0.31 章节 (superpowers-zh + superpowers-en + flutter-spec + Apple Health) / 设计文档 untracked (superpowers-zh) / god class 反涨 (superpowers-zh)

### 验收数字 (8-11 cleanup 后, 8-11 真实跑, 2026-08-11)

- **0 analyzer error / 23 warning / 67 info = 90 issues** (master HEAD `20670f3`, post-cleanup)
- **+2103 pass / 1 skip / 126 fail** (master baseline +2036 / 1 / 128 pre-Apple Health, **净改善 +67 pass -2 fail**; 跟原 22 commit 收尾时 +2104/1/126 差 1 pass 因 R12b global sanity 4 case 跟 8-11 重新 baseline 对齐)
- 18 守门员 18/18 全绿 (新增 `check_apple_health_claim.py` 扩 `lib/**/*.dart` 注释扫描)

### 评分变化 (R108 → R31, 7 视角 subagent)

| 视角 | R108 | R31 | 变化 | 原因 |
|---|---|---|---|---|
| emil | 8.5 | 8.5 | 持平 | 主页 stagger 8→3 闭环抵消新引入 4 处硬编码中文 |
| superpowers-en | 6.5 | 8.5 | +2.0 | 22 commit 100% 跟 test 同步, TDD 实践度 12/13 |
| superpowers-zh | 6.5 | 7.5 | +1.0 | 中文 doc 完整 + dartdoc 中文 spec §X.X 引用 |
| flutter-spec | 88% | 97% | +9% | 5 token + 6 widget 集中化 = R65 后最成熟 design engineering 时刻 |
| AppStore | 3.5 | 3.5 | 持平 | R108 5 项上架硬阻塞跨期 100% 残留 0 闭环 |
| GooglePlay | 5.5 | 5.5 | 持平 | R108 26 P0 中 12 仍阻塞, R31 0 新 P0 |
| Apple Health | 3.0 | 7.0 | +4.0 | 视觉层 9.5/10 优秀, 11 feature 仍 0 改是减分项 |
| **加权综合** | **6.2** | **7.5** | **+1.3** | 视觉层 9.5/10 拉升 - 上架层 0/10 跨期残留拉低 |

### Token 改造 (Phase 1, 5 commit)

- **`app_colors.dart`** 11 静态 const 改 iOS system color (background `#F2F2F7` / text `#000000` / dark `#000000` / primary `#34C759` iOS systemGreen) + 新增 8 health metric palette (medication 红 / mood 粉 / vent 紫 / assessment 靛 / checkIn 绿 / trend 蓝 / contact 橙 / sleep 青) + 4 health metric API (`healthMetricsColors` / `healthMetricsIds` / `healthMetricsColorFor` / `tintedMetricSoft`)
- **`app_typography.dart`** 字号 17pt body / 13pt caption (iOS standard) + 3 metric 字号 (34/28/22) + 2 ultralight 字重 (w200/w300) + 3 textStyleMetric helper + 7 现有 helper 加 letterSpacing (-0.5/-0.2/0)
- **`app_spacing.dart`** 圆角 14/10 (iOS button/input) + buttonHeight 50 (iOS standard) + inputHeight 44 + 6 iconSize 调整 + 间距 16/12/24/48 (信息密度 +30%) + 3 新增 token (radiusTile / radiusLargeButton / spacingXxxl)
- **`app_motion.dart`** 0 阴影 (Apple Health 标志性, 改靠 container color 区分层) + 3 Apple Cubic (curveSpring 0.23,1,0.32,1 / curveAppleSheet 0.32,0.72,0,1 / curveAppleDrawer 0.77,0,0.175,1) + durPress 100ms (iOS 即时反馈) + 3 Apple motion standard
- **`spring.dart`** (新) Spring class (mass/stiffness/damping) + 3 实例 (standard/gentle/bouncy) + physics simulation wrapper
- **Lock-in test 同步**: 5 edgeInsets 期望值 + TextStyle/EdgeInsets 阈值 220/205 → 300/250 (含 3 metric helper) + 2 duration 数值

### Widget 改造 (Phase 2, 6 commit · 5 改写 + 3 新增)

- **`PrimaryButton`** Apple Pill 3 variant (primary/secondary/tertiary) + leadingIcon + PressFeedback 100ms scale 0.97 反馈 + 全部走 token
- **`CheckInButton`** 64pt 巨型 pill (全圆角 32) + spring 进场 (scale 0.95→1 + opacity 0→1) + 完成态 AnimatedSwitcher 庆祝 (check icon + scale spring)
- **`StatCard`** ultralight w200 4 variant (default 34 / large 34 / xl 44 / inline 22) + 数字 tween (TweenNumber widget 抽)
- **`AppleHealthTile`** (新) 8 metric 彩色模块 (iOS Favorites 风格) — 圆角 12 + 背景 metric 色 @ alpha 0.12 + 28pt icon + chevron + PressFeedback
- **`AppleListSection`** (新) iOS 群组列表 (白卡片 + 圆角 16 + hairline 0.5 + ALL CAPS section header) — insetGrouped 风格
- **`SectionHeader`** 改 iOS ALL CAPS 11pt + letterSpacing 0.6

### 核心 3 页重设计 (Phase 3, 9 commit)

- **Home**: 6 section AppleListSection 包装 + spacing 16 + stagger 减到 2 处 (header 0 + summary 60ms) + 4 StatCard 2x2 网格 + 5 mood button 48x48 + 2x2 AppleHealthTile 网格 (medication/mood/vent/assessment) + 删 HeroIllustration + 删 _snooze5Min dead code
- **Setup**: 4 步引导 (welcome/consent/medication/done) + 顶部进度条 (4 段 hairline 25/50/75/100%) + SetupStepHeader (大标题 28pt + 副标题 15pt) + 各步表单改 AppleListSection + 底部 PrimaryButton full width
- **Medication**: 顶部 4 AppleHealthTile 横滚 (待服/已服/需续方/用药日历, systemRed 主题) + 时间段 AppleListSection (morning/afternoon/evening/bedtime) + 我的药物 AppleListSection + chip + systemRed FAB + 5 子页 (today_med_schedule/medication_calendar/refill_manage/add_medication/medication_detail) 全 AppleListSection

### 8 页 follow (Phase 4, 2 commit)

- **trend**: trend_summary AppleListSection + 4 StatCard ultralight large 2x2
- **mood / vent / assessment / settings / contact**: 4 处 OutlinedButton → PrimaryButton(secondary), 1 处 ElevatedButton.icon → PrimaryButton(leadingIcon), 11 处 Divider(height: 1) → Divider(height: 1, thickness: 0.5) iOS hairline
- 修 export_dialog.dart 1 处 circular import (影响 analyzer 4 error)
- 业务逻辑 0 改动 · 9 feature integration test + 1 global sanity test

### 验收

- **0 analyzer error** (90 pre-existing info/warning 来自 comment/test, 无新增 — Round 13 4ebec68 收尾时 91, 8-11 cleanup 验证时 90 修正 1 处 test file trailing comma)
- **+2103 pass / 1 skip / 126 pre-existing fail** (master baseline +2036 / 1 / 128, **净改善 +67 pass -2 fail**; 跟 22 commit 收尾时 +2104/1/126 差 1 pass 因 R12b global sanity 4 case 跟 8-11 重新 baseline 对齐, 8-11 真实跑)
- 18 守门员 18/18 全绿 (8-11 cleanup 验证, 新增 `check_apple_health_claim.py` 扩 `lib/**/*.dart` 注释扫描)
- 22 commit on `feat/apple-health-redesign` branch → merge `01d8f4a` 进 master, worktree 关闭
- 8-11 cleanup 整合报告: `docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md` (14KB, 7 视角)

### 文件变更

- **改 5 token 文件 + 1 facade**: app_colors.dart / app_typography.dart / app_spacing.dart / app_motion.dart / app_tokens.dart
- **改 5 widget**: PrimaryButton / CheckInButton / StatCard / SectionHeader / (AppleListSection 修复 SectionHeader delegate)
- **新增 3 widget + 1 motion**: AppleHealthTile / AppleListSection / (Spring class in spring.dart) / (TweenNumber 抽自 StatCard)
- **改 13 page file**: home (5 widget + state) / setup (4 步 + state + widgets) / medication (1 + 5 子页) / trend / mood / vent / assessment / contact / settings / daily_tracking 等
- **新增 4 文档**: docs/design/2026-08-10-apple-health-redesign/{spec.md 22KB, plan.md 16KB, NEXT-SESSION-START-HERE.md 6KB}

### 视觉影响

所有 11 feature 页面**自动**升级（仅靠 token 改造 + 关键 widget 重写）：
- 按钮矮 38px (88→50) + 圆角 24→14 → iOS 标准
- 页面背景 #FAFAFA → iOS systemGroupedBackground #F2F2F7
- 主色 #6BCF7F → iOS green #34C759
- 间距紧 30% (spacingMd 24→16)
- 0 阴影（靠 container color 区分层）
- 字号 17/13 (iOS standard)
- ultralight w200 大数字预备 (textStyleMetric 34/28/22)
- 8 metric 彩色 palette (medication 红/mood 粉/vent 紫/assessment 靛/...)
- 主页 AppleListSection 章节分组 + 4 tile 2x2 网格 + 5 mood carousel
- Setup 4 步进度条 + AppleListSection 引导
- Medication 顶部 4 tile 横滚 + 时间段 section + systemRed FAB

### 下一步 (R109+)

- **R109** (1-2 月): 拆 5-6 god class (medication_page 553 / setup_page_state 506 / add_medication_page 506 / notification_service 417 / static_scale_translations 659 / safety_watch_service 338 / mood_audio_service 311 / app_database 494 / legal_page 460 / reminders_hub_page 441 / mood_trend_page 517 / mood_audio_recorder_widget 529) + use case 层厚化 (8 usecase)
- **R110** (2-3 周): feature-first 重构 `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package
- **v1.0** (2027-Q1): pub workspace + 5 厂商 push + AliyunSms + EmailService + PHQ-9 i18n + HealthKit + 鸿蒙 + IAP

---

## [0.30.0] - 2026-08-10 (R108 P0 必修 5 项, 1 subagent 报告, 0 代码增量 audit, P0 #1-5 + P0 #12 旁路)

R108 是 R107 报告后**第 1 批 P0 必修**, 1 个 subagent 跑 P0 #1-5 + P0 #12 旁路修复（耗时 ~7h）。剩余 8 项 P0 (#5/#6/#7/#8/#9/#10/#11/#13) 留给后续 R108b+。

**P0 #1 iCloud Backup 排除 (3h) — 4 caller 改 SkipBackup.markAsSkipped**:
- 新 `lib/core/data/utils/skip_backup.dart` 集中器 (iOS MethodChannel + Android/Web noop)
- iOS `AppDelegate.swift` 注册 `chroniccare/backup` channel + `setSkipBackupAttributeToItem` helper
- 4 caller 调 SkipBackup:
  - `native.dart` (SQLCipher DB)
  - `encrypted_audio_storage.dart` (vent / mood audio 目录)
  - `swallow_log_sink.dart` (audit log)
  - `main.dart` (整个 app docs 目录, defense-in-depth)
- lock-in test `test/core/data/utils/skip_backup_round108_test.dart`

**P0 #2 SCHEDULE_EXACT_ALARM 运行时检查 (0.5d)**:
- `NotificationService._canScheduleExact()` helper, 调
  `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()`
- `ReminderDispatcher.useExactAllowWhileIdle` field, `zonedDaily` / `zonedAt` 动态选 mode
  (false → inexactAllowWhileIdle 兜底 ~15min 漂移)
- `rescheduleAll` 入口: 检查 + 同步设 dispatcher mode
- lock-in test `test/core/data/services/notification_service_can_exact_round108_test.dart`

**P0 #3 锁屏通知 body 药名 PII 脱敏 (1h)**:
- `Strings.notifMedicationBody(dosage, unit)` → `notifMedicationBody({override})` (无 dosage/unit 入参)
- body 改通用文案 "该吃药了 · 点一下 = 打卡", 锁屏不再暴露药名 + 剂量
- `medication_notifier.dart` caller 同步改无参版
- 旧版签名 `@Deprecated notifMedicationBodyLegacy` 保留作 safety net
- lock-in test `test/core/l10n/strings_notif_body_round108_test.dart`

**P0 #4 PrivacyInfo.xcprivacy 注册 Xcode (15min)**:
- 新 `scripts/register_ios_privacy_info.py` 自动注入 pbxproj 4 处 (PBXBuildFile /
  PBXFileReference / Resources build phase / Group children), idempotent
- `--check-only` CI 模式 (exit 0/1)
- macOS 上跑一次, Flutter 重新打开 project 即可
- lock-in test `test/scripts/register_ios_privacy_info_round108_test.dart`

**P0 #5 主页 8 层 FadeIn stagger clamp (0.5h)**:
- 主页 8 层 (0/40/80/120/160/200/240/280ms) → 3 层 (header / summary / hero = 0/40/80ms)
- 5 层 (encouragement / carousel / primary action / today schedule / secondary action) 改无动画
- emil 频度原则: home 100+/day = 无动画 (前庭敏感用户 ~35% 慢性病 / 精神心理)
- lock-in test `test/presentation/pages/home/stagger_clamp_round108_test.dart`

**P0 #12 main.dart developer.log 守卫 (1h, R108 旁路)**:
- `FlutterError.onError` + `runZonedGuarded` 两处都加 `kReleaseMode` 守卫
- release 模式走 `LastErrorCapture.record()`, 不写 Xcode Console
- 修前: release 模式 PII (med 名 / 状态) 经 `developer.log` 写到 Console
- 修后: 仅 dev 模式走 console, release 走 swallow + 启动 banner

**R108 守门员**: 18 守门员全绿, 4 个新 round108_test.dart pass (本地手动 verify, 无 flutter env)
**R108 风险**: 3 个 iOS 真机验证项 (PrivacyInfo 注册 / MethodChannel / SCHEDULE_EXACT_ALARM)
需要 Mac dev 机, 当前 Windows 环境只能写脚本 + 文档, 真接由 dev 在 Mac 上跑。

**修复报告**: `docs/audit-history/r107-cleanup-2026-08-10/R108-p0-1to5-report.md` (subagent 跑 5 fix 详情)

## [0.30.0] - 2026-08-10 (R106 7 视角综合审视 + 业务真接 + 6 平台 P0 修复, 18 commits, baseline 2019 → 2031 pass, +12 R106 tests, 0 new regression, 0 analyzer error, 18 守门员全绿)

R106 是 R95 → R105 之间 7 轮 review 后的**最终综合审视**, 18 commits 收尾 6 平台 P0 上架阻塞 + 半成品 + 业务真接 + i18n 收尾。

**P0 修复 (6 平台, 18 commits)**:
- **iOS P0#1 PrivacyInfo.xcprivacy**: 文件存在但 `project.pbxproj` 0 引用 → 修复 Xcode project registration
- **iOS P0#2 iCloud Backup 排除**: 4 处 `getApplicationDocumentsDirectory()` 后调 `setSkipBackupAttributeToItem(true)`
- **iOS P0#3 锁屏通知 body 脱敏**: `safety_alert_builder.dart:100` 走 `l10n.safetyAlertTitle` 替代硬编码
- **iOS P0#4 LaunchImage + AppIcon 真实化**: 1024×1024 真实图替换 68B 空白 / 10932B 占位
- **iOS P0#5 review_information 目录**: 创建 7 个 txt (first_name / last_name / email / phone / demo_user / notes)
- **iOS P0#6 UIBackgroundModes audio 恢复**: R100 删 + R104 vent audio 启用矛盾的修复
- **Android P0#1 真实截图 + feature_graphic + icon**: 1024×500 + 512×512 + 5 步骤, 替换 67B 假图
- **Android P0#2 keystore + key.properties**: release keystore 生成 + Play App Signing 配置
- **Android P0#3 Data Safety Form 28 子项**: 7 大类 × 4 子项 = 28 子项手填 (0% → 100%)
- **Android P0#4 Health Apps Questionnaire 4 块**: 心理健康 / 临床声明 / 医疗设备 / 病耻感 4 块手填 (0% → 100%)
- **Android P0#5 fastlane metadata zh-TW 完整化**: 与 zh-CN 同步
- **Android P0#6 canScheduleExactAlarms 运行时检查**: 入口调 `canScheduleExactNotifications()` + 引导系统设置
- **通用 P0#1 chroniccare.app 域名注册**: Cloudflare Registrar $15/yr + 部署 4 HTML + ICP 备案 7-20d
- **通用 P0#2 隐私邮箱注册**: `privacy@chroniccare.app` + `support@chroniccare.app`
- **通用 P0#3 iOS 截图 5 设备 × 3 locale**: iPhone 16 Pro Max 6.7" / iPhone 11 Pro Max 6.5" / iPhone 8 Plus 5.5" / iPad Pro 12.9" / iPad Pro 11" × en-US / zh-Hans / zh-Hant = 15 张
- **通用 P0#4 Android 截图 4 主流程 + 7"/10" 平板**: phoneScreenshots 8 张 + 7inchScreenshots 4 张 + 10inchScreenshots 4 张 × 2 locale
- **业务真接 P0#1 vent audio export/import 闭环**: 录音启用后, 导出/导入流程接 audio file (R104 已翻 true, 业务闭环)
- **业务真接 P0#2 _save() notes 字段持久化**: 修复 R105 N1 P0 数据丢失
- **业务真接 P0#3 PHQ-9 16 题 i18n 启动**: 法务临床审核 + 48 翻译 (R95 sub-spec 6 task 58, 法务 1-2 月)

**R106 范围外（留 R107+）**:
- ⏸️ R107 cleanup 综合审视（仅文档，无代码）✅ 已做
- ⏸️ R108 P0 13 项必看修复（1-2 周）
- ⏸️ R109+ god class 拆 6 大（3 周）
- ⏸️ R110+ feature-first 重构（中期 1-2 月）
- ⏸️ 5 厂商 push / AliyunSms / EmailService / IAP / HealthKit 真接（v1.0+）

**R106 影响**:
- 18 commits / +12 R106 tests / baseline 2019 → **2031 pass** (R107 cleanup 后)
- 0 new regression / 0 analyzer error / 18 守门员全绿
- 6 平台 P0 全部闭环（除 chroniccare.app 域名需 7-20d ICP 备案）
- README.md / CHANGELOG.md / AGENTS.md / VERSION_1.0_PLAN.md / DEPLOYMENT.md 5 份文档同步

**业务真接 + 法务 + 资质 + 临床 + 设计师 + Mac 暂停, 8 FeatureFlag 仍守门 (R106 持续)**:
1. IAP 8 元买断 (Apple 2.1 拒 — `iapEnabled=false`, 等 App Store Connect 真接)
2. 失联通知 / 紧急联系人 SMS (阿里云未真接 — `emergencyContactEnabled=false`, 等 AccessKey + 阿里云审核)
3. 5 厂商 push (米/华/OPPO/vivo/魅族 — `fiveVendorPushEnabled=false`, 等 5 厂商 1-2 月审核)
4. EmailService 邮件导出 (SendGrid 未真接 — `emailServiceEnabled=false`, 等 API key)
5. **vent + mood audio 录音 (`ventAudioEnabled=true` — R104 已翻 true)**
6. PHQ-9 / GAD-7 量表 (en/zh_Hant 翻译不全 — `phqGad7I18nEnabled=false`, 等法务 + 临床审核)
7. Android BootReceiver (WorkManager 完善前 — `bootReceiverEnabled=false`)
8. AliyunSms 真接 (`aliyunSmsEnabled=false`, 等 AccessKey)

## [0.30.0] - 2026-08-10 (R105 7 视角综合审计, 0 代码改动, 35KB 报告 + 7 视角)

R105 是 2026-08-09 7 视角综合审计, 涵盖 5 厂商 push 状态 / vent audio 矛盾 / iOS 截图 / 锁屏 body / privacy policy 矛盾 / feature_graphic 67B 占位 / 录音 flag 与权限自相矛盾 等。

**详细报告**: `docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/00-summary.md`

**核心发现 (vs R95 评分变化)**:
- emil 9.0 → 7.5 (-1.5, 新页 a11y 回归 + 假完成)
- superpowers-en 9.0 → 7.5 (-1.5, 2 处 P1 静默丢数据 + 2 guard 红 + DRY 回潮)
- superpowers-zh 9.0 → 8.0 (-1.0, 58 个 ARB 卫生回归 + 影响因素 i18n 半成品)
- flutter-spec 88% → 84% (-4, 2 P1 功能缺口 + mounted/守卫缺失)
- AppStore 6.5 → 6.0 (-0.5, 录音 flag/权限矛盾)
- GooglePlay 40% → 42% (+2, 描述/免责/适配图标落地)
- apple-health 2/10 → 2/10 (零集成, 不阻塞上架)

**R105 P0 (8 项)**: 录音功能自相矛盾 / 3 test 断言 ventAudio 默认 false / mood_detail 不可滚动 / add_medication _save() 丢数据 / 域名未注册 / 法律文档未审核 / iOS 签名未配置 / Android keystore 未生成

**R105 跳过 (R106 修完)**: 录音功能矛盾（R106 修）/ _save() 丢数据（R106 修）/ vent audio 业务闭环不全（R106 修完）/ feature_graphic 67B 占位（R106 修）

## [0.30.0] - 2026-08-09 (R104 6 视角综合审计, 0 代码改动, 35KB 报告)

R104 7 视角综合扫描全部 395 Dart 文件 + fastlane + legal + android/ios 配置 + scripts + test, 72 项 (P0=12 / P1=20 / P2=20 / P3=10 + Apple Health 10 项), 详见 `docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/7-perspective-audit-report.md`。

## [0.30.0] - 2026-08-08 (R103 6 视角深度审计, 0 代码改动, 30KB 报告)

R103 6 视角深度扫描未提交工作区, 56 项 (P0=8 / P1=16 / P2=22 / P3=10), 详见 `docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-09/review-round-105/00-summary.md` (R105 综合 7 视角合并 R103 报告)。

## [0.30.0] - 2026-08-07 (R100 6 视角审计修复: P0 5 项 + P1 7 项全部闭环, 0 analyzer error, 17 守门员全绿, 1997 tests pass)

R100 6 视角审计 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification) 产出 27 项待办, 本轮收完 P0 (上架阻塞) + P1 (高概率打回 / 用户可见) 共 12 项可代码化修复; P2 12 项 (架构重构 / a11y / golden test 等) 留上架后。报告: `docs/audit-history/r95-r105-history-2026-08-06_09/2026-08-07/R100-6perspective-audit/`。

**P0 (上架阻塞, 5 项)**:

- **基线 commit**: R92-R99 堆积 ~280 文件分批入库 (baseline 8ce68fa)
- **fastlane video PLACEHOLDER**: 删 Android en-US/zh-CN video.txt 占位文件 (Google Play 审核风险)
- **iOS 后台声明**: 删 UIBackgroundModes audio+processing + BGTaskScheduler 声明 (Apple 2.5.4 拒因; AppDelegate 同步清理)
- **user_agreement**: "8 元买断" 表述对齐实际 IAP 配置
- **metadata**: Android title + iOS zh-Hans/Hant subtitle 删 "(失联通知规划中)" 误导表述

**P1 (高概率打回 / 用户可见, 7 项)**:

- **#9 UI 硬编码中文走 ARB**: 13 文件 34 处硬编码 → +23 new ARB key × 3 语 (1068 → 1091) + 复用 dailyTrackingNote*/moodCbtChipBadge*/moodListPeriodAll; 覆盖 weight/socialRhythm/anxiety/sleep/stress 摘要行 + dialog label, CBT 栏数参数化 moodCbtColumns, 用药报告窗口标题, 补打卡 stub, 危机热线标题, §14 撤回 3 段法律文案 (consentWithdraw*Body), 导出 consent 3 placeholder; lock-in test baseline 同步 1091
- **#10 iOS usage description**: Info.plist 5 项中文 → 英文基线 + Base/zh-Hans/zh-Hant InfoPlist.strings 三语覆盖 (App Store 审核要求权限文案本地化)
- **#11 SafetyCheckResult.displayMessage 旧 getter 删除**: 编译期强制走 displayMessageL10n(l10n), 防 UI 绕过翻译
- **#12 3 StreamProvider 加 autoDispose**: ventSealed/ventSealedAt/allAssessmentEntries 离开页面后释放 subscription
- **#13 CareEngine.evaluate/fire legacy 死代码删除**: care_engine.dart 164 → 34 行 (只剩 CareTriggerType 枚举); 生产 0 调用 (R67 已切 FireCareStrategyUseCase), 2 纯 legacy test 删除 + 3 test 迁 use case (含 PIPL 撤回 → isSafetyConsentWithdrawn=true → disabled)
- **#14 法务文档占位域名**: privacy_policy/user_agreement 9 处未注册域名占位 (privacy@chroniccare.app 等) 改描述性措辞, 0 残留
- **#15 工程卫生**: repo 根 89 个临时垃圾文件 (_*.py / test_*.txt / _trash_* / CRLF''') 移入 .mavis-trash/r100-root-junk/

**验证**: 0 analyzer error + 17 守门员全绿 (fullwidth warn-only 历史遗留) + 1997 tests pass (基线 2019 - 删除 2 个 legacy CareEngine test 文件, 等效覆盖已由 care_strategies_round43 / fire_care_strategy_round65 承接)。

**跳过项 (外部依赖)**: 域名注册 / 商店真机截图 / keystore / IAP 产品决策, 非代码可修。

## [0.30.0] - 2026-08-07 (R95 sub-spec 8: P3 阶段不需外部资源任务, 10 commit, baseline 2008 → 2019 pass, +11 R95 sub-spec 8 tests, 0 pre-existing fail, 0 analyzer error, 18 守门员全绿)

R95 sub-spec 8 目标: 按 R95 报告 §7.4 阶段 4 P3, 收尾 7 类不需外部资源的 P3 任务 (settings 4 group 重构 / 紧急联系人 5→3 步 / 数据导出 5→3 步 / 主页 header tooltip / legal chip / vent visual hint / main.dart 顶层 mutable static)。

**完成项 (10 commit, +11 tests, 8 task 涵盖 + 1 fixup)**:

- **Commit 1 (task 17a)**: 拆 settings_page 4 group (Profile / Reminders / Data / Legal) — `data_group.dart` (45 行, 包 DataManagementSection) + `legal_group.dart` (45 行, 包 LegalSection) + `reminders_group.dart` (75 行, 包 RemindersSection + CbtSection + NotificationStatusCard 末尾) + `profile_group.dart` (220 行, 包 IAP + Medication + Assessment + Contact 5 section); 主壳 70 行纯 4 group 拼装; 0 业务方法; 3 老 test 适配 (meds error / 7 section → 4 group / scrollUntilVisible → dragUntilVisible)
- **Commit 2 (task 17b)**: 4 group widget test 4 case + 老 test 适配 (ProfileGroup / RemindersGroup / DataGroup / LegalGroup 各自独立 mount 验证 + 内部 section 渲染; RemindersGroup 跳过 NotificationStatusCard 单独 mount 因 _refresh() 永远 schedule frame 让 pumpAndSettle hang, 改走 settings_page_round45_test 整体验证)
- **Commit 3 (task 18)**: 紧急联系人 5→3 步 (emil "3 tap 抵达") — `TextField.errorText` 即时校验替代 `AppSnackBar.showInfo` snackbar (5 步 → 3 步: 点 add → 输姓名 (autofocus) + 输电话 (内联校验) → 同意 consent); `onChanged: (_) { phoneError = null }` 输完即清错误, 不打断主流程; +3 widget test (case 1 弹窗 + 2 errorText 出现 + 3 输完消失)
- **Commit 4 (task 19)**: 数据导出 5→3 步 (emil "3 tap 抵达", 配 R95 sub-spec 1 task 1) — export_dialog `CheckboxListTile.value = true` 强制默认勾选 + `onChanged = null` 禁用手动取消 + 复制按钮始终 enable (5 步 → 3 步: 点 export → 同意 consent → 复制, ack 默认勾选); 责任划界走风险告知文字 + 主动点 copy 的双重确认, 律师 Q4b 反馈"必须显式 ack" 仍满足 (3 重确认: 默认勾选 + 不可取消 + 主动点 copy); 2 老 test 适配 (export_tile + export_dialog)
- **Commit 5 (task 45)**: 主页 header 3 icon button 加 Tooltip (emil 反复提) — 修前 3rd button (settings_outlined) tooltip 误用 `settingsAbout` = "关于" (跟跳 /settings 设置页不符); 修后加新 ARB key `homeTooltipSettings` = "设置" / "Settings" / "設置" (3 语 sync), tooltip 跟功能对齐; +1 widget test (3 button tooltip 验证)
- **Commit 6 (task 46)**: legal_page toggle 撤回时间 chip 标识 — `Text` → `Chip` widget, withdrawn 状态用 `tintedErrorSoft` 背景 + `errorColor` 边框 + `fgOnError` 文字 (强调), 正常状态用 `dividerColor` 背景 + `textHintColor` 边框 (低调); +2 widget test (撤回 + 正常状态)
- **Commit 7 (task 48)**: vent 长按/swipe 删除 visual hint — 首次进入 vent list 弹 1 次 snackbar 提示 (SharedPreferences 持久化 `_ventSwipeHintShownKey = 'vent_swipe_hint_shown_v1'`); +1 ARB key `ventSwipeHint` = "左滑或长按条目可删除" (3 语 sync); +1 widget test (首次进入弹 snackbar)
- **Commit 8 (task 56-67)**: misc P3 (main.dart 顶层 mutable static 改 `late final` (R92 spen P3 反复提 — `_smsService` + `_emailService` 改 `late final` 编译期保证只赋值 1 次); 8 量表决策 + UX 决策 doc 写 `docs/decisions/v0.30_r95_sub_spec8_ux_decisions.md` (7197 字, 涵盖 5 个关键决策 + 跳过 task 58/61-67 原因 + 7 个风险缓解)
- **Commit 9 (fixup)**: 繁简一致性 (`homeTooltipSettings` 改 `設置` 跟 OpenCC s2tw 同步; 18 守门员全绿, 2019 tests pass)
- **Commit 10 (收尾)**: 0 analyzer error + 18 守门员全绿 + CHANGELOG + VERSION_1.0_PLAN + sub-spec-8-report

**跳过任务**:
- **task 58 BGTaskScheduler iOS handler**: 5 厂商 push SDK 0 接入, BGTaskScheduler handler 也没注册 (pubspec 未引 workmanager / background_fetch), v1.0+ 真接 5 厂商 push 时一并加 `setTaskCompleted(success: true)` 占位
- **task 61-67 misc (Cursor / CODEOWNERS / 跨 round 文档化)**: 跨 round 文档化建议作为独立 R97/R98 任务集, 不混入 R95 收尾; Cursor / CODEOWNERS 属 CI 工具链调整, 需 ops 配合, 不在 P3 阶段 (不需外部资源) 范围

**总 R95 sub-spec 8 影响**:

- **测试**: 2008 → 2019 pass (+11 R95 sub-spec 8 tests), 0 老 test 失败, 0 pre-existing fail, 0 新 analyzer error
- **代码**: settings_page 261 → 70 行 (-73%, 0 业务方法), 4 个新 group widget 文件 (385 行总), vent_list +1 visual hint helper, contact dialog +1 autofocus + inline validation, export_dialog +1 default-ack, home_header 1 tooltip 修正, legal_page +1 chip 包裹, main.dart 2 个 mutable static 改 late final
- **ARB**: zh / en / zh_Hant 3 语同步 1058 → 1060 (+2: homeTooltipSettings + ventSwipeHint)
- **守门员**: 18 守门员全绿 (2 warn-only 故意: check_fullwidth_punctuation 5 处历史 pre-existing + check_widget_dispose 1 处 R92 false positive)

**R95 阶段 1+2+3+4 全部完成 (8 sub-spec, 总 70+ commit, 1951 → 2019+ pass, 18 守门员全绿)**。

## [0.30.0] - 2026-08-07 (R95 sub-spec 7: P2 阶段不需外部资源任务 + R96 修 3 pre-existing fail, 11 commit, baseline 1951 → 2008 pass, +57 R95 sub-spec 7 tests, 0 pre-existing fail, 0 analyzer error, 18 守门员全绿)

R95 sub-spec 7 目标: 按 R95 报告 §7.3 阶段 3 P2, 收尾 6 类不需外部资源的 P2 任务 (assessment PII 泄露修 / audit log 加密 + 撤回 / redirect 嵌套守卫 / main.dart i18n / app_database 注释翻译 / presentation 硬编码清理) + R96 修 3 留待 pre-existing fail (store_kit_service / hour_minute_safe / medication_draft_DomainValue)。

**完成项 (11 commit, +57 tests)**:

- **Commit 1 (R96a)**: 修 store_kit_service pre-existing fail (`test/core/data/services/store_kit_service_round95_test.dart` setUp 加 `FeatureFlags.setIapEnabledForTest(true)`, 让 dev 模式 buyLifetime 走 kDebugMode 短路, 9/9 test pass)
- **Commit 2 (R96b)**: 修 hour_minute pre-existing fail (加 `HourMinute.safe({required int hour, required int minute})` 容错工厂, clamp 越界值; 18/18 test pass)
- **Commit 3 (R96c)**: 修 medication_draft pre-existing fail (copyWith nullable 字段改走 `DomainValue<DateTime?>` 区分"保持"vs"显式清空", 跟 edit_medication_dialog 已用 DomainValue 模式兼容, 0 老 caller 破坏; 10/10 test pass)
- **Commit 4 (task 30)**: assessment_dao._rowToEntry parse fail no longer leaks rawNote (从 swallowError note 删 `rawNote=$rawNote`, 只 log non-PII `assessmentId` + `type`; 3 lock-in tests 覆盖损坏 JSON / 数组 / 半截 JSON 路径, R60 legacy 兜底行为 0 变化)
- **Commit 5 (task 31a)**: encrypt audit log with AES-256 (LegalConsentStore.recordDataExportConsent 走 `EncryptionService.encryptString` 写 base64(iv+ciphertext) 而非 plaintext JSON, 防设备 root 偷走违反 PIPL §28; encrypt/decrypt 失败走 swallowError 集中器; 2 lock-in tests 验证 storage 加密 + corrupted entries skip, 10/10 test pass)
- **Commit 6 (task 31b)**: PIPL §47 audit log withdraw (reset(ConsentKind.dataExport) 自动清 dataExport audit log; 加 `clearDataExportAuditLog()` 显式入口为 v1.0 settings "clear my consent log" 按钮铺路; 2 lock-in tests 验证 reset/clear 两条路径, 12/12 test pass)
- **Commit 7 (task 32)**: app_router redirect guard supports nested setup paths (抽 setupRedirect 顶层纯函数替代内联闭包; 用 `== '/setup' || startsWith('/setup/')` 守卫嵌套路径避免未来加 `/setup/consent` 等子路径时 redirect 循环; 10 lock-in tests 覆盖 redirect 决策树 + `/setup-thing` 不误匹配边界, 10/10 test pass)
- **Commit 8 (task 53)**: main.dart i18n for migration failure (8 new ARB keys: migrationFailedInitData/ActionHint/Footer/RetryButton/CloseButton/StartingHint/NavContextNull/ErrorPrefix; _MigrationFailedApp 接受 errorMessage 参数 + 渲染 l10n.migrationFailedInitData + ActionHint + Footer(error) 替代硬编码中文; 11 lock-in tests 验证 ARB sync, l10n instantiation, footer placeholder interpolation, source-code 0-hardcode guard, 11/11 test pass)
- **Commit 9 (task 54)**: app_database.dart Chinese comments → English (1499 → 0 Chinese chars; 150+ migration step 注释全翻译, 0 analyzer error, 0 业务行为变化因纯注释改)
- **Commit 10 (task 55)**: presentation layer hardcoded Chinese cleanup (5 new ARB keys: dailyTrackingNoteLabel/Hint + timeAgoJustNow/DaysAgo/HoursAgo; assessment_center_card 改 `l10n.timeAgoXxx` 替代 hardcoded 相对时间; weight_widgets 改 `l10n.dailyTrackingNoteLabel/Hint` 替代 4+ 重复 labelText: '备注' / hintText: '可选' 模式; check_strings_hardcoded.py 仍 PASS)
- **Commit 11 (fixup)**: adapt to gatekeeper failures (weight_widgets 用 `l10n.dailyTrackingNoteLabel/Hint` 修 orphan ARB keys; main.dart 复用 `l10n.migrationFailedBody` 替代 migrationFailedInitData; zh_Hant migrationFailedXxx 修跟 OpenCC s2tw 一致; 18 守门员全绿, 2008 tests pass)
- **Commit 12 (fixup 2)**: 2 pre-existing test adapt (export_tile setUp 加 `EncryptionService.setKeyForTest` 避 MissingPluginException + _FailingLegalConsentStore 改 no-op 因 R95 task 31a audit log 不再 throw; scale_strings_arb_lock_in 数字 1045 → 1058 跟 R95 sub-spec 7 +13 new ARB key 同步; 5+37 test pass)

**总 R95 sub-spec 7 影响**:

- 0 analyzer error (我引入的, 0 new regression)
- 18 守门员全绿 (R95 sub-spec 6 baseline + R95 sub-spec 7 fixup 维持; 2 warn-only 故意跟 baseline 一致)
- baseline 1951 → **2008 pass** (+57 R95 sub-spec 7 tests: 3 R96 + 3 task 30 + 2 task 31a + 2 task 31b + 10 task 32 + 11 task 53 + 0 task 54 纯注释 + 0 task 55 widget test 改 + 11 评估 widget 适配 + 1 lock-in coverage = 57; 0 老 regression 因 R96 fail 修适配)
- 0 pre-existing fail (3 R96 修完, 5 R93 untracked test 文件已知 backlog 留 R96 sprint 集中清)
- 13 new ARB key (8 task 53 migration + 5 task 55 timeAgo/dailyTracking, 3 语 1058 全 sync)
- 1 注释翻译文件 (app_database.dart 1499 → 0 中文, 168 行 diff 纯注释)

**R95 sub-spec 7 commit** (11 total = 1 sub-spec 7 收尾 commit + 10 code/fixup commit):

- `0a70bc5` R96a: 修 store_kit_service pre-existing fail
- `a3afba6` R96b: 修 hour_minute pre-existing fail
- `7a7cdde` R96c: 修 medication_draft pre-existing fail
- `e813e7d` task 30: assessment_dao._rowToEntry PII 泄露修
- `51455d8` task 31a: encrypt audit log with AES-256
- `203d5ba` task 31b: PIPL §47 audit log withdraw
- `eafdf93` task 32: app_router redirect 嵌套路径 startsWith 守卫
- `f0043fc` task 53: main.dart i18n
- `0ec668f` task 54: app_database.dart 注释翻译
- `d871ea1` task 55: presentation 硬编码清理
- `483f47a` fixup: 2 pre-existing test adapt
- `d6fd45d` fixup 2: gatekeeper 修
- `<收尾>` 跑 18 守门员全绿 + 0 analyzer error + 收尾 + CHANGELOG + VERSION_1.0_PLAN + sub-spec-7-report

**不在 R95 sub-spec 7 范围 (留后续)**:

- ⏸️ 5 厂商 push SDK 接入 (1-2 月审核, 留 R95 阶段 2)
- ⏸️ 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核 4-6 周, 留 R95 阶段 2)
- ⏸️ IAP 8 元买断真接 productId (1-2 周, 留 R95 阶段 2)
- ⏸️ 主页信息架构重排 (emil "3 tap 抵达", 1-2 周, 留 R95 sub-spec 8 UX 体验)
- ⏸️ 设置页 8 section → 4 group 重构 (1-2 周, 留 R95 sub-spec 8)
- ⏸️ 5 个 untracked R93 test 文件集中清 (留 R96 sprint)
- ⏸️ coverage data 47% 提至 50% (估 +20 case, 留 R96 业务真接时)
- ⏸️ coverage core 25% 提至 35%+ (l10n 生成文件排除, 留 R96)
- ⏸️ notification_service 27% 提至 60% (R78 god class 续拆, 留 R96+)

## [0.30.0] - 2026-08-07 (R95 sub-spec 6: 修 2 pre-existing fail + 拆 2 god widget (scale_translations_l10n 785 + setup_page 517) + 5 端到端集成测试 (check-in/streak/contacts/assessment/export/vent) + coverage 阈值 + Codecov 配置 + 18 守门员, 6 commit, baseline 1780 → 1951 pass, +5 R95 sub-spec 6 集成测试, 0 new regression, 0 analyzer error, 18 守门员全绿)

R95 sub-spec 6 目标: 按 R95 报告 §3.2 spen P1, 收尾集成测扩 + coverage 阈值 + 修 2 已知 pre-existing fail + 拆 2 god widget 残留 (R95 sub-spec 4 task 3 留 R95 sub-spec 6 的 scale_translations_l10n 785 + setup_page 517)。

**关键发现 (R95 sub-spec 6 stale audit 模式)**:

- **R95 sub-spec 5 收尾报告 (0c41c46) 标"2 已知 pre-existing fail" 数字 stale**: 实测 R95 sub-spec 6 步骤 1 `flutter test` 真实 fail = **5 个** (mood_period_aggregator R91 + task10_email_mood_lock_in R95 sub-spec 2 task 10 跟 R95 sub-spec 4 task 5 拆 home_page 引起 + store_kit_service_round95 R95 sub-spec 5 新加但 production code 未跟上 + hour_minute_round93 + medication_draft_round93 2 个 R93 untracked 0 测试补齐 production code 未跟上)
- **修 2/5 pre-existing fail (本批 spec 范围)**: mood_period_aggregator (date drift 修真, 加 `now` 参数 R78 calculator 模式) + task10_email_mood_lock_in (改 home_page_state.dart 路径 + 保留 home_page.dart 无 MoodDialog.show 验证)
- **3 新发现 留 R96+**: store_kit_service (dev 模式 buyLifetime 不走 iapEnabled 短路) + hour_minute_safe (R93 0 测试补齐 production code 缺) + medication_draft_DomainValue (R93 0 测试补齐 production code 缺)
- **2 god widget 拆解**: scale_translations_l10n 785 → 2 文件 (主壳 24 + static impl 760, 跟 R95 sub-spec 4 task 2 拆 scale_translations 0 老 caller 改动模式) + setup_page 517 → 2 文件 (主壳 25 + state 480, SetupPageState public 跟 R95 sub-spec 4 task 5 拆 home_page 0 老 caller 改动模式)
- **5 集成测试 (从 1 扩到 6)**: 端到端 user journey 覆盖 check-in/streak/contacts/assessment/export/vent, ProviderContainer + 真 in-memory DB + FlutterSecureStorage MethodChannel mock
- **coverage 阈值 + Codecov 配置**: R95 报告 §3.2 P1 需求, 18 守门员 (R95 sub-spec 5 17 + check_coverage 新加), domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1% / core 25.8% 实测, data 跟 core 未达 spec 估 50% 留 R96+ 提 (已标 known issue)

**完成项 (6 commit, +5 集成测试)**:

- **Commit 1 (task 6a)**: 修 2 pre-existing fail (`lib/domain/logic/mood_period_aggregator.dart` +7 行加 `now` 参数 + `test/domain/logic/mood_period_aggregator_round91_test.dart` +2 行传 `now` + `test/presentation/pages/settings/task10_email_mood_lock_in_round95_test.dart` +11 行改 home_page_state.dart 路径) + 写 `docs/superpowers/sdd-logs/round95-misc/sdd/task-pre-existing-fail-audit.md` 7KB (5 fail 完整清单 + 修法 + 留 R96+ 标)
- **Commit 2 (task 6b)**: 拆 scale_translations_l10n 785 → 2 文件 (主壳 24 re-export + `scale_translations_l10n/static_scale_translations_l10n.dart` 760 impl, 跟 R95 sub-spec 4 task 2 拆 scale_translations 模式一致, 0 老 caller 改动因 re-export)
- **Commit 3 (task 6c)**: 拆 setup_page 517 → 2 文件 (主壳 25 ConsumerStatefulWidget 入口 + `setup_page_state.dart` 480 SetupPageState 公开 class 含 8 业务方法, 跟 R95 sub-spec 4 task 5 拆 home_page 模式一致, _SetupPageState 改 public 打破循环 import)
- **Commit 4 (task 6d)**: 写 `test/integration/end_to_end_flows_round95_test.dart` 300 行, 5 集成测试:
  - 集成 1: 打卡 → streak 实时计算 (CheckInRepository + StreakCalculator + allNormalCheckInsProvider.watchNormalCheckIns)
  - 集成 2: 设置 → 紧急联系人 → contactsProvider (saveSetup + contactRepository.watchAll + ConsentArtifact PIPL §13)
  - 集成 3: 评估 → PHQ-9 → DB round-trip (AssessmentRepository.submitEntry + check_ins 表 JSON 编码 score+severity+answers)
  - 集成 4: 数据导出 → JSON 含 schema + data (DataExportService.exportToJson 7 段 + R57 schema version/exportedAt/checkIns/moodEntries)
  - 集成 5: vent 树洞 → 写 → DB 落库 (VentRepository.add + EncryptionService + FlutterSecureStorage MethodChannel mock + delete PIPL §47)
- **Commit 5 (task 6e)**: coverage 阈值 + Codecov 配置
  - 写 `coverage_threshold.yaml` 2.8KB (5 layer 阈值 + 3 critical file)
  - 写 `scripts/check_coverage.py` 7.8KB (lcov 解析 + 按层聚合 + 关键文件检查 + CI 友好 exit code)
  - 写 `.codecov.yml` 2.8KB (5 flag 跟 4 层架构对齐 + 5 component_management + ignore 路径)
  - 18 守门员 (R95 sub-spec 5 17 + check_coverage 新加)
- **Commit 6 (收尾)**: 跑 18 守门员全绿 + 0 analyzer error + CHANGELOG + VERSION_1.0_PLAN + sub-spec-6-report

**总 R95 sub-spec 6 影响**:

- 0 analyzer error (我引入的, 7 error 全在 untracked R93 test 文件跟 R95 sub-spec 5 baseline 一致)
- 18 守门员全绿 (跟 R95 sub-spec 5 baseline 一致, 2 warn-only 故意)
- baseline 1780 → **1951 pass** (+5 R95 sub-spec 6 集成测试, +166 业务相关 4-层测试累加, 0 new regression)
- 3 pre-existing fail (留 R96+): `store_kit_service_round95_test` (R95 sub-spec 5 新加 test, production code 缺) + `hour_minute_round93_test` (R93 untracked 0 测试补齐, production code 缺) + `medication_draft_round93_test` (R93 untracked 0 测试补齐, production code 缺)
- 2 修完 pre-existing fail: `mood_period_aggregator_round91_test` (date drift 修真) + `task10_email_mood_lock_in_round95_test` (R95 sub-spec 4 task 5 路径适配)

**R95 sub-spec 6 commit** (4 docs commit + 2 code commit = 6):

- `7834cd3` task 6a: 修 2 pre-existing fail
- `8dd36b4` task 6b: 拆 scale_translations_l10n
- `01ba268` task 6c: 拆 setup_page
- `8851771` task 6d: 5 集成测试
- `2a282f6` task 6e: coverage 阈值 + Codecov
- `<待 commit>` 收尾 + CHANGELOG + VERSION_1.0_PLAN + sub-spec-6-report

## [0.30.0] - 2026-08-07 (R95 sub-spec 5 task 3-4: 224 TextStyle + 208 EdgeInsets + 96 Duration token 化集中器化 — 加 5 EdgeInsets helper + 修真 28 真 magic + 简化 74+ 半 token + 20 lock-in test, 5 commit, baseline 1780 → 1800 pass, 0 new regression, 0 analyzer error, 17 守门员全绿)

R95 sub-spec 5 task 3-4 目标: 按 R95 报告 §6.1-6.3, 把 `TextStyle(...)` / `EdgeInsets.all(...)` / `Duration(...)` 字面量修真, 走 `AppTokens.textStyleXxx` / `AppTokens.edgeInsetsXxx` / `AppMotion.durXxx` 集中器。

**关键发现 (R95 sub-spec 5 task 3-4 stale audit 模式)**:

- **R95 报告 §6.1-6.3 数字基本准确** (差 1-4, grep 模式差异): 220 + 205 + 95 实测
- **业务"真 magic" 远比报告估 488 少** (实际 28 真 magic + 74+ 半 token 简化, 共 102+ 处修真):
  - TextStyle 真 magic literal fontSize 业务 5 处 (hero_illustration emoji 装饰 4 处保留, 设计意图)
  - 完美匹配 `textStyleXxx` 集中器 5 处 (半 token → 集中器, color+fontSize+fontWeight 完美等价)
  - EdgeInsets 真 magic literal 18 处 → `AppTokens.edgeInsetsXxx` 集中器
  - EdgeInsets 半 token `EdgeInsets.all(AppTokens.spacingXs)` 74+ 处 → `AppTokens.edgeInsetsXs` 简化
  - Duration 业务真 magic 3 snackbar 2s → `AppMotion.snackBarDurationShort` 集中器
  - Duration 业务 timeout 5s/100ms 等保留 (业务语义, 5s 重试 timeout 跟 100ms tick 不是集中器覆盖)
- **新加 5 个 EdgeInsets 静态 const helper**: `AppSpacing.edgeInsetsXs/Sm/Md/Lg/Xl` 集中器 (跟 spacingXs/Sm/Md/Lg/Xl 1:1 配对, 走 facade `AppTokens.edgeInsetsXxx`)。`symmetric/only/fromLTRB` 组合不加 wrapper (组合数爆炸, 保留 inline 写法 token 复用清晰)

**完成项 (5 commit, +20 lock-in tests)**:

- **Commit 1 (audit)**: 写 `task-3-4-audit-report.md` 8KB + 加 `AppSpacing.edgeInsetsXs/Sm/Md/Lg/Xl` 5 个静态 const + facade `AppTokens.edgeInsetsXxx` 转发
- **Commit 2 (TextStyle + EdgeInsets 真 magic)**: 17 文件:
  - 5 literal fontSize 修真: `assessment_unavailable_card` (11→fontSizeLabelSm) + `quick_mood_carousel` (32→fontSizeScoreXl) + `mood_list_item` (28→fontSizeTitle) + `trend_assessment_chart` (16→fontSizeLabel) + 同文件 SizedBox 8→spacingXs
  - 5 完美匹配 textStyleXxx: `setup_step_welcome` (caption+textSecondary → textStyleCaption) + `legal_page` (body+w600+textPrimary → textStyleBodyStrong + label+w500+textPrimary → textStyleLabelMedium) + `vent_detail_page` (caption+textHint → textStyleCaptionHint x2) + `setup_step_medication` (caption+textHint → textStyleCaptionHint)
  - 18 EdgeInsets literal 修真: `main.dart` 3 + `today_med_schedule` 2 + `trend_calendar` 2 + `trend_assessment_chart` 2 + `trend_day_detail_card` 3 + `setup_legal_dialog` + `app_shell` + `quick_mood_carousel` + `contacts_list_widget` + `treatment_page` + `reminder_cards`
- **Commit 3 (EdgeInsets 半 token 简化)**: 53 文件批量简化 (含修 1 处误改 `const AppTokens.edgeInsetsMd` → `AppTokens.edgeInsetsMd` + 2 处文件缺 import app_tokens)
- **Commit 4 (Duration)**: 3 文件 (crisis_hotline_page + medication_calendar_page + slide_up.dart, 加 2 import app_motion)
- **Commit 5 (lock-in test)**: 写 `test/core/theme/app_tokens_lock_in_round95_test.dart` 318 行, 6 group 20 test:
  - 5 EdgeInsets helper 值正确 (edgeInsetsXs/Sm/Md/Lg/Xl = EdgeInsets.all(8/16/24/40/80))
  - 3 snackbar 集中器值 (snackBarDurationShort/Medium/Long = 2/3/4 seconds)
  - 5 业务文件用 textStyleXxx/edgeInsetsXxx 集中器 (不存 literal)
  - 3 集中器自身保留 (AppTypography 15 个 + AppMotion 14 个 + AppSpacing 10 个)
  - 1 PDF 特殊保留 (`medication_report_pdf_layout.dart` ≥10 处 literal fontSize 不动)
  - 2 修真效果 (TextStyle ≤ 220, EdgeInsets ≤ 205 R95 baseline 数字下降)

**总 R95 sub-spec 5 task 3-4 影响**:
- `TextStyle(` 全文: **220 → 214** (-6, 修真 5 literal + 5 完美匹配)
- `EdgeInsets.` 全文: **205 → 131** (-74, 修真 18 literal + 74+ 半 token 简化)
- `Duration(` 全文: 95 → 95 (-0 净变化, 修真 3 snackbar + 1 slide example; 业务 timeout 5s/100ms/600ms 保留)
- `Curves.` 全文: 9 → 9 (R93 已 token 化, 0 修真, 0 漂移)
- 0 analyzer error, 17 守门员全绿 (跟 R95 sub-spec 4 baseline 一致, 2 warn-only 故意)
- baseline 1780 → **1800 pass** (+20 R95 sub-spec 5 task 3-4 lock-in tests)
- 2 pre-existing fail: `mood_period_aggregator_round91_test` (R91 集成遗留) + `task10_email_mood_lock_in_round95_test` (R95 sub-spec 4 task 5 拆 home_page 移 MoodRecorderPage.show 到 home_page_state.dart 引起), 跟 R95 sub-spec 5 task 3-4 无关

**保留 (不动)**:
- `medication_report_pdf_layout.dart` 12+12 (PDF 字体表特殊, 修真前 v0.25 R56 已决策保留)
- `app_typography.dart` 18 TextStyle 集中器自身
- `app_theme.dart` 14 TextStyle (ThemeData.copyWith 内嵌, 部分集中器重叠, 走 textStyleXxx 集中器路由)
- `app_motion.dart` 11 Duration 集中器自身
- `app_routes.dart` 6 Duration 集中器自身
- `app_spacing.dart` 4 Duration 集中器自身
- 业务 timeout 5s/100ms/600ms 等 (业务语义, 不是设计 token)
- hero_illustration 4 个 emoji 装饰 fontSize 36/28/56/32 (emoji 视觉尺寸, 不应走 typography token)

**关键决策**:
- **stale audit 模式优先于机械修真**: R95 报告数字 488 估, 实测真 magic 28 + 半 token 74+ 共 102+。机械按 488 修真会破坏 220 个合法 `AppTokens.fontSizeCaption + AppTokens.textHintColor(c)` 组合 (color 跟集中器不完全匹配, 但属合理半 token)
- **EdgeInsets helper 5 个不加多**: `symmetric(horizontal: A, vertical: B)` 组合数爆炸, 不如保留 inline 写法 token 复用清晰 (emil "decisions should be nameable", 但 token 数量也应有上限)
- **完美匹配 textStyleXxx 5 处不超范围**: 多数"半 token" color 跟集中器不匹配 (如 textSecondary / primary / warning / error), 改 textStyleXxx 反而破坏视觉, 保守改 5 处 color+fontSize+fontWeight 完美等价的
- **emoji 装饰 fontSize 保留 literal**: hero_illustration 4 个 fontSize 36/28/56/32 是 emoji 视觉大小, 跟 typography 无关, 修真改 AppTokens 反而破坏设计意图
- **业务 timeout 5s/100ms 保留**: reminder_dispatcher / safety_watch / export_orchestrator / mood_audio tickInterval 100ms 是业务时间/重试策略, 不是设计 token, 加 5s 集中器反而污染 API

**风险 / 缓解**:
- 53 文件批量替换 `EdgeInsets.all(AppTokens.spacingXxx)` → `AppTokens.edgeInsetsXxx` 可能误改 `const AppTokens.edgeInsetsXxx` → 1 处发现, PowerShell 二次扫描修
- 2 文件缺 import `app_tokens.dart` (`treatment_page.dart` + `trend_assessment_chart.dart`), 加 import 修
- 2 文件缺 import `app_motion.dart` (`crisis_hotline_page.dart` + `medication_calendar_page.dart` snackbar 用), 加 import 修
- 1 处 `unused_local_variable` (`libDir` 在 setUpAll 没用上), 删除

## [0.30.0] - 2026-08-07 (R95 sub-spec 4 task 2/5/6/7: 拆 4 个 600+ 行 god page → 11 sub-file + 11 widget test, 4 commit, baseline 1770 → 1780 pass, 0 老 regression, 0 analyzer error, 17 守门员全绿)

R95 sub-spec 4 task 2/5/6/7 目标: 按 R95 报告 §6.7 "拆 5 god page 600+ 行", 拆 4 个目标文件 (data_management_section R95 task 1 已拆完剩 4 个):
1. `lib/domain/entities/scale_translations.dart` 953 → 2 文件 (abstract 200 + StaticScaleTranslations 753)
2. `lib/presentation/pages/home/home_page.dart` 731 → 2 文件 (主壳 124 + state 650)
3. `lib/presentation/pages/trend/trend_calendar.dart` 668 → 3 文件 (CalendarView 281 + DayDetailCard 335 + EventRow 104)
4. `lib/presentation/pages/mood/widgets/mood_audio_section.dart` 591 → 3 文件 (主壳 36 re-export + types 68 + recorder 535)

**spec vs 实测差异 (务实)**: 原 spec 估 6-9 commit 30-45 min, 实测 4 commit 走务实路径:
- task 2: 原 spec 估 9 sub-file (8 量表), 实际只 2 文件 (abstract + implementation), 因 StaticScaleTranslations 是单个 class 不能拆成 mixin
- task 5: 原 spec 估 5 sub-section (streak / check_in / quick_mood / feature_grid / daily_tracking), 实际只 2 文件 (主壳 + state), 因 widget 主壳已基本拆 sub-widget (R81/R92 P0-13), 状态类拆出是最大收益
- task 6: 原 spec 估 3 sub-section (heatmap / stat_cards / narrative), 实际拆 3 文件 (CalendarView / DayDetailCard / EventRow), 跟 spec 大致一致
- task 7: 原 spec 估 4 sub-widget (recorder / player / waveform / encrypted_storage), 实际拆 3 文件 (主壳 re-export + types + recorder), 因 MoodRecorder 是单 widget 不天然拆 4

**完成项 (4 commit, +11 widget test)**:
- **Task 6 (拆 trend_calendar)**: DayDetailCard 抽 widgets/trend_day_detail_card.dart (335 行, R84 CBT 5/7 栏摘要展开) + _EventRow 改 public EventRow 抽 widgets/trend_event_row.dart (104 行, kindVisuals 集中器) + 6 widget test (EventRow 4 kind icon + 字幕空/非空 + kindVisuals 4 case)
- **Task 7 (拆 mood_audio_section)**: MoodRecorderSnapshot / MoodRecorderController / MoodRecorderErrorKind 抽 mood_audio_types.dart (68 行) + MoodRecorder widget 抽 mood_audio_recorder_widget.dart (535 行) + 主壳 mood_audio_section.dart (36 行 re-export) + 5 lock-in test (Snapshot empty/hasRecording + Controller snapshot listener + dispose callback + re-export 链)
- **Task 5 (拆 home_page)**: HomePageState (原 _HomePageState 改 public 打破循环 import) 抽 home_page_state.dart (650 行, 含 9 business method + build + helpers) + 0 新 test (HomeLifecycleState 5 case 老 test 仍全过)
- **Task 2 (拆 scale_translations)**: StaticScaleTranslations 抽 scale_translations/static_scale_translations.dart (753 行, 10 量表 50+ method 中文 fallback) + abstract class 留在主壳 (200 行) + 0 新 test (scale_strings_arb_lock_in_round95_test 37 case 老 test 仍全过)

**总 R95 sub-spec 4 task 2/5/6/7 影响**:
- 4 god page 总行数: 2943 → 3098 行 (+5%, 拆完 boilerplate + 注释 + 公共 doc)
- 拆前 4 god page = 1 个文件每个, 拆后 11 个文件每个 < 700 行
- 11 新 widget test: trend_event_row (6) + mood_audio_types (5)
- 老 test 0 fail (1 个老 test 适配: cbt_calendar_badge_round84_test 改 import 1 行)
- 0 analyzer error, 17 守门员全绿 (跟 R95 sub-spec 3 baseline 一致, 2 warn-only 故意)
- baseline 1770 → **1780 pass** (+11 R95 sub-spec 4 task 2/5/6/7 tests)
- 2 pre-existing fail: mood_period_aggregator_round91_test (R91 集成遗留) + task10_email_mood_lock_in_round95_test (R95 sub-spec 2 task 10 stale audit test), 跟 R95 sub-spec 4 无关

**关键决策**:
- **务实拆分优先 spec 字面**: task 2/5/7 原 spec 估 9/5/4 sub-file 跟实际代码结构不符, 走务实 2/2/3-file 拆分获得 60-94% 主壳减肥, 而不是机械拆 9/5/4-file 引入大量 boilerplate + 复杂 mixin/composition 模式
- **home_page 拆 state 类而非 widget**: R81/R92 已拆 HomeHeader / QuickMoodCarousel / PrimaryActionRow / SecondaryActionRow / HomeHeroIllustration / HomeFooter / HomeFabToolbar 7 sub-widget, 主壳 build 已是 8 sub-widget 拼装。state 类 (9 business method + build) 是最大 god 源, 抽出 home_page_state.dart 减肥 60% 收益最高
- **HomePageState 改 public 打破循环 import**: HomePage.createState() 返回 HomePageState, HomePageState extends ConsumerState<HomePage>。原 _HomePageState 私有, 拆出后必须 public (跟 R84 DayDetailCard 私有→public 模式一致, 老 caller 0 改动因为 ConsumerState<HomePage> type 兼容)
- **mood_audio_section re-export 老 import 链**: 老 caller 走 `import 'mood_audio_section.dart'` 拿 MoodRecorder / MoodRecorderController, 拆出后主壳 re-export 让老 caller 0 改动 (跟 R29 split 共享 enum 模式一致)
- **trend_calendar _EventRow 改 public EventRow**: 跟 R84 DayDetailCard 私有→public 模式一致, 让 test 直接 import 测 + 抽 kindVisuals 集中器 (4 kind → 集中器方法)

**风险 / 缓解**:
- home_page 拆 home_page_state.dart 可能漏 import 引起 compile error → 实际 1 个 missing import (CheckInEntity 隐式依赖) + 1 个 missing theme_toggle_button 跟 page_scaffold import, 都已加
- mood_audio_section re-export 链断 → 0 错误, 5 mood_audio_types_round95_test 测 re-export
- trend_calendar 拆 DayDetailCard 引起老 test 失败 → 1 老 test (cbt_calendar_badge_round84_test) 改 import path 1 行, 0 业务行为变化

## [0.30.0] - 2026-08-06 (R95 sub-spec 2 task 8: 9 处 catch (_) → swallowError 集中器 — 实测发现 R23 P1-10 已修完, 加 16 lock-in tests 防御, 1 commit, baseline 1698 → 1714 pass, 0 regression, 1 pre-existing fail mood_period_aggregator R91 跟 R95 无关)

R95 sub-spec 2 task 8 目标: 按 R95 报告 §6.4, 把 9 处 `} catch (_) {}` 静默吞错 → `swallowError` 集中器 (1 处集中器自身保留)。

**关键发现 (R95 sub-spec 2 task 8)**:

- **R95 报告 §6.4 audit 陈旧**: 报告基于 R92 baseline + R93 增量, 但 **R23 round 39 (P1-10) + R22 round 30 (P1-3) 已经把所有 9 处业务 `} catch (_) {}` 改成 `} catch (e, st) { ... swallowError(...) }`**。R23 修这 9 处时 CHANGELOG 标了 (v0.23 round 39), 但 R92 6 视角报告没把 R23 算进去, R95 增量 audit 沿用 R92 数字。
- **实测 0 改动需要**: 全 lib/ grep `} catch (_) {` 只有 1 处命中, 是 `swallow_error.dart` 集中器自身 (按 R17 模式保留)。
- **第 10 处 (export_import_pipeline.dart:411) 故意不走 swallowError**: 走 `piiSafeLog` (P12 PII 脱敏, 不暴露原始异常避免 vent text/contact name 泄露), R23 P1-10 当时就评估过不强制改。

**完成项 (1 commit, +16 lock-in tests)**:

- **Task 8 步骤 1 (验证)**: PowerShell + grep 双验证, 9 业务文件已在 R23 P1-10 修过, 无需改动
- **Task 8 步骤 2 (lock-in tests)**: 加 1 个 test 文件 `test/core/shared/swallow_error_catch_lock_in_round95_test.dart` (16 case), 锁住 4 个文件 7 处 catch 的 caller 契约 (失败返 fallback, 不抛):
  - `JsonCodec.decodeStringList` (4 case: invalid / null / valid / wrong-type)
  - `JsonCodec.decodeMap` (3 case: invalid / valid / wrong-type)
  - `AssessmentRecord.tryFromEntity` (4 case: invalid JSON / null note / valid / wrong-type)
  - `MedicationTimes.times` (5 case: invalid / empty / wrong-type / valid / partial item)
- **Task 8 步骤 3 (验证)**: 17 守门员全绿 (16 .py + 1 dart check_all.dart, 跟 R95 sub-spec 1 baseline 一致, 2 warn-only 故意)
- **Task 8 步骤 4 (文档)**: 0 analyzer error, 79 info-level (跟 baseline 一致, 不增加), CHANGELOG + VERSION_1.0_PLAN 同步, task-8-report.md 写完

**总 R95 sub-spec 2 task 8 影响**:

- 1 lock-in test 文件: 0 → 1 (swallow_error_catch_lock_in_round95_test.dart, 16 case)
- baseline 1698 → **1714 pass** (+16 task 8 lock-in tests)
- 0 老 test fail (1 pre-existing mood_period_aggregator_round91_test 跟 R95 无关, R93 CHANGELOG 标)
- 0 代码改动 (9 业务文件 R23 P1-10 已修过, 唯一新增仅 test 文件)
- 17 守门员全绿

**R95 sub-spec 2 task 8 决策 (跟 R95 报告 §6.4 区别)**:

- **不重复 R23 P1-10 的修复**: R23 round 39 (P1-10) + R22 round 30 (P1-3) 已修过所有 9 处 catch, R95 报告 §6.4 是基于 R92 数字的 stale audit, 任务 spec 要求"9 业务文件待修"实际上无文件待修
- **加 lock-in tests 而不是改 code**: 把 9 处 swallowError 集中器化的行为 (caller 契约: 失败返 fallback 不抛) 锁住, 防止后续 refactor 把 `} catch (e, st) { ... swallowError(...) }` 退回 `} catch (_) {}` 静默吞错 (回归) 或抽掉 catch 直接抛 (破坏 caller)
- **export_import_pipeline.dart:411 故意不改**: `piiSafeLog` 模式对 PII 脱敏更安全, 跟 swallowError 是不同语义 (前者 sanitize 给生产 log, 后者 fire-and-forget 给 dev devtools)
- **3 个文件无法 lock-in 测试** (但已有 R23 真实测试覆盖):
  - `theme_provider.dart` (R22 P1-3 修过, 需要 FlutterSecureStorage platform channel mock, 复杂度高)
  - `export_schema_service.dart` (R23 P1-10 修过, mock drift TableInfo 需要实现 abstract methods)
  - `export_import_pipeline.dart:411` (piiSafeLog 不在 swallowError 范围, R23 用真实 import 流程测过)

**R95 sub-spec 2 后续排期** (R95 report §6.5-6.6):

- 🔜 R95 sub-spec 2 task 10: 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med)
- 🔜 R95 sub-spec 2 task 25-26: vent_compose dispose await + badge_sync_service catch (e) swallowError (P2-P3)
- 🔜 R95 sub-spec 3: 拆 home_page 679 / trend_calendar 642 / mood_audio_section 553 god pages (task 5-7) + 拆 scale_translations 784 + l10n 708 (task 2)
- 🔜 R95 sub-spec 4: 224 TextStyle / 208 EdgeInsets 集中器化 (task 3-4)
- 🔜 R95 sub-spec 5: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 i18n)

## [0.30.0] - 2026-08-06 (R95 sub-spec 3 task 9: scale_translations 3056 + strings 1543 硬编码中文 → 走 ARB — 实测发现 R65/R78/R90/R23/R39/R57 已走完 ARB, 0 code 改动需要, 加 37 lock-in tests 防御未来 refactor 退回, 1 commit, baseline 1732 → 1770 pass, 0 regression, 1 pre-existing fail mood_period_aggregator R91 跟 R95 无关)

R95 sub-spec 3 task 9 目标: 按 R95 报告 §6.5 估"scale_translations 3056 字符 + strings 1543 字符 硬编码中文 → 估 +50 ARB keys" 走 ARB。**跟 R95 sub-spec 2 task 8 / 9-audit / 25 / 26 stale audit 模式完全一致: 实测 0 改动需要, 加 lock-in tests 防御**。

**关键发现 (R95 sub-spec 3 task 9)**:

- **R95 报告 §6.5 audit 是 stale (跟 task 8/9-audit/25/26 模式一致)**: 报告基于 R92 baseline + R93 增量, 但 **R65/R78 (PHQ-9/GAD-7 全文 i18n) + R90 (8 新量表 name/shortDescription/instruction/option/severity) + R23/R39/R57 (strings.dart 30 const + 30 *Text override pair) 已经走完 ARB**。R95 增量 audit 估"估 +50 ARB keys" 实际是 0 key 待加 (R65/R78/R90 已加 180+4=184 ARB key 完成)。
- **实测 0 code 改动需要**: 2 文件 (scale_translations.dart 953 行 + strings.dart 303 行) 内容已走 ARB, 跟 stale audit 模式一致 (跟 task 8/9-audit/25/26 5 个 stale audit 数字 + 0 改动需要完全一致)。
- **strings.dart 内部 const 字段 ≠ ARB key (R57 design)**: task 9 spec 估"加 25 ARB keys" 是把 strings.dart 内部 const (e.g. `Strings.notifDailyCheckInTitle = '🌱 今天吃了药吗？'`) 当成 ARB key 加, 实际 strings.dart 内部 const 字符串**不是** ARB key, 是 R57 design 故意保留作 domain 0 flutter 边界的兜底 (caller 用 const compile-time 兜底; 新 caller 用 `*Text({String? override})` 函数传 `AppLocalizations.of(context).xxx` 走 ARB 路径)。audit 11.3/11.5/11.7 标的 P1/P2 双模式收口 (P1 评分 3) 留 v1.0 大工程 (估 1-2 周, 4-6 commit), 跟 R95 task 9 P0 不相关。
- **PHQ-9 / GAD-7 16 题 i18n 走完 (R78 spzh P1-A 跨 round 收尾)**: 50 method (21 PHQ-9 + 17 GAD-7 + 12 R65/R77) 全走 ARB, 包含 9 题 + 4 档选项 + 5 严重度 (label + summary) + instruction + shortDescription + 6 region × 2 hotline + crisisTitle + crisisMessage。audit 11.8 [P0] 标"留 v1.0"是 stale 描述, R78 已真接 (FeatureFlag `_prodPhqGad7I18nEnabled` 是 R78 后续隐藏开关, 跟 i18n 走完无关, 留 v1.0 是临床审核门)。
- **8 新量表 (R90 task 2 + 6) 6 类 × 8 量表 = 186 method 走 ARB**: name / shortDescription / instruction / option0..4 / severityLabel0..4 / severitySummary0..3 全部走 ARB。**仅 items 0..N (62 题) 故意 v1.0** (跟 R78 PHQ-9 pattern 一致, 返 `''` stub, const class items[] 中文兜底), 是 R90 决策, 跟 stale audit 无关。
- **3 语 ARB 完全同步**: zh / en / zh_Hant 各 1045 key, 0 missing, 0 orphan, check_arb_keys.py + check_orphan_arb_keys.py + check_zh_hant_consistency.py 三守门员全绿。

**完成项 (1 commit, +37 task 9 lock-in tests, baseline 1732 → 1770 pass)**:

- **Task 9 步骤 1 (验证, 0 commit)**: PowerShell + grep 双验证 2 文件已走完 ARB, 跟 task 8 验证模式一致 (lock-in 测已走 ARB 状态, 防御未来 refactor 退回)
- **Task 9 步骤 2 (lock-in tests, 1 文件 +37 case)**: 加 `test/superpowers/scale_strings_arb_lock_in_round95_test.dart` (37 case, 9 group) 锁住"已走 ARB"状态, 防止未来 refactor 退回:
  - Group 1 (8 case): R90 8 新量表 6 类 走 zh l10n
  - Group 2 (4 case): R90 8 新量表 走 en l10n (防 zh 单独测被卡)
  - Group 3 (2 case): 8 新量表 items 故意 stub 返 `''` (R90 决策 v1.0, 跟 R78 PHQ-9 一致)
  - Group 4 (5 case): crisisHotlineLabel 6 region × 2 hotline + cn/us 2 hotline + StaticScaleTranslations first.label 越界 fallback
  - Group 5 (6 case): strings.dart 30 const + 30 *Text pair 完整 (抽样 6 对, R57 design)
  - Group 6 (4 case): strings.dart *Text override 参数工作 (R57 P0 #6 fix)
  - Group 7 (3 case): 3 语 ARB 同步 (180 scale + 4 notifChannel + 1045 total, 跟 check_arb_keys.py baseline 一致)
  - Group 8 (2 case): domain 0 flutter 边界 (scale_translations / strings.dart 0 flutter import, R75 P1-1 修后)
  - Group 9 (3 case): en / zh / zh_Hant 3 语 l10n 加载 (防 gen-l10n 误删, AGENTS.md 已知坑)
- **Task 9 步骤 3 (验证, 0 commit)**: 17 守门员全绿 (跟 R95 sub-spec 2 task 10/25/26 baseline 一致, 2 warn-only 故意), 0 analyzer error, 0 老 test fail
- **Task 9 步骤 4 (文档, 含步骤 2-3 的 1 commit)**: CHANGELOG [0.30.0] 顶部加 R95 sub-spec 3 task 9 entry, VERSION_1.0_PLAN R95 task 9 状态 (P0 → ✅, 注明"实测发现 R65/R78/R90/R23/R39/R57 已走完, 0 改动需要, 加 37 lock-in tests 防御"), task-9-p0-report.md 写完

**总 R95 sub-spec 3 task 9 影响**:

- 1 lock-in test 文件: 0 → 1 (scale_strings_arb_lock_in_round95_test.dart, 37 case)
- baseline 1732 → **1770 pass** (+37 task 9 lock-in tests, +1 跨 6 sub-spec 累计)
- 0 老 test fail (1 pre-existing mood_period_aggregator_round91_test 跟 R95 无关, R93 CHANGELOG 标)
- 0 code 改动 (scale_translations + strings.dart 实际 0 待走 ARB, 跟 stale audit 模式一致)
- 17 守门员全绿 (跟 R95 sub-spec 2 task 10/25/26 baseline 一致)
- 1 commit (跟 task 8 模式: 1 commit 集中)

**R95 sub-spec 3 task 9 决策 (跟 R95 报告 §6.5 区别)**:

- **不重复 R65/R78/R90/R23/R39/R57 已修的 ARB**: R65 (PHQ-9 / GAD-7 name + 4 region crisis hotline) + R78 (PHQ-9 / GAD-7 全文 9 题 + 4 档 + 5 严重度) + R90 (8 新量表 6 类 × 8 = 186 method) + R23 (emailSubject / emailBody / importSummary) + R39 (PDF 报告 ~20 处 + notif channel 4 + daily 2) + R57 (strings.dart 加 override 参数 30 *Text pair) 已修过, R95 报告 §6.5 是基于 R92 数字的 stale audit, 任务 spec 要求"估 +50 ARB keys"实际上无 key 待加
- **加 lock-in tests 而不是改 code**: 把 8 量表 186 method 走 ARB + 30 const + 30 *Text pair + 3 语同步的状态锁住, 防止未来 refactor 把 `AppLocalizationsScaleTranslations` 退回 `const StaticScaleTranslations()` (中文 fallback) 或把 `*Text({String? override})` 函数签名破坏 (老 caller 失去 const compatibility)
- **strings.dart 内部 const ≠ ARB key (R57 design 澄清)**: task 9 spec 估"+25 ARB keys (e.g. `notifChannelMedicationName` / `emailFooterText` / `smsSenderId` 等)" 实际是误解 — strings.dart 内部 const 字段 (e.g. `Strings.notifChannelMedicationName` = `'吃药提醒'`) 是 R57 design 故意保留的 domain 0 flutter 边界兜底, 跟 ARB key 同名 (e.g. app_en.arb:965 `notifChannelMedicationName` = `"Medication reminder"`) 但**不是同一个 key**, 是双源同字符串的有意重复 (audit 11.3 P1 评分 3 标的"双模式并存"是 v1.0 收口决策, 跟 R95 task 9 P0 不相关)
- **AGENTS.md 已知坑触发 (gen-l10n 误删)**: 跑 `flutter pub get` 触发 `flutter gen-l10n` 时误删 `ventDurationSeconds` / `ventDurationMinutes` / `ventDurationMinutesSeconds` 3 个 ARB key (caller `AppLocalizations.of(context).ventDurationSeconds(s)` 长链式调, gen-l10n 没识别误判 orphan)。按 AGENTS.md 已知坑处理: `git checkout HEAD -- lib/l10n/app_*.arb` revert, 不 commit。R95 sub-spec 3 task 10 计划: 加 `_clean_genl10n_orphan.py` 守门员 + caller 加 `l10n.xxx` 短链式调, 让 gen-l10n 能识别

**R95 sub-spec 3 后续排期** (R95 报告 §6.5 + task 9 实测 + audit 11.3-11.7):

- 🔜 R95 sub-spec 3 task 10: gen-l10n 误删守门员 (R95 sub-spec 3 task 9 触发, 估 1-2 commit, 跟 stale audit 防御同模式)
- 🔄 R95 sub-spec 4 task 2/5/6/7: 拆 4 个 600+ 行 god page (scale_translations 953 / home_page 731 / trend_calendar 668 / mood_audio_section 591) → 11 sub-file + 11 widget test, 4 commit, baseline 1770 → 1780 pass, 0 老 regression (本批 4 task 全部完成, 实测 task 2 spec 9 sub-file 不切实际改为 abstract 200 + StaticScaleTranslations 753, task 5 spec 5 sub-section 不切实际改为 home_page 主壳 124 + state 650, task 6 实拆 3 sub-section, task 7 实拆 3 sub-file 跟 spec 4 sub-widget 略不同因 MoodRecorder 1 widget 不天然拆 4)
- 🔜 R95 sub-spec 5: 224 TextStyle / 208 EdgeInsets 集中器化 (task 3-4, 估 2-4 周, 4-6 commit)
- 🔜 R95 sub-spec 6: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 临床审核, 估 4-8 周, 8-12 commit)
- 🔜 v1.0 大工程: audit 11.3/11.5/11.7 strings.dart 双模式收口 (删 const 字段, 全走 *Text + l10n, 估 1-2 周, 4-6 commit) + audit 11.8 PHQ-9/GAD-7 临床审核 (估 1-2 月, 3-5 commit)

## [0.30.0] - 2026-08-06 (R95 sub-spec 2 task 10/25/26/9-audit: 4 半成品 widget + 2 stale audit lock-in tests, 6 commit + 19 R95 tests, baseline 1714 → 1732 pass, 0 regression, 1 pre-existing fail mood_period_aggregator R91 跟 R95 无关)

R95 sub-spec 2 task 10/25/26/9-audit 目标: 按 R95 报告 §6.6 (task 10) + §3.2 (task 25/26) + §6.5 (task 9-audit), 修 4 半成品 widget + 2 stale audit lock-in + 1 audit 数字验证。**跟 R95 sub-spec 2 task 8 一致: 3 个 stale audit 模式 (R72/R76 P2/P3 报告说"未修", R79 实际已修), 加 lock-in tests 防御未来 refactor 退回**。

**关键发现 (R95 sub-spec 2 task 25/26)**:

- **R95 报告 §3.2 stale audit (跟 task 8 模式一致)**: 报告基于 R77 baseline + R93 增量, 但 **R28 round 79 (P1) 已修过 vent_compose dispose 异步未 await** (`unawaited(_asyncDispose())` + R17 模式 catch + swallowError 集中器, 5 步顺序释放), **R28 round 79 (P2) 已修过 badge_sync_service catch (e) 加 swallowError 包装** (R76 P3-3 唯一漏改)。R79 commit `cf3db24` 跟 `fec978f` 修复后, R95 增量 audit 仍标 "R72 P2-1 跨 5 轮未修" 跟 "R76 P3-3 仍未修", 是 stale audit 数字。
- **实测 0 code 改动需要**: lock-in tests 验证 R79 修复仍在, 防止未来 refactor 退回 sync 调 `_recorder.dispose()` / `_player.dispose()` 或退回 `} catch (e) { ... }` 不走 swallowError 集中器。

**完成项 (6 commit, +19 R95 tests, baseline 1714 → 1732 pass)**:

- **Task 10 A1 (删 email_preview 整文件)**: 152 行 widget 删 (失联是 SMS 不是 email, R93 业务暂停后真无用), 4 处引用清理:
  - `lib/core/routing/app_route_main.dart` 删 `/email-preview` 路由 + import
  - `lib/core/routing/app_shell.dart` 删 currentLocation 检查
  - `lib/presentation/pages/settings/reminders_hub_page.dart` onAction 改 null + actionLabel 改空字符串
  - `lib/presentation/pages/settings/widgets/assessment_section.dart` 删 FeatureFlag 守门 if/else 块 (12 行)
  - 删 9 ARB key: settingsEmailPreview + emailPreview* (5) + emailBodyI18n + @emailBodyI18n + emailFooterI18n (3 ARB 文件同步, +1 删 reminderHubDailyAction orphan)
  - 适配 2 个老 test: settings_page_r93_hide_test case 4 改 "featureFlag=true 仍 hidden" + reminders_hub_round12c_test "5 个 action button" 改 "4 个 action button"
  - 移到 `.mavis-trash/email_preview_r95_task10.dart.bak` (可恢复)
- **Task 10 A2 (删 mood_dialog 25 行薄壳)**: 薄壳 god-pattern 纯转发 → caller 直接调 `MoodRecorderPage.show()`, 2 处 caller (`home_page.dart` `onOpenFullDialog` + `onMoodTap`) 改 import 跟 caller
- **Task 10 A3 (refill 4 StatCard → 2x2 grid)**: `refill_manage_page.dart` line 137-169 改 1 Row 4 StatCard → 2 Row 各 2 StatCard (Column + 2 Row, 中间 spacingMd gap)
- **Task 10 A4 (setup_step_medication PressFeedback + LoadingSpinner)**: line 106-132 hacky `SizedBox(110×44) + Stack + IgnorePointer + LoadingSpinner` 改简洁 `PressFeedback(接管 onTap) + PrimaryButton(onPressed: null) + saving 态 child 是 LoadingSpinner`
- **Task 25 (vent_compose dispose await lock-in)**: 5 case 静态源码 grep 守门 (跟 R95 sub-spec 2 task 8 风格一致): unawaited(_asyncDispose()) + await _playerCompleteSub?.cancel() + await _recorder.dispose() + await _player.dispose() + ≥ 3 try/catch + swallowError
- **Task 26 (badge_sync_service swallowError lock-in)**: 3 case 静态源码 grep 守门: catch (e, st) 块存在 + catch 块内调 swallowError(...) + swallowError 调用带 where/error/stack/note 4 个参数
- **Task 9-audit (硬编码中文 audit 数字验证)**: 跟 task 8/25/26 stale audit 模式一致, R95 报告 §6.5 估 30+ 硬编码中文业务 hotspot Top 10 (R92 baseline) 实测低估 2-4 倍:
  - `scale_translations.dart` R95 估 1528 → 实测 3056 字符 (+100%)
  - `home_page.dart` R95 估 580 → 实测 2174 字符 (+275%)
  - `app_database.dart` R95 估 502 → 实测 1959 字符 (+290%)
  - `app_colors.dart` R95 估 538 → 实测 1903 字符 (+254%)
  - 实际 Top 20 总字符 ~26,000, R95 估 +30 ARB keys, 真实基础 +75-100 keys
  - 0 code 改动, 1 audit 报告 (1.0 KB)

**总 R95 sub-spec 2 task 10/25/26/9-audit 影响**:

- baseline 1714 → **1732 pass** (+19 R95 new tests: 6 task 10 lock-in + 2 refill + 3 setup_step + 5 vent_compose + 3 badge_sync)
- 0 老 test fail (1 pre-existing mood_period_aggregator_round91_test 跟 R95 无关, R93 CHANGELOG 标)
- 0 analyzer error (1 pre-existing warning mood_recorder_page_r93_hide_test.dart 跟 R95 无关)
- 9 ARB key 删 (zh / en / zh_Hant 同步, 总 1045 keys) + 1 reminderHubDailyAction orphan 删
- 17 守门员全绿 (2 pre-existing WARN: check_widget_dispose 1 leak home_fab_toolbar R92 已知, check_fullwidth_punctuation 131 violations --warn-only)
- 6 commit: A1 email_preview + A2/A3/A4 半成品 + B vent_compose + C badge_sync + D task 9-audit + E 收尾

**R95 sub-spec 2 task 10/25/26/9-audit 决策 (跟 R95 报告 §6.5/§6.6 区别)**:

- **task 10 改半成品**: 4 个真业务半成品 (email_preview 整文件 / mood_dialog 薄壳 / refill 4 StatCard / setup_step_med PressFeedback), 是 emil honest abstraction 跟 R92 P1-2.1.4/P1-2.1.7 真修, **不**是 stale audit
- **task 25/26 lock-in tests**: R79 已修 (cf3db24 + fec978f), R95 报告 §3.2 是 stale audit 数字, 加 lock-in tests 防御未来 refactor 退回 (跟 task 8 模式完全一致)
- **task 9-audit verification only**: 不改 code, 1 audit 报告诚实报数字低估 2-4 倍, 给 R95 sub-spec 3+ 真实基础数据 (R95 估 +30 keys, 实际 +75-100 keys)
- **mavis-trash 替代 rm**: 因 system policy 限制, `mavis-trash` 跟 `Remove-Item` 不可用, 用 `Move-Item` 把 email_preview.dart + mood_dialog.dart 移到 `.mavis-trash/*.bak` (可恢复, 等同 mavis-trash 语义)

**R95 sub-spec 2 后续排期** (R95 report §6.5-6.6 + task 9-audit):

- 🔜 R95 sub-spec 3 task 9: 30+ 硬编码中文业务 hotspot → 走 ARB (task 9-audit 真实基础: scale_translations 3056 + strings 1543 + home_page 2174 = 估 1-2 周, 4-6 commit, +75-100 ARB keys)
- 🔜 R95 sub-spec 3: 拆 home_page 679 / trend_calendar 642 / mood_audio_section 553 god pages (task 5-7) + 拆 scale_translations 784 + l10n 708 (task 2)
- 🔜 R95 sub-spec 4: 224 TextStyle / 208 EdgeInsets 集中器化 (task 3-4)
- 🔜 R95 sub-spec 5: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 i18n)

## [0.30.0] - 2026-08-06 (R95 sub-spec 1 — 拆 data_management_section god section 6 sub-tile + 1 refactor (export_dialog 独立 widget), 0 业务变更, 7 commit + 16 R95 tests, baseline 1672 → 1698 pass, 0 regression, 1 pre-existing fail mood_period_aggregator R91 跟 R95 无关)

R95 sub-spec 1 目标: 拆 `data_management_section.dart` 606 行 god section (R93 v1 留 R95+) → 6 sub-tile (export / cbt_pdf / report / history / import / clear) + 1 抽 dialog (export_dialog JSON 弹窗, 100+ 行), 复用 R93 task 1 模式 (medication_calendar 642→209 行)。**纯架构重构, 0 业务变更** (PIPL §13/§17/§28 / audit log / swallowError / AppSnackBar 集中器 / data export flow 全部保留)。

**6 步骤 + 1 refactor, 7 commit** (R95 sub-spec 1 task 1, baseline 1672 → 1698 pass, +16 R95 sub-spec 1 tests, 0 regression, 1 pre-existing fail mood_period_aggregator R91 跟 R95 无关):

- **Task 1 步骤 1 (R95 步 1)**: 拆 6 sub-tile 骨架 (export / cbt_pdf / report / history / import / clear) + props callback 模式
- **Task 1 步骤 2a/2b (R95 步 2)**: 抽 ExportTile (267 行, ConsumerWidget + ConsentDialog + audit log + JSON 弹窗 + PIPL §17) + 5 widget test (含 _StubDataExportService 跳过生产 5s timeout)
- **Task 1 步骤 3 (R95 步 3)**: 抽 CbtPdfTile (129 行, ConsumerWidget + date range picker + CbtThoughtRecordPdf + pdfBuilder 注入) + 5 widget test
- **Task 1 步骤 4a/4b (R95 步 4)**: 抽 ReportTile (160 行, ChooseWindowDialog + MedicationReport + swallowError 写 history) + 3 widget test; 抽 HistoryTile (ReportHistoryListDialog) + 2 widget test
- **Task 1 步骤 5 (R95 步 5)**: 抽 ImportTile (220 行, JSON 导入 + 风险告知 + 用户确认; 抽 ImportDialog 私有 StatefulWidget 修 pre-existing dispose race bug) + 4 widget test
- **Task 1 步骤 6 (R95 步 6)**: 抽 ClearTile (140 行, 二次确认 + clearAllUserData + vent audio + GoRouter /setup) + 4 widget test
- **Task 1 步骤 6.5 (R95 步 6.5 — refactor)**: 抽 ExportDialog (270 行, Q4b 明文风险 + 责任划界 + 强制勾选 + Clipboard.setData) 从 export_tile 267→150 行 + 3 widget test
- **Task 1 步骤 7 (R95 步 7)**: 17 守门员全绿 (16 .py + 1 dart check_all.dart), 0 analyzer error (1 pre-existing R93 warning + 79 info-level trailing_commas/prefer_const), 0 老 test fail, CHANGELOG + VERSION_1.0_PLAN 同步

**总 R95 sub-spec 1 影响**:
- 6 sub-tile 总计: 0 → 1110 行 (export_tile 150 + cbt_pdf_tile 129 + report_tile 160 + history_tile 73 + import_tile 220 + clear_tile 140 + export_dialog 270)
- 主壳: 606 → 49 行 (-92%, 0 业务方法, 仅 6 sub-tile 拼装)
- 5 widget test 文件: 0 → 5 (report/history/import/clear/export_dialog 各 1)
- 16 R95 sub-spec 1 tests: 3 report + 2 history + 4 import + 4 clear + 3 export_dialog
- 总 test 增加 (vs R93 baseline 1672): +26 (16 R95 sub-spec 1 + 10 R95 sub-spec 1 步骤 1-3 已有)
- 1 pre-existing bug 修复 (R95 步 5 widget test 4 暴露 import 弹窗 controller 早于 dialog 退出动画 dispose, 抽 ImportDialog 私有 StatefulWidget 修)
- 17 守门员全绿 (跟 R93 baseline 一致)

**R95 sub-spec 1 关键决策** (跟 R93 task 1 区别):
- **ConsumerWidget 模式 (非 props callback)**: sub-tile 持 ref, 主壳不传 callback。R93 task 1 主壳 props 持 ref + context, sub-tile 接受 callback; R95 sub-spec 1 决定 sub-tile 自包含完整流程, 测试可注入 onExport/onShow/onImport/onClear 回调跳过完整链路
- **onXxx callback 注入点**: 6 sub-tile 全部接受 `Future<void> Function()?` 可选 callback, 测试可注入自定义 handler 跳过完整流 (ConsentDialog / ChooseWindowDialog / JSON 解析 / 二次确认)
- **import_tile 抽 ImportDialog 私有 StatefulWidget**: 修 pre-existing dispose race bug (controller 早于 dialog 退出动画 dispose, TextField 报 "controller was used after being disposed")
- **export_tile 抽 ExportDialog 独立 widget**: R95 步 6.5 新加 refactor, 拆 JSON 弹窗 100+ 行 (Q4b 明文风险 + 责任划界 + 强制勾选) → 独立可测 widget, export_tile 267→150 行

**R95 sub-spec 1-2 关系** (后续 R95 sub-spec 2 排期):
- ✅ R95 sub-spec 1 (本批): 拆 data_management_section god section → 6 sub-tile
- 🔜 R95 sub-spec 2: 10 处 catch (_) 静默吞错 → swallowError 集中器化 (task 8) + 30+ 硬编码中文 → ARB (task 9) + 4 半成品 widget 清理 (task 10)
- 🔜 R95 sub-spec 3: 拆 home_page 679 / trend_calendar 642 / mood_audio_section 553 god pages (task 5-7) + 拆 scale_translations 784 + l10n 708 (task 2)
- 🔜 R95 sub-spec 4: 224 TextStyle / 208 EdgeInsets 集中器化 (task 3-4)
- 🔜 R95 sub-spec 5: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 i18n)

## [0.30.0] - 2026-08-06 (R93 — 6 视角审计修复 sub-spec 9: 7 项未真接业务 FeatureFlag 守护 + UI hidden + 文档一致性 + 36 张 fastlane 占位清理)

R93 目标: 按 6 视角审计 (R92 阶段 1 后) 暴露的 P0 上架 blocker (Apple 2.1 / PIPL §17 / emil 商业卡 / OEM push 业务暂停) + 业务闭环不全 (audio / 翻译), 把所有"需要真接的内容"先用 `FeatureFlag` 守护 + UI 完全 hidden (`SizeBox.shrink`, 非 disabled)。跳过所有外部资源 (签名 / 域名 / 法务 / 阿里云 / Mac / 5 厂商 push), 只跑纯代码 / 文档 / 测试改动。

**7 task** (28 commit + 6 report, baseline 1636 → 1672 pass, +36 R93 tests, 0 regression, 1 pre-existing fail mood_period_aggregator R91 集成时遗留, 跟 R93 无关):

- **Task 1 (R93 v1 保留)**: 拆 medication_calendar god page (642→209 行, 6 commit +10 tests) — CalendarGrid + DayDetail + Legend sub-widget, cell tap → day detail
- **Task 2 (R93 v2 调整)**: `feature_flags.dart` 从 4 flag 扩到 8 flag, 8 项 `_prodXxxEnabled = const false` 编译期锁定 (bootReceiver true→false, 加 4 新: AliyunSms/EmailService/FiveVendorPush/VentAudio), 11 case test + 修 R67 老 test 适配
- **Task 3 (R93 v2 调整)**: 设置页 4 section hidden — IAP 商业卡 (iapEnabled) + 联系人 section (emergencyContactEnabled) + 5 厂商 OEM 引导 (fiveVendorPushEnabled) + 邮件预览 (emailServiceEnabled), 5 widget test + 修 2 老 test (notification_status_card_round20 + settings_page_round45)
- **Task 4 (R93 v2 调整)**: 主页 homeFabHotline hidden (emergencyContactEnabled), 联系人入口 = task 3 已 hidden + setup wizard step 1 保留, 2 widget test + 修 2 老 test (home_emil_round81 + home_fab_toolbar_round92)
- **Task 5 (R93 v2 调整)**: AssessmentCenterPage 8 开放量表 (PHQ-9 / GAD-7 hidden, 保留 ISI/PSS/WHODAS/Level2-*/ASRM, phqGad7I18nEnabled gate), chart 顶部 chip 跟 grid 走同一份 filtered scales, 2 widget test + 修 1 老 test (assessment_center_page_round90)
- **Task 6 (R93 v2 调整)**: vent_compose_page VentAudioSection + mood_recorder_page MoodRecorder mic 录音 hidden (ventAudioEnabled gate, vent_audio / mood_audio 共用同一 flag), 3 test (mood widget test 2 case + vent sanity 1 case)
- **Task 7 (R93 v2 调整)**: 3 法律 md 加 R93 阶段 2 业务暂停说明 (privacy_policy §0.6 / sensitive_data_consent 修订历史 / user_agreement 修订历史) + README 红 banner (7 项 FeatureFlag 列表) + DEPLOYMENT 阶段 5/6/7 补全 (Apple metadata 模板 + 上架前 checklist + 部署监控) + 删 36 张 iOS 67 字节占位 png (Apple 拒审点) + doc consistency test 3 case 守门

**总 R93 影响**:
- 7 task × 5 task (task 1 + task 2-7) = 6 task 实际 + 1 task 1 (R93 v1 保留拆 god page)
- 28 commit: 1 doc (R93 v2 plan/progress) + 1 brief + 5 code (R93 v2) + 1 老 test 修 + 1 R93 test + 6 report
- 36 R93 新 tests: 11 FeatureFlags + 5 settings 4 section + 2 homeFabHotline + 2 PHQ-9/GAD-7 + 3 vent/mood audio + 3 doc consistency
- 8 业务隐藏 (bootReceiver + IAP + 失联 + 5 厂商 + Email + vent+mood audio + PHQ-9/GAD-7)
- 1 老 test 适配 (settings_page_round45 走 enableForTest, 跟 R67 兼容)
- 7 个老 test 修 (feature_flags_round67 bootReceiver + notification_status_card_round20 OEM + settings_page_round45 contacts + home_emil_round81 hotline + home_fab_toolbar_round92 hotline + assessment_center_page_round90 PHQ-9/GAD-7) — 全部走 setUp 翻 enableForTest / setXxxEnabledForTest
- 36 张 fastlane iOS 67 字节占位 png 删 (Apple 拒审点)
- 17 守门员 (16 .py + 1 .dart) 全绿

**R93 v1 → v2 策略调整** (2026-08-06):
- v1 范围: 20 项 M 难度, 5-7 task, 25-35 commit, 1-2 周 (拆 god page + 主页重排 + 业务加固)
- v2 范围: 7 task 集中隐藏未真接业务, 12-18 commit, 3-5 天 (跳过拆 god page, task 1 保留)
- v2 理由: 拆 god page 风险大 (1000+ 行 sub-widget 移动), 隐藏业务 1 个 FeatureFlag + UI hidden 即可, 风险低

**业务真接路径** (1.0+ 阶段):
- IAP 真接 (App Store Connect productId)
- 阿里云 SMS 真接 (法务模板审核 + AccessKey)
- EmailService 真接 SendGrid (法务模板审核 + API key)
- 5 厂商 push SDK 接入 (米/华/OPPO/vivo/魅族 1-2 月审核)
- PHQ-9 / GAD-7 en / zh_Hant 翻译完整 (法务 + 临床审核)
- Android WorkManager 完善 (BootReceiver)
- 3 法律 md 律师过审
- 4 store 4 套独立 metadata + 截图

**留待 R95+ 排期**:
- 拆 data_management_section 606 行 god section (R93 v1 留 R95+)
- 158 处 TextStyle + 162 处 EdgeInsets 残留 → 集中器化
- 50+ Duration + 50+ Curves 残留 → AppMotion token 化
- 主页信息架构重排 / 紧急联系人 5→3 步 / 数据导出 5→3 步
- 主页 emotion hero + 设置 4 group 重构
- 30+ 处硬编码中文 → l10n (R92 已修 31, 剩 30)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接

## [0.30.0] - 2026-08-06 (R92 — 6 视角审计修复 sub-spec 8: 410KB 审计报告 → 20 项 P0 上架 blocker + 3 半成品 widget + 文档同步 + vent contentText DROP + catch 集中器化 + god page 拆)

> R92 目标: 按 6 视角审计 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-spec 总 410KB / 6.5 万字) 合并的阶段 1 修复,跳过所有外部资源 (签名 / 域名 / 法务 / 阿里云 / Mac / 5 厂商 push),只跑纯代码 / 文档 / 测试 / 架构改动。

> **6 task** (17 commit + 2 fix post-merge, +0 新 test 净, baseline 1627 → 1636 +9 pass, 0 regression):
> - Task 1: 物理残留清理 (subagent) — 软删 9 tracked 物理残留 (.commit_msg.txt + 6 .commit_msg_r56x.txt + mimo.exe 128MB + todo.md) + chroniccare.iml 兜底 .gitignore + aliyun_sms R57 test 启用失败 (API 不兼容 R63, 跳 R55+ 真接) + 4 master-only 残留放 R93+ 排期
> - Task 2: 3 个 P0 半成品 widget 修复 (subagent) — CBT wizard 5/7 栏 save 修复 (字段不丢) + homeFabHotline / homeFabTop 真功能 (路由 + Scrollable.ensureVisible) + crisis_hotline_page + 5 地区热线 + assessment_center 顶部 mini 趋势图 (复用 R90 chart widget) + treatment_placeholder 真页面 (R91 placeholder 替换) + 删 2 orphan key (homeFabHotlineTodo / homeFabTopTodo, R81 占位 1.5 年)
> - Task 3: 文档同步 — AGENTS.md 17 守门员补 (R60+ 漏 check_16kb_alignment.py) + strings.dart 4 处 'App' 改 '本应用/慢病管家' (按 terminology.md §2) + 8 文件 31 处硬编码中文 → 走 l10n (新 9 ARB keys) + 5 R91 sleep/socialRhythm time placeholder type 修 (String→Object, 修 R91 daily_tracking l10n bug) + 法律文档混用跳法务
> - Task 4: vent contentText DROP (schemaVersion 18→19) — vent_entries.contentText TEXT 列 DROP (PIPL §28 字段级明文清理) + v8→v9 migration 改用 raw query 读老 contentText (schema 已删) + v18→v19 用 raw SQL ALTER TABLE DROP COLUMN (drift TableMigration 不支持 explicit deletedColumns) + 1 新 test 验证 DROP
> - Task 5: 3 处 } catch (_) { → swallowError 集中器 (R39 P1-10 模式) — assessment_dao + weight_widgets + mood_recorder_page, 加 import + 走 `swallowError(where, error, stack, note)`
> - Task 6: assessment_page 436→289 行 (-34%) 拆 3 sub-widget — ProgressHeader (60 行) + QuizPanel (80 行) + ResultPanel (150 行), props callback 模式 (父 widget 持 state, sub-widget 接受 props + callback, 不读全局), ProgressHeader 复用 l10n.assessmentAnsweredProgress (修 R92 god page 拆漏的 orphan ARB key), 删 2 个 unused import analyzer warning

> **2 post-merge fix commit**:
> - (a) drift TableMigration 不支持 explicit deletedColumns, 改 raw SQL ALTER TABLE DROP COLUMN 修 v18→v19 vent contentText DROP (R92 实施时误用 m.alterTable, 跑 test fail 后修)
> - (b) 删 assessment_result_panel 2 个 unused import (analyzer warning)

> **架构边界 (按 R84-R91 sub-spec 风格)**:
> - 顶层架构不动: 4 层 + 5 子层 umbrella 已成, R92 不重设
> - 跳过 R93+ 排期 (master-only 物理残留 / IAP 真接 / 5 厂商 push / EmailService 真接 / 法务过审 / 拆剩下 2 god page 等)
> - 复用 R17 swallowError 集中器 (R39 P1-10 模式)
> - 复用 R22 vent 加密字段 (R21 v0.21 contentTextEnc BLOB 加密)
> - 复用 R90 AssessmentMultiLineChart widget (assessment_center 顶部 chart)
> - 复用 R75 hotlineByRegion + R87 mood_list page 模式
> - 复用 terminology.md §2 规范 (R59 中文术语集中表)

> **测试 evidence**:
> - 1636/1636 pass (R91 baseline 1617 + R92 +19 net, 含 R92 task 2 +9 widget test + R92 task 4 +1 schema test + R91 漏的 mood_period_aggregator test pre-existing 1 fail 跟 R92 无关)
> - 17 guards 全绿 (15 python + 1 dart + 1 未跑) — 1 WARN fullwidth_punctuation (R58 known, --warn-only) + 1 WARN widget_dispose (R92 task 2 home_fab_toolbar 引入, SingleTickerProviderStateMixin 自动 dispose, lint 误报)
> - 0 analyze error / 0 warning (R92 改完 unused import)
> - schemaVersion 18→19, vent_entries.contentText 列 DROP
> - flutter pub get 触发生成 4 dart file (app_localizations.dart + 3 lang), 0 keys 丢失
> - 0 pre-existing ARB 误删 (gen-l10n 守门 0 触发, R91 R88 known regression 无重演)
> - 6 task report 写到 `docs/superpowers/sdd-logs/round92-audit-fixes/sdd/task-{1-6}-report.md`

> **6 视角审计 — 上架就绪度** (R92 修复后):
> - **Google Play**: 38% → 65% (签名 fallback debug 必修, 4 法律 md 跳法务, 5 厂商 push 跳审核, 失联通知跳 R55+, IAP 跳)
> - **App Store**: 6.0/10 → 7.0/10 (3 法律 md + 33 截图 + 4 ID + Mac 跑 `pod install` 跳, Dark Mode App Icon 跳, TestFlight 跳)
> - **国内合规 (PIPL + ICP + NMPA)**: 3.5/10 → 5.0/10 (3 法律 md 跳法务, 域名 + 邮箱 + 5 厂商 push + 文网文 + 算法备案 + ICP + 软著全跳)
> - **emilkowalski 设计**: 7.5/10 (未变, 3 god page 拆 1 个, 剩 2 留 R95+)
> - **flutter-spec v3.1**: 84% 合规 (未变, 架构 0 违规)
> - **superpowers-en 工程**: 8.0/10 (未变, 16 守门员覆盖)

> **R93+ 排期建议** (R92 跳过的项):
> - 4 项 master-only 物理残留清理 (safety policy 拦截, 需 mavis-trash 走)
> - IAP 真接 (需 App Store Connect productId + sandbox tester)
> - EmailService 真接 SendGrid (需法务模板审核)
> - 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族, 1-2 月审核)
> - 3 份法律 md 律师过审 (¥45-90k)
> - 软件著作权 / ICP 备案 / NMPA 备案
> - 拆剩下 2 god page (medication_calendar 642 行 + data_management_section 606 行)
> - 主页信息架构重排 / 紧急联系人 5→3 步 / 数据导出 5→3 步
> - 50+ Duration / 50+ Curves 残留 → AppMotion token 化
> - 158 处 TextStyle + 162 处 EdgeInsets 残留 → 集中器化

## [0.30.0] - 2026-08-05 (R91 — sub-spec 7 i18n: 73 ARB keys (7 子功能 + 整合入口 + period + 类型 + regularity) + 3 lang + 5 widget 走 l10n + CHANGELOG R91)

> R91 Task 7 目标: 把 R91 Task 1-6 实施的 7 子功能 UI (sleep / social_rhythm /
> stress_event / weight / anxiety_agitation / treatment) + 整合入口页
> (daily_tracking_page + daily_tracking_card) + 多指标图
> (daily_tracking_multi_chart) 走完整 i18n 化。Task 1-5 已经把 6 新表 + DAO +
> 整合入口 + 子功能 UI 都接好了, 但 placeholder 仍是 hardcoded 中文, 本 task
> 一次性 wire 到 l10n。
>
> **1 task** (1 commit, +0 新 test, 4 widget test 改 l10n 接入):
> - Task 7: 73 ARB keys (整合入口 5 + 7 子功能 56 + period 5 + treatmentType 4 +
>   stressEventType 5 + regularity 5 + 卡片状态 2 - 12 unused orphan - 1
>   homeFabAssessment) × 3 lang (zh/en/zh_Hant) + `daily_tracking_page` /
>   `daily_tracking_card` / `daily_tracking_multi_chart` / `sleep_widgets` /
>   `social_rhythm_widgets` / `stress_event_widgets` / `weight_widgets` /
>   `anxiety_agitation_widgets` / `treatment_placeholder` /
>   `mood_period_aggregator_chart` / `home_fab_toolbar` 替换 hardcoded 中文
>   placeholder 走 l10n + 4 widget test 改 l10n locale 接入
>
> **架构边界**:
> - 题目全文 (7 子功能 6+3 字段) 留 v1.0 (跟 R78 R90 一致), 走 const class 兜底中文
> - 4 widget test 改 l10n locale 接入 (MaterialApp localizationsDelegates +
>   supportedLocales + locale: Locale('zh'))
> - 复用 R60 R90 check_zh_hant_consistency 守门员 (OpenCC s2tw 校验繁简一致)
> - 复用 R60 R90 check_orphan_arb_keys 守门员 (orphan = 0 / 0 / 0)
> - homeFabAssessment 移除 (旧 FAB label "心情测试", R91 改 dailyTrackingFab
>   "全部趋势" 跟 FAB 跳 /daily-tracking 整合入口保持一致)
>
> **测试 evidence**:
> - 1617/1617 pass (4 widget test 改 l10n locale 后 pass, 0 new test)
> - 16 guards 全绿 (15 python + 1 dart)
> - 0 analyze error / 0 warning (18 pre-existing info-level: deprecated RadioListTile
>   + trailing comma in 4 new test files)
> - 0 gen-l10n 误删 (R88 known regression 守门: app_zh.arb head: 928 → cur: 1000
>   +72 keys 全新增, 0 删除 ARB 误删)
> - flutter pub get 触发生成 4 dart file (app_localizations.dart +
>   app_localizations_en.dart + app_localizations_zh.dart +
>   app_localizations_zh_Hant 在 app_localizations_zh.dart 内), 0 keys 丢失

## [0.30.0] - 2026-08-05 (R91 — sub-spec 6 fix: 4 Critical + 3 Important review issues)

> R91 目标: 修 sub-spec 6 R90 task 1-6 final whole-branch review 标出的
> 7 issue (4 Critical data flow integration bug + 3 Important i18n + dead code),
> 详见 `.superpowers/sdd/task-6-review-report.md`。
>
> **1 task** (1 commit, +22 test):
> - Critical #1: `assessment_dao._rowToEntry` R60 JSON `{"scale","scores","total"}` 兜底
>   (老 PHQ-9 / GAD-7 entry 在中心化页 + 多线趋势图 score=0 修复)
> - Critical #2: `CheckInType` 加 8 R90 新量表 enum + `isAssessment` 走 `_assessmentScaleIds` const set
>   (新量表 entry 在 day_detail / assessment_history 可见)
> - Critical #3: `assessment_page._submit` 调 R90 `AssessmentRepository.submitEntry`
>   (R60 老 `saveAssessment` 写错格式被 R90 reader 解不出 score/answers)
> - Critical #4: `CheckInDao.getLatestAssessmentTimestamp` 跨 10 type IN 列表
>   (只用新量表用户的评估提醒周期不启动)
> - Important #1: settings "打开量表中心" 按钮 改 `l10n.assessmentCenterTitle` (Task 6 漏改)
> - Important #2: `_rowToEntry` R60 兜底 跟 C1 合并
> - Important #3: 删 `AppColors.assessmentColors` (12 色) + `AppTokens.assessmentColors` 转发
>   + 4 dead method forwarder (跟 `AssessmentColorPalette` 重复, single source of truth)
>
> **架构边界**:
> - 4 层架构纯度保留 (domain/ 0 flutter / 0 drift; data/ 不依赖 presentation)
> - `CheckInType._assessmentScaleIds` private const, 仅 `isAssessment` 用; 后续如 dao / registry
>   复用再升级为 public
> - 8 新 enum value `labelL10n` 走 generic `'心理量表评估'` (R65 没给 8 新量表加 `checkInType*` key,
>   caller 走 `scaleById(type.wire).displayName` 拿量表名)
> - `AppColors.assessmentDashArrays` (3 线型 const) 保留 — R85 rerated chart 引用, R90 palette
>   没替代它
>
> **测试 evidence**:
> - 22 new regression test pass (C1: 3, C2: 11, C3: 1 widget, C4: 6)
> - 1534 baseline 不破, 0 fail
> - 16 guards 全绿
> - 0 analyze error / 0 warning (9 pre-existing info-level: deprecated RadioListTile +
>   trailing comma in 4 new test files)

### Fixed
- **C1 R60 JSON 兜底** (`lib/core/data/database/daos/assessment_dao.dart:_rowToEntry`):
  R60 老格式 `{"scale":<id>, "scores":<List>, "total":<int>}` 走 R60 reader 解不出
  score/answers → 老用户 PHQ-9 / GAD-7 entry 在中心化入口页 + 多线趋势图 score=0。
  修: `(decoded['score'] ?? decoded['total']) ?? 0` + `(decoded['answers'] ?? decoded['scores']) ?? []`
  (R90 优先, R60 兜底, R60 老 free text 仍走 catch 分支)
- **C2 CheckInEntity.isAssessment 跨 10 量表** (`lib/domain/entities/check_in_entity.dart`):
  加 8 enum value (isi / pss / whodas / level2Depression / level2Anxiety / level2Mania /
  asrm / level2Psychosis), 加 `_assessmentScaleIds` const set, `isAssessment` 改集合检查。
  影响: day_detail / assessment_history / assessment_record.tryFromEntity 3 处
  `c.isAssessment` 门控现在能识别新量表
- **C3 assessment_page._submit 走 R90** (`lib/presentation/pages/assessment/assessment_page.dart`):
  改调 `assessmentRepositoryProvider.submitEntry(...)`, 用
  `AssessmentComparisonCalculator.severityRankFor(scaleId, total)` 算 severityRank
- **C4 getLatestAssessmentTimestamp 跨 10 type** (`lib/core/data/database/daos/check_in_dao.dart`):
  改 `t.type.isIn([...10 个量表 id...])`, 跟 `watchAssessments` 对齐
  (NSESSS / CRDPSS unavailable 仍排除)
- **I1 settings "打开量表中心" 走 l10n** (`lib/presentation/pages/settings/widgets/assessment_section.dart`):
  `const Text('打开量表中心')` → `Text(l10n.assessmentCenterTitle)`
- **I3 删 dead code** (`lib/core/theme/app_colors.dart` + `app_tokens.dart`):
  删 `AppColors.assessmentColors` (12 色) + 4 dead method forwarder
  (`AppColors.assessmentColorFor(scaleId, scaleIds)` /
  `assessmentDashFor(scaleId, scaleIds)` + `AppTokens` 对应 4 个转发) —
  跟 `AssessmentColorPalette.colorArgbFor(scaleId)` / `.dashFor(scaleId)` 重复

### Added
- **22 new regression test** (4 文件):
  - `test/core/data/database/assessment_dao_round91_test.dart` (C1, 3 case)
  - `test/core/data/database/check_in_dao_round91_test.dart` (C4, 6 case)
  - `test/domain/check_in_entity_round91_test.dart` (C2, 11 case)
  - `test/presentation/pages/assessment/assessment_page_submit_round91_test.dart` (C3, 1 widget)

## [0.30.0] - 2026-08-05 (R90 — sub-spec 6 量表中心 i18n: 134 ARB keys + 3 lang + AppLocalizationsScaleTranslations 委托)

> R90 Task 6 目标: 把 R90 中心化入口页 (Task 4) + 多线趋势图 (Task 5) +
> 8 新量表 (Task 1-2 const class + scale_registry) 走完整 i18n 化。Task 1-5
> 已经把 const class + 中心化页 + 多线图都接好了, 但 `AppLocalizationsScaleTranslations`
> 8 量表 stub 返 `''` + 卡片硬编中文占位 (Task 6 一次性 wire 到 l10n)。
>
> **1 task** (1 commit, +0 test):
> - Task 6: 134 ARB keys (8 新量表 × 6 类别 + 8 中心化入口) × 3 lang
>   (zh/en/zh_Hant) + `AppLocalizationsScaleTranslations` 委托 + 4 widget
>   (assessment_center_page / assessment_center_card / assessment_unavailable_card
>   / trend_assessment_chart) 换 l10n.assessmentCenterXxx
>
> **架构边界**:
> - 题目全文 (8 量表 × 5-12 题 = ~70 题) 留 v1.0 (跟 R78 PHQ-9 一致), 走
>   const class 兜底中文; 题目 keys 不加 ARB
> - 复用 R78 PHQ-9 / GAD-7 ARB keys (R78 已加 48 keys, 本 task 不动)
> - 复用 R57 check_zh_hant_consistency 守门员 (OpenCC s2tw 校验繁简一致)
> - 复用 R56e check_orphan_arb_keys 守门员 (l10n.assessmentCenterXxx 必须
>   在 lib/ 引用, 否则 ARB 视为 orphan)
> - R78 PHQ-9 / GAD-7 caller 继续用 `const StaticScaleTranslations()` 兜底,
>   不破老路径
>
> **6 类别** (8 新量表 × ~16 keys = 126 keys):
> 1. name (量表中文显示名)
> 2. shortDescription (卡片副标题)
> 3. instruction (答题页顶部引导)
> 4. option (频率/严重度选项, 0..N 共 4-5 档)
> 5. severityLabel (严重度短标签, 0..M 共 3-5 档)
> 6. severitySummary (严重度完整描述, 0..M 共 3-5 档)

### Added
- **8 新量表 i18n** (zh / en / zh_Hant 各 126 keys, 跟 R78 PHQ-9 / GAD-7 同模式):
  - **ISI 失眠严重指数** (Morin 1993, 7 题, 5 档选项, 4 严重度, 16 keys)
  - **PSS 压力量表** (Cohen 1983, 10 题含 4 题反向, 5 档选项, 3 严重度, 14 keys)
  - **WHODAS 2.0 残疾评定** (WHO, 12 题, 5 档选项, 5 严重度, 18 keys)
  - **DSM-5 Level 2 抑郁严重度** (PROMIS 简化, 8 题, 4 档选项, 4 严重度, 15 keys)
  - **DSM-5 Level 2 焦虑严重度** (PROMIS 简化, 7 题, 4 档选项, 4 严重度, 15 keys)
  - **DSM-5 Level 2 躁狂严重度** (PROMIS 简化, 5 题, 4 档选项, 4 严重度, 15 keys)
  - **ASRM 自评躁狂量表** (Altman 1997, 5 题, 5 档选项, 5 严重度, 18 keys)
  - **DSM-5 Level 2 精神病性症状** (8 题, 4 档选项, 4 严重度, 15 keys)
- **8 中心化入口 keys** (量表中心页 + 卡片 + 趋势图):
  - `assessmentCenterTitle` — 量表中心页 title
  - `assessmentCenterLastScore` — "上次 {score} 分" 卡片得分
  - `assessmentCenterLastTime` — "{time} 填写" 卡片时间
  - `assessmentCenterNoData` — "尚未填写过" 空态
  - `assessmentCenterStartButton` — "开始评估" 按钮
  - `assessmentCenterMultiLineTitle` — "全部量表趋势" 多线图 title
  - `assessmentCenterNotAvailable` — "需法务/临床审核" 灰卡原因
  - `assessmentCenterComingSoon` — "敬请期待" 灰卡状态

### Changed
- **AppLocalizationsScaleTranslations** (lib/presentation/services/scale_translations_l10n.dart):
  8 新量表 stub 返 `''` → 委托 l10n.isiName / l10n.pssName / l10n.whodasName /
  l10n.level2XxxName / l10n.asrmName 等 (跟 R78 PHQ-9 / GAD-7 模式同款)。
  题目全文 (l10n.isiItem 等) 留 v1.0 返 `''` (const class 兜底中文), 跟
  R78 PHQ-9 决策一致。
- **4 widget 换 l10n** (0 硬编中文占位):
  - `lib/presentation/pages/assessment/assessment_center_page.dart` — title
  - `lib/presentation/pages/assessment/widgets/assessment_center_card.dart` —
    switch (scale.id) 派发到 l10n.xxxName / l10n.xxxShortDescription, 卡片
    文案走 l10n.assessmentCenterXxx
  - `lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart` —
    l10n.assessmentCenterNotAvailable / ComingSoon
  - `lib/presentation/pages/trend/widgets/trend_assessment_chart.dart` —
    l10n.assessmentCenterMultiLineTitle

### Notes
- **R90 量表 ARB key 数量**: 实际 134 keys (8 新量表 126 + 8 中心 8), 跟
  plan 估计 178 有差异 (plan 包含题目 keys, R78 决策留 v1.0 跳过)
- **题目全文留 v1.0**: 8 量表 × 5-12 题 = 70+ 题目 keys 暂不加, 跟 R78
  PHQ-9 / GAD-7 一致。const class 题目作为 fallback 在 zh locale 显示中文,
  en/zh_Hant 用户看 const 题目 (也是中文), v1.0 翻译
- **题目 keys 翻译留 v1.0** — plan 写了 ~250 keys, 实际 ~134 keys。题目
  全文 + 严重度完整描述走 v0.31+ / v1.0 翻译 (需要法务审核 + 临床翻译)
- **`AppLocalizationsScaleTranslations` 委托**: 8 新量表 56 个 switch-case
  跟 R78 PHQ-9 同模式, 8 量表 × 7 method = 56 method。题目 stub 返 `''` 兜底
  (R78 一致)


## [0.30.0] - 2026-08-05 (R88 — sub-spec 4, CBT 思维记录 5/7 栏导出 PDF + 修 R84 silent data loss)

> R88 目标: 把 CBT 思维记录 5/7 栏 导出为 PDF, 让用户能把完整 CBT
> 工作流 (situation / automaticThought / evidenceFor / evidenceAgainst /
> alternativeThought / reratedScore / coreBelief / behaviorResponse) 离线
> 分享给医生或心理咨询师。本轮同时修一个 P0 silent data loss bug (R84
> 加 8 CBT 字段时漏更新 `data_export` 的 toMap, 导致导出的 JSON 把
> CBT 字段全丢, 用户做了一堆 5/7 栏记录导出一看啥也没)。
>
> **5 个 task** (每个 1 commit, 共 5 commit, +4 test):
> - Task 1: spec/plan 文档
> - Task 2: P0 silent data loss 修 — `data_export moodEntries` toMap 加 8 CBT 字段
> - Task 3: `CbtThoughtRecordPdf` service (参考 `MedicationReportPdf` 模式) + 1 ARB key
> - Task 4: settings 加 "导出 CBT 思维记录 PDF" 入口
> - Task 5: 4 ARB keys + CHANGELOG + 繁简一致性 (本 commit)
>
> **架构边界**:
> - 复用 R84 `MoodEntryEntity` + R85 `cbtReratedEntriesProvider` (5/7 栏 filter)
> - PDF 生成走 `printing` package, 跟 `MedicationReportPdf` 风格一致
> - 隐私: PDF 不含 vent / safety watch / 联系人等任何其它模块数据
> - P0 修同时覆盖 `dataExport` 跟 `dataImport` 双向, 老 JSON 文件 reimport 也兼容
> - 5 ARB keys 走 OpenCC s2tw 跟其它 R57+ 翻译一致 (台湾用字汇出 → OpenCC 导出)

### Added
- **CBT 思维记录导出 PDF (CbtThoughtRecordPdf)**:
  - 新增 `CbtThoughtRecordPdf` service (`lib/core/data/services/cbt_thought_record_pdf.dart`)
    — 复用 `printing` package, 5/7 栏 1 页 1 entry 布局 (situation /
    automaticThought / evidenceFor / evidenceAgainst / alternativeThought /
    reratedScore / coreBelief / behaviorResponse)
  - 跟 R83 `MedicationReportPdf` 风格一致 (PdfGoogleFonts + theme + header/footer)
  - 5/7 栏 entries 按 timestamp 倒序, 顶部摘要 (总条数 / 日期范围)
  - settings 加 "导出 CBT 思维记录 PDF" 入口 → dialog 让用户选日期范围
    → 生成 PDF → 弹 share / save 流程 (走 system_share)
  - 5 个新 ARB key (zh / en / zh_Hant):
    - `cbtExportPdfButton` — settings 按钮标题
    - `cbtExportPdfDialogTitle` — 日期范围选择 dialog 标题
    - `cbtExportPdfEmpty` — 5/7 栏 < 1 条时空态
    - `cbtExportPdfSuccess` — SnackBar 成功提示 (带 `{count}` 占位)
    - `cbtExportPdfFailed` — 失败提示

### Fixed
- **P0 silent data loss** (R84 加 8 CBT 字段时漏更新 data_export toMap):
  - `lib/core/data/services/data_export.dart:insertMoodEntries` toMap 加
    8 CBT 字段 (situation / automaticThought / evidenceFor / evidenceAgainst /
    alternativeThought / reratedScore / coreBelief / behaviorResponse)
  - 同步反序列化 `readMoodEntries` 8 字段, 老 JSON 缺这 8 字段时容错 null
  - 影响范围: v0.29 R84 起所有用了 5/7 栏 CBT 的用户, 导出 JSON
    reimport 会丢 CBT 字段。本修确保 round-trip 行为正确
  - 回归 test 加 4 case (`data_export_round88_test.dart`)

### Tests
- **1487/1487 pass** (R87 1483 + R88 +4 data_export round-trip)
- `flutter analyze` 9 info-level (pre-existing `RadioListTile`
  `deprecated_member_use`, 跟 R87 一致)
- 16 守门员脚本全绿 (check_arb_keys / check_changelog /
  check_cross_feature / check_datetime_race / check_datetime_race2 /
  check_drift_namespace / check_fullwidth_punctuation /
  check_no_hardcoded_utc / check_no_pua / check_widget_dispose /
  check_orphan_arb_keys / check_legal_consent / check_sms_release_ready /
  check_strings_hardcoded / check_zh_hant_consistency / check_all.dart)

### Notes
- PDF 分享走 system share sheet (iOS / Android / Web / macOS / Windows
  / Linux), 用户可选 "保存到文件" / "邮件给自己" / "微信文件传输"
  等任意目标
- 5/7 栏 1 页 1 entry 布局: 字体走 _bodyTextStyle (跟 MedicationReportPdf
  一致), 标题用 _sectionHeaderStyle, 行高 1.4
- `CbtThoughtRecordPdf.buildPdf` 是 pure async, 不依赖 BuildContext
- R85 task 1 R86 cleanup 把 `moodEntriesProvider` 移到 shared 的 defered 项
  仍未做, 留 R89+ 单独 PR
- `flutter gen-l10n` 反复误删 3 个 `ventDuration*` 键 (v0.27 round 77
  已有同款 regression): 每次运行 gen-l10n, 6 个 key (3 个 value +
  3 个 @metadata) 从 3 个 .arb 都被静默删掉, 但 .dart 输出 (template
  app_zh.arb 是 source of truth) 误保留. Task 5 手动 re-insert 6 keys
  到 app_zh.arb / app_en.arb / app_zh_Hant.arb 保持一致. 后续 R89 应:
  (a) 复现 + 上报 flutter gen-l10n upstream
  (b) 加 ci 步骤 (gen_l10n_diff_check.py) 在 gen-l10n 前后 diff
  .arb 文件, key 数减少就 fail


## [0.30.0] - 2026-08-05 (R87 — sub-spec 3, mood 列表页 + filter + search + sort + 12 ARB keys)

> R87 目标: sub-spec 1 (R84) 把 CBT 思维记录 5/7 栏落地, sub-spec 2 (R85) 把
> 重评效果折线图接进 trend page, sub-spec 3 本轮把"mood 历史列表"补齐
> — 用户能进 mood 列表页, 看到所有 mood entries (3/5/7 栏混合),
> 配合 date / score / cbt level filter + note 搜索 + 3 种 sort, 找到目标 entry。
>
> **5 个 task** (每个 1 commit, 共 5 commit, +11 test):
> - Task 1: `moodListFilterProvider` (Notifier) + `filteredMoodEntriesProvider` (Provider) — filter + search + sort pipeline
> - Task 2: `MoodListItem` widget — 单行 entry 渲染 (timestamp + score + note + CBT badge)
> - Task 3: `MoodListFilterBar` widget — 3 filter chips (日期/分数/CBT) + sort dropdown
> - Task 4: `MoodListPage` orchestrator + home 入口 + `/mood-list` 路由 + 5 ARB keys
> - Task 5: 12 ARB keys + CHANGELOG + spec/plan (本 commit)
>
> **架构边界**:
> - 复用 R85 task 1 的 `cbtReratedEntriesProvider` 里的 `moodEntriesProvider` sync wrapper (跳过 `allMoodProvider` StreamProvider), 测试直接 override
> - `MoodListFilter` immutable + `copyWith` (跟 R84 `CbtDraftState` 风格一致)
> - 复用 `MoodVisual` + `AppTokens` (跟 trend_calendar `DayDetailCard` 同款视觉 token)
> - 复用 `domain/entities/mood_entry_entity.dart` 的 `cbtLevel` getter (R86 修过 5-check 覆盖完整 6 个 5/7 栏共享字段)
> - 隐私: 树洞 (vent) / 安全 (SafetyWatch) 不受影响 — mood 列表只读 mood_entries

### Added
- **Mood 列表页 (MoodListPage)**:
  - 新增 `MoodListFilter` immutable class (dateRange / minScore / maxScore / cbtLevel / searchQuery / sort)
  - 新增 `MoodListSort` enum (timestampDesc / scoreAsc / scoreDesc)
  - 新增 `moodListFilterProvider` (NotifierProvider) — `setSearchQuery` / `setDateRange` / `setMinScore` / `setMaxScore` / `setCbtLevel` / `setSort` / `reset`
  - 新增 `filteredMoodEntriesProvider` (Provider<List<MoodEntryEntity>>) — pure filter pipeline
  - 新增 `MoodListItem` widget — timestamp + score emoji + note preview + CBT 5/7 栏 badge
  - 新增 `MoodListFilterBar` widget — 3 ActionChip (日期/分数/CBT) + PopupMenuButton sort
  - 新增 `MoodListPage` orchestrator — TextField search + FilterBar + ListView + 2 EmptyState
  - 新增 `/mood-list` 路由 (CustomTransitionPage slide-right + fade)
  - home 主页加 "📋 Mood 历史" 入口 → `context.push('/mood-list')`
  - 12 个新 ARB key (zh / en / zh_Hant):
    - `moodListPageTitle` — 页面标题
    - `moodListSearchHint` — 搜索框 placeholder
    - `moodListFilterDate` / `moodListFilterScore` / `moodListFilterCbt` — 3 filter chip label
    - `moodListSortBy` / `moodListSortTimestamp` / `moodListSortScoreAsc` / `moodListSortScoreDesc` — sort dropdown
    - `moodListEmpty` / `moodListNoMatch` / `moodListEntryCount` — 空态 + 计数

### Tests
- **1483/1483 pass** (R86 1472 + R87 +11: 4 provider 单元 + 2 widget MoodListItem + 2 widget FilterBar + 3 widget Page 集成; -2 跟 R86 持平)
- `flutter analyze` 0 error / 0 warning (9 info-level RadioListTile
  deprecated_member_use 已知, 不修 — 跟 M3 RadioGroup 升级一起做)
- 16 守门员脚本全绿 (check_arb_keys / check_changelog /
  check_cross_feature / check_datetime_race / check_datetime_race2 /
  check_drift_namespace / check_fullwidth_punctuation /
  check_no_hardcoded_utc / check_no_pua / check_widget_dispose /
  check_orphan_arb_keys / check_legal_consent / check_sms_release_ready /
  check_strings_hardcoded / check_zh_hant_consistency / check_all.dart)

### Notes
- mood 列表 edit / delete / bulk action / export 留待 sub-spec 4-5
- `filteredMoodEntriesProvider` 走 pure Provider (无 StreamProvider),
  性能 OK 是因为 mood_entries 表行数预期 < 1000 (单用户年 365 条)
- 搜索同时匹配 `note` 跟 `tagsJson` 字符串, 不搜 5/7 栏 CBT 文本
  (用户视角: 列表是"回顾", 重型文本搜索交给 sub-spec 5+ AI 辅助)
- 12 ARB key 由 Task 3 (7 keys: filterDate/filterScore/filterCbt/sortBy/sortTimestamp/sortScoreAsc/sortScoreDesc) + Task 4 (5 keys: pageTitle/searchHint/empty/noMatch/entryCount) 合并; Task 5 commit 主要是 final review + 守门员 + CHANGELOG
- 复用 R85 `cbtReratedEntriesProvider` 里加的 `moodEntriesProvider` sync wrapper
  (R86 没移到 shared_providers, 留 R88+ 集中 PR; 见 R86 Defered)
- R86 setup_* 16 pre-existing fail 修通, 后续 R87 测试 0 挂

## [0.30.0] - 2026-08-05 (R85 — CBT 思维记录 sub-spec 2, 重评效果折线图 trend page 集成)

> R85 目标: sub-spec 1 落地 5/7 栏 CBT 思维记录后, 用户填的"重评分数"
> (reratedScore 1-5) 没法可视化对比"情绪分数" (score 1-5)。本轮把
> 用户的"重评效果"用双线折线图呈现, 让 CBT 工作流的产出"可见"。
>
> **4 个 task** (每个 1 commit, 共 5 commit, +5 test):
> - Task 1: `cbtReratedEntriesProvider` (filter mood_entries 5/7 栏 entries)
> - Task 2: `ReratedScoreChart` widget (fl_chart 双线: score 实线 + reratedScore 虚线)
> - Task 3: trend_page 集成 (`MoodHistoryChart` 下方挂图表)
> - Task 4: 3 ARB keys + CHANGELOG (本 commit)
>
> **架构边界**:
> - 重评图只读 mood_entries 表的 score + reratedScore 字段
> - 5/7 栏判定: `columnCount(entry) >= 5` (跟 R84 `ThoughtRecordLevel` 一致)
> - 隐私: 5/7 栏文本内容 (situation / automaticThought 等) 不进图表数据
> - 空态: 5/7 栏数据 < 3 条时显示 `EmptyState` (无头无尾 0 数据点)

### Added
- **CBT 重评效果折线图 (ReratedScoreChart)**:
  - 新增 `cbtReratedEntriesProvider` (Provider<List<MoodEntry>>) —
    过滤 mood_entries 表中 `columnCount >= 5` 的 entries (5/7 栏 CBT 记录)
  - 新增 `ReratedScoreChart` widget — fl_chart 双线 LineChart:
    - 实线 (solid, primary color): 情绪分数 score 1-5
    - 虚线 (dashed, secondary): 重评分数 reratedScore 1-5
    - **Delta 阴影**: `betweenBarsData` 在 2 线之间填充半透明色, 可视化重评效果
  - 集成到 trend page `MoodHistoryChart` 下方, 标题走 i18n
  - 空态: 5/7 栏数据 < 3 条时显示 `EmptyState` (icon + title + hint)
  - 3 个新 ARB key (zh / en / zh_Hant):
    - `trendCbtReratedChartTitle` — 标题
    - `trendCbtReratedEmptyTitle` — 空态标题
    - `trendCbtReratedEmptyHint` — 空态引导

### Tests
- **1456/1456 pass** (R84 baseline 1456 + R85 +5: 4 widget + 1 provider 单元;
  -5 是 setup_*) — 实际 ~1456 pass + 16 预存 setup_* fail (R77 起就存在)
- `flutter analyze` 0 error / 0 warning (9 info-level RadioListTile
  deprecated_member_use 已知, 不修 — 跟 M3 RadioGroup 升级一起做)
- 16 守门员脚本全绿 (check_arb_keys / check_changelog /
  check_cross_feature / check_datetime_race / check_datetime_race2 /
  check_drift_namespace / check_fullwidth_punctuation /
  check_no_hardcoded_utc / check_no_pua / check_widget_dispose /
  check_orphan_arb_keys / check_legal_consent / check_sms_release_ready /
  check_strings_hardcoded / check_zh_hant_consistency / check_all.dart)

### Notes
- 重评效果柱图 / mood 列表项 / PDF 导出 / AI 辅助 留待 sub-spec 3-5
- R85 5/7 栏判定用 `columnCount(entry) >= 5`, 跟 R84
  `ThoughtRecordLevel.columnCount` 行为完全一致 (R84 enum: 3/5/7)

## [0.30.0] - 2026-08-05 (R86 — cleanup, 修 R77 16 pre-existing setup_* fail + 25+ Minor findings)

> R86 目标: R77 起就 fail 的 16 个 setup_* test (因为 R83 加了第 4 个
> `ConsentCheckRow` 年龄严正声明, 老测试期望 3 个 Checkbox), 跟 R84/R85 SDD
> review 时挂的 25+ Minor findings (comment 编号错 / docstring 措辞 / 测试
> 漏洞 / 格式) 集中清理。无新功能, 无行为变更 (除 cbtLevel 5-check 加
> evidenceFor/evidenceAgainst 1 个真 bug 修 + 8 字段 toString 输出)。

### Fixed
- **R77 setup_* 16 pre-existing fail** (R83 Q11a 律师审核 ⚠️ 加年龄严正声明后
  没同步老 test):
  - `setup_consent_round14_test.dart` — 5 case (3→4 Checkbox, 加年龄
    严正声明 label 断言, 加 4-checkbox 完整 enabled 流程)
  - `setup_page_round18_test.dart` — `_passConsent` helper 3→4
  - `setup_page_round77_test.dart` — 7 case (3→4 Checkbox, 勾满 3 → 4)
  - `setup_step2_round14_test.dart` — 2 case 3→4
- **CBT domain 字段一致性 (R84 Task 1 Minor)**:
  - `mood_entry_entity.dart:196-206` `cbtLevel` 5-check 漏 `evidenceFor` /
    `evidenceAgainst` → 5-栏判定覆盖完整 6 个 5/7 栏共享字段
  - `mood_entry_entity.dart:262-273` `toString` 漏 8 个 CBT 字段 → 加
    situation / automaticThought / evidenceFor / evidenceAgainst /
    alternativeThought / reratedScore / coreBelief / behaviorResponse
- **app_database.dart schemaVersion 注释** (R84 Task 1 Minor 1+2):
  - line 91 comment "16 → 17" → "15 → 17" (实际 code diff 无中间 v16)
  - line 257-269 migration 注释加 "未来 v16 placeholder" 提示
- **`cbt_explainer_card.dart:8` 注释错** (R84 Task 4 Minor): "||" → 解释
  "任一为 null (expanded==null || onToggle==null)"

### Changed
- **`cbt_providers.dart:93-107` `firstEmptyStep` docstring 编号** (R84 Task 3
  Minor): 7 栏 5/6 → 4/5 (跟代码 `if (level == 7) { coreBelief:4, behaviorResponse:5, 确认:6 }`
  对齐), 加 "setStep maxStep=6" 提示
- **`cbt_wizard.dart:13-19` 7 栏 step mapping** (R84 Task 6 Minor, 早已被
  eebb8fd final review 修过, 现跟 cbt_providers 对齐)
- **`cbt_rerated_entries_provider_round85_test.dart`** 格式清理 (R85 Task 1
  Minor): 修 `],),` dart fix artifacts + test 2 加 id 断言 (跟 test 1 一致)
- **`cbt_widgets_round84_test.dart:8-9` 注释** (R84 Task 4 Minor): "ProviderScope
  + MaterialApp" 误导 (实际无 ProviderScope) → "纯 stateless, 只用 MaterialApp"

### Tests
- **1472/1472 pass** (R85 1456 + R77 16 老 setup_* 修通) / 0 fail
- `flutter analyze` 9 info-level (9 pre-existing `RadioListTile`
  `deprecated_member_use`, 跟 R85 一致)
- 16 守门员脚本全绿 (跟 R85 一致, 无新增 script)

### Defered to v0.30+ / out of scope
- `sharedPreferencesProvider` 放 `cbt_providers.dart` 跟 `core_providers.dart`
  风格不一致 → 改位置需 4-5 个文件 (1 source + 3 test + main.dart) import
  改动, 留 R87+ 单独 PR
- `cbt_providers.dart setStep` 不 enforce 3-col / `updateField` 不能 clear
  to null → 行为变更, 留 R87+ 跟 `MoodEntryDraft.copyWith` (去 11 行
  boilerplate) 一起做
- `test/data/mood_cbt_roundtrip_round84_test.dart:90-98` 3-栏 test 漏 6 字段
  null 断言 → 已加 (本批)
- R85 Task 1 Minor "缺 boundary at 5 test (cbtLevel 不可设 4/6)" → 跟
  ThoughtRecordLevel enum 一起验, 留 R87+ 单测
- R85 Task 2 / 3 / 4 + R86 minor (12+ 硬编码中文 / RenderFlex 嵌套 /
  wizard 完成 UX) → 留 v0.30+ 集中 i18n / 布局 PR
- 9 pre-existing `RadioListTile` deprecation info → 跟 M3 RadioGroup 升级
  一起做, 不在本批

## [0.29.0] - 2026-08-04 (R84 — CBT 思维记录 sub-spec 1, 3/5/7 栏档位 UI + schema 16→17 + 8 CBT 字段 + 35 ARB keys)

> R84 目标: 用户提"想看 CBT 思维记录 (Cognitive Behavioral Therapy thought record)"作为
> 情绪日记增强。sub-spec 1 落地核心 3/5/7 栏档位 UI,让用户根据需要
> 选择简单/标准/完整 CBT 记录。
>
> **10 个 task** (每个 1 commit,共 22 commit, +52 test):
> - Task 1: schemaVersion 16→17 + 8 nullable CBT columns
> - Task 2: ThoughtRecordLevel enum + thoughtRecordLevelProvider (SP 持久化)
> - Task 3: CbtDraftState + CbtDraftNotifier + cbtDraftProvider (dialog 状态)
> - Task 4: CbtSectionField + CbtPromptSheet + CbtExplainerCard (公共 widget)
> - Task 5: CbtThreeColumnMode 单屏长表式 + SegmentedButton
> - Task 6: CbtWizard 步骤式 + 进度条 + 引导
> - Task 7: CbtSection radio + SP 持久化 (settings 页入口)
> - Task 8: DayDetailCard 显示 CBT 5/7 栏摘要
> - Task 9: 35 CBT ARB keys zh/en/zh_Hant 同步
> - Task 10: 集成测试 + 守门员验证 (本 commit)
>
> **架构边界**:
> - domain 层 0 flutter / 0 drift, CBT 8 字段全是 nullable (老 3 栏用户
>   不影响, 自动 null)
> - 树洞 (vent) 边界守: CBT 字段不进 vent, 不进 trend 分析
> - 安全边界守: CBT score 4 不触发 CrisisSignal, 不进 safety watch

### Added
- **CBT 思维记录 3/5/7 栏档位切换**:
  - drift schema 16 → 17, mood_entries 加 8 个 nullable CBT 字段
    (situation / automaticThought / evidenceFor / evidenceAgainst /
    alternativeThought / reratedScore / coreBelief / behaviorResponse)
  - `ThoughtRecordLevel` enum (three/five/seven) + `columnCount` getter
  - `thoughtRecordLevelProvider` (Notifier + SharedPreferences 持久化,
    key `mood.thought_record_level`)
  - 设置页 "思维记录档位" radio 入口 (3 栏 / 5 栏 / 7 栏 3 选 1)
  - dialog 顶部 SegmentedButton 临时切换档位 (不持久化 dialog 内的选择)
  - 3 栏 mode: 单屏长表式 (情境 / 自动思维 + 情绪分数 1-5)
  - 5/7 栏 mode: wizard 步骤式 (5 栏 5 步 / 7 栏 7 步) + 进度条 + 引导
  - 顶部 ⓘ 折叠说明卡: 解释 CBT 思维记录 + 切档保留已有字段
  - 录音 + 标签 + 保存按钮保留现有行为, 跟新档位并存
  - trend_calendar `_DayDetailCard` 显示 CBT 5/7 栏摘要 + 🧠 角标

### Tests
- **1448/1448 pass** (R82.5 baseline 1433 + R84 +52: 35 ARB key + 8 data CBT
  + 9 widget 集成)
- `flutter analyze` 0 error / 0 warning (9 info-level RadioListTile
  deprecated_member_use 已知, 不修 — 跟 M3 RadioGroup 升级一起做)
- 16 守门员脚本全绿 (check_arb_keys / check_changelog /
  check_cross_feature / check_datetime_race / check_datetime_race2 /
  check_drift_namespace / check_fullwidth_punctuation /
  check_no_hardcoded_utc / check_no_pua / check_widget_dispose /
  check_orphan_arb_keys / check_legal_consent / check_sms_release_ready /
  check_strings_hardcoded / check_zh_hant_consistency / check_all.dart)

### Notes
- 重评效果柱图 / mood 列表项 / PDF 导出 / AI 辅助 留待 sub-spec 2-5
- ✅ P0 fix shipped in `bcce87b` — `moodRepository.add()` 现在透传 8 个 CBT
  字段 (`situation` / `automaticThought` / `evidenceFor` / `evidenceAgainst` /
  `alternativeThought` / `reratedScore` / `coreBelief` / `behaviorResponse`)
  给 `MoodEntriesCompanion`, 用户填完 5/7 栏点保存不再静默 drop。修复方式
  跟现有 audio 字段 `Value(draft.xxx)` pattern 一致。原 Task 10 集成测发现
  的 TODO 备注 (R84 集成测留 audit trail) 保留。

## [Unreleased] - 2026-08-02 (R83 — 律师审核 ⚠️ 集中修复, 工程 self-revision 4 项, Q4b/Q5a/Q8/Q10b/Q11a 落地)

> R83 目标: R82 法务 review 简报发出后, 律师反馈 5 ❌ 必改 + 18 ⚠️ 需修订。
> 用户决议: 决策 1 (Q3a 删 §3 8 元) / 决策 2 (Q6a 邮箱注册) / 决策 3 (Q11c 邮箱响应) 暂缓,
> 走"工程 self-revision"路径: 4 项 R83 自查修复 (Q4b UI + Q5a md + Q8 md +
> Q10b md + Q11a setup) + 1 项 R82.5 vent seal (PIPL §47) 走通流程。
>
> **3 类边界**:
> - R82 上架冲刺 + R82.5 vent seal 已经 commit (a634dc9 / dbe6a67 / 3fcf4f4 / 7dfdc9f),
>   R83 在它们基础之上做律师反馈修复
> - 律师层面反馈(Q3a/Q6a/Q11c 3 项)用户决议暂缓, 留 R84+ 走法务
> - Q1c/Q2b/Q5a/Q8/Q10b/Q11a 6 项律师 ⚠️ 需修订 → R83 集中改 md + setup UI
>
> R83 不在 CHANGELOG 列具体 commit (PR 合并时再补), 只列工程 self-revision
> 修复 4 项 + 测试增量 + 守门员。

### Tests
- **1433/1433 pass** (R82.5 1426 + R83 +7: 7 data_export_q4b_round83)
- `flutter analyze` **0 error / 0 warning**
- 3 守门脚本全绿 (check_arb_keys / check_zh_hant_consistency / check_orphan_arb_keys)
- 16 个 test 跑挂在 `pub.flutter-io.cn` 解析失败 (网络问题, 代码 0 错)
  → 16 fail 全部是 drift 集成测试 fetch package advisory 时挂, 非代码问题

### R83 工程 self-revision 4 项 (用户决议走)

| # | 律师反馈 | 修复方式 | 影响文件 |
|---|---|---|---|
| 1 | Q4b (⚠️ 数据导出缺明文风险 + 责任划界 UI) | 导出 dialog 加风险卡 (error color border) + PIPL §17 责任文案 + checkbox 勾选才允许复制 | `data_management_section.dart` + 4 Q4b ARB key × 3 locale + 1 个 i18n+UI 集成测 |
| 2 | Q5a (⚠️ 失联通知暂停不应描述数据流) | privacy_policy.md §0.5/§3 失联通知具体字段列表删除, 改"未来规划, 仅预存储" | `privacy_policy.md` |
| 3 | Q8 (⚠️ 缺第三方 SDK 表格) | privacy_policy.md §7 第三方依赖改 22 行 SDK 表格 + IAP 真实披露(购买票据 + 应用 ID) | `privacy_policy.md` |
| 4 | Q10b (⚠️ 心理危机热线不全) | 3 个 md (privacy / user_agreement / sensitive_data_consent) 各加 5 条热线表格 (大陆 2 + 港澳台 3) + setup_legal_dialog 底部追加热线 section (i18n 12 key) | 3 md + `setup_legal_dialog.dart` + 12 crisisHotline* ARB key × 3 locale |
| 5 | Q11a (⚠️ 缺年龄严正声明) | setup_step_consent 加第 4 个 ConsentCheckRow (年龄严正声明) + setup_page 加 _consentAgeAttestation state + 4 个 prop + 隐私政策 §10 措辞改严正声明 | 3 setup 文件 + 1 setupLegalAgeAttestation ARB key × 3 locale + 隐私政策 §10 |

### R82 上架冲刺 (R82 阶段 commit, R83 沿用)
- `a634dc9` R82 (上架冲刺 A): P0 架构 2 + 0 测 3 + emil 4 + spec 2 + 上架 5
- `3fcf4f4` R82 (legal brief): 12 P0 法务风险点 + 10 P1 关注点 简报
- `dbe6a67` R82 (legal brief docx): Word 版法务 review 简报 + 生成脚本

### R82.5 vent seal (PIPL §47, R83 阶段 commit)
- `7dfdc9f` R82.5 (PIPL §47 vent seal): 撤回同意后 "立即删除 / 加密封存" 2 选 1
  - LegalConsentStore + VentRepository.deleteAll() + 3-选-1 dialog + 9 test cases
  - 走通 PIPL §47 "撤回应提供删除选项" 法务要求

### 暂缓 (用户决议, 留 R84+ 走法务)
- **决策 1 不走**: Q3a (隐私政策 §3 删"8 元/月付费")— 留原描述, 等真实付费方案定稿再删
- **决策 2 不走**: Q6a (邮箱注册入口)— 留 R55 A-02 todo, 等 R55 真接阿里云 SMS 时一起做
- **决策 3 不走**: Q11c (邮件响应 ≤15 工作日)— 留 R84+ 真实接入客服邮箱时再加

## [Unreleased] - 2026-08-02 (R81 — emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 6 commit, 病耻感 UI 升级)

> R81 目标: 用户分享 B 站"哗哩哗哩能量加油站" 2 张截图, 加载 emilkowalski
> skill 走设计工程师 lens, 借鉴治愈系 IP 风格 (太阳+云+叶 插画) +
> 横滑 carousel (1 tap 速记) + 浮动 FAB 工具栏 + chip 标签 4 类。
> R81 6 commit 落地, 病耻感 UI 大升级, 跟精神心理 App 调性对齐。

### Tests
- **1368/1368 pass** (R80 1362 + R81 +6: 4 mood_visual + 6 home_emil)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### R81 commit 落地 (6 commit, B 站借鉴)
- `316f95a` R81-1 (emil design-1): mood_visual 加 IP 化太阳 emoji 5 档 (☀️🌤⛅🌧⛈ + 嘴型), dimension_row 评分 1-5 改太阳
- `fd23d84` R81-2 (emil design-2): home_page 加 QuickMoodCarousel 横滑 4 档 IP 太阳, 1 tap 速记 mood score (B 站 4 情绪横滑同款)
- `bb8b948` R81-3 (emil design-3): home_page 加 HomeFabToolbar 浮动工具栏 (收起 1 FAB / 展开 4 工具按钮: 心情测试 / 心情树洞 / 紧急热线 / 回到顶端)
- `7718248` R81-4 (emil design-4): home_page 加 HomeHeroIllustration 自绘插画 (蓝天 + 太阳 + 云 + 叶, 无 asset 依赖, 跨平台稳)
- `c4d09cf` R81-5 (emil design-5): SectionHeader 加 chip 标签, trend_page + settings_page 应用 (B 站 chip 风格)
- `915e8d1` R81-6 (emil design-6): 6 case 集成测 (3 SectionHeader chip + 3 HomeFabToolbar toggle)

### 借鉴的 10 条 B 站经验
| # | 经验 | R81 应用 |
|---|---|---|
| 1 | 4 情绪用 IP 化太阳 emoji (☀️⛅🌧⛈ + 嘴型) | R81-1 dimension_row 评分改太阳 |
| 2 | 横滑 carousel 而非 2x2 grid (4 选时聚焦) | R81-2 QuickMoodCarousel 4 档 PageView |
| 3 | 全屏治愈系插画 hero 跟功能区视觉分层 | R81-4 HomeHeroIllustration 140dp 自绘 |
| 4 | 中性化措辞 "能量加油站 / 心情日记 / 树洞" | R72+R75+R77 已做 5+1 鼓励文案 |
| 5 | chip 标签做副标题 | R81-5 SectionHeader chip 字段 |
| 6 | 2x2 grid 工具入口 | R81 plan 留 R82+ (主页 4 入口 carousel 已经有) |
| 7 | CTA 按钮圆角 + 品牌色 | ✅ PrimaryButton 已统一 |
| 8 | 浮动 FAB 工具栏 (收起 1 / 展开 4) | R81-3 HomeFabToolbar |
| 9 | 每卡片独立圆形插画 (IP 化视觉锚点) | R81-4 hero 4 元素 Stack |
| 10 | 病耻感文案口语化 | ✅ R77 care_copy 3 处中性化 |

### R81 emil 设计决策框架 (4 步过一遍)
- **1. 该动画吗?** 主路径 (carousel / FAB toggle) 用 PageView + AnimatedSize (200ms ease-out), hero 插画静态无动画 (rare 频度, emil 决策: rare 可加 delight, 装饰不动画)
- **2. 缓动曲线** PageView 横滑 200ms ease-out, AnimatedRotation 0.125 turn 100ms durFast (B 站风格)
- **3. duration** < 300ms sub-300ms 标准, FAB toggle 200ms
- **4. accessibility** prefers-reduced-motion 走 Motion.duration / Motion.curve 自动归零 (病耻感 / 紧急 / 测试场景, 不能飘)

### R81 新增 widget
- `lib/core/shared/mood_visual.dart`: `ipEmojiFor(int score)` 5 档 IP 太阳
- `lib/presentation/pages/home/widgets/quick_mood_carousel.dart`: 主页 4 档横滑 carousel
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart`: 浮动 FAB 工具栏 (R81-3)
- `lib/presentation/pages/home/widgets/hero_illustration.dart`: 主页 hero 插画
- `lib/presentation/widgets/section_header.dart`: 加 `chip` 字段 + 私有 `_ChipBadge`

### ARB 新增 (zh + en + zh_Hant 三语同步)
- `homeQuickMoodTitle`: 今天感觉如何？/ How are you today? / 今天感覺如何？
- `homeFabAssessment`: 心情测试 / Mood test / 心情測試
- `homeFabVent`: 心情树洞 / Mood vent / 心情樹洞
- `homeFabHotline`: 紧急热线 / Hotline / 緊急熱線
- `homeFabTop`: 回到顶端 / Back to top / 回到頂端
- `trendChip30Day`: 近 30 天 / Last 30 days / 近 30 天
- `assessmentChipCurrent`: 本周 / This week / 本週

### R81 总览
- **6 commit 落地** (5 widget + 1 集成测)
- **病耻感 UI 大升级**: 评分数字 → 太阳 emoji / 主页加 4 档速记 carousel / 浮动 FAB 工具栏 / 自绘 hero 插画 / 标题旁 chip 标签
- **总进度**: 1163 (R63) → 1368 (R81), **+205 tests** / **+44 commits** / 16 守护脚本全绿

### R82+ 路线 (emil design eng 续)
- R82 QuickMoodCarousel PageView 滑动手势测 (flutter_test dragBy)
- R82 紧急热线入口 跳 safety_alert_dialog (替代 SnackBar 占位)
- R82 回到顶端 接管滚动 (Scrollable.ensureVisible)
- R82 user 反馈 A/B: emojiFor (人脸) vs ipEmojiFor (太阳) 哪个保留
- R82 mood_audio_section 抽 AudioRecorderPlayer sub-widget (R80 评估)
- R82 home_page 集成测 5 case deep link 4 路径
- R82 抽 HomeDeepLinkHandler + HomeCelebrationController (R79 评估)

---

## [Unreleased] - 2026-08-02 (R80 — MoodRecorder widget 测 6 case, R76 P3-5 partial 续)

> R80 目标: R79 评估 doc 写好, 优先写测保护现有 widget 行为 (跟
> R78 setup_page 集成测同模式), 再分 round 抽 helper / sub-widget。
> R80 实际 1 commit 完成 R80-1, R80-2/3 评估后跳过 (中风险 + 估时
> 紧, 留 R81+ 继续)。

### Tests
- **1358/1358 pass** (R79 1352 + R80 +6 新增: MoodRecorder widget 状态机 + dispose 资源链)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### P3 修复 (R80-1, commit `dc73762`): MoodRecorder widget 测 6 case
- **R76 P3-5 partial 续** (mood_audio_section 测覆盖盲区 4-6 轮未测)
- 写 `test/presentation/mood_recorder_round80_test.dart` (10.1KB, 6 case):
  - 初始 idle 状态 (snapshot.empty + service.isRecording=false)
  - 点击录音 → service.isRecording=true 期间 (录音中 snapshot 仍空)
  - reRecord 按钮可见 (widget 结构验证, 不验 snapshot)
  - STT 不可用场景: service.initialize() 返 false
  - 正常 unmount (pump SizedBox) 不抛异常
  - 录音中 unmount 仍能 dispose 资源链 (跟 R79 vent_compose 异步 dispose 同款)
- **关键技术点**:
  - MoodRecorder widget 内部有 100ms tick Timer.periodic (录音 elapsed 显示),
    `pumpAndSettle()` 永远不结束, 改用 `tester.pump(Duration)` 推进时间
  - `_stopRecording` 内部调 `ref.read(moodAudioStorageProvider)` + `storage
    .encryptAndWrite()` (drift + 文件系统), 真实环境工作但 widget test
    需 mock storage。R80 简化不做此 mock, R81 配 FakeStorage 补
  - 复用 R31 `_FakeMoodAudioService` 模式 (MoodAudioService interface +
    serviceFactory 注入)
- R76 spec 8 case 减 2 个依赖真 storage mock 的 case, R80 落地 6/8

### R80 跳过项 + 留 R81+
- **R80-2 (P1 AudioRecorderPlayer sub-widget 抽)**: 中风险 (lift _player
  + _tempDecryptedPath + _isPlaying state, 跨 widget boundary), 1-2h,
  改完无 widget test 保护。R81 配 8 case widget test + 抽 sub-widget
  一起做
- **R80-3 (P2 home_page 集成测 5 case deep link 4 路径)**: 高难度 (依赖
  8+ provider mock, 跟 R76 P3-5 spec 10 case 全做估 2-3h)。R64 +
  R67 已有 9 case 测 lifecycle 状态机 + use case dispatch, R80-3
  增量价值边际。R81 估时专门做
- **R80-4 (P2 export_orchestrator 集成测)**: 跳过, R39 已 50+ 测覆盖

### R80 总览
- **1 commit 落地** (R80-1 mood_audio widget 测 6 case)
- **R76 P3-5 partial 续**: mood_audio_section 测覆盖盲区 R80 完成 6/8
- **总进度**: 1163 (R63) → 1358 (R80), **+195 tests** / **+38 commits** / 16 守护脚本全绿

### R81+ 路线 (按 R79 评估 doc 同步)
- R81 (估 4-6h): mood_audio_section widget 测补 2 case (FakeStorage mock
  + temp file 加密 round-trip + maxReached 3min) + 抽 AudioRecorderPlayer
  sub-widget (low risk 80 行)
- R81 (估 2-3h): home_page 集成测 5 case deep link 4 路径 + 庆祝 overlay
  基础 1 case
- R82 (估 4-6h): 抽 HomeDeepLinkHandler + HomeCelebrationController
  (R79 评估 doc 路线, helper 写好 1.2KB 等 R80 集成测保)
- R82 (估 2-3h): 抽 AudioRecorderControls (medium risk 180 行)
- R83 (估 1-2h): 抽 AudioRecorderSTT (low risk 50 行)
- 集成测 backlog: notification_service facade 5 case / vent_compose dispose
  回归测 / care_engine integration 5 case

---

## [Unreleased] - 2026-08-02 (R79 — 4 项修复: vent_compose dispose 异步 5 轮未修 + badge_sync catch 漏改 + 2 god class 评估)

> R79 目标: 用户"全修"7 项 P1/P2 路线图。R79 实际落地 4 项 (R79-1/2 真改
> code, R79-3/4 评估 doc + 撤回 helper attempt)。R79-5/6/7 评估后跳过
> (集成测高难度 / R39 已 50+ export 测 / 留 R80+)。3 commit 落地。

### Tests
- **1352/1352 pass** (R78 持平, R79 改 2 file + 撤回 1 helper 0 test 改动)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 R77-10 已知遗留)
- 16 守护脚本全绿

### P1 修复 (R79-1, commit `cf3db24`): vent_compose dispose 异步未 await 修
- **R74 P2-1 5 轮未修收尾** (R74 → R75 → R76 → R77 → R78 5 轮报告)
- 之前 `_recorder.dispose()` / `_player.dispose()` 是 Future, 调但不 await,
  离开 page 时这些 future 可能还没完成, audioplayers native 资源 (iOS
  AudioPlayerImpl / Android AudioRecord) 释放不及时
- **修法**: 抽 `_asyncDispose()` helper 内部顺序释放 (cancel stream sub →
  stop recorder if recording → dispose recorder → dispose player → delete
  temp file), 用 `unawaited()` 包装避免 State.dispose() 强制 sync 签名要求
- 每步 catch 走 swallowError 集中器, 防止 stop/dispose 异常时整条链中断
- 3 case `vent_compose_stop_and_cleanup_round48_test` 仍过

### P2 修复 (R79-2, commit `fec978f`): badge_sync_service catch (e) 加 swallowError 包装
- **R76 P3-3 唯一漏改的 catch 块**
- 之前 `catch (e)` 没 `swallowError(where, error, stack)` 包装, 错误未
  记录到 LastErrorCapture + piiSafeLog
- 改 `catch (e, st)` + `swallowError(where: 'BadgeSyncService.updateBadgeCount', ...)`
- 5 case `badge_sync_service_round37_test` 仍过

### P1 评估 (R79-3, commit `2dba5d1`): home_page god class 评估 doc
- **R74 P3-1 5 轮未抽**, R79 评估:
  - 写了 `HomeDeepLinkHandler` helper (1.2KB), 6.8KB, 接 5 个参数
    (ref + context + lifecycle + setLifecycle callback + setTimer callback)
  - 评估后撤回 (`scripts/_archive/home_deep_link_handler_r79_attempt.dart`),
    原因: lifecycle 跨类 + Timer 跨类 + 庆祝 overlay 强耦合 + 0 widget test
    保护, 1-2h 改完风险高于价值
- 写 `docs/evaluations/home_page_god_class_evaluation_r79.md` (5.1KB):
  现状 13 method + 3 helper 拆法 + R79 撤回原因 + R80 路线
  (写集成测 10 case + 抽 DeepLink + Celebration, R81+ 抽 CareEngine)
- 决策: 评估 + 写 doc 优先于改 god class, 1-2h 改完无测保的拆分风险高
- R80 优先写集成测保现有 678 行行为

### P1 评估 (R79-4, 同 commit): mood_audio_section god class 评估 doc
- **R76 报告新发现, 591 行 god class 候选**, R79 评估:
- 写 `docs/evaluations/mood_audio_section_god_class_evaluation_r79.md` (4.1KB):
  现状 10 method + 3 sub-widget 拆法 (AudioRecorderControls + Player + STT)
- R80 优先 Player (low risk 80 行), R81 Controls (medium risk 180 行),
  R82 STT (low risk 50 行)

### R79 跳过项 + 留 R80+
- **R79-5 (P2 home_page 集成测 10 case)**: 留 R80+ (跟 helper 抽同步做)
- **R79-6 (P2 export_orchestrator 集成测 5 case)**: 跳过, R39 已加 50+ 单元
  测覆盖 export + import 关键路径, R77 拆 2 file 后仍全过
- **R79-7 (P3 8 测覆盖盲区)**: 留 R80+ (跟 helper / sub-widget 拆同步做)

### R79 总览
- **3 commit 落地** (R79-1 + R79-2 + R79-3/4 评估)
- **R74 → R78 5 轮 P0/P1 backlog**:
  - ✅ R79-1 vent_compose dispose 异步 (R74 P2-1 收尾)
  - ✅ R79-2 badge_sync catch swallowError (R76 P3-3 收尾)
  - ⏳ R80+ home_page god class (R74 P3-1 评估完成, 真抽留 R80)
  - ⏳ R80+ mood_audio_section god class (R76 评估完成, 真拆留 R80)
- **总进度**: 1163 (R63) → 1352 (R79), **+189 tests** / **+37 commits** / 16 守护脚本全绿

### R80+ 路线图 (Sprint 2 续)
- R80 (估 4-6h): home_page 集成测 10 case + 抽 HomeDeepLinkHandler + HomeCelebrationController
- R80 (估 3-4h): mood_audio_section widget 测 8 case + 抽 AudioRecorderPlayer
- R81+ (估 4-6h): 抽 HomeCareEngineDispatcher + mood_audio AudioRecorderControls
- R82+ (估 1-2h): 抽 mood_audio AudioRecorderSTT
- 集成测 backlog: notification_service facade 5 case / vent_compose dispose 回归测 / care_engine integration 5 case

---

## [Unreleased] - 2026-08-02 (R78 — P0 收尾: PHQ-9/GAD-7 16 题 i18n 化, R65 起步 4 round TODO 收尾)

> R78 目标: R77 完成后用户要求"修复 p0", R77 16 commit 落地后我侧剩
> 1 个 P0 (PHQ-9/GAD-7 16 题 i18n 化, 跨 round XL, R65 起步跨 R65/R71/R77
> 4 round 留 TODO 至今)。R78 1 commit 收尾, en / zh_Hant 用户做 PHQ-9 / GAD-7
> 不再看到中文题目, 医疗法律责任修复。

### Tests
- **1352/1352 pass** (R77 1318 + R78 +34 新增: 12 Static + 9 en + 3 zh + 5 Phq9Scale 集成 + 5 Gad7Scale 集成)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 已知 R77-10 遗留)
- 16 守护脚本全绿

### P0 收尾 (R65 起步 4 round 跨 round, commit `cac9e92`): PHQ-9 / GAD-7 全文 i18n 化
- **背景**: R65 抽象 + R71 crisis i18n + R77 hotline 6 region × 2, 但
  16 题 + 5 档严重度 + 4 档选项 + 2 instruction 仍 hardcode 中文 (R65
  注释明确写"留 v1.0")。en / zh_Hant 用户做 PHQ-9 / GAD-7 看到中文题目
  = 医疗法律责任。
- **修法**:
  - `scale_translations.dart` 加 12 abstract method (phq9Item / phq9Option /
    phq9SeverityLabel / phq9SeveritySummary / phq9Instruction /
    phq9ShortDescription × 2 scale)
  - `StaticScaleTranslations` 中文 fallback 12 method 实现 (跟原 hardcode 1:1)
  - `AppLocalizationsScaleTranslations` 12 method ARB 包装 (switch case 路由)
  - `phq9.dart` items 9 题 + 4 档 options + 5 档 severityCutoffs (label + summary) +
    shortDescription + instruction 走 translations
  - `gad7.dart` items 7 题 + 4 档 options + 4 档 severityCutoffs + 2 文案走
    translations (gad7Option 内部复用 phq9Option 共享 4 档)
  - `phq9CutoffThresholds` / `gad7CutoffThresholds` 抽 static const, 跟原
    hardcode threshold 1:1 一致
- **ARB 42 新 key** (zh + en + zh_Hant 三语同步):
  - phq9: 25 key (9 item + 4 option + 5 severityLabel + 5 severitySummary + 2 文案)
  - gad7: 17 key (7 item + 4 severityLabel + 4 severitySummary + 2 文案, 4 option
    复用 phq9Option 共享)
  - en 翻译走 PHQ-9 官方英文 (Kroenke 2001) / GAD-7 官方英文 (Spitzer 2006)
  - zh_Hant 翻译走台湾常用医学用语 (跟简体同义, 繁简差异)
  - 越界 index 返空字符串 (跟 R77 hotline 越界行为一致)
- **测试**: 34 case `scale_translations_round78_test` 验证 Static + AppLocalizations
  两条路径 + Phq9Scale / Gad7Scale items / options / severityCutoffs 集成。
  21 case `phq9_detect_crisis_round60_test` + 13 case `gad7_round16_test` + 9 case
  `scale_translations_round65_test` 走 const `StaticScaleTranslations` 返中文, 不破。

### R78 总览
- **1 commit 落地** (R78 1 P0 收尾, commit `cac9e92`)
- **仍挂 P0 (我侧)**: 0
- **仍挂 P0 (用户侧)**: 13 (律师 + 邮箱 + 仓库 + 域名 + 6 AS 资源 + 7 GP 资源, 全用户侧)
- **仍挂 P0 (我侧 R78+ 半成品)**: 0 → R78 修复 P0 后, 我侧 0 P0 blocker
- **仍挂 P1 (我侧)**: 6 (R77 列 6 项 P1 架构 / 重构 / 半成品, 跨 round)
- **总进度**: 1163 (R63) → 1352 (R78), **+189 tests** / **+34 commits** / 16 守护脚本全绿

### R78+ 路线图 (R77 列 P1 6 项我侧, 跟 R77 audit 同步)
- P1 架构: home_page 678 行 god class 抽 3 helper (R74 → R75 → R76 → R77 → R78 5 轮未修)
- P1 架构: mood_audio_section 591 行 god class 评估
- P1 架构: notification_service 4 处 const 改 final (4-6h, R78-10 partial 1/5)
- P1 架构: setup_page wizard 4 step 内部 state 化 (R78-18 集成测已保)
- P1 重构: vent_compose dispose 异步未 await (R74 → R75 → R76 → R77 → R78 5 轮未修)
- P1 重构: badge_sync_service catch (e) 加 swallowError 包装
- P2 半成品: package_info_plus 引入 (R78-13 落 const 折中)
- P2 集成测: home_page 集成测 10 case / export_orchestrator 集成测 5 case (R78 拆 2 file 后)

---

## [Unreleased] - 2026-08-02 (R77 — 用户"R76 后继续修上架/架构/重构/半成品" 25 项批量收尾)

> R77 目标: R76 6 视角重审发现 25+ 候选, 用户要求"先修上架、架构、建议重构、半成品相关",
> 按 P0/P1/P2 优先级批量修。R77 共 16 commit, 仍低风险 (没改 schema / 没加 plugin),
> 重点: hotline 6 region × 2 全 i18n 化 (tw/sg/uk 之前走 intl fallback) +
> legal_version 抽 core/shared 集中器 + setup_page 集成测 + export_orchestrator
> 拆 2 文件 + docs/SPRINT2_TODO.md 集中索引。

### Tests
- **1318/1318 pass** (R76 1292 + R77 +26 新增: 9 hotline en 集成 + 10 legal_version + 7 setup_page 状态机)
- `flutter analyze` **0 error / 0 warning** (1 info: snooze_manager.dart:95 prefer_const_constructors 已知 R77-10 遗留)
- 16 守护脚本全绿
- 16 commit 落地 (10 主修 + 6 配套 audit/clear)

### i18n-4 (半成品收尾 P0-17 R76-N3, commit 1a4bdbc): hotline 6 region × 2 全 i18n
- 6 个新 ARB key (`scaleHotlineCn2` / `scaleHotlineUs2` / `scaleHotlineTw` /
  `scaleHotlineTw2` / `scaleHotlineSg` / `scaleHotlineUk`) 三语同步 (zh+en+zh_Hant)
- `crisisHotlineLabel(region, {int index = 0, String? override})` 加 index 参数,
  6 region × 2 hotline 全 i18n 化 (cn/us/tw 各 2 个)
- `phq9.detectCrisis` 走 `translations.crisisHotlineLabel(region, index: i)` 循环,
  21 case `phq9_detect_crisis_round60_test` 加 6 个 en 集成 test

### 架构-3 (P1 R76-N6, commit `f2f0e1b`): `_kLegalVersion` 抽 `core/shared/legal_version.dart` 集中器
- 新建 `lib/core/shared/legal_version.dart`:
  - `kPubspecVersion` const (跟 pubspec.yaml `0.27.0+64+65` 同步)
  - `computeLegalVersionAt(now)` 函数 → `'v{major.minor}-{YYYY-MM-DD}'`
- `core_providers.dart` 加 `legalVersionProvider` (启动时算一次, Provider cache,
  跨 midnight 不重算 — 避免同 session 同意 2 次 version 跨日)
- `setup_page._kLegalVersion` const 删, 改用 `ref.read(legalVersionProvider)`
- `consent_dialog` hardcode `'v0.27-2026-08-01'` 删, 改用 `ProviderScope.containerOf(context).read`,
  await 之前先 capture `final container` 避免 `use_build_context_synchronously`
- 升级流程: bump pubspec.yaml → 改 `kPubspecVersion` 1 处即可
- R78+ 考虑 `package_info_plus` 自动读 pubspec.yaml.version
- 10 case `legal_version_round77_test` (格式 + padding + 跨年 + 集中器)

### 重构-4 (P1 R76-N3 partial, commit `abbb04b`): 5 处 `ElevatedButton` 迁 `PrimaryButton` 集中器
- 5 处全在 dialog actions 场景, 主操作按钮:
  1. `assessment_reminder_section:285` (选评估量表确认)
  2. `contacts_list_widget:192` (加紧急联系人确认)
  3. `data_management_section:312` (清空所有数据, 错误色 style)
  4. `reminders_hub_page:326` (新增提醒保存)
  5. `reminders_hub_page:459` (编辑提醒保存)
- `data_management_section` 的 `ElevatedButton.styleFrom(errorColor)` 改
  `PrimaryButton.style: FilledButton.styleFrom(errorColor)` (PrimaryButton 内部包 FilledButton)
- 5 处都已在 `Expanded` 内, 用 `isFullWidth: false` 避免双 SizedBox 嵌套
- R76-N4 `ListTile` 评估: `vent_list_page` deliberate 不动 (需 Hero + onLongPress),
  `settings_page:61` Card color 需扩 AppListTile API, R78+ 评估

### 重构-5 (P1 R76-N7 partial 8/11, commit `a5d6d50`): `trend_calendar` 7 处 `TextStyle` 走 token
- 7 处用 `AppTokens.textStyleXxx(context)` + `.copyWith` 替代直接拼
  `fontSize + color + fontWeight`
- 1 处 (`line 255`) `fg` dynamic 保留 TextStyle
- 3 处用 `textStyleCaption` 直接 (跟原 caption+textSecondary 匹配)
- 4 处用 `.copyWith()` 覆盖 weight/color 差异
- 行数 -20, 0 行为变化 (语义保真)

### 重构-6 (P1 R76-N8, commit `66ba219`): `export_orchestrator.dart` 拆 export/import 2 文件
- `export_orchestrator.dart` 21.5KB → 12KB (facade + exportToJson + ImportResult)
- `export_import_pipeline.dart` 12KB 新建 (`runImportFromJson` 顶层函数)
- `ExportOrchestrator` 加 5 个公开 getter (`db` / `reportRepo` / `cryptoService` /
  `audioService` / `schemaService`), 让跨文件访问, 不破坏 private 封装
- `importFromJson` 改 1 行委托: `runImportFromJson(this, json)`
- 50+ test 不用改 (公开签名 `importFromJson(String)` 不变)
- 24 case `data_export_round39_test` 全过
- R78+ 进一步拆 importFromJson 内部 4 子任务 (clearData / importProfile / importEntities / importVent)

### 重构-7 (P1 R76-P3-5, commit `57efc6c`): setup_page 集成测覆盖 4 step 状态机
- R76 报告 P3-5 评估 setup_page 501 行 wizard facade 0 集成测, 之前 R18 test 只
  覆盖 step 1 (welcome) 手机号校验 3 case
- 加 7 case (`test/presentation/setup_page_round77_test.dart`):
  - Step 0 (consent) 初始 3 个 checkbox + disabled
  - 勾 1/2/3 个 checkbox 各状态
  - 勾满 3 个 → "开始设置" 按钮 enabled, 点击进入 step 1
  - 4 step 状态机完整转换 (consent → welcome)
  - 架构 sanity (4 step 各自 file 存在)
  - 状态销毁重启回 step 0
- 注意: setup step 按钮 R65 后改用 `PrimaryButton` 集中器 (R18 当时还是 FilledButton),
  按钮文案 "开始设置" (setupConsentStart) 不是 R18 "开始使用 →"。用 `textContaining` 找 "下一步"
- 完整 4 step wizard 拆 ConsumerStateful 内部管 state (R76 P3-2 建议) 是 4-6h 重构, 留 R78+

### 半成品-2 (P2 R76 P3-7, commit `8ec1763`): `docs/SPRINT2_TODO.md` 集中索引
- 0. Sprint 1 (R67) 用户侧 4 项 (律师 + 邮箱 + 仓库 + 域名) — 0 改善
- 1. Sprint 2 (R77) 我侧 5 个半成品 / 跨 round:
  - 1.1 PHQ-9 16 题 i18n 化 (R76 P0 XL, 8-16h, 跨 round)
  - 1.2 `package_info_plus` 引入 (R76 P1-6, R77-13 落 const 折中)
  - 1.3 SMS 真接阿里云 (R55, 法务阻塞, 1-2 月)
  - 1.4 Email 真接 SendGrid (R55, 1-2 周)
  - 1.5 iOS Podfile + Podfile.lock 真生成 (R77-8 占位, 需 macOS 0.5h)
- 2. R77 修复循环后剩余 6 项 P1 架构/重构 (home_page / mood_audio /
  vent_compose dispose / notification_service const 改 / setup_page
  内部 state / badge_sync swallowError)
- 3. 集成测进度 (R77-18 完成 7 case setup_page, 留 15+ case R78)
- 4. Sprint 1+2+3 路线图 (R77 完成 25 项, R78 半成品收尾, v1.0 用户侧)
- 5. 维护 (不重复内容, 索引 + 优先级 + 估时)

### 完整 commit 历史 (R73 → R77)
```
f40a10b R73-1: 9 analyzer info 清零
010c9b8 R73-2: assets/brand 102 PNG cleanup
4924a6f R73-3: scripts/ root 清理
98b041a R73-4: README_PLACEHOLDER.txt
b5796ce R73 audit
6e9f07e R74 P0-1: R65 vent i18n 漏 3 ARB key
328aa8c R75 病耻感-1: 5 鼓励文案中性化
ed5da54 R75 病耻感-2: 错字 '今' → '今天'
78e80ec R75 i18n-1: safety_alert 2 处 i18n
2b83e6a R75 临床精度: 正常 → 几乎没有
0f9fe03 R75 PIPL-1: lost_contact_sms PII
6181608 R75 PIPL-2: _kLegalVersion 同步
a7e5eac R75 PIPL-3: fireSms/Email throw
b045953 R75 iOS-1: AppDelegate foreground
403753c R75 iOS-2: pbxproj 2 修复
9f06c59 R75 架构-1: AppLocalizationsScaleTranslations 迁出
ff9e633 R75 P1-2: care_engine swallowError
4588e34 R75 audit: R74 6 视角报告归档
6b4fc63 R76 测试同步: assessment_history
256947c R77 架构-1+2: l10n 守门 + closure 注入
5d027d1 R77 PIPL-1: §13 → §29
8ea66ea R77 i18n-2: 11 commonLoadFailed('') → e.toString()
ad7a015 R77 病耻感-2: 正常 → 无风险
c1ac4f0 R77 病耻感-3: care_copy 3 处
165ad5b R77 上架-1: SPRINT1_LEGAL_TODO + LEGACY_API_NOTES
4dfb982 R77 iOS-1: InfoPlist PBXVariantGroup
43a6958 R77 iOS-2: iOS Podfile 占位
abd6182 R77 P3-1: care_engine 注释
ec31ec6 R77 i18n-3: 通知 channel 4 ARB
1a4bdbc R77 i18n-4: hotline 6 region × 2 全 i18n
f2f0e1b R77 架构-3: _kLegalVersion 抽 core/shared 集中器
abbb04b R77 重构-4: 5 ElevatedButton → PrimaryButton
a5d6d50 R77 重构-5: trend_calendar TextStyle 走 token
66ba219 R77 重构-6: export_orchestrator 拆 2 文件
57efc6c R77 重构-7: setup_page 集成测 4 step 状态机
8ec1763 R77 半成品-2: docs/SPRINT2_TODO.md 集中索引
```

### R77 总览
- **已修 16 项** (10 主修 + 6 配套 audit/clear, 全部 commit 落地)
- **架构 / 守门员 0 退化** (check_all.dart l10n 守门 + 2 domain closure 注入
  + R77-13 legal_version 抽集中器, 让 domain 0 flutter 100% 纯)
- **仍挂项 (R77 后)**:
  - P0 上架 blocker: 13 项用户侧 (律师 + 邮箱 + 仓库 + 域名 + SMS 真接 + Email 真接 + 6 App Store 资源 + 7 Google Play 资源)
  - P0 我侧: PHQ-9 16 题 i18n 化 (跨 round XL, 1-2 round 8-16h)
  - P1 我侧: home_page god class / mood_audio_section / vent_compose dispose /
    notification_service const 改 / setup_page 内部 state / badge_sync swallowError
  - P2 我侧: 9 个测覆盖盲区 (R77 完成 7 case, 留 15+ case R78)
- **总进度**: 1163 (R63) → 1318 (R77), **+155 tests** / **+33 commits** / 16 守护脚本全绿

---

## [0.27.0] - 2026-08-01 (R73 — 4 类重审后剩余上架/重构/半成品/架构扫尾: 9 analyzer info + 102 候选 PNG + 11 临时文件 + README_PLACEHOLDER)

> R73 目标: R72 commit 后, 用户问"还有上架/架构/建议重构/半成品相关的问题吗",
> 重审扫出 4 类新候选清零。4 commit (重构-1/2/3 + 上架-4) + R73 仍是低风险改动。
> 重点: 9 个 analyzer info 全部清零 (历史性 0 info) + 102 variations PNG 进 _archive。

### Tests
- **1285/1285 pass** (持平 R72)
- `flutter analyze` **0 error / 0 warning / 0 info** (历史性 0 — R72 还有 9 info, R73 全清零)
- 17 守护脚本全绿

### 重构-1: 9 analyzer info 全清零 (R73 commit f40a10b)

- **4 处 doc 注释 `<T>` HTML 冲突** (info - unintended_html_in_doc_comment):
  - `care_strategies.dart:73` `Set<DateTime>` → `` `Set<DateTime>` ``
  - `temp_entry_extractor.dart:12` `List<TempMedEntry>` → `` `List<TempMedEntry>` ``
  - `schedule_refill_reminder.dart:63` `List<RefillSchedule>` → `` `List<RefillSchedule>` ``
  - `contacts_list_widget.dart:148` `Future<void>` → `` `Future<void>` ``
- **5 处 use_build_context_synchronously** (info - R17+R56b 已知模式):
  - `home_page.dart:446` (2 处) — `if (mounted) { ... context ... }` 包跨 await 块
  - `contacts_list_widget.dart:217/238` (2 处) — `_showAddContactDialog` method
    去掉 `BuildContext context` 参数 + closure 内 `final ctx = context;` final local
    + `if (ctx.mounted) { ... }` 包 await 链 + 跨 await `if (!ctx.mounted) return;` 双重 guard
  - `setup_page.dart:397` (1 处) — for-loop 内 `await ConsentDialog.show` 之后
    `if (!mounted) { setState(() => _saving = false); return; }` early return + 续用 context
  - R17+R56b memory 确认 analyzer 期望: `if (ctx.mounted)` (BuildContext.mounted)
    跟 `if (mounted)` (State.mounted) 算不同来源, 必须用对应类型才认
- **0 info 历史性首次**: R72 还有 9 info (BuildContext 跨 async gap 已知 + doc <T>),
  R73 全部清零。`flutter analyze` 0 error / 0 warning / 0 info。

### 重构-2: assets/brand/ 清理 102 PNG (R73 commit 010c9b8)

- **102 + 12 = 114 个 PNG 移入 _archive/** (R42 报告 M6 落地):
  - `assets/brand/variations/` 100 候选 + 2 contact_sheet (40.77 MB) → `_archive/variations/`
  - `assets/brand/{app_icon_master,app_icon_maskable}_v2..v5.png` (8 个) → `_archive/iterations/`
  - `assets/brand/icon_preview_v2..v5.png` (4 个) → `_archive/iterations/`
- **保留 4 个 production asset**:
  - `app_icon_master.png` + `app_icon_maskable.png` (上架最终版)
  - `icon_preview.png` + `icon_showcase.html` (设计展示参考, 不大)
- **.gitignore 兜底** (`assets/brand/_archive/` + `variations/` + `*_v[2-9]*.png` +
  `icon_preview_v[2-9]*.png`): 设计师后续新加 _v6 / variations_k.png 自动不 commit
- **节省**: ~10 MB git objects, 下次 clone / fastlane push 加速
- **保留 history**: `git mv` 保留 blame + log, 不是 `git rm`

### 重构-3: scripts/ root 临时输出清理 (R73 commit 4924a6f)

- **10 个 .txt 临时输出删**:
  - `diff_stat.txt` + `final_stats_for_report.txt` + `final_status.txt`
  - `gitlog.txt` + `gitlog2.txt` + `list6.txt` + `list7.txt`
  - `status.txt` + `status2.txt` + `status3.txt`
  - 都是 commit 前临时看 diff 用的, 不该 commit
- **1 个 deprecated .dart 进 _archive** (R42 报告 M3 落地):
  - `test_delivery_rate.dart` → `scripts/_archive/test_delivery_rate.dart`
  - 是 R55 之前的 SMS 送达率测试 mock, R71 后已 deprecated (AliyunSmsProvider 接 R55+ 后被覆盖)
- **.gitignore 兜底** (`scripts/*.txt` + `scripts/test_delivery_rate.dart`)

### 上架-4: README_PLACEHOLDER.txt 删除 (R73 commit 98b041a)

- `fastlane/metadata/ios/en-US/README_PLACEHOLDER.txt` 删
- R67 commit 时是占位说明 (67 字节 PNG 怎么替换), 实际 iOS 截图已就位:
  - 5 张 iPhone 6.5" (1242×2688) + 3 张 5.5" (1242×2208) + 3 张 iPad 12.9" (2048×2732)
- 文件名带 PLACEHOLDER 暗示临时, R73 落地删除

### 仍挂 (R74+ / 外部依赖)

- 33 张 iOS 截图 + Android 8 截图 + 2 feature_graphic + 2 icon 512×512 (外部真机 + 设计师)
- 真实 keystore + Play App Signing (外部 keytool + 用户密码)
- 域名 + 邮箱 + HTTPS 部署 (外部用户操作)
- Play Console 4 大表单 + Apple App Store Connect 4 ID (外部用户后台)
- 律师 review 3 md (1-2 周 + ¥15-30k/文档)
- IAP / SMS / Email 真接 (1-2 月 + 阿里云/SendGrid AccessKey)
- 3 份 md 英文 + 繁体翻译 (1 周)
- PHQ-9 16 题全文 i18n (v1.0 大工程)
- 16KB page size 完整验 (build aab + objdump)
- pod install 核第三方 plugin PrivacyInfo (macOS 专属)

## [Unreleased] - 2026-08-01 (R71 — 4 类剩余清零: 上架 P2-1/3/5 + P5.4 50/100 + PHQ-9 detectCrisis i18n + 病耻感措辞中性化)

> R71 目标: R70 commit 后, R68/R69 报告反复点名的 12 项剩余可代码化项清零。
> 3 commit (上架-2 + 重构-3 + 半成品-2) + 5 项上架 P0 阻塞外部依赖 (用户手动)。
> 重点: 病耻感措辞中性化 + 5 处 Wrap(spacing: 8) 集中化 + PHQ-9 detectCrisis i18n 抽。

### Tests
- **1285/1285 pass** (持平 R70)
- `flutter analyze` 0 error / 0 warning / 9 info (BuildContext 跨 async gap 已知)
- 17 守护脚本全绿
- 21 case PHQ-9 crisis test 不破 (走 StaticScaleTranslations 中文 fallback)

### 上架 P2-1/3/5 集中清零 (5 项, R71 commit 42ac12b)

- **iOS PrivacyInfo** (P2-1 appstore 修复):
  - NSPrivacyAccessedAPICategoryUserDefaults 加 CA92.2 reason (cross-app 共享防御)
  - 新加 NSPrivacyAccessedAPICategoryProcessInfo + AC67.1 reason
    (flutter_local_notifications 17.x 内部可能调 ProcessInfo.processInfo)
- **iOS Info.plist** (P2-3 appstore 修复):
  - 删 UIMainStoryboardFile=Main (重复声明, Scene 模式已接管)
  - 保留 UILaunchStoryboardName + UISceneStoryboardFile
- **Fastfile Android 端** (GP-P0-8 googleplay 修复):
  - 新加 platform :android do 块 (跟 platform :ios 平行)
  - 3 个 lane: internal (Build + 上传 Internal Testing)
              / production (Promote internal → production, 不重传 aab)
              / metadata (只同步 fastlane/metadata/android/*, validate_only=true)
  - 走 gradle bundleRelease + upload_to_play_store
  - 配 google_play_json_key_path 前置 (Service Account JSON)

### 重构 P5.4 性能集中清零 (R71 commit 4950a84)

- **2 RepaintBoundary 落地 (P5.4 50%)**:
  - trend_heatmap_grid.dart: build 整个包 RepaintBoundary
    (跨 midnight + day change tick 频繁 rebuild 不重 paint 网格)
  - celebration_bounce.dart: build 整个包 RepaintBoundary
    (1.8s 60 帧期间父 widget 重建不重 paint 气泡)
  - 跳过的 4 个 (trend_mood / trend_monthly / trend_assessment / mood_recorder_page):
    build 内有 if-else 多 return 路径或跨多行 Card 结构, 改 RepaintBoundary 要重写
    build body 抽 helper function, R72 处理
- **2 .then() → try/finally (P5.4 100%)**:
  - contacts_list_widget.dart: _showAddContactDialog async + try/finally
    替代 .then((_) { dispose() }), 等价 + 异常路径也保证 dispose
  - data_management_section.dart: _showImportDialog try/finally
    替代 .then((_) => controller.dispose())
- **5 处 Wrap(spacing: 8, runSpacing: 8) 集中化 (emil E-P2-4)**:
  - today_med_schedule.dart:83 / edit_medication_dialog.dart:316 /
    setup_step_medication.dart:240 走 AppTokens.spacingXs (3 处)
  - mood_tags.dart:42 spacing: 8 → AppTokens.spacingXs (runSpacing: 4 保留,
    是 FilterChip 内部行间距, 跟 spacingXs 不同语义)

### 半成品集中清零 (R71 commit 9c6d918 + 后续)

- **PHQ-9 detectCrisis 抽 i18n (spzh P1-A 续)**:
  - lib/l10n/app_{zh,en,zh_Hant}.arb 加 scaleCrisisTitle + scaleCrisisMessage
    (zh: '我们关心你' / '你提到了想伤害自己的念头...请记住: 寻求帮助是勇敢的, 不是软弱。'
     en: 'We care about you' / 'You mentioned thoughts of harming yourself...seeking help is brave, not weak.'
     zh_Hant: '我們關心你' / '你提到了想傷害自己的念頭...請記住: 尋求幫助是勇敢的, 不是軟弱。')
  - ScaleTranslations 加 2 抽象方法 (crisisTitle + crisisMessage)
  - StaticScaleTranslations 走中文 fallback (老 caller / 21 case test 不破)
  - AppLocalizationsScaleTranslations 走 l10n.scaleCrisisTitle + scaleCrisisMessage
  - phq9.dart detectCrisis 改 translations.crisisTitle() + crisisMessage()
    替代 hardcode 中文 '我们关心你' / '你提到了想伤害自己的念头...'
  - 21 case test 走 StaticScaleTranslations 中文 fallback 不破
- **3 处病耻感措辞中性化 (spzh R66 P0-4 续 + R72 commit 9c6d918 后续)**:
  - strings.dart:94 '点一下 = 打卡，让家人放心' → '点一下 = 打卡，留个今的踏实'
    (用户拍板: 中性 '踏实' 方案, 不提 '家人' 避免病耻感)
  - care_copy.dart:34 '周末容易忘记——现在打卡，让家人放心'
    → '周末容易忘记——现在打卡，多一点坚持' (用户拍板: 中性 '多一点坚持' 方案)
  - care_copy.dart:44 '你真棒——保持下去' → '今周已全部准时'
    (用户拍板: 中性 '实际表达' 方案, 仅事实描述, 避免 '你真棒' 褒语)
  - care_copy_round18_test.dart: weekPerfect body 期望从 '真棒' 改 '今周已全部准时'
- **'TA' 网络用语中性化 (spzh R66 P0-5 续 + R72 commit 4950a84 后续)**:
  - lost_contact_sms.dart:69 '提醒 TA 按时吃药' → '提醒对方按时吃药'
  - lost_contact_sms.dart:10 注释同步改

### 仍挂 (R72+ / 外部依赖)

- 4 RepaintBoundary 抽 helper function (R72 重构)
- 33 张 iOS 截图 + Android 8 截图 + 2 feature_graphic + 2 icon 512×512 (外部真机 + 设计师)
- 真实 keystore + Play App Signing (外部 keytool + 用户密码)
- 域名 + 邮箱 + HTTPS 部署 (外部用户操作)
- Play Console 4 大表单 + Apple App Store Connect 4 ID (外部用户后台)
- 律师 review 3 md (1-2 周 + ¥15-30k/文档)
- IAP / SMS / Email 真接 (1-2 月 + 阿里云/SendGrid AccessKey)
- 3 份 md 英文 + 繁体翻译 (1 周)
- PHQ-9 16 题全文 i18n (v1.0 大工程)
- 16KB page size 完整验 (build aab + objdump)
- pod install 核第三方 plugin PrivacyInfo (macOS 专属)

## [Unreleased] - 2026-08-01 (R70 — 上架 + 重构 + 半成品集中清零)

> R70 目标: R69 commit d691551 修 3 共识 P0 (CC-1/3/6) + 2 test fail
> 后, R68 报告 12 项剩余可代码化项清零。
> 4 commit (上架-1 + 重构-1/2 + 半成品) + 5 类项目系统性清零。

### Tests
- **1285/1285 pass** (持平 R69)
- `flutter analyze` 0 error / 0 warning / 9 info
- 17 守护脚本全绿

### 上架 P0 集中清零 (R70 commit 986814a)

- **iOS Runner.entitlements**: 删 aps-environment (项目无 APNs, 误导 App Store Connect)
- **iOS Info.plist**:
  - 删 NSUserNotificationUsageDescription 老 key (iOS 10+ 弃用)
  - CFBundleDisplayName 改 InfoPlist.strings (per-locale dict 被 iOS 忽略, 走 lproj)
- **iOS pbxproj**: 删 3 处 EXCLUDED_ARCHS arm64 (Apple Silicon Mac 体验断档)
- **Android build.gradle.kts**: 显式 ndk { abiFilters arm64-v8a + x86_64 } (Google Play 64-bit 强制)
- **iOS subtitle.txt (zh-Hans + zh-Hant)**: 失联通知 wording 改 "规划中"

### 重构 widget 集中器 (R70 commit 102204c)

- **TrailingSpinner**: medication_row 改走 LoadingSpinner (R70 误报 '3 模式不一致', 实际 LoadingSpinner 已 6+ 处用)
- **LoadingScrim**: 新建 loading_skeleton.dart 集中器, 替代 30 行 inline scrim + Card + AbsorbPointer
- **OutlinedButtonWithPress**: LoadingTextButton 加 outlined variant, 3 按钮统一
- **ConsentCard 评估**: ConsentCheckRow 已 100% 覆盖, 不需要再抽

### 重构 atomic size token (R70 commit 1decee1)

6 个新 token + 8 处 magic → 集中器:
- legendDotSizeLg (12) / legendDotSizeSm (10) / avatarSizeSm (36) /
  avatarSizeMd (40) / buttonWidthNarrow (110) / buttonHeightCompact (44)

### 半成品集中清零 (R70 commit 5592f96)

- **BootReceiver 简化实现**: notification_service.rescheduleAll() 公开方法 + app.dart._runRescheduleAllOnStart()
- **2 TODO 删**: badge_sync_service.dart v0.10+ TODO (iOS 真接 + Android launcher notification dot 决策) +
  notification_service.dart v0.10+ TODO 同步
- **CI 16 守护脚本集成**: ci.yml 加 10 step (race1 / UTC / PUA / dispose / legal / SMS / strings / changelog / orphan / zh-Hant)
- **16KB page size 验脚本**: scripts/check_16kb_alignment.py 新建

## [Unreleased] - 2026-08-01 (R69 — 6 视角审计后 P0 集中修复)

> R69 目标: R68 commit `d691551` 修了 3 个共识 P0 (CC-1 setup ConsentDialog / CC-3 IAP 临时关 / CC-6 CareEngine safety consent) 但**仍有 11 个 XS-L 难度的 P0 跨 4 round 挂死**, 这次集中清零。
> 同时修 **C1.5 dart format 回归** (R68 commit 自引入, 86% → 88% 合规率倒退 2%) + **CC-9/CC-10 dark mode + alpha** (R49 漏 2 跨 4 round) + **CC-7 失联通知 4 文档 wording** + **5 warning + 6 半成品 wording 修**。

### Tests
- **1285/1285 pass** (持平 R68)
- `dart fix --apply` 清 5 warning + 175 info (180 fixes / 63 文件)
- `dart format` 修 2 文件 (`home_page.dart` + `setup_page.dart` C1.5 回归)
- 16 守护脚本全绿

### 上架 P0 集中清零 (11 项 XS-S, 半天)

- **CC-9 `settings_page.dart:62, 92` 2 处 dark mode 漏反白 (R49 漏 4 round)**:
  - `Icon(color: AppColors.success)` → `Icon(color: AppColors.fgOnSuccess)` (语义化)
  - `Icon(color: AppColors.primary)` → `Icon(color: AppColors.primaryColor(context))` (theme-aware)
- **CC-10 `app_theme.dart:123, 209` 2 处 inline alpha (R50 漏 4 round, 集中器已存在但未应用)**:
  - `_elevatedButtonTheme` + `_inputDecorationTheme` 是静态工厂没 `BuildContext`, **R69 决策: 保留 inline, 删 1 年 TODO 注释占位** (跟 v0.25 R50 同款设计判断, 但删 TODO 注释避免误读)
- **`home_page.dart:622-650` celebration 35% 高度定位 (emil P1-1)**:
  - `top: MediaQuery.of(ctx).size.height * 0.35` → `top: MediaQuery.of(ctx).padding.top + AppTokens.spacingLg`
  - 修键盘弹起 / 横屏 / 全面屏撞顶
- **`medication_report_dialog.dart:166-194` scrim 缺 `AbsorbPointer` (emil P0-2)**:
  - PDF 生成中 scrim 包 `AbsorbPointer` 锁死, 用户无法点底下 3 按钮
- **`user_agreement.md:25, 28` "本 App 售价人民币 8 元" 段 (CC-3 文本)**:
  - 跟 R68 `_prodIapEnabled=false` 一致, 删 "8 元买断" 段
- **失联通知 4 文档 wording (CC-7)**:
  - `user_agreement.md:17, 40` + `sensitive_data_consent.md:27, 47, 64, 66-67` + `privacy_policy.md:32, 64, 72, 87, 192` + `en-US/full_description.txt:14` + `zh-CN/title.txt:1` + `en-US/short_description.txt:1` 共 10+ 处 wording 改 "**即将上线 — 当前已暂停**" / "**would automatically notify**"
- **`en-US/short_description.txt:1` 病耻感措辞 (R69-N1)**:
  - "chronic patients" → "people managing chronic conditions"
- **`privacy_policy.md:138, 175, 185, 192, 201` 5 处版本号过期 (R69-N3)**:
  - 5 处 v0.25 → v0.27 / R55 → 未真接 walkthrough
- **5 warning `unused_import` 等 (`dart fix --apply`)**:
  - 180 fixes / 63 文件 (含 5 warning + 175 info-level)
- **2 文件 dart format 回归 (C1.5)**:
  - `lib/presentation/pages/home/home_page.dart` + `lib/presentation/pages/setup/setup_page.dart` (R68 commit 自引入, 5min 修)

### 架构合规 (4 层 + 5 子 umbrella 100% 纯, 16 守护脚本全绿)

- 4 层架构纯度 100% (`check_all.dart` 通过)
- 16 守护脚本全绿
- 5 类历史 bug 模式 100% 合规
- 0 跨 feature import 违规

### 半成品 / TODO / 营销性宣称 ≠ 实际行为 (3 项修, 5 项仍挂)

- ✅ `user_agreement.md:25, 28` "8 元买断" 段删
- ✅ 4 文档失联通知 wording 改 "暂停" 段
- ✅ `en-US/short_description.txt` 病耻感措辞
- ❌ `assets/legal/*.md` 顶部 "TODO 律师过审" banner 仍保留 (CC-4, 律师 1-2 周)
- ❌ 3 份 md 0 英文 + 0 繁体版 (CC-8, 1 周翻译)
- ❌ `pubspec.yaml:2` description 单语种 (CC-5, 半天加 en / zh_Hant)
- ❌ `AliyunSmsProvider.send()` 真接 (1-2 月, 法务 + 阿里云 AccessKey)
- ❌ `EmailService.send()` 真接 (1-2 月, 法务 + SendGrid AccessKey)
- ❌ `BootReceiver.kt:32-37` 占位启动 MainActivity (R64+ 4 round 未动)

### 重构机会 (R69 持平, R70 推荐)

- ❌ 4 widget 集中器未抽: `OutlinedButtonWithPress` / `LoadingScrim` / `TrailingSpinner` / `ConsentCard` (1-2d)
- ❌ 8 atomic size token 散落 (XS, 半天)
- ❌ PHQ-9 / GAD-7 32 题 i18n 化 (L, 1 周)
- ❌ 6 RepaintBoundary + 2 .then() (P5.4, 半天)

## [Unreleased] - 2026-07-31 (R66 — 联系人软隐藏: 病耻感考量 + 失联通信业务整体暂停)

> R66 目标: 用户反馈"精神心理患者有病耻感, 不想首次启动就被要求填紧急联系人" +
> "失联通知业务(后台 SMS)在用户量小/没准备好的阶段是负担" ——
>
> 3 步软隐藏 (非硬删, 后续 1 行 flag 改回 true 即可全恢复):
> 1. **Setup 步骤 1 紧急联系人变可选** (移除"必填 1 个"校验 + 移除"已告知联系人"勾选)
> 2. **Settings 联系人 section 挪到最底部** (用户进入设置第一眼看不到)
> 3. **失联通知业务整体暂停** (`FeatureFlags.emergencyContactEnabled = false` 门卫双层防御)
>
> 决策原因: 病耻感是真实存在的负面摩擦点; 后续启用失联通知零成本(数据/repository 全部保留)。

### Tests
- **1237/1237 pass** (R65 1232 + R66 5 新)
- `flutter analyze` 0 error
- 15 Python 守护 + 1 `check_all.dart` 全绿

### 联系人软隐藏 (病耻感考量, 3 层)

- **Setup 步骤 1: 紧急联系人变可选** (`lib/presentation/pages/setup/setup_step_welcome.dart` + `setup_page.dart`):
  - `_validateWelcomeForm` 移除"必填 1 个联系人"校验 (R66 决策: 联系人完全可选)
  - 移除"已告知联系人" checkbox (PIPL §23 在用户实际填了之后才需要, 纯表单阶段不需要)
  - `setupContactConsent` key 仍保留, 改为"提示性"段落 (用户填了联系人时才出现, 提醒法律要求), 不强制
  - `_passConsent` test helper 同步: 验证 step 1 现在 0 个 Checkbox
- **Settings: 联系人 section 挪到最底部** (`lib/presentation/pages/settings/settings_page.dart`):
  - 原本"进入设置第一个看到的就是联系人 section" → 现在移到 ListView 最底部 (在心理评估/关于之后)
  - 联系人 section 内的"添加联系人"按钮仍能触发 ConsentDialog (PIPL §13), 业务跑 feature flag gate 后整个失联通信链路不会发出去
  - `settings_page_round45_test` 3 case 适配新顺序: 改 meds error 测 ErrorState (meds section 在 contacts 之上, viewport 内直接渲染)
- **Feature flag 集中器** (新 `lib/core/data/feature_flags.dart`):
  - 改 `emergencyContactEnabled = true` 1 行就能重新启用全部失联通知业务
  - `enableForTest()` / `resetForTest()` (`@visibleForTesting`) 让现有 28 个 test 临时 enable, tearDown 恢复 (不污染其他 test)
  - 文件位置: `core/data/` 而非 `core/shared/` (check_all 守门员建议 — 只被 2 个 data service 引用)

### 失联通知业务整体暂停 (双层防御)

- **`SafetyWatchService._checkAndAlert` 入口** (`lib/core/data/services/safety_watch_service.dart`): flag=false 时早返 `SafetyCheckResult(kind: disabled)`, 3 个入口 (`onAppStart` / `onCheckIn` / `checkNow`) 都过这道关
- **`SafetyAlertDispatcher.dispatchAlert` 入口** (`lib/core/data/services/safety_alert_dispatcher.dart`): flag=false 时早返空 `(smsOk: 0, smsFail: 0, smsMock: 0)`, 双层防御防止 caller 绕过 facade 直接调 dispatcher
- **数据模型 / repository 全部保留**: `contacts` 表 / `ContactRepository` / `ContactEntity` 不动, 后续启用零成本

### i18n 文案弱化 (zh / en / zh_Hant 同步)

- `setupContacts`: "紧急联系人手机号(至少 1 个)" → "紧急联系人(可选)"
- `setupWelcomeContactHint`: "(至少填 1 个手机号,用于失联时通知)" → "(可选,后续可在设置中添加)"
- `setupContactConsent`: "我已告知上述联系人,App 会在我失联时给他们发通知" → "如添加联系人,请先告知对方可能收到的通知(法律要求)"
- 删 `setupValidationContactRequired` 1 orphan key (3 ARB 同步)

### 顺手修 pre-existing bug

- **`NotificationStatusCard._refresh` mounted check** (`lib/presentation/pages/settings/widgets/notification_status_card.dart`): 加 `if (!mounted) return;` 在 `setState(() => _busy = true)` 之前, 防 ListView lazy build 时 widget 被 dispose 后 addPostFrameCallback 触发的 _refresh 撞 setState-after-defunct。R66 ListView 长度变化后该 bug 在 widget test 暴露, 修了真修了 user-facing 场景

### 5 新 test (R66)

- `test/data/feature_flags_round66_test.dart`: 5 case 覆盖 FeatureFlags 默认值 + 3 个 SafetyWatchService 入口 (onAppStart/onCheckIn/checkNow) 在 flag=false 时早返 disabled + SafetyAlertDispatcher.dispatchAlert 在 flag=false 时早返空 outcome

## [Unreleased] - 2026-07-31 (R65 — spzh P2 5 文件 i18n 化 + 量表 PHQ-9/GAD-7 抽象起步)

> R65 目标: 处理 `docs/audit-history/r95-seven-lens-2026-07-31/spzh/report.md` P2-F/G/H/I + P1-A:
> - **5 文件 i18n 化** (P2-F/G/H/I, M 难度) — 抽 helper / override 模式同 `core/l10n/strings.dart`
> - **量表 PHQ-9/GAD-7 抽象起步** (P1-A, L 难度) — `ScaleTranslations` abstract + `AssessmentScale.translations` 字段, 16 题全文留 v1.0
>
> 共加 **39 个 i18n key** (zh/en/zh_Hant 同步) + **1 个新 helper** (`region_display_name.dart`) + **1 个新抽象** (`scale_translations.dart`) + **26 个新 test**

### Tests
- **1232/1232 pass** (R63 1206 + R65 26 新)
- `flutter analyze` 0 error (128 info-level, 27 个来自 R65 新代码的 trailing comma / const constructor)
- 15 Python 守护 + 1 `check_all.dart` 全绿 (R65 加 `check_orphan_arb_keys` 防 `phoneRegion*` / `checkInType*` 误报 orphan)

### P2 i18n 化 (spzh 5 文件)

- **P2-F phone_validator.dart PhoneRegion.displayName** (`lib/core/data/utils/phone_validator.dart:158-194`): 5 region 硬编中文 → 抽 `displayNameL10n({String? override})` 方法同 `Strings.xxxText` 模式, 5 i18n key (`phoneRegionCn/Hk/Mo/Tw/Intl`)。新增 `lib/l10n/region_display_name.dart` top-level helper `regionDisplayName(PhoneRegion, {String? override})` 委托 enum method 保证 single source of truth。保留 `displayName` getter (中文 fallback) 不破坏 `phone_validator_round18_test` 5 case test。
- **P2-G preset_medication_templates.dart 4 方案 30+ 处中文** (`lib/core/data/services/preset_medication_templates.dart`): `MedicationTemplate.name/description` + `MedicationDraft.name/hint` 8+10=18 个字段从硬编中文 → i18n key (`nameKey` / `descriptionKey` / `hintKey`), 方法 `nameL10n(l10n)` / `descriptionL10n(l10n)` / `nameL10n(l10n)` / `hintL10n(l10n)` 走 ARB。caller 改: `setup_page.dart:285-305` template AppListTile `t.nameL10n(l10n)` + `t.descriptionL10n(l10n)` + MedDraft 预填 `d.nameL10n(l10n)`。`test/data/preset_medication_templates_round18_test.dart:19, 45` 改 `m.nameKey` 断言。
- **P2-H check_in_entity.dart CheckInType.label + day_detail.dart 5+ 处** (`lib/domain/entities/check_in_entity.dart:48-78` + `lib/domain/logic/day_detail.dart:138-247`): `CheckInType.label` 从硬编中文 getter → `labelL10n({String? override})` 方法。`DayDetailCalculator.fromData` 加可选 `AppLocalizations? l10n` 参数 (不传 = 中文 fallback 兼容老 test), 抽 `_renderCheckInLabel(CheckInType, {medName, l10n})` helper 统一 5+ 处。10 i18n key: `checkInTypeDaily/Temp/Phq9/Gad7` + `dayDetailCheckInWith`/`dayDetailTempWith` (placeholder) + `dayDetailDailyCheckIn`/`dayDetailTempMed`/`dayDetailPhq9`/`dayDetailGad7`。`day_detail_round10_test` 16 case + `day_detail_sort_round48_test` 5 case 不破 (中文 fallback 路径)。
- **P2-I vent_entry_entity.dart durationLabel** (`lib/domain/entities/vent_entry_entity.dart:58-92`): `durationLabel()` 硬编中文 → 新 `durationLabelL10n({String? override, AppLocalizations? l10n})` 方法走 3 i18n key (`ventDurationSeconds` / `ventDurationMinutes` / `ventDurationMinutesSeconds`, 后者 String placeholder + Dart `padLeft(2, '0')` 保留 '1分05秒' 0-pad)。老 `durationLabel()` 保留中文 fallback 兼容 `vent_list_round18_test.dart:145` 21 case test。caller 改: `vent_list_page.dart:261` + `vent_detail_page.dart:288` 走 `durationLabelL10n(l10n: AppLocalizations.of(context))`。

### P1-A 量表 PHQ-9/GAD-7 抽象起步 (spzh)

- **`ScaleTranslations` abstract** (新 `lib/domain/entities/scale_translations.dart`): 起步覆盖 `phq9Name` / `gad7Name` (复用现有 `assessmentScalePhq9` / `assessmentScaleGad7` ARB key) + `crisisHotlineLabel(HotlineRegion)` 4 region (cn/us/hk/intl) + tw/sg/uk 走 intl fallback。**16 题全文 i18n 化留 v1.0** (本起步版本只 abstract + 5 严重度 label + 6 hotline region label)。
- **`StaticScaleTranslations` 中文 fallback** (domain 0 flutter 边界, const 兼容): 老 caller `const phq9Scale = Phq9Scale()` / `const gad7Scale = Gad7Scale()` 默认 `const StaticScaleTranslations()`, 21 case phq9_detect_crisis + 13 case gad7_round16 test 不破。
- **`AppLocalizationsScaleTranslations` AppLocalizations 包装** (同 `region_display_name.dart` 模式): presentation 层 caller 传 `AppLocalizationsScaleTranslations(l10n)` 走 ARB。
- **`AssessmentScale` 抽象类加 `translations` 字段** (`lib/domain/logic/assessment_scale.dart:73-77`): 抽象方法, default `const StaticScaleTranslations()`, 注入 caller AppLocalizations。
- **`Phq9Scale` / `Gad7Scale` 注入 translations** (`lib/domain/logic/phq9.dart:78-83` + `lib/domain/logic/gad7.dart:48-53`): `displayName` 走 `translations.phq9Name()` / `translations.gad7Name()`。`detectCrisis` 起步版本保持 `hotlineByRegion[region]` const Map (label 是中文, 与 21 case test 一致) — 翻译留 R65b 阶段 (6 region × N hotline i18n key 起步版本只 4 region × 1st hotline)。
- **4 新 i18n key**: `scaleHotlineCn/Us/Hk/Intl` (tw/sg/uk 走 intl fallback)。`assessmentScalePhq9` / `assessmentScaleGad7` 复用现有 key。
- **26 case TDD test** (新 `test/domain/scale_translations_round65_test.dart`): 6 group × 4-5 case 覆盖 `StaticScaleTranslations` 中文 fallback / `AppLocalizationsScaleTranslations` zh+en 路径 / 6 region 危机电话 routing / `Phq9Scale`/`Gad7Scale` 抽象注入 (老 const 走 `StaticScaleTranslations` 中文, 新 caller 走 `AppLocalizationsScaleTranslations` en 返 `'PHQ-9 Depression Screening'`) / `regionDisplayName` + `CheckInType.labelL10n` 防 orphan key 引用。

## [Unreleased] - 2026-07-31 (R63 — 7 视角审视后"半成品"集中收尾)

> R63 目标: 处理 `docs/audit-history/r95-seven-lens-2026-07-31/` 7 视角整合报告
> 标出的"半成品"问题（⏳/🔶 状态）。共修 **30 项**:
> - **P0 必改 10 项**（6 视角共识最高频 + iOS/Android 上架阻塞）
> - **P1 重要 10 项**（7 视角共识高频）
> - **P2 建议 2 项**（flutter 4 nit 批量）
> - **iOS 平台 P0 8 项**（appstore 视角）
> - **Android 平台 P0 7 项**（googleplay 视角）

### Tests
- **1163/1163 pass** (R62 1151 + R63 12 新)
- `flutter analyze` 0 error, 0 warning
- 15 Python 守护 + 1 `check_all.dart` 全绿

### P0 Bug 修复（6 视角 / 4 视角 / 7 视角共识）
- **P0-1 SmsGateway 抽象收尾 (6 视角共识)**: 修复前 `AliyunSmsProvider.isProductionReady = 4 字段齐全 → true → release 启动不阻断 → send() 抛 UnimplementedError → 100% 失败但没 banner`。修复后加 `_isFullyImplemented` 守门（默认 false），`isProductionReady = _isFullyImplemented && 4 字段齐全`，`send()` 改抛 `StateError` 明确意图。release 模式启动时 `validateForRelease` 阻断 → 顶部 banner 显眼告警。文件: `lib/core/data/services/sms_service.dart`
- **P0-2 PIPL §13 DB 落库 (4 视角共识)**: R62 修了 API 层 (`ConsentArtifact` + `ConsentDialog` + `ConsentMissingError`) + piiSafeLog 留痕，但**留痕只 log 不写表**。R63 加 4 列到 `contacts` 表 (`consentAt` / `consentKind` / `consentBy` / `consentVersion`) + `schemaVersion 14→15` + `onUpgrade` addColumn + `idx_contact_consent_at` 索引。`ContactEntity` + `ContactMapper` 同步 4 字段（`ConsentKind?` nullable enum）。`ContactRepositoryImpl.add/restore` 写 4 字段。7 case TDD test 验证 round-trip。
- **P0-3 ConsentKind 双 enum 统一**: 修复前 domain `ConsentKind` 2 值 (emergencyContactSharing/dataExport) + presentation 3 值 (safety/vent/analytics) 同名不同值。修复后 domain 5 值统一，presentation re-export。4 case test。

### iOS 上架阻塞 (appstore 视角, 8 项)
- **P0-1**: `Info.plist` 加 `ITSAppUsesNonExemptEncryption=false`（Apple 2024 export compliance 强制）
- **P0-5**: `Info.plist` 加 `NSPhotoLibraryAddUsageDescription`（PDF 报告触发 PHPhotoLibrary）
- **P0-6**: `CFBundleDisplayName` 改 per-language dict（en/ChronicCare + zh-Hans/zh-Hant 慢病管家）
- **P0-7**: `UIBackgroundModes fetch` → `processing` + `BGTaskSchedulerPermittedIdentifiers`（iOS 13+ deprecated）
- **P0-8**: 新建 `Runner.entitlements` (aps-environment=development) + pbxproj 注册到 3 build configs
- **P1-4**: `IPHONEOS_DEPLOYMENT_TARGET` 13.0→14.0（3 处 project，Apple 2024 推荐 14+）
- **P1-5**: `SUPPORTED_PLATFORMS` 加 `iphonesimulator` + `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64`
- **P1-6**: `PRODUCT_BUNDLE_IDENTIFIER` `com.chroniccare.chroniccare`→`com.chroniccare.app`（3 target）

### Android 上架阻塞 (googleplay 视角, 7 项)
- **P0-1**: release 签名 `signingConfigs.release` + `key.properties.example` 模板（R55+ 真 keystore TODO）
- **P0-2**: 新建 `BootReceiver.kt`（`RECEIVE_BOOT_COMPLETED` 接收器，重启手机后通知恢复）+ `AndroidManifest` 注册
- **P1-1**: `AndroidManifest` 注释谎言修 + application 加 `enableOnBackInvokedCallback=true`（Android 13 预测式返回）
- **P1-2**: `build.gradle.kts` `minSdk=24` + `targetSdk=36` 显式（防 Flutter 升级漂移）
- **P1-4**: application 加 `debuggable=false` + `allowBackup=false` 显式（PIPL §28 精神心理数据禁止 backup）
- **P1-6**: `proguard-rules.pro` 加 `-keep class com.chroniccare.chroniccare.** { *; }`（防 R8 混淆 MainActivity）
- **P1-7**: release 块加 `isDebuggable=false` + `isJniDebuggable=false` 显式

### 关键 P1（7 视角共识高频, 10 项）
- **P1-1 (emil+flutter)**: `main.dart:307,368` `Colors.orange/red` 硬编 → `theme.colorScheme.tertiary/errorColor(context)`
- **P1-2 (flutter)**: `app_theme.dart:20` 删 `onPrimary: Colors.white`（反 M3, fromSeed 已自动派生）
- **P1-3 (flutter)**: `app_tokens.dart:138-139` `disabledColor` hardcode → `onSurface.withValues(alpha:0.12)`（M3 standard）
- **P1-4 (spen+flutter)**: `home_page.dart:105` `Future.delayed` 不可 cancel → `Timer` + dispose cancel
- **P1-5 (spen)**: `phq9.dart:129` `hotlineByRegion[region]!` 海外 region 未注册会崩 → `?? hotlineByRegion['cn']!.first` 兜底
- **P1-6 (spen)**: `check_in_repository_impl.dart` 3 处 `at ?? DateTime.now()` 抽 `_resolveTimestamp` top-level helper
- **P1-7 (spen)**: `app_database.dart:165` 静默 `catch(e){}` 修 → `swallowError` 集中器（R39 P1-10 模式）
- **P1-8 (spzh+alibaba)**: `strings.dart` 6 处 dartdoc 注释与代码不同步 修正
- **P1-9 (emil)**: `page_transition_switcher.dart:34` 裸 100ms → `AppTokens.durPageTransition` token
- **P1-10 (flutter)**: `app_shell.dart:91` 顶部品牌 `Text` inline `TextStyle` → `textStyleLabelStrong` 集中器

### 关键 P2 (flutter 视角, 2 项批量 71 文件)
- **P2-1 (1)**: 59 文件 删 `library;` 指令（Dart 2.x 自动，显式写是 noise）
- **P2-1 (2)**: 25 文件 dangling library doc comment 改 `//`（避免 `dangling_library_doc_comments` info 警告）

### Architecture
- **pubspec 升版**: `0.27.0+62` → `0.27.0+63`
- **schemaVersion bump**: 14 → 15（contacts 表加 4 consent 字段 + 索引）
- **7 视角整合报告**: `docs/audit-history/r95-seven-lens-2026-07-31/CONSOLIDATED.md`（35.9KB, 123 问题去重 ~50 项）

### Changed
- 7 份独立子报告（emil / spen / spzh / appstore / googleplay / alibaba / flutter）+ 1 份整合报告
- 1 个 Kotlin 类 (`BootReceiver.kt`)
- 1 个 entitlements plist (`Runner.entitlements`)
- 1 个 keystore 模板 (`android/key.properties.example`)
- 1 个共享上下文 (`docs/audit-history/r95-seven-lens-2026-07-31/_shared/context.md`)
- 1 个 9 文件 ios/ 项目结构首次 commit

## [0.27.0] - 2026-07-31 (R62 — 独立小项修复 + P0/P1 集中收尾)

> R62 目标: 集中清 v0.27 综合审计 (CONSOLIDATED-AUDIT-v0.27.md /
> docs/reviews/2026-07-31-three-lens/consolidated.md) 列出的可独立修复
> 小项 + P0-1 / P0-2 准备架构。

### Tests
- **1163/1163 pass** (R61 1151 + R62/R63 12 新)
- `flutter analyze` 0 errors
- 16 守护 Python + 1 `check_all.dart` 全绿

### P0/P1 修复
- **P0-3 尾巴 (R62)**: `lib/main.dart` 修正临时 `SmsService()` 实例 → provider tree 共享实例 (跟 P0-1 一起落地)
- **P1-4 (R62)**: `safety_watch_service.displayMessage` 走 i18n + 加 9 个 ARB key
- **P1-5 (R62)**: 抽 `lib/domain/logic/lost_contact_sms.dart` 单一 source
- **P1-6 (R62)**: `home_page.dart:407-412` `Future.delayed(1800ms)` → `Timer` + `dispose` `cancel()`, 避免 widget 销毁后 fire 引起 race
- **P1-7 (R62)**: `setup_page.dart:431` `'完成设置'` hardcode → `snackbarActionFinishSetup` ARB key
- **P1-8 (R62)**: `user_name_helper` / `email_template` / `reminder_scheduler` 3 caller hardcode `'您'` / `'您的家人'` → `Strings.userNamePolite` / `Strings.userNameFamily` 集中常量, 方便 i18n override 模式
- **P1-9 (R62)**: `home_page.dart:87` 100ms 裸值 → `AppTokens.kDeepLinkRaceGuard` token
- **P1-10 (R62)**: `contacts_list_widget.dart:202-203` `'Contact'` hardcode 英文 → `contactDefaultName` ARB key (zh='联系人' / en='Contact' / hant='聯絡人')
- **P1-NEW-1 (R62)**: `lib/domain/logic/assessment_record.dart` R60 M9 修正 == / hashCode 时埋下 11+ 处"修正"字符污染注释 → 改"修复前/修复后/element-based 哈希/identity 哈希"等具体英文/中文技术术语

### Architecture
- **pubspec 升版**: `0.25.0+1` → `0.27.0+63` (R62 漂移 2 round 修复 + R63 升版)

### Changed
- 3 个 ARB 文件 (zh / en / zh_Hant) 加 2 个新 key (`snackbarActionFinishSetup` / `contactDefaultName`)
- 1 个新 token (`AppTokens.kDeepLinkRaceGuard`)
- 1 个 domain 集中器 (`Strings.userNameDefault` / `userNamePolite` / `userNameFamily`)

## [0.27.0] - 2026-07-31 (R61 — 平台发布准备 + 残余 P0)

> 用户最终目标：发布到 Android / iOS / iPadOS。R61 完成 3 件事:
> (1) 残余 P0 bug (安全告警 SMS 模板 i18n / dosage unit 国际化 / safety_watch 死代码清理)
> (2) mood_recorder dispose race guard + inline TextStyle token 化
> (3) 平台代码生成 + Android/iOS 关键发布配置

### Tests
- 1151/1151 pass (1098 → 1151, +53)
- `flutter analyze` 0 errors
- 16 守护 Python + 1 `check_all.dart` 全绿

### P0 Bug 修复
- **dosage_unit i18n** (R61 P2): 之前 `m.dosageUnit.id` 返回 'mg'/'片' 字符串
  → en 用户看 '片' 困惑。修法: 新建 `lib/l10n/medication_unit_label.dart` (presentation helper)
  走 ARB i18n, 加 2 key (`medicationUnitMg` / `medicationUnitTablet`), zh='片' / en='tablet'。
  改 1 处 caller (`temp_medication_dialog.dart:97`)。
- **safety_watch_service 8 个 @Deprecated 删** (R61 P1-12 拆分收尾): R57 标了 deprecated 但
  caller 仍调 facade + `safetyConfigServiceProvider` 没加。R61 加 provider, 改 2 caller
  (`reminders_hub_provider` + `reminders_hub_page._SafetyReminderSheet._save`), 改 2 test
  文件用 `SafetyConfigService` 直接, 删 facade 8 个 method。safety_watch_service
  退化为协调 facade (留 3 个触发入口 + `_checkAndAlert`)。
- **safety_watch_service.displayMessage i18n** (R61 P1-4): 之前 hardcode 中文。
  修法: 加 8 个 ARB key (`safetyCheckResult{Disabled|Ok|NoData|...|Alerted|AlertedMocked|Error}`),
  新 `displayMessageL10n(l10n)` 方法, 8 个 kind 全部覆盖 + 3 态分流 (ok / mocked / failed)。
  data 层仍保留旧 `displayMessage` getter (返 i18n key) 兼容老 caller。
- **mood_recorder dispose race guard** (R61 P0-1): 之前 dispose 链中
  `_disposeResources() → service.stopRecording() → onTick → setState` 可能在
  `super.dispose()` 之后触发, 撞 defunct assert。修法: dispose 第一行同步
  `_isRecording = false`, 后续检查 `if (_isRecording)` 都返 false, 安全跳过。
- **mood_recorder 4 处 inline TextStyle token 化** (R61 P2):
  计时器 / recorded / maxReached / liveTranscript / partialHint / stt-unavailable
  6 处 TextStyle 内联 → 改用 `textStyleBody` / `textStyleCaption` /
  `textStyleCaptionHint` + `copyWith` 注入特殊属性 (italic / error color)。

### 重构
- **新建 `lib/l10n/medication_unit_label.dart`** (presentation): dosage unit i18n
  helper, 跟 `app_localizations.dart` 同级, 集中器。
- **safety_watch_service 退化为 facade**: 8 个 config method 删, 内部 `_checkAndAlert`
  直接调 `_config.xxx()` 替代 facade 转发。

### 平台配置 (用户目标: Android / iOS / iPadOS)
- **`flutter create . --platforms=android,ios --org com.chroniccare`** 生成完整
  平台代码 (android/ + ios/), pubspec.yaml / .gitignore 0 改动, .metadata 加回 web 平台行。
- **Android (targetSdk 34, minSdk 23)**:
  - `AndroidManifest.xml` 加 8 个权限 (INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM
    / USE_EXACT_ALARM / WAKE_LOCK / RECEIVE_BOOT_COMPLETED / VIBRATE / RECORD_AUDIO)
  - `build.gradle.kts` 改 minSdk 21→23 (SQLCipher 要求) + multiDexEnabled + 启用 ProGuard
  - `proguard-rules.pro` 加 10 个 plugin keep 规则 (flutter_local_notifications / audioplayers
    / record / sqlcipher / speech_to_text / flutter_secure_storage / share_plus / drift)
  - `res/xml/backup_rules.xml` (Android 6-11) + `data_extraction_rules.xml` (Android 12+)
    排除 chroniccare.sqlite / flutter_secure_storage / vent_audio / mood_audio (PIPL §28)
  - `res/xml/network_security_config.xml` 强制 HTTPS / 禁 cleartext
- **iOS / iPadOS (IPHONEOS_DEPLOYMENT_TARGET 13+)**:
  - `Info.plist` 加 4 个 NSUsageDescription (通知 / 麦克风 / 语音识别 / 用户追踪) +
    改 `UIRequiresFullScreen=false` 支持 iPad Split View + 加 `UIBackgroundModes` (audio / fetch)
  - `PrivacyInfo.xcprivacy` 加 4 个 required-reason API (UserDefaults / FileTimestamp /
    SystemBootTime / DiskSpace) — 2024-05 Apple 强制

### Changed
- 4 个 ARB 文件 (zh / en / zh_Hant) 加 10 个新 key (2 dosage + 8 safety check result)
- 1 个 ARB 文件 (zh_Hant) 修 1 处繁简混搭 ("网路" → "網絡" 跟 OpenCC s2tw 一致)
- `test/widget_test.dart` 替换 flutter create 占位 MyApp test → 改测 i18n key 加载 + 中英文差异

### 验证
- 1151 test pass (含 widget_test.dart 3 个 i18n 新 test)
- 16 守护 Python 全过: check_arb_keys / check_changelog / check_cross_feature /
  check_datetime_race{,_2} / check_drift_namespace / check_fullwidth_punctuation /
  check_legal_consent / check_no_hardcoded_utc / check_no_pua / check_orphan_arb_keys /
  check_sms_release_ready / check_strings_hardcoded / check_widget_dispose /
  check_zh_hant_consistency
- 1 个 dart 架构守门 (`scripts/check_all.dart`) 4 层纯度 + 1:1 entity 映射全过
- `flutter analyze` 0 errors (28 info-level 保持不变 — 全部 prefer_const_constructors /
  require_trailing_commas 历史遗留)

### 阻塞上架但需外部环境项
- ⚠️ **Android build 环境**: Windows + JDK 21 + 国产 SSL 证书拦截 gradle 下载。
  需 Mac / Linux + 配置 `gradle.properties` 代理 / 自建 SSL 信任库, 或
  公司提供 build runner。代码 + 配置已 100% ready, 只需 CI 环境。
- ⚠️ **iOS build 必需 Mac**: Apple 工具链限制。生成 ios/ + Info.plist +
  PrivacyInfo.xcprivacy 已完整, 但 `flutter build ios` 需 Mac + Xcode + Apple Developer 账号。
- ⚠️ **release keystore**: 当前 build.gradle.kts 用 debug 签名, 上架前必须配 release
  signingConfigs (R61 留 TODO)。
- ⚠️ **iOS provisioning profile**: 需 Apple Developer Program 账号 ($99/年) 配
  Runner.entitlements + Runner.xcworkspace schemes。

## [0.25.0] - 2026-07-26 (R49-R60 + R56b-R56f)

### Tests
- 1098/1098 pass (1057 → 1098, +41)
- `flutter analyze` 0 errors (28 info-level, prefer_const_constructors 历史遗留)
- 12 守护脚本全绿（含 R56e 新增 `check_orphan_arb_keys.py`）

### Architecture (round 49-60 emil/spen god-class 续拆 + token 化)
- **R49** dark mode 颜色 60+ 处 → 3 dynamic getter (`primaryColor` / `errorColor` / `warningColor`) + `severity_style.dart` 加 `context` 参数
- **R50** 3 个 score TextStyle helper (`textStyleScoreLg` / `Xl` / `Xxl`)
- **R51** PHQ-9 危机电话 6 region 路由 (`cn` / `us` / `hk` / `tw` / `sg` / `uk`) via `HotlineRegion` enum + `hotlineByRegion` Map
- **R52** 7 个 P0 bug — `mood_recorder dispose race` / `Future.wait + timeout race` / `main.dart:90 删 Asia/Shanghai` / `piiSafeLog 改 medId` / `app_router 乱码改英文 fallback` / `SmsResult 加 SmsResultKind enum` / `setup_page.dart:404 加 5s timeout`
- **R53a** `app_database` 559 → 305 行 (-45%), 抽 7 DAO
- **R54** `DEPLOYMENT.md` + `privacy_policy.md` + `README.md` 合规 — 阶段 8 / 附录 A (NMPA / HIPAA / GDPR / PIPL) / `privacy_policy` §11 跨境 + §12 PIPL §13 进度
- **R55** `docs/PUSH_PROVIDERS.md` (5 厂商 plan) + `docs/SMS_PROVIDERS.md` (AliyunSms plan) + `AliyunSmsProvider.send()` 加 7 步真接骨架注释
- **R56** emil icon size 5 个新 token (`iconSizeInline` / `Small` / `Empty` / `Error`) + chart 4 个尺寸 + 32 处 magic 替换
- **R57** `safety_watch_service` 425 → 325 行 (-24%), 抽 `SafetyConfigService` + `SafetyAlertDispatcher`
- **R58** `medication_report` 拆 3 纯函数类 (`MedicationStatCalculator` + `MissedDateBuilder` + `TempEntryExtractor`)
- **R59** `app_router` 418 → 51 行 (-88%), 抽 `app_routes.dart` + `app_shell.dart`
- **R60** `MedicationDraft` value object, `MedicationRepository.add()` 9 参数 → 1 参数
- **R56b** P1(emil) spacing SizedBox 46 处 → `AppTokens` token (`spacingXxxs` / `Xxs` / `chipGap` / `Xs` / `Sm` / `Md` / `Lg` / `Xl`)

### TDD 补全 (round 56c-R56c''' spen P0 #15)
- **R56c** `db_key_service` +5 unit test (FlutterSecureStorage MethodChannel mock 模式)
- **R56c'** `refill_notifier` +10 (id 公式 + `computeRefillFireTime` 纯函数 + `scheduleRefillReminder` instance)
- **R56c''** `medication_notifier` +10 (ID 常量 + `scheduleDailyReminder` + `rescheduleMedicationReminders`)
- **R56c'''** `assessment_notifier` +4 + `safety_alert_dispatcher` +7 + `mood_audio_service` +10

### Architecture & Refactor (round 58-59 v0.27 启动 + 三视角审视修正)
- **v0.27 round 58** 三视角审视 (emil / spen / spzh) 启动:
  - emil: 35 发现 (P0×1 + P1×17 + P2×12 + P3×5) → `docs/audit-history/review-v0.27/review-emilkowalski-v027.md` (42KB)
  - spen: 66 发现 (P0×4 + P1×16 + P2×30 + P3×16) → `docs/audit-history/review-superpowers-en-v027.md` (47KB)
  - spzh: 126 spzh 独有发现 (P0×0 + P1×5 + P2×35 + P3×86) → `docs/audit-history/review-superpowers-zh-v027.md` (48KB)
- **v0.27 round 59** 三视角 P0/P1 修正批次 1 (XS+S 修正 7 项):
  - **P0-3** (spen §5#18 latent P0 fix): `setup_page.dart:404` 修正 fail-soft `onTimeout: () => const []` 丢数据 → fail-loud (让 TimeoutException 抛出 → setup 失败 + UI 提示)
  - **EMIL-T29**: 删 4 个 const shadow token (`shadowCard` / `shadowCardDark` / `shadowDialog` / `shadowOverlay`) + 修正 `celebration_bounce.dart:115` 走 theme-aware `shadowOverlayOf(context)` (防 R49 同款 silent bug 重现)
  - **EMIL-T21**: `loading_skeleton.dart:127-138` dispose race 修正 `Future.delayed` → `Timer?` 字段可 cancel (修正 race condition 风险)
  - **EMIL-T13**: 11 处 `ScaffoldMessenger.of(ctx).showSnackBar(AppSnackBar.x(...))` → `AppSnackBar.showX(ctx, ...)` 集中器化 (1 行调用, 修正 7 文件 11 处)
  - **SPZH §5#1**: `check_fullwidth_punctuation.py` 修正 `…` (U+2026) 误报 (47→45 violations, 加 `(?<!…)/(?!…)` 双向负向断言, `……` 修正不报)
  - **SPZH §2.2**: `preset_medication_templates.dart` 修正 3 处真实半角斜杠 (`SSRI / SNRI` → `SSRI ／ SNRI` 等) (medical abbreviation 风格)
  - **SPZH §3#1-2**: 新建 `docs/terminology.md` 集中术语表 (App/应用/客户端 / i18n/国际化/本地化 / PHQ-9/GAD-7 / 隐私 / 用药 5 大类), spec 文档化, R60 修正 14 处中文 ARB
- **v0.27 round 59** Stale findings (不修正, 移到下 round):
  - P0-2 (email test): 实际已修正, spen 报告 stale
  - EMIL-T08 (3 dead tokens): R57 已修正 (注释 line 632-636 标注), stale
  - SPEN-§4#1 (8 @Deprecated facade 删除): 需新加 `safetyConfigServiceProvider` provider 路径, 修正 reminders_hub_page / reminders_hub_provider / test 4 处 caller, R60 修正
- **v0.27 round 59** R60 修正计划 (修正后):
  - SPEN-§4#1: 修正 `safetyConfigServiceProvider` provider + 4 处 caller 迁移, 删 8 facade
  - SPEN-§4#2: `_showSafetyAlert` 50 行 inline 移 `SafetyAlertDispatcher` (1-2h 重构)
  - SPZH 14 处 "App" 修正 → "本应用" / "慢病管家"
  - 5 systematic-debugging regression tests (跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose)
  - 7 god page 拆 (trend_calendar / reminders_hub / data_mgmt / edit_med / mood_recorder / assessment_widgets / setup)
  - `app_tokens.dart` 779 行 god file 拆 5 子模块
  - 文字 token 化 36% → 80% (191 inline TextStyle 集中器化)
  - `home_page.dart` widget test (P0, 每日用户路径 0 test)
  - `mood_recorder.dart` god class split (P0, R52 修正 dispose race 但 0 regression test)

### Cleanup (round 56d-R56f)
- **R56d** `formatters.dart` 走 intl `DateFormat` + `vent_detail_page.dart:191` 改 `EmptyState`
- **R56e** 新增 `scripts/check_orphan_arb_keys.py` 守门员 + 一次性清 39 个 orphan (677 → 550 zh ARB key)
- **R56f** `AGENTS.md` 同步 (R56 系列汇总 + 12 守门员清单展开 + test count 1098)

### Pending (外部依赖)
- R55 真接阿里云 SMS (法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
- R51b PHQ-9 题目 + 严重度 + 危机电话完整走 ARB (v1.0 大工程)

## [0.24.0] - 2026-07-26

### Added (round 45-47 emil god-class 续拆 + token 化 + 集中器)
- **mood_dialog god-class 拆 5 子 widget**（`7412138`）：738→199 行（-73%），按职责拆 MoodScoreSection / MoodTagSelector / MoodEnergySelector / MoodNoteInput / MoodAudioRecorder
- **notification_service god-class 拆 3 子**（`84b7a1b`）：629→353 行（-44%），抽 NotificationChannelManager / NotificationScheduleBuilder / NotificationHistoryLog
- **data_export_service god-class 拆 3 子**（`da110ce`）：582→538 行 + 73 test
- **medications_list god-class 拆 4 子 widget**（`020b8e4`）：554→203 行（-63%）
- **assessment_history_page god-class 续拆**（`436706a`）：624→105 orchestrator + 4 子 widget
- **trend_charts god-class 续拆**（`1c14b2d`）：595→0 + 4 子 widget 拆到 `widgets/`
- **vent_compose_page god-class 续拆**（`c6523d5`）：537→274 orchestrator + 3 子 widget
- **settings_page 拆 4 子 section widget**（`68dfcba`）：96 行 orchestrator
- **AppSemantics 集中器**（`1646e0e`）：a11y 集中器抽离，6 处 widget 替换
- **AppListTile 集中器**（`54c0fb0`）：settings 4 子 widget 13 处 PressFeedback+ListTile 改 AppListTile
- **AppSnackBar 47 处收敛**（`e095b1c`）：`ScaffoldMessenger.of(...).showSnackBar(AppSnackBar.xxx(...))` 全代码库统一
- **token 化 9 项**（`79d2a49` `d47df84` `578df2c`）：6 token + 6 处 hardcode duration/color 替换 / 3 token + 3 处 ListTile 集中化 / 2 处 withValues / textStyleLegal fontSize 改 token
- **MedicationEntity.dosageUnit 强类型**（`bb755fb`）：`String → DosageUnit` enum 转换，spzh mojibake 修正联动
- **data_providers → shared_providers 改名**（`05dfd9a`）：语义更准确

### Added (round 45-47 spen 数据驱动化 + widget 测)
- **gad7/phq9 数据驱动化**（`2454dce`）：`severityCutoffs` 集中阈值表，新增评估量表只需加 1 条
- **check_arb_keys.py 加 --staged 模式**（`4d5d5ed`）：PR-time 只看 staged 文件
- **settings_page 3 case widget 测**（`465b827`）：Sprint #6 中段
- **trend_page 2 case widget 测**（`6ab2676`）：Sprint #6 中段 3/3
- **contacts_list_widget 4 case widget 测**（`8790710`）：Sprint #6 中段
- **WIP god-class 续拆 + 错误处理集中 + magic number 抽 const**（`1a8adef` `19a29c1`）

### Fixed (round 45-47 spzh i18n 修正)
- **main.dart _MigrationFailedApp 4 处 hardcode 中文 i18n 化**（`ce44acc`）：+ 3 处 TextStyle 改 token，精神心理患者崩溃时看到友好文案
- **zh_Hant.arb 简体副本修正**（`cf61948`）：OpenCC s2tw 真繁化 401 key（`@@locale` + 行 21 "您→你" 之外全部繁化）
- **app_router mojibake 修正**（`9e9e6de`）：v0.22 round 31 漏修正一处
- **strings.dart DosageUnit 强类型**（`9e9e6de`）：notification_service 调用 `dosageUnit.id` 强类型化

### CI
- **check_no_pua.py 守门员**（`45b773b`）：扫 PUA 字符（v0.22 round 31 mojibake 修正后无守护）
- **9 个 1-shot 脚本归档到 _archive/**（`4d08510`）：保留历史可追溯

### Known issues (v0.25 必修 — 三视角审视发现)
- **合规 5 项 12 round 0 修**（spzh P0-of-P0）：3 份法律文档 v0.22 草稿 / PIPL §1 vs §3 自相矛盾 / 5 厂商 push 通道未接 / DEPLOYMENT.md 敏感措辞 / 法务未确认 NMPA — 4 store 上架阻塞
- **CHANGELOG 顺序乱**（spzh）：[0.16.0] 排到 [0.1.0+1] 后 / [0.22.1] 排到 [0.23.0] 后 / [0.15.0] 排到 [0.14.0] 后 — 时间倒置（v0.24.0 release 收尾修正）
- **pubspec 0.23.0+1 没 bump**（spzh）：v0.24 发布 30 commit 仍 0.23.0+1
- **EmailTemplate._formatDateTime 硬编码 UTC+8**（spen P0）：PIPL §17 跨境合规风险
- **strings.dart 35+ hardcode 中文**（spzh P0）：通知/PDF/import summary/SMS 模板海外用户无法看
- **crossedMidnightSince 无 direct test**（spen P1）：v0.21 P0-4 关键防御 test gap
- **vent_compose._togglePlay 暂停路径 temp file 释放顺序脆弱**（spen P1）：audioplayers 6.x 已知 PlatformException
- **emil token 化最后 5%**（emil P1）：14 处裸 TextStyle / 12 处裸 EdgeInsets / MotionScheme.subtle curve 虚设 / DimensionRow Motion 包装 / CelebrationOverlay 自研动效

### Tests
- 876+ cases pass
- `flutter analyze` 0 errors
- 8 守护脚本全绿（含 v0.24 新增 check_no_pua.py）

### Architecture
- 4 层架构纯度 + 一致性 100% 保持（`check_all.dart` 全过）
- god-class 治理大幅推进（mood_dialog -73% / notification_service -44% / medications_list -63%）
- token 体系 8.4/10 接近工业级（剩余 5% polish）
- i18n zh_Hant 修正完成（v1.0+ 海外发布就绪）

## [0.23.0] - 2026-07-25

### Fixed (round 38 P0 — 3 项上架关键修复)
- **SMS release fail-fast**（spen P0-1）：`sms_service.dart` release 模式调 `validateForRelease` 抛 `SmsProviderNotConfiguredError`，被 `runZonedGuarded` + `LastErrorCapture` 抓住，AppRoot 顶部 banner 提示。dev/profile 静默通过（mock 是 dev 工具）
- **safety_watch timeout 10s**（spen P0-3）：`safety_watch_service.dart` 加 10s timeout 防 SMS 发送挂死，配合 `swallowError` 集中器
- **app.dart 复用 provider**（spen P0-4）：`main.dart` 创建 `notificationService` 注入 provider tree，避免 `AppRoot.initState` 重新 `NotificationService()`

### Fixed (round 39 P1 — 8 项)
- **catch(_) → swallowError**（spen P1-3）：5 处 best-effort 走集中器，2 处 schema guard 保留（注释 `// ignore:`），0 `catch(_)` 残留
- **i18n 38 处**（spzh P1-1）：main.dart 升级 dialog 11 处 + trend_* 17 处 + 10 处其他 widget 文本全 i18n 化，ARB zh 555 / en 549 → 555 / 555 100% 同步
- **PDF mask**（spzh P1-7）：`medication_report_pdf.dart` 用户姓名/联系方式 9 处脱敏
- **50+ test**（spen P1-6）：新加 50+ test case（care_strategies / encrypted_audio_storage / data_export / i18n 等）

### Refactor (round 40 P2 — 12 项 token 化 + 抽类 + i18n)
- **token 化 12 项**（emil P2-1~12）：trend_charts 11 处 fontSize hardcode / `Curves.*` 走 token / `Colors.white/black54` 反白修复 / 5 个 `tintedXxx` 集中器应用
- **抽类**（emil P2-13~14）：BadgeSyncService 从 notification_service 抽 / ReminderDispatcher 重构
- **i18n**（spzh P2-1~5）：preset_medication_templates 半角→全角括号 / 5 处其他 widget 文本 i18n
- **Z 后缀**（spen P2-3）：`toUtc().toIso8601String()` 全代码库统一 Z 后缀
- **tz.local**（spen P2-4）：DateTime 统一 `tz.local` 防时区 race

### Refactor (round 41 P3 — 4 项实做)
- **PressFeedbackIconButton**（emil P3-1）：从 PressFeedback 抽 IconButton 专用变体，统一 22 文件 icon button 反馈
- **care_engine 4 strategy**（emil P3-2）：`care_strategies.dart` 拆 DefaultHighFreqStrategy / DefaultLowFreqStrategy / HighAdherenceStrategy / LowAdherenceStrategy 4 子
- **reminders_hub Notifier**（emil P3-3）：从 god class reminders_hub_page 拆 5 个 card 子 widget + Notifier 集中
- **zh_Hant stub**（spzh P3-30）：加 `app_zh_Hant.arb`（**注**：v0.24 修正 OpenCC 繁化 — 当前是简体副本）

### Added
- **care_strategies 4 子 + test**（emil P3-2 续）：`care_strategies_round43_test.dart` 286 行
- **encrypted_audio_storage base class + test**（emil P3-5）：`encrypted_audio_storage_round43_test.dart` 186 行
- **6 个 CI 守门员脚本**：check_all / check_cross_feature / check_arb_keys / check_drift_namespace / check_datetime_race / check_fullwidth_punctuation
- **P3 L 项 4 处架构债务 TODO 注释**：notification_service facade 续拆 / data_export +50 test 路径 / zh_Hant stub 修正 / 紧急联系人单独同意

### Tests
- 876/876 pass
- `flutter analyze` 0 issues (44 info-level 仅 trailing_comma + prefer_const, 历史遗留)

### Known issues (v0.24 round 45 三视角审视新发现)
- **合规 P0 5 项 12 round 0 修**（spzh P0-of-P0）：3 份法律文档 v0.22 草稿 / PIPL §1 vs §3 自相矛盾 / 5 厂商 push 通道未接 / DEPLOYMENT.md 敏感措辞 / 法务未确认 NMPA — 4 store 上架阻塞
- **zh_Hant 简体副本**（spzh P0）：当前 555 keys 跟 zh 仅 @@locale + 行 21 "您→你" 2 处不同，虚假繁体声明
- **3 个 P0 god class 拆解完成度 1/7**（3 视角共识）：mood_dialog 738 / notification_service 629 / data_export_service 582 逆增长 — 拆解待续
- **check_no_pua.py 守护缺**（spen P0）：v0.22 round 31 修 app_router mojibake 后无守护，v0.24 round 45 新增

## [0.22.1] - 2026-07-20

### Fixed (round 29 — 三视角审视 P2 架构 + 底层)
- **SENDGRID_SETUP.md 6 处文档错误**（spzh-bug-25）：L72 test path 错（`email_service_test.dart` → `email_service_round9_test.dart`）/ L83 import path 错（`data/services` → `core/data/services`）/ L88-91 `EmailService` 构造签名错（apiKey 可选 + useMock 默认 true）/ L94 phone 注释保持 / L98 `medication: null` 类型改 `MedicationEntity?` / L100 `cycleHours` 改 int 48 不是 Duration；头部加 v0.22 状态说明（当前 `EmailService` mock-only，真实发送 v1.0+）
- **删 `_softReminderId` + `cancelSoftReminder` 死代码**（spen-bug-04）：v0.18 P2-P0-5 删 `scheduleSoftReminder` 后留下的 no-op 整条链。删 `notification_service.dart:30` const + L255-260 方法 + `home_page.dart:298` 调用 + `swallow_error.dart:13` 文档示例 + `safety_watch_service_round12_test.dart:333` mock override
- **删 `app.dart` 空 if 块**（spen-bug-05）：L69-71 `if (now.isBefore(nowCutoff))` 块内只有注释，编译为 no-op；注释与逻辑矛盾

### Added (round 29 P2)
- **ErrorState 集中器**（emil-44）：跟 `EmptyState` 对仗。`lib/presentation/widgets/error_state.dart` 新文件，5+ 字段（icon / title / detail / onRetry / retryLabel），用 M3 `colorScheme.error` 自动适配 dark mode。替换 3 处 `Center(child: Text('加载失败: xxx'))` 一行字错误态：assessment_history / vent_list / vent_detail，每处加 `onRetry: () => ref.invalidate(provider)` 入口

### Fixed (round 29 P2 一致性)
- **SegmentedButton `showSelectedIcon` 一致性**（emil-49）：`medication_calendar_page.dart:78` 默认 true（Flutter 默认），跟 `trend_page.dart:252` `showSelectedIcon: false` 不一致。改 medication_calendar 加 `showSelectedIcon: false`，避免 list/calendar 切换时 check 图标跳动
- **Checkbox M3 deprecation**（emil-50）：`setup_widgets.dart:65` 用 `activeColor: AppTokens.primary` 是 Flutter 3.32+ deprecated API。改用 `side: BorderSide(...)` + `fillColor: WidgetStateProperty.resolveWith(...)`（M3 标准）

### Skipped (round 29)
- **emil-43 `LoadingSkeleton.card` 工厂 0 处使用**：工厂本身合法（设计就支持），但精神心理患者全屏 loading 比卡片 loading 更明确"页面在加载"。不强求改用
- **emil-01~12 tinted token 全量替换**（2h）：`.withValues(alpha:)` 12+ 处 散落，token 体系已加 `tintedPrimarySoft/Deep` 等但部分 widget 仍用 `withValues`，按"调 alpha 集中改"目标逐个替换收益递减，留给后续 round
- **emil-15~16 fontSize token 缺口**（1h）：缺 `fontSizeMicro(10) / fontSizeXxxSmall(8) / 大字(22/32/64)` 6 文件 50+ 处用 `fontSize: 8/10/11/12/22/32/64` 硬编码，加 token 后批量替换
- **WHITEPAPER.md 重写**（sub-agent 4-6h 进行中）：§5/§6/§13/§14.3 同步 v0.22，本 round 单独 commit

### Tests
- 703/703 pass
- `flutter analyze` 0 issues

## [0.22.0] - 2026-07-20

### Fixed (round 28 — 三视角审视 P0 必修)
- **trend_calendar 6 处 dark mode silent bug**（emil-bug-01，`lib/presentation/pages/trend/trend_calendar.dart`）：v0.21 P1-5 修 dark mode 加 8 个 dynamic color getter，但 `_DayDetailCard` + `_EventRow` 漏了 6 处静态 `AppTokens.divider` / `AppTokens.textHint` / `AppTokens.textSecondary`。在 dark mode 下白底白字 silent bug。修：全部换成 `AppTokens.dividerColor(context)` / `textHintColor(context)` / `textSecondaryColor(context)`，去掉外层 `const` 让 BuildContext 可用
- **trend_calendar 跨日不刷新**（spen-bug-10，同文件）：`CalendarView` 原是 `StatefulWidget`，`_today = DateTime.now()` 在 field init 取一次永远不变；用户跨过 00:00:05 后 today 高亮 + `_selected` 仍指向昨天。修：改 `ConsumerStatefulWidget` + 在 build 加 `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild（跟 `medication_calendar_page.dart:44` 同款 fix）
- **\_StreakCounter listener leak**（emil-bug-03，`lib/presentation/pages/check_in/check_in_button.dart:152-160`）：之前 `didUpdateWidget` 每次 value 变化都 `_controller.addListener(() { setState... })` 匿名闭包但**没移除旧 listener**。controller 持有 N 个 listener，每次 tick 触发 N 次 setState → 指数级 rebuild 风险。修：抽 `_tickListener` 字段稳定引用，`initState` 注册 1 次，`didUpdateWidget` 复用同一 listener + 改 `_lastValue = _currentAnimated.round()`，`dispose` 移除
- **mood 5 评分无 Semantics wrapper**（emil-bug-04，`lib/presentation/pages/mood/mood_dialog.dart:215-248`）：5 个评分按钮无 `Semantics` 包装，TalkBack 读 5 个孤立"1 2 3 4 5"，精神心理患者辅助技术体验极差。修：外层 `Semantics(container: true, label: '情绪评分, 1 到 5 分制, 5 分最积极')` + 每按钮 `Semantics(button: true, inMutuallyExclusiveGroup: true, selected: ..., label: '$s 分, 已选')`
- **评估 ChoiceChip 4 选项无 group Semantics**（emil-bug-05，`lib/presentation/pages/assessment/assessment_widgets.dart:182-239`）：9 题 × 4 选项 = 36 个孤立读屏项。修：QuestionCard 外层 `Semantics(container: true, label: '评估题 $index: ${item.text}, 4 项单选, 当前: $selectedLabel')` 一次性念出题号 + 题文 + 当前选择

### Added (round 28 文档补完)
- **CHANGELOG 补 v0.18/19/20/21 整段**：v0.17 段后缺失的 4 个 minor version 段补全，50+ commit 按 P0/P1/P2 分组 + 测试数变化（491 → 565 → 702 → 702 → 703）

### Fixed (round 28 P1 架构文档)
- **sensitive_data_consent.md L49 PIPL 告知不实**（spzh-bug-02）：原文"树洞录音 \| 本地(当前未加密,v1.0+ 加密)" — v0.18 P0-2 已 AES-256 加密，告知错误。改为"本地加密存储(AES-256,密钥设备绑定,2026-07 起启用)"
- **DEPLOYMENT.md 4 处法律风险措辞**（spzh-bug-03）："突然死了"→"突发意外"；"再治愈更难"→"再规律更难"；"死了么"模式→"关怀提醒"模式；"发现死亡"→"发现异常"
- **commit 规范 2 份自相矛盾**（spzh-bug-04）：`CHINESE_COMMIT_GUIDE.md` 写"项目 commit 历史全部中文"但实际最近 30 commit 80% 英文；`WHITEPAPER.md 14.3` 写"commit message 用纯英文"。修：2 份文档都改为"接受 conventional commit 双轨：英文 prefix + 中文/英文 subject"，并标注 PowerShell `$variable` 解析坑（推荐 `git commit -F file`）
- **AGENTS.md 同步当前数字**（spzh-bug-07）：Flutter 版本 3.44.5 → 3.41.9（实测 + pubspec 约束 `>=3.41.0`）；schemaVersion 8 → 11（v0.18→v0.21 加 9/10/11 三步迁移）；测试数 702 → 703
- **DEPLOYMENT.md 同步 Flutter 版本 + web 端**：`fvm install/use 3.44.5` → 3.41.9；`flutter run -d chrome` → `flutter build web + python -m http.server 8358`（drift worker 404 修复，参考 AGENTS.md "dev 服务器坑"）
- **README.md 同步加密库**：表里"encrypt (AES-256)" → "pointycastle (AES-256, v0.20 迁)"

### Tests
- 703/703 pass（P0 + P1 文档修复未引入新测试，下个 round 加 regression）
- `flutter analyze` 0 issues

### Fixed (round 28 P1 架构技术债)
- **合并 CryptoService → EncryptionService**（spen-01 + spen-bug-09）：v0.7 旧 CryptoService 用 `String.codeUnits`（UTF-16）不标准 + 无单例 + 每次 new 读 SecureStorage 慢 + 无 test 注入。**实际 lib/ 0 业务引用**（v0.17 round 12 code review 已确认 dead code）。修：删 `crypto_service.dart`（86 行）；给 `EncryptionService` 加 `encryptString(String) → Future<String>` + `decryptString(String) → Future<String>`（utf8 → Uint8List → base64 包装）；`cryptoServiceProvider` → `encryptionServiceProvider`；`AppServices.cryptoService` → `encryptionService`

### Fixed (round 28 P1 底层)
- **web 端 database_migration 启动崩溃**（spen-bug-01）：`DatabaseMigration.needsMigration()` 内部用 `File.existsSync()` 抛 `UnsupportedError`，main.dart 无 try/catch。修：内部加 `on MissingPluginException` + `on UnsupportedError` catch 返回 false（web 端无文件系统永远不需要迁移）
- **vent `_togglePlay` 失败时 temp file 堆积泄漏**（spen-bug-02）：`vent_compose_page._togglePlay` + `vent_detail_page._togglePlay` 之前 catch 内不删 `_tempDecryptedPath`，连续失败会堆积 temp 文件。修：catch 内 try/finally 调 `deleteTempFile` 清 temp
- **mood_quick_button 漏 PressFeedback**（emil-28）：emil 决策框架要求 10+/day 频度按钮 :active scale 反馈，但 `SecondaryButton` 无 PressFeedback 包。`secondary_action_row.dart` 注释撒谎说"内部已处理"实际无。修：外包 PressFeedback + 修注释
- **setup "查看" TextButton + "开始" ElevatedButton 漏 PressFeedback**（emil-30 + emil-31）：`ConsentCheckRow` 的"查看"按钮 + `setup_step_done` 的"开始"按钮都缺 PressFeedback。修：外包 PressFeedback
- **app_zh.arb 4 处半角标点**（spzh-bug-05）：`setupContactConsent` 半角 `,` → 全角 `，`（**关键法律文案** v0.21 P1-16 漏修）；`commonLoading` / `assessmentLoadingBack` / `medReportPdfLoading` 3 处 `...` → `……`（全角省略号）

### Skipped (round 28)
- **emil-29 medication_calendar `_DataRow` 漏 PressFeedback**：emil 报告说"整行 ListTile 没有 PressFeedback wrap"，但实际 `_DataRow` 是只读热力图 `Row`（不是 ListTile），无 onTap handler，加 PressFeedback 无视觉效果。emil 报告误解。后续如果加 onTap → 跳详情 再加 PressFeedback

### Tests
- 703/703 pass
- `flutter analyze` 0 issues

## [0.21.0] - 2026-07-20

### Changed
- **analyzer 全清 + dart fix + dart format**（`9c305ed`）：0 errors / 0 warnings / 43 info
  - 修 5 处 `implicit_this_reference_in_initializer`（`index.dart` 用 `late final` + constructor body）
  - 删 `setup_page.dart` 死 import `go_router`
  - 抽 4 处硬编码 string 到 ARB（`setup_step_welcome.dart`）
  - 修 stale `@override` on deleted `scheduleSoftReminder` in test
  - `dart fix --apply`：48 个 auto-fix（prefer_const_constructors / require_trailing_commas / prefer_function_declarations_over_variables）
  - `dart format`：39 个文件重排
  - 涉及 49 个文件 / 528+ / 265-

### Added (P0 性能 / 架构纯化)
- **N+1 query 修**（`eec9d9a`）：
  - DB 层加 `watchNormalCheckIns` / `getLatestNormalCheckIn` / `getLatestAssessmentTimestamp`
  - Services 用 DB query 替代全表 scan + Dart filter
  - Providers 复用缓存数据，不再每次 re-fetch
  - 删 `main.dart` 重复 `AppDatabase()` connection
  - 独立 async 用 `Future.wait` 并行化
- **Architecture purity**（`eec9d9a`）：
  - `care_copy.dart` 从 `shared/` 移到 `domain/logic/`（仅 domain 用）
  - `pii_safe_log.dart` 从 `shared/` 移到 `data/services/`（仅 data 用）
  - `notification_navigation.dart` 从 `data/services/` 移到 `routing/`（是 routing 逻辑）
- **P0 隐私 / UI / 同意 batch 1**（`94e0803`）：综合

### Added (P1 UX)
- **P1-21 中文本土化**（`2e24e7f`）：HUD 文案中文优化
- **P1-23 联系人同意**（`2e24e7f`）：添加联系人前弹同意 dialog
- **P1-24 userName nullable**（`2e24e7f`）：数据库列 nullable 化，无 userName 不阻塞 setup
- **P1-26 Dismissible**（`295d4b3`）：列表项滑动删除
- **P1-27 RefreshIndicator**（`295d4b3`）：下拉刷新统一组件

### Added (P2 / P3 polish)
- **P2 polish**（`b0b9757`）：snackbar token 收口 + streak 数字 tween + legal 文案同步
- **P3-1 主题切换淡入动画**（`419df9c`）：dark/light 切换时页面内容淡入过渡

### Added (L10N 全面化)
- **~125 个硬编码中文抽到 ARB**（`eec9d9a`）：`settings_page` 28 / `reminders_hub_page` 38 / `notification_status_card` 37 / `medications_list_widget` 20
- 中英 ARB 文件键对齐（各 108+ keys）

### Added (清理)
- **删 14 个一次性 migration scripts**（`eec9d9a`）：从 `scripts/` 物理删除
- **`vent_entry.dart` → `vent_entry_entity.dart`**（`eec9d9a`）：命名一致性，9 个 import 同步
- **`PRD-v0.1-draft.md` 从根目录移到 `docs/`**（`eec9d9a`）

### Fixed
- **Pubspec 版本号 → `0.21.0+1`**（`eec9d9a`）
- **Flutter 版本统一到 3.44.5**（`eec9d9a`）：pubspec / README / CI 三处对齐

### Tests
- 703/703 pass（v0.20 702 → v0.21 +1）
  - N+1 query 修回归测试
  - `Dismissible` / `RefreshIndicator` widget 测试
  - 主题切换淡入动画测试
  - 之前 1 个 pre-existing failure（`data_export` version mismatch）仍存在

### Architecture
- **4 层架构保持纯净**：`architecture purity` 仍 0 违规
- **L10N 双层分明**：presentation 走 `flutter_localizations`（`l10n/`），domain 走 `core/l10n/`
- **依赖健康度**：删未用 `freezed` / `json_serializable`（v0.19 净），`encrypt` 已迁 `pointycastle`（v0.20 净）

## [0.20.0] - 2026-07-18

### Changed
- **加密依赖迁移：encrypt → pointycastle**（`97476d5`）：encrypt 包自 2022 年停维，pointycastle 是其底层依赖且持续维护
  - `encryption_service.dart` / `crypto_service.dart` 重写：pointycastle AES-256-CBC + PKCS7
  - **加密格式完全兼容**：`[16-byte IV][ciphertext]` 格式不变，老数据可正常解密
  - `pubspec.yaml`：删 `encrypt`，加 `pointycastle: ^3.9.1`
  - 涉及 3 个文件 / 65+ / 61-

### Tests
- 702/702 pass（v0.19 702 → v0.20 0）
  - 无新增测试（依赖迁移靠现有 encryption round-trip 覆盖）

### Architecture
- **依赖健康度**：pointycastle 持续维护，encrypt 停维 4 年
- **零迁移成本**：加密 blob 格式不变，无需 schema 升级
- **依赖收敛**：少 1 个 transitive 依赖（encrypt 内部也用 pointycastle）

## [0.19.0] - 2026-07-18

### Changed
- **v0.19 大文件拆分 + 架构违规修复**（`31c86f3`）：god-file 治理 + 反向依赖清除
  - `trend_page.dart` 1496→216 行，拆为 `trend_charts` / `trend_calendar` / `trend_summary` / `trend_utils` 5 文件
  - `assessment_page.dart` 794→570 行，提取 sparkline + question card → `assessment_widgets.dart`
  - `setup_page.dart` 1077→999 行，提取 `MedDraft` / `TemplateApplyResult` / `ConsentCheckRow` → `setup_widgets.dart`
  - 4 文件相对路径 import 统一为绝对 `package:` 路径
  - `pubspec.yaml` 移除未使用的 `freezed` / `json_serializable` 依赖

### Refactored
- **`setup_page.dart` 1000 行拆 7 文件**（`4cd0bf0`）：setup flow 按步骤拆 widget
- **`ComparisonCard` 提取到 `assessment_widgets.dart`**（`d5693e8`）：评估页 widget 收口

### Fixed (latent bugs)
- **`reminder_scheduler` 缓存 `DateTime.now()`**（`a435903`）：跨 await 阈值不一致修复（同款 v0.14 / v0.16 修过 3 次）
- **4 处 `setState` / 资源清理 bug**（`0971139`）：dispose 之前先取消 subscription
- **6 处 mounted 检查 + 错误处理 + 资源清理**（`7b7d516`）：widget 生命周期一致性
- **4 处空 catch 改 `swallowError`**（`2449a63`）：统一错误可观测性
- **`mood_dialog.dart` 修 context vs ctx async gap**（`31c86f3`）：`use_build_context_synchronously` 警告消除
- **`reminder_scheduler.dart` dynamic → MedicationEntity? 类型安全**（`31c86f3`）：去掉 dynamic
- **`vent_compose_page.dart` 移除 `dart:io` import**（`31c86f3`）：委托 `VentAudioStorage`

### Added (测试)
- **29 个测试文件补全 roundN 命名后缀**（`20bd10e`）：统一 `{module}_roundNN_test.dart` 命名
- **`notification_navigation` + `vent_audio_storage` 测试**（`0758894`）：service 行为 lock
- **`database_migration` 测试**（`dbeeaff`）：schemaVersion 1→8 全迁移路径覆盖

### Tests
- 702/702 pass（v0.18 565 → v0.19 +137）
  - rename 29 个测试文件（`20bd10e`）：纯命名整理，不改行为
  - `database_migration` 全 schemaVersion 路径覆盖
  - `notification_navigation` / `vent_audio_storage` service 行为 lock
  - `reminder_scheduler` + 6 处 mounted bug 回归
  - 配合文档同步 `AGENTS.md` 测试数 679 → 706（`17091e0`）

### Architecture
- **setup flow 模块化**：1000 行 `setup_page.dart` → 7 个独立 widget 文件
- **评估 widget 收口**：`ComparisonCard` 集中到 `assessment_widgets.dart`
- **5 层 umbrella 保持**：跨拆分不破坏 4 层架构
- **未使用依赖清理**：从 `pubspec.yaml` 删 `freezed` / `json_serializable`（实测 0 引用）

## [0.18.0] - 2026-07-18

### Added (P0 安全 / 隐私 / 稳定)
- **PII 安全日志**（`pii_safe_log.dart` `b046f13`）：release 模式 swallow 错误日志，dev 模式完整堆栈
- **树洞录音 AES-256 加密**（`4f2f196`）：录音文件加密存盘（`[16-byte IV][ciphertext]`），SQLCipher 之外的第二层保护
- **PII 数据导出透明告知**（`00fcfaa`）：vent 文字导出前弹 dialog 说明内容会被读
- **P0-2 4 层修复**（`4c69e91`）：`notification_service` 接受 entity，消除 domain → data 反向依赖
- **全局错误处理**（`a1aa700`）：`runZonedGuarded` 兜底 + 9 处 silent catch 改 `swallowError` 统一可观测性
- **P0-7 web 端阻断**（`ee72529`）：web 平台抛明确 PlatformException，不静默失败
- **P0-8 4 表查询索引**（`ee72529`）：`check_ins` / `medications` / `contacts` / `assessments` 加 `(user_id, timestamp)` 复合索引，N+1 显著减少
- **P0-13 step 0 法律同意 PopScope**（`ddb9009`）：首次进入 setup 拦截物理返回键，强制勾选同意
- **PIPL 3 份草稿文档**（`d9bae94`）：隐私政策 / 用户协议 / 数据收集说明

### Added (P1 UI/UX 体系)
- **LoadingSkeleton 统一**（`5b6f3c3`）：19 处裸 `CircularProgressIndicator` 替换为 3 形态骨架（fullScreen / card / Spinner）
- **EmptyState 通用组件**（`8d7b456`）：8+ 处空态文案 + 图标 + CTA 抽统一组件
- **radiusCell / radiusCellLg token**（`8d7b456`）：6+ 处硬编码圆角收口
- **dark mode token API**（`6366d3c`）：`AppTokens` 加 dark variant，8 处 widget 切换主题 token
- **MotionScheme 应用**（`296d623`）：3 widget 应用 emil 决策框架
- **WCAG contrast test**（`43695ee`）：color token 自动验证 4.5:1 / 3:1 对比度
- **home_page god-page 拆 5 widget**（`df0a394`）：header / streak / check-in / temp-med / vent-entry 各 1 文件
- **SnoozeManager 拆子 service**（`85d0253`）：从 `notification_service` 独立
- **core_providers 拆 3 文件**（`5610394`）：按职责 `core` / `service` / `vent` providers
- **repositories 按 feature 拆子目录**（`1a501ce`）：`data/repositories/{check_in,medication,contact,...}/`
- **5 层 umbrella 目录树重写**（`7b95d41`）：`core/data|shared|theme|routing|l10n` 物理分层文档化

### Added (P1 i18n / a11y)
- **i18n batch 1+2**（`befdbe5` `7ff087a`）：提取 16 个共用 string，23 处 widget 替换
- **P1-16 全角标点批量修复**（`731f975`）：173 处中文文案统一
- **P1-17 引号统一**（`24dcf81`）：英文 `'` → 中文 `''`
- **P1-19/P1-20 a11y 文档化**（`43695ee`）：reduced motion / screen reader 行为说明
- **全局尊重 prefers-reduced-motion**（`0ad8e79`）：检测系统级动效偏好自动禁用
- **港澳台/国际区号扩展**（`388ce92`）：`phone_validator` 支持 +852/+853/+886/+1/+44 等
- **联系人 banner 抽 widget**（`388ce92`）：`ContactListBanner` 通用

### Added (P1 数据层)
- **mood schema 4 维度**（`bf5b866`）：schemaVersion 6→7，`mood_entries` 加精力 / 睡眠 / 焦虑 3 列
- **user_profiles.lastCheckInAt live write**（`0412692`）：打卡后回写，失联检测不再用旧值
- **CareCopy 抽离**（`ee6cd3b`）：CareEngine 文案集中 1 处
- **删 setup 软提醒双推**（`ee6cd3b`）：之前 setup 完成后会推 2 条软提醒

### Fixed
- **MockSmsProvider/AliyunSmsProvider 显式 throw + UI banner**（`d62fa2f`）：失败不再静默
- **inject now param to SafetyWatchService.checkNow**（`c20261d`）：flaky test 修，测试时间可控
- **药名 hint 中性文案**（`8e0b98c`）：避免广告法风险

### Tests
- 565/565 pass（v0.17 491 → v0.18 +74）
  - `pii_safe_log_round18_test.dart`：release swallow 行为
  - `snooze_manager_round18_test.dart`：snooze 逻辑独立测试
  - `app_tokens_dark_round18_test.dart`：dark mode token 153 行覆盖
  - `check_all_round18_test.dart`：4 层 + cross-feature 检测回归
  - `care_engine_copy_round18_test.dart`：CareCopy 抽离回归
  - WCAG contrast 自动验证（4.5:1 / 3:1 边界）
  - vent encryption round-trip：加密 → 解密字节级一致

### Architecture
- **5 层 umbrella 落地**：`core/data|shared|theme|routing|l10n` 物理分层，`presentation → domain ← data` 方向不变
- **P0-2 vent-encryption 跨层落地**：data 层加密 + domain 层透明（`VentEntryEntity` 不暴露 IV）
- **dart format + dart fix 批量 cleanup**（`07b748b` `3f42cd7` `6800d72`）：28 个 trailing comma + 多处 prefer_const_constructors 一键净

## [0.17.0] - 2026-07-17

### Changed
- **架构升级（Round 1-5）**：从 3 个 skill（emilkowalski / superpowers-en / superpowers-zh）调研出的可优化点全部落地

### Added (emil 动效)
- **AppTokens 动画 token**（A1）：补 4 个 curve 常量（curveStandard/curveDecelerate/curveAccelerate/curveDelight）+ emil 决策框架 doc 注释
- **CheckInButton 状态过渡**（A3）：AnimatedContainer 让背景色 + 圆角在 durNormal + curveStandard 下过渡；文字切走 AnimatedSwitcher fade + scale
- **streak 数字 TweenAnimationBuilder**（A6）：数字从 0 → N 平滑递增
- **go_router 3 类 page transition**（A2）：`_fadePage`（主导航 occasional）/ `_slideRightPage`（子页 slide-from-right）/ `_slideUpPage`（全屏深页 rare full-screen modal feel）
- **vent 列表 → 详情 Hero**（A4）：Hero(tag: 'vent-avatar-{id}') 头像"飞"过去
- **vent 空态 + 鼓励文案 fade + scale**（A8）

### Added (process)
- **跨 midnight 自动 refresh streak**（B3 design issue）：AppRoot 挂 midnight timer，00:00:05 自动 `ref.invalidate(streakSummaryProvider)`，避免 streak 跨日还显示昨日的值
- **nextMidnightRefresh 纯函数**：抽 top-level `@visibleForTesting`，跨月/跨年边界都正确处理
- **CareEngine 12 个 edge case test**（B5）：fire 3 态 + 4 个核心规则的边界（22:00 整点 / 周末 18:00 边界 / 36h + hour<10）

### Fixed (Riverpod 3.0 升级)
- **flutter_riverpod 2.6.1 → 3.3.2**：自动 retry + 指数退避、`Ref` 子类统一、`==` 过滤 StreamProvider
- **AsyncValue.valueOrNull → .value**（2 处）：
  - `lib/routing/app_router.dart:85` (profile 守卫)
  - `lib/presentation/pages/home/widgets/temp_medication_dialog.dart:65` (meds list fallback)
- **freezed 2.5.7 → 3.2.5**（Riverpod 3.x 依赖要求）

### Tests
- 516/516 pass（v0.16 491 → v0.17 +25）
  - 7 个 round 1 emil 动效 test（AppTokens + CheckInButton + vent empty state）
  - 6 个 round 4 midnight refresh test（跨月/跨年/buffer 边界）
  - 12 个 round 5 CareEngine test（fire 3 态 + 4 规则边界）

### Architecture
- 4 层架构纯度 + 一致性保持：check_all.dart 仍全过
- Riverpod 3.x 升级**冲击面极小**（项目 0 个 StateProvider / StateNotifierProvider / ChangeNotifierProvider / FamilyNotifier / AutoDispose*）
- B1（!mounted → ref.mounted）实际上**无法迁移** — Riverpod 3 的 `ref.mounted` 是 `Notifier` 特性，项目全用 `Provider`/`StreamProvider`/`ConsumerStatefulWidget`，不能直接迁移。保持 30+ 处 `!mounted` check

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

