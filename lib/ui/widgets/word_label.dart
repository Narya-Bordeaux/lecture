import 'package:flutter/material.dart';
import 'package:reading_game/domain/models/hint.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

/// L'aspect d'une etiquette de mot, sans aucun comportement.
///
/// Partage entre l'etiquette posable, son fantome pendant le deplacement et sa
/// copie rangee dans une zone : le mot garde ainsi exactement la meme
/// apparence tout au long du geste.
class WordLabelSurface extends StatelessWidget {
  const WordLabelSurface({
    required this.word,
    this.hints = const <Hint>{},
    this.compact = false,
    this.elevated = false,
    super.key,
  });

  final Word word;

  /// Les aides acquises sur ce mot. Le decoupage syllabique, une fois
  /// debloque, s'affiche en permanence sous le mot : le redemander a chaque
  /// fois serait un obstacle de plus pour un enfant en difficulte.
  final Set<Hint> hints;

  /// Version reduite, pour une etiquette rangee dans une zone.
  final bool compact;

  /// Version soulevee, pendant le deplacement au doigt.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final showSyllables = hints.contains(Hint.syllables);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.88 : 0.96),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: const Color(0xFF3B3B3B),
          width: compact ? 1.5 : 2,
        ),
        boxShadow: elevated
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Le mot tient sur une seule ligne, quitte a etre reduit : un mot
          // qui passe a la ligne fait grandir le bandeau, qui finit par
          // recouvrir les zones de depot ancrees haut dans le decor.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.text,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                // Grande taille et fort contraste : le mot doit rester
                // dechiffrable par un lecteur debutant, sur un fond illustre.
                fontSize: compact ? 15 : 21,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1B1B),
                height: 1.1,
              ),
            ),
          ),
          if (showSyllables && !compact)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                word.syllables.join(' - '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6A6A6A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une etiquette que l'enfant peut saisir et deplacer.
class DraggableWordLabel extends StatelessWidget {
  const DraggableWordLabel({
    required this.word,
    required this.hints,
    super.key,
  });

  final Word word;
  final Set<Hint> hints;

  @override
  Widget build(BuildContext context) {
    final surface = WordLabelSurface(word: word, hints: hints);

    return Semantics(
      label: UiStringsFr.wordSemantics(word.text),
      button: true,
      child: Draggable<String>(
        data: word.text,
        // Le mot suit le doigt legerement au-dessus : a cet age la main cache
        // volontiers ce qu'elle deplace.
        dragAnchorStrategy: (draggable, context, position) {
          final renderBox = context.findRenderObject() as RenderBox?;
          final size = renderBox?.size ?? Size.zero;
          return Offset(size.width / 2, size.height + 12);
        },
        feedback: Material(
          color: Colors.transparent,
          child: WordLabelSurface(word: word, hints: hints, elevated: true),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: surface),
        child: surface,
      ),
    );
  }
}
