import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/area_editor.dart';
import 'package:grisbie/domain/models/relative_area.dart';

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

  group('Arrondi', () {
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

      final rounded = editor.roundedAreas['bus']!;
      expect(rounded.left, 0.29);
      expect(rounded.top, 0.41);
      expect(rounded.width, 0.32);
      expect(rounded.height, 0.17);
    });

    test('l\'arrondi ne produit jamais une zone qui deborde', () {
      // Arrondir separement `left` et `width` peut faire depasser leur somme :
      // le jeu refuserait alors de charger le contenu que l'auteur vient
      // d'enregistrer.
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
  });

  group('Disposition par defaut', () {
    List<String> ids(int count) =>
        List<String>.generate(count, (index) => 'famille_$index');

    test('chaque famille recoit une zone, quel que soit leur nombre', () {
      for (var count = 1; count <= 9; count++) {
        final layout = AreaEditor.defaultLayout(ids(count));
        expect(layout.keys, ids(count), reason: '$count familles');
      }
    });

    test('les zones ne se chevauchent pas et restent sur l\'image', () {
      for (var count = 1; count <= 12; count++) {
        final editor = AreaEditor(
          areas: AreaEditor.defaultLayout(ids(count)),
          minimumWidth: 0,
          minimumHeight: 0,
        );
        expect(editor.overlappingFamilyIds, isEmpty, reason: '$count familles');
        for (final area in editor.roundedAreas.values) {
          expect(area.overflows, isFalse, reason: '$count familles');
        }
      }
    });

    test('jusqu\'a trois, une seule rangee', () {
      final layout = AreaEditor.defaultLayout(ids(3));
      final tops = layout.values.map((area) => area.top).toSet();
      expect(tops, hasLength(1));
    });

    test('au-dela de trois, plusieurs rangees pour garder des zones larges', () {
      // Six chemins sur une seule rangee donneraient des zones de 13 % de la
      // largeur : moins qu'un doigt sur un telephone.
      final layout = AreaEditor.defaultLayout(ids(6));
      final tops = layout.values.map((area) => area.top).toSet();
      expect(tops, hasLength(2));
      for (final area in layout.values) {
        expect(area.width, greaterThanOrEqualTo(0.25));
      }
    });

    test('le tri unique a deux zones, cote a cote', () {
      // La liste du theme et la liste du reste : deux familles, deux zones.
      final layout = AreaEditor.defaultLayout(<String>['a_manger', 'le_reste']);
      expect(layout, hasLength(2));
      expect(layout['a_manger']!.right, lessThan(layout['le_reste']!.left));
    });
  });

  group('Taille minimale', () {
    test('une zone trop petite est agrandie', () {
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.4,
            top: 0.4,
            width: 0.05,
            height: 0.02,
          ),
        },
      );

      expect(editor.isUndersized('bus'), isTrue);
      editor.enforceMinimumSize('bus');

      final area = editor.areas['bus']!;
      expect(area.width, closeTo(0.1, 1e-9));
      expect(area.height, closeTo(0.1, 1e-9));
      expect(editor.isUndersized('bus'), isFalse);
    });

    test('une zone assez grande ne bouge pas', () {
      final editor = buildEditor();
      editor.enforceMinimumSize('bus');
      expect(editor.areas['bus'], centered());
    });

    test('agrandie contre un bord, elle reste sur l\'image', () {
      final editor = buildEditor(
        areas: <String, RelativeArea>{
          'bus': const RelativeArea(
            left: 0.97,
            top: 0.98,
            width: 0.02,
            height: 0.01,
          ),
        },
      );

      editor.enforceMinimumSize('bus');

      final area = editor.areas['bus']!;
      expect(area.right, lessThanOrEqualTo(1 + 1e-9));
      expect(area.bottom, lessThanOrEqualTo(1 + 1e-9));
      expect(area.width, closeTo(0.1, 1e-9));
    });
  });
}
