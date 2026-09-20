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
class FamilyDropZone extends StatelessWidget {
  const FamilyDropZone({
    required this.family,
    required this.placedWords,
    required this.isOpen,
    required this.onWordDropped,
    super.key,
  });

  final WordFamily family;

  /// Les mots deja ranges ici, dans l'ordre ou ils ont ete poses.
  final List<Word> placedWords;

  /// Vrai lorsque la famille est complete et sa destination ouverte.
  final bool isOpen;

  /// Appele quand un mot est lache sur la zone, qu'il soit juste ou non :
  /// c'est le moteur qui tranche, pas l'interface.
  final void Function(String wordId) onWordDropped;

  @override
  Widget build(BuildContext context) {
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
            family.wordIds.length,
          ),
          child: AnimatedContainer(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ZoneTitle(
                  label: family.label,
                  // L'avancement se compte vers l'objectif, pas vers la
                  // reserve : l'enfant doit voir ce qui lui reste a faire pour
                  // ouvrir le chemin, pas la taille cachee de la liste. Le
                  // compte est borne, pour ne jamais afficher « 6 / 5 ».
                  placed: placedWords.length > family.requiredCount
                      ? family.requiredCount
                      : placedWords.length,
                  total: family.requiredCount,
                ),
                if (placedWords.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Flexible(
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
                ],
              ],
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
  });

  final String label;
  final int placed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.05,
            // Le contour sombre garde le texte lisible sur un decor clair
            // comme sur un decor charge.
            shadows: <Shadow>[
              Shadow(color: Color(0xCC000000), blurRadius: 4),
              Shadow(color: Color(0x99000000), blurRadius: 10),
            ],
          ),
        ),
        Text(
          UiStringsFr.familyProgress(placed, total),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: <Shadow>[Shadow(color: Color(0xCC000000), blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
