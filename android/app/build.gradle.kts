plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.shelfcontrol"

    // Let Flutter control these to avoid version mismatches
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // Enable core library desugaring
    }
    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.shelfcontrol"

        // KTS syntax: use assignments, not minSdkVersion(...)
        minSdkVersion = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // use your real signing config for release builds later
            signingConfig = signingConfigs.getByName("debug")
            // Enable code shrinking, obfuscation, and optimization.
            isMinifyEnabled = true
            // Enable resource shrinking.
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.0.0")) // Updated BOM version
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") // Add this line
}
