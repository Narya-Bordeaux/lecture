import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_engine.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart' as build;

/// Etape de reference utilisee par la plupart des tests : deux familles de deux
/// mots, chacune menant a une destination distincte.
Stage buildTestStage() {
  return build.stage(
    id: 'maison',
    location: 'Devant la maison',
    arrivalText: 'Grisbie veut aller a la plage.',
    families: <WordFamily>[
      build.family(
        id: 'en_train',
        label: 'En train',
        words: <Word>[
          build.word('train'),
          build.word('gare'),
        ],
        destination: 'gare',
      ),
      build.family(
        id: 'a_pied',
        label: 'A pied',
        words: <Word>[
          build.word('chaussure'),
          build.word('trottoir'),
        ],
        destination: 'rue',
      ),
    ],
  );
}

StageEngine buildEngine() {
  // Graine fixee : l'ordre des mots doit etre reproductible d'un test a l'autre.
  return StageEngine(stage: buildTestStage(), random: Random(42));
}

void main() {
  group('Placement d\'un mot', () {
    test('accepte un mot pose dans sa famille', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(result.accepted, isTrue);
      expect(engine.state.placedWordTexts, contains('train'));
    });

    test('refuse un mot pose dans une autre famille', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordText: 'train', familyId: 'a_pied');

      expect(result.accepted, isFalse);
      expect(engine.state.placedWordTexts, isNot(contains('train')));
    });

    test('un mot refuse reste disponible pour un nouvel essai', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'a_pied');
      final retry = engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(retry.accepted, isTrue);
      expect(engine.state.placedWordTexts, contains('train'));
    });

    test('un mot deja place ne peut pas etre replace', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(
        () => engine.placeWord(wordText: 'train', familyId: 'a_pied'),
        throwsArgumentError,
      );
    });

    test('un identifiant inconnu est refuse par une erreur explicite', () {
      final engine = buildEngine();

      expect(
        () => engine.placeWord(wordText: 'avion', familyId: 'en_train'),
        throwsArgumentError,
      );
      expect(
        () => engine.placeWord(wordText: 'train', familyId: 'en_fusee'),
        throwsArgumentError,
      );
    });
  });

  group('Une erreur', () {
    // Il n'y a plus d'aide (0.33.0) : un mot mal place est refuse, reste a sa
    // place, et l'enfant reessaie. L'erreur ne coute rien et n'ouvre rien.

    test('est refusee sans rien changer', () {
      final engine = buildEngine();
      final visible = engine.visibleWords;

      final result = engine.placeWord(wordText: 'train', familyId: 'a_pied');

      expect(result.accepted, isFalse);
      expect(result.completedFamilyId, isNull);
      expect(engine.state.placedWordTexts, isEmpty);
      expect(engine.visibleWords, visible);
    });

    test('se retente autant qu\'il le faut', () {
      final engine = buildEngine();

      for (var attempt = 1; attempt <= 5; attempt++) {
        engine.placeWord(wordText: 'train', familyId: 'a_pied');
      }
      final result = engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(result.accepted, isTrue);
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

      engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(engine.state.completedFamilyIds, isEmpty);
      expect(engine.state.availableDestinations, isEmpty);
    });

    test('completer une famille rend sa destination disponible', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');
      final result = engine.placeWord(wordText: 'gare', familyId: 'en_train');

      expect(result.completedFamilyId, 'en_train');
      expect(engine.state.completedFamilyIds, contains('en_train'));
      expect(
        engine.state.availableDestinations.map((d) => d.stageId),
        contains('gare'),
      );
    });

    test('completer une famille ne termine pas l\'etape', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');
      engine.placeWord(wordText: 'gare', familyId: 'en_train');

      expect(engine.state.isFinished, isFalse);
      expect(engine.state.departedTo, isNull);
    });

    test('plusieurs destinations peuvent etre disponibles en meme temps', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');
      engine.placeWord(wordText: 'gare', familyId: 'en_train');
      engine.placeWord(wordText: 'chaussure', familyId: 'a_pied');
      engine.placeWord(wordText: 'trottoir', familyId: 'a_pied');

      expect(
        engine.state.availableDestinations.map((d) => d.stageId),
        containsAll(<String>['gare', 'rue']),
      );
    });
  });

  group('Depart vers une destination', () {
    test('partir termine l\'etape et retient la destination choisie', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');
      engine.placeWord(wordText: 'gare', familyId: 'en_train');
      engine.departTo('gare');

      expect(engine.state.isFinished, isTrue);
      expect(engine.state.departedTo, 'gare');
    });

    test('partir vers une destination non disponible est refuse', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(() => engine.departTo('gare'), throwsStateError);
      expect(engine.state.isFinished, isFalse);
    });

    test('plus aucun placement n\'est accepte apres le depart', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');
      engine.placeWord(wordText: 'gare', familyId: 'en_train');
      engine.departTo('gare');

      expect(
        () => engine.placeWord(wordText: 'chaussure', familyId: 'a_pied'),
        throwsStateError,
      );
    });
  });

  group('Presentation des mots', () {
    test('tous les mots tiennent dans les emplacements de cette etape', () {
      // Quatre mots et six emplacements : la totalite est proposee d'emblee,
      // sans reserve.
      final engine = buildEngine();

      expect(
        engine.visibleWords.whereType<Word>().map((word) => word.text).toSet(),
        buildTestStage().words.map((word) => word.text).toSet(),
      );
      expect(engine.state.remainingInSupply, 0);
    });

    test('l\'ordre est reproductible a graine egale', () {
      List<String?> ids(StageEngine engine) =>
          engine.visibleWords.map((word) => word?.text).toList();

      expect(ids(buildEngine()), ids(buildEngine()));
    });
  });
}
