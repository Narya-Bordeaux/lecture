import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/picture_orientation.dart';

/// Dans la galerie, les vignettes sont recadrees au carre : l'orientation
/// reelle de l'image ne se voit plus, et c'est elle qui la classe ici.
void main() {
  test('une image plus large que haute est horizontale', () {
    expect(
      PictureOrientation.of(width: 1536, height: 1024),
      PictureOrientation.landscape,
    );
  });

  test('une image plus haute que large est verticale', () {
    expect(
      PictureOrientation.of(width: 1024, height: 1536),
      PictureOrientation.portrait,
    );
  });

  test('une image a peu pres carree est carree', () {
    expect(
      PictureOrientation.of(width: 1000, height: 1000),
      PictureOrientation.square,
    );
    expect(
      PictureOrientation.of(width: 1040, height: 1000),
      PictureOrientation.square,
    );
    expect(
      PictureOrientation.of(width: 1000, height: 1040),
      PictureOrientation.square,
    );
  });

  test('au-dela de la tolerance, l orientation se dit', () {
    expect(
      PictureOrientation.of(width: 1060, height: 1000),
      PictureOrientation.landscape,
    );
    expect(
      PictureOrientation.of(width: 1000, height: 1060),
      PictureOrientation.portrait,
    );
  });
}
