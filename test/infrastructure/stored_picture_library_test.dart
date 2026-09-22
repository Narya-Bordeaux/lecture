import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/repositories/picture_picker.dart';
import 'package:grisbie/infrastructure/pictures/stored_picture_library.dart';

import '../support/memory_content.dart';

/// Une image choisie est **du contenu** : elle va dans le même arbre que le
/// JSON, par le même puits, et redescendra avec lui.
///
/// Elle était rangée à part — un dossier de l'appareil —, si bien qu'elle ne
/// quittait jamais la machine où elle avait été prise. Et dans un navigateur
/// elle n'existait pas du tout : le sélecteur y rend une adresse `blob:` que
/// le système révoque aussitôt, d'où un aperçu vide dans la seconde.

/// Un sélecteur qui rend toujours la même image, sans appareil ni greffon.
class FakePicturePicker implements PicturePicker {
  FakePicturePicker({this.picture});

  /// Ce que le sélecteur rendra. Nul : l'auteur a refermé sans choisir.
  final PickedPicture? picture;

  int calls = 0;

  @override
  Future<PickedPicture?> pick() async {
    calls += 1;
    return picture;
  }
}

PickedPicture picture(String fileName, [List<int> bytes = const <int>[1, 2, 3]]) {
  return PickedPicture(
    bytes: Uint8List.fromList(bytes),
    fileName: fileName,
  );
}

void main() {
  group('Le nom du fichier rangé', () {
    test('part du lieu, et garde l\'extension de la source', () {
      final name = StoredPictureLibrary.fileNameFor(
        baseName: 'gare',
        sourceName: 'IMG_20260921_120000.png',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, startsWith('gare_'));
      expect(name, endsWith('.png'));
    });

    test('sans extension reconnaissable, on suppose une photo', () {
      final name = StoredPictureLibrary.fileNameFor(
        baseName: 'gare',
        sourceName: 'image_sans_extension',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, endsWith('.jpg'));
    });

    test('deux choix de suite ne se marchent pas dessus', () {
      // Le même nom donnerait le même chemin, donc la **même image en cache** :
      // choisir une autre photo n'aurait aucun effet visible.
      final first = StoredPictureLibrary.fileNameFor(
        baseName: 'gare',
        sourceName: 'a.jpg',
        now: DateTime.utc(2026, 9, 21, 12, 0, 0),
      );
      final second = StoredPictureLibrary.fileNameFor(
        baseName: 'gare',
        sourceName: 'b.jpg',
        now: DateTime.utc(2026, 9, 21, 12, 0, 1),
      );

      expect(first, isNot(second));
    });

    test('un nom de lieu accentué ne finit pas dans le chemin', () {
      final name = StoredPictureLibrary.fileNameFor(
        baseName: 'La forêt profonde',
        sourceName: 'a.jpg',
        now: DateTime.utc(2026, 9, 21, 12),
      );

      expect(name, startsWith('foret_profonde_'));
    });
  });

  group('Le rangement', () {
    late MemoryContentFolder folder;

    StoredPictureLibrary libraryOf(PicturePicker picker) {
      return StoredPictureLibrary(
        picker: picker,
        sink: folder,
        now: () => DateTime.utc(2026, 9, 21, 12),
      );
    }

    setUp(() => folder = MemoryContentFolder());

    test('l\'image est écrite dans l\'arbre de contenu', () async {
      final stored = await libraryOf(
        FakePicturePicker(picture: picture('photo.jpg', <int>[7, 8, 9])),
      ).pickPicture(baseName: 'La gare');

      // Un chemin relatif au contenu, comme « adventures/plage.json » : c'est
      // ce qui lui permet de voyager avec le reste.
      expect(stored, 'pictures/gare_1789992000000.jpg');
      expect(await folder.readBytes(stored!), <int>[7, 8, 9]);
    });

    test('renoncer n\'écrit rien', () async {
      final stored =
          await libraryOf(FakePicturePicker()).pickPicture(baseName: 'gare');

      expect(stored, isNull);
      expect(folder.bytes, isEmpty);
      expect(folder.files, isEmpty);
    });

    test('le chemin rendu se relit par la source', () async {
      // Le contrôle qui compte : ce que l'écran affichera doit se retrouver là
      // où l'outil lit son contenu. L'ancienne photothèque rangeait ailleurs,
      // et un navigateur ne retrouvait rien.
      final library = libraryOf(
        FakePicturePicker(picture: picture('photo.png', <int>[4])),
      );

      final stored = await library.pickPicture(baseName: 'plage');

      expect(() => folder.readBytes(stored!), returnsNormally);
      expect(stored, endsWith('.png'));
    });
  });
}
