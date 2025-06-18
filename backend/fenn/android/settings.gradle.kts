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
        // Utiliser Maven Central en premier pour plus de fiabilité
        mavenCentral()
        // Dépôts alternatifs pour résoudre les problèmes de TLS
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://jitpack.io") }
        // Dépôts officiels
        google()
        gradlePluginPortal()
        // Dépôts supplémentaires
        maven { url = uri("https://repo.maven.apache.org/maven2/") }
        maven { url = uri("https://plugins.gradle.org/m2/") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

// Configuration des dépôts pour tous les projets
dependencyResolutionManagement {
    repositories {
        // Utiliser Maven Central en premier pour plus de fiabilité
        mavenCentral()
        // Dépôts alternatifs pour résoudre les problèmes de TLS
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://jitpack.io") }
        // Dépôts officiels
        google()
        // Dépôts supplémentaires
        maven { url = uri("https://repo.maven.apache.org/maven2/") }
        maven { url = uri("https://plugins.gradle.org/m2/") }
    }
}

include(":app")
