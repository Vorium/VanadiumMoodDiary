# Google Play 上架规范要点 (googleplay.md)

> 来源: Google Play Developer Policy Center (2026-08-16 webfetch 失败, 基于知识库生成) `[来源: 知识库，待人工核验]`
> 适用项目: chroniccare (Flutter, Android 平台, targetSdk 36, 零云端)

## 硬性技术门槛
- **Target API**: 新应用/更新必须 target 最近 1 年内的 Android 版本 (2026-08: Android 15/API 35 起; 本项目 targetSdk 36 达标)
- **64 位**: 2021-08 起必须含 arm64-v8a (Flutter 默认全 ABI, 达标)
- **16KB page size**: 2025-11-01 起新 App/更新必须 16KB 对齐 — sqlcipher_flutter_libs ≥0.6.5 + NDK 27 配置已达标, 需 release build 后 objdump 实测 (check_16kb_alignment.py --aab)
- 签名: Play App Signing (上传 key + 商店 key); keystore 已生成需备份

## 数据安全与隐私
- **Data Safety 表单** (2022 起必填): 收集类型/用途/是否加密/可否删除 — 本项目: 全本地 0 收集, 表单已生成 build/data_safety_form.md
- **健康类 App (Health Connect / 心理健康) 政策**: 心理健康类内容需额外审查; 量表自评工具必须有免责声明 (已有); 不得宣称诊断/治疗
- 权限声明: RECORD_AUDIO (树洞录音) 必须声明用途; POST_NOTIFICATIONS 13+; SCHEDULE_EXACT_ALARM 需填权限声明表单 (生成器已备)
- 隐私政策 URL: 必填, 必须可达 (域名前置)

## 内容政策
- 虚假信息/误导健康声明: 心理类文案不得暗示"治愈" (已修 "NOT a medical device")
- 自杀/自残内容: **危机干预** — 心理健康 App 提供热线即合规加分项; 若引导就医文案不当可能触发审查, 需人工复核
- UGC: 树洞为本地私密日记, 无社区 → 无需举报机制

## 审核拒绝常见原因 (本项目对照)
| 原因 | 状态 |
|---|---|
| 目标 API 过期 | ✅ 36 |
| 16KB 对齐 | ⚠️ 配置绿, 产物未实测 |
| 隐私 URL 不可达 | ❌ 域名 ICP 未完成 |
| 截图缺失/占位 | ❌ 67B 空白占位 |
| 权限未声明 (RECORD_AUDIO) | ⚠️ 表单文本已生成, console 未填 |
| 医疗宣称 | ✅ 免责已落地 |
| 开发者账号/测试说明 | ⚠️ notes 需补 Android 侧 |

## 上架必备清单
- [ ] 隐私 URL (ICP)
- [ ] 截图 (phone 4-8 + tablet 2)
- [ ] Data Safety / Health Apps / Permissions / 删除 4 表单 (console)
- [ ] 首次 release build + 16KB objdump 实测
- [ ] keystore + 密码备份 (1Password)
- [ ] Play Console 开发者账号 + 12$ 注册费
