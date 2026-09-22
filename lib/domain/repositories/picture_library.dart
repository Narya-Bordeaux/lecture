/// Choisir une illustration et la ranger dans le contenu.
///
/// Une interface parce que le choix suppose un appareil et un greffon, alors
/// que tout ce qui s'en sert doit s'eprouver sans l'un ni l'autre. L'outil
/// d'auteur en recoit une par constructeur ; les tests en passent une fausse.
///
/// **Nulle quand il n'y a nulle part de durable ou ranger l'image** : le
/// bouton ne parait pas et le champ reste saisissable au clavier. C'est le cas
/// d'un navigateur non connecte au depot — un onglet n'a pas de disque, et
/// l'image n'y survivrait pas a la seconde qui suit.
///
/// Volontairement sans dependance a Flutter.
abstract class PictureLibrary {
  /// Demande une image, la range dans le contenu, et rend son chemin.
  ///
  /// Le chemin est **relatif au dossier du contenu** (`pictures/gare_….jpg`),
  /// comme celui d'un fichier d'aventure : une illustration est du contenu, et
  /// voyage dans le meme arbre.
  ///
  /// Rend `null` si l'auteur renonce.
  ///
  /// [baseName] nomme le fichier range : l'identifiant du lieu, en pratique.
  Future<String?> pickPicture({required String baseName});
}
