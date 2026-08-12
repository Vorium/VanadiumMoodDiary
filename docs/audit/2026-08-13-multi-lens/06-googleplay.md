# Google Play Console 上架就绪审计 (2026-08-13)

结论: **不可提交**。7 项 launch-blocker (5 资产/元数据 + keystore + privacy URL), 技术/权限姿态强 (最小权限 / 无 SMS 权限 / targetSdk 36 / 64-bit / exact-alarm 处理 / 锁屏 PII 闭环)。

## item 1: 外部链接隐藏检查表 (Play 侧) — E1-E4 全隐藏, E5 占位

| # | 项 | 状态 | 证据 |
|---|---|---|---|
| E1 | Play Billing UI | ✅ 隐藏 | iapEnabled=false + profile_group gate + store_kit buyLifetime 早返 false; in_app_purchase 编译进 APK 但 0 购买面, policy-compliant |
| E2 | push 渠道 UI | ✅ 隐藏 | fiveVendorPushEnabled=false → SizedBox.shrink; pubspec 0 厂商 SDK |
| E3 | 邮件/changelog 链接 | ✅ 隐藏 | emailServiceEnabled=false; lib/presentation 0 mailto/changelog match; 唯一出站动作 = tel: 危机热线 |
| E4 | 紧急联系人/SMS UI | ✅ 隐藏 | emergencyContactEnabled=false 双 gate + safety_watch 早返 + aliyunSms 早返 (⚠️ 但 setup 表单 + reminders_hub 安全卡 AppStore 侧可见 — 见 AS-07) |
| E5 | **privacy URL** | ❌ **占位** | privacy_url/support_url = chroniccare.app 未注册 → **Play 硬拒** (数据安全表单 + URL 必填) |

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| GP-1 | 资产 | 8 张 phone_screenshots 全 67B 占位 (en-US ×4 + zh-CN ×4, 尺寸 1232×720 合法) | fastlane/metadata/android/*/phone_screenshots/ | 设计师 1-2d | **P0** |
| GP-2 | 资产 | feature_graphic 67B 空白 (1024×500) | 两 locale | 设计师 4h | **P0** |
| GP-3 | 资产 | icon.png 1443B Flutter 默认 logo + mipmap 全套默认; Play 要求 512×512 32-bit 源 | fastlane icon + res/mipmap-* | 设计师 4h | **P0** |
| GP-4 | 资产 | 0 tablet 截图 (7" + 10"), 且无 <supports-screens> 声明 | fastlane/metadata/android/ | 设计师 | **P0** |
| GP-5 | 元数据 | en-US short_description **86 字符 > 80 上限** | short_description.txt | 5min | **P0** |
| GP-6 | 元数据 | full_description "screening" 措辞 + 已禁用功能宣传 ("stay connected with loved ones" caregiver 文案) — 误导 listing 风险 | full_description.txt:16-17,1,28 | 10min | P1 |
| GP-7 | 技术 | **keystore 未生成** → release AAB 构建失败 (key.properties 不存在, 仅 example; fastlane android internal 不带 -PdebugSigning) | android/key.properties / build.gradle.kts:61-74,91-95 | 1h | **P0** |
| GP-8 | 技术 | android:label="ChronicCare" 硬编码 (不引用 @string/app_name) + 0 <supports-screens> | AndroidManifest.xml:51 | 2min×2 | P1 |
| GP-9 | 权限 | ✅ 6 权限最小集且 Play-safe: INTERNET/POST_NOTIFICATIONS/SCHEDULE_EXACT_ALARM/WAKE_LOCK/VIBRATE/RECORD_AUDIO; 无 SEND/RECEIVE_SMS (Aliyun HTTP API 且禁用); exported=true 仅 launcher | AndroidManifest.xml:40-48 | — | ✅ |
| GP-10 | 权限 | POST_NOTIFICATIONS 运行时上下文化 (setup + 设置页, 非冷启动); exact alarm canScheduleExact 优雅降级; ⚠️ 无 UI 重新授权入口 (Android 14+ 默认拒 → 静默 ~15min 漂移) | notification_initializer.dart:122-173 | — | P2(建议) |
| GP-11 | 表单 | Data Safety 3 表单未填 (console 侧): health 数据申报 + exact-alarm 声明 + 权限声明 | scripts/generate_data_safety_form.py 存在未用 | 2h console | P1 |
| GP-12 | 技术 | 16KB: 配置侧 OK (sqlcipher_flutter_libs 0.6.8 ≥0.6.5 / targetSdk 36 / ndk 27), **但 check_16kb_alignment.py 是配置级检查, 无真实 objdump 验证, 0 CI 运行** | scripts/check_16kb_alignment.py:111-118 | 4h | P1 |
| GP-13 | 技术 | ✅ targetSdk 36 (2025-08+ 强制线) / versionCode=119=pubspec 一致 (commit 声称 +129 未落 → 上传前必须升) / multiDex + desugar / 64-bit only / R8 | build.gradle.kts | — | ✅ |
| GP-14 | 权限 | 锁屏 PII: 4 处 secret 已闭环, **badge_sync_service 第 5 处无 visibility** (低风险: min importance + 空 title, 但声明过时) | badge_sync_service.dart:59-67 | 2min | P1 |
| GP-15 | 权限 | ✅ 药名锁屏泄漏源头已修 (title 静态 '💊 该吃药了' / body 无剂量无药名 / check_pii_in_title 覆盖 safetyAlertTitle) | strings.dart:112-117 | — | ✅ |
| GP-16 | iap | Play Billing 休眠 (无购买 UI = 无 policy 面); 打开时需注册 product + PurchaseUpdated listener | — | — | P2 |
| GP-17 | 技术 | 启动屏旧式 Theme.Light.NoTitleBar + 硬编码 #6BCF7F (非拒审项, v31 风格对齐时改) | values/styles.xml:4 / launch_background.xml:4 | 1d | P3 |
| GP-18 | 技术 | 死 BootReceiver.kt 未注册 (manifest 注释已说明); changelogs/versionCode.txt 缺失 (Play "what's new" 每版本必填) | android/.../BootReceiver.kt / fastlane/metadata/android/*/changelogs/ | 0.5h+15min | P3 |

## 已修复 (vs R32 lens, HEAD 实测)

visibility secret 4 主站点 · 锁屏 PII 源头移除 · values-en app_name (✅) · 5 病名移除 · check_pii_in_title 扩 safetyAlertTitle

## 总结

1) item-1: E1-E4 全隐藏, E5 privacy URL 是 Play 侧唯一外部残留 (硬阻塞); 2) 阻塞: GP-1~5 资产/元数据 + GP-7 keystore + E5 URL + GP-11 表单; 3) 技术/权限姿态强 (最小权限无 SMS / targetSdk 36 / 锁屏闭环); 4) 短工项: GP-8 label/supports-screens (2min), GP-14 badge visibility (2min), GP-5 short_description (5min); 5) 外部依赖: 资产 3-4d 设计师 + keystore 1h + 域名 7-20d。