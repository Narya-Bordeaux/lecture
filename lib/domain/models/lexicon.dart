import 'package:reading_game/domain/models/word.dart';

/// Le vocabulaire du jeu, chaque mot defini une seule fois.
///
/// Un meme mot sert dans plusieurs etapes — « gateau » vaut pour la boutique
/// d'une station-service comme pour un gouter. Le definir a chaque endroit
/// finirait par produire deux decoupages syllabiques differents du meme mot,
/// ce que l'enfant verrait. Ici il n'existe qu'une fois.
class Lexicon {
  const Lexicon(this.words);

  /// Reunit plusieurs lexiques, charges par domaine.
  ///
  /// Un identifiant present dans deux domaines est une erreur de contenu :
  /// rien ne dit laquelle des deux definitions serait la bonne.
  factory Lexicon.merge(Iterable<Lexicon> lexicons) {
    final merged = <String, Word>{};
    final duplicates = <String>[];

    for (final lexicon in lexicons) {
      for (final entry in lexicon.words.entries) {
        if (merged.containsKey(entry.key)) {
          duplicates.add(entry.key);
        }
        merged[entry.key] = entry.value;
      }
    }

    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Mots definis plusieurs fois dans le lexique : '
        '${duplicates.join(', ')}',
      );
    }

    return Lexicon(Map<String, Word>.unmodifiable(merged));
  }

  factory Lexicon.fromJson(Map<String, dynamic> json) {
    final words = <String, Word>{};
    final duplicates = <String>[];

    for (final item in json['words'] as List<dynamic>) {
      final word = Word.fromJson(item as Map<String, dynamic>);
      // Un doublon a l'interieur d'un meme fichier est le cas le plus
      // frequent — une ligne copiee puis mal reprise. Sans ce controle, la
      // seconde definition ecraserait la premiere sans rien dire.
      if (words.containsKey(word.id)) duplicates.add(word.id);
      words[word.id] = word;
    }

    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Mots definis plusieurs fois dans le domaine '
        '"${json['domain'] ?? 'sans nom'}" : ${duplicates.join(', ')}',
      );
    }

    return Lexicon(Map<String, Word>.unmodifiable(words));
  }

  static const Lexicon empty = Lexicon(<String, Word>{});

  final Map<String, Word> words;

  bool contains(String wordId) => words.containsKey(wordId);

  /// Le mot designe par [wordId], ou une erreur nommant le coupable.
  ///
  /// Une reference inconnue est une faute de frappe dans le contenu : mieux
  /// vaut echouer en la nommant que jouer une etape amputee d'un mot.
  Word resolve(String wordId) {
    final word = words[wordId];
    if (word == null) {
      throw FormatException('Mot inconnu dans le lexique : "$wordId"');
    }
    return word;
  }

  @override
  String toString() => 'Lexicon(${words.length} mots)';
}
