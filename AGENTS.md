# AGENTS.md

> 给 AI 编程 Agent 看的项目指引。先读 README.md 看产品视角，再读这份看代码视角。

## 项目速览

**产品**：精神心理患者吃药打卡 App（参考"死了么"模式做私域加强版）。

**栈**：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6。

**核心特性**：本地加密、零云端、4 层架构（`presentation → domain ← data`）+ 共享层（`shared/`）。

## 4 层架构 + 共享层

**v0.18 (round 12 之后):** `data/shared/theme/routing/l10n` 5 个子层并入 `lib/core/`
作为 umbrella。所以实际是 **5 层 + 共享 umbrella**:
- `lib/core/data/` — 基础设施(Database / Repositories / Services)
- `lib/core/shared/` — 跨层共享(formatters / json_codec / mood_visual)
- `lib/core/theme/` — AppTokens + M3 主题
- `lib/core/routing/` — go_router
- `lib/core/l10n/` — domain 层 strings(供通知/邮件用)
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
│   │   │   ├── tables/   # 1 个表 = 1 子目录（check_in/, contact/, ...）
│   │   │   ├── mappers/  # row ↔ entity 翻译（1 文件 1 mapper）
│   │   │   ├── connection/  # conditional import (web / native)
│   │   │   └── app_database.dart
│   │   ├── repositories/  # *RepositoryImpl（按 feature 平铺, 计划按 feature 子目录）
│   │   ├── services/     # 通知/邮件/SMS/录音/导出/加密
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
│   └── l10n/              # domain 层 strings（通知/邮件 fallback）
│       └── strings.dart
├── l10n/                  # presentation 层 flutter_localizations
│   ├── app_zh.arb         # 中文文案源
│   ├── app_en.arb         # 英文文案源
│   ├── app_localizations.dart
│   ├── app_localizations_zh.dart
│   └── app_localizations_en.dart
├── domain/                # 0 Flutter 0 Drift 业务层
│   ├── entities/         # *Entity 后缀
│   ├── logic/            # 业务规则（量表/streak/care engine/报告/email 模板）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例（业务编排）
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers（按职责拆 3 文件）
    │   ├── core_providers.dart   # DB + 基础服务 + 7 个 repo
    │   ├── service_providers.dart  # reminder / safety / assessment / data export
    │   └── vent_providers.dart   # vent audio + entries
    ├── pages/             # 1 个页面 = 1 个目录（按 feature 拆 8 个）
    │   ├── home/         # 主页（打卡 / 庆祝 / mood / vent 入口）
    │   ├── setup/        # 首次设置（4 步：consent / welcome / medication / done）
    │   ├── settings/     # 设置（含 settings/widgets/ 子组件 + reminders_hub）
    │   ├── trend/        # 趋势（list + calendar 视图）
    │   ├── assessment/   # 心理评估（答题 + 历史 + 提醒 section）
    │   ├── check_in/     # 打卡按钮
    │   ├── contact/      # 紧急联系人列表
    │   ├── medication/   # 用药（calendar / refill / today / report / dialogs）
    │   ├── mood/         # 情绪（dialog + quick button）
    │   └── vent/         # 树洞（list / compose / detail）
    └── widgets/           # 通用组件
        ├── page_scaffold.dart
        ├── app_snack_bar.dart
        ├── loading_skeleton.dart  # 统一 loading（fullScreen / card / Spinner）
        ├── secondary_button.dart
        ├── press_feedback.dart    # v0.18: 按钮 :active scale 反馈
        └── animations/    # 通用动效（FadeIn / SlideUp）
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
2. `lib/core/data/database/app_database.dart` — schemaVersion 当前 12，所有表 + migration
3. `lib/domain/logic/care_engine.dart` — 失联检测 / 续方 / 通知触发核心规则
4. `lib/presentation/providers/core_providers.dart` — 全局 provider 注册表
5. `lib/routing/app_router.dart` — 所有页面路由 + shell（NavigationRail）

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
flutter test       # 必须全过（当前 2019 cases, v0.30 R107 cleanup 后）
python scripts/check_cross_feature.py  # 必须 0 violation (跨 feature import 检查)
```

## 隐私边界

以下模块**严禁**互相渗透：

| 模块 | 进什么 | 不进什么 |
|---|---|---|
| 树洞（vent） | 无 | 趋势 / 评估 / CareEngine / SafetyWatch / 通知 / 关怀 |
| 情绪日记（mood） | mood-specific reports | 通知（v0.15 之后可加） |
| 心理评估（assessment） | 评估历史趋势 | 失联通知（除非 CrisisSignal） |
| 打卡（check-in） | streak / 趋势 | 评估 |
| 失联通知（SafetyWatch） | 通知家人 | 内部 detail（仅 SMS） |

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

**8 FeatureFlag 当前状态 (R108, 同 R107)**:
1. `iapEnabled=false` (等 App Store Connect 真接)
2. `emergencyContactEnabled=false` (等阿里云 AccessKey)
3. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月审核)
4. `emailServiceEnabled=false` (等 SendGrid API key)
5. `ventAudioEnabled=**true**` (R104 已翻 true)
6. `phqGad7I18nEnabled=false` (等法务 + 临床审核)
7. `bootReceiverEnabled=false` (等 WorkManager 完善)
8. `aliyunSmsEnabled=false` (等 AccessKey)

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

**18 守护脚本清单** (v0.30 R107 cleanup 修正, v0.30 R95 加 `check_coverage.py` 后总数 18 = 17 .py + 1 .dart):
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
12. `python scripts/check_legal_consent.py` — **v0.26 R57 新增** — 单独同意 / PIPL §13 / §14 检测
13. `python scripts/check_sms_release_ready.py` — **v0.26 R57 新增** (v0.27 R58 降为 warn-only) — SMS 上线前 checklist
14. `python scripts/check_strings_hardcoded.py` — **v0.26 R57 新增** — 硬编码中文 string 检测
15. `python scripts/check_zh_hant_consistency.py` — **v0.26 R57 新增** — 繁简一致性 (OpenCC s2tw)
16. `python scripts/check_16kb_alignment.py` — **v0.28 R77 新增** (v0.30 R92 文档补) — Android 16KB page size 验证 (Google Play 2025-11-01 强制)
17. `python scripts/check_coverage.py` — **v0.30 R95 新增** — 覆盖率阈值 (domain ≥ 70% / data ≥ 50% / presentation ≥ 30%)
18. `dart scripts/check_all.dart` — 4 层架构纯度 + 一致性

**待办 (外部依赖, 非本批)**:
- R55 真接阿里云 SMS (依赖法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
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
- `docs/SENDGRID_SETUP.md` — 邮件服务配置
- `AGENTS.md` — 本文件（代码视角）
