import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/praise_schedule.dart';

/// La petite recompense d'un mot bien place : la tete de Grisbie a chaque
/// fois, et un mot d'encouragement tous les deux ou trois mots.

const _heads = <String>['admiratif', 'clindoeil'];
const _comments = <String>['Super !', 'Bien joué !', 'Génial !', 'Oui !'];

PraiseSchedule _schedule(int seed) => PraiseSchedule(
      heads: _heads,
      comments: _comments,
      random: Random(seed),
    );

/// Les recompenses de [count] bons placements, aucun ne remplissant de boite.
List<Praise?> _praises(PraiseSchedule schedule, int count) => <Praise?>[
      for (var index = 0; index < count; index++)
        schedule.next(boxCelebrated: false),
    ];

void main() {
  test('chaque bon placement fait paraitre une tete', () {
    for (final praise in _praises(_schedule(1), 30)) {
      expect(praise, isNotNull);
      expect(_heads, contains(praise!.head));
    }
  });

  test('les tetes alternent', () {
    final heads = _praises(_schedule(1), 6).map((praise) => praise!.head);

    expect(heads, <String>[
      'admiratif', 'clindoeil', 'admiratif',
      'clindoeil', 'admiratif', 'clindoeil',
    ]);
  });

  for (final seed in <int>[1, 2, 3, 4, 5, 6, 7, 8]) {
    test('un commentaire tous les deux ou trois mots (graine $seed)', () {
      final praises = _praises(_schedule(seed), 40);
      // Le rang de chaque bon placement qui porte un commentaire, a partir
      // de 1 : le premier arrive au deuxieme ou au troisieme mot.
      final ranks = <int>[
        for (var index = 0; index < praises.length; index++)
          if (praises[index]!.comment != null) index + 1,
      ];

      expect(ranks, isNotEmpty);
      var previous = 0;
      for (final rank in ranks) {
        expect(rank - previous, inInclusiveRange(2, 3), reason: '$ranks');
        previous = rank;
      }
    });
  }

  test('les deux rythmes se rencontrent, l enfant ne peut pas prevoir', () {
    final gaps = <int>{};
    for (var seed = 0; seed < 20; seed++) {
      final praises = _praises(_schedule(seed), 20);
      var previous = 0;
      for (var index = 0; index < praises.length; index++) {
        if (praises[index]!.comment == null) continue;
        gaps.add(index + 1 - previous);
        previous = index + 1;
      }
    }

    expect(gaps, <int>{2, 3});
  });

  test('jamais deux fois de suite le meme mot', () {
    for (var seed = 0; seed < 20; seed++) {
      final comments = _praises(_schedule(seed), 60)
          .map((praise) => praise!.comment)
          .whereType<String>()
          .toList();
      for (var index = 1; index < comments.length; index++) {
        expect(comments[index], isNot(comments[index - 1]));
      }
      expect(_comments, containsAll(comments.toSet()));
    }
  });

  test('une boite pleine a son « Bravo ! » : pas de tete', () {
    final schedule = _schedule(1);

    expect(schedule.next(boxCelebrated: true), isNull);
  });

  test('apres le « Bravo ! », le compte repart de zero', () {
    // Sans quoi un commentaire pourrait tomber juste apres la grande
    // fenetre.
    for (var seed = 0; seed < 20; seed++) {
      final schedule = _schedule(seed);
      schedule.next(boxCelebrated: false);
      schedule.next(boxCelebrated: true);

      expect(schedule.next(boxCelebrated: false)!.comment, isNull,
          reason: 'graine $seed');
    }
  });

  test('il faut au moins une tete et un mot', () {
    expect(
      () => PraiseSchedule(heads: const <String>[], comments: _comments),
      throwsArgumentError,
    );
    expect(
      () => PraiseSchedule(heads: _heads, comments: const <String>[]),
      throwsArgumentError,
    );
  });
}
