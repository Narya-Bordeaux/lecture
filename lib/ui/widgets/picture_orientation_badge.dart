import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/picture_orientation.dart';

/// Le sens et les dimensions d'une image, poses sur sa vignette.
///
/// Les vignettes de la galerie remplissent un carre : une image verticale et
/// une horizontale s'y ressemblent. Le badge dit laquelle est laquelle, et
/// ses dimensions disent si elle est assez grande (une vignette d'aventure
/// demande au moins 768 × 512). Le jugement vient du domaine
/// ([PictureOrientation]) ; ce widget ne fait que l'afficher.
class PictureOrientationBadge extends StatelessWidget {
  const PictureOrientationBadge({
    required this.width,
    required this.height,
    super.key,
  });

  /// Les dimensions reelles de l'image, en pixels.
  final int width;
  final int height;

  /// Le nom de chaque sens, pour l'infobulle et l'accessibilite.
  static const Map<PictureOrientation, String> orientationLabels =
      <PictureOrientation, String>{
        PictureOrientation.landscape: 'Horizontale',
        PictureOrientation.portrait: 'Verticale',
        PictureOrientation.square: 'Carrée',
      };

  static const Map<PictureOrientation, IconData> orientationIcons =
      <PictureOrientation, IconData>{
        PictureOrientation.landscape: Icons.crop_landscape,
        PictureOrientation.portrait: Icons.crop_portrait,
        PictureOrientation.square: Icons.crop_square,
      };

  @override
  Widget build(BuildContext context) {
    final orientation = PictureOrientation.of(width: width, height: height);
    final label = orientationLabels[orientation]!;
    return Tooltip(
      message: label,
      child: Semantics(
        label: '$label, $width × $height',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  orientationIcons[orientation],
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '$width × $height',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
