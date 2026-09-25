/// Une place occupee sur l'arc de la roue des aventures.
class WheelSlot {
  const WheelSlot({
    required this.itemIndex,
    required this.position,
    required this.visibility,
  });

  /// L'aventure montree, par son rang dans le sommaire.
  final int itemIndex;

  /// La place sur l'arc, en crans, comptee depuis le centre de l'arc :
  /// negative a gauche, positive a droite. Au repos, trois aventures
  /// occupent -1, 0 et 1.
  final double position;

  /// De 0 a 1 : entierement visible sur l'arc, ou en train d'y entrer ou
  /// d'en sortir. Une place invisible n'est pas rendue du tout.
  final double visibility;
}

/// La roue des aventures de l'accueil : quelle aventure occupe quelle place.
///
/// Trois places sur l'arc. Au-dela de trois aventures, la roue tourne et
/// **boucle** : apres la derniere revient la premiere. A trois ou moins elle
/// ne tourne pas, et les aventures se centrent sur l'arc.
///
/// La rotation se compte en crans, un cran faisant passer une aventure d'une
/// place a la suivante. Elle augmente quand les aventures glissent vers la
/// gauche, et n'est jamais ramenee dans un intervalle : une animation de 4,8
/// vers 5 ne doit pas sauter en arriere.
///
/// Sans dependance a Flutter : l'accueil traduit le geste en crans et
/// affiche les places que la roue rend.
class AdventureWheel {
  AdventureWheel({
    required this.itemCount,
    this.slotCount = defaultSlotCount,
    double rotation = 0,
  }) : rotation = itemCount > slotCount ? rotation : 0;

  /// Le nombre de vignettes posees sur l'arc.
  ///
  /// Quatre sur le croquis de l'auteur, trois depuis que les vignettes sont
  /// en largeur (3:2, voir `CoverFormat`) : quatre ne tenaient plus sur un
  /// telephone sans devenir trop petites pour un doigt.
  static const int defaultSlotCount = 3;

  /// Le temps pendant lequel un geste lance continue de faire tourner la
  /// roue, en secondes : il decide jusqu'ou elle file avant de se caler.
  static const double flingDuration = 0.25;

  final int itemCount;
  final int slotCount;
  final double rotation;

  /// La roue ne tourne que si elle a plus d'aventures que de places.
  bool get turns => itemCount > slotCount;

  /// La roue tournee de [slots] crans. Sans effet si elle ne tourne pas.
  AdventureWheel turnedBy(double slots) => _withRotation(rotation + slots);

  /// La roue calee sur le cran le plus proche, au lacher du doigt.
  ///
  /// [velocity], en crans par seconde, porte la roue plus loin quand le
  /// geste est lance : sans quoi un geste vif reviendrait en arriere.
  AdventureWheel settled({double velocity = 0}) =>
      _withRotation((rotation + velocity * flingDuration).roundToDouble());

  /// Les places occupees, de gauche a droite.
  List<WheelSlot> get slots {
    if (itemCount == 0) return const <WheelSlot>[];
    if (!turns) {
      final middle = (itemCount - 1) / 2;
      return <WheelSlot>[
        for (var index = 0; index < itemCount; index++)
          WheelSlot(itemIndex: index, position: index - middle, visibility: 1),
      ];
    }

    final first = rotation.floor();
    final shift = rotation - first;
    final half = (slotCount - 1) / 2;
    final result = <WheelSlot>[];
    // Une place de plus de chaque cote : celles qui entrent et qui sortent.
    for (var rank = -1; rank <= slotCount; rank++) {
      final position = rank - half - shift;
      final visibility = (1 - (position.abs() - half)).clamp(0.0, 1.0);
      if (visibility == 0) continue;
      result.add(WheelSlot(
        itemIndex: (first + rank) % itemCount,
        position: position,
        visibility: visibility,
      ));
    }
    return result;
  }

  AdventureWheel _withRotation(double value) => AdventureWheel(
        itemCount: itemCount,
        slotCount: slotCount,
        rotation: value,
      );
}
