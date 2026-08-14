# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# flutter_local_notifications 依赖 Gson TypeToken 反序列化已排程通知
# v0.32 round 8f (release 冒烟实测崩溃修复): R8 默认剥 Signature 属性 →
# TypeToken 泛型参数丢失 → "TypeToken must be created with a type argument"
# (setup 第 3 步 pendingNotificationRequests() 抛 PlatformException)。
# -keepattributes Signature 是根治 (保留泛型签名), 下面 keep 属双保险。
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# audioplayers
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# record (audio recording)
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# sqlcipher_flutter_libs
-keep class net.zetetic.** { *; }
-keep class android.database.sqlite.** { *; }
-dontwarn net.zetetic.**

# speech_to_text
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# path_provider / drift
-keep class io.requery.android.database.** { *; }

# 保留行号 (crash report 可读)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Core (Flutter deferred components 未使用, R8 报 missing class)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# v0.27 round 63 (R63, GooglePlay P1-6 修复): app 自身 keep
# 防 R8 混淆 MainActivity / BootReceiver / 任何未来 Kotlin 平台类
# (Flutter 默认 proguard-android-optimize.txt 不 keep 业务包)
-keep class com.chroniccare.chroniccare.** { *; }
