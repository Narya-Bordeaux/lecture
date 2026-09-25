import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

import '../support/stage_builders.dart' as build;
import '../support/stage_introduction_driver.dart';
import '../support/word_drag.dart';

/// Etape sans illustration : les tests portent sur le comportement, pas sur le
/// decor, et une image absente du bundle de test ferait echouer le rendu.
Stage buildTestStage({String? statement}) {
  return build.stage(
    id: 'maison',
    location: 'Devant la maison',
    arrivalText: statement,
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('arrêt'), build.word('ticket')],
        destination: 'gare',
        area: const RelativeArea(
          left: 0.04,
          top: 0.35,
          width: 0.4,
          height: 0.2,
        ),
      ),
      build.family(
        id: 'a_pied',
        label: 'À pied',
        words: <Word>[build.word('chaussure'), build.word('sentier')],
        destination: 'rue',
        area: const RelativeArea(
          left: 0.55,
          top: 0.35,
          width: 0.4,
          height: 0.2,
        ),
      ),
    ],
  );
}

/// Monte la page dans un ecran de taille fixe, en portrait.
Future<List<String>> pumpStagePage(
  WidgetTester tester, {
  String? statement,
}) async {
  final departures = <String>[];

  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(
        stage: buildTestStage(statement: statement),
        onDeparture: departures.add,
        random: Random(7),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await completeStageIntroduction(tester);

  return departures;
}


void main() {
  testWidgets('une zone compte les mots tires, pas toute la liste', (
    tester,
  ) async {
    // Une liste plus longue que la partie : le moteur tire [drawCount] mots
    // et ouvre le chemin au dernier. La zone doit annoncer ce nombre-la —
    // « 0 / 4 » promettrait deux mots que l'enfant ne verra jamais.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stage = buildTestStage();
    await tester.pumpWidget(
      MaterialApp(
        home: StagePage(
          stage: stage.copyWith(
            drawCount: 1,
          ),
          onDeparture: (_) {},
          random: Random(7),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await completeStageIntroduction(tester);

    expect(find.text(UiStringsFr.familyProgress(0, 1)), findsNWidgets(2));
    expect(find.text(UiStringsFr.familyProgress(0, 2)), findsNothing);
  });

  group('L\'enonce', () {
    // Le texte d'arrivee d'un lieu de jeu est ce qui donne son sens au tri :
    // il pose la question que les mots tranchent. Il se lit donc pendant
    // qu'on trie, pas sur un ecran qu'on a deja quitte.
    const statement = 'Y ira-t-elle à pied ou en bus ?';

    testWidgets('il s\'affiche dans le bandeau, au-dessus des mots', (
      tester,
    ) async {
      await pumpStagePage(tester, statement: statement);

      final shown = find.descendant(
        of: find.byKey(StagePage.wordTrayKey),
        matching: find.text(statement),
      );
      expect(shown, findsOneWidget);
      expect(
        tester.getBottomLeft(shown).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('arrêt')).dy),
      );
    });

    testWidgets('il reste quand tous les mots sont classes', (tester) async {
      await pumpStagePage(tester, statement: statement);

      for (final (word, family) in <(String, String)>[
        ('arrêt', 'en_bus'),
        ('ticket', 'en_bus'),
        ('chaussure', 'a_pied'),
        ('sentier', 'a_pied'),
      ]) {
        await dragWordOnto(tester, word: word, familyId: family);
      }

      expect(find.text(statement), findsOneWidget);
    });

    testWidgets('aucune consigne generique ne s\'affiche', (tester) async {
      // Retiree par l'auteur : l'enonce dit deja ce qu'il faut faire, et une
      // phrase qui ne change jamais finit par ne plus etre lue.
      await pumpStagePage(tester, statement: statement);

      expect(find.text('Pose les mots au bon endroit'), findsNothing);
    });

    testWidgets('la scene commence sous le bandeau, jamais dessous', (
      tester,
    ) async {
      // Option A, choisie par l'auteur : l'illustration occupe ce que le
      // bandeau laisse. Une zone posee tout en haut de l'image ne peut donc
      // plus passer sous l'enonce, quelle que soit sa longueur.
      final longStatement = List<String>.filled(6, statement).join(' ');
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final stage = buildTestStage(statement: longStatement);
      await tester.pumpWidget(
        MaterialApp(
          home: StagePage(
            stage: stage.copyWith(
              families: <WordFamily>[
                stage.families.first.copyWith(
                  area: const RelativeArea(
                    left: 0,
                    top: 0,
                    width: 0.4,
                    height: 0.2,
                  ),
                ),
                stage.families.last,
              ],
            ),
            onDeparture: (_) {},
            random: Random(7),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await completeStageIntroduction(tester);

      final tray = tester.getRect(find.byKey(StagePage.wordTrayKey));
      final zone = tester.getRect(
        find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
      );
      expect(zone.top, greaterThanOrEqualTo(tray.bottom));
    });

    testWidgets('sans enonce, le bandeau ne porte que les mots', (
      tester,
    ) async {
      await pumpStagePage(tester);

      expect(
        find.descendant(
          of: find.byKey(StagePage.wordTrayKey),
          matching: find.byType(Text),
        ),
        findsNWidgets(4),
      );
    });
  });

  testWidgets('les mots a classer sont tous proposes', (tester) async {
    await pumpStagePage(tester);

    for (final word in <String>['arrêt', 'ticket', 'chaussure', 'sentier']) {
      expect(find.text(word), findsOneWidget, reason: 'mot manquant : $word');
    }
  });

  testWidgets('les zones affichent leur nom et leur avancement', (
    tester,
  ) async {
    await pumpStagePage(tester);

    expect(find.text('En bus'), findsOneWidget);
    expect(find.text('À pied'), findsOneWidget);
    expect(find.text(UiStringsFr.familyProgress(0, 2)), findsNWidgets(2));
  });

  testWidgets('un mot bien place quitte la grille et rejoint sa zone', (
    tester,
  ) async {
    await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');

    // Le mot reste affiche, mais range dans la zone : une seule occurrence.
    expect(find.text('arrêt'), findsOneWidget);
    expect(find.text(UiStringsFr.familyProgress(1, 2)), findsOneWidget);
  });

  testWidgets('un mot mal place n\'est pas accepte par la zone', (
    tester,
  ) async {
    await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'a_pied');

    // Aucune zone n'a progresse : le mot est revenu dans la grille.
    expect(find.text(UiStringsFr.familyProgress(0, 2)), findsNWidgets(2));
    expect(find.text('arrêt'), findsOneWidget);
  });

  testWidgets('une erreur ne fait rien apparaitre sous le mot', (tester) async {
    // L'aide par le decoupage a ete retiree (0.33.0) : l'etiquette tremble et
    // revient, et l'enfant reessaie. Rien d'autre ne s'affiche.
    await pumpStagePage(tester);
    final before = find.byType(Text).evaluate().length;

    await dragWordOnto(tester, word: 'arrêt', familyId: 'a_pied');

    expect(find.byType(Text).evaluate().length, before);
    expect(find.textContaining(' - '), findsNothing);
  });

  testWidgets('aucun depart n\'est propose tant qu\'une famille est ouverte', (
    tester,
  ) async {
    await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');

    expect(find.text(UiStringsFr.destinationOpened), findsNothing);
  });

  testWidgets('completer une famille propose un depart sans l\'imposer', (
    tester,
  ) async {
    final departures = await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'ticket', familyId: 'en_bus');

    expect(find.text(UiStringsFr.destinationOpened), findsOneWidget);
    expect(find.text(UiStringsFr.departTo('en bus')), findsOneWidget);
    // L'enfant n'est pas parti : il garde la main.
    expect(departures, isEmpty);
  });

  testWidgets('le bouton de depart annonce l\'etape choisie', (tester) async {
    final departures = await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'ticket', familyId: 'en_bus');
    await tester.tap(find.text(UiStringsFr.departTo('en bus')));
    await tester.pumpAndSettle();

    expect(departures, <String>['gare']);
  });

  testWidgets('deux familles completes proposent deux departs', (tester) async {
    await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'ticket', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'chaussure', familyId: 'a_pied');
    await dragWordOnto(tester, word: 'sentier', familyId: 'a_pied');

    expect(find.text(UiStringsFr.departTo('en bus')), findsOneWidget);
    expect(find.text(UiStringsFr.departTo('à pied')), findsOneWidget);
  });
}
