import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/hint.dart';
import 'package:reading_game/domain/models/hint_policy.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';

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
          build.word('chaussure', <String>['chau', 'ssure']),
          build.word('trottoir', <String>['trot', 'toir']),
        ],
        destination: 'rue',
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

  group('Comptage des erreurs', () {
    test('compte les erreurs mot par mot, sans les melanger', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'a_pied');
      engine.placeWord(wordText: 'train', familyId: 'a_pied');
      engine.placeWord(wordText: 'chaussure', familyId: 'en_train');

      expect(engine.state.errorCountFor('train'), 2);
      expect(engine.state.errorCountFor('chaussure'), 1);
      expect(engine.state.errorCountFor('trottoir'), 0);
    });

    test('un placement correct n\'incremente aucun compteur', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(engine.state.errorCountFor('train'), 0);
    });
  });

  group('Deblocage automatique des aides', () {
    test('la premiere erreur debloque le decoupage en syllabes', () {
      final engine = buildEngine();

      final result = engine.placeWord(wordText: 'train', familyId: 'a_pied');

      expect(result.unlockedHints, contains(Hint.syllables));
      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('le decoupage est la seule aide du jeu', () {
      // L'illustration a ete ecartee : avec trois familles, les possibilites
      // se reduisent d'elles-memes et montrer l'image donnerait la reponse.
      final engine = buildEngine();

      for (var attempt = 1; attempt <= 8; attempt++) {
        engine.placeWord(wordText: 'train', familyId: 'a_pied');
      }

      expect(engine.state.hintsFor('train'), <Hint>{Hint.syllables});
      expect(Hint.values, <Hint>[Hint.syllables]);
    });

    test('une aide n\'est signalee comme nouvelle qu\'une seule fois', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'a_pied');
      final second = engine.placeWord(wordText: 'train', familyId: 'a_pied');

      expect(second.unlockedHints, isEmpty);
      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('les aides restent acquises apres le placement correct', () {
      final engine = buildEngine();

      engine.placeWord(wordText: 'train', familyId: 'a_pied');
      engine.placeWord(wordText: 'train', familyId: 'en_train');

      expect(engine.state.hintsFor('train'), contains(Hint.syllables));
    });

    test('le seuil est celui de la politique injectee', () {
      final engine = buildEngine(
        policy: const HintPolicy(syllablesThreshold: 2),
      );

      final first = engine.placeWord(wordText: 'train', familyId: 'a_pied');
      expect(first.unlockedHints, isEmpty);

      final second = engine.placeWord(wordText: 'train', familyId: 'a_pied');
      expect(second.unlockedHints, contains(Hint.syllables));
    });

    test('une aide peut etre demandee sans avoir commis d\'erreur', () {
      final engine = buildEngine();

      engine.requestHint(wordText: 'chaussure', hint: Hint.syllables);

      expect(engine.state.hintsFor('chaussure'), contains(Hint.syllables));
      expect(engine.state.errorCountFor('chaussure'), 0);
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
