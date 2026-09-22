import 'package:flutter/material.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Fournit les dimensions reelles d'une illustration, une fois le fichier
/// decode.
///
/// Extrait pour n'exister qu'une fois : la scene de jeu et l'outil de calage
/// des zones doivent placer les cadres au meme endroit, au pixel pres. Deux
/// resolutions separees finiraient par diverger, et l'auteur calerait ses zones
/// sur une geometrie qui n'est pas celle du jeu.
///
/// [builder] recoit `null` tant que l'image n'est pas decodee, et lorsqu'elle
/// est absente : une illustration manquante ne doit pas empecher de jouer.
///
/// L'illustration vient du bundle ou du disque selon son chemin — voir
/// [contentImageProvider]. Pendant l'edition elle n'est pas encore dans le
/// bundle, et le calage doit pourtant deja fonctionner dessus.
class BackgroundImageSize extends StatefulWidget {
  const BackgroundImageSize({
    required this.builder,
    this.asset,
    this.source,
    super.key,
  });

  /// Chemin de l'illustration, relatif au dossier du contenu.
  final String? asset;

  /// D'ou lire le contenu. Nulle, le bundle : c'est le cas du jeu.
  final ContentSource? source;
  final Widget Function(BuildContext context, Size? imageSize) builder;

  @override
  State<BackgroundImageSize> createState() => _BackgroundImageSizeState();
}

class _BackgroundImageSizeState extends State<BackgroundImageSize> {
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(BackgroundImageSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset || oldWidget.source != widget.source) {
      _imageSize = null;
      _resolve();
    }
  }

  void _resolve() {
    final asset = widget.asset;
    if (asset == null) {
      _detach();
      _provider = null;
      return;
    }

    final provider = contentImageProvider(asset, source: widget.source);
    if (provider == _provider) return;

    _detach();
    _provider = provider;
    _stream = provider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        info.image.dispose();
        if (mounted && _imageSize != size) {
          setState(() => _imageSize = size);
        }
      },
      // Une illustration manquante ne doit pas empecher de jouer : on retombe
      // sur un fond uni, les zones restant posees sur la surface entiere.
      onError: (error, stack) {
        if (mounted) setState(() => _imageSize = null);
      },
    );
    _stream!.addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _imageSize);
}
