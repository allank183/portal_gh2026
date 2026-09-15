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
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.4.4") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")

// Paksa semua plugin/subproject menggunakan Build-Tools 34.0.0
gradle.beforeProject {
    plugins.withId("com.android.application") {
        val android = extensions.findByName("android") as? com.android.build.gradle.AppExtension
        android?.buildToolsVersion("34.0.0")
    }
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android") as? com.android.build.gradle.LibraryExtension
        android?.buildToolsVersion("34.0.0")
    }
}