import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/infrastructure/pictures/picture_store.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Choisit une illustration dans la photothegue de l'appareil.
///
/// Sur Android 13 et au-dela, « image_picker » passe par le Photo Picker du
/// systeme : l'application ne voit que l'image choisie, et **aucune permission
/// n'est demandee**. C'est ce qui a fait preferer ce greffon a un selecteur de
/// fichiers general, l'application etant par ailleurs destinee aux enfants.
///
/// L'image choisie est aussitot recopiee ([PictureStore]) : le selecteur rend
/// un fichier de cache, qu'Android peut purger en cours de session.
class DevicePictureLibrary implements PictureLibrary {
  DevicePictureLibrary({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Le dossier des images en cours d'edition, a cote du contenu ecrit.
  ///
  /// Ce n'est pas `assets/pictures/` : les assets sont scelles au build, et
  /// l'image n'y entrera qu'une fois commitee dans le depot.
  static Future<String> picturesDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}/pictures';
  }

  @override
  Future<String?> pickPicture({required String baseName}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final store = PictureStore(directory: await picturesDirectory());
    return store.store(picked.path, baseName: baseName);
  }
}
