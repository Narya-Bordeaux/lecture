import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/infrastructure/pictures/bundled_picture_catalog.dart';

/// Les illustrations se choisissent **dans le depot** : l'auteur verse ses
/// images dans `assets/content/pictures/`, et l'outil les propose par leur nom.
/// Le jeu compile en meme temps embarque les memes fichiers — une image
/// choisie la existe donc forcement dans le jeu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ce qui est une illustration', () {
    test('seuls les fichiers du dossier des images comptent', () {
      final pictures = BundledPictureCatalog.picturesIn(<String>[
        'assets/content/index.json',
        'assets/content/pictures/Grisbie gare.jpg',
        'assets/content/adventures/grisbie_plage.json',
        'assets/content/pictures/Grisbie forêt.jpg',
        'packages/autre/assets/content/pictures/intrus.jpg',
      ]);

      // Le chemin est relatif au dossier du contenu, comme dans l'aventure.
      expect(pictures, <String>[
        'pictures/Grisbie forêt.jpg',
        'pictures/Grisbie gare.jpg',
      ]);
    });

    test('la liste est triee par nom', () {
      final pictures = BundledPictureCatalog.picturesIn(<String>[
        'assets/content/pictures/b.jpg',
        'assets/content/pictures/a.jpg',
      ]);

      expect(pictures, <String>['pictures/a.jpg', 'pictures/b.jpg']);
    });
  });

  test('le bundle propose les images versees par l\'auteur', () async {
    final pictures = await const BundledPictureCatalog().listPictures();

    expect(pictures, contains('pictures/gare.jpg'));
    expect(pictures, contains('pictures/maison.jpg'));
  });
}
