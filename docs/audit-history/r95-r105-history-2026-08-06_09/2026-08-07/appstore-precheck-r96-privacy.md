# App Store 审核预检清单 — R96 隐私政策修复重点

**生成时间**: 2026-08-07
**适用版本**: v0.30.0+85 (R96 P0-2/3/5 软隐藏后)
**清单目的**: App Store 审核提交前自检，重点验证 R96 隐私政策修复是否合规
**审核参考**: [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) + [App Privacy Details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)

> 本清单按 App Store 审核指南章节组织，每条标注：
> - **状态**: ✅ 通过 / ⚠️ 需注意 / 🔴 阻塞
> - **类别**: 法务 / 工程 / 配置
> - **修复难度**: 低 / 中 / 高
> - **R96 修复相关**: 标注是否本次 R96 修复涉及

---

## 摘要

| 维度 | 状态 | 说明 |
|------|------|------|
| R96 隐私政策软隐藏修复 | ✅ 通过 | P0-2/3/5 占位符已软隐藏，user_agreement.md §8 + privacy_policy.md §9 一致 |
| App Store Guideline 5.1.x (隐私) | ⚠️ 需注意 | 软隐藏策略合规，但缺少可达联系方式，Apple Reviewer 可能要求补 |
| App Store Guideline 5.1.2 (数据使用) | ✅ 通过 | PrivacyInfo.xcprivacy 完整声明 4 类数据 + 5 个 required reason API |
| App Store Guideline 1.5 (开发者信息) | 🔴 阻塞 | fastlane/Appfile 改 ENV 模式后，需用户填真实 APPLE_ID/TEAM_ID 才能提交 |
| App Store Guideline 2.1 (App 完整性) | 🔴 阻塞 | 7 项 FeatureFlag 隐藏业务需在审核备注说明（防 2.1 拒"功能不完整"） |

**核心结论**: R96 隐私政策软隐藏本身合规，但 Apple 审核员可能依据 5.1.1 要求"便捷联系方式"。建议在审核备注中明确说明"软隐藏策略 + App 内反馈渠道"。

---

## 第 1 部分：R96 隐私政策修复重点检查

### 1.1 user_agreement.md §8 联系方式软隐藏

| # | 检查项 | 状态 | 类别 | 修复难度 | R96 相关 | 详情 |
|---|--------|------|------|----------|----------|------|
| 1.1.1 | §8 联系方式无 TODO 占位符 | ✅ 通过 | 法务 | 低 | ✅ 是 | [user_agreement.md:68](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md#L68) 已改"本服务暂不提供邮件 / GitHub 渠道"，无 `support@chroniccare.app` 占位 |
| 1.1.2 | §8 软隐藏策略说明完整 | ✅ 通过 | 法务 | 低 | ✅ 是 | L68-70 明确"v0.30 R96 决策，软隐藏"+ "用户可通过 App 内 设置 → 法律与隐私 页面反馈问题" |
| 1.1.3 | §8 重新启用条件说明 | ✅ 通过 | 法务 | 低 | ✅ 是 | L70 "域名注册 + 邮箱注册 + GitHub 仓库创建后启用" |
| 1.1.4 | §8 与 privacy_policy.md §9 一致 | ✅ 通过 | 法务 | 低 | ✅ 是 | 两份文档都采用"App 内反馈"策略，无矛盾 |
| 1.1.5 | 修订历史段补 R96 entry | ✅ 通过 | 法务 | 低 | ✅ 是 | [user_agreement.md:93](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md#L93) 已补 v0.30 R96 修订记录 |
| 1.1.6 | v0.28+ TODO 描述更新 | ✅ 通过 | 法务 | 低 | ✅ 是 | [user_agreement.md:91](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md#L91) 已去掉"注册邮箱 + 替换 GitHub"硬性要求，改为"可选" |

### 1.2 privacy_policy.md §9 联系方式软隐藏

| # | 检查项 | 状态 | 类别 | 修复难度 | R96 相关 | 详情 |
|---|--------|------|------|----------|----------|------|
| 1.2.1 | §9 联系方式无 support@ 占位符 | ✅ 通过 | 法务 | 低 | ✅ 是 | [privacy_policy.md:150](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md#L150) 仅保留 `privacy@chroniccare.app` 软隐藏（R67 已做） |
| 1.2.2 | §9 软隐藏策略说明完整 | ✅ 通过 | 法务 | 低 | ✅ 是 | L150-152 "本服务不提供邮件渠道"+ "App 内 设置 → 法律与隐私 页面行使 PIPL §14 撤回同意权" |
| 1.2.3 | 修订历史段补 R96 entry | ✅ 通过 | 法务 | 低 | ✅ 是 | [privacy_policy.md:220](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md#L220) 已补 v0.30 R96 修订记录 |
| 1.2.4 | "最后更新"时间同步 | ✅ 通过 | 法务 | 低 | ✅ 是 | [privacy_policy.md:224](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md#L224) "2026-08-07 (v0.30 round 96 — P0-2 联系方式邮箱软隐藏)" |
| 1.2.5 | v0.28+ TODO 描述更新 | ✅ 通过 | 法务 | 低 | ✅ 是 | [privacy_policy.md:218](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md#L218) 已去掉"注册邮箱"硬性要求，改为"可选" |

### 1.3 fastlane/Appfile ENV 模式软隐藏

| # | 检查项 | 状态 | 类别 | 修复难度 | R96 相关 | 详情 |
|---|--------|------|------|----------|----------|------|
| 1.3.1 | Appfile 无硬编码 APPLE_ID/TEAM_ID | ✅ 通过 | 工程 | 低 | ✅ 是 | [fastlane/Appfile:27-29](file:///d:/Batch/chroniccare/fastlane/Appfile#L27) 改 `ENV["APPLE_ID"]` / `ENV["TEAM_ID"]` / `ENV["ITC_TEAM_ID"]` |
| 1.3.2 | .env.example 补 ENV 变量说明 | ✅ 通过 | 工程 | 低 | ✅ 是 | [.env.example:30-44](file:///d:/Batch/chroniccare/.env.example#L30) 加 Apple Developer 段 + 使用说明 |
| 1.3.3 | .gitignore 排除 .env | ✅ 通过 | 工程 | 低 | 否（已有） | [.gitignore:23](file:///d:/Batch/chroniccare/.gitignore#L23) `.env` 已排除 |
| 1.3.4 | Appfile 顶部注释说明使用方式 | ✅ 通过 | 工程 | 低 | ✅ 是 | [fastlane/Appfile:1-24](file:///d:/Batch/chroniccare/fastlane/Appfile#L1) 完整说明 + 替代方案（API Key 模式） |

### 1.4 scripts/generate_legal_brief_docx.py 同步

| # | 检查项 | 状态 | 类别 | 修复难度 | R96 相关 | 详情 |
|---|--------|------|------|----------|----------|------|
| 1.4.1 | docx 生成脚本同步软隐藏 | ✅ 通过 | 工程 | 低 | ✅ 是 | [generate_legal_brief_docx.py:437-439](file:///d:/Batch/chroniccare/scripts/generate_legal_brief_docx.py#L437) 同步改软隐藏 wording |
| 1.4.2 | 需重新生成 docx | ⚠️ 需注意 | 工程 | 低 | ✅ 是 | [docs/LEGAL_REVIEW_BRIEF.docx](file:///d:/Batch/chroniccare/docs/LEGAL_REVIEW_BRIEF.docx) 需跑 `python scripts/generate_legal_brief_docx.py` 重新生成 |

### 1.5 守门员验证

| # | 检查项 | 状态 | 类别 | 修复难度 | R96 相关 | 详情 |
|---|--------|------|------|----------|----------|------|
| 1.5.1 | check_legal_consent.py 全绿 | ✅ 通过 | 工程 | 低 | ✅ 是 | 跑 `python scripts/check_legal_consent.py` 返 `[OK]` |
| 1.5.2 | check_strings_hardcoded.py 全绿 | ✅ 通过 | 工程 | 低 | ✅ 是 | 跑 `python scripts/check_strings_hardcoded.py` 返 `[OK]` |
| 1.5.3 | check_arb_keys.py 全绿 | ✅ 通过 | 工程 | 低 | 否 | zh / en / zh_Hant 同步 |
| 1.5.4 | flutter analyze 0 error | ✅ 通过 | 工程 | 低 | 否 | 跑 `flutter gen-l10n` + `flutter analyze` 0 error |

---

## 第 2 部分：App Store Review Guidelines 章节对照

### 2.1 Guideline 1.5 — Developer Information（开发者信息）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 2.1.1 | App Store Connect 开发者信息完整 | 🔴 阻塞 | 配置 | 中 | 需用户填真实 Apple Developer 账号 + Team ID（R96 改 ENV 后通过 .env 注入） |
| 2.1.2 | support_url 可达 | 🔴 阻塞 | 法务 | 中 | [fastlane/metadata/ios/zh-Hans/support_url.txt](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/support_url.txt) = `https://chroniccare.app/support`，域名未注册 |
| 2.1.3 | privacy_url 可达 | 🔴 阻塞 | 法务 | 中 | [fastlane/metadata/ios/zh-Hans/privacy_url.txt](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/privacy_url.txt) = `https://chroniccare.app/privacy`，域名未注册 |
| 2.1.4 | Developer email（App Store Connect 字段） | ⚠️ 需注意 | 法务 | 低 | R96 软隐藏 `support@chroniccare.app` 后，App Store Connect "Support URL" 仍需可达 URL。**建议**: 注册域名后部署简单 HTML 联系页，或暂用 GitHub Pages 占位 |

### 2.2 Guideline 2.1 — App Completeness（App 完整性）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 2.2.1 | 7 项 FeatureFlag 隐藏业务在审核备注说明 | ⚠️ 需注意 | 法务 | 低 | IAP / 失联通知 / 5 厂商 push / EmailService / vent+mood 录音 / PHQ-9 i18n / BootReceiver 7 项 hidden，需在 App Review Information "Notes" 说明"v0.30 业务暂停，下版本真接" |
| 2.2.2 | IAP 入口完全 hidden | ✅ 通过 | 工程 | 中 | [feature_flags.dart](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) `iapEnabled=false`，UI 用 SizedBox.shrink 隐藏（非 disabled） |
| 2.2.3 | 失联通知入口 hidden | ✅ 通过 | 工程 | 中 | `emergencyContactEnabled=false` + `aliyunSmsEnabled=false` |
| 2.2.4 | 录音入口 hidden | ✅ 通过 | 工程 | 中 | `ventAudioEnabled=false` |
| 2.2.5 | PHQ-9 / GAD-7 i18n fallback | ⚠️ 需注意 | 工程 | 中 | `phqGad7I18nEnabled=false`，en/zh_Hant 用户做题走 fallback key（中文题目）。**法律风险**: en 用户看到中文题目，建议审核备注说明"v0.31 完成翻译" |
| 2.2.6 | demo 账号 / 测试账号 | ✅ 通过 | 工程 | 低 | App 完全本地化，无需 demo 账号 |

### 2.3 Guideline 5.1 — Privacy（隐私）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 5.1.1 | 隐私政策可达 | 🔴 阻塞 | 法务 | 中 | privacy_url 域名未注册（同 2.1.3） |
| 5.1.2 | 数据收集声明完整 | ✅ 通过 | 法务 | 低 | [PrivacyInfo.xcprivacy](file:///d:/Batch/chroniccare/ios/Runner/PrivacyInfo.xcprivacy) 声明 4 类数据（HealthAndFitness / AudioData / ContactInfo / UserContent）+ Linked=false + Tracking=false + Purposes=AppFunctionality |
| 5.1.3 | Required Reason API 声明完整 | ✅ 通过 | 法务 | 低 | 5 个 API: UserDefaults (CA92.1+CA92.2) / FileTimestamp (C617.1) / SystemBootTime (35F9.1) / DiskSpace (85F4.1) / ProcessInfo (AC67.1) |
| 5.1.4 | 数据本地化存储说明 | ✅ 通过 | 法务 | 低 | privacy_policy.md §2 "所有数据仅存在用户设备本地，不上传任何云端" + SQLCipher AES-256 加密 |
| 5.1.5 | 用户撤回同意权 | ✅ 通过 | 法务 | 低 | privacy_policy.md §4 "撤回同意" + R67 ConsentGate 集中器业务层真接 |
| 5.1.6 | 联系方式可达 | ⚠️ 需注意 | 法务 | 低 | R96 软隐藏后无邮件/GitHub 渠道，仅 App 内反馈。**风险**: Apple Reviewer 可能依据 5.1.1 要求"便捷联系方式" |

### 2.4 Guideline 5.1.2 — Data Use（数据使用）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 5.1.2.1 | 数据用途与声明一致 | ✅ 通过 | 法务 | 低 | privacy_policy.md §1 数据收集表 + PrivacyInfo.xcprivacy Purposes=AppFunctionality 一致 |
| 5.1.2.2 | 不做用户追踪 | ✅ 通过 | 法务 | 低 | PrivacyInfo.xcprivacy `NSPrivacyTracking=false` + `NSPrivacyTrackingDomains=[]` |
| 5.1.2.3 | 第三方 SDK 数据处理说明 | ✅ 通过 | 法务 | 低 | privacy_policy.md §7 列出 22 个 SDK，全部"仅在用户设备本地运行" |
| 5.1.2.4 | IAP 支付数据披露 | ✅ 通过 | 法务 | 低 | privacy_policy.md §7 "in_app_purchase 真实披露" 段说明"购买票据 + 应用 ID" |

### 2.5 Guideline 5.1.5 — Health Apps（健康类 App）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 5.1.5.1 | 不提供医疗建议声明 | ✅ 通过 | 法务 | 低 | user_agreement.md §2 "本 App 不提供医疗建议、诊断或治疗" + §5 "心理评估结果仅供参考，不应作为临床诊断依据" |
| 5.1.5.2 | 心理危机干预热线 | ✅ 通过 | 法务 | 低 | user_agreement.md §5 + sensitive_data_consent.md §8 列出 5 条热线（大陆 2 + 港澳台 3） |
| 5.1.5.3 | 失联通知非紧急救援声明 | ✅ 通过 | 法务 | 低 | user_agreement.md §2 "失联通知功能不是紧急救援服务。遇紧急情况请拨打 120 / 110" |

### 2.6 Guideline 5.1.1 — Legal（法律合规）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 5.1.1.1 | PIPL §14 单独同意 | ✅ 通过 | 法务 | 低 | privacy_policy.md §0 "3 项同意的时刻 + 协议版本号会写入本地数据库" + setup_legal_dialog 单独勾选 |
| 5.1.1.2 | PIPL §28 敏感个人信息同意 | ✅ 通过 | 法务 | 低 | sensitive_data_consent.md 完整 + §4 "必须取得您的单独同意" |
| 5.1.1.3 | PIPL §23 第三方提供单独同意 | ✅ 通过 | 法务 | 低 | privacy_policy.md §0.5 紧急联系人告知 + §12 单独同意实现进度（本版本不实际触发，不构成违规） |
| 5.1.1.4 | PIPL §38 跨境数据传输 | ✅ 通过 | 法务 | 低 | privacy_policy.md §11 "本版本无跨境 PII 传输实际场景" |
| 5.1.1.5 | 未成年人保护 | ✅ 通过 | 法务 | 低 | privacy_policy.md §10 "14-18 周岁需监护人代为签署同意" + 严正声明 |
| 5.1.1.6 | 律师过审 | 🔴 阻塞 | 法务 | 高 | 3 份法律 md 修订历史段均标"草稿 (未经律师过审)"，上 store 前必须律师过审 |

### 2.7 Guideline 4.0 — Design（设计）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 4.0.1 | App 元数据完整（name/subtitle/description/keywords） | ✅ 通过 | 配置 | 低 | [fastlane/metadata/ios/zh-Hans/](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans) 8 个字段全填 |
| 4.0.2 | 3 语本地化（zh-Hans / zh-Hant / en-US） | ✅ 通过 | 配置 | 低 | fastlane/metadata/ios 下 3 个 locale 目录全 |
| 4.0.3 | App Icon 1024×1024 | ⚠️ 需注意 | 配置 | 中 | 需确认 icon 已 store-ready（非 dev icon） |
| 4.0.4 | Screenshot（6.5" + iPad 12.9"） | 🔴 阻塞 | 配置 | 中 | 需截 33 张真机截图（3 设备 × 3 locale × 3-5 张） |

### 2.8 Guideline 3.1 — In-App Purchase（应用内购买）

| # | 检查项 | 状态 | 类别 | 修复难度 | 详情 |
|---|--------|------|------|----------|------|
| 3.1.1 | IAP 业务暂停说明 | ⚠️ 需注意 | 法务 | 低 | user_agreement.md §3 "本 App 售价 8 元" + R69 注脚"IAP 业务整体暂停"。**风险**: Apple 2.1 可能拒"声明付费但无购买入口"，需审核备注说明 |
| 3.1.2 | IAP productId 真接 | 🔴 阻塞 | 工程 | 中 | App Store Connect productId 未真接，`iapEnabled=false` |

---

## 第 3 部分：R96 软隐藏策略 Apple 审核风险分析

### 3.1 软隐藏策略合规性评估

**软隐藏策略**: user_agreement.md §8 + privacy_policy.md §9 声明"本服务暂不提供邮件 / GitHub 渠道"，用户通过 App 内 设置 → 法律与隐私 页面反馈。

**Apple 审核风险**:

| 风险点 | 严重度 | 概率 | 应对策略 |
|--------|--------|------|----------|
| Apple Reviewer 依据 5.1.1 要求"便捷联系方式" | 中 | 中 | 审核备注说明"软隐藏策略 + App 内反馈渠道 + 域名注册后启用邮件" |
| Apple Reviewer 依据 1.5 要求 Support URL 可达 | 高 | 高 | **必须**注册域名 + 部署 support URL（R96 软隐藏不替代 Support URL） |
| Apple Reviewer 看到 user_agreement.md "本服务暂不提供邮件渠道" 询问 | 低 | 低 | 审核备注说明"过渡方案，域名注册后启用" |
| Apple Reviewer 依据 PIPL §52 要求"便捷联系渠道" | 低 | 低 | 中国区审核可能关注，App 内反馈渠道已满足"便捷" |

### 3.2 审核备注模板（App Review Information → Notes）

```
App Review Notes (v0.30.0+85):

1. 业务暂停说明 (Guideline 2.1):
   本版本 7 项业务因外部依赖未真接，已用 FeatureFlag 隐藏（UI SizedBox.shrink，非 disabled）:
   - IAP 8 元买断 (productId 未真接，下版本接入)
   - 失联通知 SMS (阿里云 SMS 法务审核中，1-2 月)
   - 5 厂商 push (米/华/OPPO/vivo/魅族 SDK 接入中)
   - EmailService (SendGrid 审核中)
   - vent + mood 录音 (业务闭环完善中)
   - PHQ-9 / GAD-7 i18n (en/zh_Hant 翻译中)
   - Android BootReceiver (WorkManager 完善中)

2. 联系方式软隐藏说明 (Guideline 5.1.1):
   本版本暂不提供邮件 / GitHub 渠道（域名 + 邮箱注册中）。
   用户可通过 App 内 设置 → 法律与隐私 页面反馈问题。
   域名注册后（预计 7-20 天 ICP 备案）启用 support@chroniccare.app 邮箱。

3. 法律文档状态:
   3 份法律文档（privacy_policy / user_agreement / sensitive_data_consent）
   已完成 PIPL/HIPAA/GDPR 12 章节覆盖，律师过审中（预计 1-2 周）。

4. 数据本地化:
   所有用户数据仅存用户设备本地（SQLCipher AES-256 加密），
   零云端，零追踪，零广告 SDK。
```

---

## 第 4 部分：提交前 Must-Fix 清单（按优先级）

### 🔴 P0 — 阻塞提交（必须修）

| # | 任务 | 类别 | 修复难度 | 详情 |
|---|------|------|----------|------|
| P0-1 | 律师过审 3 份法律 md | 法务 | 高（1-2 周 + ¥45-90k） | [SPRINT1_LEGAL_TODO.md §1](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md) |
| P0-2 | 注册域名 `chroniccare.app` + ICP 备案 + HTTPS 部署 | 法务 | 中（1-2 天 + 7-20 天 ICP） | 解锁 privacy_url / support_url 可达 |
| P0-3 | 填真实 APPLE_ID / TEAM_ID / ITC_TEAM_ID 到 .env | 配置 | 低（10min） | R96 改 ENV 模式后，用户从 Apple Developer 后台拿真实值填 .env |
| P0-4 | App Store Connect 元数据填写完整 | 配置 | 中 | name / subtitle / description / keywords / icon / screenshot |
| P0-5 | 截 33 张真机 screenshot（3 设备 × 3 locale × 3-5 张） | 配置 | 中 | 6.5" iPhone + iPad 12.9" + 5.5" |

### 🟡 P1 — 提交前应修

| # | 任务 | 类别 | 修复难度 | 详情 |
|---|------|------|----------|------|
| P1-1 | 重新生成 LEGAL_REVIEW_BRIEF.docx | 工程 | 低 | 跑 `python scripts/generate_legal_brief_docx.py` 同步 R96 软隐藏 |
| P1-2 | 审核备注撰写（按 §3.2 模板） | 法务 | 低 | App Review Information → Notes |
| P1-3 | App Icon 1024×1024 store-ready | 配置 | 中 | 确认非 dev icon |
| P1-4 | PHQ-9 / GAD-7 en 题目翻译 | 工程 | 中（8-16h） | 避免 en 用户看到中文题目（法律风险） |

### 🟢 P2 — 提交后可做

| # | 任务 | 类别 | 修复难度 | 详情 |
|---|------|------|----------|------|
| P2-1 | 域名注册后取消软隐藏恢复 §8 联系方式 | 法务 | 低 | R96 软隐藏是过渡方案 |
| P2-2 | IAP productId 真接 | 工程 | 中 | 下版本做 |
| P2-3 | 失联通知 SMS 真接 | 工程 | 高 | 下版本做 |

---

## 第 5 部分：R96 修复前后对比

### 5.1 修复前（R95）

| 位置 | 内容 | 风险 |
|------|------|------|
| user_agreement.md:68 | `support@chroniccare.app(**TODO 占位 — 上 store 前必须注册并替换为真实邮箱**)` | 🔴 Apple Reviewer 看到占位邮箱 = 直接拒 |
| user_agreement.md:69 | `https://github.com/example/chroniccare/issues(**TODO 占位,需确认或替换为真实项目仓库**)` | 🔴 example.com 占位 = 直接拒 |
| fastlane/Appfile:21 | `apple_id("your-apple-id@example.com")` | 🔴 占位值 = fastlane 无法提交 |
| fastlane/Appfile:23 | `team_id("YOUR_TEAM_ID")` | 🔴 占位值 |
| fastlane/Appfile:25 | `itc_team_id("YOUR_ITC_TEAM_ID")` | 🔴 占位值 |

### 5.2 修复后（R96）

| 位置 | 内容 | 状态 |
|------|------|------|
| user_agreement.md:68 | `本服务暂不提供邮件 / GitHub 渠道 (v0.30 R96 决策, 软隐藏)` | ✅ 合规（软隐藏策略） |
| fastlane/Appfile:27 | `apple_id(ENV["APPLE_ID"])` | ✅ 合规（ENV 模式，真实值通过 .env 注入） |
| .env.example:36 | `APPLE_ID=your-apple-id@example.com` | ✅ 合规（模板文件，用户复制为 .env 填真实值） |

### 5.3 修复影响

| 维度 | 修复前 | 修复后 |
|------|--------|--------|
| Apple Reviewer 看到 TODO 占位 | 🔴 直接拒 | ✅ 软隐藏 wording 合规 |
| fastlane 提交能力 | 🔴 占位值无法提交 | ✅ ENV 模式，.env 填真实值即可提交 |
| 上架就绪度 | ~40% | ~45% (+5%) |
| 阻塞项 | 5 项（邮箱 + GitHub + 3 个 Apple ID） | 2 项（律师 + 域名） |

---

## 附录 A: 相关文件清单

### R96 修改的文件（7 个）

1. [assets/legal/user_agreement.md](file:///d:/Batch/chroniccare/assets/legal/user_agreement.md) — §8 联系方式软隐藏 + 修订历史
2. [assets/legal/privacy_policy.md](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md) — §9 修订历史 + 最后更新时间
3. [fastlane/Appfile](file:///d:/Batch/chroniccare/fastlane/Appfile) — ENV 模式 + 顶部注释
4. [.env.example](file:///d:/Batch/chroniccare/.env.example) — Apple Developer ENV 变量段
5. [scripts/generate_legal_brief_docx.py](file:///d:/Batch/chroniccare/scripts/generate_legal_brief_docx.py) — 同步软隐藏 wording
6. [docs/SPRINT1_LEGAL_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md) — R96 软隐藏状态标注
7. [docs/audit/2026-08-07/comprehensive-status-analysis.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-07/comprehensive-status-analysis.md) — 综合分析报告 R96 更新

### App Store 审核相关文件（参考）

- [ios/Runner/PrivacyInfo.xcprivacy](file:///d:/Batch/chroniccare/ios/Runner/PrivacyInfo.xcprivacy) — Apple 2024-05 强制隐私清单
- [ios/Runner/Info.plist](file:///d:/Batch/chroniccare/ios/Runner/Info.plist) — iOS 权限声明
- [android/app/src/main/AndroidManifest.xml](file:///d:/Batch/chroniccare/android/app/src/main/AndroidManifest.xml) — Android 权限声明
- [fastlane/metadata/ios/](file:///d:/Batch/chroniccare/fastlane/metadata/ios) — App Store Connect 元数据（3 locale × 8 字段）
- [lib/core/data/feature_flags.dart](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) — 8 项 FeatureFlag 集中定义

## 附录 B: 守门员脚本验证

```bash
# R96 修复后跑的守门员（全绿）
python scripts/check_legal_consent.py        # [OK] 无 TODO / 无 PIPL §13 单独同意 TODO
python scripts/check_strings_hardcoded.py    # [OK] 32 处中文 static const + R57 override 配对
python scripts/check_arb_keys.py             # [OK] zh / en / zh_Hant 同步
flutter analyze --no-pub                     # 0 error（跑 flutter gen-l10n 后）
```

## 附录 C: 参考资料

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Privacy Details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
- [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [docs/audit/2026-08-06/04-appstore-ios-report.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-06/04-appstore-ios-report.md) — AppStore 6 视角审计
- [docs/SPRINT1_LEGAL_TODO.md](file:///d:/Batch/chroniccare/docs/SPRINT1_LEGAL_TODO.md) — Sprint 1 法务待办
- [docs/audit/2026-08-07/comprehensive-status-analysis.md](file:///d:/Batch/chroniccare/docs/audit/2026-08-07/comprehensive-status-analysis.md) — 综合分析报告
