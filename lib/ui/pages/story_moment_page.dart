import 'package:flutter/material.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

/// Un moment de recit, seul a l'ecran.
///
/// Le texte occupe tout l'espace plutot que de se glisser dans l'ecran de jeu :
/// il donne son sens a ce qui va etre demande, et l'enfant doit pouvoir le lire
/// — ou se le faire lire — sans que les mots a classer ne le pressent.
///
/// Il ne peut pas non plus se poser au-dessus du bandeau des mots : celui-ci
/// touche deja les zones de depot ancrees haut dans le decor.
class StoryMomentPage extends StatelessWidget {
  const StoryMomentPage({
    required this.locationName,
    required this.text,
    required this.onContinue,
    this.backgroundAsset,
    super.key,
  });

  final String locationName;
  final String text;
  final VoidCallback onContinue;

  /// Le decor du lieu, estompe derriere le texte pour rester lisible.
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (backgroundAsset != null)
            Image.asset(
              backgroundAsset!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          // Voile clair : le decor reste reconnaissable, le texte lisible.
          const ColoredBox(color: Color(0xE6FDF6E8)),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      locationName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.45,
                        color: Color(0xFF3B3B3B),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 14,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text(UiStringsFr.continueStory),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
