import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/home_layout.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/ui/pages/game_home_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

import '../support/disk_content.dart';
import '../support/stage_builders.dart' as build;

/// Des aventures fabriquees pour le test : « Essai 0 », « Essai 1 »…
///
/// Chacune se reduit a une fin, ce qui suffit a eprouver l'aller et le
/// retour depuis l'accueil. Aucun contenu de ce fichier n'est livre.
class FabricatedAdventures implements AdventureRepository {
  FabricatedAdventures(this.count);

  final int count;

  String titleOf(int index) => 'Essai $index';

  @override
  Future<ContentIndex> loadIndex() async => ContentIndex(
        lexiconFiles: const <String>[],
        adventures: <AdventureEntry>[
          for (var index = 0; index < count; index++)
            AdventureEntry(id: 'essai_$index', title: titleOf(index), file: ''),
        ],
      );

  @override
  Future<Adventure> loadAdventure(String adventureId) async => Adventure(
        id: adventureId,
        title: adventureId,
        coverAsset: 'pictures/vignette.jpg',
        startStageId: 'fin',
        stages: <String, Stage>{
          'fin': build.ending(id: 'fin', location: 'La fin').copyWith(
                narrative: const Narrative(onArrival: 'Et voila.'),
              ),
        },
      );
}

/// Un telephone courant, en points logiques.
const Size phone = Size(390, 844);

Future<void> pumpHome(WidgetTester tester, AdventureRepository repository) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: GameHomePage(repository: repository)),
  );
  await tester.pumpAndSettle();
}

/// Les titres d'aventure a l'ecran, de gauche a droite.
List<String> shownTitles(WidgetTester tester, FabricatedAdventures adventures) {
  final shown = <String, double>{};
  for (var index = 0; index < adventures.count; index++) {
    final finder = find.text(adventures.titleOf(index));
    if (finder.evaluate().isEmpty) continue;
    shown[adventures.titleOf(index)] = tester.getCenter(finder).dx;
  }
  return shown.keys.toList()..sort((a, b) => shown[a]!.compareTo(shown[b]!));
}

/// Fait tourner la roue de [slots] crans, lentement : un geste lance
/// emporterait la roue plus loin.
Future<void> turn(WidgetTester tester, double slots) async {
  final layout = HomeLayout.compute(width: phone.width, height: phone.height);
  await tester.timedDrag(
    find.byType(GameHomePage),
    Offset(-slots * layout.slotSpacing, 0),
    const Duration(seconds: 2),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Ce que l accueil montre', () {
    testWidgets('le titre du jeu et son logo', (tester) async {
      await pumpHome(tester, FabricatedAdventures(3));

      expect(find.bySemanticsLabel(UiStringsFr.appTitle), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == GameHomePage.logoAsset),
        findsOneWidget,
      );
    });

    testWidgets('trois aventures, chacune sous son titre', (tester) async {
      final adventures = FabricatedAdventures(3);
      await pumpHome(tester, adventures);

      expect(shownTitles(tester, adventures), <String>['Essai 0', 'Essai 1', 'Essai 2']);
    });

    testWidgets('une seule aventure se pose au milieu', (tester) async {
      final adventures = FabricatedAdventures(1);
      await pumpHome(tester, adventures);

      expect(tester.getCenter(find.text('Essai 0')).dx, closeTo(phone.width / 2, 1));
    });
  });

  group('La roue', () {
    testWidgets('au-dela de trois, les premieres se montrent', (tester) async {
      final adventures = FabricatedAdventures(5);
      await pumpHome(tester, adventures);

      expect(shownTitles(tester, adventures), <String>['Essai 0', 'Essai 1', 'Essai 2']);
    });

    testWidgets('glisser d un cran fait entrer la suivante', (tester) async {
      final adventures = FabricatedAdventures(5);
      await pumpHome(tester, adventures);

      await turn(tester, 1);

      expect(shownTitles(tester, adventures), <String>['Essai 1', 'Essai 2', 'Essai 3']);
    });

    testWidgets('elle boucle : vers la droite revient la derniere',
        (tester) async {
      final adventures = FabricatedAdventures(5);
      await pumpHome(tester, adventures);

      await turn(tester, -1);

      expect(shownTitles(tester, adventures), <String>['Essai 4', 'Essai 0', 'Essai 1']);
    });

    testWidgets('lachee entre deux crans, elle se cale', (tester) async {
      final adventures = FabricatedAdventures(5);
      await pumpHome(tester, adventures);

      await turn(tester, 0.4);

      expect(shownTitles(tester, adventures), <String>['Essai 0', 'Essai 1', 'Essai 2']);
    });

    testWidgets('a trois aventures, elle ne tourne pas', (tester) async {
      final adventures = FabricatedAdventures(3);
      await pumpHome(tester, adventures);

      await turn(tester, 1);

      expect(shownTitles(tester, adventures), <String>['Essai 0', 'Essai 1', 'Essai 2']);
    });
  });

  group('Partir, et revenir', () {
    testWidgets('toucher une vignette ouvre son aventure', (tester) async {
      await pumpHome(tester, FabricatedAdventures(3));

      await tester.tap(find.text('Essai 1'));
      await tester.pumpAndSettle();

      expect(find.text('Et voila.'), findsOneWidget);
    });

    testWidgets('la fin ramene a l accueil', (tester) async {
      final adventures = FabricatedAdventures(3);
      await pumpHome(tester, adventures);

      await tester.tap(find.text('Essai 1'));
      await tester.pumpAndSettle();
      expect(find.text(UiStringsFr.startOver), findsNothing);
      await tester.tap(find.text(UiStringsFr.backToHome));
      await tester.pumpAndSettle();

      expect(shownTitles(tester, adventures), <String>['Essai 0', 'Essai 1', 'Essai 2']);
    });
  });

  group('Sur chaque format d ecran', () {
    // Les memes que le calcul de la mise en page (home_layout_test.dart),
    // montes pour de vrai : un debordement de colonne ne se voit qu'ici.
    const screens = <String, Size>{
      'petit telephone': Size(360, 640),
      'Galaxy A54': Size(360, 780),
      'grand telephone': Size(430, 932),
      'tablette': Size(768, 1024),
      'navigateur en largeur': Size(1280, 720),
    };

    screens.forEach((name, size) {
      testWidgets('$name : tout se pose sans deborder', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final adventures = FabricatedAdventures(5);

        await tester.pumpWidget(
          MaterialApp(home: GameHomePage(repository: adventures)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(shownTitles(tester, adventures), hasLength(3));
        for (final title in shownTitles(tester, adventures)) {
          final box = tester.getRect(find.text(title));
          expect(box.left, greaterThanOrEqualTo(0), reason: title);
          expect(box.right, lessThanOrEqualTo(size.width), reason: title);
          expect(box.bottom, lessThanOrEqualTo(size.height), reason: title);
        }
      });
    });
  });

  group('Le contenu livre', () {
    late Adventure delivered;

    setUpAll(() async => delivered = await loadRealAdventure());

    testWidgets('l aventure livree a sa vignette et son titre', (tester) async {
      await pumpHome(tester, PreloadedAdventureRepository(delivered));

      expect(find.text(delivered.title), findsOneWidget);
    });
  });
}
