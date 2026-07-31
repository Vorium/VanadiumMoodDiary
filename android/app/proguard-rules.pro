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

# v0.27 round 63 (R63, GooglePlay P1-6 修复): app 自身 keep
# 防 R8 混淆 MainActivity / BootReceiver / 任何未来 Kotlin 平台类
# (Flutter 默认 proguard-android-optimize.txt 不 keep 业务包)
-keep class com.chroniccare.chroniccare.** { *; }
