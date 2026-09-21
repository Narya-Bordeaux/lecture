import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word_family.dart';

import '../support/stage_builders.dart';

/// Construire un parcours en ajoutant des trajets, un point apres l'autre.
///
/// Regle centrale, tranchee avec l'auteur : **l'identifiant nait du nom, puis
/// s'en detache**. « La gare » donne `gare` a la creation, et renommer le lieu
/// ensuite ne le touche plus. Sans cela, chaque renommage casserait les
/// destinations qui le citent — et, plus tard, le nom du fichier
/// d'illustration.

Adventure emptyAdventureAt(String startId) {
  return Adventure(
    id: 'essai',
    title: 'Essai',
    startStageId: startId,
    stages: <String, Stage>{
      startId: stage(id: startId, families: const <WordFamily>[], location: 'Depart'),
    },
  );
}

void main() {
  group('L\'identifiant nait du nom', () {
    test('un article en tete disparait, comme dans le contenu livre', () {
      // Le contenu existant dit « La gare » -> gare, « Le garage » -> garage :
      // la regle reproduit ce que l'auteur ecrivait deja a la main.
      expect(AdventureBuilder.slugify('La gare'), 'gare');
      expect(AdventureBuilder.slugify('Le garage'), 'garage');
      expect(AdventureBuilder.slugify('La plage'), 'plage');
      expect(AdventureBuilder.slugify('La maison'), 'maison');
    });

    test('les accents tombent, pour que l\'identifiant tienne dans un chemin',
        () {
      // A l'etape 4, l'illustration d'un lieu s'appellera d'apres lui. Une
      // apostrophe ou un accent dans un nom de fichier est un vrai ennui.
      expect(AdventureBuilder.slugify('Le marché'), 'marche');
      expect(AdventureBuilder.slugify('L\'arrêt de bus'), 'arret_de_bus');
      expect(AdventureBuilder.slugify('La forêt'), 'foret');
    });

    test('il reste lisible : un mot francais, pas une suite de signes', () {
      expect(AdventureBuilder.slugify('Le guichetier'), 'guichetier');
      expect(AdventureBuilder.slugify('Chez la marchande'), 'chez_la_marchande');
    });

    test('un nom qui ne donne rien produit quand meme un identifiant', () {
      expect(AdventureBuilder.slugify('   '), isNotEmpty);
      expect(AdventureBuilder.slugify('!!!'), isNotEmpty);
      // « Le » seul : retirer l'article ne doit pas tout effacer.
      expect(AdventureBuilder.slugify('Le'), isNotEmpty);
    });
  });

  group('Ajouter des trajets', () {
    test('chaque trajet cree son lieu d\'arrivee', () {
      final built = AdventureBuilder(emptyAdventureAt('maison')).addTrips(
        'maison',
        const <NewTrip>[
          NewTrip(name: 'En bus'),
          NewTrip(name: 'En voiture'),
          NewTrip(name: 'À pied'),
        ],
      );

      expect(built.stages.keys, containsAll(<String>['en_bus', 'en_voiture', 'a_pied']));
      expect(built.findStage('maison')!.families, hasLength(3));
      expect(
        built.findStage('maison')!.families.map((f) => f.label).toList(),
        <String>['En bus', 'En voiture', 'À pied'],
      );
    });

    test('le nom reste affiche tel qu\'on l\'a ecrit', () {
      final built = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[NewTrip(name: 'La gare')]);

      // L'identifiant est normalise, le nom ne l'est pas : l'enfant lit
      // « La gare », pas « gare ».
      expect(built.findStage('gare')!.locationName, 'La gare');
      expect(built.findStage('maison')!.families.single.label, 'La gare');
    });

    test('deux noms identiques ne se marchent pas dessus', () {
      final built = AdventureBuilder(emptyAdventureAt('maison')).addTrips(
        'maison',
        const <NewTrip>[NewTrip(name: 'La gare'), NewTrip(name: 'La gare')],
      );

      expect(built.stages.keys, containsAll(<String>['gare', 'gare_2']));
      expect(built.stages, hasLength(3));
    });

    test('un nom qui reprend un lieu existant est suffixe, pas ecrase', () {
      final first = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[NewTrip(name: 'La gare')]);
      final second = AdventureBuilder(first)
          .addTrips('gare', const <NewTrip>[NewTrip(name: 'La gare')]);

      expect(second.findStage('gare'), isNotNull);
      expect(second.findStage('gare_2'), isNotNull);
      expect(second.findStage('gare')!.locationName, 'La gare');
    });

    test('ajouter un trajet a une fin la fait cesser d\'en etre une', () {
      final withEnding = Adventure(
        id: 'essai',
        title: 'Essai',
        startStageId: 'maison',
        stages: <String, Stage>{
          'maison': stage(id: 'maison', families: const <WordFamily>[]),
          'plage': ending(id: 'plage'),
        },
      );

      final built = AdventureBuilder(withEnding)
          .addTrips('plage', const <NewTrip>[NewTrip(name: 'La mer')]);

      // Sinon le marqueur et la structure se contrediraient, ce que
      // validate() refuse — a juste titre.
      expect(built.findStage('plage')!.isEnding, isFalse);
      expect(
        built.validate().where((i) => i.severity == IssueSeverity.wrong),
        isEmpty,
      );
    });

    test('un lieu neuf est signale incomplet, jamais faux', () {
      final built = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[NewTrip(name: 'La gare')]);

      // Tout ce qui vient d'etre cree reste a ecrire : c'est l'etat normal,
      // et rien ne doit s'afficher en rouge.
      expect(
        built.validate().where((i) => i.severity == IssueSeverity.wrong),
        isEmpty,
      );
      expect(built.validate(), isNotEmpty);
    });
  });

  group('Un trajet de type personnage', () {
    late Adventure built;

    setUpAll(() {
      built = AdventureBuilder(emptyAdventureAt('gare')).addTrips(
        'gare',
        const <NewTrip>[
          NewTrip(name: 'Le guichetier', kind: TripKind.encounter),
        ],
      );
    });

    test('le lieu d\'arrivee est une rencontre', () {
      final met = built.findStage('guichetier')!;

      expect(met.isEncounter, isTrue);
      expect(met.encounter!.character.name, 'Le guichetier');
    });

    test('son classeur sans issue est pose d\'office', () {
      // La specification veut qu'un personnage pose une question, et que
      // l'enfant trie entre le theme et un classeur de rebut. Sans lui, le
      // lieu naitrait a moitie, et il faudrait y penser a chaque fois.
      final met = built.findStage('guichetier')!;

      expect(met.families, hasLength(1));
      expect(met.families.single.leadsSomewhere, isFalse);
    });

    test('un trajet ordinaire n\'en pose aucun', () {
      final ordinary = AdventureBuilder(emptyAdventureAt('gare'))
          .addTrips('gare', const <NewTrip>[NewTrip(name: 'Le quai')]);

      expect(ordinary.findStage('quai')!.families, isEmpty);
      expect(ordinary.findStage('quai')!.isEncounter, isFalse);
    });
  });

  group('L\'identifiant se detache du nom', () {
    test('renommer le lieu ne touche pas son identifiant', () {
      final built = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[NewTrip(name: 'La gare')]);

      final renamed = built.findStage('gare')!
          .copyWith(locationName: 'La grande gare de la ville');

      // C'est toute la regle : l'identifiant nait du nom, puis cesse de le
      // suivre. Sinon chaque renommage casserait les destinations qui le
      // citent.
      expect(renamed.id, 'gare');
      expect(renamed.locationName, 'La grande gare de la ville');
    });
  });
}
