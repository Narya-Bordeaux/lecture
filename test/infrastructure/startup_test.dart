import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/pages/game_home_page.dart';

import '../support/disk_content.dart';

/// Ce que l'accueil du jeu propose doit s'ouvrir.
///
/// Aucun test ne lance `main.dart`. L'accueil montre toutes les aventures du
/// sommaire : une seule qui ne se charge pas donnerait, sur l'appareil, une
/// vignette qui mene a « Le jeu n'a pas pu s'ouvrir », pendant que la suite
/// resterait entierement verte. C'est arrive, du temps ou le lancement
/// demandait une aventure par son nom.
void main() {
  group('Demarrage de l\'application', () {
    test('le sommaire propose au moins une aventure', () async {
      final index = await buildDiskRepository().loadIndex();

      expect(index.adventures, isNotEmpty);
    });

    test('chaque aventure proposee se charge et se valide', () async {
      final repository = buildDiskRepository();
      final index = await repository.loadIndex();

      for (final entry in index.adventures) {
        final adventure = await repository.loadAdventure(entry.id);

        expect(
          adventure.validate().where((issue) => issue.blocksPlay),
          isEmpty,
          reason: '« ${entry.title} » ne s\'ouvrirait pas.',
        );
      }
    });

    test('la vignette du sommaire est celle de l\'aventure', () async {
      // Le sommaire en garde une copie pour que l'accueil n'ait que lui a
      // lire : une copie differente montrerait une autre image.
      final repository = buildDiskRepository();
      final index = await repository.loadIndex();

      for (final entry in index.adventures) {
        final adventure = await repository.loadAdventure(entry.id);

        expect(entry.coverAsset, adventure.coverAsset, reason: entry.id);
        expect(
          File('assets/content/${entry.coverAsset}').existsSync(),
          isTrue,
          reason: 'vignette de ${entry.id}',
        );
      }
    });

    test('le logo de l\'accueil existe', () {
      expect(File(GameHomePage.logoAsset).existsSync(), isTrue);
    });
  });
}
