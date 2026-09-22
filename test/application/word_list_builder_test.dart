import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/word_list_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/lexicon.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';
import 'package:grisbie/domain/models/word_library.dart';
import 'package:grisbie/domain/models/word_list.dart';
import 'package:grisbie/domain/models/word_list_catalog.dart';

import '../support/stage_builders.dart';

/// Composer les listes de mots d'une aventure.
///
/// **Il n'y a pas de mot seul** : un mot entre toujours par une liste. Pour
/// chaque trajet, soit on cree une liste, soit on en reutilise une qui existe.
/// Un mot deja connu garde son decoupage — le lexique n'en admet qu'un — et
/// un mot neuf ne s'ajoute pas sans le sien.

final Word _ticket = word('ticket', const <String>['ti', 'ket']);
final Word _arret = word('arrêt', const <String>['a', 'rê']);

/// Ce que le contenu existant connait deja.
final WordLibrary _library = WordLibrary(
  lexicon: Lexicon(<String, Word>{
    'ticket': _ticket,
    'arrêt': _arret,
    'clé': word('clé'),
  }),
  lists: WordListCatalog(<String, WordList>{
    'bus': wordList('bus', <Word>[_ticket, _arret]),
    'objets': wordList('objets', <Word>[word('clé')]),
  }),
);

/// Une maison d'ou partent deux trajets, a listes vides, et une boutique.
Adventure _adventure() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'maison',
    stages: <String, Stage>{
      'maison': stage(id: 'maison', location: 'Devant la maison', families: <WordFamily>[
        family(id: 'en_bus', label: 'En bus', list: wordList('maison_en_bus', const <Word>[]), destination: 'gare'),
        family(id: 'a_pied', label: 'À pied', list: wordList('maison_a_pied', const <Word>[]), destination: 'rue'),
      ]),
      'gare': stage(id: 'gare', location: 'La gare', families: <WordFamily>[
        family(id: 'le_train', label: 'Le train', list: wordList('gare_le_train', const <Word>[]), destination: 'plage'),
        WordFamily(id: 'le_reste', label: 'Le reste', lists: const <WordList>[]),
      ]),
      'rue': ending(id: 'rue'),
      'plage': ending(id: 'plage'),
    },
  );
}

WordFamily familyOf(Adventure adventure, String stageId, String familyId) {
  return adventure.findStage(stageId)!.findFamily(familyId)!;
}

void main() {
  late WordListBuilder builder;

  setUp(() {
    builder = WordListBuilder(_adventure(), library: _library);
  });

  group('Reutiliser une liste', () {
    test('le trajet cite la liste existante, avec ses mots', () {
      final after = builder.useListFor('maison', 'en_bus', 'bus');
      final bus = familyOf(after, 'maison', 'en_bus');

      expect(bus.list.id, 'bus');
      expect(bus.words.map((w) => w.text), <String>['ticket', 'arrêt']);
    });

    test('une liste inconnue est refusee en la nommant', () {
      expect(
        () => builder.useListFor('maison', 'en_bus', 'fantome'),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('fantome'))),
      );
    });

    test('les listes connues se proposent, celles de l\'aventure comprises', () {
      final ids = builder.knownLists.map((list) => list.id).toSet();

      expect(ids, containsAll(<String>['bus', 'objets', 'maison_en_bus']));
      // Une famille sans liste n'en fait pas apparaitre de fantome.
      expect(ids.contains(''), isFalse);
    });
  });

  group('Creer une liste', () {
    test('elle nait vide, nommee, et citee par le trajet', () {
      final after = builder.createListFor('maison', 'en_bus', name: 'Ce qui roule');
      final bus = familyOf(after, 'maison', 'en_bus');

      expect(bus.list.name, 'Ce qui roule');
      expect(bus.list.id, 'ce_qui_roule');
      expect(bus.words, isEmpty);
    });

    test('son identifiant ne reprend pas celui d\'une liste existante', () {
      // Les listes forment un catalogue global : un doublon ferait refuser le
      // contenu entier au chargement.
      final after = builder.createListFor('maison', 'en_bus', name: 'Bus');

      expect(familyOf(after, 'maison', 'en_bus').list.id, 'bus_2');
    });
  });

  group('Ajouter un mot', () {
    test('un mot connu garde son decoupage', () {
      final after = builder.addWord('maison_en_bus', text: 'arrêt');

      expect(
        familyOf(after, 'maison', 'en_bus').words.single.syllables,
        <String>['a', 'rê'],
      );
    });

    test('un mot neuf entre avec le decoupage saisi', () {
      final after = builder.addWord(
        'maison_en_bus',
        text: 'volant',
        syllables: const <String>['vo', 'lant'],
      );

      expect(
        familyOf(after, 'maison', 'en_bus').words.single.syllables,
        <String>['vo', 'lant'],
      );
    });

    test('un mot neuf sans decoupage est refuse', () {
      // Le decoupage n'est jamais calcule : sans lui, le mot n'a pas d'aide.
      expect(
        () => builder.addWord('maison_en_bus', text: 'volant'),
        throwsArgumentError,
      );
    });

    test('les espaces autour du mot ne comptent pas', () {
      final after = builder.addWord('maison_en_bus', text: '  arrêt ');

      expect(familyOf(after, 'maison', 'en_bus').words.single.text, 'arrêt');
    });

    test('un mot deja dans la liste ne s\'y ajoute pas deux fois', () {
      final once = builder.addWord('maison_en_bus', text: 'ticket');

      expect(
        () => WordListBuilder(once, library: _library)
            .addWord('maison_en_bus', text: 'ticket'),
        throwsStateError,
      );
    });

    test('un mot ecrit plus tot dans l\'aventure est connu aussi', () {
      final first = builder.addWord(
        'maison_en_bus',
        text: 'volant',
        syllables: const <String>['vo', 'lant'],
      );
      final second = WordListBuilder(first, library: _library)
          .addWord('maison_a_pied', text: 'volant');

      expect(
        familyOf(second, 'maison', 'a_pied').words.single.syllables,
        <String>['vo', 'lant'],
      );
    });

    test('une liste que l\'aventure ne cite pas est refusee', () {
      // Modifier une liste de la bibliotheque sans qu'aucun trajet ne la cite
      // n'aurait aucun effet visible, et rien ne l'enregistrerait.
      expect(
        () => builder.addWord('objets', text: 'clé'),
        throwsStateError,
      );
    });
  });

  group('Une liste citee a plusieurs endroits', () {
    test('la modifier la modifie partout', () {
      final shared = WordListBuilder(
        builder.useListFor('maison', 'en_bus', 'bus'),
        library: _library,
      ).useListFor('gare', 'le_train', 'bus');

      final after = WordListBuilder(shared, library: _library)
          .removeWord('bus', 'ticket');

      expect(familyOf(after, 'maison', 'en_bus').wordTexts, <String>{'arrêt'});
      expect(familyOf(after, 'gare', 'le_train').wordTexts, <String>{'arrêt'});
    });

    test('ses usages se lisent, pour le dire avant de toucher', () {
      final shared = WordListBuilder(
        builder.useListFor('maison', 'en_bus', 'bus'),
        library: _library,
      ).useListFor('gare', 'le_train', 'bus');

      final usages = WordListBuilder(shared, library: _library).usagesOf('bus');

      expect(usages.map((u) => u.locationName), <String>['Devant la maison', 'La gare']);
      expect(usages.map((u) => u.familyLabel), <String>['En bus', 'Le train']);
    });
  });

  group('Corriger un decoupage', () {
    test('le mot change dans toutes les listes qui le citent', () {
      final both = WordListBuilder(
        builder.addWord('maison_en_bus', text: 'ticket'),
        library: _library,
      ).addWord('gare_le_train', text: 'ticket');

      final after = WordListBuilder(both, library: _library)
          .changeSyllables('ticket', const <String>['tic', 'ket']);

      expect(familyOf(after, 'maison', 'en_bus').words.single.syllables, <String>['tic', 'ket']);
      expect(familyOf(after, 'gare', 'le_train').words.single.syllables, <String>['tic', 'ket']);
    });
  });

  group('Le reste d\'un tri unique', () {
    test('il puise dans les listes cochees', () {
      final after = builder.setPooledLists('gare', 'le_reste', const <String>['objets', 'bus']);

      expect(
        familyOf(after, 'gare', 'le_reste').lists.map((l) => l.id),
        <String>['objets', 'bus'],
      );
    });

    test('decocher tout le laisse sans liste', () {
      final checked = builder.setPooledLists('gare', 'le_reste', const <String>['objets']);
      final after = WordListBuilder(checked, library: _library)
          .setPooledLists('gare', 'le_reste', const <String>[]);

      expect(familyOf(after, 'gare', 'le_reste').lists, isEmpty);
    });

    test('seul le reste puise dans plusieurs listes', () {
      // Le theme, ou une famille d'un lieu a plusieurs listes, n'en cite
      // qu'une : c'est ce qui la rend lisible pour l'enfant.
      expect(
        () => builder.setPooledLists('maison', 'en_bus', const <String>['bus']),
        throwsStateError,
      );
    });
  });

  group('Renommer une liste', () {
    test('le nom change, pas l\'identifiant', () {
      final after = builder.renameList('maison_en_bus', 'Ce qui roule');

      expect(familyOf(after, 'maison', 'en_bus').list.name, 'Ce qui roule');
      expect(familyOf(after, 'maison', 'en_bus').list.id, 'maison_en_bus');
    });
  });

  group('Lire un decoupage saisi', () {
    test('les syllabes se separent par un tiret, un point ou un espace', () {
      expect(WordListBuilder.parseSyllables('a-rê'), <String>['a', 'rê']);
      expect(WordListBuilder.parseSyllables('a · rê'), <String>['a', 'rê']);
      expect(WordListBuilder.parseSyllables(' ti ket '), <String>['ti', 'ket']);
      expect(WordListBuilder.parseSyllables('mar/teau'), <String>['mar', 'teau']);
    });

    test('rien de saisi, rien de lu', () {
      expect(WordListBuilder.parseSyllables('  '), isEmpty);
    });

    test('un decoupage se relit comme il s\'ecrit', () {
      expect(WordListBuilder.formatSyllables(const <String>['a', 'rê']), 'a-rê');
    });
  });
}
