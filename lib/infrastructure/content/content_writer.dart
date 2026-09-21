import 'dart:convert';

import 'package:reading_game/domain/models/adventure.dart';
import 'package:reading_game/domain/repositories/content_sink.dart';

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

  /// Le fichier se termine par un saut de ligne, comme tout fichier texte :
  /// sans lui, git signale « no newline at end of file » a chaque
  /// enregistrement.
  Future<void> _write(String path, Object? json) {
    return sink.writeFile(path, '${_encoder.convert(json)}\n');
  }
}
