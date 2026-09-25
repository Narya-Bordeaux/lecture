import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/stage_editor_page.dart';

import '../support/stage_builders.dart' as build;

/// Le texte sous « Bravo ! », dans l'editeur de lieu : pre-ecrit, modifiable,
/// et le titre, lui, ne se change pas.

const String _proposedBus =
    'Tu as rangé tous les mots «\u00A0En bus\u00A0». Tu peux partir vers la gare, '
    'ou ouvrir un autre chemin.';

Stage _house({String? busText}) {
  final bus = build.family(
    id: 'en_bus',
    label: 'En bus',
    words: <Word>[build.word('ticket')],
    destination: 'gare',
  );
  return build.stage(
    id: 'maison',
    families: <WordFamily>[
      busText == null ? bus : bus.copyWith(completionText: busText),
      build.family(
        id: 'a_pied',
        label: 'À pied',
        words: <Word>[build.word('sentier')],
        destination: 'rue',
      ),
    ],
  );
}

/// Monte l'editeur ; [kept] recoit l'etape rendue par « Garder ».
Future<void> _pump(
  WidgetTester tester,
  Stage stage,
  void Function(Stage? kept) onKept,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            onKept(
              await Navigator.of(context).push<Stage>(
                MaterialPageRoute<Stage>(
                  builder: (_) => StageEditorPage(
                    stage: stage,
                    destinationNames: const <String, String>{
                      'gare': 'La gare',
                      'rue': 'La rue',
                    },
                  ),
                ),
              ),
            );
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Finder _busField() => find.byKey(const Key('completion_En bus'));

Future<void> _keep(WidgetTester tester) async {
  await tester.tap(find.text('Garder'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chaque trajet a son champ, pre-ecrit avec le texte propose', (
    tester,
  ) async {
    await _pump(tester, _house(), (_) {});

    expect(
      tester.widget<TextField>(_busField()).controller!.text,
      _proposedBus,
    );
    expect(find.byKey(const Key('completion_À pied')), findsOneWidget);
    // Le titre est montre, pas saisi.
    expect(
      tester.widget<TextField>(_busField()).decoration!.prefixText,
      startsWith('Bravo !'),
    );
  });

  testWidgets('« autre chose » n\'a pas de champ', (tester) async {
    final shop = build.stage(
      id: 'boutique',
      families: <WordFamily>[
        build.family(
          id: 'a_manger',
          label: 'Ce qui se mange',
          words: <Word>[build.word('pomme')],
          destination: 'plage',
        ),
        build.family(
          id: 'autre_chose',
          label: 'Autre chose',
          words: <Word>[build.word('clou')],
        ),
      ],
    );
    await _pump(tester, shop, (_) {});

    expect(find.byKey(const Key('completion_Ce qui se mange')), findsOneWidget);
    expect(find.byKey(const Key('completion_Autre chose')), findsNothing);
  });

  testWidgets('garde tel quel, le texte propose ne s\'ecrit pas', (
    tester,
  ) async {
    Stage? kept;
    await _pump(tester, _house(), (stage) => kept = stage);

    await _keep(tester);

    expect(kept!.findFamily('en_bus')!.completionText, isNull);
  });

  testWidgets('modifie, il s\'ecrit tel quel', (tester) async {
    Stage? kept;
    await _pump(tester, _house(), (stage) => kept = stage);

    await tester.enterText(_busField(), 'Le bus arrive au coin de la rue !');
    await _keep(tester);

    expect(
      kept!.findFamily('en_bus')!.completionText,
      'Le bus arrive au coin de la rue !',
    );
  });

  testWidgets('un texte ecrit se rouvre, et peut revenir au texte propose', (
    tester,
  ) async {
    Stage? kept;
    await _pump(
      tester,
      _house(busText: 'Le bus arrive !'),
      (stage) => kept = stage,
    );

    expect(
      tester.widget<TextField>(_busField()).controller!.text,
      'Le bus arrive !',
    );

    await tester.tap(find.text('Revenir au texte proposé'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_busField()).controller!.text,
      _proposedBus,
    );
    expect(find.text('Revenir au texte proposé'), findsNothing);

    await _keep(tester);
    expect(kept!.findFamily('en_bus')!.completionText, isNull);
  });
}
