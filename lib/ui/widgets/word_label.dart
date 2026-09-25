import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

/// L'aspect d'une etiquette de mot, sans aucun comportement.
///
/// Partage entre l'etiquette posable, son fantome pendant le deplacement et sa
/// copie rangee dans une zone : le mot garde ainsi exactement la meme
/// apparence tout au long du geste.
class WordLabelSurface extends StatelessWidget {
  const WordLabelSurface({
    required this.word,
    this.compact = false,
    this.elevated = false,
    super.key,
  });

  final Word word;

  /// Version reduite, pour une etiquette rangee dans une zone.
  final bool compact;

  /// Version soulevee, pendant le deplacement au doigt.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
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
      // Le mot seul, sur une seule ligne quitte a etre reduit : un mot qui
      // passe a la ligne fait grandir le bandeau, qui finit par recouvrir les
      // zones de depot ancrees haut dans le decor. Aucune aide ne s'affiche
      // plus dessous (0.33.0).
      child: FittedBox(
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
    );
  }
}

/// Une etiquette que l'enfant peut saisir et deplacer.
///
/// **Le mot compte la ou on le voit, pas sous le doigt.** L'etiquette suit
/// le doigt en se tenant au-dessus de lui — a cet age, la main cache
/// volontiers ce qu'elle deplace. Flutter cherchait pourtant la zone sous le
/// doigt : l'enfant voyait son mot dans la boite, pres du bord bas, lachait,
/// et le mot repartait, son doigt etant deja sorti. Il croyait s'etre trompe.
/// [Draggable.feedbackOffset] deplace le point vise au centre de l'etiquette.
///
/// **Lache hors des boites, le mot revient en glissant**, sans trembler : le
/// tremblement dit « tu t'es trompe », et ce n'est pas le cas.
/// [onDroppedOutside] permet a la page de montrer ou viser.
class DraggableWordLabel extends StatefulWidget {
  const DraggableWordLabel({
    required this.word,
    this.onDroppedOutside,
    super.key,
  });

  /// L'ecart entre le bas de l'etiquette et le doigt, pendant le geste.
  static const double fingerGap = 12;

  /// La duree du retour d'un mot lache hors des boites.
  static const Duration returnDuration = Duration(milliseconds: 320);

  /// Ou se trouve le centre de l'etiquette par rapport au doigt : c'est ce
  /// point-la qui doit etre dans la boite.
  static Offset seenPointFromFinger(Size labelSize) =>
      Offset(0, -(labelSize.height / 2 + fingerGap));

  final Word word;

  /// Appele quand le mot est lache hors de toute boite.
  final VoidCallback? onDroppedOutside;

  @override
  State<DraggableWordLabel> createState() => _DraggableWordLabelState();
}

class _DraggableWordLabelState extends State<DraggableWordLabel> {
  /// Une estimation avant la premiere mesure : la hauteur d'une etiquette a
  /// la taille de texte ordinaire.
  Size _labelSize = const Size(80, 41);

  /// Le mot qui revient a sa case, pose au-dessus de tout le reste.
  OverlayEntry? _returning;

  @override
  void dispose() {
    _returning?.remove();
    super.dispose();
  }

  /// Retient la taille reelle de l'etiquette, apres sa mise en page : la
  /// taille du texte peut etre grossie par les reglages du telephone.
  void _measure() {
    if (!mounted) return;
    final size = (context.findRenderObject() as RenderBox?)?.size;
    if (size != null && size != _labelSize) {
      setState(() => _labelSize = size);
    }
  }

  void _returnToSlot(Offset releasedAt) {
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final ownBox = context.findRenderObject() as RenderBox;
    final from = overlayBox.globalToLocal(releasedAt);
    final to = overlayBox.globalToLocal(ownBox.localToGlobal(Offset.zero));

    _returning?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ReturningLabel(
        word: widget.word,
        from: from,
        to: to,
        onArrived: () {
          entry.remove();
          if (identical(_returning, entry)) _returning = null;
          if (mounted) setState(() {});
        },
      ),
    );
    setState(() => _returning = entry);
    overlay.insert(entry);
    widget.onDroppedOutside?.call();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final surface = WordLabelSurface(word: widget.word);

    return Semantics(
      label: UiStringsFr.wordSemantics(widget.word.text),
      button: true,
      child: Draggable<String>(
        data: widget.word.text,
        dragAnchorStrategy: (draggable, context, position) {
          final renderBox = context.findRenderObject() as RenderBox?;
          final size = renderBox?.size ?? Size.zero;
          return Offset(
            size.width / 2,
            size.height + DraggableWordLabel.fingerGap,
          );
        },
        feedbackOffset: DraggableWordLabel.seenPointFromFinger(_labelSize),
        feedback: Material(
          color: Colors.transparent,
          child: WordLabelSurface(word: widget.word, elevated: true),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: surface),
        onDraggableCanceled: (velocity, offset) => _returnToSlot(offset),
        // Pendant le retour, la case reste vide : le mot n'est pas encore
        // arrive.
        child: Opacity(opacity: _returning == null ? 1 : 0, child: surface),
      ),
    );
  }
}

/// Le mot qui glisse de l'endroit ou il a ete lache jusqu'a sa case.
class _ReturningLabel extends StatefulWidget {
  const _ReturningLabel({
    required this.word,
    required this.from,
    required this.to,
    required this.onArrived,
  });

  final Word word;
  final Offset from;
  final Offset to;
  final VoidCallback onArrived;

  @override
  State<_ReturningLabel> createState() => _ReturningLabelState();
}

class _ReturningLabelState extends State<_ReturningLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DraggableWordLabel.returnDuration,
  )..forward().whenComplete(widget.onArrived);

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
        final position = Offset.lerp(
          widget.from,
          widget.to,
          Curves.easeOutCubic.transform(_controller.value),
        )!;
        return Positioned(left: position.dx, top: position.dy, child: child!);
      },
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: WordLabelSurface(word: widget.word, elevated: true),
        ),
      ),
    );
  }
}
