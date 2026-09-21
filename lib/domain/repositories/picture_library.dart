/// Choisir une illustration dans l'appareil, et la garder.
///
/// Une interface parce que le choix suppose un appareil et un greffon, alors
/// que tout ce qui s'en sert doit s'eprouver sans l'un ni l'autre. L'outil
/// d'auteur en recoit une par constructeur ; les tests en passent une fausse.
///
/// Volontairement sans dependance a Flutter : c'est l'implementation qui sait
/// ouvrir une photothegue.
abstract class PictureLibrary {
  /// Demande une image, la range durablement, et rend son chemin.
  ///
  /// Rend `null` si l'auteur renonce — refermer le selecteur est un geste
  /// normal, pas une panne.
  ///
  /// [baseName] nomme le fichier range : l'identifiant du lieu, en pratique.
  Future<String?> pickPicture({required String baseName});
}
