import 'package:grisbie/domain/repositories/content_sink.dart';
import 'package:grisbie/infrastructure/content/file_content_sink.dart';
import 'package:path_provider/path_provider.dart';

/// Le dossier de contenu de l'appareil, et le puits qui y ecrit.
///
/// Les assets sont scelles au build : l'outil ne peut pas reecrire
/// `assets/content/`. Il lui faut donc un dossier a lui, dans les documents de
/// l'application, et c'est ce dossier-la qu'on rapatrie ensuite vers le depot.
///
/// Savoir **ou** est ce dossier suppose un greffon, d'ou ce fichier : le
/// greffon reste dans l'infrastructure, et le point d'entree ne connait que
/// `ContentSink`.
class DeviceContentSink {
  const DeviceContentSink._();

  /// Le dossier de travail, a cote des images choisies dans l'appareil.
  static Future<String> directory() async {
    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}/content';
  }

  /// Le puits branche sur ce dossier.
  static Future<ContentSink> open() async {
    return FileContentSink(directory: await directory());
  }
}
