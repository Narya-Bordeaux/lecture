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

    // **Tout ce qui manque encore part ensemble.** Le sommaire seul devait
    // arriver d'abord — c'est lui qui dit quels fichiers demander —, mais les
    // lexiques, les listes, les personnages et l'aventure sont independants a
    // la lecture. Demandes l'un apres l'autre, ils faisaient huit
    // allers-retours en file indienne : instantane sur un disque, plusieurs
    // secondes depuis un depot distant.
    // Ce qui est deja en memoire n'est pas redemande : rouvrir une aventure ne
    // relit que son fichier.
    final files = await _readJsonFiles(<String>{
      if (_wordLists == null) ...<String>[
        ...index.lexiconFiles,
        ...index.wordListFiles,
      ],
      if (_characters == null) ?index.charactersFile,
      entry.file,
    });

    return Adventure.fromJson(
      files[entry.file]!,
      lists: _resolveWordLists(index, files),
      characters: _resolveCharacters(index, files),
    );
  }

  /// Lit plusieurs fichiers **simultanement**, et les rend par chemin.
  ///
  /// Un fichier deja en memoire n'est pas redemande : l'appelant ne met dans
  /// [paths] que ce qui lui manque.
  Future<Map<String, Map<String, dynamic>>> _readJsonFiles(
    Set<String> paths,
  ) async {
    final ordered = paths.toList(growable: false);
    final contents = await Future.wait(ordered.map(_readJson));

    return <String, Map<String, dynamic>>{
      for (var index = 0; index < ordered.length; index++)
        ordered[index]: contents[index],
    };
  }

  /// Les listes de mots de tous les domaines, reunies une fois pour la session.
  ///
  /// Les mots sont resolus au passage : une liste cite le lexique, elle ne
  /// redefinit rien. C'est pour cela que les deux peuvent se **lire** ensemble
  /// — la resolution n'a lieu qu'a l'analyse.
  WordListCatalog _resolveWordLists(
    ContentIndex index,
    Map<String, Map<String, dynamic>> files,
  ) {
    if (_wordLists != null) return _wordLists!;

    final lexicon = _lexicon ??= Lexicon.merge(<Lexicon>[
      for (final path in index.lexiconFiles) Lexicon.fromJson(files[path]!),
    ]);

    return _wordLists = WordListCatalog.merge(<WordListCatalog>[
      for (final path in index.wordListFiles)
        WordListCatalog.fromJson(files[path]!, lexicon),
    ]);
  }

  Map<String, Character> _resolveCharacters(
    ContentIndex index,
    Map<String, Map<String, dynamic>> files,
  ) {
    if (_characters != null) return _characters!;

    final path = index.charactersFile;
    if (path == null) return _characters = const <String, Character>{};

    final characters = <String, Character>{};
    for (final item in files[path]!['characters'] as List<dynamic>) {
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
