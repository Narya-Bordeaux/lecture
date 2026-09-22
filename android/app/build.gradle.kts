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
        // Repris de « pubspec.yaml » : la version 0.23.0+38 donne versionName
        // « 0.23.0 » et versionCode 38. Le Play Store exige un versionCode
        // strictement croissant, d'ou la regle « jamais reinitialise » du
        // numero de build (voir docs/versions.md).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Deux paquets Android distincts, pour deux usages qui n'ont rien a voir.
    //
    // Le jeu va aux enfants et ne contacte rien. L'outil d'auteur tourne sur le
    // telephone de l'auteur et depose le contenu sur Firebase Storage. Sur
    // Android, le SDK Firebase s'initialise **tout seul** des que
    // « google-services.json » est present au build : sans cette separation, les
    // deux points d'entree partageant le meme dossier android/, la configuration
    // de l'outil partirait mecaniquement dans le jeu.
    //
    // Le fichier ne vit donc que dans « src/auteur/ », et rien d'autre ne le lit.
    //
    // Attention : une saveur ne choisit **pas** le point d'entree Dart. Les
    // commandes appariees sont dans « docs/Commandes.md » — elles ne sont pas
    // recopiees ici, deux descriptions du meme geste finiraient par diverger.
    // « main_author.dart » refuse de demarrer si l'appariement est faux, et le
    // suffixe ci-dessous protege l'autre sens : un jeu compile par erreur avec
    // la saveur auteur ne porte pas l'identifiant publie, il est donc
    // impubliable.
    //
    // Ce qui s'affiche sous l'icone n'est pas ici : chaque saveur apporte son
    // « app_name » par un fichier de ressources, « src/<saveur>/res/values/
    // strings.xml », que le manifeste lit via @string/app_name.
    //
    // Ces libelles ont d'abord ete ecrits en « resValue » dans ce fichier. AGP 9
    // desactive cette fonctionnalite par defaut et refuse alors de configurer le
    // projet : « Product Flavor jeu contains custom resource values, but the
    // feature is disabled ». Plutot que de rallumer un drapeau que les versions
    // suivantes d'AGP eteindront encore, les libelles sont passes en ressources
    // — le recouvrement par saveur est le mecanisme Android le plus stable, et
    // un libelle d'application **est** une ressource.
    flavorDimensions += "usage"
    productFlavors {
        create("jeu") {
            dimension = "usage"
        }
        create("auteur") {
            dimension = "usage"
            // fr.naryabordeaux.grisbie.auteur : un autre paquet Android, donc
            // les deux applications cohabitent sur le telephone de l'auteur.
            // C'est cet identifiant-la qui est enregistre dans Firebase, jamais
            // celui du jeu — Firebase apparie sur l'applicationId exact.
            applicationIdSuffix = ".auteur"
            versionNameSuffix = "-auteur"
        }
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
