# GooglePlay 审计报告 — R101

**审计时间**: 2026-08-07 | **拒审风险**: 高

---

## REJECT — 必定被拒 (5 项)

| # | 问题 | 策略 | 文件 |
|---|------|------|------|
| 1 | record/speech_to_text 合并 RECORD_AUDIO 权限 (插件 Manifest 自带) | 权限政策 | pubspec.yaml:64-76 |
| 2 | 法律文件标注"草稿 (未经律师过审)" | 用户数据 | 3 份 md 修订历史 |
| 3 | 隐私政策联系方式缺失 ("本服务不提供邮件") | 开发者身份 | privacy_policy.md:150 + user_agreement.md:67 |
| 4 | PHQ-9/GAD-7 i18n 未完成 → 英文用户看中文题 | 多语言+健康 | feature_flags.dart:52 |
| 5 | SCHEDULE_EXACT_ALARM 运行时权限未检查 → crash | 精确闹钟 | reminder_dispatcher.dart:118,160 |

## REJECT-LIKELY — 大概率被拒 (5 项)

| # | 问题 | 策略 |
|---|------|------|
| 6 | 树洞 UGC 无审核/举报机制 | UGC 政策 |
| 7 | IAP 插件声明但功能禁用 → 触发计费审核 | 计费政策 |
| 8 | 用户协议描述"核心功能"但实际禁用 | 误导性声明 |
| 9 | 缺少"非医疗设备"首次启动声明 | 健康内容 |
| 10 | 联系方式全缺失 | 开发者身份 |

## WARNING (8 项)

| # | 问题 |
|---|------|
| 11 | BootReceiver.kt 半成品文件存在但未注册 |
| 12 | Data Safety 表单需声明健康数据收集 |
| 13 | 内容评级可能触发 Mature 17+ |
| 14 | compileSdk 用 flutter.compileSdkVersion 而非显式值 |
| 15 | allowBackup=false + data_extraction_rules 冗余 |
| 16 | 评估结果严重度标签缺"非医疗"修饰词 |
| 17 | 危机热线 6 地区覆盖不全 (缺日韩加澳) |
| 18 | proguard-rules.pro 缺 in_app_purchase/url_launcher keep |

## 合规确认 (17 项) ✅

19-35: targetSdk=36 ✅ / 64-bit ✅ / AAB 签名 ✅ / ProGuard ✅ / SQLCipher ✅ / cleartext=false ✅ / 备份排除 ✅ / 医疗免责声明 ✅ / PIPL 同意 ✅ / 危机干预 ✅ / 通知权限时机 ✅ / a11y ✅ / 未成年保护 ✅ / 离线优先 ✅ / multidex ✅ / debuggable=false ✅ / 预测式返回手势 ✅
