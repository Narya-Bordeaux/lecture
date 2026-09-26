import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/pages/picture_chooser_page.dart';

/// Le choix d'une image s'ouvre sur le dossier de l'aventure en cours
/// (`pictures/<id>/`), et montre les autres a la demande (option B de
/// l'auteur) : tout dans une seule grille devenait ingerable des la seconde
/// aventure.

class _Catalog implements PictureCatalog {
  _Catalog(this.pictures);

  final List<String> pictures;

  @override
  Future<List<String>> listPictures() async => pictures;
}

final _catalog = _Catalog(<String>[
  'pictures/bonjour.jpg',
  'pictures/foret/arbre.jpg',
  'pictures/plage/maison.jpg',
  'pictures/plage/sable.jpg',
]);

Future<void> pumpChooser(
  WidgetTester tester, {
  PictureCatalog? catalog,
  String? adventureId,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: PictureChooserPage(
        catalog: catalog ?? _catalog,
        adventureId: adventureId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('s ouvre sur les images de l aventure, et elles seules', (
    tester,
  ) async {
    await pumpChooser(tester, adventureId: 'plage');

    expect(find.text('maison.jpg'), findsOneWidget);
    expect(find.text('sable.jpg'), findsOneWidget);
    expect(find.text('arbre.jpg'), findsNothing);
    expect(find.text('bonjour.jpg'), findsNothing);
  });

  testWidgets('toutes les images se montrent a la demande, par dossier', (
    tester,
  ) async {
    await pumpChooser(tester, adventureId: 'plage');

    await tester.tap(find.text(PictureChooserPage.showAllLabel));
    await tester.pumpAndSettle();

    expect(find.text('arbre.jpg'), findsOneWidget);
    expect(find.text('bonjour.jpg'), findsOneWidget);
    expect(find.text('foret'), findsOneWidget);
    expect(find.text('plage'), findsOneWidget);
    expect(find.text(PictureChooserPage.rootLabel), findsOneWidget);
  });

  testWidgets('et l on revient aux images de l aventure', (tester) async {
    await pumpChooser(tester, adventureId: 'plage');

    await tester.tap(find.text(PictureChooserPage.showAllLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PictureChooserPage.showAdventureLabel));
    await tester.pumpAndSettle();

    expect(find.text('arbre.jpg'), findsNothing);
    expect(find.text('maison.jpg'), findsOneWidget);
  });

  testWidgets('choisir rend le chemin complet, dossier compris', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await Navigator.of(context).push<String>(
                MaterialPageRoute<String>(
                  builder: (_) => PictureChooserPage(
                    catalog: _catalog,
                    adventureId: 'plage',
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

    await tester.tap(find.text('sable.jpg'));
    await tester.pumpAndSettle();

    expect(chosen, 'pictures/plage/sable.jpg');
  });

  testWidgets('sans dossier pour l aventure, il dit lequel creer, et montre '
      'tout', (tester) async {
    await pumpChooser(tester, adventureId: 'montagne');

    expect(
      find.textContaining('assets/content/pictures/montagne/'),
      findsOneWidget,
    );
    expect(find.textContaining('pubspec.yaml'), findsOneWidget);
    expect(find.text('maison.jpg'), findsOneWidget);
    expect(find.text('bonjour.jpg'), findsOneWidget);
    expect(find.text(PictureChooserPage.showAdventureLabel), findsNothing);
  });

  testWidgets('sans aventure, tout se montre par dossier', (tester) async {
    await pumpChooser(tester);

    expect(find.text('arbre.jpg'), findsOneWidget);
    expect(find.text('maison.jpg'), findsOneWidget);
    expect(find.text(PictureChooserPage.showAllLabel), findsNothing);
  });

  testWidgets('un depot vide dit ou verser les images', (tester) async {
    await pumpChooser(
      tester,
      catalog: _Catalog(const <String>[]),
      adventureId: 'plage',
    );

    expect(find.textContaining('assets/content/pictures/plage/'),
        findsOneWidget);
  });
}
