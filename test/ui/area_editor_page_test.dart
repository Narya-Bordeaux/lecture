import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';
import 'package:grisbie/ui/widgets/content_image.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';

import '../support/memory_content.dart';

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

/// Ce que la page a rendu en se fermant.
///
/// Rien ne s'affiche plus en JSON : c'est l'etape calee, rendue par
/// « Garder », qui dit ou sont les zones — celle meme que l'editeur de lieu
/// reposera dans l'aventure.
class EditorOutcome {
  Stage? placed;
  bool closed = false;
}

Future<EditorOutcome> pumpEditor(
  WidgetTester tester,
  Stage stage, {
  ContentSource? contentSource,
}) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final outcome = EditorOutcome();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            outcome.placed = await Navigator.of(context).push<Stage>(
              MaterialPageRoute<Stage>(
                builder: (_) => AreaEditorPage(
                  stage: stage,
                  contentSource: contentSource,
                ),
              ),
            );
            outcome.closed = true;
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

/// Ferme la page par « Garder » et rend les zones de chaque famille.
Future<Map<String, RelativeArea?>> keep(
  WidgetTester tester,
  EditorOutcome outcome,
) async {
  await tester.tap(find.text('Garder'));
  await tester.pumpAndSettle();
  expect(outcome.closed, isTrue);
  return <String, RelativeArea?>{
    for (final family in outcome.placed!.families) family.id: family.area,
  };
}

const RelativeArea _topLeft = RelativeArea(
  left: 0.0,
  top: 0.0,
  width: 0.2,
  height: 0.2,
);

void main() {
  group('Calage des zones', () {
    testWidgets('chaque famille recoit un cadre a manipuler', (tester) async {
      await pumpEditor(tester, buildStage());

      // L'intitule apparait deux fois : sur le cadre de jeu en apercu, et sur
      // la poignee de l'outil.
      expect(find.text('En bus'), findsWidgets);
      expect(find.text('En voiture'), findsWidgets);
    });

    testWidgets('chaque poignee recouvre exactement la zone du jeu', (
      tester,
    ) async {
      // L'illustration commence sous le bandeau, et le bandeau grandit avec
      // l'enonce. Une poignee calculee sur l'ecran entier serait decalee
      // d'autant : l'auteur calerait sa zone a cote de celle que l'enfant
      // touchera.
      const bus = RelativeArea(left: 0.1, top: 0.1, width: 0.3, height: 0.2);
      final stage = buildStage(busArea: bus, carArea: _topLeft);
      await pumpEditor(
        tester,
        stage.copyWith(
          narrative: const Narrative(
            onArrival:
                'Un énoncé assez long pour tenir sur deux lignes, '
                'et même sur trois quand l\'écran est étroit.',
          ),
        ),
      );

      final handle = tester.getRect(
        find.byKey(AreaEditorPage.handleKeyFor('en_bus')),
      );
      final zone = tester.getRect(
        find.byKey(FamilyDropZone.frameKeyFor('en_bus')),
      );
      expect(handle.top, closeTo(zone.top, 1));
      expect(handle.left, closeTo(zone.left, 1));
      expect(handle.height, closeTo(zone.height, 1));
    });

    testWidgets('aucun JSON n\'est montre ni a copier', (tester) async {
      // Le calage s'enregistre avec l'aventure : le recopier a la main n'a
      // plus d'objet, et l'afficher laisserait croire qu'il le faut.
      await pumpEditor(tester, buildStage());

      expect(find.textContaining('"left"'), findsNothing);
      expect(find.text('Copier'), findsNothing);
    });

    testWidgets('une etape sans zone posee en recoit par defaut', (
      tester,
    ) async {
      // Cas d'une illustration toute neuve : sans cela l'auteur devrait faire
      // apparaitre trois cadres superposes au meme endroit.
      final outcome = await pumpEditor(tester, buildStage());

      final areas = await keep(tester, outcome);
      expect(areas['en_bus'], isNotNull);
      expect(areas['en_voiture'], isNotNull);
    });

    testWidgets('une zone par chemin, meme au-dela de trois', (tester) async {
      final families = <WordFamily>[
        for (var index = 0; index < 5; index++)
          build.family(
            id: 'chemin_$index',
            label: 'Chemin $index',
            words: <Word>[build.word('mot$index')],
            destination: 'lieu_$index',
          ),
      ];
      final outcome = await pumpEditor(
        tester,
        build.stage(id: 'carrefour', families: families),
      );

      expect(find.textContaining('chevauchent'), findsNothing);
      final areas = await keep(tester, outcome);
      expect(areas.values.whereType<RelativeArea>(), hasLength(5));
    });

    testWidgets('le tri unique a deux zones : le theme et le reste', (
      tester,
    ) async {
      final outcome = await pumpEditor(
        tester,
        build.stage(
          id: 'boutique',
          families: <WordFamily>[
            build.family(
              id: 'a_manger',
              label: 'Ce qui se mange',
              words: <Word>[build.word('pomme')],
              destination: 'plage',
            ),
            // Sans destination : la liste du reste.
            build.family(
              id: 'le_reste',
              label: 'Le reste',
              words: <Word>[build.word('clou')],
            ),
          ],
        ),
      );

      final areas = await keep(tester, outcome);
      expect(areas['a_manger'], isNotNull);
      expect(areas['le_reste'], isNotNull);
    });

    testWidgets('les zones par defaut ne se chevauchent pas', (tester) async {
      await pumpEditor(tester, buildStage());

      expect(find.textContaining('chevauchent'), findsNothing);
    });

    testWidgets('une zone deja calee est rendue telle quelle', (tester) async {
      const bus = RelativeArea(left: 0.4, top: 0.4, width: 0.2, height: 0.2);
      final outcome = await pumpEditor(
        tester,
        buildStage(busArea: bus, carArea: _topLeft),
      );

      final areas = await keep(tester, outcome);
      expect(areas['en_bus'], bus);
      expect(areas['en_voiture'], _topLeft);
    });

    testWidgets('faire glisser un cadre deplace la zone', (tester) async {
      final outcome = await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.4,
            top: 0.4,
            width: 0.2,
            height: 0.2,
          ),
          carArea: _topLeft,
        ),
      );

      // 40 points sur 400 de large : un dixieme de l'illustration.
      await tester.drag(find.text('En bus').last, const Offset(40, 0));
      await tester.pumpAndSettle();

      final areas = await keep(tester, outcome);
      expect(areas['en_bus']!.left, closeTo(0.5, 1e-9));
    });

    testWidgets('les zones rendues sont arrondies au centieme', (tester) async {
      // Ce qui part dans le fichier doit rester lisible par un enseignant.
      final outcome = await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.4,
            top: 0.4,
            width: 0.2,
            height: 0.2,
          ),
          carArea: _topLeft,
        ),
      );

      await tester.drag(find.text('En bus').last, const Offset(13, 0));
      await tester.pumpAndSettle();

      final left = (await keep(tester, outcome))['en_bus']!.left;
      expect((left * 100).roundToDouble() / 100, left);
    });

    testWidgets('une zone poussee hors de l\'image s\'arrete au bord', (
      tester,
    ) async {
      final outcome = await pumpEditor(
        tester,
        buildStage(
          busArea: const RelativeArea(
            left: 0.7,
            top: 0.4,
            width: 0.2,
            height: 0.2,
          ),
          carArea: _topLeft,
        ),
      );

      await tester.drag(find.text('En bus').last, const Offset(400, 0));
      await tester.pumpAndSettle();

      // Bloquee a 1 - 0.2 : la zone reste entierement sur l'illustration.
      final areas = await keep(tester, outcome);
      expect(areas['en_bus']!.left, closeTo(0.8, 1e-9));
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

      // Par leur nom, celui que l'auteur a saisi — pas par leur identifiant.
      final warning = find.textContaining('chevauchent');
      expect(warning, findsOneWidget);
      expect(tester.widget<Text>(warning).data, contains('En bus'));
      expect(tester.widget<Text>(warning).data, contains('En voiture'));
    });

    testWidgets('fermer sans garder ne rend rien', (tester) async {
      final outcome = await pumpEditor(tester, buildStage());

      await tester.tap(find.byTooltip('Fermer sans garder'));
      await tester.pumpAndSettle();

      expect(outcome.closed, isTrue);
      expect(outcome.placed, isNull);
    });
  });

  group('Illustration', () {
    testWidgets('le decor se lit par la source de travail', (tester) async {
      // Le defaut d'origine : l'apercu cherchait l'illustration dans le
      // bundle, ou une image prise avec l'outil n'est pas. Le calage se
      // faisait alors sur un fond vide.
      final folder = MemoryContentFolder();
      await pumpEditor(
        tester,
        buildStage().copyWith(backgroundAsset: 'pictures/maison_1.jpg'),
        contentSource: folder,
      );

      final images = tester.widgetList<ContentImage>(find.byType(ContentImage));
      expect(images, isNotEmpty);
      for (final image in images) {
        expect(image.path, 'pictures/maison_1.jpg');
        expect(image.source, same(folder));
      }
    });
  });
}
