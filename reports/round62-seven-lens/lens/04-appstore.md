# Lens 4 — App Store 上架规范审查 (R62)

> 视角: Apple App Store Review Guidelines + Technical Requirements
> 范围: iOS / iPadOS 提交前的合规和技术准备
> 项目版本: v0.25.0+1 (R61 完成平台代码生成)

---

## ✅ 现状合规项 (R61 已落地)

| 项 | 文件 | 状态 |
|---|---|---|
| **Info.plist NSUsageDescription × 4** | `ios/Runner/Info.plist:33-44` | 通知 / 麦克风 / 语音识别 / 用户追踪 4 类全配 |
| **PrivacyInfo.xcprivacy 4 大类** | `ios/Runner/PrivacyInfo.xcprivacy:30-64` | UserDefaults(CA92.1) / FileTimestamp(C617.1) / SystemBootTime(35F9.1) / DiskSpace(85F4.1) 全覆盖,2024-05 强制要求达标 |
| **iPad 多任务** | `Info.plist:50-51` | `UIRequiresFullScreen=false` + `UISupportedInterfaceOrientations~ipad` 全 4 方向 |
| **Scene-based lifecycle** | `SceneDelegate.swift` | iOS 13+ Scene 配置正确,无 Main.storyboard 残留 |
| **AppIcon 1024×1024** | `Assets.xcassets/AppIcon.appiconset/Contents.json:111-115` | `ios-marketing` 字段已声明 |
| **UIBackgroundModes** | `Info.plist:98-102` | `audio` (录音) + `fetch` (失联检测周期) |
| **SQLCipher 本地加密** | `lib/core/data/database/connection/native.dart:18-28` | `PRAGMA key` 注入,文档目录受 iOS Data Protection |
| **PIPL 单独同意** | `assets/legal/sensitive_data_consent.md` + `setup_step_consent` | `check_legal_consent.py` 守门全过 |
| **医疗免责声明** | `assets/legal/user_agreement.md:20-22,41` | 已有"不提供医疗建议/诊断/治疗" + 失联非紧急救援 + 心理评估仅参考 + 危机电话 |
| **无 IDFA / 无追踪** | `NSPrivacyTracking=false` | 全本地,无第三方追踪 SDK |
| **无 IAP / StoreKit** | `pubspec.yaml` | 纯免费,无 in_app_purchase / store_kit 依赖 |
| **无账号系统** | 项目架构 | Account Deletion (5.1.1(v) 2024-02 强制) 不适用 |
| **全局错误兜底** | `lib/main.dart:44-71` | `runZonedGuarded` + `LastErrorCapture` 满足 ITMS-90000 基础 |

---

## 🚨 P0 — 上架阻塞

### P0-1 缺 `LSApplicationCategoryType` (App Store 类别)
`Info.plist` **未设** `LSApplicationCategoryType`。建议加 `<string>healthcare-fitness</string>`。
- 理由: 精神心理 + 用药 = 命中 Apple **Health or Medical Topics** 类别审核
- App Store Connect 提交时勾选"Medical / Health"分类,需对应 Info.plist 字段呼应
- 缺失会导致审核员 review 时找不到分类对应 → 可能被归为"信息缺失"拒

### P0-2 `LaunchScreen.storyboard` 用 168×185 LaunchImage (不合规)
`Base.lproj/LaunchScreen.storyboard:19,35` 引用 `LaunchImage` (168×185 PNG,LaunchImage.imageset 是默认 flutter create 资源)。
- iPhone 6.5" 设备 (1242×2688) 启动时**严重模糊**
- Apple HIG 明确: Launch Screen 不能用低分辨率 PNG 当唯一资源
- **修法 2 选 1**:
  1. 删 LaunchImage,改成空 `UIView` + 品牌色 background (R61 注释说"不能是白屏",但其实可以纯色,Flutter root view 也是白)
  2. 加 3 个尺寸 LaunchImage (iPhone 5.5" / 6.5" / iPad)
- 当前所有设备跑同一个 168×185 → **设备多样性测试必 fail** (ITMS-90000 device compatibility)

### P0-3 Privacy Policy URL 未部署到公网
`assets/legal/privacy_policy.md` 是**本地 asset**,App Store Connect 提交时**必须填公开可访问的 https URL** (1.4.1 + 5.1.1 强制)。
- 缺 URL → 提交表单校验直接卡住,**不能进 review**
- 修法: 部署到 `https://chroniccare.com/privacy` 或 `github.io` / 备案过的企业域名
- 注意: App 内 `legal_page.dart` 走的是本地 Markdown,跟 App Store Connect 表单的 URL 是 2 个独立字段,都不能少

### P0-4 急救按钮 iOS 端真能拨打电话未验证
AGENTS.md 提"急救按钮已实现 ✓",但 `tel:120` / `tel:110` URL 在 iOS 走 `url_launcher` 需 iOS 10+ `LSApplicationQueriesSchemes` 或直接 `UIApplication.shared.open(url)`。
- 验证项: iOS Simulator 实测点击急救按钮是否真跳到系统电话 app
- 精神医疗 App 急救按钮失灵 = **App Store 1.4.1 Physical Harm 直接拒**
- 须在 setup 流程 + home 主页确保按钮 100% 可用

---

## ⚠️ P1 — 审核常见拒因 / 高优先级补强

### P1-1 `NSUserTrackingUsageDescription` 多余 (防御性反成问题)
`Info.plist:43-44` 加了 `<string>本应用不收集任何追踪数据...</string>`,但**项目无 IDFA 引用,无 tracking 调用**。
- Apple 看到这字段会要求补充 App Tracking Transparency (ATT) 框架调用
- 写"不收集"内容 ≠ 关闭追踪;**正确做法是直接删除整个 key**
- R61 注释说"防御性",反而是**触发额外审核质询**

### P1-2 iOS 13 部署目标过低
`IPHONEOS_DEPLOYMENT_TARGET = 13.0` (project.pbxproj 多处)。
- Apple 当前最低要求 = **iOS 12.0** (2023-04 起),13.0 仍合规
- 但 Flutter 3.41 模板默认就是 13.0,**无强制升级压力**
- 建议: 跟 Flutter 升级节奏走,等下个 LTS 跳到 14.0+ 即可,当前不动

### P1-3 UIBackgroundModes `audio` 需提供 reason 说明
`Info.plist:100` 声明 `audio` 后台模式。Apple 2018+ 加严了 audio 模式审核,常因"未提供音频后台合理用途"被拒。
- 项目用途 = 录音中切到后台不中断 (R61 注释 92-97 行)
- 需在 Capabilities / App Store Connect review notes 中**显式说明此用途**
- 否则 review 时被要求"提供 audio background 详细解释"

### P1-4 缺 Flutter 插件自身 xcprivacy 校验
`PrivacyInfo.xcprivacy` 只列了项目代码用的 4 类 API,但 iOS 18+ (2024 起) 要求 **第三方 SDK 也需有 xcprivacy**。
- `flutter_local_notifications` / `path_provider` / `shared_preferences` / `speech_to_text` / `record` / `audioplayers` / `flutter_secure_storage` / `share_plus` 8 个插件
- 验证方法: `pod install` 后检查 `Pods/` 下每个 plugin 的 xcprivacy
- 缺失 → Apple 2024-05 后拒 (本项目 R61 没做这步,需补)

### P1-5 Dynamic Type (iOS 字号缩放) 支持未验证
iPhone 设置 → 辅助功能 → 显示与文字大小 → 更大字号 拉到最大。
- Flutter `MaterialApp` 默认不完整支持 iOS Dynamic Type,只跟 `MediaQuery.textScaleFactor`
- 代码用了 `AppTokens.fontSizeBody` 等硬编码,系统字号缩放时可能比例失调
- 需在 `MediaQuery` wrapper 或 `TextScaler` 上做 iOS 适配
- Apple HIG 4.0 强建议,2024 后 review 越来越严

### P1-6 隐私政策本地 Markdown 无英文版
`assets/legal/privacy_policy.md` 只有中文,en 用户进 `legal_page.dart` 看到的也是中文。
- 跟 R24 i18n 体系不齐: en 模式下应有 en 隐私政策
- PIPL 强制中文 (国内),GDPR 强制当地语言 (欧洲用户),需双语版
- 修法: 走 `flutter_localizations` + ARB 抽隐私政策主体

### P1-7 `SmsService` release 模式 fail-fast 验证
`main.dart:140` 调 `SmsService.validateForRelease()` 在 release + mock 时抛错 → LastErrorCapture → AppRoot banner。
- 这是技术正确,但**App Store review 团队不会配置真 SMS** = 模拟器跑 release 模式必崩
- 修法: 加 dev / preview 配置让审核员能跑通"失联通知"演示而不真接 SMS
- 或在 review notes 显式说明"该功能需用户自配 SMS,审核测试可走 mock 通道"

### P1-8 SceneDelegate 空实现未测试
`SceneDelegate.swift` 只继承 `FlutterSceneDelegate`,无任何 custom logic。
- iOS 13+ Scene-based lifecycle 跟旧 AppDelegate-only 有差异
- 验证: iPad Split View 切前后台、Stage Manager resize、Multitasking 切换是否正常
- R61 加了但未提供验证截图

---

## 📋 P2 — 加分项 / 长期维护

### P2-1 CFBundleDisplayName "慢病管家" 苹果可读
- Apple 不会拒中文名,✅ 通过

### P2-2 App Store Connect 审核材料清单 (上架前必准备)
- [ ] 截图: iPhone 6.5" / 6.7" / 5.5" / 4.7" / 12.9" iPad 各 ≥ 1 张
- [ ] 描述: 中文 + 英文
- [ ] 关键词: 100 字符内
- [ ] 支持 URL: 公司主页或 contact 页
- [ ] 隐私政策 URL: 见 P0-3
- [ ] 类别: Health & Fitness → Medical
- [ ] 年龄分级: 17+ (医疗 + 心理健康内容)
- [ ] 版权 / 联系信息

### P2-3 Health & Health Research 声明 (5.1.1(iv))
- 精神心理 + 用药追踪 = **被归为 Health 类别**
- App Store Connect 提交流程会问"是否收集 Health 数据"
- 即使全本地 SQLCipher,仍需勾选"收集"并描述 (本项目收集: 药名 / 剂量 / PHQ-9 / GAD-7)
- 缺此声明 = 1.4.1 Medical Apps 审核绕过

### P2-4 iOS 17.5+ Privacy Manifest 跟踪
- R61 注释只覆盖项目代码,2024 后 Apple 要求 SDK 自身也声明
- 跟 P1-4 关联,长期维护

### P2-5 Sign in with Apple 评估
- 项目无账号系统,暂不需
- 若未来加云同步,必须接 Sign in with Apple (4.0 + 5.1.1)

---

## 📊 严重度矩阵

| 类别 | 数量 | 必须修才能上架 |
|---|---|---|
| P0 阻塞 | 4 项 | ✅ 必须修 (P0-1/2/3 + 验证 P0-4) |
| P1 审核高风险 | 8 项 | ⚠️ 强烈建议 (P1-1/3/4/5/7 几乎必查) |
| P2 长期 | 5 项 | 📅 持续维护 |

---

## 🔑 关键决策建议

1. **P0-1/2/3 是上架前的硬卡点**,预计 1-2 个工作日修完
2. **P1-1 (`NSUserTrackingUsageDescription`) 立刻删**,10 分钟搞定,反而省 review 时间
3. **P0-3 隐私政策 URL** = 部署到 `github.io/chroniccare/privacy` 最快,公司备案域名更佳
4. **P1-4 插件 xcprivacy 校验** = 写 1 个 `check_pod_privacy.sh` 脚本,跑一遍 `pod install` 后检查
5. **医疗 App 类别 (P0-1 + P2-3)** = Apple 必查"是否提供医疗建议"字段,准备"本 App 仅辅助服药提醒,不替代医师"声明语

## 📎 上架时间线估算

- P0 全修 + P1-1/3/4: **2-3 工作日**
- 真机测试 (iPhone 6.5" + 12.9" iPad + iPad Split View + Dynamic Type 最大): **1 工作日**
- App Store Connect 材料准备 (截图 5 套 + 双语描述 + 隐私 URL): **1-2 工作日**
- 苹果 review 周期: **24-48 小时** (首次提交通常 24h 内,复杂类别可能 48h+)
- **总计: 提交到过审约 1 周**

---

*报告生成于 R62 七视角审查 · lens 4 / 7 · 2026-07-31*
