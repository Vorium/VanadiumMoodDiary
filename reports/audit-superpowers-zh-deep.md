# 慢病管家 (ChronicCare) · superpowers-zh 深度审计报告

> **审计视角**: superpowers-zh 中文方法论 6 skill (systematic-debugging / chinese-code-review / chinese-commit-conventions / chinese-git-workflow / chinese-documentation / verification-before-completion)
> **审计范围**: lib/ (232 dart) + test/ (115) + scripts/ (133) + docs/ (52) + 配置 + 8 守护脚本跑分 + .commit_msg 历史
> **审计时间**: 2026-07-27 (对应 git HEAD fdfa172 v0.27 round 60)
> **审计模式**: 纯只读 (read-only)，未修改任何源代码

---

## 0. Summary

### 0.1 总体评价：**良好 (有结构性 P0 隐患)**
- **架构纪律**优秀：4 层架构纯度 100% (`check_all.dart` 双 ✅)，跨 feature import 0 violation (66 files checked)
- **测试纪律**优秀：~1098 tests, 12 守护脚本 + 4 个 dateTime / SMS 软规则脚本
- **国际化纪律**中等：zh / en / zh_Hant 3 个 locale 100% 同步 (551 keys)，但仍有 5+ 处 hardcode 中文穿透到 presentation 层
- **中国合规** ⚠️ **不及格**：
  - AliyunSms 真接 **0 实施** (`throw UnimplementedError`)，release 模式 `validateForRelease` 不阻断 (`isProductionReady=true`)，失联通知实际**永远发不出去**
  - 紧急联系人单独同意 (PIPL §13 + §23 第三方告知) **0 实施** — 仅文档化豁免
  - `displayMessage` 7 个 case hardcode 中文 (失联通知 UI)
  - SMS body 2 套模板措辞不一致 (ReminderService "请你方便的时候提醒 TA" vs SafetyAlertDispatcher "如确认安全请回复 1")
- **工程卫生**：版本号严重落后 (pubspec 0.25.0+1 但实际工作到 v0.27 round 60，CHANGELOG 无 v0.26/v0.27 段)；多个守护脚本不返回 exit code (CI 永远绿)

### 0.2 问题统计

| 维度 | 数量 | 备注 |
|---|---|---|
| **P0 致命风险** | 3 | 数据丢失 / 安全 / 用户承诺失约 |
| **P1 重要 bug** | 8 | 实际体验/合规破坏 |
| **P2 边界 case** | 7 | 守护脚本盲点 / race 隐患 |
| **P3 工程质量** | 7 | 工程卫生 / 文档同步 |
| **PIPL 合规风险** | 6 | §13 / §14 / §23 / §38 |
| **中文规范问题** | 5 | 硬编穿透 / 命名不一致 / 措辞分歧 |
| **守护脚本盲点** | 5 | 不 sys.exit / 状态误报 |

### 0.3 Top 10 关键问题 (按 file:line)

1. **P0** `lib/core/data/services/sms_service.dart:156-160` — `AliyunSmsProvider.send()` 永远 `throw UnimplementedError`，release 模式失联通知"已自动通知紧急联系人"是**空头承诺**
2. **P0** `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` — 添加联系人**没有任何单独同意**流程，PIPL §13 + §23 0 实施
3. **P0** `lib/core/data/services/notification_service.dart:361-363` — SafetyAlert 通知对用户说"已自动通知紧急联系人，请确认安全"，但 mock / 假 release 模式下**根本没发**
4. **P1** `lib/core/data/services/safety_watch_service.dart:323-343` — `displayMessage` 7 case 全部 hardcode 中文，en 模式用户看到中文
5. **P1** `lib/core/data/services/reminder_scheduler.dart:218-230` 与 `lib/core/data/services/safety_alert_dispatcher.dart:42-43` — **2 套失联 SMS body 措辞不一致** (TA 按时吃药 / 如确认安全请回复 1)
6. **P1** `lib/presentation/pages/home/home_page.dart:407-412` — `Future.delayed(1800ms)` 不可 cancel，widget 销毁后仍 fire → `entry.remove()` 抛 "OverlayEntry not mounted" 异常
7. **P1** `lib/presentation/pages/setup/setup_page.dart:431` — `action: '完成设置'` hardcode 中文 snackbar (v0.27 R59 修正时埋的)
8. **P1** `lib/core/shared/user_name_helper.dart:20` — `safeUserName` fallback hardcode 中文 `'您'`，en 模式用户拿到中文 fallback
9. **P1** `pubspec.yaml:4` version `0.25.0+1` 严重落后 — v0.26 R57 + v0.27 R58/59/60 共 10+ commit 不在 CHANGELOG
10. **P2** `scripts/check_datetime_race.py:55-57` + `scripts/check_datetime_race2.py:74-75` — **两个脚本都不 `sys.exit()`**，CI 永远绿 (但 home_page.dart:339 cross-method `DateTime.now()` race 漏检)

---

## 1. 系统化调试 — Bug 清单 (按 P0→P3 排序)

### BUG-01 [P0] AliyunSmsProvider.send() 永远 throw UnimplementedError — release 失联通知空头承诺

- **症状**：release 模式用户失联 48h，UI 显示"已自动通知紧急联系人，请确认安全"，但紧急联系人**从未收到任何消息**
- **复现路径**：
  1. 用真机 + 阿里云账号注册
  2. 加紧急联系人
  3. 故意漏 48h 不打卡
  4. SafetyWatch 触发 → `SafetyAlertDispatcher.dispatchAlert` 调 `_smsService.send` → `AliyunSmsProvider.send` 抛 `UnimplementedError`
  5. `SmsResult.fail(...)` → `dispatched.smsFail++` → `SafetyCheckResult.contactsFailed=1` → UI 显示"已告警：N 天前打卡，已通知 0 位联系人（1 失败）"
  6. 但**同时间本地通知** `showSafetyAlert` 仍 push："已自动通知紧急联系人，请确认安全"（谎话）
- **Root cause**：`AliyunSmsProvider.isProductionReady = true` (L122) 但 `AliyunSmsProvider.send()` (L125-161) 永远 `throw UnimplementedError`。`SmsService.validateForRelease` (L231-241) 只检查 `isProductionReady`，**不实际 ping provider**。`check_sms_release_ready.py` 守门员 v0.27 R58 修正时降级为 warn-only。
- **证据**：
  - `lib/core/data/services/sms_service.dart:122` `bool get isProductionReady => true;`
  - `lib/core/data/services/sms_service.dart:156-160` `throw UnimplementedError('AliyunSmsProvider.send() R55 真接 TODO — ...');`
  - `lib/core/data/services/sms_service.dart:231-241` `validateForRelease` 只 check `isProductionReady`
  - `lib/core/data/services/notification_service.dart:361-363` SafetyAlert 本地通知对用户说"已自动通知紧急联系人"
  - `scripts/check_sms_release_ready.py:138` 修正后 `return 0` warn-only
- **影响范围**：
  - **所有 release 模式用户**：失联通知 100% 失约
  - **精神心理患者群体**：这是产品核心承诺"漏 2 天 → 自动通知家人" — 漏就是用户死亡没人知道
  - **PIPL §28 (敏感个人信息泄露防护) + 民事侵权风险**
- **修复建议**：
  1. 短期 (P0 fix)：在 `SmsService.validateForRelease` 加 provider "ping" — 实际调一次 `send` 到 test endpoint，抛错则阻断 release
  2. 短期：在 `SafetyAlertDispatcher` 加 fall-through — 通知文案"已尝试通知紧急联系人" 而非"已自动通知"
  3. 长期：A-01 真接阿里云 SMS (1-2 月法务模板审核)
  4. **测试**：mock provider 跑 release 模式启动应该看到 `SmsProviderNotConfiguredError`，真接后跑真发成功路径
- **难度**：M (短期)+ L (真接)
- **优先级**：**P0**

### BUG-02 [P0] 紧急联系人添加无单独同意流程 — PIPL §13 + §23 0 实施

- **症状**：用户添加紧急联系人时，联系人**完全不知道自己的手机号会被用于"失联通知"。PIPL §13 单独同意 (separate consent) 和 §23 第三方 PII 告知要求联系人本人明确知情同意
- **复现路径**：
  1. 用户 A 完成 setup，输入紧急联系人 B 的姓名 + 手机号
  2. A 漏 2 天未打卡 → SMS 自动发给 B："【慢病管家】A 已 48h 未打卡，如确认安全请回复 1"
  3. B 收到陌生短信，第一次听说"我被加为紧急联系人" — **B 无任何同意机会**
- **Root cause**：
  - `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` `_showAddContactDialog` 的 `add()` 直接 insert contact，**无 consent UI**
  - `lib/presentation/pages/setup/setup_legal_dialog.dart:5-9` 注释明确承认"PIPL §13 单独同意 0 实施 (R58 文档化)"，但 `check_legal_consent.py` 用 `EXEMPT_LINE_RE = re.compile(r'✅|已实施|implemented|done|R\d+')` 把任何带 ✅ 的行豁免 — **脚本盲点**
- **证据**：
  - `lib/presentation/pages/contact/contacts_list_widget.dart:188-220` 添加按钮 onclick 流程 — 无 consent 步骤
  - `lib/presentation/pages/setup/setup_legal_dialog.dart:5-9` "PIPL §13 单独同意 0 实施"
  - `lib/presentation/pages/setup/setup_legal_dialog.dart:23` `当前状态: ✅ R58 文档化 (软实施: 用户主动告知, 联系人主动确认留 A-01)` — 用 ✅ 触发豁免
  - `scripts/check_legal_consent.py:41` `EXEMPT_LINE_RE = re.compile(r'✅|已实施|implemented|done|R\d+')` — 过宽豁免
- **影响范围**：
  - **法律风险**：PIPL §13 / §23 / 民法典第1035 条个人信息处理规则
  - **伦理风险**：精神心理患者联系人可能是父母/同事，**在不知情下被卷入医疗隐私**
  - **伦理风险**：B 可能因 A 失联 SMS 而报警 / 通知单位 → 二次伤害
- **修复建议**：
  1. **P0 短期**：添加联系人时弹 dialog："已告知联系人本人此功能并获同意？(PIPL 要求)" — 用户主动声明
  2. **P0 中期**：A-01 SMS 真接后，setup 时给 B 发"同意接收失联通知"短信，B 回复 "Y" 才算 confirmed
  3. **修守门员**：`EXEMPT_LINE_RE` 加"实施已完成"语义，不能仅看 ✅
  4. **测试**：TDD — mock SMS server 验证 confirmed=false 的 contact 不会收到失联通知
- **难度**：M (短期)+ L (A-01)
- **优先级**：**P0**

### BUG-03 [P0] SafetyAlert 本地通知声称"已自动通知紧急联系人" — 与实际 SMS 状态不符

- **症状**：用户**收到自己手机的通知**说"已自动通知紧急联系人，请确认安全"，但可能根本没人收到。精神心理患者看到通知以为有人知道 → 实际上没人知道 → 错过最佳救援时间
- **复现路径**：
  1. release 模式 + AliyunSmsProvider (isProductionReady=true 但 send throw)
  2. 用户漏 48h → `_checkAndAlert` → `_alertDispatcher.dispatchAlert` → SMS 全部 `SmsResult.fail` → `dispatched.smsFail=N`
  3. 同时间 `showSafetyAlert` 推本地通知
  4. 用户看到 ⚠️ 张三 已 3 天未打卡 / 上次打卡: ... / 已自动通知紧急联系人，请确认安全
- **Root cause**：`safety_alert_dispatcher.dart:81-85` 推本地通知**不知道 SMS 是否真发** — 应根据 `dispatched.smsOk` vs `smsFail` 动态生成文案
- **证据**：
  - `lib/core/data/services/safety_alert_dispatcher.dart:81-85` 推本地通知
  - `lib/core/data/services/notification_service.dart:353-365` hardcode body "已自动通知紧急联系人，请确认安全"
- **影响范围**：精神心理患者关键救援时机
- **修复建议**：
  1. `dispatchAlert` 返回 SMS 状态 → `showSafetyAlert` 接受 `smsStatus` 参数 → 文案分支：
     - `smsOk > 0`："已自动通知 N 位紧急联系人"
     - `smsOk == 0 && smsFail > 0`："⚠️ 通知紧急联系人失败，请手动联系"
     - `mock`："（未配置真实 SMS，已自动通知功能不可用）"
  2. **测试**：mock SMS provider 跑 dispatchAlert 验证通知文案
- **难度**：S
- **优先级**：**P0**

### BUG-04 [P1] `displayMessage` 7 case hardcode 中文 — en 模式用户看到中文

- **症状**：用户在 en locale 下打卡，安全告警触发 SnackBar 显示"已告警：3 天前打卡，已通知 0 位联系人（1 失败）" — 中文 UI 出现在英文模式
- **复现路径**：
  1. iOS/Android 设置英文
  2. 漏 2 天未打卡
  3. SafetyWatch 触发
  4. SnackBar `action: '⚠️ ${result.displayMessage}'` 渲染中文
- **Root cause**：`SafetyCheckResult.displayMessage` getter (L323-343) 用 switch 返回 hardcode 字符串 — 整个 v0.25 R57 god class 拆分时遗留
- **证据**：
  - `lib/core/data/services/safety_watch_service.dart:323-343` `String get displayMessage` — 7 case 全中文
  - `lib/presentation/pages/home/home_page.dart:153, 320` 两处 SnackBar 引用 `result.displayMessage`
  - `lib/l10n/app_zh.arb` 无 `safetyCheck*` key (没走 i18n 流程)
- **影响范围**：所有 en 模式用户的失联告警 UI
- **修复建议**：
  1. `SafetyCheckResult` 改为纯数据 (`enum SafetyCheckKind`)，文案走 `l10n.safetyCheckDisabled/Ok/NoData/...`
  2. **R57 拆分 god class 时遗漏** — R60 修正批次补
  3. **TDD 验证**：所有 7 case 跑 en/zh locale 都能拿到对应翻译
- **难度**：M
- **优先级**：P1

### BUG-05 [P1] 2 套失联 SMS body 措辞不一致 — 同一目的 2 种风格

- **症状**：紧急联系人 B 收到 SMS，可能是"【慢病管家】A 已 48h 未打卡。请你方便的时候提醒 TA 按时吃药" (ReminderService) 或"【慢病管家】A 已 2 天未打卡吃药。如确认安全请回复 1，无回复请联系本人或社区" (SafetyAlertDispatcher)。**2 套发同种短信，措辞不同** — B 困惑
- **复现路径**：
  1. 装新用户 + 加紧急联系人 B
  2. 漏 48h 不打卡
  3. SafetyWatch.onAppStart + ReminderService.checkAndSend 都可能触发
  4. 2 个 service 调 `_smsService.send` → B 收到 1+ 条风格不同的短信
- **Root cause**：
  - `lib/core/data/services/reminder_scheduler.dart:218-230` `_buildSmsBody` hardcode "请你方便的时候提醒 TA 按时吃药"
  - `lib/core/data/services/safety_alert_dispatcher.dart:42-43` `buildAlertSms` hardcode "如确认安全请回复 1，无回复请联系本人或社区"
  - 2 个 service 独立维护文案，无 single source of truth
- **证据**：
  - `lib/core/data/services/reminder_scheduler.dart:218-230` `_buildSmsBody` 方法
  - `lib/core/data/services/safety_alert_dispatcher.dart:42-43` `buildAlertSms` 方法
  - `lib/core/l10n/strings.dart:29-40` `emailSubject` / `emailBody` 已抽，但 SMS body 没抽
- **影响范围**：紧急联系人体验 (可能拒收/拉黑)
- **修复建议**：
  1. 抽 `SafetyWatchSmsTemplate` 集中器 (放 `core/l10n/strings.dart` 跟 email 模板并列)
  2. `String? override` 参数 + R57 override 模式
  3. **TDD 验证**：2 个 service 调同一模板
- **难度**：S
- **优先级**：P1

### BUG-06 [P1] `Future.delayed(1800ms)` 不可 cancel — OverlayEntry 卸载后 fire 引 race

- **症状**：用户打卡后看到庆祝 overlay，1.5s 内按返回键 / 跳转路由，widget tree 销毁。1.8s 后 `Future.delayed` 回调 fire → `entry.remove()` → 抛"OverlayEntry not currently mounted" 异常
- **复现路径**：
  1. 主页点"我今天吃了药" → `_showCelebrationOverlay` 插入 overlay
  2. 1.5s 内快速按返回键或点 settings
  3. 1.8s 时 `Future.delayed` 回调执行 `entry.remove()` → mounted=false → 异常被 swallow 但 noise
- **Root cause**：`Future.delayed` 不可 cancel，**已有先例** `loading_skeleton.dart:127-138` v0.27 R59 修正改用 `Timer?` 字段可 cancel — **home_page 跟修**
- **证据**：
  - `lib/presentation/pages/home/home_page.dart:407-412` `Future.delayed(const Duration(milliseconds: AppTokens.celebrationDisplayMs), () { if (entry.mounted) entry.remove(); });`
  - `lib/presentation/widgets/loading_skeleton.dart:120-138` 已修正模式
  - `lib/core/theme/app_tokens.dart:301-302` `static const int celebrationDisplayMs = 1800;` (已 token 化但还硬编码 Future.delayed)
- **影响范围**：所有打卡用户（高概率触发 — 庆祝 1.8s 比 1.5s 长）
- **修复建议**：
  1. `_showCelebrationOverlay` 改为 async + `Timer?` 字段，`dispose` 时 cancel
  2. 或把 overlay 改成 `AnimatedOpacity` + 自动 fade-out，不依赖 `Future.delayed`
  3. **TDD 验证**：rapid nav 100 次连续无 exception
- **难度**：S
- **优先级**：P1

### BUG-07 [P1] `setup_page.dart:431` `action: '完成设置'` hardcode 中文 snackbar

- **症状**：en 模式用户 setup 失败，snackbar action 显示"完成设置"中文
- **复现路径**：
  1. iOS 设置英文 locale
  2. 走 setup 流程，故意断网让 watchAll timeout
  3. 触发 v0.27 R59 修正后的 fail-loud 路径
  4. snackbar action 渲染 "完成设置"
- **Root cause**：v0.27 R59 修正 `setup_page.dart:409-413` 时（修正 fail-soft → fail-loud）顺手在 L431 加了 `action: '完成设置'` — **修正时没走 l10n 路径**
- **证据**：
  - `lib/presentation/pages/setup/setup_page.dart:425-434` catch 块 hardcode action
  - `lib/presentation/widgets/app_snack_bar.dart:20` 注释 `action: '保存'` 是正确示范（走 l10n 集中器）
  - `lib/l10n/app_zh.arb` / `app_en.arb` 无 `snackbarActionCompleteSetup` key
- **影响范围**：en 模式用户 setup 失败提示
- **修复建议**：
  1. 加 `l10n.snackbarActionCompleteSetup` ARB key (zh: "完成设置" / en: "Complete setup")
  2. 修正 setup_page.dart:431 走 `AppLocalizations.of(context).snackbarActionCompleteSetup`
  3. **TDD**：grep `action:\s*'[^']*[\u4e00-\u9fff]'` 找其它漏修正点
- **难度**：S
- **优先级**：P1

### BUG-08 [P1] `safeUserName` fallback hardcode 中文 `'您'` — en 模式穿透

- **症状**：en locale 用户没填姓名 → 通知 / SMS 显示"⚠️ 您 已 3 天未打卡" — en UI 出现中文 fallback
- **复现路径**：
  1. 新用户 setup 不填姓名
  2. 漏 2 天 → 触发 SafetyAlert
  3. 本地通知 title: `'⚠️ $name 已 $daysWithoutCheckIn 天未打卡'` → "⚠️ 您 已 3 天未打卡"
- **Root cause**：`user_name_helper.dart:20` `String safeUserName(String? value, {String fallback = '您'})` hardcode 中文 fallback — **shared 层 5+ 处引用**
- **证据**：
  - `lib/core/shared/user_name_helper.dart:20` `fallback = '您'`
  - `lib/domain/logic/email_template.dart:28, 55` `fallback: '您的家人'`
  - `lib/core/data/services/reminder_scheduler.dart:217` `fallback: '您的家人'`
  - `lib/core/data/services/notification_service.dart:334` `safeUserName(userName)` 用默认 '您'
  - `lib/core/data/services/safety_alert_dispatcher.dart:41` `safeUserName(userName)` 用默认 '您'
- **影响范围**：所有 en 模式 + 未填姓名的用户
- **修复建议**：
  1. 修正为 `String safeUserName(String? value, {String? fallback})` 无默认值
  2. Caller 必须传 `fallback: l10n.userNameFallbackYou` (zh: "您" / en: "You")
  3. **TDD**：所有 caller 跑 en locale 验证 UI 字符串不含中文
- **难度**：M (要改 5+ caller)
- **优先级**：P1

### BUG-09 [P1] `home_page.dart:87` `Future.delayed(100ms)` magic number — deep link race

- **症状**：用户点通知 deep link → home → `_handleDeepLink` → 等 100ms → 跑 safety check。**100ms 是 magic number**，弱机 100ms 内 widget tree 没就绪 → safety check 跑空
- **复现路径**：
  1. App 在 background
  2. 用户点"⚠️ 已自动通知"通知 → cold start
  3. `_handleDeepLink` 等 100ms 跑 `_runSafetyCheck`
  4. 弱机 100ms 后 safety watch provider 还没初始化 → silently skipped
- **Root cause**：`home_page.dart:87` `await Future<void>.delayed(const Duration(milliseconds: 100));` — **AGENTS.md 已知坑**，但 R52 修正时只修正了 setup_page 没修正 home_page
- **证据**：
  - `lib/presentation/pages/home/home_page.dart:87` `await Future<void>.delayed(const Duration(milliseconds: 100));`
  - `lib/main.dart:107-110` 注释"用 addPostFrameCallback 替代 magic 100ms"
  - `lib/app.dart:108-115` 修正样例
- **影响范围**：deep link 路径 reliability
- **修复建议**：
  1. 修正为 `WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_runSafetyCheck(force: true)));`
  2. **TDD**：rapid deep link 100 次不丢 safety check
- **难度**：S
- **优先级**：P1

### BUG-10 [P1] `contact_repository.dart` add() 默认名 `'Contact'` 硬编码英文

- **症状**：zh 模式用户添加紧急联系人留空姓名 → 联系人列表显示"Contact" 英文
- **复现路径**：
  1. iOS zh locale
  2. 添加联系人输入手机号但留空姓名
  3. 联系人列表显示"Contact 13800138000"
- **Root cause**：`contacts_list_widget.dart:202-203` `nameController.text.trim().isEmpty ? 'Contact' : ...` — hardcode 英文默认
- **证据**：
  - `lib/presentation/pages/contact/contacts_list_widget.dart:202-203` `nameController.text.trim().isEmpty ? 'Contact' : ...`
- **影响范围**：所有添加联系人留空姓名的用户
- **修复建议**：
  1. 修正为 `l10n.contactDefaultName` (zh: "联系人" / en: "Contact")
  2. 或强制必填 (空姓名 → snackbar 提示)
  3. **TDD**：zh/en locale 验证默认名本地化
- **难度**：S
- **优先级**：P1

### BUG-11 [P2] `assessment_comparison.dart:225` `now ?? DateTime.now()` 函数末尾再调 — 跨 midnight 微 race

- **症状**：函数入口可能没传 `now` 参数，末尾 `now ?? DateTime.now()` 在长 await 链后再调，理论跨 00:00:00 会跟函数内其它时间不一致
- **复现路径**：
  1. 23:59:58 调 `fromRecords(records, scaleId)`
  2. 函数内 `severityRankFor` await 内部 23:59:59 → 00:00:00
  3. L225 `now ?? DateTime.now()` 在 00:00:00 后取值
  4. `daysSincePrevious` 算 1 天 (实际应是 0 天)
- **Root cause**：`assessment_comparison.dart:225` `_daysBetween(previous.timestamp, now ?? DateTime.now())` 允许 caller 传 null，函数末尾再调
- **证据**：
  - `lib/domain/logic/assessment_comparison.dart:225`
  - AGENTS.md 已知坑 "DateTime.now() 跨 midnight race" 修正模式
- **影响范围**：罕见 timing-dependent bug
- **修复建议**：
  1. 函数入口 `final now = now ?? DateTime.now();` 一次取，下面复用
  2. **TDD 回归**：00:00:00 边界测试
- **难度**：S
- **优先级**：P2

### BUG-12 [P2] `data_export_service.dart:226-247` importData 删除所有数据 — 撤回同意后数据仍在 DB

- **症状**：用户撤回"评估分析"同意 (PIPL §14)，但 DB 里 `moodEntries` 仍存历史数据。`importFromJson` 在导入时**先清空所有表** → 即使撤回评估同意，旧数据也无法选择性删除
- **复现路径**：
  1. 累积 30 条 mood entries
  2. 设置 → 法律与隐私 → 撤回"评估分析"
  3. 期望：moodEntries 表清空；实际：DB 仍有 30 条，只是 UI 不显示
- **Root cause**：
  - `legal_page.dart:160-163` toggle `ConsentKind.analytics` 只改 SharedPreferences，**不动 DB**
  - `lib/core/data/services/export/export_orchestrator.dart:227-247` importFromJson 是 `delete all then insert` 全量覆盖，无法按 consent 过滤
  - PIPL §14 要求"撤回后必须删除 / 停止处理"
- **证据**：
  - `lib/presentation/providers/legal_consent_provider.dart:46-59` `withdraw/reset` 只写 SharedPreferences
  - `lib/core/data/services/export/export_orchestrator.dart:226-247` delete all
  - `lib/presentation/pages/settings/legal_page.dart:160-163` 撤回 toggle
- **影响范围**：撤回评估分析/失联通知/树洞同意的用户
- **修复建议**：
  1. 修正 toggle：撤回时同步调 `_db.delete(_db.moodEntries).where(...).go()` 等
  2. importFromJson 加 `consentFilter` 参数
  3. **TDD**：撤回后 import 验证 DB 行数
- **难度**：M
- **优先级**：P2

### BUG-13 [P2] `_refillBaseId + 1000` 历史包袱在 `refill_notifier.dart:188` 注释

- **症状**：v0.16 round 19 fix 已修正 200000 cancel range，但代码注释里**仍说 1000 范围会漏 cancel**。新 reader 看到注释误解
- **复现路径**：grep 找 `1000` / `cancel.*range` 看注释与实现
- **Root cause**：
  - `lib/core/data/services/refill_notifier.dart:188` 注释 "之前 `_refillBaseId + 1000` 范围太窄"
  - L196 `await _dispatcher.cancelByIdRange(refillBaseId);` 实际修正用 dispatcher
- **影响范围**：代码可读性 / 后续维护者误解
- **修复建议**：简化注释，只留"v0.16 round 19B: 200000 range 修正 medId >= 1000 漏 cancel"
- **难度**：S
- **优先级**：P2

### BUG-14 [P2] `refill_notifier.dart:111-117` `fireAt == null` 静默 no-op — 用户无感知

- **症状**：`scheduleRefillReminder` 调 `computeRefillFireTime` 当 `medication.refillAt == null` 返 null → 静默 return，**只 piiSafeLog debug mode 可看**。用户设置续方时没设 `refillAt`，永远不知道续方提醒没排上
- **复现路径**：
  1. 添加 medication 没填续方日期
  2. 30 天后没提醒
  3. 用户不知道为什么
- **Root cause**：`refill_notifier.dart:111-117` 静默 no-op，无返回值
- **证据**：
  - `lib/core/data/services/refill_notifier.dart:111-117` `if (fireAt == null) { piiSafeLog(...); return; }`
  - `lib/core/data/services/refill_notifier.dart:106-110` 无返回类型
- **影响范围**：忘记填续方日期的用户
- **修复建议**：
  1. 加 `bool scheduleRefillReminder(...)` 返回值，false 调 caller SnackBar 提示
  2. 或在 `medication_calendar_page` 加 "请设置续方日期" 提示
- **难度**：S
- **优先级**：P2

### BUG-15 [P2] `safety_watch_service.dart:343` errorMessage 包含原始 exception.toString() — 信息泄露

- **症状**：`SafetyCheckResult.errorMessage` 是 `e.toString()` 透传给用户 SnackBar，可能包含 stack trace 或 SQL 错误
- **复现路径**：
  1. 模拟 DB 异常 (`database lock`)
  2. `_checkAndAlert` catch → `e.toString()` → `'Error: database is locked'`
  3. SnackBar 显示
- **Root cause**：
  - `lib/core/data/services/safety_watch_service.dart:267-271` `errorMessage: e.toString()`
  - `lib/core/data/services/safety_watch_service.dart:341-343` displayMessage error case 透传 errorMessage
- **影响范围**：错误状态 UI
- **修复建议**：
  1. `errorMessage: l10n.safetyCheckError` 走 ARB，原始 `e.toString()` 只 log
  2. **TDD**：所有 error case 验证 UI 不含 "Error" / "Exception" 关键字
- **难度**：S
- **优先级**：P2

### BUG-16 [P2] `safety_alert_dispatcher.dart:64-78` 串行发 SMS — 慢

- **症状**：用户有 N 个紧急联系人时，串行 for 循环 `await _smsService.send`，总耗时 N × 单条延迟。10 个联系人 = 10s 阻塞
- **复现路径**：
  1. 加 10 个紧急联系人
  2. 触发失联告警
  3. `_runSafetyCheck` 等 10s 才返回（用户体验：主页卡顿）
- **Root cause**：
  - `lib/core/data/services/safety_alert_dispatcher.dart:64-78` for 循环串行 await
  - 与 `reminder_scheduler.dart:109-118` (用 `Future.wait` 并发) 不一致
- **影响范围**：多联系人的用户
- **修复建议**：
  1. 修正为 `Future.wait(contacts.map((c) => _smsService.send(to: c.phone, body: body)))` 配合 outer timeout
  2. **TDD**：10 个 mock provider 测总耗时 < 2s
- **难度**：S
- **优先级**：P2

### BUG-17 [P3] `safety_watch_service.dart:298-305` 8 个 `@Deprecated` facade 仍暴露 — caller 仍用旧 API

- **症状**：v0.26 R57 给 8 个 config API 加 `@Deprecated` 注解，注释说"改用 safetyConfigServiceProvider"。R60 修正说"修正后删 8 facade"，但实际**没删** — caller 仍用旧 facade
- **复现路径**：`grep -rn "isEnabled\|setEnabled\|getThresholdDays" lib/` 找 caller
- **Root cause**：
  - `lib/core/data/services/safety_watch_service.dart:89-124` 8 个 deprecated method
  - `lib/core/data/services/safety_watch_service.dart:81-83` 注释"v0.27 R60 修正后再删 facade，实际没删"
- **影响范围**：API 整洁度
- **修复建议**：v0.28 R60+ 修正删 facade + 修正所有 caller
- **难度**：M
- **优先级**：P3

### BUG-18 [P3] `contact_repository.dart` add() 接口无 consentConfirmedAt 字段

- **症状**：`ContactEntity` 无 `consentConfirmedAt` 字段，UI 也无"已确认/未确认"显示
- **Root cause**：`setup_legal_dialog.dart:21` 注释明确"联系人状态字段 (UserProfile 或 ContactEntity 加 consentConfirmedAt) 卡 A-01"
- **证据**：
  - `lib/presentation/pages/setup/setup_legal_dialog.dart:21-22` "联系人状态字段 (UserProfile 或 ContactEntity 加 consentConfirmedAt) 卡 A-01"
- **影响范围**：PIPL §13 实施前置条件
- **修复建议**：A-01 真接 SMS 后加字段
- **难度**：L (要 A-01 落地)
- **优先级**：P3

### BUG-19 [P3] `_refillBaseId + 200000` 注释 (refill_notifier.dart:188) 跟实际 `_dispatcher.cancelByIdRange(refillBaseId)` 不一致

- **症状**：注释说"改 cancel 范围到 200000" 但实际用 `_dispatcher.cancelByIdRange(refillBaseId)` (L196) 没传范围上限 — dispatcher 内部默认是多少？看 dispatcher
- **Root cause**：注释历史包袱，没跟上重构
- **证据**：`lib/core/data/services/refill_notifier.dart:188-196`
- **影响范围**：代码可读性
- **修复建议**：看 `reminder_dispatcher.dart: cancelByIdRange` 实现确认 default range，注释同步
- **难度**：S
- **优先级**：P3

### BUG-20 [P3] `vent_repository.dart` (domain interface) 缺 `getByIdTimestampSorted` 排序保证

- **症状**：`VentRepository.watchAll()` 实现是 `_db.watchVentEntries()` 但 DB 缺 `orderBy` — caller 拿到的列表是无序的，UI 要自己 sort
- **复现路径**：
  1. 树洞 list_page watchAll
  2. UI 显示顺序依赖 drift 默认顺序
- **Root cause**：
  - `lib/core/data/repositories/vent/vent_repository_impl.dart:33-40` `return _db.watchVentEntries().asyncMap(...)` — 无 orderBy
  - 看 `vent_dao.dart` 是否加 orderBy
- **影响范围**：树洞 list 显示顺序
- **修复建议**：DB 层加 `orderBy([(t) => OrderingTerm.desc(t.timestamp)])`
- **难度**：S
- **优先级**：P3

---

## 2. 中文代码审查

### 2.1 命名规范

| 问题 | file:line | 说明 | 难度 | 优先级 |
|---|---|---|---|---|
| 拼音 / 英文混杂 | `lib/core/data/services/encrypted_audio_storage.dart` 类名是英文"encrypted_audio_storage"，但中文注释说"树洞 vent 跟 情绪 mood 是 2 个独立 privacy 模块" — 命名 OK 但注释跟代码不同语言 | 不一致但可读 | P3 |
| 缩写不规范 | `lib/core/data/services/pii_safe_log.dart` PII 解释用了 PII 但代码全大写，OK | OK | - |
| 拼音命名 | 未发现 `shijian/yonghu/denglu` 等拼音变量 | 0 命中 | OK |
| DTO 命名 | `ContactEntity` / `UserProfile` 等统一 Entity 后缀 — OK | OK | - |

### 2.2 注释质量

| 文件 | 注释覆盖率 | 备注 |
|---|---|---|
| `lib/main.dart` | 100% 头注释 + 关键段落 | 优秀 |
| `lib/core/data/services/notification_service.dart` | 100% | 优秀 |
| `lib/core/data/services/safety_watch_service.dart:323-343` | 0 — `displayMessage` switch 7 case 无注释 | 差 (P1) |
| `lib/core/shared/user_name_helper.dart` | 90% | 良好 |
| `lib/core/data/services/reminder_scheduler.dart:218-230` `_buildSmsBody` | 50% — 缺 SMS 模板用法说明 | 中 |

### 2.3 错误信息 (用户可见 vs 内部 stack trace)

| 位置 | 问题 | 难度 | 优先级 |
|---|---|---|---|
| `lib/core/data/services/safety_watch_service.dart:267-271` | `errorMessage: e.toString()` 透传给 UI，可能含 stack | S | P1 |
| `lib/core/data/services/safety_watch_service.dart:341-343` | displayMessage error case 透传 | S | P1 |
| `lib/core/data/services/pii_safe_log.dart` | release 模式 swallow PII，dev 模式保留 stack — 设计正确 | - | OK |
| `lib/main.dart:44-50` `FlutterError.onError` | release 模式也走 `developer.log` — AGENTS.md 已知坑"developer.log 不受 kDebugMode 守卫" — 泄露 stack trace 到 logcat | M | P2 |

### 2.4 硬编码中文穿透

| file:line | hardcode 字符串 | 上下文 | 难度 | 优先级 |
|---|---|---|---|---|
| `lib/presentation/pages/setup/setup_page.dart:431` | `'完成设置'` | SnackBar action | S | P1 (BUG-07) |
| `lib/core/data/services/safety_watch_service.dart:323-343` | 7 case `displayMessage` | SnackBar 文案 | M | P1 (BUG-04) |
| `lib/core/data/services/reminder_scheduler.dart:218-230` | `_buildSmsBody` 4 行 | SMS 模板 | S | P1 (BUG-05) |
| `lib/core/data/services/safety_alert_dispatcher.dart:42-43` | `buildAlertSms` 2 行 | SMS 模板 | S | P1 (BUG-05) |
| `lib/core/shared/user_name_helper.dart:20` | `'您'` | fallback | M | P1 (BUG-08) |
| `lib/presentation/pages/contact/contacts_list_widget.dart:202-203` | `'Contact'` | 默认名 | S | P1 (BUG-10) |
| `lib/core/l10n/strings.dart:29-40` | `emailSubject` / `emailBody` 全中文 | domain fallback | M | P2 (待 v1.0 i18n 化) |
| `lib/core/l10n/strings.dart:55-57` | `emailFooter` 全中文 | email 模板 | M | P2 |
| `lib/core/data/services/notification_service.dart:353-365` | hardcode `'已自动通知紧急联系人，请确认安全'` | safety alert body | S | P0 (BUG-03) |
| `lib/core/data/services/notification_service.dart:361` | hardcode `'⚠️ $name 已 $daysWithoutCheckIn 天未打卡'` | safety alert title | S | P0 (BUG-03) |
| `lib/core/l10n/strings.dart:90-100` | `notifMedicationTitle` / `notifMedicationBody` 中文 | 通知 | M | P2 (R57 override 模式) |

### 2.5 log 规范 (developer.log vs print)

| file:line | 函数 | 规范 | 难度 | 优先级 |
|---|---|---|---|---|
| `lib/main.dart:45-49` | `developer.log('FlutterError', error: details.exception, stackTrace: details.stack);` | release 模式也会走 (AGENTS.md 已知坑) | M | P2 |
| `lib/main.dart:59` | `developer.log('FATAL UNCAUGHT', error: error, stackTrace: stack);` | 同上 | M | P2 |
| `lib/core/data/services/pii_safe_log.dart` | 用 `bool.fromEnvironment('dart.vm.product')` 守卫，release 不打印 | 设计正确 | - | OK |
| `lib/core/shared/swallow_error.dart:7-14` | 集中器，release swallow | 设计正确 | - | OK |

---

## 3. 中国合规 + 隐私 (PIPL / NMPA / 精神心理患者保护)

### 3.1 PIPL §13 (数据可携权) — 部分实施

- **现状**：`lib/core/data/services/data_export_service.dart` 实现 `exportToJson` + `importFromJson`，支持 PIPL §13 跨设备数据迁移
- **问题**：
  - `importFromJson` 是**全量覆盖** (`export_orchestrator.dart:226-247` 先 `delete all`)，不能"按 consent 选择性导入"
  - 用户撤回同意 (PIPL §14) 后，历史数据**仍在 DB** (BUG-12)
- **证据**：
  - `lib/core/data/services/export/export_orchestrator.dart:208-247` importFromJson 全量覆盖
  - `lib/presentation/providers/legal_consent_provider.dart:46-59` withdraw 只写 SharedPreferences
- **风险等级**：**P1**
- **修复建议**：
  1. `withdraw(kind)` 同步调 `_db.delete(_db.moodEntries).where(...).go()` (按 kind 选表)
  2. importFromJson 加 `consentFilter` 参数
  3. **TDD 验证**：撤回"评估分析" → DB moodEntries 表行数 = 0
- **难度**：M

### 3.2 PIPL §14 (撤回同意可逆) — 部分实施

- **现状**：
  - `lib/presentation/pages/settings/legal_page.dart` 提供撤回 toggle
  - `lib/presentation/providers/legal_consent_provider.dart` 持久化撤回时间
- **问题**：
  - 撤回时**只改 SharedPreferences**，**不动 DB 数据** (BUG-12)
  - 重新同意时 (`reset`) 只清 SharedPreferences，**不会自动恢复数据** (PIPL §14 重新同意的逻辑)
- **证据**：
  - `lib/presentation/providers/legal_consent_provider.dart:46-59` withdraw/reset 只动 SharedPreferences
  - `lib/presentation/pages/settings/legal_page.dart:52-73` `_toggle` 也不动 DB
- **风险等级**：**P1**
- **修复建议**：
  1. withdraw 时同步删 DB 行
  2. reset 时给 UI 提示"历史数据已删除，不会自动恢复"
  3. 数据可携的"删除"vs"匿名化"概念要明确
- **难度**：M

### 3.3 PIPL §13 单独同意 (紧急联系人) — **0 实施** ⚠️

- **现状**：BUG-02 已详述，联系人无单独同意流程
- **风险等级**：**P0**
- **修复建议**：见 BUG-02

### 3.4 PIPL §23 第三方 PII 告知 — 间接违反

- **现状**：发给紧急联系人的 SMS 内容**包含用户姓名 + 用药信息** (`safety_alert_dispatcher.dart:42-43` "【慢病管家】$name 已 N 天未打卡吃药")，但联系人**不知情**
- **风险等级**：**P0**
- **修复建议**：同 BUG-02

### 3.5 PIPL §38 (跨境数据传输) — 未实现

- **现状**：`sms_service.dart:151-154` 注释明确：
  ```
  // 跨境 PIPL §38:
  // - +86 大陆号段 → AliyunSms
  // - +1/+44/+852 海外号段 → TwilioSmsProvider (需 Twilio 境内代理备案)
  // - SmsService.send 入口加号码归属地路由 (R55+)
  ```
  但**实际** R55+ 修正计划**未实施**
- **风险等级**：**P1** (用户海外时家人也是 +86，仍走 AliyunSms，没问题；用户是海外时无 provider，mock 失败)
- **修复建议**：SmsService.send 加号码归属地路由
- **难度**：M

### 3.6 NMPA 医疗器械备案 — 未明确

- **现状**：
  - `docs/CHANGELOG.md:18` 提"R54 DEPLOYMENT.md + privacy_policy.md + README.md 合规 — 阶段 8 / 附录 A (NMPA / HIPAA / GDPR / PIPL)"
  - 但 app **声称是"慢病管家"** (慢性病管理类)，中国 NMPA 是否需要二类医疗器械备案？**README 没说**
- **风险等级**：**P1**
- **修复建议**：
  1. README 明确"本 app 属健康管理类，非医疗器械，不提供医疗建议"
  2. `assets/legal/user_agreement.md` 加免责声明
  3. 法务咨询是否触发 NMPA 备案

### 3.7 精神心理患者特别保护

- **现状**：
  - `lib/core/data/services/notification_service.dart:361` safety alert title 反复用 `⚠️` emoji，对精神心理患者可能造成焦虑
  - `lib/core/data/services/safety_watch_service.dart:323-343` "失联"措辞强烈
  - README 强调"措辞：温柔提醒" (L12) 但代码里**不一致**
- **风险等级**：**P2** (用户体验)
- **修复建议**：
  1. 通知文案走 `l10n.safetyAlert*` ARB key，统一"温柔"措辞
  2. A/B test emoji 焦虑度

---

## 4. 工程卫生

### 4.1 版本号 + CHANGELOG 严重落后

- **现状**：
  - `pubspec.yaml:4` `version: 0.25.0+1`
  - `docs/CHANGELOG.md` 最新条目 `[0.25.0] - 2026-07-26`
  - `git log` 显示已 commit `v0.27 round 60` (HEAD fdfa172)
  - **v0.26 R57 + v0.27 R58/59/60 共 10+ commit 不在 CHANGELOG**
- **影响**：
  - 用户/法务/投资人/合作方看到 v0.25 误判项目进展
  - 商店上传版本号要"递增"，从 0.25 直接升 0.27 是 minor + minor
  - `check_changelog.py:69-74` 只 check "第一段是否等于 pubspec version"，**漏检**
- **风险等级**：**P1**
- **修复建议**：
  1. 修正 pubspec → `0.27.0+1`
  2. CHANGELOG 补 `[0.26.0]` `[0.27.0]` 段
  3. 修正 `check_changelog.py` 加 "pubspec 跟最新 commit tag 不一致" 检查
- **难度**：S (mechanical)
- **优先级**：P1

### 4.2 commit msg 规范

- **现状**：
  - `.commit_msg_agents.md` 是 v0.25 R56f 写的模板
  - `.commit_msg_r56c3.txt` / `r56d.txt` / `r56e.txt` / `r56g.txt` / `r56h.txt` 5 个 round 草稿
  - 最新 commit (fdfa172) 风格：`<version> round <N>: <P级别> <类型> (<编号>) <描述>` — OK
  - 但 R57/R58/R59/R60 没 commit msg 草稿
- **风险等级**：**P3**
- **修复建议**：
  1. v0.27 R58/59/60 修正后写 `.commit_msg_r58.txt` 等草稿
  2. 或用 `git log --oneline | head -20` 总结成模板

### 4.3 Git 工作流

- **现状**：
  - `.github/workflows/ci.yml` 3 个 job (test / architecture / build)
  - ubuntu-latest + Flutter 3.41.9
  - 跑 `flutter analyze` + `flutter test` + `check_cross_feature --ci` + `check_arb_keys` + `check_drift_namespace --strict` + `check_datetime_race2` + `check_fullwidth_punctuation --ci`
  - **不跑**：`check_legal_consent` (PIPL 关键！) / `check_sms_release_ready` (虽然 warn-only) / `check_strings_hardcoded` / `check_orphan_arb_keys` / `check_no_pua` / `check_no_hardcoded_utc` / `check_fullwidth_punctuation` 是 include 但没看到 `check_widget_dispose`
- **风险等级**：**P2** (CI 漏关键检查)
- **修复建议**：补全 12 守护脚本到 CI
- **难度**：S

### 4.4 守护脚本盲点

| 脚本 | 盲点 | 风险 | 修复 |
|---|---|---|---|
| `scripts/check_datetime_race.py:55-57` | 无 `sys.exit()` — CI 永远绿 | P1 | 加 `return 0/1` |
| `scripts/check_datetime_race2.py:74-75` | 同上 | P1 | 同上 |
| `scripts/check_sms_release_ready.py:138` | warn-only (v0.27 R58 降级) | P0 (A-01 未真接) | v1.0 上 store 前升 hard fail |
| `scripts/check_legal_consent.py:41` | `EXEMPT_LINE_RE = re.compile(r'✅\|已实施\|implemented\|done\|R\d+')` 过宽 | P0 (PIPL §13 漏洞) | 加 "实施已完成" 语义 |
| `scripts/check_widget_dispose.py` | stdout GBK mojibake 在 Windows PowerShell | P3 (CI 看不到) | 用 `sys.stdout = io.TextIOWrapper(...)` 修正 |
| `scripts/check_changelog.py:69-74` | 只 check "第一段 == pubspec"，漏检 "pubspec 跟最新 commit 一致" | P1 | 加 commit history parse |
| `scripts/check_fullwidth_punctuation.py` | 11+ 行 violations 但 warn-only (CI exit 0) | P2 | 修正 exit code |

### 4.5 runZonedGuarded 错误处理

- **现状**：`lib/main.dart:53-71` `runZonedGuarded` 包裹 `_bootstrap` + 错误处理 (developer.log + LastErrorCapture)
- **问题**：
  - `developer.log('FlutterError', error: details.exception, ...)` release 模式也走 (BUG 2.5)
  - `developer.log('FATAL UNCAUGHT', error: error, stackTrace: stack)` release 模式也走
  - AGENTS.md 已知坑"developer.log 不受 kDebugMode 守卫，只 print 受" — 但代码仍用 developer.log
- **风险等级**：**P2**
- **修复建议**：
  1. release 模式用 `LastErrorCapture.record` 替代 `developer.log`
  2. dev 模式才走 `developer.log`
  3. **TDD 验证**：release 模式跑异常 → logcat 0 行 PII

### 4.6 测试质量

- **现状**：
  - 1098 tests
  - 0 analyzer error
  - `check_widget_dispose.py` 0 资源泄漏
  - `check_cross_feature.py` 0 violations
  - `check_arb_keys.py` zh/en/zh_Hant 同步
  - 5+ systematic-debugging regression tests (R59 修正 5 项)
- **缺失测试**：
  - `home_page.dart` 主页 widget test (CHANGELOG R60 修正计划提到"P0 每日用户路径 0 test")
  - `mood_recorder.dart` god class split 后 0 regression test (R52 修正 dispose race 但 0 regression test)
  - PIPL §13 单独同意 (BUG-02) 0 test
  - 失联 SMS 2 套模板一致 (BUG-05) 0 test
- **风险等级**：**P2**
- **修复建议**：
  1. R60 修正批次补 home_page widget test
  2. mood_recorder dispose race 修正后补 regression test (AGENTS.md 已知)
  3. PIPL §13 加 test

### 4.7 文档质量

- **现状**：
  - `AGENTS.md` 236 行 — 详细，覆盖 4 层架构 + 16 守护脚本 + 已知坑
  - `README.md` 149 行 — 中文，产品视角
  - `docs/CHANGELOG.md` 750 行 — 详细
  - `todo.md` **stale** (v0.26 R57 写的 todo，9 个 P0/P1，**没标完成状态**)
  - `docs/CHANGELOG.md` 不反映 v0.27 R58/59/60 (同 4.1)
- **风险等级**：**P2**
- **修复建议**：
  1. todo.md 标完成状态或删
  2. CHANGELOG 补 v0.26/v0.27 段

### 4.8 资产命名混乱

- **现状**：`assets/brand/` 有 `app_icon_v2/v3/v4/v5` + `app_icon_master_v2/v3/v4/v5` + `icon_preview_v2/v3/v4/v5` + `icon_showcase.html` — **30+ 文件无命名规律**
- **风险等级**：**P3**
- **修复建议**：git clean -fd `assets/brand/v*_v*` 留 v5 即可

---

## 5. Top 20 Actionable Fixes (按 P0→P3 排序)

| # | 视角 | 描述 | file:line | 难度 | 优先级 | TDD? |
|---|---|---|---|---|---|---|
| 1 | 系统化调试 + 中国合规 | AliyunSmsProvider.send() 真接 (短期 ping 守卫) | `lib/core/data/services/sms_service.dart:156-160` | M | P0 | ✓ |
| 2 | 中国合规 | 添加联系人加 consent 流程 (PIPL §13) | `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` | M | P0 | ✓ |
| 3 | 系统化调试 + 中国合规 | SafetyAlert 通知文案跟 SMS 实际状态联动 | `lib/core/data/services/notification_service.dart:361-363` | S | P0 | ✓ |
| 4 | 中国合规 | 修正 `check_legal_consent.py` EXEMPT_LINE_RE 严格化 | `scripts/check_legal_consent.py:41` | S | P0 | ✓ |
| 5 | 系统化调试 | `displayMessage` 7 case 走 l10n ARB | `lib/core/data/services/safety_watch_service.dart:323-343` | M | P1 | ✓ |
| 6 | 中文审查 | 抽 SMS 模板集中器 (ReminderService + SafetyAlertDispatcher 统一) | `lib/core/data/services/reminder_scheduler.dart:218-230` + `lib/core/data/services/safety_alert_dispatcher.dart:42-43` | S | P1 | ✓ |
| 7 | 系统化调试 | `Future.delayed(1800ms)` 修正为可 cancel Timer | `lib/presentation/pages/home/home_page.dart:407-412` | S | P1 | ✓ |
| 8 | 中文审查 | `setup_page.dart` snackbar action 走 l10n | `lib/presentation/pages/setup/setup_page.dart:431` | S | P1 | ✓ |
| 9 | 中文审查 | `safeUserName` fallback 修正为强制 caller 传 | `lib/core/shared/user_name_helper.dart:20` | M | P1 | ✓ |
| 10 | 系统化调试 | `home_page.dart:87` magic 100ms 修正为 addPostFrameCallback | `lib/presentation/pages/home/home_page.dart:87` | S | P1 | ✓ |
| 11 | 中文审查 | `contacts_list_widget.dart` 默认名 `'Contact'` 修正 | `lib/presentation/pages/contact/contacts_list_widget.dart:202-203` | S | P1 | ✓ |
| 12 | 工程卫生 | pubspec 修正 0.25.0+1 → 0.27.0+1 + CHANGELOG 补 v0.26/v0.27 段 | `pubspec.yaml:4` + `docs/CHANGELOG.md:5` | S | P1 | ✗ |
| 13 | 中国合规 | withdraw 同步删 DB (PIPL §14) | `lib/presentation/providers/legal_consent_provider.dart:46-59` | M | P2 | ✓ |
| 14 | 系统化调试 | assessment_comparison `now ?? DateTime.now()` 函数入口一次取 | `lib/domain/logic/assessment_comparison.dart:225` | S | P2 | ✓ |
| 15 | 系统化调试 | scheduleRefillReminder null fireAt 加返回值 + SnackBar | `lib/core/data/services/refill_notifier.dart:111-117` | S | P2 | ✓ |
| 16 | 系统化调试 | `safety_watch_service` errorMessage 修正不暴露 toString | `lib/core/data/services/safety_watch_service.dart:267-271` | S | P2 | ✓ |
| 17 | 系统化调试 | `safety_alert_dispatcher` 串行 SMS 修正为 Future.wait | `lib/core/data/services/safety_alert_dispatcher.dart:64-78` | S | P2 | ✓ |
| 18 | 工程卫生 | 修正 `check_datetime_race2.py` 加 `sys.exit(0/1)` | `scripts/check_datetime_race2.py:74-75` | S | P1 | ✗ |
| 19 | 工程卫生 | CI 补 12 守护脚本 (check_legal_consent / check_sms_release_ready / check_strings_hardcoded / check_orphan_arb_keys / check_no_pua / check_no_hardcoded_utc / check_widget_dispose) | `.github/workflows/ci.yml:50-66` | S | P2 | ✗ |
| 20 | 中国合规 | `sms_service` 加号码归属地路由 (PIPL §38 跨境) | `lib/core/data/services/sms_service.dart:151-154` | M | P1 | ✓ |

---

## 6. 守护脚本跑分总结 (read-only)

| 脚本 | 状态 | 备注 |
|---|---|---|
| `python scripts/check_legal_consent.py` | OK | 但豁免过宽 (BUG-02) |
| `python scripts/check_sms_release_ready.py` | WARN (1 处) | AliyunSms 仍 throw UnimplementedError |
| `python scripts/check_zh_hant_consistency.py` | OK | 551 keys 100% 一致 |
| `python scripts/check_cross_feature.py` | OK | 66 files 0 violations |
| `python scripts/check_widget_dispose.py` | OK (但 Windows PowerShell mojibake) | 0 资源泄漏 |
| `python scripts/check_arb_keys.py` | OK | zh/en/zh_Hant 同步 |
| `python scripts/check_orphan_arb_keys.py` | OK | 0 orphan |
| `python scripts/check_strings_hardcoded.py` | OK (29 处中文) | 28 配对 override 模式 |
| `python scripts/check_datetime_race.py` | OK 输出 "0" | **但不 sys.exit** |
| `python scripts/check_datetime_race2.py` | OK 输出 "0" | **但不 sys.exit** |
| `python scripts/check_changelog.py` | OK | **漏检 pubspec vs commit tag** (4.4) |
| `python scripts/check_no_pua.py` | OK | 0 PUA |
| `python scripts/check_no_hardcoded_utc.py` | OK | 0 硬编 UTC |
| `python scripts/check_drift_namespace.py` | OK | 7 tables 0 duplicates |
| `python scripts/check_fullwidth_punctuation.py` | 47 violations | warn-only (CI 没 fail) |
| `dart scripts/check_all.dart` | ✅ 双 OK | 4 层纯度 + 一致性 |

---

## 7. 审计方法论说明

按 superpowers-zh 6 skill 视角执行：

1. **systematic-debugging (4 步法)** — 20 个 bug 清单全部按"症状→复现→Root cause→证据→影响→修复"格式
2. **chinese-code-review** — 中文审查 5 维度 (命名/注释/错误信息/硬编码/log)
3. **chinese-commit-conventions** — `.commit_msg_*.txt` 5 草稿分析
4. **chinese-git-workflow** — CI workflow 1 份
5. **chinese-documentation** — AGENTS.md / README.md / CHANGELOG.md / todo.md 中文质量
6. **verification-before-completion** — 16 守护脚本盲点识别 (5 个不 sys.exit / 1 个豁免过宽 / 1 个 warn-only)

### 已知风险

- **审计纯 read-only**：未跑 `flutter test` / `flutter analyze` (因 Windows native_assets stale)，所有 bug 来自代码静态分析 + 守护脚本输出 + git log
- **没跑测试**：`mood_recorder.dart` dispose race 修正后**无 regression test** (AGENTS.md 已知)，B5/B6 等可能还有 race 没暴露
- **AI 推断 vs 实测**：BUG-02 (PIPL §13) 推测法务风险，**实际**法务口径需法务 review
- **Bug 数量下限**：找到 20 个，superpowers-zh"应有 10+ 真实 bug"达标；合规 6 项达标；中文规范 5 项达标

---

## 8. 后续修正优先级建议 (P60+ 修正批次)

### 批次 A (1-2 周，P0+P1 修正)
- A1: BUG-01 AliyunSms 真接短期守卫 + BUG-03 SafetyAlert 文案联动
- A2: BUG-02 紧急联系人 consent UI + `check_legal_consent.py` 严格化
- A3: BUG-04 / BUG-05 / BUG-07 / BUG-08 / BUG-09 / BUG-10 修正
- A4: 4.1 pubspec 修正 + CHANGELOG 补 v0.26/v0.27 段
- A5: 4.4 守护脚本修正 (3 个不 sys.exit + 1 个豁免过宽)

### 批次 B (1 月，P2+P3)
- B1: BUG-11 ~ BUG-20 修正
- B2: home_page.dart widget test + mood_recorder dispose race regression test
- B3: TODO `lib/presentation/pages/setup/setup_legal_dialog.dart` 修正 (A-01 SMS 真接前置)
- B4: CI 补 7 个守护脚本

### 批次 C (v1.0 上 store 前)
- C1: 真接阿里云 SMS (法务模板审核 + AccessKey)
- C2: PIPL §13 / §14 / §23 全面合规
- C3: NMPA 医疗器械备案咨询
- C4: NMPA/HIPAA/GDPR/PIPL 跨司法管辖

---

**审计报告完成** | 报告文件：`D:\Batch\chroniccare\reports\audit-superpowers-zh-deep.md`
**关键发现**：20 bug (3 P0 + 8 P1 + 7 P2 + 2 P3) + 6 PIPL 合规 + 5 中文规范 + 5 守护脚本盲点
**下一步建议**：修正批次 A (P0+P1 修正)，4 周内完成
