import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

/// Une famille de sens, et la direction qu'elle ouvre.
///
/// Dans ce jeu une famille n'est pas seulement une categorie : elle est aussi
/// une porte. La completer rend disponible la destination qui lui est associee.
///
/// Une famille peut cependant n'ouvrir sur rien : c'est la **liste du reste**
/// d'un tri unique, ou l'enfant range ce qui n'est pas du theme.
///
/// **Elle ne porte pas ses mots, elle cite une liste.** Une [WordList] est
/// reutilisable et plus grande que la partie ; la famille dit ou cette liste se
/// pose ici, sous quel nom l'enfant la lit, et combien de ses mots entrent en
/// jeu.
class WordFamily {
  /// Une famille et la liste qu'elle cite — le cas courant.
  ///
  /// [lists] sert a la liste du reste d'un tri unique, qui puise dans
  /// plusieurs listes a la fois : exactement l'un des deux est donne.
  WordFamily({
    required this.id,
    required this.label,
    WordList? list,
    List<WordList>? lists,
    this.destinationStageId,
    this.area,
    this.goal,
    this.drawCount,
    this.completionText,
    this.departureLabel,
  })  : assert(
          (list == null) != (lists == null),
          'Une famille cite une liste, ou plusieurs — pas les deux.',
        ),
        lists = List<WordList>.unmodifiable(lists ?? <WordList>[list!]);

  /// Construit la famille en resolvant les listes qu'elle cite.
  ///
  /// `"list"` pour une seule, `"lists"` pour plusieurs : le contenu livre
  /// ecrit la premiere forme, et elle garde son sens.
  factory WordFamily.fromJson(
    Map<String, dynamic> json,
    WordListCatalog catalog,
  ) {
    final area = json['area'];
    final several = json['lists'] as List<dynamic>?;

    return WordFamily(
      id: json['id'] as String,
      label: json['label'] as String,
      list: several == null ? catalog.resolve(json['list'] as String) : null,
      lists: several
          ?.cast<String>()
          .map(catalog.resolve)
          .toList(growable: false),
      destinationStageId: json['destination'] as String?,
      area: area == null
          ? null
          : RelativeArea.fromJson(area as Map<String, dynamic>),
      goal: json['goal'] as int?,
      drawCount: json['drawCount'] as int?,
      completionText: json['completionText'] as String?,
      departureLabel: json['departureLabel'] as String?,
    );
  }

  final String id;

  /// Nom affiche a l'enfant, par exemple « En bus ».
  final String label;

  /// Les listes que cette famille cite.
  ///
  /// Une seule, d'ordinaire. Plusieurs pour la **liste du reste** d'un tri
  /// unique : l'auteur y coche les listes ou le jeu peut prendre les mots qui
  /// ne sont pas du theme. Aucune, tant qu'il ne les a pas choisies.
  ///
  /// Apres le tirage (`Stage.drawnWith`), une seule : la liste **en jeu ici**,
  /// reduite aux mots retenus pour cette partie.
  final List<WordList> lists;

  /// La liste dans laquelle cette famille puise : ses listes reunies.
  ///
  /// Un mot present dans deux listes citees n'y figure qu'une fois, a sa
  /// premiere place.
  WordList get list {
    if (lists.length == 1) return lists.single;

    final seen = <String>{};
    return WordList(
      id: lists.map((list) => list.id).join('+'),
      name: lists.map((list) => list.name).join(', '),
      words: List<Word>.unmodifiable(<Word>[
        for (final list in lists)
          for (final word in list.words)
            if (seen.add(word.text)) word,
      ]),
    );
  }

  /// L'etape atteinte lorsque la famille est complete, si elle mene quelque
  /// part. Nulle pour la liste du reste d'un tri unique.
  final String? destinationStageId;

  /// L'endroit de l'illustration ou poser la zone de depot, par exemple sur le
  /// bus. Absent pour une famille sans ancrage visuel.
  final RelativeArea? area;

  /// Combien de mots suffisent a ouvrir la destination, si moins que la liste
  /// entiere. Les listes sont pleines par defaut.
  final int? goal;

  /// Combien de mots de la liste entrent en jeu ici, si l'auteur le demande.
  ///
  /// Nul, la liste entiere joue — ce qui reste d'elle une fois les mots
  /// communs retires. Le defaut du lieu (`Stage.drawCount`) s'applique quand
  /// la famille ne dit rien.
  final int? drawCount;

  /// Ce que l'enfant lit sous « Bravo ! » quand il a range tous les mots de
  /// cette boite : « Tu as trouvé tous les mots « en voiture ». Tu peux
  /// prendre la voiture. »
  ///
  /// **Obligatoire sur un trajet qui mene quelque part**, et jamais pre-ecrit
  /// (decision de l'auteur) : c'est de la narration. Nul, `validate()` dit le
  /// trajet a finir. La liste du reste d'un tri unique n'en a pas : elle
  /// n'ouvre aucun chemin, et rien ne s'annonce.
  final String? completionText;

  /// L'action ecrite sur le bouton de depart, a l'infinitif : « Prendre la
  /// voiture », « Quitter le garage ».
  ///
  /// **Obligatoire sur un trajet qui mene quelque part.** Le bouton disait
  /// « Partir » suivi du nom de la boite : juste pour « En voiture », absurde
  /// pour un theme (« Partir les types de musique »), et il ne doit pas
  /// nommer le lieu d'arrivee, que l'enfant decouvre en y entrant.
  final String? departureLabel;

  /// Les mots de la liste citee.
  ///
  /// Derive, et non declare : un second endroit ou poser des mots finirait par
  /// diverger de la liste, et on ne saurait plus lequel fait foi.
  List<Word> get words => list.words;

  /// Vrai si completer cette famille ouvre un chemin.
  bool get leadsSomewhere => destinationStageId != null;

  /// Combien des deux textes obligatoires d'un trajet restent a ecrire : le
  /// « Bravo ! » et l'action de depart. Toujours zero pour la liste du reste,
  /// qui n'annonce rien et n'a pas de bouton.
  ///
  /// Un texte blanc compte comme absent : l'enfant ne lirait rien.
  int get missingTextCount =>
      (lacksCompletionText ? 1 : 0) + (lacksDepartureLabel ? 1 : 0);

  bool get lacksCompletionText => leadsSomewhere && _isBlank(completionText);

  bool get lacksDepartureLabel => leadsSomewhere && _isBlank(departureLabel);

  static bool _isBlank(String? text) => text == null || text.trim().isEmpty;

  Set<String> get wordTexts => list.wordTexts;

  /// Le nombre de mots reellement demande pour ouvrir la destination.
  int get requiredCount {
    final goal = this.goal;
    if (goal == null || goal > words.length) return words.length;
    return goal < 1 ? 1 : goal;
  }

  /// Vrai si ce mot appartient a la famille.
  bool accepts(String wordText) => list.contains(wordText);

  /// La meme famille, modifiee. [list] remplace toutes les listes citees par
  /// une seule ; [lists] les remplace par plusieurs.
  WordFamily copyWith({
    String? id,
    String? label,
    WordList? list,
    List<WordList>? lists,
    String? destinationStageId,
    RelativeArea? area,
    int? goal,
    int? drawCount,
    String? completionText,
    bool clearCompletionText = false,
    String? departureLabel,
    bool clearDepartureLabel = false,
  }) {
    return WordFamily(
      id: id ?? this.id,
      label: label ?? this.label,
      lists: lists ?? (list == null ? this.lists : <WordList>[list]),
      destinationStageId: destinationStageId ?? this.destinationStageId,
      area: area ?? this.area,
      goal: goal ?? this.goal,
      drawCount: drawCount ?? this.drawCount,
      // `??` ne sait pas effacer : vider un texte passe par les drapeaux.
      completionText: clearCompletionText
          ? null
          : completionText ?? this.completionText,
      departureLabel: clearDepartureLabel
          ? null
          : departureLabel ?? this.departureLabel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      if (lists.length == 1)
        'list': lists.single.id
      else
        'lists': lists.map((list) => list.id).toList(),
      if (destinationStageId != null) 'destination': destinationStageId,
      if (area != null) 'area': area!.toJson(),
      if (goal != null) 'goal': goal,
      if (drawCount != null) 'drawCount': drawCount,
      if (completionText != null) 'completionText': completionText,
      if (departureLabel != null) 'departureLabel': departureLabel,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is WordFamily &&
      other.id == id &&
      other.label == label &&
      other.destinationStageId == destinationStageId;

  @override
  int get hashCode => Object.hash(id, label, destinationStageId);

  @override
  String toString() => 'WordFamily($id)';
}
