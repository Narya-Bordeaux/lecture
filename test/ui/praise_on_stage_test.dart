import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/widgets/praise_pop.dart';

import '../support/stage_builders.dart' as build;
import '../support/stage_introduction_driver.dart';
import '../support/word_drag.dart';

/// La tete de Grisbie sur la scene, apres un mot bien place.

const RelativeArea _left = RelativeArea(
  left: 0.04,
  top: 0.4,
  width: 0.4,
  height: 0.2,
);
const RelativeArea _right = RelativeArea(
  left: 0.55,
  top: 0.4,
  width: 0.4,
  height: 0.2,
);

/// Deux boites qui ouvrent chacune un chemin.
Stage _house() => build.stage(
      id: 'maison',
      families: <WordFamily>[
        build.family(
          id: 'en_bus',
          label: 'En bus',
          words: <Word>[build.word('arrêt'), build.word('ticket')],
          destination: 'gare',
          area: _left,
        ),
        build.family(
          id: 'a_pied',
          label: 'À pied',
          words: <Word>[build.word('chaussure'), build.word('sentier')],
          destination: 'rue',
          area: _right,
        ),
      ],
    );

/// Un tri unique : la boite « autre chose » n'ouvre rien, et n'a pas de
/// « Bravo ! ».
Stage _shop() => build.stage(
      id: 'boutique',
      families: <WordFamily>[
        build.family(
          id: 'a_manger',
          label: 'Ce qui se mange',
          words: <Word>[build.word('pomme'), build.word('pain')],
          destination: 'plage',
          area: _left,
        ),
        build.family(
          id: 'autre_chose',
          label: 'Autre chose',
          words: <Word>[build.word('clou')],
          area: _right,
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, Stage stage) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(stage: stage, onDeparture: (_) {}, random: Random(7)),
    ),
  );
  await tester.pumpAndSettle();
  await completeStageIntroduction(tester);
}

/// Pose [word] dans [familyId] sans attendre la fin des animations.
Future<void> _drop(WidgetTester tester, String word, String familyId) async {
  await dragWordTo(
    tester,
    word: word,
    target: tester.getCenter(find.byKey(FamilyDropZone.frameKeyFor(familyId))),
    settle: false,
  );
  await tester.pump(const Duration(milliseconds: 150));
}

void main() {
  testWidgets('un mot bien place fait sortir la tete, qui repart', (
    tester,
  ) async {
    await _pump(tester, _house());

    await _drop(tester, 'arrêt', 'en_bus');
    expect(find.byType(PraisePop), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(PraisePop), findsNothing);
  });

  testWidgets('elle sort au bord de la boite qui a recu le mot', (
    tester,
  ) async {
    await _pump(tester, _house());
    final frame = tester.getRect(
      find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
    );

    await _drop(tester, 'arrêt', 'en_bus');
    final head = tester.getCenter(find.byType(Image).last);

    // La boite est a gauche : la tete tient son coin haut droit.
    expect(head.dx, closeTo(frame.right, 30));
    expect(head.dy, closeTo(frame.top, 60));
  });

  testWidgets('un mot refuse ne fait rien sortir', (tester) async {
    await _pump(tester, _house());

    await _drop(tester, 'arrêt', 'a_pied');

    expect(find.byType(PraisePop), findsNothing);
  });

  testWidgets('une boite pleine a son « Bravo ! » : pas de tete', (
    tester,
  ) async {
    await _pump(tester, _house());
    await _drop(tester, 'arrêt', 'en_bus');
    await tester.pumpAndSettle();

    await _drop(tester, 'ticket', 'en_bus');

    expect(find.byType(PraisePop), findsNothing);
  });

  testWidgets('« autre chose » remplie n\'a pas de « Bravo ! » : la tete '
      'sort', (tester) async {
    await _pump(tester, _shop());

    await _drop(tester, 'clou', 'autre_chose');

    expect(find.byType(PraisePop), findsOneWidget);
  });
}
