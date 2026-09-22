import 'package:flutter/widgets.dart';
// La branche est choisie a la compilation : un fichier la ou `dart:io` existe,
// une adresse dans un navigateur, qui n'a pas de disque.
import 'package:grisbie/ui/widgets/local_image_provider_web.dart'
    if (dart.library.io) 'package:grisbie/ui/widgets/local_image_provider_io.dart';

/// D'ou vient une illustration du contenu : du bundle, ou du disque.
///
/// **Les assets sont scelles au build.** Une image que l'auteur vient
/// d'ajouter sur son telephone n'est pas dans le bundle, et n'y sera qu'apres
/// un commit et une recompilation. Pendant l'edition elle vit donc sur le
/// disque ; le jeu livre, lui, ne lit que le bundle.
///
/// La regle est le prefixe : un chemin de contenu commence toujours par
/// `assets/` — c'est ainsi qu'il est ecrit dans les fichiers d'aventure. Une
/// adresse — `http://`, `https://`, `blob:` — se lit sur le reseau. Tout le
/// reste est un fichier local, et **« local » n'a pas le meme sens partout** :
/// un fichier sur un appareil, une adresse dans un navigateur, qui n'a pas de
/// disque.
///
/// **Une seule fonction tranche**, pour les quatre endroits qui affichent une
/// image : la scene de jeu, le calage des zones, la page de garde et les
/// moments de recit. Deux regles separees finiraient par diverger, et l'auteur
/// calerait ses zones sur une image que le jeu ne montre pas.
ImageProvider contentImageProvider(String path) {
  if (path.startsWith('assets/')) return AssetImage(path);
  if (_isAddress(path)) return NetworkImage(path);
  return localImageProvider(path);
}

/// Vrai si le chemin designe quelque chose qu'on va chercher sur le reseau.
///
/// L'image choisie dans un navigateur porte une adresse `blob:` ; celle qui
/// vient d'un stockage distant, une adresse `https:`. Les deux se lisent de la
/// meme facon, et depuis n'importe quelle plateforme.
bool _isAddress(String path) {
  return path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('blob:');
}

/// Affiche une illustration du contenu, d'ou qu'elle vienne.
///
/// Remplace `Image.asset`, qui ne sait lire que le bundle.
class ContentImage extends StatelessWidget {
  const ContentImage({
    required this.path,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
    super.key,
  });

  final String path;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: contentImageProvider(path),
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
    );
  }
}
