import groovy.json.JsonSlurper

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    buildFeatures { resValues = true }
    namespace = "com.shanthini.askagain"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.shanthini.askagain"
        val config = project.file("google-services.json")
        if (config.exists()) {
            val data = JsonSlurper().parse(config) as Map<*, *>
            val projectInfo = data["project_info"] as Map<*, *>
            val client = (data["client"] as List<*>).filterIsInstance<Map<*, *>>().first {
                val info = it["client_info"] as Map<*, *>
                (info["android_client_info"] as Map<*, *>)["package_name"] == applicationId
            }
            val api = (client["api_key"] as List<*>).first() as Map<*, *>
            val oauth = (client["oauth_client"] as? List<*>)?.filterIsInstance<Map<*, *>>()?.firstOrNull { it["client_type"] == 3 }
            if (oauth != null) resValue("string", "default_web_client_id", oauth["client_id"].toString())
            resValue("string", "google_api_key", api["current_key"].toString())
            resValue("string", "google_app_id", (client["client_info"] as Map<*, *>)["mobilesdk_app_id"].toString())
            resValue("string", "gcm_defaultSenderId", projectInfo["project_number"].toString())
            resValue("string", "project_id", projectInfo["project_id"].toString())
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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

dependencies {
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
