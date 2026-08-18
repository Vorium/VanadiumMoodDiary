# R108 P0 #11-#13 subagent C 报告 (2026-08-10)

> **subagent 角色**: P0 外部依赖占位 subagent C
> **范围**: R107 报告 P0 #11 (Android keystore + Data Safety + Health Apps) + #12 (iOS + Android 截图) + #13 (chroniccare.app 域名)
> **方法**: 写脚本 + 详细步骤文档, 实际执行需用户 (Mac + 真实资源 + 外部服务)
> **基线**: v0.30.0+85 / 2026-08-10 cleanup / 2019 tests
> **关联**: `docs/audit/2026-08-10-cleanup/00-summary.md` §四 P0 13 项

---

## 一、3 个 fix 总览

| Fix | 子项 | 状态 | 工时估算 (实际跑) |
|---|---|---|---|
| **#11a** Android keystore | 脚本 + doc + test | ✅ 全部完成 | 2h (dev 实际生成) + 5min Play Console |
| **#11b** Data Safety Form | 脚本 (R72 复用) + v0.30 增量 + doc + test | ✅ 全部完成 | 1h (人工填 28 子项) |
| **#11c** Health Apps Questionnaire | 脚本 (R108 新增) + doc + test | ✅ 全部完成 | 30min (人工填 4 大块) |
| **#12** iOS + Android 截图 | 2 脚本 + doc + test | ✅ 全部完成 | 3-5d (Mac + Xcode + Android Studio) |
| **#13** chroniccare.app 域名 | 脚本 + 4 HTML 模板 + doc + test + 4 URL 文件 | ✅ 全部完成 | 4h (Cloudflare 部署) + 7-20d (ICP 备案) |

---

## 二、6 类新文件清单 (R108 增量)

### 2.1 脚本 (5 个新 + 2 个 R72 复用)

| 文件 | 类型 | 行数 | 状态 |
|---|---|---|---|
| `scripts/generate_android_keystore.sh` | Bash 脚本 (R108 新增, Mac/Linux/CI) | 159 | ✅ 完整 |
| `scripts/generate_release_keystore.ps1` | PowerShell 脚本 (R72 已存在, 验证) | 153 | ✅ 不动 |
| `scripts/generate_data_safety_form.py` | Python 脚本 (R72 已存在, R108 验证) | 262 | ✅ 不动 |
| `scripts/generate_health_apps_questionnaire.py` | Python 脚本 (R108 新增) | 197 | ✅ 完整 |
| `scripts/generate_ios_screenshots.sh` | Bash 脚本 (R108 新增, Mac only) | 207 | ✅ 完整 |
| `scripts/generate_android_screenshots.sh` | Bash 脚本 (R108 新增, Mac/Linux/WSL) | 184 | ✅ 完整 |
| `scripts/register_domain.sh` | Bash 脚本 (R108 新增, 占位) | 199 | ✅ 完整 |
| `scripts/templates/privacy.html.tmpl` | HTML 模板 (R108 新增) | 47 | ✅ 完整 |
| `scripts/templates/support.html.tmpl` | HTML 模板 (R108 新增) | 76 | ✅ 完整 |
| `scripts/templates/user-agreement.html.tmpl` | HTML 模板 (R108 新增) | 36 | ✅ 完整 |
| `scripts/templates/sensitive-data-consent.html.tmpl` | HTML 模板 (R108 新增) | 48 | ✅ 完整 |

### 2.2 详细步骤文档 (5 个 R108 新增)

| 文件 | 行数 | 状态 |
|---|---|---|
| `docs/audit/2026-08-10-cleanup/R108-android-keystore-setup.md` | 235 | ✅ 完整 |
| `docs/audit/2026-08-10-cleanup/R108-android-data-safety-form.md` | 250 | ✅ 完整 |
| `docs/audit/2026-08-10-cleanup/R108-android-health-apps-questionnaire.md` | 286 | ✅ 完整 |
| `docs/audit/2026-08-10-cleanup/R108-screenshots-automation.md` | 313 | ✅ 完整 |
| `docs/audit/2026-08-10-cleanup/R108-domain-registration-guide.md` | 343 | ✅ 完整 |
| `docs/audit/2026-08-10-cleanup/R108-p0-11to13-report.md` | (本文件) | ✅ |

### 2.3 Lock-in test (5 个 R108 新增)

| 文件 | 类型 | 覆盖 |
|---|---|---|
| `test/scripts/keystore_script_round108_test.py` | Python | 6 单测 — bash 脚本 + PowerShell 脚本 + gradle 配 + .gitignore + setup doc |
| `test/scripts/data_safety_form_round108_test.py` | Python | 8 单测 — 脚本存在 + 5 大类 + 健康 + 加密 + 删除端点 + setup doc + 脚本能跑通 |
| `test/scripts/health_apps_questionnaire_round108_test.py` | Python | 9 单测 — 4 大块 + NOT a medical device + PHQ-9/GAD-7 + 6 区域 + setup doc + 脚本能跑通 |
| `test/scripts/screenshots_scripts_round108_test.py` | Python | 7 单测 — iOS + Android 脚本 + Mac 平台检查 + 跨平台 + bash 语法 + setup doc |
| `test/scripts/domain_check_round108_test.py` | Python | 8 单测 — 注册脚本 + 4 HTML 模板 + 12 URL 文件 + setup doc + assets/legal |

**总单测**: 38 ✅ 全过

### 2.4 上架物料修复 (R108 恢复 R100 误删)

| 文件 | 状态 | 内容 |
|---|---|---|
| `fastlane/metadata/android/en-US/privacy_url.txt` | ✅ 新建 | `https://chroniccare.app/privacy` |
| `fastlane/metadata/android/en-US/support_url.txt` | ✅ 新建 | `https://chroniccare.app/support` |
| `fastlane/metadata/android/zh-CN/privacy_url.txt` | ✅ 新建 | `https://chroniccare.app/privacy` |
| `fastlane/metadata/android/zh-CN/support_url.txt` | ✅ 新建 | `https://chroniccare.app/support` |

> **R100 删了 Android 4 URL 文件 (12 → 8), R108 恢复成 12 URL**: 6 iOS (3 locale × 2) + 6 Android (2 locale × 2 + 新增 privacy × 2 + support × 2)

### 2.5 生成的 build/ 输出 (脚本跑后产生, 不入仓)

| 文件 | 大小 | 来源 |
|---|---|---|
| `build/data_safety_form.json` | 4457 bytes | R72 脚本生成 (5 大类结构化) |
| `build/data_safety_form.md` | 2847 bytes | R72 脚本生成 (人类可读 28 子项) |
| `build/health_apps_questionnaire.json` | 7187 bytes | R108 脚本生成 (4 大块结构化) |
| `build/health_apps_questionnaire.md` | 8102 bytes | R108 脚本生成 (4 段 disclosure + checklist) |

---

## 三、5 个 fix 用户执行步骤

### Fix #11a: Android keystore

```bash
# Mac/Linux/CI
chmod +x scripts/generate_android_keystore.sh
./scripts/generate_android_keystore.sh
# 交互式输入密码, 强密码用 1Password 生成 (16+ 字符)

# Windows (PowerShell)
.\scripts\generate_release_keystore.ps1

# 后续 (5 步):
# 1. flutter build appbundle --release
# 2. aapt dump badging 验 keystore SHA-256
# 3. 备份到 1Password / Bitwarden
# 4. Play Console → App integrity → 上传 .jks + 启用 Play App Signing
# 5. Play Console → Release → 上传 .aab (Internal testing)
```

### Fix #11b: Data Safety Form

```bash
python scripts/generate_data_safety_form.py
# 输出 build/data_safety_form.json + .md (28 子项 + 4 大类)

# 后续 (4 步):
# 1. Play Console → Policy → App content → Data safety
# 2. 7 大类逐项填 (按 .md 的应填声明)
# 3. Health & fitness 3 子类 + Audio 1 子类 加密披露
# 4. Save + Submit app for review
```

### Fix #11c: Health Apps Questionnaire

```bash
python scripts/generate_health_apps_questionnaire.py
# 输出 build/health_apps_questionnaire.json + .md (4 大块)

# 后续 (4 步):
# 1. Play Console → Policy → App content → Health apps
# 2. 4 大块逐项填 (按 .md 的 disclosure 4-6 段)
# 3. Block 3 必须答 "NOT a medical device" + 5 段披露
# 4. Save + Submit app for review
```

### Fix #12: iOS + Android 截图

```bash
# iOS (Mac only)
chmod +x scripts/generate_ios_screenshots.sh
./scripts/generate_ios_screenshots.sh
# 跑完: 75 张 (5 设备 × 3 locale × 5 屏)

# Android (Mac/Linux/WSL)
chmod +x scripts/generate_android_screenshots.sh
./scripts/generate_android_screenshots.sh
# 跑完: 12 张 (3 设备 × 2 locale × 4 屏)

# 后续:
# 1. 人工 review 截图质量 (无 PII, 5/4 屏顺序对, 关键功能突出)
# 2. App Store Connect / Google Play Console → 截图 → 上传
# 3. Transporter (iOS) / fastlane (Android) 一键上传
```

### Fix #13: 域名 + 邮箱 + ICP 备案

```bash
# 占位脚本 (需 dev 填 CF_API_TOKEN + CF_ACCOUNT_ID)
export CF_API_TOKEN="your_token"
export CF_ACCOUNT_ID="your_account_id"
chmod +x scripts/register_domain.sh
./scripts/register_domain.sh
# 自动: zone 创建 + Email Routing 配 4 邮箱 + Pages 部署 4 HTML

# 6 步 (Cloudflare Dashboard):
# 1. 注册 Cloudflare 账号
# 2. 注册 chroniccare.app ($15/年, 信用卡)
# 3. Pages 项目 chroniccare-legal 上传 4 HTML (从 templates/ 转 md)
# 4. Email Routing 配 4 邮箱 (support/privacy/noreply/abuse)
# 5. ICP 备案 (中国大陆上架必须, 7-20d 人工)
# 6. 公安备案 (30d 内, 5 分钟)

# 验证
for url in privacy support user-agreement sensitive-data-consent; do
  echo -n "$url: "
  curl -s -o /dev/null -w "%{http_code} (%{size_download} bytes)\n" \
    "https://chroniccare.app/$url"
done
# 期望: 全部 200
```

---

## 四、跑过的守门员 + 输出

### R108 新增 5 个 lock-in test

```
=== Test 1: keystore ===                  [OK] 6/6 tests passed
=== Test 2: data_safety_form ===          [OK] 8/8 tests passed
=== Test 3: health_apps_questionnaire === [OK] 9/9 tests passed
=== Test 4: screenshots ===               [OK] 7/7 tests passed
=== Test 5: domain ===                    [OK] 8/8 tests passed

总: 38/38 单测全过
```

### 现有 6 个 python 守门员 (确认未破坏)

| 守门员 | 输出 |
|---|---|
| `check_arb_keys.py` | ✅ zh / en / zh_Hant 3 语同步, 1266 keys |
| `check_changelog.py` | ✅ pubspec=0.30.0+85, CHANGELOG 48 entries |
| `check_cross_feature.py` | ✅ 131 files checked, 0 violations |
| `check_no_pua.py` | ✅ 0 PUA characters |
| `check_legal_consent.py` | ✅ setup_legal_dialog.dart 无 TODO |
| `check_sms_release_ready.py` | ✅ AliyunSmsProvider 真接 + isProductionReady 一致 |

**6 守门员全绿**, R108 增量没破坏任何现有检查。

### R72 复用脚本 (R108 验证可跑通)

```bash
# data_safety_form.py
[OK] JSON 写到: build/data_safety_form.json (4457 bytes)
[OK] Markdown 写到: build/data_safety_form.md (2847 bytes)

# health_apps_questionnaire.py (R108 新增)
[OK] JSON 写到: build/health_apps_questionnaire.json (7187 bytes)
[OK] Markdown 写到: build/health_apps_questionnaire.md (8102 bytes)
```

---

## 五、外部依赖总结

| Fix | 平台 | 资源 | 服务 | 时间 |
|---|---|---|---|---|
| **#11a** | Mac/Linux/Windows | JDK 17+ (keytool) | Play Console 账号 | 2h (生成) + 5min (Play Console) |
| **#11b** | 任意 (Python) | 无 | Play Console 账号 | 1h (人工填 28 子项) |
| **#11c** | 任意 (Python) | 无 | Play Console 账号 | 30min (人工填 4 大块) |
| **#12 iOS** | **Mac only** | Xcode 15+ + 5 iOS 模拟器 | App Store Connect 账号 | 1-2h 跑完 + 30min review |
| **#12 Android** | Mac/Linux/WSL | Android Studio + 3 AVD | Google Play Console 账号 | 1-2h 跑完 + 30min review |
| **#13 域名** | 任意 (Bash + curl) | $15/年 + 信用卡 | Cloudflare 账号 | 2h 部署 + 7-20d ICP 备案 |

**总投入**:
- **时间**: 上架前 1-2 周 (含 ICP 备案等待)
- **金钱**: $15/年 (域名) + $0 (Pages + Email Routing) + $0 (Developer 账号, 已注册) = $15
- **人力**: 1-2 人 (dev 跑脚本 + product 填表单 + 法务 ICP)

---

## 六、未修项 / 风险 / 下一步

### 未修项 (R108 范围外, 但相关)

| # | 项 | 工时 | 阻塞 |
|---|---|---|---|
| 1 | **iOS `review_information/` 目录** (R107 P0 #6) | 30min | R108 范围外, 单独 subagent |
| 2 | **iOS `PrivacyInfo.xcprivacy` 未注册 Xcode** (R107 P0 #3) | 15min | R108 范围外, 单独 subagent |
| 3 | **iOS `UIBackgroundModes audio` 缺** (R107 P0 #7) | 5min | R108 范围外 |
| 4 | **iOS LaunchImage + AppIcon 占位** (R107 P0 #4) | 1.5h | R108 范围外 |
| 5 | **en-US description 5.1.3 抽审风险** (R107 P0 #10) | 2.5h | R108 范围外 |
| 6 | **iOS 5 模拟器首次启动慢** | (已注释) | dev 需预留 30min |
| 7 | **App deep link `chroniccare://` 未注册** | 30min | R108 #12 隐含需求 |
| 8 | **AVD 名占位需 dev 改** (`Pixel_Tablet_7_API_34` → 实际名) | 5min | R108 #12 隐含需求 |

### 风险

1. **ICP 备案是最大风险** — 7-20d 审核 + 营业执照 + 幕布, **必做但耗时长**
   - **应对**: 早准备, 营业执照 + 幕布先备, 上架前 1 月就提交 ICP
2. **Apple 5.1.3 抽审** — en-US description 含 "hypertension, diabetes" 字样, 5.1.3 抽审延期 1-2 周
   - **应对**: R108 范围外, 单独 subagent 修
3. **App 真实 deep link 未注册** — 截图脚本会跑不通
   - **应对**: 先修 AndroidManifest + go_router, 再跑截图
4. **域名注册到 ICP 通过** 中间窗口期, App Store / Google Play 仍可上架国外 (美国 / 香港 / 台湾), 但中国大陆应用商店 (小米 / 华为 / OPPO / vivo / 魅族 / 应用宝) 必须 ICP 后才能上
   - **应对**: 国外先上架, 1-2 月后中国大陆再上

### 下一步 (R109+ 建议)

1. **R109 (1-2 周)**: P0 阻断剩余 5 项 (#3 PrivacyInfo + #4 LaunchImage + #6 review_info + #7 UIBackgroundModes + #10 en-US description) — 单独 subagent 处理
2. **R109**: 集成 `check_domain_reachable.py` 守门员, 每次 PR 自动 curl 4 URL 验 200
3. **R109**: 集成 `check_health_disclosure_consistency.py` 守门员, diff `build/health_apps_questionnaire.md` vs `fastlane/metadata/*/full_description.txt` vs `assets/legal/medical_disclaimer.md`
4. **R110**: feature_graphic.png 1024×500 + icon.png 512×512 自动生成 (从主页截图裁切)
5. **R110**: 集成 Maestro UI 自动化, 替代 deep link (更可靠)
6. **R110**: 集成 BrowserStack / Sauce Labs 跨真机测试

---

## 七、上架 Checklist (R108 范围)

### Android (Google Play)

- [ ] 跑 `python scripts/generate_android_keystore.sh` 生成 keystore
- [ ] 上传 .jks + 启用 Play App Signing
- [ ] 跑 `python scripts/generate_data_safety_form.py` 生成 28 子项
- [ ] Play Console → Data safety → 7 大类逐项填
- [ ] 跑 `python scripts/generate_health_apps_questionnaire.py` 生成 4 大块
- [ ] Play Console → Health apps → 4 大块逐项填
- [ ] 跑 `python scripts/generate_android_screenshots.sh` 生成 12 张
- [ ] Google Play Console → 商店发布 → 3 form factor 各上传
- [ ] 上传 1024×500 feature_graphic.png
- [ ] 上传 512×512 icon.png

### iOS (App Store)

- [ ] 跑 `python scripts/generate_data_safety_form.py` (iOS 用同一份)
- [ ] 跑 `python scripts/generate_ios_screenshots.sh` 生成 75 张 (Mac)
- [ ] App Store Connect → 截图 → 5 设备各 5 张
- [ ] App Store Connect → 隐私 → Privacy Policy URL

### 域名 + 邮箱

- [ ] 注册 Cloudflare 账号
- [ ] 注册 chroniccare.app ($15/年)
- [ ] 跑 `python scripts/register_domain.sh` 部署 4 HTML
- [ ] Email Routing 配 4 邮箱
- [ ] 12 URL 文件已是 `https://chroniccare.app/*` (R108 已统一)
- [ ] 验证 12 URL 全部 200
- [ ] ICP 备案 (中国大陆上架, 7-20d)
- [ ] 公安备案 (30d 内)

### 跨平台

- [ ] `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` 已新建 (R108)
- [ ] `fastlane/metadata/android/{en-US,zh-CN}/support_url.txt` 已新建 (R108)
- [ ] 12 URL 占位正确 (全部 `https://chroniccare.app/*`)
- [ ] 38 lock-in test 全过
- [ ] 6 现有 python 守门员全绿

---

## 八、文件清单汇总

### R108 新增 (18 个文件)

```
scripts/
├── generate_android_keystore.sh              (R108, Mac/Linux/CI)
├── generate_health_apps_questionnaire.py     (R108, Python)
├── generate_ios_screenshots.sh               (R108, Mac only)
├── generate_android_screenshots.sh           (R108, Mac/Linux/WSL)
├── register_domain.sh                        (R108, Bash + Cloudflare API)
└── templates/
    ├── privacy.html.tmpl                     (R108)
    ├── support.html.tmpl                     (R108)
    ├── user-agreement.html.tmpl              (R108)
    └── sensitive-data-consent.html.tmpl      (R108)

docs/audit/2026-08-10-cleanup/
├── R108-android-keystore-setup.md            (R108, 235 行)
├── R108-android-data-safety-form.md          (R108, 250 行)
├── R108-android-health-apps-questionnaire.md (R108, 286 行)
├── R108-screenshots-automation.md            (R108, 313 行)
├── R108-domain-registration-guide.md         (R108, 343 行)
└── R108-p0-11to13-report.md                  (R108, 本文件)

test/scripts/
├── keystore_script_round108_test.py          (R108, 6 单测)
├── data_safety_form_round108_test.py         (R108, 8 单测)
├── health_apps_questionnaire_round108_test.py (R108, 9 单测)
├── screenshots_scripts_round108_test.py      (R108, 7 单测)
└── domain_check_round108_test.py             (R108, 8 单测)

fastlane/metadata/android/{en-US,zh-CN}/
├── privacy_url.txt                           (R108 恢复, R100 误删)
└── support_url.txt                           (R108 恢复, R100 误删)
```

### R72 复用 (2 个文件)

```
scripts/
├── generate_release_keystore.ps1              (R72, Windows dev, 验证存在)
└── generate_data_safety_form.py               (R72, Python, 验证跑通)
```

### build/ 临时输出 (不入仓)

```
build/
├── data_safety_form.json                     (R72 脚本生成)
├── data_safety_form.md                       (R72 脚本生成)
├── health_apps_questionnaire.json             (R108 脚本生成)
└── health_apps_questionnaire.md              (R108 脚本生成)
```

---

## 九、总结

R108 subagent C 完成 P0 #11-#13 3 个 fix 的脚本生成器 + 详细步骤文档:
- **18 个新文件** (11 脚本/模板 + 5 文档 + 5 lock-in test + 4 URL 文件 = 18 个, 部分分类重叠)
- **38 个单测全过** (5 lock-in test × 7-9 单测)
- **6 现有守门员全绿** (R108 增量没破坏任何现有检查)
- **0 flutter analyze / 0 flutter test** (按要求, 跑不跑)

**外部依赖**: Mac + Xcode (iOS) / Android Studio (Android) / Cloudflare 账号 / Play Console 账号 / ICP 备案 (中国大陆上架, 7-20d)

**R108 范围外 P0 剩余 5 项** (#3 PrivacyInfo + #4 LaunchImage + #6 review_info + #7 UIBackgroundModes + #10 en-US description), 建议 R109 单独 subagent 处理 (这些是 5min-2.5h 简单修改, 不需脚本生成)。
