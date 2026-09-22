import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/ui/pages/stage_editor_page.dart';

import '../support/disk_content.dart';

/// Tout ce qu'un lieu porte, sauf ses mots.
///
/// L'ecran du parcours dit **ou** l'on va ; celui-ci dit **ce qu'il y a** :
/// le nom, l'illustration, les zones de depot et les deux moments de recit.
/// Les listes de mots sont un autre sujet, et un autre ecran — on les ouvre
/// depuis le trajet, pas depuis le lieu.

/// Monte l'editeur et rend ce qu'il renvoie a la fermeture.
Future<Stage?> pumpEditor(
  WidgetTester tester,
  Stage stage, {
  PictureLibrary? pictures,
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
                builder: (_) => StageEditorPage(
                  stage: stage,
                  pictures: pictures,
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
    realAdventure = await loadRealAdventure();
  });

  group('Ce que l\'ecran montre', () {
    testWidgets('les deux recits du lieu, tels qu\'ils sont ecrits',
        (tester) async {
      await pumpEditor(tester, realAdventure.findStage('gare')!);

      expect(find.text('La gare'), findsWidgets);
      expect(
        find.text('Le bus a amené Grisbie à la gare. Il y a des choses à voir'),
        findsOneWidget,
      );
      // Un lieu ne raconte pas son depart : le champ n'existe plus.
      expect(find.text('En repartant'), findsNothing);
    });

    testWidgets('le chemin de l\'illustration, modifiable', (tester) async {
      await pumpEditor(tester, realAdventure.startStage);

      expect(find.text('pictures/Grisbie_plage2.jpg'), findsOneWidget);
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

  group('Choisir une image dans l\'appareil', () {
    testWidgets('sans photothegue, le champ reste seul', (tester) async {
      // Une plateforme sans selecteur — ou un test — garde la saisie au
      // clavier plutot qu'un bouton qui ne ferait rien.
      await pumpEditor(tester, realAdventure.startStage);

      expect(find.text('Choisir une image'), findsNothing);
    });

    testWidgets('l\'image choisie remplit le chemin', (tester) async {
      final pictures = FakePictureLibrary('pictures/gare_1.jpg');
      await pumpEditor(
        tester,
        realAdventure.findStage('gare')!,
        pictures: pictures,
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();

      // Le chemin est **relatif au dossier du contenu** : l'image y a ete
      // ecrite, et voyagera avec le JSON.
      expect(find.text('pictures/gare_1.jpg'), findsOneWidget);
      // Le fichier est nomme d'apres le lieu, pas d'apres la photo.
      expect(pictures.askedFor, 'gare');
    });

    testWidgets('une image de travail se signale comme telle', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.findStage('gare')!,
        pictures: FakePictureLibrary('pictures/gare_1.jpg'),
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();

      // C'est l'etat normal tant que le depot git ne l'a pas recue : une
      // mention, pas une alerte.
      expect(find.textContaining('Image de travail'), findsOneWidget);
      expect(
        find.textContaining('déposée avec le contenu'),
        findsOneWidget,
        reason: 'l\'image voyage avec le JSON, elle ne reste plus a part',
      );
    });

    testWidgets('renoncer laisse le chemin d\'avant', (tester) async {
      await pumpEditor(
        tester,
        realAdventure.startStage,
        pictures: FakePictureLibrary(null),
      );

      await tester.tap(find.text('Choisir une image'));
      await tester.pumpAndSettle();

      expect(find.text('pictures/Grisbie_plage2.jpg'), findsOneWidget);
    });
  });

  group('Ce que l\'ecran rend', () {
    testWidgets('le lieu renomme garde son identifiant', (tester) async {
      Stage? edited;
      await _withEditor(tester, realAdventure.findStage('gare')!,
          (result) => edited = result, (tester) async {
        await tester.enterText(
          find.byType(TextField).first,
          'La grande gare',
        );
        await save(tester);
      });

      // L'identifiant nait du nom puis s'en detache : le renommer casserait
      // toutes les destinations qui le citent.
      expect(edited!.locationName, 'La grande gare');
      expect(edited!.id, 'gare');
    });

    testWidgets('le recit saisi revient sur l\'etape', (tester) async {
      Stage? edited;
      await _withEditor(tester, realAdventure.findStage('gare')!,
          (result) => edited = result, (tester) async {
        await tester.enterText(
          find.byKey(const Key('onArrival')),
          'Le train siffle.',
        );
        await save(tester);
      });

      expect(edited!.narrative.onArrival, 'Le train siffle.');
    });

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
        await tester.enterText(find.byType(TextField).first, 'Perdu');
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
                  builder: (_) => StageEditorPage(stage: stage),
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

/// Une photothegue qui rend toujours la meme image, sans appareil ni greffon.
class FakePictureLibrary implements PictureLibrary {
  FakePictureLibrary(this.path);

  /// Ce que le selecteur rendra. Nul : l'auteur a referme sans choisir.
  final String? path;

  /// Le nom demande au dernier appel, pour verifier d'ou il vient.
  String? askedFor;

  @override
  Future<String?> pickPicture({required String baseName}) async {
    askedFor = baseName;
    return path;
  }
}
