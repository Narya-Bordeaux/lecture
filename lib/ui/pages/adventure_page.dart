import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/ui/pages/adventure_opening_page.dart';
import 'package:grisbie/ui/pages/narration_page.dart';
import 'package:grisbie/ui/pages/stage_page.dart';
import 'package:grisbie/ui/strings/ui_strings_fr.dart';

/// Deroule une aventure : charge son contenu, puis enchaine les etapes au fil
/// des departs de l'enfant.
///
/// Un lieu de jeu s'ouvre directement sur sa scene : son texte d'arrivee y est
/// l'enonce, affiche au-dessus des mots. **Un lieu ne raconte pas son
/// depart** : l'enfant clique un trajet, et c'est le lieu suivant qui raconte.
class AdventurePage extends StatefulWidget {
  const AdventurePage({
    required this.repository,
    required this.adventureId,
    this.onFinished,
    super.key,
  });

  final AdventureRepository repository;
  final String adventureId;

  /// Appele depuis la fin, pour rendre la main a l'accueil du jeu.
  ///
  /// Nul, la fin propose de recommencer : c'est le cas de l'outil d'auteur,
  /// qui joue une aventure pour l'essayer, et n'a pas d'accueil ou revenir.
  final VoidCallback? onFinished;

  @override
  State<AdventurePage> createState() => _AdventurePageState();
}

class _AdventurePageState extends State<AdventurePage> {
  late Future<Adventure> _adventureLoading;
  String? _currentStageId;

  /// La page de garde ne se montre qu'une fois, au debut de l'aventure.
  bool _openingSeen = false;

  @override
  void initState() {
    super.initState();
    _adventureLoading = widget.repository.loadAdventure(widget.adventureId);
  }

  void _enterStage(String stageId) {
    setState(() => _currentStageId = stageId);
  }

  /// Recommencer, c'est refaire le voyage depuis le debut, page de garde
  /// comprise.
  void _restart(Adventure adventure) {
    setState(() {
      _openingSeen = false;
      _currentStageId = adventure.startStageId;
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

        return _buildStage(stage, adventure);
      },
    );
  }

  /// Une etape terminale n'a rien a classer : elle clot l'aventure.
  Widget _buildStage(Stage stage, Adventure adventure) {
    if (stage.isEnding) {
      final onFinished = widget.onFinished;
      return _TerminalStageView(
        stage: stage,
        actionLabel:
            onFinished == null ? UiStringsFr.startOver : UiStringsFr.backToHome,
        onAction: onFinished ?? () => _restart(adventure),
      );
    }

    return StagePage(
      // La cle force un etat neuf a chaque etape : sans elle, Flutter
      // reutiliserait l'etat de l'etape precedente.
      key: ValueKey<String>(stage.id),
      stage: stage,
      destinationNames: adventure.locationNames,
      // Rien ne s'intercale au depart : c'est le lieu d'arrivee qui raconte.
      onDeparture: _enterStage,
    );
  }
}

/// La fin : le nom du lieu, son illustration, son recit, et de quoi
/// revenir a l'accueil ou recommencer — sur l'ecran de lecture, comme la
/// page de garde.
class _TerminalStageView extends StatelessWidget {
  const _TerminalStageView({
    required this.stage,
    required this.actionLabel,
    required this.onAction,
  });

  final Stage stage;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return NarrationPage(
      title: stage.locationName,
      imagePath: stage.backgroundAsset,
      text: stage.narrative.onArrival ?? UiStringsFr.adventureEnd,
      actionLabel: actionLabel,
      onAction: onAction,
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
