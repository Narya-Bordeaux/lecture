/// Le rangement des illustrations : un sous-dossier par aventure.
///
/// Une aventure range ses images dans `pictures/<son identifiant>/` — celles
/// de « Grisbie va a la plage » dans `pictures/grisbie_plage/`. Toutes dans un
/// seul dossier, la liste devenait impossible a parcourir des qu'il y avait
/// plus d'une aventure. La racine de `pictures/` reste permise : une image
/// qui n'est encore a aucune aventure, ou qui sert a plusieurs.
///
/// Le dossier se deduit du chemin, rien ne le declare : un chemin d'image
/// reste un chemin comme un autre pour le jeu, qui le lit sans rien savoir de
/// ce rangement. Seul l'outil d'auteur s'en sert, pour ouvrir le choix sur
/// les images de l'aventure en cours.
abstract final class PictureFolder {
  /// Le dossier des illustrations, relatif au dossier du contenu.
  static const String directory = 'pictures/';

  /// Le « dossier » des images posees directement dans [directory].
  static const String root = '';

  /// Le dossier d'une image : `grisbie_plage` pour
  /// `pictures/grisbie_plage/maison.jpg`, [root] pour `pictures/bonjour.jpg`.
  static String of(String picturePath) {
    final relative = picturePath.startsWith(directory)
        ? picturePath.substring(directory.length)
        : picturePath;
    final separator = relative.lastIndexOf('/');
    return separator < 0 ? root : relative.substring(0, separator);
  }

  /// Le dossier propre a une aventure, tel qu'un chemin l'ecrit.
  static String pathFor(String adventureId) => '$directory$adventureId/';

  /// Les images regroupees par dossier : les dossiers par nom, la racine en
  /// dernier, et dans chacun les images par nom.
  static Map<String, List<String>> group(Iterable<String> picturePaths) {
    final byFolder = <String, List<String>>{};
    for (final path in picturePaths) {
      byFolder.putIfAbsent(of(path), () => <String>[]).add(path);
    }
    final folders = byFolder.keys.where((folder) => folder != root).toList()
      ..sort();
    if (byFolder.containsKey(root)) folders.add(root);
    return <String, List<String>>{
      for (final folder in folders) folder: byFolder[folder]!..sort(),
    };
  }
}
