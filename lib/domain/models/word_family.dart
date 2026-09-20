import 'package:reading_game/domain/models/relative_area.dart';

/// Une famille de sens, et la direction qu'elle ouvre.
///
/// Dans ce jeu une famille n'est pas seulement une categorie : elle est aussi
/// une porte. La completer rend disponible la destination qui lui est associee.
class WordFamily {
  const WordFamily({
    required this.id,
    required this.label,
    required this.wordIds,
    required this.destinationStageId,
    this.area,
  });

  factory WordFamily.fromJson(Map<String, dynamic> json) {
    final area = json['area'];
    return WordFamily(
      id: json['id'] as String,
      label: json['label'] as String,
      wordIds: Set<String>.unmodifiable(
        (json['wordIds'] as List<dynamic>).cast<String>(),
      ),
      destinationStageId: json['destinationStageId'] as String,
      area: area == null
          ? null
          : RelativeArea.fromJson(area as Map<String, dynamic>),
    );
  }

  final String id;

  /// Nom affiche a l'enfant, par exemple « En train ».
  final String label;

  /// Les mots qui appartiennent a cette famille dans cette etape.
  final Set<String> wordIds;

  /// L'etape atteinte lorsque la famille est complete.
  final String destinationStageId;

  /// L'endroit de l'illustration ou poser la zone de depot, par exemple sur le
  /// bus. Absent pour une famille sans ancrage visuel.
  final RelativeArea? area;

  /// Vrai si ce mot appartient a la famille.
  bool accepts(String wordId) => wordIds.contains(wordId);

  WordFamily copyWith({
    String? id,
    String? label,
    Set<String>? wordIds,
    String? destinationStageId,
    RelativeArea? area,
  }) {
    return WordFamily(
      id: id ?? this.id,
      label: label ?? this.label,
      wordIds: wordIds ?? this.wordIds,
      destinationStageId: destinationStageId ?? this.destinationStageId,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'wordIds': wordIds.toList(),
      'destinationStageId': destinationStageId,
      if (area != null) 'area': area!.toJson(),
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
