import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/ui/widgets/background_image_size.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Un element a poser sur le decor, a un endroit donne de l'illustration.
class SceneChild {
  const SceneChild({required this.area, required this.child});

  final RelativeArea area;
  final Widget child;
}

/// Calcule le rectangle occupe par l'illustration dans la surface donnee.
///
/// Fonction pure, extraite pour etre testable : c'est elle qui decide si une
/// zone de depot reste a l'ecran, et l'eprouver demande seulement deux tailles,
/// pas un appareil.
///
/// L'illustration est **entierement visible** et **calee en bas**. Remplir
/// l'ecran en recadrant serait tentant, mais sur un telephone allonge — 1080 x
/// 2340, soit 1:2,17, contre 1:1,5 pour l'image — l'illustration devrait
/// mesurer une fois et demie la largeur de l'ecran : un quart sortirait de
/// chaque cote, emportant avec lui les zones qui y sont ancrees.
///
/// Le calage en bas garde le personnage et le chemin visibles, et libere en
/// haut une bande que le bandeau des mots occupe deja.
/// [bottomInset] est la hauteur reservee en bas de l'ecran par le systeme —
/// barre de navigation, geste de retour. L'illustration se cale au-dessus,
/// sinon le bas du decor, ou se trouve le personnage, passe sous les boutons.
Rect computeSceneRect({
  required Size surface,
  required Size? imageSize,
  double bottomInset = 0,
}) {
  if (imageSize == null || imageSize.isEmpty || surface.isEmpty) {
    return Offset.zero & surface;
  }

  // La hauteur reellement disponible, une fois la zone systeme deduite.
  final available = Size(
    surface.width,
    (surface.height - bottomInset).clamp(0.0, surface.height),
  );
  if (available.isEmpty) return Offset.zero & surface;

  final imageRatio = imageSize.width / imageSize.height;
  final availableRatio = available.width / available.height;

  final double width;
  final double height;
  if (availableRatio < imageRatio) {
    // L'ecran est plus etroit que l'image : on cale sur la largeur.
    width = available.width;
    height = width / imageRatio;
  } else {
    height = available.height;
    width = height * imageRatio;
  }

  return Rect.fromLTWH(
    (available.width - width) / 2,
    available.height - height,
    width,
    height,
  );
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
class SceneLayout extends StatelessWidget {
  const SceneLayout({
    required this.children,
    this.backgroundAsset,
    this.contentSource,
    this.backgroundColor = const Color(0xFF9CC5E3),
    this.bottomInset = 0,
    super.key,
  });

  final List<SceneChild> children;
  final String? backgroundAsset;

  /// D'ou lire le contenu, illustrations comprises. Nulle, le bundle.
  final ContentSource? contentSource;
  final Color backgroundColor;

  /// Hauteur reservee en bas par le systeme, au-dessus de laquelle
  /// l'illustration se cale.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return BackgroundImageSize(
      asset: backgroundAsset,
      source: contentSource,
      builder: (context, imageSize) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final imageRect = computeSceneRect(
              surface: Size(constraints.maxWidth, constraints.maxHeight),
              imageSize: imageSize,
              bottomInset: bottomInset,
            );

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                // Les intitules des zones debordent volontairement de leur
                // cadre, pour n'etre jamais tronques. Seul le bord de l'ecran
                // les coupe.
                clipBehavior: Clip.none,
                children: <Widget>[
                  // La bande laissee libre au-dessus de l'illustration se fond
                  // dans son ciel : la jointure passe inapercue.
                  ColoredBox(color: backgroundColor),
                  if (backgroundAsset != null)
                    Positioned(
                      left: imageRect.left,
                      top: imageRect.top,
                      width: imageRect.width,
                      height: imageRect.height,
                      child: ContentImage(
                        source: contentSource,
                        path: backgroundAsset!,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stack) =>
                            ColoredBox(color: backgroundColor),
                      ),
                    ),
                  for (final item in children)
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
      },
    );
  }
}
