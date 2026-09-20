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
    this.backgroundAsset,
  });

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      narrative: json['narrative'] as String,
      backgroundAsset: json['backgroundAsset'] as String?,
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

  /// L'illustration de fond, sur laquelle les zones sont posees.
  final String? backgroundAsset;

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
      // Un mot dont le texte se retrouve dans le nom de sa famille se classe
      // en comparant les lettres, sans comprendre le sens : exactement ce que
      // le jeu cherche a faire travailler.
      final familyId = assignedWordIds[word.id];
      final family = familyId == null ? null : findFamily(familyId);
      if (family != null &&
          family.label.toLowerCase().contains(word.text.toLowerCase())) {
        issues.add(
          'Le mot "${word.text}" apparait dans le nom de sa famille '
          '"${family.label}" : il se classerait sans etre compris.',
        );
      }
    }

    issues.addAll(_validateAreas());

    return issues;
  }

  /// Verifie les zones de depot posees sur l'illustration.
  List<String> _validateAreas() {
    final issues = <String>[];
    final placed = <WordFamily>[];

    for (final family in families) {
      final area = family.area;
      if (area == null) continue;

      if (area.overflows) {
        issues.add(
          'La zone de la famille "${family.id}" deborde de l\'illustration.',
        );
      }
      for (final other in placed) {
        if (area.overlaps(other.area!)) {
          issues.add(
            'Les zones des familles "${other.id}" et "${family.id}" se '
            'chevauchent : le depot serait ambigu.',
          );
        }
      }
      placed.add(family);
    }

    return issues;
  }

  Stage copyWith({
    String? id,
    String? locationName,
    String? narrative,
    List<Word>? words,
    List<WordFamily>? families,
    String? backgroundAsset,
  }) {
    return Stage(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      narrative: narrative ?? this.narrative,
      words: words ?? this.words,
      families: families ?? this.families,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'locationName': locationName,
      'narrative': narrative,
      if (backgroundAsset != null) 'backgroundAsset': backgroundAsset,
      'words': words.map((word) => word.toJson()).toList(),
      'families': families.map((family) => family.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Stage($id)';
}
