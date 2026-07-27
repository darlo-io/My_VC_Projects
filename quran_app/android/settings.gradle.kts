pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 8.x — последняя версия, совместимая с Flutter Gradle Plugin 1.0.0.
    // AGP 9.x ломает сборку: "Starting AGP 9+, only the new DSL
    // interface will be read" — FGP не поддерживает AGP 9+ пока.
    // Flutter 3.44 deprecation: AGP 8.7.2 → 8.11.1 (warning при
    // сборке), Kotlin 2.1.20 → 2.2.20. Обновлено 2026-07-16.
    id("com.android.application") version "8.11.1" apply false
    // Kotlin 2.2.20 ломает сборку с `sentry_flutter` 8.x — их
    // build.gradle использует `sourceCompatibility = JavaVersion.VERSION_1_6`,
    // который Kotlin 2.2 отвергает ("Language version 1.6 is no longer
    // supported"). Kotlin 1.9.25 — последний с поддержкой 1.6
    // (Flutter SDK 3.44 поддерживает 1.9.x стабильно).
    id("org.jetbrains.kotlin.android") version "1.9.25" apply false
}

include(":app")
