import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:web/web.dart' as web;

/// Rend les fichiers ecrits par le telechargement du navigateur.
///
/// **Un depannage, et il se voit.** Un navigateur ne sait pas ecrire dans un
/// dossier : chaque fichier part separement, et il faut ensuite les reposer a
/// la main dans `assets/content/` du depot. Le nom porte le chemin, les barres
/// devenant des tirets bas, puisqu'un telechargement ne cree pas de dossier.
///
/// C'est pourquoi l'outil ne recopie pas, ici, ce qu'il n'a pas touche
/// (`ContentSaver.includeUnchanged`) : le depot possede deja le lexique.
class BrowserContentSink implements ContentSink {
  const BrowserContentSink();

  /// Le nom sous lequel un fichier descend, son chemin aplati.
  ///
  /// `adventures/plage.json` devient `adventures_plage.json` : a reposer dans
  /// `adventures/`, ce que le nom dit encore.
  static String downloadNameFor(String path) => path.replaceAll('/', '_');

  @override
  Future<void> writeBytes(String path, Uint8List bytes) {
    return _download(path, bytes, 'application/octet-stream');
  }

  @override
  Future<void> writeFile(String path, String contents) {
    return _download(
      path,
      Uint8List.fromList(utf8.encode(contents)),
      'application/json',
    );
  }

  Future<void> _download(String path, Uint8List bytes, String type) async {
    final blob = web.Blob(
      <JSUint8Array>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: type),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = downloadNameFor(path);
    anchor.click();

    web.URL.revokeObjectURL(url);
  }
}

ContentSink createBrowserContentSink() => const BrowserContentSink();
