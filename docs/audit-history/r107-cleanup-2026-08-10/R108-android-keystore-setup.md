# Android Release Keystore + Play App Signing 设置指南 (R108)

> **范围**: v0.30 R108 P0 #11a — Android 上架 P0 阻塞之一
> **基线**: v0.30.0+85 / 2026-08-10 cleanup
> **读者**: 需要上架 Google Play 的 dev / DevOps
> **关联**: `docs/PLAYSTORE_SIGNING_GUIDE.md` (R67) + `scripts/generate_release_keystore.ps1` (R72) + `scripts/generate_android_keystore.sh` (R108)

---

## 一、为什么是 P0 阻塞

`android/app/build.gradle.kts:91-94` 默认走 `signingConfigs.getByName("release")`, 该 config 读 `android/key.properties`。
**当前项目状态**:
- `android/key.properties` — ❌ 不存在 (R67 commit 留 TODO)
- `android/app/*.jks` — ❌ 不存在
- 上 store 时 gradle 报 "Keystore file not set" → 上传被 Google Play Console 拒
- R72 写 PowerShell 脚本 `generate_release_keystore.ps1` 给 Windows dev
- **R108 新增**: bash 版本 `generate_android_keystore.sh` 给 Mac/Linux dev (CI / DevOps 必备)

---

## 二、平台选择

| 平台 | 脚本 | 何时用 |
|---|---|---|
| **Windows** | `scripts/generate_release_keystore.ps1` (R72, 已存在) | Windows dev (本项目主开发环境) |
| **Mac / Linux / CI** | `scripts/generate_android_keystore.sh` (R108, 本次新增) | Mac dev / Linux dev / GitHub Actions / Bitrise / fastlane |

两个脚本功能完全一致, 选一个跑就行, **生成结果可互用** (keystore 是 OpenSSL 标准的 PKCS12, 跨平台兼容)。

---

## 三、5 步生成 + 上架流程

### Step 1: 装 JDK 17+ (keytool 命令行)

```bash
# Mac (Homebrew)
brew install openjdk@17
export PATH="$(brew --prefix openjdk@17)/bin:$PATH"

# Linux (Debian/Ubuntu)
sudo apt install openjdk-17-jdk

# Linux (RHEL/CentOS)
sudo yum install java-17-openjdk

# 验证
keytool -help | head -5
```

### Step 2: 跑脚本

**Mac / Linux**:
```bash
chmod +x scripts/generate_android_keystore.sh
./scripts/generate_android_keystore.sh
# 交互式: 选默认即可, 强密码用密码管理器生成 (16+ 字符)
```

**非交互 (CI / 自动化)**:
```bash
STORE_PASSWORD="$(pass show chroniccare/jks-store)" \
KEY_PASSWORD="$(pass show chroniccare/jks-key)" \
ALIAS=chroniccare \
VALIDITY=10000 \
KEYSIZE=2048 \
./scripts/generate_android_keystore.sh
```

**Windows (PowerShell)**:
```powershell
.\scripts\generate_release_keystore.ps1
# 交互式同上
```

### Step 3: 验证 .aab 用真实 keystore 签

```bash
# 构建 release AAB (没 -PdebugSigning 即走真实 keystore)
flutter build appbundle --release

# 验证签名 (output 应含 release keystore SHA-256)
aapt dump badging build/app/outputs/bundle/release/app-release.aab | head -3
```

### Step 4: Play Console → 启用 Play App Signing

1. 打开 https://play.google.com/console → 选 ChronicCare
2. **Setup → App integrity** → **App signing** 卡片
3. 如果第一次: 选 "Use Play App Signing" → 同意 → 上传你的 upload key
   - **注意**: Play App Signing 分两层: **upload key** (你持有) + **app signing key** (Google 持有)
   - 第一次新 App: **app signing key = 你的 upload key** (Google 会自动生成新 key 然后让你下载)
4. 上传 upload key (即你刚生成的 `chroniccare-release.jks`):
   - **Encryption key** 段不填 (我们不用 encrypted key)
   - **Upload key** 段: 点 "Upload" → 选 `chroniccare-release.jks`
   - 填 keystore 密码 + key 密码 + alias (`chroniccare`)
5. 提交后 Google 验证, 通常 5-15 分钟, 收到邮件 "App signing key enabled"

### Step 5: 上传第一个 .aab 测试

1. Play Console → **Release → Production** (或 Testing → Internal)
2. **Create new release** → 上传 `build/app/outputs/bundle/release/app-release.aab`
3. 选 release name (例 "0.30.0 (85)") + release notes
4. **Review release** → **Start rollout to Production** (Internal testing 不需要 review)
5. 等 15-60 分钟审核 → 上架成功

---

## 四、安全 + 备份 (丢 keystore = App 永久无法升级)

### 必须做的 3 件事

1. **备份到 1Password / Bitwarden** (密码管理器):
   - 1Password vault 选 "Private" 或 "DevOps"
   - 标题 "ChronicCare Android Release Keystore"
   - 附件: `chroniccare-release.jks` + `key.properties`
   - 备注: "丢 = App 永久无法升级, 必须 Play Console 重置签名 (会丢用户)"
2. **额外加密备份** (灾备):
   ```bash
   # Mac/Linux: zip + 密码
   cd android
   zip -e ../chroniccare-release-keystore-backup-$(date +%Y%m%d).zip \
     app/chroniccare-release.jks key.properties
   # 密码用 1Password 生成的 20+ 字符
   ```
3. **抄送 1 个团队成员**: 万一你不在, 别人能继续 release

### 切勿做的 4 件事

1. ❌ 把 `chroniccare-release.jks` 或 `key.properties` commit 到 git (R67 已加 `.gitignore`, 别绕过)
2. ❌ 写密码到 README / wiki / 邮件 / Slack (永远用密码管理器)
3. ❌ 用同一个 keystore 签多个 App (一个项目一个 keystore, 删 App 时不影响其他)
4. ❌ 改 alias / password 后没测就 release (第一次用新 keystore 一定要 aapt dump 验)

### 丢 keystore 怎么办 (灾备)

1. Play Console → App integrity → **Request upload key reset**
2. 上传新 keystore + 签一个声明 "I lost the original upload key"
3. Google 审核 7-15 天 (需验证你 = App 所有者)
4. 通过后 → 新 keystore 成为 upload key, App signing key 不变 (用户无感)

**⚠️ 注意**: App signing key 丢了 = 永久死, 必须用相同 packageName 重发 App (用户全部丢, 排名归零)。所以我们用 Google 托管, Google 永不丢。

---

## 五、Play Console Data Safety + Health Apps Questionnaire

keystore OK 后, 还要补两项 Play Console 表单 (脚本 + 指南见 R108 配套):
- **#11b Data Safety Form** — 7 大类 × 4 子项 = 28 子项手填 → `scripts/generate_data_safety_form.py` (R72, v0.30 增量由 R108 提供)
- **#11c Health Apps Questionnaire** — 4 大块 (心理健康 / 临床声明 / 医疗设备 / 病耻感) → `scripts/generate_health_apps_questionnaire.py` (R108 新增)

---

## 六、CI 集成 (参考)

### GitHub Actions 例 (签 release build)

```yaml
# .github/workflows/release-android.yml
- name: Decode keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/chroniccare-release.jks
    echo "${{ secrets.ANDROID_KEY_PROPS }}" > android/key.properties
- name: Build AAB
  run: flutter build appbundle --release
- name: Upload to Play Console
  uses: r0adkll/upload-google-play@v1
  with:
    serviceAccountJsonPlainText: ${{ secrets.PLAY_CONSOLE_SA_JSON }}
    packageName: app.chroniccare.patient
    releaseFiles: build/app/outputs/bundle/release/app-release.aab
    track: internal
```

### fastlane 例

```ruby
# android/fastlane/Fastfile
lane :release do
  upload_to_play_store(
    package_name: "app.chroniccare.patient",
    aab: "../build/app/outputs/bundle/release/app-release.aab",
    track: "internal",
    json_key: ENV["PLAY_CONSOLE_SA_JSON_PATH"]
  )
end
```

---

## 七、Checklist (上架前逐项过)

- [ ] `android/app/chroniccare-release.jks` 生成, 备份到 1Password
- [ ] `android/key.properties` 生成, 备份到 1Password
- [ ] `.gitignore` 排除 `*.jks` + `key.properties` (R67 已加, 验证 `git status` 不含)
- [ ] `flutter build appbundle --release` 成功
- [ ] `aapt dump badging` 显示 release keystore SHA-256
- [ ] Play Console → App integrity → App signing enabled
- [ ] Play Console → Release → 上传 .aab 成功 (Internal testing)
- [ ] **Data Safety Form** 28 子项已填 (脚本: `python scripts/generate_data_safety_form.py`)
- [ ] **Health Apps Questionnaire** 4 大块已填 (脚本: `python scripts/generate_health_apps_questionnaire.py`)
- [ ] **feature_graphic.png 1024×500** 真实图 (非 67B 占位)
- [ ] **icon.png 512×512** 真实图 (非 1443B 占位)
- [ ] **4 张 phone screenshot** 真实图 (非 67B 占位)
- [ ] **7"/10" 平板 screenshot** ≥1 张 (Google Play 强制)

详见 `R108-android-data-safety-form.md` + `R108-android-health-apps-questionnaire.md` + `R108-screenshots-automation.md`。

---

## 八、未做 / 风险 / 下一步

### 已知限制

- **本指南假设 Mac/Linux/Windows dev 都有 JDK 17+** — 如果 dev 机器 JDK 旧, 需先升级
- **第一次 Play App Signing 流程有 5-15 分钟延迟** — 不要在 release 当天第一次设
- **CI 上传 Play Console 需 service account JSON** — Play Console → Setup → API access 创建, 存 GitHub Secrets

### 后续优化 (R109+)

- R109: 加 `key.properties.example` 模板 (`.gitignore` 排除 `.example` 时用), 让 dev 不用问密码
- R110: 集成 `flutter_secure_storage` 跑时验证 keystore SHA-256 是否匹配 (防 CI 误用错 keystore)
- R110: 加 `playstore_signing_key_v2.jks` 轮换 (10+ 年后过期时)

---

## 九、相关文件清单

| 文件 | 类型 | 作用 |
|---|---|---|
| `scripts/generate_release_keystore.ps1` | PowerShell 脚本 (R72) | Windows dev 生成 keystore |
| `scripts/generate_android_keystore.sh` | Bash 脚本 (R108) | Mac/Linux dev + CI 生成 keystore |
| `android/app/build.gradle.kts:56-94` | Gradle 配置 (R97) | 读 `key.properties` 切 release signingConfig |
| `docs/PLAYSTORE_SIGNING_GUIDE.md` | 5 步指南 (R67) | 原版指南 (R108 是其 Mac/Linux 增量) |
| `.gitignore` | 排除 `*.jks` + `key.properties` (R67) | 防止误 commit 密码 |
