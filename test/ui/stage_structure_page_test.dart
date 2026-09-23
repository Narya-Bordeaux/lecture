import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/outline_page.dart';
import 'package:grisbie/ui/pages/stage_structure_page.dart';

import '../support/stage_builders.dart';

/// Revenir sur un choix de circuit.
///
/// Toucher la ligne « Plusieurs listes », « Tri unique » ou « Fin » d'une
/// carte ouvre la structure du lieu : changer sa nature, renommer, rediriger
/// ou retirer un trajet. Rien ne disparait en passant : un lieu que plus rien
/// n'atteint reste, et se supprime depuis sa propre carte.

Adventure _crossroads() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'maison',
    stages: <String, Stage>{
      'maison': stage(
        id: 'maison',
        location: 'Devant la maison',
        drawCount: 1,
        families: <WordFamily>[
          family(id: 'en_bus', label: 'En bus', words: <Word>[word('ticket')], destination: 'gare'),
          family(id: 'en_voiture', label: 'En voiture', words: <Word>[word('volant')], destination: 'garage'),
        ],
      ),
      'gare': ending(id: 'gare', location: 'La gare'),
      'garage': ending(id: 'garage', location: 'Le garage'),
    },
  );
}

class StructureOutcome {
  Adventure? kept;
}

Future<StructureOutcome> pumpStructure(
  WidgetTester tester, {
  String stageId = 'maison',
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final outcome = StructureOutcome();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            outcome.kept = await Navigator.of(context).push<Adventure>(
              MaterialPageRoute<Adventure>(
                builder: (_) => StageStructurePage(
                  adventure: _crossroads(),
                  stageId: stageId,
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
  return outcome;
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Changer la nature', () {
    testWidgets('plusieurs listes devient tri unique, theme choisi', (tester) async {
      final outcome = await pumpStructure(tester);

      await tapAndSettle(tester, find.text('En faire un tri unique'));
      await tapAndSettle(tester, find.text('En bus').last);
      // Le trajet qui part est nomme avant d'agir.
      expect(find.textContaining('« En voiture »'), findsOneWidget);
      await tapAndSettle(tester, find.text('Confirmer'));
      await tapAndSettle(tester, find.text('Garder'));

      final maison = outcome.kept!.findStage('maison')!;
      expect(maison.nature, StageNature.singleSort);
      // Le lieu que plus rien n'atteint est reste.
      expect(outcome.kept!.findStage('garage'), isNotNull);
    });

    testWidgets('renoncer a la confirmation ne change rien', (tester) async {
      final outcome = await pumpStructure(tester);

      await tapAndSettle(tester, find.text('En faire une fin'));
      await tapAndSettle(tester, find.text('Annuler'));
      await tapAndSettle(tester, find.text('Garder'));

      expect(outcome.kept!.findStage('maison')!.nature, StageNature.sorting);
    });

    testWidgets('une fin se rouvre', (tester) async {
      final outcome = await pumpStructure(tester, stageId: 'gare');

      await tapAndSettle(tester, find.text('Rouvrir ce lieu'));
      await tapAndSettle(tester, find.text('Garder'));

      expect(outcome.kept!.findStage('gare')!.nature, StageNature.undefined);
    });
  });

  group('Un lieu rouvert se redefinit sur place', () {
    // Le defaut signale par l'auteur : apres « Rouvrir ce lieu », l'ecran
    // disait seulement « Choisissez sur la carte », une impasse.

    testWidgets('les trois reponses sont offertes ici meme', (tester) async {
      await pumpStructure(tester, stageId: 'gare');
      await tapAndSettle(tester, find.text('Rouvrir ce lieu'));

      expect(find.text('Plusieurs listes'), findsOneWidget);
      expect(find.text('Tri unique'), findsOneWidget);
      expect(find.text('Une fin'), findsOneWidget);
      expect(find.textContaining('Choisissez sur la carte'), findsNothing);
    });

    testWidgets('« Plusieurs listes » demande ses trajets, et les pose', (
      tester,
    ) async {
      final outcome = await pumpStructure(tester, stageId: 'gare');
      await tapAndSettle(tester, find.text('Rouvrir ce lieu'));
      await tapAndSettle(tester, find.text('Plusieurs listes'));

      await tester.enterText(find.byKey(const Key('trip-name-0')), 'Le train');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Créer'));
      await tapAndSettle(tester, find.text('Garder'));

      final gare = outcome.kept!.findStage('gare')!;
      expect(gare.nature, StageNature.sorting);
      expect(gare.families.single.label, 'Le train');
    });

    testWidgets('« Une fin » la referme', (tester) async {
      final outcome = await pumpStructure(tester, stageId: 'gare');
      await tapAndSettle(tester, find.text('Rouvrir ce lieu'));
      await tapAndSettle(tester, find.text('Une fin'));
      await tapAndSettle(tester, find.text('Garder'));

      expect(outcome.kept!.findStage('gare')!.nature, StageNature.ending);
    });
  });

  group('Les trajets', () {
    testWidgets('un trajet se renomme', (tester) async {
      final outcome = await pumpStructure(tester);

      await tapAndSettle(tester, find.byTooltip('Renommer « En bus »'));
      await tester.enterText(find.byKey(const Key('rename-trip')), 'En autocar');
      await tapAndSettle(tester, find.text('Valider'));
      await tapAndSettle(tester, find.text('Garder'));

      expect(
        outcome.kept!.findStage('maison')!.findFamily('en_bus')!.label,
        'En autocar',
      );
    });

    testWidgets('un trajet se retire, apres confirmation', (tester) async {
      final outcome = await pumpStructure(tester);

      await tapAndSettle(tester, find.byTooltip('Retirer « En voiture »'));
      await tapAndSettle(tester, find.text('Confirmer'));
      await tapAndSettle(tester, find.text('Garder'));

      expect(outcome.kept!.findStage('maison')!.findFamily('en_voiture'), isNull);
      expect(outcome.kept!.findStage('garage'), isNotNull);
    });

    testWidgets('un trajet se redirige vers un lieu deja ecrit', (tester) async {
      final outcome = await pumpStructure(tester);

      await tapAndSettle(tester, find.byKey(const Key('destination-en_voiture')));
      await tapAndSettle(tester, find.text('La gare').last);
      await tapAndSettle(tester, find.text('Garder'));

      expect(
        outcome.kept!
            .findStage('maison')!
            .findFamily('en_voiture')!
            .destinationStageId,
        'gare',
      );
    });

    testWidgets('revenir en arriere est permis, et signale', (tester) async {
      await pumpStructure(tester);

      await tapAndSettle(tester, find.byKey(const Key('destination-en_bus')));
      await tapAndSettle(tester, find.text('Devant la maison (ce lieu même)').last);

      expect(find.textContaining('tourner en rond'), findsOneWidget);
    });
  });

  group('Depuis le parcours', () {
    Future<void> pumpOutline(WidgetTester tester, Adventure adventure) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: OutlinePage(adventure: adventure)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('la ligne de nature ouvre la structure', (tester) async {
      await pumpOutline(tester, _crossroads());

      await tapAndSettle(
        tester,
        find.text('Plusieurs listes : l\'enfant range dans chacune.'),
      );

      expect(find.text('Ce que l\'enfant fait ici'), findsOneWidget);
    });

    testWidgets('une fin s\'ouvre aussi, pour pouvoir la rouvrir', (tester) async {
      await pumpOutline(tester, _crossroads());

      await tapAndSettle(
        tester,
        find.text('Fin de l\'aventure : du texte, pas de jeu.').first,
      );

      expect(find.text('Rouvrir ce lieu'), findsOneWidget);
    });

    testWidgets('un lieu detache se supprime depuis sa carte', (tester) async {
      final detached = _crossroads().withStage(
        _crossroads().findStage('maison')!.copyWith(
              families: <WordFamily>[
                family(id: 'en_bus', label: 'En bus', words: <Word>[word('ticket')], destination: 'gare'),
              ],
            ),
      );
      await pumpOutline(tester, detached);

      expect(find.text('Aucun chemin ne mène ici.'), findsOneWidget);
      await tapAndSettle(tester, find.text('Supprimer ce lieu'));
      await tapAndSettle(tester, find.text('Supprimer'));

      expect(find.text('Le garage'), findsNothing);
    });

    testWidgets('un lieu atteint ne propose pas de se supprimer', (tester) async {
      await pumpOutline(tester, _crossroads());

      expect(find.text('Supprimer ce lieu'), findsNothing);
    });
  });
}
