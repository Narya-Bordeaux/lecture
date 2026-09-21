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
  const WordFamily({
    required this.id,
    required this.label,
    required this.list,
    this.destinationStageId,
    this.area,
    this.goal,
    this.drawCount,
  });

  /// Construit la famille en resolvant la liste qu'elle cite.
  factory WordFamily.fromJson(
    Map<String, dynamic> json,
    WordListCatalog catalog,
  ) {
    final area = json['area'];

    return WordFamily(
      id: json['id'] as String,
      label: json['label'] as String,
      list: catalog.resolve(json['list'] as String),
      destinationStageId: json['destination'] as String?,
      area: area == null
          ? null
          : RelativeArea.fromJson(area as Map<String, dynamic>),
      goal: json['goal'] as int?,
      drawCount: json['drawCount'] as int?,
    );
  }

  final String id;

  /// Nom affiche a l'enfant, par exemple « En bus ».
  final String label;

  /// La liste de mots dans laquelle cette famille puise.
  ///
  /// Apres le tirage (`Stage.drawnWith`), c'est la liste **en jeu ici** :
  /// meme identifiant, mais reduite aux mots retenus pour cette partie.
  final WordList list;

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

  /// Les mots de la liste citee.
  ///
  /// Derive, et non declare : un second endroit ou poser des mots finirait par
  /// diverger de la liste, et on ne saurait plus lequel fait foi.
  List<Word> get words => list.words;

  /// Vrai si completer cette famille ouvre un chemin.
  bool get leadsSomewhere => destinationStageId != null;

  Set<String> get wordTexts => list.wordTexts;

  /// Le nombre de mots reellement demande pour ouvrir la destination.
  int get requiredCount {
    final goal = this.goal;
    if (goal == null || goal > words.length) return words.length;
    return goal < 1 ? 1 : goal;
  }

  /// Vrai si ce mot appartient a la famille.
  bool accepts(String wordText) => list.contains(wordText);

  WordFamily copyWith({
    String? id,
    String? label,
    WordList? list,
    String? destinationStageId,
    RelativeArea? area,
    int? goal,
    int? drawCount,
  }) {
    return WordFamily(
      id: id ?? this.id,
      label: label ?? this.label,
      list: list ?? this.list,
      destinationStageId: destinationStageId ?? this.destinationStageId,
      area: area ?? this.area,
      goal: goal ?? this.goal,
      drawCount: drawCount ?? this.drawCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'list': list.id,
      if (destinationStageId != null) 'destination': destinationStageId,
      if (area != null) 'area': area!.toJson(),
      if (goal != null) 'goal': goal,
      if (drawCount != null) 'drawCount': drawCount,
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
