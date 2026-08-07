# R100 Google Play 视角报告（Android 上架准备）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动
**方法**: build.gradle.kts / AndroidManifest.xml / fastlane android metadata / 16KB 检查脚本逐项实测

## 一、已达标

| 项 | 证据 |
|---|---|
| targetSdk=36 / minSdk=24 显式 pin | `android/app/build.gradle.kts` |
| 16KB page size（Google Play 2025-11 强制）| ✅ sqlcipher_flutter_libs 版本 OK + NDK 默认 27.x（`check_16kb_alignment.py` 通过，仅 WARN ndkVersion 未显式声明） |
| R8 minify + shrinkResources + 64-bit ABI | build.gradle.kts release 配置 |
| 权限最小化：仅 5 项（INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE），R97 已删 USE_EXACT_ALARM / RECORD_AUDIO / BOOT_COMPLETED | AndroidManifest.xml:42-46 |
| cleartext 禁明文 + allowBackup=false（PIPL §28） | network_security_config + manifest |
| Release 签名配置就绪（key.properties 模式） | build.gradle.kts:55-94 |
| 双语 metadata（zh-CN / en-US）文案齐全 | fastlane/metadata/android/ |

## 二、问题清单（按拒审风险排序）

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| G-1 | **截图 + Feature Graphic 全是 67 字节 1×1 占位 PNG**（zh-CN / en-US 各 4 张截图 + feature_graphic）—— Play Console 对截图有最小尺寸校验，必拒 | `fastlane/metadata/android/*/phone_screenshots/` + `feature_graphic.png` | 底层 | 中（需真机截图 1080×1920+ / 1024×500） | **高（P0）** |
| G-2 | **video.txt = PLACEHOLDER YouTube 链接**（`watch?v=PLACEHOLDER_APP_DEMO_VIDEO`），Play 会校验 URL 有效性 | `fastlane/metadata/android/*/video.txt` | 底层 | 简单（直接删文件） | **高（P0）** |
| G-3 | **release keystore + key.properties 尚未创建** —— 无签名无法产出可上架 AAB | `android/key.properties`（不存在） | 底层 | 简单（按 PLAYSTORE_SIGNING_GUIDE 5 步） | **高（P0，提审前最后一步）** |
| G-4 | **title 含 "(失联通知规划中)"**，宣传未上线功能，审核员会追问；建议与 iOS subtitle 同步删 | `fastlane/metadata/android/zh-CN/title.txt` | 底层 | 简单 | 中（P1） |
| G-5 | **Data Safety Form**：需声明"不收集任何数据" + 提供数据删除方式（App 内导出/清除即满足，但表单要求可访问的说明 URL，依赖域名注册） | Play Console 手工项 | 底层 | 简单（表单） | 中（P1） |
| G-6 | `INTERNET` 权限保留但 iapEnabled=false，Data Safety 表单需解释（in_app_purchase 依赖） | AndroidManifest.xml:42 | 底层 | 简单（表单说明） | 中 |
| G-7 | 国产 ROM 通知可靠性：5 厂商 push flag 关闭 + BootReceiver flag 关闭（Android 14+ 重启后通知不恢复），需在 listing 描述中不承诺"重启后仍提醒" | FeatureFlags | 底层 | — | 低（文案注意） |
| G-8 | ndkVersion 未显式声明（走 flutter.ndkVersion 默认），`check_16kb_alignment.py` WARN；建议显式 pin 避免未来 Flutter 升级漂移 | build.gradle.kts | 底层 | 简单 | 低 |

## 三、结论

Android 技术合规度很高（权限最小化 + 16KB 就绪 + R8 完整）。**三个 P0 全是资产/流程问题而非代码问题**：真实截图（G-1）、删占位视频（G-2）、生成签名（G-3）。修完即可提审。
