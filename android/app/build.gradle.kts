import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cle de signature de la version publiee.
//
// Ni la cle ni ses mots de passe n'entrent dans le depot : « key.properties » et
// les magasins de cles sont ignores par git. Le modele des quatre lignes
// attendues est dans « android/key.properties.example ».
//
// Fichier absent — session cloud, poste d'un contributeur — on retombe sur la
// cle de debug, pour que « flutter build apk --release » reste possible. Un
// paquet ainsi signe s'installe sur un appareil mais **ne peut pas etre publie**
// sur le Play Store.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    // Identifiant definitif de l'application.
    //
    // Il est grave au marbre a la premiere publication : le Play Store ne permet
    // plus de le changer ensuite, une autre valeur serait une autre application,
    // sans ses installations ni ses avis.
    namespace = "fr.naryabordeaux.grisbie"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "fr.naryabordeaux.grisbie"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Repris de « pubspec.yaml » : la version 0.9.3+19 donne versionName
        // « 0.9.3 » et versionCode 19. Le Play Store exige un versionCode
        // strictement croissant, d'ou la regle « jamais reinitialise » du
        // numero de build (voir docs/versions.md).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
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

flutter {
    source = "../.."
}
