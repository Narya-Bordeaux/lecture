import 'dart:math';

import 'package:flutter/material.dart';

/// Une ligne de texte posee sur le haut d'un cercle, lettre par lettre.
///
/// Chaque lettre suit la tangente et garde sa ligne de base sur le cercle :
/// le texte s'arrondit au-dessus de [center], centre sur l'axe vertical.
/// C'est le titre en arche du croquis de l'auteur.
class CurvedTextPainter extends CustomPainter {
  CurvedTextPainter({
    required this.text,
    required this.style,
    required this.center,
    required this.radius,
  });

  final String text;
  final TextStyle style;

  /// Le centre du cercle, dans le repere du peintre.
  final Offset center;

  /// Le rayon de la ligne de base.
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final letters = <TextPainter>[
      for (final letter in text.characters)
        TextPainter(
          text: TextSpan(text: letter, style: style),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
    final totalWidth =
        letters.fold<double>(0, (sum, letter) => sum + letter.width);

    // Le texte est centre sur le haut du cercle (-pi/2), et se lit de gauche
    // a droite, donc dans le sens horaire.
    var angle = -pi / 2 - totalWidth / radius / 2;
    for (final letter in letters) {
      final halfAngle = letter.width / radius / 2;
      angle += halfAngle;
      final baseline =
          letter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

      canvas.save();
      canvas.translate(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.rotate(angle + pi / 2);
      letter.paint(canvas, Offset(-letter.width / 2, -baseline));
      canvas.restore();

      angle += halfAngle;
    }
  }

  @override
  bool shouldRepaint(CurvedTextPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.center != center ||
      oldDelegate.radius != radius;
}
