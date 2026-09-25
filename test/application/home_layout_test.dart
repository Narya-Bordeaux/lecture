import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/home_layout.dart';

/// Un point du plan, pour les controles de chevauchement.
typedef Point2 = ({double x, double y});

/// Les quatre coins d'une carte posee a la place [position] de l'arc,
/// titre compris.
List<Point2> cornersAt(HomeLayout layout, double position) {
  final placement = layout.arc.place(position);
  final halfWidth = layout.cardWidth / 2;
  final halfHeight = layout.elementHeight / 2;
  final cosTilt = cos(placement.tilt);
  final sinTilt = sin(placement.tilt);
  return <Point2>[
    for (final (dx, dy) in <(double, double)>[
      (-halfWidth, -halfHeight),
      (halfWidth, -halfHeight),
      (halfWidth, halfHeight),
      (-halfWidth, halfHeight),
    ])
      (
        x: placement.x + dx * cosTilt - dy * sinTilt,
        y: placement.y + dx * sinTilt + dy * cosTilt,
      ),
  ];
}

/// Vrai si deux polygones convexes se chevauchent (axes separateurs).
bool overlaps(List<Point2> first, List<Point2> second) {
  for (final polygon in <List<Point2>>[first, second]) {
    for (var index = 0; index < polygon.length; index++) {
      final a = polygon[index];
      final b = polygon[(index + 1) % polygon.length];
      final axis = (x: b.y - a.y, y: a.x - b.x);
      double project(Point2 p) => p.x * axis.x + p.y * axis.y;
      final firstValues = first.map(project);
      final secondValues = second.map(project);
      if (firstValues.reduce(max) <= secondValues.reduce(min) ||
          secondValues.reduce(max) <= firstValues.reduce(min)) {
        return false;
      }
    }
  }
  return true;
}

void main() {
  // Tailles logiques, zone sure deja retiree du haut.
  const screens = <String, (double, double)>{
    'petit telephone (360x640)': (360, 616),
    'Galaxy A54 (360x780)': (360, 750),
    'telephone courant (390x844)': (390, 800),
    'grand telephone (430x932)': (430, 885),
    'tablette (768x1024)': (768, 1000),
    'navigateur en largeur (1280x720)': (1280, 720),
  };

  screens.forEach((name, size) {
    final (width, height) = size;
    final layout = HomeLayout.compute(width: width, height: height);

    group(name, () {
      test('les trois cartes tiennent dans l ecran', () {
        for (final position in <double>[-1, 0, 1]) {
          for (final corner in cornersAt(layout, position)) {
            expect(corner.x, greaterThanOrEqualTo(HomeLayout.margin - 0.5),
                reason: 'place $position');
            expect(corner.x, lessThanOrEqualTo(width - HomeLayout.margin + 0.5),
                reason: 'place $position');
            expect(corner.y, lessThanOrEqualTo(height - HomeLayout.margin + 0.5),
                reason: 'place $position');
          }
        }
      });

      test('deux cartes voisines ne se chevauchent pas', () {
        expect(overlaps(cornersAt(layout, -1), cornersAt(layout, 0)), isFalse);
        expect(overlaps(cornersAt(layout, 0), cornersAt(layout, 1)), isFalse);
      });

      test('une carte qui entre ne chevauche pas sa voisine', () {
        // A mi-chemin : la carte qui entre et celle qu'elle suit.
        expect(
          overlaps(cornersAt(layout, 1.5), cornersAt(layout, 0.5)),
          isFalse,
        );
      });

      test('aucune carte ne mord sur le logo', () {
        final halfWidth = layout.logoWidth / 2;
        final halfHeight = layout.logoHeight / 2;
        for (final position in <double>[-1, 0, 1]) {
          for (final corner in cornersAt(layout, position)) {
            final dx = (corner.x - layout.logoCenterX) / halfWidth;
            final dy = (corner.y - layout.logoCenterY) / halfHeight;
            expect(dx * dx + dy * dy, greaterThan(1), reason: 'place $position');
          }
        }
      });

      test('une carte reste assez grande pour un doigt', () {
        expect(layout.cardWidth, greaterThanOrEqualTo(HomeLayout.minimumCardWidth));
        expect(layout.cardHeight, closeTo(layout.cardWidth / 1.5, 1e-9));
      });

      test('le titre ne sort pas par le haut', () {
        final top = layout.logoCenterY -
            layout.titleOuterRadius -
            layout.titleFontSize;
        expect(top, greaterThanOrEqualTo(0));
      });

      test('les deux lignes du titre ne se touchent pas, ni le logo', () {
        expect(
          layout.titleOuterRadius - layout.titleInnerRadius,
          greaterThanOrEqualTo(layout.titleFontSize),
        );
        expect(
          layout.titleInnerRadius - layout.titleFontSize * 0.3,
          greaterThan(layout.logoHeight / 2),
        );
      });
    });
  });

  test('le logo est un ovale en hauteur, centre', () {
    final layout = HomeLayout.compute(width: 390, height: 800);

    expect(layout.logoCenterX, 195);
    expect(layout.logoHeight, greaterThan(layout.logoWidth));
    // Un peu plus de la moitie de la largeur, quand la hauteur le permet.
    expect(layout.logoWidth, closeTo(390 * HomeLayout.logoShare, 1));
  });

  test('la roue est dans l axe, sous le logo, courbee vers le haut', () {
    final layout = HomeLayout.compute(width: 390, height: 800);
    final middle = layout.arc.place(0);

    expect(layout.arc.centerX, layout.logoCenterX);
    expect(middle.y, greaterThan(layout.logoCenterY + layout.logoHeight / 2));
    // Les vignettes de cote remontent : c'est un sourire, comme au croquis.
    expect(layout.arc.place(1).y, lessThan(middle.y));
  });

  test('l espace libre se partage, il ne s entasse pas en bas', () {
    final layout = HomeLayout.compute(width: 390, height: 800);
    final bottom = layout.arc.place(0).y + layout.elementHeight / 2;
    final top = layout.logoCenterY - layout.titleOuterRadius - layout.titleFontSize;

    expect(800 - bottom, closeTo(top, 1));
  });
}
