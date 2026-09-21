import 'dart:convert';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/content_repository.dart';
import 'package:grisbie/infrastructure/content/file_content_source.dart';

/// Lit les fichiers de contenu livres, comme le ferait un auteur.
///
/// Les tests portant sur le contenu reel n'ont pas acces au bundle de
/// l'application : ils lisent les memes fichiers, directement. La lecture
/// elle-meme vient de `FileContentSource`, pour qu'il n'y en ait qu'une
/// version.
class DiskContentSource extends FileContentSource {
  const DiskContentSource({String basePath = 'assets/content'})
      : super(directory: basePath);
}

/// Le depot branche sur les fichiers livres.
ContentRepository buildDiskRepository() {
  return ContentRepository(source: const DiskContentSource());
}

/// L'aventure livree, mots et personnages resolus.
Future<Adventure> loadRealAdventure([String id = 'grisbie_plage']) {
  return buildDiskRepository().loadAdventure(id);
}

/// Sert les fichiers livres, sauf ceux qu'on remplace.
///
/// Permet de recharger une aventure fraichement ecrite avec le lexique et les
/// personnages reels, sans avoir a les redeclarer.
class OverridingContentSource implements ContentSource {
  const OverridingContentSource({
    required this.overrides,
    this.base = const DiskContentSource(),
  });

  final Map<String, String> overrides;
  final ContentSource base;

  @override
  Future<String> readFile(String path) async {
    return overrides[path] ?? await base.readFile(path);
  }
}

/// Charge une aventure depuis un JSON donne, comme le ferait le jeu.
///
/// L'identifiant est lu dans le JSON lui-meme : c'est lui qui doit concorder
/// avec le sommaire, et s'en remettre a l'appelant masquerait l'erreur.
Future<Adventure> loadAdventureFrom({
  required String adventureJson,
  required String path,
}) {
  final id = (jsonDecode(adventureJson) as Map<String, dynamic>)['id'] as String;

  return ContentRepository(
    source: OverridingContentSource(
      overrides: <String, String>{path: adventureJson},
    ),
  ).loadAdventure(id);
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
