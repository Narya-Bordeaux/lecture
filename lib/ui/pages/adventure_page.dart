import 'package:flutter/material.dart';
import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/models/stage.dart';
import 'package:reading_game/domain/repositories/adventure_repository.dart';
import 'package:reading_game/ui/pages/stage_page.dart';
import 'package:reading_game/ui/strings/ui_strings_fr.dart';

/// Deroule une aventure : charge son contenu, puis enchaine les etapes au fil
/// des departs de l'enfant.
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

  @override
  void initState() {
    super.initState();
    _adventureLoading = widget.repository.loadAdventure(widget.adventureId);
  }

  void _goTo(String stageId) => setState(() => _currentStageId = stageId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Adventure>(
      future: _adventureLoading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _CenteredMessage(text: UiStringsFr.loadingFailed);
        }
        final adventure = snapshot.data;
        if (adventure == null) {
          return const _CenteredMessage(text: UiStringsFr.loading);
        }

        final stage =
            adventure.findStage(_currentStageId ?? adventure.startStageId) ??
                adventure.startStage;

        if (stage.isTerminal) {
          return _TerminalStageView(
            stage: stage,
            onRestart: () => _goTo(adventure.startStageId),
          );
        }

        return StagePage(
          // La cle force un etat neuf a chaque etape : sans elle, Flutter
          // reutiliserait l'etat de l'etape precedente.
          key: ValueKey<String>(stage.id),
          stage: stage,
          onDeparture: _goTo,
        );
      },
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
                  stage.narrative,
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
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6E8),
      body: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, color: Color(0xFF3B3B3B)),
        ),
      ),
    );
  }
}
