import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reading_game/application/area_editor.dart';
import 'package:reading_game/domain/models/relative_area.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/ui/pages/stage_page.dart';
import 'package:reading_game/ui/widgets/background_image_size.dart';
import 'package:reading_game/ui/widgets/scene_layout.dart';

/// Outil d'auteur : caler les zones de depot sur l'illustration d'une etape.
///
/// L'etape reelle est affichee en dessous, inerte : decor, bandeau des mots,
/// cadres et intitules sont exactement ceux du jeu. Une zone recouverte par le
/// bandeau se voit donc immediatement, ce qu'aucun calcul sur une image seule
/// ne montrerait.
///
/// Toute la geometrie est deleguee a [AreaEditor], en Dart pur : cette page ne
/// fait que traduire des gestes en fractions de l'illustration.
class AreaEditorPage extends StatefulWidget {
  const AreaEditorPage({required this.stage, super.key});

  final Stage stage;

  /// Cote minimal d'une zone, en points : la cible d'accessibilite usuelle.
  static const double minimumSide = 48;

  /// Cote des poignees de coin.
  static const double handleSize = 40;

  @override
  State<AreaEditorPage> createState() => _AreaEditorPageState();
}

class _AreaEditorPageState extends State<AreaEditorPage> {
  late Map<String, RelativeArea> _areas;
  bool _panelOpen = true;

  @override
  void initState() {
    super.initState();
    _areas = _initialAreas();
  }

  /// Le calage de depart : celui du contenu, ou une rangee de zones par defaut.
  ///
  /// Une etape fraichement illustree n'a aucune zone. Les poser d'office dans
  /// la moitie basse evite a l'auteur de commencer par en faire apparaitre
  /// trois au meme endroit, superposees.
  Map<String, RelativeArea> _initialAreas() {
    final families = widget.stage.families;
    final areas = <String, RelativeArea>{};
    final count = families.length;

    for (var index = 0; index < count; index++) {
      final family = families[index];
      final existing = family.area;
      if (existing != null) {
        areas[family.id] = existing;
        continue;
      }

      // Reparties sur la largeur, dans la moitie basse : le haut de
      // l'illustration est mange par le bandeau des mots sur les ecrans peu
      // allonges.
      final slot = 0.9 / count;
      areas[family.id] = RelativeArea(
        left: 0.05 + index * slot,
        top: 0.5,
        width: slot * 0.85,
        height: 0.16,
      );
    }

    return areas;
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

  void _apply(Rect imageRect, void Function(AreaEditor editor) change) {
    final editor = _editorFor(imageRect);
    change(editor);
    setState(() => _areas = Map<String, RelativeArea>.of(editor.areas));
  }

  Future<void> _copy(String json) async {
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calage copié')),
    );
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
            ),
          ),
          BackgroundImageSize(
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
            open: _panelOpen,
            json: editor.export(),
            overlapping: guilty,
            onToggle: () => setState(() => _panelOpen = !_panelOpen),
            onCopy: () => _copy(editor.export()),
            onClose: () => Navigator.of(context).pop(),
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

/// Le panneau du bas : le calage en clair, et de quoi l'emporter.
class _EditorPanel extends StatelessWidget {
  const _EditorPanel({
    required this.open,
    required this.json,
    required this.overlapping,
    required this.onToggle,
    required this.onCopy,
    required this.onClose,
  });

  final bool open;
  final String json;
  final Set<String> overlapping;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onClose;

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
                  onPressed: onToggle,
                  icon: Icon(
                    open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.white,
                  ),
                  tooltip: open ? 'Replier' : 'Déplier',
                ),
                const Expanded(
                  child: Text(
                    'Calage des zones',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(onPressed: onCopy, child: const Text('Copier')),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fermer',
                ),
              ],
            ),
            if (open) ...<Widget>[
              if (overlapping.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    'Zones qui se chevauchent : ${overlapping.join(', ')} — '
                    'le dépôt y serait ambigu.',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Text(
                  'Une zone cachée par le bandeau des mots est intouchable : '
                  'elle doit rester visible ici.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
