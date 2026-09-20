import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/domain/models/relative_area.dart';
import 'package:reading_game/ui/widgets/scene_layout.dart';

/// Ces tests portent sur le placement de l'illustration et, par consequent, sur
/// celui des zones de depot qui y sont ancrees.
///
/// Ils repondent a une panne constatee sur appareil : l'illustration etait
/// recadree pour remplir l'ecran, et sur un telephone allonge une bonne part
/// sortait lateralement, emportant les zones avec elle. Les tests d'interface
/// existants ne pouvaient rien voir : ils tournent sans illustration, donc sans
/// recadrage. Seule cette geometrie, eprouvee sur des tailles reelles, le
/// montre.

/// L'illustration livree pour l'etape de depart.
const Size illustration = Size(1024, 1536);

/// Les zones de cette etape, telles qu'ecrites dans le contenu.
const Map<String, RelativeArea> stageAreas = <String, RelativeArea>{
  'En bus': RelativeArea(left: 0.02, top: 0.29, width: 0.32, height: 0.16),
  'En voiture': RelativeArea(left: 0.37, top: 0.39, width: 0.27, height: 0.15),
  'À pied': RelativeArea(left: 0.66, top: 0.42, width: 0.30, height: 0.18),
};

/// Le rectangle qu'occupe une zone a l'ecran.
Rect areaOnScreen(RelativeArea area, Rect image) {
  return Rect.fromLTWH(
    image.left + area.left * image.width,
    image.top + area.top * image.height,
    area.width * image.width,
    area.height * image.height,
  );
}

void main() {
  // Des appareils reels, du plus allonge au plus carre. Le premier est celui
  // sur lequel le defaut a ete constate.
  const devices = <String, Size>{
    'Galaxy A54 (1080x2340)': Size(1080, 2340),
    'telephone courant (1170x2532)': Size(1170, 2532),
    'petit telephone (720x1280)': Size(720, 1280),
    'tablette (1536x2048)': Size(1536, 2048),
  };

  devices.forEach((name, screen) {
    group('Sur $name', () {
      final image = computeSceneRect(surface: screen, imageSize: illustration);

      test('l\'illustration tient entierement dans l\'ecran', () {
        expect(image.left, greaterThanOrEqualTo(-0.5), reason: 'deborde a gauche');
        expect(image.top, greaterThanOrEqualTo(-0.5), reason: 'deborde en haut');
        expect(
          image.right,
          lessThanOrEqualTo(screen.width + 0.5),
          reason: 'deborde a droite',
        );
        expect(
          image.bottom,
          lessThanOrEqualTo(screen.height + 0.5),
          reason: 'deborde en bas',
        );
      });

      test('l\'illustration garde ses proportions', () {
        expect(
          image.width / image.height,
          closeTo(illustration.width / illustration.height, 0.001),
          reason: 'l\'image serait etiree',
        );
      });

      test('l\'illustration est calee en bas', () {
        // Le personnage et le chemin sont en bas de l'image : c'est cette
        // partie qui doit rester visible, la place libre allant en haut, ou le
        // bandeau des mots la recouvre.
        expect(image.bottom, closeTo(screen.height, 0.5));
      });

      test('chaque zone de depot reste entierement a l\'ecran', () {
        stageAreas.forEach((label, area) {
          final rect = areaOnScreen(area, image);

          expect(rect.left, greaterThanOrEqualTo(-0.5), reason: '$label a gauche');
          expect(
            rect.right,
            lessThanOrEqualTo(screen.width + 0.5),
            reason: '$label depasse a droite',
          );
          expect(rect.top, greaterThanOrEqualTo(-0.5), reason: '$label en haut');
          expect(
            rect.bottom,
            lessThanOrEqualTo(screen.height + 0.5),
            reason: '$label depasse en bas',
          );
        });
      });

      test('chaque zone reste assez grande pour un doigt d\'enfant', () {
        // 48 points de cote est la cible d'accessibilite usuelle ; une zone de
        // depot doit etre nettement plus large que cela.
        final density = screen.width / 400;
        stageAreas.forEach((label, area) {
          final rect = areaOnScreen(area, image);
          expect(
            rect.width / density,
            greaterThan(60),
            reason: '$label trop etroite',
          );
          expect(
            rect.height / density,
            greaterThan(48),
            reason: '$label trop basse',
          );
        });
      });
    });
  });

  group('Cas limites', () {
    test('sans illustration, la scene occupe toute la surface', () {
      const surface = Size(400, 800);
      final rect = computeSceneRect(surface: surface, imageSize: null);

      expect(rect, Offset.zero & surface);
    });

    test('une surface vide ne provoque aucun calcul aberrant', () {
      final rect = computeSceneRect(
        surface: Size.zero,
        imageSize: illustration,
      );

      expect(rect.width, 0);
      expect(rect.height, 0);
    });

    test('un ecran plus large que l\'image cale sur la hauteur', () {
      // Cas du paysage : l'image ne doit pas etre etiree pour remplir.
      const surface = Size(2000, 1000);
      final rect = computeSceneRect(surface: surface, imageSize: illustration);

      expect(rect.height, closeTo(1000, 0.5));
      expect(rect.width, lessThan(2000));
      expect(rect.left, greaterThan(0), reason: 'devrait etre centree');
    });
  });
}
