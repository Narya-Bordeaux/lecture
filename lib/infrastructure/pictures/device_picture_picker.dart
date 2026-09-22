import 'package:grisbie/domain/repositories/picture_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Ouvre la photothegue du systeme, sur un appareil comme dans un navigateur.
///
/// Sur Android 13 et au-dela, « image_picker » passe par le Photo Picker du
/// systeme : l'application ne voit que l'image choisie, et **aucune permission
/// n'est demandee**. C'est ce qui a fait preferer ce greffon a un selecteur de
/// fichiers general, l'application etant par ailleurs destinee aux enfants.
///
/// **Le meme greffon sert dans un navigateur** (`image_picker_for_web`), ou il
/// ouvre le selecteur de fichiers du systeme.
///
/// On lit les **octets**, jamais le chemin rendu par le greffon : sur un
/// appareil c'est un fichier de cache qu'Android peut purger, et dans un
/// navigateur une adresse `blob:` que le systeme revoque aussitot. Lire le
/// chemin etait la cause de l'apercu vide sur le web ; il n'y a plus de chemin
/// a lire, donc plus rien a revoquer.
class DevicePicturePicker implements PicturePicker {
  DevicePicturePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPicture?> pick() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    return PickedPicture(
      bytes: await picked.readAsBytes(),
      // `name` porte le nom d'origine, dont on ne garde que l'extension.
      fileName: picked.name,
    );
  }
}
