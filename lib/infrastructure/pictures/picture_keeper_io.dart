import 'package:grisbie/infrastructure/pictures/picture_store.dart';
import 'package:path_provider/path_provider.dart';

/// Ranger une image choisie, la ou il y a un disque.
///
/// Pendant de `picture_keeper_web.dart`, choisi a la compilation : « le
/// disque » n'a pas le meme sens partout, et c'est la meme regle que pour
/// l'affichage d'une image (`content_image.dart`).

/// Vrai : l'image recopiee se retrouve d'une session a l'autre.
const bool keepsPictures = true;

/// Le dossier des images en cours d'edition, a cote du contenu ecrit.
///
/// Ce n'est pas `assets/pictures/` : les assets sont scelles au build, et
/// l'image n'y entrera qu'une fois commitee dans le depot.
Future<String> picturesDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return '${documents.path}/pictures';
}

/// Recopie l'image choisie et rend le chemin de la copie.
///
/// Le selecteur rend un fichier de **cache**, qu'Android peut purger en cours
/// de session : l'illustration disparaitrait sans que rien ne l'explique.
Future<String> keepPicture(String pickedPath, {required String baseName}) async {
  final store = PictureStore(directory: await picturesDirectory());
  return store.store(pickedPath, baseName: baseName);
}
