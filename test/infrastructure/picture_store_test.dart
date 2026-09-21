import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/infrastructure/pictures/picture_store.dart';

/// Ou va une image choisie dans l'appareil, et sous quel nom.
///
/// Le selecteur d'images rend un fichier **de cache**, qu'Android peut purger
/// a tout moment. Le garder tel quel ferait disparaitre l'illustration en
/// cours de session, sans que rien ne l'explique : elle est donc recopiee dans
/// un dossier a nous.

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('grisbie_pictures');
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  group('Le nom du fichier range', () {
    test('part du lieu, et garde l\'extension de la source', () {
      final name = PictureStore.fileNameFor(
        baseName: 'gare',
        sourcePath: '/cache/IMG_20260921_120000.png',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, startsWith('gare_'));
      expect(name, endsWith('.png'));
    });

    test('sans extension reconnaissable, on suppose une photo', () {
      final name = PictureStore.fileNameFor(
        baseName: 'gare',
        sourcePath: '/cache/image_sans_extension',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, endsWith('.jpg'));
    });

    test('deux choix de suite ne se marchent pas dessus', () {
      // Le meme nom donnerait le meme chemin, donc la **meme image en cache** :
      // choisir une autre photo n'aurait aucun effet visible.
      final first = PictureStore.fileNameFor(
        baseName: 'gare',
        sourcePath: '/cache/a.jpg',
        now: DateTime.utc(2026, 9, 21, 12, 0, 0),
      );
      final second = PictureStore.fileNameFor(
        baseName: 'gare',
        sourcePath: '/cache/b.jpg',
        now: DateTime.utc(2026, 9, 21, 12, 0, 1),
      );

      expect(first, isNot(second));
    });

    test('un nom de lieu accentue ne finit pas dans le chemin', () {
      // Un identifiant finit dans un nom de fichier : accents et espaces y
      // sont un vrai ennui.
      final name = PictureStore.fileNameFor(
        baseName: 'La forêt profonde',
        sourcePath: '/cache/a.jpg',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, startsWith('foret_profonde_'));
    });
  });

  group('Le rangement', () {
    test('copie l\'image, et rend son chemin', () async {
      final source = File('${directory.path}/source.jpg');
      await source.writeAsBytes(<int>[1, 2, 3]);

      final store = PictureStore(directory: '${directory.path}/rangees');
      final stored = await store.store(source.path, baseName: 'gare');

      expect(File(stored).existsSync(), isTrue);
      expect(await File(stored).readAsBytes(), <int>[1, 2, 3]);
    });

    test('cree le dossier au premier rangement', () async {
      // Une installation neuve n'a pas ce dossier : sans creation prealable, la
      // premiere image choisie echouerait.
      final source = File('${directory.path}/source.jpg');
      await source.writeAsBytes(<int>[1]);

      final target = '${directory.path}/jamais_vu/encore';
      await PictureStore(directory: target).store(source.path, baseName: 'x');

      expect(Directory(target).existsSync(), isTrue);
    });

    test('l\'original reste ou il est', () async {
      // Deplacer le fichier du selecteur toucherait la photothegue de
      // l'auteur : on copie, on ne prend pas.
      final source = File('${directory.path}/source.jpg');
      await source.writeAsBytes(<int>[1]);

      await PictureStore(directory: '${directory.path}/rangees')
          .store(source.path, baseName: 'gare');

      expect(source.existsSync(), isTrue);
    });
  });
}
