import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:grisbie/application/praise_schedule.dart';

/// Ou la tete de Grisbie sort, au bord d'une boite, dans la scene.
///
/// **Sur le coin haut de la boite tourne vers le centre**, la bulle plus loin
/// encore vers le centre : une boite a gauche la montre a son coin droit, une
/// boite a droite a son coin gauche. L'oeil de l'enfant est deja sur la
/// boite, et rien ne sort de l'ecran. Fonction pure, eprouvee sans ecran.
class PraisePlacement {
  const PraisePlacement({
    required this.headCenter,
    required this.headSize,
    required this.bubbleOnLeft,
  });

  /// Le centre de la tete, dans le repere de la scene.
  final Offset headCenter;

  /// Le cote de la tete, en points.
  final double headSize;

  /// Vrai quand la bulle se pose a gauche de la tete.
  final bool bubbleOnLeft;

  static PraisePlacement compute({required Rect zone, required Size scene}) {
    final headSize = (scene.shortestSide * 0.2).clamp(56.0, 96.0);
    final half = headSize / 2;
    final towardLeft = zone.center.dx > scene.width / 2;
    final corner = towardLeft ? zone.topLeft : zone.topRight;

    return PraisePlacement(
      headCenter: Offset(
        corner.dx.clamp(half, math.max(half, scene.width - half)),
        corner.dy.clamp(half, math.max(half, scene.height - half)),
      ),
      headSize: headSize,
      bubbleOnLeft: towardLeft,
    );
  }
}

/// La petite recompense d'un mot bien place : la tete de Grisbie sort d'un
/// coup au bord de la boite, avec parfois un mot dans une bulle, puis
/// s'efface en remontant.
///
/// **Elle ne prend aucun toucher** : l'enfant peut deja saisir le mot
/// suivant. Ce qu'elle montre est decide par [PraiseSchedule] ; ici, rien
/// que l'animation. Rend la main par [onFinished].
class PraisePop extends StatefulWidget {
  const PraisePop({
    required this.praise,
    required this.zone,
    required this.onFinished,
    super.key,
  });

  /// Les tetes de Grisbie, en rotation : des elements du jeu, pas du
  /// contenu.
  static const List<String> headAssets = <String>[
    'assets/admiratif.webp',
    'assets/clindoeil.webp',
  ];

  /// La tete seule : un « oui » en un clin d'oeil.
  static const Duration headOnlyDuration = Duration(milliseconds: 600);

  /// Avec un mot : le temps de le lire.
  static const Duration withCommentDuration = Duration(milliseconds: 1100);

  final Praise praise;

  /// Le cadre de la boite qui vient de recevoir le mot, dans la scene.
  final Rect zone;

  final VoidCallback onFinished;

  @override
  State<PraisePop> createState() => _PraisePopState();
}

class _PraisePopState extends State<PraisePop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.praise.comment == null
        ? PraisePop.headOnlyDuration
        : PraisePop.withCommentDuration,
  )
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    })
    ..forward();

  /// La sortie, avec un leger rebond.
  late final Animation<double> _appear = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
  );

  /// L'effacement, en fin de course.
  late final Animation<double> _vanish = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.65, 1, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final placement = PraisePlacement.compute(
            zone: widget.zone,
            scene: constraints.biggest,
          );
          final comment = widget.praise.comment;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final rise = -12 * _vanish.value;
              final opacity = (1 - _vanish.value).clamp(0.0, 1.0);
              final scale = _appear.value;
              final center = placement.headCenter + Offset(0, rise);
              final size = placement.headSize;

              return Opacity(
                opacity: opacity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (comment != null)
                      Positioned(
                        top: center.dy - size * 0.45,
                        left: placement.bubbleOnLeft
                            ? null
                            : center.dx + size * 0.45,
                        right: placement.bubbleOnLeft
                            ? constraints.maxWidth - center.dx + size * 0.45
                            : null,
                        child: Transform.scale(
                          scale: scale,
                          alignment: placement.bubbleOnLeft
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _Bubble(comment),
                        ),
                      ),
                    Positioned(
                      left: center.dx - size / 2,
                      top: center.dy - size / 2,
                      width: size,
                      height: size,
                      child: Transform.rotate(
                        // Un petit balancement a la sortie.
                        angle: (1 - scale) * 0.3,
                        child: Transform.scale(
                          scale: scale,
                          child: Image.asset(
                            widget.praise.head,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// La bulle du mot d'encouragement.
class _Bubble extends StatelessWidget {
  const _Bubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }
}
