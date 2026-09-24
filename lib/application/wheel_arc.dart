import 'dart:math';

/// L'endroit ou se pose une vignette, et son inclinaison.
class ArcPlacement {
  const ArcPlacement({required this.x, required this.y, required this.tilt});

  /// Le centre de la vignette, dans le repere de l'ecran (y vers le bas).
  final double x;
  final double y;

  /// L'inclinaison, en radians, positive dans le sens horaire : le haut de
  /// la vignette pointe toujours vers le moyeu.
  final double tilt;
}

/// L'arc de la roue : un cercle autour du moyeu, dont on ne voit que le bas.
///
/// Le moyeu est le logo, qui ne tourne pas. Les vignettes sont posees sur le
/// cercle comme des rayons, et c'est ce qui les fait pencher de part et
/// d'autre : droites sous le moyeu, inclinees en remontant sur les cotes.
class WheelArc {
  const WheelArc({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.stepAngle,
  });

  /// Le moyeu, dans le repere de l'ecran.
  final double centerX;
  final double centerY;

  /// La distance du moyeu au centre de chaque vignette.
  final double radius;

  /// L'angle entre deux places voisines, en radians.
  final double stepAngle;

  /// La vignette qui occupe la place [position], comptee en crans depuis le
  /// bas du cercle (voir `WheelSlot.position`).
  ArcPlacement place(double position) {
    final angle = position * stepAngle;
    return ArcPlacement(
      x: centerX + radius * sin(angle),
      y: centerY + radius * cos(angle),
      tilt: -angle,
    );
  }
}
