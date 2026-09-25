import 'package:flutter/material.dart';
import 'package:grisbie/application/completion_message.dart';
import 'package:grisbie/domain/models/narrative.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/widgets/background_image_size.dart';
import 'package:grisbie/ui/widgets/completion_popup.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// Tous les textes d'un lieu, **chacun ecrit la ou l'enfant le lira**.
///
/// L'ecran deroule les ecrans du lieu dans l'ordre ou l'enfant les vit, en
/// « diapositives » : l'arrivee et son enonce, les boites posees sur
/// l'illustration a leur vraie place, puis le « Bravo ! » de chaque trajet et
/// son bouton de depart. Pour une fin, une seule : le titre, l'image, le
/// recit. L'auteur passait auparavant d'un ecran a l'autre pour savoir quel
/// texte paraitrait ou.
///
/// **Aucune case n'est pre-ecrite** (decision de l'auteur) : c'est de la
/// narration. Le « Bravo ! » et l'action de depart sont obligatoires, et
/// `validate()` signale ceux qui manquent.
///
/// Un lieu a la fois, et non l'aventure entiere : avec les boucles et les
/// directions, un deroule complet se perdrait.
///
/// Rend l'etape modifiee, ou `null` si l'auteur renonce. « Garder », comme
/// les autres editeurs : seul l'ecran du parcours enregistre.
class StageTextsPage extends StatefulWidget {
  const StageTextsPage({
    required this.stage,
    this.contentSource,
    super.key,
  });

  final Stage stage;

  /// D'ou lire l'illustration. Nulle, le bundle.
  final ContentSource? contentSource;

  /// Les cles des champs, pour les viser dans les tests.
  static const Key locationNameKey = ValueKey<String>('texts_location');
  static const Key onArrivalKey = ValueKey<String>('texts_on_arrival');
  static Key labelKeyFor(String familyId) =>
      ValueKey<String>('texts_label_$familyId');
  static Key completionKeyFor(String familyId) =>
      ValueKey<String>('texts_completion_$familyId');
  static Key departureKeyFor(String familyId) =>
      ValueKey<String>('texts_departure_$familyId');

  @override
  State<StageTextsPage> createState() => _StageTextsPageState();
}

class _StageTextsPageState extends State<StageTextsPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.stage.locationName);
  late final TextEditingController _onArrival =
      TextEditingController(text: widget.stage.narrative.onArrival ?? '');

  late final Map<String, TextEditingController> _labels = _controllers(
    (family) => family.label,
  );
  late final Map<String, TextEditingController> _completions = _controllers(
    (family) => family.completionText ?? '',
    onlyTrips: true,
  );
  late final Map<String, TextEditingController> _departures = _controllers(
    (family) => family.departureLabel ?? '',
    onlyTrips: true,
  );

  Map<String, TextEditingController> _controllers(
    String Function(WordFamily family) initial, {
    bool onlyTrips = false,
  }) {
    return <String, TextEditingController>{
      for (final family in widget.stage.families)
        if (!onlyTrips || family.leadsSomewhere)
          family.id: TextEditingController(text: initial(family)),
    };
  }

  @override
  void dispose() {
    _name.dispose();
    _onArrival.dispose();
    for (final controller in <TextEditingController>[
      ..._labels.values,
      ..._completions.values,
      ..._departures.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String? _orNull(TextEditingController? controller) {
    final text = controller?.text.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// L'etape telle qu'elle est en cours d'edition.
  ///
  /// Un nom vide garde l'ancien : un lieu ou une boite sans nom ne se
  /// liraient plus. **L'identifiant ne bouge pas** — il nait du nom puis s'en
  /// detache.
  Stage get _edited {
    return widget.stage.copyWith(
      locationName: _orNull(_name) ?? widget.stage.locationName,
      narrative: Narrative(onArrival: _orNull(_onArrival)),
      families: <WordFamily>[
        for (final family in widget.stage.families)
          _editedFamily(family),
      ],
    );
  }

  WordFamily _editedFamily(WordFamily family) {
    final completion = _orNull(_completions[family.id]);
    final departure = _orNull(_departures[family.id]);
    return family.copyWith(
      label: _orNull(_labels[family.id]) ?? family.label,
      completionText: completion,
      clearCompletionText: completion == null,
      departureLabel: departure,
      clearDepartureLabel: departure == null,
    );
  }

  /// Les champs changent ce que montrent les autres diapositives : le nom
  /// d'une boite reparait dans le titre de son « Bravo ! ».
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Les textes'),
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    key: StageTextsPage.locationNameKey,
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _refresh(),
                    decoration: InputDecoration(
                      labelText: 'Nom du lieu',
                      helperText: widget.stage.isEnding
                          ? 'L\'enfant le lit en titre de la fin.'
                          : 'Pour toi, dans l\'outil : l\'enfant ne le lit '
                              'pas ici.',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  ..._buildSlides(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSlides(BuildContext context) {
    switch (widget.stage.nature) {
      case StageNature.undefined:
        return <Widget>[
          const SizedBox(height: 24),
          Text(
            'Ce lieu n\'est pas encore défini : ses textes viendront quand '
            'tu auras dit ce que l\'enfant y fait.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ];
      case StageNature.ending:
        return <Widget>[_Slide(title: 'La fin', child: _buildEnding())];
      case StageNature.sorting:
      case StageNature.singleSort:
        final trips =
            widget.stage.families.where((family) => family.leadsSomewhere);
        var number = 3;
        return <Widget>[
          _Slide(title: '1 · En arrivant', child: _buildArrival()),
          _Slide(title: '2 · Les boîtes', child: _buildBoxes()),
          for (final family in trips)
            _Slide(
              title: '${number++} · Quand « '
                  '${_labels[family.id]!.text.trim()} » est pleine',
              child: _buildCompletion(family),
            ),
        ];
    }
  }

  /// L'illustration du lieu, en fond d'une diapositive.
  Widget _background({double dim = 0}) {
    final asset = widget.stage.backgroundAsset;
    final fallback = ColoredBox(
      color: widget.stage.backgroundColor == null
          ? const Color(0xFF4AB8FD)
          : Color(widget.stage.backgroundColor!),
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (asset == null)
          fallback
        else
          ContentImage(
            source: widget.contentSource,
            path: asset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => fallback,
          ),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
      ],
    );
  }

  /// L'enonce, dans la fenetre qui s'ouvre au centre en arrivant.
  Widget _buildArrival() {
    return _PhoneFrame(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _background(dim: 0.15),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _Card(
                child: _SlideField(
                  fieldKey: StageTextsPage.onArrivalKey,
                  controller: _onArrival,
                  hint: 'L\'énoncé : ce qui donne son sens au tri. '
                      'Facultatif.',
                  fontSize: 16,
                  minLines: 3,
                  onChanged: _refresh,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Le nom de chaque boite, pose sur l'illustration a la place de sa
  /// zone : l'auteur l'ecrit sur le bus, sur la voiture, sur le sentier.
  Widget _buildBoxes() {
    final placed =
        widget.stage.families.where((family) => family.area != null).toList();
    final unplaced =
        widget.stage.families.where((family) => family.area == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BackgroundImageSize(
          asset: widget.stage.backgroundAsset,
          source: widget.contentSource,
          builder: (context, imageSize) {
            final ratio = imageSize == null || imageSize.isEmpty
                ? 3 / 2
                : imageSize.width / imageSize.height;
            return _PhoneFrame(
              aspectRatio: ratio,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: <Widget>[
                      _background(),
                      for (final family in placed) ...<Widget>[
                        // Le cadre, puis l'intitule juste au-dessus, comme
                        // dans le jeu.
                        Positioned(
                          left: family.area!.left * width,
                          top: family.area!.top * height,
                          width: family.area!.width * width,
                          height: family.area!.height * height,
                          child: const _ZoneOutline(),
                        ),
                        _labelPositioned(
                          family: family,
                          width: width,
                          height: height,
                          child: _SlideField(
                            fieldKey: StageTextsPage.labelKeyFor(family.id),
                            controller: _labels[family.id]!,
                            hint: 'Nom de la boîte',
                            fontSize: 14,
                            bold: true,
                            onChanged: _refresh,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            );
          },
        ),
        if (unplaced.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Sans place sur l\'image — à caler dans l\'apparence :',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final family in unplaced)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _SlideField(
                fieldKey: StageTextsPage.labelKeyFor(family.id),
                controller: _labels[family.id]!,
                hint: 'Nom de la boîte',
                fontSize: 14,
                bold: true,
                onChanged: _refresh,
              ),
            ),
        ],
      ],
    );
  }

  /// Le champ du nom d'une boite, centre sur son cadre et juste au-dessus :
  /// assez large pour qu'on y ecrive, jamais hors de l'image.
  static Widget _labelPositioned({
    required WordFamily family,
    required double width,
    required double height,
    required Widget child,
  }) {
    final area = family.area!;
    final fieldWidth = (area.width * width + 40).clamp(130.0, width);
    final centre = (area.left + area.width / 2) * width;
    return Positioned(
      left: (centre - fieldWidth / 2).clamp(0.0, width - fieldWidth),
      top: (area.top * height - 40).clamp(0.0, height - 36),
      width: fieldWidth,
      child: child,
    );
  }

  /// Le « Bravo ! » d'un trajet, et son bouton de depart en bas.
  Widget _buildCompletion(WordFamily family) {
    return _PhoneFrame(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _background(dim: 0.25),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(44, 30, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  _Card(
                    borderColor: const Color(0xFF2E7D32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          CompletionMessage.bravo,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _SlideField(
                          fieldKey: StageTextsPage.completionKeyFor(family.id),
                          controller: _completions[family.id]!,
                          hint: 'Ce que l\'enfant lit quand la boîte est '
                              'pleine. Obligatoire.',
                          fontSize: 15,
                          minLines: 2,
                          onChanged: _refresh,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: -40,
                    top: -34,
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      CompletionPopup.badgeAsset,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Le bouton de depart, dans la barre du bas du jeu.
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xE6FFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D32), width: 2),
              ),
              child: _SlideField(
                fieldKey: StageTextsPage.departureKeyFor(family.id),
                controller: _departures[family.id]!,
                hint: 'Le bouton de départ, à l\'infinitif. Obligatoire.',
                fontSize: 15,
                bold: true,
                filled: const Color(0xFFDCEFDD),
                onChanged: _refresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// La fin : le nom du lieu en titre, l'illustration, le recit.
  Widget _buildEnding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          _name.text.trim(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (widget.stage.backgroundAsset != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 3 / 2, child: _background()),
          ),
        const SizedBox(height: 8),
        _SlideField(
          fieldKey: StageTextsPage.onArrivalKey,
          controller: _onArrival,
          hint: 'Le récit de fin, sous l\'image.',
          fontSize: 16,
          minLines: 4,
          onChanged: _refresh,
        ),
      ],
    );
  }
}

/// Une diapositive : son titre, et l'ecran tel que l'enfant le verra.
class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// Le cadre d'un ecran de telephone, aux proportions donnees.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.aspectRatio, required this.child});

  final double aspectRatio;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B1B1B), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: AspectRatio(aspectRatio: aspectRatio, child: child),
      ),
    );
  }
}

/// Une fenetre blanche du jeu, comme l'enonce ou le « Bravo ! ».
class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? const Color(0x331B1B1B),
          width: borderColor == null ? 1.5 : 2.5,
        ),
      ),
      child: child,
    );
  }
}

/// Le contour d'une zone de depot, tel que le jeu le pose sur le decor.
class _ZoneOutline extends StatelessWidget {
  const _ZoneOutline();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xB31B1B1B), width: 2),
        ),
      ),
    );
  }
}

/// Une case de texte posee dans une diapositive.
///
/// Vide, elle se voit : un fond jaune pale dit qu'il reste a ecrire ici.
class _SlideField extends StatelessWidget {
  const _SlideField({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.fontSize = 14,
    this.minLines = 1,
    this.bold = false,
    this.filled,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final double fontSize;
  final int minLines;
  final bool bold;
  final Color? filled;

  @override
  Widget build(BuildContext context) {
    final empty = controller.text.trim().isEmpty;
    return TextField(
      key: fieldKey,
      controller: controller,
      minLines: minLines,
      maxLines: minLines == 1 ? 2 : minLines + 3,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => onChanged(),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: const Color(0xFF1B1B1B),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintMaxLines: 3,
        filled: true,
        fillColor: empty
            ? const Color(0xFFFFF4C2)
            : (filled ?? const Color(0xF2FFFFFF)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
