# Google Play 上架合规视角审视报告 — 2026-08-13 R112

## 0. 元数据

- 视角: Google Play Policy + 上架资产 (05)
- 审视者: googleplay-subagent
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M + 13 untracked (R112 hotfix 进行中)
- 范围: `fastlane/metadata/android/` (全 24 文件逐字读 + 尺寸实测) / `android/` (manifest、build.gradle.kts、gradle-wrapper、res、xml、key.properties) / `scripts/check_16kb_alignment.py`、`generate_data_safety_form.py`、`generate_health_apps_questionnaire.py` / 通知 visibility 全链路 (`lib/core/data/services/` 11 处 grep) / `lib/core/data/feature_flags.dart` / `lib/core/l10n/strings.dart` / `lib/domain/logic/scale_registry.dart` + `lib/presentation/pages/assessment/assessment_center_page.dart` / `docs/CHANGELOG.md`、`docs/PLAYSTORE_SIGNING_GUIDE.md` / 守门员实测 (`check_pii_in_title.py`、`check_16kb_alignment.py`、`check_review_information_todo.py`)

## 1. 整体评分 (0-10)

**6.0 / 10** — R111 遗留 3 项元数据 P0 在 working tree 已修 (short_description 86→71 字符 / changelogs 已补 / GP-10 通知重授权 UI), 但 5 项硬阻塞 (keystore + 3 类资产 + 域名 + console 表单) 原样残留; 新增 4 项 P1 (商店文案与实际量表 gate 不符 / gradle wrapper 机器路径 / 2 个 console 表单生成器过期且缺 Audio 申报)。代码侧合规姿态持续强 (6 权限最小集、5 处通知 visibility、0 广告/埋点、16KB 配置级 PASS)。

## 2. 关键发现

### P0 (必修, 阻塞上架)

- [架构] **[GP-1] 8 张 phone_screenshots 仍 67B 空白占位** — 难度:M — 工作量:设计师 1-2d (外部)
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (ls 实测各 67B, `file` 显示 1232×720 RGBA 但 IDAT 空)
  - 现状: R110→R111→R112 连续 3 期跨期残留, 尺寸合法内容空, Play Console 上传即拒
  - 建议: 走 `scripts/generate_android_screenshots.sh` (已存在) 或设计师真机截图, 每 locale ≥4 张

- [架构] **[GP-2] feature_graphic 仍 67B 空白** — 难度:M — 工作量:设计师 4h (外部)
  - 位置: 两 locale `feature_graphic.png` (1024×500, 67B)
  - 现状: 跨期残留 100%
  - 建议: 同上, Play 商店页横幅必填

- [架构] **[GP-3] icon 仍 192×192 8-bit colormap 默认图 + mipmap 全为 Flutter 模板占位** — 难度:M — 工作量:设计师 4h (外部)
  - 位置: `fastlane/metadata/android/*/icon.png` (1443B, 192×192, Play 要求 512×512 32-bit) / `android/app/src/main/res/mipmap-*/ic_launcher.png` (72/48/96/144/192, 默认 Flutter 蓝底)
  - 现状: 跨期残留; 512×512 是硬性上传门槛, 当前文件会被 Console 直接拒
  - 建议: 生成 512×512 源 + adaptive icon foreground/background 替换

- [架构] **[GP-7] keystore 仍未生成** — 难度:S — 工作量:1h (外部手动)
  - 位置: `android/key.properties` 不存在 (仅 `key.properties.example`), 全仓库 0 jks; signingConfig 已切 release (`android/app/build.gradle.kts:91-95`)
  - 现状: 首次 `flutter build appbundle --release` 必报 "Keystore file not set"; `scripts/generate_android_keystore.sh` 就绪未执行
  - 建议: 按 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步生成 → 备份到 1Password → Play App Signing

- [架构] **[E5/GP-URL] privacy/support/删除端点 URL 指向未注册域名** — 难度:S — 工作量:7-20d ICP (外部)
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` + `support_url.txt` (`https://chroniccare.app/privacy` / `/support`) / `scripts/generate_data_safety_form.py:85` (删除端点 `/delete-data-instructions`)
  - 现状: 域名 chroniccare.app 未注册/无 ICP, URL 404 → Data Safety 表单保存会被拒 (隐私政策 URL 必须可达)
  - 建议: 并行启动 ICP; 短期可先挂 GitHub Pages 等免费 HTTPS 静态页

- [架构] **[GP-11] Data Safety + Health Apps + Exact Alarm 3 表单 0 提交** — 难度:S — 工作量:2-3h console (外部)
  - 位置: `scripts/generate_data_safety_form.py` / `generate_health_apps_questionnaire.py` 输出 `build/` 0 产物
  - 现状: 生成器存在但从未跑过 (build/ 不存在), console 侧 0 记录
  - 建议: 填表前必须先修 GP-R112-03/04 (生成器内容过期, 否则照抄 = 虚假申报)

### P1 (应修)

- [架构] **[GP-R112-01] 商店文案与线上实际量表 gate 不符: "two widely-recognized standardized questionnaires" 指 PHQ-9/GAD-7, 而 prod 下两者被 FeatureFlag 隐藏, 实际露出的是另外 8 个量表** — 难度:S — 工作量:30min
  - 位置: `fastlane/metadata/android/en-US/full_description.txt:17` + `zh-CN/full_description.txt:18` vs `lib/presentation/pages/assessment/assessment_center_page.dart:47-49` (phqGad7I18nEnabled=false → 过滤 phq9/gad7) + `lib/domain/logic/scale_registry.dart:29-43` (10 量表, prod 露 8: ISI/PSS/WHODAS/level2×4/ASRM)
  - 现状: 文案声称的"两种广泛使用的问卷"恰好是被 gate 隐藏的那两种; AS-17 中性化只改了 iOS description, Android full_description 未同步。Play "misleading description" 风险 + 若评审员实测发现描述不符可直接拒
  - 建议: 改成 "a set of standardized self-assessment scales / 内置多种标准化自我评估量表" (不点名), 或翻 phqGad7I18nEnabled 后再写死名称

- [底层] **[GP-R112-02] gradle-wrapper.properties 提交了机器专属 Windows 路径 + wrapper 三件套被 .gitignore 排除 → 干净机器/CI release build 必断** — 难度:S — 工作量:15min
  - 位置: `android/gradle/wrapper/gradle-wrapper.properties:4` (`distributionUrl=file:///C:/Users/18449/.gradle/wrapper/dists/gradle-8.13-bin/gradle-8.13-bin.zip`, 自 v0.27 round 63 起在 master) + `android/.gitignore:1-4` (ignores `gradle-wrapper.jar` / `gradlew` / `gradlew.bat`) + `git ls-files android/` 实测 wrapper jar 未入库
  - 现状: 本机 .gradle 缓存掩盖了问题; 换机 clone 后既无 wrapper 脚本, 唯一被跟踪的 properties 又指向 Windows 本地 file:// URL → release 构建链不可复现 (keystore 修好后第一脚就会踩)
  - 建议: distributionUrl 改 `https\://services.gradle.org/distributions/gradle-8.13-bin.zip`; .gitignore 放行 gradlew/gradlew.bat/gradle-wrapper.jar (Flutter 官方模板默认入库)

- [架构] **[GP-R112-03] Data Safety 生成器过期 3 处: 缺 Audio 数据型 (R111-1 未闭环) / 量表名错误 / 电话号过度申报** — 难度:S — 工作量:30min
  - 位置: `scripts/generate_data_safety_form.py:65-79` (health 段: PHQ-9/GAD-7 且 audio 只藏在 mood 子类描述里, 无独立 "Audio files" 数据型) / `:135-142` (personal_info 声明收集手机号, 但 `lib/core/data/feature_flags.dart:48` emergencyContactEnabled=false + R110 round 3 gate → prod 根本不收集) / `:31-35` (版本正则 `v0\.27\.0\+\d+` → 恒返回 unknown)
  - 现状: ventAudioEnabled=true (`feature_flags.dart:70`) + manifest `RECORD_AUDIO` (`AndroidManifest.xml:48`) → Audio 是真实收集的数据型, Play Data Safety 必须单列 "Audio files" (Photos and videos or audio 大类); 照抄现生成器 = 漏报 Audio + 误报量表 + 误报手机号, 三面不符
  - 建议: health_info 加 Audio files 子类 + 修量表描述 (去 PHQ-9/GAD-7 名, 写 "self-assessment scales") + personal_info 改 "未收集 (功能停用, v1.0 翻 flag 后更新)" + 修版本正则

- [架构] **[GP-R112-04] Health Apps 问卷生成器过期: app_version 硬编码 0.30.0+85 + 宣称含 PHQ-9/GAD-7 (prod 隐藏) + 0 录音声明** — 难度:S — 工作量:30min
  - 位置: `scripts/generate_health_apps_questionnaire.py:133` (`"app_version": "0.30.0+85"`) / `:33-35` (disclosure 声称 "The app includes PHQ-9 ... and GAD-7") / 全文件 grep 无 audio/录音
  - 现状: 精神健康 App 在 Play 2024+ 政策下必填 Health Apps 问卷; 现生成器内容与 gate 后实际功能不符, 照抄即虚假声明; 且缺失"语音笔记为本地加密、不用于任何诊断/共享"声明 (心理类 App 音频敏感, 问卷被抽审概率高)
  - 建议: 版本号改读 pubspec; disclosure 与 GP-R112-01 同步改通用量表措辞; 补 1 条 audio disclosure; 与 GP-R112-03 一并修

- [架构] **[GP-R112-05] Exact Alarm 申报 + 理由文案未准备 (SCHEDULE_EXACT_ALARM 政策灰区)** — 难度:S — 工作量:2h console + 决策
  - 位置: `android/app/src/main/AndroidManifest.xml:42` (SCHEDULE_EXACT_ALARM) / `lib/core/data/services/reminder_dispatcher.dart:149-153,195-199` (canScheduleExactAlarms 检查 + inexact 兜底已闭环 R108 P0#2 ✅)
  - 现状: Play Console "Exact alarm" 申报表单必填; 服药提醒不在默认豁免名单 (alarm/calendar/timer), 需以 "core functionality = 定时服药依从性提醒" 理由申报, 存在被驳回风险; 技术侧 Android 14+ 默认拒绝 + inexact 兜底已就绪, 被驳回可降级
  - 建议: 先准备申报文案 (临床按时用药场景); 被驳回则删权限走 inexact (代码零改动)

- [架构] **[GP-R112-06] Permissions Declaration (麦克风) 声明文案缺失** — 难度:S — 工作量:15min console
  - 位置: `android/app/src/main/AndroidManifest.xml:48` (RECORD_AUDIO) — 无任何生成脚本覆盖 Permissions Declaration 表单 (仅 Data Safety/Health Apps 有)
  - 现状: Play 要求对 Microphone 权限提交 "video/audio statement"; 未备文案, 填表时会卡
  - 建议: 写 "用户主动录制的语音笔记仅本地加密存储, 不共享不用于广告" + 截图指向录音入口

### P2 (可修)

- [底层] **[R111-3] safety_alert 通知 `visibility: public` 锁屏公开 "已 X 天未打卡"** — 难度:S — 工作量:法务确认 或 1min 改
  - 位置: `lib/core/data/services/safety_alert_builder.dart:89-96` (public, R32 有意决策; working tree 已删 userName 死参数, title 静态无名字 ✅)
  - 现状: body 含健康行为信息锁屏可见; 其余 4 处 dispatcher 全 secret (`reminder_dispatcher.dart:116` / `snooze_manager.dart:100` / `badge_sync_service.dart:69` / `notification_service.dart:242`)
  - 建议: 法务/临床签批 or 改 `NotificationVisibility.private` (仅红点提醒, 内容解锁见)

- [架构] **[GP-R112-07] check_16kb_alignment.py 假阳性 "[OK] 显式 ndkVersion"** — 难度:S — 工作量:15min
  - 位置: `scripts/check_16kb_alignment.py:40-46` vs `android/app/build.gradle.kts:13` (`ndkVersion = flutter.ndkVersion` — 属性引用非 pin 值)
  - 现状: 脚本把属性引用判成"显式声明", 实际版本随 flutter.ndkVersion 漂移; 16KB 仍 100% 配置级 (0 AAB 产物, 无 objdump 实测)
  - 建议: 脚本改为识别 `flutter.ndkVersion` 引用并 WARN; 或直接 pin `ndkVersion = "27.0.12077973"` (与 GP-12 一起在首次 release build 后 objdump 验证)

- [架构] **[R111-2] 0 release 构建产物 → R8/shrink/desugar/64-bit/multidex 全链 0 真实验证** — 难度:M — 工作量:0.5-1d
  - 位置: `build/` 不存在; `android/app/build.gradle.kts:98-113` (R8+shrink+64-bit ABI+desugar 2.1.4+multidex 配置齐全但未跑过)
  - 现状: keystore 生成后首次 release build 冒烟是必修项, 预估撞 2-5 个构建错误 (R8 keep rules 风险最高)
  - 建议: keystore → `flutter build appbundle --release` → unzip 验 .so + objdump LOAD 16KB → 装 AAB 冒烟

- [底层] **[GP-10 已闭环 ✅] Android 14+ 通知权限拒绝后重新授权 UI** — 位置: CHANGELOG 0.32.0+142 (`openAppSettings` + `test/presentation/notification_status_card_permission_round8_test.dart` 3 test, untracked 待 commit) — 验证方式: 测试文件存在 + CHANGELOG 记录, 代码实读未单独复核 UI 文件, 建议主 agent 收口时复验

### P3 (建议)

- [底层] **[GP-17] 启动屏旧式 `Theme.Light.NoTitleBar` + 硬编码 #6BCF7F** — 位置: `android/app/src/main/res/values/styles.xml:4` / `drawable/launch_background.xml` — 非拒审项, Android 12+ 官方 SplashScreen API 更优
- [架构] **[GP-R112-08] android/.gitignore 排除 gradlew 系列 (与 GP-R112-02 同源)** — Flutter 官方模板 wrapper 三件套应入库; 若已修 GP-R112-02 此项自动消解
- [架构] **[GP-4] 0 tablet 截图 + 0 `<supports-screens>` 声明** — Play 不强制, 平板占比低可延后

## 3. 外部链接 / 域名 / 邮箱 / URL 检查

| 位置 | 内容 | 状态 |
|---|---|---|
| `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` | https://chroniccare.app/privacy | 占位符 (域名未注册) |
| `fastlane/metadata/android/{en-US,zh-CN}/support_url.txt` | https://chroniccare.app/support | 占位符 (域名未注册) |
| `scripts/generate_data_safety_form.py:85` | https://chroniccare.app/delete-data-instructions | 占位符 (域名未注册) |
| `fastlane/metadata/android/en-US/full_description.txt` | findahelpline.com + 3 热线 (988 / 116 123 / 400-161-9995) | 合法公开资源 ✅ |
| `fastlane/metadata/android/zh-CN/full_description.txt` | 4 条中国热线 + findahelpline.com | 合法公开资源 ✅ |
| lib/ + android/ | 0 广告 SDK / 0 埋点域名 (pubspec 37 依赖 grep firebase/admob/analytics 全空) | ✅ 干净 |
| android/res/xml/network_security_config.xml | cleartextTrafficPermitted=false | ✅ 全 HTTPS |

## 4. 四类问题 (用户点名)

### 4.1 上架相关

- 硬阻塞 5 项不变 (keystore 1h + 资产 2-3d + 域名 ICP 7-20d + console 3 表单), 全部外部依赖; 本批代码侧 0 新阻塞
- **R112 元数据收口实际进展 (working tree)**: GP-5 short_description en 86→71 字符 ✅ / GP-18b changelogs en+zh 已写 (untracked, 需 commit) ✅ / GP-10 重授权 UI ✅ / AS-17 中性化仅 iOS 三语, **Android full_description 漏改** → GP-R112-01
- 权限姿态: 6 权限最小集 (INTERNET iap 隐式 / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE / RECORD_AUDIO); 0 SEND_SMS (Aliyun SMS 为服务端方案, manifest 无多余声明 ✅ 验证通过); 0 USE_EXACT_ALARM (R97 正确移除, Play 受限权限) ✅; 0 RECEIVE_BOOT_COMPLETED (bootReceiverEnabled=false, BootReceiver.kt 未注册死文件) ✅
- 锁屏 PII: 5 处 visibility — 4 secret + 1 public (safety alert, 有意, 待法务); `python scripts/check_pii_in_title.py` 实测 PASS; title 全部静态无药名/无姓名 (`lib/core/l10n/strings.dart:112-117`)
- 版本三方一致: pubspec 0.32.0+142 = CHANGELOG = notes.txt (check_review_information_todo.py 实测 OK)
- 16KB: 仍配置级 (ndkVersion 未 pin, 0 产物) — 首次 release build 后必须 objdump

### 4.2 架构相关

- 两个 console 表单生成器 (R72/R108) 已与业务 gate 脱节 (量表名单、Audio、电话号、版本号 4 处) — 生成器属于"配置即文档"资产, 建议接入守门员或 CI 定期重跑比对
- FeatureFlag → 商店文案的联动没有任何自动化: phqGad7I18nEnabled / emergencyContactEnabled / ventAudioEnabled 3 个 flag 直接影响 Data Safety/Health Apps/描述文案, flag 翻转时无提醒机制 (R105 恢复 RECORD_AUDIO 就是前车之鉴)

### 4.3 重构建议

- `scripts/check_16kb_alignment.py` 与 `build.gradle.kts` 双端 pin NDK 版本 (消除 flutter.ndkVersion 漂移)
- 表单生成器统一从 `feature_flags.dart` + `scale_registry.dart` 读取 prod 真实状态生成 (而非手写字符串), 一劳永逸消 GP-R112-03/04 类问题

### 4.4 半成品 / TODO / 残缺功能

- `scale_registry.dart:40-42` TODO (nsesss/crdpss 收费量表) — 已标 unavailable 灰卡 ✅ 不影响上架
- `BootReceiver.kt` 死文件 (v1.0 WorkManager 参考) — 无注册无风险 ✅
- gradle wrapper 三件套 2/3 未入库 (GP-R112-02) — 唯一真"残缺"
- changelogs 已在 working tree 但 untracked — R112 commit 时务必带上

## 5. 总结 + 给整合者的建议

1) **不可提交** — 5 项硬阻塞 100% 外部依赖, 与 R111 完全一致 (keystore 1h → 资产 2-3d 设计师 → 域名 ICP 7-20d → console 表单 2-3h); 代码侧合规姿态继续保持强 (6 权限最小集、4/5 secret、0 广告埋点、0 SEND_SMS、16KB 配置 PASS、22 守门员中 3 个 Play 相关全绿)
2) **R112 元数据收口 3/4 达成**: short_description ✅ + changelogs ✅ (待 commit) + GP-10 ✅; 唯一漏项 = Android full_description 没跟 AS-17 中性化 (GP-R112-01, 且与 phqGad7I18nEnabled gate 叠加成"描述点名被隐藏的量表"双重失真, 是本批唯一有拒审风险的新发现)
3) **GP-R112-02 (gradle wrapper 机器路径) 建议本周内修** — 1 行 distributionUrl + .gitignore 3 行, 否则 keystore 生成后的首次 release build 会在换机/CI 场景翻车, 且当前无人能在干净环境复现构建
4) **填 console 表单前必须先跑一轮生成器刷新** (GP-R112-03/04): 现生成器照抄 = 漏报 Audio + 误报量表 + 误报手机号三连, 比不填更糟
5) 建议顺序: wrapper 修复 (15min) → keystore (1h) → 首次 release build 冒烟 + 16KB objdump (1d) → full_description 中性化 + 2 生成器刷新 (1h) → console 3 表单 (2-3h) → 设计师资产 (并行 2-3d) → 域名 ICP (并行 7-20d)

## 附录: 详细证据

### A. 资产实测 (ls -la + file)

```
fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png: 各 67B (1232×720 RGBA, IDAT 空)
fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png: 各 67B (1024×500)
fastlane/metadata/android/{en-US,zh-CN}/icon.png: 各 1443B (192×192, 8-bit colormap; Play 要求 512×512 32-bit)
android/app/src/main/res/mipmap-{m,h,x,xx,xxx}dpi/ic_launcher.png: 442~1443B (48/72/96/144/192, Flutter 默认模板)
android/key.properties: 不存在 (仅 key.properties.example); 0 *.jks
android/gradle/wrapper/gradle-wrapper.properties:4 = file:///C:/Users/18449/.gradle/wrapper/dists/gradle-8.13-bin/gradle-8.13-bin.zip (git log 显示 dce8c52 v0.27 R63 起)
git ls-files android/ → 无 gradlew / gradlew.bat / gradle-wrapper.jar (android/.gitignore:1-4 排除)
```

### B. 元数据实测 (wc -c)

```
en-US/short_description.txt = 71B (≤80 ✅, R112 从 86 修)
zh-CN/short_description.txt = 48B ✅
en-US/title.txt = 26 字符 ✅ (<30)
zh-CN/title.txt = 18 字符 ✅
changelogs: en 415B / zh 332B (untracked 待 commit)
full_description: en 2380B / zh 1763B (远低于 4000 上限)
```

### C. 权限清单 (AndroidManifest.xml:40-48)

INTERNET(iap 插件隐式) / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE / RECORD_AUDIO(R105 恢复)。0 SEND_SMS ✅ 0 USE_EXACT_ALARM ✅ 0 RECEIVE_BOOT_COMPLETED ✅ exported 仅 MainActivity ✅ allowBackup=false ✅ cleartext 禁 ✅ backup_rules/data_extraction_rules 排除 DB+audio ✅

### D. 通知 visibility 5 处 (grep 实测)

secret ×4: reminder_dispatcher.dart:116 / snooze_manager.dart:100 / badge_sync_service.dart:69 / notification_service.dart:242
public ×1: safety_alert_builder.dart:96 (R32 有意决策, body 含 "已 X 天未打卡"; working tree 已删 userName 死参数)

### E. FeatureFlag prod 实读 (lib/core/data/feature_flags.dart)

ventAudioEnabled=**true** (line 70) / emergencyContactEnabled=false (48) / aliyunSmsEnabled=false (59) / iapEnabled=false (51) / phqGad7I18nEnabled=false (52) / bootReceiverEnabled=false (56) / emailServiceEnabled=false (62) / fiveVendorPushEnabled=false (66)

### F. 量表 gate 证据

scale_registry.dart:29-43 注册 10 量表 (phq9/gad7/isi/pss/whodas/level2Depression/level2Anxiety/level2Mania/asrm/level2Psychosis)
assessment_center_page.dart:47-49: `phqGad7I18nEnabled ? all : all.where(id != 'phq9' && id != 'gad7')` → prod 露 8, 隐藏的恰是文案点名的 2 个

### G. 守门员实测 (exit=0)

check_pii_in_title.py ✅ / check_16kb_alignment.py ✅ (但含假阳性 [OK] 显式 ndkVersion, 见 GP-R112-07) / check_review_information_todo.py ✅ (iOS review_info 3 个外部依赖 warn 属预期)

<!-- subagent: googleplay-subagent 完成时间: 2026-08-13T19:20:00+08:00 -->
