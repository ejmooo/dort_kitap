import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Yükleme (upload) anahtarı android/key.properties'ten okunur. Bu dosya ve
// .jks anahtarı android/.gitignore'da; asla depoya girmemeli.
// Not: betik içinde `java` Gradle'ın java eklentisine çözülür, java paketine
// değil — bu yüzden Properties en üstte import ediliyor.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ejmo.dort_kitap"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications 10+ planlı bildirimler için desugaring
        // gerektiriyor; kapalıyken derleme checkDebugAarMetadata'da düşer.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Mağazada yayımlandıktan sonra DEĞİŞTİRİLEMEZ; değişirse Play bunu
        // yeni bir uygulama sayar ve mevcut kullanıcılar güncelleme alamaz.
        applicationId = "com.ejmo.dort_kitap"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Desugaring ile birlikte metot sayısı 64K sınırını aşabiliyor.
        multiDexEnabled = true
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
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
            // key.properties varsa yükleme anahtarıyla imzalanır. Yoksa debug
            // anahtarına düşer — `flutter run --release` yerelde çalışsın diye.
            // Debug imzalı bir paket Play Console'a YÜKLENEMEZ.
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
