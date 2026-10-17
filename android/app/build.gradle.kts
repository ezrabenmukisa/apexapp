import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing keys live in android/key.properties + android/keystore/ (both
// gitignored; see docs/firebase-setup.md). Without them the build falls back
// to the machine's default debug key, whose SHA must then be added to
// Firebase by hand.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun keyProperty(name: String): String? = keyProperties.getProperty(name)

android {
    namespace = "com.apex.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.apex.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Shared team debug key: one SHA-1/SHA-256 registered in Firebase.
        keyProperty("debugStoreFile")?.let { path ->
            getByName("debug") {
                storeFile = rootProject.file(path)
                storePassword = keyProperty("debugStorePassword")
                keyAlias = keyProperty("debugKeyAlias")
                keyPassword = keyProperty("debugKeyPassword")
            }
        }
        // Release / Play upload key.
        keyProperty("storeFile")?.let { path ->
            create("release") {
                storeFile = rootProject.file(path)
                storePassword = keyProperty("storePassword")
                keyAlias = keyProperty("keyAlias")
                keyPassword = keyProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key so `flutter run --release` works
            // for teammates who don't hold the upload key.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
