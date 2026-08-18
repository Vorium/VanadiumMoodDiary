# R111 综合审视最终整合报告 (2026-08-13, 9 视角并行)

> 基线: master `6bbb308` 0.32.0+140 (R110 round 3 之后 + round 7a/7b 测试批, working tree 干净)。
> 9 个 subagent 并行只读审计: 6 产品视角 (emilkowalski / superpowers / flutter-specification / AppStore / GooglePlay / Apple Health) + 顶层架构 + 2 路底层逐行 (domain+data / presentation+core)。
> 全部只读, 0 文件改动; superpowers agent 实测 `flutter analyze` + `flutter test` + 20/21 守门员。

## 状态快照

- 项目: v0.32.0+140, schemaVersion 22, 421 dart 文件 ~90.3K 行, 3 语 ARB 1241 key 100% parity
- `flutter test` = 2311 pass / 4 fail (全为 iOS 资产占位, 外部依赖) / 1 skip; `flutter analyze` = **0 error / 27 warning / 112 info** (warning 非零, 违反 0-warning 门禁)
- 守门员: 20/21 实测全绿 (唯一红 = check_16kb 需 build 产物, 按约定 skip); check_all.dart purity+consistency 0 violation
- R110 12 P0 代码闭环验证: 通知 ID 5M 带 / purity 3 处 / 紧急联系人 gate / Mock 文案 / validateForRelease / 12 处 i18n / 2 死路由 + shell / badge visibility / inline 守门员 — **全部实锤闭环**
- round 7b: 6 个 god class 补 42 test 全 pass, test:lib 映射 36%→55%, 126 fail 收口到 4 个资产占位

## 加权综合评分 (非官方, 供参考)

- 架构层: 6.0/10 (边界层 8.5 满血: purity 10 + consistency 10 + 仓库 17:17; 结构层 4/10: AR-16/17/18/19 四项 P0 全数跨期残留, god class 22 个反涨, usecase 6 文件 736L 0 进展)
- 底层: 8.0/10 (生命周期/UTC/DateTime race/隐私 全绿; 新 2 个 P1 数据 bug: E1 export schema 落后 + E2 consent 留痕断裂; 27 analyzer warning -0.3)
- 视觉层: 7.5/10 (token/集中器 9/10; 落地层 6/10: 8 项 R110 残留 7 项 0 闭环 + 3 个新 P1)
- 上架层: 2.5/10 (代码面 9.5/10 已达提交水准; 提交就绪 4/10, 硬阻塞 100% 外部依赖, 与 R110 完全一致 0 进展)
- **预估 R111 hotfix 修完代码级 P0/P1 后: 7.3 → 8.3/10**

## P0 清单 (按优先级, 跨视角排序; 全部为架构跨期残留 + 上架外部依赖)

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| AS-01/GP-1~3/AS-04~06 | 上架·资产 | 外部 (设计师) | 双平台资产 100% 占位: iOS 0 截图 / 68B LaunchImage / 10.9KB AppIcon; Android 8×67B 截图 / 67B feature_graphic / 192×192 icon — 与 R110 完全一致 0 闭环 |
| AS-03/E5 | 上架·外部 | 7-20d | privacy/support URL → chroniccare.app 域名未注册 (双平台硬阻塞) |
| GP-7 | 上架·构建 | 1h | keystore 未生成 → 首次 `flutter build appbundle --release` 必挂; 0 release 产物, R8/shrink/16KB 全链未验证 (R111-2) |
| GP-5 | 上架·元数据 | 5min | en-US short_description 86 字符 > 80 上限, Play 直接拒保存 |
| GP-11 | 上架·表单 | 2-3h | Data Safety + Health Apps + Permissions 3 表单未填; **R111-1 新增**: RECORD_AUDIO 恢复 + ventAudioEnabled=true → 必须申报 Audio 收集 |
| AR-17 | 架构·内聚 | 2-3d | scale_translations 三源仍在, 且 l10n impl 810L **0 运行时 caller 实锤死代码** (仅 test 引用), 活跃路径全走 static 781L; R90 stub 返空壳 — 删 1,590L 重复的最高 ROI 项 |
| AR-18 | 架构·编排 | 1-2wk | usecase 层 0 厚化 (6 文件 736L, 计划 14-16); 编排仍在 safety_watch 403L / refill_notifier / shared_providers:46-60 |
| AR-16 | 架构·循环 | 1wk | 4 个 data 文件仍 import 生成 ARB → data→ui 循环, pub workspace 死锁未解 |

## P1 清单 (代码级, 按优先级)

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| E1 | 底层·数据完整性 | ≤1d | **export/import JSON schema v4 落后 DB schema 22** (R101+ 后 0 更新): medications 漏 5 字段 (refillAt/refillReminderDays/form/colorIndex/notes), moodEntries 漏 7 字段 (audio/period/influenceFactors/recordingMode) → 换机/重装静默丢失 |
| E2 | 底层·合规 | ≤2h | **contact consent 4 字段不导出/导入 → PIPL §13 留痕断裂**: R68 gate 只挡 add(), 导入路径绕过, 导出→删库→导入后 consent 全 null (E1+E2 共用 export/import 路径, 一次 v5 schema 升级闭环) |
| SP-111-02 | 底层·门禁 | ≤1h | `flutter analyze` 27 warning 违反 AGENTS 0-warning 门禁 (12 unused import + 3 unused field + 10 处 test fake 死 @override — R108 delegate 拆分后 scheduleDailyReminder 已移走, round7b 新测试自带) |
| EM-21 | 底层·i18n | 1-2d | **en locale mood 标签显示中文**: ARB 无 moodLabelN key, presentation 3 处用 core Strings.moodLabel 硬编码中文 (EM-13 真相) |
| FS-14/R111-01 | 底层·路由 | 0.5h | `/contacts/new` 新死路由 (contacts_list_widget.dart:43, settings 空态可达; flag 翻 true 即 404) |
| EM-16 | 视觉·a11y | ≤0.5h | 状态色当文字色对比度 1.9:1 失败 (today_summary_card:97 / mood_factor_analysis:110,140), fgOnWarning 已存在未用 |
| EM-14 | 视觉·反馈 | ≤2h | disabled 态按钮仍 press scale + haptic 假反馈 (press_feedback / primary_button / check_in_button 无 disabled 感知) |
| EM-02/AH-04 | 半成品 | 1-2d/页 | 8 feature 仍 0 AppleListSection (mood/mood_list/vent/assessment/contact/settings/daily_tracking/crisis_hotline) — 最大视觉债, R110 残留 0 闭环 |
| SP-111-04 | 测试 | ≤1d | static_scale_translations 8 新量表 domain 中文 items 0 直接断言 (最大 0-test 块) |
| SP-111-07 | 架构 | 1-2d | usecase 厚化 0 进展 (=AR-18 重复项, 本表仅记测试侧) |
| FS-13/AR-19 | 架构·内聚 | 3-5d | saveSetup/clearAllUserData 仍在 AppDatabase:420-510 (513L) |
| AR-20 | 架构·尺寸 | 1-2mo | god class 22 个 ≥400L (R110 "15+" 反涨); 仅 medication_page 553→347 拆成; 7b 测试先行路径可行但拆解 0 进展 |
| AS-17 | 上架·合规 | 10min+问卷 | description "standardized questionnaires" 措辞可能触发 5.1.3 抽审; 提交时填 Health Information Disclosure Questionnaire |
| R111-1 | 上架·合规 | 30min | RECORD_AUDIO + ventAudioEnabled=true → Data Safety 申报 Audio (本批唯一代码联动新风险) |
| GP-18b | 上架·元数据 | 15min | fastlane changelogs/ 缺失 (Play 上传 AAB 时必填) |
| R111-2 | 上架·构建 | 0.5-1d | 首次 release build 冒烟 (keystore 后第一件事, 预估撞 2-5 个构建错误) + 16KB objdump 真实验证 |
| SP-111-09 | docs | ≤0.5h | AGENTS.md:136 "2019 cases" 过时 (实测 2311) + :443 "15+ god class 0 test" 过时 (round7b 后仅 4-5) |
| GP-12 | 上架·技术 | 4h | 16KB 检查仍配置级 (0 构建产物可 objdump) |
| AR-23 | 架构·耦合 | 3-5d | swallow_error 全局 sink 134 处调用点; consent_gate 仍 shared 持 domain 概念 |

## P2 代表项

底层: E3 checkIn.medicationId 导入孤儿 FK (1d) · R111-03 补打卡仍 SnackBar-only stub (2h, B2-09 残留) · R111-02 8/10 量表 displayName 硬编码中文, en 用户可见 (4h, 守门员盲区样板) · SP-111-12 home_header 日期无 en 分支 (0.5h) · B1-5 死 userName 参数 / B1-6 SQLCipher key 丢失无恢复 (P3) · SP-111-05 迁移 dry-run 缺 (1d) · SP-111-14 reminders_hub safety gate 0 test (2h)

视觉: EM-02b 双 header 并存 (2h) · EM-05 raw SnackBar 5/5 残留 · EM-06 mood_detail 48pt w700 · EM-15 8 处 inline 错误态 · EM-17 假 chevron · EM-18 quick_mood reduce-motion 盲区 · AH-08 reduce-transparency 假代理 (disableAnimationsOf) · AH-15 vent FAB 未落地 · AH-16 8-metric 面板只用 3 色 · AH-09 SF Symbol 0 · AH-06 3 套色板不打通

测试: FS-15 stale mock 9 处 (1h) · SP-111-08 迁移 steps hand-count · R111-08 vent compose 全链路 0 test (4h)

卫生: SP-111-11 32 处死链 (README 3 + CHANGELOG 11 + VERSION_1.0_PLAN 21, ≤1h) · FS-19/R111-10 mojibake 注释 2 文件 (0.2h) · GP-10 通知权限无重新授权 UI (2h) · AS-02 notes.txt +130 vs +140 · AS-15 "No third-party SDKs" 措辞为假 (改 "No analytics/ad SDKs") · AS-16 建 check_review_information_todo.py 守门员 (30min)

## P3 / 卫生

EM-07~11 · FS-3/4/7/9/11/17/18/20 · SP-111-03/06/13/15/16 · AR-21/22/26/27 · E4 translations 死字段 · E5 release assert 失效 · AH-13/14/17 spec 数字漂移 · GP-17 启动屏样式 · R111-04~07/09/10

## 已闭环验证 (R110 跨期, 全实锤)

通知 ID 5M 固定带 + 回归守卫 · purity 3 处 (check_all 2/2) · 紧急联系人 3 处 gate · Mock 文案 gate 内不可达 · validateForRelease 全 gate · 12 处 i18n + inline 守门员 (规则 2 = 0) · 2 死路由 + /medication 4 路由入 shell · badge visibility secret ×5 · schemaVersion 22 文档漂移消除 · Spring._EntrySpring 接线 · sleep 圆形统计 (Mardia) · MedicationTimes.safe() clamp · assessment past-fireAt catch-up · SP-en-10 126 fail → 4 资产 · SP-zh-09/13 仓库卫生 · SP-zh-15/16 · aliyun_sms 复活 (7 test pass) · AS-07/08/14 · PrivacyInfo HealthAndFitness 已删 · productId SOP 一致 · 锁屏 PII 全静态 title + secret ×4 + check_pii_in_title PASS · 版本 0.32.0+140 三方一致 (pubspec/CHANGELOG/README; notes.txt 例外)

## 上架状态 (用户 item 1)

- **代码面已干净可提交** (9.5/10): 锁屏 PII / PrivacyInfo / IAP 隐藏 / 紧急联系人 gate / 0 假声明 / 权限文案 4 项 / entitlements 空 (无 APNs/HealthKit 与声明一致)
- **提交就绪 4/10 — 硬阻塞 100% 外部依赖, 与 R110 一致 0 进展**: 域名 ICP (7-20d) + 双平台资产 (设计师) + keystore (1h) + review_information 4 占位 (等真实信息) + console 3 表单 (含 RECORD_AUDIO 申报)
- **半成品 5 项**: 补打卡 stub (R111-03) · reduce-transparency 假代理 (AH-08) · Spring gentle/bouncy 0 caller (EM-03 部分) · SF Symbol 0 (AH-09) · HealthKit 0 集成 (enforced, v1.0 2027-Q1 计划内, 合规不阻塞)
- **8 FeatureFlag 同 R108/R31/R110** (iap/emergencyContact/fiveVendorPush/emailService/phqGad7I18n/bootReceiver/aliyunSms=false; ventAudio=true)

## 架构结论 (用户 item 2)

- **边界层 8.5/10 满血**: purity 10 (check_all 0 violation) + consistency 10 + 仓库 17:17 + 跨 feature 0 violation + analyze 0 error — 守门员恢复可信任
- **结构层 4/10, 四项 P0 全数跨期残留**: AR-2/AR-16 l10n 循环 (pub workspace 死锁) · AR-3/AR-17 scale_translations 三源 (810L 死代码实锤) · AR-4/AR-18 usecase 6→14-16 0 进展 · AR-5/AR-19 DB 编排
- **god class 22 个反涨**: 唯一亮点 medication_page 553→347 拆成 (15 子文件示范) + 7b "先测试后拆" 路径可行; 多数反涨 (safety_watch 338→403 / static_scale 659→781 / legal 460→495 / mood_trend 517→558)
- **重构路线 (风险调整价值排序)**: ① AR-17 scale_translations 合一 (2-3d, 删 1,590L 重复) → ② AR-18/19 SetupService/DataWipeService + usecase 厚化 (1-2wk) → ③ AR-20 god class 接力 (1mo, 7b 模式先测后拆) → ④ AR-16 l10n 循环解锁 (1wk) → ⑤ AR-23 swallow_error 分层 (3-5d) → ⑥ AR-22/26 routing+providers 聚合 (最后, feature-first 纯 move 前置)

## 底层结论 (用户 item 3)

全树 ~90K 行已遍历: **0 P0 / 2 P1 新数据 bug** (E1 export schema v4 vs DB 22 静默丢字段 + E2 consent 留痕断裂, 共用路径一次 v5 升级闭环) + 1 新 P1 路由 (FS-14 /contacts/new) + 27 analyzer warning。生命周期纪律继续保持优秀 (9 listen 全 cancel / 13 Timer 全 dispose / audio 顺序链 / 43 处 DateTime.now() 全单次化 / 0 空 catch / UTC 无漂移复发)。修复计划见 `08-line-by-line-domain-data.md` / `09-line-by-line-presentation.md`。

## R111 修复路径

- **R111 hotfix (本周, 代码级, 预估 ~2.5-3d)**: E1+E2 export v5 升级 (1d, 最高优先真 bug) → 27 warning 清零含 10 处死 @override (1h) → EM-16/14/21 三 P1 (≤3h) → FS-14 死路由 (0.5h) → SP-111-04 量表 items 断言 (1d) → AS-16 守门员 + notes.txt + short_description + changelogs (1h) → 32 死链 + AGENTS/spec 数字同步 (2h) → 预期 8.3/10
- **R112 架构专项 (1-2 月)**: AR-17 scale_translations 合一 → AR-18/19 usecase + DB 编排 → AR-16 l10n 循环 → AR-20 god class 接力 (setup_page_state 497 / add_medication 573 / mood_audio_recorder_widget 589 / mood_trend 558)
- **视觉专项 (并行)**: EM-02/AH-04 8 feature ALS 化 (1-2d/页) + EM-02b/05/06 集中器迁移
- **外部闸门 (并行)**: 域名 ICP (7-20d) → 设计师资产 (3-4d) → keystore (1h) → 首次 release build 冒烟 + 16KB objdump (1d) → console 3 表单 (2-3h, 含 RECORD_AUDIO 申报) → review_information 真实值 + 5.1.3 问卷
- **v1.0 (2027-Q1)**: HealthKit / 鸿蒙 / 5 厂商 push / 阿里云 SMS / IAP 真接 / 8 量表全量 i18n
