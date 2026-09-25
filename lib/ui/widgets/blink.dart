import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fait clignoter le contour de son enfant, sur commande.
///
/// Sert quand un mot est lache hors de toute boite : les boites s'allument
/// deux fois, brievement, pour dire ou viser. Ce n'est pas un reproche — le
/// mot n'a pas ete refuse, il n'a simplement atteint aucune boite.
class Blink extends StatefulWidget {
  const Blink({required this.child, this.borderRadius = 14, super.key});

  final Widget child;

  /// L'arrondi du cadre que le clignotement epouse.
  final double borderRadius;

  @override
  State<Blink> createState() => BlinkState();
}

class BlinkState extends State<Blink> with SingleTickerProviderStateMixin {
  static const Duration duration = Duration(milliseconds: 800);
  static const int _pulses = 2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: duration,
  );

  /// Vrai pendant le clignotement.
  bool get isBlinking => _controller.isAnimating;

  /// Declenche un clignotement, en repartant du debut si un est en cours.
  void blink() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_controller.isAnimating) return const SizedBox.shrink();
                // Deux bosses : l'eclat monte et retombe deux fois.
                final glow = math
                    .sin(_controller.value * _pulses * math.pi)
                    .abs();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45 * glow),
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: glow),
                      width: 4,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8 * glow),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
