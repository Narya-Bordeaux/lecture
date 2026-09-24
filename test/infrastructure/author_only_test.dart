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
        .where((entry) => entry.value.contains("package:path_provider/"))
        .map((entry) => entry.key)
        .toList()
      ..sort();

    // Ni le domaine, ni le moteur, ni l'interface, ni le point d'entree :
    // savoir ou ecrire est une affaire de plateforme. Tout le reste passe par
    // `ContentSink`.
    expect(
      importers,
      <String>['lib/infrastructure/content/device_content_folder.dart'],
    );
  });

  test('plus rien n\'ouvre la photothegue de l\'appareil', () {
    // Les images se choisissent dans le depot (0.37.0) : aucun code n'a plus
    // a lire les photos d'un appareil, dans l'outil comme dans le jeu.
    final importers = sources.entries
        .where((entry) => entry.value.contains('package:image_picker/'))
        .map((entry) => entry.key);

    expect(importers, isEmpty);
  });

  test('Firebase n\'est importe que par l\'infrastructure distante', () {
    final importers = sources.entries
        .where((entry) => entry.value.contains('package:firebase_'))
        .map((entry) => entry.key)
        .where((path) => !path.startsWith('lib/infrastructure/remote/'))
        .toList()
      ..sort();

    // Le jeu livre aux enfants ne contacte rien. Les greffons sont pourtant
    // embarques — le pubspec est partage — donc la garantie doit se verifier.
    expect(importers, isEmpty);
  });

  test('un seul fichier monte le depot distant, et c\'est l\'outil', () {
    final builders = sources.entries
        .where((entry) => entry.value.contains('AuthorRemote.connect('))
        .map((entry) => entry.key)
        .where((path) => path != 'lib/infrastructure/remote/author_remote.dart')
        .toList()
      ..sort();

    expect(builders, <String>['lib/main_author.dart']);
  });

  test('rien n\'initialise Firebase hors du montage du depot', () {
    // **C'est la garantie de fond.** Le montage prevu passait par
    // « google-services.json », qu'Android lit au demarrage sans qu'on le lui
    // demande : le jeu aurait contacte Firebase sans que personne ne l'appelle.
    // Des options explicites suppriment cette initialisation automatique, et ce
    // test verifie qu'un seul endroit initialise quoi que ce soit.
    final initialisers = sources.entries
        .where((entry) => entry.value.contains('Firebase.initializeApp'))
        .map((entry) => entry.key)
        .toList()
      ..sort();

    expect(initialisers, <String>['lib/infrastructure/remote/author_remote.dart']);
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
    expect(game, isNot(contains('author_sign_in_page')));
    expect(game, isNot(contains('infrastructure/remote/')));
  });
}
