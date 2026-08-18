# 慢病管家 v0.28 多视角综合审查报告

**审查日期**: 2026-08-03
**审查范围**: 267 个 lib/.dart + ios/ + android/ + assets/legal/ + fastlane/ + test/ + ARB = 450+ 文件
**审查方法**: 4 路全新并行 agent，每路逐文件逐行阅读，不使用任何历史数据

---

# 一、Flutter 规范视角

## 顶层架构审视

### 架构成熟度: 8.3/10

项目严格遵循 4 层架构（presentation → domain ← data）+ core/shared umbrella。domain 层 0 Flutter 0 Drift 依赖，16 个 CI 守护脚本自动验证。

### 架构违规（4 处）

| # | 文件 | 问题 | 难度 |
|---|------|------|------|
| 1 | `domain/logic/chinese_holidays.dart:8` | domain 直接 import `core/data/services/pii_safe_log.dart`，违反 domain ← data 规则 | S |
| 2 | `core/data/services/safety_alert_builder.dart:33` | data/service 直接 import presentation l10n | S |
| 3 | `core/data/services/safety_watch_service.dart:16` | 同上 | S |
| 4 | `core/data/services/safety_alert_dispatcher.dart:12` | 同上 | S |

### 可重构模块（P3）

| # | 模块 | 说明 |
|---|------|------|
| 5 | `settings` pages/ | Hub god feature，含通知/数据/法律/账户多功能，建议拆子模块 |
| 6 | `Strings` class 303 行 | 50+ 中文 fallback，override 几乎无人传入，建议按功能域拆分 |
| 7 | `saveSetup`/`clearAllUserData` 在 AppDatabase | 跨表事务编排应移入 domain/usecases |
| 8 | `ReminderService` 类 | 已废弃但未删除，与 SafetyWatchService 并行维护 |

## 底层逐行排查

### P0 — 上架阻断（2 个）

| # | 文件:行号 | 类型 | 难度 | 说明 |
|---|-----------|------|------|------|
| 9 | `domain/logic/assessment_record.dart:82` | Bug | S | `json['total'] as int?` 对 double 值抛 TypeError 崩溃。应用 `is int` 判断 |
| 10 | `core/data/database/app_database.dart:198-318` | 数据丢失 | M | v8→v9 加密迁移失败的行 contentTextEnc=null，v15→v16 DROP contentText 后文字永久丢失 |

### P1 — 必修 Bug（7 个）

| # | 文件:行号 | 类型 | 难度 | 说明 |
|---|-----------|------|------|------|
| 11 | `core/data/services/reminder_scheduler.dart:119` | 崩溃 | S | `Future.wait.first as List<ContactEntity>` — cast 失败直接 TypeError |
| 12 | `core/data/services/medication_notifier.dart:147` | 崩溃 | S | `catch(e)` 缺 stack trace，无法定位失败来源 |
| 13 | `core/data/services/refill_notifier.dart:172` | 崩溃 | S | 同上 |
| 14 | `core/data/services/snooze_manager.dart:119` | 崩溃 | S | 同上 |
| 15 | `core/data/services/assessment_notifier.dart:80` | 崩溃 | S | 同上 |
| 16 | `domain/logic/care_engine.dart:143` | 逻辑 | S | 通知 id 8000+index，无 index >= 100 边界保护，新 type 可能闯入其他 id 段 |
| 17 | `core/data/services/mood_audio_service.dart:208` | i18n崩溃 | S | `throw MoodAudioException('麦克风权限被拒绝')` — en 用户看到中文异常 |

### P2 — 应修（12 个）

| # | 文件 | 类型 | 难度 | 说明 |
|---|------|------|------|------|
| 18 | `domain/logic/medication_report.dart:199-290` | i18n | L | `toReportString()` 20+ 处硬编中文（PDF 给医生看） |
| 19 | `domain/logic/care_copy.dart:50-69` | i18n | S | 4 个关怀 trigger 中文 fallback |
| 20 | `domain/logic/lost_contact_sms.dart:86-87` | i18n | S | safetyAlert SMS 中文硬编 |
| 21 | `domain/entities/vent_entry_entity.dart:98` | i18n | S | durationLabel 中文 fallback `'秒'/'分'` |
| 22 | `domain/logic/day_detail.dart:317-339` | i18n | S | 6 处打卡/评估标签中文 fallback |
| 23 | `domain/entities/check_in_entity.dart:66-72` | i18n | S | labelL10n 中文 fallback |
| 24 | `domain/logic/assessment_comparison.dart:199` | i18n | S | severityLabel 中文 `'等级 $rank'` |
| 25 | `presentation/widgets/consent_dialog.dart:169-175` | i18n | S | 3 段撤回说明硬编中文 |
| 26 | `presentation/pages/vent/vent_list_page.dart:348` | i18n | S | _formatTime 手动拼日期，应复用 Formatters |
| 27 | `presentation/pages/assessment/assessment_widgets.dart:424` | i18n | S | _dateLabel 手动拼日期，应复用 Formatters |
| 28 | `presentation/pages/assessment/assessment_widgets.dart:219` | i18n | S | `'Q$index.'` 英文硬编，zh 用户应看到 `'第N题'` |
| 29 | `core/data/services/mood_audio_service.dart:366-381` | 资源 | S | recorder.dispose() 抛异常时 sttController 可能未 close |

### P3 — 优化（12 个）

| # | 文件 | 类型 | 难度 | 说明 |
|---|------|------|------|------|
| 30 | `domain/logic/assessment_comparison.dart:252` | DateTime race | S | `now ?? DateTime.now()` 跨函数可能不一致 |
| 31 | `domain/entities/medication_entity.dart:76` | DateTime race | S | `now ?? DateTime.now()` 多次调用可能跨 midnight |
| 32 | `core/data/services/assessment_reminder_service.dart:148` | DateTime race | S | await 后重复调 getLastAssessmentAt() |
| 33 | `core/data/database/app_database.dart:366` | DateTime race | S | saveSetup 中有 `now` 但注释说"同一个 now"实际已正确 |
| 34 | `core/data/services/reminder_dispatcher.dart:64` | 性能 | M | cancelByIdRange 串行 2s×100=200s |
| 35 | `core/data/services/reminder_scheduler.dart:122` | 错误处理 | S | 两个 stream 共用 try/catch，一个失败两个都降级 |
| 36 | `presentation/pages/vent/vent_compose_page.dart:443` | 性能 | S | onChanged 每次全页 rebuild |
| 37 | `presentation/pages/setup/setup_page.dart:124` | 性能 | S | _onTextChanged 全页 rebuild |
| 38 | `presentation/providers/legal_consent_provider.dart:190` | 架构 | M | StreamProvider 仅 yield 一次，应用 FutureProvider |
| 39 | `presentation/pages/contact/contacts_list_widget.dart:181` | 硬编码 | S | hintText `'13800138000'` 硬编中国号码 |
| 40 | `presentation/pages/medication/medication_calendar_page.dart:400` | 硬编码 | S | `< 50%`/`< 100%` 字符串硬编 |
| 41 | `core/theme/app_theme.dart:144` | 硬编码 | S | OutlinedButton borderWidth 1.5 未走 token |

### Token 硬编码汇总（批量，P3/S）

main.dart(7): `SizedBox(height: 12/4/12/4/16/12/16/12)` + `EdgeInsets.all(24/16)` — 共 10 处未走 AppTokens
app_shell.dart(3): `EdgeInsets.symmetric(vertical:16)`, `size:32`, `SizedBox(height:4/8)`
app_theme.dart(1): `_navigationRailTheme` iconSize 28/24 裸数字
section_header.dart(1): `_ChipBadge` padding vertical:2
secondary_button.dart(1): spinner `SizedBox width:16`
mood_visual.dart(6): `colorArgbFor` 返回 6 个硬编码 ARGB int 未引用 AppColors

---

# 二、App Store 视角

## P0 阻断（9 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 42 | `project.pbxproj` | M | PrivacyInfo.xcprivacy 未被 pbxproj 引用，不会打包进 .ipa (**Apple 2024-05 强制要求**） |
| 43 | `project.pbxproj` | S | 缺 DEVELOPMENT_TEAM，无法签名 |
| 44 | `Podfile` | M | 无 Podfile.lock（Windows 占位），macOS 需 pod install |
| 45 | `assets/legal/*.md` | L | 3 份法律文档标注"草稿 (未经律师过审)" |
| 46 | `fastlane/metadata/**/privacy_url.txt` | M | 域名 `chroniccare.app` 未注册，URL 不可达（**必拒**） |
| 47 | `fastlane/metadata/**/support_url.txt` | S | 同上 |
| 48 | `fastlane/metadata/ios/**/description.txt` | M | 描述中提及"coming soon / 即将上线"的失联通知（违反 Guideline 2.3.1） |
| 49 | `fastlane/screenshots/` | M | 截图目录空，缺 6.7" 以上截图 |
| 50 | `user_agreement.md:68-69` | S | 邮箱 + GitHub Issues 为 TODO 占位 |

## P1 高风险（6 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 51 | `Info.plist` | S | `NSSpeechRecognitionUsageDescription` 说"本地处理不上传"但 cloud 模式可能触发矛盾 |
| 52 | `PrivacyInfo.xcprivacy:136-145` | S | ProcessInfo reason code AC67.1 与 flutter_local_notifications 实际 API 不匹配 |
| 53 | `PrivacyInfo.xcprivacy` 整体 | M | 缺 speech_to_text 相关 API 的 privacy manifest 条目 |
| 54 | `Podfile:18` | S | `platform :ios, '13.0'` 与 pbxproj `14.0` 不一致 |
| 55 | `Info.plist` | S | 缺 `CFBundleLocalizations` 显式声明 |
| 56 | `Info.plist:8` | S | `CFBundleDevelopmentRegion` 未显式设 `zh-Hans` |

## P2 建议（4 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 57 | `project.pbxproj` | S | `ORGANIZATIONNAME` 空值，`LastUpgradeCheck = 1510` |
| 58 | `PrivacyInfo.xcprivacy:98-107` | S | CA92.2 跨 App 共享声明为"防御性"，可能被审核追问 |
| 59 | `Runner.entitlements` | S | 空文件仅注释，可从 pbxproj 移除 |
| 60 | `fastlane/metadata/ios/*/screenshots` | M | 截图仅 5.5"/6.5" 尺寸，缺 6.7"/6.9" |

---

# 三、Google Play Store 视角

## P0 阻断（4 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 61 | `build.gradle.kts:88` | S | 签名用 debug keystore，Google Play **绝对拒**（key.properties 不存在） |
| 62 | `assets/legal/*.md` | L | 同 App Store #45 |
| 63 | 域名 + 邮箱 | M | 同 App Store #46,47,50 |
| 64 | `fastlane/metadata/android/**/video.txt` | S | YouTube URL = "PLACEHOLDER_APP_DEMO_VIDEO" |

## P1 高风险（4 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 65 | `AndroidManifest.xml:45` | M | `android:label="慢病管家"` 硬编中文，英文设备桌面显示中文 |
| 66 | `fastlane/metadata/android/**/full_description.txt` | M | 描述中含 "coming soon / currently disabled" 未发布功能 |
| 67 | Play Console | M | Data Safety Form 未填 |
| 68 | Play Console | S | 内容分级未填 |

## P2 建议（3 项）

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 69 | `fastlane/metadata/android/zh-CN/full_description.txt:39,41` | S | 危机热线 400-161-9995 重复写两次 |
| 70 | `AndroidManifest.xml:33` | S | USE_EXACT_ALARM 需在 Play Console 提交使用理由 |
| 71 | Play Console | M | 权限声明表单需填写 |

---

# 四、法务合规视角

## PIPL 合规（80/100）

| 条款 | 状态 | 备注 |
|------|------|------|
| §13 单独同意 | 通过 | 4 勾选 + ConsentDialog + ConsentArtifact |
| §14 撤回同意 | 通过 | 3 toggle + ConsentGate 业务层拦截 |
| §17 同意记录 | 通过 | DB 字段 + audit log |
| §23 第三方提供 | 待完成 | 用户担保模式，联系人本人确认待 SMS 接入 |
| §28 敏感信息 | 通过 | SQLCipher + 树洞字段级加密 |
| §31 未成年人 | 通过 | 年龄严正声明 |
| §38 跨境传输 | 识别中 | speech_to_text 已识别 + FeatureFlag 控制 |
| §47 删除权 | 通过 | 单条/全部/卸载 |

## 法律文档阻断项

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 72 | `user_agreement.md:68` | S | TODO `support@chroniccare.app` 占位邮箱 |
| 73 | `user_agreement.md:69` | S | TODO `github.com/example/chroniccare` 占位仓库 |
| 74 | 3 份 | L | "草稿 (未经律师过审)" 标注 — 必须律师审核后删除 |
| 75 | `user_agreement.md:24-28` | S | IAP 注脚说"暂停"但代码 `_prodIapEnabled=true` |

## 数据加密审计

| 数据类型 | 加密 | 风险 |
|----------|------|------|
| DB 整体 | SQLCipher AES-256 | 无 |
| 树洞文字 | AES-256-CBC 字段级 | 无 HMAC（本地风险低） |
| 录音文件 | AES-256-CBC | 同上 |
| Key 存储 | FlutterSecureStorage | **key 损坏静默覆盖，旧数据永久不可解（#10）** |

---

# 五、ARB i18n + 测试层

## ARB

| # | 问题 | 难度 |
|---|------|------|
| 76 | 3 个 i18n 方法仅定义在 Dart 代码中，不在 ARB 文件中（lostContactSafetyAlertBody 等） | M |
| 77 | ARB 三语同步 736 key — **通过**，无遗漏 |

## 测试

### 测试覆盖缺口

| # | 文件 | 难度 |
|---|------|------|
| 78 | `data_export_service.dart` — 零测试 | M |
| 79 | `encryption_service.dart` — 零测试 | M |
| 80 | `medication_report_pdf_layout.dart` — 零测试 | L |
| 81 | `safety_config_service.dart` — 零测试 | S |
| 82 | `store_kit_service.dart` — 零测试 | L |
| 83 | `assessment_scale.dart` — 零测试 | S |
| 84 | `temp_entry_extractor.dart` — 零测试 | S |

### Flaky 测试（跨 midnight 风险）

| # | 文件 | 难度 |
|---|------|------|
| 85 | `safety_watch_service_round12_test.dart` — 12+ 处 `DateTime.now()` 无锚定 | M |
| 86 | `refill_manage_round13a_test.dart` — 9 处 `DateTime.now()` | S |
| 87 | `assessment_reminder_service_round12_test.dart` — 3 处 before/after 夹断 | S |
| 88 | `medication_calendar_round13c_test.dart` — 3 处 | S |
| 89 | `today_med_schedule_round17_test.dart` — 2 处 | S |
| 90 | `swallow_log_sink_round83_test.dart` — 1 处 busy-wait spin poll | S |

### 其他

| # | 问题 | 难度 |
|---|------|------|
| 91 | `_tmp_email_test.dart` — 占位文件，仅 `expect(1+1,2)` | S |
| 92 | `widget_test.dart` — 未用 `_roundN_` 命名 | S |

---

# 六、综合优先级排序

## P0 — 上架阻断（16 项）

| # | 问题 | 视角 | 难度 | 类型 |
|---|------|------|------|------|
| 1 | 律师审核 3 份法律文档 | 法务+Store | L | 外部 |
| 2 | 域名 `chroniccare.app` 注册 + HTTPS 部署隐私页 | 法务+Store | M | 外部 |
| 3 | 注册 `support@chroniccare.app` 邮箱 | 法务 | S | 外部 |
| 4 | PrivacyInfo.xcprivacy 加进 pbxproj 打包 | App Store | M | 配置 |
| 5 | 配置 Apple Development Team | App Store | S | 配置 |
| 6 | Android release 签名（生成 keystore） | Play | S | 代码 |
| 7 | macOS pod install 生成 Podfile.lock | App Store | M | 外部 |
| 8 | 删除 metadata 中 "coming soon / 规划中" 文案 | Store | M | 文档 |
| 9 | 替换 GitHub Issues / 邮箱 TODO 占位 | 法务 | S | 文档 |
| 10 | 手机截图 + App Icon | Store | M | 外部 |
| 11 | Play Console Data Safety Form | Play | M | 外部 |
| 12 | IAP productId 创建 | Store | S | 外部 |
| 13 | 内容分级 | Play | S | 外部 |
| 14 | 软件著作权登记 | 法务 | L | 外部 |
| 15 | 修复 assessment_record 类型转换崩溃 | Flutter | S | 代码 |
| 16 | 修复 vent 迁移数据永久丢失 | Flutter | M | 代码 |

## P1 — 必修 Bug（15 项）

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 17 | 4 个 notifier catch(e) 缺 stack trace | S | medication/refill/snooze/assessment |
| 18 | reminder_scheduler Future.wait cast 崩溃 | S | `reminder_scheduler.dart:119` |
| 19 | care_engine 通知 id 无边界保护 | S | `care_engine.dart:143` |
| 20 | mood_audio 硬编中文异常消息 | S | `mood_audio_service.dart:208` |
| 21 | data_export_service 零测试 | M | `data_export_service.dart` |
| 22 | encryption_service 零测试 | M | `encryption_service.dart` |
| 23 | medication_report_pdf_layout 零测试 | L | `medication_report_pdf_layout.dart` |
| 24 | 3 个 AlarmDispatcher Builder 直接 import l10n | S | safety_alert_* 3 文件 |
| 25 | domain 直接 import data（pii_safe_log） | S | `chinese_holidays.dart:8` |
| 26 | PrivacyInfo reason code 与实际 API 不匹配 | S | `PrivacyInfo.xcprivacy:136-145` |
| 27 | Podfile ios 13.0 vs pbxproj 14.0 不一致 | S | `Podfile:18` |
| 28 | AndroidManifest label 硬编中文 | M | `AndroidManifest.xml:45` |
| 29 | swift bus-wait spin poll flaky test | S | `swallow_log_sink_round83_test.dart:37` |
| 30 | 12+ 处 DateTime.now() 无锚定 flaky test | M | `safety_watch_service_round12_test.dart` |
| 31 | 3 个 i18n 方法绕过 ARB pipeline | M | `app_localizations.dart:1608-1624` |

## P2 — 应修（22 项）

| # | 问题 | 难度 | 说明 |
|---|------|------|------|
| 32-38 | 7 处 domain 层 i18n 中文 fallback | S-M | medication_report/care_copy/lost_contact_sms/vent_entry/day_detail/check_in/assessment_comparison |
| 39-42 | 4 处 presentation 层硬编码中文/格式 | S | consent_dialog/vent_list/assessment_widgets/contacts_list |
| 43 | 2 个 safety_alert 文件直接 import l10n | S | 与 P1 #24 重叠 |
| 44 | Android zh-CN 危机热线重复 | S | `full_description.txt:39,41` |
| 45 | assessment 测试 before/after 夹断 | S | `assessment_reminder_service_round12_test.dart:243,355,374` |
| 46 | refill/medication/schedule 测试 DateTime | S | 3 文件 |
| 47 | 7 个测试覆盖缺口（见上方 #21-23,78-84） | S-L | 多文件 |
| 48 | 15+ 处 token 硬编码（spacing/size/color） | S | main.dart/app_shell/app_theme/mood_visual 等 |
| 49 | 2 个测试命名不规范 | S | _tmp_email_test.widget_test |
| 50 | ReminderService 死代码未删除 | M | `reminder_scheduler.dart:24-241` |

## P3 — 优化（18 项）

| # | 问题 | 难度 | 说明 |
|---|------|------|------|
| 51 | settings Hub god feature 可拆 | M | `pages/settings/` |
| 52 | Strings 类可按功能域拆分 | L | `core/l10n/strings.dart` |
| 53 | saveSetup/clearAllUserData 移入 usecase | S | `app_database.dart:350-420` |
| 54 | cancelByIdRange 串行 await 可并行 | M | `reminder_dispatcher.dart:64` |
| 55 | export 6 个 DB 查询串行可并行 | M | `export_orchestrator.dart:104-125` |
| 56 | AES-CBC 无 HMAC（本地风险低） | L | `encryption_service.dart:86-93` |
| 57 | mood_visual ARGB 未引用 AppColors | S | `mood_visual.dart:87-98` |
| 58 | legalConsentProvider 用 StreamProvider 仅 yield 一次 | M | `legal_consent_provider.dart:190` |
| 59 | vent_compose_page onChanged 全页 rebuild | S | `vent_compose_page.dart:443` |
| 60 | setup_page _onTextChanged 全页 rebuild | S | `setup_page.dart:124` |
| 61 | ConsentGate 并发两个 isWithdrawn 可能双实例化 | S | `consent_gate.dart:72-73` |
| 62 | 6 个 entity/draft 缺测试 | S | dosage_unit/hour_minute/report_history 等 |
| 63 | app_list_tile _isDestructive 死代码 | S | `app_list_tile.dart:134` |
| 64 | recorder.dispose() 异常时 sttController 未释放 | S | `mood_audio_service.dart:366-381` |
| 65 | chinese_holidays 只到 2030 | M | `chinese_holidays.dart:27-89` |
| 66 | HourMinute.fromString 静默返 00:00 | S | `hour_minute.dart:37-43` |
| 67 | CFBundleLocalizations 未显式声明 | S | `Info.plist` |
| 68 | 空 entitlements 文件可移除 | S | `Runner.entitlements` |

---

# 七、总评

| 维度 | 评分 | 关键问题 |
|------|------|----------|
| Flutter 规范 | **A-** | 15 个 P0-P1 Bug，4 处架构违规 |
| App Store 就绪 | **4/10** | 9 项阻断：隐私清单未打包/域名/法律文档/截图全缺 |
| Google Play 就绪 | **5/10** | 4 项阻断：debug 签名/域名/法律文档 |
| 法务合规 | **80/100** | PIPL 框架扎实，3 份法律文档需律师过审 |
| 架构成熟度 | **8.3/10** | 1 处 domain→data 反向依赖 + 3 处 data→presentation |
| 底层实现 | **8.5/10** | 最严重：key 损坏静默覆盖永久丢数据 |
| ARB i18n | **95/100** | 三语 736 key 同步，3 个 key 绕过 ARB pipeline |

**结论**: 450+ 文件逐行审查完毕。代码质量整体优秀，P0-P1 共找到了 15 个真实 Bug（1 个数据丢失级 + 1 个类型崩溃级）。最大阻塞在外部依赖（律师/域名/Apple 账号），预计 2-3 个月可达上架标准。
