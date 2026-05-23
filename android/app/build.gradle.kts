plugins {
    id("com.android.application")
    id("kotlin-android")
    // Uncomment to enable Firebase
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.govgate.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Required for Firebase compatibility

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.govgate.app"
        minSdk = 23 // Increased from minimum for compatibility
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Firebase Messaging auto-init enabled
        manifestPlaceholders["firebase_messaging_auto_init_enabled"] = "true"

        ndk {
            abiFilters += setOf("x86") // emulator only; remove/expand before release
        }
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
    // Firebase dependencies
    implementation("com.google.firebase:firebase-auth-ktx:22.3.1")
    implementation("com.google.firebase:firebase-firestore-ktx:24.9.1")
    implementation("com.google.firebase:firebase-storage-ktx:20.3.0")
    implementation("com.google.firebase:firebase-messaging-ktx:23.4.1")
}
