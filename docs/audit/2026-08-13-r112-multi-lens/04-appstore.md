# App Store 上架合规审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: App Store Review Guidelines 合规 + 上架资产 (04)
- 审视者: appstore subagent
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308 (0.32.0+142), working tree=127M 13?? (R112 进行中: fastlane metadata 多文件修改 + 新守门员 check_review_information_todo.py)
- 范围: 全量实读 `fastlane/metadata/ios/` 全 27 文件 (review_information 6 + en-US/zh-Hans/zh-Hant 各 7) + `fastlane/Appfile`/`Fastfile`; `ios/` 全量 (Info.plist / PrivacyInfo.xcprivacy / Runner.entitlements / AppDelegate.swift / InfoPlist.strings ×3 / AppIcon 16 文件 + LaunchImage 3 文件 + Contents.json ×2); `lib/` grep 级扫描 (DarwinNotificationDetails 5 处 / store_kit_service / feature_flags / main.dart gate / assessment 免责声明 / 危机热线); `scripts/{check_review_information_todo,check_pii_in_title,check_apple_health_claim}.py` 实读 + 实跑; `docs/SUBMISSION_INFO.md` + `docs/STOREFRONT_RELEASE_SOP.md` + `assets/legal/` 3 文件; 旧报告 R111 `04-appstore.md` 仅作待验证清单。

## 1. 整体评分 (0-10)

**4.0/10** — 代码面 9.5/10 达提交水准且 R112 再收敛 (safety alert userName 全删 + AS-16/02/15/17 闭环), 但 5 项硬阻塞 100% 外部依赖 (review 4 占位 / 未注册域名 / 0 截图 / 68B LaunchImage / 10.9KB Icon) 跨期 0 进展; 新增 3 项 P1 均为 R112 实读发现的 metadata 措辞 / Fastfile 脚枪问题。

## 2. 关键发现

### P0 (必修, 阻塞上架 — 全部外部依赖)

- [架构] **[P0-01 / AS-01] review_information 4 联系人文件仍为标记占位** — 难度:S (信息到手后) — 工作量:0.5h
  - 位置: `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt:1`
  - 现状: 4 文件内容 = `[REPLACE_BEFORE_APPLE_REVIEW: ...]` 标记占位。R111 说"4 TODO 占位已修"实为改成标记占位, 不是填真实值。fastlane 上传时会把占位字符串原样发到 App Store Connect (SUBMISSION_INFO.md 自述: 审核邮件无法送达 = 拒因/无限延长)。新守门员对此 warn-only (正确: 外部依赖登记在案)。
  - 建议: 域名注册后建 `dev@chroniccare.app` + 真实姓名/手机号一次性替换; 守门员会从 warn 转 0 warn。

- [架构] **[P0-02 / AS-03] privacy/support URL ×6 全指向未注册域名 chroniccare.app** — 难度:XL (ICP 7-20d) — 工作量:外部
  - 位置: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` = `https://chroniccare.app/privacy|support`
  - 现状: Apple 5.1.1(v) 要求 privacy URL 可访问; 域名未注册 → 链接 404 = 拒。assets/legal/privacy_policy.md:150 的联系邮箱 `privacy@chroniccare.app` 同域名依赖 (PIPL 投诉渠道)。
  - 建议: 域名 + ICP 是整条上架路径的第一闸门, 先动。

- [底层] **[P0-03 / AS-04] iOS 截图 0 张, Fastfile release lane 会照常提交** — 难度:S (改 Fastfile) / 设计师 1-2d (出图) — 工作量:15min + 外部
  - 位置: `fastlane/metadata/ios/` 无任何 screenshots 目录 (find 实测 0); `fastlane/Fastfile:59-66` `upload_to_app_store(skip_screenshots: false, submit_for_review: true)`
  - 现状: Apple 新 App 提交至少需 iPhone 6.7"/6.5" 截图。当前 0 张。
  - 建议: 出图前把 `submit_for_review: true` 改 false 或加 fail-fast guard (见 P1-03)。

- [底层] **[P0-04 / AS-05] LaunchImage 3 × 68B 1×1px 空白占位** — 难度:S (设计师出图后) — 工作量:外部 1-2d
  - 位置: `ios/Runner/Assets.xcassets/LaunchImage.imageset/{LaunchImage,LaunchImage@2x,LaunchImage@3x}.png` (file 实测 PNG 1×1 gray+alpha, 68B)
  - 现状: 启动瞬间白屏, HIG 违规; `test/ios/launch_image_size_round108_test.dart` 3 个 lock-in test 现行 fail (2377 pass / 4 fail 之 3)。
  - 建议: 设计师出 3 张真实图 (≥1KB 过锁)。storyboard 已修 (R111 确认 2377B), 只需图片。

- [底层] **[P0-05 / AS-06] AppIcon 1024×1024 = 10932B, 未过项目自身 ≥50KB 门禁** — 难度:S (设计师) — 工作量:外部 1d
  - 位置: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` (10932B, 388 独特色, RGB 无 alpha)
  - 现状: Apple 硬性要求 (1024² + 无 alpha) 技术上已满足, 但项目 lock-in test (`test/ios/app_icon_size_round108_test.dart`) 要求 ≥50KB → 2 个 test fail (4 fail 之 2), R108 定性为 "low quality icon 抽审风险"。16/16 尺寸槽 + Contents.json 19 条目 + 无 alpha 全部实测通过。
  - 建议: 设计师重做品牌图标 (scripts/generate_ios_assets.sh 或 AppIcon Generator 从 1 张导出)。

### P1 (应修, 影响品质)

- [底层] **[P1-01 / AS-21] promotional_text 仍含 "mental health assessments" — R109 P0-09 宣称删但从未落地, R110/R111 报告双双漏提** — 难度:S — 工作量:5min
  - 位置: `fastlane/metadata/ios/en-US/promotional_text.txt:1` ("Mood, vent space, and mental health assessments"); git log 显示该文件最后一次改动 = 556d454 (v0.27), R109 (2026-08-11) 的 P0-09 从未 commit
  - 现状: 用户可见 storefront 文案, 5.1.3 健康类抽审放大面; description 已中性化 (R112) 但 promo 没跟上, 前后不一致更显扎眼。
  - 建议: "mental health assessments" → "self-reflection check-ins" 之类, 与 description 新版措辞对齐。

- [底层] **[P1-02 / AS-22] en-US description 首行 + "WHO IS THIS FOR" 描述已关闭功能 — 2.1/2.3 误导风险** — 难度:S — 工作量:10min
  - 位置: `fastlane/metadata/ios/en-US/description.txt:1` ("stay connected with loved ones") + `:27` ("Caregivers who want to gently check in on loved ones")
  - 现状: "与亲友保持联系"唯一落点 = 紧急联系人 SMS, 但 `FeatureFlags.emergencyContactEnabled=false` → 联系人 UI 全 gate (profile_group.dart:183 / setup_step_welcome:124 / reminders_hub gate / app_router 0 contacts 路由)。现版本用户完全用不到该功能, 描述却当核心卖点。Apple 2.1 (App Completeness) 实测 App 无此功能 = 拒因级风险。
  - 建议: 删该句或改 "All on your device. Always." 方向; zh-Hans/zh-Hant description 无此句, 不用动。

- [架构] **[P1-03 / AS-23] Fastfile release lane 是"一键提交脚枪" — 0 截图 + submit_for_review=true 会提交残缺包** — 难度:S — 工作量:15min
  - 位置: `fastlane/Fastfile:59-66` (`skip_screenshots: false, submit_for_review: true, force: true`)
  - 现状: 当前状态下跑 `fastlane ios release` = build → 上传 → 无截图自动提交审核 → 被拒或卡审核。同时 `precheck_include_in_app_purchases: false` 需在 iapEnabled 翻 true 时同步改 true (注释已留)。
  - 建议: release lane 加 fail-fast (无 screenshots 目录即 abort) 或 submit_for_review 默认 false; metadata lane 不受影响。

- [架构] **[P1-04 / AS-17 残留] 5.1.3 Health Disclosure 准备仍为 0 — description 中性化已闭环, 但提交周问卷未起草** — 难度:M — 工作量:0.5d (提交前 1 周)
  - 位置: App Store Connect Health Information Disclosure Questionnaire (无代码位置; SUBMISSION_INFO.md:§1.2 P0-17 ⏳); description.txt:13 节标题 "Mental health assessments" 保留
  - 现状: App 内 PHQ-9/GAD-7 + 严重度分档 (轻度/中度/重度, assessment_severity_style.dart:5-11) + "推荐就医" (assessment_result_panel.dart:3,125 免责声明在) 属 Apple 5.1.3 关注面。R112 已把 description 3 locale "standardized questionnaires" → "guided self-reflection" (AS-17 闭环 ✅) 且 disclaimer 全在, 但提交时几乎必然触发 Health 类问卷。
  - 建议: 按 R111 建议预填问卷草稿 (self-assessment / not diagnosis / 非医疗器械定位), 随提交周一起交。

### P2 (可修, 优化)

- [底层] **[P2-01 / AS-20] keywords.txt "mental,health" (en) + "心理,健康" (zh-Hans/zh-Hant) — R109 P0-08 宣称删, 从未落地, R110/R111 双双漏提** — 难度:S — 工作量:5min
  - 位置: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/keywords.txt:1` (git log 最后一次改动 556d454 v0.27)
  - 现状: keywords 用户不可见, 实际风险低; 但与 R109 既定决策 (P0-08 删) 矛盾 + 审计清单静默丢失 = 流程问题。
  - 建议: 删 "mental"/"心理" 保留 "health"/"健康" 与 mood/reminder 类, 或明确决策"保留并登记"。

- [底层] **[P2-02 / AS-24] check_review_information_todo.py 规则缺口: docstring 与实现不符 + 不强制 4 文件存在** — 难度:S — 工作量:15min
  - 位置: `scripts/check_review_information_todo.py:12-14` (docstring 列 `111` / `000-0000` 等 pattern) vs `:39-47` (实现只有 7 个 pattern, 无 111/000-0000); 只 glob `*.txt` 不校验 first/last/email/phone 4 个规范文件在位 (删掉 email_address.txt 会静默 pass)
  - 现状: 守门员实测 PASS (notes.txt 0.32.0+142 = pubspec ✅, 4 标记占位 warn-only ✅), 规则 1/2 有效; 上述为防御盲区。
  - 建议: docstring 对齐实现 (删 111/000-0000 或补 pattern) + 加 4 文件存在性断言 + demo_user.txt/notes.txt 非空断言。

- [架构] **[P2-03 / AS-25] PrivacyInfo 声明 ContactInfo 但联系人功能全 gate (declared-but-not-used 与 R108 删 HealthAndFitness 同逻辑)** — 难度:S (决策) — 工作量:5min
  - 位置: `ios/Runner/PrivacyInfo.xcprivacy:66-76` (NSPrivacyCollectedDataTypeContactInfo); 对照: R108 用同一逻辑删了 HealthAndFitness (xcprivacy:36-49 注释)
  - 现状: emergencyContactEnabled=false → 无任何入口采集联系人数据, 声明 ContactInfo 严格说是假声明; 但 xcprivacy 与 App Privacy 问卷口径 (数据类) 不完全等同, 保留也可辩护。
  - 建议: 二选一: (a) 跟随 R108 逻辑删 ContactInfo, SMS 真接时加回; (b) 保留 + 在 xcprivacy 注释写明"预存储规划, 与 App Privacy 问卷保持一致"。避免审核员对比时两处不一致。

- [底层] **[P2-04] iOS release_notes.txt 缺失 (3 locale)** — 难度:S — 工作量:5min/次发版
  - 位置: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 无 release_notes.txt (iOS release notes 在 ASC 手填, fastlane deliver 可同步)
  - 现状: 非阻塞 (ASC 手填可行), 但 fastlane 全量同步时缺 release notes 会覆盖为空白。
  - 建议: 发版时生成 release_notes.txt 与 CHANGELOG 同步 (可扩 check_review_information_todo.py 规则 3)。

### P3 (建议, 长期)

- [底层] **[P3-01 / AS-18 更新] safety_alert Android visibility:public 决策 — R112 已进一步收敛, 待法务终审** — 难度:S — 工作量:1 行 (改 private) 或 0 (维持)
  - 位置: `lib/core/data/services/safety_alert_builder.dart:92-99` (visibility: public + 决策注释)
  - 现状: R112 把 builder 的 userName 参数全删 (title 与 body 都不含名字, 只剩"已 X 天未打卡 + 上次打卡日期"), 锁屏暴露面比 R111 报告时更小。当前功能被 emergencyContactEnabled gate, 运行时 0 风险; 启用前建议法务拍板 public/private。
  - 建议: 启用 SMS 前 1 轮法务 review 顺带确认。

- [底层] **[P3-02] notes.txt "Crisis Hotlines (6 regions)" vs 页面实际 5 地区分区 + 1 全国热线 + 国际 fallback** — 难度:S — 工作量:5min
  - 位置: `fastlane/metadata/ios/review_information/notes.txt:6` vs `lib/presentation/pages/crisis_hotline_page.dart:58-60`
  - 现状: 数据 map 是 6 region (cn/us/hk/tw/sg/uk), 页面展示 5 section + 800 热线。审核员数页面对不上"6"时轻微困惑。
  - 建议: notes.txt 改 "Crisis Hotlines (5 regions + international)" 或页面补 sg。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt | https://chroniccare.app/privacy | **未隐藏** — 域名未注册, 404 (P0-02) |
| fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt | https://chroniccare.app/support | **未隐藏** — 同上 (P0-02) |
| fastlane/metadata/ios/review_information/email_address.txt | 推荐 dev@chroniccare.app | 标记占位 (P0-01, 同域名依赖) |
| fastlane/metadata/ios/en-US/description.txt | https://findahelpline.com (国际危机热线) | 已隐藏?否 — 真实第三方公共资源站, 可接受 (description 内, 非 App 内) |
| assets/legal/privacy_policy.md:150 | privacy@chroniccare.app (个人信息保护负责人) | **未隐藏** — 域名未注册, PIPL 投诉渠道暂不可用 (文档已标注"邮件渠道待域名注册后启用":172) |
| lib/ 全部 | grep `https?://` = 0 命中; 仅 tel: 危机热线 (crisis_hotline_page.dart:242) | 已隐藏 ✅ — notes.txt "no web links" 声明属实 |
| fastlane/Appfile | APPLE_ID/TEAM_ID/ITC_TEAM_ID 走 ENV (.env gitignore) | 已隐藏 ✅ — 无凭据进 git |

## 4. 四类问题 (用户点名)

### 4.1 上架相关
- **R112 已闭环 (实读验证)**:
  - AS-16 守门员 `scripts/check_review_information_todo.py` 已建 + 实测 PASS (exit 0): notes.txt 0.32.0+142 = pubspec ✅ + 4 标记占位 warn-only ✅
  - AS-02 notes.txt 版本 0.32.0+130 → 0.32.0+142 ✅
  - AS-15 notes.txt "No third-party SDKs" → "No analytics, ad, or tracking SDKs" ✅ (15+ 第三方 package 事实下不再假声明)
  - AS-17 description 3 locale (en/zh-Hans/zh-Hant) "standardized questionnaires" → "guided self-reflection questionnaires" ✅ (working tree diff 实证)
  - R112 附带: safety_alert_builder userName 死参数删除 → 通知 title+body 双无名字, 锁屏 PII 比 R111 更干净 ✅
- **R111 跨期残留 5 P0 (R112 0 进展, 全外部)**: P0-01~05 见上。修复顺序: 域名 (7-20d, 一切 URL/邮箱的前置) → 设计师资产 (截图/Icon/LaunchImage 1-2d) → 真实联系人信息 → 提交。
- **锁屏 PII 实测全绿**: `python3 scripts/check_pii_in_title.py` PASS; DarwinNotificationDetails 5 处实测: reminder_dispatcher:118 / notification_service:244 / snooze_manager:102 有 categoryIdentifier + interruptionLevel; safety_alert_builder:98 有 interruptionLevel; badge_sync_service:71 presentAlert:false + 空 title (无 PII)。Android visibility secret ×4 (badge_sync:71 / reminder_dispatcher:116 / notification_service:243 / snooze_manager:100)。
- **Info.plist 实测**: NSMicrophone/NSSpeechRecognition 真实在用 (mood_audio_service speech_to_text) ✅; NSPhotoLibrary ×2 ✅; per-locale InfoPlist.strings zh-Hans/zh-Hant 4 权限文案齐全 ✅; ITSAppUsesNonExemptEncryption=false ✅; UIBackgroundModes=audio 与 ventAudioEnabled=true 匹配 ✅; entitlements 空 (无 APNs/HealthKit) ✅; AppDelegate iCloud backup 排除 MethodChannel 在 ✅。
- **IAP 实测**: productId `com.chroniccare.chroniccare.lifetime` = store_kit_service.dart:50 = STOREFRONT_RELEASE_SOP.md:76 一致 ✅; iapEnabled=false → buyLifetime 早返 false (store_kit_service.dart:105-109) → profile_group.dart:65 gate 隐藏购买卡 → main.dart:170-173 跳过 warmup; notes.txt "fully free, no IAP" 当前属实 ✅。翻 true 时联动清单: precheck_include_in_app_purchases (Fastfile:64) / notes.txt 第 8 条 / user_agreement §3 (当前"免费"措辞, assets/legal/user_agreement.md:22)。
- **无假声明实测**: `python3 scripts/check_apple_health_claim.py` PASS; lib/ 0 "Apple Health"/"HealthKit" 声明; xcprivacy 无 HealthAndFitness (R108 删, 注释完整)。

### 4.2 架构相关 (AppStore 视角)
- 无 AppStore 侧架构 P0。守门员体系 (check_review_information_todo + check_pii_in_title + check_apple_health_claim) 三层防御有效, 但 P2-02 指出 review_information 守门员 2 个防御盲区 (docstring 漂移 + 文件存在性)。
- 审计链条缺口 (流程层): R109 P0-08/09 (keywords/promotional) 宣称后从未落地, R110/R111 报告无追认机制 → 两个 P1/P2 沉底 12 天。建议新守门员或 CI checklist 收录 keywords/promotional 扫描。

### 4.3 重构建议
- check_review_information_todo.py 扩为 "check_ios_metadata.py" 三规则: (1) 现有 4 文件占位 + 存在性 (2) notes.txt 版本 (3) 新增 keywords/promotional 敏感词黑名单 (mental,health 连写 / "mental health assessments" / 病名) — 一次性 30min 根治 P1-01/P2-01 类沉底。
- Fastfile release lane 加 fail-fast (P1-03), 与 0 截图状态解耦。

### 4.4 半成品 / TODO / 残缺功能
- 实物资产 3 件套半成品: AppIcon 10.9KB (低于自设 50KB 门禁) / LaunchImage 68B×3 / 截图 0 — 全在设计师闸门外, 有 lock-in test 防回退 (4 fail 即信号)。
- review_information 4 占位 — 有守门员防"未标记回退", 但真实值必须人填 (外部)。
- Health Information Disclosure Questionnaire 未起草 (P1-04)。
- 无 macos/ 目录 (不在上架范围, 无碍)。

## 5. 总结 + 给整合者的建议

1) **代码面维持 9.5/10, R112 更干净**: AS-16/02/15/17 四项 R111 遗留全部实读验证闭环; R112 附带把 safety alert 通知里的 userName 从 title+body 双删, 锁屏 PII 收敛度超过历史任何一轮; 3 个守门员实测全绿。AppStore 视角 0 新代码 bug。
2) **整体 4.0/10 (+0.5 vs R111 3.5), 卡点不变**: 5 项 P0 100% 外部 (域名/设计师/真实信息), AI 可做的已基本做完, 剩下的唯一代码面动作 = P1-01/P1-02 (description/promotional 措辞, 15min) + P1-03 (Fastfile fail-fast, 15min)。
3) **给整合者**: (a) 本轮新发现里 P1-02 ("stay connected with loved ones" 描述已关闭功能) 是唯一真正可能被 Apple 2.1 拒的新风险, 建议本轮 10min 修; (b) P1-01/P2-01 属于 R109 声称闭环但从未落地的项, 建议修的同时补"keywords/promotional 扫描"进守门员 (P2 重构建议) 防第三次沉底; (c) 上架路径建议向用户重申: 域名 ICP 是唯一关键路径闸门, 其他全部等它。
4) **上架检查清单状态 (R112 实测)**: 代码面 ✅ / review 4 占位 ⏳外部 / notes.txt ✅ / privacy-support URL ⏳域名 / 截图 0 ⏳设计师 / LaunchImage 68B ⏳设计师 / AppIcon 10.9KB ⏳设计师 / Health 问卷 ⏳提交周 / Appfile 凭据 ⏳上架前 / 法务 3 文档 ⏳1-2 周 / DEVELOPMENT_TEAM ⏳首次 Mac build。

## 附录: 详细证据 (grep 输出、文件引用)

- 4 标记占位: `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt:1` — 内容见 P0-01; 守门员实测输出: `[check_review_information_todo.py] OK — review_information 0 未标记占位` + 4 warn + `[ok] notes.txt 版本 0.32.0+142 与 pubspec 同步` (exit 0)
- R112 description diff: en-US "Self-administered mood and mental wellbeing check-ins using two widely-recognized standardized questionnaires..." → "Optional guided self-reflection questionnaires to help you notice patterns in your feelings over time..." (同款 zh-Hans/zh-Hant 三语)
- notes.txt diff: "No third-party SDKs" → "No analytics, ad, or tracking SDKs" + 版本 0.32.0+142
- DarwinNotificationDetails 5 处: reminder_dispatcher.dart:118 / notification_service.dart:244 / badge_sync_service.dart:71 / snooze_manager.dart:102 / safety_alert_builder.dart:98
- R112 safety_alert_builder diff: `required String? userName` 参数 + `safeUserName()` 调用 + `// ignore: unused_local_variable final _ = name;` 全部删除 (notification_service.dart:385 / safety_alert_sender_impl.dart 同步)
- 资产实测: `file` 输出 — Icon 1024: "PNG image data, 1024 x 1024, 8-bit/color RGB" (10932B, 388 独特色, 0 tRNS); LaunchImage ×3: "PNG image data, 1 x 1, 8-bit gray+alpha" (68B); 全部 16 icon 无 alpha (tRNS 扫描 0 命中); Contents.json 19 条目 = 标准模板齐全
- 截图: `find fastlane/metadata/ios` — 目录仅 {en-US, review_information, zh-Hans, zh-Hant}, 0 screenshots/release_notes
- 联系人 gate: profile_group.dart:183 `if (FeatureFlags.emergencyContactEnabled) ...[`; app_router.dart grep "contacts" 0 命中
- main.dart gate: 164 `if (FeatureFlags.emergencyContactEnabled) {` (validateForRelease) / 170 `if (FeatureFlags.iapEnabled) {` (warmup)
- keywords/promotional 未落地实证: `git log --oneline -- fastlane/metadata/ios/en-US/keywords.txt` → 最后改动 556d454 (v0.27 round 68); R110 05-appstore.md + R111 04-appstore.md grep "keywords|promotional" 均 0 命中
- crisis_hotline_page.dart:58 "5 地区 (大陆/台湾/香港/美国/国际) + 1 个 800-810-1117" vs notes.txt:6 "(6 regions)"

<!-- subagent: appstore 完成时间: 2026-08-13T12:40:00+08:00 -->
