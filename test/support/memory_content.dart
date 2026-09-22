import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

/// Un dossier de contenu tenu en memoire.
///
/// Lit et ecrit au meme endroit, ce qui permet d'enregistrer puis de relire —
/// le seul controle qui prouve qu'un enregistrement est complet.
class MemoryContentFolder implements ContentSource, ContentSink {
  MemoryContentFolder([Map<String, String>? files])
      : files = <String, String>{...?files};

  final Map<String, String> files;

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    if (contents == null) throw StateError('Fichier absent : $path');
    return contents;
  }

  @override
  Future<void> writeFile(String path, String contents) async {
    files[path] = contents;
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
  Future<void> writeFile(String path, String contents) =>
      written.writeFile(path, contents);
}
