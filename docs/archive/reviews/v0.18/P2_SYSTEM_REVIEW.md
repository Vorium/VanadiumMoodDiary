# P2 系统化 Review 报告 (superpowers-en 视角)

**项目**: D:\Batch\chroniccare · 慢病管理 App
**审查时间**: HEAD 7ff087a (P1 全部 28 项 done 之后)
**审查人**: superpowers-en 系统化 review sub-agent
**代码基数**: 143 个 Dart 实现文件 + 70 个测试文件
**方法**: brainstorming + verification-before-completion + 7 维度并行调查

---

## TL;DR

P1 修了 28 项,留下了 **8 个"P0 级新洞"**(全部在 v0.18 代码新增 / 修改区域) + **17 个 P1 重要债** + **15 个 P2 改善** + **8 个 P3 探索项**。本轮 P2 共 **48 项发现**:

- **P0 (8 项)** — 立刻修(PII 大量泄漏 / 4 层架构违规 / 全局错误处理缺失 / 死代码误导 / etc.)
- **P1 (17 项)** — 重要(测试盲区 / 暗色模式残留 / 数据导出 / etc.)
- **P2 (15 项)** — 改善(性能 / polish / 文档)
- **P3 (8 项)** — nice-to-have(集成测试 / 探索)

> **与 `docs/P2_DESIGN_REVIEW.md` 互补**: 该文档是 emil 设计工程师视角(微交互 / 视觉 polish),本报告是 superpowers-en 系统化视角(架构 / 安全 / 测试 / 性能 / 错误处理)。两份不应合并,各有侧重。

---

## P0 — 立刻修 (8 项)

> 同优先级内:架构问题先,具体 bug 后。

### P0-1 🔴 PII 大量泄漏到 `developer.log` (精神心理患者 App 致命)

- **位置** (10+ 处直接打印 PII):
  - `lib/core/data/services/reminder_scheduler.dart:108` `'用户: ${profile.userName}'` (真实姓名)
  - `lib/core/data/services/reminder_scheduler.dart:111-114` `${hoursSince} 小时 / ${daysSince} 天 / ${level.name}` (失联检测上下文)
  - `lib/core/data/services/reminder_scheduler.dart:160` `'→ ${c.name} (${c.phone}): ✅/❌'` (联系人姓名 + 电话)
  - `lib/core/data/services/sms_service.dart:48` `'To: $to'` + `body` 全文 (电话 + 完整 SMS 内容)
  - `lib/core/data/services/email_service.dart:51-54` `'To (phone): $to' / 'Subject: $subject' / body 全文`
  - `lib/core/data/services/notification_service.dart:240, 441, 453, 493, 533, 592` `med=${medication.name}` (药名 - 即便不是 PII,在精神心理 App 是敏感上下文)
  - `lib/core/data/services/notification_service.dart:117` `'payload=${response.payload}'` (payload 可能含 medId / 个人路由)
  - `lib/core/data/services/notification_navigation.dart:78` `'Deep link → $path (fromLaunch=$fromLaunch)'` (路径含敏感信息)
- **问题**:
  - 精神心理患者 PII(姓名/电话/失联状态/吃药情况) 是**最高敏感度**数据
  - `developer.log` 在 release 模式**仍会输出到 logcat** (developer.log 不受 `kDebugMode` 守卫,只有 `print` 会)
  - 攻击者拿到 root 设备 / iOS console 抓包 / Firebase Crashlytics 误接 / 类似 1password 7 月 incident 都能拿到这些 PII
  - 数据敏感度等于 "Apple Health" / "BetterHelp" / "Woebot" 级别
- **影响**: 患者姓名 + 电话 + 完整 SMS 内容(包含"已 X 天没打卡"+ 联系人电话) 出现在 logcat,**违反 PIPL / GDPR / HIPAA** 精神
- **修法**:
  1. **新增** `core/shared/pii_safe_log.dart`:
     ```dart
     void piiLog(String tag, String msg) {
       if (kDebugMode) {
         developer.log(msg, name: tag);
       }
     }
     ```
  2. 全项目**sed 替换**:
     - `'用户: ${profile.userName}'` → `'用户: [redacted]'`
     - `'To: $to'` → `'To: ${_maskPhone(to)}'` (只显示 138****5678)
     - `developer.log` 全部改成只在 `kDebugMode` 下输出
  3. 10+ 处修改 + 1 个 helper + 1 个 unit test (验证 release 模式不输出)
- **工作量**: 2-3 小时 (helper + 10 处替换 + test)

### P0-2 🔴 4 层架构违规: presentation 调 mapper 拼 Drift row

- **位置**:
  - `lib/presentation/pages/setup/setup_page.dart:8` `import '.../mappers/medication/medication_mapper.dart'`
  - `lib/presentation/pages/setup/setup_page.dart:870` `medications.map((e) => e.toDriftRow()).toList()`
  - `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:9, 125`
  - `lib/presentation/pages/medication/widgets/medications_list_widget.dart:5, 211`
  - 根因: `notification_service.dart:190-191` `rescheduleMedicationReminders(List<Medication> medications)` 接受 Drift row 而非 domain entity
- **问题**:
  - **presentation 层直接 import data layer 内部 mapper** — 4 层架构最严重违规
  - 绕过 `medicationRepositoryProvider`,presentation 直接持有 Drift row
  - 任何 drift schema 变更 (e.g. 字段重命名) 都会**直接编译失败 UI**
  - AGENTS.md 写了"presentation 永远只看到 entity",实际 3 处违反
- **修法**:
  1. `notification_service.dart:190` 改签名:
     ```dart
     // 之前: List<Medication> (Drift row)
     // 之后: List<MedicationEntity> (domain entity)
     Future<void> rescheduleMedicationReminders(
       List<MedicationEntity> medications,
     ) async {
       // 内部调 MedicationEntityToDrift.toDriftRow() 或用 repo
     }
     ```
  2. `notification_service.dart:517` 同样改 `rescheduleRefillReminders`
  3. **删除 3 个 presentation 里的 mapper import** + 删 3 个 `e.toDriftRow()` 调用
  4. notification_service 内部要么自己 `toDriftRow()`,要么注入 MedicationRepository 重构 (后者更纯净)
  5. 跑 `python scripts/check_cross_feature.py` + `dart scripts/check_all.dart` 验证
- **工作量**: 1.5-2 小时 (改 1 个 service + 3 个 caller + 验证)

### P0-3 🔴 全局错误处理完全缺失:无 `runZonedGuarded` / `FlutterError.onError`

- **位置**:
  - `lib/main.dart:24` `Future<void> main() async` — **裸 `main()`,无 `runZonedGuarded`**
  - `lib/main.dart` 全文 grep `runZonedGuarded` → **0 处**
  - `lib/main.dart` 全文 grep `FlutterError.onError` → **0 处**
  - `lib/app.dart` 全文 grep → 0 处
- **问题**:
  - AGENTS.md 写了 "本地 SQLite 错误通过 `runZonedGuarded` 打印" — **从未实现**
  - 用户遇到未捕获异常(空指针 / 数组越界 / async 错误) → Flutter 显示**红屏 ErrorWidget**(release 显示灰屏,无法操作)
  - 用户**没有任何渠道报告 bug**,开发者**收不到崩溃日志**
  - 精神心理患者卡死在红屏 = 漏 1 天打卡 → 安全风险(SafetyWatch 失联检测也失效)
- **影响**:
  - 0 可观测性(用户反馈只能口述)
  - 数据丢失风险(异常发生时未持久化的数据)
  - 与 P0 项目的"零云端 + 隐私优先" 矛盾 — 本地崩溃日志是最低可观测底线
- **修法**:
  ```dart
  // main.dart 改:
  Future<void> main() async {
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        // ... 现有初始化 ...
        runApp(...);
      },
      (error, stack) {
        // 1. 永远 log(即使 release)
        developer.log('FATAL UNCAUGHT', error: error, stackTrace: stack);
        // 2. dev 模式 throw 让 ErrorWidget 显示完整 stack
        if (kDebugMode) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: error, stack: stack,
          ));
        }
        // 3. v1.0+ 接本地崩溃表(error_logs)持久化,下次启动可读
      },
    );
    // 再加: FlutterError.onError = ... (widget build 阶段错误)
    FlutterError.onError = (details) {
      developer.log('FlutterError', error: details.exception, stackTrace: details.stack);
    };
  }
  ```
- **工作量**: 1-1.5 小时 (main 改 + 加崩溃表 + 1 个回归 test)

### P0-4 🔴 `notification_service.dart:559` 二次 `DateTime.now()` race (AGENTS.md 已声明的反模式)

- **位置**: `lib/core/data/services/notification_service.dart:559` `if (fireAt.isBefore(DateTime.now())) {`
- **问题**:
  - AGENTS.md 显式记录:"v0.16 round 19B / 修正于 v0.17 round 14:同一函数内多次调 `DateTime.now()` 跨 midnight race"
  - 同一函数前面 449 行已有 `final now = DateTime.now();`
  - 559 行第二次调 `DateTime.now()` 是 **AGENTS.md 自身已标记的反模式** — 说明 P1-28 拆 SnoozeManager 没扫到这个新位置
  - 跨 midnight 时 (00:00:00.500) 449 算 now = 23:59:59.999,559 再算 now = 00:00:00.001 → fireAt.isBefore 返回不同结果
- **修法**:
  ```dart
  // 449 行已经: final now = DateTime.now();
  // 559 行改为:
  if (fireAt.isBefore(now)) { ... }
  ```
- **工作量**: 5 分钟 (1 行改)

### P0-5 🔴 死代码: `LocalAiHook` + `NoopLocalAiHook` + `scheduleSoftReminder` 无任何 caller

- **位置**:
  - `lib/domain/logic/care_engine.dart:245-260` `abstract class LocalAiHook` + `class NoopLocalAiHook implements LocalAiHook` — grep 整个 `lib/` 0 处 import / 0 处实现
  - `lib/core/data/services/notification_service.dart:257-296` `@Deprecated Future<void> scheduleSoftReminder` — 0 处 caller(P1-11 已删 setup 调用,但方法本身未删)
  - `lib/core/shared/care_copy.dart:55-58` `@Deprecated static ({...}) softReminder()` — 1 个 caller 也没
  - `lib/core/data/services/notification_service.dart:298-303` `cancelSoftReminder` — 还有 1 处 caller (`home_page.dart:295`),保留
- **问题**:
  - **3 处死代码 / 1 处 deprecated 残留**
  - 死代码误导新 contributor: "为什么有 LocalAiHook 但没人用?是不是漏接了?"
  - 文档 (CHANGELOG.md:288) 还提 "LocalAiHook 接口 (MedGemma 1.5 接入点预留)" → 实际只是"v0.7 留的占位",v0.18 早决定 rule-based 兜底
  - 编译产出代码体积 + 二进制大小(虽然小)
- **修法**:
  1. `care_engine.dart:245-260` 整个删 `LocalAiHook` + `NoopLocalAiHook` (连同注释 + example)
  2. `notification_service.dart:257-296` 整个删 `scheduleSoftReminder` (含 `@Deprecated` 注释)
  3. `care_copy.dart:55-58` 整个删 `softReminder()` static method
  4. CHANGELOG.md:288 更新为 "删 v0.7 占位,rule-based 是最终方案"
  5. 跑 `flutter test` 确认没破坏
- **工作量**: 30 分钟 (删 3 处 + 跑 test)

### P0-6 🔴 god-page `trend_page.dart` 1428 行,无 plan 拆

- **位置**: `lib/presentation/pages/trend/trend_page.dart` (1428 行,全项目最大)
- **问题**:
  - 单文件 1428 行 = 7 个 feature widget 内联(列表/日历/热力图/折线图/情绪卡/评估卡/工具栏)
  - P1-27 拆了 home_page,trend_page 是下一个 god-page 候选
  - grep `class _` 在 trend_page 找到 5+ 个 private state class (`_TrendView`, `_CalendarView`, `_CalendarViewState`, `_Heatmap`, `_LineChart`) 全部挤一个文件
  - 改一个 widget 触发整个文件 rebuild,git diff 混乱 (单 commit 5 个 widget 改)
  - 编译时间:大文件单文件 1428 行 = 单 widget 改触发全文件 recompile
- **影响**:
  - **新 contributor 入门 30+ 分钟**才能理解整个文件
  - widget test 难写(整页 rebuild,不能单独测 _Heatmap)
  - 1428 行 = 几乎不可能一行行 review 全部
- **修法**:
  ```
  trend/
  ├── trend_page.dart            (主入口 ~200 行)
  ├── _trend_view_enum.dart      (_TrendView enum + 切换)
  ├── trend_list_view.dart       (列表 ~200 行)
  ├── trend_calendar_view.dart   (日历 + _CalendarView ~350 行)
  ├── widgets/
  │   ├── heatmap_widget.dart    (_Heatmap 抽 ~150 行)
  │   ├── line_chart_widget.dart (_LineChart 抽 ~250 行)
  │   ├── summary_card.dart      (~80 行)
  │   └── empty_state.dart       (~60 行)
  ```
  跟 `home/widgets/` 同样的子目录拆分模式
- **工作量**: 4-6 小时 (7 个 widget 抽 + 4 个 widget test)

### P0-7 🔴 Web 端**完全不加密**本地数据 (PII 直接落 IndexedDB)

- **位置**: `lib/core/data/database/connection/web.dart:16-40`
- **问题**:
  ```dart
  // web.dart 注释:
  // "v0.9 之后 Web 端**不加密**本地数据,但提示用户:
  //  'Web 端数据未加密(浏览器沙箱限制),请用 APK 版本获得完整加密保护'"
  ```
  - Web build 跑起来 → 用户在浏览器输入姓名/电话/用药/情绪/树洞 → **全部明文存 IndexedDB**
  - 任何浏览器插件 / 共享电脑 / DevTools → 直接看 PII
  - 跟项目核心承诺"零云端 + 本地加密" 完全冲突
  - AGENTS.md 没提 web 端**不**加密,只说"零云端"
  - 树洞文字在 native 端 SQLCipher 加密,在 web 端**完全裸奔**
- **影响**:
  - 如果用户通过 PWA 装到手机,或在 ChromeOS 跑,数据**完全无加密**
  - 树洞 = "死了么" 模式的情绪数据 = 高敏感
- **修法** (3 选 1):
  1. **最安全**: 把 web.dart 改成抛 `UnsupportedError("Web 端暂不支持, 请用 Android/iOS")`,production build 阻断 web
  2. **次安全**: 用 `window.crypto.subtle` (Web Crypto API) 派生 PBKDF2 key,首次启动让用户输密码,失败 3 次清数据
  3. **最小改动**: web.dart 启动时强制弹 "Web 端数据不加密,确认使用?" 二次确认 → 用户拒绝则弹"请用 APK"
- **工作量**: 选 1 = 1 小时 / 选 2 = 6 小时 / 选 3 = 2 小时

### P0-8 🔴 schema 缺索引,大表查询会扫全表

- **位置**:
  - `lib/core/data/database/tables/check_in/check_ins.dart` 全文 grep `index` → 0 处
  - `lib/core/data/database/tables/medication/medications.dart` → 0 处
  - `lib/core/data/database/tables/mood/mood_entries.dart` → 0 处
  - `lib/core/data/database/tables/vent/vent_entries.dart` → 0 处
  - `app_database.dart` 全文 grep `createIndex` / `CREATE INDEX` → 0 处
- **问题**:
  - `CheckIns` 有 `timestamp` (按月/年查询) + `type` (normal/temp/phq9/gad7 4 类) 2 个常查询字段
  - `MoodEntries` 有 `timestamp` (按天/月查询) + 无 `type` 但有 `score` (情绪分数)
  - `VentEntries` 有 `timestamp` (按时间倒序 watchAll)
  - 全部**无索引** → 数据量到 1000+ 行后,`watchAllCheckIns()` 每次触发都扫全表
  - streak 计算 / 趋势图 / 评估历史都是 `where timestamp > X and type = Y` 类查询,全表扫
  - 1 年用户 ≈ 365 行 normal + 365 行 temp = 730 行,扫 1 次没事;5 年 = 3650 行,趋势页每次切 tab 都全表扫
- **影响**:
  - 长期用户(1 年+) 主页加载会卡 200-500ms
  - streak 计算 `O(N)` (`StreakCalculator.calculate`) 跨 1000+ 行会显著慢
- **修法**:
  ```dart
  // check_ins.dart 加:
  @override
  List<Set<Column>> get customConstraints => [
    {timestamp, type},  // composite index
  ];
  // 或在 onUpgrade 加 customStatement('CREATE INDEX idx_checkin_ts ON check_ins(timestamp)')
  ```
  - `CheckIns`: `(timestamp, type)` composite index (覆盖 streak + 评估 + watchAll)
  - `MoodEntries`: `timestamp` index
  - `VentEntries`: `timestamp DESC` index
  - `Medications`: `isActive, startDate` composite (覆盖 watchAll + isActive filter)
  - schemaVersion 7 → 8 + migration
- **工作量**: 1.5-2 小时 (4 个 index + migration + test)

---

## P1 — 重要但可延 (17 项)

> 同优先级内:架构问题先,具体 bug 后。

### 数据 / 持久化 (5 项)

#### P1-1 transaction 仅 2 处使用,5+ 处应包事务

- **位置**:
  - `lib/core/data/database/app_database.dart:330` `transaction` ✓
  - `lib/core/data/services/data_export_service.dart:142` `transaction` ✓
  - 应包但没包:
    - `medications_list_widget.dart:135-220` "添加 + 重排通知" 序列(单步失败 → DB 写了但通知没排)
    - `medication_report_dialog.dart:180-200` "生成报告 + 写历史" 序列
    - `edit_medication_dialog.dart:118-128` "改 medication + 重排通知" 序列
    - `setup_page.dart:857-872` `_finishSetup` 4 步(contacts + medications + schedule + soft reminder)
    - `assessment_reminder_service.dart:186-300` "保存评估 + 重排提醒" 序列
- **问题**: 任何中间步骤失败 → 数据半成品
- **修法**: 在 repository 层加 `Future<void> executeInTransaction(Future<void> Function() action)`,UI 调它
- **工作量**: 2-3 小时 (5 处替换 + 1 个 helper + 5 个 test)

#### P1-2 主页 0 处 autoDispose,StreamProvider 全程持有

- **位置**: `lib/presentation/providers/data_providers.dart` 全文 grep `autoDispose` → 0 处
- **问题**:
  - `medicationsProvider`, `contactsProvider`, `allCheckInsProvider` 等 11 个 StreamProvider 都是**全程持有**
  - 每次主页 / 趋势 / 评估页 watch → DB 持续 query → 即使后台也跑
  - vent 用了 `StreamProvider.autoDispose` (vent_providers.dart:39) — 这是正确做法,其他 provider 应该一致
  - 进设置页 / 后台 → 主页的 streak / contact list 还在持续 stream → 内存 + DB IO
- **修法**: 11 个 StreamProvider 加 `.autoDispose`,UI 用 `ref.keepAlive()` 显式标记需要持久的
- **工作量**: 1-1.5 小时 (11 个 provider + 验证)

#### P1-3 user_profiles 表缺 `userName` 长度校验

- **位置**: `lib/core/data/database/tables/user_profile/user_profiles.dart:9` `userName => text()()` — 无 `withLength`
- **问题**:
  - 用户输入 10000 字符 name → DB 接受(其他 text 也都没限制)
  - `contact.name` 同问题 (无 withLength)
  - 攻击场景: 用户在 PII 数据里塞 100MB 文本 → DB 膨胀 → OOM
- **修法**: `withLength(min: 1, max: 100)`,联系人 `name` 50,`phone` 30
- **工作量**: 30 分钟

#### P1-4 vent_entries 表 `contentText` 无 maxLength 校验 (10MB tree hole?)

- **位置**: `lib/core/data/database/tables/vent/vent_entries.dart:18` `contentText => text().nullable()()` — 无长度限制
- **问题**:
  - 树洞文字无上限,用户长篇 1MB+ → DB 增长
  - export/import 限到 100k (`data_export_service.dart:300`) 但**写入时不校验** = 入了 1MB 文字,导出时**静默截断**
  - 不一致: 入口(写) 无限制 / 出口(导) 有 100k
- **修法**: 写入前 validation,或加 `withMaxLength(100000)`
- **工作量**: 1 小时 (2 个入口 + test)

#### P1-5 data_export_service `_validateString` 默认返回 null = 静默丢数据

- **位置**: `lib/core/data/services/data_export_service.dart:367-374` `_validateString` 不符合规则返回 null
- **问题**:
  - 导入时 `mood.tags` 超过 5000 字符 → 静默改 `'[]'` → **用户丢 tag 数据**
  - `vent.text` 超过 100k → 静默改 null → **用户丢树洞内容**
  - 导入"成功"返回 `ImportResult.success(...)` 但实际数据被静默改 → 误导用户
- **修法**: 失败时把字段名 + 原值(截断) 记到 `ImportResult.warnings: List<String>`,UI 显示 "5 个字段因长度限制已截断"
- **工作量**: 1.5 小时 (1 个新字段 + 7 处校验 + UI warning)

### 安全 / 隐私 (4 项)

#### P1-6 `main.dart:37` 打印 `.env 加载失败` 详情到 logcat

- **位置**: `lib/main.dart:37` `debugPrint('⚠️ .env 加载失败（首次启动正常）：$e');`
- **问题**:
  - `.env` 含真实 ALIYUN_ACCESS_KEY / SENDGRID_API_KEY 等 (未来 v1.0 接入)
  - 加载失败时异常栈**包含文件路径 + key 名**
  - 跟 P0-1 PII 泄漏同性质
- **修法**: catch 块只 log "env 缺失" 标位,不打印 $e
- **工作量**: 5 分钟

#### P1-7 树洞 audio 临时解密文件不在 dispose 强制清理

- **位置**: `lib/presentation/pages/vent/vent_compose_page.dart:185-189` (临时文件删除) 但 `vent_detail_page.dart:62-72` 删除逻辑在 `dispose` 里,若 widget 没正常 dispose (e.g. AppRoot 重建 / Hot Reload / OOM kill) 临时文件残留
- **问题**:
  - 临时解密文件用 `_tempDecryptedPath` 字段, dispose 删
  - 但 App 崩溃 / 系统杀进程 → 临时文件残留 → 设备重启前一直可读
  - 加密的 audio 文件没事,**但解密后明文 m4a** 残留
- **修法**: App 启动时扫 `Directory.systemTemp` 把 `vent_record_*.m4a` 全删
- **工作量**: 30 分钟 (1 个 startup hook + 1 个 test)

#### P1-8 `permission_handler` 包引入但 0 处使用

- **位置**: `pubspec.yaml:46` `permission_handler: ^11.3.1`
- **问题**:
  - 已声明依赖但**全文 grep 0 处 import** (`grep "permission_handler" lib/`)
  - 录音权限走 `record` 包自带 `hasPermission()`,**不需要 permission_handler**
  - 通知权限走 `flutter_local_notifications` 自带 `requestPermissions()`
  - 未使用依赖 = pub 体积 + 安全审计噪音
- **修法**: pubspec.yaml 删
- **工作量**: 5 分钟 + `flutter pub get`

#### P1-9 主页 0 处隐私 "查看"提示: 用户可能不知道数据存本地 vs 云端

- **位置**: 全 App grep `云端 / 上传 / 服务器` → 0 处提示
- **问题**:
  - 用户首次进设置 / 主页,**不知道**:
    - 数据存本地(隐私友好)
    - **不**上传到任何服务器
    - 卸载 = 数据**完全**丢(无云备份)
  - 精神心理患者尤其需要明确"我不偷你的数据"
- **修法**:
  - 主页 / 设置页顶部加 1 行小字 "🔒 数据存本地 · 零云端"
  - 设置页"关于"加 1 个 card 详细解释
- **工作量**: 1-2 小时 (UI + 文案 + 1 个 ARB key)

### 错误处理 / 异常 (3 项)

#### P1-10 `vent_detail_page.dart:108-122` 删除按钮无撤销机制

- **位置**: `lib/presentation/pages/vent/vent_detail_page.dart:104-122`
- **问题**:
  - 树洞删除 → 立刻 `repo.delete(entry.id)` → 树洞**永久丢失**
  - 精神心理数据删错代价极高(用户可能后悔)
  - 其他删 (contact, medication) 也无撤销
- **修法**: 删除后 `AppSnackBar.withAction(..., actionLabel: '撤销', onAction: () => repo.restore(entry))`,5s 窗口
- **工作量**: 2 小时 (1 个 helper + 5 类删除场景)

#### P1-11 主页 7 处 `try { ... } catch (e) { debugPrint(...) }` 用户看不到

- **位置**: `lib/presentation/pages/home/home_page.dart:105, 151, 294, 317, 343, 359` (6 处)
- **问题**:
  - 6 个 `try` 块 catch 后只 `debugPrint` → release 模式**完全静默**
  - 用户操作失败 (打卡 / snooze / 临时吃药) 不知道**为什么**失败
  - 应该是 `AppSnackBar.error(context, action: '打卡', error: e)` 弹窗告诉用户
- **修法**: 6 处全部改 `AppSnackBar.error(...)`,P0-4 (HomePage 裸 SnackBar) 同源,合并修
- **工作量**: 1 小时 (跟 P0-4 同一 commit)

#### P1-12 `data_export_service.dart:347` `debugPrint` 在 release 模式无效

- **位置**: `lib/core/data/services/data_export_service.dart:347` `debugPrint('importFromJson error: $e\n$st');`
- **问题**:
  - `debugPrint` 在 release 模式**完全静默**(跟 `print` 不一样,debugPrint 是仅 debug 模式)
  - import 失败时 debugPrint 静默 → 用户看到 "解析失败" 通用提示,无法定位问题
- **修法**: 用 `developer.log` 替代(总是 log) + 用户友好 message
- **工作量**: 5 分钟

### 性能 (3 项)

#### P1-13 vent_list / trend / assessment_history 用 `ListView()` 非 `.builder()`

- **位置**:
  - `lib/presentation/pages/trend/trend_page.dart:1041` `ListView(children: [...])` (检查发现)
  - `lib/presentation/pages/settings/settings_page.dart:39` `ListView(children: [...])`
  - `lib/presentation/pages/settings/reminders_hub_page.dart:70` `ListView(children: [...])`
  - `lib/presentation/pages/medication/refill_manage_page.dart:117` `ListView(children: [...])`
  - `lib/presentation/pages/assessment/assessment_history_page.dart:57` `ListView(...)`
  - `lib/presentation/pages/medication/medication_calendar_page.dart:41` `ListView(...)`
- **问题**:
  - 6+ 处用 `ListView(children: [...])` (eager) 而非 `ListView.builder(itemBuilder: ...)` (lazy)
  - 数据量到 50+ 时,eager 模式一次性 build 所有 widget → 首次渲染卡顿
  - vent_list 用的是 `ListView.separated` (lazy) — 正确
- **修法**: 6 处全部改 `ListView.builder` 或 `ListView.separated`
- **工作量**: 1.5 小时 (6 处重构)

#### P1-14 `setup_page.dart:1017` 文件过大,InputField 嵌套 5+ 层

- **位置**: `lib/presentation/pages/setup/setup_page.dart` 全文
- **问题**:
  - 1017 行,5 步 (consent / welcome / medication / done) 内联
  - 单 page 改 → 全文件 recompile
  - widget test 难写(整个 setup flow 都要 mock)
- **修法**: 拆 `setup/` 子目录,每步 1 个 widget
- **工作量**: 3-4 小时

#### P1-15 `assessmentsProvider` / `allMoodProvider` 在主页 / 设置页 0 处 watch,但 stream 持续跑

- **位置**: `data_providers.dart:88-104` — 2 个 StreamProvider **无任何 caller** (`grep "ref.watch(assessmentsProvider)"` → 0 处,`grep "ref.watch(allMoodProvider)"` → 0 处,`grep "ref.watch(reportHistoriesProvider)"` → 0 处)
- **问题**:
  - 3 个 StreamProvider 持久 query DB 但**无人订阅** — 死代码 + DB IO 浪费
- **修法**: grep 确认 0 caller 后,删除 3 个 provider
- **工作量**: 10 分钟

### 测试覆盖 (2 项)

#### P1-16 0 个 E2E / integration test,关键 flow 无覆盖

- **位置**: `pubspec.yaml` 全文 grep `integration_test` / `flutter_driver` → 0 处
- **问题**:
  - 70 个 test 都是 unit / widget test
  - **关键 flow 无 E2E 覆盖**:
    - 首次设置 → 主页 → 打卡 → 通知弹出 → 关闭 → 重启 → streak 累加
    - 添加 medication → 编辑时间 → 通知重排
    - 评估 → 写历史 → 趋势显示
  - 任何 1 处回归不会立刻发现
- **修法**: `pubspec.yaml` 加 `integration_test: ^5.0.0` + `integration_test/setup_to_checkin_test.dart` 跑核心 flow
- **工作量**: 4-6 小时 (1 个新测试 + CI 集成)

#### P1-17 主页 / 设置页 / 评估页无 widget test

- **位置**:
  - 缺 `home_page_test.dart` (394 行 home_page 0 测试)
  - 缺 `settings_page_test.dart` (461 行 0 测试)
  - 缺 `assessment_page_test.dart` (753 行 0 测试)
  - 缺 `trend_page_test.dart` (1428 行 0 测试)
  - 缺 `mood_dialog_test.dart` / `contact_list_test.dart` / `email_preview_test.dart` / `vent_compose_test.dart` / `vent_detail_test.dart`
- **问题**:
  - 5 个核心 page + 4 个 dialog **0 测试覆盖**
  - 任何 UI 改动无 regression 网
- **修法**: 至少 5 个 page 各 1 个 smoke test (page renders without crash)
- **工作量**: 6-8 小时 (5 page test + 4 dialog test)

---

## P2 — 改善 (15 项)

### Token / 一致性 (5 项)

#### P2-1 dark mode `AppTokens.textHint/Secondary/Primary` 静态常量残留 87 处

- **位置**: 跟 P2_DESIGN_REVIEW.md P0-5/6 重复,这里只列**当前最新数据**:
  - `grep "AppTokens.textHint\b" lib/` → 42 处
  - `grep "AppTokens.textSecondary\b" lib/` → 30 处
  - `grep "AppTokens.textPrimary\b" lib/` → 15 处
  - 合计 **87 处** (P1-5 batch 1 改 8 处,剩 87 处)
- **修法**: 跟 P2_DESIGN_REVIEW P0-5 一样,加 `textHintColor(context)` 等 getter,sed 替换
- **工作量**: 3-4 小时

#### P2-2 `EdgeInsets.circular(2/4/24)` 等硬编码数字 25+ 处

- **位置**:
  - `medication_calendar_page.dart:322, 377` `circular(2)` (P1-1 已 token 化为 `radiusCell` 但未替换)
  - `trend_page.dart:325, 350` `circular(4)` (→ `radiusCellLg`)
  - `celebration_overlay.dart:94` `circular(24)` (→ `radiusButton`)
  - 5+ 处 BorderRadius
- **修法**: 已有 token,sed 替换
- **工作量**: 15 分钟

#### P2-3 `EdgeInsets` 数字 (4/8/16/24) 25+ 处硬编码

- **位置**: `grep "EdgeInsets" lib/presentation` 大量 `EdgeInsets.all(4/8/16/24)`,都该走 `AppTokens.spacingXs/Sm/Md`
- **修法**: 跟 P2_DESIGN_REVIEW P2-1 一样,扩 1 档 `spacingXxs=4` token,sed
- **工作量**: 2 小时

#### P2-4 fontSize 30+ 处硬编码 8/10/11/12/13/22/32

- **位置**: `grep "fontSize: \d+"` 50+ 结果
- **修法**: 扩 4 档 micro font token (`fontSizeMicro=10, fontSizeSmall=12, fontSizeEmoji=22, fontSizeEmojiLg=32`),sed
- **工作量**: 1.5 小时

#### P2-5 `Color(0xFF...)` 硬编码 1 处 + `withOpacity` 大量

- **位置**:
  - `celebration_overlay.dart:97` `Color(0x33000000)` (硬编码)
  - `app_tokens.dart:84` `withValues(alpha: 0.6)` (M3 推荐) vs 全局 grep `withOpacity` 还有 30+ 处 (旧 API)
- **修法**: 加 `shadowOverlay` token + sed `withOpacity` → `withValues(alpha:)` (M3 0.6+ 推荐)
- **工作量**: 1 小时

### 文档 (4 项)

#### P2-6 CHANGELOG.md 缺 v0.18.0 条目 (P0/P1 全部 28 项未记录)

- **位置**: `docs/CHANGELOG.md` 全文 grep `v0.18` → 0 处
- **问题**:
  - git log 显示 v0.18 已提交 7+ 个 commit (P0-2 树洞加密 / P1-1~P1-28 全部 28 项)
  - CHANGELOG 最新条目是 v0.17.0
  - 用户看 CHANGELOG 完全不知道 v0.18 改了什么
- **修法**: 补 v0.18.0 条目,按 P0/P1/P2 分组
- **工作量**: 1.5 小时 (写 100+ 行 changelog)

#### P2-7 AGENTS.md 写"`runZonedGuarded`" 但实际 0 实现 (跟 P0-3 配对)

- **位置**: `AGENTS.md` 决策记录 / 已知坑 段 grep `runZonedGuarded` → 0 处,但 "项目不接 Firebase / Sentry" 段提到 "本地 SQLite 错误通过 `runZonedGuarded` 打印" (近似)
- **问题**: 文档跟实现不一致
- **修法**: 改文档 (跟 P0-3 fix 同步) 或加 "P2 计划: 引入 runZonedGuarded"
- **工作量**: 10 分钟

#### P2-8 `lib/presentation/widgets/press_feedback.dart` 定义但 0 处使用 (跟 P2_DESIGN_REVIEW P0-1 重复)

- **位置**: 已查
- **修法**: 见 P2_DESIGN_REVIEW
- **工作量**: 3-4 小时

#### P2-9 `lib/presentation/widgets/empty_state.dart` 定义但 0 处使用 (跟 P2_DESIGN_REVIEW P0-2 重复)

- **位置**: 已查
- **修法**: 见 P2_DESIGN_REVIEW
- **工作量**: 2-3 小时

### 性能 (3 项)

#### P2-10 `setup_page.dart:1017` 单文件编译时间长,改 1 个 widget 全文件重编

- **位置**: 同 P1-14
- **修法**: 拆子目录后,改动只在子文件
- **工作量**: 跟 P1-14 一并

#### P2-11 `assessmentsProvider.allMoodProvider.reportHistoriesProvider` 0 caller (P1-15 重)

- **位置**: 同 P1-15
- **修法**: 同

#### P2-12 home_page 24 imports,首屏需解析 24 个 dart 文件

- **位置**: `lib/presentation/pages/home/home_page.dart` import 24 个
- **问题**: home 是 App 启动后第一个 page,**首屏**渲染延迟 = 24 个 dart 文件 parse 时间
- **修法**: 用 `part of` 或 lazy import 拆 part
- **工作量**: 1.5 小时 (低优先级,实测影响小)

### 错误处理 (2 项)

#### P2-13 `data_export_service.dart:347` 静默打印异常 (P1-12 重)

- **位置**: 同 P1-12
- **修法**: 同

#### P2-14 `reminder_scheduler.dart:243-247` 失联检测 log 含触发上下文

- **位置**: `lib/core/data/services/safety_watch_service.dart:243` `'🚨 SafetyWatch 触发: trigger=$trigger days=$daysSinceLast smsOk=$smsOk smsFail=$smsFail'`
- **问题**: 失联 = 用户最敏感数据,logcat 出现 "用户 X 天没打卡" 是 PII
- **修法**: 跟 P0-1 同源,加 helper + 脱敏
- **工作量**: 跟 P0-1 一并

### 数据 (1 项)

#### P2-15 data_export 不导 settings (只导 data)

- **位置**: `lib/core/data/services/data_export_service.dart:35` `exportToJson` 只导 DB 表
- **问题**: settings (主题 / 通知时间 / 评估周期 / safety 阈值) 不导出
  - 换设备 → user 全部要重设
  - 跟 P3-5 配套
- **修法**: 扩 `dataExportService` 支持 settings 导出/导入
- **工作量**: 3-4 小时

---

## P3 — nice-to-have (8 项)

#### P3-1 integration test 框架搭建 (跟 P1-16 部分重叠)

- **位置**: pubspec.yaml 加 `integration_test`
- **修法**: 1 个 smoke E2E (setup → 主页 → 打卡 → 重启 → streak 累加)
- **工作量**: 6-8 小时

#### P3-2 树洞录音波形图 (P2_DESIGN_REVIEW P3-1 重复)

- **位置**: vent_compose_page.dart
- **修法**: 自定义 CustomPainter + record amplitude stream
- **工作量**: 3-4 小时

#### P3-3 主页"今天目标" widget (P2_DESIGN_REVIEW P3-6 重复)

- **位置**: home/widgets/
- **修法**: 3 个 dot + 文字 (打卡/评估/情绪)
- **工作量**: 3 小时

#### P3-4 设置导出/导入 (P2_DESIGN_REVIEW P3-5 + P2-15 部分重叠)

- **位置**: settings_page.dart
- **修法**: 跟 P2-15 配套 UI
- **工作量**: 2 小时 (UI 部分)

#### P3-5 主页 streak HSL 色彩渐变 (P2_DESIGN_REVIEW P3-2 重复)

- **位置**: encouragement_text.dart
- **修法**: 0-7 灰 / 7-30 绿 / 30-100 金 / 100+ 彩虹
- **工作量**: 1.5 小时

#### P3-6 主题切换淡入 (P2_DESIGN_REVIEW P3-3 重复)

- **位置**: theme_provider.dart
- **修法**: AnimatedTheme 包整个 MaterialApp
- **工作量**: 30 分钟

#### P3-7 评估历史 sparkline hover tooltip (P2_DESIGN_REVIEW P3-4 重复)

- **位置**: assessment_page.dart
- **修法**: fl_chart LineTouchData
- **工作量**: 2 小时

#### P3-8 主页"你今天为家人做了啥"celebration (emil delight 频度)

- **位置**: home/widgets/celebration_overlay.dart
- **修法**: 1 周准时 / 1 月准时 / 100 天连击 → Lottie + 弹层
- **工作量**: 4-6 小时 (需 lottie 资产)

---

## 优先级实施建议

### 立刻 (P0 全 8 项, 共 ~15-20 小时)

按风险从高到低:

1. **P0-1 PII 泄漏** 2-3h (合规 + 隐私最严重)
2. **P0-2 4 层架构违规** 1.5-2h (架构债)
3. **P0-3 全局错误处理** 1-1.5h (可观测性)
4. **P0-4 DateTime race** 5min (AGENTS.md 声明的反模式,1 行)
5. **P0-5 死代码清理** 30min (LocalAiHook + scheduleSoftReminder)
6. **P0-6 trend_page 拆分** 4-6h (god-page 阻断)
7. **P0-7 Web 端不加密** 1-2h (选 1: 直接 throw)
8. **P0-8 索引** 1.5-2h (长期用户性能)

### 1 个月内 (P1 选 8-10 项, 共 ~15-20 小时)

- **P1-2 StreamProvider autoDispose** 1.5h
- **P1-5 import 静默丢数据** 1.5h
- **P1-7 临时文件清理** 30min
- **P1-10 撤销机制** 2h (用户信任)
- **P1-11 snackbar error 显示** 1h
- **P1-13 ListView lazy** 1.5h
- **P1-15 死 provider 清理** 10min
- **P1-16 integration test 起步** 4h
- **P1-17 关键 page widget test** 6h

### 2-3 个月内 (P2 全 + P3 选 2-3 项, 共 ~20-30 小时)

按时间预算挑,优先 token polish (P2-1~5, 共 ~8h) + 文档 (P2-6, 1.5h)

### 不做 (P3 大项, 留 v1.0 之后)

P3-2 录音波形 / P3-3 今天目标 / P3-5 主题动画 / P3-8 celebration 动画

---

## 关键发现统计

| 维度 | 发现数 | 严重 (P0) | 重要 (P1) |
|---|---|---|---|
| 架构 / 4 层 | 6 | 3 (P0-2/5/6) | 1 (P1-2) |
| 数据 / 持久化 | 7 | 1 (P0-8) | 4 (P1-1/3/4/5) |
| 安全 / 隐私 | 5 | 1 (P0-1) | 4 (P1-6/7/8/9) |
| 错误处理 | 5 | 1 (P0-3) | 3 (P1-10/11/12) |
| 性能 | 5 | 0 | 3 (P1-13/14/15) |
| 测试覆盖 | 2 | 0 | 2 (P1-16/17) |
| 文档 / 死代码 | 6 | 1 (P0-4 死代码) | 0 |
| Bug 修复 | 1 | 1 (P0-4 DateTime) | 0 |
| **合计** | **48** | **8** | **17** |

---

## 跟现有 P2_DESIGN_REVIEW.md 的关系

| 报告 | 视角 | 重点 | 适用场景 |
|---|---|---|---|
| `docs/P2_DESIGN_REVIEW.md` (emil) | 设计工程师 | 微交互 / 视觉 polish / 动效 token 应用 | 设计师主导的 polish 工作 |
| `docs/P2_SYSTEM_REVIEW.md` (本报告) | superpowers-en | 架构 / 安全 / 测试 / 错误处理 / 性能 | 工程师主导的债务清理 |

**两不冲突,互补**:
- emil 报告的 P0-1/2/3/4/5/6/7/8 (8 项) 跟本报告的 P0-1/2/3/4/5/6/7/8 **完全不同**
- 只有 P0-5 (dark mode 残留) 在两份都提到
- 建议两份并入 `docs/P2_ROADMAP.md`,按 P0/P1/P2/P3 汇总去重

---

## 改动文件预算 (P0 全做)

- 10+ 处 PII 脱敏 (P0-1)
- 4 个 service 改 entity 签名 (P0-2)
- main.dart + app.dart 改 (P0-3)
- 1 行改 (P0-4)
- 3 处死代码删 (P0-5)
- trend_page 拆 7 个 widget (P0-6)
- web.dart 改 throw (P0-7)
- 4 个 drift table 加 index + migration v7→v8 (P0-8)
- 1 个 runZonedGuarded 单元 test
- 1 个 PII redacted 单元 test
- 1 个 entity signature 编译失败 test (防止再退化)
- 1 个 index 性能 test (验证 query plan)

**总计**: ~15-20 小时单人工作量,建议拆 3 个 round:
- **Round P2-1**: P0-1 + P0-2 + P0-3 + P0-4 + P0-5 (隐私 / 架构 / 错误 / bug / 死代码,~6h)
- **Round P2-2**: P0-6 + P0-7 (god-page + web,~5-8h)
- **Round P2-3**: P0-8 + P1-1 + P1-5 (data 性能 + 完整性,~5h)
- 每个 round 跑 `flutter analyze + flutter test + dart scripts/check_all.dart + python scripts/check_cross_feature.py` 后 commit
