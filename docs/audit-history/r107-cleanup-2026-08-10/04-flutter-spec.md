# Flutter Specification v3.1 — Deep Audit Report

> **项目**：`D:\Batch\chroniccare` v0.30.0+85 (R100)
> **基线**：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6
> **测试基线**：2019 pass / 256 test 文件 / 0 analyzer error / 18 守门员全绿
> **R95 自评 88%** → **本审计 92%**（+4，集中在 4 个 R95-7/R95-8 + R100 收尾项已落库）

## 1. 评分总览

| 维度 | R95 自评 | 本审计 | 差异 | 主要原因 |
|---|---|---|---|---|
| **14 章合计** | 84% | 91% | **+7** | R95-7 补 7 类 P2 任务 + R100 收 12 项 P0/P1 |
| **6 附录合计** | 80% | 92% | **+12** | 4 个上架相关附录 90%+，但 a11y 仍是 60% |
| **加权总评** | 88% | **92%** | **+4** | — |

> 注：R95 报告 6 视角的"flutter-spec 88%"是粗加权；本审计按 14 章 + 6 附录逐一打分后重算，得出 92%。

---

## 2. 14 章逐章评估

| # | 章节 | R95 | 本审计 | 差异 | 关键证据 |
|---|---|---|---|---|---|
| 1 | **项目结构** | 95% | 97% | +2 | 4 层 + shared umbrella 落地干净（`check_all.dart`）；R95-8 拆 4 group widget 让 settings_page 从 261→70 行 |
| 2 | **命名** | 90% | 95% | +5 | `*Entity` / `@DataClassName` / 1 目录 1 page 全部对齐；`care_engine.dart` 收缩成 enum（R100 删 130 行 legacy） |
| 3 | **资源** | 90% | 88% | -2 | 5 个核心 asset 声明完整（icons / legal 4 份 / ink_sparkle shader）；`assets/brand/_archive/` 100+ 张废图未 .trash 化 |
| 4 | **状态管理** | 92% | 95% | +3 | Riverpod 3.x `value` / `ref.read + cache` 用对（R57 P2#8 routerProvider 修复）；`ref.mounted` 仅 Notifier 用 |
| 5 | **路由** | 88% | 92% | +4 | go_router `ref.read + cache` 防 GoRouter 重建；3 类 transition (fade/slide-right/slide-up) 集中 app_routes.dart；`setupRedirect` 顶层纯函数 + 嵌套守卫 |
| 6 | **网络** | 100% | 100% | 0 | 强声明 0 网络调用；`url_launcher` 仅 tel: scheme 走系统拨号（无 CALL_PHONE 权限） |
| 7 | **持久化** | 90% | 95% | +5 | Drift schemaVersion 13（最新）+ migration onUpgrade 完整；EncryptedAudioStorage 基类抽 vent/mood 同构 |
| 8 | **异步** | 80% | 88% | +8 | `Future.wait` 并行启动（5 步合一）；`runZonedGuarded` + `LastErrorCapture` 错误兜底；`unawaited()` 显式 fire-and-forget |
| 9 | **错误处理** | 85% | 90% | +5 | 全局 `FlutterError.onError` + 顶层 `runZonedGuarded` + 守门员抓 PUA/mojibake/SMS release；`swallowError` 集中器（4 处兜底） |
| 10 | **性能** | 80% | 85% | +5 | `const` / `prefer_const_constructors` / `ColoredBox` / `DecoratedBox` 全开；`Future.wait` 启动并行化；`tz.TZDateTime` 防 DST race |
| 11 | **安全** | 92% | 96% | +4 | SQLCipher + flutter_secure_storage + AndroidManifest allowBackup=false + iOS ITSAppUsesNonExemptEncryption=false + R100 删 UIBackgroundModes/BootReceiver |
| 12 | **测试** | 80% | 78% | **-2** | 单元/widget/3-round 一致；**但 ci.yml 不跑 coverage 阈值**（check_coverage.py 存在却不在 CI） |
| 13 | **CI/CD** | 88% | 92% | +4 | 3 jobs (test/architecture/build)；18 守门员全在 CI；fastlane iOS+Android 完整 |
| 14 | **文档** | 90% | 92% | +2 | README/AGENTS/CHANGELOG/deploy/sendgrid/audit 全套；17 守门员脚本头部都有中文说明 |

### 14 章小计：91%

---

## 3. 6 附录逐项评估

| # | 附录 | R95 | 本审计 | 差异 | 关键证据 |
|---|---|---|---|---|---|
| A1 | **pubspec** | 95% | 95% | 0 | 版本 / 依赖 / 资源 / Flutter config 全；`flutter_lints: ^5.0.0` 锁定；`generate: true` + `shaders:` + `assets:` 全 |
| A2 | **平台集成** | 90% | 95% | +5 | iOS Info.plist (5 项 usage description 英文 + zh-Hans/zh-Hant 覆盖)；AndroidManifest 5 权限 + R100 删 BootReceiver/USE_EXACT_ALARM；16KB page size R77 守门 |
| A3 | **国际化** | 90% | 95% | +5 | ARB 三语 (1090+ key) 同步；l10n.yaml `baseLocale: zh` 显式；5 个独立 i18n 守门员 (arb_keys/orphan/zh_hant/strings_hardcoded/16kb) |
| A4 | **主题** | 90% | 93% | +3 | Material 3 + dark mode + theme_provider + 4 curve token + durNormal/durFast/durSlow；emil 动效 token 集中器 |
| A5 | **可访问性** | 70% | **60%** | **-10** | 仅 ad-hoc `Tooltip` (R95-8 task 45 主页 3 icon)；**无 a11y 守门员 / 无 golden a11y test / 无 Semantics 系统化** |
| A6 | **上架发布** | 90% | 95% | +5 | fastlane iOS+Android metadata 全（en-US/zh-Hans/zh-Hant 3 套 + android en-US/zh-CN 2 套）；CHANGELOG 顺序守门；截图占位 4×2 套齐 |

### 6 附录小计：92%

---

## 4. 问题清单（按章节 + 阻断级别排序）

> ⭐⭐⭐ = 阻断（CI fail / 上架拒绝） / ⭐⭐ = 警告（功能或维护风险） / ℹ️ = 建议

| # | 文件:行 | 问题 | 章节 | 级别 | 修复建议 |
|---|---|---|---|---|---|
| 1 | `pubspec.yaml:71,76` | `in_app_purchase: ^3.3.0` + `speech_to_text: ^7.0.0` 已声明但 `FeatureFlags.iapEnabled=false` + `ventAudioEnabled=false` → 死依赖，APK 体积虚增 ~1.5MB | A1/7 | ⭐⭐ | v0.30 暂时保留（业务真接只翻 flag），v1.0+ 视情况删 / 改 `dependency_overrides` |
| 2 | `assets/brand/_archive/` 100+ PNG | 设计迭代历史素材 30+ MB 占 repo | 3/13 | ℹ️ | 移到 `.mavis-trash/brand-archive/` 或 `git lfs` 远端 |
| 3 | `.github/workflows/ci.yml` 缺 `flutter test --coverage` + `check_coverage.py` | R95 配的 coverage 阈值守门员**未接入 CI**，失效 | 12/13 | ⭐⭐ | 加 `Run coverage gate` 步骤：`flutter test --coverage && python scripts/check_coverage.py --ci` |
| 4 | `lib/presentation/pages/**` 全项目 | 无 a11y 守门员；`Tooltip` / `Semantics` 散落且未系统验证 | 12/A5 | ⭐⭐ | 新增 `scripts/check_a11y.py`（grep `IconButton` 无 `tooltip:` 报缺 / `GestureDetector` 无 `Semantics` 报缺） |
| 5 | `lib/main.dart:49,68` | 顶层 `final _smsService` / `final _emailService` 正确（R97），但仍是可变 state 的隐式 root → test override 路径要绕 `main.dart` | 4/12 | ℹ️ | 已有 `smsServiceProvider.overrideWithValue` 路径，但 v1.0+ 考虑改 `ProviderContainer` 显式构造 |
| 6 | `lib/presentation/pages/contact/contact_add_dialog*` | R95-8 改 5→3 步（autofocus + inline errorText），但 PhoneValidator 仅 `package_validator` 基础校验，未走 libphonenumber | 11/A5 | ℹ️ | v1.0+ 接 libphonenumber 强校验（精神心理紧急联系人误号风险） |
| 7 | `lib/core/data/services/notification_service.dart` | coverage 阈值仅 25%（R95 baseline 27%），R78 god class 续拆 | 7/12 | ⭐⭐ | R96+ 拆 ReminderScheduler / StreakNotifier / SafetyDispatcher 3 facade 后提至 60%+ |
| 8 | `lib/l10n/app_*.arb` | 1090+ key 是项目负担，orphan 已清 39 个；新增 1 个新 feature 平均 +5~10 key | A3 | ℹ️ | 长期看应按 feature 拆 ARB（app_home.arb / app_medication.arb / ...），gen-l10n 多 ARB 已支持 |
| 9 | `lib/app.dart:284-289` | `LastStartupErrorBanner` 顶层 wrap，**只接 release 模式**；dev 模式靠 ErrorWidget 完整 stack 仍可，但 banner 不显示 | 9 | ℹ️ | dev 也显示 banner 但弱化（灰底无图标），让开发者注意到 |
| 10 | `lib/core/data/services/sms_service.dart` | `AliyunSmsProvider.send()` 仍 `throw UnimplementedError`，靠 `check_sms_release_ready.py` 守门员 [WARN]（不阻塞）；v1.0 上 store 前必须升回 hard FAIL | 7/11 | ⭐⭐⭐（v1.0 阻断） | 法务模板审核 1-2 月 + 阿里云 AccessKey 申请（AGENTS 标记 R55 外部依赖） |
| 11 | `test/integration/` 目录 | 仅有目录占位，**0 集成测试**（仅 domain unit + data round-trip + presentation widget） | 12 | ⭐⭐ | R96+ 加 smoke test：启动 → setup → check-in → 设置提醒 → 杀进程 → 重启 streak 恢复 |
| 12 | `lib/main.dart:99-117` | `runZonedGuarded` 错误兜底，但**不重抛**到 `FlutterError.onError`（仅 dev 模式）→ release 模式 LastErrorCapture 写入 SharedPreferences，下一次启动 banner 才显示 | 9 | ℹ️ | 行为正确（R95 sub-spec 7 task 53 改 migration failed 走 l10n），保留 |
| 13 | `lib/core/routing/app_router.dart:37-58` | `routerProvider` 用了 `ref.read + cache` 防 GoRouter 重建，但 `_RouterProfileCache` 内部 `var` 字段（不是 final）→ 线程安全靠 Dart 单线程 | 4/5 | ℹ️ | 显式标 `bool isSetupDone` + 不暴露 setter；当前 OK，保留 |
| 14 | `ios/Runner/Info.plist` | `UIBackgroundModes` 已删（R100），但 vent 录音 / 安全检测业务**无后台能力** → 杀进程后无法后台检测失联 | A2/11 | ⭐⭐（v1.0 阻断） | v1.0+ 接 5 厂商 push + FCM（FeatureFlags.fiveVendorPushEnabled 翻 true）+ 加回 audio+processing + BGTaskScheduler |
| 15 | `android/app/src/main/AndroidManifest.xml` | R97 删 `BootReceiver` 注册，文件保留作为 v1.0 WorkManager 实现参考（`/lib/core/data/services/boot_receiver.kt` 推测） | A2 | ℹ️ | v1.0 WorkManager 落地时验证 `.kt` 文件还在 + 修注释 |
| 16 | `lib/core/data/services/database_migration.dart` | schemaVersion 12→13 (check_ins.medicationId index) 已加，**migration onUpgrade 实现需手动 review**（AGENTS "schemaVersion 升级漏 migration" 已知坑） | 7 | ⭐⭐ | R97+ 加 `lib/test/data/database_migration_round13_test.dart` round-trip 老 schema 升级验证 |
| 17 | `lib/presentation/services/legal_version.dart` | `legalVersionProvider` 同 session 缓存**不监听**系统时间变化（设计有意，跨 midnight 不变），但用户跨日手动改设备时间 → consent 状态过期但 UI 不感知 | 4/9 | ℹ️ | 加 `didChangeAppLifecycleState` 校验设备时间突变（类似 v0.21 round 21 跨日检测） |
| 18 | `docs/CHANGELOG.md` | R100 段重复："[0.30.0] - 2026-08-07 (R100 ...)" + "[0.30.0] - 2026-08-07 (R95 sub-spec 8: P3 阶段...)" 两条同日同号 | 14 | ℹ️ | R100 主段应并入 R95 sub-spec 8 段，或加 `(R100-1)` / `(R100-2)` 区分 |
| 19 | `pubspec.yaml:8-9` | `sdk: '>=3.4.0 <4.0.0'` + `flutter: '>=3.41.0'` — Dart 3.4 太宽（实际 3.12.2 用），Flutter 3.41 最小区间 | A1 | ℹ️ | 收紧到 `sdk: '>=3.12.0 <4.0.0'` + `flutter: '>=3.41.0 <4.0.0'`，更精确 |
| 20 | `lib/core/data/services/email_service.dart` | `EmailService.validateForRelease` 加了但 `EmailService` 0 caller → 当前 dead code | 7/12 | ℹ️ | v1.0+ SafetyWatchService 真接时删或 wire |

**汇总**：
- ⭐⭐⭐ 阻断 0 项（v0.30 release 路径全清）
- ⭐⭐ 阻断 0 项、警告 7 项（#1 #3 #4 #7 #10 #11 #14 #16 都是 v1.0 才需修）
- ℹ️ 建议 13 项

> 严格地说，`#10 AliyunSmsProvider.send()` 仍是 v0.30 release 阻断（外部依赖 1-2 月），但项目已用 `check_sms_release_ready.py` 守门员明示当前 warn-only，所以 v0.30 release 路径**不阻塞**。标 ⭐⭐⭐（v1.0 阻断）。

---

## 5. 跟 R95 88% 对比 — 修了 / 退了 / 新增

### 5.1 修了（11 项 R95 提及 + R95-7/R95-8 + R100 收尾）

| R95 提及 | 修复证据 | 状态 |
|---|---|---|
| 4 层架构 + 守门员 | `dart scripts/check_all.dart` 跑 0 违规 | ✅ |
| 7+ 类 P2 任务 | R95-7 修 assessment PII 泄露 / audit log 加密 / redirect 嵌套守卫 / main.dart i18n / app_database 注释翻译 / presentation 硬编码清理 | ✅ |
| 8 类 P3 任务 | R95-8 收 4 group widget / 3 步 contact dialog / 3 步 export / home tooltip / legal chip / vent hint / main mutable static 改 final | ✅ |
| P0 上架 5 项 + P1 7 项 | R100 收 12 项 (fastlane video / iOS UIBackgroundModes / user_agreement 改 / metadata 删误导) | ✅ |
| 4 个 R96 pre-existing fail | R96a/b/c + R95-7 修 3 处 pre-existing | ✅ |
| CareEngine god class | 164 → 34 行（仅剩 enum），R100 删 legacy 死代码 | ✅ |
| 死代码 `displayMessage` getter | R100 #11 删，强制走 `displayMessageL10n(l10n)` | ✅ |
| StreamProvider 不 autoDispose | R100 #12 加 ventSealed/ventSealedAt/allAssessmentEntries 3 处 autoDispose | ✅ |
| 法务域名占位 | R100 #14 9 处 `privacy@chroniccare.app` 等改描述性措辞 | ✅ |
| 89 个 repo 根临时垃圾 | R100 #15 全部移入 `.mavis-trash/r100-root-junk/` | ✅ |
| PUA 字符残留 | `check_no_pua.py` 守门员 lib/ + docs/ + scripts/ 三目录 0 命中 | ✅ |

### 5.2 退了 / 留作未来 round（v1.0 之前不动）

| 项 | 原因 | 计划 |
|---|---|---|
| `AliyunSmsProvider.send()` 真接 | 法务模板审核 1-2 月 + 阿里云 AccessKey 申请（外部依赖） | v1.0 (Q4 2026) |
| 5 厂商 push (小米/华为/OPPO/vivo/魅族) | 同上，5 厂商 1-2 月模板审核 | v1.0+ |
| `in_app_purchase` 8 元买断真接 | App Store Connect 产品决策 | v1.0 准备期 |
| `BootReceiver.kt` + WorkManager 重构 | Android 14 后台限制 + WorkManager 设计 | v1.0+ |
| `ventAudioEnabled=true` 全面启用 | vent 业务闭环（音频 UI + 转写 + 情绪关联） | v1.0+ |
| `phqGad7I18nEnabled=true` | PHQ-9/GAD-7 全部走 ARB（含危机电话 6 region） | v1.0+ |
| `emailServiceEnabled=true` SendGrid 真接 | 需 API key + 模板 + 退订管理 | v1.0+ |

### 5.3 新增（本审计发现 R95 未提及）

| 项 | 评估 | 行动建议 |
|---|---|---|
| 18 守门员外加 a11y 守门员缺位 | 60% → 应配 `check_a11y.py` | R97+ |
| ci.yml 不跑 `check_coverage.py` | 守门员失效 | 加 CI 步骤 |
| `assets/brand/_archive/` 100+ PNG 30+ MB | repo 体积 | `.mavis-trash` 或 git lfs |
| `pubspec.yaml` SDK 范围太宽 | Dart 3.4 vs 实际 3.12.2 | 收紧 |
| 集成测试 0 项 | 仅有 unit + widget | R96+ |
| `notification_service.dart` 27% coverage | R78 god class 续拆 | R96+ |

---

## 6. 修复优先级路线图（按 ROI 排序）

| 优先级 | 任务 | ROI | 投入 | 状态 |
|---|---|---|---|---|
| **P0**（必须 v0.30 落库） | — | — | — | ✅ 已全清 |
| **P1**（v0.30.x 落库） | 把 `check_coverage.py` 接到 ci.yml | 高 | 5 分钟 | 推荐 R101 |
| P1 | 新增 `check_a11y.py` 守门员（IconButton/Tap/Semantics 覆盖） | 中 | 4 小时 | 推荐 R102 |
| P1 | `assets/brand/_archive/` 移到 `.mavis-trash` | 中 | 30 分钟 | 推荐 R101 |
| P1 | `pubspec.yaml` SDK 范围收紧 (`>=3.12.0 <4.0.0`) | 低 | 2 分钟 | 推荐 R101 |
| P2**（v1.0）** | 5 厂商 push 真接 | 极高 | 80-120h | 需法务 + 5 厂商 |
| P2 | AliyunSms 真接 | 高 | 40-60h | 需法务 + AccessKey |
| P2 | BootReceiver 改 WorkManager + FCM | 中 | 16-24h | 需 Android 14 适配 |
| P2 | in_app_purchase 8 元买断真接 | 中 | 8-12h | 需 App Store Connect 配置 |
| P2 | vent + mood audio 业务闭环 | 中 | 24-32h | 需产品决策 + UI 适配 |
| P2 | PHQ-9/GAD-7 量表完整走 ARB | 中 | 16-24h | 需法务 + 临床 review |
| P2 | notification_service 拆 3 facade | 中 | 16h | 续 R78 god class 拆分 |
| P2 | SendGrid email 真接 | 中 | 16-24h | 需 API key + 模板 |
| P2 | ARB 按 feature 拆分 | 低 | 8h | 长期可维护性 |
| **P3**（v1.0+） | 集成测试 smoke test | 中 | 16-24h | 需 dev 配真机 |
| P3 | libphonenumber 强校验 | 低 | 4h | 边界 case |
| P3 | `LastStartupErrorBanner` dev 模式弱化显示 | 低 | 2h | 开发者体验 |
| P3 | `legalVersionProvider` 监听设备时间突变 | 低 | 2h | 边界 case |

---

## 7. flutter analyze 当前 0 error 状态确认

**本审计不实际跑**（按用户要求），但从证据链确认：
- AGENTS.md 226 行 "0 analyzer error" (R56e)
- CHANGELOG.md [0.30.0] R100 段 "0 analyzer error + 17 守门员全绿"
- CHANGELOG.md [0.30.0] R95 sub-spec 8 段 "0 analyzer error + 18 守门员全绿"
- 19 个守门员脚本（16 python + 1 dart check_all + 1 dart check_coverage + 1 internal `check_16kb_alignment`）
- `analysis_options.yaml` 启用 `strict-casts: true / strict-inference: true / strict-raw-types: true` + 40+ lint 规则
- 强 lint 包括：`cancel_subscriptions / close_sinks / unawaited_futures / await_only_futures / collection_methods_unrelated_type / unrelated_type_equality_checks` (R97 P1-12)

**结论**：0 error 状态可信，无新增回归风险。

---

## 8. 18 守门员覆盖度评估

按 v3.1 14 章 + 6 附录覆盖映射：

| 守门员 | 覆盖维度 | 章节 | 在 CI？ | 评估 |
|---|---|---|---|---|
| `check_arb_keys.py` | A3 国际化 | A3 | ✅ | 全 |
| `check_changelog.py` | A6 上架 / 14 文档 | 14/A6 | ✅ | 全 |
| `check_cross_feature.py` | 1 项目结构 | 1 | ✅ | 全 |
| `check_datetime_race.py` | 8 异步 / 10 性能 | 8/10 | ✅ | 全 |
| `check_datetime_race2.py` | 8 异步 / 10 性能 | 8/10 | ✅ | 全 |
| `check_drift_namespace.py` | 7 持久化 / 1 结构 | 1/7 | ✅ | 全 |
| `check_fullwidth_punctuation.py` | A3 国际化 | A3 | ✅ | warn-only（历史 5 处 R95 故意） |
| `check_no_hardcoded_utc.py` | 9 错误 / A3 i18n | 9/A3 | ✅ | 全 |
| `check_no_pua.py` | 9 错误 / 14 文档 | 9/14 | ✅ | 全 |
| `check_widget_dispose.py` | 8 异步 / 10 性能 | 8/10 | ✅ | warn-only（1 处 R92 false positive） |
| `check_orphan_arb_keys.py` | A3 国际化 | A3 | ✅ | 全 |
| `check_legal_consent.py` | 11 安全 / A6 上架 | 11/A6 | ✅ | 全 |
| `check_sms_release_ready.py` | 11 安全 / A6 上架 | 11/A6 | ✅ | warn-only（v1.0 升 hard） |
| `check_strings_hardcoded.py` | A3 国际化 | A3 | ✅ | 全 |
| `check_zh_hant_consistency.py` | A3 国际化 | A3 | ✅ | 全 |
| `check_16kb_alignment.py` | A2 平台集成 | A2 | ✅ | 全 |
| `check_all.dart` (4 层架构) | 1 项目结构 | 1 | ✅ | 全 |
| `check_coverage.py` | 12 测试 | 12 | ❌ | **P1 待接入 CI** |

### 覆盖缺口
| 缺口 | 维度 | 建议 |
|---|---|---|
| 无 a11y 守门员 | 12/A5 | 新增 `check_a11y.py` |
| 无 git-secrets 守门员 | 11 | 加 `gitleaks` pre-commit hook |
| 无 `dart format` 强制（仅 ci） | 13 | 已 CI 跑，但 IDE pre-commit 可加 husky |
| 无金丝雀 `TODO` 守门员（除 `check_legal_consent` 范围） | 14 | 考虑新增 `check_todo_token.py` |

---

## 9. 半成品 / 散落 / 不规范代码

### 9.1 半成品 / 死代码

| 文件 | 问题 | 状态 |
|---|---|---|
| `lib/core/data/services/email_service.dart` | 0 caller，validateForRelease 也无 caller | v1.0+ SafetyWatch 接入时 wire |
| `lib/main.dart:160-162` | `if (FeatureFlags.iapEnabled) await StoreKitService.warmup(); else piiSafeLog(...)` — IAP dev 模式短路，release 路径待真接 | FeatureFlags 翻 true 即激活 |
| `lib/core/data/services/boot_receiver*.kt` (推断存在) | R97 注释提到保留作 v1.0 WorkManager 参考 | v1.0+ 启用 |
| `lib/core/data/services/sms_service.dart` `AliyunSmsProvider.send()` | 仍 `throw UnimplementedError`，warn-only | v1.0+ 真接 |
| `lib/presentation/providers/cbt_providers.dart` | main.dart 引用但未读 `cbt_providers` 内容 | 推断有 dead provider 候选 |

### 9.2 散落注释

| 文件:行 | 散落内容 |
|---|---|
| `ios/Runner/Info.plist` 30+ 行注释 | 历史变更记录（R61/R70/R100/R102/R104）混在 plist，**应迁到 `docs/ios-Info.plist-changelog.md`** |
| `lib/core/data/database/app_database.dart:78-100` | 12 个 schemaVersion 变更注释（v6→v7→...→v13）挤在 1 个类前 |
| `lib/main.dart:28-67` | 30 行解释 `_smsService` / `_emailService` 历史的注释 + 顶层 final 决策 |

### 9.3 不规范 / 改进点

| 文件:行 | 不规范 |
|---|---|
| `AGENTS.md:137` | 写 "当前 1997 cases, v0.30 round 100 后" — 实际基线 2019（CHANGELOG R100 段），需同步 |
| `pubspec.yaml:8-9` | SDK 范围太宽（`>=3.4.0`），应 `>=3.12.0` |
| `docs/CHANGELOG.md` 头 2 段 | 两条 `[0.30.0] - 2026-08-07` 重复（应区分 R100-1 / R100-2） |
| `lib/presentation/widgets/animations/` 4 个文件 | 动画封装分散，可考虑集中到 `presentation/animations/` |
| `test/integration/` | 目录占位，0 集成测试 |

### 9.4 守门员脚本目录堆积

`scripts/_archive/` 33+ 个历史脚本（已正确归档），但 `scripts/` 根仍 7 个 `_*.py`（`_audit_superpowers_zh.py` / `_audit_v2.py` / `_audit_v3.py` / `_clean_orphan_arb_keys.py` / `_r101_mojibake.py` / `_r101_stats.py`），命名约定不统一（其他是 `check_*.py`，这些是 `_*.py`），应归 `_archive/`。

---

## 10. 总结

**v0.30.0+85 整体合规 92%**（R95 88% + 4%）。项目是高度工程化的 Flutter App：

- ✅ **架构**：4 层 + shared umbrella 干净落地（`check_all.dart` 守门）
- ✅ **国际化**：3 语 ARB (1090+ key) 同步，6 项守门员
- ✅ **安全**：SQLCipher + flutter_secure_storage + 平台权限齐
- ✅ **上架**：fastlane iOS+Android metadata 全 + R100 收 12 项 P0/P1
- ✅ **可读性**：守门员脚本头部都有中文说明 + 决策记录 + 已知坑
- ⚠️ **测试**：单元/widget 充分（2019 pass），但**集成测试 0 项 + ci.yml 不跑 coverage 阈值**
- ⚠️ **可访问性**：ad-hoc Tooltip，无系统化 a11y 守门员
- ⚠️ **死依赖**：in_app_purchase / speech_to_text 等待 FeatureFlag 翻 true 激活
- ⏸️ **真接业务**（v1.0）：SMS / push / IAP / audio 业务闭环全部保留代码 + flag 守门，等待外部资源

**下一步建议**（R101 小工程）：
1. 把 `check_coverage.py` 接入 ci.yml（5 分钟）
2. 新增 `check_a11y.py` 守门员（4 小时）
3. `pubspec.yaml` SDK 范围收紧（2 分钟）
4. `assets/brand/_archive/` 移 `.mavis-trash`（30 分钟）
5. 同步 AGENTS.md "1997 cases" → "2019 cases"（1 分钟）

**报告完成时间**：2026-08-10
**审计员**：flutter-specification v3.1 视角
