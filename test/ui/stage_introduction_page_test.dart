import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/stage_introduction.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/widgets/family_intro_card.dart';
import 'package:grisbie/ui/widgets/scene_layout.dart';
import 'package:grisbie/ui/widgets/statement_popup.dart';

import '../support/stage_builders.dart' as build;

/// La mise en place d'un lieu, vue par l'enfant : le decor seul, l'enonce au
/// centre, puis le cartouche et chaque boite qui va se ranger a sa place.

const String _statement = 'Y ira-t-elle en bus ou à pied ?';

Stage _stage({String? statement = _statement}) {
  return build.stage(
    id: 'maison',
    arrivalText: statement,
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('arrêt'), build.word('ticket')],
        destination: 'gare',
        area: const RelativeArea(left: 0.04, top: 0.35, width: 0.4, height: 0.2),
      ),
      build.family(
        id: 'a_pied',
        label: 'À pied',
        words: <Word>[build.word('chaussure'), build.word('sentier')],
        destination: 'rue',
        area: const RelativeArea(left: 0.55, top: 0.35, width: 0.4, height: 0.2),
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  Stage? stage,
  bool interactive = true,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(
        stage: stage ?? _stage(),
        onDeparture: (_) {},
        random: Random(7),
        interactive: interactive,
      ),
    ),
  );
  await tester.pump();
}

/// Le cartouche est-il visible ? Il occupe sa place des le debut : seule son
/// opacite dit s'il se montre.
bool _trayIsVisible(WidgetTester tester) {
  final opacity = tester.widget<AnimatedOpacity>(
    find.ancestor(
      of: find.byKey(StagePage.wordTrayKey),
      matching: find.byType(AnimatedOpacity),
    ),
  );
  return opacity.opacity == 1;
}

/// Les mots se deplacent-ils ? Le cartouche est rendu inerte tant que la
/// mise en place n'est pas finie.
bool _wordsCanMove(WidgetTester tester) {
  final guard = tester.widget<IgnorePointer>(
    find
        .ancestor(
          of: find.byKey(StagePage.wordTrayKey),
          matching: find.byType(IgnorePointer),
        )
        .first,
  );
  return !guard.ignoring;
}

Future<void> _pastBackground(WidgetTester tester) async {
  await tester.pump(StageIntroduction.backgroundOnlyDuration);
  await tester.pumpAndSettle();
}

Future<void> _closeStatement(WidgetTester tester) async {
  await tester.tap(find.byKey(StatementPopup.closeKey));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('d\'abord le decor seul', (tester) async {
    await _pump(tester);

    expect(_trayIsVisible(tester), isFalse);
    expect(find.byType(StatementPopup), findsNothing);
    expect(find.byType(FamilyDropZone), findsNothing);
  });

  testWidgets('un quart de seconde plus tard, l\'enonce au centre', (
    tester,
  ) async {
    await _pump(tester);
    await _pastBackground(tester);

    expect(find.byType(StatementPopup), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatementPopup),
        matching: find.text(_statement),
      ),
      findsOneWidget,
    );
    expect(_trayIsVisible(tester), isFalse);
    expect(find.byType(FamilyDropZone), findsNothing);
  });

  testWidgets('l\'enonce ne se ferme que par sa fleche', (tester) async {
    await _pump(tester);
    await _pastBackground(tester);

    // Un toucher a cote, dans un coin du decor.
    await tester.tapAt(const Offset(20, 600));
    await tester.pumpAndSettle();
    expect(find.byType(StatementPopup), findsOneWidget);

    await _closeStatement(tester);
    expect(find.byType(StatementPopup), findsNothing);
  });

  testWidgets('la fleche fermee, le cartouche parait et la premiere boite '
      'se presente, les mots immobiles', (tester) async {
    await _pump(tester);
    await _pastBackground(tester);
    await _closeStatement(tester);

    expect(_trayIsVisible(tester), isTrue);
    expect(find.text('arrêt'), findsOneWidget);
    expect(_wordsCanMove(tester), isFalse);
    expect(find.byKey(FamilyIntroCard.keyFor('en_bus')), findsOneWidget);
    // Aucune zone n'est encore sur le decor : la seule est celle de la
    // carte, qui est la boite elle-meme, agrandie.
    expect(find.byType(FamilyDropZone), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FamilyIntroCard),
        matching: find.byType(FamilyDropZone),
      ),
      findsOneWidget,
    );
  });

  testWidgets('la boite presentee est au centre de la scene, agrandie', (
    tester,
  ) async {
    await _pump(tester);
    await _pastBackground(tester);
    await _closeStatement(tester);

    final card = tester.getRect(find.byKey(FamilyIntroCard.keyFor('en_bus')));
    final scene = tester.getRect(find.byType(FamilyIntroCard));

    expect(card.center.dx, closeTo(scene.center.dx, 1));
    expect(card.center.dy, closeTo(scene.center.dy, 1));
    // La zone reelle fait 40 % de la largeur de l'image : la carte est plus
    // grande qu'elle.
    expect(card.width, greaterThan(scene.width * 0.4));
  });

  testWidgets('touchee, la boite va se ranger a sa place exacte', (
    tester,
  ) async {
    await _pump(tester);
    await _pastBackground(tester);
    await _closeStatement(tester);

    await tester.tap(find.byType(FamilyIntroCard));
    // Le premier rendu ne fait que lancer l'envol.
    await tester.pump();
    // A mi-vol, elle a quitte le centre sans etre arrivee.
    await tester.pump(const Duration(milliseconds: 300));
    final midFlight = tester.getRect(
      find.byKey(FamilyIntroCard.keyFor('en_bus')),
    );
    await tester.pumpAndSettle();

    final zone = tester.getRect(
      find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
    );
    final centre = tester.getRect(find.byType(FamilyIntroCard)).center;
    expect(midFlight, isNot(equals(zone)));
    expect(midFlight.center, isNot(equals(centre)));
    expect(find.byKey(FamilyIntroCard.keyFor('en_bus')), findsNothing);
    // La suivante se presente aussitot.
    expect(find.byKey(FamilyIntroCard.keyFor('a_pied')), findsOneWidget);
    expect(_wordsCanMove(tester), isFalse);
  });

  testWidgets('la carte arrive exactement ou la zone l\'attend', (
    tester,
  ) async {
    // Aucun saut quand la carte cede la place a la zone : c'est ce qui fait
    // voir a l'enfant d'ou vient ce qu'il trouve sur le decor.
    await _pump(tester);
    await _pastBackground(tester);
    await _closeStatement(tester);

    await tester.tap(find.byType(FamilyIntroCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 649));
    final landing = tester.getRect(
      find.byKey(FamilyIntroCard.keyFor('en_bus')),
    );
    await tester.pumpAndSettle();
    final zone = tester.getRect(
      find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
    );

    expect(landing.left, closeTo(zone.left, 1));
    expect(landing.top, closeTo(zone.top, 1));
    expect(landing.width, closeTo(zone.width, 1));
    expect(landing.height, closeTo(zone.height, 1));
  });

  testWidgets('la derniere boite rangee, les mots se deplacent', (
    tester,
  ) async {
    await _pump(tester);
    await _pastBackground(tester);
    await _closeStatement(tester);

    await tester.tap(find.byType(FamilyIntroCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FamilyIntroCard));
    await tester.pumpAndSettle();

    expect(find.byType(FamilyIntroCard), findsNothing);
    expect(find.byKey(FamilyDropZone.frameKeyFor('en_bus')), findsOneWidget);
    expect(find.byKey(FamilyDropZone.frameKeyFor('a_pied')), findsOneWidget);
    expect(_wordsCanMove(tester), isTrue);
  });

  testWidgets('le decor ne bouge pas quand le cartouche parait', (
    tester,
  ) async {
    // Option A : la place du cartouche est reservee des le debut. Sans cela,
    // l'illustration rapetisserait sous les yeux de l'enfant.
    await _pump(tester);
    final trayBefore = tester.getRect(find.byKey(StagePage.wordTrayKey));
    final sceneBefore = tester.getRect(find.byType(SceneLayout));

    await _pastBackground(tester);
    await _closeStatement(tester);

    expect(tester.getRect(find.byKey(StagePage.wordTrayKey)), trayBefore);
    expect(tester.getRect(find.byType(SceneLayout)), sceneBefore);
  });

  testWidgets('sans enonce, le decor mene droit a la premiere boite', (
    tester,
  ) async {
    await _pump(tester, stage: _stage(statement: null));
    await _pastBackground(tester);

    expect(find.byType(StatementPopup), findsNothing);
    expect(_trayIsVisible(tester), isTrue);
    expect(find.byKey(FamilyIntroCard.keyFor('en_bus')), findsOneWidget);
  });

  testWidgets('l\'apercu du calage montre la scene deja en place', (
    tester,
  ) async {
    await _pump(tester, interactive: false);

    expect(find.byType(StatementPopup), findsNothing);
    expect(find.byType(FamilyIntroCard), findsNothing);
    expect(_trayIsVisible(tester), isTrue);
    expect(find.byKey(FamilyDropZone.frameKeyFor('en_bus')), findsOneWidget);
  });
}
