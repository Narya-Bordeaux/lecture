import 'dart:math';

import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';

/// Une boite de rangement presentee au centre de la scene, qui va se ranger a
/// sa place quand l'enfant la touche.
///
/// **La carte est la boite elle-meme, agrandie** : le meme cadre, le meme
/// intitule, poses a l'endroit exact de la zone puis grossis et ramenes au
/// centre. En vol, elle ne fait que retrouver sa taille et sa place — a
/// l'arrivee, rien ne distingue la carte de la zone qui la remplace, et
/// l'enfant a vu d'ou venait ce qu'il trouve sur le decor.
///
/// Toute la scene recoit le toucher, pas seulement la carte : l'intitule
/// deborde du cadre, et un enfant de six ans ne doit pas manquer sa cible.
class FamilyIntroCard extends StatefulWidget {
  const FamilyIntroCard({
    required this.family,
    required this.requiredCount,
    required this.targetRect,
    required this.onPlaced,
    super.key,
  });

  /// Identifie la carte d'une famille, pour la viser dans les tests.
  static Key keyFor(String familyId) =>
      ValueKey<String>('family_intro_$familyId');

  final WordFamily family;
  final int requiredCount;

  /// Le cadre de la zone sur la scene, dans le repere du calque : la ou la
  /// carte va se ranger.
  final Rect targetRect;

  /// Appele une fois la carte arrivee a sa place.
  final VoidCallback onPlaced;

  /// De combien la boite est grossie au centre de la scene.
  ///
  /// Assez pour qu'elle se lise comme une annonce — les deux tiers de la
  /// largeur —, sans jamais depasser la moitie de la hauteur ni tripler :
  /// une zone deja grande n'a pas a envahir l'ecran. Jamais moins que sa
  /// taille reelle, elle ne ferait que retrecir en allant a sa place.
  static double restScaleFor({required Rect target, required Size surface}) {
    if (target.isEmpty || surface.isEmpty) return 1;
    final wanted = min(
      surface.width * 2 / 3 / target.width,
      surface.height / 2 / target.height,
    );
    return wanted.clamp(1.0, 3.0);
  }

  @override
  State<FamilyIntroCard> createState() => _FamilyIntroCardState();
}

class _FamilyIntroCardState extends State<FamilyIntroCard>
    with TickerProviderStateMixin {
  /// L'apparition, un peu retardee : le temps que le cartouche se montre
  /// avant la premiere boite.
  late final AnimationController _appearance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  late final AnimationController _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _appearance.dispose();
    _flight.dispose();
    super.dispose();
  }

  Future<void> _fly() async {
    if (_flight.isAnimating || _flight.isCompleted) return;
    await _flight.forward();
    if (mounted) widget.onPlaced();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final surface = Size(constraints.maxWidth, constraints.maxHeight);
        final target = widget.targetRect;
        final restScale = FamilyIntroCard.restScaleFor(target: target, surface: surface);
        // Au repos, le centre du cadre est au centre de la scene.
        final restOffset = surface.center(Offset.zero) - target.center;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _fly,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fromRect(
                rect: target,
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[
                    _appearance,
                    _flight,
                  ]),
                  builder: (context, child) {
                    final appeared = const Interval(
                      0.4,
                      1,
                      curve: Curves.easeOutBack,
                    ).transform(_appearance.value);
                    final travelled = Curves.easeInOutCubic.transform(
                      _flight.value,
                    );
                    final scale = (restScale + (1 - restScale) * travelled) *
                        (0.8 + 0.2 * appeared);

                    return Opacity(
                      opacity: appeared.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset.lerp(restOffset, Offset.zero, travelled)!,
                        child: Transform.scale(scale: scale, child: child),
                      ),
                    );
                  },
                  child: Semantics(
                    button: true,
                    label: UiStringsFr.placeFamilySemantics(
                      widget.family.label,
                    ),
                    child: IgnorePointer(
                      child: FamilyDropZone(
                        key: FamilyIntroCard.keyFor(widget.family.id),
                        family: widget.family,
                        requiredCount: widget.requiredCount,
                        placedWords: const [],
                        isOpen: false,
                        onWordDropped: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
