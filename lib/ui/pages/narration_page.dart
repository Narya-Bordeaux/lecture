import 'package:flutter/material.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// L'ecran de lecture du jeu : un titre facultatif en haut, l'illustration,
/// puis le texte, et un bouton pour continuer.
///
/// **Un seul ecran pour lire**, qu'on ouvre l'aventure (la page de garde) ou
/// qu'on l'acheve (une fin). Deux mises en page auraient fini par dire la meme
/// chose differemment — c'est arrive : la fin n'affichait pas son image, et
/// l'auteur qui en posait une ne la voyait jamais.
///
/// L'illustration est montree **en entier, a ses proportions**, sur toute la
/// largeur : elle peut etre horizontale, a l'inverse des decors de jeu.
class NarrationPage extends StatelessWidget {
  const NarrationPage({
    required this.text,
    required this.actionLabel,
    required this.onAction,
    this.title,
    this.imagePath,
    this.contentSource,
    super.key,
  });

  /// Le titre, en haut. Nul, l'ecran commence par l'image.
  final String? title;

  /// L'illustration, relative au dossier du contenu. Nulle, pas d'image.
  final String? imagePath;

  final String text;

  /// Ce que dit le bouton : « C'est parti ! », « Recommencer »…
  final String actionLabel;
  final VoidCallback onAction;

  /// D'ou lire l'illustration. Nulle, le bundle : c'est le cas du jeu.
  final ContentSource? contentSource;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final image = imagePath;

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
                    if (title != null) ...<Widget>[
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (image != null) ...<Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ContentImage(
                            path: image,
                            source: contentSource,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (context, error, stack) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      text,
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
              // doit jamais falloir faire glisser l'ecran pour continuer.
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: FilledButton(
                onPressed: onAction,
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
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
