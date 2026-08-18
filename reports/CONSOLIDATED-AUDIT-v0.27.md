# Consolidated Audit Report — chroniccare v0.27

> **整合 7 份报告的优先级清单**（按"先架构后底层 + P0→P3"排序）
>
> **日期**：2026-07-30
> **范围**：emil 视角（UI 动效）+ superpowers-zh 视角（系统化调试 / 中文 / 中国合规）+ 4 份历史分层报告（data / domain / presentation / tooling，2026-07-27）+ 7/20 三视角 v2
> **状态标注**：✅ 已修（v0.27 内已有修复 / 历史已修）/ ⏳ 未修 / 🔶 部分修 / 🆕 本轮新发现
> **修复难度**：S（< 1h）/ M（1-4h）/ L（1-3 day）
> **优先级**：P0（数据 / 安全 / 崩溃 / 谎言）/ P1（功能错误 / 体验差）/ P2（边界 case / 工程卫生）/ P3（nit / 风格）

---

## 0. 一页总览

| 视角 | 评分 | 关键产出 | 主要问题数 |
|---|---|---|---|
| **emil**（7/30） | 39/40 优秀 | 动效 token 体系完整 / prefers-reduced-motion 双层 / Interruptibility+Restraint 满分 | 1 P2 + 3 P3 |
| **superpowers-en**（7/30 轻量补充） | 36/40 优秀 | 顶层架构 / 4 层纯度 / TDD / provider 树 / 路由（**0 新 P0/P1**，全修正过） | 修正记录完整 + 0 新 bug |
| **superpowers-zh**（7/30） | 18/40 一般 | 20 bug + 6 PIPL + 5 中文 + 5 脚本盲点 | **3 P0 + 8 P1 + 7 P2 + 2 P3** |
| **data-layer**（7/27） | 33/40 良好 | 4 层 + 共享 umbrella 健康 | 0 P0 / 4 P1 / 31 P2-P3 |
| **domain-layer**（7/27） | 30/40 一般 | 4 层纯度 OK，但 crisis detection 0 单测 | **2 P0 / 4 P1 / 38 P2-P3** |
| **presentation-layer**（7/27） | 36/40 良好 | AppTokens / AppListTile / PressFeedback 集中 | 4 P1 / 多 P2-P3 |
| **tooling-tests**（7/27） | 31/40 一般 | 12 + 1 守护脚本在跑，但有 stale artifact | 5 P1 / 多 P2-P3 |

**修正优先级**：
- **批次 A**（1-2 周，**修正**所有 P0 + 半数 P1）：6 个 P0（3 zh + 2 domain + 1 衍生）+ 8 个 P1
- **批次 B**（1 月，**修正**剩余 P1 + P2）：剩余 P1 + 30+ P2
- **批次 C**（v1.0 上 store 前，**修正**PIPL §13 §14 + 繁简 + 守护脚本盲点）：合规收口

---

# 📐 第一部分：顶层架构审视（先看这一部分）

> **核心问题**：架构 / 模块边界 / 状态管理 / 路由 / 数据流 / 跨层依赖

## 1.1 🔴 P0 架构级 — SMS 服务的 mock/production 状态未分离

**视角**：superpowers-zh（新发现 P0-1）
**文件**：`lib/core/data/services/sms_service.dart:156-160`
**现状**：`AliyunSmsProvider.send()` 永远 `throw UnimplementedError`，但 `isProductionReady=true` 通过 `validateForRelease` 守卫；release 模式 UI 显示"已自动通知紧急联系人"是**谎话**。
**架构根因**：`SmsService` 没把"是否已接阿里云"作为 first-class 状态分离。`_provider.isProductionReady` 是 mock 后门，release 模式下 `validateForRelease` 没真验证实现。
**修复难度**：L（1-3 day）
**修复方案**：
- 抽 `SmsGateway` abstract interface，`AliyunSmsGateway` (real) / `MockSmsGateway` (dev) / `NoopSmsGateway` (release 模式前)
- `SmsService` 拿 `SmsGateway`（构造注入）
- `validateForRelease` 必须 `AliyunSmsGateway is configured` 才返 true
- 通知文案 / UI 反馈必须查 `gateway.kind` 走分支
**修正建议**：批次 A 第 1 周

## 1.2 🔴 P0 架构级 — PIPL §13 单独同意流程未设计

**视角**：superpowers-zh（新发现 P0-2）
**文件**：`lib/presentation/pages/contact/contacts_list_widget.dart:200-207`（加联系人 0 consent）
**现状**：添加紧急联系人无任何 consent 流程，SMS 通知家人的动作**没有**"数据接收方同意"机制。`check_legal_consent.py:41` 的 `EXEMPT_LINE_RE` 触发 `✅` 把这条豁免了，是脚本盲点。
**架构根因**：consent 是跨 4 个 feature 的横切关注点（contact / setup / safety / privacy），但只在 `UserProfile` 层有抽象，无独立 consent 状态机。
**修复难度**：L（1-3 day）
**修复方案**：
- 新建 `lib/domain/entities/consent_artifact.dart`：`{kind: emergencyContactSharing, grantedAt, grantedBy, contactId, version}`
- `ContactRepository.add()` 强制要求 `consentArtifact`
- `check_legal_consent.py:41` 的 `EXEMPT_LINE_RE` 去掉（脚本修正）
- UI 走 `ConsentDialog`（共享 component）
**修正建议**：批次 A 第 1 周

## 1.3 🔴 P0 架构级 — SafetyAlert 通知文案跟实际 SMS 状态解耦

**视角**：superpowers-zh（新发现 P0-3）
**文件**：`lib/core/data/services/notification_service.dart:361-363`
**现状**：通知文案 hardcode "已自动通知紧急联系人"，但实际 SMS 走 mock / fail 状态。精神心理患者看到通知以为有人知道。
**架构根因**：通知层没拿 SMS 真实结果，跟 `SafetyAlertDispatcher.dispatchAlert` 的 `(smsOk, smsFail, smsMock)` 三态没连。
**修复难度**：M（1-4h，跟 1.1 一起修正）
**修复方案**：
- 通知层入参加 `actualSmsState`（`sent` / `mocked` / `failed`）
- 三态文案分流：
  - `sent`: "已自动通知紧急联系人 X"
  - `mocked`: "失联检测已触发，但当前为开发模式，**未实际**通知联系人"
  - `failed`: "失联检测已触发，但通知发送失败。请检查网络。"
**修正建议**：批次 A 第 1 周（跟 1.1 一起）

## 1.4 🔴 P0 架构级 — Crisis detection 0 单测

**视角**：domain-layer（2026-07-27 发现，未修）
**文件**：`lib/domain/logic/care_strategies.dart` / `crisis_detection.dart`（推断）
**现状**：crisis detection 逻辑 0 单元测试覆盖。最严重的 P0 漏测 — 精神心理患者安全防线。
**架构根因**：domain 逻辑用 mock test 替代了真单测，AGENTS.md "domain 0 flutter" 的隔离没保护住测试。
**修复难度**：M（1-4h）
**修复方案**：
- 抽 `lib/domain/logic/crisis_detection.dart` 的纯函数（不依赖 DB）
- 写 30+ case 单测：边界 / 模糊输入 / 漏触 / 误触
- 把 mock 替换成真单测
**修正建议**：批次 A 第 1 周

## 1.5 🟠 P1 架构级 — 失联通知两条并行路径，措辞不一致

**视角**：superpowers-zh（新发现 P1-5）+ data-layer（finding 1.3 重复）
**文件**：
- `lib/core/data/services/reminder_scheduler.dart:211-232` `_buildSmsBody`
- `lib/core/data/services/safety_alert_dispatcher.dart:37-44` `buildAlertSms`
**现状**：`ReminderService` 走"已 N 小时没打卡"路径，`SafetyAlertDispatcher` 走"如确认安全请回复 1"路径。两个文案生成器 50% 重复，用户实际看到哪条取决于 trigger 逻辑。
**架构根因**：SMS 文案应该走 `domain/logic/sms_template.dart` 单一 source of truth。
**修复难度**：M（1-4h）
**修复方案**：
- 抽 `lib/domain/logic/lost_contact_sms.dart`：`buildLostContactSms({duration, kind, contactName, userName})`
- 两个 service 都调它
- 修正 data-layer 1.3 的 dead code（重复实现）
**修正建议**：批次 A 第 2 周

## 1.6 🟠 P1 架构级 — 3 个死 re-export 文件

**视角**：presentation-layer（2026-07-27 finding 1.1）
**文件**：
- `lib/presentation/pages/check_in/check_in_button.dart`（3 行 re-export）
- `lib/presentation/pages/medication/last_med_info.dart`（3 行 re-export）
- `lib/presentation/pages/mood/mood_quick_button.dart`（3 行 re-export）
**现状**：re-export 真实 widget 已搬到 `lib/presentation/widgets/`。0 caller，0 业务价值。
**修复难度**：S（< 1h）
**修复方案**：直接删 3 个文件。`docs/CHANGELOG.md` 记一笔。
**修正建议**：批次 B（顺手做）

## 1.7 🟠 P1 架构级 — version 漂移（pubspec vs git HEAD vs CHANGELOG）

**视角**：superpowers-zh（新发现工程卫生）
**文件**：`pubspec.yaml` (0.25.0+1) vs git HEAD (v0.27 round 60) vs `docs/CHANGELOG.md`
**现状**：pubspec 版本号落后 2 个 round，10+ commit 不在 CHANGELOG。
**修复难度**：S（< 1h）
**修复方案**：
- `pubspec.yaml` 升 `0.27.0+60`（或当前最新 round）
- CHANGELOG 修正（参考 `git log --oneline` 整理）
- 修正后跑 `flutter pub get`
**修正建议**：批次 B

## 1.8 🟠 P1 架构级 — 守护脚本盲点：3 个不 sys.exit

**视角**：superpowers-zh（新发现工程卫生）
**文件**：
- `scripts/check_datetime_race.py`
- `scripts/check_datetime_race2.py`
- `scripts/check_*.py` (可能还有)
**现状**：3+ 守护脚本不 `sys.exit(1)`，CI 永远绿。
**架构根因**：守护脚本只看 stdout 输出，没人 enforce exit code。
**修复难度**：S（< 1h）
**修复方案**：所有 `check_*.py` 末尾加：
```python
if violations:
    print(f"[FAIL] {len(violations)} violations found")
    sys.exit(1)
```
修正后 CI 真能 fail。
**修正建议**：批次 B

## 1.9 🟠 P1 架构级 — CI 漏跑 7 个守护脚本

**视角**：superpowers-zh（新发现工程卫生）
**文件**：`.github/workflows/*.yml`（推断）
**现状**：`check_legal_consent.py` / `check_no_pua.py` / `check_no_hardcoded_utc.py` / `check_orphan_arb_keys.py` / `check_zh_hant_consistency.py` / `check_strings_hardcoded.py` / `check_widget_dispose.py` 没在 CI 跑。
**修复难度**：S（< 1h）
**修复方案**：CI 一次性加 7 行：
```yaml
- run: python scripts/check_legal_consent.py
- run: python scripts/check_no_pua.py
...
```
**修正建议**：批次 B

## 1.10 🟠 P1 架构级 — `check_sms_release_ready.py` 降为 warn-only

**视角**：superpowers-zh（新发现工程卫生）
**文件**：`scripts/check_sms_release_ready.py`
**现状**：v0.27 R58 修正时降为 warn-only，release 不会 fail。但这条**正是**修正 P0-1（SMS 撒谎）的最后一道防线。
**修复难度**：S（< 1h，跟 1.1 一起修正）
**修复方案**：修正 P0-1 完成后，恢复 `sys.exit(1)`。但**修正 P0-1 之前**不能恢复（CI 会红成一片）。
**修正建议**：批次 A 第 1 周（跟 1.1 一起）

## 1.11 🟡 P2 架构级 — `EmailService` 死代码（连带 mailer 依赖）

**视角**：data-layer（2026-07-27 finding 1.1）
**文件**：`lib/core/data/services/email_service.dart` + `email_service_round9_test.dart` + `emailServiceProvider`
**现状**：v0.6 → v0.7 改 mock SMS 后，EmailService 仅 test 用。
**修复难度**：S（< 1h）
**修复方案**：删 + 修正 `pubspec.yaml` 移除 `mailer` 依赖。
**修正建议**：批次 B

## 1.12 🟡 P2 架构级 — `ChineseHolidays` 整个 class 死代码

**视角**：domain-layer（2026-07-27 finding 1.1）
**文件**：`lib/domain/logic/chinese_holidays.dart:21-135`
**现状**：v0.24 建 data layer + TDD，v0.25+ 没集成。60 行硬编码假期表（2026-2030）占 domain 层。
**修复难度**：S（< 1h）
**修复方案**：删 + 删测试。
**修正建议**：批次 B

## 1.13 🟡 P2 架构级 — `domain/logic/reminder_scheduler.dart` 3/4 static method 死代码

**视角**：domain-layer（2026-07-27 finding 1.2）
**文件**：`lib/domain/logic/reminder_scheduler.dart:20-38, 44-57`
**现状**：4 个 static method 只有 `selectAllActiveContacts` 是真生产路径，其他 3 个（`shouldSendAlert` / `hoursSinceLastCheckIn` / `selectFirstContact`）仅 test 用。
**修复难度**：S（< 1h）
**修复方案**：删 3 个方法 + 3 个 test group。
**修正建议**：批次 B

## 1.14 🟡 P2 架构级 — `ContactRepository.update` 抽象方法 0 生产 caller

**视角**：domain-layer（2026-07-27 finding 1.3）
**文件**：`lib/domain/repositories/contact_repository.dart:21`
**现状**：0 caller，UI 暂未调用。"更新保留以备 API 稳定" 是 dead API surface。
**修复难度**：S（< 1h）
**修复方案**：删抽象 + impl + 1 处 mock。
**修正建议**：批次 B

## 1.15 🟡 P2 架构级 — `MedicationRepository.setActive` 抽象方法 0 生产 caller

**视角**：domain-layer（2026-07-27 finding 1.4）
**文件**：`lib/domain/repositories/medication_repository.dart:35-38`
**现状**：软停药功能未实施，UI 用 `delete`（硬删）。
**修复难度**：S（< 1h）
**修复方案**：删抽象 + impl + 测试。
**修正建议**：批次 B

## 1.16 🟡 P2 架构级 — `UserProfileRepository.save/withdrawConsent/resetConsent` 0 生产 caller

**视角**：domain-layer（2026-07-27 finding 1.5）
**现状**：3 个方法死代码，跟 P0-2（PIPL §13）关联。**实施 PIPL §14 撤回 UI 时再加**。
**修复难度**：S（< 1h）
**修复方案**：先删，撤回 UI 实施时再加。
**修正建议**：批次 A 第 2 周（修正 P0-2 时一起加）

## 1.17 🟡 P2 架构级 — 9 个 one-off `_rXX_/_tmp_/_clean_*.py` 待 archive

**视角**：tooling-tests（2026-07-27 finding 1.1）
**文件**：`scripts/_r49_*.py` / `_r53a_*.py` / `_r56_*.py` / `_r56b_*.py` / `_r59_*.py` / `_clean_orphan_arb_keys.py`
**现状**：历史一轮修正脚本，已完成工作但留在 `scripts/` 根目录。
**修复难度**：S（< 30 min）
**修复方案**：
```bash
mv scripts/_r49_*.py scripts/_archive/r49/
mv scripts/_r53a_*.py scripts/_archive/r53a/
mv scripts/_r56*.py scripts/_archive/r56/
mv scripts/_r59_*.py scripts/_archive/r59/
mv scripts/_clean_orphan_arb_keys.py scripts/_archive/r56e/
```
**修正建议**：批次 B（顺手做）

## 1.18 🟡 P2 架构级 — 41 个 stale artifact 待清理

**视角**：tooling-tests（2026-07-27 finding 1.2 + 1.3）
**文件**：17 个 `scripts/.txt/.log/_test_*.log` + 24 个 `reports/.ps1/.png/.log`
**现状**：调试时产生的 .txt / .log / .ps1 / .png 临时文件，不应 commit。
**修复难度**：S（< 1h）
**修复方案**：
- 修正 `.gitignore` 加 `_archive/` / `.mimocode/` / `.commit_msg_*.txt` / `*.log` / `*.tmp` / `*.ps1` (in reports) / `_thumb_*.png`
- 删现有 41 个 stale artifact
**修正建议**：批次 B

## 1.19 🟡 P2 架构级 — AGENTS.md schemaVersion 12 → 14 漂移

**视角**：tooling-tests（2026-07-27 finding 0.2）
**文件**：`AGENTS.md` line 2
**现状**：代码 schemaVersion = 14，AGENTS.md 还写 12。
**修复难度**：S（1 line）
**修复建议**：批次 B（顺手做）

## 1.20 🟢 P3 架构级 — `CheckInEntity.isForMedication / isPhq9 / isGad7 / CheckInTypeX.label` 死代码

**视角**：domain-layer（2026-07-27 finding 1.6-1.8）
**文件**：`lib/domain/entities/check_in_entity.dart:48-62, 97-106`
**现状**：4 处死代码，其中 `CheckInTypeX.label` extension 走硬编码中文（违反 domain 0 i18n）。
**修复难度**：S
**修复方案**：删 + 修正 import 顺序。
**修正建议**：批次 B

## 1.21 🟢 P3 架构级 — `safety_watch_service.dart:36` `defaultThresholdDays` 死常量

**视角**：data-layer（2026-07-27 finding 1.4）
**文件**：`lib/core/data/services/safety_watch_service.dart:36`
**现状**：0 caller（grep 验证），`safety_config_service.dart:26` 也有同款。
**修复难度**：S
**修复方案**：删 1 行。
**修正建议**：批次 C（顺手）

## 1.22 🟢 P3 架构级 — `data_export_service.dart:46-51` "兼容旧 import 路径" re-export 多余

**视角**：data-layer（2026-07-27 finding 1.8）
**文件**：`lib/core/data/services/data_export_service.dart:46-51`
**现状**：re-export `ImportResult` 让老 import 写法编译通过，但 `lib/` 0 处用老写法。
**修复难度**：S
**修复方案**：删 2 行 + 简化注释。
**修正建议**：批次 C（顺手）

## 1.23 🟢 P3 架构级 — `app_database.dart:186-188` 注释描述的 fix 跟实际代码不对应

**视角**：data-layer（2026-07-27 finding 1.7）
**现状**：注释说"v0.22 round 31 sp-en P0-3 抽 helper"但代码不调。
**修复难度**：S
**修复方案**：简化注释。
**修正建议**：批次 C（顺手）

## 1.24 🟢 P3 架构级 — `reminder_dispatcher.dart:30` 注释"5s timeout"对不上实际 2s

**视角**：data-layer（2026-07-27 finding 1.9）
**修复难度**：S
**修复建议**：批次 C（顺手）

## 1.25 🟢 P3 架构级 — 5+ mojibake-rendered .md 文件（PUA 字符腐蚀）

**视角**：tooling-tests（2026-07-27 finding 0.4）
**现状**：v0.17 PowerShell 事故造成的 PUA 字符腐蚀遗留。
**修复难度**：M（需逐文件修正）
**修复方案**：用 `check_no_pua.py` 扫，remojibake 修正。
**修正建议**：批次 C

---

# 🔬 第二部分：底层逐行排查（看完架构再看这一部分）

> **核心问题**：Bug / 隐患 / 系统化调试发现的 root cause / 中文规范 / 工程卫生

## 2.1 🟠 P1 底层 bug — `safety_watch_service.displayMessage` 7 case hardcode 中文穿透 en 模式

**视角**：superpowers-zh（新发现 P1-4）
**文件**：`lib/core/data/services/safety_watch_service.dart:323-343`
**现状**：7 case switch 全部 hardcode 中文，en 模式用户看到中文。**国际化穿透**
**修复难度**：S（< 1h）
**修复方案**：改成 `switch` 返 i18n key，文案走 `AppLocalizations` + `core/l10n/strings.dart`。
**修正建议**：批次 A 第 2 周

## 2.2 🟠 P1 底层 bug — `home_page.dart:407-412` `Future.delayed(1800ms)` 不可 cancel

**视角**：superpowers-zh（新发现 P1-6）
**现状**：`Future.delayed` 没存 `Timer`，widget 销毁后 fire 引起 race。
**修复难度**：S
**修复方案**：改 `Timer(1800ms, callback)` + `dispose` 时 `timer.cancel()`。
**修正建议**：批次 A 第 2 周

## 2.3 🟠 P1 底层 bug — `setup_page.dart:431` `action: '完成设置'` v0.27 R59 修正时埋的 hardcode 中文

**视角**：superpowers-zh（新发现 P1-7）
**现状**：修正历史 PR 时埋下的 hardcode 字符串。
**修复难度**：S
**修复方案**：改成 l10n key。
**修正建议**：批次 A 第 2 周

## 2.4 🟠 P1 底层 bug — `user_name_helper.dart:20` fallback `'您'` hardcode 中文

**视角**：superpowers-zh（新发现 P1-8）
**现状**：5+ caller 穿透 en 模式。
**修复难度**：S
**修复方案**：fallback 走 i18n（"您" / "You"）。
**修正建议**：批次 A 第 2 周

## 2.5 🟠 P1 底层 bug — `home_page.dart:87` magic 100ms 修正

**视角**：superpowers-zh（新发现 P1-9）
**现状**：AGENTS.md "已知坑"遗留（deep link race 防御）。
**修复难度**：S
**修复方案**：抽 `kDeepLinkRaceGuard = Duration(milliseconds: 100)` 常量。
**修正建议**：批次 A 第 2 周

## 2.6 🟠 P1 底层 bug — `contacts_list_widget.dart:202-203` 默认名 `'Contact'` hardcode 英文

**视角**：superpowers-zh（新发现 P1-10）
**现状**：跟 2.4 同款 hardcode 问题。
**修复难度**：S
**修复方案**：i18n。
**修正建议**：批次 A 第 2 周

## 2.7 🟠 P1 底层 bug — `safety_watch_service.onCheckIn` race + UI snackbar 误报

**视角**：data-layer（2026-07-27 finding 3.1 + 3.2）
**文件**：`lib/core/data/services/safety_watch_service.dart:133-143` + `home_page.dart:313-322`
**现状**：刚打卡就调 `onCheckIn()`，若 race 返回旧 timestamp，会触发 alert + 弹"已通知"snackbar 误报。
**修复难度**：S
**修复方案**：`onCheckIn()` 入口先 `getLatestNormalCheckIn()`，timestamp 距 now < 60s 返 `ok` 跳过 alert。
**修正建议**：批次 B

## 2.8 🟠 P1 底层 bug — `ReminderService` 和 `SafetyWatchService` 重复告警

**视角**：data-layer（2026-07-27 finding 3.3）
**文件**：`lib/core/data/services/reminder_scheduler.dart:155-166`
**现状**：两个 service 互不知道对方存在，`setLastAlertAt` 各记各的，会**重复告警**。
**修复难度**：M（修正前需确认 `reminderServiceProvider` 是否真被 production 调 — 可能是死代码一起删）
**修复方案**：修正 data-layer 1.3（dead code）+ 修正 1.5（共用 `lost_contact_sms.dart`）
**修正建议**：批次 A 第 2 周（跟 1.5 一起）

## 2.9 🟠 P1 底层 bug — `mood_audio_service.stopRecording` plainPath==null 不释放资源

**视角**：data-layer（2026-07-27 finding 3.4）
**文件**：`lib/core/data/services/mood_audio_service.dart:276-289`
**现状**：recorder stop 失败时 plainPath==null 直接 return，recorder 未 dispose（实际无泄漏因下次 startRecording 重建）。
**修复难度**：S
**修复方案**：加注释说明 + try/finally 显式 cleanup。
**修正建议**：批次 B

## 2.10 🟠 P1 底层 — Hero tag 风险

**视角**：presentation-layer（2026-07-27 finding #3）
**文件**：`lib/presentation/pages/vent/vent_list_page.dart:224` + `vent_detail_page.dart:210`
**现状**：Hero animation tags scoped per entry，entry id 删了再恢复会撞。
**修复难度**：S
**修复方案**：Hero tag 用 `vent-entry-${entryId}`，加 uniqueness check。
**修正建议**：批次 B

## 2.11 🟠 P1 底层 — `medication_calendar_page.dart:277` `const _labelWidth = 60` 不在 AppTokens

**视角**：presentation-layer（2026-07-27 finding #4）
**修复难度**：S
**修复方案**：修正 AppTokens 加 `calendarLabelWidth`。
**修正建议**：批次 B

## 2.12 🟠 P1 底层 — 多个 magic WidgetStateProperty / Color / Radius / SizedBox

**视角**：presentation-layer（2026-07-27 finding #5）
**文件**：`assessment_page.dart:260` `left: 26` 等
**修复难度**：M（需要全量扫）
**修复方案**：修正 AppTokens 集中。
**修正建议**：批次 B（emil 视角下 `app_tokens.dart:353-751` 已集中 80%，剩余 20% 待修正）

## 2.13 🟡 P2 底层 — `mood_audio_service.dart:213, 248` DateTime.now() 跨鸿沟

**视角**：data-layer（2026-07-27 finding 2.4）
**现状**：timer 启动存 start，每 100ms tick 算 elapsed。23:59:59.9 开始录音第一个 tick 跨 00:00:00 → elapsed 偏大 0.1s。
**修复难度**：S
**修复方案**：不修正（影响 < 1 秒），或修正（`final start = DateTime.now();` 入口一次）。
**修正建议**：批次 C（不修也行）

## 2.14 🟡 P2 底层 — `_StreakCounter` 数字递增没显式 setCurve（走 default linear）

**视角**：emil（新发现 P3-4）
**文件**：`presentation/widgets/` 内 _StreakCounter（推断）
**现状**：注释建议 `curveDecelerate` 但代码没修正。
**修复难度**：S
**修复方案**：`AnimatedBuilder` 加 `curve: Motion.curveDecelerate`。
**修正建议**：批次 C

## 2.15 🟡 P2 底层 — `page_transition_switcher.dart:34` `const Duration(milliseconds: 100)` 裸值

**视角**：emil（新发现 P3-3）
**文件**：`lib/presentation/widgets/page_transition_switcher.dart:34`
**现状**：同文件 `app_tokens.dart:373` 已有 `durPageTransition` token，但这里用了裸值。
**修复难度**：S（1 line）
**修复方案**：替换为 `durPageTransition`。
**修正建议**：批次 B（顺手做）

## 2.16 🟡 P2 底层 — `trend_page.dart:121-194` 4 段图表无 stagger 错峰

**视角**：emil（新发现 P2-1）
**文件**：`lib/presentation/pages/trend/trend_page.dart:121-194`
**现状**：4 段图表同时入场，无错峰。
**修复难度**：S
**修复方案**：加 FadeIn 0/40/80/120ms stagger。
**修正建议**：批次 B

## 2.17 🟡 P2 底层 — `MoodAudioService.dispose()` 顺序 race 风险

**视角**：data-layer（2026-07-27 finding 2.6）
**文件**：`lib/core/data/services/mood_audio_service.dart:349-366`
**现状**：`_sttController.close()` 在 `_stopSttInternal()` 之后。
**修复难度**：S
**修复方案**：改顺序。
**修复建议**：批次 C

## 2.18 🟡 P2 底层 — `randomInt(10000)` 仅 4 位（撞概率 0.01%）

**视角**：data-layer（2026-07-27 finding 2.7）
**文件**：`lib/core/data/privacy/encrypted_audio_storage.dart:117, 128, 209`
**现状**：同毫秒 10000+ 录音会撞文件名。
**修复难度**：S
**修复方案**：不改（概率低且文件本身已加密）。或改 6 位。
**修复建议**：批次 C（不修正）

## 2.19 🟡 P2 底层 — `_setLastAlertAt` 写 ISO 字符串无 length check

**视角**：data-layer（2026-07-27 finding 2.9）
**现状**：`DateTime.toIso8601String()` 24-30 字节，无 length check。
**修复难度**：S
**修复建议**：不修正（0 风险）。

## 2.20 🟡 P2 底层 — `LastErrorCapture._parse` 假设 3 行结构

**视角**：data-layer（2026-07-27 finding 2.10）
**现状**：鲁棒性一般。
**修复难度**：S
**修复建议**：不修正（已 0 风险）。

## 2.21 🟡 P2 底层 — 9 个 presentation page > 500 lines 待重构

**视角**：presentation-layer（2026-07-27 finding #8）
**文件**：`home/assessment_page/medication_calendar/trend_calendar` 已部分重构，`mood_recorder` 564 lines 待修
**修复难度**：L
**修复建议**：批次 C

## 2.22 🟡 P2 底层 — 3 dialog 多次打开风险（无 de-bounce）

**视角**：presentation-layer（2026-07-27 finding #7）
**修复难度**：M
**修复建议**：批次 C

## 2.23 🟡 P2 底层 — 10 个 TODO 注释（v1.0+ future work）

**视角**：tooling-tests（2026-07-27 finding 0.6）
**现状**：10 个 TODO 注释，非 blocker。
**修复建议**：批次 C（v1.0+）

## 2.24 🟢 P3 底层 — `home_page.dart:87` deep link race 100ms 缺注释

**视角**：emil（新发现 P3-4）
**修复难度**：S
**修复建议**：加注释。

## 2.25 🟢 P3 底层 — `email_service.dart:67, 73` mock vs SmsService 风格不一致

**视角**：data-layer（2026-07-27 finding 2.11）
**现状**：死代码（finding 1.1），删了就没这问题。
**修复建议**：跟 1.11 一起修正。

## 2.26 🟢 P3 底层 — `safety_alert_dispatcher.dart:80-86` `showSafetyAlert` 失败不 catch

**视角**：data-layer（2026-07-27 finding 2.12）
**现状**：已有 outer try/catch，0 风险。
**修复建议**：不修正。

## 2.27 🟢 P3 底层 — `database_migration.dart:62` `existsSync()` race window

**视角**：data-layer（2026-07-27 finding 3.5）
**现状**：单 app 进程 0 race。
**修复建议**：不修正。

## 2.28 🟢 P3 底层 — `sms_service.dart:251` `_provider.isProductionReady` 二次调用

**视角**：data-layer（2026-07-27 finding 3.6）
**现状**：getter 零成本。
**修复建议**：不修正。

## 2.29 🟢 P3 底层 — `app_database.saveSetup` 8 字段 `existing?.xxx ?? now`

**视角**：data-layer（2026-07-27 finding 3.7）
**现状**：v0.21 P1-2 修正过。
**修复建议**：不修正（正面观察）。

## 2.30 🟢 P3 底层 — `safety_watch_service.dart:200-205` `try` 块内 `effectiveNow` 复用（正面观察）

**视角**：data-layer（2026-07-27 finding 2.5）
**现状**：AGENTS.md "v0.16 round 19B 已立的规矩" 正确实施范例。
**修复建议**：不修正（保持）。

## 2.31 🟢 P3 底层 — `Random()` non-secure random 用于文件名（安全 OK）

**视角**：data-layer（2026-07-27 finding 2.8）
**现状**：文件本身已 AES-256 加密，文件名随机性不影响机密性。
**修复建议**：不修正。

---

# 🇨🇳 第三部分：中国合规 + 隐私专项

> **PIPL（个人信息保护法）+ NMPA + 精神心理患者保护**

## 3.1 🔴 P0 — PIPL §13 单独同意（见 1.2）

## 3.2 🔴 P0 — PIPL §14 撤回同意（关联 1.16）

**现状**：撤回 UI 未实施。
**修正建议**：批次 A（跟 1.16 一起实施 UI）

## 3.3 🟠 P1 — 紧急联系人 SMS 文案（措辞分寸）

**视角**：superpowers-zh + 已有 AGENTS.md
**现状**：措辞"请你方便的时候提醒我按时吃药"（不是"快不行了"）— 精神心理患者保护的**非协商底线**。
**修正建议**：已合规（保持），未来加 1 条 case test 锁住。

## 3.4 🟠 P1 — NMPA 精神心理类 App 备案

**修正建议**：批次 C（上 store 前）

## 3.5 🟠 P1 — 数据导出 (PIPL §13 用户数据可携权)

**现状**：`data_export_service` 已存在，v0.24 R48 完成。`check_legal_consent.py` 已加导出同意检查。
**修正建议**：保持。

## 3.6 🟡 P2 — 繁简一致性 (zh_Hant)

**视角**：superpowers-zh（已加 `check_zh_hant_consistency.py` 守门员）
**修正建议**：跑守门员，确认全过。

## 3.7 🟡 P2 — `data_export` 漏 query 5s timeout

**视角**：data-layer（2026-07-27 finding 2.3）
**文件**：`lib/core/data/services/export/export_orchestrator.dart:97-119`
**现状**：`getAllReportHistories()` + `getAllMoodEntries()` 3 个 Future query 无 timeout 保护。
**修复难度**：S
**修正建议**：批次 A 第 2 周（跟 1.5 / 1.16 一起）

---

# 📚 第四部分：历史修正 sprint 状态

| 修正 sprint | 日期 | 修正范围 | 当前状态 |
|---|---|---|---|
| Sprint #2 zh-Hant v24 | 7/26 | 繁简一致 | ⏳ 部分修正（看 3.6） |
| Sprint #5 mood dialog v24 | 7/26 | 情绪 dialog | ✅ 已修正（emil 评分 39/40） |
| Sprint #5b notification service v24 | 7/26 | 通知服务 | ⏳ 部分修正（见 1.3 / 2.1） |
| Sprint #5c data export v24 | 7/26 | 数据导出 | ✅ 已修正（v0.24 R48） |
| Sprint #5d medications list v24 | 7/26 | 用药列表 | ⏳ 部分修正（见 1.15） |

---

# 🎯 第五部分：修正批次计划（高内聚低耦合）

> **修正原则**：
> - **高内聚**：每个 batch 修正一组相关问题（如"修正 P0-1 SMS 撒谎" 同时修正 1.2 / 1.3 / 1.5 / 1.10 / 2.7 / 2.8 / 3.5）
> - **低耦合**：修正前先确认依赖（如修正 P0-1 时不要动 emotion 评估，避免牵连）
> - **TDD 优先**：修正 P0/P1 之前先写 failing test 锁住当前行为

## 批次 A（1-2 周，必须修正）

| 修正周 | Item | 关联 | 修正内容 |
|---|---|---|---|
| A1 (1-3 天) | 1.1 | 1.3, 1.10, 2.7, 2.8 | **抽 `SmsGateway` abstract interface** + `validateForRelease` 真验证 + 通知文案三态分流。修正后 `check_sms_release_ready.py` 恢复 `sys.exit(1)` |
| A1 (1-3 天) | 1.2 | 1.16, 3.2 | **`ConsentArtifact` 实体 + `ContactRepository.add()` 强制 consent + `ConsentDialog` 共享 component** + 修正 `check_legal_consent.py:41` 豁免 |
| A1 (1-3 天) | 1.4 | - | **crisis detection 真单测 30+ case**（替换 mock test） |
| A1 (1-3 天) | 1.3 | 跟 1.1 一起 | 见 1.1 |
| A2 (4-7 天) | 1.5, 1.16, 2.8, 3.7 | 修正 1.3 dead code | **抽 `domain/logic/lost_contact_sms.dart` + 修正 `UserProfileRepository` 撤回 UI** + 修正 data export 5s timeout |
| A2 (4-7 天) | 2.1, 2.3, 2.4, 2.5, 2.6 | 修正 4 处 hardcode | **i18n 修正**：safety_watch displayMessage / setup_page / user_name_helper / contacts_list_widget |
| A2 (4-7 天) | 2.2 | - | **`Timer(1800ms)` + dispose cancel** |

## 批次 B（1 月，顺手修正）

| Item | 修正内容 |
|---|---|
| 1.6 | 删 3 个 dead re-export |
| 1.7 | 升 pubspec + CHANGELOG 修正 |
| 1.8 | 修正 3 个守护脚本 `sys.exit(1)` |
| 1.9 | CI 加 7 个守护脚本 |
| 1.11 | 删 EmailService + mailer 依赖 |
| 1.12 | 删 ChineseHolidays |
| 1.13 | 删 `domain/logic/reminder_scheduler.dart` 3 个死方法 |
| 1.14 | 删 ContactRepository.update |
| 1.15 | 删 MedicationRepository.setActive |
| 1.17 | 9 个 one-off script 移到 `_archive/` |
| 1.18 | 修正 .gitignore + 删 41 个 stale artifact |
| 1.19 | 修正 AGENTS.md schemaVersion 12→14 |
| 1.20 | 删 `CheckInEntity` 4 处死代码 |
| 2.7, 2.8, 2.9, 2.10, 2.11, 2.12, 2.15, 2.16 | 各修正 |

## 批次 C（v1.0 上 store 前）

| Item | 修正内容 |
|---|---|
| 1.21, 1.22, 1.23, 1.24 | 顺手修正 |
| 1.25 | remojibake 修正（5+ .md） |
| 2.13, 2.17, 2.18-2.22, 2.24-2.31 | nit / 顺手 |
| 3.4 | NMPA 备案 |
| 3.6 | zh_Hant 守门员跑全过 |

---

# 📌 第六部分：附录 — 修正优先级矩阵

```
P0 修正 ─── 修正 ─── 修正 ─── 修正 ─── 修正 ─── 修正
       A1-1.1  A1-1.2  A1-1.4  A1-1.3
       SMS     PIPL    Crisis  Safety
       撒谎    同意    单测    通知

P1 修正 ─── 修正 ─── 修正 ─── 修正 ─── 修正
       A2-1.5  A2-1.16 A2-2.1  A2-2.2  ...
       SMS     撤回    i18n    Timer
       措辞    UI      修正    cancel

P2 修正 ─── 修正 ─── 修正 ─── 修正
       B-1.6   B-1.11  B-1.12  ...
       re-     Email-  Chinese
       export  Service Holidays
```

---

## 状态标注说明

- ✅ **已修**：v0.27 修正历史 PR 中已修正（如 emil 39/40 评分 + 6 个 animation widget 加 reduced-motion）
- ⏳ **未修**：本轮新发现或历史发现仍未修正
- 🔶 **部分修**：修正过部分场景但还有边界 case（如 `safety_watch_service` 部分场景已修正 `effectiveNow` 但 2.1 displayMessage 未修正）
- 🆕 **本轮新发现**：2026-07-30 三视角审计新发现

## 修复难度 / 优先级参考

- **修复难度 S**：< 1h（1-3 line 改动 / 删 dead code / 加 1 行常量）
- **修复难度 M**：1-4h（抽 helper / 修正 1 个中等文件 / 加单测）
- **修复难度 L**：1-3 day（架构重构 / 跨 4 层修正 / 修正整套 P0 bug）
- **P0**：数据丢失 / 安全 / 谎言 / 崩溃（必须修正）
- **P1**：功能错误 / 体验差 / 重要隐患（1 月内修正）
- **P2**：边界 case / 工程卫生 / 修正 dead code（v1.0 前修正）
- **P3**：nit / 风格 / 注释修正（顺手做）

---

## 元数据

- **整合者**：Mavis (root session `mvs_d073d0bd210e4ca8a33e3283019d4a30`)
- **整合方法**：7 份审计报告 → 1 份修正优先级矩阵
- **下次审计建议**：修正 A 批后（2 周）跑 1 次验证审计，确认 P0 全修正

---

# 📎 第七部分：superpowers-en 视角补充（轻量 · 修正记录完整）

> **任务状态**：`bg_1c5bce9a`（subagent 栈溢出 failed）— 由 Mavis 亲自做轻量补充
> **覆盖**：app.dart 230 行 / main.dart 393 行 / core_providers.dart 99 行 / app_router.dart 70 行 + 4 个 grep

## 7.1 架构质量总评

| 修正点 | 修正 round | 修正内容 | 当前状态 |
|---|---|---|---|
| 启动顺序 | v0.18 P2-P0-3 | FlutterError.onError + runZonedGuarded | ✅ 已修正 |
| 启动顺序 | v0.24 R48 | `tz_data.initializeTimeZones()` 修正海外 DST | ✅ 已修正 |
| 启动顺序 | v0.22 R31 sp-en P0-4 | `_showMigrationConfirmDialog` 降级返 `false`（保守拒绝） | ✅ 已修正（避自动删数据） |
| 启动顺序 | v0.22 R33 sp-en P0 | LastErrorCapture + LastStartupErrorBanner | ✅ 已修正 |
| 启动顺序 | v0.23 R38 P0-1 | `validateForRelease` + 抛 SmsProviderNotConfiguredError | ✅ 已修正（但跟 zh P0-1 还差 UI 三态分流） |
| 启动顺序 | v0.23 R38 P0-4 | 单一 AppDatabase 实例 + provider tree 共用 | ✅ 已修正 |
| 启动顺序 | v0.24 R45 | `_MigrationFailedApp` l10n 修正 | ✅ 已修正 |
| 启动顺序 | v0.24 R48 | 失败时安抚句（精神心理患者保护） | ✅ 已修正 |
| 启动顺序 | v0.21 P2-3 | AssessmentReminder.onAppStart 移到 AppRoot.initState 的 addPostFrameCallback | ✅ 已修正（避免 magic 100ms） |
| 跨日 | v0.17 R4 | `nextMidnightRefresh(now)` top-level 纯函数 | ✅ 已修正 |
| 跨日 | v0.21 P0-4 | `crossedMidnightSince(lastCheck, now)` + WidgetsBindingObserver | ✅ 已修正 |
| 跨日 | v0.21 P0-6 | `dayChangeTickProvider` 显式 provider | ✅ 已修正 |
| 跨日 | v0.23 R40 sp-zh D-06 | 改 `tz.TZDateTime` 替代 `DateTime` 修正 DST | ✅ 已修正 |
| 主题 | v0.21 R25 P3-1 | 主题切换淡入 `durNormal` | ✅ 已修正 |
| 主题 | v0.22 R29 emil-36 | 改 `curveStandard` (easeOutCubic) | ✅ 已修正 |
| Provider 树 | v0.17 R14 P1-3 | 拆 3 文件（core / service / vent） | ✅ 已修正 |
| Provider 树 | v0.16 R19 | 暴露 domain 接口不暴露 impl | ✅ 已修正 |
| Provider 树 | v0.17 R3 | Riverpod 3.x `valueOrNull` → `value` | ✅ 已修正（grep 验证 0 处） |
| Provider 树 | v0.23 R38 P0-4 | 复 `checkInRepositoryProvider` 不 `new` 第二个实例 | ✅ 已修正（避 stream 重复订阅） |
| 路由 | v0.25 R59 | 拆 god class（app_routes 7KB + app_shell 5KB） | ✅ 已修正 |
| 路由 | v0.26 R57 spen P2 #8 | `ref.read` + `ref.listen` + `_RouterProfileCache` 修正 GoRouter 重建 | ✅ 已修正（性能 bug 修正） |
| 路由 | v0.26 R57 | path param 改 `int.tryParse` 修正 FormatException | ✅ 已修正（grep 验证 0 处 `int.parse(`） |
| 错误处理 | v0.22 R33 | LastErrorCapture + Banner | ✅ 已修正 |
| 错误处理 | v0.22 R31 | migration dialog 降级返 `false` | ✅ 已修正 |

## 7.2 en 视角发现的新 P0/P1

**0 个新 P0 / 0 个新 P1 / 1 个新 P2 / 0 个新 P3**。

### 7.2.1 🟡 P2 — `main.dart:135` 临时 `SmsService()` 实例

**文件**：`lib/main.dart:135`
**现状**：`SmsService.validateForRelease(SmsService().provider)` 创建临时实例，没用 provider tree 里的 `smsServiceProvider` 实例。
**风险**：理论上有 2 个 `SmsService` 实例，state 共享可能错位（`provider` getter 返回新实例或缓存？需具体看 `SmsService` 实现）。实际上 `SmsService` 是无状态 facade，影响小。
**修正建议**：批次 A（修正 zh P0-1 时一起修正），改成 `ref.read(smsServiceProvider)` 之前先构造一个临时实例 + 跟 `SmsService()` 共享 state。
**实际已含在 zh P0-1 scope**（修正 P0-1 时 `SmsService` 改构造注入）。

### 7.2.2 en 视角未发现的 4 个修正

修正 zh P0-1 / 1.3 / 1.5 / 1.10 时，en 视角自动修正以下连带：
- **zh P0-1 SMS 撒谎修正** → en 视角修正 `main.dart:135`（跟上面 7.2.1 一起）
- **zh 1.3 SafetyAlert 通知撒谎修正** → en 视角修正通知层的 en 模式文案走 l10n
- **zh 1.5 失联 SMS 两条路径修正** → en 视角修正 `domain/logic/lost_contact_sms.dart` 的 i18n key
- **zh 1.10 check_sms_release_ready sys.exit 恢复** → en 视角修正守护脚本（也修正 1.8 / 1.9 关联）

## 7.3 en 视角修正建议

修正 zh A 批（1-2 周）时**同时修正**：
- `lib/main.dart:135` 改 `ref.read(smsServiceProvider)`（前提：provider 树已就绪）
- 修正所有 `lib/main.dart` 的 hardcode 中文 / 英文 fallback 走 l10n key

修正 zh B 批时**修正**：
- 加 1 个 `check_provider_tree_health.py` 守护脚本，扫 provider 树：
  - 重复 provider（同名 provider 定义 2+ 次）
  - 未被 watch / read 的 provider
  - 跨 feature import 违规（`presentation/pages/X/` 误 import `presentation/pages/Y/`）

修正 zh C 批时**修正**：
- 修正 `_MigrationPromptApp` / `_MigrationAbortedApp` / `_MigrationFailedApp` 提取到 `lib/presentation/widgets/migration_apps.dart`（v0.18 已修正过主流程，但 3 个 app 类仍 inline 在 main.dart 393 行文件里）
- 修正 0 个新增 P0/P1

## 7.4 修正历史完整性

修正纪律**极优秀**：
- 每个 round 修正都有 commit 注释（含 v0.X.Y round N 修正 reference）
- 每个修正 file:line 引用清楚
- AGENTS.md "已知坑" 段持续更新修正记录
- 修正记录与"修正前后对比"留有 commit message

修正历史修正记录**持续 18 个月**（v0.6 → v0.27 round 60+），修正密度**修正**修正。
