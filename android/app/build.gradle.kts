import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ginger.sushruta"
    compileSdk = 36
    // Highest NDK required across plugins is 28.2.13676358 (jni).
    // All other plugins request 27.0.12077973 and are forward-compatible.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    lint {
        disable += "NullSafeMutableLiveData"
        checkReleaseBuilds = false
    }

    defaultConfig {
        applicationId = "com.ginger.sushruta"
        minSdk = 29
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add 16 KB page size support
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    // Add packaging options for 16 KB page size support
    packagingOptions {
        jniLibs {
            useLegacyPackaging = false
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
//    buildTypes {
//        release {
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")

//    // Correct Kotlin DSL syntax for PSPDFKit with exclusion
//    implementation("com.pspdfkit:pspdfkit:8.4.1") {
//        exclude(group = "io.nutrient", module = "nutrient")
//    }
}

// Add ProGuard rules to keep necessary classes
tasks.register("createProguardRules") {
    doLast {
        file("proguard-rules.pro").writeText("""
            -keep class com.google.android.play.core.** { *; }
            -keep class com.google.android.play.core.splitcompat.** { *; }
            -keep class com.google.android.play.core.splitinstall.** { *; }
            -keep class com.google.android.play.core.tasks.** { *; }
            -dontwarn com.google.android.play.core.**
            
            # Razorpay rules
            -keep class com.razorpay.** { *; }
            -dontwarn com.razorpay.**
            
            # ProGuard annotation rules
            -dontwarn proguard.annotation.Keep
            -dontwarn proguard.annotation.KeepClassMembers
        """.trimIndent())
    }
}

tasks.named("preBuild") {
    dependsOn("createProguardRules")
}
