# pull-onshelf 上架审计报告 — chroniccare 1.1.0+149

审计人: pull-onshelf 审计 agent / 日期: 2026-08-16 / 基线: master `f9f4e2b5` + working tree (R113 修复战役未 commit)
审查范围: ios/ (Info.plist + 3 语 InfoPlist.strings + PrivacyInfo.xcprivacy + entitlements + AppIcon/LaunchImage + pbxproj) · android/ (AndroidManifest 主/debug + build.gradle.kts + proguard + xml 资源 + keystore/key.properties) · pubspec.yaml · fastlane/ (Fastfile + Appfile + metadata 全部逐文件) · assets/legal/ 4 份 · lib/ 代码级 grep (kDebugMode/TODO/密钥/FeatureFlags/路由) · scripts/ 守门员清单 · docs/SUBMISSION_INFO.md · build/ 生成产物
规范依据: .opencode/standards/{appstore,googleplay,cn-android-stores}.md (2026-08-16 版)

---

## 一、就绪度评分

| 商店 | 评分 | 判定依据 |
|---|---|---|
| App Store (iOS) | **未就绪** | 代码面 9.5/10 已达提交水准, 但 4 项硬阻塞 100% 残留: privacy/support URL `[PENDING_DOMAIN]` 占位 ×6 文件 / review_information 4 占位 / 截图 0 张 (Fastfile release lane 自身有 guard 拦截) / 5.1.3 健康问卷 + 律师过审未签 |
| Google Play | **未就绪** | privacy_url 占位 / 4+4 张 67B 空白截图 (合法 PNG 但纯色无内容) / console 4 表单 (Data Safety / Health Apps / Permissions 声明 / 删除) 未填 / 16KB 对齐仅配置级绿、release 产物未 objdump 实测 / keystore 密码未备份 |
| 国内安卓 (华为/小米/OPPO/vivo/应用宝) | **未就绪** | ICP 备案 + 软著 0 证据 (硬门槛) / 隐私政策 URL 无备案域名 / 隐私政策 §9 + 用户协议 §8 联系邮箱占位 (工信部要求真实可联系) / 截图空白 / copyright 无法律主体名 |

**跨商店共性结论**: 代码、权限、合规文档三方面均已达到"提交水准"; 未就绪原因 100% 集中在外部依赖 (域名 ICP → 4 邮箱 → 设计师截图 → console 表单 → keystore 备份 → 律师签字)。全部为已知 blocker, 无新发现 REJECT 级代码问题。

---

## 二、按商店分组的整改清单

### REJECT — 必然/极大概率被拒 (全部为已知外部依赖, 无代码级新发现)

**R1. privacy_url / support_url 占位** — 全商店 — 元数据 (fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt:1 + support_url.txt:1; fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt:1 + support_url.txt:1)
- 问题描述: 6 个文件内容均为 `[PENDING_DOMAIN: 域名注册后替换为 https://chroniccare.app/privacy]`
- 规范依据: App Store 5.1.1 / Google Play 隐私政策必填且可达 / 工信部要求备案域名
- 影响: 三端全部被拒 (URL 不可达即拒)
- 整改: 域名注册 + ICP 备案 (7-20d) → 替换 6 文件 → 隐私政策部署到 https://chroniccare.app/privacy
- 难度: 低(机械替换) / 优先级: P0 (外部依赖)

**R2. review_information 4 占位** — App Store — 元数据 (fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt:1)
- 问题描述: 4 文件内容均为 `[REPLACE_BEFORE_APPLE_REVIEW: ...]`
- 规范依据: App Store 审核联系人必须真实可送达 (1.5)
- 影响: 提交即被拒或审核停滞
- 整改: 填真实姓名/邮箱/电话 (域名注册后可用 dev@chroniccare.app)
- 难度: 低 / 优先级: P0

**R3. iOS 截图 0 张** — App Store — 资产 (fastlane/metadata/ios/*/screenshots/ 不存在; Fastfile:48-55 release lane 自带 guard 拦截)
- 问题描述: 三个 locale 均无 screenshots 目录; Fastfile 会在 0 截图时 `UI.user_error!`
- 规范依据: App Store 新 App 必须 ≥1 张 6.7"/6.5" 截图
- 影响: 无法提交 (guard 拦截 + Apple 拒)
- 整改: 设计师出图 → 放 fastlane/metadata/ios/{locale}/screenshots/
- 难度: 低 / 优先级: P0 (设计师外部依赖)

**R4. Android 截图 8 张 67B 空白** — Google Play + 国内 — 资产 (fastlane/metadata/android/{zh-CN,en-US}/phone_screenshots/screenshot_{1..4}.png)
- 问题描述: 8 张均为 67 字节合法 PNG (1232×720 纯色, IDAT 仅 12 字节 = 无内容)
- 规范依据: Play 截图须真实展示 App UI; 空白/占位截图审核必拒 (2.1 完整性)
- 影响: Google Play + 国内各家均拒
- 整改: 设计师出图替换 (Play 要求 4-8 phone + 可选 tablet)
- 难度: 低 / 优先级: P0 (设计师外部依赖)

**R5. ICP 备案 + 软著缺失** — 国内安卓 — 资质 (全 repo 0 证据; cn-android-stores.md 清单第 1-2 项)
- 问题描述: 华为/小米/应用宝强制软著; 2023-09 起国内分发强制 App ICP 备案号
- 影响: 国内商店全部无法提交
- 整改: App 主办者 ICP 备案 + 软著申请 (外部流程, 数周-数月)
- 难度: 高(流程) / 优先级: P0

**R6. 法律文书联系邮箱占位** — 国内 (含 App Store WARN 级) — 合规 (assets/legal/privacy_policy.md:134; assets/legal/user_agreement.md:61,63)
- 问题描述: 隐私政策 §9「个人信息保护负责人:【邮箱待启用: 域名注册后填入】」; 用户协议 §8 同款 2 处
- 规范依据: 工信部《App 违法违规收集使用个人信息行为认定方法》要求提供有效联系方式; Apple 5.1.1 隐私政策需可联系
- 影响: 国内商店 REJECT (联系方式无效); App Store WARN
- 整改: 域名/邮箱注册后替换为真实邮箱并重新走同意流程 (userAgreementVersion 刷版本)
- 难度: 低 / 优先级: P0 (国内) / P1 (App Store)

### WARN — 可能被拒/审核变慢

**W1. release_notes 引用已删除功能 "contacts"** — App Store + Google Play — 元数据 (fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/release_notes.txt:1)
- 问题描述: 「Export/import now backs up your complete history (medications, mood entries, **contacts**)」— v1.1.0 已永久删除联系人功能
- 规范依据: App Store 2.3.1 (未文档化/错误功能宣传); Play 元数据准确性
- 影响: 审核员核对实际功能发现不符 → 打回修改
- 整改: 改「medications, mood entries, worry threads, daily tracking」并同步 zh-Hans/zh-Hant
- 难度: 低 / 优先级: P1

**W2. Android changelog 版本头过期** — Google Play — 元数据 (fastlane/metadata/android/{en-US,zh-CN}/changelogs/default.txt:1)
- 问题描述: 标题「Version 1.0.0」, 当前 1.1.0+149
- 影响: Play 按 release 展示 changelog, 版本号错位 → 审核质疑
- 整改: 改「Version 1.1.0」+ 补情绪优先/树洞/烦恼闭环要点
- 难度: 低 / 优先级: P2

**W3. 5.1.3 健康问卷未提交 (草稿已就绪)** — App Store — console 表单 (docs/SUBMISSION_INFO.md:121-136; build/health_apps_questionnaire.json 已生成)
- 问题描述: 自评量表 + 严重度 + 危机资源 → 几乎必然触发 Health 抽审问卷
- 整改: 提交周复制粘贴进 ASC (草稿与 description 中性化口径一致, 已把 PHQ-9/GAD-7 点名改通用措辞)
- 难度: 低 / 优先级: P1

**W4. Google Play console 4 表单未填 (文本已生成)** — Google Play — console 表单 (build/data_safety_form.md + SUBMISSION_INFO.md:99)
- 问题描述: Data Safety / Health Apps / Permissions (RECORD_AUDIO + SCHEDULE_EXACT_ALARM + POST_NOTIFICATIONS) / 数据删除 4 表单, 生成器已备但 console 未提交
- 影响: 不填无法提交; RECORD_AUDIO 未申报会拒
- 难度: 低 / 优先级: P1

**W5. 16KB 对齐仅配置级绿, 产物未实测** — Google Play — 技术 (scripts/check_16kb_alignment.py; android/app/build.gradle.kts:14 NDK 27)
- 问题描述: sqlcipher_flutter_libs ^0.6.5 (locked 0.6.8) + NDK 27 + abiFilters arm64-v8a/x86_64 配置达标, 但 2025-11-01 强制项需 release AAB 后 `check_16kb_alignment.py --aab` objdump 实测
- 影响: 实测不过即被拒
- 整改: 有 Android SDK 的机器跑首次 release build + objdump
- 难度: 中 / 优先级: P1 (外部: 本机无 Android SDK)

**W6. keystore 密码未备份** — Google Play + 国内 — 签名 (android/app/chroniccare-release.jks 已生成 + key.properties 4 键齐全且 gitignored ✓)
- 问题描述: R108 生成 keystore 但密码备份 1Password 是用户手工操作, 无自动证据; 丢 key = 永远无法更新已上架 App
- 整改: 备份 storePassword/keyPassword + .jks 到 1Password
- 难度: 低 / 优先级: P1 (用户操作)

**W7. 律师过审 TODO 未闭环** — 全商店 (国内尤重) — 合规 (assets/legal/user_agreement.md:83)
- 问题描述: 修订历史仍有「v0.28+ 待定 **TODO (上 store 前必须由专业律师过审)**」
- 影响: 国内商店心理类文档审查趋严, 未过审法律文档 = 打回风险; App Store 5.1.3 抽审亦可能要求
- 整改: 律师过审 → 删 TODO 行 → 文档版本 bump → 重走用户同意
- 难度: 中(外部) / 优先级: P1

**W8. INTERNET 权限理由过期 (疑未使用)** — 国内安卓 — 权限 (android/app/src/main/AndroidManifest.xml:40)
- 问题描述: 注释称 INTERNET 因「in_app_purchase plugin 隐式依赖」保留, 但 1.0.0 已删 IAP (pubspec 无 in_app_purchase); lib/ 全量 grep 无任何 http:// 网络调用; debug 构建的 INTERNET 已由 src/debug/AndroidManifest.xml 覆盖
- 规范依据: 国内绿色应用公约权限最小化 (OPPO/小米自检报告)
- 影响: 国内审核可能要求解释或移除; Play 不拒 (normal 权限不面向用户)
- 整改: 移除主 manifest INTERNET 并回归验证 (或补正确理由注释); 若 speech_to_text 网络识别依赖 Play Services 亦不需要 app 侧权限
- 难度: 低 / 优先级: P2

**W9. 隐私政策"零云端"表述 vs speech_to_text 平台级云端** — App Store — 合规 (fastlane/metadata/ios/en-US/description.txt 「Zero cloud: We don't have servers」 vs assets/legal/privacy_policy.md §7 speech_to_text 行「mobile 走平台 on-device / **cloud**」)
- 问题描述: iOS SFSpeechRecognizer 将语音送 Apple 服务器; 商店文案「Zero cloud」字面与平台 STT 行为存在解释空间
- 规范依据: App Store 5.1.1 隐私声明须与实际一致
- 影响: 抽审时可能被问询
- 整改: description 补一句「voice transcription is processed by your device's built-in service, never stored by us」(zh 两语同步)
- 难度: 低 / 优先级: P2

**W10. copyright 无法律主体** — 国内 — 元数据 (fastlane/metadata/ios/*/copyright.txt:1 「© 2026 chroniccare」)
- 问题描述: 国内商店要求版权主体与软著/备案主体一致
- 整改: 软著主体名替换
- 难度: 低 / 优先级: P2

**W11. working tree 未 commit** — 全商店 — 流程 (git status: 90+ 文件修改含 metadata/图标/Fastfile/CI)
- 问题描述: R113 修复战役 + 图标/feature_graphic 再生成全部未 commit; 上架 build 必须从干净已提交状态出
- 影响: 若直接打包 = 资产与代码版本不可追溯, 审核问题难复现
- 整改: 上架前 commit (风格 `<version> round <N>: ...`)
- 难度: 低 / 优先级: P1

### SUGGEST — 不阻塞过审

- **S1** 商店文案仍药本位: iOS subtitle「Medication + Mood Tracker」/ Android 标题「ChronicCare - Med Reminder」/ promotional_text 首句药打卡, 与 1.1.0 情绪优先定位错位 — 建议统一为 mood/vent 优先表述 (元数据; 低; P3)
- **S2** AppIcon 1024 仅 16KB (合法: 1024×1024 无 alpha 已验证) — 设计资产质量待设计师版替换 (ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png; 低; P3)
- **S3** 死文件 BootReceiver.kt 编译进 release 但无 manifest 注册 (inert) — 建议删除防审核员混淆 (android/app/src/main/kotlin/.../BootReceiver.kt; 低; P3)
- **S4** 2 处注释引用已删 flag (`emailServiceEnabled` lib/presentation/pages/settings/widgets/assessment_section.dart:98; `emergencyContactEnabled` lib/presentation/pages/home/widgets/home_fab_toolbar.dart:106) — 注释级陈旧, 建议清理 (低; P3)
- **S5** user_agreement.md §1 列「心理评估(PHQ-9 / GAD-7)」为核心功能, 但 prod `phqGad7I18nEnabled=false` 已从量表中心过滤 (assessment_center_page.dart:47-49) — 协议与现状微不一致, 建议措辞泛化为「自助反思量表」 (低; P2)
- **S6** iOS 年龄分级「4+」预期偏乐观 — 敏感心理健康内容 + 14-18 监护人同意流程, 问卷大概率判 12+/17+; 提交时勿勾 Kids Category, 按问卷真实作答 (低; P3)
- **S7** .env (38B) 存在于工作区且 gitignored ✓ — 确认其内容与 .env.example 一致无真实凭据即可 (低; P3)

---

## 三、已确认无风险项 (检查过且无问题, 防止重复排查)

1. **iOS 权限声明 4 项全部真用**: NSMicrophone/NSSpeechRecognition (vent+mood 录音, FeatureFlags.ventAudioEnabled=true) / NSPhotoLibraryAdd+Usage (PDF 报告) — Info.plist:53-73 + 3 语 InfoPlist.strings 全覆盖 ✓
2. **Android 权限 6 项除 INTERNET 外全真用**: POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM (reminder+snooze) / WAKE_LOCK / VIBRATE / RECORD_AUDIO ✓; USE_EXACT_ALARM + RECEIVE_BOOT_COMPLETED 已按 R97 移除 ✓
3. **PrivacyInfo.xcprivacy**: NSPrivacyTracking=false; CollectedDataTypes = AudioData + UserContent (无 HealthAndFitness, 与 0 HealthKit 集成一致); 5 类 AccessedAPITypes 均有 reason (CA92.1/CA92.2 + C617.1 + 35F9.1 + 85F4.1 + AC67.1) ✓
4. **加密合规**: ITSAppUsesNonExemptEncryption=false (SQLCipher 标准库) ✓; Runner.entitlements 空 (无 APNs/HealthKit 假声明) ✓
5. **技术门槛**: targetSdk 36 ✓ / minSdk 24 ✓ / 64-bit abiFilters ✓ / multidex ✓ / R8 keep 规则覆盖全部 10+ 插件 (proguard-rules.pro) ✓ / release debuggable=false + JNI debug false ✓
6. **签名**: release signingConfig 读 key.properties (缺则报错), `-PdebugSigning=true` 显式 fallback — 不会再犯 R97-P0-5 debug 签名上架; .jks + key.properties + .env 全部 gitignored 且未 commit ✓
7. **版本一致性**: pubspec 1.1.0+149 ↔ notes.txt「1.1.0+149」↔ Android versionCode 149 ↔ iOS FLUTTER_BUILD_NUMBER=149 ✓; App 名 3 语对齐 (ChronicCare/慢病管家) iOS+Android ✓
8. **代码级干净**: 0 硬编码密钥/测试账号 (grep apiKey/secret/password 仅 DB 密码变量) / 0 http:// 网络调用 / 0 调试后门路由 / kReleaseMode 守卫 3 处防 PII 写 console + piiSafeLog 统一出口 ✓
9. **隐藏功能边界**: PHQ-9/GAD-7 从量表中心过滤 (flag false)、5 厂商 push section SizedBox.shrink、BootReceiver 无注册 — 商店文案 0 点名隐藏功能 (R111 AS-17 中性化已落地: 「guided self-reflection」) ✓
10. **危机干预**: 主页危机热线 FAB 永远显示 (home_fab_toolbar.dart:106-118) — Apple 1.4.1 强制项 ✓; 量表危机检测 (level2_depression/anxiety/psychosis/ISI/WHODAS/ASRM detectCrisis) 与 Android 描述「Crisis resources are highlighted...」一致 ✓
11. **隐私文档**: 4 份 legal md 打包进 assets ✓ + PIPL 单独同意 (3 勾选) + 撤回通道 + 未成年人 §10 + 树洞绝对隔离承诺 ✓; 外联 (SMS/Email/联系人) 文档全删 ✓
12. **锁屏 PII**: Android 通知全走 NotificationVisibility.secret (notification_service/reminder_dispatcher/snooze/badge 4 处) ✓; iOS Darwin 通知 title/body 守门员 check_pii_in_title 扩到 10/10 ✓
13. **备份安全**: allowBackup=false + dataExtractionRules 双排除 + fullBackupContent ✓; iOS SkipBackup 4 caller + iCloud 目录级 opt-out ✓
14. **路由无死链**: 40 条路由全部对应功能页, /worry/archive 已排在 /worry/:id 前 (R113 修复) ✓
15. **Fastfile 脚枪防护**: iOS release lane 0 截图 guard + submit_for_review=false + automatic_release=false (R112 AS-23) ✓
16. **国内合规亮点**: 全本地零出境 (PIPL §38 无场景) + 权限最小化思路 + 心理类免责声明齐全 — 唯一硬门 = 备案/软著/域名

---

## 四、整改优先级路线 (与项目已知 blocker 一致)

1. **外部闸门 (并行推进)**: 域名 ICP (7-20d) → 4 邮箱 → keystore 密码备份 → 设计师截图 (iOS + Android 8 张) + AppIcon 设计版 → 律师过审 → console 表单填写 (Play 4 表单 + ASC 5.1.3 问卷 + review_information 真实值)
2. **提交前代码闸 (1h)**: W1 release_notes 去 contacts / W2 changelog 版本头 / W8 INTERNET 权限决策 / W11 commit 干净基线
3. **首次 release build 验证**: Android 16KB objdump 实测 + iOS TestFlight 冒烟
4. 完成后复跑本审计 → 预期三端均达「有条件就绪」(国内仍需 ICP/软著完成)
