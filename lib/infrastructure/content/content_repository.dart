import 'dart:convert';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/character.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';
import 'package:grisbie/domain/repositories/adventure_repository.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

/// Assemble une aventure a partir des fichiers de contenu.
///
/// Le chargement se fait en trois temps : le fichier pere dit ce qui existe,
/// les lexiques et les personnages sont lus une fois pour toutes, puis
/// l'aventure resout ses references. Une aventure ne contient donc que des
/// identifiants, jamais la definition d'un mot.
///
/// Volontairement sans dependance a Flutter : c'est [ContentSource] qui sait
/// d'ou viennent les fichiers.
class ContentRepository implements AdventureRepository {
  ContentRepository({required this.source, this.indexPath = 'index.json'});

  /// D'ou viennent les fichiers : les assets de l'application en jeu, le
  /// disque dans les tests.
  final ContentSource source;

  /// Le fichier pere, relatif au dossier du contenu.
  final String indexPath;

  ContentIndex? _index;
  Lexicon? _lexicon;
  WordListCatalog? _wordLists;
  Map<String, Character>? _characters;

  @override
  Future<ContentIndex> loadIndex() async {
    return _index ??= ContentIndex.fromJson(await _readJson(indexPath));
  }

  @override
  Future<Adventure> loadAdventure(String adventureId) async {
    final adventure = await loadDraft(adventureId);

    // Un contenu incoherent produirait un jeu bloque sans message : mieux vaut
    // echouer ici, avec la liste des problemes. Le fichier est nomme, et non
    // l'aventure : c'est lui que l'auteur doit ouvrir pour corriger.
    final issues = adventure.validate();
    if (issues.isNotEmpty) {
      final file = (await loadIndex()).findAdventure(adventureId)!.file;
      throw FormatException(
        'Contenu invalide dans "$file" :\n- ${issues.join('\n- ')}',
      );
    }

    return adventure;
  }

  /// La meme aventure, sans exiger qu'elle soit jouable.
  ///
  /// Une aventure en cours d'ecriture est incomplete par definition : le lieu
  /// qu'on vient de creer n'a pas ses mots, et la destination qu'on vient
  /// d'annoncer n'existe pas encore. [loadAdventure] la refuserait, et l'outil
  /// d'auteur ne pourrait jamais rouvrir ce qu'il vient d'enregistrer.
  ///
  /// Tolerer l'incomplet n'est pas tolerer n'importe quoi : un fichier absent
  /// du sommaire ou illisible echoue ici comme ailleurs. C'est `validate()`,
  /// et lui seul, qui n'est plus opposable — a l'appelant de le consulter et
  /// de montrer ce qu'il rapporte.
  Future<Adventure> loadDraft(String adventureId) async {
    final index = await loadIndex();
    final entry = index.findAdventure(adventureId);
    if (entry == null) {
      throw FormatException(
        'Aventure inconnue : "$adventureId". Le fichier "$indexPath" ne la '
        'declare pas.',
      );
    }

    final lists = await _loadWordLists(index);
    final characters = await _loadCharacters(index);

    final adventure = Adventure.fromJson(
      await _readJson(entry.file),
      lists: lists,
      characters: characters,
    );

    return adventure;
  }

  /// Les lexiques de tous les domaines, reunis une fois pour la session.
  Future<Lexicon> _loadLexicon(ContentIndex index) async {
    if (_lexicon != null) return _lexicon!;

    final lexicons = <Lexicon>[];
    for (final path in index.lexiconFiles) {
      lexicons.add(Lexicon.fromJson(await _readJson(path)));
    }
    return _lexicon = Lexicon.merge(lexicons);
  }

  /// Les listes de mots de tous les domaines, reunies une fois pour la session.
  ///
  /// Les mots sont resolus au passage : une liste cite le lexique, elle ne
  /// redefinit rien.
  Future<WordListCatalog> _loadWordLists(ContentIndex index) async {
    if (_wordLists != null) return _wordLists!;

    final lexicon = await _loadLexicon(index);
    final catalogs = <WordListCatalog>[];
    for (final path in index.wordListFiles) {
      catalogs.add(WordListCatalog.fromJson(await _readJson(path), lexicon));
    }
    return _wordLists = WordListCatalog.merge(catalogs);
  }

  Future<Map<String, Character>> _loadCharacters(ContentIndex index) async {
    if (_characters != null) return _characters!;

    final path = index.charactersFile;
    if (path == null) return _characters = const <String, Character>{};

    final json = await _readJson(path);
    final characters = <String, Character>{};
    for (final item in json['characters'] as List<dynamic>) {
      final character = Character.fromJson(item as Map<String, dynamic>);
      characters[character.id] = character;
    }
    return _characters = Map<String, Character>.unmodifiable(characters);
  }

  Future<Map<String, dynamic>> _readJson(String path) async {
    final raw = await source.readFile(path);
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException catch (error) {
      throw FormatException('JSON invalide dans "$path" : ${error.message}');
    }
  }
}
