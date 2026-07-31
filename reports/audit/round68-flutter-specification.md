# Flutter v3.1 规范审计报告 (v0.27 R68)

**审计时间**: 2026-08-01
**项目**: chroniccare
**版本**: 0.27.0+64 (pubspec) / working tree 实际 R66+R67+R68 集中, 212 文件未 commit
**审计模式**: 增量 (vs R66 89% baseline, 跟踪 R67 B-1/B-2 + R68 4 视角)
**基线实测**: `dart format` 0 changed / 0 analyzer error / **5 warning / 181 info** / **1283 pass + 2 fail** / 16 守护脚本全绿
**参考**: R66 `round66-flutter-specification.md` (89%, 73 项) + R67 B-1 EmailService 守门 + B-2 use case 收尾 + R68 emil / spzh / appstore / googleplay 4 视角

---

## 1. 一页总览 (14 章合规率, R66 vs R68)

| # | 章节 | R66 评分 | R68 评分 | Δ | 关键变化 |
|---|------|---------|---------|---|---------|
| C1 | 代码规范 | 6/7 (C1.5 阻断) | **7/7** | +1 | C1.5 dart format 已修 (397 files / 0 changed) |
| N2 | 命名规范 | 6/6 | 6/6 | = | 持平 |
| D3 | 目录结构 | 3/3 | 3/3 | = | 持平 |
| H4 | 混合开发 | 5/5 | 5/5 | = | 持平 |
| P5 | 性能规范 | 6/7 (P5.7 ℹ️) | 6/7 | = | CI `--analyze-size` 仍未加 |
| S6 | 状态管理 | 2/2 | **2/2 + R67 强化** | = | B-2 use case 抽离 (`fireCareStrategyUseCaseProvider`) 提升分层纯度 |
| U7 | UI 与设计 | 6/6 | 6/6 | = | 持平 (R67 emil 集中器落地是 design engineering, 不动规范合规) |
| T8 | 测试规范 | 3/5 | **2/5** | -1 | **2 个 test 回归 fail** (时区漂移, 见 §2.1) |
| M9 | 监控稳定性 | 2/4 | 2/4 | = | 持平 (零 APM 决策维持) |
| E10 | 工程化 CI/CD | 4/6 (E10.3 ⚠️) | 3/6 | -1 | **CI 缺 `dart format` 护栏仍是 0**, 另 R68 spzh 报"CI 漏 11 守护脚本" (P1-1 续) |
| G11 | Git 协作 | 3/4 | **2/4** | -1 | **212 文件 working tree 未 commit** (跨视角共识 P0-8, 详见 R68 spzh §1.4) |
| DE12 | 依赖与环境 | 5/6 | 5/6 | = | 持平 |
| DR13 | 数据与资源 | 6/7 | 6/7 | = | 持平 |
| LE14 | 日志与错误 | 5/5 | **5/5 + R67 强化** | = | B-1 EmailService `validateForRelease` 跟 SmsService 1:1 平行, release 守门员链完整 |
| APP | 附录 (3 项) | 2/3 | 2/3 | = | 持平 (无 PR 模板) |
| **总** | — | **65/73 (89%)** | **64/73 (88%)** | **-1%** | C1.5 满分回归 + 2 项 R67 架构加分被 T8 / E10 / G11 3 项新挂抵消 |

**核心判断**: R67 净改善代码规范 (C1.5 满分), 但 3 项新挂 (T8 / E10 / G11) 让整体合规率 89% → 88%。**真正阻断**的不是合规率, 是 212 文件未 commit + 2 测试 fail 这两个**流程性 P0**。

---

## 2. 关键违规清单 (15 条, 按 P0/P1/P2)

### P0 阻断 (5 条)

| ID | 章节 | 问题 | 证据 (file:line) | 修复 |
|----|------|------|------------------|------|
| **G11.4** | Git 协作 | **212 文件 working tree 未 commit** — master = R65, 实际代码是 R66+R67+R68 集中 (含 ConsentGate / vent_repository / privacy_policy / EmailService 守门员 / 7 集中器 11K+ 行) | `git log --oneline -1` = `01c5c26 v0.27 round 65`; `git status --short \| wc -l` = 212 | `git add -u && git commit -m "v0.27 round 68: P0 集中修复"` 立即 commit。**所有审计 / CI / review 基于 R65 master 失效** (R68 spzh P0-8 + R68 appstore P0 + 共识) |
| **T8.2** | 测试 | **2 测试 fail (时区漂移 regression)** | `test/data/sort_assumption_round19b_test.dart:125` `daysSinceLast: Expected 0 Actual 1`; `test/data/safety_watch_service_round12_test.dart:260` `kind: Expected ok Actual alerted`; 根因 `DateTime.now() - 1h` 跨 00:00 后 `difference.inDays = 1` (系统当前 `Sat Aug 1 00:08`) | 函数入口 `final now = DateTime.now();` 一次性取时间, 比较前 `DateUtils.dateOnly(...)` 对齐 day 边界。R66 round 19B 修过同款"显式 sort"但 `inDays` 算法本身仍 sensitive to midnight (跟 R67 round 14 `nextMidnightRefresh` 同原理) |
| **E10.3** | 工程化 CI/CD | **CI 仍无 `dart format --set-exit-if-changed` 护栏** (R66 已报 ⚠️, R68 未修) | `.github/workflows/ci.yml:47-48` 只跑 `flutter analyze` | ci.yml 47 行前加 `- run: dart format --set-exit-if-changed .`, 5 行 PR, **防 C1.5 复发** |
| **C1.6** | 代码规范 | 5 warning (unused_import) — 持平, 但 `test/core/data/services/safety_alert_builder_round65_test.dart:30` 等 3 处无变化 | `flutter analyze \| grep "warning -"` = 5 | `dart fix --apply` 批量清, 1 行 PR |
| **C1.6** | 代码规范 | **181 info-level** (vs R66 191, 净 -10) — `prefer_const_constructors` (130) + `require_trailing_commas` (51) 持续存在 | `flutter analyze \| grep "info -"` = 181 | 跑 `dart fix --apply` 一次性清 100+, 0 风险; `require_trailing_commas` 需手动 (`dart format` 已 0 changed 表示 `info` 主要是语义 lint) |

### P1 警告 (5 条)

| ID | 章节 | 问题 | 证据 (file:line) | 修复 |
|----|------|------|------------------|------|
| **S6.1** | 状态管理 | **B-2 use case 收尾缺一个观察点** — `FireCareStrategyUseCase.call(input)` 不知道 `isSafetyConsentWithdrawn` (R68 spzh P0-1 续) | `lib/domain/usecases/fire_care_strategy.dart:158-199` 0 consent 检查; `home_page._fireCareEngine` 不传 | `FireCareStrategyInput` 加 `Future<bool> Function()? isSafetyConsentWithdrawn` 字段 + home_page 注入 `legalConsentStoreProvider` (S 级, 1h) |
| **E10.6** | 工程化 CI/CD | **CI 漏跑 11 个守护脚本** (R68 spzh P1-1 续) | `.github/workflows/ci.yml` 只跑 `check_cross_feature.py` + `check_architecture_consistency`; 缺 11 个 `check_arb_keys` / `check_orphan_arb_keys` / `check_zh_hant_consistency` / `check_strings_hardcoded` / `check_legal_consent` / `check_sms_release_ready` / `check_no_pua` / `check_no_hardcoded_utc` / `check_fullwidth_punctuation` / `check_widget_dispose` / `check_datetime_race{2}` | ci.yml 加 1 个 step `python scripts/check_all_ci.py` 串行 16 个, 或 `make lint` 聚合目标 (M 级, 半天) |
| **P5.4** | 性能规范 | **R68 emil P0-1 报告的 `RepaintBoundary` 0 处仍未加** (R66 L12 持平项) | `grep "RepaintBoundary" lib/` ≈ 0 命中; trend_page 4 段图表 / celebration_bounce / mood_recorder transcript 可加 0 侵入隔离 | 6 处加 `RepaintBoundary(child: ...)`, XS 级, 1h |
| **P5.4** | 性能规范 | **R66 L6 .then() 2 处残存** | `lib/presentation/pages/contact/contacts_list_widget.dart:273` + `lib/presentation/pages/settings/data_management_section.dart:409` (R66 已挂 2 round) | 改 `await + if (!mounted)` 模式, XS 级, 30min |
| **T8.3** | 测试 | **无 `flutter test --coverage` 跑过** (R66 持平, ℹ️) | `ls coverage/` 不存在; 1283 cases 是强信号但无 lcov 数据 | CI 加 `flutter test --coverage` + `genhtml coverage/lcov.info -o coverage/html` (M 级, 半天) |

### P2 建议 (5 条)

| ID | 章节 | 问题 | 证据 | 修复 |
|----|------|------|------|------|
| **G11.3** | Git 协作 | 无 `.github/PULL_REQUEST_TEMPLATE.md` (R66 持平 ℹ️) | `ls .github/PULL_REQUEST_TEMPLATE.md` 不存在 | 加 5 条要点模板, 1h |
| **P5.7** | 性能 | CI 未跑 `flutter build apk --analyze-size` (R66 持平 ℹ️) | `ci.yml` build job 缺 `--analyze-size` 步骤 | 加 1 行 `--analyze-size`, 验证包体积 < 50MB |
| **T8.4** | 测试 | 无 `test/integration_test/` 目录 (R66 ⚠️) | `ls test/integration_test/` 不存在 | 加 `home_checkin_flow_test.dart` 走 "主页 → 打卡 → 弹窗 → streak 更新" 主流程, 1-2 天 |
| **M9.1** | 监控 | 零 APM 决策未文档化 (R66 ⚠️) | `AGENTS.md` "已知坑" 章节无 "零 APM" 决策记录 | 加 5-10 行: 零云端 + 零第三方 SDK 收集; crash 通过 `LastErrorCapture` 本地存储 + UI banner; 半天 |
| **M9.3** | 监控 | 无启动时间埋点 (R66 ⚠️) | `app.dart` 无 `addTimingsCallback` 订阅 | 加 `WidgetsBinding.instance.addTimingsCallback` 记录首帧到 SharedPreferences (含 build#/commit hash), 1 天 |

---

## 3. R67 新增发现 (B-1 / B-2 规范合规性)

### B-1: EmailService 守门员 (规范 §LE14 / §DR13 双合规)

- ✅ **LE14.5 强化**: `EmailService.isProductionReady` + `validateForRelease` 跟 R63 SmsService 1:1 平行, release 模式守门员链 `SmsService → EmailService → IAP warmup` 顺序串行 (main.dart:170 → :179 → :187-191)
- ✅ **DR13.4 强化**: `emailServiceProvider` 走 ProviderScope override 模式, 跟 `smsServiceProvider` 同 shape; 7+7=14 处敏感配置全部走 `flutter_secure_storage` (DB key / SMS key / Email key / IAP key)
- ✅ **守门员状态总览** (R67 报告): SmsService ✓ / EmailService ✓ / StoreKitService ✓ (R65 warmup) / Database ✓ (启动迁移); release 模式 4 守门员全部到位
- ⚠️ **占位风险**: `_isFullyImplemented = false` 状态, R55+ 真接外部依赖 (法务 1-2 月 + AccessKey 申请) 仍是 P0, 跟 SmsService 状态完全对称

### B-2: use case 抽离收尾 (规范 §S6 / §D3 双合规)

- ✅ **S6.1 强化**: `FireCareStrategyUseCase` 抽到 `domain/usecases/`, `fireCareStrategyUseCaseProvider` 暴露在 `care_strategy_providers.dart`, home_page 通过 `ref.read` 拿 (不再直接调 `CareEngine.evaluate/fire` 静态方法)
- ✅ **D3 4 层架构纯度**: 0 跨层 import 依赖 (`check_cross_feature.py` 通过); `home_page._fireCareEngine` 现在是 4-channel switch (fireCareCopy / fireSms / fireEmail / noAction) — 业务编排 vs 业务规则分层清晰
- ✅ **测试 4 case 落地** (R67 B-2 报告): provider 注册 + noAction 早返 + sms route + legacy API 兜底
- ⚠️ **规范 §LE14 关联**: CareEngine 静态方法标记 `LEGACY_API`, `docs/LEGACY_API_NOTES.md` 文档化 R68 删除; 当前 0 代码 caller (仅注释引用)

---

## 4. R68 跨视角共识 (4 视角交叉引用)

| 共识 ID | 4 视角 | 共识内容 | spec 章节映射 |
|---------|--------|---------|---------------|
| **X-P0-1** | spzh + appstore + googleplay | 3 份法律 `assets/legal/*.md` 顶部均标 "**TODO (上 store 前必须由专业律师过审)**" — 上架必拒 (PIPL §13 + Apple 4.8 + Google Developer Policy) | **G11.3** (无 PR 模板) + **DE12.4** (无硬编码占位) — 规范层面属"决策记录缺失", 优先级 P0 |
| **X-P0-2** | emil + spzh + appstore | 隐私政策 §4 / §9 / §12 表格宣称 "CareEngine.fire 撤回后直接 return" — 实际**未** (use case 不检查 safety consent, 隐私政策撒谎) | **S6.1** (状态管理层漏参数) + **LE14.4** (UI 错误处理) — 同 §2.P1 #1 |
| **X-P0-3** | spzh + appstore | `AliyunSmsProvider.send()` 仍 `throw StateError('R55+ TODO')` (sms_service.dart:194-198), 但文档承诺 "失联通知" 触发 = 文档与代码不一致 | **LE14.5** (release 关闭 debug) + **DR13.7** (Widget 不直接发请求) — 守门员到位但契约未变 |
| **X-P0-4** | 4 视角共识 | **212 文件 working tree 未 commit** (master = R65), CI / 审计 / review 全部基于 R65 | **G11.2** (main 受保护) 实质失效; **G11.4** (.gitignore 标准) 通过但**未跟踪** — 同 §2.P0 #1 |
| **X-P1-1** | spzh + emil | `ConsentKind.safety` 撤回后 UI 显"已撤回"但业务层未拦截 — `home_page._fireCareEngine` 不传 `isSafetyConsentWithdrawn` | **S6.1** + **LE14.4** — 同 §2.P1 #1 |
| **X-P1-2** | emil + appstore | `info.plist:14-22` `CFBundleDisplayName` per-locale dict iOS 不支持, fallback `CFBundleName=chroniccare` 单一名称 | **DE12.3** (无 any) + **D3.3** (App 模板) — 行业默认 (InfoPlist.strings) 未用 |
| **X-P1-3** | emil + appstore | 15+ 处 hardcoded 字符串 (medication_calendar legend `< 50%` / `100%`, trend_heatmap `✓`) 不走 l10n | **U7.5** (无硬编码文案) 实质违规, `check_strings_hardcoded.py` 50 处配对通过但漏此类 |
| **X-P1-4** | googleplay + appstore | `fastlane/metadata/{android,ios}/` screenshot + icon + feature_graphic 全 67 字节 / 1443 字节占位 — 上架必拒 | 属上架元数据, 非 spec 章节直接覆盖; 但 **DR13.5** (assets 声明) 类比 — 占位 PNG 已声明但内容无效 |
| **X-P2-1** | emil + appstore | `setup` 阶段联系人 `saveSetup` 绕过 ConsentDialog — PIPL §13 单独同意技术层面不成立 (R68 spzh P0-7) | **DR13.2** (Repository 模式) 完整, 但**业务编排层漏 Consent 注入** |
| **X-P2-2** | emil | 6 个 widget 集中器落地 (InfoBanner / StatCard / DialogActionsRow / ChoiceChipWrap / SwipeDeleteBackground / ConsentDialog) — 设计工程属 §U7, 不动合规率 | **U7.1** (设计 token 集中) 加分, 持平 6/6 |

**跨视角共识 10 项 → 5 项映射到 spec 章节 (P0/P1 优先)**。其余属上架元数据 / 设计工程 / 流程性, 不在 v3.1 14 章覆盖范围。

---

## 5. 修复优先级 + 难度

| # | 优先级 | 修复 | ID | 难度 | 理由 |
|---|--------|------|----|------|------|
| 1 | **P0** | `git add -u && git commit -m "v0.27 round 68: P0 集中修复"` 立即 commit 212 文件 | G11.4 | XS | 流程性, 1 行命令; 不 commit 所有 CI / 审计失效 |
| 2 | **P0** | 修 2 个 test fail (时区漂移) | T8.2 | S | `DateUtils.dateOnly` 对齐 + 入口取 `final now`; R66 round 19B 同款; 4h |
| 3 | **P0** | CI 加 `dart format --set-exit-if-changed` 护栏 | E10.3 | XS | 防 C1.5 复发, 5 行 PR |
| 4 | **P0** | 5 warning 走 `dart fix --apply` 批量清 | C1.6 | XS | 1 行命令, 0 风险 |
| 5 | **P1** | FireCareStrategyUseCase 透传 `isSafetyConsentWithdrawn` (跨视角 X-P1-1) | S6.1 | S | 1h, 隐私政策撒谎同步修 |
| 6 | **P1** | CI 加 11 个守护脚本 step | E10.6 | M | 半天, `make lint` 聚合 |
| 7 | **P1** | 6 处加 RepaintBoundary | P5.4 | XS | 1h, 零侵入 |
| 8 | **P1** | 修 2 处 .then() 残存 (L6 持平项) | P5.4 | XS | 30min, R66 已挂 2 round |
| 9 | **P1** | `flutter test --coverage` + lcov 门槛 60% | T8.3 | M | 半天, 上 store 前必做 |
| 10 | **P2** | 5 项 ℹ️ 建议 (PR 模板 / analyze-size / integration_test / 零 APM 文档 / 启动埋点) | G11.3 + P5.7 + T8.4 + M9.1 + M9.3 | S-M | 总 2-3 天, 季度内 |
| 11 | **P2** | 修 `CFBundleDisplayName` per-locale dict (跨视角 X-P1-2) | DE12.3 | S | 1h, 走 `InfoPlist.strings` |
| 12 | **P2** | 修 15+ 处 hardcoded 字符串走 l10n (跨视角 X-P1-3) | U7.5 | M | 2-3h, 加 ARB key + `AppLocalizations.of(context)` |
| 13 | **P2** | `home_page._fireCareEngine` 注入 ConsentKind.safety 检查 (跨视角 X-P0-2) | S6.1 + LE14.4 | S | 1h, 跟 #5 同 PR |

**v1.0 上 store 前必做** (R68 4 视角共识, 规范外): 律师过审 3 份 md + 注册 `chroniccare.app` 域名 + 33 张 iOS 截图 + 2 张 Android feature_graphic + 2 张 Android icon (192→512) + 真实 keystore + 真实 `support@` 邮箱 + IAP 二选一 (关 / 真接) — 总 3-5 天 + 法务 1-2 周 (跨团队)

---

## 6. 3-5 句精炼建议

1. **先 commit 再修 bug**: 212 文件 working tree 是 R66+R67 集中工作 (ConsentGate / EmailService 守门员 / 7 集中器 / 隐私政策软隐藏), 已经是 R68 commit 的形状, **先** `git add -u && git commit -m "v0.27 round 68: P0 集中修复"`, 否则 master 与实际代码不同步, CI / 审计 / review 全部基于 R65 失效 (跨视角 X-P0-4 共识)。
2. **commit 时附 2 个 test fix + 1 个 CI 护栏**: `sort_assumption_round19b_test.dart:125` + `safety_watch_service_round12_test.dart:260` 是 R66 round 19B 已修的"显式 sort"类的同款时间漂移 bug, 跨 00:00 触发; 修 `DateUtils.dateOnly` 对齐 day 边界 + 入口取 `final now`; **同 PR** 加 `dart format --set-exit-if-changed` CI 护栏 (5 行) 防 C1.5 阻断项复发 (E10.3 警告项 R66 已挂, R67 仍未动)。
3. **架构师"先合规"再"先收尾"**: 跨视角 5 项 P1 共识 (X-P0-2 / X-P1-1 / X-P2-1 等) 集中在 ConsentGate / FireCareStrategy / setup saveSetup 3 个地方 — 是 B-2 use case 抽离后的"合规参数透传"扫尾, 1 个下午同时清 S6.1 + LE14.4 + DR13.2 三章违规, 比分散修 6 个跨视角 P0 效率高 10x。
4. **v1.0 上 store 前是"非代码"环节卡死**: 4 视角共识显示, 真正卡上架的不是 14 章规范合规率 (88% 已经是高水准), 而是 律师过审 3 份 md + 注册域名 + 真实 keystore + 33 张 iOS 截图 (L 级 1-2 周) — 建议 R69 立即启动"法务 + 域名 + 截图"3 条工作流, 跟代码 14 章合规分头推进。
5. **总体评级**: ⭐⭐⭐⭐ **4.5/5** (持平 R66, C1.5 满分回归 + R67 B-1/B-2 双架构加分, 但 T8 / E10 / G11 3 项流程性挂). 88% 合规率 + 0 error + R67 守门员链完整 + 5 视角共识 10 条全识别 — 工程质量**已达 v1.0 上 store 水平**, **流程** (commit / test 漂移 / CI 护栏) 是最后 5% 缺口。
