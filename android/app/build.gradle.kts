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

    buildTypes {
        release {
            // v0.27 round 61 (R61): TODO 上架前必须改 release 签名 (keystore)
            // 当前用 debug 签名以便 `flutter run --release` 跑通
            // 上架 Play Store 前必须配 signingConfigs.release block
            // v0.27 round 63 (R63, GooglePlay P0-1 修复): R55+ 配 release keystore
            // 步骤:
            //   1. cp android/key.properties.example android/key.properties + 填实值
            //   2. 下方 signingConfig 切到 signingConfigs.getByName("release")
            //   3. 上方加 signingConfigs.create("release") { ... } block 读 key.properties
            //   4. .gitignore 加 key.properties + *.jks
            //   5. Play Console 启用 Play App Signing + 上传 .aab
            // 当前 release 块**仍然**用 debug 签名, 仅加显式安全开关 (P1-7)
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
