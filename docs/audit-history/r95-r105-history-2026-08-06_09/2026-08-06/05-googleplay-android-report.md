# Google Play Android 上架审计

> 审计日期: 2026-08-06
> 项目版本: 0.30.0+85 (`pubspec.yaml`)
> 审计范围: `android/` `pubspec.yaml` `lib/main.dart` `lib/core/data/services/` `lib/presentation/pages/setup/` `lib/domain/logic/care_engine.dart` `docs/` `assets/legal/` `fastlane/`
> 审计定位: 只读, 不改任何代码, 不跑 `flutter analyze` / `flutter test`

---

## 总体评估

**Google Play 上架就绪度: 38%** (代码 + 工程层基本就绪, 但法务 + 合规 + 上架材料 + 国产 ROM 推送 4 大块大量 TODO)

| 维度 | 状态 | 说明 |
|------|------|------|
| 代码架构 + 4 层纯度 | ✅ 100% | 16 守护脚本 + 0 analyzer error, 已是 v0.30.0 状态 |
| Android 工程配置 | 🟡 75% | targetSdk=36 / minSdk=24 / R8 / 64-bit / allowBackup=false / networkSecurityConfig 都对; 但 signingConfig 仍 fallback debug, **上 store 前必切** |
| Google Play 政策合规 | 🔴 30% | 隐私政策 / 用户协议 / 敏感信息同意书 3 份 md **全部 "草稿 (未经律师过审)" 标**, `LEGAL_REVIEW_BRIEF.md` 列了 12 项 P0 风险 + 10 项 P1 + 已知 P2 弱项 |
| Data Safety Form | 🟡 50% | `generate_data_safety_form.py` 自动生成模板 OK, 但**真实填表 + 提交需用户手动**; 隐私 URL `https://chroniccare.app/privacy` 是占位, 域名未注册 |
| 通知 + 国产 ROM 适配 | 🔴 35% | `NotificationStatusCard` 自检卡 + 5 品牌 OEM 引导已实装; 但**5 厂商 push SDK 0 接入** (`PUSH_PROVIDERS.md` 仅有 plan) → 国产 ROM 推送送达率 < 70% |
| 失联通知业务 | ⏸ 暂停 | `FeatureFlags._prodEmergencyContactEnabled = false` / `_prodIapEnabled = false` / `_prodBootReceiverEnabled = true`; release 模式 SMS / Email 全部 mock 守卫, 启动时 `validateForRelease` 会主动抛错 + LastErrorCapture banner |
| IAP / 内购 | ⏸ 暂停 | `in_app_purchase: ^3.3.0` 依赖装好, 但 `_prodIapEnabled = false`; `user_agreement.md §3` 写"8 元买断", **文案 vs 实际不符** (CC-3 风险) |
| 上架材料 | 🟡 60% | fastlane/metadata/{en-US, zh-CN} 基本齐; zh-CN 缺 tablet 截图; **video.txt 是 PLACEHOLDER**; 缺 Android 端 `privacy_url.txt`; 缺 Government / Health / COVID-19 声明 |

### 红线问题 (P0)

1. **3 份法律 md 未经律师过审, 标 "草稿" 状态** — `assets/legal/{privacy_policy, user_agreement, sensitive_data_consent}.md` + `LEGAL_REVIEW_BRIEF.md` 12 项 P0 全是合规灰区
2. **`signingConfig` 仍走 debug** — `android/app/build.gradle.kts:80` 注释 `// TODO 上 store 前切换`, 上 store 100% 拒
3. **隐私 / 删除 URL 是占位** — `generate_data_safety_form.py:114` `https://chroniccare.app/privacy` + `:85` `https://chroniccare.app/delete-data-instructions`, 域名未注册, Play Console Data Safety 必填项 = 拒
4. **`Appfile` 4 ID 全是 TODO** — `fastlane/Appfile:21-24` `your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`
5. **`BootReceiver` 实现是 "简化方案" TODO** — `BootReceiver.kt:18-21` 注释 "完整方案需 FlutterEngineCache + MethodChannel 调 rescheduleAll, 留给 R64 完善", 当前启动 MainActivity 简单粗暴
6. **失联通知业务 vs 隐私政策描述不一致** — `privacy_policy §0.5/§3/§12` 描述失联通知会发 SMS, 但 `FeatureFlags._prodEmergencyContactEnabled = false` + `AliyunSmsProvider.send()` 仍 `throw StateError` → **告知不准确 (PIPL §17)** + **App Store 4.3 Spam 风险**
7. **8 元买断 vs IAP 暂停** — `user_agreement.md §3` 写 "8 元买断", `StoreKitService.buyLifetime()` release 返 `false` → **描述与功能不符 (Apple 2.1)**
8. **5 厂商 push SDK 0 接** — `PUSH_PROVIDERS.md` 完整 plan 写好, **0 行实装代码**, 国产 ROM 推送送达率 < 70% → **失联通知业务上线后无效** (本项目死结)
9. **AliyunSmsProvider.send() `throw StateError` 仍占位** — `sms_service.dart:195-199` 注释 "R55 真接 TODO", 1-2 月外部依赖 (法务 + AccessKey)
10. **快速签名还是 debug, key.properties.example 占位** — `key.properties.example:6-9` 全是 `YOUR_PASSWORD` 占位

---

## 1. Google Play 政策合规

### 1.1 Data safety (数据安全)

> 当前状态: `scripts/generate_data_safety_form.py` (R72) 已实现自动生成 `build/data_safety_form.json` + `data_safety_form.md` 模板, 涵盖 4 大类 (账号 / 设备 / 应用活动 / 个人信息) + Health info 子类 (PHQ-9 / GAD-7 / Medications / Mood)。本地 SQLCipher AES-256 + Keychain 加密。App 内一键清空 + 卸载清除。

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.1.1 | 隐私 URL `https://chroniccare.app/privacy` 是占位, 域名未注册, 3 份 md 也未公开部署 | 底层 (DNS / 部署) | 2 | **P0** |
| 1.1.2 | 数据删除端点 `https://chroniccare.app/delete-data-instructions` 同上 | 底层 (DNS / 部署) | 2 | **P0** |
| 1.1.3 | `support@chroniccare.app` / `privacy@chroniccare.app` 邮箱未注册, 软隐藏决策 (`LEGACY_API_NOTES.md`) 违反 PIPL §50 "便捷联系" 原则 | 底层 (法务 + 服务) | 2 | **P0** |
| 1.1.4 | Data Safety Form 4 大类手动填, 跑脚本 ≠ 提交, 用户需登录 Play Console 填 | 流程 | 1 | P1 |
| 1.1.5 | `data_safety_form.py:32-33` `parse_privacy_policy` 用 `re.search(r'v0\.27\.0\+\d+', text)` 读版本号, 但 `privacy_policy.md` 实际**不含** `v0.27.0+85` 字样 (md 顶部只有标题), **脚本必然回退 `unknown`** → 生成的 JSON `app_version` 字段 = "unknown" | 底层 (脚本 bug) | 1 | P2 |
| 1.1.6 | 第三方 SDK 披露不完整 (`LEGAL_REVIEW_BRIEF.md` §1.8) — `privacy_policy §7` 列 6 个 SDK, 实际 `pubspec.yaml` 16 个依赖, 缺 `in_app_purchase` / `speech_to_text` / `pdf` / `printing` / `permission_handler` 等 | 法务 | 2 | P1 |
| 1.1.7 | `privacy_policy.md §1` "设备型号、操作系统版本" 描述模糊 — 法务需确认是否构成 Play "Device info" 收集 | 法务 | 2 | P1 |
| 1.1.8 | `speech_to_text: ^7.0.0` on-device STT 行为未在隐私政策明确, 是否会上云未知 | 法务 | 2 | P1 |
| 1.1.9 | `in_app_purchase` 必须收购买历史 (transaction data) — Data Safety 表需勾 "Personal info → purchase history" | 法务 | 1 | P1 |
| 1.1.10 | 加密声明 (美国 EAR / Encryption Registration) — 若用了 SSL / TLS 标准库 + SQLCipher 需在 Play Console 勾 "Use encryption" | 流程 | 1 | P2 |

**已就绪 ✅**:
- `android:allowBackup="false"` (AndroidManifest.xml:53) → PIPL §28 严禁备份 PII
- `android:dataExtractionRules` + `android:fullBackupContent` 都明确 exclude `chroniccare.sqlite` + `flutter_secure_storage` + `vent_audio` + `mood_audio`
- `android:networkSecurityConfig` 强制 `cleartextTrafficPermitted="false"`
- SQLCipher AES-256 全文加密, SecureStorage 存密钥
- 用户可请求删除 (App 内一键清 + 卸载清除)

### 1.2 Permissions (权限)

> 当前状态: `android/app/src/main/AndroidManifest.xml` 声明 8 个 uses-permission + 1 个 uses-feature (microphone)。`NotificationService.init()` 调 `requestNotificationsPermission()` (Android 13+ runtime) + iOS 三连 alert/badge/sound。

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.2.1 | 申请时机: `NotificationService.init()` 在 `main.dart:154` 启动时立即请求 POST_NOTIFICATIONS, 未在**首次触发场景**延迟申请 (Android 启动就弹通知权限) | 底层 (UX) | 2 | P1 |
| 1.2.2 | `RECORD_AUDIO` 无 runtime permission UI 路径 — `mood_audio_service.dart:194` 调 `_recorder.hasPermission()` 失败抛 `MoodAudioException('麦克风权限被拒绝')`, 但 setup 流程**未引导**用户开启 (M 录音 + 树洞录音均无引导弹窗) | 底层 (UX) | 2 | P1 |
| 1.2.3 | 缺 `permission_handler: ^11.3.1` 的应用层封装 — `pubspec.yaml:39` 装好但 `lib/` 内 0 调用 (grep 0 命中), 装的 plugin 没用上 | 底层 (冗余依赖) | 1 | P2 |
| 1.2.4 | 缺 `CAMERA` / `READ_CONTACTS` / `READ_CALENDAR` / `ACCESS_FINE_LOCATION` / `READ_EXTERNAL_STORAGE` / `READ_PHONE_STATE` / `CALL_PHONE` / `SEND_SMS` — 全部**未声明**, 符合"零云端 + 仅本地"产品定位, 风险低 | ✅ | 1 | — |
| 1.2.5 | 缺 `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MICROPHONE` (Android 14+ 必填) — 树洞录音当前**完全后台无法录**, 但产品形态不需要后台录, 风险低 | ✅ | 1 | — |
| 1.2.6 | `WAKE_LOCK` 声明但未在 BootReceiver 实际使用 — 风险低, 真实 wake lock 由 flutter_local_notifications 内部用 | ✅ | 1 | — |
| 1.2.7 | `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` 双声明 — Android 13+ Google Play 政策要求二选一, `USE_EXACT_ALARM` 用于闹钟类 App (仅当 App 核心功能是闹钟), **本 App 是 medication reminder** — 应只用 `SCHEDULE_EXACT_ALARM` (用户可拒) | 底层 (合规) | 1 | P1 |
| 1.2.8 | `BootReceiver` `android:exported="true"` — Android 12+ 必须显式声明, 当前是 true, OK; 但 BOOT_COMPLETED 隐式 Intent 要求 exported=true | ✅ | 1 | — |
| 1.2.9 | `MainActivity` `android:exported="true"` + LAUNCHER intent-filter — 标准, OK | ✅ | 1 | — |

**危险权限用得合理 ✅**:
- `RECORD_AUDIO` (mood / vent 录音, 必填)
- `POST_NOTIFICATIONS` (Android 13+ 通知, 必填)
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (medication reminder 准点推送, 必填)
- `WAKE_LOCK` (通知唤醒, 必填)
- `RECEIVE_BOOT_COMPLETED` (BootReceiver 重排通知, 必填)
- `VIBRATE` (safety alert 震动, 必填)
- `INTERNET` (SMS / Email provider, dev 调试, 必填)

### 1.3 Health Connect (Android 14+ 替代 Google Fit)

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.3.1 | **完全没接入 Health Connect** — 缺 `health_connect` plugin, 用药 / 心理 / 睡眠数据**仅本地**, 不写入 Health Connect, 也**不读** Health Connect 数据 | 架构 (设计选择) | 4 | P2 |
| 1.3.2 | 无 Google Fit OAuth 接入, 无 FitBit / Samsung Health 桥接 | 架构 | 5 | P3 |
| 1.3.3 | Health Connect 权限 (`android.permission.health.READ_STEPS` / `READ_HEART_RATE` / `READ_SLEEP`) — 当前 0 声明, 若**永远不接** Android Health = 缺失 "data portability to system" 卖点 | 架构 | 5 | P3 |

**评估**: 当前产品定位 (零云端 / 本地优先) 跟 Health Connect 哲学冲突; 接入 Health Connect = 增加攻击面 (Health Connect 是 Google Account-bound, 跟"零账号"定位冲突)。建议**长期 P3** 而非 P0/P1。

### 1.4 隐私政策 / 用户协议 / 单独同意

> 当前状态: `assets/legal/{privacy_policy.md (224 行), user_agreement.md (83 行), sensitive_data_consent.md (106 行)}` 3 份 md。`setup_step_consent.dart` 4 勾选 (R83 加 age attestation)。PIPL §13 单独同意已在 `setup_page._finishSetup` 实施 (R68, 每个联系人弹 ConsentDialog)。

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.4.1 | 3 份 md **全部标 "草稿 (未经律师过审)"** — `LEGAL_REVIEW_BRIEF.md` 列出 12 项 P0 风险需法务回答 | 法务 | 5 | **P0** |
| 1.4.2 | `LEGAL_REVIEW_BRIEF.md` §1.1: 失联通知业务暂停 vs 隐私政策描述不一致 — "会发 SMS" vs 实际 0% 触发 (PIPL §17 告知不准确 + Apple 4.3 Spam 风险) | 法务 | 2 | **P0** |
| 1.4.3 | §1.2: 紧急联系人 "单独同意" 链路不完整 — 联系人本人回复 Y 确认**未实装** (业务暂停, 依赖 SMS provider 真接) | 法务 | 3 | P0 |
| 1.4.4 | §1.3: 8 元买断 vs IAP 暂停 — `user_agreement.md §3` 写买断, `iapEnabled = false`, `buyLifetime()` release 返 `false` (Apple 2.1 / 3.1.5 + 4.3 Spam 风险) | 法务 | 1 | **P0** |
| 1.4.5 | §1.4: 数据导出 0 consent 流程 — `ConsentKind.dataExport` R63 定义, R82 改走 ConsentDialog + audit log, 但**实际 JSON 是明文**, 导出后用户自担风险未明确 | 法务 | 2 | P1 |
| 1.4.6 | §1.5: 跨境传输 PIPL §38 评估未做 — 隐私政策 §11 已描述, 但**业务暂停期间**实际 0 跨境发生; v0.28 真接 SMS 后需做 (标准合同备案 4-6 周, 安全评估 8-12 周) | 法务 | 5 | P1 |
| 1.4.7 | §1.6: 隐私 / PIPL 投诉邮箱软隐藏 — `privacy@chroniccare.app` 未注册, 7 工作日响应**无法实施** (PIPL §50) | 法务 + 服务 | 2 | **P0** |
| 1.4.8 | §1.7: 树洞 "特殊类别敏感数据" 归类不确定 (PIPL §28 vs "私密记录") | 法务 | 2 | P1 |
| 1.4.9 | §1.9: 自动化决策 / 算法透明性 (PIPL §24) — 失联检测算法未在隐私政策说明 + 拒绝方式不明确 | 法务 | 2 | P1 |
| 1.4.10 | §1.10: 免责声明边界 — `user_agreement §5` 有, 但 4 国危机热线是否完整待查 (中国 / 美国 / 英国 / 国际; 缺台湾 1925 / 香港 2389 2222) | 法务 | 1 | P1 |
| 1.4.11 | §1.11: 未成年人 14-18 周岁验证 (PIPL §31) — R83 加 age attestation 勾选, 但**"勾选"不是"验证"**, 12 岁勾 18 实操无解 | 法务 | 3 | P1 |
| 1.4.12 | §1.12: IAP 8 元买断 + 自动续费 — Apple 抽 30% / Google 15-30%, 中国 "明码标价" 合规待查 | 法务 | 1 | P2 |
| 1.4.13 | §2.5: 多语言版本差异 — zh / en / zh_Hant 3 ARB 同步, en 缺 GDPR / CCPA 引用, zh_Hant 港澳台缺独立法律声明 | 法务 | 2 | P1 |
| 1.4.14 | §2.6: 协议变更通知 — "继续使用视为同意" 在敏感信息场景 PIPL §14 **不适用**, 需重走同意 | 法务 | 2 | P2 |
| 1.4.15 | §2.7: 删除权时效 — 7 工作日 (未成年人) ✓, 成年人无 15 工作日承诺 | 法务 | 1 | P2 |
| 1.4.16 | §2.8: 数据导出 / 导入风险 — JSON 明文 + 导入覆盖未明示 "物理删除" | 法务 | 1 | P2 |
| 1.4.17 | §2.9: "勾选才能用" 强迫同意 vs PIPL §14 自愿原则 | 法务 | 1 | P2 |
| 1.4.18 | §2.10: 政策措辞准确性 — "因为我们没有服务器" 算承诺还是事实陈述 | 法务 | 1 | P2 |

**已就绪 ✅**:
- 4 勾选 (R83: 3 协议 + 1 年龄严正声明)
- PIPL §13 单独同意: `setup_page._finishSetup` R68 实装, 每个联系人弹 ConsentDialog
- PIPL §14 撤回同意: R67 真正生效 (CareEngine.fire / VentRepository.add / trend_page 拦截)
- 同意记录可审计: `user_profiles.consent_*` 字段持久化
- Legal version 同步: R77 改走 `legalVersionProvider` 启动时算一次, pubspec 升版本时手动同步

### 1.5 内购 / 订阅 (Google Play Billing)

> 当前状态: `in_app_purchase: ^3.3.0` 依赖装好, `StoreKitService` 单例封装, `FeatureFlags._prodIapEnabled = false` 业务暂停。

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.5.1 | **GPB 未真接** — `StoreKitService.buyLifetime()` `sms_service.dart:119` release 模式返 `false` (Apple IAP / Google Play Billing 0 实际购买流); `user_agreement.md §3` 写 "8 元买断" = 描述 vs 实际不符 (CC-3) | 底层 + 法务 | 3 | **P0** |
| 1.5.2 | Google Play Console **必须**用 Google Play Billing (GPB), 不能用第三方支付 — 当前 `_prodIapEnabled = false` 是临时绕路, 上 store 前必开 | 底层 (合规) | 3 | **P0** |
| 1.5.3 | productId `com.chroniccare.app.lifetime` 在 Google Play Console / App Store Connect **未创建** | 后台 | 2 | **P0** |
| 1.5.4 | 8 元定价是否合理 (中国 "明码标价" + 平台抽成 30% → 开发者 5.6 元) | 法务 + 产品 | 1 | P1 |
| 1.5.5 | 退款政策 (`user_agreement §4` 24 小时内未使用核心功能可全额退款) — 需匹配 Apple / Google 平台规则 | 法务 | 1 | P1 |
| 1.5.6 | NonConsumablePurchase (一次性买断) vs Subscriptions — 文档已选 NonConsumable, 8 元买断合规 | ✅ | 1 | — |
| 1.5.7 | 试用期 / 宽限期 — NonConsumable 不适用 | ✅ | 1 | — |
| 1.5.8 | 订阅管理 — 一次性买断无订阅, OK | ✅ | 1 | — |

### 1.6 内容审核 / IARC

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.6.1 | **Content Rating (IARC)** — Play Console 上架时必填问卷; 精神心理类 App 勾 "Health" + "Medical" 类, 评分可能 T (Teen 13+) 或 PEGI 12+ | 流程 | 1 | P1 |
| 1.6.2 | "Mental health" / "Health" 标签 — Play Console Category 选 "Health & Fitness" 还是 "Medical" 待定 (影响 IARC 问卷 + 审核严格度) | 产品 + 法务 | 1 | P1 |
| 1.6.3 | 树洞 (UGC) — UGC 需 UGC policy: 用户可举报 / 屏蔽 / 关键词过滤; **树洞内容完全私密不进任何统计**, 但 UGC 政策仍要求 | 法务 + 产品 | 3 | P2 |
| 1.6.4 | 心理健康内容: 不能给医疗建议 — `full_description.txt` 已加 "IMPORTANT: ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment" | ✅ | 1 | — |
| 1.6.5 | 危机干预 / 紧急联系人 — 4 国热线 (US 988 / UK 116 123 / China 400-161-9995 / International findahelpline.com) + 北京 010-82951332 / 上海 021-12320-5 | ✅ | 1 | — |
| 1.6.6 | 台湾 1925 / 香港 2389 2222 / 澳门热线 — 港澳台 zh_Hant 用户**未覆盖** (LEGAL_REVIEW_BRIEF §1.10) | 法务 | 1 | P1 |

### 1.7 医疗健康类 App 额外审查

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 1.7.1 | "Medical" / "Health" 类 — Play Console 标签 + IARC 问卷联动 | 流程 | 1 | P1 |
| 1.7.2 | **Medical Device 风险: 用药提醒是否构成医疗器械?** — `DEPLOYMENT.md` 附录 A.1 NMPA "非医疗器械" 声明模板已写, 但**未实装为 PDF 提交**; 精神心理患者用药提醒 ≠ 医疗器械 (NMPA 6810 类), 但 Apple / Google 可能要求 formal declaration | 法务 | 2 | P1 |
| 1.7.3 | FDA / NMPA 认证 — 中国大陆上架**不强制 FDA** (非美国市场), NMPA "非医疗器械" 声明**强烈建议** | 法务 | 2 | P1 |
| 1.7.4 | 临床声明限制 — `full_description.txt` 已写 "personal tracking tool only", "PHQ-9 ... Built-in PHQ-9 (depression) and GAD-7 (anxiety) screening" 用 "screening" 一词可能触发 "medical claim" 风险 (Apple 5.2.1) | 法务 | 1 | P1 |
| 1.7.5 | 心理评估**结果给分 + 严重度分级** (`assessment_comparison`) — 严格按 Apple 5.2.1 不能 "diagnose" 但可 "inform"; 当前文案 "screening" OK | ✅ | 1 | — |
| 1.7.6 | 危机资源弹窗 — `PHQ-9 score >= 15` (中重度) 自动显示热线, `LEGACY_API_NOTES.md` 5 国热线待补 | ✅ | 1 | — |

---

## 2. Android 平台规范

### 2.1 Target SDK / Min SDK

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 2.1.1 | `compileSdk` | ✅ | `flutter.compileSdkVersion` (Flutter 3.41.9 默认 36) |
| 2.1.2 | `minSdk` | ✅ | 24 (R63 显式 pin, Flutter 3.41.9 默认 24) |
| 2.1.3 | `targetSdk` | ✅ | 36 (R63 显式 pin, Google Play 2025-08 强制 Android 16) |
| 2.1.4 | Android 14 (API 34) 适配 | ✅ | `enableOnBackInvokedCallback="true"` (R63 预测式返回手势) |
| 2.1.5 | Android 15 (API 35) 适配 | 🟡 | `targetSdk=36` 已超 35, **但 edge-to-edge 强制**未处理 (Android 15 强制 enableEdgeToEdge) — `MainActivity.kt:1-4` 是 `FlutterActivity` 默认实现, **未调 `WindowCompat.setDecorFitsSystemWindows(window, false)`** |
| 2.1.6 | Android 16 (API 36) 适配 | ✅ | targetSdk 已 36 |
| 2.1.7 | 16KB page size | ✅ | R70 验脚本 (`check_16kb_alignment.py`) 通过; Flutter 3.41.9 + SQLCipher 0.6.8 + record 5.2.0 + audioplayers 6.1.0 + flutter_secure_storage 9.2.2 都已 16KB 对齐; 但**未显式声明 ndkVersion** (`build.gradle.kts:11` 用 `flutter.ndkVersion` 隐式依赖) |

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.1.a | **Android 15 edge-to-edge 未适配** — `MainActivity.kt` 纯默认 `FlutterActivity` 未调 `WindowCompat.setDecorFitsSystemWindows(window, false)`, Android 15 设备 status bar / navigation bar 会盖住 UI | 底层 (Kotlin) | 2 | P1 |
| 2.1.b | `ndkVersion` 未显式声明 — Flutter 升级时默认值变化风险 (R63 注释) | 底层 (Kotlin) | 1 | P2 |
| 2.1.c | Android 14 partial photo access (READ_MEDIA_VISUAL_USER_SELECTED) — 本 App 0 媒体访问, 不受影响 | ✅ | 1 | — |

### 2.2 启动 / 闪屏 (SplashScreen API)

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.2.1 | **未用 SplashScreen API (Android 12+ 强制)** — `values/styles.xml:4-7` + `values-night/styles.xml:4-7` 用 `android:windowBackground` 旧式 splash, Android 12+ 设备仍能用, 但**不**符合 Google 推荐的 SplashScreen API (Android 12 起强制) | 底层 (Kotlin) | 2 | P1 |
| 2.2.2 | **无 monochrome splash icon** — Android 12+ SplashScreen API 要求 `mipmap-anydpi-v26/ic_launcher_monochrome.xml`, **完全不存在** (`Get-ChildItem` mipmap-anydpi-v26 = False) | 底层 (res) | 2 | P1 |
| 2.2.3 | `launch_background.xml` 是纯白底, 无品牌 logo 居中 — 体验 OK 但不品牌化 | UX | 1 | P2 |
| 2.2.4 | `applicationName="${applicationName}"` 走 Flutter 默认 (`io.flutter.app.FlutterApplication`), OK | ✅ | 1 | — |
| 2.2.5 | `MainActivity` `android:configChanges` 覆盖 11 项, OK, 避免 Activity 重建 | ✅ | 1 | — |
| 2.2.6 | `android:hardwareAccelerated="true"` OK | ✅ | 1 | — |
| 2.2.7 | `android:windowSoftInputMode="adjustResize"` OK | ✅ | 1 | — |
| 2.2.8 | `android:taskAffinity=""` — 防 task hijacking, OK | ✅ | 1 | — |
| 2.2.9 | `android:launchMode="singleTop"` — 标准 LAUNCHER, OK | ✅ | 1 | — |

### 2.3 Background (后台)

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.3.1 | **BootReceiver 简化方案 (TODO)** — `BootReceiver.kt:18-21` 注释 "完整方案需 FlutterEngineCache.getInstance().get(engineId) 复用 engine + MethodChannel 调 Flutter 侧 rescheduleAll, 留给 R64 完善", 当前 `startActivity(MainActivity)` 强制拉起 UI 极不优雅 (用户重启手机后 App 莫名打开) | 底层 (Kotlin) | 3 | **P0** |
| 2.3.2 | `WorkManager` (后台任务) — 0 接入, 重启后通知重排全靠 BootReceiver 拉起 MainActivity (有 bug 风险) | 底层 (Java/Kotlin) | 4 | P1 |
| 2.3.3 | `FOREGROUND_SERVICE_TYPE_*` (Android 14+ 必填) — 0 Foreground Service 声明, 树洞 / 情绪录音**完全后台无法录**; 产品定位是"前台录"风险低 | ✅ | 1 | — |
| 2.3.4 | 国产 ROM 杀后台 — 见 §5 | — | — | — |

### 2.4 通知 (Notification)

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 2.4.1 | `NotificationChannel` (Android 8+ 必填) | ✅ | 2 channel: `chroniccare.medication` (default) + `chroniccare.safety` (high) |
| 2.4.2 | `IMPORTANCE_DEFAULT` (medication) + `IMPORTANCE_HIGH` (safety) | ✅ | `notification_service.dart:202-205` 用 default, safety 走 builder |
| 2.4.3 | `POST_NOTIFICATIONS` runtime (Android 13+) | ✅ | `notification_service.dart:174` 调 `requestNotificationsPermission()` |
| 2.4.4 | 通知分组 / 通知设置 | ❌ | 0 通知 group + 0 设置 deep link (`app/settings/notification`) |
| 2.4.5 | Doze Mode / App Standby | ✅ | `androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle` 3 处使用 |
| 2.4.6 | 全屏 Intent (紧急情况) | ❌ | safety alert 当前只是 IMPORTANCE_HIGH + 锁屏可见, 0 全屏 Intent |
| 2.4.7 | 通知样式 (BigText / BigPicture / Messaging / Media) | ❌ | 0 BigTextStyle 等, body 截断后体验差 |
| 2.4.8 | 通知操作 (Action) | ❌ | medication reminder 0 "我已吃药" / "推迟 10min" quick action |
| 2.4.9 | 直接回复 (Direct Reply) | ❌ | 0 RemoteInput |
| 2.4.10 | 气泡 (Bubble) (Android 11+) | ❌ | 0 bubble metadata |

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.4.a | medication reminder 0 通知 action (snooze / done) — 用户点通知只跳页面, 不能直接处理 | UX | 2 | P1 |
| 2.4.b | 0 BigTextStyle — 长 body 截断 | UX | 1 | P2 |
| 2.4.c | 0 全屏 Intent safety alert — 用户错过通知后无强提示 (精神心理患者失联场景) | UX + 底层 | 2 | P1 |
| 2.4.d | 0 通知 group / 通知设置 deep link | UX | 1 | P2 |

### 2.5 音频

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.5.1 | `MediaRecorder` 配置 — `mood_audio_service.dart:203-207` `RecordConfig(encoder: AAC, bitRate: 64000, sampleRate: 44100)` OK, 跟 `record: ^5.2.0` plugin | ✅ | 1 | — |
| 2.5.2 | `FOREGROUND_SERVICE_MICROPHONE` (Android 14+) — 0 声明, 当前 mood/vent 录音**完全前台**, 后台录音会崩 | UX | 2 | P2 (后台录音需求不明确) |
| 2.5.3 | Audio Focus — 0 显式调 `requestAudioFocus`, 跟其他 App 抢麦 (微信来电 / 音乐 App) 体验差 | UX | 2 | P2 |
| 2.5.4 | 蓝牙 / 耳机 route change — 0 listener, 拔耳机录音继续 | UX | 2 | P2 |
| 2.5.5 | MediaSession (锁屏控制 / 蓝牙控制) — 0 实装, 树洞播放锁屏无控制 (audioplayers 6.1.0 默认无) | UX | 3 | P3 |
| 2.5.6 | AAudio / Oboe — 0 使用, `record: ^5.2.0` 默认走 AudioRecord, 性能 OK 但非低延迟 | UX | 4 | P3 |

### 2.6 文件 / 存储

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 2.6.1 | Scoped Storage (Android 10+) | ✅ | App 私有目录 (`getApplicationDocumentsDirectory()`), 无 MANAGE_EXTERNAL_STORAGE |
| 2.6.2 | `MANAGE_EXTERNAL_STORAGE` (限制) | ✅ | 0 声明, 不需要 |
| 2.6.3 | 内部存储 (`getFilesDir` / `getCacheDir`) | ✅ | `path_provider` 走默认, 录音 + 临时文件 OK |
| 2.6.4 | Auto Backup 排除 | ✅ | `backup_rules.xml` 排除 sqlite + secure_storage + vent_audio + mood_audio |
| 2.6.5 | Key-Value Backup | ✅ | 同上 |
| 2.6.6 | SQLCipher 加密 | ✅ | `sqlcipher_flutter_libs: ^0.6.5` 装好, Drift 用 `NativeDatabase` + `openOnWeb` + password |
| 2.6.7 | `EncryptedSharedPreferences` (DB 密钥) | ✅ | `flutter_secure_storage: ^9.2.2` 走 Android EncryptedSharedPreferences / iOS Keychain |
| 2.6.8 | Android Keystore | ✅ | flutter_secure_storage 内部用, 设备绑定 |
| 2.6.9 | `android:allowBackup="false"` | ✅ | AndroidManifest.xml:53 |
| 2.6.10 | 录音文件 AES-256 加密 | ✅ | `EncryptedAudioStorage` 基类 + `VentAudioStorage` + `MoodAudioStorage` |
| 2.6.11 | 树洞文字 AES-256 字段级加密 | ✅ | `ExportCryptoService` + `EncryptionService` (隐私政策 §2 描述) |

### 2.7 数据库

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 2.7.1 | drift Room / SQLite | ✅ | `drift: ^2.20.3` + SQLCipher |
| 2.7.2 | `onUpgrade` migration | ✅ | `app_database.dart` schemaVersion=12, migration 函数定义 (AGENTS.md 提到 12 + 11 守护脚本) |
| 2.7.3 | WAL mode | ✅ | drift 默认开 |
| 2.7.4 | Foreign key | ✅ | drift `references` 声明 |

### 2.8 性能

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.8.1 | Flutter Engine 启动 — 0 测量 | 流程 | 3 | P2 |
| 2.8.2 | 冷启动 / 温启动 / 热启动 — 0 数据 | 流程 | 3 | P2 |
| 2.8.3 | 内存泄漏 — `check_widget_dispose.py` 守门员, R0x 多次修; `R17+R56b BuildContext 跨 async gap` 是已知模式 | ✅ | 1 | — |
| 2.8.4 | ANR 风险 — 0 监控 | 流程 | 3 | P2 |
| 2.8.5 | StrictMode — 0 启用 | 流程 | 1 | P2 |
| 2.8.6 | Battery Historian — 0 测量 | 流程 | 3 | P3 |
| 2.8.7 | `runZonedGuarded` 全局错误兜底 + `LastErrorCapture` + `last_startup_error_banner` 显式告警 | ✅ | 1 | — |

### 2.9 可访问性 (Accessibility)

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 2.9.1 | TalkBack — 0 系统化审查, 部分 widget 缺 `Semantics(label: ...)` | UX | 3 | P1 |
| 2.9.2 | 字体缩放 — Flutter 默认支持, 但 `app_tokens.dart` 有 `fontSizeCaption = 12` 等小字, **未做 textScaleFactor 自适应** | UX | 2 | P1 |
| 2.9.3 | 高对比度 — 0 dark mode 强化 (`values-night/styles.xml:4-7` 仅 `Theme.Black.NoTitleBar`, UI 内 colorScheme 已 dark OK) | UX | 2 | P2 |
| 2.9.4 | Reduce Motion — Flutter 0 系统化 `MediaQuery.disableAnimations` 处理 | UX | 2 | P2 |
| 2.9.5 | 触摸目标大小 (48dp+) — `app_tokens.dart` 0 显式 48dp 最小目标常量, 个别 IconButton 偏小 (`iconSizeEmpty` 等) | UX | 2 | P1 |

### 2.10 国产 ROM 适配 (重点)

见 §5 专项。

---

## 3. Android 工程配置

### 3.1 `android/app/build.gradle.kts`

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 3.1.1 | `namespace` | ✅ | `com.chroniccare.chroniccare` |
| 3.1.2 | `applicationId` | ✅ | 同上 |
| 3.1.3 | `compileSdk` | ✅ | flutter 默认 (36) |
| 3.1.4 | `minSdk` | ✅ | 24 (R63 显式) |
| 3.1.5 | `targetSdk` | ✅ | 36 (R63 显式) |
| 3.1.6 | `versionCode` / `versionName` | ✅ | flutter.versionCode / flutter.versionName (跟 pubspec 同步) |
| 3.1.7 | Java 17 | ✅ | `JavaVersion.VERSION_17` |
| 3.1.8 | Kotlin | ✅ | `2.2.20` |
| 3.1.9 | `multiDexEnabled` | ✅ | true (4D 情绪 + audio + 多个 plugin 触发 64K) |
| 3.1.10 | `signingConfigs.release` 块 | 🟡 | 已加, 但默认 fallback debug (R67 注释 "上 store 前必走 5 步") |
| 3.1.11 | `buildTypes.release.signingConfig` | ❌ | **当前 `signingConfigs.getByName("debug")`** — `build.gradle.kts:80` TODO 注释 |
| 3.1.12 | `buildTypes.release.isDebuggable` | ✅ | false (R63 显式) |
| 3.1.13 | `buildTypes.release.isJniDebuggable` | ✅ | false (R63 显式) |
| 3.1.14 | `isMinifyEnabled` | ✅ | true (R8) |
| 3.1.15 | `isShrinkResources` | ✅ | true |
| 3.1.16 | `proguardFiles` | ✅ | `proguard-android-optimize.txt` + `proguard-rules.pro` |
| 3.1.17 | `abiFilters` | ✅ | `arm64-v8a` + `x86_64` (R70 显式 64-bit) |
| 3.1.18 | `ndkVersion` 显式 | 🟡 | 走 `flutter.ndkVersion` 隐式 |

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 3.1.a | **`signingConfig = signingConfigs.getByName("debug")`** — 必须切到 release (按 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步) | 底层 (Kotlin + 文件) | 2 | **P0** |
| 3.1.b | `ndkVersion` 显式声明建议 — 加 `ndkVersion = "27.0.12077973"` (R70 推荐) | 底层 (Kotlin) | 1 | P2 |

### 3.2 `android/build.gradle.kts` + `android/settings.gradle.kts`

| # | 项 | 状态 |
|---|----|------|
| 3.2.1 | `allprojects.repositories` (google + mavenCentral) | ✅ |
| 3.2.2 | `pluginManagement` (google + mavenCentral + gradlePluginPortal) | ✅ |
| 3.2.3 | AGP `8.11.1` | ✅ |
| 3.2.4 | Kotlin `2.2.20` | ✅ |
| 3.2.5 | Gradle `8.14` (wrapper) | ✅ |
| 3.2.6 | Flutter Gradle Plugin (`1.0.0`) | ✅ |
| 3.2.7 | `flutter-plugin-loader` | ✅ |

### 3.3 `android/gradle.properties`

```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
```

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 3.3.a | 缺 `android.enableJetifier=false` (项目 0 旧 support library, 显式禁 Jetifier 加速 build) | 底层 (Kotlin) | 1 | P3 |
| 3.3.b | 缺 `kotlin.code.style=official` (跟 `flutter_lints` 风格统一) | 底层 (Kotlin) | 1 | P3 |
| 3.3.c | 缺 `org.gradle.caching=true` / `org.gradle.parallel=true` (CI build 加速) | 底层 (Kotlin) | 1 | P3 |

### 3.4 `android/app/proguard-rules.pro`

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 3.4.1 | Flutter wrapper | ✅ | `-keep class io.flutter.**` |
| 3.4.2 | flutter_local_notifications | ✅ | `-keep class com.dexterous.**` |
| 3.4.3 | audioplayers | ✅ | `-keep class xyz.luan.audioplayers.**` |
| 3.4.4 | record | ✅ | `-keep class com.llfbandit.record.**` |
| 3.4.5 | sqlcipher_flutter_libs | ✅ | `-keep class net.zetetic.**` |
| 3.4.6 | speech_to_text | ✅ | `-keep class com.csdcorp.speech_to_text.**` |
| 3.4.7 | flutter_secure_storage | ✅ | `-keep class com.it_nomads.fluttersecurestorage.**` |
| 3.4.8 | share_plus | ✅ | `-keep class dev.fluttercommunity.plus.share.**` |
| 3.4.9 | drift (path_provider) | ✅ | `-keep class io.requery.android.database.**` |
| 3.4.10 | 行号 (crash report) | ✅ | `-keepattributes SourceFile,LineNumberTable` + `-renamesourcefileattribute` |
| 3.4.11 | `com.chroniccare.chroniccare.**` keep | ✅ | R63 显式 |
| 3.4.12 | **缺 `in_app_purchase` R8 keep** — `com.android.billingclient.**` 第三方支付 SDK, 上 store 前必加 | 底层 (Kotlin) | 1 | **P0** |
| 3.4.13 | **缺 `permission_handler` R8 keep** — `com.baseflow.permissionhandler.**` | 底层 (Kotlin) | 1 | P1 |

### 3.5 签名 (debug / release)

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 3.5.1 | **debug 签名** — 当前 `release.signingConfig = debug` | 底层 (Kotlin) | 2 | **P0** |
| 3.5.2 | **Play App Signing 未启用** — 需 Play Console → App signing → Use Google Play App Signing + 上传 keystore | 后台 | 2 | **P0** |
| 3.5.3 | **upload key 未生成** — `android/key.properties` 不存在 (`.example` 占位) | 后台 | 2 | **P0** |
| 3.5.4 | 签名 v1 / v2 / v3 / v3.1 / v4 — 默认 v2 + v3 (Android Studio 默认), 0 显式; AAB 走 v3 | ✅ | 1 | — |
| 3.5.5 | keystore 备份方案 — `generate_release_keystore.ps1` 脚本化, `.gitignore` 已排除 `.jks` + `key.properties` | ✅ | 1 | — |

### 3.6 App Bundle (`.aab`) vs APK

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 3.6.1 | `flutter build appbundle --release` 可产出 | ✅ | fastlane `:android internal` lane 配 `task: "bundleRelease"` |
| 3.6.2 | Play App Signing (AAB only) | ✅ (待启用) | 见 3.5.2 |
| 3.6.3 | APK 备份 (备历史) | ❌ | 当前 fastlane `:android internal` `skip_upload_apk: true` (只传 AAB) |

### 3.7 资源缩减 (R8 / ProGuard)

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 3.7.1 | R8 已开 | ✅ | `isMinifyEnabled = true` |
| 3.7.2 | resource shrink 已开 | ✅ | `isShrinkResources = true` |
| 3.7.3 | R8 mapping 留存 — `mapping.txt` 默认在 `build/app/outputs/mapping/release/mapping.txt` | ✅ (R8 默认) | 1 | — |
| 3.7.4 | 多 dex | ✅ | `multiDexEnabled = true` |

### 3.8 `android/local.properties` (开发本地, 不入仓)

```properties
sdk.dir=C:\\Users\\18449\\AppData\\Local\\Android\\sdk
flutter.sdk=D:\\tools\\flutter
flutter.buildMode=debug
flutter.versionName=0.25.0  # ⚠️ 跟 pubspec 0.30.0 不一致
flutter.versionCode=1        # ⚠️ 跟 pubspec 85 不一致
```

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 3.8.a | `flutter.versionName=0.25.0` / `flutter.versionCode=1` 跟 `pubspec.yaml 0.30.0+85` **不一致** — `local.properties` 是开发机本地, 不入仓, 但 IDE 读这个值可能误显示 | 底层 (本地配置) | 1 | P3 (本地, 不影响 release) |

---

## 4. 上架材料 (Listing Materials)

### 4.1 Play Console 元数据 (fastlane/metadata/android/)

| # | 项 | zh-CN | en-US | 状态 |
|---|----|-------|-------|------|
| 4.1.1 | `title.txt` | (缺文件) | "ChronicCare - Med Reminder" | 🟡 zh-CN 缺 |
| 4.1.2 | `short_description.txt` | (缺文件) | "Daily check-in + mood tracker for people managing chronic conditions. Private & local." | 🟡 zh-CN 缺 |
| 4.1.3 | `full_description.txt` | ✅ 中文完整 | ✅ 英文完整 | ✅ |
| 4.1.4 | `icon.png` | ✅ | ✅ | ✅ |
| 4.1.5 | `feature_graphic.png` | ✅ | ✅ | ✅ |
| 4.1.6 | `video.txt` | ⚠️ "PLACEHOLDER_APP_DEMO_VIDEO" | ⚠️ 同 | ❌ 占位 |
| 4.1.7 | `phone_screenshots/` (4 张) | ✅ | ✅ | ✅ |
| 4.1.8 | tablet screenshots (7" / 10") | ❌ | ❌ | ❌ |
| 4.1.9 | `privacy_url.txt` (Android) | ❌ | ❌ | ❌ (iOS 端有) |
| 4.1.10 | `category.txt` (Health & Fitness / Medical) | ❌ | ❌ | ❌ |
| 4.1.11 | 联系人邮箱 (`contact_email.txt`) | ❌ | ❌ | ❌ |
| 4.1.12 | changelog | fastlane 自动 | 同 | ✅ |

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 4.1.a | **`video.txt` 是占位 URL** — `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO` → Play Console 上传时**报错** (YouTube 视频 ID 不存在) | 底层 (内容) | 1 | **P0** |
| 4.1.b | zh-CN 缺 `title.txt` / `short_description.txt` — fastlane 跳过空文件 = zh-CN 用户看到 en 标题 | 内容 | 1 | P1 |
| 4.1.c | **缺 tablet screenshots** (7" / 10") — Play Console 必填, 上传时强制 | 流程 + 内容 | 2 | **P0** |
| 4.1.d | **缺 `privacy_url.txt` (Android)** — iOS 端有, Android 端 fastlane metadata 没建 | 底层 (内容) | 1 | **P0** |
| 4.1.e | **缺 `category.txt` (Health & Fitness / Medical)** — 选错类 = 审核方向错 | 产品 | 1 | P1 |
| 4.1.f | 缺 `contact_email.txt` — `support@chroniccare.app` 未注册 | 流程 | 1 | **P0** |
| 4.1.g | `phone_screenshots/` 命名 1-4 vs 01-05 — iOS 是 `01_home.png` 风格, Android 是 `screenshot_1.png`, **风格统一即可** | ✅ | 1 | — |

### 4.2 应用说明 (短 80 字 / 长 4000 字)

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 4.2.1 | 短 80 字 | ✅ | "Daily check-in + mood tracker for people managing chronic conditions. Private & local." |
| 4.2.2 | 长 4000 字 | ✅ | en-US 完整 (含 4 国危机热线 + Privacy commitment + WHO IS THIS FOR + IMPORTANT) |
| 4.2.3 | zh-CN 长描述 | ✅ | 含北京 010-82951332 / 上海 021-12320-5 / 全国 400-161-9995 热线; **缺台湾 1925 / 香港 2389 2222** |

### 4.3 分类 / 标签 / 内容分级

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 4.3.1 | Category | ❌ | 缺 `category.txt` |
| 4.3.2 | Tags | ❌ | 缺 `tags.txt` |
| 4.3.3 | IARC Content Rating | ❌ | 未填 (上架时 Play Console 强制问卷) |
| 4.3.4 | Target Audience | ❌ | 未填 (建议 12+ / Teen) |

### 4.4 隐私权政策链接 / 数据安全表单

见 §1.1。

### 4.5 政府部门应用声明 / 健康应用声明 / COVID-19 声明 / 加密声明

| # | 项 | 状态 | 说明 |
|---|----|------|------|
| 4.5.1 | Government app declaration (中国政府应用) | ❌ | `isGovernmentApp: false` 应勾 |
| 4.5.2 | Health apps declaration (健康应用声明) | ❌ | `isHealthApp: true` 应勾 (PHQ-9 / GAD-7 + 树洞 = 健康相关) |
| 4.5.3 | COVID-19 apps declaration | ❌ | `isCovid19App: false` 必填 (不勾不让提交) |
| 4.5.4 | Encryption declaration (美国 EAR) | ❌ | `useEncryption: true` 应勾 (SSL/TLS + SQLCipher) |
| 4.5.5 | Ads declaration | ❌ | `isAdSupported: false` 应勾 |
| 4.5.6 | In-app purchase declaration | ❌ | `isIap: true` 应勾 (8 元买断) |
| 4.5.7 | Data safety form | 🟡 | 脚本生成模板, 用户需手动提交 (见 §1.1) |

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 4.5.a | **5 项 Play Console 上架时强制声明 0 维护** — Government / Health / COVID-19 / Encryption / Ads / IAP 必填, 漏填 = 拒提交 | 流程 | 1 | **P0** |

---

## 5. 国产 ROM 适配 (重点 — 用户基线)

> 当前状态: `NotificationStatusCard` 自检卡 + 5 品牌 OEM 引导 (Xiaomi / Huawei / OPPO / vivo / Meizu) 实装在 `lib/presentation/pages/settings/widgets/notification_status_card.dart`。`OemBackgroundHint` 折叠 + `_OemBrand` 品牌步骤。

| # | 问题 | 类型 | 难度 | 优先级 |
|---|------|------|------|--------|
| 5.1 | **5 厂商 push SDK 0 接入** — `docs/PUSH_PROVIDERS.md` 完整 plan 写好, 估时 1-2 月, **0 行实装代码**; 国产 ROM 推送送达率 < 70% → 失联通知业务上线后**无效**, 死结 | 底层 (SDK 集成) | 5 (每厂 1-2 周审核) | **P0** |
| 5.2 | `MiPush` / `mipush` / `huawei_push` / `oppo_push` / `vivo_push` / `mzpush` 依赖 0 添加 (`pubspec.yaml` grep 0 命中) | 底层 (依赖) | 1 | **P0** |
| 5.3 | `firebase_messaging` 0 添加 — 海外用户兜底, 缺 | 底层 (依赖) | 1 | P1 |
| 5.4 | 通知自检卡 `NotificationStatusCard` 实装 OK (R20 + R40 + R56b 多轮迭代) | ✅ | 1 | — |
| 5.5 | OEM 引导文字 5 品牌 (自启动 / 精确闹钟 / 省电白名单) 实装 OK | ✅ | 1 | — |
| 5.6 | 国产 ROM 通知权限默认禁用 — 自检卡 + 引导已处理 | ✅ | 1 | — |
| 5.7 | 锁屏显示 — flutter_local_notifications 默认走 channel visibility, OK | ✅ | 1 | — |
| 5.8 | 通知栏收纳 (华为 / 小米支持) — 0 实装 (Android 系统默认有, 不强求) | ✅ | 1 | — |
| 5.9 | **Battery Historian 0 测量** — 国产 ROM 耗电是上架后用户投诉重点 | 流程 | 3 | P2 |
| 5.10 | **0 接厂商后台管理 SDK** (推送) — 即使上 store 推送率 < 70%, 长期死结 | 架构 | 5 | **P0** |

**总结**: 国产 ROM 适配**已就绪 UX 层 (自检卡 + 引导)**, **未就绪 SDK 层 (5 厂商 push)**。**这是本项目最大 P0**: 精神心理患者 + 失联通知 + 国产 ROM 推送率 < 70% = **核心安全承诺失败**。

---

## 6. 已知 Android 坑 / 待办

| # | 已知坑 | 状态 | 说明 |
|---|--------|------|------|
| 6.1 | Android 14 partial photo access (`READ_MEDIA_VISUAL_USER_SELECTED`) | ✅ 不受影响 | App 0 媒体访问 |
| 6.2 | Android 14 foreground service type | ✅ 不受影响 | 0 Foreground Service |
| 6.3 | Android 15 edge-to-edge 强制 | ❌ 未适配 | `MainActivity` 纯默认, 未调 `WindowCompat.setDecorFitsSystemWindows(window, false)` |
| 6.4 | Android 16 (Baklava) 预览 | ✅ 兼容 | targetSdk=36 |
| 6.5 | 国产 ROM 后台限制 | ❌ 未解决 | 见 §5 |
| 6.6 | targetSdk 升级影响 | ✅ | R63 显式 pin 36 |
| 6.7 | 签名 v1 / v2 / v3 / v3.1 / v4 | ✅ | AAB 走 v3 (默认) |
| 6.8 | 16KB page size (Google Play 2025-11 强制) | ✅ | R70 验脚本通过 |
| 6.9 | Multidex 64K | ✅ | `multiDexEnabled = true` |
| 6.10 | `flutter gen-l10n` 反复误删 3 个 `ventDuration*` 键 (R88 known regression) | ❌ 已知 | 每次 gen-l10n 手动 re-insert, R89 计划加 `gen_l10n_diff_check.py` |
| 6.11 | 链接 `BuildContext` 跨 async gap (`use_build_context_synchronously`) | 🟡 | R17+R56b 已知模式, 27 处 `!mounted` check; analyzer 仍 warn |
| 6.12 | `flutter_secure_storage` 部分 Android 设备首启 ~200ms 延迟 (README 已知) | 🟡 | 用户感知风险低, 不修 |
| 6.13 | `dart format` + `dart fix --apply` 反复 trailing commas | 🟡 | 工具组合已知, 不修 |
| 6.14 | `dart:io` 跨层使用 — 严格说违反 4 层架构 (但 `lib/core/data/` 允许) | ✅ | 守门员 `check_all.dart` 通过 |
| 6.15 | `R.string.localization_provider` 跨平台 | 🟡 | R77 legal version 同步, 改一处 + pubspec bump 手动同步 |
| 6.16 | Stream subscription leak | ✅ | check_widget_dispose.py 守门 |
| 6.17 | `audioplayers + record` 同进程文件锁冲突 | ✅ | AGENTS.md 已知坑, "先 dispose recorder 再 dispose player" |
| 6.18 | `VentEntryEntity` vs `VentEntry` 命名 | ✅ | AGENTS.md 注释, 守门 |
| 6.19 | Drift `*_rowToEntity` 漏字段 (R91 Critical #1 修) | ✅ | R91 + 22 regression test |

---

## 修复路线 (按 P0 → P3 排)

### P0 — 上架 blocker (不修 = 100% 拒)

1. **[P0] 切 `signingConfig` 到 release** (`build.gradle.kts:80`) — 跑 `generate_release_keystore.ps1` + cp `key.properties.example` + 改 1 行 + 跑 fastlane `android internal` 验
2. **[P0] 注册 `chroniccare.app` 域名 + HTTPS 部署 3 份 md** — 7-20 天 ICP 备案, 走阿里云 / 腾讯云 / Cloudflare
3. **[P0] 注册 `support@` / `privacy@` 邮箱** + 7 工作日响应机制 — Apple 5.1.1 + PIPL §50
4. **[P0] `fastlane/Appfile` 4 ID 替换真实值** + 配 Service Account JSON
5. **[P0] `video.txt` 真实 YouTube URL** — 录 30 秒 demo 视频上传
6. **[P0] Tablet screenshots (7" + 10")** — Android 设备 / 模拟器各截 4 张
7. **[P0] `privacy_url.txt` (Android)** — 跟 zh-CN en-US 都加
8. **[P0] 5 项 Play Console 强制声明 (Government/Health/COVID-19/Encryption/IAP/Ads)** — 上架前必填
9. **[P0] IAP 真接 (8 元买断 productId)** — `com.chroniccare.app.lifetime` 在 Google Play Console + App Store Connect 创建; `StoreKitService.buyLifetime()` release 模式真接
10. **[P0] BootReceiver 改用 FlutterEngineCache + MethodChannel** — `BootReceiver.kt:18-21` TODO 落地, 避免重启手机后强拉 MainActivity
11. **[P0] 律师 review 3 份 md** — `LEGAL_REVIEW_BRIEF.md` 12 项 P0 全部回答 + 签字盖章
12. **[P0] 失联通知业务 vs 隐私政策描述统一** — 二选一: 删隐私政策"会发 SMS" / 启用 FeatureFlags 真接 SMS
13. **[P0] 5 厂商 push SDK 接入 (小/华/OPP/vivo/魅族)** — 1-2 月审核, 这是 P0 长期项
14. **[P0] 第三方 SDK 披露补全 (Data Safety Form)** — `LEGAL_REVIEW_BRIEF §1.8` 列的 `in_app_purchase` / `speech_to_text` / `pdf` / `printing` / `permission_handler` 5 个 SDK
15. **[P0] `in_app_purchase` R8 keep** — proguard-rules.pro 加 `-keep class com.android.billingclient.** { *; }`
16. **[P0] `bootReceiverEnabled` R70 TODO 真接 WorkManager** — `safety_watch_service.dart:99` 注释 "v0.28 WorkManager 完善之前临时关闭"

### P1 — 重要 (过审可加但建议修)

1. **[P1] Android 15 edge-to-edge** — `MainActivity` 调 `WindowCompat.setDecorFitsSystemWindows(window, false)`
2. **[P1] Android 12+ SplashScreen API + monochrome icon** — `mipmap-anydpi-v26/ic_launcher_monochrome.xml` + SplashScreen API 集成
3. **[P1] 通知 action (snooze / done)** + **全屏 Intent safety alert** + **BigTextStyle**
4. **[P1] `RECORD_AUDIO` runtime permission UX 引导** — 录音前弹 rationale
5. **[P1] `POST_NOTIFICATIONS` 延迟申请** — 启动不弹, 首次 medication 提醒时弹
6. **[P1] IARC Content Rating 问卷** + **Category 选 Health & Fitness / Medical**
7. **[P1] `permission_handler` 移除 (装了不用) 或实装**
8. **[P1] `USE_EXACT_ALARM` 移除** — 只用 `SCHEDULE_EXACT_ALARM` (政策合规)
9. **[P1] Data Safety Form 4 大类手动填提交**
10. **[P1] zh-CN metadata 补 `title.txt` / `short_description.txt`**
11. **[P1] TalkBack / 字体缩放 / 48dp 触摸目标** 审查
12. **[P1] WorkManager (后台任务)** 接入
13. **[P1] 跨境 PIPL §38 评估** — v0.28 真接 SMS 前做
14. **[P1] 港澳台危机热线补 (台湾 1925 / 香港 2389 2222)**
15. **[P1] 多语言版本 en 补 GDPR / CCPA 引用**
16. **[P1] 协议变更自动重走同意弹窗** (PIPL §14 敏感场景)
17. **[P1] Tree hole / vent 归类 "敏感个人信息" 法务确认**
18. **[P1] `firebase_messaging` 兜底接入 (海外)**
19. **[P1] Adult 15 工作日删除权承诺**
20. **[P1] 未成年人 14-18 周岁验证 (PIPL §31) 强化**
21. **[P1] `RECORD_AUDIO` rationale 弹窗**

### P2 — 建议

1. **[P2] 显式 `ndkVersion` 声明**
2. **[P2] `data_safety_form.py:32-33` 脚本 bug 修** — `re.search(r'v0\.27\.0\+\d+', text)` 跟实际 md 不匹配
3. **[P2] 0 通知 group / 通知设置 deep link**
4. **[P2] Audio Focus / 蓝牙 route 监听**
5. **[P2] Adult 删除权时效细化**
6. **[P2] Android 14 64-bit 强制** — 已 abiFilters, 验 ✅
7. **[P2] IAP 8 元定价法务确认**
8. **[P2] Battery Historian / 冷启动测量**
9. **[P2] StrictMode enable**
10. **[P2] gradle.properties 加 `enableJetifier=false` / `caching=true` / `parallel=true`**

### P3 — nice-to-have

1. **[P3] Health Connect 接入** (跟产品定位冲突, 长期)
2. **[P3] MediaSession (锁屏控制)**
3. **[P3] `local.properties` `flutter.versionName=0.25.0` 跟 pubspec 同步 (本地配置)**
4. **[P3] IARC / Health Connect 长期**

---

## 半成品 / 残缺项

### 工程层

- [ ] **`build.gradle.kts:80` `signingConfig = signingConfigs.getByName("debug")`** — 上 store 前必切 release
- [ ] `BootReceiver.kt:18-21` 简化方案 — 改用 FlutterEngineCache + MethodChannel
- [ ] `MainActivity.kt` 4 行纯默认 — 需调 `WindowCompat.setDecorFitsSystemWindows(window, false)` (Android 15 edge-to-edge)
- [ ] `proguard-rules.pro` 缺 `com.android.billingclient.**` keep (IAP 真接后)
- [ ] `proguard-rules.pro` 缺 `permission_handler` keep
- [ ] `proguard-rules.pro` 缺 `com.google.android.gms:play-services` keep (firebase_messaging 真接后)
- [ ] `android:networkSecurityConfig` 0 显式 `usesCleartextTraffic="false"` (manifest 53 行只引了 config, 0 显式)
- [ ] `android/app/src/main/res/mipmap-anydpi-v26/` 目录不存在 — 缺 monochrome icon
- [ ] `flutter.versionName=0.25.0` 跟 `pubspec.yaml 0.30.0` 不一致 (local.properties 本地, 不影响 release)

### 业务层

- [ ] **`AliyunSmsProvider.send()` 仍 `throw StateError`** — 失联通知真接 SMS
- [ ] **`StoreKitService.buyLifetime()` release 模式返 `false`** — IAP 真接 productId
- [ ] **`FeatureFlags._prodEmergencyContactEnabled = false`** — 失联通知业务暂停
- [ ] **`FeatureFlags._prodIapEnabled = false`** — IAP 业务暂停
- [ ] **`FeatureFlags._prodPhqGad7I18nEnabled = false`** — 量表题目 i18n 关闭
- [ ] **`BootReceiver` 启动 MainActivity 简单粗暴** — 改 WorkManager

### 法务 / 合规

- [ ] `assets/legal/privacy_policy.md` 标 "草稿 (未经律师过审)"
- [ ] `assets/legal/user_agreement.md` 标 "草稿 (未经律师过审)"
- [ ] `assets/legal/sensitive_data_consent.md` 标 "草稿 (未经律师过审)"
- [ ] `LEGAL_REVIEW_BRIEF.md` 12 项 P0 风险未回答 (其中 §1.1 / 1.3 / 1.4 / 1.6 / 1.7 紧急)
- [ ] `privacy@chroniccare.app` 邮箱未注册
- [ ] `support@chroniccare.app` 邮箱未注册
- [ ] `chroniccare.app` 域名未注册
- [ ] NMPA "非医疗器械" 声明 PDF 未生成 (`DEPLOYMENT.md` 附录 A.1 模板 OK, 但未实装)
- [ ] GDPR / HIPAA / CCPA / 台湾个人资料保护法 / 澳门个人资料保护法 适配 — 0 评估

### 上架材料

- [ ] `fastlane/metadata/android/en-US/video.txt` 是 `PLACEHOLDER_APP_DEMO_VIDEO`
- [ ] `fastlane/metadata/android/zh-CN/` 缺 `title.txt` / `short_description.txt`
- [ ] `fastlane/metadata/android/{en-US, zh-CN}/` 缺 `category.txt` / `tags.txt` / `contact_email.txt` / `privacy_url.txt`
- [ ] `fastlane/metadata/android/{en-US, zh-CN}/` 缺 7" / 10" tablet screenshots
- [ ] Play Console 5 项强制声明 (Government / Health / COVID-19 / Encryption / IAP / Ads) 0 维护
- [ ] Data Safety Form 4 大类手动填提交
- [ ] IARC Content Rating 问卷 0 填
- [ ] Target Audience 0 填

### 国产 ROM

- [ ] **5 厂商 push SDK 0 接入** (MiPush / HuaweiPush / OppoPush / VivoPush / MzPush)
- [ ] **`docs/PUSH_PROVIDERS.md` 1-2 月审核 plan 0 启动**
- [ ] `firebase_messaging` 0 接入 (海外兜底)
- [ ] `pubspec.yaml` 0 厂商 push 依赖

### 已知守门员弱点 (R88 已知 + 未修)

- [ ] **`flutter gen-l10n` 反复误删 3 个 `ventDuration*` 键** — 每次手动 re-insert, R89 计划加 `gen_l10n_diff_check.py` 守门员
- [ ] `check_widget_dispose.py` 已知 27 处 `!mounted` check 跨 async gap — 已知模式不修
- [ ] R88 + R87 + R86 + R85 + R84 + R83 + R82 + R81 + R80 9 round 累积 — 需大版本规整

---

## Android 平台未完成的适配

### 1. Android 15+ 强制项

- [ ] **edge-to-edge (Android 15 强制)** — `MainActivity` 需 `WindowCompat.setDecorFitsSystemWindows(window, false)`, 配合 insets 处理
- [ ] **SplashScreen API (Android 12+ 强烈推荐)** — `androidx.core:core-splashscreen` 集成 + monochrome icon
- [ ] **predictive back (Android 14 强烈推荐)** — `enableOnBackInvokedCallback="true"` ✅ 已有

### 2. Android 14+ 适配项

- [ ] **FOREGROUND_SERVICE_TYPE_* (Android 14+ 必填)** — 当前 0 Foreground Service, 不受影响
- [ ] **partial photo access (`READ_MEDIA_VISUAL_USER_SELECTED`)** — 0 媒体访问, 不受影响

### 3. 通知深度优化

- [ ] **通知 Action (snooze / done)** — 用户点通知直接处理
- [ ] **全屏 Intent safety alert** — 失联通知用 full-screen intent 强提示
- [ ] **BigTextStyle** — 长 body 完整显示
- [ ] **通知 group / 通知设置 deep link** — 多条 medication reminder 分组

### 4. 音频深度优化

- [ ] **Audio Focus** — 跟微信/音乐 App 协调
- [ ] **蓝牙 route change 监听** — 拔耳机录音停止
- [ ] **MediaSession (锁屏控制)** — 树洞播放锁屏控制

### 5. 性能 / 可访问性 / 监控

- [ ] **冷启动 / 温启动 / 热启动测量**
- [ ] **Battery Historian 测量**
- [ ] **TalkBack Semantics 审查**
- [ ] **字体缩放自适应 (`MediaQuery.textScaleFactor`)**
- [ ] **48dp+ 触摸目标常量 (`AppTokens.minTouchTarget`)**
- [ ] **Reduce Motion (`MediaQuery.disableAnimations`)**

### 6. Crash / 监控

- [ ] **Crashlytics / Sentry / Bugsnag 0 接入** — 本地 SQLite 错误通过 `runZonedGuarded` 打印, 无远程监控
- [ ] **Analytics 0 接入** (跟"零云端"定位一致, 不建议加)
- [ ] **Firebase Remote Config 0 接入** (同上)

### 7. 测试覆盖

- [ ] **`android/` Espresso / UI Automator 测试 0 接入** — 仅 Flutter widget test
- [ ] **`BootReceiver` 单元测试 0** — 纯 Kotlin 端
- [ ] **`MainActivity` 集成测试 0** — Android 端到端

---

## 整体结论

### 优势 (做对的事)

- ✅ **4 层架构 + 16 守护脚本** 体系严密, 1617 测试 + 0 analyzer error
- ✅ **隐私边界** 严格: SQLCipher AES-256 + 录音 AES-256 + SecureStorage + allowBackup=false + 国产 ROM 0 数据备份 + cleartext 禁
- ✅ **PIPL §13/§14** 实施完整: 4 勾选 + 单独同意 + 撤回同意业务层真接
- ✅ **失联通知业务** 启动守卫 (`SmsService.validateForRelease` / `EmailService.validateForRelease`) + `LastErrorCapture` 兜底
- ✅ **Target SDK 36** + 16KB 对齐 + 64-bit + R8 + Multidex
- ✅ **`NotificationStatusCard` 国产 ROM 自检卡** + 5 品牌 OEM 引导
- ✅ **fastlane 双端** + Play App Signing 5 步指南 + 16KB 验脚本
- ✅ **3 份法律 md 骨架完整** (草稿状态, 等律师过审)
- ✅ **隐私 / Data Safety 模板** 脚本化生成
- ✅ **Cargo cult level 详情**: `BootReceiver` 简化方案, `bootReceiverEnabled` 临时关, `iapEnabled` 临时关, `emergencyContactEnabled` 临时关, 都在合理范围内有"feature flag + TODO 注释"

### 关键差距 (上架前必补)

- 🔴 **法务** — 3 份 md 律师过审 + 12 项 P0 风险回答
- 🔴 **签名** — `signingConfig` 切 release + Play App Signing 启用
- 🔴 **域名 / 邮箱** — `chroniccare.app` 注册 + `support@` / `privacy@` 邮箱
- 🔴 **上架材料** — tablet screenshots + 5 项强制声明 + zh-CN metadata 补全 + `video.txt` 真实 URL
- 🔴 **IAP** — `StoreKitService.buyLifetime()` release 模式真接 + productId 创建 + 文档统一
- 🔴 **失联通知业务** vs **隐私政策** — 二选一 (删 / 启用)
- 🔴 **5 厂商 push SDK** — 1-2 月审核, 长期 P0
- 🔴 **AliyunSmsProvider 真接** — 1-2 月外部依赖

### 8 月底 / 9 月初上架 (2026-08-15 估)

按 `LEGAL_REVIEW_BRIEF.md` §5 "上 store 前必完成" 5 项 + `DEPLOYMENT.md` 阶段 7.5 "提交前 5 项 P0 阻塞":

1. 律师 review 3 份 md (1-2 周 + ¥45-90k) — 阻塞
2. 真实 keystore + Play App Signing (1 天) — 阻塞
3. `support@chroniccare.app` + 域名 + HTTPS 部署 (7-20 天 ICP) — 阻塞
4. Play Console 4 大表单 (Data Safety + Health + Permissions + Data Deletion) (1 天) — 阻塞
5. Apple App Store Connect 4 ID (1 天) — 阻塞
6. IAP 真接 (1-2 周 + 1 天) — 阻塞
7. 失联通知业务 vs 隐私政策统一 (1 天法务决策) — 阻塞

**总估: 2-3 周 (法务是瓶颈) + 1-2 月 (5 厂商 push + Aliyun SMS 审核)**。**8 月底能上 v0.30.0 基础版 (失联通知业务暂停 + IAP 关闭 + 国产 ROM UX 适配 + 5 厂商 push 推迟到 v0.31)**, **不能上完整 v1.0 (含失联通知真接)**。
