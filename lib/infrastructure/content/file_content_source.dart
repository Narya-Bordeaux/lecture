import 'dart:io';

import 'package:grisbie/domain/repositories/content_file_not_found.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

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
  Future<String> readFile(String path) async {
    final file = File('$directory/$path');

    // Un fichier jamais ecrit est une **absence**, pas une panne : c'est ce
    // qui permet a `FallbackContentSource` de se replier sur le contenu livre
    // sans masquer un disque plein ou un dossier interdit.
    if (!await file.exists()) throw ContentFileNotFound(path);

    return file.readAsString();
  }
}
