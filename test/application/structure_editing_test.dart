import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Revenir sur la structure d'un lieu deja ecrit.
///
/// Une fois la nature choisie, rien ne permettait d'y revenir : ni changer un
/// lieu a plusieurs listes en tri unique, ni rouvrir une fin creee par erreur,
/// ni renommer ou retirer un trajet. Ces gestes gardent tout ce qui peut
/// l'etre, et **ne suppriment jamais un lieu en passant** : un lieu que plus
/// rien n'atteint reste, detache, jusqu'a ce que l'auteur le supprime.

/// Devant la maison : trois trajets vers la gare, le garage et la rue.
Adventure _crossroads() {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: 'maison',
    stages: <String, Stage>{
      'maison': stage(
        id: 'maison',
        location: 'Devant la maison',
        drawCount: 7,
        families: <WordFamily>[
          family(id: 'en_bus', label: 'En bus', words: <Word>[word('ticket')], destination: 'gare'),
          family(id: 'en_voiture', label: 'En voiture', words: <Word>[word('volant')], destination: 'garage'),
          family(id: 'a_pied', label: 'À pied', words: <Word>[word('sentier')], destination: 'rue'),
        ],
      ),
      'gare': stage(id: 'gare', location: 'La gare', families: const <WordFamily>[]),
      'garage': ending(id: 'garage', location: 'Le garage'),
      'rue': ending(id: 'rue', location: 'La rue'),
    },
  );
}

AdventureBuilder _builder([Adventure? adventure]) =>
    AdventureBuilder(adventure ?? _crossroads());

void main() {
  group('Renommer un trajet', () {
    test('le nom lu par l\'enfant change, pas l\'identifiant', () {
      final after = _builder().renameTrip('maison', 'en_bus', 'En autocar');
      final bus = after.findStage('maison')!.findFamily('en_bus')!;

      expect(bus.label, 'En autocar');
      expect(bus.destinationStageId, 'gare');
    });

    test('un nom vide est refuse', () {
      expect(
        () => _builder().renameTrip('maison', 'en_bus', '  '),
        throwsArgumentError,
      );
    });
  });

  group('Retirer un trajet', () {
    test('le trajet part, le lieu qu\'il desservait reste', () {
      final after = _builder().removeTrip('maison', 'en_voiture');

      expect(after.findStage('maison')!.findFamily('en_voiture'), isNull);
      // Rien ne disparait sans que l'auteur l'ait decide.
      expect(after.findStage('garage'), isNotNull);
    });

    test('retirer le dernier trajet rend le lieu a definir', () {
      var adventure = _crossroads();
      for (final id in <String>['en_bus', 'en_voiture', 'a_pied']) {
        adventure = AdventureBuilder(adventure).removeTrip('maison', id);
      }

      expect(adventure.findStage('maison')!.nature, StageNature.undefined);
    });
  });

  group('Rediriger un trajet', () {
    test('il peut rejoindre n\'importe quel lieu deja ecrit', () {
      final after = _builder().redirectTrip('maison', 'en_voiture', 'rue');

      expect(
        after.findStage('maison')!.findFamily('en_voiture')!.destinationStageId,
        'rue',
      );
    });

    test('meme en arriere : la boucle est permise, et signalee', () {
      final withTrip = AdventureBuilder(_crossroads())
          .addTrips('gare', const <NewTrip>[NewTrip(name: 'Le train')]);
      final looped = AdventureBuilder(withTrip)
          .redirectTrip('gare', 'train', 'maison');

      expect(
        looped.findStage('gare')!.findFamily('train')!.destinationStageId,
        'maison',
      );
      expect(looped.validate().where((i) => i.message.contains('tourner en rond')),
          isNotEmpty);
    });

    test('un lieu inconnu est refuse', () {
      expect(
        () => _builder().redirectTrip('maison', 'en_bus', 'lune'),
        throwsStateError,
      );
    });

    test('le reste d\'un tri unique ne mene nulle part, et y reste', () {
      final shop = AdventureBuilder(_crossroads())
          .defineAsSingleSort('gare', const NewTrip(name: 'Ce qui se mange'));
      final rest = shop
          .findStage('gare')!
          .families
          .singleWhere((f) => !f.leadsSomewhere);

      expect(
        () => AdventureBuilder(shop).redirectTrip('gare', rest.id, 'rue'),
        throwsStateError,
      );
    });
  });

  group('Plusieurs listes devient tri unique', () {
    test('le trajet choisi devient le theme, les autres partent', () {
      final after = _builder().convertToSingleSort('maison', themeFamilyId: 'en_bus');
      final maison = after.findStage('maison')!;

      expect(maison.nature, StageNature.singleSort);
      final theme = maison.families.singleWhere((f) => f.leadsSomewhere);
      expect(theme.id, 'en_bus');
      expect(theme.wordTexts, <String>{'ticket'}, reason: 'sa liste est gardee');
      expect(maison.families.where((f) => !f.leadsSomewhere), hasLength(1));
      // Les lieux desservis par les trajets retires restent, detaches.
      expect(after.findStage('garage'), isNotNull);
    });

    test('le reste nait sans liste, a cocher', () {
      final after = _builder().convertToSingleSort('maison', themeFamilyId: 'en_bus');
      final rest = after
          .findStage('maison')!
          .families
          .singleWhere((f) => !f.leadsSomewhere);

      expect(rest.lists, isEmpty);
    });

    test('un trajet inconnu est refuse', () {
      expect(
        () => _builder().convertToSingleSort('maison', themeFamilyId: 'en_fusee'),
        throwsStateError,
      );
    });
  });

  group('Tri unique devient plusieurs listes', () {
    test('le reste part, le theme reste un trajet ordinaire', () {
      final shop = AdventureBuilder(_crossroads())
          .convertToSingleSort('maison', themeFamilyId: 'en_bus');
      final after = AdventureBuilder(shop).convertToSorting('maison');
      final maison = after.findStage('maison')!;

      expect(maison.nature, StageNature.sorting);
      expect(maison.families.map((f) => f.id), <String>['en_bus']);
    });
  });

  group('Devenir une fin, et en revenir', () {
    test('un lieu a trajets devient une fin : ses trajets partent', () {
      final after = _builder().convertToEnding('maison');

      expect(after.findStage('maison')!.nature, StageNature.ending);
      expect(after.findStage('maison')!.families, isEmpty);
      expect(after.findStage('gare'), isNotNull);
    });

    test('une fin se rouvre, et redevient a definir', () {
      final after = _builder().reopen('garage');

      expect(after.findStage('garage')!.nature, StageNature.undefined);
    });

    test('rouvrir un lieu qui n\'est pas une fin est refuse', () {
      expect(() => _builder().reopen('maison'), throwsStateError);
    });
  });

  group('Supprimer un lieu', () {
    test('un lieu que plus rien n\'atteint se supprime', () {
      final detached = _builder().removeTrip('maison', 'en_voiture');
      final after = AdventureBuilder(detached).removeStage('garage');

      expect(after.findStage('garage'), isNull);
    });

    test('un lieu encore atteint ne se supprime pas', () {
      // Le trajet qui y mene deviendrait une promesse sans lieu.
      expect(() => _builder().removeStage('gare'), throwsStateError);
    });

    test('le point de depart ne se supprime pas', () {
      expect(() => _builder().removeStage('maison'), throwsStateError);
    });
  });
}
