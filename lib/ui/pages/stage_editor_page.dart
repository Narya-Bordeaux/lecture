import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';
import 'package:grisbie/ui/widgets/picture_field.dart';

/// Tout ce qu'un lieu porte, sauf ses mots.
///
/// L'ecran du parcours dit **ou** l'on va — les trajets, les arrivees, la
/// forme de la journee. Celui-ci dit **ce qu'il y a** une fois sur place : le
/// nom, l'illustration, les zones de depot et le recit d'arrivee.
///
/// Les listes de mots n'y sont pas : elles appartiennent a un **trajet**, pas
/// a un lieu, et une meme liste sert a plusieurs endroits. Les mettre ici
/// laisserait croire qu'on les modifie pour ce lieu seul.
///
/// Rend l'etape modifiee, ou `null` si l'auteur renonce.
///
/// **« Garder », pas « Enregistrer »** : rien n'est ecrit ici, l'etape remonte
/// a l'ecran du parcours qui travaille en memoire. Un seul geste de l'outil
/// ecrit sur le disque, et c'est lui seul qui porte le mot.
class StageEditorPage extends StatefulWidget {
  const StageEditorPage({
    required this.stage,
    this.pictures,
    this.contentSource,
    super.key,
  });

  final Stage stage;

  /// Les images du depot, parmi lesquelles choisir l'illustration.
  ///
  /// Nul, le champ reste saisissable au clavier et le bouton ne paraît pas :
  /// c'est le cas des tests qui ne portent pas sur l'image.
  final PictureCatalog? pictures;

  /// D'ou lire le contenu, illustrations comprises.
  ///
  /// Nulle, le bundle : c'est le cas du jeu et des tests. L'outil d'auteur y
  /// passe la source ou il travaille, pour que l'apercu montre l'image qu'il
  /// vient de deposer et non celle d'avant.
  final ContentSource? contentSource;


  @override
  State<StageEditorPage> createState() => _StageEditorPageState();
}

class _StageEditorPageState extends State<StageEditorPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.stage.locationName);
  late final TextEditingController _background =
      TextEditingController(text: widget.stage.backgroundAsset ?? '');
  late final TextEditingController _onArrival =
      TextEditingController(text: widget.stage.narrative.onArrival ?? '');

  /// Les familles, dont les zones changent au calage.
  late List<WordFamily> _families = widget.stage.families;

  @override
  void dispose() {
    _name.dispose();
    _background.dispose();
    _onArrival.dispose();
    super.dispose();
  }

  /// Le texte saisi, ou `null` quand le champ est vide.
  ///
  /// Un recit vide et un recit absent sont la meme chose ; ecrire une chaine
  /// vide dans le contenu ferait afficher un ecran de texte sans texte.
  static String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  String get _backgroundPath => _background.text.trim();

  /// L'etape telle qu'elle est en cours d'edition.
  ///
  /// **L'identifiant ne bouge pas**, meme si le nom change : il nait du nom
  /// puis s'en detache, et le faire suivre casserait toutes les destinations
  /// qui le citent.
  Stage get _edited {
    return widget.stage.copyWith(
      locationName: _name.text.trim().isEmpty
          ? widget.stage.locationName
          : _name.text.trim(),
      families: _families,
      narrative: Narrative(onArrival: _orNull(_onArrival)),
      backgroundAsset: _backgroundPath.isEmpty ? null : _backgroundPath,
      clearBackgroundAsset: _backgroundPath.isEmpty,
    );
  }

  /// Ouvre le calage des zones sur l'etape en cours d'edition.
  ///
  /// C'est bien l'etape **editee** qu'on cale, illustration comprise : sans
  /// cela l'auteur poserait ses zones sur l'image d'avant.
  Future<void> _placeAreas() async {
    final placed = await Navigator.of(context).push<Stage>(
      MaterialPageRoute<Stage>(
        builder: (_) => AreaEditorPage(
          stage: _edited,
          contentSource: widget.contentSource,
        ),
      ),
    );
    if (placed == null) return;

    setState(() => _families = placed.families);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le lieu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fermer sans garder',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(_edited),
            child: const Text('Garder'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nom du lieu',
              helperText: 'Ce que l\'enfant lit en arrivant.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          _buildBackground(context),
          const SizedBox(height: 24),
          _buildNarrative(context),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('L\'illustration', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        PictureField(
          fieldKey: const Key('background'),
          controller: _background,
          catalog: widget.pictures,
          contentSource: widget.contentSource,
          // L'apercu et le bouton de calage suivent ce qui est saisi.
          onChanged: () => setState(() {}),
        ),
        // Une fin, ou un lieu pas encore ecrit, n'a rien a deposer : le bouton
        // n'aurait aucune cible.
        if (_families.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _placeAreas,
              icon: const Icon(Icons.crop_free),
              label: const Text('Placer les zones'),
            ),
          ),
          _Note(
            '${_families.where((f) => f.area != null).length} zone(s) posée(s) '
            'sur ${_families.length}.',
          ),
        ],
      ],
    );
  }

  Widget _buildNarrative(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Une fin n'a rien a trier : son texte n'est pas un enonce, mais le
        // recit qui clot la journee, sous son image.
        Text(
          widget.stage.isEnding ? 'Le récit de fin' : 'L\'énoncé',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('onArrival'),
          controller: _onArrival,
          maxLines: 6,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'En arrivant',
            helperText: widget.stage.isEnding
                ? 'Sous l\'image, sur l\'écran de fin.'
                : 'En haut de la scène, au-dessus des mots : ce qui '
                    'donne son sens au tri.',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        // Dit ce que l'ecran ne demande pas, et pourquoi : le geste manquant
        // se chercherait sinon.
        _Note(
          'Un lieu ne raconte pas son départ. L\'enfant clique un trajet, et '
          'c\'est le lieu d\'arrivée qui raconte, avec son propre texte.',
        ),
      ],
    );
  }
}

/// Une precision discrete sous un champ.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
