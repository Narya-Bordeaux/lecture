import 'dart:convert';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/content_writer.dart';

/// Enregistre une aventure, **entierement**.
///
/// Ecrire le seul fichier d'aventure ne suffirait pas : il ne contient que des
/// references. Sans son sommaire il est introuvable, sans ses listes il cite
/// des listes que personne n'a ecrites, et sans le lexique ses listes citent
/// des mots inconnus. Un enregistrement partiel produirait un dossier qui ne se
/// recharge pas, et l'auteur ne le decouvrirait qu'a la relecture.
///
/// Le contenu livre est **scelle dans le bundle** : on lit d'un cote, on ecrit
/// de l'autre. Le dossier ecrit doit donc se suffire, ce qui suppose d'y
/// recopier ce que l'outil ne produit pas — lexiques et personnages.
class ContentSaver {
  const ContentSaver({
    required this.source,
    required this.writer,
    this.indexPath = 'index.json',
  });

  /// D'ou vient le contenu existant : le sommaire, les lexiques, les listes.
  final ContentSource source;

  final ContentWriter writer;

  final String indexPath;

  /// Ecrit l'aventure et tout ce dont elle a besoin. Rend les chemins touches.
  ///
  /// [includeUnchanged] recopie ce que l'outil n'a pas touche — lexiques,
  /// personnages, autres aventures — pour que le dossier ecrit se suffise.
  /// C'est ce qu'il faut sur un appareil, qui n'a rien d'autre.
  ///
  /// Le mettre a faux ne rend que **ce qui vient d'etre ecrit**. C'est ce qu'il
  /// faut quand la destination possede deja le reste : un depot, ou le dossier
  /// de telechargement d'un navigateur d'ou les fichiers seront reposes a la
  /// main. Recopier le lexique y serait au mieux inutile.
  Future<List<String>> save(
    Adventure adventure, {
    bool includeUnchanged = true,
  }) async {
    final index = ContentIndex.fromJson(
      jsonDecode(await source.readFile(indexPath)) as Map<String, dynamic>,
    );
    final written = <String>[];

    // Ce que l'outil ne touche pas passe tel quel : le relire pour le reecrire
    // ferait courir le risque qu'une serialisation en perde un champ.
    //
    // **Les autres aventures en font partie.** Le sommaire les declare ; sans
    // leurs fichiers, le dossier ecrit annoncerait des aventures introuvables,
    // et le defaut ne se verrait qu'en essayant d'en ouvrir une.
    for (final path in <String>[
      if (includeUnchanged) ...<String>[
        ...index.lexiconFiles,
        ...index.wordListFiles,
        for (final entry in index.adventures)
          if (entry.id != adventure.id) entry.file,
      ],
    ]) {
      await writer.copyFile(path, from: source);
      written.add(path);
    }

    // Les listes et les mots, chacun reecrit **la ou il vit**. Une liste ou
    // un mot deja defini ailleurs l'est une fois pour toutes : l'ecrire dans
    // un second fichier en ferait un doublon, et le chargement refuserait le
    // dossier entier.
    final listsPath = 'lists/${adventure.id}.json';
    final lexiconPath = 'lexicon/${adventure.id}.json';

    final listFiles = await _entriesByFile(
      index.wordListFiles,
      array: 'lists',
      key: 'id',
    );
    final lexiconFiles = await _entriesByFile(
      index.lexiconFiles,
      array: 'words',
      key: 'text',
    );

    final listPaths = listFiles.merge(
      ownPath: listsPath,
      ownTemplate: <String, dynamic>{'lists': <dynamic>[]},
      entries: <String, Map<String, dynamic>>{
        for (final list in adventure.wordLists) list.id: list.toJson(),
      },
    );
    final lexiconPaths = lexiconFiles.merge(
      ownPath: lexiconPath,
      ownTemplate: <String, dynamic>{
        'domain': adventure.id,
        'words': <dynamic>[],
      },
      entries: <String, Map<String, dynamic>>{
        for (final list in adventure.wordLists)
          for (final word in list.words) word.text: word.toJson(),
      },
    );

    for (final path in <String>[...listPaths, ...lexiconPaths]) {
      final json = listFiles.files[path] ?? lexiconFiles.files[path]!;
      await writer.writeJson(path, json);
      if (!written.contains(path)) written.add(path);
    }

    final adventurePath = 'adventures/${adventure.id}.json';
    await writer.writeAdventure(adventure, path: adventurePath);
    written.add(adventurePath);

    // Le sommaire en dernier : il annonce ce qui vient d'etre ecrit, et une
    // annonce sans fichier serait pire qu'un fichier sans annonce.
    var updated = index.withAdventure(AdventureEntry(
      id: adventure.id,
      title: adventure.title,
      file: adventurePath,
    ));
    if (listPaths.contains(listsPath)) {
      updated = updated.withWordListFile(listsPath);
    }
    if (lexiconPaths.contains(lexiconPath)) {
      updated = updated.withLexiconFile(lexiconPath);
    }

    await writer.writeIndex(updated, path: indexPath);
    written.add(indexPath);

    return List<String>.unmodifiable(written);
  }

  /// Les entrees de chaque fichier, lues pour savoir ou vit chaque liste et
  /// chaque mot.
  Future<_ContentFiles> _entriesByFile(
    List<String> paths, {
    required String array,
    required String key,
  }) async {
    final files = <String, Map<String, dynamic>>{};
    for (final path in paths) {
      files[path] =
          jsonDecode(await source.readFile(path)) as Map<String, dynamic>;
    }
    return _ContentFiles(
      files: files,
      array: array,
      key: key,
    );
  }
}

/// Des fichiers de contenu a tableau — lexiques ou listes — et leurs entrees.
///
/// Sait ou vit chaque entree, et reporte une modification **dans son
/// fichier**, en y laissant le reste tel qu'il a ete lu.
class _ContentFiles {
  _ContentFiles({
    required this.files,
    required this.array,
    required this.key,
  });

  /// Le contenu de chaque fichier, modifie sur place par [merge].
  final Map<String, Map<String, dynamic>> files;

  /// Le tableau qui porte les entrees : `lists` ou `words`.
  final String array;

  /// Ce qui identifie une entree : `id` pour une liste, `text` pour un mot.
  final String key;

  List<Map<String, dynamic>> _entriesOf(Map<String, dynamic> json) {
    return (json[array] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
  }

  /// Reporte [entries] dans les fichiers. Rend les chemins a reecrire.
  ///
  /// Une entree deja definie dans un fichier y est remplacee — et le fichier
  /// n'est reecrit que si elle a change. Une entree que nul ne definit va au
  /// fichier propre a l'aventure, [ownPath], cree d'apres [ownTemplate] s'il
  /// n'existe pas.
  ///
  /// **Le fichier propre garde ce qu'il avait** : une liste ecrite au premier
  /// enregistrement ne disparait pas parce qu'une autre s'ajoute au second.
  /// C'etait le defaut de la version precedente, qui le reecrivait avec les
  /// seules nouveautes.
  Set<String> merge({
    required String ownPath,
    required Map<String, dynamic> ownTemplate,
    required Map<String, Map<String, dynamic>> entries,
  }) {
    final declaredIn = <String, String>{
      for (final file in files.entries)
        for (final entry in _entriesOf(file.value))
          entry[key] as String: file.key,
    };

    final dirty = <String>{};
    for (final entry in entries.values) {
      final id = entry[key] as String;
      final path = declaredIn[id] ?? ownPath;
      final json = files.putIfAbsent(
        path,
        () => Map<String, dynamic>.of(ownTemplate)..[array] = <dynamic>[],
      );

      final existing = _entriesOf(json);
      final position = existing.indexWhere((each) => each[key] == id);
      if (position >= 0 && _same(existing[position], entry)) {
        continue;
      }

      final updated = List<dynamic>.of(existing);
      if (position >= 0) {
        // Seuls les champs que le modele connait sont remplaces : un champ
        // ajoute a la main dans le fichier n'est pas perdu.
        updated[position] = <String, dynamic>{
          ...existing[position],
          ...entry,
        };
      } else {
        updated.add(entry);
      }
      json[array] = updated;
      dirty.add(path);
    }

    return dirty;
  }

  /// Vrai si [written] ne change rien a ce que [existing] dit deja.
  static bool _same(
    Map<String, dynamic> existing,
    Map<String, dynamic> written,
  ) {
    return written.entries.every(
      (field) => jsonEncode(existing[field.key]) == jsonEncode(field.value),
    );
  }
}
