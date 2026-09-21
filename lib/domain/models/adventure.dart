import 'package:grisbie/domain/models/adventure_opening.dart';
import 'package:grisbie/domain/models/character.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

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
    this.opening,
  });

  /// Construit l'aventure en resolvant listes et personnages.
  ///
  /// Une aventure ne contient que des references : elle cite des listes, qui
  /// citent des mots. Rien n'y est defini deux fois.
  factory Adventure.fromJson(
    Map<String, dynamic> json, {
    required WordListCatalog lists,
    required Map<String, Character> characters,
  }) {
    final stages = <String, Stage>{};
    for (final item in json['stages'] as List<dynamic>) {
      final stage = Stage.fromJson(
        item as Map<String, dynamic>,
        lists: lists,
        characters: characters,
      );
      stages[stage.id] = stage;
    }

    final opening = json['opening'] as Map<String, dynamic>?;

    return Adventure(
      id: json['id'] as String,
      title: json['title'] as String,
      startStageId: json['startStageId'] as String,
      stages: Map<String, Stage>.unmodifiable(stages),
      opening: opening == null ? null : AdventureOpening.fromJson(opening),
    );
  }

  final String id;

  /// Titre affiche, par exemple « Grisbie va a la plage ».
  final String title;

  final String startStageId;

  /// Les etapes, indexees par identifiant.
  final Map<String, Stage> stages;

  /// La page de garde, montree une fois avant le premier lieu.
  final AdventureOpening? opening;

  Stage get startStage {
    final stage = stages[startStageId];
    if (stage == null) {
      throw StateError('L\'etape de depart "$startStageId" est introuvable.');
    }
    return stage;
  }

  Stage? findStage(String stageId) => stages[stageId];

  /// La meme aventure, ce lieu remplace.
  ///
  /// L'outil d'auteur travaille en memoire et rend l'aventure modifiee ;
  /// reconstruire l'aventure a la main a chaque edition en perdrait un champ
  /// le jour ou il s'en ajoute un.
  ///
  /// Le lieu doit exister : un identifiant mal repris ajouterait un lieu
  /// fantome au lieu d'en corriger un, et l'auteur ne verrait sa faute que
  /// bien plus tard. C'est aussi ce qui tient bon au renommage : l'identifiant
  /// ne suit pas le nom, le lieu rebaptise garde donc sa place.
  Adventure withStage(Stage stage) {
    if (!stages.containsKey(stage.id)) {
      throw StateError('Lieu inconnu : "${stage.id}".');
    }

    return Adventure(
      id: id,
      title: title,
      startStageId: startStageId,
      opening: opening,
      stages: Map<String, Stage>.unmodifiable(
        Map<String, Stage>.of(stages)..[stage.id] = stage,
      ),
    );
  }

  /// La meme aventure, avec cette page de garde — ou sans, si elle est nulle.
  ///
  /// Une methode a part plutot qu'un `copyWith` : `??` ne saurait pas en
  /// retirer une, alors que renoncer a la page de garde est un geste legitime.
  Adventure withOpening(AdventureOpening? opening) {
    return Adventure(
      id: id,
      title: title,
      startStageId: startStageId,
      opening: opening,
      stages: stages,
    );
  }

  /// Les lieux qui closent le parcours.
  ///
  /// Une fin porte un ecran, une illustration et un texte : plusieurs chemins
  /// qui aboutissent au meme endroit ont tout interet a partager la meme,
  /// plutot que d'en ecrire deux identiques. L'outil d'auteur s'en sert pour
  /// proposer celles qui existent deja.
  List<Stage> get endings {
    return List<Stage>.unmodifiable(
      stages.values.where((stage) => stage.isEnding),
    );
  }

  /// Les listes que cette aventure cite, chacune une fois.
  ///
  /// Derivees des familles, et non declarees a part : une aventure qui
  /// annoncerait ses listes en tete finirait par en annoncer une qu'elle
  /// n'emploie plus. C'est ce qu'il faut enregistrer a cote d'elle.
  List<WordList> get wordLists {
    final byId = <String, WordList>{};
    for (final stage in stages.values) {
      for (final family in stage.families) {
        byId[family.list.id] = family.list;
      }
    }
    return List<WordList>.unmodifiable(byId.values);
  }

  /// Les incoherences de contenu sur l'ensemble de l'aventure.
  ///
  /// Chaque anomalie dit si elle est fausse ou seulement incomplete — voir
  /// [IssueSeverity]. Une aventure jouable n'en presente aucune.
  List<ContentIssue> validate() {
    final issues = <ContentIssue>[];

    if (!stages.containsKey(startStageId)) {
      // Sans point d'entree, l'aventure ne s'ouvre pas du tout. Aucun lieu
      // existant n'est en cause, d'ou l'absence de `stageId`.
      issues.add(ContentIssue.wrong(
        'L\'etape de depart "$startStageId" est introuvable.',
      ));
    }

    for (final stage in stages.values) {
      issues.addAll(stage.validate());

      for (final family in stage.families) {
        final destination = family.destinationStageId;
        if (destination != null && !stages.containsKey(destination)) {
          // Ecrire « le bus va au marche » puis creer le marche est une facon
          // normale d'avancer. Une promesse pas encore tenue et une faute de
          // frappe sont de toute facon indiscernables : les traiter en faute
          // interdirait d'ecrire le parcours dans l'ordre ou il se raconte.
          issues.add(ContentIssue.incomplete(
            'La famille "${family.id}" mene a l\'etape inconnue '
            '"$destination".',
            stageId: stage.id,
            familyId: family.id,
          ));
        }
      }
    }

    // Une etape qu'aucun chemin n'atteint est du contenu mort dans une
    // aventure finie. Mais un lieu ecrit avant d'etre relie l'est aussi :
    // c'est du travail restant, pas une faute.
    final reachable = <String>{startStageId};
    for (final stage in stages.values) {
      for (final family in stage.families) {
        final destination = family.destinationStageId;
        if (destination != null) reachable.add(destination);
      }
    }
    for (final stageId in stages.keys) {
      if (!reachable.contains(stageId)) {
        issues.add(ContentIssue.incomplete(
          'Cette etape n\'est atteignable par aucun chemin.',
          stageId: stageId,
        ));
      }
    }

    return issues;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startStageId': startStageId,
      if (opening != null) 'opening': opening!.toJson(),
      'stages': stages.values.map((stage) => stage.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Adventure($id)';
}
