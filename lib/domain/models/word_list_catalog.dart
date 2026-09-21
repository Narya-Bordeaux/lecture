import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/word_list.dart';

/// Les listes de mots disponibles, chacune definie une seule fois.
///
/// Pendant du [Lexicon], un etage plus haut : le lexique indexe les mots par
/// leur orthographe, ce catalogue indexe les listes par leur identifiant. Une
/// aventure ne contient donc que des references — `"list": "bus"` — et la meme
/// liste sert a plusieurs lieux, voire a plusieurs aventures.
class WordListCatalog {
  const WordListCatalog(this.lists);

  /// Reunit les fichiers de listes, charges par domaine.
  factory WordListCatalog.merge(Iterable<WordListCatalog> catalogs) {
    final merged = <String, WordList>{};
    final duplicates = <String>[];

    for (final catalog in catalogs) {
      for (final entry in catalog.lists.entries) {
        if (merged.containsKey(entry.key)) duplicates.add(entry.key);
        merged[entry.key] = entry.value;
      }
    }

    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Listes definies plusieurs fois : ${duplicates.join(', ')}',
      );
    }

    return WordListCatalog(Map<String, WordList>.unmodifiable(merged));
  }

  factory WordListCatalog.fromJson(
    Map<String, dynamic> json,
    Lexicon lexicon,
  ) {
    final lists = <String, WordList>{};
    final duplicates = <String>[];

    for (final item in json['lists'] as List<dynamic>? ?? <dynamic>[]) {
      final list = WordList.fromJson(item as Map<String, dynamic>, lexicon);
      // Un doublon a l'interieur d'un meme fichier est le cas le plus
      // frequent : une liste copiee puis mal renommee. Sans ce controle, la
      // seconde ecraserait la premiere en silence, et des mots disparaitraient
      // du jeu sans que rien ne le dise.
      if (lists.containsKey(list.id)) duplicates.add(list.id);
      lists[list.id] = list;
    }

    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Listes definies plusieurs fois dans le fichier '
        '"${json['domain'] ?? 'sans nom'}" : ${duplicates.join(', ')}',
      );
    }

    return WordListCatalog(Map<String, WordList>.unmodifiable(lists));
  }

  static const WordListCatalog empty = WordListCatalog(<String, WordList>{});

  final Map<String, WordList> lists;

  bool contains(String listId) => lists.containsKey(listId);

  /// La liste designee par [listId], ou une erreur la nommant.
  ///
  /// Une reference inconnue est une faute de frappe dans le contenu, ou une
  /// liste qu'on a oublie de declarer au sommaire. Mieux vaut echouer en la
  /// nommant que jouer un lieu ampute d'une famille.
  WordList resolve(String listId) {
    final list = lists[listId];
    if (list == null) {
      throw FormatException('Liste inconnue : "$listId"');
    }
    return list;
  }

  @override
  String toString() => 'WordListCatalog(${lists.length} listes)';
}
