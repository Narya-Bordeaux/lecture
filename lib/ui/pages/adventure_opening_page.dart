import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// La page de garde d'une aventure.
///
/// C'est le seul ecran de lecture du jeu : le titre annonce en haut, l'illustration occupe toute la largeur, et le
/// texte se lit dessous. C'est un seuil que l'on franchit une fois, pas une
/// transition entre deux lieux.
///
/// L'illustration d'ouverture est souvent horizontale, a l'inverse des decors
/// de jeu : elle est montree en entier, a ses proportions, sans recadrage.
class AdventureOpeningPage extends StatelessWidget {
  const AdventureOpeningPage({
    required this.opening,
    required this.adventureTitle,
    required this.onStart,
    super.key,
  });

  final AdventureOpening opening;

  /// Sert de titre si l'ouverture n'en donne pas.
  final String adventureTitle;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final image = opening.imageAsset;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              // Defilable : sur un petit ecran, titre, image et texte peuvent
              // depasser, et rien ne doit etre coupe.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      opening.titleOr(adventureTitle),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    if (image != null) ...<Widget>[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ContentImage(
                            path: image,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (context, error, stack) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      opening.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.45,
                        color: Color(0xFF3B3B3B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              // Le bouton reste a portee du pouce, hors du defilement : il ne
              // doit jamais falloir faire glisser l'ecran pour commencer.
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(UiStringsFr.startAdventure),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
