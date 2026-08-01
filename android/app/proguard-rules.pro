# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Keep Play Core (deferred components / split install) referenced by Flutter's embedding
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# record plugin (audio recording)
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# just_audio
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# Gson / JSON models used via json_serializable, keep field names
-keepattributes Signature
-keepattributes *Annotation*
-keep class * implements java.io.Serializable { *; }
