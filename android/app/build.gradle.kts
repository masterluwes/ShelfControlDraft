plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // <- prefer this id
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.shelfcontrol"

    // Use Flutter-provided versions
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // Toolchains (Kotlin 2.x prefers Java 17)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        // (Optional) remove this: it's a Java compiler flag, not Kotlin.
        // freeCompilerArgs += "-Xlint:deprecation"
    }

    defaultConfig {
        applicationId = "com.example.shelfcontrol"

        // ✅ Kotlin DSL properties (not Groovy functions)
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
