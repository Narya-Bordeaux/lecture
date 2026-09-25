import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/pages/stage_appearance_page.dart';

import '../support/disk_content.dart';

/// L'apparence d'un lieu : son illustration et la place de ses cadres, rien
/// d'autre. Les textes ont leur propre ecran (`stage_texts_page_test.dart`).

/// Monte l'editeur et rend ce qu'il renvoie a la fermeture.
Future<Stage?> pumpEditor(
  WidgetTester tester,
  Stage stage, {
  PictureCatalog? pictures,
  ContentSource? contentSource,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  Stage? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<Stage>(
              MaterialPageRoute<Stage>(
                builder: (_) => StageAppearancePage(
                  stage: stage,
                  pictures: pictures,
                  contentSource: contentSource,
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

  return result;
}

/// Ferme l'editeur par « Garder » et rend l'etape obtenue.
///
/// « Garder », et non « Enregistrer » : rien n'est ecrit ici, l'etape remonte
/// a l'ecran du parcours. Un seul geste de l'outil ecrit sur le disque.
Future<void> save(WidgetTester tester) async {
  await tester.tap(find.text('Garder'));
  await tester.pumpAndSettle();
}

void main() {
  late Adventure realAdventure;

  setUpAll(() async {
    realAdventure = await loadRealDraft();
  });

  group('Ce que l\'ecran montre', () {
    testWidgets('le chemin de l\'illustration, modifiable', (tester) async {
      await pumpEditor(tester, realAdventure.startStage);

      expect(find.text('pictures/maison.jpg'), findsOneWidget);
    });

    testWidgets('un lieu sans famille ne propose pas de poser des zones',
        (tester) async {
      // Une fin n'a rien a y deposer : le bouton n'aurait aucune cible.
      await pumpEditor(tester, realAdventure.findStage('plage')!);

      expect(find.text('Placer les zones'), findsNothing);
    });

    testWidgets('un lieu avec des familles le propose', (tester) async {
      await pumpEditor(tester, realAdventure.startStage);

      expect(find.text('Placer les zones'), findsOneWidget);
    });
  });

  group('Choisir une image dans le depot', () {
    // L'auteur verse ses images dans `assets/content/pictures/` ; l'outil les
    // propose, et le jeu compile en meme temps les embarque. Rien n'est copie
    // ni renomme.

    testWidgets('sans catalogue, le champ reste seul', (tester) async {
      await pumpEditor(tester, realAdventure.startStage);

      expect(find.text('Choisir une image'), findsNothing);
    });

    testWidgets('l\'image choisie remplit le chemin', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.findStage('gare')!,
        pictures: FakePictureCatalog(<String>[
          'pictures/Grisbie carrefour.jpg',
          'pictures/Grisbie gare.jpg',
        ]),
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();

      // La liste montre les noms, pas les chemins.
      expect(find.text('Grisbie carrefour.jpg'), findsOneWidget);
      await tester.tap(find.text('Grisbie gare.jpg'));
      await tester.pumpAndSettle();

      expect(find.text('pictures/Grisbie gare.jpg'), findsOneWidget);
    });

    testWidgets('renoncer laisse le chemin d\'avant', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.startStage,
        pictures: FakePictureCatalog(<String>['pictures/Grisbie gare.jpg']),
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('pictures/maison.jpg'), findsOneWidget);
    });

    testWidgets('un depot vide dit ou verser les images', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.startStage,
        pictures: FakePictureCatalog(const <String>[]),
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();

      expect(find.textContaining('assets/content/pictures/'), findsOneWidget);
    });

    testWidgets('une image absente du depot est signalee', (tester) async {
      // Une image rangee autrefois par l'outil sur le depot distant n'existe
      // pas dans le jeu compile : l'enfant verrait un fond uni.
      await pumpEditor(
        tester,
        realAdventure.startStage.copyWith(
          backgroundAsset: 'pictures/gare_1790155902917.jpg',
        ),
        pictures: FakePictureCatalog(<String>['pictures/Grisbie gare.jpg']),
      );

      expect(find.textContaining('pas dans le dépôt'), findsOneWidget);
    });

    testWidgets('une image qui ne se lit pas dit pourquoi', (tester) async {
      // « Image introuvable » seul laissait chercher a l'aveugle : un refus
      // du depot, une coupure, un fichier absent se ressemblaient tous. La
      // raison reelle s'affiche sous l'apercu.
      await pumpEditor(
        tester,
        realAdventure.startStage,
        contentSource: _FailingSource('le dépôt a refusé la lecture'),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('le dépôt a refusé la lecture'), findsOneWidget);
    });

    testWidgets('une image du depot ne signale rien', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.startStage,
        pictures: FakePictureCatalog(<String>['pictures/maison.jpg']),
      );

      expect(find.textContaining('pas dans le dépôt'), findsNothing);
      expect(find.textContaining('Image de travail'), findsNothing);
    });
  });

  group('Ce que l\'ecran rend', () {
    testWidgets('vider le chemin retire l\'illustration', (tester) async {
      Stage? edited;
      await _withEditor(tester, realAdventure.startStage,
          (result) => edited = result, (tester) async {
        await tester.enterText(find.byKey(const Key('background')), '');
        await save(tester);
      });

      // `copyWith` seul garderait l'ancienne valeur, et l'auteur croirait
      // avoir retire l'image.
      expect(edited!.backgroundAsset, isNull);
    });

    testWidgets('renoncer ne rend rien', (tester) async {
      Stage? edited;
      var closed = false;
      await _withEditor(tester, realAdventure.findStage('gare')!, (result) {
        edited = result;
        closed = true;
      }, (tester) async {
        await tester.enterText(find.byKey(const Key('background')), 'Perdu');
        await tester.tap(find.byTooltip('Fermer sans garder'));
        await tester.pumpAndSettle();
      });

      expect(closed, isTrue);
      expect(edited, isNull);
    });
  });
}

/// Ouvre l'editeur, execute [act], et transmet ce que la page a rendu.
Future<void> _withEditor(
  WidgetTester tester,
  Stage stage,
  void Function(Stage? result) collect,
  Future<void> Function(WidgetTester tester) act,
) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            collect(
              await Navigator.of(context).push<Stage>(
                MaterialPageRoute<Stage>(
                  builder: (_) => StageAppearancePage(stage: stage),
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

  await act(tester);
}

/// Un catalogue fixe, sans bundle.
class FakePictureCatalog implements PictureCatalog {
  FakePictureCatalog(this.pictures);

  final List<String> pictures;

  @override
  Future<List<String>> listPictures() async => pictures;
}

/// Une source dont chaque lecture echoue, avec la raison donnee.
class _FailingSource implements ContentSource {
  _FailingSource(this.reason);

  final String reason;

  @override
  Future<String> readFile(String path) async => throw StateError(reason);

  @override
  Future<Uint8List> readBytes(String path) async => throw StateError(reason);
}
