import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/relative_area.dart';
import 'package:grisbie/domain/models/word.dart';

/// Une famille de sens, et la direction qu'elle ouvre.
///
/// Dans ce jeu une famille n'est pas seulement une categorie : elle est aussi
/// une porte. La completer rend disponible la destination qui lui est associee.
///
/// Une famille peut cependant n'ouvrir sur rien : c'est le cas du classeur de
/// rebut d'une enigme — « garde-le » — ou l'enfant range ce qui ne repond pas
/// a la question posee.
class WordFamily {
  const WordFamily({
    required this.id,
    required this.label,
    required this.words,
    this.destinationStageId,
    this.area,
    this.goal,
  });

  /// Construit la famille en resolvant ses mots dans le lexique.
  factory WordFamily.fromJson(Map<String, dynamic> json, Lexicon lexicon) {
    final area = json['area'];
    final wordTexts = (json['words'] as List<dynamic>).cast<String>();

    return WordFamily(
      id: json['id'] as String,
      label: json['label'] as String,
      words: List<Word>.unmodifiable(wordTexts.map(lexicon.resolve)),
      destinationStageId: json['destination'] as String?,
      area: area == null
          ? null
          : RelativeArea.fromJson(area as Map<String, dynamic>),
      goal: json['goal'] as int?,
    );
  }

  final String id;

  /// Nom affiche a l'enfant, par exemple « En bus ».
  final String label;

  /// Les mots qui appartiennent a cette famille dans cette etape.
  final List<Word> words;

  /// L'etape atteinte lorsque la famille est complete, si elle mene quelque
  /// part. Nulle pour un classeur sans issue.
  final String? destinationStageId;

  /// L'endroit de l'illustration ou poser la zone de depot, par exemple sur le
  /// bus. Absent pour une famille sans ancrage visuel.
  final RelativeArea? area;

  /// Combien de mots suffisent a ouvrir la destination, si moins que la liste
  /// entiere. Les listes sont pleines par defaut.
  final int? goal;

  /// Vrai si completer cette famille ouvre un chemin.
  bool get leadsSomewhere => destinationStageId != null;

  Set<String> get wordTexts => words.map((word) => word.text).toSet();

  /// Le nombre de mots reellement demande pour ouvrir la destination.
  int get requiredCount {
    final goal = this.goal;
    if (goal == null || goal > words.length) return words.length;
    return goal < 1 ? 1 : goal;
  }

  /// Vrai si ce mot appartient a la famille.
  bool accepts(String wordText) => words.any((word) => word.text == wordText);

  WordFamily copyWith({
    String? id,
    String? label,
    List<Word>? words,
    String? destinationStageId,
    RelativeArea? area,
    int? goal,
  }) {
    return WordFamily(
      id: id ?? this.id,
      label: label ?? this.label,
      words: words ?? this.words,
      destinationStageId: destinationStageId ?? this.destinationStageId,
      area: area ?? this.area,
      goal: goal ?? this.goal,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'words': words.map((word) => word.text).toList(),
      if (destinationStageId != null) 'destination': destinationStageId,
      if (area != null) 'area': area!.toJson(),
      if (goal != null) 'goal': goal,
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
