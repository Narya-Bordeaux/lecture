import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:grisbie/application/stage_engine.dart';
import 'package:grisbie/application/stage_introduction.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';
import 'package:grisbie/ui/widgets/family_drop_zone.dart';
import 'package:grisbie/ui/widgets/family_intro_card.dart';
import 'package:grisbie/ui/widgets/scene_layout.dart';
import 'package:grisbie/ui/widgets/shake.dart';
import 'package:grisbie/ui/widgets/statement_popup.dart';
import 'package:grisbie/ui/widgets/word_label.dart';

/// L'ecran d'une etape : l'enonce, le decor, les mots a classer, les zones de
/// depot et les departs possibles.
///
/// **Un lieu se met en place avant de se jouer** ([StageIntroduction]) : le
/// decor seul, l'enonce au centre, puis le cartouche et chaque boite de
/// rangement presentee une a une. Les mots ne bougent qu'ensuite.
///
/// Cette page n'applique aucune regle. Elle transmet les gestes au
/// [StageEngine] et affiche l'etat qu'il renvoie. Toute tentation d'y decider
/// si un mot est bien place serait une duplication du moteur.
class StagePage extends StatefulWidget {
  const StagePage({
    required this.stage,
    required this.onDeparture,
    this.random,
    this.contentSource,
    this.interactive = true,
    this.sceneOverlayBuilder,
    super.key,
  });

  final Stage stage;

  /// Faux pour un apercu : la page s'affiche telle que l'enfant la verra, mais
  /// aucun geste n'y est transmis. C'est le cas de l'outil de calage, qui
  /// montre la scene deja en place, sans sa mise en place.
  final bool interactive;

  /// Un calque pose sur l'illustration, dans son repere — voir
  /// [SceneLayout.overlayBuilder]. Il recoit les gestes meme quand la page
  /// n'est pas [interactive] : ce sont les poignees de l'outil de calage.
  final Widget Function(Rect imageRect)? sceneOverlayBuilder;

  /// D'ou lire le contenu, illustrations comprises. Nulle, le bundle : c'est
  /// le cas du jeu. L'outil de calage y passe la source de travail, sans quoi
  /// l'apercu chercherait dans le bundle une image qui n'y est pas encore.
  final ContentSource? contentSource;

  /// Appele avec l'identifiant de l'etape choisie quand l'enfant part.
  final void Function(String stageId) onDeparture;

  final Random? random;

  /// Identifie le bandeau des mots, pour pouvoir le mesurer entierement dans
  /// les tests et verifier qu'il ne recouvre aucune zone de depot.
  static const Key wordTrayKey = ValueKey<String>('word_tray');

  @override
  State<StagePage> createState() => _StagePageState();
}

class _StagePageState extends State<StagePage> {
  late StageEngine _engine;
  late StageIntroduction _introduction;

  /// Le quart de seconde ou le decor se montre seul.
  Timer? _backgroundOnlyTimer;

  /// Une cle de secousse par mot, pour faire trembler la bonne etiquette.
  final Map<String, GlobalKey<ShakeState>> _shakeKeys =
      <String, GlobalKey<ShakeState>>{};

  @override
  void initState() {
    super.initState();
    _createEngine();
  }

  @override
  void didUpdateWidget(StagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Changer d'etape repart d'un moteur neuf : les erreurs et les aides
    // appartiennent a l'etape qu'on quitte.
    if (oldWidget.stage.id != widget.stage.id) {
      _createEngine();
    }
  }

  @override
  void dispose() {
    _backgroundOnlyTimer?.cancel();
    super.dispose();
  }

  void _createEngine() {
    _engine = StageEngine(stage: widget.stage, random: widget.random);
    _startIntroduction();
    _shakeKeys
      ..clear()
      ..addEntries(
        widget.stage.words.map(
          (word) => MapEntry(word.text, GlobalKey<ShakeState>()),
        ),
      );
  }

  /// Chaque lieu repart de sa mise en place — rejouer une journee comprise.
  void _startIntroduction() {
    _backgroundOnlyTimer?.cancel();
    if (!widget.interactive) {
      _introduction = StageIntroduction.skipped(widget.stage);
      return;
    }
    _introduction = StageIntroduction.forStage(widget.stage);
    _backgroundOnlyTimer = Timer(
      StageIntroduction.backgroundOnlyDuration,
      _advanceIntroduction,
    );
  }

  void _advanceIntroduction() {
    if (!mounted) return;
    setState(() => _introduction = _introduction.advance());
  }

  void _handleDrop({required String wordText, required String familyId}) {
    // Un mot deja pose n'est plus deplacable : la garde evite de solliciter le
    // moteur pour un geste que l'interface ne devrait pas permettre.
    if (_engine.state.placedWordTexts.contains(wordText)) return;

    final result = _engine.placeWord(wordText: wordText, familyId: familyId);
    if (!result.accepted) {
      _shakeKeys[wordText]?.currentState?.shake();
    }
    setState(() {});
  }

  /// Combien de mots la zone annonce : ceux de la partie tiree.
  int _requiredCountOf(WordFamily family) {
    return _engine.stage.findFamily(family.id)?.requiredCount ??
        family.requiredCount;
  }

  /// Le calque de la scene : la boite presentee, et les poignees de l'outil
  /// de calage quand il y en a.
  Widget _buildSceneOverlay(Rect imageRect) {
    final presentedId = _introduction.presentedFamilyId;
    final presented =
        presentedId == null ? null : widget.stage.findFamily(presentedId);
    final area = presented?.area;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (presented != null && area != null)
          FamilyIntroCard(
            // Une carte neuve par boite : chacune fait sa propre entree.
            key: ValueKey<String>('intro_${presented.id}'),
            family: presented,
            requiredCount: _requiredCountOf(presented),
            targetRect: Rect.fromLTWH(
              imageRect.left + area.left * imageRect.width,
              imageRect.top + area.top * imageRect.height,
              area.width * imageRect.width,
              area.height * imageRect.height,
            ),
            onPlaced: _advanceIntroduction,
          ),
        if (widget.sceneOverlayBuilder != null)
          widget.sceneOverlayBuilder!(imageRect),
      ],
    );
  }

  /// Les emplacements proposes par le moteur, vides compris.
  List<Word?> get _visibleSlots => _engine.visibleWords;

  List<Word> _wordsPlacedIn(String familyId) {
    return _engine.state.placements.entries
        .where((entry) => entry.value == familyId)
        .map((entry) => widget.stage.findWord(entry.key)!)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _engine.state.availableDestinations;

    final backgroundColor = widget.stage.backgroundColor == null
        ? const Color(0xFF4AB8FD)
        : Color(widget.stage.backgroundColor!);

    // **L'illustration occupe ce que le bandeau laisse** (option A, choisie
    // par l'auteur). Posee sous le bandeau, une zone ancree haut dans l'image
    // passait dessous des que l'enonce s'allongeait, et le doigt y etait
    // arrete sans rien pour le dire. Ici le recouvrement est impossible, quelle
    // que soit la longueur du texte ; l'image rapetisse d'autant sur un petit
    // ecran.
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Column(
            children: <Widget>[
              // **Le cartouche occupe sa place des le debut**, invisible
              // (option A, choisie par l'auteur) : l'illustration ne bouge
              // pas quand il parait. Les mots s'y lisent pendant la
              // presentation des boites, mais ne bougent qu'ensuite.
              SafeArea(
                bottom: false,
                child: IgnorePointer(
                  ignoring:
                      !widget.interactive || !_introduction.canMoveWords,
                  child: AnimatedOpacity(
                    opacity: _introduction.isTrayVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    child: _WordTray(
                      statement: widget.stage.narrative.onArrival,
                      slots: _visibleSlots,
                      shakeKeys: _shakeKeys,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SceneLayout(
                  backgroundAsset: widget.stage.backgroundAsset,
                  contentSource: widget.contentSource,
                  backgroundColor: backgroundColor,
                  // Le bas du decor porte le chemin : le caler au-dessus de la
                  // barre de navigation evite qu'il passe sous les boutons.
                  bottomInset: MediaQuery.paddingOf(context).bottom,
                  overlayBuilder: _buildSceneOverlay,
                  children: <SceneChild>[
                    for (final family in widget.stage.families)
                      if (family.area != null &&
                          _introduction.isFamilyPlaced(family.id))
                        SceneChild(
                          area: family.area!,
                          child: IgnorePointer(
                            ignoring: !widget.interactive,
                            child: FamilyDropZone(
                              // Le nom et la zone viennent du lieu de l'ecran
                              // — le calage les deplace sans relancer la
                              // partie ; le compte vient de la partie tiree.
                              family: family,
                              requiredCount: _requiredCountOf(family),
                              placedWords: _wordsPlacedIn(family.id),
                              isOpen: _engine.state.completedFamilyIds.contains(
                                family.id,
                              ),
                              onWordDropped: (wordText) => _handleDrop(
                                wordText: wordText,
                                familyId: family.id,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          if (_introduction.step == IntroductionStep.statement)
            SafeArea(
              child: StatementPopup(
                text: widget.stage.narrative.onArrival!,
                onClose: _advanceIntroduction,
              ),
            ),
          if (destinations.isNotEmpty && widget.interactive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: _DepartureBar(
                  destinations: destinations,
                  onDepart: widget.onDeparture,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// L'enonce et la grille des mots proposes, en haut de l'ecran.
///
/// **L'enonce donne son sens au tri** : il situe l'enfant et pose la question
/// que les mots vont trancher. Il se lit donc pendant qu'on trie, dans le meme
/// cartouche que les mots, et reste quand ils sont tous classes. Aucune
/// consigne generique ne l'accompagne : l'auteur l'a retiree, l'enonce disant
/// deja ce qu'il faut faire.
///
/// Chaque case correspond a un emplacement du moteur, et garde sa position :
/// un mot classe est remplace sur place par un mot de la reserve, les autres
/// ne bougent pas.
class _WordTray extends StatelessWidget {
  const _WordTray({
    required this.statement,
    required this.slots,
    required this.shakeKeys,
  });

  /// Trois colonnes : avec six emplacements, deux lignes pleines.
  static const int _columns = 3;

  /// Le texte d'arrivee du lieu, ou `null` s'il n'en a pas.
  final String? statement;

  final List<Word?> slots;
  final Map<String, GlobalKey<ShakeState>> shakeKeys;

  @override
  Widget build(BuildContext context) {
    final hasWords = slots.any((word) => word != null);
    if (!hasWords && statement == null) return const SizedBox.shrink();

    // La hauteur de ce bandeau est contrainte : les zones de depot sont
    // ancrees au decor, et la premiere — le bus — commence vers 29 % de la
    // hauteur. Un bandeau plus haut la recouvrirait et intercepterait le
    // doigt avant elle.
    return Container(
      key: StagePage.wordTrayKey,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x331B1B1B), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (statement != null)
            Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, hasWords ? 8 : 0),
              child: Text(
                statement!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B1B1B),
                ),
              ),
            ),
          if (hasWords)
            for (final row in _rows(slots))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (final word in row)
                      Expanded(
                        child: Center(
                          // Un emplacement vide garde sa place : la grille ne se
                          // reorganise pas sous les doigts de l'enfant.
                          child: word == null
                              ? const SizedBox.shrink()
                              : Shake(
                                  key: shakeKeys[word.text],
                                  child: DraggableWordLabel(word: word),
                                ),
                        ),
                      ),
                    for (var i = row.length; i < _columns; i++)
                      const Expanded(child: SizedBox.shrink()),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  List<List<Word?>> _rows(List<Word?> slots) {
    final rows = <List<Word?>>[];
    for (var start = 0; start < slots.length; start += _columns) {
      rows.add(slots.sublist(start, min(start + _columns, slots.length)));
    }
    return rows;
  }
}

/// Le bandeau de depart, en bas de l'ecran.
class _DepartureBar extends StatelessWidget {
  const _DepartureBar({required this.destinations, required this.onDepart});

  final List<AvailableDestination> destinations;
  final void Function(String stageId) onDepart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E7D32), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            UiStringsFr.destinationOpened,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: destinations
                .map(
                  (destination) => FilledButton(
                    onPressed: () => onDepart(destination.stageId),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      UiStringsFr.departTo(
                        destination.familyLabel.toLowerCase(),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
