import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/infrastructure/content/asset_content_source.dart';
import 'package:grisbie/ui/widgets/content_image.dart';

import '../support/memory_content.dart';

/// D'où vient une illustration.
///
/// **Une illustration est du contenu**, au même titre qu'un fichier
/// d'aventure : son chemin est relatif au dossier du contenu, et c'est la
/// *source* qui sait où ce dossier se trouve — le bundle pour le jeu, un
/// dossier de l'appareil ou le dépôt distant pour l'outil d'auteur.
///
/// Elle vivait à part jusqu'en 0.28.0 : un chemin de fichier sur l'appareil,
/// une adresse `blob:` dans un navigateur. Elle ne voyageait donc pas avec le
/// contenu — prise sur le téléphone, elle n'arrivait jamais sur le poste — et
/// dans un onglet elle disparaissait avant même d'être affichée.
///
/// Une seule fonction tranche, pour les quatre endroits qui affichent une
/// image. Deux règles séparées finiraient par diverger, et l'auteur calerait
/// ses zones sur une image que le jeu ne montre pas.

void main() {
  group('Où chercher l\'illustration', () {
    test('un chemin relatif se lit par la source du contenu', () {
      // Le cas ordinaire depuis 0.28.0 : « pictures/gare_….jpg », comme
      // « adventures/plage.json ».
      expect(
        contentImageProvider('pictures/gare_1.jpg'),
        isA<ContentPictureImage>(),
      );
    });

    test('la source passée est bien celle qui lira', () {
      final folder = MemoryContentFolder();
      final provider = contentImageProvider(
        'pictures/gare_1.jpg',
        source: folder,
      ) as ContentPictureImage;

      // Sans cela, l'outil montrerait l'image du bundle au lieu de celle qu'il
      // vient de déposer sur le dépôt.
      expect(provider.source, same(folder));
      expect(provider.path, 'pictures/gare_1.jpg');
    });

    test('sans source, c\'est le bundle — le cas du jeu', () {
      final provider =
          contentImageProvider('pictures/gare_1.jpg') as ContentPictureImage;

      expect(provider.source, isA<AssetContentSource>());
    });

    test('deux appels sur le même chemin donnent le même fournisseur', () {
      // Sans cela le cache d'images rechargerait le fichier à chaque rendu, et
      // l'aperçu clignoterait à chaque geste de calage.
      expect(
        contentImageProvider('pictures/a.jpg'),
        contentImageProvider('pictures/a.jpg'),
      );
    });

    test('deux sources différentes donnent deux fournisseurs différents', () {
      // Se connecter au dépôt change l'endroit où l'image est lue : garder le
      // même fournisseur ferait afficher celle d'avant.
      expect(
        contentImageProvider('pictures/a.jpg', source: MemoryContentFolder()),
        isNot(contentImageProvider(
          'pictures/a.jpg',
          source: MemoryContentFolder(),
        )),
      );
    });
  });
}
