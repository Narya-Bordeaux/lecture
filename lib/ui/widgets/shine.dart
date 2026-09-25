import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fait passer un reflet dore sur son enfant, sur commande.
///
/// Sert quand la derniere boite a trouve sa place : le reflet parcourt les
/// mots l'un apres l'autre, dans l'ordre de lecture, et chacun grossit un
/// instant a son passage. Il dit a l'enfant : « a toi, maintenant ».
class Shine extends StatefulWidget {
  const Shine({required this.child, this.borderRadius = 12, super.key});

  final Widget child;

  /// L'arrondi de l'etiquette, que le reflet ne deborde pas.
  final double borderRadius;

  @override
  State<Shine> createState() => ShineState();
}

class ShineState extends State<Shine> with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 450);

  /// De combien l'etiquette grossit au plus fort du reflet.
  static const double _growth = 0.12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: duration,
  );

  Timer? _delay;

  /// Vrai du declenchement a la fin du reflet, attente comprise.
  bool get isShining => _delay != null || _controller.isAnimating;

  /// Fait passer le reflet apres [delay] — ce qui echelonne les etiquettes.
  void play({Duration delay = Duration.zero}) {
    _delay?.cancel();
    _delay = Timer(delay, () {
      _delay = null;
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // La structure ne change jamais, reflet ou non : sans quoi
        // l'etiquette serait reconstruite, et un geste commence pendant le
        // reflet s'interromprait.
        final active = _controller.isAnimating;
        final progress = _controller.value;
        final swell = active ? math.sin(progress * math.pi) : 0.0;
        // La bande lumineuse traverse l'etiquette en diagonale, d'un peu
        // avant le bord gauche a un peu apres le bord droit.
        final centre = -0.3 + 1.6 * progress;

        return Transform.scale(
          scale: 1 + _growth * swell,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFFFFC928).withValues(alpha: 0.9 * swell),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                child!,
                if (active)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: const <Color>[
                                Color(0x00FFD54F),
                                Color(0xB3FFD54F),
                                Color(0x00FFD54F),
                              ],
                              stops: <double>[
                                (centre - 0.25).clamp(0.0, 1.0),
                                centre.clamp(0.0, 1.0),
                                (centre + 0.25).clamp(0.0, 1.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
