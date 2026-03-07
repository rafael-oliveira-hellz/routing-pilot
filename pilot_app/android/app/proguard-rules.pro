# Pilot App — ProGuard/R8. APP-8002: ofuscar e otimizar release.
# Flutter/Dart: manter classes e nativos usados pelo engine.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
# Evitar remoção de reflexão usada por plugins
-dontwarn io.flutter.embedding.**
