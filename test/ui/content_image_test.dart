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
///
/// **« Le disque » n'a pas le meme sens partout.** Sur un appareil c'est un
/// fichier ; dans un navigateur il n'y en a pas, et le chemin est alors une
/// adresse — celle d'un blob choisi par l'auteur, ou plus tard celle d'un
/// fichier depose sur Firebase Storage. Ce fichier eprouve la branche
/// appareil ; la branche web est choisie a la compilation et ne s'execute
/// qu'en navigateur.

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

    test('une adresse reste une adresse, meme sur un appareil', () {
      // L'outil d'auteur tournera aussi dans un navigateur, et le contenu
      // finira depose sur un stockage distant : un chemin peut donc etre une
      // adresse, y compris lu depuis un telephone.
      expect(
        contentImageProvider('https://exemple.test/gare.jpg'),
        isA<NetworkImage>(),
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
