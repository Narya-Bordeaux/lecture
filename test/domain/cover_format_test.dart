import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/cover_format.dart';

void main() {
  group('Le format de la vignette', () {
    test('3:2 en largeur, a la taille conseillee : rien a dire', () {
      expect(CoverFormat.check(width: 1536, height: 1024), isEmpty);
    });

    test('la taille minimale suffit', () {
      expect(CoverFormat.check(width: 768, height: 512), isEmpty);
    });

    test('un ou deux pixels d ecart ne declenchent rien', () {
      expect(CoverFormat.check(width: 1535, height: 1024), isEmpty);
      expect(CoverFormat.check(width: 1536, height: 1022), isEmpty);
    });

    test('un decor en hauteur n a pas les bonnes proportions', () {
      expect(
        CoverFormat.check(width: 1024, height: 1536),
        <CoverProblem>[CoverProblem.wrongProportions],
      );
    });

    test('un carre non plus', () {
      expect(
        CoverFormat.check(width: 1000, height: 1000),
        <CoverProblem>[CoverProblem.wrongProportions],
      );
    });

    test('une image trop petite sera floue', () {
      expect(
        CoverFormat.check(width: 600, height: 400),
        <CoverProblem>[CoverProblem.tooSmall],
      );
    });

    test('les deux defauts se cumulent', () {
      expect(
        CoverFormat.check(width: 300, height: 300),
        <CoverProblem>[CoverProblem.wrongProportions, CoverProblem.tooSmall],
      );
    });
  });
}
