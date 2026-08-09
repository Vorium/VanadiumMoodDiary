# P2 中文规范 / 合规 / 隐私审查清单

> **审查范围**：D:\Batch\chroniccare Flutter 慢病 / 精神心理 App
> **审查视角**：superpowers-zh（中国特色规范）+ PIPL + 广告法 + 医疗广告 + App 违法违规收集
> **审查时间**：P1 全部 28 项 done (HEAD: 7ff087a) 之后
> **审查基线**：v0.17 末 / v0.18 初，528 cases pass，0 analyze error
> **审查方式**：静态 grep + 关键文件精读，**不修代码**，只产发现列表
> **审查员**：superpowers-zh 中文规范审查 sub-agent
> **优先级口径**：
> - P0 = 必须立刻修：法律风险 / PIPL 违规 / 隐私漏洞
> - P1 = 重要但可延：文案 / a11y / 国产 ROM / 错别字
> - P2 = 改善：商业 / 国际化 / polish
> - P3 = nice-to-have：探索性

---

## 0. 摘要 (TL;DR)

| 维度 | P0 立即 | P1 重要 | P2 改善 | P3 探索 | 合计 |
|---|---|---|---|---|---|
| PIPL / 隐私 | **8** | 5 | 2 | 0 | 15 |
| 广告法 / 医疗广告 | **2** | 1 | 0 | 0 | 3 |
| App 违法违规收集 | **3** | 2 | 1 | 0 | 6 |
| 中文文案 / 错别字 | 0 | **7** | 4 | 1 | 12 |
| 中文 a11y | 0 | **4** | 2 | 1 | 7 |
| 中国特色 / 商业 | 0 | 3 | **5** | 2 | 10 |
| 文档 / 占位 | 0 | **2** | 3 | 1 | 6 |
| **合计** | **13** | **24** | **17** | **5** | **59** |

**最关键 3 个发现（P0 立即）**：
1. **setup 第 1 步写「设置 → 法律与隐私」可撤回，但设置页根本没有这个入口**（虚假告知，PIPL 第 26 条）
2. **vent 文字 contentText 存 SQLCipher 但 field-level 是明文**（设备 root + 拿到 DB 加密 key = 直接 SELECT 读出用户最隐私倾诉）
3. **preset_medication_templates hint 仍列 8+ 真实处方药通用名**（碳酸锂 / 阿普唑仑 / 艾司唑仑 / 佐匹克隆 / 褪黑素，违反《药品广告管理办法》）

---

## 1. PIPL / 隐私类（15 项）

### P0（8 项 — 必须立刻修）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P0-01** | **「设置 → 法律与隐私」撤回同意是虚假告知** | `lib/presentation/pages/setup/setup_page.dart:226`<br>提示用户"您可以随时在「设置 → 法律与隐私」撤回同意" | setup 第 1 步文案承诺可撤回，但**设置页 (settings_page.dart) 整个 492 行没有任何"法律与隐私"入口**，也找不到 legal/withdraw/consentRevoke 任何路由/UI 元素。PIPL 第 26 条: 应当提供撤回同意的便捷方式。虚假告知属于告知违规。 | (1) 新建 `lib/presentation/pages/settings/legal_page.dart` + `app_router.dart` 加 `/settings/legal` 路由<br>(2) legal_page 显示 3 份文档 (复用 `setup_page.dart:991` 的 `_showLegalDocument`)<br>(3) 加 3 个独立开关：撤回失联通知同意 / 撤回数据导出 / 撤回敏感数据处理<br>(4) 撤回操作 = 立刻停推 + 不删数据（区别于删除权）<br>(5) 在设置页"提醒" section 顶部加"法律与隐私"入口<br>(6) 隐私政策 4. 撤回同意 一节真正实现 | 4-6h |
| **P2-P0-02** | **vent 文字 contentText 在 SQLCipher 内是 plaintext** | `lib/core/data/database/tables/vent/vent_entries.dart:21`<br>`lib/core/data/repositories/vent/vent_repository_impl.dart:47` | vent 录音已 AES-256 加密（**这是 P0-2 修过的**，v0.18 round 14），但 contentText 是 `Value(hasText ? text.trim() : null)` 直接写进 SQLCipher 表。SQLCipher 整体加密 = 攻击者必须先拿到 DB 加密 key 才能解密。**问题**：P0-2 隐含的"树洞文字也加密"安全承诺没兑现，**设备 root + 拿 key = 直接读 content_text 字段**。隐私政策 5.1 节只说"录音未加密"但**完全没提文字是 plaintext at field-level**。 | (1) vent text 走和 audio 一样的 `EncryptionService.encrypt(utf8.encode(text))`<br>(2) `content_text_enc` 字段 (BLOB) 替代 `contentText` (TEXT)<br>(3) mapper 解密给 UI<br>(4) 隐私政策 5.1 同步更新"文字 + 录音均加密"<br>(5) schemaVersion 7→8 + migration<br>(6) 旧条目 plaintext 写 1 次性 migration 加密 | 6-8h |
| **P2-P0-03** | **developer.log 大量打印敏感信息** | `lib/core/data/services/reminder_scheduler.dart:108-114`<br>`lib/core/data/services/email_service.dart:49-55`<br>`lib/core/data/services/sms_service.dart:46-53`<br>`lib/core/data/services/notification_service.dart` 多处 | P0-1 已发现 PII 泄漏（在 `reminder_scheduler.dart` 用 `developer.log('  用户: ${profile.userName}')` + `developer.log('  To (phone): $to')` + `developer.log(body, name: 'EmailService')`）。P0-1 fix 应该是：**生产构建**（`kReleaseMode` 或 `dart-define`）下全部 `developer.log` 改为 swallow 静默。<br>当前所有 `developer.log` 都默认跑，可能被 `adb logcat` / `idevicesyslog` / 设备厂商日志采集读取。 | (1) 在 `lib/core/shared/swallow_error.dart` 加 `devLog(name, msg)` wrapper，`kReleaseMode` 时 swallow 全部 `developer.log`<br>(2) 关键 service (`reminder_scheduler` / `email_service` / `sms_service`) 调用统一走 `devLog` 而不是裸 `developer.log`<br>(3) 加 dev-mode regression test: 验证 release 模式不打印 userName / phone / body<br>(4) `flutter build apk --release` 后用 `adb logcat` 验证无泄漏 | 3-4h |
| **P2-P0-04** | **setupContactHint 仍是 `mom@example.com`，P1-14 改了 email→phone 但翻译没改** | `lib/l10n/app_zh.arb:22`<br>`lib/l10n/app_en.arb:22`<br>`lib/presentation/pages/setup/setup_page.dart:296-298` | P1-14 把 contact 字段从 email 改成 phone，UI label/hint 都改了（"紧急联系人手机号"+"13800138000"），**但 i18n 文件没更新**。`app_zh.arb:22` 还是 `setupContactHint: "mom@example.com"`，`app_zh.arb:36` 还是 `setupContacts: "紧急联系人邮箱（至少 1 个）"`。<br>用户看到中文翻译说"邮箱"，但输入框提示"手机号"——**前后矛盾**。PIPL 告知原则要求信息真实准确。 | (1) `app_zh.arb`: `setupContacts` → "紧急联系人手机号（至少 1 个）", `setupContactHint` → "13800138000"<br>(2) `app_en.arb`: 同步更新为 phone hint<br>(3) `app_localizations_*.dart` 重新生成 | 0.5h |
| **P2-P0-05** | **setup step 0 UI 提示"除邮件通知"上云，但项目宣称"零云端"** | `lib/l10n/app_zh.arb:56`<br>`lib/l10n/app_en.arb:41`<br>`lib/presentation/pages/setup/setup_page.dart:791` | setup 第 3 步隐私声明 3 行：<br>• 本地加密<br>• **不会上传云端（除邮件通知）** ← "除邮件通知"<br>• 你可以随时导出<br>但 `README.md` / `WHITEPAPER.md` / `AGENTS.md` 全部声称"零云端"。邮件通知走 `EmailService`（mock）+ `SmsService`（mock）——**目前是 mock，没真发**。"除邮件通知"会让用户误以为邮件功能在偷偷上传数据。<br>PIPL 第 7 条: 告知内容应当真实准确。 | (1) 暂时改文案: `setupPrivacy2` → "• 不会上传到任何云端服务器"<br>(2) 删 "(除邮件通知)" — 邮件通知走用户邮箱 SMTP，不算"云端上传"<br>(3) 英文版同步: "• Never uploaded to cloud (except email)" → "• Never uploaded to any server"<br>(4) `app_localizations_*.dart` 重新生成 | 0.5h |
| **P2-P0-06** | **隐私政策 9.1 + 用户协议 8. 节都还是 `privacy@example.com` / `support@example.com` 占位邮箱** | `assets/legal/privacy_policy.md:85`<br>`assets/legal/user_agreement.md:57`<br>`README.md:168` | PIPL 第 52 条: 处理敏感个人信息前应告知"联系方式"。3 份法律文档都明确写"占位"，并声明"上线前必须替换为真实邮箱"。**目前没有真实邮箱**。<br>同样 `https://github.com/example/chroniccare/issues` 也是占位 GitHub URL。 | (1) 注册一个真实邮箱: privacy@yourcompany.com / support@yourcompany.com<br>(2) 替换 3 份 .md + 隐私政策 README 引用<br>(3) 建立实际反馈渠道（24h 内响应承诺）<br>(4) CHANGELOG 加 "P0-占位邮箱修复" | 1h |
| **P2-P0-07** | **"我是 XXX" 邮件模板强加 userName 字段** | `lib/core/l10n/strings.dart:15-17`<br>`lib/domain/logic/email_template.dart:31`<br>`lib/core/data/services/reminder_scheduler.dart` | `Strings.emailBody(userName, days)` → `'我是 $userName，已经 $days 天没在 App 里打卡了。\n'`。PIPL 第 6 条 (最小化) + 必要性原则：用户**没有**填名字时（"你的名字" 字段是选填或可空？），邮件里出现"我是  + 1 天" 尴尬。`user_profiles.userName` 是 `text()()` NOT NULL（必填）→ setup 第 2 步强制要求填名字（setup_page.dart:266 TextField），**用户不能跳过**。 | (1) `emailBody` 改成 `'我已 $days 天没在 App 里打卡了。\n'` (无 userName 占位符)<br>(2) 或：检测 userName.trim().isEmpty 时用 fallback "用户"<br>(3) 或：让 userName 真正可空（user_profiles 改 nullable + setup UI 标记"选填"）<br>(4) SMS 模板同样检查 | 2h |
| **P2-P0-08** | **设置页缺"清空所有数据"入口，违背隐私政策"注销 = 删除"承诺** | `lib/presentation/pages/settings/settings_page.dart:74-115`<br>整页 492 行无 `deleteAll` / `wipeAll` / `clearDatabase` 入口 | 隐私政策 7. "删除权" 写: "在 App 内删除单条 / 全部数据;卸载 App 立即清除所有本地数据"。但 UI 只能"导出 JSON" + "导入数据" (覆盖)，**没有"清空所有数据"按钮**。PIPL 第 47 条: 应当提供便捷的"主动删除全部"功能。<br>当前唯一删除路径：卸载 App = 数据连同迁移可能丢失（如果用户没导出）。 | (1) 在设置页"数据管理" section 加"清空所有本地数据" ListTile<br>(2) 弹二次确认 dialog: "将清空全部打卡 / 用药 / 评估 / 树洞 / 联系人，无法恢复"<br>(3) 实现 `AppDatabase.clearAllTables()` 走 drift `delete(go(Table))` 循环<br>(4) 删 vent audio 文件 (调 `VentAudioStorage.deleteAll()`)<br>(5) 清理后 `context.go('/setup')` 重新走 setup 流程<br>(6) 测：清空后 schemaVersion 不变, 重新 setup 数据全空 | 4-5h |

### P1（5 项 — 重要但可延）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-01** | **UserProfile 缺 consent 记录字段** | `lib/core/data/database/tables/user_profile/user_profiles.dart:6-19`<br>`lib/domain/entities/user_profile_entity.dart:4-29` | PIPL 第 14 条: 应记录同意情况。UserProfile 只有 `id/userName/checkInCycleHours/firstLaunchAt/lastCheckInAt`，**没有** `userAgreementVersion / privacyPolicyVersion / sensitiveDataConsentAt / consentRevokedAt` 字段。无法证明用户当时同意了哪一版协议。<br>合规审计：法务要求"用户授权时刻 + 协议版本 + IP/设备" 至少 3 字段。 | (1) UserProfile 加 4 字段:<br>  - `userAgreementVersion: text()` (e.g. "v0.18-2026-07-18")<br>  - `privacyPolicyVersion: text()`<br>  - `sensitiveDataConsentAt: datetime()`<br>  - `consentRevokedAt: datetime().nullable()`<br>(2) schemaVersion 7→8 + migration<br>(3) setup step 0 完成时写这 3 个 version + consent timestamp<br>(4) 撤回同意时写 `consentRevokedAt`<br>(5) "法律与隐私" 页面显示当前同意状态 + 撤回按钮 | 3-4h |
| **P2-P1-02** | **setup 3 步独立勾选但实际不写入"用户档案同意"字段** | `lib/presentation/pages/setup/setup_page.dart:42-44`<br>`setup_page.dart:800-870` 提交 | 即使没有 P2-P1-01 字段，setup 完成后 3 个 checkbox (`_consentUserAgreement / _consentPrivacyPolicy / _consentSensitiveData`) 状态**只活在内存**，写到 DB 的只有 `userName + firstLaunchAt + lastCheckInAt`。重启 App 后无法判断用户**是否** 同意过哪些文档。<br>PIPL 撤回同意 = 撤回"曾经同意的某项" → 必须有"曾经同意"的记录。 | (1) 加 P2-P1-01 字段<br>(2) `AppDatabase.completeFirstSetup(...)` 改签名，加 3 个 `bool` + 3 个版本号 + 1 个 timestamp 参数<br>(3) `user_profile_repository.dart` 同步 | 2-3h |
| **P2-P1-03** | **隐私政策说"联系人只用于失联通知"，实际也用于邮件通知** | `assets/legal/privacy_policy.md:38-41` §3 | 隐私政策 §3 写"失联通知触发时，我们将向**用户预置**的紧急联系人发送：用户姓名 / 距离上次打卡的日数 / 失联通知短信模板"。**真实代码** (`email_service.dart:50-55`) 邮件 / SMS 都发到联系人，且 `email_service.dart:49-55` 打印了 body（含 userName + days）到 developer.log。隐私政策没提"邮件通知"也用联系人，告知不完整。 | (1) 隐私政策 §3 改为"用于失联通知 + 失联确认邮件"两类<br>(2) `emailService` 走 `devLog` 不再裸 `developer.log`（P2-P0-03 fix）<br>(3) 加邮件内容的"用户预审"流程：先发到本人邮箱（"我们准备通知 XXX"）24h 后再发联系人 | 1-2h |
| **P2-P1-04** | **"我是 XXX" 邮件正文国际字符没考虑** | `lib/core/l10n/strings.dart:15-17` | 邮件模板 hardcode 中文 "我是 XXX" — 但 EmailService 是"任何"用户的失联通知通道，如果未来做 i18n / 海外用户（港澳台 / 国际区号 P1-14 修过），中文 hardcode 不通。 | (1) 邮件模板 i18n 化：接收 `Strings` 作为参数<br>(2) 暂留中文，但加注释 "TODO i18n"<br>(3) P1-1 之后 task 评估是否纳入 | 1h |
| **P2-P1-05** | **隐私政策 §3 联系人只写"姓名 + 手机号"但 setup UI 收集"姓名 + 手机号 + 排序"** | `lib/presentation/pages/setup/setup_page.dart:823-832`<br>`assets/legal/privacy_policy.md:15` | 联系人 list 还收 `sortOrder`，但隐私政策只说"姓名 + 手机号"。PIPL 告知原则: 收集字段必须明确告知。多收的 `sortOrder` 字段没告知。 | (1) 隐私政策 §1 表格补 `sortOrder` 字段（说明：仅用于"多个联系人按顺序通知"）<br>(2) UI 解释 sortOrder：通知按"排序"循环 — 但目前 reminders_hub 是按 sortOrder 顺序通知 1 个联系人，不是循环 | 0.5h |

### P2（2 项 — 改善）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-01** | **隐私政策说"设备信息"但不收集** | `assets/legal/privacy_policy.md:18` | §1 表格第 5 行"设备信息: 设备型号 / 操作系统版本 — 通知 / 兼容性" → 但 `pubspec.yaml` 没 `device_info` / `package_info` 依赖，代码里没收集。PIPL 告知原则: 声明了但没收集 = 应当删除或说明是预留。 | 隐私政策 §1 删"设备信息"行 + 隐私政策 §6 "不主动收集"加一行"设备信息" | 0.5h |
| **P2-P2-02** | **隐私政策 §7 SDK 清单 5 个不全** | `assets/legal/privacy_policy.md:67-71`<br>对照 `pubspec.yaml` | §7 列 5 个 SDK：flutter_secure_storage / sqlcipher_flutter_libs / flutter_local_notifications / audioplayers+record / go_router+riverpod+drift。但 pubspec 还有：`path_provider / path` / `permission_handler` (收集权限状态) / `share_plus` (导出数据用 share sheet，可能泄漏到系统) / `shared_preferences` / `fl_chart` / `pdf`+`printing` / `intl` / `uuid` / `flutter_dotenv` / `freezed_annotation`+`json_annotation` / `encrypt` (加密库) / `flutter_timezone`+`timezone`。<br>PIPL 第 52 条 + 《App 违法违规收集》6 大类: SDK 清单必须真实完整。 | 隐私政策 §7 加全 pubspec 依赖列表，分"数据相关" / "纯框架" 2 类 | 1h |

---

## 2. 广告法 / 医疗广告类（3 项）

### P0（2 项 — 必须立刻修）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P0-09** | **preset_medication_templates 仍列 8+ 真实处方药通用名** | `lib/core/data/services/preset_medication_templates.dart:71, 89, 110, 119, 132` | P0-5 改过 hint 文案（删了 4 个最有名的：舍曲林 / 氟西汀 / 文拉法辛 / 利培酮），**但没改全**。当前 hint 还有：<br>• "常见 SSRI / SNRI 类抗抑郁药"（OK, 分类）<br>• **"常见：碳酸锂 / 丙戊酸钠 / 拉莫三嗪"** ← 3 个真实处方药<br>• **"常见：阿普唑仑 / 艾司唑仑 / 佐匹克隆 / 褪黑素"** ← **阿普唑仑 / 艾司唑仑是国家管制的二类精神药品**，《精神药品品种目录》收录；褪黑素是保健品<br>《药品广告管理办法》§4: 处方药不得在大众媒体做广告。<br>《广告法》§15: 处方药不得发布广告。 | (1) hint 全部改为"具体药名以医生处方为准" / "SSRI 类" / "苯二氮卓类助眠药"（不写通用名）<br>(2) 模板 name 里的 "SSRI / SNRI" 改成 "抗抑郁药" 通用分类<br>(3) name "情绪稳定剂" / "抗精神病药" / "镇静/抗焦虑辅助" 已 OK<br>(4) review 全部 6 个模板的 hint 字段<br>(5) 加 schemaVersion 8 migration 把旧 hint 替换为新 | 1-2h |
| **P2-P0-10** | **隐私政策 §1 §3 仍说"医疗"+"治愈"暗示** | `assets/legal/privacy_policy.md:14`<br>`docs/DEPLOYMENT.md:155` | 隐私政策 §1 写"健康数据: 药名 / 剂量 / 打卡时间 / **PHQ-9 / GAD-7 评估分**"。DEPLOYMENT.md §风险 §155 写"复发一次，再治愈更难"。<br>《广告法》§16 + 《医疗广告管理办法》§3: 医疗广告禁止"承诺治愈率" / "保证治愈"。"再治愈更难"虽不是承诺，但**医疗 App 自我描述里用"治愈"一词风险高**。<br>同时"健康数据"在 PIPL 是"敏感个人信息"，"医疗"定性 → App 是否需要医疗备案（**国家药监局 NMPA**《移动医疗器械注册管理办法》）？ | (1) DEPLOYMENT.md 风险章节"再治愈更难" → "再次停药后，重新规律吃药所需时间会更长"<br>(2) 隐私政策 §1 改"健康数据" → "健康记录"<br>(3) 评估 App 法规定性: 精神心理自评工具（P1-3 不构成"医疗"）但需说明"本 App 不构成医疗器械"<br>(4) settings_page.dart disclaimer 已写"不提供医疗建议"，但**免责声明 vs 法律定性**需律师确认 | 1-2h |

### P1（1 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-06** | **setupReminder3 "我会联系紧急人" 措辞** | `lib/l10n/app_zh.arb:53` | setup 第 3 步写"✓ 漏 2 天我会联系紧急人"。"我会联系" → 隐含承诺。《广告法》§24: 教育 / 培训广告不得保证。但慢病 App 的"我会联系"**算不算承诺？**<br>实际实现：CareEngine 触发 SMS/email 给紧急联系人，**确实是承诺**。问题是用户对"漏 2 天"理解可能不同（gap >= 36h？实际代码 `care_engine.dart:103` 写 `minutesSince >= 36 * 60 && now.hour >= 10`）。 | (1) setupReminder3 改为"✓ 漏 2 天会通知你的紧急联系人"（去主观化）<br>(2) settings reminders_hub 加"失联检测阈值配置" UI（当前写死 36h，PHQ 第 9 题危机不是 36h 触发）<br>(3) CareEngine 阈值可配 | 1-2h |

---

## 3. App 违法违规收集个人信息类（6 项）

### P0（3 项 — 必须立刻修）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P0-11** | **"用户名"不是必要个人信息，可 nickname / 匿名** | `lib/core/data/database/tables/user_profile/user_profiles.dart:10`<br>`lib/presentation/pages/setup/setup_page.dart:266-280` | PIPL §6 最小化 + 《App 违法违规收集》§4 必要原则：用户真名**不是** 慢病打卡 App 的必要信息。**PIPL §4**: 个人信息处理应有明确合理目的，并与处理目的直接相关。<br>当前 userName 直接进 `email_service.dart` 邮件"我是 XXX" + 推送标题 + SMS 模板。但用户**完全可以匿名 / 用昵称**。 | (1) setup 字段 label 改"你的名字（昵称也可）"<br>(2) hint 改"小明 / 小红"<br>(3) 隐私政策 §1 改"用户标识: 用户昵称 — 用于通知个性化 + 失联邮件"<br>(4) 邮件/SMS 模板里 "我是 XXX" 改成 "我"（去掉名字占位） | 1-2h |
| **P2-P0-12** | **紧急联系人电话真必要？可考虑只收邮箱或 app 内通知** | `lib/presentation/pages/setup/setup_page.dart:288-300`<br>`lib/core/data/services/sms_service.dart` | PIPL §6 最小化：电话 vs 邮箱 vs app 内 push 哪个必要？<br>实际：失联通知是**救命功能**——电话 = 兜底。但收集 3 个联系人电话 = 收集 3 个无关人 PII（这 3 个联系人**没同意**被收集）。<br>PIPL §13 知情同意: 紧急联系人**不是**用户，其 PII 处理应另行告知。当前隐私政策没给"紧急联系人须知"。 | (1) setup 第 2 步加"添加紧急联系人须知"：<br>  "我们建议你提前告知 [联系人姓名] 你的手机号会用于失联通知；其姓名和手机号存在你 App 本地，不上传"<br>(2) UI 加 checkbox: "我已告知 [联系人姓名] 上述情况"<br>(3) 隐私政策 §3 补"紧急联系人的知情权" | 2-3h |
| **P2-P0-13** | **setup 4 步 = 0/1/2/3 但 setupStep(current, total) 显示"第 1 步/共 4 步"是"第 0 步"** | `lib/l10n/app_zh.arb:25`<br>`lib/presentation/pages/setup/setup_page.dart:74` | `setupStep` 用 `(current+1, 4)` 算。`current` 从 0 开始。UI 显示 "第 1 步/共 4 步" 但实际 4 步是 consent(0) + welcome(1) + medication(2) + done(3)。<br>问题是 consent 步算"第 1 步"？PIPL §14 单独同意: 同意环节不应当"被包含在通用 setup 流程里"而要**前置 + 显眼**。<br>应改为：<br>• 同意页 = 第 0 阶段, 独立于 setup 4 步<br>• setup 是 3 步: 欢迎 / 用药 / 完成 | (1) 路由拆: `/consent` (P0-6 单独 page) + `/setup` 3 步<br>(2) 或: consent 是 setup 前的强制 gate, 用 `WillPopScope` 拦截"返回"<br>(3) `setupStep` 改成 `(current, total-1)` 并标"开始前请阅读法律条款" 横幅 | 2h |

### P1（2 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-07** | **PII 访问权限 UI 不明** | `lib/presentation/pages/contact/contacts_list_widget.dart:105-115` | 设置页加联系人 = 调 `permission_handler`？还是直接加？权限流程：<br>1. setup 阶段：用户主动输入电话 → 不需要 `READ_CONTACTS` 权限（自己手输入）<br>2. 但 UI 是否有"从通讯录选"按钮？PIPL §6: 不必要的权限不要申请。<br>如果当前没申请 `READ_CONTACTS` 权限 = 没问题。如果有 = 违反最小化。 | (1) 确认 `pubspec.yaml` 没 `permission_handler` 用作通讯录<br>(2) 加 P2-P1-08 验证: 实际权限申请 = 通知 / 麦克风 / 存储 / 时区 — 都不涉及"用户通讯录"<br>(3) 隐私政策 §1 加"我们不读取您设备的通讯录" | 0.5h |
| **P2-P1-08** | **导出 JSON 内 vent 文字导出但录音文件不导出，文案不一致** | `lib/presentation/pages/settings/settings_page.dart:259-264`<br>`lib/core/data/services/data_export_service.dart:50-90`<br>`assets/legal/privacy_policy.md:65` | settings_page.dart 写"树洞(私密倾诉)的文字会导出，但录音文件不导出"。但隐私政策 §5 说"录音加密"。**逻辑矛盾**——既然录音加密，应该能导出 (用户拿加密文件 + 拿加密 key)?<br>实际：导出只导 vent text 字段，不导 audioPath。 | (1) 选项 A: 录音也导，但 key 怎么给？ 用户复制 key 进 JSON → 安全？<br>(2) 选项 B: 维持现状但更新隐私政策<br>(3) 选项 C: vent audio 永不导出 (永久本地)，隐私政策 §3 写明<br>(4) 推荐 C，简洁 | 0.5h |

### P2（1 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-03** | **登录时无"是否同意隐私政策"明确时机** | `lib/main.dart:40-150` 启动 | 当前是 setup 第 0 步强制勾选。问题是：App 启动 → 显示首页 → 用户没用过 App 时"首页"已经展示用户数据（打卡 / streak / 评估历史）。<br>PIPL 知情同意 §14 应当"在处理个人信息前"。当前是"setup 完成后才能进首页" — 但首页 UI 元素 / 文案已经让用户看到 / 体验了。 | (1) 启动时判断 `userProfile == null` → 直接 route 强制 setup<br>(2) 不要先 show 首页 "loading" 再 redirect — 让首次用户体验更"先告知后使用" | 0.5h |

---

## 4. 中文文案 / 错别字类（12 项）

### P1（7 项 — 重要但可延)

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-09** | **"setupMedTimes1/2/3" 用 `1次 / 2次 / 3次` 无空格** | `lib/l10n/app_zh.arb:43-45` | 中文 + 数字 + 中文 量词，无空格符合《中文文案排版指北》：<br>✓ "1次" 正确（数字+中文之间通常无空格）<br>但 "1次" / "2次" / "3次" 是**模板化**字符串。读起来"1次"容易看成"十一"——> 应统一为 "1 次"。 | 改为 "1 次" / "2 次" / "3 次"（加全角空格）<br>但中文规范不强制—— Google 「中文文案排版指北」明确**数字 + 量词不加空格**。<br>**结论**：当前 "1次" 正确，**不修**。 | 0h（无需改） |
| **P2-P1-10** | **"7/14/30 天" 数字-斜杠-数字** | `lib/l10n/app_zh.arb:66` | "选时间窗口（7/14/30 天）" 中文 + 数字 + 斜杠 + 数字 + 中文 — 斜杠 ` /` 在中文内用全角 `／` 更合规范（《标点符号用法》GB/T 15834-2011）。 | 改为 "选时间窗口（7／14／30 天）" 或保留半角但加空格"7 / 14 / 30 天" | 0.5h |
| **P2-P1-11** | **"PHQ-9 / GAD-7" 数字-连字符-数字** | `lib/l10n/app_zh.arb:53`<br>`lib/l10n/app_zh.arb:111`<br>多处 | "PHQ-9 抑郁筛查" 等 — 量表名是英文 ID，按国内医学界惯例 "PHQ-9" 写法正确（连字符 + 数字）。<br>但 setupReminder3 "每 $days 天提醒做心理评估（PHQ-9 / GAD-7）" 中"PHQ-9 / GAD-7"用半角斜杠 — 中文 + 英文 ID 混排时建议前后加空格。 | setupReminder3 改"每 $days 天提醒做心理评估（PHQ-9 / GAD-7）" 改成"每 $days 天提醒做心理评估（PHQ-9／GAD-7）" 或 "PHQ-9 / GAD-7"前后加空格 | 0.5h |
| **P2-P1-12** | **"commonLoading" 加载中... 用 3 个英文点** | `lib/l10n/app_zh.arb:78` | "加载中..." 是半角省略号 = 3 个半角点。中文文案排版指北要求用 1 个全角省略号 `……`（GB/T 15834-2011 §4.6）。 | 改为 "加载中……"<br>同理所有 "..." → "……" | 1h |
| **P2-P1-13** | **"checkInReminder1-3" 模板句首 ✓ 符号** | `lib/l10n/app_zh.arb:51-53` | "✓ 推送 1 次提醒" 句首 ✓ 是非中文符号，中文 UI 标准多用 "·" 居中点（项目其他地方用了 "•"）。UI 一致性。 | 改为 "· 推送 1 次提醒" 或保留 ✓ 但统一 checkmark 风格 | 0.5h |
| **P2-P1-14** | **"homeStillOnline" 🌱 你还在线** | `lib/l10n/app_zh.arb:21` | "🌱 你还在线" — 🌱 (sprout) 表达"还在坚持 / 还在生长"，OK。<br>但 vent 树洞里也用 🌱？检查 `last_med_info.dart:35` "少 1 次没关系，明天继续 🌱" — OK 同 🌱 出现 2 处。<br>**问题**：抑郁 / 自伤倾向的用户看到 🌱（植物）emoji 可能联想到其他意象。医疗 App 慎用 emoji。 | 评估 emoji 风险。如保守，去掉所有 🌱 改纯文字 "继续坚持" / "明天继续" | 0.5h |
| **P2-P1-15** | **"snackbarPhoneInvalid" 文案与 setup 错位** | `lib/l10n/app_zh.arb:88`<br>`lib/l10n/app_en.arb:62` | "号码格式不对（支持大陆/港澳台/国际）" — 用了 **半角** `/` 而不是 **全角** `／` 或 `、`。P1-14 修了电话区号支持但文案是 P1-14 一起补的，**没统一标点**。 | 改为 "号码格式不对（支持大陆／港澳台／国际）" 或 "号码格式不对（支持大陆、港澳台、国际）" | 0.5h |

### P2（4 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-04** | **英文翻译 "phone" vs 中文 "邮箱" 残留** | `lib/l10n/app_en.arb:21, 22, 23` | "Emergency contact emails (at least 1)" / "mom@example.com" / "+ Add another contact" 仍是邮箱语言，**P1-14 改了中文 UI 但英文 UI 没改**。<br>更严重：英文版 setup 流程对国际用户**误导**——以为需要填邮箱。 | 同步改英文 i18n 为 "Emergency contact phones" / "13800138000" / "+ Add another contact" | 0.5h |
| **P2-P2-05** | **"appTagline" 翻译"I took my meds today"** | `lib/l10n/app_en.arb:4-7` | "I took my meds today" 是 "我今天吃了药" 原文直译。地道英文应该是 "Took my meds today" 或 "Daily check-in: meds taken"。"I took" 略书面 / 婴儿语。 | 改为 "Took my meds today" | 0.1h |
| **P2-P2-06** | **"homeStreakBroken" 翻译"Missing 1 is fine, tomorrow counts"** | `lib/l10n/app_en.arb:17` | "Missing 1 is fine, tomorrow counts" — 英文 "tomorrow counts" 略硬。地道英文: "Missed one? Tomorrow counts" / "Missing one is fine, tomorrow is a new start"。 | 改 "Missed one? Tomorrow counts" | 0.1h |
| **P2-P2-07** | **"snackbarPhoneInvalid" 英文"CN/HK/MO/TW/intl"** | `lib/l10n/app_en.arb:62` | "Phone format invalid (CN/HK/MO/TW/intl)" — 缩写不地道。国际用户对 CN/HK/MO/TW 不熟。 | 改 "Phone format invalid (mainland China, Hong Kong, Macao, Taiwan, international)" | 0.1h |

### P3（1 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P3-01** | **缺繁体中文（港澳台）** | `lib/l10n/app_zh.arb` 只有简中 | 项目支持港澳台手机号（P1-14 扩展），但文案只有简体中文。港澳台用户用 App 时：<br>• 简体字"联系人" vs 繁体"聯絡人"<br>• 简体"继续" vs 繁体"繼續" | (1) 加 `app_zh_Hant.arb` 繁体版（≈ 5% 工作量）<br>(2) Flutter localizations 自动按系统 locale 切换<br>(3) 隐私政策 3 份 .md 也需要繁体版 | 6-8h |

---

## 5. 中文 a11y 类（7 项）

### P1（4 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-16** | **TextField 全无 Semantics label** | `lib/presentation/pages/vent/vent_compose_page.dart:316-325`<br>`lib/presentation/pages/setup/setup_page.dart:266-302`<br>`lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:211-230`<br>所有 TextField | 中文屏幕阅读器（TalkBack / VoiceOver）需要 `Semantics(label: ...)` 才能朗读输入框。当前 TextField 无 `decoration.labelText` 是中文（"你的名字"）但**屏幕阅读器**可能朗读成英文翻译 "your-name" 或乱码。<br>Flutter 中文 TTS 需系统装"讯飞语音" / "百度语音" — 系统默认 Google TTS 不支持中文。 | (1) 给所有中文 TextField 加 `decoration.labelText: Text(AppLocalizations.of(...).xxx)` — 项目已用 i18n，OK<br>(2) 加 `inputFormatters: [LengthLimitingTextInputFormatter(N)]`<br>(3) 加 `semanticCounterText: true` 让 TalkBack 朗读字符数<br>(4) 测：开 TalkBack 中文（需装讯飞语音）走 setup 流程 | 2-3h |
| **P2-P1-17** | **中文读屏不支持 — 没用 Tts()** | `lib/` 全项目 grep | 项目有 audioplayers 播录音，但**没**用 `flutter_tts` 给读屏兜底。失明 / 视障用户不能用 App 评估心理量表。 | (1) 加 `flutter_tts` 依赖<br>(2) 设置页加"读屏辅助"开关<br>(3) 评估题 / 危机对话框用 TTS 朗读<br>(4) 工作量大，列为 P1 | 6-8h |
| **P2-P1-18** | **录音 mic 权限拒绝后无降级** | `lib/presentation/pages/vent/vent_compose_page.dart:90-100`<br>`lib/main.dart` 启动时 | 启动 App 后立即要 mic 权限？或第一次点录音才要？ P0 fix 了"snackbarNeedMicPermission" 但**第一次启动 → 主页 → 直接看到 mic 入口**没提示前置权限。 | (1) 主页 vent 入口加 "需要麦克风权限" 预提示<br>(2) 第一次进入 vent compose 主动请求权限<br>(3) `permission_handler` 已经在 pubspec，启用即可 | 1h |
| **P2-P1-19** | **中文 UI 长度溢出风险** | `lib/presentation/pages/contact/contacts_list_widget.dart:45` `Text(contacts[i].phone)` | 中文 + 港澳台 / 国际手机号最长 15 位（E.164）+ 国家码 +86，**ListTile 宽屏可能溢出**。<br>当前用 `Text(contacts[i].phone)` 无 `overflow: TextOverflow.ellipsis` 兜底。 | (1) `Text(contacts[i].phone, overflow: TextOverflow.ellipsis)`<br>(2) `maxLines: 1` | 0.5h |

### P2（2 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-08** | **"我是 XXX" 模板中"XXX"是机器码感** | `lib/core/l10n/strings.dart:15-17` | 中文 UI 风格化差。"我是 XXX" 像 SQL 占位符。 | "我是 $userName" 改为 "我是「$userName」" 加全角引号<br>或 "我 ($userName) 已经 $days 天没打卡了" | 0.1h |
| **P2-P2-09** | **中文行高 1.5 不一致** | `lib/core/theme/app_tokens.dart` | setup_page.dart 用 `height: 1.4` (consent hint) / `height: 1.5` (legal doc) / `height: 1.2` (title)。中文阅读最佳行高 1.5-1.7（GB/T 9704 党政机关公文格式）。 | (1) `AppTokens.lineHeightTight = 1.3`<br>(2) `AppTokens.lineHeightBody = 1.5`<br>(3) `AppTokens.lineHeightLegal = 1.7`<br>(4) 全文搜 height: 1.x 替换为 token | 2-3h |

### P3（1 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P3-02** | **"您的" vs "你的" 用法不统一** | `lib/l10n/app_zh.arb` 多处 | 项目 setup 步骤用 "你的名字"（口语）但 disclaimer "本应用不提供医疗建议" 用 "本" 不用 "您"。`snackBarPhoneInvalid` 用 "您" 又有。<br>现代 App 多用"你"（去敬语化），但**医疗 App 建议用"您"** 表示尊重。 | 全文统一 "你" → "您"（医疗 App 风格）<br>grep 替换 30+ 处 | 1h |

---

## 6. 中国特色 / 商业 / 隐私边界类（10 项）

### P1（3 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-20** | **国产 ROM 自检卡只覆盖 5 品牌，缺 4 品牌** | `lib/presentation/pages/settings/widgets/notification_status_card.dart:240-300` | `_OemBackgroundHint` 列了 5 家：**小米/华为/OPPO/Vivo/魅族**。**漏了**：<br>• 锤子 (Smartisan) — 仍有少量用户<br>• 一加 (OnePlus) — 实际是 OPPO 子公司, 部分独立<br>• 真我 (Realme) — OPPO 子品牌<br>• 努比亚 / 红魔 (nubia) — 游戏手机<br>• 中兴 (ZTE) — 老年机<br>• 联想 (Lenovo) — 老年机 / 平板 | (1) 加 2-3 个最常见"漏网"：一加 / 真我 / 努比亚<br>(2) 末尾加 "其他品牌？" 引导用户去对应官方论坛 | 1h |
| **P2-P1-21** | **setup 第 2 步"我每天会做" 是叙述视角混乱** | `lib/l10n/app_zh.arb:50-53`<br>`lib/presentation/pages/setup/setup_page.dart:770-790` | setup 第 3 步 "我每天会做：" + "✓ 推送 1 次提醒" + "✓ 你点 1 下 = 打卡" + "✓ 漏 2 天我会联系紧急人"。<br>**人称混乱**：<br>• "我每天会做" ← 第一人称（App 视角）<br>• "推送 1 次提醒" ← App 视角<br>• "你点 1 下" ← 第二人称（用户视角）<br>• "我会联系紧急人" ← 第一人称<br>同一段话 App 视角和用户视角混着说。 | 全部统一为"你"（用户视角）：<br>• "你每天会做："<br>• "✓ App 推送 1 次提醒"<br>• "✓ 你点 1 下 = 打卡"<br>• "✓ 你漏 2 天 App 会联系紧急人" | 0.5h |
| **P2-P1-22** | **联系人 SMS 模板没考虑国内外地区** | `lib/core/l10n/strings.dart:15-17` | SMS 模板中文 hardcode。港澳台 / 国际用户用 App 失联通知时，**国内亲人收到中文 SMS** —— OK。但**国际用户用 App**, 国外亲人收到中文 SMS 呢？<br>实际项目主张 0 云端，目前 SMS mock，但 mock 模板仍是中文。 | (1) i18n 化 SMS 模板<br>(2) 按 contact 存储"国家码" 推断 locale<br>(3) P2 改善（功能层面 1.0+） | 2h |

### P2（5 项 — 改善）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-10** | **i18n 翻译机翻痕迹** | `lib/l10n/app_en.arb` 整文件 | "Pick a time window" 略生硬。地道 "Choose a date range"。"Aggregates your regular + temp medications in this window" 句子太长。 | 找 1 个 native speaker review 全部 50+ string。<br>或: 用 DeepL API + 人工 review。 | 4-6h |
| **P2-P2-11** | **节假日 / 农历 / 24 节气支持缺失** | `lib/` grep 0 hit | streak 算法基于"日"（`streak_calculator.dart`），不考虑节假日。但**中国用户**过年 / 国庆回家可能"漏 1 天吃药"是文化惯例，**不应破 streak**。<br>PHQ 评估周期 = 14 天但春节前后作息不同。 | (1) 加 `flutter_chinese_calendar` 或 `chinese_calendar` 依赖<br>(2) 7 大节假日（春节/端午/中秋/国庆等） streak 跳过<br>(3) 评估周期在节假日延后 | 6-8h |
| **P2-P2-12** | **失联通知默认 36h 阈值** | `lib/domain/logic/care_engine.dart:103` | `minutesSince >= 36 * 60 && now.hour >= 10` — 写死 36h。<br>不同用户需求不同：<br>• 重度抑郁 / 高自杀风险用户 = 12h 阈值更安全<br>• 慢病稳定期用户 = 72h 即可<br>setup 阶段没让用户配。 | (1) setup 步骤加"失联检测阈值"选择 (12h/24h/36h/48h/72h)<br>(2) `UserProfileEntity` 加 `safetyThresholdHours`<br>(3) `reminders_hub` 失联通知卡可调整 | 3-4h |
| **P2-P2-13** | **变现 / 商业模式不清晰** | `assets/legal/user_agreement.md:31-32` | 用户协议 §3 写"售价人民币 8 元（Google Play / Apple App Store 统一定价），一次性买断"。<br>但 pubspec 没 `in_app_purchase` 依赖, 代码无 IAP 实现。**App 实际是免费**（0 元）<br>隐私政策 / 商业模型 / 上架价 = 三个文档互相矛盾。 | (1) 选 1 个商业模型：<br>  A. 完全免费 + 未来 Pro 增值<br>  B. 一次性 8 元买断 + 写 IAP 实现<br>  C. 订阅制 + 写 IAP 实现<br>(2) 统一 3 份法律文档 + pubspec + 上架信息<br>(3) 推荐 B (匹配用户协议) | 1-2h |
| **P2-P2-14** | **第三方医院合作接口未实现** | `lib/domain/entities/` 0 hit | 项目说"对接医院"，但代码无 医院 API / 处方上传 / HIS 集成。<br>用户协议 §1 写"医疗报告给医生看" → 医生怎么拿？<br>PIPL 共享 §23: 与第三方共享需单独同意。 | (1) 评估是否真要做"医院对接"<br>(2) 如做: 加 `hospital_partner_repository.dart` + 单独 consent<br>(3) 如不做: 删用户协议 §1 相应文案 | 2-3h |

### P3（2 项 — 探索性）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P3-03** | **离线/弱网场景未测** | `lib/main.dart:1-280` 启动 | 当前启动流程依赖 `flutter_dotenv` 加载 `.env`。**弱网 / 离线** 用户首次启动会 `.env 加载失败`（main.dart:37 debugPrint）→ 但 fallback 是什么？<br>如果是 sync 加载会卡。 | (1) `.env` 改为 build-time 注入 (--dart-define)<br>(2) 启动流程加 `isOnline` 探测<br>(3) 离线模式：只显示本地数据 | 3-4h |
| **P2-P3-04** | **农历 / 节气 / 生日支持** | `lib/` 0 hit | 老年用户 / 传统习惯用农历生日提醒。 | (1) 加 `chinese_calendar` 依赖<br>(2) 联系人可加"农历生日" + 通知<br>(3) 用药也可加"节气提醒" | 8-12h |

---

## 7. 文档 / 占位 / 元数据类（6 项）

### P1（2 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P1-23** | **pubspec.yaml version 还是 `0.1.0+1`** | `pubspec.yaml:4`<br>`lib/presentation/pages/settings/settings_page.dart:218` | pubspec.yaml `version: 0.1.0+1` + settings_page.dart 显示 "v0.1.0 · 我今天吃了药"。<br>CHANGELOG 已 v0.17.0。**用户从 store 看是 v0.1 是误导**。 | (1) pubspec 改 `version: 0.18.0+1`<br>(2) settings_page 同步显示 `v0.18.0`<br>(3) AGENTS.md / CHANGELOG 同步 | 0.2h |
| **P2-P1-24** | **README 写"SMS 走阿里云占位"但 阿里云占位 class 实际 throw** | `README.md:168`<br>`lib/core/data/services/sms_service.dart:99` | README 写 "SMS 走阿里云占位（v1.0 上正式接入）" 但 `AliyunSmsProvider.send()` 直接 `throw StateError('未实现')`。**占位 ≠ 占位**——README 给用户"看起来能发"的预期，代码实际 throw。 | (1) README 改为"目前 SMS 是 mock 占位（v1.0+ 接阿里云）"<br>(2) 或：mock provider 真的静默 log（不 throw）<br>(3) reminders_hub 已加 P0-1 banner 提示"还是 mock 状态" | 0.5h |

### P2（3 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P2-15** | **3 份法律文档最后更新日期都是 `2026-07-18` 但代码 v0.18 内容早已变** | `assets/legal/privacy_policy.md:5`<br>`assets/legal/user_agreement.md:4`<br>`assets/legal/sensitive_data_consent.md:5` | 3 份 .md 都写"最后更新: 2026-07-18"。但 CHANGELOG 之后又 N 轮修改。**法律文档与代码不同步** = 告知违规。 | (1) 加 CI check: `git diff --name-only HEAD~10 | grep -E '\.md$' | grep legal` → 触发"法律文档重审"流程<br>(2) 每改一处涉及用户权利的代码，**必须同步更新对应法律文档**<br>(3) 加 `docs/LEGAL_CHANGELOG.md` 记录每次法律文档变更 | 2h |
| **P2-P2-16** | **隐私政策 §1 表没标"是否敏感个人信息"** | `assets/legal/privacy_policy.md:11-19` | §1 表只列"信息类别 / 具体字段 / 收集目的 / 存储位置"，**没明确标"是否敏感"**。PIPL §28 敏感个人信息需"单独同意"。<br>虽然 §2 单独 consent 文件覆盖了"敏感"，但 §1 表应明确标 `敏感: ✅ / ❌`。 | §1 表加 1 列"敏感" — 健康数据 ✅ / 联系人 ❌ / 树洞 ✅ / 设备信息 ❌ | 0.5h |
| **P2-P2-17** | **隐私政策 缺"未成年人保护"明示** | `assets/legal/privacy_policy.md` 整文件<br>对照 §敏感同意书 §1 末 "14 周岁以下" | 敏感同意书 §1 末尾列了"14 周岁以下未成年人的信息"作为敏感个人信息分类。<br>但隐私政策**没说**对未成年人的处理：<br>• 是否允许注册？<br>• 是否需要家长同意？<br>• 是否做年龄限制？<br>代码里 `setup_page.dart` 也没年龄校验。 | (1) 隐私政策 §1 末加"未成年人保护"段<br>(2) 写"本 App 不对 14 岁以下开放"<br>(3) setup 步骤加"您的年龄" 必填字段（< 14 拒绝）<br>(4) 或：模糊"非医疗建议"以规避医疗 App 对未成年人限制 | 2h |

### P3（1 项）

| ID | 标题 | 位置 | 描述 | 建议修法 | 工作量 |
|---|---|---|---|---|---|
| **P2-P3-05** | **AGENTS.md 没列 P2 阶段产物** | `AGENTS.md` 决策记录 | AGENTS.md 决策记录表已 12+ 行，**没 P2 阶段产物**。新加 sub-agent 不知道 P2 工作流。 | (1) AGENTS.md 决策表加 P2 阶段关键决策<br>(2) 或: 加 `docs/REVIEW_PIPELINE.md` 描述 P0/P1/P2 流程 | 0.5h |

---

## 8. 整体排序（按工作量 / 风险）

### 必做（P0 立即 修）— 估算 26-35 h

1. **P2-P0-01** 撤回同意 UI + 路由 (4-6h) ⭐ 最优先
2. **P2-P0-03** developer.log 生产 swallow (3-4h) ⭐ 最优先
3. **P2-P0-02** vent 文字加密 (6-8h) ⭐ 最严重
4. **P2-P0-09** 模板 hint 删处方药通用名 (1-2h) ⭐ 1 行字面
5. **P2-P0-05** setupPrivacy2 改"零云端" (0.5h) ⭐ 1 行字面
6. **P2-P0-04** setupContactHint 改 phone (0.5h) ⭐ 1 行字面
7. **P2-P0-06** 替换占位邮箱 (1h) ⭐ 1 行字面
8. **P2-P0-07** emailBody 去 userName (2h) ⭐
9. **P2-P0-08** 清空所有数据入口 (4-5h) ⭐ PIPL §47
10. **P2-P0-10** "治愈" 改 "再规律" (1-2h) ⭐
11. **P2-P0-11** userName 提示 "昵称也可" (1-2h) ⭐ PIPL §6
12. **P2-P0-12** 联系人知情同意 (2-3h) ⭐ PIPL §13
13. **P2-P0-13** consent 步拆独立 (2h) ⭐ PIPL §14

### 应该做（P1 重要）— 估算 30-45 h

14. **P2-P1-01** + **P2-P1-02** consent 字段 (3-4h+2-3h)
15. **P2-P1-10/11/12/15** 中文标点统一 (2-3h)
16. **P2-P1-16/17/18/19** a11y (10-12h)
17. **P2-P1-20/21/22** 国产 ROM + 人称 (2-3h)
18. **P2-P1-23/24** 版本号 / README 同步 (0.7h)
19. **P2-P1-03/04/05/06/07/08** PIPL 配套 (5-7h)

### 可以延后（P2 改善）— 估算 18-28 h

20. **P2-P2-01/02** 隐私政策收尾 (1.5h)
21. **P2-P2-03** 登录时机 (0.5h)
22. **P2-P2-04/05/06/07** i18n 翻译 (0.8h)
23. **P2-P2-08/09** 中文排版 (2-3h)
24. **P2-P2-10** native review (4-6h)
25. **P2-P2-11/12/13/14** 中国特色 + 商业 (16-22h)

### nice-to-have（P3 探索）— 估算 18-30 h

26. **P2-P3-01** 繁体中文 (6-8h)
27. **P2-P3-02** 统一"你/您" (1h)
28. **P2-P3-03** 离线模式 (3-4h)
29. **P2-P3-04** 农历生日 (8-12h)
30. **P2-P3-05** AGENTS.md 增补 (0.5h)

**总估算**：P0 26-35h + P1 30-45h + P2 18-28h + P3 18-30h = **92-138 h**

按 1 人 8h/天 ≈ **12-18 工作日**

---

## 9. 重点关注：必须 re-verify 的 5 项

1. **P2-P0-01 撤回同意 UI** — setup 第 1 步已写"可撤回"，P0-6 已声明实现。**实际不存在** = 已说谎用户。PIPL §26 明确禁止虚假告知。
2. **P2-P0-02 vent 文字加密** — 用户最隐私倾诉，但 P0-2 隐含承诺"树洞加密"没兑现。AGENTS.md 隐私边界写了"绝不进任何分析"但没说"文字本身是否加密"。
3. **P2-P0-03 developer.log** — `reminder_scheduler.dart:108` 真名泄漏到 logcat — `adb logcat | grep "ReminderService"` 任何开发环境 / 测试设备 / 厂商系统都能读。
4. **P2-P0-09 处方药通用名** — setup 第 2 步"选模板" 显示"常见：碳酸锂 / 丙戊酸钠 / 拉莫三嗪 / 阿普唑仑..." 是**广告法 §15 处方药不得广告**直接踩雷。
5. **P2-P0-08 缺清空所有数据** — 隐私政策白纸黑字写"在 App 内删除单条/全部"，但 UI 无入口 = 自我违约。PIPL §47 明确要求"主动删除"。

---

## 10. 下一步建议

### 立即（这周内）
- 修 P2-P0-04/05/06/07（4 个 1 行字面修，合计 < 3h）
- 修 P2-P0-09 模板 hint（1-2h）
- 评估 P2-P0-01 撤回同意 UI 工作量 + 排期

### 1-2 周内
- P2-P0-02 vent 文字加密（设计 + schema 升级 + migration）
- P2-P0-03 developer.log release swallow
- P2-P0-08 清空所有数据 UI

### 1 个月内
- P2-P0-10/11/12/13 隐私深度修复
- P1 全套（24 项）

### 2-3 个月
- P2 改善 + P3 探索

---

## 附录 A: 关键文件清单

| 类别 | 文件 |
|---|---|
| PIPL 法律文档 | `assets/legal/{privacy_policy.md, user_agreement.md, sensitive_data_consent.md}` |
| 同意 UI | `lib/presentation/pages/setup/setup_page.dart` (1061 行) |
| 撤回 UI 缺失 | `lib/presentation/pages/settings/settings_page.dart` (492 行) |
| vent 文字 | `lib/core/data/repositories/vent/vent_repository_impl.dart:47` |
| vent 表 | `lib/core/data/database/tables/vent/vent_entries.dart:21` |
| vent 录音加密 | `lib/core/data/services/vent_audio_storage.dart` (P0-2 已修) |
| developer.log 泄漏 | `lib/core/data/services/{reminder_scheduler, email_service, sms_service}.dart` |
| 处方药 hint | `lib/core/data/services/preset_medication_templates.dart` |
| 模板 (UI 强加 userName) | `lib/core/l10n/strings.dart:15-17` |
| 占位邮箱 | `assets/legal/{privacy_policy, user_agreement}.md` + `README.md:168` |
| SetupContactHint 过时 | `lib/l10n/{app_zh, app_en}.arb:22,36` |
| "零云端" 文案矛盾 | `lib/l10n/{app_zh, app_en}.arb:56/41` + `lib/presentation/pages/setup/setup_page.dart:791` |
| 通知自检 | `lib/presentation/pages/settings/widgets/notification_status_card.dart` |
| 版本号 | `pubspec.yaml:4` + `lib/presentation/pages/settings/settings_page.dart:218` |
| i18n | `lib/l10n/{app_zh, app_en, app_localizations_zh, app_localizations_en}.arb/.dart` |
| 紧急联系人 | `lib/presentation/pages/contact/contacts_list_widget.dart` |
| 评估 / 危机 | `lib/domain/logic/{phq9, gad7, assessment_scale}.dart` |
| CareEngine | `lib/domain/logic/care_engine.dart` |
| safety watch | `lib/core/data/services/safety_watch_service.dart` |
| EmailService mock | `lib/core/data/services/email_service.dart` |
| SmsService mock | `lib/core/data/services/sms_service.dart` |

## 附录 B: 验证清单

- [ ] `flutter analyze` — 0 error / 0 warning (P1-2 P1-3 已绿)
- [ ] `flutter test` — 528+ cases pass
- [ ] `python scripts/check_cross_feature.py` — 0 violation
- [ ] `dart scripts/check_all.dart` — 4 层架构纯度 100%
- [ ] `flutter pub outdated` — 0 重大升级
- [ ] 5 个 P0 修完后 `grep` 验证：
  - `grep -rn "developer.log.*profile.userName" lib/` → 0 hit
  - `grep -rn "Value.*text.trim" lib/core/data/repositories/vent/` → 0 hit (vent 文字已加密)
  - `grep -rn "碳酸锂\|阿普唑仑\|佐匹克隆" lib/core/data/services/preset_medication_templates.dart` → 0 hit
  - `grep -rn "example.com" assets/legal/` → 0 hit
  - `grep -rn "mom@example.com" lib/l10n/` → 0 hit
  - `grep -rn "wipeAllData\|deleteAllData\|clearAllData" lib/presentation/pages/settings/` → 1 hit (新入口)
  - `grep -rn "/settings/legal" lib/` → 1 hit (新路由)

---

**审查完成**。P2 共 **59 项发现**：P0 = 13, P1 = 24, P2 = 17, P3 = 5。
总工作量估算 **92-138 h (12-18 工作日)**。
建议：本周修 4 个 1 行字面 + 1 个 模板 hint；下月修 vent 文字加密 + 撤回同意 UI + 清空数据 UI。
