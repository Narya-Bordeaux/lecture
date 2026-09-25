import 'package:flutter/material.dart';
import 'package:grisbie/application/completion_message.dart';

/// Le « Bravo ! » qui s'ouvre quand l'enfant a range tous les mots d'une
/// boite.
///
/// Grisbie, le pouce leve, deborde du coin haut, a cote du titre. **Un
/// toucher n'importe ou le ferme** (decision de l'auteur) : c'est une
/// felicitation, pas une question, et le chemin reste ouvert dans la barre
/// du bas.
class CompletionPopup extends StatelessWidget {
  const CompletionPopup({
    required this.message,
    required this.onClose,
    super.key,
  });

  /// Grisbie qui leve le pouce : un element du jeu, pas du contenu.
  static const String badgeAsset = 'assets/grisbie_bravo.webp';

  /// La couleur des chemins ouverts, celle de la barre de depart.
  static const Color _green = Color(0xFF2E7D32);

  static const double _badgeSize = 104;

  final CompletionMessage message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: ColoredBox(
        // Un voile leger : le decor reste visible, mais la fenetre se detache.
        color: const Color(0x33000000),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            builder: (context, appearance, child) => Opacity(
              opacity: appearance.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.8 + 0.2 * appearance,
                child: child,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                // La place du badge, qui deborde en haut a gauche.
                padding: const EdgeInsets.fromLTRB(
                  24 + _badgeSize * 0.3,
                  _badgeSize * 0.45,
                  24,
                  0,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    _buildCard(),
                    Positioned(
                      left: -_badgeSize * 0.4,
                      top: -_badgeSize * 0.55,
                      width: _badgeSize,
                      height: _badgeSize,
                      child: Image.asset(
                        badgeAsset,
                        fit: BoxFit.contain,
                        // Sans l'image, le titre suffit : rien ne doit
                        // empecher l'enfant de lire son « Bravo ! ».
                        errorBuilder: (context, error, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _green, width: 3),
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
            // Le titre s'ecarte du badge, pose dans le coin.
            padding: const EdgeInsets.only(left: _badgeSize * 0.45),
            child: Text(
              message.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: _green,
                height: 1.1,
              ),
            ),
          ),
          if (message.body case final body?) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1B1B),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
