import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/pages/adventure_opening_editor_page.dart';
import 'package:grisbie/ui/widgets/picture_field.dart';

/// Ce que l'editeur de page de garde dit d'une image, dimensions a l'appui.
///
/// Un conseil, jamais un refus : la page de garde montre l'image entiere,
/// quelles que soient ses proportions. Le format 3:2 est celui des ecrans de
/// lecture et des vignettes, et le suivre permet de reprendre l'image telle
/// quelle pour la vignette.
void main() {
  test('une image au format ne declenche aucune alerte', () {
    expect(describeOpeningPictureProblems(1536, 1024), isEmpty);
  });

  test('hors format, l image est montree entiere, et l editeur le dit', () {
    final warnings = describeOpeningPictureProblems(1672, 941);

    expect(warnings, hasLength(1));
    expect(warnings.single, contains('1672 × 941'));
    expect(warnings.single, contains('entière'));
    expect(warnings.single, contains('vignette'));
    expect(warnings.single, contains('1536 × 1024'));
  });

  test('une image trop petite sera floue, et l editeur le dit', () {
    final warnings = describeOpeningPictureProblems(600, 400);

    expect(warnings, hasLength(1));
    expect(warnings.single, contains('floue'));
    expect(warnings.single, contains('768 × 512'));
  });

  testWidgets('le champ d image de la page de garde regarde le format', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdventureOpeningEditorPage(adventureTitle: 'Essai'),
      ),
    );

    final field = tester.widget<PictureField>(find.byType(PictureField));
    expect(field.checkDimensions, same(describeOpeningPictureProblems));
  });
}
