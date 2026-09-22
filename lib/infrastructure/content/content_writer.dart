import 'dart:convert';

import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_index.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

/// Enregistre le contenu sous la forme exacte que le chargement relit.
///
/// Pendant symetrique de `ContentRepository`. Le format n'est pas redecrit
/// ici : chaque modele sait se serialiser, et ce sont les memes `toJson()` que
/// le jeu utilise deja. Une seconde description du format finirait par
/// diverger de celle qui est lue.
///
/// Volontairement sans dependance a Flutter : c'est [ContentSink] qui sait ou
/// vont les fichiers.
class ContentWriter {
  const ContentWriter({required this.sink});

  final ContentSink sink;

  /// Deux espaces d'indentation : le contenu doit rester relisible par un
  /// enseignant ou un parent, et c'est le point d'entree le plus accessible
  /// pour une contribution exterieure. Une seule longue ligne fermerait cette
  /// porte.
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');

  /// Ecrit l'aventure sous [path], relatif au dossier du contenu.
  ///
  /// Le lexique n'est pas touche : l'aventure ne cite que des mots, elle n'en
  /// definit aucun.
  Future<void> writeAdventure(
    Adventure adventure, {
    required String path,
  }) {
    return _write(path, adventure.toJson());
  }

  /// Ecrit un fichier de listes de mots.
  ///
  /// Les listes vivent a cote des aventures et non dedans : c'est ce qui leur
  /// permet de servir a plusieurs. Enregistrer une aventure suppose donc
  /// d'enregistrer aussi les listes qu'elle cite, sans quoi elle citerait des
  /// listes que personne n'a ecrites.
  Future<void> writeWordLists(
    Iterable<WordList> lists, {
    required String path,
  }) {
    return _write(path, <String, dynamic>{
      'lists': lists.map((list) => list.toJson()).toList(),
    });
  }

  /// Ecrit un fichier de contenu deja mis en forme par l'appelant.
  ///
  /// Sert a reecrire un lexique ou un fichier de listes en n'y remplacant
  /// que quelques entrees : le reste du fichier — son domaine, l'ordre de ses
  /// entrees — passe tel qu'il a ete lu.
  Future<void> writeJson(String path, Map<String, dynamic> json) {
    return _write(path, json);
  }

  /// Recopie un fichier d'un contenu a l'autre, sans le relire.
  ///
  /// Sert aux fichiers que l'outil ne sait pas produire — lexiques,
  /// personnages. Les charger pour les reecrire ferait courir le risque
  /// qu'une serialisation en perde un champ, et ces fichiers-la sont
  /// justement ceux que l'outil n'a aucune raison de toucher.
  Future<void> copyFile(String path, {required ContentSource from}) async {
    await sink.writeFile(path, await from.readFile(path));
  }

  /// Ecrit le fichier pere.
  ///
  /// Une aventure que le sommaire n'annonce pas est introuvable pour le jeu :
  /// creer une aventure suppose donc toujours de reecrire ce fichier.
  Future<void> writeIndex(
    ContentIndex index, {
    String path = 'index.json',
  }) {
    return _write(path, index.toJson());
  }

  /// Le fichier se termine par un saut de ligne, comme tout fichier texte :
  /// sans lui, git signale « no newline at end of file » a chaque
  /// enregistrement.
  Future<void> _write(String path, Object? json) {
    return sink.writeFile(path, '${_encoder.convert(json)}\n');
  }
}
