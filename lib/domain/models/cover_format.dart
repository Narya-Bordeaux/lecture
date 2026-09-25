/// Ce qui ne va pas dans une image de vignette.
enum CoverProblem {
  /// Pas en 3:2 : elle sera recadree au centre pour remplir la carte.
  wrongProportions,

  /// Plus petite que le minimum utile : elle sera floue sur un telephone.
  tooSmall,
}

/// Le format de la vignette d'une aventure, celle de la roue de l'accueil.
///
/// **3:2 en largeur**, le format des illustrations de narration : l'auteur
/// peut reprendre celle de la page de garde telle quelle. Les cartes de la
/// roue ont exactement ces proportions.
///
/// Une image hors format n'est pas refusee : elle est recadree, et l'outil le
/// dit. C'est le seul endroit du jeu ou une image est recadree — aucune zone
/// de depot n'est calee sur une vignette.
class CoverFormat {
  const CoverFormat._();

  /// Largeur sur hauteur.
  static const double aspectRatio = 3 / 2;

  /// La taille conseillee, celle des illustrations de narration.
  static const int recommendedWidth = 1536;
  static const int recommendedHeight = 1024;

  /// En dessous, l'image est floue : une vignette occupe environ un tiers de
  /// la largeur d'un telephone, soit 400 a 500 pixels reels.
  static const int minimumWidth = 768;
  static const int minimumHeight = 512;

  /// L'ecart de proportions tolere, en fraction : une image a un ou deux
  /// pixels pres ne merite pas d'alerte.
  static const double aspectTolerance = 0.02;

  /// Les defauts d'une image de ces dimensions, en pixels. Vide, elle convient.
  static List<CoverProblem> check({required int width, required int height}) {
    final ratio = width / height;
    return <CoverProblem>[
      if ((ratio / aspectRatio - 1).abs() > aspectTolerance)
        CoverProblem.wrongProportions,
      if (width < minimumWidth || height < minimumHeight) CoverProblem.tooSmall,
    ];
  }
}
