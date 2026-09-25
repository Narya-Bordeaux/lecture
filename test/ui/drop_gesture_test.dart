import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/widgets/blink.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/widgets/family_intro_card.dart';
import 'package:grisbie/ui/widgets/shine.dart';
import 'package:grisbie/ui/widgets/statement_popup.dart';
import 'package:grisbie/application/stage_introduction.dart';

import '../support/stage_builders.dart' as build;
import '../support/stage_introduction_driver.dart';
import '../support/word_drag.dart';

/// Le geste de l'enfant : ou compte le mot, ce qui s'allume, et ce qui se
/// passe quand il lache a cote.

Stage _stage() {
  return build.stage(
    id: 'maison',
    arrivalText: 'Y ira-t-elle en bus ou à pied ?',
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('arrêt'), build.word('ticket')],
        destination: 'gare',
        area: const RelativeArea(left: 0.04, top: 0.4, width: 0.4, height: 0.2),
      ),
      build.family(
        id: 'a_pied',
        label: 'À pied',
        words: <Word>[build.word('chaussure'), build.word('sentier')],
        destination: 'rue',
        area: const RelativeArea(left: 0.55, top: 0.4, width: 0.4, height: 0.2),
      ),
    ],
  );
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: StagePage(stage: _stage(), onDeparture: (_) {}, random: Random(7)),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _zone(WidgetTester tester, String familyId) {
  return tester.getRect(find.byKey(FamilyDropZone.frameKeyFor(familyId)));
}

/// Vrai si le mot est range dans la zone.
bool _isPlacedIn(WidgetTester tester, String word, String familyId) {
  return find
      .descendant(
        of: find.byKey(FamilyDropZone.frameKeyFor(familyId)),
        matching: find.text(word),
      )
      .evaluate()
      .isNotEmpty;
}

void main() {
  group('Le mot compte la ou on le voit', () {
    testWidgets('le mot dans la boite, le doigt deja sorti dessous : il est '
        'range', (tester) async {
      // Le cas qui trompait l'enfant : il voyait son mot dans la boite, pres
      // du bord bas, et le mot repartait.
      await _pump(tester);
      await completeStageIntroduction(tester);
      final zone = _zone(tester, 'en_bus');

      final label = tester.getSize(wordLabelFinder('arrêt'));
      final seenAt = Offset(zone.center.dx, zone.bottom - 4);
      final fingerAt = seenAt + Offset(0, label.height / 2 + 12);
      expect(zone.contains(fingerAt), isFalse);

      await dragWordTo(tester, word: 'arrêt', target: seenAt);

      expect(_isPlacedIn(tester, 'arrêt', 'en_bus'), isTrue);
    });

    testWidgets('le doigt dans la boite, le mot au-dessus : rien n\'est '
        'range', (tester) async {
      await _pump(tester);
      await completeStageIntroduction(tester);
      final zone = _zone(tester, 'en_bus');

      final label = tester.getSize(wordLabelFinder('arrêt'));
      final seenAt = Offset(zone.center.dx, zone.top - 4);
      final fingerAt = seenAt + Offset(0, label.height / 2 + 12);
      expect(zone.contains(fingerAt), isTrue);

      await dragWordTo(tester, word: 'arrêt', target: seenAt);

      expect(_isPlacedIn(tester, 'arrêt', 'en_bus'), isFalse);
    });
  });

  testWidgets('survolee, la boite devient presque blanche', (tester) async {
    await _pump(tester);
    await completeStageIntroduction(tester);
    final zone = _zone(tester, 'en_bus');
    final label = wordLabelFinder('arrêt');
    final seenPoint = Offset(0, tester.getSize(label).height / 2 + 12);

    final gesture = await tester.startGesture(tester.getCenter(label));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveTo(zone.center + seenPoint);
    await tester.pumpAndSettle();

    final frame = tester.widget<AnimatedContainer>(
      find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
    );
    final colour = (frame.decoration! as BoxDecoration).color!;
    expect(colour.a, closeTo(FamilyDropZone.hoveredOpacity, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  group('Lache hors des boites', () {
    testWidgets('le mot revient en glissant a sa case', (tester) async {
      await _pump(tester);
      await completeStageIntroduction(tester);
      final slot = tester.getRect(wordLabelFinder('arrêt'));

      // Tout en bas du decor, loin des deux boites.
      await dragWordTo(
        tester,
        word: 'arrêt',
        target: const Offset(180, 600),
        settle: false,
      );
      // En chemin : le mot est visible hors de sa case, qui reste vide.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('arrêt'), findsNWidgets(2));
      final travelling = tester.getRect(find.text('arrêt').last);
      expect(slot.contains(travelling.center), isFalse);

      await tester.pumpAndSettle();
      expect(find.text('arrêt'), findsOneWidget);
      expect(tester.getRect(wordLabelFinder('arrêt')), slot);
    });

    testWidgets('les boites clignotent pour dire ou viser', (tester) async {
      await _pump(tester);
      await completeStageIntroduction(tester);

      await dragWordTo(
        tester,
        word: 'arrêt',
        target: const Offset(180, 600),
        settle: false,
      );
      await tester.pump();

      final blinks = tester.stateList<BlinkState>(find.byType(Blink));
      expect(blinks, hasLength(2));
      expect(blinks.every((blink) => blink.isBlinking), isTrue);

      await tester.pumpAndSettle();
      expect(blinks.any((blink) => blink.isBlinking), isFalse);
    });

    testWidgets('un mot refuse ne fait pas clignoter les boites', (
      tester,
    ) async {
      // Deux messages differents : refuse, il tremble ; lache a cote, les
      // boites s'allument. Les meler rendrait les deux illisibles.
      await _pump(tester);
      await completeStageIntroduction(tester);

      await dragWordOnto(tester, word: 'arrêt', familyId: 'a_pied');

      final blinks = tester.stateList<BlinkState>(find.byType(Blink));
      expect(blinks.any((blink) => blink.isBlinking), isFalse);
      expect(_isPlacedIn(tester, 'arrêt', 'a_pied'), isFalse);
    });
  });

  group('Le reflet qui ouvre le jeu', () {
    Future<void> untilLastBox(WidgetTester tester) async {
      await tester.pump(StageIntroduction.backgroundOnlyDuration);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(StatementPopup.closeKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FamilyIntroCard));
      await tester.pumpAndSettle();
    }

    testWidgets('parcourt les mots quand la derniere boite est rangee', (
      tester,
    ) async {
      await _pump(tester);
      await untilLastBox(tester);

      List<ShineState> shines() =>
          tester.stateList<ShineState>(find.byType(Shine)).toList();
      expect(shines().any((shine) => shine.isShining), isFalse);

      await tester.tap(find.byType(FamilyIntroCard));
      await tester.pump();
      // L'envol de la derniere boite, puis le rendu qui la range.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(shines(), hasLength(4));
      expect(shines().every((shine) => shine.isShining), isTrue);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(shines().any((shine) => shine.isShining), isFalse);
    });

    testWidgets('ne revient pas quand un mot en remplace un autre', (
      tester,
    ) async {
      await _pump(tester);
      await completeStageIntroduction(tester);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await dragWordOnto(tester, word: 'arrêt', familyId: 'en_bus');

      final shines = tester.stateList<ShineState>(find.byType(Shine));
      expect(shines.any((shine) => shine.isShining), isFalse);
    });
  });
}
