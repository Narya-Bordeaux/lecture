import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';

/// Le contenu depose sur un stockage distant, lu et ecrit comme un dossier.
///
/// Les deux moities de la meme chose : `ContentSource` pour relire, comme le
/// jeu le fait des assets, `ContentSink` pour ecrire, comme l'outil le fait sur
/// un disque. L'arborescence est identique — `index.json`, `adventures/…` — et
/// c'est ce qui permet a `ContentSaver` et `ContentRepository` de ne rien
/// savoir du reseau.
///
/// **Le jeu livre n'en approche jamais** : personne ne lui passe ce depot, et
/// `author_only_test.dart` interdit que quoi que ce soit hors de ce dossier
/// importe Firebase.
class RemoteContentStore implements ContentSource, ContentSink {
  const RemoteContentStore({required this.storage, this.root = 'content'});

  final FirebaseStorage storage;

  /// Le prefixe de tous les fichiers, pour que le contenu ne soit pas seul au
  /// monde dans le bucket.
  final String root;

  /// Le chemin d'un fichier dans le bucket.
  ///
  /// Pur, et donc eprouvable : c'est la seule chose ici qui puisse etre fausse
  /// sans qu'un appareil et un reseau le disent.
  String pathFor(String path) {
    final trimmed = path.startsWith('/') ? path.substring(1) : path;
    return root.isEmpty ? trimmed : '$root/$trimmed';
  }

  /// Au-dela, ce n'est plus un fichier de contenu.
  ///
  /// `getData` exige une borne : sans elle, un fichier inattendu remplirait la
  /// memoire de l'appareil.
  static const int maxFileBytes = 4 * 1024 * 1024;

  @override
  Future<String> readFile(String path) async {
    final data = await storage.ref(pathFor(path)).getData(maxFileBytes);
    if (data == null) {
      throw StateError('Fichier absent du dépôt distant : ${pathFor(path)}');
    }
    return utf8.decode(data);
  }

  @override
  Future<void> writeFile(String path, String contents) async {
    await storage.ref(pathFor(path)).putString(
          contents,
          metadata: SettableMetadata(
            contentType: 'application/json; charset=utf-8',
          ),
        );
  }
}
