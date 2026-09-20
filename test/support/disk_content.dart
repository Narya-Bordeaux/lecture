import 'dart:io';

import 'package:reading_game/domain/models/adventure.dart';
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
Future<Adventure> loadRealAdventure([String id = 'grisbie_beach']) {
  return buildDiskRepository().loadAdventure(id);
}
