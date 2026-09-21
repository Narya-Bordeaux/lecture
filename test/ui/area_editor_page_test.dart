import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';

import '../support/stage_builders.dart' as build;

/// Une etape de calage : deux familles, dont une deja posee sur l'illustration.
Stage buildStage({RelativeArea? busArea, RelativeArea? carArea}) {
  return build.stage(
    id: 'maison',
    families: <WordFamily>[
      build.family(
        id: 'en_bus',
        label: 'En bus',
        words: <Word>[build.word('arrêt'), build.word('ticket')],
        destination: 'gare',
        area: busArea,
      ),
      build.family(
        id: 'en_voiture',
        label: 'En voiture',
        words: <Word>[build.word('volant'), build.word('clé')],
        destination: 'garage',
        area: carArea,
      ),
    ],
  );
}

/// Sans illustration chargee, la scene occupe toute la surface : une fraction
/// se lit donc directement sur la taille de l'ecran, ce qui rend les
/// deplacements previsibles.
const Size _screen = Size(400, 800);

Future<void> pumpEditor(WidgetTester tester, Stage stage) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: AreaEditorPage(stage: stage)));
  await tester.pumpAndSettle();
}

void main() {
  group('Calage des zones', () {
    testWidgets('chaque famille recoit un cadre a manipuler', (tester) async {
      await pumpEditor(tester, buildStage());

      // L'intitule apparait deux fois : sur le cadre de jeu en apercu, et sur
      // la poignee de l'outil.
      expect(find.text('En bus'), findsWidgets);
      expect(find.text('En voiture'), findsWidgets);
    });

    testWidgets('une etape sans zone posee en recoit par defaut', (
      tester,
    ) async {
      // Cas d'une illustration toute neuve : sans cela l'auteur devrait faire
      // apparaitre trois cadres superposes au meme endroit.
      await pumpEditor(tester, buildStage());

      expect(find.textContaining('"left"'), findsOneWidget);
      // Deux familles, donc deux lignes de calage.
      expect(find.textContaining('en_bus'), findsOneWidget);
      expect(find.textContaining('en_voiture'), findsOneWidget);
    });

    testWidgets('les zones par defaut ne se chevauchent pas', (tester) async {
      await pumpEditor(tester, buildStage());

      expect(find.textContaining('chevauchent'), findsNothing);
    });

    testWidgets('faire glisser un cadre deplace la zone', (tester) async {
      await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.4,
            top: 0.4,
            width: 0.2,
            height: 0.2,
          ),
          carArea: const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.2,
            height: 0.2,
          ),
        ),
      );

      expect(find.textContaining('"left": 0.40'), findsOneWidget);

      // 40 points sur 400 de large : un dixieme de l'illustration.
      await tester.drag(find.text('En bus').last, const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('"left": 0.50'), findsOneWidget);
    });

    testWidgets('une zone poussee hors de l\'image s\'arrete au bord', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.7,
            top: 0.4,
            width: 0.2,
            height: 0.2,
          ),
          carArea: const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.2,
            height: 0.2,
          ),
        ),
      );

      await tester.drag(find.text('En bus').last, const Offset(400, 0));
      await tester.pumpAndSettle();

      // Bloquee a 1 - 0.2 : la zone reste entierement sur l'illustration.
      expect(find.textContaining('"left": 0.80'), findsOneWidget);
    });

    testWidgets('un chevauchement est signale en nommant les deux familles', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.1,
            top: 0.4,
            width: 0.3,
            height: 0.2,
          ),
          carArea: const RelativeArea(
            left: 0.3,
            top: 0.4,
            width: 0.3,
            height: 0.2,
          ),
        ),
      );

      final warning = find.textContaining('chevauchent');
      expect(warning, findsOneWidget);
      expect(tester.widget<Text>(warning).data, contains('en_bus'));
      expect(tester.widget<Text>(warning).data, contains('en_voiture'));
    });
  });
}
