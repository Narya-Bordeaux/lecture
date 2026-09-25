import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_introduction.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart' as build;

const RelativeArea _somewhere = RelativeArea(
  left: 0.1,
  top: 0.4,
  width: 0.2,
  height: 0.2,
);

WordFamily _trip(String id, {RelativeArea? area = _somewhere}) {
  return build.family(
    id: id,
    label: id,
    words: <Word>[build.word('$id-1')],
    destination: 'ailleurs',
    area: area,
  );
}

WordFamily _others() {
  return build.family(
    id: 'les_autres',
    label: 'Les autres',
    words: <Word>[build.word('caillou')],
    area: _somewhere,
  );
}

Stage _stage({
  required List<WordFamily> families,
  String? arrivalText = 'Y ira-t-elle a pied, en bus ou en voiture ?',
}) {
  return build.stage(id: 'maison', families: families, arrivalText: arrivalText);
}

/// Avance jusqu'a la premiere boite, en passant le decor et l'enonce.
StageIntroduction _untilFirstFamily(Stage stage) {
  return StageIntroduction.forStage(stage).advance().advance();
}

void main() {
  group('Le deroule', () {
    test('commence par le decor seul', () {
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus')]),
      );

      expect(introduction.step, IntroductionStep.background);
      expect(introduction.isTrayVisible, isFalse);
      expect(introduction.canMoveWords, isFalse);
      expect(introduction.presentedFamilyId, isNull);
      expect(introduction.isFamilyPlaced('en_bus'), isFalse);
    });

    test('le decor seul dure un quart de seconde', () {
      // Decision de l'auteur : juste le temps de voir le lieu avant le texte.
      expect(
        StageIntroduction.backgroundOnlyDuration,
        const Duration(milliseconds: 250),
      );
    });

    test('puis l\'enonce, toujours sans cartouche', () {
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus')]),
      ).advance();

      expect(introduction.step, IntroductionStep.statement);
      expect(introduction.isTrayVisible, isFalse);
      expect(introduction.canMoveWords, isFalse);
    });

    test('fermer l\'enonce montre le cartouche et presente la premiere boite',
        () {
      final introduction = _untilFirstFamily(
        _stage(families: <WordFamily>[_trip('en_bus'), _trip('a_pied')]),
      );

      expect(introduction.step, IntroductionStep.families);
      expect(introduction.isTrayVisible, isTrue);
      expect(introduction.presentedFamilyId, 'en_bus');
      expect(introduction.isFamilyPlaced('en_bus'), isFalse);
      // Les mots se lisent, mais ne bougent pas encore.
      expect(introduction.canMoveWords, isFalse);
    });

    test('chaque boite rangee presente la suivante', () {
      final introduction = _untilFirstFamily(
        _stage(families: <WordFamily>[_trip('en_bus'), _trip('a_pied')]),
      ).advance();

      expect(introduction.step, IntroductionStep.families);
      expect(introduction.isFamilyPlaced('en_bus'), isTrue);
      expect(introduction.presentedFamilyId, 'a_pied');
      expect(introduction.isFamilyPlaced('a_pied'), isFalse);
    });

    test('la derniere boite rangee ouvre le jeu', () {
      final introduction = _untilFirstFamily(
        _stage(families: <WordFamily>[_trip('en_bus'), _trip('a_pied')]),
      ).advance().advance();

      expect(introduction.step, IntroductionStep.playing);
      expect(introduction.isTrayVisible, isTrue);
      expect(introduction.canMoveWords, isTrue);
      expect(introduction.presentedFamilyId, isNull);
      expect(introduction.isFamilyPlaced('en_bus'), isTrue);
      expect(introduction.isFamilyPlaced('a_pied'), isTrue);
    });

    test('rien ne suit le jeu', () {
      final playing = _untilFirstFamily(
        _stage(families: <WordFamily>[_trip('en_bus')]),
      ).advance();

      expect(playing.advance, throwsStateError);
    });

    test('chaque pas rend un nouvel etat, sans toucher au precedent', () {
      final start = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus')]),
      );

      start.advance();

      expect(start.step, IntroductionStep.background);
    });
  });

  group('L\'ordre des boites', () {
    test('suit l\'ordre de creation', () {
      final introduction = StageIntroduction.forStage(
        _stage(
          families: <WordFamily>[
            _trip('en_voiture'),
            _trip('en_bus'),
            _trip('a_pied'),
          ],
        ),
      );

      expect(
        introduction.familyOrder,
        <String>['en_voiture', 'en_bus', 'a_pied'],
      );
    });

    test('« les autres » viennent toujours en dernier', () {
      // Le fichier peut ecrire la liste du reste avant le theme : elle se
      // presente quand meme en dernier, le theme donnant son sens au reste.
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_others(), _trip('villes')]),
      );

      expect(introduction.familyOrder, <String>['villes', 'les_autres']);
    });

    test('une boite sans place sur le decor n\'est pas presentee', () {
      // Elle n'aurait nulle part ou aller : un lieu en cours de calage, que
      // l'outil d'auteur fait essayer.
      final introduction = StageIntroduction.forStage(
        _stage(
          families: <WordFamily>[_trip('en_bus'), _trip('a_pied', area: null)],
        ),
      );

      expect(introduction.familyOrder, <String>['en_bus']);
    });
  });

  group('Ce qui manque se saute', () {
    test('sans enonce, le decor mene droit aux boites', () {
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus')], arrivalText: null),
      ).advance();

      expect(introduction.step, IntroductionStep.families);
      expect(introduction.presentedFamilyId, 'en_bus');
    });

    test('un enonce blanc compte comme absent', () {
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus')], arrivalText: '   '),
      ).advance();

      expect(introduction.step, IntroductionStep.families);
    });

    test('sans boite a presenter, l\'enonce mene droit au jeu', () {
      final introduction = StageIntroduction.forStage(
        _stage(families: <WordFamily>[_trip('en_bus', area: null)]),
      ).advance().advance();

      expect(introduction.step, IntroductionStep.playing);
    });
  });

  group('Sans mise en place', () {
    test('le jeu est ouvert d\'emblee, toutes les boites en place', () {
      // C'est l'apercu de l'outil de calage : l'auteur y voit la scene
      // entiere, et non son introduction.
      final introduction = StageIntroduction.skipped(
        _stage(families: <WordFamily>[_trip('en_bus'), _others()]),
      );

      expect(introduction.step, IntroductionStep.playing);
      expect(introduction.isTrayVisible, isTrue);
      expect(introduction.canMoveWords, isTrue);
      expect(introduction.isFamilyPlaced('en_bus'), isTrue);
      expect(introduction.isFamilyPlaced('les_autres'), isTrue);
    });
  });
}
