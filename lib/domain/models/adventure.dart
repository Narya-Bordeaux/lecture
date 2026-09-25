import 'package:grisbie/domain/models/adventure_opening.dart';
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
    this.coverAsset,
  });

  /// Construit l'aventure en resolvant ses listes.
  ///
  /// Une aventure ne contient que des references : elle cite des listes, qui
  /// citent des mots. Rien n'y est defini deux fois.
  factory Adventure.fromJson(
    Map<String, dynamic> json, {
    required WordListCatalog lists,
  }) {
    final stages = <String, Stage>{};
    for (final item in json['stages'] as List<dynamic>) {
      final stage = Stage.fromJson(
        item as Map<String, dynamic>,
        lists: lists,
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
      coverAsset: json['cover'] as String?,
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

  /// La vignette, qui represente l'aventure dans la roue de l'accueil.
  ///
  /// Une image a part, choisie pour cela, au format de `CoverFormat` — elle
  /// peut etre celle de la page de garde, si l'auteur le decide. Obligatoire
  /// pour jouer : l'accueil n'a jamais de carte vide. Le sommaire en garde une
  /// copie, comme du titre, pour que l'accueil n'ait que lui a lire.
  final String? coverAsset;

  /// Toutes les illustrations que l'aventure cite : vignette, page de garde
  /// et lieux, sans doublon.
  ///
  /// Ce que le depot doit contenir pour que le jeu les montre : une image
  /// citee mais absente donnerait un fond uni, sans rien pour le dire.
  Set<String> get picturePaths => <String>{
        ?coverAsset,
        ?opening?.imageAsset,
        for (final stage in stages.values) ?stage.backgroundAsset,
      };

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
      coverAsset: coverAsset,
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
      coverAsset: coverAsset,
      stages: stages,
    );
  }

  /// La meme aventure, avec cette vignette — ou sans, si elle est nulle.
  ///
  /// A part d'un `copyWith` pour la meme raison que [withOpening] : retirer
  /// une vignette doit etre possible.
  Adventure withCover(String? coverAsset) {
    return Adventure(
      id: id,
      title: title,
      startStageId: startStageId,
      opening: opening,
      coverAsset: coverAsset,
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
        for (final list in family.lists) {
          byId[list.id] = list;
        }
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

    if (coverAsset == null || coverAsset!.trim().isEmpty) {
      // Un manque et non une faute : c'est l'etat de toute aventure neuve.
      // Mais l'accueil du jeu montrerait une carte vide.
      issues.add(const ContentIssue.incomplete(
        'L\'aventure n\'a pas de vignette pour l\'accueil.',
      ));
    }

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

    issues.addAll(_validateLoops());

    return issues;
  }

  /// Les trajets qui ramenent a un lieu deja traverse.
  ///
  /// Un trajet de `s` vers `d` fait partie d'une boucle quand, depuis `d`, on
  /// peut revenir a `s`. Tous les trajets de la boucle sont nommes : c'est
  /// l'un d'eux que l'auteur voudra peut-etre rediriger, et rien ne dit
  /// lequel. **Un avertissement, jamais une faute** : rejoindre un lieu deja
  /// ecrit est permis, l'outil se contente de le montrer.
  List<ContentIssue> _validateLoops() {
    final issues = <ContentIssue>[];
    for (final stage in stages.values) {
      for (final family in stage.families) {
        final destination = family.destinationStageId;
        if (destination == null || !stages.containsKey(destination)) continue;
        if (!_canReach(destination, stage.id)) continue;

        final target = stages[destination]!.locationName;
        issues.add(ContentIssue.warning(
          'Le trajet "${family.label}" mene a "$target", d\'ou l\'on peut '
          'revenir ici : l\'enfant peut tourner en rond.',
          stageId: stage.id,
          familyId: family.id,
        ));
      }
    }
    return issues;
  }

  /// Vrai si un chemin mene de [from] a [to] — [from] compris.
  bool _canReach(String from, String to) {
    final seen = <String>{};
    final queue = <String>[from];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current == to) return true;
      if (!seen.add(current)) continue;
      final stage = stages[current];
      if (stage == null) continue;
      for (final family in stage.families) {
        final next = family.destinationStageId;
        if (next != null) queue.add(next);
      }
    }
    return false;
  }

  /// Jouable, incomplete ou fausse : ce que l'outil annonce en tete.
  ContentReadiness get readiness => ContentReadiness.of(validate());

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (coverAsset != null) 'cover': coverAsset,
      'startStageId': startStageId,
      if (opening != null) 'opening': opening!.toJson(),
      'stages': stages.values.map((stage) => stage.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Adventure($id)';
}
