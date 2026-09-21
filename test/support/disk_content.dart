import 'dart:io';

import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/models/content_index.dart';
import 'package:reading_game/domain/repositories/adventure_repository.dart';
import 'package:reading_game/domain/repositories/content_source.dart';
import 'package:reading_game/infrastructure/content/content_repository.dart';

/// Lit les fichiers de contenu sur le disque, comme le ferait un auteur.
///
/// Les tests portant sur le contenu reel n'ont pas acces au bundle de
/// l'application : ils lisent les memes fichiers, directement.
class DiskContentSource implements ContentSource {
  const DiskContentSource({this.basePath = 'assets/content'});

  final String basePath;

  @override
  Future<String> readFile(String path) {
    return File('$basePath/$path').readAsString();
  }
}

/// Le depot branche sur les fichiers livres.
ContentRepository buildDiskRepository() {
  return ContentRepository(source: const DiskContentSource());
}

/// L'aventure livree, mots et personnages resolus.
Future<Adventure> loadRealAdventure([String id = 'grisbie_plage']) {
  return buildDiskRepository().loadAdventure(id);
}

/// Sert une aventure deja chargee, sans toucher au disque.
///
/// Indispensable dans un test de widget : `pumpAndSettle` fait avancer une
/// horloge virtuelle, mais n'attend pas les entrees-sorties reelles. Un depot
/// qui lit des fichiers pendant le rendu laisse le test tourner sans fin.
class PreloadedAdventureRepository implements AdventureRepository {
  PreloadedAdventureRepository(this.adventure);

  final Adventure adventure;

  @override
  Future<ContentIndex> loadIndex() async {
    return ContentIndex(
      lexiconFiles: const <String>[],
      adventures: <AdventureEntry>[
        AdventureEntry(
          id: adventure.id,
          title: adventure.title,
          file: 'memoire',
        ),
      ],
    );
  }

  @override
  Future<Adventure> loadAdventure(String adventureId) async => adventure;
}
