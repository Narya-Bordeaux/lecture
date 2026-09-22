import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:grisbie/domain/repositories/content_file_not_found.dart';
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

  /// Le code par lequel Firebase dit « ce fichier n'existe pas ».
  ///
  /// **Lui seul.** Un refus de la regle (`unauthorized`), un reseau coupe ou
  /// un blocage du navigateur sont des **pannes** et doivent remonter : les
  /// prendre pour des absences faisait servir en silence le contenu livre a la
  /// place du travail depose, et rien ne le disait.
  static const String absenceCode = 'object-not-found';

  @override
  Future<String> readFile(String path) async {
    final Uint8List? data;
    try {
      data = await storage.ref(pathFor(path)).getData(maxFileBytes);
    } on FirebaseException catch (error) {
      if (error.code == absenceCode) {
        throw ContentFileNotFound(path, cause: error);
      }
      rethrow;
    }

    if (data == null) throw ContentFileNotFound(path);
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
