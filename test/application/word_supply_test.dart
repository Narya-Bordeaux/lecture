import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';

import '../support/stage_builders.dart' as build;

/// Etape dotee d'un reservoir : plus de mots que d'emplacements visibles.
///
/// Deux familles de six mots, quatre emplacements affiches. Un mot bien classe
/// libere son emplacement, qu'un mot du reservoir vient reprendre.
Stage buildSupplyStage({int? goal}) {
  return build.stage(
    id: 'home',
    location: 'Devant la maison',
    visibleWordCount: 4,
    families: <WordFamily>[
      build.family(
        id: 'by_bus',
        label: 'En bus',
        words: <Word>[
          for (var i = 1; i <= 6; i++) build.word('bus$i', 'bus$i'),
        ],
        destination: 'station_hall',
        goal: goal,
      ),
      build.family(
        id: 'on_foot',
        label: 'A pied',
        words: <Word>[
          for (var i = 1; i <= 6; i++) build.word('foot$i', 'foot$i'),
        ],
        destination: 'street',
        goal: goal,
      ),
    ],
  );
}

StageEngine buildEngine({int? goal, int seed = 5}) {
  return StageEngine(stage: buildSupplyStage(goal: goal), random: Random(seed));
}

/// Place correctement le premier mot visible, quelle que soit sa famille.
String placeFirstVisibleWord(StageEngine engine) {
  final word = engine.visibleWords.firstWhere((word) => word != null)!;
  final family = engine.stage.families.firstWhere(
    (family) => family.accepts(word.id),
  );
  engine.placeWord(wordId: word.id, familyId: family.id);
  return word.id;
}

void main() {
  group('Emplacements visibles', () {
    test('l\'etape n\'affiche que le nombre d\'emplacements prevu', () {
      final engine = buildEngine();

      expect(engine.visibleWords, hasLength(4));
      expect(engine.visibleWords.whereType<Word>(), hasLength(4));
    });

    test('les mots visibles sont tous differents', () {
      final engine = buildEngine();

      final ids = engine.visibleWords.whereType<Word>().map((w) => w.id);
      expect(ids.toSet(), hasLength(4));
    });

    test('le reservoir contient les mots non encore montres', () {
      final engine = buildEngine();

      expect(engine.state.remainingInSupply, 8);
    });

    test('l\'ordre est reproductible a graine egale', () {
      List<String?> visibleIds(StageEngine engine) =>
          engine.visibleWords.map((word) => word?.id).toList();

      expect(visibleIds(buildEngine()), visibleIds(buildEngine()));
    });
  });

  group('Remplacement apres un mot bien classe', () {
    test('un mot bien classe libere son emplacement pour un nouveau mot', () {
      final engine = buildEngine();
      final placedId = placeFirstVisibleWord(engine);

      expect(engine.visibleWords, hasLength(4));
      expect(engine.visibleWords.whereType<Word>(), hasLength(4));
      expect(
        engine.visibleWords.whereType<Word>().map((w) => w.id),
        isNot(contains(placedId)),
      );
      expect(engine.state.remainingInSupply, 7);
    });

    test('le mot arrive a la place laissee libre', () {
      final engine = buildEngine();
      final before = engine.visibleWords.map((word) => word?.id).toList();
      final placedId = placeFirstVisibleWord(engine);
      final freedSlot = before.indexOf(placedId);
      final after = engine.visibleWords.map((word) => word?.id).toList();

      expect(after[freedSlot], isNot(placedId));
      // Les autres mots n'ont pas bouge : l'enfant ne perd pas des yeux celui
      // qu'il etait en train de lire.
      for (var slot = 0; slot < before.length; slot++) {
        if (slot == freedSlot) continue;
        expect(after[slot], before[slot], reason: 'emplacement $slot deplace');
      }
    });

    test('le nouveau mot vient du reservoir, jamais un deja place', () {
      final engine = buildEngine();
      final placed = <String>[];

      for (var turn = 0; turn < 6; turn++) {
        placed.add(placeFirstVisibleWord(engine));
        final visibleIds =
            engine.visibleWords.whereType<Word>().map((w) => w.id).toList();
        for (final id in placed) {
          expect(visibleIds, isNot(contains(id)));
        }
      }
    });

    test('un mot mal classe ne declenche aucun remplacement', () {
      final engine = buildEngine();
      final before = engine.visibleWords.map((word) => word?.id).toList();

      final word = engine.visibleWords.firstWhere((word) => word != null)!;
      final wrongFamily = engine.stage.families.firstWhere(
        (family) => !family.accepts(word.id),
      );
      engine.placeWord(wordId: word.id, familyId: wrongFamily.id);

      expect(engine.visibleWords.map((word) => word?.id).toList(), before);
      expect(engine.state.remainingInSupply, 8);
    });

    test('le reservoir epuise, les emplacements se vident', () {
      final engine = buildEngine();

      // Les douze mots sont classes un a un.
      for (var turn = 0; turn < 12; turn++) {
        placeFirstVisibleWord(engine);
      }

      expect(engine.state.remainingInSupply, 0);
      expect(engine.visibleWords.whereType<Word>(), isEmpty);
    });
  });

  group('Objectif d\'une famille', () {
    test('par defaut, il faut classer toute la liste', () {
      final engine = buildEngine();

      expect(engine.stage.families.first.requiredCount, 6);
    });

    test('un objectif plus court ouvre la destination plus tot', () {
      final engine = buildEngine(goal: 2);
      expect(engine.stage.families.first.requiredCount, 2);

      // Deux mots bus suffisent, sans attendre les quatre autres.
      engine.placeWord(wordId: 'bus1', familyId: 'by_bus');
      expect(engine.state.availableDestinations, isEmpty);
      engine.placeWord(wordId: 'bus2', familyId: 'by_bus');

      expect(
        engine.state.availableDestinations.map((d) => d.stageId),
        contains('station_hall'),
      );
    });

    test('un mot deja visible ou en reservoir reste classable apres', () {
      final engine = buildEngine(goal: 2);

      engine.placeWord(wordId: 'bus1', familyId: 'by_bus');
      engine.placeWord(wordId: 'bus2', familyId: 'by_bus');
      // L'objectif est atteint, mais rien n'empeche de continuer a jouer.
      engine.placeWord(wordId: 'bus3', familyId: 'by_bus');

      expect(engine.state.placedWordIds, contains('bus3'));
      expect(engine.state.isFinished, isFalse);
    });

    test('le compte se fait par famille, sans melanger', () {
      final engine = buildEngine(goal: 2);

      engine.placeWord(wordId: 'bus1', familyId: 'by_bus');
      engine.placeWord(wordId: 'foot1', familyId: 'on_foot');

      expect(engine.state.availableDestinations, isEmpty);
    });
  });
}
