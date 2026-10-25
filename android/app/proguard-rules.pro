# Flutter's Gradle plugin adds its own keep rules when minify is on.
# This file is the app-specific extra.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
