import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/main.dart';

import '../support/disk_content.dart';

/// Ce que l'application demande au demarrage doit exister dans le contenu.
///
/// Aucun test ne lance `main.dart` : renommer une aventure sans reprendre cette
/// constante donne un jeu qui affiche « Le jeu n'a pas pu s'ouvrir » sur
/// l'appareil, pendant que la suite reste entierement verte. C'est arrive.
void main() {
  group('Demarrage de l\'application', () {
    test('l\'aventure demandee au lancement est declaree dans le sommaire',
        () async {
      final index = await buildDiskRepository().loadIndex();

      expect(
        index.findAdventure(ReadingGameApp.defaultAdventureId),
        isNotNull,
        reason:
            'main.dart demande "${ReadingGameApp.defaultAdventureId}", absente '
            'de index.json : le jeu ne s\'ouvrirait pas.',
      );
    });

    test('cette aventure se charge et se valide', () async {
      // Declaree ne suffit pas : son fichier doit exister et etre coherent.
      final adventure = await buildDiskRepository().loadAdventure(
        ReadingGameApp.defaultAdventureId,
      );

      expect(adventure.validate(), isEmpty);
    });
  });
}
