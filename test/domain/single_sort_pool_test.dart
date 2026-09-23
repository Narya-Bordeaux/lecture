import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

import '../support/stage_builders.dart';

/// Le tri unique, option C : le panier « autre » puise dans des listes choisies.
///
/// L'auteur choisit la liste du theme, puis coche les listes ou le jeu peut
/// prendre les mots qui n'en sont pas. Le jeu y tire des mots **absents du
/// theme**. Tirer dans tout le vocabulaire a ete ecarte : « banane », absente
/// de la liste « Ce qui se mange » mais presente ailleurs, serait refusee a
/// l'enfant qui la range a juste titre. Cocher des listes, c'est dire
/// lesquelles sont sures pour ce theme.

final WordList _food = wordList('nourriture', <Word>[
  word('pomme'),
  word('pain'),
  word('gâteau'),
]);

final WordList _objects = wordList('objets', <Word>[
  word('clé'),
  word('banc'),
  word('pomme'),
]);

final WordList _tools = wordList('outils', <Word>[
  word('marteau'),
  word('clé'),
]);

Stage shop({List<WordList>? restLists, int? drawCount}) {
  return stage(
    id: 'boutique',
    drawCount: drawCount,
    families: <WordFamily>[
      family(
        id: 'a_manger',
        label: 'Ce qui se mange',
        list: _food,
        destination: 'plage',
      ),
      WordFamily(
        id: 'autre',
        label: 'Autre chose',
        lists: restLists ?? <WordList>[_objects, _tools],
      ),
    ],
  );
}

WordFamily restOf(Stage stage) =>
    stage.families.singleWhere((family) => !family.leadsSomewhere);

WordFamily themeOf(Stage stage) =>
    stage.families.singleWhere((family) => family.leadsSomewhere);

void main() {
  group('Une famille qui cite plusieurs listes', () {
    test('ses mots sont ceux des listes reunies, chacun une fois', () {
      final rest = restOf(shop());

      // « clé » est dans les deux listes cochees : il ne compte qu'une fois.
      expect(
        rest.words.map((w) => w.text),
        <String>['clé', 'banc', 'pomme', 'marteau'],
      );
    });

    test('elle se relit telle qu\'elle s\'ecrit', () {
      final catalog = WordListCatalog(<String, WordList>{
        'objets': _objects,
        'outils': _tools,
      });
      final json = restOf(shop()).toJson();

      expect(json['lists'], <String>['objets', 'outils']);
      expect(json.containsKey('list'), isFalse);

      final read = WordFamily.fromJson(json, catalog);
      expect(read.lists.map((list) => list.id), <String>['objets', 'outils']);
    });

    test('une seule liste s\'ecrit comme avant', () {
      // Le contenu livre ecrit « list » : le format ne change pas pour lui.
      final json = themeOf(shop()).toJson();

      expect(json['list'], 'nourriture');
      expect(json.containsKey('lists'), isFalse);
    });

    test('« list » et « lists » se lisent tous deux', () {
      final catalog = WordListCatalog(<String, WordList>{
        'nourriture': _food,
      });

      final single = WordFamily.fromJson(<String, dynamic>{
        'id': 'a_manger',
        'label': 'Ce qui se mange',
        'list': 'nourriture',
      }, catalog);
      final several = WordFamily.fromJson(<String, dynamic>{
        'id': 'autre',
        'label': 'Autre chose',
        'lists': <String>['nourriture'],
      }, catalog);

      expect(single.lists.single.id, 'nourriture');
      expect(several.lists.single.id, 'nourriture');
    });

    test('elle peut ne citer encore aucune liste', () {
      final rest = restOf(shop(restLists: const <WordList>[]));

      expect(rest.words, isEmpty);
      expect(rest.toJson()['lists'], isEmpty);
    });
  });

  group('Le reste se tire hors du theme', () {
    test('les mots du theme sont retires du reste', () {
      final boutique = shop();

      // « pomme » est dans la liste d'objets, mais c'est du theme : le jeu ne
      // doit jamais la proposer comme « autre chose ».
      expect(
        boutique.availableWordsIn(restOf(boutique)).wordTexts,
        <String>{'clé', 'banc', 'marteau'},
      );
    });

    test('le theme, lui, garde tous ses mots', () {
      // Asymetrie voulue : c'est le reste qui se definit par le theme, pas
      // l'inverse. Dans un lieu a plusieurs listes, un mot commun est retire
      // des deux cotes ; ici, retirer « pomme » du theme n'aurait aucun sens.
      final boutique = shop();

      expect(
        boutique.availableWordsIn(themeOf(boutique)).wordTexts,
        <String>{'pomme', 'pain', 'gâteau'},
      );
    });

    test('le tirage respecte la regle', () {
      final drawn = shop(drawCount: 3).drawnWith(Random(1));

      expect(restOf(drawn).wordTexts.contains('pomme'), isFalse);
      expect(themeOf(drawn).wordTexts, hasLength(3));
    });

    test('un lieu a plusieurs listes reste symetrique', () {
      final station = stage(id: 'gare', families: <WordFamily>[
        family(id: 'a', label: 'A', list: _objects, destination: 'x'),
        family(id: 'b', label: 'B', list: _tools, destination: 'y'),
      ]);

      // « clé » est ambigu ici : il part des deux cotes.
      expect(
        station.availableWordsIn(station.families.first).wordTexts,
        <String>{'banc', 'pomme'},
      );
      expect(
        station.availableWordsIn(station.families.last).wordTexts,
        <String>{'marteau'},
      );
    });
  });

  group('Ce que la carte doit pouvoir dire', () {
    test('une famille qui ne puise encore nulle part est a finir', () {
      final issues = shop(restLists: const <WordList>[]).validate();
      final empty = issues.where((i) => i.familyId == 'autre').toList();

      expect(empty, isNotEmpty);
      expect(empty.every((i) => i.severity == IssueSeverity.incomplete), isTrue);
    });

    test('l\'offre d\'une famille se compte apres exclusion', () {
      final boutique = shop(drawCount: 7);
      final supply = boutique.supplyOf(restOf(boutique));

      expect(supply.total, 4);
      expect(supply.shared, 1);
      expect(supply.available, 3);
      expect(supply.required, 7);
      expect(supply.isEnough, isFalse);
    });

    test('sans nombre demande, toute offre non vide suffit', () {
      final boutique = shop();
      final supply = boutique.supplyOf(themeOf(boutique));

      expect(supply.required, isNull);
      expect(supply.isEnough, isTrue);
    });
  });
}
