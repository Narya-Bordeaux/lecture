import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/cover_format.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/widgets/content_image.dart';
import 'package:grisbie/ui/widgets/picture_field.dart';

/// Ce que l'editeur de vignette rend.
///
/// Une enveloppe, pour la meme raison que `OpeningEdit` : « renoncer » et
/// « retirer la vignette » donneraient tous deux `null` autrement.
class CoverEdit {
  const CoverEdit(this.coverAsset);

  /// La vignette voulue, ou `null` pour n'en plus avoir.
  final String? coverAsset;
}

/// Les alertes a montrer pour une vignette de ces dimensions, en pixels.
///
/// Le jugement vient du domaine ([CoverFormat]) ; cette fonction ne fait que
/// le dire, dimensions a l'appui.
List<String> describeCoverProblems(int width, int height) {
  const recommended =
      '${CoverFormat.recommendedWidth} × ${CoverFormat.recommendedHeight}';
  return <String>[
    for (final problem in CoverFormat.check(width: width, height: height))
      switch (problem) {
        CoverProblem.wrongProportions =>
          'Cette image ($width × $height) n\'est pas au format 3:2 en '
              'largeur : elle sera recadrée au centre. Conseillé : $recommended.',
        CoverProblem.tooSmall =>
          'Cette image ($width × $height) est trop petite : elle sera floue '
              'sur un téléphone. Au moins ${CoverFormat.minimumWidth} × '
              '${CoverFormat.minimumHeight}.',
      },
  ];
}

/// La vignette de l'aventure : l'image qui la represente dans la roue de
/// l'accueil du jeu.
///
/// Un editeur a part, et non un champ de la page de garde : la vignette n'est
/// pas ce que l'enfant lit en entrant dans l'aventure, c'est ce qui la lui
/// fait choisir. Elle peut reprendre l'illustration de la page de garde, si
/// l'auteur le decide.
///
/// Rend un [CoverEdit], ou `null` si l'auteur renonce.
class CoverEditorPage extends StatefulWidget {
  const CoverEditorPage({
    this.coverAsset,
    this.pictures,
    this.adventureId,
    this.contentSource,
    super.key,
  });

  /// La vignette actuelle, nulle tant qu'il n'y en a pas.
  final String? coverAsset;

  /// Les images du depot, parmi lesquelles choisir.
  final PictureCatalog? pictures;

  /// L'aventure en cours, dont le dossier d'images s'ouvre d'abord.
  final String? adventureId;

  /// D'ou lire l'apercu. Nulle, le bundle.
  final ContentSource? contentSource;

  @override
  State<CoverEditorPage> createState() => _CoverEditorPageState();
}

class _CoverEditorPageState extends State<CoverEditorPage> {
  late final TextEditingController _image =
      TextEditingController(text: widget.coverAsset ?? '');

  @override
  void dispose() {
    _image.dispose();
    super.dispose();
  }

  String get _path => _image.text.trim();

  void _keep() {
    Navigator.of(context).pop(CoverEdit(_path.isEmpty ? null : _path));
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vignette de l\'aventure'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer sans garder',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(onPressed: _keep, child: const Text('Garder')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'L\'image qui représente l\'aventure sur l\'accueil du jeu. '
            'Format 3:2 en largeur, comme les illustrations de narration : '
            '${CoverFormat.recommendedWidth} × ${CoverFormat.recommendedHeight} '
            'conseillé. Sans vignette, l\'aventure n\'est pas complète.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          PictureField(
            fieldKey: const Key('coverImage'),
            controller: _image,
            catalog: widget.pictures,
            adventureId: widget.adventureId,
            contentSource: widget.contentSource,
            checkDimensions: describeCoverProblems,
            onChanged: () => setState(() {}),
          ),
          if (path.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            Text(
              'Dans la roue de l\'accueil',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            // Recadree comme dans la roue : c'est ici que l'auteur voit ce
            // que l'enfant verra, et non l'image entiere de l'apercu.
            Center(
              child: SizedBox(
                width: 180,
                child: AspectRatio(
                  aspectRatio: CoverFormat.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ContentImage(
                      key: const Key('coverPreview'),
                      path: path,
                      source: widget.contentSource,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (widget.coverAsset != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(const CoverEdit(null)),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Retirer la vignette'),
              ),
            ),
        ],
      ),
    );
  }
}
