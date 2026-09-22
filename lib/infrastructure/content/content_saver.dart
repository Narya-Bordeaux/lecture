import 'dart:convert';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/models/word_list.dart';
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
        ?index.charactersFile,
        for (final entry in index.adventures)
          if (entry.id != adventure.id) entry.file,
      ],
    ]) {
      await writer.copyFile(path, from: source);
      written.add(path);
    }

    final newLists = await _listsToWrite(index, adventure);
    final listsPath = 'lists/${adventure.id}.json';
    if (newLists.isNotEmpty) {
      await writer.writeWordLists(newLists, path: listsPath);
      written.add(listsPath);
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
    if (newLists.isNotEmpty) updated = updated.withWordListFile(listsPath);

    await writer.writeIndex(updated, path: indexPath);
    written.add(indexPath);

    return List<String>.unmodifiable(written);
  }

  /// Les listes de l'aventure que le contenu existant ne definit pas deja.
  ///
  /// Le catalogue est **global** — c'est ce qui rend une liste reutilisable
  /// d'un lieu et d'une aventure a l'autre. Reecrire ici une liste que le
  /// contenu livre definit deja en ferait un doublon, et le chargement
  /// refuserait le dossier entier.
  Future<List<WordList>> _listsToWrite(
    ContentIndex index,
    Adventure adventure,
  ) async {
    final declared = <String>{};
    for (final path in index.wordListFiles) {
      final json = jsonDecode(await source.readFile(path)) as Map<String, dynamic>;
      for (final item in json['lists'] as List<dynamic>? ?? <dynamic>[]) {
        declared.add((item as Map<String, dynamic>)['id'] as String);
      }
    }

    return adventure.wordLists
        .where((list) => !declared.contains(list.id))
        .toList(growable: false);
  }
}
