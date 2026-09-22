import 'dart:typed_data';

/// D'ou viennent les fichiers de contenu.
///
/// Abstraite pour que le chargement soit testable sans Flutter : le jeu lit
/// les fichiers embarques dans l'application, les tests les lisent sur le
/// disque ou les fabriquent en memoire.
///
/// Un fichier absent se signale par `ContentFileNotFound`, jamais par une
/// erreur quelconque : c'est ce qui permet a `FallbackContentSource` de se
/// replier sans masquer une panne.
abstract class ContentSource {
  /// Le contenu du fichier designe par [path], relatif au dossier du contenu.
  Future<String> readFile(String path);

  /// Les octets du fichier designe par [path].
  ///
  /// Pendant de `ContentSink.writeBytes` : une illustration se lit par la meme
  /// source que le reste du contenu, ce qui evite une seconde regle pour
  /// decider d'ou vient une image.
  Future<Uint8List> readBytes(String path);
}
