import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/picture_catalog.dart';
import 'package:grisbie/ui/pages/area_editor_page.dart';
import 'package:grisbie/ui/widgets/picture_field.dart';

/// L'apparence d'un lieu : son illustration et la place de ses cadres.
///
/// **Rien que l'apparence** (decision de l'auteur) : la premiere ligne de la
/// carte d'un lieu ouvre ceci, la seconde ouvre ses textes
/// (`StageTextsPage`). Melanger les deux obligeait a passer d'un ecran a
/// l'autre pour savoir quel texte paraitrait ou.
///
/// Rend l'etape modifiee, ou `null` si l'auteur renonce.
///
/// **« Garder », pas « Enregistrer »** : rien n'est ecrit ici, l'etape remonte
/// a l'ecran du parcours qui travaille en memoire. Un seul geste de l'outil
/// ecrit sur le disque, et c'est lui seul qui porte le mot.
class StageAppearancePage extends StatefulWidget {
  const StageAppearancePage({
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
  State<StageAppearancePage> createState() => _StageAppearancePageState();
}

class _StageAppearancePageState extends State<StageAppearancePage> {
  late final TextEditingController _background =
      TextEditingController(text: widget.stage.backgroundAsset ?? '');

  /// Les familles, dont les zones changent au calage.
  late List<WordFamily> _families = widget.stage.families;

  @override
  void dispose() {
    _background.dispose();
    super.dispose();
  }

  String get _backgroundPath => _background.text.trim();

  /// L'etape telle qu'elle est en cours d'edition.
  Stage get _edited {
    return widget.stage.copyWith(
      families: _families,
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
        title: Text('L\'apparence · ${widget.stage.locationName}'),
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
          Text(
            'L\'illustration',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          PictureField(
            fieldKey: const Key('background'),
            controller: _background,
            catalog: widget.pictures,
            contentSource: widget.contentSource,
            // L'apercu et le bouton de calage suivent ce qui est saisi.
            onChanged: () => setState(() {}),
          ),
          // Une fin, ou un lieu pas encore ecrit, n'a rien a deposer : le
          // bouton n'aurait aucune cible.
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
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${_families.where((f) => f.area != null).length} zone(s) '
                'posée(s) sur ${_families.length}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
