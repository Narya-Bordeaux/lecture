import 'dart:convert';
import 'dart:typed_data';

import 'package:grisbie/domain/repositories/content_file_not_found.dart';
import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/domain/repositories/content_store.dart';

/// Un dossier de contenu tenu en memoire.
///
/// Lit et ecrit au meme endroit, ce qui permet d'enregistrer puis de relire —
/// le seul controle qui prouve qu'un enregistrement est complet.
class MemoryContentFolder implements ContentStore {
  MemoryContentFolder([Map<String, String>? files])
      : files = <String, String>{...?files};

  final Map<String, String> files;

  /// Ce qui a ete ecrit en octets — une illustration, en pratique.
  final Map<String, Uint8List> bytes = <String, Uint8List>{};

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    // Une absence, et non une panne : c'est ce que `FallbackContentSource`
    // distingue, et les tests doivent se comporter comme le vrai dossier.
    if (contents == null) throw ContentFileNotFound(path);
    return contents;
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final written = bytes[path];
    if (written != null) return written;

    return Uint8List.fromList(utf8.encode(await readFile(path)));
  }

  @override
  Future<void> writeFile(String path, String contents) async {
    files[path] = contents;
  }

  @override
  Future<void> writeBytes(String path, Uint8List contents) async {
    bytes[path] = contents;
    // Le fichier existe, quelle que soit la façon dont on le relit.
    files[path] = '<${contents.length} octets>';
  }
}

/// Sert les fichiers d'un dossier, et recueille les ecritures dans un autre.
///
/// C'est la situation reelle de l'outil d'auteur : il lit le contenu livre,
/// scelle dans le bundle, et ecrit ailleurs.
class SplitContentFolder implements ContentSource, ContentSink {
  SplitContentFolder({required this.source, required this.written});

  final MemoryContentFolder source;
  final MemoryContentFolder written;

  @override
  Future<String> readFile(String path) => source.readFile(path);

  @override
  Future<Uint8List> readBytes(String path) => source.readBytes(path);

  @override
  Future<void> writeFile(String path, String contents) =>
      written.writeFile(path, contents);

  @override
  Future<void> writeBytes(String path, Uint8List contents) =>
      written.writeBytes(path, contents);
}
