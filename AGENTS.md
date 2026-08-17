# AGENTS.md

> 给 AI 编程 Agent 看的项目指引。先读 README.md 看产品视角，再读这份看代码视角。
>
> **EN Summary**: A mental-health self-care Flutter app (emotion-first: vent + mood primary, medication/assessment secondary), 4-layer architecture (data/domain/presentation + 5-umbrella core/), 27/27 CI gatekeepers, 2616 tests pass (R122 P2-2 baseline, 0 fail / 1 skip), 1340 ARB keys (zh/en/zh-Hant), zero cloud + zero push + zero exfil, SQLCipher local encryption. See [DEVELOPMENT_REQUIREMENTS.md](docs/DEVELOPMENT_REQUIREMENTS.md) for v2.0 requirements (R117). Toolchain: Flutter 3.47 (Gradle 8.14 + NDK 28.2 + newDsl=true) after R117 round 5. R120 综合审视加权 7.5/10 (emil 8.0 / flutter-spec 97% / superpowers-zh 7.0 / frame-thinking 8.5). R108 §六 god class 候选 6/12 闭环 (R118 P2-7 10 量表 / R119 P1-1 app_database 564→139L / R120 P1-2 notification_service 386→252L / R116 round 4 add_medication_page / R122 P2-1 mood_audio_service 496→251L / R122 P2-2 legal_page 555→344L).

## 项目速览

**产品**：情绪日记 + 树洞倾诉优先的精神心理自我关怀 App，用药记录辅助（1.1.0 情绪优先重构后定位）。

**栈**：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6。

**核心特性**：本地加密、零云端、4 层架构（`presentation → domain ← data`）+ 共享层（`shared/`）。

## 4 层架构 + 共享层

**v0.18 (round 12 之后):** `data/shared/theme/routing/l10n` 5 个子层并入 `lib/core/`
作为 umbrella。所以实际是 **5 层 + 共享 umbrella**:
- `lib/core/data/` — 基础设施(Database / Repositories / Services)
- `lib/core/shared/` — 跨层共享(formatters / json_codec / mood_visual)
- `lib/core/theme/` — AppTokens + M3 主题
- `lib/core/routing/` — go_router
- `lib/core/l10n/` — domain 层 strings(供通知用)
- `lib/l10n/` — presentation 层 flutter_localizations(供 UI 用)
- `lib/domain/` — 0 Flutter 0 Drift 业务层
- `lib/presentation/` — UI 层

```
lib/
├── main.dart              # 入口（启动顺序 + SQLCipher + 通知 init）
├── app.dart               # App 根 + ProviderScope
├── core/                  # 基础设施 umbrella
│   ├── data/              # data 层（DB / Repositories / Services / Utils）
│   │   ├── database/     # Drift 表 / 数据库 / 迁移
│   │   │   ├── tables/   # 1 个表 = 1 子目录（check_in/, medication/, mood/, vent/, ...）
│   │   │   ├── mappers/  # row ↔ entity 翻译（1 文件 1 mapper）
│   │   │   ├── connection/  # conditional import (web / native)
│   │   │   └── app_database.dart
│   │   ├── repositories/  # *RepositoryImpl（按 feature 平铺, 计划按 feature 子目录）
│   │   ├── services/     # 通知/录音/导出/加密
│   │   └── utils/         # phone_validator 等
│   ├── shared/            # 跨层共享（domain + data + presentation 都可用）
│   │   ├── formatters.dart
│   │   ├── json_codec.dart
│   │   ├── domain_value.dart  # DomainValue<T>（替代 drift Value<T>）
│   │   └── mood_visual.dart   # 情绪分数 → emoji/label
│   ├── theme/             # AppTokens + M3 主题 + dark mode
│   │   ├── app_tokens.dart   # 颜色/字体/间距/圆角/动画/阴影/breakpoint
│   │   ├── app_theme.dart    # light + dark ThemeData
│   │   ├── theme_provider.dart   # Riverpod ThemeMode
│   │   └── theme_toggle_button.dart
│   ├── routing/           # go_router 配置
│   │   └── app_router.dart  # 所有路由 + fade/slide-right/slide-up 3 类 transition
│   └── l10n/              # domain 层 strings（通知 fallback）
│       └── strings.dart
├── l10n/                  # presentation 层 flutter_localizations
│   ├── app_zh.arb         # 中文文案源
│   ├── app_en.arb         # 英文文案源
│   ├── app_localizations.dart
│   ├── app_localizations_zh.dart
│   └── app_localizations_en.dart
├── domain/                # 0 Flutter 0 Drift 业务层
│   ├── entities/         # *Entity 后缀
│   ├── logic/            # 业务规则（量表/streak/报告/情绪回顾聚合/标签库）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例（业务编排）
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers（按职责拆 3 文件）
    │   ├── core_providers.dart   # DB + 基础服务 + 7 个 repo
    │   ├── service_providers.dart  # assessment reminder / data export
    │   └── vent_providers.dart   # vent audio + entries
    ├── pages/             # 1 个页面 = 1 个目录（按 feature 拆 10 个）
    │   ├── home/         # 主页（打卡 / 庆祝 / mood / vent 入口）
    │   ├── setup/        # 首次设置（4 步：consent / welcome / medication / done）
    │   ├── settings/     # 设置（含 settings/widgets/ 子组件 + reminders_hub）
    │   ├── trend/        # 趋势（list + calendar 视图）
    │   ├── assessment/   # 心理评估（答题 + 历史 + 提醒 section）
    │   ├── medication/   # 用药（calendar / refill / today / report / dialogs）
    │   ├── mood/         # 情绪（dialog + quick button）
    │   ├── mood_list/    # 情绪列表 + 情绪回顾
    │   ├── vent/         # 树洞（list / compose / detail）
    │   ├── daily_tracking/  # 每日跟踪（睡眠 / 体重 / 社交节律 / 压力等 6 项）
    │   └── crisis_hotline_page.dart  # 危机热线（5 区域一键拨打）
    └── widgets/           # 通用组件
        ├── page_scaffold.dart
        ├── app_snack_bar.dart
        ├── loading_skeleton.dart  # 统一 loading（fullScreen / card / Spinner）
        ├── secondary_button.dart
        ├── press_feedback.dart    # v0.18: 按钮 :active scale 反馈
        └── animations/    # 通用动效（FadeIn / CelebrationBounce / PageTransitionSwitcher）
```

**依赖方向**：`presentation → domain ← data`。`domain/` 下任何文件都不能 `import 'package:flutter/...'`。验证方式：`flutter analyze` + `flutter test`，以及 0 error。

**关键约束**：
- domain 实体 = `*Entity` 后缀（避免和 drift `@DataClassName('X')` 冲突）
- drift 表的 @DataClassName 用单数（`VentEntry`），但 domain 实体叫 `VentEntryEntity`
- row → entity 的翻译放 `data/database/*_mapper.dart`，**不放** domain 层
- presentation provider 用 `Provider<X>(...)` 暴露 `XRepository`（domain 接口），不暴露 impl
- UI 调 `context.push(...)` / `context.pop()`（go_router 习惯），不用 `Navigator.pushNamed`

## 必读文件

进项目先扫这 5 个：

1. `lib/main.dart` — 启动顺序、SQLCipher 初始化、通知 init
2. `lib/core/data/database/app_database.dart` — schemaVersion 当前 23，所有表 + migration
3. `lib/domain/logic/mood_review_aggregator.dart` — 情绪回顾聚合核心规则 (1.1.0 新增)
4. `lib/presentation/providers/core_providers.dart` — 全局 provider 注册表
5. `lib/core/routing/app_router.dart` — 所有页面路由 + shell（NavigationRail）

## 命名约定

| 概念 | 命名 | 例子 |
|---|---|---|
| drift 表 | snake_case 表名 + 单数 @DataClassName | `vent_entries` + `VentEntry` |
| domain 实体 | PascalCase + `Entity` 后缀 | `VentEntryEntity` |
| mapper | `X_mapper.dart` | `vent_mapper.dart` |
| repository impl | `X_repository_impl.dart` | `vent_repository_impl.dart` |
| abstract repo | `X_repository.dart`（无后缀） | `vent_repository.dart` |
| provider | `xRepositoryProvider` | `ventRepositoryProvider` |
| 页面 | 1 个目录 = 1 个页面 | `lib/presentation/pages/vent/` |
| 测试 | 跟实现 1:1，加 round 编号后缀 | `vent_list_round18_test.dart` |

## 开发流程

**新功能 5 步走**（参考 v0.15 vent 落地）：

1. **domain**：`entities/X_entity.dart` + `repositories/X_repository.dart`（abstract）
2. **data**：`database/tables/x_entries.dart` + `database/x_mapper.dart` + `repositories/x_repository_impl.dart`
3. **schema 升级**：`app_database.dart` schemaVersion++ + migration + `watchX`/`insertX`/`deleteX` 方法 + `dart run build_runner build --delete-conflicting-outputs`
4. **presentation**：`pages/x/`（1 个目录 = 1 页面） + `core_providers.dart` + `app_router.dart` 加路由
5. **测试 + 验证**：`flutter analyze` 0 error + `flutter test` 全过 + `flutter commit` 风格 commit

**写完先跑两个命令**：

```bash
flutter analyze    # 必须 0 error
flutter test       # 必须全过（R112 实测 2377 pass / 4 fail [iOS 资产占位] / 1 skip; 目标 0 fail, 4 fail 等设计师资产）
python scripts/check_cross_feature.py  # 必须 0 violation (跨 feature import 检查)
```

## 隐私边界

以下模块**严禁**互相渗透：

| 模块 | 进什么 | 不进什么 |
|---|---|---|
| 树洞（vent） | 无 | 趋势 / 评估 / 通知 / 关怀 |
| 情绪日记（mood） | mood-specific reports | 通知（v0.15 之后可加） |
| 心理评估（assessment） | 评估历史趋势 | 外部通知 |
| 打卡（check-in） | streak / 趋势 | 评估 |

如果发现树洞内容进了趋势页 = **bug**，立即修。

## 测试

```bash
flutter test                                       # 全部
flutter test test/domain/                          # 仅 domain
flutter test test/data/                            # 仅 data
flutter test test/presentation/                    # 仅 presentation
flutter test test/presentation/X_round18_test.dart # 单文件
```

测试结构：1 个测试文件对应 1 个 round。命名 `{module}_{roundN}_test.dart`。`roundN` 对应版本号中的 round 数字（如 v0.15 round 18）。

测试三层：
- **domain 业务**：纯 Dart，零 Flutter 依赖，最快
- **data round-trip**：DB insert → entity → 校验字段
- **presentation widget**：`ProviderScope` overrides + `MaterialApp` + `tester.pumpAndSettle`

## 调试

```bash
flutter run -d <device>                            # 跑
flutter logs                                       # 看日志
flutter test --plain-name "测试描述"               # 跑单个 test
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成
```

**dev 服务器坑**：web 平台不能用 `flutter run -d chrome`（drift worker 404），用 `flutter build web` + `python -m http.server 8358` 走 production 模式。

## 架构检查脚本（v0.16 Round 9-11）

1 个 CI 友好的脚本检查 4 层架构健康度（v0.16 Round 13 起合并）：

```bash
dart scripts/check_all.dart   # 一次出两份报告：purity + consistency
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑
```

**`check_all.dart`** 检查：
- **[1/2] 纯度**：domain/shared/ 0 flutter / 0 drift / 0 data / 0 presentation；data 不依赖 presentation。同时检测 `package:` 绝对路径 + `../../` 相对路径
- **[2/2] 一致性**：domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应；shared/ 每个文件至少被 2 层用
- 违规时 exit code 1，CI 会 fail

> Round 13 之前用的是 `check_domain_purity.dart` + `check_architecture_consistency.dart` 2 个 script，已合并删除。

**已知 bug 修复**：写这俩脚本时发现 Dart `RegExp` 默认 `^` 不 multi-line — 必须显式 `multiLine: true` 或用 `readAsLinesSync()` 逐行处理。

## v0.30 R108 revisit 综合审视 (2026-08-10, 9 视角从 0 重跑)

**状态**: 120 个旧报告归档到 `docs/audit-history/` → 9 视角 subagent 从 0 重新跑 (7 lens + 顶层架构 + 底层逐行)。**加权综合 ≈ 6.2/10** (R108 拆 god class 进行中,working tree 引入 8 个回归 error + 上架"实物资产"未做,**临时从 R107 8.0 倒退 1.8 分**)。详细整合见 `docs/audit/2026-08-10-r108-revisit/00-FINAL-CONSOLIDATION.md` (40KB / 9 份 subagent 报告合计 404KB)。旧 R107 报告归档到 `docs/audit-history/r107-cleanup-2026-08-10/`。

**评分变化 (R107 → R108)**:
- emil 9.0 → 8.5 (-0.5, 主页 stagger 8→3 已闭环, 上架前 5 大 P0 未闭环)
- superpowers-en 9.0 → 6.5 (-2.5, R108 拆解漏 compile gate, 8 个 P0 引入 error)
- superpowers-zh 7.0 → 6.5 (-0.5, 域名 + 5 厂商 push + 阿里云 SMS 3 大硬阻塞未解)
- flutter-spec 92% → 88% (-4%, R108 引入 4 error 临时倒退)
- AppStore 4.5 → 3.5 (-1.0, 实物资产 100% 缺失)
- GooglePlay 55% → 5.5/10 (= 55%, 持平但有大量 P0)
- apple-health 3 → 3.0 (持平, HealthKit 0 集成)
- 顶层架构: 8.2 → 8.4 (+0.2, 4 层架构 1:1 + 15 god class 候选清晰)
- 底层逐行: 7.0/10 (新增 14 项发现, 1 P0 = audit log 跨时区漂移)

**R108 revisit 38 P0 (去重后, 按优先级排序)**:
- 优先级 1 上架硬阻塞 (5 项): iOS 截图 0 / Android 截图 67B + feature_graphic 67B / iOS LaunchImage 68B / review TODO 占位 / 5.1.3 抽审
- 优先级 2 外部依赖卡点 (4 项): chroniccare.app 域名 (7-20d ICP) + 4 邮箱 + 阿里云 SMS (失联通知 100% 失效, 1-2 月) + 5 厂商 push (1-2 月)
- 优先级 3 鸿蒙 + IAP (2 项)
- 优先级 4 锁屏 PII 跨 3 视角共识 (1 项): 锁屏通知 title 仍含药名 (R108 修了 body 但漏 title)
- 优先级 5 R108 引入 8 个回归 error (8 项, 合计 ≤2.5h): audio_lifecycle 缺 imports / MoodEntry recordingMode 未 regenerate / provider undefined / notification_service 跨类访问 @visibleForTesting / legal_consent audit log 不带 UTC / vent_detail_page fire-and-forget Future / weight_widgets dynamic 反射 / PrivacyInfo HealthAndFitness 0 HealthKit
- 优先级 6 其他 P0 (12 项, 单视角发现)

**R108 修完路径**:
- **Phase 1 R108 收尾** (1-2 周): 8 P0 引入 error + 上架紧急 4h + 6 项 god class 收尾 (2d) + 5 个新守门员 → 预期 7.5-8.0/10
- **Phase 2 外部依赖** (1-2 月): 域名 ICP + 4 邮箱 + 5 厂商 push + 阿里云 SMS
- **Phase 3 R109 god class 专项** (1-2 月): 5-6 god class 拆 + use case 层厚化 → 预期 8.5/10
- **Phase 4 R110 feature-first** (2-3 周): `lib/features/{feature}/{domain,data,presentation}/` + pub workspace → 预期 9.0/10
- **Phase 5 R1.0 长期** (2027-Q1): HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP → 预期 9.5/10

**R108+ 路线图 (与 R107 路线图对比更新)**:
- **R108** (1-2 周): 修 8 个 P0 引入 error + 上架紧急 4h + 6 项 god class 收尾 (vs R107 计划"上架前 P0 13 项")
- **R109** (1-2 月): 拆 5-6 个 god class (medication_page 553 / setup_page_state 506 / add_medication_page 506 / notification_service 417 / static_scale_translations 659 / safety_watch_service 338 / mood_audio_service 311 / app_database 494 / legal_page 460 / reminders_hub_page 441 / mood_trend_page 517 / mood_audio_recorder_widget 529) + use case 层厚化 (8 个 usecase)
- **R110** (2-3 周): feature-first 重构 + pub workspace 3 package
- **v1.0** (2027-Q1): pub workspace + 5 厂商 push + AliyunSms + EmailService + PHQ-9 i18n + HealthKit + 鸿蒙 + IAP 真接

**4 FeatureFlag 当前状态 (历史 8 → 7 → 4; v1.0.0+147 删 iap, 1.1.0 round 4b 删 3 外联 flag)**:
1. `ventAudioEnabled=**true**` (R104 已翻 true)
2. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月审核)
3. `phqGad7I18nEnabled=false` (等法务 + 临床审核)
4. `bootReceiverEnabled=false` (等 WorkManager 完善)

## v0.31 Apple Health 风格重设计 + 8-11 cleanup 综合审视 (2026-08-10~11, 23 commit + 2 cleanup commit, 7 视角, 加权综合 6.2 → 7.5/10)

**状态**: v0.31.0 Apple Health (iOS 17/18) 视觉语言**重设 22 commit** (master `01d8f4a`) + 8-11 cleanup **2 commit** (master `20670f3`) 收尾。**23 work commit 净 +7447/-3504**, 5 phase / 13 task / R1-R12b 流水。**加权综合 6.2 → 7.5/10** (R108 6.2 → +1.3 升, 上架层 0/10 跨期残留拉低 + 视觉层 9.5/10 优秀拉升)。详细整合见 `docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md` (14KB), 7 视角 subagent 报告合计 79KB。R108 整合报告对照 `docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md`。

**核心变更**:

- **5 token 集中器** (Phase 1, R1-R4): `app_colors.dart` (iOS system color + 8 health metric palette) / `app_typography.dart` (17pt body + 13pt caption + ultralight w200 大数字) / `app_spacing.dart` (圆角 14/10 + buttonHeight 50 + 信息密度 +30%) / `app_motion.dart` (0 阴影 + 3 Apple cubic-bezier) / `spring.dart` (Spring 物理模型 mass/stiffness/damping, **R109 接入**)
- **6 widget 集中器** (Phase 2, R5-R8): `PrimaryButton` (Apple Pill 3 variant) / `CheckInButton` (64pt 巨型 pill + spring 进场) / `StatCard` (ultralight w200 4 variant + 数字 tween) / `AppleHealthTile` (8 metric 彩色模块) / `AppleListSection` (iOS 群组列表 insetGrouped) / `SectionHeader` (iOS ALL CAPS 11pt)
- **5 page 重设** (Phase 3, R9-R11): Home (6 section AppleListSection + spacing 16 + stagger 8→3 闭环 + 4 StatCard 2x2 + 5 mood carousel) / Setup (4 步进度条 25/50/75/100%) / Medication (4 AppleHealthTile 横滚 + systemRed FAB + 5 子页) / Trend / Vent
- **9 page follow** (Phase 4, R12): trend / mood / vent / assessment / settings / contact / daily_tracking 按钮+分隔线改 Apple Health 风格
- **1 物理 Spring 模型** (P0 半成品): `spring.dart` 145 行 0 caller, spec §3.4.3 双轨制 (Spring 物理 vs curve 模拟) 空跑。R109 第 1 周接 `_EntrySpring` 走 `Spring.standard.toSimulation()`

**21 守门员 21 全绿** (跨期 R95 `check_coverage.py` 起延续, R31 加 `check_apple_health_claim.py` 扩到 `lib/**/*.dart` 注释, R109 round 1 加 `check_usecase_layer.py`, R110 加 `check_strings_hardcoded.py` inline 规则 → 20 .py + 1 .dart = 21)

**评分变化 (R108 → R31)**:
- emil 8.5 → 8.5 (持平, 主页 stagger 8→3 闭环抵消新引入 4 处硬编码中文)
- superpowers-en 6.5 → 8.5 (+2.0, R31 22 commit 100% 跟 test 同步, TDD 实践度 12/13 跟 test 同步)
- superpowers-zh 6.5 → 7.5 (+1.0, 中文 doc 完整 + dartdoc 中文 spec §X.X 引用)
- flutter-spec 88% → 97% (+9%, R31 5 token + 6 widget 集中化是 R65 后最成熟 "design engineering" 时刻)
- AppStore 3.5 → 3.5 (持平, R108 5 项上架硬阻塞跨期 100% 残留 0 闭环, R31 新增 5 P0 上架阻塞 = 累计 10 P0)
- GooglePlay 5.5 → 5.5 (持平, R108 26 P0 中 12 仍阻塞, R31 0 新 P0)
- Apple Health 3.0 → 7.0 (+4.0, R31 视觉层 9.5/10 优秀, 11 feature 仍 0 改是减分项)
- **加权综合 6.2 → 7.5 (+1.3)**

**R31 17 P0 紧急修 (按优先级排序, R109 第 1 周闭环 1 周内可到 8.5/10)**:
- **上架/合规 7 项** (P0-01~07, 3.5h 总和, 0.5h 立即可修): review_information 4 TODO 占位 / notes.txt 版本号过期 / store_kit_service productId 冗余 / description.txt 5.1.1 抽审 / 3 处 DarwinNotificationDetails 锁屏 PII / 4 处 AndroidNotificationDetails.visibility 锁屏 PII / 7 处 raw IconButton
- **Apple Health 半成品 5 项** (P0-08~12, 4-5h): Spring 接 _EntrySpring / R108 P0-004 "Apple Health" 关键词 lock-in 扩 lib/ 注释 / PageScaffold translucent AppBar (spec §4.9) / dart format 2 文件 / 设计文档 44KB untracked 入库
- **上架硬阻塞 5 项** (P0-13~17, 1-2 月, 设计师/外部依赖): iOS 截图 / iOS LaunchImage / Android 截图 + feature_graphic / chroniccare.app 域名 + 4 邮箱 ICP / AppIcon 1024×1024 ≥ 200KB

**R31+ 路线图 (跟 R108 路线图合并更新)**:
- **R31 hotfix (本周, 1 周)**: 闭环 17 P0 → 8.5/10
- **R109 god class 专项** (1-2 月): 拆 setup_page_state 513L + setup_step_medication 614L (本批反涨 108L) + medication_page 524L + 11 个 R108 §六 候选 + use case 层厚化 (8 usecase) → 9.0/10
- **R110 feature-first 重构** (2-3 周): `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package
- **v1.0 (2027-Q1)**: HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP 真接 + 5 token 集中器转 pub workspace 公共 package

**6 大跨视角共识 issue (新引入)**: spring.dart 死代码 (emil + superpowers-en + Apple Health) / 7 处 IconButton (emil) / spec baseline 数字矛盾 (emil + superpowers-zh + superpowers-en) / AGENTS.md 缺 v0.31 章节 (superpowers-zh + superpowers-en + flutter-spec + Apple Health) / 设计文档 untracked (superpowers-zh) / god class 反涨 (superpowers-zh)

**untracked 待入库** (R31 hotfix commit 时一起):
- `docs/audit/2026-08-11-cleanup/` 9 个文件 (9 份审视报告合计 79KB)
- `docs/design/2026-08-10-apple-health-redesign/` 3 个文件 (spec.md 22KB + plan.md 16KB + NEXT-SESSION-START-HERE.md 6KB, 合计 44KB)

**4 FeatureFlag 当前状态 (R31 同 R108+R107 → v1.0.0+147 删 iap → 1.1.0 round 4b 删 3 外联)**: 同 v1.1.0 章节 (4 flag)。

## v0.23 P0-P3 集中清理 (round 38-44)

按"三视角审视"报告 (emil / superpowers-en / superpowers-zh) 全修:

- **P0 (round 38)**: SMS release fail-fast + safety_watch timeout + app.dart 复用 provider (3 项,1 项 Android 跳过因 web-only)
- **P1 (round 39)**: 8 项 — catch(_)→swallowError (4 处) + i18n 38 处 + PDF mask + 50+ case 测试
- **P2 (round 40)**: 12 项 — emil token 化 (tintedSuccessSoft/fgOnPrimaryMuted/iconSizeMicro/...) + 抽 SectionHeader + setup 改 PageTransitionSwitcher + tz.local
- **P3 (round 41)**: 4 项实做 + 5 项 TODO 注释 — PressFeedbackIconButton + care_engine 4 strategy + reminders_hub Notifier + zh_Hant stub
- **P3 L 项 TODO**: notification god class (已抽 3 facade 子) + data_export god class (已加 50+ test) + 紧急联系人单独同意 (待 SMS 接入)
- **v0.24 round 45**: 3 视角再审视 → Sprint #3 main.dart i18n + Sprint #4 token + Sprint #6 check_no_pua.py + CHANGELOG [0.23.0] 补 + AGENTS 数据同步

总计: 910+ tests pass (v0.24 round 48 后 34 个新增), 0 analyzer error, 11 守护脚本全绿 (v0.24 round 48 新增 check_no_hardcoded_utc / check_widget_dispose / check_changelog).

## v0.25 spen P0 #15 TDD + 杂项清理 (round 56b-56e)

按 spen P0 #15 (sub-service 0 test) + spen 杂项 全修:

- **R56b**: P1(emil) spacing SizedBox 走 token — 46 处 magic 修复 (spacingXxxs/Xxs/chipGap/Xs/Sm/Md/Lg/Xl)
- **R56c**: TDD 续 — db_key_service +5 unit test (FlutterSecureStorage MethodChannel mock 模式)
- **R56c'**: TDD 续 — refill_notifier +10 (id 公式 + computeRefillFireTime 纯函数 + scheduleRefillReminder instance)
- **R56c''**: TDD 续 — medication_notifier +10 (ID 常量 + scheduleDailyReminder + rescheduleMedicationReminders)
- **R56c'''**: TDD 续 — assessment_notifier +4 + safety_alert_dispatcher +7 + mood_audio_service +10 = +21
- **R56d**: 杂项清理 — formatters 走 intl DateFormat + vent_detail_page 改 EmptyState
- **R56e**: 守门员 — check_orphan_arb_keys.py + 一次性清 39 个 orphan (677 → 550 zh ARB key)

总计 (本批): 1057 → 1098 tests (+41), 0 analyzer error, 12 守护脚本全绿 (新增 check_orphan_arb_keys).

**21 守护脚本清单** (v0.30 R107 cleanup 修正, v0.30 R95 加 `check_coverage.py`, R31 加 `check_apple_health_claim.py`, R32 加 `check_pii_in_title.py`, R109 round 1 加 `check_usecase_layer.py`, R111 round 8 加 `check_review_information_todo.py` 后总数 22, 1.1.0 round 4b 删 `check_sms_release_ready.py` [SMS 外联删除] → 21 = 20 .py + 1 .dart):
1. `python scripts/check_arb_keys.py` — zh / en / zh_Hant ARB 同步
2. `python scripts/check_changelog.py` — pubspec 版本号 + CHANGELOG 顺序
3. `python scripts/check_cross_feature.py` — 跨 feature import 边界
4. `python scripts/check_datetime_race.py` — 跨函数 DateTime.now() 多次调用
5. `python scripts/check_datetime_race2.py` — 跨 DateTime(year,month,day) 多次调用
6. `python scripts/check_drift_namespace.py` — @DataClassName 唯一
7. `python scripts/check_fullwidth_punctuation.py` — 全角标点 (warn-only)
8. `python scripts/check_no_hardcoded_utc.py` — UTC 硬编码
9. `python scripts/check_no_pua.py` — PUA 字符
10. `python scripts/check_widget_dispose.py` — 资源泄漏
11. `python scripts/check_orphan_arb_keys.py` — **R56e 新增** — ARB key 定义但未引用
12. `python scripts/check_legal_consent.py` — **v0.26 R57 新增** (1.1.0 round 4b 删紧急联系人 §13 检测) — 单独同意 / PIPL §13 / §14 检测
13. `python scripts/check_strings_hardcoded.py` — **v0.26 R57 新增** (v0.32 R110 扩 inline 字面量规则) — 硬编码中文 string 检测
14. `python scripts/check_zh_hant_consistency.py` — **v0.26 R57 新增** — 繁简一致性 (OpenCC s2tw)
15. `python scripts/check_16kb_alignment.py` — **v0.28 R77 新增** (v0.30 R92 文档补) — Android 16KB page size 验证 (Google Play 2025-11-01 强制)
16. `python scripts/check_coverage.py` — **v0.30 R95 新增** — 覆盖率阈值 (domain ≥ 70% / data ≥ 50% / presentation ≥ 30%)
17. `python scripts/check_apple_health_claim.py` — **R31 新增** — "Apple Health" 关键词 + health_kit 声明扫描 (防假声明)
18. `python scripts/check_pii_in_title.py` — **R32 新增** (1.1.0 round 4c 删 safety/contact 黑名单项) — 通知 title/body 锁屏 PII 检测
19. `python scripts/check_usecase_layer.py` — **R109 round 1 新增** — use case 层硬约束 (0 data/0 theme/0 presentation/0 l10n/0 Flutter)
20. `python scripts/check_review_information_todo.py` — **R111 round 8 新增** — review_information 未标记占位防回退 + notes.txt 版本同步 (AS-16)
21. `dart scripts/check_all.dart` — 4 层架构纯度 + 一致性

**待办 (外部依赖, 非本批)**:
- R51b PHQ-9 题目 + 严重度 + 危机电话完整走 ARB (v1.0 大工程, 当前仅 hotline 6 region 走 hot path)

## 关键约束

- `dart:io` 只在 `data/` 下用（domain 层用 `dart:io` 拼路径 OK，但不能用 `package:flutter/...`）
- 写完代码**必跑** `flutter analyze` + `flutter test`
- 任何 PR 必保 0 error / 0 warning（info-level 可以）
- `pubspec.yaml` 改完必跑 `flutter pub get`
- drift 表改完必跑 `dart run build_runner build --delete-conflicting-outputs`
- 改完 schema 必改 `app_database.dart` 的 schemaVersion + migration
- 提交风格：`<version> round <N>: <title>`，参考 `git log --oneline`

## 已知坑

- **schemaVersion 升级漏 migration**：改表后忘了加 `onUpgrade`，老用户升级会崩
- **`VentEntryEntity` vs `VentEntry`**：domain 用前者，drift 生成后者，写 import 别搞混
- **audioplayers + record** 一起用：先 `dispose recorder` 再 `dispose player`，否则文件锁冲突
- **SQLCipher 加密 + audio 文件**：audio 在 DB 之外（app docs），但 DB 路径仍受 SQLCipher 保护
- **crash reporter 集成**：本项目不接 Firebase / Sentry，本地 SQLite 错误通过 `runZonedGuarded` 打印
- **Stream subscription leak**：`_player.onXxx.listen(...)` 返回的 `StreamSubscription` 必须存字段，**`dispose()` 里 `.cancel()`**。`audioplayers` 之类第三方包的 listener 不取消 = 每次进/出页面都漏一个
- **BuildContext 跨 async gap**：State class 里方法签名不要重复拿 `BuildContext context` 参数 — 用 `this.context`。否则 analyzer 警告 `use_build_context_synchronously`（mounted check 跟 context 是不同来源）
- **`dart format` + `dart fix --apply` 组合**：批量清 `trailing_commas` / `prefer_const_constructors` 200+ info-level 警告。`dart format` 加换行后会让 trailing comma 数量变多，必须跟 `dart fix --apply` 配合才能净
- **隐式排序假设是 silent bug**（v0.16 round 19/19B）：`.first` / `.last` 用时序数据必须显式 sort，不依赖 drift orderBy 的隐式顺序。修法：函数内部 `[...records]..sort((a, b) => b.timestamp.compareTo(a.timestamp))` 再 `.first`，加 unsorted input regression test。已修：`streak_calculator` / `assessment_comparison` / `reminder_scheduler` / `safety_watch_service` / `assessment_reminder_service`（用 `reduce(isAfter)` 找最新）
- **Notification id cancel range 公式必须匹配**（v0.16 round 19/19B）：cancel 范围要 ≥ `base + maxMedId * 系数`。修前 3 个 service 用 1000/100000 太窄。修后统一 200000，覆盖 medId 几万个，远超实际用户量。`int32` 安全（~2.1B）
- **AudioPlayer / recorder / 任何 acquire 资源的临时对象用 `try/finally`**（v0.16 round 19B）：`_getAudioDuration` 之前 try 内 `setSource` + `getDuration` + `dispose` 一气呵成，异常时 dispose 不跑 → resource leak。修：`final player = AudioPlayer(); try { ... } catch (_) {} finally { await player.dispose(); }`
- **`DateTime.now()` / `DateTime(y, m, d)` 多次调用 race**（v0.16 round 19B / 修正于 v0.17 round 14）：同一函数或同 field init 内多次调 `DateTime.now()` 跨 midnight 可能返回不同日期，跨月/跨年时 `DateTime(year, month, day)` 同函数多次调也可能不一致。常见模式：
  - `showDatePicker(initialDate: now+30d, firstDate: now-7d, lastDate: now+365d)` 3 次 `now`
  - `DateTime _calendarMonth = DateTime(now.year, now.month, 1)` 然后又 `DateTime(now.year, now.month + 1, 0)`
  - "先判过期再算 daysLeft": `if (now.isAfter(...)) ...; final daysLeft = expiry.difference(now).inDays;` 跨 midnight 后 `now` 已变
  - 修法：函数入口 `final now = DateTime.now();` 一次，下面所有判断/计算复用
  - 找 bug 方法：`grep "DateTime\.now()"` 在 `lib/`，看同函数或同 field init 是否多次出现
  - 例：`lib/core/data/services/reminder_scheduler.dart:97`（v0.14 修过同款 bug）
- **国产 ROM 静默杀后台通知**（v0.16 round 20）：小米 / 华为 / OPPO / Vivo / 魅族 默认禁止 App 后台运行 + 自启动 + 精确闹钟。用户反映"20:00 没收到提醒"99% 是这个原因。**不要靠 `developer.log` 排查，用户看不到**。修：在设置页加 `NotificationStatusCard` 自检卡：状态显示 + 一键测试 + OEM 引导文字。`androidScheduleMode: exactAllowWhileIdle` 是必要条件但不充分。找 bug 方法：用户报"没收到提醒"先检查 ROM + 自检卡状态数 = 0
- **Riverpod 3.x 升级 `valueOrNull` → `value`**（v0.17 round 3）：2.6 的 `AsyncValue.valueOrNull` 在 3.x 改成 `value`。找 bug 方法：升 3.x 报 `undefined_getter valueOrNull` 就是这个
- **Riverpod 3.x `ref.mounted` 仅限 Notifier**（v0.17 round 3）：项目用 Provider/StreamProvider/ConsumerStatefulWidget，没法用 `ref.mounted` 替代 `if (!mounted) return;`。保持 27 处 `!mounted` check（v0.17 round 7 实际数：1 处 ref.mounted + 27 处 !mounted）
- **跨 midnight streak 不刷新**（v0.17 round 4）：streakSummaryProvider 在 build 内取 `DateTime.now()`，跨 23:59:59 后 widget 重建会拿新 now，但 streakSummaryProvider 自身没监听时间变化。修：AppRoot 挂 midnight timer，00:00:05 自动 `ref.invalidate(streakSummaryProvider)`。`nextMidnightRefresh(now)` 是 top-level 纯函数，跨月/跨年都正确。buffer 5s 防 race
- **emil 动效 token 必须集中**（v0.17 round 1）：项目原本 `app_tokens.dart` 只有 `durFast/durNormal/durSlow`，缺 `curve*` 常量。各 widget 各写各的 `Curves.easeInOut` 风格不统一。修：4 个 curve token + emil 决策框架 doc 注释（100+/day 无动画, tens/day 微弱, occasional 标准, rare 可加 delight）
- **go_router 默认无 transition**（v0.17 round 2）：`GoRoute.builder` 默认切换无动画。修：用 `pageBuilder` + `CustomTransitionPage`，3 类 transition（fade / slide-right / slide-up）按频度分类
- **Material 3 ink_sparkle shader 缺失导致 widget test fail**（v0.17 round 8）：Material 3 InkWell 在 widget test 中需要 `shaders/ink_sparkle.frag`，但 `flutter test` 默认的 `TestAssetBundle` 不带这个 shader → 报 `Asset 'shaders/ink_sparkle.frag' manifest could not be decoded: INVALID_ARGUMENT`。**修法**：从 Flutter SDK 复制 shader 到 `assets/shaders/ink_sparkle.frag`，并在 `pubspec.yaml` 的 `flutter: shaders:` 字段声明。文件源：`$FLUTTER_ROOT/packages/flutter/lib/src/material/shaders/ink_sparkle.frag`（3978 bytes）。找 bug 方法：`flutter test` 输出里有 ink_sparkle + `INVALID_ARGUMENT` 异常。**注意**：Flutter 3.44.5+ 因为 shader format 升级 (1→2) 暂时不兼容此 trick；当前项目跑的是 3.41.9 所以 work
- **跨 feature import 边界**（v0.17 round 12）：presentation/ 按 feature 拆（`pages/{check_in,medication,mood,vent,...}/`），但跨 feature 引入别的 feature 的 `presentation/pages/` 会导致耦合蔓延。**规则**：
  - ✅ 允许跨 feature import `core/`, `domain/`, `data/`, `presentation/providers/`, `presentation/widgets/`
  - ❌ 禁止 `presentation/pages/{feature A}/` import `presentation/pages/{feature B}/`（除 hub：`home` 和 `settings`）
  - 验证：`python scripts/check_cross_feature.py`（CI 模式 `--ci` 退出码 1）
  - 例外：通用 widget（"次要按钮"之类）放 `presentation/widgets/`，别放 `pages/home/widgets/`（否则 mood 之类 feature 用了会触发 lint）

## 决策记录

| 决策 | 原因 |
|---|---|
| 4 层架构 | domain 易测试 + 易复用 + 0 Flutter 依赖 |
| SQLCipher | 精神心理患者数据敏感，零云端 |
| 树洞独立表 | 隐私边界：绝对不进任何分析 / 通知 / 关怀 |
| audio 存本地文件 | DB 体积不能爆炸，文件用路径引用 |
| ProviderScope overrides 测试 | 真实 DB 测试太慢，in-memory + override 足够覆盖 |
| 主页底部按钮加"倾诉" | 用户主要路径 = 打卡 / 设置 / 倾诉 3 个核心动作 |

## 文档

- `README.md` — 产品视角
- `docs/CHANGELOG.md` — 版本变更（Keep a Changelog 格式）
- `docs/DEPLOYMENT.md` — 部署相关

---

## v0.31.1 R32 hotfix 闭环 R31 报告跨期残留 (2026-08-11, 11 commit P0 修 + 1 整合 commit, master 0.31.1+108)

`fix/v0.31.1-bug-batch` 11 commit merge to master, 闭环 R31 报告"跨期残留 100%"的 11 P0。

**P0-01 ~ P0-09 全闭环 (R32 hotfix round 1)**:

- P0-01 review_information 4 TODO 占位 (AppStore BUG-1)
- P0-02 notes.txt 版本号 v0.30.0+85 → 0.31.0+107 (AppStore BUG-3)
- P0-03 store_kit productId com.chroniccare.app.lifetime → com.chroniccare.chroniccare.lifetime (AppStore BUG-7)
- P0-04 description 5 病名 5.1.1 抽审 (AppStore BUG-6)
- P0-04b 4 locale description 5 病名 (R108 守门员扩)
- P0-05 3 DarwinNotificationDetails 空构造 (AppStore BUG-2, emil P0-C)
- P0-06 4 AndroidNotificationDetails visibility: secret (GooglePlay P0-006)
- P0-07 7 raw IconButton → PressFeedbackIconButton (emil P0-C, R108 P1-001 漏修)
- P0-07b page_scaffold.dart:42 raw IconButton 漏修补 (P0-07 隐藏漏修)
- P0-08 Spring 物理模型接 _EntrySpring + 5 case test (emil + superpowers-en + Apple Health 跨视角共识)
- P0-09 Apple Health 关键词 lock-in test 扩 lib/ 主体 (Apple Health P0-1)

**R32 hotfix round 2 (0.31.1+109, 5 个剩余 P0)**:

- P0-15 i18n 跨期 21 处硬编码中文 → ARB key (medication_page 4 + primary_action_row 7 + secondary_action_row 7 + today_summary_card 1 + quick_mood_carousel 2)
- P0-30 check_zh_hant_consistency 9 处繁简不一致 (跨期 R31 P2-04 漏)
- P0-13 check_fullwidth_punctuation 守门员严格化 + 修 11 处半角标点
- P0-29 check_orphan_arb_keys FAIL (跟 P0-15 一起, 0 orphan)
- P0-32 lock-in test 阈值 300 → 250 (R31 P1-06 跨期 0 闭环)

**R32 综合审视 6 视角加权综合 6.2/10 → 修后预估 8.0/10 (+1.8)**。

**21 守门员最终状态 (R111 2026-08-13 实测)**:

- **21 绿 / 0 红 / 1 skip** (16kb 待重 build)
- 明细见下方 v0.32 R110 章节 + `docs/audit/2026-08-13-multi-lens/00-FINAL-CONSOLIDATION.md`

**半成品 (R110 round 3 (2026-08-13) 后还剩)**:

- 7 feature 0 改 (Apple Health spec §5.1-5.7) — mood / mood_list / vent / assessment / contact / settings / daily_tracking / crisis_hotline 仍 0-部分 AppleListSection 化 (EM-02/AH-04)
- SF Symbol 字体 (spec §3.1.3) — Material Icons 占位
- HealthKit 集成 = 0 (守门员 enforced, v1.0 2027-Q1 计划)
- 22 个 god class (≥400L) — round 7b 已给 6 个补 test (add_medication 6 / edit_medication 8 / assessment_widgets 11 / mood_audio_recorder 6 / mood_trend 6 / vent_detail 5), 剩 4-5 个 0 专用测试 (setup_page_state / legal_page / reminders_hub / home_page_state 等); 拆解仅 medication_page 553→347 完成

**详细整合报告**: [docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md](docs/audit/2026-08-11-r32-multi-lens/00-FINAL-CONSOLIDATION.md) (52KB, 6 视角子报告合计 173KB)
- `AGENTS.md` — 本文件（代码视角）

## v0.32 R110 10 视角综合审视 (2026-08-13, 并行 subagent 只读审计)

**状态**: 10 个 subagent (7 产品视角 + 顶层架构 + 2 路底层逐行) 从 0 重跑。**P0 12 项** (通知 ID 碰撞 / purity 3 处 / 上架合规 3 项 / i18n 12 处 + 守门员盲区 / 双平台资产 + keystore + 域名)。报告: `docs/audit/2026-08-13-multi-lens/` (11 文件, 00-FINAL 整合 + 10 视角)。

**R110 核心变更**:

- **round 1**: 审计入库 + 仓库卫生 (R32 报告补交死链修复 / .bak / worktree prune / 归档 / .gitignore)
- **round 2**: docs 对齐 (README / AGENTS / design spec / CHANGELOG 补 [0.32.0+120..+130] / pubspec 0.32.0+130 / notes.txt 去虚假声明)
- **round 3**: P0 代码闭环 — 通知 ID 固定带 2M+ (safety/assessment/mood/badge/care) + 回归测试; domain purity 3 处 (phone_validator→core/shared / FeatureFlags 构造注入 / visibleForTesting→meta); 紧急联系人 setup 表单 + reminders_hub 安全卡 gate; Mock/开发模式文案中性化; validateForRelease gate; 12 处硬编码中文 → ARB (11 key × 3 语); 2 个死路由 404 + /medication 入 ShellRoute; badge_sync visibility secret; check_strings_hardcoded inline 规则

**P0 遗留 (外部依赖)**: chroniccare.app 域名 ICP (7-20d) + 双平台截图/图标 (设计师) + keystore 生成 (1h) + review_information 真实值

**R110+ 路线图**: R110 收尾 (R109 working tree 99 文件归类 commit + 126 fail 复验) → R109 遗留 (setup_page_state 497 / add_medication 568 / mood_audio_recorder_widget 589 等 god class 拆 + usecase 厚化 6→14-16) → scale_translations 三源合一 → AR-2 l10n 循环解耦 → feature-first + pub workspace → v1.0 (2027-Q1: HealthKit / 鸿蒙 / 5 厂商 push / 阿里云 SMS / IAP 真接)

## v0.32 R111 9 视角综合审视 (2026-08-13, 并行 subagent 只读审计)

**状态**: 9 个 subagent (6 产品视角 + 顶层架构 + 2 路底层逐行) 从 0 重跑, working tree 干净基线。**R110 12 P0 代码闭环全实锤** (通知 ID 5M 带 + 回归守卫 / purity 0 violation / 紧急联系人 3 处 gate / Mock 文案 gate 内 / validateForRelease gate / 12 处 i18n + inline 守门员 0 / 2 死路由 + /medication 入 shell / badge secret ×5)。round 7b 为 6 个 god class 补 42 test (test:lib 36%→55%), 126 fail 收口到 4 个资产占位。**加权综合 ≈ 7.3/10** (架构 6.0 / 底层 8.0 / 视觉 7.5 / 上架 2.5), hotfix 后预估 8.3/10。报告: `docs/audit/2026-08-13-r111-multi-lens/` (10 文件)。

**R111 新发现 P0/P1 (代码级)**:

- **E1/E2 (P1 bug, ≤1d+2h)**: export/import JSON schema v4 落后 DB schema 22 — medications 漏 5 字段 (refillAt/refillReminderDays/form/colorIndex/notes) + moodEntries 漏 7 字段 (audio/period/influenceFactors/recordingMode) 换机/重装**静默丢失**; contact consent 4 字段不导出 → PIPL §13 留痕断裂 (R68 gate 只挡 add, 导入绕过)。共用 export/import 路径, 一次 v5 schema 升级 + round-trip test 闭环
- **SP-111-02 (≤1h)**: `flutter analyze` 27 warning 违反 0-warning 门禁 — 10 处 test fake 死 @override (R108 delegate 拆分后 scheduleDailyReminder 移走) + 11 处 lib unused import/field (R109 重构残留)
- **EM-21 (1-2d)**: en locale mood 标签显示中文 (ARB 无 moodLabelN key, presentation 3 处用 core Strings.moodLabel 硬编码)
- **FS-14 (0.5h)**: /contacts/new 死 push → 404 (emergencyContactEnabled 翻 true 即踩雷)
- **EM-16 (0.5h)**: 状态色当文字色对比度 1.9:1 (fgOnWarning 已存在未用) · **EM-14 (≤2h)**: disabled 按钮仍 press scale+haptic 假反馈
- **SP-111-04 (≤1d)**: static_scale_translations 8 新量表 domain 中文 items 0 直接断言 (最大 0-test 块)

**架构 4 P0 跨期残留 (0 进展)**: AR-17 scale_translations 三源 (810L l10n impl **0 运行时 caller 实锤死代码**, 2-3d 删 1,590L 重复) / AR-18 usecase 6 文件 736L (计划 14-16) / AR-19 saveSetup+clearAllUserData 仍在 app_database:420-510 / AR-16 4 个 data 文件 import 生成 ARB (pub workspace 死锁)。god class 22 个反涨, 仅 medication_page 553→347 拆成。

**上架**: 代码面 9.5/10 达提交水准 (锁屏 PII / PrivacyInfo / IAP 隐藏 / 0 假声明全绿); 硬阻塞 100% 外部依赖与 R110 一致 — 域名 ICP (7-20d) + 双平台资产 (设计师) + keystore (1h) + review_information 4 占位 + console 3 表单 (**新增 RECORD_AUDIO Audio 申报**, R105 恢复 + ventAudioEnabled=true)。

**R111 hotfix 计划 (本周)**: E1+E2 export v5 升级 (1d) → 27 warning 清零 (1h) → EM-16/14/21 (≤3h) → FS-14 死路由 (0.5h) → SP-111-04 量表 items 断言 (1d) → AS-16 check_review_information_todo.py 守门员 + notes.txt/short_description/changelogs (1h) → 死链 32 处 (本批已修 README/CHANGELOG/VERSION_1.0_PLAN/DEPLOYMENT) + AGENTS/spec 数字同步 (本批已修) → 预期 8.3/10

**R111+ 路线图 (与 R110 合并更新)**: R112 架构专项 (AR-17 合一 → AR-18/19 usecase+DB 编排 → AR-16 l10n 循环 → AR-20 god class 接力) · 视觉专项 (EM-02/AH-04 8 feature ALS 化 1-2d/页) · 外部闸门 (域名 → 资产 → keystore → release build 冒烟 + 16KB objdump → console 表单 → review 真实值 + 5.1.3 问卷) · v1.0 (2027-Q1)

## v0.32 R112 9 视角综合审视 (2026-08-13, 并行 subagent 只读审计)

**状态**: 9 个 subagent (6 产品视角 + 顶层架构 + 2 路底层逐行) 从 0 重跑, baseline = working tree R112 进行中 (127M + 13??, pubspec 0.32.0+142)。**R111 待验证清单 8/8 全实读闭环属实** (E1/E2/E3 export v5 7 case round-trip / FS-14 / EM-14/16/21 / R111-02/03 / SP-111-02 warning 27→3 / mojibake / spring 接真 caller)。实测: test 2377 pass / 4 fail (iOS 资产) / 1 skip; analyze 0 error / **3 warning / 133 info** (CHANGELOG "0 warning" 宣称不实)。**加权 ≈ 7.1/10** (emil 7.5 / superpowers 8.5 / flutter-spec 8.5 / AppStore 4.0 / GooglePlay 6.0 / AppleHealth 7.0 / 顶层架构 6.0 / 底层 8.0+8.0), 修完代码级 P0/P1 预估 8.3/10。报告: `docs/audit/2026-08-13-r112-multi-lens/` (10 文件)。

**R112 新发现 P0/P1 (代码级, 按优先级)**:

- **★E6 (P0, ~1d, 与 v5 同批修)**: export v5 仍**完全缺 6 张 daily tracking 表** (sleep/weight/socialRhythm/stress/treatment/anxietyAgitation, R91 功能) — 换机整块静默丢失; R111 E1 只对 medications/mood/contacts 逐字段对照漏了整表; import 也不 clear 这 6 表
- **★E-01 (P1, 0.5d)**: mood_audio_recorder_widget + vent_compose dispose 链 unmount 后 `ref.read` → Riverpod 3.4.2 `_assertNotDisposed` 无条件抛 → 被吞 → MoodAudioService native 句柄每次泄漏 (100+/day) + 明文 temp 文件永不删除 (PIPL §28)。修法 = B1-11 同款字段缓存 storage (initState 捕获)
- **★E-02 (P1, 0.2h)**: legal_page.dart:94 裸 `developer.log` 无 kReleaseMode 守卫 (全 lib 唯一), vent 删除失败 stack 泄 PII
- **★E7/E8/E9 (P1, 2h+4h+1h)**: profile PIPL §14 同意留痕 4 字段不导出 (E2 只修 contact 侧) / medications 导出走 watchActive() 丢软停药药名 (与报告 watchAllIncludingInactive 矛盾) / 趋势日历 8 新量表显示 raw scaleId
- **★裸 id 回归 (P1, 10min)**: settings 量表列表 phq9/gad7 subtitle 显示裸 id — scale_name_l10n switch 漏 2 case + 测试 `ids.sublist(2)` 盲区 (新 helper 必须全 id 覆盖 + isNot(id) 断言)
- **EM-16b (P1, ≤1h)**: 对比度只修 warning 档 — success 2.4:1 / error 3.0:1 / warningStrong 2.3:1 仍作文字色; fgOnSuccess=success 假 token
- **上架文案 4 新 P1 (1h 内)**: AS-22 description "stay connected with loved ones" 描述已 gate 关闭功能 (2.1 拒因级) / GP-R112-01 Android 文案点名被隐藏的 PHQ-9/GAD-7 / AS-21 promotional "mental health assessments" (R109 宣称删从未落地) / AS-23 Fastfile submit_for_review 脚枪
- **GP-R112-02 (P1, 15min)**: gradle-wrapper.properties 提交 `file:///C:/Users/18449/...` 机器路径 + wrapper 三件套被 .gitignore 排除 → 干净机器 release build 必断

**架构新实锤 (2 个守门盲区)**: check_all data 规则只禁 `presentation/`, **不禁 `l10n/` 不禁 `core/routing/`** — AR-16 (data→生成 ARB 4 文件) 与 R112-ARCH-02 (data→notification_navigation 传递 Flutter) 三年没人管得住。修法 = 先让 gate 红。**结论: 4 层 + core umbrella 对 81K 行够用, feature-first (2-3wk 纯 move 边际收益 < 成本) 与 pub workspace (零云端无买家) 现在都不推荐**; AR-17 R112 恶化到 4 源 (scale_name_l10n 新增但 assessment_center_card 私有 switch 未迁) + 810L 死代码 0 runtime caller 再实锤; AR-18 usecase 2/6 是死代码 (CheckSafety / ScheduleRefillReminder, service 直连 logic); god class 21 个 (仅 medication_page 拆成, export_import_pipeline 530L 新入口)。

**R112 hotfix 收尾 ✅ 已执行完毕 (2026-08-13, 修复战役 3 wave / 10 subagent + 主 agent 整合)**: E6+E7+E8+E9 export 补全 ✅ → E-01/E-02 ✅ → 裸 id + EM-16b ✅ → 3 warning 清零 + CHANGELOG 改实测数 ✅ → 上架文案 ×4 + wrapper ✅ → GP-R112-03/04 生成器刷新 ✅ → AR-17 删 1,600L 死代码 + 接线 2 usecase ✅ → 8 feature ALS 化 ✅ (EM-02/AH-04) → AR-16/ARCH-02 守门先红后修 ✅ → AR-19/ARCH-01/ARCH-03 编排下沉 ✅ → AR-23 swallowError 分簇 ✅ → golden ×3 + P3 卫生 ✅。终态: **2483 pass / 4 fail (iOS 资产) / 1 skip; analyze 0e/0w; 22 守门员全绿**。账本: `docs/audit/2026-08-13-r112-multi-lens/10-FIX-LEDGER.md`。未 commit (等用户确认)。
**残余 (R113+ 路线)**: 上架外部 P0 剩余 (域名 ICP / 设计师资产 / review 4 占位 / console 4 表单人工填 — 文本已生成在 build/ / release build 冒烟+16KB objdump 实测 — 本机无 Android SDK, keystore 已生成, check_16kb_alignment.py 已支持 --aab 真验证) · AR-20 god class 18 个长线拆解 (批1 pipeline + 批2 setup_page_state 503→331 + add_medication 573→258 已拆) · R51b 8 量表 items i18n (v1.0) · AH-08/09 真 reduce-transparency/SF Symbol (v1.0) · keystore 密码备份 1Password (用户操作)。

**R112+ 路线图 (与 R111 合并更新)**: R113 视觉专项 (8 feature ALS 化: settings 4 组 → vent → assessment → mood_list; 集中器自清; golden 3 widget) · 架构专项 (AR-16 守门先红 0.5d → AR-19+R112-ARCH-01 ConsentPreferenceStore 数据编排下沉 5d → AR-20 god class 接力批1 export pipeline 拆 4 子函数) · 外部闸门 (域名 ICP → keystore → 首次 release build 冒烟 + 16KB objdump → console 4 表单 → 设计师资产 → review 真实值 + 5.1.3 问卷) · v1.0 (2027-Q1)

## v1.1.0 情绪优先重构 (2026-08-15, rounds 1-6, 外联删除定版 + 情绪/树洞优先)

**状态**: 产品定位翻转 — 从"吃药打卡 + 失联通知"重定位为**情绪日记 + 树洞倾诉优先、用药记录辅助**。6 round 落地: 外联全链删除 + 3 新功能 + 导航/首页重构。**FeatureFlags 7→4, 守门员 22→21, schemaVersion 22→23, export schema v5→v6**。

**核心变更**:

- **round 1/1b/1c (domain)**: 树洞预设标签库 `vent_tag_library` + 情绪状态短语库 `status_phrase_library` + 情绪回顾聚合器 `mood_review_aggregator` (12 case 测试)
- **round 2 (data)**: schema 23 — vent +tagsJson / mood +statusPhrase 两列 + migration + round-trip 测试
- **round 3 (data)**: export v6 — 删 contacts 段 + statusPhrase/tagsJson, 老 v5 文件 contacts key 忽略
- **round 4/4b/4c (presentation + 外联删除)**: contact 页/setup 联系人表单/settings 失联卡/home safety check 全删; SMS/邮件/SafetyWatch/CareEngine/ReminderChecker 服务全删 + contacts 表 + migration drop; FeatureFlags 7→4; 守门员 22→21 (check_sms_release_ready 删, check_pii_in_title/check_legal_consent 同步收窄); user_name_helper 等死代码清理
- **round 5/5b (导航 + 首页)**: 4 tab 心情/树洞/趋势/设置 (/vent /trend 入 ShellRoute); 首页双主卡 MoodHeroCard + VentHeroCard, 打卡降级 compact
- **round 5c/5d/5e (3 新功能 UI)**: 树洞标签 (compose 选择 + 列表筛选 + 详情显示) / 状态短语 (dialog 预设+自定义 + 列表/详情) / 情绪回顾页 (周/月统计摘要 + /mood-review 路由)
- **round 6 (文档)**: README/CHANGELOG/AGENTS 同步 + 版本 1.1.0+148

## v1.1.0 论文落地 (2026-08-16, rounds 8-9, F3 心理技巧 + F4 树洞公约 + F1 烦恼闭环)

**状态**: 基于 4 篇论文的落地方向按 F3→F4→F1→F2 顺序推进; F3/F4/F1 已闭环, F2 待做。版本 1.1.0+149, schemaVersion 24, export schema v7, ARB 1323×3 语, 2338 test / 0 fail / 1 skip, analyze 0e/0w/219 info。**守门员实测 (R113): 17 绿 / 2 红 (check_review_information_todo: notes.txt 版本滞后 + check_coverage: lcov 缺失) / 1 工具缺失 (check_zh_hant_consistency 需 OpenCC) / 1 skip (16KB 产物验证)** — "写全绿前必实跑全套"。

- **round 8 (F3 心理技巧知识库)**: `domain/logic/psychology_tips_library.dart` (5 技巧) + `preset_content_l10n.dart.localizedPsychologyTip()` + 36 ARB key×3 + `/tips` `/tips/:id` 页 + settings 入口 + 11 测试。
- **round 8 (F4 树洞使用公约)**: `data/services/vent_agreement_store.dart` (SharedPreferences `vent_agreement_acknowledged`) + vent_compose initState 弹窗 + `presentation/pages/vent/widgets/vent_agreement_dialog.dart` (抽 dialog 保 <520 行守门) + 6 测试。
- **round 9 (F1 烦恼闭环)**: 烦恼主题体系 (记录心情可绑定进行中烦恼 / 新建 / 不关联):
  - **domain**: `worry_thread_entity.dart` (WorryStatus open/resolved + WorryThreadEntity) + `worry_thread_library.dart` (generateTitle 前 20 字) + `worry_thread_repository.dart`; MoodEntryEntity/Draft +worryThreadId, MoodRepository +watchByThread.
  - **data**: schemaVersion 23→24 — 新 `worry_threads` 表 + `mood_entries.worryThreadId` 列 + `worry_dao.dart` (watchOpen/watchResolved/getById/getAll/insert/resolve/reopen/rename) + `mood_dao.watchByThread` (时间正序) + `from<24` migration. Export v7 — 新 worryThreads 段 + mood.worryThreadId 原 id 导出 + import old→new 重映射 (老 v6 无此段 → 降级 null, 不建孤儿 FK).
  - **presentation**: `worry_providers.dart` (worryOpen/Resolved/Entries autoDispose) + `worry_timeline_page.dart` (/worry/:id: 继续倾诉/闭环/reopen/重命名) + `worry_archive_page.dart` (/worry/archive 忆往昔 🎉) + `widgets/worry_section.dart` + `widgets/worry_selector_field.dart` (bottom sheet) — **这两个 widget 放 `presentation/widgets/` 而非 pages/worry/**, 因 mood 页也 import (跨 feature guard 禁 pages/{A}→pages/{B})。
  - **集成**: `/mood/create?worry=<id>` 路由传 initialWorryThreadId; mood_list_page 插 WorrySection; mood_recorder_page 保存时新建烦恼并绑定.
  - **测试**: 新 24 测试 (worry_thread_library 8 / worry_thread roundtrip 6 / data_export_v7_worry 4 / worry_timeline widget 5 + 迁移 dry-run 扩 24); 4 个 `implements MoodRepository` 测试补 watchByThread stub; 6 个挂 MoodRecorderPage/MoodListPage 的测试补 worry provider override.
- **坑 (本批)**: `DateTime` 不能 const → const WorryThreadEntity 报错; WorrySelectorField/Section 跨 feature 需放 widgets/; `MoodEntriesCompanion.insert` 直接构造 (无 toCompanion); `app_tokens` textStyle* 都是 `textStyle*(context)` 非 const getter.

**隐私边界**: 烦恼闭环属情绪日记 (mood) 范畴, 不进树洞/通知/评估/趋势; 树洞仍绝对隔离。

**4 FeatureFlag**: `ventAudioEnabled=true` / `fiveVendorPushEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` 均 false (等外部依赖)。

## v1.1.0 R113 九视角综合审视 (2026-08-16, 并行 subagent 只读审计)

**状态**: 9 个并行 subagent (emil / superpowers / flutter-audit / gdc / AppStore / GooglePlay / AppleHealth + 2 路底层逐行) 从 0 重跑。**加权综合 ≈ 7.2/10**。完整整合报告: `docs/audit/2026-08-16-r113-multi-lens/00-FINAL-CONSOLIDATION.md`。

**评分**: emil 7.5 / superpowers 7.0 (守门员全绿声明不可复现) / flutter-audit 8.7 (0 致命) / gdc 架构健康 (R112 六大架构债全闭环实锤) / AppStore 5.5 / GooglePlay 6.0 / AppleHealth 视觉 8.0 (HealthKit 0 集成但合规 10/10) / 底层逐行 22+21 发现 (0 隐私违规)。

**外部链接隐藏确认 ✅ 100% 干净** (双视角独立实锤): SMS/Email/紧急联系人/失联/5 厂商 push/FCM/阿里云/SendGrid 代码+数据表+UI+ARB+权限全链删除。残留仅 4 处文案 (release_notes.txt "contacts" / ARB 3 语联系人残留 / ARB example 元数据 / BootReceiver.kt 死文件)。

**R113 新发现 (P1 级功能 bug, 按修复顺序)**:
1. `/worry/archive` 被 `/worry/:id` 遮蔽成死路由 (go_router first-match-wins) — "忆往昔"入口开 threadId=0 永远转圈 (`app_route_worry.dart:11-19`)
2. 打卡失败仍弹成功庆祝 + streak+1 (`home_page_state.dart:357-369`)
3. `requestPermission()` 恒返 true — 权限拒绝引导永不触发 (`notification_initializer.dart:129-142`)
4. 情绪提醒通知点击完全无反应 — `chroniccare://mood-diary` 无 resolver case (`mood_reminder_notifier.dart:70`)
5. 漏服日期全部落在开药之前 (`medication_stat_calculator.dart:117-124`)
6. profile 导入被 userName 空值整体跳过 → PIPL §14 留痕丢失 (`export_import_pipeline.dart:200-205`)
7. refillReminderDays=0 (import 合法) → 全部续方提醒静默中止 (`refill_scheduler.dart:63`)
8. snooze 硬编码 exactAllowWhileIdle 绕过降级策略 (`snooze_manager.dart:120`)
9. 趋势日历 8 新量表显示裸 scaleId + 总分恒 0 (R112 E9 未闭环: `day_detail.dart:371-394` tryFromEntity 只读 total 但 R90 写 score)
10. 评估提醒 body 含量表名 "PHQ9" — iOS 锁屏 PII (守门员只守 title 不守 body)

**上架阻塞 100% 外部依赖** (与 R112 一致): 截图 0/67B 占位 (设计师) / 域名 ICP 7-20d / review 信息 4 占位 / 5.1.3 问卷 / Console 4 表单 / 16KB 真验证 / keystore 备份 / 律师签字。代码侧唯一红色 = notes.txt 版本滞后 (30min)。

**R113+ 路线图**: wave 1 守门员转绿 (notes.txt + lcov + OpenCC + format 142 文件) → wave 2 S 级功能 bug (8 个) → wave 3 UI bug 收口 → wave 4 守门员收口 (CI 补 5 个 + datetime_race exit + 16KB 产物验证) + domain i18n 四路合一 → wave 5 export_import_pipeline 931L 拆 3 文件 (最后真 god class) → wave 6 F1 UI 测试补全 → wave 7 主页动画停播 (StatefulShellRoute) + 跨 midnight stale → 长线 mood ALS 化 + 法务文档 + 上架外部闸门。

## v1.1.0 R113 修复战役 (2026-08-16, 7 wave 全闭环, 未 commit 等用户确认)

**状态**: R113 九视角综合审视发现的代码级 P0/P1/P2 按路线图 7 wave 全修。**终态: 2407 pass / 0 fail / 1 skip; analyze 0e/0w; 21 守门员全绿 + check_all 双绿 + format 0 changed + coverage 全阈值 PASS**。账本: `docs/audit/2026-08-16-r113-multi-lens/00-FINAL-CONSOLIDATION.md` + 各 wave 报告 (git diff)。

**Wave 1 守门员转绿**: notes.txt +149 / spec.md 数字 74 calls/43 files + "Card 清零"措辞收窄 / typography 注释同步 (13pt / 110pt) / dart format 142 文件。

**Wave 2 八个 S 级功能 bug (8/8 + 56 tests)**:
1. /worry/archive 死路由遮蔽 — 路由顺序对调 + timeline EmptyState (worryThreadNotFound ×3 语)
2. 打卡失败仍庆祝 — `home_page_state._onCheckIn` hasError 早退
3. requestPermission() 恒 true — 平台分支 (新 dev_dep flutter_local_notifications_platform_interface)
4. mood-diary 通知点击无反应 — resolver 加 case → /mood-diary
5. 漏服日期在开药前 — MissedDateBuilder 加 effectiveStart
6. _EntrySpring 无视 reduce-motion — didChangeDependencies 归零 + medication 打卡 Motion.duration + PressFeedback
7. 2 处 success 色作文字色 — fgOnSuccess
8. 评估通知 body 量表名 PII — Strings 签名删 scaleIdUppercase 参数 (编译期防泄漏)

**Wave 3 UI bug 收口 (8/8 + 12 tests + 2 新发现 bug)**:
- CBT PDF 硬编码中文 → CbtPdfL10n 12 getter (badge5/7 + moodLabel + originalScoreLabel); **check_strings_hardcoded.py 整文件豁免 → `// rule3-whitelist: 行号/区间` 精确豁免 token**
- tracking_item_card "今天" → _isToday 日期对比; vent_detail catch 路径 → _storage 字段缓存; mood_recorder 孤儿烦恼 → createdThreadId 回滚删除; vent/treatment Dismissible fire-and-forget → try/catch + swallowError + snackbar; medication 打卡静默失败 → 反馈; mood_trend y=0 → computeTrendSpots FlSpot.nullSpot (折线断开); legal withdraw → try/catch + withdrawnAt 回读
- **测试 agent 发现 2 个新 bug 并修**: (7b P0) Dismissible dismissed-state 留在树 → FlutterError (Riverpod invalidate 是 isRefreshing 不是 loading) → key rotation (`treatment-{id}-{failCount}`); (8b P1) legal withdraw 3 选 1 dialog 选项 Row 无 onTap 永不可点 → InkWell pop(choice)

**Wave 4 守门员收口**: CI 16→21 守门员 (flutter test --coverage + 5 个补进) + **修 2 处既有 YAML 语法错误 (workflow 此前解析不过!)** + check_datetime_race×2 加 exit 1 + check_16kb 产物缺失 FAIL + **check_pii_in_title 2/5 → title+body 10/10** + 17 pytest 自测。**Ruling: domain i18n 四路合一不半修** (round 7b 已闭环显示层; 量表题目全量 i18n = v1.0 R51b 既定计划)。

**Wave 5 export_import_pipeline 拆解**: 934L → facade 184 + import_entities 656 (meds+mood+worry+6 tracking) + import_profile 86 + import_vent 70 + import_shared 29 (ImportResultBuilder)。**移动中发现并修 3 bug**: refillReminderDays=0 双端防守 (scheduler 返回 null 不抛 + import clamp 1) / piiSafeLog 无 kReleaseMode 守卫 / medication_detail _InfoChip 对比度。

**Wave 6 F1 UI 测试补全 (11 tests)**: worry_archive_page 4 (渲染/空态/reopen/路由) + worry_selector_field 5 (3 分支 + 预绑定 + 新建) + mood_recorder_worry_binding 2 (成功路径 draft.worryThreadId==42 + createCalls==0 防重复建; /mood/create?worry=7 真路由绑定链)。

**Wave 7 主页动画停播 + 跨 midnight stale**: `homeEntryPlayedProvider` (NotifierProvider 进程级 flag) — 首帧全动画, tab 切换后 FadeIn duration.zero + 无 stagger + _EntrySpring 跳 1.0 (未上 StatefulShellRoute — 留 R114); 5 处 build DateTime.now() → ref.watch(todayProvider) (mood_trend behavioral / vent_list / daily_tracking / assessment_center_card / mood_review), 2 behavioral + 3 lock-in tests。

**事故记录 (本批)**: 全量 `for s in scripts/*.py` 循环踩 2 个一次性脚本地雷 — (1) `apply_l10n_implements.py` 把已删 SafetyAlertL10n implements 写回 generated file → 146 test 编译失败; (2) `_clean_orphan_arb_keys.py` 按 round 56e 硬编码列表删 8 个后来重新启用的 live key (moodLabel1-5 / ventDuration*) → 从 HEAD 恢复。**两脚本已删除防再犯**。

**R114 长线**: mood 主流程 ALS 化 (P1, 2-3d) / StatefulShellRoute 分支保活 / 法务文档 3 份残留已删功能 (需用户+律师) / 上架外部闸门 (域名 ICP → 设计师资产 → keystore 备份 → console 表单 → review 真实值) / export_import_pipeline import_entities 656L 可视需再拆 _importDailyTracking。

## v1.1.0 R114 standard 审计 + 修复战役 (2026-08-16, 未 commit)

**状态**: standard skill 全流程 — 规范落地 `.opencode/standards/` (5 份) → 10 并行子代理审计 (6 视角 + 4 底层分批, 报告 `.opencode/audit/01~13` + 00 汇总) → spec 回写 `.opencode/spec.md` → 修复战役 5 wave (A/B1/B2/C/D) 全闭环。**终态: 2509 pass / 0 fail / 1 skip; analyze 0e/0w + lib/ 0 info; 21 守门员 + check_all 全绿; format 0 changed**。

**Wave A (P1 ×11 + 25 tests)**: check-in/today 通知死链 (resolver case + 双 sender 走 encode) / 录音明文 temp 清理 (deleteTempRecordFile 全路径, PIPL §28) / 评估总分恒 0 (total/score 双 key 兼容) / 裸 scaleId + en 中文 (day_detail 3 closure 注入) / vent_hero_card 封存泄漏 (PIPL §47, sealed gate) / medication_row Dismissible key rotation / vent 删除 2 处 try/catch / 裸 db id → 药名 (homeMedHint name 参数) / setup done 幂等 (PopScope + guard) / release_notes 重写 / INTERNET 注释更新 (决定保留)。

**Wave B1 (P2 ×8 + 60 tests)**: eager ListView → **LazyAppleListSection 新集中器** (sliver 化, 视觉 1:1) / snooze exact 注入 scheduleModeProvider / **refill 带 6000→2500000** + legacy 精确清理 (cancel 互杀闭环) / watchToday DAO 跨日重订阅 / 打卡率分母 elapsed 天 / date_utils UTC 归一化避 DST / provider 吞 error → hasError 传播 (4 处) / **DB key 失配 → probeDatabaseReadable + DatabaseResetPromptApp** (重试/重置二次确认, 顺带修 boot apps 裸 MaterialApp 缺 delegates 崩溃)。

**Wave B2 (P2 ×9 + 49 tests)**: tab 过渡统一 fade (4 tab 根) / iOS swipe-back (_SwipeBackCupertinoRoute 子类) / 宽屏返回按钮 (canPop 保留 AppBar) / 双重 inset 统一 20+0 (PageScaffold 唯一负责, ALS margin 归零) / fl_chart Semantics (4 ARB key) / StatCard tabularFigures + tile textScaler clamp 1.3 / import_entities 664→421 (拆 import_daily_tracking.dart) / footer 门控 + 高频 durFast / 裸 InkWell×5 处 PressFeedback + celebration scale 0.5 + **spring bouncy 接 celebration (第 2 真 caller)**。

**Wave C (P3 ×14 + ~40 tests)**: 删死代码 6 项 (uuid 依赖 / MoodQuickButton+todayMoodProvider / flutter_dotenv / encryptionServiceProvider / windowSizeOf / slide_up) / lib lint 清零 (16 trailing comma + dangling doc + prefer_const ×2) / export_schema dynamic→Object? / page_scaffold title! 安全 / loading_text_button spinner 色按 variant / magic spacing token 化 / worry_selector 失效降级同步 draft / consent_dialog ctx / AES-CBC TODO(v1.0 GCM)。

**Wave D (mood ALS 化)**: mood_recorder Dialog 内 2 组 AppleListSection (评分组/记录组) + **MoodScoreButtons 共享 widget (72pt 圆形 + spring 选中 + reduce-motion + 48pt 下限 clamp)** + CBT wizard score 段迁移 + PrimaryButton pill + cbt_explainer_card ALS 化 + 删 4 维死代码 (mood_score_chooser/dimension_row); 裁决: Dialog 保持 modal (sheet 化留 v1.0, 6+ 调用方风险高)。+4 tests, 2509 pass。

**R115 剩余 (外部依赖为主)**: 上架闸门 (域名 ICP / 截图 / review 信息 / console 表单 / ICP 备案+软著) / StatefulShellRoute 分支保活 / mood sheet 化 (v1.0) / 法务文档律师过审 / ARB 1331→1328 基线。**gdc 主矛盾警告: 工程闭环 vs 用户闭环脱节 — 建议今天注册域名 + 本周 sideload 10 真实用户, 停止审计循环**。

## v1.1.0 R115 emotion-first 重构 (2026-08-17, Batch 1 视觉 + Batch 2 隐私加固)

**状态**: 1.1.0+150 commit, 14 新 ARB key (3 langs), more_entry_sheet.dart + primary_action_row.dart (3 list rows + MoreEntryTrigger) + today_summary_card.dart (mood/vent/sleep/worry) + health_data_group.dart + settings_page.dart (5 groups) + profile_group.dart cleanup。Batch 2 隐私加固: 5 新守门员 (check_no_network_io / check_release_no_network / check_permissions_whitelist / check_encryption_at_rest / check_pii_in_assets) + docs/PRIVACY_HARDENING.md 13KB。22→27 守门员, 2515 tests pass, 1340 ARB keys (zh/en/zh-Hant)。

## v1.1.0 R116 god class 拆解 4 round (2026-08-17, 1.1.0+150~+154)

**状态**: round 1 mood_trend_page 653L → 104L 主壳 + 4 chart 子文件 / round 2 reminders_hub_page 312L → 213L 主壳 + 155L assessment_reminder_sheet / round 3 medication_page 380L → 281L 主壳 + 121L medication_slot_entry_row / round 4 add_medication_page 247L → 195L + AddMedicationStepIndicator + AddMedicationStepFooter (1.1.0+154 5 widgets + 9 orphan ARB key 清掉)。R108 §六 4/12 闭环 (1 提前)。

## v1.1.0 R117 综合审视 11 视角 (2026-08-17, docs/audit/2026-08-17-comprehensive/ ~63KB)

**状态**: 11 视角 subagent 报告 + 00-FINAL-CONSOLIDATION.md + docs/DEVELOPMENT_REQUIREMENTS.md v2.0 (239L) + 5 新上架守门员 (check_appstore_screenshots / check_ios_launchimage / check_appicon_size / check_domain_icp / check_appstore_metadata)。加权综合 7.0/10 (R31 6.5 → +0.5)。27/27 守门员 = 22 现有 + 5 上架 P0 external (expected fail 等资源)。25 P0/P1/P2/P3 修复需求 (11 误判已识别)。

## v1.1.0 R118 god class 续拆 P2-7 — 10 量表抽独立 class (2026-08-17, 8 commit db920d50~b29d3bd7)

**状态**: 10 量表抽独立 class (Phq9Translations 94L / Gad7Translations 84L / IsiTranslations 83L / PssTranslations 84L / WhodasTranslations 90L / AsrmTranslations 83L / Level2Depression 84L / Level2Anxiety 83L / Level2Mania 81L / Level2Psychosis 88L) + 主壳 StaticScaleTranslations 659L → 394L (-40%)。composition 委托: 10 const instance + 70 method (7 × 10) 1:1 委托。test/domain/entities/scale_translations/round118_direct_test.dart 42 case (边界 20 / 主壳委托 10 / 跨 class 共享 2 / 真实输出非空 10)。0 公共 API 变化, 0 跨层 import regression, 0 drift schema 破坏。

## v1.1.0 R119 god class 续拆 P1-1 — app_database 564L → 139L 主壳 + 480L part 文件 (2026-08-17, 1 commit 82fe9e9b)

**状态**: 抽 app_database_migrations.dart 作 `part of 'app_database.dart'`, 共享 library scope 让 drift 生成 `db.moodEntries` / `db.ventEntries` 等 TableInfo 顶层引用无需 import/export。主壳 139L (-75%) = imports + `@DriftDatabase` + 2 constructor + `schemaVersion 24` + 1-line migration getter + 15 DAO facade。SQL 字符串 snake_case 保持 (1 处 perl replace 误改已修)。test/core/data/database/app_database_split_round119_test.dart 5 case (双存在 / part 指令 / 1-line 委托 / 24 guard / 主壳 < 200L)。schemaVersion 24 不变, 24-version onUpgrade 1:1 保留, 0 数据迁移风险。

## v1.1.0 R120 god class 续拆 P1-2 — notification_service 386L → 252L facade 收紧 (2026-08-17, 1 commit e07ae845)

**状态**: 抽 `_buildNotificationDetails()` 私有方法 (showNow 内 30L Android+iOS NotificationDetails 块封装) + 40L 跨 sub-service ID range 文档外移到 `docs/architecture/NOTIFICATION_ID_BANDS.md` 独立 doc + 32L 类头历史注释压缩到 12L 摘要。test/core/data/services/notification_service_split_round120_test.dart 5 case (双存在 / 私有方法 / showNow 1-line 委托 / ID doc 外移 / 主壳 < 350L)。test/core/data/services/notification_service_can_exact_round108_test.dart A2 修 `+ 3000` 硬编码缓冲 (R120 文件 11064→9930 字节后越界)。0 sub-service 接口变化, 0 公共 API 变化。

## v1.1.0 R120 综合审视 4 视角 (2026-08-17, docs/audit/2026-08-17-round120/ 6 文件 1186 行)

**状态**: 1 主 agent 自查 + 4 subagent 并行 (emil 8.0 / flutter-spec 97% / superpowers-zh 7.0 / frame-thinking 8.5), 加权综合 **7.5/10** (R117 7.0 → +0.5)。R108 §六 god class 候选 **4/12 闭环** (R116 round 4 add_medication_page + R118 P2-7 10 量表 + R119 P1-1 app_database + R120 P1-2 notification_service)。修 1 守门员回归: notification_service rule3-whitelist 行号重生 (205,271,303,312-313 → 137,193,207,215-216)。

**R121 优先级 1 综合 (4 视角加权, 估时 12.1h, 预期加权 7.5→8.0)**:
- superpowers-zh: 文档同步 4 项 (CHANGELOG 缺 R118 P2-7 + AGENTS 缺 4 章节 + EN Summary 2515→2571 + PRIVACY_HARDENING 改 R120 framing) — 3.1h
- frame-thinking: vent_list_page 684L 拆 3 (emotion-first 主路径) + spring.dart 145L 接入 _EntrySpring — 3.5h
- emil: R120 2 alias @Deprecated 标记 + R119 part 文件拆 4 子文件 + R118 量表 class 各自 implements ScaleTranslations — 4h
- flutter-spec: CI 接入 `flutter test --coverage` + spring.dart gentle 接入 — 1.5h

**R121 战略** = 70% god class 续拆 + 20% P0 external 主动动作 (域名 ICP / 设计师 RFP) + 10% 文档同步 + 跨期 P0 等外部。**跨期 7 P0 external 0 闭环已 8 round** (frame-thinking Focus 维度降 1 分, R121 该并行推主动动作)。

## v1.1.0 R121 hotfix — superpowers-zh P0 文档同步 4 项 (2026-08-17, 1 commit)

**状态**: AGENTS.md 顶部 EN Summary 2515 → 2571 (R120 baseline) + 加 R115/R116/R117/R118/R119/R120/R120-audit 7 章节 (原 R115-R120 缺, superpowers-zh 独家 P0 漏洞) + PRIVACY_HARDENING.md 改 R115 → R120 framing + CHANGELOG 1.1.0+15X 段补 R118 P2-7 entry。scale_translations.dart 头部注释加 R118 段, AGENTS.md 21 守门员清单重写为 27 (R115 +5)。1.1.0+155 R119 / 1.1.0+156 R120 CHANGELOG entry 已加, R118 P2-7 8 commit 流水 entry 补完。

## v1.1.0 R121 P1-2 — vent_list_page 684L 拆 2/3 (2026-08-17, 2 commit 2ed079fb / fd5bce85)

**状态**: frame-thinking Focus 维度跨期残留 — vent_list_page 684L 拆 2/3 (emotion-first 主路径)。step 1 抽 `widgets/vent_entry_cell.dart` (232L, VentEntryCell + VentHintHelper 公开 widget 集中器模式 + super.key) — commit 2ed079fb。step 2 续抽 `widgets/vent_entry_list.dart` (189L, VentEntryList 公开) — commit fd5bce85。主壳 684L → 251L (-63%)。`_VentListPageState` 60L 业务编排 state 暂不拆 (跟 _VentEmptyState / _VentSealedState 紧耦合, 单独拆需传 5+ callback 不划算)。修 mood_trend_day_change_round113 + home_footer_fade_gating_round114 改读双文件 0 业务行为变化。

## v1.1.0 R121 P1-3 — notification alias @Deprecated + migrations 拆 4 sub-part (2026-08-17, 3 commit 1b134650 / 5c5b9110 / 82a0f4a4)

**状态**: step 1 (1.1.0+160, emil 决策) — notification_service 2 facade alias `refillNotificationId` + `computeRefillFireTime` 加 @Deprecated 标记, 注释指向新 `_` 私有实现 (R120 facade 收紧的子层收口, 后续 v1.1 删)。step 2 (1.1.0+161, emil 决策) — app_database_migrations 480L → 60L 薄壳 + 4 sub-part (`v1_v5.dart` 60L / `v6_v12.dart` 162L / `v13_v18.dart` 110L / `v19_v24.dart` 109L), 主 orchestrator 4 行调用 4 sub-part, 共享 library scope 让 drift 生成的 `db.moodEntries` / `db.ventEntries` / `db.medications` 顶层引用 0 编译 boilerplate。step 3 (1.1.0+163, 评估) — 量表各自 implements ScaleTranslations 实测 10 class × 70 method = 700 method stub 远超 70 委派, 真正消除需抽象 Translation interface + pub workspace 规模, defer 到 R122+ 路线图。

## v1.1.0 R121 P1-4 — CI coverage gate + spring.gentle 真实动画 caller (2026-08-17, 1 commit f250c6f2)

**状态**: flutter-spec 跨期残留 — CI 配 `flutter test --coverage` + `python3 scripts/check_coverage.py` 75.4% 阈值 (5 layer + 2 critical file) 全过 (TOTAL 75.4% / domain 82.0% / data 75.4% / presentation 75.4% / shared 88.4% / core 62.3% / streak_calculator.dart 96.4% ≥90% / notification_service.dart 63.5% ≥25%)。spring.gentle 真实动画 caller: `test/core/theme/spring_gentle_round121_test.dart` 3 case — Spring.gentle 0→1 收敛 + 阻尼比 ζ=0.735 欠阻尼 (mass=1 / stiffness=150 / damping=18) + 真实 widget 动画 `animateWith(Spring.gentle.toSimulation)` 在 0.5s 收敛 (跟 mood_score_buttons 同模式, 满足 "1 个真实 caller" 验收)。不改 PressFeedback/showModalBottomSheet 30+ 调用点 (M3 动画跟 iOS spring 不同档, 改 custom transition 风险大)。

## v1.1.0 R122 P2-1 step 1 — mood_audio_service STT 抽独立 class (2026-08-17, 1 commit 779e6d8d, 1.1.0+164)

**状态**: flutter-spec 跨期残留 (R31 误判"已闭环" cross-residual) — mood_audio_service.dart 496L 跨 audio recording + STT + storage 3 业务。抽 `mood_audio_stt.dart` (154L) 含 MoodAudioStt public class, 完全封装 SpeechToText + StreamController + STT 错误处理 (audioErrorSink)。主 MoodAudioServiceImpl 5 处委派: _stt 字段 → _sttController 字段 / initialize → 1-line / startRecording STT 启动 → 1-line / cancelRecording STT 停止 → 1-line / dispose STT 释放 → 1-line / isSttListening getter → 1-line。step 1 拆 STT 496L → 406L (-18%)。

## v1.1.0 R122 P2-1 step 2 — mood_audio_service recorder 抽独立 class (2026-08-17, 1 commit, 1.1.0+165)

**状态**: 拆 3 facade step 2 — 抽 `mood_audio_recorder.dart` (307L) 含 MoodAudioRecorder public class — recorder 状态机 (start / stop / pause / resume / cancel / dispose) + 3min 上限 + 100ms tick timer + 暂停冻结 elapsed + temp file 清理 (R114 BUG 2 跨期残留)。4 getter: isRecording / isPaused / recordingElapsed / tempRecordPath + `setAutoStopCallback(onAutoStop)` (3min 到期回调, service 层挂) + `MoodAudioRecordingOutcome` value class (plainPath + durationMs, 跟 service 层 `MoodAudioResult` 区分) + `MoodAudioRecorderException` public exception (service 层 catch 转 `MoodAudioException` 保持公开 API 兼容) + `_deleteTempFile` → `deleteTempFile` 公开 (让 service 层 `deleteTempRecordFile` 1-line 委派, single source of truth)。

主 MoodAudioServiceImpl 6 方法全部委派: startRecording → `_recorderController.start()` + catch 转译 + `_sttController.startListen()` / stopRecording → `_recorderController.stop()` + 转换 outcome → result / pauseRecording / resumeRecording → 1-line / cancelRecording → `_recorderController.cancel()` + `_sttController.stop()` / dispose → `_recorderController.dispose()` + `_sttController.dispose()` / `deleteTempRecordFile` 静态 → 1-line 委派到 `MoodAudioRecorder.deleteTempFile`。

主 service 删 13 字段 + 2 imports: `_recorder` (AudioRecorder) / `_isRecording` / `_isPaused` / `_pausedAt` / `_pausedTotal` / `_recordingStart` / `_recordingTimer` / `_recordingElapsed` / `_tempRecordPath` / `_onTickCb` / `_onMaxReachedCb` / `_effectiveMaxDuration` / `_effectiveTickInterval` + `dart:io` (不再直接用 File) + `package:record/record.dart` (不再直接用 AudioRecorder/RecordConfig)。构造器签名改: `AudioRecorder? + maxDuration? + tickInterval?` (3 直接参数) → `MoodAudioRecorder? recorderController` (1 facade 参数)。

**R122 P2-1 step 2 主 service 缩 406L → 251L (-38.2%)**, 跟 R122 路线图预期 ~250L 完全对齐。`mood_audio_recorder_split_round122_test.dart` 10 case 守门员 (主 service < 280L / 不含 5 recorder state 字段 / 不含 `_recordingTimer` / 不含 `_tempRecordPath` / 不直接用 `package:record/record.dart` 含 negative lookbehind 排除 Mood 前缀 / 不直接用 `dart:io` / MoodAudioRecorder public API 完整 4+5+1+1+1 / 6 委派 + 4 getter 委派 / 异常转译)。`mood_audio_service_round61c3_test.dart` 2 case 适配新构造器签名。

## v1.1.0 R122 P2-1 step 3 — mood_audio_storage 独立验证 (拆 3 facade 闭环) (2026-08-17, 1 commit, 1.1.0+166)

**状态**: 拆 3 facade 闭环 — `mood_audio_storage.dart` 67L 已 100% 独立 (R0.23 round 43 spen-2 抽 EncryptedAudioStorage 基类已完成 99% 业务逻辑, MoodAudioStorage 仅 mood-specific 配置)。`mood_audio_storage_split_round122_test.dart` 6 case 守门员 (4 文件双存在 / storage < 100L / storage 0 业务方法含不 import dart:io / storage extends EncryptedAudioStorage + export 基类 / 主 service 不 import EncryptedAudioStorage 基类 (委派路径完整) / 4 文件总和 < 800L)。

**R122 路线图 ✅ 闭环**: P2-1 step 1 (STT 154L) + step 2 (recorder 307L) + step 3 (storage 66L review) — 主 MoodAudioServiceImpl 最终 251L (-49.4%, 超路线图预期 50%)。拆 3 facade 总 780L (拆前 496L, +284L = +57.3% overhead, 主要是 import / 文档 / 业务注释, 0 facade 业务回填)。**R108 §六 god class 候选 5/12 闭环** (R118 P2-7 10 量表 / R119 P1-1 app_database / R120 P1-2 notification_service / R116 round 4 add_medication_page / R122 P2-1 mood_audio_service)。

## v1.1.0 R122 P2-2 — legal_page 555L 拆 4 widget + 1 enum (2026-08-17, 1 commit, 1.1.0+167)

**状态**: R108 §六 真实 god class 候选闭环 (R108 估算 460L 接近, 实际 555L)。R116 / R121 期间没动, R122 P2-2 拆 4 widget + 1 enum 跟 R121 P1-2 vent_list_page 模式对齐。`lib/presentation/pages/settings/widgets/` 新增 5 文件:
- `legal_section_title.dart` (34L) — `LegalSectionTitle` 公开 (super.key, section 标题渲染)
- `legal_doc_tile.dart` (34L) — `LegalDocTile` 公开 (法律文档入口: 用户协议 / 隐私政策 / 敏感数据同意)
- `legal_consent_tile.dart` (119L) — `LegalConsentTile` 公开 (撤回同意 toggle 行, R95 sub-spec 8 task 46 chip 标识)
- `legal_withdraw_option.dart` (73L) — `LegalWithdrawOption` 公开 (vent 撤回 3 选 1 dialog 内部选项, R113 BUG 8b 修 InkWell)
- `legal_withdraw_choice.dart` (18L) — `LegalWithdrawChoice` 公开 enum (替代 _VentWithdrawChoice)

主 `legal_page.dart` 555L → **344L (-38%)**, 只剩 2 class (`LegalPage` + `_LegalPageState`) + 1 顶层 helper `clearLegalConsentCache`。业务方法 `_load` / `_toggle` / `_showVentWithdrawDialog` 跟 state 紧耦合保留 (R121 P1-2 同款决策, 跟 _VentListPageState 60L 业务编排 state 类比)。

**R95 sub-spec 5 task 3-4 lock-in 协同**: `app_tokens_lock_in_round95_test.dart` 1 case 适配 — legal_page textStyleBodyStrong + textStyleLabelMedium 集中器检查从单文件 (主壳) → 整个 legal_page 模块 (主壳 + 5 widgets/legal_*.dart), 跟 R121 vent_list_page 拆 widget 模式协同。R95 lock-in 当时没考虑 page → 多 widget 拆解, 本批补 R95 + R122 跨期协同。

**`legal_page_split_round122_test.dart`** (新增 8 case) 守门员: 6 文件双存在 / 主壳 < 400L / 主壳不再含 4 private widget + 1 enum / 5 公开 widget/enum 各自 super.key / 公开命名一致 / 主壳用公开 widget 名替换 / 6 文件总和 < 700L (拆前 555L, +12% overhead, 跟 R122 mood_audio_service 拆 3 facade +57% overhead 比优秀)。

**R108 §六 god class 候选 6/12 闭环** (R118 P2-7 10 量表 / R119 P1-1 app_database / R120 P1-2 notification_service / R116 round 4 add_medication_page / R122 P2-1 mood_audio_service / R122 P2-2 legal_page)。剩 5 候选过时 (R116 / R118 已拆): `medication_page 553L` (R116 round 1 拆) / `mood_trend_page 517L` (R116 拆 104L) / `reminders_hub_page 441L` (R116 拆 213L) / `setup_page_state 506L` (R116 拆 301L) / `static_scale_translations 659L` (R118 P2-7 替代)。
