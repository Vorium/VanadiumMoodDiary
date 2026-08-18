# SUBMISSION_INFO — 上架提交清单

> **本文件重建日期**: 2026-08-18 (gdc R128e audit)
> **原始 SUBMISSION_INFO.md (5245L CHANGELOG 部分 + R72-R108 上架 checklist) 已随 322 份含'修'字文档 commit 删除 (b2d9744f)**
> **当前状态**: 1.1.0+185, 上架准备度代码 9/10 + 元数据 0/10

---

## 一、Apple App Store Connect 必填项 (5 P0 硬阻断)

### 1.1 Privacy Policy URL (3 locale)
- `fastlane/metadata/ios/en-US/privacy_url.txt`
- `fastlane/metadata/ios/zh-Hans/privacy_url.txt`
- `fastlane/metadata/ios/zh-Hant/privacy_url.txt`
- **当前**: `[PENDING_DOMAIN: 域名注册后替换为 https://chroniccare.app/privacy]`
- **修复**: 域名注册 + DNS + GitHub Pages 配置 (短期方案)

### 1.2 Support URL (3 locale)
- `fastlane/metadata/ios/en-US/support_url.txt`
- `fastlane/metadata/ios/zh-Hans/support_url.txt`
- `fastlane/metadata/ios/zh-Hant/support_url.txt`
- **当前**: `[PENDING_DOMAIN: ...]`
- **修复**: 同 1.1

### 1.3 review_information 4 字段
- `fastlane/metadata/ios/review_information/first_name.txt`
- `fastlane/metadata/ios/review_information/last_name.txt`
- `fastlane/metadata/ios/review_information/email_address.txt`
- `fastlane/metadata/ios/review_information/phone_number.txt`
- **当前**: 全部 `[REPLACE_BEFORE_APPLE_REVIEW: ...]`
- **修复**: 真人填字段 (1h)

### 1.4 iOS Screenshots (3 locale × 3 尺寸)
- `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/`
- **当前**: 0 张
- **修复**: 设计师出图 (1-2 周) + 5-8 张/尺寸 × 3 尺寸 × 3 locale

### 1.5 iOS Podfile
- `ios/Podfile` + `ios/Podfile.lock`
- **当前**: 占位 (R77 标注, 首次 macOS build 必须重新生成)
- **修复**: macOS 跑 `cd ios && pod install`, commit `Podfile.lock` (1d)

---

## 二、Google Play Console 必填项 (1 P0 硬阻断)

### 2.1 域名 + ICP 备案
- **当前**: `[PENDING_DOMAIN: ...]` (隐私政策 URL + 支持 URL + Data Safety 邮箱 全部占位)
- **修复**: 域名注册 + ICP 备案 (7-20 天流程, 中国上架必备)

### 2.2 Data Safety 表
- Play Console 后台 Data Safety 申报 (GDPR/CCPA 数据申报)
- **当前**: 0 填写
- **修复**: 跟 assets/legal/privacy_policy.md 数据收集声明 1:1

### 2.3 截图 (8 张竖屏)
- `fastlane/metadata/android/{en-US,zh-CN}/phoneScreenshots/`
- **当前**: 0 张 (历史有 4 张横屏 1232×720)
- **修复**: 设计师出图

### 2.4 Changelog (default.txt)
- `fastlane/metadata/android/{en-US,zh-CN}/changelogs/`
- **当前**: `default.txt` = v1.0.0 内容
- **修复**: 已加 `115.txt` (1.1.0+185) (本 R128e audit 已 commit), 切换 fastlane 默认到 115.txt

---

## 三、跨平台共享元数据

### 3.1 5 法律文档 (assets/legal/)
| 文件 | 行数 | 状态 |
|---|---|---|
| `privacy_policy.md` | 200 | R128e audit 重建 + git 取回 + 已 commit |
| `user_agreement.md` | 89 | R128e audit: TODO → PENDING_LAWYER_REVIEW 标记 |
| `sensitive_data_consent.md` | — | 已 commit |
| `medical_disclaimer.md` | 53 | 5 地区热线 + 不替代医生声明 + 非医疗器械声明 |

### 3.2 法律文档邮箱占位 (3 处)
- `assets/legal/privacy_policy.md:131`
- `assets/legal/user_agreement.md:61, 63`
- **当前**: `【邮箱待启用: 域名注册后填入】`
- **修复**: 域名注册后填 `support@chroniccare.app` + `privacy@chroniccare.app`

---

## 四、技术合规清单 (已绿)

### 4.1 Apple
- [x] iOS Deployment Target 14.0 (可升至 15.0+)
- [x] PrivacyInfo.xcprivacy 5+2 NSPrivacyXyz 完整
- [x] Runner.entitlements 空 dict (0 HealthKit 误声明)
- [x] Info.plist 0 NSHealthShareUsageDescription
- [x] LSApplicationCategoryType = healthcare-fitness
- [x] 5 守门员 + 1 lock-in + 1 description (check_apple_health_claim.py 7 规则)
- [x] 16KB page size (sqlcipher_flutter_libs 0.6.5+)
- [x] 0 APNs (本 app 不远程推送)
- [x] 0 ATT (本 app 不追踪)
- [x] 0 IAP (永久免费定版)
- [x] 危机热线 5 地区 + tel: scheme 一键拨打

### 4.2 Google Play
- [x] targetSdk 36 (Android 15)
- [x] AAB 强制 (build/app/outputs/bundle/release/)
- [x] 64-bit native libs (drift / sqlcipher)
- [x] Play App Signing (Play Console 后台启用)
- [x] 权限最小化 (通知 + 录音 + 拨号 + 存储, 仅必要)
- [x] 备份排除 (3 个 XML, app docs + audio + db 排除 iCloud)
- [x] network_security HTTPS-only

### 4.3 跨平台
- [x] SQLCipher 加密 (flutter_secure_storage + pointycastle)
- [x] flutter_localizations + intl 0.20.2 (zh / en / zh_Hant)
- [x] a11y: prefers-reduced-motion + 全局 textScaler 1.5x clamp (R128e)
- [x] 危机热线 5 地区 i18n 三语

---

## 五、上架阻塞清单 (按优先级)

### 🔴 P0 (硬阻断, 上架会被立即拒)
1. iOS Screenshots 缺失 (3 locale × 3 尺寸)
3. iOS Privacy Policy URL 占位 (3 locale)
4. iOS Support URL 占位 (3 locale)
5. iOS review_information 4 字段占位
6. iOS Podfile 占位
7. Android 域名 + ICP 备案

### 🟠 P1 (review team 大概率退回)
1. user_agreement.md 律师过审 PENDING_LAWYER_REVIEW
2. 3 处邮箱占位
3. zh-Hant description 缺大陆热线 (已 R128e 部分修复: 加 3 条大陆热线)
4. iOS Appfile 用 ENV 占位 (fastlane 上传需 cp .env.example .env)
5. Google Play Data Safety form 0 填写
6. 16KB page size 未自动验证 (仅注释承诺)
7. Android 截图 8 张竖屏 (0 张)

### 🟡 P2 (可上架但需说明)
1. iPhone App Icon `@1x` 文件 < 1KB
2. iOS Deployment Target 14.0
3. iOS LaunchImage 用旧模式

---

## 六、修复路径

### 第一阶段 (1-2 周)
1. **域名注册** (1-2d, ¥150)
   - 注册 `chroniccare.app` (年费 $12-15)
   - DNS 配置 + GitHub Pages 部署
   - 替换 5 URL 占位 + 3 邮箱占位
2. **ICP 备案** (7-20d, 中国大陆必备)
3. **截图出图** (1-2 周, 设计师)
4. **review_information 填字段** (1h, 真人)
5. **macOS build 生成 Podfile.lock** (1d)

### 第二阶段 (1 月)
6. 律师过审法律文档 (¥3000-8000, 1-2 周)
7. Apple App Store Connect 实际填写 (主分类 / 副分类 / 年龄分级)
8. Google Play Console 实际填写 (Data Safety + 4 大表单)
9. fastlane ENV 配置 (.env.example → .env 真人填)

---

## 七、上架时间表预估

| 阶段 | 内容 | 时长 | 累计 |
|---|---|---|---|
| 域名 + DNS | 注册 chroniccare.app | 1-2d | 2d |
| ICP 备案 | 中国大陆备案 | 7-20d | 22d |
| 截图出图 | 设计师 | 1-2 周 | 36d |
| Podfile.lock | macOS build | 1d | 37d |
| review_information | 真人填字段 | 1h | 37d |
| 律师过审 | 法律文档 | 1-2 周 | 51d |
| Apple 提交 | App Store Connect | 3-7d review | 58d |
| Google Play 提交 | Play Console | 1-7d review | 65d |

**预估上架**: 60-65 天 (从今天起, 不计外部依赖延期)

---

## 八、跨期 P0 修真 (R129 hotfix, 已 commit)

R129 P0 修真 8 项 (c323d42d):
- Apple Health 字面提及 lock-in
- 5 vendor push NoOp 占位
- bootReceiver 守门员
- 0 widget lifecycle 漏
- 4 description 5 病名修正
- 7 IconButton PressFeedback
- review_information 4 TODO
- Spring 物理模型

R128e (本 gdc audit, 2026-08-18) 修真:
- R93 spec 5 flag → 1 flag 矛盾
- 3 prod-false flag 触发条件
- Apple Health 守门员 5 → 7 规则
- 14 文件 token 化

---

## 九、局限

- ❌ 原始 5245L SUBMISSION_INFO 详细清单已随 322 文档删除不可恢复
- ❌ App Store Connect 后台实际状态本审计无法访问
- ❌ Google Play Console 后台实际状态本审计无法访问
- ✅ 本清单是从 git + fastlane + audit 报告重建的精简版
- ✅ 后续提交增量修改直接 commit