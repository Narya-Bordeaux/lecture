import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_wheel.dart';

/// Les indices d'aventure des places, de gauche a droite.
List<int> itemsOf(AdventureWheel wheel) =>
    wheel.slots.map((slot) => slot.itemIndex).toList();

/// Les positions des places, de gauche a droite.
List<double> positionsOf(AdventureWheel wheel) =>
    wheel.slots.map((slot) => slot.position).toList();

void main() {
  group('Une roue qui ne tourne pas', () {
    test('aucune aventure : aucune place', () {
      final wheel = AdventureWheel(itemCount: 0);

      expect(wheel.slots, isEmpty);
      expect(wheel.turns, isFalse);
    });

    test('une seule aventure se pose au centre de l arc', () {
      final wheel = AdventureWheel(itemCount: 1);

      expect(itemsOf(wheel), <int>[0]);
      expect(positionsOf(wheel), <double>[0]);
    });

    test('moins de trois aventures se centrent sur l arc', () {
      final wheel = AdventureWheel(itemCount: 2);

      expect(itemsOf(wheel), <int>[0, 1]);
      expect(positionsOf(wheel), <double>[-0.5, 0.5]);
    });

    test('trois aventures remplissent l arc sans le faire tourner', () {
      final wheel = AdventureWheel(itemCount: 3);

      expect(wheel.turns, isFalse);
      expect(itemsOf(wheel), <int>[0, 1, 2]);
      expect(positionsOf(wheel), <double>[-1, 0, 1]);
    });

    test('le geste est ignore', () {
      final wheel = AdventureWheel(itemCount: 3).turnedBy(0.7);

      expect(wheel.rotation, 0);
      expect(positionsOf(wheel), <double>[-1, 0, 1]);
    });

    test('toutes les places sont pleinement visibles', () {
      final wheel = AdventureWheel(itemCount: 3);

      expect(wheel.slots.every((slot) => slot.visibility == 1), isTrue);
    });
  });

  group('Une roue qui tourne', () {
    test('au repos, trois aventures visibles, les premieres', () {
      final wheel = AdventureWheel(itemCount: 6);

      final visible = wheel.slots.where((slot) => slot.visibility == 1);
      expect(visible.map((slot) => slot.itemIndex), <int>[0, 1, 2]);
      expect(visible.map((slot) => slot.position), <double>[-1, 0, 1]);
    });

    test('tourner d un cran fait entrer la suivante par la droite', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(1);

      final visible = wheel.slots.where((slot) => slot.visibility == 1);
      expect(visible.map((slot) => slot.itemIndex), <int>[1, 2, 3]);
    });

    test('elle boucle : apres la derniere revient la premiere', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(4);

      final visible = wheel.slots.where((slot) => slot.visibility == 1);
      expect(visible.map((slot) => slot.itemIndex), <int>[4, 5, 0]);
    });

    test('elle boucle aussi dans l autre sens', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(-1);

      final visible = wheel.slots.where((slot) => slot.visibility == 1);
      expect(visible.map((slot) => slot.itemIndex), <int>[5, 0, 1]);
    });

    test('entre deux crans, les places glissent sans sauter', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(0.25);

      expect(itemsOf(wheel), <int>[0, 1, 2, 3]);
      expect(positionsOf(wheel), <double>[-1.25, -0.25, 0.75, 1.75]);
    });

    test('celle qui sort s efface, celle qui entre apparait', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(0.25);
      final visibility = <int, double>{
        for (final slot in wheel.slots) slot.itemIndex: slot.visibility,
      };

      // L'aventure 0 sort par la gauche, deja un quart hors de l'arc.
      expect(visibility[0], closeTo(0.75, 1e-9));
      // L'aventure 3 entre par la droite, d'un quart.
      expect(visibility[3], closeTo(0.25, 1e-9));
      // Celles du milieu restent pleinement visibles.
      expect(visibility[1], 1);
      expect(visibility[2], 1);
    });

    test('au repos, seules les trois places de l arc existent', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(2);

      expect(itemsOf(wheel), <int>[2, 3, 4]);
    });

    test('une meme aventure n occupe jamais deux places', () {
      // Quatre aventures pour trois places : la plus serree des boucles.
      // Deux places pour une meme aventure donneraient deux vignettes
      // identiques a l'ecran, et deux widgets de meme cle.
      for (var step = -40; step <= 40; step++) {
        final shown = itemsOf(AdventureWheel(itemCount: 4).turnedBy(step / 8));

        expect(shown.toSet().length, shown.length, reason: 'cran $step');
      }
    });
  });

  group('Le calage au lacher', () {
    test('se pose sur le cran le plus proche', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(1.3);

      expect(wheel.settled().rotation, 1);
    });

    test('un geste lance emporte vers le cran suivant', () {
      final wheel = AdventureWheel(itemCount: 6).turnedBy(1.3);

      expect(wheel.settled(velocity: 3).rotation, 2);
      expect(wheel.settled(velocity: -3).rotation, 1);
    });

    test('un geste tres lance fait passer plusieurs crans', () {
      final wheel = AdventureWheel(itemCount: 8);

      expect(wheel.settled(velocity: 12).rotation, greaterThan(1));
    });

    test('une roue qui ne tourne pas reste au repos', () {
      final wheel = AdventureWheel(itemCount: 3);

      expect(wheel.settled(velocity: 12).rotation, 0);
    });

    test('au repos, chaque place est sur un cran', () {
      final random = Random(7);
      for (var trial = 0; trial < 20; trial++) {
        final wheel = AdventureWheel(itemCount: 7)
            .turnedBy(random.nextDouble() * 20 - 10)
            .settled(velocity: random.nextDouble() * 10 - 5);

        for (final slot in wheel.slots) {
          expect(slot.position % 1, 0, reason: 'essai $trial');
        }
      }
    });
  });
}
