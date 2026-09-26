import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/cover_format.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/widgets/picture_field.dart';

/// Ce qu'il faut dire de l'illustration de la page de garde, d'apres ses
/// dimensions en pixels. Vide, elle convient.
///
/// Un conseil, jamais un refus : la page de garde montre l'image entiere, a
/// ses proportions. Le format est celui de la vignette (`CoverFormat`), le
/// 3:2 des ecrans de lecture : le suivre permet de reprendre l'image telle
/// quelle pour la vignette.
List<String> describeOpeningPictureProblems(int width, int height) {
  const recommended =
      '${CoverFormat.recommendedWidth} × ${CoverFormat.recommendedHeight}';
  return <String>[
    for (final problem in CoverFormat.check(width: width, height: height))
      switch (problem) {
        CoverProblem.wrongProportions =>
          'Cette image ($width × $height) n\'est pas au format 3:2 en '
              'largeur. Elle sera montrée entière, mais ne pourra pas servir '
              'de vignette sans être recadrée. Conseillé : $recommended.',
        CoverProblem.tooSmall =>
          'Cette image ($width × $height) est trop petite : elle sera floue '
              'sur un téléphone. Au moins ${CoverFormat.minimumWidth} × '
              '${CoverFormat.minimumHeight}.',
      },
  ];
}

/// Ce que l'editeur de page de garde rend.
///
/// Une enveloppe plutot qu'une [AdventureOpening] nue : il faut distinguer
/// « renoncer » — la page se ferme sans rien changer — de « retirer la page de
/// garde », qui est un vrai geste. Les deux donneraient `null` autrement.
class OpeningEdit {
  const OpeningEdit(this.opening);

  /// La page de garde voulue, ou `null` pour n'en plus avoir.
  final AdventureOpening? opening;
}

/// Le seuil de l'aventure : un titre, une illustration, un texte.
///
/// Ce n'est pas un lieu — il n'y a rien a classer — mais la page qui ouvre la
/// journee. Le titre annonce, l'image occupe la largeur a ses proportions (elle peut etre
/// horizontale), le texte se lit dessous.
///
/// Rend un [OpeningEdit], ou `null` si l'auteur renonce.
class AdventureOpeningEditorPage extends StatefulWidget {
  const AdventureOpeningEditorPage({
    required this.adventureTitle,
    this.opening,
    this.pictures,
    this.adventureId,
    this.contentSource,
    super.key,
  });

  /// Sert de repli au titre : une aventure n'a pas a repeter son nom.
  final String adventureTitle;

  /// La page de garde actuelle, nulle tant qu'il n'y en a pas.
  final AdventureOpening? opening;

  /// Les images du depot, parmi lesquelles choisir l'illustration.
  final PictureCatalog? pictures;

  /// L'aventure en cours, dont le dossier d'images s'ouvre d'abord.
  final String? adventureId;

  /// D'ou lire le contenu, illustrations comprises.
  ///
  /// Nulle, le bundle : c'est le cas du jeu et des tests. L'outil d'auteur y
  /// passe la source ou il travaille, pour que l'apercu montre l'image qu'il
  /// vient de deposer et non celle d'avant.
  final ContentSource? contentSource;


  @override
  State<AdventureOpeningEditorPage> createState() =>
      _AdventureOpeningEditorPageState();
}

class _AdventureOpeningEditorPageState
    extends State<AdventureOpeningEditorPage> {
  late final TextEditingController _title =
      TextEditingController(text: widget.opening?.title ?? '');
  late final TextEditingController _image =
      TextEditingController(text: widget.opening?.imageAsset ?? '');
  late final TextEditingController _text =
      TextEditingController(text: widget.opening?.text ?? '');

  @override
  void dispose() {
    _title.dispose();
    _image.dispose();
    _text.dispose();
    super.dispose();
  }

  static String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String get _imagePath => _image.text.trim();

  /// Vrai des qu'il y a quelque chose a montrer.
  ///
  /// Une page de garde sans rien dessus ferait attendre l'enfant devant un
  /// ecran vide : mieux vaut alors ne pas en avoir.
  bool get _hasSomething =>
      _title.text.trim().isNotEmpty ||
      _text.text.trim().isNotEmpty ||
      _imagePath.isNotEmpty;

  void _save() {
    Navigator.of(context).pop(
      OpeningEdit(
        _hasSomething
            ? AdventureOpening(
                title: _orNull(_title),
                imageAsset: _imagePath.isEmpty ? null : _imagePath,
                text: _text.text.trim(),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page de garde'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer sans garder',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(onPressed: _save, child: const Text('Garder')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Montrée une fois, avant le premier lieu. Quand elle existe, le '
            'lieu de départ n\'a pas besoin de texte d\'arrivée : deux écrans '
            'de suite feraient attendre l\'enfant pour rien.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('openingTitle'),
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Titre',
              helperText: 'Vide, « ${widget.adventureTitle} » prend sa place.',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          PictureField(
            fieldKey: const Key('openingImage'),
            controller: _image,
            catalog: widget.pictures,
            adventureId: widget.adventureId,
            contentSource: widget.contentSource,
            helperText: 'Montrée en entier. Conseillé : 3:2 en largeur, '
                'comme la vignette.',
            checkDimensions: describeOpeningPictureProblems,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('openingText'),
            controller: _text,
            maxLines: 8,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Le texte d\'ouverture',
              helperText: 'Plus long qu\'un énoncé : c\'est un seuil.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(const OpeningEdit(null)),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Retirer la page de garde'),
            ),
          ),
        ],
      ),
    );
  }
}
