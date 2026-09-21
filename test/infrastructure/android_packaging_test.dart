import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/main_author.dart';

/// Verifie ce que les paquets Android annonceront une fois construits.
///
/// Aucun build Android n'est possible en session cloud, et ces valeurs ne sont
/// lues par aucun code Dart : rien d'autre ne les regarde. Elles sont pourtant
/// les plus coûteuses du projet a corriger — l'identifiant d'application est
/// definitif des la premiere publication sur le Play Store.
///
/// **Portee de ce test** : il lit des fichiers, il ne lance pas Gradle. Il
/// attrape un nom qui derive, un fichier egare, une saveur mal ecrite ; il ne
/// prouve pas que le projet Android compile. Seul un build sur un poste equipe
/// le dira.
///
/// La table de verite des noms est dans `docs/Noms_et_identifiants.md`.

/// L'identifiant definitif de l'application publiee.
const String expectedApplicationId = 'fr.naryabordeaux.grisbie';

/// Le suffixe qui distingue le paquet de l'outil d'auteur.
///
/// Il fait de l'outil une autre application Android : les deux cohabitent sur
/// le telephone, et c'est cet identifiant suffixe qui est enregistre dans
/// Firebase. Consequence recherchee : le jeu compile par erreur avec la saveur
/// auteur ne porte pas l'identifiant publie, il est donc impubliable.
const String authorApplicationIdSuffix = '.auteur';

/// La saveur du jeu livre aux enfants.
const String gameFlavor = 'jeu';

/// Le seul dossier ou `google-services.json` a le droit d'exister.
const String authorSourceSet = 'android/app/src/auteur';

void main() {
  late String buildGradle;

  setUpAll(() {
    buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
  });

  group('Identite de l\'application Android', () {
    test('l\'identifiant d\'application est celui qui sera publie', () {
      expect(
        buildGradle,
        contains('applicationId = "$expectedApplicationId"'),
        reason: 'Le Play Store n\'autorise aucun changement d\'identifiant '
            'apres la premiere publication : une autre valeur serait une autre '
            'application, sans ses installations ni ses avis.',
      );
    });

    test('le namespace suit l\'identifiant', () {
      // Divergents, le dossier Kotlin et la classe generee R ne se trouvent
      // plus : la compilation Android echoue, mais seulement sur l'appareil.
      expect(buildGradle, contains('namespace = "$expectedApplicationId"'));
    });

    test('la classe MainActivity est dans le paquet correspondant', () {
      final path = 'android/app/src/main/kotlin/'
          '${expectedApplicationId.replaceAll('.', '/')}/MainActivity.kt';
      final activity = File(path);

      expect(
        activity.existsSync(),
        isTrue,
        reason: 'MainActivity.kt est attendue en "$path".',
      );
      expect(
        activity.readAsStringSync(),
        contains('package $expectedApplicationId'),
      );
    });

    test('le libelle sous l\'icone vient des saveurs', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      // Le manifeste ne porte plus de libelle en dur : chaque saveur nomme son
      // application, sans quoi les deux icones seraient indiscernables sur
      // l'ecran d'accueil de l'auteur.
      expect(manifest, contains('android:label="@string/app_name"'));
      expect(buildGradle, contains('resValue("string", "app_name", "Grisbie")'));
      expect(
        buildGradle,
        contains('resValue("string", "app_name", "Grisbie auteur")'),
      );
    });
  });

  group('Separation du jeu et de l\'outil d\'auteur', () {
    test('les deux saveurs sont declarees dans la meme dimension', () {
      expect(buildGradle, contains('flavorDimensions += "usage"'));
      expect(buildGradle, contains('create("$gameFlavor")'));
      expect(
        buildGradle,
        contains('create("$authorFlavor")'),
        reason: 'La saveur attendue par lib/main_author.dart est '
            '"$authorFlavor" : le point d\'entree et le build doivent nommer '
            'la meme chose.',
      );
      // Une saveur sans dimension fait echouer la configuration Gradle.
      expect('dimension = "usage"'.allMatches(buildGradle).length, 2);
    });

    test('seule la saveur auteur porte un suffixe d\'identifiant', () {
      expect(
        buildGradle,
        contains('applicationIdSuffix = "$authorApplicationIdSuffix"'),
        reason: 'Sans suffixe, l\'outil d\'auteur remplacerait le jeu a '
            'l\'installation, et un build dépareillé donnerait un jeu '
            'publiable qui contacte Google.',
      );
      expect(
        'applicationIdSuffix'.allMatches(buildGradle).length,
        1,
        reason: 'Le jeu doit garder l\'identifiant nu : suffixe, il ne serait '
            'plus l\'application publiee.',
      );
    });

    test('le dossier de la saveur auteur existe', () {
      // Sans lui, il n'y a nulle part ou deposer « google-services.json », et
      // le test suivant refuserait le fichier partout.
      expect(
        Directory(authorSourceSet).existsSync(),
        isTrue,
        reason: 'Dossier attendu : "$authorSourceSet".',
      );
    });
  });

  group('Ce que le jeu livre aux enfants ne doit pas contenir', () {
    test('google-services.json ne vit que dans la saveur auteur', () {
      // Sur Android, le SDK Firebase s'initialise **tout seul** des que ce
      // fichier est present au build, et enregistre un identifiant d'appareil
      // aupres de Google. Le public etant mineur et la decision du projet etant
      // qu'aucune donnee ne quitte l'appareil, la saveur « jeu » ne doit en
      // aucun cas l'embarquer.
      final stray = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.endsWith('google-services.json'))
          .where((path) => path != '$authorSourceSet/google-services.json')
          .toList();

      expect(
        stray,
        isEmpty,
        reason: 'Firebase s\'initialiserait seul dans le jeu des enfants, qui '
            'contacterait alors un serveur :\n${stray.join('\n')}\n'
            'Seul "$authorSourceSet/" est autorise. '
            'Voir docs/Noms_et_identifiants.md.',
      );
    });
  });
}
