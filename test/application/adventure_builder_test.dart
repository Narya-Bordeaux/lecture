import 'package:flutter_test/flutter_test.dart';
import 'package:grisbie/application/adventure_builder.dart';
import 'package:grisbie/domain/models/adventure.dart';
import 'package:grisbie/domain/models/content_issue.dart';
import 'package:grisbie/domain/models/stage.dart';
import 'package:grisbie/domain/models/word.dart';
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

  group('Un trajet de type tri unique', () {
    // L'enfant y trie entre **une liste et son complement** : ce qui est du
    // theme, et tout le reste. Rien a comparer d'un mot a l'autre, chacun se
    // juge seul contre un seul critere.

    late Adventure built;

    setUpAll(() {
      built = AdventureBuilder(emptyAdventureAt('gare')).addTrips(
        'gare',
        const <NewTrip>[
          NewTrip(name: 'La boutique', kind: TripKind.singleSort),
        ],
      );
    });

    test('la liste du reste est posee d\'office', () {
      // Elle n'est pas un defaut a corriger : c'est la moitie du dispositif.
      // La poser d'office evite un lieu ne a moitie.
      final sorting = built.findStage('boutique')!;

      expect(sorting.isSingleSort, isTrue);
      expect(sorting.families, hasLength(1));
      expect(sorting.families.single.leadsSomewhere, isFalse);
    });

    test('aucun personnage n\'est invente', () {
      // Le personnage est un ornement, pas la mecanique : l'outil ne doit pas
      // en fabriquer un dont l'auteur n'a pas voulu.
      expect(built.findStage('boutique')!.isEncounter, isFalse);
    });

    test('un trajet ordinaire ne pose aucune liste', () {
      final ordinary = AdventureBuilder(emptyAdventureAt('gare'))
          .addTrips('gare', const <NewTrip>[NewTrip(name: 'Le quai')]);

      expect(ordinary.findStage('quai')!.families, isEmpty);
      expect(ordinary.findStage('quai')!.isSingleSort, isFalse);
    });

    test('il n\'accepte qu\'une seule sortie', () {
      final prolonged = AdventureBuilder(built).addTrips(
        'boutique',
        const <NewTrip>[NewTrip(name: 'Ce qui se mange')],
      );

      expect(prolonged.findStage('boutique')!.families, hasLength(2));
      expect(
        prolonged.validate().where((i) => i.severity == IssueSeverity.wrong),
        isEmpty,
      );

      // Une seconde sortie en ferait un tri ordinaire affuble d'une liste de
      // rebut : ce n'est plus la meme mecanique, et l'outil le refuse.
      expect(
        () => AdventureBuilder(prolonged).addTrips(
          'boutique',
          const <NewTrip>[NewTrip(name: 'Ce qui se boit')],
        ),
        throwsStateError,
      );
    });

    test('deux trajets d\'un coup y sont refuses', () {
      expect(
        () => AdventureBuilder(built).addTrips(
          'boutique',
          const <NewTrip>[NewTrip(name: 'Un'), NewTrip(name: 'Deux')],
        ),
        throwsStateError,
      );
    });
  });

  group('Une aventure a partir de zero', () {
    test('elle se reduit a son point de depart', () {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Grisbie va au marché',
        startName: 'Devant la maison',
      );

      expect(fresh.id, 'grisbie_va_au_marche');
      expect(fresh.stages, hasLength(1));
      expect(fresh.startStageId, 'devant_la_maison');
      expect(fresh.startStage.locationName, 'Devant la maison');
    });

    test('elle est incomplete, jamais fausse', () {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Le seuil',
      );

      // Commencer une aventure ne doit pas ouvrir sur un ecran rouge.
      expect(
        fresh.validate().where((i) => i.severity == IssueSeverity.wrong),
        isEmpty,
      );
      expect(fresh.validate(), isNotEmpty);
    });

    test('on la prolonge aussitot, trajet par trajet', () {
      final fresh = AdventureBuilder.createAdventure(
        title: 'Essai',
        startName: 'Devant la maison',
      );

      final built = AdventureBuilder(fresh).addTrips(
        fresh.startStageId,
        const <NewTrip>[NewTrip(name: 'En bus'), NewTrip(name: 'À pied')],
      );

      expect(built.stages, hasLength(3));
      expect(built.startStage.families, hasLength(2));
    });
  });

  group('Chaque liste du reste est propre a son lieu', () {
    test('deux tris uniques ne partagent pas leur liste', () {
      final built = AdventureBuilder(emptyAdventureAt('depart')).addTrips(
        'depart',
        const <NewTrip>[
          NewTrip(name: 'La boutique', kind: TripKind.singleSort),
          NewTrip(name: 'Le kiosque', kind: TripKind.singleSort),
        ],
      );

      final boutique = built.findStage('boutique')!.families.single;
      final kiosque = built.findStage('kiosque')!.families.single;

      // Les familles ne sont pas le meme objet : ecrire dans l'une ne peut en
      // aucun cas toucher l'autre. Les mots viennent du lexique, qui les
      // definit une fois ; les **listes**, elles, appartiennent au lieu.
      expect(identical(boutique, kiosque), isFalse);
      expect(boutique.words, isEmpty);
      expect(kiosque.words, isEmpty);
    });

    test('remplir l\'une laisse l\'autre intacte', () {
      final built = AdventureBuilder(emptyAdventureAt('depart')).addTrips(
        'depart',
        const <NewTrip>[
          NewTrip(name: 'La boutique', kind: TripKind.singleSort),
          NewTrip(name: 'Le kiosque', kind: TripKind.singleSort),
        ],
      );

      final boutique = built.findStage('boutique')!.families.single;
      final filled = boutique.copyWith(
        list: boutique.list.copyWith(
          words: <Word>[word('vélo', const <String>['vé', 'lo'])],
        ),
      );

      expect(filled.words, hasLength(1));
      expect(built.findStage('kiosque')!.families.single.words, isEmpty);
    });
  });

  group('Un trajet qui clot la journee', () {
    late Adventure built;

    setUpAll(() {
      built = AdventureBuilder(emptyAdventureAt('gare')).addTrips(
        'gare',
        const <NewTrip>[NewTrip(name: 'La plage', kind: TripKind.ending)],
      );
    });

    test('le lieu d\'arrivee se declare fin', () {
      // Troisieme choix structurel, a cote du tri a plusieurs listes et du tri
      // unique : ici la journee s'arrete, et rien ne repart.
      final beach = built.findStage('plage')!;

      expect(beach.isEnding, isTrue);
      expect(beach.families, isEmpty);
    });

    test('elle ne produit aucune anomalie', () {
      // Une fin declaree et sans famille est un lieu acheve : ni faux, ni
      // incomplet. C'est le seul lieu qu'on puisse creer deja termine.
      expect(
        built.validate().where((i) => i.stageId == 'plage'),
        isEmpty,
      );
    });

    test('prolonger une fin la fait cesser d\'en etre une', () {
      // Le moteur le permet et le doit : le marqueur et la structure ne
      // peuvent pas se contredire. L'ecran, lui, ne le propose plus — une
      // carte de fin n'a pas de bouton « Ajouter des trajets ».
      final prolonged = AdventureBuilder(built)
          .addTrips('plage', const <NewTrip>[NewTrip(name: 'Le retour')]);

      expect(prolonged.findStage('plage')!.isEnding, isFalse);
    });
  });

  group('Plusieurs chemins vers la meme fin', () {
    /// Un carrefour a deux sorties, dont l'une se termine deja a la plage.
    Adventure forkEndingAtBeach() {
      final forked = AdventureBuilder(emptyAdventureAt('carrefour')).addTrips(
        'carrefour',
        const <NewTrip>[NewTrip(name: 'En bus'), NewTrip(name: 'À pied')],
      );
      return AdventureBuilder(forked).addTrips(
        'en_bus',
        const <NewTrip>[NewTrip(name: 'La plage', kind: TripKind.ending)],
      );
    }

    test('rejoindre une fin existante ne cree aucun lieu', () {
      final before = forkEndingAtBeach();
      final after = AdventureBuilder(before).addTrips(
        'a_pied',
        const <NewTrip>[
          NewTrip(name: 'Le sentier', existingStageId: 'plage'),
        ],
      );

      // Une fin porte un ecran, une image et un texte : deux chemins qui
      // aboutissent au meme endroit doivent partager la meme, sans quoi il
      // faudrait ecrire deux fois la meme arrivee.
      expect(after.stages.keys, hasLength(before.stages.keys.length));
      expect(
        after.findStage('a_pied')!.families.single.destinationStageId,
        'plage',
      );
    });

    test('le nom saisi reste celui du trajet, pas celui du lieu', () {
      final after = AdventureBuilder(forkEndingAtBeach()).addTrips(
        'a_pied',
        const <NewTrip>[
          NewTrip(name: 'Le sentier', existingStageId: 'plage'),
        ],
      );

      // C'est ce que l'enfant lit sur la zone de depot. Le lieu d'arrivee, lui,
      // garde le nom qu'il avait.
      expect(after.findStage('a_pied')!.families.single.label, 'Le sentier');
      expect(after.findStage('plage')!.locationName, 'La plage');
    });

    test('un lieu qui n\'existe pas est refuse en le nommant', () {
      expect(
        () => AdventureBuilder(forkEndingAtBeach()).addTrips(
          'a_pied',
          const <NewTrip>[
            NewTrip(name: 'Le sentier', existingStageId: 'montagne'),
          ],
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('montagne'),
          ),
        ),
      );
    });
  });

  group('Le trajet et le lieu qu\'il atteint portent deux noms', () {
    // « En bus » est ce que l'enfant lit sur la zone de depot ; « La gare »
    // est le lieu ou il arrive. Deux choses differentes, et c'est tout
    // l'interet : l'enfant classe des mots sous « En bus », puis decouvre
    // « La gare ». L'outil les confondait, et apprenait donc a l'auteur une
    // regle fausse — au point de faire passer le contenu livre pour un
    // affichage casse.

    test('le lieu porte le nom donne, et son identifiant en vient', () {
      final built = AdventureBuilder(emptyAdventureAt('maison')).addTrips(
        'maison',
        const <NewTrip>[NewTrip(name: 'En bus', locationName: 'La gare')],
      );

      // Exactement ce que le contenu livre ecrit a la main : l'outil en est
      // desormais capable, ce qui n'etait pas le cas.
      expect(built.stages.keys, contains('gare'));
      expect(built.findStage('gare')!.locationName, 'La gare');

      final family = built.findStage('maison')!.families.single;
      expect(family.label, 'En bus', reason: 'ce que l\'enfant lit');
      expect(family.id, 'en_bus', reason: 'la famille est celle du trajet');
    });

    test('sans nom de lieu, le trajet le prete', () {
      // Le comportement d'avant, garde tel quel : nommer les deux est une
      // possibilite, pas une obligation.
      final built = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[NewTrip(name: 'La gare')]);

      expect(built.findStage('gare')!.locationName, 'La gare');
    });

    test('un nom de lieu laisse vide ne remplace rien', () {
      // Un champ qu'on n'a pas rempli ne doit pas produire un lieu appele
      // « lieu » : c'est ce que `slugify` rend d'une chaine sans lettre.
      final built = AdventureBuilder(emptyAdventureAt('maison')).addTrips(
        'maison',
        const <NewTrip>[NewTrip(name: 'En bus', locationName: '   ')],
      );

      expect(built.stages.keys, contains('en_bus'));
      expect(built.findStage('en_bus')!.locationName, 'En bus');
    });

    test('une fin nommee a part se declare quand meme fin', () {
      final built = AdventureBuilder(emptyAdventureAt('maison')).addTrips(
        'maison',
        const <NewTrip>[
          NewTrip(
            name: 'Prendre le train',
            locationName: 'La plage',
            kind: TripKind.ending,
          ),
        ],
      );

      expect(built.findStage('plage')!.isEnding, isTrue);
      expect(built.findStage('maison')!.families.single.label,
          'Prendre le train');
    });

    test('rejoindre un lieu deja ecrit ignore le nom propose', () {
      final before = AdventureBuilder(emptyAdventureAt('maison'))
          .addTrips('maison', const <NewTrip>[
        NewTrip(name: 'En bus', locationName: 'La plage', kind: TripKind.ending),
      ]);

      final after = AdventureBuilder(before).addTrips(
        'maison',
        const <NewTrip>[
          NewTrip(
            name: 'À pied',
            locationName: 'Un autre nom',
            existingStageId: 'plage',
          ),
        ],
      );

      // Le lieu existe : le renommer par un trajet qui le rejoint ferait
      // changer son titre a l'insu de l'autre chemin qui y mene.
      expect(after.findStage('plage')!.locationName, 'La plage');
      expect(after.stages.keys, hasLength(before.stages.keys.length));
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
