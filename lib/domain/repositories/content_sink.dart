import 'dart:typed_data';

/// Ou vont les fichiers de contenu que l'on enregistre.
///
/// Symetrique de `ContentSource`, et abstraite pour la meme raison : ecrire du
/// contenu doit s'eprouver sans Flutter ni appareil. L'outil d'auteur ecrit
/// dans un dossier de l'appareil ou sur le depot distant, les tests
/// recueillent en memoire.
///
/// Les assets d'une application sont scelles au moment du build et ne peuvent
/// pas etre reecrits : une implementation branchee sur `assets/` n'existerait
/// donc pas.
abstract class ContentSink {
  /// Enregistre [contents] sous [path], relatif au dossier du contenu.
  Future<void> writeFile(String path, String contents);

  /// Enregistre des octets sous [path], relatif au dossier du contenu.
  ///
  /// **Une illustration est du contenu**, au meme titre qu'un JSON : elle vit
  /// dans le meme arbre, part par le meme puits et redescend avec lui. Sans
  /// cela, le pont entre le poste et le telephone ne portait que du texte, et
  /// une image choisie ne quittait jamais l'appareil ou le navigateur.
  Future<void> writeBytes(String path, Uint8List bytes);
}
