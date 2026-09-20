/// D'ou viennent les fichiers de contenu.
///
/// Abstraite pour que le chargement soit testable sans Flutter : le jeu lit
/// les fichiers embarques dans l'application, les tests les lisent sur le
/// disque ou les fabriquent en memoire.
abstract class ContentSource {
  /// Le contenu du fichier designe par [path], relatif au dossier du contenu.
  Future<String> readFile(String path);
}
