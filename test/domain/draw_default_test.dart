import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';

import '../support/stage_builders.dart';

/// **Sept mots par zone** (0.42.0), decision de l'auteur : sans reglage, chaque
/// zone tire cinq mots — la zone « autre chose » comprise, qui les puise dans
/// l'ensemble de ses listes cochees, et non cinq par liste.
///
/// Sans reglage, la liste jouait entiere : une zone de douze mots s'annoncait
/// « 0 / 12 » et en exigeait douze.

List<Word> wordsNamed(String prefix, int count) =>
    List<Word>.generate(count, (index) => word('$prefix$index'));

void main() {
  test('sans reglage, une zone tire cinq mots', () {
    final stage = build(
      families: <WordFamily>[
        family(
          id: 'a',
          label: 'A',
          words: wordsNamed('a', 12),
          destination: 'fin',
        ),
      ],
    );

    expect(Stage.defaultDrawCount, 5);
    expect(stage.drawCountFor(stage.families.single), 5);
    expect(
      stage.drawnWith(Random(1)).families.single.requiredCount,
      5,
    );
  });

  test('la zone « autre chose » tire cinq mots dans l\'ensemble de ses listes',
      () {
    final theme = family(
      id: 'theme',
      label: 'Ce qui se mange',
      words: wordsNamed('mange', 9),
      destination: 'fin',
    );
    final rest = WordFamily(
      id: 'reste',
      label: 'Le reste',
      lists: <WordList>[
        wordList('objets', wordsNamed('objet', 5)),
        wordList('outils', wordsNamed('outil', 5)),
      ],
    );
    final stage = build(families: <WordFamily>[theme, rest]);

    final drawn = stage.drawnWith(Random(3)).findFamily('reste')!;
    // Cinq en tout, et non cinq par liste : dix mots disponibles, cinq tires.
    expect(drawn.requiredCount, 5);
  });

  test('une liste de moins de cinq mots est a finir', () {
    // Option A, choisie par l'auteur : une zone courte n'est pas jouee
    // entiere en silence, elle demande qu'on ecrive les mots manquants.
    final stage = build(
      families: <WordFamily>[
        family(
          id: 'a',
          label: 'A',
          words: wordsNamed('a', 3),
          destination: 'fin',
        ),
      ],
    );

    expect(
      stage.validate().where(
            (issue) =>
                issue.severity == IssueSeverity.incomplete &&
                issue.familyId == 'a',
          ),
      isNotEmpty,
    );
  });

  test('un reglage explicite l\'emporte sur le defaut', () {
    final stage = build(
      drawCount: 3,
      families: <WordFamily>[
        family(
          id: 'a',
          label: 'A',
          words: wordsNamed('a', 12),
          destination: 'fin',
        ),
      ],
    );

    expect(stage.drawCountFor(stage.families.single), 3);
  });
}

Stage build({required List<WordFamily> families, int? drawCount}) =>
    stage(id: 'lieu', families: families, drawCount: drawCount);
