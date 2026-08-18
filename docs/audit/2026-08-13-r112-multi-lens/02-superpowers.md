# superpowers 工程实践视角审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: superpowers (工程实践 / TDD / 质量门禁 / 测试卫生 / 死代码 / 仓库卫生)
- 审视者: superpowers subagent
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308 (0.32.0 round 7b-6), working tree=109 modified + 17 untracked (R112 = R111 hotfix 计划执行中, pubspec 0.32.0+142)
- 范围: 全量 git diff (112 文件, +25577/-25238) 抽读 + 门禁实测 + 新旧测试抽查。关键文件: `export/{export_import_pipeline,export_orchestrator,export_schema_service}.dart`、`test/data/data_export_v5_round8_test.dart`、`test/domain/static_scale_translations_round8_test.dart`、`test/data/database_migration_dryrun_round8_test.dart`、`lib/presentation/services/scale_name_l10n.dart`、`lib/presentation/widgets/mood_label.dart`、`lib/presentation/widgets/press_feedback.dart`、`lib/domain/usecases/*`、`lib/core/theme/spring.dart`、`lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart`、全部新 test 文件、AGENTS.md / CHANGELOG.md

## 1. 整体评分 (0-10)

**8.5/10** — R112 这一批的 TDD 纪律是项目历史最好的一档: 每个 R111 发现都带真实行为测试闭环 (export v5 round-trip / 迁移真实 dry-run / 量表一致性 36 test), 死代码清理干净利落; 扣分在 3 个新 warning 与 CHANGELOG "0 warning" 声明不符、AR-17 三源问题非但没合一反而加了第 4 个 dispatch 源、以及 2 个 usecase 仍 0 运行时 caller。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0

(0 项) 代码层无 P0。4 个 test fail 全部为 iOS 资产占位 (AppIcon / LaunchImage, 设计师外部依赖, 已知跨期残留)。

### P1

- [底层] **[SP-R112-01] CHANGELOG 宣称 "analyze 0 warning" 与 working tree 实测不符 (3 warning 未清)** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/presentation/pages/crisis_hotline_page.dart:30` / `lib/presentation/pages/medication/medication_calendar_page.dart:27` / `test/presentation/pages/medication/medication_backfill_round8_test.dart:12` + `docs/CHANGELOG.md` [0.32.0+142] 段
  - 现状: 实测 `flutter analyze` = 0 error / **3 warning** / 133 info。2 个是 R112 自己 AppSnackBar 重构的残留 (crisis_hotline / medication_calendar 删了 `AppMotion.snackBarDurationShort` 用法但没删 import), 1 个是新测试的 unused import。CHANGELOG 已写 "0 error / 0 warning" — 文档提前宣称未达成状态。R111 SP-111-02 (27 warning) 确实清掉了 27→3, 但净 3 仍违反项目自己的 "任何 PR 必保 0 error / 0 warning" 门禁。
  - 建议: commit 前删 3 个 import (5 分钟), 同时把 CHANGELOG 验证行改为实测后的数字; 长期把 `flutter analyze --fatal-warnings` 挂进守门员脚本, 防止再次"宣称清零实为未清"。

- [架构] **[SP-R112-02] AR-17 三源问题未解决, R112 反而新增第 4 个量表名 dispatch 源** — 修复难度:M — 工作量:1-2d
  - 位置: `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart:30` (810L, 186 method) / `lib/presentation/services/scale_name_l10n.dart:15` (新增) / `lib/presentation/pages/assessment/widgets/assessment_center_card.dart:36` (私有 `_l10nName` switch) / `lib/domain/entities/scale_translations/static_scale_translations.dart` (中文 fallback)
  - 现状: 实读验证 — `AppLocalizationsScaleTranslations` (810 行 l10n impl) 在 `lib/` 内 **0 运行时 caller** (只有 test + 注释引用), R111 判定的死代码状态在 R112 依旧成立。R112 为修 R111-02 (en 量表名) 新增 `scale_name_l10n.dart` 作为 name/shortDescription 的**平行** dispatch, 没有复用现有 186-method impl, 也没有删它。量表名/短描述现在有 4 个源: const 中文 fallback、810L l10n impl (死)、私有 `_l10nName`、新 `scaleNameL10n`。量表**题目** (items) 的 i18n 仍是 v1.0 backlog, 810L impl 里已实现的 186 method 从未被 UI 调用过。
  - 建议: 二选一 — (a) 删 810L impl (约 1,590L 连带测试调整), 题目 i18n 等 v1.0 重写; (b) 把 scaleNameL10n/assessment_center_card 全部收敛到 AppLocalizationsScaleTranslations, 让它成为唯一 runtime dispatch。当前"既不删也不接"是最差状态。

### P2

- [架构] **[SP-R112-03] usecase 层 2/6 无运行时 caller (AR-18 半厚化)** — 修复难度:S-M — 工作量:0.5-1d
  - 位置: `lib/domain/usecases/check_safety.dart:56` / `lib/domain/usecases/schedule_refill_reminder.dart:79`
  - 现状: 6 个 usecase 中 4 个已接 presentation (RecordCheckInUseCase / RecordTempMedicationUseCase / TriggerReminderUseCase / DispatchSafetyAlertUseCase / ScheduleAssessmentReminderUseCase / FireCareStrategyUseCase 均有 provider), 但 `CheckSafetyUseCase` 与 `ScheduleRefillReminderUseCase` 只有自己 test 引用 — 生产代码 `SafetyWatchService` 仍直连 `SafetyDetector`, RefillNotifier 仍直连 `refill_scheduler`。usecase 层 739 行中 183 行是"有 test 无 caller"的展示性代码。
  - 建议: 在 safety_watch_service / refill_notifier 接入这 2 个 usecase (小改动), 或删除并把 test 移回 logic 层。别留"两边都维护"的中间态。

- [底层] **[SP-R112-04] E5 (saveSetup assert→StateError) 新抛路径 0 测试** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/core/data/database/app_database.dart:453-462`
  - 现状: R112 把 `assert(contactList.length == contactConsents.length)` 改成 release 也生效的 `throw StateError` (PIPL §13 保护, 方向正确), 但 grep 全 test/ 无任何断言此 StateError 的 case — 新行为无 lock-in, 未来有人改回 assert 或改成静默截断都测不出。
  - 建议: setup 测试加 1 个 "长度不一致 → throwsA(isA<StateError>())" case。

- [底层] **[SP-R112-05] 覆盖率闸门余量薄 (data 仅 +1.5pp)** — 修复难度:S — 工作量:持续观察
  - 位置: `coverage_threshold.yaml` by_layer.data=45, 实测 46.5%
  - 现状: `check_coverage.py` 实测 domain 72.6/70 (+2.6pp) / data 46.5/45 (+1.5pp) / presentation 53.8/30 / shared 84.7/50 / core 25.1/20。data 层随便删 1-2 个 test 文件 (如 safety_alert_builder 清理) 就可能红闸。R112 删了 builder 死参数 + 2 个服务死字段, 对应 test 也删了若干行 — 当前绿但接近临界。
  - 建议: 短期不动; 若后续再清 data 层死代码, 先补等量覆盖再删。

- [底层] **[SP-R112-06] check_16kb_alignment 仍是"打印指令"而非"验证"** — 修复难度:S — 工作量:1h + 一次 release build
  - 位置: `scripts/check_16kb_alignment.py`
  - 现状: 脚本只输出 objdump 操作步骤, 没有自动 PASS/FAIL 判定。守门员清单里它是唯一无 exit-code 语义的。baseline 注明"1 skip (16kb 待重 build)" — 即 2025-11-01 Google Play 强制的 16KB 页对齐至今未被任何工具链自动验证过。
  - 建议: 脚本支持 `--so-path` 参数 + objdump 解析 LOAD 段 align ≥ 2^14 判定 + exit code; 下次 release build 后跑一次并记录结果。

### P3

- [底层] `docs/CHANGELOG.md` [0.32.0+142] 验证行 "flutter analyze 0 error / 0 warning" 与实测 (3 warning) 不符 — 见 SP-R112-01。
- [文档] `AGENTS.md:136` "R111 实测 2311 pass" 仍准确 (R111 baseline), 但 R112 段落尚未写 (当前 2377 pass) — commit 时应加 R112 章节并同步数字。
- [文档] `AGENTS.md:333` 写 coverage 阈值 "data ≥ 50%", 实际 `coverage_threshold.yaml` 为 45 (注释自认"目标 50% 留 R96+") — 文档数字过期 2 个版本。同文件 coverage_threshold.yaml 注释 "18 守门员" 也已过期 (现 22)。
- [底层] `lib/presentation/widgets/check_in_button.dart:86` `child: _EntrySpring(` 缩进错位 (R112 手改 EM-14 时引入), `dart format` 未跑。commit 前统一 format。
- [底层] `test/presentation/pages/setup/setup_redesign_round10_test.dart:31` 仍有一个空 `scheduleDailyReminder` fake override (R108 迁移注释自认已迁到 NotificationDelegate) — 10 处死 override 清掉了 9 处, 这 1 处漏网 (analyze 不报, 无害但死代码)。
- [仓库] 17 个 untracked 全部是 R112 合法产物 (7 新源码/测试 + android changelogs ×2 目录 + r111/r112 审计报告目录) — commit 时应收全, 审计报告入库符合项目先例 (r111 报告已 planned)。
- [底层] `pubspec.yaml` 有 CRLF→LF 整文件转换 (103/103 行), commit 前确认其他文件无混入 EOL churn。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| lib/core/data/services/sms_service.dart:109,191 | https://dysmsapi.aliyuncs.com/ (阿里云 SMS endpoint) | 已隐藏 (无 AccessKey, 端点本身非机密) |
| lib/domain/logic/chinese_holidays.dart:17 | https://holidayapi.com (注释, 明确"不接") | 已隐藏 (未使用) |
| fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt, support_url.txt | https://chroniccare.app/privacy + /support | **占位符/外部依赖** — 域名未注册 (ICP 7-20d, R110/R111 跨期已知) |
| fastlane/metadata/{ios 3 locale,android zh-CN}/description:36 | https://findahelpline.com | 已隐藏 (公开危机热线目录, 合规要求) |

无硬编码密钥 / token / 邮箱口令。lib/ 内无泄露。

## 4. 四类问题 (用户点名)

### 4.1 上架相关
- 代码面达标: check_pii_in_title / check_apple_health_claim / check_legal_consent / check_review_information_todo 全绿 (后者 3 处 warn = first/last name/phone 占位, 属外部依赖)。4 个 iOS 资产 fail 与域名/keystore 均为已知外部阻塞, 无新增。

### 4.2 架构相关 (详给 07 整合)
- usecase 层: 4/6 接入、2/6 展示性 (SP-R112-03)。
- scale translations: 4 源并存 + 810L 死 impl (SP-R112-02)。
- R112 架构正向动作: `user_name_helper.dart` 移 domain/logic (check_all 一致性规则驱动, 移动后 0 违规, 测试同步搬迁); `SafetyAlertSenderImpl`/`SafetyWatchService` 死字段清除; `_NoOpSafetyAlertSender` 改名满足 usecase 命名守门员。

### 4.3 重构建议
- 本轮大 diff (25K 行) 中 ~24K 是 l10n 重生成 + `dart format` 重排 + reminders_hub mojibake 注释清理 (HEAD 版本 20 处 `�` 乱码清零)。真实功能变更约 300 行。建议 commit 时把"格式/生成/乱码清理"与"功能变更"分 commit, 便于 review 与 revert。
- scale_name_l10n.dart 与 assessment_center_card._l10nName 二合一 (见 SP-R112-02)。

### 4.4 半成品 / TODO / 残缺功能
- spring.dart: **R111 P0-08 已闭环** — `check_in_button.dart:245` `Spring.standard.toSimulation()` 是真实运行时 caller, 不再是 0 caller。残留小瑕疵: `Spring.of()` 内 `final _ = context` 占位 (自注释未来接 accessibility, 可接受)。
- weight_widgets `_getHeightCm()` 返 null 占位 (R108 P0-019 短期方案, heightCm 列留 R109) — 有自注释, 已知半成品, 不新增。
- PHQ-9/GAD-7 题目 i18n 仍 v1.0 backlog (phqGad7I18nEnabled=false) — 已知。

## 5. 总结 + 给整合者的建议

**R112 实测门禁 (全部本次实跑)**:
- `flutter analyze`: 0 error / **3 warning** / 133 info (warning 与 CHANGELOG 宣称不符)
- `flutter test`: **2377 pass / 4 fail (iOS 资产) / 1 skip (main_migration_i18n_round95, 有意+文档化, 非静默)** — 与 baseline 一致
- `dart scripts/check_all.dart`: 纯度+一致性 **PASS**
- 13 个 python 守门员全绿: arb_keys / changelog / cross_feature / drift_namespace / orphan_arb_keys / legal_consent / strings_hardcoded / zh_hant_consistency / usecase_layer / review_information_todo (warn-only, 3 外部占位) / pii_in_title / apple_health_claim / coverage (PASS, data 余量 +1.5pp)
- check_16kb_alignment: 指令模式无判定 (SP-R112-06)

**R111 宣称闭环的实读验证结果**:
- ✅ E1/E2 export v5: 真闭环。export 双向 +9 字段 (medication 5 + mood 5 + consent 4), import 全走 validate + 默认值降级, 老 v4 文件优雅 null。7 个 round-trip test 全真实断言 (含 FK 重映射 + inactive 过滤孤儿 case)。附赠 E3 (checkIn.medicationId 重映射) 也一并闭环。
- ✅ SP-111-04: 36 test 一致性断言 (8 量表 × items/options/severity/元数据 4 组 + 越界 + override), 不是抄题面假测试。
- ✅ SP-111-05/08: 真实 SQLite dry-run v19→v22 (DROP 5 列 → 重开 → 3 步迁移 → 断言列回归/数据保留) + onUpgrade guard 源码自动比对 — 本项目最扎实的迁移测试。
- ✅ SP-111-02: 27 warning → 3 (10 处死 fake @override 清除, 剩 1 处 setup_redesign 漏网 + 2 个新 import 残留)。
- ✅ FS-14 / EM-14 / EM-16 / EM-21 / R111-02 / R111-03 / GP-10: 全部实读确认修复 + 各自带真实行为测试。
- ❌ AR-17: 未闭环, 且新增平行 dispatch (SP-R112-02)。
- ⚠️ "analyze 0 warning": 未达成 (SP-R112-01)。

**给整合者**: 修 SP-R112-01 (5 分钟) 后本批可 commit; SP-R112-02 建议列入 R113 架构专项第 1 项 (与 AR-17 原计划合并); 其余 P2/P3 可随手下轮处理。

## 附录: 详细证据 (grep 输出、文件引用)

- 门禁实测输出全文见本报告 §5; analyze 3 warning 明细:
  ```
  warning • Unused import: 'package:chroniccare/core/theme/app_motion.dart' • lib/presentation/pages/crisis_hotline_page.dart:30:8
  warning • Unused import: 'package:chroniccare/core/theme/app_motion.dart' • lib/presentation/pages/medication/medication_calendar_page.dart:27:8
  warning • Unused import: 'package:chroniccare/domain/entities/check_in_entity.dart' • test/presentation/pages/medication/medication_backfill_round8_test.dart:12:8
  ```
- test 输出关键行: `01:19 +2377 ~1 -4: Some tests failed.` (4 fail 全在 test/ios/app_icon_size_round108_test.dart + launch_image_size_round108_test.dart, 资产占位)
- `AppLocalizationsScaleTranslations` lib/ 内引用全部为注释 (`lib/domain/logic/isi.dart:37` 等), 唯一实类是 `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart:30`, runtime caller 0。
- `CheckSafetyUseCase` / `ScheduleRefillReminderUseCase` 全库引用: 自身文件 + `test/domain/usecases/*_round65_test.dart` + 注释; 生产 provider 0。
- spring.dart caller: `lib/presentation/widgets/check_in_button.dart:40 (import) :245 (Spring.standard.toSimulation)`。
- HEAD 版 reminders_hub_page.dart 20 处 `�` 乱码 → working tree 0 (R111-10 闭环实锤)。
- saveSetup E5 diff: `lib/core/data/database/app_database.dart` `git diff -w` 仅 +11/-4 (assert→StateError + user_name_helper 路径注释), 其余 1033 行 churn 均为 import 重排 + format。

<!-- subagent: superpowers 完成时间: 2026-08-13T05:10:00Z -->
