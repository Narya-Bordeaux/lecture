import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifie ce que l'application Android annoncera une fois publiee.
///
/// Aucun build Android n'est possible en session cloud, et ces valeurs ne sont
/// lues par aucun code Dart : rien d'autre ne les regarde. Elles sont pourtant
/// les plus coûteuses du projet a corriger — l'identifiant d'application est
/// definitif des la premiere publication sur le Play Store.
///
/// La table de verite des noms est dans `docs/Noms_et_identifiants.md`. Ce test
/// en est le controle : changer un nom ici sans l'y reporter, ou l'inverse,
/// fait echouer la suite.

/// L'identifiant definitif de l'application Android.
const String expectedApplicationId = 'fr.naryabordeaux.grisbie';

/// Ce qui s'affiche sous l'icone, sur l'ecran d'accueil de l'appareil.
///
/// A ne pas confondre avec le nom de la fiche Play Store, « Les Aventures de
/// Grisbie », qui se saisit dans la console et ne figure pas dans le depot.
const String expectedLauncherLabel = 'Grisbie';

void main() {
  group('Identite de l\'application Android', () {
    late String buildGradle;

    setUpAll(() {
      buildGradle = File('android/app/build.gradle.kts').readAsStringSync();
    });

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

    test('le libelle sous l\'icone est celui decide', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(
        manifest,
        contains('android:label="$expectedLauncherLabel"'),
        reason: 'Le libelle du manifeste s\'affiche tel quel sur l\'ecran '
            'd\'accueil. Le nom genere par le modele Flutter y apparaitrait.',
      );
    });
  });

  group('Ce que le jeu livre aux enfants ne doit pas contenir', () {
    test('aucun google-services.json n\'est present dans android/', () {
      // Sur Android, le SDK Firebase s'initialise **tout seul** des que ce
      // fichier est present au build, et enregistre un identifiant d'appareil
      // aupres de Google. Le public etant mineur et la decision du projet etant
      // qu'aucune donnee ne quitte l'appareil, le jeu livre ne doit en aucun
      // cas l'embarquer.
      //
      // Tant que le projet n'a pas de saveurs Gradle, les deux points d'entree
      // partagent le meme dossier android/ : le fichier ne peut donc exister
      // nulle part. Le jour ou une saveur « auteur » existera, ce test devra
      // n'autoriser que son dossier — et non etre supprime.
      final found = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'))
          .where((path) => path.endsWith('google-services.json'))
          .toList();

      expect(
        found,
        isEmpty,
        reason: 'Firebase s\'initialiserait seul dans le jeu des enfants, qui '
            'contacterait alors un serveur :\n${found.join('\n')}\n'
            'Voir docs/Noms_et_identifiants.md.',
      );
    });
  });
}
