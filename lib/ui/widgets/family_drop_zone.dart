import 'package:flutter/material.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';
import 'package:reading_game/ui/widgets/word_label.dart';

/// Un cadre translucide pose sur l'illustration, ou l'enfant depose les mots.
///
/// Le cadre reste translucide meme rempli : le decor qu'il designe — le bus,
/// la voiture, le sentier — doit rester visible, c'est lui qui donne son sens
/// a la famille.
///
/// L'intitule est pose **au-dessus** du cadre et non dedans. A l'interieur, il
/// devait tenir dans la largeur de la zone et « En voiture » s'y abregeait en
/// « En voitu... » — un enfant qui apprend a lire ne doit jamais voir un mot
/// tronque. Au-dessus, il peut deborder lateralement, et il laisse le cadre
/// entier aux mots deposes.
class FamilyDropZone extends StatelessWidget {
  const FamilyDropZone({
    required this.family,
    required this.placedWords,
    required this.isOpen,
    required this.onWordDropped,
    super.key,
  });

  /// De combien l'intitule peut deborder de chaque cote de son cadre.
  static const double _labelOverflow = 90;

  /// Identifie le cadre d'une famille, pour le viser dans les tests.
  ///
  /// L'intitule etant desormais pose au-dessus du cadre, il ne peut plus servir
  /// de repere pour y deposer un mot.
  static Key frameKeyFor(String familyId) =>
      ValueKey<String>('zone_frame_$familyId');

  final WordFamily family;

  /// Les mots deja ranges ici, dans l'ordre ou ils ont ete poses.
  final List<Word> placedWords;

  /// Vrai lorsque la famille est complete et sa destination ouverte.
  final bool isOpen;

  /// Appele quand un mot est lache sur la zone, qu'il soit juste ou non :
  /// c'est le moteur qui tranche, pas l'interface.
  final void Function(String wordText) onWordDropped;

  @override
  Widget build(BuildContext context) {
    final total = family.requiredCount;
    final placed = placedWords.length > total ? total : placedWords.length;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: _buildFrame(context)),
        // L'intitule se hisse au-dessus du cadre : la translation d'une fois
        // sa propre hauteur le place juste avant le bord superieur, sans qu'il
        // faille connaitre cette hauteur a l'avance.
        Positioned(
          left: -_labelOverflow,
          right: -_labelOverflow,
          top: 0,
          child: FractionalTranslation(
            translation: const Offset(0, -1),
            child: _ZoneTitle(
              label: family.label,
              placed: placed,
              total: total,
              isOpen: isOpen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrame(BuildContext context) {
    return DragTarget<String>(
      // La zone accepte tous les mots. Refuser ici court-circuiterait le
      // moteur, et priverait l'enfant du retour qui lui apprend son erreur.
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onWordDropped(details.data),
      builder: (context, candidates, rejected) {
        final isHovered = candidates.isNotEmpty;

        return Semantics(
          label: UiStringsFr.familySemantics(
            family.label,
            placedWords.length,
            family.requiredCount,
          ),
          child: AnimatedContainer(
            key: frameKeyFor(family.id),
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: isHovered ? 0.42 : (isOpen ? 0.34 : 0.24),
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOpen
                    ? const Color(0xFF2E7D32)
                    : (isHovered
                        ? const Color(0xFF1B1B1B)
                        : const Color(0xB31B1B1B)),
                width: isOpen || isHovered ? 3 : 2,
              ),
            ),
            child: placedWords.isEmpty
                ? const SizedBox.expand()
                : Center(
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: placedWords
                            .map(
                              (word) => WordLabelSurface(
                                word: word,
                                compact: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Le nom de la famille et son avancement, lisibles sur n'importe quel fond.
class _ZoneTitle extends StatelessWidget {
  const _ZoneTitle({
    required this.label,
    required this.placed,
    required this.total,
    required this.isOpen,
  });

  final String label;
  final int placed;
  final int total;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Ni coupure ni abreviation : le mot est ecrit en entier, quitte a
          // deborder du cadre.
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: isOpen ? const Color(0xFFBBF7C2) : Colors.white,
              height: 1.05,
              // Le contour sombre garde le texte lisible sur un decor clair
              // comme sur un decor charge.
              shadows: const <Shadow>[
                Shadow(color: Color(0xE6000000), blurRadius: 4),
                Shadow(color: Color(0xB3000000), blurRadius: 10),
                Shadow(color: Color(0x80000000), blurRadius: 18),
              ],
            ),
          ),
          Text(
            UiStringsFr.familyProgress(placed, total),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
              shadows: <Shadow>[
                Shadow(color: Color(0xE6000000), blurRadius: 4),
                Shadow(color: Color(0xB3000000), blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
