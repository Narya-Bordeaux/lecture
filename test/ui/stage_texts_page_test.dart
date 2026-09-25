import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_texts_page.dart';

import '../support/stage_builders.dart' as build;

/// Les textes d'un lieu, chacun ecrit la ou l'enfant le lira : l'arrivee,
/// les boites sur l'illustration, puis le « Bravo ! » et le bouton de chaque
/// trajet. Rien n'est pre-ecrit.

Stage _house({bool withTexts = false}) {
  return build.stage(
    id: 'maison',
    location: 'Devant la maison',
    arrivalText: 'Y ira-t-elle en bus ou en voiture ?',
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('ticket')],
        destination: 'gare',
        area: const RelativeArea(left: 0.05, top: 0.5, width: 0.4, height: 0.3),
        withTexts: withTexts,
      ),
      build.family(
        id: 'en_voiture',
        label: 'En voiture',
        words: <Word>[build.word('volant')],
        destination: 'garage',
        withTexts: withTexts,
      ),
    ],
  );
}

Stage _garage() {
  return build.stage(
    id: 'garage',
    location: 'Le garage',
    families: <WordFamily>[
      build.family(
        id: 'musique',
        label: 'Les types de musique',
        words: <Word>[build.word('rock')],
        destination: 'plage',
      ),
      build.family(
        id: 'autre_chose',
        label: 'Autre chose',
        words: <Word>[build.word('clou')],
      ),
    ],
  );
}

/// Monte l'ecran ; [onClosed] recoit ce qu'il rend.
Future<void> _pump(
  WidgetTester tester,
  Stage stage, {
  void Function(Stage? kept)? onClosed,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final kept = await Navigator.of(context).push<Stage>(
              MaterialPageRoute<Stage>(
                builder: (_) => StageTextsPage(stage: stage),
              ),
            );
            onClosed?.call(kept);
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

Future<void> _keep(WidgetTester tester) async {
  await tester.tap(find.text('Garder'));
  await tester.pumpAndSettle();
}

void main() {
  group('Les diapositives, dans l\'ordre ou l\'enfant les vit', () {
    testWidgets('l\'arrivee, les boites, puis un « Bravo ! » par trajet', (
      tester,
    ) async {
      await _pump(tester, _house());

      expect(find.text('1 · En arrivant'), findsOneWidget);
      expect(find.text('2 · Les boîtes'), findsOneWidget);
      expect(find.text('3 · Quand « En bus » est pleine'), findsOneWidget);
      expect(find.text('4 · Quand « En voiture » est pleine'), findsOneWidget);
      expect(find.text('Bravo !'), findsNWidgets(2));
    });

    testWidgets('rien n\'est pre-ecrit', (tester) async {
      await _pump(tester, _house());

      expect(_text(tester, StageTextsPage.completionKeyFor('en_bus')), '');
      expect(_text(tester, StageTextsPage.departureKeyFor('en_bus')), '');
    });

    testWidgets('les textes deja ecrits se rouvrent a leur place', (
      tester,
    ) async {
      await _pump(tester, _house(withTexts: true));

      expect(
        _text(tester, StageTextsPage.onArrivalKey),
        'Y ira-t-elle en bus ou en voiture ?',
      );
      expect(_text(tester, StageTextsPage.labelKeyFor('en_bus')), 'En bus');
      expect(
        _text(tester, StageTextsPage.departureKeyFor('en_bus')),
        'Partir en bus',
      );
    });

    testWidgets('une boite sans place sur l\'image a son champ dessous', (
      tester,
    ) async {
      await _pump(tester, _house());

      expect(find.textContaining('Sans place sur l\'image'), findsOneWidget);
      expect(
        find.byKey(StageTextsPage.labelKeyFor('en_voiture')),
        findsOneWidget,
      );
    });

    testWidgets('renommer une boite renomme sa diapositive', (tester) async {
      await _pump(tester, _house());

      await tester.enterText(
        find.byKey(StageTextsPage.labelKeyFor('en_voiture')),
        'La voiture',
      );
      await tester.pump();

      expect(find.text('4 · Quand « La voiture » est pleine'), findsOneWidget);
    });
  });

  group('Ce que l\'ecran rend', () {
    testWidgets('chaque texte revient sur son trajet', (tester) async {
      Stage? kept;
      await _pump(tester, _house(), onClosed: (stage) => kept = stage);

      await tester.enterText(
        find.byKey(StageTextsPage.completionKeyFor('en_voiture')),
        'Tu as trouvé tous les mots « en voiture ». Tu peux prendre la '
        'voiture.',
      );
      await tester.enterText(
        find.byKey(StageTextsPage.departureKeyFor('en_voiture')),
        'Prendre la voiture',
      );
      await tester.enterText(
        find.byKey(StageTextsPage.labelKeyFor('en_voiture')),
        'La voiture',
      );
      await tester.enterText(
        find.byKey(StageTextsPage.onArrivalKey),
        'Par où partir ?',
      );
      await _keep(tester);

      final car = kept!.findFamily('en_voiture')!;
      expect(car.label, 'La voiture');
      expect(car.completionText, startsWith('Tu as trouvé tous les mots'));
      expect(car.departureLabel, 'Prendre la voiture');
      expect(car.missingTextCount, 0);
      expect(kept!.narrative.onArrival, 'Par où partir ?');
      // L'identifiant ne suit pas le nom.
      expect(kept!.findFamily('en_voiture'), isNotNull);
    });

    testWidgets('vider un texte le retire', (tester) async {
      Stage? kept;
      await _pump(
        tester,
        _house(withTexts: true),
        onClosed: (stage) => kept = stage,
      );

      await tester.enterText(
        find.byKey(StageTextsPage.departureKeyFor('en_bus')),
        '  ',
      );
      await _keep(tester);

      expect(kept!.findFamily('en_bus')!.departureLabel, isNull);
      expect(kept!.findFamily('en_bus')!.lacksDepartureLabel, isTrue);
    });

    testWidgets('un nom vide garde l\'ancien', (tester) async {
      Stage? kept;
      await _pump(tester, _house(), onClosed: (stage) => kept = stage);

      await tester.enterText(
        find.byKey(StageTextsPage.labelKeyFor('en_bus')),
        '',
      );
      await tester.enterText(find.byKey(StageTextsPage.locationNameKey), '');
      await _keep(tester);

      expect(kept!.findFamily('en_bus')!.label, 'En bus');
      expect(kept!.locationName, 'Devant la maison');
    });

    testWidgets('le lieu renomme garde son identifiant', (tester) async {
      Stage? kept;
      await _pump(tester, _house(), onClosed: (stage) => kept = stage);

      await tester.enterText(
        find.byKey(StageTextsPage.locationNameKey),
        'Devant la petite maison',
      );
      await _keep(tester);

      expect(kept!.locationName, 'Devant la petite maison');
      expect(kept!.id, 'maison');
    });

    testWidgets('renoncer ne rend rien', (tester) async {
      Stage? kept;
      var closed = false;
      await _pump(tester, _house(), onClosed: (stage) {
        kept = stage;
        closed = true;
      });

      await tester.enterText(find.byKey(StageTextsPage.onArrivalKey), 'Perdu');
      await tester.tap(find.byTooltip('Fermer sans garder'));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(kept, isNull);
    });
  });

  testWidgets('tri unique : « autre chose » a son nom, pas de « Bravo ! »', (
    tester,
  ) async {
    await _pump(tester, _garage());

    expect(
      find.byKey(StageTextsPage.labelKeyFor('autre_chose')),
      findsOneWidget,
    );
    expect(
      find.byKey(StageTextsPage.completionKeyFor('autre_chose')),
      findsNothing,
    );
    expect(find.text('3 · Quand « Les types de musique » est pleine'),
        findsOneWidget);
    expect(find.textContaining('Autre chose » est pleine'), findsNothing);
  });

  testWidgets('une fin : une seule diapositive, son titre et son recit', (
    tester,
  ) async {
    Stage? kept;
    await _pump(
      tester,
      build.ending(id: 'plage', location: 'La plage'),
      onClosed: (stage) => kept = stage,
    );

    expect(find.text('La fin'), findsOneWidget);
    expect(find.text('2 · Les boîtes'), findsNothing);

    await tester.enterText(
      find.byKey(StageTextsPage.onArrivalKey),
      'Ça y est, Grisbie est arrivée à la plage !',
    );
    await _keep(tester);

    expect(
      kept!.narrative.onArrival,
      'Ça y est, Grisbie est arrivée à la plage !',
    );
  });
}
