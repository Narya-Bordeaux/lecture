import 'dart:convert';

import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/models/character.dart';
import 'package:reading_game/domain/models/content_index.dart';
import 'package:reading_game/domain/models/lexicon.dart';
import 'package:reading_game/domain/repositories/adventure_repository.dart';
import 'package:reading_game/domain/repositories/content_source.dart';

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
  Map<String, Character>? _characters;

  @override
  Future<ContentIndex> loadIndex() async {
    return _index ??= ContentIndex.fromJson(await _readJson(indexPath));
  }

  @override
  Future<Adventure> loadAdventure(String adventureId) async {
    final index = await loadIndex();
    final entry = index.findAdventure(adventureId);
    if (entry == null) {
      throw FormatException(
        'Aventure inconnue : "$adventureId". Le fichier "$indexPath" ne la '
        'declare pas.',
      );
    }

    final lexicon = await _loadLexicon(index);
    final characters = await _loadCharacters(index);

    final adventure = Adventure.fromJson(
      await _readJson(entry.file),
      lexicon: lexicon,
      characters: characters,
    );

    // Un contenu incoherent produirait un jeu bloque sans message : mieux vaut
    // echouer ici, avec la liste des problemes.
    final issues = adventure.validate();
    if (issues.isNotEmpty) {
      throw FormatException(
        'Contenu invalide dans "${entry.file}" :\n- ${issues.join('\n- ')}',
      );
    }

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
