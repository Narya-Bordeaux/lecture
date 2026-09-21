import 'dart:io';

import 'package:grisbie/domain/repositories/content_sink.dart';

/// Enregistre le contenu dans un dossier du systeme de fichiers.
///
/// C'est la moitie locale de l'outil d'auteur : le dossier de travail sur
/// l'appareil, ou un dossier du depot sur un poste. Un depot distant se
/// branche de la meme facon, par une autre implementation de [ContentSink] :
/// l'arborescence est la meme, seuls les octets voyagent autrement.
class FileContentSink implements ContentSink {
  const FileContentSink({required this.directory});

  /// Le dossier racine du contenu, l'equivalent de `assets/content`.
  final String directory;

  @override
  Future<void> writeFile(String path, String contents) async {
    final file = File('$directory/$path');

    // Un dossier vierge n'a ni `adventures/` ni `lexicon/` : sans creation
    // prealable, la premiere aventure d'une installation neuve echouerait.
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }
}
