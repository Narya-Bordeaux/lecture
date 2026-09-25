import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/pages/cover_editor_page.dart';

/// Ce que l'editeur de vignette dit d'une image, dimensions a l'appui.
void main() {
  test('une image au format ne declenche aucune alerte', () {
    expect(describeCoverProblems(1536, 1024), isEmpty);
  });

  test('un decor en hauteur sera recadre, et l editeur le dit', () {
    final warnings = describeCoverProblems(1024, 1536);

    expect(warnings, hasLength(1));
    expect(warnings.single, contains('1024 × 1536'));
    expect(warnings.single, contains('recadrée'));
    expect(warnings.single, contains('1536 × 1024'));
  });

  test('une image trop petite sera floue, et l editeur le dit', () {
    final warnings = describeCoverProblems(600, 400);

    expect(warnings, hasLength(1));
    expect(warnings.single, contains('floue'));
    expect(warnings.single, contains('768 × 512'));
  });
}
