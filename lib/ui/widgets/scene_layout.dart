import 'package:flutter/material.dart';
import 'package:reading_game/domain/models/relative_area.dart';

/// Un element a poser sur le decor, a un endroit donne de l'illustration.
class SceneChild {
  const SceneChild({required this.area, required this.child});

  final RelativeArea area;
  final Widget child;
}

/// Affiche l'illustration de fond et pose des elements a des endroits precis
/// de cette illustration.
///
/// Le point delicat : les zones sont reperees par rapport a l'image, pas a
/// l'ecran. Comme l'image est recadree pour remplir l'ecran, poser les zones
/// sur l'ecran les decalerait du bus ou de la voiture des que le format
/// changerait. Ce widget calcule donc le rectangle reellement occupe par
/// l'image, puis y place les zones — elles restent collees au decor sur tout
/// appareil.
///
/// Sans illustration, les zones se reperent par rapport a la surface entiere,
/// ce qui permet de faire tourner l'interface sans decor.
class SceneLayout extends StatefulWidget {
  const SceneLayout({
    required this.children,
    this.backgroundAsset,
    this.backgroundColor = const Color(0xFF9CC5E3),
    super.key,
  });

  final List<SceneChild> children;
  final String? backgroundAsset;
  final Color backgroundColor;

  @override
  State<SceneLayout> createState() => _SceneLayoutState();
}

class _SceneLayoutState extends State<SceneLayout> {
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;
  Size? _imageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveBackground();
  }

  @override
  void didUpdateWidget(SceneLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backgroundAsset != widget.backgroundAsset) {
      _imageSize = null;
      _resolveBackground();
    }
  }

  /// Demande les dimensions reelles de l'illustration, seules connues une fois
  /// le fichier decode.
  void _resolveBackground() {
    final asset = widget.backgroundAsset;
    if (asset == null) {
      _detachListener();
      _provider = null;
      return;
    }

    final provider = AssetImage(asset);
    if (provider == _provider) return;

    _detachListener();
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

  void _detachListener() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final surface = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = _coveredRect(surface);

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ColoredBox(color: widget.backgroundColor),
              if (widget.backgroundAsset != null)
                Positioned(
                  left: imageRect.left,
                  top: imageRect.top,
                  width: imageRect.width,
                  height: imageRect.height,
                  child: Image.asset(
                    widget.backgroundAsset!,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stack) =>
                        ColoredBox(color: widget.backgroundColor),
                  ),
                ),
              for (final item in widget.children)
                Positioned(
                  left: imageRect.left + item.area.left * imageRect.width,
                  top: imageRect.top + item.area.top * imageRect.height,
                  width: item.area.width * imageRect.width,
                  height: item.area.height * imageRect.height,
                  child: item.child,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Le rectangle qu'occupe l'illustration une fois recadree pour couvrir la
  /// surface, centree. Sans dimensions connues, l'illustration est reputee
  /// occuper toute la surface.
  Rect _coveredRect(Size surface) {
    final imageSize = _imageSize;
    if (imageSize == null || imageSize.isEmpty || surface.isEmpty) {
      return Offset.zero & surface;
    }

    final imageRatio = imageSize.width / imageSize.height;
    final surfaceRatio = surface.width / surface.height;

    final double width;
    final double height;
    if (surfaceRatio > imageRatio) {
      // La surface est plus large que l'image : on cale sur la largeur et on
      // deborde en hauteur.
      width = surface.width;
      height = width / imageRatio;
    } else {
      height = surface.height;
      width = height * imageRatio;
    }

    return Rect.fromLTWH(
      (surface.width - width) / 2,
      (surface.height - height) / 2,
      width,
      height,
    );
  }
}
