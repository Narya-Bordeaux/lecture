import 'dart:io';

import 'package:reading_game/domain/repositories/content_source.dart';

/// Lit le contenu depuis un dossier du systeme de fichiers.
///
/// Pendant de [FileContentSink] : l'outil d'auteur doit pouvoir relire ce
/// qu'il vient d'enregistrer, ce que la source branchee sur les assets ne
/// permet pas — ceux-ci sont scelles au moment du build.
class FileContentSource implements ContentSource {
  const FileContentSource({required this.directory});

  /// Le dossier racine du contenu, l'equivalent de `assets/content`.
  final String directory;

  @override
  Future<String> readFile(String path) {
    return File('$directory/$path').readAsString();
  }
}
