import 'package:reading_game/domain/models/relative_area.dart';

/// Le coin saisi lors d'un redimensionnement.
///
/// Le coin oppose reste fixe : c'est le geste attendu, et il evite qu'une zone
/// se deplace pendant qu'on la retaille.
enum AreaCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Le calage des zones de depot d'une etape, en fractions de l'illustration.
///
/// Toute la geometrie du mode auteur vit ici : deplacer, redimensionner,
/// contraindre aux bords, garder une cible atteignable au doigt, detecter un
/// chevauchement et produire le JSON a recopier dans l'aventure.
///
/// Volontairement sans dependance a Flutter : la page d'edition ne fait que
/// traduire des gestes en fractions et afficher ce que ce moteur renvoie. Les
/// cas delicats — un coin tire au-dela du bord, un arrondi qui fait deborder
/// une zone — s'eprouvent ainsi sans appareil.
class AreaEditor {
  AreaEditor({
    required Map<String, RelativeArea> areas,
    required this.minimumWidth,
    required this.minimumHeight,
    this.decimals = 2,
  }) : _areas = Map<String, RelativeArea>.of(areas);

  final Map<String, RelativeArea> _areas;

  /// Largeur et hauteur minimales, en fractions de l'illustration.
  ///
  /// La page les calcule a partir de la taille reellement affichee, pour que
  /// la zone reste atteignable par un doigt d'enfant quel que soit l'appareil.
  final double minimumWidth;
  final double minimumHeight;

  /// Nombre de decimales conservees a l'export.
  final int decimals;

  /// Les zones telles qu'elles sont manipulees, en pleine precision.
  Map<String, RelativeArea> get areas =>
      Map<String, RelativeArea>.unmodifiable(_areas);

  /// Les zones telles qu'elles seront ecrites dans le fichier d'aventure.
  ///
  /// C'est sur elles que portent les controles : signaler un chevauchement sur
  /// une valeur exacte que l'auteur n'ecrira jamais n'aurait aucun sens.
  Map<String, RelativeArea> get roundedAreas {
    return Map<String, RelativeArea>.unmodifiable(
      _areas.map(
        (familyId, area) => MapEntry<String, RelativeArea>(
          familyId,
          _round(area),
        ),
      ),
    );
  }

  /// Les familles dont la zone en recouvre une autre.
  ///
  /// Les deux fautives sont nommees : l'auteur doit savoir laquelle deplacer.
  Set<String> get overlappingFamilyIds {
    final rounded = roundedAreas;
    final entries = rounded.entries.toList(growable: false);
    final guilty = <String>{};

    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        if (entries[i].value.overlaps(entries[j].value)) {
          guilty.add(entries[i].key);
          guilty.add(entries[j].key);
        }
      }
    }

    return guilty;
  }

  /// Deplace la zone de [familyId] sans changer sa taille.
  void move(String familyId, {required double dx, required double dy}) {
    final area = _require(familyId);

    // La zone glisse jusqu'au bord et s'y arrete : poussee au-dela, elle
    // emporterait sa cible hors de l'illustration.
    final left = _clamp(area.left + dx, 0, 1 - area.width);
    final top = _clamp(area.top + dy, 0, 1 - area.height);

    _areas[familyId] = RelativeArea(
      left: left,
      top: top,
      width: area.width,
      height: area.height,
    );
  }

  /// Retaille la zone de [familyId] en tirant [corner], l'oppose restant fixe.
  void resize(
    String familyId, {
    required AreaCorner corner,
    required double dx,
    required double dy,
  }) {
    final area = _require(familyId);

    final movesLeftEdge =
        corner == AreaCorner.topLeft || corner == AreaCorner.bottomLeft;
    final movesTopEdge =
        corner == AreaCorner.topLeft || corner == AreaCorner.topRight;

    var left = area.left;
    var right = area.right;
    var top = area.top;
    var bottom = area.bottom;

    if (movesLeftEdge) {
      // Le bord gauche ne franchit ni l'illustration, ni la largeur minimale.
      left = _clamp(left + dx, 0, right - minimumWidth);
    } else {
      right = _clamp(right + dx, left + minimumWidth, 1);
    }

    if (movesTopEdge) {
      top = _clamp(top + dy, 0, bottom - minimumHeight);
    } else {
      bottom = _clamp(bottom + dy, top + minimumHeight, 1);
    }

    _areas[familyId] = RelativeArea(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  /// Remplace le calage d'une famille, par exemple pour revenir en arriere.
  void replace(String familyId, RelativeArea area) {
    _require(familyId);
    _areas[familyId] = area;
  }

  /// Le JSON des zones, pret a etre recopie dans le fichier d'aventure.
  ///
  /// Chaque famille est nommee, pour que l'auteur sache ou coller quoi.
  String export() {
    final rounded = roundedAreas;
    final lines = rounded.entries.map((entry) {
      final area = entry.value;
      return '"${entry.key}": { '
          '"left": ${_format(area.left)}, '
          '"top": ${_format(area.top)}, '
          '"width": ${_format(area.width)}, '
          '"height": ${_format(area.height)} }';
    });

    return lines.join(',\n');
  }

  RelativeArea _require(String familyId) {
    final area = _areas[familyId];
    if (area == null) {
      throw ArgumentError.value(
        familyId,
        'familyId',
        'Famille absente du calage en cours',
      );
    }
    return area;
  }

  /// Arrondit la zone, puis la ramene dans l'illustration si besoin.
  ///
  /// Arrondir `left` et `width` separement peut faire depasser leur somme d'un
  /// centieme. Sans cette reprise, le jeu refuserait de charger le contenu que
  /// l'auteur vient tout juste d'exporter.
  RelativeArea _round(RelativeArea area) {
    var left = _roundValue(area.left);
    var top = _roundValue(area.top);
    var width = _roundValue(area.width);
    var height = _roundValue(area.height);

    final step = _step;
    if (width < step) width = step;
    if (height < step) height = step;
    if (left + width > 1) left = _roundValue(1 - width);
    if (top + height > 1) top = _roundValue(1 - height);
    if (left < 0) left = 0;
    if (top < 0) top = 0;

    return RelativeArea(left: left, top: top, width: width, height: height);
  }

  /// Le plus petit ecart representable au nombre de decimales retenu.
  double get _step => 1 / _scale;

  double get _scale {
    var scale = 1.0;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    return scale;
  }

  double _roundValue(double value) => (value * _scale).round() / _scale;

  String _format(double value) => value.toStringAsFixed(decimals);

  static double _clamp(double value, double lower, double upper) {
    if (upper < lower) return lower;
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
  }
}
