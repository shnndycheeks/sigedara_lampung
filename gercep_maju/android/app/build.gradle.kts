plugins {
    id("com.android.application")
    id("kotlin-android")

    // TAMBAHAN FIREBASE
    id("com.google.gms.google-services")

    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gercep_maju"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // WAJIB UNTUK NOTIFICATION
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.gercep_maju"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    // FIREBASE BOM
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // FIREBASE CLOUD MESSAGING
    implementation("com.google.firebase:firebase-messaging")

    // DESUGARING
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}