# 04-Engineering 审计报告 — 性能 / 安全 / 可访问性 / 国际化 / 依赖安全

> 审计日期: 2026-08-16 · 版本 1.1.0+149 · 只读审计 (未修改任何代码)
> 基线: R113 修复战役刚闭环 (working tree 308 文件未 commit)
> 实测: `flutter analyze` **0 error / 0 warning / 266 info** (info 集中在 scale_strings_arb_lock_in_round95_test.dart trailing comma) · 守门员 check_strings_hardcoded / check_arb_keys / check_pii_in_title 全绿

---

## 综合评分

| 维度 | 分数 | 一句话 |
|---|---|---|
| 1. 性能 | **7.5/10** | 启动路径/列表/图表隔离已达工程标准; 发现 2 个死依赖 (dotenv 只 load 不读 / uuid 0 引用) + 1 个未接线的本地日志 sink |
| 2. 安全 | **8.0/10** | 密钥/加密/日志守卫/PII 通知全绿; 残留 key-DB 失配无恢复路径 (低概率高影响) + cancelRecording 明文 temp 不清理 (已知 P3 未闭环) |
| 3. 可访问性 | **7.0/10** | reduce-motion/触达/tooltip/对比度均达标; 图表 0 语义 (17 处 Semantics/90K LOC) + 1 处硬编码白 |
| 4. 国际化 | **8.5/10** | 3 语 ARB 同步 + 硬编码 0 + CbtPdfL10n 14 getter 全覆盖; domain 预设双源维护是既定债 (R51b v1.0) |
| 5. 依赖安全 | **7.5/10** | 版本约束齐全 + 无已知 CVE; pointycastle 3.9.1 跨大版本 + 2 死依赖 + printing 重量级包 |

**加权综合 ≈ 7.7/10**

---

## Top 10 Findings (优先级 + 难度 + file:line + 一句话)

1. **P2 · 低** `lib/core/data/services/swallow_log_sink.dart:20` — round 83 设计的 release 本地日志 sink 从未接线 (lib/ 0 caller, 仅 test 用), swallowError release 模式 100% 静默, 排查线上问题零线索
2. **P2 · 中** `lib/core/data/services/database_migration.dart:39-71` — 只处理"无 key + 明文 DB"迁移; "secure storage 有 key 但 DB 打不开" (Android 备份恢复 DB 未恢复 keystore key) 无恢复路径 → 用户卡死无法启动
3. **P3 · 低** `lib/core/data/services/mood_audio_service.dart:341-362` — cancelRecording/dispose 停止录音后不删除 `_tempRecordPath` 明文 m4a (仅置 null), 依赖 OS temp 清理, Android 不保证
4. **P3 · 低** `pubspec.yaml:53` + `lib/main.dart:17` — `uuid: ^4.5.1` lib+test 0 引用, 纯死依赖
5. **P3 · 低** `lib/main.dart:188-194` — flutter_dotenv 只 load `.env` 全项目 0 处 `dotenv.env` 读取, 启动 Future.wait 5 任务之一纯浪费 + 死依赖
6. **P2 · 中** `lib/presentation/pages/mood_list/mood_trend_page.dart` (fl_chart 全页) — 趋势/热力/月度图表 0 Semantics, 全 lib 仅 17 处 Semantics (90K LOC), 视力障碍用户无法读数据
7. **P3 · 低** `lib/presentation/pages/mood_list/mood_trend_page.dart:326` — `Colors.white` 硬编码 tooltip 文字色, 唯一一处 presentation 硬编码颜色, 违反 0 硬编码 token 规范
8. **P3 · 低** `lib/core/data/services/encryption_service.dart:82-122` — AES-256-CBC 无完整性认证 (无 HMAC/GCM), 文件被篡改不可检测 (本地 at-rest 可接受, 加固建议)
9. **P3 · 低** `pubspec.yaml:31` — pointycastle ^3.9.1 vs latest 4.0.2 跨 1 个大版本; 无已知 CVE 且 AES-CBC 路径稳定, 但长期滞后
10. **P3 · 低** `lib/l10n/app_zh.arb` (2144 key) + `lib/domain/logic/psychology_tips_library.dart` 等 — domain 预设内容 canonical 中文 + ARB override 双源, 加条目需 2 处同步 (R51b 量表 i18n 未做, v1.0 既定计划)

---

## 1. 性能 (7.5/10)

### 已验证达标 ✅
- **启动路径**: `lib/main.dart:116-133` EarlyLoadingApp 先跑 → `Future.wait` 5 任务并行 (env / timezone / migration check / notification / SharedPreferences) → `AppDatabase()` 是 `LazyDatabase` + `NativeDatabase.createInBackground` (`lib/core/data/database/connection/native.dart:40`), DB open 在后台 isolate, 首帧不阻塞; AppRoot 4 个 `addPostFrameCallback` (`lib/app.dart:105-131`) 全部首帧后执行。结构无可挑剔。
- **大列表**: `ListView(children` = **0**, `Column(children: [for` = **0**, `ListView.builder/GridView.builder/SliverList` = 12。✅
- **图表隔离**: `RepaintBoundary` 25 处, 覆盖 trend_heatmap_grid / trend_mood_chart / trend_monthly_chart / mood_trend_page。✅
- **dispose 基准**: vent_detail_page 3 个 StreamSubscription 全部 `.cancel()` (`vent_detail_page.dart:69-71`); mood_audio_recorder_widget E-01 字段缓存 (`_serviceField/_storageField` initState 捕获, 75-86 行) dispose 链无 ref.read。✅ 33/33 dispose 基准维持。
- **动画**: Motion 集中器 75 处引用 / 14 文件; `MediaQuery.disableAnimations` 6 处接线; 动画只动 transform/opacity。✅

### 发现
| # | 类型 | 难度 | 优先级 | 证据 | 描述 / 建议 |
|---|---|---|---|---|---|
| P-01 | 底层 | 低 | P3 | `lib/main.dart:188-194` | **flutter_dotenv 只 load 不读**: `_loadEnv()` 跑 `dotenv.load()`, 但全项目 0 处 `dotenv.env` / `dotenv.get` (rg 全 lib 无结果)。启动 5 并行任务之一纯开销 + `.env` 缺失时打警告日志。建议: 若无未来配置需求删依赖+任务; 若有需求补读取。 |
| P-02 | 架构 | 低 | P3 | `pubspec.yaml:53` | **uuid 死依赖**: `uuid: ^4.5.1` lib+test 0 引用。删。 |
| P-03 | 底层 | 低 | P3 | `lib/core/data/services/mood_audio_service.dart:264-295` | 100ms `Timer.periodic` 每 tick 调 `DateTime.now()`, 3min 录音 = 1800 次, 每次仅驱动计时 UI。开销可忽略, 记录在案不需修。 |

## 2. 安全 (8.0/10)

### 已验证达标 ✅
- **DB 密钥**: `db_key_service.dart:38-41` 32B `Random.secure()` → base64 → FlutterSecureStorage (iOS Keychain / Android `encryptedSharedPreferences: true`)。密钥永不落明文。✅
- **SQLCipher 接线**: `connection/native.dart:36-44` PRAGMA key 在 setup 回调 (首次 SQL 前), base64 字符集正则验证 + 单引号转义双保险。✅
- **音频加密链**: `encrypted_audio_storage.dart:147-197` encryptAndWrite try/finally 双兜底 (写 enc 失败也删明文); decryptToTemp 写 OS temp, 播放完 deleteTempFile; vent 侧 deleteAllWithRetry 3 次重试 + purgeOrphanPlainFiles 启动清孤儿明文。✅
- **日志守卫全覆盖验证**: 全 lib `developer.log` 仅 5 处 — main.dart 3 处 (78/98/257 全带 `!kReleaseMode` 守卫, 有 lock-in test) + swallow_error.dart:45 (带 `_isProduct`) + pii_safe_log.dart:56 (带 `_isProduct`)。**0 裸 log 残留** (R112 E-02 已修, 无回归)。✅
- **导出文件**: export v7 JSON 只走 `Clipboard.setData` (`export_dialog.dart`), **不落盘** — 明文 JSON 风险面 = 用户剪贴板 + 主动粘贴目标, 有风险告知 + 强制 ack + 加密 audit log (`consent_preference_store.dart:196-208` AES-256, UTC 时间戳)。风险等级: **可接受 (用户主动操作 + 三重防护)**。
- **audit log**: ConsentPreferenceStore AES-256 加密 + PIPL §47 撤回清 log + §13 grantedAt UTC 'Z'。✅
- **通知 PII**: `check_pii_in_title.py` 实测 PASS — 10 个 title/body 定义 0 PII。✅

### 发现
| # | 类型 | 难度 | 优先级 | 证据 | 描述 / 建议 |
|---|---|---|---|---|---|
| S-01 | 架构 | 中 | P2 | `lib/core/data/services/database_migration.dart:39-71` | **key-DB 失配无恢复路径**: `needsMigration()` 只看 `hasKey()`; 若 Android 备份恢复场景 (DB 文件被还原但 Keystore 里的加密 key 未还原) → 新 key 打开旧 DB 抛 SQLCipher "file is not a database" → runZonedGuarded 捕获 → 用户面对无限启动失败, 无重置/恢复入口。建议: catch SQLCipher 打开失败后弹"数据库无法解密"引导 (重置或等待备份), 与 MigrationFailedApp 同模式。低概率高影响。 |
| S-02 | 底层 | 低 | P3 | `lib/core/data/services/mood_audio_service.dart:341-362, 402-419` | **cancelRecording/dispose 不删明文 temp**: 用户取消录音 → `_recorder.stop()` 后 `_tempRecordPath = null`, 明文 m4a 留在 `Directory.systemTemp` 等 OS 清理 (iOS 自动, Android 不保证)。已知 P3 仍未闭环。建议: `File(_tempRecordPath).delete()` try/catch + audioErrorSink, 两路径 (cancel/dispose) 各 2 行。 |
| S-03 | 底层 | 低 | P3 | `lib/core/data/services/encryption_service.dart:82-122` | **AES-CBC 无完整性认证**: 无 HMAC/GCM, 密文篡改不可检测 (解密只可能失败 PKCS7 pad, 可能碰巧成功产出错误明文)。本地 at-rest 文件加密场景可接受, 属加固建议非漏洞。 |
| S-04 | 架构 | 低 | P2 | `lib/core/data/services/swallow_log_sink.dart:20-21` | **release 本地日志 sink 未接线**: 文件头写明"main.dart release 模式调 setSwallowLogSink", 但 `SwallowLogSink.create()` 在 lib/ **0 caller** (rg 确认仅 test 引用), `setSwallowLogSink` 函数也不存在。round 83 的整套"release 模式可观测性"设计 (1MB FIFO + PII 脱敏 + 诊断包) 是死代码, swallowError release 完全静默。建议: main.dart `_bootstrap()` 内 `unawaited(SwallowLogSink.create().then(setSwallowLogSink))` + swallow_error.dart 加 sink 调用 (原设计 2 行接线), 或删文件明示不做。 |

## 3. 可访问性 (7.0/10)

### 已验证达标 ✅
- **reduce-motion**: `Motion.duration/curve` 包装器 (`app_motion.dart:289-306`) + `disableAnimations` 6 处接线; _EntrySpring R113 修 (didChangeDependencies 归零) + PressFeedback/medication 打卡走 Motion.duration。✅
- **触达尺寸**: `buttonHeight 50pt / 44pt` token (`app_spacing.dart`); PressFeedbackIconButton 支持 `constraints` 强制最小 tap 区域。✅
- **IconButton tooltip**: 41 处 IconButton 全走 PressFeedbackIconButton, 抽查全部带 tooltip (37 直接匹配 + 4 个在 doc 注释/构造函数内, 无真实缺失)。✅
- **对比度**: R111/R113 已全修 — success/error/warning 状态色作文字色全部换 fgOn* 系 (cbt_three_column_mode / mood_factor_analysis / medication_detail 注释注明 ≈5.1:1 WCAG AA)。✅

### 发现
| # | 类型 | 难度 | 优先级 | 证据 | 描述 / 建议 |
|---|---|---|---|---|---|
| A-01 | 架构 | 中 | P2 | `lib/presentation/pages/mood_list/mood_trend_page.dart` (fl_chart 全页) | **图表 0 语义**: 趋势/热力/月度图表纯视觉 (fl_chart 无内置 semantics), 全 lib `Semantics(/semanticLabel/MergeSemantics` 仅 17 处 vs 90K LOC。视力障碍用户 (精神心理人群高相关) 完全无法获取趋势数据。建议: 图表容器加 `Semantics(label: <月平均情绪 X 分/趋势上升>)` + 关键数值 text alternative; 最低成本 = 每图 1 个汇总 label。 |
| A-02 | 底层 | 低 | P3 | `lib/presentation/pages/mood_list/mood_trend_page.dart:326` | **唯一硬编码颜色**: `Colors.white` tooltip 文字色 (fl_chart LineTooltipItem)。对 fl_chart 默认深灰 tooltip 底对比度 OK, 但违反 0 硬编码 token 规范 + 未来 light tooltip 主题化会破。建议: `AppTokens.fgOnPrimary(context)` 或显式声明 tooltip bg 色。 |
| A-03 | 架构 | 低 | P3 | 全局 | textScaler 0 显式引用 — 依赖 M3 默认跟随系统缩放 (行为正确); 但无大字号 golden 测试, 50pt 固定高按钮 + 200% 字号下的溢出风险未覆盖。建议: 1 个大 textScaler=2.0 widget test 冒烟。 |

## 4. 国际化 (8.5/10)

### 已验证达标 ✅
- **3 语同步**: `check_arb_keys.py` 实测 PASS — zh 2144 / en 2087 / zh_Hant 2124 key, zh_Hant 0 missing; zh vs en 差异 27 个全为 `@key` 元数据描述 (message key 0 差异, 自写脚本复核)。✅
- **硬编码扫描**: `check_strings_hardcoded.py` 实测 PASS — 规则1 = 28 处 (全部 R57 override 配对, 合法模式); 规则2 inline = 0; 规则3 domain/core = 0 (rule3-whitelist 行号精确豁免)。✅
- **CbtPdfL10n**: `cbt_pdf_l10n.dart` 14 个 getter (比 R113 报告 12 还多 2: moodLabel + originalScoreLabel) 全部委托 `AppLocalizations.of`, PDF 层 7 处调用 `cbtPdfL10n.xxx`。R113 修复验证属实。✅
- **locale**: `supportedLocales = [en, zh, zh_Hant]` (`app_localizations.dart:96-99`) + fallback 完整。✅
- **domain 预设双源模式**: canonical 中文 + `preset_content_l10n` / `localized*` override 28 配对, 模式清晰。✅

### 发现
| # | 类型 | 难度 | 优先级 | 证据 | 描述 / 建议 |
|---|---|---|---|---|---|
| I-01 | 架构 | 中 | P3 | `lib/domain/logic/psychology_tips_library.dart` + `vent_tag_library` + `status_phrase_library` + `static_scale_translations` | **预设内容双源维护债**: 加 1 条心理技巧/标签 = domain canonical + 3 语 ARB override 共 4 处同步。R51b (量表 8 套 items 全量 i18n) 未做, v1.0 既定计划。当前 28 配对守门员护着, 非回归; 长期建议 i18n 四路合一 (R113 wave 4 ruling 已明确不半修)。 |

## 5. 依赖安全 (7.5/10)

### 已验证达标 ✅
- **版本约束**: 全部 `^x.y.z` 下限约束, 0 `any`; `dependency_overrides` 锁 sqlparser 0.44.5 (drift_dev 2.34.0 兼容锁, 有注释说明)。✅
- **sqlcipher_flutter_libs 0.6.8**: ≥0.6.5 满足 Google Play 16KB page size 强制要求, 0.7.0 eol 决策有注释。✅
- **平台接口 dev_dep**: audioplayers_platform_interface / flutter_local_notifications_platform_interface 仅测试用 (depend_on_referenced_packages 合规模式)。✅

### 依赖清单逐一核对
| 包 | 版本 | 使用情况 | 判定 |
|---|---|---|---|
| uuid | ^4.5.1 | lib+test **0 引用** | ❌ 死依赖, 删 |
| flutter_dotenv | ^6.0.1 | 仅 main.dart load, 0 读取 | ❌ 死依赖, 删 (或补读取) |
| printing | ^5.13.4 | 2 文件 (medication_report_dialog 预览 + cbt_pdf_tile) | ⚠️ 重量级 native 包; 有真实预览功能, 保留合理 |
| share_plus | ^10.1.4 | 1 文件 (medication_report_dialog 分享 PDF) | ✅ |
| url_launcher | ^6.3.1 | 1 文件 (crisis_hotline tel: 一键拨打) | ✅ |
| record | ^5.2.0 | 4 文件 (mood/vent 录音) | ✅ |
| audioplayers | ^6.1.0 | 4 文件 (播放) | ✅ |
| speech_to_text | ^7.0.0 | 4 文件 (本地 STT) | ✅ |
| pointycastle | ^3.9.1 | encryption_service | ⚠️ latest 4.0.2 跨大版本, 无已知 CVE, AES-CBC 路径稳定 |

### 发现
| # | 类型 | 难度 | 优先级 | 证据 | 描述 / 建议 |
|---|---|---|---|---|---|
| D-01 | 底层 | 低 | P3 | `pubspec.yaml:31` | **pointycastle 3.9.1**: 2023 起大版本 4.x 已出, 3.9.1 是 3.x 末版。无已知 CVE (AES-CBC/PKCS7 使用路径简单稳定), 但迁移 4.x 属纯机械重构 (API 名变化), 建议列入 v1.0 计划窗口, 不在近期急。 |
| D-02 | 架构 | 低 | P3 | `pubspec.yaml:53,54` | uuid + flutter_dotenv 2 死依赖 (见 P-01/P-02), 双维度计 1 次。删依赖同时减启动任务 + 包体。 |
| D-03 | 底层 | 低 | P3 | `pubspec.yaml:25` | sqlcipher_flutter_libs 锁 0.6.x 长期内核滞后 (0.7.0 eol 不升级决策)。SQLCipher 4.5.x 无已知漏洞, 但需在 v1.0 前复查上游 0.7 后续/替代包 (sqlcipher 5.x)。 |

---

## 统计摘要

| 维度 | 发现数 | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| 性能 | 3 | 0 | 0 | 0 | 3 |
| 安全 | 4 | 0 | 0 | 2 | 2 |
| 可访问性 | 3 | 0 | 0 | 1 | 2 |
| 国际化 | 1 | 0 | 0 | 0 | 1 |
| 依赖安全 | 3 | 0 | 0 | 0 | 3 |
| **合计** | **14** | **0** | **0** | **3** | **11** |

**0 P0** — R113 修复战役的代码级成果全部实锤 (dispose 链 / reduce-motion / PII 通知 / PDF l10n / 日志守卫 / 导出 v7)。

## 优先修复清单 (低到高成本)

1. **30 分钟**: 删 uuid + flutter_dotenv 死依赖 (P-01/P-02/D-02) — 顺手删 `_loadEnv()` 启动任务
2. **1 小时**: SwallowLogSink 接线 2 行 (S-04) — round 83 设计复活, 线上排查能力从 0 到 1
3. **1 小时**: cancelRecording/dispose 删明文 temp (S-02) — PIPL §28 收口最后一角
4. **2 小时**: mood_trend_page Colors.white → token (A-02) + 图表 Semantics label (A-01)
5. **0.5 天**: DB key 失配恢复路径 (S-01) — DatabaseMigration 加"打不开的 DB"检测 + 引导页
6. **v1.0 窗口**: pointycastle 4.x 迁移 + R51b 量表 i18n + AES 完整性认证 (HMAC) 评估

## 审计方法

- 逐文件读: main.dart / app.dart / db_key_service / mood_audio_service / mood_audio_storage / vent_audio_storage / encrypted_audio_storage / encryption_service / pii_safe_log / swallow_error / swallow_log_sink / consent_preference_store / export_orchestrator / export_crypto_service / app_motion / database_migration / connection/native / mood_audio_recorder_widget / vent_detail_page
- 实测: flutter analyze (0e/0w/266i) · check_strings_hardcoded PASS · check_arb_keys PASS · check_pii_in_title PASS (10 title/body 0 泄漏)
- Grep 扫描: ListView(children)=0 · RepaintBoundary=25 · developer.log=5 (全带守卫) · Semantics=17 · IconButton tooltip 41/41 · uuid/dotenv/share_plus/url_launcher/printing 引用面
- ARB 自写脚本复核: zh/en/zh_Hant message key 0 差异 (仅 @metadata 差异)
