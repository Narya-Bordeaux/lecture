import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/domain/repositories/picture_picker.dart';

/// Choisit une illustration et l'ecrit **dans l'arbre de contenu**.
///
/// C'est le point de bascule de la 0.28.0 : une image n'est plus rangee a
/// part, elle devient un fichier de contenu comme un autre. Elle part donc par
/// le meme puits que le JSON — dossier de l'appareil ou depot distant —, et
/// redescendra avec lui.
///
/// **Ce que cela repare, au passage** : dans un navigateur, l'image n'existait
/// que sous une adresse `blob:` que le systeme revoquait aussitot, et l'apercu
/// echouait sur-le-champ. Ecrite dans le contenu, elle se relit par la source,
/// comme tout le reste.
///
/// Sans dependance a une plateforme : le choix vient d'un [PicturePicker],
/// l'ecriture d'un [ContentSink]. Les deux s'eprouvent en memoire, ce que la
/// version precedente ne permettait pas.
class StoredPictureLibrary implements PictureLibrary {
  const StoredPictureLibrary({
    required this.picker,
    required this.sink,
    this.now = DateTime.now,
  });

  final PicturePicker picker;

  /// Ou va l'image : le meme puits que le reste du contenu.
  final ContentSink sink;

  /// Injectable pour que le nom produit soit previsible en test.
  final DateTime Function() now;

  /// Le dossier des illustrations, relatif au dossier du contenu.
  static const String directory = 'pictures';

  @override
  Future<String?> pickPicture({required String baseName}) async {
    final picked = await picker.pick();
    if (picked == null) return null;

    final path = '$directory/${fileNameFor(
      baseName: baseName,
      sourceName: picked.fileName,
      now: now(),
    )}';

    await sink.writeBytes(path, picked.bytes);
    return path;
  }

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
    required String sourceName,
    required DateTime now,
  }) {
    // Un identifiant finit dans un nom de fichier : accents et espaces y sont
    // un vrai ennui. C'est la meme regle que pour les identifiants de lieux,
    // et elle n'existe donc qu'une fois.
    final safe = AdventureBuilder.slugify(baseName);
    return '${safe}_${now.millisecondsSinceEpoch}${extensionOf(sourceName)}';
  }

  /// L'extension du fichier choisi, ou `.jpg` a defaut.
  ///
  /// Une extension inconnue vaut mieux qu'aucune : elle porte le type du
  /// fichier jusqu'au depot, qui s'en sert pour le servir, et jusqu'au poste,
  /// ou un fichier sans suffixe se laisse mal ouvrir au moment de le commiter.
  static String extensionOf(String sourceName) {
    final dot = sourceName.lastIndexOf('.');
    final slash = sourceName.lastIndexOf('/');
    if (dot <= slash || dot == sourceName.length - 1) return '.jpg';

    final extension = sourceName.substring(dot).toLowerCase();
    return extension.length > 5 ? '.jpg' : extension;
  }
}
