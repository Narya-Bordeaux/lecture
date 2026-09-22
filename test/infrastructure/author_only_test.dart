import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ce qui ne doit exister que dans l'outil d'auteur.
///
/// Les deux points d'entree partagent `pubspec.yaml` : les greffons de l'outil
/// sont donc **embarques dans le jeu**, qu'il les appelle ou non. Le jeu est
/// destine a des enfants et n'emet rien ; la garantie ne peut pas tenir a la
/// seule bonne volonte, elle doit se verifier.
///
/// Meme raison que pour `google-services.json`, dont
/// `android_packaging_test.dart` interdit toute copie hors de la saveur auteur.

/// Tous les fichiers Dart de `lib/`, avec leur contenu.
Map<String, String> readLibrarySources() {
  final sources = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    sources[entity.path.replaceAll(r'\', '/')] = entity.readAsStringSync();
  }
  return sources;
}

void main() {
  late Map<String, String> sources;

  setUpAll(() => sources = readLibrarySources());

  test('les greffons ne sont importes que par l\'infrastructure dediee', () {
    final importers = sources.entries
        .where((entry) =>
            entry.value.contains("package:image_picker/") ||
            entry.value.contains("package:path_provider/"))
        .map((entry) => entry.key)
        .toList()
      ..sort();

    // Ni le domaine, ni le moteur, ni l'interface, ni le point d'entree :
    // choisir une image et savoir ou ecrire sont des affaires de plateforme.
    // Tout le reste passe par `PictureLibrary` et `ContentSink`.
    expect(
      importers,
      <String>[
        'lib/infrastructure/content/device_content_sink.dart',
        'lib/infrastructure/pictures/device_picture_library.dart',
      ],
    );
  });

  test('un seul fichier construit la photothegue, et c\'est l\'outil', () {
    final builders = sources.entries
        .where((entry) => entry.value.contains('DevicePictureLibrary('))
        .map((entry) => entry.key)
        .where((path) => path != 'lib/infrastructure/pictures/device_picture_library.dart')
        .toList()
      ..sort();

    // Le jeu n'a aucun chemin vers la photothegue de l'appareil : personne ne
    // la lui passe, et il ne sait pas la fabriquer.
    expect(builders, <String>['lib/main_author.dart']);
  });

  test('le jeu ne mene pas aux ecrans d\'auteur', () {
    // `main.dart` ouvre l'aventure, et rien d'autre. Un import d'ecran
    // d'auteur signalerait un bouton cache — ou un geste a decouvrir par
    // megarde, ce que ce projet refuse.
    final game = sources['lib/main.dart']!;

    expect(game, isNot(contains('author_home_page')));
    expect(game, isNot(contains('outline_page')));
    expect(game, isNot(contains('area_editor_page')));
    expect(game, isNot(contains('stage_editor_page')));
  });
}
