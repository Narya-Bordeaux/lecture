import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/ui/pages/adventure_page.dart';
import 'package:grisbie/ui/pages/narration_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

import '../support/disk_content.dart';
import '../support/stage_builders.dart' as build;

/// L'ecran de lecture du jeu : un titre facultatif, l'image, puis le texte.
///
/// Un seul, pour la page de garde comme pour la fin : deux mises en page
/// finiraient par dire la meme chose differemment. La fin n'avait pas
/// d'image — l'auteur en posait, et elles ne paraissaient jamais.

Finder imageAt(String path) => find.byWidgetPredicate(
      (widget) => widget is ContentImage && widget.path == path,
    );

Future<void> pumpNarration(
  WidgetTester tester, {
  String? title,
  String? imagePath,
  String text = 'Le texte.',
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: NarrationPage(
        title: title,
        imagePath: imagePath,
        text: text,
        actionLabel: 'Suite',
        onAction: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le titre en haut, l\'image, puis le texte', (tester) async {
    await pumpNarration(
      tester,
      title: 'Le titre',
      imagePath: 'pictures/plage.jpg',
    );

    final title = tester.getRect(find.text('Le titre'));
    final image = tester.getRect(imageAt('pictures/plage.jpg'));
    final text = tester.getRect(find.text('Le texte.'));
    expect(title.bottom, lessThanOrEqualTo(image.top));
    expect(image.bottom, lessThanOrEqualTo(text.top));
  });

  testWidgets('sans titre, l\'ecran commence par l\'image', (tester) async {
    await pumpNarration(tester, imagePath: 'pictures/plage.jpg');

    expect(imageAt('pictures/plage.jpg'), findsOneWidget);
    expect(find.text('Le texte.'), findsOneWidget);
    // Seuls le texte et le bouton portent des mots.
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('sans image, le texte suit le titre', (tester) async {
    await pumpNarration(tester, title: 'Le titre');

    expect(find.byType(ContentImage), findsNothing);
    expect(find.text('Le titre'), findsOneWidget);
  });

  group('La fin d\'une aventure', () {
    testWidgets('montre son illustration', (tester) async {
      // Le defaut vu par l'auteur : une fin illustree s'affichait sans image.
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final adventure = Adventure(
        id: 'essai',
        title: 'Essai',
        coverAsset: 'pictures/vignette.jpg',
        startStageId: 'plage',
        stages: <String, Stage>{
          // Une aventure reduite a sa fin : c'est elle qu'on eprouve.
          'plage': build.ending(id: 'plage', location: 'La plage').copyWith(
                backgroundAsset: 'pictures/plage.jpg',
                narrative: const Narrative(onArrival: 'La mer est là !'),
              ),
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

      expect(find.text('La plage'), findsOneWidget);
      expect(imageAt('pictures/plage.jpg'), findsOneWidget);
      expect(find.text('La mer est là !'), findsOneWidget);
      expect(find.text(UiStringsFr.startOver), findsOneWidget);
    });
  });
}
