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

Stage _house({String? busText, String? departure, bool withTexts = true}) {
  final bus = build.family(
    id: 'en_bus',
    label: 'En bus',
    words: <Word>[build.word('arrêt'), build.word('ticket')],
    destination: 'gare',
    area: _left,
    departureLabel: departure,
    withTexts: withTexts,
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
    // Le texte de l'auteur, tel quel : rien n'est compose.
    expect(find.text('Tu as trouvé tous les mots « En bus ».'), findsOneWidget);
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

  testWidgets('sans texte — lieu inacheve que l\'outil essaie — « Bravo ! » '
      'seul', (tester) async {
    await _pump(tester, _house(withTexts: false));
    await _completeBus(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Bravo !'), findsOneWidget);
    expect(find.textContaining('Tu as'), findsNothing);
  });

  testWidgets('le bouton de depart porte l\'action ecrite', (tester) async {
    await _pump(tester, _house(departure: 'Prendre le bus'));
    await _completeBus(tester);
    await dismissCompletion(tester);

    expect(find.text('Prendre le bus'), findsOneWidget);
  });

  testWidgets('« autre chose » remplie ne dit rien', (tester) async {
    await _pump(tester, _shop());

    await dragWordOnto(tester, word: 'clou', familyId: 'autre_chose');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(CompletionPopup), findsNothing);
  });
}
