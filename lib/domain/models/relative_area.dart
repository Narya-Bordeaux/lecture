/// Une region de l'illustration, exprimee en fractions de sa largeur et de sa
/// hauteur (0 a 1).
///
/// Les coordonnees sont relatives et non en pixels : la meme zone reste posee
/// sur le bus quelle que soit la taille de l'ecran. C'est une donnee de
/// contenu — ou se trouve tel element dans telle illustration — et non une
/// regle de jeu, mais elle voyage avec le contenu pour qu'une aventure tienne
/// dans un seul fichier relisible.
class RelativeArea {
  const RelativeArea({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  })  : assert(left >= 0 && left <= 1, 'left doit rester entre 0 et 1'),
        assert(top >= 0 && top <= 1, 'top doit rester entre 0 et 1'),
        assert(width > 0 && width <= 1, 'width doit rester entre 0 et 1'),
        assert(height > 0 && height <= 1, 'height doit rester entre 0 et 1');

  factory RelativeArea.fromJson(Map<String, dynamic> json) {
    return RelativeArea(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  /// Vrai si la zone deborde de l'illustration.
  bool get overflows => right > 1 || bottom > 1;

  /// Vrai si les deux zones se chevauchent, ne serait-ce qu'en partie.
  ///
  /// Deux zones qui se recouvrent rendraient le depot ambigu : l'enfant ne
  /// saurait pas laquelle il vise.
  bool overlaps(RelativeArea other) {
    return left < other.right &&
        other.left < right &&
        top < other.bottom &&
        other.top < bottom;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is RelativeArea &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() =>
      'RelativeArea($left, $top, ${width}x$height)';
}
