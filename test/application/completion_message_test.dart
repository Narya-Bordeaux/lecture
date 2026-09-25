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
/// « Bravo ! » en titre, toujours ; dessous, le texte que l'auteur a ecrit.
/// Rien n'est pre-ecrit.

Stage _garage({String? completionText, bool withTexts = true}) {
  return build.stage(
    id: 'garage',
    families: <WordFamily>[
      build.family(
        id: 'musique',
        label: 'Les types de musique',
        words: <Word>[build.word('rock')],
        destination: 'plage',
        completionText: completionText,
        withTexts: withTexts,
      ),
      build.family(
        id: 'autre_chose',
        label: 'Autre chose',
        words: <Word>[build.word('clou')],
      ),
    ],
  );
}

void main() {
  test('« Bravo ! » en titre, le texte de l\'auteur dessous', () {
    final message = CompletionMessage.forFamily(
      stage: _garage(
        completionText: 'Tu as reconnu toute la musique. Tu peux quitter le '
            'garage.',
      ),
      familyId: 'musique',
    );

    expect(message!.title, 'Bravo !');
    expect(
      message.body,
      'Tu as reconnu toute la musique. Tu peux quitter le garage.',
    );
  });

  test('rien n\'est compose : sans texte, « Bravo ! » seul', () {
    // Un lieu inacheve, que l'outil fait essayer : le jeu, lui, refuse de
    // l'ouvrir.
    final message = CompletionMessage.forFamily(
      stage: _garage(withTexts: false),
      familyId: 'musique',
    );

    expect(message!.title, 'Bravo !');
    expect(message.body, isNull);
  });

  test('« autre chose » ne dit rien : elle n\'ouvre aucun chemin', () {
    expect(
      CompletionMessage.forFamily(stage: _garage(), familyId: 'autre_chose'),
      isNull,
    );
  });

  group('Dans le fichier', () {
    final catalog = WordListCatalog(<String, WordList>{
      'bus': build.wordList('bus', <Word>[build.word('ticket')]),
    });

    test('le texte de l\'auteur s\'ecrit et se relit', () {
      final family = WordFamily.fromJson(<String, dynamic>{
        'id': 'en_bus',
        'label': 'En bus',
        'list': 'bus',
        'destination': 'gare',
        'completionText': 'Le bus arrive !',
      }, catalog);

      expect(family.completionText, 'Le bus arrive !');
      expect(family.toJson()['completionText'], 'Le bus arrive !');
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
      final family = build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('ticket')],
        destination: 'gare',
        completionText: 'Le bus !',
      );

      expect(family.copyWith(label: 'En car').completionText, 'Le bus !');
      expect(
        family.copyWith(clearCompletionText: true).completionText,
        isNull,
      );
    });
  });
}
