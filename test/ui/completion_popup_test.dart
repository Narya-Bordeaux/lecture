import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/completion_popup.dart';

import '../support/stage_builders.dart' as build;
import '../support/stage_introduction_driver.dart';
import '../support/word_drag.dart';

/// Le « Bravo ! » d'une boite complete, vu par l'enfant.

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

Stage _house({String? busText}) {
  final bus = build.family(
    id: 'en_bus',
    label: 'En bus',
    words: <Word>[build.word('arrêt'), build.word('ticket')],
    destination: 'gare',
    area: _left,
  );
  return build.stage(
    id: 'maison',
    families: <WordFamily>[
      busText == null ? bus : bus.copyWith(completionText: busText),
      build.family(
        id: 'a_pied',
        label: 'À pied',
        words: <Word>[build.word('chaussure'), build.word('sentier')],
        destination: 'rue',
        area: _right,
      ),
    ],
  );
}

Stage _shop() {
  return build.stage(
    id: 'boutique',
    families: <WordFamily>[
      build.family(
        id: 'a_manger',
        label: 'Ce qui se mange',
        words: <Word>[build.word('pomme')],
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
}

Future<void> _pump(WidgetTester tester, Stage stage) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(
        stage: stage,
        onDeparture: (_) {},
        random: Random(7),
        destinationNames: const <String, String>{
          'gare': 'La gare',
          'rue': 'La rue',
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  await completeStageIntroduction(tester);
}

Future<void> _completeBus(WidgetTester tester) async {
  await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');
  await dragWordOnto(tester, word: 'ticket', familyId: 'en_bus');
}

void main() {
  testWidgets('la boite remplie, « Bravo ! » parait apres une courte pause',
      (tester) async {
    await _pump(tester, _house());
    await _completeBus(tester);

    // D'abord la boite qui passe au vert, sans rien par-dessus.
    expect(find.byType(CompletionPopup), findsNothing);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Bravo !'), findsOneWidget);
    expect(
      find.text('Tu as rangé tous les mots «\u00A0En bus\u00A0». Tu peux partir vers '
          'la gare, ou ouvrir un autre chemin.'),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                CompletionPopup.badgeAsset,
      ),
      findsOneWidget,
    );
  });

  testWidgets('un toucher n\'importe ou le ferme, le chemin attend dessous', (
    tester,
  ) async {
    await _pump(tester, _house());
    await _completeBus(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(20, 600));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionPopup), findsNothing);
    expect(find.text(UiStringsFr.departTo('en bus')), findsOneWidget);
  });

  testWidgets('le texte de l\'auteur remplace le texte propose', (
    tester,
  ) async {
    await _pump(tester, _house(busText: 'Le bus arrive au coin de la rue !'));
    await _completeBus(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Bravo !'), findsOneWidget);
    expect(find.text('Le bus arrive au coin de la rue !'), findsOneWidget);
  });

  testWidgets('la derniere boite ne propose plus d\'autre chemin', (
    tester,
  ) async {
    await _pump(tester, _house());
    await _completeBus(tester);
    await dismissCompletion(tester);

    await dragWordOnto(tester, word: 'chaussure', familyId: 'a_pied');
    await dragWordOnto(tester, word: 'sentier', familyId: 'a_pied');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      find.text('Tu as rangé tous les mots «\u00A0À pied\u00A0». Tu peux partir vers '
          'la rue.'),
      findsOneWidget,
    );
  });

  testWidgets('« autre chose » remplie ne dit rien', (tester) async {
    await _pump(tester, _shop());

    await dragWordOnto(tester, word: 'clou', familyId: 'autre_chose');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionPopup), findsNothing);
  });
}
