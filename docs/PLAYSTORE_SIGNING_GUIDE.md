# Play Store 上架签名配置指南（v0.27 R67 Sprint 1）

**创建时间**: 2026-07-31
**目标**: 5 步配 release keystore + Play App Signing, 让 `flutter build appbundle` 产出的 .aab 可上传 Play Store
**前置**: R67 已加 signingConfigs.release block (读 `key.properties`), 当前默认 fallback debug, **上 store 前必走 5 步**

---

## 0. 背景

R67 修复前: `android/app/build.gradle.kts` release 块用 `signingConfig = signingConfigs.getByName("debug")` 签 → Play Store 100% 拒 ("APK/App Bundle is signed with debug key")。R67 加了 signingConfigs.release block 读 `key.properties`, 但默认仍走 debug (避免 R67 commit 阶段 build 挂掉)。

上 store 前 5 步:

1. 生成 release keystore
2. 配 `android/key.properties` (4 个真实值)
3. 切 `signingConfig = signingConfigs.getByName("release")`
4. 启用 Play App Signing + 上传 .aab
5. 验证 + 提交

---

## 1. 生成 release keystore

**重要**: keystore 一旦丢失 = 无法更新 App (Play App Signing 启用前)。**多备份几份 (加密 U 盘 / 1Password / 公司密码管理器)**, 失效日期前都不要删。

```bash
# 1. 切到 android/app 目录
cd android/app

# 2. 生成 keystore (RSA 2048, 10000 天 = 27 年, alias=chroniccare)
keytool -genkey -v \
  -keystore chroniccare-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias chroniccare

# 提示输入 4 个值:
#   - keystore password: (强密码, 16+ 字符, 存密码管理器)
#   - key password:      (可以跟 keystore 密码相同, 也可以不同)
#   - 姓名 / 组织 / 城市 / 省 / 国家代码: 都填真实公司信息
```

生成后:
- `android/app/chroniccare-release.jks` (~2-3 KB, 千万**不要** commit)
- `android/.gitignore` 已排除 `**/*.jks` (R63 加的) + root `.gitignore` 兜底 (R67 加的)

---

## 2. 配 `android/key.properties`

```bash
# 1. 复制模板
cp android/key.properties.example android/key.properties

# 2. 编辑 (不要用记事本, 用 VSCode / vim 避免换行符问题)
#    填 R67 step 1 记下的 4 个真实值:
#
#    storeFile=chroniccare-release.jks    # 相对 android/ 目录
#    storePassword=YOUR_STORE_PASSWORD    # 跟 keytool 第 1 个密码一致
#    keyAlias=chroniccare                  # 跟 -alias 一致
#    keyPassword=YOUR_KEY_PASSWORD        # 跟 keytool 第 2 个密码一致
```

**重要**:
- `key.properties` 已在 `.gitignore` 排除, **永远不要 commit**
- 4 个值都填实际值, 不要留 `YOUR_*` 占位 (否则 build 必失败)

---

## 3. 切 `signingConfig` 到 release

打开 `android/app/build.gradle.kts`, 找:

```kotlin
buildTypes {
    release {
        // TODO 上 store 前切换
        signingConfig = signingConfigs.getByName("debug")
        ...
    }
}
```

改成:

```kotlin
buildTypes {
    release {
        // v0.27 round 67 (上 store 切换): 用 release keystore
        signingConfig = signingConfigs.getByName("release")
        ...
    }
}
```

---

## 4. 启用 Play App Signing

1. 登录 [Play Console](https://play.google.com/console)
2. 选 chroniccare App → **Setup** → **App signing** (或 **App integrity**)
3. 选 **Use Google Play App Signing** → 上传 `android/app/chroniccare-release.jks` (用密钥导出工具, 选 "Export key" 不用 raw .jks)
4. 启用后, Play Console 会生成"app signing key" + "upload key" 两个 key:
   - **App signing key** (托管在 Google) — 用户装的 App 用这个签
   - **Upload key** (用户自己) — 每次上传 .aab 用这个, Play 重新用 app signing key 签后下发
5. 把第 1 步生成的 `chroniccare-release.jks` 当作 **upload key**

---

## 5. 验证 + 提交

```bash
# 1. 测 release build (本地先跑一遍, 不要直接上 Play)
flutter clean
flutter build appbundle --release

# 预期输出:
# ✓ Built build/app/outputs/bundle/release/app-release.aab

# 2. 验证签名 (用 apksigner)
$ANDROID_HOME/build-tools/35.0.0/apksigner verify --print-certs build/app/outputs/bundle/release/app-release.aab
# 应看到:
#   Verifies
#   Verified using v2 scheme (APK Signature Scheme v2): true
#   Verified using v3 scheme (APK Signature Scheme v3): true
#   Subject: CN=慢性病管家, OU=..., O=...

# 3. 上传 .aab 到 Play Console
#    Play Console → Release → Production → Create new release
#    上传 build/app/outputs/bundle/release/app-release.aab
#    填版本号 / Release notes / 选国家/地区 → Review release → Start rollout
```

---

## 6. 常见问题

### Q1: 切 release 签名后 build 报 "Keystore was tampered with, or password was incorrect"
- 检查 `key.properties` 的 `storePassword` 是不是跟 `keytool` 第 1 个密码一致
- 大小写敏感, 末尾不要有空格 / 换行

### Q2: 切 release 签名后 build 报 "Keystore file not set"
- `key.properties` 不存在, 或 `storeFile=` 路径错了
- 默认 keystore 在 `android/app/`, 相对路径从 `android/` 算起: `storeFile=chroniccare-release.jks`

### Q3: Play Console 上传 .aab 后报 "Upload key is not authorized"
- 启用了 Play App Signing, 但上传的 keystore 不是 Play Console 登记的 upload key
- 重新走第 4 步登记 upload key

### Q4: 旧版本 (debug 签) 已上传, 怎么升级到 release 签?
- 这种情况**不能**简单升级: Play 看到签名不匹配会拒
- 必须走 Play Console 的 "Request upload key reset" (人工审核, 1-3 天)
- 应急方案: 用同一 debug key 重新打 release (不推荐, 但能过审核)

### Q5: keystore 丢了怎么办?
- **没启用 Play App Signing**: 无法更新 App, 只能重新发新包 + 换 package name (丢所有用户)
- **启用 Play App Signing**: 联系 Google 恢复 upload key, 走人工审核
- 结论: **keystore 至少备份 3 份** (1Password + 加密 U 盘 + 团队成员各 1 份)

---

## 7. iOS 端

iOS 端用 Xcode 自动签名 + Apple Developer 证书, 流程跟 Android 不同。详见:
- `fastlane/metadata/ios/` metadata (R67 已建)
- `fastlane/Fastfile` `lane :release` (R67 已建)
- Apple Developer 后台: [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Keys

iOS 端**不**需要手维护 keystore, Apple 托管, 只要 .p12 证书 + provisioning profile 就行。

---

## 8. 引用

- Android 官方: https://developer.android.com/studio/publish/app-signing
- Play App Signing: https://support.google.com/googleplay/android-developer/answer/9842756
- Flutter 官方: https://docs.flutter.dev/deployment/android#signing-the-app
- 本项目 R67 修复 commit: 见 git log `--grep="C-P0-9"`
