import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fait trembler brievement son enfant, sur commande.
///
/// Sert a signaler un mot mal place : l'etiquette revient a sa case et tremble
/// une fois. Le refus est ainsi immediat et lisible, sans marquer l'echec par
/// une couleur d'alerte — a 6 ans, un rouge vif se lit comme une punition.
class Shake extends StatefulWidget {
  const Shake({required this.child, super.key});

  final Widget child;

  @override
  State<Shake> createState() => ShakeState();
}

class ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 420);
  static const double _amplitude = 9;
  static const double _oscillations = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  /// Declenche une secousse, en repartant du debut si une est en cours.
  void shake() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // L'amplitude decroit avec l'avancee : le mouvement s'eteint de
        // lui-meme, comme un objet qu'on repose.
        final decay = 1 - _controller.value;
        final offset = math.sin(
              _controller.value * _oscillations * 2 * math.pi,
            ) *
            _amplitude *
            decay;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
