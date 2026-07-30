pluginManagement {
    val flutterSdkPath = run {
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

    // The versions live in gradle.properties.  They have to be named here
    // rather than in the `plugins` block below: the Kotlin DSL compiles that
    // block as a program of its own, with the rest of this file erased, so a
    // variable declared out there wouldn't be in scope inside it.
    val agpVersion: String by settings
    val kotlinVersion: String by settings
    plugins {
        id("com.android.application") version agpVersion
        id("com.android.library") version agpVersion
        id("org.jetbrains.kotlin.android") version kotlinVersion
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Versions come from `pluginManagement` above.  These stay listed here,
    // and not only there, because it's this block that puts the plugins on the
    // build scripts' classpath; `pluginManagement` only supplies a default
    // version.  The Flutter plugins we depend on rely on that classpath, as
    // they apply `com.android.library` and `kotlin-android` imperatively.
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
}

include(":app")
