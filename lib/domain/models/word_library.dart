import 'package:grisbie/domain/models/word_list_catalog.dart';

/// Toutes les listes deja ecrites, pour les reutiliser.
///
/// L'outil d'auteur s'en sert quand un trajet reprend une liste existante
/// plutot que d'en ecrire une nouvelle. Le jeu n'en a pas l'usage : il ne lit
/// que ce que son aventure cite.
class WordLibrary {
  const WordLibrary({this.lists = WordListCatalog.empty});

  static const WordLibrary empty = WordLibrary();

  final WordListCatalog lists;
}
