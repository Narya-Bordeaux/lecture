import 'dart:typed_data';

/// Une image que l'auteur vient de choisir, avant qu'on la range.
class PickedPicture {
  const PickedPicture({required this.bytes, required this.fileName});

  final Uint8List bytes;

  /// Le nom du fichier d'origine.
  ///
  /// On n'en garde que l'extension : le nom sous lequel l'image sera rangee
  /// vient du lieu, pas de l'appareil.
  final String fileName;
}

/// Ouvre la photothegue et rend l'image choisie, **en octets**.
///
/// Des octets et non un chemin : c'est la seule forme qui existe partout. Un
/// appareil rend un fichier de cache, un navigateur une adresse `blob:` que le
/// systeme revoque aussitot — et cette adresse revoquee est precisement ce qui
/// faisait echouer l'apercu.
///
/// Volontairement sans dependance a Flutter, et sans savoir ou l'image ira :
/// ranger est l'affaire de `StoredPictureLibrary`.
abstract class PicturePicker {
  /// Rend `null` si l'auteur renonce — refermer le selecteur est un geste
  /// normal, pas une panne.
  Future<PickedPicture?> pick();
}
