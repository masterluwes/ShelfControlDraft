plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.shelfcontrol"

    // Let Flutter set these, but ensure they’re Ints
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ✅ Use Java/Kotlin 17 (required by modern AGP)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Desugaring not needed when using 17; if you keep it, it's harmless
        isCoreLibraryDesugaringEnabled = true
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.shelfcontrol"

        // ✅ Firebase plugins (e.g., cloud_firestore 6.x) require at least 23
        // If flutter.minSdkVersion is lower, force 23.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // change when you set up release signing
            isMinifyEnabled = true
            isShrinkResources = true
        }
        debug {
            // default is fine
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM and libs are fine
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // If you keep desugaring:
    // coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
