import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/ui/pages/adventure_opening_page.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/pages/story_moment_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

/// Les trois temps d'une etape.
enum _StagePhase {
  /// Le recit d'arrivee, avant de jouer.
  arrival,

  /// Le classement des mots.
  playing,

  /// Le recit de depart, avant le lieu suivant.
  completion,
}

/// Deroule une aventure : charge son contenu, puis enchaine les etapes au fil
/// des departs de l'enfant.
///
/// Chaque etape se joue en trois temps — recit d'arrivee, jeu, recit de
/// depart — les deux recits etant sautes quand l'etape n'en a pas.
class AdventurePage extends StatefulWidget {
  const AdventurePage({
    required this.repository,
    required this.adventureId,
    super.key,
  });

  final AdventureRepository repository;
  final String adventureId;

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  late Future<Adventure> _adventureLoading;
  String? _currentStageId;
  _StagePhase _phase = _StagePhase.arrival;

  /// La page de garde ne se montre qu'une fois, au debut de l'aventure.
  bool _openingSeen = false;

  /// Ou l'enfant part une fois le recit de depart lu.
  String? _pendingDestination;

  @override
  void initState() {
    super.initState();
    _adventureLoading = widget.repository.loadAdventure(widget.adventureId);
  }

  void _enterStage(String stageId) {
    setState(() {
      _currentStageId = stageId;
      _phase = _StagePhase.arrival;
      _pendingDestination = null;
    });
  }

  /// Recommencer, c'est refaire le voyage depuis le debut, page de garde
  /// comprise.
  void _restart(Adventure adventure) {
    setState(() {
      _openingSeen = false;
      _currentStageId = adventure.startStageId;
      _phase = _StagePhase.arrival;
      _pendingDestination = null;
    });
  }

  /// L'enfant quitte le lieu : le recit de depart s'intercale, s'il existe.
  void _leaveStage(Stage stage, String destination) {
    if (stage.narrative.onCompletion == null) {
      _enterStage(destination);
      return;
    }
    setState(() {
      _phase = _StagePhase.completion;
      _pendingDestination = destination;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Adventure>(
      future: _adventureLoading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _CenteredMessage(
            text: UiStringsFr.loadingFailed,
            // Le chargement produit des diagnostics precis — mot inconnu,
            // personnage absent, destination introuvable. Les cacher derriere
            // un message generique laisse chercher a l'aveugle, ce qui est
            // exactement ce qui est arrive avec des assets non declares.
            detail: '${snapshot.error}',
          );
        }
        final adventure = snapshot.data;
        if (adventure == null) {
          return const _CenteredMessage(text: UiStringsFr.loading);
        }

        final opening = adventure.opening;
        if (opening != null && !_openingSeen) {
          return AdventureOpeningPage(
            opening: opening,
            adventureTitle: adventure.title,
            onStart: () => setState(() => _openingSeen = true),
          );
        }

        final stage =
            adventure.findStage(_currentStageId ?? adventure.startStageId) ??
                adventure.startStage;

        return switch (_phase) {
          _StagePhase.arrival => _buildArrival(stage, adventure),
          _StagePhase.playing => _buildPlayingOrEnd(stage, adventure),
          _StagePhase.completion => _buildCompletion(stage, adventure),
        };
      },
    );
  }

  Widget _buildArrival(Stage stage, Adventure adventure) {
    final text = stage.narrative.onArrival;
    // Une etape terminale raconte deja son arrivee dans son propre ecran : la
    // doubler d'un moment de recit afficherait deux fois le meme texte.
    if (text == null || stage.isTerminal) {
      return _buildPlayingOrEnd(stage, adventure);
    }

    return StoryMomentPage(
      locationName: stage.locationName,
      text: text,
      backgroundAsset: stage.backgroundAsset,
      onContinue: () => setState(() => _phase = _StagePhase.playing),
    );
  }

  /// Une etape terminale n'a rien a classer : elle clot l'aventure.
  Widget _buildPlayingOrEnd(Stage stage, Adventure adventure) {
    if (stage.isTerminal) {
      return _TerminalStageView(
        stage: stage,
        onRestart: () => _restart(adventure),
      );
    }

    return StagePage(
      // La cle force un etat neuf a chaque etape : sans elle, Flutter
      // reutiliserait l'etat de l'etape precedente.
      key: ValueKey<String>(stage.id),
      stage: stage,
      onDeparture: (destination) => _leaveStage(stage, destination),
    );
  }

  Widget _buildCompletion(Stage stage, Adventure adventure) {
    final destination = _pendingDestination;
    final text = stage.narrative.onCompletion;
    if (destination == null || text == null) {
      return _buildPlayingOrEnd(stage, adventure);
    }

    return StoryMomentPage(
      locationName: stage.locationName,
      text: text,
      backgroundAsset: stage.backgroundAsset,
      onContinue: () => _enterStage(destination),
    );
  }
}

/// L'arrivee : le recit du lieu, et de quoi repartir.
class _TerminalStageView extends StatelessWidget {
  const _TerminalStageView({required this.stage, required this.onRestart});

  final Stage stage;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  stage.locationName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B1B),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stage.narrative.onArrival ?? UiStringsFr.adventureEnd,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.4,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: onRestart,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text(UiStringsFr.startOver),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.detail});

  final String text;

  /// Le detail technique, montre au developpeur seulement : l'enfant n'a que
  /// faire d'une pile d'appels, mais sans elle une panne se cherche a
  /// l'aveugle.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
                if (detail != null && kDebugMode) ...<Widget>[
                  const SizedBox(height: 20),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        detail!,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF8A3B3B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
