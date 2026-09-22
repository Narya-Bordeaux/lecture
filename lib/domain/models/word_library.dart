import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

/// Tout le vocabulaire deja ecrit : le lexique et les listes.
///
/// L'outil d'auteur en a besoin pour deux gestes. **Reutiliser une liste**
/// existante plutot que la reecrire, et **retrouver un mot** deja defini —
/// son decoupage ne se tape qu'une fois, puisque le lexique n'en admet qu'un.
///
/// Le jeu n'en a pas l'usage : il ne lit que ce que son aventure cite.
class WordLibrary {
  const WordLibrary({
    this.lexicon = Lexicon.empty,
    this.lists = WordListCatalog.empty,
  });

  static const WordLibrary empty = WordLibrary();

  final Lexicon lexicon;
  final WordListCatalog lists;
}
