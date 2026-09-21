import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

/// D'ou vient une illustration : du bundle, ou du disque.
///
/// **Les assets sont scelles au build.** Une image que l'auteur vient d'ajouter
/// sur son telephone n'y est pas, et n'y sera qu'apres un commit et une
/// recompilation. Pendant l'edition elle vit donc sur le disque, et le jeu
/// livre, lui, ne lit que le bundle.
///
/// Une seule fonction tranche, pour les quatre endroits qui affichent une
/// image. Deux regles separees finiraient par diverger, et l'auteur calerait
/// ses zones sur une image que le jeu ne montre pas.

void main() {
  group('Ou chercher l\'illustration', () {
    test('un chemin d\'asset vient du bundle', () {
      expect(
        contentImageProvider('assets/pictures/Grisbie_plage.jpg'),
        isA<AssetImage>(),
      );
    });

    test('tout autre chemin vient du disque', () {
      // C'est le cas pendant l'edition : l'image est dans le dossier de
      // l'application, pas encore dans le depot.
      expect(
        contentImageProvider('/data/user/0/fr.naryabordeaux.grisbie/gare.jpg'),
        isA<FileImage>(),
      );
    });

    test('le chemin du disque est conserve tel quel', () {
      final provider =
          contentImageProvider('/tmp/images/gare.jpg') as FileImage;

      expect(provider.file.path, '/tmp/images/gare.jpg');
    });

    test('deux appels sur le meme chemin donnent le meme fournisseur', () {
      // Sans cela le cache d'images rechargerait le fichier a chaque rendu, et
      // l'apercu clignoterait a chaque geste de calage.
      expect(
        contentImageProvider('assets/pictures/a.jpg'),
        contentImageProvider('assets/pictures/a.jpg'),
      );
      expect(
        contentImageProvider('/tmp/a.jpg'),
        contentImageProvider('/tmp/a.jpg'),
      );
    });
  });
}
