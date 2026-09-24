import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/wheel_arc.dart';

void main() {
  // Une roue de rayon 100 centree en (200, 300), un cran tous les 30 degres.
  const arc = WheelArc(
    centerX: 200,
    centerY: 300,
    radius: 100,
    stepAngle: pi / 6,
  );

  group('La place d une vignette sur l arc', () {
    test('au centre de l arc : sous le moyeu, droite', () {
      final placement = arc.place(0);

      expect(placement.x, closeTo(200, 1e-9));
      expect(placement.y, closeTo(400, 1e-9));
      expect(placement.tilt, closeTo(0, 1e-9));
    });

    test('a gauche, elle remonte et penche vers la droite', () {
      final placement = arc.place(-1);

      expect(placement.x, closeTo(200 - 100 * sin(pi / 6), 1e-9));
      expect(placement.y, closeTo(300 + 100 * cos(pi / 6), 1e-9));
      // Sens horaire : le haut de la vignette pointe vers le moyeu.
      expect(placement.tilt, closeTo(pi / 6, 1e-9));
    });

    test('a droite, elle remonte et penche vers la gauche', () {
      final placement = arc.place(1);

      expect(placement.x, closeTo(200 + 100 * sin(pi / 6), 1e-9));
      expect(placement.y, closeTo(300 + 100 * cos(pi / 6), 1e-9));
      expect(placement.tilt, closeTo(-pi / 6, 1e-9));
    });

    test('deux places symetriques sont en miroir', () {
      final left = arc.place(-1.5);
      final right = arc.place(1.5);

      expect(left.x + right.x, closeTo(2 * arc.centerX, 1e-9));
      expect(left.y, closeTo(right.y, 1e-9));
      expect(left.tilt, closeTo(-right.tilt, 1e-9));
    });

    test('chaque place reste a distance du moyeu', () {
      for (var step = -20; step <= 20; step++) {
        final placement = arc.place(step / 8);
        final distance = sqrt(
          pow(placement.x - arc.centerX, 2) + pow(placement.y - arc.centerY, 2),
        );

        expect(distance, closeTo(arc.radius, 1e-9));
      }
    });
  });
}
