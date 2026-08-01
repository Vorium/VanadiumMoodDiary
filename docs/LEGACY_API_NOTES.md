# 软隐藏决策 + 重新启用条件（v0.27 R67 集中跟踪）

> v0.27 R67 引入: 多个 "v1.0+ TODO" 业务 (SMS 真接 / Email 真接 / IAP /
> 紧急联系人本人独立确认 / DosageUnit i18n / 16KB 完整验 / pod install
> 核) 走 **软隐藏** 策略 — 留 TODO 注释, **业务暂停**, release 模式
> 不触发, 不算 fail, 让 v0.27 MVP 上架能跑通 (用户最基础功能)。
>
> v0.27 R72 spen B-1 + B-2 + B-3 加 3 处 release guard: release 模式未
> 配置 provider 走 `throw StateError` 阻断, 防止 mock 误判业务可用。
>
> v0.27 R77 (P0-15 紧急, R74 报告 AS-P0-11 修): 此占位 md 创建, 让
> `privacy_policy.md:0.5` + `user_agreement.md:60-61` 引用死链
> `docs/LEGACY_API_NOTES.md` 暂时不报 404。

## 软隐藏业务清单 (R67-R72 累计 6+ 项)

### 1. AliyunSmsProvider 真接
- **R55 之前**: send() 静默返 true
- **v0.22 R38 P0-1 修**: send() 抛 `UnimplementedError`
- **v0.23 R63 改**: 改抛 `StateError` ("业务不可用"), 明确语义
- **v0.27 R72 B-2 release guard**: release 模式 `_isFullyImplemented=false` 抛 StateError
- **重新启用条件**:
  1. 法务审核 1-2 月 (短信模板 + PIPL)
  2. 阿里云 AccessKey 申请 (需公司资质)
  3. 改 `_isFullyImplemented=true`
  4. release 跑通冒烟

### 2. EmailService SendGrid 真接
- 同 1, provider 改 SendGrid
- 当前 mock, send 返 false (R67 P1-8 修)
- **重新启用条件**: SendGrid API key 申请 + 法务

### 3. StoreKit IAP
- 0 个 IAP (v0.23 R55 暂停)
- `in_app_purchase_storekit 0.4.11` 引入但 `FeatureFlags._prodIapEnabled=false`
- **重新启用条件**: App Store Connect 创建 productId + 法务 8 元定价过审

### 4. 紧急联系人本人独立确认 (PIPL §13 完整实施)
- 当前 PIPL §13 走"代理人代同意"模式 (用户告知 + 用户同意即生效)
- **完整实施**: 紧急联系人本人收到 SMS 确认链接, 点确认后才生效
- **重新启用条件**: SMS 通道 (依赖 #1) + 法务 §13 详细条款

### 5. 16KB page size 完整验
- v0.27 R70 加 `check_16kb_alignment.py` 简化版 (查配置)
- **完整验**: build aab + `objdump -p` 看 segment align >= 2**14 = 16384
- **重新启用条件**: 跑完整 aab build + objdump (需 macOS + Android SDK)

### 6. pod install 核第三方 plugin PrivacyInfo
- **背景**: 第三方 plugin (audioplayers / record / printing / share_plus /
  sqlcipher_flutter_libs) 需自带 PrivacyInfo.xcprivacy, 否则 Apple 拒
- **当前**: 未核 (R67 假设都是合规)
- **重新启用条件**: pod install + 逐个查 plugin pod 目录

### 7. DosageUnit i18n
- 当前 `'片' → 'tablet' (跟英文 locale 一致)` 留 v1.0 (v0.27 R22)
- 届时走 migration + 一次性数据迁移脚本

### 8. PackageInfo 读 legal version
- v0.27 R75 改 `_kLegalVersion = 'v0.27-2026-08-01'` (const 写死, R76-N6 半修)
- **完整方案**: 启动时读 `package_info_plus` 拿 pubspec version, 升级时自动 bump
- **R77+ 考虑**: 加 `package_info_plus` plugin
