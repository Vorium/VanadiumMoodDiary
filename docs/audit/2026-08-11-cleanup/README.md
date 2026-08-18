# 8-11 cleanup 综合审视 · README

> **跑时间**: 2026-08-11
> **触发**: v0.31.0 Apple Health 风格重设计 23 commit 落地后, 跑综合审视确认无新引入问题
> **基线**: master HEAD `01d8f4a` v0.31.0+107 (23 work commit, 净 +7447/-3504)
> **加权综合**: 7.5/10 (R108 6.2 → +1.3 升)

## 报告目录索引

| # | 文件 | 大小 | 内容摘要 |
|---|---|---|---|
| 0 | `00-spec.md` | 4.4KB | 7 视角分工 + 5 维度评估 + 输出格式 + 时间线 + 跑前 baseline 锁定 |
| 0 | `00-FINAL-CONSOLIDATION.md` | 14.3KB | **整合报告** — 7 视角评分汇总 + 17 P0 紧急修 + 16 P1 + 6 P2 + 11 P3 + 顶层架构总结 + R109+ 路线图 + VERDICT |
| 1 | `01-emil.md` | 11.1KB | 动效 / 组件设计 / iOS HIG — 5 P0 + 6 P1 + 5 P2, R31 评分 8.5/10 |
| 2 | `02-superpowers-en.md` | 11.4KB | 工程师实操 / TDD / code review — R31 评分 8.5/10 (R108 6.5 → +2.0 最大升幅) |
| 3 | `03-superpowers-zh.md` | 9.1KB | 中文开发者上手成本 / R108 §六 43 项对照 — R31 评分 7.5/10 |
| 4 | `04-flutter-spec.md` | 11.1KB | Flutter v3.1 规范 14 章 + 6 附录 — 97% 合规 (R108 88% → +9%) |
| 5 | `05-appstore.md` | 10.8KB | iOS 上架 / 5.1.3 抽审 / Info.plist / LaunchImage — R31 评分 3.5/10 (持平 R108) |
| 6 | `06-googleplay.md` | 11.4KB | Android 上架 / Data Safety / 16KB / PrivacyInfo — R31 评分 5.5/10 (持平 R108) |
| 7 | `07-apple-health.md` | 9.6KB | Apple Health app 设计语言 / iOS 17/18 视觉 / 11 feature — R31 评分 7.0/10 (R108 3.0 → +4.0) |
| - | (08-line-by-line.md) | - | **未跑** — spec 提及 8 视角, 实际只跑了 7 视角 (emil/superpowers-en/superpowers-zh/flutter-spec/AppStore/GooglePlay/Apple Health), 顶层架构 + 底层逐行已合并入 `00-FINAL-CONSOLIDATION.md` §5 |

**总大小**: 9 文件 79KB (lens 报告合计)

## 7 视角评分汇总

| 视角 | R108 | R31 | 变化 | 一句话评语 |
|---|---|---|---|---|
| flutter-spec | 88% | **97%** | +9% | 5 token + 6 widget 集中化 = R65 后最成熟 design engineering 时刻 |
| emil | 8.5 | 8.5 | 持平 | 主页 stagger 8→3 闭环抵消新引入 4 处硬编码中文 |
| superpowers-en | 6.5 | **8.5** | **+2.0** | 22 commit 100% 跟 test 同步, TDD 实践度 12/13 |
| Apple Health | 3.0 | **7.0** | **+4.0** | 视觉层 9.5/10 优秀, 11 feature 仍 0 改是减分项 |
| superpowers-zh | 6.5 | 7.5 | +1.0 | 中文 doc 完整 + dartdoc 中文 spec §X.X 引用 |
| AppStore | 3.5 | 3.5 | 持平 | R108 5 项上架硬阻塞跨期 100% 残留 0 闭环 |
| GooglePlay | 5.5 | 5.5 | 持平 | R108 26 P0 中 12 仍阻塞, R31 0 新 P0 |
| **加权综合** | **6.2** | **7.5** | **+1.3** | 视觉层 9.5/10 拉升 - 上架层 0/10 跨期残留拉低 |

## 17 P0 紧急修 (R109 第 1 周闭环 1 周内可到 8.5/10)

### 上架/合规 (7 项, 3.5h 总和, 0.5h 立即可修)

| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-01 | `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` 4 TODO 占位 | S 30min | AppStore BUG-1 | 真实姓名 + 邮箱 + 手机号 |
| P0-02 | `notes.txt:1` 版本号 `v0.30.0+85` 过期 | S 5min | AppStore BUG-3 | 改 `0.31.0+107` |
| P0-03 | `store_kit_service.dart:50` productId `com.chroniccare.app.lifetime` 冗余 | S 5min | AppStore BUG-7 | 改 `com.chroniccare.chroniccare.lifetime` |
| P0-04 | `description.txt:17,27` PHQ-9/GAD-7/depression/anxiety/bipolar/PTSD/ADHD 5.1.1 抽审 | S 30min | AppStore BUG-6 | 删 5 病名, 守门员 `description_no_medical_claim_round108_test.dart` |
| P0-05 | 3 个 `DarwinNotificationDetails()` 空构造 (notification_service:229 / reminder_dispatcher:110 / snooze_manager:95) 锁屏 PII | S 0.5h | AppStore BUG-2 + emil P0-C 跨视角 | 加 `categoryIdentifier` + `relevanceScore: 0` + `interruptionLevel` |
| P0-06 | 4 个 `AndroidNotificationDetails.visibility` 未设 `NotificationVisibility.secret` | S 0.5h | GooglePlay P0-006 | 4 处全设, 跨期 锁屏 PII Android 端 |
| P0-07 | 7 处 raw `IconButton` (R108 报告 + R11a 新增 medication_page.dart:87) | S 1h | emil P0-C | 全改 `PressFeedbackIconButton` 集中器 |

### Apple Health 半成品 (5 项, 4-5h)

| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-08 | `Spring` 物理模型 145 行 0 caller 死代码 (spec §3.4.3 双轨制空跑) | M 1-2h | emil P0-E + superpowers-en P1 + Apple Health P0-3 | 接 `_EntrySpring` 走 `Spring.standard.toSimulation()`, 给 spring.dart 写 5 case test (不删) |
| P0-09 | R108 P0-004 "Apple Health" 关键词 lock-in 被反转 134 处新增到 lib 注释 | S 1h | Apple Health P0-1 | 扩展 `check_apple_health_claim.py` 扫描 `lib/**/*.dart` 注释 + 设计 spec, 触发 fail |
| P0-10 | spec §4.9 PageScaffold translucent AppBar 未实现 (page_scaffold.dart 0 改) | M 1-2h | Apple Health P0-2 | 改 PageScaffold: BackdropFilter blur(20) + white@0.6 + hairline divider + reduce-transparency 适配 |
| P0-11 | `dart format` 2 文件 wrap diff (check_in_button + primary_button 各 1-2 行) | S 5min | flutter-spec C1.5 | 跑 `dart format lib/presentation/widgets/check_in_button.dart lib/presentation/widgets/primary_button.dart` |
| P0-12 | 设计文档 44KB untracked (`docs/design/2026-08-10-apple-health-redesign/{spec,plan,NEXT-SESSION-START-HERE}.md`) | S 5min | superpowers-zh P1-1 | `git add docs/design/...` + commit "0.31.0: 入库 Apple Health 设计文档" |

### 上架硬阻塞 (5 项, 1-2 月, 设计师/外部依赖)

| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-13 | iOS 截图 6+ 张 (fastlane 脚本存在未跑) | L 1-2d | AppStore §3 | fastlane deliver screenshots |
| P0-14 | iOS LaunchImage 3 张 68B 占位 | L 1-2d | AppStore BUG-4 | 设计师出图 |
| P0-15 | Android 8 张 phone screenshots + feature_graphic 67B + icon Flutter logo | L 1-2d | GooglePlay P0-001/002/003 | 设计师出图 |
| P0-16 | chroniccare.app 域名 + 4 邮箱 ICP | XL 7-20d | AppStore P0-006 + GooglePlay P0-005 | 外部依赖 |
| P0-17 | AppIcon 1024×1024 10932B 偏小 | M 1d | AppStore P1-027 | 设计师重出 ≥ 200KB |

## P1 (16 项) / P2 (6 项) / P3 (11 项) 摘要

详细见 `00-FINAL-CONSOLIDATION.md` §3-4, 主要分类:

- **P1 跨期硬编码** (7 项): R11a medication_page 4 处硬编码中文 + 1 Colors.white + 1 新漏 IconButton 包装 / QuickMoodCarousel '心情' + '记录失败' / 48pt vs 72pt / lock-in test 阈值改回 250 / curveAppleSheet + curveAppleDrawer 死代码
- **P1 god class 反涨** (4 项): setup_page_state 513L (R108 506 → +7) / setup_step_medication 614L (R108 506 → +108) / medication_page 524L / 4 AppleHealthTile 横滚拆 controller
- **P1 重复实现** (1 项): _StreakCounter 跟 _TweenNumber 95% 重复抽 tween_number
- **P1 11 feature 描述虚标** (4 项): mood_list / daily_tracking / vent / crisis_hotline 0 改
- **P2 dev doc 同步** (6 项): AGENTS.md 缺 v0.31 章节 (本 README 修) / CHANGELOG 数字 stale (本 PR 修) / 跨平台 reproduce 留 v0.32 / spec baseline 数字矛盾 / PrimaryButton doc 注释硬编码 / R12b global sanity test 改 AST
- **P3 细节 polish** (11 项): CheckInButton fontWeight w700→w600 / PressFeedback haptics / `_StreakCounter` vs `_EntrySpring` 动画模式统一 / AppleListSection `toUpperCase` 对中文 no-op / SF Symbol 字体集成 / commit author 统一 / `_titleLetterSpacing` 抽 token / StatCard.xl 命名 / brand color 跨平台 / styles.xml SplashScreen / ...

## 6 大跨视角共识 issue (新引入)

| issue | 共识视角数 | 视角 | 难度 |
|---|---|---|---|
| spring.dart 死代码 (R4b 引入, R31 0 caller) | 3 | emil P0-E + superpowers-en P1 + Apple Health P0-3 | M 1-2h |
| 7 处 raw IconButton (R57 集中器未闭环) | 1 | emil P0-C | S 1h |
| spec baseline 数字矛盾 (2102/1/127 写但实际 2103/1/126) | 3 | emil + superpowers-zh + superpowers-en | S 5min |
| AGENTS.md 缺 v0.31 章节 (本 README 修) | 4 | superpowers-zh + superpowers-en + flutter-spec + Apple Health | S 1-2h |
| 设计文档 44KB untracked (`docs/design/2026-08-10-apple-health-redesign/`) | 1 | superpowers-zh P1-1 | S 5min |
| god class 反涨 (setup_page_state +108L, setup_step_medication +108L) | 1 | superpowers-zh | L 1-2d |

## 加权综合 6.2 → 7.5 对比

### 跟 R108 6.2/10 对比
- **视觉层**: 9.5/10 优秀 (4 token 集中器 + 6 widget + 5 page 重设 + 0 业务逻辑改动 + 0 跨 feature import + 跨平台 0 影响)
- **上架/合规层**: 0/10 跨期残留 (5 项硬阻塞 + 7 个新 bug, 0 闭环)
- **测试层**: 12/13 改写 commit 跟 test 同步 (TDD 实践度)
- **架构层**: 4 层架构 1:1 + 18 守门员全绿 + 8 FeatureFlag 状态稳定

### 6 大优势
1. 设计 token 集中化 (5 token 文件 + 1 facade) — R65 后最成熟
2. widget 集中化 (6 widget 文件) — Apple Health 视觉签名 95% 到位
3. 5 page 重设 (Home/Setup/Medication/Trend/Vent) — 用户主路径全覆盖
4. 0 业务逻辑改动 — 风险最低的 UI redesign
5. TDD 实践度 12/13 — 跟 test 同步比例行业领先
6. 0 跨 feature import violation — 4 层架构纯度维持

### 5 大劣势
1. 上架/合规层 0/10 跨期残留 (P0-01~17 累计 17 项上架硬阻塞)
2. spring.dart 死代码 (R4b 引入, 0 caller, R31 仍未接)
3. R108 P0 漏闭环 (P0-001 5 大上架 + P0-002 FadeIn 500ms + P1-001 7 IconButton + P1-003 硬编码)
4. god class 反涨 (setup_page_state +7, setup_step_medication +108, medication_page 4 AppleHealthTile 整合)
5. 11 feature 0 改 (mood_list/daily_tracking/vent/crisis_hotline 仍是旧 visual language)

## R109+ 路线图 (与 R108 路线图合并)

### Phase 1 R31 hotfix (1 周) — 闭环 17 P0 → 8.5/10
- **Day 1-2**: P0-01~07 上架/合规 (3.5h 总和) + P0-11 dart format (5min) + P0-12 设计文档入库 (5min)
- **Day 2-3**: P0-08 Spring 接 _EntrySpring (1-2h) + P0-09 lock-in test 扩 lib/**/*.dart (1h) + P0-10 PageScaffold translucent AppBar (1-2h)
- **Day 4-5**: P0-13/14/15 设计师协同 (fastlane 脚本跑 + 设计师出图), P0-16 域名 ICP 启动 (1-2 月异步)
- **预期**: 0.31.1 hotfix 出, 综合 8.5/10

### Phase 2 R109 (1-2 月) — 拆 god class + 抽公共 widget → 9.0/10
- P1-08/09 setup_page_state 513L + setup_step_medication 614L 拆 controller (3-4d)
- P1-12 tween_number 公共 widget (1-2h)
- P1-01~07 跨期硬编码修 (1-2h 总和)
- P1-13/14/15/16 11 feature 完整改写 (各 1-2d, 选 2-3 个高 ROI)
- P2-01/02/03/04/05 dev doc 同步 (3h 总和) — **本 PR 已修 P2-01 + P2-02**

### Phase 3 R110 (2-3 周) — feature-first 重构
- `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package
- 4 个 R108 §六 god class 候选: notification_service 417 / mood_audio_service 311 / app_database 494 / legal_page 460 (跟 medication/setup 拆解合并)
- SF Symbol 字体集成 + brand color 跨平台对齐
- 8 metric icon 跟 SF Symbol 一一对应

### Phase 4 v1.0 (2027-Q1) — 长期
- HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP 真接
- 5 token 集中器转 pub workspace 公共 package

## VERDICT

**v0.31.0 Apple Health 风格重设计 PASS (加权 7.5/10, R108 6.2 → +1.3)**。

**核心矛盾**: 视觉层 9.5/10 优秀 (4 token 集中器 + 6 widget + 5 page 重设 + 0 业务逻辑改动 + 0 跨 feature import + 跨平台 0 影响) — 但上架/合规层 0/10 跨期残留 (5 项硬阻塞 + 7 个新 bug) + 6 大跨视角共识 issue (spring 死代码 / 7 IconButton / spec 数字矛盾 / AGENTS.md 缺 / 设计文档 untracked / god class 反涨)。

**1 周闭环 17 P0 即可到 8.5/10**, R109 god class 专项后可到 9.0/10。

**不建议本批提交 hotfix**: 0.31.1 应专注 §2.1 上架/合规 7 项 (P0-01~07) + P0-11 dart format, 其他 10 P0 留 R109 第 1 周同步跑 (跟 god class 拆解合并, 避免单独 0.31.1 拆 commit 不连续)。

## 相关报告

- **R108 整合报告** (前次审视 baseline): `docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md` (16.7KB, 9 视角)
- **R108 9 视角 sub-report** (已合并入 R108-overall-report): `docs/audit-history/.../lens/` (2026-08-11 cleanup 删, 已合并归档)
- **R107 旧审视报告** (2026-08-10 cleanup 归档): `docs/audit-history/r107-cleanup-2026-08-10/` (9 视角, 9 报告)
- **R106 审视报告** (更早 baseline): `docs/audit-history/` 1.2MB 历史 26 份 (跨期 R107 归档)

## untracked 待入库 (R31 hotfix commit 时)

- `docs/audit/2026-08-11-cleanup/` 9 个文件 (本目录 79KB)
- `docs/design/2026-08-10-apple-health-redesign/` 3 个文件 (spec.md 22KB + plan.md 16KB + NEXT-SESSION-START-HERE.md 6KB, 合计 44KB)

建议下一条 commit: `0.31.1: 入库 8-11 cleanup 7 视角审视报告 (79KB) + Apple Health 设计文档 (44KB)`
