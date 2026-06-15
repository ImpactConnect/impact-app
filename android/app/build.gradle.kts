plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase support
}

android {
    namespace = "com.impactconnect.app"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.impactconnect.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 7
        versionName = "1.0.3"
        multiDexEnabled = true
        ndk {
            ndkVersion = "26.1.10909125"
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("../../release.keystore")
            storePassword = "07032196863"
            keyAlias = "release"
            keyPassword = "07032196863"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

android {
    dexOptions {
        javaMaxHeapSize = "4g"
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {

    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-base:18.3.0")
    implementation("com.google.android.gms:play-services-basement:18.3.0")
    implementation("com.google.android.gms:play-services-ads:22.6.0") // Google Mobile Ads
}
