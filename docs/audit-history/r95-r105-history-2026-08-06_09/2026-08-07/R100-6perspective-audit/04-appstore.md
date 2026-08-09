# R100 App Store 视角报告（iOS 上架准备）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动
**方法**: Info.plist / InfoPlist.strings / AppDelegate.swift / fastlane ios metadata 逐项实测

## 一、已达标

| 项 | 证据 |
|---|---|
| 5 项 usage description 齐全 | `Info.plist:42-68`（麦克风 / 语音识别 / 相册 ×2 / 追踪） |
| `ITSAppUsesNonExemptEncryption=false` | 标准库加密豁免，避免每年加密申报 |
| LSApplicationCategoryType = healthcare-fitness + Scene manifest | Info.plist:137 |
| BGTaskScheduler 标识符 Info.plist ↔ AppDelegate 一致 | `com.chroniccare.safety-check`（AppDelegate.swift:33） |
| 3 语 metadata（en-US / zh-Hans / zh-Hant）文案齐全且质量合格 | fastlane/metadata/ios/ |
| per-locale 显示名 | Base=ChronicCare / zh-Hans=慢病管家 |

## 二、问题清单（按拒审风险排序）

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| A-1 | **screenshots/ 目录完全缺失**（Apple 6.5"/5.5" 截图必传）—— 当前根本无法提审 | `fastlane/metadata/ios/*/` | 底层 | 中（需真机截图） | **高（P0）** |
| A-2 | **privacy_url / support_url 指向未注册域名** `chroniccare.app`（3 语 × 2 文件共 6 处）。App Review 会实际访问这两个 URL，404 = 拒 | `fastlane/metadata/ios/*/privacy_url.txt, support_url.txt` | 底层 | 中（注册域名 + 静态页） | **高（P0）** |
| A-3 | **UIBackgroundModes=[audio, processing] 但无真实使用**：ventAudio flag 关闭（audio 无场景）+ BGTask handler 是占位实现。Apple 2.5.4（声明的后台能力未实际使用）拒审风险 | Info.plist:144-148；AppDelegate.swift:33-37 | 底层 | 简单（删声明，业务启用时再加回） | **高（P1）** |
| A-4 | **5 项 usage description 仅中文**（Info.plist 内嵌中文），en locale 用户权限弹窗显示中文；InfoPlist.strings 只覆盖 CFBundleDisplayName，未覆盖 NS*UsageDescription | Info.plist:42-68；3 个 InfoPlist.strings | 底层 | 简单（Base 英文 + zh lproj 覆盖） | 中（P1） |
| A-5 | **价格描述不一致**：user_agreement.md 写"售价人民币 8 元一次性买断"，实际 iapEnabled=false 免费。虽已加注脚（R68/R93 决策），审核员仍可能按 Apple 2.1/3.1.1 追问 | `assets/legal/user_agreement.md:22-26` | 底层 | 简单（删或改"未来版本"表述） | 中（P1） |
| A-6 | subtitle/title 含 "(失联通知规划中)"（zh-Hans/zh-Hant），承诺未上线功能，审核员会追问 | `fastlane/metadata/ios/zh-Hans/subtitle.txt` | 底层 | 简单 | 中（P1） |
| A-7 | `INTERNET` 权限 + "零云端"宣传并存（in_app_purchase 隐式依赖），App Privacy 表单需如实填"无数据收集"并备好解释 | AndroidManifest/iOS 通用 | 底层 | 简单（表单填写） | 中 |

## 三、结论

代码侧 iOS 合规度高（无 IDFA、无第三方追踪、加密豁免声明正确）。**阻塞项是 A-1（截图）+ A-2（域名）**，二者不解决无法提审；A-3 是最高概率的实质拒审点，建议提审前删除后台模式声明。
