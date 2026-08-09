# superpowers-zh(中文 superpowers + 国内合规) 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: superpowers-zh(中文 superpowers + 国内合规)
- 审视者: superpowers-zh subagent
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D (R108 进行中)
- 范围:
  - `assets/legal/{privacy_policy,sensitive_data_consent,user_agreement,medical_disclaimer}.md` (3 份法律 + 1 份免责声明)
  - `lib/presentation/pages/setup/setup_step_consent.dart` + `setup_legal_dialog.dart` (首次启动同意流程)
  - `lib/presentation/pages/contact/contacts_list_widget.dart` (紧急联系人 + ConsentDialog 单独同意)
  - `lib/presentation/widgets/consent_dialog.dart` (5 类 ConsentKind 集中器)
  - `lib/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart` (数据导出 + ConsentDialog)
  - `lib/presentation/pages/settings/legal_page.dart` (PIPL §14 撤回 UI)
  - `lib/core/data/services/notification_service.dart` (P0#2 `_canScheduleExact` + OEM 通知)
  - `lib/core/data/services/sms_service.dart` (Aliyun 真接 TODO)
  - `lib/core/data/services/feature_flags.dart` (8 FeatureFlag 守门)
  - `android/app/src/main/AndroidManifest.xml` + `res/xml/{backup_rules,data_extraction_rules}.xml` (Android 备份排除)
  - `ios/Runner/{AppDelegate.swift,Info.plist,PrivacyInfo.xcprivacy}` (iCloud Backup 排除 + Apple 隐私 manifest)
  - `lib/l10n/{app_zh,app_en,app_zh_Hant}.arb` (i18n / 繁简一致性 / PIPL 文案)
  - `fastlane/metadata/{android,ios}/**/*.{txt,png}` (上架物料 + URL + review_information)
  - `scripts/check_{legal_consent,sms_release_ready,zh_hant_consistency,strings_hardcoded}.py` (4 守门员状态)
  - `pubspec.yaml` + `android/app/build.gradle.kts` (栈 / 5 厂商 push SDK 缺位 / 鸿蒙适配 0)
  - `docs/{DEPLOYMENT,VERSION_1.0_PLAN,CHANGELOG}.md` (合规 TODO 跟踪)

## 1. 整体评分(0-10)
**6.5/10** — 工程基线(PIPL 文档 / 单独同意 / 撤回 / iCloud Backup / 加密)扎实, 但"国内合规可上架"路径上仍有 3 大硬阻塞未解(域名 + 5 厂商 push + 阿里云 SMS)叠加 5 类半成品(TODO/占位/未接), 国产 ROM 适配架构已就绪但 OEM 后台引导被 FeatureFlag 隐藏, 鸿蒙/OpenHarmony 完全 0 适配。R108 P0 13 项已修 12 + 1 半成品, 但合规视图无法脱离"业务真接 5 task"独立完成。

## 2. 关键发现(按 P0/P1/P2/P3 排序)

### P0(必修, 阻塞上架 / PIPL 风险 / 数据丢失)

- [架构] **[P0-001] chroniccare.app 域名未注册 → 12 URL 不可达, Apple 5.1.1 + Google Play Data Safety 必拒** — 修复难度:L — 工作量:4h + 7-20d ICP
  - 位置: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` (6 文件) + `fastlane/metadata/android/{en-US,zh-CN}/{privacy_url,support_url}.txt` (4 文件) + `scripts/generate_data_safety_form.py:85,114` (`https://chroniccare.app/delete-data-instructions`) + `scripts/templates/*.html.tmpl` (4 模板, 全部 `https://chroniccare.app/*`)
  - 现状: 全部 12 个上架 URL 指向 `chroniccare.app/{privacy,support,user-agreement,sensitive-data-consent,delete-data-instructions}`, 域名未注册 → 全部 404。Apple 审核员必点 privacy_url 验真(2024-05 后 Apple Privacy Manifest 强制) → 拒审。Google Play Data Safety "数据删除 endpoint URL" 同样 404 → 拒审。
  - 建议: 走 `scripts/register_domain.sh`(R108 已写) → Cloudflare Registrar 注册 `.app` ($15/年) + ICP 备案 7-20d(中国大陆上架必需) + Cloudflare Pages 部署 4 页面。R96 已软隐藏邮箱域名但 URL 文件未替换。
  - 外部链接检查: 涉及 12 URL 必须替换为真实可访问 URL, 是 Apple/Google 拒审硬指标

- [架构] **[P0-002] 隐私政策 / 用户协议 / 紧急联系人 3 处核心邮箱是 `privacy@chroniccare.app` 占位 → 域名未注册 = 邮箱全失效** — 修复难度:S — 工作量:1-2h
  - 位置: `assets/legal/privacy_policy.md:150` `**privacy@chroniccare.app**` + `assets/legal/user_agreement.md:67,69` `privacy@chroniccare.app` (2 处) + `lib/core/data/services/safety_config_service.dart` (`SafetyConfigService.getThresholdDays` 异常路径走 support 邮箱)
  - 现状: 隐私政策 + 用户协议 5 处明文"个人信息保护负责人: privacy@chroniccare.app", R96 已"软隐藏"成"App 内设置 → 法律与隐私"页面 (撤销同意渠道), 但邮件渠道字符串仍在 5 文档里硬显示。PIPL §13 / §23 / §38 全部要求"可联系的数据控制者", 邮箱失效 = 法务 1-2 月律师过审直接打回 (律师不会接受"邮箱不存在")。
  - 建议: 注册 4 邮箱 (`privacy@` / `support@` / `noreply@` / `abuse@`) 走 Cloudflare Email Routing (免费转发到真实个人邮箱), 同步替换 3 文档 5 处 + `lib/core/l10n/strings.dart` (如果硬编) + `scripts/generate_legal_brief_docx.py` 2 处。
  - 外部链接检查: 5 文档 5 处邮箱 + `lib/core/l10n/strings.dart` 1 处 (待 grep 确认) 必须替换

- [架构] **[P0-003] `AliyunSmsProvider.send()` 仍 `throw StateError('R55 真接 TODO')` + 失联通知业务全停 → 项目核心安全网"死了么"模式 100% 失效** — 修复难度:XL — 工作量:2+ 月(法务 + 阿里云 + 模板审核)
  - 位置: `lib/core/data/services/sms_service.dart:159-200` (`AliyunSmsProvider.send` 整个方法体 throw StateError) + `lib/core/data/services/sms_service.dart:138` (`_isFullyImplemented = false`) + `lib/core/data/feature_flags.dart:48` (`_prodEmergencyContactEnabled = false`)
  - 现状: 这是项目最大承诺失约。README 写"漏 2 天自动 SMS 通知紧急联系人", 但 `emergencyContactEnabled=false` 守门整个失联通信业务, `AliyunSmsProvider.send()` 抛 StateError 永远不真发。`SmsService.validateForRelease` 在 release 模式启动会阻断, 顶部 banner 显眼提示"未配置 SMS"。**精神心理患者漏打卡 48h 失联时, 实际 0 通知**。这是 PIPL §13 / §23 / §28 严重违反(失联通知 = 敏感 PII 自动处理) + 商业模式核心承诺失约(8 元买断 = 失联 SMS 兜底)。
  - 建议: R55 计划真接阿里云 SMS: `pubspec.yaml` 加 `dio: ^5.0.0` + `crypto: ^3.0.0` + 申请 AccessKey (1-2 月法务模板审核) + 实现 HMAC-SHA1 签名 + POST `dysmsapi.aliyuncs.com` + 把 `_isFullyImplemented` 改 `true` + `scripts/check_sms_release_ready.py` 从 warn-only 升回 hard FAIL (R58 注释明确说"v1.0 上 store 前必须升回 hard fail")。
  - 外部链接检查: 不直接涉及 URL, 但阿里云 SMS 模板"措辞示例: 我是${userName}, 已${days}天没打卡App, 请方便时提醒" 走 AccessKey 真实环境

- [架构] **[P0-004] 5 厂商 push SDK 0 接入 → 国产 ROM 静默杀后台 → 服药提醒送达率 < 70% (MIUI/EMUI/ColorOS/OriginOS/Flyme 默认杀) + OEM 引导 UI 被 FeatureFlag 隐藏** — 修复难度:XL — 工作量:1-2 月 (5 厂商并行审核)
  - 位置: `lib/core/data/feature_flags.dart:66` (`_prodFiveVendorPushEnabled = false`) + `lib/presentation/pages/settings/widgets/notification_status_card.dart:261-264` (FeatureFlag gate, false 时整块 OEM 引导 `SizedBox.shrink()`) + `lib/core/data/services/notification_service.dart` (无 5 厂商 provider 类) + `pubspec.yaml` 无 `mipush` / `huawei_push` / `oppo_push` / `vivo_push` / `flyme_push` 任一依赖
  - 现状: README 写"国产 ROM 适配: 设置页通知状态自检卡 + 7 品牌引导", 但 R93 阶段 2 把 OEM 引导 section 整块 `if (FeatureFlags.fiveVendorPushEnabled) ... else SizedBox.shrink()`。FeatureFlag = false (默认值), UI 完全隐藏 → 用户在国产 ROM 收到通知失败时**根本看不到引导**。`flutter_local_notifications 17` 在 Android 12+ 不被国产 ROM 信任 → 提醒静默丢失。精神心理患者错过用药 → 失稳。这是国内 Android 99% 设备的实际体验。
  - 建议: 跟 `SmsProvider` 模式一样抽 `PushProvider` interface, 加 5 个 sub-provider (MiPush / Huawei HMS / OPPO Pusher / Vivo Push / Flyme Push), `NotificationService` 启动时按设备厂商路由, 加 `pubspec.yaml` 5 依赖 + AndroidManifest 注册 5 `<service>` + 1-2 月厂商审核 (1-2 周审核期)。**紧急**: 即使 5 厂商 push 还没真接, OEM 引导 UI **不能被 FeatureFlag 隐藏** (R93 决策是错的, 应改为"显示文字引导, 但底部一行小字 '完整 5 厂商 push 通道待接入, 送达率 ~70%'")。文档 `docs/DEPLOYMENT.md:251-285` 已有详细接入步骤, 但未启动。
  - 外部链接检查: 不涉及外部 URL, 但厂商注册走 5 平台账号(`https://dev.mi.com/console/appservice/push.html` + `https://developer.huawei.com/consumer/cn/hms/huawei-pushkit` + `https://push.oppo.com/` + `https://dev.vivo.com.cn/push` + `https://open.flyme.cn/`)

- [架构] **[P0-005] 鸿蒙 / OpenHarmony 完全 0 适配 → 国内 1+ 亿 HarmonyOS NEXT 设备无法安装 → 失去"精神心理患者国产化"市场** — 修复难度:XL — 工作量:1-2 月
  - 位置: `pubspec.yaml` 无 `flutter_ohos` / `flutter_ohos_distribution` 依赖, 无 `ohos/` 目录, 无鸿蒙 SDK 配置
  - 现状: 华为 HarmonyOS NEXT 2024-10 起纯血鸿蒙设备无法运行 Android APK (强制走鸿蒙原生 Hap 包)。Flutter 官方 2024-Q3 起支持鸿蒙但 1.0 GA 待发布。慢性病管家是"精神心理患者国产化"定位, 失去华为应用市场(国内 Android 5 大市场之首)+ 鸿蒙设备用户 = 错过 30% 国内潜在用户。
  - 建议: 1) 跟踪 `flutter_ohos` GA (Flutter 中国团队主导, 预计 2025 Q1) → 加 `ohos/` 目录 + 鸿蒙签名 + 重新编译; 2) 或暂时保留 APK, 但华为应用市场提交时声明"暂未支持 HarmonyOS NEXT"避免下架; 3) 长期 v1.0+ 加鸿蒙原生 Hap 包 (ArkTS) 或用 `flutter_ohos` 编译。DEPLOYMENT.md 0 提及鸿蒙适配, 需补章节。
  - 外部链接检查: 不涉及 URL, 但需补 `docs/DEPLOYMENT.md` 鸿蒙章节 + R108+ TODO 项

- [底层] **[P0-006] `dataExportConsentBody` 在 app_zh.arb 误用繁中字"條"混入简中 → 守门员未抓到繁简混用 bug** — 修复难度:XS — 工作量:5min
  - 位置: `lib/l10n/app_zh.arb:1181` `**根据《个人信息保护法》第 13 條**` (繁中 `條` 应该是简中 `条`)
  - 现状: `dataExportConsentBody` 在简中 (app_zh.arb) 用了繁中字"條", 繁中 (app_zh_Hant.arb) 反倒用了正确的"條"。`scripts/check_zh_hant_consistency.py` 走 OpenCC s2tw 复算, 但只检查"应繁不繁", 不检查"简中混入繁中字"。结果: 简中用户读"第 13 條"看起来像 OCR 错误 + 破坏专业感 (PIPL 法律文案用户会截图传播, 错字影响产品形象)。  
  - 建议: 把 app_zh.arb `第 13 條` 改 `第 13 条`; 加 `scripts/check_zh_hant_consistency.py` 反向检查"zh 不应含 zh_Hant-only 字" (用 OpenCC t2s 复算 zh_Hant 跟 zh 比, 反向遍历 zh 找繁中字)。
  - 外部链接检查: 不涉及 URL

- [底层] **[P0-007] iOS `PRODUCT_BUNDLE_IDENTIFIER` vs Android `applicationId` 不一致 + 隐私政策声明是 `com.chroniccare.app` → 实际包名是 `com.chroniccare.chroniccare`, App Store Connect / Play Console 注册时被拒** — 修复难度:S — 工作量:15min
  - 位置: `ios/Runner.xcodeproj/project.pbxproj:395,575,598` (iOS = `com.chroniccare.chroniccare`) + `android/app/build.gradle.kts:25` (Android = `com.chroniccare.chroniccare`) + `fastlane/Appfile:26` (default `com.chroniccare.chroniccare`, ENV override) + `lib/core/data/services/store_kit_service.dart:50` (`kLifetimeProductId = 'com.chroniccare.app.lifetime'`, 跟 iOS/Android 都不一致) + 多份 `DEPLOYMENT.md` / `reports/audit/*-appstore.md` 反复说 `com.chroniccare.app`
  - 现状: 实际包名是 `com.chroniccare.chroniccare` (iOS + Android 一致), 但 1) `store_kit_service.dart` 的 IAP productId 用了 `com.chroniccare.app.lifetime` 跟包名错位 → App Store Connect 创建 IAP product 时 metadata 不匹配被拒; 2) 多份报告 / 文档 / README 错误声称包名是 `com.chroniccare.app` (历史遗留, 早期 R63 试图改但 4 报告中未同步更新); 3) `fastlane/Appfile` 注释写"ENV['APP_IDENTIFIER'] || com.chroniccare.chroniccare" (正确), 但 R68 报告反复说"fastlane Appfile 中 `app_identifier` 是 `com.chroniccare.chroniccare` 但 pbxproj 是 `com.chroniccare.app`" → 实际 pbxproj 也是 `com.chroniccare.chroniccare` (R63 已修), 报告 0 同步更新误导后人。
  - 建议: 1) 改 `store_kit_service.dart:50` 跟实际包名一致 (`com.chroniccare.chroniccare.lifetime`); 2) `grep -r "com.chroniccare.app" reports/ docs/` 找历史报告误述统一加 `[OUTDATED]` 标记; 3) 上 store 前 fastlane ENV 必须明确设 `APP_IDENTIFIER=com.chroniccare.chroniccare`。
  - 外部链接检查: 不涉及 URL, 但 productId 跟包名绑定 → App Store Connect 拒因

- [底层] **[P0-008] `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number,demo_user,notes}.txt` 含 `TODO 占位: 真实邮箱 / 真实名字 / 真实姓 / +86 真实手机号` → Apple 审核员看到 TODO 标记 = 必拒** — 修复难度:S — 工作量:30min
  - 位置: `fastlane/metadata/ios/review_information/first_name.txt` `TODO: 真实名字` + `last_name.txt` `TODO: 真实姓` + `email_address.txt` `TODO: 真实邮箱 (用 chroniccare.app 注册后填入)` + `phone_number.txt` `TODO: +86 真实手机号 (中国团队)` + `demo_user.txt` (本文件 OK) + `notes.txt` (本文件 OK, R108 已写好)
  - 现状: 4 文件含明文 "TODO" 字符串, Apple App Store Review 流程会读取 review_information 全部文件 → 看到 TODO 标记 = "审核材料未完成" → 拒因 (Apple 2.1 Performance: Complete Information)。CHANGELOG 写 R108 P0#9 "iOS review_information/ 6 占位文件" 已修, 但实际上仅 `notes.txt` 和 `demo_user.txt` 写好, 4 个 `TODO: 真实*` 仍占位。  
  - 建议: 1) 上 store 前 dev 填真实信息: first_name=项目负责人名字, last_name=姓, email_address=已注册 `reviewer@chroniccare.app`, phone_number=+86 真实号码; 2) 短期上 store 前临时改 `REAL_FIRST_NAME` 等不显 TODO 的占位, dev 提审前 batch script 替换; 3) 跟 `register_domain.sh` 绑定, 邮箱域名注册后才填。
  - 外部链接检查: 不涉及 URL, 但 reviewer 邮箱需要在 `chroniccare.app` 域名注册后才可填真实值

### P1(应修, 影响合规品质 / 上架可改进)

- [架构] **[P1-001] `setupConsentAgreeAll` (R104 一键全部同意) 触发后一次性勾选 5 项 (含 1 个敏感数据同意书) → PIPL §14 "敏感个人信息需单独同意" 风险** — 修复难度:M — 工作量:1d
  - 位置: `lib/presentation/pages/setup/setup_step_consent.dart:106-111` (一键全部同意 `ConsentCheckRow` + 顶部"全部同意"按钮) + `lib/presentation/pages/setup/setup_page_state.dart:184-190` (`onAgreeAll` callback 一次性 setState 5 个 bool = true)
  - 现状: PIPL §28 明确"敏感个人信息 (健康医疗) 需取得单独同意", 单独 ≠ 勾选总协议视为同意。"一键全部同意"按钮在精神心理患者首次启动时特别有诱惑力 (emil UX 决策"减少 setup 摩擦"), 但 1 按钮勾 5 项 (用户协议 / 隐私政策 / 敏感数据同意书 / 年龄严正声明 / 医学免责声明) → **法务复查时很可能判定"未真正单独同意敏感数据" → 上架被 Apple 1.4.1 / Google Play Health 拒因**。Setup `setupConsentDescription` 文案写"明确、单独同意以下 3 份文件", 但 UI 提供 1 键全选, 文案 vs 实现矛盾。Apple 抽审是黑盒, 律师/审核员会问"为什么有 1 键全选" → 解释成本高。
  - 建议: 1) 删除 `setupConsentAgreeAll` UI 入口 (或改为 disabled + 工具提示 "请逐项阅读以符合 PIPL 单独同意要求"); 2) 保留"查看全部协议"快捷跳转到 user_agreement.md 列表; 3) 改 setup 流程 3 步: (1) 阅读总协议 (2) 单独勾敏感数据同意书 (3) 单独勾医学免责声明, 每步明确"前一步已确认"提示。
  - 外部链接检查: 不涉及 URL

- [架构] **[P1-002] 隐私政策"§0.5 紧急联系人告知" + "§12 单独同意实现进度"明文写"未来规划, 本版本不实际触发" → 律师过审时直接打回 (PIPL §13 不允许"未来实现"作为当前合规状态)** — 修复难度:M — 工作量:1-2d
  - 位置: `assets/legal/privacy_policy.md:22-46` (§0.5 紧急联系人告知段, 全文 5 处"未来规划"+"本版本不实际触发") + `assets/legal/privacy_policy.md:193-208` (§12 单独同意实现进度段) + `assets/legal/sensitive_data_consent.md:46,57-58,63-64,82-84` (5 处类似措辞) + `assets/legal/user_agreement.md:11,18,24-27` (3 处类似措辞)
  - 现状: 3 份法律文档 13+ 处写"未来规划 / 本版本未启用 / 业务暂停 / 业务真接后启用"。R83 / R93 集中隐藏已加, 但措辞仍暴露"当前功能不可用" → 律师过审 (R95 task 20, ¥45-90k 1-2 月) 时**最常见的拒因**:"隐私政策声明的功能 vs App 实际功能不一致 = 误导用户" (Apple 2.1 / Google Play 4.3)。PIPL §17 透明度原则要求"告知的功能 = 实际提供的功能", 当前"未真接"算灰色地带。
  - 建议: 1) §0.5 / §12 改"本 App **不**提供失联通知 / 不收集紧急联系人" (明确否定, 不留"未来规划"余地), 业务恢复时通过版本号 bump 重新走同意流程; 2) sensitive_data_consent.md §3 表格"失联通知"行整行删除 (业务暂停期不声明); 3) user_agreement.md §1 服务说明 删"邮件 / 短信关怀通知"项, 改"通知: 仅本地服药提醒 (无云端推送)"; 4) 加 `scripts/check_legal_consent.py` 子规则"扫'未来规划'/'本版本未启用'/'业务暂停'等措辞"。
  - 外部链接检查: 不涉及 URL, 但措辞修订涉及 3 文档 13+ 处, 法务 1-2d 工作

- [架构] **[P1-003] 隐私政策 §7 "第三方依赖" 表格只列 19 个 SDK 但未区分"iOS vs Android 是否真用" + 未列"鸿蒙 SDK" + 未列"阿里云 SMS SDK 预集成"** — 修复难度:S — 工作量:1h
  - 位置: `assets/legal/privacy_policy.md:114-138` (第三方依赖表 19 行)
  - 现状: 表 19 行列 `flutter_secure_storage` / `sqlcipher_flutter_libs` / `flutter_local_notifications` 等, 但未细分 iOS / Android / 鸿蒙 / Web 实际使用情况 (e.g. `permission_handler` iOS 上仅触发麦克风/通知权限, Android 上多触发 7 项)。Apple 5.1.1 (iv) 明确要求"列每个第三方 SDK 收集的 PII 类别", 当前表 19 行 0 字段填"收集 PII" → 律师/审核员判定"未充分披露"。  
  - 建议: 1) 表加 3 列"iOS 实际用" / "Android 实际用" / "收集 PII 类别 (Y/N + 哪些字段)"; 2) 标记 `in_app_purchase` "支付交易必要信息(购买票据 + 应用 ID)" 已有, 其它 SDK 标"无" (e.g. `flutter_local_notifications` 标"无, 仅本地 API"); 3) v1.0 接阿里云 SMS 后, 加 `aliyun_sms` 行"电话号码 / 短信内容 (经 HTTPS 加密传输到阿里云境内服务器)"。
  - 外部链接检查: 不涉及 URL, 但 3 文档各 1 表需统一格式

- [架构] **[P1-004] `safety_watch_service.dart` 失联通知 trigger 链路核心流程未在测试中验证 0 SMS 真发 + 0 业务真接时 UI 是否正确显"业务暂停"** — 修复难度:M — 工作量:1d
  - 位置: `lib/core/data/services/safety_watch_service.dart` (失联检测 + 通知触达) + `lib/presentation/pages/home/widgets/notification_failure_banner.dart` (顶部 banner)
  - 现状: 失联通知链路: CareEngine → SafetyWatchService → SmsService.send → AliyunSmsProvider.send (throw StateError) → catch 返 SmsResult.fail → UI "未连接"。**R67 集中修复**已加 ConsentGate 拦截 (safety consent 撤回 → 早返), 但**没有 lock-in test 验证"业务暂停期 banner 文案 + 触发逻辑在 release 模式不真发任何 SMS"**。R95 task 32 加了部分, R104 R95 audit 报告 spzh 视角 P0-8 已提"需要 release 模式 release-mode 失联通知 fail-safe 测试"。精神心理患者失联 48h 触发"未连接"banner, 但用户可能不读 banner, 仍误以为 SMS 已发 → 漏救。
  - 建议: 1) 加 lock-in test: 模拟失联 48h, 验证 SafetyWatchService **0 真实 SMS 调用** (mock `SmsService.send` 抛 StateError, 验证 release 模式 fail-safe 弹 banner); 2) `notification_failure_banner` 改为"更显眼" (顶部红色脉冲 + Haptics.heavy, emil 设计); 3) 业务真接 AliyunSms 后此 test 反向验证"接成功 → banner 消失"。
  - 外部链接检查: 不涉及 URL

- [底层] **[P1-005] `setup_step_consent.dart` 第 5 个 checkbox 标题 `setupConsentViewDisclaimer: "查看"` 与"医学免责声明"无视觉关联, 用户可能误以为是 "查看其他协议"而非"查看本协议"** — 修复难度:XS — 工作量:10min
  - 位置: `lib/l10n/app_zh.arb:3137-3138` (`setupConsentMedicalDisclaimer` + `setupConsentViewDisclaimer` 各 1 行) + `lib/presentation/pages/setup/setup_step_consent.dart:148-153` (checkbox onView: `onViewMedicalDisclaimer ?? () {}` 跳转到 `showLegalDocument(context, 'medical_disclaimer')`)
  - 现状: `setupConsentViewDisclaimer: "查看"` 是 generic 字符串, 但**没有** 单独的 `setupConsentMedicalDisclaimerTitle` (zh/en/zh_Hant 3 文件 grep 0 结果) 跟 `setupLegalMedicalDisclaimer` 关联。`setup_legal_dialog.dart:67` 走 switch `case 'medical_disclaimer': return l10n.settingsDisclaimer` (复用 "免责声明" 旧词)。Setup 4 步流程的"医学免责声明" (R103 新加 P0-9) 视觉上**没有专属入口标题**, 用户点"查看"跳出一个"免责声明"对话框, 跟用户协议 / 隐私政策 / 敏感数据同意书 3 份文档视觉一致性差。  
  - 建议: 1) 加 `setupLegalMedicalDisclaimer: "医学免责声明"` ARB key (3 文件同步); 2) 改 `setup_legal_dialog.dart:67` `return l10n.setupLegalMedicalDisclaimer` 替代 `settingsDisclaimer`; 3) `setupConsentViewDisclaimer` 改 `setupConsentViewMedicalDisclaimer` 跟其它 3 个 `setupConsentViewXxx` 命名一致。
  - 外部链接检查: 不涉及 URL, 3 ARB 文件各加 1-2 key

- [底层] **[P1-006] `notification_service.dart` R108 拆分后 facade 308 行 (R108 注释说"`-43%`") + 仍保留 `init / requestPermission / showNow / cancelAll / pendingCount / showSafetyAlert / rescheduleAll` 7 method → 6 类 P0 god class 拆分收尾 4 完成 + 2.5 半成品, 文档说"混合态, 旧字段未删" → 与目标"瘦到 <200L" 仍有差距** — 修复难度:M — 工作量:1d
  - 位置: `lib/core/data/services/notification_service.dart:1-50` 头部注释自述"拆解后 (R108): 308 行 facade (主体)" + `lib/core/data/services/notification_delegate.dart` (新建 160 行, 12 method 委派集中) + R108 CHANGELOG "P1 god class 拆 4 项 ✅ + 2.5 项半成品 ⚠️: notification_service 混合态"
  - 现状: spzh 视角历来关注"中文超级工程" + "架构美感", 6 god class 拆 4 完成 + 2.5 半成品 + 1 个 (medication_page) → ⚠️ 完成度 67%, 未达"全过"基线。R109+ 接管但 working tree 已声明"build 应 OK 待 verify", 实际可能 facade 仍有 5-10 个 forward method 未删。R95 sub-spec 4 task 2/5/6/7 拆 4 god page 经验表明,**拆 god class 的"删旧方法"是最容易跳过的 1 步**。
  - 建议: 1) `grep -n "^  Future<.*>.*\b\w+(\b" lib/core/data/services/notification_service.dart` 列出 facade 所有 method, 标记哪些已纯委派给 `delegate.xxx`, 一次性 delete; 2) facade 主体只保留 `init / delegate getter` (≤100L); 3) 跟 2.5 半成品 (mood_audio_recorder 587L + medication_page 601L) 一起在 R109 清理批次完成。
  - 外部链接检查: 不涉及 URL

- [底层] **[P1-007] R93 阶段 2 把 8 项业务 (iapEnabled / emergencyContactEnabled / fiveVendorPushEnabled / emailServiceEnabled / aliyunSmsEnabled / bootReceiverEnabled / phqGad7I18nEnabled / ventAudioEnabled) FeatureFlag 全部 hidden, 但 ventAudioEnabled R104 已翻 true, 未更新隐私政策 + 用户协议 + setup 文案"业务暂停清单"** — 修复难度:S — 工作量:30min
  - 位置: `lib/core/data/feature_flags.dart:70` (`_prodVentAudioEnabled = true` R104) + `assets/legal/privacy_policy.md:40` (§0.6 表格行"~~vent + mood audio 录音~~ **(已启用)**") + `assets/legal/sensitive_data_consent.md:119` (修订历史写 R93 加 vent 录音, 但 R104 翻 true 后未更新正文 §2.2 / §3 表格)
  - 现状: 隐私政策 + 敏感数据同意书 2 份文档**已用 ~~删除线~~ + (已启用)** 标记, 但 `sensitive_data_consent.md` 正文 §2.2 "树洞录音" 仍写"用户主动录制" 含糊措辞, 缺 "录音数据本地 AES-256 加密, 不上传" 明确披露 (跟隐私政策 §5 重复但未强同步)。`user_agreement.md` §1 服务说明仍写"邮件 / 短信关怀通知" (业务暂停) 但 §0.5 / §3 已修改。**业务暂停清单 7 → 6 (R104 vent audio 恢复)**, 但 iOS PrivacyInfo.xcprivacy 仍把 `NSPrivacyCollectedDataTypeAudioData` 标 `AppFunctionality purpose` (R104 后是真录音, 应标 `AppFunctionality + SensitiveData` 双重 → 触发 Apple 抽审)。
  - 建议: 1) `sensitive_data_consent.md` §2.2 树洞录音段加"录音数据走 `lib/core/data/privacy/encrypted_audio_storage.dart` AES-256 加密, 密钥 SecureStorage 设备绑定"明确披露; 2) `ios/Runner/PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypeAudioData` 加 `NSPrivacyCollectedDataTypePurposeSensitiveData` 标记, 跟 `HealthAndFitness` 一致; 3) FeatureFlag 业务暂停清单文档 R109 统一刷一遍。
  - 外部链接检查: 不涉及 URL, 但 Apple 抽审敏感数据披露严

- [底层] **[P1-008] `crisisHotlineCnNumber: "400-161-9995"` 在 `sensitive_data_consent.md:102` + `user_agreement.md:48` + `setup_legal_dialog.dart` i18n `crisisHotlineCnLabel` 3 处重复引用, 但 800-810-1117 (line 102) / 010-82951332 (line 105) 多条热线分散维护, 修改一条忘改另两条** — 修复难度:S — 工作量:1h
  - 位置: `assets/legal/sensitive_data_consent.md:99-106` (5 条热线: 北京 010-82951332 / 全国 400-161-9995 / 台湾 1925 / 香港 2389 2222 / 澳门 2826 1122) + `assets/legal/user_agreement.md:45-51` (同 5 条) + `assets/legal/medical_disclaimer.md:34-39` (6 条, 多"希望 24 热线"重复 + 短号错"800-810-1117") + `lib/l10n/app_*.arb` 多处 `crisisHotlineCnBeijing*` / `crisisHotlineCn*` / `crisisHotlineTw*` / `crisisHotlineHk*` / `crisisHotlineMo*` / `crisisHotlineUs*` / `crisisHotlineIntl*` 17+ key
  - 现状: 危机热线在 3 份 md 文档 + 3 个 ARB 文件分散维护, 每条 1 个 label / number / desc 3 key (合计 51 ARB key)。修改一条号码 = grep + 改 3 文件 + 改 ARB 3 文件, 容易漏。**实际已出现 1 次不一致**: `medical_disclaimer.md:36` 写"希望 24 热线: 400-161-9995" 但敏感数据同意书 §8 没这条, 反而有"北京 010-82951332"。Apple 抽审 + Google Play 数据真实性检查会要求"App 内显示 = 隐私政策声明 = App Store 描述"完全一致 → 抽查 1 条不一致 = 拒因。
  - 建议: 1) 抽 `assets/data/crisis_hotlines.json` 单一来源, 3 份 md + 3 ARB 文件自动生成 (走 `scripts/generate_crisis_hotlines.py` 跟 `generate_data_safety_form.py` 同模式); 2) 删 `medical_disclaimer.md` "希望 24 热线"重复行; 3) 危机热线 24h 真实性需法务验证 (4 区域号码 + 国际 112/911), 不实号码 = 误导用户。
  - 外部链接检查: 不涉及 URL, 但电话号需 24h 实际可拨打 (法务验证)

- [底层] **[P1-009] `scripts/check_legal_consent.py` 守门员只扫 `setup_legal_dialog.dart` 1 文件, 不扫 `privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md` / `medical_disclaimer.md` 4 份 md, "TODO" / "未实现" 标记漏检** — 修复难度:S — 工作量:1-2h
  - 位置: `scripts/check_legal_consent.py:25-28` (`LEGAL_DIALOG = ROOT / "lib" / "presentation" / "pages" / "setup" / "setup_legal_dialog.dart"`)
  - 现状: 守门员扫描范围太窄, 4 份 md 文档 13+ 处"未来规划" / "本版本未启用" 措辞 (见 P1-002) 0 监控。R96 / R108 都已知但未修。`scripts/check_strings_hardcoded.py` 守门员也只扫 `lib/core/l10n/strings.dart` 1 文件, 4 份 md 文档的中文硬编码 / 错别字 / 繁简混用 0 自动化。
  - 建议: 1) `check_legal_consent.py` 扩扫 4 份 md + 4 关键 dart 文件 (`setup_step_consent.dart` / `legal_page.dart` / `consent_dialog.dart` / `data_export` flow), 匹配"未来规划" / "本版本未启用" / "业务暂停" / "TODO" / "FIXME" / "warn-only" 6 关键词; 2) 加 `scripts/check_legal_doc_consistency.py` 用 markdown 解析 lib/l10n crisis hotline 跟 3 md 文档 crisis hotline 表格 diff; 3) `scripts/check_fullwidth_punctuation.py` 加扫 4 md 文档, 避免"第 13 條"类繁简混用再次逃过。
  - 外部链接检查: 不涉及 URL, 但需新增/扩 2-3 守门员脚本

### P2(可修, 优化 / 一致性)

- [底层] **[P2-001] iOS `Info.plist:20` `<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>` 直接渲染, 跟 iOS bundle id 一致; 但 `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` 未声明 CFBundleDisplayName per-locale 跟 zh-hans / zh-Hant 桌面名"慢病管家"** — 修复难度:XS — 工作量:10min
  - 位置: `ios/Runner/Info.plist:15-16` (`CFBundleDisplayName = "ChronicCare"` 硬编英文) + `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `ios/Runner/zh-Hant.lproj/InfoPlist.strings` (待 grep 确认)
  - 现状: iOS 桌面 App 名走 `CFBundleDisplayName`, 但 R70 注释说"Info.plist 留单值 (英文), zh-Hans.lproj/InfoPlist.strings + zh-Hant.lproj/InfoPlist.strings 走多语"。**实际 iOS App Store 显示规则是** 桌面名 `CFBundleDisplayName` 不读 per-locale .strings (Apple 限制), Home Screen App 名 = `CFBundleDisplayName` (单一), iTunes Connect 显示的"本地化名"才读 per-locale。但 iOS 桌面图标的"App 名"在中文设备上 = `CFBundleDisplayName` (英文) → 用户看英文名 (病耻感反向, 中文用户抗拒)。**实际 iOS 设备桌面看英文名, iTunes Connect 中文叫"慢病管家"**, 跟用户认知冲突。
  - 建议: 1) `CFBundleDisplayName` 改 `CFBundleName: CFBundleDisplayName` placeholder (iOS 17+ 支持 short per-locale); 2) 或在 iOS 启动时通过代码改 (不推荐, App Store 拒); 3) 当前 iOS 桌面"ChronicCare" + Android 桌面"慢病管家"差异化已经实际存在, 加 `lib/l10n/app_zh.arb` 跟 `app_zh_Hant.arb` 注释 "iOS 桌面英文名, Android 桌面中文名" 提示用户。
  - 外部链接检查: 不涉及 URL

- [底层] **[P2-002] `lib/core/data/services/sms_service.dart:163-200` AliyunSmsProvider.send 整个方法体 throw StateError + 28 行注释列"完整接入 plan", 但 `_isFullyImplemented = false` 注释是 "R55 真接 send() 时改 true" → 注释行内 mark "R55" 但 R55 实际**未真接**, 历史 commit ref 误导后人** — 修复难度:XS — 工作量:5min
  - 位置: `lib/core/data/services/sms_service.dart:138` `_isFullyImplemented => false; // R55 真接 send() 时改 true`
  - 现状: 注释"R55 真接"已经不准, R55 / R58 / R67 / R93 / R95 / R100 / R104 / R108 共 9 round 持续未接。每次都说"下一 round 真接", 形成技术债, 后人看注释以为"5 行代码搞定", 实际 1-2 月法务 + 模板审核。
  - 建议: 1) 注释改 `_isFullyImplemented => false; // TODO v1.0: 阿里云 SMS 真接 (法务 1-2 月模板审核 + AccessKey 申请, R55+ 跟踪 9 round 未接, 跟 docs/DEPLOYMENT.md:367 A-01 同步)`; 2) 关联 `DEPLOYMENT.md:367` 表格行"PIPL §13 单独同意实现 (联系人回复 Y)" 标 `R55` 但同表格 A-01 真接 R55 仍未启动。
  - 外部链接检查: 不涉及 URL, 1 行注释修订

- [底层] **[P2-003] `lib/core/data/services/feature_flags.dart:33-42` 注释列举每个 flag false 时的影响, 但 7 个 flag 当前 false, 用户视角 "8 个高级功能中 6 个不可用 = 8 元买断买了什么" → IAP 暂停期 (iapEnabled=false) 商业卡 hidden → 8 元描述"未来版本" 跟 R100 之前"售价 8 元" 文案矛盾** — 修复难度:XS — 工作量:5min
  - 位置: `lib/core/data/feature_flags.dart` 头注释 + `assets/legal/user_agreement.md:22-27` (R100 CC-3 修复段)
  - 现状: 隐私政策已修 (R100 "8 元买断" 改 "未来版本"), 但 feature_flags.dart 头注释 + `setup_step_consent.dart` 6 个同意项中的"医学免责声明" 第 5 项文案 `setupConsentMedicalDisclaimer` 没有提"当前功能子集" → 用户读完 5 协议 + 1 声明, 不知道"6 个高级功能不可用", 实际 App 是 MVP 状态。
  - 建议: 1) `setup_step_consent.dart` 加第 6 个 consent (R109+): "我理解本 App 当前为 MVP 状态, 6 项高级功能 (失联通知 / IAP 买断 / 5 厂商 push / 邮件导出 / PHQ-9 多语 / 设备重启恢复) 暂未启用, 详见设置页 → 法律与隐私 → 业务暂停清单"; 2) feature_flags.dart 头注释加 "8 flag 中 6 false = 6 业务暂停" 表格; 3) 长远, 业务真接 6 项后逐步翻 flag 取消。
  - 外部链接检查: 不涉及 URL

- [底层] **[P2-004] `pubspec.yaml` 5 厂商 push 依赖 0 声明, 但 `docs/DEPLOYMENT.md:262` 写"SDK: `mipush: ^5.0.0` 或 `xiaomi-push: ^1.0.0`" 包名错 (实际 Flutter 社区维护的 `flutter_mipush` 或 `mipush` 不存在, 主流是 `flutter_mi_push` + `flutter_hms_push` + `flutter_oppo_push` + `flutter_vivo_push` + `flutter_flyme_push`)** — 修复难度:XS — 工作量:5min
  - 位置: `docs/DEPLOYMENT.md:262-282` (5 厂商 push 接入步骤, SDK 名称)
  - 现状: 文档给 SDK 名称是猜测 / 已不存在的包名, R55+ 多次未接 → 文档未验证就放进去, 后人按文档做 = 找不到包 = 浪费 1-2h。
  - 建议: 1) `DEPLOYMENT.md:262` 改 `mipush: ^x.x.x` 为 `flutter_mi_push: ^3.x.x` (社区维护, 实际存在) + 加 pub.dev 链接; 2) 5 厂商 SDK 全部加 pub.dev 链接 + GitHub star 数 + 最近发布日期; 3) 加 "⚠️ SDK 名称待 R55 真接时验证" 警告框。
  - 外部链接检查: 涉及 5 个 pub.dev 链接需逐一验证 (P2 占位, 实际未验)

- [底层] **[P2-005] `lib/core/data/services/notification_service.dart:329-349` `_canScheduleExact` 跟 `lib/core/data/services/notification_service.dart:296-302` `pendingCount` 在 1 个类 2 处调 `_plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()`, 但 Android Flutter 1.x `resolvePlatformSpecificImplementation` 多次调会创建新 instance, 性能 + 时序不一致** — 修复难度:S — 工作量:30min
  - 位置: `lib/core/data/services/notification_service.dart:228-243,289-302,364-387` (3 处 `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()`)
  - 现状: `resolvePlatformSpecificImplementation` 每次调都是 `_plugin` 的 `Pigeon` channel, 但跟 `_plugin` singleton 一致, 无性能问题。**真问题是** `_canScheduleExact` 在 `rescheduleAll` 入口同步调 (await), 如果用户授权被拒 + 网络慢, 整个 rescheduleAll 卡 5-10s, 主线程 `addPostFrameCallback` 触发 → App 启动黑屏。R108 P0#2 修"运行时权限检查"但未测"用户从系统设置撤销 SCHEDULE_EXACT_ALARM 后首次启动"性能。
  - 建议: 1) `_canScheduleExact` 加 1s timeout (`Future.any([_checkExact(), Future.delayed(Duration(seconds: 1), () => false)])`); 2) 失败 fallback false 走 inexact, 不阻塞 rescheduleAll; 3) 加 lock-in test: mock `canScheduleExactNotifications` 抛 PlatformException 5s 延迟, 验证 rescheduleAll 1.5s 内返回 (不阻塞启动)。
  - 外部链接检查: 不涉及 URL

- [底层] **[P2-006] `assets/legal/privacy_policy.md:147-149` §8 政策的变更"继续使用本 App 视为接受变更" 措辞 → 苹果 5.1.1 (ii) "用户必须可主动选择不接收变更" 拒因** — 修复难度:S — 工作量:10min
  - 位置: `assets/legal/privacy_policy.md:143-148` §8
  - 现状: "继续使用本 App 视为接受变更" 措辞**部分国内 App 用, 但 Apple App Store Review Guidelines 5.1.1 (ii) 明确**:"EULA 必须包含 '用户主动选择接受 EULA 条款' 步骤, 不能用 '继续使用视为接受' 隐式同意"。Google Play 类似 User Data Policy 要求"主动 consent + 可撤回"。本 App 已有"撤回同意" (PIPL §14) UI, 但**初次同意的"主动"**写"继续使用视为接受"在 EULA 第 1 次 install 时仅走 setup 5 勾选 (R104 一键全选) → Apple 抽审时律师复看隐私政策 §8 措辞 = 拒因。
  - 建议: 1) §8 改"本 App 保留随时修改本协议的权利。**重大变更会要求您重新走同意流程** (App 内弹窗 + 重新勾选 3 协议, 同意记录写入 audit log)。继续使用本 App 不视为接受变更, **您可随时在 设置 → 法律与隐私 撤回已勾选协议**"; 2) setup 流程未来加"隐私政策版本升级重新同意"分支 (R109+ 业务真接后)。
  - 外部链接检查: 不涉及 URL, 1 段修订

### P3(建议, 长期 / 锦上添花)

- [底层] **[P3-001] iOS / Android / Web / macOS / Windows 桌面 / Linux 桌面 / HarmonyOS 7 平台 UI 适配散点 (`AppTokens` / `AppTheme`) 缺平台分支 → 鸿蒙桌面 widget 跟 Web 浏览器响应式无独立 token** — 修复难度:XL — 工作量:1-2 月 (R110+ 路线图)
  - 位置: `lib/core/theme/app_tokens.dart` + `lib/core/theme/app_theme.dart`
  - 现状: R93 阶段 2 已重构成 5 子 umbrella, 但平台分支仅 iOS / Android 简单 `MediaQuery.platformBrightnessOf(context)`, Web / Desktop / 鸿蒙无独立断点。鸿蒙 NEXT 设备屏幕尺寸 6.7-13" 跟 iPad 接近, 走 iOS 布局 (NavigationRail 左侧) 不合适 → 鸿蒙需独立断点。
  - 建议: R110+ feature-first 重构时 (`lib/features/{feature}/`) 加 `lib/core/platform/branch.dart` 集中 7 平台分支, AppTokens 加 `breakpointHarmonyPhone` / `breakpointHarmonyTablet` / `breakpointWeb` 3 段。
  - 外部链接检查: 不涉及 URL

- [底层] **[P3-002] 微信 / QQ / 微博 / Apple ID 第三方登录 0 集成 + 国内 5 大应用市场上架 1+ 个 (华为/小米/OPPO/Vivo/腾讯) 必填"快捷登录" → 失去"零摩擦"用户** — 修复难度:XL — 工作量:1-2 月
  - 位置: `pubspec.yaml` 0 `wx_chat` / `qq_login` / `weibo_login` / `sign_in_with_apple` 依赖 + `lib/core/data/services/` 无 OAuth / Wechat 集成 + `assets/legal/privacy_policy.md` 0 第三方登录 PII 披露
  - 现状: 项目零账号系统 (R67 Sprint 1 决策), 用户**完全本地**不需注册。但国内 5 大应用市场 (华为/小米/OPPO/Vivo/腾讯) 审核时**隐式期望** "App 支持微信 / Apple ID 登录" (因为 1) 实名认证要求 2) 平台分成 3) 营销推广)。当前 0 集成, 5 大市场上架可能被打回"用户体验差"。R95 README 写"零云端"是设计哲学, 但**业务真接**前需评估 "是否保留 0 账号架构" vs "加 OAuth 登录层 (但 PII 不存云端, 仅本地图标关联)".
  - 建议: 1) R110+ 评估 "本地 OAuth 集成" (用 `sign_in_with_apple` + `flutter_wechat` 拿 OpenID / UnionID, 设备本地存 SQLite 不上云), 满足 5 大市场审核预期; 2) 隐私政策 §7 第三方依赖加 4 行 + §1 信息收集加"第三方 OpenID 仅本地存储, 不上传, 不关联设备 ID"; 3) 长期保留"零账号"哲学 = "OpenID 仅用于登录, 不收集 PII 也不用于推送".
  - 外部链接检查: 4 个第三方登录 SDK 申请 (wechat / qq / weibo / apple developer 后台), 各 1-2 周

- [底层] **[P3-003] 鸿蒙 / OpenHarmony NEXT 适配 0 起步 → R95 路线图 v1.0+ 才启动, 但华为应用市场 (国内 Android 5 大之首) 2024-Q4 起新 App 必填"HarmonyOS NEXT 支持计划", 1+ 亿设备无法安装 → 失去国产化心智** — 修复难度:XL — 工作量:1-2 月 (R97+ 路线图)
  - 位置: `pubspec.yaml` 0 `flutter_ohos` 依赖 + 0 `ohos/` 目录 + `docs/DEPLOYMENT.md` 0 鸿蒙章节
  - 现状: Flutter 3.41 不支持鸿蒙 NEXT (官方支持 2025 Q1 计划), 当前 R97+ 推迟到 v1.0+。但华为应用市场上架时 (国内 Android 5 大之首, 用户体量 30%) 审核员会问"是否支持 HarmonyOS NEXT", 答"否" = 上架时标"暂不支持"标签 → 影响搜索排名 + 用户主动选装率。
  - 建议: 1) R110+ 跟踪 Flutter 官方鸿蒙 GA, GA 后 1 周内启动 `flutter_ohos` 适配; 2) 短期在华为应用市场提交时, 主动声明"暂不支持 HarmonyOS NEXT, 计划 2025 Q2 启动适配"避免下架; 3) 补 `docs/DEPLOYMENT.md` 鸿蒙章节 (R97+ 路线图已提但未实做); 4) 评估"用 ArkTS 写鸿蒙原生 Hap 包" 跟 "用 flutter_ohos 编译" 2 路径, 选成本低的。
  - 外部链接检查: 涉及华为开发者联盟注册, 鸿蒙 SDK 下载, 1-2 月审核

- [底层] **[P3-004] `lib/core/l10n/strings.dart` 仍有部分 hardcoded 英文 "PIPEL §13 单独同意" / "consent" / "audit" 等术语 + 通知文案部分走硬编 (e.g. `Strings.notifChannelSafetyName`) 0 走 ARB 化** — 修复难度:L — 工作量:1-2d
  - 位置: `lib/core/l10n/strings.dart` (307 行) + 多处 `Strings.xxx`
  - 现状: R57 / R58 集中修复后剩 21 处硬编中文字符串 + 多处英文 (e.g. `'notification failed'`), domain 层不能 import flutter, 走 const fallback 是合法设计, 但 `check_strings_hardcoded.py` 守门员只扫硬编**中文**, 英文硬编 0 监控。鸿蒙 NEXT / 海外扩展需多语 fallback 时英文走 const 没问题, 但中文 fallback 是反向 (e.g. 中文设备上通知 channel desc 显示 "服药提醒通道" 而英文设备显示 "Medication reminder channel" 应该走 ARB, 但 R57 加了"override 配对模式"使 caller 必须显式传, domain layer 调用者忘记传就 fallback 中文 → 英文用户看到中文).
  - 建议: 1) `check_strings_hardcoded.py` 扩扫英文常量, 抓"无 override 配对" 的硬编; 2) R58 override 模式改 default = null, caller 漏传走 `Strings.xxx` 中文 fallback + log warning (dev 模式可见) + 1 测试覆盖; 3) 鸿蒙 NEXT 平台分支时, ARB 加 `app_zh_Hans_HK` / `app_zh_Hant_HK` 等区域方言。
  - 外部链接检查: 不涉及 URL

- [底层] **[P3-005] `assets/legal/medical_disclaimer.md` 跟 3 份法律文档 (`user_agreement` / `privacy_policy` / `sensitive_data_consent`) 危机热线 + "非医疗器械"声明有重复但各写各的, 改 1 处忘改另 3 处** — 修复难度:M — 工作量:1d
  - 位置: `assets/legal/medical_disclaimer.md` (新增文件, R103 加) + `assets/legal/privacy_policy.md` (相关章节) + `assets/legal/user_agreement.md` (相关章节) + `assets/legal/sensitive_data_consent.md` (相关章节)
  - 现状: 4 份文档独立维护, 危机热线 / "非医疗器械" / "未成年人保护" / "跨境数据传输" 等共同条款各写一份, 改 1 条号码 4 文件改 4 次。R103 加 medical_disclaimer 时直接复制 3 危机热线 + 加"国际"行, 跟其它 3 文档差 1 条"希望 24 热线" (P1-008 已提)。
  - 建议: 1) 抽 `assets/legal/sections/*.md` 模块化 (crisis_hotlines.md / not_medical_device.md / minor_protection.md), 4 文档 `{% include %}` 引用; 2) Flutter 端 markdown 解析走 `flutter_markdown` 暂不支持 include, 改 `build_legal_docs.py` 拼装生成 4 文件; 3) 加 `scripts/check_legal_doc_consistency.py` 守门员 diff 4 文件的共同条款, 跑 PR check。
  - 外部链接检查: 不涉及 URL

- [底层] **[P3-006] 鸿蒙 / OpenHarmony NEXT 设备无法访问 `https://chroniccare.app/*` URL → 鸿蒙用户首次打开 App 看到隐私政策里的"详情见 https://chroniccare.app/privacy" 但浏览器打开是 404 (iOS / Android 用户也 404 但更明显)** — 修复难度:XS — 工作量:1h
  - 位置: `assets/legal/privacy_policy.md:225` (修订历史行 "联系方式邮箱改为 privacy@chroniccare.app") + 3 文档 5 处 `privacy@chroniccare.app` + 6 个 fastlane URL 文件
  - 现状: 4 文档 5+ 处写"详见 https://chroniccare.app/privacy", 跟 6 个 fastlane URL 文件一致。鸿蒙用户 (1+ 亿) 跟 iOS / Android 用户一样点链接 404。鸿蒙更糟, 鸿蒙浏览器对未注册域名 404 行为可能不一致 (部分国产浏览器展示"非安全连接" 红色警告, 加重病耻感)。
  - 建议: 1) 文档 + URL 文件统一加 "URL 待域名注册后启用 (R109+ 计划)"; 2) 短期在 App 内 "设置 → 法律与隐私" 加 "隐私政策本地副本" 入口 (实际已通过 `showLegalDocument(context, 'privacy_policy')` 实现, 但需要在隐私政策自身 + 上架物料 强调 "**本 App 完整包含隐私政策副本, 无需联网访问**"); 3) Apple 5.1.1 要求"URL 真实可访问" 是硬指标, 4 文档"详见 URL" 措辞 Apple 抽审时可能判定"欺骗用户", 建议改成"本 App 内置完整副本, 设置 → 法律与隐私 可随时查看" + 移除 4 文档中的"详见 URL" 措辞。
  - 外部链接检查: 涉及 5 文档"详见 URL" 措辞修订, 1-2h

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 | 影响 |
|------|------|------|------|
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` (3) | `https://chroniccare.app/privacy` | ❌ 未隐藏 / 域名未注册 (404) | Apple 5.1.1 拒因 P0-001 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` (3) | `https://chroniccare.app/support` | ❌ 未隐藏 / 域名未注册 (404) | Apple 5.1.1 拒因 P0-001 |
| `fastlane/metadata/android/{en-US,zh-CN}/{privacy_url,support_url}.txt` (4) | `https://chroniccare.app/{privacy,support}` | ❌ 未隐藏 / 域名未注册 (404) | Google Play 拒因 P0-001 |
| `assets/legal/privacy_policy.md:150` | `**privacy@chroniccare.app**` | ⚠️ 软隐藏 (R96 + 文档内"App 内设置行使撤回权"), 邮箱未注册 | 律师过审打回 P0-002 |
| `assets/legal/user_agreement.md:67,69` | `privacy@chroniccare.app` (2 处) | ⚠️ 软隐藏 (R96 同上) | 律师过审打回 P0-002 |
| `scripts/generate_data_safety_form.py:85` | `'https://chroniccare.app/delete-data-instructions'` | ❌ 未隐藏 (脚本生成器, 真接域名后才生效) | Google Play Data Safety URL 必填项 404 P0-001 |
| `scripts/generate_data_safety_form.py:114` | `'https://chroniccare.app/privacy'` | ❌ 同上 | 同上 |
| `scripts/templates/*.html.tmpl` (4) | `https://chroniccare.app/{privacy,support,user-agreement,sensitive-data-consent}` | ❌ 未隐藏 (Cloudflare Pages 占位) | 跟 URL 同问题 P0-001 |
| `scripts/register_domain.sh:29-33` | `chroniccare.app` + `support@/privacy@/noreply@/abuse@chroniccare.app` (4 邮箱) | ⚠️ 脚本内 `PLACEHOLDER_*` 占位 | 仅脚本用, 不影响 App 本身 |
| `lib/core/data/services/store_kit_service.dart:50` | `kLifetimeProductId = 'com.chroniccare.app.lifetime'` | ❌ **包名错位** (iOS / Android 实际 `com.chroniccare.chroniccare`) | App Store Connect 创建 IAP product metadata 不匹配 P0-007 |
| `fastlane/Appfile:26` | `app_identifier(ENV["APP_IDENTIFIER"] \|\| "com.chroniccare.chroniccare")` | ✅ 正确 (跟 iOS / Android 一致) | OK |
| `lib/core/data/services/safety_config_service.dart` | `support@chroniccare.app` 异常路径 | ⚠️ 软隐藏, 邮箱未注册 | 跟 P0-002 同步 |
| `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt` (4) | `TODO: 真实名字 / 真实姓 / 真实邮箱 / +86 真实手机号` | ❌ 未隐藏 (明文 TODO) | Apple 2.1 Complete Information 拒因 P0-008 |
| `ios/Runner.xcodeproj/project.pbxproj:395,575,598` | `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare` | ✅ 正确 (跟 Android 一致) | OK |
| `android/app/build.gradle.kts:25` | `applicationId = "com.chroniccare.chroniccare"` | ✅ 正确 | OK |
| `assets/legal/{user_agreement.md:67, privacy_policy.md:150}` | 2 邮箱 `privacy@chroniccare.app` 同上 (跟脚本区对应) | ⚠️ 软隐藏, 邮箱未注册 | P0-002 |
| `assets/legal/sensitive_data_consent.md` (全文 0 邮箱) | 0 邮箱 / 0 URL | ✅ 干净 | OK |

**外部链接隐藏总评**: R96 软隐藏已覆盖 5+ 处邮箱占位, 但**fastlane 6 URL + 5 模板 + 4 review_information 4 TODO 占位 + store_kit_service 错位包名 0 全部未修**, 是 R108 P0 上架阻塞 1 大类。R109+ 启动域名注册 → 同步修复 12 URL + 4 邮箱 + 4 TODO 占位 + 1 错位包名 = 共 21 处待处理。

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关 (必填, 影响 iOS / Android / Privacy)

1. **R108 P0 13 项已修 12 + 1 半成品**: 详见 `docs/CHANGELOG.md` [0.30.0] entry。已修: iCloud Backup 4 处 (P0-001 已标 P0-001 但实是另一类), `canScheduleExactAlarms()` (P0-001 类似项), 锁屏通知 body PII 脱敏, PrivacyInfo.xcprivacy 注册 Xcode, 主页 8 层 FadeIn stagger, en-US description "hypertension, diabetes" 修订, UIBackgroundModes audio 恢复, main.dart 4 处 `developer.log` 加 `kReleaseMode` 守卫, iOS `review_information/` 6 文件 (实际只 2 文件 OK, 4 文件仍 TODO), iOS LaunchImage + AppIcon 设计师 brief, Android keystore + Data Safety Form + Health Apps 4 块, iOS + Android 截图自动化脚本, chroniccare.app 域名注册步骤文档。**未真正修完**: iOS `review_information/` 4 TODO 占位 (P0-008), 域名未注册 (P0-001 阻塞全部 URL)。

2. **5 大国内应用市场 (华为 / 小米 / OPPO / Vivo / 腾讯) 0 上架准备**: `docs/DEPLOYMENT.md:237-249` 已写上架材料 checklist, 但实际**0 启动** (营业执照 + 软件著作权 + ICP 备案 + 隐私 URL + 软件著作权 1-2 月受理 缺 全部)。P1-003 / P3-002 / P3-003 都需要业务真接后才走。

3. **鸿蒙 / OpenHarmony NEXT 0 适配**: R97+ 路线图, R110+ 启动 (P3-003)。当前 1+ 亿设备无法安装, 失去"精神心理患者国产化"心智。

4. **业务真接 5 task 全停 (R93 阶段 2)**: IAP / SMS / 5 厂商 push / Email / PHQ-9 多语, 全部 FeatureFlag 守门 hidden。R95 / R100 / R104 / R108 共 13 round 未启动任一项。法务 ¥45-90k 1-2 月 + 阿里云 AccessKey 1-2d + 5 厂商 push 1-2 月审核 + SendGrid API key + IAP productId 真接, 总计 3-6 月, 是国内上架的实际时间线。

5. **IAP 业务暂停期隐私政策措辞漏洞**: `user_agreement.md:22-27` 已加 R100 注脚"未来版本可能提供可选的一次性买断功能", 但**未明确"当前不可购买"**。Apple 2.1 Performance: Complete Information 抽审时可能问"App Store Connect 显示 8 元买断, App 内无购买入口 = 信息不一致"。需在用户协议 §3 + setup 流程加 "本版本暂不提供购买入口, 8 元买断功能真接后启用" 明确披露。

6. **App Store / Google Play 上架 4 大审核重点缺位**:
   - **Apple 5.1.1 (iv) "可联系的支持渠道"**: 软隐藏的 `privacy@chroniccare.app` 在 iOS 设备没装邮件 App 时, 链接点开 = 无反应。Apple 抽审 1 次已发现 (R66 audit 报告)。
   - **Apple 1.4.1 Physical Harm / Medical**: PHQ-9 / GAD-7 危机干预弹窗未在 App Store 截图 0 显示 (R100 已修 en-US description, 但截图 0 是 P0-008 之前未修)。
   - **Google Play Health Apps questionnaire**: 28 子项未填, `scripts/generate_health_apps_questionnaire.py` 脚本占位, R109+ 启动。
   - **NMPA "非医疗器械" 声明 PDF**: `docs/DEPLOYMENT.md:311-330` 模板已写, 但**未生成实际 PDF**, 5 大市场审核必填。

7. **4 份法律文档未律师过审**: R95 task 20 (¥45-90k 1-2 月) 启动条件依赖付费 / 域名注册 / 主体资质 3 件外部, R108 工作流仍未启动。

### 4.2 架构相关 (可选, 顶层架构 subagent 必须深写)

1. **法律文档架构 0 模块化**: 4 份 md 文档独立维护, 共同条款 (危机热线 / 未成年人保护 / 跨境数据传输 / "非医疗器械" 声明 / 撤回同意流程) 复制 4 次, 改 1 处忘改 3 处。R109+ 抽 `assets/legal/sections/*.md` 子模块, 4 文档 `{% include %}` 引用 (P3-005)。

2. **FeatureFlag 架构 7 守门 false + 1 true (ventAudioEnabled)**: 当前 8 个 flag, 7 false = 7 业务暂停, 业务真接 1-1 翻 flag 是干净架构。但**未在 ARB 中显式标注"业务暂停清单"**, 用户读完 5 协议不知道 6 项功能不可用 (P2-003)。

3. **PIPL §13 单独同意集中器 (`ConsentDialog`) 5 类 ConsentKind**: `lib/presentation/widgets/consent_dialog.dart` 已抽象, 但 `safety / vent / analytics` 3 个 PIPL §14 撤回场景**未走 dialog** (v0.27 R82 注释 "fallback 模板, 走直接 toggle, 留接口给 v1.0"), 实际是设计缺位。R109+ 评估"撤回也走 dialog 二次确认 + 跟 Android System AlertDialog 同等级"。

4. **i18n 5 类 ConsentKind 文案分散在 ARB**: 5 个 consent template (contactConsentTitle / dataExportConsentTitle / setupLegalXxx) 命名不一致, 部分用 `setup*` 前缀部分用 `contact*` / `dataExport*` 前缀, 维护时容易漏。R109+ 统一 `consentXxxTitle` 命名空间。

5. **`legal_page.dart` 3 个 toggle 撤回 UI vs 5 个 ConsentKind 全集不一致**: `_visibleKinds` 显式列 3 (safety / vent / analytics), `ConsentKind.values` 5 个 (含 emergencyContactSharing / dataExport), `PIPL §13` 强场景 2 值**从不在 UI 出现**, 仅后台走 ConsentDialog。命名"legalPageWithdrawXxx" 暗示用户**可以撤回**这 3 类, 但 emergencyContactSharing 是"添加联系人时同意", dataExport 是"导出时同意", **撤回语义不明确** → 用户认知混乱。

6. **8 守门员中 4 个未覆盖国内合规**:
   - `check_legal_consent.py` 范围太窄 (P1-009)
   - `check_sms_release_ready.py` 已被 R58 降级 warn-only, 不可作为 release 闸门
   - `check_zh_hant_consistency.py` 只检查"应繁不繁", 不检查"简中混繁中字" (P0-006)
   - `check_strings_hardcoded.py` 只扫 `strings.dart`, 4 份 md 0 监控

### 4.3 重构建议 (可选, 顶层架构 subagent 必须深写)

1. **`setup_step_consent.dart` 4 → 5 → 6 步流程**: 当前 5 checkbox (3 协议 + 1 年龄 + 1 免责声明), R104 加 1 键全选 (P1-001 风险)。建议 R109+ 重构成 3 步"阅读总协议 → 单独勾敏感数据 → 单独勾免责声明" + 删 1 键全选 + 加"业务暂停清单"步骤 (P2-003)。

2. **法律文档 4 份 → 1 份 + sections/**: P3-005。

3. **CRUD 4 类 PII 字段 (药名 / 剂量 / 联系人 / 录音 / 评估) 走单独同意标记**: 当前 `consent_artifact` 实体只标 `grantedAt / version / kind`, 缺 `dataCategories / purpose / retention / thirdParties / 撤回时间 / 撤回原因` 6 字段 (PIPL §17 / §23 / §28 完整追溯需)。R95 audit R95 sub-spec 7 task 31b PIPL §47 撤回 (reset ConsentKind.dataExport 自动清 audit log) 已部分实现, R109+ 补全 6 字段。

4. **`FeatureFlags.iapEnabled` / `fiveVendorPushEnabled` / `emergencyContactEnabled` 3 项跟 8 元买断业务挂钩, 需在 `lib/core/data/services/store_kit_service.dart` 跟 `lib/core/data/services/sms_service.dart` 加"业务真接后自动翻 flag" 业务代码 (R109+ 自动同步, 当前 2 类 flag 各自静态 false)**。

5. **iOS / Android 平台分支散点重构**: 当前 `Platform.isIOS / isAndroid / kIsWeb` 多处重复, 鸿蒙 / OpenHarmony 加进来后 5+ 平台分支 = 7+ 处需统一。R110+ feature-first 重构时抽 `lib/core/platform/branch.dart` 集中 7 平台分支 (P3-001)。

### 4.4 半成品 / TODO / 残缺功能 (必填, 跨 subagent 重点)

1. **业务真接 5 task 全半成品** (R93 阶段 2 守门, R108 CHANGELOG 自述):
   - IAP `com.chroniccare.app.lifetime` productId **未在 App Store Connect 创建** (R68 决策保留, R108 仍未启动, store_kit_service.dart:50 包名错位, 见 P0-007)
   - 阿里云 SMS `_isFullyImplemented = false` 9 round 未接 (P0-003)
   - 5 厂商 push SDK 0 集成 + OEM 引导 UI 被 FeatureFlag 隐藏 (P0-004)
   - EmailService (SendGrid) `emailServiceEnabled = false`, 邮件导出功能 hidden
   - PHQ-9 / GAD-7 16 题多语 `phqGad7I18nEnabled = false`, 走 fallback key
   - AliyunSms provider 同样 `aliyunSmsEnabled = false`, 守门

2. **8 个 R108 P0 中 1 半成品 (notification_service god class 拆)**:
   - facade 308 行 (R108 拆后) + NotificationDelegate 160 行 (新)
   - 6 method (init / requestPermission / showNow / cancelAll / pendingCount / showSafetyAlert) 仍 facade 主体
   - 12 method 已委派到 delegate namespace
   - 距"瘦到 <200L" 目标 108 行差距
   - 跟 mood_audio_recorder (587L) + medication_page (601L) 共 3 半成品待 R109+ 收尾

3. **iOS review_information/ 4 TODO 占位** (P0-008): `first_name.txt` / `last_name.txt` / `email_address.txt` / `phone_number.txt` 各 1 行 TODO, 仅 `notes.txt` / `demo_user.txt` 已 OK。

4. **域名 + 邮箱占位** (P0-001 / P0-002): 6 URL + 5 邮箱 + 4 模板 + 4 review_information + 1 IAP productId 包名错位 = 21 处待业务真接或外部资源落地后批量修复。

5. **setup 流程 1 键全选** (P1-001): R104 加的 UX 改进, 跟 PIPL §28 单独同意原则有冲突, R109+ 评估删 / 改。

6. **华为应用市场上架 0 准备** (P3-003): 鸿蒙 NEXT 适配推迟 R97+, 实际 R108 仍未启动, 1+ 亿设备无 App。

7. **国内 5 大市场 (华为 / 小米 / OPPO / Vivo / 腾讯) 0 上架材料** (P3-002 / P3-003): 营业执照 / 软件著作权 / ICP 备案 / 隐私 URL / 软件著作权 1-2 月 缺全部, R109+ 启动需 3-6 月。

8. **OAuth / 微信 / QQ / 微博 第三方登录 0 集成** (P3-002): 5 大市场审核隐式期望, R110+ 评估本地 OAuth 集成。

9. **业务暂停期 7 → 6 项 (ventAudioEnabled R104 翻 true)**: 文档 + PrivacyInfo.xcprivacy 需同步刷新 (P1-007)。

10. **CRUD 4 类 PII 字段 consent_artifact 6 字段缺失** (P2 重构 3): 业务真接 5 task 完成前不阻塞, 完成后审计需求激增 (法务 1-2 月, 1-2 律师).

## 5. 总结 + 给整合者的建议

**superpowers-zh 视角核心结论**: 项目**PIPL 文档 + 撤回同意 + 单独同意 + iCloud Backup 排除 + Android 备份排除**这 5 大类**已 100% 落地** (R58 / R67 / R83 / R93 / R95 / R108 累计 11 round 集中修复), 工程基线扎实; 但**"国内合规可上架"路径上仍有 3 大硬阻塞未解 + 5 类半成品**:
1. 域名 + 邮箱 + review_information 4 TODO + IAP productId 错位 = 21 处占位 (P0-001 / P0-002 / P0-007 / P0-008)
2. 业务真接 5 task (IAP / SMS / 5 厂商 push / Email / PHQ-9 多语) 9 round 未启动 (P0-003 / P0-004 / P1-007)
3. 鸿蒙 / OpenHarmony 0 适配 (P0-005) + 5 大市场上架材料 0 准备 (P3-002 / P3-003)

**给整合者的建议** (3 类):
1. **R108 P0 上架阻塞收尾 1 周**: 解决 P0-001 / P0-002 / P0-006 / P0-007 / P0-008 这 5 类已发现 bug, 是 0 外部依赖可立即修的 (域名注册 4h, 邮箱注册 1-2h, IAP productId 修 15min, review_information 4 TODO 30min, 简繁混用 5min)。
2. **R109+ 业务真接 3-6 月**: IAP / SMS / 5 厂商 push / Email / PHQ-9 多语 5 task 启动, 同步翻 5 个 FeatureFlag, 同步刷 4 文档 + 1 NSPrivacyCollectedDataType。
3. **R110+ feature-first 重构 + 鸿蒙适配 6-12 月**: 跟 P3-001 / P3-002 / P3-003 一起规划, 7 平台 + 5 大市场上架材料 + OAuth 集成 + 鸿蒙原生 Hap 包, 总计 6-12 月工作量。

**R108 收尾建议优先序 (P0 → P1 → P2 → P3)**:
- P0 (8 项, 全部需 R108+ 修): 域名注册 (4h) + 邮箱注册 (1-2h) + 4 review_information TODO (30min) + IAP productId 修 (15min) + 简繁混用修 (5min) = 6-8h 工作量, 全部 0 外部依赖可立即修
- P1 (9 项, 大部分需 1-2d + 部分外部): setupConsentAgreeAll 删除 (1d) + 隐私政策措辞修订 13+ 处 (1-2d) + 第三方依赖表扩列 (1h) + lock-in test 1 个 (1d) + 5 个 UI 修订 (1h 合计) = 3-5d
- P2 (6 项, 优化): 1-3d 总计
- P3 (6 项, 长期 R109+ / R110+): 6-12 月跨度

**给整合者的 3 个最容易忘的关键提醒**:
1. **`scripts/check_sms_release_ready.py` 已被 R58 降级 warn-only, v1.0 上 store 前必须升回 hard FAIL** (注释明确, R58 + R63 + R67 + R95 + R108 共 6 round 未升)。
2. **`check_legal_consent.py` 守门员范围太窄, 4 份 md 文档 13+ 处"未来规划" / "本版本未启用" 措辞 0 监控, 律师过审时最常见的拒因** (P1-002 / P1-009 合并修)。
3. **R93 阶段 2 把 8 项业务 FeatureFlag 全部 hidden, 但 ventAudioEnabled R104 已翻 true, 文档 + PrivacyInfo.xcprivacy 未同步刷新, Apple 抽审敏感数据披露严** (P1-007)。

---

<!-- subagent: superpowers-zh 完成时间: 2026-08-10 -->
