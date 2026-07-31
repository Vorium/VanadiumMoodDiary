plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.chroniccare.chroniccare"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // v0.27 round 61 (R61): com.chroniccare.chroniccare 已在 flutter create
        // 阶段指定 --org com.chroniccare, 自动生成。无需改。
        applicationId = "com.chroniccare.chroniccare"
        // v0.27 round 63 (R63, GooglePlay P1-2 修复): 显式 pin minSdk=24 /
        // targetSdk=36, 防 Flutter 升级时默认值变化。
        // 之前用 `flutter.minSdkVersion` / `flutter.targetSdkVersion` 是隐式依赖。
        // - minSdk=24: Flutter 3.41.9 默认 24; SQLCipher 要求 ≥23, 24 富余 1 版
        // - targetSdk=36: 2025-08 Play 上架要求 (Android 16); Flutter 3.41.9 默认 36
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // v0.27 round 61 (R61): 4 维情绪 + audio + 多个第三方 plugin
        // 触发 64K 方法数, 启用 multidex
        multiDexEnabled = true
    }

    // v0.27 round 67 (Sprint 1 上架前 P0, googleplay C-P0-9):
    // Release signingConfigs 块, 读 `android/key.properties` (用户负责生成)。
    //
    // **当前默认** fallback 到 debug 签名 (跟 R67 前兼容, 让 `flutter run --release`
    // 还能跑通)。**上 store 前必须**:
    // 1. cp android/key.properties.example android/key.properties
    // 2. 填 4 个真实值 (storeFile / storePassword / keyAlias / keyPassword)
    // 3. `key.properties` + `*.jks` 已在 .gitignore 排除 (R63 已加)
    // 4. 把 release.signingConfig 切到 signingConfigs.getByName("release")
    //    (见下方 `release { ... }` 块 TODO 注释)
    // 5. Play Console 启用 Play App Signing + 上传 .aab
    //
    // 详见 docs/PLAYSTORE_SIGNING_GUIDE.md (R67 新增 5 步指南)。
    signingConfigs {
        create("release") {
            // 读 key.properties (若存在) → 用真实 keystore 签
            // 缺 key.properties → 抛 FileNotFoundException, 上 store 前会卡这
            val keystoreProperties = java.util.Properties()
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                keystorePropertiesFile.inputStream().use { stream ->
                    keystoreProperties.load(stream)
                }
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String?
            }
            // key.properties 不存在时, 字段保持 null → 上 store build 时
            // gradle 报 "Keystore file not set", 用户按 PLAYSTORE_SIGNING_GUIDE
            // 走 5 步生成 + cp + 填
        }
    }

    buildTypes {
        release {
            // v0.27 round 67 (Sprint 1, googleplay C-P0-9):
            // **TODO 上 store 前切换**: 改成 signingConfigs.getByName("release")
            // 当前保留 debug 是为了让 R67 commit 阶段 build 不挂 (无 key.properties)
            // 上 store 时改成 release 即可 (见 docs/PLAYSTORE_SIGNING_GUIDE.md)
            signingConfig = signingConfigs.getByName("debug")
            // v0.27 round 63 (R63, GooglePlay P1-7 修复): 显式禁 debug/jni-debug
            // release 默认 debuggable=false, 但显式更稳 + 防 R8 误判
            isDebuggable = false
            isJniDebuggable = false
            // 启用 ProGuard / R8
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
