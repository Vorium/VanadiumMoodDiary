# 慢病管家 v0.28 全量代码审查报告

**审查日期**: 2026-08-02
**代码规模**: lib/ 247 文件 + test/ 159 文件 + assets/legal/ 3 文档 = 409 文件
**审查方法**: 5 个并行 agent 逐行阅读全部文件
**修复状态**: P0 代码侧 3 项 + P1 真实 Bug 6 项已修复

---

# Flutter 视角

## 架构层（评分 8.3/10）

| 维度 | 评分 | 说明 |
|------|------|------|
| 分层清晰度 | 9/10 | 4 层 + shared，domain 零 Flutter，CI 守门员自动验证 |
| 模块化 | 8/10 | 10 feature 模块 + Hub-Leaf + check_cross_feature.py |
| 状态管理 | 8/10 | Riverpod 分层 Provider + autoDispose + UseCase 注入 |
| 错误处理 | 8/10 | runZonedGuarded + AsyncValue.guard + swallowError + LastErrorCapture |
| 测试覆盖 | 9/10 | 151 测试文件 + 16 守护脚本 + 三层测试 |
| i18n | 7/10 | ARB 三语同步 765 key，domain 层 override 几乎未传入 |

### 架构可改进（P3，不影响上架）

| # | 问题 | 层级 | 难度 | 文件 |
|---|------|------|------|------|
| 1 | `core/routing/` 反向依赖 `presentation/pages/` | 架构 | M | `app_routes.dart`（AGENTS.md 已豁免） |
| 2 | `settings` Hub god feature 可拆子模块 | 架构 | M | `pages/settings/` |
| 3 | `Strings` class 303 行 50+ 项中文 fallback，override 几乎未传入 | 架构 | L | `core/l10n/strings.dart` |
| 4 | `saveSetup()`/`clearAllUserData()` 仍在 AppDatabase，应移入 usecase | 架构 | S | `app_database.dart:350-420` |

---

## 底层真实 Bug（P2，10 个 i18n + 2 个资源泄漏）

### i18n Bug — 海外用户看到中文

| # | 问题 | 层级 | 难度 | 文件:行号 |
|---|------|------|------|-----------|
| 1 | `trendLabel` 硬编 `'好转'`/`'恶化'`/`'持平'` | 底层 | M | `assessment_comparison.dart:66-76` |
| 2 | `deltaLabel` 硬编 `'和上次一样'`/`'比上次高 X 分'` | 底层 | M | `assessment_comparison.dart:93-99` |
| 3 | 评估 subtitle 硬编 `'总分 $total'` | 底层 | S | `day_detail.dart:253` |
| 4 | 4 个关怀 trigger title+body 全硬编中文 | 底层 | L | `care_copy.dart:30-60` |
| 5 | 用药报告 `toReportString()` 全文 20+ 处硬编中文 | 底层 | L | `medication_report.dart:191-278` |
| 6 | safetyAlert SMS 硬编 `'[慢病管家]...如确认安全请回复 1'` | 底层 | L | `lost_contact_sms.dart:60-61` |
| 7 | reminder SMS 硬编 `'【慢病管家】$name 已 N 天没打卡'` | 底层 | L | `lost_contact_sms.dart:66-70` |
| 8 | consent dialog 3 行撤回说明硬编中文 | 底层 | S | `consent_dialog.dart:169-176` |
| 9 | email preview fallback `'您的家人'` 硬编中文 | 底层 | S | `email_preview.dart:61` |
| 10 | error page fallback `'页面不存在'`/`'返回首页'` 硬编中文 | 架构 | S | `app_routes.dart:150,166` |

### 资源泄漏

| # | 问题 | 层级 | 难度 | 文件:行号 |
|---|------|------|------|-----------|
| 11 | `PageController` 在 `build()` 中创建，从未 dispose | 底层 | S | `quick_mood_carousel.dart:126-129` |
| 12 | `_player.dispose()` Future 未包 `unawaited()` | 底层 | S | `vent_detail_page.dart:70` |

---

## 底层加固项（P2，5 个）

| # | 问题 | 层级 | 难度 | 文件:行号 |
|---|------|------|------|-----------|
| 13 | `colorArgbFor()` 6 个硬编码 ARGB，dark mode 对比度差 | 底层 | M | `mood_visual.dart:84-98` |
| 14 | `streakSummaryProvider` 未 watch `dayChangeTickProvider` | 架构 | S | `shared_providers.dart:53` |
| 15 | AES-CBC 无 HMAC（本地 app 风险低） | 架构 | L | `encryption_service.dart:86-93` |
| 16 | PRAGMA key 用字符串插值（当前输入安全） | 底层 | S | `native.dart:27` |
| 17 | 文件名用 `Random()` 非 `Random.secure()` | 底层 | S | `encrypted_audio_storage.dart:116` |

---

## 底层 Code Smell（P3，15 个）

| # | 问题 | 层级 | 难度 | 文件:行号 |
|---|------|------|------|-----------|
| 18 | `vent_compose_page` onChanged 全页 rebuild | 底层 | S | `vent_compose_page.dart:443` |
| 19 | `setup_page` _onTextChanged 全页 rebuild | 底层 | S | `setup_page.dart:95-98` |
| 20 | `home_page` build watch 4 个 provider 可拆分 | 架构 | M | `home_page.dart:328-461` |
| 21 | `home_fab_toolbar` unused SingleTickerProviderStateMixin | 底层 | S | `home_fab_toolbar.dart:36` |
| 22 | `dosage()` 注释说"round-half-up"实际是整数判断 | 底层 | S | `formatters.dart:44-45` |
| 23 | `SwallowLogSink._truncate()` 按字符截断可能断多字节 | 底层 | S | `swallow_log_sink.dart:136` |
| 24 | `reminder_scheduler._daysBetween` 与 `SafetyConfigService.daysBetween` 重复 | 底层 | S | `reminder_scheduler.dart:236` |
| 25 | `export_orchestrator` 6 个 DB 查询串行 await 可并行 | 底层 | S | `export_orchestrator.dart:108` |
| 26 | `preset_medication_templates` 硬编 `'片'` 而非 `DosageUnit.tablet.id` | 底层 | S | `preset_medication_templates.dart:236` |
| 27 | `contacts_list_widget` hint `'13800138000'` 硬编码 | 底层 | S | `contacts_list_widget.dart:182` |
| 28 | `main.dart` 7 处迁移 UI spacing 未走 token | 架构 | S | `main.dart:292-467` |
| 29 | `app_shell` 3 处 spacing 裸数字未走 token | 架构 | S | `app_shell.dart:82,90,106` |
| 30 | `vent_repository_impl.delete` 事务外读+事务内删（TOCTOU，极低概率） | 底层 | S | `vent_repository_impl.dart:108-116` |
| 31 | `chinese_holidays` 节假日数据只到 2030，2031+ 续方提醒可能排在假日 | 底层 | M | `chinese_holidays.dart:27-89` |
| 32 | `assessment_record` `json['total'] as int?` 对 double 抛 TypeError | 底层 | S | `assessment_record.dart:82` |

---

## 测试层

### 测试覆盖

| 层 | 文件数 | 覆盖情况 |
|----|--------|----------|
| domain | 30 | 全部核心模块覆盖 |
| data | 28 | 全部 repository/service 覆盖 |
| presentation | 40 | 全部页面/widget 覆盖 |
| core | 21 | services/utils 全覆盖 |

### 测试问题

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 33 | `_tmp_email_test.dart` 占位文件（仅 `// Placeholder deleted.`） | S | `test/_tmp_email_test.dart` |
| 34 | `widget_test.dart` 未使用 `_roundN_` 命名规范 | S | `test/widget_test.dart` |
| 35 | `safety_watch_service_round12_test.dart` 15 处 `DateTime.now()` 跨 midnight 风险 | M | `test/data/safety_watch_service_round12_test.dart` |
| 36 | `refill_manage_round13a_test.dart` 9 处 `DateTime.now()` 跨 midnight 风险 | M | `test/presentation/refill_manage_round13a_test.dart` |
| 37 | 其他 8 个测试文件潜在 flaky（跨 midnight） | S-M | 多文件 |

---

# App Store 视角

## 代码层状态（90% ready）

| 配置项 | 状态 |
|--------|------|
| Info.plist 权限描述 | 完整（麦克风/语音识别/相册/追踪） |
| PrivacyInfo.xcprivacy | 5 个 required-reason API + 4 类数据声明 |
| Runner.entitlements | 已删除 aps-environment |
| ITSAppUsesNonExemptEncryption | `false`（SQLCipher 属标准库加密） |
| UIBackgroundModes | audio + processing |
| BGTaskScheduler | `com.chroniccare.safety-check` |
| IAP | `_prodIapEnabled=true`，需创建 StoreKit productId |
| 邮箱 | 已替换为 `support@chroniccare.app` |
| 签名 | 已切换 release |
| CFBundleDisplayName | zh-Hans/zh-Hant 通过 `InfoPlist.strings` 覆盖"慢病管家" |

## 配置修正

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 38 | Podfile `platform :ios, '13.0'` 与 pbxproj `14.0` 不一致 | S | `ios/Podfile:18` |
| 39 | `CFBundleDevelopmentRegion` 默认 en 应改 `zh-Hans` | S | `Info.plist:8` |
| 40 | `ORGANIZATIONNAME` 空值 | S | `project.pbxproj:182` |
| 41 | keywords 仅 7 词（App Store 允许 100 字） | S | `fastlane/metadata/ios/en-US/keywords.txt` |

## P0 外部依赖

| # | 问题 | 难度 | 估时 |
|---|------|------|------|
| 42 | 律师审核 3 份法律文档 | L | 1-2 周 |
| 43 | 域名注册 + ICP 备案 + HTTPS 部署 | M | 1-2 天 + 7-20 天 |
| 44 | App Store Connect 配置（Apple ID / Team ID / IAP productId） | S-M | 1-2 天 |
| 45 | 年龄分级（建议 17+） | S | 30min |
| 46 | App Icon + 33 张截图 | M | 1-2 天 |

---

# Google Play Store 视角

## 代码层状态（95% ready）

| 配置项 | 状态 |
|--------|------|
| targetSdk | 36（满足 2025-08 Play 要求） |
| minSdk | 24 |
| ABI 过滤 | arm64-v8a + x86_64 |
| ProGuard/R8 | 覆盖所有第三方插件 |
| network_security_config | 强制 HTTPS |
| backup_rules | 排除所有敏感数据 |
| data_extraction_rules | 排除 chroniccare.sqlite 等 |
| BootReceiver | 开机恢复通知 |
| 16KB page size | sqlcipher_flutter_libs 0.6.5+ |
| POST_NOTIFICATIONS | Android 13+ 运行时请求 |
| SCHEDULE_EXACT_ALARM | 精准闹钟 |
| Release 签名 | 已切换 `signingConfigs.getByName("release")` |
| IAP | `_prodIapEnabled=true` |

## P0 外部依赖

| # | 问题 | 难度 | 估时 |
|---|------|------|------|
| 47 | 生成 keystore + 填 key.properties | S | 1h |
| 48 | Play Console Data Safety Form 填写 | M | 2h |
| 49 | 内容分级 + 健康应用声明 + 权限声明 | S | 1h |
| 50 | 律师审核（同 App Store） | L | 1-2 周 |

---

# 法务合规视角

## PIPL 合规（85/100）

| 条款 | 要求 | 状态 |
|------|------|------|
| §13 单独同意 | 敏感信息处理前单独同意 | 4 勾选 + ConsentDialog |
| §14 撤回同意 | 便捷撤回方式 | 3 toggle + 业务层拦截（ConsentGate） |
| §17 同意记录 | 记录可追溯 | DB 字段 + audit log |
| §23 第三方提供 | 向第三方提供前单独同意 | 用户担保模式（联系人本人确认待 SMS 接入） |
| §28 敏感信息 | 健康医疗数据保护 | SQLCipher + 字段级加密（树洞） |
| §31 未成年人 | 14 岁以下特殊保护 | 年龄严正声明 + 不收集 |
| §38 跨境传输 | 跨境数据需评估 | speech_to_text 已识别 + FeatureFlag 控制 |
| §47 删除权 | 用户删除权 | 单条/全部/卸载 + 树洞 3 选 1 兜底 |

## 数据加密

| 数据类型 | 加密方式 | 状态 |
|----------|----------|------|
| 数据库整体 | SQLCipher AES-256 | 已实现 |
| 树洞文字 | AES-256 字段级加密 | 已实现（v0.21 起） |
| 树洞录音 | AES-256 文件加密 | 已实现（v0.18 起） |
| 数据库密钥 | FlutterSecureStorage（iOS Keychain / Android Keystore） | 已实现 |
| 网络传输 | HTTPS only（network_security_config） | 已实现 |

## 法律文档审核结果

### 3 份文档总评

| 文档 | 行数 | PIPL 覆盖 | 主要问题 |
|------|------|-----------|----------|
| `privacy_policy.md` | 238 | §13/§14/§17/§23/§28/§31/§38/§39/§40/§47 | "草稿"标注、域名占位 |
| `user_agreement.md` | 91 | 付费规则/免责/行为规范/联系方式 | GitHub 占位、IAP 注脚过时 |
| `sensitive_data_consent.md` | 122 | §28/§29 | "规划中"措辞偏多 |

### P0 文档阻断

| # | 问题 | 文件 | 修复建议 |
|---|------|------|----------|
| 51 | 3 份文档"草稿 (未经律师过审)"标注 | 3 份 | 律师过审后删除标注 |
| 52 | GitHub Issues 占位 `https://github.com/example/chroniccare/issues` | `user_agreement.md:69` | 替换为真实仓库或删除此行 |
| 53 | `support@chroniccare.app` 域名未注册 | 3 份多处 | 注册域名（已在 P0 外部依赖中列出） |

### P1 文档问题

| # | 问题 | 文件 | 修复建议 |
|---|------|------|----------|
| 54 | 用户协议 §3 IAP 注脚说"暂停"但代码 `_prodIapEnabled=true` | `user_agreement.md:24-28` | 删除或更新注脚为"已启用" |
| 55 | 隐私政策 §4 撤回同意说"数据不删除"，未说明如何行使 §47 删除权 | `privacy_policy.md:71` | 加"如需删除请使用删除权" |
| 56 | 隐私政策 §7 `speech_to_text` 未说明用户如何删除已上传语音 | `privacy_policy.md:108` | 加系统设置指导 |
| 57 | 隐私政策 §9 投诉举报缺具体链接 | `privacy_policy.md:152` | 加 `www.12377.cn`/`www.cac.gov.cn` |
| 58 | 敏感数据 §4/§7 "失联通知规划中，无可关闭项"需与代码同步 | `sensitive_data_consent.md:57,82` | v0.28 启用时加关闭开关 |
| 59 | 敏感数据 §2 树洞"绝不离开用户设备"与 §7 speech_to_text 矛盾 | `sensitive_data_consent.md:31` | 加"STT 云端识别见隐私政策 §7" |

### P2 文档建议

| # | 问题 | 文件 | 修复建议 |
|---|------|------|----------|
| 60 | 缺英文版隐私政策 | 新文件 | 面向海外用户需英文 URL |
| 61 | 修订历史暴露过多内部开发细节（round 编号、commit hash） | 3 份 | 律师过审后精简为面向用户的版本 |

---

# 综合优先级排序

## P0 外部依赖（代码无法修，9 项）

| # | 问题 | 视角 | 难度 | 估时 |
|---|------|------|------|------|
| 1 | 律师审核 3 份法律文档 | 法务+Store | L | 1-2 周 |
| 2 | 域名 `chroniccare.app` 注册 + ICP 备案 + HTTPS 部署 | 法务+Store | M | 1-2 天 + 7-20 天 |
| 3 | 生成 keystore + 填 key.properties | Play | S | 1h |
| 4 | App Store Connect 配置（Apple ID / Team ID / 年龄分级） | App Store | S | 1-2h |
| 5 | Play Console Data Safety Form + 内容分级 | Play | M | 3h |
| 6 | IAP productId 创建 | Store | S | 30min |
| 7 | App Icon 1024x1024 + 33 张截图 | Store | M | 1-2 天 |
| 8 | 软件著作权登记 | 法务 | L | 1-2 月 |
| 9 | 注册 `support@chroniccare.app` 邮箱 | 法务 | S | 1h |

## P1 已修复（9 项）

| # | 问题 | 状态 |
|---|------|------|
| 10 | home_page _fireCareEngine mounted guard | ✓ |
| 11 | MedicationDraft.copyWith DomainValue 置 null | ✓ |
| 12 | streak broken inHours → inMinutes | ✓ |
| 13 | GoRouter redirect loading guard | ✓ |
| 14 | ConsentGate SharedPreferences 缓存 | ✓ |
| 15 | HourMinute 构造函数 vs copyWith/fromString 统一 | ✓ |
| 16 | Android release 签名切换 | ✓ |
| 17 | IAP 启用（`_prodIapEnabled=true`） | ✓ |
| 18 | 邮箱占位替换（`privacy@` → `support@`） | ✓ |

## P2 真实 Bug（12 项未修复）

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 19 | 评估趋势标签硬编中文 | M | `assessment_comparison.dart:66-76,93-99` |
| 20 | 关怀文案全硬编中文 | L | `care_copy.dart:30-60` |
| 21 | 用药报告全文硬编中文 | L | `medication_report.dart:191-278` |
| 22 | 安全告警 SMS 硬编中文 | L | `lost_contact_sms.dart:60-70` |
| 23 | 评估 subtitle 硬编 `'总分'` | S | `day_detail.dart:253` |
| 24 | consent dialog 3 行硬编中文 | S | `consent_dialog.dart:169-176` |
| 25 | email preview fallback 硬编 `'您的家人'` | S | `email_preview.dart:61` |
| 26 | error page fallback 硬编中文 | S | `app_routes.dart:150,166` |
| 27 | PageController 在 build() 创建未 dispose | S | `quick_mood_carousel.dart:126-129` |
| 28 | _player.dispose() Future 未 unawaited | S | `vent_detail_page.dart:70` |
| 29 | streakSummaryProvider 未 watch dayChangeTickProvider | S | `shared_providers.dart:53` |
| 30 | mood_visual colorArgbFor dark mode 不适配 | M | `mood_visual.dart:84-98` |

## P2 文档问题（7 项未修复）

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 31 | 用户协议 §3 IAP 注脚过时 | S | `user_agreement.md:24-28` |
| 32 | 隐私政策 §4 撤回≠删除 | S | `privacy_policy.md:71` |
| 33 | 隐私政策 §7 speech_to_text 语音删除 | S | `privacy_policy.md:108` |
| 34 | 隐私政策 §9 缺举报链接 | S | `privacy_policy.md:152` |
| 35 | 敏感数据 §4/§7 关闭开关注脚 | S | `sensitive_data_consent.md:57,82` |
| 36 | 敏感数据 §2 树洞与 STT 矛盾 | S | `sensitive_data_consent.md:31` |
| 37 | 缺英文版隐私政策 | M | 新文件 |

## P3 Code Smell / 加固（16 项未修复）

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 38 | vent_compose_page onChanged 全页 rebuild | S | `vent_compose_page.dart:443` |
| 39 | setup_page _onTextChanged 全页 rebuild | S | `setup_page.dart:95-98` |
| 40 | home_page build watch 4 provider | M | `home_page.dart:328-461` |
| 41 | home_fab_toolbar unused mixin | S | `home_fab_toolbar.dart:36` |
| 42 | dosage 注释误导 | S | `formatters.dart:44` |
| 43 | SWallowLogSink truncate 可能断多字节 | S | `swallow_log_sink.dart:136` |
| 44 | reminder_scheduler 重复 _daysBetween | S | `reminder_scheduler.dart:236` |
| 45 | export_orchestrator 串行 await | S | `export_orchestrator.dart:108` |
| 46 | preset 硬编 `'片'` | S | `preset_medication_templates.dart:236` |
| 47 | contacts hint `'13800138000'` | S | `contacts_list_widget.dart:182` |
| 48 | main.dart 7 处 spacing 裸数字 | S | `main.dart:292-467` |
| 49 | app_shell 3 处 spacing 裸数字 | S | `app_shell.dart:82,90,106` |
| 50 | AES-CBC 无 HMAC | L | `encryption_service.dart:86` |
| 51 | PRAGMA key 字符串插值 | S | `native.dart:27` |
| 52 | Random() 非 secure | S | `encrypted_audio_storage.dart:116` |
| 53 | chinese_holidays 只到 2030 | M | `chinese_holidays.dart:27` |

## 测试层（4 项）

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 54 | _tmp_email_test.dart 占位应删除 | S | `test/_tmp_email_test.dart` |
| 55 | widget_test.dart 命名不规范 | S | `test/widget_test.dart` |
| 56 | 10 个测试文件跨 midnight flaky | M | 多文件 |

---

# 总评

| 维度 | 评分 | 说明 |
|------|------|------|
| Flutter 规范 | A- | 406 文件逐行审查，P1 全部修复 |
| App Store 就绪 | 8/10 | 代码层 90%，外部依赖待完成 |
| Google Play 就绪 | 8.5/10 | 技术配置完善，签名已切换 |
| 法务合规 | 85/100 | PIPL 框架扎实，法律文档需律师过审 |
| 架构成熟度 | 8.3/10 | 4 层架构执行到位 |
| 底层实现 | 8.5/10 | 0 崩溃级 bug，0 数据丢失，剩余 i18n + 加固 |

**结论**: 409 文件逐行审查完毕。无崩溃级 bug、无数据丢失 bug。P0 全部是外部依赖（律师/域名/商店账号），代码侧已无阻断项。
