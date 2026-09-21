import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_engine.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Le tirage des mots, et ce que la validation en dit.
///
/// Une liste est **reutilisable et plus grande que la partie** : a l'entree du
/// lieu, le moteur en tire quelques mots. Deux consequences, et ce sont les
/// deux moities de ce fichier.
///
/// 1. Les mots communs aux listes d'un meme lieu sont **retires avant le
///    tirage**. Un mot ambigu ne peut donc plus arriver a l'ecran — la regle
///    n'est pas abandonnee, elle change de main : la machine l'applique au lieu
///    de l'auteur.
/// 2. « Assez de mots » cesse d'etre une propriete de la liste pour devenir une
///    propriete de **la liste a ce lieu-la** : la meme liste exclut
///    differemment selon ses voisines.

List<Word> words(List<String> texts) {
  return texts.map((text) => word(text)).toList();
}

/// Les mots reellement en jeu dans une famille, une fois le tirage fait.
Set<String> drawnIn(Stage stage, String familyId, int seed) {
  final drawn = stage.drawnWith(Random(seed));
  return drawn.findFamily(familyId)!.list.wordTexts;
}

void main() {
  group('Les mots communs sont retires avant le tirage', () {
    /// Deux familles qui partagent « moteur » et « roue ». C'est l'exemple de
    /// `CLAUDE.md` : un bus est une voiture en plus grand.
    Stage sharingStage() {
      return stage(
        id: 'maison',
        families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: words(<String>['moteur', 'roue', 'arret', 'ticket']),
            destination: 'gare',
          ),
          family(
            id: 'en_voiture',
            label: 'En voiture',
            words: words(<String>['moteur', 'roue', 'volant', 'essence']),
            destination: 'garage',
          ),
        ],
      );
    }

    test('aucun mot partage n\'arrive a l\'ecran', () {
      final stageAtPlay = sharingStage().drawnWith(Random(1));

      final bus = stageAtPlay.findFamily('en_bus')!.list.wordTexts;
      final car = stageAtPlay.findFamily('en_voiture')!.list.wordTexts;

      expect(bus.intersection(car), isEmpty);
      expect(bus, <String>{'arret', 'ticket'});
      expect(car, <String>{'volant', 'essence'});
    });

    test('ecrire le meme mot dans deux listes n\'est plus une faute', () {
      // C'est meme devenu la facon de declarer qu'il est ambigu ici : la
      // regle tenait a la main de l'auteur, elle passe a la machine.
      final issues = sharingStage().validate();

      expect(issues.where((issue) => issue.severity == IssueSeverity.wrong),
          isEmpty);
      expect(issues.any((issue) => issue.message.contains('ambigu')), isFalse);
    });

    test('le moteur ne propose que les mots tires', () {
      final engine = StageEngine(stage: sharingStage(), random: Random(1));

      final onScreen = engine.visibleWords
          .whereType<Word>()
          .map((word) => word.text)
          .toSet();

      expect(onScreen, isNot(contains('moteur')));
      expect(onScreen, isNot(contains('roue')));
      expect(onScreen.length, 4);
    });
  });

  group('Le tirage', () {
    /// Une liste large : plus de mots que la partie n'en demande.
    Stage wideStage({int? stageDraw, int? familyDraw}) {
      return stage(
        id: 'maison',
        drawCount: stageDraw,
        families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: words(<String>[
              'arret', 'ticket', 'horaire', 'abri', 'ligne', 'terminus',
              'guichet', 'couloir', 'banquette', 'sonnette', 'quai', 'feu',
            ]),
            destination: 'gare',
            drawCount: familyDraw,
          ),
        ],
      );
    }

    test('il prend le nombre demande, pas toute la liste', () {
      expect(drawnIn(wideStage(stageDraw: 4), 'en_bus', 1), hasLength(4));
    });

    test('sans nombre demande, toute la liste reste en jeu', () {
      // Le comportement d'avant la reserve tirée : rien ne change pour un
      // contenu qui ne demande rien.
      expect(drawnIn(wideStage(), 'en_bus', 1), hasLength(12));
    });

    test('la famille l\'emporte sur le defaut du lieu', () {
      expect(
        drawnIn(wideStage(stageDraw: 7, familyDraw: 3), 'en_bus', 1),
        hasLength(3),
      );
    });

    test('rejouer la meme partie donne d\'autres mots', () {
      // C'est le benefice recherche : la liste survit a la partie.
      final draws = <Set<String>>{
        for (var seed = 1; seed <= 10; seed++)
          drawnIn(wideStage(stageDraw: 4), 'en_bus', seed),
      };

      expect(draws.length, greaterThan(1));
    });

    test('la meme graine donne le meme tirage', () {
      // Sans cela aucun test de moteur ne serait reproductible.
      expect(
        drawnIn(wideStage(stageDraw: 4), 'en_bus', 7),
        drawnIn(wideStage(stageDraw: 4), 'en_bus', 7),
      );
    });

    test('demander plus que disponible prend ce qu\'il y a', () {
      // Le moteur ne casse pas sur un contenu trop maigre ; c'est `validate()`
      // qui le dit, et l'outil d'auteur qui le montre.
      expect(drawnIn(wideStage(stageDraw: 40), 'en_bus', 1), hasLength(12));
    });
  });

  group('Assez de mots, une fois l\'exclusion faite', () {
    Stage stageWithDraw(int draw, List<String> bus, List<String> car) {
      return stage(
        id: 'maison',
        drawCount: draw,
        families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: words(bus),
            destination: 'gare',
          ),
          family(
            id: 'en_voiture',
            label: 'En voiture',
            words: words(car),
            destination: 'garage',
          ),
        ],
      );
    }

    test('il en manque : c\'est incomplet, et le compte est dit', () {
      final issues = stageWithDraw(
        4,
        <String>['moteur', 'roue', 'arret', 'ticket'],
        <String>['moteur', 'roue', 'volant', 'essence'],
      ).validate();

      final shortage = issues.firstWhere(
        (issue) => issue.familyId == 'en_bus' && issue.message.contains('4'),
      );

      // Ecrire d'autres mots est le remede, et c'est le geste normal de
      // l'ecriture : rien ici n'est faux.
      expect(shortage.severity, IssueSeverity.incomplete);
      expect(shortage.message, contains('2'));
    });

    test('il y en a assez : rien n\'est signale', () {
      final issues = stageWithDraw(
        2,
        <String>['moteur', 'arret', 'ticket'],
        <String>['moteur', 'volant', 'essence'],
      ).validate();

      expect(issues, isEmpty);
    });

    test('l\'exclusion vide entierement une liste : c\'est faux', () {
      // Les deux listes disent alors la meme chose, et continuer d'ecrire n'y
      // changera rien.
      final issues = stageWithDraw(
        2,
        <String>['moteur', 'roue'],
        <String>['moteur', 'roue', 'volant', 'essence'],
      ).validate();

      final emptied = issues.firstWhere(
        (issue) =>
            issue.familyId == 'en_bus' &&
            issue.severity == IssueSeverity.wrong,
      );

      expect(emptied.message, contains('en_bus'));
    });

    test('sans nombre demande, rien n\'est exige', () {
      // L'auteur n'a rien promis : il joue avec ce qui reste.
      final issues = stage(
        id: 'maison',
        families: <WordFamily>[
          family(
            id: 'en_bus',
            label: 'En bus',
            words: words(<String>['moteur', 'arret']),
            destination: 'gare',
          ),
          family(
            id: 'en_voiture',
            label: 'En voiture',
            words: words(<String>['moteur', 'volant']),
            destination: 'garage',
          ),
        ],
      ).validate();

      expect(issues, isEmpty);
    });
  });
}
