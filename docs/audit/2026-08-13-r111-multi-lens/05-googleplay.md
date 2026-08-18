# Google Play 上架视角审计 (2026-08-13, R111)

## 基线

参照 R110 报告 (GP-01~18, `docs/audit/2026-08-13-multi-lens/06-googleplay.md`) + `docs/PLAYSTORE_SIGNING_GUIDE.md` (R67 5 步 keystore 指南) + `docs/DEPLOYMENT.md` (阶段 6.4/7.5 手动清单)。HEAD = `6bbb308` (0.32.0+140, R110 round 7b-6)。纯只读审计, 0 文件修改。

**结论: 仍不可提交。** 硬阻塞全部为外部依赖残留 (keystore / 5 项资产 / privacy URL), 代码/权限姿态保持强 (锁屏 PII 全闭环、最小权限、visibility 5 处全 secret 或有意 public)。R110 round 3 闭环的 4 个代码级 P0 (badge visibility / PII 检查 / gate / 版本号) 全部验证通过。**新增 1 个代码侧风险**: R105 恢复 RECORD_AUDIO + ventAudioEnabled=true 后, Data Safety 表单必须申报 Audio 收集, 且 Health Apps 问卷需加录音声明。

## Findings

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| GP-1 | 资产 | **8 张 phone_screenshots 仍 67B 空白占位** (en-US ×4 + zh-CN ×4, 1232×720 尺寸合法但内容空) — R110 跨期残留 | fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png (67B, IDAT 0 字节) | 设计师 1-2d | **P0** |
| GP-2 | 资产 | **feature_graphic 仍 67B 空白** (1024×500) — R110 跨期残留 | 两 locale feature_graphic.png | 设计师 4h | **P0** |
| GP-3 | 资产 | **icon 仍 192×192 默认 logo** (Play 要求 512×512 32-bit 源 + 合规图标) — R110 跨期残留 | fastlane icon.png (1443B, 192×192 colormap) + res/mipmap-* 默认 | 设计师 4h | **P0** |
| GP-4 | 资产 | 0 tablet 截图 + 0 `<supports-screens>` 声明 — R110 跨期残留 (注: Play 不强制 tablet 截图, 原 P0 过重, 降为 P2 推荐) | android/ 0 matches | 设计师 | P2 |
| GP-5 | 元数据 | **en-US short_description 86 字符 > 80 上限** (Play console 直接拒绝保存) — R110 跨期残留 | fastlane/metadata/android/en-US/short_description.txt (len=86) | 5min | **P0** |
| GP-7 | 技术 | **keystore 仍未生成** — `key.properties` 不存在 (仅 example), 0 jks; release signingConfig 已切 (R97), 但无 keystore → 首次 `flutter build appbundle --release` 必挂 "Keystore file not set" — R110 跨期残留 | android/key.properties 缺失 / build.gradle.kts:91-95 | 1h | **P0** |
| GP-11 | 表单 | **Data Safety + Health Apps 问卷 + Permissions Declaration 3 表单仍未填** (console 侧); 生成脚本就绪但 0 提交记录 | scripts/generate_data_safety_form.py / generate_health_apps_questionnaire.py (均存在) | 2-3h console | **P0** |
| E5 | 元数据 | **privacy URL 仍指向未注册域名** `https://chroniccare.app/privacy` (域名 ICP 7-20d 外部依赖) — R110 跨期残留 | 两 locale privacy_url.txt / support_url.txt | 7-20d | **P0** |
| GP-12 | 技术 | **16KB 仍是配置级检查**: 0 构建产物可 objdump 验证, check_16kb_alignment.py 只查 ndkVersion 字符串 + targetSdk — R110 跨期残留 | scripts/check_16kb_alignment.py:40-46 / build/ 0 AAB | 4h (含首次 release build) | P1 |
| R111-1 | 权限 | **RECORD_AUDIO 权限 (R105 恢复) + ventAudioEnabled=true → Data Safety 表单必须申报 "Audio" 数据收集 (本地) + 权限声明理由**; 原 GP-9 的"6 权限集"已过时, 现 7 权限; 健康类 App 政策对心理 App 音频记录敏感, 理由必须写清"用户主动录制语音笔记, 仅本地加密存储, 不共享" | AndroidManifest.xml:48 / pubspec.yaml:36 (ventAudioEnabled=true) | 30min console | P1 |
| R111-2 | 技术 | **0 release 构建产物** → R8 shrink / desugar / 64-bit ABI / multidex 全链 0 真实验证; keystore 生成后首次 release build 冒烟 (含 16KB objdump) 是必修项, 预估可撞 2-5 个构建错误 | build/app/outputs/ 0 产物 | 0.5-1d | P1 |
| R111-3 | 权限 | safety_alert_builder `visibility: public` — R32 有意决策 (紧急 UX), title 已去 userName, 但 body 含"已 X 天未打卡" = 健康行为信息锁屏公开; 需法务/临床确认 or 改 private (1 行) | safety_alert_builder.dart:100 | 法务确认 或 1min 改 | P2 |
| GP-10 | 权限 | POST_NOTIFICATIONS 上下文请求 ✅ 但 Android 14+ 无 UI 重新授权入口 → 用户误拒后通知静默漂移 — R110 跨期残留 | notification_initializer.dart:122-173 | 2h | P2 |
| GP-17 | 技术 | 启动屏旧式 Theme.Light.NoTitleBar + 硬编码 #6BCF7F (非拒审项) — R110 跨期残留 | values/styles.xml:4 / launch_background.xml:4 | 1d | P3 |
| GP-18b | 元数据 | fastlane changelogs/ 缺失 (Play "what's new" 每版本必填, 上传 .aab 时要求) — R110 跨期残留 | fastlane/metadata/android/*/changelogs/ 不存在 | 15min | P1 |
| GP-18a | 技术 | BootReceiver.kt 死文件未注册 (v1.0 WorkManager 参考) — 半闭环, 残留风险 0 | manifest 注释 (AndroidManifest.xml:21-26) | 0 | ✅ |

## R110 跨期残留验证

| GP ID | R110 状态 | R111 实测 | 判定 |
|---|---|---|---|
| GP-1~3 | 未闭环 | 67B 截图 ×8 / 67B feature_graphic / 192×192 icon 全部原样 | ❌ 跨期残留 (资产 3-4d 设计师) |
| GP-5 | 未闭环 | short_description len=86 | ❌ 跨期残留 (5min) |
| GP-6 | 未闭环 (P1) | full_description 已中性化: "standardized questionnaires" 无 screening; 无 caregiver "stay connected" 文案; zh-CN 同步 (R110 round 2/3 已修) | ✅ 闭环 |
| GP-7 | 未闭环 | key.properties 缺失, 0 jks; signingConfig 已切 release (R97) | ❌ 跨期残留 (1h, 外部手动) |
| GP-8 | 半闭环 | label=@string/app_name ✅ + values-en ✅; supports-screens 0 声明 (非必需) | ✅ 代码侧闭环 |
| GP-9 | ✅ | 7 权限 (新增 RECORD_AUDIO, R105 有意恢复), 0 SMS 权限, exported 仅 launcher | ✅ 保持 |
| GP-10 | P2 建议 | 无重新授权 UI 未改 | ❌ 跨期残留 (P2) |
| GP-11 | 未闭环 | 2 个生成脚本存在, console 未填 | ❌ 跨期残留 (2-3h console) |
| GP-12 | 未闭环 | 配置级检查, 0 构建产物 | ❌ 跨期残留 (4h) |
| GP-13 | ✅ | targetSdk 36 / minSdk 24 / versionCode=140=pubspec=CHANGELOG 三者一致 | ✅ 闭环 |
| GP-14 | 未闭环 (P1) | badge_sync_service.dart:69 visibility: secret (R110 round 3 已修) | ✅ 闭环 |
| GP-15 | ✅ | title 静态 '💊 该吃药了' 无药名 (strings.dart:112-113); check_pii_in_title.py PASS | ✅ 闭环 |
| GP-16 | P2 | IAP 休眠 0 购买面 | ✅ 保持 |
| GP-18 | P3 | BootReceiver 未注册 ✅; changelogs 缺失 | ⚠️ 半闭环 (changelogs 残留) |

## 上架检查清单状态

```
硬阻塞 (P0, 7 项):   keystore (1h) + 截图 8 张 (1-2d) + feature_graphic (4h) + icon (4h) + short_description (5min) + Data Safety 3 表单 (2-3h) + privacy URL 域名 (7-20d)
代码侧闭环:           锁屏 PII 全闭环 (5 处 visibility + title 脱敏 + check_pii_in_title PASS)
                      20 守门员全绿 (16KB 配置级 PASS)
                      版本号三方一致 (0.32.0+140)
                      SMS 0 权限 / 6 外露功能全 FeatureFlag gate
待修 (P1):           RECORD_AUDIO 申报 (30min) + changelogs (15min) + 16KB 真实验证 (4h) + 首次 release build 冒烟 (0.5-1d)
待决策 (P2):         safety_alert public 锁屏 + POST_NOTIFICATIONS 重新授权 UI
```

## 总结

1) **不可提交** — 7 项硬阻塞全为外部依赖残留 (keystore 1h + 资产 3-4d 设计师 + 域名 7-20d + console 表单 2-3h), 代码侧 0 阻塞; 2) R110 round 3 的 4 项代码 P0 全闭环验证通过 (badge secret / PII / gates / 版本号); 3) **新增 R111-1**: RECORD_AUDIO 恢复后 Data Safety 表单必须申报 Audio — 这是本批唯一代码侧联动风险, 必须在填表单前意识到; 4) 首次 release build 冒烟 0 状态 — keystore 生成后第一件事; 5) 建议顺序: keystore (1h) → release build 冒烟 + 16KB objdump (1d) → short_description + changelogs (20min) → console 3 表单 (2-3h, 含 RECORD_AUDIO 申报) → 设计师资产 (并行 3-4d) → 域名 ICP (并行 7-20d)。
