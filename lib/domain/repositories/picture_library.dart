/// Choisir une illustration, et la garder autant que la plateforme le permet.
///
/// Une interface parce que le choix suppose un appareil et un greffon, alors
/// que tout ce qui s'en sert doit s'eprouver sans l'un ni l'autre. L'outil
/// d'auteur en recoit une par constructeur ; les tests en passent une fausse.
///
/// Volontairement sans dependance a Flutter : c'est l'implementation qui sait
/// ouvrir une photothegue.
abstract class PictureLibrary {
  /// Demande une image, la range, et rend son chemin.
  ///
  /// Rend `null` si l'auteur renonce — refermer le selecteur est un geste
  /// normal, pas une panne.
  ///
  /// [baseName] nomme le fichier range : l'identifiant du lieu, en pratique.
  Future<String?> pickPicture({required String baseName});

  /// Vrai si l'image choisie survit a la fermeture de l'application.
  ///
  /// **Elle ne survit pas partout, et l'auteur doit le savoir avant de
  /// travailler.** Sur un appareil, l'image est recopiee dans un dossier a
  /// nous et se retrouve d'une session a l'autre. Dans un navigateur, elle
  /// tient a une adresse `blob:` qui meurt avec l'onglet : le calage, lui, est
  /// conserve, puisque ce sont des fractions rangees dans le JSON.
  ///
  /// C'est l'interface qui porte cette difference, et non `kIsWeb` consulte
  /// dans un widget : l'ecran n'a pas a savoir sur quoi il tourne, et un
  /// `kIsWeb` en dur ne s'eprouverait pas.
  bool get keepsPictures;
}
