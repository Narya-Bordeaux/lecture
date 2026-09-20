import 'package:reading_game/domain/models/word.dart';
import 'package:reading_game/domain/models/word_family.dart';

/// Une etape du parcours : un lieu, des mots a classer, et les familles qui
/// ouvrent chacune vers un lieu suivant.
///
/// Une etape sans famille est terminale : le chat y arrive et l'aventure
/// s'arrete la.
class Stage {
  const Stage({
    required this.id,
    required this.locationName,
    required this.narrative,
    required this.words,
    required this.families,
  });

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      narrative: json['narrative'] as String,
      words: List<Word>.unmodifiable(
        (json['words'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => Word.fromJson(item as Map<String, dynamic>)),
      ),
      families: List<WordFamily>.unmodifiable(
        (json['families'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => WordFamily.fromJson(item as Map<String, dynamic>)),
      ),
    );
  }

  final String id;

  /// Le lieu ou se deroule l'etape, par exemple « La gare ».
  final String locationName;

  /// L'episode d'histoire affiche en arrivant.
  final String narrative;

  final List<Word> words;
  final List<WordFamily> families;

  /// Une etape sans famille clot le parcours.
  bool get isTerminal => families.isEmpty;

  Word? findWord(String wordId) {
    for (final word in words) {
      if (word.id == wordId) return word;
    }
    return null;
  }

  WordFamily? findFamily(String familyId) {
    for (final family in families) {
      if (family.id == familyId) return family;
    }
    return null;
  }

  /// Les incoherences de contenu, listees en clair.
  ///
  /// Le contenu pedagogique est destine a etre ecrit a la main, et a terme par
  /// des contributeurs exterieurs : mieux vaut un diagnostic precis qu'un
  /// comportement de jeu inexplicable.
  List<String> validate() {
    final issues = <String>[];
    final wordIds = words.map((word) => word.id).toList();

    for (final id in wordIds.toSet()) {
      if (wordIds.where((other) => other == id).length > 1) {
        issues.add('Le mot "$id" est declare plusieurs fois.');
      }
    }

    final assignedWordIds = <String, String>{};
    for (final family in families) {
      if (family.wordIds.isEmpty) {
        issues.add('La famille "${family.id}" ne contient aucun mot.');
      }
      for (final wordId in family.wordIds) {
        if (findWord(wordId) == null) {
          issues.add(
            'La famille "${family.id}" reference le mot inconnu "$wordId".',
          );
        }
        // Un mot classable dans deux familles de la meme etape est exactement
        // le « mot ambigu » que la specification proscrit.
        final owner = assignedWordIds[wordId];
        if (owner != null) {
          issues.add(
            'Le mot "$wordId" est ambigu : il appartient aux familles '
            '"$owner" et "${family.id}".',
          );
        }
        assignedWordIds[wordId] = family.id;
      }
    }

    for (final word in words) {
      if (!assignedWordIds.containsKey(word.id)) {
        issues.add('Le mot "${word.id}" n\'appartient a aucune famille.');
      }
      if (word.syllables.isEmpty) {
        issues.add('Le mot "${word.id}" n\'a pas de decoupage syllabique.');
      }
    }

    return issues;
  }

  Stage copyWith({
    String? id,
    String? locationName,
    String? narrative,
    List<Word>? words,
    List<WordFamily>? families,
  }) {
    return Stage(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      narrative: narrative ?? this.narrative,
      words: words ?? this.words,
      families: families ?? this.families,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'locationName': locationName,
      'narrative': narrative,
      'words': words.map((word) => word.toJson()).toList(),
      'families': families.map((family) => family.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Stage($id)';
}
