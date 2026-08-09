# Google Play Store 视角报告 — review-round-105 (2026-08-09)

**评分**: 42/100 (R104 = 40/100, +2)
**基线**: R104 (2026-08-09, 68/100 综合)
**审查对象**: uncommitted batch — `android/app/build.gradle.kts`、`proguard-rules.pro`、`AndroidManifest.xml`、`launch_background.xml`、`gradle-wrapper.properties`、`fastlane/metadata/android/*`、`assets/legal/*`、`feature_flags.dart`
**审查方式**: 静态审查 (Data Safety Form / IARC 内容评级 / Health Apps 问卷 / App Signing 登记均为 Console 侧操作, 无法从仓库验证, 按"未完成"计)

---

## 一、本批 diff 速览 (新 / 残留 / 已修复)

| 项 | 本批改动 | 判定 |
|---|---|---|
| `build.gradle.kts` | +coreLibraryDesugaring (desugar_jdk_libs 2.1.4) | 已修复 (java.time 兼容, 合理) |
| `proguard-rules.pro` | +Google Play Core 3 条 dontwarn | 已修复 (R8 missing class) |
| `AndroidManifest.xml` | +tools 命名空间、+RECORD_AUDIO `tools:node="remove"`、+roundIcon、label 改 "ChronicCare"、**删除** `android:debuggable="false"` | ⚠️ 部分正确 (见 GP-7/GP-10/GP-11) |
| `launch_background.xml` | 默认色改绿 `#6BCF7F` | ⚠️ 见 GP-14 (v21 未同步) |
| `gradle-wrapper.properties` | **distributionUrl 从 https 改成 file:///C:/Users/... 本地路径** | ❌ 新回归 (GP-6) |
| `fastlane/metadata/android/*` | 描述删 "失联通知 (即将上线)" + 录音提及; **截图/feature_graphic 仍是 67 字节占位** | ⚠️ 描述已修复; 素材未修 (GP-1) |
| `assets/legal/*` | 联系方式改 privacy@chroniccare.app、删"草稿"标"定稿"、+§9.5、+录音不导出 | ⚠️ 域名未注册 (GP-4), 定稿标记过早 (GP-5) |
| `feature_flags.dart:70` | `_prodVentAudioEnabled = true` (R104 前 false) | ❌ 新回归 — 与 manifest 删 RECORD_AUDIO 矛盾 (GP-7) |
| 新文件 | 适配图标 (mipmap-anydpi-v26)、`medical_disclaimer.md` 接入 onboarding | 已修复 (GP-3 免责声明部分) |

---

## 二、问题清单

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|---|---|---|---|---|---|---|
| GP-1 (残留) | 全部 8 张 Android 截图 + 2 张 feature_graphic + icon 是 **67/1443 字节占位 PNG** — DEPLOYMENT §6.3 声称"真实截图保留", 实际未替换 (iOS 67B 占位 R93 已删, Android 漏了)。Play 上架必填截图, 占位图 = 审核拒 + 质量差 | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/*.png` + `feature_graphic.png` (67B) | 底层/素材 | 中 | P0 | 用真机截 4-6 张 (主页/打卡/用药日历/情绪/评估) + 1024×500 feature graphic + 512×512 icon; 参照 STOREFRONT_RELEASE_SOP §4 删占位 |
| GP-2 (残留) | Release keystore 未生成 (只有 key.properties.example); signingConfig 已切 release (R97), 无 key.properties 时 gradle 报 "Keystore file not set" 直接失败。上 store 前必须生成 | `android/key.properties` + `android/app/build.gradle.kts:91-95` | 底层/签名 | 简单 | P0 | 跑 `pwsh scripts/generate_release_keystore.ps1` → cp key.properties.example → 填真实值 → Play Console 启用 Play App Signing 上传 .aab |
| GP-3 (残留) | IARC 内容评级未配置 — 健康类 App 含危机热线/自杀相关内容, 需做 IARC 问卷 (Console → App content → Rating)。R104 起 3 轮未动 | Play Console (assets 无法验证) | 底层/合规 | 中 | P0 | 填 IARC 问卷 (年龄 12+ / 医疗主题), 提交后会自动通过 |
| GP-4 (残留) | `chroniccare.app` 域名 + `privacy@chroniccare.app` 邮箱未注册 — 本批反而把 legal 3 份文档的"软隐藏"改回真实邮箱 claim, 域名不存在 = 隐私政策 URL 指向未注册域名 + 联系邮箱不可达, Play 审核会因隐私政策 URL 无效拒 | `assets/legal/privacy_policy.md` §9 + `user_agreement.md` §8 | 底层/外部 | 中 | P0 | 先注册域名 + 邮箱 + 部署隐私页, 再回填 URL; 未注册前应保留"软隐藏"占位 (R96 策略) |
| GP-5 (残留) | 3 份法律文档未律师审核, 本批把修订历史"草稿"改成"定稿" — 状态与事实不符, 若 Play 审核抽查隐私政策/声明, "定稿"表述不成立; 律师过审是 PIPL §28 敏感数据处理的前提 | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 修订历史 | 底层/法务 | 高 | P0 | 律师过审后再标"定稿"; 当前建议回退"草稿 (待律师审核)"措辞 |
| GP-6 (新) | **gradle-wrapper distributionUrl 回归为本地路径** `file:///C:/Users/18449/.gradle/...gradle-8.13-bin.zip` — 原本是 `https://services.gradle.org/distributions/gradle-8.9-bin.zip`。换机器/CI/Google 上传环境直接下载失败; AGP 8.11.1 要求 Gradle ≥8.13, 8.9 也偏低。另仓库根有未跟踪 `.gradle-8.14-all.zip` (junk) | `android/gradle/wrapper/gradle-wrapper.properties:4` | 底层/构建 | 简单 | P1 | 改回 `https://services.gradle.org/distributions/gradle-8.13-bin.zip`; 删仓库根 `.gradle-8.14-all.zip`; 提交前跑 `flutter build appbundle --release` 验证 |
| GP-7 (新) | **音频功能状态 4 处矛盾**: (1) `FeatureFlags._prodVentAudioEnabled = true` (mic 按钮显示, vent_compose_page:455 / mood_recorder_page:375); (2) manifest 用 `tools:node="remove"` 强删 RECORD_AUDIO (注释仍写 "ventAudioEnabled=false", 过期); (3) 无任何 RECORD_AUDIO 运行时请求; (4) 描述/隐私政策仍声称"录音存本地"。结果 = Android 上 `_recorder.hasPermission()` 恒 false → 录音 100% 不可用, 用户点 mic 只弹 snackbar。若反向真接, 则必须重新声明 RECORD_AUDIO + 运行时请求 + Data Safety 声明麦克风 | `lib/core/data/feature_flags.dart:70` + `android/app/src/main/AndroidManifest.xml:51` + `lib/presentation/pages/vent/vent_compose_page.dart:196-205` | 底层/功能+权限 | 简单 | P1 | 二选一: (a) flag 翻回 false + 描述/隐私删所有"录音"字样 + 保持 remove; (b) 真接: manifest 恢复 RECORD_AUDIO + `permission_handler` 请求 + Data Safety 表单加 mic + 统一 4 处。禁止当前"半开半关"状态上架 |
| GP-8 (残留) | SCHEDULE_EXACT_ALARM 运行时检查缺失 — 代码用 `exactAllowWhileIdle` (reminder_dispatcher:118/160, snooze_manager:109), 但 `rescheduleAll` 入口无 `canScheduleExactAlarms()` 检查; Android 13+ 用户可撤销权限, 撤销后静默降级 inexact (~15min 延迟)。且 Play Console 权限声明 (Permissions declaration) 未填此权限 | `lib/core/data/services/notification_service.dart:313-325` (TODO) | 底层/权限 | 中 | P1 | 实现 P1-13 TODO: rescheduleAll 入口检查 + 引导到系统设置; 服药提醒属合法使用场景, Console 声明必勾 |
| GP-9 (残留) | Data Safety Form / Health Apps 问卷未填 (Console 侧) — 本 App 收集 10 类健康数据 (mood/sleep/weight/medication/assessment...), 必须声明 health data + encryption at rest (SQLCipher AES-256 ✓) + no transmission (✓) + 删除机制 (✓ 一键全删); 医疗类须过 Health Apps 问卷。表单 claim 必须与隐私政策一致 | Play Console (assets 无法验证) + `scripts/generate_data_safety_form.py` | 底层/合规 | 中 | P1 | 跑 `python scripts/generate_data_safety_form.py` 生成初稿, 人工对账后填 Console; 特别注意 GP-7 若恢复录音需加 mic 数据类别 |
| GP-10 (部分修复) | R104 G1 只修一半: label 从硬编码中文"慢病管家"改成硬编码英文"ChronicCare", 但 `values/strings.xml` + `values-en/strings.xml` 已有本地化 `@string/app_name` (zh=慢病管家 / en=ChronicCare), manifest 没用 = R85 本地化修复被架空, 中文设备桌面也显示 ChronicCare | `android/app/src/main/AndroidManifest.xml:54` + `values/strings.xml` | 底层/i18n | 简单 | P2 | `android:label="@string/app_name"`, 同步修正 R85 注释 (manifest:45 提到已用 @string, 实际没用) |
| GP-11 (新) | R63 加的 `android:debuggable="false"` 被本批删除 — 现仅靠 release buildType `isDebuggable=false` (build.gradle.kts:98)。若误传 debug 签名/未配 key.properties 时走了 debug fallback, 包可被反编译调试 | `android/app/src/main/AndroidManifest.xml:53-62` | 底层/安全 | 简单 | P2 | 恢复 manifest `android:debuggable="false"` (belt-and-suspenders, 防 R8/构建配置漂移) |
| GP-12 (新) | 新增 `android:roundIcon="@mipmap/ic_launcher_round"` + mipmap-anydpi-v26 适配图标, 但 raster mipmap-{mdpi..xxxhdpi} 只有 `ic_launcher.png`, **缺 `ic_launcher_round.png`** — minSdk=24, API 24/25 设备 (非适配图标) roundIcon 解析失败 → 回退普通图标 | `android/app/src/main/AndroidManifest.xml:57` + `android/app/src/main/res/mipmap-*/` | 底层/资源 | 简单 | P2 | 生成 pre-26 raster `ic_launcher_round.png` (或用 flutter_launcher_icons 重生成全密度) |
| GP-13 (已修复) | R104 G8 RECORD_AUDIO `tools:node="remove"` 已落地 — record/speech_to_text 插件不再合并麦克风权限, 满足"无录音业务不暴露 mic 权限"的 Play 政策 | `android/app/src/main/AndroidManifest.xml:51` | 底层/权限 | 简单 | — | 保持; 但注意与 GP-7 冲突, 若走真接方向需同步撤销 |
| GP-14 (新) | launch_background 默认 drawable 改绿 `#6BCF7F`, 但 `drawable-v21/launch_background.xml` 仍是 `?android:colorBackground` — 实际所有设备 (API≥21) 走 v21 分支, 绿色 splash 永不生效; 且 `ic_launcher_background.xml` 绿色 `#6BCF7F` 与 launch 背景不匹配 | `android/app/src/main/res/drawable/launch_background.xml:4` + `drawable-v21/launch_background.xml:5` | 底层/UI | 简单 | P3 | v21 分支同步 `#6BCF7F` (或统一抽 color resource) |
| GP-15 (新) | 16KB 脚本 WARN: `ndkVersion = flutter.ndkVersion` 隐式 — Flutter 升级时 16KB 对齐依赖默认值漂移。脚本本身 [OK] (targetSdk=36 ≥35, Play 2025-11 强制 16KB 已满足) | `android/app/build.gradle.kts:13` | 底层/构建 | 简单 | P3 | 显式 pin `ndkVersion = "27.0.12077973"`; 上线前跑 `bundletool validate --bundle=...aab` 真验 |
| GP-16 (残留) | proguard 缺 `permission_handler` keep 规则 (`com.baseflow.permissionhandler.**`) — permission_handler 已装 (pubspec:39) 但 lib/ 内 0 调用, R8 开 minify 时若未来启用会混淆 crash; 当前无影响 | `android/app/proguard-rules.pro` | 底层/构建 | 简单 | P3 | 加 keep 规则, 或从 pubspec 移除死依赖 (permission_handler / speech_to_text 若 GP-7 走关闭方向) |

---

## 三、已确认 OK (无需动作)

- **targetSdk=36 / minSdk=24** — 满足 2026 Play target API 要求 (build.gradle.kts:34-35)
- **64-bit ABI** 显式 `arm64-v8a + x86_64` (build.gradle.kts:110-112)
- **Signing**: release signingConfig 已切 (R97); fastlane 走 `bundleRelease` 产出 .aab (`skip_upload_apk: true`)
- **16KB page size**: `check_16kb_alignment.py` 通过 (`targetSdk = 36 >= 35, OK`), 仅 ndkVersion 建议 pin
- **POST_NOTIFICATIONS**: 声明 + 运行时 `requestPermission()` 存在且从 init() 移除 (notification_service.dart:199, R97-P1-6), context 内请求 ✓
- **USE_EXACT_ALARM**: 已删除 (R97) — 不再触碰 Play 2024-07 对 alarm-clock 类 App 的限制 ✓
- **INTERNET / WAKE_LOCK / VIBRATE**: 均有正当用途 (in_app_purchase 隐式 / 通知唤醒 / 震动)
- **allowBackup=false** + fullBackupContent/dataExtractionRules 排除 DB/secure_storage/audio ✓
- **cleartext 禁用**: network_security_config `<base-config cleartextTrafficPermitted="false">` ✓
- **exported 组件**: 仅 MainActivity (launcher); BootReceiver 注册已删 ✓
- **医学免责声明**: `medical_disclaimer.md` 新文件 + 已接入 onboarding 同意流程 (setup_page_state.dart:181-182) ✓ (Health Apps 政策合规 +1)
- **metadata 描述**不再提及已禁用功能 (失联通知/录音已删) — 除录音残留字样 (见 GP-7) ✓
- **适配图标**: mipmap-anydpi-v26 新建 (background 绿 + foreground 胶囊/爱心) ✓

---

## 四、评分

**42/100** (R104: 40/100)

| 维度 | 得分/说明 |
|---|---|
| 权限清单合理性 (Manifest) | +5: 5 权限全合理, USE_EXACT_ALARM 已删, RECORD_AUDIO remove; -3: GP-7 音频半开半关 |
| 构建/签名 (targetSdk / keystore / wrapper) | +4: targetSdk36/64-bit/16KB/release signing; -6: GP-6 wrapper 本地路径, GP-2 keystore 未生成 |
| 内容评级 / 健康类政策 | +2: 免责声明接入 onboarding; -4: IARC 未填, Health Apps 问卷未填 |
| Data Safety / 隐私 | +2: 零云端+加密+删除机制齐全; -4: 表单未填, 域名/邮箱未注册, 录音状态矛盾 |
| 上架物料 (描述/截图/图标) | +3: 描述清理已禁用功能, 适配图标; -5: 截图/feature_graphic 67B 占位 |
| 隐私备份/cleartext/exported | +5: allowBackup=false + 排除规则 + cleartext 禁用 + 仅 launcher exported 全达标 |

**总结**: 本批在"描述清理 / 免责声明 / 适配图标 / desugaring / proguard Play Core"上有实质进展, 但引入 2 个 P1 级新回归 (gradle-wrapper 本地路径、音频功能 4 处矛盾), 且 P0 级阻塞全部未动 (截图占位、keystore、IARC、域名、法务、Data Safety Form)。**上架路径**: 先修 GP-6/GP-7 两个新回归并保持 CI 绿, 再逐项清 P0 (截真实素材 → 注册域名/邮箱 → 生成 keystore → 填 Console 4 表单 → IARC → 律师过审)。

**Console 侧无法从仓库验证 (需人工)**: Data Safety Form、IARC 问卷、Health Apps 问卷、Permissions declaration、Play App Signing 登记、隐私政策 URL 有效性。
