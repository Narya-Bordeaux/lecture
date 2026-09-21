import 'package:flutter_test/flutter_test.dart';
import 'package:reading_game/application/area_editor.dart';
import 'package:reading_game/domain/models/relative_area.dart';

/// Une zone de reference, au milieu de l'illustration et loin des bords.
RelativeArea centered() {
  return const RelativeArea(left: 0.4, top: 0.4, width: 0.2, height: 0.2);
}

AreaEditor buildEditor({Map<String, RelativeArea>? areas}) {
  return AreaEditor(
    areas: areas ?? <String, RelativeArea>{'bus': centered()},
    minimumWidth: 0.1,
    minimumHeight: 0.1,
  );
}

void main() {
  group('Deplacer une zone', () {
    test('la decale des memes fractions', () {
      final editor = buildEditor();

      editor.move('bus', dx: 0.1, dy: -0.2);

      final area = editor.areas['bus']!;
      expect(area.left, closeTo(0.5, 1e-9));
      expect(area.top, closeTo(0.2, 1e-9));
      // Le deplacement ne change jamais la taille.
      expect(area.width, closeTo(0.2, 1e-9));
      expect(area.height, closeTo(0.2, 1e-9));
    });

    test('la zone ne peut pas sortir de l\'illustration', () {
      // Une zone poussee hors de l'image emporterait sa cible avec elle : le
      // chargement la refuserait, et l'auteur ne le verrait qu'apres coup.
      final editor = buildEditor();

      editor.move('bus', dx: 5, dy: 5);

      final area = editor.areas['bus']!;
      expect(area.right, closeTo(1, 1e-9));
      expect(area.bottom, closeTo(1, 1e-9));

      editor.move('bus', dx: -5, dy: -5);

      expect(editor.areas['bus']!.left, closeTo(0, 1e-9));
      expect(editor.areas['bus']!.top, closeTo(0, 1e-9));
    });

    test('une famille inconnue est signalee, pas ignoree', () {
      final editor = buildEditor();

      expect(
        () => editor.move('fantome', dx: 0.1, dy: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Redimensionner par un coin', () {
    test('le coin oppose ne bouge pas', () {
      final editor = buildEditor();

      editor.resize('bus', corner: AreaCorner.bottomRight, dx: 0.1, dy: 0.1);

      final area = editor.areas['bus']!;
      expect(area.left, closeTo(0.4, 1e-9));
      expect(area.top, closeTo(0.4, 1e-9));
      expect(area.right, closeTo(0.7, 1e-9));
      expect(area.bottom, closeTo(0.7, 1e-9));
    });

    test('tirer le coin haut-gauche deplace ce coin seul', () {
      final editor = buildEditor();

      editor.resize('bus', corner: AreaCorner.topLeft, dx: -0.1, dy: -0.1);

      final area = editor.areas['bus']!;
      expect(area.left, closeTo(0.3, 1e-9));
      expect(area.top, closeTo(0.3, 1e-9));
      // Le coin bas-droit reste ou il etait.
      expect(area.right, closeTo(0.6, 1e-9));
      expect(area.bottom, closeTo(0.6, 1e-9));
    });

    test('une zone ne devient jamais plus petite qu\'un doigt', () {
      // 48 points de cote est la cible d'accessibilite usuelle ; en dessous,
      // l'enfant vise une cible que son doigt recouvre entierement.
      final editor = buildEditor();

      editor.resize('bus', corner: AreaCorner.bottomRight, dx: -5, dy: -5);

      final area = editor.areas['bus']!;
      expect(area.width, closeTo(0.1, 1e-9));
      expect(area.height, closeTo(0.1, 1e-9));
    });

    test('le redimensionnement s\'arrete au bord de l\'illustration', () {
      final editor = buildEditor();

      editor.resize('bus', corner: AreaCorner.bottomRight, dx: 5, dy: 5);

      expect(editor.areas['bus']!.right, closeTo(1, 1e-9));
      expect(editor.areas['bus']!.bottom, closeTo(1, 1e-9));
    });
  });

  group('Chevauchement', () {
    test('deux zones disjointes ne sont pas signalees', () {
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.3,
            height: 0.3,
          ),
          'voiture': const RelativeArea(
            left: 0.5,
            top: 0.5,
            width: 0.3,
            height: 0.3,
          ),
        },
      );

      expect(editor.overlappingFamilyIds, isEmpty);
    });

    test('deux zones qui se recouvrent sont nommees toutes les deux', () {
      // Le depot y serait ambigu : l'enfant ne saurait pas laquelle il vise.
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.4,
            height: 0.4,
          ),
          'voiture': const RelativeArea(
            left: 0.3,
            top: 0.3,
            width: 0.4,
            height: 0.4,
          ),
          'pied': const RelativeArea(
            left: 0.8,
            top: 0.8,
            width: 0.2,
            height: 0.2,
          ),
        },
      );

      expect(editor.overlappingFamilyIds, <String>{'bus', 'voiture'});
    });

    test('le chevauchement se juge sur les valeurs arrondies', () {
      // C'est le JSON arrondi qui sera charge par le jeu : signaler un
      // chevauchement sur la valeur exacte, que l'auteur n'ecrira jamais,
      // n'aurait aucun sens.
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.3004,
            height: 0.3,
          ),
          'voiture': const RelativeArea(
            left: 0.3006,
            top: 0.0,
            width: 0.3,
            height: 0.3,
          ),
        },
      );

      // Arrondies au centieme, les deux zones se touchent sans se recouvrir.
      expect(editor.roundedAreas['bus']!.right, closeTo(0.30, 1e-9));
      expect(editor.roundedAreas['voiture']!.left, closeTo(0.30, 1e-9));
      expect(editor.overlappingFamilyIds, isEmpty);
    });
  });

  group('Export', () {
    test('les fractions sont arrondies au centieme', () {
      // Ecrire 0.2933333 dans un fichier relu par un enseignant n'aurait aucun
      // sens : au centieme pres, la zone bouge d'un pour cent de l'image.
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.29333,
            top: 0.40777,
            width: 0.32111,
            height: 0.16999,
          ),
        },
      );

      expect(editor.export(), contains('"left": 0.29'));
      expect(editor.export(), contains('"top": 0.41'));
      expect(editor.export(), contains('"width": 0.32'));
      expect(editor.export(), contains('"height": 0.17'));
    });

    test('l\'arrondi ne produit jamais une zone qui deborde', () {
      // Arrondir separement `left` et `width` peut faire depasser leur somme :
      // le jeu refuserait alors de charger le contenu que l'auteur vient
      // d'exporter.
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.9949,
            top: 0.9949,
            width: 0.0051,
            height: 0.0051,
          ),
        },
      );

      final rounded = editor.roundedAreas['bus']!;
      expect(rounded.overflows, isFalse);
      expect(rounded.right, lessThanOrEqualTo(1));
      expect(rounded.bottom, lessThanOrEqualTo(1));
    });

    test('chaque famille est nommee dans le JSON produit', () {
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'en_bus': centered(),
          'en_voiture': const RelativeArea(
            left: 0.0,
            top: 0.0,
            width: 0.2,
            height: 0.2,
          ),
        },
      );

      final exported = editor.export();

      expect(exported, contains('en_bus'));
      expect(exported, contains('en_voiture'));
    });
  });
}
