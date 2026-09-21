import 'dart:io';

import 'package:grisbie/application/adventure_builder.dart';

/// Range les images choisies dans l'appareil, sous un nom stable.
///
/// Le selecteur d'images rend un fichier **de cache**, qu'Android peut purger
/// a tout moment. Le garder tel quel ferait disparaitre l'illustration en cours
/// de session, sans que rien ne l'explique : elle est donc recopiee ici.
///
/// Separe du selecteur lui-meme pour etre eprouvable : choisir une image
/// suppose un appareil et un greffon, la ranger ne suppose qu'un disque.
class PictureStore {
  const PictureStore({required this.directory});

  /// Le dossier ou vivent les images en cours d'edition.
  ///
  /// Ce n'est pas `assets/pictures/` — les assets sont scelles au build. C'est
  /// une etape intermediaire, jusqu'a ce que l'image soit commitee dans le
  /// depot.
  final String directory;

  /// Le nom sous lequel ranger une image.
  ///
  /// L'identifiant du lieu, un horodatage, et l'extension de la source.
  ///
  /// **L'horodatage n'est pas une precaution de style.** Sans lui, choisir une
  /// autre photo pour le meme lieu ecrirait au meme chemin ; le cache d'images
  /// de Flutter, qui indexe par chemin, continuerait d'afficher l'ancienne, et
  /// le geste paraitrait sans effet.
  static String fileNameFor({
    required String baseName,
    required String sourcePath,
    required DateTime now,
  }) {
    // Un identifiant finit dans un nom de fichier : accents et espaces y sont
    // un vrai ennui. C'est la meme regle que pour les identifiants de lieux,
    // et elle n'existe donc qu'une fois.
    final safe = AdventureBuilder.slugify(baseName);
    return '${safe}_${now.millisecondsSinceEpoch}${_extensionOf(sourcePath)}';
  }

  /// L'extension du fichier source, ou `.jpg` a defaut.
  ///
  /// Une extension inconnue vaut mieux qu'aucune : un fichier sans suffixe se
  /// laisse mal ouvrir sur un poste, au moment de le commiter.
  static String _extensionOf(String sourcePath) {
    final dot = sourcePath.lastIndexOf('.');
    final slash = sourcePath.lastIndexOf('/');
    if (dot <= slash || dot == sourcePath.length - 1) return '.jpg';

    final extension = sourcePath.substring(dot).toLowerCase();
    return extension.length > 5 ? '.jpg' : extension;
  }

  /// Copie l'image et rend le chemin de la copie.
  ///
  /// On **copie**, on ne deplace pas : le fichier d'origine appartient a la
  /// photothegue de l'auteur, et le lui prendre serait une surprise.
  Future<String> store(String sourcePath, {required String baseName}) async {
    final target = Directory(directory);
    // Une installation neuve n'a pas ce dossier : sans creation prealable, la
    // premiere image choisie echouerait.
    await target.create(recursive: true);

    final name = fileNameFor(
      baseName: baseName,
      sourcePath: sourcePath,
      now: DateTime.now(),
    );
    final stored = await File(sourcePath).copy('$directory/$name');

    return stored.path;
  }
}
