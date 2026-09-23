import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart' as build;

/// Un lieu se joue-t-il seul, pour que l'auteur l'essaie sur l'appareil ?
///
/// Il faut des familles, et que chacune garde au moins un mot une fois les
/// mots communs retires : une famille vide s'ouvrirait d'elle-meme, sans que
/// rien ait ete trie, et l'essai mentirait sur ce que l'enfant vivra.
void main() {
  test('un lieu dont chaque famille a des mots se joue seul', () {
    final stage = build.stage(
      id: 'maison',
      families: <WordFamily>[
        build.family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[build.word('ticket')],
          destination: 'gare',
        ),
        build.family(
          id: 'a_pied',
          label: 'À pied',
          words: <Word>[build.word('sentier')],
          destination: 'rue',
        ),
      ],
    );

    expect(stage.canBeTriedAlone, isTrue);
  });

  test('une fin ne se joue pas : il n\'y a rien a trier', () {
    expect(build.ending(id: 'plage').canBeTriedAlone, isFalse);
  });

  test('un lieu a definir ne se joue pas', () {
    expect(
      build.stage(id: 'neuf', families: const <WordFamily>[]).canBeTriedAlone,
      isFalse,
    );
  });

  test('une famille sans mot empeche l\'essai', () {
    final stage = build.stage(
      id: 'maison',
      families: <WordFamily>[
        build.family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[build.word('ticket')],
          destination: 'gare',
        ),
        build.family(
          id: 'a_pied',
          label: 'À pied',
          words: const <Word>[],
          destination: 'rue',
        ),
      ],
    );

    expect(stage.canBeTriedAlone, isFalse);
  });

  test('une famille videe par les mots communs empeche l\'essai', () {
    final stage = build.stage(
      id: 'maison',
      families: <WordFamily>[
        build.family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[build.word('roue')],
          destination: 'gare',
        ),
        build.family(
          id: 'en_voiture',
          label: 'En voiture',
          words: <Word>[build.word('roue')],
          destination: 'garage',
        ),
      ],
    );

    expect(stage.canBeTriedAlone, isFalse);
  });
}
