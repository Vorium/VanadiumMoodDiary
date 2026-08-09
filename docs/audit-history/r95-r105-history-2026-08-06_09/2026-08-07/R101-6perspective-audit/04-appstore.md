# AppStore 审计报告 — R101

**审计时间**: 2026-08-07 | **拒审风险**: 高

---

## REJECT — 必定拒审 (5 项)

| # | 问题 | Guideline | 文件 |
|---|------|-----------|------|
| 1 | 隐私政策 URL 404 (chroniccare.app/privacy) | 5.1.1 | fastlane/metadata/ios/*/privacy_url.txt |
| 2 | Support URL 404 (chroniccare.app/support) | 5.1.1 | fastlane/metadata/ios/*/support_url.txt |
| 3 | 用户协议提及付费但 IAP 未完成 | 3.1.1 | user_agreement.md:22 + store_kit_service.dart:117 |
| 4 | iOS 截图缺失 (0 张) | 2.3.3 | fastlane/metadata/ios/ 无 screenshots/ |
| 5 | Podfile.lock 缺失 | 2.1 | ios/ 无 Podfile.lock |

## REJECT-LIKELY — 高概率拒审 (5 项)

| # | 问题 | Guideline |
|---|------|-----------|
| 6 | Dynamic Type 完全不支持 (所有字号硬编码 const) | 2.5.1 |
| 7 | 医疗免责声明不够显著 (仅设置页底部) | 1.4.1 |
| 8 | 描述宣传 "coming soon" 功能 | 2.3.3 |
| 9 | PHQ-9/GAD-7 i18n 未完成但描述宣传 | 2.3.7 |
| 10 | 开发者联系方式缺失 | 5.1.1 |

## WARNING (8 项)

| # | 问题 |
|---|------|
| 11 | ITSAppUsesNonExemptEncryption=false 但用 SQLCipher (声明正确但需准备说明) |
| 12 | 无 APNs 但有通知 delegate (本地通知正常) |
| 13 | NSUserTrackingUsageDescription 声明但无 ATT 弹窗 |
| 14 | 年龄分级需声明 Health/Medical Info |
| 15 | App 名称 "慢病管家" 可能触发医疗审查 |
| 16 | screenshots 目录结构缺失 |
| 17 | zh-Hant InfoPlist.strings 需确认完整 |
| 18 | chroniccare.app 域名可能未注册 |

## INFO (8 项)

19-26: IAP 依赖未使用 / SafeArea 良好 ✅ / Dark Mode 完整 ✅ / iPad 支持 ✅ / iOS 最低版本 Podfile 13.0 vs pbxproj 14.0 不一致 / 隐私政策 URL 格式 / record+audioplayers 已知坑 / crisis hotline URL
