# superpowers-zh 视角审视报告 — chroniccare v0.24.0

> 视角：**i18n / 合规 / 中文 / 提交规范 / 法务**
> 项目路径：`D:\Batch\chroniccare`
> 审视时间：2026-07-26
> 审视人：sp-zh sub-agent (本任务执行者)
> 已知起点：v0.24 round 48 已完成 main.dart 4 处硬编修真 + zh_Hant 繁化 + mojibake 修真 + EmailTemplate 动态时区 + 11 守护脚本
> 扫描范围：lib/ 213 个 dart + test/ 105 + scripts/ 11 个 + docs/ 7 主文档 + l10n/ + pubspec.yaml
> 工具：grep / Select-String / git log / read + 全量 review
>
> **报告体例**：每个发现标 `文件:行`、风险等级（🟠 P1 / 🟡 P2 / 🟢 P3）、grep 复现命令。
> **不重复**：spen 报告（架构/TDD/best practice）与 emil 报告（UI/动效/视觉）已覆盖的发现**不在本报告重复**。本报告专注 i18n / 合规 / 法务。

---

## 一、顶层架构审视

### 1.1 i18n 架构评级：⭐⭐⭐ (3/5 — 中)

**现状**：
- `lib/l10n/app_zh.arb` + `app_en.arb` + `app_zh_Hant.arb`（presentation 层 flutter_localizations）共 591 / 589 / 591 顶层 key
- `lib/core/l10n/strings.dart`（domain 层 fallback）：50+ 处硬编中文
- ARB 三方一致：v0.24 round 48 P1-21 加 `check_arb_keys.py` 守护 → zh / en / zh_Hant 完全同步
- **major gap**：domain 层 strings.dart 50+ 处硬编 + presentation 层 ARB 已 591 key

**替代方案**：

| 方案 | 优势 | 劣势 | 切换 |
|---|---|---|---|
| 当前"双层 i18n" | domain 0 flutter、presentation 用 ARB | 50+ 处硬编、3 套（domain strings / ARB / text inline） | — |
| **domain 全 i18n（pass context）** | 统一 1 套 | 破坏 domain 0 flutter 原则 | ❌ |
| **domain strings 走 zh-Hant 派生** | 国内用户 0 失血 | en / 繁 / 海外华人 仍硬编 | 🟡 部分 |
| **单点 .arb + fallback** | 1 套 source | domain 0 flutter 边界破坏 | ❌ |

**顶层建议（5 条）**：
1. **`strings.dart` 走 i18n 字典注入**：`EmailTemplate.buildBody(userName, days, ..., bodyOverride, footerOverride)` 已支持 override —— 把 50+ 处 strings 同样加 override 模式，caller 传 AppLocalizations 拿
2. **量表 PHQ-9 / GAD-7 题目 + 严重度** 走 ARB：`displayName / instruction / items[i].text / options / severityCutoffs[i].label` 全部抽 AppLocalizations 量表化（v1.0+）
3. **`phone_validator.dart` PhoneRegion.displayName** 走 enum 派 StringName → AppLocalizations
4. **PDF 报告 `medication_report.toReportString()` 跟 `Strings.pdf*` 重复硬编**：用 `Strings.pdf*` 单一 source（v0.24 round 39 抽了 PDF，但 toReportString 漏抽）
5. **"zh_Hant 是 stub" 跟"zh_Hant 401 key 全部繁化"矛盾**：AGENTS.md / CHANGELOG 写的是"stub"，但 cf61948 实际是 OpenCC s2tw 完整繁化。需 sync 文档

### 1.2 合规架构评级：⭐⭐ (2/5 — 差)

**现状**：
- 精神心理患者 + 失联通知（= 向第三方 PII）+ 海外紧急联系人（= 跨境）= PIPL §17 / §23 / §28 三重合规红线
- 3 份法律文档（privacy_policy.md / user_agreement.md / sensitive_data_consent.md）v0.22 草拟，**"单独同意"未真正实施**（setup_step_consent 只勾"已告知"，不让联系人回复 Y）
- **5 厂商 push 通道 0 接**（README.md 自报"推送 = flutter_local_notifications 17"）
- **NMPA 资质 / HIPAA / GDPR 提都没提** —— DEPLOYMENT.md 选类目"医疗"但没声明"非医疗器械"
- **失联通知 mock 永远返 false**（v0.24 round 38 P0-1 修过"假成功"，但 release mode SMS provider 未接入 → production 失联通知不可用）
- **CHANGELOG 0.24.0 "Known issues" 段**还列着"5 厂商 push 通道未接 / 法务未确认 NMPA — 4 store 上架阻塞"——**v0.24.0 release 没解锁**

**替代方案**：

| 方案 | 优势 | 劣势 | 切换 |
|---|---|---|---|
| 当前"法律文档 + 草拟 + 假实现" | 0 成本 | 上 store 4 store 全挂 | — |
| **接 5 厂商 push**（小米/华为/OPPO/Vivo/魅族/FCM/APNS）| 推送能到 95%+ 用户 | 集成 + 厂商审核 6+ 月 | 🟡 v1.0 |
| **SMS provider 真实接入 AliyunSmsProvider** | 失联通知 production 可用 | 阿里云备案 + 签名 + 模板审核 2+ 月 | 🟡 v1.0 |
| **NMPA 备案"非医疗器械"声明** | 上 store 必需 | 法务 review + 申报 | 🟡 v1.0 |

**顶层建议（5 条）**：
1. **DEPLOYMENT.md 加"NMPA / 上架合规 checklist"** 章节：医疗类目声明非医疗器械 / 隐私 URL / 危机热线 / 紧急联系人同意 / 推送备案
2. **privacy_policy.md 加"跨境数据传输"段**：失联通知 = PII 传给海外联系人 = PIPL §38 / §39 需单独告知
3. **`setup_legal_dialog.dart` 联系同意实现**：v0.23 round 41 P3-31 TODO 仍挂着 — 4-8h 工时 + 等 SMS 接入
4. **3 份法律文档国际化**：英文版 / 繁中版 legal docs (PIPL 不约束海外华人但 App Store/Google Play 需要)
5. **release mode SMS provider 必接**：v0.24 round 38 P0-1 修了 mock fail-fast，但 `AliyunSmsProvider.send()` 仍 throw UnimplementedError → release 失联通知**永远抛错**

---

## 二、底层逐行排查

> **总发现数**：56 个独立问题（不含 spen 已知 19 + spen 新增 55 + emil 97）
> - i18n 硬编 30
> - i18n 一致性 6
> - 文案质量 4
> - 提交规范 5
> - 合规 / 隐私 / 法务 7
> - 时区 / 日期 2
> - CI / 脚本 1
> - 文档完整性 1

### 2.1 i18n 硬编（30 个 — 实际 50+）

**A. domain 层 `core/l10n/strings.dart`（25 处）**：

| # | 文件:行 | 硬编 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | `core/l10n/strings.dart:17` | `emailSubject: '[停药提醒] $name 已经 $days 天没吃药了'` 邮件主题中文 | 🟠 P1 英文家人看不懂 | 加 `subjectOverride` 参数（已用 buildSubject，但 emailBody/emailFooter 各自硬编） |
| 2 | `core/l10n/strings.dart:26-27` | `emailBody: '我是 $name，已经 $days 天没在 App 里打卡了。\n请你方便的时候提醒我按时吃药，避免复发。'` | 🟠 P1 | 加 `bodyOverride` |
| 3 | `core/l10n/strings.dart:30` | `emailLastMed: '最后吃药：$time'` | 🟠 P1 | 改 AppLocalizations |
| 4 | `core/l10n/strings.dart:31-32` | `emailMedInfo: '$name $dosage${unit.id}'` | 🟠 P1 药名 + 剂量中英混 | 改 |
| 5 | `core/l10n/strings.dart:33` | `emailCycle: '签到周期：$hours 小时'` | 🟠 P1 | 改 |
| 6 | `core/l10n/strings.dart:34-36` | `emailFooter: '这是一条自动通知，由慢病管家 App 发送。\n本通知不包含任何医疗建议。\n如需停止接收，请在 App 设置中修改。'` | 🟠 P1 法律声明中文 | 改 |
| 7 | `core/l10n/strings.dart:42-43` | `notifChannelMedicationName/Desc: '吃药提醒' / '到点提醒你吃药打卡'` | 🟠 P1 Android 系统设置显示 | 改 AppLocalizations 注入 |
| 8 | `core/l10n/strings.dart:44-45` | `notifChannelSafetyName/Desc` 同上 | 🟠 P1 | 改 |
| 9 | `core/l10n/strings.dart:48-49` | `notifDailyCheckInTitle/Body: '🌱 今天吃了药吗？' / '点一下 = 打卡，让家人放心'` | 🟠 P1 措辞"让家人放心"暗示监控 | 改 + 措辞调整 |
| 10 | `core/l10n/strings.dart:52-54` | `notifMedicationTitle/Body: '💊 该吃药了：$medName' / '$dosage${unit.id} · 点一下 = 打卡'` | 🟠 P1 | 改 |
| 11 | `core/l10n/strings.dart:57-59` | `notifRefillTitle/Body: '💊 该续方了：$medName' / '还剩约 $daysLeft 天断药，记得去医院或线上开药'` | 🟠 P1 | 改 |
| 12 | `core/l10n/strings.dart:62-64` | `notifAssessmentTitle/Body: '🌿 心理评估时间到' / '已经 $days 天没做 $scaleIdUppercase 了，请花 2 分钟做一下评估'` | 🟠 P1 | 改 |
| 13 | `core/l10n/strings.dart:71-72` | `pdfTitle: '慢病管家 · 用药报告' / pdfAuthor: '慢病管家'` | 🟠 P1 PDF metadata | 改 |
| 14 | `core/l10n/strings.dart:73-74` | `pdfSubject/pdfRecentDays` | 🟠 P1 | 改 |
| 15 | `core/l10n/strings.dart:80-82` | `pdfSectionRoutineMeds/TempMeds/Summary` | 🟠 P1 | 改 |
| 16 | `core/l10n/strings.dart:85-91` | `pdfLabelPatient/ReportPeriod/GeneratedAt/Unset/NoValue` 7 处 | 🟠 P1 | 改 |
| 17 | `core/l10n/strings.dart:94-106` | `pdfLabelStart/MedicationStats/Missed/NoMissed/UnsetTime/pdfDailyNTimes/pdfMedicationStatsValue` 7 处 | 🟠 P1 | 改 |
| 18 | `core/l10n/strings.dart:109-120` | `pdfColumnDate/Time/Med/Note/pdfOnTime/Missed/Extra/TempN/AdherencePct` 9 处 | 🟠 P1 | 改 |
| 19 | `core/l10n/strings.dart:126-131` | `importSummaryContact/Medication/CheckIn/Report/Mood/Vent` 6 处 | 🟡 P2 (UI 显示) | 改 |
| 20 | `core/l10n/strings.dart:135-141` | `moodLabel: 1=>'很差', 2=>'差', 3=>'一般', 4=>'好', 5=>'很好'` | 🟠 P1 情绪日记核心标签 | 改 AppLocalizations.moodLabelN（已定义但未引用） |
| 21 | `core/l10n/strings.dart:145-146` | `snoozeTitle/Body: '💊 提醒吃药（snooze）' / '刚才您点了"稍后提醒"，该吃药了'` | 🟠 P1 | 改 |

**B. domain 层量表（10 处）**：

| # | 文件:行 | 硬编 | 风险 | 修复 |
|---|---|---|---|---|
| 22 | `domain/logic/phq9.dart:19-23` | `phq9Options: {0: '完全不会', 1: '好几天', 2: '一半以上的天数', 3: '几乎每天'}` 4 档选项 | 🟠 P1 评估题 9 道 + 选项英文用户**看不懂** | 抽 `Map<int, AppLocalizedString>` |
| 23 | `domain/logic/phq9.dart:80-88` | 9 道题中文硬编（"做事时提不起劲或没有兴趣" / "有不如死掉或用某种方式伤害自己的念头"） | 🟠 P1 9 道题 | 抽 `List<AssessmentItem>` 走 ARB |
| 24 | `domain/logic/phq9.dart:99-103` | 5 档严重度标签（"几乎没有抑郁" / "轻度抑郁" / "中度抑郁" / "中重度抑郁" / "重度抑郁"）+ summary 5 档 | 🟠 P1 | 抽 SeverityCutoff.label/summary 走 ARB |
| 25 | `domain/logic/phq9.dart:126-127` | `'(label: '全国24小时心理援助热线', number: '400-161-9995')' / '(label: '北京心理危机研究与干预中心', number: '010-82951332')'` | 🟠 P1 **医疗法律红线**：海外华人打 400-161-9995 不可达 / 跨境紧急电话 PII 风险 | 加 region 字段 + locale 路由 |
| 26 | `domain/logic/gad7.dart:10-16` | 7 道题 + `gad7Items` 7 题目中文 | 🟠 P1 | 同 phq9 |
| 27 | `domain/logic/gad7.dart:22-26` | 4 档选项（"完全不会"等） | 🟠 P1 | 同 phq9 |
| 28 | `domain/logic/gad7.dart:60-63` | 4 档严重度标签 | 🟠 P1 | 同 phq9 |
| 29 | `domain/logic/care_copy.dart:29-46` | 4 个关怀文案中文（"🛏️ 记得早点休息" / "☀️ 周末也要记得" / "🌿 你还好吗？" / "🌟 一整周都准时！" + body 4 段） | 🟠 P1 关怀通知是核心 UX | 走 AppLocalizations |
| 30 | `domain/logic/medication_report.dart:252-339` | `toReportString()` 30+ 处中文硬编（"═══════════════════" / "慢病管家 · 用药报告" / "患者: ..." / "报告周期: ..." / "生成时间: ..." / "—— 暂无用药数据 ——" / "本报告由「慢病管家」App 自动生成" / "本应用不提供医疗建议，仅供医生参考" / "━━━ 常吃药方案 ━━━" / "未设置时间" / "每日 N 次（...）" / "起始: ..." / "N 天内实际服药: ..." / "⚠️ 漏服: ..." / "✓ 无漏服" / "━━━ 临时用药 ━━━" / "共 N 次" / "━━━ 总览 ━━━" / "按时服药: N 次" / "漏服: N 次" / "补服: N 次（漏服后补救或加量）" / "临时用药: N 次" / "依从率: N%"） | 🟠 P1 **跟 strings.dart 重复硬编**（PDF 走 Strings.pdfXxx / text report 走 inline） | 用 Strings.pdfXxx 单一 source |

**C. data / service 层（5 处）**：

| # | 文件:行 | 硬编 | 风险 | 修复 |
|---|---|---|---|---|
| 31 | `core/data/database/connection/web.dart:25-27` | `UnsupportedError('Web 平台暂不支持，精神心理患者 PII 不能落明文 IndexedDB。\n请用 Android / iOS 客户端获得完整加密保护。\n详细原因见 docs/P2_SYSTEM_REVIEW.md P0-7。')` 错误信息中英混杂 | 🟡 P2 (dev 模式) | AppLocalizations + path 不写死 |
| 32 | `core/data/services/safety_watch_service.dart:311-312` | `_buildAlertSms: '[慢病管家] $name 已 $daysSinceLast 天未打卡吃药。\n如确认安全请回复 1，无回复请联系本人或社区。'` SMS 模板中文 | 🟠 P1 紧急 SMS 给海外华人 = 中文看不懂 | 走 AppLocalizations + 海外区号分流 |
| 33 | `core/data/services/safety_watch_service.dart:386-405` | `displayMessage` 8 种状态中文（'安全开关已关闭' / '正常（N 天前打卡）' / '新用户，暂无打卡' / '今天已经发过告警（N 天前打卡）' / 'DND 时段，跳过告警' / '无紧急联系人，未发送' / '已告警：N 天前打卡，已通知 N 位联系人（N 失败）' / '错误：...'） | 🟠 P1 安全开关显示核心 UI | 走 AppLocalizations |
| 34 | `core/data/services/notification_service.dart:354` | `'从未打卡'` 通知 body fallback | 🟠 P1 | 改 |
| 35 | `core/data/services/notification_service.dart:361-362` | `'⚠️ $name 已 $daysWithoutCheckIn 天未打卡' / '上次打卡: $lastStr。已自动通知紧急联系人，请确认安全。'` 通知 title/body 中文 | 🟠 P1 失联通知核心 | 改 |
| 36 | `core/data/utils/phone_validator.dart:158-170` | `PhoneRegion.displayName: '中国大陆' / '中国香港' / '中国澳门' / '中国台湾' / '国际'` 5 个 region 名 | 🟠 P1 联系人 region 显示 | 走 AppLocalizations |
| 37 | `core/data/services/preset_medication_templates.dart:63-154` | 4 个预置方案 30+ 处中文（"单药 · SSRI 早一次" / "SSRI 类抗抑郁药" / "1 种药，每天早 8 点服用（适用 SSRI / SNRI 类）" / "常见 SSRI / SNRI 类抗抑郁药（具体药名以医生处方为准）" 等） | 🟠 P1 首次设置核心 UI（虽然 P0-3/5 修了《广告法》风险，但仍是中文） | 走 AppLocalizations |
| 38 | `core/data/services/snooze_manager.dart:80-82` | `AndroidNotificationDetails('chroniccare.medication', '吃药提醒', channelDescription: '到点提醒你吃药打卡', ...)` 通知 channel name/desc 中文 | 🟠 P1 跟 strings.dart 重复 | 用 Strings.notifChannelMedicationName/Desc |
| 39 | `core/data/services/reminder_scheduler.dart:220-230` | `_buildSmsBody: '【慢病管家】$name 已 $daysSince 没打卡。' / '请你方便的时候提醒 TA 按时吃药。' / '常吃药: ${medication.name} ${medication.dosage}${medication.dosageUnit.id}' / '—— 这是一条自动提醒，请勿回复'` SMS 4 行中文 | 🟠 P1 跟 safety_watch_service 的 _buildAlertSms 重复硬编 | 抽 `SmsTemplates.buildLostContact()` 统一 |
| 40 | `core/data/services/medication_notifier.dart:91, 113, 142-150` | piiSafeLog 中文 4 处（'✅ 设置每日 $hour:$minute 提醒' / '❌ 设置提醒失败: $e' / '✅ medication reminders 全部 cancel + 重新调度' / '❌ 推送调度失败 med=${med.name} t=$t: $e' / '✅ 重新调度 $scheduled 个 medication 推送'） | 🟠 P1 PII 泄漏（med.name 在 log） | piiSafeLog 已 mask name，但 log 内容中文海外 dev 查不到 |
| 41 | `core/data/services/refill_notifier.dart:114, 127, 138, 165, 204` | piiSafeLog 中文 5 处（'⏭️ scheduleRefillReminder: med=${medication.name} 无 refillAt, 跳过' / 'fireAt=$fireAt 已过, 跳过' / '⚠️ cancelRefillReminder 失败 (med=${medication.name}): $e' / '✅ 续方提醒: med=${medication.name} ...' / '❌ 续方提醒调度失败: $e' / '✅ 重排 $scheduled 个 medication 的续方提醒'） | 🟠 P1 PII 泄漏 | 同上 |
| 42 | `domain/entities/check_in_entity.dart:53-60` | `CheckInType.label: '每日打卡' / '临时吃药' / 'PHQ-9 评估' / 'GAD-7 评估'` 4 个 type 标签 | 🟠 P1 (day_detail 用) | 改 AppLocalizations |
| 43 | `domain/entities/vent_entry_entity.dart:62-65` | `durationLabel: '$sec秒' / '$m分' / '$m分${s.toString().padLeft(2, '0')}秒'` 时长格式中文 | 🟠 P1 (树洞核心) | 改 |
| 44 | `domain/entities/vent_entry_entity.dart:112` | `toString: 'VentEntryEntity(id=$id, ts=$timestamp, text=${contentText?.length ?? 0}字, audio=${audioPath != null})'` 调试 toString 中文 "字" | 🟢 P3 (dev 调试) | 改 |
| 45 | `domain/logic/assessment_comparison.dart:69-99` | 4 个 trend label 中文（'好转' / '恶化' / '持平' / '首次评估'）+ delta label 3 处 | 🟠 P1 (评估历史核心 UI) | 改 |
| 46 | `domain/logic/assessment_comparison.dart:172` | `'等级 $rank'` fallback 标签中文 | 🟠 P1 | 改 |
| 47 | `domain/logic/day_detail.dart:166, 178, 244-246` | `'打卡 · ${med.name}' / '每日打卡' / '临时 · ${parsed.name}' / '临时吃药' / 'PHQ-9 抑郁筛查' / 'GAD-7 焦虑筛查'` 5+ 处 | 🟠 P1 (趋势日详情核心) | 改 |
| 48 | `presentation/pages/setup/setup_step_medication.dart:222-235` | `DropdownMenuItem(value: DosageUnit.mg.id, child: const Text('mg'))` DosageUnit display 硬编 | 🟠 P1 (虽然 mg 是国际单位，但元数据没走 l10n) | 改 |

**总硬编数 48 处**（实际可能更多，没算注释里的）。其中 🟠 P1 (PIPL / 紧急通知 / 量表题目) 占 35+。

### 2.2 i18n 一致性（6 个）

| # | 文件:行 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | `lib/l10n/app_zh.arb` vs `app_en.arb` 顶层 key | 591 / 589 一致（多 2 个是 metadata 差异），**check_arb_keys.py 守护 OK** | 🟢 通过 | — |
| 2 | `app_zh_Hant.arb` 跟 zh 一致性 | 591/591 一致（v0.24 round 45 OpenCC s2tw 全部繁化） | 🟢 通过 | — |
| 3 | `lib/l10n/app_zh.arb` **39 个孤儿 key 未引用**（grep 验证） | 见下表 | 🟠 P1 维护负担 + Flutter gen-l10n 生成 dead code | 加 `check_orphan_arb_keys.py` 守门员 |
| 4 | `app_zh.arb` 跟 `app_en.arb` 命名风格不一致 | `setupContactName` (zh) vs `setupContactNameLabel` (en) | 🟢 命名是 metadata，影响极小 | OK |
| 5 | `app_zh_Hant` 文档状态 | AGENTS.md 写"zh_Hant stub"，但 `cf61948` 实际是 OpenCC s2tw 完整繁化 401 key | 🟡 P2 文档不一致 | 改 AGENTS.md |
| 6 | `app_localizations_zh.dart` 注释里 写 `line 21 "您→你" 之外全部繁化`（grep CHANGELOG 命中） | 没实际验证，可能漏繁 | 🟡 P2 | 跑 `flutter gen-l10n` + 跑 `diff_arb` |

**39 个孤儿 key 完整列表**（grep 验证）：

```
appTagline, commonAutoCheckinFailed, commonCheckinFailed, commonConfirm,
commonDeleteWarning, commonDone, commonEmpty, commonError, commonTakePhoto,
homeSnoozeFailed, legalPageResetConsent, listSwipeDeleteHint,
medReportGenPdfAction, moodAudioDeleteRecording, moodAudioDurationTemplate,
moodAudioRecording, moodAudioTranscriptEmpty, moodLabel1, moodLabel2,
moodLabel3, moodLabel4, moodLabel5,
notifChannelMedicationDescI18n, notifChannelMedicationNameI18n,
notifDailyCheckInBodyI18n, notifDailyCheckInTitleI18n,
settingsClearAllDataFailed, settingsExport, setupContactHint,
setupMedFrequency, setupMedName, setupMedSchedule, setupMedTimes1,
setupMedTimes2, setupMedTimes3, setupSaveFailed,
ventDurationMinutes, ventDurationMinutesSeconds, ventDurationSeconds
```

**复现命令**：
```bash
# 已写好的脚本: scripts/check_arb_keys.py 验证 zh/en/zh_Hant 同步
# 新增: 验证 ARB key 都被代码引用
python -c "
import re, pathlib
arb = pathlib.Path('lib/l10n/app_zh.arb').read_text(encoding='utf-8')
keys = set(re.findall(r'\"([a-zA-Z][a-zA-Z0-9_]*)\"\s*:\s*\"', arb)) - {'@@locale'}
unused = []
for k in keys:
    pat = re.compile(r'\.' + re.escape(k) + r'\b')
    if not any(pat.search(p.read_text(encoding='utf-8')) for p in pathlib.Path('lib').rglob('*.dart') if 'app_localizations' not in str(p)):
        unused.append(k)
print(f'未引用 key: {len(unused)}')
print('\n'.join(unused))
"
```

### 2.3 文案质量 / microcopy（4 个）

| # | 文件:行 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | `core/l10n/strings.dart:48-49` | `notifDailyCheckInBody: '点一下 = 打卡，让家人放心'` 措辞"让家人放心"暗示家人监控 | 🟠 P1 精神心理敏感 — 用户看到"家人监控"可能焦虑 | 改"让 TA 安心"或"保持健康" |
| 2 | `core/data/services/reminder_scheduler.dart:223` | `'请你方便的时候提醒 TA 按时吃药。'` "TA" 是 95 后网络用语，**不适用于中老年用户**（精神心理患者含中年/老年抑郁） | 🟡 P2 跨代际沟通 | 改"他/她"或"用户" |
| 3 | `domain/logic/care_copy.dart:39-46` | `weekPerfect: '🌟 一整周都准时！/ 你真棒——保持下去'` "你真棒"太口语化 | 🟡 P2 精神心理患者可能觉得居高临下 | 改"做得很好"或"这周你很自律" |
| 4 | `core/l10n/strings.dart:57-59` | `notifRefillBody: '还剩约 $daysLeft 天断药，记得去医院或线上开药'` "断药"措辞不准确（"快没药"是"快断"，"已经 0 颗"才是"断"） | 🟢 P3 语义模糊 | 改"还剩 N 天" |

### 2.4 提交规范 / commit / CHANGELOG（5 个）

| # | 范围 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | 最近 240 commit | **早期 v0.17 round 14 commit 风格不统一**：早期 v0.17 用 `Bug-5` / `P3-1` / `P1-7` trac 编号（如 `3781ed1 v0.17 round 14: Bug-4 wrap fire-and-forget futures in unawaited()`），v0.22+ 改 `<type>(<scope>)` 风格（如 `f1827c4 v0.24 round 48: fix(P0) 5 项 P0 全清`） | 🟡 P2 git log 混双轨 | 加 git commit-msg hook 验证（v0.17 风格已冻结可加 whitelist） |
| 2 | `docs/CHANGELOG.md` | **CHANGELOG "Known issues (v0.25 必修 — 三视角审视发现)" 段没刷新为 v0.24 round 48 实际修复状态**。例如：<br/>"CHANGELOG 顺序乱" → 已修<br/>"pubspec 0.23.0+1 没 bump" → 已修<br/>"EmailTemplate._formatDateTime 硬编码 UTC+8" → 已修<br/>"crossedMidnightSince 无 direct test" → 已修（a8b9562 加了）<br/>"vent_compose._togglePlay 暂停路径" → 已修（c3e68e1） | 🟠 P1 CHANGELOG 严重过时 — release 文档应反映当前状态 | v0.24.1 段重写 + 把 v0.24.0 "Known issues" 移到 "Fixed in v0.24 round 48" |
| 3 | `docs/CHANGELOG.md` v0.24.0 段 | 段内 section 层级混用：`### Added` / `### Fixed` / `### CI` / `### Tests` / `### Architecture` / `### Known issues` —— "Tests" 和 "Architecture" 不符合 Keep a Changelog 标准（应该是 `### Changed` 或 `### Technical`） | 🟡 P2 CHANGELOG 格式 | 改 `Tests → ## [0.24.0] - 2026-07-26` 跟其他段一致 |
| 4 | `README.md:131` | "876 cases" 跟实际 `flutter test` 跑出 **1052 cases** 不一致（spen 报告里写了 1052，但 README 没刷新） | 🟡 P2 文档 outdated | 改 1052 |
| 5 | `AGENTS.md` 跟 `CHANGELOG.md` 数字一致性 | AGENTS.md 写"910+ tests"（v0.24 round 48 后） + CHANGELOG 写"876 cases"（README v0.22 历史）+ README 写"876 cases"—— **3 处数字打架** | 🟡 P2 | 全部刷成 1052 |

**commit 格式审计**（v0.17 早期 vs v0.22+）：
```bash
git -C D:\Batch\chroniccare log --oneline -300 | Select-String -Pattern "v0\.17 round 14"
# 输出：Bug-N / P0-N / P1-N / P2-N / P3-N 风格（无 <type>）
git -C D:\Batch\chroniccare log --oneline -50
# 输出：v0.24 round 48: <type>(<scope>) <title> 风格
```

**CHANGELOG 段顺序**（验证 `check_changelog.py`）：
```bash
python scripts/check_changelog.py
# 输出: [OK] check_changelog: pubspec=[0.24.0+1] CHANGELOG 顺序正确 (19 段)
```
顺序 OK，但**段标题层级不一致**（混合 Added/Fixed/CI/Tests/Architecture/Known issues）。

### 2.5 合规 / 隐私 / 法务（7 个）

| # | 文件:行 | 问题 | 风险等级 | 修复 |
|---|---|---|---|---|
| 1 | `lib/presentation/pages/setup/setup_legal_dialog.dart:5-24` | **PIPL §13 单独同意未实现**。注释 v0.23 round 41 P3-31 TODO 挂着：当前 setup 流程只勾"我已告知上述联系人"，**联系人本人没法律地位**。严格 PIPL §13/§23 需让联系人回复"Y"才合规 | 🟠 P1 PIPL 合规红线 — 4 store 上架必备 | 加 contact 表 `consentConfirmedAt` 字段 + setup 阶段发短信确认 + 30 天未确认提醒 |
| 2 | `assets/legal/privacy_policy.md` | **缺"跨境数据传输"段**。失联通知 SMS/email 发给海外紧急联系人 = 把 PII（姓名 + 打卡数据）传出中国 = PIPL §38 / §39 需单独告知 | 🟠 P1 PIPL 合规 | 加"§10 跨境数据传输"段 |
| 3 | `docs/DEPLOYMENT.md` 全部 | **0 处提 NMPA / HIPAA / GDPR / 5 厂商 push / 7 大 store 上架清单**。只在阶段 5 / 阶段 6 简略提 Google Play + App Store。**国内 5 大应用市场**（华为 / 小米 / OPPO / Vivo / 腾讯）**+ 5 厂商 push 通道**（小米推送 / 华为 PUSH / OPPO PUSH / Vivo PUSH / 魅族 PUSH）**0 提及** | 🟠 P1 上 store 阻塞 | 加"阶段 8: 国内 store + 5 厂商 push" 段 |
| 4 | `docs/DEPLOYMENT.md:184` | "内容审核：声明'非医疗器械'" 出现但**没具体模板** —— 实际 App Store 审核需要正式"非医疗器械声明" PDF，Google Play 需要在 Data Safety 声明医疗数据类型 | 🟠 P1 上 store 阻塞 | 加 NMPA "非医疗器械" 声明模板（中文 + 英文） |
| 5 | `core/data/services/sms_service.dart:133-135` | `AliyunSmsProvider.send() throw UnimplementedError(...)` — release 模式下 SMS 永远抛错，**失联通知 production 不可用**。v0.24 round 38 P0-1 修了"假成功"，但真接 SMS 仍 TODO | 🟠 P1 上 store 阻塞 | v1.0 接阿里云 SMS SDK（v0.22 round 32 sp-zh P0 跟踪）|
| 6 | `core/data/services/email_service.dart:55-67` | mock 模式 `return false`（spen 已记）。`_useMock = true` 永远 false → safety_watch_service 把 mock fail 算 `contactsFailed` → 联系人 UI 显示"已通知 0 位（X 失败）"—— 实际根本没发 | 🟠 P1 数据完整性（与 spen 重合） | 改 `SmsResult.mock` 独立 kind |
| 7 | `domain/logic/phq9.dart:126-127` | **`'全国24小时心理援助热线 400-161-9995'` / `'北京心理危机研究与干预中心 010-82951332'`** —— 海外华人打 400-161-9995 不可达。**精神心理紧急电话 = 医疗法律红线**：海外用户做评估后看到中文电话 = 不能用 = 危机事件责任 | 🟠 P1 医疗法律风险 | 加 `region` 字段 + locale 路由（北美 Lifeline 988 / 香港撒玛利亚 2389 2222 / 台湾生命线 1995） |

### 2.6 时区 / 日期（2 个）

| # | 文件:行 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | `lib/main.dart:90` | `tz.setLocalLocation(tz.getLocation('Asia/Shanghai'))` 硬编码 | 🟠 P1 海外用户 tz 错位（spen 已记 #6） | 删除硬编码，依赖 notification_service.init 覆盖 |
| 2 | `lib/core/shared/formatters.dart:7-23` | `date/monthDay/time/dateTime/dateCompact` 全部用 `DateTime.year/month/day/hour/minute` 拼字符串，**不走 intl**。英文用户看 `2026-07-26` 而不是 `Jul 26, 2026` 或 `26 Jul 2026` | 🟠 P1 i18n 完整度 | 改 `intl` 包 `DateFormat.yMMMd('en_US')` |

**DateTime.now().toIso8601String() 无 Z 后缀**（注释提及）：
- `core/data/services/data_export_service.dart:50` 注释说"之前用 `DateTime.now().toIso8601String()` 输出无时区"已修
- `data_export_service.dart:43-47` 实际 `_isoUtc = d.toUtc().toIso8601String()` ✅ 已修

### 2.7 CI / 脚本（1 个）

| # | 文件 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | 11 个守护脚本 | **缺"ARB key 引用"守门员**：check_arb_keys.py 只查 .arb 同步，**不查"已写 key 但代码未引用"**。39 个孤儿 key（见 2.2 #3）就是漏网之鱼 | 🟡 P2 维护负担 + 生成 dead code | 加 `check_orphan_arb_keys.py` |

**11 个守护脚本覆盖**（grep 验证）：
```
scripts/
├── check_all.dart               # 4 层架构 purity + consistency (v0.16 R13)
├── check_arb_keys.py            # ARB zh/en/zh_Hant 同步 (v0.22 R30 + v0.24 R48 P1-21)
├── check_changelog.py           # CHANGELOG 顺序 + pubspec 一致 (v0.24 R45)
├── check_cross_feature.py       # presentation 跨 feature import (v0.17 R12)
├── check_datetime_race.py       # DateTime.now() 多次调用 (v0.16 R19)
├── check_datetime_race2.py      # DateTime 多参 race (v0.17 R14)
├── check_drift_namespace.py     # drift namespace 冲突 (v0.17 R14)
├── check_fullwidth_punctuation.py # 全角标点 (v0.22 R30)
├── check_no_hardcoded_utc.py    # UTC 硬编码 (v0.24 R48 P0-4)
├── check_no_pua.py              # Unicode PUA 字符 (v0.24 R45)
├── check_widget_dispose.py      # Widget 资源泄漏 (v0.22 R30)
```

11 个脚本都很专业，**唯一 gap**：ARB 孤儿 key 检测。

### 2.8 文档完整性（1 个）

| # | 范围 | 问题 | 风险 | 修复 |
|---|---|---|---|---|
| 1 | `docs/CHANGELOG.md` v0.24.0 段 | **Known issues 段过期**（见 2.4 #2） | 🟠 P1 | 移到"Fixed in v0.24 round 48" |

**DEPLOYMENT.md 缺**（合并到 2.5 #3）：
- NMPA 资质 / HIPAA / GDPR
- 5 厂商 push 通道
- 7 大 store 上架清单（Google Play / App Store / 华为 / 小米 / OPPO / Vivo / 腾讯）
- "非医疗器械" 正式声明 PDF 模板
- PIPL 跨境数据传输合规

**README.md 缺**（合并到 2.4 #4）：1052 tests + 5 厂商 push / 3 大法律文档 URL

**AGENTS.md 数字打架**（2.4 #5）：910+ vs 1052 + 3 文档同步

---

## 三、Top 10 优先级清单

按（合规风险 / 用户感知 / 修复成本）排序：

| # | 标题 | 风险 | 成本 | 关键路径 |
|---|---|---|---|---|
| 1 | **PIPL §13 单独同意未实现（联系人回复 Y）** | 🟠 P1 4 store 上架阻塞 + 法律责任 | 4-8h（等 SMS 接入后） | `presentation/pages/setup/setup_legal_dialog.dart:5-24` + `core/data/database/app_database.dart` 加 `consentConfirmedAt` 字段 |
| 2 | **量表 PHQ-9 / GAD-7 题目 + 严重度标签全部硬编中文** | 🟠 P1 评估核心 + 海外华人危机电话不可达 | 1 round | `domain/logic/phq9.dart:19-103` + `domain/logic/gad7.dart:10-63` |
| 3 | **CHANGELOG 0.24.0 "Known issues" 段过期** | 🟠 P1 release 文档错乱 | 0.5h | `docs/CHANGELOG.md` v0.24.0 段 |
| 4 | **domain 层 strings.dart 50+ 处硬编 + 跟 PDF toReportString 重复** | 🟠 P1 紧急通知 / SMS / 邮件全错 | 1 round（加 override 模式） | `core/l10n/strings.dart` 全部 + `domain/logic/medication_report.dart:252-339` |
| 5 | **5 厂商 push 通道 0 接** | 🟠 P1 推送送达率 < 70%（国产 ROM 静默杀） | 1-2 round（厂商审核 6+ 月） | DEPLOYMENT.md 改 + pubspec 加依赖 + AndroidManifest 改 |
| 6 | **AliyunSmsProvider.send() 永远 throw UnimplementedError** | 🟠 P1 release 失联通知 production 不可用 | 0.5-1 round | `core/data/services/sms_service.dart:133-135` |
| 7 | **NMPA / Data Safety / "非医疗器械" 声明模板缺** | 🟠 P1 4 store 上架阻塞 | 1-2 round（法务 review） | `docs/DEPLOYMENT.md` 阶段 5 / 阶段 6 扩 + 3 份法律文档加 |
| 8 | **39 个孤儿 ARB key + 缺守护脚本** | 🟡 P2 维护负担 | 0.5h | 新建 `scripts/check_orphan_arb_keys.py` |
| 9 | **medication_report.toReportString() 重复硬编** | 🟠 P1 PDF + text 双份中文 | 0.5h 抽 Strings.pdfXxx | `domain/logic/medication_report.dart:252-339` |
| 10 | **3 处文档数字打架（910/1052/876）** | 🟡 P2 release 文档一致性 | 0.1h 改 README + AGENTS + CHANGELOG | `README.md:131` + AGENTS.md + CHANGELOG.md |

---

## 四、发现的真实 Bug + 监管风险

按"实际能复现"和"优先级"排序：

### Bug 1: medication_report.dart toReportString() 跟 strings.dart 重复硬编
- **文件**：`lib/domain/logic/medication_report.dart:252-339` + `lib/core/l10n/strings.dart:71-120`
- **现象**：PDF 报告（`medication_report_pdf.dart`）走 `Strings.pdfXxx` 集中器，但 text 报告（`toReportString()`）inline 写同样内容
- **复现命令**：
  ```bash
  # 找 toReportString 里的"慢病管家"
  grep -n "慢病管家" lib/domain/logic/medication_report.dart
  # 找 Strings.pdfXxx
  grep -n "pdfTitle\|pdfAuthor\|pdfSectionRoutineMeds" lib/core/l10n/strings.dart
  ```
- **影响**：海外医生看 text report 看到"慢病管家 · 用药报告"中文
- **修复**：用 `Strings.pdfXxx` 单一 source；`toReportString()` 接受 `Strings` 注入

### Bug 2: 量表 9 道题 + 严重度全部硬编中文
- **文件**：`lib/domain/logic/phq9.dart:19-103` + `lib/domain/logic/gad7.dart:10-63`
- **现象**：所有 9 + 7 = 16 道评估题 / 5 + 4 = 9 档严重度 / 2 个危机电话全部中文硬编
- **复现命令**：
  ```bash
  grep -n "做事时提不起劲\|有不如死掉" lib/domain/logic/phq9.dart
  grep -n "400-161-9995\|010-82951332" lib/domain/logic/phq9.dart
  ```
- **影响**：英文用户 / 港澳台用户 / 海外华人做评估时看到"做事时提不起劲或没有兴趣"是中文 → **不会用**。第 9 题"有不如死掉或用某种方式伤害自己的念头"是自杀检测，危机电话是 400-161-9995（中国），**海外华人打不通** = **医疗法律风险**
- **修复**：抽 `List<AssessmentItem>` 走 ARB + 加 `region` 路由（北美 988 / 香港 2389 2222 / 台湾 1995 / 新加坡 1800-221-4444）

### Bug 3: CHANGELOG v0.24.0 "Known issues" 段过期
- **文件**：`docs/CHANGELOG.md` v0.24.0 段 "Known issues (v0.25 必修 — 三视角审视发现)" 子段
- **现象**：列了 8 项"v0.25 必修"问题，但 v0.24 round 48 P0 已修 5 项（CHANGELOG 顺序、pubspec、EmailTemplate UTC、crossedMidnight test、vent_compose stop）
- **复现命令**：
  ```bash
  grep -n "Known issues" docs/CHANGELOG.md
  # 输出 3 段（v0.24.0 / v0.23.0 / v0.22.1），v0.24.0 的"已知"实际已修
  ```
- **影响**：开发者看 CHANGELOG 以为"v0.24 release 时这些问题还没修"，跟 commit log 不一致
- **修复**：把"已修"标 ✅，未修的标 ❌ 留给 v0.25；或重写为 "Round 48 fixed: ..."

### Bug 4: phone_validator.dart PhoneRegion.displayName 5 处硬编
- **文件**：`lib/core/data/utils/phone_validator.dart:158-170`
- **现象**：5 个 region 名称硬编中文（'中国大陆' / '中国香港' / '中国澳门' / '中国台湾' / '国际'）
- **复现命令**：
  ```bash
  grep -n "中国大陆\|中国香港\|国际" lib/core/data/utils/phone_validator.dart
  ```
- **影响**：英文用户在 setup 联系人时看到 "+86 中国大陆" 不知道是啥
- **修复**：抽 `RegionDisplayName` 走 AppLocalizations 注入

### Bug 5: setup_legal_dialog.dart PIPL §13 单独同意未实现
- **文件**：`lib/presentation/pages/setup/setup_legal_dialog.dart:5-24` 注释明确写"v0.23 round 41 (spzh P3-31 TODO) 联系同意未实现"
- **现象**：setup 流程只勾"我已告知上述联系人"，**联系人本人没法律地位**。严格 PIPL §13/§23 需让联系人回复 Y 才合规
- **复现命令**：
  ```bash
  grep -n "P3-31\|PIPL §13\|单独同意" lib/presentation/pages/setup/setup_legal_dialog.dart
  ```
- **影响**：4 store 上架审核会被打回（隐私政策自相矛盾） + 法务风险
- **修复**：contact 表加 `consentConfirmedAt` 字段 + setup 阶段发短信确认 + 30 天未确认提醒

### Bug 6: PHQ-9 第 9 题危机电话硬编中国
- **文件**：`lib/domain/logic/phq9.dart:126-127`
- **现象**：`'(label: '全国24小时心理援助热线', number: '400-161-9995')' / '(label: '北京心理危机研究与干预中心', number: '010-82951332')'`
- **复现命令**：
  ```bash
  grep -n "400-161-9995\|010-82951332" lib/domain/logic/phq9.dart
  ```
- **影响**：海外华人做评估时如果第 9 题阳性 → 弹危机资源 → 显示中国电话 → **打不通 = 用户自杀而 App 显示的"救命"电话没用 = 法律责任**
- **修复**：加 region 路由（北美 988 / 香港 2389 2222 / 台湾 1995 / 新加坡 1800-221-4444）

### Bug 7: 39 个孤儿 ARB key
- **文件**：`lib/l10n/app_zh.arb` 591 key 中 39 个未引用
- **现象**：例如 `notifChannelMedicationNameI18n` 定义但代码用 `Strings.notifChannelMedicationName`（domain） / `moodLabel1..5` 定义但代码用 `Strings.moodLabel(int)` / `ventDurationSeconds` 定义但代码用 `'$sec秒'`（domain/entities/vent_entry_entity.dart:62）
- **复现命令**（见 2.2 #3 详细脚本）
- **影响**：维护负担（app 体积微增） + Flutter gen-l10n 生成 dead code（不致命但浪费）
- **修复**：删孤儿 key + 加 `check_orphan_arb_keys.py` 守门员

### Bug 8: formatters.dart 不走 intl
- **文件**：`lib/core/shared/formatters.dart:7-23`
- **现象**：`date/monthDay/time/dateTime/dateCompact` 5 个方法全部用 `DateTime.year/month/day/hour/minute` 拼字符串
- **复现命令**：
  ```bash
  grep -n "d.year\|d.month\|d.day\|d.hour\|d.minute" lib/core/shared/formatters.dart
  ```
- **影响**：英文用户看 `2026-07-26 14:08` 而不是 `Jul 26, 2026 2:08 PM`；月/日分隔符 `-` / `:` 在不同 locale 应该不同
- **修复**：用 `intl` 包 `DateFormat.yMMMd('en_US').format(d)` + `DateFormat.Hm('en_US')`

### Bug 9: setup_step_medication.dart DropdownMenuItem 硬编 'mg'
- **文件**：`lib/presentation/pages/setup/setup_step_medication.dart:222-235`
- **现象**：`DropdownMenuItem(value: DosageUnit.mg.id, child: const Text('mg'))` —— 药名"mg"是国际单位没翻译（OK），但整段 DropdownMenuItem 没走 l10n 模式
- **复现命令**：
  ```bash
  grep -n "DropdownMenuItem\|Text('mg')\|Text(l10n" lib/presentation/pages/setup/setup_step_medication.dart
  ```
- **影响**：一致性问题（其他 dosage unit 走 l10n，'mg' 不走）
- **修复**：加 `l10n.commonDosageUnitMg` key（en: "mg" / zh: "毫克"），跟 `commonDoseUnit` 一致

### Bug 10: web.dart 错误信息中英混杂
- **文件**：`lib/core/data/database/connection/web.dart:25-27`
- **现象**：`'Web 平台暂不支持，精神心理患者 PII 不能落明文 IndexedDB。\n请用 Android / iOS 客户端获得完整加密保护。\n详细原因见 docs/P2_SYSTEM_REVIEW.md P0-7。'`
- **复现命令**：
  ```bash
  grep -n "精神心理患者 PII\|Web 平台暂不支持" lib/core/data/database/connection/web.dart
  ```
- **影响**：英文用户 dev 模式跑 web 端看到中文错误
- **修复**：抽 `webErrorMessage` 走 AppLocalizations + 路径不写死（用 `package:chroniccare/...` 引用）

### Bug 11: 紧急联系人口头"已告知" ≠ 法律"单独同意"
- **文件**：`lib/presentation/pages/setup/setup_step_consent.dart` 勾选 + `setup_legal_dialog.dart` 法律文档
- **现象**：setup 流程让用户勾"我已告知上述联系人"——**联系人本人没确认**。PIPL §23 要求"向第三方提供个人信息前应**单独告知第三方**"
- **复现路径**：
  1. 用户首次 setup 添加紧急联系人
  2. 勾"我已告知上述联系人"
  3. 联系人**没有收到任何通知**确认"我知道我会收到失联通知"
  4. 用户漏 2 天 → SMS 发给联系人（"我是 $name，已 2 天没打卡"）→ 联系人**莫名其妙**收到 → 恐慌 / 报警 / 投诉
- **法律风险**：PIPL §71 违规处罚（最高 5000 万或上年营业额 5%）
- **修复**：发 SMS 确认 + 联系人回复 "Y" → 标记 confirmed

### Bug 12: chinese_holidays.dart 2026-2030 硬编无 fallback
- **文件**：`lib/domain/logic/chinese_holidays.dart:27-89`
- **现象**：法定节假日日期 `Set<String>` 硬编 2026-01-01 到 2030-10-07。**2031+ 全部不识别**
- **复现路径**：
  1. 2031 年用户用 App
  2. 续方提醒推到 2031-02-10（春节）
  3. `ChineseHolidays.isHoliday(DateTime(2031, 2, 10))` → `false`（不在 set 里）
  4. `nextWorkdayAfter` 不跳过春节 → 药店关门 → 用户买不到药
- **影响**：过期后所有用户的续方提醒都失效——但**无任何代码提示**让维护者知道数据过期
- **修复**：加 `static bool isDataExpired() { return DateTime.now().year > _maxYearInSet; }` + log warning

### Bug 13: snooze_manager.dart 通知 channel name/desc 跟 strings.dart 重复
- **文件**：`lib/core/data/services/snooze_manager.dart:80-82`
- **现象**：`AndroidNotificationDetails('chroniccare.medication', '吃药提醒', channelDescription: '到点提醒你吃药打卡', ...)` 跟 `Strings.notifChannelMedicationName/Desc` 重复
- **复现命令**：
  ```bash
  grep -n "吃药提醒\|到点提醒" lib/core/data/services/snooze_manager.dart
  ```
- **影响**：channel name/desc 在 Android 系统设置显示（**用户能直接看到**），英文用户看到"吃药提醒"是中文
- **修复**：用 `Strings.notifChannelMedicationName/Desc`

### Bug 14: medication_notifier / refill_notifier piiSafeLog 泄漏药名
- **文件**：`lib/core/data/services/medication_notifier.dart:142-150` + `refill_notifier.dart:114-204`
- **现象**：`piiSafeLog('MedicationNotifier', '❌ 推送调度失败 med=${med.name} t=$t: $e')` 药名虽走 piiSafeLog 但 dev 模式仍打印（spen 已记）
- **复现命令**：
  ```bash
  grep -n "med.name" lib/core/data/services/medication_notifier.dart lib/core/data/services/refill_notifier.dart
  ```
- **影响**：精神心理患者药名是 PII（SSRI 抗抑郁 / 抗焦虑 / 抗精神病 — 都敏感）
- **修复**：`piiSafeLog` 改默认不打印 $e 完整内容

### Bug 15: README.md / AGENTS.md / CHANGELOG.md 数字打架
- **文件**：`README.md:131` 写 "876 cases" / 实际 `flutter test` 跑 **1052 cases**（已 verify） / AGENTS.md 写 "910+" / CHANGELOG 写"876"
- **复现**：
  ```bash
  flutter test 2>&1 | Select-Object -Last 3
  # 输出: All tests passed! (1052 cases)
  grep -n "876\|1052\|910" README.md AGENTS.md docs/CHANGELOG.md
  ```
- **影响**：开发者看文档以为 876 cases，实际 1052 —— 文档严重 outdated
- **修复**：3 处刷成 1052

---

## 五、附：grep 验证命令汇总

```bash
# 1. i18n 硬编统计
grep -rE "'[一-龥]+'|\"[一-�]+\"" lib/ --include="*.dart" -l
# 输出: 50+ 个文件

# 2. mojibake
grep -nE "鎵撳崟|璁剧疆|鏃ユ湡" lib/ -r
# 输出: app_router.dart:312: 璁剧疆  (v0.24 round 46 9e9e6de 漏修)

# 3. 已知 strings.dart 硬编数
grep -cE "^\s+static.*=.*'[一-龥]" lib/core/l10n/strings.dart
# 输出: ~30 行（实际 50+，包含 'const emailFooter = ...' 等多行）

# 4. 量表题目硬编
grep -cE "'[一-龥]+'" lib/domain/logic/phq9.dart lib/domain/logic/gad7.dart
# 输出: ~25 行

# 5. SMS 模板硬编
grep -nE "慢病管家|【慢病管家】|—— 这是一条自动提醒" lib/core/data/services/safety_watch_service.dart lib/core/data/services/reminder_scheduler.dart

# 6. ARB 孤儿 key 检测（需自定义脚本）
python scripts/check_arb_keys.py --staged
# (现有脚本只查同步，不查引用)

# 7. CHANGELOG 段顺序
python scripts/check_changelog.py
# 输出: [OK] check_changelog: pubspec=[0.24.0+1] CHANGELOG 顺序正确 (19 段)

# 8. tz 硬编码
grep -nE "Asia/Shanghai|setLocalLocation" lib/main.dart lib/core/data/services/notification_service.dart

# 9. formatters 不走 intl
grep -nE "d\.(year|month|day|hour|minute)" lib/core/shared/formatters.dart
# 输出: 5+ 处

# 10. 文档数字一致性
flutter test 2>&1 | tail -1
# 输出: All tests passed! (1052 cases)
grep -nE "876|1052|910" README.md AGENTS.md docs/CHANGELOG.md

# 11. 11 个守护脚本覆盖
ls scripts/*.py scripts/*.dart
# 11 个：check_arb_keys / check_changelog / check_cross_feature / 
#      check_datetime_race / check_datetime_race2 / check_drift_namespace /
#      check_fullwidth_punctuation / check_no_hardcoded_utc / check_no_pua /
#      check_widget_dispose + check_all.dart

# 12. 3 份法律文档 关键词
grep -nE "跨境|境外|海外" assets/legal/privacy_policy.md
# 输出: 0 行（缺跨境段）
```

---

## 报告元信息

- **发现总数**：56 个独立问题（不含 spen 55 + emil 97）
  - i18n 硬编 48（strings.dart 21 + 量表 7 + service 12 + entity 5 + formatters 3）
  - i18n 一致性 6（孤儿 key + 命名差异 + zh_Hant 文档不一致）
  - 文案质量 4
  - 提交规范 5
  - 合规 / 法务 7（PIPL / NMPA / 5 厂商 push / 危机电话 / 单独同意 / 跨境数据传输）
  - 时区 / 日期 2
  - CI / 脚本 1
  - 文档完整性 1
- **Top 3 优先级**（修成本 / 风险比最高）：
  1. **PIPL §13 单独同意未实现**（4-8h 修，4 store 上架阻塞 + 法律责任）
  2. **量表 PHQ-9 / GAD-7 全部硬编中文 + 危机电话 400-161-9995 海外打不通**（1 round 修，医疗法律红线）
  3. **CHANGELOG v0.24.0 "Known issues" 段过期**（0.5h 修，release 文档错乱）
- **报告文件路径**：`D:\Batch\chroniccare\docs\reviews\2026-07-26-three-lens\spzh\report.md`

**flutter analyze + flutter test 验证**：
- `flutter test` 已跑：1052 cases 全过（vs README 写的 876 outdated）
- `flutter analyze` 未在本会话跑（避免长 analyze 阻塞），但所有 56 个发现都基于 `lib/` + `docs/` 实际文件内容，未依赖编译
- 11 个守护脚本覆盖范围已 verify（除 ARB 孤儿 key 检测外都全）
