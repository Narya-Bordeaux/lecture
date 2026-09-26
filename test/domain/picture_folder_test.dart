import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/picture_folder.dart';

/// Les images se rangent par aventure : `pictures/<id de l'aventure>/`.
void main() {
  group('Le dossier d une image', () {
    test('une image rangee donne le dossier de son aventure', () {
      expect(PictureFolder.of('pictures/grisbie_plage/maison.jpg'),
          'grisbie_plage');
    });

    test('une image a la racine n a pas de dossier', () {
      expect(PictureFolder.of('pictures/bonjour.jpg'), PictureFolder.root);
    });

    test('le dossier propre a une aventure porte son identifiant', () {
      expect(PictureFolder.pathFor('grisbie_plage'), 'pictures/grisbie_plage/');
    });
  });

  group('Regrouper par dossier', () {
    test('chaque dossier garde ses images, les dossiers par nom, la racine '
        'en dernier', () {
      final groups = PictureFolder.group(<String>[
        'pictures/bonjour.jpg',
        'pictures/plage/b.jpg',
        'pictures/foret/a.jpg',
        'pictures/plage/a.jpg',
      ]);

      expect(groups.keys, <String>['foret', 'plage', PictureFolder.root]);
      expect(groups['plage'], <String>['pictures/plage/a.jpg',
          'pictures/plage/b.jpg']);
      expect(groups[PictureFolder.root], <String>['pictures/bonjour.jpg']);
    });

    test('sans image, aucun dossier', () {
      expect(PictureFolder.group(const <String>[]), isEmpty);
    });
  });
}
