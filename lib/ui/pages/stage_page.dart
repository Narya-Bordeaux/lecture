import 'dart:math';

import 'package:flutter/material.dart';
import 'package:reading_game/application/stage_engine.dart';
import 'package:reading_game/domain/models/hint.dart';
import 'package:reading_game/domain/models/hint_policy.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';
import 'package:reading_game/ui/widgets/family_drop_zone.dart';
import 'package:reading_game/ui/widgets/scene_layout.dart';
import 'package:reading_game/ui/widgets/shake.dart';
import 'package:reading_game/ui/widgets/word_label.dart';

/// L'ecran d'une etape : le decor, les mots a classer, les zones de depot et
/// les departs possibles.
///
/// Cette page n'applique aucune regle. Elle transmet les gestes au
/// [StageEngine] et affiche l'etat qu'il renvoie. Toute tentation d'y decider
/// si un mot est bien place serait une duplication du moteur.
class StagePage extends StatefulWidget {
  const StagePage({
    required this.stage,
    required this.onDeparture,
    this.hintPolicy = const HintPolicy(),
    this.random,
    super.key,
  });

  final Stage stage;

  /// Appele avec l'identifiant de l'etape choisie quand l'enfant part.
  final void Function(String stageId) onDeparture;

  final HintPolicy hintPolicy;
  final Random? random;

  /// Identifie le bandeau des mots, pour pouvoir le mesurer entierement dans
  /// les tests et verifier qu'il ne recouvre aucune zone de depot.
  static const Key wordTrayKey = ValueKey<String>('word_tray');

  @override
  State<StagePage> createState() => _StagePageState();
}

class _StagePageState extends State<StagePage> {
  late StageEngine _engine;

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

  void _createEngine() {
    _engine = StageEngine(
      stage: widget.stage,
      hintPolicy: widget.hintPolicy,
      random: widget.random,
    );
    _shakeKeys
      ..clear()
      ..addEntries(
        widget.stage.words.map(
          (word) => MapEntry(word.id, GlobalKey<ShakeState>()),
        ),
      );
  }

  void _handleDrop({required String wordId, required String familyId}) {
    // Un mot deja pose n'est plus deplacable : la garde evite de solliciter le
    // moteur pour un geste que l'interface ne devrait pas permettre.
    if (_engine.state.placedWordIds.contains(wordId)) return;

    final result = _engine.placeWord(wordId: wordId, familyId: familyId);
    if (!result.accepted) {
      _shakeKeys[wordId]?.currentState?.shake();
    }
    setState(() {});
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

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SceneLayout(
            backgroundAsset: widget.stage.backgroundAsset,
            backgroundColor: widget.stage.backgroundColor == null
                ? const Color(0xFF4AB8FD)
                : Color(widget.stage.backgroundColor!),
            children: <SceneChild>[
              for (final family in widget.stage.families)
                if (family.area != null)
                  SceneChild(
                    area: family.area!,
                    child: FamilyDropZone(
                      family: family,
                      placedWords: _wordsPlacedIn(family.id),
                      isOpen: _engine.state.completedFamilyIds.contains(
                        family.id,
                      ),
                      onWordDropped: (wordId) => _handleDrop(
                        wordId: wordId,
                        familyId: family.id,
                      ),
                    ),
                  ),
            ],
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                _WordTray(
                  slots: _visibleSlots,
                  hintsFor: _engine.state.hintsFor,
                  shakeKeys: _shakeKeys,
                  // Quand un personnage pose la question, sa replique tient
                  // lieu de consigne : elle dit ce qu'il faut faire, et mieux
                  // qu'une invitation generique.
                  invitation: widget.stage.encounter?.line,
                ),
                const Spacer(),
                if (destinations.isNotEmpty)
                  _DepartureBar(
                    destinations: destinations,
                    onDepart: widget.onDeparture,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La grille des mots proposes, en haut de l'ecran.
///
/// Chaque case correspond a un emplacement du moteur, et garde sa position :
/// un mot classe est remplace sur place par un mot de la reserve, les autres
/// ne bougent pas.
class _WordTray extends StatelessWidget {
  const _WordTray({
    required this.slots,
    required this.hintsFor,
    required this.shakeKeys,
    this.invitation,
  });

  /// Trois colonnes : avec six emplacements, deux lignes pleines.
  static const int _columns = 3;

  final List<Word?> slots;
  final Set<Hint> Function(String wordId) hintsFor;
  final Map<String, GlobalKey<ShakeState>> shakeKeys;

  /// La consigne affichee au-dessus des mots. Par defaut une invitation
  /// generique, remplacee par la replique du personnage lors d'une rencontre.
  final String? invitation;

  @override
  Widget build(BuildContext context) {
    if (slots.every((word) => word == null)) return const SizedBox.shrink();

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
          Text(
            invitation ?? UiStringsFr.dragInvitation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 6),
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
                                key: shakeKeys[word.id],
                                child: DraggableWordLabel(
                                  word: word,
                                  hints: hintsFor(word.id),
                                ),
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
