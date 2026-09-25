import 'package:flutter/material.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

/// L'enonce d'un lieu, au milieu de l'ecran, avant que le jeu ne s'installe.
///
/// **Il ne se ferme que par sa fleche** — decision de l'auteur : un toucher a
/// cote le ferait par megarde, avant que l'enfant ne l'ait lu. Le meme texte
/// reste ensuite en tete du cartouche, pendant qu'on trie.
class StatementPopup extends StatelessWidget {
  const StatementPopup({required this.text, required this.onClose, super.key});

  /// La fleche qui ferme l'enonce, pour la viser dans les tests.
  static const Key closeKey = ValueKey<String>('statement_close');

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
        builder: (context, appearance, child) => Opacity(
          opacity: appearance.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * appearance, child: child),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            // Le style du cartouche, en plus lisible : c'est le meme texte
            // qu'on y retrouvera.
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x331B1B1B), width: 1.5),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B1B1B),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filled(
                    key: closeKey,
                    onPressed: onClose,
                    tooltip: UiStringsFr.closeStatement,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
