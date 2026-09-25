import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/completion_message.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

import '../support/stage_builders.dart' as build;

/// Le message qui s'ouvre quand l'enfant a range tous les mots d'une boite.
///
/// « Bravo ! » en titre, toujours ; dessous, un texte que l'auteur peut
/// ecrire, et qui sinon se compose de lui-meme d'apres le lieu.

WordFamily _trip(String id, String label, {String? completionText}) {
  final family = build.family(
    id: id,
    label: label,
    words: <Word>[build.word('$id-1')],
    destination: 'vers_$id',
  );
  return completionText == null
      ? family
      : family.copyWith(completionText: completionText);
}

Stage _house({String? busText}) {
  return build.stage(
    id: 'maison',
    families: <WordFamily>[
      _trip('en_bus', 'En bus', completionText: busText),
      _trip('a_pied', 'À pied'),
    ],
  );
}

const Map<String, String> _names = <String, String>{
  'vers_en_bus': 'La gare',
  'vers_a_pied': 'Le sentier',
};

void main() {
  group('Le texte propose', () {
    test('dit la boite rangee, le lieu atteint, et l\'autre choix', () {
      expect(
        CompletionMessage.defaultText(
          familyLabel: 'En bus',
          destinationName: 'La gare',
          otherPathsRemain: true,
        ),
        'Tu as rangé tous les mots «\u00A0En bus\u00A0». Tu peux partir vers la gare, '
        'ou ouvrir un autre chemin.',
      );
    });

    test('sans autre chemin a ouvrir, il ne le propose pas', () {
      expect(
        CompletionMessage.defaultText(
          familyLabel: 'À pied',
          destinationName: 'Le sentier',
          otherPathsRemain: false,
        ),
        'Tu as rangé tous les mots «\u00A0À pied\u00A0». Tu peux partir vers le sentier.',
      );
    });

    test('seul l\'article prend une minuscule, pas un nom propre', () {
      String towards(String name) => CompletionMessage.defaultText(
            familyLabel: 'En train',
            destinationName: name,
            otherPathsRemain: false,
          );

      expect(towards('L\'école'), contains('vers l\'école.'));
      expect(towards('Les dunes'), contains('vers les dunes.'));
      expect(towards('Une cabane'), contains('vers une cabane.'));
      expect(towards('Paris'), contains('vers Paris.'));
      expect(towards('Lyon'), contains('vers Lyon.'));
    });

    test('sans nom de lieu, il parle du chemin', () {
      // L'outil fait essayer un lieu seul, sans le reste de l'aventure.
      expect(
        CompletionMessage.defaultText(
          familyLabel: 'En bus',
          otherPathsRemain: false,
        ),
        'Tu as rangé tous les mots «\u00A0En bus\u00A0». Tu peux suivre ce chemin.',
      );
    });
  });

  group('Au moment ou la boite est complete', () {
    test('le texte propose, quand l\'auteur n\'a rien ecrit', () {
      final message = CompletionMessage.forFamily(
        stage: _house(),
        familyId: 'a_pied',
        completedFamilyIds: const <String>{'a_pied'},
        destinationNames: _names,
      );

      expect(message, isNotNull);
      expect(message!.title, 'Bravo !');
      expect(
        message.body,
        'Tu as rangé tous les mots «\u00A0À pied\u00A0». Tu peux partir vers le sentier, '
        'ou ouvrir un autre chemin.',
      );
    });

    test('plus d\'autre chemin quand toutes les boites sont rangees', () {
      final message = CompletionMessage.forFamily(
        stage: _house(),
        familyId: 'a_pied',
        completedFamilyIds: const <String>{'en_bus', 'a_pied'},
        destinationNames: _names,
      );

      expect(message!.body, isNot(contains('autre chemin')));
    });

    test('le texte de l\'auteur, quand il en a ecrit un', () {
      final message = CompletionMessage.forFamily(
        stage: _house(busText: 'Le bus arrive au coin de la rue !'),
        familyId: 'en_bus',
        completedFamilyIds: const <String>{'en_bus'},
        destinationNames: _names,
      );

      expect(message!.title, 'Bravo !');
      expect(message.body, 'Le bus arrive au coin de la rue !');
    });

    test('« autre chose » ne dit rien : elle n\'ouvre aucun chemin', () {
      final stage = build.stage(
        id: 'boutique',
        families: <WordFamily>[
          _trip('a_manger', 'Ce qui se mange'),
          build.family(
            id: 'autre_chose',
            label: 'Autre chose',
            words: <Word>[build.word('clou')],
          ),
        ],
      );

      expect(
        CompletionMessage.forFamily(
          stage: stage,
          familyId: 'autre_chose',
          completedFamilyIds: const <String>{'autre_chose'},
          destinationNames: _names,
        ),
        isNull,
      );
    });
  });

  group('Pour l\'outil d\'auteur', () {
    test('le texte propose se lit comme si d\'autres chemins restaient', () {
      // C'est le cas le plus frequent au moment ou l'enfant range sa premiere
      // boite ; le jeu retire la fin d'elle-meme quand il n'en reste plus.
      expect(
        CompletionMessage.proposedFor(
          stage: _house(),
          familyId: 'en_bus',
          destinationNames: _names,
        ),
        'Tu as rangé tous les mots «\u00A0En bus\u00A0». Tu peux partir vers la gare, '
        'ou ouvrir un autre chemin.',
      );
    });

    test('un lieu a une seule sortie ne propose jamais d\'autre chemin', () {
      final stage = build.stage(
        id: 'boutique',
        families: <WordFamily>[_trip('en_bus', 'En bus')],
      );
      expect(
        CompletionMessage.proposedFor(
          stage: stage,
          familyId: 'en_bus',
          destinationNames: _names,
        ),
        isNot(contains('autre chemin')),
      );
    });

    test('garder le texte propose n\'ecrit rien : il suivra les noms', () {
      final proposed = CompletionMessage.proposedFor(
        stage: _house(),
        familyId: 'en_bus',
        destinationNames: _names,
      );

      expect(CompletionMessage.storedText(proposed, proposed: proposed),
          isNull);
      expect(CompletionMessage.storedText('  ', proposed: proposed), isNull);
      expect(
        CompletionMessage.storedText(' Le bus arrive ! ', proposed: proposed),
        'Le bus arrive !',
      );
    });
  });

  group('Dans le fichier', () {
    final catalog = WordListCatalog(<String, WordList>{
      'bus': build.wordList('bus', <Word>[build.word('ticket')]),
    });

    test('le texte de l\'auteur s\'ecrit et se relit', () {
      final json = WordFamily.fromJson(<String, dynamic>{
        'id': 'en_bus',
        'label': 'En bus',
        'list': 'bus',
        'destination': 'gare',
        'completionText': 'Le bus arrive !',
      }, catalog);

      expect(json.completionText, 'Le bus arrive !');
      expect(json.toJson()['completionText'], 'Le bus arrive !');
    });

    test('absent, il ne s\'ecrit pas', () {
      final family = WordFamily.fromJson(<String, dynamic>{
        'id': 'en_bus',
        'label': 'En bus',
        'list': 'bus',
      }, catalog);

      expect(family.completionText, isNull);
      expect(family.toJson().containsKey('completionText'), isFalse);
    });

    test('il s\'efface, et copyWith le garde sinon', () {
      final family = _trip('en_bus', 'En bus', completionText: 'Le bus !');

      expect(family.copyWith(label: 'En car').completionText, 'Le bus !');
      expect(
        family.copyWith(clearCompletionText: true).completionText,
        isNull,
      );
    });
  });
}
