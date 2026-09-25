import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// Verifie l'icone de l'application et son ecran de chargement.
///
/// Les images sont produites par `tool/generate_app_icons.py` d'apres le logo
/// de l'accueil ; les fichiers XML sont ecrits a la main. **Aucun build
/// Android n'est possible en session cloud** : ce test lit des fichiers, il
/// attrape une image manquante, de mauvaise taille, ou une ressource citee
/// qui n'existe pas. Seul un lancement sur le telephone montre le rendu.

const String mainRes = 'android/app/src/main/res';
const String authorRes = 'android/app/src/auteur/res';

/// Les densites Android et leur facteur par rapport au dp.
const Map<String, double> densities = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

/// La largeur et la hauteur d'un PNG, lues dans son en-tete.
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = ByteData.sublistView(bytes, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  group('Icone adaptative', () {
    test('cite un calque avant et une couleur de fond qui existent', () {
      final adaptive = File('$mainRes/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(adaptive, contains('@mipmap/ic_launcher_foreground'));
      expect(adaptive, contains('@color/ic_launcher_background'));
      expect(
        File('$mainRes/values/colors.xml').readAsStringSync(),
        contains('name="ic_launcher_background"'),
      );
    });

    for (final entry in densities.entries) {
      test('${entry.key} : calque de 108 dp et icone de repli de 48 dp', () {
        final layer = (108 * entry.value).round();
        final legacy = (48 * entry.value).round();
        for (final res in <String>[mainRes, authorRes]) {
          expect(
            pngSize('$res/mipmap-${entry.key}/ic_launcher_foreground.png'),
            (layer, layer),
            reason: res,
          );
          expect(
            pngSize('$res/mipmap-${entry.key}/ic_launcher.png'),
            (legacy, legacy),
            reason: res,
          );
        }
      });
    }

    test('l\'outil d\'auteur a sa propre icone, marquee d\'un crayon', () {
      // Deux icones identiques cote a cote sur le telephone de l'auteur
      // se confondraient : la saveur auteur remplace les images du jeu.
      for (final density in densities.keys) {
        for (final name in <String>[
          'ic_launcher_foreground.png',
          'ic_launcher.png',
        ]) {
          final game = File('$mainRes/mipmap-$density/$name').readAsBytesSync();
          final author =
              File('$authorRes/mipmap-$density/$name').readAsBytesSync();
          expect(author, isNot(equals(game)), reason: '$density/$name');
        }
      }
    });
  });

  group('Ecran de chargement', () {
    test('Android 12 et plus : l\'icone sur le bleu de l\'accueil', () {
      for (final folder in <String>['values-v31', 'values-night-v31']) {
        final styles = File('$mainRes/$folder/styles.xml').readAsStringSync();
        expect(
          styles,
          contains('windowSplashScreenAnimatedIcon">'
              '@mipmap/ic_launcher_foreground<'),
          reason: folder,
        );
        expect(
          styles,
          contains('windowSplashScreenBackground">@color/splash_background<'),
          reason: folder,
        );
      }
    });

    test('Android 7 a 11 : le logo en ovale, a chaque densite', () {
      for (final folder in <String>['drawable', 'drawable-v21']) {
        final background = File(
          '$mainRes/$folder/launch_background.xml',
        ).readAsStringSync();
        expect(background, contains('@drawable/splash_logo'), reason: folder);
        expect(background, contains('@color/splash_background'));
      }
      for (final density in densities.keys) {
        expect(
          File('$mainRes/drawable-$density/splash_logo.png').existsSync(),
          isTrue,
          reason: density,
        );
      }
    });

    test('le bleu est celui de l\'accueil', () {
      // GameHomePage.backgroundColor : le chargement se fond dans l'accueil.
      expect(
        File('$mainRes/values/colors.xml').readAsStringSync(),
        contains('<color name="splash_background">#DCEBF7</color>'),
      );
    });
  });

  test('web : chaque icone annoncee existe, a la taille annoncee', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    final icons = (manifest['icons'] as List<dynamic>).cast<Map>();
    expect(icons, isNotEmpty);
    for (final icon in icons) {
      final side = int.parse((icon['sizes'] as String).split('x').first);
      expect(pngSize('web/${icon['src']}'), (side, side), reason: icon['src']);
    }
    expect(File('web/favicon.png').existsSync(), isTrue);
  });
}
