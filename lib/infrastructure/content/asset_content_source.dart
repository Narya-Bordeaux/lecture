import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:grisbie/domain/repositories/content_source.dart';

/// Lit les fichiers de contenu embarques dans l'application.
class AssetContentSource implements ContentSource {
  const AssetContentSource({this.bundle, this.basePath = 'assets/content'});

  /// Injectable pour charger un contenu de substitution dans les tests, sans
  /// dependre des assets reellement embarques.
  final AssetBundle? bundle;

  /// Le dossier du contenu, auquel les chemins du fichier pere sont relatifs.
  final String basePath;

  @override
  Future<String> readFile(String path) {
    return (bundle ?? rootBundle).loadString('$basePath/$path');
  }
}
