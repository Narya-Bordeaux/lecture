import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';
import 'package:grisbie/ui/pages/word_list_page.dart';

import '../support/stage_builders.dart';

/// L'ecran de liste, ouvert en touchant un trajet.
///
/// **Il n'y a pas de mot seul** : un trajet sans liste en cree une ou en
/// reutilise une. Un mot deja connu garde son decoupage ; un mot neuf ne
/// s'ajoute pas sans le sien. Le reste d'un tri unique, lui, se compose en
/// cochant des listes.

final Word _ticket = word('ticket', const <String>['ti', 'ket']);

final WordLibrary _library = WordLibrary(
  lexicon: Lexicon(<String, Word>{'ticket': _ticket, 'clé': word('clé')}),
  lists: WordListCatalog(<String, WordList>{
    'bus': wordList('bus', <Word>[_ticket]),
    'objets': wordList('objets', <Word>[word('clé')]),
  }),
);

Adventure _adventure() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'maison',
    stages: <String, Stage>{
      'maison': stage(
        id: 'maison',
        location: 'Devant la maison',
        drawCount: 7,
        families: <WordFamily>[
          WordFamily(
            id: 'en_bus',
            label: 'En bus',
            lists: const <WordList>[],
            destinationStageId: 'boutique',
          ),
        ],
      ),
      'boutique': stage(
        id: 'boutique',
        location: 'La boutique',
        families: <WordFamily>[
          family(
            id: 'a_manger',
            label: 'Ce qui se mange',
            words: <Word>[word('pain')],
            destination: 'plage',
          ),
          WordFamily(id: 'le_reste', label: 'Le reste', lists: const <WordList>[]),
        ],
      ),
      'plage': ending(id: 'plage'),
    },
  );
}

/// Ce que la page a rendu en se fermant.
class ListOutcome {
  Adventure? kept;
  bool closed = false;
}

Future<ListOutcome> pumpList(
  WidgetTester tester, {
  String stageId = 'maison',
  String familyId = 'en_bus',
  Adventure? adventure,
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final outcome = ListOutcome();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            outcome.kept = await Navigator.of(context).push<Adventure>(
              MaterialPageRoute<Adventure>(
                builder: (_) => WordListPage(
                  adventure: adventure ?? _adventure(),
                  stageId: stageId,
                  familyId: familyId,
                  library: _library,
                ),
              ),
            );
            outcome.closed = true;
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return outcome;
}

Future<void> keep(WidgetTester tester) async {
  await tester.tap(find.text('Garder'));
  await tester.pumpAndSettle();
}

/// Cree une liste pour le trajet, sous le nom propose.
Future<void> createList(WidgetTester tester) async {
  await tester.tap(find.text('Créer une liste'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
}

Future<void> typeWord(WidgetTester tester, String text, [String? syllables]) async {
  await tester.enterText(find.byKey(const Key('word-text')), text);
  await tester.pumpAndSettle();
  if (syllables != null) {
    await tester.enterText(find.byKey(const Key('word-syllables')), syllables);
    await tester.pumpAndSettle();
  }
}

WordFamily familyIn(Adventure adventure, String stageId, String familyId) =>
    adventure.findStage(stageId)!.findFamily(familyId)!;

void main() {
  group('Un trajet sans liste', () {
    testWidgets('propose de creer ou de reutiliser', (tester) async {
      await pumpList(tester);

      expect(find.text('Ce trajet n\'a pas encore de liste de mots.'), findsOneWidget);
      expect(find.text('Créer une liste'), findsOneWidget);
      expect(find.text('Réutiliser une liste'), findsOneWidget);
    });

    testWidgets('creer une liste la nomme d\'apres le trajet', (tester) async {
      final outcome = await pumpList(tester);
      await createList(tester);
      await keep(tester);

      final bus = familyIn(outcome.kept!, 'maison', 'en_bus');
      expect(bus.list.name, 'En bus');
      expect(bus.words, isEmpty);
    });

    testWidgets('reutiliser une liste en reprend les mots', (tester) async {
      final outcome = await pumpList(tester);

      await tester.tap(find.text('Réutiliser une liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('bus'));
      await tester.pumpAndSettle();
      await keep(tester);

      expect(familyIn(outcome.kept!, 'maison', 'en_bus').wordTexts, <String>{'ticket'});
    });
  });

  group('Ajouter des mots', () {
    testWidgets('un mot neuf demande son decoupage', (tester) async {
      await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'volant');

      // Sans decoupage, rien ne s'ajoute : il n'est jamais calcule.
      final add = tester.widget<FilledButton>(find.byKey(const Key('word-add')));
      expect(add.onPressed, isNull);
    });

    testWidgets('un mot neuf entre avec son decoupage', (tester) async {
      final outcome = await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'volant', 'vo-lant');
      await tester.tap(find.byKey(const Key('word-add')));
      await tester.pumpAndSettle();
      await keep(tester);

      expect(
        familyIn(outcome.kept!, 'maison', 'en_bus').words.single.syllables,
        <String>['vo', 'lant'],
      );
    });

    testWidgets('un mot connu reprend son decoupage', (tester) async {
      final outcome = await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'ticket');

      // Le lexique n'en admet qu'un : le champ disparait, le decoupage se lit.
      expect(find.byKey(const Key('word-syllables')), findsNothing);
      expect(find.text('Déjà connu : ti-ket'), findsOneWidget);

      await tester.tap(find.byKey(const Key('word-add')));
      await tester.pumpAndSettle();
      await keep(tester);

      expect(
        familyIn(outcome.kept!, 'maison', 'en_bus').words.single.syllables,
        <String>['ti', 'ket'],
      );
    });

    testWidgets('les champs se vident pour le mot suivant', (tester) async {
      await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'volant', 'vo-lant');
      await tester.tap(find.byKey(const Key('word-add')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byKey(const Key('word-text'))).controller!.text,
        isEmpty,
      );
      expect(find.text('volant'), findsOneWidget);
    });

    testWidgets('le decompte dit s\'il y a de quoi jouer', (tester) async {
      await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'ticket');
      await tester.tap(find.byKey(const Key('word-add')));
      await tester.pumpAndSettle();

      // Sept mots demandes par lieu, un seul ecrit.
      expect(find.text('1 mot : 1 jouable, il en faut 7.'), findsOneWidget);
    });

    testWidgets('retirer un mot le retire de la liste', (tester) async {
      final outcome = await pumpList(tester);
      await createList(tester);
      await typeWord(tester, 'ticket');
      await tester.tap(find.byKey(const Key('word-add')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Retirer « ticket »'));
      await tester.pumpAndSettle();
      await keep(tester);

      expect(familyIn(outcome.kept!, 'maison', 'en_bus').words, isEmpty);
    });
  });

  group('Le reste d\'un tri unique', () {
    testWidgets('on coche les listes ou il puise', (tester) async {
      final outcome = await pumpList(
        tester,
        stageId: 'boutique',
        familyId: 'le_reste',
      );

      expect(find.textContaining('dans les listes que vous cochez'), findsOneWidget);
      await tester.tap(find.text('objets'));
      await tester.pumpAndSettle();
      await keep(tester);

      expect(
        familyIn(outcome.kept!, 'boutique', 'le_reste').lists.map((l) => l.id),
        <String>['objets'],
      );
    });

    testWidgets('la liste du theme ne se propose pas', (tester) async {
      // Ses mots sont precisement ceux que le reste exclut.
      await pumpList(tester, stageId: 'boutique', familyId: 'le_reste');

      expect(find.text('a_manger'), findsNothing);
      expect(find.text('bus'), findsOneWidget);
    });
  });

  testWidgets('fermer sans garder ne rend rien', (tester) async {
    final outcome = await pumpList(tester);
    await createList(tester);

    await tester.tap(find.byTooltip('Fermer sans garder'));
    await tester.pumpAndSettle();

    expect(outcome.closed, isTrue);
    expect(outcome.kept, isNull);
  });
}
