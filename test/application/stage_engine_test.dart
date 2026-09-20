import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/hint.dart';
import 'package:reading_game/domain/models/hint_policy.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';

/// Etape de reference utilisee par la plupart des tests : deux familles de deux
/// mots, chacune menant a une destination distincte.
Stage buildTestStage() {
  return const Stage(
    id: 'home',
    locationName: 'Devant la maison',
    narrative: 'Grisbie veut aller a la plage.',
    words: [
      Word(id: 'train', text: 'train', syllables: ['train']),
      Word(id: 'station', text: 'gare', syllables: ['gare']),
      Word(id: 'shoe', text: 'chaussure', syllables: ['chau', 'ssure']),
      Word(id: 'sidewalk', text: 'trottoir', syllables: ['trot', 'toir']),
    ],
    families: [
      WordFamily(
        id: 'by_train',
        label: 'En train',
        wordIds: {'train', 'station'},
        destinationStageId: 'station_hall',
      ),
      WordFamily(
        id: 'on_foot',
        label: 'A pied',
        wordIds: {'shoe', 'sidewalk'},
        destinationStageId: 'street',
      ),
    ],
  );
}

StageEngine buildEngine({HintPolicy policy = const HintPolicy()}) {
  // Graine fixee : l'ordre des mots doit etre reproductible d'un test a l'autre.
  return StageEngine(
    stage: buildTestStage(),
    hintPolicy: policy,
    random: Random(42),
  );
}

void main() {
  group('Placement d\'un mot', () {
    test('accepte un mot pose dans sa famille', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(result.accepted, isTrue);
      expect(engine.state.placedWordIds, contains('train'));
    });

    test('refuse un mot pose dans une autre famille', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordId: 'train', familyId: 'on_foot');

      expect(result.accepted, isFalse);
      expect(engine.state.placedWordIds, isNot(contains('train')));
    });

    test('un mot refuse reste disponible pour un nouvel essai', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'on_foot');
      final retry = engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(retry.accepted, isTrue);
      expect(engine.state.placedWordIds, contains('train'));
    });

    test('un mot deja place ne peut pas etre replace', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(
        () => engine.placeWord(wordId: 'train', familyId: 'on_foot'),
        throwsArgumentError,
      );
    });

    test('un identifiant inconnu est refuse par une erreur explicite', () {
      final engine = buildEngine();

      expect(
        () => engine.placeWord(wordId: 'avion', familyId: 'by_train'),
        throwsArgumentError,
      );
      expect(
        () => engine.placeWord(wordId: 'train', familyId: 'en_fusee'),
        throwsArgumentError,
      );
    });
  });

  group('Comptage des erreurs', () {
    test('compte les erreurs mot par mot, sans les melanger', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'on_foot');
      engine.placeWord(wordId: 'train', familyId: 'on_foot');
      engine.placeWord(wordId: 'shoe', familyId: 'by_train');

      expect(engine.state.errorCountFor('train'), 2);
      expect(engine.state.errorCountFor('shoe'), 1);
      expect(engine.state.errorCountFor('sidewalk'), 0);
    });

    test('un placement correct n\'incremente aucun compteur', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(engine.state.errorCountFor('train'), 0);
    });
  });

  group('Deblocage automatique des aides', () {
    test('la premiere erreur debloque le decoupage en syllabes', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordId: 'train', familyId: 'on_foot');

      expect(result.unlockedHints, contains(Hint.syllables));
      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('l\'illustration n\'arrive qu\'a la cinquieme erreur', () {
      final engine = buildEngine();

      for (var attempt = 1; attempt <= 4; attempt++) {
        final result = engine.placeWord(wordId: 'train', familyId: 'on_foot');
        expect(
          result.unlockedHints,
          isNot(contains(Hint.illustration)),
          reason: 'erreur $attempt : trop tot pour l\'illustration',
        );
      }

      final fifth = engine.placeWord(wordId: 'train', familyId: 'on_foot');

      expect(fifth.unlockedHints, contains(Hint.illustration));
      expect(engine.state.hintsFor('train'), contains(Hint.illustration));
    });

    test('une aide n\'est signalee comme nouvelle qu\'une seule fois', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'on_foot');
      final second = engine.placeWord(wordId: 'train', familyId: 'on_foot');

      expect(second.unlockedHints, isEmpty);
      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('les aides restent acquises apres le placement correct', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'on_foot');
      engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('les seuils sont ceux de la politique injectee', () {
      final engine = buildEngine(
        policy: const HintPolicy(
          syllablesThreshold: 2,
          illustrationThreshold: 3,
        ),
      );

      final first = engine.placeWord(wordId: 'train', familyId: 'on_foot');
      expect(first.unlockedHints, isEmpty);

      final second = engine.placeWord(wordId: 'train', familyId: 'on_foot');
      expect(second.unlockedHints, contains(Hint.syllables));

      final third = engine.placeWord(wordId: 'train', familyId: 'on_foot');
      expect(third.unlockedHints, contains(Hint.illustration));
    });

    test('une aide peut etre demandee sans avoir commis d\'erreur', () {
      final engine = buildEngine();

      engine.requestHint(wordId: 'shoe', hint: Hint.illustration);

      expect(engine.state.hintsFor('shoe'), contains(Hint.illustration));
      expect(engine.state.errorCountFor('shoe'), 0);
    });
  });

  group('Completion d\'une famille et destinations', () {
    test('aucune destination n\'est disponible au depart', () {
      final engine = buildEngine();

      expect(engine.state.completedFamilyIds, isEmpty);
      expect(engine.state.availableDestinations, isEmpty);
    });

    test('une famille partiellement remplie n\'ouvre rien', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(engine.state.completedFamilyIds, isEmpty);
      expect(engine.state.availableDestinations, isEmpty);
    });

    test('completer une famille rend sa destination disponible', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');
      final result = engine.placeWord(wordId: 'station', familyId: 'by_train');

      expect(result.completedFamilyId, 'by_train');
      expect(engine.state.completedFamilyIds, contains('by_train'));
      expect(
        engine.state.availableDestinations.map((d) => d.stageId),
        contains('station_hall'),
      );
    });

    test('completer une famille ne termine pas l\'etape', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');
      engine.placeWord(wordId: 'station', familyId: 'by_train');

      expect(engine.state.isFinished, isFalse);
      expect(engine.state.departedTo, isNull);
    });

    test('plusieurs destinations peuvent etre disponibles en meme temps', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');
      engine.placeWord(wordId: 'station', familyId: 'by_train');
      engine.placeWord(wordId: 'shoe', familyId: 'on_foot');
      engine.placeWord(wordId: 'sidewalk', familyId: 'on_foot');

      expect(
        engine.state.availableDestinations.map((d) => d.stageId),
        containsAll(<String>['station_hall', 'street']),
      );
    });
  });

  group('Depart vers une destination', () {
    test('partir termine l\'etape et retient la destination choisie', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');
      engine.placeWord(wordId: 'station', familyId: 'by_train');
      engine.departTo('station_hall');

      expect(engine.state.isFinished, isTrue);
      expect(engine.state.departedTo, 'station_hall');
    });

    test('partir vers une destination non disponible est refuse', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');

      expect(() => engine.departTo('station_hall'), throwsStateError);
      expect(engine.state.isFinished, isFalse);
    });

    test('plus aucun placement n\'est accepte apres le depart', () {
      final engine = buildEngine();

      engine.placeWord(wordId: 'train', familyId: 'by_train');
      engine.placeWord(wordId: 'station', familyId: 'by_train');
      engine.departTo('station_hall');

      expect(
        () => engine.placeWord(wordId: 'shoe', familyId: 'on_foot'),
        throwsStateError,
      );
    });
  });

  group('Presentation des mots', () {
    test('tous les mots a classer sont proposes', () {
      final engine = buildEngine();

      expect(
        engine.shuffledWords.map((word) => word.id).toSet(),
        buildTestStage().words.map((word) => word.id).toSet(),
      );
    });

    test('l\'ordre est reproductible a graine egale', () {
      final first = buildEngine().shuffledWords.map((w) => w.id).toList();
      final second = buildEngine().shuffledWords.map((w) => w.id).toList();

      expect(first, second);
    });
  });
}
