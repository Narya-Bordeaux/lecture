import 'dart:math';

import 'package:grisbie/application/wheel_arc.dart';
import 'package:grisbie/domain/models/cover_format.dart';

/// La mise en page de l'accueil du jeu, calculee pour un ecran donne.
///
/// Le croquis de l'auteur s'organise autour du logo : le titre s'arrondit
/// au-dessus sur deux lignes, les vignettes pendent en dessous le long d'un
/// arc, penchees comme des rayons.
///
/// **L'arc n'est pas centre sur le logo**, et c'est voulu. Trois vignettes en
/// largeur occupent presque toute la largeur d'un telephone ; pour les
/// ecarter autour du centre du logo, il fallait un rayon si grand qu'un vide
/// de plusieurs centaines de points s'ouvrait entre le logo et les cartes.
/// L'arc passe donc juste sous le logo, avec une courbure fixe
/// ([stepDegrees]), et son centre se trouve plus haut, dans l'axe.
///
/// Fonction pure, en points logiques : l'ecran ne fait que poser ce qu'elle
/// rend, et les cas delicats — un petit telephone, un navigateur couche —
/// s'eprouvent sans appareil.
class HomeLayout {
  const HomeLayout._({
    required this.width,
    required this.height,
    required this.logoCenterX,
    required this.logoCenterY,
    required this.logoWidth,
    required this.titleFontSize,
    required this.cardWidth,
    required this.captionFontSize,
    required this.arc,
  });

  /// La marge tenue le long des bords.
  static const double margin = 16;

  /// En dessous, une vignette devient trop petite a viser et a regarder.
  static const double minimumCardWidth = 72;

  /// Au-dessus, une vignette ecrase le logo sur un grand ecran.
  static const double maximumCardWidth = 240;

  /// L'espace tenu entre deux vignettes voisines, et sous le logo.
  static const double cardSpacing = 10;

  /// L'espace entre la vignette et son titre.
  static const double captionGap = 4;

  /// Le titre d'une aventure tient sur deux lignes au plus.
  static const int captionLines = 2;

  /// L'angle entre deux places voisines. Assez pour que les vignettes de
  /// cote penchent comme sur le croquis ; davantage, elles mangeraient la
  /// largeur qu'il faut pour trois.
  static const double stepDegrees = 20;

  /// L'ovale du logo, hauteur sur largeur : en hauteur, comme sur le croquis.
  static const double logoAspect = 1.15;

  /// La part de la largeur que le logo prend quand la hauteur le permet.
  static const double logoShare = 0.6;

  /// Le logo ne prend jamais plus que cette part de la hauteur : sur un
  /// ecran couche, les vignettes n'auraient plus de place.
  static const double logoHeightShare = 0.45;

  final double width;
  final double height;

  /// Le logo.
  final double logoCenterX;
  final double logoCenterY;
  final double logoWidth;
  double get logoHeight => logoWidth * logoAspect;

  /// Le titre du jeu, en deux lignes arrondies autour du logo.
  final double titleFontSize;

  /// Le cercle de la ligne du bas (« de Grisbie »), a hauteur de ligne de
  /// base, centre sur le logo.
  double get titleInnerRadius => _titleInnerRadius(logoWidth, titleFontSize);

  /// Le cercle de la ligne du haut (« Les Aventures »).
  double get titleOuterRadius => titleInnerRadius + titleFontSize * 1.25;

  /// Une vignette, au format 3:2 de `CoverFormat`.
  final double cardWidth;
  double get cardHeight => cardWidth / CoverFormat.aspectRatio;

  /// Le titre d'aventure sous la vignette.
  final double captionFontSize;
  double get captionHeight => captionFontSize * 1.25 * captionLines;

  /// La vignette et son titre, ce que la roue fait tourner.
  double get elementHeight => cardHeight + captionGap + captionHeight;

  /// Le cercle des vignettes : `arc.place` donne le centre de chaque
  /// vignette, titre compris.
  final WheelArc arc;

  /// La longueur d'arc entre deux places : ce que le doigt doit parcourir
  /// pour faire tourner la roue d'un cran.
  double get slotSpacing => arc.radius * arc.stepAngle;

  static double _titleInnerRadius(double logoWidth, double fontSize) =>
      logoWidth * logoAspect / 2 + fontSize * 0.5;

  static double _titleFontSize(double logoWidth) =>
      (logoWidth * 0.17).clamp(22.0, 48.0);

  static double _captionFontSize(double cardWidth) =>
      (cardWidth * 0.13).clamp(13.0, 20.0);

  static double _elementHeight(double cardWidth) =>
      cardWidth / CoverFormat.aspectRatio +
      captionGap +
      _captionFontSize(cardWidth) * 1.25 * captionLines;

  static double get _step => stepDegrees * pi / 180;

  /// Le rayon ou deux vignettes voisines se touchent presque par leur bord
  /// interieur, le plus serre.
  static double _radiusFor(double cardWidth) {
    final inner = (cardWidth + cardSpacing) / (2 * sin(_step / 2));
    return inner + _elementHeight(cardWidth) / 2;
  }

  /// La vignette de cote, penchee : jusqu'ou elle s'etend a l'horizontale
  /// depuis l'axe.
  static double _reach(double cardWidth) {
    final radius = _radiusFor(cardWidth);
    return radius * sin(_step) +
        cardWidth / 2 * cos(_step) +
        _elementHeight(cardWidth) / 2 * sin(_step);
  }

  /// La plus grande vignette dont trois tiennent en largeur.
  static double _widestCard(double width) {
    var cardWidth = min(width * 0.3, maximumCardWidth).floorToDouble();
    while (cardWidth > minimumCardWidth &&
        _reach(cardWidth) > width / 2 - margin) {
      cardWidth -= 1;
    }
    return cardWidth;
  }

  /// La hauteur qu'il faut : titre, logo, vignettes, sans rien entre.
  static double _neededHeight(double logoWidth, double cardWidth) {
    final fontSize = _titleFontSize(logoWidth);
    final titleTop = fontSize + _titleInnerRadius(logoWidth, fontSize) +
        fontSize * 1.25 - logoWidth * logoAspect / 2;
    return 2 * margin +
        titleTop +
        logoWidth * logoAspect +
        cardSpacing +
        _elementHeight(cardWidth);
  }

  static HomeLayout compute({required double width, required double height}) {
    var cardWidth = _widestCard(width);
    var logoWidth = min(width * logoShare, height * logoHeightShare / logoAspect);
    final smallestLogo = min(width, height) * 0.25;

    // Le logo cede d'abord, puis les vignettes : elles sont a toucher.
    while (_neededHeight(logoWidth, cardWidth) > height) {
      if (logoWidth > smallestLogo) {
        logoWidth -= 2;
      } else if (cardWidth > minimumCardWidth) {
        cardWidth -= 2;
      } else {
        break;
      }
    }

    // La hauteur qui reste, partagee en trois : au-dessus du titre, entre le
    // logo et les vignettes, et sous elles. Tout serre en haut laissait un
    // grand vide en bas des telephones allonges.
    final slack = max(0.0, height - _neededHeight(logoWidth, cardWidth)) / 3;

    final fontSize = _titleFontSize(logoWidth);
    final outerRadius =
        _titleInnerRadius(logoWidth, fontSize) + fontSize * 1.25;
    final logoCenterY = margin + slack + fontSize + outerRadius;
    final logoBottom = logoCenterY + logoWidth * logoAspect / 2;
    final centerCardY =
        logoBottom + cardSpacing + slack + _elementHeight(cardWidth) / 2;
    final radius = _radiusFor(cardWidth);

    return HomeLayout._(
      width: width,
      height: height,
      logoCenterX: width / 2,
      logoCenterY: logoCenterY,
      logoWidth: logoWidth,
      titleFontSize: fontSize,
      cardWidth: cardWidth,
      captionFontSize: _captionFontSize(cardWidth),
      arc: WheelArc(
        centerX: width / 2,
        centerY: centerCardY - radius,
        radius: radius,
        stepAngle: _step,
      ),
    );
  }
}
