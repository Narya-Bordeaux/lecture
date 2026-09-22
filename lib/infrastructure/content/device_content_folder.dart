import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/domain/repositories/content_source.dart';
import 'package:grisbie/infrastructure/content/file_content_sink.dart';
import 'package:grisbie/infrastructure/content/file_content_source.dart';
import 'package:path_provider/path_provider.dart';

/// Le dossier de contenu de l'appareil : l'outil y ecrit son travail, et c'est
/// la qu'il le relit.
///
/// Les assets sont scelles au build : l'outil ne peut pas reecrire
/// `assets/content/`. Il lui faut donc un dossier a lui, dans les documents de
/// l'application, et c'est ce dossier-la qu'on rapatrie ensuite vers le depot.
///
/// **Les deux bouts sont ici, et c'est le point** : ecrire sans pouvoir relire
/// donnerait une aventure qu'on enregistre et qu'on ne rouvre jamais. Savoir
/// **ou** est ce dossier suppose un greffon, d'ou ce fichier : le greffon reste
/// dans l'infrastructure, et le point d'entree ne connait que [ContentSource]
/// et [ContentSink].
class DeviceContentFolder {
  const DeviceContentFolder._();

  /// Le dossier de travail, a cote des images choisies dans l'appareil.
  static Future<String> path() async {
    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}/content';
  }

  /// La lecture de ce dossier.
  static ContentSource sourceAt(String directory) {
    return FileContentSource(directory: directory);
  }

  /// L'ecriture dans ce dossier.
  static ContentSink sinkAt(String directory) {
    return FileContentSink(directory: directory);
  }
}
