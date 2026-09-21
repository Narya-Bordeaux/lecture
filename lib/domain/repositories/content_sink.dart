/// Ou vont les fichiers de contenu que l'on enregistre.
///
/// Symetrique de `ContentSource`, et abstraite pour la meme raison : ecrire du
/// contenu doit s'eprouver sans Flutter ni appareil. L'outil d'auteur ecrit
/// dans un dossier de l'appareil, les tests recueillent en memoire.
///
/// Les assets d'une application sont scelles au moment du build et ne peuvent
/// pas etre reecrits : une implementation branchee sur `assets/` n'existerait
/// donc pas.
abstract class ContentSink {
  /// Enregistre [contents] sous [path], relatif au dossier du contenu.
  Future<void> writeFile(String path, String contents);
}
