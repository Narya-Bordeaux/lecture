import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/asset_content_source.dart';

/// D'ou vient une illustration : toujours du contenu.
///
/// **Une illustration est du contenu**, au meme titre qu'un fichier
/// d'aventure. Son chemin est donc relatif au dossier du contenu —
/// `pictures/gare_….jpg` — et c'est la **source** qui sait ou ce dossier se
/// trouve : le bundle pour le jeu, un dossier de l'appareil ou le depot
/// distant pour l'outil d'auteur.
///
/// C'est ce qui remplace les trois regles d'avant. L'image vivait alors a part
/// — un chemin de fichier sur l'appareil, une adresse `blob:` dans un
/// navigateur — et ne voyageait pas avec le contenu : prise sur le telephone,
/// elle n'arrivait jamais sur le poste ; choisie dans un onglet, elle
/// disparaissait avant d'etre affichee, le systeme revoquant l'adresse.
///
/// **Une seule fonction tranche**, pour les trois endroits qui affichent une
/// image : la scene de jeu, le calage des zones et la page de garde. Deux regles separees finiraient par diverger, et l'auteur
/// calerait ses zones sur une image que le jeu ne montre pas.
ImageProvider contentImageProvider(String path, {ContentSource? source}) {
  return ContentPictureImage(
    path,
    source: source ?? const AssetContentSource(),
  );
}

/// Une image lue par la source de contenu, comme n'importe quel fichier.
///
/// Un `ImageProvider` a part entiere, et non un `FutureBuilder` : c'est ce qui
/// la fait entrer dans le cache d'images de Flutter, qui indexe par egalite du
/// fournisseur. Sans cela, chaque reconstruction relirait les octets et
/// redecoderait l'image.
@immutable
class ContentPictureImage extends ImageProvider<ContentPictureImage> {
  const ContentPictureImage(this.path, {required this.source, this.scale = 1.0});

  /// Le chemin, relatif au dossier du contenu.
  final String path;

  /// D'ou viennent les fichiers : le bundle, l'appareil, le depot distant.
  ///
  /// Fait partie de l'identite du fournisseur : changer de source — se
  /// connecter au depot — doit bien redonner une autre image.
  final ContentSource source;

  final double scale;

  @override
  Future<ContentPictureImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ContentPictureImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ContentPictureImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: key.scale,
      debugLabel: key.path,
    );
  }

  Future<ui.Codec> _load(
    ContentPictureImage key,
    ImageDecoderCallback decode,
  ) async {
    final Uint8List bytes = await key.source.readBytes(key.path);
    if (bytes.isEmpty) {
      throw StateError('Illustration vide : "${key.path}".');
    }

    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    return other is ContentPictureImage &&
        other.path == path &&
        other.source == source &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(path, source, scale);

  @override
  String toString() => 'ContentPictureImage("$path")';
}

/// La raison d'un echec de lecture, lisible par l'auteur.
///
/// « Image introuvable » seul laissait chercher a l'aveugle : un refus du
/// depot, une coupure, un fichier absent ou illisible se ressemblaient tous.
/// L'outil d'auteur montre donc la raison reelle — tronquee, une pile d'appels
/// n'apprend rien de plus.
String describeImageError(Object error) {
  final text = '$error'.trim();
  return text.length <= 240 ? text : '${text.substring(0, 240)}…';
}

/// Affiche une illustration du contenu, d'ou qu'elle vienne.
///
/// Remplace `Image.asset`, qui ne sait lire que le bundle.
class ContentImage extends StatelessWidget {
  const ContentImage({
    required this.path,
    this.source,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
    super.key,
  });

  final String path;

  /// D'ou lire le contenu. Nulle, le bundle : c'est le cas du jeu.
  final ContentSource? source;

  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: contentImageProvider(path, source: source),
      fit: fit,
      alignment: alignment,
      errorBuilder: errorBuilder,
    );
  }
}
