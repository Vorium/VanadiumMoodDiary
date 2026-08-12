# App Store 上架就绪审计 (2026-08-13)

结论: **不可提交**。代码面 R32 11 项 P0 全闭环, 但元数据/资产/URL 硬阻塞未动; 紧急联系人部分可见 + Mock 文案暴露违反 "隐藏策略"。

## item 1: 外部链接隐藏检查表

| 模块 | 状态 | 证据 |
|---|---|---|
| IAP "立即买断" | ✅ 隐藏 | feature_flags iapEnabled=false + profile_group.dart:65 gate + main.dart:163 跳过 warmup |
| 5 厂商 push 自检 | ✅ 隐藏 | fiveVendorPushEnabled=false + notification_status_card.dart:262 |
| 邮件导出 section | ✅ 隐藏 | emailServiceEnabled=false + assessment_section.dart:84 → SizedBox.shrink |
| 设置页联系人 | ✅ 隐藏 | profile_group.dart:183 gate |
| webview/mailto/http/SMS URI | ✅ 干净 | 仅 tel: 危机热线 (crisis_hotline_page.dart:242-246, 苹果认可); ARB 0 external URL |
| **setup 联系人表单** | ❌ **可见** | setup_step_welcome.dart:130-183 无任何 flag |
| **reminders_hub 安全卡** | ❌ **可见** | reminders_hub_page.dart:135-136,197 + reminder_cards.dart:84-110 红色 Mock 横幅 (app_zh.arb:337) |
| privacy/support URL | ⚠️ 占位 | 10 个文件全部 chroniccare.app (域名未注册); domain 需 ICP 7-20d |

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| AS-01 | 元数据 | review_information 4 文件仍占位符 `[REPLACE_BEFORE_APPLE_REVIEW:...]` | fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt | ≤5min 填真实值 | **P0** |
| AS-02 | 元数据 | notes.txt 版本过时 (0.31.0+107) + 虚假声明 "7 backend 功能不在 UI" (实际可见) | notes.txt:1,8 | ≤5min | **P0** |
| AS-03 | 外部 | privacy/support URL 全指向未注册 chroniccare.app; Apple 5.1.1(v) 要求可访问 | 10 个 url 文件 + assets/legal/*.md:150 | 7-20d (ICP) | **P0** |
| AS-04 | 资产 | **iOS 截图 0 张** (无 iphone_*/ipad_* 目录, Fastfile skip_screenshots=false → 提交即失败) | fastlane/metadata/ios/en-US/ | 设计师 | **P0** |
| AS-05 | 资产 | LaunchImage 3× 68B 1×1px 占位 (storyboard 本身已修 2414B) | ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png | 设计师 | **P0** |
| AS-06 | 资产 | AppIcon 1024² 仅 10.9KB (近空白, 2.3.7 拒审风险) | AppIcon.appiconset/Icon-App-1024x1024@1x.png | 设计师 | **P0** |
| AS-07 | 合规 | **紧急联系人部分可见**: setup 表单 + 安全卡, 违反 notes.txt 声明 | 见上 | ≤2h | **P0** |
| AS-08 | 合规 | **用户可见 "当前使用 Mock"/"开发模式, 未实际通知" 文案** | app_zh.arb:337,978 | ≤1h | **P0** |
| AS-09 | 合规 | description 5.1.3 措辞 "Built-in psychological screening" (病名已清, 但 screening 仍招审查) | en-US/description.txt | 10min | P1 |
| AS-10 | iap | SOP 文档 productId 过时 (代码已修 com.chroniccare.chroniccare.lifetime) | STOREFRONT_RELEASE_SOP.md:76 vs store_kit_service.dart:50 | 5min | P1 |
| AS-11 | 元数据 | pubspec 0.32.0+119 vs commit 0.32.0+129 漂移 | pubspec.yaml | 5min | P1 |
| AS-12 | 资产 | Android 占位 (Play 侧): 8×67B 截图 + feature_graphic 空白 + icon 192×192 | fastlane/metadata/android/ | 设计师 | P1 |
| AS-13 | 合规 | setup 联系人路径缺 PIPL §13 同意弹窗 (仅被动文案; ConsentDialog 只在隐藏的设置路径) | setup_step_welcome.dart:171-183 | ≤2h | P1 |
| AS-14 | 合规 | **release 启动 validateForRelease 抛错 → "上次启动出错"横幅 (审阅者第一印象灾难)** | sms_service.dart:51-60 / email_service.dart / app.dart:293-298 | ≤1h | **P0** |

## 已验证闭环 (R32/R109, master 上)

锁屏 PII: 5 处 Darwin cateoryIdentifier + timeSensitive / Android visibility secret ×3 / safetyAlert static title 全 ARB / check_pii_in_title 覆盖 · 病名 4 locale 清除 · review_information TODO→占位符 · productId · 8 IconButton · PrivacyInfo.xcprivacy 完整 (AccessedAPI 4 类 + CollectedDataTypes 3 类, HealthAndFitness 正确移除) · entitlements 空 (无 push/HealthKit, 一致) · ITSAppUsesNonExemptEncryption=false · usage strings + zh-Hans/zh-Hant InfoPlist.strings 齐全 · 同意审计轨迹 UTC 归一

## 总结

1) R32 11 项代码 P0 全闭环, 代码卫生已达提交水准; 2) item-1: IAP/邮件/push/联系人设置全隐藏, 但 setup 表单 + 安全卡 + Mock 文案 3 处违反; 3) 无 webview/mailto/https/SMS 面, 仅 tel: 危机热线; 4) 硬阻塞: review 4 占位 / notes.txt / 0 截图 / 68B LaunchImage / 10.9KB Icon / screening 措辞 — 代码项 ~2-3 人日, 外部 (域名/设计师) 是闸门; 5) 结论: 提交前必须过 AS-01/02/07/08/09/14 + 外部资产。