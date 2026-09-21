import 'dart:io';

import 'package:flutter/widgets.dart';

/// D'ou vient une illustration du contenu : du bundle, ou du disque.
///
/// **Les assets sont scelles au build.** Une image que l'auteur vient
/// d'ajouter sur son telephone n'est pas dans le bundle, et n'y sera qu'apres
/// un commit et une recompilation. Pendant l'edition elle vit donc sur le
/// disque ; le jeu livre, lui, ne lit que le bundle.
///
/// La regle est le prefixe : un chemin de contenu commence toujours par
/// `assets/` — c'est ainsi qu'il est ecrit dans les fichiers d'aventure — et
/// tout le reste est un chemin de fichier.
///
/// **Une seule fonction tranche**, pour les quatre endroits qui affichent une
/// image : la scene de jeu, le calage des zones, la page de garde et les
/// moments de recit. Deux regles separees finiraient par diverger, et l'auteur
/// calerait ses zones sur une image que le jeu ne montre pas.
ImageProvider contentImageProvider(String path) {
  if (path.startsWith('assets/')) return AssetImage(path);
  return FileImage(File(path));
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
