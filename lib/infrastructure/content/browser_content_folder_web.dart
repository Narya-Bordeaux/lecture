import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:grisbie/domain/repositories/content_file_not_found.dart';
import 'package:grisbie/domain/repositories/content_store.dart';
import 'package:web/web.dart' as web;

/// Un dossier du poste, designe par l'auteur dans Chrome, lu et ecrit.
///
/// Passe par l'acces aux fichiers du navigateur (« File System Access ») :
/// l'auteur choisit le dossier `assets/content/` de sa copie du depot, et le
/// navigateur y donne un acces en ecriture pour la duree de l'onglet. Chrome
/// et Edge le proposent ; Firefox et Safari non — le bouton ne parait pas.
///
/// Les chemins sont ceux du contenu (`lists/transport.json`) : chaque dossier
/// intermediaire est ouvert, et cree a l'ecriture.
class BrowserContentFolder implements ContentStore {
  BrowserContentFolder(this._root);

  final web.FileSystemDirectoryHandle _root;

  @override
  Future<String> readFile(String path) async {
    final file = await _fileFor(path);
    return (await file.text().toDart).toDart;
  }

  @override
  Future<Uint8List> readBytes(String path) async {
    final file = await _fileFor(path);
    return (await file.arrayBuffer().toDart).toDart.asUint8List();
  }

  @override
  Future<void> writeFile(String path, String contents) =>
      _write(path, contents.toJS);

  @override
  Future<void> writeBytes(String path, Uint8List bytes) =>
      _write(path, bytes.toJS);

  Future<web.File> _fileFor(String path) async {
    try {
      final (directory, name) = await _locate(path, create: false);
      final handle = await directory.getFileHandle(name).toDart;
      return await handle.getFile().toDart;
    } catch (error) {
      // Une absence, et non une panne : c'est ce que les controles
      // d'integration distinguent. Le reste — un refus d'acces — remonte.
      if (_domErrorName(error) == 'NotFoundError') {
        throw ContentFileNotFound(path, cause: error);
      }
      rethrow;
    }
  }

  Future<void> _write(String path, JSAny data) async {
    final (directory, name) = await _locate(path, create: true);
    final handle = await directory
        .getFileHandle(name, web.FileSystemGetFileOptions(create: true))
        .toDart;
    final stream = await handle.createWritable().toDart;
    await stream.write(data).toDart;
    await stream.close().toDart;
  }

  /// Le dossier qui contient [path], et le nom du fichier.
  Future<(web.FileSystemDirectoryHandle, String)> _locate(
    String path, {
    required bool create,
  }) async {
    final segments = path.split('/');
    var directory = _root;
    for (final segment in segments.take(segments.length - 1)) {
      directory = await directory
          .getDirectoryHandle(
            segment,
            web.FileSystemGetDirectoryOptions(create: create),
          )
          .toDart;
    }
    return (directory, segments.last);
  }
}

/// Vrai si le navigateur sait donner acces a un dossier du poste.
bool canPickContentFolderImpl() =>
    web.window.has('showDirectoryPicker');

@JS('showDirectoryPicker')
external JSPromise<web.FileSystemDirectoryHandle> _showDirectoryPicker(
  JSObject options,
);

/// Demande a l'auteur de designer un dossier, en lecture et ecriture.
///
/// Rend `null` s'il renonce — refermer le selecteur est un geste normal.
Future<ContentStore?> pickContentFolderImpl() async {
  final options = JSObject()..['mode'] = 'readwrite'.toJS;
  try {
    return BrowserContentFolder(await _showDirectoryPicker(options).toDart);
  } catch (error) {
    if (_domErrorName(error) == 'AbortError') return null;
    rethrow;
  }
}

/// Le nom d'une erreur du navigateur (`NotFoundError`, `AbortError`…), ou
/// `null` si ce n'en est pas une.
///
/// Lu comme une propriete plutot que par un test de type : un type
/// d'interoperabilite ne se verifie pas de la meme facon selon le compilateur.
String? _domErrorName(Object error) {
  final jsError = error.jsify();
  if (jsError == null || !jsError.isA<JSObject>()) return null;
  final name = (jsError as JSObject)['name'];
  return name.isA<JSString>() ? (name as JSString).toDart : null;
}
