/// Le sens d'une image : plus large que haute, plus haute que large, ou
/// a peu pres carree.
///
/// Sert a la galerie de l'outil d'auteur, dont les vignettes sont recadrees
/// au carre : sans cela, une image verticale et une horizontale s'y
/// ressemblent.
enum PictureOrientation {
  landscape,
  portrait,
  square;

  /// L'ecart tolere entre largeur et hauteur, en fraction, pour qu'une image
  /// reste carree : a quelques pixels pres, elle se lit comme un carre.
  static const double squareTolerance = 0.05;

  /// Le sens d'une image de ces dimensions, en pixels.
  static PictureOrientation of({required int width, required int height}) {
    final ratio = width / height;
    if ((ratio - 1).abs() <= squareTolerance &&
        (1 / ratio - 1).abs() <= squareTolerance) {
      return PictureOrientation.square;
    }
    return ratio > 1
        ? PictureOrientation.landscape
        : PictureOrientation.portrait;
  }
}
