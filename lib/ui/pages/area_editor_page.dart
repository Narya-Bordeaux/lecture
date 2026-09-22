import 'dart:math';

import 'package:flutter/material.dart';
import 'package:grisbie/application/area_editor.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/widgets/background_image_size.dart';
import 'package:grisbie/ui/widgets/scene_layout.dart';

/// Outil d'auteur : caler les zones de depot sur l'illustration d'une etape.
///
/// L'etape reelle est affichee en dessous, inerte : decor, bandeau des mots,
/// cadres et intitules sont exactement ceux du jeu. Une zone recouverte par le
/// bandeau se voit donc immediatement, ce qu'aucun calcul sur une image seule
/// ne montrerait.
///
/// Toute la geometrie est deleguee a [AreaEditor], en Dart pur : cette page ne
/// fait que traduire des gestes en fractions de l'illustration.
///
/// Une zone par famille, quel que soit leur nombre : un lieu ordinaire en a
/// une par chemin, un tri unique deux — le theme et le reste.
///
/// Rend **l'etape calee**, ou `null` si l'auteur renonce. Rien ne s'ecrit ici :
/// l'etape retourne a l'editeur de lieu, puis au parcours, et c'est
/// « Enregistrer » qui l'ecrit avec le reste. Aucun JSON n'est montre — le
/// recopier a la main a ete la seule facon d'enregistrer, ce n'est plus le cas.
class AreaEditorPage extends StatefulWidget {
  const AreaEditorPage({required this.stage, this.contentSource, super.key});

  final Stage stage;

  /// D'ou lire le contenu, illustrations comprises. Nulle, le bundle.
  final ContentSource? contentSource;

  /// Cote minimal d'une zone, en points : la cible d'accessibilite usuelle.
  static const double minimumSide = 48;

  /// Cote des poignees de coin.
  static const double handleSize = 40;

  @override
  State<AreaEditorPage> createState() => _AreaEditorPageState();
}

class _AreaEditorPageState extends State<AreaEditorPage> {
  late Map<String, RelativeArea> _areas;

  /// Les zones posees d'office, que l'auteur n'a pas encore touchees.
  ///
  /// Seules elles sont agrandies a la taille d'un doigt sans qu'on le demande :
  /// retoucher en silence une zone calee par l'auteur serait lui reprendre la
  /// main sur son contenu.
  late Set<String> _placedByDefault;

  @override
  void initState() {
    super.initState();
    final families = widget.stage.families;
    final missing = <String>[
      for (final family in families)
        if (family.area == null) family.id,
    ];

    // Une etape fraichement illustree n'a aucune zone : on lui en pose, en
    // grille dans la moitie basse, plutot que de les empiler au meme endroit.
    final defaults = AreaEditor.defaultLayout(missing);
    _areas = <String, RelativeArea>{
      for (final family in families)
        family.id: family.area ?? defaults[family.id]!,
    };
    _placedByDefault = missing.toSet();
  }

  /// L'etape telle qu'elle serait jouee avec le calage en cours.
  ///
  /// L'identifiant ne change pas : la page de jeu conserve donc son moteur, et
  /// les mots ne se remelangent pas a chaque geste.
  Stage get _previewStage {
    return widget.stage.copyWith(
      families: widget.stage.families
          .map((family) => family.copyWith(area: _areas[family.id]))
          .toList(growable: false),
    );
  }

  /// L'etape rendue a l'editeur : les zones arrondies, telles qu'elles seront
  /// enregistrees. C'est sur elles que portent les controles de chevauchement.
  Stage _placedStage(Rect imageRect) {
    final rounded = _editorFor(imageRect).roundedAreas;
    return widget.stage.copyWith(
      families: widget.stage.families
          .map((family) => family.copyWith(area: rounded[family.id]))
          .toList(growable: false),
    );
  }

  /// Le moteur de calage, arme des minimums reels de l'appareil.
  AreaEditor _editorFor(Rect imageRect) {
    return AreaEditor(
      areas: _areas,
      minimumWidth: _minimumFraction(AreaEditorPage.minimumSide, imageRect.width),
      minimumHeight:
          _minimumFraction(AreaEditorPage.minimumSide, imageRect.height),
    );
  }

  /// Convertit un cote en points en fraction de l'illustration affichee.
  static double _minimumFraction(double side, double available) {
    if (available <= 0) return 0.05;
    return (side / available).clamp(0.01, 0.5);
  }

  void _apply(
    Rect imageRect,
    String familyId,
    void Function(AreaEditor editor) change,
  ) {
    final editor = _editorFor(imageRect);
    change(editor);
    setState(() {
      _areas = Map<String, RelativeArea>.of(editor.areas);
      _placedByDefault.remove(familyId);
    });
  }

  /// Agrandit a la taille d'un doigt les zones posees d'office.
  ///
  /// Le minimum depend de l'illustration reellement affichee, connue seulement
  /// a la mise en page : d'ou un rattrapage apres l'image, et non a
  /// l'ouverture.
  void _enforceMinimumOnDefaults(AreaEditor editor) {
    final undersized = _placedByDefault.where(editor.isUndersized).toList();
    if (undersized.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      undersized.forEach(editor.enforceMinimumSize);
      setState(() => _areas = Map<String, RelativeArea>.of(editor.areas));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // L'etape reelle, inerte : elle sert d'apercu, pas de jeu.
          IgnorePointer(
            child: StagePage(
              stage: _previewStage,
              onDeparture: (_) {},
              random: Random(1),
              contentSource: widget.contentSource,
            ),
          ),
          BackgroundImageSize(
            source: widget.contentSource,
            asset: widget.stage.backgroundAsset,
            builder: (context, imageSize) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final imageRect = computeSceneRect(
                    surface: Size(constraints.maxWidth, constraints.maxHeight),
                    imageSize: imageSize,
                    bottomInset: bottomInset,
                  );

                  return _buildHandles(imageRect);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandles(Rect imageRect) {
    final editor = _editorFor(imageRect);
    _enforceMinimumOnDefaults(editor);
    final guilty = editor.overlappingFamilyIds;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final family in widget.stage.families)
          ..._handlesFor(
            familyId: family.id,
            label: family.label,
            imageRect: imageRect,
            overlapping: guilty.contains(family.id),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _EditorPanel(
            // L'auteur connait ses familles par leur nom, pas par leur
            // identifiant.
            overlappingLabels: <String>[
              for (final family in widget.stage.families)
                if (guilty.contains(family.id)) family.label,
            ],
            onClose: () => Navigator.of(context).pop(),
            onApply: () => Navigator.of(context).pop(_placedStage(imageRect)),
          ),
        ),
      ],
    );
  }

  List<Widget> _handlesFor({
    required String familyId,
    required String label,
    required Rect imageRect,
    required bool overlapping,
  }) {
    final area = _areas[familyId];
    if (area == null) return const <Widget>[];

    final rect = Rect.fromLTWH(
      imageRect.left + area.left * imageRect.width,
      imageRect.top + area.top * imageRect.height,
      area.width * imageRect.width,
      area.height * imageRect.height,
    );
    final color = overlapping ? Colors.redAccent : Colors.amberAccent;

    return <Widget>[
      // Le corps deplace la zone entiere.
      Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _apply(
            imageRect,
            familyId,
            (editor) => editor.move(
              familyId,
              dx: details.delta.dx / imageRect.width,
              dy: details.delta.dy / imageRect.height,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 2),
              color: color.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
      for (final corner in AreaCorner.values)
        _cornerHandle(
          familyId: familyId,
          corner: corner,
          rect: rect,
          imageRect: imageRect,
          color: color,
        ),
    ];
  }

  Widget _cornerHandle({
    required String familyId,
    required AreaCorner corner,
    required Rect rect,
    required Rect imageRect,
    required Color color,
  }) {
    final center = switch (corner) {
      AreaCorner.topLeft => rect.topLeft,
      AreaCorner.topRight => rect.topRight,
      AreaCorner.bottomLeft => rect.bottomLeft,
      AreaCorner.bottomRight => rect.bottomRight,
    };
    const size = AreaEditorPage.handleSize;

    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => _apply(
          imageRect,
          familyId,
          (editor) => editor.resize(
            familyId,
            corner: corner,
            dx: details.delta.dx / imageRect.width,
            dy: details.delta.dy / imageRect.height,
          ),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

/// Le panneau du bas : garder ou renoncer, et ce qui empecherait de jouer.
///
/// Les alertes n'apparaissent que lorsqu'il y en a : un panneau court laisse
/// voir le bas de l'illustration, ou se posent justement les zones.
class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.overlappingLabels,
    required this.onClose,
    required this.onApply,
  });

  /// Les noms des familles dont les zones se chevauchent, dans l'ordre du lieu.
  final List<String> overlappingLabels;
  final VoidCallback onClose;

  /// Rend l'etape calee a l'appelant, qui la repose dans l'aventure.
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fermer sans garder',
                ),
                const Expanded(
                  child: Text(
                    'Zones de dépôt',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: onApply, child: const Text('Garder')),
              ],
            ),
            if (overlappingLabels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Text(
                  'Ces zones se chevauchent : ${overlappingLabels.join(', ')} — '
                  'le dépôt y serait ambigu.',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                'Une zone cachée par le bandeau des mots est intouchable : '
                'elle doit rester visible ici.',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
