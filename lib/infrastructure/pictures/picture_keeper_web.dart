/// Ranger une image choisie, la ou il n'y a pas de disque.
///
/// Pendant de `picture_keeper_io.dart`, choisi a la compilation. Dans un
/// navigateur, le selecteur rend une adresse `blob:` que `contentImageProvider`
/// sait deja afficher : il n'y a **rien a recopier**, et nulle part ou le
/// faire.
///
/// La recopie n'y aurait de toute facon pas d'objet : ce qu'elle protege sur un
/// appareil, c'est un fichier de cache qu'Android peut purger.
library;

/// Faux : l'adresse `blob:` meurt avec l'onglet.
///
/// L'ecran le dit a l'auteur, plutot que de le laisser decouvrir un lieu sans
/// illustration en rouvrant son aventure. Le calage, lui, survit — ce sont des
/// fractions rangees dans le JSON.
const bool keepsPictures = false;

/// Rend l'adresse telle quelle : elle est deja ce qu'on peut garder.
Future<String> keepPicture(String pickedPath, {required String baseName}) async {
  return pickedPath;
}
