import 'package:reading_game/domain/models/stage.dart';

/// Une « journee » du chat Grisbie : un ensemble d'etapes reliees entre elles.
///
/// Les etapes forment un graphe et non une liste : une famille completee mene a
/// une etape, qui propose a son tour ses propres directions.
class Adventure {
  const Adventure({
    required this.id,
    required this.title,
    required this.startStageId,
    required this.stages,
  });

  factory Adventure.fromJson(Map<String, dynamic> json) {
    final stages = <String, Stage>{};
    for (final item in json['stages'] as List<dynamic>) {
      final stage = Stage.fromJson(item as Map<String, dynamic>);
      stages[stage.id] = stage;
    }

    return Adventure(
      id: json['id'] as String,
      title: json['title'] as String,
      startStageId: json['startStageId'] as String,
      stages: Map<String, Stage>.unmodifiable(stages),
    );
  }

  final String id;

  /// Titre affiche, par exemple « Grisbie va a la plage ».
  final String title;

  final String startStageId;

  /// Les etapes, indexees par identifiant.
  final Map<String, Stage> stages;

  Stage get startStage {
    final stage = stages[startStageId];
    if (stage == null) {
      throw StateError('L\'etape de depart "$startStageId" est introuvable.');
    }
    return stage;
  }

  Stage? findStage(String stageId) => stages[stageId];

  /// Les incoherences de contenu sur l'ensemble de l'aventure.
  List<String> validate() {
    final issues = <String>[];

    if (!stages.containsKey(startStageId)) {
      issues.add('L\'etape de depart "$startStageId" est introuvable.');
    }

    for (final stage in stages.values) {
      issues.addAll(stage.validate().map((issue) => '[${stage.id}] $issue'));

      for (final family in stage.families) {
        if (!stages.containsKey(family.destinationStageId)) {
          issues.add(
            '[${stage.id}] La famille "${family.id}" mene a l\'etape '
            'inconnue "${family.destinationStageId}".',
          );
        }
      }
    }

    // Une etape qu'aucun chemin n'atteint est du contenu mort : l'enfant ne la
    // verra jamais, et c'est presque toujours une erreur de saisie.
    final reachable = <String>{startStageId};
    for (final stage in stages.values) {
      for (final family in stage.families) {
        reachable.add(family.destinationStageId);
      }
    }
    for (final stageId in stages.keys) {
      if (!reachable.contains(stageId)) {
        issues.add('L\'etape "$stageId" n\'est atteignable par aucun chemin.');
      }
    }

    return issues;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startStageId': startStageId,
      'stages': stages.values.map((stage) => stage.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Adventure($id)';
}
