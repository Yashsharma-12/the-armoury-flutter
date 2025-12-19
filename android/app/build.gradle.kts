plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // ✅ Apply the Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ✅ Required for using newer Java features (like Date/Time) on older Android versions
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        
        // ✅ For Firebase, 21 is the recommended minimum to avoid MultiDex issues
        minSdk = flutter.minSdkVersion 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ Required because Firebase adds a lot of methods to your app
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // ✅ For a real APK, you usually use a release signing config.
            // Keeping "debug" for now so you can build without creating a keystore file.
            signingConfig = signingConfigs.getByName("debug")
            
            // ✅ Optimization settings
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BoM - Manages versions for all Firebase libraries automatically
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    
    // ✅ Core Library Desugaring - Needed for older device compatibility
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}
