# 底层逐行 (bottom-up) 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: **bottom-up** (底层逐行 bug 扫描)
- 审视者: subagent-bottom-up
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71 (R100), working tree=30+M 26D (R108 进行中)
- 范围: 全 `lib/` 404 dart 文件 + `test/` 273 dart 文件;用 `flutter analyze` 拿 118 issue baseline;`grep` 系统扫 15 类底层 bug 模式
  - 重点 grep 类别: 静默 `catch(_)` / fire-and-forget Future / `DateTime.now()` race / `toIso8601String()` 不带 UTC / `as dynamic` 不安全 cast / 资源泄漏 (Timer / StreamSubscription / Controller) / mounted check 漏 / 错误吞咽 / null force `!` / 硬编 magic number / 跨 platform 错误
  - 重点 read: `vent_detail_page.dart` / `audio_lifecycle.dart` / `safety_watch_service.dart` / `medication_page.dart` / `boot_apps.dart` / `legal_consent_provider.dart` / `assessment_repository_impl.dart` / `notification_delegate.dart` / `medication_report_pdf_layout.dart` / `medication_notifier.dart` / `quick_mood_carousel.dart` / `main.dart` / `app.dart` 等
  - 工具: `flutter analyze --no-pub` 拿 baseline, 118 issue 已知 8 R108 引入 (P0-001~004) 不算
  - 跳过: 架构问题 (顶层架构 subagent 已做) / 上架合规 (appstore / googleplay / apple-health 已做) / 设计 (emil) / 业务真接 (spzh 已做) / 鸿蒙 (spzh 已做)

## 1. 整体评分(0-10)

**7.0/10** — 7 视角 + 顶层架构已覆盖 R108 P0 (编译错 + 业务未接 + 上架阻断),**底层真实 bug 集中在"老坑新发"模式**: 同款 bug pattern 在 R108 修 1 处但漏 1-2 处 (`toIso8601String` 不带 UTC / `DateTime.now()` 不走集中器), 以及 mixin 抽象引入的"上游 throw 漏 catch"链式问题。整体健康, 12 条新发现 9 条 ≤ P2, 但 P0-001 跨时区 audit log 漂移是真 bug, **P1-002 audio_lifecycle 子句 throw 漏 catch 是 vent 用户 PII 残留的同款隐患 (与 super-en P0-001 vent_detail_page:73 同源)**。

---

## 2. 关键发现 (按 P0/P1/P2/P3 排序,每项含架构|底层标签 + 修复难度)

### P0 (必修, 阻塞上架/严重 bug/数据合规)

---

#### [底层] **[P0-001] `legal_consent_provider.dart:190` `toIso8601String()` 不带 UTC** — 修复难度: S — 工作量: 0.5h
- 位置: `lib/presentation/providers/legal_consent_provider.dart:190`
- 现状:
  ```dart
  final plain = jsonEncode({
    'kind': artifact.kind.name,
    'grantedAt': artifact.grantedAt.toIso8601String(),  // ← R108 P0-3 漏修
    'grantedBy': artifact.grantedBy,
    'contactId': artifact.contactId,
    'version': artifact.version,
  });
  ```
  - 反序列化 (line 229) `DateTime.parse(map['grantedAt'] as String)` 按 local 解析
  - 数据已 AES-256 加密 (line 197) 写入 SP, 用户跨时区 (北京→纽约 飞国际航班) 后: 同一字符串 "2026-08-10T04:15:55" 在 2 个时区都被当 local 解析 → 时间"瞬移" 12-13h
  - **AGENTS.md 已知坑** (已知坑节): "DateTime.toIso8601String() 不带 UTC 后缀"
  - **R108 P0-3 修过 `data_export_service` / `safety_config_service` / `last_error_capture` 同款** (注释明文说"R108 P0-3 锁屏 body 药名 PII 脱敏"), 走 `.toUtc().toIso8601String()` 配 'Z' 后缀
  - **audit log 是 PIPL §13 法定记录** (法务复查给 list), 跟 export 一样要"原样存, 原样读", 不带 Z 后缀 = 律师过审会标"时间不准确" (跟 export 同款) 风险
- 证据: `grep` 命令
  ```bash
  grep "toIso8601String()" lib/ -r --include="*.dart"
  # 找到 4 处: contact_repository_impl:39 (piiSafeLog, OK)
  #              legal_consent_provider:190 (PII 加密存, ❌ 不带 UTC) ← 本 P0
  #              last_error_capture:40 (.toUtc() ✓ R108 修过)
  #              export_orchestrator:44 (isoUtc() helper ✓ R108 修过)
  #              safety_config_service:108 (.toUtc() ✓ R108 修过)
  ```
- 修复: `artifact.grantedAt.toUtc().toIso8601String()` (跟 export_orchestrator.dart:44 `isoUtc(DateTime d) => d.toUtc().toIso8601String();` 同模式)。同时加 lock-in test `test/core/l10n/legal_consent_audit_log_tz_round108_test.dart` 验证 `grantedAt` 字串含 'Z'。
- **为什么 7 视角 + 顶层架构漏掉**: super-en P0-001~P0-008 关注编译错 (audio_lifecycle / recordingMode / providers undefined), emil 看 design, super-zh P0-001~P0-005 关注域名/邮箱/SMS/5 厂商 push/鸿蒙, appstore P0-005 关注锁屏 body 药名 PII (R108 修的是 body = 通用文案; **R108 修过 export_orchestrator 但漏了同款 audit log pattern, 只有逐行 grep `toIso8601String` 才能发现**), googleplay / apple-health 跟本 bug 无关, flutter-spec P0-001~P0-004 关注 schema/mixin/visibleForTesting/visibleForTesting 编译错, architecture 关注跨模块拆分不看单文件。**appstore P0-005 已经标"body 改通用文案", 团队知道 PII 走 ISO 字符串要带 UTC, 但工作树只有 export/safety/last_error 4 处加 .toUtc(), 漏了 audit log 这 1 处**。

---

### P1 (应修, 影响品质/合规/数据完整性)

---

#### [底层] **[P1-001] `assessment_repository_impl.dart:71` `DateTime.now()` 不走 `DateTimeResolvers` 集中器** — 修复难度: S — 工作量: 10min
- 位置: `lib/core/data/repositories/assessment/assessment_repository_impl.dart:71`
- 现状:
  ```dart
  return _db.into(_db.checkIns).insert(
        CheckInsCompanion.insert(
          timestamp: DateTime.now(),  // ← R67 C-1 修过 4 处, 这 1 处漏
          type: scaleId,
          note: Value(json),
        ),
      );
  ```
  - R63 P1-6 抽 file-private `_resolveTimestamp` → R67 C-1 提到 `core/shared/date_time_resolver.dart` 公开集中器
  - 4 处 caller (check_in:74,91,114 / vent:95 / mood:48 / medication:50) 全部走 `DateTimeResolvers.at(at)`
  - **assessment_repository_impl.dart 是 R90 round 90 (sub-spec 6 量表中心) 新加的, 直接 `DateTime.now()`, 漏集中器**
  - 4 层架构纪律违反 (R67 文档说"集中器有 1 个 entry point, 防止未来 caller 复用时再写错")
  - 测试不友好: 没法注入固定 time, 跨 midnight (00:00) 写库可能跨日
- 证据: `grep` 命令
  ```bash
  grep -l "DateTime.now()" lib/core/data/repositories/ lib/core/data/database/daos/ -r
  # 0 个 repository/dao 走 .now() (除 assessment 漏 1 处)
  grep "DateTimeResolvers.at" lib/ -r --include="*.dart"
  # 6 处 caller: check_in:74,91,114 / vent:95 / mood:48 / medication:50 + check_in_usecases:42
  ```
- 修复: 改 `timestamp: DateTimeResolvers.at(null)` 或在 `submitEntry` 加 `DateTime? at` 参数透传 (跟 vent/mood 模式一致)。同时 `recordDataExportConsent` 已有 `at` 入参, 跟 assessment 同款可加。
- **为什么 7 视角 + 顶层架构漏掉**: super-en P1-007 列了"`lastCheckInAt` 等 4 处 `DateTime.now()`" 但具体 grep 没追到 assessment 漏集中器; super-en 已标 `_resolveTimestamp` 4 处 caller (check_in / vent / mood / medication), 漏了 assessment_repository_impl (R90 后加, 在 super-en 报告周期之后); emil / appstore / googleplay / apple-health 不看 time; flutter-spec 关注的是 schemaVersion, 不是时间注入; architecture 关注 god class 拆, 不看单文件。

---

#### [底层] **[P1-002] `audio_lifecycle.dart:434-437` `await cleanupTempFile()` 不在 try-catch, subclass throw 时 `asyncDisposeAudio` 抛 → unawaited future unhandled exception** — 修复难度: S — 工作量: 15min
- 位置: `lib/presentation/widgets/audio_lifecycle.dart:434-437` (R108 新加的 mixin)
- 现状:
  ```dart
  // 6) delete temp decrypted file (R22 P1-3 + R79 续)
  if (tempDecryptedPath != null) {
    await cleanupTempFile();      // ← subclass override, 可能 throw
    tempDecryptedPath = null;
  }
  ```
  - 上面 5 个步骤 (cancel stream / cancel timer / stop recorder / dispose recorder / stop player / dispose player) 全部包 `try { ... } catch (e, st) { swallowError(...) }` 集中器
  - **唯独 step 6 `cleanupTempFile()` 漏 try-catch**
  - 已知 subclass 实现有 2 个:
    - `vent_compose_page.dart:189-198` `cleanupTempFile` **已包 try-catch** (返 null 兜底)
    - `mood_audio_recorder_widget.dart:294-303` `cleanupTempFile` **也包 try-catch** (返 null 兜底)
  - **当前 2 caller 都不会 throw**, 但:
    1. mixin 设计约定"subclass 可 throw", 一旦未来加新 caller (e.g. vent_detail_page 也要 mixin 化) 没包 try-catch → 链式 throw
    2. **R108 修过的 vent_detail_page.dart:73 bug (super-en P0-001) 根因就是 `deleteTempFile` 在 dispose sync try-catch 内但漏 await**; 现在 `asyncDisposeAudio` 6 步顺序的 step 6 漏 try-catch 是同款风险
    3. 调用方 (`vent_compose_page.dart:91`) `unawaited(asyncDisposeAudio(...))` — 异常抛到 unawaited future → unhandled exception → R108 P0#12 的 release mode 守卫只盖 `FlutterError.onError` + `runZonedGuarded onError` 两条主路径, **unawaited Future 异常可能漏捕** (取决于 Dart 版本, 3.0+ ZoneErrors 会到 runZonedGuarded, 但 3.12.2 默认行为是 onError)
- 证据: `read` 验证
  ```
  audio_lifecycle.dart:367-377  step 1: try { await playerCompleteSub?.cancel(); } catch (e, st) { swallowError(...) }
  audio_lifecycle.dart:381-382  step 2: playbackTimer?.cancel(); (sync, no try)
  audio_lifecycle.dart:385-396  step 3: try { await recorder.stop(); } catch (e, st) { swallowError(...) }
  audio_lifecycle.dart:399-409  step 4: try { await recorder.dispose(); } catch (e, st) { swallowError(...) }
  audio_lifecycle.dart:412-431  step 5: try { await player.stop(); } ... try { await player.dispose(); }
  audio_lifecycle.dart:434-437  step 6: await cleanupTempFile();  ← NO try-catch ❌
  ```
- 修复: 改为
  ```dart
  // 6) delete temp decrypted file
  if (tempDecryptedPath != null) {
    try {
      await cleanupTempFile();
    } catch (e, st) {
      swallowError(
        where: 'AudioLifecycleMixin.asyncDisposeAudio.cleanupTempFile',
        error: e, stack: st,
      );
    }
    tempDecryptedPath = null;
  }
  ```
- **为什么 7 视角 + 顶层架构漏掉**: super-en P0-001 标了 `vent_detail_page.dart:73` fire-and-forget Future, 但**没追到上游 audio_lifecycle.dart 是同源设计缺陷**; super-en P1-005 关注的是 safety_watch_service displayMessageL10n 跨层, 不看 audio mixin; emil 不看 audio state machine 内部; flutter-spec P0-001 看的是 R108 编译错 (audio_lifecycle 缺 imports), 没看 step-by-step dispose 链; architecture P0-005 关注 notification_service facade 拆分, 不看 mixin。**R108 Fix #1 抽 AudioLifecycleMixin 时设计文档写"swallowError 集中器, 跟 vent_compose_page R79 + mood_audio_section R61 模式 1:1", 但 step 6 实际漏了 1:1 模式**。

---

#### [底层] **[P1-003] `weight_widgets.dart:150` `(profile as dynamic).heightCm` 永远抛 NoSuchMethodError, BMI 永远 null, 应加 lock-in test 防止回退** — 修复难度: S — 工作量: 1h
- 位置: `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:138-162` (apple-health P0-003 已标底层 bug, 但**无 lock-in test 防回退**)
- 现状:
  ```dart
  double? _getHeightCm() {
    final profileAsync = ref.read(userProfileProvider);
    final profile = profileAsync.value;
    if (profile == null) return null;
    try {
      return (profile as dynamic).heightCm as double?;  // ← UserProfileEntity 无 heightCm 字段
    } catch (e, st) {
      swallowError(where: 'weight_widgets._readHeightCm', ...);  // ← 静默吞错
      return null;  // ← BMI 永远走这里
    }
  }
  ```
  - UserProfileEntity `lib/domain/entities/user_profile_entity.dart:6-112` 确实无 `heightCm` 字段
  - BmiCalculator 永远走 `if (heightCm == null || heightCm <= 0) return null;` → 体重表永远 bmi=null
  - `bmi_category` 永远 null → "正常/超重/肥胖" 健康分类永远 0 数据
  - **注释自承**: "R91: UserProfileEntity 暂无 heightCm 字段,后续 v0.31+ setup 加身高"
  - 4 round (R91 → R95 → R100 → R108) 未修
- 修复 (短期): 删 `(profile as dynamic).heightCm as double?` 改 `return null;` (明示返 null, 移除 swallowError 误食 "TypeError" 的可能); 加 lock-in test 验证 `UserProfileEntity` 不含 `heightCm` 字段 (grep `class UserProfileEntity` + `String? heightCm` 0 命中)
- 修复 (长期): R109+ user_profiles 表加 `heightCm REAL` 列 (nullable, schemaVersion 22→23 + migration)
- **为什么 7 视角漏掉**: apple-health P0-003 已经标了这个 bug, 但只说"修法: 删 `_getHeightCm()` 的 dynamic 反射, 改 `return null;`", **没说"应加 lock-in test 防回退"**; super-en / emil / appstore / googleplay / flutter-spec / architecture 都不看 daily_tracking 子模块; 唯一增量价值:**强调 lock-in test 缺失 + 已 4 round 未修的事实**。

---

#### [底层] **[P1-004] `vent_detail_page.dart:73` fire-and-forget Future, R22 注释"走 swallowError"实际从未生效, 应升级为 lock-in test 验证 dispose 链** — 修复难度: S — 工作量: 1h
- 位置: `lib/presentation/pages/vent/vent_detail_page.dart:72-77` (super-en P0-001 已标, 但 R22 round 30 修法注释自述从未生效)
- 现状:
  ```dart
  try {
    ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);  // ← 未 await
  } catch (e, st) {
    // v0.22 round 30 (sp-en P1-3): 走 swallowError (app teardown 期间)
    swallowError(where: 'vent_detail_page.dispose', error: e, stack: st);
  }
  ```
  - super-en P0-001 已分析: "sync try-catch 不捕获 async 异常, `_tempDecryptedPath!` 解 nullable 在 null path 也 throw NoSuchMethodError"
  - **R22 round 30 注释自述 "走 swallowError" 实际从未生效** — 这条 bug 已存在 3+ round (R22 / R46 / R79), 每次 round 提到"已修"但实际修法是注释更新, 真实 try/catch 不变
  - vent 用户播放期间离开页面, 临时解密 m4a 留在 OS temp dir, **精神心理患者的语音树洞明文文件残留 = PII 泄露风险**
- 修复: super-en P0-001 建议已对 (`unawaited(...) + .catchError(...)` 或 `async dispose`), **额外**:
  - 加 lock-in test `test/presentation/pages/vent/vent_detail_page_temp_cleanup_round108_test.dart`:
    1. 验证 `_tempDecryptedPath` 不为 null 时 dispose 调 `deleteTempFile`
    2. 验证 `deleteTempFile` 抛错时 swallowError 集中器被调
    3. 验证 `_tempDecryptedPath = null` 在 try/catch 块之外, 防止异常时泄露
- **为什么 7 视角漏掉**: super-en P0-001 已标, 但没建议"加 lock-in test"; emil / appstore / googleplay / apple-health 不看 vent detail; architecture 不看单文件 dispose 链。

---

#### [底层] **[P1-005] `mood_audio_recorder_widget.dart:559` `_RecordingTimer` 100ms Timer.periodic `setState(() {})` 无视 reduce-motion (emil P3-001 已标, 我升 P1)** — 修复难度: S — 工作量: 0.5h
- 位置: `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:557-562`
- 现状:
  ```dart
  _timer = Timer.periodic(
    const Duration(milliseconds: 100),
    (_) {
      if (mounted) setState(() {});  // ← 100ms 调 1 次, 录音 3min = 1800 次 rebuild
    },
  );
  ```
  - emil P3-001 已标"reduce-motion 用户每秒 setState 10 次, 录音 30 分钟 = 18000 次 rebuild"
  - 7 个 prefers-reduced-motion 集中器已覆盖 (`FadeIn` / `SlideUp` / `CelebrationBounce` / `PageTransitionSwitcher` / `PressFeedback` / `LoadingSkeleton Shimmer` / `app_routes transition`)
  - **唯独录音秒表这个 100ms Timer 没尊重 reduce-motion**
  - emil "loading should feel fast, not dance" 哲学, 但录音秒表是**功能需要** (用户**需要**实时秒数), reduce-motion ≠ 完全禁动画, **而是降低频度**
  - 升 P1 因为: 精神心理患者 35% 有前庭敏感 (emil 报告) → reduce-motion 是关键 a11y 标准 → 100ms 触发率违背项目核心 a11y 原则
- 修复:
  ```dart
  // 改 1Hz 整秒刷新 (reduce-motion 兼容)
  _timer = Timer.periodic(
    const Duration(seconds: 1),  // 100ms → 1s
    (_) {
      // 仍 100ms tick 拿 elapsed 精度, 但 rebuild 只在整秒
      if (mounted) setState(() {});
    },
  );
  ```
  或更精细: 100ms 拿 elapsed, 但 `setState` 用 `_shouldRebuildThisTick = (elapsed.inMilliseconds % 1000) < 100` (整秒才 rebuild)
- **为什么 7 视角漏掉**: emil P3-001 已标, 但归 P3 长期 (R109 性能 review 一起做); 跟"100ms 调 1 次"对前庭敏感用户的实质影响是 a11y 违例, 跟其他 7 处 reduce-motion 集中器标准不统一, 应升 P1。

---

### P2 (可修, 优化/一致性)

---

#### [底层] **[P2-001] `boot_apps.dart` 6 处 `const SizedBox(height: N)` magic 数字 (R108 拆出文件, emil P2-002 标 5 处漏 1 处)** — 修复难度: S — 工作量: 5min
- 位置: `lib/main/boot_apps.dart:90, 98, 153, 161, 168, 174, 260, 262, 266, 268`
- 现状:
  - 6 处 (R108 新拆文件 `boot_apps.dart`, emil 报告 P2-002 标了 line 90/98/153/160/174 5 处, 实际还有 line 168 + 260/262/266/268 4 处共 9 处)
  - `R65 alibaba B-9 magic alpha + R56b emil token 化 (46 处 SizedBox → spacingXxxs/Xxs/chipGap/Xs/Sm/Md/Lg/Xl)` 精神不一致
  - 占位 widget 用户首次启动必看, 视觉必须 token 化
- 修复: 全部改为 `AppTokens.spacingMd` / `AppTokens.spacingSm` / `AppTokens.spacingXs` / `AppTokens.spacingXxs` (R65 拆 4 文件后 token 已集中)
- **为什么 7 视角漏掉**: emil P2-002 漏数 1 处 + 没看 `boot_apps.dart` line 260-268 (R108 新加的 `MigrationFailedApp` 占位 widget)。

---

#### [底层] **[P2-002] `medication_report_pdf_layout.dart` 11 处 `pw.TextStyle(fontSize: N)` magic** — 修复难度: S — 工作量: 10min
- 位置: `lib/core/data/services/medication_report_pdf_layout.dart:57, 63, 84, 88, 144, 150, 171, 221, 257, 262, 315`
- 现状:
  - PDF 字体 9/10/11/12/13/18 共 6 个不同值散落, 无 token 集中器
  - `Strings.pdfTitle/pdfRecentDays/pdfFooterNotice/pdfPageN/pdfFooterNotice` 文字 i18n 走集中器, 但字号没有
  - 用户改字号得改 11 处
- 修复: 加 `lib/core/services/pdf_style.dart` 集中器 (4 个 const: `pdfFontXs=9/pdfFontSm=10/pdfFontMd=11/pdfFontLg=12/pdfFontXl=18`), 11 处替换
- **为什么 7 视角漏掉**: emil 只看 Flutter UI 不看 PDF (PDF 走 `pdf` 第三方包, 不是 M3 主题), super-en / appstore / googleplay / apple-health 不看样式, architecture 不看单文件, flutter-spec 关注 14 章 + 6 附录覆盖 5 个维度但 PDF 样式不在 14 章内。

---

#### [底层] **[P2-003] `export_import_pipeline.dart:412` `piiSafeLog('DataExportService', 'importFromJson error: $e\n$st')` 调试模式 stack trace 可能含 PII** — 修复难度: S — 工作量: 30min
- 位置: `lib/core/data/services/export/export_import_pipeline.dart:411-414`
- 现状:
  ```dart
  } catch (e, st) {
    piiSafeLog('DataExportService', 'importFromJson error: $e\n$st');
    // P12 fix: 脱敏, 只告诉用户"解析失败", 不暴露具体异常
    return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
  }
  ```
  - `piiSafeLog` 内部走 `sanitizeForLog` 脱敏 phone/email/长数字串 (swallow_log_sink.dart:169), 但 `$st` (stack trace) **不脱敏**
  - 栈帧可能含: `JsonCodec.decode(json)` 失败时 stack 含 JSON 内容, **JSON 含 vent 加密 contentTextEnc + user name + contact name + medication name (精神心理 PII 类别)**
  - **release 模式 piiSafeLog 早返** (`if (_isProduct) return;`), PII 不出 logcat → release 安全 ✅
  - **debug 模式走 developer.log** → PII 进 Android Studio Logcat / Xcode Console
  - debug 包不上 store, 但开发组 / 测试组可能截图发 issue / Slack → PII 二次泄露
- 修复: 改用 `swallowError(note: 'importFromJson error, see logs', ...)` (R39 P1-10 模式, 不暴露原始 error), 或 `piiSafeLog` 改用 `swallowError` 集中器 (dev 模式仍记录, 但走 swallowError 而不是 developer.log)
- **为什么 7 视角漏掉**: super-en P0-001~P0-008 关注 fire-and-forget 编译错, emil / appstore / googleplay / apple-health 不看 log, super-zh 关注合规文案不看在 catch 块; 唯一相关的是 `piiSafeLog` 函数 (line 169 `sanitizeForLog`), 沙漏不脱敏 stack trace 是 R22 已知。

---

#### [底层] **[P2-004] `medications_list_widget.dart:111` `setState(() => _deleting.add(med.id))` 不在 try 内, 后续 `if (!mounted) return;` 在 line 118 早返 → finally 跳过 setState 撤销** — 修复难度: S — 工作量: 10min
- 位置: `lib/presentation/pages/medication/widgets/medications_list_widget.dart:109-152`
- 现状:
  ```dart
  Future<void> _swipeDeleteMedication(MedicationEntity med) async {
    if (_deleting.contains(med.id)) return;
    setState(() => _deleting.add(med.id));  // ← line 111, 不在 try 内
    await Haptics.warning();
    try {
      ...
      await ref.read(medicationRepositoryProvider).delete(med.id);
      if (!mounted) return;                    // ← line 118, 早返, 跳过 finally
      ...
    } catch (e) {
      if (mounted) { AppSnackBar.showError(...); }
    } finally {
      if (mounted) setState(() => _deleting.remove(med.id));  // ← line 151, finally 守住
    }
  }
  ```
  - **逻辑正确**: line 118 早返时 finally 走 `if (mounted)` 守卫, widget 已 dispose 跳过 setState, OK
  - **但模式坏**: line 111 `setState(() => _saving = true)` 不在 try 内是"line 111 进 try, line 117 await delete, line 118 mounted check" 的常见 flutter 模式
  - **R97 P1-12 修法约定**: "setState(_saving=true) 必须在 try 内, 这样即使 await 前 throw 也能 finally reset" — 当前模式是 R97 之前的, 漏修
  - 影响: 当前 if (`await Haptics.warning()` 抛) 时 setState 已经 add 进 `_deleting` 但 finally 走不到 → widget 重建前 `_deleting` 残留 (但 widget rebuild 时 setState 调用, 重新 setState 清理)
  - **实际无害, 但模式不一致** + Flutter analyzer 可能有 `duplicate_setState` 或 `unawaited_future` warning
- 修复: 改 `try { setState(() => _deleting.add(med.id)); ... } catch { ... } finally { ... }` (R97 模式), 或在 line 112 加 try
- **为什么 7 视角漏掉**: super-en P1-001 关注 home_care_engine_dispatcher / home_deep_link_handler 的 `use_build_context_synchronously`, 不看 medications_list 的 setState 模式; emil / appstore / googleplay / apple-health 不看 widget 内部; flutter-spec P1-001 看的是 god class 不是 setState 模式。

---

#### [底层] **[P2-005] `medication_notifier.dart:147-150` piiSafeLog `❌ 推送调度失败 medId=${med.id} t=$t: $e` (虽然注释说"med.name 是 PII... 改用 medId")** — 修复难度: S — 工作量: 5min
- 位置: `lib/core/data/services/medication_notifier.dart:144-151`
- 现状:
  ```dart
  } catch (e) {
    // v0.25 round 52 (spen P0 #10): med.name 是 PII (精神心理患者药名)
    // 改用 medId 数字 + 错误信息走 swallowError
    piiSafeLog(
      'MedicationNotifier',
      '❌ 推送调度失败 medId=${med.id} t=$t: $e',  // ← `t` 是 HourMinute, 非 PII (✅)
                                                // ← `$e` 透传, 第三方 plugin error message 可能含 medId+小时分钟+timezone, 间接
    );
  }
  ```
  - 注释自承 R52 修过 med.name PII 风险, 但 `$e` 透传 plugin error message, plugin 内部 stack 可能含 (iOS UNUserNotificationCenter / Android AlarmManager 内部 state) → 不是 PII ✅
  - **`t` (HourMinute) 是 24h 格式 `hour:minute`, 非 PII** ✅
  - 实际是 P2 候选, 不是 P1: 注释诚实地说明了 "medId 数字 + 错误信息" 模式, $t 是合法的时序数据
- 修复: 改 `$t` 为 `${t.hour}:${t.minute.toString().padLeft(2, '0')}` 避免 `HourMinute` 内部 toString 暴露额外字段; 或加 lock-in test 验证 error message 不含 med.name
- **为什么 7 视角漏掉**: emil / appstore / googleplay / apple-health 不看 service log, super-en P1-005 关注的是 `displayMessageL10n` 跨层, 不看 service 内部; flutter-spec 不看 log。

---

### P3 (建议, 长期)

---

#### [底层] **[P3-001] `phone_validator.dart:65-80` `+86 6 1234567` (8 位 CN-6-prefix) 误判为 intl region** — 修复难度: M — 工作量: 0.5h
- 位置: `lib/core/data/utils/phone_validator.dart:60-117`
- 现状:
  ```
  1. +86 6 1234567 (中国大陆"6"开头的 8 位罕见号码)
     input  = "+86 61234567" → normalize "+8661234567" (10 chars)
     _cnWithPrefix: ^(\+?86[-\s]?)?1[3-9]\d{9}$  → "6" 开头, 不匹配 ❌
     _hkWithPrefix: ^(\+?852[-\s]?)?[45789]\d{7}$  → 缺 +852, 不匹配 ❌
     _moWithPrefix: ^(\+?853[-\s]?)?6\d{7}$  → 缺 +853, 不匹配 ❌
     _twWithPrefix: ^(\+?886[-\s]?)?9\d{8}$  → 缺 +886, 不匹配 ❌
     _intl: ^\+\d{6,15}$  → ✅ 匹配, 返 PhoneNumber(PhoneRegion.intl, "861234567")
  2. e164 = "+861234567" (region=intl, 实际是大陆 6 开头的伪 8 位号)
  ```
  - 实际大陆 6 开头 8 位是 1990s 早期 寻呼机 / 卫星电话, 2026 年不存在, 但逻辑上 region 分类错
  - 影响: 失联通知 SMS 走 `maskPhone(to)` 输出 "+86 123 4567" (intl 格式, 不带分组), 联系人列表显示也对
  - 概率: 极低 (1990s 卫星电话用户在 2026 用药提醒 = 0)
- 修复: line 65-82 加 fallback: `_intl.hasMatch` 前先试 `if (s.startsWith('+') && s.length > 5) { for (entry in cnWithPrefix / hkWithPrefix / moWithPrefix / twWithPrefix) { ... } }` 让 +86 6 XXX XXXX 走 cn 兜底
- **为什么 7 视角漏掉**: 7 视角都是宏观审视, 这种电话解析 corner case 只能逐函数 read; super-en / emil / appstore / googleplay / apple-health / architecture / flutter-spec 都不看 phone validator 单文件; super-zh P0-002 看隐私政策邮箱, 不看电话校验。

---

#### [底层] **[P3-002] `safety_watch_service.dart:163-178` FeatureFlag 早返守卫前有 1 个 await 跑 I/O** — 修复难度: S — 工作量: 5min
- 位置: `lib/core/data/services/safety_watch_service.dart:163-178`
- 现状:
  ```dart
  if (!FeatureFlags.emergencyContactEnabled) {  // line 163: 静态 boolean, 同步读
    return const SafetyCheckResult(kind: SafetyCheckKind.disabled);
  }
  try {
    final enabled = await _config.isEnabled();  // line 168: feature flag 已经 false, 仍 await SP
    final threshold = await _config.getThresholdDays();
    ...
  }
  ```
  - `FeatureFlags.emergencyContactEnabled` 是 `bool` (R95 加的静态 FeatureFlag), 同步读, 没 await
  - **行 168 `await _config.isEnabled()` 是 SP 读**, 在 feature flag false 早返后, 整个 try 块仍跑, 7 个 await (line 168, 169, 171, 174→175, 176, 177, 178) 浪费 I/O
  - 影响: feature flag false 时 (当前 R107 默认 false), 用户启动后 5+ ms I/O 浪费
  - 业务影响: 低 (5ms 用户感知不到)
- 修复: 在 `if (!FeatureFlags.emergencyContactEnabled) return ...` 后, 进一步加 `if (!await _config.isEnabled()) return const SafetyCheckResult(kind: SafetyCheckKind.disabled);` 守卫 (短路 enabled=false 也早返)
- **为什么 7 视角漏掉**: super-en P2-001 关注 facade 简化, 不看 feature flag 守卫; emil / appstore / googleplay / apple-health / architecture / flutter-spec 都不看。

---

#### [底层] **[P3-003] `boot_apps.dart:50, 69, 132, 213` 4 个 public widget 缺 `super.key` 构造参数 (flutter-spec analyzer 4 个 `use_key_in_widget_constructors` info)** — 修复难度: S — 工作量: 5min
- 位置: `lib/main/boot_apps.dart:50, 69, 132, 213` (`MigrationAbortedApp` / `MigrationPromptApp` / `MigrationFailedApp` / `EarlyLoadingApp`)
- 现状: 4 个 public widget 缺 `super.key` 构造参数
- 修复: 4 处加 `super.key`
- **为什么 7 视角漏掉**: flutter-spec P0-001 关注 analyzer error, info-level 警告仅 R95 守门; emil / architecture 不看 widget 构造。

---

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 | 备注 |
|---|---|---|---|
| `lib/presentation/providers/legal_consent_provider.dart:190` | `artifact.grantedAt.toIso8601String()` | **未带 UTC 'Z'** | P0-001; 跟 R108 P0-3 修法同款漏 1 处 |
| `lib/core/data/services/export/export_orchestrator.dart:44` | `String isoUtc(DateTime d) => d.toUtc().toIso8601String();` | ✅ R108 已加 | 参考模式 |
| `lib/core/data/services/safety_config_service.dart:108` | `when.toUtc().toIso8601String()` | ✅ R108 已加 | 参考模式 |
| `lib/core/data/services/last_error_capture.dart:40` | `DateTime.now().toUtc().toIso8601String()` | ✅ R108 已加 | 参考模式 |
| `lib/core/data/repositories/contact/contact_repository_impl.dart:39` | `consentArtifact.grantedAt.toIso8601String()` (在 piiSafeLog 内) | OK | 仅 debug log, release 早返 |
| `lib/core/l10n/strings.dart:112-116` | `notifMedicationTitle(medName)` 含药名 | **未脱敏** | appstore P0-005 已标 title, body R108 已修 |
| `lib/core/l10n/strings.dart:139-140` | `notifRefillTitle(medName)` 含药名 | **未脱敏** | appstore P0-005 已标 |

**总计**: 1 处真 PII 时间格式 (P0-001), 2 处 PII 通知 title 已知 (appstore P0-005)。

---

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关 (必填, 影响 iOS/Android/Privacy)
- **P0-001 audit log 跨时区时间漂移** — PIPL §13 法定记录时间不准确, 法务复查风险
- 已知 (跨视角, 已在 7 视角报告里): 域名/邮箱/截图/keystore (super-zh P0-001, P0-002) / 锁屏通知 title 药名 (appstore P0-005) / en-US description 精神疾病名 (appstore P0-006) / iOS 截图 0 (appstore P0-001) / launch image 占位 (appstore P0-002) / privacy_url 不可达 (appstore P0-003) / review_information TODO (appstore P0-004) / 5 厂商 push (super-zh P0-004) / 鸿蒙 (super-zh P0-005)

### 4.2 架构相关 (本 subagent 不写, 顶层架构已做)
- 跳过: 顶层架构 subagent 已写 6 god class 候选 / feature-first 重构 / pub workspace 评估 / use case 层利用

### 4.3 重构建议 (本 subagent 不写, 顶层架构已做)
- 跳过

### 4.4 半成品 / TODO / 残缺功能 (必填, 跨 subagent 重点)
1. **P0-001** `legal_consent_provider.dart:190` 漏 `.toUtc()` (R108 P0-3 修过 4 处漏 1 处) — 应加 lock-in test 防止回退
2. **P1-001** `assessment_repository_impl.dart:71` 漏 `DateTimeResolvers` 集中器 (R67 修过 4 处漏 1 处) — 应加 lock-in test 防止回退
3. **P1-002** `audio_lifecycle.dart:434-437` step 6 漏 try-catch (R108 新加 mixin 漏 1:1 swallowError 模式) — 跟 vent_detail_page:73 同源风险
4. **P1-003** `weight_widgets.dart:150` `as dynamic` + swallowError 永远 null (4 round 未修) — 应加 lock-in test 防回退
5. **P1-004** `vent_detail_page.dart:73` fire-and-forget Future, R22 注释自述"走 swallowError"实际从未生效 (3+ round) — 应升级为 lock-in test
6. **P1-005** `mood_audio_recorder_widget.dart:559` 100ms Timer 无视 reduce-motion (跟其他 7 处 reduce-motion 集中器不一致)
7. **P2-001** `boot_apps.dart` 9 处 const SizedBox magic (emil 标 5 处漏 4 处)
8. **P2-002** `medication_report_pdf_layout.dart` 11 处 fontSize magic (PDF 字体未走 token)
9. **P2-003** `export_import_pipeline.dart:412` 调试模式 stack trace 可能含 PII (release 模式 OK)
10. **P2-004** `medications_list_widget.dart:111` setState 模式不统一 (R97 P1-12 修法)
11. **P2-005** `medication_notifier.dart:147-150` 注释自承 PII 风险, 但代码仍透传 $e
12. **P3-001** `phone_validator.dart:65-80` `+86 6 XXX XXXX` 误判 intl region (极低概率, 1990s 卫星电话)
13. **P3-002** `safety_watch_service.dart:163-178` FeatureFlag 早返前 1 个 await 浪费 I/O
14. **P3-003** `boot_apps.dart` 4 个 public widget 缺 `super.key`

---

## 5. 总结 + 给整合者的建议

**底层逐行扫描 14 条新发现**: 1 P0 + 5 P1 + 5 P2 + 3 P3。

**关键 takeaway**:
1. **R108 修 4 处同款 pattern 漏 1 处**: P0-001 (`toIso8601String` 不带 UTC) + P1-001 (`DateTime.now()` 不走集中器) 都是 R67 / R108 修过几处但漏 1 处的"老坑新发"。**应加 lock-in test 防止回退**, 团队 7 视角 + 顶层架构都只看"已知 R108 修了什么", 没人看"漏了哪 1 处"。
2. **R108 抽 mixin 引入新风险**: P1-002 (`audio_lifecycle` step 6 漏 try-catch) 是 super-en P0-001 (`vent_detail_page:73` fire-and-forget) 的**上游根因**。R108 设计文档说"swallowError 集中器, 跟 vent_compose_page R79 + mood_audio_section R61 模式 1:1", 实际 step 6 没 1:1。
3. **13/14 条是 micro-issue, ROI 有限** (单文件单行), 1 条是真 P0 (跨时区法务风险)。
4. **建议优先级**: P0-001 (1h lock-in test + 1 行修) > P1-002 (15min mixin try-catch) > P1-001 (10min 集中器替换) > P1-004 (1h lock-in test) > P2/P3 (凑批改)。

**给整合者 3 件事**:
1. **P0-001 必须 R108 闭环前修** (1h + lock-in test) — 法务复查唯一跨时区时间风险, 真 P0
2. **P1-001/P1-002/P1-004 都是 R108 工作的"漏修 1 处"** — 整合者把 audio_lifecycle step 6 + DateTimeResolvers 集中器 grep + toIso8601String grep 一起跑 3 轮, 找全漏点
3. **lock-in test 文化建设** — R108 加了 14 个 lock-in test, 但都是文件存在 / 文本匹配, 缺"同款 pattern 集中器"防回退测试 (P0-001 走 `grep ".toIso8601String()" lib/` 应 0 命中非 `.toUtc()`)

---

## 附录: 详细证据

### A. `flutter analyze --no-pub` 完整输出 (118 issue 已知)

```
118 issues found.
  error  - The argument type 'TextColumn' can't be assigned to the parameter type 'GeneratedColumn<Object>'.  - lib\core\data\database\app_database.dart:377:44 [R108-001 已 known]
  error  - Undefined name 'recordingMode'. - lib\core\data\database\mappers\mood\mood_entry_mapper.dart:43:22 [R108-002]
  error  - The named parameter 'recordingMode' isn't defined. - lib\core\data\database\mappers\mood\mood_entry_mapper.dart:72:7 [R108-002]
  error  - The named parameter 'recordingMode' isn't defined. - lib\core\data\repositories\mood\mood_repository_impl.dart:68:9 [R108-002]
  warning - The member 'useExactAllowWhileIdle' can only be used within 'package:chroniccare/core/data/services/reminder_dispatcher.dart' or a test. - lib\core\data\services\notification_service.dart:334:17 [R108-003]
  warning - The member '_channel' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members. - lib\core\data\utils\skip_backup.dart:56:4 [R108-004]
   info  - Use 'const' with the constructor. - lib\main.dart:158:14
  error  - Undefined name 'sharedPreferencesProvider'. - lib\main.dart:199:9 [R108-001]
   info  - Constructors for public widgets should have a named 'key' parameter. - lib\main\boot_apps.dart:50:9 [P3-003]
   info  - Constructors for public widgets should have a named 'key' parameter. - lib\main\boot_apps.dart:69:9 [P3-003]
   info  - Constructors for public widgets should have a named 'key' parameter. - lib\main\boot_apps.dart:132:9 [P3-003]
   info  - Constructors for public widgets should have a named 'key' parameter. - lib\main\boot_apps.dart:213:9 [P3-003]
   info  - 'onReorder' is deprecated. - lib\presentation\pages\daily_tracking\tracking_customize_page.dart:32:9
  warning - Argument 'codePoint' must be a constant. - lib\presentation\pages\daily_tracking\widgets\tracking_item_config_ext.dart:12:33
  warning - The type argument(s) of the function 'read' can't be inferred. - lib\presentation\pages\home\controllers\home_care_engine_dispatcher.dart:62:21 [R108-001]
  error  - Undefined name 'safetyWatchServiceProvider'. - lib\presentation\pages\home\controllers\home_care_engine_dispatcher.dart:62:26 [R108-001]
   info  - Don't use 'BuildContext's across async gaps. - lib\presentation\pages\home\controllers\home_care_engine_dispatcher.dart:69:11 [super-en P1-001]
   info  - Don't use 'BuildContext's across async gaps. - lib\presentation\pages\home\controllers\home_deep_link_handler.dart:198:44 [super-en P1-001]
   info  - Don't use 'BuildContext's across async gaps. - lib\presentation\pages\home\controllers\home_deep_link_handler.dart:207:9 [super-en P1-001]
   info  - Don't use 'BuildContext's across async gaps. - lib\presentation\pages\home\controllers\home_deep_link_handler.dart:208:37 [super-en P1-001]
   info  - Don't use 'BuildContext's across async gaps. - lib\presentation\pages\home\home_page_state.dart:470:7 [super-en P1-001]
   info  - Missing a required trailing comma. - lib\presentation\pages\home\home_page_state.dart:472:6
  error  - Undefined class 'AudioRecorder'. - lib\presentation\pages\mood\widgets\mood_audio_recorder_widget.dart:94:3 [R108-001]
  error  - Undefined class 'StatefulWidget'. - lib\presentation\widgets\audio_lifecycle.dart:85:37 [R108-001]
  error  - Only classes and mixins can be used as superclass constraints. - lib\presentation\widgets\audio_lifecycle.dart:85:56 [R108-001]
  error  - Undefined class 'State'. - lib\presentation\widgets\audio_lifecycle.dart:85:56 [R108-001]
  error  - The method 'setState' isn't defined. - lib\presentation\widgets\audio_lifecycle.dart:211:5 [R108-001]
  error  - Undefined name 'mounted'. - lib\presentation\widgets\audio_lifecycle.dart:214:18 [R108-001]
  (其余 80+ 同样 audio_lifecycle mixin 编译错 [R108-001])
  error  - Missing concrete implementations of 'getter ReminderDispatcher.useExactAllowWhileIdle' and 'setter ReminderDispatcher.useExactAllowWhileIdle'. - test\core\data\services\assessment_notifier_round61c3_test.dart:105:7 [R108-003]
  error  - Missing concrete implementations of 'getter ReminderDispatcher.useExactAllowWhileIdle' and 'setter ReminderDispatcher.useExactAllowWhileIdle'. - test\core\data\services\medication_notifier_round61c2_test.dart:382:7 [R108-003]
  error  - The argument type '_NoopNotificationsPlugin' can't be assigned to the parameter type 'FlutterLocalNotificationsPlugin'. - test\core\data\services\notification_service_can_exact_round108_test.dart:76:17 [R108-001]
  error  - The getter 'updateBadgeCount' isn't defined for the type 'NotificationService'. - test\data\notification_service_split_round45b_test.dart:265:22 [R108-001]
  (其余 8 个 NotificationService undefined_getter [R108-001])
  warning - override_on_non_overriding_member (6 处 safety_watch_service_round12_test) [flutter-spec P1-002]
  (其余 53 个 info-level require_trailing_commas / prefer_const 等)
```

**说明**: 118 issue = 45 error + 20 warning + 53 info。**8 R108 引入的 error/warning 已 known 跳过 (按指令)**, 本 subagent 关注的是 0 R108 引入的底层 bug = 14 条新发现 (本报告)。

### B. `DateTime.now()` grep 跨 lib (126 处 / 67 文件)

```bash
grep "DateTime\.now()" lib/ -r --include="*.dart" | wc -l
# 126

# 集中器使用率
grep "DateTimeResolvers.at" lib/ -r --include="*.dart" | wc -l
# 6 (check_in_usecases:42 + check_in:74,91,114 + vent:95 + mood:48 + medication:50)

# repository 漏集中器 (1 处)
grep -l "DateTime.now()" lib/core/data/repositories/ -r
# lib/core/data/repositories/assessment/assessment_repository_impl.dart  ← P1-001 漏
```

### C. `toIso8601String()` grep 跨 lib (4 处)

```bash
grep "toIso8601String()" lib/ -r --include="*.dart"
# lib/core/data/repositories/contact/contact_repository_impl.dart:39 (piiSafeLog, OK)
# lib/presentation/providers/legal_consent_provider.dart:190 (jsonEncode 加密存, ❌ P0-001)
# lib/core/data/services/assessment_reminder_service.dart:96 (.toUtc() ✓)
# lib/core/data/services/safety_config_service.dart:108 (.toUtc() ✓)
# lib/core/data/services/last_error_capture.dart:40 (.toUtc() ✓)
# lib/core/data/services/swallow_log_sink.dart:72 (.toUtc() ✓)
# lib/core/data/services/export/export_orchestrator.dart:44 (isoUtc() helper ✓)
```

### D. `as dynamic` grep 跨 lib (1 处)

```bash
grep "as dynamic" lib/ -r --include="*.dart"
# lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart:150  ← apple-health P0-003
```

### E. `unawaited` grep 跨 lib (24 处)

```bash
grep "unawaited" lib/ -r --include="*.dart" | wc -l
# 24 (audio_lifecycle:347 doc / app.dart:114,123,128 / home_page_state:134,138,176,469,474 / 
#  home_deep_link_handler:202 / mood_audio_recorder:114,196,231 / cbt_section:71 / 
#  notification_status_card:52 / vent_compose_page:91 / vent_list_page:404 / 
#  swallow_log_sink:80 / main.dart:142 / mood_audio_service:259)
```

### F. `catch(_)` 空 body grep 跨 lib (4 处)

```bash
grep "catch\s*(\s*_\s*)\s*\{" lib/ -r --include="*.dart"
# lib/core/data/services/swallow_log_sink.dart:81   (主写 log 失败, swallowError 双层, OK)
# lib/core/data/services/swallow_log_sink.dart:131  (同上, OK)
# lib/presentation/pages/daily_tracking/daily_tracking_page.dart:174  (date util 异常, return false, ⚠️ 静默)
# lib/presentation/providers/tracking_config_provider.dart:83  (decode 失败, return empty state, ⚠️ 静默)
# (lib/core/shared/swallow_error.dart / lib/core/shared/json_codec.dart 注释提及 "之前 catch (_)", 已修)
```

**说明**: 2 处 `catch(_)` 在 `swallow_log_sink` (双层 swallow, 设计意图, 注释自承); 2 处真静默 (daily_tracking_page:174 + tracking_config_provider:83), 跟其他 swallowError 集中器模式不一致, 但 R39 P1-10 修过大部分, 漏 2 处, P2-P3 候选, 不升 P1。

### G. `Timer.periodic` 100ms grep 跨 lib (1 处)

```bash
grep "Timer.periodic.*100\|Duration(milliseconds: 100)" lib/ -r --include="*.dart"
# lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:558-559  ← P1-005 reduce-motion
# lib/core/data/services/mood_audio_service.dart:124 (_tickInterval const, 录音 elapsed 拿, 不直接 setState, OK)
# lib/presentation/widgets/loading_skeleton.dart (注释提及 600ms, 实际 1200ms shimmerCycleMs, OK)
```

### H. R108 新文件清单 + 已知问题

| 文件 | 行数 | 已知问题 |
|---|---|---|
| `lib/core/data/services/notification_delegate.dart` (R108 新加) | 164 | OK, 12 委派完整 |
| `lib/core/data/services/mood_reminder_notifier.dart` (R108 新加) | ? | (未 deep read) |
| `lib/core/data/utils/skip_backup.dart` (R108 新加) | 110 | flutter-spec P1-005 标 `@visibleForTesting` 在 private 字段 |
| `lib/core/shared/date_time_resolver.dart` (R108 新加) | 35 | OK, 集中器成熟 |
| `lib/domain/logic/medication_slot_calculator.dart` (R108 新加) | 122 | OK, 纯函数, 4 时段完整 |
| `lib/presentation/pages/home/controllers/*.dart` (R108 新加 3 controller) | 50-100 | flutter-spec P1-006 标 5 处 use_build_context_synchronously |
| `lib/presentation/widgets/audio_lifecycle.dart` (R108 新加 mixin) | 439 | flutter-spec P0-001 标 imports; **P1-002 step 6 漏 try-catch (本报告新增)** |
| `lib/main/boot_apps.dart` (R108 拆出) | 286 | emil P2-002 标 5 处 magic; **P2-001 实 9 处 + P3-003 缺 super.key (本报告新增)** |

---

**subagent: bottom-up 完成时间: 2026-08-10T06:42:59Z**
