# Release builds are shrunk by R8. Plugins call into their Kotlin code from
# Dart over method channels, which R8 can't see, so it renamed or dropped
# methods they need (shared_preferences crashed at startup). Keep them whole.
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.llfbandit.app_links.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Kotlin coroutines, which the plugins' suspend functions run on.
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# Some plugins (shared_preferences among them) call Kotlin straight from Dart
# through package:jni, which looks methods up by name at run time.
-keep class com.github.dart_lang.jni.** { *; }
