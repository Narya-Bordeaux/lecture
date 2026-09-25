import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/pages/adventure_opening_page.dart';
import 'package:grisbie/ui/pages/adventure_page.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

import '../support/disk_content.dart';
import '../support/stage_builders.dart' as build;

/// Monte la page de garde seule, sans illustration : l'image n'est pas dans le
/// bundle de test, et c'est la mise en page qui est eprouvee ici.
Future<void> pumpOpening(
  WidgetTester tester, {
  required AdventureOpening opening,
  required VoidCallback onStart,
  Size screen = const Size(1080, 2340),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: AdventureOpeningPage(
        opening: opening,
        adventureTitle: 'Titre de repli',
        onStart: onStart,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Page de garde', () {
    testWidgets('montre le titre, puis le texte', (tester) async {
      await pumpOpening(
        tester,
        opening: const AdventureOpening(
          title: 'Grisbie part à la plage',
          text: 'Ce matin, Grisbie a mis son sac à dos.',
        ),
        onStart: () {},
      );

      expect(find.text('Grisbie part à la plage'), findsOneWidget);
      expect(
        find.text('Ce matin, Grisbie a mis son sac à dos.'),
        findsOneWidget,
      );
      expect(find.text(UiStringsFr.startAdventure), findsOneWidget);
    });

    testWidgets('le titre est au-dessus du texte', (tester) async {
      await pumpOpening(
        tester,
        opening: const AdventureOpening(title: 'Le titre', text: 'Le texte.'),
        onStart: () {},
      );

      expect(
        tester.getTopLeft(find.text('Le titre')).dy,
        lessThan(tester.getTopLeft(find.text('Le texte.')).dy),
      );
    });

    testWidgets('sans titre propre, celui de l\'aventure s\'affiche', (
      tester,
    ) async {
      await pumpOpening(
        tester,
        opening: const AdventureOpening(text: 'Un texte.'),
        onStart: () {},
      );

      expect(find.text('Titre de repli'), findsOneWidget);
    });

    testWidgets('le bouton reste visible sans avoir a faire defiler', (
      tester,
    ) async {
      // Un texte tres long ne doit pas repousser le bouton hors de l'ecran :
      // un enfant ne devinerait pas qu'il faut faire glisser la page.
      await pumpOpening(
        tester,
        opening: AdventureOpening(
          title: 'Un titre',
          text: List<String>.filled(40, 'Une phrase de recit.').join(' '),
        ),
        onStart: () {},
        screen: const Size(720, 1280),
      );

      final button = find.text(UiStringsFr.startAdventure);
      expect(button, findsOneWidget);

      final rect = tester.getRect(button);
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(rect.bottom, lessThanOrEqualTo(screenHeight));
    });

    testWidgets('le bouton annonce le depart', (tester) async {
      var started = false;

      await pumpOpening(
        tester,
        opening: const AdventureOpening(text: 'Un texte.'),
        onStart: () => started = true,
      );
      await tester.tap(find.text(UiStringsFr.startAdventure));

      expect(started, isTrue);
    });
  });

  group('Enchainement depuis l\'aventure livree', () {
    // Le contenu se charge ici, et surtout pas dans le test : `testWidgets`
    // fait tourner une horloge simulee, ou une lecture disque reelle ne se
    // resout jamais — le test tournerait sans fin.
    late Adventure adventure;
    setUpAll(() async => adventure = await loadRealAdventure());

    testWidgets('la page de garde precede le premier lieu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdventurePage(
            // Le contenu est deja charge : un depot qui lirait le disque
            // pendant le rendu ferait tourner le test sans fin, l'horloge de
            // pumpAndSettle n'attendant pas les entrees-sorties reelles.
            repository: PreloadedAdventureRepository(adventure),
            adventureId: adventure.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // D'abord la page de garde.
      expect(find.text('Grisbie part à la plage'), findsOneWidget);

      await tester.tap(find.text(UiStringsFr.startAdventure));
      await tester.pumpAndSettle();

      // Puis le jeu, directement.
      expect(find.text('Grisbie part à la plage'), findsNothing);
      expect(find.text('En bus'), findsOneWidget);
    });
  });

  group('Arrivee dans un lieu de jeu', () {
    testWidgets('le jeu s\'ouvre aussitot, l\'enonce en haut', (tester) async {
      // Aucun ecran de recit ne s'intercale : l'enonce se lit sur la scene,
      // pendant qu'on trie. Le lire sur un ecran quitte avant de jouer lui
      // otait son role, qui est de donner son sens au tri.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adventure = Adventure(
        id: 'essai',
        title: 'Essai',
        coverAsset: 'pictures/vignette.jpg',
        startStageId: 'maison',
        stages: <String, Stage>{
          'maison': build.stage(
            id: 'maison',
            arrivalText: 'Par où partir ?',
            drawCount: 1,
            families: <WordFamily>[
              build.family(
                id: 'en_bus',
                label: 'En bus',
                words: <Word>[build.word('ticket')],
                destination: 'fin',
                area: const RelativeArea(
                  left: 0.1,
                  top: 0.5,
                  width: 0.4,
                  height: 0.2,
                ),
              ),
            ],
          ),
          'fin': build.ending(id: 'fin'),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AdventurePage(
            repository: PreloadedAdventureRepository(adventure),
            adventureId: adventure.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(StagePage.wordTrayKey), findsOneWidget);
      expect(find.text('Par où partir ?'), findsOneWidget);
      expect(find.text('ticket'), findsOneWidget);
    });
  });
}
