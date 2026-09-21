import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/domain/models/relative_area.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';
import 'package:reading_game/ui/pages/stage_page.dart';
import 'package:reading_game/ui/widgets/family_drop_zone.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

import '../support/stage_builders.dart' as build;

/// Etape sans illustration : les tests portent sur le comportement, pas sur le
/// decor, et une image absente du bundle de test ferait echouer le rendu.
Stage buildTestStage() {
  return build.stage(
    id: 'maison',
    location: 'Devant la maison',
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[
          build.word('arrêt', <String>['ar', 'rêt']),
          build.word('ticket', <String>['tic', 'ket']),
        ],
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
        words: <Word>[
          build.word('chaussure', <String>['chaus', 'sure']),
          build.word('sentier', <String>['sen', 'tier']),
        ],
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
Future<List<String>> pumpStagePage(WidgetTester tester) async {
  final departures = <String>[];

  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(
        stage: buildTestStage(),
        onDeparture: departures.add,
        random: Random(7),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return departures;
}

/// Fait glisser l'etiquette [word] jusqu'au centre du cadre [familyId].
///
/// On vise le cadre et non l'intitule : celui-ci est pose au-dessus de la zone,
/// et n'est donc plus un point de depot valide.
Future<void> dragWordOnto(
  WidgetTester tester, {
  required String word,
  required String familyId,
}) async {
  final wordFinder = find.text(word).first;
  final zoneFinder = find.byKey(FamilyDropZone.frameKeyFor(familyId));

  final gesture = await tester.startGesture(tester.getCenter(wordFinder));
  // Un premier deplacement declenche la prise en main, avant de viser.
  await gesture.moveBy(const Offset(0, 40));
  await tester.pump();
  await gesture.moveTo(tester.getCenter(zoneFinder));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('une erreur fait apparaitre le decoupage en syllabes', (
    tester,
  ) async {
    await pumpStagePage(tester);

    expect(find.text('ar - rêt'), findsNothing);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'a_pied');

    expect(find.text('ar - rêt'), findsOneWidget);
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

  testWidgets('deux familles completes proposent deux departs', (
    tester,
  ) async {
    await pumpStagePage(tester);

    await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'ticket', familyId: 'en_bus');
    await dragWordOnto(tester, word: 'chaussure', familyId: 'a_pied');
    await dragWordOnto(tester, word: 'sentier', familyId: 'a_pied');

    expect(find.text(UiStringsFr.departTo('en bus')), findsOneWidget);
    expect(find.text(UiStringsFr.departTo('à pied')), findsOneWidget);
  });
}
