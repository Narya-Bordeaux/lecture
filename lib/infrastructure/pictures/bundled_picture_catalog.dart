import 'package:flutter/services.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';

/// Les illustrations embarquees avec l'application, lues dans son manifeste.
///
/// L'outil d'auteur se compile a partir du depot, comme le jeu : il embarque
/// donc exactement les images que le jeu aura. Une image versee dans
/// `assets/content/pictures/` apparait ici a la compilation suivante.
class BundledPictureCatalog implements PictureCatalog {
  const BundledPictureCatalog({this.bundle});

  /// Le bundle a lire. Nul, celui de l'application.
  final AssetBundle? bundle;

  /// Le dossier des illustrations dans le bundle.
  static const String bundleDirectory = 'assets/content/pictures/';

  /// Ce qui precede un chemin de contenu dans le bundle.
  static const String contentRoot = 'assets/content/';

  @override
  Future<List<String>> listPictures() async {
    final manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );
    return picturesIn(manifest.listAssets());
  }

  /// Retient les illustrations parmi les cles du bundle, en chemins de
  /// contenu tries par nom.
  static List<String> picturesIn(Iterable<String> assetKeys) {
    return assetKeys
        .where((key) => key.startsWith(bundleDirectory))
        .map((key) => key.substring(contentRoot.length))
        .toList()
      ..sort();
  }
}
