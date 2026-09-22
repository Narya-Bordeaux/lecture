import 'package:grisbie/domain/repositories/picture_library.dart';
import 'package:grisbie/infrastructure/pictures/picture_keeper_web.dart'
    if (dart.library.io) 'package:grisbie/infrastructure/pictures/picture_keeper_io.dart'
    as keeper;
import 'package:image_picker/image_picker.dart';

/// Choisit une illustration, sur un appareil comme dans un navigateur.
///
/// Sur Android 13 et au-dela, « image_picker » passe par le Photo Picker du
/// systeme : l'application ne voit que l'image choisie, et **aucune permission
/// n'est demandee**. C'est ce qui a fait preferer ce greffon a un selecteur de
/// fichiers general, l'application etant par ailleurs destinee aux enfants.
///
/// **Le meme greffon sert dans un navigateur** (`image_picker_for_web`) : il y
/// ouvre le selecteur de fichiers du systeme et rend une adresse `blob:`, que
/// `contentImageProvider` sait deja afficher. L'ecran d'auteur etait prive de
/// bouton sur le web, ce qui interdisait de charger une image sur un poste —
/// alors que c'est la moitie du travail qu'on y fait.
///
/// Ce qui differe d'une plateforme a l'autre, c'est **ce qu'on peut garder** :
/// une recopie durable la ou il y a un disque, rien du tout dans un
/// navigateur. D'ou l'import conditionnel, et [keepsPictures] que l'ecran
/// affiche.
class DevicePictureLibrary implements PictureLibrary {
  DevicePictureLibrary({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get keepsPictures => keeper.keepsPictures;

  @override
  Future<String?> pickPicture({required String baseName}) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    return keeper.keepPicture(picked.path, baseName: baseName);
  }
}
