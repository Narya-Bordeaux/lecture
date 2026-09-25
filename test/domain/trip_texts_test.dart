import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

import '../support/stage_builders.dart' as build;

/// Les deux textes qu'un trajet doit porter, **obligatoires** (decision de
/// l'auteur) : ce que l'enfant lit sous « Bravo ! » quand la boite est
/// pleine, et l'action de depart ecrite sur le bouton — « Prendre la
/// voiture ». Aucun n'est pre-ecrit : sans eux, l'aventure est a finir.

List<ContentIssue> _textIssues(Stage stage) {
  return stage
      .validate()
      .where((issue) => issue.message.contains('« Bravo ! »') ||
          issue.message.contains('bouton de départ'))
      .toList();
}

void main() {
  group('Obligatoires sur chaque trajet', () {
    test('un trajet sans texte ni action est a finir, deux fois', () {
      final stage = build.stage(
        id: 'maison',
        families: <WordFamily>[
          build.family(
            id: 'en_voiture',
            label: 'En voiture',
            words: <Word>[build.word('volant')],
            destination: 'garage',
            withTexts: false,
          ),
        ],
      );

      final issues = _textIssues(stage);
      expect(issues, hasLength(2));
      expect(
        issues.every((issue) => issue.severity == IssueSeverity.incomplete),
        isTrue,
      );
      expect(issues.every((issue) => issue.familyId == 'en_voiture'), isTrue);
      expect(issues.every((issue) => issue.stageId == 'maison'), isTrue);
      // La carte du lieu les compte sur son bouton « Textes ».
      expect(issues.every((issue) => issue.isMissingText), isTrue);
    });

    test('un texte blanc compte comme absent', () {
      final stage = build.stage(
        id: 'maison',
        families: <WordFamily>[
          build.family(
            id: 'en_voiture',
            label: 'En voiture',
            words: <Word>[build.word('volant')],
            destination: 'garage',
            completionText: '   ',
            departureLabel: ' ',
          ),
        ],
      );

      expect(_textIssues(stage), hasLength(2));
    });

    test('les deux ecrits, rien a signaler', () {
      final stage = build.stage(
        id: 'maison',
        families: <WordFamily>[
          build.family(
            id: 'en_voiture',
            label: 'En voiture',
            words: <Word>[build.word('volant')],
            destination: 'garage',
            completionText: 'Tu as trouvé tous les mots « en voiture ».',
            departureLabel: 'Prendre la voiture',
          ),
        ],
      );

      expect(_textIssues(stage), isEmpty);
    });

    test('« autre chose » n\'en demande aucun : elle n\'ouvre rien', () {
      final stage = build.stage(
        id: 'garage',
        families: <WordFamily>[
          build.family(
            id: 'musique',
            label: 'Les types de musique',
            words: <Word>[build.word('rock')],
            destination: 'plage',
          ),
          build.family(
            id: 'autre_chose',
            label: 'Autre chose',
            words: <Word>[build.word('clou')],
          ),
        ],
      );

      expect(_textIssues(stage), isEmpty);
    });
  });

  group('Dans le fichier', () {
    final catalog = WordListCatalog(<String, WordList>{
      'voiture': build.wordList('voiture', <Word>[build.word('volant')]),
    });

    test('l\'action de depart s\'ecrit et se relit', () {
      final family = WordFamily.fromJson(<String, dynamic>{
        'id': 'en_voiture',
        'label': 'En voiture',
        'list': 'voiture',
        'destination': 'garage',
        'departureLabel': 'Prendre la voiture',
      }, catalog);

      expect(family.departureLabel, 'Prendre la voiture');
      expect(family.toJson()['departureLabel'], 'Prendre la voiture');
    });

    test('absente, elle ne s\'ecrit pas', () {
      final family = WordFamily.fromJson(<String, dynamic>{
        'id': 'en_voiture',
        'label': 'En voiture',
        'list': 'voiture',
      }, catalog);

      expect(family.departureLabel, isNull);
      expect(family.toJson().containsKey('departureLabel'), isFalse);
    });

    test('elle s\'efface, et copyWith la garde sinon', () {
      final family = build.family(
        id: 'en_voiture',
        label: 'En voiture',
        words: <Word>[build.word('volant')],
        destination: 'garage',
        departureLabel: 'Prendre la voiture',
      );

      expect(
        family.copyWith(label: 'La voiture').departureLabel,
        'Prendre la voiture',
      );
      expect(
        family.copyWith(clearDepartureLabel: true).departureLabel,
        isNull,
      );
    });
  });
}
