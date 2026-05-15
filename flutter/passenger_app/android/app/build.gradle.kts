import java.util.Base64
import java.util.Properties
import kotlin.text.Charsets

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.passenger_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.passenger_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val dartDefines = mutableMapOf<String, String>()
        (project.properties["dart-defines"] as? String)?.split(",")?.forEach { encoded ->
            if (encoded.isBlank()) return@forEach
            runCatching {
                val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
                val eq = decoded.indexOf('=')
                if (eq > 0) {
                    dartDefines[decoded.substring(0, eq)] = decoded.substring(eq + 1)
                }
            }
        }
        val localProps = Properties()
        rootProject.file("local.properties").takeIf { it.exists() }?.reader(Charsets.UTF_8)?.use {
            localProps.load(it)
        }
        val mapsKey = dartDefines["GOOGLE_MAPS_API_KEY"]
            ?: localProps.getProperty("GOOGLE_MAPS_API_KEY")
            ?: ""
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
